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
| Relaunch | `am update-appinfo` (the update an overlay or a wallpaper-colour change sends) relaunches the activity: the old process ends with no native signal and no GL call without a context, the system starts the game again in a new process, which renders 60 frames, has the window focus and shows a picture, and logs no `E factoria` line | not applicable |
| Native plugin | the game has a native plugin with a Java class ([below](#native-plugins-on-android)): its script logged `probe add=3` (the sum came from the Java class through JNI) and `probe info=` with `"plugin":"example"` (`FA_SMOKE_EXPECT`) | the app links the plugin's static library ([below](#native-plugins-ios)): the same two lines in the console (`FA_IOS_PLUGIN_PROBE=1`) |
| Apple plugin | not applicable | the game links the Apple backend plugin (Swift, StoreKit, GameKit; [below](#native-plugins-ios)): the console shows `Apple backend ready`, `probe backend=apple` and `probe unlock=notSignedIn` (a Game Center call answered by the Swift code; `FA_IOS_APPLE_PROBE=1`, script `tools/cli/tests/apple_probe.js`) |
| Google Play plugin | the game has the Google Play backend plugin (a C bridge plus a Java module with Billing, Play Games and Play Integrity; [PLATFORM.md](PLATFORM.md#7-google-play-billing-play-games-services-and-play-integrity)): the log shows `Google Play backend ready`, `probe backend=googleplay` and `probe signin=unavailable` (the emulator has no Google Play services, so the Java code answers the sign-in with a teaching refusal; script `tools/cli/tests/googleplay_probe.js`, `FA_SMOKE_EXPECT`) | not applicable |

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

To upload the bundle from FactorIA: `publish.googleplay` runs `fastlane supply` with a service account key
(`FACTORIA_GOOGLEPLAY_JSON_KEY`) and refuses a debug-signed bundle. The first bundle of a new app must be uploaded by hand in
the Play Console; the service account, the track and the release notes are in
[EXPORTING.md](EXPORTING.md#google-play) (`publish_googleplay {"dryRun":true}` shows the command).

The passwords reach Gradle only as environment variables of its process: they are not in `gradle.properties`, `build.gradle`,
`build.log` or any file of the export, nor on a command line. A release export without a keystore **fails** (the AAB it
would produce is one Google Play rejects), with the steps above in its hint. To try a release build on your own device with
the debug key anyway, add `--allow-debug-key` (`"allowDebugKey": true` in the `project.export` command): the export then
warns and signs with the debug key; never upload that build. A keystore that does not exist, or missing passwords, are
reported by the plan (`project.export` with `dryRun`) before Gradle starts. To build by hand inside the exported project, set the same variables and run `./gradlew assembleRelease`
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

### Native plugins on Android

A native plugin ([EXTENDING.md](EXTENDING.md), section G) has an `android/` folder in its own folder, next to its
`src/`. `factoria call project.new_plugin` writes all of it; add `"android"` to the plugin's `"platforms"` in `factoria.json`
once the library is built:

```
plugins/example/
  CMakeLists.txt  src/plugin.c  include/fa_plugin.h     the C code, built with the NDK (below)
  android/
    build.gradle                                        a Gradle library module (namespace factoria.plugin.example)
    consumer-rules.pro                                  keeps factoria.plugin.** when the app is minified
    src/main/AndroidManifest.xml                        the SDK's permissions and components, merged into the app's
    src/main/java/factoria/plugin/example/Plugin.java   the Java the C code calls through JNI (src/main/kotlin works too)
    src/main/jniLibs/<abi>/libexample.so                the library: built by CMake, not by Gradle
```

**Build the library once per ABI the engine ships**, `arm64-v8a` (phones) and `x86_64` (the emulator); `CMakeLists.txt`
copies each build to `android/src/main/jniLibs/<abi>/`:

```bash
for abi in arm64-v8a x86_64; do
  cmake -S plugins/example -B plugins/example/build/$abi -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=$abi \
        -DANDROID_PLATFORM=android-26 -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake
  cmake --build plugins/example/build/$abi
done
```

Any recent NDK works (CI uses `sdkmanager "ndk;27.2.12479018"`); `ANDROID_PLATFORM` is the game's `minSdk` (26 by default). The
template links with 16 KB pages, like the player ([16 KB memory pages](#16-kb-memory-pages)). A library missing for an
ABI is not an export error (the module may build it itself): on a device of that ABI the plugin does not load, the log
says `cannot load libexample.so` and scripts that use it get that error.

**The export** (prebuilt and source mode alike) copies the module to `plugins/<name>` of the Gradle project, without
`build/`, `.gradle/` and `.cxx/`; adds `include ':plugin_<name>'` to `settings.gradle` and
`implementation project(':plugin_<name>')` to `app/build.gradle`; declares the Android Gradle plugin for libraries in the
root `build.gradle` (the same version as the application plugin); and writes the game's SDK levels to `gradle.properties`
(`factoria.compileSdk`, `factoria.minSdk`), which the template's `build.gradle` reads. A plugin that is only `.aar` /
`.jar` files (no `build.gradle` in `android/`) has them copied to `app/libs/<name>` and added as
`implementation fileTree(dir: 'libs/<name>', include: ['*.aar', '*.jar'])`. The module's folder inside the project is
never part of the game's assets. The export fails, naming the folder (`factoria validate` warns), when `android/` has
neither a `build.gradle(.kts)` nor an `.aar` / `.jar`.

**Java code and `hasCode`.** The manifest has `android:hasCode="false"` (the engine is all native), which tells Android not
to load any code of the APK. The export sets it to `true` as soon as a plugin brings code: its module has
`src/main/java` or `src/main/kotlin`, or it ships `.aar` / `.jar` files. A module that only lists Maven `dependencies`
and has no source folder of its own must get one (a Java file with its JNI glue) to turn it on. The exported project
allows Google and Maven Central as repositories, and Gradle refuses repositories declared in a module
(`FAIL_ON_PROJECT_REPOS`): an SDK from another repository ships as `.aar` files.

**AndroidX.** The template's `gradle.properties` sets `android.useAndroidX=true`: the Google SDKs a plugin brings (Play
Billing, Play Games, Play Integrity) depend on AndroidX libraries, and Gradle refuses to build them without it. The player
itself uses no AndroidX code, so nothing in a game without such a plugin changes.

**Calling Java from C.** `api->native_handle("android.activity")` is the game's `ANativeActivity*`: `->vm` is the
`JavaVM*` for JNI and `->clazz` the activity object. The game's thread is not attached to the VM, so attach it for the
call (`GetEnv`, then `AttachCurrentThread` and `DetachCurrentThread` when it was detached). `FindClass` on a native thread
only sees the system's classes: load the plugin's own classes through the activity's class loader
(`getClassLoader().loadClass("factoria.plugin.example.Plugin")`), then call the static method. Check for a pending Java
exception after each call that can throw and clear it (`ExceptionDescribe` logs it and clears it): JNI calls with an
exception pending are undefined, and the checked JNI of debug builds and emulators aborts the process. `src/plugin.c` of the template does all of this for `add(a, b)`: copy `java_add` and `add_in_java` for your own
calls.

CI covers it: the `android-apk` job scaffolds this plugin outside the game (`${FA_CI_PLUGINS}/example`), builds
`libexample.so` for both ABIs, exports, and checks that the APK carries both libraries and `factoria/plugin/example/Plugin`
in its dex; `android-emulator` then checks that the game's script got `add(1, 2) = 3` from the Java class and the output
of `example.info` (`FA_SMOKE_EXPECT` of `scripts/android-smoke.sh`).

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
`arm64` and `x86_64`. The iOS libraries are in the macOS package only (the Windows and Linux ones carry Android), but you
can still prepare an iOS project on Windows or Linux: `factoria setup players --platforms mobile` downloads the macOS
package and keeps its `mobile/` (Android and iOS) under `~/.factoria/players/<version>/mobile`, and `factoria export
--platform ios` finds it there, with no `--mobile-dir`. Copy the exported folder to a Mac to build it. **Source**: the export holds only `game/` and `build_ios.sh`, which runs CMake on the engine checkout.

`build_ios.sh` runs the CMake named by `FACTORIA_CMAKE` when it is set, else the CMake 3.24+ the export found
(`factoria setup cmake` installs one when there is none), else `cmake` from `PATH`.

Direct use of the engine checkout (no export):

```bash
cmake --preset ios-simulator -DFA_GAME_PROJECT_DIR=/path/to/game -DFA_GAME_BUNDLE_ID=com.example.mygame \
      -DFA_GAME_NAME="My Game" -DFA_GAME_VERSION=1.0.0 -DFA_GAME_ORIENTATION=portrait
cmake --build --preset ios-simulator --target factoria_player -- -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO
```

CMake variables: `FA_GAME_PROJECT_DIR`, `FA_GAME_BUNDLE_ID`, `FA_GAME_NAME`,
`FA_GAME_VERSION`, `FA_GAME_BUILD` (`CFBundleVersion`; default `FA_GAME_VERSION`), `FA_GAME_ORIENTATION`,
`FA_GAME_ASSET_CATALOG` (path of an `.xcassets` folder with an `AppIcon` set; no icon when empty),
`FA_GAME_PRIVACY_MANIFEST` (a `PrivacyInfo.xcprivacy` copied to the root of the app),
`FA_GAME_NON_EXEMPT_ENCRYPTION` (`ON` writes `ITSAppUsesNonExemptEncryption` as true; default `OFF`) and
`FA_IOS_DEVELOPMENT_TEAM`. They feed
`platforms/ios/Info.plist.in` (full screen, MetalKit, orientation lists for
iPhone and iPad, launch screen via `UILaunchScreen`) and the Xcode target (the catalog is compiled into `Assets.car`,
`ASSETCATALOG_COMPILER_APPICON_NAME` is `AppIcon`). The game folder is copied
into the bundle after linking with the same exclude rules as `factoria export`
(`platforms/common/copy_game.cmake`). Without `FA_GAME_PROJECT_DIR` the app
starts with a red screen and logs why.

### Native plugins (iOS)

A game's native plugins ([EXTENDING.md](EXTENDING.md), section G) are static libraries on iOS, linked into the app. The
plugin's folder holds one per SDK: `ios/iphoneos/lib<name>.a` (arm64) and `ios/iphonesimulator/lib<name>.a` (arm64 and
x86_64, like the player's simulator libraries). The template's `CMakeLists.txt` builds them with CMake's Xcode generator,
one SDK at a time (the commands are in its `README.md`), and defines `FA_PLUGIN_STATIC`, so that `FA_PLUGIN_INIT(<name>)`
defines `fa_plugin_init_<name>` instead of the exported `fa_plugin_init`: several plugins live in one executable.

`factoria export --platform ios` needs both libraries of every plugin declared for iOS (it names the missing file) and
copies the plugin's `ios/` folder to `plugins/<name>/` next to `build_ios.sh`, which passes `-DFA_GAME_PLUGINS=<name;name>`
and `-DFA_GAME_PLUGIN_DIR=<export>/plugins` to CMake. In both modes (`platforms/ios/plugins.cmake`, used by
`player/CMakeLists.txt` and by the exported `CMakeLists.txt`) the app links the libraries of the SDK it is configured for
and gets a generated source that calls `fa_register_static_plugin("<name>", fa_plugin_init_<name>)` from a static
constructor, before `main` (the source is the app's own, not an archive's, so the linker keeps it). The engine finds the
registered entry point instead of loading a library. A plugin declared for iOS that
the app was built without (no `FA_GAME_PLUGINS`) logs the warning "it is not linked into the app", and a script that uses
it gets that reason as an error, as for any plugin that does not load.

Direct use of the engine checkout: add `-DFA_GAME_PLUGINS=example -DFA_GAME_PLUGIN_DIR=/path/to/plugins` to the
`cmake --preset ios-simulator` command above, with `/path/to/plugins/example/iphonesimulator/libexample.a` in place (the
device build needs `iphoneos/`). CI does this with the example plugin (the `ios` job runs `scripts/ios-smoke.sh` with
`FA_IOS_PLUGIN_PROBE=1`).

**The plugin manifest, `ios/plugin.json`.** A static library cannot say which system frameworks it uses, whether it is
written in Swift, or which capabilities the signed app needs. The plugin says so in `ios/plugin.json` (optional; a plugin
without one needs nothing):

```json
{
  "frameworks": ["StoreKit", "GameKit"],
  "swift": true,
  "entitlements": {
    "com.apple.developer.game-center": true,
    "com.apple.developer.ubiquity-kvstore-identifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)"
  }
}
```

| Key | Meaning | What the export does |
|---|---|---|
| `frameworks` | System frameworks the plugin's code uses, by name (`"StoreKit"`, no `.framework`). | `build_ios.sh` passes `-DFA_GAME_PLUGIN_FRAMEWORKS=StoreKit;GameKit`; `platforms/ios/plugins.cmake` links each into the app. |
| `swift` | `true`: the plugin is written in Swift. | `-DFA_GAME_PLUGIN_SWIFT=ON`: the app gets what Xcode adds to a target with Swift code: the toolchain's Swift library folder for the SDK (the back-deployment libraries a Swift static library asks for) and the run path to the OS's Swift runtime, `/usr/lib/swift`. |
| `entitlements` | Capabilities of the signed app: a key to a boolean, number, string or list of strings. `$(TeamIdentifierPrefix)` and `$(CFBundleIdentifier)` are Xcode's build settings. | The entitlements of all plugins are merged into `factoria_player.entitlements` next to `build_ios.sh` (`-DFA_GAME_ENTITLEMENTS=...`, which the project's `CODE_SIGN_ENTITLEMENTS` points to), so Xcode's automatic signing turns the capabilities on for the App ID. Two plugins that ask for the same entitlement with different values fail the export, naming both. |

A manifest with a mistake (an unknown key, a wrong type) fails the export with the file, the JSON pointer and a "did you
mean". The Apple plugin ([PLATFORM.md](PLATFORM.md#6-apple-storekit-2-game-center-and-icloud)) is the example of all
three keys: Swift code built with `xcrun swiftc`, StoreKit and GameKit, Game Center and iCloud entitlements. When a linked
plugin brings StoreKit and the catalog has `platform.products`, the export also writes `Products.storekit` (a StoreKit
configuration made from the catalog) and `build_ios.sh` references it from the Xcode scheme (`storekit_scheme.cmake`, run
after CMake generates the project): running the project from Xcode sells the products without App Store Connect.
`./build_ios.sh --run` launches with `simctl`, which does not use it.

A plugin written in Swift builds with the Xcode toolchain (`xcrun swiftc`; the Apple plugin's `CMakeLists.txt` is the
example): one static library per SDK, and an entry point defined with `@_cdecl` that a small C file
(`fa_plugin_init_<name>`) calls. Not supported yet: Swift packages, XCFrameworks and third-party frameworks that are not
part of the iOS SDK (the manifest names system frameworks only).

App Store: archive from Xcode (Product > Archive) with a distribution
certificate and provisioning profile, and export the archive as an `.ipa` (Organizer > Distribute App > App Store Connect >
Export). `publish.appstore` uploads that `.ipa` to App Store Connect and TestFlight with an App Store Connect API key: the key,
the build number, the processing time and what to do in TestFlight are in [EXPORTING.md](EXPORTING.md#app-store-connect-testflight)
(`publish_appstore {"dryRun":true}` shows the `xcrun altool` command; it runs on a Mac). The icon comes from the game's `icon` (without one the app has the default
icon and the export warns); the launch screen is the plain `UILaunchScreen` of `Info.plist.in`, change it in Xcode
if you want a branded one. Raise `export.ios.buildNumber` for every upload. What the two stores ask about privacy is in
[Store privacy forms](#store-privacy-forms).

## Store privacy forms

Both stores ask what your app does with user data before they accept an upload, and they check it against the app. The
answers depend on the whole game (its plugins, its scripts, your servers), so these are the facts about the engine to
build them from, not a form already filled in. Check the store's current help pages too: the forms change.

**What the engine itself does.** Nothing leaves the device: no analytics, no advertising id, no accounts, no network
connection of its own. Saves (`storage`) and `log.txt` are files in the app's private folder, and crash reports are
written next to them; nothing sends them anywhere. A game that adds its own networking, an ads or analytics SDK, or a store
plugin changes the answers, as below.

### App Store (iOS)

**Privacy manifest.** Apple requires a `PrivacyInfo.xcprivacy` in every app that calls a "required reason" API, and rejects
an upload that uses one without declaring it. `factoria export --platform ios` writes it next to `build_ios.sh` and the
build copies it to the root of the app. For the engine it declares:

| API category | Reason | Why |
|---|---|---|
| `FileTimestamp` | `C617.1` | the size and modification time of the game's own files inside the app (`fs` file checks, hot reload), through `stat` |
| `SystemBootTime` | `35F9.1` | the monotonic clock (`mach_absolute_time`) that the frame loop, physics and the script runtime measure elapsed time with |

It also says `NSPrivacyTracking` false, no tracking domains and no collected data types. The engine does not use disk space
or `UserDefaults` APIs; the Apple plugin (StoreKit, Game Center, iCloud key-value store) is made of system frameworks,
which carry their own declarations.

If your game or a plugin of yours calls more required-reason APIs, collects data or tracks, say so in `factoria.json`; the
export merges it with the engine's entries (a category the engine already declares gets the union of the reasons):

```json
"export": {
  "ios": {
    "usesNonExemptEncryption": false,
    "privacy": {
      "tracking": false,
      "accessedApis": [{ "category": "DiskSpace", "reasons": ["E174.1"] }],
      "collectedData": [
        { "type": "PurchaseHistory", "linked": true, "purposes": ["AppFunctionality"] }
      ]
    }
  }
}
```

- `accessedApis[].category`: `FileTimestamp`, `SystemBootTime`, `DiskSpace`, `UserDefaults` or `ActiveKeyboards`. `reasons`
  are Apple's codes for that category: FileTimestamp `DDA9.1` (shown to the user), `C617.1` (files in the app's own container),
  `3B52.1` (files the user chose), `0A2A.1` (a third-party SDK's wrapper); SystemBootTime `35F9.1` (time elapsed between
  events inside the app), `8FFB.1` (a timestamp of an event shown to the user), `3D61.1` (a user-initiated bug report);
  DiskSpace `E174.1` (check before writing a file or to tell the user), `85F4.1` (show the user), `7D9E.1` (a user-initiated
  bug report), `B728.1` (health research apps); UserDefaults `CA92.1` (the app's own preferences), `1C8F.1` (app group),
  `C56D.1` (third-party SDK wrapper), `AC6B.1` (managed app configuration); ActiveKeyboards `3EC4.1` (a custom keyboard),
  `54BD.1` (to pick a keyboard-specific UI). Apple's page "Describing use of required reason API" has the exact wording.
- `collectedData[].type`: `Name`, `EmailAddress`, `PhoneNumber`, `PhysicalAddress`, `OtherUserContactInfo`, `Health`, `Fitness`,
  `PaymentInfo`, `CreditInfo`, `OtherFinancialInfo`, `PreciseLocation`, `CoarseLocation`, `SensitiveInfo`, `Contacts`,
  `EmailsOrTextMessages`, `PhotosOrVideos`, `AudioData`, `GameplayContent`, `CustomerSupport`, `OtherUserContent`,
  `BrowsingHistory`, `SearchHistory`, `UserID`, `DeviceID`, `PurchaseHistory`, `ProductInteraction`, `AdvertisingData`,
  `OtherUsageData`, `CrashData`, `PerformanceData`, `OtherDiagnosticData`, `EnvironmentScanning`, `Hands`, `Head`,
  `OtherDataTypes`. `purposes`: `ThirdPartyAdvertising`, `DeveloperAdvertising`, `Analytics`, `ProductPersonalization`,
  `AppFunctionality`, `Other`. `linked` is whether the data is tied to the user's identity, `tracking` whether it is used to
  track the user.
- `tracking` and `trackingDomains`: only for apps (or SDKs in them) that track users across other companies' apps and sites;
  tracking also needs the App Tracking Transparency prompt, which the engine does not show.
- A mistake in any of these (an unknown category, a reason code that belongs to another category, a misspelled data type)
  is an error that names the pointer in `factoria.json` and suggests the closest valid value.

Third-party SDKs that you link as plugins bring their own manifest requirements; add what they document.

**Encryption.** `Info.plist` gets `ITSAppUsesNonExemptEncryption` `false`, so App Store Connect does not ask the
export-compliance question on every upload. That is right for a game that uses only the encryption iOS provides (HTTPS
through the system, the Keychain). If your game ships its own cryptography, set `export.ios.usesNonExemptEncryption` to
`true` and answer the export-compliance questions in App Store Connect (some countries need documentation).

**The App Privacy "nutrition label"** (App Store Connect > your app > App Privacy) is filled in by hand and should match the
manifest:

| Your game | What to answer |
|---|---|
| Engine only, saves on the device | "Data Not Collected" |
| Apple plugin: purchases (StoreKit 2), Game Center, iCloud key-value saves | Apple processes these inside its own services and the data is not sent to you, so they do not add a "collected" entry. If your own server receives receipts or Game Center player ids, add Purchase History and/or User ID, linked to the user, purpose App Functionality |
| An ads, attribution or analytics SDK | Whatever the SDK documents (Device ID, Advertising Data, Product Interaction, ...), and `tracking` plus the ATT prompt if it tracks |
| Your own account system or backend | The data you send (Name, Email Address, User ID, Gameplay Content...) |

### Google Play (Android)

**Data safety** (Play Console > App content > Data safety) is also filled in by hand; Play compares it with the app. The
engine adds no permissions of its own to `AndroidManifest.xml` (add some with `export.android.permissions`). The answers:

| Your game | What to declare |
|---|---|
| Engine only, saves on the device | "No data collected" and "No data shared". `log.txt`, crash reports and saves stay in the app's private folder; no network library is linked |
| `googleplay` plugin: purchases (Play Billing) | Play Billing handles the payment and shows the purchase history to the game on the device; the Billing library adds the `com.android.vending.BILLING` permission to the manifest. Declare Purchase history (Financial info) only if your own server receives or stores purchase tokens or receipts |
| `googleplay` plugin: Play Games Services (when `playGamesId` is set) | The Play Games SDK signs the player in and keeps achievements, leaderboard scores and Saved Games in the player's Google account. Declare a player id (User IDs under Personal info) and the game data (App activity) when your own backend receives them; where only Google's services hold them, follow Google's definition of "collected" in the Data safety help |
| `googleplay` plugin: Play Integrity | The request and the verdict go through Google; the token goes to your server. Declare what your server keeps of it (device or app integrity information) |
| An ads SDK | Advertising ID (`com.google.android.gms.permission.AD_ID` in `export.android.permissions`), plus what the SDK documents; apps that target Android 13+ without it get a zeroed ad id |
| Your own backend, accounts, analytics | The data you send, whether you share it, whether it is encrypted in transit and whether players can ask for deletion |

Play also asks for a **privacy policy** link on the store listing of every app, and for the "Data deletion" answers when you
have accounts. Go through the form again whenever you add a plugin or SDK.

## Touch input

The platform layer maps touches to the same `Input` object scripts use:

- every finger is a touch (`Input::touches()`; begin/move/end) in design coordinates;
- the first finger also drives the mouse: position plus `MouseLeft` down/up, so
  UI and scripts written for the mouse work unchanged (this is done by `Input` itself, so `game.touch` in tests and
  any other feed behave the same);
- input actions bound to `"Touch"` or `"MouseLeft"` in `factoria.json` fire on touch;
- an optional on-screen gamepad (`TouchStick`, `TouchButton`) plays a game written for a pad, see "On-screen gamepad"
  below. The on-screen keyboard, the Back button, the notch and vibration are in "Phone features" below.
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
  marks them handled, so pad buttons never act as Back or touches. System Back (the Back key or gesture) is a
  separate event, `input.onBack` (see "Phone features"). Pads fill slots 0..3 in the order they first send an event.
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

### On-screen gamepad

A game that plays with a gamepad plays on a phone with two UI components and no change to its scripts. A `TouchStick` is
a disc with a knob that follows the finger; a `TouchButton` is a disc with an optional label. A finger on them moves a
stick or holds a button of the **touch pad**, a virtual pad the action bindings read like a real one: an action bound to
`"GamepadLeftStickRight"` gets the stick's push, one bound to `"GamepadA"` fires while the `A` button is held. The default
`ui_*` actions include the left stick and `GamepadA` / `GamepadB`, so the stick also walks menus.

```json
{ "id": "move", "components": { "Transform": { "position": [40, -40] },
    "TouchStick": { "anchor": [0, 1], "pivot": [0, 0], "size": [220, 220] } } },
{ "id": "jump", "components": { "Transform": { "position": [-40, -60] },
    "TouchButton": { "anchor": [1, 1], "pivot": [1, 0], "button": "A", "text": "A" } } },
{ "id": "dash", "components": { "Transform": { "position": [-160, -40] },
    "TouchButton": { "anchor": [1, 1], "pivot": [1, 0], "button": "B", "text": "B" } } }
```

with `"jump": ["Space", "GamepadA"]`, `"move_left": ["A", "GamepadLeftStickLeft"]`... in `factoria.json` `input.actions`.

- **Where**: they are UI widgets (screen space, `anchor`, `pivot`, `size`, `layer`, `color`, a `texture` instead of the
  disc), and `safeArea` is on by default, so the anchor is a corner of the safe area and the notch never covers them.
  A Panel can lay them out like any widget.
- **When**: with `touchOnly` (the default) they are drawn only while the player uses touch (`input.lastDevice` is
  `"touch"`; a phone starts that way), so they disappear when the player picks up a real pad or the keyboard and come back
  on the next touch. A finger landing on one always works. `touchOnly: false` draws them on any device: desktop previews,
  screenshots, tests.
- **Fingers**: each control takes the finger that lands on it and keeps it until it lifts, even when the finger slides
  off (the stick stays at full tilt in that direction). Several fingers work at once: move and jump together. A finger a
  control holds is the pad's: it is not in `input.touches`, does not fire `"Touch"` or move the mouse, so a game's own
  touch handling never sees it. When controls overlap, the one created later takes the finger.
- **Values**: the stick's edge (half its shorter side) is full tilt; the pad deadzone (`input.deadzone` in
  `factoria.json`, default 0.2) applies like on a real stick. The components show the state at run time: `value` and
  `pressed` on a `TouchStick`, `pressed` on a `TouchButton`, `shown` on both; `ui.state` lists them too.
- **What it is not**: the touch pad has no number (`input.gamepad(0)` and the numbered pad queries never see it) and does
  not make `input.lastDevice` `"gamepad"`, so button prompts stay on touch. A mouse click does not press the controls.
  The stick is fixed where it is drawn (no floating stick that appears under the thumb).

Test it headless like any touch: `game.touchStart([x, y])`, `game.touchMove`, `game.touchEnd` (or the command
`game.input {"touch": ...}`) on the control's rectangle, then check the action (`input.vector("move_left", "move_right",
"move_down", "move_up")`).

## Phone features

What a phone has that a desktop does not, in the scripts (`import { screen, input } from "factoria"`). Every call is a
safe no-op on desktop, and a headless run records it, so a game can be tested without a device.

### Notch and system bars: the safe area

`screen.safeArea` is the part of the screen a notch, rounded corners, the camera hole, the home indicator and the system bars
leave free, as a `Rect` in design pixels (y down). `screen.insets` is the same as four numbers (`left`, `top`, `right`,
`bottom`: how much each edge loses) and `screen.size` is the design size. On a phone they follow the device, also when it is
turned; on desktop and in a headless run the safe area is the whole screen.

The scene follows it without a line of script: set `safeArea: true` next to `anchor` on a `Sprite`, `Shape2D`, `Text`,
`ParticleEmitter` or a UI widget (`Button`, `Panel`, ...) and the anchor is a corner or an edge of the safe area instead of
the screen. A score in the top left corner (`anchor: [0, 0]`, `safeArea: true`) never hides under the notch; a background
(`safeArea: false`, the default) still fills the whole screen. Layouts, hit testing, drawing and the editor use the same rule.

- Android: the window insets of the decor view (system bars and display cutout; API 30+ `WindowInsets.getInsets`, older
  releases `getSystemWindowInset*` and the API 28 `DisplayCutout`). The game is full screen, so the bars only count when
  the user pulls them in. Read again about every 15 frames and on every resize and rotation.
- iOS: `UIView.safeAreaInsets` of the game view, the same way.
- A phone that reports nothing (an old Android) gets the whole screen.

To look at a layout without the phone, pretend to have a notch: `game.setSafeArea("phone-portrait")` (or
`"phone-landscape"`, `"none"`, or `{ top: 40, left: 10 }` in design pixels) in a script test, or the command
`screen.set_safe_area {"profile":"phone-portrait"}` followed by `game.step` and `game.screenshot`. The profiles are an iPhone
15 (393 x 852 points: 59 at the top and 34 at the bottom; turned, 59 on each side and 21 at the bottom) as fractions of the
design size. The test hook ends with each test.

### The Back button

Android's Back (the key or the gesture) reaches the game as `input.onBack(handler)`. The newest handler is asked first and
the first one that does not return `false` consumes Back (return `true`, or nothing); if none consumes it, the game
leaves, which is what Android would have done. Close the pause menu, go up one screen, and let the main menu return
`false`:

```js
const off = input.onBack(() => {
  if (!pauseMenu.visible) return false; // nothing to close here: ask the next handler, or leave
  pauseMenu.close();
  return true;
});
```

Handlers end with the scene, like `ui.on`; call the returned function to remove one earlier. In a test, `game.pressBack()`
sends it (the command `game.input {"back": true}` does the same). iOS and desktop have no Back button: nothing calls it.
The exported manifest sets `android:enableOnBackInvokedCallback="false"`: from Android 16 an app that targets API 36 gets
Back through the new predictive-back callback instead of a key event (and a `NativeActivity` would simply finish), and
this attribute asks for the key event, which is what the engine reads. The game therefore has no predictive-back
animation. Not tried on an Android 16 device or emulator.

### Vibration

`input.vibrate(seconds = 0.1)` buzzes the phone for up to 5 seconds. Android uses the `Vibrator` service (`VibrationEffect`
on API 26+), and the exported manifest always carries the `VIBRATE` permission (a normal permission: nothing to ask the
player). iOS cannot choose the length: up to 0.05 s is a light tap, up to 0.15 s a medium one, up to 0.3 s a heavy one,
and anything longer the system vibration (about half a second). Devices without a motor (tablets, iPads, the emulator)
do nothing. A headless run records the calls: `game.vibrations()` in a test returns the list of seconds asked for.

### The on-screen keyboard

A `TextField` with focus raises the keyboard by itself and hides it when it loses the focus; `input.showKeyboard(on)` does
it from a script. What is typed arrives in `input.text` (and Enter, Backspace as `keyPressed`).

- iOS: sokol_app's hidden text field. Composed text (accents, dictation, swipe typing) arrives; a character outside the
  Basic Multilingual Plane (emoji) is dropped by sokol_app. Verified in the source only: the iOS keyboard was not run on a
  device for this change.
- Android: a `NativeActivity` has no text editor, so the keyboard is shown with `InputMethodManager` on the decor view
  (`showSoftInput`, `toggleSoftInput` as a fallback; the NativeActivity method sokol_app uses does nothing on many
  devices) and what is typed comes as key events, from which the engine asks Android for the character the key makes. That
  gives letters, digits, punctuation, Space, Enter and Backspace in the keyboard's layout, and accents through dead keys.
  Limits: a keyboard that composes words or emoji (predictive text, swipe, CJK input methods, emoji panels, voice typing)
  cannot send them to a `NativeActivity`, and some keyboards send nothing until a hardware-style key is pressed. A hardware
  keyboard works the same way (also on a tablet). Written against the NDK headers and checked for syntax only: it was not
  run on a device or in the emulator, and the calls are made from the game's thread instead of the Android UI thread, which
  works on the releases known to the author but is not guaranteed by Android.
