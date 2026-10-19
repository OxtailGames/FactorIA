# {{PROJECT_NAME}} — guide for AI agents

This is a **FactorIA** game project (engine {{ENGINE_VERSION}}, created {{DATE}}). You build the
game by editing JSON and JavaScript, then checking the result with the engine tools. Everything
is text; you never need a GUI. The full guide is `factoria docs read ai-guide` (MCP: `docs_read {"name":"ai-guide"}`).

## The loop (follow it for every change)

1. **Read** what exists: `factoria docs read ai-guide` (once per task), then `scripting` and
   `components`. (With MCP: tools `docs_list`, `docs_read`, `docs_search`.) Read before guessing
   component or API names.
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
| `levels/*.json` | ASCII level maps, the arguments of `scene.import_ascii`; the source of truth of a tile level (optional, see Tile levels below) |
| `data/*.json` | tuning data, imported with `import levels from "../data/levels.json";` (optional) |
| `assets/` | textures, audio, fonts, models (add only what you really need) |
| `types/factoria.d.ts` | script API typings (generated: `factoria validate --fix-types`) |
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
- Game logic belongs in `scripts/` classes extending `Behaviour` (`onStart`, `onUpdate(dt)`,
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
- **One-shot effects:** a `ParticleEmitter` with `emitting: false`, `burst: 24`, `autoDestroy: true` and
  `blend: "additive"` fires once and removes itself. `particles.burst(entity, n)` bursts an existing one.
- **Neon glow:** `"blend": "additive"` on bright Sprites/Shapes/particles plus `"bloom": true` on the primary `Camera`
  (`bloomThreshold`, `bloomIntensity`, `bloomRadius`) over a dark `clearColor`. Never hand-draw blurred halo sprites.
  `"bloomScreenSpace": false` keeps the HUD crisp. Spin a triangle with `pivot: [0.5, 0.3333]` (its centroid);
  `Shape2D` also has `diamond`, `polygon` and `star`; `ParticleEmitter` takes `space: "screen"`. Guide section 9.20.
- **Custom shaders:** `MeshRenderer.material` names a `materials/*.material.json` (a GLSL `surface()` snippet that changes
  what the standard material computed, optional `vertex()`, typed params). Write the two files, call `shader.compile`
  (MCP `shader_compile`) until `ok`, then look at a screenshot. Full guide with five worked examples: `factoria docs read shaders`.
- **One-way platforms:** `Collider2D.oneWay: true` (not Tilemap solid tiles).
- **Tile levels:** `scene.import_ascii` (MCP `scene_import_ascii`, CLI `factoria call scene.import_ascii @levels/level1.json`) turns
  ASCII `rows` plus a `legend` into a Tilemap and its coins, enemies and spawn points (prefabs placed at the cell centres). Keep
  the map in `levels/` and re-run it after every edit. Put `"path": "scenes/x.scene.json"` in the map file: it edits that scene
  FILE (optionally starting `from` a base scene) and never touches the running game; no `--scene`, no `scene.save`.
  `Tilemap.columns` is optional (0 = derived from the tileset image width): leave it out. Guide section 9.8. Do not place
  tile objects by hand or write a level generator.
- **Camera and area limits:** `entity.bounds()` is the world rectangle `{x, y, w, h}` (bottom-left corner and size) of a
  Tilemap, Sprite or Shape2D. Clamp a follow camera with `world.find("map").bounds()`, not with map sizes copied into props.
  Guide section 9.6.
- **Sounds and their tests:** `audio.play("assets/sfx/jump.wav")`. Assert it with
  `expect(game.audioLog()).toContainPlayed("jump.wav")` (options `times`, `bus`, `source`; `game.clearAudioLog()`). A clip that
  failed to load does not count. MCP `audio_log`. Guide sections 9.7 and 10.
- **Prefab files and tidy JSON:** `prefab.save` (MCP `prefab_save`) saves an entity you built in the running game, with its
  children, as `prefabs/<name>.prefab.json` (it leaves out ids, the root position and `tilemap:` tags; it never overwrites
  without `"overwrite": true`). `scene.format` (MCP `scene_format`; `{"check": true}` only lists) puts hand-edited scenes and
  prefabs in the canonical layout. Guide section 6. Do not lay out prefab JSON by hand.
- **Sensing:** `entity.isGrounded()`, `entity.isTouching([dx, dy])`, `physics.raycast(a, b, {ignore: this.entity})`.
  Skip the first two fixed steps before probing (bodies are created by the first physics step).
- **Spawning:** `world.spawn(json, {position, parent, props})` and `world.spawnPrefab(path, {position, props, overrides})`;
  `parent` is an Entity or an id, and `position` is then local to it.
- **Cross-scene state:** `session` is a plain object that survives `scene.load`. `storage` is for save files.
- **Failing a check:** `throw new ToolError(message, hint, data?)`. For a list of every problem, return it as a
  normal result with `ok: false`.
- **3D:** `RigidBody3D.angularVelocity`, `rollWithMotion` and `rollingFriction` (a rolling ball slows by that, not by
  sliding friction; with `rollWithMotion` off a sphere is a rigid body that real friction rolls and spins);
  box colliders follow `Transform.rotation` and fast bodies do not tunnel; dynamic boxes are
  rigid bodies (collisions turn them: they tip, tumble and settle), so give a box-shaped character or an upright
  crate `"lockRotation": true`; calm bodies fall asleep and wake when touched or written to; kinematic platforms
  carry the bodies on them;
  `Light.castShadows`; `settings.fogDensity` and `fogColor`.
- **Vectors:** `vec2(...)`, `[x, y]` and `{x, y}` are accepted wherever a vector is expected.
- **Replays:** `factoria run --headless --input replay.json` with `press`, `release`, `keys` and `mouse` entries.

## Debugging

- `factoria validate` first: it loads every scene and checks assets, input bindings, scripts.
- `factoria run --headless --frames N --state-out out.json` dumps entities and components; MCP
  `game_state` / `scene_list_entities` give the same live. `game_logs` shows script errors.
- Compare screenshots before/after a change. If the picture is black, check there is a
  primary `Camera`, that sprites have a `layer` and size, and that the colors are not 0..255.
- To act on a running game, use `factoria session`: one JSON request per stdin line, one JSON answer per
  stdout line, and the game keeps its state. For example
  `printf '%s\n' '{"command":"game.step","args":{"frames":30}}' '{"command":"script.eval","args":{"code":"world.find(\"player\").position"}}' | factoria session`.
- `factoria call --batch '[{"command":"game.step","args":{"frames":30}},{"command":"script.eval","args":{"code":"..."}}]'`
  runs several commands on one engine; add `--press a,b` or `--input replay.json` after the array to set the start.
  A plain `factoria call <command> '<json>'` starts a NEW engine each time. All commands: `factoria commands`.
- Headless runs and tests simulate every frame but draw only for screenshots (fast); `--render-all` draws all.

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
- Examples worth reporting: a component field you expected is missing; an error message did not
  say how to fix the problem; a doc was wrong or absent; a command you wanted does not exist; a
  crash; slow or flaky headless runs; anything you had to emulate in JS.

## Definition of done for a task

`factoria validate` is clean, a screenshot shows the intended result, `factoria test` passes with
a test covering the new behaviour, and every engine gap you met is in `ENGINE_FEEDBACK.json`.
