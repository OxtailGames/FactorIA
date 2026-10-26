# Exporting a game

`factoria export` turns a game project into something you can ship. The same
function is available to tools as `fa::export_project` (`fa/tooling/export.h`), to AIs as the command
`project.export`, and in the editor as the **Export** button ([From the editor](#from-the-editor)).

```bash
factoria export [project] --platform <linux|windows|macos|android|ios|web> [--format apk|aab|gradle|appimage|msix|folder] [--out DIR] [--release [--allow-debug-key]]
                [--player PATH] [--engine-root DIR | --mobile-dir DIR] [--allow-player-mismatch] [--allow-missing-plugins]
```

`--format` is for Android (`apk` by default, `aab` for Google Play, `gradle` for only the project): see [Android](#android);
for Linux, `appimage` also builds the game as one AppImage file: see [Linux: AppImage](#linux-appimage).
`--release` on Linux, Windows and macOS puts the whole game in ONE file, `game.pak`, with the scripts compiled to bytecode: see
[Release build](#release-build-gamepak). On Android it builds the release APK/AAB. `--platform web` writes a page, the web
player and `game.pak`, plus a zip itch.io takes as an HTML5 game: see [Web](#web).

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
`format` and `artifact` (Android: the format, and the absolute path of the APK/AAB that was built; Linux with `appimage`: the AppImage; web: `zip` and the zip), `mode` also tells where the web player came from,
`notices` (see [License notices](#license-notices)), `pack` and `packed` (a `--release` desktop export: the pack and the paths in it), `files`
(what is on disk, so a release export lists `game.pak`, not the files in it), `nextSteps`, `warnings`. A game with AI-made assets also
gets `AI_CONTENT_DISCLOSURE.md` ([AI content disclosure](#ai-content-disclosure)).

## From an AI: `project.export`

The same export is the command `project.export` (MCP tool `project_export`, also `factoria call project.export`, the
editor console and `fa.call` in scripts), so an AI connected over MCP can build a Windows folder or the Android
APK without a shell. Arguments are all optional: `platform` (default: this machine), `format` (Android: `apk`, `aab` or
`gradle`; Linux: `appimage`), `out` (parent folder, relative to the project and inside it like the `fs.*` commands, default `build/export`) and
`release`. It returns the report (`outputDir`, `mode` (Android, iOS, web), `format`, `artifact`, `notices`, `pack` and `packed` for a release desktop export, `pluginsLeftOut` with `allowMissingPlugins`, `materials` when the game has custom materials, `files`, `nextSteps`, `warnings`); an
unknown platform or format or a failed validation is an error with a hint. An Android export runs Gradle, which takes from
seconds to minutes (the first one much longer): the call returns when the build is done.
`dryRun: true` runs every check of the export and writes nothing: it returns `platform`, `outputDir` (the folder an
export would replace), `mode` (Android, iOS), `format` and `artifact` (Android, Linux with `appimage`), `toolchain` (Android with `apk` or `aab`:
`jdk`, `jdkFrom`, `jdkMajor`, `sdk` and `sdkFrom`, the JDK and SDK the build would use and where they were found), `player`
(desktop; web: its `factoria_player.js`) and `warnings`, or the error the export would give, including a missing JDK or SDK, a missing keystore or
password for `--release` (`fa::plan_export` in C++). `--player`, `--engine-root` and `--mobile-dir` are CLI-only: the command uses the `factoria_player` and the `mobile/`
folder next to the running binary, or `$FACTORIA_ENGINE_DIR` when it is set.

```
project_export {"platform":"windows","release":true}
project_export {"platform":"android","dryRun":true}
```

## From the editor

The editor's toolbar has an **Export** button (also File > Export Game...). It opens the **Export game** window: one
button per platform (Windows, macOS, Linux, Android, iOS, Web), each running this same export, never a separate one.

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
  installs it (**Install Android build tools**, **Download Windows player**, **Download mobile libraries**, **Download web player**, **Install CMake**,
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
`AGENTS.md`, `CLAUDE.md`, `jsconfig.json`, the project's own top-level `README.md` (documentation for whoever works on the
game; any capitalization), a top-level `steam_appid.txt` (the development app id of the
[Steam backend](PLATFORM.md#steam-steamworks): a game started by Steam gets its app id from Steam), the folder of a native
plugin that lives inside the project (its build is shipped instead, below), and the output folder itself. Your project is never modified; the feedback file stays in the
repository. Those are the files no game reads, on every platform and with or without `--release`; the list is also the comment of
`fa/tooling/export.h`. Only the TOP-LEVEL `README.md` is left out: a `README.md`, `CREDITS.md` or `LICENSE` deeper in the project, or a data
file of any kind, ships, because a game may load it.

**Dot-folders never ship** (`.git`, `.factoria`, `.github`, `.vscode`, a `.cache` of your own): anything whose name starts with a dot is
left out at every depth, so a game must not keep data it loads in a folder like `.data/`. Rename the folder
instead. To leave out more, list project-relative globs in `export.exclude` of `factoria.json`:

```json
{ "export": { "exclude": ["store/**", "levels/*.tmx", "notes"] } }
```

`*` matches inside one folder, `**` crosses folders, `?` is one character; a glob that names a folder leaves out everything in
it. The globs apply to every export (the game folder, `game.pak`, web, Android, iOS) and are added to the list above. Paths are
project-relative with forward slashes and may not leave the project. `factoria validate` checks them: a glob that matches no
file is a warning (probably a typo), one that matches the main scene is an error. Your project is never modified.

Audio import settings (`assets.json`, [ASSETS.md](ASSETS.md)) act at export time: a WAV with `convert: "qoa"` ships as
`<path>.qoa` (the engine plays that twin when the original is missing; the converted file is cached in
`.factoria/export-cache/<platform>/audio/`, so only changed sounds are encoded again), and the shipped `assets.json`
carries the measured loudness (`analysis`) of every sound with `normalize` on, so the game never measures at run time.
A conversion that cannot be done (more than 8 channels) leaves the file as it is and adds a warning to the report.

Custom materials (`*.material.json`) ship compiled, because a game has no shader compiler: the export compiles each one
for the shader dialects of the platform (Windows `hlsl5`, Linux `glsl430`, macOS `metal_macos`, iOS `metal_ios` and
`metal_sim`, Android and web `glsl300es`) and ships `materials/water.material.json.<dialect>.shader` next to the material;
the GLSL snippet the material names (`shaders/water.surface.glsl`) is not shipped. This needs sokol-shdc, which the
factoria downloads carry next to `factoria` ([The shader compiler](#setting-up-this-computer)), unless
`.factoria/shader-cache` already holds the compiled shaders. A
material that does not compile stops the export with the errors `factoria validate` lists (file, line, column, the line
quoted, a hint). The report's `materials` lists the materials that shipped. How to write a material: [SHADERS.md](SHADERS.md).

The export adds two files of its own: `.factoria-export` at the top of the export folder (next section) and
`FACTORIA_NOTICES.txt` ([License notices](#license-notices)). An Android export also leaves out the keystore named by
`export.android.signing` when it lives inside the project (a warning says to keep it outside the repository): a signing
key must never end up in the assets of an APK.

### Textures

Textures are the one thing an export changes instead of copying (import settings `compression` and `atlas` in
`assets.json`; [ASSETS.md](ASSETS.md#textures) has the details):

- **Android and iOS exports** compress every PNG to a GPU-ready KTX2 file (UASTC, Basis Universal): the export ships
  `assets/hero.png.ktx2` in place of `assets/hero.png`, and the game, which keeps asking for `assets/hero.png`, loads the
  twin and uploads it to ASTC, ETC2 or BC7 depending on the device, falling back to RGBA8 when needed. Video memory
  for textures drops to a quarter. **Desktop exports** ship PNGs (set `"compression": "uastc"` in
  `defaults.texture` to compress them too).
- Textures with the same `atlas` group are packed into `assets/atlases/<group>.png` (several pages when they do not fit)
  and the shipped `assets.json` records where each went (`packed`); the original PNGs are not shipped.
- Encoding is cached in `.factoria/export-cache/<platform>/` (never shipped), so only the first export is slow. A texture
  that cannot be converted ships as a PNG with a warning; the export never fails because of it.

### Size of the player

Every game of a platform ships the same prebuilt player (that is what lets a game export without a compiler), so it
carries the whole engine: 2D and 3D, physics, audio, networking, UI. Code a game never calls costs disk space only: it is
not run and allocates nothing. The linker drops the functions and data that nothing reaches: `-dead_strip` on macOS and iOS,
`--gc-sections` on Linux (with every file compiled into its own sections), the NDK's default `--gc-sections` on Android,
`/OPT:REF` with MSVC on Windows, and Emscripten's own removal on the web. Measured 2026-10-26 on the M29 engine:

| Player | Size |
|---|---|
| macOS arm64, Release, without symbols | 9.1 MB (10.2 MB before `-dead_strip`) |
| Web, `factoria_player.wasm`, Emscripten 6.0.10 | 8.0 MB, 3.0 MB with gzip (6.8 MB and 2.7 MB in v0.2.0) |
| Windows x64 (v0.2.0) | 8.1 MB |
| Linux x86_64 (v0.2.0, before `--gc-sections`) | 13 MB |

Link-time optimization (LTO) saved 0.1 MB more on macOS and is not used: it changes which code is inlined across
modules, and the engine keeps its floating-point code identical on every platform. For most games the assets weigh more
than the player; [Textures](#textures) and `export.exclude` are where an export gets smaller.

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
plus third-party libraries and fonts (sokol, QuickJS-ng, Box2D, stb, cgltf, Basis Universal, HarfBuzz, SheenBidi, dr_libs, QOA,
nlohmann/json, SDL_GameControllerDB, DejaVu Sans, Press Start 2P). Their licenses only ask that their notices travel
with every copy, so every export writes `FACTORIA_NOTICES.txt` with all of them where it ships with the game:

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

## AI content disclosure

Stores ask whether a game contains AI-generated content (Steam's content survey, and similar forms elsewhere). When any
asset in `assets.json` has `provenance.ai: true`, the export writes `AI_CONTENT_DISCLOSURE.md` at the top of
`<out>/<game-slug>-<platform>/`, next to the game and not inside it, and adds a line to `nextSteps`. It is for you to read
and paste into the store form; leave it out of what you ship if you like. No AI assets, no file. What it says, where the
records come from and `assets.disclosure` are in [ASSETS.md](ASSETS.md#provenance-and-store-disclosure).

## What each export needs

One row per export. A **source build** is a `factoria` compiled from the repository: it has its own OS's player but no
`mobile/` libraries, no `web/` and no players of the other OSes. The **download** (the FactorIA package) carries `mobile/`
(Android; iOS only in the macOS package), `web/` and the player of its own OS. The host columns say whether a machine can
do the export with a source build: **yes** = offline, nothing is downloaded; **after setup** = offline once the named
download is done; **no** = that host cannot do it. The cells come from the export code and `factoria setup`; `factoria setup`
(no arguments) lists what a computer already has.

| Export | What it needs | Windows host | Linux host | macOS host |
|---|---|---|---|---|
| `windows` folder ([Desktop](#desktop-linux-windows-macos)) | the Windows player: from the download, or `factoria setup players` (about 60 MB for all OSes) or `--player`. The exe's icon and version info are written by the export on any host. Signing is `sign.windows` (patching the exe removes the player's signature) | yes | after setup | after setup |
| `windows --format msix` ([Microsoft Store](#microsoft-store)) | the same as the folder; the package itself needs nothing else | yes | yes | yes |
| `linux` folder | the Linux player, same sources | after setup | yes | after setup |
| `linux --format appimage` ([AppImage](#linux-appimage)) | `factoria setup appimage` (about 16 MB; Linux x86_64 only, so WSL on Windows) | in WSL, after setup | after setup (x86_64) | no |
| `macos` `.app` | the macOS player, same sources. The ad hoc `codesign` runs only on a Mac; elsewhere the app is not signed | after setup | after setup | yes |
| `macos` signed and notarized ([Signing and notarizing](#signing-and-notarizing-for-macos)) | `codesign`, `xcrun notarytool` and `stapler` (Xcode command-line tools), a Developer ID Application certificate (Apple Developer Program) and a notary profile. Notarization uploads to Apple | no | no | online (notarization) |
| `web` ([Web](#web)) | `web/` (`factoria_player.js` + `.wasm`): in the download; for a source build `factoria setup players --platforms web` (about 15-33 MB), or an Emscripten 6.0.10 build of the engine passed with `--player` ([BUILDING.md](BUILDING.md)) | after setup | after setup | after setup |
| `android --format gradle` ([Android](#android)) | no JDK, no SDK. The project holds the Android libraries (prebuilt mode) or is generated from an engine checkout (source mode) | after setup (`players --platforms mobile`) or with a checkout: yes | same | same |
| `android` apk / aab, **prebuilt** ([modes](#mobile-exports-prebuilt-or-source)) | a JDK 17+ (17 and 21 are tested; `factoria setup android` installs Temurin 21) and the Android SDK with `platforms;android-36` and `build-tools;35.0.0` (same command, about 500 MB, accepts the SDK license); the Android libraries as above. No NDK, no CMake. The first build downloads Gradle 8.14.3 and the Android Gradle plugin | after setup, then after one online build | same | same |
| `android` apk / aab, **from source** | the same JDK and SDK, an engine checkout (`--engine-root` or `FACTORIA_ENGINE_DIR`), and NDK r27+ (`ndk;27.2.12479018`) and a CMake 3.24+: 3.31.6 in the SDK, else any other 3.24+ in the SDK, else one on this computer (the export points Gradle at it with `cmake.dir`). `factoria setup android` does not install the NDK or the CMake: `sdkmanager "ndk;27.2.12479018" "cmake;3.31.6"`. Compiles the engine for two ABIs (minutes) | after setup, then after one online build | same | same |
| `android --release` (Google Play) | the above plus a keystore and `FACTORIA_ANDROID_KEYSTORE_PASSWORD` ([Signing](#android)); without a keystore it is an error unless `--allow-debug-key` (never upload that build) | same | same | same |
| `ios` project ([iOS](#ios)) | prebuilt: the iOS libraries (in the macOS download; on Windows and Linux `factoria setup players --platforms mobile`); source: an engine checkout | prebuilt: after setup; source: yes | same | yes with the macOS download or a checkout |
| `ios` app (`build_ios.sh`) | a Mac with Xcode (from the App Store; `factoria setup xcode` checks it) and CMake 3.24+ (`factoria setup cmake` installs 3.31.6, about 75 MB); a device build also needs an Apple Team ID | no | no | yes |

Uploading the result is a separate step: [Uploading to stores](#uploading-to-stores). What each `factoria setup` component
installs, and where: [Setting up this computer](#setting-up-this-computer). A source build ahead of the last release cannot
run `factoria setup players` (error `no_release`): build the player on that OS and pass `--player`.

## Setting up this computer

An export needs things that are not part of FactorIA: a JDK and the Android SDK for an APK or AAB, the `factoria_player`
of the other operating systems, CMake and Xcode for iOS. FactorIA installs what it can instead of only telling you what to
install:

```bash
factoria setup                                     # what this computer has and what is missing (writes and downloads nothing)
factoria setup android                             # JDK 21 + Android SDK; shows the Android SDK license and asks first
factoria setup android --accept-licenses           # you have read the license and accept it (scripts)
factoria setup players                             # the players of the other desktop OSes + the Android/iOS libraries, for this version
factoria setup players --platforms windows,linux   # only these (windows, linux, macos, mobile, web)
factoria setup cmake                               # CMake 3.31 for the iOS export, unless a CMake 3.24+ is found
factoria setup xcode                               # macOS: checks Xcode, opens its App Store page when it is missing
factoria setup appimage                            # Linux x86_64 (and WSL): appimagetool + the AppImage runtime, for --format appimage
factoria setup shaders                             # sokol-shdc, the shader compiler of custom materials (the factoria downloads already have it next to factoria)
factoria setup ffmpeg                              # ffmpeg, so --record-video trailer.mp4 works without installing it by hand
```

| Component | What it installs | Download | The export that needs it |
|---|---|---|---|
| `android` | Eclipse Temurin JDK 21, the Android command-line tools (revision 22.0, the classic Java `sdkmanager`), `platform-tools`, `platforms;android-36`, `build-tools;35.0.0`, the Android SDK license | about 500 MB (0.9 GB on disk) | `--platform android` (APK/AAB through Gradle) |
| `players` | `factoria_player` of every desktop OS but this one, and `mobile/` (the Android and iOS libraries, from the macOS package, on any OS), from the GitHub release of this factoria's version | about 60 MB | `--platform windows\|linux\|macos` for another OS; Android and iOS without the engine source |
| `players` with `--platforms web` | `web/` (`factoria_player.js` + `factoria_player.wasm`), from the download of this machine's own OS. Every download has `web/` next to `factoria`, so this is only for a factoria without it | about 15-33 MB | `--platform web` ([Web](#web)) |
| `cmake` | CMake 3.31 from Kitware, only when no CMake 3.24+ is found (`--force` installs it anyway) | about 75 MB | `--platform ios` (`build_ios.sh`) |
| `xcode` | nothing: Xcode comes from the App Store and needs your Apple ID and password, so this only checks it, opens its page and lists the steps | - | `--platform ios` |
| `shaders` | sokol-shdc, the shader compiler of custom materials, at a pinned commit of `github.com/floooh/sokol-tools-bin`: the one file for this computer (Windows, Linux or macOS, x64 or arm64), checked against a SHA-256 compiled into FactorIA. The factoria downloads carry the same file next to `factoria`, so this is for a factoria built from source, or when that copy is gone | about 8-12 MB | compiling `*.material.json` (`factoria validate`, `run`, `export`); see below |
| `ffmpeg` | ffmpeg 6.0, the static GPL build of `github.com/eugeneware/ffmpeg-static` (release `b6.0`, with libx264 and AAC): the one gzip file for this computer (Windows x64, Linux and macOS x64 or arm64), checked against a SHA-256 compiled into FactorIA and unpacked to `$FACTORIA_HOME/tools/ffmpeg/b6.0/`. Skipped when an ffmpeg is already found | about 19-28 MB | `factoria run --record-video trailer.mp4` ([Recording a replay as a video](#gameplay-video-from-a-replay)) |
| `appimage` | appimagetool 1.9.1 and the type 2 AppImage runtime 20251108 from `github.com/AppImage`, each checked against a SHA-256 compiled into FactorIA. Only on Linux x86_64 (`unsupported` elsewhere) | about 16 MB | `--platform linux --format appimage` ([Linux: AppImage](#linux-appimage)) |

Everything lands under `$FACTORIA_HOME` (default `~/.factoria`, `%USERPROFILE%\.factoria` on Windows):

```
~/.factoria/
  android/jdk/          Eclipse Temurin 21
  android/sdk/          cmdline-tools/22.0, platform-tools, platforms/android-36, build-tools/35.0.0, licenses/
  android/user/         what Google's tools keep for themselves ($ANDROID_USER_HOME): about 4 MB (sdkmanager's package-list cache) with the pinned tools, about 250 MB if the fallback below applies
  players/<version>/    windows/factoria_player.exe, linux/factoria_player, macos/factoria_player, mobile/, web/ (only when asked for)
  tools/cmake/          CMake (CMake.app on macOS)
  tools/appimage/       appimagetool-<version>-x86_64.AppImage and runtime-<version>-x86_64 (Linux x86_64 only)
  tools/sokol-shdc/     <commit>/sokol-shdc[.exe] (folders of older commits are removed by the next install)
  export.json           machine settings: learns where the JDK and the SDK are (below)
```

Nothing else on the computer changes: no `sudo`, no `PATH`, no registry. A JDK or SDK that is found already (`android.jdk`,
`JAVA_HOME`, `ANDROID_HOME`, Android Studio's) is used and only completed with what is missing, never replaced; Unity Hub's
belongs to Unity and is never touched (FactorIA sets up its own next to it). Only what was installed here is written to
`export.json`. Running a setup again is safe: it skips what is there and says so.

**From the editor.** File > Set Up This Computer... opens a window with the components, their state, what is missing
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

**The shader compiler.** Custom materials are compiled with sokol-shdc. The factoria downloads (zip, installer, tar.gz,
AppImage) carry it next to `factoria` (`sokol-shdc.exe` on Windows), so a downloaded FactorIA needs no setup for it.
FactorIA looks for it in this order: the file named by `$SOKOL_SHDC`, a `sokol-shdc` next to the `factoria` program (the
downloads), then `$FACTORIA_HOME/tools/sokol-shdc/<commit>/` (what `factoria setup shaders` installs; `<commit>` is the pinned
sokol-tools-bin commit, and the file is checked against its SHA-256 before it is kept). `setup.status` shows which one was
found (`found next to factoria` for the one of the download); a `$SOKOL_SHDC` that names nothing is reported as a problem rather
than ignored. The release checks the file it bundles against the same pin: on Windows and Linux it is the pinned file byte for
byte (unsigned, so its SHA-256 is the one below); on macOS the pinned x86_64 and arm64 files are joined into one universal file
and signed with `factoria`, so only its two halves match the pin. `tools/shaders/compile_shaders.sh` (engine developers) uses the
same pin and the same folder. **Windows Defender may remove `sokol-shdc.exe`.** It has flagged the pinned file as a threat by
mistake (a false positive, `Trojan:Win32/Bearfoos.B!ml`, a guess of Defender's machine-learning model; the file is an unsigned
command-line compiler, and the SHA-256 of the pinned Windows build is
`43d42c2e477bcc5012420f8d9ff641fedc41d552d165397fff4f2e60ba0d2ebb`, so you can check that a file is the one FactorIA pins:
`certutil -hashfile sokol-shdc.exe SHA256` or PowerShell's `Get-FileHash`). If the file vanishes or cannot be read,
`setup.status` says `missing` and the install says why. Restore it from Windows Security > Virus & threat protection > Protection
history (or allow it there), run `factoria setup shaders` to download the pinned file again into `~/.factoria`, or point
`SOKOL_SHDC` at a copy you trust; FactorIA never changes your antivirus settings. A false positive can be reported to Microsoft at
microsoft.com/wdsi/filesubmission. Games never contain sokol-shdc, only the developer's computer needs it: exported games hold
the compiled shaders, and its licences (and those of what it links) are in `factoria docs licenses` and in the
`THIRD_PARTY_NOTICES.txt` of the downloads.

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
`api.github.com` and `github.com/OxtailGames/FactorIA/releases` (players), `github.com/Kitware/CMake` (CMake) and
`github.com/AppImage` (appimagetool and the runtime; two pinned releases) and `raw.githubusercontent.com/floooh/sokol-tools-bin` (sokol-shdc; one pinned commit); a listing
that points anywhere else is refused. Every file is checked against the checksum its publisher lists (SHA-256 from Adoptium,
GitHub and Kitware, SHA-1 from Google's package list, a SHA-256 compiled into FactorIA for the two AppImage files and for sokol-shdc) before it is unpacked, and a mismatch (code `checksum_mismatch`)
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

No image tool or provider? `assets.draw_icon` draws the icon and the Android foreground from shapes and text
([ASSETS.md](ASSETS.md#the-game-icon-without-a-provider-assetsdraw_icon)).

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
    "macos":   { "category": "public.app-category.games", "minimumSystemVersion": "11.0", "copyright": "Copyright 2026 My Studio",
                 "buildNumber": "7", "entitlements": { "com.apple.security.network.client": true } },
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
| macOS | `buildNumber` | the project's `version` | `CFBundleVersion` (`version` stays `CFBundleShortVersionString`): up to three whole numbers separated by dots. App Store Connect wants it to grow with every upload of the Mac App Store package. |
| macOS | `usesNonExemptEncryption` | `false` | `ITSAppUsesNonExemptEncryption` in `Info.plist` (always written, so App Store Connect does not ask about export compliance on every upload). `true` only when the game uses encryption beyond what macOS provides. |
| macOS | `entitlements` | none | Extra entitlements of the Mac App Store signature (`{"com.apple.security.network.client": true}`), merged into the sandbox, plugin and profile entitlements by `sign.macos` with `distribution: "appStore"` ([Mac App Store](#mac-app-store)). Reverse-DNS keys with boolean, string or array values; the sandbox and the identifiers (`com.apple.application-identifier`, `com.apple.developer.team-identifier`, `com.apple.security.inherit`) are not yours to set (the profile gives them). A misspelt well-known key is a warning with a "did you mean". |
| Linux | `categories` | `["Game"]` | `Categories=` of the `.desktop` file (the entries are joined with `;`). |
| Android | `format` | `apk` | `apk`, `aab` (Google Play bundle) or `gradle` (only the Gradle project). |
| Android | `adaptiveIcon.foreground` | the icon scaled into the safe zone | A 108dp layer (432x432 px recommended): only the inner 66dp circle always stays visible. The default shrinks the icon to 66/108 of the layer over transparency. |
| Android | `adaptiveIcon.background` | `#FFFFFF` | `"#RRGGBB"`, or the path of an image that fills the layer. |
| Android | `adaptiveIcon.monochrome` | none | Single-colour PNG with transparency; Android 13 tints it for themed icons. |
| Android | `versionCode` | from `version`: `1.2.3` is `10203` | Whole number that grows with every Google Play upload. |
| Android | `minSdk` / `targetSdk` | `26` / `36` | API levels; `26 <= minSdk <= targetSdk`. |
| Android | `permissions` | none | Extra `<uses-permission>` names such as `android.permission.INTERNET`. `android.permission.VIBRATE` (for `input.vibrate`) is always in the manifest. |
| Android | `signing.keystore` / `signing.alias` | none | Release signing key: the keystore file (project-relative or absolute; keystores are better kept outside the repository) and the key's alias. The passwords are never in the project (below). |
| iOS | `iconBackground` | `#FFFFFF` | The App Store icon cannot be transparent: transparent pixels take this colour, and the PNG is written without an alpha channel. |
| iOS | `teamId` | none | 10-character Apple Team ID for device builds. It is the default of `FA_IOS_DEVELOPMENT_TEAM`: that environment variable, when set, wins. |
| iOS | `buildNumber` | the project's `version` | `CFBundleVersion` (`version` stays `CFBundleShortVersionString`): up to three whole numbers separated by dots. App Store Connect wants it to grow with every upload. |
| iOS | `usesNonExemptEncryption` | `false` | `ITSAppUsesNonExemptEncryption` in `Info.plist`. `true` only when the game uses encryption beyond what iOS provides (HTTPS and other system encryption are exempt). |
| iOS | `privacy` | the engine's entries only | What the game adds to `PrivacyInfo.xcprivacy`: `tracking`, `trackingDomains`, `accessedApis` (`[{"category": "DiskSpace", "reasons": ["E174.1"]}]`), `collectedData` (`[{"type": "PurchaseHistory", "linked": true, "purposes": ["AppFunctionality"]}]`). The categories, reason codes, data types and purposes are in [MOBILE.md](MOBILE.md#store-privacy-forms). Edited in `factoria.json` only (the editor's window leaves it as it is). |
| Windows | `format` | `folder` | `folder`: only `<slug>-windows/`. `msix`: also `<slug>-windows.msix` next to it, the package of the Microsoft Store (`--format msix` wins over it). See [Microsoft Store](#microsoft-store). |
| Windows | `msix.identityName`, `msix.publisher`, `msix.publisherDisplayName` | empty (a placeholder identity) | The package identity, copied from Partner Center > Product identity: `Package/Identity/Name` (like `12345Studio.MyGame`), `Package/Identity/Publisher` (`CN=...`) and the publisher name players see. Without them the package installs on your PC but the Store rejects it. |
| Windows | `msix.displayName`, `msix.description` | the game's name | The name and short description Windows shows. |
| Windows | `msix.backgroundColor` | `transparent` | Tile background: `#RRGGBB` or `transparent`. |
| Windows | `msix.version` | the project's `version` plus `.0` | Four numbers (`1.2.3.0`); the Store needs the fourth to be 0. |
| Windows | `msix.minVersion` | `10.0.17763.0` | Oldest Windows 10 build (version 1809). |
| Windows | `msix.languages` | the project's `localization.languages`, else `["en-us"]` | Language tags the Store lists for the app. |
| All | `export.exclude` (directly in `export`) | `[]` | Project-relative globs no export ships, see [What is shipped](#what-is-shipped-and-what-is-not). |
| Desktop | `export.scriptBytecode` (directly in `export`, not per platform) | `true` | A `--release` export of Linux, Windows or macOS compiles the scripts to bytecode inside `game.pak`; `false` packs them as plain source. See [Scripts as bytecode](#scripts-as-bytecode). |

Wrong types or values are errors that name the JSON pointer and the fix
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
  "android": { "sdk": "/Users/me/Library/Android/sdk", "jdk": "/path/to/jdk", "keystorePassword": "...", "keyPassword": "..." },
  "sign": { "macos": { "identity": "Developer ID Application: Ada Lovelace (ABCDE12345)", "notaryProfile": "factoria-notary" } }
}
```

| Key | Meaning |
|---|---|
| `android.sdk` | Folder of the Android SDK. Empty = look for it (below). `~/` is the home folder. |
| `android.jdk` | Folder of a JDK 17 or newer (the one that contains `bin/java` and `release`). Empty = look for it. |
| `android.keystorePassword` | Password of the keystore. `FACTORIA_ANDROID_KEYSTORE_PASSWORD` wins over it. |
| `android.keyPassword` | Password of the signing key. `FACTORIA_ANDROID_KEY_PASSWORD` wins over it; when neither is set the keystore password is used. |
| `sign.macos.identity` | The certificate `sign.macos` signs with (`Developer ID Application: Your Name (TEAMID)`). The `identity` argument and `FACTORIA_MACOS_SIGN_IDENTITY` win over it. Not a secret. |
| `sign.windows.pfx` | The code-signing certificate (`.pfx`) `sign.windows` signs with. The `pfx` argument and `FACTORIA_WINDOWS_PFX` win over it. The password is only read from `FACTORIA_WINDOWS_PFX_PASSWORD`. |
| `sign.macos.keychain` | A keychain file that holds the certificate. `FACTORIA_MACOS_KEYCHAIN` and the `keychain` argument win over it. |
| `sign.macos.notaryProfile` | The notarytool keychain profile (`xcrun notarytool store-credentials <name>`). `FACTORIA_NOTARY_PROFILE` and the `keychainProfile` argument win over it. |
| `sign.macos.appStoreIdentity` | The certificate of `distribution: "appStore"` (`Apple Distribution: ...` or `3rd Party Mac Developer Application: ...`). The `identity` argument and `FACTORIA_MACOS_APPSTORE_IDENTITY` win over it. |
| `sign.macos.installerIdentity` | The certificate that signs the `.pkg` (`3rd Party Mac Developer Installer: ...` or `Mac Installer Distribution: ...`). The `installerIdentity` argument and `FACTORIA_MACOS_INSTALLER_IDENTITY` win over it. |

The file is written with owner-only permissions on macOS and Linux because it can hold passwords (loading it warns when
other users can read it). Passwords never go in `factoria.json` or in the files of an export. The Apple ID password of
notarization is the one secret `sign.macos` takes, and only from the environment (`FACTORIA_APPLE_APP_PASSWORD`), never from this file.

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

**The player must come from the same build as `factoria`.** Both carry a build fingerprint (the commit they were built from,
with `-dirty` when tracked files had uncommitted changes; `factoria version` prints it). The export reads the player's
bytes, so it checks the player of another OS too, and the web player (`factoria_player.wasm`) and the prebuilt Android
(`libfactoria_player.so`) and iOS (`libfactoria_player_main.a`) libraries; an Android or iOS export that compiles the engine
from a checkout has no prebuilt player to check. A player from another
build stops the export with an error that names both builds: it may lack the components or the script API the game uses, or
fail to start. Fix it by building both from one checkout, or with `factoria setup players` when this `factoria` is the
release those players belong to (for the web: `cmake --build --preset web-release`, or `factoria setup players --platforms web`;
for Android and iOS: `factoria setup players`, `--mobile-dir`, or `--engine-root` to compile the engine from a checkout).
To bundle that player anyway, pass `--allow-player-mismatch` (the `export` command's
`allowPlayerMismatch` argument): the export goes on and `warnings` says which builds differ. A `factoria` or a player built
outside a git checkout carries `unknown` and is not compared. The same commit with `-dirty` on one side only is a warning,
not an error; the fingerprint does not see which edits a `-dirty` build had, so rebuild both after editing the engine.

**A player with no fingerprint** is one from a release older than the check (v0.2.0 and earlier). `factoria setup players`
installs the players of *this factoria's version*, so on a newer `factoria` built from source it would put the same old
player back: the error then says the player predates fingerprints, and the ways on are a player from a newer release (once
one is published and your `factoria` matches it), a player built from your checkout (`--player`), or
`--allow-player-mismatch` when you know the old player runs your game (it lacks whatever the engine gained since; the
warning says so). The check is not relaxed to compare engine versions: only the fingerprint tells two builds apart.

```
linux/windows:  my-game-linux/
                  my-game            (my-game.exe on Windows)
                  my-game.png  my-game.desktop      (Linux only: the icon and the application-menu entry)
                  my-game-x86_64.AppImage            (Linux only, with --format appimage: the whole game as one file)
                  FACTORIA_NOTICES.txt
                  AI_CONTENT_DISCLOSURE.md           (only when assets are made with AI)
                  game/              factoria.json, scenes/, scripts/, assets/ ...
macOS:          my-game-macos/My Game.app/Contents/
                  Info.plist  MacOS/my-game  Resources/AppIcon.icns  Resources/game/...  Resources/FACTORIA_NOTICES.txt
```

With `--release` the `game/` folder is one file, [`game.pak`](#release-build-gamepak), in the same place (next to the
executable; `Contents/Resources` in the `.app`).

The executable is named after the game's slug (`Space Dodge` -> `space-dodge`). A game called `Game`, or whose name has no
letter or digit, has the slug `game`: on Linux its executable is `game-bin`, so it does not sit on the `game/` folder
(`game.desktop` and `game.png` keep the slug; Windows `game.exe` and macOS `Contents/MacOS/game` cannot collide).

The player starts the game found in `game/` next to the executable (inside the
`.app`: `Contents/Resources/game`), else the pack `game.pak` next to it. Command line:

```
my-game [projectDir | game.pak] [--scene scenes/level2.scene.json] [--fullscreen] [--version]
```

`--version` prints the engine version and build the player belongs to (`factoria_player 0.2.0 (build 1a2b3c4d5e6f)`,
what `factoria version` prints after `factoria`) and exits.

**Linux requirements.** The Linux player is built in Valve's Steam Runtime "sniper" container (libstdc++ and libgcc
linked in), so a Linux game needs glibc 2.31 or newer and the usual desktop libraries (`libX11`, `libXi`, `libXcursor`,
`libGL.so.1`, `libEGL.so.1`, `libasound.so.2`): it runs in Steam's Linux runtime (Steam Deck included), on Ubuntu 20.04
and newer, Debian 11 and newer, Fedora and Arch. A player you build yourself with `linux-release` needs at least the glibc
of the machine that built it; `scripts/build-sniper.sh` makes the portable one ([BUILDING.md](BUILDING.md)).

**Native plugins** ([EXTENDING.md](EXTENDING.md), section G). The export copies the build of every plugin declared for
the platform next to the executable: the contents of the plugin's `windows/` or `linux/` folder (its library and the
ones it needs), or of `macos/` into `Contents/Frameworks` (the ad hoc signature below covers them, with `--deep`). The
player loads them from there. An export for a platform the plugin is declared for but not built for fails and says
which file is missing; `factoria validate` lists those problems for every platform (a warning for each platform other
than this computer's). A plugin is built only for the computer it is built on (`platform.add_backend` and CMake), but the
export of every platform needs its build: get the other platforms' builds from CI or from the other computer (the same
command there) and copy each platform's folder next to the plugin. Without them, pass `--allow-missing-plugins` (the
`export` command's `allowMissingPlugins`): the export leaves out each plugin whose build is missing, with a warning that
names it, and the report lists them in `pluginsLeftOut`. It applies to plugins declared `optional` and to those that are
not (the game then starts, but scripts that call the missing plugin fail, and the warning says so): use it for a build you
test or send to a tester, and build every plugin before the one you publish. A Steam game exported this way has no Steam:
it runs with no platform services (`platform.backend` is `none`). A `plugin.json` in the plugin's `macos/` folder (the entitlements it needs, EXTENDING.md section G)
does not ship in the app: the export writes the entitlements to `<game>.entitlements` next to it, for the signing step
with your Apple developer certificate (the ad hoc signature cannot carry Game Center or iCloud).

Save games go to the OS per-user data folder (`~/.local/share/<id>`,
`%APPDATA%\<id>`, `~/Library/Application Support/<id>`).

Every run writes its log to `log.txt` in that folder (rewritten on each start): it is the file to ask a player for with a
bug report. On Windows the exe is a GUI program, so the game opens no console window. Started from a terminal it still
prints its log there, but the terminal does not wait for it (`start /wait my-game.exe` does); output redirected to a
file or a pipe works as with any program. If the game cannot start at all (no `game/` folder and no `game.pak` next to the exe, or a
pack that is damaged or from another FactorIA version), a double-clicked exe shows the error in a message box.

**Crash reports.** When the game crashes (a fault such as a write through a null pointer or a stack overflow,
`abort()`, an uncaught C++ exception), the player writes a report next to `log.txt` before it ends, into the `crashes`
folder of the save folder. The newest five are kept.

```
<save folder>/log.txt
<save folder>/crashes/crash-20261017T143052Z.txt     the readable report (the UTC time is in the name)
<save folder>/crashes/crash-20261017T143052Z.dmp     Windows only: a minidump
```

The next start of the game logs one line, "the previous run crashed; the report is ...". Ask a player for the
`crashes` folder together with `log.txt`; nothing is sent anywhere by itself. The `.txt` holds the engine and game
versions, the time, the signal or exception (`access violation, write to 0x0`; for an uncaught C++ exception also its
message), the last log lines, and the stack, innermost call first:

```
exception: 0xc0000005 access violation, write to 0x0
stack (innermost first):
#0  factoria_player.exe!fa::Foo::update + 0x2a  (foo.cpp:51)  [0x7ff75d9d83e2]
#1  factoria_player.exe!fa::Engine::step + 0x1c  (engine.cpp:310)  [0x7ff75d9d889e]
```

A frame shows its function, file and line when the symbols of that build are found (on Windows the `.pdb` next to the
exe or in the symbol path), else only `module+offset`. To read a `.dmp`, open it in Visual Studio (File > Open, then
"Debug with Native Only") or WinDbg (File > Open Crash Dump, then `!analyze -v` and `k`) with the `.pdb` and the source of
the exact build that crashed. On Linux and macOS the stack lines read `module(symbol+0xoffset) [address]` (the address
of a caller is shown one byte back, so that it lies inside the call); `addr2line -f -C -e factoria_player <offset>`
(Linux) or `atos -o <binary> -l <load address> <address>` (macOS) turns an offset into a function and line when the
binary has symbols. The system still does what it did on a crash (exit status, core file, its own crash dialog), and a
stack overflow is reported only on the main thread. Android and iOS write their own crash logs (`adb logcat` and
tombstones; Xcode Organizer), so the player does not install the reporter there. Sending reports to a server is not part
of the engine yet.

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
it. To distribute the game, sign it with your own Developer ID and notarize it (Apple Developer Program): the command
`sign.macos` does it ([Signing and notarizing for macOS](#signing-and-notarizing-for-macos)). The player of the macOS download
is universal (Apple Silicon and Intel).

### Signing and notarizing for macOS

The ad hoc signature above runs on your Mac. To hand the game to other people you sign it with your Developer ID
Application certificate and have Apple notarize it (Apple Developer Program). The command `sign.macos` does every step on
the exported app (MCP tool `sign_macos`, `factoria call sign.macos`, the editor console, `fa.call`; C++:
`fa/tooling/sign.h`, `fa::sign_macos`):

```bash
factoria export --platform macos
factoria call sign.macos '{"identity":"Developer ID Application: Ada Lovelace (ABCDE12345)","keychainProfile":"factoria-notary"}'
factoria call sign.macos '{"dryRun":true}'      # every command line it would run, on any computer
```

1. `codesign` of every piece of native code in `Contents/Frameworks` (the native plugins: frameworks, bundles, helper apps,
   `.dylib` and `.so` files and other Mach-O files), the deepest first, then of the app: `--force --options runtime
   --timestamp --sign <identity>` (the hardened runtime and a secure timestamp are what Apple asks for).
2. With `provisioningProfile`: the profile is copied to `Contents/embedded.provisionprofile` first, and the app is signed with
   the export's `<game>.entitlements` (below).
3. `codesign --verify --deep --strict`.
4. Notarization: the app is zipped with `ditto`, `xcrun notarytool submit --wait` uploads it and waits for Apple's verdict.
   When Apple refuses the app the error quotes `notarytool log` (typically a library that is not signed with the hardened
   runtime and a timestamp, or a file changed after signing).
5. `xcrun stapler staple` and `validate` (the ticket goes into the app, so it opens offline), then `spctl --assess`:
   Gatekeeper's own verdict.
6. `ditto` writes the stapled app to `<out>/<game-slug>-macos.zip`, next to the export folder: the file to share.

Arguments, all optional (`app` and `out` default to the export of this game, `build/export/<game-slug>-macos/<Name>.app`;
`app`, `out` and `zip` stay inside the project like the `fs.*` commands, the files you point the other arguments at may be
anywhere):

| Argument | Meaning |
|---|---|
| `identity` | The certificate: its name (`Developer ID Application: Your Name (TEAMID)`; `security find-identity -v -p codesigning` lists them) or its SHA-1. `"-"` signs ad hoc (no certificate; the app runs on this Mac only and is never notarized). Default: `FACTORIA_MACOS_SIGN_IDENTITY`, then `sign.macos.identity` of `~/.factoria/export.json`; with none the error says so. |
| `keychain` | A keychain file that holds the certificate (and the notary profile). Default: `FACTORIA_MACOS_KEYCHAIN`, then `sign.macos.keychain`, then the user's keychains. |
| `notarize` | Unset: notarize when there are credentials and the identity is a Developer ID Application certificate, else only sign, with a warning that says why. `true`: that is an error instead of a warning. `false`: only sign. |
| `keychainProfile` | A notarytool profile saved once with `xcrun notarytool store-credentials <name>`. Default: `FACTORIA_NOTARY_PROFILE`, then `sign.macos.notaryProfile`. |
| `apiKey`, `apiKeyId`, `apiIssuer` | An App Store Connect API key instead: the `AuthKey_<id>.p8` file, its key id and, for a team key, the issuer id. Defaults: `FACTORIA_NOTARY_API_KEY`, `FACTORIA_NOTARY_API_KEY_ID`, `FACTORIA_NOTARY_API_ISSUER`. |
| `appleId`, `teamId` | An Apple ID instead. Defaults: `FACTORIA_APPLE_ID` / `FACTORIA_APPLE_TEAM_ID` (also `APPLE_ID` / `APPLE_TEAM_ID`). The app-specific password is read from `FACTORIA_APPLE_APP_PASSWORD` (or `APPLE_APP_PASSWORD`) **only**. |
| `provisioningProfile`, `entitlements` | See below. |
| `distribution` | `developerId` (default): the steps above. `appStore`: sign for the Mac App Store and build the `.pkg` ([Mac App Store](#mac-app-store)); never notarized. |
| `installerIdentity` | `appStore` only: the certificate that signs the `.pkg`. Default: `FACTORIA_MACOS_INSTALLER_IDENTITY`, then `sign.macos.installerIdentity`. |
| `pkg` | `appStore` only: where the `.pkg` goes (default: `<game-slug>-macos.pkg` next to the export folder). |
| `zip` | Where the zip to share goes (default: next to the export folder). |
| `dryRun` | Check everything and return the command lines in `steps[]`; sign and send nothing. |

The login for notarytool is the first of: a keychain profile, an API key, an Apple ID. The result is `{app, dryRun,
identity, identityFrom, credentials, signed, verified, notarized, stapled, notarizationId, zip, distribution, pkg,
steps[], warnings[], nextSteps[]}` (`distribution: "appStore"` adds `installerIdentity`, `pkgSigned`, `entitlements` and `profile`); each step is `{title, command, commandLine, ran, exitCode}`. Nothing secret is ever an argument, is in
`factoria.json`, in a result or in a log: the only secret there is, the app-specific password, comes from the environment
and is replaced by `<redacted>` in every step and every line of output. A key file or a keychain profile holds its secret
where Apple's tools keep it.

`~/.factoria/export.json` (this computer only, [Machine settings](#machine-settings-factoriaexportjson)) may carry the
identity, the keychain and the profile name, which are not secrets:

```json
{ "sign": { "macos": { "identity": "Developer ID Application: Ada Lovelace (ABCDE12345)", "notaryProfile": "factoria-notary" } } }
```

**Needs a Mac.** `codesign`, `notarytool` and `stapler` exist only on macOS. Anywhere else a real run is an error that says
so and what to do (copy the export folder to a Mac, or let a macOS CI runner do it: [CI for your game](#ci-for-your-game));
`dryRun: true` always works and prints the commands a Mac would run, with this computer's paths. Export on the Mac too (or
on a macOS CI runner): the export seals the app there, and the files keep their permissions.

**Capabilities that need a profile (Game Center, iCloud).** A native plugin that asks for them makes the export write
`<game>.entitlements` next to the app, with a `TEAMID` placeholder. macOS kills an app that claims such an entitlement
without a provisioning profile for its App ID, so `sign.macos` applies that file **only** together with `provisioningProfile`
(the `.provisionprofile` you create in the Apple Developer portal for the App ID, with the same capabilities). Without a profile
the app is signed without them and the result warns that those services will answer "unavailable". Replace `TEAMID` with your
10-character Team ID first (or set `export.ios.teamId` in `factoria.json` and export again): `sign.macos` refuses a file that
still has the placeholder. `entitlements` signs the app with a file of your own instead.

**Every export replaces the app**: sign again after each `project.export`. An app that is changed after it is signed
(a file added to the bundle) is no longer valid; export and sign again instead of editing it.

### Mac App Store

To sell the game on the Mac App Store the app is signed another way: with the **App Sandbox**, with a distribution
certificate instead of Developer ID, with a provisioning profile, and wrapped in a signed installer `.pkg` that
[`publish.appstore`](#app-store-connect-testflight) uploads. `sign.macos` does it with `distribution: "appStore"`
(Apple Developer Program):

```bash
factoria export --platform macos --release
factoria call sign.macos '{"distribution":"appStore","identity":"Apple Distribution: Ada Lovelace (ABCDE12345)","installerIdentity":"3rd Party Mac Developer Installer: Ada Lovelace (ABCDE12345)","provisioningProfile":"keys/MyGame_MAS.provisionprofile"}'
factoria call publish.appstore '{"platforms":["macos"]}'
```

What you set up by hand first, in the Apple Developer portal (the commands cannot): the App ID of the game (`id` of
`factoria.json`) with its capabilities, an **Apple Distribution** (or "3rd Party Mac Developer Application") certificate, a
**Mac Installer Distribution** (or "3rd Party Mac Developer Installer") certificate, both in your keychain, and a **Mac App
Store provisioning profile** for the App ID (download the `.provisionprofile`). Create the app in App Store Connect too.

The steps (`factoria call sign.macos '{"distribution":"appStore","dryRun":true}'` lists them on any computer):

1. The provisioning profile is read (`security cms -D`): `sign.macos` refuses it when it is expired, does not cover the
   bundle id of `Info.plist`, or does not hold the sandbox's identifiers, and warns when it is not a Mac App Store profile.
2. `lipo -archs` of the executables: a warning when the game is `x86_64` only (App Store Connect expects arm64 to be
   there) or a plugin lacks an architecture of the app.
3. The entitlements are written next to the export folder (`<game-slug>-macos.appstore.entitlements`, and
   `-appstore-inherit.entitlements` for helpers): `com.apple.security.app-sandbox`, those that native plugins ask for,
   the `export.macos.entitlements` extras (`com.apple.security.network.client` for online games,
   `com.apple.security.files.user-selected.read-write` for saves the player chooses, ...), and the identifiers taken from
   the profile (`com.apple.application-identifier`, `com.apple.developer.team-identifier`). The sandbox is mandatory:
   an `entitlements` file of your own without it is refused.
4. Everything in `Contents/Frameworks` is signed with the same identity and `--timestamp`, but **without** the hardened
   runtime (the store does not use it): a helper app, XPC service or tool gets the inherit entitlements
   (`app-sandbox` + `inherit`) so it runs inside the sandbox of the app.
5. The profile is embedded as `Contents/embedded.provisionprofile` and the app is signed with the entitlements.
6. `codesign --verify --deep --strict`, then the entitlements are read back from the signature (`codesign -d
   --entitlements`) and the sandbox must be there.
7. `productbuild --component <app> /Applications --sign <installer identity> <game-slug>-macos.pkg`, then
   `pkgutil --check-signature`.

There is no notarization (the store reviews the app) and no zip. A real run needs a Mac with `codesign`,
`productbuild` and `lipo`. The identity comes from the `identity` argument, then `FACTORIA_MACOS_APPSTORE_IDENTITY`,
then `sign.macos.appStoreIdentity`; a Developer ID certificate is an error here (the store refuses it), and so is a
distribution certificate without `distribution: "appStore"`. The installer certificate comes from `installerIdentity`,
`FACTORIA_MACOS_INSTALLER_IDENTITY`, `sign.macos.installerIdentity`; without it the `.pkg` is built **unsigned** with a
warning (it can be signed later with `productsign`). `provisioningProfile` is required except for `identity: "-"`.

**Trying it here.** `{"distribution":"appStore","identity":"-"}` signs ad hoc with the sandbox: no certificate or profile,
so the app is not accepted by the store and the entitlements that need a profile (plugins') are left out, but the app
**runs sandboxed on this Mac** (its files go to `~/Library/Containers/<bundle id>`), which is the way to find what the
sandbox breaks: saving beside the executable, opening arbitrary paths, network (needs `network.client`). The engine's own
test does exactly that and runs the signed export.

**Other stores.** The sandboxed build is meant for the Mac App Store. Steam and itch.io take the `developerId` build (a
sandboxed game cannot use the Steam client's libraries); `sign.macos` warns when the app carries the Steam, Epic or GOG
plugin, which do not belong in a Mac App Store build.

`publish.appstore` takes the `.pkg` as an artifact: `{"platforms":["macos"]}` or `{"artifact":"build/export/mygame-macos.pkg"}`
(`.ipa` and `.pkg` both present: say which), through `xcrun altool --upload-package <pkg> --type macos --apple-id ...
--bundle-id ... --bundle-version <build> --bundle-short-version-string <version>`, with the same API key as for iOS.
**Not tested against a real upload** (it needs a paid account), and `--type macos` is not verified on the newest Xcode:
if `altool` refuses it, upload the `.pkg` with Apple's Transporter app.

### Linux: AppImage

`--format appimage` also builds the game as **one file** that runs on most Linux desktops without installing anything: the
folder of the Linux export stays, and `<out>/<game-slug>-linux/<game-slug>-x86_64.AppImage` is added next to its files
(reported as `artifact`).

```bash
factoria setup appimage                                    # once: appimagetool and the AppImage runtime (about 16 MB)
factoria export --platform linux --format appimage         # the command: project.export {"platform":"linux","format":"appimage"}
./build/export/my-game-linux/my-game-x86_64.AppImage       # or with --appimage-extract-and-run on a computer without FUSE
```

- **Where it can be built.** On Linux x86_64, or in WSL (Ubuntu) on Windows: `appimagetool` is an x86_64 Linux program. On a Mac,
  Windows or an ARM Linux the export refuses before it writes anything, with an error that says to export on Linux or in WSL;
  without `--format` the Linux export works from any computer and writes the folder (`tar czf` it to share). A CI job can
  build it too ([CI for your game](#ci-for-your-game) exports the folder; add a `factoria setup appimage` step and
  `--format appimage` to its Linux export step).
- **The tools come from `factoria setup appimage`**, never from the export (it downloads nothing): appimagetool 1.9.1 and the
  type 2 runtime 20251108 from `github.com/AppImage`, each checked against a SHA-256 that is compiled into FactorIA (the same
  files and hashes `scripts/package-appimage.sh` packs FactorIA's own AppImage with). They live in
  `<FactorIA home>/tools/appimage/`. Without them the export says to run the setup; `setup.status` lists the component as
  `appimage` (`unsupported` away from Linux x86_64).
- **The AppDir.** Beside the export folder (and removed again, whatever happens) the export builds
  `.<game-slug>-linux.AppDir/` with `AppRun` (starts `usr/bin/<game-slug>`), `<game-slug>.desktop` (the export's entry with
  `Icon=<game-slug>` and `X-AppImage-Version` from the game's `version`), `<game-slug>.png` and `.DirIcon` (the game's icon; a
  plain placeholder and a warning when the game has none) and `usr/bin/` holding the export folder as it is: the player, `game/`,
  `FACTORIA_NOTICES.txt` and the native plugins' libraries. The player finds `game/` and the plugins next to its executable, so
  the layout needs no change. Then it runs
  `ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 appimagetool --no-appstream --runtime-file <runtime> <AppDir> <AppImage>`
  (`APPIMAGE_EXTRACT_AND_RUN` lets the tool run where FUSE is missing: CI, containers, WSL).
- **Running it.** `chmod +x` (the export already does), or **Allow executing as a program** once in a file manager. A
  computer without FUSE 2 starts it with `--appimage-extract-and-run`. The game uses the system's X11, OpenGL and ALSA, and
  needs a glibc at least as new as the player's: the FactorIA download is built on Ubuntu 24.04, so an older distribution may
  refuse it. Save games and `log.txt` go where the folder export puts them.
- **If appimagetool fails** the error quotes what it printed (often a `.desktop` validation: `export.linux.categories`) and the
  export folder stays, complete without the AppImage; fix it and export again.
- **Flatpak is not generated.** An AppImage needs nothing but the file; Flatpak needs a manifest, a runtime and a store
  review. A game that wants it can wrap the folder export.

### Release build (`game.pak`)

`factoria export --release` (or `project_export {"release": true}`) for Linux, Windows and macOS ships the game as ONE
read-only file instead of a `game/` folder of loose files:

```
linux/windows:  my-game-windows/            my-game.exe  game.pak  FACTORIA_NOTICES.txt
macOS:          My Game.app/Contents/       MacOS/my-game  Resources/game.pak  Info.plist ...
```

Every file listed under [What is shipped](#what-is-shipped-and-what-is-not) goes into the pack as it is (textures, sounds and
fonts are already compressed, so nothing is compressed twice), except the scripts, which can be compiled
([below](#scripts-as-bytecode)). Nothing of the game is left loose: a game of thousands of small files is copied, zipped and
installed as one file, and the player of the game cannot swap a texture or edit a script by opening a folder. (This is packaging,
not protection: anyone who knows the format can read the pack, and the bytecode of a script can be decompiled.) The report has
`pack` (`game.pak`) and `packed` (every path inside it); its `files` lists what is on disk.

**How the player uses it.** It looks for `game/` next to the executable first (so a folder always wins, which makes it easy to
try a changed file), then for `game.pak`; `factoria_player path/to/game.pak` runs a pack from anywhere. It mounts the pack into
the virtual file system the whole engine reads through (`fa::fs::mount_pack`, [ARCHITECTURE.md](ARCHITECTURE.md)): `factoria.json`, scenes,
prefabs, textures, sounds, fonts, scripts, `import`s and the window icon all come out of it, and a game that works from the folder
works from the pack. Only the index (the list of paths with their offsets) is read at start; a file is read from disk when the
game asks for it, and any number of threads can read at once, so a large pack starts as fast as a small one. While a pack is
mounted, a project-relative path that is not in it is "File not found" with a "did you mean" taken from the pack, whatever lies
on disk. Absolute paths and everything the game writes are not affected: save games go to the per-user data folder as always,
and a file written with a project-relative path lands in the (absent) `game/` folder next to the pack.

**Format** (version 1, integers little-endian; `fa/core/pack.h` is the reference and holds the `fa::PackWriter` and `fa::PackReader`):
a 16-byte header (`FAPACK\r\n`, `u32` version, `u32` reserved), the files' bytes back to back, an index (`u32` count, then per file,
sorted by path: `u16` path length, the UTF-8 path, `u64` offset, `u64` size) and a 24-byte footer (`u64` index offset, `u64` index
size, `FAPKEND!`). The reader finds the index through the footer, so a pack that was cut short (an interrupted download, a full
disk) is refused with a message that says to export again, never half-read, and the writer builds `game.pak.tmp` and renames it, so
an export never leaves a half-written pack under the real name. A pack with another format version says which version it has and
which this FactorIA reads.

#### Scripts as bytecode

With `export.scriptBytecode` on (the default; set `"export": { "scriptBytecode": false }` in `factoria.json` to turn it off), the
`.js` and `.mjs` files go into the pack compiled to QuickJS bytecode, with the QuickJS of the player that ships with the game. They keep
their paths (`scripts/player.js`), so `Script` components, `import`s between scripts and JSON imports are unchanged, and a pack can
mix compiled and plain scripts. The source text is not shipped, but the file names and line numbers are: an error in the
shipped game still reads `scripts/player.js:12:7: TypeError: ...` and the log and `script.errors` give the same file and line as in
development. Loading a compiled script skips parsing, so large scripts start faster.

Bytecode only runs on the FactorIA that wrote it. Each compiled script carries the FactorIA and QuickJS versions, and a game that
meets a script from another one says so instead of crashing:

```
'scripts/player.js' was compiled by FactorIA 0.1.5; QuickJS 0.17.0, but this game runs FactorIA 0.1.6; QuickJS 0.17.0, and compiled
scripts only run on the version that wrote them (hint: Export the game again with this FactorIA version (`factoria export --release`);
export.scriptBytecode: false in factoria.json ships the scripts as plain source instead.)
```

The export copies the player of its own FactorIA, so a pack and its player always match; a mismatch happens when you pass another
`--player`, or put a pack next to a player of another version. `false` packs the scripts as the source they are (readable, and
independent of the player's version). A script that has a syntax error is packed as source with a warning that names the file and
line, so the game behaves as it does from the folder: the error shows when something loads that script (`factoria validate` lists
them before you export). Without `--release`, and on Android and iOS, the setting changes nothing.

Not shipped, so not compiled: `tools/` (JS tool modules, which are for development) and `tests/`. The player never reloads
files while it runs (hot reload belongs to `factoria run` and the editor, which work on the project folder), and a compiled module keeps
the name it was compiled under, so a pack is a fixed game: change a script, export again.

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
  the game lives in (it rewrites them to absolute paths and copies the file to `~/.local/share/applications`). The
  [AppImage](#linux-appimage) carries the same entry, with `Icon=<name>` and the game's version.

Windows: the player of a release download carries FactorIA's signature once the release is signed
([BUILDING.md](BUILDING.md), "Releasing"), and one built from source is not signed. Writing the game's icon and version
information edits the exe, which invalidates a signature, so the export removes it (the certificate table at the end of
the file) and says so in the report: an exe with the wrong signature is worse than an unsigned one. Only a player
without the placeholders is copied byte for byte, signature included. SmartScreen may warn about an unsigned exe; sign
the exported exe with `signtool` to publish under your own name:

```
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 /a my-game.exe
```

## Web

`factoria export --platform web` writes a game that runs in a browser (WebGL2 and WebAssembly). The player is the engine
compiled with Emscripten (`factoria_player.js` + `factoria_player.wasm`); the game travels in ONE `game.pak`, like a
desktop [release build](#release-build-gamepak) (scripts as bytecode unless `export.scriptBytecode` is false), whether or
not you pass `--release`.

```bash
factoria export --platform web                    # build/export/<slug>-web/ and build/export/<slug>-web.zip
factoria export --platform web --player path/to/web-player-folder
```

```
build/export/
  my-game-web/                 the folder: any web host serves it as it is
    index.html                 the loading page (progress for the wasm and the pack), then the game
    factoria_player.js         the Emscripten glue
    factoria_player.wasm       the engine
    game.pak                   the whole game
    FACTORIA_NOTICES.txt       the licenses of the engine inside the game ([License notices](#license-notices))
    .factoria-export           marker (see Replacing an earlier export); not in the zip
    AI_CONTENT_DISCLOSURE.md   only for a game with AI-made assets; not in the zip
  my-game-web.zip              the same files with index.html at the root of the zip
```

**Trying it.** A browser does not run `index.html` from a file (it fetches the wasm and the pack), so serve the folder
over http, e.g. `python -m http.server 8080 --directory build/export/my-game-web` and open `http://localhost:8080/`. The
export prints this command as its first next step.

**itch.io.** The zip is what itch.io takes as an HTML5 game: create a project of kind *HTML*, upload `my-game-web.zip`,
tick *This file will be played in the browser* and set the viewport size (itch.io's page for HTML5 games lists the
limits the export checks and warns about: at most 1000 files, 500 MB unpacked, 200 MB for one file, paths of at most
240 characters). Any other web host serves the folder: send `.wasm` as `application/wasm` (almost every host does).
`factoria publish` does not push the web export yet; upload the zip by hand or run
`butler push build/export/my-game-web.zip <user>/<game>:html5`.

**Where the player comes from.** The export looks, in this order, for a folder holding both `factoria_player.js` and
`factoria_player.wasm`:

1. `--player <folder>` (or the path of `factoria_player.js`; the CLI only. The editor and `project.export` use 2 to 4).
2. `web/` next to the `factoria` binary: every FactorIA download has it, like `mobile/`.
3. The one `factoria setup players --platforms web` installed (`<FactorIA home>/players/<version>/web/`, taken from the
   download of this machine's own OS; a factoria that has `web/` next to it never needs it).
4. A web build of the engine source: `build/web-release/player/` (or `build/web/player/`) in the checkout factoria was
   built from ([BUILDING.md](BUILDING.md)). A build directory elsewhere: pass its `player/` folder with `--player`.

Without `--player` the export looks at 2, then the checkout's build (4), then 3, and takes the first whose build
fingerprint is this factoria's: a fresh `build/web-release` wins over an installed player of an older release. When none
matches it takes the first one it found and stops on the mismatch, as for every player (see "The player must come from the
same build as `factoria`" under Desktop; `--player` is checked too). The error names both builds and says to build the web
player in the checkout (`cmake --build --preset web-release`), to run `factoria setup players --platforms web`, or to pass
`--allow-player-mismatch`. If a player that lacks something still reaches the browser, the script error names the module and
the missing export and says the player may be older than the game's engine.

With none of them the export stops before writing anything and says which folders it looked in and the command that fixes
it. `--json` and the plan (`dryRun`) report where the player came from as `mode` (`explicit`, `package`, `installed` or
`build`), the `factoria_player.js` used as `player`, and the zip as `artifact` (`format` is `zip`).

**The page.** `index.html` is `platforms/web/shell.html`, embedded in the factoria binary, with `{{title}}` (the game's
`name`, HTML-escaped), `{{wasmBytes}}` and `{{pakBytes}}` (the sizes of the two downloads, for the progress bar when the
server sends no `Content-Length`) replaced. A placeholder this factoria does not know stays as it is, with a warning.

**What differs from the other exports.**

- **Textures** stay PNG (the `auto` compression is `none`, as on desktop): WebGL2 guarantees no compressed format (ASTC
  and ETC2 are mostly phones, BC7 mostly desktops, and a browser tells the page only at run time), so a KTX2 file would be
  decoded to RGBA in the browser anyway. A texture can still ask for `"compression": "uastc"` in its import settings.
  Atlas pages are at most 2048 px, like on phones: browsers run there too.
- **Audio** is not changed by the web: WAV, OGG and QOA all decode in the player. Prefer OGG or QOA for long sounds, since
  every byte is downloaded before the game starts.
- **Typing.** Typed text reaches the game from the browser's `keypress` events, so it needs a real keyboard (or events a
  browser treats as typed; a browser pane's synthetic key events may only send `keydown`, and then letters do not appear).
  On a phone or tablet, a `TextField` with focus makes the browser show its keyboard through a hidden `<input>`; iOS Safari
  may need a second tap on the field. Details: [TEXT.md](TEXT.md#typing-text). A gamepad alone types with the on-screen
  keyboard of [MENUS.md](MENUS.md).
- **No icon** and no `export.web` settings: the page and the browser tab are the game's face. The `platforms` list of
  `factoria.json` is not checked for `web`.
- **Size** is the cost of the web: the wasm player plus the whole pack is downloaded before the first frame. `factoria
  validate` already warns about big files; the zip is deflated, so a host that compresses (gzip, brotli) saves little more.

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
  app/src/main/AndroidManifest.xml NativeActivity + android.app.lib_name=factoria_player, orientation, icon, permissions, hasCode
  app/src/main/res/values/strings.xml   app name
  app/src/main/res/mipmap-*/       launcher icons made from the project's icon (and the adaptive icon)
  app/src/main/assets/             the game + assets_index.txt
  app/src/main/jniLibs/<abi>/libfactoria_player.so   prebuilt mode only: the engine
  plugins/<name>/                  native plugins: the Gradle module of each plugin's android/ folder
  app/libs/<name>/                 native plugins: the .aar / .jar files of a plugin that has no module
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

**Native plugins** ([EXTENDING.md](EXTENDING.md), section G). A plugin declared for `android` needs an `android/` folder in
its own folder: a Gradle library module (`build.gradle` or `build.gradle.kts`, with the plugin's `lib<name>.so` for
`arm64-v8a` and `x86_64` in `src/main/jniLibs/<abi>/` and any Java or Kotlin code) or `.aar` / `.jar` files. The export
copies a module to `plugins/<name>` (without its `build/`, `.gradle/` and `.cxx/`) and adds it to `settings.gradle` and
to the app's dependencies; `.aar` / `.jar` files go to `app/libs/<name>`. The module reads `factoria.compileSdk` and
`factoria.minSdk` from `gradle.properties`, which the export writes from `targetSdk` and `minSdk`. `android:hasCode` is
`false` unless a plugin brings code (Java / Kotlin sources or archives). The Gradle project sets `android.useAndroidX=true`,
which the Google SDKs of a plugin (Play Billing, Play Games) need. A plugin folder inside the project never ships
as game files. A plugin without an Android build fails the export and says what to put in `android/`. Building the
library, calling Java from C, `hasCode` and the details: [MOBILE.md](MOBILE.md#native-plugins-on-android).

**Platform settings** that change the project: `minSdk` / `targetSdk` (`compileSdk` follows `targetSdk`), `versionCode`,
`permissions` (extra `<uses-permission>` lines), the `icon` (launcher icons and adaptive icon, in the manifest as `icon` and
`roundIcon`; without one the platform default and a warning) and `signing`. See [Platform settings](#platform-settings).

**Signing**. A debug build is signed with the debug key of the machine (fine for trying the app). `--release` signs with the
keystore of `export.android.signing` (`keystore`, `alias`; a project-relative path is resolved against the project and the
file is never copied into the app). The passwords are never written to a project, a file of the export or a command line:
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
- **The privacy manifest.** `PrivacyInfo.xcprivacy` is written next to `build_ios.sh` (`FA_GAME_PRIVACY_MANIFEST`) and copied
  to the root of the app: the engine's required-reason APIs (file time stamps, the monotonic clock), no tracking, no collected
  data. `export.ios.privacy` adds what the game or its plugins do. `Info.plist` also gets `ITSAppUsesNonExemptEncryption`
  (`false`; `export.ios.usesNonExemptEncryption` changes it). What to put in both, and in Google Play's Data safety form:
  [MOBILE.md](MOBILE.md#store-privacy-forms).
- **Plugin entries in `Info.plist`.** A plugin's `ios/plugin.json` can ask for Info.plist keys (`infoPlist`) and vendored
  XCFrameworks (`xcframeworks`); the AdMob plugin adds `GADApplicationIdentifier`, `SKAdNetworkItems` and, with
  `platform.ads.trackingPrompt`, `NSUserTrackingUsageDescription` (one `InfoPlist.strings` per language of the game when
  `platform.ads.trackingDescriptionKey` is set). [MOBILE.md](MOBILE.md#native-plugins-ios).

**Native plugins** ([EXTENDING.md](EXTENDING.md), section G). Each plugin declared for iOS needs `ios/iphoneos/lib<name>.a` and
`ios/iphonesimulator/lib<name>.a`; the export copies its `ios/` folder to `plugins/<name>/` and the app links it
([MOBILE.md](MOBILE.md#native-plugins-ios)). The plugin's `ios/plugin.json` (system frameworks, Swift, entitlements) makes
`build_ios.sh` link those frameworks and the Swift runtime, and the export writes `factoria_player.entitlements` next to
it; when the catalog has products it also writes `Products.storekit` (with or without a store plugin), which the
Xcode scheme uses to sell the products when the project runs from Xcode, with one localization per language of the game
([PLATFORM.md](PLATFORM.md#6-apple-storekit-2-game-center-and-icloud)).

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

Details in [MOBILE.md](MOBILE.md).

## Uploading to stores

Seven commands upload a build to a store with the store's own uploader: four for the desktop exports, three for the packages
(mobile builds and the MSIX). They are commands like `project.export` (MCP tools `publish_steam`, `publish_itch`, `publish_epic`, `publish_gog`,
`publish_appstore`, `publish_googleplay`, `publish_microsoft`; also `factoria call publish.steam '{"dryRun":true}'` and the editor console), so an
AI can ship a build. FactorIA writes the
build files and runs the tool; it never downloads or installs the tool, never takes a password, and never writes a secret
to a file of the project.

| Command | Uploader | One upload per platform goes to |
|---|---|---|
| `publish.steam` | `steamcmd` | a depot of your Steam app (all depots in one build) |
| `publish.itch` | `butler` | a channel of your itch.io page |
| `publish.epic` | `BuildPatchTool` (`-mode=UploadBinary`) | an artifact of your Epic product |
| `publish.gog` | `GOGGalaxyPipelineBuilder build-game` | a GOG build of your product |
| `publish.appstore` | `xcrun altool --upload-package` (macOS only) | App Store Connect / TestFlight: the one `.ipa` |
| `publish.googleplay` | `fastlane supply` | a track of your app in Google Play: the one `.aab` |
| `publish.microsoft` | `msstore` (Microsoft Store Developer CLI) | a submission of your app in Partner Center: the one `.msix` |

The first four upload the folders `project.export` wrote: `<project>/build/export/<game-slug>-<platform>` for `windows`,
`macos` and `linux`. Export every platform first (`project_export {"platform":"windows"}`, ...). The mobile builds are one
file each, not a folder: see [App Store Connect (TestFlight)](#app-store-connect-testflight) and
[Google Play](#google-play) below. Everything in a desktop export is uploaded (the game, `FACTORIA_NOTICES.txt`, which must stay) except `.factoria-export` and `AI_CONTENT_DISCLOSURE.md`,
which belong to the export, not to the game. Show the AI content disclosure on the store page by hand when the game needs
it ([AI content disclosure](#ai-content-disclosure)).

Arguments (all optional; every command has `dryRun`):

| Argument | Meaning |
|---|---|
| `platforms` | `["windows","macos","linux"]` (`win`, `mac`, `osx` also work). Default: every platform that has an export folder and is set up for this store in `factoria.json`; the others are skipped with a warning. Naming one that is not ready is an error. |
| `out` | Parent folder of the exports, inside the project (default `build/export`, the `out` of `project.export`). |
| `folders` | `{"windows": "dist/win"}`: upload another folder (inside the project) for a platform. Wins over `out`. |
| `dryRun` | `true`: write the build files and return the exact command lines and what would be uploaded where. Nothing is started or sent. A missing uploader, secret, account or id (the Steam app id, the Epic ids...) is a warning, not an error: the plan is returned with the missing value shown as a placeholder (`MISSING_...`, and the tool's bare name), so you see the steps before you set anything up. |
| `account`, `appId`, `branch` | `publish.steam` only: the Steam account (default `publish.steam.account`), the app id (default the number in `steam_appid.txt`) and the beta branch to set live (default `publish.steam.branch`). |
| `branch` | `publish.gog` only: the GOG branch to put the build on (Pipeline Builder `--branch`). |
| `artifact` | `publish.appstore`, `publish.googleplay` and `publish.microsoft` only: the `.ipa` / `.aab` / `.msix` to upload, inside the project (the MSIX default is `<out>/<slug>-windows.msix`). They take no `platforms` or `folders`. |
| `track`, `releaseStatus` | `publish.googleplay` only: the release track (`internal`, `alpha`, `beta`, `production`, or a closed testing track) and `draft` or `completed` (default `publish.googleplay.track` / `.releaseStatus`, else `internal` and `draft`). |

The result is `{store, dryRun, uploaded, version, tool, toolFrom, uploads, steps, files, warnings, nextSteps}` plus, after
a real run, `exitCode` and `log`. `uploads` has one entry per platform: `{platform, folder, destination, files, bytes,
uploaded}`: what goes where. `steps` has one entry per run of the uploader: `{title, command, commandLine, files, ran,
exitCode}` (the command line with every secret replaced by `<redacted>`). `files` are the build files written. The
version is the game's `version` of `factoria.json` (`0.1.0` when it has none). While a tool runs, every line of its output
is written to the engine log as it comes (category `publish.<store>`: stderr of `factoria call` and `factoria mcp`, the editor
console) and kept in `<project>/.factoria/publish/<store>.log`, with secrets replaced by `<redacted>`. A tool that exits with an error is not a crash: the command fails with the exit code,
the last lines of its output, the log path and what to check, and the error's `data` is the same report, so the AI can see
which platforms were uploaded before the failure (the run stops at the first failing upload).

```
publish_itch {"dryRun":true}
publish_steam {"platforms":["windows","linux"],"branch":"beta"}
publish_epic {"platforms":["windows"]}
publish_gog {"branch":"testing"}
publish_appstore {"dryRun":true}
publish_googleplay {"track":"internal","releaseStatus":"draft"}
publish_microsoft {"dryRun":true}
```

Always run the dry run first; it also checks the tool, the ids and the exports, and it shows the files written to
`<project>/.factoria/publish/<store>/` (the Steam `.vdf` scripts, the GOG project files, the ignore list of Epic and GOG). The build
files are rewritten on every call; do not commit `.factoria/`. (Epic's `cloud` folder there is the tool's chunk cache: keep it between uploads.)

### What you set up by hand first

FactorIA cannot create your pages, products or credentials. Each store has something to do once on its partner site:

- **Steam**: a Steamworks account and an app with an app id; one depot per platform (App Admin > SteamPipe > Depots) and the
  depots added to a package of the app; a build account with the *Edit App Metadata* permission for the app
  (Users & Permissions; the Steamworks upload page names it); the launch options of each depot (App Admin > Installation > General) after the first upload.
  Put the app id in `steam_appid.txt` (`platform.add_backend {"backend":"steam","appId":<id>}` writes it). Docs:
  <https://partner.steamgames.com/doc/sdk/uploading>.
- **itch.io**: an account and a page for the game (the address `mystudio.itch.io/space-dodge` makes the game
  `mystudio/space-dodge`); the page can stay a draft. Docs: <https://itch.io/docs/butler/>.
- **Epic Games Store**: a Dev Portal organization and product, one artifact per platform (Artifacts and Binaries), and a
  Build Patch Tool client with its secret (Product Settings > General). Docs:
  <https://dev.epicgames.com/docs/epic-games-store/publishing-tools/uploading-binaries/bpt-instructions-160>.
- **GOG**: a product with its product id in the GOG Developer Portal, and Pipeline Builder access for your account. Docs:
  <https://docs.gog.com/pb-quick-start/> and <https://docs.gog.com/pb-build-game/>.
- **App Store Connect**: an Apple Developer Program membership, the app (My Apps > +, with the bundle id of the game's `id`),
  and an App Store Connect API key ([App Store Connect (TestFlight)](#app-store-connect-testflight)).
- **Google Play**: a Play Console developer account, the app (with the game's `id` as its package name), the **first bundle
  uploaded by hand**, and a service account with access to the app ([Google Play](#google-play)).

### Store ids: `publish` in `factoria.json`

The ids of the game in the stores go in the `publish` object of `factoria.json` (checked by `factoria validate`, like
`export`). None of them is a secret. Every wrong value is an error naming the JSON pointer and the fix; an unknown key is a
warning with a "did you mean".

```json
"publish": {
  "steam": { "account": "mystudio_build", "depots": { "windows": 1234561, "macos": 1234562, "linux": 1234563 }, "branch": "beta" },
  "itch": { "game": "mystudio/space-dodge", "channels": { "windows": "windows", "macos": "mac", "linux": "linux" } },
  "epic": { "organizationId": "o-abc123", "productId": "0123abcd", "clientId": "xyz",
            "artifacts": { "windows": "<artifact id>", "macos": "<artifact id>", "linux": "<artifact id>" } },
  "gog": { "productId": "1234567890", "clientId": "5555", "languages": ["en-US", "fr-FR"] },
  "appstore": { "appleId": "6448277777" },
  "googleplay": { "track": "internal", "releaseStatus": "draft", "changelogs": { "en-US": "store/whats-new-en.txt" } }
}
```

| Field | Meaning |
|---|---|
| `steam.account` | Name of the Steam build account that uploads. Its password is not stored anywhere in the project. |
| `steam.depots` | `{platform: depot id}`. A platform without a depot is not uploaded. |
| `steam.branch` | Beta branch the build is set live on after the upload. Optional; `default` is refused: make a build default by hand in Steamworks. Without a branch the build is uploaded but not live. |
| `itch.game` | `user/game` of the page, lower case, as in its address. |
| `itch.channels` | `{platform: channel}`. Default `windows`, `mac`, `linux`. itch.io tags a channel's download by its name (`windows`, `osx` or `mac`, `linux`); add suffixes such as `windows-beta` for a test channel. |
| `epic.organizationId`, `epic.productId`, `epic.clientId` | From the Dev Portal. The client is the Build Patch Tool credential. |
| `epic.artifacts` | `{platform: artifact id}`. A platform without an artifact is not uploaded. |
| `gog.productId` | The product id of the game in the GOG Developer Portal. |
| `gog.clientId` | GALAXY client id of the product (optional). |
| `gog.languages` | Locale codes of the game's languages. Default `["en-US"]`. |
| `appstore.appleId` | The app's Apple ID: the number under App Store Connect > your app > App Information > General Information (about ten digits; not the e-mail of your account). The bundle id is the game's `id`. |
| `googleplay.track` | `internal` (default), `alpha`, `beta`, `production`, or the name of a closed testing track. The package name is the game's `id`. |
| `googleplay.releaseStatus` | `draft` (default: the release waits in the Play Console until you roll it out) or `completed` (it rolls out at once). |
| `googleplay.changelogs` | `{Play language: file}`, e.g. `{"en-US": "store/whats-new-en.txt"}`: the release notes, plain text files of the project, 1 to 500 characters each. Default: none uploaded. |

Store ids are copied from the partner sites as text or numbers. Unknown platforms are rejected with a "did you mean"
(`windws` -> `windows`), and `android` and `ios` with the reason.

### Secrets: environment variables and `~/.factoria/`

A secret is never read from `factoria.json`, never written to a file of the project, never shown in a result, a progress line
or a log (the value is replaced by `<redacted>`), and never placed on a command line unless the uploader leaves no other way.

| Store | Secret | Where it comes from |
|---|---|---|
| Steam | the account password and the Steam Guard approval | not given to FactorIA: run `steamcmd +login <account>` once in a terminal; steamcmd keeps the login (`config/config.vdf`) and the next run needs no password. |
| itch.io | the API key | `butler login` once (butler keeps it in its own config folder), or the environment variable `BUTLER_API_KEY`. |
| Epic | the client secret | the environment variable `FACTORIA_EPIC_CLIENT_SECRET`. It reaches the tool in its environment and the command line only names the variable (`-ClientSecretEnvVar=FACTORIA_EPIC_CLIENT_SECRET`). |
| App Store Connect | the API key | a `.p8` file outside the project: `FACTORIA_APPSTORE_API_KEY` is its path, `FACTORIA_APPSTORE_API_KEY_ID` its Key ID and `FACTORIA_APPSTORE_API_ISSUER` the Issuer ID (`FACTORIA_NOTARY_API_KEY`, `_KEY_ID`, `_ISSUER` of [`sign.macos`](#signing-and-notarizing-for-macos) work too). The file is never read, copied or shown: altool finds it in the folder named by its own `API_PRIVATE_KEYS_DIR`. |
| Google Play | the service account key | a JSON file outside the project: `FACTORIA_GOOGLEPLAY_JSON_KEY` (or fastlane's `SUPPLY_JSON_KEY`) is its path. FactorIA checks that it is a service account key and passes the path to fastlane; the content is never shown. |
| GOG | the GOG account | the sign-in Pipeline Builder cached (run it once by hand), or `FACTORIA_GOG_USERNAME` and `FACTORIA_GOG_PASSWORD` (both or neither). Pipeline Builder only accepts the password as an argument, so it is visible in the process list while the upload runs; the shown command line has it replaced by `<redacted>`. |

### Finding the tools

FactorIA looks for each uploader, in this order: the environment variable (the executable, or the folder that holds it), the
`publish` object of `~/.factoria/export.json` ([Machine settings](#machine-settings-factoriaexportjson)), then `PATH`. When it
finds none the command fails with the store's download page, the variable and the key to set; nothing is downloaded.

| Tool | Environment variable | Key in `~/.factoria/export.json` `publish` | Download |
|---|---|---|---|
| steamcmd | `FACTORIA_STEAMCMD` | `steamcmd` | <https://developer.valvesoftware.com/wiki/SteamCMD> |
| butler | `FACTORIA_BUTLER` | `butler` | <https://itch.io/docs/butler/installing.html> |
| BuildPatchTool | `FACTORIA_BUILDPATCHTOOL` | `buildPatchTool` | the Dev Portal (Build Patch Tool page of the docs above) |
| GOGGalaxyPipelineBuilder | `FACTORIA_GOG_PIPELINE_BUILDER` | `galaxyPipelineBuilder` | <https://docs.gog.com/pb-quick-start/> |
| xcrun (Xcode; altool is part of it) | `FACTORIA_XCRUN` | `xcrun` | Xcode from the Mac App Store, then `xcode-select --install` |
| fastlane | `FACTORIA_FASTLANE` | `fastlane` | <https://docs.fastlane.tools/getting-started/android/setup/> (`gem install fastlane` or `brew install fastlane`) |

```json
{ "format": "factoria.export-config/1", "publish": { "steamcmd": "C:/Tools/steamcmd/steamcmd.exe", "butler": "~/butler" } }
```

### Steam

`publish.steam` writes `app_build_<appid>.vdf` and one `depot_build_<depot>.vdf` per platform into
`.factoria/publish/steam/`, then runs `steamcmd +login <account> +run_app_build <app_build.vdf> +quit`. A depot's content
root is the export folder of its platform, mapped as `"*"` to the depot's root, recursively, without the two export marker
files. The build description is `<name> <version>`. With a `branch` the app script has `SetLive` and the build becomes the
current build of that beta branch; without one the build is only uploaded.

Things to know:

- Steam keeps the executable bit of a file only when the upload runs on macOS or Linux: upload the `macos` and `linux` depots
  from that OS. An export made on Windows has no executable bit to keep. This is a Steamworks rule, not FactorIA's.
- After the first upload set each depot's launch option in Steamworks (the result's `nextSteps` lists the file for each platform).
- The app id 480 (Valve's test app, Spacewar) is refused in a real upload. A dry run accepts it and warns, so you can see the plan before you have your own id. If `steam_appid.txt` is missing the error says how to write it.

```
publish_steam {"dryRun":true}
-> steps[0].commandLine: steamcmd +login mystudio_build +run_app_build C:/games/space/.factoria/publish/steam/app_build_1234560.vdf +quit
-> uploads: windows -> Steam app 1234560, depot 1234561 (windows), 41 files, 12.4 MB
```

### itch.io

`publish.itch` runs `butler push <export folder> <user>/<game>:<channel> --userversion <version> --ignore .factoria-export
--ignore AI_CONTENT_DISCLOSURE.md` once per platform: `windows`, `mac` and `linux` channels unless `publish.itch.channels` says
otherwise. butler only sends what changed since the last push of the channel, so repeated uploads are quick. No build files are
written. The dry run warns when neither `BUTLER_API_KEY` is set nor a `butler login` exists.

### Epic Games Store

`publish.epic` runs `BuildPatchTool -OrganizationId=... -ProductId=... -ArtifactId=<artifact of the platform> -ClientId=...
-ClientSecretEnvVar=FACTORIA_EPIC_CLIENT_SECRET -mode=UploadBinary -BuildRoot=<export folder> -CloudDir=<work folder>/cloud/<platform>
-BuildVersion=<version> -AppLaunch=<the game's executable> -AppArgs= -FileIgnoreList=<ignore list>` once per platform.
`-AppLaunch` is `<slug>.exe`, `<Name>.app/Contents/MacOS/<slug>` or `<slug>` (`game-bin` on Linux for the slug `game`, see
[Desktop](#desktop-linux-windows-macos)), relative to the export folder: the export must
contain it. The cloud folder holds the tool's chunks for later patches and is kept between uploads (`.factoria/publish/epic/cloud`);
the tool needs it to be different from the build root.

An Epic `BuildVersion` can be used once per artifact and may contain letters, digits and `. + - _` only (1 to 100
characters): raise `version` in `factoria.json` before every upload. After the upload, assign the build to a platform label
and publish the product in the Dev Portal.

### GOG

`publish.gog` writes `gog-<platform>.json` (a Pipeline Builder project: the export folder as the depot of the product, the
game's executable as the primary file task) and `ignore.txt` into `.factoria/publish/gog/`, then runs
`GOGGalaxyPipelineBuilder build-game <json> --ignore_list <ignore.txt> --version <version> [--branch <branch>]` once per platform
(macOS is `osx` for GOG). A build is not live until you publish it from the Developer Portal (Builds & Branches); Pipeline Builder
cannot publish to the *master* branch, so `branch: "master"` is refused.

### App Store Connect (TestFlight)

`publish.appstore` uploads the `.ipa` of your iOS build with `xcrun altool --upload-package <ipa> --type ios --apple-id
<appleId> --bundle-id <id> --bundle-version <export.ios.buildNumber> --bundle-short-version-string <version> --apiKey
<Key ID> --apiIssuer <Issuer ID>`. It runs on **macOS with Xcode only**; on another computer a real run is refused with the
reason, and `dryRun` still shows the plan.

**The Mac App Store.** The same command uploads the `.pkg` that [`sign.macos` with `distribution: "appStore"`](#mac-app-store)
writes (`build/export/<game-slug>-macos.pkg`), with `--type macos` and `export.macos.buildNumber`. Say which file with
`platforms` (`["ios"]` or `["macos"]`) or `artifact` (a `.pkg` extension means macOS); with no hint it uploads the one that
exists, and with both an `.ipa` and a `.pkg` it asks you to choose.

**The `.ipa` is yours to make.** `factoria export --platform ios` writes an Xcode project (`build_ios.sh`), not an `.ipa`.
Build it once per release:

1. `./build_ios.sh` and open `build/FactorIA.xcodeproj` (or `FA_IOS_DEVELOPMENT_TEAM=<team> ./build_ios.sh`).
2. In Xcode: set Signing & Capabilities > Team, pick **Any iOS Device (arm64)**, then Product > Archive.
3. In the Organizer: Distribute App > **App Store Connect** > Export (not Upload: FactorIA uploads it). Save the `.ipa` as
   `build/export/<game-slug>.ipa` (inside the project, next to the exports; the newest `.ipa` of `build/export` is used when
   that name is missing), or pass `artifact`.

The version and build number must be the ones in the `.ipa`: they come from `factoria.json` (`version`, `export.ios.buildNumber`;
the bundle id is `id`), so export, archive and publish with the same `factoria.json`. App Store Connect takes each build
number once per version: raise `export.ios.buildNumber` for every upload.

**The API key** (once, in App Store Connect > Users and Access > Integrations > App Store Connect API > Team Keys): generate a
key with the **App Manager** role, download `AuthKey_<Key ID>.p8` (Apple lets you download it once; keep it outside the
project and do not rename it), and note the Key ID and the Issuer ID of that page. Then:

```
export FACTORIA_APPSTORE_API_KEY=~/keys/AuthKey_ABCDE12345.p8
export FACTORIA_APPSTORE_API_KEY_ID=ABCDE12345
export FACTORIA_APPSTORE_API_ISSUER=11111111-2222-3333-4444-555555555555
```

Add `"publish": {"appstore": {"appleId": "6448277777"}}` to `factoria.json` (the app must exist in App Store Connect first,
with the same bundle id), run `publish_appstore {"dryRun":true}`, then `publish_appstore {}`.

**After the upload** App Store Connect *processes* the build: it takes a few minutes to an hour, you get an e-mail if it is
rejected (a missing `ITSAppUsesNonExemptEncryption`, an icon with transparency, an unsupported architecture...), and then the
build appears under your app > TestFlight. Internal testers get it once you add them to a group; external testers need
Apple's beta review. To release to the store, pick the build on the version page of the App Store tab and submit it. None
of this is done by FactorIA.

### Google Play

`publish.googleplay` uploads the release bundle with `fastlane supply --aab <aab> --track <track> --release_status
<draft|completed> --package_name <id> --json_key <service account key>`. The bundle is the one `factoria export --platform
android --format aab --release` writes (`build/export/<game-slug>-android/<game-slug>.aab`), or `artifact`. It runs on any
computer that has fastlane.

- **A debug-signed bundle is refused.** Google Play rejects it, so `publish.googleplay` fails before anything is sent when
  the file is a `-debug.aab`, or when `export.android.signing.keystore` is not set in `factoria.json` (the release export
  then fell back to the debug key). Create the keystore ([MOBILE.md](MOBILE.md#signing-and-release)) and export again. A bundle you
  signed some other way can be passed as `artifact`; FactorIA only warns, because it cannot see how a file was signed.
- **The first bundle of a new app is uploaded by hand.** Google Play requires it: in the Play Console create the app (its
  package name is the game's `id`), complete the app setup, and upload the first `.aab` yourself under Testing > Internal
  testing > Create new release. The API works from the second bundle on. Until the app is published it accepts only
  `"releaseStatus": "draft"` (the default).
- **The service account** (once): in the Play Console > Users and permissions, invite a service account with permission to
  release to the tracks you use (create it in Google Cloud: IAM > Service accounts, enable the *Google Play Android Developer
  API* in that project, and add a JSON key). Keep the key file outside the project and set `FACTORIA_GOOGLEPLAY_JSON_KEY` to
  its path. Access takes a while to apply after the invitation.
- **Draft or completed.** `draft` (the default) leaves a release in the Play Console that you review and roll out;
  `completed` rolls it out right away. `track: "production"` with `completed` publishes to everyone: the dry run warns.
- **Release notes.** `publish.googleplay.changelogs` maps a Play language to a text file of the project; the files are
  copied to `.factoria/publish/googleplay/metadata/<language>/changelogs/default.txt` on every call and uploaded with the
  release. Only the release notes are uploaded: the listing text, images and screenshots stay as they are in the Play Console.
  Each language must already be added to the store listing.
- **Version codes.** Google Play takes each `versionCode` once: raise `version` (or `export.android.versionCode`) in
  `factoria.json` before every release export. The data safety form and the other store forms stay in the Play Console.

```
publish_googleplay {"dryRun":true}
-> steps[0].commandLine: fastlane supply --aab .../space-dodge.aab --track internal --release_status draft --package_name com.mystudio.spacedodge --json_key ~/keys/play.json ...
-> uploads: android -> Google Play com.mystudio.spacedodge, track internal (draft, version code 10203), 1 file, 24.1 MB
```

### Microsoft Store

`factoria export --platform windows --format msix` (or `export.windows.format: "msix"`) writes the Windows folder as usual and,
next to it, `<out>/<slug>-windows.msix`: the package of the Microsoft Store and of `Add-AppxPackage`. It is built on any
computer (macOS, Linux, Windows) by FactorIA itself, with no Windows SDK: the same game folder is the package payload,
with `AppxManifest.xml`, `AppxBlockMap.xml` (SHA-256 per 64 KiB block), `[Content_Types].xml` and the logos. The package is
deterministic (same game, same bytes) and unsigned. The report has `format: "msix"` and the package among its `artifacts`.

```
factoria export --platform windows --format msix --release
```

**Identity.** Reserve the app name in Partner Center, then copy from its Product identity page into `factoria.json`:

```json
"export": { "windows": { "format": "msix", "msix": {
    "identityName": "12345Studio.MyGame",
    "publisher": "CN=0123ABCD-4567-89EF-0123-456789ABCDEF",
    "publisherDisplayName": "My Studio" } } }
```

Without them the package gets a placeholder identity (`FactorIA.<slug>`, `CN=FactorIA Developer`): it installs on your own
PC once signed, but the Store rejects it. `project.validate` and the export warn about it. The other fields
(`displayName`, `description`, `backgroundColor`, `version`, `minVersion`, `languages`) are in the
[settings table](#icon-and-settings-per-platform). The version is the game's `version` plus `.0`: the Store reserves the fourth number.

**Logos.** The manifest's `StoreLogo`, `Square44x44Logo`, `Square150x150Logo`, `Wide310x150Logo` and `Square310x310Logo`
(and the scale and target-size variants Windows looks for) are cut from the game's icon (`export.windows.icon`, else `icon`)
and written as PNG into `Assets/`. The package has no `resources.pri`; whether every Windows version finds the qualified
files without one has not been checked on a real PC. Replace the icon with a square picture of at least 400x400.

**Upload to the Store, unsigned.** Upload the `.msix` as it is: Microsoft signs it after certification, with the publisher
of your account. Create the submission by hand in Partner Center (pricing, age rating, privacy policy URL, listing and
screenshots; see [AI content disclosure](#ai-content-disclosure) for the content questions) and upload the package, or, once
the app and a first submission exist, `publish.microsoft` (below) uploads later versions. An update raises `version`.

**Try it on a PC without the Store.** Windows only installs signed packages, and the certificate subject must equal the
manifest `Publisher`.

- With a certificate: `sign.windows {"pfx":"signing.pfx"}` signs the package (`signtool` on Windows, `osslsigncode` on the
  other computers; `FACTORIA_SIGNTOOL` and `FACTORIA_OSSLSIGNCODE` point at the tool). The password is only read from
  `FACTORIA_WINDOWS_PFX_PASSWORD`, never from `factoria.json` or an argument. The pfx can also be `FACTORIA_WINDOWS_PFX` or
  `sign.windows.pfx` of `~/.factoria/export.json`. The command checks the certificate subject (with `openssl`, when present)
  against the manifest `Publisher` and refuses when they differ. `exe: true` also signs the game's exe, for a game shared
  as a folder or a zip. `dryRun` shows the command lines with the password as `<redacted>`.
- Without one, on Windows: `sign.windows {"testCertificate":true}` creates a self-signed certificate with the right subject,
  signs the package and writes its public part (`<slug>-windows-test-certificate.cer`) next to it. Install the certificate once, in an
  administrator PowerShell: `Import-Certificate -FilePath <slug>-windows-test-certificate.cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople`;
  then `Add-AppxPackage <slug>-windows.msix`. In PowerShell, pipe the arguments in (`'{"testCertificate":true}' | factoria call
  sign.windows -`): Windows PowerShell 5.1 drops the inner quotes of `factoria call sign.windows '{"testCertificate":true}'`.
- With Developer Mode on, `Add-AppxPackage -AllowUnsigned <file>` installs an unsigned package for testing (Windows 11 and
  recent Windows 10); such a package has no verified identity and cannot be updated by the Store.

The engine could not install a package on a real Windows PC while writing this: the byte layout is checked in the tests, and
the first install of a game is yours to confirm. Report a failure in `ENGINE_FEEDBACK.json`.

**`publish.microsoft`.** Runs the Microsoft Store Developer CLI (`msstore`, installed by you: `winget install "Microsoft Store Developer CLI"`
or the .NET tool; `FACTORIA_MSSTORE` points at it): `msstore reconfigure --tenantId ... --sellerId ... --clientId ... --clientSecret ...`
and then `msstore publish <folder> --inputFile <msix> --appId <productId> --noCommit`. `publish.microsoft.productId` of
`factoria.json` is the 12-character Store ID (Partner Center > your app > Product identity). The credentials come from an Azure AD
application you associate with Partner Center (Account settings > Tenants > Azure AD applications) and only from the environment:
`FACTORIA_MSSTORE_TENANT_ID`, `FACTORIA_MSSTORE_SELLER_ID`, `FACTORIA_MSSTORE_CLIENT_ID` and `FACTORIA_MSSTORE_CLIENT_SECRET`
(the secret is never shown: `<redacted>`). `releaseStatus: "draft"` (default) leaves the submission waiting in Partner
Center (`--noCommit`); `completed` sends it to certification. The first submission of a new app is always by hand.
FactorIA ran `msstore` only against a fake in its tests; a real upload needs a Partner Center account.

### Testing without a store

The tests of these commands run against a fake uploader (`tools/common/test_tools/fake_store_tool.cpp`) that records its arguments:
point the environment variable of a tool at any program to see exactly how it is called. `dryRun` needs no account.

## Store page material

Every store wants images at its own sizes and, for the page, a gameplay video. FactorIA makes both without an image
tool: screenshots at the stores' sizes, capsules cut from one piece of key art, and a video recorded from an input replay.

### Screenshots

Screenshots are the real game drawn natively larger, not enlarged. A game designed at 1280x720 gives Steam's, Epic's and
Microsoft's 1920x1080 with `--render-scale 1.5` (same HUD, camera and visible area, sharp text):

```
factoria run --headless --input replays/tour.json --frames 600 --screenshot-at 120,300,540 \
  --render-scale 1.5 --screenshot-pattern store/shot_{frame}.png
```

From a script or an AI, `game.screenshot {path, scale: 1.5}` does the same. Pick the frames with `--screenshot-at` after
looking at a few; Steam wants at least five screenshots of the game only (no logo, text or awards on them), Google Play and
the App Store take theirs from the table below (`assets.draw_capsules` cuts those from a screenshot too).

### Capsules and covers: `assets.draw_capsules`

`assets.draw_capsules` cuts one key art (a screenshot, or any image in the project) to every image of the stores you name
and writes `store/capsules/<store>/<name>_<w>x<h>.png`. The art is cover-cropped around `focus` (a point `[x, y]` as
fractions of the art, default the middle); the `logo` is an image (`{"image": "assets/logo.png"}`, a PNG with a
transparent background) or the title drawn with the same rasterizer as [`assets.draw_icon`](ASSETS.md#the-game-icon-without-a-provider-assetsdraw_icon)
(`{"text": "Lantern Keep", "font": "assets/fonts/Title.ttf", "fill": "#fff4d0"}`). The logo goes where the asset's rule puts
it: centred on capsules and covers, in the upper part for Microsoft (the bottom third is overlaid), none on heroes, page
backgrounds and screenshots (Steam's library hero must have no text), and alone on a transparent canvas for the logo-only
assets (Steam's library logo, Epic's logo). Assets with the same size in one store are one file.

Three arguments frame the logo:

- `safeArea`: the margin the logo keeps from the edges, as fractions of the image (0 to 0.45 each). A number is every side,
  `{"left": 0.05, "top": 0.05, "right": 0.05, "bottom": 0.3}` names sides (the others keep 0.05), and
  `{"default": 0.08, "microsoft": {"bottom": 0.4}}` differs per store (a store not named uses `default`, or the asset's
  own default). Without it every capsule keeps 0.05 on each side, and the Microsoft poster and box art also keep their bottom
  third, which the store overlays with text. The logo is made smaller to fit inside the area and is never placed outside it.
- `logoAnchor`: where the logo sits in the safe area instead of the asset's rule: `center`, `top`, `bottom`, `left`, `right`,
  `topLeft`, `topRight`, `bottomLeft`, `bottomRight`, or a point `[x, y]` (`[0, 0]` puts the logo's corner on the area's
  top-left corner, `[1, 1]` on the bottom-right one, `[0.5, 0.5]` is the middle). It applies to every asset that carries a
  logo, but not to the logo-only assets (Steam's library logo, Epic's logo): those stay centred.
- `focus` also moves the logo when the key art already has the capsule's proportions (within 1%): the crop then has nothing
  to choose, so the logo moves by how far `focus` is from `[0.5, 0.5]` (a focus of `[0.3, 0.5]` moves it a fifth of the width to
  the left of where the rule or `logoAnchor` put it), kept inside the safe area. On art of another shape `focus` only decides
  the crop.

```
factoria screenshot --frames 120 --render-scale 1.5 --out store/keyart.png
factoria call assets.draw_capsules '{"keyArt":"store/keyart.png","focus":[0.5,0.45],"logo":{"text":"My Game"},"stores":["steam","itch"]}'
```

`orientation: "portrait"` turns the phone and tablet screenshot sizes of Google Play and the App Store (landscape by default).
Look at the PNGs: change `focus` or the logo and call again (files are replaced). Use 1920x1080 key art or bigger; the
biggest image (Steam's 3840x1240 hero) is enlarged from it.

### Sizes (as of 2026-10)

These are the sizes in the code (`tools/common/src/store_assets.cpp`), checked against each store's documentation in
October 2026. Stores change them: check the store's page before uploading, and tell us in `ENGINE_FEEDBACK.json` when one moved.
"Logo" says whether `assets.draw_capsules` puts the logo on it; where the store has no rule the placement is our choice.

**Steam** ([standard assets](https://partner.steamgames.com/doc/store/assets/standard), [library assets](https://partner.steamgames.com/doc/store/assets/libraryassets))

| Image | Size | Logo |
|---|---|---|
| Header capsule | 920x430 | yes |
| Small capsule | 462x174 | yes (fills it) |
| Main capsule | 1232x706 | yes |
| Vertical capsule | 748x896 | yes |
| Page background | 1438x810 | no (ambient) |
| Library capsule | 600x900 | yes, low |
| Library header | 920x430 | yes |
| Library hero | 3840x1240 | no text at all; keep the subject inside the centred 860x380 |
| Library logo | 1280x720 (or 1280 wide / 720 tall) | alone, transparent PNG |
| Screenshots | 1920x1080 minimum, 16:9, at least 5 | no |

**Epic Games Store** ([Storefront Media Guide](https://dev.epicgames.com/docs/epic-games-store/sales-and-marketing/marketing/storefront-media-guide))

| Image | Size | Logo |
|---|---|---|
| Product logo | 960x540 | alone |
| Offer image, landscape | 2560x1440 | yes |
| Offer image, portrait | 1200x1600 | yes |
| Social preview | 1200x1200 | yes |
| Screenshots / media carousel images | 1920x1080 | no |

**GOG** ([essentials checklist](https://docs.gog.com/basic-game-assets/)): GOG publishes the sizes of its store images only in
the templates of the developer portal. The key art (at least 1920x1080, layered .psd with the logo for GOG's team) is
documented; the vertical cover 342x482 and the background 1600x670 come from GOG's support article and are **not verified**:
check them against the templates.

| Image | Size | Logo |
|---|---|---|
| Key art | 1920x1080 or more | no |
| Vertical cover | 342x482 (unverified) | yes, low |
| Background | 1600x670 (unverified) | no |

**Microsoft Store** ([screenshots and images](https://learn.microsoft.com/windows/apps/publish/publish-your-app/msix/screenshots-and-images))

| Image | Size | Logo |
|---|---|---|
| Poster art 2:3 | 720x1080 | yes, in the upper two thirds |
| Box art 1:1 | 1080x1080 | yes, in the upper two thirds |
| App tile icon | 300x300 | yes |
| Super hero art 16:9 | 1920x1080 | no (no text allowed) |
| Screenshots, trailer thumbnail | 1920x1080 (screenshots: 1366x768 or more) | no |

**Google Play** ([graphic assets](https://support.google.com/googleplay/android-developer/answer/9866151))

| Image | Size | Logo |
|---|---|---|
| Feature graphic | 1024x500, no alpha | yes |
| App icon | 512x512 (the real icon: `assets.draw_icon`) | yes |
| Phone / tablet screenshots | 320 to 3840 px a side, long side at most twice the short one; 1920x1080 (or 1080x1920) also qualifies for large-screen recommendations | no |

**App Store** ([screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)), no alpha, landscape here (`orientation: "portrait"` swaps):

| Image | Size | Logo |
|---|---|---|
| iPhone 6.9" | 2868x1320 | no |
| iPhone 6.5" | 2778x1284 (required when there are no 6.9" ones) | no |
| iPhone 6.3" | 2622x1206 (at least one iPhone size is required) | no |
| iPad 13" | 2752x2064 (required if the app runs on iPad) | no |

**itch.io**: the cover image upload form asks for 630x500 (minimum 315x250); itch.io's docs do not print the size, so it
is **not verified** against documentation. The logo is centred.

| Image | Size | Logo |
|---|---|---|
| Cover image | 630x500 | yes |

### Gameplay video from a replay

`factoria run --headless --input replay.json --frames N --record-video out.avi` plays the replay and writes a video of it:
every frame is drawn at `--render-scale` (1.5 on 1280x720 = 1920x1080) at the project's `fixedHz` frames per second, and the
audio mix of the run is its sound track (none when the run is silent). The same replay and seed always give the same file.
Record a replay with the editor (play session recorder) or write it by hand ([CLI.md](CLI.md), AI_GUIDE 11.2).

```
factoria run --headless --input replays/trailer.json --frames 900 --render-scale 1.5 --record-video store/trailer.avi
```

- `.avi` needs nothing else: Motion-JPEG video and 16-bit PCM audio. Every player and editor reads it; it is large (about
  10 MB a second at 1080p, so do not commit it; ffmpeg makes the small .mp4). **Limit:** an AVI file cannot pass about
  2 GB, which is roughly 3 minutes of 1080p at 60 fps (twice that at 720p). When the video reaches it, recording stops at that
  frame, the run goes on, and the report lists the reason in `problems` (exit code 2). Record a shorter replay
  (`--frames`) or use a smaller `--render-scale`.
- `.mp4` (H.264 + AAC, what Steam, Google Play and the App Store accept for previews) is made by
  [ffmpeg](https://ffmpeg.org/download.html), found like the store tools of [Finding the tools](#finding-the-tools):
  `FACTORIA_FFMPEG` (the executable or its folder), `"publish": {"ffmpeg": "<path>"}` in `~/.factoria/export.json`, `PATH`,
  then the copy `factoria setup ffmpeg` installs under `$FACTORIA_HOME/tools/ffmpeg/` (`setup.status` lists the `ffmpeg`
  component and `setup.install {"component": "ffmpeg"}` installs it, one download of 19-28 MB). FactorIA records the AVI and ffmpeg converts it (even sizes, `yuv420p`, `+faststart`). Without ffmpeg the request fails
  before the replay runs, with this advice: run `factoria setup ffmpeg`, install ffmpeg yourself, or record `.avi` and convert it yourself:
  `ffmpeg -i trailer.avi -c:v libx264 -pix_fmt yuv420p -c:a aac trailer.mp4`.
- Stores want the video at their own sizes and rates (Microsoft: 1920x1080 MP4, under 2 GB, 60 s or less recommended);
  pick `--frames` and `--render-scale` for it. A video needs a GPU like screenshots do (headless EGL with Mesa works).

## CI for your game

`project.new_ci_workflow` writes `.github/workflows/factoria.yml` into the game's folder: a GitHub Actions workflow that
validates the game, runs its tests and exports it on every push to `main` or `master` and on every pull request.

```bash
factoria call project.new_ci_workflow                                      # all three platforms
factoria call project.new_ci_workflow '{"platforms":["linux","windows"],"dryRun":true}'   # print it, write nothing
factoria call project.new_ci_workflow '{"workingDirectory":"games/my-game"}'  # the game is a folder of a larger repository
```

(MCP tool `project_new_ci_workflow`; C++: `fa/tooling/ci_workflow.h`, `fa::write_ci_workflow`.) Templates do not carry the
file, because not every game lives on GitHub: call it when yours does. What the workflow does:

- **Job `check`, on `ubuntu-24.04`.** Installs the libraries FactorIA loads (`xvfb libegl1 libopengl0 libx11-6 libxcursor1
  libxi6 libasound2t64 libgl1-mesa-dri libegl-mesa0`: the Mesa software renderer, so no GPU is needed), downloads the
  FactorIA package and **checks it against the SHA-256 GitHub lists for the release asset** (with `python3`, which every
  runner has), puts it on the `PATH`, then runs `factoria validate`, `xvfb-run -a factoria test`, `factoria setup players
  --platforms windows` and `factoria export` for Linux and Windows. The exports are packed (a `.tar.gz` for Linux, which keeps
  the executable bit, and a `.zip` for Windows) and uploaded with `actions/upload-artifact`: Actions > the run > Artifacts.
- **Job `macos`, on `macos-latest`.** Installs the macOS package, runs `factoria export --platform macos` (the app is
  sealed ad hoc, see [Desktop](#desktop-linux-windows-macos)) and uploads it. To sign and notarize in CI, import your Developer
  ID certificate into a keychain in that job from repository secrets, store the notarytool profile or pass the credentials as
  environment variables (never in the file), and add a step that runs `factoria call sign.macos`
  ([Signing and notarizing for macOS](#signing-and-notarizing-for-macos)); the workflow has a comment where it goes.
- **One pinned version.** `FACTORIA_VERSION` at the top of the file is the FactorIA release the job downloads, the same
  version as the `factoria` that wrote the file (`version` chooses another: `"0.1.6"` or `"latest"`). A `factoria` built from
  source has no release of its own, so the file follows the newest release (`"latest"`) and the result warns about it. Change
  the one line to move the game to another version; the download is `github.com/OxtailGames/FactorIA/releases`.
- **Least privilege.** `permissions: contents: read`; the job's token only reads the public release listing for its checksum.

Arguments: `platforms` (`linux`, `windows`, `macos`; default all three), `path` (another file name inside
`.github/workflows/`), `workingDirectory` (the game's folder relative to the repository root, default `.`), `version`,
`overwrite` and `dryRun`. **It never overwrites a file that differs**: an existing `factoria.yml` is an error that names
`overwrite: true`, another file name and `dryRun` as the ways on (an identical file is left alone and reported as up to
date). GitHub reads workflows only from the repository root: for a game in a subfolder, write it with `workingDirectory` and
move the file to `<repository>/.github/workflows/` (the result warns when the game is inside a larger git repository). The
result is `{path, written, dryRun, version, repo, platforms[], workflow, warnings[], nextSteps[]}`, `workflow` being the
YAML. The workflow runs the same `factoria` commands you run by hand: when a CI export fails, run the failing step locally.

**Smoke-testing the exported game.** `factoria_player --frames N` draws N frames of the game and exits: `0` when it ran, `1`
when a script raised an error by then (the errors are logged), and a non-zero code from the operating system when it crashed.
`2` means a bad option. It works on the player inside an export, so a CI step can start the game it just built:

```bash
build/export/my-game-linux/my-game --frames 120          # xvfb-run -a ... on a machine without a display
```

The game opens a window like a normal run, so on a Linux runner start it with `xvfb-run -a` (the `check` job already installs
what it needs). `factoria run --headless --frames N` does the same check without a window or the export.

### Checking an exported build

`--frames N` only proves that the build starts. To check that it **plays** the same as the game you tested, give it a
replay (the JSON `input.record` writes, [DEBUGGING.md](DEBUGGING.md)) and ask for what it ended up with:

```bash
build/export/my-game-linux/my-game --frames 300 --input replays/level1.json \
    --dump-state out/state.json --screenshot out/last.png
factoria run --headless --frames 300 --input replays/level1.json --state-out out/ref.json \
    --screenshot-at 299 --screenshot-pattern out/ref.png
cmp out/state.json out/ref.json && cmp out/last.png out/ref.png
```

- `--input <replay>`: plays the replay; a relative path is relative to the current directory. A replay does not name a
  scene: it plays from the start scene (`--scene` overrides it, as for the editor).
- `--dump-state <file>`: the world state as JSON after the last frame (what `factoria run --state-out` writes).
- `--screenshot <file>`: a PNG of the last frame (frame `N-1`, what `--screenshot-at N-1` captures), at design size.
- All three need `--frames N` (without it the player says so and exits 2); any one of them makes the run **headless**
  (no window, no audio, fixed time step, seed 1, in-memory storage, fake platform), the same path as `factoria run
  --headless`, so it also works on a CI machine without a display (it still needs a GPU or the Mesa software renderer).
  Missing parent folders of the outputs are created.
- Exit code: `0`; `1` when a script raised an error (printed on stderr), like `factoria run`; `2` for a usage error: a missing
  or malformed replay, an output that cannot be written, `--frames` missing.
- What to compare: the state dump should be **byte-equal** to `factoria run`'s for the same replay and frame count (it is
  deterministic); the screenshot is equal too when both run on the same renderer (the test `cli_player_replay` compares the
  PNG bytes), but across machines or GPUs allow a small pixel tolerance. A difference in the state means the export
  changed the game's behaviour (missing asset, script, plugin); a difference only in the picture means a renderer problem.
- Not available in the player: `--props` (a replay of a scene that needs props cannot be checked this way) and the
  other `factoria run` outputs (audio, video).
- In CI: run the player step after `factoria export` in the same job, then `cmp` or diff the files as above, and upload
  them as artifacts when they differ.

## Tips

- Run `factoria validate` first; export only checks what packaging needs.
- Add the platform to `"platforms"` in `factoria.json` or export prints a warning.
- Orientation comes from `display.orientation` (`landscape`, `portrait`, `any`).
- Version `1.2.3` becomes Android `versionCode` 10203 and iOS `CFBundleShortVersionString` 1.2.3; the iOS `CFBundleVersion` is
  the same unless `export.ios.buildNumber` says otherwise.
