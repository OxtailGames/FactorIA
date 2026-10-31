// Remote Play Together: the friends who joined the game through Steam and play on their own device (ISteamRemotePlay).
// Steam announces a guest with SteamRemotePlaySessionConnected_t and SteamRemotePlaySessionDisconnected_t, which carry only
// the session id; the session's description is read from the interface while it is connected and kept, since it can no
// longer be read once the guest left. The guest's input is not handled here: Steam shows the guest's controller to the
// game as one more gamepad.
#include "backend.h"

namespace steam_plugin {

namespace {

// ESteamDeviceFormFactor.
const char* form_factor_name(int value) {
    switch (value) {
        case 1: return "phone";
        case 2: return "tablet";
        case 3: return "computer";
        case 4: return "tv";
        case 5: return "vr";
        default: return "unknown";
    }
}

void handle_sessions(FaRequest* r, const Json&) {
    Backend& b = backend();
    SteamApi& s = steam();
    Json out = Json::array();
    const u32 count = s.SteamAPI_ISteamRemotePlay_GetSessionCount(s.remotePlay);
    std::map<u32, Json> now;
    for (u32 i = 0; i < count; ++i) {
        const u32 id = s.SteamAPI_ISteamRemotePlay_GetSessionID(s.remotePlay, static_cast<int>(i));
        if (id == 0) continue;  // k_unSessionIDInvalid
        Json session = remote_play_session(id);
        now[id] = session;
        out.push(std::move(session));
    }
    b.remoteSessions = std::move(now);  // what Steam says now is the truth: it also forgets guests that left unnoticed
    resolve(r, out);
}

}  // namespace

Json remote_play_session(u32 id) {
    SteamApi& s = steam();
    Json out = Json::object();
    out.set("id", id);
    const u64 steamId = s.SteamAPI_ISteamRemotePlay_GetSessionSteamID(s.remotePlay, id);
    out.set("guestName", steamId ? display_name(steamId) : std::string());
    out.set("guestId", steamId ? std::to_string(steamId) : std::string());
    const char* device = s.SteamAPI_ISteamRemotePlay_GetSessionClientName(s.remotePlay, id);
    out.set("deviceName", device ? device : "");
    out.set("formFactor", form_factor_name(s.SteamAPI_ISteamRemotePlay_GetSessionClientFormFactor(s.remotePlay, id)));
    int width = 0, height = 0;
    if (s.SteamAPI_ISteamRemotePlay_BGetSessionClientResolution(s.remotePlay, id, &width, &height) && width > 0 && height > 0)
        out.set("resolution", Json::object().set("width", width).set("height", height));
    else
        out.set("resolution", Json());
    return out;
}

void remote_play_connected(u32 id) {
    Backend& b = backend();
    if (!b.steam.remotePlay) return;
    Json session = remote_play_session(id);
    b.remoteSessions[id] = session;
    emit("remotePlay", Json::object().set("status", "connected").set("session", session));
}

void remote_play_disconnected(u32 id) {
    Backend& b = backend();
    if (!b.steam.remotePlay) return;
    auto known = b.remoteSessions.find(id);
    // A guest that joined before the plugin looked has no description kept; Steam no longer has one to give, so the event
    // says only who left.
    Json session = known != b.remoteSessions.end() ? known->second : Json::object().set("id", id);
    if (known != b.remoteSessions.end()) b.remoteSessions.erase(known);
    emit("remotePlay", Json::object().set("status", "disconnected").set("session", session));
}

void remember_remote_play_sessions() {
    Backend& b = backend();
    SteamApi& s = b.steam;
    if (!s.remotePlay) return;
    const u32 count = s.SteamAPI_ISteamRemotePlay_GetSessionCount(s.remotePlay);
    for (u32 i = 0; i < count; ++i) {
        const u32 id = s.SteamAPI_ISteamRemotePlay_GetSessionID(s.remotePlay, static_cast<int>(i));
        if (id != 0) b.remoteSessions[id] = remote_play_session(id);
    }
}

const std::map<std::string, Handler>& remote_play_methods() {
    static const std::map<std::string, Handler> methods = {
        {"remotePlay.sessions", handle_sessions},
    };
    return methods;
}

}  // namespace steam_plugin
