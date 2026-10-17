# Engine feedback report

Status: 73 entries reported by the four example games, all 73 verified fixed-in-engine (M6 closed the last 10). No entry is open, every milestone (M1-M9) is done (M9: run on Apple hardware); M5 closed the proactive 3D-physics and gamepad gaps, M7 the gaps found while implementing M5 and M6, and M8 those found in M7 plus the desktop download's next steps. What only certificates, real devices or a device farm can close is listed under M8 and M9, "Left open". M10-M23 come from an external evaluation of v0.1.4 (re-triage 2026-10-16): what it still takes to ship a game to the stores; M10 (game UI and menus), M11 (native plugins) and M15 (asset pipeline) are done; M12 (platform services) has its API and the Steam, Apple and Google Play backends; the rest is not started. The history of finished milestones (what was built, what was fixed on the way) is in [ROADMAP_DONE.md](ROADMAP_DONE.md); this file keeps what they left open and the decisions to respect.
Regenerate the ranked list with `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push --out feedback/ROADMAP.md` (then re-add the milestones section).

0 entries from 4 project(s), 0 distinct gap(s). Ranked by total occurrences x severity weight (blocker 8, major 4, minor 2, nice-to-have 1).

_No open feedback entries._

# Next engine milestones

Hand-written triage section (the ranked list above is generated; regenerate it with the command in
`feedback/README.md` and keep this section). Triage date 2026-10-13, against commit `e2b0090`: of the 55
entries from the four example games, the engine already fixed most; the work packages below cover what is left,
plus two packages for gaps seen while verifying that no game has hit yet (marked *proactive*).

Earlier re-triages (2026-10-13 and 2026-10-14) are in [ROADMAP_DONE.md](ROADMAP_DONE.md).

Re-triage 2026-10-16, after `497303d` (v0.1.4), from an external evaluation: a veteran developer tried to take a game
from `factoria new` to every store with v0.1.4 and listed 82 numbered gaps plus a few notes (the ids below are the
report's: H tools, F engine features, E exports, S store services, A asset generation, D docs, U game menus, Q production
quality; the report itself is not in the repository). Every gap was checked against the code; all of them held.
- Fixed in the same PR as this triage: E-01 (the Windows player and every exported exe are GUI programs: no console
  window, and a terminal that starts one still gets its log), E-02 (the exe's version information is the game's name
  and version), E-06 in part (every run writes `log.txt` in the save folder; crash reporting is M13), E-11 (paths over
  260 characters on Windows; with `--json` a failure prints a JSON error object), Q-07 (a missing glyph logs one warning
  per font naming the characters and a font that has them) and D-06 (GETTING_STARTED status table).
- Already listed, not repeated: E-03 and Q-02 (M8, "Left open"), H-11 and the Android shutdown part of F-10 (M9, "Found
  while implementing M9"). Q-01 (the project's age, one maintainer) and Q-08 (a strength) are not engine work.
- Everything else, and the points of the report's per-store table that no id covers, is grouped in M10-M23 below, in
  the report's order of priority: what blocks any store release first.
  Roblox is out of scope (end of the list). None of these gaps came from the four example games, which are jam-sized and
  never needed menus, localization or stores; M21 adds a complete reference game to close that blind spot.

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP).

## M1-M7 — DONE

Docs and templates (M1), CLI diagnostics (M2), 2D level authoring (M3), bloom (M4), 3D physics 2.0 and gamepads (M5),
polish found while migrating the examples (M6), their leftovers and the mobile players in CI (M7). Nothing they found is
open; what they built is in [ROADMAP_DONE.md](ROADMAP_DONE.md).

## Decisions of finished milestones

Kept here because later work has to respect them (the full story is in ROADMAP_DONE.md):
- M3: there is no `CameraFollow2D` component; a camera that follows within level bounds is the AI_GUIDE 9.6 recipe.
  `scene.import_ascii` does not keep its legend in the scene, so `factoria validate` checks the Tilemap data instead.
- M4: bloom is flat `Camera` fields (`bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`) because reflection has
  no nested structs. It costs about 5 ms per drawn frame at 1280x720 on llvmpipe (the target was 2 ms); a backend that
  cannot create it logs one error and draws without bloom.
- M5: gamepad bindings keep the names reserved since 0.1 (`GamepadA`, `GamepadLeftStickLeft`...), not `Gamepad:A`; a
  binding matches any of 4 pads; `input.value` is analog with a radial deadzone (`input.deadzone`, default 0.2) and an
  action is down at 0.5.
- M6: file-targeted component edits are the `edits` argument of `scene.import_ascii` (file mode, the
  `scene.set_component` code); scene, prefab and JSON files are written through `fs::write_bytes` (a temporary file
  renamed over the target).
- M8: spheres with `rollWithMotion` keep the arcade model, other spheres are rigid bodies; boxes do not roll
  (`angularDamping` is their spin drag). Mobile exports use the package's prebuilt players (`mode: prebuilt`), the
  engine checkout only when asked for or when factoria runs from a source build (`mode: source`).
- M9: the players ask for OpenGL ES 3.0 and sokol_gfx is told 3.0 even when the driver reports more: the engine uses no
  ES 3.1 feature. On Android, sokol_app's exit in `onDestroy` is turned into `_exit(0)` and the activity is
  `stateNotNeeded`, so the system starts the game again in a new process. macOS exports are signed ad hoc after every
  file is written; Developer ID signing then needs `--force`.
- M10: UI focus comes only through `autoFocus` or `ui.focus`, so Space or A never clicks a HUD button (the templates
  decision is in M10 below).
- M11: a plugin that does not load is a warning, and its reason becomes the script's error.
- M15: exports ship the import settings of `assets.json` and drop provenance and style.

## M8. Leftovers of M7, desktop download next steps (L, *proactive*)

Closes the "Found while implementing M7" and "Desktop download: next steps" lists (both in ROADMAP_DONE.md). One worker
branch per package, merged together in PR #29.

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M8.

Left open, not fixable in this repository alone:
- Certificates: an Authenticode certificate or Azure Trusted Signing is needed before the Windows signing step does
  anything (macOS signing is set up since M9). New Authenticode certificates come on a token or a cloud HSM, so the
  `.pfx` path in `scripts/sign-windows.sh` may have to become that service's signing action.
- GitHub-hosted runners cannot run an arm64 Android emulator (no KVM on `ubuntu-24.04-arm`, no nested virtualization on
  macOS) and have no real GPUs; that needs a device farm with an account. `simctl` cannot tap, so iOS touch is not run.
- No real gamepad has been used on Linux or Android; the Android Z/RZ trigger scaling is taken from Android's docs.
- 3D: a kinematic body's own rotation within a sub-step is not swept; in an extreme pile of impacts a body lags in time
  instead of tunnelling.
- The AppImage does not update itself (AppImageUpdate/zsync would), and after an in-place update the Windows "Apps" list
  still shows the installed version.

## M9. Run on Apple hardware (M, *proactive*) — DONE (PR #33 and the `m9-apple-hardware` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M9.

Left open after M9:
- An Apple pad on iOS: same code as macOS, built and run, but not with a real pad. The iOS Simulator shows a virtual
  `Gamepad (MFi)` in slot 0.

Found while implementing M9, not fixed:
- Windows has no window read-back for the editor (D3D11), so the editor autotests are not registered there.
- Android: when the activity is destroyed the engine is not shut down (sokol_app calls `cleanup` only while a surface
  exists, and the surface is always gone by `onDestroy`; the process now ends with `_exit`), so a game gets no callback
  when it closes or restarts. `storage` saves on every write, so nothing is lost today.

## M10. Game UI and menus (L, blocker for every store) — DONE (PRs #47, #50, #51, #53)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M10.

Decision (2026-10-16): templates stay minimal (the empty ones are a camera and nothing else); a game's AI builds menus
from the recipe when its game needs them.

Left open:
- `TextField`: the caret stays at the end (no caret movement, selection or IME composition). The Steam Deck floating
  keyboard is M12; mobile on-screen keyboard polish is M16.
- Layout and hit-tests ignore the rotation and scale of UI entities; a `Sprite` inside a container needs an explicit
  `size` (texture sizes are not measured by the layout). 9-slice for `Sprite` is M18.
- Window control on macOS, iOS, Android and a real Linux desktop is compiled in CI but was not run on those systems
  (Windows was). Android pads always report `generic`; X11 `displaySize` is the whole screen, not the usable area; on
  macOS vsync off tears but keeps the display's frame rate (sokol paces frames with a display link).
- Save slots with their menu are M19; a GDPR/COPPA consent screen on these menus is M22.

## M11. Native plugins per game (L, blocker for M12 and the consoles) — DONE (PR #49 and the `m11/plugins-mobile` PR)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M11.

Left open:
- iOS takes static libraries only: no Swift packages or XCFrameworks (system frameworks, the Swift runtime and
  entitlements came with M12's Apple backend: the plugin's `ios/plugin.json`, docs/MOBILE.md).
- An Android plugin that is only a Maven dependency in its `build.gradle` (no Java/Kotlin sources, no `.aar` / `.jar`)
  keeps `hasCode="false"`; the export cannot see that it brings code.
- A missing ABI's `.so` on Android is not a warning (the module may build it itself); on a device of that ABI the
  plugin just does not load.
- The desktop export copies plugin folders with `std::filesystem::copy`: very deep plugin folders can hit MAX_PATH on
  Windows.

## M12. Platform services API (L, blocker for Steam and for any monetization)

Closes S-01..S-08 (S-09 is in M23), and the Play Integrity, iCloud and Steam Deck keyboard points of the per-store
table. Needs M11.

- A `platform` JS module: achievements, stats, leaderboards, cloud saves, purchases (with restore and receipts), overlay,
  presence, and `platform.has("achievements")`. A fake backend runs in `factoria test` and headless runs, with
  `game.platform` hooks to script store answers in tests.
- Backends as M11 plugins, in this order: Steamworks (S-02; `steam_appid.txt` in development runs), StoreKit 2 and Game
  Center (S-04, S-05), Play Billing and Play Games v2. Then Epic Online Services and GOG Galaxy (S-03), ads with
  consent (Google UMP, Apple ATT; S-06), analytics and remote config (S-07), push notifications and deep links (S-08).
- Steamworks also brings the Steam Deck's on-screen keyboard (`ShowGamepadTextInput`, the floating keyboard) for M10's
  text field; M16's keyboard is mobile only.
- Play Integrity (Google Play) next to Play Billing, and iCloud as a cloud-save backend next to StoreKit.
- Later: the purchase SDKs of Android stores outside Play (Amazon Appstore, Samsung Galaxy Store, Huawei AppGallery).

Acceptance criteria:
- Achievements and a purchase flow pass with the fake backend in a test (on the M10 menus fixture).
- With the Steamworks plugin and Valve's test AppID 480, an exported desktop game unlocks an achievement (manual check,
  steps in the docs).

Done so far (package A, branch `m12/platform-api`): the API, the fake backend and plugin ABI v2; no store backend yet.
- **`fa_services`** (new module, `fa/services/platform.h`): the `"platform"` catalog of factoria.json (achievements,
  stats, leaderboards, products, per-backend store `ids`, `backend`; teaching errors, `factoria validate` and the
  project schema), the request protocol `(method, args) -> one answer`, the `PlatformServices` dispatcher (ids checked
  and `storeId` filled in before a backend sees a request; answers from any thread, delivered at the start of a frame),
  the `PlatformBackend` interface, the deterministic fake backend (scripted answers, `delayFrames`, `signedIn`, events,
  a request log) and the "none" backend. The `platform.*` commands (`state`, `reset`, `respond`, `emit`, `set_fake`).
- **Scripts**: `platform` in the `factoria` module (every call a Promise; mistakes throw with a "did you mean", store
  failures reject with `.code` and `.hint`; `platform.on` for `purchase`, `overlay`, `player`), and `game.platform`
  in `factoria:test`; `await` works in tests.
- **Plugin ABI v2** (`fa_plugin.h`): `add_backend`, `FaRequest`, `resolve`, `reject`, `emit`; version 1 plugins load
  unchanged. Backend choice: `platform.backend`, `EngineConfig::platformBackend/platformFallback`; headless runs and
  tests use the fake, an exported game without a store plugin gets "none" (never free purchases). `project.new_plugin`
  takes a `template` (the folders of `platforms/plugins/`, none yet).
- **Docs and fixture**: `docs/PLATFORM.md` (API, catalog, errors, fake store and testing, writing a backend plugin);
  the menus fixture has a shop (consumable gems, a non-consumable, restore) and `tests/platform.test.js`: buying gems
  through the pad adds them and finishes the transaction, a cancelled buy and a `network` failure grant nothing, a
  delayed answer shows "waiting", restore returns the non-consumable, an achievement unlocks during play and the
  overlay event pauses the game (the first acceptance criterion).

Done so far (package B, branch `m12/steam`): the Steamworks backend.
- **`platforms/plugins/steam`** (the `"steam"` template of `project.new_plugin`, a C++17 plugin with no Valve file in the
  repository): it loads Valve's redistributable at run time (`steam_api64.dll`, `libsteam_api.dylib`, `libsteam_api.so`,
  next to the plugin first), declares the part of the flat API it uses itself and finds the versioned interfaces by name
  (checked against SDK 1.58 to 1.64; a newer SDK such as 1.65 is used with a warning when every function the plugin calls
  is present, probing up to five interface versions above the known ones; anything else is refused with what was tried). Steam
  starts in `fa_plugin_init`
  (`SteamAPI_InitFlat`, `SteamAPI_Init` on old libraries), callbacks run by manual dispatch in the plugin's `frame`, and
  the dev app id comes from `steam_appid.txt` (project folder or working folder; 480 is Valve's test app). Every failure to
  start is a teaching log line and the engine falls back (fake in development, none in an exported game).
  Achievements (unlock, progress, list, reset), stats, leaderboards (created on first use, keep-best uploads, top, around
  and friends), Steam Cloud (`<key>.json`), DLC purchases (`pending` through the overlay cart, a `purchase` event when the
  DLC arrives), overlay, rich presence, and the events `overlay`, `purchase`, `player`. Consumables and subscriptions are
  `unavailable` (Steam's microtransactions need the game's own server). The command `steam.status` shows what the plugin found.
- **Tests**: a mock of the Steamworks library (`platforms/plugins/steam/tests/mock_steam_api.cpp`, built as a shared library
  with the redistributable's file name, in a current, an older (SDK 1.58 to 1.60), a next (one interface version above the newest known) and a far-future variant) and ctest `steam_plugin_*`
  (Linux, Windows, macOS): the real plugin in an Engine with `platformBackend="steam"` covers every method and event, stats that
  load late, Steam failing to deliver or to start, a late answer after the engine ended, a stray call result, a missing
  library, Steam not running, no app id, the services again on a library with newer interface versions (used, one warning), a
  library too far ahead (refused), and the exit on Linux and macOS (stats stored, `SteamAPI_Shutdown`). `tooling` tests build
  the plugin through `platform.add_backend` with an SDK folder and a .zip.
- **`platform.add_backend {"backend": "steam"}`**: writes and builds the plugin, copies the three libraries from the SDK folder or
  .zip, writes `steam_appid.txt` (default 480), and `factoria export` never ships that file. Docs: the Steam section of
  `docs/PLATFORM.md` with the numbered manual check against app 480, and `plugins/steam/README.md`.

Left open (Steam):
- **The manual check with app 480 has not run**: it needs a Steam client and account, which the machine that built this did
  not have (`docs/PLATFORM.md`, "Manual check with Valve's test app 480"). Everything above is tested against the mock only,
  so struct layouts, callback ids and interface versions rest on the public Steamworks headers (SDK 1.58a to 1.64); a real
  SDK 1.65 library (it replaced `ISteamUtils::IsRunningOnSteamDeck`) has not been tried either. Whether
  Steam's overlay appears over the engine's Metal (macOS), OpenGL (Linux) and Direct3D 11 (Windows) windows is unchecked.
- **The Steam Deck on-screen keyboard for `TextField` is not wired.** The plugin API has no hook for it: it needs (1) a
  notification to the plugin when a text field takes or loses focus (with the field's rectangle, its text and whether it
  is multi-line; `Input::keyboard_shown()` is today applied by the windowed runtime to the phone soft keyboard only) so the
  Steam plugin can call `ISteamUtils::ShowFloatingGamepadTextInput` / `ShowGamepadTextInput`, and (2) a call for the plugin
  to hand text back to the focused field (`FloatingGamepadTextInputDismissed_t` / `GamepadTextInputDismissed_t` and
  `GetEnteredGamepadTextInput`). Players on the Deck can use Steam's own keyboard (Steam + X).
- Steam Inventory, microtransactions (`ISteamMicroTxn`), Steam Input and the workshop are not wrapped; there is no `SteamAPI_RestartAppIfNecessary`
  (a shipped game started outside Steam runs without platform services); prices of DLC are not shown (Steam gives them on its store page).
- On Windows the plugin does not call `SteamAPI_Shutdown` at exit (a DLL's exit handlers run after Steam's own DLL is gone);
  stats are stored every frame, so only the last frame's changes could be lost.
- Every engine that loads the plugin starts Steam, `factoria test` and MCP sessions included; the plugin API cannot tell a plugin
  which backend the engine chose, so the fake-store runs show up as "playing" in Steam. A lazy start needs an API call for
  "the engine uses your backend".

Done (package C, branch `m12/apple`): the Apple backend, `platforms/plugins/apple`, backend `"apple"` on iOS and macOS.
- **The plugin** (Swift, built with `xcrun swiftc` by its CMake file; a C file is the entry point): StoreKit 2
  purchases (products, buy with Ask to Buy, finish, restore, `purchase` events for updates and unfinished transactions;
  receipts are JWS), Game Center (sign-in with a `player` event, achievements, leaderboards, the access-point overlay),
  iCloud key-value cloud saves, and the command `apple.status`. No stats and no presence (Game Center has none).
  Tests (`apple_backend_tests`) load the real dylib into a real Engine with no signature or Apple Account: every
  request is answered once and in time, each refusal teaches.
- **Plugin manifests**: `ios/plugin.json` / `macos/plugin.json` (system frameworks, the Swift runtime, entitlements),
  merged by the exports: the iOS project links StoreKit and GameKit and the Swift runtime and is signed with
  `factoria_player.entitlements`; the macOS export writes `<game>.entitlements` for the developer's own signing.
  `factoria export --platform ios` also writes `Products.storekit` from the catalog and wires it into the Xcode
  scheme. `platform.add_backend {"backend": "apple"}` writes, declares and builds the plugin. CI: the `ios` job
  links the plugin into the simulator app and checks `Apple backend ready`, `probe backend=apple` and a Game Center
  answer (`FA_IOS_APPLE_PROBE=1`).

Left open for the Apple backend (manual checks, docs/PLATFORM.md "Manual checks"): a real purchase, Ask to Buy, restore,
Game Center sign-in, achievements, leaderboards and iCloud sync need App Store Connect, a development-signed app and a
sandbox account, so no CI job runs them. The scheme reference to `Products.storekit` and the file's schema version are
not yet checked in Xcode itself. A macOS app needs the developer's certificate and provisioning profile for Game Center
and iCloud (the export is ad hoc signed). No `cloudChanged` event when iCloud brings a newer save from another device.

Done (package D, branches `m12/integrity` and `m12/googleplay`): the Google Play backend and a new platform service.
- **`integrity`**, the eighth service (`fa_services`, `platform.integrity.token(challenge)` -> `{ token }`): a signed token
  that vouches for the app and the device, for the game's server to verify. The engine checks the challenge (16 to 500
  characters of URL-safe Base64) and the shape of the answer; the fake answers `fake-integrity-<n>`. Steam and Apple do not
  offer it (`unavailable`).
- **`platforms/plugins/googleplay`** (the `"googleplay"` template, backend `"googleplay"`, Android only): a C bridge (JNI:
  every request goes to `Backend.request` in Java, answers come back through `RegisterNatives` callbacks) and a Gradle
  module in Java on Play Billing 9.1, Play Games Services v2 22.1 and Play Integrity 1.6. Purchases (consumables are
  consumed, the rest acknowledged; pending payments; `purchase` events for unfinished purchases at start and on every
  resume; receipts are Google's signed purchase JSON and signature), the overlay (Play Games screens, the Play Store page)
  and integrity are always on; achievements, leaderboards (25 rows a call) and Saved Games only with a Play Games project
  id in `games-ids.xml` (the plugin removes Play Games' auto-start provider and starts it only then). No stats and no
  presence. Each request answers once, with a 30 s watchdog (restore 120 s). The command `googleplay.status` lists what
  the device lacks.
- **`platform.add_backend {"backend": "googleplay", "playGamesId"}`**: writes and declares the plugin, writes the project id,
  builds the bridge for arm64-v8a and x86_64 with the Android SDK's NDK, CMake and Ninja, and lists the Play Console steps
  with the catalog's ids (product ids Play refuses, achievements and leaderboards without `ids.googleplay`). The exported
  Android project now has `android.useAndroidX=true` (Billing and Play Games need AndroidX).
- **CI**: `android-apk` sets the backend up with `add_backend`, checks the APK (both libraries, the plugin's and Google's
  classes in the dex, the merged manifest and resources); `android-emulator` (an image with no Google Play) checks
  `Google Play backend ready`, the services, `googleplay.status`, and that `signIn()` and `integrity.token` come back
  through JNI as teaching `unavailable`s. Tooling tests cover the setup command and the export of the module.

Left open (Google Play): **nothing has run against Google's services.** Purchases, Play Games and Play Integrity need a
Play Console app, a build on a testing track, license testers and a phone with Google Play (docs/PLATFORM.md section 7,
"CI and manual checks"); CI's emulator has no Google Play, and this machine has no NDK, so the Java was only compiled with
`javac` against the real libraries before CI. Play Games events (increment-only counters) are not mapped to stats;
`achievements.reset()` and the "friends" overlay are `unavailable`; Play Integrity uses the classic request (no Standard
API, no cloud project number, so an app distributed outside Play cannot get tokens). Apple's App Attest is not an
`integrity` backend yet.

Left open (the next M12 packages): Epic Online Services and GOG Galaxy, ads with consent, analytics and remote config, push
notifications and deep links, the Android stores outside Play. `PlatformServices` keeps no receipts or entitlement cache: a
backend answers `restore()` itself. Overlay and presence are one call each; there is no `achievements.onUnlocked`
event, rich presence has no localization, and `platform.stats.add` is a get then a set (not atomic across devices).
Cloud saves take JSON values only (no binary blobs, no conflict resolution beyond "last write wins" in the fake).

## M13. Store-ready desktop export (M-L, high)

Closes E-04, E-05, E-06 (the crash half), E-09 (the desktop half; mobile uploads are M16), E-10, F-15, Q-03 and H-10.
Authenticode signing is M8, "Left open".

- Linux: the release player needs glibc 2.38 and GLIBCXX 3.4.31 (`release.yml` builds on `ubuntu-24.04`), so it does
  not start in the Steam Linux Runtime "sniper" (glibc 2.31), Ubuntu 22.04 or Debian 12. Build it in the sniper SDK
  container or an old-glibc image.
- Packing: with `--release` the game ships as one archive read through `fa::fs` instead of loose files, with optional
  QuickJS bytecode instead of plain `.js`. The export copies the project's `README.md` today; leave out files that are
  not game data.
- Crash reporting next to `log.txt`: a minidump on Windows (`SetUnhandledExceptionFilter`, `MiniDumpWriteDump`), a
  backtrace on POSIX; an optional upload URL, off by default.
- Upload as commands an AI can call: steamcmd (writes the app build VDF), butler (itch.io), Epic's BuildPatchTool and
  GOG's Galaxy Pipeline Builder, with a dry run.
- macOS: Developer ID signing and notarization of the exported `.app` as a command (codesign, notarytool, stapler),
  instead of the manual steps in docs/EXPORTING.md ("To distribute the game...").
- Linux direct distribution: an AppImage or Flatpak of the exported game with its `.desktop` file (the export writes a
  folder and suggests a tar).
- A CI workflow for game projects (validate, test, export), from a template file or `factoria new`.
- `scripts/build.ps1` asks only PATH for `cmake`, so a Visual Studio install with its bundled CMake fails with "cmake
  not found"; find it through vswhere, and warn about checkout paths deep enough for MSBuild's FTK1011 (MAX_PATH).

Acceptance criteria:
- CI runs the release Linux player (`--version` and a headless frame) inside the Steam Runtime sniper container.
- A `--release` desktop export has no loose `.js` and no README.md, and still runs.
- A deliberate crash leaves a crash file with a stack in the save folder.
- `build.ps1` builds on a machine whose only CMake is the one Visual Studio installs.

## M14. Localization (L, blocker for a global release)

Closes F-02, H-08, U-06 and the text-scaling part of U-05. This PR only made missing glyphs visible: Chinese, Japanese and
Korean need a font the game ships, and Arabic draws left to right with unjoined letters.

- String tables (`locales/<lang>.json`), `i18n.t(key, args)` in JS, a `key` field on Text, the system language on every
  platform, a fallback language, `i18n.setLanguage` at run time.
- A font fallback chain (project-wide and per Text), so a CJK font fills what the main font lacks.
- Shaping with HarfBuzz (MIT) and bidirectional line layout for Arabic, Hebrew and Indic scripts.
- `factoria validate` reports characters in string tables and scene texts that no configured font covers, with the file
  and the character (the run-time warning added in this PR is the starting point); CSV or XLIFF export and import for
  translators.

Acceptance criteria:
- `日本語 中文 한국어 العربية` renders every script with Noto fonts, Arabic joined and right to left (golden image).
- `validate` fails on a missing glyph and names the character, the text and the file.
- Switching language at run time updates every Text that has a `key`.

## M15. AI asset generation and import pipeline (L, blocker for "the AI does everything") — DONE (PRs #52, #55, #56, #57)

Built: [ROADMAP_DONE.md](ROADMAP_DONE.md), M15.

Left open:
- SDF/MSDF font atlases: the runtime rasterizes TTF/OTF at any size already; distance-field text belongs with the text
  work of M10/M14.
- Video import: waits for M19's video player, which decides the format.
- Importers: OBJ polygons are triangulated as fans (concave faces come out wrong); Aseprite blend modes are composed as
  normal and tilemap layers are skipped (both warn); PSD imports the flattened image only; FBX skins and animations wait
  for M18.
- Providers: Meshy makes untextured preview meshes only; ElevenLabs music is instrumental; seeds are honoured by `fake`
  and `asset-command` only, reference images by OpenAI and `fake` only (the others warn).
- Audio: normalization has no limiter (the gain is capped so the peak stays under -1 dBFS); Android and iOS never
  measure loudness at run time, so sounds need the `analysis` records `assets.analyze_audio` or the export writes.
- Textures: ASTC and ETC2 are sampled in the Linux CI (llvmpipe) and were checked by software decoding, not on a phone
  GPU; ETC2 keeps less colour detail than ASTC and BC7 (one brightness offset for red, green and blue); KTX2 files use
  no Zstd supercompression (none vendored); textures whose sides are not multiples of 4 ship as PNG.

## M16. Mobile store-ready (M, high on mobile)

Closes F-17, the device half of F-08, the mobile half of E-09, E-12, E-13 and the mobile part of Q-06. Store SDKs on
mobile come with M11 and M12.

- `screen.safeArea` in JS (Android window insets, iOS `safeAreaInsets`), and anchors that can follow it.
- Android Back: an event the game can consume; today the system Back leaves the app.
- An on-screen keyboard for M10's text field, an optional on-screen gamepad, vibration.
- The iOS export writes `PrivacyInfo.xcprivacy` (the required-reason APIs the engine uses) and
  `ITSAppUsesNonExemptEncryption`; the docs list what to declare in Google Play's data safety form.
- `setup players --platforms mobile` on Windows and Linux installs the iOS libraries too (only the macOS package has
  them today, so an iOS project from Windows needs `--mobile-dir` pointed at a macOS package).
- Upload as commands with a dry run: App Store Connect and TestFlight (App Store Connect API), and the Google Play
  Developer API (or fastlane).
- An Android `--release` export without a keystore is an error unless `--allow-debug-key` is passed: today it is only a
  warning, and the AAB it produces is one Google Play rejects.

Acceptance criteria:
- The emulator smoke test sends Back and the game receives the event; a notched device profile reports non-zero insets.
- A test reads `PrivacyInfo.xcprivacy` from the generated Xcode project.
- `export --platform android --release` without a keystore fails with a teaching error.

## M17. Web export (L, high)

Closes E-07 and the web gamepad gap (docs/MOBILE.md). CMake already recognizes Emscripten; sokol and QuickJS build for it.

- An Emscripten preset and player (WebGL2), `export --platform web` writing `index.html`, the wasm and a data pack;
  audio unlocked on the first input; `storage` in IndexedDB; gamepads through the browser Gamepad API.
- A loading page with progress for the wasm and data download.

Acceptance criteria:
- CI builds the web player and runs an exported template in headless Chromium until its first frame renders.
- The export is a zip that itch.io accepts as an HTML5 game.

## M18. Animation and production 3D (L, high for 3D games)

Closes F-03, F-04, F-05, F-06 and the run-time part of H-06.

- glTF skins and animation clips (the loader flattens nodes and reads neither `skins` nor `animations`): GPU skinning,
  an animator with clips, blending and events; a tween/easing JS module; a small state machine.
- Rendering (Blinn-Phong, `kMaxLights = 8`, no culling today): normal maps, glTF metallic-roughness PBR with image-based
  lighting, frustum culling, instancing, more lights, custom shaders per material.
- Physics (`Collider3D` is box or sphere, no joints): capsule, convex and triangle-mesh colliders; Box2D's joints exposed
  in 2D (revolute, distance, prismatic, weld) and hinge/ball joints in 3D; a character controller.
- 2D: flipped and rotated tile indices, 9-slice (shared with M10), 2D lights with normal maps, parallax layers.

Acceptance criteria:
- A skinned glTF sample plays two clips and blends between them (golden image).
- 10 000 instanced cubes draw in one draw call per material; off-screen meshes are not submitted (render stats).
- A capsule body walks up a triangle-mesh ramp; a revolute-joint pendulum keeps its period.

## M19. Runtime features (M each, medium; take them when a game needs them)

Closes F-07 (effects), F-09, F-10 (except the Android shutdown, M9), F-11, F-14, F-16, F-18, H-07 and U-08.

- Networking: `http.fetch` (a Promise) and WebSocket in JS on every platform; real-time multiplayer later.
- Saves: slots with their menu (on M10), a version field with a migration hook, optional encryption, cloud through
  M12's `platform`.
- Pathfinding: grid A* on a Tilemap, a navmesh for 3D, a behaviour-tree helper module.
- Video: a video player component for logos and cut-scenes (e.g. pl_mpeg, MIT).
- `scene.loadAsync` with progress, for loading screens and larger worlds.
- Split screen: a viewport rectangle on Camera (four gamepads already work).
- Audio: effects on the buses (low-pass, reverb), ducking and snapshots.

Acceptance criteria: each item ships with its doctest or JS test and its docs, like any command or component.

## M20. Editor and tooling (L, medium-high)

Closes H-01, H-02, H-03, H-05, H-09 and the editor part of H-06.

- Hand editing: entity tree, an inspector built from reflection (every field already has a doc string and a range), an
  asset browser and transform gizmos; every edit goes through the commands the AI uses, so undo comes with them.
- A script debugger: breakpoints and stepping in QuickJS behind a Debug Adapter Protocol server, for VS Code.
- A profiler: CPU time per system and per behaviour class, GPU timings and memory, in `play.report` and an editor panel.
- Later: tile painting and object placement in the viewport, an animation timeline, particle and material editors.

Acceptance criteria:
- The editor autotest edits a field in the inspector and the scene file changes.
- An integration test drives the DAP server over stdio and stops at a breakpoint in a template behaviour.
- The profiler report lists each behaviour class with its milliseconds per frame.

## M21. Docs and material for shipping (M, high)

Closes D-01..D-05, D-07 and the store-page notes of the report.

- Docs marked by version ("since 0.1.x"); `factoria docs` already serves the docs of its own binary.
- A publishing guide per store with a checklist (Steam, Epic, GOG, Microsoft Store, Google Play, App Store, itch.io):
  what the engine does and what the developer still does by hand.
- A "finish your game" guide (menus, options, saves, localization, accessibility, credits) with M10-M14.
- A complete reference game built on M10-M14 and the fake platform backend, with its own ENGINE_FEEDBACK.json, so the
  feedback loop sees what jam-sized examples never reach.
- Tutorials for people and a browsable API reference generated from `factoria api --md`.
- An AI cost guide (tokens and money for a typical game, from `--max-cost` and the editor's usage records).
- Store page material: screenshots and capsule art at each store's sizes, gameplay video recorded from a replay,
  store metadata as text files per language.

Acceptance criteria: every guide is embedded in the binary and listed by `factoria docs`; a replay can be written to a
video file.

## M22. Production quality and legal (M, high)

Closes Q-04, Q-05, the rest of Q-06 and U-05 (except text scaling, in M14).

- Frame time and memory of every example on every CI runner, recorded and failing on regressions.
- Game updates: a content version in `factoria.json` and save migration (with M19's save versions).
- Templates and guidance: EULA, privacy policy, a GDPR/COPPA consent screen (on M10), age ratings (IARC, PEGI, ESRB).
- Accessibility: a subtitles component, colour-blind filters (post-processing), screen-reader hooks where the platform
  has them.

Acceptance criteria: a CI job fails when an example's frame time or memory regresses past its budget; the consent screen
and subtitles are in the M10 menu recipe and its fixture, with tests.

## M23. Closed stores and consoles (L each, later)

Closes E-08 and S-09, plus the Mac App Store and Microsoft Store rows of the report. Needs M11 and M12.

- Mac App Store: App Sandbox entitlements, Apple Distribution signing and a provisioning profile, a `.pkg` from
  `productbuild`, upload through the App Store Connect API (today only the Developer ID flow outside the store exists).
- Microsoft Store and PC Game Pass: MSIX packaging of the game (the engine's own installer is not one), Partner Center
  upload, the Microsoft GDK for Xbox services.
- Consoles (Switch, PlayStation, Xbox): their SDKs are under NDA and cannot live in this MIT repository. What this
  repository can do is the seam: a platform layer and render-backend interface (D3D12/GDKX, NVN, AGC) that a private M11
  plugin implements, and certification checklists (TRC, Lotcheck, XR) once a licensed developer contributes them.

Acceptance criteria: a sandboxed macOS export passes `codesign --verify --strict` with the App Sandbox entitlement and
runs; an MSIX of an exported game installs with `Add-AppxPackage`.

## Out of scope: Roblox

Roblox is not an export target. Roblox games run Luau inside Roblox Studio with Roblox's own services (DataStore,
MarketplaceService); exporting to it would take a JavaScript-to-Luau transpiler and a converter from scenes to `.rbxlx`,
which is a different product. Not planned.
