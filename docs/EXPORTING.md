# Exporting a game

`factoria export` turns a game project into something you can ship. The same
function is available to tools as `fa::export_project` (`fa/tooling/export.h`), to AIs as the command
`project.export`, and in the editor as the **Export** button ([From the editor](#from-the-editor)).

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
`dryRun: true` runs every check of the export and writes nothing: it returns `platform`, `outputDir` (the folder an
export would replace), `mode` (Android, iOS), `player` (desktop) and `warnings`, or the error the export would give
(`fa::plan_export` in C++). `--player`, `--engine-root` and `--mobile-dir` are CLI-only: the command uses the `factoria_player` and the `mobile/`
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

## Setting up this computer

An export needs things that are not part of FactorIA: a JDK and the Android SDK for an APK or AAB, the `factoria_player`
of the other operating systems, CMake and Xcode for iOS. FactorIA installs what it can instead of only telling you what to
install:

```bash
factoria setup                                     # what this computer has and what is missing (writes and downloads nothing)
factoria setup android                             # JDK 21 + Android SDK; shows the Android SDK license and asks first
factoria setup android --accept-licenses           # you have read the license and accept it (scripts)
factoria setup players                             # the players of the other desktop OSes + the Android/iOS libraries, for this version
factoria setup players --platforms windows,linux   # only these (windows, linux, macos, mobile)
factoria setup cmake                               # CMake 3.31 for the iOS export, unless a CMake 3.24+ is found
factoria setup xcode                               # macOS: checks Xcode, opens its App Store page when it is missing
```

| Component | What it installs | Download | The export that needs it |
|---|---|---|---|
| `android` | Eclipse Temurin JDK 21, the Android command-line tools, `platform-tools`, `platforms;android-36`, `build-tools;35.0.0`, the SDK licenses | about 600 MB (1.1 GB on disk) | `--platform android` (APK/AAB through Gradle) |
| `players` | `factoria_player` of every desktop OS but this one, and `mobile/` (Android libraries; also iOS on a Mac), from the GitHub release of this factoria's version | about 60 MB | `--platform windows\|linux\|macos` for another OS; Android and iOS without the engine source |
| `cmake` | CMake 3.31 from Kitware, only when no CMake 3.24+ is found (`--force` installs it anyway) | about 75 MB | `--platform ios` (`build_ios.sh`) |
| `xcode` | nothing: Xcode comes from the App Store and needs your Apple ID and password, so this only checks it, opens its page and lists the steps | - | `--platform ios` |

Everything lands under `$FACTORIA_HOME` (default `~/.factoria`, `%USERPROFILE%\.factoria` on Windows):

```
~/.factoria/
  android/jdk/          Eclipse Temurin 21
  android/sdk/          cmdline-tools/latest, platform-tools, platforms/android-36, build-tools/35.0.0, licenses/
  android/user/         what Google's command-line tools keep for themselves ($ANDROID_USER_HOME, about 250 MB)
  players/<version>/    windows/factoria_player.exe, linux/factoria_player, macos/factoria_player, mobile/
  tools/cmake/          CMake (CMake.app on macOS)
  export.json           machine settings: learns where the JDK and the SDK are (below)
```

Nothing else on the computer changes: no `sudo`, no `PATH`, no registry. A JDK or SDK that is found already (`android.jdk`,
`JAVA_HOME`, `ANDROID_HOME`, Android Studio's) is used and only completed with what is missing, never replaced; Unity Hub's
belongs to Unity and is never touched (FactorIA sets up its own next to it). Only what was installed here is written to
`export.json`. Running a setup again is safe: it skips what is there and says so.

**The Android SDK license** is a legal agreement between you and Google. In a terminal `factoria setup android` prints the
text and asks `[y/N]`; without a terminal it refuses (code `license_required`) until `--accept-licenses` says you have read
it (`factoria setup --json` prints the text). The refusal comes before anything is downloaded. The newest command-line tools
(revision 23) are a front for Google's "Android CLI": it records the agreement while it installs the first package,
unpacks itself into `android/user` (about 250 MB), shows Google's terms and sends Google usage statistics under Google's
privacy policy. `sdkmanager` has no switch for that (the `android` program next to it has `--no-metrics`).

**What is trusted.** Downloads come only from `api.adoptium.net` and `github.com/adoptium` (JDK), `dl.google.com` (SDK),
`api.github.com` and `github.com/OxtailGames/FactorIA/releases` (players) and `github.com/Kitware/CMake` (CMake); a listing
that points anywhere else is refused. Every file is checked against the checksum its publisher lists (SHA-256 from Adoptium,
GitHub and Kitware, SHA-1 from Google's package list) before it is unpacked, and a mismatch (code `checksum_mismatch`)
installs nothing. Archives are unpacked next to their destination and moved into place only when complete, so an
interrupted install never looks installed. The programs used are `curl` (macOS, Windows 10+ and most Linux have it;
`HTTPS_PROXY` is honored), `tar` (macOS, Windows) and `tar` or `unzip` (Linux).

**`players` needs a release.** It downloads the packages of release `v<version>` of `OxtailGames/FactorIA`, the version that
`factoria version` prints. A development build ahead of the last release fails with code `no_release` and names the newest
release; build the player on the other OS (BUILDING.md) and pass it with `--player`, or use a downloaded factoria. A
player has to match the factoria that copies it into a game, which is why the folder carries the version.

**The export uses what was installed.** `--player` and `--mobile-dir` still win; then the `mobile/` folder next to
`factoria`; then `players/<version>/` of the FactorIA home (`fa::installed_player`, `fa::installed_mobile_dir`). The Android
toolchain is read from `export.json` (below) and CMake is `fa::find_cmake`: `PATH`, Homebrew, `/Applications/CMake.app`, then
`tools/cmake`.

**From an AI.** The commands `setup.status` (read-only) and `setup.install` (MCP tools `setup_status`, `setup_install`) do
the same. `setup.status {"component":"android"}` returns each component's `state` (`installed`, `missing`, `partial`,
`unsupported`), `problems[]`, `installSizeMb` and, while the Android license is not accepted, `licenses[]` with its full
text. `setup.install {"component":"android","acceptLicenses":true}` installs and returns the `steps[]` (each `installed`,
`skipped` or `guidance`), `paths`, `nextSteps` and `warnings`; errors carry a `code` (`license_required`, `checksum_mismatch`,
`network`, `no_release`, `cancelled`, `unsupported`, `invalid_argument`, `failed`) and the steps done before the failure. An
install downloads hundreds of megabytes: ask the user first, and set `acceptLicenses` only after the user has read the
license text and said yes, never on your own. C++: `fa/tooling/setup.h` (`fa::setup_status`, `fa::setup_install`); the
editor's Export window builds its buttons on it.

Tests: `FACTORIA_SETUP_ONLINE_TESTS=1 ctest -R tooling` also reads the real Google, Adoptium and GitHub listings (a few
hundred KB, nothing is installed) to catch a changed format.

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

`%USERPROFILE%\.factoria\export.json` on Windows; `FACTORIA_HOME` moves it into that folder (`$FACTORIA_HOME/export.json`,
where `factoria setup` installs too) and `FACTORIA_EXPORT_CONFIG` names another file, winning over both. Keys this version
does not know are kept when the file is saved. `factoria setup android` fills in `android.jdk` and `android.sdk` for what it installs.

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
| JDK | `android.jdk`, `JAVA_HOME`, the JDK of `factoria setup android` (`<FactorIA home>/android/jdk`), Android Studio's bundled JDK (macOS `/Applications/Android Studio.app/Contents/jbr/Contents/Home`, Windows `%ProgramFiles%\Android\Android Studio\jbr`, Linux `/opt/android-studio/jbr`, `~/android-studio/jbr`), then Unity Hub's Android JDK (`.../Unity/Hub/Editor/<newest version first>/.../AndroidPlayer/OpenJDK`) | it has `bin/java` and `bin/javac`, and its `release` file says Java 17 or newer (`JAVA_VERSION="17.0.9"`) |
| SDK | `android.sdk`, `ANDROID_HOME`, `ANDROID_SDK_ROOT`, the SDK of `factoria setup android` (`<FactorIA home>/android/sdk`), the usual folder (macOS `~/Library/Android/sdk`, Windows `%LOCALAPPDATA%\Android\Sdk`, Linux `~/Android/Sdk`), then Unity Hub's `AndroidPlayer/SDK` | it has `platform-tools/`, `platforms/` or `licenses/` |

A folder you named (in the file or an environment variable) that does not qualify is skipped with a warning when a later
one does, and is reported as the problem when none does. A missing JDK or SDK is a *problem* that says what to run
(`factoria setup android` installs both; otherwise Android Studio, or a JDK 17+ from adoptium.net, or the command-line tools) and where to set the folder (Platform settings >
Android in the editor, `~/.factoria/export.json`, or the environment variable). An SDK without accepted licenses
(`licenses/android-sdk-license`) only gets a warning: Gradle cannot download a missing SDK platform until you run
`sdkmanager --licenses`.

## Desktop (Linux, Windows, macOS)

The `factoria_player` binary is copied next to the game. By default it is taken
from the folder of the running `factoria` binary (or the build tree layout
`<build>/player/`). Exporting for another OS than the one you run on needs a
player of that OS: `factoria setup players` downloads the ones of the release ([Setting up this computer](#setting-up-this-computer)),
or pass `--player path/to/factoria_player[.exe]` for one built there.

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
