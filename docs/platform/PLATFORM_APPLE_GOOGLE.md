# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases, page 3 of 4

Part of [Store and platform services: achievements, stats, leaderboards, cloud saves, purchases](../PLATFORM.md) (the entry page lists every page).

## 6. Apple: StoreKit 2, Game Center and iCloud

The backend `"apple"` is a Swift plugin (`platforms/plugins/apple`, written into the game by `platform.add_backend`) for **iOS
16.3+ and macOS 12+**. It answers `platform` with:

| Service | Apple's API | Notes |
|---|---|---|
| `purchases` | StoreKit 2 | consumables, non-consumables and subscriptions; Ask to Buy; refunds. |
| `achievements`, `leaderboards` | Game Center | the sign-in sheet, the banners, global / around the player / friends boards. |
| `overlay` | Game Center | `"achievements"`, `"leaderboards"` and `"friends"` through the Game Center access point. `"store"` is `unavailable`: `purchases.buy` shows the purchase sheet. |
| `cloudSave` | iCloud key-value store | 1 MB and 1024 keys for the whole game. |

Game Center has no stats and no presence: `platform.has("stats")` and `platform.has("presence")` are false and the engine
answers those calls `unavailable`. Keep the numbers you need in `cloud.save` or on a leaderboard.

### Setup, in one command

On a Mac with Xcode:

```bash
factoria call platform.add_backend '{"backend": "apple"}'
```

It writes the plugin to `plugins/apple` from its template and declares it for iOS and macOS in factoria.json (unless it is
declared already), then builds its three libraries with the Xcode toolchain (`xcrun swiftc`, driven by CMake):
`macos/libapple.dylib`, `ios/iphoneos/libapple.a` and `ios/iphonesimulator/libapple.a`. Arguments: `appleSlices` (any of
`"macos"`, `"iphoneos"`, `"iphonesimulator"`; default all three) and `appleBuild: false` (only write and declare, to build
later on a Mac). A computer that is not a Mac cannot build Swift against StoreKit: the command says so and offers
`appleBuild: false`. Its `nextSteps` list what only a person can do, with the ids of your catalog filled in:

1. **Apple Developer portal**: the App ID of `factoria.json`'s `id` needs the capabilities **Game Center**, **In-App
   Purchase** and **iCloud** (key-value storage only, no iCloud Drive or CloudKit).
2. **App Store Connect**: add the app with that bundle id, accept the **Paid Apps Agreement**, turn **Game Center** on, and
   create the products, achievements and leaderboards. Each gets **exactly** the id of the catalog (`ids.apple`, else `id`).
3. A **sandbox tester** (Users and Access > Sandbox), signed in under Settings > Developer > Sandbox Apple Account.

Then export with `factoria export --platform ios` (or `macos`). The exports read the plugin's `plugin.json` (frameworks,
the Swift runtime, entitlements: [MOBILE.md](../mobile/MOBILE_IOS.md#native-plugins-ios), [EXTENDING.md](../EXTENDING.md#g2-the-declaration)).
**iOS**: the Xcode project links StoreKit, GameKit and the Swift runtime and is signed with the entitlements
(`factoria_player.entitlements`; set `export.ios.teamId` or `FA_IOS_DEVELOPMENT_TEAM` so Xcode can sign for a device).
**macOS**: Game Center and iCloud are *restricted* entitlements, which macOS only honours in an app signed with your Apple
Developer certificate and a provisioning profile. The export is signed ad hoc, so it runs, and those services answer
`unavailable` with a hint; the export also writes `<game>.entitlements`, and `sign.macos` with `provisioningProfile` (the profile
of the App ID, from the Apple Developer portal) signs the app with them ([EXPORTING.md](../exporting/EXPORTING_DESKTOP.md#signing-and-notarizing-for-macos)). An ad hoc app also gets no answers from the App Store: try purchases from Xcode (below) or after that signing step.

### What each call does

| Call | On Apple |
|---|---|
| `platform.signIn()` | Starts Game Center's authentication: a sheet the first time, a welcome banner after. Resolves `{ id, name, signedIn }` (`id` is the `gamePlayerID`, stable for this game). A player who is not signed in gets `notSignedIn` with a hint (sign in under Settings > Game Center). With no sheet and no answer it ends after 20 s; a sheet on screen waits for the player. |
| `achievements.unlock(id)`, `.progress(id, fraction)` | Reports to Game Center (`newly` is false when it was unlocked already). An id that App Store Connect does not have is `unknownId`, listing the ids it has. |
| `achievements.list()` | The catalog's achievements with what the player reached. |
| `achievements.reset()` | Resets *every* achievement of the player (development). |
| `leaderboards.submit(id, score)`, `.entries(id, {range, count})` | The all-time board, or the period's ("Leaderboard periods": a recurring board at its current occurrence, with `periodStart` and `periodEnd`; a classic one with the `.today` / `.week` scope). `range`: `"top"`, `"around"` (empty until the player has a score) or `"friends"`. `best` is the player's best including this score. |
| `cloud.save/load/list/remove` | One iCloud key-value key per cloud key; the value is stored as JSON text. Over 1 MB or 1024 keys: `failed`. No iCloud account or no entitlement: `unavailable`. Syncing between devices is iCloud's (seconds to minutes); `load` reads what this device has. |
| `cloud.stat(key)` | `{ exists, size }` of the key's JSON text; `modified` is always `null` because the iCloud key-value store keeps no time for a key: keep a revision counter in the saved value to tell which save is newer ("Which save is newer"). |
| `purchases.products(ids?)` | The product's `displayName`, `description`, `displayPrice` (the player's storefront), price value, currency and type. A product the store does not know is left out, with a warning in the log that says how to create it. |
| `purchases.buy(id)` | Shows the purchase sheet. `purchased` (with `transactionId` and the JWS `receipt`), `cancelled`, or `pending` (Ask to Buy). `notAllowed` when Screen Time forbids purchases. The call waits as long as the player takes with the sheet, but gives up after 30 s when the App Store never shows it. |
| `purchases.finish(transactionId)` | `Transaction.finish()`. The id must come from a `buy()` result, a `purchase` event or a `restore()` entry of this run. |
| `purchases.restore()` | Syncs with the App Store (it may ask for the Apple Account password) and returns the verified entitlements: non-consumables and active subscriptions. |
| `overlay.open(page, id?)` | Opens the Game Center dashboard on the page (an `id` goes straight to that achievement or leaderboard on iOS 18 / macOS 15). Needs a signed-in player. |

**Events.** `purchase` for a transaction that did not come from `buy()`: an Ask to Buy approval, a purchase made on another
device, a subscription renewal, or a purchase the last run did not finish. Those arrive right after the game starts, before a
script could listen, so the engine keeps the ones nobody listens for (up to 100) and hands them to the first
`platform.on("purchase", ...)`: register it in `onStart`, grant, then `finish`. `overlay` `{open}` when the Game Center
dashboard opens and closes. `player` when the Game Center sign-in changes (also when the player signs out in Settings while
the game runs).

**Refunds, expired subscriptions and unverified transactions.** A revoked (refunded) or expired transaction is finished and
never delivered. A transaction whose signature does not verify on the device is *not* delivered and not finished (the log
says so): a modified device or a missing StoreKit test certificate, never a purchase to grant.

### Receipts are JWS documents

The `receipt` of a purchase is the transaction as a **JWS** (the compact text `header.payload.signature`), signed by Apple.
The device has verified it (StoreKit 2 delivers only verified transactions to the game). A game with real money at stake
(server-side goods, an online economy) must verify it again **on its server** before granting: check the signature against
the certificate chain in the header (`x5c`, ending at Apple's root CA), then read `productId`, `transactionId`,
`originalTransactionId`, `bundleId` and `environment` (`"Sandbox"`, `"Xcode"` or `"Production"`) from the payload. Apple's
App Store Server Library (Swift, Java, Node and Python) does the verification, and the App Store Server API looks a
transaction up by its `transactionId` and sends refund notifications. A single-player game that trusts the device can ignore
the receipt.

### Testing purchases without App Store Connect

`factoria export --platform ios` writes **`Products.storekit`** next to the Xcode project whenever the catalog has products (the
Apple plugin does not have to be declared or built): a
StoreKit configuration file made from `platform.products` (consumables and non-consumables as such; a subscription as a
monthly auto-renewable product in one subscription group; the prices and titles of the catalog; ids = `ids.apple`, else
`id`). Every product gets one localization per language of the game (`localization.languages`): its name and description come
from the product's `titleKey` / `descriptionKey` in `locales/<language>.json` (a key a language lacks falls back to the default
language, then to the catalog's plain `title` / `description`; a plural entry gives its `other` form), so the sheet Xcode shows
follows the simulator's language. `build_ios.sh` wires it into the project's scheme, so **running the project from Xcode** sells exactly those products,
with no App Store Connect, sandbox account, network or provisioning, and `Debug > StoreKit > Manage Transactions` approves or
fails purchases and simulates Ask to Buy, refunds and renewals. If the scheme shows "StoreKit Configuration: None", pick the
file under Product > Scheme > Edit Scheme > Run > Options. The file is rewritten at every export: edit the catalog, not the
file. Launching the app any other way (`build_ios.sh --run`, `simctl launch`, the home screen of a device) does not use it;
products then come from the App Store (sandbox for development-signed builds, TestFlight for TestFlight builds). Game Center
has no such file: a sign-in needs a real or sandbox Apple Account (on the simulator: Settings > Game Center).

### When something does not work: `apple.status`

The plugin registers the command **`apple.status`** (from a script: `fa.call("apple.status", {})`): whether a Game Center
player is signed in, whether this device may make payments, whether iCloud is signed in and, on macOS, whether the app
carries the entitlements, with a `problems` list of sentences that say what to fix. When StoreKit or Game Center cannot talk to
Apple at all (an app that is not signed with a development team, or run outside Xcode without a StoreKit file), the calls
reject `unavailable` with a hint that points here.

| Situation | What the game gets |
|---|---|
| Not signed in to Game Center | `notSignedIn` ("Sign in under Settings > Game Center..."). |
| Achievement or leaderboard missing in App Store Connect | `unknownId`, with the ids that exist. |
| Product missing in App Store Connect | `unknownId` from `buy`; `products()` leaves it out and logs the steps (Paid Apps Agreement, product id). |
| Purchases restricted by Screen Time | `notAllowed`. |
| No answer from Apple in 30 s (restore: 120 s) | `network`. |
| iCloud signed out, or the entitlement missing | `unavailable` (cloud saves), naming the entitlement. |
| Apple's servers cannot be reached | `network`. |

### Manual checks

These need App Store Connect, a development-signed build and a sandbox account, so no automated test runs them. The tests
cover what needs none of that: the plugin registers in a real engine and answers every request once, in time, with a
teaching error; the exports write the frameworks, entitlements and `Products.storekit`; the iOS Simulator job builds and
launches an app with the plugin linked. Before a release, on a device with a sandbox account:

1. `platform.signIn()` shows the sheet once; `platform.player` and the `player` event follow it; `platform.backend` is `"apple"`.
2. An achievement unlocks (banner on screen), a half-way `progress` is kept, `list()` shows both, `reset()` clears them.
3. A score reaches the board (`submit`), and `entries` returns it for `"top"`, `"around"` and `"friends"`.
4. `overlay.open` opens the dashboard for each page, with `overlay` events at open and close.
5. A consumable: `buy`, grant, `finish`, buy again. A non-consumable: `buy`, then `restore()` on a second device or after
   reinstalling. A subscription: `buy`, then `restore()`. Ask to Buy: `pending`, then the approval arrives as a `purchase`
   event.
6. Kill the app after a `buy` and before `finish`: the next run delivers the purchase as a `purchase` event.
7. `cloud.save` on one device, `cloud.load` on another with the same iCloud account.

Record what a real check finds in `ENGINE_FEEDBACK.json`.

## 7. Google Play: Billing, Play Games Services and Play Integrity

The backend `"googleplay"` is a plugin with a C bridge and a Java Gradle module (`platforms/plugins/googleplay`, written into
the game by `platform.add_backend`) for **Android on a device with Google Play** (the game's `minSdk`, 26 by default). It answers `platform` with:

| Service | Google's API | Notes |
|---|---|---|
| `purchases` | Play Billing 9.1 | consumables, non-consumables and subscriptions; pending payments; refunds. Always on. |
| `overlay` | Play Games / Play Store | `"achievements"` and `"leaderboards"` (Play Games screens) and `"store"` (the game's Play Store page). Always on; `"friends"` is `unavailable`. |
| `integrity` | Play Integrity 1.6 | a token that vouches for the app and the device: the generic service, this is its Android backend. Always on. |
| `achievements`, `leaderboards` | Play Games Services v2 22.1 | the sign-in prompt, Google's banners, all-time, daily and weekly public / around the player / friends boards. **Only with a Play Games project id** (below). |
| `cloudSave` | Play Games Saved Games | one snapshot per cloud key. **Only with a Play Games project id.** |

Play Games has no stats and no presence: `platform.has("stats")` and `platform.has("presence")` are false and the engine
answers those calls `unavailable`. Keep the numbers you need in `cloud.save` or on a leaderboard. Without a project id,
`platform.has("achievements")`, `"leaderboards"` and `"cloudSave"` are false too, and `platform.signIn()` answers signed out.

### Setup, in one command

```bash
factoria call platform.add_backend '{"backend": "googleplay", "playGamesId": "123456789012"}'
```

It writes the plugin to `plugins/googleplay` from its template and declares it for Android in factoria.json (unless it is
declared already), writes the Play Games project id to the plugin's `android/src/main/res/values/games-ids.xml`, and builds the
C bridge for `arm64-v8a` and `x86_64` with the **Android SDK's NDK, CMake and Ninja** (the SDK that
[the export](../exporting/EXPORTING_MOBILE.md#android) uses: `ANDROID_HOME` / `ANDROID_SDK_ROOT`, else Android Studio's default folder). It uses
NDK `27.2.12479018` and CMake `3.31.6` when installed, else the newest installed with a note in `done`, and builds against
the game's `minSdk` (`export.android.minSdk`, 26 by default). The libraries land in `android/src/main/jniLibs/<abi>/`. Without
an SDK or an NDK the command stops before writing anything, says which is missing and how to install it (`sdkmanager
"ndk;27.2.12479018"`), and offers `googleplayBuild: false`.

| Argument | Meaning |
|---|---|
| `playGamesId` | The Play Games Services project id (digits: Play Console > Play Games Services > Setup and management > Configuration). Kept as it is when not passed; `""` turns Play Games off. A build without it offers `purchases`, `overlay` and `integrity` only. Export again after changing it. |
| `googleplayBuild` | `false` only writes and declares the plugin, to build later where the NDK is installed (the plugin's README has the commands). |

The result lists the built `libraries` and `nextSteps`, with the ids of your catalog filled in. What only a person can do:

1. **Play Console**: create the app with the package name of factoria.json's `id`, upload a signed build to a testing track
   (`factoria export --platform android --format aab`; internal testing is enough) and add your Google account under
   Settings > License testing. Billing and Play Integrity answer only for an app Play knows, and the app must be installed
   from the track's opt-in link, not with `adb`.
2. **Products** (Monetize with Play > Products): one-time products and subscriptions (with a base plan), each with
   **exactly** the id of the catalog (`ids.googleplay`, else `id`) and active. Google's rule for product ids: lowercase
   letters, digits, `_` and `.`, starting with a letter or digit, at most 40 characters; the command lists the ones that break it.
3. **Play Games Services** (only for achievements, leaderboards and cloud saves): create the project, add an Android credential
   for the package name with the SHA-1 of the key the build is signed with (the upload key for `adb` installs, the Play App
   Signing key for builds from Play), turn **Saved Games** on for cloud saves, and add yourself as a tester while the project is
   unpublished. Then pass its id as `playGamesId`.
4. **Achievements and leaderboards**: create them in that project. Play generates their ids (they start with `CgkI`): copy each
   into `ids.googleplay` of the catalog entry. A leaderboard's sort order must match the catalog's `order` (Play fixes it at creation).
5. **Play Integrity**: link a Google Cloud project in Play Console > Test and release > App integrity. A token is decoded
   **on your server** with Google's `decodeIntegrityToken`, never on the device.

Then export with `factoria export --platform android`: the exported Gradle project builds the plugin's module, which pulls
Billing, Play Games and Play Integrity from Google's Maven repository, and merges its manifest ([MOBILE.md](../mobile/MOBILE_ANDROID.md#native-plugins-on-android)).
The plugin's manifest removes Play Games' automatic initializer: the plugin starts the SDK itself, and only when a project id is
set.

### What each call does

Google answers with its own ids: the engine maps the catalog ids to the `ids.googleplay` (else `id`) of each entry, and back.

| Call | On Google Play |
|---|---|
| `platform.signIn()` | Play Games signs the player in by itself when the app starts (a `player` event follows when it does). `signIn()` shows Google's sign-in prompt if the player is not signed in, and resolves `{ id, name, signedIn }` (`id` is the Play Games player id). A player who declines gets `notSignedIn`. Without a project id it resolves signed out, without any prompt. |
| `achievements.unlock(id)`, `.progress(id, fraction)` | Reports to Play Games (`newly` is false when it was unlocked already). `progress` needs an **incremental** achievement (else `failed`, saying how to make it one); 1 unlocks it. An id that Play Console does not have is `unknownId`, listing the ids it has. |
| `achievements.list()` | The catalog's achievements with what the player reached (an achievement Play does not have is reported locked, with a warning in the log). |
| `achievements.reset()` | `unavailable`: a game cannot reset achievements on Google Play. Use a fresh test account, or the Play Games management API from your own tooling. |
| `leaderboards.submit(id, score)` | The all-time board, or the daily or weekly one for a board with a `period` ("Leaderboard periods"). `best` is the player's best in that table including this score. |
| `leaderboards.entries(id, {range, count})` | `range`: `"top"`, `"around"` or `"friends"` (the player must allow friends in the Play Games app, else `notAllowed`). **At most 25 rows** per call: a larger `count` is cut to 25. The board's sort order is the one set in Play Console; the catalog's `order` is not sent. |
| `cloud.save(key, data)`, `cloud.load(key)`, `cloud.list()`, `cloud.remove(key)` | One Saved Games snapshot per cloud key, named after it (Play allows letters, digits and `- . _ ~`, up to 100 characters: every key the engine accepts fits). The value is stored as JSON text. `load` of a key that does not exist is `null` (a script gets `undefined`). When two devices saved the same key, the most recently modified save wins. Saved Games not turned on in Play Console: `unavailable`. |
| `cloud.stat(key)` | `{ exists, size, modified }`: the snapshot's last-modified time (`getLastModifiedTimestamp`, in Unix seconds) and the size of its data. Play has no call for the size alone, so `stat` **opens the snapshot and reads its bytes to count them** (it does not return them to the game, and closes it without saving); it costs about as much as `cloud.load`. A key with no snapshot is `{ exists: false }`. The last-modified time is the clock of the device that saved ("Which save is newer"). |
| `purchases.products(ids?)` | The product's title, description, price text (the player's currency), price value, currency and type. A product Google does not know is left out, with a warning in the log that says how to create it. A subscription shows the price of its base plan's renewing phase. |
| `purchases.buy(id)` | Shows Google's purchase sheet. `purchased` (with `transactionId` and `receipt`), `cancelled`, or `pending` (a payment that needs time: cash, a parent's approval). The call waits as long as the player takes with the sheet, but gives up after 30 s when Google answers nothing. |
| `purchases.finish(transactionId)` | A consumable is **consumed** (it can be bought again), a non-consumable or a subscription is **acknowledged**. Google **refunds a purchase that is not acknowledged within three days**: grant, then finish. The id must come from a `buy()` result, a `purchase` event or a `restore()` entry of this run. |
| `purchases.restore()` | Returns what the player owns: non-consumables and active subscriptions of the catalog (consumables are used up). Waits up to 120 s. |
| `overlay.open(page, id?)` | `"achievements"`: Google's achievements screen. `"leaderboards"`: all boards, or the one of `id`. `"store"`: the game's page in the Play Store app (a browser when there is none). The first two need Play Games on. |
| `integrity.token(...)` | Asks Google for an integrity token for the challenge your server made (the Play Integrity nonce: URL-safe Base64, 16 to 500 characters, as section 2 says). Needs Google Play services and a Play Store; for an app that Play did not install it answers `unavailable` (`APP_NOT_INSTALLED`). |

**Events.** `purchase` for a purchase that did not come from `buy()`: a pending payment that completed, a purchase made on
another device, a subscription renewal, or a purchase the last run did not finish. The plugin looks for them when the game
starts and **every time the game comes back to the front** (Google gives no push for them), once per purchase and state;
the engine keeps the ones nobody listens for (up to 100) and hands them to the first `platform.on("purchase", ...)`:
register it in `onStart`, grant, then `finish`. `overlay` `{open}` when a Google screen opens (Play Games or the Play Store)
and when the game is back in front. `player` when the Play Games player is known at start or changes.

**Refunds.** A refunded or cancelled purchase is no longer reported by Google, so it is not delivered or restored; a game
that must take goods back tracks refunds on its server (the Google Play Developer API's voided purchases).

### Receipts

The `transactionId` of a purchase is Google's **purchase token**. The `receipt` is the JSON text
`{"signedData": "<the purchase as Google signed it>", "signature": "<base64>"}`: `signedData` holds `packageName`,
`productId`, `purchaseToken`, `orderId` and the purchase time, and `signature` is checked with the licence key of the app
(Play Console > Monetize with Play > Monetization setup). A game with real money at stake (server-side goods, an online
economy) must verify the receipt **on its server** before granting: either verify the signature with the licence key, or
send the `purchaseToken` and `productId` to the Google Play Developer API (`purchases.products.get`, or
`purchases.subscriptionsv2.get`), which answers with the purchase state and whether it was acknowledged. A single-player game
that trusts the device can ignore the receipt.

### Testing purchases

Billing answers only for an app that Play knows, so a purchase needs a Play Console app, a build on a testing track, a license
tester account, and the app installed from Play. `adb install` builds and emulators without the Play Store cannot buy:
the calls then reject `unavailable` with a hint that names what is missing. A license tester pays nothing (the sheet says
"test card, always approves"), and Play Console lists the test orders. For everything but buying, a debug build installed with
`adb` is enough: Play Games works once the project knows the debug key's SHA-1 (add it as a second credential).

### When something does not work: `googleplay.status`

The plugin registers the command **`googleplay.status`** (from a script: `fa.call("googleplay.status", {})`): the package and
who installed it, Google Play services and Play Store versions and whether they are usable, the Billing connection, whether
Play Games is on (with the project id) and who is signed in, the services on offer, and a `problems` list of sentences that
say what to fix. Run it first.

| Situation | What the game gets |
|---|---|
| No Google Play services (an emulator image without the Play icon, a device without Google) | `unavailable`, naming Google Play services and how to get a device or image that has it. Purchases and Integrity are `unavailable` too. |
| Player not signed in to Play Games | `notSignedIn` from `signIn()` (the player declined), and from the calls that need a player. The hint explains the tester rule of an unpublished project. |
| Play Games project not set up (wrong id, missing credential or SHA-1) | `failed`, with a hint that lists the three things to check. |
| Achievement or leaderboard missing in Play Console | `unknownId` for an achievement (the message lists the ids Play has). A leaderboard id that Play does not know often comes back as an internal error of Play Games: the hint says to check `ids.googleplay` against Play Console. |
| Product missing in Play Console, or the app unknown to Play | `unknownId` from `buy`; `products()` leaves it out and logs the steps. `DEVELOPER_ERROR` is `failed`, listing the usual causes (no test track, another signing key, product inactive). |
| Billing not available (no Play Store, no Google account, an unsupported country) | `unavailable`. |
| The player already owns a non-consumable | `failed`, pointing at `restore()`. |
| No answer from Google in 30 s (restore: 120 s) | `network`. |
| Google's servers cannot be reached | `network`. |
| `reset()`, a `"friends"` overlay, stats, presence | `unavailable`. |

### CI and manual checks

CI builds the C bridge for both ABIs, exports the plugin and checks that the APK carries both libraries, the plugin's classes
(with Billing, Play Games and Play Integrity linked into the dex) and the merged manifest; the emulator job (an Android image
with **no** Google Play) then starts that APK and checks that the plugin registered the backend in a real engine, that
`googleplay.status` answers and that `signIn()` and `integrity.token` are answered through the C bridge and the Java code
with a teaching `unavailable` (the table at the top of [MOBILE.md](../MOBILE.md)). The tests of the tooling cover the setup command (the NDK lookup, the project id, the `nextSteps`).
What needs a Play Console app, a signed build and Google accounts is checked by hand before a release, on a phone with Google
Play, the build installed from the internal testing track:

1. `platform.backend` is `"googleplay"`; `googleplay.status` has an empty `problems` list.
2. `platform.signIn()` shows the prompt once; `platform.player` and the `player` event follow it.
3. An achievement unlocks (Google's banner on screen); a half-way `progress` of an incremental one is kept, `list()` shows
   both. `overlay.open("achievements")` shows them, with `overlay` events at open and close.
4. A score reaches the board (`submit`), and `entries` returns it for `"top"`, `"around"` and `"friends"`.
5. A consumable: `buy`, grant, `finish`, buy again. A non-consumable: `buy`, then `restore()` after reinstalling. A subscription:
   `buy`, then `restore()`. A slow payment method: `pending`, then the completion arrives as a `purchase` event.
6. Kill the app after a `buy` and before `finish`: the next run delivers the purchase as a `purchase` event.
7. `cloud.save` on one phone, `cloud.load` on another with the same Google account.
8. `integrity.token` returns a token that your server can decode.

Record what a real check finds in `ENGINE_FEEDBACK.json`.
