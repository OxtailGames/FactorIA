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
| Min OS | Android 8.0 (API 26), arm64-v8a + x86_64 | iOS 15 |

STATUS: the mobile code could not be compiled on the Linux development machine.
CI (`.github/workflows/ci.yml`, jobs `ios`, `android`, `android-apk`) is the
source of truth; expect small fixes on the first real device run.

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

Logs: `adb logcat -s FactorIA sokol`.

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
- there is no on-screen keyboard or gamepad mapping yet: bind touch to actions
  and build on-screen buttons as entities that read touches.
- Losing focus or backgrounding releases all inputs and fires `Suspended`/`Resumed`.
