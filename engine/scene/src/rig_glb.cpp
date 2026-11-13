// The skinned .glb of a rig (rig_glb.h): mesh_to_glb's bytes with the joints, the inverse bind matrices and the weights added.
#include "fa/scene/rig_glb.h"

#include <cmath>
#include <cstring>
#include <format>

namespace fa {

namespace {

std::uint32_t read32(const std::uint8_t* p) { return std::uint32_t(p[0]) | (std::uint32_t(p[1]) << 8) | (std::uint32_t(p[2]) << 16) | (std::uint32_t(p[3]) << 24); }

}  // namespace

Result<std::vector<std::uint8_t>> rig_to_glb(const MeshData& model, const RigFit& fit, const std::string& glbPath, const RigWeights* given) {
    if (fit.bones.empty() || fit.bones.size() > kRigMaxBones)
        return make_error(std::format("a skin needs 1 to {} joints, the rig has {}", kRigMaxBones, fit.bones.size()), "Lower the spine, neck or tail options.");
    auto base = mesh_to_glb(model, glbPath);
    if (!base.ok()) return base.error();
    const std::vector<std::uint8_t>& in = *base;
    if (in.size() < 28 || read32(in.data()) != 0x46546C67)
        return make_error("internal: mesh_to_glb did not return a .glb", "Report this as an engine bug.");
    const std::uint32_t jsonLen = read32(in.data() + 12);
    const std::uint8_t* jsonStart = in.data() + 20;
    const std::uint32_t binLen = read32(jsonStart + jsonLen);
    const std::uint8_t* binStart = jsonStart + jsonLen + 8;
    Json root = parse_json_lenient(std::string_view(reinterpret_cast<const char*>(jsonStart), jsonLen));
    if (root.is_discarded()) return make_error("internal: the .glb mesh_to_glb wrote has unreadable JSON", "Report this as an engine bug.");
    std::vector<std::uint8_t> bin(binStart, binStart + binLen);

    const std::size_t n = model.vertex_count();
    if (given && given->vertex_count() != n)
        return make_error(std::format("internal: {} skin weights for a model of {} vertices", given->vertex_count(), n), "Report this as an engine bug.");
    auto append = [&](const void* p, std::size_t bytes) {
        const std::size_t at = bin.size();
        bin.resize(at + bytes);
        std::memcpy(bin.data() + at, p, bytes);
        while (bin.size() % 4 != 0) bin.push_back(0);
        return at;
    };
    auto add_view = [&](const void* p, std::size_t bytes, Json target) {
        const std::size_t at = append(p, bytes);
        Json v = {{"buffer", 0}, {"byteOffset", at}, {"byteLength", bytes}};
        if (!target.is_null()) v["target"] = target;
        root["bufferViews"].push_back(v);
        return int(root["bufferViews"].size() - 1);
    };
    auto add_accessor = [&](int view, int componentType, std::size_t count, const char* type) {
        root["accessors"].push_back({{"bufferView", view}, {"byteOffset", 0}, {"componentType", componentType}, {"count", count}, {"type", type}});
        return int(root["accessors"].size() - 1);
    };

    std::vector<std::uint16_t> joints(n * 4, 0);
    std::vector<float> weights(n * 4, 0.0f);
    if (given) {
        joints = given->joints;
        weights = given->weights;
    } else {
        const std::vector<std::uint16_t> binding = rig_rigid_binding(fit, model);
        for (std::size_t v = 0; v < n; ++v) {
            joints[v * 4] = binding[v];
            weights[v * 4] = 1.0f;
        }
    }
    const int jointsAcc = add_accessor(add_view(joints.data(), joints.size() * 2, 34962), 5123, n, "VEC4");
    const int weightsAcc = add_accessor(add_view(weights.data(), weights.size() * 4, 34962), 5126, n, "VEC4");
    for (Json& mesh : root["meshes"])
        for (Json& prim : mesh["primitives"]) {
            prim["attributes"]["JOINTS_0"] = jointsAcc;
            prim["attributes"]["WEIGHTS_0"] = weightsAcc;
        }

    std::vector<float> ibm;
    ibm.reserve(fit.bones.size() * 16);
    for (const RigBoneFit& b : fit.bones) {
        const float m[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, -b.head.x, -b.head.y, -b.head.z, 1};
        ibm.insert(ibm.end(), m, m + 16);
    }
    const int ibmAcc = add_accessor(add_view(ibm.data(), ibm.size() * 4, Json()), 5126, fit.bones.size(), "MAT4");

    // the bones: node 0 is the mesh, bone i is node i + 1
    Json& nodes = root["nodes"];
    nodes[0]["skin"] = 0;
    Json joinsList = Json::array();
    for (std::size_t i = 0; i < fit.bones.size(); ++i) {
        const RigBoneFit& b = fit.bones[i];
        const Vec3 local = b.parentIndex >= 0 ? b.head - fit.bones[std::size_t(b.parentIndex)].head : b.head;
        Json node = {{"name", b.name}, {"translation", Json::array({local.x, local.y, local.z})}};
        Json extras = {{"role", b.role}};
        if (b.index) extras["index"] = b.index;
        if (!b.side.empty()) extras["side"] = b.side;
        // Where the bone points at rest (head to tail), for the 3D clips and IK (anim3d.h): a leaf has no child to read it from.
        const Vec3 d = b.tail - b.head;
        const float len = std::sqrt(d.x * d.x + d.y * d.y + d.z * d.z);
        if (len > 1e-6f) {
            extras["axis"] = Json::array({d.x / len, d.y / len, d.z / len});
            extras["length"] = len;
        }
        node["extras"] = extras;
        nodes.push_back(node);
        joinsList.push_back(int(i + 1));
    }
    for (std::size_t i = 0; i < fit.bones.size(); ++i)
        if (fit.bones[i].parentIndex >= 0) {
            Json& parent = nodes[std::size_t(fit.bones[i].parentIndex) + 1];
            if (!parent.contains("children")) parent["children"] = Json::array();
            parent["children"].push_back(int(i + 1));
        }
    root["scenes"][0]["nodes"].push_back(1);
    root["skins"] = Json::array({{{"name", "rig"},
                                  {"joints", joinsList},
                                  {"inverseBindMatrices", ibmAcc},
                                  {"skeleton", 1},
                                  {"extras", {{"factoriaRig", {{"format", kRigDocFormat}, {"template", fit.templateName}}}}}}});
    root["asset"]["generator"] = "FactorIA rig.bake";
    root["buffers"][0]["byteLength"] = bin.size();

    std::string json = root.dump();
    while (json.size() % 4 != 0) json += ' ';
    std::vector<std::uint8_t> out;
    auto put32 = [&](std::uint32_t v) {
        for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(v >> (8 * i)));
    };
    put32(0x46546C67);
    put32(2);
    put32(std::uint32_t(12 + 8 + json.size() + 8 + bin.size()));
    put32(std::uint32_t(json.size()));
    put32(0x4E4F534A);
    out.insert(out.end(), json.begin(), json.end());
    put32(std::uint32_t(bin.size()));
    put32(0x004E4942);
    out.insert(out.end(), bin.begin(), bin.end());
    return out;
}

}  // namespace fa
