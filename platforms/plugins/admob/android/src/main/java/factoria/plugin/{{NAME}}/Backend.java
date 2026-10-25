package factoria.plugin.{{NAME}};

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONArray;

import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;

/**
 * The AdMob backend of FactorIA. src/plugin.c loads this class through the game's class loader, registers the four native methods
 * below and calls {@link #init}; from then on every `ads.*` request of the game arrives in {@link #request}. All Google work runs on
 * the main thread (the consent form and the ad listeners expect it); an answer may come from there at any time.
 */
public final class Backend {
    private Backend() {}

    // Implemented by src/plugin.c: they answer a request (token = the C side's FaRequest*), send an event and log a line.
    static native void resolve(long token, String json);
    static native void reject(long token, String code, String message, String hint);
    static native void emit(String event, String json);
    static native void log(int level, String text);

    private static final String TAG = "FactorIA.admob";

    /** The plugin's name, as the game declared it (the command is "<plugin>.status"). */
    static volatile String plugin = "admob";
    /** The game's activity; the consent form and the ads need it. */
    static volatile Activity activity;
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

    /** One daemon thread for the timeouts of requests. */
    static synchronized ScheduledExecutorService timer() {
        if (timer == null) {
            timer = new ScheduledThreadPoolExecutor(1, r -> {
                Thread t = new Thread(r, "admob-timeout");
                t.setDaemon(true);
                return t;
            });
        }
        return timer;
    }

    // ---------------------------------------------------------------------------------------------- entry points ----
    /**
     * Called once by the C side, on the game's thread. Returns the services as a JSON array: just "ads". Nothing of Google's runs
     * yet: the consent form and the Mobile Ads SDK start on the main thread once the activity is in front, and (in a game for
     * children and adults) once the game knows whether the player is under age.
     */
    public static String init(Activity activity, String plugin) {
        Backend.activity = activity;
        Backend.plugin = plugin;
        main.post(Backend::start);
        return new JSONArray().put("ads").toString();
    }

    private static void start() {
        try {
            Ads.begin(activity);
            activity.getApplication().registerActivityLifecycleCallbacks(new Lifecycle());
            started = true;
            Ads.resumed(); // the activity may be in front already
        } catch (Throwable t) {
            error("the AdMob backend could not start: " + t + ". Every request will fail until the app is restarted; " + plugin
                    + ".status lists what is missing.");
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
            return Ads.status().toString();
        } catch (Throwable t) {
            return Json.obj("problems", new JSONArray().put("The status itself failed: " + t + ". The log has the stack trace.")).toString();
        }
    }

    // --------------------------------------------------------------------------------------------------- requests ----
    private static void dispatch(Request r) {
        try {
            if (!started) {
                r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: the AdMob backend did not start",
                        "The log (line \"the AdMob backend could not start\") says why. " + plugin + ".status lists what is missing."));
                return;
            }
            Ads.learn(r);
            switch (r.method) {
                case "ads.available": Ads.available(r); break;
                case "ads.showRewarded": Ads.showRewarded(r); break;
                case "ads.consent": Ads.consent(r); break;
                case "ads.setUnderAge": Ads.setUnderAge(r); break;
                case "ads.privacyOptions": Ads.privacyOptions(r); break;
                default:
                    r.reject(new Failure(Failure.UNAVAILABLE, r.doing() + " failed: AdMob has no such thing (" + r.method + ")",
                            "This backend only offers the \"ads\" service. Check platform.has(service) before using a service; the game's "
                                    + "store backend answers the others."));
            }
        } catch (Throwable t) {
            r.reject(Errors.of(t, r.doing()));
        }
    }

    // -------------------------------------------------------------------------------------------------- lifecycle ----
    /** The game's activity coming back to the front: the consent form can be shown from here on. */
    private static final class Lifecycle implements Application.ActivityLifecycleCallbacks {
        @Override public void onActivityResumed(Activity a) {
            if (a == activity) Ads.resumed();
        }

        @Override public void onActivityCreated(Activity a, Bundle state) {}
        @Override public void onActivityStarted(Activity a) {}
        @Override public void onActivityPaused(Activity a) {}
        @Override public void onActivityStopped(Activity a) {}
        @Override public void onActivitySaveInstanceState(Activity a, Bundle state) {}
        @Override public void onActivityDestroyed(Activity a) {}
    }
}
