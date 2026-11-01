// factoria validate: Camera.showTags / hideTags name tags some entity carries, are arrays of strings and do not overlap.
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
bool mentions(const std::vector<ValidationIssue>& issues, const std::string& needle) {
    for (const ValidationIssue& i : issues)
        if (i.message.find(needle) != std::string::npos || i.hint.find(needle) != std::string::npos) return true;
    return false;
}
}  // namespace

TEST_CASE("validate: Camera showTags/hideTags warn for a tag nobody carries, and error for a tag in both lists") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* tags, const char* component, const char* fields) {
        Json e = Json::object({{"id", id}, {"tags", Json::parse(tags)}, {"components", Json::object({{component, Json::parse(fields)}})}});
        (*scene)["entities"].push_back(e);
    };
    add("page", R"(["page"])", "Sprite", R"({})");
    add("cam_ok", "[]", "Camera", R"({"showTags": ["page"], "hideTags": ["ui"]})");
    add("cam_typo", "[]", "Camera", R"({"showTags": ["pagee"]})");
    add("cam_both", "[]", "Camera", R"({"showTags": ["page"], "hideTags": ["page"]})");
    add("cam_bad", "[]", "Camera", R"({"showTags": "page"})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    CHECK(mentions(r.warnings, "No entity in any scene or prefab has the tag 'pagee'"));
    CHECK(mentions(r.warnings, "Did you mean 'page'"));
    CHECK(mentions(r.warnings, "tag 'ui'"));        // hideTags of a tag nobody carries
    CHECK_FALSE(mentions(r.warnings, "tag 'page'"));  // 'page' is carried by an entity
    CHECK(mentions(r.errors, "both showTags and hideTags"));
    CHECK(mentions(r.errors, "showTags"));  // the non-array value
}

TEST_CASE("validate: a tag carried only by a prefab satisfies Camera.showTags") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    stdfs::create_directories(dir / "prefabs");
    Json prefab = Json::object({{"entity", Json::object({{"name", "Leaf"}, {"tags", Json::array({"leaf"})}})}});
    REQUIRE(save_scene_json_file((dir / "prefabs/leaf.prefab.json").string(), prefab).ok());
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    (*scene)["entities"].push_back(Json::object(
        {{"id", "cam"}, {"components", Json::object({{"Camera", Json::parse(R"({"showTags": ["leaf"]})")}})}}));
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    CHECK_FALSE(mentions(r.warnings, "tag 'leaf'"));
    CHECK_FALSE(mentions(r.errors, "showTags"));
}
