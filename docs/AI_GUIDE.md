# How to build a game with FactorIA (for AI agents)

Read this guide before you change a FactorIA game. Read it with `factoria docs read ai-guide`, or over MCP with `docs_read {"name":"ai-guide"}` or the resource `factoria://docs/AI_GUIDE.md`. The `AGENTS.md` in your project repeats the short rules.

Every name here is part of this build's contracts. Check a name before you use it: `factoria api --md` lists every component field, `factoria commands` lists every command and its arguments (`factoria commands scene.spawn` shows one), and `factoria docs search <words>` searches these docs. Over MCP use `docs_components`, `docs_commands` and `docs_search`. Do not guess component fields or command arguments.

## 1. Mental model

A game is a folder of text files:

```
my-game/
  factoria.json           project settings: display, physics, input actions, main scene
  scenes/*.scene.json     levels: entities with components
  prefabs/*.prefab.json   reusable entities (optional)
  scripts/*.js            behaviours: game logic as JavaScript classes
  tools/*.js              project tools: commands you (and other AIs) can call
  tests/*.test.js         headless tests
  data/*.json             level or balance data, imported from scripts (optional)
  assets/                 images, sounds, fonts, models (only when you need them)
  types/factoria.d.ts     generated script typings (do not edit)
  AGENTS.md               short guide for AI agents, written by `factoria new`
  ENGINE_FEEDBACK.json    engine gaps you met (see THE FEEDBACK RULE)
  .factoria/              generated output: screenshots, logs (do not edit)
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
| `title` | short noun phrase, such as "No gamepad input". Reuse the same wording for the same gap. |
| `missing` | what you needed and what the engine did instead |
| `workaround` | what you did instead, with `workaroundFiles` (project-relative paths) |
| `suggestion` | the engine change that would remove the workaround: a field, a command or an API |

The tool requires `category`, `severity`, `title`, `missing` and `workaround`. Always add `workaroundFiles` and `suggestion` as well, because the engine team needs them. `effort` (`small`, `medium`, `large`) and `reporter` (`{"kind":"ai","agent":"...","model":"..."}`) are optional. Call `feedback_list {"status":"open"}` (or `factoria feedback list --status open`) to see what is already recorded.

Good example, a missing input binding:

```json
{
  "category": "input",
  "severity": "major",
  "title": "No gamepad input",
  "missing": "The game needs a controller, but gamepad bindings such as GamepadA are reserved and not supported yet.",
  "workaround": "none: feature dropped. The game is keyboard and touch only.",
  "suggestion": "Support GamepadA/B/X/Y and D-pad bindings in factoria.json input.actions."
}
```

Good example, a missing scene feature:

```json
{
  "category": "scene",
  "severity": "minor",
  "title": "No per-tile entity hooks in Tilemap",
  "missing": "A Tilemap draws and collides but cannot place coins, enemies or spawn points on its tiles, so each pickup is a separate entity whose position I computed from the tile grid by hand.",
  "workaround": "scenes/level1.scene.json lists the coins as separate entities at the tile centres.",
  "workaroundFiles": ["scenes/level1.scene.json"],
  "suggestion": "Let a Tilemap carry a list of {col, row, prefab} entries that are spawned when the scene loads."
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
| `project_validate` | `project.validate` | Check the whole project. Returns `ok`, `errors[]`, `warnings[]`; each issue has `file`, `pointer`, `message` and `hint`. |
| `project_test` | `project.test` | Run `tests/*.test.js` headless, optionally `{"filter":"player"}`. Tests change the running world, so call `scene_reload` afterwards. |
| `scene_list_entities` | `scene.list_entities` | List entities. Filters: `name` (substring), `tag`, `component`, `limit`. |
| `scene_get_entity` | `scene.get_entity` | One entity with every field, by `id` (or name). |
| `scene_spawn` | `scene.spawn` | Create an entity: `{"prefab":"prefabs/enemy.prefab.json","position":[300,0]}`, or entity JSON with `name`, `tags`, `components` and an optional `parent` id. |
| `scene_set_component`, `scene_remove_component` | `scene.set_component`, `scene.remove_component` | Set fields with `{"id":"player","component":"Shape2D","fields":{...}}`, or remove a component by `id` and `component`. |
| `scene_destroy` | `scene.destroy` | Destroy an entity and its children: `{"id":"coin_1"}`. |
| `scene_load`, `scene_save`, `scene_reload` | `scene.load`, `scene.save`, `scene.reload` | Load `{"path"}`, save the running world (optional `path`), or reload the current scene. |
| `game_step` | `game.step` | Advance N fixed frames: `{"frames":60,"press":["move_right"]}`. `press` and `release` apply before the first frame and stay in effect until released. |
| `game_input` | `game.input` | Press or release an action or key now, or move the mouse. Forms: `{"action":"jump","down":true}`, `{"key":"Space","down":false}`, `{"mouse":{"position":[640,360]}}`. The next `game_step` sees the input. |
| `game_screenshot` | `game.screenshot` | Capture the last rendered frame as an image. Optional `path`; by default it is saved under `.factoria/screenshots/`. Needs graphics. |
| `game_state` | `game.state` | Dump the running game: entities, physics, script errors, render stats. Filters: `entities` (ids), `components` (names), `includeDefaults`, `maxEntities` (default 200). |
| `game_logs` | `game.logs` | Recent log lines: `{"minLevel":"warn","max":50}`. Pass `after` (a `seq` from an earlier call) to get only new lines. |
| `game_pause`, `game_resume` | `game.pause`, `game.resume` | Pause or resume the simulation. |
| `script_eval` | `script.eval` | Evaluate JavaScript in the running game: `{"code":"world.findByTag(\"coin\").length"}`. |
| `script_errors` | `script.errors` | Exceptions thrown by scripts. |
| `physics_raycast` | `physics.raycast` | First hit of a ray: `{"from":[0,300],"to":[0,-300]}` in 2D. In 3D pass `"dimension":"3d"`, `origin`, `direction`, `maxDistance`. Only `mask` is available here; `ignore` exists in scripts (section 8). |
| `api_components`, `api_commands`, `api_scripting`, `assets_list`, `engine_info`, `project_info` | `api.*`, `assets.list`, `engine.info`, `project.info` | Introspection of the engine, the API and the project. |
| `fs_list`, `fs_read`, `fs_write`, `fs_edit`, `fs_search`, `fs_delete` | `fs.*` | Project files, sandboxed to the project folder. Use them if your client has no file tools. |
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
| Screen space | `"space": "screen"` on Sprite, Shape2D or Text. Units are design pixels, the origin is the top-left corner and +Y points down. Cameras do not affect it. Use it for HUD and menus. Section 9.4 shows how to pin items to the corners. |
| `anchor` and `pivot` | Screen space only: `anchor` (0..1 in each axis) is the screen point the position is relative to: [0,0] top-left, [1,0] top-right, [0,1] bottom-left, [1,1] bottom-right. `pivot` is the point of the item that sits at that point: [0,0] bottom-left, [0,1] top-left, [1,1] top-right, [0.5,0.5] centre. Sprite and Shape2D default to [0.5,0.5]; Text defaults to [0,1]. |
| 3D | Units are meters. Right-handed, +Y up. A perspective camera looks down its local -Z axis. |
| Angles | Degrees. In 2D only `rotation[2]` is used, counter-clockwise. In 3D, `rotation` is `[pitch X, yaw Y, roll Z]` and the matrix is `Ry(yaw) · Rx(pitch) · Rz(roll)`. |
| Colors | `[r, g, b, a]` with values 0..1, `"#rgb"`, `"#rrggbb"` or `"#rrggbbaa"`, or a name: white, black, red, green, blue, yellow, cyan, magenta, gray, grey, orange, purple, pink, brown, transparent. If any value in an array is above 1, the engine reads the array as 0..255 bytes, so keep to 0..1. |
| Vectors | In scripts, a vector argument accepts `Vec2`/`Vec3` values, `{x, y}` or `[x, y]`. In JSON, use arrays (`[x, y]` or `[x, y, z]`); `{x, y}` objects also work in component fields. |
| Input | Gameplay reads actions (`input.pressed("jump")`) declared in `factoria.json` under `input.actions`. Bindings are key names (`"A"`, `"Space"`, `"Left"`, `"LeftShift"`, `"0"` to `"9"`, `"F1"`), `"MouseLeft"`, `"MouseRight"`, `"MouseMiddle"` or `"Touch"` (any finger down). Gamepad names are reserved and not supported yet. |
| Ids | Give every gameplay entity a stable `id` (`"player"`, `"coin_3"`). Entity references use ids. |
| Paths | Project-relative with forward slashes (`assets/hero.png`). The file tools (`fs_*`) reject absolute paths and any `..` segment. |
| Determinism | Random numbers come from `rng` (imported from "factoria"). Time comes from the `dt` argument or `time.dt`. Never use `Math.random`, `Date.now` or wall-clock time. |
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

`settings` holds the scene-wide values: `gravity2D`, `gravity3D`, `ambientLight`, `skyColor`, `horizonColor`, `fogColor`, `fogDensity`, `music`, `musicVolume`. A prefab is `factoria.prefab/1` with one `entity`:

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
| `Camera` | `projection` (orthographic, perspective), `primary`, `clearColor`, `depth`, `clear`, `orthoSize` (0 = design height / 2), `fov` | The view. Without a primary camera the screenshot is black. |
| `Sprite` | `texture` (asset path; empty = solid `color`), `size` (0 = image size), `pivot` (default [0.5, 0.5]), `color`, `flipX`, `flipY`, `layer`, `space`, `anchor`, `blend`, `region`, `pixelArt` | An image or a coloured quad. |
| `SpriteAnimator` | `columns`, `rows`, `firstFrame`, `lastFrame`, `fps`, `loop`, `playing` (needs a Sprite) | Frame-by-frame animation from a sprite sheet. |
| `Shape2D` | `shape` (rectangle, circle, line, triangle), `size`, `color`, `filled`, `thickness`, `layer`, `space`, `anchor`, `pivot` (default [0.5, 0.5]), `blend` | Placeholder art and UI panels. No assets needed. For a circle, `size[0]` is the diameter. |
| `Text` | `text` (`\n` breaks lines), `fontSize` (default 24), `color`, `align`, `pivot` (default [0, 1]), `maxWidth`, `layer` (default 100), `space`, `anchor`, `font` | Labels, scores and the HUD (`space: "screen"`). |
| `Tilemap` | `tileset`, `tileSize`, `columns`, `width`, `height`, `tiles` (row 0 is the top row, -1 = empty), `solidTiles` | A level from a grid. Solid tiles get collision (section 9.8). |
| `ParticleEmitter` | `emitting`, `rate`, `burst`, `autoDestroy`, `maxParticles`, `lifetime`, `speed`, `direction` (0 = right, 90 = up), `spread`, `gravity`, `startSize`, `endSize`, `startColor`, `endColor`, `blend`, `texture`, `layer` | Sparks, dust and explosions (section 9.12). |

`layer` is the draw order: higher layers draw on top. `space: "screen"` items ignore the camera.

**3D**

| Component | Key fields | Typical use |
|---|---|---|
| `MeshRenderer` | `mesh` (cube, sphere, plane, cylinder, capsule, cone, quad, or a .glb/.gltf path), `color`, `texture`, `metallic`, `roughness`, `emissive`, `unlit`, `castShadows`, `receiveShadows`, `uvScale` | Visible 3D objects. Primitives need no assets. Unless `unlit`, it needs a light to look right. |
| `Light` | `type` (directional, point, spot), `color`, `intensity`, `range`, `spotAngle`, `castShadows` (directional only) | Lighting and shadows. A directional light points along the entity's -Z axis after its rotation. |

**Physics**

| Component | Key fields | Typical use |
|---|---|---|
| `RigidBody2D` | `type` (static, dynamic, kinematic), `velocity` [x,y], `angularVelocity` (degrees/s), `gravityScale`, `fixedRotation`, `bullet`, `linearDamping`, `angularDamping` | Moves an entity under 2D physics. A static body never moves. |
| `Collider2D` | `shape` (box, circle, capsule), `size`, `radius`, `offset`, `isTrigger`, `oneWay`, `friction`, `restitution`, `density`, `layer` (0..31), `mask` (-1 = all layers) | Collision shape. With `isTrigger: true` it reports overlaps and does not block. With `oneWay: true` it is a one-way platform (section 9.5). |
| `RigidBody3D` | `type`, `mass`, `velocity` [x,y,z], `angularVelocity` (degrees/s about x, y, z), `rollWithMotion`, `gravityScale`, `linearDamping` | A simple 3D body. Shapes ignore `Transform.rotation`; `angularVelocity` spins the visual. |
| `Collider3D` | `shape` (box, sphere), `size`, `radius`, `offset`, `isTrigger`, `friction`, `restitution`, `layer`, `mask` | 3D collision. Boxes are axis-aligned, and `size` is scaled by `Transform.scale`. |

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
| `onStart()` | Once, before the first update. `props` are already applied. |
| `onUpdate(dt)` | Every frame. `dt` is in seconds, scaled by `time.scale`. |
| `onFixedUpdate(dt)` | Every fixed step, before physics. Use it for movement that physics must see. |
| `onLateUpdate(dt)` | After all updates. Use it for cameras that follow targets. |
| `onDestroy()` | Before the entity is removed. |
| `onCollisionEnter(other, info)`, `onCollisionExit(other)` | Solid contacts. `info` is `{point, normal, impulse}`. |
| `onTriggerEnter(other)`, `onTriggerExit(other)` | Overlaps with trigger colliders. |
| `onEvent(name, data, source)` | Any `world.emit` event. |

Timing you can rely on:

- The behaviour object exists as soon as its entity does: right after `world.spawn`, `spawnPrefab`, a scene load or `game.load`. So `world.spawn(...).behaviour` and `game.find("id").behaviour` are usable at once. `onStart()` runs at the start of the next step.
- Physics bodies are created by the first physics step. In the first `onFixedUpdate` after a spawn or a load, `physics.raycast` finds nothing and `isTouching` is false. Skip the first two fixed steps before you probe (section 9.14).
- `Script.props` keys that are not fields of the class are reported once (in the log and by `factoria validate`), with a "did you mean" hint. Declare every tunable as a class field.

Inside a behaviour: `this.entity` (the owning entity), `this.world`, `this.after(seconds, fn)` and `this.every(seconds, fn)` (timers that stop when the entity is destroyed; both return a handle with `.cancel()`), `this.on(name, fn)` (an event listener), and `this.enabled` (false skips the update callbacks).

Entity members: `id`, `name`, `tags`, `active`, `alive`, `transform`, `position`, `worldPosition`, `get(name)` (a live view, or `null`), `add(name, fields)`, `set(name, fields)`, `has`, `remove`, `destroy()` (deferred to the end of the frame), `hasTag`, `addTag`, `removeTag`, `parent`, `children`, `setParent`, `behaviour`, `send(method, ...args)`, `isGrounded(tolerance?)` (2D pixels or 3D meters), `isTouching(direction, tolerance?)`, `emitBurst(count)` and `toJSON()`.

`entity.isTouching([1, 0])` is true when a solid body touches this entity on the right; `[-1, 0]` is left, `[0, -1]` is the ground below, `[0, 1]` the ceiling. Triggers never count.

The most-used members of the `"factoria"` module. The full list is in `docs_read {"name":"scripting"}`:

| Import | Members |
|---|---|
| `world` | `find(idOrName)`, `findAll(name)`, `findByTag(tag)`, `entities()`, `spawn(json, {position, rotation, scale, parent, props})`, `spawnPrefab(path, {position, rotation, scale, parent, props, overrides})`, `emit(name, data)`, `on(name, fn)` (returns an unsubscribe function) |
| `input` | `pressed(a)`, `down(a)`, `released(a)`, `axis(negative, positive)`, `vector(left, right, down, up)`, `keyDown("Space")`, `keyPressed`, `keyReleased`, `mouse` (`position`, `world`, `delta`, `wheel`, `down("left")`, `pressed("left")`), `touches` (`[{id, position, world, pressed}]`) |
| `audio` | `play(path, {volume, pitch, pan, loop, bus})` (bus defaults to `"sfx"`), `stop(id)`, `stopAll()`, `music(path, {volume, fade})`, `stopMusic(fade)`, `setVolume(bus, v)` |
| `physics` | `raycast(from, to, {mask, ignore, ignoreTriggers})`, `raycast3d(origin, dir, maxDistance, {mask, ignore, ignoreTriggers})`, `overlapCircle(center, r, {mask})`, `overlapBox(rect, {mask})`, `overlapSphere(center, r, {mask})`, `applyImpulse`, `applyForce`, `setVelocity` |
| `time`, `camera`, `debug` | `time.dt`, `time.fixedDt`, `time.elapsed`, `time.scale` (0 pauses gameplay); `camera.main`, `worldToScreen`, `screenToWorld`; `debug.line`, `debug.rect`, `debug.circle`, `debug.text`, `debug.box`, `debug.sphere` |
| `scene`, `game`, `storage` | `scene.load(path)` (deferred to the end of the frame), `scene.current`; `game.quit()`, `game.paused`, `game.project`, `game.screenSize`; `storage.get(key, fallback)`, `storage.set(key, value)`, `storage.remove(key)` |
| `session` | A plain object that survives scene loads for the whole run (section 9.15) |
| `rng`, `math` | `rng.seed(n)`, `rng.float()`, `rng.range(a, b)`, `rng.int(a, b)`, `rng.chance(p)`, `rng.pick(array)`; `math.clamp`, `lerp`, `damp`, `moveTowards`, `degToRad` and others |
| `particles`, `ui` | `particles.burst(entity, count)`; `ui.measureText(text, {fontSize, font, maxWidth})` returns `{width, height}` |
| `vec2`, `vec3`, `color` | constructors, for example `vec2(10, 0)`, `vec3([0, 4, 9])` or `color("#ffcc00")` |
| `ToolError` | `new ToolError(message, hint, data?)` for a failed check in a tool (section A of `docs_read {"name":"extending"}`) |
| `fa` | `fa.call(name, args)` runs any command and throws on error; `fa.commands()` lists them |

Options worth knowing:

- `world.spawn(json, {parent})` makes the new entity a child. `parent` is an Entity or an id string, and `position` is then local to the parent.
- `raycast` options: `mask` (layer bits), `ignore` (an Entity or id whose colliders are skipped, including its children), `ignoreTriggers` (default true). Colliders that already contain the ray origin are skipped too.
- `input.touches` entries: `id` (the finger), `position` (Vec2, design pixels, top-left origin), `world` (Vec3 in the world through the main camera) and `pressed` (true only on the first frame of contact).
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

To spawn without a prefab, pass the entity object itself, as in `templates/2d-platformer/tools/spawn_coin.js`:

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

`props` in the spawn options is merged into the entity's `Script.props`. `destroy()` is deferred to the end of the frame. Destroy the entities you no longer need, so that spawners do not fill the scene.

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

The camera stays inside the level rectangle. The rectangle lives in a JSON file that the script imports (section 9.16):

```js
// scripts/follow_camera.js
import { Behaviour, math } from "factoria";
import levels from "../data/levels.json";

export default class FollowCamera extends Behaviour {
  target = "player";
  smoothing = 8;   // higher is snappier

  onLateUpdate(dt) { // after all updates, so the target has already moved
    const t = this.world.find(this.target);
    if (!t) return;
    const { minX, minY, maxX, maxY } = levels.bounds;
    const halfW = 640, halfH = 360; // half of the 1280x720 design size (orthoSize 0)
    const tx = math.clamp(t.position.x, minX + halfW, maxX - halfW);
    const ty = math.clamp(t.position.y, minY + halfH, maxY - halfH);
    const p = this.entity.position;
    p.x = math.damp(p.x, tx, this.smoothing, dt);
    p.y = math.damp(p.y, ty, this.smoothing, dt);
  }
}
```

`data/levels.json` holds `{ "bounds": { "minX": -640, "minY": -360, "maxX": 1000, "maxY": 720 } }`. If the level is narrower than the view, `minX + halfW` is greater than `maxX - halfW`, the clamp range is empty, and the result depends on the target. Centre the camera on `(minX + maxX) / 2` in that case.

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

`project_validate` checks the asset fields of the scene (for example `Sprite.texture`, `AudioSource.clip` and `Script.path`), but not paths written in code. A missing file passed to `audio.play` shows up in `game_logs`.

### 9.8 Tilemap levels and tile collision

A `Tilemap` draws a grid from a tileset image. Row 0 is the TOP row, and `-1` is an empty tile. The entity's position is the top-left corner of the map, with +Y up. Tile (col, row) covers x from `px + col*tw` to `px + (col+1)*tw` and y from `py - (row+1)*th` to `py - row*th`.

```json
{
  "id": "level",
  "name": "Level",
  "components": {
    "Transform": { "position": [-640, 360, 0] },
    "Tilemap": {
      "tileset": "assets/tiles.png",
      "tileSize": [32, 32],
      "columns": 8,
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

The flat `tiles` array has `width * height` entries (the field also accepts an array of rows). The tileset image holds tiles of `tileSize`, laid out `columns` per row, left to right and top to bottom. Validation reports a missing tileset.

How tiles collide (verified against the physics rules):

- Every tile index in `solidTiles` becomes part of one static body per Tilemap. Horizontal runs in a row are merged, and identical runs in consecutive rows are merged too.
- Tile shapes are on layer 0, with friction 0.5 and no bounce. They are not triggers, so tiles raise no trigger events, and they are not one-way.
- Tile indices that are not in `solidTiles` are drawn but never block.
- Merging can leave seams between boxes of different heights. A character with friction can catch on a seam when it slides along a wall. Give characters `friction: 0` against walls, or use a circle or capsule foot.
- Tiles cannot carry behaviour. Coins, enemies and spawn points are separate entities. Place them with the tile formula above.

### 9.9 3D scene with a light and fog

From `templates/3d-empty/scenes/main.scene.json` (abridged):

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

To burst an emitter that already exists, call `particles.burst(entity, 24)` or `entity.emitBurst(24)`; both work with `emitting: false`. Without graphics (`--no-graphics`) they do nothing and log a warning. A continuous effect (fire, dust) keeps `emitting: true` and a `rate`.

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

Hot reload covers JSON too. A syntax error is reported against the `.json` file. For levels that must be generated from parameters, write a project tool that builds the scene and writes it with `fs.write` (see `docs_read {"name":"extending"}`, A.1).

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

A **moving platform** is a `RigidBody3D` with `"type": "kinematic"` whose `velocity` the script sets. Bodies resting on top of it are carried along by its displacement, so a rider moves with the platform. Verified: over 30 frames the platform moved 1.49 m and the ball resting on it moved 1.48 m.

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

To make something spin without rolling, set `RigidBody3D.angularVelocity` (degrees per second about x, y, z) and `"rollWithMotion": false`. Verified: `[0, 90, 0]` gave `rotation.y = 90` after one second. Collision shapes stay axis-aligned, so the spin is visual only.

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
- Touch: `touch(screenPos, frames)` for a finger held for some frames, `touchStart(screenPos, id?)`, `touchMove(screenPos, id?)`, `touchEnd(id?)`. `input.touches[0].pressed` is true on the first frame only.
- Queries: `find(idOrName)`, `world`, `time`, `state()`, `screenshot(path)` (needs graphics).

Patterns that work:

- Settle first with `game.step(...)`, then act, then assert. Read values after the step, not before.
- Reach behaviour fields through the entity: `game.find("enemy_1").behaviour.dir`.
- Test behaviour, not implementation: positions, component values, whether an entity still exists (`game.find(id) === null`).
- Use `toBeCloseTo(n, digits)` for floats, and `toBeGreaterThan` for "moved far enough".
- `game.load` gives a test a known starting state. Within one file, anything else (variables, `session`, behaviour fields) carries over between tests unless the test loads or resets it.
- Storage is an empty in-memory store for each test file, so tests never read or write the real save. `session` is also reset per file.
- Keep tests fast: headless steps do not draw, so `game.step(600)` costs little. Take a screenshot only where you need to see something, and avoid `--render-all`, which draws every frame in software and is much slower.
- `console.log`, `console.warn` and `console.error` in scripts are log lines with category `script`. To see what a test printed, run `factoria test --log-level info`. Use `console.log` while you debug, and remove it before you finish.
- Import JSON data in tests the same way as in scripts (`import levels from "../data/levels.json";`).

## 11. Debugging, live sessions and replays

| Command | MCP tool | What it tells you |
|---|---|---|
| `factoria validate`, `project.validate` | `project_validate` | Structure and references, before anything runs. |
| `script.errors` | `script_errors` | Exceptions thrown by scripts, with file, line and stack. |
| `game.logs` | `game_logs` | Log lines. `console.log/warn/error` in scripts appear with category `script`. |
| `game.state` | `game_state` | Entities, components, physics, logs and errors of the running game. |
| `scene.get_entity` | `scene_get_entity` | One entity by id. |

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

The same format works with `factoria call --input` and `factoria session --input`, which apply it while stepping.

### 11.3 Other checks

- Errors name their location (file and JSON pointer), what is wrong and how to fix it. Unknown component or field names come with a "did you mean" hint. Read the hint first.
- Black or empty screenshot: check for a primary `Camera`, that sprites have a `layer` and a size, that colours are 0..1 (not 0..255), and that world and screen space are not mixed up. A Text or panel in the wrong corner usually has the wrong `anchor` or `pivot` (section 9.4). If the machine has no GPU, the engine runs in logic-only mode and `game_screenshot` says so. Then rely on `game_state` and `game_logs`.
- Body that does not move: check its `type` (static never moves), that it has a collider, its `layer` and `mask`, and the sign of gravity in `settings.gravity2D`.
- A patrol or sensor that turns around on its first step: the first physics step has not run yet (section 9.14).
- Results differ between runs: look for `Math.random`, `Date.now`, or timing. Headless runs are deterministic only when those are absent.
- Tool errors: a tool that throws `ToolError` returns `code` `tool_error`, the `message` and the `hint`. The hint is how to fix the data. Extra `data` appears in the JSON error of `factoria session` and `call --batch`; MCP shows only the code, message and hint, so put the facts a fixer needs in the hint.

## 12. Common mistakes

- Reading raw keys in gameplay. Declare an action in `factoria.json` and read the action.
- Using `Math.random` or `Date.now`. Use `rng` and `dt`.
- Writing colours as 0..255. Use 0..1, or `"#rrggbb"`.
- Expecting +Y to point down in the world. In the world +Y is up. Only screen-space UI has +Y down.
- Treating tilemap row 0 as the bottom row. Row 0 is the top row.
- Forgetting the primary `Camera`.
- Using `pivot: [0, 0]` for top-left screen text. Text pivots are y-up: top-left is `[0, 1]`.
- Expecting Tilemap solid tiles to be one-way, or expecting coins and enemies to be tile entries. Use a one-way entity for jump-through ledges, and separate entities for pickups.
- Probing for ground in the first fixed step after a spawn (section 9.14).
- Reading `game.world` or `game.time` in `script.eval`. Use `world` and `time`.
- Editing `types/factoria.d.ts` or `.factoria/`. Both are generated.
- Guessing a component field or command argument. Check `factoria api --md` and `factoria commands`.
- Changing only the running game (`scene_spawn`, `scene_set_component`) and then forgetting that the scene file did not change. Save the scene (`scene_save`) or write it in the file.
- Skipping THE FEEDBACK RULE because the workaround "works".

## 13. Performance

- Build a level with one `Tilemap` rather than hundreds of sprites. Its solid tiles become a small number of merged colliders.
- Use `burst` with `autoDestroy` for one-shot effects, and set `maxParticles` for continuous ones.
- Look up entities once in `onStart` and keep the references. Calling `world.find` every frame adds up.
- Use `RigidBody2D.bullet: true` only for fast, small bodies.
- 3D physics handles spheres and boxes. Very fast bodies can pass through each other.
- Keep iteration runs short. 120 frames is 2 seconds of game time.

## 14. Where to read more

- `factoria docs read scripting` (MCP `docs_read {"name":"scripting"}`): the full JavaScript API, tools and tests.
- `factoria api --md` and `factoria commands` (MCP `docs_components` and `docs_commands`): generated references for this build.
- `factoria docs read extending` (MCP `docs_read {"name":"extending"}`): how to add project tools and engine commands.
- `factoria docs read cli` (MCP `docs_read {"name":"cli"}`): every command and flag.
- The project's `AGENTS.md`: short rules for this game.
