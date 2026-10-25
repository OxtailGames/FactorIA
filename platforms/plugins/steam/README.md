# {{NAME}}: the Steam backend

A native plugin that makes the game's `platform.*` calls (achievements, stats, leaderboards, cloud saves, purchases, overlay, rich
presence, Remote Play guests; `factoria docs read platform`) go to **Steam**, through the Steamworks flat C API. The game is written once against
`platform`; this plugin is what answers on Steam. It holds no Valve code: it loads Valve's redistributable at run time.

**The quick way:** `factoria call platform.add_backend '{"backend": "steam", "sdk": "<Steamworks SDK folder or .zip>"}'` does all of
the below (declares the plugin, builds it, copies the redistributable, writes `steam_appid.txt`, keeps it out of the export).
This folder is what it leaves behind, so you can also do it by hand.

## Files

- `src/`: the plugin. `plugin.cpp` (entry point), `steam_loader.cpp` (loads the redistributable, starts Steam), `backend.cpp`
  (callbacks, call results), `methods_game.cpp` (achievements, stats, leaderboards, cloud), `methods_store.cpp` (purchases,
  overlay, presence), `remote_play.cpp` (Remote Play Together guests), `text_input.cpp` (the Steam Deck keyboard), `steam_functions.h` and `steam_types.h` (the part of the Steamworks API it uses, declared here).
  `include/fa_plugin.h` is the engine's plugin API.
- `CMakeLists.txt`: builds it and copies the library into this folder, one subfolder per platform: `windows/{{NAME}}.dll`,
  `macos/lib{{NAME}}.dylib`, `linux/lib{{NAME}}.so`. It needs no Steamworks SDK to build.

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

## What it needs next to it

Valve's redistributable, **next to the plugin's library** (it is looked for there first, then on the system's library path):

| Platform | Plugin | Steamworks redistributable (from the SDK's `redistributable_bin/`) |
|---|---|---|
| Windows | `windows/{{NAME}}.dll` | `windows/steam_api64.dll` (`win64/`) |
| macOS | `macos/lib{{NAME}}.dylib` | `macos/libsteam_api.dylib` (`osx/`) |
| Linux | `linux/lib{{NAME}}.so` | `linux/libsteam_api.so` (`linux64/`) |

Get the SDK at partner.steamgames.com/downloads/list (a free Steamworks account). Valve's license does not let this repository
ship its files, so you copy them. The plugin was checked against the flat API of the **Steamworks SDK 1.58 to 1.64**. A library
of a newer SDK (1.65 and later) is used with one warning, as long as the functions the plugin calls are present and its
interface versions are at most five above the known ones (`{{NAME}}.status` lists them as `newerInterfaces`); a library that
does not fit is refused with a message that says what was tried. 64-bit only.

Then declare the plugin and choose it as the game's backend in `factoria.json`:

```json
"plugins": { "{{NAME}}": { "path": "plugins/{{NAME}}", "platforms": ["windows", "macos", "linux"] } },
"platform": { "backend": "steam", "achievements": [ { "id": "first_win", "name": "First win", "ids": { "steam": "ACH_WIN_ONE_GAME" } } ] }
```

`ids.steam` maps each achievement, stat, leaderboard and product to its Steam name (a product's is the **app id of its DLC**).

## Trying it before the game has an app id

Valve's test app is **480** (Spacewar); any Steam account can run it. Put a file `steam_appid.txt` holding `480` in the project
folder, start the Steam client, and `factoria run`. Spacewar has the achievement `ACH_WIN_ONE_GAME`, the stats `NumWins` (int)
and `FeetTraveled` (float), and the leaderboard `Feet Traveled`.

`steam_appid.txt` is for development only: **`factoria export` never copies it**. A game started from the Steam client gets its app
id from Steam. A game exported without Steam running, or without the redistributable, runs with no platform services.

## What it answers

| Call | On Steam |
|---|---|
| `platform.signIn()` | The Steam user: `{id: SteamID, name: persona name, signedIn}`. |
| `achievements.unlock / progress / list / reset` | `SetAchievement` + `StoreStats`; progress shows Steam's "n of 100" notice; `reset` is `ResetAllStats` (development). |
| `stats.get / set` | Int and float stats; stored once per frame. |
| `leaderboards.submit / entries` | `FindOrCreateLeaderboard` (created on first use with the catalog's order), keep-best uploads, `top`, `around` and `friends` ranges. |
| `cloud.save / load / list / remove / stat` | Steam Cloud files named `<key>.json`. Needs Cloud turned on for the app in the Steamworks partner site. `stat` answers `{exists, size, modified}` with `GetFileSize` and `GetFileTimestamp` (Unix seconds); a missing key is `{exists: false}`. |
| `purchases.*` | **DLC**: `buy` opens the DLC in the Steam overlay's cart and answers `pending`; when the player owns it, a `purchase` event follows. Consumables and subscriptions are `unavailable` (Steam's microtransactions need your own server). |
| `overlay.open` | The overlay's achievements and friends, the store page of the game or a DLC, or the game's leaderboards page. |
| `presence.set(text, data)` | Rich presence: `text` is the key `status`; `data` keys are sent as they are (`connect`, `steam_display`...). |
| `remotePlay.sessions()` | The Remote Play Together guests connected now (`ISteamRemotePlay`: session id, the guest's persona name and SteamID, device name, form factor, resolution). Offered only when the Steam library has `ISteamRemotePlay`. |

Events: `overlay` (opened or closed), `purchase` (a DLC the player got), `player` (Steam went online or offline), `remotePlay` (a
guest joined or left; the guest's controller reaches the game as one more gamepad, which this plugin does not touch).

Every engine that loads this plugin starts Steam, because a plugin cannot know which backend the engine will pick: `factoria run`,
but also `factoria test`, `factoria call` and the MCP server on this game start Steam when it is running (your friends see you in
the game), and log the warning below when it is not. Those headless runs still answer `platform.*` with the fake store, so tests
never touch Steam's data.

`factoria call {{NAME}}.status` shows what the plugin found: app id and where it came from, player, library, interfaces, overlay
and Cloud.

## When it does not start

The plugin logs why and the game falls back (the fake backend in development, none in an exported game): Steam is not running, no
app id, the redistributable is missing or from a SDK it does not know. Each message says what to do. The full description, the
Steam Deck notes and the manual check against app 480 are in `factoria docs read platform` ("Steam").
