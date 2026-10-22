# Shipping Clockwork Courier (P6)

Version 1.0.0 (`factoria.json` `version`). Build numbers: Android `versionCode` 10000, iOS and macOS `buildNumber` "1".
Raise the build number of a platform for every upload to its store; raise `version` for every public release.

Everything below was run on a MacBook (Apple M5, macOS) on 2026-10-22 with the `factoria` of this checkout. "Engine" means
`factoria` does it; "by hand" means a person does it in a store console or an IDE.

## What is in the game folder for the stores

| Path | What |
|---|---|
| `assets/icon.png` (1024), `assets/icon_fg.png` (432, Android adaptive foreground; background colour in `export.android.adaptiveIcon`) | Game icon, drawn by `factoria call assets.draw_icon @tools/icon.json`. |
| `store/keyart.png` (2880x1620) | Key art; the capsules are cut from it. |
| `store/capsules/{googleplay,itch,steam}/clockwork-courier_WxH.png` | Google Play 512x512 and 1024x500, itch.io 630x500, Steam 748x896, 920x430, 1438x810, 1280x720, 600x900, 462x174, 3840x1240, 1232x706. Not in git: see below. |
| `store/screenshots/{phone,tablet,desktop}/NN_<level>.png` | Five per set: phone 2868x1320, tablet 2752x2064, desktop 1920x1080. Not in git: see below. |
| `store/make_store_images.py` | Writes the screenshots (recorded headless from the bot input in `store/trailer/replays/`) and the capsules (`assets.draw_capsules` on the key art). |
| `store/{en,es,ja}/*` | Listing text per language: name, subtitle, short and long description, keywords, promotional text, what's new, category, age rating answers, privacy text, URLs. |
| `store/check_store.py` | `python3 store/check_store.py` checks every text against the length limits of the three stores. Run it after editing a text. |
| `store/trailer/` | The trailer (see "Trailer"). |
| `perf.json` | Performance budget: `factoria call perf.check`. |

The screenshots and capsules (about 17 MB) are git-ignored, like the trailer video: write them before an upload, from the
game folder, with `python3 store/make_store_images.py path/to/factoria` (about 10 s; the files come out the same every
time). Run it again after a change to a level or to the key art.

`tests/budget.test.js` checks the size of the icons and the key art (a missing file reads as 32x32, so it fails), the size of
every screenshot and capsule that is there, and the entity, mesh, light and particle budget of each level.

`factoria.json` `export.exclude` is `["store/**", "screenshots/**"]`: the store material and the screenshots are not packed
into the game.

URLs in `store/*/urls.txt` and the e-mail are PLACEHOLDERS (`example.com`). Replace them before submitting: both Apple and Google
require a real privacy policy URL, even for a game that collects nothing (`store/*/privacy.md` has the text).

## Exports, as run

| Target | Command | Result |
|---|---|---|
| Web | `factoria export --platform web --out OUT` | 1 s. `OUT/clockwork-courier-web/` 16 MB and `clockwork-courier-web.zip` 10 MB, the file for itch.io (HTML5 game). Opened in a browser pane over localhost: the intro, title, level select, a level and moving the courier all work. |
| iOS | `factoria export --platform ios --out OUT`, then `cd OUT/clockwork-courier-ios && ./build_ios.sh --simulator --build` | Export is quick; the simulator build took 1m05s, the .app is 59 MB. Ran on the iOS Simulator: intro, title, a level, taps and swipes move the courier. |
| Android | `factoria export --platform android --out OUT` (apk; `--format aab` for Google Play; `--release` needs `export.android.signing` or `--allow-debug-key` for a private test) | apk 52.8 MB in 2m23s (source mode, Gradle `--offline`). Ran on an emulator: intro, title, a level, taps; Android Back at the title asks "Quit?" and Back again closes the question (`tests/comfort.test.js`, "title: Back asks before quitting"). |
| macOS | `factoria export --platform macos [--release] --out OUT` | Exports (`Clockwork Courier.app`), but NOT verified running here: see problems. |
| Windows, Linux | not run on this machine | `factoria export --platform windows` / `linux`; `windows --format msix` makes the Microsoft Store package. |

Problems found while exporting (each is in `ENGINE_FEEDBACK.json`; the ids are in the entries, not here):

- Android source mode needs CMake 3.31.6 in the Android SDK and a JDK. On a machine without them the Gradle build tries to
  download CMake. Offline recipe used here: `cmake.dir=<system cmake dir>` in the exported project's `local.properties`,
  `./gradlew assembleDebug --offline -Pfactoria.cmakeVersion=<system cmake version>`, `JAVA_HOME` of any JDK 17.
  Install the SDK pieces once (`sdkmanager "cmake;3.31.6"`) and none of this is needed.
- The first launch on a fresh emulator may show "System UI isn't responding": tap Wait. Launch with
  `adb shell am start -n com.factoria.examples.clockworkcourier/android.app.NativeActivity` (the activity is the engine's
  `android.app.NativeActivity`, not a `MainActivity`).
- macOS: the `--release` app stops with "no factoria.json in '/'"; the normal app runs a player older than the project
  (it does not know `Text.key`, `Text.safeArea` or `Button`). The `factoria_player` that is bundled is the one next to the
  `factoria` binary, which on this machine was an older build than the binary. Rebuild the engine so both match
  (`cmake --build build/macos-release`) and export again; check with `open -n "Clockwork Courier.app" --stderr err.log`.
- `platform.add_backend` has no real dry run and reformats `factoria.json`; the commit that added the plugin shows it.

## App Store (iOS and Mac App Store)

Engine: the Xcode project and the app, icon from `assets/icon.png`, `ITSAppUsesNonExemptEncryption` (false), privacy
`tracking` false, `Products.storekit` for the in-app purchases (written on export because `plugins/apple` is declared:
`platform.add_backend apple` put it in `factoria.json` and built `plugins/apple`). The plugin's libraries are not in git:
build them once on a Mac before exporting for iOS or macOS, `cmake -S plugins/apple -B plugins/apple/build && cmake --build
plugins/apple/build` (`plugins/apple/README.md`); without them the game still runs with the local stub and `factoria validate` only warns (the plugin is `"optional": true`), but the export says which file is missing and stops. Test purchases: open the exported Xcode project, Edit Scheme, Options, StoreKit Configuration =
`Products.storekit`. StoreKit cannot be checked without Xcode.

By hand: App Store Connect record (bundle id `com.factoria.examples.clockworkcourier`), team and signing in Xcode,
the in-app products with the ids of `factoria.json` (`platform.products`), the texts of `store/<lang>/` (en, es, ja), the age
rating answers (`age_rating.md`), the privacy "nutrition label" (data not collected; `privacy.md`), the screenshots of
`store/screenshots/phone` (6.9 inch) and `tablet`, the trailer, the privacy policy URL, TestFlight, review. Build number
"1" for the first upload.

## Google Play

Engine: `factoria export --platform android --format aab --release` (needs `export.android.signing`: a keystore you keep
for ever; Play App Signing holds the real key), adaptive icon from `assets/icon_fg.png` and `#1d2240`.

By hand: Play Console app, the content rating questionnaire (`age_rating.md`), the Data safety form (nothing collected),
the listing texts and graphics (`store/capsules/googleplay` 512x512 icon and 1024x500 feature graphic, phone and tablet
screenshots), the in-app products, the privacy policy URL, an internal test track first. `versionCode` 10000 goes up for
every upload.

## Steam (desktop) and itch.io

Steam: `factoria export --platform windows|macos|linux`, upload the folders with SteamPipe (by hand); the capsules are in
`store/capsules/steam`, screenshots in `store/screenshots/desktop`, texts in `store/<lang>/`. Steam services (achievements,
leaderboards) need the engine's Steam backend (`platform.add_backend`, a Steam app id and the Steamworks SDK): not added
here, so on desktop they use the engine's local fake until it is.

itch.io: upload `clockwork-courier-web.zip` as an HTML5 game (viewport 1280x720, mobile friendly), cover 630x500 from
`store/capsules/itch`, screenshots from `store/screenshots/desktop`.

## Trailer

The engine has no video editor, so the trailer is a scripted scene recorded by the engine.

- `store/trailer/trailer.js` is the director (a Behaviour): camera moves, captions and fades, driven only by `time.dt`.
- `store/trailer/make_trailer.py` writes `store/trailer/scenes/shot_N.scene.json` (a level, the director, captions, a black
  cover; git-ignored) and `.factoria/tmp/trailer_input.json` (the recorded bot input of each level in `store/trailer/replays/`, cut to the
  length of its shot on one global frame counter).
- Shots (43.6 s in all, 2615 frames at 60 fps): rooftops_1 7.5 s (title card, "A tiny robot. A big city. One spring."),
  rooftops_3 10 s, market_1 8 s, rooftops_2 9 s, market_3 9 s.
- Rerun after a change to a level:

```
cd examples/clockwork-courier
python3 store/trailer/make_trailer.py
factoria run --headless --scene store/trailer/scenes/shot_1.scene.json \
  --input .factoria/tmp/trailer_input.json --frames 2615 --render-scale 1 \
  --record-video clockwork_courier_trailer.avi
```

  The AVI is large (183 MB for 43.6 s, so it is not in the repository). Convert it for the stores (ffmpeg is not part of
  the engine toolchain; install it yourself):
  `ffmpeg -i clockwork_courier_trailer.avi -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a aac clockwork_courier_trailer.mp4`.
  Check that it has sound before uploading.
- The recorded input of `rooftops_3` and `market_3` drifts after about 700 frames (the same physics order problem as the two
  known failing expert-shortcut tests), and level replays need a 10 frame offset (`SETTLE` in `make_trailer.py`). The
  shots are cut before the drift matters; watch the video once before every upload.

## Studio intro

`scenes/intro.scene.json` and `scripts/intro.js` are the `mainScene`: about 4.8 s, shown once (`introSeen` in storage),
skippable (tap, click, key, pad button, Skip, Android Back). `tests/intro.test.js` covers it. To bring it back in a test
or on a device, clear the `introSeen` key (or the app data).

## Budget

`factoria call perf.check` compares a 300 frame run of `market_3` (the heaviest level: 119 draw calls, 416 entities,
about 82 MB) with `perf.json`. Only the runner `macos-clang-metal` (this Mac) has a baseline; on another machine (CI on
Linux, Windows) the first run prints `baselineEntry`: paste it under `runners`, or run `factoria call perf.baseline` there.
Draw calls per level on this machine, 120 frames: market_3 119, market_2 110, rooftops_3 105, market_1 83, rooftops_1 71.
The engine reports draw calls and entities only; triangles and lights are not in `perf.measure`, and `game.state.renderStats`
is zero without a window, so `tests/budget.test.js` counts what each scene asks for instead (entities, meshes, lights,
particle emitters).
