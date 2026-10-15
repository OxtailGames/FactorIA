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

STATUS: CI (`.github/workflows/ci.yml`) builds the mobile players and RUNS them with a demo game:

- `ios` job: boots an iPhone on the newest iOS Simulator runtime of the `macos-latest` runner (iOS 26.5, iPhone 17 Pro,
  Xcode 26.6 when this was written; the app renders with the real Metal driver), installs the `.app` and launches it with its console captured.
- `android-emulator` job: boots an API 34 `x86_64` emulator (default image, KVM, software GPU: OpenGL ES 3.0 only),
  installs the debug APK that `android-apk` built (it carries `arm64-v8a` and `x86_64`) and starts it.

Both assert that the process stays alive, the player logged its run marker `player: 60 frames rendered`
(`engine/runtime/src/runners.cpp`; logcat shows `I factoria: player: 60 frames rendered`), the engine logged no error,
nothing crashed and a screenshot shows a picture. Logs, the screenshot and crash reports are uploaded as artifacts
(`ios-smoke`, `android-smoke`) on every run. Locally: `scripts/ios-smoke.sh <app> <bundleId>` (Mac) and
`scripts/android-smoke.sh <apk> <applicationId>` (adb device or emulator).

Not covered by CI: real devices and GPUs, running arm64 Android code (the emulator is `x86_64`), touch, audio and
suspend/resume. A failing run is therefore a real bug; a green one is not a device certification.

Found by the first device runs (all fixed): the emulator has no OpenGL ES 3.1, so the player asks for a 3.0 context
(`to_sapp_desc`); and its software GLES treats every texture larger than 1x1 as incomplete unless the texture states
its last mip level, so the renderer creates all images through `make_image` (`engine/render/src/image_gl.cpp`), which
sets `GL_TEXTURE_MAX_LEVEL`. Without it the emulator showed a black window while the log looked healthy; that is why
the smoke tests also check the screenshot.

## Prebuilt or source

`factoria export --platform android|ios` runs in one of two modes (`mode` in the export report). The FactorIA download
carries the engine's mobile runtime ready-made in `FactorIA/mobile/` (Android `.so` in every package, iOS static
libraries in the macOS package), so exporting from the download is **prebuilt**: nothing of the engine is compiled on
your machine. A `factoria` built from the repository, or one pointed at a checkout (`--engine-root`,
`$FACTORIA_ENGINE_DIR`), exports from **source**. The rule and the folder layout are in [EXPORTING.md](EXPORTING.md#mobile-exports-prebuilt-or-source).

The libraries are built by `.github/workflows/release.yml` (jobs `mobile-android`, `mobile-ios`) with the same CMake
presets as CI, and its smoke tests build an APK and an iOS Simulator app from the unpacked package alone, with no engine
checkout on the machine.

## Android

Prerequisites:

- JDK 17
- Android SDK with `platforms;android-34` and `build-tools;34.0.0`
  (`sdkmanager "platforms;android-34" "build-tools;34.0.0"`). That is all in **prebuilt** mode: no NDK, no CMake.
- Only in **source** mode (engine developers): an NDK r27+ (r26's libc++ has no std::format, `ndk;27.2.12479018`) and
  CMake 3.31 (`cmake;3.31.6`; the engine needs 3.24+, the SDK default is older), so
  `sdkmanager "platforms;android-34" "build-tools;34.0.0" "ndk;27.2.12479018" "cmake;3.31.6"`.
- `ANDROID_SDK_ROOT` set (or `sdk.dir=` in `local.properties`)
- Gradle 8.7+ once, to create the wrapper (`gradle wrapper --gradle-version 8.7`); Android Studio can open the folder directly.

Steps: `factoria export --platform android`, then in the output folder
`./gradlew assembleDebug` and `adb install -r app/build/outputs/apk/debug/app-debug.apk`.
Prebuilt: Gradle only packages `app/src/main/jniLibs/<abi>/libfactoria_player.so` and the game, about a minute. Source:
the first build compiles the whole engine for two ABIs (several minutes). To build for one ABI only, edit `abiFilters`
in `app/build.gradle`. Gradle may print a warning that it could not strip debug symbols from the `.so` files without an
NDK; the libraries of the download are already stripped, so it is harmless.

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
Command line build: `FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --build`
(simulator without signing: `./build_ios.sh --simulator --build -- CODE_SIGNING_ALLOWED=NO`; everything after `--` goes
to `xcodebuild`).

**Prebuilt** (the macOS download): the export holds a small `CMakeLists.txt`, `cmake/` and `lib/<iphoneos|iphonesimulator>/*.a`
next to `game/`, and `build_ios.sh` configures that folder. No engine source is needed, only Xcode and CMake. The libraries
are the player and the whole engine as static archives (`libfactoria_player_main.a` is the player: `main` comes from
`sokol_app` inside `libfa_platform.a`); the exported project links the archives of the SDK it is configured for, with the
same frameworks as the engine presets. There is no XCFramework because the exported project is configured per SDK (device
or simulator), like the `ios` presets, and CMake's Xcode generator (3.24) cannot link one. The simulator archives hold
`arm64` and `x86_64`. The iOS libraries are not in the Windows and Linux packages (iOS cannot be built there), so export
for iOS on a Mac. **Source**: the export holds only `game/` and `build_ios.sh`, which runs CMake on the engine checkout.

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
