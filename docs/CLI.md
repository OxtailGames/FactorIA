# The `factoria` command line

`factoria` is the one binary humans and AIs use: create projects, run and test games headless, expose the engine
over MCP, run the built-in AI agent, manage `ENGINE_FEEDBACK.json`.

- Every command has `--help` with examples. `factoria help [command]` works too.
- Exit codes: `0` ok, `1` failure (the command ran and failed), `2` usage error (bad flag or argument).
- Unknown commands, subcommands, flags, templates, platforms... answer with a "did you mean" suggestion.
- Commands that inform (not just do) take `--json` for machine-readable output.
- Diagnostics and logs go to stderr; stdout carries the result. `--log-level trace|debug|info|warn|error`
  (default `warn`) is accepted by every command.
- A command that needs a project takes it as the optional first argument, or via `--project DIR`; without
  either it uses the project that contains the current directory (the nearest `factoria.json`).

## Projects

### `factoria new <dir> [--template T] [--name NAME] [--id ID] [--force] [--json]`
Creates a project (default template `2d-empty`; also `2d-platformer`, `3d-empty`). Writes `factoria.json`, a scene,
a script, a test, a project tool, `AGENTS.md`/`CLAUDE.md` (the guide for AIs), `ENGINE_FEEDBACK.json`, `.mcp.json`.
```
factoria new my-game
factoria new platformer --template 2d-platformer --name "Pixel Hop" --id com.acme.pixelhop
```

### `factoria templates [--json]`
Lists templates with dimension and description.

### `factoria validate [project] [--json] [--no-scenes]`
Checks `factoria.json`, every scene/prefab, asset references, `ENGINE_FEEDBACK.json` and the JavaScript syntax of
`scripts/**/*.js` and `tools/*.js`. Messages give file, JSON pointer, the problem and a fix. Exit 1 on any error.

### `factoria export [project] [--platform P] [--out DIR] [--release] [--player PATH] [--json]`
Packages the game (linux/windows/macos bundle, Android Gradle project, iOS project). Without `--platform` the
current machine's platform is used; `--player` selects the `factoria_player` binary to bundle. Prints the output
folder and the next steps.

### `factoria editor [project]`
Opens the visual editor (only in builds with the editor).

## Running

### `factoria run [project] [options]`
Windowed by default (hot reload on). With `--headless` it runs deterministically without a window and prints a report.

| Option | Meaning |
|---|---|
| `--scene S`, `--width W`, `--height H` | Start scene / resolution override |
| `--headless` | No window; every frame is exactly `1/fixedHz` s |
| `--frames N` | Frames to simulate (default 60) |
| `--input replay.json` | Input replay: `{"frames": {"0": {"press": ["jump"]}, "30": {"release": ["jump"]}}}` |
| `--screenshot-at 10,60` | Frames to capture as PNG |
| `--screenshot-pattern P` | PNG path containing `{frame}` (default `<project>/.factoria/screenshots/frame_{frame}.png`) |
| `--state-out f.json` | Final world state dump |
| `--record-audio f.wav` | Record the audio mix |
| `--seed N` | World RNG seed |
| `--allow-script-errors` | Exit 0 even if scripts raised errors |
| `--json` | Print the report as JSON (lists the PNG paths) |

```
factoria run
factoria run --headless --frames 120 --screenshot-at 10,60 --json
```
Report (JSON): `{ok, exitCode, frames, screenshots:[paths], scriptErrors:[...], sceneErrors:[...], stateOut?, audioOut?}`.
Same seed + same input = same state and pixels.

### `factoria screenshot [project] [--frames N] [--out shot.png] [--json]`
Runs `N` frames (default 30) headless and saves a PNG (default `<project>/.factoria/screenshots/shot.png`).

### `factoria test [project] [--filter TEXT] [--json]`
Runs `tests/**/*.test.js` on a headless engine; prints one line per test and failure messages with expected/actual.
Exit 1 if a test fails or a test file does not load.

## Commands (the tool surface of MCP and the AI agent)

### `factoria call <command> ['<json args>'] [--project DIR] [--frames-before N] [--scene S] [--seed N]`
Runs any registered command on a headless engine and prints its JSON result. Arguments: inline JSON, `@file.json`,
or `-` (stdin). Failures print `error: code: message` and the hint on stderr, exit 1. Outside a project a scratch
project is used, so `docs.*` and `project.create` work anywhere.
```
factoria call scene.list_entities
factoria call scene.spawn '{"name":"Enemy","components":{"Transform2D":{"position":[100,50]}}}'
factoria call game.screenshot '{"path":"/tmp/s.png"}' --frames-before 60
```

### `factoria commands [prefix-or-name] [--project DIR] [--json]`
Lists commands by category (`*` = modifies state). With an exact name it prints the description and argument schema.

### `factoria api [--md|--json|--dts|--schema scene|prefab|project] [--out FILE] [--project DIR]`
Prints the API reference: components, commands, scripting. `--dts` writes the TypeScript declarations; with
`--project` and no `--out` it writes `<project>/types/factoria.d.ts`. `--schema` prints a JSON Schema.

## MCP

### `factoria mcp [--project DIR] [--scene S] [--no-graphics] [--no-hot-reload]`
Model Context Protocol server on stdio (details: [MCP.md](MCP.md)). Creates a headless engine for the project
(GPU if available, otherwise logic-only: `game_screenshot` then reports why), registers the engine, tooling,
project (`project.create`, `project.templates`, `project.test`) and `ai.*` commands, and serves them. Scripts
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

### `factoria feedback init|add|list|validate|collect`
```
factoria feedback add --category physics --severity major --title "No one-way platforms" \
    --missing "Collider2D has no one-way option" --workaround "scripts/one_way.js" --files scripts/one_way.js
factoria feedback add --json '{"category":"docs","severity":"minor","title":"...","missing":"...","workaround":"..."}'
factoria feedback list --status open
factoria feedback validate
factoria feedback collect games/ examples/ --out roadmap.md      # .json => JSON; --include-closed
```
`add` merges into a similar open entry (occurrences++). See [ENGINE_FEEDBACK.md](ENGINE_FEEDBACK.md).

### `factoria docs [name] | list | read <name> | search <query...>`
The docs embedded in the binary (offline). `factoria docs scripting` prints SCRIPTING.md.

### `factoria version` / `--version`, `factoria help [command]`

## Embedding

`fa::cli::cli_main(args, out, err, in)` (`tools/cli/include/fa/cli/cli.h`) runs the whole CLI in-process; the unit
tests and the editor use it.
