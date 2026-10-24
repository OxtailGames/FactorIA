// The Steam backend plugin, for real: the plugin library built from platforms/plugins/steam/src runs in an Engine with
// platformBackend = "steam", and talks to a mock of the Steamworks redistributable (mock_steam_api.cpp) that sits next to it
// under the real file name. The game's scripts call platform.* and the mock records what reached "Steam".
//
// A plugin is loaded once per process, and a failed start is remembered, so the scenarios that need a different Steam run in
// their own process (CMakeLists.txt registers one ctest entry per test-case prefix): "steam services" (Steam running,
// current SDK), "steam legacy" (an SDK 1.58 to 1.60 library), "steam next" (interface versions one above the newest the
// plugin was checked against: the services again on that library, FA_STEAM_TEST_VARIANT=next), "steam future" (interface
// versions far above them), "steam without library", "steam not running", "steam without app id", "steam exit".
#include <doctest.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <memory>
#include <string>
#include <vector>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/runtime/engine.h"
#include "fa/runtime/plugins.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

// ---------------------------------------------------------------------------------------------------- the files --
#if defined(_WIN32)
const char* const kPlatformDir = "windows";
const char* const kPluginFile = "steam.dll";
const char* const kLibraryFile = "steam_api64.dll";
#elif defined(__APPLE__)
const char* const kPlatformDir = "macos";
const char* const kPluginFile = "libsteam.dylib";
const char* const kLibraryFile = "libsteam_api.dylib";
#else
const char* const kPlatformDir = "linux";
const char* const kPluginFile = "libsteam.so";
const char* const kLibraryFile = "libsteam_api.so";
#endif

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// fa::Json keeps the order of an object's keys and compares objects in that order; the tests do not care about the order.
Json canon(const Json& v) {
    if (v.is_object()) {
        std::vector<std::string> keys;
        for (auto it = v.begin(); it != v.end(); ++it) keys.push_back(it.key());
        std::sort(keys.begin(), keys.end());
        Json out = Json::object();
        for (const std::string& k : keys) out[k] = canon(v.at(k));
        return out;
    }
    if (v.is_array()) {
        Json out = Json::array();
        for (const Json& e : v) out.push_back(canon(e));
        return out;
    }
    return v;
}

std::string logs_since(std::uint64_t seq) {
    std::string out;
    for (const LogEntry& e : recent_logs(2000, LogLevel::Trace, seq)) out += e.category + ": " + e.message + "\n";
    return out;
}

void clear_environment(const char* name) {
#if defined(_WIN32)
    SetEnvironmentVariableA(name, nullptr);
    _putenv_s(name, "");
#else
    unsetenv(name);
#endif
}

[[maybe_unused]] void set_environment(const char* name, const std::string& value) {
#if defined(_WIN32)
    _putenv_s(name, value.c_str());
#else
    setenv(name, value.c_str(), 1);
#endif
}

// ----------------------------------------------------------------------------------------------------- the mock --
// The mock library as the test uses it: loaded by this program too, from the same file the plugin loads, so both see one
// module and one state. MockSteam_Control is its only door (commands: mock_steam_api.cpp).
class Mock {
public:
    explicit Mock(const stdfs::path& file) {
#if defined(_WIN32)
        HMODULE h = LoadLibraryExW(file.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH);
        control_ = h ? reinterpret_cast<Control>(reinterpret_cast<void*>(GetProcAddress(h, "MockSteam_Control"))) : nullptr;
#else
        void* h = dlopen(file.c_str(), RTLD_NOW | RTLD_LOCAL);  // never closed: the plugin keeps using it until the process ends
        control_ = h ? reinterpret_cast<Control>(dlsym(h, "MockSteam_Control")) : nullptr;
#endif
        REQUIRE_MESSAGE(control_ != nullptr, "cannot load the mock Steamworks library " << file.generic_string());
    }

    Json call(const Json& command) {
        const std::string text = command.dump();
        Json answer = Json::parse(control_(text.c_str()));
        INFO("mock " << text << " -> " << answer.dump());
        REQUIRE_FALSE(answer.contains("error"));
        return answer;
    }
    Json state() { return call(Json{{"op", "state"}}); }
    void reset() { call(Json{{"op", "reset"}}); }
    void set(Json options) {
        options["op"] = "set";
        call(options);
    }
    void fire(const std::string& what, Json extra = Json::object()) {
        extra["op"] = "fire";
        extra["what"] = what;
        call(extra);
    }
    // Every call into the mock that is worth knowing about, in order ("StoreStats", "SetAchievement ACH_WIN_ONE_GAME"...).
    std::vector<std::string> calls() {
        std::vector<std::string> out;
        const Json now = state();  // a named value: the elements of a temporary's member would be gone before the loop
        for (const Json& c : now["calls"]) out.push_back(c.get<std::string>());
        return out;
    }
    int count_calls(const std::string& prefix) {
        int n = 0;
        for (const std::string& c : calls()) n += c.rfind(prefix, 0) == 0 ? 1 : 0;
        return n;
    }
    bool called(const std::string& call) {
        for (const std::string& c : calls())
            if (c == call) return true;
        return false;
    }

private:
    using Control = const char* (*)(const char*);
    Control control_ = nullptr;
};

// -------------------------------------------------------------------------------------------------------- a game --
const char* const kCatalog = R"({
  "achievements": [
    {"id": "first_win", "name": "First win", "ids": {"steam": "ACH_WIN_ONE_GAME"}},
    {"id": "hundred_wins", "name": "100 wins", "ids": {"steam": "ACH_WIN_100_GAMES"}},
    {"id": "ghost", "name": "Ghost", "ids": {"steam": "ACH_NOT_THERE"}}
  ],
  "stats": [
    {"id": "wins", "type": "int", "ids": {"steam": "NumWins"}},
    {"id": "feet", "type": "float", "ids": {"steam": "FeetTraveled"}},
    {"id": "nope", "type": "int", "ids": {"steam": "NoSuchStat"}}
  ],
  "leaderboards": [
    {"id": "feet_board", "name": "Feet", "ids": {"steam": "Feet Traveled"}},
    {"id": "fastest", "name": "Fastest", "order": "ascending", "ids": {"steam": "Fastest"}},
    {"id": "ghost_board", "name": "Ghost board", "ids": {"steam": "No Such Board"}},
    {"id": "daily_run", "name": "Daily run", "order": "ascending", "period": "daily", "ids": {"steam": "Daily Run"}},
    {"id": "weekly_run", "name": "Weekly run", "period": "weekly", "ids": {"steam": "Weekly Run"}}
  ],
  "products": [
    {"id": "soundtrack", "type": "nonConsumable", "title": "Soundtrack", "ids": {"steam": "480001"}},
    {"id": "skins", "type": "nonConsumable", "title": "Skins", "ids": {"steam": "480002"}},
    {"id": "gems", "type": "consumable", "title": "Gems", "ids": {"steam": "480003"}},
    {"id": "pass", "type": "subscription", "title": "Season pass", "ids": {"steam": "480004"}},
    {"id": "missing", "type": "nonConsumable", "title": "Not a DLC", "ids": {"steam": "480999"}},
    {"id": "noid", "type": "nonConsumable", "title": "No Steam id"}
  ],
  "backend": "steam"
})";

enum class Library { Current, Legacy, Next, Future, None };

// A project folder with the plugin and (unless Library::None) the mock next to it, as `platform.add_backend` leaves a game.
struct SteamGame {
    stdfs::path dir;
    std::unique_ptr<Mock> mock;

    SteamGame(Library library, const std::string& appId) {
        dir = stdfs::canonical(fs::make_temp_dir("fa_steam_plugin_test"));  // canonical: the plugin and this program must name one file
        const stdfs::path native = dir / "native" / "steam" / kPlatformDir;
        stdfs::create_directories(native);
        stdfs::create_directories(dir / "scenes");
        std::ofstream(dir / "factoria.json") << R"({"format":"factoria.project/1","name":"SteamTest","plugins":{"steam":{"path":"native/steam"}},"platform":)"
                                             << kCatalog << "}";
        std::ofstream(dir / "scenes/main.scene.json") << R"({"format":"factoria.scene/1","entities":[]})";
        if (!appId.empty()) std::ofstream(dir / "steam_appid.txt") << appId << "\n";
        stdfs::copy_file(FA_STEAM_PLUGIN_FILE, native / kPluginFile, stdfs::copy_options::overwrite_existing);
        if (library != Library::None) {
            const char* source = library == Library::Current  ? FA_STEAM_MOCK_CURRENT
                                 : library == Library::Legacy ? FA_STEAM_MOCK_LEGACY
                                 : library == Library::Next   ? FA_STEAM_MOCK_NEXT
                                                              : FA_STEAM_MOCK_FUTURE;
            stdfs::copy_file(source, native / kLibraryFile, stdfs::copy_options::overwrite_existing);
            mock = std::make_unique<Mock>(native / kLibraryFile);
        }
        // Nothing of the developer's own Steam setup may decide the app id.
        clear_environment("SteamAppId");
        clear_environment("SteamGameId");
    }
    ~SteamGame() {
        std::error_code ec;
        stdfs::remove_all(dir, ec);  // best effort: Windows keeps the loaded DLLs
    }
    EngineConfig config(const std::string& backend = "steam", const std::string& fallback = "fake") const {
        EngineConfig c;
        c.projectDir = dir.generic_string();
        c.headless = true;
        c.graphics = false;
        c.hotReload = false;
        c.platformBackend = backend;
        c.platformFallback = fallback;
        return c;
    }
};

// ------------------------------------------------------------------------------------------------------ scripts --
Json run(Engine& engine, const std::string& code) {
    auto r = engine.scripts().eval(code);
    INFO(code << " -> " << (r.ok() ? r.value().dump() : r.error().message));
    REQUIRE(r.ok());
    return r.value();
}

void pump(Engine& engine, int frames = 2) { engine.step(frames); }

// The date game.today() answers (what a daily or weekly leaderboard is addressed by); game.setDate is for tests of the script runner.
void set_date(Engine& engine, const std::string& iso) { CHECK(engine.scripts().set_date(iso).empty()); }

// Starts `expression` (a promise from the platform API), steps frames until it settles, and returns {ok, value} or
// {ok: false, code, message, hint}.
Json settle(Engine& engine, const std::string& expression, int frames = 10) {
    static int counter = 0;
    const std::string slot = "s" + std::to_string(++counter);
    run(engine, "globalThis.__settled = globalThis.__settled || {}; __settled." + slot + " = null; (" + expression +
                    ").then((v) => { __settled." + slot + " = { ok: true, value: v === undefined ? null : v }; }, "
                    "(e) => { __settled." + slot + " = { ok: false, code: e.code, message: String(e.message), hint: e.hint || '' }; }); 0");
    for (int i = 0; i <= frames; ++i) {
        Json done = run(engine, "__settled." + slot);
        if (!done.is_null()) return done;
        engine.step(1);
    }
    FAIL("the promise of " << expression << " did not settle in " << frames << " frames");
    return Json();
}

std::string text(const Json& v, const char* key) { return v.value(key, std::string()); }

// An engine on a game, with the log position at its start.
struct Session {
    Engine engine;
    std::uint64_t seq = log_last_seq();

    Session(const SteamGame& game, const std::string& backend = "steam", const std::string& fallback = "fake") {
        std::string err;
        REQUIRE_MESSAGE(engine.init(game.config(backend, fallback), nullptr, &err), err);
    }
    ~Session() { engine.shutdown(); }
    std::string logs() const { return logs_since(seq); }
};

// What every test of a running Steam checks at its end: the mock saw no misuse of the Steamworks API, every request was
// answered (once), and the plugin logged no error.
void expect_clean(Session& s, Mock& mock) {
    Json state = mock.state();
    CHECK_MESSAGE(state["violations"].empty(), state["violations"].dump());
    CHECK(s.engine.platform_services()->pending() == 0);
    const std::string logs = s.logs();
    CHECK_FALSE(has(logs, "not waiting for an answer"));  // the engine's warning for an answer to a request that is not waiting
}

// Whether this process runs the services on the "next" library (the ctest entry steam_plugin_next sets the variable).
bool next_variant() {
    const char* variant = std::getenv("FA_STEAM_TEST_VARIANT");
    return variant && std::string(variant) == "next";
}

// One game for every test of the "steam services" process: the plugin loads once.
SteamGame& services_game() {
    static SteamGame game(next_variant() ? Library::Next : Library::Current, "480");
    return game;
}

}  // namespace

// ============================================================================================== steam next ======
// A library of a later SDK (SDK 1.65 bumped ISteamUtils to v011): every interface is one version above the newest the
// plugin knows. The accessors are found by probing upwards, the flat functions the plugin calls are the same, so it works,
// and says once that it is running on interface versions it was not checked against. (Run with the services, in
// steam_plugin_next, whose library is this one: the plugin loads once per process, so all its logs are in logs_since(0).)
TEST_CASE("steam next: interfaces newer than the checked SDKs are used, with one warning") {
    if (!next_variant()) return;  // `steam_plugin_services` has the current library; this test belongs to steam_plugin_next
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);
    CHECK(run(s.engine, "platform.backend") == "steam");

    const std::string logs = logs_since(0);
    CHECK(has(logs, "are newer than the SDKs this plugin was checked against (1.58 to 1.64); they are used, since every function the "
                    "plugin calls is present"));
    CHECK(has(logs, "ISteamUtils v011"));
    CHECK(has(logs, "ISteamUser v024"));
    CHECK(has(logs, "ISteamRemoteStorage v017"));
    std::size_t warnings = 0;
    for (std::size_t at = logs.find("newer than the SDKs this plugin was checked against"); at != std::string::npos;
         at = logs.find("newer than the SDKs this plugin was checked against", at + 1))
        ++warnings;
    CHECK_MESSAGE(warnings == 1, "the warning must be logged once, not per interface or per engine: " << logs);
    CHECK(has(logs, "Steam is ready: app 480"));

    CommandResult status = s.engine.commands().call("steam.status");
    REQUIRE(status.ok);
    CHECK(status.result["checkedSdk"] == "Steamworks SDK 1.58 to 1.64");
    std::vector<std::string> newer;
    for (const Json& n : status.result["newerInterfaces"]) newer.push_back(n.get<std::string>());
    std::sort(newer.begin(), newer.end());
    CHECK(newer == std::vector<std::string>{"ISteamApps v010", "ISteamFriends v019", "ISteamRemoteStorage v017", "ISteamUser v024",
                                            "ISteamUserStats v014", "ISteamUtils v011"});
    CHECK(has(status.result["interfaces"].get<std::string>(), "ISteamUtils v011"));
    CHECK(status.result["statsLoaded"] == true);

    // And it works: the mock hands every method the interface pointer it expects, whatever the version name.
    Json who = settle(s.engine, "platform.signIn()");
    CHECK(who["ok"] == true);
    CHECK(settle(s.engine, "platform.achievements.unlock('first_win')")["ok"] == true);
    expect_clean(s, mock);
}

// ============================================================================================ steam services ======
TEST_CASE("steam services: the backend registers, signs the player in and reports its status") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);
    CHECK(run(s.engine, "platform.backend") == "steam");
    for (const char* service : {"achievements", "stats", "leaderboards", "cloudSave", "purchases", "overlay", "presence"})
        CHECK_MESSAGE(run(s.engine, std::string("platform.has('") + service + "')") == true, service);

    Json who = settle(s.engine, "platform.signIn()");
    REQUIRE(who["ok"] == true);
    CHECK(canon(who["value"]) == canon(Json::parse(R"({"id":"76561198000000001","name":"Tester","signedIn":true})")));
    CHECK(run(s.engine, "platform.player.name") == "Tester");
    mock.set(Json{{"loggedOn", false}});
    CHECK(settle(s.engine, "platform.signIn()")["value"]["signedIn"] == false);
    mock.set(Json{{"loggedOn", true}});

    // The app id came from the steam_appid.txt in the project folder, handed to Steam as the variables Steam itself sets.
    Json state = mock.state();
    CHECK(state["appIdEnv"] == "480");
    CHECK(state["gameIdEnv"] == "480");
    CHECK(state["manual"] == true);  // the plugin switched Steam to manual dispatch: it never calls SteamAPI_RunCallbacks

    CommandResult status = s.engine.commands().call("steam.status");
    REQUIRE(status.ok);
    CHECK(status.result["backend"] == "steam");
    CHECK(status.result["appId"] == 480);
    CHECK(has(status.result["appIdFrom"].get<std::string>(), "steam_appid.txt in "));
    CHECK(has(status.result["library"].get<std::string>(), kLibraryFile));
    CHECK(has(status.result["interfaces"].get<std::string>(), next_variant() ? "ISteamUserStats v014" : "ISteamUserStats v013"));
    CHECK(status.result["newerInterfaces"].size() == (next_variant() ? 6u : 0u));
    CHECK(status.result["player"]["name"] == "Tester");
    CHECK(status.result["overlayEnabled"] == true);
    CHECK(status.result["cloudEnabledForApp"] == true);
    CHECK(status.result["statsLoaded"] == true);
    CHECK(status.result["dlc"] == 2);
    expect_clean(s, mock);
}

TEST_CASE("steam services: achievements unlock, report progress, list and reset") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    Json first = settle(s.engine, "platform.achievements.unlock('first_win')");
    REQUIRE(first["ok"] == true);
    CHECK(canon(first["value"]) == canon(Json::parse(R"({"id":"first_win","unlocked":true,"newly":true})")));
    Json state = mock.state();
    CHECK(state["achievements"]["ACH_WIN_ONE_GAME"] == true);
    CHECK(state["stored"]["achievements"]["ACH_WIN_ONE_GAME"] == true);  // stored, not only set
    CHECK(state["storeCalls"] == 1);

    // Again: Steam has it, so nothing is set or stored a second time, and "newly" says so.
    Json again = settle(s.engine, "platform.achievements.unlock('first_win')");
    CHECK(canon(again["value"]) == canon(Json::parse(R"({"id":"first_win","unlocked":true,"newly":false})")));
    CHECK(mock.state()["storeCalls"] == 1);

    // Progress shows Steam's "n of 100" notice; Steam keeps the progress in a stat, so only the notice is sent.
    Json half = settle(s.engine, "platform.achievements.progress('hundred_wins', 0.5)");
    CHECK(canon(half["value"]) == canon(Json::parse(R"({"id":"hundred_wins","progress":0.5,"unlocked":false})")));
    CHECK(mock.called("IndicateAchievementProgress ACH_WIN_100_GAMES 50 100"));
    CHECK(mock.state()["achievements"]["ACH_WIN_100_GAMES"] == false);
    settle(s.engine, "platform.achievements.progress('hundred_wins', 0)");
    CHECK(mock.count_calls("IndicateAchievementProgress") == 1);  // 0 says nothing
    Json full = settle(s.engine, "platform.achievements.progress('hundred_wins', 1)");
    CHECK(canon(full["value"]) == canon(Json::parse(R"({"id":"hundred_wins","progress":1,"unlocked":true})")));
    CHECK(mock.state()["achievements"]["ACH_WIN_100_GAMES"] == true);

    // The list covers the whole catalog; an achievement Steam does not have shows locked, with a warning that teaches.
    Json list = settle(s.engine, "platform.achievements.list()");
    REQUIRE(list["ok"] == true);
    CHECK(canon(list["value"]) == canon(Json::parse(R"([{"id":"first_win","name":"First win","description":"","unlocked":true,"progress":1},)"
                                                    R"({"id":"hundred_wins","name":"100 wins","description":"","unlocked":true,"progress":1},)"
                                                    R"({"id":"ghost","name":"Ghost","description":"","unlocked":false,"progress":0}])")));
    const std::string logs = s.logs();
    CHECK(has(logs, "Steam has no achievement \"ACH_NOT_THERE\" for app 480"));
    CHECK(has(logs, "Set ids.steam of \"ghost\""));

    // Unlocking one Steam does not know rejects with where to fix it.
    Json ghost = settle(s.engine, "platform.achievements.unlock('ghost')");
    CHECK(ghost["ok"] == false);
    CHECK(ghost["code"] == "unknownId");
    CHECK(has(text(ghost, "message"), "Steam has no achievement \"ACH_NOT_THERE\" for app 480 (the catalog id is \"ghost\")"));
    CHECK(has(text(ghost, "hint"), "Stats & Achievements"));
    CHECK(has(text(ghost, "hint"), "ACH_WIN_ONE_GAME"));

    Json reset = settle(s.engine, "platform.achievements.reset()");
    CHECK(reset["ok"] == true);
    state = mock.state();
    CHECK(state["achievements"]["ACH_WIN_ONE_GAME"] == false);
    CHECK(state["achievements"]["ACH_WIN_100_GAMES"] == false);
    CHECK(mock.called("ResetAllStats true"));
    expect_clean(s, mock);
}

TEST_CASE("steam services: an unlock that Steam cannot store rejects with network") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);
    mock.set(Json{{"loggedOn", false}});  // SetAchievement works, StoreStats does not
    Json r = settle(s.engine, "platform.achievements.unlock('hundred_wins')");
    CHECK(r["ok"] == false);
    CHECK(r["code"] == "network");
    CHECK(has(text(r, "message"), "Steam did not accept the stats"));
    CHECK(has(text(r, "hint"), "retry"));
    expect_clean(s, mock);
}

TEST_CASE("steam services: stats read, write and add, stored once per frame") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    CHECK(settle(s.engine, "platform.stats.get('wins')")["value"] == 0);
    run(s.engine, "globalThis.set = []; platform.stats.set('wins', 7).then((v) => set.push(v)); 0");
    CHECK(mock.state()["intStats"]["NumWins"] == 7);
    CHECK(mock.state()["storeCalls"] == 0);  // stored by the frame, not by every set
    pump(s.engine, 1);
    CHECK(canon(run(s.engine, "set")) == canon(Json::parse("[7]")));
    CHECK(mock.state()["storeCalls"] == 1);
    CHECK(mock.state()["stored"]["intStats"]["NumWins"] == 7);

    // Several sets in one frame cost one StoreStats (Steam limits how often it may be called).
    run(s.engine, "platform.stats.set('wins', 8); platform.stats.set('wins', 9); platform.stats.set('feet', 1.5); 0");
    pump(s.engine, 1);
    CHECK(mock.state()["storeCalls"] == 2);
    CHECK(mock.state()["intStats"]["NumWins"] == 9);

    CHECK(settle(s.engine, "platform.stats.add('wins', 3)")["value"] == 12);
    CHECK(settle(s.engine, "platform.stats.get('feet')")["value"] == 1.5);
    CHECK(settle(s.engine, "platform.stats.set('feet', 0.1)")["value"] == 0.1);  // 0.1, not 0.10000000149
    pump(s.engine, 1);

    // A stat the game's Steam app does not have, and a value an int stat cannot hold.
    Json unknown = settle(s.engine, "platform.stats.get('nope')");
    CHECK(unknown["code"] == "unknownId");
    CHECK(has(text(unknown, "message"), "Steam has no int stat \"NoSuchStat\" for app 480 (the catalog id is \"nope\")"));
    CHECK(has(text(unknown, "hint"), "NumWins"));
    Json big = settle(s.engine, "platform.stats.set('wins', 3000000000)");
    CHECK(big["code"] == "failed");
    CHECK(has(text(big, "message"), "32-bit"));
    expect_clean(s, mock);
}

TEST_CASE("steam services: a daily or weekly leaderboard is one Steam board per period") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    // Day one: the board "Daily Run 2026-10-23" is made with the catalog's order (ascending, numeric) and holds the score.
    set_date(s.engine, "2026-10-23");  // a Friday
    CHECK(settle(s.engine, "platform.leaderboards.submit('daily_run', 61000)")["value"]["best"] == 61000);
    CHECK(mock.called("FindOrCreateLeaderboard Daily Run 2026-10-23 1 1"));
    Json one = settle(s.engine, "platform.leaderboards.entries('daily_run')");
    REQUIRE(one["value"].size() == 1);
    CHECK(one["value"][0]["isPlayer"] == true);
    CHECK(mock.count_calls("FindOrCreateLeaderboard Daily Run 2026-10-23") == 1);  // the handle is kept

    // Day two: another board, empty, and a score worse than yesterday's is this day's best.
    set_date(s.engine, "2026-10-24");
    Json two = settle(s.engine, "platform.leaderboards.entries('daily_run')");
    REQUIRE(two["ok"] == true);
    CHECK(two["value"].size() == 0);
    CHECK(mock.called("FindOrCreateLeaderboard Daily Run 2026-10-24 1 1"));
    CHECK(settle(s.engine, "platform.leaderboards.submit('daily_run', 90000)")["value"]["best"] == 90000);
    CHECK(mock.state()["boards"]["Daily Run 2026-10-23"]["entries"].size() == 1);

    // Back to day one: its board still has its score.
    set_date(s.engine, "2026-10-23");
    CHECK(settle(s.engine, "platform.leaderboards.entries('daily_run')")["value"][0]["score"] == 61000);

    // A weekly board is named after the Monday and keeps its week, Monday to Sunday.
    set_date(s.engine, "2026-10-21");  // a Wednesday
    CHECK(settle(s.engine, "platform.leaderboards.submit('weekly_run', 7)")["value"]["best"] == 7);
    CHECK(mock.called("FindOrCreateLeaderboard Weekly Run 2026-10-19 2 1"));
    set_date(s.engine, "2026-10-25");  // the Sunday of that week
    CHECK(settle(s.engine, "platform.leaderboards.entries('weekly_run')")["value"].size() == 1);
    set_date(s.engine, "2026-10-26");  // the next Monday
    CHECK(settle(s.engine, "platform.leaderboards.entries('weekly_run')")["value"].size() == 0);
    CHECK(mock.called("FindOrCreateLeaderboard Weekly Run 2026-10-26 2 1"));
    CHECK(mock.count_calls("FindOrCreateLeaderboard Weekly Run 2026-10-19") == 1);

    // Weeks of days do not grow the handle cache without bound: every day is one lookup, and the game works on.
    for (int month = 1; month <= 3; ++month)
        for (int day = 1; day <= 28; ++day) {
            char date[16];
            std::snprintf(date, sizeof date, "2027-%02d-%02d", month, day);
            set_date(s.engine, date);
            REQUIRE(settle(s.engine, "platform.leaderboards.entries('daily_run')")["ok"] == true);
        }
    CHECK(mock.count_calls("FindOrCreateLeaderboard Daily Run 2027-") == 84);
    expect_clean(s, mock);
}

TEST_CASE("steam services: leaderboards submit, list and create") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    Json top = settle(s.engine, "platform.leaderboards.entries('feet_board', { range: 'top', count: 2 })");
    REQUIRE(top["ok"] == true);
    REQUIRE(top["value"].size() == 2);
    CHECK(canon(top["value"][0]) == canon(Json::parse(R"({"rank":1,"name":"Alice","score":5000,"playerId":"76561198000000002","isPlayer":false})")));
    CHECK(top["value"][1]["name"] == "Bob");

    // A score between Alice and Bob: the player is second, and best is the score.
    Json sub = settle(s.engine, "platform.leaderboards.submit('feet_board', 4000)");
    REQUIRE(sub["ok"] == true);
    CHECK(canon(sub["value"]) == canon(Json::parse(R"({"id":"feet_board","score":4000,"best":4000})")));
    CHECK(mock.called("UploadLeaderboardScore 4000 method 1"));  // keep best
    Json around = settle(s.engine, "platform.leaderboards.entries('feet_board', { range: 'around', count: 3 })");
    REQUIRE(around["value"].size() == 3);
    CHECK(around["value"][0]["name"] == "Alice");
    CHECK(canon(around["value"][1]) == canon(Json::parse(R"({"rank":2,"name":"Tester","score":4000,"playerId":"76561198000000001","isPlayer":true})")));
    CHECK(around["value"][2]["name"] == "Bob");

    // A worse score changes nothing and best says what Steam kept.
    Json worse = settle(s.engine, "platform.leaderboards.submit('feet_board', 100)");
    CHECK(canon(worse["value"]) == canon(Json::parse(R"({"id":"feet_board","score":100,"best":4000})")));

    // Friends: the player and the two friends, not Carol.
    Json friends = settle(s.engine, "platform.leaderboards.entries('feet_board', { range: 'friends', count: 10 })");
    REQUIRE(friends["value"].size() == 3);
    CHECK(friends["value"][0]["name"] == "Alice");
    CHECK(friends["value"][2]["name"] == "Bob");
    CHECK(mock.state()["findCalls"] == 1);  // the leaderboard handle is looked up once and kept

    // A leaderboard that does not exist yet is created with the catalog's order, once; its first score is its best.
    Json made = settle(s.engine, "platform.leaderboards.submit('fastest', 61000)");
    REQUIRE(made["ok"] == true);
    CHECK(made["value"]["best"] == 61000);
    CHECK(mock.called("FindOrCreateLeaderboard Fastest 1 1"));  // ascending, numeric
    CHECK(mock.state()["boards"]["Fastest"]["sort"] == 1);
    CHECK(settle(s.engine, "platform.leaderboards.submit('fastest', 59000)")["value"]["best"] == 59000);
    CHECK(mock.count_calls("FindOrCreateLeaderboard Fastest") == 1);

    // When Steam cannot create it the error says where to.
    mock.set(Json{{"createBoards", false}});
    Json ghost = settle(s.engine, "platform.leaderboards.submit('ghost_board', 1)");
    CHECK(ghost["code"] == "unknownId");
    CHECK(has(text(ghost, "message"), "Steam has no leaderboard \"No Such Board\" for app 480"));
    CHECK(has(text(ghost, "hint"), "Feet Traveled"));
    mock.set(Json{{"createBoards", true}});

    // A score Steam cannot hold.
    Json huge = settle(s.engine, "platform.leaderboards.submit('feet_board', 5000000000)");
    CHECK(huge["code"] == "failed");
    CHECK(has(text(huge, "message"), "32-bit"));
    expect_clean(s, mock);
}

TEST_CASE("steam services: cloud saves are <key>.json files") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    Json saved = settle(s.engine, "platform.cloud.save('slot1', { level: 3, name: 'Ana' })");
    REQUIRE(saved["ok"] == true);
    CHECK(saved["value"]["key"] == "slot1");
    CHECK(saved["value"]["bytes"] == static_cast<int>(std::string(R"({"level":3,"name":"Ana"})").size()));
    Json files = mock.state()["files"];
    REQUIRE(files.contains("slot1.json"));
    CHECK(canon(Json::parse(files["slot1.json"].get<std::string>())) == canon(Json::parse(R"({"level":3,"name":"Ana"})")));
    CHECK(canon(settle(s.engine, "platform.cloud.load('slot1')")["value"]) == canon(Json::parse(R"({"level":3,"name":"Ana"})")));
    CHECK(settle(s.engine, "platform.cloud.load('nothing')")["value"].is_null());  // no such key: undefined

    mock.set(Json{{"files", Json{{"slot2.json", "{}"}, {"notes.txt", "not ours"}}}});
    CHECK(canon(settle(s.engine, "platform.cloud.list()")["value"]) == canon(Json::parse(R"(["slot1","slot2"])")));  // only <key>.json files
    CHECK(settle(s.engine, "platform.cloud.remove('slot1')")["ok"] == true);
    CHECK(settle(s.engine, "platform.cloud.remove('slot1')")["ok"] == true);  // removing what is not there is fine
    CHECK(canon(settle(s.engine, "platform.cloud.list()")["value"]) == canon(Json::parse(R"(["slot2"])")));

    mock.set(Json{{"failWrites", true}});
    Json full = settle(s.engine, "platform.cloud.save('slot3', 1)");
    CHECK(full["code"] == "failed");
    CHECK(has(text(full, "message"), "Steam Cloud refused to write \"slot3.json\""));
    mock.set(Json{{"failWrites", false}});

    mock.set(Json{{"cloudApp", false}});
    Json noApp = settle(s.engine, "platform.cloud.save('slot3', 1)");
    CHECK(noApp["code"] == "unavailable");
    CHECK(has(text(noApp, "message"), "Steam Cloud is not enabled for app 480"));
    CHECK(has(text(noApp, "hint"), "App Admin"));
    mock.set(Json{{"cloudApp", true}, {"cloudAccount", false}});
    Json noAccount = settle(s.engine, "platform.cloud.load('slot2')");
    CHECK(noAccount["code"] == "unavailable");
    CHECK(has(text(noAccount, "message"), "turned off for this Steam account"));
    expect_clean(s, mock);
}

TEST_CASE("steam services: purchases are DLC") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);
    run(s.engine, "globalThis.events = []; platform.on('purchase', (e) => events.push(e)); 0");

    // products(): Steam's DLC list, by the catalog's ids. A product that is not a DLC of the app is left out.
    Json products = settle(s.engine, "platform.purchases.products()");
    REQUIRE(products["ok"] == true);
    REQUIRE(products["value"].size() == 2);
    CHECK(products["value"][0]["id"] == "soundtrack");
    CHECK(products["value"][0]["title"] == "Spacewar Soundtrack");
    CHECK(products["value"][1]["id"] == "skins");
    CHECK(has(s.logs(), "The product \"gems\" is not a DLC of app 480"));
    CHECK(settle(s.engine, "platform.purchases.products(['skins'])")["value"].size() == 1);

    // Already owned: purchased at once. Not owned: the overlay opens Steam's cart and the answer is "pending".
    Json owned = settle(s.engine, "platform.purchases.buy('skins')");
    CHECK(canon(owned["value"]) == canon(Json::parse(R"({"status":"purchased","productId":"skins","transactionId":"dlc-480002"})")));
    Json pending = settle(s.engine, "platform.purchases.buy('soundtrack')");
    CHECK(canon(pending["value"]) == canon(Json::parse(R"({"status":"pending","productId":"soundtrack"})")));
    CHECK(mock.called("ActivateGameOverlayToStore 480001 2"));  // add to cart and show

    // The player buys it in the overlay: Steam's DlcInstalled becomes a purchase event with the catalog's id.
    mock.fire("dlc", Json{{"appId", 480001}});
    pump(s.engine);
    Json events = run(s.engine, "events");
    REQUIRE(events.size() == 1);
    CHECK(canon(events[0]) == canon(Json::parse(R"({"status":"purchased","productId":"soundtrack","transactionId":"dlc-480001","receipt":""})")));
    CHECK(settle(s.engine, "platform.purchases.finish('dlc-480001')")["ok"] == true);  // nothing to finish on Steam

    Json restored = settle(s.engine, "platform.purchases.restore()");
    REQUIRE(restored["value"].size() == 2);
    CHECK(restored["value"][0]["productId"] == "soundtrack");
    CHECK(canon(restored["value"][1]) == canon(Json::parse(R"({"productId":"skins","transactionId":"dlc-480002"})")));

    // What Steam cannot sell from a game.
    Json gems = settle(s.engine, "platform.purchases.buy('gems')");
    CHECK(gems["code"] == "unavailable");
    CHECK(has(text(gems, "message"), "Steam cannot sell the consumable \"gems\""));
    CHECK(has(text(gems, "hint"), "ISteamMicroTxn"));
    Json pass = settle(s.engine, "platform.purchases.buy('pass')");
    CHECK(pass["code"] == "unavailable");
    CHECK(has(text(pass, "message"), "subscription \"pass\""));
    Json missing = settle(s.engine, "platform.purchases.buy('missing')");
    CHECK(missing["code"] == "unknownId");
    CHECK(has(text(missing, "message"), "Steam lists no DLC 480999 for app 480"));
    CHECK(has(text(missing, "hint"), "App Admin > DLC"));
    Json noid = settle(s.engine, "platform.purchases.buy('noid')");
    CHECK(noid["code"] == "unknownId");
    CHECK(has(text(noid, "message"), "has no DLC app id for Steam"));
    CHECK(has(text(noid, "hint"), "ids.steam"));
    expect_clean(s, mock);
}

TEST_CASE("steam services: overlay, presence and the events Steam sends") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    CHECK(settle(s.engine, "platform.overlay.open('achievements')")["ok"] == true);
    CHECK(mock.called("ActivateGameOverlay Achievements"));
    CHECK(settle(s.engine, "platform.overlay.open('friends')")["ok"] == true);
    CHECK(mock.called("ActivateGameOverlay Friends"));
    CHECK(settle(s.engine, "platform.overlay.open('leaderboards')")["ok"] == true);
    CHECK(mock.called("ActivateGameOverlayToWebPage https://steamcommunity.com/stats/480/leaderboards/ 0"));
    CHECK(settle(s.engine, "platform.overlay.open('store', 'soundtrack')")["ok"] == true);
    CHECK(mock.called("ActivateGameOverlayToStore 480001 0"));
    CHECK(settle(s.engine, "platform.overlay.open('store')")["ok"] == true);
    CHECK(mock.called("ActivateGameOverlayToStore 480 0"));  // the game's own store page
    mock.set(Json{{"overlayEnabled", false}});
    Json off = settle(s.engine, "platform.overlay.open('friends')");
    CHECK(off["code"] == "unavailable");
    CHECK(has(text(off, "message"), "The Steam overlay is not available"));
    CHECK(has(text(off, "hint"), "Enable the Steam Overlay"));
    mock.set(Json{{"overlayEnabled", true}});

    // Presence: set() replaces what friends see, "" clears it.
    CHECK(settle(s.engine, "platform.presence.set('In a match', { score: '5', connect: '+connect 1.2.3.4' })")["ok"] == true);
    CHECK(canon(mock.state()["presence"]) == canon(Json::parse(R"({"status":"In a match","score":"5","connect":"+connect 1.2.3.4"})")));
    CHECK(settle(s.engine, "platform.presence.set('In the menu')")["ok"] == true);
    CHECK(canon(mock.state()["presence"]) == canon(Json::parse(R"({"status":"In the menu"})")));
    Json tooLong = settle(s.engine, "platform.presence.set('x', { note: '" + std::string(300, 'a') + "' })");
    CHECK(tooLong["code"] == "failed");
    CHECK(has(text(tooLong, "message"), "too long for Steam"));
    CHECK(canon(mock.state()["presence"]) == canon(Json::parse(R"({"status":"In the menu"})")));  // nothing changed
    CHECK(settle(s.engine, "platform.presence.set('')")["ok"] == true);
    CHECK(mock.state()["presence"] == Json::object());

    // Events: the overlay opening and closing, and the connection to Steam.
    run(s.engine, "globalThis.events = []; platform.on('overlay', (e) => events.push(['overlay', e.open]));"
                  "platform.on('player', (p) => events.push(['player', p.signedIn, p.name])); 0");
    mock.fire("overlay", Json{{"active", true}});
    mock.fire("overlay", Json{{"active", false}});
    mock.fire("disconnected");
    pump(s.engine);
    CHECK(canon(run(s.engine, "events")) == canon(Json::parse(R"([["overlay",true],["overlay",false],["player",false,"Tester"]])")));
    CHECK(run(s.engine, "platform.player.signedIn") == false);
    mock.fire("connected");
    pump(s.engine);
    CHECK(run(s.engine, "platform.player.signedIn") == true);
    expect_clean(s, mock);
}

TEST_CASE("steam services: failures on the way are answered once, and strays are harmless") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    Session s(game);

    // Steam cannot deliver the answer (the connection to its servers failed).
    mock.set(Json{{"failNext", 1}});
    Json network = settle(s.engine, "platform.leaderboards.entries('feet_board')");
    CHECK(network["code"] == "network");
    CHECK(has(text(network, "message"), "connection to Steam's servers failed"));

    // Steam refuses to start the call at all.
    mock.set(Json{{"refuseNext", 1}});
    Json refused = settle(s.engine, "platform.leaderboards.entries('feet_board')");
    CHECK(refused["code"] == "failed");
    CHECK(has(text(refused, "message"), "Steam refused to start the request"));

    // The result takes a while: the promise waits, then the next frames deliver it.
    mock.set(Json{{"hold", true}});
    run(s.engine, "globalThis.late = []; platform.leaderboards.entries('feet_board', { count: 1 }).then((r) => late.push(r.length)); 0");
    pump(s.engine, 3);
    CHECK(run(s.engine, "late.length") == 0);
    CHECK(s.engine.platform_services()->pending() == 1);
    mock.call(Json{{"op", "release"}});
    pump(s.engine, 4);
    CHECK(canon(run(s.engine, "late")) == canon(Json::parse("[1]")));

    // An answer for a call the plugin never made does nothing, and the callbacks it does not use are skipped.
    mock.fire("stray");
    pump(s.engine);
    CHECK(settle(s.engine, "platform.stats.get('wins')")["ok"] == true);
    expect_clean(s, mock);
}

TEST_CASE("steam services: an answer that arrives after the engine is gone does nothing") {
    SteamGame& game = services_game();
    Mock& mock = *game.mock;
    mock.reset();
    {
        Session gone(game);
        mock.set(Json{{"hold", true}});
        run(gone.engine, "platform.leaderboards.entries('feet_board').catch(() => {}); 0");
    }  // the engine ends with the request unanswered
    mock.call(Json{{"op", "release"}});
    Session s(game);
    pump(s.engine, 4);  // the next engine's frames pump the old call's result: the plugin answers a request nobody waits for
    CHECK(settle(s.engine, "platform.stats.get('wins')")["ok"] == true);
    expect_clean(s, mock);
}

// ================================================================================================ steam legacy =====
// A library of SDK 1.58 to 1.60: no SteamAPI_InitFlat, older interface versions, and stats that arrive after a request.
TEST_CASE("steam legacy: an older library works, and requests wait for the stats") {
    clear_environment("SteamAppId");
    clear_environment("SteamGameId");
    SteamGame game(Library::Legacy, "");
    Mock& mock = *game.mock;
    mock.set(Json{{"failStats", true}});  // the first load of the stats fails
    Session s(game);
    CHECK(run(s.engine, "platform.backend") == "steam");
    CommandResult status = s.engine.commands().call("steam.status");
    REQUIRE(status.ok);
    CHECK(has(status.result["interfaces"].get<std::string>(), "ISteamUserStats v012"));
    CHECK(has(status.result["interfaces"].get<std::string>(), "ISteamFriends v017"));
    CHECK(has(status.result["interfaces"].get<std::string>(), "ISteamApps v008"));
    CHECK(status.result["statsLoaded"] == false);  // asked for at start, not here yet
    CHECK(mock.count_calls("RequestCurrentStats") == 1);

    // The stats failed to load: the request that waited for them rejects with why, and the next one asks again.
    Json failed = settle(s.engine, "platform.achievements.unlock('first_win')");
    CHECK(failed["ok"] == false);
    CHECK(failed["code"] == "network");
    CHECK(has(text(failed, "message"), "Steam could not load the player's stats"));
    mock.set(Json{{"failStats", false}});
    Json ok = settle(s.engine, "platform.achievements.unlock('first_win')");
    REQUIRE(ok["ok"] == true);
    CHECK(ok["value"]["newly"] == true);
    CHECK(mock.count_calls("RequestCurrentStats") == 2);
    CHECK(mock.state()["achievements"]["ACH_WIN_ONE_GAME"] == true);

    // Things that need no stats work, and the older interfaces are called with their own pointers (the mock checks).
    CHECK(settle(s.engine, "platform.purchases.products()")["value"].size() == 2);
    CHECK(settle(s.engine, "platform.overlay.open('friends')")["ok"] == true);
    Json state = mock.state();
    CHECK(state["violations"].empty());
    CHECK(state["inits"] == 1);
    CHECK(s.engine.platform_services()->pending() == 0);
}

// ================================================================================================ steam future =====
TEST_CASE("steam future: a library of a newer SDK is refused with the supported range, and the game falls back") {
    SteamGame game(Library::Future, "");
    Session s(game, "");  // the way `factoria run` starts: factoria.json platform.backend names the plugin
    const std::string logs = s.logs();
    CHECK(has(logs, "has none of the interface accessors this plugin can use"));
    // It says which versions were tried: the ones it was checked against, then the window above them.
    CHECK(has(logs, "SteamAPI_SteamUserStats_v013, SteamAPI_SteamUserStats_v012; newer: SteamAPI_SteamUserStats_v014 to "
                    "SteamAPI_SteamUserStats_v018"));
    CHECK(has(logs, "SteamAPI_SteamUtils_v010; newer: SteamAPI_SteamUtils_v011 to SteamAPI_SteamUtils_v015"));
    CHECK(has(logs, "Steamworks SDK 1.58 to 1.64"));
    CHECK(has(logs, "plugin 'steam' is not loaded"));
    CHECK(has(logs, "factoria.json platform.backend names the plugin 'steam', which did not load"));
    CHECK(run(s.engine, "platform.backend") == "fake");
    CHECK(run(s.engine, "platform.has('purchases')") == true);  // the fake's
    CHECK(game.mock->state()["inits"] == 0);                    // Steam was never started
    CommandResult info = s.engine.commands().call("engine.info");
    REQUIRE(info.ok);
    bool listed = false;
    for (const Json& p : info.result["startupProblems"]) listed = listed || has(p.get<std::string>(), "plugin 'steam' is not loaded");
    CHECK(listed);
}

// =========================================================================================== steam without library =====
TEST_CASE("steam without library: the missing redistributable is explained, the game falls back") {
    SteamGame game(Library::None, "480");
    {
        Session s(game, "");
        const std::string logs = s.logs();
        CHECK(has(logs, (std::string("The Steamworks library ") + kLibraryFile + " was not found").c_str()));
        CHECK(has(logs, "partner.steamgames.com"));
        CHECK(has(logs, "platform.add_backend"));
        CHECK(has(logs, "fake platform backend in development"));
        CHECK(run(s.engine, "platform.backend") == "fake");
        CHECK(run(s.engine, "platform.has('achievements')") == true);
    }
    {
        // An exported game has no fake store: it runs without platform services.
        Session shipped(game, "", "none");
        CHECK(run(shipped.engine, "platform.backend") == "none");
        CHECK(run(shipped.engine, "platform.has('achievements')") == false);
        Json r = settle(shipped.engine, "platform.achievements.unlock('first_win')");
        CHECK(r["code"] == "unavailable");
    }
}

// ============================================================================================ steam not running =====
TEST_CASE("steam not running: Steam is not started, the message says what to do, the game falls back") {
    SteamGame game(Library::Current, "480");
    game.mock->set(Json{{"initMode", "norunning"}});
    {
        Session s(game, "");
        const std::string logs = s.logs();
        CHECK(has(logs, "Steam did not start"));
        CHECK(has(logs, "Steam is not running, or the game has no app id"));
        CHECK(has(logs, "Start the Steam client and sign in"));
        CHECK(has(logs, "steam_appid.txt holding 480"));
        CHECK(has(logs, "the fake platform backend in development, none in an exported game"));
        CHECK(has(logs, "The app id came from steam_appid.txt in "));
        CHECK(run(s.engine, "platform.backend") == "fake");
        CHECK(game.mock->state()["inits"] == 0);
    }
    {
        Session shipped(game, "", "none");
        CHECK(run(shipped.engine, "platform.backend") == "none");
        CHECK(run(shipped.engine, "platform.has('purchases')") == false);
    }
}

// =========================================================================================== steam without app id =====
TEST_CASE("steam without app id: Steam refuses to start, and the message names steam_appid.txt") {
    SteamGame game(Library::Current, "");
    game.mock->set(Json{{"initMode", "noappid"}});
    Session s(game, "");
    const std::string logs = s.logs();
    CHECK(has(logs, "Neither SteamAppId nor SteamGameId environment variable nor steam_appid.txt was found"));  // Steam's own words
    CHECK(has(logs, "No app id was found: there is no SteamAppId variable and no steam_appid.txt"));
    CHECK(has(logs, "must not ship a steam_appid.txt"));
    CHECK(run(s.engine, "platform.backend") == "fake");
}

// ================================================================================================== steam exit =====
// The process ends while Steam runs: the plugin stores the stats set since the last frame and shuts Steam down (atexit). A
// child process, since the exit is what is tested; the mock appends a line per StoreStats and Shutdown to a file.
TEST_CASE("steam child: start Steam, set a stat, end the process") {
    const char* log = std::getenv("FA_STEAM_EXIT_LOG");
    if (!log) return;  // only meaningful when "steam exit" starts it
    SteamGame game(Library::Current, "480");
    game.mock->set(Json{{"exitLog", std::string(log)}});
    Session s(game);
    run(s.engine, "platform.stats.set('wins', 5); 0");  // set, not stored yet: the next frame would
}

TEST_CASE("steam exit: the plugin stores pending stats and shuts Steam down when the process ends") {
#if defined(_WIN32)
    MESSAGE("Windows runs a DLL's exit handlers after Steam's own DLL is gone, so the plugin does not call Steam there");
#else
    const stdfs::path log = stdfs::canonical(fs::make_temp_dir("fa_steam_exit")) / "exit.log";
    set_environment("FA_STEAM_EXIT_LOG", log.generic_string());
    const std::string command = std::string("\"") + FA_STEAM_TEST_EXE + "\" \"--test-case=steam child*\" > /dev/null 2>&1";
    const int rc = std::system(command.c_str());
    clear_environment("FA_STEAM_EXIT_LOG");
    CHECK(rc == 0);
    std::ifstream in(log);
    const std::string content((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    CHECK(content == "StoreStats\nShutdown\n");
    std::error_code ec;
    stdfs::remove_all(log.parent_path(), ec);
#endif
}
