// The Steamworks "flat" C API functions this plugin calls, declared here by the plugin itself: no Valve header or library
// is part of this repository. steam_loader.cpp looks each one up by name in the Steamworks redistributable at run time
// (steam_api64.dll, libsteam_api.dylib, libsteam_api.so), so the plugin builds anywhere with no SDK. The signatures follow
// steam_api_flat.h of the Steamworks SDK 1.58 to 1.64; `void*` stands for the ISteam* interface pointers, `u64` for
// SteamAPICall_t, SteamLeaderboard_t and CSteamID, `u32` for AppId_t, and the enums are plain ints.
//
// Used as an X-macro: X(name, return type, (parameters)). The test mock (tests/mock_steam_api.cpp) defines every function of
// the lists below, and the compiler checks that its signatures match.
#pragma once

#include <cstdint>

namespace steam_plugin {

using u32 = std::uint32_t;
using u64 = std::uint64_t;
using i32 = std::int32_t;

struct CallbackMsg;  // steam_types.h

// Functions every supported SDK exports. Missing one = this is not a Steamworks library the plugin can use.
#define STEAM_REQUIRED_FUNCTIONS(X)                                                                                         \
    X(SteamAPI_Shutdown, void, ())                                                                                          \
    X(SteamAPI_GetHSteamPipe, i32, ())                                                                                      \
    X(SteamAPI_ManualDispatch_Init, void, ())                                                                               \
    X(SteamAPI_ManualDispatch_RunFrame, void, (i32))                                                                        \
    X(SteamAPI_ManualDispatch_GetNextCallback, bool, (i32, CallbackMsg*))                                                   \
    X(SteamAPI_ManualDispatch_FreeLastCallback, void, (i32))                                                                \
    X(SteamAPI_ManualDispatch_GetAPICallResult, bool, (i32, u64, void*, int, int, bool*))                                   \
    /* ISteamUser */                                                                                                        \
    X(SteamAPI_ISteamUser_BLoggedOn, bool, (void*))                                                                         \
    X(SteamAPI_ISteamUser_GetSteamID, u64, (void*))                                                                         \
    /* ISteamFriends */                                                                                                     \
    X(SteamAPI_ISteamFriends_GetPersonaName, const char*, (void*))                                                          \
    X(SteamAPI_ISteamFriends_GetFriendPersonaName, const char*, (void*, u64))                                               \
    X(SteamAPI_ISteamFriends_ActivateGameOverlay, void, (void*, const char*))                                               \
    X(SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage, void, (void*, const char*, int))                                 \
    X(SteamAPI_ISteamFriends_ActivateGameOverlayToStore, void, (void*, u32, int))                                           \
    X(SteamAPI_ISteamFriends_SetRichPresence, bool, (void*, const char*, const char*))                                      \
    X(SteamAPI_ISteamFriends_ClearRichPresence, void, (void*))                                                              \
    /* ISteamUtils */                                                                                                       \
    X(SteamAPI_ISteamUtils_GetAppID, u32, (void*))                                                                          \
    X(SteamAPI_ISteamUtils_IsOverlayEnabled, bool, (void*))                                                                 \
    /* ISteamApps */                                                                                                        \
    X(SteamAPI_ISteamApps_BIsDlcInstalled, bool, (void*, u32))                                                              \
    X(SteamAPI_ISteamApps_GetDLCCount, int, (void*))                                                                        \
    X(SteamAPI_ISteamApps_BGetDLCDataByIndex, bool, (void*, int, u32*, bool*, char*, int))                                  \
    /* ISteamUserStats */                                                                                                   \
    X(SteamAPI_ISteamUserStats_GetStatInt32, bool, (void*, const char*, i32*))                                              \
    X(SteamAPI_ISteamUserStats_GetStatFloat, bool, (void*, const char*, float*))                                            \
    X(SteamAPI_ISteamUserStats_SetStatInt32, bool, (void*, const char*, i32))                                               \
    X(SteamAPI_ISteamUserStats_SetStatFloat, bool, (void*, const char*, float))                                             \
    X(SteamAPI_ISteamUserStats_GetAchievement, bool, (void*, const char*, bool*))                                           \
    X(SteamAPI_ISteamUserStats_SetAchievement, bool, (void*, const char*))                                                  \
    X(SteamAPI_ISteamUserStats_StoreStats, bool, (void*))                                                                   \
    X(SteamAPI_ISteamUserStats_IndicateAchievementProgress, bool, (void*, const char*, u32, u32))                           \
    X(SteamAPI_ISteamUserStats_ResetAllStats, bool, (void*, bool))                                                          \
    X(SteamAPI_ISteamUserStats_FindOrCreateLeaderboard, u64, (void*, const char*, int, int))                                \
    X(SteamAPI_ISteamUserStats_DownloadLeaderboardEntries, u64, (void*, u64, int, int, int))                                \
    X(SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry, bool, (void*, u64, int, void*, i32*, int))                    \
    X(SteamAPI_ISteamUserStats_UploadLeaderboardScore, u64, (void*, u64, int, i32, const i32*, int))                        \
    /* ISteamRemoteStorage */                                                                                               \
    X(SteamAPI_ISteamRemoteStorage_FileWrite, bool, (void*, const char*, const void*, i32))                                 \
    X(SteamAPI_ISteamRemoteStorage_FileRead, i32, (void*, const char*, void*, i32))                                         \
    X(SteamAPI_ISteamRemoteStorage_GetFileSize, i32, (void*, const char*))                                                  \
    X(SteamAPI_ISteamRemoteStorage_FileExists, bool, (void*, const char*))                                                  \
    X(SteamAPI_ISteamRemoteStorage_FileDelete, bool, (void*, const char*))                                                  \
    X(SteamAPI_ISteamRemoteStorage_GetFileCount, i32, (void*))                                                              \
    X(SteamAPI_ISteamRemoteStorage_GetFileNameAndSize, const char*, (void*, int, i32*))                                     \
    X(SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount, bool, (void*))                                                 \
    X(SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp, bool, (void*))

// Functions only some SDKs export; the plugin works without them (a null pointer in the table).
//   SteamAPI_InitFlat                 SDK 1.58 and newer. Older libraries export SteamAPI_Init instead.
//   SteamAPI_Init                     the old bool init, used when InitFlat is missing.
//   SteamAPI_IsSteamRunning           only used to word the error when Steam did not start.
//   ISteamUserStats_RequestCurrentStats  SDK 1.60 and older need it before stats work; newer ones sync stats at init.
#define STEAM_OPTIONAL_FUNCTIONS(X)                                                                                         \
    X(SteamAPI_InitFlat, int, (char*))                                                                                      \
    X(SteamAPI_Init, bool, ())                                                                                              \
    X(SteamAPI_IsSteamRunning, bool, ())                                                                                    \
    X(SteamAPI_ISteamUserStats_RequestCurrentStats, bool, (void*))

// The interface accessors of the SDK versions the plugin supports, newest first. Each interface is looked up under its
// candidates in order; the first the library exports wins. Verified against the headers of SDK 1.58a, 1.59, 1.60, 1.62 and
// 1.64. A library that exports none of the candidates of an interface is a Steamworks version this plugin does not know.
#define STEAM_ACCESSORS(X)                                                                                                  \
    X(user, "ISteamUser", "SteamAPI_SteamUser_v023")                                                                        \
    X(friends, "ISteamFriends", "SteamAPI_SteamFriends_v018", "SteamAPI_SteamFriends_v017")                                 \
    X(utils, "ISteamUtils", "SteamAPI_SteamUtils_v010")                                                                     \
    X(apps, "ISteamApps", "SteamAPI_SteamApps_v009", "SteamAPI_SteamApps_v008")                                             \
    X(userStats, "ISteamUserStats", "SteamAPI_SteamUserStats_v013", "SteamAPI_SteamUserStats_v012")                         \
    X(remoteStorage, "ISteamRemoteStorage", "SteamAPI_SteamRemoteStorage_v016")

// The Steamworks SDK versions whose flat API this plugin was checked against (the text of the errors).
inline constexpr const char* kSupportedSdk = "Steamworks SDK 1.58 to 1.64";

}  // namespace steam_plugin
