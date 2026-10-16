// project.validate and the `icon` / `export` settings of factoria.json: wrong values, unknown keys, icon files.
#include <doctest.h>

#include <filesystem>

#include "fa/core/image.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

std::string new_project(testing::TempDir& tmp) {
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    return tmp.sub("game");
}

void write_icon(const std::string& path, int w, int h) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * h * 4, 255);
    REQUIRE(save_png(img, path).ok());
}

std::vector<const ValidationIssue*> at(const std::vector<ValidationIssue>& list, const std::string& pointer) {
    std::vector<const ValidationIssue*> found;
    for (const auto& i : list)
        if (i.file == "factoria.json" && i.pointer == pointer) found.push_back(&i);
    return found;
}

// Adds top-level keys to the project's factoria.json.
void patch_project(const std::string& dir, const char* extra) {
    auto j = load_json_file(dir + "/factoria.json");
    REQUIRE(j.ok());
    json_merge(*j, *parse_json(extra));
    REQUIRE(save_json_file(dir + "/factoria.json", *j).ok());
}

}  // namespace

TEST_CASE("validate: a project without icon settings stays clean, a good icon and export block add nothing") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    REQUIRE(validate_project(dir).ok);
    write_icon(dir + "/assets/icon.png", 1024, 1024);
    patch_project(dir, R"({"icon": "assets/icon.png", "export": {"android": {"format": "aab", "minSdk": 28},
                           "macos": {"copyright": "x"}, "ios": {"teamId": "ABCDE12345"}}})");
    const ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    CHECK(r.errors.empty());
    CHECK(r.warnings.empty());
}

TEST_CASE("validate: icon files that are missing, unreadable or badly shaped") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    write_icon(dir + "/assets/icon.png", 1024, 1024);
    write_icon(dir + "/assets/small.png", 128, 128);
    write_icon(dir + "/assets/wide.png", 800, 600);
    testing::write_all(dir + "/assets/broken.png", "not a png");
    patch_project(dir, R"({"icon": "assets/icn.png", "export": {
        "windows": {"icon": "assets/small.png"},
        "macos": {"icon": "assets/wide.png"},
        "linux": {"icon": "assets/broken.png"},
        "android": {"icon": "assets/icon.png", "adaptiveIcon": {"foreground": "assets/nope.png", "background": "assets/icon.png", "monochrome": "assets/mono.png"}},
        "ios": {"icon": "assets/icon.png"}}})");
    const ValidationReport r = validate_project(dir);
    CHECK_FALSE(r.ok);

    auto missing = at(r.errors, "/icon");
    REQUIRE(missing.size() == 1);
    CHECK(missing[0]->message == "the icon file 'assets/icn.png' does not exist");  // the location is not repeated in the message
    CHECK(missing[0]->hint.find("Did you mean 'assets/icon.png'?") != std::string::npos);
    CHECK(missing[0]->to_string().find("factoria.json#/icon: the icon file") == 0);

    auto broken = at(r.errors, "/export/linux/icon");
    REQUIRE(broken.size() == 1);
    CHECK(broken[0]->message.find("cannot use 'assets/broken.png' as an icon") != std::string::npos);

    CHECK(at(r.errors, "/export/android/adaptiveIcon/foreground").size() == 1);
    CHECK(at(r.errors, "/export/android/adaptiveIcon/monochrome").size() == 1);
    CHECK(at(r.errors, "/export/android/adaptiveIcon/background").empty());

    auto small = at(r.warnings, "/export/windows/icon");
    REQUIRE(small.size() == 1);
    CHECK(small[0]->message.find("smaller than 512") != std::string::npos);
    auto wide = at(r.warnings, "/export/macos/icon");
    REQUIRE(wide.size() == 1);
    CHECK(wide[0]->message.find("not square") != std::string::npos);
    CHECK(at(r.warnings, "/export/android/icon").empty());
    CHECK(at(r.errors, "/export/ios/icon").empty());
}

TEST_CASE("validate: wrong export values are reported once, with the settings' own message and fix") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    patch_project(dir, R"({"icon": 5, "export": {"android": {"minSdk": "26", "targetSdk": 20, "format": "zip"},
                           "ios": {"teamId": "nope"}}})");
    const ValidationReport r = validate_project(dir);
    CHECK_FALSE(r.ok);
    for (const char* pointer : {"/icon", "/export/android/minSdk", "/export/android/targetSdk", "/export/android/format", "/export/ios/teamId"}) {
        INFO("pointer ", pointer);
        auto found = at(r.errors, pointer);
        REQUIRE(found.size() == 1);  // the schema reports the same pointer; only one message survives
        CHECK_FALSE(found[0]->hint.empty());
    }
    CHECK(at(r.errors, "/export/android/format")[0]->hint.find("apk") != std::string::npos);
    CHECK(at(r.errors, "/export/android/targetSdk")[0]->message.find("below the minimum 26") != std::string::npos);
}

TEST_CASE("validate: unknown keys in export are warnings with a did-you-mean") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    patch_project(dir, R"({"export": {"android": {"fromat": "aab"}, "windoes": {}}})");
    const ValidationReport r = validate_project(dir);
    CHECK(r.ok);  // warnings only
    auto key = at(r.warnings, "/export/android/fromat");
    REQUIRE(key.size() == 1);
    CHECK(key[0]->hint.find("Did you mean 'format'?") != std::string::npos);
    auto platform = at(r.warnings, "/export/windoes");
    REQUIRE(platform.size() == 1);
    CHECK(platform[0]->hint.find("Did you mean 'windows'?") != std::string::npos);
}

TEST_CASE("validate: save_export_settings output validates") {
    testing::TempDir tmp;
    const std::string dir = new_project(tmp);
    write_icon(dir + "/assets/icon.png", 1024, 1024);
    auto s = load_export_settings(dir);
    REQUIRE(s.ok());
    s->icon = "assets/icon.png";
    s->android.format = "aab";
    s->android.signing = {"keys/upload.jks", "upload"};
    s->linux.categories = {"Game", "ArcadeGame"};
    s->ios.buildNumber = "7";
    REQUIRE(save_export_settings(dir, *s).ok());
    const ValidationReport r = validate_project(dir);
    CHECK(r.ok);
    CHECK(r.warnings.empty());
}
