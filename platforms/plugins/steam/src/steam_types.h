// The Steamworks types this plugin reads: the callback ids and the layout of the callback structures, declared by the
// plugin itself (no Valve header is part of this repository). Taken from the public Steamworks headers, SDK 1.58 to 1.64
// (isteamuserstats.h, isteamapps.h, isteamfriends.h, isteamuser.h, steam_api_internal.h).
//
// Packing: Steam packs its callback structures at 4 bytes on Linux and macOS and at 8 on Windows ("VALVE_CALLBACK_PACK_SMALL"
// and "_LARGE" in steamclientpublic.h). The structures below use the same, or the fields of the 64-bit ones land at the
// wrong offsets.
#pragma once

#include <cstdint>

#include "steam_functions.h"

namespace steam_plugin {

#if defined(__linux__) || defined(__APPLE__) || defined(__FreeBSD__)
#define STEAM_PLUGIN_PACK 4
#else
#define STEAM_PLUGIN_PACK 8
#endif
#pragma pack(push, STEAM_PLUGIN_PACK)

// Callback ids (the first number of each family plus the offset the header gives).
enum CallbackId : int {
    kSteamServersConnected = 101,
    kSteamServersDisconnected = 103,
    kGameOverlayActivated = 331,
    kSteamAPICallCompleted = 703,
    kDlcInstalled = 1005,
    kUserStatsReceived = 1101,
    kUserStatsStored = 1102,
    kUserAchievementStored = 1103,
    kLeaderboardFindResult = 1104,
    kLeaderboardScoresDownloaded = 1105,
    kLeaderboardScoreUploaded = 1106,
};

// EResult: only the values the plugin looks at.
enum : int { kResultOk = 1, kResultFail = 2, kResultNoConnection = 3, kResultInvalidParam = 8, kResultTimeout = 16 };

// ESteamAPIInitResult.
enum : int { kInitOk = 0, kInitFailedGeneric = 1, kInitNoSteamClient = 2, kInitVersionMismatch = 3 };

// Enums passed as plain ints.
enum : int { kDataRequestGlobal = 0, kDataRequestGlobalAroundUser = 1, kDataRequestFriends = 2 };
enum : int { kSortAscending = 1, kSortDescending = 2 };
enum : int { kDisplayNumeric = 1 };
enum : int { kUploadKeepBest = 1 };
enum : int { kOverlayToStoreNone = 0, kOverlayToStoreAddToCartAndShow = 2 };
enum : int { kWebPageDefault = 0 };

// What SteamAPI_ManualDispatch_GetNextCallback fills in.
struct CallbackMsg {
    i32 hSteamUser;
    i32 callback;
    std::uint8_t* param;
    i32 paramSize;
};

struct SteamAPICallCompleted {  // a call result is ready: fetch it with GetAPICallResult
    static constexpr int kCallback = kSteamAPICallCompleted;
    u64 asyncCall;
    i32 callback;  // the id of the call result's structure
    u32 paramSize;
};

struct GameOverlayActivated {
    static constexpr int kCallback = kGameOverlayActivated;
    std::uint8_t active;
    bool userInitiated;
    u32 appId;
    u32 overlayPid;
};

struct DlcInstalled {
    static constexpr int kCallback = kDlcInstalled;
    u32 appId;
};

struct SteamServersDisconnected {
    static constexpr int kCallback = kSteamServersDisconnected;
    i32 result;
};

struct UserStatsReceived {
    static constexpr int kCallback = kUserStatsReceived;
    u64 gameId;
    i32 result;
    u64 steamId;
};

struct UserStatsStored {
    static constexpr int kCallback = kUserStatsStored;
    u64 gameId;
    i32 result;
};

struct LeaderboardFindResult {
    static constexpr int kCallback = kLeaderboardFindResult;
    u64 leaderboard;
    std::uint8_t found;
};

struct LeaderboardScoresDownloaded {
    static constexpr int kCallback = kLeaderboardScoresDownloaded;
    u64 leaderboard;
    u64 entries;  // the handle for GetDownloadedLeaderboardEntry
    i32 count;
};

struct LeaderboardScoreUploaded {
    static constexpr int kCallback = kLeaderboardScoreUploaded;
    std::uint8_t success;
    u64 leaderboard;
    i32 score;
    std::uint8_t scoreChanged;
    i32 globalRankNew;
    i32 globalRankPrevious;
};

struct LeaderboardEntry {  // LeaderboardEntry_t
    u64 steamId;
    i32 globalRank;
    i32 score;
    i32 detailCount;
    u64 ugc;
};

#pragma pack(pop)

}  // namespace steam_plugin
