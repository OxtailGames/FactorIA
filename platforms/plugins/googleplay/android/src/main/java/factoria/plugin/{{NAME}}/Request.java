package factoria.plugin.{{NAME}};

import com.google.android.gms.tasks.Task;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * One platform request of the game. It is answered exactly once, whichever way the work ends (a result, a failure, the
 * watchdog): the first answer wins, a later one is dropped (resolve and reject say whether theirs was the answer).
 */
final class Request {
    final String method;
    final JSONObject args;
    private final long token;
    private final AtomicBoolean answered = new AtomicBoolean();
    private volatile boolean interacting;

    Request(long token, String method, String argsJson) {
        this.token = token;
        this.method = method;
        JSONObject parsed;
        try {
            parsed = new JSONObject(argsJson == null || argsJson.isEmpty() ? "{}" : argsJson);
        } catch (JSONException e) {
            parsed = new JSONObject();
        }
        this.args = parsed;
    }

    /** The call as a game wrote it, for messages: platform.purchases.buy("gems_100"). */
    String doing() {
        String id = args.optString("id", args.optString("key", ""));
        return "platform." + method + "(" + (id.isEmpty() ? "" : JSONObject.quote(id)) + ")";
    }

    boolean isAnswered() {
        return answered.get();
    }

    /** The request now waits for the player (Google's purchase or sign-in screen is up): the watchdog no longer cuts it short. */
    void beginInteraction() {
        interacting = true;
    }

    /** Answers with a result: a JSONObject, a JSONArray, a string, a number, a boolean or null. False when it was answered already. */
    boolean resolve(Object value) {
        if (!answered.compareAndSet(false, true)) return false;
        try {
            Backend.resolve(token, Json.text(value));
        } catch (Throwable t) {
            Backend.error("could not answer " + method + ": " + t);
        }
        return true;
    }

    /** Answers with a failure. False when it was answered already. */
    boolean reject(Failure f) {
        if (!answered.compareAndSet(false, true)) return false;
        try {
            Backend.reject(token, f.code, f.getMessage(), f.hint);
        } catch (Throwable t) {
            Backend.error("could not answer " + method + ": " + t);
        }
        return true;
    }

    /** Rejects with `network` when nothing has answered after {@code seconds} (unless the player is busy with a Google screen). */
    void watch(int seconds) {
        Backend.timer().schedule(() -> {
            if (answered.get() || interacting) return;
            reject(new Failure(Failure.NETWORK, doing() + " got no answer from Google within " + seconds + " seconds",
                    "Check the internet connection and try again. If it keeps happening on a device or emulator, the command "
                            + Backend.plugin + ".status (fa.call from a script) lists what is missing: Google Play services, the Play Store, "
                            + "a Google account, an app Play does not know."));
        }, seconds, TimeUnit.SECONDS);
    }

    /** One step of a chain of Google Tasks. */
    interface Step<T> {
        void run(T value) throws Exception;
    }

    /** Runs a step; whatever it throws rejects this request (so a callback of Google's never lets an exception leave). */
    <T> void run(Step<T> step, T value) {
        try {
            step.run(value);
        } catch (Throwable t) {
            reject(Errors.of(t, doing()));
        }
    }

    /** Runs {@code then} with the task's result on the main thread; any failure (the task's or the step's) rejects this request. */
    <T> void await(Task<T> task, String doing, Step<T> then) {
        task.addOnSuccessListener(value -> run(then, value));
        task.addOnFailureListener(e -> reject(Errors.of(e, doing)));
    }
}
