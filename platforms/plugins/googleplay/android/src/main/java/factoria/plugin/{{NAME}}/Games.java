package factoria.plugin.{{NAME}};

import android.app.Activity;

import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.games.AnnotatedData;
import com.google.android.gms.games.AchievementsClient;
import com.google.android.gms.games.GamesClientStatusCodes;
import com.google.android.gms.games.GamesSignInClient;
import com.google.android.gms.games.LeaderboardsClient;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.SnapshotsClient;
import com.google.android.gms.games.achievement.Achievement;
import com.google.android.gms.games.achievement.AchievementBuffer;
import com.google.android.gms.games.leaderboard.LeaderboardScore;
import com.google.android.gms.games.leaderboard.LeaderboardScoreBuffer;
import com.google.android.gms.games.leaderboard.LeaderboardVariant;
import com.google.android.gms.games.leaderboard.ScoreSubmissionData;
import com.google.android.gms.games.snapshot.Snapshot;
import com.google.android.gms.games.snapshot.SnapshotMetadata;
import com.google.android.gms.games.snapshot.SnapshotMetadataBuffer;
import com.google.android.gms.games.snapshot.SnapshotMetadataChange;
import com.google.android.gms.tasks.Task;

import org.json.JSONArray;
import org.json.JSONObject;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * Google Play Games Services v2: the player, achievements, leaderboards and cloud saves (Saved Games). Only called when the
 * project id of games-ids.xml is set. Everything here runs on the main thread.
 */
final class Games {
    private Games() {}

    private static final int PUBLIC = LeaderboardVariant.COLLECTION_PUBLIC;
    private static final int POLICY = SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED;
    /** Play Games answers at most this many leaderboard rows per call. */
    private static final int MAX_ROWS = 25;

    /** The last known player, {id, name, signedIn}; null until Play Games told. */
    static volatile JSONObject player;
    private static Request signingIn;

    private static Activity activity() { return Backend.activity; }

    private static String storeId(Request r) { return r.args.optString("storeId", r.args.optString("id")); }

    // ---------------------------------------------------------------------------------------------------- player ----
    /** Play Games signs the player in by itself when the app starts: tells the game who it is, if anyone. */
    static void refresh() {
        Activity a = activity();
        if (Errors.noPlayServices(a, "") != null) return;
        PlayGames.getGamesSignInClient(a).isAuthenticated().addOnSuccessListener(auth -> {
            if (auth.isAuthenticated()) PlayGames.getPlayersClient(a).getCurrentPlayer().addOnSuccessListener(p -> {
                JSONObject now = Json.obj("id", p.getPlayerId(), "name", p.getDisplayName(), "signedIn", true);
                if (!now.toString().equals(String.valueOf(player))) Backend.emit("player", now.toString());
                player = now;
            });
        });
    }

    /** The game's activity was paused while a sign-in is waiting: Google's prompt is up, so the player may take their time. */
    static void paused() {
        Request s = signingIn;
        if (s != null && !s.isAnswered()) s.beginInteraction();
    }

    static void signIn(Request r) {
        if (Backend.gamesId.isEmpty()) {
            r.resolve(Json.obj("id", "", "name", "", "signedIn", false));
            return;
        }
        Failure f = Errors.noPlayServices(activity(), r.doing());
        if (f != null) {
            r.reject(f);
            return;
        }
        GamesSignInClient client = PlayGames.getGamesSignInClient(activity());
        signingIn = r;
        r.await(client.isAuthenticated(), r.doing(), auth -> {
            if (auth.isAuthenticated()) who(r);
            else r.await(client.signIn(), r.doing(), again -> {
                if (again.isAuthenticated()) who(r);
                else r.reject(new Failure(Failure.NOT_SIGNED_IN, r.doing() + " failed: the player is not signed in to Google Play Games",
                        "The player closed or declined the sign-in. Ask again when they want the feature. While the Play Games project is unpublished, the "
                                + "Google account must be one of its testers (Play Console > Play Games Services > Setup and management > Testers)."));
            });
        });
    }

    private static void who(Request r) {
        r.await(PlayGames.getPlayersClient(activity()).getCurrentPlayer(), r.doing(), p -> {
            JSONObject now = Json.obj("id", p.getPlayerId(), "name", p.getDisplayName(), "signedIn", true);
            player = now;
            r.resolve(now);
        });
    }

    // --------------------------------------------------------------------------------------------- achievements ----
    /** Finds one achievement in what Play Games has; rejects with the ids it does have when it is not there. */
    private static void achievement(Request r, AchievementsClient c, String sid, Request.Step<Achievement> then) {
        r.await(c.load(false), r.doing(), data -> {
            AchievementBuffer buffer = data.get();
            Achievement found = null;
            StringBuilder known = new StringBuilder();
            try {
                for (int i = 0; buffer != null && i < buffer.getCount(); i++) {
                    Achievement a = buffer.get(i);
                    if (a.getAchievementId().equals(sid)) found = a.freeze();
                    if (i < 12) known.append(i == 0 ? "" : ", ").append(a.getAchievementId());
                }
            } finally {
                if (buffer != null) buffer.release();
            }
            if (found == null) {
                r.reject(new Failure(Failure.UNKNOWN_ID, r.doing() + " failed: Play Games has no achievement " + JSONObject.quote(sid)
                        + (known.length() == 0 ? " (it has none yet)" : " (it has: " + known + ")"),
                        "Create it in Play Console (Play Games Services > Setup and management > Achievements) and put the id Play generated (it starts with "
                                + "CgkI) in platform.achievements[].ids.googleplay in factoria.json."));
                return;
            }
            r.run(then, found);
        });
    }

    static void unlock(Request r) {
        String sid = storeId(r);
        AchievementsClient c = PlayGames.getAchievementsClient(activity());
        achievement(r, c, sid, a -> {
            if (a.getState() == Achievement.STATE_UNLOCKED) r.resolve(Json.obj("id", sid, "unlocked", true, "newly", false));
            else r.await(c.unlockImmediate(sid), r.doing(), done -> r.resolve(Json.obj("id", sid, "unlocked", true, "newly", true)));
        });
    }

    static void progress(Request r) {
        String sid = storeId(r);
        double fraction = Math.max(0, Math.min(1, r.args.optDouble("progress", 0)));
        AchievementsClient c = PlayGames.getAchievementsClient(activity());
        achievement(r, c, sid, a -> {
            if (fraction >= 1) {
                r.await(c.unlockImmediate(sid), r.doing(), done -> r.resolve(Json.obj("id", sid, "progress", 1.0, "unlocked", true)));
            } else if (a.getType() == Achievement.TYPE_INCREMENTAL) {
                int steps = (int) Math.round(fraction * a.getTotalSteps());
                r.await(c.setStepsImmediate(sid, steps), r.doing(), unlocked -> r.resolve(Json.obj("id", sid, "progress", fraction, "unlocked", unlocked)));
            } else {
                r.reject(new Failure(Failure.FAILED, r.doing() + " failed: the achievement is not incremental, so it has no progress",
                        "Only incremental achievements keep progress: make it incremental in Play Console (Achievements > the achievement > Incremental, with "
                                + "its number of steps), or call unlock when it is done."));
            }
        });
    }

    static void achievements(Request r) {
        JSONArray wanted = r.args.optJSONArray("achievements");
        r.await(PlayGames.getAchievementsClient(activity()).load(false), r.doing(), data -> {
            Map<String, JSONObject> byId = new HashMap<>();
            AchievementBuffer buffer = data.get();
            try {
                for (int i = 0; buffer != null && i < buffer.getCount(); i++) {
                    Achievement a = buffer.get(i);
                    boolean unlocked = a.getState() == Achievement.STATE_UNLOCKED;
                    double done = unlocked ? 1.0 : a.getType() == Achievement.TYPE_INCREMENTAL && a.getTotalSteps() > 0 ? a.getCurrentSteps() / (double) a.getTotalSteps() : 0.0;
                    byId.put(a.getAchievementId(), Json.obj("id", a.getAchievementId(), "unlocked", unlocked, "progress", done));
                }
            } finally {
                if (buffer != null) buffer.release();
            }
            JSONArray out = new JSONArray();
            for (int i = 0; wanted != null && i < wanted.length(); i++) {
                String sid = wanted.getJSONObject(i).optString("storeId", wanted.getJSONObject(i).optString("id"));
                JSONObject mine = byId.get(sid);
                if (mine == null) Backend.warn("Play Games has no achievement " + JSONObject.quote(sid) + ", so achievements.list() reports it locked. Create it in Play Console.");
                out.put(mine != null ? mine : Json.obj("id", sid, "unlocked", false, "progress", 0.0));
            }
            r.resolve(out);
        });
    }

    static void reset(Request r) {
        r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: Play Games cannot reset achievements from the game",
                "Reset a test account's progress from the Play Games Services management API (achievements.reset or resetAll, with the Play Console "
                        + "credentials of the project), or use a fresh test account."));
    }

    // ---------------------------------------------------------------------------------------------- leaderboards ----
    /**
     * The time span of the board's period: Play Games keeps a daily, a weekly and an all-time table for every leaderboard. Its
     * days and weeks start at its own times (midnight Pacific time), not at the player's midnight, and the API does not say
     * when the current one began, so the answers carry no periodStart or periodEnd (docs/PLATFORM.md, "Leaderboard periods").
     */
    static int timeSpan(Request r) {
        String period = r.args.optString("period", "allTime");
        if ("daily".equals(period)) return LeaderboardVariant.TIME_SPAN_DAILY;
        if ("weekly".equals(period)) return LeaderboardVariant.TIME_SPAN_WEEKLY;
        return LeaderboardVariant.TIME_SPAN_ALL_TIME;
    }

    static void submit(Request r) {
        String sid = storeId(r);
        int timeSpan = timeSpan(r);
        long score = r.args.optLong("score");
        LeaderboardsClient c = PlayGames.getLeaderboardsClient(activity());
        r.await(c.submitScoreImmediate(sid, score), r.doing(), sent -> {
            ScoreSubmissionData.Result result = sent.getScoreResult(timeSpan);
            if (result != null && result.newBest) {
                r.resolve(Json.obj("id", sid, "score", score, "best", score));
                return;
            }
            r.await(c.loadCurrentPlayerLeaderboardScore(sid, timeSpan, PUBLIC), r.doing(), mine -> {
                LeaderboardScore best = mine == null ? null : mine.get();
                r.resolve(Json.obj("id", sid, "score", score, "best", best == null ? score : best.getRawScore()));
            });
        });
    }

    static void entries(Request r) {
        String sid = storeId(r);
        String range = r.args.optString("range", "top");
        int timeSpan = timeSpan(r);
        int count = Math.max(1, Math.min(MAX_ROWS, r.args.optInt("count", 10))); // ponytail: no paging past one call of 25 rows
        LeaderboardsClient c = PlayGames.getLeaderboardsClient(activity());
        r.await(PlayGames.getPlayersClient(activity()).getCurrentPlayerId(), r.doing(), me -> {
            Task<AnnotatedData<LeaderboardsClient.LeaderboardScores>> rows = "around".equals(range)
                    ? c.loadPlayerCenteredScores(sid, timeSpan, PUBLIC, count)
                    : c.loadTopScores(sid, timeSpan, "friends".equals(range) ? LeaderboardVariant.COLLECTION_FRIENDS : PUBLIC, count);
            r.await(rows, r.doing(), data -> {
                JSONArray out = new JSONArray();
                LeaderboardsClient.LeaderboardScores scores = data.get();
                if (scores != null) {
                    try {
                        LeaderboardScoreBuffer buffer = scores.getScores();
                        for (int i = 0; i < buffer.getCount(); i++) {
                            LeaderboardScore s = buffer.get(i);
                            String pid = s.getScoreHolder() == null ? "" : s.getScoreHolder().getPlayerId();
                            out.put(Json.obj("rank", s.getRank(), "name", s.getScoreHolderDisplayName(), "score", s.getRawScore(), "playerId", pid,
                                    "isPlayer", pid.equals(me)));
                        }
                    } finally {
                        scores.release();
                    }
                }
                r.resolve(out);
            });
        });
    }

    // ------------------------------------------------------------------------------------------------ cloud save ----
    private static Snapshot opened(SnapshotsClient.DataOrConflict<Snapshot> result, Request r) throws Failure {
        if (result.isConflict()) {
            throw new Failure(Failure.FAILED, r.doing() + " failed: Play Games reports a conflict between two devices' saves",
                    "Try again: the most recently modified save wins and is kept.");
        }
        return result.getData();
    }

    private static boolean notFound(Exception e) {
        return e instanceof ApiException && ((ApiException) e).getStatusCode() == GamesClientStatusCodes.SNAPSHOT_NOT_FOUND;
    }

    /** Each cloud key is one Saved Games snapshot of the same name (Play allows letters, digits and - . _ ~, up to 100 characters). */
    static void save(Request r) {
        String key = r.args.optString("key");
        byte[] bytes = r.args.optString("data").getBytes(StandardCharsets.UTF_8);
        SnapshotsClient c = PlayGames.getSnapshotsClient(activity());
        r.await(c.open(key, true, POLICY), r.doing(), result -> {
            Snapshot snapshot = opened(result, r);
            snapshot.getSnapshotContents().writeBytes(bytes);
            SnapshotMetadataChange change = new SnapshotMetadataChange.Builder().setDescription("FactorIA save " + key).build();
            r.await(c.commitAndClose(snapshot, change), r.doing(), done -> r.resolve(Json.obj("key", key, "bytes", bytes.length)));
        });
    }

    static void load(Request r) {
        String key = r.args.optString("key");
        SnapshotsClient c = PlayGames.getSnapshotsClient(activity());
        Task<SnapshotsClient.DataOrConflict<Snapshot>> opening = c.open(key, false, POLICY);
        opening.addOnSuccessListener(result -> r.run(x -> {
            Snapshot snapshot = opened(result, r);
            String text = new String(snapshot.getSnapshotContents().readFully(), StandardCharsets.UTF_8);
            c.discardAndClose(snapshot);
            r.resolve(Json.obj("key", key, "data", text));
        }, null));
        opening.addOnFailureListener(e -> {
            if (notFound(e)) r.resolve(null);
            else r.reject(Errors.of(e, r.doing()));
        });
    }

    /**
     * The size and the modified time of a key. Play's metadata has no size, so the snapshot is opened and its bytes counted (they
     * are not handed to the game); the time is the snapshot's last modified time, which the device that saved set from its clock.
     */
    static void stat(Request r) {
        String key = r.args.optString("key");
        SnapshotsClient c = PlayGames.getSnapshotsClient(activity());
        Task<SnapshotsClient.DataOrConflict<Snapshot>> opening = c.open(key, false, POLICY);
        opening.addOnSuccessListener(result -> r.run(x -> {
            Snapshot snapshot = opened(result, r);
            int size = snapshot.getSnapshotContents().readFully().length;
            long modifiedMs = snapshot.getMetadata().getLastModifiedTimestamp();
            c.discardAndClose(snapshot);
            r.resolve(Json.obj("exists", true, "size", size, "modified", modifiedMs / 1000));
        }, null));
        opening.addOnFailureListener(e -> {
            if (notFound(e)) r.resolve(Json.obj("exists", false));
            else r.reject(Errors.of(e, r.doing()));
        });
    }

    static void list(Request r) {
        r.await(PlayGames.getSnapshotsClient(activity()).load(false), r.doing(), data -> {
            JSONArray out = new JSONArray();
            SnapshotMetadataBuffer buffer = data.get();
            try {
                for (int i = 0; buffer != null && i < buffer.getCount(); i++) out.put(buffer.get(i).getUniqueName());
            } finally {
                if (buffer != null) buffer.release();
            }
            r.resolve(out);
        });
    }

    static void remove(Request r) {
        String key = r.args.optString("key");
        SnapshotsClient c = PlayGames.getSnapshotsClient(activity());
        r.await(c.load(false), r.doing(), data -> {
            SnapshotMetadata found = null;
            SnapshotMetadataBuffer buffer = data.get();
            try {
                for (int i = 0; buffer != null && i < buffer.getCount(); i++) if (buffer.get(i).getUniqueName().equals(key)) found = buffer.get(i).freeze();
            } finally {
                if (buffer != null) buffer.release();
            }
            if (found == null) r.resolve(Json.obj());
            else r.await(c.delete(found), r.doing(), done -> r.resolve(Json.obj()));
        });
    }
}
