// platform.add_backend {"backend": "steam"} (tools/common/src/platform_setup_steam.cpp): the plugin from its template, a real
// CMake build of it, Valve's libraries copied from an SDK folder or .zip, steam_appid.txt, and the teaching errors for what is
// missing. The Steam plugin itself runs against a mock Steamworks library in platforms/plugins/steam/tests.
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/runtime/plugins.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"
#include "fa/tooling/tooling.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

bool mentions(const Json& list, const std::string& part) {
    for (const Json& s : list)
        if (has(s.get<std::string>(), part)) return true;
    return false;
}

struct Game {
    testing::TempDir tmp;
    std::string dir = tmp.sub("game");
    CommandRegistry reg;
    Game() {
        REQUIRE(create_project(dir, "2d-empty").ok());
        register_plugin_commands(reg, dir);
        register_platform_setup_commands(reg, dir);
    }
    CommandResult add(const Json& args) { return reg.call("platform.add_backend", args); }
    std::string message(const CommandResult& r) const { return r.error.value("message", std::string()) + " | " + r.error.value("hint", std::string()); }
};

// The SDK folder as Valve ships it (steamworks_sdk_*.zip unpacks to sdk/): only the files the setup reads.
void make_sdk(const stdfs::path& root, const std::vector<std::string>& libraries) {
    for (const std::string& lib : libraries) testing::write_all(root / "sdk/redistributable_bin" / lib, "library:" + lib);
    testing::write_all(root / "sdk/public/steam/steam_api.h", "// header");
}

const std::vector<std::string> kAllLibraries = {"win64/steam_api64.dll", "osx/libsteam_api.dylib", "linux64/libsteam_api.so"};

// A .zip with the entries stored (no compression): the setup unpacks it with the system's tar/unzip.
void write_stored_zip(const stdfs::path& file, const std::vector<std::pair<std::string, std::string>>& entries) {
    auto crc32 = [](const std::string& data) {
        std::uint32_t crc = 0xFFFFFFFFu;
        for (unsigned char c : data) {
            crc ^= c;
            for (int k = 0; k < 8; ++k) crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
        }
        return ~crc;
    };
    std::string out, central;
    auto u16 = [](std::string& s, std::uint32_t v) { s += static_cast<char>(v & 0xFF); s += static_cast<char>((v >> 8) & 0xFF); };
    auto u32 = [&](std::string& s, std::uint32_t v) { u16(s, v & 0xFFFF); u16(s, v >> 16); };
    for (const auto& e : entries) {
        const std::uint32_t offset = static_cast<std::uint32_t>(out.size()), crc = crc32(e.second), size = static_cast<std::uint32_t>(e.second.size());
        u32(out, 0x04034b50); u16(out, 20); u16(out, 0); u16(out, 0); u16(out, 0); u16(out, 33);
        u32(out, crc); u32(out, size); u32(out, size); u16(out, static_cast<std::uint32_t>(e.first.size())); u16(out, 0);
        out += e.first + e.second;
        u32(central, 0x02014b50); u16(central, 20); u16(central, 20); u16(central, 0); u16(central, 0); u16(central, 0); u16(central, 33);
        u32(central, crc); u32(central, size); u32(central, size); u16(central, static_cast<std::uint32_t>(e.first.size()));
        u16(central, 0); u16(central, 0); u16(central, 0); u16(central, 0); u32(central, 0); u32(central, offset);
        central += e.first;
    }
    const std::uint32_t centralOffset = static_cast<std::uint32_t>(out.size());
    out += central;
    u32(out, 0x06054b50); u16(out, 0); u16(out, 0); u16(out, static_cast<std::uint32_t>(entries.size()));
    u16(out, static_cast<std::uint32_t>(entries.size())); u32(out, static_cast<std::uint32_t>(central.size())); u32(out, centralOffset); u16(out, 0);
    testing::write_all(file, out);
}

}  // namespace

TEST_CASE("steam setup: the plugin is created, built, given Valve's libraries from a zip and an app id") {
    if (find_cmake().empty()) {
        MESSAGE("no CMake 3.24+ on this computer: the build of the Steam plugin is not tested");
        return;
    }
    Game g;
    const stdfs::path root = g.tmp.path;
    std::vector<std::pair<std::string, std::string>> entries;
    for (const std::string& lib : kAllLibraries) entries.emplace_back("sdk/redistributable_bin/" + lib, "library:" + lib);
    entries.emplace_back("sdk/public/steam/steam_api.h", "// header");
    write_stored_zip(root / "steamworks_sdk_162.zip", entries);

    CommandResult r = g.add(Json{{"backend", "steam"}, {"sdk", (root / "steamworks_sdk_162.zip").string()}});
    if (!r.ok && has(g.message(r), "'unzip' program is missing")) {
        MESSAGE("no unzip on this computer: the SDK .zip is not tested");
        return;
    }
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const stdfs::path folder = stdfs::path(g.dir) / "plugins" / "steam";
    CHECK(stdfs::path(r.result["folder"].get<std::string>()) == folder);
    CHECK(r.result["appId"] == 480);

    // The plugin: declared for the three desktop platforms, from the template without its tests.
    auto project = load_json_file(g.dir + "/factoria.json");
    REQUIRE(project.ok());
    const Json& platforms = (*project)["plugins"]["steam"]["platforms"];
    REQUIRE(platforms.is_array());
    CHECK(platforms.size() == 3);
    CHECK(stdfs::exists(folder / "src/plugin.cpp"));
    CHECK(stdfs::exists(folder / "include/fa_plugin.h"));
    CHECK_FALSE(stdfs::exists(folder / "tests"));
    CHECK(testing::read_all(folder / "CMakeLists.txt").find("project(steam CXX)") != std::string::npos);

    // Built for this computer, into the folder the engine looks in.
    const std::string host = runtime_platform();
    const std::string pluginFile = host == "windows" ? "windows/steam.dll" : host == "macos" ? "macos/libsteam.dylib" : "linux/libsteam.so";
    CHECK_MESSAGE(stdfs::exists(folder / pluginFile), pluginFile);

    // Valve's libraries from the zip, for every platform, next to where the plugin goes.
    CHECK(testing::read_all(folder / "windows/steam_api64.dll") == "library:win64/steam_api64.dll");
    CHECK(testing::read_all(folder / "macos/libsteam_api.dylib") == "library:osx/libsteam_api.dylib");
    CHECK(testing::read_all(folder / "linux/libsteam_api.so") == "library:linux64/libsteam_api.so");

    // steam_appid.txt: Valve's test app, in the project.
    CHECK(testing::read_all(stdfs::path(g.dir) / "steam_appid.txt") == "480\n");

    const Json& done = r.result["done"];
    CHECK(mentions(done, "created the plugin 'steam' from its template"));
    CHECK(mentions(done, "built the steam plugin"));
    CHECK(mentions(done, "copied Valve's redistributable libraries"));
    CHECK(mentions(done, "wrote steam_appid.txt with app id 480"));
    const Json& next = r.result["nextSteps"];
    CHECK(mentions(next, "ACH_WIN_ONE_GAME"));
    CHECK(mentions(next, "NumWins"));
    CHECK(mentions(next, "ids.steam"));
    CHECK(mentions(next, "never copies steam_appid.txt"));
    CHECK_FALSE(mentions(next, "Copy Valve's library for this computer"));  // it is there

    // Again: what is there is kept, a new app id is written, the SDK may be the unpacked folder.
    make_sdk(root / "unpacked", kAllLibraries);
    CommandResult again = g.add(Json{{"backend", "steam"}, {"sdk", (root / "unpacked").string()}, {"appId", 1234}});
    REQUIRE_MESSAGE(again.ok, again.error.dump());
    CHECK(mentions(again.result["done"], "kept the plugin 'steam' factoria.json already declares"));
    CHECK(mentions(again.result["done"], "wrote steam_appid.txt with app id 1234"));
    CHECK(testing::read_all(stdfs::path(g.dir) / "steam_appid.txt") == "1234\n");
    CHECK(mentions(again.result["nextSteps"], "app 1234"));
    CHECK_FALSE(mentions(again.result["nextSteps"], "ACH_WIN_ONE_GAME"));  // not the test app any more

    // Without "appId" the file is kept; without "sdk" the libraries are kept.
    CommandResult third = g.add(Json{{"backend", "steam"}});
    REQUIRE_MESSAGE(third.ok, third.error.dump());
    CHECK(mentions(third.result["done"], "kept steam_appid.txt (app id 1234)"));
    CHECK(testing::read_all(stdfs::path(g.dir) / "steam_appid.txt") == "1234\n");
    CHECK(stdfs::exists(folder / "macos/libsteam_api.dylib"));
    CHECK_FALSE(mentions(third.result["nextSteps"], "Copy Valve's library for this computer"));
}

TEST_CASE("steam setup: without an SDK the libraries are a next step, and nothing else is missing") {
    if (find_cmake().empty()) {
        MESSAGE("no CMake 3.24+ on this computer: the build of the Steam plugin is not tested");
        return;
    }
    Game g;
    CommandResult r = g.add(Json{{"backend", "steam"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(testing::read_all(stdfs::path(g.dir) / "steam_appid.txt") == "480\n");
    const Json& next = r.result["nextSteps"];
    CHECK(mentions(next, "Copy Valve's library for this computer next to the plugin"));
    CHECK(mentions(next, "partner.steamgames.com/downloads/list"));
    CHECK(mentions(next, "\"sdk\""));
    CHECK_FALSE(mentions(r.result["done"], "copied Valve's"));
}

TEST_CASE("steam setup: every missing piece is a teaching error, and nothing is written before them") {
    Game g;
    auto untouched = [&] {
        auto project = load_json_file(g.dir + "/factoria.json");
        REQUIRE(project.ok());
        CHECK_FALSE(project->contains("plugins"));
        CHECK_FALSE(stdfs::exists(stdfs::path(g.dir) / "plugins"));
        CHECK_FALSE(stdfs::exists(stdfs::path(g.dir) / "steam_appid.txt"));
    };

    // The SDK path does not exist.
    CommandResult missing = g.add(Json{{"backend", "steam"}, {"sdk", g.tmp.sub("nowhere")}});
    REQUIRE_FALSE(missing.ok);
    CHECK(missing.error["code"] == "not_found");
    CHECK(has(g.message(missing), "does not exist"));
    CHECK(has(g.message(missing), "partner.steamgames.com/downloads/list"));
    untouched();

    // A folder that is not the SDK.
    testing::write_all(stdfs::path(g.tmp.sub("empty")) / "readme.txt", "x");
    CommandResult notSdk = g.add(Json{{"backend", "steam"}, {"sdk", g.tmp.sub("empty")}});
    REQUIRE_FALSE(notSdk.ok);
    CHECK(notSdk.error["code"] == "invalid_argument");
    CHECK(has(g.message(notSdk), "is not a Steamworks SDK: it has no redistributable_bin/ folder"));
    untouched();

    // A file that is not a zip.
    testing::write_all(g.tmp.sub("sdk.tar"), "x");
    CommandResult notZip = g.add(Json{{"backend", "steam"}, {"sdk", g.tmp.sub("sdk.tar")}});
    REQUIRE_FALSE(notZip.ok);
    CHECK(has(g.message(notZip), "is a file, but not a .zip"));
    untouched();

    // An SDK without the library of this computer (the folder has the other two).
    const std::string host = runtime_platform();
    std::vector<std::string> others;
    for (const std::string& lib : kAllLibraries) {
        const bool isHost = (host == "windows" && lib.find("win64") == 0) || (host == "macos" && lib.find("osx") == 0) ||
                            (host == "linux" && lib.find("linux64") == 0);
        if (!isHost) others.push_back(lib);
    }
    make_sdk(g.tmp.path / "partial", others);
    CommandResult partial = g.add(Json{{"backend", "steam"}, {"sdk", (g.tmp.path / "partial").string()}});
    REQUIRE_FALSE(partial.ok);
    CHECK(partial.error["code"] == "not_found");
    CHECK(has(g.message(partial), "the library this computer (" + host + ") needs"));
    CHECK(has(g.message(partial), "Steamworks SDK 1.58 to 1.64"));
    untouched();

    // A zip that is not a Steamworks SDK unpacks, and is refused for what it lacks.
    write_stored_zip(g.tmp.path / "other.zip", {{"readme.txt", "hello"}});
    CommandResult otherZip = g.add(Json{{"backend", "steam"}, {"sdk", (g.tmp.path / "other.zip").string()}});
    if (!otherZip.ok && has(g.message(otherZip), "'unzip' program is missing")) {
        MESSAGE("no unzip on this computer: the SDK .zip is not tested");
    } else {
        REQUIRE_FALSE(otherZip.ok);
        CHECK(has(g.message(otherZip), "is not a Steamworks SDK"));
    }
    untouched();

    // An app id that is not a number of Steam's.
    CommandResult badId = g.add(Json{{"backend", "steam"}, {"appId", 0}});
    REQUIRE_FALSE(badId.ok);
    CHECK(has(g.message(badId), "appId"));
    untouched();
}

TEST_CASE("steam setup: project.new_plugin with the steam template skips the template's tests") {
    testing::TempDir tmp;
    const std::string dir = tmp.sub("game");
    REQUIRE(create_project(dir, "2d-empty").ok());
    CommandRegistry reg;
    register_plugin_commands(reg, dir);
    CommandResult r = reg.call("project.new_plugin", Json{{"name", "store"}, {"template", "steam"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    std::vector<std::string> files;
    for (const Json& f : r.result["files"]) files.push_back(f.get<std::string>());
    auto listed = [&](const std::string& f) { return std::find(files.begin(), files.end(), f) != files.end(); };
    for (const char* expected : {"CMakeLists.txt", "README.md", "src/plugin.cpp", "src/backend.cpp", "src/steam_loader.cpp", "include/fa_plugin.h"})
        CHECK_MESSAGE(listed(expected), expected);
    for (const std::string& f : files) CHECK_MESSAGE(f.rfind("tests/", 0) != 0, f);
    const stdfs::path folder = stdfs::path(dir) / "plugins/store";
    CHECK_FALSE(stdfs::exists(folder / "tests"));
    const std::string readme = testing::read_all(folder / "README.md");
    CHECK(readme.find("{{NAME}}") == std::string::npos);
    CHECK(readme.find("libstore.dylib") != std::string::npos);  // the name was filled in
    const std::string cmake = testing::read_all(folder / "CMakeLists.txt");
    CHECK(cmake.find("FA_PLUGIN_NAME=store") != std::string::npos);
    // The next steps of a backend plugin are not the example plugin's.
    bool backendStep = false, exampleStep = false;
    for (const Json& s : r.result["nextSteps"]) {
        backendStep = backendStep || has(s.get<std::string>(), "platform.add_backend");
        exampleStep = exampleStep || has(s.get<std::string>(), "plugins.store.add");
    }
    CHECK(backendStep);
    CHECK_FALSE(exampleStep);
    // The listing of templates names it.
    CommandResult bad = reg.call("project.new_plugin", Json{{"name", "other"}, {"template", "stam"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(has(bad.error["hint"].get<std::string>(), "steam"));
}

TEST_CASE("steam setup: an export never ships steam_appid.txt") {
    testing::TempDir tmp;
    const std::string proj = tmp.sub("proj");
    REQUIRE(create_project(proj, "2d-platformer").ok());
    testing::write_all(stdfs::path(proj) / "steam_appid.txt", "480\n");
    testing::write_all(stdfs::path(proj) / "notes.txt", "kept");
    testing::write_all(stdfs::path(proj) / "data/steam_appid.txt", "480\n");  // only the project's own file is the development one
    const std::string player = tmp.sub("fake_player/factoria_player");
    testing::write_all(player, "#!/bin/sh\nexit 0\n");
    ExportOptions o;
    o.projectDir = proj;
    o.platform = "linux";
    o.outDir = tmp.sub("out");
    o.playerBinary = player;
    auto r = export_project(o);
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
    const stdfs::path game = stdfs::path(tmp.sub("out/proj-linux/game"));
    CHECK_FALSE(stdfs::exists(game / "steam_appid.txt"));
    CHECK(stdfs::exists(game / "notes.txt"));
    CHECK(stdfs::exists(game / "data/steam_appid.txt"));
}
