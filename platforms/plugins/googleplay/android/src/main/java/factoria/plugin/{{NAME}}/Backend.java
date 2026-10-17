package factoria.plugin.{{NAME}};

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.google.android.gms.games.PlayGamesSdk;

import org.json.JSONArray;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;

/**
 * The Google Play backend of FactorIA. src/plugin.c loads this class through the game's class loader, registers the four native
 * methods below and calls {@link #init}; from then on every request of the game arrives in {@link #request}. All Google work runs
 * on the main thread (the Billing and Play Games listeners expect it); an answer may come from there at any time.
 */
public final class Backend {
    private Backend() {}

    // Implemented by src/plugin.c: they answer a request (token = the C side's FaRequest*), send an event and log a line.
    static native void resolve(long token, String json);
    static native void reject(long token, String code, String message, String hint);
    static native void emit(String event, String json);
    static native void log(int level, String text);

    private static final String TAG = "FactorIA.googleplay";

    /** The plugin's name, as the game declared it (the command is "<plugin>.status"). */
    static volatile String plugin = "googleplay";
    /** The game's activity; Billing and Play Games need it for their screens. */
    static volatile Activity activity;
    /** The Play Games project id of games-ids.xml; empty means Play Games is off and its SDK is never called. */
    static volatile String gamesId = "";
    /** What the backend offers (the C side hands it to the engine). */
    static final JSONArray services = new JSONArray();
    static volatile Purchases purchases;
    static volatile boolean started;

    static final Handler main = new Handler(Looper.getMainLooper());
    private static ScheduledExecutorService timer;

    // ---------------------------------------------------------------------------------------------------- logging ----
    static void info(String text) { write(1, text); }
    static void warn(String text) { write(2, text); }
    static void error(String text) { write(3, text); }

    private static void write(int level, String text) {
        try {
            log(level, text);
        } catch (Throwable t) { // the natives are not registered (a unit test, a half-started plugin): still say it
            Log.println(level + 3, TAG, text);
        }
    }

    /** One daemon thread for the watchdogs of requests. */
    static synchronized ScheduledExecutorService timer() {
        if (timer == null) {
            timer = new ScheduledThreadPoolExecutor(1, r -> {
                Thread t = new Thread(r, "googleplay-watchdog");
                t.setDaemon(true);
                return t;
            });
        }
        return timer;
    }

    // ---------------------------------------------------------------------------------------------- entry points ----
    /** Called once by the C side, on the game's thread. Returns the services as a JSON array; the SDKs start on the main thread. */
    public static String init(Activity activity, String plugin) {
        Backend.activity = activity;
        Backend.plugin = plugin;
        gamesId = Status.gamesProjectId(activity);
        services.put("purchases");
        services.put("overlay");
        services.put("integrity");
        if (gamesId.isEmpty()) {
            info("Play Games is off (no project id in games-ids.xml): this backend offers purchases, the Play Store page and Play Integrity. "
                    + "To add achievements, leaderboards and cloud saves, run platform.add_backend {\"backend\":\"googleplay\",\"playGamesId\":\"<project id>\"} "
                    + "and export again.");
        } else {
            services.put("achievements");
            services.put("leaderboards");
            services.put("cloudSave");
        }
        main.post(Backend::start);
        return services.toString();
    }

    private static void start() {
        try {
            Activity a = activity;
            purchases = new Purchases();
            if (!gamesId.isEmpty()) {
                PlayGamesSdk.initialize(a.getApplicationContext());
                Games.refresh();
            }
            a.getApplication().registerActivityLifecycleCallbacks(new Lifecycle());
            purchases.resume();
            started = true;
        } catch (Throwable t) {
            error("the Google Play backend could not start: " + t + ". Every request will fail until the app is restarted; " + plugin
                    + ".status lists what is missing on this device.");
        }
    }

    /** Called by the C side for every request of the game, on the game's thread. Never throws; answers exactly once. */
    public static void request(long token, String method, String argsJson) {
        Request r = new Request(token, method, argsJson);
        try {
            if (!main.post(() -> dispatch(r))) r.reject(new Failure(Failure.FAILED, r.doing() + " failed: the app is shutting down", null));
        } catch (Throwable t) {
            r.reject(Errors.of(t, r.doing()));
        }
    }

    /** The JSON of the "<plugin>.status" command. */
    public static String status() {
        try {
            return Status.json();
        } catch (Throwable t) {
            return Json.obj("problems", new JSONArray().put("The status itself failed: " + t + ". The log has the stack trace.")).toString();
        }
    }

    // --------------------------------------------------------------------------------------------------- requests ----
    private static void dispatch(Request r) {
        try {
            if (!started) {
                r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: the Google Play backend did not start",
                        "The log (line \"the Google Play backend could not start\") says why. " + plugin + ".status lists what is missing on this device."));
                return;
            }
            r.watch("purchases.restore".equals(r.method) ? 120 : 30);
            switch (r.method) {
                case "player.signIn": Games.signIn(r); break;
                case "achievements.unlock": Games.unlock(r); break;
                case "achievements.progress": Games.progress(r); break;
                case "achievements.list": Games.achievements(r); break;
                case "achievements.reset": Games.reset(r); break;
                case "leaderboards.submit": Games.submit(r); break;
                case "leaderboards.entries": Games.entries(r); break;
                case "cloud.save": Games.save(r); break;
                case "cloud.load": Games.load(r); break;
                case "cloud.list": Games.list(r); break;
                case "cloud.remove": Games.remove(r); break;
                case "purchases.products": purchases.products(r); break;
                case "purchases.buy": purchases.buy(r); break;
                case "purchases.finish": purchases.finish(r); break;
                case "purchases.restore": purchases.restore(r); break;
                case "overlay.open": Overlay.open(r); break;
                case "integrity.token": Integrity.token(r); break;
                default:
                    r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: Google Play has no such thing (" + r.method + ")",
                            "Google Play Games has no stats and no presence. Check platform.has(service) before using a service. Keep numbers in "
                                    + "cloud.save or on a leaderboard."));
            }
        } catch (Throwable t) {
            r.reject(Errors.of(t, r.doing()));
        }
    }

    // -------------------------------------------------------------------------------------------------- lifecycle ----
    /** The game's activity going away (the player opened Google's screen) and coming back (resumed). */
    private static final class Lifecycle implements Application.ActivityLifecycleCallbacks {
        @Override public void onActivityResumed(Activity a) {
            if (a != activity) return;
            Overlay.resumed();
            Purchases p = purchases;
            if (p != null) p.resume();
        }

        @Override public void onActivityPaused(Activity a) {
            if (a == activity) Games.paused();
        }

        @Override public void onActivityCreated(Activity a, Bundle state) {}
        @Override public void onActivityStarted(Activity a) {}
        @Override public void onActivityStopped(Activity a) {}
        @Override public void onActivitySaveInstanceState(Activity a, Bundle state) {}
        @Override public void onActivityDestroyed(Activity a) {}
    }
}
