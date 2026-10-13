# Scripting reference (JavaScript)

Gameplay code is JavaScript (ES2023 modules) run by QuickJS. Three kinds of
script live in a project:

| Folder | What | Runs |
|---|---|---|
| `scripts/` | **Behaviours** attached to entities via the `Script` component | every frame while the game runs |
| `tools/` | **Tools**: commands for AIs/editor/CLI (become MCP tools) | when called |
| `tests/` | **Tests** (`*.test.js`) | `factoria test` (headless) |

Type declarations for everything below are generated into
`types/factoria.d.ts`; add `// @ts-check` at the top of a file and run
`npx tsc -p .` to type-check (optional but recommended for AIs).

## Behaviours

```js
// scripts/player.js
import { Behaviour, input, audio, vec2 } from "factoria";

export default class Player extends Behaviour {
  speed = 320;        // fields are defaults; Script.props in the scene override them
  jumpSpeed = 620;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
  }

  onUpdate(dt) {
    const dir = input.axis("move_left", "move_right");
    this.body.velocity.x = dir * this.speed;          // component views write through
    if (input.pressed("jump") && this.entity.isGrounded()) {
      this.body.velocity.y = this.jumpSpeed;
      audio.play("assets/sfx/jump.wav");
    }
  }

  onCollisionEnter(other, info) {
    if (other.hasTag("coin")) {
      other.destroy();
      this.world.emit("coin_collected", { by: this.entity.id });
    }
  }
}
```

Scene usage: `"Script": { "path": "scripts/player.js", "props": { "speed": 400 } }`.

### When behaviours exist
The behaviour instance is constructed (class fields initialised, `Script.props`
applied) **synchronously** when its entity appears: right after `world.spawn`,
`world.spawnPrefab`, `entity.add("Script", ...)`, a scene load and `game.load`
in tests. So `world.spawn(...).behaviour` and `game.find("id").behaviour` are
usable immediately (configure it, call its methods). `onStart()` still runs
later: at the start of the next step, before the entity's first `onUpdate`
(so `game.load(...)` in a test followed by `game.step()` runs `onStart`; reading
`.behaviour` fields set in `onStart` needs one `game.step()` first).

A `Script.props` key that is not an own field of the class (declare it as a
class field!) logs ONE warning naming the entity, with a "did you mean"
suggestion; `factoria validate` reports the same through
`ScriptSystem::check_props`.

### Cross-scene state
- `session` (from `"factoria"`) is a plain object that survives scene loads for
  the whole run: `session.score = 0; session.lives = 3`. It is not saved to disk
  (use `storage` for that) and is reset for every test file.
- Module-level variables (`let score = 0` in a module) also persist across
  scene loads, because modules are evaluated once per run. Behaviours,
  timers and `world.on` listeners do not: they are dropped when a scene loads.

### Lifecycle (all optional)

| Method | When |
|---|---|
| `onStart()` | once, before the first update after the entity exists (props already applied) |
| `onUpdate(dt)` | every frame, `dt` in seconds (scaled by `time.scale`) |
| `onFixedUpdate(dt)` | every fixed step (default 60 Hz), before physics |
| `onLateUpdate(dt)` | after all updates (cameras following targets) |
| `onDestroy()` | before the entity is removed |
| `onCollisionEnter(other, info)` / `onCollisionExit(other)` | physics contacts; `info = { point, normal, impulse }` |
| `onTriggerEnter(other)` / `onTriggerExit(other)` | overlaps with trigger colliders |
| `onEvent(name, data, source)` | any `world.emit` event (also `world.on(name, fn)`) |

### Behaviour members
- `this.entity` — the owning `Entity`; `this.world` — the world.
- `this.after(seconds, fn)` / `this.every(seconds, fn)` — timers, cancelled
  automatically on destroy; return a handle with `.cancel()`.
- `this.enabled` — `false` skips update callbacks.

## Entity

| Member | Description |
|---|---|
| `id`, `name`, `tags`, `active`, `alive` | identity (`id` is the stable scene id) |
| `transform` | `Transform` view: `position`, `rotation`, `scale` (Vec3 views) |
| `position` | shortcut for `transform.position` (assignable: `e.position = vec2(10, 0)`) |
| `worldPosition` | world-space position (get/set) |
| `get(name)` | live view of a component or `null` (`e.get("Sprite").color.a = 0.5`) |
| `add(name, fields?)` | adds (or returns) a component, applies `fields` |
| `set(name, fields)` | patches fields (adds if missing) |
| `has(name)`, `remove(name)` | |
| `destroy()` | deferred to end of frame (children too) |
| `parent`, `children`, `setParent(e, keepWorld?)` | hierarchy |
| `hasTag(t)`, `addTag(t)`, `removeTag(t)` | tags |
| `behaviour` | the script instance attached to it (or `null`) |
| `send(method, ...args)` | calls `behaviour[method](...args)` if it exists |
| `isGrounded(tolerance?)` | 2D or 3D physics: standing on something (contact normal up) |
| `isTouching(direction, tolerance?)` | solid contact against the body on that side: `isTouching([1, 0])` = wall on the right, `[0, 1]` = ceiling (2D or 3D by body type) |
| `emitBurst(n)` | immediately spawn `n` particles from this entity's `ParticleEmitter` (no-op + warning without a renderer) |
| `toJSON()` | entity JSON (as in scene files) |

Component views expose exactly the reflected fields listed by `factoria api
components` (also `docs/COMPONENTS.md`). Vector/color fields are live views
(`v.x = 1` writes into the engine); enums are lowercase strings
(`body.type = "kinematic"`); asset fields are path strings; JSON fields
(`Tilemap.tiles`, `Script.props`) are plain objects — assign a new value to
write.

## Vectors everywhere
Every API taking a position/vector (`world.spawn`/`spawnPrefab` options and
component fields, `entity.position`/`worldPosition`, `physics.*`, `camera.*`,
`debug.*`, `entity.set/add` fields) accepts a `Vec2`/`Vec3`, a plain `{x, y}` /
`{x, y, z}` object or an `[x, y]` / `[x, y, z]` array. 2D values set `z = 0`
(scale: `z = 1`). `rotation` may be a number (degrees around z) or a vector;
`scale` a number or a vector. Bad input throws an Error that lists the accepted
forms. Rects (`physics.overlapBox`, `debug.rect`) take `{x, y, w, h}` or
`[x, y, w, h]`.

## Imports
- `"./util.js"` / `"../lib/x.js"` resolve relative to the importing module;
  `"scripts/x.js"` (no leading dot) is relative to the project root. A path
  that leaves the project root is an error naming the import.
- JSON data: `import levels from "../data/levels.json";` gives the parsed
  file as the default export (hot reload aware). A JSON syntax error is
  reported against the .json file.
- Test files get fresh module instances (see Tests), so module state never leaks
  between test files.

## Modules

Everything is imported from `"factoria"`:

```js
import { Behaviour, world, input, audio, physics, time, camera, debug, scene, game,
         storage, rng, fa, vec2, vec3, color, Vec2, Vec3, Color, math,
         session, particles, ui, ToolError } from "factoria";
```

### world
- `find(idOrName)` → Entity | null · `findAll(name)` · `findByTag(tag)` · `entities()`
- `spawn(entityJson, { position, rotation, scale, parent, props })` → Entity (same format as scene files; `{ name, tags, components: {...} }`)
- `spawnPrefab(path, { position, rotation, scale, parent, props, overrides })` → Entity.
  `props` is merged into the entity's `Script.props` (on top of the prefab's own); `overrides` is entity JSON
  merged over the prefab (`{ components: { Sprite: { color: ... } } }`).
- Destroyed entities (`entity.destroy()`, deferred to frame end) stop being returned by `find`/`findAll`/`findByTag`
  immediately and their id can be reused right away (`world.spawn({ id: "gem_1" })` right after destroying `gem_1`).
- `emit(name, data)` · `on(name, fn)` → unsubscribe function
- `settings` — SceneSettings view (gravity2D, ambientLight, ...)
- `time`, `frame`

### input
- Actions (preferred): `down(a)`, `pressed(a)`, `released(a)`, `axis(neg, pos)`, `vector(left, right, down, up)`
- Keys: `keyDown("Space")`, `keyPressed("A")`, `keyReleased("Escape")`
- Mouse: `mouse.position` (screen, top-left origin), `mouse.world` (world coords via main camera),
  `mouse.delta`, `mouse.wheel`, `mouse.down("left")`, `mouse.pressed("right")`
- Touch: `touches` → `[{ id, position, world, pressed }]`

### audio
- `play(path, { volume, pitch, pan, loop, bus })` → voice id · `stop(id)` · `stopAll()`
- `music(path, { volume, fade })` · `stopMusic(fade)` · `setVolume(bus, v)` (`"master"`, `"sfx"`, `"music"`, `"ui"`)

### physics
- `raycast(from, to, { mask, ignore, ignoreTriggers })` → `{ entity, point, normal, distance } | null` (2D when `from` has no z)
- `raycast3d(origin, dir, maxDistance, { mask, ignore, ignoreTriggers })`. Colliders that contain the ray origin are
  skipped. From a behaviour pass the caster so it does not hit itself: `physics.raycast(a, b, { ignore: this.entity })`
  (`ignore` is an Entity or id; triggers are skipped unless `ignoreTriggers: false`). Ledge check pattern: cast a short
  ray down from just ahead of the feet and treat "no hit" as a ledge.
-  `overlapCircle(center, r)` · `overlapBox(rect)` · `overlapSphere(center, r)`
- `applyImpulse(entity, v)` · `applyForce(entity, v)` · `setVelocity(entity, v)`

### time
`dt`, `fixedDt`, `elapsed`, `frame`, `scale` (writable; 0 pauses gameplay).

### camera
`main` (primary camera Entity), `worldToScreen(v)`, `screenToWorld(v)`.

### debug
`line(a, b, color?)`, `rect(x, y, w, h, color?)`, `circle(center, r, color?)`, `text(screenPos, str, color?)`.

### particles / ui
- `particles.burst(entity, count)` (same as `entity.emitBurst(count)`) spawns particles now from a `ParticleEmitter`,
  even with `emitting = false`. Without a renderer (headless) it is a no-op with a warning.
- `ui.measureText(text, { fontSize, font, maxWidth })` → `{ width, height }` laid out like `Text` rendering.
  Headless runs approximate (0.6 × fontSize per character) and warn once.

### scene / game / storage
- `scene.load(path)` (deferred to frame end) · `scene.reload()` · `scene.current`
- `game.quit()` · `game.paused` · `game.project` (read-only factoria.json) · `game.screenSize`
- `storage.get(key, fallback)` · `storage.set(key, value)` · `storage.remove(key)` — persistent JSON save data
  (`<user dir>/storage.json`). Tests always use an empty in-memory storage per test file and never touch the real
  save; the runtime can run headless with `ScriptSystem::set_storage_mode(StorageMode::Memory)`.

### rng (deterministic, seeded per run)
`rng.seed(n)` reseeds the world RNG (seed → level determinism from tools/tests) · `rng.float()` [0,1) · `rng.range(a, b)` · `rng.int(a, b)` (inclusive) · `rng.chance(p)` · `rng.pick(array)`

### math & values
- `vec2(x, y)`, `vec3(x, y, z)`, `color(r, g, b, a?)` / `color("#ffcc00")`
- `Vec2`/`Vec3` methods: `add sub mul scale div dot length lengthSq normalized distance lerp clone equals`,
  `Vec2.fromAngle(deg)`, `v.angle()`, `v.rotated(deg)`
- `math`: `clamp lerp inverseLerp remap damp moveTowards approach sign degToRad radToDeg wrapAngle`
- `console.log/warn/error` go to the engine log (category `script`).

### fa (commands)
`fa.call(name, args)` runs any command (same as MCP tools; throws on error) ·
`fa.commands()` lists them.

## Tools (`tools/*.js`)

```js
// tools/spawn_wave.js — becomes command "project.spawn_wave" / MCP tool "project_spawn_wave"
import { world, rng, vec2 } from "factoria";

export default {
  name: "spawn_wave",
  summary: "Spawn a wave of enemies at random positions.",
  description: "Example: {\"count\": 8}. Returns the ids of the spawned enemies.",
  input: { type: "object", properties: { count: { type: "integer", minimum: 1, default: 5 } } },
  readOnly: false,
  run({ count }) {
    const ids = [];
    for (let i = 0; i < count; i++) {
      const e = world.spawnPrefab("prefabs/enemy.prefab.json", { position: vec2(rng.range(-600, 600), 300) });
      ids.push(e.id);
    }
    return { spawned: ids };
  },
};
```

Tools hot-reload when the file changes; MCP clients are notified.

**Failing a tool.** `throw new ToolError(message, hint, data?)` (from `"factoria"`) reports an *expected* failure
(for example a check tool that found bad level data): the caller gets code `tool_error`, the message, your `hint`
(how to fix the data, not the tool) and, if given, `data` (any JSON, appended to the message as `data: {...}` so the
report is not lost). Any other thrown Error is a script bug: code `failed`, the message with `file:line`, and it is
also recorded as a script error. `ToolError` is not recorded as a script error.

## Tests (`tests/*.test.js`)

```js
import { test, expect, game } from "factoria:test";

test("player jumps", () => {
  game.load("scenes/main.scene.json");
  game.step(5);                         // let things settle
  const player = game.find("player");
  const y0 = player.position.y;
  game.press("jump");
  game.step(10);
  game.release("jump");
  expect(player.position.y).toBeGreaterThan(y0);
});
```

- `test(name, fn)`, `test.skip`, `describe(name, fn)`
- `expect(v)`: `toBe toEqual toBeCloseTo(n, digits) toBeGreaterThan toBeGreaterThanOrEqual toBeLessThan
  toBeLessThanOrEqual toBeTruthy toBeFalsy toBeNull toBeDefined toContain toHaveLength toThrow`, and `.not`
- `game`: `load(path)` (behaviours are constructed immediately, `onStart` runs on the first `step`),
  `loadJson(sceneObject)`, `step(frames = 1)`, `touch(pos, frames = 1)`, `touchStart(pos, id?)`, `touchMove(pos, id?)`,
  `touchEnd(id?)` (fill `input.touches`; `pressed` is true for the frame after `touchStart`), `press(action)`, `release(action)`, `tap(action)`,
  `keyDown(key)`, `keyUp(key)`, `mouseMove(screenPos)`, `click(screenPos, button?)`, `find(idOrName)`,
  `world`, `time`, `screenshot(path)`, `state()`

Each test FILE starts from fresh module instances (module-level state is
re-created, tools are re-evaluated against them), an empty in-memory `storage`
(the real save file is never read or written) and an empty `session`. Within a
file, state carries over between tests unless you reset it.

Tests run inside the current engine (only one renderer can exist per
process). Between test files the runner reloads the project's start scene,
reseeds the world RNG with the project seed, clears input overrides, timers and
behaviours; `game.load` also reseeds. Before each test input overrides and
`time.scale` are reset. Results are deterministic. Extras: `describe.skip`,
`beforeEach(fn)` / `afterEach(fn)` inside `describe`, matchers `toBeUndefined`,
`toBeNaN`, `toMatch`, `toBeInstanceOf`. Failures print expected/received and
`file:line` of the failing `expect`.

## Runtime notes
- `Math.random()` is routed to the deterministic world RNG (`rng.*`); never use
  wall-clock time in simulation.
- Callbacks running longer than 2 s are aborted ("script took too long") and the
  behaviour is disabled until its file is reloaded. Exceptions are recorded once
  per (file, line, message) with a hint; the behaviour keeps running.
- `world.on(name, fn)` listeners get `(data, source)`; `this.on(name, fn)` is the
  same. All listeners/timers are dropped when a scene loads.
- Unknown input actions, keys, components and fields throw errors with
  "did you mean" suggestions. Component views reject unknown field assignment.
- Hot reload (`reload_module`) re-imports the module and every module that
  imports it, recreates affected behaviours (entity state kept, props re-applied,
  `onStart` runs again, `onDestroy` is NOT called) and reloads tools.
- A tool never replaces a built-in command: a tool whose `project.<name>`
  already exists is rejected with a script error.
- `entity.get("Script").props` (a JSON field) returns a copy; assign to write.
