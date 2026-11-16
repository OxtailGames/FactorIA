# Exporting a game

`factoria export` turns a game project into something you can ship. The same
function is available to tools as `fa::export_project` (`fa/tooling/export.h`), to AIs as the command
`project.export`, and in the editor as the **Export Game** item of the menu bar ([From the editor](#from-the-editor)).

```bash
factoria export [project] --platform <linux|windows|macos|android|ios|web> [--format apk|aab|gradle|appimage|msix|folder] [--out DIR] [--release [--allow-debug-key]]
                [--player PATH] [--engine-root DIR | --mobile-dir DIR] [--allow-player-mismatch] [--allow-missing-plugins]
                [--single-file [--single-file-max-mb N]] [--json]
```

`--format` is for Android (`apk` by default, `aab` for Google Play, `gradle` for only the project): see [Android](exporting/EXPORTING_MOBILE.md#android);
for Linux, `appimage` also builds the game as one AppImage file: see [Linux: AppImage](exporting/EXPORTING_DESKTOP.md#linux-appimage).
`--release` on Linux, Windows and macOS puts the whole game in ONE file, `game.pak`, with the scripts compiled to bytecode: see
[Release build](exporting/EXPORTING_DESKTOP.md#release-build-gamepak). On Android it builds the release APK/AAB. `--platform web` writes a page, the web
player and `game.pak`, plus a zip itch.io takes as an HTML5 game; with `--single-file` it writes ONE html page instead: see
[Web](exporting/EXPORTING_WEB.md#web).

Before anything is written the project is validated: `factoria.json` must exist,
`name` must be set, `mainScene` must exist and `id` must be a reverse-DNS
identifier (required for Android and iOS: `com.example.spacedodge`, letters,
digits and underscores, every part starting with a letter; Java keywords such
as `new` are rejected for Android). Errors name the file, the JSON pointer and
the fix.

The result goes to `<out>/<game-slug>-<platform>/` (default `--out`:
`<project>/build/export`). That folder is deleted and recreated on every
export, but only when it is empty or an export wrote it: a folder of yours that happens to have that name is never
deleted ([Replacing an earlier export](exporting/EXPORTING_CONTENTS.md#replacing-an-earlier-export)). `--json` prints the report: `outputDir`, `mode` (Android and iOS only, see [Mobile exports](exporting/EXPORTING_MOBILE.md#mobile-exports-prebuilt-or-source)),
`format` and `artifact` (Android: the format, and the absolute path of the APK/AAB that was built; Linux with `appimage`: the AppImage; web: `zip` and the zip), `mode` also tells where the web player came from,
`notices` (see [License notices](exporting/EXPORTING_CONTENTS.md#license-notices)), `pack` and `packed` (a `--release` desktop export: the pack and the paths in it), `files`
(what is on disk, so a release export lists `game.pak`, not the files in it), `nextSteps`, `warnings`. A game with AI-made assets also
gets `AI_CONTENT_DISCLOSURE.md` ([AI content disclosure](exporting/EXPORTING_CONTENTS.md#ai-content-disclosure)).

## Pages of this doc

- [What is shipped and what each export needs](exporting/EXPORTING_CONTENTS.md): What is shipped, replacing an export, license notices, AI disclosure and what each export needs.
- [Setting up and platform settings](exporting/EXPORTING_SETUP.md): Setting up this computer and the platform settings of factoria.json.
- [Desktop](exporting/EXPORTING_DESKTOP.md): Linux, Windows and macOS exports: release build, packages, signing, Steam, Epic, GOG, itch.io, Microsoft and Mac App Store.
- [Web](exporting/EXPORTING_WEB.md): The web export: player, serving, single file, hosting.
- [Mobile](exporting/EXPORTING_MOBILE.md): Mobile exports: prebuilt or source, Android and iOS export details.
- [Uploading to stores and store page material](exporting/EXPORTING_STORES.md): Uploading to stores and the store page material.

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
password for `--release` (`fa::plan_export` in C++). The command takes `--player` as `player` (an absolute path or one relative to the
project). `--engine-root` and `--mobile-dir` are CLI-only: the command uses the `mobile/` folder next to the running binary, or
`$FACTORIA_ENGINE_DIR` when it is set.

```
project_export {"platform":"windows","release":true}
project_export {"platform":"android","dryRun":true}
```

## From the editor

The editor's menu bar has an **Export Game** item after Help (on macOS, the **Export** menu with **Export Game...**,
Cmd+E; File > Export Game... does the same on every system). It opens the **Export game** window: one
button per platform (Windows, macOS, Linux, Android, iOS, Web), each running this same export, never a separate one.

- **Output folder**: the parent folder of the exports, `<project>/build/export` by default. Type a path (relative to
  the project), press **Choose...** for the system's folder dialog or **Default** to go back; **Show in Finder** (Explorer
  on Windows, the file manager on Linux) opens it. An export replaces `<output folder>/<game>-<platform>` and nothing
  else, and only a folder an earlier export wrote ([Replacing an earlier export](exporting/EXPORTING_CONTENTS.md#replacing-an-earlier-export)): when
  the chosen folder already holds another folder of that name, each platform's row says so and nothing is deleted.
  **Release** makes a release build, as `--release` does (for Android a release APK or AAB, signed with the keystore
  of the Android settings; hover it for what it changes on each platform).
- **Platform settings...** (top of the window, also File > Platform Settings...) and the **Settings...** button of each
  row open the [Platform settings window](EDITOR.md#platform-settings): the icon and the fields of
  [Platform settings](exporting/EXPORTING_SETUP.md#platform-settings) below, with Save / Revert, previews of the icons, a Create keystore... button for
  the Android signing key and the JDK / SDK folders of this computer. It edits `factoria.json` (and
  `~/.factoria/export.json`) through the same code `factoria validate` and the export read them with.
- **Android format**: the Android row's **Format** menu picks `apk`, `aab` or `gradle` (`export.android.format`) and saves
  it in `factoria.json` at once, without waiting for Save in the settings window.
- **Set up buttons**: a row that cannot run because this computer lacks something FactorIA installs shows the button that
  installs it (**Install Android build tools**, **Download Windows player**, **Download mobile libraries**, **Download web player**, **Install CMake**,
  **Open App Store (Xcode)**): the editor's front for [`factoria setup`](exporting/EXPORTING_SETUP.md#setting-up-this-computer).
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
  sealed ad hoc, see [Desktop](exporting/EXPORTING_DESKTOP.md#desktop-linux-windows-macos)) and uploads it. To sign and notarize in CI, import your Developer
  ID certificate into a keychain in that job from repository secrets, store the notarytool profile or pass the credentials as
  environment variables (never in the file), and add a step that runs `factoria call sign.macos`
  ([Signing and notarizing for macOS](exporting/EXPORTING_DESKTOP.md#signing-and-notarizing-for-macos)); the workflow has a comment where it goes.
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
- `--persist-storage` (with those flags, as `factoria run --persist-storage`): `storage.*` and the save files go to the game's
  real user folder instead of memory. It is how to see that a save lands where it should: inside the container of a
  sandboxed Mac App Store build (`~/Library/Containers/<bundle id>/Data/Library/Application Support/<bundle id>/`), or in
  `HOME` (`APPDATA`, `XDG_DATA_HOME`) pointed at a temporary folder in a test. A replay that presses Play and saves leaves
  the file, with no click on the window (`cli_larkspur_ship` does that for Larkspur Lodge). Start from a clean folder: the
  files stay between runs. Without any of the three flags it is a usage error (exit 2).
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
