package factoria.plugin.{{NAME}};

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;

import com.google.android.gms.games.PlayGames;

import org.json.JSONObject;

/**
 * Google's own screens: the Play Games achievements and leaderboards, and the game's Play Store page. The game's activity pauses
 * while one is up and resumes when the player comes back; those two moments are the `overlay` events.
 */
final class Overlay {
    private Overlay() {}

    private static final int REQUEST_CODE = 52301;
    private static boolean open; // main thread only

    static void open(Request r) {
        String page = r.args.optString("page");
        String storeId = r.args.optString("storeId", "");
        Activity a = Backend.activity;
        switch (page) {
            case "achievements":
                if (games(r)) r.await(PlayGames.getAchievementsClient(a).getAchievementsIntent(), r.doing(), intent -> show(r, intent));
                break;
            case "leaderboards":
                if (games(r)) {
                    r.await(storeId.isEmpty() ? PlayGames.getLeaderboardsClient(a).getAllLeaderboardsIntent()
                            : PlayGames.getLeaderboardsClient(a).getLeaderboardIntent(storeId), r.doing(), intent -> show(r, intent));
                }
                break;
            case "store":
                store(r, a);
                break;
            default: // "friends": the Play Games SDK has no screen for it
                r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: Google Play has no " + JSONObject.quote(page) + " screen",
                        "Use \"achievements\", \"leaderboards\" or \"store\". Handle the rejection: a game works without a friends screen."));
        }
    }

    private static boolean games(Request r) {
        if (!Backend.gamesId.isEmpty()) return true;
        r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: Play Games is off in this build",
                "Set the Play Games project id (platform.add_backend {\"backend\":\"googleplay\",\"playGamesId\":\"<digits>\"}) and export again. "
                        + "The \"store\" page works without it."));
        return false;
    }

    private static void show(Request r, Intent intent) {
        Backend.activity.startActivityForResult(intent, REQUEST_CODE);
        opened();
        r.resolve(Json.obj());
    }

    /** The game's own page in the Play Store app, else in a browser. */
    private static void store(Request r, Activity a) {
        String url = "id=" + a.getPackageName();
        try {
            a.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?" + url)));
        } catch (ActivityNotFoundException noStore) {
            a.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?" + url)));
        }
        opened();
        r.resolve(Json.obj());
    }

    private static void opened() {
        if (open) return;
        open = true;
        Backend.emit("overlay", Json.obj("open", true).toString());
    }

    /** The game's activity is back in front: the screen it opened is closed. */
    static void resumed() {
        if (!open) return;
        open = false;
        Backend.emit("overlay", Json.obj("open", false).toString());
    }
}
