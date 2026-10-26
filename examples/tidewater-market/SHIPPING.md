# Shipping Tidewater Market (P7)

Version 0.1.0 (`factoria.json` `version`). It is a reference game: nothing here has been uploaded to a store.

Everything below was run on a MacBook (Apple M5, macOS) on 2026-10-26 with the `factoria` of this checkout (0.2.0, a
development build ahead of the last release). "Engine" means `factoria` does it; "by hand" means a person does it in a
store console.

## What is in the game folder for the stores

| Path | What |
|---|---|
| `assets/icon.png` (1024), `assets/icon_fg.png` (432, Android adaptive foreground; background colour in `export.android.adaptiveIcon`) | Game icon: an isometric house on an island, drawn by `factoria call assets.draw_icon @tools/icon.json`. |
| `store/keyart.png` (1920x1080) | Key art: the game's own town, 100 bot days, no interface. In git (1.6 MB). |
| `store/capsules/{steam,itch}/tidewater-market_WxH.png` | itch.io 630x500; Steam 748x896, 920x430, 1438x810, 1280x720, 600x900, 462x174, 3840x1240, 1232x706. Not in git: see below. |
| `store/screenshots/NN_<name>.png` | Six at 1920x1080: title, first harbour, growing town, busy town, overlay, goods table. Not in git. |
| `store/make_store_images.py` | Writes the screenshots, the key art and the capsules, all from the game's own renders. |
| `store/en/*` | Listing text: name, subtitle, short and long description, keywords, promotional text, what's new, category, age rating answers, privacy answers, URLs. |
| `store/check_store.py` | `python3 store/check_store.py` checks every text against the length limits of the stores. Run it after editing a text. |
| `store/trailer/` | The trailer (see "Trailer"). |
| `tools/icon.json`, `tests/store_assets.test.js` | Icon recipe; the test checks the exact size of the icons, the key art and every screenshot and capsule that is there. |
| `tools/cli/tests/perf/tidewater-market*.perf.json` (in the engine repository) | Performance budgets (see "Budget"). |

How to rebuild every store asset, from the game folder:

```
factoria call assets.draw_icon @tools/icon.json              # icon.png and icon_fg.png
python3 store/make_store_images.py path/to/factoria          # key art, screenshots, capsules (about 40 s, same every time)
python3 store/check_store.py                                  # texts against the store limits
```

The renders use scene props that the game's `game_controller.js` reads (`factoria run --props '{...}'`, they are not the
`props` of a Script component): `grow` (bot days played before the first frame, one per frame), `zoom`, `photo` (no
interface; entities tagged `caption` stay), `timelapse` (frames per bot day, the world keeps updating) and `music`. No engine
change was needed for the store images.

The screenshots and capsules (about 17 MB) are git-ignored, like the trailer video: write them before an upload.

`factoria.json` `export.exclude` is `["store/**", "assets/src/**"]`. Without it the first web export packed the generated
store images and the pak was 21.7 MB; with it the pak is 3.5 MB.

URLs in `store/en/urls.txt` and the e-mail are PLACEHOLDERS (`example.com`). Replace them before submitting; `store/en/privacy.md`
has the facts for the privacy forms (no accounts, no analytics, no network).

## Exports, as run

| Target | Command | Result |
|---|---|---|
| Web | `factoria export --platform web --release --player build/web-release/player --out OUT` | Seconds. Folder 12.2 MB and `tidewater-market-web.zip` 6.1 MB, the file for itch.io. Played in a browser: new game, build, save, reload, continue. See "Web". |
| macOS | `factoria export --platform macos --release --out OUT` | `Tidewater Market.app` 33 MB (arm64 executable 30.2 MB, `game.pak` 3.5 MB, icon, notices). Started from its own folder with `--frames 300 --screenshot`: Metal / Apple M5, the menu scene loads, exit 0, no warnings. Not signed or notarized (needs a Developer ID: by hand). |
| Windows | `factoria export --platform windows --release --out OUT` | REFUSED here: the installed player (`~/.factoria/players/0.2.0/windows`) has no build fingerprint and this `factoria` is a newer build. Not run, not checked. |
| Linux | `factoria export --platform linux --release --out OUT` | REFUSED here for the same reason. Not run, not checked. |

For Windows and Linux: run `cmake --build <build dir> --target factoria factoria_player` and export with `--player <path>`, or
export on a machine with a player of this build (a published release). `--allow-player-mismatch` would bundle the old
player, but a player of another build may lack what the game uses (the installed web player did exactly that: see FB-0050).

### Web

Exported with a web player built from this checkout (`cmake --preset web-release && cmake --build --preset web-release`,
Emscripten 6.0.10 from `~/emsdk`) and `--player build/web-release/player`. Without `--player` the export takes the older
installed player first (FB-0050), and that one cannot run the game.

| File | Raw | gzip -9 |
|---|---|---|
| `factoria_player.wasm` | 8,442,650 | 3,156,289 |
| `game.pak` | 3,494,807 | 2,908,128 |
| `factoria_player.js` | 153,171 | 38,786 |
| `FACTORIA_NOTICES.txt` | 57,982 | 11,261 |
| `index.html` | 10,560 | 4,193 |
| Total | 12,159,170 | 6,118,657 |

brotli is not installed here, so there is no brotli figure. The zip is 6,131,713 bytes. itch.io serves the files compressed.

Load time in the browser pane over `python3 -m http.server` on localhost (no network, so this is the cost of the page
itself, not a download): load event 59 ms, the wasm fetched in about 10 ms, the menu scene loaded 0.06 s after the player
started and "60 frames rendered" about 1.1 s after it. On a real connection add the download of about 6 MB.

Played in the browser pane, all of it with the mouse and keyboard: title, Play, slot 1 New game, First Harbour, the build
menu (Housing, House), a house placed (960 coins left, 0/4 residents), Esc drops the tool and then opens the pause menu,
Save game to slot 1 (the slot shows the thumbnail, "Played 1 min", 960 coins), page reloaded, Play, Continue: the house and
the 960 coins are back. No errors in the console.

Seen while playing:
- The engine's page handed the wasm to the player through `Module.wasmBinary`, which Emscripten 6 no longer reads, so the
  8.4 MB wasm was downloaded twice on every load. Fixed in the engine (`platforms/web/shell.html` now uses
  `instantiateWasm`); the export above is from the fixed engine and fetches it once.
- The tooltip of the building under the pointer stays drawn over the pause menu.
- The first click on a building card right after switching the build tab did not select it once; the next click did.
  Not reproduced since.
- The browser logs "ScriptProcessorNode is deprecated" from the player's audio (FB-0054).
- `favicon.ico` is a 404: the export writes no icon for the page.

## Budget

`tools/cli/tests/perf/tidewater-market.perf.json` (scene `scenes/stress.scene.json`, 640 walkers, 300 frames) is the file the
`example_tidewater-market_perf` test checks. `tidewater-market-title.perf.json` (`scenes/menu.scene.json`) and
`tidewater-market-game.perf.json` (`scenes/game.scene.json`) are the same for the other two scenes; run them by hand:
`factoria call --no-graphics perf.check '{"file":"<path>"}'` from the game folder. The baseline is this Mac with a Debug
build (runner `macos-clang-metal-debug`); other runners get `no_baseline` and print the entry to add (paste it, or run
`factoria call perf.baseline` there).

| Scene | cpu avg / p95 ms | draw calls | entities | texture MB | peak MB | Budget (draw calls / entities / texture MB / lights / triangles) |
|---|---|---|---|---|---|---|
| title (menu) | 15.0 / 19.0 | 9 | 2713 | 21.3 | 117 | 24 / 3500 / 32 / 4 / 1000 |
| game | 17.8 / 20.4 | 20 | 2966 | 21.3 | 129 | 40 / 4000 / 32 / 4 / 1000 |
| stress (640 walkers) | 41.5 / 52.1 | 19 | 4980 | 21.3 | 138 | 40 / 6500 / 32 / 4 / 1000 |

All are under budget; the stress town stays at 19 draw calls headless because the whole map and every walker share one atlas.
The game draws no triangles or lights (2D). CPU times are a Debug build: a Release build is several times faster, so the
CI time limits will be loose until a runner records its own baseline.

## Trailer

The trailer is a scripted scene recorded by the engine: `store/trailer/trailer.js` (director: camera between the harbour and
the town centre, zoom, caption fades, fade from and to black, all by frame count) and `store/trailer/make_trailer.py` (writes
`store/trailer/scenes/trailer.scene.json`, git-ignored, and prints the `--props` of the run). The bot plays the town in time
lapse (`grow` 100 days, 4 frames per day). 18 s, 1080 frames at 60 fps:

```
python3 store/trailer/make_trailer.py
factoria run . --headless --scene store/trailer/scenes/trailer.scene.json --props '<printed by the script>' \
  --frames 1080 --render-scale 1 --record-video tidewater_market_trailer.mp4
```

It needs ffmpeg (`factoria setup ffmpeg`, once). It recorded in 2 min 13 s to a 21.8 MB H.264 + AAC mp4 (not in the repository).
Looking at frames of it: the town is already full by about frame 300, so the time lapse is short; the camera drift is slight; and
the captions sit at the bottom with low contrast over busy terrain. Treat it as a first cut: lengthen `DAYS` or `LAPSE`, add a
dark band behind the captions, then watch it once before an upload.

## "Before you call it finished" (docs/FINISHING.md)

Done: [x]. Not done or not checked: [ ] with the reason.

- [ ] Main menu with Play, Options, Credits, Quit; pad, keyboard and mouse (`tests/gamepad_game.test.js`, `tests/mouse_flow.test.js`). Quit is hidden on iOS and Android only: the web build shows a Quit button (the checklist asks for none on the web), left open.
- [x] Pause in the game, resuming restores the speed (`tests/pause.test.js`).
- [x] Volumes per bus (five), text size, controls and language in options, saved and applied on start (`tests/options.test.js`).
- [x] Controls can be rebound and reset (`tests/options.test.js`).
- [x] Saves: versioned (v2), migration from v1 with fixtures of both (`tests/fixtures/`), three slots, a Damaged state (`scripts/ui/slots_screen.js`, `tests/save.test.js`, `tests/save_store.test.js`).
- [x] Progress is written after meaningful events and as autosaves, not only on exit.
- [ ] Every language has the same keys and every screen fits at 100 % and 200 % in every language: only English exists (`locales/en.json`); translations are P8. The screens were checked at 200 % text in English (`tests/ui_layout.test.js`, `tests/options.test.js`).
- [x] Text size, reduced motion and colour-blind safe signals are options; the signals do not depend on colour alone. There is no assist mode or shake: they do not apply to a management game.
- [ ] Achievements and stats are declared and do nothing harmful when there is no store (`scripts/game/achievements.js`; the tests that touch them are in `tests/trade_ui.test.js`, there is no test of the no-store case). Steam achievements need the Steam backend: not added (by hand).
- [x] Credits screen; `FACTORIA_NOTICES.txt` ships in every export; asset provenance is recorded in `assets.json`.
- [ ] A way for a player to send `log.txt` and the `crashes` folder: the game has no button for it. The files are in the save folder; say so on the store page.
- [x] `factoria validate`: 0 errors, 0 warnings (one note: the git-ignored trailer scene is hand-formatted). `factoria test`: 232 passed, 0 failed.
- [x] Screenshots of the menu, a level and the overlay were looked at (the six store screenshots) in English. Not at 200 % text and not in a second language (only English).

## What is left for a real release

- Export Windows and Linux with players of this build (the web export was played with one, see "Web").
- Replace the placeholder URLs and e-mail in `store/en/urls.txt`; write the real privacy policy page.
- Translations (P8), a log/crash send button, a Steam app id and the Steamworks backend for achievements and cloud saves.
- Sign and notarize the macOS app (`factoria call sign.macos`), sign the Windows exe; fill each store's forms by hand (`docs/PUBLISHING.md`).
- Redo the trailer pass described above and record it again.
- Measure a Release build and add the baselines of the CI runners (Linux, Windows) to the three perf files.
