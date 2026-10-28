# Shipping Larkspur Lodge

What each store needs, what is done, what ran where and what is left to do by hand. Everything below was run on
2026-10-27 on one Mac (Apple M5, macOS 26, Metal, Xcode 27 with the iOS 27.1 simulator SDK) with a Debug source build of
FactorIA 0.2.0. Nothing was uploaded anywhere and no store account was used.

Short version: **the Mac App Store package was built, sandboxed and ad hoc signed, and the sandboxed app was started on
this Mac (it creates its container and runs); the one thing not seen is a save file in that container (the
player saves from a replay with `--persist-storage` since M33.12, FB-0801, but that was run outside the sandbox). The iPad build compiled and its title screen was looked at on the iPad Pro 13-inch
simulator. The MSIX and the Linux (Steam Deck) folder were built, not run: there is no such machine here.** Every
signature is ad hoc or missing, so no store accepts these files as they are (section 8).

## 1. What the project sets up (`factoria.json`)

| Setting | Value | Used by |
|---|---|---|
| `name`, `id`, `version` | `Larkspur Lodge`, `com.oxtailgames.larkspurlodge`, `0.1.0` | window title, exe name `larkspur-lodge`, bundle id, save folder |
| `display` | 1280x720 design, `scaleMode: fit`, landscape | the window; 16:9 is letterboxed on 4:3 (FB-0803) |
| `icon` | `assets/icon.png` (1024x1024) | every export builds its icon sizes from it |
| `export.exclude` | `store/**`, `assets/src/**` | the store material and the generator scripts stay out of `game.pak` |
| `export.scriptBytecode` | `true` | `--release` compiles the scripts |
| `export.macos` | adventure games category, minimum macOS 11.0, build number 1 | `Info.plist` |
| `export.windows.msix` | display name, publisher display name, background colour | the MSIX manifest; **no `identityName` or `publisher` yet** (section 8) |
| `export.linux` | `Game;AdventureGame` | the `.desktop` file |
| `export.ios` | background `#1b1220`, build number 1, `usesNonExemptEncryption` false | `Info.plist`, privacy manifest |

The icon (`assets/icon.png`), the key art and every screenshot are renders of the game itself, made by
`assets/src/make_store.py` and `assets.draw_capsules` (no outside image, no AI image); `assets.json` has the provenance of
each file (CC0-1.0, the lodge models are Kenney CC0).

## 2. Store material

```bash
FACTORIA=/path/to/factoria python3 -I assets/src/make_store.py shots     # store/screenshots/*.png, 1920x1080
FACTORIA=/path/to/factoria python3 -I assets/src/make_store.py trailer   # .factoria/store/trailer.mp4 (not committed)
factoria call assets.draw_capsules '{"source":"store/keyart.png", ...}'   # store/capsules/{steam,microsoft,itch,appstore}/
python3 -I store/check_store.py                                          # the texts
```

| What | Where | Notes |
|---|---|---|
| Key art | `store/keyart.png` | the hall at night with the HUD hidden |
| Screenshots | `store/screenshots/{hall,hall2,library,dining,kitchen,landing,cellar}.png` | 1920x1080, English UI, HUD hidden, one per area (the cellar from chapter 4) |
| Capsules | `store/capsules/steam/` (9 sizes, header 920x430 to library hero 3840x1240), `microsoft/` (300x300, 720x1080, 1080x1080, 1920x1080), `itch/` (630x500), `appstore/` (iPhone and iPad sizes up to 2868x1320 and 2752x2064) | built from the key art |
| Trailer | `.factoria/store/trailer.mp4`, 1480 frames at 1920x1080 with sound | **the intro cut-scene only** (about 25 s: the opening cut-scene in the hall, with its captions and the skip prompt), recorded from `store/replays/intro.json` that clicks Play. It is the game's own cut-scene, not a cut-down edit; a real trailer needs editing by hand. Recording it held 4.4 GB of memory before FB-0802 was fixed (the Metal read-back; now about 61 MB) |
| Store texts | `store/en/{name,short_description,long_description,features,whats_new}.txt` | English only. One folder per language: package P8 adds `es`, `de`, `ko`, `he` with the same five files and `check_store.py` then checks them too |
| Age rating answers | `store/age_rating.md` | IARC and App Store questionnaire, with the reason for each answer |

The iPad App Store screenshots must be 2752x2064 or 2048x2732 with no bars; the 16:9 renders are letterboxed there
(FB-0803), so take iPad pictures from a running iPad (section 5).

## 3. Exports

```bash
factoria export --platform macos --release                                  # the macOS app
factoria call sign.macos '{"distribution":"appStore","identity":"-"}'      # sandbox + ad hoc + .pkg
factoria export --platform windows --format msix --release --allow-player-mismatch
factoria export --platform linux --release --allow-player-mismatch
factoria export --platform ios --release --allow-player-mismatch
```

| Platform | Output (under `.factoria/export*`, git-ignored) | Size | Made with |
|---|---|---|---|
| macOS App Store | `larkspur-lodge-macos/Larkspur Lodge.app`, `larkspur-lodge-macos.pkg`, `.appstore.entitlements` | 21 MB app, 12 MB pkg | this build's player |
| Windows MSIX | `larkspur-lodge-windows.msix` and the folder | 18 MB msix | the installed 0.2.0 player (FB-0804) |
| Linux | `larkspur-lodge-linux/` (`larkspur-lodge`, `.desktop`, icon, `game.pak`) | 23 MB | the installed 0.2.0 player (FB-0804) |
| iOS source project | `larkspur-lodge-ios/` (`build_ios.sh`, Xcode project) | built for the simulator | this checkout |

The whole game is in `game.pak` (187 files, scripts compiled to bytecode).

## 4. The Mac App Store package, run on this Mac

1. `factoria export --platform macos --release` then `sign.macos` with `distribution: appStore` and `identity: "-"`
   writes the sandbox entitlements (`com.apple.security.app-sandbox` true, checked with `codesign -d --entitlements`),
   signs the app ad hoc and builds the `.pkg` **unsigned** (an ad hoc identity cannot sign a pkg).
2. The sandboxed app was started from `.factoria/export/` (a `player` link to its binary, so the shell does not name the
   sandbox container): it created `~/Library/Containers/com.oxtailgames.larkspurlodge/` and ran with audio, Metal and the
   menu scene (59 entities), exiting 0 after its frames. The player's log went to `Data/Library/Application Support/
   com.oxtailgames.larkspurlodge/log.txt`, and the state dump and a screenshot it was told to write went into `Data/`.
   A relative `--input` path fails there: the working directory of a sandboxed app is its container, so pass an
   absolute path inside it.
3. **A save file, without a click.** The exported player takes `--persist-storage` with `--frames` and `--input`, so a replay
   that presses Play, skips the intro and saves in slot 1 (`tests/replays/save_slot1.json`) leaves a real `slot1.json`:
   `player --frames 520 --input <absolute path> --persist-storage` (FB-0801). `ctest -R cli_larkspur_ship` runs it on the
   exported game with `HOME` in a temporary folder and finds the file. **Not repeated inside the signed sandbox container
   after that change**: the container still holds only what the earlier run left, so item 4 below is the one check left.
4. **Once, in the container** (a few minutes): run the sandboxed app with the replay and `--persist-storage` as in 3 (an absolute path
   inside the container for `--input`), or double-click the sandboxed app, Play, press Esc, Save game in slot 1, quit, then check
   `ls ~/Library/Containers/com.oxtailgames.larkspurlodge/Data/Library/Application\ Support/com.oxtailgames.larkspurlodge/`.

## 5. iPad (iOS Simulator)

`factoria export --platform ios`, then `build_ios.sh --simulator --build` built `factoria_player.app` for the simulator (Release), and the app was installed on the iPad Pro 13-inch (M5) simulator with `xcrun simctl install` and
started with `simctl launch com.oxtailgames.larkspurlodge`; `simctl io screenshot` took its picture (2064x2752, the
simulator in portrait, so the landscape game shows turned on its side). The picture was looked at: the title screen with
"Larkspur Lodge" and the Play, Load game, Options and Credits buttons, all text sharp, the 16:9 area with black bars on the
4:3 screen (FB-0803). The app was terminated and the simulator shut down.

**Playing it on the Simulator** is now one command, with the same replay as section 4 (the player takes the replay and the
turn of the screen itself, because `simctl` cannot tap or rotate):
`factoria call player.run_ios_sim '{"app":"<factoria_player.app>","input":"tests/replays/save_slot1.json","device":"iPad Pro 13-inch","orientation":"landscape","screenshot":"build/ipad.png"}'`
(docs/MOBILE.md). It was **not run** on this game's Simulator build after it was written; run it once and look at the screenshot.

**Not done:** playing it on a real iPad. Only the first screen was seen there; and the picture is a build output, not a
store screenshot. By hand: run `./build_ios.sh --run` on a real iPad with a Team id, play a chapter with touch, and take
the App Store screenshots there (2752x2064).

## 6. Render and perf budgets of the busiest room

The busiest room is the ground floor (`scenes/ground.scene.json`: hall, library, dining room and kitchen in view, 331
entities, 13 lights). `python3 -I store/check_budgets.py` plays it for 300 headless frames at four sizes and fails over the
caps (draw calls 300, entities 400, triangles 30000, lights 16). Measured (Debug build, Metal, Apple M5):

| Size | Draw calls | Entities | Triangles | Lights | CPU avg | Peak memory |
|---|---|---|---|---|---|---|
| 1280x720 (design) | 223 | 331 | 8888 | 13 | 0.55 ms | 66 MB |
| 1280x800 (Steam Deck) | 223 | 331 | 8398 | 13 | 0.54 ms | 66 MB |
| 1180x820 (iPad points) | 214 | 331 | 7524 | 13 | 0.56 ms | 66 MB |
| 2732x2048 (iPad Pro pixels) | 213 | 331 | 6796 | 13 | 0.55 ms | 66 MB |

Draw calls fall with the wider aspect (more is culled); entities do not change. The perf baseline
`tools/cli/tests/perf/larkspur-lodge.perf.json` (engine repo) still holds: `factoria call perf.measure` on the ground scene
gives `drawCalls` 225 and `entities` 331, the same as its runner entry, so nothing in it changed. CPU time and memory are
CI's to measure.

## 7. Steam Deck (Valve's checklist)

The Linux folder was built but **never run** (no Linux machine), so every answer that depends on running is unverified.

| Valve's question | Answer | Checked? |
|---|---|---|
| Input: full controller support, no mouse or keyboard needed | Every menu and the whole story are playable with a gamepad (move, interact, dialogue, notebook, deduction board, pause, options); rebinding and button glyphs are in the options (P6) | in tests with a pad (`tests/options.test.js`), not on a Deck |
| Input: on-screen keyboard for text | The game asks for no text | yes |
| Input: Steam Input glyphs for Deck buttons | The game draws its own glyphs by device (Xbox-style for a pad); it has no Steam Input action sets, so Steam shows the pad as an Xbox controller | no |
| Display: default resolution suits 1280x800 | The design is 1280x720, fit with bars on 16:10 (1280x800 gives thin bars); budgets at 1280x800 are in section 6 | render only |
| Display: text legible on the 7-inch screen | Text size option up to 200 % with its layout check in the tests (P6) | not on the Deck |
| Seamless: no launcher, launch dialog or compatibility warning at start | The game opens on its own title, no launcher | not run |
| Seamless: no EULA or login that needs a mouse | None | yes |
| System support: runs natively on Linux (Vulkan or OpenGL) | The Linux folder is a native player; the 0.2.0 player has no fingerprint (FB-0804) | **no** |
| Saves in the standard place | `~/.local/share/larkspur-lodge`-style per-user folder named by the game id (docs/EXPORTING.md) | not run |

By hand: copy the Linux folder to a Deck (`chmod +x larkspur-lodge`), play chapter 1 in Game Mode with the pad only, then
submit to Valve's review. Expect the review to ask for the Steam Input glyph point.

## 8. By-hand list (what the user must do)

1. **Accounts and fees.** Steamworks (app fee), Partner Center (Microsoft), Apple Developer Program, itch.io (free). Google Play is not used.
2. **Mac App Store.** In Xcode or the Developer portal create the App ID `com.oxtailgames.larkspurlodge`, a "Mac App
   Distribution" and a "Mac Installer Distribution" certificate and a provisioning profile; sign again
   (`sign.macos` with the real identity and the profile) and upload the signed `.pkg` with Transporter. The ad hoc one here only starts
   on this machine. Add the saved-file check of section 4.
3. **Microsoft Store.** Copy `identityName`, `publisher` and `publisherDisplayName` from Partner Center > Product identity into
   `export.windows.msix`, export again and upload the MSIX (the Store signs it). Try it first on a Windows PC with
   `sign.windows` and a test certificate. Not run here.
4. **Steam.** Create the app, depots and a build account, fill `publish.steam` in `factoria.json`, paste the store texts and
   upload the capsules and screenshots, answer the content survey with `store/age_rating.md`, and run the Linux build on a Deck (section 7).
5. **iPad / iPhone.** Team id, App Store Connect record, the real build on a device (section 5), the screenshots at 2752x2064
   from it, the privacy policy URL and the age rating from `store/age_rating.md`.
6. **Privacy policy URL** for every store (the game collects nothing; the page can say so), the support URL and a contact.
7. **Languages.** The game (`locales/`) and the store texts (`store/<lang>/`) exist in en, es, de, ko and he. The four
   translations were written by an AI: have native readers check them (the game strings, the dialogue and the store
   texts) before release. The store texts must not claim a language the game lacks.
8. **Trailer.** The mp4 is the intro cut-scene only; cut a real trailer from it and play footage.
9. **Notarization** of a Developer ID build for outside the Mac App Store (not needed for the App Store itself).

## 9. Could not be checked

- The save in the sandbox container itself (section 4, item 4), the replay on the iPad Simulator and the real iPad (section 5), and the Windows and Linux runs.
- Anything that needs a store account: uploads, review, signing with real identities.
- The Steam Deck answers marked "no" in section 7.
