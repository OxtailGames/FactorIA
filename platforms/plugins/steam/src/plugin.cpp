/* The Steamworks backend of FactorIA's `platform` API (docs/PLATFORM.md, "Steam"): a native plugin (docs/EXTENDING.md,
 * "Native plugins") that registers the backend "steam" and answers the game's achievements, stats, leaderboards, cloud saves,
 * purchases (DLC), overlay and rich presence requests with the Steamworks flat C API.
 *
 * It contains no code or header of Valve's: steam_loader.cpp loads the Steamworks redistributable at run time (steam_api64.dll,
 * libsteam_api.dylib, libsteam_api.so), looked for next to this plugin first, and calls it through function pointers that
 * steam_functions.h declares. CMakeLists.txt passes the plugin's name as FA_PLUGIN_NAME and copies the build where the game
 * finds it. include/fa_plugin.h is the whole engine API.
 *
 *   plugin.cpp         the entry point, the exit, the command steam.status
 *   backend.cpp        answers, call results, the callback pump
 *   text_input.cpp     Steam's own keyboard on a Steam Deck or in Big Picture (plugin API 3)
 *   methods_game.cpp   sign-in, achievements, stats, leaderboards, cloud saves
 *   methods_store.cpp  purchases (DLC), overlay, rich presence
 */
#include <cstdlib>
#include <string>

#include "backend.h"

namespace steam_plugin {

namespace {

void on_request(FaRequest* request, const char* method, const char* argsJson, void*) { handle_request(request, method, argsJson); }

void on_frame(void*) {
    if (backend().started) run_frame();
}

// Process exit: Steam wants SteamAPI_Shutdown, and the stats set since the last frame are stored first.
// Not on Windows: a DLL's exit handlers run when the DLL is detached at process exit, after Steam's own DLL (loaded later)
// was detached, and calling into it then is undefined. Windows stores the stats every frame and Steam's client notices the
// process ending on its own.
void on_exit() {
#if !defined(_WIN32)
    Backend& b = backend();
    if (!b.started) return;
    b.started = false;
    if (b.statsDirty && b.stats == Backend::Stats::Ready) b.steam.SteamAPI_ISteamUserStats_StoreStats(b.steam.userStats);
    b.steam.SteamAPI_Shutdown();
#endif
}

// The command steam.status: what the plugin found, for a person or an AI checking the setup.
void status(FaCall* call, const char*, void*) {
    Backend& b = backend();
    SteamApi& s = b.steam;
    Json out = Json::object();
    out.set("plugin", b.api->plugin).set("backend", "steam").set("appId", b.appId).set("appIdFrom", s.appIdSource.empty() ? "Steam" : s.appIdSource);
    out.set("player", player_json());
    out.set("library", s.library).set("interfaces", s.accessors);
    Json newer = Json::array();  // interfaces of an SDK newer than the ones this plugin was checked against (kCheckedSdk)
    for (const std::string& n : s.newerInterfaces) newer.push(n);
    out.set("newerInterfaces", newer).set("checkedSdk", kCheckedSdk);
    out.set("overlayEnabled", s.SteamAPI_ISteamUtils_IsOverlayEnabled(s.utils));
    out.set("cloudEnabledForAccount", s.SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(s.remoteStorage));
    out.set("cloudEnabledForApp", s.SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(s.remoteStorage));
    out.set("statsLoaded", b.stats == Backend::Stats::Ready);
    out.set("dlc", s.SteamAPI_ISteamApps_GetDLCCount(s.apps));
    b.api->reply(call, out.dump().c_str());
}

}  // namespace

}  // namespace steam_plugin

FA_PLUGIN_INIT(FA_PLUGIN_NAME) {
    using namespace steam_plugin;
    Backend& b = backend();
    if (api->version < 2 || !api->add_backend) {
        const std::string old = "This FactorIA is too old for the Steam plugin: platform backends need plugin API version 2, and this "
                                "engine has version " + std::to_string(api->version) + ". Update FactorIA (`factoria` and the editor).";
        api->log(api, 3, old.c_str());
        return 1;
    }
    b.api = api;

    std::string error;
    if (!load_library(b.steam, error) || !start_steam(b.steam, error)) {
        // Not an error: the plugin is meant to be declared "optional", and a game runs without Steam (a build for a store
        // other than Steam, a computer without Valve's library). The engine logs the plugin as skipped, too.
        api->log(api, 2, error.c_str());
        return 1;
    }
    b.started = true;
    SteamApi& s = b.steam;
    b.selfId = s.SteamAPI_ISteamUser_GetSteamID(s.user);
    b.appId = s.SteamAPI_ISteamUtils_GetAppID(s.utils);
    if (s.needsStatsRequest) {  // SDK 1.60 and older load the stats on request; newer ones before the game starts
        b.stats = Backend::Stats::Loading;
        s.SteamAPI_ISteamUserStats_RequestCurrentStats(s.userStats);
    }

    const std::string commandName = std::string(api->plugin) + ".status";
    FaCommandDesc command = {commandName.c_str(),
                             "Show what the Steam plugin found: app id, player, library, overlay and cloud.",
                             "Returns {plugin, backend, appId, appIdFrom, player, library, interfaces, newerInterfaces (the "
                             "ones newer than the SDKs checkedSdk names: used, with a warning), checkedSdk, overlayEnabled, "
                             "cloudEnabledForAccount, cloudEnabledForApp, statsLoaded, dlc}. Example: {}.",
                             nullptr, 1, status, nullptr};
    FaBackendDesc desc = {"steam", "[\"achievements\",\"stats\",\"leaderboards\",\"cloudSave\",\"purchases\",\"overlay\",\"presence\"]",
                             on_request, on_frame, nullptr};
    // Plugin API 3: the Steam Deck's own keyboard for a TextField a gamepad player focuses (an older engine has no hook).
    const bool keyboardHook = api->version >= 3 && api->add_text_input && api->submit_text;
    if (api->add_command(api, &command) != 0 || api->add_backend(api, &desc) != 0 ||
        (keyboardHook && api->add_text_input(api, on_text_input, nullptr) != 0)) {
        s.SteamAPI_Shutdown();
        b.started = false;
        return 1;
    }
    // Plugin API 4: tell the engine whether this is a Steam Deck (game.device.steamDeck); an older engine has no such hook.
    if (api->version >= 4 && api->set_device_fact && s.SteamAPI_ISteamUtils_IsSteamRunningOnSteamDeck)
        api->set_device_fact(api, "steamDeck", s.SteamAPI_ISteamUtils_IsSteamRunningOnSteamDeck(s.utils) ? 1 : 0);
    std::atexit(on_exit);
    const std::string newer = newer_interfaces_warning(s);
    if (!newer.empty()) api->log(api, 2, newer.c_str());
    const std::string ready = "Steam is ready: app " + std::to_string(b.appId) + ", player " + std::to_string(b.selfId) + " (" + s.library +
                              ", " + s.accessors + (s.appIdSource.empty() ? "" : "; app id from " + s.appIdSource) + ")";
    api->log(api, 1, ready.c_str());
    return 0;
}
