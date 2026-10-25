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
| macOS | `factoria export --platform macos [--release] --out OUT` (build the Apple plugin first: "App Store" below) | `Clockwork Courier.app` 20 MB, a few seconds. Both the normal and the `--release` app, started from `/` with `--frames 400`: the Apple backend starts, the intro and the first level load, exit 0, no warnings. |
| Windows, Linux | not run on this machine | `factoria export --platform windows` / `linux`; `windows --format msix` makes the Microsoft Store package. |

Problems found while exporting (each is in `ENGINE_FEEDBACK.json`; the ids are in the entries, not here):

- Android source mode needs NDK r27+, a CMake 3.24+ and a JDK 17+. The export finds the CMake by itself: the SDK's
  3.31.6, else the newest 3.24+ in the SDK, else one of the computer (PATH, Homebrew, `factoria setup cmake`); it writes
  `cmake.dir` into `local.properties` and `factoria.cmakeVersion` into `gradle.properties` of the exported project and a
  warning says which it took. The JDK is `JAVA_HOME`, Android Studio's or the `java` on `PATH`. When no CMake is found the
  error says what to install and how to build offline. With no network (the apk here was built that way) install CMake and
  a `ninja` first and run `./gradlew assembleDebug --offline` in the exported project.
- The first launch on a fresh emulator may show "System UI isn't responding": tap Wait. Launch with
  `adb shell am start -n com.factoria.examples.clockworkcourier/android.app.NativeActivity` (the activity is the engine's
  `android.app.NativeActivity`, not a `MainActivity`).
- Desktop: the export bundles the `factoria_player` next to the `factoria` binary and stops with an error naming both
  builds when the player comes from another build than `factoria` (both carry a build fingerprint; an older player once
  stopped the `--release` app with "no factoria.json in '/'" and did not know `Text.key`, `Text.safeArea` or `Button`).
  Build both from one checkout (`cmake --build <build dir>`, or pass `--player <build dir>/player/factoria_player`), or use
  the release's players (`factoria setup players`), and export again. `--allow-player-mismatch` bundles the player anyway
  and only warns. Check the result with `"Clockwork Courier.app/Contents/MacOS/clockwork-courier" --frames 200` or
  `open -n "Clockwork Courier.app" --stderr err.log`.

## App Store (iOS and Mac App Store)

Engine: the Xcode project and the app, icon from `assets/icon.png`, `ITSAppUsesNonExemptEncryption` (false), privacy
`tracking` false, `Products.storekit` for the in-app purchases (written on every iOS export whose catalog has products, with
one localization per language: en, es, ja). The plugin's libraries are not in git:
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

## Ads (AdMob, Android and iOS)

The `more_time` placement runs on the engine's fake store; an export without an ads plugin offers no ad
(`platform.has("ads")` is false), and the rest of the game is the same. For real rewarded ads, add Google's AdMob plugin:
`factoria call platform.add_backend '{"backend": "admob"}'` for Android, plus `"sdk": "<Google's iOS SDK zip>"` on a Mac
for iOS (docs/PLATFORM.md, section 8). It is not added here. A development export with it shows Google's test ads: an
export of this game showed the consent form, a test rewarded ad and the 20 s on an Android emulator with Google Play
services and on the iOS simulator.

By hand: the two apps in the AdMob console, their app ids in `platform.ads.appIds` (`android`, `ios`), a rewarded ad unit
for `more_time` in its `ids.admob` and `ids.admob_ios`, and the GDPR message in AdMob > Privacy & messaging. With real ads
the game no longer "collects nothing": the Data safety form, Apple's privacy label and `privacy.md` must say what AdMob
collects. The game does not ask for tracking (no `trackingPrompt`) and its audience is `general`.

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
  --record-video clockwork_courier_trailer.mp4
```

  Run `factoria setup ffmpeg` once (it installs a pinned ffmpeg under `$FACTORIA_HOME/tools/ffmpeg/`, no manual step
  after that): the engine records the replay and converts it to H.264 + AAC, `yuv420p`, `+faststart`, 1280x720. Without
  ffmpeg the run stops before the replay with that advice. With `.avi` instead of `.mp4` the file is large (183 MB for
  43.6 s, so no video is in the repository) and every store needs it converted.
  Check that it has sound before uploading.
- The recorded input of `rooftops_3` and `market_3` drifts after about 700 frames, and level replays need a 10 frame
  offset (`SETTLE` in `make_trailer.py`). The shots are cut before the drift matters; watch the video once before every
  upload. The input was recorded before the rope bridges of those two levels moved 0.2 m off the roof slabs: the courier
  now crosses them up to 3 m behind the recording (checked at frames 610 and 650, still on the route). Record the input
  again if a later level change pushes it off.

## Studio intro

`scenes/intro.scene.json` and `scripts/intro.js` are the `mainScene`: a `Video` plays `assets/video/studio_intro.mpg`
(MPEG-1 + MP2, 640x360, 60 fps, 4.8 s, 495 KB with sound), shown once (`introSeen` in storage), skippable (tap, click, key,
pad button, Skip, Android Back). `tests/intro.test.js` covers it. To bring it back in a test or on a device, clear the
`introSeen` key (or the app data). The recipe for any game is in `docs/MENUS.md` ("A studio intro").

The film is recorded from an animated scene, `store/intro/intro_anim.scene.json` (+ `intro_anim.js`; `store/` is not
exported), and imported. Rerun after changing it:

```
cd examples/clockwork-courier
factoria run --headless --scene store/intro/intro_anim.scene.json --frames 288 --render-scale 0.5 \
  --record-video .factoria/tmp/intro.avi
factoria call assets.import '{"source":".factoria/tmp/intro.avi","path":"assets/video/studio_intro.mpg","overwrite":true,
  "license":"Original work of the project","author":"Oxtail Games"}'
```

288 frames are 4.8 s at the 60 Hz fixed step (`LENGTH` in `scripts/intro.js` must match); `--render-scale 0.5` records
640x360 (the Video is drawn at the full screen size, so it is scaled up). The import needs ffmpeg (`factoria setup
ffmpeg`). The `source` in `assets.json` names the scene the film came from; set it again if the import replaced the entry.

## Budget

`factoria call perf.check` compares a 300 frame run of `market_3` (the heaviest level: 119 draw calls, 416 entities,
about 82 MB) with `perf.json`. Only the runner `macos-clang-metal` (this Mac) has a baseline; on another machine (CI on
Linux, Windows) the first run prints `baselineEntry`: paste it under `runners`, or run `factoria call perf.baseline` there.
Draw calls per level on this machine, 120 frames: market_3 119, market_2 110, rooftops_3 105, market_1 83, rooftops_1 71.
The engine reports draw calls and entities only; triangles and lights are not in `perf.measure`, and `game.state.renderStats`
is zero without a window, so `tests/budget.test.js` counts what each scene asks for instead (entities, meshes, lights,
particle emitters).
