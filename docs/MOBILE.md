# Mobile: Android and iOS

The shipping player (`player/`) is one code base for all platforms. On mobile,
`sokol_app` owns the process entry point and calls `sokol_main()` in
`player/main.cpp`, which prepares the file system and returns
`fa::to_sapp_desc(fa::make_app_desc(config))`.

| | Android | iOS |
|---|---|---|
| Entry | `NativeActivity` (`libfactoria_player.so`) | `main()` from sokol_app, UIKit + MTKView |
| Graphics | GLES 3.0 (`SOKOL_GLES3`) | Metal |
| Game files | APK assets, read through `AAssetManager` (`assets_index.txt` lists them) | `<App>.app/game/` |
| Save games | `internalDataPath` | `Documents/` |
| Min OS | Android 8.0 (API 26), arm64-v8a + x86_64 | iOS 16.3 |

STATUS: CI (`.github/workflows/ci.yml`) builds the mobile players and RUNS them with a demo game
(`templates/2d-platformer`, bundled by `ios-build` through `FA_GAME_PROJECT_DIR`, as a copy that calls the example native plugin, and by `android-apk` through `factoria export`):

- `ios` job: boots an iPhone on the newest iOS Simulator runtime of the `macos-latest` runner (iOS 26.5, iPhone 17 Pro,
  Xcode 26.6 when this was written; the app renders with the real Metal driver), installs the `.app` and launches it with its console captured.
- `android-emulator` job: boots an API 34 `x86_64` emulator (default image, KVM, software GPU: OpenGL ES 3.0 only),
  installs the debug APK that `android-apk` built (it carries `arm64-v8a` and `x86_64`) and starts it.

Both run one script (`scripts/ios-smoke.sh <app> <bundleId>` on a Mac, `scripts/android-smoke.sh <apk> <applicationId>`
on an adb device or emulator) that walks through the steps below on the same booted simulator/emulator. Every step has
its own failure message, and the logs, screenshots and crash reports are uploaded as artifacts (`ios-smoke`,
`android-smoke`) on every run.

| Step | Android emulator | iOS Simulator |
|---|---|---|
| Ready | no fixed sleep: `sys.boot_completed`, boot animation stopped, package manager answers, device provisioned, keyguard dismissed, launcher has the window focus; after the install, the broadcast queues are idle (`am wait-for-broadcast-idle`) | `simctl bootstatus -b` |
| Run | process alive, `player: 60 frames rendered`, same process 5 s later | same |
| Audio | `audio: output device open` and `audio: stream running` (the platform pulled samples); the warning `no audio output device available` fails | same (the failure prints the host's audio devices) |
| Touch | `input touchscreen tap` in the middle of the screen reaches the player (`input: first touch`) | `simctl` cannot inject touches, so a UI test (`platforms/ios/touch-test`, XCUITest, built with CMake + `xcodebuild`) taps the middle of the running app's screen: `input: first touch` at the middle of the design (checked for the `fit` and `stretch` scale modes), same process |
| Suspend / resume | HOME key, then `am start`: `player: suspended`, the process survives, `player: resumed`, `player: 60 frames rendered after resume`, the game has the window focus, a new native window was created (debug sokol_app), the screen shows a picture | launch Settings on top, then launch the app again: same checks, same process |
| Configuration change | the font scale is changed twice: the process and activity survive | not applicable |
| No crash | no Java exception, native signal or ANR, no `E factoria` line, the activity was never destroyed or relaunched, the screenshot shows a picture | no `ERROR` line, no crash report, the screenshot shows a picture |
| Relaunch | `am update-appinfo` (the update an overlay or a wallpaper-colour change sends) relaunches the activity: the old process runs the game's end (`player: ended`, the probe's `game.on("quit")` line once, `FA_SMOKE_QUIT`) and ends with no native signal and no GL call without a context, the system starts the game again in a new process, which renders 60 frames, has the window focus and shows a picture, and logs no `E factoria` line; it logs `probe quits stored=1`, the count the old process wrote with `storage.setAsync` in its `quit` handler | not applicable |
| Back and quit | `input keyevent KEYCODE_BACK`: the game's `input.onBack` handler consumes the first press and stays (`FA_SMOKE_BACK`); it lets the second through, which ends the game: the process ends within 20 s and is not started again, after `player: ended` and the `quit` line once, with no crash or `E factoria` line (`FA_SMOKE_QUIT`). A force-stop delivers no callback and is not tested | not applicable |
| Native plugin | the game has a native plugin with a Java class ([below](mobile/MOBILE_ANDROID.md#native-plugins-on-android)): its script logged `probe add=3` (the sum came from the Java class through JNI) and `probe info=` with `"plugin":"example"` (`FA_SMOKE_EXPECT`) | the app links the plugin's static library ([below](mobile/MOBILE_IOS.md#native-plugins-ios)): the same two lines in the console (`FA_IOS_PLUGIN_PROBE=1`) |
| Apple plugin | not applicable | the game links the Apple backend plugin (Swift, StoreKit, GameKit; [below](mobile/MOBILE_IOS.md#native-plugins-ios)): the console shows `Apple backend ready`, `probe backend=apple` and `probe unlock=notSignedIn` (a Game Center call answered by the Swift code; `FA_IOS_APPLE_PROBE=1`, script `tools/cli/tests/apple_probe.js`) |
| Google Play plugin | the game has the Google Play backend plugin (a C bridge plus a Java module with Billing, Play Games and Play Integrity; [PLATFORM.md](platform/PLATFORM_APPLE_GOOGLE.md#7-google-play-billing-play-games-services-and-play-integrity)): the log shows `Google Play backend ready`, `probe backend=googleplay` and `probe signin=unavailable` (the emulator has no Google Play services, so the Java code answers the sign-in with a teaching refusal; script `tools/cli/tests/googleplay_probe.js`, `FA_SMOKE_EXPECT`) | not applicable |
| AdMob plugin | the game has the AdMob ads backend next to the Google Play one ([PLATFORM.md](platform/PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios)): the log shows `AdMob backend ready`, `probe adsbackend=admob store=googleplay`, the manifest's test app id (`probe admob test=true ... appId=ca-app-pub-3940256099942544~3347511713`) and `probe underage=ok` (a call went through the C bridge to the Java code and back; script `tools/cli/tests/admob_probe.js`, `FA_SMOKE_EXPECT`). It loads no ad: that needs Google's network | none in CI: Google's iOS SDK is a download that the repository never holds. The tooling tests export with a stub XCFramework; the simulator steps are by hand ([PLATFORM.md](platform/PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios)) |

The lines the scripts wait for are part of the player: `player: 60 frames rendered` (`engine/runtime/src/runners.cpp`),
`player: suspended`, `player: resumed`, `player: 60 frames rendered after resume`, `player: ended` (same file), `audio: output device open`
and `audio: stream running` (`engine/audio/src/audio.cpp`), `input: first touch` (`engine/platform/src/app.cpp`).
Each is logged once per start or per suspend/resume at info level; do not reword them without changing the scripts. In
logcat they look like `I factoria: player: 60 frames rendered`.

Android waits for readiness instead of sleeping because an activity started right after boot used to be destroyed about a
second later. The likely cause: Android restarts an activity for every configuration change the manifest does not list,
a restarted `NativeActivity` ends the whole process (sokol_app calls `exit(0)` in `onDestroy`), and the emulator's
virtual SIM loads some seconds after `sys.boot_completed`, which changes `mcc`/`mnc`. The manifest now lists every change
the player can ignore (`mcc`, `mnc`, `locale`, `layoutDirection`, `fontScale`, `fontWeightAdjustment`, `colorMode` next
to the ones that were there), which also keeps a real phone from killing the game when the user changes the language or
the font size; the font-scale step keeps that fixed. One restart cannot be listed: a change of the app's assets paths
(`CONFIG_ASSETS_PATHS`, logged as `wm_relaunch_resume_activity ... 80000000`). A run started right after the install was
relaunched that way while ActivityManager was still delivering `BOOT_COMPLETED` and the install's broadcasts, so the
script now waits until every broadcast queue is idle before it starts the game; the relaunch step covers the same
relaunch on purpose (see "Lifecycle" under Android). If a run still loses the process, `android-smoke.sh` prints the
activity lifecycle events (`wm_*_activity`), `configuration_changed` events, the window focus and the SIM state.

Not covered by CI, so a green run is not a device certification:

- **Real devices and real GPUs** (Adreno, Mali, PowerVR, Apple GPUs on hardware): a device farm (Firebase Test Lab, AWS
  Device Farm, BrowserStack) needs an account and costs money; the repository has none, so there is no such job.
- **arm64 Android code** runs on no GitHub-hosted runner as an emulator. The `android` job compiles it and checks its
  entry points, and the APK carries the `arm64-v8a` library, but nothing executes it. Why: the emulator accelerates only
  guests of the host's architecture ([Android docs](https://developer.android.com/studio/run/emulator-acceleration):
  ARM images on Intel/AMD hosts "can't use the VM acceleration", and the Linux requirements list only Intel and AMD CPUs;
  [android-emulator-runner](https://github.com/ReactiveCircus/android-emulator-runner): "the old ARM-based emulators were
  slow and are no longer supported by Google"). An arm64 host would be needed, and neither arm64 hosted runner offers
  nested virtualization: `ubuntu-24.04-arm` has no `/dev/kvm` ([actions/runner-images#14062](https://github.com/actions/runner-images/issues/14062),
  closed as not planned in August 2026) and the macOS runners say "Nested-virtualization is not supported due to the
  limitation of Apple's Virtualization Framework" ([GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)).
  Not tried: the ARM translation of Google APIs `x86_64` images (`adb install --abi arm64-v8a`), which would run the
  arm64 library through a translator, not on an ARM CPU.
- **Audio you can hear** (only that the stream is pulled), orientation changes, low memory,
  phone calls and other interruptions, process death and state restore, gamepads, release (optimised) builds (CI runs
  the debug APK and the Debug simulator build), other API levels than 34, iPad and older iOS versions.

A failing run is therefore a real bug; a green one says the player starts, draws, plays an audio stream, takes a tap at
the right place, survives going to the background and back and does not crash on the emulator or simulator.

Checked by hand on Apple hardware (October 2026, MacBook Air M5, Xcode 27.1): on an iPhone 16 (A18, iOS 27) the
examples Block Push (taps), Neon Swarm (music, sound effects, aiming at the finger) and Gem Roller (3D) run, render,
play audible sound, survive Home and back and a turn to the other landscape side; the same on the iOS 27 Simulator.
Those runs found that every touch landed 3x too far (the engine scaled sokol_app's positions, which are already in
framebuffer pixels, by the display scale again; the same put mouse clicks 2x off on a Retina Mac and on a Windows
display scaled to 200%), which the touch step above now catches.

The console of the app: from the iOS 27 runtime (Xcode 27) on, `simctl launch --stdout=<file> --stderr=<file>` opens
the paths inside the simulator's own file system (`/tmp/x` lands in `<device>/data/tmp/x`, a path under the home
folder fails the launch), so the files on the Mac stay empty. `ios-smoke.sh` and `build_ios.sh --run` use
`simctl launch --console-pty` instead, which works on every Xcode.

Found by the first device runs (all fixed): the emulator has no OpenGL ES 3.1, so the player asks for a 3.0 context
(`to_sapp_desc`), and sokol_gfx is told that version even when the driver reports a newer one (the arm64 emulator with
`-gpu swiftshader_indirect` reports 3.1 for a 3.0 context and rejects 3.1 queries, which aborted a Debug build in
`sg_setup`; see `engine/platform/src/sokol_impl.c`). The engine uses no ES 3.1 feature. And the emulator's software GLES treats every texture larger than 1x1 as incomplete unless the texture states
its last mip level, so the renderer creates all images through `make_image` (`engine/render/src/image_gl.cpp`), which
sets `GL_TEXTURE_MAX_LEVEL`. Without it the emulator showed a black window while the log looked healthy; that is why
the smoke tests also check the screenshot.

## Pages of this doc

- [Android](mobile/MOBILE_ANDROID.md): Android: SDK, build, plugins, signing and release.
- [iOS](mobile/MOBILE_IOS.md): iOS: build, plugins, signing and TestFlight.
- [Store privacy forms](mobile/MOBILE_PRIVACY.md): The store privacy forms (Google Play Data safety, App Store privacy).
- [Touch, phone features and web](mobile/MOBILE_DEVICE.md): Touch input, phone features and the web build on a phone.

## Prebuilt or source

`factoria export --platform android|ios` runs in one of two modes (`mode` in the export report). The FactorIA download
carries the engine's mobile runtime ready-made in `FactorIA/mobile/` (Android `.so` in every package, iOS static
libraries in the macOS package), so exporting from the download is **prebuilt**: nothing of the engine is compiled on
your machine. A `factoria` built from the repository, or one pointed at a checkout (`--engine-root`,
`$FACTORIA_ENGINE_DIR`), exports from **source**. The rule and the folder layout are in [EXPORTING.md](exporting/EXPORTING_MOBILE.md#mobile-exports-prebuilt-or-source).

The libraries are built by `.github/workflows/release.yml` (jobs `mobile-android`, `mobile-ios`) with the same CMake
presets as CI, and its smoke tests build an APK and an iOS Simulator app from the unpacked package alone, with no engine
checkout on the machine.
