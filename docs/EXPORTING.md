# Exporting a game

`factoria export` turns a game project into something you can ship. The same
function is available to tools as `fa::export_project` (`fa/tooling/export.h`).

```bash
factoria export [project] --platform <linux|windows|macos|android|ios> [--out DIR] [--release] [--player PATH]
```

Before anything is written the project is validated: `factoria.json` must exist,
`name` must be set, `mainScene` must exist and `id` must be a reverse-DNS
identifier (required for Android and iOS: `com.example.spacedodge`, letters,
digits and underscores, every part starting with a letter; Java keywords such
as `new` are rejected for Android). Errors name the file, the JSON pointer and
the fix.

The result goes to `<out>/<game-slug>-<platform>/` (default `--out`:
`<project>/build/export`). That folder is deleted and recreated on every
export. `--json` prints the report: `outputDir`, `files`, `nextSteps`, `warnings`.

## From an AI: `project.export`

The same export is the command `project.export` (MCP tool `project_export`, also `factoria call project.export`, the
editor console and `fa.call` in scripts), so an AI connected over MCP can build a Windows folder or the Android
Gradle project without a shell. Arguments are all optional: `platform` (default: this machine), `out` (parent folder;
a relative path is relative to the project folder, default `build/export`) and `release`. It returns the report
(`outputDir`, `files`, `nextSteps`, `warnings`); an unknown platform or a failed validation is an error with a hint.
`--player` and `--engine-root` are CLI-only: the command uses the `factoria_player` next to the running binary and
`$FACTORIA_ENGINE_DIR`.

```
project_export {"platform":"windows","release":true}
```

## What is shipped (and what is not)

Everything in the project except: `.factoria/`, every dot-file or dot-folder
(`.git`, `.mcp.json`, `.gitignore`), `tests/`, `tools/`, `types/`,
`node_modules/`, `ENGINE_FEEDBACK.json` (the file named by `feedbackFile`),
`AGENTS.md`, `CLAUDE.md`, `jsconfig.json`, and the output folder itself. Your
project is never modified; the feedback file stays in the repository.

## Desktop (Linux, Windows, macOS)

The `factoria_player` binary is copied next to the game. By default it is taken
from the folder of the running `factoria` binary (or the build tree layout
`<build>/player/`). Exporting for another OS than the one you run on needs a
player built there: pass `--player path/to/factoria_player[.exe]`.

```
linux/windows:  my-game-linux/
                  my-game            (my-game.exe on Windows)
                  game/              factoria.json, scenes/, scripts/, assets/ ...
macOS:          my-game-macos/My Game.app/Contents/
                  Info.plist  MacOS/my-game  Resources/game/...
```

The player starts the game found in `game/` next to the executable (inside the
`.app`: `Contents/Resources/game`). Command line:

```
my-game [projectDir] [--scene scenes/level2.scene.json] [--fullscreen]
```

Save games go to the OS per-user data folder (`~/.local/share/<id>`,
`%APPDATA%\<id>`, `~/Library/Application Support/<id>`).

macOS distribution outside your own machine needs signing and notarization:
`codesign --deep --options runtime --sign "Developer ID Application: ..." "My Game.app"`,
then `xcrun notarytool submit` (needs an Apple developer account).
Windows: the executable is not signed; SmartScreen may warn unless you sign it
with `signtool`.

## Android

`factoria export --platform android` writes a complete Gradle project built from
`platforms/android` of the engine checkout:

```
my-game-android/
  settings.gradle  build.gradle  gradle.properties  gradle/wrapper/gradle-wrapper.properties
  app/build.gradle                 applicationId, versionName/Code, abiFilters, CMake arguments
  app/src/main/AndroidManifest.xml NativeActivity + android.app.lib_name=factoria_player, orientation
  app/src/main/res/values/strings.xml   app name
  app/src/main/assets/             the game + assets_index.txt
```

`assets_index.txt` lists every game file (one project-relative path per line).
The engine needs it because Android cannot enumerate folders inside an APK.

The engine itself is compiled by Gradle through CMake from the engine checkout
(`factoria.engineDir` in `gradle.properties`, default: the checkout `factoria`
was built from; override with `FACTORIA_ENGINE_DIR`). Build:

```bash
cd my-game-android
gradle wrapper --gradle-version 8.7      # once, needs Gradle installed (Android Studio does it for you)
./gradlew assembleDebug                  # app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Prerequisites, signing and troubleshooting: [MOBILE.md](MOBILE.md).

## iOS

`factoria export --platform ios` (macOS with Xcode only for the next step)
writes `my-game-ios/game/` and `build_ios.sh`. The script runs CMake with the
Xcode generator and the same settings as the `ios` preset, adding
`-DFA_GAME_PROJECT_DIR=game -DFA_GAME_BUNDLE_ID=... -DFA_GAME_NAME=... -DFA_GAME_VERSION=... -DFA_GAME_ORIENTATION=...`:

```bash
./build_ios.sh --simulator     # or without flag for a device; opens build/FactorIA.xcodeproj
FA_IOS_DEVELOPMENT_TEAM=ABCDE12345 ./build_ios.sh --build
```

Details in [MOBILE.md](MOBILE.md).

## Tips

- Run `factoria validate` first; export only checks what packaging needs.
- Add the platform to `"platforms"` in `factoria.json` or export prints a warning.
- Orientation comes from `display.orientation` (`landscape`, `portrait`, `any`).
- Version `1.2.3` becomes Android `versionCode` 10203 and iOS `CFBundleVersion` 1.2.3.
