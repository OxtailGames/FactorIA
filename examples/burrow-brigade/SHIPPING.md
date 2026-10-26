# Shipping Burrow Brigade

What the game sets up for Steam and the desktop exports, what the engine does, what is still done by hand and what could
not be checked. Everything below was run on 2026-10-25 on a Mac (Apple M5, macOS 26, Metal) with a Debug source build of
FactorIA 0.2.0 (`factoria version`), no Steam client, no Valve SDK, no network use. Nothing was uploaded anywhere.

Short version: **the macOS export starts and runs on this Mac; the Windows and Linux exports build but were not run
(no such machine here, and their players carry no build fingerprint, FB-0032); the Steam backend is mapped
(achievements, stats, boards, presence) but the plugin is built per machine with Valve's SDK, so the real check against
Valve's test app 480 is a manual step (section 4).**

## 1. What the project sets up (`factoria.json`)

| Setting | Value | Used by |
|---|---|---|
| `name`, `id` | `Burrow Brigade`, `com.oxtailgames.burrowbrigade` | window title, exe name `burrow-brigade`, bundle id, the save folder |
| `version` | `0.1.0` | exe version info, `Info.plist`, upload versions |
| `display` | 1280x720 design, `scaleMode: fit`, landscape | the window and the store screenshots |
| `platforms` | windows, macos, linux | the export warns when a platform is missing |
| `icon` | `assets/icon.png` (1024x1024) and `assets/icon_fg.png` | every export builds its icon sizes from it |
| `export.macos` / `export.linux` | games category, minimum macOS 11.0, copyright; `Game;ArcadeGame` | `Info.plist`, `.desktop` file |
| `export.scriptBytecode` | `true` | `--release`: scripts are compiled inside `game.pak` |
| `export.exclude` | `store/**`, `tools/**`, `tests/**`, `screenshots/**`, `assets/fonts/make_subset.py`, `perf.json`, `scenes/busiest.scene.json`, `scripts/game/busiest.js`, `SHIPPING.md` | what stays out of `game.pak` (the store material, the layout screenshots, the font subset script and the test-only floor; the font's `OFL.txt` ships) |
| `platform` | six achievements, four stats, two leaderboards (`best_run_cash`, `daily_run_cash`), each with a Steam id | `platform.*` and the Steam plugin (P5) |
| `publish.steam` | **placeholders** (below) | `publish.steam` |

**The `publish` ids are placeholders.** They only show the format. Replace both with the real value from Steamworks
before a real upload:

| Where | Fake value | Replace with |
|---|---|---|
| `publish.steam.account` | `FAKE_steam_build_account` | your Steam build account (a Steamworks user with the "Edit App Metadata" and "Publish App Changes" rights; log in once with `steamcmd +login`) |
| `publish.steam.depots` | `9000001` (windows), `9000002` (macos), `9000003` (linux) | one depot id per platform, from App Admin > SteamPipe > Depots |
| `steam_appid.txt` | `480` (Valve's test app, Spacewar) | your own app id. Never shipped: `factoria export` does not copy it |

The icon is drawn by `assets.draw_icon` from `tools/icon.json` (`factoria call assets.draw_icon @tools/icon.json`), a
miner's hard hat with a lamp over two crossed picks; provenance in `assets.json` (CC0-1.0, drawn from shapes and text, no outside image, no AI image).

## 2. Store material (rebuilt by script)

Everything is made from the game itself by `store/make_store.py` (Python 3 with Pillow; `ffmpeg` for the trailer, from
`factoria setup` or `FACTORIA_FFMPEG`):

```bash
python3 store/make_store.py --factoria /path/to/factoria all      # or: scenes | record | images | trailer
```

| Step | What it does | Output |
|---|---|---|
| `scenes` | writes one scene per shot from `scenes/busiest.scene.json` (a floor, a seed, 1 to 4 miners) | `store/scenes/` (committed) |
| `record` | `store/record.test.js` plays four floors (Topsoil, Crystal Caves, Magma Deep, the Mole King) with four `MinerBot`s and prints their stick and button changes; the script writes them as input replays | `store/replays/*.json` (committed) |
| `images` | `factoria run --headless --input <replay> --render-scale 1.5 --screenshot-at <frame>` for eight screenshots (1920x1080, English UI), then the key art and `assets.draw_capsules` | `store/screenshots/`, `store/capsules/{steam,itch}/` (git-ignored), `store/keyart.png` (committed) |
| `trailer` | `store/trailer/trailer.js` plays the replays under captions and records video | `store/trailer.mp4` (git-ignored) |

The screenshots are real play (four miners with their lamps and torches, the crystals and magma glowing, a beetle, the Mole
King, the camp at the fire, the join screen), 1920x1080 as Steam asks. The Steam capsules are at Steam's sizes: header
920x430, small 462x174, main 1232x706, vertical 748x896, library hero 3840x1240 and library logo 1280x720; the itch.io ones
come with them. The key art is a staged frame lifted so the logo sits below the miners (FB-0034). The replays are the
recording of the bots, so the same input always gives the same pictures (deterministic: same seed, same input).

Store texts are in `store/en/`, `store/ru/` and `store/th/` (name, short description, long description, features, what's
new). `python3 store/check_store.py` checks the Steam limits (short description 300 characters, name 80, long description
8000), that no file is empty, that Russian and Thai really contain their letters and that no path or placeholder slipped in.
Russian and Thai were written for this page, not machine-translated from a glossary; have a native reader look at them
before launch. The texts say the game is playable in English, Russian and Thai: that holds once package P8 has added
`locales/ru.json` and `locales/th.json`; until then only English is in the game.

Steam does not read these files. Paste them into the store page by hand (Store Presence > Basic Info) and upload the
capsules and screenshots there (Graphical Assets). Steam's own capsule art rules apply: the header and capsules carry the
logo, the library hero does not need it.

## 3. Exports

```bash
factoria export --platform macos --release
factoria export --platform windows --release --allow-player-mismatch
factoria export --platform linux --release --allow-player-mismatch
```

| Platform | Folder (git-ignored, under `build/export/`) | Size | Made with |
|---|---|---|---|
| macOS (arm64) | `burrow-brigade-macos/Burrow Brigade.app` | 16 MB | the player of this factoria build |
| Windows | `burrow-brigade-windows/` (`burrow-brigade.exe`, `game.pak`) | 13 MB | the installed 0.2.0 player, `--allow-player-mismatch` |
| Linux | `burrow-brigade-linux/` (`burrow-brigade`, `.desktop`, `game.pak`) | 18 MB | the installed 0.2.0 player, `--allow-player-mismatch` |

The whole game is in `game.pak` (167 files, scripts compiled to bytecode). The exports are not committed.

### The macOS run (checked on this Mac)

1. `"build/export/burrow-brigade-macos/Burrow Brigade.app/Contents/MacOS/burrow-brigade" --version` prints
   `factoria_player 0.2.0 (build e9384f7e82ee)`.
2. The same binary with `--frames 300` opens a 2560x1440 Metal window, opens the audio device, loads
   `scenes/menu.scene.json` (98 entities), renders the frames and exits 0. With `--scene scenes/join.scene.json` it loads the
   join screen (17 entities) the same way. The app is an ad hoc signed arm64 bundle; sign and notarize it with
   `sign.macos` before it leaves this machine.
3. **Input.** The exported player now takes `--input <replay>`, `--dump-state <file>` and `--screenshot <file>` with `--frames`
   like `factoria run` (FB-0029; EXPORTING.md, "checking an exported build"). The check below was made before that, with the
   engine's own runtime on the same project and scripts, and was not repeated on the exported binary: `factoria run --headless --scene scenes/join.scene.json
   --input store/replays/join.json --frames 200 --state-out build/proof/join_state.json` presses A on four gamepads one
   after the other. Without `--input` the state dump shows "Nobody has joined yet." and four "press A to join" slots; with
   it, the slots read "P1 - Gamepad 1 - Start begins the shift", "P2 - Gamepad 2", "P3 - Gamepad 3", "P4 - Gamepad 4". The
   floors of the screenshots and the trailer are four bots playing from replays, the same input path.
4. **By hand, once:** double-click the app, press Enter on the title, Enter to join, and dig. This is the one thing a script
   cannot do on the exported binary.

### Windows and Linux (not run here)

Both folders were built and are the right size, but there is no Windows or Linux machine here, so **neither was started**.
Their players are the installed 0.2.0 ones, which carry no build fingerprint (FB-0032), so export needed
`--allow-player-mismatch`: run each on its OS before the first upload:

- Windows: unzip the folder, start `burrow-brigade.exe`, check the title, join with A or Enter, dig, quit. On a clean
  machine check that nothing asks for a runtime installer.
- Linux: `chmod +x burrow-brigade && ./burrow-brigade` on an X11 or Wayland desktop with Vulkan or OpenGL, plus a Steam
  Deck in Game Mode with the pad.

Steam keeps a file's executable bit only from a macOS or Linux machine: upload the macOS and Linux depots from that OS
(`publish.steam` says so in its next steps).

## 4. Steam

- **Set up**: three depots in `factoria.json` (`publish.steam`), the achievements, stats and leaderboards of P5 mapped to
  Steam ids in `platform` (`ACH_FIRST_ORE`, `ACH_MOLE_RESCUER`, `ACH_MOLE_KING`, `ACH_BRIGHT_STRATUM`, `ACH_FULL_HOUSE`,
  `ACH_BUG_SQUASHER`; stats `NumOreDug`, `NumMolesRescued`, `NumFloorsCleared`, `NumEnemiesDefeated`; boards `BestRunCash`
  and `DailyRunCash`), rich presence from `scripts/online/presence.js`, and `steam_appid.txt` with 480.
- **The plugin is not committed.** `platform.add_backend steam` builds `plugins/steam` on the machine that exports, and it
  needs Valve's Steamworks SDK (a free download from Valve, not redistributable). Without it a run logs a warning (an
  ERROR before FB-0031) and the export warns that the Windows and Linux plugin builds are missing (FB-0031). So the committed project has no `plugins/steam`
  (it is in `.gitignore`), the game runs with platform services off ("no store backend"), and the exports above have no Steam
  library. Before the real Steam build, on each export machine:
  `factoria call platform.add_backend '{"backend":"steam","sdk":"~/Downloads/steamworks_sdk_<version>.zip","appId":<your app id>}'`.
- **Publish dry run**: `publish.steam` writes the `.vdf` files and runs `steamcmd`. Valve's test app 480 is accepted
  in a dry run with a warning and refused for a real upload (FB-0033, fixed in the engine; the command below was run before
  that change and with another id). To see the plan with any id:
  `factoria call publish.steam '{"dryRun":true,"appId":1234567}'` returned the three depots (windows 9000001, macos
  9000002, linux 9000003), `steamcmd +login FAKE_steam_build_account +run_app_build .../app_build_1234567.vdf +quit`, with
  `steamcmd` not found on this Mac named as a warning (nothing ran, `ran: false`).
- **By hand**: the Steamworks account and the app fee, the app and its depots and package, the store page (texts and art
  from section 2), the launch options (windows `burrow-brigade.exe`, macos `Burrow Brigade.app`, linux `burrow-brigade`),
  the achievement and stat definitions on Steamworks with the ids above, a build account, and `steamcmd +login` once.
- **Check against app 480 (manual)**: with the SDK, `steam_appid.txt` = 480 and the Steam client running and logged in, run
  `factoria run`: Steam shows the game as Spacewar and Remote Play Together lets a second pad join the join screen. The Spacewar achievement and
  board ids are not ours, so the unlock check needs your own app; 480 is meant to show only that the plugin starts, the overlay opens and
  the rich presence line appears (not checked here).

## 5. Budgets

The busiest floor is Crystal Caves floor 3 with four miners, six torches, the crystals glowing and the HUD
(`scenes/busiest.scene.json`, the `Busiest` behaviour). Three files agree:

| File | What it holds |
|---|---|
| `perf.json` | 300 frames of that scene; budgets `maxDrawCalls` 24, `maxLights` 24, `maxTextureMB` 4, `maxEntities` 200; one runner, `macos-clang-metal` |
| `tools/cli/tests/perf/burrow-brigade.perf.json` (engine repo) | the same scene and budgets, with one entry per CI runner (`drawCalls` and `entities` are the same on all of them) |
| `tests/render_budget.test.js` | the same caps, checked on every floor (all nine), with 4 miners, and the Light2D count (`renderStats().lights2d`, up to 24 in view) |

Measured on the Mac (`factoria call perf.measure`, `factoria call perf.check` passes): 11 draw calls, 145 entities, 47 MB
peak, 1.4 ms CPU per frame on average (p95 2.3 ms), 0.08 MB of textures. CPU time and memory are CI's to measure; draw
calls and entities are the same on every runner.

`lights` reads 20 in the report: `perf.measure` counts `Light2D` too since the engine fixed it (FB-0028, a duplicate of FB-0009).
The render test reads `renderStats().lights2d` (more than 16 on the busiest floor, never over the cap of 24).

## 6. Could not be checked

- Windows and Linux runs of the exports (section 3), the Steam Deck, a clean-machine start.
- Anything that needs Valve's library: the plugin build, app 480, the overlay, Remote Play Together, the real
  `steamcmd` upload, achievements on a real Steam account.
- Signing and notarizing the macOS app (needs a Developer ID).
- Keyboard and pad input on the exported binary (the exported player has `--input` now, FB-0029, but it was not run): proven with the headless runtime instead.
- The Russian and Thai store texts by a native reader, and the games' own Russian and Thai (package P8).
