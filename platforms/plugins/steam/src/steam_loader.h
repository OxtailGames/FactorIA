// Loading the Steamworks redistributable at run time and starting Steam: the plugin calls the flat C API through the
// function pointers of SteamApi, so it needs no SDK to build.
#pragma once

#include <string>
#include <vector>

#include "steam_functions.h"
#include "steam_types.h"

namespace steam_plugin {

struct SteamApi {
#define STEAM_DECLARE(name, ret, params) ret(*name) params = nullptr;
    STEAM_REQUIRED_FUNCTIONS(STEAM_DECLARE)
    STEAM_OPTIONAL_FUNCTIONS(STEAM_DECLARE)
#undef STEAM_DECLARE

    // The interfaces of the current user (valid once start_steam succeeded).
    void* user = nullptr;
    void* friends = nullptr;
    void* utils = nullptr;
    void* apps = nullptr;
    void* userStats = nullptr;
    void* remoteStorage = nullptr;
    void* remotePlay = nullptr;  // null when the library has no ISteamRemotePlay: the remotePlay service is then off

    void* module = nullptr;     // the library's handle (dlopen, LoadLibrary)
    i32 pipe = 0;               // the HSteamPipe of manual dispatch
    std::string library;        // the file that was loaded
    std::string accessors;      // the interface versions in use: "ISteamUserStats v013, ..."
    std::vector<std::string> newerInterfaces;  // those newer than the SDKs the plugin was checked against: "ISteamUtils v011"
    std::string appIdSource;    // where the app id came from: "the SteamAppId variable", "steam_appid.txt in <folder>", ""
    bool needsStatsRequest = false;  // SDK 1.60 and older: stats arrive after RequestCurrentStats
};

// Opens the library (next to this plugin first, then the system's search path) and looks the functions up. False with a
// teaching message in `error`: where to get the library, which versions work.
bool load_library(SteamApi& api, std::string& error);

// Initialises Steam (SteamAPI_InitFlat, or SteamAPI_Init on old libraries), switches to manual callback dispatch and
// looks the interfaces up. False with a teaching message in `error`.
bool start_steam(SteamApi& api, std::string& error);

// The warning for interfaces newer than the SDKs the plugin was checked against ("" when there are none).
std::string newer_interfaces_warning(const SteamApi& api);

// The text of an error for the cases the SDK reports without saying what to do.
std::string how_to_start_steam();

}  // namespace steam_plugin
