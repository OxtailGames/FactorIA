# Exporting a game, page 1 of 6

Part of [Exporting a game](../EXPORTING.md) (the entry page lists every page).

## What is shipped (and what is not)

Everything in the project except: `.factoria/`, every dot-file or dot-folder
(`.git`, `.mcp.json`, `.gitignore`), `build/` (earlier exports), `tests/`, `tools/`, `types/`,
`node_modules/`, `ENGINE_FEEDBACK.json` (the file named by `feedbackFile`) and its `.archive.json` next to it,
`scripts/autoplay.js` (the bot `play.auto` runs, [SCRIPTING](../SCRIPTING.md#the-bot-gameautoplay); `tools/`, `tests/` and `scripts/autoplay.js` are matched in any capitalization), `AGENTS.md`, `CLAUDE.md`, `REVIEW.md` (the note the AI reviewers read first), `jsconfig.json`, the project's own top-level `README.md` (documentation for whoever works on the
game; any capitalization), a top-level `steam_appid.txt` (the development app id of the
[Steam backend](../platform/PLATFORM_BACKENDS.md#steam-steamworks): a game started by Steam gets its app id from Steam), the folder of a native
plugin that lives inside the project (its build is shipped instead, below), and the output folder itself. Your project is never modified; the feedback file stays in the
repository. Those are the files no game reads, on every platform and with or without `--release`; the list is also the comment of
`fa/tooling/export.h`. Only the TOP-LEVEL `README.md` is left out: a `README.md`, `CREDITS.md` or `LICENSE` deeper in the project, or a data
file of any kind, ships, because a game may load it. That includes the files a glob import
(`import tables from "../data/dialogue/*.json"`, [SCRIPTING](../SCRIPTING.md#imports)) lists: keep them outside `tests/`, `tools/`
and `export.exclude`, or the exported game finds fewer files than the project does.

The project's own commands live in the modules under `tools/`, subfolders included (`project.<name>`), so a shipped game has none
of them. An export warns when a shipped script calls one with a literal name (`fa.call("project.scatter_gems", ...)`): the call would
fail in the game. Move what the game needs into a module under `scripts/` and import it from both the tool and the script. A name
built at run time is not found by the warning.

**A shipped script calls only commands the player has.** The exported player has the engine's runtime commands (the ones
`scene.spawn`, `game.state`, `vfx.play`, `tilemap.generate`, `scene.place_ascii`... belong to) and the commands of the game's native
plugins; it does not have the commands that only developer tools use (they write project files or author assets: `scene.format`,
`prefab.save` and every other command that lives in `tools/authoring`, `anim.*` and `mesh.*` among them once they have moved there; the editor, the
CLI and MCP have them).
`fa.call` with such a name fails when the game runs, so the export reads every shipped script (`scripts/` and any other `.js` that
ships, not `tools/`, `tests/`, `scripts/autoplay.js` or what `export.exclude` leaves out) and **stops** on each literal
`fa.call("<command>")` of a command that is not the player's, before it writes anything (a `dryRun` finds it too, and so does the
web export of `factoria serve`, which plans the export first). The error lists up to eight calls, each as `file:line:column`, the command,
"this command is for the editor, the CLI and MCP (authoring); the exported player does not have it", and what to do instead: the JS
way where there is one (`mesh.*` is the `mesh` API of `"factoria"`, `anim.*` clips are assets that the entity's Animator plays,
`scene.import_ascii` is `scene.place_ascii` at play time), or "do it before you export" for `prefab.save` and `scene.format`. A
name that matches no command at all gets "did you mean" when one command is close, and `factoria call docs.commands` lists them. The names a native plugin registers
(`<plugin>.<verb>`, for each plugin `factoria.json` declares) count as the player's. Only a string literal is checked
(`fa.call("scene.format")`, in either quote style): a name built at run time (`fa.call(name)`, `fa.call(prefix + ".format")`) or a
call inside a comment or a string is not, and it still fails in the game if the player lacks it. `factoria validate` reports the same
calls as warnings, in the scripts the export ships, so you see them before you export. The editor's Export window plans every
platform every two seconds without reading the scripts each time: it keeps the last result for ten seconds, and drops it
at once on a save, a project reload, an export or a changed `factoria.json`, so a script edited outside the editor shows up
within ten seconds or when the window is opened again (an export, `dryRun` and `factoria serve` always read the scripts).

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

Audio import settings (`assets.json`, [ASSETS.md](../ASSETS.md)) act at export time: a WAV with `convert: "qoa"` ships as
`<path>.qoa` (the engine plays that twin when the original is missing; the converted file is cached in
`.factoria/export-cache/<platform>/audio/`, so only changed sounds are encoded again), and the shipped `assets.json`
carries the measured loudness (`analysis`) of every sound with `normalize` on, so the game never measures at run time.
A conversion that cannot be done (more than 8 channels) leaves the file as it is and adds a warning to the report.

Custom materials (`*.material.json`) ship compiled, because a game has no shader compiler: the export compiles each one
for the shader dialects of the platform (Windows `hlsl5`, Linux `glsl430`, macOS `metal_macos`, iOS `metal_ios` and
`metal_sim`, Android and web `glsl300es`) and ships `materials/water.material.json.<dialect>.shader` next to the material;
the GLSL snippet the material names (`shaders/water.surface.glsl`) is not shipped. This needs sokol-shdc, which the
factoria downloads carry next to `factoria` ([The shader compiler](EXPORTING_SETUP.md#setting-up-this-computer)), unless
`.factoria/shader-cache` already holds the compiled shaders. A
material that does not compile stops the export with the errors `factoria validate` lists (file, line, column, the line
quoted, a hint). The report's `materials` lists the materials that shipped. How to write a material: [SHADERS.md](../SHADERS.md).

The export adds two files of its own: `.factoria-export` at the top of the export folder (next section) and
`FACTORIA_NOTICES.txt` ([License notices](#license-notices)). An Android export also leaves out the keystore named by
`export.android.signing` when it lives inside the project (a warning says to keep it outside the repository): a signing
key must never end up in the assets of an APK.

### Textures

Textures are the one thing an export changes instead of copying (import settings `compression` and `atlas` in
`assets.json`; [ASSETS.md](../ASSETS.md#textures) has the details):

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
`/OPT:REF` with MSVC on Windows, and Emscripten's own removal on the web. These sizes are examples, not promises: they
were measured on the dates and versions named here and grow with the engine (check the size of the `factoria_player` of
your own download):

| Player | Size |
|---|---|
| macOS arm64, Release, without symbols (2026-10-26, M29 engine) | 9.1 MB (10.2 MB before `-dead_strip`) |
| Web, `factoria_player.wasm`, Emscripten 6.0.10 (2026-10-26, M29 engine) | 8.0 MB, 3.0 MB with gzip (6.8 MB and 2.7 MB in v0.2.0) |
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

**A game running from the folder (Windows).** Windows does not delete a file a program holds open, and a game that runs
from an export holds its exe, its libraries and `game.pak` (when it is memory-mapped, the default on 64-bit) open for as
long as it runs. So before an export deletes the previous folder it looks at those files (the `.exe`, `.dll`, `.so`,
`.dylib` and `.pak` files, a macOS bundle's executable and a player at the top of the folder; the loose files of a game
are never held, it reads them and closes them again). It looks at 100000 files at most, a count and not a time, so the
same folder always gets the same answer. If one is held it stops with
`export: '<file>' is open in another program (the game running from <folder>?): close it and export again`; nothing is
deleted and the previous export stays as it was. Close the game and export again. A program that only reads a file and
lets others delete it (a cloud sync client, a virus scanner, `tail`, a game that reads its `game.pak` without mapping it,
as with `FA_PACK_MAP=0`) does not stop an export: Windows deletes the file under it, the program reads on from the old
file and the export writes a new one. A file that was held for less than about a second is not counted. A read-only exe
that is running is found on Windows 10 1809 and later; a read-only file left by an earlier export (copied from a
read-only player) is deleted anyway. To look, the export marks each of those files for deletion and takes the mark back
at once; should Windows refuse to take it back, the export stops with
`export: Windows did not take back the deletion mark ...: that file may be deleted now`, and the next export writes it
again. Under Wine any open handle counts as held. On macOS and Linux an open file can be deleted, so nothing is looked at there (with `FA_FS_WINDOWS_RULES`
the same check runs on the files the engine holds open itself, so the tests see it).

**Android keeps Gradle's working folders.** An Android export is a Gradle project, and the APK or AAB build runs Gradle
inside it. The Gradle daemon stays alive for 15 minutes after a build (`org.gradle.daemon.idletimeout` in
`gradle.properties`) and keeps files open in the project's working folders, so an export over an Android export deletes
everything except `.gradle/`, `.kotlin/`, `build/`, `app/build/` and `plugins/<name>/build/`, then writes the project
again. The next build is then incremental (Gradle sees which inputs changed) and a second export right after the first
works on Windows with the daemon alive. Those folders are never part of the export's `files`. To start Gradle from
nothing, delete the folder yourself (or run `gradlew --stop` first on Windows).

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

The built-in fonts that are not inside the player (`builtin:serif`, `builtin:hand`, `builtin:blackletter`,
`builtin:display`, [TEXT.md](../TEXT.md#built-in-fonts)) are different: the export copies the files of the ones your game names
to `builtin-fonts/` (a scene, prefab, script, data file or `factoria.json` that contains the name written out in full; a
name a script builds from pieces is not seen) and adds their OFL license texts to `FACTORIA_NOTICES.txt`. A game that names
none carries neither the files nor the texts. The report lists them as `builtinFonts`.

Keep it in what you distribute (zip, installer, store build). You may also show it on a credits or licenses screen;
nothing else is required. `factoria docs licenses` prints the full list, including what only the developer tools
contain (Dear ImGui, in the editor, and the Gradle wrapper, Apache-2.0, which an Android export writes into its Gradle
project and which is not part of the game).

## AI content disclosure

Stores ask whether a game contains AI-generated content (Steam's content survey, and similar forms elsewhere). When any
asset in `assets.json` has `provenance.ai: true`, the export writes `AI_CONTENT_DISCLOSURE.md` at the top of
`<out>/<game-slug>-<platform>/`, next to the game and not inside it, and adds a line to `nextSteps`. It is for you to read
and paste into the store form; leave it out of what you ship if you like. No AI assets, no file. What it says, where the
records come from and `assets.disclosure` are in [ASSETS.md](../ASSETS.md#provenance-and-store-disclosure).

## What each export needs

One row per export. A **source build** is a `factoria` compiled from the repository: it has its own OS's player but no
`mobile/` libraries, no `web/` and no players of the other OSes. The **download** (the FactorIA package) carries `mobile/`
(Android; iOS only in the macOS package), `web/` and the player of its own OS. The host columns say whether a machine can
do the export with a source build: **yes** = offline, nothing is downloaded; **after setup** = offline once the named
download is done; **no** = that host cannot do it. The cells come from the export code and `factoria setup`; `factoria setup`
(no arguments) lists what a computer already has.

| Export | What it needs | Windows host | Linux host | macOS host |
|---|---|---|---|---|
| `windows` folder ([Desktop](EXPORTING_DESKTOP.md#desktop-linux-windows-macos)) | the Windows player: from the download, or `factoria setup players` (about 60 MB for all OSes) or `--player`. The exe's icon and version info are written by the export on any host. Signing is `sign.windows` (patching the exe removes the player's signature) | yes | after setup | after setup |
| `windows --format msix` ([Microsoft Store](EXPORTING_STORES.md#microsoft-store)) | the same as the folder; the package itself needs nothing else | yes | yes | yes |
| `linux` folder | the Linux player, same sources | after setup | yes | after setup |
| `linux --format appimage` ([AppImage](EXPORTING_DESKTOP.md#linux-appimage)) | `factoria setup appimage` (about 16 MB; Linux x86_64 only, so WSL on Windows) | in WSL, after setup | after setup (x86_64) | no |
| `macos` `.app` | the macOS player, same sources. The ad hoc `codesign` runs only on a Mac; elsewhere the app is not signed | after setup | after setup | yes |
| `macos` signed and notarized ([Signing and notarizing](EXPORTING_DESKTOP.md#signing-and-notarizing-for-macos)) | `codesign`, `xcrun notarytool` and `stapler` (Xcode command-line tools), a Developer ID Application certificate (Apple Developer Program) and a notary profile. Notarization uploads to Apple | no | no | online (notarization) |
| `web` ([Web](EXPORTING_WEB.md#web)) | `web/` (`factoria_player.js` + `.wasm`): in the download; for a source build `factoria setup players --platforms web` (about 15-33 MB) or, on a development build ahead of the last release, `factoria setup webplayer` (builds it from the checkout), or an Emscripten 6.0.10 build of the engine passed with `--player` ([BUILDING.md](../design/BUILDING.md), repository only, not in the binary) | after setup | after setup | after setup |
| `android --format gradle` ([Android](EXPORTING_MOBILE.md#android)) | no JDK, no SDK. The project holds the Android libraries (prebuilt mode) or is generated from an engine checkout (source mode) | after setup (`players --platforms mobile`) or with a checkout: yes | same | same |
| `android` apk / aab, **prebuilt** ([modes](EXPORTING_MOBILE.md#mobile-exports-prebuilt-or-source)) | a JDK 17+ (17 and 21 are tested; `factoria setup android` installs Temurin 21) and the Android SDK with `platforms;android-36` and `build-tools;35.0.0` (same command, about 500 MB, accepts the SDK license); the Android libraries as above. No NDK, no CMake. The first build downloads Gradle 8.14.3 and the Android Gradle plugin | after setup, then after one online build | same | same |
| `android` apk / aab, **from source** | the same JDK and SDK, an engine checkout (`--engine-root` or `FACTORIA_ENGINE_DIR`), and NDK r27+ (`ndk;27.2.12479018`) and a CMake 3.24+: 3.31.6 in the SDK, else any other 3.24+ in the SDK, else one on this computer (the export points Gradle at it with `cmake.dir`). `factoria setup android` does not install the NDK or the CMake: `sdkmanager "ndk;27.2.12479018" "cmake;3.31.6"`. Compiles the engine for two ABIs (minutes) | after setup, then after one online build | same | same |
| `android --release` (Google Play) | the above plus a keystore and `FACTORIA_ANDROID_KEYSTORE_PASSWORD` ([Signing](EXPORTING_MOBILE.md#android)); without a keystore it is an error unless `--allow-debug-key` (never upload that build) | same | same | same |
| `ios` project ([iOS](EXPORTING_MOBILE.md#ios)) | prebuilt: the iOS libraries (in the macOS download; on Windows and Linux `factoria setup players --platforms mobile`); source: an engine checkout | prebuilt: after setup; source: yes | same | yes with the macOS download or a checkout |
| `ios` app (`build_ios.sh`) | a Mac with Xcode (from the App Store; `factoria setup xcode` checks it) and CMake 3.24+ (`factoria setup cmake` installs 3.31.6, about 75 MB); a device build also needs an Apple Team ID | no | no | yes |

Uploading the result is a separate step: [Uploading to stores](EXPORTING_STORES.md#uploading-to-stores). What each `factoria setup` component
installs, and where: [Setting up this computer](EXPORTING_SETUP.md#setting-up-this-computer). A source build ahead of the last release has no
players of its own: `factoria setup players` takes the newest release's and says that their build fingerprint will not match
(an export then needs `--allow-player-mismatch`); the web player can be built from the checkout with `factoria setup webplayer`
([A development build](EXPORTING_DESKTOP.md#a-development-build-players-from-the-checkout)). For the other OSes build the player on that OS and pass `--player`.
