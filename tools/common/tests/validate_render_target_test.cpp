// factoria validate: "target:<name>" in a texture field is the live picture of a render-target camera, not a missing file.
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("validate: target:<name> is accepted in texture fields; a malformed name is an error that says how to write it") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* component, const char* fields) {
        Json e = Json::object({{"id", id}, {"components", Json::object({{component, Json::parse(fields)}})}});
        (*scene)["entities"].push_back(e);
    };
    add("page_cam", "Camera", R"({"renderTarget": "page", "renderTargetSize": [256, 256]})");
    add("page_sprite", "Sprite", R"({"texture": "target:page"})");
    add("page_mesh", "MeshRenderer", R"({"mesh": "quad", "texture": "target:page"})");
    add("bad_name", "Sprite", R"({"texture": "target:no spaces!"})");
    add("no_name", "Sprite", R"({"texture": "target:"})");
    add("missing_file", "Sprite", R"({"texture": "assets/none.png"})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    int named = 0, empty = 0, missing = 0, other = 0;
    for (const ValidationIssue& i : r.errors) {
        if (i.message.find("target:no spaces!") != std::string::npos) {
            ++named;
            CHECK(i.hint.find("target:book") != std::string::npos);
        } else if (i.message.find("no name after") != std::string::npos) {
            ++empty;
        } else if (i.message.find("assets/none.png") != std::string::npos) {
            ++missing;
        } else {
            ++other;
            MESSAGE(i.to_string());
        }
    }
    CHECK(named == 1);
    CHECK(empty == 1);
    CHECK(missing == 1);
    CHECK(other == 0);  // "target:page" on a Sprite and on a MeshRenderer is not reported as a missing file
}
