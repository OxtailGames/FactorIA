// M75 P1d: world.bake_hlod merges the meshes under an entity into one simplified .glb and, with `apply`, sets LodGroup.hlodProxy on it
// (docs/BIG_WORLDS_LOD.md, "HLOD proxy"). The merge keeps the materials as submeshes, the output is deterministic byte for byte, the
// errors teach with a JSON pointer, and a refused call writes nothing.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>

#include "fa/authoring/authoring.h"
#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"
#include "fa/scene/components_world.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/serialize.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Project {
    stdfs::path dir;
    Project() {
        authoring::install();
        dir = fs::make_temp_dir("fa_hlod").value();
        write(
            "factoria.json",
            R"({"format":"factoria.project/1","name":"Hlod","id":"com.example.hlod","mainScene":"scenes/town.scene.json",
                  "display":{"width":320,"height":180}})");
        write("scenes/town.scene.json", R"({
  "format": "factoria.scene/1",
  "entities": [
    {"id": "block", "name": "block", "components": {"Transform": {"position": [10, 0, 5]}}, "children": [
      {"id": "wall", "name": "wall", "components": {"Transform": {"position": [0, 1, 0], "scale": [2, 2, 2]}, "MeshRenderer": {"mesh": "cube"}}},
      {"id": "dome", "name": "dome", "components": {"Transform": {"position": [3, 1, 0]}, "MeshRenderer": {"mesh": "sphere", "color": [0.8, 0.2, 0.2, 1]}}},
      {"id": "hidden", "name": "hidden", "active": false, "components": {"Transform": {"position": [0, 5, 0]}, "MeshRenderer": {"mesh": "cube"}}}
    ]},
    {"id": "cell", "name": "cell", "components": {"Transform": {"position": [50, 0, 0]}}, "children": [
      {"id": "lod0", "name": "lod0", "components": {"Transform": {}}, "children": [
        {"id": "cell_wall", "name": "cell_wall", "components": {"Transform": {"position": [0, 1, 0]}, "MeshRenderer": {"mesh": "cube"}}},
        {"id": "cell_dome", "name": "cell_dome", "components": {"Transform": {"position": [3, 1, 0]}, "MeshRenderer": {"mesh": "sphere"}}}
      ]}
    ]},
    {"id": "group", "name": "group", "components": {"Transform": {"position": [90, 0, 0]}, "LodGroup": {"thresholds": [40]}, "MeshRenderer": {"mesh": "cube"}}, "children": [
      {"id": "near", "name": "near", "components": {"Transform": {}, "MeshRenderer": {"mesh": "sphere"}}},
      {"id": "far", "name": "far", "components": {"Transform": {"position": [0, 0, 20]}, "MeshRenderer": {"mesh": "cube"}}}
    ]},
    {"id": "empty", "name": "empty", "components": {"Transform": {}}}
  ]
})");
    }
    ~Project() {
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
        c.scene = "scenes/town.scene.json";
        return c;
    }
};

Json call(Engine& e, const std::string& name, const Json& args) {
    auto r = e.commands().call(name, args);
    INFO(name << " " << args.dump() << " -> " << r.error.dump());
    REQUIRE(r.ok);
    return r.result;
}

std::string error_text(Engine& e, const Json& args) {
    auto r = e.commands().call("world.bake_hlod", args);
    INFO(args.dump());
    REQUIRE_FALSE(r.ok);
    return r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string());
}

}  // namespace

TEST_CASE("world.bake_hlod: is registered, documented and an edit of the project") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const CommandInfo* info = e.commands().info("world.bake_hlod");
    REQUIRE(info != nullptr);
    CHECK(info->category == "world");
    CHECK_FALSE(info->readOnly);
    CHECK(info->description.find("LodGroup.hlodProxy") != std::string::npos);
    CHECK(info->description.find("Example:") != std::string::npos);
    CHECK(info->capabilitiesDeclared);
}

TEST_CASE(
    "world.bake_hlod: merges the meshes under the entity, keeps the materials and writes a .glb that loads back") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const Json r = call(e, "world.bake_hlod",
                        Json::object({{"entity", "block"}, {"out", "assets/hlod/block.glb"}, {"ratio", 0.5}}));
    CHECK(r["saved"] == "assets/hlod/block.glb");
    CHECK(r["meshes"] == 2);  // the inactive one is skipped
    CHECK(r["skipped"] == 1);
    CHECK(r["skippedList"][0]["entity"] == "hidden");
    CHECK(r["applied"] == false);
    CHECK(r["submeshes"] == 2);  // the cube's and the sphere's material
    CHECK(r["triangles"].get<int>() > 0);
    CHECK(r["triangles"].get<int>() < r["trianglesBefore"].get<int>());
    CHECK(stdfs::exists(p.dir / "assets/hlod/block.glb"));

    auto g = read_gltf_mesh("assets/hlod/block.glb");
    REQUIRE_MESSAGE(g.ok(), (g.ok() ? std::string() : g.error().message));
    CHECK(g.value().data.triangle_count() == r["triangles"].get<std::size_t>());
    // In the entity's local space: the block is at (10, 0, 5), the wall at its local (0, 1, 0) with scale 2 and the dome 3 m to the side
    // (the simplifier may collapse an extreme vertex of the sphere, so the bounds are ranges: what matters is that they are the block's own
    // 1 m left of the wall and not the scene's 10 m)
    CHECK(g.value().data.bmin.x > -1.2f);
    CHECK(g.value().data.bmin.x < 0.0f);
    CHECK(g.value().data.bmax.x > 2.5f);
    CHECK(g.value().data.bmax.x < 3.6f);
    CHECK(g.value().data.bmax.y > 1.5f);
    CHECK(g.value().data.bmax.y < 2.1f);
    // The scene is not changed without `apply`
    CHECK(e.world().get<LodGroup>(e.world().find_by_id("block")) == nullptr);
}

TEST_CASE("world.bake_hlod: the same arguments write the same bytes, in the open scene and from the scene file") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    call(e, "world.bake_hlod", Json::object({{"entity", "block"}, {"out", "assets/a.glb"}, {"ratio", 0.25}}));
    call(e, "world.bake_hlod", Json::object({{"entity", "block"}, {"out", "assets/b.glb"}, {"ratio", 0.25}}));
    const Json r =
        call(e, "world.bake_hlod",
             Json::object(
                 {{"scene", "scenes/town.scene.json"}, {"root", "block"}, {"out", "assets/c.glb"}, {"ratio", 0.25}}));
    CHECK(r["meshes"] == 2);
    const std::string a = p.read("assets/a.glb");
    REQUIRE_FALSE(a.empty());
    CHECK(a == p.read("assets/b.glb"));
    CHECK(a == p.read("assets/c.glb"));
    // another ratio is another mesh
    call(e, "world.bake_hlod", Json::object({{"entity", "block"}, {"out", "assets/d.glb"}, {"ratio", 0.9}}));
    CHECK(a != p.read("assets/d.glb"));
    // maxError alone works too, and a baked proxy can itself be merged under another entity
    const Json m =
        call(e, "world.bake_hlod", Json::object({{"entity", "block"}, {"out", "assets/e.glb"}, {"maxError", 0.5}}));
    CHECK(m["triangles"].get<int>() > 0);
}

TEST_CASE("world.bake_hlod: apply sets LodGroup.hlodProxy and a default threshold, and keeps a threshold already set") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const Entity block = e.world().find_by_id("cell");
    REQUIRE(e.world().alive(block));
    const Json r = call(e, "world.bake_hlod",
                        Json::object({{"entity", "cell"}, {"out", "assets/hlod/block.glb"}, {"apply", true}}));
    CHECK(r["applied"] == true);
    const LodGroup* lg = e.world().get<LodGroup>(block);
    REQUIRE(lg != nullptr);
    CHECK(lg->hlodProxy == "assets/hlod/block.glb");
    CHECK(lg->hlodThreshold > 0.0f);
    CHECK(lg->hlodThreshold == doctest::Approx(r["hlodThreshold"].get<float>()));
    // a threshold the author chose stays; a second bake changes the proxy only
    e.world().get<LodGroup>(block)->hlodThreshold = 77.0f;
    call(e, "world.bake_hlod", Json::object({{"entity", "cell"}, {"out", "assets/hlod/block2.glb"}, {"apply", true}}));
    CHECK(e.world().get<LodGroup>(block)->hlodProxy == "assets/hlod/block2.glb");
    CHECK(e.world().get<LodGroup>(block)->hlodThreshold == 77.0f);
}

TEST_CASE(
    "world.bake_hlod: apply refuses an entity with several children and no LodGroup, and tells how to wrap them") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const std::string t =
        error_text(e, Json::object({{"entity", "block"}, {"out", "assets/hlod/block.glb"}, {"apply", true}}));
    CHECK(t.find("/apply") != std::string::npos);
    CHECK(t.find("LOD levels") != std::string::npos);
    CHECK(t.find("ONE child entity") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.dir / "assets"));  // nothing is written
    CHECK(e.world().get<LodGroup>(e.world().find_by_id("block")) == nullptr);
    // without `apply` the same entity bakes (the children are merged), and the cell with ONE child accepts `apply`
    call(e, "world.bake_hlod", Json::object({{"entity", "block"}, {"out", "assets/hlod/block.glb"}}));
    CHECK(stdfs::exists(p.dir / "assets/hlod/block.glb"));
}

TEST_CASE("world.bake_hlod: under a LodGroup only child 0 is merged, and the entity's own MeshRenderer is left out") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const Json r = call(e, "world.bake_hlod", Json::object({{"entity", "group"}, {"out", "assets/hlod/group.glb"}}));
    CHECK(r["meshes"] == 1);  // `near` (a sphere): not `far` (level 1) and not the group's own cube
    CHECK(r["levelsIgnored"] == 1);
    CHECK(r["skippedList"][0]["entity"] == "group");
    // apply is allowed on an entity that is already a group, whatever its children
    const Json a = call(e, "world.bake_hlod",
                        Json::object({{"entity", "group"}, {"out", "assets/hlod/group2.glb"}, {"apply", true}}));
    CHECK(a["applied"] == true);
    const LodGroup* lg = e.world().get<LodGroup>(e.world().find_by_id("group"));
    REQUIRE(lg != nullptr);
    CHECK(lg->thresholds.size() == 1);
    CHECK(lg->hlodProxy == "assets/hlod/group2.glb");
    // The default threshold never lies before the group's own last one: this group's is 40 m and its proxy is small, so 8 times its size is
    // under 60 m (1.5 times 40).
    CHECK(lg->hlodThreshold == doctest::Approx(60.0f));
}

TEST_CASE("world.bake_hlod: the default threshold of a ScreenSize group stays under its smallest threshold") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    const Entity group = e.world().find_by_id("group");
    REQUIRE(e.world().alive(group));
    e.world().get<LodGroup>(group)->mode = LodMode::ScreenSize;
    e.world().get<LodGroup>(group)->thresholds = {0.3f, 0.02f};  // the last level starts below 2% of the screen
    call(e, "world.bake_hlod", Json::object({{"entity", "group"}, {"out", "assets/hlod/group3.glb"}, {"apply", true}}));
    CHECK(e.world().get<LodGroup>(group)->hlodThreshold == doctest::Approx(0.02f / 1.5f).epsilon(0.001));
}

TEST_CASE("world.bake_hlod: what apply sets is a scene change, so restoring the snapshot taken before takes it back") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    // The editor's Console takes this snapshot before the command and loads it back on Undo (the .glb stays on disk).
    const Json before = snapshot_scene(e.world());
    call(e, "world.bake_hlod", Json::object({{"entity", "cell"}, {"out", "assets/hlod/undo.glb"}, {"apply", true}}));
    REQUIRE(e.world().get<LodGroup>(e.world().find_by_id("cell")) != nullptr);
    e.world().clear();
    load_scene(e.world(), before, "undo");
    const Entity cell = e.world().find_by_id("cell");
    REQUIRE(e.world().alive(cell));
    CHECK(e.world().get<LodGroup>(cell) == nullptr);
    CHECK(stdfs::exists(p.dir / "assets/hlod/undo.glb"));
}

TEST_CASE("world.bake_hlod: errors teach, with the JSON pointer and the fix, and write nothing") {
    Project p;
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(p.config(), nullptr, &err), err);
    std::string t = error_text(e, Json::object({{"entity", "empty"}, {"out", "assets/x.glb"}}));
    CHECK(t.find("No meshes to merge under 'empty'") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "block"}, {"out", "assets/x.glb"}, {"ratio", 0}}));
    CHECK(t.find("/ratio") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "block"}, {"out", "assets/x.glb"}, {"ratio", 1.5}}));
    CHECK(t.find("ratio") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "block"}, {"out", "assets/x.glb"}, {"maxError", -2}}));
    CHECK(t.find("/maxError") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "block"}, {"out", "assets/x.txt"}}));
    CHECK(t.find("/out") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "block"}, {"out", "../outside.glb"}}));
    CHECK(t.find("/out") != std::string::npos);
    t = error_text(e,
                   Json::object({{"entity", "block"}, {"scene", "scenes/town.scene.json"}, {"out", "assets/x.glb"}}));
    CHECK(t.find("/scene") != std::string::npos);
    t = error_text(e, Json::object({{"scene", "scenes/town.scene.json"}, {"out", "assets/x.glb"}}));
    CHECK(t.find("/root") != std::string::npos);
    t = error_text(
        e, Json::object(
               {{"scene", "scenes/town.scene.json"}, {"root", "block"}, {"out", "assets/x.glb"}, {"apply", true}}));
    CHECK(t.find("/apply") != std::string::npos);
    t = error_text(e, Json::object({{"out", "assets/x.glb"}}));
    CHECK(t.find("/entity") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "block"}}));
    CHECK(t.find("out") != std::string::npos);
    t = error_text(e, Json::object({{"entity", "nobody"}, {"out", "assets/x.glb"}}));
    CHECK(t.find("nobody") != std::string::npos);
    t = error_text(e, Json::object({{"scene", "scenes/town.scene.json"}, {"root", "nobody"}, {"out", "assets/x.glb"}}));
    CHECK(t.find("/root") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.dir / "assets/x.glb"));
    CHECK_FALSE(stdfs::exists(p.dir / "assets"));
    CHECK(e.world().get<LodGroup>(e.world().find_by_id("block")) == nullptr);
}
