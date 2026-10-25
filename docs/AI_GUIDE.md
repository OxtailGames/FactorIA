# How to build a game with FactorIA (for AI agents)

Read this guide before you change a FactorIA game. Read it with `factoria docs read ai-guide`, or over MCP with `docs_read {"name":"ai-guide"}` or the resource `factoria://docs/AI_GUIDE.md`. The `AGENTS.md` in your project repeats the short rules.

Every name here is part of this build's contracts. Check a name before you use it: `factoria api --md` lists every component field, `factoria commands` lists every command and its arguments (`factoria commands scene.spawn` shows one), and `factoria docs search <words>` searches these docs. Over MCP use `docs_components`, `docs_commands` and `docs_search`. Do not guess component fields or command arguments.

## 1. Mental model

A game is a folder of text files:

```
my-game/
  factoria.json           project settings: display, physics, input actions, main scene, icon and per-platform export settings (docs: exporting)
  scenes/*.scene.json     levels: entities with components
  prefabs/*.prefab.json   reusable entities (optional)
  scripts/*.js            behaviours: game logic as JavaScript classes
  tools/*.js              project tools: commands you (and other AIs) can call
  plugins/<name>/         native plugins: C/C++ code for this game, plugins.<name>.<fn>() in scripts (optional; docs: extending, G)
  tests/*.test.js         headless tests
  data/*.json             level or balance data, imported from scripts (optional)
  assets/                 images, sounds, fonts, models (only when you need them)
  types/factoria.d.ts     generated script typings (do not edit)
  AGENTS.md               short guide for AI agents, written by `factoria new`
  ENGINE_FEEDBACK.json    engine gaps you met (see THE FEEDBACK RULE)
  .factoria/              generated output: screenshots, logs (do not edit; scratch files go in .factoria/tmp/)
```

- **Components are data.** An entity has a stable `id`, optional `name` and `tags`, and components such as `Transform`, `Sprite` or `RigidBody2D`. Engine systems (rendering, physics, audio, scripts) read them.
- **Behaviours are JavaScript.** Logic lives in classes that extend `Behaviour`. Attach one with the `Script` component: `"Script": {"path": "scripts/player.js", "props": {"speed": 300}}`. `props` override the class fields, so one script serves many entities.
- **Commands are tools.** Every engine capability is a named command, such as `scene.spawn`. Over MCP the name has `.` replaced by `_`: `scene_spawn`. The file `tools/spawn_wave.js` becomes the command `project.spawn_wave` and the MCP tool `project_spawn_wave`.
- **The simulation is fixed-step and deterministic.** It runs at `physics.fixedHz` steps per second (60 by default). The same seed and the same input give the same result, so tests are reliable.

## 2. The development loop

Repeat it for every change. Make small steps: change one thing, validate, run, look.

1. **Read.** `factoria docs read scripting` for the script API, `factoria api --md` for components, `factoria docs search "..."` for the rest. Over MCP: `docs_list`, `docs_read {"name":"scripting"}`, `docs_components`, `docs_search {"query":"..."}`.
2. **Edit** scenes, prefabs, `scripts/`, `tools/`, `tests/`, `data/` or `factoria.json`.
3. **Validate.** `factoria validate` (MCP: `project_validate`). Fix every error using its file, JSON pointer and hint. Run `factoria validate --fix-types` when the typings are out of date (it rewrites `types/factoria.d.ts`). It must be clean before you go on.
4. **Run and LOOK.** `factoria run --headless --frames 120 --screenshot-at 119 --json` (MCP: `game_step {"frames":120}`, then `game_screenshot`). The report lists the PNG paths. Open the image and check that it shows what you intended. `scriptErrors` in the report and `game_logs` show script problems. A clean validation does not prove that the scene is right.
5. **Test.** Add or update a test in `tests/*.test.js` for every behaviour. Run `factoria test` (MCP: `project_test`). A bug fix starts with a test that fails.
6. **Debug the live game** when a test is not enough: `factoria session` keeps one game running and answers one JSON request per line (section 11).
7. **Report gaps** as soon as you meet them (section 3).

Done means: `project_validate` is clean, a screenshot shows the intended result, the tests pass and cover the new behaviour, and every engine gap you met is recorded in `ENGINE_FEEDBACK.json`.

## 3. THE FEEDBACK RULE (mandatory)

Whenever the engine lacks a feature, has a bug, gives an error that does not say how to fix it, or has a wrong or missing doc, **and** you build a workaround or drop the feature: record it now, in the same turn, before you continue. Do not wait until the end of the task. Duplicates are fine: a similar open entry in the same category is merged, and its `occurrences` count goes up. Not reporting is the only wrong choice.

Call the MCP tool `feedback_report`, or run `factoria call feedback.report '{...}'`, or run `factoria feedback add --category ... --severity ... --title ... --missing ... --workaround ...` (`--missing` needs a few words, not one). All three write to `ENGINE_FEEDBACK.json`.

| Field | Value |
|---|---|
| `category` | one of: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation, tooling, ai-integration, docs, platform, performance, networking, other |
| `severity` | `blocker` (could not build it), `major` (large or fragile workaround), `minor` (small workaround), `nice-to-have` (convenience) |
| `title` | short noun phrase, such as "No gamepad rumble". Reuse the same wording for the same gap. |
| `missing` | what you needed and what the engine did instead |
| `workaround` | what you did instead, with `workaroundFiles` (project-relative paths) |
| `suggestion` | the engine change that would remove the workaround: a field, a command or an API |

The tool requires `category`, `severity`, `title`, `missing` and `workaround`. Always add `workaroundFiles` and `suggestion` as well, because the engine team needs them. `effort` (`small`, `medium`, `large`) and `reporter` (`{"kind":"ai","agent":"...","model":"..."}`) are optional. Call `feedback_list {"status":"open"}` (or `factoria feedback list --status open`) to see what is already recorded.

Good example, a missing input feature:

```json
{
  "category": "input",
  "severity": "minor",
  "title": "No gamepad rumble",
  "missing": "The game wants to vibrate the controller when the player is hit, but scripts have no rumble API.",
  "workaround": "none: feature dropped. A hit is shown with a screen shake only.",
  "suggestion": "Add input.gamepad(i).rumble(strong, weak, seconds) that vibrates the pad."
}
```

Good example, a missing scene feature:

```json
{
  "category": "scene",
  "severity": "minor",
  "title": "No flip or rotate flags for single tiles",
  "missing": "A Tilemap tile index always draws the tile upright, so a mirrored slope or a rotated corner needs its own copy in the tileset image.",
  "workaround": "assets/tiles.png has a mirrored copy of every slope tile; the map uses those indices.",
  "workaroundFiles": ["assets/tiles.png", "scenes/level1.scene.json"],
  "suggestion": "Let a tile entry carry flipX, flipY and rotate flags, for example as bits of the tile index."
}
```

Bad example:

```json
{
  "category": "other",
  "severity": "major",
  "title": "It does not work",
  "missing": "stuff",
  "workaround": "changed it"
}
```

It passes the schema and is still useless. The title names no gap, `missing` does not say what was needed, the workaround names no file, and there is no suggestion, so the engine team cannot act on it. Write each entry so that a developer who has never seen your project understands the gap.

Without MCP and without the CLI, add an object to the `entries` array of `ENGINE_FEEDBACK.json` by hand. It must match `schemas/engine-feedback.schema.json`, which also requires `id` (`FB-0001`, the next free number), `date`, `occurrences` and `status`. The tools set those for you, so prefer them.

## 4. Using the MCP tools and the CLI

A tool name is the command name with `.` replaced by `_`. Arguments are one JSON object. Results are JSON, and a screenshot comes back as an image. A failure returns `code`, `message` and `hint`; the hint says how to fix it. An unknown name returns a "did you mean" suggestion. `docs_commands` lists every command with its `inputSchema`, so use it to get exact argument names.

| Tool | Command | Purpose |
|---|---|---|
| `docs_list`, `docs_read`, `docs_search`, `docs_components`, `docs_commands` | `docs.*` | Read the built-in docs, the component reference and the command list. |
| `project_validate` | `project.validate` | Check the whole project. Returns `ok`, `errors[]`, `warnings[]` and `notes[]` (informational, nothing to fix: for example that some scene files are formatted by hand, which is valid); each issue has `file`, `pointer`, `message` and `hint`. It loads every `*.scene.json` and `*.prefab.json` of the project wherever it is kept (not only `scenes/` and `prefabs/`; hidden folders, `node_modules` and a top-level `build/` are skipped), each prefab on its own too, so a value outside a field's range (`Shape2D.sides` 200 when the range is 3..64) is an error with the JSON pointer and the allowed range. Nothing is clamped: fix the value. |
| `shader_compile`, `material_info` | `shader.compile`, `material.info` | Custom materials (`*.material.json`, schema `schemas/material.schema.json`): `material_info {"material":"materials/water.material.json"}` describes lighting, params (type, default, range, doc), textures and programs; `shader_compile` compiles its GLSL snippet for the dialects of some platforms (`{"material":...,"platforms":["windows","web"]}`, default all) and returns `errors[]` with `file`, `line`, `column`, `source` and a fix `hint`; call it until `ok`. `project_validate` does the same for every material. The guide for writing the snippet: `docs_read {"name":"shaders"}`. Needs sokol-shdc: the factoria downloads carry it next to `factoria`; otherwise `factoria setup shaders` or `SOKOL_SHDC`. |
| `project_test` | `project.test` | Run `tests/*.test.js` headless, optionally `{"filter":"player","files":["tests/saves.test.js"]}` (files, folders or globs). Tests change the running world, so call `scene_reload` afterwards. |
| `project_export` | `project.export` | Package the game: `{"platform":"windows","release":true}` (all optional: `platform` default this machine, `format` for Android and `appimage` for Linux, `out` parent folder relative to the project, `release`). Desktop needs the `factoria_player` next to the running binary; Android writes a Gradle project and BUILDS the APK (`format` `apk`, default) or the Play bundle (`aab`) with the project's own Gradle wrapper (needs a JDK 17+ and the Android SDK; the first build downloads Gradle and takes minutes; `gradle` only writes the project), `format` `appimage` on Linux x86_64 (or WSL) also builds `<slug>-x86_64.AppImage` after `setup_install {"component":"appimage"}` (about 16 MB), iOS a Mac build script, using the ready-made `mobile/` runtime of the download (`mode` `prebuilt`, no NDK or engine source) or an engine checkout (`source`). `release` on Android signs with `export.android.signing` and the passwords from `FACTORIA_ANDROID_KEYSTORE_PASSWORD` / `FACTORIA_ANDROID_KEY_PASSWORD` (never put them in the project); on linux, windows and macos it puts the whole game in ONE `game.pak` next to the executable (no `game/` folder), with the scripts compiled to bytecode unless `export.scriptBytecode` is `false` in `factoria.json`. Returns `outputDir`, `mode`, `format`, `artifact` (the built file), `notices`, `pack` and `packed` (a release desktop export), `files`, `nextSteps`, `warnings`; `dryRun: true` only checks (returns the `outputDir` it would write, `toolchain` with the JDK and SDK found, or the error) and writes nothing. The export replaces `outputDir` only when an export wrote it (it holds `.factoria-export`) or it is empty; any other folder there is an error, never deleted. Every export writes `FACTORIA_NOTICES.txt` (the licenses of the engine runtime inside the game): it must stay in what the user ships. See `docs_read {"name":"exporting"}`. |
| `sign_macos` | `sign.macos` | Sign, notarize and staple the exported macOS app with the user's Developer ID, then zip it to share (`<slug>-macos.zip`): `{"identity":"Developer ID Application: Name (TEAMID)","keychainProfile":"factoria-notary"}`. Needs a Mac for a real run (elsewhere it is an error that says so); `{"dryRun":true}` lists the exact command lines on any computer, so use that first and show them. The identity and the notary login come from the arguments, `FACTORIA_MACOS_SIGN_IDENTITY` / `FACTORIA_NOTARY_PROFILE` (or an API key, or an Apple ID) or `sign.macos.*` of `~/.factoria/export.json`; the Apple ID app-specific password only from `FACTORIA_APPLE_APP_PASSWORD`: never ask for a password to put in an argument, never write one in the project. `provisioningProfile` is needed for the Game Center / iCloud entitlements the export writes. Sign again after every export. Returns `signed`, `verified`, `notarized`, `stapled`, `zip`, `steps[]`, `warnings[]`. See `docs_read {"name":"exporting"}`. |
| `project_new_ci_workflow` | `project.new_ci_workflow` | Write `.github/workflows/factoria.yml`, a GitHub Actions workflow that installs the FactorIA release of the same version (checksum verified), runs `factoria validate` and `factoria test` under Xvfb, exports Linux and Windows on Ubuntu and macOS on a macOS runner, and uploads the exports as artifacts. Call it when the game goes on GitHub; `{"platforms":["linux","windows"],"dryRun":true}` shows it first. It never overwrites a file that differs unless `overwrite` is true. A game inside a larger repository: `workingDirectory` is its folder, and the file must live in the repository root's `.github/workflows/`. Returns `path`, `written`, `version`, `workflow`, `warnings[]`. See `docs_read {"name":"exporting"}`, "CI for your game". |
| `publish_steam`, `publish_itch`, `publish_epic`, `publish_gog`, `publish_appstore`, `publish_googleplay` | `publish.steam`, `publish.itch`, `publish.epic`, `publish.gog`, `publish.appstore`, `publish.googleplay` | Upload the desktop exports `project.export` made (`build/export/<slug>-windows|macos|linux`) to a store with its own uploader (steamcmd, butler, BuildPatchTool, GOG Galaxy Pipeline Builder): `{"dryRun":true}` first (writes the build files into `.factoria/publish/<store>/`, runs nothing, returns the exact command lines and what would be uploaded where), then `{}` or `{"platforms":["windows"]}`. The ids of the game are in the `publish` object of `factoria.json` (`steam.account`/`depots`, `itch.game`, `epic.organizationId`/`productId`/`clientId`/`artifacts`, `gog.productId`; `factoria validate` checks them); Steam also needs the app id in `steam_appid.txt` (`appId` overrides it) and takes `branch` (a beta branch to set live; never `default`), GOG takes `branch`. Secrets never go in the project or the arguments: Steam and itch.io use the login the tool cached (`steamcmd +login`, `butler login`; `BUTLER_API_KEY` also works), Epic `FACTORIA_EPIC_CLIENT_SECRET`, GOG `FACTORIA_GOG_USERNAME` + `FACTORIA_GOG_PASSWORD`. A tool that is not installed is an error with its download page (in a `dryRun` it and any missing secret or id are warnings and the plan is still returned; set `FACTORIA_STEAMCMD`, `FACTORIA_BUTLER`, `FACTORIA_BUILDPATCHTOOL` or `FACTORIA_GOG_PIPELINE_BUILDER`, or `publish` in `~/.factoria/export.json`; nothing is downloaded). Returns `uploaded`, `uploads[{platform, folder, destination, files, bytes, uploaded}]`, `steps[{command, commandLine, ran, exitCode}]` (secrets as `<redacted>`), `log`, `warnings`, `nextSteps`; a failing tool is an error whose `data` is that report. The mobile stores upload one built file: `publish_googleplay` the release `.aab` (`factoria export --platform android --format aab --release`; `publish.googleplay` in `factoria.json`: `track`, `releaseStatus` draft or completed, `changelogs`; the service account key is the file named by `FACTORIA_GOOGLEPLAY_JSON_KEY`; the first bundle of an app is uploaded by hand in the Play Console; a debug-signed bundle is refused) and `publish_appstore` the `.ipa` you exported from an Xcode archive (`build/export/<slug>.ipa`; macOS only; `publish.appstore.appleId`; the API key is the file `FACTORIA_APPSTORE_API_KEY` with `FACTORIA_APPSTORE_API_KEY_ID` and `FACTORIA_APPSTORE_API_ISSUER`); both take `artifact` instead of `platforms`, and `publish_googleplay` takes `track` and `releaseStatus`. Raise the game's `version` before every upload (Epic accepts each version once per artifact; Google Play each version code, App Store Connect each build number). See `docs_read {"name":"exporting"}`, "Uploading to stores". The per-store checklists (what FactorIA does, what the user still does by hand, review times): `docs_read {"name":"publishing"}`. |
| `setup_status`, `setup_install` | `setup.status`, `setup.install` | Check and install what an export needs on this computer: the Android JDK + SDK (`android`), the `factoria_player` of other platforms and the mobile libraries (`players`), CMake (`cmake`), Xcode (`xcode`, guidance only), appimagetool and the AppImage runtime for a Linux AppImage export (`appimage`, Linux x86_64 only), sokol-shdc, the shader compiler of custom materials (`shaders`). `setup_status {"component":"android"}` (read-only) returns each component's `state`, `problems[]` and, while the Android SDK license is not accepted, its full text in `licenses[]`. `setup_install {"component":"android","acceptLicenses":true}` downloads hundreds of MB into `~/.factoria` (checksums verified) and returns `steps[]`, `paths`, `nextSteps`. Run it when an export fails for a missing JDK, SDK, player or CMake, but ASK THE USER first, and set `acceptLicenses` only after the user has read the license text and said yes: it is a legal agreement with Google, never accept it for them. See `docs_read {"name":"exporting"}`. |
| `scene_list_entities` | `scene.list_entities` | List entities. Filters: `name` (substring), `tag`, `component`, `limit`. |
| `scene_get_entity` | `scene.get_entity` | One entity with every field, by `id` (or name). |
| `scene_spawn` | `scene.spawn` | Create an entity: `{"prefab":"prefabs/enemy.prefab.json","position":[300,0]}`, or entity JSON with `name`, `tags`, `components` and an optional `parent` id. |
| `scene_set_component`, `scene_remove_component` | `scene.set_component`, `scene.remove_component` | Set fields with `{"id":"player","component":"Shape2D","fields":{...}}`, or remove a component by `id` and `component`. A value outside a field's range is refused with the range and the nearest allowed value, and nothing changes. A free-form field (`Script.props`) is replaced as a whole; add `"merge": true` to read `fields` as a JSON merge-patch (RFC 7386) instead: `{"id":"level","component":"Script","merge":true,"fields":{"props":{"levelIndex":3,"old":null}}}` changes `levelIndex`, deletes `old` and keeps every other prop. |
| `scene_destroy` | `scene.destroy` | Destroy an entity and its children: `{"id":"coin_1"}`. |
| `scene_set_parent` | `scene.set_parent` | Move an entity under another one, or to the top level: `{"id":"coin_3","parent":"chest"}`; `"parent":null` (or `""`) makes it a root. By default it stays where it is on screen (its local Transform is recomputed); `"keepWorldTransform":false` keeps the local Transform. A parent that is the entity or one of its children is refused. |
| `scene_import_ascii` | `scene.import_ascii` | Build a tile level and its objects from ASCII `rows` and a `legend` (section 9.8): `{"rows":["..o..","#####"],"legend":{"#":0,"o":{"prefab":"prefabs/coin.prefab.json"}},"tilemap":{...},"path":"scenes/level1.scene.json"}`. With `path` it edits that scene FILE and never touches the running game. |
| `scene_ascii_edit` | `scene.ascii_edit` | Edit the ASCII map of a level args file with ops (`fill`, `replace`, `insertColumns`, `deleteColumns`, `put` with `row` or `above`) and rebuild the level (section 9.8): `{"file":"levels/1-1.json","ops":[{"op":"put","col":40,"glyph":"o","above":1}]}`. |
| `scene_load`, `scene_save`, `scene_reload` | `scene.load`, `scene.save`, `scene.reload` | Load `{"path"}`, save the running world (optional `path`), or reload the current scene. |
| `prefab_save` | `prefab.save` | Save an entity of the running world, with its children, as a prefab file: `{"id":"enemy_3","path":"prefabs/enemy.prefab.json"}`. It does not overwrite a file unless `"overwrite":true`. Section 6 says what the file leaves out. |
| `scene_format` | `scene.format` | Put hand-edited scenes and prefabs in the canonical layout without loading them: `{"paths":["prefabs"]}` formats those files or folders, `{"all":true}` the whole project, `{"check":true}` only lists (with none of the three it writes nothing and fails, naming the files it would change) the files that are not canonical (`"strict":true` makes that an error). Section 6. |
| `game_step` | `game.step` | Advance N fixed frames: `{"frames":60,"press":["move_right"]}`. `press` and `release` apply before the first frame and stay in effect until released. |
| `game_input` | `game.input` | Press or release an action or key now, or move the mouse, a gamepad or a finger. Forms: `{"action":"jump","down":true}`, `{"key":"Space","down":false}`, `{"mouse":{"position":[640,360]}}`, `{"gamepad":{"index":0,"buttons":{"A":true},"axes":{"LeftX":-1}}}`, `{"touch":{"id":1,"position":[200,300],"down":true}}`, `{"back":true}` (the phone's Back button: the `input.onBack` handlers run on the next step, and the game quits if none consumes it). The next `game_step` sees the input. |
| `screen_set_safe_area` | `screen.set_safe_area` | Pretend the device has a notch or system bars: `{"profile":"phone-portrait"}` (also `phone-landscape`, `none`) or `{"top":40,"left":10}` in design pixels. Items with `safeArea: true` move and `screen.safeArea` in scripts reports it; then `game_step` and `game_screenshot`. |
| `game_screenshot` | `game.screenshot` | Capture the game view as it is now (changes since the last step included) as an image. Optional `path`; by default it is saved under `.factoria/screenshots/`. Optional `scale` (0.25 to 4): the same frame drawn natively larger, for store screenshots (1280x720 at 1.5 = 1920x1080, HUD and visible area unchanged; `--width/--height` would change them). Optional `simulate` (`greyscale`, `protanopia`, `deuteranopia`, `tritanopia`): the saved image shows what a colour-blind viewer sees, to check that hazards and pickups read without their colour (section 9.20.1). Needs graphics. |
| `game_state` | `game.state` | Dump the running game: entities, physics, script errors, render stats. Filters: `entities` (ids), `components` (names), `includeDefaults`, `maxEntities` (default 200). |
| `game_logs` | `game.logs` | Recent log lines: `{"minLevel":"warn","max":50}`. Pass `after` (a `seq` from an earlier call) to get only new lines. |
| `game_pause`, `game_resume` | `game.pause`, `game.resume` | Pause or resume the simulation. |
| `play_sessions`, `play_report` | `play.sessions`, `play.report` | What the user saw while playing in the editor (Play .. Stop): `play_report {}` returns the latest session with frame-time stats (avg, p95, max), the slowest frames, a `profile` (where the time went: ms per engine system and per script behaviour class, GPU, memory; `perf_profile` gives the same for a headless run), warnings/errors, the problems the user marked with F9 (frame, note, screenshot; the first one comes back as a picture, `{"mark":2}` for the next) and the path of `input.json`, an input replay for `factoria run --headless --input`. **When the user says they played and found problems (slow, ugly UI, bugs), call `play_report` first**, then replay or inspect the marked frames. `play_sessions` lists older ones. |
| `audio_log` | `audio.log` | Sounds played so far (scripts, `AudioSource`, music), oldest first: `{"path":"jump.wav"}` keeps one clip (a file name matches any folder). Each play has `frame`, `path`, `volume`, `bus`, `source` (entity id) and `ok` (false = the clip failed to load). Pass `after` (a `seq`) for only new plays. |
| `script_eval` | `script.eval` | Evaluate JavaScript in the running game: `{"code":"world.findByTag(\"coin\").length"}`. |
| `script_errors` | `script.errors` | Exceptions thrown by scripts. Cleared by `scene_load`/`scene_reload`. |
| `script_reload` | `script.reload` | Re-import scripts edited on disk without reloading the scene (`scene_load`/`scene_reload` already do it, and re-read the input actions of `factoria.json`). `{"force":true}` re-imports every module. |
| `physics_raycast` | `physics.raycast` | First hit of a ray: `{"from":[0,300],"to":[0,-300]}` in 2D. In 3D pass `"dimension":"3d"`, `origin`, `direction`, `maxDistance`. Takes the options of the script API and of `physics_shape_cast`: `mask`, `ignore` (id of an entity whose colliders, and its children's, are skipped: the caster) and `ignoreTriggers` (default `true`; `false` hits trigger colliders too): `{"from":[0,300],"to":[0,-300],"ignore":"player","ignoreTriggers":false}`. |
| `physics_shape_cast` | `physics.shape_cast` | First collider a shape with size touches while its centre moves from `from` to `to`: `{"shape":{"shape":"box","size":[32,48]},"from":[0,100],"to":[0,-300],"ignore":"player"}`. 2 numbers in `from`/`to` = 2D (`circle` with `radius`, `box` with `size:[w,h]`), 3 numbers = 3D (`sphere`, `box` with `size:[x,y,z]`). Also takes `mask` and `ignoreTriggers`. Returns `{"hit":false}` or `{hit, entity, point, normal, distance}` (section 9.21). |
| `assets_generate_image`, `assets_generate_sprite_sheet`, `assets_generate_sound`, `assets_generate_music`, `assets_generate_voice`, `assets_generate_model` | `assets.generate_*` | Generate art, sounds, music, speech and 3D models with the asset providers of `ai.json`, write them under `assets/` and record their provenance. `assets_generate_image` returns the picture. Section 9.23. |
| `assets_provenance`, `assets_set_provenance`, `assets_disclosure` | `assets.provenance`, `assets.set_provenance`, `assets.disclosure` | Where each asset came from (and the files with no record), recording it for files you did not generate, and the AI-content text for store forms. Section 9.23. |
| `api_components`, `api_commands`, `api_scripting`, `assets_list`, `engine_info`, `project_info` | `api.*`, `assets.list`, `engine.info`, `project.info` | Introspection of the engine, the API and the project. |
| `fs_list`, `fs_read`, `fs_write`, `fs_edit`, `fs_search`, `fs_delete` | `fs.*` | Project files, sandboxed to the project folder (writes and deletes skip `.factoria/` except the scratch folder `.factoria/tmp/`). Every file the engine and these commands write is replaced atomically (a temporary `<name>.fa-tmp...` file next to it is renamed over the target, and removed if that fails), so a crash, a full disk or the hot-reload watcher never sees a half-written scene. Use them if your client has no file tools. |
| `assets_import`, `assets_slice_sheet` | `assets.import`, `assets.slice_sheet` | Bring a file made elsewhere into `assets/` with its provenance, and make a sprite sheet playable by `SpriteAnimator` (section 9.23). |
| `assets_draw_icon`, `assets_draw_capsules` | `assets.draw_icon`, `assets.draw_capsules` | Draw the game icon (1024x1024) and the Android adaptive-icon foreground from shapes and text, and the store page images (capsules, heroes, covers) at each store's sizes from key art and a logo, no image provider needed (docs: assets, exporting). |
| `feedback_report`, `feedback_list`, `feedback_update` | `feedback.*` | The FEEDBACK RULE. |
| `project_<name>` | `project.<name>` | Your own tool from `tools/<name>.js`. |

Examples:

```
docs_read {"name":"scripting"}
docs_search {"query":"raycast"}
project_validate {}
scene_spawn {"prefab":"prefabs/enemy.prefab.json","position":[300,0]}
game_step {"frames":120}
game_step {"frames":60,"press":["move_right"]}
game_screenshot {}
game_state {"components":["Transform","RigidBody2D"],"maxEntities":50}
game_logs {"minLevel":"warn","max":50}
script_eval {"code":"world.findByTag(\"coin\").length"}
fs_read {"path":"scripts/player.js","startLine":1,"endLine":40}
fs_edit {"path":"scripts/player.js","find":"speed = 300","replace":"speed = 360"}
feedback_list {"status":"open"}
```

The argument names above are the ones the engine accepts. `fs_edit` requires the text in `find` to match exactly once, unless you pass `"replaceAll": true`.

Without MCP, the same commands run from a shell: `factoria commands` lists them, `factoria call <command> '<json>'` runs one on a fresh engine, and `factoria call --batch` or `factoria session` run several on one engine (section 11).

The MCP server also offers prompts: `make-game` (argument `idea`), `add-feature` (`feature`), `fix-bug` (`description`) and `report-engine-gap`.

## 5. Coordinates, units and conventions

| Topic | Rule |
|---|---|
| 2D world | Units are design pixels. +X is right and +Y is up. The origin is the centre of the screen. With the 1280x720 design size of the templates, a default camera shows x from -640 to 640 and y from -360 to 360. |
| Screen space | `"space": "screen"` on Sprite, Shape2D, Text or ParticleEmitter. Units are design pixels, the origin is the top-left corner and +Y points down. Cameras do not affect it. Use it for HUD and menus. Section 9.4 shows how to pin items to the corners. |
| `anchor` and `pivot` | Screen space only: `anchor` (0..1 in each axis) is the screen point the position is relative to: [0,0] top-left, [1,0] top-right, [0,1] bottom-left, [1,1] bottom-right. `pivot` is the point of the item that sits at that point: [0,0] bottom-left, [0,1] top-left, [1,1] top-right, [0.5,0.5] centre. Sprite and Shape2D default to [0.5,0.5]; Text defaults to [0,1]. |
| 3D | Units are meters. Right-handed, +Y up. A perspective camera looks down its local -Z axis. |
| Angles | Degrees. In 2D only `rotation[2]` is used, counter-clockwise. In 3D, `rotation` is `[pitch X, yaw Y, roll Z]` and the matrix is `Ry(yaw) · Rx(pitch) · Rz(roll)`. |
| Colors | `[r, g, b, a]` with values 0..1, `"#rgb"`, `"#rrggbb"` or `"#rrggbbaa"`, or a name: white, black, red, green, blue, yellow, cyan, magenta, gray, grey, orange, purple, pink, brown, transparent. If any value in an array is above 1, the engine reads the array as 0..255 bytes, so keep to 0..1. |
| Rects | `{x, y, w, h}` or `[x, y, w, h]` (`physics.overlapBox`, `debug.rect`, `entity.bounds()`): `(x, y)` is the minimum corner, the BOTTOM-LEFT in the +Y-up world, and `w`, `h` the size. |
| Vectors | In scripts, a vector argument accepts `Vec2`/`Vec3` values, `{x, y}` or `[x, y]`. In JSON, use arrays (`[x, y]` or `[x, y, z]`); `{x, y}` objects also work in component fields. |
| Input | Gameplay reads actions (`input.pressed("jump")`) declared in `factoria.json` under `input.actions`. Bindings are key names (`"A"`, `"Space"`, `"Left"`, `"LeftShift"`, `"0"` to `"9"`, `"F1"`), `"MouseLeft"`, `"MouseRight"`, `"MouseMiddle"`, `"Touch"` (any finger down) or gamepad names, which match ANY connected pad: buttons `"GamepadA"`, `"GamepadB"`, `"GamepadX"`, `"GamepadY"`, `"GamepadStart"`, `"GamepadBack"`, `"GamepadGuide"`, `"GamepadDpadLeft"`/`Right`/`Up`/`Down`, `"GamepadLeftShoulder"`, `"GamepadRightShoulder"`, `"GamepadLeftThumb"`, `"GamepadRightThumb"` and the analog half axes `"GamepadLeftStickLeft"`/`Right`/`Up`/`Down`, `"GamepadRightStickLeft"`/`Right`/`Up`/`Down`, `"GamepadLeftTrigger"`, `"GamepadRightTrigger"`. Sticks and triggers are analog: `input.axis("move_left", "move_right")` gives -1..1 and `input.vector(...)` a short vector for a half-tilted stick, `input.value(action)` gives 0..1, and an action counts as down from 0.5. A radial deadzone (default 0.2, `"input": {"deadzone": 0.2}` in `factoria.json`) hides stick drift. For local multiplayer, `input.gamepad(1).down("A")` reads one pad. Tests drive pads with `game.gamepad(0).press("A")` and `.axis("LeftX", -1)`. On phones, the `TouchStick` and `TouchButton` widgets (UI table below) press these same gamepad bindings, so a pad game plays by touch unchanged. Unknown binding names are errors with a "did you mean". Real pads are read in windowed runs: Windows (XInput), Linux (joystick API), macOS/iOS (GameController) and Android and the web (the browser's Gamepad API). Face buttons are positional (`GamepadA` is the bottom button whatever the pad prints on it). On Linux a pad is translated through a mapping line found by its USB/Bluetooth ids: the engine embeds the Linux lines of the community SDL GameControllerDB (about 740 entries, including generic "USB Gamepad" devices, DualShock 4, DualSense, Switch Pro), and a pad listed nowhere gets the Xbox (xpad) layout. For a pad whose buttons come out wrong, add its line (copy it from SDL's GameControllerDB or SDL tools; the engine logs the pad's GUID) to a `gamecontrollerdb.txt` next to `factoria.json` (one line per pad, `#` comments), or have the player set the standard `SDL_GAMECONTROLLERCONFIG` environment variable; priority is that variable, then the file, then the built-in lines. Android drops a pad's slot when the pad is unplugged and tells Z/RZ sticks from Z/RZ triggers by the axes the device reports. No real pad has been tried on Linux or Android yet. `game.on("gamepadConnected" | "gamepadDisconnected", (pad) => ...)` gives `{ slot, id, name, type }`; `id` is the same for the same physical pad every time, and a pad that returns gets its old slot when that is free (`input.gamepad(i).id` and `.name` read them; pads plugged in before the first scene are not announced). Tests: `game.gamepad(1).connect({ id, name, type })`. |
| Ids | Give every gameplay entity a stable `id` (`"player"`, `"coin_3"`). Entity references use ids. |
| Paths | Project-relative with forward slashes (`assets/hero.png`). The file tools (`fs_*`) reject absolute paths and any `..` segment. To create a sprite or other binary file from text tools, call `fs_write` with `"encoding": "base64"` and the base64 of the PNG bytes as `content` (generate the PNG in a JS tool or script, or encode it yourself); the default `"utf8"` is text only. |
| Determinism | Random numbers come from `rng` (imported from "factoria"); a generator that must repeat from a seed uses its own `rng.create(seed)` (section 9.16). Time comes from the `dt` argument or `time.dt`. Never use `Math.random`, `Date.now` or wall-clock time. |
| Names | JSON keys are camelCase. Components are PascalCase (`RigidBody2D`). Enum values are lowercase (`"orthographic"`, `"additive"`). Commands are `area.verb_object`. |
| Secrets | Never put API keys in a project. They belong in `~/.factoria/ai.json` or in environment variables. |

## 6. Scene and prefab files

A scene is `factoria.scene/1`. Each entity has `id`, `name`, `tags`, `active`, `prefab`, `components` and `children`. Entity references use the string `id`.

```json
{
  "format": "factoria.scene/1",
  "settings": { "gravity2D": [0, -980] },
  "entities": [
    {
      "id": "camera",
      "name": "Main Camera",
      "components": {
        "Camera": { "projection": "orthographic", "clearColor": [0.35, 0.55, 0.85, 1], "primary": true }
      }
    },
    {
      "id": "player",
      "name": "Player",
      "tags": ["player"],
      "components": {
        "Transform": { "position": [-300, -250, 0] },
        "Shape2D": { "shape": "rectangle", "size": [32, 48], "color": [0.95, 0.35, 0.3, 1], "layer": 2 },
        "RigidBody2D": { "type": "dynamic", "fixedRotation": true },
        "Collider2D": { "shape": "box", "size": [32, 48], "friction": 0.2 },
        "Script": { "path": "scripts/player.js", "props": { "speed": 300, "jumpSpeed": 620 } }
      }
    }
  ]
}
```

`settings` holds the scene-wide values: `gravity2D`, `gravity3D`, `ambientLight`, `skyColor`, `horizonColor`, `fogColor`, `fogDensity`, `music`, `musicVolume`. A hand-written scene may leave out any of them (or all of `settings`) and gets the defaults. When the engine writes a scene (`scene_save`, `scene_import_ascii` with `path`, the editor) it saves only the settings that differ from their defaults, EXCEPT the gravity: `gravity2D` (default `[0, -980]`, pixels/s² in 2D) and `gravity3D` (default `[0, -9.81, 0]`, m/s² in 3D) are always written, so the file itself shows what pulls the bodies down, even at the default. A saved 2D level therefore starts like this, and a 2D game reads only `gravity2D`:

```json
{
  "format": "factoria.scene/1",
  "settings": {
    "gravity2D": [0.0, -980.0],
    "gravity3D": [0.0, -9.81, 0.0]
  },
  "entities": [
```

A prefab is `factoria.prefab/1` with one `entity`:

```json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Enemy",
    "tags": ["enemy"],
    "components": {
      "Shape2D": { "shape": "rectangle", "size": [40, 40], "color": [0.8, 0.2, 0.2, 1] },
      "RigidBody2D": { "type": "dynamic", "fixedRotation": true },
      "Collider2D": { "shape": "box", "size": [40, 40] },
      "Script": { "path": "scripts/enemy.js", "props": { "speed": 120 } }
    }
  }
}
```

A scene entity can start from a prefab and override it: `{"id": "enemy_1", "prefab": "prefabs/enemy.prefab.json", "components": {"Transform": {"position": [200, -100, 0]}}}`.

### Saving a prefab from the running game, and keeping files tidy

Do not format prefab JSON by hand. Build the thing in the running game (`scene_spawn`, `scene_set_component`, children with `parent`), look at it, then save it:

```
prefab_save {"id": "enemy_3", "path": "prefabs/enemy.prefab.json"}
```

Over the CLI, a plain `factoria call` starts a new game each time, so the entity must exist in the start scene; to save something you spawned first, use `factoria call --batch` or `factoria session` (section 11).

The file is a `factoria.prefab/1` document in the canonical layout (the one `scene_save` writes), with the entity's whole tree: its children and each component's non-default fields. A prefab describes the reusable thing, not the instance you built it from, so the file does NOT carry:

- **Ids.** Every instantiation gets fresh ones. An `id` stays only where another entity of the saved tree points at it through an entity-typed field, so that reference still resolves.
- **The root's `Transform.position`.** It is where this instance stands. The spawn call (`scene_spawn {"prefab":..., "position":[x,y]}`), the scene entity or the `scene.import_ascii` legend places each new instance. Children keep their positions relative to the root, and the root's rotation and scale are kept.
- **Tags that start with `tilemap:`.** `scene.import_ascii` adds them to the objects it places, and a prefab that carried one would be destroyed when that map is re-imported.
- **Entity references that leave the saved tree.** They would point at nothing in every instance.

The result is `{path, entity, children, overwritten, notes}`; `notes` lists what was left out when it matters (for example the root position that was dropped). `path` must end in `.prefab.json` and normally lives in `prefabs/`, where `project_info` and `project_validate` look. An existing file is an error until you pass `"overwrite": true`. To keep one entity exactly where it stands, save the whole scene with `scene_save`.

After you edit scene or prefab files by hand, run `scene_format` (CLI: `factoria call scene.format '{"paths":["scenes"]}'`). It rewrites the `*.scene.json` and `*.prefab.json` files you name in the canonical layout: 2-space indent, short arrays of numbers on one line (`"position": [0, 12.5, 0]`), long ones wrapped at about 100 columns, a Tilemap's `tiles` one map row per line. It does not load anything into the game and it only changes whitespace: values and key order stay as they are, and each file is read back and compared with the original data before it is written. `paths` (files or folders) says which; `"all": true` takes the whole project; with neither (and no `check`) the command writes nothing and fails, saying how many files it would change and the first ones, so a call never rewrites files you did not mean to touch. With `"check": true` nothing is written and the result lists the files that are not canonical in `notCanonical`, which is what a CI step or a review wants; add `"strict": true` and the command fails (error code `not_canonical`, the message lists the files) when any file is not canonical, so `factoria call scene.format '{"check":true,"strict":true}'` exits non-zero. `project_validate` also warns once per scene or prefab that is not canonical, with the command to run. A file with a JSON syntax error is reported in `errors` with its file, line and column and skipped; fix it and run the command again.

## 7. Component cheat-sheet

This is a summary. `factoria api --md` (also `docs_components`, and `docs/COMPONENTS.md`) has every field, its default and its range, generated from the engine, so it is always current.

**Core (every entity has these)**

| Component | Key fields | Typical use |
|---|---|---|
| `Transform` | `position` [x,y,z] (local to the parent), `rotation` [x,y,z] in degrees, `scale` | Where things are. |
| `EntityInfo` (not a component) | top-level `id`, `name`, `tags`, `active` | Identity. `active: false` disables an entity and its children. |

**2D**

| Component | Key fields | Typical use |
|---|---|---|
| `Camera` | `projection` (orthographic, perspective), `primary`, `clearColor`, `depth`, `clear`, `orthoSize` (0 = design height / 2), `fov`, `bloom` (bool, default off), `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` (default true), `colorFilter` (`none`, `greyscale`, `highContrast`, `protanopia`, `deuteranopia`, `tritanopia`) | The view. Without a primary camera the screenshot is black. `bloom: true` adds a glow around bright pixels; `bloomScreenSpace: false` keeps the screen-space HUD crisp (section 9.20). `colorFilter` is the players' accessibility filter (section 9.20.1). |
| `Sprite` | `texture` (asset path; empty = solid `color`), `size` (0 = image size), `pivot` (default [0.5, 0.5]), `color`, `flipX`, `flipY`, `layer`, `space`, `anchor`, `blend`, `region`, `pixelArt` | An image or a coloured quad. |
| `SpriteAnimator` | `columns`, `rows`, `firstFrame`, `lastFrame`, `fps`, `loop`, `playing` (needs a Sprite) | Frame-by-frame animation from a sprite sheet. |
| `Video` | `path`, `autoplay`, `loop`, `volume`, `bus`, `fit`, `tint` + the UiBox fields; runtime `playing`, `time`, `duration`, `ended` | An `.mpg` (MPEG-1 + MP2) drawn in a UI rectangle with its sound; time follows the game clock. Script: `entity.video.play()`, `.seek(s)`, `.on("ended", fn)`. Bring any video with `assets.import` (needs ffmpeg). [ASSETS.md](ASSETS.md) "Video", [MENUS.md](MENUS.md) studio intro. |
| `Shape2D` | `shape` (rectangle, circle, line, triangle, diamond, polygon, star), `size`, `color`, `filled`, `thickness`, `layer`, `space`, `anchor`, `pivot` (default [0.5, 0.5]), `blend`, `sides`, `points`, `innerRadius`, `lit` | Placeholder art and UI panels. No assets needed. For a circle, `size[0]` is the diameter. A `triangle` points up (apex at the top-middle of its `size` box); a `diamond` is a rhombus whose 4 points touch the middles of the box edges (gems, enemies, markers); a `polygon` is a regular polygon with `sides` sides (default 6) and a `star` has `points` tips (default 5) with notches at `innerRadius` (0..1, default 0.5) of the outer radius, both inscribed in the `size` box with the first vertex up. Outlines (`filled: false`) of triangle, diamond, polygon and star grow inward, like the rectangle's. `pivot` is the point of the `size` box that sits on the position and that the entity rotates around: to spin a triangle without it wobbling use `pivot: [0.5, 0.3333]` (its centroid). Circles and diamonds already spin in place at the default pivot. |
| `Text` | `text` (`\n` breaks lines), `fontSize` (default 24), `color`, `align`, `pivot` (default [0, 1]), `maxWidth`, `layer` (default 100), `space`, `anchor`, `font` | Labels, scores and the HUD (`space: "screen"`). Shaped text: Arabic and Hebrew read right to left, `maxWidth` also wraps Chinese, Japanese and Korean without spaces. DejaVu Sans is the default font and has no CJK: ship a Noto font (`docs_read {"name":"text"}`). |
| `Tilemap` | `tileset`, `tileSize`, `width`, `height`, `tiles` (row 0 is the top row, -1 = empty; flat list with `width`/`height`, or an array of rows), `solidTiles`, optional `columns` (0 = derived from the tileset image) | A level from a grid, written together with its coins and enemies by `scene.import_ascii` (section 9.8). Solid tiles get collision. |
| `ParticleEmitter` | `emitting`, `rate`, `burst`, `autoDestroy`, `maxParticles`, `lifetime`, `speed`, `direction` (0 = right, 90 = up), `spread`, `gravity`, `startSize`, `endSize`, `startColor`, `endColor`, `blend`, `texture`, `layer`, `space`, `anchor` | Sparks, dust and explosions (section 9.12). `"space": "screen"` (plus `anchor`) draws them in the HUD pass in design pixels (origin top-left); `direction` and `gravity` keep their meaning (90 = up, negative `gravity` y falls down the screen). Ignored for `is3D`. |

`layer` is the draw order: higher layers draw on top. `space: "screen"` items ignore the camera.

**3D**

| Component | Key fields | Typical use |
|---|---|---|
| `MeshRenderer` | `mesh` (cube, sphere, plane, cylinder, capsule, cone, quad, or a .glb/.gltf path), `color`, `texture`, `normalMap`, `normalScale`, `metallic`, `roughness`, `emissive`, `unlit`, `castShadows`, `receiveShadows`, `uvScale`, `materialColors` | Visible 3D objects with a PBR material. Primitives need no assets. Unless `unlit`, it needs a light to look right. glTF models bring their own material (section 9.9). |
| `Animator` | `clip`, `speed`, `loop`, `playing`, `fade`, `events`, and a state machine: `params`, `states`, `transitions` | Plays the clips of a skinned glTF on the entity with the MeshRenderer, blends between them, sends clip events, switches state from parameters. Script: `entity.animator.play("Run", 0.2)`, `.set("speed", 3)`. Section 9.25, [ANIMATION.md](ANIMATION.md). |
| `Light` | `type` (directional, point, spot), `color`, `intensity`, `range`, `spotAngle`, `castShadows` (directional only) | Lighting and shadows. A directional light points along the entity's -Z axis after its rotation. Up to 32 lights are used per frame (section 9.9). |

**Physics**

| Component | Key fields | Typical use |
|---|---|---|
| `RigidBody2D` | `type` (static, dynamic, kinematic), `velocity` [x,y], `angularVelocity` (degrees/s), `gravityScale`, `fixedRotation`, `bullet`, `linearDamping`, `angularDamping` | Moves an entity under 2D physics. A static body never moves. |
| `Collider2D` | `shape` (box, circle, capsule), `size`, `radius`, `offset`, `isTrigger`, `oneWay`, `friction`, `restitution`, `density`, `layer` (0..31), `mask` (-1 = all layers) | Collision shape. With `isTrigger: true` it reports overlaps and does not block. With `oneWay: true` it is a one-way platform (section 9.5). |
| `RigidBody3D` | `type`, `mass`, `velocity` [x,y,z], `angularVelocity` (degrees/s about x, y, z), `lockRotation`, `angularDamping`, `rollWithMotion`, `rollingFriction`, `gravityScale`, `linearDamping` | A simple 3D body. A dynamic **box** is a rigid body: collisions and friction turn it (it tips over a ledge, tumbles, settles on a face), so put `"lockRotation": true` on a character or a crate that must stay upright. A sphere is an arcade rolling ball by default (`rollWithMotion`, contacts never turn it); with `"rollWithMotion": false` it is a rigid body too and real friction rolls and spins it. Box colliders follow `Transform.rotation`. Fast bodies are swept against every solid collider, so they do not tunnel. |
| `Collider3D` | `shape` (box, sphere, capsule, convex, mesh), `size`, `radius`, `height`, `mesh`, `offset`, `isTrigger`, `friction`, `restitution`, `layer`, `mask` | 3D collision. Boxes are oriented: they follow the entity's world rotation (parents included). `size` and `offset` are scaled by `Transform.scale`, and `offset` is rotated with the entity. `capsule` is `radius` + `height` (tip to tip) along the entity's local Y. `convex` is the hull of `mesh`'s vertices; `mesh` uses its triangles and is for STATIC level geometry only (section 9.18). `mesh` is a primitive name (cube, sphere, plane, cylinder, capsule, cone, quad) or a .gltf/.glb path, usually the same as `MeshRenderer.mesh`. |
| `Joint3D` | `type` (hinge, ball, fixed), `connected` (entity id, empty = the world), `anchor`, `connectedAnchor`, `autoAnchor`, `axis`, `useLimits`, `lowerLimit`, `upperLimit` (degrees), `useMotor`, `motorSpeed` (degrees/s), `maxMotorTorque`, `collideConnected`, `damping`, `angle` and `stalled` (read-only) | Joins this entity's `RigidBody3D` to another body: doors, pendulums, wheels, ragdoll limbs, chains (section 9.18). Needs a `Collider3D` on the same entity. |
| `CharacterController3D` | `radius`, `height`, `center`, `stepOffset`, `slopeLimit` (degrees), `skin`, `layer`, `mask`, `velocity`, `carriedByPlatforms`, `applyWeight`, `mass`, `pushStrength`, `isGrounded` and `groundNormal` (read-only) | A walking capsule moved by `physics.moveCharacter` (section 9.18): slides along walls, climbs steps, refuses steep slopes, sticks to the ground going down, pushes crates. No `RigidBody3D` or `Collider3D` on the same entity. |

**UI (menus and settings screens; screen space only, section 9.22)**

| Component | Key fields | Typical use |
|---|---|---|
| `Panel` | `size`, `pivot`, `anchor`, `layer` (default 200), `color`, `texture` + `slice` (9-slice), `layout` (none, row, column, grid), `spacing`, `padding` [l,t,r,b], `columns`, `align`, `justify`, `fit` | A background that places its children in a column, row or grid. |
| `Button` | `text`, `size`, `autoFocus`, `interactable`, `font`, `fontSize`, `textColor`, `accentColor` + the style fields of Panel | Sends `ui.click`. |
| `Toggle` | `label`, `value` | Sends `ui.change` `{value: bool}`. |
| `Slider` | `label`, `value`, `min`, `max`, `step`, `showValue`, `format` (`"{percent}%"`) | Sends `ui.change` `{value: number}`; left / right change it by `step`. |
| `TextField` | `text`, `placeholder`, `maxLength` | Sends `ui.change` while typing and `ui.submit` on Enter. |
| `ScrollList` | `spacing`, `padding`, `scrollSpeed`, `scroll` | A column that scrolls with the wheel and clips its children. |
| `TouchStick` | `stick` (left, right), `knobColor`, `touchOnly` + the style fields of Panel (`safeArea` on by default); runtime `value`, `pressed`, `shown` | On-screen stick for phones: a finger moves that stick of a virtual pad, so actions bound to `GamepadLeftStick*` work by touch. Shown only while the player uses touch (`docs_read {"name":"mobile"}`). |
| `TouchButton` | `button` (`A`, `B`, `X`, `Y`, `Start`, `DpadUp`...), `text`, `font`, `fontSize`, `textColor`, `touchOnly` + the style fields of Panel; runtime `pressed`, `shown` | On-screen button for phones: holds that pad button, so actions bound to `GamepadA`... fire by touch. Test with `game.touchStart([x, y])` on it. |

**Audio and scripts**

| Component | Key fields | Typical use |
|---|---|---|
| `AudioSource` | `clip`, `volume` (0..1), `pitch`, `loop`, `playOnStart`, `spatial`, `range`, `playing` (runtime: set true to play) | A sound on an entity. Formats: .wav, .ogg, .mp3. |
| `AudioListener` | `volume` | The "ears" for spatial sound. Without one, the primary camera listens. |
| `Script` | `path` (module), `props` (values that override the class fields), `enabled` | Attaches a Behaviour to the entity. |

## 8. Scripts: behaviours and the JavaScript API

A behaviour is an ES module whose default export extends `Behaviour`. All methods are optional:

| Method | When it runs |
|---|---|
| `onStart()` | Once, the first time the entity is active, before its first update. `props` are already applied. |
| `onEnable()`, `onDisable()` | Every time the entity (or an ancestor) becomes active / inactive, before the frame is drawn. The first `onEnable` follows `onStart`. A panel refreshes its texts in `onEnable`. |
| `onUpdate(dt)` | Every frame. `dt` is in seconds, scaled by `time.scale`. While `time.scale` is 0 (`game.paused`) only behaviours with the class field `runWhilePaused = true` get it, with the real `dt` (pause menus). |
| `onFixedUpdate(dt)` | Every fixed step, before physics. Use it for movement that physics must see. |
| `onLateUpdate(dt)` | After all updates. Use it for cameras that follow targets. |
| `onDestroy()` | Before the entity is removed. |
| `onCollisionEnter(other, info)`, `onCollisionExit(other)` | Solid contacts. `info` is `{point, normal, impulse}`. |
| `onTriggerEnter(other)`, `onTriggerExit(other)` | Overlaps with trigger colliders. |
| `onEvent(name, data, source)` | Any `world.emit` event. |

Timing you can rely on:

- The behaviour object exists as soon as its entity does: right after `world.spawn`, `spawnPrefab`, a scene load or `game.load`. So `world.spawn(...).behaviour` and `game.find("id").behaviour` are usable at once. `onStart()` runs at the start of the next step. This holds for inactive entities too (`behaviour` of a panel spawned with `active: false` is its instance); their hooks run when they are first activated.
- Physics bodies are created by the first physics step. In the first `onFixedUpdate` after a spawn or a load, `physics.raycast` finds nothing and `isTouching` is false. Skip the first two fixed steps before you probe (section 9.14).
- `Script.props` keys that are not fields of the class are reported once (in the log and by `factoria validate`), with a "did you mean" hint. Declare every tunable as a class field.
- Hooks are called by their exact names (`onStart`, `onUpdate`, ...). A method named `start()`, `update()` or `onupdate()` (no arguments) is never called; it is reported once (in the log and by `factoria validate`) with a "did you mean".

Inside a behaviour: `this.entity` (the owning entity), `this.world`, `this.after(seconds, fn)` and `this.every(seconds, fn)` (timers that stop when the entity is destroyed; both return a handle with `.cancel()`), `this.on(name, fn)` (an event listener), and `this.enabled` (false skips the update callbacks).

Entity members: `id`, `name`, `tags`, `active`, `alive`, `transform`, `position`, `worldPosition`, `bounds()` (the world rectangle of its 2D visual, section 9.6), `get(name)` (a live view, or `null`), `add(name, fields)`, `set(name, fields)`, `has`, `remove`, `destroy()` (deferred to the end of the frame), `hasTag`, `addTag`, `removeTag`, `parent`, `children`, `setParent`, `behaviour`, `send(method, ...args)`, `isGrounded(tolerance?)` (2D pixels or 3D meters), `isTouching(direction, tolerance?)`, `emitBurst(count)` and `toJSON()`.

`entity.isTouching([1, 0])` is true when a solid body touches this entity on the right; `[-1, 0]` is left, `[0, -1]` is the ground below, `[0, 1]` the ceiling. Triggers never count.

The most-used members of the `"factoria"` module. The full list is in `docs_read {"name":"scripting"}`:

| Import | Members |
|---|---|
| `world` | `find(idOrName)`, `findAll(name)`, `findByTag(tag)`, `entities()`, `spawn(json, {position, rotation, scale, parent, index, props})`, `spawnPrefab(path, {position, rotation, scale, parent, index, props, overrides, childOverrides})`, `emit(name, data)`, `on(name, fn)` (returns an unsubscribe function) |
| `input` | `pressed(a)`, `down(a)`, `released(a)`, `axis(negative, positive)`, `vector(left, right, down, up)`, `keyDown("Space")`, `keyPressed`, `keyReleased`, `mouse` (`position`, `world`, `delta`, `wheel`, `down("left")`, `pressed("left")`), `touches` (`[{id, position, world, pressed}]`); options menus: `actions()`, `bindings(a)`, `rebind(a, [names])`, `resetBindings(a?)`, `lastPressed()` (what went down this frame, for "press a key"), `lastDevice`, `buttonName(bindingOrAction, pad?)` ("Cross" on a PlayStation pad), `gamepad(i).type`, `text` (typed this frame), `showKeyboard(on?)`, `onBack(fn)` (the Back button: return `false` to pass it on; unconsumed it quits), `vibrate(seconds?)`, `mouse.visible`, `mouse.locked` (details in `docs_read {"name":"scripting"}`) |
| `screen` | `safeArea` (a `Rect` in design pixels: what a phone's notch, rounded corners and system bars leave free; the whole screen on desktop and headless), `insets` (`{left, top, right, bottom}`), `size`. Put `safeArea: true` beside `anchor` on a Sprite, Shape2D, Text, ParticleEmitter or UI widget to anchor it to the safe area. Test with `game.setSafeArea("phone-portrait")` / `screen_set_safe_area` (`docs_read {"name":"mobile"}`) |
| `window` | `available`, `fullscreen` / `setFullscreen(on)`, `size` / `setSize(w, h)`, `displaySize`, `resolutions()`, `vsync` / `setVsync(on)`, `frameCap` (0 or 15..1000). Getters work everywhere; setters need a real window (not headless, not tests) and throw a teaching error otherwise, so check `window.available`. Phones and tablets are always full screen. Save the choice with `storage` |
| `audio` | `play(path, {volume, pitch, pan, loop, bus})` (bus defaults to `"sfx"`), `stop(id)`, `stopAll()`, `music(path, {volume, fade})`, `stopMusic(fade)`, `setVolume(bus, v)`, `getVolume(bus)` |
| `physics` | `raycast(from, to, {mask, ignore, ignoreTriggers})`, `raycast3d(origin, dir, maxDistance, {mask, ignore, ignoreTriggers})`, `shapeCast(shape, from, to, {mask, ignore, ignoreTriggers})`, `overlapCircle(center, r, {mask})`, `overlapBox(rect, {mask})`, `overlapSphere(center, r, {mask})`, `applyImpulse`, `applyForce`, `setVelocity`, `moveCharacter(entity, delta)` |
| `time`, `camera`, `debug` | `time.dt`, `time.fixedDt`, `time.elapsed`, `time.scale` (0 = paused: physics, particles, animators, timers and `onUpdate` stop; audio and the UI go on), `time.unscaledDt`; `camera.main`, `worldToScreen`, `screenToWorld`; `debug.line`, `debug.rect`, `debug.circle`, `debug.text`, `debug.box`, `debug.sphere` |
| `scene`, `game`, `storage` | `scene.load(path)` (deferred to the end of the frame), `scene.current`; `game.quit()`, `game.paused` (= `time.scale` 0), `game.project`, `game.screenSize`, `game.platform` (`"windows"`, `"android"`...), `game.notices()` (the runtime's third-party parts, for credits); `storage.get(key, fallback)`, `storage.set(key, value)`, `storage.remove(key)` |
| `session` | A plain object that survives scene loads for the whole run (section 9.15) |
| `rng`, `math` | `rng.seed(n)`, `rng.float()`, `rng.range(a, b)`, `rng.int(a, b)`, `rng.chance(p)`, `rng.pick(array)`, `rng.shuffle(array)` (all draw from the ONE world RNG); `rng.create(seed)` returns an independent seeded generator with the same methods, for generators and tools (section 9.16); `math.clamp`, `lerp`, `damp`, `moveTowards`, `degToRad` and others |
| `platform` | Store and platform services, every call a Promise: `platform.has("purchases")`, `achievements.unlock(id)`, `stats.add(id, n)`, `leaderboards.submit(id, score)`, `cloud.save(key, value)`, `purchases.buy(id)` / `finish(transactionId)` / `restore()`, `on("purchase" \| "overlay" \| "player", fn)`; ids are declared in `factoria.json` `"platform"`. In tests the fake store answers and `game.platform` (from `factoria:test`) controls it. Details: `docs_read {"name":"platform"}` |
| `particles`, `ui` | `particles.burst(entity, count)`; `ui.measureText(text, {fontSize, font, maxWidth, space})` returns `{width, height}`; `ui.layout()` runs the UI layout now (read `Button.size` / `ui.rectOf` right after changing a text); `ui.textScale` (0.5 to 3, not saved) is the player's text size option for screen-space Text and widget labels (`docs_read {"name":"text"}`); `ui.speak(text, {interrupt})` says a line with the system's text to speech in `i18n.language` (`ui.stopSpeaking()`, `ui.speechAvailable`; tests record the lines in `game.spoken()`; recipe and manual check in `docs_read {"name":"menus"}`) |
| `assets` | `assets.textureSize("assets/hero.png")` returns the texture file's pixel size `{width, height}` (32 x 32 for a missing file); works headless |
| `vec2`, `vec3`, `color` | constructors, for example `vec2(10, 0)`, `vec3([0, 4, 9])` or `color("#ffcc00")` |
| `ToolError` | `new ToolError(message, hint, data?)` for a failed check in a tool (section A of `docs_read {"name":"extending"}`) |
| `fa` | `fa.call(name, args)` runs any command; on error it throws an Error with `code`, `hint` and, for a tool's `ToolError(message, hint, data)`, `data`; `fa.commands()` lists them |

Options worth knowing:

- `world.spawn(json, {parent})` makes the new entity a child. `parent` is an Entity or an id string, and `position` is then local to the parent.
- `raycast` and `shapeCast` options: `mask` (layer bits), `ignore` (an Entity or id whose colliders are skipped, including its children), `ignoreTriggers` (default true). Colliders that already contain the ray origin (or overlap the cast shape at its start) are skipped too. The commands `physics.raycast` and `physics.shape_cast` take the same three options (`ignore` is an entity id or name there).
- `input.touches` entries: `id` (the finger), `position` (Vec2, design pixels, top-left origin), `world` (Vec3 in the world through the main camera) and `pressed` (true only on the first frame of contact). The first finger also drives the mouse (`input.mouse.position`, left button down while it is down), on a phone and in tests (`game.touch`) alike: read the mouse OR the touches for a tap, or make the second reading harmless.
- `world.find` no longer returns destroyed entities, and their id can be reused right away.

## 9. Recipes

Every snippet below parses and its scenes validate. The patrol, camera, pickup, one-way, tilemap, particle, HUD, rolling-ball, moving-platform and 3D probe recipes were also run in a test project.

### 9.1 Platformer character

This is the movement part of `templates/2d-platformer/scripts/player.js`, the starting point for any platformer:

```js
// @ts-check
import { Behaviour, input } from "factoria";

export default class Player extends Behaviour {
  speed = 300;     // overridden by Script.props in the scene
  jumpSpeed = 620;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
  }

  onUpdate(dt) {
    this.body.velocity.x = input.axis("move_left", "move_right") * this.speed;
    if (input.pressed("jump") && this.entity.isGrounded()) {
      this.body.velocity.y = this.jumpSpeed;
    }
  }
}
```

Gravity comes from `settings.gravity2D`. `fixedRotation: true` on the body keeps the character upright.

### 9.2 Top-down movement

```js
import { Behaviour, input } from "factoria";

export default class TopDown extends Behaviour {
  speed = 240;

  onUpdate(dt) {
    const dir = input.vector("move_left", "move_right", "move_down", "move_up"); // normalized, +Y up
    const p = this.entity.position; // live view: writes go straight to Transform
    p.x += dir.x * this.speed * dt;
    p.y += dir.y * this.speed * dt;
  }
}
```

If the entity must push or be pushed by walls, give it a `RigidBody2D` with `"type": "kinematic"` and set its `velocity` instead.

**Moving platform (2D).** A platform is a `RigidBody2D` with `"type": "kinematic"` (plus a `Collider2D`) whose script sets `velocity` each frame (a sine for a swing, a constant for a lift). A `dynamic` body resting on top of it is carried along, also when its own script sets `velocity.x` every frame (a platformer player that writes `velocity.x = 0` without input stays put on the platform). For a body that is carried, `RigidBody2D.velocity` is relative to the platform: it reads 0 while it stands still on it, and `velocity.x = 6` walks 6 units per second relative to the platform. A body that is not touching the platform from above (jumping, falling) is not carried. Moving the platform by writing its `Transform.position` is a teleport and carries nothing: set `velocity`. Verified: a player writing `velocity.x = 0` every frame stayed within 1 px of its place on a platform that swung 96 px in 100 frames. The player script needs no ray-cast or speed bookkeeping.

### 9.3 Spawning prefabs and entities

```js
import { Behaviour, world, rng, vec2 } from "factoria";

export default class Spawner extends Behaviour {
  interval = 1.5; // seconds

  onStart() {
    this.every(this.interval, () => {
      world.spawnPrefab("prefabs/enemy.prefab.json", { position: vec2(rng.range(-500, 500), 340) });
    });
  }
}
```

To spawn without a prefab, pass the entity object itself (the 2d-platformer template's `tools/spawn_coin.js` spawns its coin from `prefabs/coin.prefab.json` instead):

```js
// x and y are the coordinates you want (world pixels, +Y up).
const coin = world.spawn({
  name: "Coin",
  tags: ["coin"],
  components: {
    Transform: { position: [x, y, 0] },
    Shape2D: { shape: "circle", size: [24, 24], color: [1, 0.85, 0.2, 1], layer: 1 },
    RigidBody2D: { type: "static" },
    Collider2D: { shape: "circle", radius: 12, isTrigger: true },
  },
}, { parent: "level" });   // optional: parent is an Entity or an id; position is local to it
```

`props` in the spawn options is merged into the entity's `Script.props`. `destroy()` is deferred to the end of the frame, but the entity leaves physics at once (no collisions, no raycast or overlap hits), so you may destroy rigid bodies and spawn replacements at the same positions in the same frame. Destroy the entities you no longer need, so that spawners do not fill the scene.

### 9.4 HUD pinned to the screen corners

Screen-space items keep their place when the window changes shape. `anchor` picks the screen corner, `pivot` picks the corner of the item that sits there, and `position` is an offset in design pixels from that point (+Y is down, so `[-24, 24]` is 24 px in from the right and 24 px down):

| Corner | `anchor` | Text `pivot` | `position` for a 24 px margin |
|---|---|---|---|
| top-left | `[0, 0]` | `[0, 1]` | `[24, 24]` |
| top-right | `[1, 0]` | `[1, 1]` | `[-24, 24]` |
| bottom-left | `[0, 1]` | `[0, 0]` | `[24, -24]` |
| bottom-right | `[1, 1]` | `[1, 0]` | `[-24, -24]` |

```json
{
  "id": "lives",
  "name": "Lives",
  "components": {
    "Transform": { "position": [-24, 24, 0] },
    "Text": { "text": "Lives: 3", "fontSize": 28, "color": [1, 1, 1, 1], "pivot": [1, 1], "anchor": [1, 0], "space": "screen", "layer": 100 }
  }
}
```

A screen-space panel uses the same fields. A Shape2D rectangle is centred on its position by default, so set `pivot` to make a panel hang from a corner:

```json
{
  "id": "panel",
  "components": {
    "Transform": { "position": [16, -16, 0] },
    "Shape2D": { "shape": "rectangle", "size": [200, 60], "color": [0, 0, 0, 0.5], "layer": 90,
                 "space": "screen", "anchor": [0, 1], "pivot": [0, 0] }
  }
}
```

Text that changes at runtime is written from a behaviour, for example `this.entity.get("Text").text = "Coins: " + n;`. Check the screenshot: a clipped label usually means the wrong pivot.

### 9.5 Collisions, triggers and one-way platforms

```js
import { Behaviour } from "factoria";

export default class Pickup extends Behaviour {
  // The entity has Collider2D with "isTrigger": true.
  onTriggerEnter(other) {
    if (other.hasTag("player")) {
      this.world.emit("pickup", { by: other.id });
      this.entity.destroy(); // deferred to the end of the frame
    }
  }
}
```

- A trigger reports overlaps and never blocks. Two triggers never report each other, and a trigger only detects solid shapes.
- Tilemap tiles do not produce trigger events.
- `layer` (0..31) is the collision category of a collider. `mask` lists the layers it collides with, as a bit sum: layer 1 is 2, layer 3 is 8, so `mask: 10` means layers 1 and 3. `-1` means all layers.
- A **one-way platform** is a solid entity with `"oneWay": true` on its `Collider2D`. It blocks a body only when the body comes down onto it from above; the body can jump up through it from below and pass sideways. A verified test jumped from the floor under a one-way ledge and landed on top of it.

```json
{
  "id": "one_way",
  "name": "One-way ledge",
  "components": {
    "Transform": { "position": [100, -180, 0] },
    "Shape2D": { "shape": "rectangle", "size": [200, 16], "color": [0.9, 0.8, 0.3, 1] },
    "RigidBody2D": { "type": "static" },
    "Collider2D": { "shape": "box", "size": [200, 16], "oneWay": true }
  }
}
```

One-way applies to the entity's collider, not to Tilemap solid tiles. For a jump-through ledge in a tile level, put a separate one-way entity on top of the map. The platform should be unrotated; a platform flipped 180 degrees is one-way from below.

### 9.6 Camera follow with level bounds

The camera stays inside the level rectangle. Take that rectangle from the level's `Tilemap` with `entity.bounds()` instead of copying the map size into props, so the limits cannot drift from the map. The camera script gets the id of the Tilemap entity:

```js
// scripts/follow_camera.js
import { Behaviour, math } from "factoria";

export default class FollowCamera extends Behaviour {
  target = "player";
  bounds = "map";    // id of the level's Tilemap entity; "" = no limits
  smoothing = 8;     // higher is snappier

  clampPos(x, y) {
    const area = this.bounds ? this.world.find(this.bounds)?.bounds() : null; // { x, y, w, h } or null
    if (!area) return [x, y];
    const halfW = 640, halfH = 360; // half of the 1280x720 design size (orthoSize 0)
    // A level smaller than the view has an empty clamp range: centre on the level instead.
    const cx = area.w <= 2 * halfW ? area.x + area.w / 2 : math.clamp(x, area.x + halfW, area.x + area.w - halfW);
    const cy = area.h <= 2 * halfH ? area.y + area.h / 2 : math.clamp(y, area.y + halfH, area.y + area.h - halfH);
    return [cx, cy];
  }

  onLateUpdate(dt) { // after all updates, so the target has already moved
    const t = this.world.find(this.target);
    if (!t) return;
    const [tx, ty] = this.clampPos(t.position.x, t.position.y);
    const p = this.entity.position;
    p.x = math.damp(p.x, tx, this.smoothing, dt);
    p.y = math.damp(p.y, ty, this.smoothing, dt);
  }
}
```

In the scene the camera entity has `"Script": { "path": "scripts/follow_camera.js", "props": { "target": "player", "bounds": "map" } }`, where `map` is the id of the Tilemap (the entity `scene.import_ascii` writes, section 9.8).

`bounds()` returns `{ x, y, w, h }` in world units: `(x, y)` is the BOTTOM-LEFT corner (+Y up), `x + w` is the right edge and `y + h` the top edge, the same `Rect` that `physics.overlapBox` takes. For a Tilemap it is the map size (`width` x `height` tiles, or the rows) times `tileSize`, placed by the entity's transform; the entity position is the map's top-left corner. A map imported with `anchor: "bottom-left"` at `[0, 0]` gives `{ x: 0, y: 0, w: columns * tileSize, h: rows * tileSize }`. Resize or move the map and the camera limits follow. It also works for a `Sprite` (a background picture) or a `Shape2D` (an arena floor). It returns `null` for an entity without a world-space 2D visual (an empty map, a `space: "screen"` item); the script above then does not clamp. Calling it every frame is fine.

A level that is not a Tilemap keeps its rectangle in a JSON file that the script imports (section 9.16): `import levels from "../data/levels.json"` with `{ "bounds": { "minX": -640, "minY": -360, "maxX": 1000, "maxY": 720 } }`, and the same clamp with those numbers.

### 9.7 Sounds and music

```js
import { Behaviour, input, audio } from "factoria";

export default class Jumper extends Behaviour {
  onUpdate() {
    if (input.pressed("jump") && this.entity.isGrounded()) {
      audio.play("assets/sfx/jump.wav", { volume: 0.6 }); // bus defaults to "sfx"
    }
  }
}
```

Background music: set `"music": "assets/music/theme.ogg"` and `"musicVolume"` in the scene `settings`, or call `audio.music(path, {volume, fade})` from a script. Buses are `master`, `sfx`, `music` and `ui`.

A scene load stops every sound and the music, and then starts the new scene's `settings.music` (the same track again when both scenes name it). Music that should play across scenes (a menu theme into the first level) is started by a script with `audio.music(path, { persist: true })`: it survives scene loads, and a scene whose `settings.music` is the same track does not restart it.

Change a sound while it plays with `audio.setVoiceVolume(id, volume, fadeSeconds)` (`id` from `audio.play`; wind that swells, an engine hum). For music in layers (drums that come in when the fight starts) use `audio.musicLayers({ base: "assets/music/base.ogg", drums: "assets/music/drums.ogg" }, { levels: { drums: 0 } })` and then `audio.setLayer("drums", 1, 2)`: the layers start on the same sample and stay in step while they loop, as long as the clips have the same length.

Long sounds (over 10 seconds, so music) stream by themselves: a 3-minute track costs about 40 KB of decoded audio instead of 60 MB, so do not split music into pieces to save memory. To make every sound equally loud, put `"audio": {"normalize": true}` under `defaults` in `assets.json` (section 9.23).

`project_validate` checks the asset fields of the scene (for example `Sprite.texture`, `AudioSource.clip` and `Script.path`), but not paths written in code. A missing file passed to `audio.play` shows up in `game_logs`.

To check that a sound really fires, read the play log: in a test, `expect(game.audioLog()).toContainPlayed("jump.wav")` (section 10); from MCP or the CLI, `audio_log` after `game_step`. A play whose clip failed to load is in the log with `ok: false` and does not count as played.

### 9.8 Tilemap levels, objects and tile collision

Author a tile level as ASCII art with the command `scene.import_ascii` (MCP `scene_import_ascii`). It writes the `Tilemap` and spawns the coins, enemies and spawn points that stand on it, at the right place. Do not compute tile positions by hand and do not write a level generator script.

```
factoria call scene.import_ascii @level1.json          # args in a file; or MCP scene_import_ascii {...}
```

```json
{
  "rows": [
    "..........",
    "...o..o...",
    "..........",
    ".P......o.",
    "##########",
    "%%%%%%%%%%"
  ],
  "legend": {
    "#": 0,
    "%": 1,
    "o": { "prefab": "prefabs/coin.prefab.json" },
    "P": { "prefab": "prefabs/player.prefab.json", "id": "player" }
  },
  "tilemap": { "tileset": "assets/tiles.png", "tileSize": [32, 32], "solidTiles": [0, 1] },
  "anchor": "bottom-left",
  "position": [0, 0],
  "path": "scenes/level1.scene.json"
}
```

- `rows` is the map: one string per row, ONE CHARACTER PER TILE, all rows the same length, row 0 is the TOP row. `.` and a space are empty tiles unless the legend defines them.
- `legend` maps each character to a tile index (an integer, `-1` = empty) or to an object `{"tile"?, "flipX"?, "flipY"?, "rotate"?, "prefab"?, "id"?, "overrides"?, "offset"?}`. A glyph with a `tile` draws that tile (`flipX`, `flipY` and `rotate` 0/90/180/270 clockwise turn it, section 9.26). A glyph with a `prefab` spawns that prefab at the CENTRE of its cell (a glyph may have both). `overrides` patches the prefab's components for that glyph (`{"Script": {"props": {"speed": 60}}}`), and `offset` `[dx, dy]` shifts the object from the cell centre in world units (a 96 px flag that must stand on the ground, for instance).
- `legendFrom` (optional) is a project-relative JSON file with a legend shared by several maps, e.g. `"legendFrom": "levels/legend.json"` holding `{"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}}` (or `{"legend": {...}}`). It is merged UNDER the map's own `legend`: the map wins for a glyph both define, and `legend` may be left out. Entries that only the shared file defines are never reported as unused; the map's own unused entries still are.
- `tilemap` holds the Tilemap fields for a new tilemap (`tileset`, `tileSize`, `columns`, `solidTiles`, `color`, `layer`). You do not need `columns`: left at 0 (the default) it is derived from the tileset image, as many whole tiles of `tileSize[0]` as fit across it. Pass it only for an image with another layout. If an earlier import set `columns` explicitly and you now change `tileset` or `tileSize` without `columns`, it goes back to 0 (the result says so in `notes`). The grid (`tiles`, `width`, `height`) always comes from `rows`.
- `entity` (default `"tilemap"`) is the id of the Tilemap entity: created when missing, updated when it exists. Use another id for a second layer, such as a background.
- `position` and `anchor` (`top-left`, `bottom-left` or `center`) place the map: `anchor` says which point of the map sits at `position`. With `bottom-left` at `[0, 0]` the level's floor starts at y = 0. Without them a new tilemap has its top-left corner at the origin, and an existing one stays where it is.
- Objects are ordinary top-level entities, saved with the scene. Give unique objects an `id` in the legend (`"id": "player"`). Other objects get ids from the prefab file name in row-major order: `coin_1`, `coin_2`, `crawler_1`. Every object carries the tag `tilemap:<entity>` (for example `tilemap:tilemap`).
- Re-import after editing the map: with `replace` (default `true`) the objects of earlier imports into the same tilemap are destroyed first, so nothing is duplicated and the ids stay stable. `replace: false` keeps them.
- `path` is the scene FILE to build (see "Edit a scene file, not the running game" below). It is the normal way to use the command.
- `save: true` (only without `path`) also writes the current scene file, so one call is enough. It is refused when the running scene is just the project's `mainScene` that was loaded because nobody chose a scene (see below).
- The result lists the `spawned` objects (`id`, `prefab`, `cell: [col, row]`, `position`), the `removed` ids, the number of non-empty tiles (`tileCount`) and `warnings` (a legend glyph that is never used, no tileset, no `solidTiles`).
- Errors name the row and column, the glyph and the legend, with a "did you mean": ragged rows, an unknown glyph, a legend value that is not an integer or an object, a missing prefab, a duplicate fixed `id`, a tile index outside the tileset. A failed import changes nothing.

Run `project_validate`, then take a screenshot to check the picture: the tiles, the coins and the player must line up.

**Edit a scene file, not the running game (`path`, `from`, `dryRun`).** Without `path` the command changes the RUNNING world, like `scene.spawn`. That is the right tool in the editor or in a play-test, but a poor one for building level files: `scene.load` and `scene.save` act on the running world too, and loading a scene stops the audio and resets the physics. Give the command a `path` and it works on the file instead:

```
factoria call scene.import_ascii @levels/level1.json       # level1.json carries "path": "scenes/level1.scene.json"
```

- `path` (project-relative, e.g. `scenes/level1.scene.json`) is the scene file to edit. The file is loaded into a scratch world that the engine throws away, the map is imported into it, and the result is written back to `path` in the same layout as `scene_save` (compact `tiles` rows, the gravity always in `settings`, stable key order, so a diff shows what changed). The running world, its scene, the audio, the physics and the scripts are not touched, and nothing is reloaded, so it is safe to call from a project tool, from a script or while a game is running. If the running scene is that file and hot reload is on (windowed play), the game reloads it from disk like after any other edit of the file.
- `from` (needs `path`) is a scene file to START from instead of `path`. A generator uses it to build `path` from a base scene that has the settings, camera, HUD and level script but no map (`"from": "levels/base.scene.json"`); `path` is then replaced. `from` must exist (the error suggests close scene names).
- A `path` that does not exist yet and no `from`: the scene starts empty (default settings, no camera) and is created. That makes a new level one call; the result says so in `notes`. If `path` looks like a typo of an existing scene (`scenes/mian.scene.json`), `warnings` says "Did you mean 'scenes/main.scene.json'?" after creating it. Pass `from` to build on an existing scene.
- `dryRun: true` (needs `path`) writes nothing and returns the resulting scene in `scene`, for a preview or a test. The same call without `dryRun` writes exactly that scene.
- `edits` (needs `path`) patches components of the scene's entities after the map is imported and before the file is written: `{"<entity id>": {"<Component>": {field: value}}}`. Each entry is exactly `scene_set_component` (a component the entity lacks is added, only the given fields change, a value outside a field's range is refused, `Script.props` is replaced as a whole, so pass all the props, unless the entry has `"$merge": true`: then `props` is merged into the current props as an RFC 7386 JSON merge-patch, keys you do not mention stay and `null` deletes one). It is how a generator tunes the base scene it starts from (`"edits": {"camera": {"Camera": {"clearColor": [0.5, 0.7, 0.95, 1]}}, "level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}`: the level number changes, the base scene's other props such as `killY` stay, and the generator never reads the base scene) without writing a patched copy of the base scene first. It also reaches the entities the import placed. A wrong entity, component or field fails the call, names `edits["<id>"]["<Component>"]` with suggestions, and nothing is written. Without `path` use `scene_set_component` on the running world; `edits` is refused there.
- **What the file contains.** The written scene keeps PREFAB REFERENCES instead of expanding prefabs: each legend object is `{"id": "coin_1", "prefab": "prefabs/coin.prefab.json", "tags": ["coin", "tilemap:tilemap"], "components": {"Transform": {"position": [...]}, ...the glyph's overrides}}`, and the prefab entities of the `from` scene stay exactly as written there. Editing a prefab file then changes every level the next time it loads, with no import in between, and level files stay small. A scene loaded into the world still expands them (only the file is shorter). An entity that `edits` touches, and a base-scene prefab entry without an `id`, are written expanded, because a reference cannot express the edit. `scene_format` and `project_validate` treat the new files like any other scene.
- The result has the usual keys plus `path`, `from` (the file it started from, `null` for an empty scene), `entityCount`, `dryRun` and `saved` (the file written, absent in a dry run).
- Everything else behaves as in the running world: `replace` removes the objects of the earlier import from the scene, ids are checked against every entity of the file (a fixed `id` that the file already uses is an error), the tileset is read for the range check. A failed import writes nothing, and a start file that has load errors (an unknown component, a bad value) is refused instead of being rewritten with those entries silently dropped. `save` is ignored when `path` is given.
- `path` is written like any file written by a command: not into `.factoria/` except `.factoria/tmp/` (see "Scratch files" below), and not outside the project.

**The safe workflow for a level.** Keep the map in a JSON file (`levels/level1.json`) with `"path": "scenes/level1.scene.json"` and rebuild it with `factoria call scene.import_ascii @levels/level1.json` from the project folder. No `--scene`, no `scene_load`, no `scene_save`. Without `path` the same file with `"save": true` would, on a `factoria call` without `--scene`, rewrite the project's main scene with the wrong map. The engine therefore refuses `save` without `path` while the running scene is only the default `mainScene` (nobody passed `--scene` or called `scene.load`, and it is not the editor): the error `unsafe_save` names the file it would have overwritten and says to add `path`, or to choose the scene first on purpose (`--scene scenes/main.scene.json`). When `save` is allowed, the result's `notes` say `SAVED '<file>'` and that it is the running scene.

**Scratch files (`.factoria/tmp/`).** `.factoria/` holds what the engine and its tools produce (screenshots, save games, AI transcripts, editor state); `scene_save`, `scene_import_ascii` with `path`, `fs_write`, `fs_edit` and `fs_delete` refuse to write or delete there, with one exception that all of them share: `.factoria/tmp/` is a scratch folder where files can be created, overwritten and deleted (for example a test's output). `fs_list` and `fs_search` hide `.factoria/` but show a `path` inside `.factoria/tmp`. It is not committed.

The map's world rectangle is `world.find("map").bounds()` (`{ x, y, w, h }`, bottom-left corner and size): use it for camera limits, kill planes and spawn areas instead of repeating `columns * tileSize` in props (section 9.6).

What the command writes is a plain `Tilemap` component. A `Tilemap` draws a grid from a tileset image. Row 0 is the TOP row, and `-1` is an empty tile. The entity's position is the top-left corner of the map, with +Y up. Tile (col, row) covers x from `px + col*tw` to `px + (col+1)*tw` and y from `py - (row+1)*th` to `py - row*th`, so its centre is `(px + (col+0.5)*tw, py - (row+0.5)*th)`.

```json
{
  "id": "level",
  "name": "Level",
  "components": {
    "Transform": { "position": [-640, 360, 0] },
    "Tilemap": {
      "tileset": "assets/tiles.png",
      "tileSize": [32, 32],
      "width": 6,
      "height": 3,
      "tiles": [
        -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1,
         0,  1,  1,  1,  0,  2
      ],
      "solidTiles": [0, 1, 2]
    }
  }
}
```

The flat `tiles` array has `width * height` entries. `tiles` may also be an array of rows (`[[-1, 0, 1], [2, 2, 2]]`); then the rows define the size and `width`/`height` are not needed. In both forms the renderer and the 2D collision read the same grid, so what is drawn is exactly what collides. A flat list without `width` is read as ONE row (validation warns). When the engine saves a scene or prefab (`scene_save`, `save: true`, the editor), it writes a flat `tiles` one map row per line with aligned columns, as in the example above, so the file shows the map and a diff shows which row changed. The same writer puts short arrays (`position`, `color`, `tags`, `solidTiles`) on one line and wraps long number lists at about 100 columns. This is plain JSON, so you can keep that layout when you edit a scene by hand, but nothing depends on it; run `scene_format` (section 6) after a hand edit and it puts the map rows and the arrays back in that layout. The tileset image holds tiles of `tileSize`, laid out left to right and top to bottom. `columns` (tiles per image row) is optional: leave it out and it is derived from the image width divided by `tileSize[0]`, so tile 3 of a 4-tile-wide image is the 4th tile of the first row. Set it only for a layout that does not follow the image width. Validation reports a missing tileset, a `tiles` list that does not match `width * height` (or rows of different lengths, or strings instead of integers), and tile indices outside the tileset image.

How tiles collide (verified against the physics rules):

- Every tile index in `solidTiles` becomes part of one static body per Tilemap. Horizontal runs in a row are merged, and identical runs in consecutive rows are merged too.
- Tile shapes are on layer 0, with friction 0.5 and no bounce. They are not triggers, so tiles raise no trigger events, and they are not one-way.
- Tile indices that are not in `solidTiles` are drawn but never block.
- Merging can leave seams between boxes of different heights. A character with friction can catch on a seam when it slides along a wall. Give characters `friction: 0` against walls, or use a circle or capsule foot.
- Tiles cannot carry behaviour. Coins, enemies and spawn points are entities spawned by `scene.import_ascii` from the legend (above).

**Editing a map without rewriting rows.** When the level lives in an args file (`levels/1-1.json`), change it with `scene.ascii_edit` (MCP `scene_ascii_edit`) instead of counting characters in a 300-column row. `ops` run in order, all-or-nothing (an error names the op, `ops[2]`, and writes nothing); columns and rows count from 0, row 0 = top:

```
factoria call scene.ascii_edit '{"file":"levels/1-1.json","ops":[
  {"op":"put","col":40,"glyph":"o","above":1},
  {"op":"fill","rect":[10,20,4,1],"glyph":"#"},
  {"op":"replace","from":"o","to":".","rect":[100,0,30,23]},
  {"op":"insertColumns","at":60,"count":5},
  {"op":"deleteColumns","at":200,"count":3}]}'
```

`put` takes `row` (absolute) or `above` (cells above the ground of that column, 1 = standing on it; ground = the topmost tile listed in the file's `tilemap.solidTiles`, else the Tilemap of the scene the file builds). `insertColumns` without `glyph` repeats the column left of `at` with every object glyph turned into `.`. The file keeps its other keys and order, with one row per line. When the file has a `path` the level is rebuilt like `scene.import_ascii @file` (`rebuild: false` skips it) and the result lists every object with its glyph and `cell`; `dryRun` writes nothing and returns the edited `rows`.

### 9.9 3D scene with a light and fog

A camera, a sun and a floor (the `3d-empty` template has only the camera; add the rest):

```json
{
  "format": "factoria.scene/1",
  "settings": { "ambientLight": [0.3, 0.32, 0.38, 1], "skyColor": [0.45, 0.62, 0.85, 1] },
  "entities": [
    { "id": "camera", "components": {
        "Transform": { "position": [0, 3, 8], "rotation": [-15, 0, 0] },
        "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": {
        "Transform": { "position": [0, 10, 0], "rotation": [-50, -30, 0] },
        "Light": { "type": "directional", "intensity": 1.1, "castShadows": true } } },
    { "id": "floor", "components": {
        "Transform": { "position": [0, 0, 0], "scale": [20, 1, 20] },
        "MeshRenderer": { "mesh": "plane", "color": [0.35, 0.5, 0.35, 1] } } },
    { "id": "cube", "tags": ["spinner"], "components": {
        "Transform": { "position": [0, 1, 0] },
        "MeshRenderer": { "mesh": "cube", "color": [0.9, 0.45, 0.2, 1], "metallic": 0.1, "roughness": 0.5 } } }
  ]
}
```

- Shadows: a directional `Light` with `"castShadows": true` casts them. `MeshRenderer.castShadows` and `receiveShadows` (both default true) control each object.
- Fog: `settings.fogDensity` (0 = off) and `settings.fogColor` blend distant objects into the fog colour. `skyColor` and `horizonColor` paint the sky gradient behind a perspective camera.
- Lighting: `ambientLight` lights every surface evenly. Add point or spot lights with `type: "point"` or `"spot"` (no shadows yet).

Production 3D rendering (all automatic; there is nothing to switch on):

- **PBR materials.** `metallic` and `roughness` drive Cook-Torrance (GGX) lighting. Metal reflects the sky: the engine builds a small environment from `settings.skyColor` and `settings.horizonColor` (rougher surfaces see a blurrier sky), so a shiny sphere looks right with no environment asset. `ambientLight` still lights the diffuse side. Lighting happens in gamma space (colours are not linearised), as in older scenes. A scene with a cleared sky and a bright `skyColor` therefore gives plastic a faint sheen and metals a bright rim: lower `skyColor`/`horizonColor` for a dark scene.
- **Normal maps.** `MeshRenderer.normalMap` (a tangent-space map, glTF convention: +Y up, the usual blue-ish image) adds relief without triangles; `normalScale` (default 1) scales it, `uvScale` tiles it with the base texture. Primitives get their tangents from their UVs.
- **glTF materials.** A model's own `baseColorFactor`/texture, `metallicFactor`/`roughnessFactor`, `metallicRoughnessTexture`, `normalTexture`, `occlusionTexture`, `emissiveFactor`/`emissiveTexture` (and `KHR_materials_emissive_strength`) are all used. A glTF material's metallic and roughness replace `MeshRenderer.metallic`/`roughness` (those apply to primitives and to models without a material); `color` still tints the base color (of every material), `materialColors` (`{"Body": [0.2, 0.8, 0.7, 1]}`, keyed by the glTF material name) replaces the base color factor of ONE material so the others keep theirs (a typo in the name is a `factoria validate` error with a "did you mean"; built-in shapes ignore it), `emissive` adds to the glTF emission, and `normalMap` replaces the glTF normal map when set. Models without a TANGENT attribute get tangents generated from their UVs.
- **Many objects.** Meshes outside the camera frustum are not drawn. Meshes with the same `mesh`, textures and material values (`color`, `metallic`, `roughness`, `emissive`, `unlit`, `receiveShadows`, `uvScale`, `normalMap`, `normalScale`, `material`, `materialParams`, `materialColors`) are drawn with ONE instanced draw call per mesh part, however many there are: 10 000 identical cubes cost one draw. Give each its own `color` and they stop sharing, so for crowds vary the Transform, not the material. `play.report` shows `meshes` (drawn), `meshesCulled`, `meshBatches` (groups drawn with one instanced draw), `drawCalls`, `materials` (custom materials drawn) and `materialFallbacks` (materials that failed to build and are drawn magenta; the error log, `game.logs`, says why). In a test, `game.screenshot(path)` draws a frame and `game.state().renderStats` then has the same numbers ([SHADERS.md](SHADERS.md)). Objects off screen still cast shadows into view while a shadow-casting light is on.
- **Lights.** Up to 32 lights are used each frame. When a scene has more, the shadow-casting sun comes first, then the other directional lights, then point and spot lights by brightness over distance to the camera (the nearest and brightest are kept); `lightsDropped` in the stats says how many were left out. A light costs every lit pixel, so keep the lights that reach the camera few and give them a small `range`.
- Custom shaders (full guide with five worked examples: `docs_read {"name":"shaders"}`, [SHADERS.md](SHADERS.md)): `MeshRenderer.material` names a `*.material.json` whose GLSL snippet changes the surface (and optionally moves vertices); `material_info` lists its params, `shader_compile` checks it, `materialParams` overrides params per entity. A material that does not compile draws magenta.
- Not available yet: an environment map image for reflections, shadows from point and spot lights.

### 9.10 Save data

```js
import { Behaviour, storage } from "factoria";

export default class Scoreboard extends Behaviour {
  onStart() {
    this.best = storage.get("bestScore", 0); // fallback when nothing is saved yet
  }

  finish(score) {
    if (score > this.best) {
      this.best = score;
      storage.set("bestScore", score); // JSON-serializable values only
    }
  }
}
```

Save data is per user, across runs. Tests never touch it (section 10).

### 9.11 Changing levels

```js
import { Behaviour, scene } from "factoria";

export default class Goal extends Behaviour {
  onTriggerEnter(other) {
    if (other.hasTag("player")) scene.load("scenes/level2.scene.json"); // applied at the end of the frame
  }
}
```

A scene change drops every behaviour, timer and `world.on` listener of the old scene. Anything that must survive the change goes in `session` (section 9.15) or in `storage`.

### 9.12 One-shot particle effects

A burst of sparks, a pickup pop or an explosion is a prefab with an emitter that does not emit continuously. The burst fires when the entity is created, even with `emitting: false`. `autoDestroy` removes the entity after the last particle dies. `"blend": "additive"` makes overlapping particles glow.

```json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Pop",
    "components": {
      "ParticleEmitter": {
        "emitting": false, "rate": 0, "burst": 24, "lifetime": 0.5,
        "speed": 260, "spread": 180, "direction": 90,
        "startSize": 10, "endSize": 0,
        "startColor": [1, 0.9, 0.3, 1], "endColor": [1, 0.4, 0.1, 0],
        "gravity": [0, -300, 0], "blend": "additive", "autoDestroy": true, "layer": 50
      }
    }
  }
}
```

```js
// Inside the pickup behaviour, when the player touches the coin:
world.spawnPrefab("prefabs/pop.prefab.json", { position: this.entity.position.clone() });
this.entity.destroy();
```

To burst an emitter that already exists, call `particles.burst(entity, 24)` or `entity.emitBurst(24)`; both work with `emitting: false`. Without graphics (`--no-graphics`) they do nothing and log a warning. A continuous effect (fire, dust) keeps `emitting: true` and a `rate`. For HUD effects (a score pop, menu sparks) set `"space": "screen"` (and an `anchor`): the emitter is positioned in design pixels from the top-left, ignores the camera and is drawn in the HUD pass, so `Camera.bloomScreenSpace: false` keeps it crisp; `direction` and `gravity` mean the same as in the world (90 = up, negative `gravity` y falls).

### 9.13 Coin pickup from the player

The coin reacts to the player's overlap through a trigger. The player tells the coin to collect itself:

```js
// scripts/player.js (the player's onTriggerEnter)
onTriggerEnter(other) {
  if (other.hasTag("coin")) other.send("collect");
}
```

```js
// scripts/coin.js
import { Behaviour, session, world } from "factoria";

export default class Coin extends Behaviour {
  collect() {
    session.coins = (session.coins ?? 0) + 1;
    world.spawnPrefab("prefabs/pop.prefab.json", { position: this.entity.position.clone() });
    this.entity.destroy();
  }
}
```

The coin entity has `Collider2D` with `isTrigger: true`. `entity.send(method, ...args)` calls a method on another entity's behaviour, and does nothing if there is none.

### 9.14 Patrol AI: turn at walls and ledges

An enemy walks in `dir` and turns when a wall is in front of it (`isTouching`) or when nothing is under the next step (a short downward ray, `physics.raycast` with `ignore: this.entity` so it does not hit itself). The first two fixed steps are skipped, because bodies are created by the first physics step.

```js
// scripts/patrol.js
import { Behaviour, physics, vec2 } from "factoria";

export default class Patrol extends Behaviour {
  speed = 90;
  dir = -1;      // -1 = left, 1 = right
  halfW = 20;    // half the width of the body
  halfH = 20;    // half the height of the body
  ticks = 0;

  onFixedUpdate() {
    const body = this.entity.get("RigidBody2D");
    if (!body) return;
    if (this.ticks < 2) {          // bodies do not exist before the first physics step
      this.ticks += 1;
      body.velocity.x = this.dir * this.speed;
      return;
    }
    if (this.entity.isTouching([this.dir, 0])) this.dir = -this.dir;   // wall in front
    const p = this.entity.position;
    // Ledge probe: a short ray down from just ahead of the feet. No hit means nothing to stand on.
    const ahead = vec2(p.x + this.dir * (this.halfW + 4), p.y - this.halfH + 2);
    const ground = physics.raycast(ahead, vec2(ahead.x, ahead.y - 8), { ignore: this.entity });
    if (!ground) this.dir = -this.dir;
    body.velocity.x = this.dir * this.speed;
  }
}
```

Scene entity: `"RigidBody2D": {"type": "dynamic", "fixedRotation": true}`, `"Collider2D": {"shape": "box", "size": [40, 40], "friction": 0}`, and `"Script": {"path": "scripts/patrol.js", "props": {"speed": 90, "dir": -1}}`. Verified: an enemy walking left stopped and turned at a wall, and an enemy on a 160 px shelf turned at both edges.

### 9.15 Cross-scene state with `session`

`session` is a plain object that lives for the whole run. Use it for values that must survive a `scene.load`: score, coins, lives, the current level. It is not saved to disk (use `storage` for that).

```js
import { Behaviour, session } from "factoria";

export default class Hud extends Behaviour {
  onUpdate() {
    this.entity.get("Text").text = `Coins: ${session.coins ?? 0}`;
  }
}
```

Verified: `session.coins = 7`, then `scene.load` of another scene, still reads 7. Module-level variables survive a scene load too, but behaviours, timers and `world.on` listeners do not. Tests reset `session` for every test file.

### 9.16 Level data in JSON imports

Keep level layouts, tuning tables and text in `data/*.json` and import them from scripts or tests. Relative paths resolve from the importing file, so `scripts/x.js` imports `../data/levels.json`, and a test in `tests/` imports the same file with `../data/levels.json`:

```js
import levels from "../data/levels.json";   // the parsed file, as the default export
const { minX, maxX } = levels.bounds;
```

Hot reload covers JSON too. A syntax error is reported against the `.json` file, with its line and column (`data/levels.json:3:14: invalid JSON: ...`); `project_validate` lists it once as an error of that file, however many scripts import it, and does not add `Script.props` warnings for the scripts that could not load because of it. For levels that must be generated from parameters, write a project tool. For a tile level it composes ASCII `rows` and calls `scene.import_ascii` with `path` and `from` (section 9.8), which writes the scene file without touching the running game; for anything else it builds the scene and writes it with `fs.write` (see `docs_read {"name":"extending"}`, A.1). A generator that must give the same level for the same seed draws its random numbers from `rng.create(seed)`, not from `rng` and not from `rng.seed(seed)`: `rng.seed` reseeds the single world RNG the running game draws from (and a script cannot restore its state), while `rng.create` is an independent generator that never touches it:

```js
import { rng } from "factoria";

const r = rng.create(seed);   // mulberry32: the same seed gives the same sequence on every platform and engine version
const width = r.int(30, 60);  // inclusive; also r.float(), r.range(a, b), r.chance(p), r.pick(list), r.shuffle(list)
```

### 9.17 3D chase camera

The camera sits at the target plus an offset and follows it smoothly. Its rotation stays fixed, because there is no look-at: set `rotation` yourself. To face a direction `(dx, dz)` on the ground, use yaw `atan2(-dx, -dz)` in degrees.

```js
import { Behaviour, math, vec3 } from "factoria";

export default class ChaseCamera extends Behaviour {
  target = "ball";
  offset = [0, 4, 9];   // meters from the target; +Z is behind a camera that looks down -Z
  smoothing = 6;

  onLateUpdate(dt) {
    const t = this.world.find(this.target);
    if (!t) return;
    const want = t.worldPosition.add(vec3(this.offset));
    const p = this.entity.position;
    p.x = math.damp(p.x, want.x, this.smoothing, dt);
    p.y = math.damp(p.y, want.y, this.smoothing, dt);
    p.z = math.damp(p.z, want.z, this.smoothing, dt);
  }
}
```

Scene: the camera entity has `"Transform": {"position": [0, 4, 9], "rotation": [-20, 0, 0]}` (looking slightly down), `"Camera": {"projection": "perspective", "primary": true}`, and `"Script": {"path": "scripts/chase_camera.js", "props": {"target": "ball"}}`.

### 9.18 3D rolling ball and moving platforms

A sphere collider with `RigidBody3D` spins to match its rolling while it touches the ground: `rollWithMotion` (default true) derives the spin from its horizontal speed. Verified: a ball moved 5.96 m along X and its rotation turned by about -676 degrees about Z.

A rolling sphere is slowed by rolling resistance, not by sliding friction: `RigidBody3D.rollingFriction` (default 0.02) caps the friction impulse at `rollingFriction` times the normal impulse, so on flat ground its speed falls by about `rollingFriction * 9.81` m/s every second. A ball launched at 3 m/s rolls about 23 m before it stops, whatever `Collider3D.friction` says. With `"rollWithMotion": false` the sphere is a real rigid body instead (below). So a rolling ball you steer by setting `velocity` every frame keeps the speed you give it; raise `rollingFriction` (for example 0.3) for a heavy, grippy ball, or write the velocity toward zero yourself.

**Real rolling.** With `"rollWithMotion": false` a dynamic sphere is a rigid body like a box: friction at its contact point spins it (solid sphere, inertia 2/5 m r^2), so it rolls down a slope without slipping (a 30 degree slope gives 5/7 g sin = 3.5 m/s^2 and a spin of speed / radius; verified: 3.96 m and 10.5 rad/s in 1.5 s) and a glancing hit makes both spheres spin. It has no rolling resistance: on flat ground it keeps rolling until `angularDamping` / `linearDamping` (or an obstacle) stops it. Add `"lockRotation": true` for a ball that only slides (contacts never spin it and friction stops it within a second, which is what `rollWithMotion: false` meant before). Keep the default for a ball you steer by setting `velocity` every frame.

```js
// scripts/ball_control.js: push the ball with the move_* actions
import { Behaviour, input } from "factoria";

export default class BallControl extends Behaviour {
  speed = 6;

  onFixedUpdate() {
    const body = this.entity.get("RigidBody3D");
    body.velocity.x = input.axis("move_left", "move_right") * this.speed;
    body.velocity.z = -input.axis("move_back", "move_forward") * this.speed; // forward is -Z
  }
}
```

A **moving platform** is a `RigidBody3D` with `"type": "kinematic"` whose `velocity` the script sets. Bodies resting on top of it are carried along by its displacement, so a rider moves with the platform. Verified: over 30 frames the platform moved 1.49 m and the ball resting on it moved 1.48 m. A `CharacterController3D` standing on it is carried too (displacement, and the turn of a platform with `angularVelocity`, about the platform's centre) without any script code; set `"carriedByPlatforms": false` on the character for one that must not ride. Verified: a character stood 300 frames on a platform moving at 1 m/s and stayed within 5 cm of its place on it; with `carriedByPlatforms: false` it stayed where it was and the platform left.

```js
// scripts/mover.js: slides back and forth along X
import { Behaviour, time } from "factoria";

export default class Mover extends Behaviour {
  amplitude = 3;
  speed = 1.5;

  onStart() {
    this.body = this.entity.get("RigidBody3D");
  }

  onFixedUpdate() {
    this.body.velocity.x = Math.cos(time.elapsed * this.speed) * this.amplitude * this.speed;
  }
}
```

To make something spin without rolling, set `RigidBody3D.angularVelocity` (degrees per second about x, y, z) and `"rollWithMotion": false` with `"lockRotation": true` (a rigid sphere would roll on whatever it touches). Verified: `[0, 90, 0]` gave `rotation.y = 90` after one second. A box collider turns with the entity (a spinning kinematic bar pushes the bodies it meets); a sphere collider has no orientation, so for an arcade or locked sphere the spin is visual only. A dynamic box that is not `lockRotation`ed also spins by itself when it is hit or lands on an edge (below).

3D box colliders, fast bodies and sweeps:

- **Oriented boxes.** A `Collider3D` box takes the entity's world rotation (`Transform.rotation`, parents included), so a wall rotated 30 degrees about Y is a wall at 30 degrees, and a box turned 45 degrees blocks at its rotated edge, not at the corner of its axis-aligned bounding box. `offset` is rotated and scaled with the entity. Raycasts, `overlapSphere`, `isTouching`, events and the physics debug dump (`shapes[].rotation`, euler degrees) all use the turned shape. An unrotated box behaves exactly as before.
- **Dynamic boxes are rigid bodies.** Contacts and friction act at the contact points and apply torque (inertia from the box's size and mass, uniform density, rotating about the collider's centre). A box with its centre past a ledge edge tips over and falls, a box dropped on its corner falls onto a face and comes to rest (and falls asleep, see the next bullet), a stack of crates stays standing, and a sphere that hits a box near its top edge spins it. The orientation lives in the body; the engine writes it to `Transform.rotation` every step, and writing `Transform.rotation` yourself re-orients the body (it keeps its `angularVelocity`). `angularVelocity` is in degrees per second about the world axes; `RigidBody3D.angularDamping` slows a spin in the air (default 0). A box tumbling in the air precesses like a real one (a gyroscopic term keeps its angular momentum and energy: a fast spin about the intermediate axis of a plank flips over by itself); a cube or a sphere spins steadily.
- **Dynamic bodies sleep.** A dynamic 3D body whose fastest point (spin included) stays under 5 cm/s for half a second falls asleep together with every body touching it, so a stack of crates sleeps as one. A sleeping body costs no solver work and sends no collision events, and it stays exactly where it is. It wakes when an awake body or a moving kinematic platform touches it, when a script writes its `Transform.position` or `Transform.rotation` (a teleport wakes the body and everything touching it, like 2D), its `RigidBody3D.velocity` or `angularVelocity`, when `applyImpulse`, `applyForce` or `setVelocity` is called on it, when the scene's gravity changes, and when what it rests on is destroyed, disabled, resized or moved away (a crate on a deleted platform falls). Scripts cannot read or set the sleep state; the `awake` flag of each body is in the `physics` part of the engine state dump, as in 2D.
- **Keep characters upright: `lockRotation`.** `"lockRotation": true` on a dynamic box makes collisions and friction never turn it: it stays upright, slides and stops as boxes did before rotation dynamics (cheaper too). `angularVelocity` and `Transform.rotation` written by gameplay still turn a locked box. Use it on a box-shaped player or enemy and on any crate that must not topple. It also stops contacts from spinning a sphere with `rollWithMotion` off. A sphere with `rollWithMotion` on (the default) is never turned by contacts: its spin follows its motion. Kinematic and static bodies are not affected by torque.
- **Limits of the rotation model.** Contacts are exact for box-box face contacts (up to 8 clipped contact points), one point for contacts between two crossing edges and for sphere contacts (a box standing on one of its edges, parallel to the face it touches, still gets two contact points and does not wobble along the edge). Boxes have no rolling resistance: a tumbling box loses energy at each impact on a face or an edge and settles, and `angularDamping` is the knob for drag. A spinning kinematic bar pushes bodies by its collider, not by its surface speed.
- **Fast bodies do not tunnel.** A body that would move relative to another body (static, kinematic or dynamic) by more than about half its smallest size in one physics sub-step (a 60 m/s bullet sphere, two spheres flying at each other, a fast kinematic wall) is swept in relative motion and stopped at the time of impact. The contacts are resolved there (stop, bounce, slide) and the rest of the sub-step continues with the new velocities, so a fast body that hits a ramp keeps sliding along it instead of losing the rest of its move. This is automatic. A turning box is swept through its own rotation within the sub-step too (a long thin rod spinning at 40 rad/s cannot swing through a thin wall, and after one end hits, the rest of the sub-step still catches the other end swinging in). Up to 32 impacts per sub-step are resolved this way; with more (a ball bouncing a thousand times a second between two walls a hand apart) the rest of the move waits for the next sub-step instead of being applied unswept, so the body can only fall slightly behind in time, never tunnel.
- **Shape casts.** The 3D shape cast sweeps a sphere or an axis-aligned box from one point to another and returns the first collider it touches (oriented boxes and spheres included), with the distance the centre travelled, the contact point and the surface normal. Colliders that already overlap the shape at the start are skipped, like a raycast that starts inside a collider; `mask`, `ignore` and `ignoreTriggers` work as for raycasts.

- **Collider shapes: capsule, convex, mesh.** `Collider3D.shape` also takes `capsule` (`radius`, `height` tip to tip, along the entity's local Y: the shape for a character or a rod), `convex` (the convex hull of the vertices of `mesh`, for a rock, a crate with chamfers or any dynamic prop) and `mesh` (the triangles of `mesh`, for terrain, ramps and level geometry). `mesh` is a primitive name or a project-relative .gltf/.glb path, usually the same as the entity's `MeshRenderer.mesh`; `Transform.scale` scales it. **A `mesh` collider must be static**: with a dynamic or kinematic `RigidBody3D` it is ignored and the engine logs one error saying so (use `convex`, or several boxes and capsules, for a moving body). Every shape collides with every other one, and works with raycasts, shape casts, `overlapSphere`, `isTouching`, fast-body sweeps, sleeping, events and the physics debug draw. Limits: a convex hull from a model with over 256 vertices is reduced to 256 extreme points, a dynamic capsule or convex body has the inertia of its bounding box and rotates about its collider centre, a box lying on a mesh rests on its low corners, and a raycast that grazes a capsule or hull at under about 3 degrees can miss.
- **Joints.** Add `Joint3D` to an entity that has a `RigidBody3D` and a `Collider3D`: `"Joint3D": {"type": "hinge", "anchor": [0, 0.5, 0], "axis": [0, 0, 1]}` hangs it from a pivot at that point (in the entity's own axes) of the world; `connected` names another entity (it needs a body too) to hinge the two together (leave it out or write `""` for the world; both mean the same in scene files, scripts and `scene.set_component`), and `autoAnchor: true` then pins them where the anchor is now. `hinge` turns about `axis`, with `useLimits` (`lowerLimit`/`upperLimit` in degrees, measured from the pose the joint started in) and an optional motor (`useMotor`, `motorSpeed` degrees/s, `maxMotorTorque`); `ball` pins a point and leaves the rotation free (chains, ragdoll shoulders); `fixed` welds. The pair does not collide unless `collideConnected` is true. `Joint3D.angle` (read-only, degrees) is the hinge angle. A swinging body keeps its real pendulum period. `Joint3D.damping` (1/s, default 0) takes the swing out of the relative turning of the two bodies (a door that closes softly, a floppy limb). Bodies joined by joints sleep together once all of them are calm (a settled chain or bridge costs nothing and wakes when something touches it, a motor or a joint to a moving kinematic body keeps them awake), and groups of joined bodies are solved apart from each other, so one chain never disturbs another. `Joint3D.stalled` (read-only) turns true when a motor has been pushing for a quarter of a second without the joint turning (a gate against a wall, too little `maxMotorTorque`), so a script can react; a hinge that reached its limit is not stalled. A joint that cannot be built (no body, `connected` is itself or has no body) is reported once with how to fix it, and the body is not held. A scene simulates the same whatever ran in the process before it (earlier scenes, destroyed entities, reused entity slots): 3D bodies and joints are solved in the scene's entity order.
- **Character controller.** Put `CharacterController3D` on an entity (no `RigidBody3D`, no `Collider3D`: the controller is its own capsule) and move it from `onFixedUpdate`:

```js
import { Behaviour, physics, input, time, vec3 } from "factoria";

export default class Walker extends Behaviour {
  vy = 0;
  onFixedUpdate() {
    const dt = time.fixedDt;
    const walk = input.axis("move_left", "move_right") * 4, side = input.axis("move_up", "move_down") * 4;
    const r = physics.moveCharacter(this.entity, vec3(walk * dt, this.vy * dt, side * dt));
    if (r.isGrounded) this.vy = input.pressed("jump") ? 6 : -1;   // r.groundNormal, r.ground (entity), r.hitWall, r.hitCeiling
    else this.vy -= 9.81 * dt;
  }
}
```

  `radius`, `height`, `stepOffset` (highest step it climbs), `slopeLimit` (steepest slope it walks, degrees) and `skin` (small gap kept to surfaces) are fields of the component. It slides along walls instead of stopping, climbs steps up to `stepOffset`, treats slopes steeper than `slopeLimit` like walls, snaps down onto the ground when walking off a ramp, and pushes the free dynamic bodies it walks into (`pushStrength`, default 1 = it gives them its own speed, 0 = it does not push; a body held by a `Joint3D` is never pushed). It has no gravity of its own: keep a vertical speed in the script. Setting `CharacterController3D.velocity` (m/s) instead moves it every physics step without a script call. A kinematic platform it stands on carries it (`carriedByPlatforms`, default true; see the moving platform above). Standing on a dynamic body it weighs on it: with `applyWeight` (default true) every physics step presses `mass` kilograms times gravity on that body at the character's feet, so a seesaw tips towards the side it stands on and a plank of a bridge sags (`"applyWeight": false` for a character that weighs nothing).

  A seesaw is a dynamic plank on a hinge with the pivot at its centre; nothing else is needed for it to tip under the character:

  ```json
  "plank": { "components": {
    "Transform": { "position": [0, 1, 0] },
    "Collider3D": { "size": [4, 0.2, 1.5] },
    "RigidBody3D": { "type": "dynamic", "mass": 20 },
    "Joint3D": { "type": "hinge", "axis": [0, 0, 1], "useLimits": true, "lowerLimit": -20, "upperLimit": 20 }
  } }
  ```

  (`connected` left out = the world.) The plank turns about the z axis, stays on its pivot however the character pushes, and a character standing on its +x half takes the +x end down.

  **A rope bridge** is a row of dynamic planks hinged to each other, the first and the last hinged to the world. Nothing needs tuning: a chain of three or more jointed dynamic bodies gets extra solver iterations and a little drag by itself, so it hangs still and falls asleep within a few seconds (a body in a chain is about 1 m long and 5 to 10 kg; planks 1 m wide or more are the easy case). Build the planks in a script when the scene starts, so a level only says where the bridge goes:

  ```js
  import { Behaviour, world } from "factoria";

  export default class RopeBridge extends Behaviour {
    from = [0, 2, 0]; to = [12, 2, 0]; planks = 12; sag = 0.4;
    onStart() {
      const n = this.planks, [fx, fy, fz] = this.from, [tx, ty, tz] = this.to;
      // A parabola from one end to the other; plank i spans the points i/n and (i+1)/n of the curve.
      const at = (t) => [fx + (tx - fx) * t, fy + (ty - fy) * t - this.sag * 4 * t * (1 - t), fz + (tz - fz) * t];
      const planks = [];
      for (let i = 0; i < n; i++) {
        const a = at(i / n), b = at((i + 1) / n);
        const len = Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
        const tilt = (Math.atan2(b[1] - a[1], b[0] - a[0]) * 180) / Math.PI;
        const mid = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 0.07, (a[2] + b[2]) / 2];
        planks.push(world.spawn({ id: `${this.entity.id}_plank_${i}`, components: {
          Transform: { position: mid, rotation: [0, 0, tilt] },
          Collider3D: { shape: "box", size: [len * 0.94, 0.14, 1.5], friction: 0.8 },
          RigidBody3D: { type: "dynamic", mass: 6 },
        } }, { position: mid }));
      }
      // The hinge of plank i sits at its far end and joins it to plank i + 1; the last one joins the world ("").
      planks.forEach((p, i) => p.add("Joint3D", { type: "hinge", axis: [0, 0, 1],
        anchor: [0.47 * Math.hypot(...at((i + 1) / n).map((v, k) => v - at(i / n)[k])), 0, 0],
        connected: i + 1 < n ? planks[i + 1].id : "" }));
      // The first plank hangs from a static post at the start.
      const post = world.spawn({ id: `${this.entity.id}_start`, components: {
        Transform: { position: at(0) }, RigidBody3D: { type: "static" },
        Collider3D: { shape: "box", size: [0.05, 0.05, 0.05], isTrigger: true } } }, { position: at(0) });
      post.add("Joint3D", { type: "hinge", axis: [0, 0, 1], connected: planks[0].id });
    }
  }
  ```

  Rules: put both ends just past the edges of the slabs (0.05 m or more): a plank that starts inside a static collider is reported (a warning in the log on the first step, naming both entities, the depth and the fix, and by `factoria validate` for scenes) and the chain buckles. The courier walking on it weighs on the planks (`CharacterController3D.applyWeight`) and never shoves them. For a limp rope or a heavier bridge add `damping` (try 2 to 10) to the planks' joints; do not raise the bodies' `linearDamping`, which also slows the fall. There is no `physics.make_chain3d` command: the recipe is about 25 lines and the engine settles the chain itself, so a command would only hide this code.

### 9.19 3D ground checks and raycasts

```js
import { Behaviour, physics, vec3 } from "factoria";

export default class GroundProbe extends Behaviour {
  onUpdate() {
    this.grounded = this.entity.isGrounded();   // 3D tolerance is 0.05 m by default
    // Distance to the floor below, ignoring this entity's own collider.
    const down = physics.raycast3d(this.entity.worldPosition, vec3(0, -1, 0), 5, { ignore: this.entity });
    this.height = down ? down.distance : Infinity;   // down = { entity, point, normal, distance } or null
  }
}
```

A collider that contains the ray origin is always skipped, so a ray that starts at the centre of a ball does not hit the ball. Use `ignore` when the ray starts outside the caster's own collider, for example just ahead of a body. The 3D `isTouching(direction)` works like the 2D one, for any direction.

### 9.20 Neon glow: additive blend and camera bloom

Glow is a camera setting, not artwork. Draw the bright things with `"blend": "additive"` (overlapping lights add up instead of covering each other), then switch on bloom on the primary `Camera`: every pixel brighter than `bloomThreshold` bleeds light into its surroundings. Do not hand-draw blurred halo sprites or stack translucent copies of a shape; they cost entities and never look as good.

```json
{ "id": "camera", "components": {
    "Camera": { "projection": "orthographic", "clearColor": [0.02, 0.02, 0.05, 1],
                "bloom": true, "bloomThreshold": 0.6, "bloomIntensity": 1.2, "bloomRadius": 20,
                "bloomScreenSpace": false } } },
{ "id": "ship", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Shape2D": { "shape": "triangle", "size": [60, 60], "color": [0.1, 0.9, 1, 1], "pivot": [0.5, 0.3333],
                 "filled": false, "thickness": 4, "blend": "additive" } } }
```

- **Fields.** `bloom` turns it on (default off, so existing games are unchanged). `bloomThreshold` (0..1, default 0.7) is the brightness where glow starts, measured as the largest of r, g and b, so a saturated colour such as `[1, 0, 0.8]` glows as much as white. Lower it to make dim colours glow, raise it so only the brightest things do. `bloomIntensity` (0..10, default 1.2) is how much glow is added. `bloomRadius` (1..128 design pixels, default 20) is how far it reaches; radii below about 5 behave like 5.
- **Dark background.** The glow is added on top of the picture, so it only shows on dark areas. Keep `clearColor` and backgrounds dark; a light background hides it.
- **Bright sources.** Sprites, shapes and particles that glow need a bright `color` (at or above the threshold). `ParticleEmitter` with `"blend": "additive"` plus bloom gives fire, sparks and explosions for free. In 3D, bright unlit meshes (`MeshRenderer.unlit`) and strong `emissive` colours glow the same way.
- **HUD: crisp or glowing.** By default bloom is applied to the whole finished picture, screen-space items included, so white HUD text glows too. Set `"bloomScreenSpace": false` on the `Camera` (the recipe above does) to draw the screen-space items (Sprite, Shape2D and Text with `"space": "screen"`, and debug text) AFTER the bloom: the world glows and the HUD stays crisp, with translucent panels blending over the glow. Leave it `true` when a screen-space title or logo should glow, as on a title screen. Particles and tilemaps are world-space only, so they always glow.
- **Shapes for neon.** `Shape2D` has `rectangle`, `circle`, `line`, `triangle`, `diamond` (a rhombus touching the middles of its `size` box; a square box gives a 45-degree square), `polygon` (`sides`) and `star` (`points`, `innerRadius`). Outlines (`filled: false`, `thickness`) read best under bloom. `pivot` is also the point a shape rotates around: a spinning `triangle` wobbles with the default pivot because the centre of its box is not its centre of mass, so give it `"pivot": [0.5, 0.3333]` (its centroid). The recipe above does.
- **Screenshots and tests.** The glow is part of the image (`factoria run --headless --screenshot-at`, MCP screenshots), and it is deterministic. Look at a screenshot after tuning; compare with `bloom: false` to see what it adds.
- **Animating it.** `this.entity.get("Camera").bloomIntensity = 1 + Math.sin(time.elapsed * 4) * 0.5;` pulses the glow from a script.
- **Cost.** Bloom reads the finished frame once, blurs a reduced-resolution copy and adds it back (4 to 7 extra passes, the number grows with the radius). That is cheap on a GPU; the software renderer used for headless runs spends about 5 ms per drawn frame at 1280x720. Headless tests and `factoria call` only draw when they take a screenshot, so bloom costs them nothing otherwise.

### 9.20.1 Colour-blind players: the colour filter and the colour-blind check

Roughly one player in twelve men and one in two hundred women cannot tell some colours apart, so a hazard that is only red against a green floor is invisible to them. Two separate tools:

- **Check it yourself (no change for the player).** `game_screenshot {"simulate":"deuteranopia"}` (also `protanopia`, `tritanopia`, `greyscale`), `game.screenshot(path, { simulate: "protanopia" })` in a test, or `factoria run --headless --screenshot-at 60 --screenshot-simulate deuteranopia`. The saved PNG shows what that viewer sees: look at it and ask whether every hazard, pickup, enemy and button is still found, by shape, outline, brightness or an icon, not only by hue. Take one normal screenshot and the `greyscale` one at least; add `deuteranopia` (the commonest) for red/green designs. The method: the pixels are taken as sRGB, decoded to linear light, multiplied by the Machado, Oliveira and Fernandes 2009 matrix of severity 1.0 (the cone is missing completely, the worst case) and encoded again; `greyscale` is Rec. 709 luminance in linear light. The check is done on the CPU on the saved file, so what the game draws is untouched.
- **Give it to the player.** `Camera.colorFilter` is the last post-process of the frame (after bloom, HUD included), so screenshots, `--screenshot-at` and `--record-video` show it: `none` (default, no cost), `greyscale`, `highContrast` (contrast x1.8 around mid grey) and `protanopia`, `deuteranopia`, `tritanopia`, which are daltonize corrections for a player who lacks that cone: the loss is estimated with the same Machado matrix and the lost information is shifted into the channels the player still sees (Fidaner's method), so red and green end up differing in brightness and blue. The engine never saves the choice: put an option in the game's options screen that writes `this.entity.get("Camera").colorFilter = "deuteranopia"` and keeps it in `storage` (the menu kit in [MENUS.md](MENUS.md) has the button), and set it again in every scene, as every scene has its own camera.

Prefer designs that work without any filter (shapes, outlines, patterns); the filter is the safety net, the check is how you know.

### 9.21 Sweep a shape instead of a ray: will it fit, how far can it go

A ray is a line. When the thing that has to fit has a size (a character stepping into a gap, a crate being pushed, a dash, a placement preview), sweep its shape with `physics.shapeCast(shape, from, to, opts)`. It returns the same `{ entity, point, normal, distance } | null` as `raycast`; `distance` is how far the centre of the shape travels before it touches something.

```js
// scripts/dash.js: dash right as far as the player's own box fits, never into a wall (needs a "dash" input action).
import { Behaviour, input, physics, vec2 } from "factoria";

export default class Dash extends Behaviour {
  size = [28, 44];     // the same size as the player's Collider2D
  length = 120;

  onFixedUpdate() {
    if (!input.pressed("dash")) return;
    const p = this.entity.position;
    const from = vec2(p.x, p.y), to = vec2(p.x + this.length, p.y);
    // Skips the player's own collider (ignore) and anything it already overlaps at `from`.
    const hit = physics.shapeCast({ shape: "box", size: this.size }, from, to, { ignore: this.entity });
    const travel = hit ? hit.distance : this.length;     // hit.normal is the wall's surface normal
    this.entity.position = [p.x + travel, p.y];
  }
}
```

- **Shapes.** 2D: `{ shape: "circle", radius: 8 }` or `{ shape: "box", size: [w, h] }` (pixels). 3D (pass 3D `from`/`to`): `{ shape: "sphere", radius: 0.5 }` or `{ shape: "box", size: [x, y, z] }` (meters). Full sizes, like the colliders; the shape is centred on the cast position and never rotates. Sweep a capsule collider with a box or circle of similar size.
- **Where it stops.** At contact: in 2D, to a fraction of a pixel, so moving the centre by `distance` puts the shape against the surface, not into it.
- **Touching is not overlapping.** A body standing on the ground touches it: a cast down hits at once (`distance` about 0, `normal` up) and a cast up or sideways ignores the ground. A collider the shape is deeper inside than 1 cm (1 pixel at the default 100 pixels per meter) is skipped, as a ray starting inside a collider is. Put `ignore: this.entity` for the caster's own collider.
- **Not for** testing a spot (`from === to` returns `null`; use `overlapBox` / `overlapCircle`), ground checks (`isGrounded`) or walls (`isTouching`).
- From outside a script, the command `physics.shape_cast` does the same: `{"shape":{"shape":"box","size":[28,44]},"from":[0,100],"to":[120,100],"ignore":"player"}`.
- A wrong shape throws an Error that names the problem and shows an example, for instance `"sphere"` in a 2D cast (`"circle"` is the 2D name) or a misspelt `"circel"` (did you mean `circle`).

### 9.22 A menu: buttons, sliders, focus and the gamepad

Widgets (section 7, UI) are entities in screen space. A `Panel` with `layout: "column"` stacks its children; the first
item has `autoFocus` so the keyboard and the gamepad work from the first frame. A scene (`scenes/menu.scene.json`) with a
title, two buttons and a volume slider:

```json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "menu", "name": "Main menu",
      "components": {
        "Transform": { "position": [0, 0, 0] },
        "Panel": { "anchor": [0.5, 0.5], "size": [360, 300], "layout": "column", "spacing": 12, "padding": [20, 20, 20, 20] } },
      "children": [
        { "id": "title", "components": { "Text": { "text": "My Game", "fontSize": 36, "space": "screen", "pivot": [0.5, 1] } } },
        { "id": "play_button", "components": { "Button": { "text": "Play", "size": [260, 56], "autoFocus": true } } },
        { "id": "volume", "components": { "Slider": { "label": "Volume", "value": 0.8, "size": [320, 44] } } },
        { "id": "quit_button", "components": { "Button": { "text": "Quit", "size": [260, 56] } } }
      ] }
  ]
}
```

```js
// scripts/menu.js, on the "menu" entity
import { Behaviour, ui, scene, game, audio } from "factoria";

export default class Menu extends Behaviour {
  onStart() {
    this.on("ui.click", (data) => {
      if (data.id === "play_button") scene.load("scenes/level1.scene.json");
      if (data.id === "quit_button") game.quit();
    });
    this.on("ui.change", (data) => { if (data.id === "volume") audio.setVolume("master", data.value); });
  }
}
```

- **Navigation is automatic.** Up / down / left / right (keys, d-pad, left stick) move the focus to the nearest widget
  in that direction (widgets lined up with the focused one first, so Right along a row of tabs stays on the row),
  `ui_submit` (Enter, Space, pad A) clicks, `ui_cancel` (Escape, pad B) sends `ui.cancel`; the mouse works too. Nothing is
  focused until an `autoFocus` widget or `ui.focus(entity)` takes the focus, which keeps Space / A (jump) from clicking HUD
  buttons during play. Rebind the six `ui_*` actions in `factoria.json` `input.actions` if you want other keys.
- **Looks.** A plain widget is a translucent dark rectangle with a label; give `texture` + `slice` (9-slice borders in
  texture pixels) for a themed one, and `color`, `textColor`, `accentColor` to restyle. Everything is design pixels, so
  `size`, `padding` and `spacing` do not change with the window size; use `anchor` and `pivot` to pin a panel to a corner
  or the centre.
- **Pause menu.** The UI keeps working while `game.paused` (`time.scale` 0); section 9.24 has the pause menu.
- **Find and click things from outside.** `ui.state` lists every widget with its `rect` (so `game.input` can click its
  centre), `focused` and `value`. To test a menu without a mouse, tap the pad: `game.gamepad().tap("DpadDown")`,
  `.tap("A")`, then assert on `ui.focused`, widget values or `ui.on` events (see `SCRIPTING.md`, UI).
- **Long lists** go in a `ScrollList`: the wheel scrolls it, moving the focus to an item scrolls it into view, and
  everything inside is clipped to its rectangle.

### 9.23 Art, sounds and models: generate, import, ship

Never hand-draw placeholder art pixel by pixel through `fs.write`: generate it, import it, and let the export compress
it. The full reference is `docs/ASSETS.md` (`docs_read {"name":"assets"}`).

**Generate.** `assets.generate_image` writes a PNG at the size you ask for, records where it came from, and shows you the
picture: look at it, and ask again (`overwrite: true`) with a better prompt. The house style in `assets.json` (`style`:
`prompt`, `references`, `palette`) is applied to every image, so the art stays consistent; `style: false` skips it.

```json
{"prompt": "a knight, side view, idle", "path": "assets/knight.png", "width": 64, "height": 64, "transparent": true}
```

A character that moves is a sprite sheet: `assets.generate_sprite_sheet {"prompt":"a knight walking right","path":"assets/knight_walk.png","frames":6,"columns":3,"frameWidth":64,"frameHeight":64,"fps":10}`
normalizes the grid and records it, and its result gives the components to use: `Sprite {texture}` and `SpriteAnimator
{columns, rows, firstFrame, lastFrame, fps}` on one entity. Sounds and music: `assets.generate_sound` and
`assets.generate_music` (`prompt`, `path`, `seconds`; the extension is the one the provider makes, the error names it),
speech: `assets.generate_voice {text, path, voice}`, models: `assets.generate_model {prompt, path}`; use them as the
`clip` of an `AudioSource` and the `mesh` of a `MeshRenderer`.

- **Providers.** They are configured by the user in `ai.json` (`assets` section). If a kind has none, the error shows what to
  add; do not edit `ai.json` yourself, tell the user. `provider: "fake"` works offline and makes small placeholders: use it
  to build and test the flow, then ask the user which real provider to use. Generation costs money: one call, look, then
  decide; never loop over variations.
- **Provenance.** Every generate command records `origin`, `ai`, provider, model, prompt and license in `assets.json`. Files
  you did not generate get a record with `assets.set_provenance {path, origin: "original" | "imported", ai, license, source}`
  (`ai: true` for something made with AI elsewhere). `assets.provenance {}` lists the records and the files that have none.
- **Store disclosure.** Before a release, `assets.disclosure` returns the AI-content text for Steam's survey; `factoria export`
  writes it as `AI_CONTENT_DISCLOSURE.md`. Fix the "Assets without provenance" list first.
- **Tests.** A test project uses the `fake` provider, so the check is offline and deterministic.

**Importing.** A file made elsewhere (downloaded, from an artist, exported from a tool) comes in with `assets.import`
(MCP tool `assets_import`). It copies or converts the file into `assets/` and records the provenance in `assets.json`:

```
assets_import {"source":"C:/art/hero.aseprite","license":"CC-BY 4.0","author":"Ana Lopez"}
```

- **Say where it came from.** Pass `license` and `author` for anything you did not make (the credits and the store
  disclosures read them), `ai: true` for what an AI made, and `sourceUrl` for the page you downloaded it from. A URL is
  not read: download the file first. `path` picks the destination (a path under `assets/`, or a folder ending in `/`).
- **Formats.** Aseprite becomes a PNG sheet with its tags as clips, PSD a PNG, OBJ (with its MTL and textures) a `.gltf`,
  FBX a `.glb` (through FBX2glTF or Blender; the error says where to get one), a video (`.mp4`, `.mov`, `.webm`...) an
  `.mpg` (MPEG-1 + MP2, through ffmpeg: `factoria setup ffmpeg`) for the `Video` component. Images, sounds, fonts, GLB and
  glTF are copied. Not read: `.blend`, WebP, GIF, SVG. The full list is in `docs_read {"name":"assets"}`.
- **Read `nextSteps` and `warnings`.** They hold the `Sprite` and `SpriteAnimator` fields to use for a sheet (columns,
  rows, first and last frame, fps), the size of a model, and what could not be carried over (ping-pong tags, blend
  modes, a missing texture).
- **A sheet that is not a clean grid** (frames of different sizes, a solid background, as generated and downloaded
  sheets often are): `assets_slice_sheet {"path":"assets/walk_raw.png","auto":true,"frames":8,"align":"bottom","background":"auto"}`
  finds the sprites, repacks them into a uniform grid, writes `walk_raw_sheet.png` and returns the SpriteAnimator
  fields. A regular grid you know: `{"path":"assets/walk.png","columns":4,"rows":2}` checks it against the image and
  records it.

**Shipping textures.** A mobile `factoria export` compresses every texture to a KTX2 twin (`assets/hero.png.ktx2` replaces
`assets/hero.png`; names in scenes and scripts do not change; import setting `compression`). Set `"atlas": "ui"` in a
texture's import settings (`assets.json`) to have the export pack that group into one atlas image, for sprites,
particles and UI widgets only (not tilesets or mesh textures; validate warns). `factoria run` keeps using your PNGs. Details:
`docs/ASSETS.md` > Textures.

**Shipping audio.** Audio ships with three import settings (`assets.json`, `docs_read {"name":"assets"}` "Import
settings > Audio"): `stream` (`auto` streams sounds over 10 seconds; `always`/`never` force it), `normalize` with
`targetLufs` (play every sound at the same loudness, default -16 LUFS) and `convert: "qoa"` (the export ships WAV files
as `<path>.qoa`, about 5 times smaller; scenes and scripts keep the `.wav` name). Run `assets.analyze_audio` once after
adding sounds: it measures their loudness and keeps the result in `assets.json` (needed on mobile, where the engine
never measures), and `project_validate` warns about clipped, very loud, very quiet and unevenly loud sounds.

### 9.24 Game menus: main menu, options, credits, loading screen, pause

New projects have no menus. `factoria call project.add_menu_kit` (MCP `project_add_menu_kit {"parts":[...]}`, default all
parts; it never touches a file you changed unless `overwrite` is true and adds only the texts your locales lack) copies a
complete set into the game, and `factoria docs read menus` (MCP `docs_read {"name":"menus"}`) explains it. FactorIA's own
tests drive it with a gamepad only: a main menu, options (video, audio per bus, controls, language),
credits listing the software in `FACTORIA_NOTICES.txt`, a loading screen and a pause menu, with the settings saved
between runs. In short:

1. `factoria.json`: `"mainScene": "scenes/menu.scene.json"` and a `"pause": ["Escape", "P", "GamepadStart"]` action.
2. `scripts/settings.js` (settings in `storage`, applied once per run) and `scripts/ui/menu_stack.js` (panels over
   panels, back with B / Escape).
3. The main menu and credits: `scenes/menu.scene.json`, `scripts/main_menu.js`, `scripts/ui/credits.js`.
4. Options: `prefabs/ui/options.prefab.json`, `scripts/ui/options.js`.
5. The loading screen: `scenes/loading.scene.json`, `scripts/loading.js`.
6. Pause: `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js`, and one `pause_menu` entity in each level.
7. A shop, only for a game with in-app purchases: `scripts/ui/shop.js`, the `shop` panel and `shop_button` of the menu
   scene, and `scripts/store_events.js` (pauses the game while the store overlay is open). It uses the `platform`
   API (`factoria docs read platform`); the kit's `tests/platform.test.js` drives it against the fake store.
8. Languages: `factoria.json` `"localization"`, `locales/<language>.json` per language and a `key` on every Text and
   widget (`factoria docs read localization`); the kit's `tests/i18n.test.js` switches the language at run time.

When you write menus of your own, the same rules apply:

- **Panels over panels.** Show one panel and hide the one below with `active`: a focused widget that becomes inactive
  loses the focus and the new panel's `autoFocus` widget takes it. Remember `ui.focused` before, and `ui.focus(...)` it
  after closing, so the player lands where they were.
- **Pause.** `game.paused = true` freezes physics, animations and every behaviour without `runWhilePaused = true`; the
  UI keeps working. Unpause in the pause behaviour's next `onUpdate`, not in the "Resume" click handler, or the A /
  Space press that clicked it also jumps. `time.scale` outlives scene loads: set `game.paused = false` before
  `scene.load`.
- **Settings.** Keep them in `storage` and apply them when the game starts (`session` remembers that it was done).
  `window.*` setters throw when there is no window (headless runs, tests): check `window.available`.
- **Controls.** Rebind with `input.rebind(action, list)` from the next `input.lastPressed()`, and name buttons with
  `input.buttonName(action)` (Cross on a PlayStation pad, A on an Xbox pad).
- **Quit** has no place on phones and tablets: hide it when `game.platform` is `"ios"` or `"android"`.
- **Several languages.** Put the text of a game that may be translated in `locales/<language>.json` from the start and
  give the `Text` or widget a `key`: `{ "text": "Play", "key": "menu.play" }`. The engine overwrites `text` with the
  player's language, so a script never writes it; text a script builds uses `i18n.t(key, { count })` and is written
  again on `i18n.on("change", ...)`. `i18n.setLanguage(tag)` switches at once; the choice goes in `storage`.
- **Adding a language.** Add its tag to `localization.languages`, create `locales/<tag>.json` with the keys of the default
  language's table, list a font in `localization.languageFonts` when its script is not Latin, Greek, Cyrillic, Hebrew or
  Arabic (Noto Sans has one per script), and run `factoria validate`: it names missing keys, wrong placeholders and
  plural forms, `key`s no table has, and every character no font of the language can draw (`U+65E5 '日'`). To send the
  strings to translators, `factoria call i18n.export` writes a CSV or XLIFF file and `i18n.import` reads it back.

### 9.25 Animated characters, state machines and tweens

Full reference: `docs_read {"name":"animation"}` (docs/ANIMATION.md). A skinned glTF/GLB with named animation clips plays
through the `Animator` component, on the entity that has the model's `MeshRenderer`:

```json
{ "id": "hero", "components": {
    "MeshRenderer": { "mesh": "assets/models/hero.glb" },
    "Animator": {
      "clip": "Idle",
      "events": [{ "clip": "Run", "time": 0.25, "name": "footstep" }, { "clip": "Run", "time": 0.75, "name": "footstep" }],
      "params": { "speed": 0 },
      "states": { "idle": { "clip": "Idle" }, "run": { "clip": "Run" } },
      "transitions": [ { "from": "idle", "to": "run", "when": "speed > 0.1", "fade": 0.15 },
                       { "from": "run", "to": "idle", "when": "speed <= 0.1" } ] } } }
```

```js
hero.animator.set("speed", Math.abs(vx));                       // the state machine does the rest
hero.animator.play("Attack", 0.1);                                // or drive clips by hand: cross-fade 0.1 s
hero.animator.on("footstep", () => audio.play("assets/sounds/step.wav"));
```

Animation runs in the fixed step, so headless tests and replays match (`game.step(60)` then check
`hero.animator.state` / `.time`). `import { tween, ease } from "factoria"` moves any number, vector or color over time
(2D and 3D): `tween(panel.position, { x: 0 }, { duration: 0.4, ease: "backOut" })`, `await tween(...).finished`.
The model is drawn deformed on the GPU (up to 64 joints; more joints = bind pose plus a warning), shadows included.
Each animated model is its own draw call, so keep crowds of animated characters modest.

### 9.26 2D production: flipped tiles, 9-slice, lights, parallax, joints

- **Flipped and rotated tiles.** A tile value in `Tilemap.tiles` is the index plus flag bits: `+268435456` flip X, `+536870912` flip Y, `+1073741824` transpose (applied first, then X, then Y). Turn 90 degrees clockwise = `1342177280 + i`, 180 = `805306368 + i`, 90 counter-clockwise = `1610612736 + i`. `solidTiles`, the tileset range check and collision use the plain index only. In `scene.import_ascii` a legend object takes `{"tile": 3, "flipX": true, "flipY": false, "rotate": 90}` (rotate is clockwise: 0, 90, 180, 270) so you never write the numbers.
- **9-slice sprites.** `Sprite.slice` = `[left, top, right, bottom]` in pixels of the picture (of the `region` when set). The corners keep their size, the edges and centre stretch to `size`. Works with `flipX/flipY`, `region` and atlas textures. A size smaller than the corners shrinks them evenly.
- **Lights.** Add `Light2D` entities (`type` point or directional, `color`, `intensity`, `radius`, `falloff`, `height` for point lights, `direction` and `elevation` for directional ones). Only a `Sprite`, `Tilemap` or `Shape2D` (world space) with `lit: true` is lit (a lit shape is flat: no normal map, outlines and lines included); the base brightness is `SceneSettings.ambientLight`. `Sprite.normalMap` (needs `lit`) gives bumps; the normal map may be another size or packed in an atlas. At most 16 lights per frame (WebGL2 and GLES3 uniform limit): directional lights first, then the point lights whose radius reaches the camera view (the ones with more of their radius in view first, then the brighter ones; an off-view light is never kept over one in view). More than 16 in view logs one warning per scene; `game.renderStats().lights2d` and `lights2dDropped` show what was kept and left out, and `perf.measure`'s `lights` (so `maxLights`) counts 2D and 3D lights together. Lights ignore layers and cast no shadows. Unlit sprites cost nothing extra.
- **Parallax.** `Parallax.factor` 1 follows the world, 0 sticks to the screen, 0.5 moves at half the camera's speed (use a value above 1 for a foreground). `repeatX` / `repeatY` with `repeatSize` tile a Sprite endlessly over the view. It works with the camera follow of 9.6: the offset is computed from the camera position each frame, so `entity.bounds()` and the editor pick follow it and replays stay deterministic.
- **Joints.** `Joint2D` goes on the body entity. `connected` is another entity with a body, or empty to pin to the world (then `connectedAnchor` is a world position). `anchor` is on this entity, `connectedAnchor` on the other, in local pixels. Types: `revolute` (hinge; `enableLimit` with `lowerLimit`/`upperLimit` in degrees, 0 = the pose at creation), `distance` (a rope of `length`, 0 = the starting distance; `enableSpring` with `springHertz`/`dampingRatio` makes it elastic), `prismatic` (slides along `axis`, limits in pixels), `weld` (glue). `enableMotor` with `motorSpeed` (degrees/s or px/s) and `maxMotorTorque`. Limits, motor and spring change live from scripts; the type, anchors, axis and `connected` rebuild the joint. `reactionForce`, `reactionTorque`, `angle` and `translation` are read-only runtime fields.

```js
const j = this.entity.get("Joint2D");
j.enableMotor = true; j.motorSpeed = 180;        // a wheel starts spinning
if (Math.hypot(j.reactionForce.x, j.reactionForce.y) > 5000) this.world.destroy(this.entity); // a rope that takes too much
```

## 10. Tests

Each test file starts with fresh module state, an empty `session` and storage, and the project's start scene and seed, so results are deterministic. Drive the game through inputs and assert on the result:

```js
import { test, expect, game } from "factoria:test";

test("player runs right", () => {
  game.load("scenes/main.scene.json");
  game.step(60);                  // let the player land
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30);
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});
```

The `game` object under test:

- Scenes: `load(path)` (reseeds the RNG; behaviours exist at once, `onStart` runs on the first `step`), `loadJson(sceneObject)` for a scene built in the test.
- Time: `step(frames = 1)`. 60 frames is one second of game time.
- Actions: `press(action)` and `release(action)` hold an action until released; `tap(action)` presses for one frame.
- Keys and mouse: `keyDown(key)`, `keyUp(key)`, `mouseMove(screenPos)`, `click(screenPos, button?)`.
- Widgets: `click`, `touch` and `touchStart` also take a widget id or an Entity instead of a position and use the centre of its laid-out rectangle (safe area included). `ui.rectOf(entityOrId)` gives that rectangle (a widget or a screen-space `Text`; the `rect` of `ui.state` lists the same). After `game.setSafeArea(...)` take a `game.step(1)` before reading a rectangle or touching a control anchored to the safe area.
- Timing: `world.emit` from a test reaches its listeners at the next `game.step`; `platform.*` answers are ready at once.
- Touch: `touch(screenPos, frames)` for a finger held for some frames, `touchStart(screenPos, id?)`, `touchMove(screenPos, id?)`, `touchEnd(id?)`. `input.touches[0].pressed` is true on the first frame only. As on a device, the first finger also moves the mouse and holds the left button (`input.mouse.pressed("left")` is true on that first frame), so a touch test also covers the mouse branch of your code: do not add a `click` to simulate it. A script that handles both the mouse and `input.touches` sees one tap twice, so make the second handling harmless (for example, act on the target cell only if it is not already taken).
- Queries: `find(idOrName)`, `world`, `time`, `state()`, `screenshot(path)` (needs graphics).
- Store: `game.platform` controls the fake store every test run uses (not the `game.platform` of the `factoria` module, which is the OS name): `respond(method, answer, times = 1)` makes the next `"purchases.buy"` fail (`{ error: "network" }`), cancel (`{ status: "cancelled" }`) or answer something else, `emit("purchase" | "overlay" | "player", data)`, `set({ signedIn, delayFrames, backend })` (`backend: "none"` plays a game without a store until `reset()`: `platform.has` is false and calls reject `unavailable`), `state()`, `calls()`, `reset()`; `await platform.purchases.buy(...)` works in a test (`docs_read {"name":"platform"}`).
- Sound: `audioLog()` lists the sounds played since the test started (`{frame, time, path, volume, pitch, pan, bus, loop, music, source, ok}`, oldest first); it is cleared before each test, and `clearAudioLog()` clears it by hand.

Assert sounds with `toContainPlayed` (alias `toHavePlayed`). The path can be the full project path, just the file name, or a RegExp; options `times` (exact count), `bus` and `source` (entity or id) narrow it. Plays whose clip failed to load do not count, and the failure message lists what did play:

```js
test("jumping plays the jump sound once", () => {
  game.load("scenes/main.scene.json");
  game.step(60);
  game.clearAudioLog();                      // ignore sounds from the level start
  game.tap("jump");
  expect(game.audioLog()).toContainPlayed("assets/sfx/jump.wav", { times: 1 });
  expect(game.audioLog()).not.toContainPlayed("hurt.wav");
});
```

Patterns that work:

- Settle first with `game.step(...)`, then act, then assert. Read values after the step, not before.
- Reach behaviour fields through the entity: `game.find("enemy_1").behaviour.dir`.
- Test behaviour, not implementation: positions, component values, whether an entity still exists (`game.find(id) === null`).
- Use `toBeCloseTo(n, digits)` for floats, and `toBeGreaterThan` for "moved far enough".
- Physics is exact for one build on one platform, not across them (next section). Where a level test depends on a chaotic setup (a rope bridge, a stack, a seesaw), wrap it in `robust(check, { runs, nudge })`: the check runs under small, repeatable nudges of the bodies, so it asserts what survives rounding (reached, delivered, a range) instead of an exact frame count.
- `game.load` gives a test a known starting state. Within one file, anything else (variables, `session`, behaviour fields) carries over between tests unless the test loads or resets it.
- Storage is an empty in-memory store for each test file, so tests never read or write the real save. `session` is also reset per file.
- Keep tests fast: headless steps do not draw, so `game.step(600)` costs little. Take a screenshot only where you need to see something, and avoid `--render-all`, which draws every frame in software and is much slower.
- `console.log`, `console.warn` and `console.error` in scripts are log lines with category `script`. `factoria test` shows what each test printed, indented under the test (and under `logs` with `--json`). Use `console.log` while you debug, and remove it before you finish.
- Import JSON data in tests the same way as in scripts (`import levels from "../data/levels.json";`).

### Physics and platforms

What holds: the same source, seed and input give the same physics, bit for bit, on Linux, Windows and macOS (and Debug and Release agree). The engine gets there in three ways. It is built with no floating-point contraction (`-ffp-contract=off`, `/fp:precise` on MSVC), so `a * b + c` is never fused into one rounding on arm64 or on CPUs with FMA. The simulation never calls the C library's `sin`, `cos`, `atan2`, `asin` or `acos`, whose last bit differs between glibc, Apple's libm and the MSVC CRT: it uses `fa::det::` (`fa/core/det_math.h`), which is built only from `+ - * / sqrt` on doubles, and those IEEE 754 rounds the same everywhere. Ties in sorts are broken by index or entity id, never by the standard library's own order. Box2D (2D) has its own cosine, sine and atan2 and is built with the same flags.

CI runs a physics replay on its Linux, Windows and macOS jobs, prints its hash (`FA_PHYSICS_REPLAY_HASH`) and compares it with the ONE value committed in `engine/physics/tests/test_determinism.cpp`; a platform that differs fails the job.

What is not promised: the same engine version only. A change to the physics code, or to a game's own scene, moves the result (and so the committed hash) on every platform together. The exact numbers of `Math.sin` and friends in game scripts, and of rendering, are not part of this: scripts that feed such numbers into physics (an angle computed with `Math.atan2`) get the JavaScript engine's own result, which may differ by a bit between platforms; keep gameplay-critical angles to the transform and physics APIs.

For your game: do not assert an exact frame count or an exact position after a long physics run. Use `robust()` (SCRIPTING.md, "Tests") and give chaotic setups a margin (bridges that settle before the player arrives, ledges wider than the worst nudge).

## 11. Debugging, live sessions and replays

| Command | MCP tool | What it tells you |
|---|---|---|
| `factoria validate`, `project.validate` | `project_validate` | Structure and references, before anything runs. |
| `script.errors` | `script_errors` | Exceptions thrown by scripts, with file, line and stack. |
| `game.logs` | `game_logs` | Log lines. `console.log/warn/error` in scripts appear with category `script`. |
| `audio.log` | `audio_log` | Which sounds played, on which frame and bus, and whether the clip loaded. |
| `game.state` | `game_state` | Entities, components, physics, logs and errors of the running game. |
| `scene.get_entity` | `scene_get_entity` | One entity by id. |
| `script.trace` | `script_trace` | Run the project headless and record the stack, locals and watch expressions every time given script lines run (with an optional condition), or collect logpoint lines: `{"points":[{"file":"scripts/player.js","line":17,"condition":"this.body.velocity.y > 0","watch":["this.body.velocity","dt"]}],"frames":300,"maxHits":20}`. Returns `hits`, `logs`, `errors`, `framesRun`, `truncated`. Use it instead of adding `console.log` and re-running. `docs_read {"name":"debugging"}`. |

A person debugs the same scripts with breakpoints and stepping in VS Code (F5; `factoria setup vscode` installs the
extension): [DEBUGGING.md](DEBUGGING.md).

### 11.1 Stateful debugging: `factoria session` and `call --batch`

`factoria call <command> '<json>'` starts a new engine every time, so game state does not carry over between calls. To act on one running game, use one of these two:

- `factoria session` reads one JSON request per line on stdin and writes one JSON answer per line. The game keeps running between lines:

  ```
  printf '%s\n' '{"command":"game.step","args":{"frames":30}}' \
    '{"command":"script.eval","args":{"code":"world.find(\"player\").position"}}' \
    '{"command":"session.quit"}' | factoria session
  ```

- `factoria call --batch '<json array>'` runs the commands in order on one engine and prints `{"ok", "results": [...]}`. It stops at the first failure (add `--keep-going` to continue). Options such as `--scene`, `--press a,b` (actions held before the first command) or `--input replay.json` go after the array:

  ```
  factoria call --batch '[{"command":"game.step","args":{"frames":30}},{"command":"script.eval","args":{"code":"time.elapsed"}}]'
  factoria call --batch '[{"command":"game.state","args":{"entities":["player"]}}]' --press move_right
  ```

Inside `script.eval`, the globals are the `"factoria"` names: `world`, `input`, `time`, `session`, `physics`, `rng` and the rest. `game` there is the game object (`game.paused`, `game.project`, `game.screenSize`), not the test object: `game.world` and `game.time` do not exist in scripts.

### 11.2 Input replays

`factoria run --headless --frames N --input replay.json --state-out state.json --json` drives a headless run from a file. Frames are 0-based. An entry is applied before its frame is simulated. A screenshot listed for frame N is taken after frame N was simulated. Each entry may hold:

- `press` and `release`: action names (held until released) or key names.
- `keys`: raw keys, `{"Space": true}` for down, `false` for up.
- `mouse`: `{"position": [x, y], "left": true, "right": false, "middle": false}` in design pixels.
- `gamepad`: `{"index": 0, "buttons": {"A": true, "DpadLeft": false}, "axes": {"LeftX": -1, "RightTrigger": 0.5}}`, or an array of those for several pads. `index` is 0 to 3 (default 0), `"connected": false` unplugs the pad. Buttons are `A B X Y Start Back Guide DpadLeft DpadRight DpadUp DpadDown LeftShoulder RightShoulder LeftThumb RightThumb`; axes are `LeftX LeftY RightX RightY` (-1..1, +Y up) and `LeftTrigger RightTrigger` (0..1). The state stays until a later frame sets it again, so set an axis back to 0 to release the stick.
- `clipboard`: a string put on the (in-memory) clipboard before the frame; a focused TextField reads it when `keys` presses Ctrl+V.
- `touch`: `{"id": 1, "position": [x, y], "down": true}`, or an array for several fingers. `down` defaults to true: a new `id` begins a finger, a known `id` moves it; `"down": false` lifts it (`position` is not needed then). The first finger also drives the mouse, as on a device.

```json
{
  "frames": {
    "0":  { "press": ["move_right"], "mouse": { "position": [640, 360], "left": true, "right": false, "middle": false } },
    "5":  { "keys": { "Q": true } },
    "6":  { "keys": { "Q": false } },
    "30": { "release": ["move_right"], "mouse": { "position": [640, 360], "left": false } }
  }
}
```

Optional `"timing": [[dt, fixedSteps], ...]` (one pair per frame, from frame 0) makes `factoria run --headless` run frame N with that frame time and that many fixed steps instead of one fixed step. Editor play sessions record it so their replay is exact; frames past its end step normally.

The same format works with `factoria call --input` and `factoria session --input`, which apply it while stepping (they ignore `timing`).

### 11.3 Other checks

- Errors name their location (file and JSON pointer), what is wrong and how to fix it. Unknown component or field names come with a "did you mean" hint. Read the hint first.
- Black or empty screenshot: check for a primary `Camera`, that sprites have a `layer` and a size, that colours are 0..1 (not 0..255), and that world and screen space are not mixed up. A Text or panel in the wrong corner usually has the wrong `anchor` or `pivot` (section 9.4). If the machine has no GPU, the engine runs in logic-only mode and `game_screenshot` says so. Then rely on `game_state` and `game_logs`.
- Body that does not move: check its `type` (static never moves), that it has a collider, its `layer` and `mask`, and the sign of gravity in `settings.gravity2D`.
- A patrol or sensor that turns around on its first step: the first physics step has not run yet (section 9.14).
- Results differ between runs: look for `Math.random`, `Date.now`, or timing. Headless runs are deterministic only when those are absent.
- Tool errors: a tool that throws `ToolError` returns `code` `tool_error`, the `message` and the `hint`. The hint is how to fix the data. Extra `data` appears in the JSON error of `factoria session` and `call --batch`, and as `e.data` on the Error that `fa.call` throws inside a script or test; MCP shows only the code, message and hint, so put the facts a fixer needs in the hint.

## 12. Common mistakes

- Reading raw keys in gameplay. Declare an action in `factoria.json` and read the action.
- Using `Math.random` or `Date.now`. Use `rng` and `dt`.
- Writing colours as 0..255. Use 0..1, or `"#rrggbb"`.
- Expecting +Y to point down in the world. In the world +Y is up. Only screen-space UI has +Y down.
- Treating tilemap row 0 as the bottom row. Row 0 is the top row.
- Forgetting the primary `Camera`.
- Using `pivot: [0, 0]` for top-left screen text. Text pivots are y-up: top-left is `[0, 1]`.
- Expecting Tilemap solid tiles to be one-way. Use a one-way entity for jump-through ledges.
- Copying the map size into camera limit props (`minX`, `maxX`, ...). They go stale when the map changes. Read the rectangle from the Tilemap with `entity.bounds()` (section 9.6).
- Seeding a level generator with `rng.seed(n)`. That reseeds the game's one RNG. Use `rng.create(n)` (section 9.16).
- Placing coins, enemies and spawn points by hand, or writing a script that generates the level. Put them in the legend of `scene.import_ascii` (section 9.8) and re-import after every edit.
- Probing for ground in the first fixed step after a spawn (section 9.14).
- Reading `game.world` or `game.time` in `script.eval`. Use `world` and `time`.
- Editing `types/factoria.d.ts` or `.factoria/`. Both are generated.
- Guessing a component field or command argument. Check `factoria api --md` and `factoria commands`.
- Changing only the running game (`scene_spawn`, `scene_set_component`) and then forgetting that the scene file did not change. Save the scene (`scene_save`) or write it in the file.
- Writing a prefab file by hand to capture something you already built in the running game, or laying out JSON by hand. Save it with `prefab_save` and tidy hand edits with `scene_format` (section 6).
- Skipping THE FEEDBACK RULE because the workaround "works".

## 13. Performance

- Build a level with one `Tilemap` rather than hundreds of sprites. Its solid tiles become a small number of merged colliders.
- Use `burst` with `autoDestroy` for one-shot effects, and set `maxParticles` for continuous ones.
- Look up entities once in `onStart` and keep the references. Calling `world.find` every frame adds up.
- Use `RigidBody2D.bullet: true` only for fast, small bodies.
- 3D physics handles spheres, capsules, convex hulls, static triangle meshes and (oriented) boxes, plus hinge/ball/fixed joints and a character controller. Fast bodies are swept against every solid collider. A `mesh` collider is static only; jointed bodies never sleep. Path finding over 3D ground (around walls, up ramps): a `NavMesh3D` component baked from the static colliders and `nav.findPath(from, to)` in scripts, see [NAVIGATION.md](NAVIGATION.md) (`docs_read {"name":"navigation"}`).
- Keep iteration runs short. 120 frames is 2 seconds of game time.

## 14. Where to read more

- `factoria docs read scripting` (MCP `docs_read {"name":"scripting"}`): the full JavaScript API, tools and tests.
- `factoria api --md` and `factoria commands` (MCP `docs_components` and `docs_commands`): generated references for this build.
- `factoria docs read animation` (MCP `docs_read {"name":"animation"}`): the Animator component (clips, cross-fades, events, state machine) and `tween` / `ease`.
- `factoria docs read extending` (MCP `docs_read {"name":"extending"}`): how to add project tools, native plugins (C/C++ for one game) and engine commands.
- `factoria docs read cli` (MCP `docs_read {"name":"cli"}`): every command and flag.
- `factoria docs read menus` (MCP `docs_read {"name":"menus"}`): a main menu, options, credits, a loading screen
  and a pause menu to copy into a game, and a shop for a game with in-app purchases.
- `factoria docs read platform` (MCP `docs_read {"name":"platform"}`): achievements, stats, leaderboards, cloud saves
  and purchases through one API, the fake store for tests, and how a native plugin becomes a store backend.
- `factoria docs read localization` (MCP `docs_read {"name":"localization"}`): string tables, `key` fields,
  plurals and placeholders, the `i18n` script API, `i18n.state` / `i18n.set_language` / `i18n.export` / `i18n.import`,
  fonts per language, what `factoria validate` checks, and how the start language is chosen.
- `factoria docs read finishing` (MCP `docs_read {"name":"finishing"}`): the ordered path from a playable prototype to a
  game ready for a store: menus, options that persist, versioned saves with migration and a damaged-save screen,
  localization and right-to-left checked at 200 % text, accessibility, store services, credits, tests and a checklist.
- `factoria docs read ai-costs` (MCP `docs_read {"name":"ai-costs"}`): what a whole game cost in tokens and money
  (measured), what drives the cost, the `limits` that cap it and where to see what was spent. Tell the user when a
  task is going to be long or dear.
- The project's `AGENTS.md`: short rules for this game.
