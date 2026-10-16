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
export, but only when it is empty or an export wrote it: a folder of yours that happens to have that name is never
deleted ([Replacing an earlier export](#replacing-an-earlier-export)). `--json` prints the report: `outputDir`, `mode` (Android and iOS only, see [Mobile exports](#mobile-exports-prebuilt-or-source)),
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
  else, and only a folder an earlier export wrote ([Replacing an earlier export](#replacing-an-earlier-export)): when
  the chosen folder already holds another folder of that name, each platform's row says so and nothing is deleted.
  **Release** makes a release build, as `--release` does (for Android a release APK or AAB, signed with the keystore
  of the Android settings; hover it for what it changes on each platform).
- **Platform settings...** (top of the window, also File > Platform Settings...) and the **Settings...** button of each
  row open the [Platform settings window](EDITOR.md#platform-settings): the icon and the fields of
  [Platform settings](#platform-settings) below, with Save / Revert, previews of the icons, a Create keystore... button for
  the Android signing key and the JDK / SDK folders of this computer. It edits `factoria.json` (and
  `~/.factoria/export.json`) through the same code `factoria validate` and the export read them with.
- **Android format**: the Android row's **Format** menu picks `apk`, `aab` or `gradle` (`export.android.format`) and saves
  it in `factoria.json` at once, without waiting for Save in the settings window.
- **Set up buttons**: a row that cannot run because this computer lacks something FactorIA installs shows the button that
  installs it (**Install Android build tools**, **Download Windows player**, **Download mobile libraries**, **Install CMake**,
  **Open App Store (Xcode)**): the editor's front for [`factoria setup`](#setting-up-this-computer).
- **Each platform's row** says what an export there writes (hover **Ready** for the folder and the player), or why it
  cannot run here, with the error and hint `factoria export` would print: a desktop player missing for another OS, no
  prebuilt mobile players and no engine checkout, a missing reverse-DNS `id` for Android and iOS... Its button stays
  disabled until that is fixed; the rows are checked again every few seconds (`fa::plan_export`, which writes nothing).
  For another OS's desktop export, **Choose player...** picks the `factoria_player` built there (the one next to
  `factoria` in the FactorIA download for that OS), like `--player`.
- **While it runs** (in the background; the editor keeps working) the window shows the export's current step, the
  build output as it scrolls by and a **Cancel** button (it stops the running build; the export reports that it was
  cancelled).
- **The report** shows under the buttons when the export finishes: the output folder with **Show in Finder** /
  **Copy path**, the format and, when the export made one file (an APK or an AAB), the **artifact** with its own
  **Show in Finder** (selects the file) and **Copy file path**, the mode, the warnings and the numbered **next steps**,
  or the error and how to fix it. **Copy report** copies it as text. A `gradle` Android export and an iOS export are
  projects, not finished apps: the next steps say how to build them (Gradle, `build_ios.sh` / Xcode on a Mac).

The export packages the files on disk: when the scene has unsaved changes the window says so and offers **Save scene**.

## What is shipped (and what is not)

Everything in the project except: `.factoria/`, every dot-file or dot-folder
(`.git`, `.mcp.json`, `.gitignore`), `build/` (earlier exports), `tests/`, `tools/`, `types/`,
`node_modules/`, `ENGINE_FEEDBACK.json` (the file named by `feedbackFile`),
`AGENTS.md`, `CLAUDE.md`, `jsconfig.json`, the folder of a native plugin that lives inside the project (its build is
shipped instead, below), and the output folder itself. Your project is never modified; the feedback file stays in the
repository.

The export adds two files of its own: `.factoria-export` at the top of the export folder (next section) and
`FACTORIA_NOTICES.txt` ([License notices](#license-notices)). An Android export also leaves out the keystore named by
`export.android.signing` when it lives inside the project (a warning says to keep it outside the repository): a signing
key must never end up in the assets of an APK.

## Replacing an earlier export

Every export starts by deleting `<out>/<game-slug>-<platform>/` and writing it again, so files you add there do not
survive the next export. So that a folder of yours is never deleted just because it has that name (easy to hit with
`--out` or the editor's **Choose...**), the export replaces a folder only when it:

- holds `.factoria-export`, the short text file every export writes at its top (the game does not need it: leave it
  out of what you ship if you like);
- holds `FACTORIA_NOTICES.txt` where that platform's export puts it (the table in [License notices](#license-notices)),
  which is how exports made before the marker existed are recognized; or
- is empty.

Any other file or folder of that name stops the export before anything is written. The error names the folder and the
hint says how to go on: choose another output folder, or move or delete that folder yourself if nothing in it is
needed. A folder exported by a factoria older than the license notices has neither file: delete it once and export
again; from then on every export replaces it on its own. The check is part of the plan (`fa::plan_export`), so the
editor's Export window shows it on each platform's row and `project_export {"dryRun":true}` returns it as its error.

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
| `android` | Eclipse Temurin JDK 21, the Android command-line tools (revision 22.0, the classic Java `sdkmanager`), `platform-tools`, `platforms;android-36`, `build-tools;35.0.0`, the Android SDK license | about 500 MB (0.9 GB on disk) | `--platform android` (APK/AAB through Gradle) |
| `players` | `factoria_player` of every desktop OS but this one, and `mobile/` (Android libraries; also iOS on a Mac), from the GitHub release of this factoria's version | about 60 MB | `--platform windows\|linux\|macos` for another OS; Android and iOS without the engine source |
| `cmake` | CMake 3.31 from Kitware, only when no CMake 3.24+ is found (`--force` installs it anyway) | about 75 MB | `--platform ios` (`build_ios.sh`) |
| `xcode` | nothing: Xcode comes from the App Store and needs your Apple ID and password, so this only checks it, opens its page and lists the steps | - | `--platform ios` |

Everything lands under `$FACTORIA_HOME` (default `~/.factoria`, `%USERPROFILE%\.factoria` on Windows):

```
~/.factoria/
  android/jdk/          Eclipse Temurin 21
  android/sdk/          cmdline-tools/22.0, platform-tools, platforms/android-36, build-tools/35.0.0, licenses/
  android/user/         what Google's tools keep for themselves ($ANDROID_USER_HOME): about 4 MB (sdkmanager's package-list cache) with the pinned tools, about 250 MB if the fallback below applies
  players/<version>/    windows/factoria_player.exe, linux/factoria_player, macos/factoria_player, mobile/
  tools/cmake/          CMake (CMake.app on macOS)
  export.json           machine settings: learns where the JDK and the SDK are (below)
```

Nothing else on the computer changes: no `sudo`, no `PATH`, no registry. A JDK or SDK that is found already (`android.jdk`,
`JAVA_HOME`, `ANDROID_HOME`, Android Studio's) is used and only completed with what is missing, never replaced; Unity Hub's
belongs to Unity and is never touched (FactorIA sets up its own next to it). Only what was installed here is written to
`export.json`. Running a setup again is safe: it skips what is there and says so.

**From the editor.** File > Set Up This Computer... opens a window with the four components, their state, what is missing
and an **Install** button each, with a progress bar, **Cancel** and a log while it runs and the report (steps, warnings, next
steps) when it finishes. The Export window and the Platform settings tabs show the button that fixes what their row
lacks, in plain words (**Install Android build tools**, **Download Windows player**, **Download mobile libraries**, **Install CMake**,
**Open App Store (Xcode)**). A button calls `fa::setup_install`, the function behind `factoria setup` and `setup.install`, on a
worker thread: nothing is installed any other way. See [the editor](EDITOR.md#setting-up-this-computer).

**The Android SDK license** is a legal agreement between you and Google. In a terminal `factoria setup android` prints the
text and asks `[y/N]`; without a terminal it refuses (code `license_required`) until `--accept-licenses` says you have read
it (`factoria setup --json` prints the text). In the editor, **Install Android build tools** shows the full text in a dialog
whose **I accept** button stays disabled until you tick that you have read it and accept. The refusal comes before anything
is downloaded. After you agree, the install
records exactly that license (`android/sdk/licenses/android-sdk-license`, the line Google's tools write for it) and nothing
else: it does not run `sdkmanager --licenses`, which would also accept every other license Google lists (previews, Google TV,
system images...).

**Which command-line tools.** The install pins revision 22.0 (`kSetupAndroidCmdlineTools` in `fa/tooling/setup.h`), the
newest whose `sdkmanager` is still the classic Java program: `bin/sdkmanager` starts `SdkManagerCli` from `lib/*.jar`, it
fetches only the packages it is asked for and keeps nothing but its package-list cache (about 4 MB) in `android/user`. The
newest revision (23, which Google's list calls `cmdline-tools;latest`) turned `sdkmanager` into a shell script in front of
Google's "Android CLI": it unpacks itself into `android/user` (about 250 MB) on first use, shows Google's terms and sends
Google usage statistics under Google's privacy policy, and `sdkmanager` has no switch for that (the `android` program next to
it has `--no-metrics`). Only when Google's list no longer offers the pinned revision (missing or marked obsolete) does the
install fall back to `cmdline-tools;latest`; it then says so in the `warnings` of its report, and that note, the 250 MB and
the statistics apply. Update FactorIA to get a build that pins a revision that still exists. An SDK you already have (Android
Studio's, `ANDROID_HOME`) keeps the tools it has (`--force` adds the pinned revision next to them, and that one is used);
Google's tools always run with `ANDROID_USER_HOME` inside the FactorIA folder.

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
`tools/cmake` (`build_ios.sh` runs `FACTORIA_CMAKE` when it is set, else the CMake the export found, else `cmake` from `PATH`).

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
hundred KB, nothing is installed) to catch a changed format, or Google dropping the pinned command-line tools revision.

## Platform settings

What an export needs besides the game itself (an icon, the Android version code, a Mac app category, a signing key...)
is set in two places:

- **`factoria.json`** (committed with the game): a top-level `icon` and an `export` object with one object per
  platform. Everything is optional and every field has a default; the file is documented field by field in
  `schemas/project.schema.json` (`factoria api --schema project` prints it; its descriptions are the reference for AIs).
  The editor's [Platform settings window](EDITOR.md#platform-settings) edits exactly these keys.
- **`~/.factoria/export.json`** (this computer only, never in a project): where the Android SDK and JDK are, and the
  keystore passwords.

The desktop and iOS exports read every field that concerns them (the Desktop and iOS sections below say where each one
goes). Until another platform's export reads a field, setting it changes nothing in that export. `factoria validate`
checks all of them, and the C++ API (`fa/tooling/export_settings.h`, `fa/tooling/icons.h`) reads, writes and applies them.

### Icon

One square image, `"icon": "assets/icon.png"` (project-relative path, forward slashes, inside the project; PNG or JPG;
1024x1024 recommended, at least 512x512). Each platform's export generates what that platform needs from it: the `.icns`
of a macOS app (16 to 1024 px and the @2x sizes), the icon resource of the Windows exe (16 to 256 px), the launcher icons
of Android (mipmaps from 48 to 192 px, a round variant and the adaptive icon), the App Store icon of iOS (1024x1024 with
no transparency) and the PNG of a Linux build. `export.<platform>.icon` replaces it for one platform. No icon at all
means the platform's default icon (and a warning from the export).

The same image is the window icon of the running game on Windows and Linux (title bar and taskbar, also when the game
is started from `factoria run`): the player reads `icon`, or `export.<this platform>.icon`, from `factoria.json` and hands
it to the window in 16 to 256 px. On macOS the Dock icon comes from the `.app`; mobile has no window. A missing or
unreadable icon is a warning in the log, never an error at run time (the export and `factoria validate` do report it).

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
| iOS | `teamId` | none | 10-character Apple Team ID for device builds. It is the default of `FA_IOS_DEVELOPMENT_TEAM`: that environment variable, when set, wins. |
| iOS | `buildNumber` | the project's `version` | `CFBundleVersion` (`version` stays `CFBundleShortVersionString`): up to three whole numbers separated by dots. App Store Connect wants it to grow with every upload. |

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
                  my-game.png  my-game.desktop      (Linux only: the icon and the application-menu entry)
                  FACTORIA_NOTICES.txt
                  game/              factoria.json, scenes/, scripts/, assets/ ...
macOS:          my-game-macos/My Game.app/Contents/
                  Info.plist  MacOS/my-game  Resources/AppIcon.icns  Resources/game/...  Resources/FACTORIA_NOTICES.txt
```

The player starts the game found in `game/` next to the executable (inside the
`.app`: `Contents/Resources/game`). Command line:

```
my-game [projectDir] [--scene scenes/level2.scene.json] [--fullscreen]
```

**Native plugins** ([EXTENDING.md](EXTENDING.md), section G). The export copies the build of every plugin declared for
the platform next to the executable: the contents of the plugin's `windows/` or `linux/` folder (its library and the
ones it needs), or of `macos/` into `Contents/Frameworks` (the ad hoc signature below covers them, with `--deep`). The
player loads them from there. An export for a platform the plugin is declared for but not built for fails and says
which file is missing; `factoria validate` lists those problems for every platform (a warning for each platform other
than this computer's).

Save games go to the OS per-user data folder (`~/.local/share/<id>`,
`%APPDATA%\<id>`, `~/Library/Application Support/<id>`).

Every run writes its log to `log.txt` in that folder (rewritten on each start): it is the file to ask a player for with a
bug report. On Windows the exe is a GUI program, so the game opens no console window. Started from a terminal it still
prints its log there, but the terminal does not wait for it (`start /wait my-game.exe` does); output redirected to a
file or a pipe works as with any program. If the game cannot start at all (no `game/` folder next to the exe), a
double-clicked exe shows the error in a message box.

**Long paths on Windows.** A macOS `.app` nests four folders, so an export into a deep folder easily passes the
260-character limit of Windows paths (MAX_PATH). The export (and every file the engine reads or writes) uses the `\\?\`
form of a path that long, so it works whether or not long paths are enabled on the machine. Explorer, zip tools and
some other programs still cannot open such files: export into a short folder (`--out C:\exports`) when you can.

On macOS the export signs the finished `.app` ad hoc (`codesign --force --deep --sign -`), last, so the signature
covers its `Info.plist`, the game files and the native plugins in `Contents/Frameworks`. The player of a signed release carries FactorIA's Developer ID signature, which covers
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
### Icon and settings per platform

What each desktop export takes from [Platform settings](#platform-settings):

- **macOS.** `Contents/Resources/AppIcon.icns` is generated from the icon (16 to 1024 px, PNG payloads, plus the @2x
  sizes) and `Info.plist` names it with `CFBundleIconFile`. `category`, `minimumSystemVersion` and `copyright` become
  `LSApplicationCategoryType`, `LSMinimumSystemVersion` and `NSHumanReadableCopyright` (the last only when set). All of
  it is written before the ad hoc signature, so `codesign --verify --deep --strict` passes.
- **Windows.** The exe is a copy of `factoria_player.exe`, whose icon resource is a neutral placeholder
  (`player/windows/factoria_player.ico`, compiled in by `factoria_player.rc`). The export replaces the placeholder's
  images (16, 24, 32, 48, 64, 128 and 256 px) with the game's icon in place, so the exe keeps its size and its
  structure, and recomputes the PE checksum. This works on any host: no Windows tools are needed to export for Windows
  from a Mac or Linux. A player without the placeholder (an older player, or another binary passed to `--player`) is copied
  unchanged and the report says so: the exe shows the player's own icon, and the game window still shows the game's
  icon at run time (above). The version information (Explorer's Details tab; Task Manager shows the description) is
  filled in the same way, with or without an icon: `FileDescription` and `ProductName` are the game's `name`,
  `FileVersion`, `ProductVersion` and the version numbers its `version`, `InternalName` and `OriginalFilename` the exe's
  name. The placeholder leaves 79 characters for a name and 31 for a version; a longer one is cut, with a warning.
- **Linux.** `<name>.png` (256 px) and `<name>.desktop` are written next to the game, with `Name`, `Exec`, `Icon`,
  `Type=Application`, `Terminal=false` and `Categories` (from `categories`; the default is `Game;`). Both
  `Exec=` and `Icon=` are bare names: the report prints the one command that installs the entry for the folder
  the game lives in (it rewrites them to absolute paths and copies the file to `~/.local/share/applications`).

Windows: the player of a release download carries FactorIA's signature once the release is signed
([BUILDING.md](BUILDING.md), "Releasing"), and one built from source is not signed. Writing the game's icon and version
information edits the exe, which invalidates a signature, so the export removes it (the certificate table at the end of
the file) and says so in the report: an exe with the wrong signature is worse than an unsigned one. Only a player
without the placeholders is copied byte for byte, signature included. SmartScreen may warn about an unsigned exe; sign
the exported exe with `signtool` to publish under your own name:

```
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /a my-game.exe
```

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
`-DFA_GAME_PROJECT_DIR=game -DFA_GAME_BUNDLE_ID=... -DFA_GAME_NAME=... -DFA_GAME_VERSION=... -DFA_GAME_BUILD=...
-DFA_GAME_ORIENTATION=... -DFA_GAME_ASSET_CATALOG=Assets.xcassets -DFA_IOS_DEVELOPMENT_TEAM=...` (and, for a game with
native plugins, `-DFA_GAME_PLUGINS=... -DFA_GAME_PLUGIN_DIR=plugins`):

```bash
./build_ios.sh --simulator --run                         # build, start in the iOS Simulator, console in the terminal
FA_IOS_DEVELOPMENT_TEAM=ABCDE12345 ./build_ios.sh --run  # the same on the connected iPhone or iPad
./build_ios.sh --simulator --build -- <xcodebuild args>  # only build; everything after -- goes to xcodebuild
./build_ios.sh --simulator     # or without flag for a device; opens build/FactorIA.xcodeproj
```

A device build registers the connected device with the team on the first build (Developer Mode must be on); see
[MOBILE.md](MOBILE.md#ios).

From the project's [platform settings](#platform-settings) the export takes:

- **The app icon.** `Assets.xcassets/AppIcon.appiconset` is written next to `build_ios.sh`: one 1024x1024 PNG
  (Xcode 14 or newer derives every iPhone and iPad size from it), composed opaquely over `iconBackground` because
  iOS rejects transparency. The script passes the catalog to CMake as `FA_GAME_ASSET_CATALOG`; Xcode compiles it into
  `Assets.car` and fills `CFBundleIcons` and `CFBundleIconName` of the app. Without an icon the export warns and the app has the default icon.
- **`teamId`** becomes the default of `FA_IOS_DEVELOPMENT_TEAM` in the script, so `./build_ios.sh --run` signs for the
  device without the variable. Setting `FA_IOS_DEVELOPMENT_TEAM` yourself still wins.
- **`buildNumber`** becomes `CFBundleVersion` (`FA_GAME_BUILD`); when absent, the `version` is used as before.

**Native plugins** ([EXTENDING.md](EXTENDING.md), section G). Each plugin declared for iOS needs `ios/iphoneos/lib<name>.a` and
`ios/iphonesimulator/lib<name>.a`; the export copies its `ios/` folder to `plugins/<name>/` and the app links it
([MOBILE.md](MOBILE.md#native-plugins-ios)).

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
The iOS libraries ship in the macOS download only, so export for iOS on a Mac.

Details in [MOBILE.md](MOBILE.md).

## Tips

- Run `factoria validate` first; export only checks what packaging needs.
- Add the platform to `"platforms"` in `factoria.json` or export prints a warning.
- Orientation comes from `display.orientation` (`landscape`, `portrait`, `any`).
- Version `1.2.3` becomes Android `versionCode` 10203 and iOS `CFBundleShortVersionString` 1.2.3; the iOS `CFBundleVersion` is
  the same unless `export.ios.buildNumber` says otherwise.
