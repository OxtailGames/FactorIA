# Shipping Lantern Keep

What the game sets up for each store, what the engine does, what is still done by hand, and what could not be checked
on the machine that made this file (Windows 11, no network use, no store accounts, no Android NDK, no Mac). Everything
here was run on 2026-10-19 with a Debug source build of FactorIA 0.1.6 (`factoria version`).

Short version: **the Windows desktop build, the `game.pak` release build, the Android Gradle project and the iOS Xcode
project export fine here; Linux, macOS and the web export need `factoria setup players` (a download) and the Android
APK/AAB needs an NDK or the prebuilt players plus a Gradle download.** Nothing was uploaded anywhere.

## 1. What the project sets up (`factoria.json`)

| Setting | Value | Used by |
|---|---|---|
| `name`, `id` | `Lantern Keep`, `com.factoria.examples.lanternkeep` | window title, exe name `lantern-keep`, Android `applicationId`, iOS bundle id, the save folder |
| `version` | `1.0.0` | exe version info, Android `versionName` (and `versionCode` 10000), iOS `CFBundleShortVersionString`, upload versions |
| `display` | 1280x720 design, `scaleMode: fit`, `orientation: landscape` | desktop window, Android `sensorLandscape`, iOS orientation |
| `platforms` | windows, macos, linux, web, android, ios | the export warns when a platform is missing |
| `icon` | `assets/icon.png` (1024x1024, opaque) | every export builds its icon sizes from it; also the window icon on Windows and Linux |
| `export.android` | `format: aab`, `minSdk 26`, `targetSdk 36`, `versionCode 10000`, adaptive icon `assets/icon_fg.png` (432x432) on `#141428` | Google Play bundle; no signing block yet (see section 4) |
| `export.ios` | `iconBackground #141428`, `buildNumber 1.0.0`, `usesNonExemptEncryption false` | App Store Connect |
| `export.macos` / `export.linux` | games category, minimum macOS 11.0, copyright; `Game;ArcadeGame` | `Info.plist`, `.desktop` file |
| `export.scriptBytecode` | `true` | `--release` and web: scripts are compiled inside `game.pak` |
| `publish.*` | **placeholder ids, all fake** (below) | the `publish.<store>` commands |

**The `publish` ids are placeholders.** They only show the format. Replace every one with the real value from the
store's partner site before a real upload:

| Where | Fake value | Replace with |
|---|---|---|
| `publish.steam.account` | `FAKE_steam_build_account` | your Steam build account |
| `publish.steam.depots` | `9000001`, `9000002`, `9000003` | one depot id per platform (and write the app id to `steam_appid.txt`) |
| `publish.itch.game` | `fake-studio/lantern-keep` | `<your itch user>/<page name>` |
| `publish.epic.*` | `FAKE-org-id`, `FAKE-product-id`, `FAKE-client-id`, `FAKE-artifact-*` | Dev Portal ids |
| `publish.gog.productId` | `1000000001` | the GOG product id |
| `publish.appstore.appleId` | `1000000002` | the Apple ID of the app in App Store Connect |
| `publish.googleplay` | `internal`, `draft`, changelogs `store/whats-new-*.txt` | fine as is for a first upload |

Other files this package added: `assets/icon.png`, `assets/icon_fg.png` (made by `tools/make_icon.py`, Pillow, no AI;
provenance recorded in `assets.json`), `prefabs/ui/touch_controls.prefab.json` (on-screen gamepad), `store/` (texts),
`.store/screenshots/` (screenshots), `tools/make_screenshots.py`, `tests/shipping.test.js`.

`factoria.json` has a `platform` section owned by the store-services package; this package did not touch it.

## 2. The game on a phone

- **On-screen gamepad** (`factoria docs read mobile`, "On-screen gamepad"): `touch_left` and `touch_right` are
  `TouchButton`s `DpadLeft`/`DpadRight`, `touch_jump` is `A`, `touch_pause` is `Start`. They press the same actions as a
  pad (`move_left`, `move_right`, `jump`, `pause` already list those pad bindings), so no script changed. They draw only
  while the last input was a finger (`touchOnly`), so a desktop player never sees them. Layer 120, under the menus.
- **Safe area**: the HUD texts and the four buttons have `safeArea: true` (the buttons by default), so a notch or the
  home indicator never covers them. The HUD's dark bar stays full width on purpose. Checked with
  `game.setSafeArea("phone-landscape")` (the test below and the screenshots).
- **Landscape**: `display.orientation: landscape` becomes `sensorLandscape` in the Android manifest (verified in the
  generated project).
- **Test**: `tests/shipping.test.js` drives touch with `game.touchStart/touchEnd`: left, right, jump, run + jump with two
  fingers, pause, the notch case (it reads the button rectangles from `ui.state`, because they move with the insets).
  The engine lets a test drive touch, so this runs headless in about 1 s. **Not tested: a real phone** (fingers, multi-touch
  latency, whether the buttons are comfortable at real physical size).
- The menus (Play, Options...) work with a tap because buttons react to touch like to the mouse; the level end panel and
  the pause panel are the same buttons. Nobody has tapped them on a phone.

## 3. Exports run here

All commands from `examples/lantern-keep/`, with `factoria` = the prebuilt Debug binary, `--out .factoria/exports...`
(git-ignored, nothing committed). Times are wall clock. The player of this machine is a **Debug** build: 24.5 MB; a
release player is smaller, so sizes below are an upper bound.

| Export | Command | Time | Size | Result |
|---|---|---|---|---|
| Windows folder | `factoria export --platform windows --out .factoria/exports` | 1.2 s | 25.6 MB, 80 files (`lantern-keep.exe` 24.5 MB, `game/` 1.1 MB, notices 58 KB) | OK. `lantern-keep.exe --version` prints `factoria_player 0.1.6`; started with `--scene scenes/levels/2-1.scene.json`, still alive and responding after 6 s, `log.txt`: scene loaded (51 entities), `player: 60 frames rendered`, no warning or error. |
| Windows release | `factoria export --platform windows --release --out .factoria/exports-release` | 1.1 s | 25.6 MB, **4 files**: `lantern-keep.exe`, `game.pak` 1.0 MB, `FACTORIA_NOTICES.txt`, `.factoria-export` | OK, same smoke test as above (the pak is read, scripts are bytecode). |
| Web | `factoria export --platform web --out .factoria/exports-web` | 0.05 s | none | **Failed before writing anything**: `error: export: no web player found: factoria_player.js and factoria_player.wasm are not in .../build/orch/tools/cli/web, <FactorIA home>/players/<version>/web (factoria setup players --platforms web), .../build/web-release/player (a web build of the engine source)`. Fix: `factoria setup players --platforms web` (a download) or an Emscripten build. Not done (no downloads allowed). So **the web build was never run**; the zip that itch.io takes (`lantern-keep-web.zip`) would hold `index.html`, `factoria_player.js/.wasm` and `game.pak` (about 1 MB plus the wasm). |
| Android Gradle project | `factoria export --platform android --format gradle --out .factoria/exports-android` | 4.4 s | 109 files | OK. Manifest checked: `sensorLandscape`, `applicationId com.factoria.examples.lanternkeep`, `versionCode 10000`, `versionName 1.0.0`, min 26 / target 36, icons in `mipmap-*` (adaptive icon included), only the `VIBRATE` permission, `hasCode false`. Mode `source`. |
| Android APK / AAB | `factoria call project.export '{"platform":"android","format":"apk","dryRun":true}'` | instant | n/a | The plan passes: JDK 21 (Android Studio), SDK 36 found. **A real build was not started**: it would need (a) the Gradle 8.14.3 distribution, not cached on this machine (the wrapper downloads it), (b) in `source` mode the NDK r27 and CMake 3.31.6, neither installed (`<sdk>/ndk` and `<sdk>/cmake` do not exist) and a compile of the whole engine, or in `prebuilt` mode the players of `factoria setup players` (48 MB, missing). So Android stops after generating the project; **no APK or AAB exists and none was installed on a device or emulator.** |
| iOS project | `factoria export --platform ios --out .factoria/exports-ios` | 4.2 s | 84 files | OK as a project (`build_ios.sh`, `Assets.xcassets` with the 1024 icon, `PrivacyInfo.xcprivacy`). Building needs a Mac with Xcode: **not checked**. |
| Linux | `factoria export --platform linux` | 0.06 s | none | Failed as documented: `cannot export for linux from a windows machine without a player binary built for linux` (hint: `factoria setup players`). Not run. |
| macOS | `factoria export --platform macos` | 0.05 s | none | Same error for macos. Not run. A `.app` made on Windows cannot be signed or notarized (`sign.macos` needs a Mac). |

The game logs one thing worth knowing: with an English default, a Spanish Windows starts in Spanish (`i18n: Language
es (default en; ...)`). That is intended (`localization`); a store tester will see the language of their OS.

**What the export does not ship** (docs): `tests/`, `tools/`, `types/`, `ENGINE_FEEDBACK.json`, `AGENTS.md`, `CLAUDE.md`,
the top-level README and every dot-folder (so `.store/` and `.factoria/` stay out). **What it does ship that it need not**:
`levels/` (80 KB of map sources), `screenshots/` (320 KB of P1's screenshots) and `store/` (a few KB of texts). The export has
no exclude list (ENGINE_FEEDBACK), which is why the 2 MB of store screenshots live in the dot-folder `.store/`: in `store/`
they tripled `game.pak`.

## 4. Per store

Common to all of them: the **AI content disclosure** is "none": `factoria call assets.disclosure` says no asset is
recorded as AI-made (every file has a provenance record: the tileset and jump sound come from the template, the rest were
drawn or synthesized by scripts, CC0), so the export writes no `AI_CONTENT_DISCLOSURE.md` and the store's AI question is
answered "no AI-generated content, none generated live". If you add AI assets later, record them with
`assets.set_provenance`/the generate commands and the file appears. The game has **no network code**, no ads, no
purchases, no account: privacy answers are "no data collected" (but see section 6: the store services package may add
Steam/Apple/Google services that change some answers).

### Steam
- **Set up**: Windows, macOS and Linux targets, icon, version, `publish.steam` (fake account, depots 9000001..3, no branch),
  store texts in `store/store.en.json` / `store.es.json` (Steam short description limit 300, ours are under 80), screenshots
  `steam-1920x1080-*.png` (six).
- **Engine does**: `publish.steam` writes the `.vdf` files and runs `steamcmd`. Tried the dry run with a fake uploader and a
  fake app id: plan for `windows -> Steam app 9000000, depot 9000001, 89 files, 27.7 MB`, command
  `steamcmd +login FAKE_steam_build_account +run_app_build .../app_build_9000000.vdf +quit`.
- **By hand**: Steamworks account and the 100 USD app fee, the app, depots and package, the store page (capsules: header
  460x215, small 231x87, main 616x353, vertical 374x448, hero 3840x1240, logo; **none made here**, the icon is only a start),
  trailer, the content survey, the age rating questionnaire, tags (`store.*.json` has suggestions), pricing, release review.
  `steam_appid.txt` (written by `platform.add_backend`, the store-services package). Log in once with `steamcmd +login`.
  Upload macOS and Linux depots from that OS (the executable bit).
- **Could not check**: a real `steamcmd` run, Steam Deck behaviour, the overlay.

### itch.io
- **Set up**: `publish.itch.game` (fake `fake-studio/lantern-keep`), channels `windows`/`mac`/`linux`, the web zip.
- **Engine does**: `publish.itch` -> `butler push <export folder> fake-studio/lantern-keep:windows --userversion 1.0.0
  --ignore .factoria-export --ignore AI_CONTENT_DISCLOSURE.md` (dry run checked with a fake butler). The web export
  produces `lantern-keep-web.zip` for an HTML5 page; `butler push build/export/lantern-keep-web.zip <user>/<game>:html5`.
- **By hand**: account, the page (the long description is `store.en.json` `longDescription`), screenshots, cover image
  (630x500 recommended: **not made**), butler login, choosing "played in the browser" and the viewport (1280x720) for the web
  build, pricing/donations.
- **Could not check**: the web build itself (no web player here), butler, how it plays in a browser (audio unlock,
  gamepad, fullscreen).

### Epic Games Store
- **Set up**: `publish.epic` with fake organization/product/client/artifact ids.
- **Engine does**: `BuildPatchTool ... -mode=UploadBinary` dry run checked with a fake tool and secret (needs
  `FACTORIA_EPIC_CLIENT_SECRET`). `-AppLaunch=lantern-keep.exe`.
- **By hand**: Epic Games Dev Portal account (and Epic's approval to publish: it is curated), product, artifacts, the Build
  Patch Tool client and secret, store page, ratings, review. The Epic Online Services are not used (no achievements).
- **Could not check**: a real upload.

### GOG
- **Set up**: `publish.gog` (product `1000000001`, languages `en-US`, `es-ES`).
- **Engine does**: writes `gog-windows.json` and `ignore.txt` and runs Pipeline Builder (dry run checked with a fake tool).
- **By hand**: GOG accepts games by invitation after a review of the game and a Developer Portal product; builds must
  be published from the portal; GOG wants a game without DRM (this one has none), an offline installer (the engine does not
  make one: GOG builds it from the files) and screenshots/art in their sizes (not made).
- **Could not check**: a real upload; GOG's own requirements for the Windows build (they may want an installer-friendly
  layout).

### Microsoft Store
- **Set up**: nothing store-specific: the Windows folder and the icon.
- **Engine does**: **nothing** for this store. There is no MSIX package, no `export.windows` setting besides `icon`, no
  `publish.microsoft` (ENGINE_FEEDBACK FB-0019).
- **By hand**: Partner Center account (registration fee), reserve the name, build an MSIX (`makeappx` from the Windows SDK or
  the MSIX Packaging Tool) from the exported folder with an identity, publisher and tile logos at the store's sizes, sign it
  (the Store signs it for you after submission), upload, age rating (IARC), privacy policy URL, certification. Or ship it as
  an installer from a URL (the Store accepts that for desktop apps).
- **Could not check**: the packaging at all (no Windows SDK tools were installed or used here).

### Google Play
- **Set up**: `applicationId` from `id`, `versionCode 10000`, `aab` format, adaptive icon, landscape, touch controls,
  `publish.googleplay` (internal track, draft, release notes `store/whats-new-en.txt`, `store/whats-new-es.txt`), store texts
  (title 30 / short description 80 characters: `store/store.*.json` fit), phone screenshots `phone-landscape-1920x1080-*.png`.
- **Engine does**: builds a signed `.aab` with `factoria export --platform android --format aab --release` (**not run**: see
  section 3) and uploads it with `publish.googleplay` (fastlane). The `publish.googleplay` dry run stops here with
  `there is no bundle to upload ... lantern-keep.aab does not exist`.
- **By hand**: Play Console account (one-time fee, identity verification), the app, **upload the first bundle yourself**, a
  **keystore** (`keytool -genkeypair ...`; keep it outside the repository, then add
  `"signing": {"keystore": "<path>", "alias": "upload"}` to `export.android` and set
  `FACTORIA_ANDROID_KEYSTORE_PASSWORD`/`..._KEY_PASSWORD`), Play App Signing, the store listing (icon 512x512: derive it from
  `assets/icon.png`; feature graphic 1024x500: **not made**), content rating questionnaire, target audience, **Data safety:
  "No data collected / not shared"**, a **privacy policy URL** (Play requires one on every app), the closed-testing
  requirement for new personal accounts (12+ testers for 14 days before production, per Google's current policy: check),
  the 16 KB page-size rule is handled by the engine's libraries.
- **Could not check**: an APK/AAB on a device or emulator, the touch controls on a real screen, the Play pre-launch report.

### App Store (iOS)
- **Set up**: bundle id from `id`, version 1.0.0, build number `1.0.0`, landscape, icon (1024, opaque, over `#141428`),
  `usesNonExemptEncryption false`, `publish.appstore` (fake Apple ID), screenshots `phone-landscape-2208x1242-*.png`
  (the 5.5-inch landscape size; newer sizes such as 2868x1320 for the 6.9-inch are **not made**).
- **Engine does**: the Xcode project (`build_ios.sh`), `PrivacyInfo.xcprivacy` (nothing collected, no tracking),
  `Info.plist`. `publish.appstore` uploads an `.ipa` you build; it only runs on a Mac.
- **By hand**: Apple Developer Program membership, App Store Connect app record, a Mac with Xcode to archive and export the
  `.ipa` (the engine does not make it), the team id (`export.ios.teamId` or `FA_IOS_DEVELOPMENT_TEAM`), the App Store API
  key, App Privacy label ("Data Not Collected"), age rating, review notes, a privacy policy URL, review.
- **Could not check**: everything from the CMake/Xcode build onward (no Mac).

### The web (own site or itch.io)
- **Set up**: `export --platform web` needs no settings (no icon, no `export.web`); the page title is the game's name.
- **Could not check**: it never ran (no web player on this machine). Open questions: first-frame download size, WebGL 2
  on the target browsers, audio only after a click, localStorage saves, the touch controls in a mobile browser.
- **By hand**: hosting (any static host; `.wasm` as `application/wasm`), a domain, a privacy note.

## 5. Store page material (`store/`, `.store/`)

- No store-text layout exists in the engine (the docs have none; only `publish.googleplay.changelogs` reads plain text
  files). The layout used here is plain: `store/store.en.json` and `store/store.es.json` with `name`, `subtitle` (30 characters
  for the App Store), `shortDescription` (80, Google Play), `longDescription`, `features`, `keywords` (joined with commas
  under 100 characters for App Store keywords), `tags` (Steam), `category`, `ageNotes`; `store/whats-new-en.txt` and
  `whats-new-es.txt` (release notes, under 500 characters). `tests/shipping.test.js` checks the lengths.
- Screenshots (`.store/screenshots/`, from `python tools/make_screenshots.py <factoria>`, headless runs, no GPU or window):
  six `steam-1920x1080-*.png` (menu, Courtyard, a level with a gap, the Cellars, the lantern lighting the bricks, the level end
  panel) and two scenes for phones as `phone-landscape-1920x1080-*` and `phone-landscape-2208x1242-*` with the touch
  controls and a notch (`phone-landscape` safe area).
- **The engine renders only at the design size** (1280x720): `--width/--height` change the design, so a 1920x1080 run
  shows 1.5x more of the level and a stretched HUD. The store sizes are therefore the 1280x720 renders **enlarged with
  Lanczos** (exactly 1.5x for 1920x1080): fine for a first listing, soft next to native art. They are not the screenshots
  of a real phone. Redo them on a device before launch (ENGINE_FEEDBACK FB-0013).
- Not made: Steam capsules/hero/logo, Google Play feature graphic, itch.io cover, a trailer, a 512x512 Play icon, the
  Spanish-language screenshots (the images are English, the game's default; `i18n.setLanguage("es")` before a run gives
  Spanish ones).

## 6. Crash reports, `log.txt`, version, licenses

- **`log.txt`**: every run writes it (rewritten at each start) to the save folder: on Windows
  `%APPDATA%\com.factoria.examples.lanternkeep\log.txt`, on Linux `~/.local/share/com.factoria.examples.lanternkeep/`,
  on macOS `~/Library/Application Support/com.factoria.examples.lanternkeep/`. Ask a player for it. Checked here: it exists
  and has the startup lines above.
- **Crash reports**: a crash writes `crashes/crash-<UTC time>.txt` (and `.dmp` on Windows) in the same folder, the last five are
  kept, and the next start logs one line about it. The `crashes/` folder was created on first run here (empty: nothing crashed).
  Nothing is sent anywhere; the engine has no crash upload. Android and iOS use their own tools (`adb logcat`, Xcode
  Organizer, Play Console "Android vitals"). **No crash was provoked to test the reporter.** Keep the `.pdb` of a release
  build if you want line numbers in the stack.
- **Version information of the exe** (Explorer, Details): checked with `Get-Item ...exe | VersionInfo`:
  `FileDescription` and `ProductName` `Lantern Keep`, `FileVersion` and `ProductVersion` `1.0.0`, `InternalName`
  `lantern-keep`, `OriginalFilename` `lantern-keep.exe`. The exe's icon is the lantern (extracted and looked at). The exe is
  **not code-signed** (a source build; the release downloads carry FactorIA's signature, which the export removes when it
  writes the icon and version): SmartScreen may warn. Sign with `signtool sign /fd SHA256 /tr <timestamp url> /td SHA256 /a
  lantern-keep.exe` and your own certificate.
- **Licenses**: `FACTORIA_NOTICES.txt` is written next to the exe by every export and must travel with the game (zip,
  installer, store build). The game's credits screen lists the runtime software too. The game's own files: code and
  art by the project, assets CC0 (see `assets.json`); nothing in the project says how *you* license Lantern Keep: pick a
  license (or none) before publishing the source.
- **Privacy**: no network, no analytics, saves local. This changes if the store-services package adds Steam/Apple/Google
  services: re-read the "Store privacy forms" of `factoria docs read mobile` then.

## 7. Before the first real release (the checklist)

1. Release builds, not Debug: use the downloaded FactorIA (its player is release-built, signed, and the downloads carry the
   prebuilt Android/iOS libraries and the web player), then `factoria setup players` and export every platform.
2. Replace the fake ids in `publish` and write `steam_appid.txt`.
3. Make the Android keystore, set the passwords in the environment, add `export.android.signing`, build the `.aab`, upload
   the first one by hand.
4. Test on a real phone (touch, safe area, rotation, Back button), a Steam Deck/pad, and a clean Windows machine.
5. Redo the screenshots natively, make the store art, write the privacy policy page, fill in every store form and rating.
6. Raise `version` (and `export.ios.buildNumber`, `export.android.versionCode`) for every upload: every store takes a
   number once.
