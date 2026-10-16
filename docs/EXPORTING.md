# Exporting a game

`factoria export` turns a game project into something you can ship. The same
function is available to tools as `fa::export_project` (`fa/tooling/export.h`).

```bash
factoria export [project] --platform <linux|windows|macos|android|ios> [--out DIR] [--release] [--player PATH]
                [--engine-root DIR | --mobile-dir DIR]
```

Before anything is written the project is validated: `factoria.json` must exist,
`name` must be set, `mainScene` must exist and `id` must be a reverse-DNS
identifier (required for Android and iOS: `com.example.spacedodge`, letters,
digits and underscores, every part starting with a letter; Java keywords such
as `new` are rejected for Android). Errors name the file, the JSON pointer and
the fix.

The result goes to `<out>/<game-slug>-<platform>/` (default `--out`:
`<project>/build/export`). That folder is deleted and recreated on every
export. `--json` prints the report: `outputDir`, `mode` (Android and iOS only, see [Mobile exports](#mobile-exports-prebuilt-or-source)),
`notices` (see [License notices](#license-notices)), `files`, `nextSteps`, `warnings`.

## From an AI: `project.export`

The same export is the command `project.export` (MCP tool `project_export`, also `factoria call project.export`, the
editor console and `fa.call` in scripts), so an AI connected over MCP can build a Windows folder or the Android
Gradle project without a shell. Arguments are all optional: `platform` (default: this machine), `out` (parent folder,
relative to the project and inside it like the `fs.*` commands, default `build/export`) and `release`. It returns the report
(`outputDir`, `mode`, `notices`, `files`, `nextSteps`, `warnings`); an unknown platform or a failed validation is an error with a hint.
`--player`, `--engine-root` and `--mobile-dir` are CLI-only: the command uses the `factoria_player` and the `mobile/`
folder next to the running binary, or `$FACTORIA_ENGINE_DIR` when it is set.

```
project_export {"platform":"windows","release":true}
```

## What is shipped (and what is not)

Everything in the project except: `.factoria/`, every dot-file or dot-folder
(`.git`, `.mcp.json`, `.gitignore`), `build/` (earlier exports), `tests/`, `tools/`, `types/`,
`node_modules/`, `ENGINE_FEEDBACK.json` (the file named by `feedbackFile`),
`AGENTS.md`, `CLAUDE.md`, `jsconfig.json`, and the output folder itself. Your
project is never modified; the feedback file stays in the repository.

The export adds one file of its own, `FACTORIA_NOTICES.txt` (next section).

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
contain (Dear ImGui, in the editor).

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

macOS distribution outside your own machine needs signing and notarization:
`codesign --force --deep --options runtime --sign "Developer ID Application: ..." "My Game.app"`
(`--force`: the player may already carry FactorIA's signature),
then `xcrun notarytool submit` (needs an Apple developer account). The player of the macOS download is universal
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

`factoria export --platform android` writes a complete Gradle project:

```
my-game-android/
  settings.gradle  build.gradle  gradle.properties  gradle/wrapper/gradle-wrapper.properties
  app/build.gradle                 applicationId, versionName/Code, abiFilters (prebuilt: no native build)
  app/src/main/AndroidManifest.xml NativeActivity + android.app.lib_name=factoria_player, orientation
  app/src/main/res/values/strings.xml   app name
  app/src/main/assets/             the game + assets_index.txt
  app/src/main/jniLibs/<abi>/libfactoria_player.so   prebuilt mode only: the engine
```

`assets_index.txt` lists every game file (one project-relative path per line).
The engine needs it because Android cannot enumerate folders inside an APK.

**Prebuilt** (the download): `app/build.gradle` has no `externalNativeBuild`, `ndkVersion` or engine path; Gradle only
packages `jniLibs` (`arm64-v8a` and `x86_64`, both required) and the assets, so the build takes about a minute and
needs the Android SDK alone.

**Source**: Gradle compiles the engine through CMake from the engine checkout (`factoria.engineDir` in `gradle.properties`,
default: the checkout the export used; override with `FACTORIA_ENGINE_DIR`), which takes several minutes the first time.

Build, in both modes:

```bash
cd my-game-android
gradle wrapper --gradle-version 8.7      # once, needs Gradle installed (Android Studio does it for you)
./gradlew assembleDebug                  # app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
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
