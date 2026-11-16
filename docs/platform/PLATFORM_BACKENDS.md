# Store and platform services: achievements, stats, leaderboards, cloud saves, purchases, page 2 of 4

Part of [Store and platform services: achievements, stats, leaderboards, cloud saves, purchases](../PLATFORM.md) (the entry page lists every page).

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

**Ads have a backend of their own.** A plugin whose backend offers only `["ads"]` is an **ads backend**: it is chosen apart
from the store backend and works next to it. The engine sends `ads.*` to the ads backend and everything else to the store
backend; with no ads plugin, `ads.*` goes to the store backend when that offers ads (the fake does). Several ads plugins:
`"platform": { "ads": { "backend": "admob" } }` picks, otherwise the first by name with a warning. `platform.state` shows
`adsBackend` and `adsWhy` next to `backend` and `why`. A development run or a test never uses an ads plugin: it keeps the fake,
and `adsWhy` says so.

**So does `http.fetch`.** The engine serves it with the system's HTTP client in every run that is not headless, a test,
`factoria call`, `session` or MCP (those use the fake, which never reaches the network); no plugin can offer it, and a
plugin that lists `"http"` among its services is refused with a message that says so. `platform.state` shows
`httpBackend` (`"nsurlsession"`, `"winhttp"`, `"curl"`, `"httpurlconnection"`, `"fetch"` or `"fake"`), `httpWhy` and the declared
`networkHosts`. [NETWORKING.md](../NETWORKING.md) has the rest.

| Backend | Status |
|---|---|
| `fake` | Done. Development and tests. |
| `none` | Done. Exported games without a store plugin. |
| Steam (Steamworks) | Done: the `steam` plugin, [below](#steam-steamworks). |
| Apple (StoreKit 2, Game Center, iCloud) | Done: iOS and macOS, `platform.add_backend {"backend": "apple"}`, [section 6](PLATFORM_APPLE_GOOGLE.md#6-apple-storekit-2-game-center-and-icloud). |
| Google Play (Billing, Play Games Services, Play Integrity) | Done: Android, `platform.add_backend {"backend": "googleplay"}`, [section 7](PLATFORM_APPLE_GOOGLE.md#7-google-play-billing-play-games-services-and-play-integrity). |
| AdMob (Google's consent form UMP, rewarded ads) | Done: Android and iOS (no ads on macOS), an ads backend, `platform.add_backend {"backend": "admob"}`, [section 8](PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios). |

### Store backends: one command sets them up

`factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`, `"googleplay"` or the ads backend `"admob"`) does the setup of a
backend in one call: it writes the backend's plugin from its template (`project.new_plugin` with `"template":
"<backend>"`) unless factoria.json already declares it, builds it for this computer with CMake (the CMake `setup`
installs when there is none; the Google Play and AdMob bridges are built with the Android SDK's NDK instead), and adds what that
store needs. Running it again keeps what is there. It patches factoria.json instead of rewriting it (only `plugins.<backend>` is added; the other keys, their order and the layout stay as they are). `"dryRun": true` writes, builds and copies nothing and lists the `files` and factoria.json `keys` it would write (`wouldDo` has the steps); an argument it does not know is an error with a "did you mean". Its result lists what it did (`done`) and what only a person can do
(`nextSteps`: store dashboards, accounts). Each backend's section says what it adds and which arguments it reads.

### Steam (Steamworks)

The `steam` plugin (`platforms/plugins/steam` in the engine, the `"steam"` template of `project.new_plugin`) answers the
game's `platform.*` calls with Valve's Steamworks API: achievements, stats, leaderboards, Steam Cloud (with the size and
time of a file), DLC purchases, the overlay, rich presence and the guests of Remote Play Together. It holds **no Valve code or header**: it loads Valve's redistributable library at run time and
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

The plugin was checked against the flat API of **Steamworks SDK 1.58 to 1.64**. It calls the flat functions by name (they do
not change with the interface versions) and finds the interfaces by their versioned accessors (`SteamAPI_SteamUtils_v010`...):
the versions of those SDKs first, then the five versions above the newest it knows. **A newer SDK is used, with one warning**
that names the interfaces newer than the plugin was checked against (and `steam.status` lists them as `newerInterfaces`), as
long as every function the plugin calls is present. That covers **SDK 1.65** (July 2026): it changed ISteamUtils
(`IsRunningOnSteamDeck` gave way to `IsRunningOnSteamHardware`; the plugin calls neither), so its library is expected to
export a newer accessor than 1.64's. Only a library with a function the plugin needs missing (a later SDK renamed or removed it), or with interface
versions more than five above the known ones, or from an SDK older than 1.58, is refused, with a message that lists what was
tried. If a newer SDK misbehaves, put the redistributable of SDK 1.64 next to the plugin, or update the plugin. (The tests use
a mock of Steam's library with a newer accessor for each interface; none ran against a real 1.65 library.) Only the 64-bit
libraries are used. The export copies the plugin's whole folder for the platform, so Valve's library ships next to it.

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
what to do** (a warning, not an error: `project.new_plugin` and `platform.add_backend` declare the plugin `optional`), and the game falls back: the fake backend in a development run, **none** in an exported game.
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
| `leaderboards.submit(id, score)` | Uploads keeping the player's best; `best` is what Steam kept. Scores are 32-bit. A daily or weekly board is the Steam board `<name> <periodKey>` ("Leaderboard periods"). |
| `leaderboards.entries(id, {range, count})` | `top`: ranks 1 to `count`. `around`: the player in the middle. `friends`: the player and friends (Steam gives them all; at most `count` are returned). Names are Steam persona names. |
| `cloud.save / load / list / remove` | Steam Cloud files named `<key>.json`. Needs Cloud enabled for the app (partner site, App Admin > Cloud) and for the account; otherwise `unavailable`, saying which. A file is up to 100 MB; the app's quota applies. |
| `cloud.stat(key)` | The file's size (`GetFileSize`) and Steam's own time for it (`GetFileTimestamp`, Unix seconds); `{ exists: false }` when Steam has no such file. Same `unavailable` as the other cloud calls when Cloud is off. |
| `remotePlay.sessions()` | `ISteamRemotePlay`: the sessions Steam lists now (`GetSessionCount`, `GetSessionID`), each with the guest's SteamID and persona name, the device's name and form factor, and its resolution (`null` when Steam gives none). The service is offered only when the Steam library exports `ISteamRemotePlay` (the plugin tries `SteamAPI_SteamRemotePlay_v002`, then `_v001`): `steam.status` lists `ISteamRemotePlay v00N` among the interfaces when it does. |
| `purchases.products(ids?)` | Steam's DLC list for the app, by the products' `ids.steam`: `title` is the DLC's name; `price` is `""` (Steam gives a DLC's price on its store page, not here), `priceValue` null. |
| `purchases.buy(id)` | Owned already: `purchased` with the transaction `dlc-<appid>`. Not owned: the overlay opens the DLC in a cart and the answer is `pending`; when the player owns it, a `purchase` event follows. A consumable or a subscription is `unavailable` (below). |
| `purchases.restore()` | The non-consumable products whose DLC the player owns. |
| `purchases.finish(txn)` | Nothing to do on Steam: resolves. |
| `overlay.open(page, id?)` | `achievements` and `friends`: that overlay page. `store`: the DLC's store page for a product, else the game's own. `leaderboards`: the game's leaderboards page on Steam Community (Steam has no overlay page for them). `unavailable` when Steam says the overlay is off. |
| `presence.set(text, data?)` | Rich presence: `text` is the key `status`, each `data` key is sent as it is (`connect`, `steam_display`...), and what was shown before is replaced. Steam allows 30 keys of 64 bytes with values of 256. |

**Events**: `overlay` (`{open}`, Steam's `GameOverlayActivated`), `purchase` (a DLC the player got, from the overlay or another
computer: Steam's `DlcInstalled`), `player` (Steam went online or offline), `remotePlay` (a guest connected or disconnected:
Steam's `SteamRemotePlaySessionConnected_t` and `SteamRemotePlaySessionDisconnected_t`). The disconnect callback carries
only the session id, so the plugin keeps the description it read while the guest was connected and puts it in the event;
sessions that were connected before the game started are read at start-up, and no event announces them.

**DLC, not microtransactions.** Steam sells a game's extras as **DLC**, which is what `nonConsumable` products map to. Steam's
other mechanism, microtransactions (`ISteamMicroTxn`), needs your own server calling Valve's web API and cannot start
from the client, so **consumables and subscriptions are `unavailable` on Steam**, with a message that says so. Sell a
consumable as a DLC that grants it once, or keep the shop on the stores that have it. (Steam Inventory, Steam's service for
items, is not wrapped either.)

**Limits worth knowing.** Stat and achievement changes reach Steam when stored (every frame that set one, and at exit on macOS and
Linux); an offline player's are kept by Steam and sent later. There is no `achievements.onUnlocked` event. A Steam Cloud
file holds the JSON text of one key. What is wrapped: sign-in and the persona name, achievements, stats, leaderboards, Steam
Cloud files (save, load, list, remove, stat), DLC, the overlay, rich presence, the Deck keyboard and Deck detection, and
the Remote Play guest list and its connect and disconnect events. Not wrapped: Steam Input, workshop, networking, inventory,
and Remote Play's other half (inviting someone with `BSendRemotePlayTogetherInvite`, the guests' own controller or mouse
settings). Of Remote Play only what the list above says is read.

**Tested against a mock only.** The plugin's tests (`steam_plugin_*`) run against a mock of Steam's library that checks
every call's signature, so the `cloud.stat` and Remote Play code paths are exercised, but no real Steam client, real Cloud
file or real Remote Play session has been tried. The manual check below does not cover them yet: until somebody runs a Remote Play
session (a second computer or the Steam Link app on a phone) and a `cloud.stat` on app 480 and writes down what Steam
answered, treat the `modified` of a Cloud file and the exact `formFactor` and `resolution` of a session as unverified.

**Steam Deck.** The Deck is a Linux machine with the controller as a gamepad (the engine names its buttons like an Xbox pad).
The release `factoria_player` for Linux is built in the Steam Linux Runtime "sniper" container (glibc 2.31, libstdc++
linked in; `scripts/build-sniper.sh`, docs/design/BUILDING.md, repository only, not in the binary), and CI runs it there, so a Linux export runs in the runtime Steam
gives Linux games, on the Deck included (pick "Steam Linux Runtime 3.0 (sniper)" in the Steamworks partner site); the
Windows build through Proton is the alternative.

**Steam Deck detection.** The Steam plugin answers `game.device.steamDeck` (and `handheld`) from `IsSteamRunningOnSteamDeck`, which is
certain; when the game runs without Steam the `SteamDeck=1` environment variable decides, and `SteamDeck=0` turns it off.

**Gamepad ids.** `input.gamepad(i).id` and `game.on("gamepadConnected")` give each pad a stable id: Windows XInput has none, so it
is "an Xbox pad in XInput slot N", and a Windows HID pad (DualShock, DualSense, Switch Pro, generic pads, read through Raw
Input) uses vendor, product, name and the serial number it reports; Linux uses vendor, product, name and the kernel `uniq` serial, and the slot is the `jsN`
number; macOS, iOS and the web (Gamepad.id) use the name, the web also vendor and product; Android adds the InputDevice
descriptor. See docs/SCRIPTING.md, "Pads plugged in and out".

**Steam Deck keyboard.** On a Steam Deck, and in Big Picture on any computer (`IsSteamRunningOnSteamDeck` or
`IsSteamInBigPictureMode`), a `TextField` that takes the focus while the last input came from a gamepad gets Steam's own
keyboard (plugin API 3, [section 5](#5-writing-a-backend-plugin)). The plugin first tries the **floating** keyboard
(`ShowFloatingGamepadTextInput`): Steam draws it over the game next to the field, whose rectangle the plugin passes in window
pixels, and types into the window as key presses, so the field fills as with a real keyboard and sends `ui.change` as usual.
Where Steam does not offer it, the plugin opens the **full-screen** one (`ShowGamepadTextInput`, with the field's text and
`maxLength`); when the player confirms, the text comes back (`GamepadTextInputDismissed_t`, `GetEnteredGamepadTextInput`) and
replaces the field's text (cut to `maxLength`, `ui.change` sent); cancelling changes nothing. The floating keyboard is taken
down when the field loses the focus, and pressing A on the focused field opens it again. While Steam's keyboard has the
field, `input.platformKeyboard` is true and the menu kit's on-screen keyboard stays closed; a game's own keyboard can read
the same flag. On a desktop Steam nothing changes: the player has a keyboard, and a pad uses the kit's on-screen keyboard.
Steam's keyboard is single line and not a password field because `TextField` has neither yet. If Steam refuses both
keyboards the plugin logs one warning and the game's own keyboard is used.

**Troubleshooting.** The plugin's messages say what to do; the usual ones:

| The log says | Do |
|---|---|
| `The Steamworks library ... was not found` | Copy Valve's library next to the plugin (`add_backend` with `sdk` does it). |
| `Steam is not running, or the game has no app id` | Start the Steam client and sign in; check `steam_appid.txt` is in the project folder and holds a number. |
| `The Steam client is older than the Steamworks library` | Update Steam (Steam menu > Check for Steam Client Updates), or use an older SDK's library. |
| `has none of the interface accessors this plugin can use` | The library is from an SDK older than 1.58, or one that changed the interfaces by more than five versions: the message lists what was tried; use an SDK between 1.58 and 1.64, or update the plugin. |
| `... newer than the SDKs this plugin was checked against` | A warning, not an error: the library is from a newer SDK (1.65 or later) and the plugin uses it. If a call misbehaves, use the SDK 1.64 library, or update the plugin. |
| `does not export SteamAPI_...` | A function the plugin calls is not in the library: a later SDK renamed or removed it. Use the SDK 1.64 library, or update the plugin. |
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
   When Cloud works, `platform.cloud.stat("check")` answers `{ exists: true, size, modified }` with Steam's time for the file
   (not yet tried against real Steam, see "Tested against a mock only"); with a guest on Remote Play Together
   `platform.remotePlay.sessions()` lists it and the `remotePlay` event arrives when it connects and leaves.
7. Open Steam's overlay in the game window (Shift+Tab): with the window focused it must open, and the game receives the
   `overlay` event. Call `platform.overlay.open("achievements")` from the script: it opens the overlay's achievements page.
   (The engine draws with Direct3D 11 on Windows, Metal on macOS and OpenGL on Linux: note in ENGINE_FEEDBACK.json on which of
   them the overlay does not appear.)
8. In Steam, your friends list shows "Checking Steam" under your name while the game runs.
9. In Steam's own page for the achievement (Library > Spacewar > Achievements, or `steamcommunity.com/stats/480/achievements`),
   "Win a game" shows unlocked.
10. **Deck keyboard (on a real Steam Deck, or a desktop in Big Picture mode).** The tests run against a mock; this is
    the check against the real keyboard. Add a scene with a `TextField` (`factoria call scene.spawn`, or the menu kit's
    `name` scene) and run the game from Steam as a non-Steam game, or from Desktop Mode with Steam open.
    a. With the pad (do not touch the keyboard or the touch screen), move the focus to the field with the d-pad: Steam's
       floating keyboard appears next to the field, over the game, and the kit's own on-screen keyboard does not.
       `input.platformKeyboard` is true (log it from `onUpdate`).
    b. Type with the Deck's touch keyboard: the characters appear in the field, `ui.change` arrives for each, and `maxLength` is
       respected. Press Enter on it: `ui.submit` arrives.
    c. Move the focus to a button: the keyboard goes away and `input.platformKeyboard` is false. Come back to the field and
       press A: it comes up again.
    d. If the floating keyboard does not appear (older SteamOS), the full-screen one must: type "hello", confirm, and the field
       holds "hello". Cancel instead: the text is unchanged.
    e. Plug in a keyboard and press a key: nothing breaks, the field takes the typing. On a desktop Steam (not Big Picture)
       steps a to d do not apply: the pad opens the kit's keyboard.
    Note in `ENGINE_FEEDBACK.json` anything that differs (a keyboard in the wrong place means the window rectangle is off).
11. Export: `factoria export --platform <this OS>`; the exported folder holds the plugin and Valve's library, **no**
    `steam_appid.txt`. Start the exported game from a terminal with Steam running: without an app id Steam refuses to start
    it, the log says so, and the game runs with no platform services (`platform.backend` is `none`). For the final check, a
    game started by the Steam client gets its app id from Steam: upload a build to your own app with SteamPipe (app 480 takes no
    uploads) and start it from the Steam library.

## 5. Writing a backend plugin

A [native plugin](../EXTENDING.md#g-native-plugins-cc-for-one-game) becomes a backend with the **plugin API version 2**:
`add_backend`, and `resolve`, `reject` and `emit` to answer. (`factoria call project.new_plugin` copies `fa_plugin.h`;
a version 1 plugin keeps working, and one built for version 2 checks `api->version >= 2`.) **Version 3** adds
`add_text_input` and `submit_text`, for a platform keyboard that a gamepad player gets for a `TextField` (the Steam Deck's;
[EXTENDING.md](../EXTENDING.md#g-native-plugins-cc-for-one-game)); a plugin built for version 2 keeps working, and
one that wants the hook checks `api->version >= 3` before it reads the new members.

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
- `emit(api, "purchase" | "overlay" | "player" | "remotePlay", data_json)` reaches `platform.on` in the running game.
  A `remotePlay` event is `{ status: "connected" | "disconnected", session }` (the table below says what a session is).
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
| `stats.add` | `{ id, storeId, type, delta }` | `{ id, value }` (the new value). Only the fake backend gets it, so that two adds in a frame count twice; a backend plugin keeps implementing `stats.get` and `stats.set` and the script adds with those. |
| `leaderboards.submit` | `{ id, storeId, name, order, period, periodKey, date, score }` | `{ id, score, best, periodStart?, periodEnd? }` |
| `leaderboards.entries` | `{ id, storeId, name, order, period, periodKey, date, range, count }` | `[{ rank, name, score, playerId, isPlayer }]`, or `{ entries: [...], periodStart, periodEnd }` when the store says when the period runs |
| `cloud.save` | `{ key, data }` (`data` is JSON text) | `{ key, bytes }` |
| `cloud.load` | `{ key }` | `{ key, data }`, or `null` when there is no such key |
| `cloud.list` | `{}` | `["key", ...]` |
| `cloud.remove` | `{ key }` | `{}` |
| `cloud.stat` | `{ key }` | `{ exists: false }`, or `{ exists: true, size, modified }` (`modified` in Unix seconds, or `null` when the store keeps no time) |
| `remotePlay.sessions` | `{}` | `[{ id, guestName, guestId, deviceName, formFactor, resolution }]` (`formFactor`: `"phone"`, `"tablet"`, `"computer"`, `"tv"`, `"vr"` or `"unknown"`; `resolution`: `{ width, height }` or `null`) |
| `purchases.products` | `{ products: [{ id, storeId, type }] }` | `[{ id, title, description, price, priceValue, currency, type }]` |
| `purchases.buy` | `{ id, storeId, type }` | `{ status, productId, transactionId, receipt }` |
| `purchases.finish` | `{ transactionId, id, storeId, type }` | `{}` |
| `purchases.restore` | `{ products: [{ id, storeId, type }] }` | `[{ productId, transactionId, receipt }]` |
| `overlay.open` | `{ page, id?, storeId? }` | `{}` |
| `presence.set` | `{ text, data }` | `{}` |
| `ads.available` | `{ placement, adUnitId, type }` | `{ available }` |
| `ads.showRewarded` | `{ placement, adUnitId, type }` | `{ rewarded, reason? }` |
| `ads.consent` | `{}` | `{ gdpr, tracking, canShowAds }` |
| `integrity.token` | `{ challenge }` | `{ token }` (`token` is a string; the engine has checked `challenge` is 16 to 500 characters of URL-safe Base64) |

The C++ side is `fa/services/platform.h` (`PlatformBackend`, `PlatformServices`, `platform_methods()` with this table)
and `fa/runtime/platform_backend.h` (the plugin adapter and the choice of backend). The fake backend
(`fa/services/fake_platform.h`) is the reference implementation of every row.
