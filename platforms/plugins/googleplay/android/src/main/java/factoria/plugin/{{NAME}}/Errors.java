package factoria.plugin.{{NAME}};

import android.content.Context;

import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingResult;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.games.GamesClientStatusCodes;
import com.google.android.play.core.integrity.IntegrityServiceException;
import com.google.android.play.core.integrity.model.IntegrityErrorCode;

/**
 * What Google Play Billing, Play Games Services and Play Integrity report, as the error codes of docs/PLATFORM.md with a message
 * that names the call and a hint that says what to do.
 */
final class Errors {
    private Errors() {}

    private static String statusHint() {
        return " The command " + Backend.plugin + ".status (fa.call from a script) lists what is missing on this device.";
    }

    static final String PRODUCT_HINT = "Create the product in Play Console (Monetize with Play > Products: One-time products, or Subscriptions with a "
            + "base plan) with exactly this product id (platform.products[].ids.googleplay in factoria.json, else its id) and make it active. "
            + "Google answers only for an app it knows: upload a signed build to a test track (internal testing is enough) and install it "
            + "from Play with a license tester account (Play Console > Settings > License testing).";

    /** Whatever went wrong inside a request, as a Failure. */
    static Failure of(Throwable t, String doing) {
        if (t instanceof Failure) return (Failure) t;
        if (t instanceof IntegrityServiceException) return integrity((IntegrityServiceException) t, doing);
        if (t instanceof ApiException) return games((ApiException) t, doing);
        String what = t.getClass().getSimpleName() + (t.getMessage() == null ? "" : ": " + t.getMessage());
        return new Failure(Failure.FAILED, doing + " failed unexpectedly (" + what + ")",
                "This is a bug of the plugin or of a Google library, not of the game: the Java exception is in the log. Note it in "
                        + "ENGINE_FEEDBACK.json." + statusHint());
    }

    /** Null when Google Play services works; otherwise why it does not (an emulator image without Google Play is the usual cause). */
    static Failure noPlayServices(Context context, String doing) {
        GoogleApiAvailability api = GoogleApiAvailability.getInstance();
        int code = api.isGooglePlayServicesAvailable(context);
        if (code == ConnectionResult.SUCCESS) return null;
        String name = api.getErrorString(code);
        switch (code) {
            case ConnectionResult.SERVICE_MISSING:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play services is not installed on this device (" + name + ")",
                        "This is an emulator image or a device without Google Play. Test on a phone, or on an emulator image that says "
                                + "\"Google Play\" (Android Studio > Device Manager, a system image with the Play Store icon), and sign in to a Google "
                                + "account there." + statusHint());
            case ConnectionResult.SERVICE_VERSION_UPDATE_REQUIRED:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play services is out of date (" + name + ")",
                        "Update Google Play services in the Play Store (search for it by name), then try again." + statusHint());
            case ConnectionResult.SERVICE_DISABLED:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play services is disabled (" + name + ")",
                        "Enable it: Settings > Apps > Google Play services > Enable." + statusHint());
            default:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play services is not usable on this device (" + name + ")",
                        "Open the Play Store, update it and Google Play services, and sign in to a Google account." + statusHint());
        }
    }

    // ---------------------------------------------------------------------------------------------------- billing ----
    static String billingName(int code) {
        switch (code) {
            case BillingResponseCode.SERVICE_TIMEOUT: return "SERVICE_TIMEOUT";
            case BillingResponseCode.FEATURE_NOT_SUPPORTED: return "FEATURE_NOT_SUPPORTED";
            case BillingResponseCode.SERVICE_DISCONNECTED: return "SERVICE_DISCONNECTED";
            case BillingResponseCode.OK: return "OK";
            case BillingResponseCode.USER_CANCELED: return "USER_CANCELED";
            case BillingResponseCode.SERVICE_UNAVAILABLE: return "SERVICE_UNAVAILABLE";
            case BillingResponseCode.BILLING_UNAVAILABLE: return "BILLING_UNAVAILABLE";
            case BillingResponseCode.ITEM_UNAVAILABLE: return "ITEM_UNAVAILABLE";
            case BillingResponseCode.DEVELOPER_ERROR: return "DEVELOPER_ERROR";
            case BillingResponseCode.ERROR: return "ERROR";
            case BillingResponseCode.ITEM_ALREADY_OWNED: return "ITEM_ALREADY_OWNED";
            case BillingResponseCode.ITEM_NOT_OWNED: return "ITEM_NOT_OWNED";
            case BillingResponseCode.NETWORK_ERROR: return "NETWORK_ERROR";
            default: return "response code " + code;
        }
    }

    /** A Billing response that is not OK. {@code doing} names the call: platform.purchases.buy("gems_100"). */
    static Failure billing(BillingResult result, String doing) {
        int code = result.getResponseCode();
        String debug = result.getDebugMessage();
        String detail = " (" + billingName(code) + (debug == null || debug.isEmpty() ? "" : ": " + debug) + ")";
        switch (code) {
            case BillingResponseCode.BILLING_UNAVAILABLE:
            case BillingResponseCode.FEATURE_NOT_SUPPORTED:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play Billing is not available here" + detail,
                        "The device has no Google Play Store (an emulator image without the Google Play icon), the Play Store is too old for "
                                + "this, or the signed-in Google account cannot buy (a restricted profile, an unsupported country). Use a phone or an "
                                + "emulator image with Google Play, update the Play Store, and sign in to a Google account." + statusHint());
            case BillingResponseCode.SERVICE_DISCONNECTED:
            case BillingResponseCode.SERVICE_UNAVAILABLE:
            case BillingResponseCode.SERVICE_TIMEOUT:
            case BillingResponseCode.NETWORK_ERROR:
                return new Failure(Failure.NETWORK, doing + " failed: Google Play could not be reached" + detail,
                        "Check the internet connection and that the Play Store app opens, then try again." + statusHint());
            case BillingResponseCode.ITEM_UNAVAILABLE:
                return new Failure(Failure.UNKNOWN_ID, doing + " failed: Google Play says the product is not available" + detail, PRODUCT_HINT);
            case BillingResponseCode.DEVELOPER_ERROR:
                return new Failure(Failure.FAILED, doing + " failed: Google Play rejected how the app asks for it" + detail,
                        "The usual causes: the app is not uploaded to a test track in Play Console (Billing answers only for an app Play knows), "
                                + "the installed build is signed with another key than the uploaded one (install the build Play serves), the product "
                                + "is not active, or the Google account is not a license tester or a tester of the track." + statusHint());
            case BillingResponseCode.USER_CANCELED:
                return new Failure(Failure.FAILED, doing + " was cancelled by the player" + detail, null);
            case BillingResponseCode.ITEM_ALREADY_OWNED:
                return new Failure(Failure.FAILED, doing + " failed: the player already owns this product" + detail,
                        "A non-consumable can be bought once: call platform.purchases.restore(). A consumable must be finish()ed (consumed) before "
                                + "it can be bought again.");
            case BillingResponseCode.ITEM_NOT_OWNED:
                return new Failure(Failure.FAILED, doing + " failed: Google Play says the player does not own this purchase" + detail,
                        "It was refunded, or consumed already; nothing is left to finish.");
            default:
                return new Failure(Failure.FAILED, doing + " failed: Google Play Billing answered" + detail,
                        "Try again; if it persists, the Play Store may be broken or outdated." + statusHint());
        }
    }

    // ------------------------------------------------------------------------------------------------ play games ----
    static final String GAMES_SETUP_HINT = "Play Games Services answers only an app it knows. Check: the project id in "
            + "android/src/main/res/values/games-ids.xml is the one under Play Console > Play Games Services > Setup and management > "
            + "Configuration; the project has an Android credential for this package name with the SHA-1 of the key the build is signed "
            + "with (the upload key and the Play App Signing key); the Google account is a tester of the project while it is unpublished.";

    static Failure games(ApiException e, String doing) {
        int code = e.getStatusCode();
        String name = GamesClientStatusCodes.getStatusCodeString(code);
        String detail = " (" + name + (e.getStatusMessage() == null || e.getStatusMessage().isEmpty() ? "" : ": " + e.getStatusMessage()) + ")";
        switch (code) {
            case CommonStatusCodes.SIGN_IN_REQUIRED:
                return new Failure(Failure.NOT_SIGNED_IN, doing + " failed: the player is not signed in to Google Play Games" + detail,
                        "Call platform.signIn() first: it signs the player in and shows Google's prompt when needed. The device needs a Google "
                                + "account, and while the Play Games project is unpublished that account must be one of its testers (Play Console > "
                                + "Play Games Services > Setup and management > Testers).");
            case CommonStatusCodes.NETWORK_ERROR:
            case CommonStatusCodes.TIMEOUT:
            case CommonStatusCodes.INTERRUPTED:
            case GamesClientStatusCodes.NETWORK_ERROR_NO_DATA:
            case GamesClientStatusCodes.NETWORK_ERROR_OPERATION_FAILED:
                return new Failure(Failure.NETWORK, doing + " failed: Play Games could not be reached" + detail,
                        "Check the internet connection and try again.");
            case CommonStatusCodes.SERVICE_VERSION_UPDATE_REQUIRED:
            case CommonStatusCodes.SERVICE_DISABLED:
            case CommonStatusCodes.API_NOT_CONNECTED:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play services cannot serve Play Games on this device" + detail,
                        "Update or enable Google Play services, and use a device or an emulator image with Google Play." + statusHint());
            case CommonStatusCodes.DEVELOPER_ERROR:
            case GamesClientStatusCodes.APP_MISCONFIGURED:
            case GamesClientStatusCodes.GAME_NOT_FOUND:
            case GamesClientStatusCodes.LICENSE_CHECK_FAILED:
                return new Failure(Failure.FAILED, doing + " failed: Play Games Services does not accept this app" + detail, GAMES_SETUP_HINT + statusHint());
            case GamesClientStatusCodes.ACHIEVEMENT_UNKNOWN:
                return new Failure(Failure.UNKNOWN_ID, doing + " failed: Play Games has no such achievement" + detail,
                        "Create it in Play Console (Play Games Services > Setup and management > Achievements) and set platform.achievements[].ids."
                                + "googleplay in factoria.json to the id Play generated (it starts with CgkI).");
            case GamesClientStatusCodes.ACHIEVEMENT_NOT_INCREMENTAL:
                return new Failure(Failure.FAILED, doing + " failed: the achievement is not incremental" + detail,
                        "Make it incremental in Play Console (Achievements > the achievement > Incremental, with its number of steps) to keep progress.");
            case GamesClientStatusCodes.SNAPSHOT_FOLDER_UNAVAILABLE:
            case GamesClientStatusCodes.SNAPSHOT_CREATION_FAILED:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Saved Games is not available" + detail,
                        "Turn Saved Games on in Play Console (Play Games Services > Setup and management > Configuration > Saved Games), wait a few "
                                + "minutes for it to take effect, and check that the signed-in account is a tester of the project.");
            case GamesClientStatusCodes.OPERATION_IN_FLIGHT:
                return new Failure(Failure.FAILED, doing + " failed: another saved-game operation is still running" + detail,
                        "Wait for the previous cloud call to finish before starting the next.");
            case GamesClientStatusCodes.CONSENT_REQUIRED:
                return new Failure(Failure.NOT_ALLOWED, doing + " failed: the player has not allowed the game to see their Play Games friends" + detail,
                        "The Play Games app asks the player once; ask for the \"top\" or \"around\" board instead, or try again later.");
            case CommonStatusCodes.CANCELED:
                return new Failure(Failure.FAILED, doing + " was cancelled" + detail, null);
            case CommonStatusCodes.INTERNAL_ERROR:
                return new Failure(Failure.FAILED, doing + " failed: Play Games reported an internal error" + detail,
                        "It is also what Play Games answers for an id it does not know: check platform.<section>[].ids.googleplay in factoria.json "
                                + "against Play Console. Otherwise try again." + statusHint());
            default:
                return new Failure(Failure.FAILED, doing + " failed: Play Games answered" + detail, GAMES_SETUP_HINT + statusHint());
        }
    }

    // ------------------------------------------------------------------------------------------------- integrity ----
    static Failure integrity(IntegrityServiceException e, String doing) {
        int code = e.getErrorCode();
        String detail = " (Play Integrity error " + code + ")";
        switch (code) {
            case IntegrityErrorCode.API_NOT_AVAILABLE:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: the Play Integrity API is not available" + detail,
                        "The Play Store on this device is too old for it, or the app is not set up for it: link a Google Cloud project in Play "
                                + "Console > Test and release > App integrity, and update the Play Store.");
            case IntegrityErrorCode.PLAY_STORE_NOT_FOUND:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: the official Google Play Store is not installed" + detail,
                        "Play Integrity needs the Play Store: test on a phone or an emulator image with Google Play.");
            case IntegrityErrorCode.PLAY_STORE_ACCOUNT_NOT_FOUND:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: no Google account is signed in to the Play Store" + detail,
                        "Sign in to a Google account in the Play Store app, then try again.");
            case IntegrityErrorCode.APP_NOT_INSTALLED:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: the app was not installed from Google Play" + detail,
                        "Play Integrity answers only for an app that Play installed: install the build from the internal testing track (the "
                                + "testers' link) instead of adb install. " + Backend.plugin + ".status shows the installer.");
            case IntegrityErrorCode.PLAY_SERVICES_NOT_FOUND:
            case IntegrityErrorCode.PLAY_SERVICES_VERSION_OUTDATED:
            case IntegrityErrorCode.PLAY_STORE_VERSION_OUTDATED:
            case IntegrityErrorCode.CANNOT_BIND_TO_SERVICE:
                return new Failure(Failure.UNAVAILABLE, doing + " failed: Google Play services or the Play Store is missing or out of date" + detail,
                        "Update the Play Store and Google Play services, and use a device or an emulator image with Google Play." + statusHint());
            case IntegrityErrorCode.NETWORK_ERROR:
            case IntegrityErrorCode.GOOGLE_SERVER_UNAVAILABLE:
            case IntegrityErrorCode.CLIENT_TRANSIENT_ERROR:
                return new Failure(Failure.NETWORK, doing + " failed: Google could not be reached" + detail,
                        "Check the internet connection and try again, waiting a little longer each time.");
            case IntegrityErrorCode.TOO_MANY_REQUESTS:
                return new Failure(Failure.FAILED, doing + " failed: too many integrity requests" + detail,
                        "Request a token only when the server needs one (at sign-in or before a purchase), and retry later with an exponentially growing delay.");
            case IntegrityErrorCode.NONCE_TOO_SHORT:
            case IntegrityErrorCode.NONCE_TOO_LONG:
            case IntegrityErrorCode.NONCE_IS_NOT_BASE64:
                return new Failure(Failure.FAILED, doing + " failed: Google refused the challenge" + detail,
                        "The challenge must be URL-safe Base64 without padding or wrapping, 16 to 500 characters, made by your server (docs/PLATFORM.md).");
            case IntegrityErrorCode.CLOUD_PROJECT_NUMBER_IS_INVALID:
                return new Failure(Failure.FAILED, doing + " failed: the app is not linked to a valid Google Cloud project" + detail,
                        "Link a Google Cloud project with the Play Integrity API enabled in Play Console > Test and release > App integrity.");
            case IntegrityErrorCode.APP_UID_MISMATCH:
            default:
                return new Failure(Failure.FAILED, doing + " failed: Play Integrity answered" + detail,
                        "See https://developer.android.com/google/play/integrity/error-codes for the code." + statusHint());
        }
    }
}
