# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases

One script API, `platform`, for what a store gives a game: **achievements**, **stats**, **leaderboards**, **cloud
saves**, **in-app purchases**, the store **overlay** and **rich presence**. A game is written once against it; a backend
decides what answers: the **fake** store (development and every test), **none** (an exported game that has no store
plugin), or a store SDK that a native plugin wraps (Steam: [below](#steam-steamworks); Apple: a later M12 package).

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
| Steam (Steamworks) | Done: the `steam` plugin, [below](#steam-steamworks). |
| Apple (StoreKit 2 and Game Center) | Coming in the next M12 packages. |

### Store backends: one command sets them up

`factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`) does the setup of a store backend in one call:
it writes the backend's plugin from its template (`project.new_plugin` with `"template": "<backend>"`) unless
factoria.json already declares it, builds it for this computer with CMake (the CMake `setup` installs when there is
none), and adds what that store needs. Running it again keeps what is there. Its result lists what it did (`done`) and
what only a person can do (`nextSteps`: store dashboards, accounts). Each backend's section says what it adds and which
arguments it reads.

### Steam (Steamworks)

The `steam` plugin (`platforms/plugins/steam` in the engine, the `"steam"` template of `project.new_plugin`) answers the
game's `platform.*` calls with Valve's Steamworks API: achievements, stats, leaderboards, Steam Cloud, DLC purchases, the
overlay and rich presence. It holds **no Valve code or header**: it loads Valve's redistributable library at run time and
calls its flat C API.

**Set it up** with one call, then `factoria run`:

```bash
factoria call platform.add_backend '{"backend": "steam", "sdk": "~/Downloads/steamworks_sdk_162.zip"}'
```

It writes `plugins/steam/` from the template and declares it for Windows, macOS and Linux, builds it with CMake for this
computer, copies Valve's three libraries from the SDK next to it, and writes `steam_appid.txt` (see below). Running it
again keeps what is there. The Steamworks SDK is a download from Valve (partner.steamgames.com/downloads/list, a free
Steamworks account); its license does not let FactorIA ship its files, so you supply them.

| Argument | Meaning |
|---|---|
| `sdk` | The SDK as a folder or its `steamworks_sdk_*.zip` (relative paths start in the project folder, `~/` works). Without it the build is made and the libraries are a `nextSteps` item. |
| `appId` | Your game's Steam app id for `steam_appid.txt`. Without it an existing file is kept, else it gets **480**, Valve's test app. |

By hand (what `plugins/steam/README.md` describes): `project.new_plugin {"name": "steam", "template": "steam"}`, build the plugin,
copy the library of each platform next to the plugin's, write `steam_appid.txt`.

| Platform | Plugin (built for it) | Valve's library, in the same folder |
|---|---|---|
| Windows | `windows/steam.dll` | `steam_api64.dll` (SDK: `redistributable_bin/win64/`) |
| macOS | `macos/libsteam.dylib` | `libsteam_api.dylib` (`redistributable_bin/osx/`) |
| Linux | `linux/libsteam.so` | `libsteam_api.so` (`redistributable_bin/linux64/`) |

The plugin was written against the flat API of **Steamworks SDK 1.58 to 1.64** and finds the interfaces by their versioned
names; a library from an SDK it does not know is refused with a message that says so. Only the 64-bit libraries are used.
The export copies the plugin's whole folder for the platform, so Valve's library ships next to it.

**steam_appid.txt.** In development Steam learns which game this is from a `steam_appid.txt` (a number) in the project
folder. `add_backend` writes **480** (Spacewar, Valve's test app: any Steam account can run it, and it has achievements,
stats and a leaderboard to try). For your own game put its app id there and sign in to an account that owns it. The
plugin hands the number to Steam; **`factoria export` never copies `steam_appid.txt`**, because a game started from the
Steam client gets its app id from Steam, and a shipped file would make it run as the wrong game. (A shipped game that is
started outside Steam cannot start Steam and runs without platform services.)

**Starting.** When the plugin loads it opens the library, starts Steam (`SteamAPI_InitFlat`, `SteamAPI_Init` on an older
library), and takes over Steam's callbacks (manual dispatch: it calls Steam once per engine frame itself, never
`SteamAPI_RunCallbacks`). `SteamAPI_Shutdown` runs when the process ends (not on Windows, where the DLL's exit handlers run
after Steam's own DLL is gone; Steam notices the process ending, and stats are stored every frame anyway). When Steam
cannot start (it is not running, there is no app id, the library is missing or from another SDK) the plugin **logs why, with
what to do**, and the game falls back: the fake backend in a development run, **none** in an exported game.
`factoria call platform.state` shows the backend and `why`; `factoria call steam.status` shows what the plugin found (app id and
where it came from, player, library and interface versions, overlay, Cloud).

Every engine that loads the plugin starts Steam, because a plugin cannot know which backend the engine will pick: that includes
`factoria test`, `factoria call` and the MCP server on a game that declares it. They still answer `platform.*` with the fake
store and never touch Steam's data, but a running Steam client shows you as playing the game, and a computer without Steam
(CI) logs the warning above (only a log line: the run goes on with the fake store).

**Catalog ids** (`ids.steam` of each entry in `factoria.json`, section 1):

| Catalog | `ids.steam` is | Without it |
|---|---|---|
| achievements | the achievement's **API Name** (Steamworks partner site, App Admin > Stats & Achievements), e.g. `ACH_WIN_ONE_GAME` | the catalog `id` |
| stats | the stat's **API Name**; its type there (int or float) must be the catalog's `type` | the catalog `id` |
| leaderboards | the leaderboard's name; created on first use with the catalog's `order` when it does not exist | the catalog `id` |
| products | the **app id of the DLC** (the number in its store page's URL) | not a DLC: the product is left out and a warning says how to fix it |

**What each call does on Steam**

| Call | On Steam |
|---|---|
| `signIn()` | `{ id: SteamID, name: persona name, signedIn: whether Steam is online }`. |
| `achievements.unlock(id)` | `SetAchievement` then `StoreStats`; `newly` is false when Steam had it. |
| `achievements.progress(id, f)` | At `1` unlocks. Below it shows Steam's "n of 100" notice (`IndicateAchievementProgress`); Steam keeps real progress in the stat behind the achievement, so set that stat too. |
| `achievements.list()` | `GetAchievement` for each catalog entry (one Steam does not have shows locked, with a warning). `progress` is 0 or 1. |
| `achievements.reset()` | `ResetAllStats` including achievements: development only. |
| `stats.get / set` | Int and float stats. A set is stored by the next frame (several sets in a frame are one `StoreStats`; Steam limits how often it may be called). Int stats are 32-bit. |
| `leaderboards.submit(id, score)` | Uploads keeping the player's best; `best` is what Steam kept. Scores are 32-bit. |
| `leaderboards.entries(id, {range, count})` | `top`: ranks 1 to `count`. `around`: the player in the middle. `friends`: the player and friends (Steam gives them all; at most `count` are returned). Names are Steam persona names. |
| `cloud.save / load / list / remove` | Steam Cloud files named `<key>.json`. Needs Cloud enabled for the app (partner site, App Admin > Cloud) and for the account; otherwise `unavailable`, saying which. A file is up to 100 MB; the app's quota applies. |
| `purchases.products(ids?)` | Steam's DLC list for the app, by the products' `ids.steam`: `title` is the DLC's name; `price` is `""` (Steam gives a DLC's price on its store page, not here), `priceValue` null. |
| `purchases.buy(id)` | Owned already: `purchased` with the transaction `dlc-<appid>`. Not owned: the overlay opens the DLC in a cart and the answer is `pending`; when the player owns it, a `purchase` event follows. A consumable or a subscription is `unavailable` (below). |
| `purchases.restore()` | The non-consumable products whose DLC the player owns. |
| `purchases.finish(txn)` | Nothing to do on Steam: resolves. |
| `overlay.open(page, id?)` | `achievements` and `friends`: that overlay page. `store`: the DLC's store page for a product, else the game's own. `leaderboards`: the game's leaderboards page on Steam Community (Steam has no overlay page for them). `unavailable` when Steam says the overlay is off. |
| `presence.set(text, data?)` | Rich presence: `text` is the key `status`, each `data` key is sent as it is (`connect`, `steam_display`...), and what was shown before is replaced. Steam allows 30 keys of 64 bytes with values of 256. |

**Events**: `overlay` (`{open}`, Steam's `GameOverlayActivated`), `purchase` (a DLC the player got, from the overlay or another
computer: Steam's `DlcInstalled`), `player` (Steam went online or offline).

**DLC, not microtransactions.** Steam sells a game's extras as **DLC**, which is what `nonConsumable` products map to. Steam's
other mechanism, microtransactions (`ISteamMicroTxn`), needs your own server calling Valve's web API and cannot start
from the client, so **consumables and subscriptions are `unavailable` on Steam**, with a message that says so. Sell a
consumable as a DLC that grants it once, or keep the shop on the stores that have it. (Steam Inventory, Steam's service for
items, is not wrapped either.)

**Limits worth knowing.** Stat and achievement changes reach Steam when stored (every frame that set one, and at exit on macOS and
Linux); an offline player's are kept by Steam and sent later. There is no `achievements.onUnlocked` event. A Steam Cloud
file holds the JSON text of one key. Steam Input, workshop, networking, and inventory are not wrapped.

**Steam Deck.** The Deck is a Linux machine with the controller as a gamepad (the engine names its buttons like an Xbox pad).
Today the release `factoria_player` for Linux needs glibc 2.38 and does not start in the Steam Linux Runtime "sniper" (glibc
2.31; M13 in feedback/ROADMAP.md), so a Deck release waits for that, or ships the Windows build through Proton. **The Deck's
on-screen keyboard for a `TextField` is not wired:** Steam's `ShowGamepadTextInput` and `ShowFloatingGamepadTextInput` would
have to be called when a text field takes focus, and the plugin API has no hook for that (M12 "Left open" in
feedback/ROADMAP.md). Until then players type with the keyboard Steam opens by itself (Steam button + X).

**Troubleshooting.** The plugin's messages say what to do; the usual ones:

| The log says | Do |
|---|---|
| `The Steamworks library ... was not found` | Copy Valve's library next to the plugin (`add_backend` with `sdk` does it). |
| `Steam is not running, or the game has no app id` | Start the Steam client and sign in; check `steam_appid.txt` is in the project folder and holds a number. |
| `The Steam client is older than the Steamworks library` | Update Steam (Steam menu > Check for Steam Client Updates), or use an older SDK's library. |
| `has none of the interface accessors this plugin knows` | The library is from an SDK newer or older than 1.58 to 1.64: use one of those. |
| `The Steamworks library ... cannot be loaded` | It is not the 64-bit library of this OS (or it is damaged). On macOS a library that came through a browser may be quarantined: `xattr -d com.apple.quarantine <file>`. |
| `Steam Cloud is not enabled for app N` | Enable it in the partner site (App Admin > Cloud) and publish; for 480 it may simply be off. |
| `The Steam overlay is not available` | In Steam: Settings > In Game > Enable the Steam Overlay. It loads a few seconds after start and needs the game to draw with a graphics API Steam hooks. |

**Manual check with Valve's test app 480.** The tests of the plugin run against a mock of Steam's library (`ctest`:
`steam_plugin_*`); this is the check against the real Steam, which needs a Steam client and a free account. Do it on each
desktop OS you ship.

1. Install Steam, sign in, leave it running. (The Deck: switch to Desktop Mode, or run it from a terminal with Steam open.)
2. `factoria new steamcheck && cd steamcheck`, then download the Steamworks SDK zip and run
   `factoria call platform.add_backend '{"backend": "steam", "sdk": "<the zip>"}'`. `steam_appid.txt` now holds `480`.
3. In `factoria.json` add the catalog (Spacewar's names):
   ```json
   "platform": {
     "achievements": [{ "id": "first_win", "name": "First win", "ids": { "steam": "ACH_WIN_ONE_GAME" } }],
     "stats": [{ "id": "wins", "type": "int", "ids": { "steam": "NumWins" } }, { "id": "feet", "type": "float", "ids": { "steam": "FeetTraveled" } }],
     "leaderboards": [{ "id": "feet_board", "name": "Feet", "ids": { "steam": "Feet Traveled" } }],
     "backend": "steam"
   }
   ```
4. `factoria call steam.status`: it prints `"appId": 480`, `"appIdFrom": "steam_appid.txt in ..."`, your Steam name, and
   `"statsLoaded": true`. (If it fails, the log says why, see Troubleshooting.)
5. Add `scripts/check.js` and an entity with `"Script": { "path": "scripts/check.js" }` to `scenes/main.scene.json`:
   ```js
   import { Behaviour, platform } from "factoria";
   export default class Check extends Behaviour {
     async onStart() {
       console.log("backend", platform.backend);                                       // steam
       console.log("player", JSON.stringify(await platform.signIn()));
       console.log("unlock", JSON.stringify(await platform.achievements.unlock("first_win")));
       console.log("wins", await platform.stats.add("wins", 1));
       console.log("board", JSON.stringify(await platform.leaderboards.submit("feet_board", 1000)));
       console.log("top", JSON.stringify(await platform.leaderboards.entries("feet_board", { count: 3 })));
       console.log("save", JSON.stringify(await platform.cloud.save("check", { n: 1 })));
       await platform.presence.set("Checking Steam", { score: "1" });
     }
   }
   ```
6. `factoria run`. In the log: `steam: Steam is ready: app 480`, `backend steam`, your player, `unlock {"id":"first_win","unlocked":true,"newly":true}`
   (`newly` is false on a second run: reset it with `platform.achievements.reset()`), `wins` one higher each run, your score in
   `board`. A `cloud.save` may answer `unavailable` for app 480 if Valve has Cloud off for it; that message is the correct answer.
7. Open Steam's overlay in the game window (Shift+Tab): with the window focused it must open, and the game receives the
   `overlay` event. Call `platform.overlay.open("achievements")` from the script: it opens the overlay's achievements page.
   (The engine draws with Direct3D 11 on Windows, Metal on macOS and OpenGL on Linux: note in ENGINE_FEEDBACK.json on which of
   them the overlay does not appear.)
8. In Steam, your friends list shows "Checking Steam" under your name while the game runs.
9. In Steam's own page for the achievement (Library > Spacewar > Achievements, or `steamcommunity.com/stats/480/achievements`),
   "Win a game" shows unlocked.
10. Export: `factoria export --platform <this OS>`; the exported folder holds the plugin and Valve's library, **no**
    `steam_appid.txt`. Start the exported game from a terminal with Steam running: without an app id Steam refuses to start
    it, the log says so, and the game runs with no platform services (`platform.backend` is `none`). For the final check, a
    game started by the Steam client gets its app id from Steam: upload a build to your own app with SteamPipe (app 480 takes no
    uploads) and start it from the Steam library.

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
