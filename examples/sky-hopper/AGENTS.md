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
| `levels/level1.json`, `level2.json` | ASCII maps of the two hand-made levels: the arguments of `scene.import_ascii`, the source of truth of their tiles, coins, crawlers, player and flag (see Levels below) |
| `levels/generator_base.scene.json` | the part of a level that is not map (settings, camera, `level` script, HUD); `project.generate_level` builds on it |
| `prefabs/*.prefab.json` | reusable entities (`factoria.prefab/1`), spawn with `world.spawnPrefab`; here the things a map spawns: `coin`, `enemy`, `player`, `goal` |
| `scripts/*.js` | behaviours attached to entities via the `Script` component |
| `tools/*.js` | project commands, become `project.<name>` / MCP tool `project_<name>` |
| `tests/*.test.js` | headless tests run by `factoria test` |
| `assets/` | textures, audio, fonts, models (add only what you really need) |
| `types/factoria.d.ts` | script API typings (regenerate: `factoria api --dts`) |
| `ENGINE_FEEDBACK.json` | engine gaps you found (below) |
| `.factoria/` | generated output (screenshots, logs, saves). Git-ignored; never edit. Scratch files: `.factoria/tmp/` |

## Levels (ASCII maps)

Do not edit the tiles or the coins, crawlers, player and flag of `scenes/level1.scene.json` and `level2.scene.json`
by hand, and do not compute their coordinates. Each level is an ASCII map in `levels/<name>.json`: the arguments
of the engine command `scene.import_ascii` (`rows`, `legend`, `tilemap`, `entity`, `anchor`/`position`, `path`).
The command writes the `map` Tilemap and spawns the objects from the prefabs in `prefabs/`, each in the cell of its
character, into the scene FILE named by `path` (it starts from that file, so the camera, `level` script and HUD stay).
To change a level: edit the map, rebuild, `factoria validate`, run and look at it.

```bash
# from this folder; each map names its scene in "path", so no --scene and no scene.load/scene.save
factoria call scene.import_ascii @levels/level1.json
factoria call scene.import_ascii @levels/level2.json
```

`path` makes the command edit the file in a scratch world: the running game (if any) is not touched. Do NOT put
`"save": true` in a map file instead: without `path` the command changes the running scene, and a `factoria call`
without `--scene` runs `scenes/level1.scene.json` (the main scene), so the engine refuses it (`unsafe_save`).

- Legend: `#` grass (tile 0), `%` dirt (1), `=` brick platform (2), `.` empty, `o` coin, `E` crawler, `P` player
  (`id: "player"`), `F` goal flag (`id: "goal"`; its `overrides` set `next`, the scene loaded when it is reached).
  `E` and `F` have a legend `offset` (crawler 4 px down, flag 16 px up) so they stand on the ground.
- Ids are stable: `player`, `goal`, and `coin_N` / `enemy_N` numbered in reading order (row by row, top first). Tests
  and scripts look entities up by these ids. Every spawned object also has the tag `tilemap:map`; rebuilding replaces
  them, so nothing is duplicated.
- The scene keeps everything that is not map: `camera`, the `level` script entity and the `hud`. The camera limits
  (`maxX`, `maxY` in the `camera` Script props) are scene data: set them to the map size in pixels
  (columns * 32, rows * 32) when you resize a map. `tests/platformer.test.js` checks this and that each scene is
  exactly what its map builds, so a hand edit of a scene or a forgotten rebuild fails `factoria test`.
- A new level: copy `levels/generator_base.scene.json` to `scenes/levelN.scene.json`, set `levelIndex` in its
  `level` entity and the camera limits, copy a map to `levels/levelN.json` with `"path": "scenes/levelN.scene.json"`,
  edit it and run the command above for it. Point the previous level's `F` legend `next` at the new scene. (Do not put `"from"` in
  a hand-made level's map file: `from` replaces the scene, so the camera limits you set in it would be lost on every rebuild.)
- `project.generate_level` (`tools/generate_level.js`) makes a random level the same way: it composes `rows` and a
  `legend` from `width`, `seed` and `difficulty`, writes a copy of `levels/generator_base.scene.json` with this level's
  camera limits and level number to `.factoria/tmp/` (the scratch folder), and calls
  `scene.import_ascii {path, from: <that copy>, dryRun}`. The running game is never touched (nothing to save or
  restore), `dryRun` writes nothing. `scenes/generated.scene.json` is
  `factoria call project.generate_level '{"width":90,"seed":7,"difficulty":3}'`. The result lists the `rows`.

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
