// A mock of the Steamworks redistributable, for the tests of the Steam plugin: a shared library with the file name of the real one
// (steam_api64.dll, libsteam_api.dylib, libsteam_api.so) that exports every flat function the plugin calls, with everything in memory.
// Call results and callbacks come out of the manual-dispatch functions on the next SteamAPI_ManualDispatch_RunFrame, as in Steam.
//
// It plays Valve's test app 480 (Spacewar): the achievements ACH_WIN_ONE_GAME, ACH_WIN_100_GAMES, ACH_TRAVEL_FAR_ACCUM and
// ACH_TRAVEL_FAR_SINGLE, the stats NumGames, NumWins, NumLosses (int) and FeetTraveled, MaxFeetTraveled, AverageSpeed (float), and the
// leaderboard "Feet Traveled" with a few other players. It also checks how it is used and records every violation: a call with the
// wrong interface pointer, GetNextCallback without FreeLastCallback, manual dispatch before ManualDispatch_Init.
//
// The tests drive it through one exported function, MockSteam_Control(json): see control() below. Three variants of the same source are
// built (CMake): the current SDK (1.62 and newer interface versions), a "legacy" one (1.58 to 1.60: older interface versions, stats
// that must be requested, no SteamAPI_InitFlat) and a "future" one whose interface versions the plugin does not know.
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <iterator>
#include <map>
#include <string>
#include <type_traits>
#include <vector>

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

#include <nlohmann/json.hpp>

#include "../src/steam_functions.h"
#include "../src/steam_types.h"

#if defined(_WIN32)
#define MOCK_API extern "C" __declspec(dllexport)
#else
#define MOCK_API extern "C" __attribute__((visibility("default")))
#endif

using namespace steam_plugin;
using Json = nlohmann::ordered_json;

namespace {

struct Entry {
    u64 steamId;
    i32 score;
};

struct Ranked {
    int rank;
    Entry entry;
};

struct Board {
    u64 handle = 0;
    std::string name;
    int sort = kSortDescending;
    std::vector<Entry> entries;  // best first
};

struct Completed {
    int callback = 0;
    std::vector<std::uint8_t> data;
    bool ioFailed = false;
};

struct Queued {
    int id;
    std::vector<std::uint8_t> data;
};

struct World {
    // lifecycle
    bool initialized = false, manual = false, running = true;
    int shutdowns = 0, inits = 0;
    std::string appIdEnv, gameIdEnv;
    // the player
    bool loggedOn = true;
    u64 steamId = 76561198000000001ull;
    std::string persona = "Tester";
    std::map<u64, std::string> names;
    // stats and achievements
    struct Achievement {
        bool unlocked = false;
    };
    std::map<std::string, Achievement> achievements;
    std::map<std::string, i32> intStats;
    std::map<std::string, float> floatStats;
    Json stored = Json::object();  // what the last StoreStats took
    int storeCalls = 0;
    bool statsLoaded = true, failStats = false;
    // leaderboards
    std::map<u64, Board> boards;
    bool createBoards = true;
    std::map<u64, std::vector<Ranked>> downloaded;  // entry handle -> the entries a download returned, with their global ranks
    std::vector<u64> friends;
    int findCalls = 0;
    // cloud: the files, and the time Steam stamped each with (Unix seconds; a write takes `clock` and moves it on a second)
    std::map<std::string, std::string> files;
    std::map<std::string, i64> fileTimes;
    i64 clock = 1767225600;  // 2026-01-01T00:00:00Z, like the fake backend's cloud clock
    bool cloudAccount = true, cloudApp = true, failWrites = false;
    // Remote Play Together: the guests connected now (ISteamRemotePlay)
    struct Guest {
        u32 id;
        u64 steamId;
        std::string device;
        int formFactor;  // ESteamDeviceFormFactor
        int width, height;
    };
    std::vector<Guest> guests;
    // DLC
    struct Dlc {
        u32 appId;
        std::string name;
        bool owned;
    };
    std::vector<Dlc> dlc;
    // the keyboards (ISteamUtils): where Steam runs, which of them it offers, and the text the modal one returns
    bool onDeck = false, bigPicture = false, floatingOffered = true, modalOffered = true;
    std::string enteredText;
    // overlay and presence
    bool overlayEnabled = true;
    std::map<std::string, std::string> presence;
    // the pump
    u64 nextHandle = 5000;
    std::vector<std::pair<u64, Completed>> ready;  // delivered by the next RunFrame
    std::map<u64, Completed> completed;
    std::deque<Queued> queue;
    std::vector<std::uint8_t> current;
    bool inCallback = false, hold = false;
    int failNext = 0, refuseNext = 0;
    // what happened
    std::vector<std::string> calls;
    std::vector<std::string> violations;
};

World g;
// Kept across "reset": how Steam starts (decides what SteamAPI_Init does) and where the calls of a process that exits are logged.
std::string g_initMode, g_exitLog;
bool g_noRemotePlay = false;  // a Steam client that hands out no ISteamRemotePlay (the accessor returns null)

void log_line(const std::string& line) {
    if (g_exitLog.empty()) return;
    if (std::FILE* f = std::fopen(g_exitLog.c_str(), "ab")) {
        std::fprintf(f, "%s\n", line.c_str());
        std::fclose(f);
    }
}

void reset_world() {
    const int shutdowns = g.shutdowns, inits = g.inits;
    const bool initialized = g.initialized, manual = g.manual;
    const std::string appIdEnv = g.appIdEnv, gameIdEnv = g.gameIdEnv;
    g = World();
    g.shutdowns = shutdowns;
    g.inits = inits;
    g.initialized = initialized;
    g.manual = manual;
    g.appIdEnv = appIdEnv;
    g.gameIdEnv = gameIdEnv;
    for (const char* a : {"ACH_WIN_ONE_GAME", "ACH_WIN_100_GAMES", "ACH_TRAVEL_FAR_ACCUM", "ACH_TRAVEL_FAR_SINGLE"}) g.achievements[a] = {};
    for (const char* s : {"NumGames", "NumWins", "NumLosses"}) g.intStats[s] = 0;
    for (const char* s : {"FeetTraveled", "MaxFeetTraveled", "AverageSpeed"}) g.floatStats[s] = 0.0f;
    g.names = {{g.steamId, "Tester"}, {76561198000000002ull, "Alice"}, {76561198000000003ull, "Bob"}, {76561198000000004ull, "Carol"}};
    g.friends = {76561198000000002ull, 76561198000000003ull};
    Board feet;
    feet.handle = 900;
    feet.name = "Feet Traveled";
    feet.sort = kSortDescending;
    feet.entries = {{76561198000000002ull, 5000}, {76561198000000003ull, 3000}, {76561198000000004ull, 1000}};
    g.boards[feet.handle] = feet;
    g.dlc = {{480001, "Spacewar Soundtrack", false}, {480002, "Spacewar Skin Pack", true}};
}

struct Init {
    Init() { reset_world(); }
} initialize_world;

// ------------------------------------------------------------------------------------------------------ interfaces --
// The accessors hand out these; every method checks that it got the right one.
char g_user, g_friends, g_utils, g_apps, g_userStats, g_remoteStorage, g_remotePlay;

void violation(const std::string& what) { g.violations.push_back(what); }

void expect(const void* self, const void* tag, const char* method) {
    if (self != tag) violation(std::string(method) + " was called with the wrong interface pointer");
}

void record(const std::string& call) { g.calls.push_back(call); }

template <class T>
std::vector<std::uint8_t> bytes_of(const T& value) {
    std::vector<std::uint8_t> out(sizeof value);
    std::memcpy(out.data(), &value, sizeof value);
    return out;
}

void push_callback(int id, std::vector<std::uint8_t> data) { g.queue.push_back({id, std::move(data)}); }

// A call result that RunFrame will deliver. 0 = Steam refuses to start the call.
template <class T>
u64 new_call(const T& result) {
    if (g.refuseNext > 0) {
        --g.refuseNext;
        return 0;
    }
    Completed c;
    c.callback = T::kCallback;
    c.data = bytes_of(result);
    if (g.failNext > 0) {
        --g.failNext;
        c.ioFailed = true;
    }
    const u64 handle = ++g.nextHandle;
    g.ready.emplace_back(handle, std::move(c));
    return handle;
}

void sort_board(Board& b) {
    std::stable_sort(b.entries.begin(), b.entries.end(), [&](const Entry& x, const Entry& y) {
        return b.sort == kSortAscending ? x.score < y.score : x.score > y.score;
    });
}

int rank_of(const Board& b, u64 steamId) {
    for (std::size_t i = 0; i < b.entries.size(); ++i)
        if (b.entries[i].steamId == steamId) return static_cast<int>(i) + 1;
    return 0;
}

Board* find_board(u64 handle) {
    auto it = g.boards.find(handle);
    return it == g.boards.end() ? nullptr : &it->second;
}

// Everything that needs the player's stats: false until they are loaded.
bool stats_usable() { return g.initialized && g.statsLoaded; }

// An environment variable as the process has it (on Windows the plugin and this library have their own C runtimes: ask the system).
std::string env_or_empty(const char* name) {
#if defined(_WIN32)
    char buffer[512];
    const DWORD n = GetEnvironmentVariableA(name, buffer, sizeof buffer);
    return n > 0 && n < sizeof buffer ? std::string(buffer, n) : std::string();
#else
    const char* v = std::getenv(name);
    return v ? v : "";
#endif
}

// ------------------------------------------------------------------------------------------------------- control ---
std::string control_result;

Json state() {
    Json s = Json::object();
    Json ach = Json::object();
    for (const auto& a : g.achievements) ach[a.first] = a.second.unlocked;
    Json ints = Json::object(), floats = Json::object();
    for (const auto& i : g.intStats) ints[i.first] = i.second;
    for (const auto& f : g.floatStats) floats[f.first] = f.second;
    Json boards = Json::object();
    for (const auto& b : g.boards) {
        Json entries = Json::array();
        for (const Entry& e : b.second.entries) entries.push_back(Json::object({{"steamId", std::to_string(e.steamId)}, {"score", e.score}}));
        boards[b.second.name] = Json::object({{"sort", b.second.sort}, {"entries", entries}});
    }
    Json files = Json::object();
    for (const auto& f : g.files) files[f.first] = f.second;
    Json fileTimes = Json::object();
    for (const auto& f : g.fileTimes) fileTimes[f.first] = f.second;
    Json guests = Json::array();
    for (const auto& guest : g.guests)
        guests.push_back(Json::object({{"id", guest.id}, {"steamId", std::to_string(guest.steamId)}, {"device", guest.device},
                                       {"formFactor", guest.formFactor}, {"width", guest.width}, {"height", guest.height}}));
    Json presence = Json::object();
    for (const auto& p : g.presence) presence[p.first] = p.second;
    Json dlc = Json::object();
    for (const auto& d : g.dlc) dlc[std::to_string(d.appId)] = d.owned;
    s["initialized"] = g.initialized;
    s["manual"] = g.manual;
    s["inits"] = g.inits;
    s["shutdowns"] = g.shutdowns;
    s["appIdEnv"] = g.appIdEnv;
    s["gameIdEnv"] = g.gameIdEnv;
    s["achievements"] = ach;
    s["intStats"] = ints;
    s["floatStats"] = floats;
    s["stored"] = g.stored;
    s["storeCalls"] = g.storeCalls;
    s["boards"] = boards;
    s["findCalls"] = g.findCalls;
    s["files"] = files;
    s["fileTimes"] = fileTimes;
    s["guests"] = guests;
    s["presence"] = presence;
    s["dlc"] = dlc;
    s["pending"] = g.ready.size() + g.completed.size();
    s["calls"] = g.calls;
    s["violations"] = g.violations;
    return s;
}

// Commands (one JSON object, "op" says which):
//   state                         the whole state: achievements, stats, boards, files, presence, DLC, calls, violations
//   reset                         the defaults (the library stays initialised)
//   set {...}                     options: initMode ("", "norunning", "noappid", "mismatch": how SteamAPI_Init fails), exitLog (a file
//                                 that gets a line for every StoreStats and Shutdown), loggedOn, running, cloudAccount, cloudApp, failWrites, overlayEnabled, createBoards, failStats,
//                                 onDeck, bigPicture (IsSteamRunningOnSteamDeck / InBigPictureMode), floatingOffered, modalOffered (false: that keyboard's function returns false),
//                                 hold (keep call results back until "release"), failNext (n call results end in an I/O failure),
//                                 refuseNext (n calls return the invalid handle 0), unlockedAchievements [names], intStats {name: n}
//   release                       deliver the call results that were held back
//   fire overlay {active}         GameOverlayActivated_t
//   fire gamepadText {submitted, text}  the modal keyboard closed: GamepadTextInputDismissed_t, GetEnteredGamepadTextInput has text
//   fire floatingDismissed        FloatingGamepadTextInputDismissed_t
//   fire dlc {appId, owned}       the player gets the DLC: DlcInstalled_t
//   fire connected | disconnected SteamServersConnected_t, SteamServersDisconnected_t
//   fire stray                    a SteamAPICallCompleted_t for a call nobody made
//   fire remotePlayConnect {id, steamId, device, formFactor, width, height}  a guest joins: SteamRemotePlaySessionConnected_t
//   fire remotePlayDisconnect {id}  the guest leaves: SteamRemotePlaySessionDisconnected_t (Steam no longer knows the session)
//   set guests [{id, steamId, device, formFactor, width, height}]  guests that are connected already, announced by no callback
//   set noRemotePlay (kept by reset)  the accessor of ISteamRemotePlay returns null, as a client without Remote Play does
//   set fileTimes {name: unix seconds}, clock n  the time of a cloud file, and the time the next write gets
//   clearCalls                    forget the call log
Json control(const Json& cmd) {
    const std::string op = cmd.value("op", "");
    if (op == "state") return state();
    if (op == "reset") {
        reset_world();
    } else if (op == "clearCalls") {
        g.calls.clear();
        g.violations.clear();
    } else if (op == "release") {
        g.hold = false;
    } else if (op == "set") {
        auto flag = [&](const char* key, bool& field) {
            if (cmd.contains(key)) field = cmd[key].get<bool>();
        };
        flag("loggedOn", g.loggedOn);
        flag("running", g.running);
        flag("cloudAccount", g.cloudAccount);
        flag("cloudApp", g.cloudApp);
        flag("failWrites", g.failWrites);
        flag("overlayEnabled", g.overlayEnabled);
        flag("onDeck", g.onDeck);
        flag("bigPicture", g.bigPicture);
        flag("floatingOffered", g.floatingOffered);
        flag("modalOffered", g.modalOffered);
        flag("createBoards", g.createBoards);
        flag("failStats", g.failStats);
        flag("hold", g.hold);
        flag("noRemotePlay", g_noRemotePlay);
        if (cmd.contains("clock")) g.clock = cmd["clock"].get<i64>();
        if (cmd.contains("fileTimes"))
            for (auto it = cmd["fileTimes"].begin(); it != cmd["fileTimes"].end(); ++it) g.fileTimes[it.key()] = it->get<i64>();
        if (cmd.contains("guests"))
            for (const auto& e : cmd["guests"])
                g.guests.push_back({e.value("id", 1u), std::stoull(e.value("steamId", std::string("76561198000000002"))),
                                    e.value("device", std::string("Test phone")), e.value("formFactor", 1), e.value("width", 1280),
                                    e.value("height", 720)});
        if (cmd.contains("initMode")) g_initMode = cmd["initMode"].get<std::string>();
        if (cmd.contains("exitLog")) g_exitLog = cmd["exitLog"].get<std::string>();
        if (cmd.contains("failNext")) g.failNext = cmd["failNext"].get<int>();
        if (cmd.contains("refuseNext")) g.refuseNext = cmd["refuseNext"].get<int>();
        if (cmd.contains("unlockedAchievements"))
            for (const auto& n : cmd["unlockedAchievements"]) g.achievements[n.get<std::string>()].unlocked = true;
        if (cmd.contains("intStats"))
            for (auto it = cmd["intStats"].begin(); it != cmd["intStats"].end(); ++it) g.intStats[it.key()] = it->get<i32>();
        if (cmd.contains("files"))
            for (auto it = cmd["files"].begin(); it != cmd["files"].end(); ++it) {
                g.files[it.key()] = it->get<std::string>();
                g.fileTimes[it.key()] = g.clock++;
            }
        if (cmd.contains("boardScore")) {  // {board, steamId, score}: someone's entry
            Board* b = nullptr;
            for (auto& e : g.boards)
                if (e.second.name == cmd["boardScore"].value("board", "")) b = &e.second;
            if (b) {
                const u64 id = std::stoull(cmd["boardScore"].value("steamId", std::to_string(g.steamId)));
                b->entries.erase(std::remove_if(b->entries.begin(), b->entries.end(), [&](const Entry& e) { return e.steamId == id; }), b->entries.end());
                b->entries.push_back({id, cmd["boardScore"].value("score", 0)});
                sort_board(*b);
            }
        }
    } else if (op == "fire") {
        const std::string what = cmd.value("what", "");
        if (what == "overlay") {
            GameOverlayActivated a{};
            a.active = cmd.value("active", true) ? 1 : 0;
            a.userInitiated = true;
            a.appId = 480;
            push_callback(kGameOverlayActivated, bytes_of(a));
        } else if (what == "gamepadText") {  // the modal keyboard closed: {submitted, text}
            g.enteredText = cmd.value("text", "");
            GamepadTextInputDismissed d{};
            d.submitted = cmd.value("submitted", true);
            d.submittedText = static_cast<u32>(g.enteredText.size());
            push_callback(kGamepadTextInputDismissed, bytes_of(d));
        } else if (what == "floatingDismissed") {  // the floating keyboard closed
            push_callback(kFloatingGamepadTextInputDismissed, {});
        } else if (what == "dlc") {
            const u32 app = cmd.value("appId", 480001u);
            for (auto& d : g.dlc)
                if (d.appId == app) d.owned = true;
            DlcInstalled d{app};
            push_callback(kDlcInstalled, bytes_of(d));
        } else if (what == "connected") {
            push_callback(kSteamServersConnected, {});
        } else if (what == "disconnected") {
            SteamServersDisconnected d{kResultNoConnection};
            push_callback(kSteamServersDisconnected, bytes_of(d));
        } else if (what == "remotePlayConnect") {
            World::Guest guest{cmd.value("id", 1u), std::stoull(cmd.value("steamId", std::string("76561198000000002"))),
                        cmd.value("device", std::string("Test phone")), cmd.value("formFactor", 1), cmd.value("width", 1280),
                        cmd.value("height", 720)};
            g.guests.push_back(guest);
            push_callback(kSteamRemotePlaySessionConnected, bytes_of(SteamRemotePlaySessionConnected{guest.id}));
        } else if (what == "remotePlayDisconnect") {
            const u32 id = cmd.value("id", 1u);
            g.guests.erase(std::remove_if(g.guests.begin(), g.guests.end(), [&](const World::Guest& x) { return x.id == id; }), g.guests.end());
            push_callback(kSteamRemotePlaySessionDisconnected, bytes_of(SteamRemotePlaySessionDisconnected{id}));
        } else if (what == "stray") {
            SteamAPICallCompleted c{424242, kLeaderboardFindResult, sizeof(LeaderboardFindResult)};
            Completed result;
            result.callback = kLeaderboardFindResult;
            result.data = bytes_of(LeaderboardFindResult{});
            g.completed[424242] = result;
            push_callback(kSteamAPICallCompleted, bytes_of(c));
        } else {
            return Json::object({{"error", "unknown fire " + what}});
        }
    } else {
        return Json::object({{"error", "unknown op " + op}});
    }
    return Json::object({{"ok", true}});
}

}  // namespace

// The one function the tests call (they load this library themselves and share its state with the plugin).
MOCK_API const char* MockSteam_Control(const char* json) {
    Json cmd = Json::parse(json ? json : "{}", nullptr, false);
    control_result = cmd.is_discarded() ? Json::object({{"error", "not JSON"}}).dump() : control(cmd).dump();
    return control_result.c_str();
}

// ------------------------------------------------------------------------------------------------------ the flat API --
// Lifecycle.
#if !defined(MOCK_LEGACY)
MOCK_API int SteamAPI_InitFlat(char* errMessage) {
    const std::string mode = g_initMode;
    g.appIdEnv = env_or_empty("SteamAppId");
    g.gameIdEnv = env_or_empty("SteamGameId");
    auto fail = [&](int result, const char* text) {
        if (errMessage) std::snprintf(errMessage, 1024, "%s", text);
        return result;
    };
    if (mode == "norunning") {
        g.running = false;
        return fail(kInitNoSteamClient, "SteamAPI_Init(): Sys_LoadModule failed to load the Steam client library");
    }
    if (mode == "noappid") return fail(kInitFailedGeneric, "SteamAPI_Init(): Neither SteamAppId nor SteamGameId environment variable nor steam_appid.txt was found");
    if (mode == "mismatch") return fail(kInitVersionMismatch, "Steam client appears to be out of date");
    g.initialized = true;
    ++g.inits;
    return kInitOk;
}
#endif

MOCK_API bool SteamAPI_Init() {
    g.appIdEnv = env_or_empty("SteamAppId");
    g.gameIdEnv = env_or_empty("SteamGameId");
    if (g_initMode == "norunning") {
        g.running = false;
        return false;
    }
    g.initialized = true;
    ++g.inits;
    return true;
}

MOCK_API bool SteamAPI_IsSteamRunning() { return g.running; }

MOCK_API void SteamAPI_Shutdown() {
    ++g.shutdowns;
    g.initialized = false;
    log_line("Shutdown");
}

MOCK_API i32 SteamAPI_GetHSteamPipe() { return 77; }

MOCK_API void SteamAPI_ManualDispatch_Init() { g.manual = true; }

MOCK_API void SteamAPI_ManualDispatch_RunFrame(i32) {
    if (!g.manual) violation("ManualDispatch_RunFrame before ManualDispatch_Init");
    if (g.hold) return;
    for (auto& r : g.ready) {
        SteamAPICallCompleted done{r.first, r.second.callback, static_cast<u32>(r.second.data.size())};
        g.completed[r.first] = r.second;
        push_callback(kSteamAPICallCompleted, bytes_of(done));
    }
    g.ready.clear();
}

MOCK_API bool SteamAPI_ManualDispatch_GetNextCallback(i32, CallbackMsg* message) {
    if (!g.manual) violation("ManualDispatch_GetNextCallback before ManualDispatch_Init");
    if (g.inCallback) violation("GetNextCallback was called again before FreeLastCallback");
    if (g.queue.empty()) return false;
    g.current = std::move(g.queue.front().data);
    message->hSteamUser = 1;
    message->callback = g.queue.front().id;
    if (g.queue.front().id == kUserStatsReceived && !g.failStats) g.statsLoaded = true;  // the player's stats arrived
    message->param = g.current.data();
    message->paramSize = static_cast<i32>(g.current.size());
    g.queue.pop_front();
    g.inCallback = true;
    return true;
}

MOCK_API void SteamAPI_ManualDispatch_FreeLastCallback(i32) {
    if (!g.inCallback) violation("FreeLastCallback was called without a callback");
    g.inCallback = false;
    g.current.clear();
}

MOCK_API bool SteamAPI_ManualDispatch_GetAPICallResult(i32, u64 call, void* buffer, int size, int expected, bool* failed) {
    auto it = g.completed.find(call);
    if (it == g.completed.end()) return false;
    if (it->second.callback != expected) {
        violation("GetAPICallResult expected callback " + std::to_string(expected) + " but the call has " + std::to_string(it->second.callback));
        return false;
    }
    if (size < static_cast<int>(it->second.data.size())) {
        violation("GetAPICallResult got a buffer of " + std::to_string(size) + " bytes for a result of " + std::to_string(it->second.data.size()));
        return false;
    }
    if (failed) *failed = it->second.ioFailed;
    if (!it->second.data.empty()) std::memcpy(buffer, it->second.data.data(), it->second.data.size());
    g.completed.erase(it);
    return true;
}

// Interface accessors: the versions each variant exports.
#if defined(MOCK_NEXT)
// What a Steamworks SDK after the newest the plugin knows exports (SDK 1.65 bumped ISteamUtils to v011): one version above
// each, everything else as in the current variant.
MOCK_API void* SteamAPI_SteamUser_v024() { return &g_user; }
MOCK_API void* SteamAPI_SteamFriends_v019() { return &g_friends; }
MOCK_API void* SteamAPI_SteamUtils_v011() { return &g_utils; }
MOCK_API void* SteamAPI_SteamApps_v010() { return &g_apps; }
MOCK_API void* SteamAPI_SteamUserStats_v014() { return &g_userStats; }
MOCK_API void* SteamAPI_SteamRemoteStorage_v017() { return &g_remoteStorage; }
MOCK_API void* SteamAPI_SteamRemotePlay_v002() { return g_noRemotePlay ? nullptr : &g_remotePlay; }
#elif defined(MOCK_FUTURE)
MOCK_API void* SteamAPI_SteamUser_v099() { return &g_user; }
MOCK_API void* SteamAPI_SteamFriends_v099() { return &g_friends; }
MOCK_API void* SteamAPI_SteamUtils_v099() { return &g_utils; }
MOCK_API void* SteamAPI_SteamApps_v099() { return &g_apps; }
MOCK_API void* SteamAPI_SteamUserStats_v099() { return &g_userStats; }
MOCK_API void* SteamAPI_SteamRemoteStorage_v099() { return &g_remoteStorage; }
MOCK_API void* SteamAPI_SteamRemotePlay_v002() { return g_noRemotePlay ? nullptr : &g_remotePlay; }
#elif defined(MOCK_LEGACY)
MOCK_API void* SteamAPI_SteamUser_v023() { return &g_user; }
MOCK_API void* SteamAPI_SteamFriends_v017() { return &g_friends; }
MOCK_API void* SteamAPI_SteamUtils_v010() { return &g_utils; }
MOCK_API void* SteamAPI_SteamApps_v008() { return &g_apps; }
MOCK_API void* SteamAPI_SteamUserStats_v012() { return &g_userStats; }
MOCK_API void* SteamAPI_SteamRemoteStorage_v016() { return &g_remoteStorage; }
// An older SDK exports only the first version of ISteamRemotePlay: the plugin falls back to it.
MOCK_API void* SteamAPI_SteamRemotePlay_v001() { return g_noRemotePlay ? nullptr : &g_remotePlay; }
#else
MOCK_API void* SteamAPI_SteamUser_v023() { return &g_user; }
MOCK_API void* SteamAPI_SteamFriends_v018() { return &g_friends; }
MOCK_API void* SteamAPI_SteamUtils_v010() { return &g_utils; }
MOCK_API void* SteamAPI_SteamApps_v009() { return &g_apps; }
MOCK_API void* SteamAPI_SteamUserStats_v013() { return &g_userStats; }
MOCK_API void* SteamAPI_SteamRemoteStorage_v016() { return &g_remoteStorage; }
MOCK_API void* SteamAPI_SteamRemotePlay_v002() { return g_noRemotePlay ? nullptr : &g_remotePlay; }
#endif

// ISteamUser.
MOCK_API bool SteamAPI_ISteamUser_BLoggedOn(void* self) {
    expect(self, &g_user, "ISteamUser::BLoggedOn");
    return g.loggedOn;
}
MOCK_API u64 SteamAPI_ISteamUser_GetSteamID(void* self) {
    expect(self, &g_user, "ISteamUser::GetSteamID");
    return g.steamId;
}

// ISteamFriends.
MOCK_API const char* SteamAPI_ISteamFriends_GetPersonaName(void* self) {
    expect(self, &g_friends, "ISteamFriends::GetPersonaName");
    return g.persona.c_str();
}
MOCK_API const char* SteamAPI_ISteamFriends_GetFriendPersonaName(void* self, u64 id) {
    expect(self, &g_friends, "ISteamFriends::GetFriendPersonaName");
    auto it = g.names.find(id);
    return it == g.names.end() ? "[unknown]" : it->second.c_str();
}
MOCK_API void SteamAPI_ISteamFriends_ActivateGameOverlay(void* self, const char* dialog) {
    expect(self, &g_friends, "ISteamFriends::ActivateGameOverlay");
    record(std::string("ActivateGameOverlay ") + dialog);
}
MOCK_API void SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(void* self, const char* url, int mode) {
    expect(self, &g_friends, "ISteamFriends::ActivateGameOverlayToWebPage");
    record(std::string("ActivateGameOverlayToWebPage ") + url + " " + std::to_string(mode));
}
MOCK_API void SteamAPI_ISteamFriends_ActivateGameOverlayToStore(void* self, u32 app, int flag) {
    expect(self, &g_friends, "ISteamFriends::ActivateGameOverlayToStore");
    record("ActivateGameOverlayToStore " + std::to_string(app) + " " + std::to_string(flag));
}
MOCK_API bool SteamAPI_ISteamFriends_SetRichPresence(void* self, const char* key, const char* value) {
    expect(self, &g_friends, "ISteamFriends::SetRichPresence");
    if (std::strlen(key) > 64 || std::strlen(value) > 256 || g.presence.size() >= 30) return false;
    if (*value) g.presence[key] = value;
    else g.presence.erase(key);
    return true;
}
MOCK_API void SteamAPI_ISteamFriends_ClearRichPresence(void* self) {
    expect(self, &g_friends, "ISteamFriends::ClearRichPresence");
    g.presence.clear();
}

// ISteamUtils.
MOCK_API u32 SteamAPI_ISteamUtils_GetAppID(void* self) {
    expect(self, &g_utils, "ISteamUtils::GetAppID");
    return 480;
}
MOCK_API bool SteamAPI_ISteamUtils_IsOverlayEnabled(void* self) {
    expect(self, &g_utils, "ISteamUtils::IsOverlayEnabled");
    return g.overlayEnabled;
}

MOCK_API bool SteamAPI_ISteamUtils_IsSteamRunningOnSteamDeck(void* self) {
    expect(self, &g_utils, "ISteamUtils::IsSteamRunningOnSteamDeck");
    return g.onDeck;
}
MOCK_API bool SteamAPI_ISteamUtils_IsSteamInBigPictureMode(void* self) {
    expect(self, &g_utils, "ISteamUtils::IsSteamInBigPictureMode");
    return g.bigPicture;
}
MOCK_API bool SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput(void* self, int mode, int x, int y, int w, int h) {
    expect(self, &g_utils, "ISteamUtils::ShowFloatingGamepadTextInput");
    record("ShowFloatingGamepadTextInput " + std::to_string(mode) + " " + std::to_string(x) + " " + std::to_string(y) + " " +
           std::to_string(w) + " " + std::to_string(h));
    return g.floatingOffered;
}
MOCK_API bool SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(void* self) {
    expect(self, &g_utils, "ISteamUtils::DismissFloatingGamepadTextInput");
    record("DismissFloatingGamepadTextInput");
    return true;
}
MOCK_API bool SteamAPI_ISteamUtils_ShowGamepadTextInput(void* self, int mode, int line, const char* description, u32 charMax, const char* existing) {
    expect(self, &g_utils, "ISteamUtils::ShowGamepadTextInput");
    record("ShowGamepadTextInput " + std::to_string(mode) + " " + std::to_string(line) + " " + std::string(description ? description : "") + " " +
           std::to_string(charMax) + " [" + std::string(existing ? existing : "") + "]");
    return g.modalOffered;
}
MOCK_API u32 SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(void* self) {
    expect(self, &g_utils, "ISteamUtils::GetEnteredGamepadTextLength");
    return static_cast<u32>(g.enteredText.size() + 1);  // with the terminating zero, as Steam counts it
}
MOCK_API bool SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(void* self, char* text, u32 size) {
    expect(self, &g_utils, "ISteamUtils::GetEnteredGamepadTextInput");
    if (size == 0) return false;
    std::snprintf(text, size, "%s", g.enteredText.c_str());
    return true;
}

// ISteamApps.
MOCK_API bool SteamAPI_ISteamApps_BIsDlcInstalled(void* self, u32 app) {
    expect(self, &g_apps, "ISteamApps::BIsDlcInstalled");
    for (const auto& d : g.dlc)
        if (d.appId == app) return d.owned;
    return false;
}
MOCK_API int SteamAPI_ISteamApps_GetDLCCount(void* self) {
    expect(self, &g_apps, "ISteamApps::GetDLCCount");
    return static_cast<int>(g.dlc.size());
}
MOCK_API bool SteamAPI_ISteamApps_BGetDLCDataByIndex(void* self, int index, u32* app, bool* available, char* name, int size) {
    expect(self, &g_apps, "ISteamApps::BGetDLCDataByIndex");
    if (index < 0 || index >= static_cast<int>(g.dlc.size())) return false;
    *app = g.dlc[static_cast<std::size_t>(index)].appId;
    *available = true;
    std::snprintf(name, static_cast<std::size_t>(size), "%s", g.dlc[static_cast<std::size_t>(index)].name.c_str());
    return true;
}

// ISteamUserStats.
#if defined(MOCK_LEGACY)
MOCK_API bool SteamAPI_ISteamUserStats_RequestCurrentStats(void* self) {
    expect(self, &g_userStats, "ISteamUserStats::RequestCurrentStats");
    record("RequestCurrentStats");
    UserStatsReceived received{480, g.failStats ? kResultFail : kResultOk, g.steamId};
    // The stats arrive with the next RunFrame, as a plain callback.
    push_callback(kUserStatsReceived, bytes_of(received));
    g.statsLoaded = false;
    return true;
}
#endif
MOCK_API bool SteamAPI_ISteamUserStats_GetStatInt32(void* self, const char* name, i32* value) {
    expect(self, &g_userStats, "ISteamUserStats::GetStat(int)");
    auto it = g.intStats.find(name);
    if (!stats_usable() || it == g.intStats.end()) return false;
    *value = it->second;
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_GetStatFloat(void* self, const char* name, float* value) {
    expect(self, &g_userStats, "ISteamUserStats::GetStat(float)");
    auto it = g.floatStats.find(name);
    if (!stats_usable() || it == g.floatStats.end()) return false;
    *value = it->second;
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_SetStatInt32(void* self, const char* name, i32 value) {
    expect(self, &g_userStats, "ISteamUserStats::SetStat(int)");
    auto it = g.intStats.find(name);
    if (!stats_usable() || it == g.intStats.end()) return false;
    it->second = value;
    record("SetStatInt32 " + std::string(name) + " " + std::to_string(value));
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_SetStatFloat(void* self, const char* name, float value) {
    expect(self, &g_userStats, "ISteamUserStats::SetStat(float)");
    auto it = g.floatStats.find(name);
    if (!stats_usable() || it == g.floatStats.end()) return false;
    it->second = value;
    record("SetStatFloat " + std::string(name));
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_GetAchievement(void* self, const char* name, bool* achieved) {
    expect(self, &g_userStats, "ISteamUserStats::GetAchievement");
    auto it = g.achievements.find(name);
    if (!stats_usable() || it == g.achievements.end()) return false;
    *achieved = it->second.unlocked;
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_SetAchievement(void* self, const char* name) {
    expect(self, &g_userStats, "ISteamUserStats::SetAchievement");
    auto it = g.achievements.find(name);
    if (!stats_usable() || it == g.achievements.end()) return false;
    it->second.unlocked = true;
    record(std::string("SetAchievement ") + name);
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_StoreStats(void* self) {
    expect(self, &g_userStats, "ISteamUserStats::StoreStats");
    if (!stats_usable() || !g.loggedOn) return false;
    ++g.storeCalls;
    record("StoreStats");
    log_line("StoreStats");
    Json snapshot = Json::object();
    for (const auto& a : g.achievements) snapshot["achievements"][a.first] = a.second.unlocked;
    for (const auto& i : g.intStats) snapshot["intStats"][i.first] = i.second;
    for (const auto& f : g.floatStats) snapshot["floatStats"][f.first] = f.second;
    g.stored = snapshot;
    push_callback(kUserStatsStored, bytes_of(UserStatsStored{480, kResultOk}));
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_IndicateAchievementProgress(void* self, const char* name, u32 current, u32 maximum) {
    expect(self, &g_userStats, "ISteamUserStats::IndicateAchievementProgress");
    if (!stats_usable() || g.achievements.find(name) == g.achievements.end()) return false;
    record(std::string("IndicateAchievementProgress ") + name + " " + std::to_string(current) + " " + std::to_string(maximum));
    return true;
}
MOCK_API bool SteamAPI_ISteamUserStats_ResetAllStats(void* self, bool achievementsToo) {
    expect(self, &g_userStats, "ISteamUserStats::ResetAllStats");
    if (!stats_usable()) return false;
    for (auto& i : g.intStats) i.second = 0;
    for (auto& f : g.floatStats) f.second = 0;
    if (achievementsToo)
        for (auto& a : g.achievements) a.second.unlocked = false;
    record(std::string("ResetAllStats ") + (achievementsToo ? "true" : "false"));
    return true;
}
MOCK_API u64 SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(void* self, const char* name, int sort, int display) {
    expect(self, &g_userStats, "ISteamUserStats::FindOrCreateLeaderboard");
    ++g.findCalls;
    record(std::string("FindOrCreateLeaderboard ") + name + " " + std::to_string(sort) + " " + std::to_string(display));
    LeaderboardFindResult result{};
    for (auto& b : g.boards)
        if (b.second.name == name) result = {b.first, 1};
    if (!result.found && g.createBoards) {
        Board b;
        b.handle = 1000 + g.boards.size();
        b.name = name;
        b.sort = sort;
        g.boards[b.handle] = b;
        result = {b.handle, 1};
    }
    return new_call(result);
}
MOCK_API u64 SteamAPI_ISteamUserStats_UploadLeaderboardScore(void* self, u64 handle, int method, i32 score, const i32*, int) {
    expect(self, &g_userStats, "ISteamUserStats::UploadLeaderboardScore");
    record("UploadLeaderboardScore " + std::to_string(score) + " method " + std::to_string(method));
    LeaderboardScoreUploaded result{};
    Board* b = find_board(handle);
    if (!b || !g.loggedOn) return new_call(result);  // success = 0
    result.success = 1;
    result.leaderboard = handle;
    result.score = score;
    const int before = rank_of(*b, g.steamId);
    bool changed = true;
    for (Entry& e : b->entries)
        if (e.steamId == g.steamId) {
            const bool better = b->sort == kSortAscending ? score < e.score : score > e.score;
            changed = method != kUploadKeepBest || better;
            if (changed) e.score = score;
        }
    if (before == 0) b->entries.push_back({g.steamId, score});
    sort_board(*b);
    result.scoreChanged = changed ? 1 : 0;
    result.globalRankNew = rank_of(*b, g.steamId);
    result.globalRankPrevious = before;
    return new_call(result);
}
MOCK_API u64 SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(void* self, u64 handle, int request, int from, int to) {
    expect(self, &g_userStats, "ISteamUserStats::DownloadLeaderboardEntries");
    record("DownloadLeaderboardEntries " + std::to_string(request) + " " + std::to_string(from) + " " + std::to_string(to));
    LeaderboardScoresDownloaded result{};
    Board* b = find_board(handle);
    if (!b) return new_call(result);
    std::vector<Ranked> picked;
    const int count = static_cast<int>(b->entries.size());
    auto pick = [&](int rank) { picked.push_back({rank, b->entries[static_cast<std::size_t>(rank - 1)]}); };
    if (request == kDataRequestGlobal) {
        for (int rank = from; rank <= to; ++rank)
            if (rank >= 1 && rank <= count) pick(rank);
    } else if (request == kDataRequestGlobalAroundUser) {
        const int mine = rank_of(*b, g.steamId);
        if (mine > 0)
            for (int rank = mine + from; rank <= mine + to; ++rank)
                if (rank >= 1 && rank <= count) pick(rank);
    } else if (request == kDataRequestFriends) {
        for (int rank = 1; rank <= count; ++rank) {
            const u64 id = b->entries[static_cast<std::size_t>(rank - 1)].steamId;
            if (id == g.steamId || std::find(g.friends.begin(), g.friends.end(), id) != g.friends.end()) pick(rank);
        }
    }
    result.leaderboard = handle;
    result.entries = ++g.nextHandle;
    result.count = static_cast<i32>(picked.size());
    g.downloaded[result.entries] = picked;
    return new_call(result);
}
MOCK_API bool SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(void* self, u64 entries, int index, void* out, i32*, int) {
    expect(self, &g_userStats, "ISteamUserStats::GetDownloadedLeaderboardEntry");
    auto it = g.downloaded.find(entries);
    if (it == g.downloaded.end() || index < 0 || index >= static_cast<int>(it->second.size())) return false;
    const Ranked& r = it->second[static_cast<std::size_t>(index)];
    LeaderboardEntry entry{};
    entry.steamId = r.entry.steamId;
    entry.score = r.entry.score;
    entry.globalRank = r.rank;
    std::memcpy(out, &entry, sizeof entry);
    return true;
}

// ISteamRemoteStorage.
MOCK_API bool SteamAPI_ISteamRemoteStorage_FileWrite(void* self, const char* name, const void* data, i32 size) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::FileWrite");
    if (g.failWrites) return false;
    g.files[name] = std::string(static_cast<const char*>(data), static_cast<std::size_t>(size));
    g.fileTimes[name] = g.clock++;
    return true;
}
MOCK_API i32 SteamAPI_ISteamRemoteStorage_FileRead(void* self, const char* name, void* data, i32 size) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::FileRead");
    auto it = g.files.find(name);
    if (it == g.files.end()) return 0;
    const i32 n = std::min<i32>(size, static_cast<i32>(it->second.size()));
    std::memcpy(data, it->second.data(), static_cast<std::size_t>(n));
    return n;
}
MOCK_API i32 SteamAPI_ISteamRemoteStorage_GetFileSize(void* self, const char* name) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::GetFileSize");
    auto it = g.files.find(name);
    return it == g.files.end() ? 0 : static_cast<i32>(it->second.size());
}
MOCK_API bool SteamAPI_ISteamRemoteStorage_FileExists(void* self, const char* name) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::FileExists");
    return g.files.count(name) > 0;
}
MOCK_API bool SteamAPI_ISteamRemoteStorage_FileDelete(void* self, const char* name) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::FileDelete");
    g.fileTimes.erase(name);
    return g.files.erase(name) > 0;
}
MOCK_API i64 SteamAPI_ISteamRemoteStorage_GetFileTimestamp(void* self, const char* name) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::GetFileTimestamp");
    auto it = g.fileTimes.find(name);
    return it == g.fileTimes.end() ? 0 : it->second;  // Steam answers 0 for a file that does not exist
}
MOCK_API i32 SteamAPI_ISteamRemoteStorage_GetFileCount(void* self) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::GetFileCount");
    return static_cast<i32>(g.files.size());
}
MOCK_API const char* SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(void* self, int index, i32* size) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::GetFileNameAndSize");
    if (index < 0 || index >= static_cast<int>(g.files.size())) return "";
    auto it = g.files.begin();
    std::advance(it, index);
    *size = static_cast<i32>(it->second.size());
    return it->first.c_str();
}
MOCK_API bool SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(void* self) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::IsCloudEnabledForAccount");
    return g.cloudAccount;
}
MOCK_API bool SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(void* self) {
    expect(self, &g_remoteStorage, "ISteamRemoteStorage::IsCloudEnabledForApp");
    return g.cloudApp;
}

// ISteamRemotePlay.
static const World::Guest* find_guest(u32 id) {
    for (const World::Guest& guest : g.guests)
        if (guest.id == id) return &guest;
    return nullptr;
}
MOCK_API u32 SteamAPI_ISteamRemotePlay_GetSessionCount(void* self) {
    expect(self, &g_remotePlay, "ISteamRemotePlay::GetSessionCount");
    return static_cast<u32>(g.guests.size());
}
MOCK_API u32 SteamAPI_ISteamRemotePlay_GetSessionID(void* self, int index) {
    expect(self, &g_remotePlay, "ISteamRemotePlay::GetSessionID");
    return index >= 0 && index < static_cast<int>(g.guests.size()) ? g.guests[static_cast<std::size_t>(index)].id : 0;
}
MOCK_API u64 SteamAPI_ISteamRemotePlay_GetSessionSteamID(void* self, u32 id) {
    expect(self, &g_remotePlay, "ISteamRemotePlay::GetSessionSteamID");
    const World::Guest* guest = find_guest(id);
    return guest ? guest->steamId : 0;  // an invalid CSteamID for a session Steam does not know
}
MOCK_API const char* SteamAPI_ISteamRemotePlay_GetSessionClientName(void* self, u32 id) {
    expect(self, &g_remotePlay, "ISteamRemotePlay::GetSessionClientName");
    const World::Guest* guest = find_guest(id);
    return guest ? guest->device.c_str() : nullptr;
}
MOCK_API int SteamAPI_ISteamRemotePlay_GetSessionClientFormFactor(void* self, u32 id) {
    expect(self, &g_remotePlay, "ISteamRemotePlay::GetSessionClientFormFactor");
    const World::Guest* guest = find_guest(id);
    return guest ? guest->formFactor : 0;
}
MOCK_API bool SteamAPI_ISteamRemotePlay_BGetSessionClientResolution(void* self, u32 id, int* width, int* height) {
    expect(self, &g_remotePlay, "ISteamRemotePlay::BGetSessionClientResolution");
    const World::Guest* guest = find_guest(id);
    if (!guest || guest->width <= 0) return false;
    *width = guest->width;
    *height = guest->height;
    return true;
}

// The compiler checks that every function the plugin calls is defined here with the signature the plugin declares.
#define MOCK_CHECK_SIGNATURE(name, ret, params) static_assert(std::is_same<decltype(&::name), ret(*) params>::value, "signature of " #name);
STEAM_REQUIRED_FUNCTIONS(MOCK_CHECK_SIGNATURE)
#if !defined(MOCK_LEGACY)
MOCK_CHECK_SIGNATURE(SteamAPI_InitFlat, int, (char*))
#else
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUserStats_RequestCurrentStats, bool, (void*))
#endif
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_IsSteamRunningOnSteamDeck, bool, (void*))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_IsSteamInBigPictureMode, bool, (void*))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput, bool, (void*, int, int, int, int, int))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput, bool, (void*))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_ShowGamepadTextInput, bool, (void*, int, int, const char*, u32, const char*))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_GetEnteredGamepadTextLength, u32, (void*))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamUtils_GetEnteredGamepadTextInput, bool, (void*, char*, u32))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamRemotePlay_GetSessionCount, u32, (void*))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamRemotePlay_GetSessionID, u32, (void*, int))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamRemotePlay_GetSessionSteamID, u64, (void*, u32))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamRemotePlay_GetSessionClientName, const char*, (void*, u32))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamRemotePlay_GetSessionClientFormFactor, int, (void*, u32))
MOCK_CHECK_SIGNATURE(SteamAPI_ISteamRemotePlay_BGetSessionClientResolution, bool, (void*, u32, int*, int*))
MOCK_CHECK_SIGNATURE(SteamAPI_Init, bool, ())
MOCK_CHECK_SIGNATURE(SteamAPI_IsSteamRunning, bool, ())
