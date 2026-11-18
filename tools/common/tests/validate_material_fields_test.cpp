// factoria validate: the `material` of a Sprite, a widget or the sky must be an existing *.material.json.
#include <doctest.h>

#include <filesystem>

#include "fa/scene/serialize.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {
const ValidationIssue* find_error(const ValidationReport& r, const std::string& pointer) {
    for (const ValidationIssue& i : r.errors)
        if (i.file == "scenes/main.scene.json" && i.pointer == pointer) return &i;
    return nullptr;
}
}  // namespace

TEST_CASE("validate: a material field names an existing *.material.json, with the project's materials as the hint") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    testing::write_all(dir / "materials/wave.material.json", "{}");
    testing::write_all(dir / "assets/notes.txt", "x");

    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    auto add = [&](const char* id, const char* type, const char* fields) {
        (*scene)["entities"].push_back(
            Json::object({{"id", id}, {"components", Json::object({{type, Json::parse(fields)}})}}));
    };
    add("ok", "Sprite", R"({"material": "materials/wave.material.json"})");
    add("typo", "Sprite", R"({"material": "materials/wavve.material.json"})");
    add("wrong", "Shape2D", R"({"material": "assets/notes.txt"})");
    add("ui", "Panel", R"({"material": "materials/gone.material.json"})");
    (*scene)["settings"] = Json::parse(R"({"skyMaterial": "materials/wav.material.json"})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    CHECK(find_error(r, "/entities/0/components/Sprite/material") == nullptr);
    const std::size_t base = (*scene)["entities"].size() - 4;
    const ValidationIssue* typo =
        find_error(r, "/entities/" + std::to_string(base + 1) + "/components/Sprite/material");
    REQUIRE(typo != nullptr);
    CHECK(typo->message.find("does not exist") != std::string::npos);
    CHECK(typo->hint.find("Did you mean 'materials/wave.material.json'?") != std::string::npos);
    const ValidationIssue* wrong =
        find_error(r, "/entities/" + std::to_string(base + 2) + "/components/Shape2D/material");
    REQUIRE(wrong != nullptr);
    CHECK(wrong->message.find(".material.json") != std::string::npos);
    CHECK(find_error(r, "/entities/" + std::to_string(base + 3) + "/components/Panel/material") != nullptr);
    const ValidationIssue* sky = find_error(r, "/settings/skyMaterial");
    REQUIRE(sky != nullptr);
    CHECK(sky->hint.find("materials/wave.material.json") != std::string::npos);
}
