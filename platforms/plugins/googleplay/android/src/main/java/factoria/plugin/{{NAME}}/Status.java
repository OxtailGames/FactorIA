package factoria.plugin.{{NAME}};

import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

import org.json.JSONArray;
import org.json.JSONObject;

/** The "<plugin>.status" command: what this device and this build give Google Play, and a list of sentences that say what to fix. */
final class Status {
    private Status() {}

    /** The Play Games project id of games-ids.xml; empty when it is not set. */
    static String gamesProjectId(Context context) {
        int id = context.getResources().getIdentifier("game_services_project_id", "string", context.getPackageName());
        return id == 0 ? "" : context.getString(id).trim();
    }

    private static String versionOf(PackageManager pm, String pkg) {
        try {
            String v = pm.getPackageInfo(pkg, 0).versionName;
            return v == null ? "unknown" : v;
        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    private static String installer(PackageManager pm, String pkg) {
        try {
            return Build.VERSION.SDK_INT >= 30 ? pm.getInstallSourceInfo(pkg).getInstallingPackageName() : pm.getInstallerPackageName(pkg);
        } catch (PackageManager.NameNotFoundException e) {
            return null;
        }
    }

    static String json() {
        Activity a = Backend.activity;
        PackageManager pm = a.getPackageManager();
        String pkg = a.getPackageName();
        JSONArray problems = new JSONArray();

        String installer = installer(pm, pkg);
        if (!"com.android.vending".equals(installer)) {
            problems.put("The app was not installed by Google Play (installer: " + (installer == null ? "none, e.g. adb" : installer) + "). Billing answers only for an "
                    + "app that is uploaded to a Play Console track, and Play Integrity only for one that Play installed: install the build from the "
                    + "internal testing track (the testers' link) to try purchases and integrity. Play Games works from adb once the project is set up.");
        }

        GoogleApiAvailability api = GoogleApiAvailability.getInstance();
        int services = api.isGooglePlayServicesAvailable(a);
        if (services != ConnectionResult.SUCCESS) {
            problems.put("Google Play services is not usable (" + api.getErrorString(services) + "): use a phone or an emulator image with the Google Play icon, "
                    + "and update Google Play services.");
        }
        String store = versionOf(pm, "com.android.vending");
        if (store == null) problems.put("The Google Play Store is not installed: purchases and Play Integrity cannot work. Use a device or an emulator image with Google Play.");

        Purchases p = Backend.purchases;
        String billing = p == null ? "not started" : p.state();
        if (p != null && !"ready".equals(billing) && !"connecting".equals(billing)) {
            problems.put("Google Play Billing is " + billing + ". The usual cause is no Play Store or no Google account on the device.");
        }

        boolean gamesOn = !Backend.gamesId.isEmpty();
        JSONObject player = Games.player;
        if (!gamesOn) {
            problems.put("Play Games is off (no project id in games-ids.xml): achievements, leaderboards and cloud saves answer unavailable. Run "
                    + "platform.add_backend {\"backend\":\"googleplay\",\"playGamesId\":\"<project id>\"} and export again.");
        } else if (player == null) {
            problems.put("No Play Games player is signed in yet. platform.signIn() asks the player; while the Play Games project is unpublished the Google account must be "
                    + "one of its testers (Play Console > Play Games Services > Setup and management > Testers).");
        }
        if (!Backend.started) problems.put("The backend did not start; the log has the reason.");

        return Json.obj(
                "package", pkg,
                "installer", installer == null ? "none" : installer,
                "playServices", Json.obj("available", services == ConnectionResult.SUCCESS, "state", api.getErrorString(services), "version", versionOf(pm, "com.google.android.gms")),
                "playStore", Json.obj("installed", store != null, "version", store),
                "billing", billing,
                "playGames", Json.obj("enabled", gamesOn, "projectId", Backend.gamesId, "signedIn", player != null,
                        "playerId", player == null ? null : player.optString("id"), "playerName", player == null ? null : player.optString("name")),
                "services", Backend.services,
                "problems", problems).toString();
    }
}
