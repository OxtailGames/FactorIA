// The Steam backend: the state it shares between requests, how requests are answered, and how Steam's callbacks are pumped
// (manual dispatch). Everything here runs on the game's thread: the engine calls `request` and `frame` there, and the
// plugin never answers from another one.
#pragma once

#include <cstdint>
#include <cstring>
#include <functional>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "fa_plugin.h"
#include "json_mini.h"
#include "steam_loader.h"
#include "steam_types.h"

namespace steam_plugin {

// How a request that Steam answers later is continued: the call result's bytes, or ioFailed when Steam could not deliver it.
using ResultHandler = std::function<void(const std::uint8_t* data, int size, bool ioFailed)>;

struct Backend {
    const FaPluginApi* api = nullptr;
    SteamApi steam;
    u64 selfId = 0;   // the player's SteamID
    u32 appId = 0;    // the game's app id (ISteamUtils::GetAppID)
    bool started = false;  // Steam is initialised and not yet shut down

    // Stats: SDK 1.61 and newer have them at init (Ready); older ones load them after RequestCurrentStats (Loading) and
    // requests that need them wait.
    enum class Stats { Ready, Idle, Loading };
    Stats stats = Stats::Ready;
    struct Held {
        FaRequest* request;
        std::function<void()> run;
    };
    std::vector<Held> heldForStats;
    bool statsDirty = false;  // a stat was set and StoreStats has not been called since

    struct Call {
        int callback;  // the id of the result structure the request waits for
        ResultHandler handler;
    };
    std::map<u64, Call> calls;                      // API call handle -> who waits for it
    std::map<std::string, u64> leaderboards;        // store name -> handle (a leaderboard handle is valid for the session)
    std::set<std::string> warned;                   // warnings that are logged once
    std::string library;

    // The platform keyboard (text_input.cpp): which of Steam's keyboards is up for the focused TextField.
    enum class Keyboard { None, Floating, Modal };
    Keyboard keyboard = Keyboard::None;
};

Backend& backend();
inline SteamApi& steam() { return backend().steam; }

// ----------------------------------------------------------------------------------------------------- answering --
void log(int level, const std::string& message);   // 0 debug, 1 info, 2 warning, 3 error
void warn_once(const std::string& key, const std::string& message);
void resolve(FaRequest* request, const Json& result);
// code: "unavailable", "notSignedIn", "notAllowed", "unknownId", "network" or "failed" (docs/PLATFORM.md).
void reject(FaRequest* request, const char* code, const std::string& message, const std::string& hint = std::string());
void emit(const char* event, const Json& data);

// ------------------------------------------------------------------------------------------------- Steam's side --
// Continue `request` when Steam completes `call` with the result structure `callback`. A call of 0 is Steam refusing to
// start it: the request is rejected right away.
void wait_for(FaRequest* request, u64 call, int callback, ResultHandler handler);

// The typed form: `ok` gets the result structure; an I/O failure or a result of the wrong size rejects the request.
template <class T, class Ok>
void wait_for(FaRequest* request, u64 call, Ok ok) {
    wait_for(request, call, T::kCallback, [request, ok](const std::uint8_t* data, int size, bool ioFailed) {
        if (ioFailed) {
            reject(request, "network", "Steam could not complete the request: the connection to Steam's servers failed",
                   "Check that Steam is online (not in Offline Mode) and offer the player a retry.");
            return;
        }
        if (size < static_cast<int>(sizeof(T))) {
            reject(request, "failed",
                   "Steam answered with a result of " + std::to_string(size) + " bytes, but this plugin expects " +
                       std::to_string(sizeof(T)),
                   "The Steam library does not match the SDK this plugin was checked against (" + std::string(kCheckedSdk) +
                       "): use the redistributable of one of them, or update the plugin.");
            return;
        }
        T value;
        std::memcpy(&value, data, sizeof value);
        ok(value);
    });
}

// Runs `run` now when the player's stats are loaded, else when they arrive; rejects `request` if they cannot be loaded.
void with_stats(FaRequest* request, std::function<void()> run);
// StoreStats; false (after rejecting `request`) when Steam did not take it.
bool store_stats(FaRequest* request);

// Once per frame: Steam's RunFrame, then every callback and call result that is ready.
void run_frame();
// Calls StoreStats for stats set since the last time (the frame does it; the exit does too).
void flush_stats();

// ---------------------------------------------------------------------------------------------- platform keyboard --
// The plugin API 3 text input handler (text_input.cpp): on a Steam Deck or in Big Picture it opens Steam's floating keyboard
// (Steam types into the window as key presses) or, where that is not offered, the modal one (the text comes back through
// text_input_dismissed). Returns 1 when Steam shows a keyboard.
int on_text_input(const FaTextInput* input, void* user);
void text_input_dismissed(const GamepadTextInputDismissed& result);   // the modal keyboard closed: hand its text to the field
void floating_text_input_dismissed();                                  // the floating keyboard closed

// ------------------------------------------------------------------------------------------------------ methods --
// plugin.cpp routes a request to one of these; each answers the request exactly once.
void handle_request(FaRequest* request, const char* method, const char* argsJson);

using Handler = void (*)(FaRequest*, const Json&);
const std::map<std::string, Handler>& player_and_stats_methods();   // methods_game.cpp
const std::map<std::string, Handler>& store_methods();              // methods_store.cpp

// Helpers the method files share.
Json player_json();                                      // {id, name, signedIn} of the player
std::string app_text();                                // "app 480"
std::string quoted(const std::string& s);                // "\"text\""
bool parse_app_id(const std::string& text, u32& id);     // a DLC's app id written as digits
std::string display_name(u64 steamId);                   // GetFriendPersonaName, "" when unknown

}  // namespace steam_plugin
