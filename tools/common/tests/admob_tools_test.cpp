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
#include "fa/tooling/plugin_manifest.h"
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

// Declares the admob plugin for a platform (the folder is the template's, without the build).
void add_plugin(const std::string& dir, const char* platform = "android") {
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    auto r = reg.call("project.new_plugin", Json::parse(std::string(R"({"name": "admob", "template": "admob", "platforms": [")") + platform + R"("]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
}

// A stand-in for Google's SDK download: the two XCFrameworks with one file each, under the folder name of the real zip.
std::vector<std::pair<std::string, std::string>> fake_sdk_files(const std::string& root = "GoogleMobileAdsSdkiOS-13.11.0/") {
    return {{root + "GoogleMobileAds.xcframework/Info.plist", "<plist/>"},
            {root + "GoogleMobileAds.xcframework/ios-arm64/GoogleMobileAds.framework/GoogleMobileAds", "binary"},
            {root + "UserMessagingPlatform.xcframework/Info.plist", "<plist/>"},
            {root + "UserMessagingPlatform.xcframework/ios-arm64/UserMessagingPlatform.framework/UserMessagingPlatform", "binary"}};
}

void write_fake_sdk_folder(const stdfs::path& folder) {
    for (const auto& [name, contents] : fake_sdk_files()) testing::write_all(folder / name, contents);
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

TEST_CASE("admob template: the iOS side is Swift over Google's XCFrameworks, which the repository never holds") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    add_plugin(dir, "ios");
    const stdfs::path plugin = stdfs::path(dir) / "plugins/admob";

    auto manifest = load_json_file((plugin / "ios/plugin.json").string());
    REQUIRE(manifest.ok());
    CHECK((*manifest)["swift"] == true);
    REQUIRE((*manifest)["xcframeworks"].size() == 2);
    CHECK((*manifest)["xcframeworks"][0] == "frameworks/GoogleMobileAds.xcframework");
    CHECK((*manifest)["xcframeworks"][1] == "frameworks/UserMessagingPlatform.xcframework");
    CHECK((*manifest)["infoPlist"]["SKAdNetworkItems"].size() > 20);  // Google's list of ad networks
    CHECK_FALSE((*manifest)["infoPlist"].contains("GADApplicationIdentifier"));  // the export writes it from the catalog
    const auto reread = parse_plugin_manifest(testing::read_all(plugin / "ios/plugin.json"), "ios/plugin.json");
    REQUIRE_MESSAGE(reread.ok(), (reread.ok() ? "" : reread.error().to_string()));
    CHECK(reread->xcframeworks.size() == 2);

    for (const char* swift : {"src/Plugin.swift", "src/Ads.swift", "src/Common.swift", "src/Errors.swift", "src/entry.c", "include/module.modulemap"})
        CHECK_MESSAGE(stdfs::exists(plugin / swift), swift);
    const std::string cmake = testing::read_all(plugin / "CMakeLists.txt");
    CHECK(has(cmake, "project(admob NONE)"));  // the Apple build; Android's CMake stays in the same file
    CHECK(has(cmake, "FA_ADMOB_SLICES"));

    // UMP first, then ATT only on request, and the Swift side reads what the export wrote.
    const std::string swift = testing::read_all(plugin / "src/Ads.swift");
    CHECK(has(swift, "ATTrackingManager"));
    CHECK(has(swift, "FactoriaAdsTrackingPrompt"));
    CHECK(has(swift, kAdmobSampleRewardedUnitIos));
    const std::string plugin_swift = testing::read_all(plugin / "src/Plugin.swift");
    CHECK(has(plugin_swift, "adsServices = \"[\\\"ads\\\"]\""));
    for (const char* other : {"purchases", "achievements", "leaderboards"}) CHECK_FALSE(has(plugin_swift, std::string("\\\"") + other + "\\\""));

    // The Google SDK never goes in git.
    const std::string ignore = testing::read_all(plugin / ".gitignore");
    CHECK(has(ignore, "/ios/frameworks/"));
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
    REQUIRE(props.contains("admobPlatforms"));
    CHECK(props["admobPlatforms"]["items"]["enum"] == Json::parse(R"(["android", "ios"])"));
    REQUIRE(props.contains("sdk"));
    CHECK(has(props["sdk"].value("description", std::string()), "GoogleMobileAds.xcframework"));
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
        CHECK(r.result["libraries"].empty());
        CHECK(r.result["appId"] == "");
        CHECK(r.result["audience"] == "general");

        auto settings = load_project(dir);
        REQUIRE(settings.ok());
        REQUIRE(settings->plugins.size() == 1);
        CHECK(settings->plugins[0].name == "admob");
        CHECK(settings->plugins[0].platforms == std::vector<std::string>{"android", "ios"});

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
        CHECK_FALSE(has(steps, "\"more_time\", \"double_coins\" have no ids.admob yet"));  // only the one without a unit is flagged
        CHECK(has(steps, "The placements \"more_time\", \"double_coins\" have no ids.admob_ios yet"));  // iOS has its own units: neither has one
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
    auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobPlatforms": ["android"]})"));
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

// ------------------------------------------------------------------------------------------------------------------ iOS --
TEST_CASE("platform.add_backend admob: iOS copies Google's XCFrameworks from a folder or a zip and keeps them out of git") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    const stdfs::path frameworks = stdfs::path(dir) / "plugins/admob/ios/frameworks";
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);

    SUBCASE("an unpacked folder") {
        write_fake_sdk_folder(tmp.sub("download"));
        const Json args = Json::object({{"backend", "admob"}, {"admobPlatforms", Json::array({"ios"})}, {"admobBuild", false}, {"sdk", tmp.sub("download")}});
        auto r = reg.call("platform.add_backend", args);
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(stdfs::exists(frameworks / "GoogleMobileAds.xcframework/ios-arm64/GoogleMobileAds.framework/GoogleMobileAds"));
        CHECK(stdfs::exists(frameworks / "UserMessagingPlatform.xcframework/Info.plist"));
        CHECK(r.result["libraries"].empty());
        CHECK(r.result["platforms"] == Json::parse(R"(["ios"])"));
        CHECK(r.result["iosAppId"] == "");
        const std::string done = joined(r.result["done"]);
        CHECK(has(done, "copied GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework"));
        CHECK(has(done, "never commit them"));
        CHECK(has(done, "did not build iOS (admobBuild is false)"));

        auto settings = load_project(dir);
        REQUIRE(settings.ok());
        REQUIRE(settings->plugins.size() == 1);
        CHECK(settings->plugins[0].platforms == std::vector<std::string>{"ios"});

        // The plugin's .gitignore covers what was copied.
        CHECK(has(testing::read_all(stdfs::path(dir) / "plugins/admob/.gitignore"), "/ios/frameworks/"));

        const std::string steps = joined(r.result["nextSteps"]);
        CHECK(has(steps, "appIds"));
        CHECK(has(steps, "\"ios\""));
        CHECK(has(steps, "ids.admob_ios"));
        CHECK(has(steps, "App Tracking Transparency"));
        CHECK(has(steps, "trackingPrompt"));
        CHECK(has(steps, "GADApplicationIdentifier"));
        CHECK_FALSE(has(steps, "AdMob console (admob.google.com), Android"));  // nothing about Android when it is not asked for

        // Running it again replaces the frameworks.
        testing::write_all(frameworks / "GoogleMobileAds.xcframework/stale.txt", "old");
        auto again = reg.call("platform.add_backend", args);
        REQUIRE_MESSAGE(again.ok, again.error.dump());
        CHECK_FALSE(stdfs::exists(frameworks / "GoogleMobileAds.xcframework/stale.txt"));
    }

    SUBCASE("a .zip, whose frameworks sit in a folder inside") {
        testing::write_stored_zip(tmp.sub("GoogleMobileAdsSdkiOS-13.11.0.zip"), fake_sdk_files());
        auto r = reg.call("platform.add_backend", Json::object({{"backend", "admob"}, {"admobPlatforms", Json::array({"ios"})}, {"admobBuild", false},
                                                                {"sdk", tmp.sub("GoogleMobileAdsSdkiOS-13.11.0.zip")}}));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(stdfs::exists(frameworks / "GoogleMobileAds.xcframework/Info.plist"));
        CHECK(stdfs::exists(frameworks / "UserMessagingPlatform.xcframework/ios-arm64/UserMessagingPlatform.framework/UserMessagingPlatform"));
    }

    SUBCASE("a relative path starts in the project folder") {
        write_fake_sdk_folder(stdfs::path(dir) / "vendor");
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobPlatforms": ["ios"], "admobBuild": false, "sdk": "vendor"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(stdfs::exists(frameworks / "GoogleMobileAds.xcframework/Info.plist"));
    }

    SUBCASE("dryRun lists the copy and writes nothing") {
        write_fake_sdk_folder(tmp.sub("download"));
        auto r = reg.call("platform.add_backend", Json::object({{"backend", "admob"}, {"admobPlatforms", Json::array({"ios"})}, {"admobBuild", false},
                                                                {"sdk", tmp.sub("download")}, {"dryRun", true}}));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(has(joined(r.result["wouldDo"]), "would copy GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework"));
        CHECK(has(r.result["files"].dump(), "plugins/admob/ios/frameworks/GoogleMobileAds.xcframework"));
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins"));
        CHECK_FALSE(load_json_file(dir + "/factoria.json")->contains("plugins"));
    }

    SUBCASE("without sdk and without Xcode work, the next steps say where to get it") {
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobPlatforms": ["ios"], "admobBuild": false})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK_FALSE(stdfs::exists(frameworks));
        const std::string steps = joined(r.result["nextSteps"]);
        CHECK(has(steps, "developers.google.com/admob/ios/quick-start"));
        CHECK(has(steps, "\"sdk\""));
    }

    SUBCASE("a build with no SDK in place does not build iOS and says why") {
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobPlatforms": ["ios"]})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        const std::string done = joined(r.result["done"]);
#if defined(__APPLE__)
        CHECK(has(done, "did not build iOS: Google's SDK is not in"));
        CHECK(has(joined(r.result["nextSteps"]), "Download Google's Mobile Ads SDK for iOS"));
#else
        CHECK(has(done, "did not build iOS: Swift and Google's iOS SDK need a Mac with Xcode"));
#endif
        CHECK(r.result["libraries"].empty());
        CHECK(stdfs::exists(stdfs::path(dir) / "plugins/admob/ios/plugin.json"));
    }
}

TEST_CASE("platform.add_backend admob: a wrong sdk or platform is refused before anything is written") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);
    const auto refused = [&](const Json& extra, const char* code, const char* message) {
        Json args = Json::object({{"backend", "admob"}, {"admobPlatforms", Json::array({"ios"})}, {"admobBuild", false}});
        for (auto it = extra.begin(); it != extra.end(); ++it) args[it.key()] = it.value();
        auto r = reg.call("platform.add_backend", args);
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == code);
        CHECK_MESSAGE(has(r.error["message"].get<std::string>(), message), r.error["message"].dump());
        CHECK_FALSE(r.error.value("hint", std::string()).empty());
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins"));
        CHECK_FALSE(load_json_file(dir + "/factoria.json")->contains("plugins"));
        return r;
    };

    SUBCASE("a path that does not exist") {
        auto r = refused(Json::object({{"sdk", tmp.sub("nowhere.zip")}}), "not_found", "does not exist");
        CHECK(has(r.error["hint"].get<std::string>(), "developers.google.com/admob/ios/quick-start"));
    }
    SUBCASE("a file that is not a zip") {
        testing::write_all(tmp.sub("sdk.tar"), "x");
        refused(Json::object({{"sdk", tmp.sub("sdk.tar")}}), "invalid_argument", "but not a .zip");
    }
    SUBCASE("a folder that is not Google's SDK") {
        testing::write_all(tmp.sub("other/GoogleMobileAds.xcframework/Info.plist"), "<plist/>");  // only one of the two
        refused(Json::object({{"sdk", tmp.sub("other")}}), "invalid_argument", "is not the Google Mobile Ads SDK for iOS");
    }
    SUBCASE("a zip without the frameworks") {
        testing::write_stored_zip(tmp.sub("empty.zip"), {{"readme.txt", "nothing"}});
        refused(Json::object({{"sdk", tmp.sub("empty.zip")}}), "invalid_argument", "is not the Google Mobile Ads SDK for iOS");
    }
    SUBCASE("sdk for an Android-only plugin") {
        write_fake_sdk_folder(tmp.sub("download"));
        auto r = refused(Json::object({{"admobPlatforms", Json::array({"android"})}, {"sdk", tmp.sub("download")}}), "invalid_argument", "admobPlatforms has no ios");
        CHECK(has(r.error["hint"].get<std::string>(), "Add \"ios\""));
    }
    SUBCASE("a platform AdMob has no SDK for") {
        // The schema lists android and ios, so the call is refused before the backend runs.
        refused(Json::object({{"admobPlatforms", Json::array({"macos"})}}), "invalid_arguments", "/admobPlatforms/0");
    }
}

TEST_CASE("platform.add_backend admob: the plugin is never declared for macOS, which has no AdMob SDK") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);
    auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "admob", "admobBuild": false})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    auto settings = load_project(dir);
    REQUIRE(settings.ok());
    REQUIRE(settings->plugins.size() == 1);
    for (const std::string& platform : settings->plugins[0].platforms) CHECK(platform != "macos");
    // The template still carries a macOS entry point that offers nothing, so a Mac build of a project that lists the plugin links.
    const std::string entry = testing::read_all(stdfs::path(dir) / "plugins/admob/src/entry.c");
    CHECK(has(entry, "macOS"));
}

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

TEST_CASE("ads_ios_settings: a development export carries Google's iOS sample app id; a release export the catalog's") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp, R"({"ads": {"appIds": {"android": "ca-app-pub-1234567890123456~1234567890", "ios": "ca-app-pub-1234567890123456~0987654321"},
                                              "audience": "mixed", "placements": [{"id": "p"}]}})");
    CHECK_FALSE(ads_ios_settings(dir, false).present);  // no plugin yet
    add_plugin(dir, "ios");
    const AdsIosSettings dev = ads_ios_settings(dir, false);
    CHECK(dev.present);
    CHECK(dev.appId == kAdmobSampleAppIdIos);
    CHECK(dev.test);
    CHECK(dev.audience == "mixed");
    CHECK_FALSE(dev.trackingPrompt);
    const AdsIosSettings release = ads_ios_settings(dir, true);
    CHECK(release.appId == "ca-app-pub-1234567890123456~0987654321");  // not the Android one
    CHECK_FALSE(release.test);

    set_platform(dir, kCatalog);
    CHECK(ads_ios_settings(dir, true).appId == kAdmobSampleAppIdIos);  // no id: the sample, so the app still starts
    CHECK(ads_ios_settings(dir, true).audience == "general");
}

TEST_CASE("ads_ios_settings: the tracking sentence is the catalog's, the default, or one per language from the locale key") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp, R"({"ads": {"trackingPrompt": true, "placements": [{"id": "p"}]}})");
    add_plugin(dir, "ios");
    AdsIosSettings s = ads_ios_settings(dir, false);
    CHECK(s.trackingPrompt);
    CHECK(s.trackingDescription == kDefaultTrackingDescription);
    CHECK(s.trackingDescriptions.empty());

    set_platform(dir, R"({"ads": {"trackingPrompt": true, "trackingDescription": "Plain \"text\".", "placements": [{"id": "p"}]}})");
    CHECK(ads_ios_settings(dir, false).trackingDescription == "Plain \"text\".");

    // A locale key wins, and each language of the game gets its own sentence (a language that lacks the key falls back to the default's).
    set_platform(dir, R"({"ads": {"trackingPrompt": true, "trackingDescription": "Plain.", "trackingDescriptionKey": "ads.tracking", "placements": [{"id": "p"}]}})");
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["localization"] = Json::parse(R"({"defaultLanguage": "en", "languages": ["en", "es", "ja"]})");
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
    testing::write_all(stdfs::path(dir) / "locales/en.json", R"({"ads.tracking": "Ads that fit you."})");
    testing::write_all(stdfs::path(dir) / "locales/es.json", R"({"ads.tracking": "Anuncios a tu medida."})");
    testing::write_all(stdfs::path(dir) / "locales/ja.json", R"({"other": "x"})");
    s = ads_ios_settings(dir, false);
    CHECK(s.trackingDescription == "Ads that fit you.");
    REQUIRE(s.trackingDescriptions.size() == 3);
    CHECK(s.trackingDescriptions["en"] == "Ads that fit you.");
    CHECK(s.trackingDescriptions["es"] == "Anuncios a tu medida.");
    CHECK(s.trackingDescriptions["ja"] == "Ads that fit you.");
}

TEST_CASE("check_ads for iOS: its own app id, its own ad units and the tracking prompt") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    add_plugin(dir, "ios");

    SUBCASE("no app id and a placement without an iOS unit") {
        const std::string text = all_text(check_ads(dir));
        CHECK(has(text, "/platform/ads/appIds/ios: the game has the admob plugin for iOS but platform.ads.appIds.ios is not set"));
        CHECK(has(text, "/platform/ads/placements/0/ids: the placement \"more_time\" has no \"ids\": {\"admob_ios\": ...}"));
        CHECK(has(text, "/platform/ads/placements/1/ids: the placement \"double_coins\" has no \"ids\": {\"admob_ios\": ...}"));  // its unit is Android's
        CHECK(has(text, "the Android unit (ids.admob) does not work on iOS"));
        CHECK_FALSE(has(text, "Android but"));
        CHECK(check_ads(dir, "android").empty());  // an Android export has nothing to say about an iOS-only plugin
        CHECK(all_text(check_ads(dir, "ios")) == text);
    }
    SUBCASE("Google's iOS samples and ids of the wrong shape") {
        set_platform(dir.c_str(), R"({"ads": {"appIds": {"ios": "ca-app-pub-3940256099942544~1458002511"},
            "placements": [{"id": "a", "ids": {"admob_ios": "ca-app-pub-3940256099942544/1712485313"}},
                           {"id": "b", "ids": {"admob_ios": "ca-app-pub-1234567890123456~1234567890"}}]}})");
        const std::string text = all_text(check_ads(dir, "ios"));
        CHECK(has(text, "platform.ads.appIds.ios is Google's sample app id"));
        CHECK(has(text, "the placement \"a\" uses Google's sample ad unit"));
        CHECK(has(text, "/platform/ads/placements/1/ids/admob_ios"));
        CHECK(has(text, "is not an AdMob ad unit id"));
    }
    SUBCASE("good ids say nothing") {
        set_platform(dir.c_str(), R"({"ads": {"appIds": {"ios": "ca-app-pub-1234567890123456~1234567890"},
            "placements": [{"id": "a", "ids": {"admob_ios": "ca-app-pub-1234567890123456/1234567890"}}]}})");
        CHECK(check_ads(dir).empty());
    }
    SUBCASE("a game with both plugins sees each platform's problems") {
        stdfs::remove_all(stdfs::path(dir) / "plugins");
        auto project = load_json_file(dir + "/factoria.json");
        REQUIRE(project.ok());
        project->erase("plugins");
        REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
        add_plugin(dir, "android\", \"ios");
        set_platform(dir.c_str(), R"({"ads": {"appIds": {"android": "ca-app-pub-1234567890123456~1234567890"},
            "placements": [{"id": "a", "ids": {"admob": "ca-app-pub-1234567890123456/1234567890"}}]}})");
        CHECK(check_ads(dir, "android").empty());
        const std::string text = all_text(check_ads(dir));
        CHECK(has(text, "platform.ads.appIds.ios is not set"));
        CHECK_FALSE(has(text, "Android but"));
    }
    SUBCASE("the tracking prompt on a game without the iOS plugin never shows the sheet") {
        stdfs::remove_all(stdfs::path(dir) / "plugins");
        auto project = load_json_file(dir + "/factoria.json");
        REQUIRE(project.ok());
        project->erase("plugins");
        REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
        set_platform(dir.c_str(), R"({"ads": {"trackingPrompt": true, "placements": [{"id": "a"}]}})");
        const std::string text = all_text(check_ads(dir));
        CHECK(has(text, "/platform/ads/trackingPrompt: platform.ads.trackingPrompt is true but the game has no ads plugin for iOS"));
        CHECK(check_ads(dir, "android").empty());
        // With the plugin for iOS the warning goes away.
        add_plugin(dir, "ios");
        CHECK_FALSE(has(all_text(check_ads(dir)), "trackingPrompt"));
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
