# {{PROJECT_NAME}} — guide for AI agents

This is a **FactorIA** game project (engine {{ENGINE_VERSION}}, created {{DATE}}). You build the
game by editing JSON and JavaScript, then checking the result with the engine tools. Everything
is text; you never need a GUI. The full guide is `factoria docs read ai-guide` (MCP: `docs_read {"name":"ai-guide"}`).

## The loop (follow it for every change)

1. **Read** what exists: `factoria docs read ai-guide` (once per task), then `scripting` and
   `components`. (With MCP: tools `docs_list`, `docs_read`, `docs_search`. A long page comes in parts with its
   `contents`: read a section with `docs_read {"name":"ai-guide","heading":"..."}`; `docs_components {"name":"Sprite"}`
   gives one component in full.) Read before guessing component or API names.
2. **Edit** scenes (`scenes/*.scene.json`), prefabs, `scripts/*.js`, `tools/*.js`, `factoria.json`.
3. **Validate**: `factoria validate` (MCP: `project_validate`). Fix every error; each one has a
   file, a JSON pointer and a hint. After the engine API changes, `factoria validate --fix-types`
   regenerates `types/factoria.d.ts`.
4. **Run and LOOK**: `factoria run --headless --frames 120 --screenshot-at 119 --json` (MCP: `game_step`,
   then `game_screenshot`). Open the PNG and check it really shows what you intended. Do not
   assume the scene is right because validation passed.
5. **Test**: `factoria test` (MCP: `project_test`). Add or update a test in `tests/` for every
   behaviour you add; a bug fix starts with a failing test.
6. **Report engine gaps** (see below) the moment you hit one, not at the end.

Small steps: change one thing, validate, run, look. Commit-sized increments.

When the user says they played the game (in the editor) and found problems (slow, ugly UI, bugs),
call `play.report` (MCP: `play_report`) first: it has the frame times, errors, the user's notes and
screenshots, and an input replay of their session (`factoria run --headless --input <replay>`).

## Where things live

| Path | What |
|---|---|
| `factoria.json` | project settings: name, display size, main scene, physics, input actions |
| `scenes/*.scene.json` | levels: entities with components (format `factoria.scene/1`) |
| `prefabs/*.prefab.json` | reusable entities (`factoria.prefab/1`), spawn with `world.spawnPrefab` |
| `scripts/*.js` | behaviours attached to entities via the `Script` component |
| `tools/*.js` | project commands, become `project.<name>` / MCP tool `project_<name>` |
| `plugins/<name>/` | native plugins (C/C++: SDKs, platform services), `plugins.<name>.<fn>()` in scripts (optional: `project.new_plugin`, docs: extending, section G) |
| `tests/*.test.js` | headless tests run by `factoria test` |
| `levels/*.json` | ASCII level maps, the arguments of `scene.import_ascii`; the source of truth of a tile level (optional, skill `tile-levels`) |
| `data/*.json` | tuning data, imported with `import levels from "../data/levels.json";` (optional) |
| `assets/` | textures, audio, fonts, models (add only what you really need) |
| `types/factoria.d.ts` | script API typings (generated: `factoria validate --fix-types`) |
| `REVIEW.md` | the note the art critics and game reviewers read first (never exported, skill `review-ready`) |
| `skills/<name>/SKILL.md` | this game's own topic guides (optional, see Skills below) |
| `ENGINE_FEEDBACK.json` | engine gaps you found (below) |
| `.factoria/` | generated output (screenshots, logs, saves). Git-ignored; never edit. Scratch files: `.factoria/tmp/` |

## Conventions

- JSON keys are `camelCase`. Component names are PascalCase (`Sprite`, `RigidBody2D`).
  Run `factoria api --md` for every component and field; unknown names are errors with
  "did you mean" suggestions.
- Entities have a stable string `id` (`"player"`, `"coin_3"`) and optional `name`, `tags`.
  Entity references in components use these ids. Always give gameplay entities an `id`.
- Units: **+Y is up**, right-handed. Angles in degrees. Colors are `[r, g, b, a]` in 0..1 (or
  `"#rrggbb"`). 2D world units are design pixels, origin at the screen centre; screen-space UI
  (`"space": "screen"`) has origin top-left and +Y down. 3D units are meters.
- Read input through **actions** (`input.pressed("jump")`) declared in `factoria.json`
  `input.actions`, not raw keys. Add an action there before using it.
- Prefer built-in `Shape2D` / primitive meshes (`"mesh": "cube"`) until real art is needed, so
  the game runs with no binary assets.
- Game logic belongs in `scripts/` classes extending `Behaviour` (`onStart`, `onEnable`/`onDisable`, `onUpdate(dt)`,
  `onFixedUpdate`, `onCollisionEnter`, `onTriggerEnter`...). Tunable numbers are class fields
  that scenes can override via `"Script": {"path": ..., "props": {...}}`.
- Determinism: use `rng` from `"factoria"` (never `Math.random`) and `time.dt` / the `dt`
  argument (never `Date.now`). Tests and replays depend on it. A tool or generator that must repeat from a seed uses
  its own `rng.create(seed)` (same methods as `rng`, never touches the game's RNG), not `rng.seed`. Guide section 9.16.
- Paths are project-relative with forward slashes (`assets/hero.png`).
- Never put API keys or secrets in this project. Keys live in `~/.factoria/ai.json` or env vars.
- Do not edit generated files (`.factoria/`, `types/factoria.d.ts`).

## Engine features you can rely on

- **HUD in the corners:** `"space": "screen"` with `anchor` ([0,0] top-left, [1,1] bottom-right) and `pivot`
  (Text default [0,1]). Guide section 9.4.
- **Prefab files and tidy JSON:** `prefab.save` (MCP `prefab_save`) saves an entity you built in the running game, with its
  children, as `prefabs/<name>.prefab.json` (it leaves out ids, the root position and `tilemap:` tags; it never overwrites
  without `"overwrite": true`). `scene.format` (MCP `scene_format`; `{"paths": [...]}` names the files, `{"check": true}` only lists; with neither it changes nothing and says so) puts hand-edited scenes and
  prefabs in the canonical layout. Guide section 6. Do not lay out prefab JSON by hand.
- **Sensing:** `entity.isGrounded()`, `entity.isTouching([dx, dy])`, `physics.raycast(a, b, {ignore: this.entity})`.
  Skip the first two fixed steps before probing (bodies are created by the first physics step).
- **Spawning:** `world.spawn(json, {position, parent, props})` and `world.spawnPrefab(path, {position, props, overrides})`;
  `parent` is an Entity or an id, and `position` is then local to it.
- **Cross-scene state:** `session` is a plain object that survives `scene.load`. `storage` is for save files.
- **Failing a check:** `throw new ToolError(message, hint, data?)`. For a list of every problem, return it as a
  normal result with `ok: false`.
- **Vectors:** `vec2(...)`, `[x, y]` and `{x, y}` are accepted wherever a vector is expected.
- **Replays:** `factoria run --headless --input replay.json` with `press`, `release`, `keys` and `mouse` entries.

## Debugging

- `factoria validate` first: it loads every scene and checks assets, input bindings, scripts.
- A screenshot that looks wrong: take it again with `game_screenshot {"region":[x,y,w,h],"zoom":8}` or a filmstrip (skill `inspect-the-picture`).
  If it is black, check there is a primary `Camera`, that sprites have a `layer` and size, and that the colors are not 0..255.
- `factoria run --headless --frames N --state-out out.json` dumps entities and components; MCP
  `game_state` / `scene_list_entities` give the same live. `game_logs` shows script errors.
- To click in the running game (MCP `game_click`, CLI `factoria call game.click`): `{"id":"play"}` clicks the centre of a UI
  widget, `{"position":[640,360]}` a screen point in design pixels, `{"world":[3,-2]}` a world point. It moves the mouse, presses, steps
  one frame, releases and steps one more, so scripts see `input.mouse.pressed` and then `released` and Buttons get their `click`.
  `game_input {"mouse":{"position":[x,y],"left":true}}` + `game_step` presses too, but the button stays held until you set `left:false`.
- To act on a running game, use `factoria session`: one JSON request per stdin line, one JSON answer per
  stdout line, and the game keeps its state. For example
  `printf '%s\n' '{"command":"game.step","args":{"frames":30}}' '{"command":"script.eval","args":{"code":"world.find(\"player\").position"}}' | factoria session`.
- `factoria call --batch '[{"command":"game.step","args":{"frames":30}},{"command":"script.eval","args":{"code":"..."}}]'`
  runs several commands on one engine; add `--press a,b` or `--input replay.json` after the array to set the start.
  A plain `factoria call <command> '<json>'` starts a NEW engine each time. All commands: `factoria commands`.
- To see inside a script without adding `console.log`, use `script.trace` (MCP: `script_trace`): it runs the
  project headless and records the stack, locals and watch expressions each time given lines run, e.g.
  `factoria call script.trace '{"points":[{"file":"scripts/player.js","line":17,"watch":["this.body.velocity","dt"]}],"frames":300,"maxHits":20}'`.
  A person debugs the same scripts with breakpoints in VS Code (F5; `factoria setup vscode`). Read `factoria docs read debugging`.
- Headless runs and tests simulate every frame but draw only for screenshots (fast); `--render-all` draws all.

## Skills (topic guides)

Longer guides are skills (the Agent Skills format: `skills/<name>/SKILL.md`), read only when the task needs one. List them with
`skills_list` (CLI `factoria call skills.list`) and read one with `skills_read {"name":"..."}` (CLI `factoria call skills.read
'{"name":"custom-shaders"}'`; a skill's other files with `"file"`). The engine's own: `custom-shaders`, `glow-and-effects`,
`tile-levels`, `physics-3d`, `web-requests`, `menus-and-finishing`, `publishing-and-exporting`, `inspect-the-picture`,
`make-art`, `make-audio` and `review-ready` (keep `REVIEW.md` current so the art critics and game reviewers can play the build:
read it before you finish a feature). This project can have its own in `skills/` (`skills_new`; `factoria validate` checks them).

## Recording engine gaps (IMPORTANT)

FactorIA improves from what game-making AIs report. **Whenever the engine lacked a feature or
had a bug and you built a workaround or dropped the feature, record it immediately**:

- MCP tool `feedback_report`, CLI `factoria feedback add ...` or `factoria call feedback.report '{...}'`,
  or append an object to the `entries` array of `ENGINE_FEEDBACK.json` by hand (schema `schemas/engine-feedback.schema.json`).
- Fields: `category`, `severity` (`blocker` | `major` | `minor` | `nice-to-have`), `title` (short
  noun phrase, reuse wording for the same gap), `missing` (what and why you needed it),
  `workaround` (what you did, with `workaroundFiles`), `suggestion` (how the engine could fix it).
- Reporting the same gap again merges into the existing entry (counts occurrences), so do not
  worry about duplicates. Not reporting is the only wrong choice.
- `ENGINE_FEEDBACK.json` holds the open entries; closed ones move to `ENGINE_FEEDBACK.archive.json` (never edit it); reporting a fixed gap again reopens it.
- `share` (optional): the gap for the engine developer, written in engine terms only (component, field and command names;
  `{title, missing, suggestion?}`, nothing about this game). Then run `ai.review_feedback {id}`: a cheap model checks it and sets `reviewed: true`
  (it sends nothing). Only the user turns sending on (editor dialog, or `factoria feedback sharing always|ask|never`); if the report says it is not set up, tell them once.
- Examples worth reporting: a component field you expected is missing; an error message did not
  say how to fix the problem; a doc was wrong or absent; a command you wanted does not exist; a
  crash; slow or flaky headless runs; anything you had to emulate in JS.

## Definition of done for a task

`factoria validate` is clean, a screenshot shows the intended result, `factoria test` passes with
a test covering the new behaviour, and every engine gap you met is in `ENGINE_FEEDBACK.json`.
