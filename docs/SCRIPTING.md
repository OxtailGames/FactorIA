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
| `position` | shortcut for `transform.position` (assignable: `e.position = vec2(10, 0)`). On an entity with a physics body it teleports the body (also when it was asleep: it falls from the new place), and `isGrounded()` reflects the new place after the next physics step |
| `worldPosition` | world-space position (get/set) |
| `bounds()` | world-space rectangle of the entity's 2D visual, `Rect \| null` (see below) |
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

### entity.bounds()

`entity.bounds()` returns the world-space axis-aligned rectangle `{ x, y, w, h }` of the entity's 2D visual (a `Rect`),
or `null` when there is none. Use it to read an extent from the scene instead of copying numbers into props, for
example the clamp rectangle of a follow camera from the level's `Tilemap`:

```js
const r = world.find("map").bounds();   // Tilemap at (0, 512), 60 x 16 tiles of 32 px: { x: 0, y: 0, w: 1920, h: 512 }
const minX = r.x, maxX = r.x + r.w, minY = r.y, maxY = r.y + r.h;
```

- **Convention.** `(x, y)` is the minimum corner: the BOTTOM-LEFT in the +Y-up world, and `w`, `h` are the size. This
  is the `Rect` every other API uses, so the result can go straight into `physics.overlapBox(rect)` or
  `debug.rect(...)`. `r.x + r.w` is the right edge and `r.y + r.h` the top edge. The numbers are world units after the
  entity's world transform (parents included).
- **Tilemap.** The size of the map as it is drawn and collides (the rows form, or `width` x `height` of the flat form;
  the same helper as the renderer) times `tileSize`. The entity position is the map's TOP-left corner, so the map spans
  `x .. x + w` and `y - h .. y` at scale 1. An empty map has no bounds (`null`).
- **Sprite, Shape2D.** The drawn box from `size` and `pivot`. A sprite without `size` uses its `region`, else the
  texture's pixel size (32 x 32 for a plain colour quad or a missing texture). A circle is its bounding square
  (diameter `size.x`), a line is the stroked segment from the origin to `size`, and the outline `thickness` of the other
  shapes is ignored.
- **Text.** The laid-out text box (`pivot` and `maxWidth` as drawn). Without a renderer (headless) the size is the
  same approximation as `ui.measureText` and logs the same one-time warning.
- **Rotation and scale** of the world transform are applied, and the result is the box around the rotated corners.
  An entity that has several visuals (a `Sprite` and a `Text`) gets the union of their rectangles.
- **Screen space.** A visual with `space: "screen"` is positioned on the screen, not in the world, so it has no world
  rectangle: it is skipped, and an entity that only has screen-space visuals returns `null`. Lay HUD items out with
  `game.screenSize` and their `anchor`.
- Children are not included. `active` and colour alpha are ignored: a hidden entity still has bounds.

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
`[x, y, w, h]`; `(x, y)` is the minimum (bottom-left) corner. `entity.bounds()` returns a Rect.

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
         session, particles, ui, assets, ToolError } from "factoria";
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
- Actions (preferred): `down(a)`, `pressed(a)`, `released(a)`, `value(a)`, `axis(neg, pos)`, `vector(left, right, down, up)`.
  Keys, mouse, touch and gamepad buttons are 0 or 1; gamepad sticks and triggers are analog. `value(a)` is 0..1 (the
  maximum over the action's bindings), `axis(neg, pos)` is `value(pos) - value(neg)`, so a stick gives -1..1 while keys
  give exactly -1, 0 or 1, and `vector(...)` is `(axis, axis)` normalized only when longer than 1 (a half-tilted stick
  gives a short vector, two keys a unit diagonal). An action is `down` from `value >= 0.5` (a stick pushed about 60 %
  of the way with the default deadzone); `pressed`/`released` fire when it crosses that threshold.
- Keys: `keyDown("Space")`, `keyPressed("A")`, `keyReleased("Escape")`
- Mouse: `mouse.position` (screen, top-left origin), `mouse.world` (world coords via main camera),
  `mouse.delta`, `mouse.wheel`, `mouse.down("left")`, `mouse.pressed("right")`
- Touch: `touches` → `[{ id, position, world, pressed }]`. The first finger also drives the mouse (position, and the
  left button down while it is down), on a device and in tests alike, so a script that reads both `input.mouse` and
  `input.touches` sees one tap in both and should act on it once.
- Gamepads: bind `"GamepadA"`, `"GamepadStart"`, `"GamepadDpadLeft"`, `"GamepadLeftStickRight"`, `"GamepadRightTrigger"`...
  in `input.actions` (the full list is in `docs/AI_GUIDE.md`); a binding matches ANY connected pad. Unknown names are
  errors with a "did you mean". Sticks use a radial deadzone (`"input": { "deadzone": 0.2 }` in `factoria.json`, default
  0.2) and the rest is rescaled to the full range; read or assign `input.deadzone` to offer calibration in an options
  menu. `gamepad(index = 0)` (0..3) returns one pad for local multiplayer:
  `{ connected, down(button), pressed(button), released(button), axis(name), rawAxis(name) }`. Buttons: `A B X Y Start Back
  Guide DpadLeft DpadRight DpadUp DpadDown LeftShoulder RightShoulder LeftThumb RightThumb`; axes: `LeftX LeftY RightX RightY`
  (-1..1, +Y up) and `LeftTrigger RightTrigger` (0..1). `axis` has the deadzone applied (what the bindings see), `rawAxis`
  does not. Real pads are read in windowed runs only (Windows XInput, Linux joystick API, macOS/iOS GameController;
  Android and web: not yet), so headless runs and tests stay deterministic.

### audio
- `play(path, { volume, pitch, pan, loop, bus })` → voice id · `stop(id)` · `stopAll()`
- `music(path, { volume, fade })` · `stopMusic(fade)` · `setVolume(bus, v)` (`"master"`, `"sfx"`, `"music"`, `"ui"`)
- Every play request (scripts, `AudioSource`, scene music) is recorded in a play log: tests read it with
  `game.audioLog()`, agents with the `audio.log` command.

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
The `Camera` component fields are live, for example `camera.main.get("Camera").bloomIntensity = 2` changes the glow
(`bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`; see AI_GUIDE section 9.20).

### debug
`line(a, b, color?)`, `rect(x, y, w, h, color?)`, `circle(center, r, color?)`, `text(screenPos, str, color?)`.

### particles / ui
- `particles.burst(entity, count)` (same as `entity.emitBurst(count)`) spawns particles now from a `ParticleEmitter`,
  even with `emitting = false`. Without a renderer (headless) it is a no-op with a warning.
- `ui.measureText(text, { fontSize, font, maxWidth })` → `{ width, height }` laid out like `Text` rendering.
  Headless runs approximate (0.6 × fontSize per character) and warn once.

### assets
- `assets.textureSize(path)` → `{ width, height }` (same shape as `ui.measureText`): the pixel size of the texture file at
  the project-relative `path`, for example `assets.textureSize("assets/hero.png")`. It is the size a `Sprite` without
  `size` or `region` is drawn at and the one `entity.bounds()` uses. A missing or unreadable file gives 32 × 32 (the size
  of the missing-texture checker). It reads the file, so it works headless; the result is cached per file and
  modification time, so calling it every frame is cheap. An empty or non-string `path` throws.

### scene / game / storage
- `scene.load(path)` (deferred to frame end) · `scene.reload()` · `scene.current`
- `game.quit()` · `game.paused` · `game.project` (read-only factoria.json) · `game.screenSize`
- `storage.get(key, fallback)` · `storage.set(key, value)` · `storage.remove(key)` — persistent JSON save data
  (`<user dir>/storage.json`). Tests always use an empty in-memory storage per test file and never touch the real
  save; the runtime can run headless with `ScriptSystem::set_storage_mode(StorageMode::Memory)`.

### rng (deterministic, seeded per run)
`rng.seed(n)` reseeds the world RNG (seed → level determinism from tools/tests) · `rng.float()` [0,1) · `rng.range(a, b)` · `rng.int(a, b)` (inclusive) · `rng.chance(p)` · `rng.pick(array)` · `rng.shuffle(array)` (a shuffled copy)

`rng` is the ONE random stream of the running game, and `Math.random()` draws from it too. Reseeding it changes what
the game does next, and a script cannot read its state to restore it. A generator that must be repeatable from a seed
(a level generator tool, a name or loot table) therefore uses its own generator:

```js
import { rng } from "factoria";

const r = rng.create(42);              // independent: never touches the world RNG
const width = r.int(30, 60);           // 30..60 inclusive
const hill = r.chance(0.3);
const order = r.shuffle(["a", "b", "c"]);
r.seed(42);                            // start over; same as rng.create(42)
```

`rng.create(seed)` returns a generator with the same methods as `rng` (`float`, `range`, `int`, `chance`, `pick`,
`shuffle`, `seed`). Using it never changes `rng.float()` or `Math.random()`, and two generators never share state.

- **Algorithm (stable).** mulberry32: a 32-bit state that advances by `0x6d2b79f5` per draw, mixed to a 32-bit
  integer; `float()` is that integer divided by 2^32, so it is in [0, 1). The algorithm and the draws each method
  uses are guaranteed not to change between engine versions, so a stored seed keeps producing the same level on every
  platform. A change would be a breaking change of the engine.
- **Draws per call.** `float`, `range`, `int` and `chance` draw once. `pick` draws once (not at all for an empty
  array). `shuffle` draws `length - 1` times (Fisher-Yates from the end). A call always draws the same number of
  times whatever its arguments are (`int(5, 5)` still draws), so the sequence does not depend on the arguments.
- `int(min, max)` is `min + floor(float() * (max - min + 1))` with both ends inclusive and truncated to integers; it
  returns `min` when `max <= min`. `range(min, max)` is `min + (max - min) * float()`. `chance(p)` is `float() < p`
  (default 0.5). `pick(items)` is `items[floor(float() * items.length)]`.
- **Seed.** A finite number, reduced to 32 bits (`seed >>> 0`: the integer part, modulo 2^32). `0` is valid, `1` and
  `4294967297` give the same sequence, and so do `1` and `1.9`. A non-number or `NaN` throws an error that shows an
  example.
- 32 bits of state means a period of 2^32 draws: plenty for a level or a table, not meant for cryptography.

### math & values
- `vec2(x, y)`, `vec3(x, y, z)`, `color(r, g, b, a?)` / `color("#ffcc00")`
- `Vec2`/`Vec3` methods: `add sub mul scale div dot length lengthSq normalized distance lerp clone equals`,
  `Vec2.fromAngle(deg)`, `v.angle()`, `v.rotated(deg)`
- `math`: `clamp lerp inverseLerp remap damp moveTowards approach sign degToRad radToDeg wrapAngle`
- `console.log/warn/error` go to the engine log (category `script`).

### fa (commands)
`fa.call(name, args)` runs any command (same as MCP tools) and returns its result · `fa.commands()` lists them.
On failure `fa.call` throws an `Error` whose message is `<name> failed: <message> (hint: <hint>)` and which also
carries `e.code`, `e.hint` and, when the command reported structured details, `e.data`: a project tool that throws
`ToolError(message, hint, data)` gives the caller `e.code === "tool_error"` and `e.data === data`, so a test can assert
on the data instead of parsing the message.

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
(how to fix the data, not the tool) and, if given, `data` (any JSON). `data` travels as the structured field `error.data`
(MCP and `factoria call` print it next to the message; it is not appended to the message). Any other thrown Error is a script bug: code `failed`, the message with `file:line`, and it is
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
  toBeLessThanOrEqual toBeTruthy toBeFalsy toBeNull toBeDefined toContain toHaveLength toThrow`, and `.not`;
  for sounds `expect(game.audioLog()).toContainPlayed(path, { times?, bus?, source? })` (alias `toHavePlayed`; `path`
  is a project path, a file name such as `"jump.wav"`, or a RegExp; plays whose clip failed to load do not count)
- `game`: `load(path)` (behaviours are constructed immediately, `onStart` runs on the first `step`),
  `loadJson(sceneObject)`, `step(frames = 1)`, `touch(pos, frames = 1)`, `touchStart(pos, id?)`, `touchMove(pos, id?)`,
  `touchEnd(id?)` (fill `input.touches`; `pressed` is true for the frame after `touchStart`; like a finger on a device,
  the first finger also moves the mouse and holds the left button, so `touch` alone tests mouse handling too: no
  `click` needed), `press(action)`, `release(action)`, `tap(action)`,
  `keyDown(key)`, `keyUp(key)`, `gamepad(index = 0)`, `mouseMove(screenPos)`, `click(screenPos, button?)`, `find(idOrName)`,
  `world`, `time`, `screenshot(path)`, `state()`, `audioLog()` (sounds played since the test started:
  `[{ seq, frame, time, path, volume, pitch, pan, bus, loop, music, source, ok }]`, cleared before each test),
  `clearAudioLog()`

`game.gamepad(index = 0)` drives a pad: `press(button)`, `release(button)`, `tap(button)` (press, step, release, step, like
`game.tap`), `axis(name, value)`, `connect()` and `disconnect()`. Like `keyDown`, `press`, `release` and `axis` act at once and
the next `game.step` sees them; they connect the pad. Actions bound to `Gamepad*` names react as they do to a real pad:

```js
test("the stick moves the player", () => {
  game.load("scenes/main.scene.json");
  game.gamepad(0).axis("LeftX", 1);        // a full push right: input.axis("move_left", "move_right") is 1
  game.step(30);
  expect(game.find("player").position.x).toBeGreaterThan(0);
  game.gamepad(0).tap("A");                // jump
});
```

Bad button or axis names and indices outside 0..3 throw with a "did you mean".

Each test FILE starts from fresh module instances (module-level state is
re-created, tools are re-evaluated against them), an empty in-memory `storage`
(the real save file is never read or written) and an empty `session`. Within a
file, state carries over between tests unless you reset it.

Tests run inside the current engine (only one renderer can exist per
process). Between test files the runner reloads the project's start scene,
reseeds the world RNG with the project seed, clears input overrides, timers and
behaviours; `game.load` also reseeds. Before each test input overrides, the gamepads (unplugged),
`input.deadzone` (back to the project's value), `time.scale` and the audio log are reset. Results are deterministic. Extras: `describe.skip`,
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
