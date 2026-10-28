// factoria validate: a screen widget that lies completely outside the design size (anchor counts Y down, pivot Y up).
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

TEST_CASE("validate: a widget wholly outside the design size is a warning that says where it is and how to fix it") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* fields, bool active = true) {
        Json e = Json::object({{"id", id}, {"components", Json::object({{"Panel", Json::parse(fields)}})}});
        if (!active) e["active"] = false;
        (*scene)["entities"].push_back(e);
    };
    // The design size is 1280 x 720 (the template's). Anchor [0.5, 1] puts the position on the bottom edge.
    add("bar_ok", R"({"size": [400, 100], "anchor": [0.5, 1], "pivot": [0.5, 0]})");              // stands on the bottom edge
    add("bar_hanging", R"({"size": [400, 100], "anchor": [0.5, 1], "pivot": [0.5, 1]})");         // hangs below the screen
    add("half_in", R"({"size": [400, 100], "anchor": [0.5, 1], "pivot": [0.5, 0.5]})");           // half visible: fine
    add("hidden", R"({"size": [400, 100], "anchor": [0.5, 1], "pivot": [0.5, 1]})", false);       // inactive: not asked about
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    for (const auto& e : r.errors) MESSAGE(e.to_string());
    CHECK(r.ok);  // a warning: the scene loads

    int hits = 0;
    for (const ValidationIssue& i : r.warnings) {
        if (i.message.find("lies completely outside the screen") == std::string::npos) continue;
        ++hits;
        CHECK(i.file == "scenes/main.scene.json");
        CHECK(i.message.find("Panel 'bar_hanging'") != std::string::npos);
        CHECK(i.message.find("y 720 to 820") != std::string::npos);
        CHECK(i.message.find("1280 x 720") != std::string::npos);
        CHECK(i.hint.find("pivot") != std::string::npos);
    }
    CHECK(hits == 1);
}
