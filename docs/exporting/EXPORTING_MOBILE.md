# Exporting a game, page 5 of 6

Part of [Exporting a game](../EXPORTING.md) (the entry page lists every page).

## Mobile exports: prebuilt or source

Android and iOS exports need the engine's runtime for the phone. It does not depend on the game (the game travels as
files inside the APK / app), so the FactorIA download carries it ready-made, next to the `factoria` executable:

```
FactorIA/
  factoria  factoria_player
  mobile/
    android/jniLibs/arm64-v8a/libfactoria_player.so     in every package (Windows, macOS, Linux)
    android/jniLibs/x86_64/libfactoria_player.so
    ios/iphoneos/*.a                                     in the macOS package only (`factoria setup players` fetches it on Windows and Linux)
    ios/iphonesimulator/*.a                              arm64 + x86_64
```

The Android/iOS project templates are built into the `factoria` binary, like the docs and game templates. Every Android
and iOS export therefore runs in one of two **modes**, reported as `mode` in the export report (`--json`, `project.export`)
and in the CLI output (`Exported android build to ... (22 files, mode: prebuilt)`):

| mode | The engine runtime is | Needs |
|---|---|---|
| `prebuilt` | the ready-made `mobile/` libraries of the download, copied into the project | Android: JDK 17 and the Android SDK only (no NDK, no CMake); `factoria setup android` installs both. iOS: Xcode and CMake 3.24+ (no engine source); `factoria setup cmake` installs CMake |
| `source` | compiled from an engine source checkout, with that checkout's templates | the checkout and, on Android, NDK r27+ and CMake 3.31 (engine developers) |

**The rule**, in order (the first that applies wins):

1. `--engine-root DIR` was given, or `$FACTORIA_ENGINE_DIR` is set (and no `--mobile-dir` was given): **source**, from that
   checkout. A path that is not an engine checkout is an error, not a silent fallback.
2. `--mobile-dir DIR` was given, or the `mobile/` folder next to the `factoria` executable holds the players (Android: a
   `libfactoria_player.so` for both `arm64-v8a` and `x86_64`; iOS: `libfactoria_player_main.a` in both `iphoneos` and `iphonesimulator`),
   or `factoria setup players` installed them (`<FactorIA home>/players/<version>/mobile`): **prebuilt**.
3. The source checkout this `factoria` was built from still exists (a development build): **source**.
4. Otherwise the export fails and says what to do: use the FactorIA download, or set `FACTORIA_ENGINE_DIR`.

So the download exports prebuilt unless you point it at a checkout; a `factoria` built from the repository has no
`mobile/` folder and keeps exporting from source. The `nextSteps` of the report repeat which mode ran.

### Android

`factoria export --platform android` writes a complete Gradle project, then builds the app with it:

```
my-game-android/
  my-game-debug.apk                the result (my-game.apk for --release, .aab with --format aab)
  build.log                        everything Gradle printed
  gradlew  gradlew.bat  gradle/wrapper/{gradle-wrapper.jar,gradle-wrapper.properties}   the Gradle wrapper (Gradle 8.14.3)
  settings.gradle  build.gradle  gradle.properties  local.properties (sdk.dir of this computer: do not commit)
  app/build.gradle                 applicationId, versionName/Code, minSdk/targetSdk, abiFilters, signing (prebuilt: no native build)
  app/src/main/AndroidManifest.xml NativeActivity + android.app.lib_name=factoria_player_vulkan, factoria.engine.GlActivity
                                   (lib_name factoria_player, process :gl), orientation, icon, permissions, hasCode
  app/src/main/java/factoria/engine/GlActivity.java   the OpenGL player's activity (a plain NativeActivity)
  app/src/main/res/values/strings.xml   app name
  app/src/main/res/mipmap-*/       launcher icons made from the project's icon (and the adaptive icon)
  app/src/main/assets/             the game + assets_index.txt
  app/src/main/jniLibs/<abi>/libfactoria_player.so, libfactoria_player_vulkan.so   prebuilt mode only: the engine
  plugins/<name>/                  native plugins: the Gradle module of each plugin's android/ folder
  app/libs/<name>/                 native plugins: the .aar / .jar files of a plugin that has no module
```

`assets_index.txt` lists every game file (one project-relative path per line).
The engine needs it because Android cannot enumerate folders inside an APK.

**Two players.** The launcher activity loads `libfactoria_player_vulkan.so`, the Vulkan player. Where Vulkan cannot start,
or when the game's choice is `gles3`, it starts `factoria.engine.GlActivity` (the OpenGL player, `libfactoria_player.so`, in the
process `:gl`) with the reason in the intent extras, and finishes itself; the OpenGL player never hands back
([Two players on Linux and Android](../RENDERING.md#two-players-on-linux-and-android)). `export.android.vulkanPlayer: false`
ships only `libfactoria_player.so`, which the launcher activity then loads, and the manifest declares no GlActivity. In source mode Gradle builds
both targets (`factoria_player`, `factoria_player_vulkan`, `-DFA_PLAYER_VULKAN=ON`); in prebuilt mode libraries without
`libfactoria_player_vulkan.so` (a release older than the Vulkan player) ship the OpenGL player only, and the report warns.

**Formats** (`--format`, or `export.android.format` in `factoria.json`; the flag wins):

| format | Runs | Result |
|---|---|---|
| `apk` (default) | `./gradlew assembleDebug` (`assembleRelease` with `--release`) | `<slug>-debug.apk` (`<slug>.apk`): an app you install with `adb install -r` |
| `aab` | `./gradlew bundleDebug` (`bundleRelease`) | `<slug>-debug.aab` (`<slug>.aab`): the Android App Bundle Google Play takes |
| `gradle` | nothing | only the project; no JDK or SDK is needed. Build it yourself (`./gradlew assembleDebug`) or open it in Android Studio |

**What the build needs**: a JDK 17+ and the Android SDK (found as in [Finding the Android toolchain](EXPORTING_SETUP.md#finding-the-android-toolchain);
`plan_export` / `dryRun` reports them as `toolchain` and fails early, with what to install, when one is missing).
Gradle itself is not needed: the export writes the project's own wrapper, and the first build downloads Gradle 8.14.3, the
Android Gradle plugin and the SDK platform (needs the internet and accepted SDK licenses: `sdkmanager --licenses`, once). The
wrapper is checked against a fixed SHA-256, so every machine builds with the same Gradle. The export gives Gradle the JDK
and SDK it found (`JAVA_HOME`, `ANDROID_HOME`; `ANDROID_SDK_ROOT` is unset so the two cannot disagree) and writes the SDK
path to `local.properties`.

**Progress and logs**: the CLI prints Gradle's output on stderr as it runs (not with `--json`; C++ callers get the lines through
`ExportOptions::progress`). Everything is also in `build.log` of the export folder. Prebuilt mode on an Apple-silicon Mac: about 45 seconds the
first time (Gradle and the Android Gradle plugin are downloaded), a few seconds from then on. **Source** mode compiles the
whole engine for two ABIs the first time (minutes, less with ccache).

**When the build fails** the error says what Gradle said ("What went wrong") and the export folder stays, so you can open the
project in Android Studio or run `./gradlew` there. The most common causes get a specific fix in the error's hint: SDK licenses
not accepted, a JDK that is too old or new, a wrong SDK folder, no internet for the first download. A cancelled build
(`ExportOptions::cancel`) also leaves the folder; export again to continue where Gradle stopped.

**Prebuilt** (the download): `app/build.gradle` has no `externalNativeBuild`, `ndkVersion` or engine path; Gradle only
packages `jniLibs` (`arm64-v8a` and `x86_64`, both required) and the assets, so the build needs the Android SDK alone.

**Source**: Gradle compiles the engine through CMake from the engine checkout (`factoria.engineDir` in `gradle.properties`,
default: the checkout the export used; override with `FACTORIA_ENGINE_DIR`), which takes several minutes the first time and
needs NDK r27+ and a CMake 3.24+ (`sdkmanager "ndk;27.2.12479018" "cmake;3.31.6"`). Android Gradle Plugin wants an exact CMake
version, so the export reads it instead of requiring 3.31.6: the SDK's `cmake;3.31.6` when installed; else the newest CMake 3.24+
in the SDK; else a CMake 3.24+ of this computer (PATH, Homebrew, `/Applications/CMake.app`, `C:\Program Files\CMake`, or the
one `factoria setup cmake` installs), which the export hands to Gradle with `cmake.dir=<its folder>` in `local.properties`.
The version it picked goes to `factoria.cmakeVersion` in `gradle.properties`, and a warning says which. To build with no
network and no SDK CMake: install CMake 3.24+ (`brew install cmake`, `winget install Kitware.CMake`, or
https://cmake.org/download; a Mac can use `factoria setup cmake`), a `ninja` next to it or on `PATH`, and run Gradle with
`--offline`. Edit `cmake.dir` and `factoria.cmakeVersion` by hand when you move the project to another computer.

The engine's libraries are linked for 16 KB memory pages (Google Play requires it for apps that target Android 15+), and the
APK is zip-aligned for them.

**Native plugins** ([EXTENDING.md](../EXTENDING.md), section G). A plugin declared for `android` needs an `android/` folder in
its own folder: a Gradle library module (`build.gradle` or `build.gradle.kts`, with the plugin's `lib<name>.so` for
`arm64-v8a` and `x86_64` in `src/main/jniLibs/<abi>/` and any Java or Kotlin code) or `.aar` / `.jar` files. The export
copies a module to `plugins/<name>` (without its `build/`, `.gradle/` and `.cxx/`) and adds it to `settings.gradle` and
to the app's dependencies; `.aar` / `.jar` files go to `app/libs/<name>`. The module reads `factoria.compileSdk` and
`factoria.minSdk` from `gradle.properties`, which the export writes from `targetSdk` and `minSdk`. `android:hasCode` is
`true`: the engine ships one Java class (`factoria.engine.Ime`, the IME connection) next to a plugin's code. The Gradle project sets `android.useAndroidX=true`,
which the Google SDKs of a plugin (Play Billing, Play Games) need. A plugin folder inside the project never ships
as game files. A plugin without an Android build fails the export and says what to put in `android/`. Building the
library, calling Java from C, `hasCode` and the details: [MOBILE.md](../mobile/MOBILE_ANDROID.md#native-plugins-on-android).

**Platform settings** that change the project: `minSdk` / `targetSdk` (`compileSdk` follows `targetSdk`), `versionCode`,
`permissions` (extra `<uses-permission>` lines), the `icon` (launcher icons and adaptive icon, in the manifest as `icon` and
`roundIcon`; without one the platform default and a warning) and `signing`. See [Platform settings](EXPORTING_SETUP.md#platform-settings).

**Signing**. A debug build is signed with the debug key of the machine (fine for trying the app). `--release` signs with the
keystore of `export.android.signing` (`keystore`, `alias`; a project-relative path is resolved against the project and the
file is never copied into the app). The passwords are never written to a project, a file of the export or a command line
(the only passwords on a command line are the GOG and Microsoft Store ones, see "Secrets and the process list"):
they come from `FACTORIA_ANDROID_KEYSTORE_PASSWORD` and `FACTORIA_ANDROID_KEY_PASSWORD` (or `android.keystorePassword` /
`keyPassword` of `~/.factoria/export.json`; the key password defaults to the keystore password) and are given to the Gradle
process as environment variables only. `plan_export` and `--release` check that the keystore exists and that the passwords
are set before Gradle starts. A release build with no keystore configured is an error, because the app it would make is one
Google Play rejects; the error says how to make a key. To try a release build on your own device with the debug key, pass
`--allow-debug-key` (the `project.export` command's `allowDebugKey`): the export then warns and uses the debug key, and that
build must not be uploaded. To make a key: `keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
(keep the file and its passwords safe). A release build you run by hand in the exported project (`./gradlew assembleRelease`)
reads the same environment variables.

```bash
factoria export --platform android --format aab --release
adb install -r my-game/build/export/my-game-android/my-game-debug.apk   # the apk format
```

Prerequisites, signing and troubleshooting: [MOBILE.md](../MOBILE.md).

### iOS

`factoria export --platform ios` (macOS with Xcode only for the next step) writes the game and a `build_ios.sh`. The
script runs CMake with the Xcode generator and the same settings as the `ios` preset, adding
`-DFA_GAME_PROJECT_DIR=game -DFA_GAME_BUNDLE_ID=... -DFA_GAME_NAME=... -DFA_GAME_VERSION=... -DFA_GAME_BUILD=...
-DFA_GAME_ORIENTATION=... -DFA_GAME_ASSET_CATALOG=Assets.xcassets -DFA_IOS_DEVELOPMENT_TEAM=...` (and, for a game with
native plugins, `-DFA_GAME_PLUGINS=... -DFA_GAME_PLUGIN_DIR=plugins`):

```bash
./build_ios.sh --simulator --run                         # build, start in the iOS Simulator, console in the terminal
FA_IOS_DEVELOPMENT_TEAM=ABCDE12345 ./build_ios.sh --run  # the same on the connected iPhone or iPad
./build_ios.sh --simulator --build -- <xcodebuild args>  # only build; everything after -- goes to xcodebuild
./build_ios.sh --simulator     # or without flag for a device; opens build/FactorIA.xcodeproj
```

**MetalFX (`render.upscaler` mode `metalfx`).** Nothing to set in the export: the player loads Apple's MetalFX framework at run time (no entitlement,
no `Info.plist` key, no link step), so one build runs on every iOS the engine supports. It draws on a device with iOS 16 or later and a GPU with the
MetalFX scalers; its reactive mask (bright particles and additive sprites that must not trail) needs iOS 17.4, an older iOS draws without the mask. The
iOS Simulator and Android do not have it: the mode draws as `temporal` (then `spatial`) and `render.supports {"feature":"metalfx"}` says why. A game
that sets `mode` `auto` gets the best mode on each device ([UPSCALING.md](../UPSCALING.md), "MetalFX (Apple GPUs)").

A device build registers the connected device with the team on the first build (Developer Mode must be on); see
[MOBILE.md](../mobile/MOBILE_IOS.md#ios).

From the project's [platform settings](EXPORTING_SETUP.md#platform-settings) the export takes:

- **The app icon.** `Assets.xcassets/AppIcon.appiconset` is written next to `build_ios.sh`: one 1024x1024 PNG
  (Xcode 14 or newer derives every iPhone and iPad size from it), composed opaquely over `iconBackground` because
  iOS rejects transparency. The script passes the catalog to CMake as `FA_GAME_ASSET_CATALOG`; Xcode compiles it into
  `Assets.car` and fills `CFBundleIcons` and `CFBundleIconName` of the app. Without an icon the export warns and the app has the default icon.
- **`teamId`** becomes the default of `FA_IOS_DEVELOPMENT_TEAM` in the script, so `./build_ios.sh --run` signs for the
  device without the variable. Setting `FA_IOS_DEVELOPMENT_TEAM` yourself still wins.
- **`buildNumber`** becomes `CFBundleVersion` (`FA_GAME_BUILD`); when absent, the `version` is used as before.
- **The privacy manifest.** `PrivacyInfo.xcprivacy` is written next to `build_ios.sh` (`FA_GAME_PRIVACY_MANIFEST`) and copied
  to the root of the app: the engine's required-reason APIs (file time stamps, the monotonic clock), no tracking, no collected
  data. `export.ios.privacy` adds what the game or its plugins do. `Info.plist` also gets `ITSAppUsesNonExemptEncryption`
  (`false`; `export.ios.usesNonExemptEncryption` changes it). What to put in both, and in Google Play's Data safety form:
  [MOBILE.md](../mobile/MOBILE_PRIVACY.md#store-privacy-forms).
- **Plugin entries in `Info.plist`.** A plugin's `ios/plugin.json` can ask for Info.plist keys (`infoPlist`) and vendored
  XCFrameworks (`xcframeworks`); the AdMob plugin adds `GADApplicationIdentifier`, `SKAdNetworkItems` and, with
  `platform.ads.trackingPrompt`, `NSUserTrackingUsageDescription` (one `InfoPlist.strings` per language of the game when
  `platform.ads.trackingDescriptionKey` is set). [MOBILE.md](../mobile/MOBILE_IOS.md#native-plugins-ios).

**Native plugins** ([EXTENDING.md](../EXTENDING.md), section G). Each plugin declared for iOS needs `ios/iphoneos/lib<name>.a` and
`ios/iphonesimulator/lib<name>.a`; the export copies its `ios/` folder to `plugins/<name>/` and the app links it
([MOBILE.md](../mobile/MOBILE_IOS.md#native-plugins-ios)). The plugin's `ios/plugin.json` (system frameworks, Swift, entitlements) makes
`build_ios.sh` link those frameworks and the Swift runtime, and the export writes `factoria_player.entitlements` next to
it; when the catalog has products it also writes `Products.storekit` (with or without a store plugin), which the
Xcode scheme uses to sell the products when the project runs from Xcode, with one localization per language of the game
([PLATFORM.md](../platform/PLATFORM_APPLE_GOOGLE.md#6-apple-storekit-2-game-center-and-icloud)).

```
my-game-ios/                        prebuilt mode (the download for macOS)
  build_ios.sh  game/
  CMakeLists.txt  cmake/            a small project: Info.plist template, the game-copy script
  lib/iphoneos/*.a  lib/iphonesimulator/*.a   the engine and player as static libraries
  plugins/<name>/iphoneos/lib<name>.a  plugins/<name>/iphonesimulator/lib<name>.a   the native plugins of the game (if any)
```

In **prebuilt** mode the script configures `CMakeLists.txt` of the folder itself and links the app from `lib/`: no engine
source is needed. The libraries are static archives (not an XCFramework: the exported project picks the archives of the
SDK it is configured for, device or simulator, like the `ios` presets do, and CMake 3.24 cannot link XCFrameworks). In
**source** mode the folder holds only `game/` and `build_ios.sh`, and the script runs CMake on the engine checkout.
The iOS libraries ship in the macOS download only: on Windows and Linux run `factoria setup players --platforms mobile`
(it fetches the macOS package and keeps its `mobile/`), then `factoria export --platform ios` finds them without
`--mobile-dir`. Building the project still needs a Mac with Xcode.

Details in [MOBILE.md](../MOBILE.md).
