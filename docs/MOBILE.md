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
(`templates/2d-platformer`, bundled by `ios-build` through `FA_GAME_PROJECT_DIR` and by `android-apk` through `factoria export`):

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
| Ready | no fixed sleep: `sys.boot_completed`, boot animation stopped, package manager answers, device provisioned, keyguard dismissed, launcher has the window focus | `simctl bootstatus -b` |
| Run | process alive, `player: 60 frames rendered`, same process 5 s later | same |
| Audio | `audio: output device open` and `audio: stream running` (the platform pulled samples); the warning `no audio output device available` fails | same (the failure prints the host's audio devices) |
| Touch | `input touchscreen tap` in the middle of the screen reaches the player (`input: first touch`) | not covered: `simctl` cannot inject touches |
| Suspend / resume | HOME key, then `am start`: `player: suspended`, the process survives, `player: resumed`, `player: 60 frames rendered after resume`, the game has the window focus, a new native window was created (debug sokol_app), the screen shows a picture | launch Settings on top, then launch the app again: same checks, same process |
| Configuration change | the font scale is changed twice: the process and activity survive | not applicable |
| No crash | no Java exception, native signal or ANR, no `E factoria` line, the activity was never destroyed or relaunched, the screenshot shows a picture | no `ERROR` line, no crash report, the screenshot shows a picture |

The lines the scripts wait for are part of the player: `player: 60 frames rendered` (`engine/runtime/src/runners.cpp`),
`player: suspended`, `player: resumed`, `player: 60 frames rendered after resume` (same file), `audio: output device open`
and `audio: stream running` (`engine/audio/src/audio.cpp`), `input: first touch` (`engine/platform/src/app.cpp`).
Each is logged once per start or per suspend/resume at info level; do not reword them without changing the scripts. In
logcat they look like `I factoria: player: 60 frames rendered`.

Android waits for readiness instead of sleeping because an activity started right after boot used to be destroyed about a
second later. The likely cause: Android restarts an activity for every configuration change the manifest does not list,
a restarted `NativeActivity` ends the whole process (sokol_app calls `exit(0)` in `onDestroy`), and the emulator's
virtual SIM loads some seconds after `sys.boot_completed`, which changes `mcc`/`mnc`. The manifest now lists every change
the player can ignore (`mcc`, `mnc`, `locale`, `layoutDirection`, `fontScale`, `fontWeightAdjustment`, `colorMode` next
to the ones that were there), which also keeps a real phone from killing the game when the user changes the language or
the font size; the font-scale step keeps that fixed. If a run still loses the process, `android-smoke.sh` prints the
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
- **iOS touch** (see the table), **audio you can hear** (only that the stream is pulled), the Android Back button,
  orientation changes, low memory, phone calls and other interruptions, process death and state restore, gamepads,
  release (optimised) builds (CI runs the debug APK and the Debug simulator build), other API levels than 34, iPad and
  older iOS versions.

A failing run is therefore a real bug; a green one says the player starts, draws, plays an audio stream, takes a tap
(Android), survives going to the background and back and does not crash on the emulator or simulator.

Found by the first device runs (all fixed): the emulator has no OpenGL ES 3.1, so the player asks for a 3.0 context
(`to_sapp_desc`); and its software GLES treats every texture larger than 1x1 as incomplete unless the texture states
its last mip level, so the renderer creates all images through `make_image` (`engine/render/src/image_gl.cpp`), which
sets `GL_TEXTURE_MAX_LEVEL`. Without it the emulator showed a black window while the log looked healthy; that is why
the smoke tests also check the screenshot.

## Android

Prerequisites:

- JDK 17
- Android SDK with: `platforms;android-34`, `build-tools;34.0.0`, an NDK r27+ (r26's libc++ has no std::format)
  (`ndk;27.2.12479018`) and CMake 3.31 (`cmake;3.31.6`; the engine needs 3.24+, the SDK default is older).
  Install with `sdkmanager "platforms;android-34" "build-tools;34.0.0" "ndk;27.2.12479018" "cmake;3.31.6"`.
- `ANDROID_SDK_ROOT` set (or `sdk.dir=` in `local.properties`)
- Gradle 8.7+ once, to create the wrapper (`gradle wrapper --gradle-version 8.7`); Android Studio can open the folder directly.

Steps: `factoria export --platform android`, then in the output folder
`./gradlew assembleDebug` and `adb install -r app/build/outputs/apk/debug/app-debug.apk`.
The first build compiles the whole engine for two ABIs (several minutes). To
build for one ABI only, edit `abiFilters` in `app/build.gradle`.

Without Gradle (just the native library, as CI does): `export ANDROID_NDK_HOME=...; ./scripts/build-android.sh`
produces `build/android-arm64/player/libfactoria_player.so`.

Logs: `adb logcat -s factoria` (tag `factoria`: the engine log and the sokol messages; a native crash is under `libc` and `DEBUG`).

### Signing and release

Debug APKs are signed with the debug key automatically. For release:

1. Create a keystore once: `keytool -genkey -v -keystore release.jks -alias game -keyalg RSA -keysize 2048 -validity 10000`.
2. Add to `app/build.gradle`:
   ```groovy
   signingConfigs { release {
       storeFile file(System.getenv('FA_KEYSTORE') ?: 'release.jks')
       storePassword System.getenv('FA_KEYSTORE_PASSWORD')
       keyAlias 'game'
       keyPassword System.getenv('FA_KEY_PASSWORD') } }
   buildTypes { release { signingConfig signingConfigs.release } }
   ```
3. `./gradlew assembleRelease` (APK) or `./gradlew bundleRelease` (AAB for Google Play).

Never commit the keystore or passwords.

### Orientation

`display.orientation` in `factoria.json`: `landscape` -> `sensorLandscape`,
`portrait` -> `sensorPortrait`, `any` -> `fullSensor` in `AndroidManifest.xml`.
The app is full screen; the game renders at its design resolution with the
project's `scaleMode`.

## iOS

Prerequisites: macOS, the full Xcode app (not only command line tools; run
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`), CMake 3.24+,
an Apple developer team for devices (a free Apple ID works for your own device).

Steps: `factoria export --platform ios`, then on the Mac `./build_ios.sh --simulator`
(or without flag for a device). Xcode opens `build/FactorIA.xcodeproj`; choose the
`factoria_player` scheme, set Team under Signing & Capabilities and press Run.
Command line build: `FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --build`.

Direct use of the engine checkout (no export):

```bash
cmake --preset ios-simulator -DFA_GAME_PROJECT_DIR=/path/to/game -DFA_GAME_BUNDLE_ID=com.example.mygame \
      -DFA_GAME_NAME="My Game" -DFA_GAME_VERSION=1.0.0 -DFA_GAME_ORIENTATION=portrait
cmake --build --preset ios-simulator --target factoria_player -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO
```

CMake variables: `FA_GAME_PROJECT_DIR`, `FA_GAME_BUNDLE_ID`, `FA_GAME_NAME`,
`FA_GAME_VERSION`, `FA_GAME_ORIENTATION`, `FA_IOS_DEVELOPMENT_TEAM`. They feed
`platforms/ios/Info.plist.in` (full screen, MetalKit, orientation lists for
iPhone and iPad, launch screen via `UILaunchScreen`). The game folder is copied
into the bundle after linking with the same exclude rules as `factoria export`
(`platforms/common/copy_game.cmake`). Without `FA_GAME_PROJECT_DIR` the app
starts with a red screen and logs why.

App Store: archive from Xcode (Product > Archive) with a distribution
certificate and provisioning profile; set the real app icon and launch screen
in Xcode (the template ships none).

## Touch input

The platform layer maps touches to the same `Input` object scripts use:

- every finger is a touch (`Input::touches()`; begin/move/end) in design coordinates;
- the first finger also drives the mouse: position plus `MouseLeft` down/up, so
  UI and scripts written for the mouse work unchanged (this is done by `Input` itself, so `game.touch` in tests and
  any other feed behave the same);
- input actions bound to `"Touch"` or `"MouseLeft"` in `factoria.json` fire on touch;
- there is no on-screen keyboard or on-screen gamepad yet: bind touch to actions
  and build on-screen buttons as entities that read touches.
- Physical gamepads: iOS reads them through the GameController framework (extended gamepads: MFi, Xbox, PlayStation;
  written, not yet built or run). The web build has no gamepad support yet. Bindings such as `"GamepadA"` are
  accepted everywhere.
- Android gamepads (Bluetooth or USB pads that Android itself supports: Xbox, DualShock/DualSense, Switch Pro, most
  generic ones) come from the NativeActivity input queue: the button keys (`AKEYCODE_BUTTON_A`..`MODE`, the D-pad
  keys), and the joystick axes (left stick X/Y, right stick Z/RZ or RX/RY, triggers `LTRIGGER`/`RTRIGGER` or
  `BRAKE`/`GAS`, D-pad `HAT_X`/`HAT_Y`). Android's own key layouts already give pads the Xbox naming, so there is no
  mapping table; the face buttons are positional like everywhere (`GamepadA` is the bottom one). The engine takes
  these events through sokol_app's `sapp_desc.android.native_event_cb` hook (installed by `to_sapp_desc()`) and
  marks them handled, so pad buttons never act as Back or touches. System Back (the Back key or gesture) is not
  taken: it still leaves the app. Pads fill slots 0..3 in the order they first send an event. Limits: the NDK
  reports no device removal, so an unplugged pad keeps its slot until a fifth pad needs one (Android itself releases
  its keys and recentres its axes, so nothing sticks); a pad with a non-standard axis layout (triggers on Z/RZ and the
  right stick on RX/RY) is not told apart. This code has been compiled but never run on a device.
- Losing focus or backgrounding releases all inputs and fires `Suspended`/`Resumed`; pads that are still connected
  report their real state again afterwards.
