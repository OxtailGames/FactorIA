// The files a model document's gameReady settings add to its bake: LOD .glbs, collider hull .glbs and a prefab that wires them to a
// MeshRenderer and a Collider3D (model_game_ready.h has the operations, model_doc_bake.cpp writes what this makes).
#include <cmath>

#include "fa/core/strings.h"
#include "fa/scene/model_game_ready.h"
#include "fa/tooling/model_bake.h"

namespace fa {

namespace {

double round5(double v) { return std::round(v * 1e5) / 1e5; }
Json vec(Vec3 v) { return Json::array({round5(v.x), round5(v.y), round5(v.z)}); }

std::string stem_of(const std::string& output) {
    return output.size() > 4 && to_lower(output.substr(output.size() - 4)) == ".glb"
               ? output.substr(0, output.size() - 4)
               : output;
}
std::string base_name(const std::string& path) {
    const auto slash = path.rfind('/');
    return slash == std::string::npos ? path : path.substr(slash + 1);
}

Result<ModelGameReady> settings_of(const ModelDoc& doc) {
    if (doc.gameReady.is_null()) return ModelGameReady{};
    return parse_game_ready(doc.gameReady, "/gameReady");
}

}  // namespace

std::vector<std::string> model_expected_extras(const ModelDoc& doc, const std::string& output) {
    std::vector<std::string> out;
    auto g = settings_of(doc);
    if (!g.ok()) return out;
    const std::string stem = stem_of(output);
    for (std::size_t i = 0; i < g->lods.size(); ++i) out.push_back(stem + ".lod" + std::to_string(i + 1) + ".glb");
    if (g->collider.shape == "convex") out.push_back(stem + ".collider.glb");
    if (!g->lods.empty() || g->collider.shape != "none") out.push_back(stem + ".prefab.json");
    return out;
}

Result<ModelGameReadyFiles> model_game_ready_files(const ModelDoc& doc, const ModelBuild& build,
                                                   const std::string& output) {
    ModelGameReadyFiles files;
    files.mesh = build.data;
    if (doc.gameReady.is_null()) return files;
    auto settings = settings_of(doc);
    if (!settings.ok()) return settings.error();
    if (settings->is_default()) return files;
    auto made = make_game_ready(build.data, *settings);
    if (!made.ok()) return made.error();
    files.mesh = made->mesh;
    files.report = game_ready_report_json(*made, *settings);
    files.warnings = made->warnings;
    const std::string stem = stem_of(output);

    Json meshRenderer = Json::object({{"mesh", output}});
    Json lods = Json::array();
    for (std::size_t i = 0; i < made->lods.size(); ++i) {
        const std::string path = stem + ".lod" + std::to_string(i + 1) + ".glb";
        auto bytes = mesh_to_glb(made->lods[i], path);
        if (!bytes.ok())
            return make_error("cannot write LOD" + std::to_string(i + 1) + ": " + bytes.error().message,
                              bytes.error().hint);
        files.glbs.emplace_back(path, std::move(*bytes));
        lods.push_back(Json::object({{"mesh", path}, {"distance", round5(made->lodInfo[i + 1].distance)}}));
    }
    if (!lods.empty()) meshRenderer["lods"] = lods;

    const ModelCollider& c = made->collider;
    Json components = Json::object({{"MeshRenderer", meshRenderer}});
    Json children = Json::array();
    auto hull_file = [&](const ModelHull& h, const std::string& path) -> Result<void> {
        auto bytes = mesh_to_glb(model_hull_mesh(h), path);
        if (!bytes.ok()) return make_error("cannot write the collider: " + bytes.error().message, bytes.error().hint);
        files.glbs.emplace_back(path, std::move(*bytes));
        return {};
    };
    if (c.shape == "box") {
        components["Collider3D"] = Json::object({{"shape", "box"}, {"size", vec(c.size)}, {"offset", vec(c.center)}});
    } else if (c.shape == "sphere") {
        components["Collider3D"] =
            Json::object({{"shape", "sphere"}, {"radius", round5(c.radius)}, {"offset", vec(c.center)}});
    } else if (c.shape == "capsule") {
        components["Collider3D"] = Json::object({{"shape", "capsule"},
                                                 {"radius", round5(c.radius)},
                                                 {"height", round5(c.height)},
                                                 {"offset", vec(c.center)}});
    } else if (c.shape == "convex" && c.hulls.size() == 1) {
        const std::string path = stem + ".collider.glb";
        if (auto r = hull_file(c.hulls[0], path); !r.ok()) return r.error();
        components["Collider3D"] = Json::object({{"shape", "convex"}, {"mesh", path}});
    } else if (c.shape == "decomposed") {
        for (std::size_t i = 0; i < c.hulls.size(); ++i) {
            const std::string path = stem + ".collider" + std::to_string(i + 1) + ".glb";
            if (auto r = hull_file(c.hulls[i], path); !r.ok()) return r.error();
            children.push_back(Json::object(
                {{"name", "collider_" + std::to_string(i + 1)},
                 {"components", Json::object({{"Collider3D", Json::object({{"shape", "convex"}, {"mesh", path}})}})}}));
        }
    }
    if (!lods.empty() || c.shape != "none") {
        Json entity = Json::object({{"name", base_name(stem)}, {"components", components}});
        if (!children.empty()) entity["children"] = children;
        files.prefabPath = stem + ".prefab.json";
        files.prefabText = dump_json(Json::object({{"format", "factoria.prefab/1"}, {"entity", entity}}));
    }
    return files;
}

}  // namespace fa
