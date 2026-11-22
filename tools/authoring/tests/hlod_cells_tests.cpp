// M75 P1e: world.bake_cell_hlods merges the meshes of every cell of a world index into one simplified .glb in the space of the
// cell's corner and names it in the index (docs/BIG_WORLDS_STREAMING.md, "HLOD proxies"). The files are deterministic byte for byte,
// the index stays a valid index, a refused call writes nothing and the errors teach with a JSON pointer.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>

#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/world_index.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct CellsProject {
    stdfs::path dir;
    CellsProject() {
        authoring::install();
        dir = fs::make_temp_dir("fa_hlod_cells").value();
        write("factoria.json",
              R"({"format":"factoria.project/1","name":"HlodCells","id":"com.example.hlodcells","mainScene":"scenes/main.scene.json",
                  "display":{"width":320,"height":180}})");
        write("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
        write("worlds/town.world.json", R"({
  "format": "factoria.world/1", "version": 1, "dimension": "3d", "cellSize": 100, "origin": [0, 0],
  "cells": [
    {"coord": [0, 0], "scene": "cells/0_0.scene.json", "bounds": {"min": [0, 0, 0], "max": [100, 5, 100]}},
    {"coord": [1, 0], "scene": "cells/1_0.scene.json", "bounds": {"min": [100, 0, 0], "max": [200, 5, 100]}, "sizeBytes": 321},
    {"coord": [0, 1], "scene": "cells/0_1.scene.json", "bounds": {"min": [0, 0, 100], "max": [100, 5, 200]}}
  ]
})");
        write("cells/0_0.scene.json", R"({"format":"factoria.scene/1","entities":[
  {"id":"a","components":{"Transform":{"position":[10,0.5,10]},"MeshRenderer":{"mesh":"cube"}}},
  {"id":"b","components":{"Transform":{"position":[40,1,50]},"MeshRenderer":{"mesh":"sphere","color":[0.8,0.2,0.2,1]}}},
  {"id":"hidden","active":false,"components":{"Transform":{"position":[90,1,90]},"MeshRenderer":{"mesh":"cube"}}}
]})");
        write("cells/1_0.scene.json", R"({"format":"factoria.scene/1","entities":[
  {"id":"c","components":{"Transform":{"position":[150,1,20],"scale":[2,2,2]},"MeshRenderer":{"mesh":"cube"}},"children":[
    {"id":"d","components":{"Transform":{"position":[0,1,0]},"MeshRenderer":{"mesh":"sphere"}}}]}
]})");
        write("cells/0_1.scene.json", R"({"format":"factoria.scene/1","entities":[
  {"id":"marker","components":{"Transform":{"position":[50,0,150]}}}
]})");
    }
    ~CellsProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    void write(const std::string& rel, const std::string& text) const {
        stdfs::create_directories((dir / rel).parent_path());
        std::ofstream(dir / rel, std::ios::binary) << text;
    }
    std::string read(const std::string& rel) const {
        std::ifstream in(dir / rel, std::ios::binary);
        return std::string(std::istreambuf_iterator<char>(in), {});
    }
    EngineConfig config() const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        c.memoryStorage = true;
        c.jobThreads = "0";
        c.scene = "scenes/main.scene.json";
        return c;
    }
};

Json call(Engine& e, const Json& args) {
    auto r = e.commands().call("world.bake_cell_hlods", args);
    INFO(args.dump() << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

std::string error_text(Engine& e, const Json& args) {
    auto r = e.commands().call("world.bake_cell_hlods", args);
    INFO(args.dump());
    REQUIRE_FALSE(r.ok);
    return r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string());
}

Json world_arg(Json extra = Json::object()) {
    extra["world"] = "worlds/town.world.json";
    return extra;
}

}  // namespace

TEST_CASE("world.bake_cell_hlods: is registered, documented and an edit of the project") {
    CellsProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("world.bake_cell_hlods");
    REQUIRE(info != nullptr);
    CHECK(info->category == "world");
    CHECK_FALSE(info->readOnly);
    CHECK(info->capabilitiesDeclared);
    CHECK(info->description.find("Example:") != std::string::npos);
    CHECK(info->description.find("hlod") != std::string::npos);
    for (const char* arg : {"world", "outDir", "cells", "ratio", "maxError", "maxDistance", "dryRun"}) {
        INFO(arg);
        REQUIRE(info->inputSchema["properties"].contains(arg));
        CHECK_FALSE(info->inputSchema["properties"][arg].value("description", std::string()).empty());
    }
}

TEST_CASE("world.bake_cell_hlods: bakes one proxy per cell in the cell's corner space and names it in the index") {
    CellsProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const Json r = call(e, world_arg(Json::object({{"ratio", 0.5}, {"maxDistance", 900}})));
    CHECK(r["cellsBaked"] == 2);
    CHECK(r["outDir"] == "worlds/town_hlod");
    CHECK(r["dryRun"] == false);
    REQUIRE(r["cellsSkipped"].size() == 1);  // the cell with no mesh keeps what it has
    CHECK(r["cellsSkipped"][0]["coord"] == Json::array({0, 1}));
    CHECK(r["triangles"].get<int>() > 0);
    CHECK(r["triangles"].get<int>() < r["trianglesBefore"].get<int>());
    CHECK(stdfs::exists(p.dir / "worlds/town_hlod/0_0.glb"));
    CHECK(stdfs::exists(p.dir / "worlds/town_hlod/1_0.glb"));
    CHECK_FALSE(stdfs::exists(p.dir / "worlds/town_hlod/0_1.glb"));

    // Cell [1, 0] starts at x 100: its cube at x 150 (2 m wide, scale 2 => 2 m) is at 49..51 in the corner's space, not at 149..151.
    auto g = read_gltf_mesh("worlds/town_hlod/1_0.glb");
    REQUIRE_MESSAGE(g.ok(), (g.ok() ? std::string() : g.error().message));
    CHECK(g.value().data.bmin.x == doctest::Approx(49.0f).epsilon(0.05));
    CHECK(g.value().data.bmax.x == doctest::Approx(51.0f).epsilon(0.05));
    // Cell [0, 0]: the inactive cube is left out (skipped counted), so the mesh stops at the sphere (x 40.5 at most).
    auto g0 = read_gltf_mesh("worlds/town_hlod/0_0.glb");
    REQUIRE(g0.ok());
    CHECK(g0.value().data.bmax.x < 41.5f);
    CHECK(r["baked"][0]["skipped"] == 1);

    // The index names the proxies, keeps what it had and is still a valid index with its files in place.
    std::vector<WorldIndexIssue> issues;
    auto index = load_world_index("worlds/town.world.json", {}, &issues);
    REQUIRE_MESSAGE(index.ok(), (index.ok() ? std::string() : index.error().message));
    CHECK(issues.empty());
    CHECK(index.value().find(0, 0)->hlod == "worlds/town_hlod/0_0.glb");
    CHECK(index.value().find(1, 0)->hlod == "worlds/town_hlod/1_0.glb");
    CHECK(index.value().find(1, 0)->hlodMaxDistance == 900.0);
    CHECK(index.value().find(1, 0)->sizeBytes == 321);
    CHECK(index.value().find(0, 1)->hlod.empty());
    CHECK(r["indexWritten"] == "worlds/town.world.json");
}

TEST_CASE("world.bake_cell_hlods: the same arguments write the same bytes, and a second run changes nothing") {
    CellsProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    call(e, world_arg(Json::object({{"ratio", 0.25}, {"outDir", "out/a"}})));
    const std::string indexA = p.read("worlds/town.world.json");
    call(e, world_arg(Json::object({{"ratio", 0.25}, {"outDir", "out/b"}})));
    CHECK(p.read("out/a/0_0.glb") == p.read("out/b/0_0.glb"));
    CHECK(p.read("out/a/1_0.glb") == p.read("out/b/1_0.glb"));
    CHECK_FALSE(p.read("out/a/0_0.glb").empty());
    // the index of the second run names the second folder; baking the first folder again gives the first index back byte for byte
    CHECK(p.read("worlds/town.world.json") != indexA);
    call(e, world_arg(Json::object({{"ratio", 0.25}, {"outDir", "out/a"}})));
    CHECK(p.read("worlds/town.world.json") == indexA);
}

TEST_CASE("world.bake_cell_hlods: `cells` bakes only those, and dryRun reports without writing") {
    CellsProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const std::string before = p.read("worlds/town.world.json");
    const Json dry = call(e, world_arg(Json::object({{"dryRun", true}})));
    CHECK(dry["dryRun"] == true);
    CHECK(dry["cellsBaked"] == 2);
    CHECK(dry["baked"][0]["triangles"].get<int>() > 0);
    CHECK(dry["written"].empty());
    CHECK_FALSE(stdfs::exists(p.dir / "worlds/town_hlod"));
    CHECK(p.read("worlds/town.world.json") == before);

    const Json one = call(e, world_arg(Json::object({{"cells", Json::array({Json::array({1, 0})})}})));
    CHECK(one["cellsBaked"] == 1);
    CHECK(stdfs::exists(p.dir / "worlds/town_hlod/1_0.glb"));
    CHECK_FALSE(stdfs::exists(p.dir / "worlds/town_hlod/0_0.glb"));
    auto index = load_world_index("worlds/town.world.json");
    REQUIRE(index.ok());
    CHECK(index.value().find(0, 0)->hlod.empty());
    CHECK(index.value().find(1, 0)->hlod == "worlds/town_hlod/1_0.glb");
    // the {i, j} form works too
    const Json obj = call(e, world_arg(Json::object({{"cells", Json::array({Json::object({{"i", 0}, {"j", 0}})})}})));
    CHECK(obj["cellsBaked"] == 1);
}

TEST_CASE("world.bake_cell_hlods: a refused call names its JSON pointer and writes nothing") {
    CellsProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const std::string before = p.read("worlds/town.world.json");
    std::string t = error_text(e, Json::object());
    CHECK(t.find("world") != std::string::npos);  // the schema's `required` or the command's own check names it
    t = error_text(e, Json::object({{"world", "worlds/none.world.json"}}));
    CHECK(t.find("none.world.json") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"cells", Json::array({Json::array({7, 7})})}})));
    CHECK(t.find("/cells/0") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"cells", Json::array({Json::array({0, 0}), Json::array({0, 0})})}})));
    CHECK(t.find("/cells/1") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"cells", Json::array({"0,0"})}})));
    CHECK(t.find("/cells/0") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"ratio", 1.5}})));
    CHECK(t.find("/ratio") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"maxError", -1}})));
    CHECK(t.find("/maxError") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"maxDistance", -5}})));
    CHECK(t.find("/maxDistance") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"outDir", "../outside"}})));
    CHECK(t.find("/outDir") != std::string::npos);
    t = error_text(e, world_arg(Json::object({{"outdir", "x"}})));
    CHECK(t.find("/outdir") != std::string::npos);
    CHECK(p.read("worlds/town.world.json") == before);
    CHECK_FALSE(stdfs::exists(p.dir / "worlds/town_hlod"));
    CHECK_FALSE(stdfs::exists(p.dir.parent_path() / "outside"));

    // A cell scene that cannot be read stops the command before any file is written.
    p.write("cells/1_0.scene.json", "{ not json");
    t = error_text(e, world_arg());
    CHECK(t.find("1_0.scene.json") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.dir / "worlds/town_hlod"));
    CHECK(p.read("worlds/town.world.json") == before);
}

TEST_CASE("world.bake_cell_hlods: a proxy file that cannot be written leaves the index as it was") {
    CellsProject p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const std::string before = p.read("worlds/town.world.json");
    // A folder where the second file goes: the write fails after the first one was written.
    stdfs::create_directories(p.dir / "worlds/town_hlod/1_0.glb");
    auto r = e.commands().call("world.bake_cell_hlods", world_arg());
    REQUIRE_FALSE(r.ok);
    CHECK(r.error.value("message", std::string()).find("1_0.glb") != std::string::npos);
    CHECK(r.error.value("message", std::string()).find("index is unchanged") != std::string::npos);
    CHECK(p.read("worlds/town.world.json") == before);
}
