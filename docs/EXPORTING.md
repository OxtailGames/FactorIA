# Exporting a game

`factoria export` turns a game project into something you can ship. The same
function is available to tools as `fa::export_project` (`fa/tooling/export.h`), to AIs as the command
`project.export`, and in the editor as the **Export** button ([From the editor](#from-the-editor)).

```bash
factoria export [project] --platform <linux|windows|macos|android|ios> [--format apk|aab|gradle] [--out DIR] [--release]
                [--player PATH] [--engine-root DIR | --mobile-dir DIR]
```

`--format` is for Android (`apk` by default, `aab` for Google Play, `gradle` for only the project): see [Android](#android).

Before anything is written the project is validated: `factoria.json` must exist,
`name` must be set, `mainScene` must exist and `id` must be a reverse-DNS
identifier (required for Android and iOS: `com.example.spacedodge`, letters,
digits and underscores, every part starting with a letter; Java keywords such
as `new` are rejected for Android). Errors name the file, the JSON pointer and
the fix.

The result goes to `<out>/<game-slug>-<platform>/` (default `--out`:
`<project>/build/export`). That folder is deleted and recreated on every
export. `--json` prints the report: `outputDir`, `mode` (Android and iOS only, see [Mobile exports](#mobile-exports-prebuilt-or-source)),
`format` and `artifact` (Android: the format, and the absolute path of the APK/AAB that was built),
`notices` (see [License notices](#license-notices)), `files`, `nextSteps`, `warnings`.

## From an AI: `project.export`

The same export is the command `project.export` (MCP tool `project_export`, also `factoria call project.export`, the
editor console and `fa.call` in scripts), so an AI connected over MCP can build a Windows folder or the Android
APK without a shell. Arguments are all optional: `platform` (default: this machine), `format` (Android: `apk`, `aab` or
`gradle`), `out` (parent folder, relative to the project and inside it like the `fs.*` commands, default `build/export`) and
`release`. It returns the report (`outputDir`, `mode`, `format`, `artifact`, `notices`, `files`, `nextSteps`, `warnings`); an
unknown platform or format or a failed validation is an error with a hint. An Android export runs Gradle, which takes from
seconds to minutes (the first one much longer): the call returns when the build is done.
`dryRun: true` runs every check of the export and writes nothing: it returns `platform`, `outputDir` (the folder an
export would replace), `mode` (Android, iOS), `format` and `artifact` (Android), `toolchain` (Android with `apk` or `aab`:
`jdk`, `jdkFrom`, `jdkMajor`, `sdk` and `sdkFrom`, the JDK and SDK the build would use and where they were found), `player`
(desktop) and `warnings`, or the error the export would give, including a missing JDK or SDK, a missing keystore or
password for `--release` (`fa::plan_export` in C++). `--player`, `--engine-root` and `--mobile-dir` are CLI-only: the command uses the `factoria_player` and the `mobile/`
folder next to the running binary, or `$FACTORIA_ENGINE_DIR` when it is set.

```
project_export {"platform":"windows","release":true}
project_export {"platform":"android","dryRun":true}
```

## From the editor

The editor's toolbar has an **Export** button (also File > Export Game...). It opens the **Export game** window: one
button per platform (Windows, macOS, Linux, Android, iOS), each running this same export, never a separate one.

- **Output folder**: the parent folder of the exports, `<project>/build/export` by default. Type a path (relative to
  the project), press **Choose...** for the system's folder dialog or **Default** to go back; **Show in Finder** (Explorer
  on Windows, the file manager on Linux) opens it. An export replaces `<output folder>/<game>-<platform>` and nothing
  else. **Release** changes the build commands in the next steps, as `--release` does.
- **Each platform's row** says what an export there writes (hover **Ready** for the folder and the player), or why it
  cannot run here, with the error and hint `factoria export` would print: a desktop player missing for another OS, no
  prebuilt mobile players and no engine checkout, a missing reverse-DNS `id` for Android and iOS... Its button stays
  disabled until that is fixed; the rows are checked again every few seconds (`fa::plan_export`, which writes nothing).
  For another OS's desktop export, **Choose player...** picks the `factoria_player` built there (the one next to
  `factoria` in the FactorIA download for that OS), like `--player`.
- **The report** shows under the buttons when the export finishes (it runs in the background; the editor keeps working):
  the output folder with **Show in Finder** / **Copy path**, the mode, the warnings and the numbered **next steps**,
  or the error and how to fix it. **Copy report** copies it as text. Android and iOS exports are projects, not
  finished apps: the next steps say how to build them (Gradle for the APK, `build_ios.sh` / Xcode on a Mac).

The export packages the files on disk: when the scene has unsaved changes the window says so and offers **Save scene**.

## What is shipped (and what is not)

Everything in the project except: `.factoria/`, every dot-file or dot-folder
(`.git`, `.mcp.json`, `.gitignore`), `build/` (earlier exports), `tests/`, `tools/`, `types/`,
`node_modules/`, `ENGINE_FEEDBACK.json` (the file named by `feedbackFile`),
`AGENTS.md`, `CLAUDE.md`, `jsconfig.json`, and the output folder itself. Your
project is never modified; the feedback file stays in the repository.

The export adds one file of its own, `FACTORIA_NOTICES.txt` (next section). An Android export also leaves out the keystore
named by `export.android.signing` when it lives inside the project (a warning says to keep it outside the repository):
a signing key must never end up in the assets of an APK.

## License notices

Your game is yours. FactorIA is open source under the MIT License, and the files `factoria new` puts in a project
(the templates) are MIT-0: use, change and sell them with no notice at all.

What an exported game does carry is the FactorIA runtime (`factoria_player`), which is FactorIA's MIT-licensed code
plus third-party libraries and fonts (sokol, QuickJS-ng, Box2D, stb, cgltf, dr_libs, nlohmann/json,
SDL_GameControllerDB, DejaVu Sans, Press Start 2P). Their licenses only ask that their notices travel with every copy,
so every export writes `FACTORIA_NOTICES.txt` with all of them where it ships with the game:

| Platform | `FACTORIA_NOTICES.txt` |
|---|---|
| Linux, Windows | next to the executable |
| macOS | `My Game.app/Contents/Resources/` |
| Android | `app/src/main/assets/` (inside the APK) |
| iOS | `game/` (inside the app bundle) |

Keep it in what you distribute (zip, installer, store build). You may also show it on a credits or licenses screen;
nothing else is required. `factoria docs licenses` prints the full list, including what only the developer tools
contain (Dear ImGui, in the editor, and the Gradle wrapper, Apache-2.0, which an Android export writes into its Gradle
project and which is not part of the game).

## Platform settings

What an export needs besides the game itself (an icon, the Android version code, a Mac app category, a signing key...)
is set in two places:

- **`factoria.json`** (committed with the game): a top-level `icon` and an `export` object with one object per
  platform. Everything is optional and every field has a default; the file is documented field by field in
  `schemas/project.schema.json` (`factoria api --schema project` prints it; its descriptions are the reference for AIs).
  The editor's Platform settings window edits exactly these keys.
- **`~/.factoria/export.json`** (this computer only, never in a project): where the Android SDK and JDK are, and the
  keystore passwords.

Until a platform's export reads a field, setting it changes nothing in that export; `factoria validate` already checks all of
them and the C++ API (`fa/tooling/export_settings.h`, `fa/tooling/icons.h`) reads, writes and applies them.

### Icon

One square image, `"icon": "assets/icon.png"` (project-relative path, forward slashes, inside the project; PNG or JPG;
1024x1024 recommended, at least 512x512). Each platform's export generates what that platform needs from it: the `.icns`
of a macOS app (16 to 1024 px and the @2x sizes), the icon resource of the Windows exe (16 to 256 px), the launcher icons
of Android (mipmaps from 48 to 192 px, a round variant and the adaptive icon), the App Store icon of iOS (1024x1024 with
no transparency) and the PNG of a Linux build. `export.<platform>.icon` replaces it for one platform. No icon at all
means the platform's default icon (and a warning from the export).

A smaller or non-square image is accepted with a warning (`factoria validate` shows it); a non-square one is centered on a
transparent square of its longer side. Scaling averages the pixels (premultiplied by alpha, so transparent edges do not
darken) when it shrinks the image, and is bilinear when it enlarges it.

### `export.<platform>`

```json
{
  "icon": "assets/icon.png",
  "export": {
    "macos":   { "category": "public.app-category.games", "minimumSystemVersion": "11.0", "copyright": "Copyright 2026 My Studio" },
    "linux":   { "categories": ["Game", "ArcadeGame"] },
    "android": { "format": "aab", "minSdk": 26, "targetSdk": 36, "versionCode": 10203,
                 "adaptiveIcon": { "foreground": "assets/icon_fg.png", "background": "#202020" },
                 "permissions": ["android.permission.VIBRATE"],
                 "signing": { "keystore": "keys/upload.keystore", "alias": "upload" } },
    "ios":     { "iconBackground": "#FFFFFF", "teamId": "ABCDE12345", "buildNumber": "7" }
  }
}
```

| Platform | Field | Default | Meaning |
|---|---|---|---|
| all | `icon` | the project's `icon` | Icon of this platform only. |
| macOS | `category` | `public.app-category.games` | `LSApplicationCategoryType` of `Info.plist`. |
| macOS | `minimumSystemVersion` | `11.0` | `LSMinimumSystemVersion`; `major.minor`, 11.0 or newer (the player needs it). |
| macOS | `copyright` | none | `NSHumanReadableCopyright`. |
| Linux | `categories` | `["Game"]` | `Categories=` of the `.desktop` file (the entries are joined with `;`). |
| Android | `format` | `apk` | `apk`, `aab` (Google Play bundle) or `gradle` (only the Gradle project). |
| Android | `adaptiveIcon.foreground` | the icon scaled into the safe zone | A 108dp layer (432x432 px recommended): only the inner 66dp circle always stays visible. The default shrinks the icon to 66/108 of the layer over transparency. |
| Android | `adaptiveIcon.background` | `#FFFFFF` | `"#RRGGBB"`, or the path of an image that fills the layer. |
| Android | `adaptiveIcon.monochrome` | none | Single-colour PNG with transparency; Android 13 tints it for themed icons. |
| Android | `versionCode` | from `version`: `1.2.3` is `10203` | Whole number that grows with every Google Play upload. |
| Android | `minSdk` / `targetSdk` | `26` / `36` | API levels; `26 <= minSdk <= targetSdk`. |
| Android | `permissions` | none | Extra `<uses-permission>` names such as `android.permission.VIBRATE`. |
| Android | `signing.keystore` / `signing.alias` | none | Release signing key: the keystore file (project-relative or absolute; keystores are better kept outside the repository) and the key's alias. The passwords are never in the project (below). |
| iOS | `iconBackground` | `#FFFFFF` | The App Store icon cannot be transparent: transparent pixels take this colour, and the PNG is written without an alpha channel. |
| iOS | `teamId` | none (`FA_IOS_DEVELOPMENT_TEAM`) | 10-character Apple Team ID for device builds. |
| iOS | `buildNumber` | the project's `version` | `CFBundleVersion`: up to three whole numbers separated by dots. |

`windows` only has `icon`. Wrong types or values are errors that name the JSON pointer and the fix
(`factoria.json#/export/android/minSdk: minSdk (34) is higher than targetSdk (30) ...`). An unknown key inside
`export` or a platform object is only a warning, with a "did you mean" (`categroy` -> `category`), because a newer engine
may know keys an older one does not. `fa::save_export_settings` patches the text of `icon` and `export` in
`factoria.json` and nothing else: every other key, the key order, the indentation, the array style and the line
endings stay as they are, fields equal to their default are removed, and a save with no change does not touch the file.

### Machine settings: `~/.factoria/export.json`

`%USERPROFILE%\.factoria\export.json` on Windows; `FACTORIA_EXPORT_CONFIG` names another file. Keys this version does not
know are kept when the file is saved.

```json
{
  "format": "factoria.export-config/1",
  "android": { "sdk": "/Users/me/Library/Android/sdk", "jdk": "/path/to/jdk", "keystorePassword": "...", "keyPassword": "..." }
}
```

| Key | Meaning |
|---|---|
| `android.sdk` | Folder of the Android SDK. Empty = look for it (below). `~/` is the home folder. |
| `android.jdk` | Folder of a JDK 17 or newer (the one that contains `bin/java` and `release`). Empty = look for it. |
| `android.keystorePassword` | Password of the keystore. `FACTORIA_ANDROID_KEYSTORE_PASSWORD` wins over it. |
| `android.keyPassword` | Password of the signing key. `FACTORIA_ANDROID_KEY_PASSWORD` wins over it; when neither is set the keystore password is used. |

The file is written with owner-only permissions on macOS and Linux because it can hold passwords (loading it warns when
other users can read it). Passwords never go in `factoria.json` or in the files of an export.

### Finding the Android toolchain

`fa::find_android_toolchain` (it only looks at folders; it starts no process) picks, in order, the first folder that
qualifies:

| | Order | A folder qualifies when |
|---|---|---|
| JDK | `android.jdk`, `JAVA_HOME`, Android Studio's bundled JDK (macOS `/Applications/Android Studio.app/Contents/jbr/Contents/Home`, Windows `%ProgramFiles%\Android\Android Studio\jbr`, Linux `/opt/android-studio/jbr`, `~/android-studio/jbr`), then Unity Hub's Android JDK (`.../Unity/Hub/Editor/<newest version first>/.../AndroidPlayer/OpenJDK`) | it has `bin/java` and `bin/javac`, and its `release` file says Java 17 or newer (`JAVA_VERSION="17.0.9"`) |
| SDK | `android.sdk`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, the usual folder (macOS `~/Library/Android/sdk`, Windows `%LOCALAPPDATA%\Android\Sdk`, Linux `~/Android/Sdk`), then Unity Hub's `AndroidPlayer/SDK` | it has `platform-tools/`, `platforms/` or `licenses/` |

A folder you named (in the file or an environment variable) that does not qualify is skipped with a warning when a later
one does, and is reported as the problem when none does. A missing JDK or SDK is a *problem* that says what to install
(Android Studio, or a JDK 17+ from adoptium.net, or the command-line tools) and where to set the folder (Platform settings >
Android in the editor, `~/.factoria/export.json`, or the environment variable). An SDK without accepted licenses
(`licenses/android-sdk-license`) only gets a warning: Gradle cannot download a missing SDK platform until you run
`sdkmanager --licenses`.

## Desktop (Linux, Windows, macOS)

The `factoria_player` binary is copied next to the game. By default it is taken
from the folder of the running `factoria` binary (or the build tree layout
`<build>/player/`). Exporting for another OS than the one you run on needs a
player built there: pass `--player path/to/factoria_player[.exe]`.

```
linux/windows:  my-game-linux/
                  my-game            (my-game.exe on Windows)
                  FACTORIA_NOTICES.txt
                  game/              factoria.json, scenes/, scripts/, assets/ ...
macOS:          my-game-macos/My Game.app/Contents/
                  Info.plist  MacOS/my-game  Resources/game/...  Resources/FACTORIA_NOTICES.txt
```

The player starts the game found in `game/` next to the executable (inside the
`.app`: `Contents/Resources/game`). Command line:

```
my-game [projectDir] [--scene scenes/level2.scene.json] [--fullscreen]
```

Save games go to the OS per-user data folder (`~/.local/share/<id>`,
`%APPDATA%\<id>`, `~/Library/Application Support/<id>`).

On macOS the export signs the finished `.app` ad hoc (`codesign --force --sign -`), last, so the signature covers its
`Info.plist` and the game files. The player of a signed release carries FactorIA's Developer ID signature, which covers
the executable alone: copied into a bundle unchanged it fails `codesign --verify` ("code has no resources but signature
indicates they must be present"), and a Mac that downloads such an app calls it damaged. The ad hoc app runs on your
Mac; a copy someone else downloads is stopped by Gatekeeper like any app that is not notarized (with Open Anyway).
Exporting for macOS on Windows or Linux cannot sign: the report warns, and `codesign --force --sign -` on a Mac fixes
it. To distribute the game, sign it with your own Developer ID and notarize it (Apple Developer Program):

```
codesign --force --deep --options runtime --timestamp --sign "Developer ID Application: ..." "My Game.app"
ditto -c -k --keepParent "My Game.app" my-game.zip
xcrun notarytool submit my-game.zip --keychain-profile <profile> --wait
xcrun stapler staple "My Game.app"
```

`--force` replaces the ad hoc signature; `xcrun notarytool store-credentials <profile>` saves your Apple ID, team ID and
app-specific password once. Zip the stapled app again to share it. The player of the macOS download is universal
(Apple Silicon and Intel).
Windows: the exported exe is a copy of `factoria_player.exe`. From a release download it carries FactorIA's signature
once the release is signed ([BUILDING.md](BUILDING.md), "Releasing"), and from a build from source it is not signed.
SmartScreen may still warn, and shows FactorIA's name as the publisher; sign the exe with `signtool` to publish under
your own.

## Mobile exports: prebuilt or source

Android and iOS exports need the engine's runtime for the phone. It does not depend on the game (the game travels as
files inside the APK / app), so the FactorIA download carries it ready-made, next to the `factoria` executable:

```
FactorIA/
  factoria  factoria_player
  mobile/
    android/jniLibs/arm64-v8a/libfactoria_player.so     in every package (Windows, macOS, Linux)
    android/jniLibs/x86_64/libfactoria_player.so
    ios/iphoneos/*.a                                     in the macOS package only
    ios/iphonesimulator/*.a                              arm64 + x86_64
```

The Android/iOS project templates are built into the `factoria` binary, like the docs and game templates. Every Android
and iOS export therefore runs in one of two **modes**, reported as `mode` in the export report (`--json`, `project.export`)
and in the CLI output (`Exported android build to ... (22 files, mode: prebuilt)`):

| mode | The engine runtime is | Needs |
|---|---|---|
| `prebuilt` | the ready-made `mobile/` libraries of the download, copied into the project | Android: JDK 17 and the Android SDK only (no NDK, no CMake). iOS: Xcode and CMake 3.24+ (no engine source) |
| `source` | compiled from an engine source checkout, with that checkout's templates | the checkout and, on Android, NDK r27+ and CMake 3.31 (engine developers) |

**The rule**, in order (the first that applies wins):

1. `--engine-root DIR` was given, or `$FACTORIA_ENGINE_DIR` is set (and no `--mobile-dir` was given): **source**, from that
   checkout. A path that is not an engine checkout is an error, not a silent fallback.
2. `--mobile-dir DIR` was given, or the `mobile/` folder next to the `factoria` executable holds the players (Android: a
   `libfactoria_player.so` for both `arm64-v8a` and `x86_64`; iOS: `libfactoria_player_main.a` in both `iphoneos` and `iphonesimulator`): **prebuilt**.
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
  app/src/main/AndroidManifest.xml NativeActivity + android.app.lib_name=factoria_player, orientation, icon, permissions
  app/src/main/res/values/strings.xml   app name
  app/src/main/res/mipmap-*/       launcher icons made from the project's icon (and the adaptive icon)
  app/src/main/assets/             the game + assets_index.txt
  app/src/main/jniLibs/<abi>/libfactoria_player.so   prebuilt mode only: the engine
```

`assets_index.txt` lists every game file (one project-relative path per line).
The engine needs it because Android cannot enumerate folders inside an APK.

**Formats** (`--format`, or `export.android.format` in `factoria.json`; the flag wins):

| format | Runs | Result |
|---|---|---|
| `apk` (default) | `./gradlew assembleDebug` (`assembleRelease` with `--release`) | `<slug>-debug.apk` (`<slug>.apk`): an app you install with `adb install -r` |
| `aab` | `./gradlew bundleDebug` (`bundleRelease`) | `<slug>-debug.aab` (`<slug>.aab`): the Android App Bundle Google Play takes |
| `gradle` | nothing | only the project; no JDK or SDK is needed. Build it yourself (`./gradlew assembleDebug`) or open it in Android Studio |

**What the build needs**: a JDK 17+ and the Android SDK (found as in [Finding the Android toolchain](#finding-the-android-toolchain);
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
needs NDK r27+ and CMake 3.31 in the SDK (`sdkmanager "ndk;27.2.12479018" "cmake;3.31.6"`).

The engine's libraries are linked for 16 KB memory pages (Google Play requires it for apps that target Android 15+), and the
APK is zip-aligned for them.

**Platform settings** that change the project: `minSdk` / `targetSdk` (`compileSdk` follows `targetSdk`), `versionCode`,
`permissions` (extra `<uses-permission>` lines), the `icon` (launcher icons and adaptive icon, in the manifest as `icon` and
`roundIcon`; without one the platform default and a warning) and `signing`. See [Platform settings](#platform-settings).

**Signing**. A debug build is signed with the debug key of the machine (fine for trying the app). `--release` signs with the
keystore of `export.android.signing` (`keystore`, `alias`; a project-relative path is resolved against the project and the
file is never copied into the app). The passwords are never written to a project, a file of the export or a command line:
they come from `FACTORIA_ANDROID_KEYSTORE_PASSWORD` and `FACTORIA_ANDROID_KEY_PASSWORD` (or `android.keystorePassword` /
`keyPassword` of `~/.factoria/export.json`; the key password defaults to the keystore password) and are given to the Gradle
process as environment variables only. `plan_export` and `--release` check that the keystore exists and that the passwords
are set before Gradle starts. A release build with no keystore configured uses the debug key and says so in a warning; Google
Play does not accept that. To make a key: `keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000`
(keep the file and its passwords safe). A release build you run by hand in the exported project (`./gradlew assembleRelease`)
reads the same environment variables.

```bash
factoria export --platform android --format aab --release
adb install -r my-game/build/export/my-game-android/my-game-debug.apk   # the apk format
```

Prerequisites, signing and troubleshooting: [MOBILE.md](MOBILE.md).

### iOS

`factoria export --platform ios` (macOS with Xcode only for the next step) writes the game and a `build_ios.sh`. The
script runs CMake with the Xcode generator and the same settings as the `ios` preset, adding
`-DFA_GAME_PROJECT_DIR=game -DFA_GAME_BUNDLE_ID=... -DFA_GAME_NAME=... -DFA_GAME_VERSION=... -DFA_GAME_ORIENTATION=...`:

```bash
./build_ios.sh --simulator --run                         # build, start in the iOS Simulator, console in the terminal
FA_IOS_DEVELOPMENT_TEAM=ABCDE12345 ./build_ios.sh --run  # the same on the connected iPhone or iPad
./build_ios.sh --simulator --build -- <xcodebuild args>  # only build; everything after -- goes to xcodebuild
./build_ios.sh --simulator     # or without flag for a device; opens build/FactorIA.xcodeproj
```

A device build registers the connected device with the team on the first build (Developer Mode must be on); see
[MOBILE.md](MOBILE.md#ios).

```
my-game-ios/                        prebuilt mode (the download for macOS)
  build_ios.sh  game/
  CMakeLists.txt  cmake/            a small project: Info.plist template, the game-copy script
  lib/iphoneos/*.a  lib/iphonesimulator/*.a   the engine and player as static libraries
```

In **prebuilt** mode the script configures `CMakeLists.txt` of the folder itself and links the app from `lib/`: no engine
source is needed. The libraries are static archives (not an XCFramework: the exported project picks the archives of the
SDK it is configured for, device or simulator, like the `ios` presets do, and CMake 3.24 cannot link XCFrameworks). In
**source** mode the folder holds only `game/` and `build_ios.sh`, and the script runs CMake on the engine checkout.
The iOS libraries ship in the macOS download only, so export for iOS on a Mac.

Details in [MOBILE.md](MOBILE.md).

## Tips

- Run `factoria validate` first; export only checks what packaging needs.
- Add the platform to `"platforms"` in `factoria.json` or export prints a warning.
- Orientation comes from `display.orientation` (`landscape`, `portrait`, `any`).
- Version `1.2.3` becomes Android `versionCode` 10203 and iOS `CFBundleVersion` 1.2.3.
