// factoria validate: a dynamic body that starts inside a static collider, and Joint3D.connected "" (the world).
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("validate: a body started inside a wall is a warning naming both, and connected \"\" is the world") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* components) {
        (*scene)["entities"].push_back(Json::object({{"id", id}, {"components", Json::parse(components)}}));
    };
    add("wall", R"({"Transform": {"position": [0, 0, 0]}, "Collider3D": {"size": [4, 1, 4]}, "RigidBody3D": {"type": "static"}})");
    add("crate", R"({"Transform": {"position": [0, 0.85, 0]}, "Collider3D": {"size": [1, 1, 1]}, "RigidBody3D": {}})");
    add("free", R"({"Transform": {"position": [10, 3, 0]}, "Collider3D": {"size": [1, 1, 1]}, "RigidBody3D": {}})");
    add("door", R"({"Transform": {"position": [20, 3, 0]}, "Collider3D": {"size": [1, 1, 1]}, "RigidBody3D": {},
                    "Joint3D": {"connected": "", "axis": [0, 1, 0]}})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    int overlaps = 0;
    for (const ValidationIssue& w : r.warnings) {
        if (w.message.find("inside") == std::string::npos) continue;
        ++overlaps;
        CHECK(w.file == "scenes/main.scene.json");
        CHECK(w.message.find("crate") != std::string::npos);
        CHECK(w.message.find("wall") != std::string::npos);
    }
    CHECK(overlaps == 1);  // the free crate and the door start in the air
    for (const ValidationIssue& e : r.errors) CHECK_MESSAGE(e.message.find("connected") == std::string::npos, e.to_string());
    for (const ValidationIssue& w : r.warnings) CHECK_MESSAGE(w.message.find("connected") == std::string::npos, w.to_string());
}
