# Sky Hopper — guide for AI agents

This is a **FactorIA** game project (engine 0.1.0, created 2026-10-13). You build the
game by editing JSON and JavaScript, then checking the result with the engine tools. Everything
is text; you never need a GUI.

## The loop (follow it for every change)

1. **Read** what exists: `factoria docs list`, then `factoria docs read ai-guide` / `scripting` /
   `components`. (With MCP: tools `docs_list`, `docs_read`, `docs_search`.) Read before guessing
   component or API names.
2. **Edit** scenes (`scenes/*.scene.json`), prefabs, `scripts/*.js`, `tools/*.js`, `factoria.json`.
3. **Validate**: `factoria validate` (MCP: `project_validate`). Fix every error; each one has a
   file, a JSON pointer and a hint.
4. **Run and LOOK**: `factoria run --headless --frames 120 --screenshot-at 119` (MCP: `game_step`,
   then `game_screenshot`). Open the PNG and check it really shows what you intended. Do not
   assume the scene is right because validation passed.
5. **Test**: `factoria test` (MCP: `project_test`). Add or update a test in `tests/` for every
   behaviour you add; a bug fix starts with a failing test.
6. **Report engine gaps** (see below) the moment you hit one, not at the end.

Small steps: change one thing, validate, run, look. Commit-sized increments.

## Where things live

| Path | What |
|---|---|
| `factoria.json` | project settings: name, display size, main scene, physics, input actions |
| `scenes/*.scene.json` | levels: entities with components (format `factoria.scene/1`) |
| `prefabs/*.prefab.json` | reusable entities (`factoria.prefab/1`), spawn with `world.spawnPrefab` |
| `scripts/*.js` | behaviours attached to entities via the `Script` component |
| `tools/*.js` | project commands, become `project.<name>` / MCP tool `project_<name>` |
| `tests/*.test.js` | headless tests run by `factoria test` |
| `assets/` | textures, audio, fonts, models (add only what you really need) |
| `types/factoria.d.ts` | script API typings (regenerate: `factoria api --dts`) |
| `ENGINE_FEEDBACK.json` | engine gaps you found (below) |
| `.factoria/` | generated output (screenshots, logs, saves). Git-ignored; never edit |

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
- Game logic belongs in `scripts/` classes extending `Behaviour` (`onStart`, `onUpdate(dt)`,
  `onFixedUpdate`, `onCollisionEnter`, `onTriggerEnter`...). Tunable numbers are class fields
  that scenes can override via `"Script": {"path": ..., "props": {...}}`.
- Determinism: use `rng` from `"factoria"` (never `Math.random`) and `time.dt` / the `dt`
  argument (never `Date.now`). Tests and replays depend on it.
- Paths are project-relative with forward slashes (`assets/hero.png`).
- Never put API keys or secrets in this project. Keys live in `~/.factoria/ai.json` or env vars.
- Do not edit generated files (`.factoria/`, `types/factoria.d.ts`).

## Debugging

- `factoria validate` first: it loads every scene and checks assets, input bindings, scripts.
- `factoria run --headless --frames N --state-out out.json` dumps entities and components; MCP
  `game_state` / `scene_list_entities` give the same live. `game_logs` shows script errors.
- Compare screenshots before/after a change. If the picture is black, check there is a
  primary `Camera`, that sprites have a `layer` and size, and that the colors are not 0..255.
- To poke at runtime: `factoria call <command> '<json>'` (all commands: `factoria commands`).

## Recording engine gaps (IMPORTANT)

FactorIA improves from what game-making AIs report. **Whenever the engine lacked a feature or
had a bug and you built a workaround or dropped the feature, record it immediately**:

- MCP tool `feedback_report` / CLI `factoria call feedback.report '{...}'`, or append to
  `ENGINE_FEEDBACK.json` by hand (schema `schemas/engine-feedback.schema.json`).
- Fields: `category`, `severity` (`blocker` | `major` | `minor` | `nice-to-have`), `title` (short
  noun phrase, reuse wording for the same gap), `missing` (what and why you needed it),
  `workaround` (what you did, with `workaroundFiles`), `suggestion` (how the engine could fix it).
- Reporting the same gap again merges into the existing entry (counts occurrences), so do not
  worry about duplicates. Not reporting is the only wrong choice.
- Examples worth reporting: a component field you expected is missing; an error message did not
  say how to fix the problem; a doc was wrong or absent; a command you wanted does not exist; a
  crash; slow or flaky headless runs; anything you had to emulate in JS.

## Definition of done for a task

`factoria validate` is clean, a screenshot shows the intended result, `factoria test` passes with
a test covering the new behaviour, and every engine gap you met is in `ENGINE_FEEDBACK.json`.
