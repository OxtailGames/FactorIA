// The tooling side of the Google Play backend (docs/PLATFORM.md, "Google Play"): the plugin template and
// platform.add_backend {"backend": "googleplay"}. The Java and the C bridge are built by the engine's CI (Android emulator job):
// nothing here needs an NDK, a Gradle or a device.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <map>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// A game with a package name and a catalog that has a good and a bad product id, and one achievement with an id of Play's.
std::string make_game(const testing::TempDir& tmp) {
    const std::string dir = tmp.sub("game");
    ScaffoldOptions so;
    so.name = "Space Dodge";
    so.id = "com.example.spacedodge";
    REQUIRE(create_project(dir, "2d-empty", so).ok());
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["platform"] = Json::parse(R"({
      "achievements": [{"id": "first_win", "name": "First win"}, {"id": "perfect", "name": "Perfect", "ids": {"googleplay": "CgkIperfect123"}}],
      "leaderboards": [{"id": "high_score", "name": "High score"}],
      "products": [{"id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99},
                   {"id": "Remove_Ads", "type": "nonConsumable", "title": "No ads", "price": 2.99}]})");
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());
    return dir;
}

std::string joined(const Json& list) {
    std::string out;
    for (const Json& s : list) out += s.get<std::string>() + "\n";
    return out;
}

// The android search that finds nothing: no environment, no usual folders (the SDK of the machine running the tests is not seen).
AndroidToolchainSearch nothing_found() {
    AndroidToolchainSearch s;
    s.env = [](const std::string&) { return std::string(); };
    return s;
}

const char* kIdsFile = "plugins/googleplay/android/src/main/res/values/games-ids.xml";

}  // namespace

TEST_CASE("googleplay template: every placeholder is replaced and the backend is the one the catalog's ids are keyed by") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    auto r = reg.call("project.new_plugin", Json::parse(R"({"name": "googleplay", "template": "googleplay", "platforms": ["android"]})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const stdfs::path plugin = stdfs::path(dir) / "plugins/googleplay";

    // No file or folder name and no text keeps a {{NAME}}.
    for (const auto& entry : stdfs::recursive_directory_iterator(plugin)) {
        CHECK_MESSAGE(entry.path().generic_string().find("{{") == std::string::npos, entry.path().generic_string());
        if (entry.is_regular_file()) CHECK_MESSAGE(testing::read_all(entry.path()).find("{{NAME}}") == std::string::npos, entry.path().generic_string());
    }

    const std::string cmake = testing::read_all(plugin / "CMakeLists.txt");
    CHECK(cmake.find("project(googleplay C)") != std::string::npos);
    CHECK(cmake.find("android/src/main/jniLibs/") != std::string::npos);
    CHECK(cmake.find("max-page-size=16384") != std::string::npos);  // 16 KB pages
    CHECK(cmake.find("sdkmanager") != std::string::npos);            // the configure error on a host build teaches

    // The bridge registers the backend "googleplay" and loads the Java class of the plugin.
    const std::string bridge = testing::read_all(plugin / "src/plugin.c");
    CHECK(bridge.find("#define BACKEND_NAME \"googleplay\"") != std::string::npos);
    CHECK(bridge.find("add_backend") != std::string::npos);
    CHECK(bridge.find("FA_PLUGIN_INIT(FA_PLUGIN_NAME)") != std::string::npos);
    CHECK(testing::read_all(plugin / "include/fa_plugin.h").find("add_backend") != std::string::npos);

    // The Gradle module: the namespace, the three Google libraries, the Play Games id read from a string resource.
    const stdfs::path module = plugin / "android";
    const std::string gradle = testing::read_all(module / "build.gradle");
    CHECK(gradle.find("namespace 'factoria.plugin.googleplay'") != std::string::npos);
    CHECK(gradle.find("com.android.billingclient:billing:") != std::string::npos);
    CHECK(gradle.find("com.google.android.gms:play-services-games-v2:") != std::string::npos);
    CHECK(gradle.find("com.google.android.play:integrity:") != std::string::npos);
    const std::string manifest = testing::read_all(module / "src/main/AndroidManifest.xml");
    CHECK(manifest.find("com.google.android.gms.games.APP_ID") != std::string::npos);
    CHECK(manifest.find("@string/game_services_project_id") != std::string::npos);
    CHECK(testing::read_all(plugin / "android/src/main/res/values/games-ids.xml").find("game_services_project_id\" translatable=\"false\"></string>") !=
          std::string::npos);  // empty: Play Games is off until a project id is set

    // The Java: services that never include stats or presence; the Play Games ones only with a project id.
    const std::string backend = testing::read_all(module / "src/main/java/factoria/plugin/googleplay/Backend.java");
    CHECK(backend.find("services.put(\"purchases\")") != std::string::npos);
    CHECK(backend.find("services.put(\"integrity\")") != std::string::npos);
    CHECK(backend.find("\"stats\"") == std::string::npos);
    CHECK(backend.find("\"presence\"") == std::string::npos);
    CHECK(backend.find("gamesId.isEmpty()") != std::string::npos);
}

TEST_CASE("platform.add_backend googleplay: is listed with the arguments it reads") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir);
    const CommandInfo* info = reg.info("platform.add_backend");
    REQUIRE(info != nullptr);
    const Json& props = info->inputSchema["properties"];
    REQUIRE(props.contains("playGamesId"));
    REQUIRE(props.contains("googleplayBuild"));
    CHECK(props["googleplayBuild"]["default"] == true);
    CHECK_FALSE(props["playGamesId"].value("description", std::string()).empty());
    CHECK(info->description.find("googleplay: the Google Play Billing") != std::string::npos);
}

TEST_CASE("platform.add_backend googleplay: writes the plugin for Android, keeps and sets the Play Games id, lists the Play Console steps") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    const AndroidToolchainSearch none = nothing_found();
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir, &none);

    SUBCASE("googleplayBuild false writes and declares the plugin without building, for Android only") {
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["backend"] == "googleplay");
        CHECK(stdfs::exists(stdfs::path(dir) / "plugins/googleplay/src/plugin.c"));
        CHECK(stdfs::exists(stdfs::path(dir) / "plugins/googleplay/android/src/main/java/factoria/plugin/googleplay/Backend.java"));
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/googleplay/build-arm64-v8a"));
        CHECK_FALSE(r.result.contains("libraries"));
        CHECK(r.result["playGamesId"] == "");

        auto settings = load_project(dir);
        REQUIRE(settings.ok());
        REQUIRE(settings->plugins.size() == 1);
        CHECK(settings->plugins[0].name == "googleplay");
        CHECK(settings->plugins[0].platforms == std::vector<std::string>{"android"});

        const std::string done = joined(r.result["done"]);
        CHECK(done.find("created the plugin 'googleplay'") != std::string::npos);
        CHECK(done.find("did not build") != std::string::npos);

        // The next steps use the game's package name, its catalog and the rules of Play's ids.
        const std::string steps = joined(r.result["nextSteps"]);
        CHECK(steps.find("com.example.spacedodge") != std::string::npos);
        CHECK(steps.find("license tester") != std::string::npos);
        CHECK(steps.find("\"gems_100\"") != std::string::npos);
        CHECK(steps.find("Monetize with Play") != std::string::npos);
        CHECK(steps.find("\"Remove_Ads\"") != std::string::npos);  // listed, and flagged by the id rules below
        CHECK(steps.find("lowercase letters, digits, _ and .") != std::string::npos);
        CHECK(steps.find("\"first_win\"") != std::string::npos);
        CHECK(steps.find("\"CgkIperfect123\"") != std::string::npos);
        CHECK(steps.find("\"high_score\"") != std::string::npos);
        CHECK(steps.find("achievement first_win, leaderboard high_score") != std::string::npos);  // no ids.googleplay yet
        CHECK(steps.find("achievement perfect") == std::string::npos);                              // this one has it
        CHECK(steps.find("ids.googleplay") != std::string::npos);
        CHECK(steps.find("playGamesId") != std::string::npos);  // Play Games is still off
        CHECK(steps.find("Saved Games") != std::string::npos);
        CHECK(steps.find("SHA-1") != std::string::npos);
        CHECK(steps.find("Play Integrity") != std::string::npos);
        CHECK(steps.find("googleplay.status") != std::string::npos);

        // Without a playGamesId the file is left as it is (empty).
        CHECK(testing::read_all(stdfs::path(dir) / kIdsFile).find("translatable=\"false\"></string>") != std::string::npos);
    }

    SUBCASE("playGamesId is written to games-ids.xml, kept when the next call does not pass it, and \"\" turns Play Games off") {
        auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false, "playGamesId": "123456789012"})"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["playGamesId"] == "123456789012");
        const std::string xml = testing::read_all(stdfs::path(dir) / kIdsFile);
        CHECK(xml.find("<string name=\"game_services_project_id\" translatable=\"false\">123456789012</string>") != std::string::npos);
        CHECK(xml.find("<resources>") != std::string::npos);  // the rest of the file is untouched
        CHECK(joined(r.result["done"]).find("set the Play Games project id 123456789012") != std::string::npos);
        CHECK(joined(r.result["nextSteps"]).find("The project id 123456789012 is set already") != std::string::npos);

        auto again = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false})"));
        REQUIRE_MESSAGE(again.ok, again.error.dump());
        CHECK(again.result["playGamesId"] == "123456789012");
        CHECK(testing::read_all(stdfs::path(dir) / kIdsFile) == xml);
        CHECK(joined(again.result["done"]).find("kept the plugin 'googleplay'") != std::string::npos);
        CHECK(load_project(dir)->plugins.size() == 1);

        auto same = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false, "playGamesId": 123456789012})"));
        REQUIRE_MESSAGE(same.ok, same.error.dump());  // a number works too
        CHECK(joined(same.result["done"]).find("kept the Play Games project id 123456789012") != std::string::npos);

        auto off = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false, "playGamesId": ""})"));
        REQUIRE_MESSAGE(off.ok, off.error.dump());
        CHECK(testing::read_all(stdfs::path(dir) / kIdsFile).find("translatable=\"false\"></string>") != std::string::npos);
        CHECK(joined(off.result["done"]).find("turned Play Games off") != std::string::npos);
    }

    SUBCASE("a project id that is not a number is refused before anything is written") {
        auto bad = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false, "playGamesId": "CgkI12345"})"));
        REQUIRE_FALSE(bad.ok);
        CHECK(bad.error["message"].get<std::string>().find("CgkI12345") != std::string::npos);
        CHECK(bad.error["hint"].get<std::string>().find("Setup and management > Configuration") != std::string::npos);
        CHECK(bad.error["hint"].get<std::string>().find("achievement id") != std::string::npos);
        CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/googleplay"));
        auto list = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "playGamesId": ["1"]})"));
        REQUIRE_FALSE(list.ok);
    }
}

TEST_CASE("platform.add_backend googleplay: a computer without the Android NDK says what to install and writes nothing") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    AndroidToolchainSearch search = nothing_found();
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir, &search);
    auto call = [&] { return reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay"})")); };
    auto expect_install_help = [](const CommandResult& r) {
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "unavailable");
        const std::string hint = r.error["hint"].get<std::string>();
        CHECK(hint.find("sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\"") != std::string::npos);
        CHECK(hint.find("factoria setup android") != std::string::npos);
        CHECK(hint.find("googleplayBuild") != std::string::npos);  // the way out
        CHECK(hint.find("android.toolchain.cmake") != std::string::npos);
    };

    // No Android SDK at all.
    auto none = call();
    expect_install_help(none);
    CHECK(none.error["message"].get<std::string>().find("no Android SDK") != std::string::npos);
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/googleplay"));  // nothing half-done
    CHECK_FALSE(load_json_file(dir + "/factoria.json")->contains("plugins"));

    // An SDK without an NDK.
    const std::string sdk = tmp.sub("sdk");
    testing::write_all(stdfs::path(sdk) / "platform-tools" / "adb", "");
    std::map<std::string, std::string> vars = {{"ANDROID_HOME", sdk}};
    search.env = [&](const std::string& name) {
        auto it = vars.find(name);
        return it == vars.end() ? std::string() : it->second;
    };
    auto noNdk = call();
    expect_install_help(noNdk);
    CHECK(noNdk.error["message"].get<std::string>().find("has no NDK") != std::string::npos);
    CHECK(noNdk.error["message"].get<std::string>().find(stdfs::path(sdk).generic_string()) != std::string::npos);

    // An NDK folder that is not an NDK (no toolchain file) does not count; a real one does, and then CMake and Ninja are missing.
    testing::write_all(stdfs::path(sdk) / "ndk" / "27.2.12479018" / "source.properties", "");
    CHECK(call().error["message"].get<std::string>().find("has no NDK") != std::string::npos);
    testing::write_all(stdfs::path(sdk) / "ndk" / "27.2.12479018" / "build" / "cmake" / "android.toolchain.cmake", "");
    auto noCmake = call();
    expect_install_help(noCmake);
    CHECK(noCmake.error["message"].get<std::string>().find("no CMake with Ninja") != std::string::npos);
    testing::write_all(stdfs::path(sdk) / "cmake" / "3.31.6" / "bin" / "cmake", "");  // CMake alone is not enough
    CHECK(call().error["message"].get<std::string>().find("no CMake with Ninja") != std::string::npos);
    CHECK_FALSE(stdfs::exists(stdfs::path(dir) / "plugins/googleplay"));

    // googleplayBuild false needs none of it.
    auto written = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "googleplayBuild": false})"));
    CHECK_MESSAGE(written.ok, written.error.dump());
}

#if !defined(_WIN32)
// The whole build, with an SDK made of scripts: it checks which NDK, CMake and Ninja are used, the arguments of each ABI's configure
// and build, the library each ABI must leave, and the notes about the versions that were used instead of the pinned ones.
TEST_CASE("platform.add_backend googleplay: builds the bridge for each ABI with the SDK's newest NDK and CMake when the pinned ones are missing") {
    testing::TempDir tmp;
    const std::string dir = make_game(tmp);
    auto project = load_json_file(dir + "/factoria.json");
    REQUIRE(project.ok());
    (*project)["export"] = Json::parse(R"({"android": {"minSdk": 28}})");
    REQUIRE(save_json_file(dir + "/factoria.json", *project).ok());

    const stdfs::path sdk = tmp.sub("sdk");
    const stdfs::path log = tmp.sub("cmake-calls.txt");
    testing::write_all(sdk / "platform-tools" / "adb", "");
    for (const char* v : {"26.1.10909125", "28.0.12433566", "27.0.12077973"})
        testing::write_all(sdk / "ndk" / v / "build" / "cmake" / "android.toolchain.cmake", "");
    testing::write_all(sdk / "cmake" / "3.22.1" / "bin" / "ninja", "");
    testing::write_all(sdk / "cmake" / "3.30.5" / "bin" / "ninja", "");
    const stdfs::path cmake = sdk / "cmake" / "3.30.5" / "bin" / "cmake";
    testing::write_all(cmake, "#!/bin/sh\necho \"$*\" >> '" + log.string() + R"('
if [ "$1" = "--build" ]; then
  abi="${2##*/build-}"
  folder="${2%/build-*}"
  mkdir -p "$folder/android/src/main/jniLibs/$abi"
  : > "$folder/android/src/main/jniLibs/$abi/libgoogleplay.so"
fi
)");
    stdfs::permissions(cmake, stdfs::perms::owner_exec | stdfs::perms::owner_read | stdfs::perms::owner_write, stdfs::perm_options::add);

    AndroidToolchainSearch search = nothing_found();
    search.env = [&](const std::string& name) { return name == "ANDROID_HOME" ? sdk.string() : std::string(); };
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    register_platform_setup_commands(reg, dir, &search);
    auto r = reg.call("platform.add_backend", Json::parse(R"({"backend": "googleplay", "playGamesId": "42"})"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());

    REQUIRE(r.result["libraries"].size() == 2);
    CHECK(r.result["libraries"][0] == "android/src/main/jniLibs/arm64-v8a/libgoogleplay.so");
    CHECK(r.result["libraries"][1] == "android/src/main/jniLibs/x86_64/libgoogleplay.so");
    const std::string done = joined(r.result["done"]);
    CHECK(done.find("used NDK 28.0.12433566 because the pinned 27.2.12479018 is not installed") != std::string::npos);
    CHECK(done.find("used CMake 3.30.5 because the pinned 3.31.6 is not installed") != std::string::npos);

    const std::string calls = testing::read_all(log);
    const std::string folder = r.result["folder"].get<std::string>();
    for (const char* abi : {"arm64-v8a", "x86_64"}) {
        CAPTURE(abi);
        CHECK(calls.find("-S " + folder + " -B " + folder + "/build-" + abi + " -G Ninja") != std::string::npos);
        CHECK(calls.find("-DANDROID_ABI=" + std::string(abi)) != std::string::npos);
        CHECK(calls.find("--build " + folder + "/build-" + abi) != std::string::npos);
    }
    CHECK(calls.find("-DCMAKE_MAKE_PROGRAM=" + sdk.generic_string() + "/cmake/3.30.5/bin/ninja") != std::string::npos);
    CHECK(calls.find("-DCMAKE_TOOLCHAIN_FILE=" + sdk.generic_string() + "/ndk/28.0.12433566/build/cmake/android.toolchain.cmake") != std::string::npos);
    CHECK(calls.find("-DANDROID_PLATFORM=android-28") != std::string::npos);  // the project's minSdk
    CHECK(calls.find("-DCMAKE_BUILD_TYPE=Release") != std::string::npos);
    CHECK(testing::read_all(stdfs::path(dir) / kIdsFile).find(">42</string>") != std::string::npos);
}
#endif
