# Mobile: Android and iOS, page 3 of 4

Part of [Mobile: Android and iOS](../MOBILE.md) (the entry page lists every page).

## Store privacy forms

Both stores ask what your app does with user data before they accept an upload, and they check it against the app. The
answers depend on the whole game (its plugins, its scripts, your servers), so these are the facts about the engine to
build them from, not a form already filled in. Check the store's current help pages too: the forms change.

**What the engine itself does.** Nothing leaves the device by itself: no analytics, no advertising id, no accounts, no
connection the game's scripts did not ask for. Saves (`storage`) and `log.txt` are files in the app's private folder, and
crash reports are written next to them; nothing sends them anywhere. A game whose scripts call `http.fetch` talks only to
the hosts it declares in `factoria.json` `"network"` ([NETWORKING.md](../NETWORKING.md)). A game that declares hosts, adds an ads
or analytics SDK, or a store plugin changes the answers, as below.

### App Store (iOS)

**Privacy manifest.** Apple requires a `PrivacyInfo.xcprivacy` in every app that calls a "required reason" API, and rejects
an upload that uses one without declaring it. `factoria export --platform ios` writes it next to `build_ios.sh` and the
build copies it to the root of the app. For the engine it declares:

| API category | Reason | Why |
|---|---|---|
| `FileTimestamp` | `C617.1` | the size and modification time of the game's own files inside the app (`fs` file checks, hot reload), through `stat` |
| `SystemBootTime` | `35F9.1` | the monotonic clock (`mach_absolute_time`) that the frame loop, physics and the script runtime measure elapsed time with |

It also says `NSPrivacyTracking` false, no tracking domains and no collected data types. The engine does not use disk space
or `UserDefaults` APIs; the Apple plugin (StoreKit, Game Center, iCloud key-value store) is made of system frameworks,
which carry their own declarations.

If your game or a plugin of yours calls more required-reason APIs, collects data or tracks, say so in `factoria.json`; the
export merges it with the engine's entries (a category the engine already declares gets the union of the reasons):

```json
"export": {
  "ios": {
    "usesNonExemptEncryption": false,
    "privacy": {
      "tracking": false,
      "accessedApis": [{ "category": "DiskSpace", "reasons": ["E174.1"] }],
      "collectedData": [
        { "type": "PurchaseHistory", "linked": true, "purposes": ["AppFunctionality"] }
      ]
    }
  }
}
```

- `accessedApis[].category`: `FileTimestamp`, `SystemBootTime`, `DiskSpace`, `UserDefaults` or `ActiveKeyboards`. `reasons`
  are Apple's codes for that category: FileTimestamp `DDA9.1` (shown to the user), `C617.1` (files in the app's own container),
  `3B52.1` (files the user chose), `0A2A.1` (a third-party SDK's wrapper); SystemBootTime `35F9.1` (time elapsed between
  events inside the app), `8FFB.1` (a timestamp of an event shown to the user), `3D61.1` (a user-initiated bug report);
  DiskSpace `E174.1` (check before writing a file or to tell the user), `85F4.1` (show the user), `7D9E.1` (a user-initiated
  bug report), `B728.1` (health research apps); UserDefaults `CA92.1` (the app's own preferences), `1C8F.1` (app group),
  `C56D.1` (third-party SDK wrapper), `AC6B.1` (managed app configuration); ActiveKeyboards `3EC4.1` (a custom keyboard),
  `54BD.1` (to pick a keyboard-specific UI). Apple's page "Describing use of required reason API" has the exact wording.
- `collectedData[].type`: `Name`, `EmailAddress`, `PhoneNumber`, `PhysicalAddress`, `OtherUserContactInfo`, `Health`, `Fitness`,
  `PaymentInfo`, `CreditInfo`, `OtherFinancialInfo`, `PreciseLocation`, `CoarseLocation`, `SensitiveInfo`, `Contacts`,
  `EmailsOrTextMessages`, `PhotosOrVideos`, `AudioData`, `GameplayContent`, `CustomerSupport`, `OtherUserContent`,
  `BrowsingHistory`, `SearchHistory`, `UserID`, `DeviceID`, `PurchaseHistory`, `ProductInteraction`, `AdvertisingData`,
  `OtherUsageData`, `CrashData`, `PerformanceData`, `OtherDiagnosticData`, `EnvironmentScanning`, `Hands`, `Head`,
  `OtherDataTypes`. `purposes`: `ThirdPartyAdvertising`, `DeveloperAdvertising`, `Analytics`, `ProductPersonalization`,
  `AppFunctionality`, `Other`. `linked` is whether the data is tied to the user's identity, `tracking` whether it is used to
  track the user.
- `tracking` and `trackingDomains`: only for apps (or SDKs in them) that track users across other companies' apps and sites;
  tracking also needs the App Tracking Transparency prompt: the engine shows it only for the ads plugin with `platform.ads.trackingPrompt` ([PLATFORM.md](../platform/PLATFORM_ADS.md#ads-on-ios)); a plugin or SDK of your own must ask itself.
- A mistake in any of these (an unknown category, a reason code that belongs to another category, a misspelled data type)
  is an error that names the pointer in `factoria.json` and suggests the closest valid value.

Third-party SDKs that you link as plugins bring their own manifest requirements; add what they document.

**Encryption.** `Info.plist` gets `ITSAppUsesNonExemptEncryption` `false`, so App Store Connect does not ask the
export-compliance question on every upload. That is right for a game that uses only the encryption iOS provides (HTTPS
through the system, the Keychain). If your game ships its own cryptography, set `export.ios.usesNonExemptEncryption` to
`true` and answer the export-compliance questions in App Store Connect (some countries need documentation).

**The App Privacy "nutrition label"** (App Store Connect > your app > App Privacy) is filled in by hand and should match the
manifest:

| Your game | What to answer |
|---|---|
| Engine only, saves on the device, no `"network"` hosts | "Data Not Collected" |
| `"network"` hosts and `http.fetch` | Answer for what **your** server receives from the requests (a player name, a score, the IP address): collected, and linked to the user when it can identify the player. The engine adds no identifier of its own; `http.fetch` allows `https://` only, so App Transport Security needs no exception ([NETWORKING.md](../NETWORKING.md)) |
| Apple plugin: purchases (StoreKit 2), Game Center, iCloud key-value saves | Apple processes these inside its own services and the data is not sent to you, so they do not add a "collected" entry. If your own server receives receipts or Game Center player ids, add Purchase History and/or User ID, linked to the user, purpose App Functionality |
| `admob` plugin on iOS: rewarded ads, Google's consent form (UMP) and, with `platform.ads.trackingPrompt`, the "Allow tracking" sheet (ATT) | Google's Mobile Ads SDK collects the advertising id, device and ad interaction data: answer Device ID, Advertising Data and Product Interaction as collected and linked to the user, purpose Third-Party Advertising, and "Data Used to Track You" if you ask for tracking, following Google's AdMob App Store privacy help. Keep the privacy manifest in line: with `trackingPrompt`, set `export.ios.privacy.tracking` to `true` and list the ad network's domains in `export.ios.privacy.trackingDomains` (the export warns when `trackingPrompt` is on and `tracking` is not). Google's XCFrameworks carry their own privacy manifests (PrivacyInfo.xcprivacy). A game for children must follow Apple's Kids Category rules for ads |
| An ads, attribution or analytics SDK | Whatever the SDK documents (Device ID, Advertising Data, Product Interaction, ...), and `tracking` plus the ATT prompt if it tracks |
| Your own account system or backend | The data you send (Name, Email Address, User ID, Gameplay Content...) |

### Google Play (Android)

**Data safety** (Play Console > App content > Data safety) is also filled in by hand; Play compares it with the app. The
engine adds only what a feature needs to `AndroidManifest.xml`: `INTERNET` when `factoria.json` declares `"network"` hosts (nothing otherwise), and `VIBRATE` (add others with `export.android.permissions`). The answers:

| Your game | What to declare |
|---|---|
| Engine only, saves on the device, no `"network"` hosts | "No data collected" and "No data shared". `log.txt`, crash reports and saves stay in the app's private folder; the game makes no request |
| `"network"` hosts and `http.fetch` | Declare what your server receives from the requests (often a player name or id, a score, the IP address that every request reveals); the engine adds no identifier of its own. Data in transit is encrypted: the engine only allows `https://` (plain `http://` to `localhost` is for development) |
| `googleplay` plugin: purchases (Play Billing) | Play Billing handles the payment and shows the purchase history to the game on the device; the Billing library adds the `com.android.vending.BILLING` permission to the manifest. Declare Purchase history (Financial info) only if your own server receives or stores purchase tokens or receipts |
| `googleplay` plugin: Play Games Services (when `playGamesId` is set) | The Play Games SDK signs the player in and keeps achievements, leaderboard scores and Saved Games in the player's Google account. Declare a player id (User IDs under Personal info) and the game data (App activity) when your own backend receives them; where only Google's services hold them, follow Google's definition of "collected" in the Data safety help |
| `googleplay` plugin: Play Integrity | The request and the verdict go through Google; the token goes to your server. Declare what your server keeps of it (device or app integrity information) |
| `admob` plugin: rewarded ads and Google's consent form (UMP) | Google's Mobile Ads SDK collects the advertising id, the device and ad interaction data and shares them with the ad network; declare Device or other IDs and App interactions as shared, and Advertising or marketing as the purpose, following Google's AdMob Data safety help. The merged manifest carries the AD_ID permission when the SDK asks for it: check it in the built APK (`aapt2 dump permissions`). A game for children must follow Google's families policy for ads. [Ads](../platform/PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios) |
| An ads SDK | Advertising ID (`com.google.android.gms.permission.AD_ID` in `export.android.permissions`), plus what the SDK documents; apps that target Android 13+ without it get a zeroed ad id |
| Accounts, analytics (your own backend beyond `http.fetch`) | The data you send, whether you share it, whether it is encrypted in transit and whether players can ask for deletion |

Play also asks for a **privacy policy** link on the store listing of every app, and for the "Data deletion" answers when you
have accounts. Go through the form again whenever you add a plugin or SDK.
