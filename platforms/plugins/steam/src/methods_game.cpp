// The Steam methods about the player and the game's own data: sign-in, achievements, stats, leaderboards and cloud saves
// (docs/PLATFORM.md lists every method with its arguments and result).
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>

#include "backend.h"

namespace steam_plugin {

namespace {

const double kInt32Min = -2147483648.0;
const double kInt32Max = 2147483647.0;

// A float as Steam holds it, written the short way (0.1, not 0.10000000149).
double short_float(float f) {
    char buffer[32];
    std::snprintf(buffer, sizeof buffer, "%.7g", static_cast<double>(f));
    return std::strtod(buffer, nullptr);
}

struct IdPair {
    std::string id, storeId;
};

std::vector<IdPair> id_pairs(const Json& args, const char* key) {
    std::vector<IdPair> out;
    if (const Json* list = args.find(key); list && list->is_array())
        for (const Json& e : list->items()) out.push_back({e.string_or("id"), e.string_or("storeId", e.string_or("id"))});
    return out;
}

// ------------------------------------------------------------------------------------------------------- sign in --
void player_sign_in(FaRequest* r, const Json&) { resolve(r, player_json()); }

// ----------------------------------------------------------------------------------------------------- achievements --
void unknown_achievement(FaRequest* r, const std::string& id, const std::string& name) {
    reject(r, "unknownId", "Steam has no achievement " + quoted(name) + " for " + app_text() + " (the catalog id is " + quoted(id) + ")",
           "Set ids.steam of the achievement in factoria.json platform.achievements to its API name from the Steamworks partner "
           "site (App Admin > Stats & Achievements), and publish the stats and achievements there. Valve's test app 480 has "
           "ACH_WIN_ONE_GAME.");
}

// Sets the achievement and stores it. False after rejecting `r`.
bool unlock_now(FaRequest* r, const std::string& id, const std::string& name) {
    SteamApi& s = steam();
    if (!s.SteamAPI_ISteamUserStats_SetAchievement(s.userStats, name.c_str())) {
        reject(r, "failed", "Steam refused to unlock the achievement " + quoted(name) + " (the catalog id is " + quoted(id) + ")",
               "Steam only unlocks achievements while it is online and the player's stats are loaded.");
        return false;
    }
    return store_stats(r);
}

void achievements_unlock(FaRequest* r, const Json& a) {
    const std::string id = a.string_or("id"), name = a.string_or("storeId", id);
    with_stats(r, [=] {
        SteamApi& s = steam();
        bool achieved = false;
        if (!s.SteamAPI_ISteamUserStats_GetAchievement(s.userStats, name.c_str(), &achieved)) return unknown_achievement(r, id, name);
        if (!achieved && !unlock_now(r, id, name)) return;
        resolve(r, Json::object().set("id", id).set("unlocked", true).set("newly", !achieved));
    });
}

void achievements_progress(FaRequest* r, const Json& a) {
    const std::string id = a.string_or("id"), name = a.string_or("storeId", id);
    const double progress = std::min(1.0, std::max(0.0, a.number_or("progress", 0)));
    with_stats(r, [=] {
        SteamApi& s = steam();
        bool achieved = false;
        if (!s.SteamAPI_ISteamUserStats_GetAchievement(s.userStats, name.c_str(), &achieved)) return unknown_achievement(r, id, name);
        if (!achieved && progress >= 1.0) {
            if (!unlock_now(r, id, name)) return;
            achieved = true;
        } else if (!achieved && progress > 0.0) {
            // A notification "n of 100"; Steam keeps the progress in the stat behind the achievement, not here.
            const u32 current = static_cast<u32>(std::min(99.0, std::max(1.0, std::floor(progress * 100.0 + 0.5))));
            s.SteamAPI_ISteamUserStats_IndicateAchievementProgress(s.userStats, name.c_str(), current, 100);
        }
        resolve(r, Json::object().set("id", id).set("progress", achieved ? 1.0 : progress).set("unlocked", achieved));
    });
}

void achievements_list(FaRequest* r, const Json& a) {
    const std::vector<IdPair> items = id_pairs(a, "achievements");
    with_stats(r, [=] {
        SteamApi& s = steam();
        Json out = Json::array();
        for (const IdPair& item : items) {
            bool achieved = false;
            if (!s.SteamAPI_ISteamUserStats_GetAchievement(s.userStats, item.storeId.c_str(), &achieved))
                warn_once("achievement:" + item.storeId,
                          "Steam has no achievement " + quoted(item.storeId) + " for " + app_text() + ": platform.achievements.list() shows "
                          "it locked. Set ids.steam of " + quoted(item.id) + " to its API name from the Steamworks partner site.");
            out.push(Json::object().set("id", item.id).set("unlocked", achieved).set("progress", achieved ? 1.0 : 0.0));
        }
        resolve(r, out);
    });
}

void achievements_reset(FaRequest* r, const Json&) {
    with_stats(r, [=] {
        SteamApi& s = steam();
        if (!s.SteamAPI_ISteamUserStats_ResetAllStats(s.userStats, true)) {
            reject(r, "failed", "Steam refused to reset the stats and achievements",
                   "Only works while Steam is online and the stats are loaded; it is meant for development.");
            return;
        }
        if (store_stats(r)) resolve(r, Json::object());
    });
}

// ------------------------------------------------------------------------------------------------------------ stats --
void unknown_stat(FaRequest* r, const std::string& id, const std::string& name, const std::string& type) {
    reject(r, "unknownId", "Steam has no " + type + " stat " + quoted(name) + " for " + app_text() + " (the catalog id is " + quoted(id) + ")",
           "Set ids.steam of the stat in factoria.json platform.stats to its API name from the Steamworks partner site (App Admin > "
           "Stats & Achievements), and make sure its type there (int or float) is the \"type\" of the catalog. Valve's test app 480 has "
           "the int stat NumWins.");
}

// The value Steam holds now; false after rejecting `r`.
bool read_stat(FaRequest* r, const std::string& id, const std::string& name, const std::string& type, Json& value) {
    SteamApi& s = steam();
    if (type == "float") {
        float f = 0;
        if (!s.SteamAPI_ISteamUserStats_GetStatFloat(s.userStats, name.c_str(), &f)) return unknown_stat(r, id, name, type), false;
        value = Json(short_float(f));
    } else {
        i32 n = 0;
        if (!s.SteamAPI_ISteamUserStats_GetStatInt32(s.userStats, name.c_str(), &n)) return unknown_stat(r, id, name, type), false;
        value = Json(n);
    }
    return true;
}

void stats_get(FaRequest* r, const Json& a) {
    const std::string id = a.string_or("id"), name = a.string_or("storeId", id), type = a.string_or("type", "int");
    with_stats(r, [=] {
        Json value;
        if (read_stat(r, id, name, type, value)) resolve(r, Json::object().set("id", id).set("value", value));
    });
}

void stats_set(FaRequest* r, const Json& a) {
    const std::string id = a.string_or("id"), name = a.string_or("storeId", id), type = a.string_or("type", "int");
    const double wanted = a.number_or("value", 0);
    with_stats(r, [=] {
        SteamApi& s = steam();
        bool ok = false;
        if (type == "float") {
            ok = s.SteamAPI_ISteamUserStats_SetStatFloat(s.userStats, name.c_str(), static_cast<float>(wanted));
        } else {
            if (wanted < kInt32Min || wanted > kInt32Max) {
                reject(r, "failed", "the value " + std::to_string(static_cast<long long>(wanted)) + " does not fit the stat " + quoted(id) +
                                        ": Steam int stats are 32-bit whole numbers",
                       "Use a value from -2147483648 to 2147483647, or declare the stat as \"float\" in factoria.json platform.stats.");
                return;
            }
            ok = s.SteamAPI_ISteamUserStats_SetStatInt32(s.userStats, name.c_str(), static_cast<i32>(wanted));
        }
        if (!ok) return unknown_stat(r, id, name, type);
        // Stored by the next frame: several sets in one frame cost one StoreStats (Steam limits how often it may be called).
        backend().statsDirty = true;
        Json value;
        if (read_stat(r, id, name, type, value)) resolve(r, Json::object().set("id", id).set("value", value));
    });
}

// -------------------------------------------------------------------------------------------------------- leaderboards --
void unknown_leaderboard(FaRequest* r, const std::string& id, const std::string& name) {
    reject(r, "unknownId", "Steam has no leaderboard " + quoted(name) + " for " + app_text() + " and could not create it (the catalog id is " +
                               quoted(id) + ")",
           "Create the leaderboard in the Steamworks partner site (App Admin > Stats & Achievements > Leaderboards) and set ids.steam "
           "of the leaderboard in factoria.json platform.leaderboards to its name. Valve's test app 480 has \"Feet Traveled\".");
}

// Steam has no periods: a daily or weekly board is one Steam board per period, named "<store name> <periodKey>" ("Fastest
// 2026-10-23"). The key is the day, or the Monday of the week, in the game's calendar (the engine sends it).
std::string board_name(const std::string& name, const Json& a) {
    const std::string key = a.string_or("periodKey");
    return key.empty() ? name : name + " " + key;
}

// Boards of old periods are never read again and a handle is cheap to look up again, so the cache is emptied when it grows.
constexpr std::size_t kMaxCachedBoards = 64;

// Finds (or creates) the leaderboard and continues with its handle. The handle is cached: it is valid for the session.
void with_leaderboard(FaRequest* r, const std::string& id, const std::string& name, const std::string& order,
                      std::function<void(u64)> then) {
    Backend& b = backend();
    if (auto it = b.leaderboards.find(name); it != b.leaderboards.end()) return then(it->second);
    SteamApi& s = b.steam;
    // `order` only matters when Steam creates the board here: an existing board keeps its own sort.
    const u64 call = s.SteamAPI_ISteamUserStats_FindOrCreateLeaderboard(s.userStats, name.c_str(),
                                                                       order == "ascending" ? kSortAscending : kSortDescending, kDisplayNumeric);
    wait_for<LeaderboardFindResult>(r, call, [=](const LeaderboardFindResult& found) {
        if (!found.found || found.leaderboard == 0) return unknown_leaderboard(r, id, name);
        auto& cache = backend().leaderboards;
        if (cache.size() >= kMaxCachedBoards) cache.clear();
        cache[name] = found.leaderboard;
        then(found.leaderboard);
    });
}

void leaderboards_submit(FaRequest* r, const Json& a) {
    const std::string id = a.string_or("id"), name = board_name(a.string_or("storeId", id), a), order = a.string_or("order", "descending");
    const double score = a.number_or("score", 0);
    if (score < kInt32Min || score > kInt32Max) {
        reject(r, "failed", "the score " + std::to_string(static_cast<long long>(score)) + " does not fit a Steam leaderboard: scores are 32-bit whole numbers",
               "Submit a score from -2147483648 to 2147483647 (a time in milliseconds fits for 24 days).");
        return;
    }
    with_leaderboard(r, id, name, order, [=](u64 board) {
        SteamApi& s = steam();
        const u64 call = s.SteamAPI_ISteamUserStats_UploadLeaderboardScore(s.userStats, board, kUploadKeepBest, static_cast<i32>(score), nullptr, 0);
        wait_for<LeaderboardScoreUploaded>(r, call, [=](const LeaderboardScoreUploaded& up) {
            if (!up.success) {
                reject(r, "failed", "Steam did not accept the score for the leaderboard " + quoted(name),
                       "The player may be offline, or the leaderboard is read-only (set it to allow client uploads in the Steamworks partner site).");
                return;
            }
            const Json base = Json::object().set("id", id).set("score", up.score);
            if (up.scoreChanged) return resolve(r, Json(base).set("best", up.score));
            // Steam kept a better score the player had: read it back.
            SteamApi& s2 = steam();
            const u64 own = s2.SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(s2.userStats, board, kDataRequestGlobalAroundUser, 0, 0);
            wait_for<LeaderboardScoresDownloaded>(r, own, [=](const LeaderboardScoresDownloaded& d) {
                SteamApi& s3 = steam();
                i32 best = up.score;
                LeaderboardEntry entry{};
                if (d.count > 0 && s3.SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(s3.userStats, d.entries, 0, &entry, nullptr, 0) &&
                    entry.steamId == backend().selfId)
                    best = entry.score;
                resolve(r, Json(base).set("best", best));
            });
        });
    });
}

void leaderboards_entries(FaRequest* r, const Json& a) {
    const std::string id = a.string_or("id"), name = board_name(a.string_or("storeId", id), a), order = a.string_or("order", "descending");
    const std::string range = a.string_or("range", "top");
    const int count = static_cast<int>(std::min(100.0, std::max(1.0, a.number_or("count", 10))));
    with_leaderboard(r, id, name, order, [=](u64 board) {
        SteamApi& s = steam();
        int kind = kDataRequestGlobal, from = 1, to = count;
        if (range == "around") {  // the player in the middle: count entries from -count/2
            kind = kDataRequestGlobalAroundUser;
            from = -(count / 2);
            to = from + count - 1;
        } else if (range == "friends") {  // Steam returns all of the player's friends: no range
            kind = kDataRequestFriends;
            from = to = 0;
        }
        const u64 call = s.SteamAPI_ISteamUserStats_DownloadLeaderboardEntries(s.userStats, board, kind, from, to);
        wait_for<LeaderboardScoresDownloaded>(r, call, [=](const LeaderboardScoresDownloaded& d) {
            SteamApi& s2 = steam();
            Json out = Json::array();
            for (int i = 0; i < d.count && static_cast<int>(out.items().size()) < count; ++i) {
                LeaderboardEntry entry{};
                if (!s2.SteamAPI_ISteamUserStats_GetDownloadedLeaderboardEntry(s2.userStats, d.entries, i, &entry, nullptr, 0)) continue;
                std::string player = display_name(entry.steamId);
                if (player.empty() || player == "[unknown]") player = std::to_string(entry.steamId);
                out.push(Json::object()
                             .set("rank", entry.globalRank)
                             .set("name", player)
                             .set("score", entry.score)
                             .set("playerId", std::to_string(entry.steamId))
                             .set("isPlayer", entry.steamId == backend().selfId));
            }
            resolve(r, out);
        });
    });
}

// ----------------------------------------------------------------------------------------------------------- cloud --
// The files of Steam Cloud are `<key>.json`.
std::string cloud_file(const std::string& key) { return key + ".json"; }

bool cloud_enabled(FaRequest* r) {
    SteamApi& s = steam();
    if (!s.SteamAPI_ISteamRemoteStorage_IsCloudEnabledForAccount(s.remoteStorage)) {
        reject(r, "unavailable", "Steam Cloud is turned off for this Steam account",
               "In Steam: Settings > Cloud > Enable Steam Cloud synchronization. Games can keep saving locally with the storage module.");
        return false;
    }
    if (!s.SteamAPI_ISteamRemoteStorage_IsCloudEnabledForApp(s.remoteStorage)) {
        reject(r, "unavailable", "Steam Cloud is not enabled for " + app_text(),
               "Turn it on in the Steamworks partner site (App Admin > Cloud: a byte quota and a file count), publish the change, "
               "and make sure the player did not turn it off in the game's Properties. Valve's test app 480 may not have it.");
        return false;
    }
    return true;
}

void cloud_save(FaRequest* r, const Json& a) {
    if (!cloud_enabled(r)) return;
    SteamApi& s = steam();
    const std::string key = a.string_or("key"), data = a.string_or("data");
    if (data.size() > 100u * 1024u * 1024u) {
        reject(r, "failed", "the value of " + quoted(key) + " is " + std::to_string(data.size()) + " bytes: Steam Cloud files are limited to 100 MB",
               "Save less data, or split it over several keys.");
        return;
    }
    if (!s.SteamAPI_ISteamRemoteStorage_FileWrite(s.remoteStorage, cloud_file(key).c_str(), data.data(), static_cast<i32>(data.size()))) {
        reject(r, "failed", "Steam Cloud refused to write " + quoted(cloud_file(key)) + " (" + std::to_string(data.size()) + " bytes)",
               "The game's Steam Cloud quota (bytes or number of files, set in the Steamworks partner site) may be used up.");
        return;
    }
    resolve(r, Json::object().set("key", key).set("bytes", data.size()));
}

void cloud_load(FaRequest* r, const Json& a) {
    if (!cloud_enabled(r)) return;
    SteamApi& s = steam();
    const std::string key = a.string_or("key"), file = cloud_file(key);
    if (!s.SteamAPI_ISteamRemoteStorage_FileExists(s.remoteStorage, file.c_str())) return resolve(r, Json());  // no such key
    const i32 size = s.SteamAPI_ISteamRemoteStorage_GetFileSize(s.remoteStorage, file.c_str());
    std::string data(static_cast<std::size_t>(std::max<i32>(size, 0)), '\0');
    const i32 read = size > 0 ? s.SteamAPI_ISteamRemoteStorage_FileRead(s.remoteStorage, file.c_str(), &data[0], size) : 0;
    if (read != size) {
        reject(r, "failed", "Steam Cloud returned " + std::to_string(read) + " of the " + std::to_string(size) + " bytes of " + quoted(file),
               "The file may still be downloading; try again in a moment.");
        return;
    }
    resolve(r, Json::object().set("key", key).set("data", data));
}

void cloud_list(FaRequest* r, const Json&) {
    if (!cloud_enabled(r)) return;
    SteamApi& s = steam();
    std::vector<std::string> keys;
    const i32 count = s.SteamAPI_ISteamRemoteStorage_GetFileCount(s.remoteStorage);
    for (i32 i = 0; i < count; ++i) {
        i32 size = 0;
        const char* file = s.SteamAPI_ISteamRemoteStorage_GetFileNameAndSize(s.remoteStorage, i, &size);
        const std::string name = file ? file : "";
        if (name.size() > 5 && name.compare(name.size() - 5, 5, ".json") == 0) keys.push_back(name.substr(0, name.size() - 5));
    }
    std::sort(keys.begin(), keys.end());
    Json out = Json::array();
    for (const std::string& k : keys) out.push(k);
    resolve(r, out);
}

void cloud_remove(FaRequest* r, const Json& a) {
    if (!cloud_enabled(r)) return;
    SteamApi& s = steam();
    const std::string key = a.string_or("key"), file = cloud_file(key);
    if (s.SteamAPI_ISteamRemoteStorage_FileExists(s.remoteStorage, file.c_str()) &&
        !s.SteamAPI_ISteamRemoteStorage_FileDelete(s.remoteStorage, file.c_str())) {
        reject(r, "failed", "Steam Cloud refused to delete " + quoted(file), "Try again in a moment.");
        return;
    }
    resolve(r, Json::object());
}

}  // namespace

const std::map<std::string, Handler>& player_and_stats_methods() {
    static const std::map<std::string, Handler> methods = {
        {"player.signIn", player_sign_in},
        {"achievements.unlock", achievements_unlock},
        {"achievements.progress", achievements_progress},
        {"achievements.list", achievements_list},
        {"achievements.reset", achievements_reset},
        {"stats.get", stats_get},
        {"stats.set", stats_set},
        {"leaderboards.submit", leaderboards_submit},
        {"leaderboards.entries", leaderboards_entries},
        {"cloud.save", cloud_save},
        {"cloud.load", cloud_load},
        {"cloud.list", cloud_list},
        {"cloud.remove", cloud_remove},
    };
    return methods;
}

}  // namespace steam_plugin
