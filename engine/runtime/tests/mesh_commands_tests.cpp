// mesh.create / update / destroy / save / list / info (docs/SCRIPTING.md, "Procedural meshes").
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/runtime/engine.h"
#include "fa/scene/mesh_geometry.h"
#include "fa/scene/mesh_store.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kProject = R"({
  "format": "factoria.project/1",
  "name": "Mesh Commands Test",
  "id": "com.example.meshcommands",
  "mainScene": "scenes/main.scene.json",
  "display": { "width": 320, "height": 180, "scaleMode": "pixelPerfect" },
  "physics": { "fixedHz": 60, "pixelsPerMeter": 100 }
})";

const char* kScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "name": "Camera", "components": { "Camera": { "clearColor": "#202020" } } },
    { "id": "thing", "name": "thing", "components": { "Transform": { "position": [0, 0, 0] }, "MeshRenderer": { "mesh": "cube" } } }
  ]
})";

struct TempProject {
    stdfs::path dir;
    explicit TempProject(const std::string& name) {
        dir = fs::make_temp_dir("fa_meshcmd_test_" + name);
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json", std::ios::binary) << kProject;
        std::ofstream(dir / "scenes/main.scene.json", std::ios::binary) << kScene;
        std::ofstream(dir / "scenes/other.scene.json", std::ios::binary) << kScene;
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
};

EngineConfig cfg(const TempProject& p) {
    EngineConfig c;
    c.projectDir = p.dir.generic_string();
    c.headless = true;
    c.hotReload = false;
    return c;
}

Json quad() {
    return Json::object({{"positions", Json::parse("[[0,0,0],[1,0,0],[1,1,0],[0,1,0]]")}, {"indices", Json::parse("[0,1,2,0,2,3]")}});
}

}  // namespace

TEST_CASE("mesh commands: create, info, list, update and destroy") {
    TempProject p("basic");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    auto made = c.call("mesh.create", quad());
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    const std::string id = made.result["id"];
    CHECK(id.rfind("mesh:", 0) == 0);
    CHECK(made.result["vertices"] == 4);
    CHECK(made.result["triangles"] == 2);
    CHECK(made.result["bounds"]["max"][0] == 1);
    CHECK(made.result["submeshes"].size() == 1);

    // the id is a MeshRenderer.mesh value
    auto set = c.call("scene.set_component", Json::object({{"id", "thing"}, {"component", "MeshRenderer"}, {"fields", Json::object({{"mesh", id}})}}));
    CHECK_MESSAGE(set.ok, set.error.dump());

    auto list = c.call("mesh.list", Json::object());
    REQUIRE(list.ok);
    CHECK(list.result["count"] == 1);

    auto upd = c.call("mesh.update", Json::object({{"id", id}, {"positions", Json::parse("[0,0,0, 3,0,0, 3,3,0, 0,3,0]")}}));
    REQUIRE_MESSAGE(upd.ok, upd.error.dump());
    CHECK(upd.result["version"] == 2);
    CHECK(upd.result["bounds"]["max"][1] == 3);
    auto info = c.call("mesh.info", Json::object({{"id", id}}));
    REQUIRE(info.ok);
    CHECK(info.result["version"] == 2);

    auto bad = c.call("mesh.update", Json::object({{"id", id}, {"indices", Json::parse("[0,1,9]")}}));
    CHECK_FALSE(bad.ok);
    CHECK(bad.error.dump().find("valid: 0..3") != std::string::npos);
    CHECK(c.call("mesh.info", Json::object({{"id", id}})).result["version"] == 2);  // a refused update changes nothing

    auto gone = c.call("mesh.destroy", Json::object({{"id", id}}));
    REQUIRE(gone.ok);
    auto again = c.call("mesh.destroy", Json::object({{"id", id}}));
    CHECK_FALSE(again.ok);
    CHECK(again.error.dump().find("does not exist") != std::string::npos);
    CHECK_FALSE(c.call("mesh.info", Json::object({{"id", "cube"}})).ok);
    CHECK_FALSE(c.call("mesh.create", Json::object({{"indices", Json::parse("[0,1,2]")}})).ok);  // no positions
    CHECK_FALSE(c.call("mesh.create", Json::object({{"positions", Json::parse("[0,0,0]")}, {"colour", 1}})).ok);
    e.shutdown();
}

TEST_CASE("mesh commands: a scene load releases the meshes, and save writes a .glb that loads back") {
    TempProject p("scene_save");
    Engine e;
    std::string err;
    REQUIRE_MESSAGE(e.init(cfg(p), nullptr, &err), err);
    auto& c = e.commands();
    Json args = quad();
    args["submeshes"] = Json::parse(R"([{"material":{"name":"skin","color":[1,0.5,0.25,1]},"start":0,"count":3},{"material":"cloth"}])");
    auto made = c.call("mesh.create", args);
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    const std::string id = made.result["id"];
    CHECK(made.result["submeshes"][1]["start"] == 3);
    CHECK(made.result["submeshes"][1]["count"] == 3);

    auto saved = c.call("mesh.save", Json::object({{"id", id}, {"path", "assets/models/quad.glb"}}));
    REQUIRE_MESSAGE(saved.ok, saved.error.dump());
    CHECK(saved.result["saved"] == "assets/models/quad.glb");
    CHECK(stdfs::exists(p.dir / "assets/models/quad.glb"));
    fs::set_project_root(p.dir);
    auto names = gltf_material_names("assets/models/quad.glb");
    REQUIRE(names.ok());
    CHECK(*names == std::vector<std::string>{"skin", "cloth"});
    CHECK_FALSE(c.call("mesh.save", Json::object({{"id", id}, {"path", "assets/models/quad.obj"}})).ok);

    auto loaded = c.call("scene.load", Json::object({{"path", "scenes/other.scene.json"}}));
    REQUIRE_MESSAGE(loaded.ok, loaded.error.dump());
    auto list = c.call("mesh.list", Json::object());
    CHECK(list.result["count"] == 0);
    auto stale = c.call("mesh.update", Json::object({{"id", id}, {"positions", Json::parse("[0,0,0]")}}));
    CHECK_FALSE(stale.ok);
    CHECK(stale.error.dump().find("scene") != std::string::npos);
    e.shutdown();
}
