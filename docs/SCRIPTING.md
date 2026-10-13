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
| `isGrounded()` | 2D physics: touching ground below |
| `toJSON()` | entity JSON (as in scene files) |

Component views expose exactly the reflected fields listed by `factoria api
components` (also `docs/COMPONENTS.md`). Vector/color fields are live views
(`v.x = 1` writes into the engine); enums are lowercase strings
(`body.type = "kinematic"`); asset fields are path strings; JSON fields
(`Tilemap.tiles`, `Script.props`) are plain objects — assign a new value to
write.

## Modules

Everything is imported from `"factoria"`:

```js
import { Behaviour, world, input, audio, physics, time, camera, debug, scene, game,
         storage, rng, fa, vec2, vec3, color, Vec2, Vec3, Color, math } from "factoria";
```

### world
- `find(idOrName)` → Entity | null · `findAll(name)` · `findByTag(tag)` · `entities()`
- `spawn(entityJson)` → Entity (same format as scene files; `{ name, tags, components: {...} }`)
- `spawnPrefab(path, { position, rotation, parent, overrides })` → Entity
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
- `raycast(from, to, { mask })` → `{ entity, point, normal, distance } | null` (2D when given Vec2)
- `raycast3d(origin, dir, maxDistance)` · `overlapCircle(center, r)` · `overlapBox(rect)` · `overlapSphere(center, r)`
- `applyImpulse(entity, v)` · `applyForce(entity, v)` · `setVelocity(entity, v)`

### time
`dt`, `fixedDt`, `elapsed`, `frame`, `scale` (writable; 0 pauses gameplay).

### camera
`main` (primary camera Entity), `worldToScreen(v)`, `screenToWorld(v)`.

### debug
`line(a, b, color?)`, `rect(x, y, w, h, color?)`, `circle(center, r, color?)`, `text(screenPos, str, color?)`.

### scene / game / storage
- `scene.load(path)` (deferred to frame end) · `scene.reload()` · `scene.current`
- `game.quit()` · `game.paused` · `game.project` (read-only factoria.json) · `game.screenSize`
- `storage.get(key, fallback)` · `storage.set(key, value)` · `storage.remove(key)` — persistent JSON save data

### rng (deterministic, seeded per run)
`rng.float()` [0,1) · `rng.range(a, b)` · `rng.int(a, b)` (inclusive) · `rng.chance(p)` · `rng.pick(array)`

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
- `game`: `load(path)`, `step(frames = 1)`, `press(action)`, `release(action)`, `tap(action)`,
  `keyDown(key)`, `keyUp(key)`, `mouseMove(screenPos)`, `click(screenPos, button?)`, `find(idOrName)`,
  `world`, `time`, `screenshot(path)`, `state()`

Each test file runs in a fresh engine instance with the project's seed, so
results are deterministic.
