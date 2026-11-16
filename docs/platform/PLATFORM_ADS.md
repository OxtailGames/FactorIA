# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases, page 4 of 4

Part of [Store and platform services: achievements, stats, leaderboards, cloud saves, purchases](../PLATFORM.md) (the entry page lists every page).

## 8. Ads: Google AdMob and consent on Android and iOS

The backend `"admob"` is a plugin (`platforms/plugins/admob`, written into the game by `platform.add_backend`) for **Android**
(a C bridge and a Java Gradle module) and **iOS** (Swift, [Ads on iOS](#ads-on-ios)). It is an **ads backend**: it offers only
the `"ads"` service and works next to the game's store backend ([section 4](PLATFORM_BACKENDS.md#4-which-backend-runs)), so a game with Google Play
or App Store purchases and AdMob ads has both. Both platforms behave and answer the same; what differs is the setup, and Apple's
tracking sheet. **macOS has no AdMob SDK**: the plugin offers no ads there and `platform.has("ads")` is false (so it is on
Windows and Linux).

| Call | On AdMob |
|---|---|
| `platform.ads.consent()` | Google's User Messaging Platform (UMP). `gdpr` is `"notRequired"` (the player is outside the regions that need the form), `"granted"`, `"denied"` or `"unknown"` (the flow has not ended, or the game has not told the age of a `"mixed"` audience); `tracking` is `"notRequired"` on Android, and on iOS unless the game asks for the tracking sheet ([Ads on iOS](#ads-on-ios)); `canShowAds` is UMP's `canRequestAds`; `privacyOptions` is `"required"` when the player must be able to change their choices. |
| `platform.ads.available(placement)` | Loads one rewarded ad for the placement and keeps it. `true` when one is ready; `false` when there is none (no fill, no consent, no network, or 30 s without an answer). A kept ad older than 55 minutes is thrown away and loaded again (Google expires rewarded ads after an hour). |
| `platform.ads.showRewarded(placement)` | Shows the kept ad. `{ rewarded: true }` **only from the SDK's reward callback**; closing the ad early is `{ rewarded: false, reason: "closedEarly" }`, no ad is `reason: "noFill"` and a player who refused the consent is `reason: "consentRefused"`. The next ad of that placement loads in the background. |
| `platform.ads.setUnderAge(bool)`, `platform.ads.privacyOptions()` | [Children and consent](#children-and-consent). |

### Setup, in one command

```bash
factoria call platform.add_backend '{"backend": "admob"}'                                                         # Android
factoria call platform.add_backend '{"backend": "admob", "sdk": "~/Downloads/GoogleMobileAdsSdkiOS-13.11.0.zip"}'  # + iOS, on a Mac
```

It writes the plugin to `plugins/admob` from its template and declares it in factoria.json (unless it is declared already) for
Android and iOS (`"admobPlatforms": ["android"]` or `["ios"]` picks one). The repository holds no Google code:

- **Android**: it builds the C bridge for `arm64-v8a` and `x86_64` with the **Android SDK's NDK, CMake and Ninja**, the way
  [section 7](PLATFORM_APPLE_GOOGLE.md#7-google-play-billing-play-games-services-and-play-integrity) does for Google Play. When the game is exported,
  Gradle fetches the Mobile Ads SDK and Google's consent library from Google's Maven repository and merges the plugin's manifest
  ([MOBILE.md](../mobile/MOBILE_ANDROID.md#native-plugins-on-android)).
- **iOS**: Google's SDK is a download (developers.google.com/admob/ios/quick-start, "Download the SDK"). `"sdk"` is the zip or
  the unpacked folder: the command copies `GoogleMobileAds.xcframework` and `UserMessagingPlatform.xcframework` into
  `plugins/admob/ios/frameworks/` (the plugin's `.gitignore` keeps them out of git: each clone runs the command again with its
  own download) and builds the Swift side with Xcode for the device and the simulator. On a computer without Xcode, or without
  `"sdk"`, the command still writes and declares the plugin, and `nextSteps` says what is missing. An iOS export whose plugin
  lacks the frameworks fails and says where to put them.

`"admobBuild": false` only writes and declares the plugin (and copies the frameworks when `"sdk"` is given).

The result lists `nextSteps`, with the ids of your catalog filled in. What only a person can do:

1. **Nothing, to see ads at all.** A development export (`factoria export --platform android` or `ios`, without `--release`)
   uses Google's test ads, below.
2. **AdMob console** (admob.google.com): add the app (the package name of factoria.json's `id`; the iOS app is another app of
   the console) and copy its **app id** (`ca-app-pub-1234567890123456~1234567890`, with a tilde) into
   `"platform": { "ads": { "appIds": { "android": "...", "ios": "..." } } }`.
3. **Ad units**: create a rewarded ad unit for each placement in each app and copy its id (`ca-app-pub-1234567890123456/1234567890`,
   with a slash) into the placement: `"ids": { "admob": "...", "admob_ios": "..." }` (`admob` is the Android unit, `admob_ios` the
   iOS one). An app id in a unit field, or the other way round, is an error that says so.
4. **Consent**: in AdMob > Privacy & messaging, create and publish the GDPR message (and the US states message if you sell
   there). Without a published message the consent library has no form to show.
5. **Audience**: `platform.ads.audience` for a game for children or for children and adults ([below](#children-and-consent)).
6. **iOS only, if the ads need the advertising id**: `trackingPrompt`, below.

### Ads on iOS

An iOS export of a game with the plugin links Google's two XCFrameworks (static libraries in the current SDK, so nothing is embedded; a dynamic one would be),
the plugin's Swift library, `AdSupport`, `AppTrackingTransparency` and `WebKit`, and writes into the Info.plist:
`GADApplicationIdentifier` (the app id), Google's list of `SKAdNetworkItems` (without it AdMob cannot attribute installs), and
the engine's `FactoriaAds*` keys that tell the plugin the audience and whether this is a test build. The plugin declares those in
its `ios/plugin.json` (`xcframeworks`, `infoPlist`, [MOBILE.md](../mobile/MOBILE_IOS.md#native-plugins-ios)).

The start order is the same as on Android, with Apple's sheet added:

1. **Google's consent form (UMP)**, for the players who need it (the EEA, the UK, Switzerland, some US states).
2. **Apple's "Allow tracking" sheet (App Tracking Transparency)**, only when `platform.ads.trackingPrompt` is `true` in the
   catalog, only after the form closed with consent to request ads, only while the status is `notDetermined`, and never for a
   player counted as under age. A game that does not ask never sees the sheet and `consent().tracking` is `"notRequired"`;
   otherwise it is Apple's status: `"authorized"`, `"denied"`, `"restricted"` or `"notDetermined"` (a player who was never
   asked).
3. **The Mobile Ads SDK starts**; a refused tracking sheet does not stop ads (they are not personalized then).

```json
"ads": {
  "appIds": { "ios": "ca-app-pub-1234567890123456~0987654321" },
  "trackingPrompt": true,
  "trackingDescriptionKey": "ads.tracking",
  "placements": [ { "id": "more_time", "type": "rewarded", "ids": { "admob": "ca-app-pub-1234567890123456/1234567890",
                                                                    "admob_ios": "ca-app-pub-1234567890123456/0987654321" } } ]
}
```

- `trackingDescription` is the sentence of the sheet (`NSUserTrackingUsageDescription`); without it the export writes "This
  identifier will be used to deliver personalized ads to you." Apple reviews the sentence: say what the identifier is for.
  `trackingDescriptionKey` names a key of the string tables instead: the export writes one `InfoPlist.strings` per language of
  the game (`localization.languages`, [LOCALIZATION.md](../LOCALIZATION.md)), so iOS shows the sheet in the player's language.
- An app that asks to track must say so in its privacy manifest: set `export.ios.privacy.tracking` (and the tracking domains)
  to match. The iOS export warns when `trackingPrompt` is true and it is not, and `factoria validate` warns when `trackingPrompt`
  is true and the game has no ads plugin for iOS ([MOBILE.md](../mobile/MOBILE_PRIVACY.md#store-privacy-forms)).
- In AdMob > Privacy & messaging, create the IDFA explainer message too if you ask for tracking.
- A `children` audience never asks for tracking, whatever `trackingPrompt` says.

### Test ads and real ads

| Export | App id in the manifest | Ad unit loaded |
|---|---|---|
| `factoria export --platform android` (development) | Google's sample app id `ca-app-pub-3940256099942544~3347511713`, whatever the catalog says | Google's sample rewarded unit `ca-app-pub-3940256099942544/5224354917` for every placement |
| `factoria export --platform android --release` | `platform.ads.appIds.android` (the sample id when it is not set, with a warning) | the placement's `ids.admob`; a placement without a valid one rejects with `unknownId` and says how to add it |
| `factoria export --platform ios` (development) | Google's iOS sample app id `ca-app-pub-3940256099942544~1458002511` (`GADApplicationIdentifier`), whatever the catalog says | Google's iOS sample rewarded unit `ca-app-pub-3940256099942544/1712485313` for every placement |
| `factoria export --platform ios --release` | `platform.ads.appIds.ios` (the sample id when it is not set, with a warning) | the placement's `ids.admob_ios`; a placement without a valid one rejects with `unknownId` |

Test ads are labelled as such, earn nothing, and cannot get your account flagged for clicking your own ads. The mode comes
from the manifest (`factoria.ads.test`, written by the export; on iOS the Info.plist's `FactoriaAdsTest`), not from `platform.release`: an exported game always runs without
a fallback store, so `platform.release` is true in every APK, test ads or not. `factoria validate` and a release export warn when
the game has the admob plugin for Android (iOS) and `platform.ads.appIds.android` (`.ios`) is missing or Google's sample id, when a
placement has no `ids.admob` (`ids.admob_ios`) or has the sample unit, and when the audience is `"mixed"` and no script calls
`setUnderAge`. An export for one platform reports only that platform's problems.

### Children and consent

The start order is Google's, and the plugin keeps it: the consent form (a player in the EEA, the UK or Switzerland answers it
once; Google keeps the answer) comes first, and the Mobile Ads SDK starts only when the player's choices allow requesting ads.
Nothing runs before the game's activity is in front. `ads.available` and `ads.showRewarded` wait for that to finish, and answer
"no ad" if it ends without the player's consent or if the SDK start takes more than 120 s after the form. While the consent form is still open the wait
goes on: the player may take minutes to read it, and the flow ends by itself with an error if the network fails.

`platform.ads.audience` in factoria.json says who plays:

| Audience | What the engine does |
|---|---|
| `"general"` (default) | Nothing special: consent as UMP decides. A game that told the age with `setUnderAge` has it passed on. |
| `"children"` | The game is made for children. Every player counts as under age: UMP and every ad request are tagged for child-directed treatment and the under age of consent, with the maximum content rating G. `setUnderAge(false)` is ignored. Check Google's families policies before you ship ads in a children's game. |
| `"mixed"` | Children and adults play. **Until the game calls `platform.ads.setUnderAge(bool)`, nothing is requested**: no consent form, no SDK start, no ad (`available` is false, `showRewarded` is `consentRefused`, `consent().gdpr` is `"unknown"`), so a child is never shown the form untagged. The answer tags UMP and every ad request the way `"children"` does for a child (`true`), or as not child-directed (`false`). |

For `"mixed"`, add the menu kit's age gate: `factoria call project.add_menu_kit '{"parts": ["main-menu", "ageGate"]}'`
(the main menu opens it; the `ageGate` part alone adds the panel and `openAgeGate()` for your own first scene; [MENUS.md](../menus/MENUS_HOW.md)). It asks the year of birth, keeps only whether the player is under age (never the year; a player
who prefers not to say counts as a child), and calls `platform.ads.setUnderAge`; later runs read the stored answer and call it
again. The engine keeps the answer for the run and sends it to the backend with every ads request. `platform.reset()` (tests)
forgets it.

`platform.ads.privacyOptions()` opens UMP's form where the player changes their choices or takes consent back. Google requires a
button for it whenever `platform.ads.consent().privacyOptions` is `"required"`; show it **only then** (the menu kit's options screen
does). It resolves `{ shown }`; if the player took consent back, the ads kept in memory are discarded and no new one loads.

The **fake backend** answers all of it for development and tests: `game.platform.ad("watched", { gdpr: "granted", privacyOptions:
"required" })` sets what `consent()` answers, both calls appear in `state().fake.calls`, and `state().fake.ads.privacyShown` counts the forms.

### When something does not work: `admob.status`

The plugin registers the command **`admob.status`** (from a script: `fa.call("admob.status", {})`): the manifest's (iOS: the
Info.plist's) app id, whether this is a test build, the audience, the age the game told, the consent answer (on iOS also
`trackingPrompt`), whether the SDK started, each placement's unit, whether its ad is ready and its last error, and a `problems`
list of sentences that say what to fix. Run it first.

| Situation | What the game gets |
|---|---|
| The audience is `"mixed"` and the game never told the age | No consent form and no ads, as above. `problems` says so. |
| The player refused the consent | `available` false, `showRewarded` `{ rewarded: false, reason: "consentRefused" }`. |
| No ad to show (no fill, no network, a new app that AdMob still reviews) | `available` false; `showRewarded` `reason: "noFill"`. The log has Google's error code. |
| Release build with no valid `ids.admob` (iOS: `ids.admob_ios`) for the placement | `unknownId`, naming the placement and the catalog key to add. |
| iOS, `trackingPrompt` true and the Info.plist has no `NSUserTrackingUsageDescription` (an old export) | iOS ends the app when the sheet is requested; the log warns before. Export again. |
| iOS, the player refused the tracking sheet | Ads still load (not personalized); `consent().tracking` is `"denied"`. |
| The ad failed to show | `failed`, with Google's code and message. |
| No AdMob app id in the manifest (Info.plist on iOS) | AdMob stops the app at start; `factoria validate` warns before. |

### CI and manual checks

**Android.** CI exports the game with the plugin, checks that the APK carries both libraries, the plugin's classes (with the Mobile Ads SDK
and UMP linked into the dex) and the manifest with the app id, and starts it on the emulator to see that the plugin registered the
**ads** backend and answers `admob.status` through the C bridge. It does not load an ad: that needs Google's network and an
image with Google Play. The tooling tests cover the setup command, the manifest of an export (the app id, the test flag, the
audience) and the validate warnings. By hand, on an emulator with Google Play (for instance the AVD `Pixel7_API35`), with the
development export of a game that has the plugin:

1. `adb install -r game.apk`, start it and read `adb logcat -s FactorIA.admob`: `AdMob: development export, Google's test ads`,
   then `ads: consent {...}` (a European test device shows UMP's form first; elsewhere the status is `notRequired`) and
   `ads: the Mobile Ads SDK is ready`.
2. Open the screen that offers the ad: `ads: a rewarded ad is ready for '<placement>'`. Show it: Google's test ad, then
   `ads: the player earned the reward of '<placement>' (...)` and `ads: the rewarded ad of '<placement>' was closed, rewarded: true`.
3. Close a second ad before the reward: `rewarded: false`, `reason: "closedEarly"`, and the game grants nothing.
4. With `consent().privacyOptions` `"required"` (a test device in UMP's debug geography), the options button shows UMP's form.
5. In a `"mixed"` game, check that nothing is requested before the age gate is answered (`admob.status` says
   `consentFlowStarted: false`).

**iOS.** No CI job loads Google's iOS SDK (it is a download that the repository never holds): the tooling tests export a game
with a stub XCFramework made by the test and check that it is linked, that the Info.plist has the app id, the `SKAdNetworkItems`
and the tracking sentence, and that the catalog and validate errors teach; they also cover the setup command with a stub SDK zip.
By hand, on the iOS Simulator (an iPhone runtime of Xcode; the simulator needs the network), with the development export of a
game that has the plugin (`factoria export --platform ios`, then the `nextSteps` it prints to build and install the app; read
the app's console with `xcrun simctl launch --console-pty <device> <bundle id>`):

1. The log shows `AdMob backend ready: service ads on ios`, `AdMob: development export, Google's test ads, audience general,
   tracking prompt on|off`, `ads: consent {...}` and `ads: the Mobile Ads SDK is ready`.
2. A rewarded ad: `ads: a rewarded ad is ready for '<placement>'`, Google's test ad, `ads: the player earned the reward...`, then
   `...was closed, rewarded: true`. Closing it early gives `rewarded: false`, `reason: "closedEarly"`.
3. The consent form: a development export reads Google's debug settings, which a release build ignores. Launch with
   `SIMCTL_CHILD_FA_ADS_DEBUG_GEOGRAPHY=EEA xcrun simctl launch --console-pty <device> <bundle id>` (or `regulatedUSState`,
   `other`; the launch argument `-FactoriaAdsDebugGeography EEA` does the same) to see UMP's form on a simulator, and
   `SIMCTL_CHILD_FA_ADS_RESET_CONSENT=1` to forget the stored answer (UMP keeps it between runs). `simctl` cannot tap: answer the
   form by hand in the Simulator app, or with an XCUITest (`platforms/ios/touch-test` shows how).
4. With `trackingPrompt` true: after the form is answered, the "Allow tracking" sheet appears with your sentence, and the log
   says `ads: tracking authorized` (or `denied`). It comes after the form and not before. iOS keeps the answer per app: change it in the simulator's Settings > Privacy & Security > Tracking, or use a fresh simulator to be asked again.
5. In a `"mixed"` game, nothing is requested before the age gate is answered (`admob.status` says `consentFlowStarted: false`).
6. A release export shows no test ad: it carries your `appIds.ios` and the `ids.admob_ios` of each placement. A new AdMob app
   may get "no fill" for a day or two while Google reviews it.

Record what a real check finds in `ENGINE_FEEDBACK.json`.
