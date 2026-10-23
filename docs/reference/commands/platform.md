[Back to the index](../README.md)

# Commands: platform

## `platform.add_backend` (modifies state)

Since 0.2.0.

Set up a store backend for this game: its plugin, its build and what the store needs.

One call instead of the manual steps of docs/PLATFORM.md ("Store backends"): writes the backend's plugin from its template (project.new_plugin with template = backend) unless factoria.json already declares it, builds it for this computer with CMake, and adds what that store needs. steam: the Steamworks plugin (achievements, stats, leaderboards, Cloud saves, DLC purchases, overlay, rich presence): writes it, builds it for this computer, copies Valve's redistributable libraries from the Steamworks SDK ("sdk": its folder or .zip) next to it for Windows, macOS and Linux, and writes steam_appid.txt ("appId", default Valve's test app 480) for development. apple: the StoreKit 2, Game Center and iCloud plugin for iOS and macOS (Swift: it builds on a Mac with Xcode). googleplay: the Google Play Billing, Play Games Services and Play Integrity plugin for Android (a C bridge and a Java module; it builds with the Android SDK's NDK). Run it again after a change: it keeps what is there. Returns {backend, folder, done[], nextSteps[]}: nextSteps lists what only a person can do (store dashboards, accounts). factoria.json is patched, not rewritten: only the plugins.<backend> key is added, and the other keys, their order and the layout stay as they are. With `dryRun` true nothing is written, built or copied: the result is {backend, dryRun: true, folder, files[] (what it would write), keys[] (the factoria.json keys it would write), wouldDo[], nextSteps[]}. An argument that does not exist is an error with a "did you mean" (backend-specific ones like sdk or appId are listed above and are accepted for every backend). Example: {"backend": "steam", "appId": 480}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `sdk` | string | no | (steam) The Steamworks SDK: its folder, or the steamworks_sdk_*.zip from partner.steamgames.com/downloads/list (a free Steamworks account). Valve's redistributable libraries are copied from it next to the plugin. Without it they are not copied: nextSteps says where to put them. Relative paths start in the project folder. |
| `appId` | integer | no | (steam) Your game's Steam app id, written to steam_appid.txt for development. Without it an existing steam_appid.txt is kept, else the file gets 480, Valve's test app (Spacewar), which any Steam account can run. |
| `appleSlices` | array | no | apple: which libraries to build: macos (the .dylib of a Mac app), iphoneos (an iPhone or iPad) and iphonesimulator (the iOS Simulator). Default: all three. |
| `appleBuild` | boolean | no | apple: false only writes the plugin and declares it, without building (any computer); build it later on a Mac with Xcode: cmake -S plugins/apple -B plugins/apple/build && cmake --build plugins/apple/build. Default true. |
| `playGamesId` | any | no | googleplay: the Play Games Services project id (digits: Play Console > Play Games Services > Setup and management > Configuration), written to android/src/main/res/values/games-ids.xml. Without it the backend offers purchases, the store page and Play Integrity, and no achievements, leaderboards or cloud saves. Kept as it is when not passed; "" turns Play Games off. Export again after changing it. |
| `googleplayBuild` | boolean | no | googleplay: false only writes the plugin and declares it, without building (any computer); build it later where the Android NDK is installed. Default true. |
| `backend` | string ["steam","apple","googleplay"] | yes | The store backend to set up; it is also the plugin's name. |
| `dryRun` | boolean | no | true = write, build and copy nothing: list the files and factoria.json keys it would write (files, keys) and the steps (wouldDo). Default false. |

## `platform.emit` (modifies state)

Since 0.2.0.

Send an event to the game as the store would: a purchase, the overlay opening or closing, a sign-in change.

`event` is "purchase" ({productId, status?: "purchased" | "pending" | "cancelled" (default purchased), transactionId?, receipt?}; a purchased one also records an unfinished transaction, made up when not given), "overlay" ({open: bool}) or "player" ({id?, name?, signedIn}). Scripts get it through platform.on(event, fn) at the start of the next frame (game.step). Fails when the game runs a real store backend. Example: platform.emit {"event":"overlay","data":{"open":true}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `event` | string ["purchase","overlay","player"] | yes | The event name. |
| `data` | object | no | The event's data. Default {}. |

## `platform.reset` (modifies state)

Since 0.2.0.

Reset the fake platform backend: nothing unlocked, bought or saved, no scripted answers, signed in, an empty request log.

Also numbers transactions from fake-1 and integrity tokens from fake-integrity-1 again. Pending requests are not cancelled. Fails when the game runs a real store backend (the message says which and why). Tests start every file with a fresh fake already; use this between tests that share state. Example: platform.reset {}

## `platform.respond` (modifies state)

Since 0.2.0.

Script the next answer(s) the fake platform backend gives to a method: an error, an exact result, or a change to the default.

`method` is a platform method such as "purchases.buy" (docs/PLATFORM.md lists them all). `answer` is one of {"error": "network", "message"?, "hint"?} to reject (codes: unavailable, notSignedIn, notAllowed, unknownId, network, failed), {"result": value} to resolve with exactly that value, or any other object, which is merged into the default result: {"status": "cancelled"} cancels a purchase (and buys nothing). Answers are used first in, first out, one per request; `times` queues the same answer several times. Fails when the game runs a real store backend. Example: platform.respond {"method":"purchases.buy","answer":{"status":"cancelled"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `method` | string | yes | The platform method, e.g. "purchases.buy", "achievements.unlock", "cloud.save". |
| `answer` | object | yes | {error, message?, hint?} \| {result} \| an object merged into the default result. |
| `times` | integer | no | How many requests get this answer. Default 1. |

## `platform.revoke` (modifies state)

Not released yet (on main after 0.2.0).

Take a purchase back in the fake platform backend, as a refund does, and send the game the event a real store would.

The product leaves purchases.restore() and its unfinished transaction is dropped; the game gets a "purchase" event {status: "revoked", productId, transactionId, receipt} at the start of the next frame (game.step), which platform.on("purchase", fn) listeners receive. Fails when the player owns no such product (the message lists the owned ones) or when the game runs a real store backend. Example: platform.revoke {"productId":"remove_ads"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `productId` | string | yes | The catalog id of the product to take back, e.g. "remove_ads". |

## `platform.set_ad` (modifies state)

Not released yet (on main after 0.2.0).

Script what the fake platform backend's test ad does: watched to the end, closed early, no ad to show, or consent refused.

`outcome` decides how every ads.showRewarded() ends until changed (and platform.reset): "watched" (the default: {rewarded: true}), "closedEarly" ({rewarded: false, reason: "closedEarly"}), "noFill" (no ad: ads.available() is false and showRewarded gives reason "noFill") or "consentRefused" (also sets gdpr and tracking to "denied"; reason "consentRefused"). `gdpr` ("granted", "denied", "notRequired", "unknown") and `tracking` ("authorized", "denied", "notDetermined", "restricted", "notRequired") are what ads.consent() answers; a denied gdpr stops every ad. Give any of them. platform.state's fake.ads counts the ads shown and rewarded. Fails when the game runs a real store backend. Example: platform.set_ad {"outcome":"closedEarly"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `outcome` | string ["watched","closedEarly","noFill","consentRefused"] | no | How the next ads end. |
| `gdpr` | string ["granted","denied","notRequired","unknown"] | no | What the GDPR (UMP) sheet answered. |
| `tracking` | string ["authorized","denied","notDetermined","restricted","notRequired"] | no | What the tracking (ATT) sheet answered. |

## `platform.set_fake` (modifies state)

Since 0.2.0.

Change how the fake platform backend behaves: signed in or out, and how many frames it holds its answers.

`signedIn: false` makes every method but player.signIn answer notSignedIn (and sends a `player` event); `delayFrames: n` holds each answer for n engine frames (0, the default, answers at once), so a test can look at the "waiting" state of a screen and game.step() until the answer arrives. Give any of them. `backend: "none"` makes the fake behave as the none backend (platform.has false for every service, every call rejects `unavailable`, signIn answers signed out) until platform.reset. Fails when the game runs a real store backend. Example: platform.set_fake {"delayFrames":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `signedIn` | boolean | no | false: the player is not signed in. |
| `backend` | string ["fake","none"] | no | "none": behave as the none backend until platform.reset. |
| `delayFrames` | integer | no | Frames each answer is held (0 = at once). |

## `platform.state`

Since 0.2.0.

Show which platform backend runs, its services, the player, the declared ids and, for the fake backend, everything it holds.

Returns {backend, why, services, player: {id, name, signedIn}, catalog: {achievements, stats, leaderboards, products, placements} (the ids factoria.json "platform" declares), pending (requests waiting for an answer), fake?} where `fake` (only when the backend is the fake) is {signedIn, delayFrames, frame, achievements: {id: {unlocked, progress}}, stats: {id: value}, leaderboards: {id: best} (a daily or weekly board: "id@periodKey"), cloud: {key: text}, owned: [productId], unfinished: [{transactionId, productId, receipt}], presence: {text, data}, ads: {outcome, gdpr, tracking, shown, rewarded}, scripted: {method: answers queued}, held, calls: [{seq, frame, method, args, ok, result | error, scripted?}], callsDropped}. `calls` is every request the game made, with the arguments the backend got (store ids included) and how it was answered: assert on it after game.step. Example: platform.state {}

