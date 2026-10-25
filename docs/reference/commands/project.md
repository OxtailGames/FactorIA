[Back to the index](../README.md)

# Commands: project

## `checkpoint.create` (modifies state)

Since 0.2.0.

Save a checkpoint: a snapshot of every file of the project that checkpoint.restore can put back.

Copies the project's files into .factoria/checkpoints (content-addressed: a file that did not change since an earlier checkpoint is not copied again, so the second checkpoint of a project is cheap). Includes scripts, scenes, tests and assets; skips folders starting with '.', node_modules and a top-level build/. Keeps the newest 30 checkpoints. The editor makes one before every AI run (the Revert button of the AI Assistant), so call this yourself only before a risky change the user did not ask the editor to track. Returns {id, label, created (epoch seconds), files, bytes (size of the files), bytesStored (newly copied), filesHashed}. Example: {"label":"before the refactor"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `label` | string | no | A short name shown by checkpoint.list and the editor, e.g. "before the refactor". |

## `checkpoint.diff`

Since 0.2.0.

Show which files changed since a checkpoint (modified, added, deleted).

Compares the files now with checkpoint `id`. Returns {modified, added, deleted} (project-relative paths) and counts. Changes nothing. Example: {"id":"20261022-153012-7"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | A checkpoint id from checkpoint.list. |

## `checkpoint.list`

Since 0.2.0.

List the project's checkpoints, newest first.

Returns {checkpoints: [{id, label, created (epoch seconds), files, bytes}], limit}. Only the newest `limit` checkpoints are kept.

## `checkpoint.restore` (modifies state)

Since 0.2.0.

Put the project's files back as they were at a checkpoint (the user's Revert); ask the user before calling it.

Writes back the files that were modified or deleted since checkpoint `id` and deletes the files added since (anything the user edited by hand in those files is lost). First it saves an automatic checkpoint "Before restoring <label>" and returns its id as safetyCheckpointId: restoring that one takes this restore back. Files are written through a temp file and a rename, so a crash never leaves half a file. This does NOT reload the scene open in the editor (the editor's Revert button does). Returns {modified, added, deleted (what was done), safetyCheckpointId}. Example: {"id":"20261022-153012-7"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | A checkpoint id from checkpoint.list. |

## `perf.baseline` (modifies state)

Since 0.2.0.

Measure the game and write or refresh THIS runner's entry in its performance budget file (perf.json).

Measures like perf.measure (3 runs, median) and stores the result under runners.<runner> of the budget file, keeping the other runners' entries, the run settings and any "tolerance" already there. Run it once per kind of machine you want checked (the runner id is os-compiler-renderer, e.g. windows-msvc-d3d11-warp, linux-gcc-llvmpipe, macos-clang-metal-paravirtual; a Debug build adds -debug), and again when the game got heavier ON PURPOSE. A game sets its own budget the same way: `factoria call perf.baseline` writes <project>/perf.json, commit it, and `factoria call perf.check` (in CI it fails past the tolerance) checks it. File: {format:"factoria.perf/1", frames, scene?, input?, tolerance?: {cpuAvg:1.0 (ratio over the baseline), cpuP95:1.5, memory:0.1, drawCalls:0.1, entities:0.1, triangles:0.1, lights:0.1, textureMB:0.1, cpuSlackMs:1, memorySlackMB:8, textureSlackMB:1, countSlack:2}, budgets?: {maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities} (absolute caps, see perf.check), runners: {<id>: sample}}. A limit is max(baseline*(1+ratio), baseline+slack). `tolerance` here sets the file's tolerances. Returns {file, runner, sample, created}. Example: {"frames":300,"input":"replays/play.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | no | Budget file, project-relative (or absolute). Default "perf.json". |
| `frames` | integer | no | Frames per run; stored in the file (default: the file's value, else 300). |
| `scene` | string | no | Start scene; stored in the file. |
| `input` | string | no | Project-relative input replay; stored in the file. |
| `repeats` | integer | no | Runs to take the median of. Default 3. |
| `tolerance` | object | no | Tolerances to store in the file: cpuAvg, cpuP95, memory, drawCalls, entities, triangles, lights, textureMB (ratios), cpuSlackMs, memorySlackMB, textureSlackMB, countSlack. |

## `perf.check`

Since 0.2.0.

Measure the game and fail when it costs more than its performance budget (perf.json) allows on this runner.

Measures with the settings of the budget file (frames, scene, input) and compares with runners.<this runner> of the file (see perf.baseline for the format and the tolerances). Memory, draw calls, entities, triangles, lights and texture memory (the last three only when the baseline has them) past their limit FAIL always. The file's "budgets" object ({maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities}) or the `budgets` argument sets absolute caps that fail whatever the baseline says, also on a runner with no baseline. A time (cpuMsAvg, cpuMsP95) past its limit FAILS when the CI environment variable is set; elsewhere it only WARNS (status "warn"), because a developer machine can be busy. A time over the limit is measured a second time before it counts. A runner with no entry passes with status "no_baseline" and returns `baselineEntry`: the exact JSON to add under "runners" (or run perf.baseline here); with requireBaseline it fails instead (error `perf_no_baseline`, same data). Returns {runner, status: pass|warn|no_baseline, file, sample, rows: [{metric, measured, baseline, limit, exceeded}], message, baselineEntry?}; a failure is an error `perf_budget_exceeded` with the same data. Example: {} or {"file":"perf.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | no | Budget file, project-relative (or absolute). Default "perf.json". |
| `strictTime` | boolean | no | Make a time over its limit fail even outside CI (default: only in CI). |
| `requireBaseline` | boolean | no | Fail when this runner has no entry in the file, so a CI job cannot pass without checking anything. Default false. |
| `budgets` | object | no | Absolute caps that fail whatever the baseline says (they replace the same keys of the file's "budgets"): maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities. |

## `perf.measure`

Since 0.2.0.

Run the game headless for N frames and report its cost: CPU time per frame, peak memory, draw calls, entities, triangles, lights, texture memory.

Runs the project in a second headless engine inside this process, drawing every frame with the GPU renderer when there is one (graphics "none" otherwise: draw calls are 0), and returns {runner, sample: {frames, cpuMsAvg, cpuMsP95, cpuMsMax (CPU time of the engine per frame: process CPU, not wall clock, so a busy machine moves it less), peakMemoryMB (peak resident memory of the process), drawCalls, entities, triangles (of the main pass), lights (3D lights of the main pass plus Light2D lights of the same frame) and textureMB (GPU texture memory), all max over the run, graphics}}. `runner` is the id of this machine's and build's kind (os-compiler-renderer, plus -debug for a Debug build, e.g. linux-gcc-llvmpipe) that budget files key their baselines by. `input` is an input replay (like `factoria run --input`) to reach the heavy part of the game. Peak memory is the whole process's, so measure with the same host every time (`factoria call --no-graphics perf.measure`). Example: {"frames":300}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | How many frames to run (fixed step). Default 300. |
| `scene` | string | no | Start scene (default: the project's mainScene). |
| `input` | string | no | Project-relative input replay JSON applied during the run. |
| `repeats` | integer | no | Run this many times; time metrics are the median, memory/draw calls/entities the max. Default 1. |

## `perf.profile`

Since 0.2.0.

Run the game headless with the profiler on and report where the time goes: per engine system, per script behaviour class, GPU time, memory.

Use it when the game is slow and you need to know WHY (perf.measure only says how slow). Runs the project like perf.measure (drawing every frame with the GPU renderer when there is one) with the profiler on and returns {runner, graphics, profile}. profile = {frames, clock:"wall", frameMs:{avg,p95,max} (engine time of a frame), systems: {platform, physics, scriptsFixedUpdate, animation, scriptsEvents, ui, scriptsUpdate, audio, scriptsLateUpdate, localization, render, endOfFrame: {avgMs, p95Ms, maxMs}}, behaviours: [{class, path, avgMs (per frame, counting the frames it did not run), maxMs, callsPerFrame}] slowest first (every per-behaviour callback counts: onStart, onUpdate, onFixedUpdate, onLateUpdate, collision/trigger handlers, onEvent; timers, world.on handlers and promise jobs are the bucket "(timers, events and promises)"), gpu: {avgMs, p95Ms, maxMs, samples, reason} (milliseconds the GPU took to draw the world; null with a `reason` where the graphics backend has no timer queries: Metal, GLES3, WebGL2, or no GPU), memory: {start, end, peak: {processMB, jsHeapMB, textureMB, audioDecodedMB, entities}}}. Times are wall-clock milliseconds and vary a little from run to run: compare the ORDER and the big gaps, not the decimals. A system's time includes the behaviours it runs (scriptsUpdate holds every onUpdate). `warmup` frames (default 30) run first and are not counted, because the first frames load assets. Use `input` (an input replay) to reach the heavy part of the game. The profiler only measures: game.state, replays and saves are identical with it on. The editor's play sessions record the same section in play.report, and View > Profiler shows it live. Example: {"frames":300,"input":"replays/play.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | How many frames to profile (fixed step), after the warm-up. Default 300. |
| `warmup` | integer | no | Frames to run first and leave out of the numbers (assets load, caches fill). Default 30. |
| `scene` | string | no | Start scene (default: the project's mainScene). |
| `input` | string | no | Project-relative input replay JSON applied during the run. |

## `project.add_menu_kit` (modifies state)

Not released yet (on main after 0.2.0).

Copy the menu kit (main menu, options, pause, loading screen, ...) into the game and merge its strings into the locales.

The menu kit of docs/MENUS.md (templates/menus/ in the FactorIA install): `parts` picks what to copy, the files go to the same paths in the game (scripts/, scenes/, prefabs/ui/, tests/recipe.test.js) and the kit's strings are merged into locales/<language>.json for every language of factoria.json "localization" (added when the game has none). Scenes and prefabs are written in the canonical layout of scene.format. Parts that others need come along (the main menu needs core, options, credits, shop and ageGate) and are listed in `requiredBy`. A kit file the game already has and has changed is NOT touched unless `overwrite` is true: it is listed in `skipped`; a file that is the same is listed in `unchanged`, so running the command twice changes nothing. String keys the game already has are never replaced, with or without `overwrite`; only missing ones are added. A language the kit has no texts for gets the English ones. The "pause" part also adds the input action "pause" to factoria.json when it is missing. Returns {parts[], requiredBy{}, added[], unchanged[], overwritten[], skipped[{file,reason}], locales[{file,created,merged[],skipped[]}], settings[], nextSteps[]}. Examples: {} (all parts), {"parts":["pause"]}, {"parts":["main-menu","loading"],"overwrite":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `parts` | array | no | Which parts to add; default all. Parts and what they copy: core: Shared by every menu: the player's settings saved in storage (scripts/settings.js), the stack of panels that open over each other (scripts/ui/menu_stack.js), read-aloud for focused widgets (scripts/ui/read_aloud.js) and the menu.* strings.; options: The options panel: video, a colour filter, audio per bus, controls (rebinding) and language, saved between runs (prefabs/ui/options.prefab.json, scripts/ui/options.js).; credits: The credits panel that lists the software inside the runtime (scripts/ui/credits.js).; shop: The shop panel for in-app purchases (scripts/ui/shop.js) and the behaviour that pauses a level while the store's overlay is open (scripts/store_events.js). Needs the products in factoria.json "platform" (docs/PLATFORM.md).; ageGate: The age gate for a game whose ads reach children and adults (factoria.json platform.ads.audience "mixed"): a neutral birth-year screen (prefabs/ui/age_gate.prefab.json, scripts/ui/age_gate.js) that tells the ad network whether the player is under the age of consent with platform.ads.setUnderAge(). The main menu opens it once, before any ad; its tests/age_gate.test.js checks it.; main-menu: The title screen: scenes/menu.scene.json (Play, Options, Credits, Shop, Quit, with the options, credits, shop and age gate panels in it), scripts/main_menu.js, and tests/recipe.test.js, the kit's test, which drives the menu with a gamepad only. Needs core, options, credits, shop and ageGate: the scene uses their scripts and prefab.; pause: The pause menu (prefabs/ui/pause.prefab.json, scripts/pause_menu.js): Resume, Options, Main menu. Put one entity with scripts/pause_menu.js in every level; adds the "pause" action to factoria.json when the game has none.; loading: The loading screen (scenes/loading.scene.json, scripts/loading.js): the main menu's Play button goes through it to the first level.; keyboard: The on-screen keyboard for a player without a physical one (prefabs/ui/keyboard.prefab.json, scripts/ui/keyboard.js): put one entity with the script in every scene that has a TextField.; dialogue: Subtitles for spoken lines and hints: say(key, {sound, speaker}) in scripts/dialogue.js, drawn by a Captions entity. Its strings are the example lines captions.* (replace them with the game's own). |
| `overwrite` | boolean | no | Replace a kit file the game has changed (a file that is the same is left alone). Without it that file is left as it is and listed in `skipped`. String keys the game has are never replaced. Default false. |

## `project.create` (modifies state)

Create a new game project from a template.

Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, scripts, a test, AGENTS.md, ENGINE_FEEDBACK.json and the real types/factoria.d.ts. Afterwards start `factoria mcp --project <dir>` to work on it. Example: {"dir":"my-game","template":"2d-platformer","name":"My Game"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `dir` | string | yes | Target folder (created; must be empty or new). |
| `template` | string | no | 2d-empty, 2d-platformer or 3d-empty (see project.templates). Default "2d-empty". |
| `name` | string | no | Display name (default: folder name). |
| `id` | string | no | Reverse-DNS id, e.g. com.example.mygame. |

## `project.export` (modifies state)

Since 0.1.2.

Package the game for a platform: a desktop bundle, an Android APK/AAB, an iOS project, or a web page (HTML5).

Validates the project (factoria.json, name, mainScene, reverse-DNS id, the icon and export settings) and writes a fresh <out>/<game-slug>-<platform>/ folder (deleted and recreated on every call, but only when it is empty or an export wrote it: every export leaves a .factoria-export file at its top, and any other existing folder of that name is an error that says how to proceed, never deleted; the project itself is not modified). linux/windows/macos: the game plus the factoria_player runtime found next to the running factoria binary, so exporting for another OS than this machine's fails with a hint. android: a complete Gradle project that is then BUILT with its own Gradle wrapper (needs a JDK 17+ and the Android SDK, found automatically; the first build downloads Gradle and the Android Gradle plugin, so it takes minutes and needs network): `format` "apk" (default) or "aab" (Google Play bundle) leaves <slug>[-debug].apk/.aab next to the project and reports it as `artifact`; "gradle" only writes the project and builds nothing. `release` builds the release variant (signed with export.android.signing; without a keystore it is an error unless `allowDebugKey` is true); on linux, windows and macos it packs the whole game into one archive, game.pak, next to the executable (no game/ folder, no loose scripts: they become bytecode unless export.scriptBytecode is false) and reports it as `pack` with the packed paths in `packed`. ios: the game plus an Xcode/CMake project and build_ios.sh. Android and iOS have a mode, reported as `mode`: "prebuilt" (the engine is the ready-made player in the mobile/ folder next to the factoria binary of the FactorIA download: no engine source, and for Android no NDK or CMake) or "source" (the engine is compiled from a source checkout, chosen by $FACTORIA_ENGINE_DIR or when factoria runs from a development build); with no players and no checkout the error says what to do. A failed Gradle build is an error that quotes what went wrong and where the log is (<out>/<slug>-android/build.log); the Gradle project stays on disk. linux with `format` "appimage" also builds the whole game as one <out>/<slug>-linux/<slug>-x86_64.AppImage (reported as `artifact`; needs Linux x86_64 or WSL and the tools of `setup.install` component appimage; the folder export stays). web: <slug>-web/ holds index.html (the loading page), factoria_player.js and factoria_player.wasm (the Emscripten player, found with `player`, else next to the factoria binary in web/, else installed by `setup.install` component players with platforms ["web"], else a web build of the engine source) and game.pak (the whole game, scripts as bytecode, always, whatever `release` says), and <out>/<slug>-web.zip next to the folder holds the same with index.html at its root: upload it to itch.io as an HTML5 game (`artifact`, format "zip"; `mode` says where the player came from: explicit, package, installed or build). windows with `format` "msix" (or export.windows.format) also writes <out>/<slug>-windows.msix next to the folder, the package of the Microsoft Store, from any computer (reported as `artifact`, format "msix"; identity in export.windows.msix; sign it with `sign.windows`, upload it with `publish.microsoft`). A browser needs the folder served over http, not opened as a file (nextSteps has the command). macOS: sign and notarize the exported app with `sign.macos`. Every export also writes FACTORIA_NOTICES.txt, the licenses of the engine code inside the game, where it ships with it (`notices`). Returns {outputDir, mode (android/ios/web), format and artifact (android, web), pack (web too), notices, files[], nextSteps[], warnings[]}; nextSteps lists what to do next (e.g. the adb install command). dryRun: true runs every check and writes nothing (no Gradle either): it returns {platform, outputDir (the folder an export would replace), mode, format, artifact (the file a build would write) and toolchain (android: the JDK and SDK found and where from), player (desktop), warnings[]} or the error the export would give (e.g. no JDK installed). Details: docs_read {"name":"exporting"}. Examples: {"platform":"windows","release":true}, {"platform":"android","format":"aab","release":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platform` | string | no | linux, windows, macos, android, ios or web (aliases win, mac, osx, html5 also work). web: a folder with index.html, the web player and game.pak, plus <slug>-web.zip next to it for itch.io. Default: the machine running factoria. |
| `out` | string | no | Parent folder of the export, relative to the project folder and inside it. Default: build/export. |
| `format` | string ["apk","aab","gradle","appimage","msix","folder"] | no | Windows: msix also writes <slug>-windows.msix next to the export folder, the Microsoft Store package (any host; identity in export.windows.msix); folder (the default unless export.windows.format says otherwise) writes only the folder. Android: apk (an installable app, the default unless export.android.format says otherwise), aab (the Google Play bundle) or gradle (only the Gradle project, nothing is built and no JDK or SDK is needed); apk and aab run Gradle and need a JDK 17+ and the Android SDK. Linux: appimage also builds <slug>-x86_64.AppImage, the whole game as one file (needs Linux x86_64 or WSL, and `setup.install` component appimage once). Other platforms ignore it. |
| `release` | boolean | no | Android: build the release APK/AAB (signed with export.android.signing and the keystore passwords from FACTORIA_ANDROID_KEYSTORE_PASSWORD / FACTORIA_ANDROID_KEY_PASSWORD or ~/.factoria/export.json; without a keystore it is an error, see allowDebugKey). Desktop (linux, windows, macos): the game ships as ONE archive, game.pak, instead of the game/ folder, with the scripts compiled to bytecode unless export.scriptBytecode is false in factoria.json. iOS: only changes the build commands of the iOS script. Default false. |
| `allowDebugKey` | boolean | no | Android release build without a keystore (no export.android.signing in factoria.json): sign with the debug key instead of failing. Fine for trying the build on your own device; Google Play rejects such an app, so never upload it. Create a real keystore for the store (keytool -genkeypair, or the editor's Platform settings > Android). Default false. |
| `allowMissingPlugins` | boolean | no | Leave out a native plugin whose build for the target platform is missing (plugins/<name>/<platform>/, see docs_read EXTENDING.md) instead of stopping the export. Works for optional and non-optional plugins: a warning names each one and the result lists them in pluginsLeftOut[]. The exported game runs without the plugin (scripts that call it fail unless it is "optional" in factoria.json and they check for it). A plugin is built only for the computer you build it on (platform.add_backend and CMake): get the other platforms' builds from CI or another machine. The CLI flag is --allow-missing-plugins. Default false. |
| `allowPlayerMismatch` | boolean | no | Desktop (linux, windows, macos): bundle the factoria_player even when it was built from another commit than this factoria (its build fingerprint differs or is missing). By default that export stops with an error, because an old player may lack what the game uses (components, script API) or fail to start; the CLI flag is --allow-player-mismatch. Rebuild both from one checkout instead when you can. Default false. |
| `dryRun` | boolean | no | Only check whether the export can run (project, player or mobile mode, output folder): returns the plan or the error, writes nothing. Default false. |

## `project.info`

Show the project settings, input actions, current scene, scenes and scripts.

Returns the parsed factoria.json plus {currentScene, scenes[], scripts[], prefabs[], sceneErrors}. Example: project.info {}

## `project.new_ci_workflow` (modifies state)

Since 0.2.0.

Write a GitHub Actions workflow that validates, tests and exports the game on every push.

Writes .github/workflows/factoria.yml into the game's folder. On every push to main or master and every pull request it installs FactorIA on an Ubuntu 24.04 runner (the release package of the SAME version as this factoria, checked against the SHA-256 GitHub lists; a build from source has no release of its own, so it follows the newest one and warns), installs the OpenGL/X11/Xvfb libraries, runs `factoria validate` and `factoria test` under xvfb-run, downloads the other players (`factoria setup players`), exports the game for Linux and Windows, and on a macOS runner for macOS, and uploads the exports as workflow artifacts (tar.gz; the Windows one is a zip). It never overwrites a file that differs unless `overwrite` is true (an identical file is left alone). Project templates do not carry the file: call this when the game goes on GitHub. A game in a subfolder of the repository: GitHub reads workflows only from the repository root, so write it with `workingDirectory` set to that folder and move the file to <repo>/.github/workflows/. Returns {path, written, dryRun, version, repo, platforms[], workflow (the YAML), warnings[], nextSteps[]}. Details: docs_read {"name":"exporting"}, "CI for your game". Examples: {}, {"platforms":["linux","windows"],"dryRun":true}, {"workingDirectory":"games/my-game","overwrite":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports the workflow makes: linux, windows, macos (aliases win, mac, osx also work). Default: all three. |
| `path` | string | no | The workflow file, relative to the project: .github/workflows/<name>.yml. Default: .github/workflows/factoria.yml. |
| `workingDirectory` | string | no | The game's folder relative to the repository root when factoria.json is not at the root of the repository. Default ".". |
| `version` | string | no | The FactorIA release the workflow downloads: "latest" or a version such as 0.1.6. Default: the version of this factoria (a build from source: latest, with a warning). |
| `overwrite` | boolean | no | Replace the file when it exists and differs. Without it that is an error. Default false. |
| `dryRun` | boolean | no | Return the workflow and what would happen; write nothing. Default false. |

## `project.new_plugin` (modifies state)

Since 0.1.6.

Create a native plugin (C/C++) for this game and declare it in factoria.json.

Writes a plugin folder (default plugins/<name>, or `path`: project-relative, absolute, or with ${VARIABLE} parts for a private folder outside the repository) holding src/plugin.c, include/fa_plugin.h (the whole C API), CMakeLists.txt, README.md and android/ (the Gradle module of its Android build), and adds "plugins": {"<name>": {"path", "platforms", "optional"}} to factoria.json (`platforms` defaults to this computer's; `optional` to true: the game runs, and exports with allowMissingPlugins, without the build). The plugin adds the script function plugins.<name>.add(a, b) and the command <name>.info: build it with CMake (nextSteps), then `factoria run` loads it. `template` (default "basic") picks another starting point: a platform backend for a store (the folders of platforms/plugins/ in the engine; docs/PLATFORM.md, "Writing a backend"). The name: lower-case letters, digits and underscores, not an engine area (scene, game, ...). Fails when factoria.json already declares the plugin or the folder is not empty. Only that key of factoria.json changes: the other keys, their order and the layout stay as they are. With `dryRun` true nothing is written: the result lists the `files` and the `keys` of factoria.json it would write. An argument that does not exist is an error with a "did you mean". Returns {folder, files[], keys[], plugin, nextSteps[], dryRun?}. Details: docs_read {"name":"extending"} (section G). Example: {"name": "example"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | The plugin's name: scripts call plugins.<name>.<function>() and its commands are <name>.<verb>. |
| `template` | string | no | What to start from: "basic" (an example command and function) or a store backend template shipped with the engine (the folders of platforms/plugins/: they answer the game's platform.* calls, docs/PLATFORM.md). An unknown name lists the available ones. Default "basic". |
| `path` | string | no | Its folder (default plugins/<name>): project-relative, absolute, or with ${VARIABLE} parts. |
| `platforms` | array | no | The platforms it will be built for (default: this computer's). |
| `optional` | boolean | no | Written as "optional" in factoria.json: true = the game runs without the plugin (a missing build is a validate warning, not an error). Pass false when the game cannot work without it. Default true. |
| `dryRun` | boolean | no | true = write nothing: list the files and the factoria.json keys it would write. Default false. |

## `project.templates`

List the project templates `project.create` can start from.

Returns [{name, description, dimension}]. Example: {}.

## `project.test` (modifies state)

Run the project's JavaScript tests (tests/*.test.js) headless and return the report.

Tests run inside this engine instance and change the world; reload the scene afterwards (scene.reload). `files` runs only those test files: project-relative paths, folders or globs such as tests/ui*.test.js (a path that is not a *.test.js file is an error that says what to pass). Example: project.test {"filter":"player","files":["tests/saves.test.js"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `filter` | string | no | Only run test cases whose name contains this. |
| `files` | array | no | Test files, folders or globs, project-relative (default: every tests/**/*.test.js). |

## `project.validate`

Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.

Run after every batch of edits. Returns {ok, errors[], warnings[]}; each issue has file, JSON pointer, message and a fix hint. Checks every *.scene.json and *.prefab.json of the project, wherever it is kept (scenes/, prefabs/, levels/...; folders starting with '.', node_modules and a top-level build/ are skipped, like scene.format). Loads every scene, and every prefab on its own, into a temporary world, so it does not disturb a running game; anything the loader refuses is an error with the JSON pointer, e.g. an unknown field or a value outside a field's range ("Field 'sides': value 200 is outside the allowed range 3..64"; the offending field keeps its default, nothing is clamped). Scene and prefab files whose whitespace differs from what scene.save writes are valid: they give ONE entry in `notes` (informational, not a warning; optional fix: scene.format). The result has `ok`, `errors`, `warnings`, `notes`, `scenesChecked`, `scriptsChecked`, `materialsChecked`. It reports a .json that a script imports and that is not valid JSON once, as that file with line and column. Example: {} Warns about Script.props keys that do not exist on the behaviour, and about behaviour methods that look like misspelled lifecycle hooks (update() or onupdate() instead of onUpdate()).

