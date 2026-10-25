// The tooling side of the AdMob ads backend (docs/PLATFORM.md, "Ads"): the plugin template, platform.add_backend {"backend": "admob"},
// what a release export and `factoria validate` say about the ids, and the manifest values the export writes. The Java and the C
// bridge are built by the engine's CI (Android emulator job): nothing here needs an NDK, a Gradle or a device.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <map>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/tooling/ads_release.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "fa/tooling/validate.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kCatalog = R"({
  "ads": {"placements": [{"id": "more_time", "type": "rewarded"}, {"id": "double_coins", "ids": {"admob": "ca-app-pub-1234567890123456/1234567890"}}]}
})";

std::string make_game(const testing::TempDir& tmp, const char* platform = kCatalog) {
    const std::string dir = tmp.sub("game");
    ScaffoldOptions so;
    so.name = "Space Dodge";
    so.id = "com.example.spacedodge";
    REQUIRE(create_project(dir, "2d-empty", so).ok());
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["platform"] = Json::parse(platform);
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
    return dir;
}

// Declares the admob plugin for Android (the folder is the template's, without the build).
void add_plugin(const std::string& dir) {
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    auto r = reg.call("project.new_plugin", Json::parse(R"({"name": "admob", "template": "admob", "platforms": ["android"]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
}

void set_platform(const std::string& dir, const char* platform) {
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["platform"] = Json::parse(platform);
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
}

std::string joined(const Json& list) {
    std::string out;
    for (const Json& s : list) out += s.get<std::string>() + "\n";
    return out;
}

std::string all_text(const std::vector<AdsIssue>& issues) {
    std::string out;
    for (const AdsIssue& i : issues) out += i.pointer + ": " + i.message + " | " + i.hint + "\n";
    return out;
}

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

AndroidToolchainSearch nothing_found() {
    AndroidToolchainSearch s;
    s.env = [](const std::string&) { return std::string(); };
    return s;
}

}  // namespace

TEST_CASE("admob template: every placeholder is replaced and the backend offers only ads") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    add_plugin(dir);
    const stdfs::path plugin = stdfs::path(dir) / "plugins/admob";

    for (const auto& entry : stdfs::recursive_directory_iterator(plugin)) {
        CHECK_MESSAGE(entry.path().generic_string().find("{{") == std::string::npos, entry.path().generic_string());
        if (entry.is_regular_file()) CHECK_MESSAGE(testing::read_all(entry.path()).find("{{NAME}}") == std::string::npos, entry.path().generic_string());
    }

    const std::string cmake = testing::read_all(plugin / "CMakeLists.txt");
    CHECK(has(cmake, "project(admob C)"));
    CHECK(has(cmake, "android/src/main/jniLibs/"));
    CHECK(has(cmake, "max-page-size=16384"));  // 16 KB pages
    CHECK(has(cmake, "sdkmanager"));

    const std::string bridge = testing::read_all(plugin / "src/plugin.c");
    CHECK(has(bridge, "#define BACKEND_NAME \"admob\""));
    CHECK(has(bridge, "add_backend"));

    const stdfs::path module = plugin / "android";
    const std::string gradle = testing::read_all(module / "build.gradle");
    CHECK(has(gradle, "namespace 'factoria.plugin.admob'"));
    CHECK(has(gradle, "com.google.android.gms:play-services-ads:"));
    CHECK(has(gradle, "com.google.android.ump:user-messaging-platform:"));

    // The manifest reads the three values the export writes (platforms/android/app/build.gradle).
    const std::string manifest = testing::read_all(module / "src/main/AndroidManifest.xml");
    CHECK(has(manifest, "com.google.android.gms.ads.APPLICATION_ID"));
    CHECK(has(manifest, "${factoriaAdsAppId}"));
    CHECK(has(manifest, "factoria.ads.test"));
    CHECK(has(manifest, "${factoriaAdsTest}"));
    CHECK(has(manifest, "${factoriaAdsAudience}"));

    // The Java: only "ads" is offered, and the sample ids are Google's own.
    const std::string backend = testing::read_all(module / "src/main/java/factoria/plugin/admob/Backend.java");
    CHECK(has(backend, "\"ads\""));
    for (const char* other : {"\"purchases\"", "\"achievements\"", "\"stats\"", "\"leaderboards\"", "\"integrity\""}) CHECK_FALSE(has(backend, other));
    const std::string ads = testing::read_all(module / "src/main/java/factoria/plugin/admob/Ads.java");
    CHECK(has(ads, kAdmobSampleRewardedUnit));
}

TEST_CASE("platform.add_backend admob: is listed with the arguments it reads") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);
    const CommandInfo* info = reg.info("platform.add_backend");
    REQUIRE(info != nullptr);
    const Json& props = info->inputSchema["properties"];
    REQUIRE(props.contains("admobBuild"));
    CHECK(props["admobBuild"]["default"] == true);
    CHECK_FALSE(props["admobBuild"].value("description", std::string()).empty());
    CHECK(has(info->description, "admob: "));
}

TEST_CASE("platform.add_backend admob: writes the plugin for Android and lists the AdMob console steps with the game's own placements") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    const AndroidToolchainSearch none = nothing_found();
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir, &none);

    SUBCASE("admobBuild false writes and declares the plugin without building") {
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobBuild": false})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["backend"] == "admob");
        CHECK(stdfs::exists(stdfs::path(dir) / "plugins/admob/src/plugin.c"));
        CHECK(stdfs::exists(stdfs::path(dir) / "plugins/admob/android/src/main/java/factoria/plugin/admob/Ads.java"));
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/admob/build-arm64-v8a"));
        CHECK_FALSE(r.result.contains("libraries"));
        CHECK(r.result["appId"] == "");
        CHECK(r.result["audience"] == "general");

        auto settings = load_project(dir);
        REQUIRE(settings.ok());
        REQUIRE(settings->plugins.size() == 1);
        CHECK(settings->plugins[0].name == "admob");
        CHECK(settings->plugins[0].platforms == std::vector<std::string>{"android"});

        const std::string done = joined(r.result["done"]);
        CHECK(has(done, "created the plugin 'admob'"));
        CHECK(has(done, "did not build"));

        const std::string steps = joined(r.result["nextSteps"]);
        CHECK(has(steps, "test app id"));                             // a development export needs nothing
        CHECK(has(steps, "com.example.spacedodge"));                  // the app to add in AdMob
        CHECK(has(steps, "\"appIds\""));
        CHECK(has(steps, "not set yet"));
        CHECK(has(steps, "\"more_time\""));                           // a placement without a unit
        CHECK(has(steps, "The placements \"more_time\" have no ids.admob yet"));
        CHECK(has(steps, "\"more_time\", \"double_coins\""));  // both are listed
        CHECK_FALSE(has(steps, "\"more_time\", \"double_coins\" have no"));  // only the one without a unit is flagged
        CHECK(has(steps, "Privacy & messaging"));
        CHECK(has(steps, "Children and consent"));
        CHECK(has(steps, "admob.status"));

        // Adding it again keeps the plugin.
        auto again = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobBuild": false})"));
        REQUIRE_MESSAGE(again.ok, again.error.dump());
        CHECK(has(joined(again.result["done"]), "kept the plugin 'admob'"));
        CHECK(load_project(dir)->plugins.size() == 1);
    }

    SUBCASE("the app id and the audience of the catalog are quoted") {
        set_platform(dir.c_str(), R"({"ads": {"appIds": {"android": "ca-app-pub-1234567890123456~1234567890"}, "audience": "mixed",
                                      "placements": [{"id": "more_time", "ids": {"admob": "ca-app-pub-1234567890123456/1234567890"}}]}})");
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobBuild": false})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["appId"] == "ca-app-pub-1234567890123456~1234567890");
        CHECK(r.result["audience"] == "mixed");
        const std::string steps = joined(r.result["nextSteps"]);
        CHECK(has(steps, "The catalog has ca-app-pub-1234567890123456~1234567890 already"));
        CHECK(has(steps, "ageGate"));
        CHECK_FALSE(has(steps, "have no ids.admob yet"));
    }
}

TEST_CASE("platform.add_backend admob: a computer without the Android NDK says what to install and writes nothing") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    AndroidToolchainSearch search = nothing_found();
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir, &search);
    auto none = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob"})"));
    REQUIRE_FALSE(none.ok);
    CHECK(none.error["code"] == "unavailable");
    CHECK(has(none.error["message"].get<std::string>(), "no Android SDK"));
    const std::string hint = none.error["hint"].get<std::string>();
    CHECK(has(hint, "sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\""));
    CHECK(has(hint, "admobBuild"));  // the way out names this backend's own flag
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/admob"));
    CHECK_FALSE(load_json_file(dir + "/factoria.json")->contains("plugins"));
}

#if !defined(_WIN32)
TEST_CASE("platform.add_backend admob: builds the bridge for each ABI") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    const stdfs::path sdk = tmp.sub("sdk");
    const stdfs::path log = tmp.sub("cmake-calls.txt");
    testing::write_all(sdk / "platform-tools" / "adb", "");
    testing::write_all(sdk / "ndk" / "27.2.12479018" / "build" / "cmake" / "android.toolchain.cmake", "");
    testing::write_all(sdk / "cmake" / "3.31.6" / "bin" / "ninja", "");
    const stdfs::path cmake = sdk / "cmake" / "3.31.6" / "bin" / "cmake";
    testing::write_all(cmake, "#!/bin/sh\necho \"$*\" >> '" + log.string() + R"('
if [ "$1" = "--build" ]; then
  abi="${2##*/build-}"
  folder="${2%/build-*}"
  mkdir -p "$folder/android/src/main/jniLibs/$abi"
  : > "$folder/android/src/main/jniLibs/$abi/libadmob.so"
fi
)");
    stdfs::permissions(cmake, stdfs::perms::owner_exec | stdfs::perms::owner_read | stdfs::perms::owner_write, stdfs::perm_options::add);

    AndroidToolchainSearch search = nothing_found();
    search.env = [&](const std::string& name) { return name == "ANDROID_HOME" ? sdk.string() : std::string(); };
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir, &search);
    auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["libraries"].size() == 2);
    CHECK(r.result["libraries"][0] == "android/src/main/jniLibs/arm64-v8a/libadmob.so");
    CHECK(r.result["libraries"][1] == "android/src/main/jniLibs/x86_64/libadmob.so");
    const std::string calls = testing::read_all(log);
    CHECK(has(calls, "-DANDROID_ABI=arm64-v8a"));
    CHECK(has(calls, "-DANDROID_ABI=x86_64"));
    CHECK(has(calls, "-DCMAKE_TOOLCHAIN_FILE=" + sdk.generic_string() + "/ndk/27.2.12479018/build/cmake/android.toolchain.cmake"));
}
#endif

// ------------------------------------------------------------------------------------------- ids, export and validate --
TEST_CASE("ads_export_settings: a development export always carries Google's sample app id; a release export the catalog's") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp, R"({"ads": {"appIds": {"android": "ca-app-pub-1234567890123456~1234567890"}, "audience": "children",
                                              "placements": [{"id": "p"}]}})");
    const AdsExportSettings dev = ads_export_settings(dir, false);
    CHECK(dev.appId == kAdmobSampleAppId);
    CHECK(dev.test);
    CHECK(dev.audience == "children");
    const AdsExportSettings release = ads_export_settings(dir, true);
    CHECK(release.appId == "ca-app-pub-1234567890123456~1234567890");
    CHECK_FALSE(release.test);

    // No app id in a release: the sample id, so the app still starts (and check_ads warns).
    set_platform(dir, kCatalog);
    CHECK(ads_export_settings(dir, true).appId == kAdmobSampleAppId);
    CHECK(ads_export_settings(dir, true).audience == "general");
    CHECK_FALSE(ads_export_settings(dir, true).test);
}

TEST_CASE("check_ads: a game with the admob plugin and no app id, the sample ids or a placement without a unit gets a warning") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);

    SUBCASE("without the plugin there is nothing to say about ids") {
        CHECK(check_ads(dir).empty());
    }
    SUBCASE("with the plugin: no app id, a placement without a unit") {
        add_plugin(dir);
        const auto issues = check_ads(dir);
        const std::string text = all_text(issues);
        CHECK(has(text, "/platform/ads/appIds/android: the game has the admob plugin for Android but platform.ads.appIds.android is not set"));
        CHECK(has(text, "/platform/ads/placements/0/ids: the placement \"more_time\" has no \"ids\": {\"admob\": ...}"));
        CHECK_FALSE(has(text, "double_coins"));  // that one has a good unit
        CHECK(issues.size() == 2);
    }
    SUBCASE("the sample ids and ids of the wrong shape") {
        add_plugin(dir);
        set_platform(dir.c_str(), R"({"ads": {"appIds": {"android": "ca-app-pub-3940256099942544~3347511713"},
            "placements": [{"id": "a", "ids": {"admob": "ca-app-pub-3940256099942544/5224354917"}},
                           {"id": "b", "ids": {"admob": "ca-app-pub-1234567890123456~1234567890"}}]}})");
        const std::string text = all_text(check_ads(dir));
        CHECK(has(text, "platform.ads.appIds.android is Google's sample app id"));
        CHECK(has(text, "the placement \"a\" uses Google's sample ad unit"));
        CHECK(has(text, "is not an AdMob ad unit id"));
        CHECK(has(text, "An id with a tilde (~) is the app id"));
    }
    SUBCASE("good ids say nothing") {
        add_plugin(dir);
        set_platform(dir.c_str(), R"({"ads": {"appIds": {"android": "ca-app-pub-1234567890123456~1234567890"},
            "placements": [{"id": "a", "ids": {"admob": "ca-app-pub-1234567890123456/1234567890"}}]}})");
        CHECK(check_ads(dir).empty());
    }
    SUBCASE("a mixed audience needs a script that asks the age") {
        set_platform(dir.c_str(), R"({"ads": {"audience": "mixed", "placements": [{"id": "a"}]}})");
        const std::string text = all_text(check_ads(dir));
        CHECK(has(text, "/platform/ads/audience: the audience is \"mixed\" but no script calls platform.ads.setUnderAge()"));
        CHECK(has(text, "ageGate"));
        testing::write_all(stdfs::path(dir) / "scripts" / "age.js", "export function ask() { platform.ads.setUnderAge(false); }\n");
        CHECK(check_ads(dir).empty());
    }
}

TEST_CASE("validate: the ads setup warns, and an app id that is an ad unit is an error that teaches") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    add_plugin(dir);
    const ValidationReport r = validate_project(dir);
    bool appId = false, unit = false;
    for (const ValidationIssue& w : r.warnings) {
        if (w.pointer == "/platform/ads/appIds/android") appId = true;
        if (w.pointer == "/platform/ads/placements/0/ids") unit = true;
    }
    CHECK(appId);
    CHECK(unit);
    CHECK(r.ok);  // warnings only: a development export works without ids

    set_platform(dir.c_str(), R"({"ads": {"appIds": {"android": "ca-app-pub-1234567890123456/1234567890"}, "placements": [{"id": "a"}]}})");
    const ValidationReport bad = validate_project(dir);
    CHECK_FALSE(bad.ok);
    bool taught = false;
    for (const ValidationIssue& e : bad.errors)
        if (e.pointer == "/platform/ads/appIds/android" && has(e.message, "is not an AdMob app id") && has(e.hint, "ad unit")) taught = true;
    CHECK(taught);
}
