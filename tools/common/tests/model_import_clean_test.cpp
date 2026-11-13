// model.import_clean (assets_model_import.cpp) and the `mesh` operation it relies on: a deliberately dirty glTF (a soup of duplicate vertices, a
// floating speck, an offset, centimetres, one flipped triangle) becomes a model document that reads the cleaned mesh and bakes, with a report that
// teaches. The mesh work itself is tested in engine/scene/tests/test_model_import_clean.cpp.
#include <doctest.h>

#include <cstring>

#include "asset_test_helpers.h"
#include "fa/core/json_schema.h"
#include "fa/scene/model_doc.h"
#include "fa/tooling/model_bake.h"

using namespace fa;
using namespace fa::testing;

namespace {

// Writes `<rel>` (.gltf) and its .bin: a 100 x 180 x 100 box as a 36-vertex soup moved 300 along x, a flipped triangle and a speck 4 m up. Centimetres.
void write_dirty_gltf(const AssetsProject& p, const std::string& rel, bool withUv = false) {
    const float P[8][3] = {{-50, 0, -50}, {50, 0, -50}, {50, 180, -50}, {-50, 180, -50},
                           {-50, 0, 50},  {50, 0, 50},  {50, 180, 50},  {-50, 180, 50}};
    const int F[12][3] = {{0, 2, 1}, {0, 3, 2}, {4, 5, 6}, {4, 6, 7}, {0, 1, 5}, {0, 5, 4},
                          {2, 3, 7}, {2, 7, 6}, {1, 2, 6}, {1, 6, 5}, {3, 0, 4}, {3, 4, 7}};
    std::vector<float> pos, uv;
    auto add = [&](float x, float y, float z) {
        pos.insert(pos.end(), {x, y, z});
        uv.insert(uv.end(), {float((pos.size() / 3) % 7) / 7.0f, float((pos.size() / 3) % 5) / 5.0f});
    };
    for (int t = 0; t < 12; ++t) {
        int a = F[t][0], b = F[t][1], c = F[t][2];
        if (t == 5) std::swap(b, c);
        for (int v : {a, b, c}) add(P[v][0] + 300, P[v][1], P[v][2]);
    }
    const float S[4][3] = {{300, 580, 0}, {301, 580, 0}, {300, 581, 0}, {300, 580, 1}};
    const int T[4][3] = {{0, 2, 1}, {0, 1, 3}, {0, 3, 2}, {1, 2, 3}};
    for (const auto& t : T)
        for (int v : t) add(S[v][0], S[v][1], S[v][2]);
    const std::size_t n = pos.size() / 3;
    std::vector<std::uint32_t> idx(n);
    for (std::size_t i = 0; i < n; ++i) idx[i] = std::uint32_t(i);
    std::string bin(reinterpret_cast<const char*>(pos.data()), pos.size() * 4);
    const std::size_t uvOff = bin.size();
    if (withUv) bin.append(reinterpret_cast<const char*>(uv.data()), uv.size() * 4);
    const std::size_t idxOff = bin.size();
    bin.append(reinterpret_cast<const char*>(idx.data()), idx.size() * 4);
    float mn[3] = {1e9f, 1e9f, 1e9f}, mx[3] = {-1e9f, -1e9f, -1e9f};
    for (std::size_t i = 0; i < n; ++i)
        for (int k = 0; k < 3; ++k) {
            mn[k] = std::min(mn[k], pos[i * 3 + std::size_t(k)]);
            mx[k] = std::max(mx[k], pos[i * 3 + std::size_t(k)]);
        }
    const std::string binName = rel.substr(rel.rfind('/') + 1, rel.size() - rel.rfind('/') - 6) + ".bin";
    Json attrs = Json::object({{"POSITION", 0}});
    Json views = Json::array({Json::object({{"buffer", 0}, {"byteOffset", 0}, {"byteLength", pos.size() * 4}})});
    Json accessors = Json::array({Json::object({{"bufferView", 0},
                                                {"componentType", 5126},
                                                {"count", n},
                                                {"type", "VEC3"},
                                                {"min", Json::array({mn[0], mn[1], mn[2]})},
                                                {"max", Json::array({mx[0], mx[1], mx[2]})}})});
    if (withUv) {
        attrs["TEXCOORD_0"] = 1;
        views.push_back(Json::object({{"buffer", 0}, {"byteOffset", uvOff}, {"byteLength", uv.size() * 4}}));
        accessors.push_back(Json::object({{"bufferView", 1}, {"componentType", 5126}, {"count", n}, {"type", "VEC2"}}));
    }
    views.push_back(Json::object({{"buffer", 0}, {"byteOffset", idxOff}, {"byteLength", idx.size() * 4}}));
    accessors.push_back(
        Json::object({{"bufferView", views.size() - 1}, {"componentType", 5125}, {"count", n}, {"type", "SCALAR"}}));
    const Json g = Json::object(
        {{"asset", Json::object({{"version", "2.0"}})},
         {"scene", 0},
         {"scenes", Json::array({Json::object({{"nodes", Json::array({0})}})})},
         {"nodes", Json::array({Json::object({{"mesh", 0}})})},
         {"meshes",
          Json::array({Json::object(
              {{"primitives", Json::array({Json::object(
                                  {{"attributes", attrs}, {"indices", accessors.size() - 1}, {"material", 0}})})}})})},
         {"materials", Json::array({Json::object(
                           {{"name", "skin"},
                            {"pbrMetallicRoughness", Json::object({{"baseColorFactor", Json::array({0.8, 0.5, 0.3, 1})},
                                                                   {"roughnessFactor", 0.7}})}})})},
         {"buffers", Json::array({Json::object({{"uri", binName}, {"byteLength", bin.size()}})})},
         {"bufferViews", views},
         {"accessors", accessors}});
    write_all(p.file(rel.substr(0, rel.rfind('/') + 1) + binName), bin);
    write_all(p.file(rel), g.dump());
}

}  // namespace

TEST_CASE("model.import_clean: a dirty glTF becomes a baked model document that reads the cleaned mesh, with a "
          "teaching report") {
    AssetsProject p;
    write_dirty_gltf(p, "assets/models/dirty.gltf");
    const Json r = p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"}, {"height", 1.8}});
    CHECK(r["path"] == "assets/models/dirty_clean.model.json");
    CHECK(r["mesh"] == "assets/models/dirty_clean.mesh.glb");
    CHECK(r["output"] == "assets/models/dirty_clean.glb");
    CHECK(r["bake"]["state"] == "baked");
    CHECK(p.exists("assets/models/dirty_clean.glb"));
    CHECK(read_all(p.file("assets/models/dirty_clean.mesh.glb")).substr(0, 4) == "glTF");

    const Json& rep = r["report"];
    CHECK(rep["before"]["triangles"] == 16);
    CHECK(rep["after"]["triangles"] == 12);
    CHECK(rep["pieces"]["removed"] == 1);
    CHECK(rep["pieces"]["list"][0]["triangles"] == 4);
    CHECK(rep["weld"]["verticesMerged"].get<int>() > 0);
    CHECK(rep["trianglesReoriented"] == 1);
    CHECK(rep["scale"]["factor"].get<double>() == doctest::Approx(0.01));
    CHECK(rep["scale"]["reason"].get<std::string>().find("height 1.8 m") != std::string::npos);
    CHECK(rep["nonManifoldEdgesFixed"].get<int>() > 0);
    CHECK(rep["after"]["surface"]["closed"] == true);
    CHECK(rep["after"]["size"][1].get<double>() == doctest::Approx(1.8));
    CHECK(rep["budget"].size() == 3);
    CHECK(rep["budget"][0]["fits"] == true);
    CHECK(r["summary"].get<std::string>().find("16 -> 12 triangles") != std::string::npos);

    // the document: a mesh node, the source material, an unwrap (the source had no uvs)
    const Json doc = parse_json(read_all(p.file("assets/models/dirty_clean.model.json")), "doc").value();
    CHECK(doc["nodes"][0]["op"] == "mesh");
    CHECK(doc["nodes"][0]["source"] == "assets/models/dirty_clean.mesh.glb");
    CHECK(doc["materials"].contains("skin"));
    CHECK(doc["uv"]["method"] == "unwrap");
    const Json info = p.ok("model.info", {{"path", "assets/models/dirty_clean.model.json"}});
    CHECK(info["valid"] == true);
    CHECK(info["bake"]["state"] == "fresh");
    CHECK(info["measurements"]["triangles"] == 12);
    CHECK(info["measurements"]["bounds"]["min"][1].get<double>() == doctest::Approx(0.0).epsilon(0.001));
    CHECK(info["inputs"][0] == "assets/models/dirty_clean.mesh.glb");
    const Json recipe = p.manifest()["assets"]["assets/models/dirty_clean.glb"]["provenance"]["recipe"];
    bool readsMesh = false;
    for (const Json& in : recipe["inputs"]) readsMesh = readsMesh || in["path"] == "assets/models/dirty_clean.mesh.glb";
    CHECK(readsMesh);

    // later operations apply to it: a modifier node next to the mesh, edited by id
    p.ok("model.edit", {{"path", "assets/models/dirty_clean.model.json"},
                        {"op", "add"},
                        {"node", {{"op", "sphere"}, {"radius", 0.2}, {"position", {0, 2, 0}}}}});
    CHECK(
        p.ok("model.info", {{"path", "assets/models/dirty_clean.model.json"}})["measurements"]["triangles"].get<int>() >
        12);
    p.ok("model.game_ready",
         {{"path", "assets/models/dirty_clean.model.json"}, {"lods", Json::array({{{"ratio", 0.5}}})}});

    // the mesh file is an input: changing it makes the bake stale
    p.ok("model.bake", {{"path", "assets/models/dirty_clean.model.json"}});
    CHECK(p.ok("model.info", {{"path", "assets/models/dirty_clean.model.json"}})["bake"]["state"] == "fresh");
    std::string mesh = read_all(p.file("assets/models/dirty_clean.mesh.glb"));
    mesh.push_back(' ');
    write_all(p.file("assets/models/dirty_clean.mesh.glb"), mesh);
    CHECK(p.ok("model.info", {{"path", "assets/models/dirty_clean.model.json"}})["bake"]["state"] == "stale");
}

TEST_CASE(
    "model.import_clean: a source with uvs keeps them (no unwrap in auto), unwrap always replaces them and says so") {
    AssetsProject p;
    write_dirty_gltf(p, "assets/models/dirty.gltf", true);
    const Json kept = p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"}, {"scale", 0.01}});
    CHECK(kept["report"]["unwrapped"] == false);
    CHECK_FALSE(parse_json(read_all(p.file("assets/models/dirty_clean.model.json")), "d").value().contains("uv"));
    CHECK(kept["bake"]["state"] == "baked");
    const Json forced = p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"},
                                                    {"scale", 0.01},
                                                    {"unwrap", "always"},
                                                    {"overwrite", true},
                                                    {"texelsPerUnit", 64}});
    CHECK(forced["report"]["unwrapped"] == true);
    const Json doc = parse_json(read_all(p.file("assets/models/dirty_clean.model.json")), "d").value();
    CHECK(doc["uv"]["texelsPerUnit"] == 64);
    CHECK(forced["bake"]["state"] == "baked");
    const Json never =
        p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"}, {"unwrap", "never"}, {"overwrite", true}});
    CHECK(never["report"]["unwrapped"] == false);
}

TEST_CASE("model.import_clean: reference scales to a model's height, human is 1.8 m, remesh and platform budgets") {
    AssetsProject p;
    write_dirty_gltf(p, "assets/models/dirty.gltf");
    p.ok("model.create", {{"path", "assets/models/door.model.json"},
                          {"nodes", Json::array({{{"op", "box"}, {"size", {1, 2.5, 0.1}}}})}});
    const Json r = p.ok("model.import_clean",
                        {{"source", "assets/models/dirty.gltf"}, {"reference", "assets/models/door.model.json"}});
    CHECK(r["report"]["after"]["size"][1].get<double>() == doctest::Approx(2.5));
    CHECK(r["referenceHeight"]["metres"].get<double>() == doctest::Approx(2.5));
    const Json h = p.ok("model.import_clean",
                        {{"source", "assets/models/dirty.gltf"}, {"reference", "human"}, {"overwrite", true}});
    CHECK(h["report"]["after"]["size"][1].get<double>() == doctest::Approx(1.8));

    const Json rm = p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"},
                                                {"height", 1.8},
                                                {"remesh", true},
                                                {"remeshCells", 32},
                                                {"platform", "mobile"},
                                                {"triangles", 500},
                                                {"overwrite", true}});
    CHECK(rm["report"]["remesh"]["rawTriangles"].get<int>() > 500);
    CHECK(rm["report"]["after"]["triangles"].get<int>() <= 520);
    CHECK(rm["report"]["after"]["surface"]["closed"] == true);
    CHECK(rm["bake"]["state"] == "baked");
    CHECK(p.ok("model.info", {{"path", "assets/models/dirty_clean.model.json"}})["measurements"]["closed"] == true);
}

TEST_CASE("model.import_clean: a .obj goes through the importer, z-up is turned upright") {
    AssetsProject p;
    // a 1 x 1 x 3 column (z is its height), as a Blender export would be
    write_all(
        p.file("assets/models/column.obj"),
        "v 0 0 0\nv 1 0 0\nv 1 1 0\nv 0 1 0\nv 0 0 3\nv 1 0 3\nv 1 1 3\nv 0 1 3\n"
        "f 1 3 2\nf 1 4 3\nf 5 6 7\nf 5 7 8\nf 1 2 6\nf 1 6 5\nf 3 4 8\nf 3 8 7\nf 2 3 7\nf 2 7 6\nf 4 1 5\nf 4 5 8\n");
    const Json r = p.ok("model.import_clean", {{"source", "assets/models/column.obj"}, {"upAxis", "z"}});
    CHECK(r["converted"] == "assets/models/column.gltf");
    CHECK(p.exists("assets/models/column.gltf"));
    CHECK(r["report"]["after"]["size"][1].get<double>() == doctest::Approx(3.0));
    CHECK(r["report"]["after"]["size"][2].get<double>() == doctest::Approx(1.0));
    CHECK(r["report"]["after"]["surface"]["closed"] == true);
    // a second run reuses the converted file
    const Json again =
        p.ok("model.import_clean", {{"source", "assets/models/column.obj"}, {"upAxis", "z"}, {"overwrite", true}});
    CHECK(has_warning(again["report"], "already existed"));
}

TEST_CASE("model.import_clean: errors name the location, what is wrong and the fix") {
    AssetsProject p;
    write_dirty_gltf(p, "assets/models/dirty.gltf");
    auto fails = [&](const Json& args, const std::string& needle) {
        CommandResult r = p.call("model.import_clean", args);
        CHECK_FALSE(r.ok);
        const std::string text = r.error.dump();
        CHECK_MESSAGE(text.find(needle) != std::string::npos, text);
    };
    fails({{"source", "assets/models/dirt.gltf"}}, "dirty.gltf");  // did you mean
    fails({{"source", "assets/notes.txt"}}, ".glb, .gltf or .obj");
    fails({{"source", "assets/models/dirty.gltf"}, {"height", 1.8}, {"scale", 2}}, "only one of");
    fails({{"source", "assets/models/dirty.gltf"}, {"upAxis", "x"}}, "upAxis");
    fails({{"source", "assets/models/dirty.gltf"}, {"origin", "bottom-centre"}}, "bottom_center");  // did you mean
    fails({{"source", "assets/models/dirty.gltf"}, {"platform", "console"}}, "desktop");
    fails({{"source", "assets/models/dirty.gltf"}, {"reference", "assets/models/nothing.model.json"}}, "reference");
    fails({{"source", "assets/models/dirty.gltf"}, {"remeshCells", 4}}, "remeshCells");
    fails({{"source", "assets/models/dirty.gltf"}, {"nope", 1}}, "nope");
    const Json huge = p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"}});
    CHECK(has_warning(huge["report"],
                      "texels per metre"));  // a 180 m model gets a smaller unwrap resolution, not a minutes-long one
    fails({{"source", "assets/models/dirty.gltf"}}, "overwrite");
    // nothing but the bad request was written by the failures
    CHECK_FALSE(p.exists("assets/models/nope.model.json"));
}

TEST_CASE("model `mesh` operation: checked like any node, reads a project glb, tells the missing file") {
    AssetsProject p;
    write_dirty_gltf(p, "assets/models/dirty.gltf");
    p.ok("model.import_clean", {{"source", "assets/models/dirty.gltf"}, {"scale", 0.01}});
    // two copies of the mesh side by side in one model
    const Json r = p.ok(
        "model.create",
        {{"path", "assets/models/pair.model.json"},
         {"materials", {{"skin", {{"color", {1, 0, 0, 1}}}}}},
         {"nodes",
          Json::array({{{"op", "mesh"}, {"source", "assets/models/dirty_clean.mesh.glb"}, {"position", {-1, 0, 0}}},
                       {{"op", "mesh"},
                        {"source", "assets/models/dirty_clean.mesh.glb"},
                        {"position", {1, 0, 0}},
                        {"material", "skin"}}})}});
    CHECK(r["measurements"]["triangles"] == 24);
    CHECK(r["measurements"]["bounds"]["size"][0].get<double>() == doctest::Approx(3.0));
    // invalid: not a glb, not a project path, missing file
    std::vector<ModelIssue> issues;
    auto bad = parse_model_doc(
        parse_json(R"({"format":"factoria.model/1","nodes":[{"op":"mesh","source":"assets/a.png"}]})", "t").value(),
        "t.model.json", &issues);
    CHECK_FALSE(bad.ok());
    REQUIRE_FALSE(issues.empty());
    CHECK(issues[0].pointer == "/nodes/0/source");
    CHECK(issues[0].hint.find(".glb") != std::string::npos);
    issues.clear();
    auto outside = parse_model_doc(
        parse_json(R"({"format":"factoria.model/1","nodes":[{"op":"mesh","source":"../x.glb"}]})", "t").value(),
        "t.model.json", &issues);
    CHECK_FALSE(outside.ok());
    CHECK(issues[0].message.find("not inside the project") != std::string::npos);
    CommandResult missing =
        p.call("model.create", {{"path", "assets/models/gone.model.json"},
                                {"nodes", Json::array({{{"op", "mesh"}, {"source", "assets/models/none.glb"}}})}});
    CHECK(missing.result.dump().find("none.glb") != std::string::npos);
}
