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
| Ready | no fixed sleep: `sys.boot_completed`, boot animation stopped, package manager answers, device provisioned, keyguard dismissed, launcher has the window focus; after the install, the broadcast queues are idle (`am wait-for-broadcast-idle`) | `simctl bootstatus -b` |
| Run | process alive, `player: 60 frames rendered`, same process 5 s later | same |
| Audio | `audio: output device open` and `audio: stream running` (the platform pulled samples); the warning `no audio output device available` fails | same (the failure prints the host's audio devices) |
| Touch | `input touchscreen tap` in the middle of the screen reaches the player (`input: first touch`) | `simctl` cannot inject touches, so a UI test (`platforms/ios/touch-test`, XCUITest, built with CMake + `xcodebuild`) taps the middle of the running app's screen: `input: first touch` at the middle of the design (checked for the `fit` and `stretch` scale modes), same process |
| Suspend / resume | HOME key, then `am start`: `player: suspended`, the process survives, `player: resumed`, `player: 60 frames rendered after resume`, the game has the window focus, a new native window was created (debug sokol_app), the screen shows a picture | launch Settings on top, then launch the app again: same checks, same process |
| Configuration change | the font scale is changed twice: the process and activity survive | not applicable |
| No crash | no Java exception, native signal or ANR, no `E factoria` line, the activity was never destroyed or relaunched, the screenshot shows a picture | no `ERROR` line, no crash report, the screenshot shows a picture |
| Relaunch | `am update-appinfo` (the update an overlay or a wallpaper-colour change sends) relaunches the activity: the old process ends with no native signal and no GL call without a context, the system starts the game again in a new process, which renders 60 frames, has the window focus and shows a picture, and logs no `E factoria` line | not applicable |

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
- **Audio you can hear** (only that the stream is pulled), the Android Back button, orientation changes, low memory,
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

`factoria export --platform android` writes the Gradle project **and builds the app with it** (`--format aab` builds the
Google Play bundle, `--format gradle` only writes the project). Details of the export: [EXPORTING.md](EXPORTING.md#android).

The quickest way to get the prerequisites: `factoria setup android` downloads a JDK 21 and the Android SDK (platform 36,
build-tools 35.0.0, platform-tools; you read and accept the SDK license first) into `~/.factoria` and tells `factoria export`
where they are, and `factoria setup players` downloads the prebuilt `mobile/` libraries for an exe that has none next to it
([EXPORTING.md](EXPORTING.md#setting-up-this-computer)). The editor has the same as buttons. By hand:

Prerequisites (the export checks them first and says what is missing and how to set it up):

- A JDK 17 or newer (Android builds are tested with 17 and 21). The export finds `JAVA_HOME`, Android Studio's bundled JDK
  and Unity Hub's; or set `android.jdk` in `~/.factoria/export.json`.
- The Android SDK (Android Studio installs it; or the command-line tools): `ANDROID_HOME`, the usual folder of your OS, or
  `android.sdk` in `~/.factoria/export.json`. Accept its licenses once: `sdkmanager --licenses`. Gradle then downloads the
  platform (`platforms;android-36`, the default `targetSdk`) and build tools it needs by itself. That is all in **prebuilt**
  mode: no NDK, no CMake.
- Only in **source** mode (engine developers): an NDK r27+ (r26's libc++ has no std::format, `ndk;27.2.12479018`) and
  CMake 3.31 (`cmake;3.31.6`; the engine needs 3.24+, the SDK default is older), so
  `sdkmanager "platforms;android-36" "build-tools;35.0.0" "ndk;27.2.12479018" "cmake;3.31.6"`.
- No Gradle install: the export writes the project's own Gradle wrapper, and the first build downloads Gradle, the Android
  Gradle plugin and the SDK platform (internet needed once; everything is cached after it).

Steps: `factoria export --platform android`; the app is `<out>/<game>-android/<game>-debug.apk`, then
`adb install -r <game>-debug.apk` and `adb logcat -s factoria`. The report's `nextSteps` print the exact commands.
Prebuilt: Gradle only packages `app/src/main/jniLibs/<abi>/libfactoria_player.so` and the game, which takes seconds once
Gradle and the plugin are cached. Source: the first build compiles the whole engine for two ABIs (several minutes). To build
for one ABI only, edit `abiFilters` in `app/build.gradle` of the exported project. The libraries of the download are
already stripped, so Gradle prints no strip warning for them. The project also opens directly in Android Studio.

If the build fails the export folder stays (with `build.log`) and the error names the cause when it knows it:

| Gradle says | What to do |
|---|---|
| licenses not accepted | `sdkmanager --licenses` of the SDK the error names (or Android Studio > SDK Manager > SDK Tools), then export again |
| unsupported class file version / Java version | use a JDK 17 or 21: `android.jdk` in `~/.factoria/export.json` or `JAVA_HOME` |
| SDK location not found | `ANDROID_HOME`, or `android.sdk`; the folder needs `platform-tools` and `platforms` |
| could not resolve / download / timed out | the first build needs the internet (services.gradle.org, Google Maven, dl.google.com); check the proxy, then export again |

Without Gradle (just the native library, as CI does): `export ANDROID_NDK_HOME=...; ./scripts/build-android.sh`
produces `build/android-arm64/player/libfactoria_player.so`.

Logs: `adb logcat -s factoria` (tag `factoria`: the engine log and the sokol messages; a native crash is under `libc` and `DEBUG`).

### Signing and release

Debug builds are signed with the debug key of your machine automatically; that is fine for trying the app on a phone or an
emulator, and Google Play refuses it. For release:

1. Create a keystore once, outside the project folder and outside git:
   `keytool -genkeypair -v -keystore ~/keys/upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`.
2. In `factoria.json`: `"export": {"android": {"signing": {"keystore": "/Users/me/keys/upload.jks", "alias": "upload"}}}` (the
   Platform settings window of the editor writes the same keys). The keystore is not copied into the app: a keystore inside
   the project is left out of the export, with a warning.
3. Give the passwords to the export, never to a file of the project: the environment variables
   `FACTORIA_ANDROID_KEYSTORE_PASSWORD` and `FACTORIA_ANDROID_KEY_PASSWORD` (the second defaults to the first), or
   `android.keystorePassword` / `android.keyPassword` in `~/.factoria/export.json` (this computer only, owner-readable).
4. `factoria export --platform android --release` builds `<game>.apk` (signed; check it with
   `apksigner verify --print-certs`), and `--format aab --release` builds `<game>.aab`, the bundle **Google Play takes**
   (upload it in the Play Console; with Play App Signing the key above is your upload key).

The passwords reach Gradle only as environment variables of its process: they are not in `gradle.properties`, `build.gradle`,
`build.log` or any file of the export, nor on a command line. A release export without a keystore uses the debug key and
warns; a keystore that does not exist, or missing passwords, are reported by the plan (`project.export` with `dryRun`)
before Gradle starts. To build by hand inside the exported project, set the same variables and run `./gradlew assembleRelease`
(APK) or `./gradlew bundleRelease` (AAB).

### 16 KB memory pages

Android 15 devices may use 16 KB memory pages and Google Play requires apps that target Android 15+ to support them. The
player links with `-Wl,-z,max-page-size=16384` (the NDK r27 default is 4 KB), and Gradle aligns the native libraries inside
the APK to 16 KB; check an APK with `zipalign -c -P 16 -v 4 <apk>` (from the SDK's `build-tools`).

Never commit the keystore or passwords.

### Orientation

`display.orientation` in `factoria.json`: `landscape` -> `sensorLandscape`,
`portrait` -> `sensorPortrait`, `any` -> `fullSensor` in `AndroidManifest.xml`.
The app is full screen; the game renders at its design resolution with the
project's `scaleMode`.

### Lifecycle

- Going to the background and back keeps the process: the game gets `Suspended`/`Resumed` (`player: suspended`,
  `player: resumed` in the log) and the GL surface is rebuilt.
- Configuration changes the manifest lists (orientation, screen size, density, dark mode, locale, font size, the SIM's
  `mcc`/`mnc` and the others in `android:configChanges`) are handled in place: the game keeps running.
- A change of the app's assets paths cannot be listed: a new wallpaper colour palette or theme (Android 12+), a system
  overlay turned on or off (e.g. the display-cutout emulation of the developer options). Android then relaunches every
  activity. A destroyed NativeActivity ends the process (sokol_app exits so that the next start has fresh globals), and
  the activity is `stateNotNeeded`, so Android starts the game again in a new process: it restarts from its first
  scene, as after a cold start.
- Back and closing the game destroy the activity too; the process ends and the game is not started again.
- When the process ends this way it ends at once (`_exit`, see `engine/platform/src/sokol_impl.c`): the engine is not
  shut down and no script callback runs. Save progress while the game runs: `storage` writes go to `storage.json` in the
  app's internal folder immediately.

## iOS

Prerequisites: macOS, the full Xcode app (not only command line tools; run
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`), CMake 3.24+,
an Apple developer team for devices (a free Apple ID works for your own device). `factoria setup` checks them,
`factoria setup cmake` installs CMake and `factoria setup xcode` opens Xcode's App Store page and lists the steps that need
your password ([EXPORTING.md](EXPORTING.md#setting-up-this-computer)).

Steps: `factoria export --platform ios`, then on the Mac, in the exported folder:

```bash
./build_ios.sh --simulator --run                          # build, start in the iOS Simulator, console in the terminal
FA_IOS_DEVELOPMENT_TEAM=<TEAMID> ./build_ios.sh --run     # the same on the connected iPhone or iPad (see teamId below)
./build_ios.sh [--simulator] --build [-- <xcodebuild arguments>]   # only build (the .app path is printed)
./build_ios.sh [--simulator]                              # create build/FactorIA.xcodeproj and open it in Xcode
```

`--run` installs the app and starts it with its console (stdout and stderr, so the engine log) in the terminal; Ctrl+C
ends the game. Simulator builds need no team: they are built unsigned and signed ad hoc. In Xcode instead: choose the
`factoria_player` scheme, set Team under Signing & Capabilities and press Run.

The export fills in what `factoria.json` says (`icon`, `export.ios`; [EXPORTING.md](EXPORTING.md#platform-settings)):
`export.ios.teamId` is the default of `FA_IOS_DEVELOPMENT_TEAM` inside `build_ios.sh` (the environment variable still
wins, so one script serves several developers), `export.ios.buildNumber` is the app's `CFBundleVersion` (the `version` is
`CFBundleShortVersionString`), and the icon is the `Assets.xcassets` next to the script (an opaque 1024x1024 `AppIcon`
over `export.ios.iconBackground`).

A device needs, once: a cable (or the same network after the first pairing), "Trust this computer" accepted on it,
Developer Mode on (Settings > Privacy & Security > Developer Mode; it restarts the device; the switch shows up only after
the device was connected to Xcode once), and a team. The team id is the `OU` of your "Apple Development" certificate
(`security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject`) or Xcode > Settings > Accounts; a
free Apple ID works for your own devices. The first build for a team registers the connected device with it and
creates the provisioning profile (`xcodebuild -allowProvisioningDeviceRegistration`), which needs the device connected
during the build: `build_ios.sh` picks the first connected iPhone or iPad (`FA_IOS_DEVICE=<udid>` picks another,
`xcrun devicectl list devices` lists them). Building for "any device" with no device connected fails on a team's first
build with "Your team has no devices from which to generate a provisioning profile".

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
`FA_GAME_VERSION`, `FA_GAME_BUILD` (`CFBundleVersion`; default `FA_GAME_VERSION`), `FA_GAME_ORIENTATION`,
`FA_GAME_ASSET_CATALOG` (path of an `.xcassets` folder with an `AppIcon` set; no icon when empty) and
`FA_IOS_DEVELOPMENT_TEAM`. They feed
`platforms/ios/Info.plist.in` (full screen, MetalKit, orientation lists for
iPhone and iPad, launch screen via `UILaunchScreen`) and the Xcode target (the catalog is compiled into `Assets.car`,
`ASSETCATALOG_COMPILER_APPICON_NAME` is `AppIcon`). The game folder is copied
into the bundle after linking with the same exclude rules as `factoria export`
(`platforms/common/copy_game.cmake`). Without `FA_GAME_PROJECT_DIR` the app
starts with a red screen and logs why.

App Store: archive from Xcode (Product > Archive) with a distribution
certificate and provisioning profile. The icon comes from the game's `icon` (without one the app has the default
icon and the export warns); the launch screen is the plain `UILaunchScreen` of `Info.plist.in`, change it in Xcode
if you want a branded one. Raise `export.ios.buildNumber` for every upload.

## Touch input

The platform layer maps touches to the same `Input` object scripts use:

- every finger is a touch (`Input::touches()`; begin/move/end) in design coordinates;
- the first finger also drives the mouse: position plus `MouseLeft` down/up, so
  UI and scripts written for the mouse work unchanged (this is done by `Input` itself, so `game.touch` in tests and
  any other feed behave the same);
- input actions bound to `"Touch"` or `"MouseLeft"` in `factoria.json` fire on touch;
- there is no on-screen keyboard or on-screen gamepad yet: bind touch to actions
  and build on-screen buttons as entities that read touches.
- Physical gamepads: iOS (and macOS) read them through the GameController framework (extended gamepads: MFi, Xbox,
  PlayStation, Switch Pro). The framework names the buttons by position, like the engine (`A` is the bottom one). A pad
  keeps its slot while connected, an unplugged pad frees it (logged as `gamepad: pad 0 connected: Controller (Xbox
  One)`). Run on macOS with an Xbox Wireless Controller over Bluetooth (every button, both sticks with +Y up, triggers
  0..1, unplug and plug back); on iOS it is the same code, built and run but not yet with a real pad. The iOS Simulator
  shows a virtual pad of its own (`Gamepad (MFi)`) in slot 0. The web build has no gamepad support yet. Bindings such as `"GamepadA"` are
  accepted everywhere.
- Android gamepads (Bluetooth or USB pads that Android itself supports: Xbox, DualShock/DualSense, Switch Pro, most
  generic ones) come from the NativeActivity input queue: the button keys (`AKEYCODE_BUTTON_A`..`MODE`, the D-pad
  keys), and the joystick axes (left stick X/Y, right stick Z/RZ or RX/RY, triggers `LTRIGGER`/`RTRIGGER` or
  `BRAKE`/`GAS`, D-pad `HAT_X`/`HAT_Y`). Android's own key layouts already give pads the Xbox naming, so there is no
  mapping table; the face buttons are positional like everywhere (`GamepadA` is the bottom one). The engine takes
  these events through sokol_app's `sapp_desc.android.native_event_cb` hook (installed by `to_sapp_desc()`) and
  marks them handled, so pad buttons never act as Back or touches. System Back (the Back key or gesture) is not
  taken: it still leaves the app. Pads fill slots 0..3 in the order they first send an event.
  The NDK has no device enumeration, so `gamepad_android.cpp` asks `android.view.InputDevice` through JNI when a pad is
  new, about every 2 s, and when the app is back after a pause. `getDevice(id)` returning null means the pad was
  unplugged: its slot is freed (the game sees it disconnect, the other pads keep their numbers, the next pad takes the
  free slot). `getMotionRange(axis)` says which axes a pad has: `Z`+`RZ` without `RX`+`RY` means the right stick is
  Z/RZ; with `RX`+`RY` too and no trigger axes (`LTRIGGER`/`RTRIGGER`/`BRAKE`/`GAS`) the right stick is RX/RY and Z/RZ
  are the triggers (-1 released .. +1 pulled); a pad with both pairs AND trigger axes, or not asked yet, uses whichever
  pair is further from rest. Limits: a pad with only Z/RZ and no trigger axes is taken to have its right stick there;
  an unplugged pad is noticed within about 2 s; without JNI it keeps its slot until a fifth pad needs one. Never run
  on a device: the decisions are unit tested on every OS, the JNI glue is only built by CI.
- Losing focus or backgrounding releases all inputs and fires `Suspended`/`Resumed`; pads that are still connected
  report their real state again afterwards.
