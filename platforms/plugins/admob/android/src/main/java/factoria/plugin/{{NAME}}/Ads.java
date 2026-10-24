package factoria.plugin.{{NAME}};

import android.app.Activity;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.SystemClock;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Consent (Google's User Messaging Platform) and rewarded ads (the Mobile Ads SDK). Everything here runs on the main thread.
 *
 * The order is Google's: the consent form first (a player in the EEA, UK or Switzerland answers it once; the answer is kept), and
 * only when the player's choices allow requesting ads, the Mobile Ads SDK starts. Nothing of that runs before the activity is in
 * front, and in a game for children and adults ("mixed") nothing runs before the game told {@code ads.setUnderAge}, so a child is
 * never shown the form and the SDK never starts untagged.
 */
final class Ads {
    private Ads() {}

    /** Google's sample app id and rewarded unit (developers.google.com/admob/android/test-ads): they show test ads and earn nothing. */
    static final String SAMPLE_APP_ID = "ca-app-pub-3940256099942544~3347511713";
    static final String SAMPLE_REWARDED = "ca-app-pub-3940256099942544/5224354917";

    private static final Pattern UNIT = Pattern.compile("ca-app-pub-\\d{16}/\\d{10}");
    /** Rewarded ads expire an hour after they were loaded; a kept ad older than this is thrown away. */
    private static final long MAX_AGE_MS = 55L * 60 * 1000;

    // What the export wrote into the manifest (platforms/android/app/build.gradle, manifestPlaceholders).
    private static String appId = "";
    private static String audience = "general"; // factoria.json platform.ads.audience
    private static boolean test = true;         // a development export: Google's test ids, whatever the catalog says

    private static Activity activity;
    private static boolean resumed;
    /** The player is under the age of consent: null = the game did not say. */
    private static Boolean underAge;
    private static boolean flowStarted;
    private static boolean consentDone;   // the consent flow ended (with or without a form)
    private static String consentProblem; // why the consent information could not be read, or null
    private static boolean sdkStarting;
    private static boolean sdkReady;
    private static String blocked;        // why no ad can be requested (the player refused, the SDK did not start), or null
    private static ConsentInformation consent;
    private static final List<Runnable> waiting = new ArrayList<>();
    private static final Map<String, Slot> slots = new HashMap<>();

    /** One kept rewarded ad per placement. */
    private static final class Slot {
        final String placement;
        String unit = "";
        RewardedAd ad;
        long loadedAt;
        boolean loading;
        String lastError;
        final List<Runnable> waiters = new ArrayList<>();

        Slot(String placement) { this.placement = placement; }

        boolean fresh() { return ad != null && SystemClock.elapsedRealtime() - loadedAt < MAX_AGE_MS; }
    }

    // --------------------------------------------------------------------------------------------------------- start ----
    @SuppressWarnings("deprecation")
    static void begin(Activity a) {
        activity = a;
        try {
            ApplicationInfo info = a.getPackageManager().getApplicationInfo(a.getPackageName(), PackageManager.GET_META_DATA);
            Bundle meta = info.metaData;
            if (meta != null) {
                Object id = meta.get("com.google.android.gms.ads.APPLICATION_ID");
                appId = id == null ? "" : String.valueOf(id);
                Object a2 = meta.get("factoria.ads.audience");
                if (a2 != null) audience = String.valueOf(a2);
                Object t = meta.get("factoria.ads.test");
                test = t == null || Boolean.parseBoolean(String.valueOf(t));
            }
        } catch (Throwable t) {
            Backend.warn("could not read the ads settings from the manifest (" + t + "): using Google's test ads");
        }
        if ("children".equals(audience)) underAge = Boolean.TRUE;
        if (!test && (appId.isEmpty() || SAMPLE_APP_ID.equals(appId)))
            Backend.warn("this is a release build but the app id is " + (appId.isEmpty() ? "missing" : "Google's sample id")
                    + ": real ads will not load. Set platform.ads.appIds.android in factoria.json (docs/PLATFORM.md, \"Ads\").");
        Backend.info("AdMob: " + (test ? "development export, Google's test ads" : "release export, real ads") + ", audience " + audience);
    }

    static void resumed() {
        resumed = true;
        maybeStart();
    }

    /** What the game knows about the player's age travels with every request; a new answer reconfigures the SDK. */
    static void learn(Request r) {
        if (r.args.has("underAge") && !r.args.isNull("underAge")) setUnderAge(r.args.optBoolean("underAge"));
        maybeStart();
    }

    private static void setUnderAge(boolean value) {
        if ("children".equals(audience)) value = true; // a game for children counts every player as a child
        if (underAge != null && underAge == value) return;
        underAge = value;
        if (sdkReady) {
            configure(); // the tags only apply to requests made from now on: ads loaded before are not tagged
            for (Slot s : slots.values()) s.ad = null;
        }
        Backend.info("ads: the player is " + (value ? "under" : "not under") + " the age of consent");
    }

    private static boolean ageKnown() {
        return !"mixed".equals(audience) || underAge != null;
    }

    private static void maybeStart() {
        if (flowStarted || !resumed || !ageKnown()) return;
        flowStarted = true;
        try {
            consent = UserMessagingPlatform.getConsentInformation(activity);
            ConsentRequestParameters.Builder params = new ConsentRequestParameters.Builder();
            if (underAge != null) params.setTagForUnderAgeOfConsent(underAge);
            consent.requestConsentInfoUpdate(activity, params.build(),
                    () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, formError -> {
                        if (formError != null)
                            consentProblem = "the consent form failed: " + formError.getMessage() + " (error " + formError.getErrorCode() + ")";
                        consentFlowEnded();
                    }),
                    requestError -> {
                        consentProblem = "the consent information could not be read: " + requestError.getMessage() + " (error " + requestError.getErrorCode() + ")";
                        consentFlowEnded();
                    });
        } catch (Throwable t) {
            consentProblem = "the consent library failed: " + t;
            Backend.error("ads: " + consentProblem);
            consentFlowEnded();
        }
    }

    private static void consentFlowEnded() {
        consentDone = true;
        if (consentProblem != null) Backend.warn("ads: " + consentProblem);
        Backend.info("ads: consent " + consentJson());
        startSdk();
    }

    /** Starts the Mobile Ads SDK once the player's choices allow requesting ads (also after they change them in the privacy form). */
    private static void startSdk() {
        if (sdkReady || sdkStarting) return;
        if (consent == null || !consent.canRequestAds()) {
            blocked = consentProblem != null ? consentProblem : "the player did not give the consent that ads need";
            settle();
            return;
        }
        blocked = null;
        sdkStarting = true;
        try {
            configure();
            MobileAds.initialize(activity, status -> {
                sdkReady = true;
                sdkStarting = false;
                Backend.info("ads: the Mobile Ads SDK is ready");
                settle();
            });
        } catch (Throwable t) {
            sdkStarting = false;
            blocked = "the Mobile Ads SDK could not start: " + t;
            Backend.error("ads: " + blocked);
            settle();
        }
    }

    /** COPPA and the age of consent: the tags AdMob needs on every request of a child (developers.google.com/admob/android/targeting). */
    private static void configure() {
        RequestConfiguration.Builder b = MobileAds.getRequestConfiguration().toBuilder();
        if (underAge != null) {
            b.setTagForChildDirectedTreatment(underAge ? RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_TRUE
                                                       : RequestConfiguration.TAG_FOR_CHILD_DIRECTED_TREATMENT_FALSE);
            b.setTagForUnderAgeOfConsent(underAge ? RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_TRUE
                                                  : RequestConfiguration.TAG_FOR_UNDER_AGE_OF_CONSENT_FALSE);
            if (underAge) b.setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_G);
        }
        MobileAds.setRequestConfiguration(b.build());
    }

    /** Runs what waited for the start to finish (the SDK is ready, or it will not be). */
    private static void settle() {
        List<Runnable> run = new ArrayList<>(waiting);
        waiting.clear();
        for (Runnable r : run) r.run();
    }

    private static boolean settled() {
        return sdkReady || blocked != null || (consentDone && (consent == null || !consent.canRequestAds()));
    }

    /** Runs {@code then} once the consent flow and the SDK start have ended; a request that waits too long gets {@code late}. */
    private static void whenSettled(Request r, Runnable then, Runnable late) {
        if (settled()) {
            then.run();
            return;
        }
        waiting.add(() -> {
            if (!r.isAnswered()) then.run();
        });
        giveUpLater(r, late);
    }

    /** The consent flow can show a form the player reads for minutes (the game is paused behind it): do not give up while it runs. */
    private static void giveUpLater(Request r, Runnable late) {
        r.after(120, () -> {
            if (r.isAnswered()) return;
            if (flowStarted && !consentDone) giveUpLater(r, late); // the flow ends by itself, with an error if the network fails
            else late.run();
        });
    }

    // ----------------------------------------------------------------------------------------------------- consent ----
    private static JSONObject consentJson() {
        String gdpr = "unknown";
        String options = "unknown";
        boolean canShow = false;
        if (consent != null && consentDone) {
            canShow = consent.canRequestAds();
            switch (consent.getConsentStatus()) {
                case ConsentInformation.ConsentStatus.NOT_REQUIRED: gdpr = "notRequired"; break;
                case ConsentInformation.ConsentStatus.OBTAINED: gdpr = canShow ? "granted" : "denied"; break;
                case ConsentInformation.ConsentStatus.REQUIRED: gdpr = "denied"; break; // the flow ended and it is still required: no answer
                default: gdpr = "unknown";
            }
            switch (consent.getPrivacyOptionsRequirementStatus()) {
                case REQUIRED: options = "required"; break;
                case NOT_REQUIRED: options = "notRequired"; break;
                default: options = "unknown";
            }
        }
        // Android has no tracking sheet (that is Apple's ATT).
        return Json.obj("gdpr", gdpr, "tracking", "notRequired", "canShowAds", canShow, "privacyOptions", options);
    }

    static void consent(Request r) {
        if (!ageKnown()) { // a game for children and adults has not asked the age yet: the form must not appear
            r.resolve(Json.obj("gdpr", "unknown", "tracking", "notRequired", "canShowAds", false, "privacyOptions", "unknown"));
            return;
        }
        whenSettled(r, () -> r.resolve(consentJson()), () -> r.resolve(consentJson()));
    }

    static void setUnderAge(Request r) {
        r.resolve(new JSONObject()); // learn() already kept the answer and started the consent flow if it was waiting for it
    }

    static void privacyOptions(Request r) {
        if (!ageKnown()) {
            r.resolve(Json.obj("shown", false));
            return;
        }
        whenSettled(r, () -> {
            if (consent == null || consent.getPrivacyOptionsRequirementStatus() != ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED) {
                r.resolve(Json.obj("shown", false));
                return;
            }
            r.beginInteraction();
            UserMessagingPlatform.showPrivacyOptionsForm(activity, formError -> {
                if (formError != null) {
                    r.reject(Errors.google(formError.getErrorCode(), String.valueOf(formError.getMessage()), r.doing()));
                    return;
                }
                if (!consent.canRequestAds()) { // the player took the consent back: ads kept in memory must not be shown
                    for (Slot s : slots.values()) s.ad = null;
                    blocked = "the player did not give the consent that ads need";
                } else {
                    startSdk();
                }
                r.resolve(Json.obj("shown", true));
            });
        }, () -> r.resolve(Json.obj("shown", false)));
    }

    // ------------------------------------------------------------------------------------------------------- ads ----
    /** The unit to load for a placement: Google's rewarded sample in a development export, the catalog's AdMob unit in a release one. */
    private static String unitFor(Request r) throws Failure {
        if (test) return SAMPLE_REWARDED;
        String unit = r.args.optString("adUnitId", "");
        if (!UNIT.matcher(unit).matches())
            throw new Failure(Failure.UNKNOWN_ID, r.doing() + " failed: '" + unit + "' is not an AdMob ad unit id",
                    "Give the placement its AdMob unit in factoria.json: \"placements\": [{\"id\": \"" + r.args.optString("placement")
                            + "\", \"ids\": {\"admob\": \"ca-app-pub-1234567890123456/1234567890\"}}] (AdMob > Apps > Ad units).");
        if (SAMPLE_REWARDED.equals(unit))
            Backend.warn("the placement '" + r.args.optString("placement") + "' uses Google's sample ad unit in a release build: it earns nothing");
        return unit;
    }

    private static Slot slotFor(Request r) throws Failure {
        String placement = r.args.optString("placement", "");
        Slot s = slots.get(placement);
        if (s == null) {
            s = new Slot(placement);
            slots.put(placement, s);
        }
        s.unit = unitFor(r);
        return s;
    }

    private static void load(Slot s) {
        if (s.loading || s.fresh() || !sdkReady) return;
        s.ad = null;
        s.loading = true;
        try {
            RewardedAd.load(activity, s.unit, new AdRequest.Builder().build(), new RewardedAdLoadCallback() {
                @Override public void onAdLoaded(RewardedAd ad) {
                    s.loading = false;
                    s.ad = ad;
                    s.loadedAt = SystemClock.elapsedRealtime();
                    s.lastError = null;
                    Backend.info("ads: a rewarded ad is ready for '" + s.placement + "'");
                    wake(s);
                }

                @Override public void onAdFailedToLoad(LoadAdError e) {
                    s.loading = false;
                    s.ad = null;
                    s.lastError = e.getMessage() + " (Google error " + e.getCode() + ")";
                    Backend.warn("ads: no rewarded ad for '" + s.placement + "': " + s.lastError);
                    wake(s);
                }
            });
        } catch (Throwable t) {
            s.loading = false;
            s.lastError = String.valueOf(t);
            Backend.error("ads: loading an ad threw: " + t);
            wake(s);
        }
    }

    private static void wake(Slot s) {
        List<Runnable> run = new ArrayList<>(s.waiters);
        s.waiters.clear();
        for (Runnable r : run) r.run();
    }

    /** Calls {@code then} when the slot has an ad or the load ended without one. */
    private static void whenLoaded(Slot s, Request r, Runnable then) {
        if (s.fresh()) {
            then.run();
            return;
        }
        s.waiters.add(() -> {
            if (!r.isAnswered()) then.run();
        });
        load(s);
        if (!s.loading && !s.fresh()) wake(s); // load() did not start (SDK not ready): do not wait for nothing
    }

    static void available(Request r) {
        if (!ageKnown()) {
            r.resolve(Json.obj("available", false));
            return;
        }
        whenSettled(r, () -> {
            try {
                if (!sdkReady) {
                    r.resolve(Json.obj("available", false));
                    return;
                }
                Slot s = slotFor(r);
                r.after(30, () -> r.resolve(Json.obj("available", false))); // a slow network is "no ad for now"
                whenLoaded(s, r, () -> r.resolve(Json.obj("available", s.fresh())));
            } catch (Throwable t) {
                r.reject(Errors.of(t, r.doing()));
            }
        }, () -> r.resolve(Json.obj("available", false)));
    }

    static void showRewarded(Request r) {
        if (!ageKnown()) {
            r.resolve(Json.obj("rewarded", false, "reason", "consentRefused"));
            return;
        }
        whenSettled(r, () -> {
            try {
                if (!sdkReady) {
                    r.resolve(Json.obj("rewarded", false, "reason", consent != null && !consent.canRequestAds() ? "consentRefused" : "noFill"));
                    return;
                }
                Slot s = slotFor(r);
                r.after(30, () -> {
                    if (!r.isInteracting()) r.resolve(Json.obj("rewarded", false, "reason", "noFill"));
                });
                whenLoaded(s, r, () -> show(s, r));
            } catch (Throwable t) {
                r.reject(Errors.of(t, r.doing()));
            }
        }, () -> r.resolve(Json.obj("rewarded", false, "reason", "noFill")));
    }

    private static void show(Slot s, Request r) {
        if (!s.fresh()) {
            r.resolve(Json.obj("rewarded", false, "reason", "noFill"));
            return;
        }
        RewardedAd ad = s.ad;
        s.ad = null; // an ad is shown once
        boolean[] earned = {false};
        ad.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override public void onAdDismissedFullScreenContent() {
                Backend.info("ads: the rewarded ad of '" + s.placement + "' was closed, rewarded: " + earned[0]);
                if (earned[0]) r.resolve(Json.obj("rewarded", true));
                else r.resolve(Json.obj("rewarded", false, "reason", "closedEarly"));
                load(s); // keep the next one ready
            }

            @Override public void onAdFailedToShowFullScreenContent(AdError e) {
                r.reject(Errors.google(e.getCode(), e.getMessage(), r.doing()));
                load(s);
            }
        });
        r.beginInteraction();
        try {
            ad.show(activity, item -> {
                earned[0] = true; // the only place that grants the reward
                Backend.info("ads: the player earned the reward of '" + s.placement + "' (" + item.getAmount() + " " + item.getType() + ")");
            });
        } catch (Throwable t) {
            r.reject(Errors.of(t, r.doing()));
        }
    }

    // ------------------------------------------------------------------------------------------------------ status ----
    static JSONObject status() {
        JSONObject o = new JSONObject();
        JSONArray problems = new JSONArray();
        try {
            o.put("plugin", Backend.plugin);
            o.put("started", Backend.started);
            o.put("appId", appId);
            o.put("test", test);
            o.put("audience", audience);
            o.put("underAge", underAge == null ? JSONObject.NULL : underAge);
            o.put("consentFlowStarted", flowStarted);
            o.put("consent", consentJson());
            o.put("sdkReady", sdkReady);
            o.put("blocked", blocked == null ? JSONObject.NULL : blocked);
            JSONObject ads = new JSONObject();
            for (Slot s : slots.values())
                ads.put(s.placement, new JSONObject().put("unit", s.unit).put("ready", s.fresh()).put("loading", s.loading)
                        .put("lastError", s.lastError == null ? JSONObject.NULL : s.lastError));
            o.put("placements", ads);
            if (appId.isEmpty())
                problems.put("The manifest has no com.google.android.gms.ads.APPLICATION_ID: AdMob stops the app at start. Export the game again (factoria export --platform android).");
            if (!test && SAMPLE_APP_ID.equals(appId))
                problems.put("This is a release build with Google's sample app id: set platform.ads.appIds.android in factoria.json and export again.");
            if (!resumed) problems.put("The activity has not been in front yet: the consent form waits for it.");
            if ("mixed".equals(audience) && underAge == null)
                problems.put("The audience is \"mixed\" and the game has not called platform.ads.setUnderAge(): no consent form, no SDK and no ad until it does (the menu kit's ageGate part asks).");
            if (consentProblem != null) problems.put("Consent: " + consentProblem);
            if (blocked != null) problems.put("No ad can be requested: " + blocked);
            o.put("problems", problems);
        } catch (Throwable t) {
            problems.put("The status failed: " + t);
        }
        return o;
    }
}
