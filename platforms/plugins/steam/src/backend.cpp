// Answering requests, waiting for Steam's call results and pumping its callbacks (manual dispatch).
#include "backend.h"

#include <algorithm>
#include <exception>

namespace steam_plugin {

Backend& backend() {
    static Backend instance;
    return instance;
}

// ----------------------------------------------------------------------------------------------------- answering --
void log(int level, const std::string& message) {
    const Backend& b = backend();
    if (b.api && b.api->log) b.api->log(b.api, level, message.c_str());
}

void warn_once(const std::string& key, const std::string& message) {
    if (backend().warned.insert(key).second) log(2, message);
}

void resolve(FaRequest* request, const Json& result) {
    const Backend& b = backend();
    b.api->resolve(request, result.dump().c_str());
}

void reject(FaRequest* request, const char* code, const std::string& message, const std::string& hint) {
    const Backend& b = backend();
    b.api->reject(request, code, message.c_str(), hint.empty() ? nullptr : hint.c_str());
}

void emit(const char* event, const Json& data) {
    const Backend& b = backend();
    b.api->emit(b.api, event, data.dump().c_str());
}

// --------------------------------------------------------------------------------------------------- call results --
void wait_for(FaRequest* request, u64 call, int callback, ResultHandler handler) {
    if (call == 0) {  // k_uAPICallInvalid
        reject(request, "failed", "Steam refused to start the request",
               "Steam is not ready (the player may be offline, or Steam is shutting down). Try again in a moment.");
        return;
    }
    backend().calls[call] = {callback, std::move(handler)};
}

void with_stats(FaRequest* request, std::function<void()> run) {
    Backend& b = backend();
    if (b.stats == Backend::Stats::Ready) {
        run();
        return;
    }
    b.heldForStats.push_back({request, std::move(run)});
    if (b.stats == Backend::Stats::Idle) {  // SDK 1.60 and older: ask for the stats (again)
        b.stats = Backend::Stats::Loading;
        b.steam.SteamAPI_ISteamUserStats_RequestCurrentStats(b.steam.userStats);
    }
}

bool store_stats(FaRequest* request) {
    Backend& b = backend();
    b.statsDirty = false;
    if (b.steam.SteamAPI_ISteamUserStats_StoreStats(b.steam.userStats)) return true;
    reject(request, "network", "Steam did not accept the stats: the player is offline, or the stats were not loaded yet",
           "The change is kept in this session and Steam sends it with the next successful store. Offer a retry later.");
    return false;
}

void flush_stats() {
    Backend& b = backend();
    if (!b.statsDirty || b.stats != Backend::Stats::Ready) return;
    b.statsDirty = false;
    if (!b.steam.SteamAPI_ISteamUserStats_StoreStats(b.steam.userStats))
        warn_once("storestats", "Steam did not accept StoreStats: the player is offline, or the stats were not loaded. The stats stay "
                                "in this session and are sent with the next store.");
}

// -------------------------------------------------------------------------------------------------- the callbacks --
namespace {

template <class T>
bool read(const std::vector<std::uint8_t>& data, T& out) {
    if (data.size() < sizeof(T)) return false;
    std::memcpy(&out, data.data(), sizeof out);
    return true;
}

}  // namespace

Json player_json() {
    Backend& b = backend();
    Json out = Json::object();
    out.set("id", std::to_string(b.selfId));
    const char* name = b.steam.SteamAPI_ISteamFriends_GetPersonaName(b.steam.friends);
    out.set("name", name ? name : "");
    out.set("signedIn", b.steam.SteamAPI_ISteamUser_BLoggedOn(b.steam.user));
    return out;
}

namespace {

void stats_received(const UserStatsReceived& r) {
    Backend& b = backend();
    if (r.steamId != b.selfId) return;  // stats of another player (not requested by this plugin)
    std::vector<Backend::Held> held;
    held.swap(b.heldForStats);
    if (r.result == kResultOk) {
        b.stats = Backend::Stats::Ready;
        for (Backend::Held& h : held) h.run();
        return;
    }
    b.stats = Backend::Stats::Idle;  // the next request asks again
    for (const Backend::Held& h : held)
        reject(h.request, "network", "Steam could not load the player's stats (EResult " + std::to_string(r.result) + ")",
               "Check that Steam is online and that the game has stats and achievements configured in the Steamworks partner site.");
}

void stats_stored(const UserStatsStored& r) {
    if (r.result == kResultOk) return;
    if (r.result == kResultInvalidParam)
        warn_once("statsinvalid", "Steam rejected some of the stats that were stored (they broke a constraint of the stat in the "
                                  "Steamworks partner site, e.g. a maximum change) and sent its own values back: read them again "
                                  "with platform.stats.get.");
    else
        warn_once("statsstored", "Steam could not store the stats (EResult " + std::to_string(r.result) +
                                     "): they stay in this session and are sent with the next successful store.");
}

void dispatch(int id, const std::vector<std::uint8_t>& data) {
    Backend& b = backend();
    SteamApi& s = b.steam;
    switch (id) {
        case kSteamAPICallCompleted: {
            SteamAPICallCompleted done;
            if (!read(data, done)) return;
            auto it = b.calls.find(done.asyncCall);
            // Fetch the result even when nobody waits for it: Steam keeps it until it is fetched.
            std::vector<std::uint8_t> result(std::max<u32>(done.paramSize, 1));
            bool failed = false;
            const bool got = s.SteamAPI_ManualDispatch_GetAPICallResult(s.pipe, done.asyncCall, result.data(), static_cast<int>(done.paramSize),
                                                                        done.callback, &failed);
            if (it == b.calls.end()) return;  // an answer for a call this plugin did not make: harmless
            ResultHandler handler = std::move(it->second.handler);
            const int expected = it->second.callback;
            b.calls.erase(it);
            if (got && !failed && done.callback != expected) {
                warn_once("callbackid", "Steam answered a call with the result " + std::to_string(done.callback) + " but " +
                                            std::to_string(expected) + " was expected: the Steam library does not match this plugin");
                handler(result.data(), 0, true);
                return;
            }
            handler(result.data(), static_cast<int>(done.paramSize), !got || failed);
            return;
        }
        case kGamepadTextInputDismissed: {
            GamepadTextInputDismissed r;
            if (read(data, r)) text_input_dismissed(r);
            return;
        }
        case kFloatingGamepadTextInputDismissed:
            floating_text_input_dismissed();
            return;
        case kGameOverlayActivated: {
            GameOverlayActivated a;
            if (!read(data, a)) return;
            emit("overlay", Json::object().set("open", a.active != 0));
            return;
        }
        case kDlcInstalled: {
            DlcInstalled d;
            if (!read(data, d)) return;
            const std::string app = std::to_string(d.appId);
            // The engine turns the DLC's app id (the product's ids.steam) into the catalog's product id.
            emit("purchase", Json::object()
                                 .set("status", "purchased")
                                 .set("productId", app)
                                 .set("transactionId", "dlc-" + app)
                                 .set("receipt", ""));
            return;
        }
        case kSteamServersConnected:
        case kSteamServersDisconnected: {
            Json player = player_json();
            if (id == kSteamServersDisconnected) player.set("signedIn", false);
            emit("player", player);
            return;
        }
        case kUserStatsReceived: {
            UserStatsReceived r;
            if (read(data, r)) stats_received(r);
            return;
        }
        case kUserStatsStored: {
            UserStatsStored r;
            if (read(data, r)) stats_stored(r);
            return;
        }
        default: return;  // a callback this plugin does not use
    }
}

}  // namespace

void run_frame() {
    Backend& b = backend();
    SteamApi& s = b.steam;
    s.SteamAPI_ManualDispatch_RunFrame(s.pipe);
    CallbackMsg message{};
    for (int guard = 0; guard < 100000 && s.SteamAPI_ManualDispatch_GetNextCallback(s.pipe, &message); ++guard) {
        // Copy the payload and release the callback before running anything: a handler may start new Steam calls.
        std::vector<std::uint8_t> data;
        if (message.param && message.paramSize > 0) data.assign(message.param, message.param + message.paramSize);
        const int id = message.callback;
        s.SteamAPI_ManualDispatch_FreeLastCallback(s.pipe);
        try {
            dispatch(id, data);
        } catch (const std::exception& e) {
            log(3, std::string("a Steam callback (") + std::to_string(id) + ") failed: " + e.what());
        } catch (...) {
            log(3, "a Steam callback (" + std::to_string(id) + ") failed");
        }
    }
    flush_stats();
}

// --------------------------------------------------------------------------------------------------------- helpers --
std::string app_text() { return "app " + std::to_string(backend().appId); }

std::string quoted(const std::string& s) { return "\"" + s + "\""; }

bool parse_app_id(const std::string& text, u32& id) {
    if (text.empty() || text.size() > 10) return false;
    u64 value = 0;
    for (char c : text) {
        if (c < '0' || c > '9') return false;
        value = value * 10 + static_cast<u64>(c - '0');
    }
    if (value == 0 || value > 0xFFFFFFFFull) return false;
    id = static_cast<u32>(value);
    return true;
}

std::string display_name(u64 steamId) {
    Backend& b = backend();
    const char* name = b.steam.SteamAPI_ISteamFriends_GetFriendPersonaName(b.steam.friends, steamId);
    return name ? name : "";
}

// ------------------------------------------------------------------------------------------------------- routing --
void handle_request(FaRequest* request, const char* method, const char* argsJson) {
    const std::string name = method ? method : "";
    try {
        Json args;
        std::string error;
        if (!Json::parse(argsJson ? argsJson : "{}", args, error)) {
            reject(request, "failed", "the arguments of " + name + " are not JSON (" + error + ")",
                   "This is an engine bug; report it with `factoria call feedback.add`.");
            return;
        }
        for (const auto* table : {&player_and_stats_methods(), &store_methods()}) {
            auto it = table->find(name);
            if (it != table->end()) {
                it->second(request, args);
                return;
            }
        }
        reject(request, "unavailable", "the Steam backend does not implement " + name,
               "Check platform.has(service) first; docs/PLATFORM.md lists what Steam offers.");
    } catch (const std::exception& e) {
        reject(request, "failed", std::string("the Steam plugin failed while handling ") + name + ": " + e.what());
    } catch (...) {
        reject(request, "failed", std::string("the Steam plugin failed while handling ") + name);
    }
}

}  // namespace steam_plugin
