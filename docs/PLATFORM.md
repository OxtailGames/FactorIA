# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases

One script API, `platform`, for what a store gives a game: **achievements**, **stats**, **leaderboards**, **cloud
saves**, **in-app purchases**, the store **overlay** and **rich presence**. A game is written once against it; a backend
decides what answers: the **fake** store (development and every test), **none** (an exported game that has no store
plugin), or a store SDK that a native plugin wraps (Steam, Apple: later M12 packages).

```js
import { platform } from "factoria";

if (platform.has("achievements")) platform.achievements.unlock("first_win").catch(() => {}); // best effort
const bought = await platform.purchases.buy("gems_100"); // a Promise: the store answers when it answers
if (bought.status === "purchased") {
  addGems(100);
  await platform.purchases.finish(bought.transactionId); // grant first, finish after
}
```

[MENUS.md](MENUS.md) has a shop built on it, and `tests/platform.test.js` of that kit drives it against the fake store.
Do not confuse `platform` (this API) with `game.platform` of the `factoria` module (the operating system's name:
`"windows"`, `"ios"`...) and with `game.platform` of `factoria:test` (the fake store's test hooks, below).

## 1. The catalog: `"platform"` in factoria.json

A game declares what it uses. The engine checks every id against it before a request leaves the game, so a typo is an
error with a "did you mean", not a silent failure inside a store SDK. Every section is optional.

```json
"platform": {
  "achievements": [
    { "id": "first_win", "name": "First win", "description": "Win one match.", "hidden": false,
      "ids": { "steam": "ACH_WIN_ONE_GAME", "apple": "com.studio.game.first_win" } }
  ],
  "stats": [ { "id": "wins", "type": "int", "ids": { "steam": "NumWins" } } ],
  "leaderboards": [ { "id": "high_score", "name": "High score", "order": "descending", "ids": { "apple": "high_score_v2" } } ],
  "products": [
    { "id": "gems_100", "type": "consumable", "title": "100 gems", "price": 0.99, "currency": "USD",
      "ids": { "apple": "com.studio.game.gems100" } },
    { "id": "remove_ads", "type": "nonConsumable", "title": "Remove ads", "price": 2.99 }
  ],
  "backend": "auto"
}
```

| Field | Meaning |
|---|---|
| `id` | What scripts pass to `platform.*`: `A-Z a-z 0-9 _ . -`, 1 to 64 characters, unique in its section. |
| `ids` | The id each store uses for the same thing: `{"steam": "ACH_WIN_ONE_GAME"}`. The key is the backend's name; without an entry the store id is `id`. |
| achievements | `name` (required), `description`, `hidden` (default false). |
| stats | `type`: `"int"` (default) or `"float"`. An int stat takes whole numbers. |
| leaderboards | `name` (required), `order`: `"descending"` (higher is better, default) or `"ascending"` (lower is better: times). |
| products | `type`: `"consumable"`, `"nonConsumable"` or `"subscription"` (required), `title` (required), `description`, `price` (a number, `currency` default `"USD"`). Only the fake store uses `price`: real stores give their own, localized. |
| `backend` | Which backend plugin to use: `"auto"` (default), a plugin's name, or one per platform: `{"windows": "steam", "macos": "steam", "linux": "steam", "ios": "apple"}`. See section 5. |

`factoria validate` reports every problem of the section (`factoria.json#/platform/products/1/type: "consumable " is
not a product type; use one of "consumable", "nonConsumable", "subscription" (did you mean "consumable"?)`), and a
`backend` that names a plugin the project does not declare. At run time a section with errors counts as empty (each
call then says its id is not declared) and the engine logs why.

## 2. The script API

`import { platform } from "factoria"`. **Every call returns a Promise.**

| Call | Resolves with |
|---|---|
| `platform.backend` | The name of the backend that runs: `"fake"`, `"none"`, `"steam"`... (the plugin's name). |
| `platform.has(service)` | Whether the backend offers the service: `"achievements"`, `"stats"`, `"leaderboards"`, `"cloudSave"`, `"purchases"`, `"overlay"`, `"presence"`. Check it before using a service that a store may not have. |
| `platform.player` | The last known `{ id, name, signedIn }` (empty and signed out until the store tells). |
| `platform.signIn()` | `{ id, name, signedIn }`. Always allowed. |
| `platform.on(event, fn)` | Returns a function that removes the listener. Events: below. |
| `platform.achievements.unlock(id)` | `{ id, unlocked: true, newly }` (`newly` is false when it was unlocked already). |
| `platform.achievements.progress(id, fraction)` | `{ id, progress, unlocked }`. `fraction` is 0 to 1; 1 unlocks. |
| `platform.achievements.list()` | `[{ id, unlocked, progress }]`, the whole catalog. |
| `platform.achievements.reset()` | Development: clears every achievement. |
| `platform.stats.get(id)` | The number. |
| `platform.stats.set(id, value)` | The new value. An int stat needs a whole number. |
| `platform.stats.add(id, delta)` | The new value (a get, then a set: not atomic). |
| `platform.leaderboards.submit(id, score)` | `{ id, score, best }`; `best` is the player's best after this. The score is a whole number. |
| `platform.leaderboards.entries(id, { range = "top", count = 10 })` | `[{ rank, name, score, playerId, isPlayer }]`. `range`: `"top"`, `"around"` (the player's neighbours) or `"friends"`; `count` 1 to 100. |
| `platform.cloud.save(key, value)` | `{ key, bytes }`. `value` is anything JSON can hold. Keys: `A-Z a-z 0-9 _ . -`, up to 64 characters. |
| `platform.cloud.load(key)` | The value, or `undefined` when there is no such key. |
| `platform.cloud.list()` / `.remove(key)` | `["key", ...]` / nothing. |
| `platform.purchases.products(ids?)` | `[{ id, title, description, price, priceValue, currency, type }]` as the store shows them. `price` is text for the player's country (`"$0.99"`). A product the store does not know is left out. |
| `platform.purchases.buy(id)` | `{ status, productId, transactionId, receipt }`. `status` is `"purchased"`, `"pending"` (Ask to Buy: it arrives later as a `purchase` event) or `"cancelled"`. `transactionId` and `receipt` only when purchased. |
| `platform.purchases.finish(transactionId)` | Nothing. Tells the store the game granted the purchase. |
| `platform.purchases.restore()` | `[{ productId, transactionId, receipt }]`: what the player owns that does not get used up (non-consumables, active subscriptions). |
| `platform.overlay.open(page, id?)` | Opens the store's own screen: `page` is `"achievements"`, `"leaderboards"`, `"friends"` or `"store"`; `id` narrows it to one achievement, leaderboard or product. |
| `platform.presence.set(text, data?)` | "What the player is doing" for friends. `data`: an object whose values are strings. |

**Purchases: grant, then finish.** A store keeps a purchase "unfinished" until the game calls `finish`, and hands it over
again on the next run. Grant what was bought first, finish after, and remember the `transactionId`s you granted so the
same purchase never pays twice. Consumables (gems) are not remembered by the store after `finish`; non-consumables
(Remove ads) come back from `restore()`, which a "Restore purchases" button must offer on Apple platforms.

### Events

`platform.on(event, fn)`; the listeners run at the start of an engine frame, never in the middle of a script call, and
are cleared when a scene loads (register them in `onStart`).

| Event | Data | When |
|---|---|---|
| `"purchase"` | `{ status, productId, transactionId, receipt }` | A transaction that did not come from a `buy()` call: Ask to Buy approved, an unfinished purchase from an earlier run, a purchase made in the store itself. One that arrives before any listener exists is kept and delivered to the first `platform.on("purchase", ...)`: a paid purchase is never lost. |
| `"overlay"` | `{ open }` | The store's overlay opened or closed. Games pause while it is open (`scripts/store_events.js` in [MENUS.md](MENUS.md)). |
| `"player"` | `{ id, name, signedIn }` | The sign-in state changed. `platform.player` follows it. |

### Mistakes throw, store failures reject

- A mistake in the call throws **at once**, before anything is sent: an id the catalog does not declare (with a "did
  you mean" and where to declare it), a wrong argument type, an unknown service or event.
  `platform.achievements.unlock("first_wn"): "first_wn" is not an achievement of this game (did you mean "first_win"?);
  declare it in factoria.json platform.achievements`.
- A failure of the store **rejects** the Promise with an `Error` that has `.code` and `.hint`; the message reads
  `platform.purchases.buy("gems_100") failed: <what> (hint: <how to fix>)`. Handle the rejection, or the engine reports
  it as an unhandled script error.

| `e.code` | Meaning |
|---|---|
| `unavailable` | No backend, or it does not offer that service. Check `platform.has("<service>")` first. |
| `notSignedIn` | The player is not signed in. Every call but `signIn()` needs it. |
| `notAllowed` | Purchases are disabled or restricted (parental controls). |
| `unknownId` | The store does not know the id the catalog maps to. |
| `network` | The store could not be reached. Offer a retry. |
| `failed` | Anything else; the message says what. |

Achievements, stats and presence are best effort: end those calls with `.catch(() => {})`. Purchases are not: show the
player what happened (`e.hint`) and grant nothing.

## 3. The fake store, and testing with it

The fake backend runs in development and in **every** headless run: `factoria test`, `factoria call`, `factoria
session`, the MCP server. It is deterministic (no clock, no random numbers), keeps everything in memory, offers all seven
services, and starts afresh in each test file. The defaults are plausible successes: the player is signed in as
`{ id: "fake-player", name: "Player", signedIn: true }`; `buy` answers `purchased` with the transaction `fake-1`,
`fake-2`... and the receipt `fake-receipt-1`...; the purchase stays unfinished until `finish`; consumables are never
"owned"; `products()` takes title and price from the catalog (`$0.99`, or `2.99 EUR`); a leaderboard shows the player's
own best. `await` works in tests, and an answer is ready at once, without `game.step()`.

`import { game } from "factoria:test"` gives `game.platform`, the store's controls:

| Call | Does |
|---|---|
| `game.platform.respond(method, answer, times = 1)` | Queues the answer of the next `times` calls of `method` (`"purchases.buy"`; first come, first served). `answer` is `{ error: "network", message?, hint? }` to fail, `{ result: value }` to answer exactly that, or fields merged into the default result: `{ status: "cancelled" }`. A cancelled buy owns nothing. |
| `game.platform.emit(event, data)` | Sends `"purchase"`, `"overlay"` or `"player"` to the `platform.on` listeners at the next `game.step()`. An emitted purchased `purchase` is also an unfinished transaction. |
| `game.platform.set({ signedIn, delayFrames })` | `signedIn: false` makes every call but `signIn()` reject `notSignedIn`. `delayFrames: n` holds every answer for `n` engine frames: a test can see the "waiting" state, then `game.step(n)`. |
| `game.platform.state()` | The backend, services, player, the catalog's ids, the number of pending requests, and `fake`: achievements, stats, leaderboards, cloud, owned, unfinished, presence, and `calls`, the log of every request (`{ seq, frame, method, args }`). |
| `game.platform.calls()` | `state().fake.calls`. |
| `game.platform.reset()` | A fresh fake: signed in, no delay, nothing owned, no scripted answers, an empty log. |

```js
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";

test("a cancelled purchase grants nothing, a retry works", async () => {
  game.platform.respond("purchases.buy", { status: "cancelled" });
  expect((await platform.purchases.buy("gems_100")).status).toBe("cancelled");
  expect(game.platform.state().fake.unfinished).toEqual([]);

  game.platform.respond("purchases.buy", { error: "network", hint: "Check the connection." }); // once
  await platform.purchases.buy("gems_100").catch((e) => expect(e.code).toBe("network"));

  const ok = await platform.purchases.buy("gems_100");
  expect(ok.transactionId).toBe("fake-1");
  await platform.purchases.finish(ok.transactionId);
  expect((await platform.achievements.unlock("big_spender")).newly).toBe(true);
  expect(game.platform.state().fake.achievements.big_spender.unlocked).toBe(true);
});

test("the store overlay pauses the game", () => {
  game.platform.emit("overlay", { open: true });
  game.step(1);
  // ... your game paused itself in platform.on("overlay", ...)
});
```

The same controls are commands, for MCP clients and `factoria call` (they work on the fake only, and say which backend
runs when it is another): `platform.state`, `platform.reset`, `platform.respond {method, answer, times}`,
`platform.emit {event, data}`, `platform.set_fake {signedIn, delayFrames}`.

## 4. Which backend runs

| Run | Backend |
|---|---|
| `factoria run`, the editor's Play | The backend plugin the game declares for this platform. None: the **fake** (an info line in the log says so: purchases are not real). |
| `factoria test`, `factoria call`, `factoria session`, MCP, any headless run | Always the **fake**. Tests never touch a store. |
| An exported game (`factoria_player`) | The backend plugin. None: **none**, so an exported game never gets free purchases from the fake. |

With **none**, `platform.has(...)` is false for every service and every call rejects `unavailable`. `signIn()` answers
signed out.

Choosing a plugin: one loaded plugin that registered a backend is used. Several: `"platform": { "backend": "steam" }`
(or one per platform) picks, otherwise the first by name with a warning that lists them. A `backend` that names a plugin
that did not load falls back as above and logs why. `factoria call platform.state` shows `backend` and `why`.

| Backend | Status |
|---|---|
| `fake` | Done. Development and tests. |
| `none` | Done. Exported games without a store plugin. |
| Steam (Steamworks) | Coming in the next M12 packages. |
| Apple (StoreKit 2, Game Center, iCloud) | Done: iOS and macOS, `platform.add_backend {"backend": "apple"}`, [section 6](#6-apple-storekit-2-game-center-and-icloud). |

### Store backends: one command sets them up

`factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`) does the setup of a store backend in one call:
it writes the backend's plugin from its template (`project.new_plugin` with `"template": "<backend>"`) unless
factoria.json already declares it, builds it for this computer with CMake (the CMake `setup` installs when there is
none), and adds what that store needs. Running it again keeps what is there. Its result lists what it did (`done`) and
what only a person can do (`nextSteps`: store dashboards, accounts). Each backend's section says what it adds and which
arguments it reads.

## 5. Writing a backend plugin

A [native plugin](EXTENDING.md#g-native-plugins-cc-for-one-game) becomes a backend with the **plugin API version 2**:
`add_backend`, and `resolve`, `reject` and `emit` to answer. (`factoria call project.new_plugin` copies `fa_plugin.h`;
a version 1 plugin keeps working, and one built for version 2 checks `api->version >= 2`.)

```c
#include <string.h>
#include "fa_plugin.h"

static const FaPluginApi* g_api;

// Called for every request of the game, on the game's thread. Answer once with resolve() or reject(): now, or later
// from any thread (a store SDK's callback). The engine has checked the ids and filled in "storeId".
static void on_request(FaRequest* req, const char* method, const char* args_json, void* user) {
    if (strcmp(method, "achievements.unlock") == 0) {
        // args_json: {"id":"first_win","storeId":"ACH_WIN_ONE_GAME"} -> call the SDK with storeId...
        g_api->resolve(req, "{\"id\":\"first_win\",\"unlocked\":true,\"newly\":true}");
    } else {
        g_api->reject(req, "unavailable", "this backend does not do that", "Check platform.has(service) first.");
    }
}

static void on_frame(void* user) { /* once per frame, before scripts: SteamAPI_RunCallbacks() */ }

FA_PLUGIN_INIT(mystore) {
    g_api = api;
    FaBackendDesc backend = {"mystore", "[\"achievements\"]", on_request, on_frame, NULL};
    return api->add_backend(api, &backend);   // 0 = done; one backend per plugin
}
```

- `name` is what the catalog's `ids` are keyed by (`"ids": {"mystore": "..."}`); `services` is a JSON array of the
  services the backend offers. A request for another service is answered `unavailable` by the engine: the backend never
  sees it.
- A `FaRequest*` is a token: answer it **exactly once**. A second answer, or one for a game that has ended, is ignored
  (and logged once). `resolve`, `reject` and `emit` may be called from any thread; the game gets the answer at the
  start of its next frame.
- `resolve` takes JSON text; text that is not JSON fails the request with `failed`. `reject` takes one of the codes of
  section 2 (`unavailable`, `notSignedIn`, `notAllowed`, `unknownId`, `network`, `failed`; anything else becomes
  `failed`), a message that says what went wrong and a hint that says how to fix it.
- `emit(api, "purchase" | "overlay" | "player", data_json)` reaches `platform.on` in the running game.
- Strings passed to the engine are copied. A handler never lets an exception leave.

**The contract.** The backend gets `(method, args)` and answers with the result below. `id` is the catalog id,
`storeId` the id that store uses (`ids` of the catalog, else `id`). A purchase result names its product in `productId`
(`id` or `storeId` work too); the engine turns the store's id back into the catalog's before the game sees it, and
the `id`s in an `achievements.list` or `purchases.products` answer the same way.

| Method | The backend gets | It answers |
|---|---|---|
| `player.signIn` | `{}` | `{ id, name, signedIn }` |
| `achievements.unlock` | `{ id, storeId }` | `{ id, unlocked: true, newly }` |
| `achievements.progress` | `{ id, storeId, progress }` | `{ id, progress, unlocked }` |
| `achievements.list` | `{ achievements: [{ id, storeId }] }` | `[{ id, unlocked, progress }]` |
| `achievements.reset` | `{ achievements: [{ id, storeId }] }` | `{}` |
| `stats.get` | `{ id, storeId, type }` | `{ id, value }` |
| `stats.set` | `{ id, storeId, type, value }` | `{ id, value }` |
| `leaderboards.submit` | `{ id, storeId, order, score }` | `{ id, score, best }` |
| `leaderboards.entries` | `{ id, storeId, order, range, count }` | `[{ rank, name, score, playerId, isPlayer }]` |
| `cloud.save` | `{ key, data }` (`data` is JSON text) | `{ key, bytes }` |
| `cloud.load` | `{ key }` | `{ key, data }`, or `null` when there is no such key |
| `cloud.list` | `{}` | `["key", ...]` |
| `cloud.remove` | `{ key }` | `{}` |
| `purchases.products` | `{ products: [{ id, storeId, type }] }` | `[{ id, title, description, price, priceValue, currency, type }]` |
| `purchases.buy` | `{ id, storeId, type }` | `{ status, productId, transactionId, receipt }` |
| `purchases.finish` | `{ transactionId, id, storeId, type }` | `{}` |
| `purchases.restore` | `{ products: [{ id, storeId, type }] }` | `[{ productId, transactionId, receipt }]` |
| `overlay.open` | `{ page, id?, storeId? }` | `{}` |
| `presence.set` | `{ text, data }` | `{}` |

The C++ side is `fa/services/platform.h` (`PlatformBackend`, `PlatformServices`, `platform_methods()` with this table)
and `fa/runtime/platform_backend.h` (the plugin adapter and the choice of backend). The fake backend
(`fa/services/fake_platform.h`) is the reference implementation of every row.

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
the Swift runtime, entitlements: [MOBILE.md](MOBILE.md#native-plugins-ios), [EXTENDING.md](EXTENDING.md#g2-the-declaration)).
**iOS**: the Xcode project links StoreKit, GameKit and the Swift runtime and is signed with the entitlements
(`factoria_player.entitlements`; set `export.ios.teamId` or `FA_IOS_DEVELOPMENT_TEAM` so Xcode can sign for a device).
**macOS**: Game Center and iCloud are *restricted* entitlements, which macOS only honours in an app signed with your Apple
Developer certificate and a provisioning profile. The export is signed ad hoc, so it runs, and those services answer
`unavailable` with a hint; the export also writes `<game>.entitlements` and lists the `codesign` command that turns them on
(`nextSteps`). An ad hoc app also gets no answers from the App Store: try purchases from Xcode (below) or after that signing step.

### What each call does

| Call | On Apple |
|---|---|
| `platform.signIn()` | Starts Game Center's authentication: a sheet the first time, a welcome banner after. Resolves `{ id, name, signedIn }` (`id` is the `gamePlayerID`, stable for this game). A player who is not signed in gets `notSignedIn` with a hint (sign in under Settings > Game Center). With no sheet and no answer it ends after 20 s; a sheet on screen waits for the player. |
| `achievements.unlock(id)`, `.progress(id, fraction)` | Reports to Game Center (`newly` is false when it was unlocked already). An id that App Store Connect does not have is `unknownId`, listing the ids it has. |
| `achievements.list()` | The catalog's achievements with what the player reached. |
| `achievements.reset()` | Resets *every* achievement of the player (development). |
| `leaderboards.submit(id, score)`, `.entries(id, {range, count})` | The all-time board. `range`: `"top"`, `"around"` (empty until the player has a score) or `"friends"`. `best` is the player's best including this score. |
| `cloud.save/load/list/remove` | One iCloud key-value key per cloud key; the value is stored as JSON text. Over 1 MB or 1024 keys: `failed`. No iCloud account or no entitlement: `unavailable`. Syncing between devices is iCloud's (seconds to minutes); `load` reads what this device has. |
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

`factoria export --platform ios` writes **`Products.storekit`** next to the Xcode project when the catalog has products: a
StoreKit configuration file made from `platform.products` (consumables and non-consumables as such; a subscription as a
monthly auto-renewable product in one subscription group; the prices and titles of the catalog; ids = `ids.apple`, else
`id`). `build_ios.sh` wires it into the project's scheme, so **running the project from Xcode** sells exactly those products,
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
