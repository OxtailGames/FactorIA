// project.validate and rich text: the "text" section of factoria.json, the markup of scene texts, and the bold face a font
// without one is told to get.
#include <doctest.h>

#include <fstream>

#include "fa/core/fs.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;

namespace {

struct Project {
    testing::TempDir tmp;
    std::string dir;

    Project(const char* text, const char* extraScene = nullptr) {
        REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
        dir = tmp.sub("game");
        if (text) {
            auto j = load_json_file(dir + "/factoria.json");
            REQUIRE(j.ok());
            (*j)["text"] = *parse_json(text);
            REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
        }
        if (extraScene) {
            std::ofstream(dir + "/scenes/rich.scene.json", std::ios::binary) << extraScene;
        }
    }
    ValidationReport validate() const { return validate_project(dir); }
    void write(const std::string& rel, const std::string& text) const {
        std::filesystem::create_directories(std::filesystem::path(dir + "/" + rel).parent_path());
        std::ofstream(dir + "/" + rel, std::ios::binary) << text;
    }
};

std::vector<const ValidationIssue*> at(const std::vector<ValidationIssue>& list, const std::string& file, const std::string& pointer) {
    std::vector<const ValidationIssue*> found;
    for (const auto& i : list)
        if (i.file == file && i.pointer == pointer) found.push_back(&i);
    return found;
}

const char* kRichScene = R"({
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "ok", "components": { "Text": { "text": "[c:good]Sold[/c] [icon:fish]", "markup": true } } },
    { "id": "typos", "components": { "Text": { "text": "[c:gode]x[/c] [icon:fsh] [oops]", "markup": true } } },
    { "id": "boldonly", "components": { "Text": { "text": "heavy", "bold": true } } },
    { "id": "plain", "components": { "Text": { "text": "[this is not markup]" } } }
  ]
})";

}  // namespace

TEST_CASE("validate: a good text section with files that exist adds nothing") {
    Project p(R"({"colors": {"good": "#80dc80"}, "icons": {"fish": {"texture": "assets/icons.png", "region": [0, 0, 16, 16]}},
                  "fonts": {"": {"bold": "assets/Bold.ttf"}}})");
    p.write("assets/icons.png", "x");
    p.write("assets/Bold.ttf", "x");
    const ValidationReport r = p.validate();
    for (const auto& e : r.errors) CHECK_MESSAGE(false, e.to_string());
    for (const auto& w : r.warnings) CHECK_MESSAGE((w.file == "AGENTS.md" || w.file == "tests"), w.to_string());
}

TEST_CASE("validate: text section mistakes are reported once each at their pointer, and missing files are named") {
    Project p(R"({"colors": {"good": 12}, "icons": {"fish": {"texture": "assets/nope.png", "region": [0, 0, 16, 16]}},
                  "fonts": {"": {"bold": "assets/NoBold.ttf"}}, "colours": {}})");
    const ValidationReport r = p.validate();
    CHECK_FALSE(r.ok);
    const auto color = at(r.errors, "factoria.json", "/text/colors/good");
    REQUIRE(color.size() == 1);
    CHECK_FALSE(color[0]->hint.empty());
    const auto texture = at(r.errors, "factoria.json", "/text/icons/fish/texture");
    // the file checks need a valid section: reported once the colour is fixed
    CHECK(texture.empty());
    const auto typo = at(r.warnings, "factoria.json", "/text/colours");
    REQUIRE(typo.size() == 1);
    CHECK(typo[0]->message.find("colors") != std::string::npos);

    Project q(R"({"icons": {"fish": {"texture": "assets/nope.png", "region": [0, 0, 16, 16]}}, "fonts": {"": {"bold": "assets/NoBold.ttf"}}})");
    const ValidationReport r2 = q.validate();
    REQUIRE(at(r2.errors, "factoria.json", "/text/icons/fish/texture").size() == 1);
    CHECK(at(r2.errors, "factoria.json", "/text/icons/fish/texture")[0]->message.find("assets/nope.png") != std::string::npos);
    CHECK(at(r2.errors, "factoria.json", "/text/fonts//bold").size() == 1);
}

TEST_CASE("validate: markup of scene texts is checked against the section, and bold without a bold face gets one suggestion") {
    Project p(R"({"colors": {"good": "#80dc80"}, "icons": {"fish": {"texture": "assets/icons.png", "region": [0, 0, 16, 16]}}})", kRichScene);
    p.write("assets/icons.png", "x");
    const ValidationReport r = p.validate();
    const std::string scene = "scenes/rich.scene.json";
    CHECK(at(r.warnings, scene, "/entities/1/components/Text/text").empty());  // "ok"
    const auto typos = at(r.warnings, scene, "/entities/2/components/Text/text");
    REQUIRE(typos.size() == 3);
    std::string all;
    for (const auto* w : typos) all += w->message + "\n";
    CHECK(all.find("unknown colour 'gode'") != std::string::npos);
    CHECK(all.find("unknown icon 'fsh'") != std::string::npos);
    CHECK(all.find("unknown tag [oops]") != std::string::npos);
    // text without markup: brackets are text
    CHECK(at(r.warnings, scene, "/entities/4/components/Text/text").empty());
    // one suggestion for the built-in font, wherever it is used (the first use names the place)
    int suggestions = 0;
    for (const auto& w : r.warnings)
        if (w.message.find("has no bold face") != std::string::npos) {
            ++suggestions;
            CHECK(w.hint.find("\"bold\"") != std::string::npos);
        }
    CHECK(suggestions == 1);
}

TEST_CASE("validate: a font with a bold face in the section needs no suggestion") {
    Project p(R"({"colors": {"good": "#80dc80"}, "icons": {"fish": {"texture": "assets/icons.png", "region": [0, 0, 16, 16]}},
                  "fonts": {"": {"bold": "assets/Bold.ttf"}}})", kRichScene);
    p.write("assets/icons.png", "x");
    p.write("assets/Bold.ttf", "x");
    for (const auto& w : p.validate().warnings) CHECK(w.message.find("has no bold face") == std::string::npos);
}
