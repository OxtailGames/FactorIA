# How to build a game with FactorIA (for AI agents)

Read this guide before you change a FactorIA game. Over MCP it is served as `docs_read {"name":"ai-guide"}` and as the resource `factoria://docs/AI_GUIDE.md`. The CLI form `factoria docs read ai-guide` is planned. The `AGENTS.md` in your project repeats the short rules.

Every name here comes from the engine contracts. Your build may not have all of them yet, so the tools in your tool list are the ones that exist. To check a name, call `docs_search` or `docs_commands`. Do not guess component fields or command arguments.

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
  assets/                 images, sounds, fonts, models (only when you need them)
  types/factoria.d.ts     generated script typings (do not edit)
  AGENTS.md               short guide for AI agents, written by `factoria new`
  ENGINE_FEEDBACK.json    engine gaps you met (see THE FEEDBACK RULE)
  .factoria/              generated output: screenshots, logs (do not edit)
```

- **Components are data.** An entity has a stable `id`, optional `name` and `tags`, and components such as `Transform`, `Sprite` or `RigidBody2D`. Engine systems (rendering, physics, audio, scripts) read them.
- **Behaviours are JavaScript.** Logic lives in classes that extend `Behaviour`. Attach one with the `Script` component: `"Script": {"path": "scripts/player.js", "props": {"speed": 300}}`. `props` override the class fields, so one script serves many entities.
- **Commands are tools.** Every engine capability is a named command, such as `scene.spawn`. Over MCP the name has `.` replaced by `_`: `scene_spawn`. The file `tools/spawn_wave.js` becomes the command `project.spawn_wave` and the tool `project_spawn_wave`.
- **The simulation is fixed-step and deterministic.** It runs at `physics.fixedHz` steps per second (60 by default). The same seed and the same input give the same result, so tests are reliable.

## 2. The development loop

Repeat it for every change. Make small steps: change one thing, validate, run, look.

1. **Read.** `docs_list`, then `docs_read {"name":"scripting"}` for the script API, `docs_components` for component fields, and `docs_search {"query":"..."}` for everything else.
2. **Edit** scenes, prefabs, `scripts/`, `tools/`, `tests/` or `factoria.json`.
3. **Validate.** Run `project_validate` (CLI: `factoria validate`). Fix every error using its file, JSON pointer and hint. It must be clean before you go on.
4. **Run and LOOK.** Run `game_step {"frames":120}`, then `game_screenshot`. Open the image and check that it shows what you intended. Check `game_logs` and `script_errors`. A clean validation does not prove that the scene is right.
5. **Test.** Add or update a test in `tests/*.test.js` for every behaviour. Run it with `project_test` (CLI: `factoria test`, planned). A bug fix starts with a test that fails.
6. **Report gaps** as soon as you meet them (next section).

Done means: `project_validate` is clean, a screenshot shows the intended result, the tests pass and cover the new behaviour, and every engine gap you met is recorded in `ENGINE_FEEDBACK.json`.

## 3. THE FEEDBACK RULE (mandatory)

Whenever the engine lacks a feature, has a bug, gives an error that does not say how to fix it, or has a wrong or missing doc, **and** you build a workaround or drop the feature: record it now, in the same turn, before you continue. Do not wait until the end of the task. Duplicates are fine: a similar open entry in the same category is merged, and its `occurrences` count goes up. Not reporting is the only wrong choice.

Call the MCP tool `feedback_report` with:

| Field | Value |
|---|---|
| `category` | one of: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation, tooling, ai-integration, docs, platform, performance, networking, other |
| `severity` | `blocker` (could not build it), `major` (large or fragile workaround), `minor` (small workaround), `nice-to-have` (convenience) |
| `title` | short noun phrase, such as "No one-way platforms". Reuse the same wording for the same gap. |
| `missing` | what you needed and what the engine did instead |
| `workaround` | what you did instead, with `workaroundFiles` (project-relative paths) |
| `suggestion` | the engine change that would remove the workaround: a field, a command or an API |

Optional: `effort` (`small`, `medium`, `large`) and `reporter` (`{"kind":"ai","agent":"...","model":"..."}`). Call `feedback_list {"status":"open"}` to see what is already recorded.

Good example, a missing physics option:

```json
{
  "category": "physics",
  "severity": "major",
  "title": "No one-way platforms",
  "missing": "Collider2D has no one-way option, so the player cannot jump up through a platform from below.",
  "workaround": "scripts/one_way.js disables the platform collider while the player moves upward.",
  "workaroundFiles": ["scripts/one_way.js"],
  "suggestion": "Add a Collider2D oneWay field (bool) with a direction, enforced by fa_physics."
}
```

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

Without MCP, use `factoria call feedback.report '{...}'` (CLI, planned), or add an entry to `ENGINE_FEEDBACK.json` by hand. A hand-written entry must match `schemas/engine-feedback.schema.json`, which also requires `id`, `date`, `occurrences` and `status`. The tool sets those for you, so prefer it.

## 4. Using the MCP tools

A tool name is the command name with `.` replaced by `_`. Arguments are one JSON object. Results are JSON, and a screenshot comes back as an image. A failure returns `code`, `message` and `hint`; the hint says how to fix it. An unknown name returns a "did you mean" suggestion. `docs_commands` lists every command with its `inputSchema`, so use it to get exact argument names.

| Tool | Command | Purpose |
|---|---|---|
| `docs_list`, `docs_read`, `docs_search`, `docs_components`, `docs_commands` | `docs.*` | Read the built-in docs, the component reference and the command list. |
| `project_validate` | `project.validate` | Check the whole project. Returns `ok`, `errors[]`, `warnings[]`; each issue has `file`, `pointer`, `message` and `hint`. |
| `project_test` | `project.test` | Run `tests/*.test.js` headless, optionally `{"filter":"player"}`. Tests change the running world, so call `scene_reload` afterwards. |
| `scene_list_entities` | `scene.list_entities` | List entities. Filters: `name`, `tag`, `component`. |
| `scene_get_entity` | `scene.get_entity` | One entity with every field, by `id`. |
| `scene_spawn` | `scene.spawn` | Create an entity: `{"prefab":"prefabs/enemy.prefab.json","position":[300,0]}`, or entity JSON with `name`, `tags` and `components`. |
| `scene_set_component`, `scene_remove_component` | `scene.set_component`, `scene.remove_component` | Set fields with `{"id":"player","component":"Shape2D","fields":{...}}`, or remove a component by `id` and `component`. |
| `scene_destroy` | `scene.destroy` | Destroy an entity and its children: `{"id":"coin_1"}`. |
| `scene_load`, `scene_save`, `scene_reload` | `scene.load`, `scene.save`, `scene.reload` | Load `{"path"}`, save the running world (optional `path`), or reload the current scene. |
| `game_step` | `game.step` | Advance N fixed frames: `{"frames":60,"press":["move_right"]}`. `press` and `release` apply before the first frame and stay in effect until released. |
| `game_input` | `game.input` | Press or release an action or key now, or move the mouse. Forms: `{"action":"jump","down":true}`, `{"key":"Space","down":false}`, `{"mouse":{"position":[640,360]}}`. The next `game_step` sees the input. |
| `game_screenshot` | `game.screenshot` | Capture the current frame as an image. Optional `path`; by default it is saved under `.factoria/screenshots/`. |
| `game_state` | `game.state` | Dump the running game: entities, physics, script errors, render stats. Filters: `entities` (ids), `components` (names), `includeDefaults`, `maxEntities` (default 200). |
| `game_logs` | `game.logs` | Recent log lines: `{"minLevel":"warn","max":50}`. Pass `after` (a `seq` from an earlier call) to get only new lines. |
| `game_pause`, `game_resume` | `game.pause`, `game.resume` | Pause or resume the simulation. |
| `script_eval` | `script.eval` | Evaluate JavaScript in the running game: `{"code":"world.findByTag(\"coin\").length"}`. |
| `script_errors` | `script.errors` | Exceptions thrown by scripts. |
| `physics_raycast` | `physics.raycast` | First hit of a ray: `{"from":[0,300],"to":[0,-300]}` in 2D. In 3D pass `"dimension":"3d"`, `origin`, `direction` and `maxDistance`. |
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

The MCP server also offers prompts: `make-game` (argument `idea`), `add-feature` (`feature`), `fix-bug` (`description`) and `report-engine-gap`.

## 5. Coordinates, units and conventions

| Topic | Rule |
|---|---|
| 2D world | Units are design pixels. +X is right and +Y is up. The origin is the centre of the screen. With the 1280x720 design size of the templates, a default camera shows x from -640 to 640 and y from -360 to 360. |
| Screen space | Sprite, Shape2D and Text with `"space": "screen"`. Units are design pixels, the origin is the top-left corner and +Y points down. Cameras do not affect it. Use it for HUD and menus. |
| 3D | Units are meters. Right-handed, +Y up. A perspective camera looks down its local -Z axis. |
| Angles | Degrees. In 2D only `rotation[2]` is used, counter-clockwise. In 3D, `rotation` is `[pitch X, yaw Y, roll Z]`, applied in the order Y, X, Z. |
| Colors | `[r, g, b, a]` with values 0..1, or `"#rrggbb"` / `"#rrggbbaa"`. If any value in an array is above 1, the engine reads the array as 0..255 bytes, so keep to 0..1. |
| Input | Gameplay reads actions (`input.pressed("jump")`) declared in `factoria.json` under `input.actions`. Bindings are key names (`"A"`, `"Space"`, `"Left"`, `"LeftShift"`, `"0"` to `"9"`, `"F1"`), `"MouseLeft"`, `"MouseRight"`, `"MouseMiddle"` or `"Touch"`. Gamepad names are reserved and not supported yet. |
| Ids | Give every gameplay entity a stable `id` (`"player"`, `"coin_3"`). Entity references use ids. |
| Paths | Project-relative with forward slashes (`assets/hero.png`). The file tools reject absolute paths and `..`. |
| Determinism | Random numbers come from `rng` (imported from "factoria"). Time comes from the `dt` argument or `time.dt`. Never use `Math.random`, `Date.now` or wall-clock time. |
| Names | JSON keys are camelCase. Components are PascalCase (`RigidBody2D`). Enum values are lowercase (`"orthographic"`). Commands are `area.verb_object`. |
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

`settings` holds the scene-wide values (`gravity2D`, `gravity3D`, `ambientLight`, `skyColor`, `music` and others). A prefab is `factoria.prefab/1` with one `entity`:

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

This is a summary. `docs_components` has every field, its default and its range, and it is generated from the engine, so it is always current.

**Core (every entity has these)**

| Component | Key fields | Typical use |
|---|---|---|
| `Transform` | `position` [x,y,z], `rotation` [x,y,z] in degrees, `scale` | Where things are. |
| `EntityInfo` (not a component) | top-level `id`, `name`, `tags`, `active` | Identity. `active: false` disables an entity and its children. |

**2D**

| Component | Key fields | Typical use |
|---|---|---|
| `Camera` | `projection` (orthographic, perspective), `primary`, `clearColor`, `depth`, `clear`, `orthoSize` (0 = design height / 2), `fov` | The view. Without a primary camera the screenshot is black. |
| `Sprite` | `texture` (asset path; empty = solid `color`), `size` (0 = image size), `pivot` (default [0.5, 0.5]), `color`, `flipX`, `flipY`, `layer`, `space`, `region`, `pixelArt` | An image or a coloured quad. |
| `SpriteAnimator` | `columns`, `rows`, `firstFrame`, `lastFrame`, `fps`, `loop`, `playing` (needs a Sprite) | Frame-by-frame animation from a sprite sheet. |
| `Shape2D` | `shape` (rectangle, circle, line, triangle), `size`, `color`, `filled`, `thickness`, `layer`, `space` | Placeholder art and UI panels. No assets needed. For a circle, `size[0]` is the diameter. |
| `Text` | `text` (`\n` breaks lines), `fontSize` (default 24), `color`, `align`, `pivot` (default [0, 1]), `maxWidth`, `layer` (default 100), `space`, `font` | Labels, scores and the HUD (`space: "screen"`). |
| `Tilemap` | `tileset`, `tileSize`, `columns`, `width`, `height`, `tiles` (row 0 is the top row, -1 = empty), `solidTiles` | A level from a grid. Solid tiles get collision. |
| `ParticleEmitter` | `emitting`, `rate`, `burst`, `maxParticles`, `lifetime`, `speed`, `direction` (0 = right, 90 = up), `spread`, `gravity`, `startSize`, `endSize`, `startColor`, `endColor`, `texture` | Sparks, dust and explosions (use `burst`). |

**3D**

| Component | Key fields | Typical use |
|---|---|---|
| `MeshRenderer` | `mesh` (cube, sphere, plane, cylinder, capsule, cone, quad, or a .glb/.gltf path), `color`, `texture`, `metallic`, `roughness`, `emissive`, `unlit`, `castShadows`, `receiveShadows`, `uvScale` | Visible 3D objects. Primitives need no assets. Needs a perspective camera and, unless `unlit`, a light. |
| `Light` | `type` (directional, point, spot), `color`, `intensity`, `range`, `spotAngle`, `castShadows` (directional only) | Lighting. A directional light points along the entity's -Z axis after its rotation. |

**Physics**

| Component | Key fields | Typical use |
|---|---|---|
| `RigidBody2D` | `type` (static, dynamic, kinematic), `velocity` [x,y], `gravityScale`, `fixedRotation`, `bullet`, `linearDamping`, `angularDamping`, `angularVelocity` | Moves an entity under 2D physics. A static body never moves. |
| `Collider2D` | `shape` (box, circle, capsule), `size`, `radius`, `offset`, `isTrigger`, `friction`, `restitution`, `density`, `layer` (0..31), `mask` (-1 = all layers) | Collision shape. With `isTrigger: true` it reports overlaps and does not block. |
| `RigidBody3D` | `type`, `mass`, `velocity` [x,y,z], `gravityScale`, `linearDamping` | A simple 3D body with no rotation dynamics. |
| `Collider3D` | `shape` (box, sphere), `size`, `radius`, `offset`, `isTrigger`, `friction`, `restitution`, `layer`, `mask` | 3D collision. 3D physics ignores `Transform.rotation`. |

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

Inside a behaviour: `this.entity` (the owning entity), `this.world`, `this.after(seconds, fn)` and `this.every(seconds, fn)` (timers that stop when the entity is destroyed; both return a handle with `.cancel()`), and `this.enabled`.

The most-used members of the `"factoria"` module. The full list is in `docs_read {"name":"scripting"}`:

| Import | Members |
|---|---|
| `world` | `find(idOrName)`, `findAll(name)`, `findByTag(tag)`, `entities()`, `spawn(json)`, `spawnPrefab(path, {position, rotation, parent, overrides})`, `emit(name, data)`, `on(name, fn)` (returns an unsubscribe function) |
| `input` | `pressed(a)`, `down(a)`, `released(a)`, `axis(negative, positive)`, `vector(left, right, down, up)`, `keyDown("Space")`, `mouse` (`position`, `world`, `delta`, `down("left")`), `touches` |
| `audio` | `play(path, {volume, pitch, pan, loop, bus})`, `stop(id)`, `stopAll()`, `music(path, {volume, fade})`, `stopMusic(fade)`, `setVolume(bus, v)` |
| `physics` | `raycast(from, to, {mask})`, `raycast3d(origin, dir, maxDistance)`, `overlapCircle`, `overlapBox`, `overlapSphere`, `applyImpulse`, `applyForce`, `setVelocity` |
| `time`, `camera`, `debug` | `time.dt`, `time.fixedDt`, `time.scale`; `camera.main`, `worldToScreen`, `screenToWorld`; `debug.line`, `debug.rect`, `debug.circle`, `debug.text` |
| `scene`, `game`, `storage` | `scene.load(path)` (deferred to the end of the frame), `game.quit()`, `game.paused`; `storage.get(key, fallback)`, `storage.set(key, value)`, `storage.remove(key)` |
| `rng`, `math` | `rng.float()`, `rng.range(a, b)`, `rng.int(a, b)`, `rng.chance(p)`, `rng.pick(array)`; `math.clamp`, `lerp`, `damp`, `moveTowards`, `degToRad` and others |
| `vec2`, `vec3`, `color` | constructors, for example `vec2(10, 0)` or `color("#ffcc00")` |
| `fa` | `fa.call(name, args)` runs any command and throws on error; `fa.commands()` lists them |

Entities expose `id`, `name`, `tags`, `active`, `transform`, `position`, `worldPosition`, `get(name)` (a live view, or `null`), `add(name, fields)`, `set(name, fields)`, `has`, `remove`, `destroy()` (deferred to the end of the frame), `hasTag`, `addTag`, `removeTag`, `parent`, `children`, `setParent`, `isGrounded()` (2D), `send(method, ...args)` and `toJSON()`.

## 9. Recipes

### 9.1 Platformer character

This is `templates/2d-platformer/scripts/player.js`, which is the starting point for any platformer:

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
const coin = world.spawn({
  name: "Coin",
  tags: ["coin"],
  components: {
    Transform: { position: [x, y, 0] },
    Shape2D: { shape: "circle", size: [24, 24], color: [1, 0.85, 0.2, 1], layer: 1 },
    RigidBody2D: { type: "static" },
    Collider2D: { shape: "circle", radius: 12, isTrigger: true },
  },
});
```

`destroy()` is deferred to the end of the frame. Destroy the entities you no longer need, so that spawners do not fill the scene.

### 9.4 Score and HUD

HUD entity in the scene (values from `templates/2d-platformer`):

```json
{
  "id": "hud",
  "name": "Score",
  "components": {
    "Transform": { "position": [24, 24, 0] },
    "Text": { "text": "Coins: 0", "fontSize": 32, "color": [1, 1, 1, 1], "pivot": [0, 0], "space": "screen", "layer": 100 },
    "Script": { "path": "scripts/hud.js" }
  }
}
```

Script that listens for an event emitted by the player (`this.world.emit("coin_collected", {...})`):

```js
import { Behaviour } from "factoria";

export default class Hud extends Behaviour {
  coins = 0;

  onStart() {
    this.world.on("coin_collected", () => {
      this.coins += 1;
      this.entity.get("Text").text = `Coins: ${this.coins}`;
    });
  }
}
```

Text pivots are easy to get wrong in screen space. Check the screenshot, and use the default `[0, 1]` pivot if the text is clipped.

### 9.5 Collisions and triggers

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
- `Collider2D` has no one-way option. If you need one, report it (THE FEEDBACK RULE).

### 9.6 Camera follow

From `templates/2d-platformer/scripts/follow_camera.js`:

```js
import { Behaviour, math } from "factoria";

export default class FollowCamera extends Behaviour {
  target = "player"; // entity id
  smoothing = 8;     // higher is snappier

  onLateUpdate(dt) { // runs after all updates, so the target has already moved
    const t = this.world.find(this.target);
    if (!t) return;
    const p = this.entity.position;
    p.x = math.damp(p.x, t.position.x, this.smoothing, dt);
  }
}
```

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

### 9.8 Tilemap levels

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

`tiles` has `width * height` entries. Add a real tileset image at `assets/tiles.png`, or validation will report the missing asset.

### 9.9 3D scene with a light

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

### 9.11 Changing levels

```js
import { Behaviour, scene } from "factoria";

export default class Goal extends Behaviour {
  onTriggerEnter(other) {
    if (other.hasTag("player")) scene.load("scenes/level2.scene.json"); // applied at the end of the frame
  }
}
```

## 10. Tests

Each test file runs in a fresh engine with the project's seed, so results are deterministic. Drive the game through inputs and assert on the result:

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

- Available: `test`, `test.skip`, `describe`; `expect` with `toBe`, `toEqual`, `toBeCloseTo(n, digits)`, `toBeGreaterThan`, `toBeLessThan`, `toContain`, `toBeNull`, `toBeDefined`, `toThrow` and `.not`.
- `game`: `load`, `step(frames)`, `press`, `release`, `tap`, `keyDown`, `keyUp`, `click`, `find`, `world`, `time`, `screenshot(path)`, `state()`.
- Test behaviour, not implementation: positions, component values, whether an entity still exists.

## 11. Debugging

| Command | MCP tool | What it tells you |
|---|---|---|
| `project.validate` | `project_validate` | Structure and references, before anything runs. |
| `script.errors` | `script_errors` | Exceptions thrown by scripts, with file, line and stack. |
| `game.logs` | `game_logs` | Log lines. `console.log/warn/error` in scripts appear with category `script`. |
| `game.state` | `game_state` | Entities, components, physics, logs and errors of the running game. |
| `scene.get_entity` | `scene_get_entity` | One entity by id. |

- Errors name their location (file and JSON pointer), what is wrong and how to fix it. Unknown component or field names come with a "did you mean" hint. Read the hint first.
- Black or empty screenshot: check for a primary `Camera`, that sprites have a `layer` and a size, that colours are 0..1, and that world and screen space are not mixed up.
- Body that does not move: check its `type` (static never moves), that it has a collider, its `layer` and `mask`, and the sign of gravity in `settings.gravity2D`.
- Results differ between runs: look for `Math.random`, `Date.now`, or timing. Headless runs are deterministic only when those are absent.
- Reproduce a bug with an input replay for headless runs. Frames are 0-based and an entry applies before its frame runs:

```json
{ "frames": { "0": { "press": ["jump"] }, "30": { "release": ["jump"] } } }
```

## 12. Common mistakes

- Reading raw keys in gameplay. Declare an action in `factoria.json` and read the action.
- Using `Math.random` or `Date.now`. Use `rng` and `dt`.
- Writing colours as 0..255. Use 0..1.
- Expecting +Y to point down in the world. In the world +Y is up. Only screen-space UI has +Y down.
- Treating tilemap row 0 as the bottom row. Row 0 is the top row.
- Forgetting the primary `Camera`.
- Editing `types/factoria.d.ts` or `.factoria/`. Both are generated.
- Guessing a component field or command argument. Check `docs_components` and `docs_commands`.
- Changing only the running game (`scene_spawn`, `scene_set_component`) and then forgetting that the scene file did not change.
- Skipping THE FEEDBACK RULE because the workaround "works".

## 13. Performance

- Build a level with one `Tilemap` rather than hundreds of sprites. Its solid tiles become a small number of merged colliders.
- Use `ParticleEmitter.burst` for one-shot effects, and set `maxParticles` for continuous ones.
- Look up entities once in `onStart` and keep the references. Calling `world.find` every frame adds up.
- Use `RigidBody2D.bullet: true` only for fast, small bodies.
- 3D physics handles spheres and boxes. Very fast bodies can pass through each other.
- Keep iteration runs short. 120 frames is 2 seconds of game time.

## 14. Where to read more

- `docs_read {"name":"scripting"}`: the full JavaScript API, tools and tests.
- `docs_components` and `docs_commands`: generated references for this build.
- `docs_read {"name":"extending"}`: how to add project tools and engine commands.
- The project's `AGENTS.md`: short rules for this game.
