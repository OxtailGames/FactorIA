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
    const std::size_t base = (*scene)["entities"].size() - 4;  // the entities the test added come after the template's
    CHECK(find_error(r, "/entities/" + std::to_string(base) + "/components/Sprite/material") == nullptr);
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

TEST_CASE("validate: a material path with a backslash, an absolute path or '..' is refused the same way on every OS") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    testing::write_all(dir / "materials/wave.material.json", "{}");

    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    const std::size_t base = (*scene)["entities"].size();
    const char* paths[] = {"materials\\wave.material.json", "/materials/wave.material.json",
                           "C:/game/materials/wave.material.json", "materials/../materials/wave.material.json"};
    const char* shapes[] = {"uses a backslash", "is an absolute path", "is an absolute path", "leaves the project"};
    for (std::size_t i = 0; i < 4; ++i)
        (*scene)["entities"].push_back(
            Json::object({{"id", "m" + std::to_string(i)},
                          {"components", Json::object({{"Sprite", Json::object({{"material", paths[i]}})}})}}));
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());

    const ValidationReport r = validate_project(dir.string());
    for (std::size_t i = 0; i < 4; ++i) {
        const ValidationIssue* e =
            find_error(r, "/entities/" + std::to_string(base + i) + "/components/Sprite/material");
        INFO(paths[i]);
        REQUIRE(e != nullptr);
        CHECK(e->message.find(shapes[i]) != std::string::npos);
        CHECK(e->hint.find("forward slashes") != std::string::npos);
        CHECK(e->hint.find("materials/wave.material.json") != std::string::npos);
    }
}

TEST_CASE("validate: SceneSettings.skyMaterial must be a material of kind sky") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const stdfs::path dir = tmp.path / "game";
    testing::write_all(dir / "materials/rock.material.json", R"({"kind": "mesh"})");
    testing::write_all(dir / "materials/dusk.material.json", R"({"kind": "sky"})");

    auto scene = load_json_file((dir / "scenes/main.scene.json").string());
    REQUIRE(scene.ok());
    (*scene)["settings"] = Json::parse(R"({"skyMaterial": "materials/rock.material.json"})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    ValidationReport r = validate_project(dir.string());
    const ValidationIssue* wrong = find_error(r, "/settings/skyMaterial");
    REQUIRE(wrong != nullptr);
    CHECK(wrong->message.find("kind \"mesh\"") != std::string::npos);
    CHECK(wrong->message.find("needs kind \"sky\"") != std::string::npos);
    CHECK(wrong->hint.find("materials/dusk.material.json") != std::string::npos);

    (*scene)["settings"] = Json::parse(R"({"skyMaterial": "materials/dusk.material.json"})");
    REQUIRE(save_scene_json_file((dir / "scenes/main.scene.json").string(), *scene).ok());
    r = validate_project(dir.string());
    CHECK(find_error(r, "/settings/skyMaterial") == nullptr);
}
