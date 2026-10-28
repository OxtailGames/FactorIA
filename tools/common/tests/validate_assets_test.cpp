// project.validate: the assets.json manifest (schemas/assets.schema.json) and the asset checks.
#include <doctest.h>

#include <filesystem>

#include "asset_test_helpers.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const ValidationIssue* find_issue(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer = {}) {
    for (const ValidationIssue& i : list)
        if (i.file == file && (pointer.empty() || i.pointer == pointer)) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("validate: assets.json is checked against its schema, and entries of missing files are reported") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    testing::write_all(stdfs::path(dir) / "assets/hero_v2.png", "not really a png");
    testing::write_all(stdfs::path(dir) / "assets.json", R"({
      "format": "factoria.assets/1",
      "defaults": {"audio": {"stream": "sometimes"}},
      "assets": {
        "assets/hero.png": {"provenance": {"origin": "generated", "date": "2026-10-16", "provider": "fake"}}
      }
    })");

    const ValidationReport r = validate_project(dir);
    CHECK_FALSE(r.ok);
    const ValidationIssue* bad = find_issue(r.errors, "assets.json", "/defaults/audio/stream");
    REQUIRE(bad != nullptr);
    const ValidationIssue* missing = find_issue(r.warnings, "assets.json", "/assets/assets~1hero.png");
    REQUIRE(missing != nullptr);
    CHECK(missing->hint.find("assets/hero_v2.png") != std::string::npos);
}

TEST_CASE("validate: a valid assets.json adds no issue") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    const ValidationReport before = validate_project(dir);
    testing::write_all(stdfs::path(dir) / "assets.json",
                       R"({"format": "factoria.assets/1", "defaults": {"texture": {"compression": "uastc"}}})");
    const ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    CHECK(r.warnings.size() == before.warnings.size());
}

TEST_CASE("validate: textures that are not multiples of 4 are warned about when platforms has android or ios, with the export's message") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    Image odd;
    odd.width = 40;
    odd.height = 30;
    odd.rgba.assign(40 * 30 * 4, 255);
    testing::write_png(stdfs::path(dir) / "assets/odd.png", odd);
    Image good;
    good.width = 40;
    good.height = 32;
    good.rgba.assign(40 * 32 * 4, 255);
    testing::write_png(stdfs::path(dir) / "assets/good.png", good);

    const auto setPlatforms = [&](const char* list) {
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["platforms"] = *parse_json(list);
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    };
    setPlatforms(R"(["windows"])");
    CHECK(find_issue(validate_project(dir).warnings, "assets/odd.png") == nullptr);

    setPlatforms(R"(["windows", "android"])");
    const ValidationReport r = validate_project(dir);
    const ValidationIssue* w = find_issue(r.warnings, "assets/odd.png");
    REQUIRE(w != nullptr);
    CHECK(w->message.find("40x30") != std::string::npos);
    CHECK(w->message.find("multiples of 4") != std::string::npos);
    CHECK(find_issue(r.warnings, "assets/good.png") == nullptr);

    // In an atlas group the texture is repacked at a size the compression takes: no warning.
    testing::write_all(stdfs::path(dir) / "assets.json",
                       R"({"format": "factoria.assets/1", "assets": {"assets/odd.png": {"import": {"atlas": "ui"}}}})");
    CHECK(find_issue(validate_project(dir).warnings, "assets/odd.png") == nullptr);
}

TEST_CASE("validate: export.exclude is checked, a glob that matches nothing is a warning and one that matches the main scene an error") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    testing::write_all(stdfs::path(dir) / "store/shot.png", "x");
    const auto setExclude = [&](const char* list) {
        auto j = load_json_file(dir + "/factoria.json");
        REQUIRE(j.ok());
        (*j)["export"]["exclude"] = *parse_json(list);
        REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    };
    setExclude(R"(["store/**"])");
    ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    CHECK(find_issue(r.warnings, "factoria.json", "/export/exclude/0") == nullptr);

    setExclude(R"(["stor/**"])");
    r = validate_project(dir);
    CHECK(find_issue(r.warnings, "factoria.json", "/export/exclude/0") != nullptr);

    setExclude(R"(["scenes/**"])");
    r = validate_project(dir);
    CHECK_FALSE(r.ok);
    CHECK(find_issue(r.errors, "factoria.json", "/export/exclude/0") != nullptr);

    setExclude(R"(["../outside", 5])");
    r = validate_project(dir);
    CHECK(find_issue(r.errors, "factoria.json", "/export/exclude/0") != nullptr);
    CHECK(find_issue(r.errors, "factoria.json", "/export/exclude/1") != nullptr);
}

TEST_CASE("validate: a built-in font in a scene is the engine's, not a missing project file; a misspelt one is named") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    testing::write_all(stdfs::path(dir) / "scenes/fonts.scene.json", R"({
      "format": "factoria.scene/1",
      "entities": [
        {"id": "title", "components": {"Text": {"text": "Roguestory", "font": "builtin:display"}}},
        {"id": "body", "components": {"Text": {"text": "Once", "font": "builtin:serif#bold"}}},
        {"id": "plain", "components": {"Text": {"text": "Hi", "font": "builtin"}}},
        {"id": "typo", "components": {"Text": {"text": "Oops", "font": "builtin:serfi"}}}
      ]
    })");

    const ValidationReport r = validate_project(dir);
    for (const char* ok : {"/entities/0/components/Text/font", "/entities/1/components/Text/font", "/entities/2/components/Text/font"})
        CHECK(find_issue(r.errors, "scenes/fonts.scene.json", ok) == nullptr);
    const ValidationIssue* typo = find_issue(r.errors, "scenes/fonts.scene.json", "/entities/3/components/Text/font");
    REQUIRE(typo != nullptr);
    CHECK(typo->message.find("Unknown built-in font 'builtin:serfi'") != std::string::npos);
    CHECK(typo->hint.find("Did you mean 'builtin:serif'?") != std::string::npos);
}
