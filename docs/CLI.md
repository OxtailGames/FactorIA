# The `factoria` command line

`factoria` is the one binary humans and AIs use: create projects, run and test games headless, expose the engine
over MCP, run the built-in AI agent, manage `ENGINE_FEEDBACK.json`.

- Every command has `--help` with examples. `factoria help [command]` works too.
- Exit codes: `0` ok, `1` failure (the command ran and failed), `2` usage error (bad flag or argument).
- Unknown commands, subcommands, flags, templates, platforms... answer with a "did you mean" suggestion.
- Commands that inform (not just do) take `--json` for machine-readable output. With `--json` a failure is JSON too:
  stdout holds `{"ok": false, "error": {"code", "message", "hint"}}` (`code` is `invalid_argument` for bad arguments,
  exit code 2; `internal` for a bug in factoria; `failed` otherwise, exit code 1), and the same text for people goes to
  stderr.
- Diagnostics and logs go to stderr; stdout carries the result. `--log-level trace|debug|info|warn|error`
  (default `warn`) is accepted by every command.
- A command that needs a project takes it as the optional first argument, or via `--project DIR`; without
  either it uses the project that contains the current directory (the nearest `factoria.json`).

## Paths

A path given to a command-line option follows one of three rules, so `factoria run games/x --headless --input
replays/jump.json` works from any folder:

| Kind | Options | Rule |
|---|---|---|
| Input file | `--input` (`run`, `call`, `session`), `@args.json` and `--batch-file` (`call`) | Absolute: used as it is. Relative: the file in the **current directory** if it exists there, otherwise the one in the **project folder**. When neither is a file, the error lists every location tried (absolute) and suggests a similarly named file; exit code 2. |
| Output file | `--state-out`, `--screenshot-pattern`, `--record-audio` (`run`), `--out` (`screenshot`, `api`) | Relative to the **current directory**, like any shell tool; parent folders are created. The report prints the absolute path written. Defaults live in the project: `<project>/.factoria/screenshots/...`. |
| Project path | `--scene`, and the paths inside command arguments (`scene.load`, `scene.import_ascii` `path`/`from`, `game.screenshot`, `fs.*`) | Relative to the **project folder** (the engine's file system). Not looked up in the current directory. |

Writes made by commands (`scene.save`, `scene.import_ascii` with `path`, `fs.write`, `fs.edit`, `fs.delete`) never go
into `.factoria/` or the version-control folder, except the scratch folder `.factoria/tmp/`, where files can be created
and deleted.

## Projects

### `factoria new <dir> [--template T] [--name NAME] [--id ID] [--force] [--json]`
Creates a project (default template `2d-empty`; also `2d-platformer`, `3d-empty`). Writes `factoria.json`, a scene,
a script, a test, a project tool, `AGENTS.md`/`CLAUDE.md` (the guide for AIs), `ENGINE_FEEDBACK.json`, `.mcp.json`
and the real script typings `types/factoria.d.ts` (generated from the engine's script API, not a placeholder).
```
factoria new my-game
factoria new platformer --template 2d-platformer --name "Pixel Hop" --id com.acme.pixelhop
```

### `factoria templates [--json]`
Lists templates with dimension and description.

### `factoria validate [project] [--json] [--no-scenes] [--fix-types]`
Checks `factoria.json`, every scene/prefab, asset references, `ENGINE_FEEDBACK.json` and the JavaScript syntax of
`scripts/**/*.js` and `tools/*.js`. Messages give file, JSON pointer, the problem and a fix. Exit 1 on any error.
"Every scene/prefab" means every `*.scene.json` and `*.prefab.json` of the project, wherever it lives (`scenes/`,
`prefabs/`, `levels/`...; folders starting with `.`, `node_modules` and a top-level `build/` are skipped, like
`scene.format`). Each is loaded, prefabs on their own too, and what the loader refuses is an error with its JSON pointer:
an unknown field, or a number outside a field's range (`Shape2D.sides` 200 when the range is 3..64: the value is
refused, never clamped, and the message gives the range and the nearest allowed value). A file that is not in the
canonical layout is a warning (fix: `factoria call scene.format`).
`Script.props` keys that do not exist on the behaviour (typos) and a placeholder `types/factoria.d.ts` are reported as
warnings. `--fix-types` regenerates `types/factoria.d.ts` from the engine (same as `factoria api --dts --project .`).

### `factoria export [project] [--platform P] [--format apk|aab|gradle] [--out DIR] [--release] [--player PATH] [--engine-root DIR] [--mobile-dir DIR] [--json]`
Packages the game (linux/windows/macos bundle, Android APK or AAB, iOS project). Without `--platform` the
current machine's platform is used; `--out` is the parent folder (default `<project>/build/export`); the export is written to `<out>/<slug>-<platform>/`,
which is replaced only when it is empty or an earlier export wrote it (it holds `.factoria-export`): any other folder of
that name is an error, never deleted ([EXPORTING.md](EXPORTING.md#replacing-an-earlier-export)).
`--player` selects the `factoria_player` binary to bundle. Android/iOS exports are `prebuilt` (the ready-made `mobile/`
folder next to `factoria`, or `--mobile-dir`) or `source` (`--engine-root`, `$FACTORIA_ENGINE_DIR`, or the checkout a
development build came from); the mode is printed and reported as `mode`, and the rule is in [EXPORTING.md](EXPORTING.md).
Android builds the app itself with the Gradle wrapper it writes into the project: `--format apk` (default), `aab` (the
Google Play bundle) or `gradle` (only the project; no JDK or SDK needed), `--release` for the signed release build; Gradle's
output scrolls on stderr (not with `--json`) and is kept in `build.log` of the export (see [EXPORTING.md](EXPORTING.md#android)).
Prints the output folder, the built file, warnings and the next steps. The command `project.export` (`platform`, `format`,
`out`, `release`, `dryRun`) does the same for MCP clients and `factoria call`, and the editor's Export button for people; see
[EXPORTING.md](EXPORTING.md).

### `factoria editor [project]`
Opens the visual editor (only in builds with the editor). It is AI-first: the viewport, the AI Assistant chat, the Console and View > Audio
are described in `docs/EDITOR.md`. There is no hand-editing UI; the AI Assistant and the Console run engine commands (`scene.spawn`,
`scene.set_component`, `scene.import_ascii`, `audio.log`...), so everything the editor does can also be done with `factoria call`.

### `factoria setup [android|players|cmake|xcode] [--accept-licenses] [--platforms LIST] [--force] [--json]`
Checks this computer for exporting and installs what is missing into `~/.factoria` (`$FACTORIA_HOME`), so nobody has to install
a JDK or an SDK by hand. `factoria setup` alone prints what each component has (nothing is written or downloaded, except the
Android license text with `--json`) and says which `factoria setup <component>` to run. `android` installs Eclipse Temurin
JDK 21, the Android command-line tools (revision 22.0, the classic Java `sdkmanager`), platform-tools, platform 36 and
build-tools 35.0.0, and saves their folders in `~/.factoria/export.json`; it shows the Android SDK license and asks `[y/N]`
in a terminal, and without one refuses until `--accept-licenses` says you have read and accepted it. `players` downloads the
`factoria_player` of the other desktop OSes and the Android/iOS libraries from the GitHub release of this version
(`--platforms windows,linux,macos,mobile` narrows it).
`cmake` installs CMake 3.31 for the iOS export unless a 3.24+ is found. `xcode` (macOS) checks Xcode, opens its App Store page
when missing and lists what you do next (it never runs `sudo`). `--force` installs again even when something is found.
Progress goes to stderr; `--json` prints the report (status: components with `state`, `problems`, `licenses`). Every download is
checked against its publisher's checksum. Details, what is trusted and the commands for AIs (`setup.status`, `setup.install`):
[EXPORTING.md](EXPORTING.md#setting-up-this-computer).
```
factoria setup
factoria setup android
factoria setup android --accept-licenses
factoria setup players --platforms windows,linux
```

## Running

### `factoria run [project] [options]`
Windowed by default (hot reload on). With `--headless` it runs deterministically without a window and prints a report.

| Option | Meaning |
|---|---|
| `--scene S`, `--width W`, `--height H` | Start scene / resolution override |
| `--headless` | No window; every frame is exactly `1/fixedHz` s |
| `--frames N` | Frames to simulate (default 60) |
| `--input replay.json` | Input replay (current directory first, then the project; see Paths): `{"frames": {"0": {"press": ["jump"]}, "30": {"release": ["jump"]}}}`; entries also take `keys`, `mouse`, `gamepad` and `touch` (see `docs/AI_GUIDE.md` 11.2) |
| `--screenshot-at 10,60` | Frames to capture as PNG |
| `--screenshot-pattern P` | PNG path containing `{frame}`, relative to the current directory (default `<project>/.factoria/screenshots/frame_{frame}.png`) |
| `--state-out f.json` | Final world state dump (relative to the current directory) |
| `--record-audio f.wav` | Record the audio mix (relative to the current directory) |
| `--seed N` | World RNG seed |
| `--allow-script-errors` | Exit 0 even if scripts raised errors |
| `--render-all` | Draw every frame (default headless: simulate every frame, draw only screenshot frames and the last frame; screenshots are pixel-identical either way) |
| `--persist-storage` | Let scripts' `storage.*` use the real save file (default headless: in memory, so runs do not leak state) |
| `--json` | Print the report as JSON (lists the PNG paths) |

```
factoria run
factoria run --headless --frames 120 --screenshot-at 10,60 --json
```
Report (JSON): `{ok, exitCode, frames, screenshots:[paths], scriptErrors:[...], sceneErrors:[...], stateOut?, audioOut?}`.
Same seed + same input = same state and pixels.

### `factoria screenshot [project] [--frames N] [--out shot.png] [--json]`
Runs `N` frames (default 30) headless and saves a PNG (default `<project>/.factoria/screenshots/shot.png`).

### `factoria test [project] [--filter TEXT] [--render-all] [--persist-storage] [--json]`
Runs `tests/**/*.test.js` on a headless engine; prints one line per test, failure messages with expected/actual and
the totals. Exit 1 if a test fails or a test file does not load. Tests simulate every frame but only draw when a
screenshot is taken (`--render-all` draws every frame; much slower with software rendering), `storage.*` is in memory,
and the same commands as `factoria call` (including `fs.*`) are available to scripts via `fa.call(name, args)`.
`console.log/warn/error` output of test files and behaviours is shown by default, indented under the test as
`| text` (also with `--log-level warn`); engine info logs stay hidden. With `--json` it is `logs` per case (and a
top-level `logs` for output outside tests).

## Commands (the tool surface of MCP and the AI agent)

### `factoria call <command> ['<json args>'] [options]` / `factoria call --batch '<json array>'`
Runs registered commands on a headless engine and prints the JSON result. Arguments: inline JSON, `@file.json`, or
`-` (stdin). Failures print `error: code: message`, the hint and, when the command returned structured `data`
(e.g. a project tool's `ToolError`), `data: {...}` on stderr, exit 1; `--json` also prints
`{"ok":false,"error":{code,message,hint,data}}` on stdout. Outside a project a scratch
project is used, so `docs.*` and `project.create` work anywhere. Options: `--project DIR`, `--scene S` (start scene),
`--seed N`, `--press a,b` (hold actions/keys before the command), `--input replay.json` (input replay applied while
stepping; steps through its last frame unless `--frames-before N` is given), `--frames-before N`, `--no-graphics`,
`--render-all`, `--persist-storage`.

**Every `call` starts a new engine**, so `game.step` in one call is not seen by `script.eval` in the next. To run
several commands against the SAME game use `--batch` (or `--batch-file F.json`, `-` = stdin): an array of
`{"command": "...", "args": {...}}` executed in order on one engine. It prints
`{"ok": bool, "results": [{"ok": true, "result": ...} | {"ok": false, "error": {code, message, hint, data?}}]}`, stops at
the first failure (`--keep-going` continues) and exits 1 if any command failed.
```
factoria call scene.list_entities
factoria call scene.spawn '{"name":"Enemy","components":{"Transform":{"position":[100,50,0]}}}'
factoria call scene.import_ascii @level1.json   # ASCII rows + legend -> Tilemap + coins/enemies; "path": "scenes/level1.scene.json" writes that scene FILE and leaves the running game alone
factoria call prefab.save '{"id":"boss","path":"prefabs/boss.prefab.json"}'   # an entity of the start scene (or one spawned earlier in a --batch) -> prefab file
factoria call scene.format '{"check":true}'     # list scene/prefab files not in the canonical layout; without "check" it rewrites them
factoria call scene.format '{"check":true,"strict":true}'   # same, but exits non-zero when any file is not canonical (CI)
factoria call game.screenshot '{"path":"/tmp/s.png"}' --frames-before 60
factoria call game.state --scene scenes/level2.scene.json --press move_right --frames-before 30
factoria call --batch '[{"command":"game.step","args":{"frames":30}},{"command":"script.eval","args":{"code":"time.elapsed"}}]'
```
Commands that create or patch entities (`scene.spawn`, `scene.set_component`) fail (exit 1, with a "did you mean"
hint) on unknown component or field names instead of creating a half-built entity.
`scene.set_component` also refuses a number outside the field's range, naming the range. Its `merge` argument reads `fields` as a
JSON merge-patch (RFC 7386) so that `Script.props` can be changed key by key: `factoria call scene.set_component
'{"id":"level","component":"Script","merge":true,"fields":{"props":{"levelIndex":3}}}'` keeps every other prop
(`null` deletes a key). `scene.import_ascii`'s `edits` do the same per edit with `"$merge": true`.
`physics.raycast` takes `mask`, `ignore` and `ignoreTriggers` like `physics.shape_cast`.

### `factoria session [project] [options]`
A JSON-lines loop on ONE engine for AIs without MCP: read one request per stdin line, write one JSON answer per stdout
line. State persists between lines. Same options as `call` (`--scene`, `--press`, `--input`, `--frames-before`, ...).
```
$ factoria session
{"ready":true,"project":"/work/game","graphics":true,"frame":0,"commands":46}
> {"command":"game.step","args":{"frames":30}}
{"ok":true,"result":{"frame":30,"time":0.5,"scene":"scenes/main.scene.json",...}}
> {"command":"script.eval","args":{"code":"world.findByTag('player')[0].position"}}
{"ok":true,"result":{"value":[0,0,0]}}
> {"command":"nope"}
{"ok":false,"error":{"code":"unknown_command","message":"Unknown command 'nope'","hint":"Valid: ..."}}
```
A line may also be an array of requests (answered with an array of results). `{"command":"session.quit"}` or EOF
ends the session. Logs go to stderr, so stdout is pure JSON lines.

### `factoria commands [prefix-or-name] [--project DIR] [--json]`
Lists commands by category (`*` = modifies state). With an exact name it prints the description and argument schema.

### `factoria api [--md|--json|--dts|--schema scene|prefab|project] [--out FILE] [--project DIR]`
Prints the API reference: components, commands, scripting. `--dts` writes the TypeScript declarations; with
`--project` and no `--out` it writes `<project>/types/factoria.d.ts`. `--schema` prints a JSON Schema.

## MCP

### `factoria mcp [--project DIR] [--scene S] [--no-graphics] [--no-hot-reload]`
Model Context Protocol server on stdio (details: [MCP.md](MCP.md)). Creates a headless engine for the project
(GPU if available, otherwise logic-only: `game_screenshot` then reports why), registers the engine, tooling,
project (`project.create`, `project.templates`, `project.test`) and `ai.*` commands, and serves them. `mcp`, `call`,
`session`, `test` and the editor all register the same command set (`fa::register_project_commands`), so `fs.*`,
`docs.*`, `feedback.*` and `project.validate` work everywhere, including inside tests. Frames are simulated but only
drawn when `game_screenshot` asks (`--render-all` draws every frame); `storage.*` is in memory (`--persist-storage`). Scripts
and `tools/*.js` are watched; clients receive `notifications/tools/list_changed` when the tool set changes.
stdout carries protocol messages only. Without a project it starts with documentation and project-creation
tools so an AI can bootstrap one.
```
claude mcp add factoria -- factoria mcp --project .
```

## AI agent

Providers and roles are configured in `~/.factoria/ai.json` ([AI_PROVIDERS.md](AI_PROVIDERS.md)); keys are never printed.

| Command | Purpose |
|---|---|
| `factoria ai doctor [--json]` | Which CLIs/keys are usable right now |
| `factoria ai providers [--json]` | Providers and the role mapping |
| `factoria ai config [--json]` | Config path, effective settings (redacted), example file |
| `factoria ai run [project] "<task>" [--provider P] [--role orchestrator\|worker\|fast] [--model M] [--max-turns N] [--max-cost USD] [--no-delegate] [--json]` | Run a task; streams text, tool calls and cost |

`ai run` gives the agent the project's command registry as tools (the `ai.*` commands are hidden from it). Use `-`
as the task to read stdin, `@file` to read it from a file. The transcript is saved in `<project>/.factoria/ai/sessions/`.
Command results containing `"$image": {"path"|"base64", "mimeType"}` are sent to the model as images.

## Feedback and docs

### `factoria feedback init|add|list|update|validate|collect`
```
factoria feedback add --category physics --severity major --title "No one-way platforms" \
    --missing "Collider2D has no one-way option" --workaround "scripts/one_way.js" --files scripts/one_way.js
factoria feedback add --json '{"category":"docs","severity":"minor","title":"...","missing":"...","workaround":"..."}'
factoria feedback list --status open
factoria feedback update games/my-game FB-001 --status fixed-in-engine --engine-issue abc123 [--note TEXT] [--json]
factoria feedback validate
factoria feedback collect games/ examples/ --out roadmap.md      # .json => JSON; --include-closed
```
`add` merges into a similar open entry (occurrences++). `update [project] <id>` triages an entry: `--status open|fixed-in-engine|wont-fix|duplicate`, `--engine-issue REF`, `--note TEXT` (appended to `notes`). `collect` groups reports of the same gap across projects even
when the titles differ ("Bug:" prefixes, plurals, stop words and synonyms such as stub/placeholder are ignored; a
short title contained in a longer one counts; same-category or similar-suggestion entries score higher, and a
cluster may span categories). See [ENGINE_FEEDBACK.md](ENGINE_FEEDBACK.md).

### `factoria docs [name] | list | read <name> | search <query...>`
The docs embedded in the binary (offline). `factoria docs scripting` prints SCRIPTING.md. Two are generated:
`components` (the component reference) and `licenses` (FactorIA's MIT license and every third-party license inside
the binaries; the downloads ship it as `THIRD_PARTY_NOTICES.txt`).

### `factoria version` / `--version`, `factoria help [command]`

## Embedding

`fa::cli::cli_main(args, out, err, in)` (`tools/cli/include/fa/cli/cli.h`) runs the whole CLI in-process; the unit
tests and the editor use it.
