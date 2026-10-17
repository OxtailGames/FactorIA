// project.validate and the "localization" section of factoria.json: wrong values with their JSON pointer, unknown keys.
// What the string tables (locales/<language>.json) hold is not checked by validate yet.
#include <doctest.h>

#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;

namespace {

std::string project_with(testing::TempDir& tmp, const char* localization) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    auto j = load_json_file(dir + "/factoria.json");
    REQUIRE(j.ok());
    (*j)["localization"] = *parse_json(localization);
    REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
    return dir;
}

std::vector<const ValidationIssue*> at(const std::vector<ValidationIssue>& list, const std::string& pointer) {
    std::vector<const ValidationIssue*> found;
    for (const auto& i : list)
        if (i.file == "factoria.json" && i.pointer == pointer) found.push_back(&i);
    return found;
}

}  // namespace

TEST_CASE("validate: a good localization section adds nothing") {
    testing::TempDir tmp;
    const std::string dir = project_with(tmp, R"({"defaultLanguage": "en", "languages": ["en", "es", "zh-Hans"],
        "fallbackFonts": ["assets/fonts/a.ttf"], "languageFonts": {"zh-Hans": ["assets/fonts/b.ttf"]}})");
    const ValidationReport r = validate_project(dir);
    CHECK(r.errors.empty());
    CHECK(r.warnings.empty());
}

TEST_CASE("validate: localization mistakes are reported once each, at their pointer, with a fix") {
    testing::TempDir tmp;
    const std::string dir = project_with(tmp, R"({"defaultLanguage": "fr", "languages": ["en", "pt_br", "en"],
        "languageFonts": {"ja": ["a.ttf"]}, "fallbackFont": []})");
    const ValidationReport r = validate_project(dir);
    CHECK_FALSE(r.ok);

    const auto badTag = at(r.errors, "/localization/languages/1");
    REQUIRE(badTag.size() == 1);  // the schema's own message is dropped in favour of this one
    CHECK(badTag[0]->message.find("pt-BR") != std::string::npos);
    CHECK_FALSE(badTag[0]->hint.empty());
    const auto twice = at(r.errors, "/localization/languages/2");
    REQUIRE(twice.size() == 1);
    CHECK(twice[0]->message.find("listed twice") != std::string::npos);

    const auto typo = at(r.warnings, "/localization/fallbackFont");
    REQUIRE(typo.size() == 1);
    CHECK(typo[0]->message.find("fallbackFonts") != std::string::npos);  // did you mean
}

TEST_CASE("validate: a default language that is not in the list, a font for a language the game lacks") {
    testing::TempDir tmp;
    const std::string dir = project_with(tmp, R"({"defaultLanguage": "fr", "languages": ["en", "es"],
        "languageFonts": {"ja": ["assets/fonts/a.ttf"]}})");
    const ValidationReport r = validate_project(dir);
    const auto def = at(r.errors, "/localization/defaultLanguage");
    REQUIRE(def.size() == 1);
    CHECK(def[0]->message.find("not one of \"languages\"") != std::string::npos);
    const auto font = at(r.errors, "/localization/languageFonts/ja");
    REQUIRE(font.size() == 1);
    CHECK(font[0]->message.find("not one of \"languages\"") != std::string::npos);
}
