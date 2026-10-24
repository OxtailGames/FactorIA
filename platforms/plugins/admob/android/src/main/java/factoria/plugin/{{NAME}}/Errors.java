package factoria.plugin.{{NAME}};

/** Turns what went wrong into a {@link Failure} that says what happened and how to fix it. */
final class Errors {
    private Errors() {}

    /** An exception inside the plugin or a Google callback. */
    static Failure of(Throwable t, String doing) {
        if (t instanceof Failure) return (Failure) t;
        if (t instanceof SecurityException)
            return new Failure(Failure.NOT_ALLOWED, doing + " failed: " + t.getMessage(),
                    "A permission is missing. Mobile ads need android.permission.INTERNET, which the Google libraries add to the app "
                            + "themselves; export the game again (factoria export --platform android).");
        return new Failure(Failure.FAILED, doing + " failed: " + t,
                "This is a bug of the plugin or of the Google library; the log has the stack trace. " + Backend.plugin
                        + ".status lists what is missing on this device.");
    }

    /** A failure of the Mobile Ads SDK or the consent library: Google's code (AdRequest.ERROR_CODE_*) and message. */
    static Failure google(int code, String message, String doing) {
        String text = doing + " failed: " + message + " (Google error " + code + ")";
        if (code == 2) // AdRequest.ERROR_CODE_NETWORK_ERROR
            return new Failure(Failure.NETWORK, text, "Check the internet connection and try again.");
        if (code == 1) // AdRequest.ERROR_CODE_INVALID_REQUEST
            return new Failure(Failure.FAILED, text,
                    "AdMob refused the request: usually the ad unit id or the app id is wrong. In a development run the plugin uses Google's "
                            + "test ids; in a release build set platform.ads.appIds.android and the placement's \"ids\": {\"admob\": \"ca-app-pub-...\"} "
                            + "in factoria.json (docs/PLATFORM.md, \"Ads\").");
        return new Failure(Failure.FAILED, text, Backend.plugin + ".status lists the state of the consent form and the SDK; the log has the details.");
    }
}
