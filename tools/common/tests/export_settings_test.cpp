// icon / export of factoria.json (parse, load, save), ~/.factoria/export.json, and the Android toolchain search.
#include <doctest.h>

#include <filesystem>
#include <map>

#ifndef _WIN32
#include <sys/stat.h>
#endif

#include "fa/core/process.h"
#include "fa/tooling/export_settings.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

Json parse(const char* text) {
    auto j = parse_json(text, "test");
    REQUIRE(j.ok());
    return *j;
}

const ExportSettingsIssue* find_issue(const std::vector<ExportSettingsIssue>& list, const std::string& pointer) {
    for (const auto& i : list)
        if (i.pointer == pointer) return &i;
    return nullptr;
}

std::string project_file(const testing::TempDir& tmp) { return tmp.sub("factoria.json"); }

// The template's own style: 2-space indent, scalar arrays and small objects on one line.
const char* kTemplateStyle = R"({
  "format": "factoria.project/1",
  "name": "Space Dodge",
  "id": "com.example.spacedodge",
  "version": "1.2.3",
  "display": { "width": 1280, "height": 720, "scaleMode": "fit" },
  "input": {
    "actions": {
      "jump": ["Space", "W", "Up"]
    }
  },
  "platforms": ["windows", "macos", "linux", "ios", "android"],
  "feedbackFile": "ENGINE_FEEDBACK.json"
}
)";

// The style of save_project / dump_json: every array element on its own line.
const char* kDumpStyle = R"({
  "format": "factoria.project/1",
  "name": "Gem Roller",
  "platforms": [
    "windows",
    "macos"
  ],
  "feedbackFile": "ENGINE_FEEDBACK.json"
})";

// A map-backed environment for the injectable lookups.
ExportEnvLookup env_of(std::map<std::string, std::string> vars) {
    return [vars = std::move(vars)](const std::string& name) {
        auto it = vars.find(name);
        return it == vars.end() ? std::string() : it->second;
    };
}

}  // namespace

// ---------------------------------------------------------------------------------------------------- parse

TEST_CASE("export settings: a project without icon/export gets the defaults") {
    auto r = parse_export_settings(parse(R"({"format": "factoria.project/1", "name": "G", "version": "1.2.3"})"));
    CHECK(r.errors.empty());
    CHECK(r.warnings.empty());
    const ProjectExportSettings& s = r.settings;
    CHECK(s.icon.empty());
    CHECK(s.macos.category == "public.app-category.games");
    CHECK(s.macos.minimumSystemVersion == "11.0");
    CHECK(s.macos.copyright.empty());
    CHECK(s.linux.categories == std::vector<std::string>{"Game"});
    CHECK(s.android.format == "apk");
    CHECK(s.android.minSdk == 26);
    CHECK(s.android.targetSdk == 36);
    CHECK(s.android.adaptiveIcon.background == "#FFFFFF");
    CHECK(s.android.permissions.empty());
    CHECK(s.ios.iconBackground == "#FFFFFF");
    CHECK(s.projectVersion == "1.2.3");
    CHECK(s.android_version_code() == 10203);
    CHECK(s.ios_build_number() == "1.2.3");
    CHECK(s.icon_for("android").empty());
}

TEST_CASE("export settings: every documented field is read") {
    auto r = parse_export_settings(parse(R"({
      "version": "0.4.2",
      "icon": "assets/icon.png",
      "export": {
        "windows": {"icon": "assets/win.png"},
        "macos": {"icon": "assets/mac.png", "category": "public.app-category.puzzle-games", "minimumSystemVersion": "13.3",
                  "copyright": "(c) 2026 Someone"},
        "linux": {"icon": "assets/linux.png", "categories": ["Game", "ArcadeGame"]},
        "android": {"icon": "assets/android.png", "format": "aab",
                    "adaptiveIcon": {"foreground": "assets/fg.png", "background": "#202020", "monochrome": "assets/mono.png"},
                    "versionCode": 77, "minSdk": 28, "targetSdk": 35,
                    "permissions": ["android.permission.VIBRATE", "com.google.android.gms.permission.AD_ID"],
                    "signing": {"keystore": "keys/upload.keystore", "alias": "upload"}},
        "ios": {"icon": "assets/ios.png", "iconBackground": "#101010", "teamId": "ABCDE12345", "buildNumber": "42"}
      }})"));
    REQUIRE(r.errors.empty());
    CHECK(r.warnings.empty());
    const ProjectExportSettings& s = r.settings;
    CHECK(s.icon == "assets/icon.png");
    CHECK(s.windows.icon == "assets/win.png");
    CHECK(s.macos.category == "public.app-category.puzzle-games");
    CHECK(s.macos.minimumSystemVersion == "13.3");
    CHECK(s.macos.copyright == "(c) 2026 Someone");
    CHECK(s.linux.categories == std::vector<std::string>{"Game", "ArcadeGame"});
    CHECK(s.android.format == "aab");
    CHECK(s.android.adaptiveIcon.foreground == "assets/fg.png");
    CHECK(s.android.adaptiveIcon.background == "#202020");
    CHECK(s.android.adaptiveIcon.monochrome == "assets/mono.png");
    CHECK(s.android.versionCode == 77);
    CHECK(s.android.minSdk == 28);
    CHECK(s.android.targetSdk == 35);
    CHECK(s.android.permissions.size() == 2);
    CHECK(s.android.signing.keystore == "keys/upload.keystore");
    CHECK(s.android.signing.alias == "upload");
    CHECK(s.ios.iconBackground == "#101010");
    CHECK(s.ios.teamId == "ABCDE12345");
    CHECK(s.ios.buildNumber == "42");
    CHECK(s.android_version_code() == 77);
    CHECK(s.ios_build_number() == "42");
    // icon_for: the platform's own, else the project's
    CHECK(s.icon_for("windows") == "assets/win.png");
    CHECK(s.icon_for("macos") == "assets/mac.png");
    CHECK(s.icon_for("linux") == "assets/linux.png");
    CHECK(s.icon_for("android") == "assets/android.png");
    CHECK(s.icon_for("ios") == "assets/ios.png");
    CHECK(s.icon_for("web") == "assets/icon.png");
}

TEST_CASE("export settings: icon_for falls back to the project icon") {
    auto r = parse_export_settings(parse(R"({"icon": "a.png", "export": {"android": {"icon": "b.png"}}})"));
    CHECK(r.settings.icon_for("android") == "b.png");
    CHECK(r.settings.icon_for("windows") == "a.png");
    CHECK(r.settings.icon_for("ios") == "a.png");
}

TEST_CASE("export settings: the Android versionCode is derived from the version") {
    CHECK(android_version_code_from("1.2.3") == 10203);
    CHECK(android_version_code_from("0.1.0") == 100);
    CHECK(android_version_code_from("2.0") == 20000);
    CHECK(android_version_code_from("0.0.0") == 1);       // never below 1
    CHECK(android_version_code_from("") == 1);
    CHECK(android_version_code_from("1.2.300") == 10299);  // each part is capped at 99
    CHECK(android_version_code_from("1.2.3-beta") == 10203);
}

TEST_CASE("export settings: wrong types and values are errors that name the pointer and the fix") {
    auto r = parse_export_settings(parse(R"({
      "icon": 5,
      "export": {
        "macos": {"minimumSystemVersion": "10.15", "category": ""},
        "linux": {"categories": ["Game", "A;B", 3]},
        "android": {"format": "ab", "versionCode": 0, "minSdk": "26", "targetSdk": 25.5, "permissions": ["VIBRATE"],
                    "adaptiveIcon": {"background": "#12345"}, "signing": []},
        "ios": {"teamId": "abcde12345", "iconBackground": "white", "buildNumber": "v1"}
      }})"));
    for (const char* ptr : {"/icon", "/export/macos/minimumSystemVersion", "/export/macos/category", "/export/linux/categories/1",
                            "/export/linux/categories/2", "/export/android/format", "/export/android/versionCode",
                            "/export/android/minSdk", "/export/android/targetSdk", "/export/android/permissions/0",
                            "/export/android/adaptiveIcon/background", "/export/android/signing", "/export/ios/teamId",
                            "/export/ios/iconBackground", "/export/ios/buildNumber"}) {
        const ExportSettingsIssue* e = find_issue(r.errors, ptr);
        INFO("pointer ", ptr);
        REQUIRE(e != nullptr);
        CHECK_FALSE(e->message.empty());
        CHECK_FALSE(e->hint.empty());  // every error says how to fix it
    }
    CHECK(r.errors.size() == 15);
    CHECK(find_issue(r.errors, "/export/android/format")->hint.find("apk") != std::string::npos);
    CHECK(find_issue(r.errors, "/export/macos/minimumSystemVersion")->message.find("older than macOS 11.0") != std::string::npos);
    // invalid fields keep their defaults
    CHECK(r.settings.android.format == "apk");
    CHECK(r.settings.macos.minimumSystemVersion == "11.0");
    CHECK(r.settings.ios.teamId.empty());
}

TEST_CASE("export settings: the SDK levels are checked against each other") {
    auto low = parse_export_settings(parse(R"({"export": {"android": {"minSdk": 25}}})"));
    REQUIRE(low.errors.size() == 1);
    CHECK(low.errors[0].pointer == "/export/android/minSdk");
    CHECK(low.errors[0].message.find("below the minimum 26") != std::string::npos);

    auto order = parse_export_settings(parse(R"({"export": {"android": {"minSdk": 34, "targetSdk": 30}}})"));
    REQUIRE(order.errors.size() == 1);
    CHECK(order.errors[0].pointer == "/export/android/minSdk");
    CHECK(order.errors[0].message.find("minSdk (34) is higher than targetSdk (30)") != std::string::npos);
    CHECK(order.errors[0].hint.find("26 <= minSdk <= targetSdk") != std::string::npos);

    // minSdk above the DEFAULT targetSdk is wrong too
    auto vs_default = parse_export_settings(parse(R"({"export": {"android": {"minSdk": 40}}})"));
    CHECK(vs_default.errors.size() == 1);

    auto ok = parse_export_settings(parse(R"({"export": {"android": {"minSdk": 30, "targetSdk": 30}}})"));
    CHECK(ok.errors.empty());
    CHECK(ok.settings.android.minSdk == 30);
}

TEST_CASE("export settings: icon paths must stay inside the project") {
    auto abs = parse_export_settings(parse(R"({"icon": "/Users/me/icon.png", "export": {"ios": {"icon": "C:\\icons\\a.png"}}})"));
    CHECK(find_issue(abs.errors, "/icon") != nullptr);
    CHECK(find_issue(abs.errors, "/export/ios/icon") != nullptr);
    auto up = parse_export_settings(parse(R"({"icon": "../icon.png"})"));
    REQUIRE(up.errors.size() == 1);
    CHECK(up.errors[0].message.find("leaves the project folder") != std::string::npos);
    auto back = parse_export_settings(parse(R"({"icon": "assets\\icon.png"})"));
    CHECK(back.errors.empty());
    CHECK(back.settings.icon == "assets/icon.png");  // backslashes become forward slashes
    // a keystore may live outside the project
    auto ks = parse_export_settings(parse(R"({"export": {"android": {"signing": {"keystore": "/keys/up.jks", "alias": "up"}}}})"));
    CHECK(ks.errors.empty());
    CHECK(ks.settings.android.signing.keystore == "/keys/up.jks");
}

TEST_CASE("export settings: unknown keys are warnings with a did-you-mean") {
    auto r = parse_export_settings(parse(R"({"export": {
        "windoes": {"icon": "a.png"},
        "macos": {"categroy": "x"},
        "android": {"fromat": "aab", "signing": {"keystor": "k"}, "adaptiveIcon": {"foregound": "f.png"}}
      }})"));
    CHECK(r.errors.empty());
    const ExportSettingsIssue* platform = find_issue(r.warnings, "/export/windoes");
    REQUIRE(platform != nullptr);
    CHECK(platform->hint.find("Did you mean 'windows'?") != std::string::npos);
    const ExportSettingsIssue* key = find_issue(r.warnings, "/export/macos/categroy");
    REQUIRE(key != nullptr);
    CHECK(key->hint.find("Did you mean 'category'?") != std::string::npos);
    CHECK(key->hint.find("Valid: icon, category, minimumSystemVersion, copyright") != std::string::npos);
    CHECK(find_issue(r.warnings, "/export/android/fromat")->hint.find("Did you mean 'format'?") != std::string::npos);
    CHECK(find_issue(r.warnings, "/export/android/signing/keystor")->hint.find("Did you mean 'keystore'?") != std::string::npos);
    CHECK(find_issue(r.warnings, "/export/android/adaptiveIcon/foregound")->hint.find("Did you mean 'foreground'?") != std::string::npos);
    CHECK(r.settings.android.format == "apk");  // an unknown key never changes a setting
}

TEST_CASE("export settings: a signing entry with only half of its fields warns") {
    auto r = parse_export_settings(parse(R"({"export": {"android": {"signing": {"keystore": "k.jks"}}}})"));
    CHECK(r.errors.empty());
    REQUIRE(find_issue(r.warnings, "/export/android/signing/alias") != nullptr);
}

// ---------------------------------------------------------------------------------------------------- load

TEST_CASE("export settings: load_export_settings reads the file and reports the first problem") {
    testing::TempDir tmp;
    testing::write_all(project_file(tmp), R"({"format": "factoria.project/1", "name": "G", "version": "2.0.1",
        "export": {"android": {"format": "aab", "extra": 1}}})");
    std::vector<std::string> warnings;
    auto ok = load_export_settings(tmp.str(), &warnings);
    REQUIRE(ok.ok());
    CHECK(ok->android.format == "aab");
    CHECK(ok->android_version_code() == 20001);
    REQUIRE(warnings.size() == 1);
    CHECK(warnings[0].find("factoria.json#/export/android/extra") != std::string::npos);
    CHECK(warnings[0].find("Unknown key 'extra'") != std::string::npos);

    testing::write_all(project_file(tmp), R"({"export": {"android": {"minSdk": "x", "targetSdk": 99999}}})");
    auto bad = load_export_settings(tmp.str());
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("factoria.json#/export/android/minSdk") != std::string::npos);
    CHECK(bad.error().message.find("expected a whole number") != std::string::npos);
    CHECK(bad.error().hint.find("API level") != std::string::npos);
    CHECK(bad.error().hint.find("1 more problem(s)") != std::string::npos);
    CHECK(bad.error().hint.find("factoria validate") != std::string::npos);

    testing::write_all(project_file(tmp), "{ not json");
    CHECK_FALSE(load_export_settings(tmp.str()).ok());
    CHECK_FALSE(load_export_settings(tmp.sub("nowhere")).ok());
    testing::write_all(project_file(tmp), "[1, 2]");
    CHECK_FALSE(load_export_settings(tmp.str()).ok());
}

// ---------------------------------------------------------------------------------------------------- save

TEST_CASE("export settings: saving with nothing changed does not touch the file") {
    testing::TempDir tmp;
    testing::write_all(project_file(tmp), kTemplateStyle);
    auto s = load_export_settings(tmp.str());
    REQUIRE(s.ok());
    const auto before = stdfs::last_write_time(project_file(tmp));
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    CHECK(testing::read_all(project_file(tmp)) == kTemplateStyle);
    CHECK(stdfs::last_write_time(project_file(tmp)) == before);
}

TEST_CASE("export settings: save patches icon and export only, keeping the file's own layout") {
    testing::TempDir tmp;
    testing::write_all(project_file(tmp), kTemplateStyle);
    auto s = load_export_settings(tmp.str());
    REQUIRE(s.ok());
    s->icon = "assets/icon.png";
    s->android.format = "aab";
    s->android.minSdk = 28;
    s->android.permissions = {"android.permission.VIBRATE"};
    s->android.signing = {"keys/up.jks", "up"};
    s->macos.copyright = "(c) Me";
    s->linux.categories = {"Game", "ActionGame"};
    s->ios.teamId = "ABCDE12345";
    REQUIRE(save_export_settings(tmp.str(), *s).ok());

    const std::string text = testing::read_all(project_file(tmp));
    // Everything before the new keys is byte for byte what it was (the last member gained a comma).
    const std::string head = std::string(kTemplateStyle).substr(0, std::string(kTemplateStyle).rfind("\n}"));
    CHECK(text.rfind(head + ",\n", 0) == 0);
    // New members follow the file's style: 2-space indent, scalar arrays inline.
    CHECK(text.find("\n  \"icon\": \"assets/icon.png\",\n  \"export\": {\n    \"macos\": {") != std::string::npos);
    CHECK(text.find("\"categories\": [\"Game\", \"ActionGame\"]") != std::string::npos);
    CHECK(text.find("\"permissions\": [\"android.permission.VIBRATE\"]") != std::string::npos);
    CHECK(text.find("\"format\": \"aab\"") != std::string::npos);
    CHECK(text.back() == '\n');

    // It reads back the same, and the other keys survived.
    auto back = load_export_settings(tmp.str());
    REQUIRE(back.ok());
    CHECK(back->icon == "assets/icon.png");
    CHECK(back->android == s->android);
    CHECK(back->macos == s->macos);
    CHECK(back->linux == s->linux);
    CHECK(back->ios == s->ios);
    Json j = parse(text.c_str());
    CHECK(j["name"] == "Space Dodge");
    CHECK(j["display"]["scaleMode"] == "fit");
    CHECK(j["input"]["actions"]["jump"].size() == 3);
    CHECK(j["feedbackFile"] == "ENGINE_FEEDBACK.json");

    // Setting everything back to the defaults removes the keys again, and so the file is what it was.
    back->icon.clear();
    back->android = AndroidExportSettings{};
    back->macos = MacosExportSettings{};
    back->linux = LinuxExportSettings{};
    back->ios = IosExportSettings{};
    REQUIRE(save_export_settings(tmp.str(), *back).ok());
    CHECK(testing::read_all(project_file(tmp)) == kTemplateStyle);
}

TEST_CASE("export settings: fields equal to their defaults are not written") {
    testing::TempDir tmp;
    testing::write_all(project_file(tmp), kTemplateStyle);
    auto s = load_export_settings(tmp.str());
    REQUIRE(s.ok());
    s->android.format = "apk";  // the default
    s->android.minSdk = 26;
    s->macos.category = "public.app-category.games";
    s->ios.iconBackground = "#FFFFFF";
    s->android.versionCode = 0;
    s->android.permissions = {};
    s->android.icon = "assets/android.png";  // the only real change
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    Json j = parse(testing::read_all(project_file(tmp)).c_str());
    REQUIRE(j.contains("export"));
    CHECK(j["export"].size() == 1);
    CHECK(j["export"]["android"].size() == 1);
    CHECK(j["export"]["android"]["icon"] == "assets/android.png");
}

TEST_CASE("export settings: save keeps the indentation, array style and line endings of the file") {
    testing::TempDir tmp;

    // 1. dump_json style: every array element on its own line -> arrays stay exploded
    testing::write_all(project_file(tmp), kDumpStyle);
    auto a = load_export_settings(tmp.str());
    REQUIRE(a.ok());
    a->linux.categories = {"Game", "ArcadeGame"};
    a->icon = "icon.png";
    REQUIRE(save_export_settings(tmp.str(), *a).ok());
    std::string text = testing::read_all(project_file(tmp));
    CHECK(text.find("\"categories\": [\n        \"Game\",\n        \"ArcadeGame\"\n      ]") != std::string::npos);
    CHECK(text.find("  \"platforms\": [\n    \"windows\",\n    \"macos\"\n  ],\n") != std::string::npos);  // untouched
    CHECK(text.back() == '}');  // no trailing newline appeared: the file had none
    REQUIRE(load_export_settings(tmp.str()).ok());

    // 2. four-space indent
    testing::write_all(project_file(tmp), "{\n    \"name\": \"G\",\n    \"platforms\": [\"linux\"]\n}\n");
    auto b = load_export_settings(tmp.str());
    REQUIRE(b.ok());
    b->android.format = "aab";
    REQUIRE(save_export_settings(tmp.str(), *b).ok());
    text = testing::read_all(project_file(tmp));
    CHECK(text == "{\n    \"name\": \"G\",\n    \"platforms\": [\"linux\"],\n    \"export\": {\n        \"android\": {\n            \"format\": \"aab\"\n        }\n    }\n}\n");

    // 3. tabs
    testing::write_all(project_file(tmp), "{\n\t\"name\": \"G\"\n}\n");
    auto t = load_export_settings(tmp.str());
    REQUIRE(t.ok());
    t->icon = "i.png";
    REQUIRE(save_export_settings(tmp.str(), *t).ok());
    CHECK(testing::read_all(project_file(tmp)) == "{\n\t\"name\": \"G\",\n\t\"icon\": \"i.png\"\n}\n");

    // 4. Windows line endings
    testing::write_all(project_file(tmp), "{\r\n  \"name\": \"G\"\r\n}\r\n");
    auto c = load_export_settings(tmp.str());
    REQUIRE(c.ok());
    c->ios.teamId = "ABCDE12345";
    REQUIRE(save_export_settings(tmp.str(), *c).ok());
    text = testing::read_all(project_file(tmp));
    CHECK(text == "{\r\n  \"name\": \"G\",\r\n  \"export\": {\r\n    \"ios\": {\r\n      \"teamId\": \"ABCDE12345\"\r\n    }\r\n  }\r\n}\r\n");

    // 5. an empty object and a one-line file
    testing::write_all(project_file(tmp), "{}");
    auto e = load_export_settings(tmp.str());
    REQUIRE(e.ok());
    e->icon = "i.png";
    REQUIRE(save_export_settings(tmp.str(), *e).ok());
    CHECK(parse(testing::read_all(project_file(tmp)).c_str())["icon"] == "i.png");
    testing::write_all(project_file(tmp), "{\"name\":\"G\",\"id\":\"a.b\"}");
    auto o = load_export_settings(tmp.str());
    REQUIRE(o.ok());
    o->icon = "i.png";
    REQUIRE(save_export_settings(tmp.str(), *o).ok());
    Json one = parse(testing::read_all(project_file(tmp)).c_str());
    CHECK(one["icon"] == "i.png");
    CHECK(one["id"] == "a.b");
}

TEST_CASE("export settings: save replaces and removes members wherever they sit in the file") {
    testing::TempDir tmp;
    // icon first, export in the middle, strings with braces and escapes around them
    testing::write_all(project_file(tmp), R"({
  "icon": "old.png",
  "name": "A {tricky} \"name\"",
  "export": {"android": {"format": "aab"}, "unknownPlatform": {"x": [1, 2]}},
  "version": "1.0.0"
}
)");
    auto s = load_export_settings(tmp.str());
    REQUIRE(s.ok());
    CHECK(s->icon == "old.png");
    s->icon = "new.png";
    s->android.format = "apk";  // back to the default: removed from the object
    s->macos.copyright = "(c)";
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    Json j = parse(testing::read_all(project_file(tmp)).c_str());
    CHECK(j["icon"] == "new.png");
    CHECK(j["name"] == "A {tricky} \"name\"");
    CHECK(j["version"] == "1.0.0");
    CHECK_FALSE(j["export"].contains("android"));         // its only field went back to the default
    CHECK(j["export"]["macos"]["copyright"] == "(c)");
    CHECK(j["export"]["unknownPlatform"]["x"].size() == 2);  // unknown keys are kept
    CHECK(j.items().begin().key() == "icon");              // key order kept

    // remove icon (first member) and export (middle member)
    s = load_export_settings(tmp.str());
    s->icon.clear();
    s->macos = MacosExportSettings{};
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    j = parse(testing::read_all(project_file(tmp)).c_str());
    CHECK_FALSE(j.contains("icon"));
    CHECK(j["export"].size() == 1);  // only the unknown platform is left
    CHECK(j.size() == 3);

    // last and only members
    testing::write_all(project_file(tmp), "{\n  \"name\": \"G\",\n  \"icon\": \"i.png\"\n}\n");
    s = load_export_settings(tmp.str());
    s->icon.clear();
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    CHECK(testing::read_all(project_file(tmp)) == "{\n  \"name\": \"G\"\n}\n");
    testing::write_all(project_file(tmp), "{\n  \"icon\": \"i.png\"\n}\n");
    s = load_export_settings(tmp.str());
    s->icon.clear();
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    CHECK(testing::read_all(project_file(tmp)) == "{\n}\n");
    CHECK(parse(testing::read_all(project_file(tmp)).c_str()).empty());
}

TEST_CASE("export settings: save refuses a missing or broken factoria.json and never writes a broken one") {
    testing::TempDir tmp;
    ProjectExportSettings s;
    s.icon = "i.png";
    auto missing = save_export_settings(tmp.sub("nothing"), s);
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("does not exist") != std::string::npos);
    testing::write_all(project_file(tmp), "{ nope");
    auto broken = save_export_settings(tmp.str(), s);
    REQUIRE_FALSE(broken.ok());
    CHECK(broken.error().hint.find("Fix the JSON syntax") != std::string::npos);
    CHECK(testing::read_all(project_file(tmp)) == "{ nope");  // untouched
    testing::write_all(project_file(tmp), "[]");
    CHECK_FALSE(save_export_settings(tmp.str(), s).ok());
}

// ---------------------------------------------------------------------------------------------------- machine config

TEST_CASE("machine export config: the path follows HOME, with an override") {
    CHECK(machine_export_config_path(env_of({{"FACTORIA_EXPORT_CONFIG", "/x/y.json"}, {"HOME", "/home/me"}})) == "/x/y.json");
#ifndef _WIN32
    CHECK(machine_export_config_path(env_of({{"HOME", "/home/me"}})) == "/home/me/.factoria/export.json");
#else
    CHECK(machine_export_config_path(env_of({{"USERPROFILE", "C:\\Users\\me"}})) == "C:\\Users\\me\\.factoria\\export.json");
#endif
    CHECK(machine_export_config_path(env_of({})) == ".factoria/export.json");
}

TEST_CASE("machine export config: load, save and round trip") {
    testing::TempDir tmp;
    const std::string path = tmp.sub("home/.factoria/export.json");
    auto none = load_machine_export_config(path);
    REQUIRE(none.ok());  // a missing file is not an error
    CHECK(none->androidSdk.empty());
    CHECK(none->sourcePath.empty());

    MachineExportConfig cfg;
    cfg.androidSdk = "/sdk";
    cfg.androidJdk = "/jdk";
    cfg.androidKeystorePassword = "store-secret";
    cfg.androidKeyPassword = "key-secret";
    REQUIRE(save_machine_export_config(cfg, path).ok());
    Json j = parse(testing::read_all(path).c_str());
    CHECK(j["format"] == "factoria.export-config/1");
    CHECK(j["android"]["sdk"] == "/sdk");
    CHECK(j["android"]["keyPassword"] == "key-secret");

    auto back = load_machine_export_config(path);
    REQUIRE(back.ok());
    CHECK(back->androidSdk == "/sdk");
    CHECK(back->androidJdk == "/jdk");
    CHECK(back->androidKeystorePassword == "store-secret");
    CHECK(back->androidKeyPassword == "key-secret");
    CHECK(back->sourcePath == path);
    CHECK(back->warnings.empty());

#ifndef _WIN32
    struct stat st {};
    REQUIRE(stat(path.c_str(), &st) == 0);
    CHECK((st.st_mode & 0777) == 0600);  // it holds passwords
    chmod(path.c_str(), 0644);
    auto open = load_machine_export_config(path);
    REQUIRE(open.ok());
    REQUIRE(open->warnings.size() == 1);
    CHECK(open->warnings[0].find("chmod 600") != std::string::npos);
#endif

    // Empty values are removed; keys of other versions are kept.
    testing::write_all(path, R"({"format": "factoria.export-config/1", "future": {"a": 1}, "android": {"sdk": "/old", "other": true}})");
    MachineExportConfig update;
    update.androidJdk = "/jdk2";
    REQUIRE(save_machine_export_config(update, path).ok());
    j = parse(testing::read_all(path).c_str());
    CHECK(j["future"]["a"] == 1);
    CHECK(j["android"]["jdk"] == "/jdk2");
    CHECK(j["android"]["other"] == true);
    CHECK_FALSE(j["android"].contains("sdk"));
    MachineExportConfig empty;
    REQUIRE(save_machine_export_config(empty, path).ok());
    CHECK(parse(testing::read_all(path).c_str()).contains("android") == true);  // "other" is still there
}

TEST_CASE("machine export config: bad files give errors that name the key") {
    testing::TempDir tmp;
    const std::string path = tmp.sub("export.json");
    testing::write_all(path, "{ nope");
    auto syntax = load_machine_export_config(path);
    REQUIRE_FALSE(syntax.ok());
    CHECK(syntax.error().message.find("export.json") != std::string::npos);
    testing::write_all(path, R"({"format": "factoria.export-config/9"})");
    auto format = load_machine_export_config(path);
    REQUIRE_FALSE(format.ok());
    CHECK(format.error().message.find("#/format") != std::string::npos);
    testing::write_all(path, R"({"android": {"sdk": 5}})");
    auto type = load_machine_export_config(path);
    REQUIRE_FALSE(type.ok());
    CHECK(type.error().message.find("#/android/sdk") != std::string::npos);
    CHECK(type.error().hint.find("factoria.export-config/1") != std::string::npos);
    testing::write_all(path, "[1]");
    CHECK_FALSE(load_machine_export_config(path).ok());
}

TEST_CASE("machine export config: environment variables win over the file for the passwords") {
    MachineExportConfig cfg;
    cfg.androidKeystorePassword = "file-store";
    cfg.androidKeyPassword = "file-key";
    auto file = resolve_android_signing_secrets(cfg, env_of({}));
    CHECK(file.keystorePassword == "file-store");
    CHECK(file.keystorePasswordFrom == "export.json");
    CHECK(file.keyPassword == "file-key");
    auto env = resolve_android_signing_secrets(cfg, env_of({{"FACTORIA_ANDROID_KEYSTORE_PASSWORD", "env-store"},
                                                            {"FACTORIA_ANDROID_KEY_PASSWORD", "env-key"}}));
    CHECK(env.keystorePassword == "env-store");
    CHECK(env.keystorePasswordFrom == "FACTORIA_ANDROID_KEYSTORE_PASSWORD");
    CHECK(env.keyPassword == "env-key");
    CHECK(env.keyPasswordFrom == "FACTORIA_ANDROID_KEY_PASSWORD");
    // key password defaults to the keystore password
    MachineExportConfig onlyStore;
    onlyStore.androidKeystorePassword = "s";
    auto same = resolve_android_signing_secrets(onlyStore, env_of({}));
    CHECK(same.keyPassword == "s");
    CHECK(same.keyPasswordFrom == "keystore password");
    auto nothing = resolve_android_signing_secrets({}, env_of({}));
    CHECK(nothing.keystorePassword.empty());
    CHECK(nothing.keystorePasswordFrom.empty());
}

// ---------------------------------------------------------------------------------------------------- toolchain

namespace {

// A folder that looks like a JDK. `version` goes into <jdk>/release as JAVA_VERSION (empty = no release file).
std::string make_jdk(const testing::TempDir& tmp, const std::string& rel, const std::string& version, bool javac = true) {
    const stdfs::path root = stdfs::path(tmp.str()) / rel;
    testing::write_all(root / "bin" / "java", "");
    if (javac) testing::write_all(root / "bin" / "javac", "");
    if (!version.empty()) testing::write_all(root / "release", "IMPLEMENTOR=\"Test\"\nJAVA_VERSION=\"" + version + "\"\nOS_NAME=\"Linux\"\n");
    return root.string();
}

std::string make_sdk(const testing::TempDir& tmp, const std::string& rel, bool licenses = true) {
    const stdfs::path root = stdfs::path(tmp.str()) / rel;
    stdfs::create_directories(root / "platform-tools");
    if (licenses) testing::write_all(root / "licenses" / "android-sdk-license", "abc");
    return root.string();
}

bool any_contains(const std::vector<std::string>& list, const std::string& text) {
    for (const auto& s : list)
        if (s.find(text) != std::string::npos) return true;
    return false;
}

AndroidToolchainSearch search_with(std::map<std::string, std::string> vars, std::vector<AndroidToolchainCandidate> jdk = {},
                                   std::vector<AndroidToolchainCandidate> sdk = {}) {
    AndroidToolchainSearch s;
    s.env = env_of(std::move(vars));
    s.jdk = std::move(jdk);
    s.sdk = std::move(sdk);
    return s;
}

}  // namespace

TEST_CASE("android toolchain: the JDK major version comes from the release file") {
    testing::TempDir tmp;
    CHECK(jdk_major_version(make_jdk(tmp, "a", "17.0.9")) == 17);
    CHECK(jdk_major_version(make_jdk(tmp, "b", "21")) == 21);
    CHECK(jdk_major_version(make_jdk(tmp, "c", "1.8.0_392")) == 8);
    CHECK(jdk_major_version(make_jdk(tmp, "d", "")) == 0);
    CHECK(jdk_major_version(tmp.sub("nowhere")) == 0);
}

TEST_CASE("android toolchain: configured folders win, then the environment, then the usual places") {
    testing::TempDir tmp;
    const std::string cfgJdk = make_jdk(tmp, "cfg/jdk", "17.0.1");
    const std::string envJdk = make_jdk(tmp, "env/jdk", "21.0.2");
    const std::string studioJdk = make_jdk(tmp, "studio/jbr", "17.0.9");
    const std::string cfgSdk = make_sdk(tmp, "cfg/sdk");
    const std::string homeSdk = make_sdk(tmp, "env/android_home");
    const std::string rootSdk = make_sdk(tmp, "env/sdk_root");
    const std::string defaultSdk = make_sdk(tmp, "default/sdk");
    const std::vector<AndroidToolchainCandidate> jdks = {{studioJdk, "Android Studio"}};
    const std::vector<AndroidToolchainCandidate> sdks = {{defaultSdk, "default location"}};

    MachineExportConfig cfg;
    cfg.androidJdk = cfgJdk;
    cfg.androidSdk = cfgSdk;
    auto all = find_android_toolchain(cfg, search_with({{"JAVA_HOME", envJdk}, {"ANDROID_HOME", homeSdk}, {"ANDROID_SDK_ROOT", rootSdk}}, jdks, sdks));
    CHECK(all.ok());
    CHECK(all.jdk == cfgJdk);
    CHECK(all.jdkFrom == "config");
    CHECK(all.jdkMajor == 17);
    CHECK(all.sdk == cfgSdk);
    CHECK(all.sdkFrom == "config");

    MachineExportConfig none;
    auto env = find_android_toolchain(none, search_with({{"JAVA_HOME", envJdk}, {"ANDROID_HOME", homeSdk}, {"ANDROID_SDK_ROOT", rootSdk}}, jdks, sdks));
    CHECK(env.ok());
    CHECK(env.jdk == envJdk);
    CHECK(env.jdkFrom == "JAVA_HOME");
    CHECK(env.jdkMajor == 21);
    CHECK(env.sdk == homeSdk);
    CHECK(env.sdkFrom == "ANDROID_HOME");

    auto root = find_android_toolchain(none, search_with({{"ANDROID_SDK_ROOT", rootSdk}}, jdks, sdks));
    CHECK(root.sdk == rootSdk);
    CHECK(root.sdkFrom == "ANDROID_SDK_ROOT");

    auto places = find_android_toolchain(none, search_with({}, jdks, sdks));
    CHECK(places.ok());
    CHECK(stdfs::path(places.jdk) == stdfs::path(studioJdk));  // a candidate comes back with this OS's separators
    CHECK(places.jdkFrom == "Android Studio");
    CHECK(stdfs::path(places.sdk) == stdfs::path(defaultSdk));
    CHECK(places.sdkFrom == "default location");
    CHECK(places.warnings.empty());
}

TEST_CASE("android toolchain: version patterns try the newest Unity Hub editor first") {
    testing::TempDir tmp;
    make_jdk(tmp, "Hub/Editor/2022.3.10f1/PlaybackEngines/AndroidPlayer/OpenJDK", "11.0.14");
    const std::string newest = make_jdk(tmp, "Hub/Editor/6000.0.70f1/PlaybackEngines/AndroidPlayer/OpenJDK", "17.0.9");
    make_jdk(tmp, "Hub/Editor/2021.3.1f1/PlaybackEngines/AndroidPlayer/OpenJDK", "8.0.1");
    const std::string newestSdk = make_sdk(tmp, "Hub/Editor/6000.0.70f1/PlaybackEngines/AndroidPlayer/SDK");
    make_sdk(tmp, "Hub/Editor/2022.3.10f1/PlaybackEngines/AndroidPlayer/SDK");
    const std::string pattern = (stdfs::path(tmp.str()) / "Hub/Editor/*/PlaybackEngines/AndroidPlayer").string();

    auto tc = find_android_toolchain({}, search_with({}, {{pattern + "/OpenJDK", "Unity Hub"}}, {{pattern + "/SDK", "Unity Hub"}}));
    CHECK(tc.ok());
    CHECK(stdfs::path(tc.jdk) == stdfs::path(newest));  // 6000 > 2022 > 2021 numerically, not as text
    CHECK(tc.jdkFrom == "Unity Hub");
    CHECK(stdfs::path(tc.sdk) == stdfs::path(newestSdk));

    // An older editor is skipped when the newest has no usable JDK (here: Java 11 only).
    testing::TempDir old;
    make_jdk(old, "Hub/Editor/9999.0.0f1/PlaybackEngines/AndroidPlayer/OpenJDK", "11.0.14");
    const std::string good = make_jdk(old, "Hub/Editor/2022.3.10f1/PlaybackEngines/AndroidPlayer/OpenJDK", "17.0.9");
    auto skip = find_android_toolchain({}, search_with({}, {{(stdfs::path(old.str()) / "Hub/Editor/*/PlaybackEngines/AndroidPlayer/OpenJDK").string(), "Unity Hub"}}));
    CHECK(stdfs::path(skip.jdk) == stdfs::path(good));
}

TEST_CASE("android toolchain: a configured folder that is not usable is skipped with a warning, or is the problem") {
    testing::TempDir tmp;
    const std::string good = make_jdk(tmp, "studio/jbr", "17.0.9");
    MachineExportConfig cfg;
    cfg.androidJdk = tmp.sub("gone/jdk");
    cfg.sourcePath = "/home/me/.factoria/export.json";
    auto fell = find_android_toolchain(cfg, search_with({}, {{good, "Android Studio"}}));
    CHECK(stdfs::path(fell.jdk) == stdfs::path(good));
    CHECK(fell.jdkFrom == "Android Studio");
    REQUIRE(fell.warnings.size() >= 1);
    CHECK(any_contains(fell.warnings, "The JDK folder in /home/me/.factoria/export.json is not usable"));
    CHECK(any_contains(fell.warnings, "does not exist"));
    CHECK(any_contains(fell.warnings, "Using the Android Studio JDK"));
    CHECK_FALSE(fell.ok());  // only because this search has no SDK

    // nothing else to fall back on: that is what blocks the build, with the fix
    auto stuck = find_android_toolchain(cfg, search_with({}));
    CHECK_FALSE(stuck.ok());
    CHECK(any_contains(stuck.problems, "The JDK folder in /home/me/.factoria/export.json is not usable"));
    CHECK(any_contains(stuck.problems, "Platform settings > Android"));
    CHECK(any_contains(stuck.problems, "No JDK 17 or newer found"));
    CHECK(any_contains(stuck.problems, "adoptium.net"));
    CHECK(stuck.jdk.empty());
}

TEST_CASE("android toolchain: JDK problems say what is wrong") {
    testing::TempDir tmp;
    // too old
    const std::string old = make_jdk(tmp, "jdk11", "11.0.14");
    auto tc = find_android_toolchain({}, search_with({{"JAVA_HOME", old}}));
    CHECK_FALSE(tc.ok());
    CHECK(tc.jdk == old);  // shown so that the UI can say "this one is too old"
    CHECK(tc.jdkMajor == 11);
    CHECK(any_contains(tc.problems, "is Java 11"));
    CHECK(any_contains(tc.problems, "needs Java 17 or newer"));
    CHECK(any_contains(tc.problems, "JAVA_HOME is not usable"));

    // a JRE
    const std::string jre = make_jdk(tmp, "jre", "17.0.9", /*javac=*/false);
    tc = find_android_toolchain({}, search_with({{"JAVA_HOME", jre}}));
    CHECK(any_contains(tc.problems, "without javac"));

    // not a JDK folder at all
    stdfs::create_directories(stdfs::path(tmp.str()) / "empty");
    tc = find_android_toolchain({}, search_with({{"JAVA_HOME", tmp.sub("empty")}}));
    CHECK(any_contains(tc.problems, "has no bin/java"));

    // no release file: the version cannot be told
    const std::string norelease = make_jdk(tmp, "norelease", "");
    tc = find_android_toolchain({}, search_with({{"JAVA_HOME", norelease}}));
    CHECK(any_contains(tc.problems, "Cannot tell the Java version"));

    // a JDK 21 is fine; "~" in the config means the home folder
    const std::string jdk21 = make_jdk(tmp, "home/jdks/21", "21.0.1");
    MachineExportConfig cfg;
    cfg.androidJdk = "~/jdks/21";
    tc = find_android_toolchain(cfg, search_with({{"HOME", tmp.sub("home")}}));
    CHECK(tc.jdk == tmp.sub("home") + "/jdks/21");
    CHECK(tc.jdkMajor == 21);
    CHECK(tc.jdkFrom == "config");
}

TEST_CASE("android toolchain: SDK problems and warnings") {
    testing::TempDir tmp;
    // not an SDK
    stdfs::create_directories(stdfs::path(tmp.str()) / "notsdk" / "bin");
    auto tc = find_android_toolchain({}, search_with({{"ANDROID_HOME", tmp.sub("notsdk")}}));
    CHECK_FALSE(tc.ok());
    CHECK(any_contains(tc.problems, "does not look like an Android SDK"));
    CHECK(any_contains(tc.problems, "ANDROID_HOME is not usable"));
    CHECK(any_contains(tc.problems, "No Android SDK found"));
    CHECK(any_contains(tc.problems, "developer.android.com/studio"));
    CHECK(any_contains(tc.problems, "Platform settings > Android"));
    CHECK(any_contains(tc.problems, "~/.factoria/export.json"));

    // an SDK is recognised by platform-tools/, platforms/ or licenses/
    for (const char* sub : {"platforms", "licenses"}) {
        stdfs::create_directories(stdfs::path(tmp.str()) / sub / "sdk" / sub);
        tc = find_android_toolchain({}, search_with({{"ANDROID_HOME", tmp.sub(std::string(sub) + "/sdk")}}));
        CHECK(tc.sdk == tmp.sub(std::string(sub) + "/sdk"));
        CHECK(any_contains(tc.problems, "No Android SDK found") == false);
    }

    // licenses not accepted: usable, but worth a warning
    const std::string nolic = make_sdk(tmp, "nolic", /*licenses=*/false);
    tc = find_android_toolchain({}, search_with({{"ANDROID_HOME", nolic}}));
    CHECK(tc.sdk == nolic);
    CHECK(any_contains(tc.problems, "No Android SDK found") == false);
    CHECK(any_contains(tc.warnings, "sdkmanager --licenses"));

    // ANDROID_HOME that is gone falls back to ANDROID_SDK_ROOT with a warning
    const std::string root = make_sdk(tmp, "root");
    tc = find_android_toolchain({}, search_with({{"ANDROID_HOME", tmp.sub("gone")}, {"ANDROID_SDK_ROOT", root}}));
    CHECK(tc.sdk == root);
    CHECK(tc.sdkFrom == "ANDROID_SDK_ROOT");
    CHECK(any_contains(tc.warnings, "ANDROID_HOME is not usable"));
}

TEST_CASE("android toolchain: nothing installed lists both problems and to_json says so") {
    auto tc = find_android_toolchain({}, search_with({}));
    CHECK_FALSE(tc.ok());
    CHECK(tc.problems.size() == 2);
    CHECK(any_contains(tc.problems, "No JDK 17 or newer found"));
    CHECK(any_contains(tc.problems, "No Android SDK found"));
    Json j = tc.to_json();
    CHECK(j["ok"] == false);
    CHECK(j["problems"].size() == 2);
    CHECK(j["jdk"] == "");
}

TEST_CASE("android toolchain: the default search lists this OS's usual places") {
    AndroidToolchainSearch s = default_android_toolchain_search();
    CHECK_FALSE(s.jdk.empty());
    CHECK_FALSE(s.sdk.empty());
    bool unity = false;
    for (const auto& c : s.jdk) unity = unity || c.from == "Unity Hub";
    CHECK(unity);
    for (const auto& c : s.jdk) CHECK_FALSE(c.path.empty());
    // The real machine's result is only checked for being well formed (what is installed varies).
    AndroidToolchain tc = find_android_toolchain({}, s);
    CHECK((tc.ok() || !tc.problems.empty()));
}

TEST_CASE("export settings: scriptBytecode defaults to true, can be switched off and must be a boolean") {
    CHECK(parse_export_settings(parse(R"({"name": "G"})")).settings.scriptBytecode);
    CHECK(parse_export_settings(parse(R"({"export": {"linux": {}}})")).settings.scriptBytecode);
    auto off = parse_export_settings(parse(R"({"export": {"scriptBytecode": false}})"));
    CHECK(off.errors.empty());
    CHECK(off.warnings.empty());  // a known key, not a typo
    CHECK_FALSE(off.settings.scriptBytecode);
    auto on = parse_export_settings(parse(R"({"export": {"scriptBytecode": true}})"));
    CHECK(on.errors.empty());
    CHECK(on.settings.scriptBytecode);

    auto bad = parse_export_settings(parse(R"({"export": {"scriptBytecode": "no"}})"));
    REQUIRE(bad.errors.size() == 1);
    CHECK(bad.errors[0].pointer == "/export/scriptBytecode");
    CHECK(bad.errors[0].message.find("expected true or false") != std::string::npos);
    CHECK(bad.errors[0].hint.find("\"scriptBytecode\": false") != std::string::npos);
    CHECK(bad.settings.scriptBytecode);  // an invalid value keeps the default

    auto typo = parse_export_settings(parse(R"({"export": {"scriptByteCode": false}})"));
    REQUIRE(!typo.warnings.empty());
    CHECK(typo.warnings[0].pointer == "/export/scriptByteCode");
    CHECK(typo.warnings[0].hint.find("scriptBytecode") != std::string::npos);  // did you mean
}

TEST_CASE("export settings: scriptBytecode is saved only when it is not the default") {
    testing::TempDir tmp;
    testing::write_all(project_file(tmp), kTemplateStyle);
    auto s = load_export_settings(tmp.str());
    REQUIRE(s.ok());
    CHECK(s->scriptBytecode);
    s->scriptBytecode = false;
    REQUIRE(save_export_settings(tmp.str(), *s).ok());
    Json j = parse(testing::read_all(project_file(tmp)).c_str());
    REQUIRE(j.contains("export"));
    CHECK(j["export"]["scriptBytecode"] == false);
    CHECK(j["name"] == "Space Dodge");  // the rest of the file is as it was

    auto back = load_export_settings(tmp.str());
    REQUIRE(back.ok());
    CHECK_FALSE(back->scriptBytecode);
    back->scriptBytecode = true;  // the default again: the key goes away, and so does the empty "export"
    REQUIRE(save_export_settings(tmp.str(), *back).ok());
    CHECK(testing::read_all(project_file(tmp)) == kTemplateStyle);
}

TEST_CASE("find_ffmpeg: the environment variable, then export.json, then PATH") {
    testing::TempDir t;
    testing::write_all(t.path / "tools" / "ffmpeg", "x");
    testing::write_all(t.path / "other" / "ffmpeg.exe", "x");
    testing::write_all(t.path / "export.json", R"({"publish": {"ffmpeg": ")" + (t.path / "other" / "ffmpeg.exe").generic_string() + R"("}})");
    const std::string config = (t.path / "export.json").string();
    const auto env = [&](const std::string& name) -> std::string { return name == "FACTORIA_FFMPEG" ? (t.path / "tools").generic_string() : ""; };
    auto found = find_ffmpeg(env, config);
    REQUIRE(found.ok());
    CHECK(found->path == (t.path / "tools" / "ffmpeg").generic_string());  // a folder: the executable inside
    CHECK(found->from == "FACTORIA_FFMPEG");
    const auto none = [](const std::string&) -> std::string { return ""; };
    found = find_ffmpeg(none, config);
    REQUIRE(found.ok());
    CHECK(found->path == (t.path / "other" / "ffmpeg.exe").generic_string());
    CHECK(found->from == "export.json");
    // A variable that points at nothing is an error, not a silent fall-through to PATH.
    const auto wrong = [&](const std::string& name) -> std::string { return name == "FACTORIA_FFMPEG" ? (t.path / "nowhere").generic_string() : ""; };
    const auto bad = find_ffmpeg(wrong, config);
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("FACTORIA_FFMPEG") != std::string::npos);
    CHECK(bad.error().hint.find("ffmpeg.org") != std::string::npos);
    const auto onPath = find_ffmpeg(none, (t.path / "missing.json").string());
    CHECK(onPath.ok() == !which("ffmpeg").empty());
}
