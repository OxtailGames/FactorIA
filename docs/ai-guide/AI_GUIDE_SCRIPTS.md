# AI guide: scripts and the first recipes

Part of [AI guide](../AI_GUIDE.md): the JavaScript API (section 8) and recipes 9.1 to 9.7: platformer, top-down, spawning, HUD, collisions, camera, sounds.

## 8. Scripts: behaviours and the JavaScript API

A behaviour is an ES module whose default export extends `Behaviour`. All methods are optional:

| Method | When it runs |
|---|---|
| `onStart()` | Once, the first time the entity is active, before its first update. `props` are already applied. |
| `onEnable()`, `onDisable()` | Every time the entity (or an ancestor) becomes active / inactive, before the frame is drawn. The first `onEnable` follows `onStart`. A panel refreshes its texts in `onEnable`. |
| `onUpdate(dt)` | Every frame. `dt` is in seconds, scaled by `time.scale`. While `time.scale` is 0 (`game.paused`) only behaviours with the class field `runWhilePaused = true` get it, with the real `dt` (pause menus). |
| `onFixedUpdate(dt)` | Every fixed step, before physics. Use it for movement that physics must see. A frame runs 0 to 5 steps, but a press or release (`input.pressed`, `keyPressed`, `mouse.pressed`, `released`, `touches[].pressed`, gamepad edges) reaches exactly ONE `onFixedUpdate` (the first step after it happened; one that arrives in a frame with no step waits for the next) and exactly ONE `onUpdate`, so read one-shot input in either hook. Details in `docs_read {"name":"scripting"}`, "Which callback sees what (input)". |
| `onLateUpdate(dt)` | After all updates. Use it for cameras that follow targets. |
| `onDestroy()` | Before the entity is removed. |
| `onCollisionEnter(other, info)`, `onCollisionExit(other)` | Solid contacts. `info` is `{point, normal, impulse}`. |
| `onTriggerEnter(other)`, `onTriggerExit(other)` | Overlaps with trigger colliders. |
| `onEvent(name, data, source)` | Any `world.emit` event. |

Timing you can rely on:

- The behaviour object exists as soon as its entity does: right after `world.spawn`, `spawnPrefab`, a scene load or `game.load`. So `world.spawn(...).behaviour` and `game.find("id").behaviour` are usable at once. `onStart()` runs at the start of the next step. This holds for inactive entities too (`behaviour` of a panel spawned with `active: false` is its instance); their hooks run when they are first activated.
- Physics bodies are created by the first physics step. In the first `onFixedUpdate` after a spawn or a load, `physics.raycast` finds nothing and `isTouching` is false. Skip the first two fixed steps before you probe (section 9.14).
- `Script.props` keys that are not fields of the class are reported once (in the log and by `factoria validate`), with a "did you mean" hint. Declare every tunable as a class field.
- Hooks are called by their exact names (`onStart`, `onUpdate`, ...). A method named `start()`, `update()` or `onupdate()` (no arguments) is never called; it is reported once (in the log and by `factoria validate`) with a "did you mean".

Inside a behaviour: `this.entity` (the owning entity), `this.world`, `this.after(seconds, fn)` and `this.every(seconds, fn)` (timers that stop when the entity is destroyed; both return a handle with `.cancel()`), `this.on(name, fn)` (an event listener), and `this.enabled` (false skips the update callbacks).

Entity members: `id`, `name`, `tags`, `active`, `alive`, `transform`, `position`, `worldPosition`, `bounds()` (the world rectangle of its 2D visual, section 9.6), `get(name)` (a live view, or `null`), `add(name, fields)`, `set(name, fields)`, `has`, `remove`, `destroy()` (deferred to the end of the frame), `hasTag`, `addTag`, `removeTag`, `parent`, `children`, `setParent`, `behaviour`, `send(method, ...args)`, `isGrounded(tolerance?)` (2D pixels or 3D meters), `isTouching(direction, tolerance?)`, `emitBurst(count)` and `toJSON()`.

`entity.isTouching([1, 0])` is true when a solid body touches this entity on the right; `[-1, 0]` is left, `[0, -1]` is the ground below, `[0, 1]` the ceiling. Triggers never count.

The most-used members of the `"factoria"` module. The full list is in `docs_read {"name":"scripting"}`:

| Import | Members |
|---|---|
| `world` | `find(idOrName)`, `findAll(name)`, `findByTag(tag)`, `entities()`, `spawn(json, {position, rotation, scale, parent, index, props})`, `spawnPrefab(path, {position, rotation, scale, parent, index, props, overrides, childOverrides})`, `emit(name, data)`, `on(name, fn)` (returns an unsubscribe function) |
| `input` | `pressed(a)`, `down(a)`, `released(a)`, `axis(negative, positive)`, `vector(left, right, down, up)`, `keyDown("Space")`, `keyPressed`, `keyReleased`, `mouse` (`position`, `world`, `delta`, `wheel`, `down("left")`, `pressed("left")`), `touches` (`[{id, position, world, pressed}]`); `player(i)` (local multiplayer: `use({pad})` / `use({keys})`, then `down`, `pressed`, `value`, `axis`, `vector`, `rebind`, `export`, section 9.28); options menus: `actions()`, `bindings(a)`, `rebind(a, [names])`, `resetBindings(a?)`, `lastPressed()` (what went down this frame, for "press a key"), `lastDevice`, `buttonName(bindingOrAction, pad?)` ("Cross" on a PlayStation pad), `gamepad(i).type`, `text` (typed this frame), `showKeyboard(on?)`, `onBack(fn)` (the Back button: return `false` to pass it on; unconsumed it quits), `vibrate(seconds?)`, `mouse.visible`, `mouse.locked` (details in `docs_read {"name":"scripting"}`) |
| `screen` | `safeArea` (a `Rect` in design pixels: what a phone's notch, rounded corners and system bars leave free; the whole screen on desktop and headless), `insets` (`{left, top, right, bottom}`), `size`. Put `safeArea: true` beside `anchor` on a Sprite, Shape2D, Text, ParticleEmitter or UI widget to anchor it to the safe area. Test with `game.setSafeArea("phone-portrait")` / `screen_set_safe_area` (`docs_read {"name":"mobile"}`) |
| `window` | `available`, `fullscreen` / `setFullscreen(on)`, `size` / `setSize(w, h)`, `displaySize`, `resolutions()`, `vsync` / `setVsync(on)`, `frameCap` (0 or 15..1000). Getters work everywhere; setters need a real window (not headless, not tests) and throw a teaching error otherwise, so check `window.available`. Phones and tablets are always full screen. Save the choice with `storage` |
| `audio` | `play(path, {volume, pitch, pan, loop, bus})` (bus defaults to `"sfx"`), `stop(id)`, `stopAll()`, `music(path, {volume, fade})`, `stopMusic(fade)`, `setVolume(bus, v)`, `getVolume(bus)` |
| `physics` | `raycast(from, to, {mask, ignore, ignoreTriggers})`, `raycast3d(origin, dir, maxDistance, {mask, ignore, ignoreTriggers})`, `shapeCast(shape, from, to, {mask, ignore, ignoreTriggers})`, `overlapCircle(center, r, {mask})`, `overlapBox(rect, {mask})`, `overlapSphere(center, r, {mask})`, `applyImpulse`, `applyForce`, `setVelocity`, `moveCharacter(entity, delta)` |
| `time`, `camera`, `debug` | `time.dt`, `time.fixedDt`, `time.elapsed`, `time.scale` (0 = paused: physics, particles, animators, timers and `onUpdate` stop; audio and the UI go on), `time.unscaledDt`; `camera.main`, `camera.all`, `camera.at(point)`, `worldToScreen(v, camera?)`, `screenToWorld(v, depth?, camera?)`, `screenRay(point, camera?)` (with several cameras they default to the camera under the point, section 9.29); `debug.line`, `debug.rect`, `debug.circle`, `debug.text`, `debug.box`, `debug.sphere`, `debug.bones(root?)` (the `Bone2D` skeleton, docs/ANIMATION.md "Bones and IK") |
| `scene`, `game`, `storage` | `scene.load(path)` (deferred to the end of the frame), `scene.current`; `game.quit()`, `game.paused` (= `time.scale` 0), `game.project`, `game.screenSize`, `game.platform` (`"windows"`, `"android"`...), `game.notices()` (the runtime's third-party parts, for credits); `storage.get(key, fallback)`, `storage.set(key, value)`, `storage.remove(key)` |
| `session` | A plain object that survives scene loads for the whole run (section 9.15) |
| `rng`, `math` | `rng.seed(n)`, `rng.float()`, `rng.range(a, b)`, `rng.int(a, b)`, `rng.chance(p)`, `rng.pick(array)`, `rng.shuffle(array)` (all draw from the ONE world RNG); `rng.create(seed)` returns an independent seeded generator with the same methods, for generators and tools (section 9.16); `math.clamp`, `lerp`, `damp`, `moveTowards`, `degToRad` and others |
| `platform` | Store and platform services, every call a Promise: `platform.has("purchases")`, `achievements.unlock(id)`, `stats.add(id, n)`, `leaderboards.submit(id, score)`, `cloud.save(key, value)`, `purchases.buy(id)` / `finish(transactionId)` / `restore()`, `on("purchase" \| "overlay" \| "player", fn)`; ids are declared in `factoria.json` `"platform"`. In tests the fake store answers and `game.platform` (from `factoria:test`) controls it. Details: `docs_read {"name":"platform"}` |
| `particles`, `ui` | `particles.burst(entity, count)`; `ui.measureText(text, {fontSize, font, maxWidth, space, markup, bold})` returns `{width, height}`; `Text.markup` reads `[b]`, `[i]`, `[c:name]` and `[icon:name]`; `Text.font` takes `"builtin:serif"` (book serif with real bold and italic), `"builtin:hand"`, `"builtin:blackletter"`, `"builtin:display"` or `"builtin:pixel"` (`docs_read {"name":"text"}`, "Built-in fonts") (project `text` section, `ui.markupProblems(text)`; `docs_read {"name":"text"}`); `ui.layout()` runs the UI layout now (read `Button.size` / `ui.rectOf` right after changing a text); `ui.textScale` (0.5 to 3, not saved) is the player's text size option for screen-space Text and widget labels (`docs_read {"name":"text"}`); `ui.scale` (0.5 to 3, default from `factoria.json` `"ui": {"scale"}`, not saved) makes every screen-space widget and Text bigger or smaller, and `ui.on("scale" \| "textScale", fn)` runs when either changes; `tooltip` on a widget or Panel (a key, text or `{title, lines}`), `ui.setTooltip(entity, fn)`, `ui.showTooltip(content, {x, y})`, `ui.tooltip` and `"ui": {"tooltipDelay", "tooltip"}` in `factoria.json` make hover tooltips (`docs_read {"name":"menus"}`, "Tooltips"); `draggable` on a widget, `ui.on("dragStart" \| "dragOver" \| "drop" \| "dragCancel", fn)`, `ui.setDropTarget(widget, rule)`, `ui.setDragImage(widget)`, `ui.dragging` and `game.drag(from, to)` make drag and drop (`docs_read {"name":"menus"}`, "Drag and drop"); a `Chart` component draws `values` as bars or lines (automatic axis including zero, labels in the language's number format) and `ui.on("chartHover", fn)` reports the sample under the pointer (`docs_read {"name":"menus"}`, "Charts"); `ui.speak(text, {interrupt})` says a line with the system's text to speech in `i18n.language` (`ui.stopSpeaking()`, `ui.speechAvailable`; tests record the lines in `game.spoken()`; recipe and manual check in `docs_read {"name":"menus"}`) |
| `vfx` | `vfx.play("assets/vfx/hit.vfx.json", {position, entity, rotation, scale, speed, loop})` returns the entity that plays the effect (`null` when 64 already play); `vfx.stop(entity, {immediate})`; `vfx.playing()` lists the effects that play now | Play an effect document (section 9.12; `docs_read {"name":"particles"}`, "Effect documents"). A file with errors throws with the file, the JSON pointer and the fix. |
| `assets` | `assets.textureSize("assets/hero.png")` returns the texture file's pixel size `{width, height}` (32 x 32 for a missing file); works headless |
| `vec2`, `vec3`, `color` | constructors, for example `vec2(10, 0)`, `vec3([0, 4, 9])` or `color("#ffcc00")` |
| `ToolError` | `new ToolError(message, hint, data?)` for a failed check in a tool (section A of `docs_read {"name":"extending"}`) |
| `fa` | `fa.call(name, args)` runs any command; on error it throws an Error with `code`, `hint` and, for a tool's `ToolError(message, hint, data)`, `data`; `fa.commands()` lists them |

Options worth knowing:

- `world.spawn(json, {parent})` makes the new entity a child. `parent` is an Entity or an id string, and `position` is then local to the parent. An Entity field (`Interactable.knob` / `fill`, `Joint2D.connected`...) that names an id spawned LATER is left empty with a warning and filled when that entity appears; ids inside the same spawn (`children`) resolve at once.
- `raycast` and `shapeCast` options: `mask` (layer bits), `ignore` (an Entity or id whose colliders are skipped, including its children), `ignoreTriggers` (default true). Colliders that already contain the ray origin (or overlap the cast shape at its start) are skipped too. The commands `physics.raycast` and `physics.shape_cast` take the same three options (`ignore` is an entity id or name there).
- `input.touches` entries: `id` (the finger), `position` (Vec2, design pixels, top-left origin), `world` (Vec3 in the world through the camera under the finger: the main camera when there is only one) and `pressed` (true only on the first frame of contact). The first finger also drives the mouse (`input.mouse.position`, left button down while it is down), on a phone and in tests (`game.touch`) alike: read the mouse OR the touches for a tap, or make the second reading harmless.
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

**Moving platform (2D).** A platform is a `RigidBody2D` with `"type": "kinematic"` (plus a `Collider2D`) whose script sets `velocity` each frame (a sine for a swing, a constant for a lift). A `dynamic` body resting on top of it is carried along, also when its own script sets `velocity.x` every frame (a platformer player that writes `velocity.x = 0` without input stays put on the platform). For a body that is carried, `RigidBody2D.velocity` is relative to the platform: it reads 0 while it stands still on it, and `velocity.x = 6` walks 6 units per second relative to the platform. A body that is not touching the platform from above (jumping, falling) is not carried. Moving the platform by writing its `Transform.position` is a teleport and carries nothing: set `velocity`. Verified: a player writing `velocity.x = 0` every frame stayed within 1 px of its place on a platform that swung 96 px in 100 frames. The player script needs no ray-cast or speed bookkeeping.

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

To spawn without a prefab, pass the entity object itself (the 2d-platformer template's `tools/spawn_coin.js` spawns its coin from `prefabs/coin.prefab.json` instead):

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

`props` in the spawn options is merged into the entity's `Script.props`. `destroy()` is deferred to the end of the frame, but the entity leaves physics at once (no collisions, no raycast or overlap hits), so you may destroy rigid bodies and spawn replacements at the same positions in the same frame. Destroy the entities you no longer need, so that spawners do not fill the scene.

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

Children of a Panel are placed from the parent's `Transform.position`: a child's screen position is that position plus the child's own `position` and the point named by the child's own `anchor`. The parent's `anchor` and `pivot` only place the parent's rectangle; they do not move its children, so a Panel with `anchor: [0.5, 0.5]` and `Transform.position` `[0, 0]` has its children at the top-left corner of the screen unless a layout (`layout: "column"`...) or the children's own anchors place them. In a Shape2D with `space: "screen"`, a `line`'s `size.y` points UP (a line `[100, 40]` goes 100 px right and 40 px up) while Panels, Texts and Sprites grow downwards. A chart bar is a rectangle with `pivot: [0, 1]` that hangs from its position: `size: [w, h]` is w to the right and h down.

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

The camera stays inside the level rectangle. Take that rectangle from the level's `Tilemap` with `entity.bounds()` instead of copying the map size into props, so the limits cannot drift from the map. The camera script gets the id of the Tilemap entity:

```js
// scripts/follow_camera.js
import { Behaviour, math } from "factoria";

export default class FollowCamera extends Behaviour {
  target = "player";
  bounds = "map";    // id of the level's Tilemap entity; "" = no limits
  smoothing = 8;     // higher is snappier

  clampPos(x, y) {
    const area = this.bounds ? this.world.find(this.bounds)?.bounds() : null; // { x, y, w, h } or null
    if (!area) return [x, y];
    const halfW = 640, halfH = 360; // half of the 1280x720 design size (orthoSize 0)
    // A level smaller than the view has an empty clamp range: centre on the level instead.
    const cx = area.w <= 2 * halfW ? area.x + area.w / 2 : math.clamp(x, area.x + halfW, area.x + area.w - halfW);
    const cy = area.h <= 2 * halfH ? area.y + area.h / 2 : math.clamp(y, area.y + halfH, area.y + area.h - halfH);
    return [cx, cy];
  }

  onLateUpdate(dt) { // after all updates, so the target has already moved
    const t = this.world.find(this.target);
    if (!t) return;
    const [tx, ty] = this.clampPos(t.position.x, t.position.y);
    const p = this.entity.position;
    p.x = math.damp(p.x, tx, this.smoothing, dt);
    p.y = math.damp(p.y, ty, this.smoothing, dt);
  }
}
```

In the scene the camera entity has `"Script": { "path": "scripts/follow_camera.js", "props": { "target": "player", "bounds": "map" } }`, where `map` is the id of the Tilemap (the entity `scene.import_ascii` writes, section 9.8).

`bounds()` returns `{ x, y, w, h }` in world units: `(x, y)` is the BOTTOM-LEFT corner (+Y up), `x + w` is the right edge and `y + h` the top edge, the same `Rect` that `physics.overlapBox` takes. For a Tilemap it is the map size (`width` x `height` tiles, or the rows) times `tileSize`, placed by the entity's transform; the entity position is the map's top-left corner. A map imported with `anchor: "bottom-left"` at `[0, 0]` gives `{ x: 0, y: 0, w: columns * tileSize, h: rows * tileSize }`. Resize or move the map and the camera limits follow. It also works for a `Sprite` (a background picture) or a `Shape2D` (an arena floor). It returns `null` for an entity without a world-space 2D visual (an empty map, a `space: "screen"` item); the script above then does not clamp. Calling it every frame is fine.

A level that is not a Tilemap keeps its rectangle in a JSON file that the script imports (section 9.16): `import levels from "../data/levels.json"` with `{ "bounds": { "minX": -640, "minY": -360, "maxX": 1000, "maxY": 720 } }`, and the same clamp with those numbers.

### 9.6.1 A strategy camera (drag, edges, wheel zoom to the cursor)

A management, strategy or builder game needs a camera the player moves: drag to pan, the screen edges and WASD scroll, the wheel zooms towards the cursor, and the view never leaves the map. Two ways, both on an orthographic camera that is not rotated:

1. The kit's behaviour. `project.add_menu_kit {"parts":["cameraRig"]}` copies `scripts/camera_rig.js` (and its test) and adds the input actions `camera_drag` (middle button), `camera_left/right/up/down` (WASD and arrows) and `camera_zoom_in/out` (PageUp/PageDown, =/-). Put the script on the camera entity: `"Script": { "path": "scripts/camera_rig.js", "props": { "boundsEntity": "map", "zoomMin": 0.4, "zoomMax": 2.5, "startZoom": 1, "margin": 100 } }`. `boundsEntity` is the id of the Tilemap or background Sprite whose `bounds()` limits the view (section 9.6; "" = no limit), `zoomMin` and `zoomMax` are pixels per world unit, `edgeSize` the width of the scrolling zone at the screen edge (0 = off), `panSpeed` pixels per second. It ignores a wheel turn and a new drag over a widget or Panel (`ui.pointerOverUi`) and the wheel a ScrollList scrolled (`ui.wheelConsumed`); a modal that the UI does not know about sets `rig.wheelBlocked = true`. A script can call `rig.setView(x, y, zoom)`, `rig.moveTo(x, y, zoom)` (eased; `rig.instantMoves = true` jumps, for a "reduced motion" option), `rig.setBounds({ x, y, w, h })`, `rig.screenToWorld(sx, sy)` and read `rig.view` (`{ x, y, zoom }`). Extend the class to change the controls (override `pointer()`, `updateDrag()`, `edgePanAllowed()` or `onInput()`; Tidewater Market's `scripts/game/map_camera.js` adds a gamepad cursor and click-to-latch drag that way).
2. The helpers, for your own script. `camera.zoomAt(screenPoint, factor, { min, max })` multiplies the zoom (pixels per world unit) and moves the camera so the world point under `screenPoint` stays put; `camera.panBy(screenDelta)` moves the world with a drag; `camera.clampTo(rect, { margin })` keeps the view inside a rectangle (centred when the rectangle is smaller than the view); `camera.zoomOf()`, `camera.setZoom(zoom)` and `camera.orthoSizeFor(zoom, designHeight)` convert between the zoom and `Camera.orthoSize` (= design height / 2 / zoom), so you never do that division by hand.

```js
// wheel zoom to the cursor, middle-button drag, clamped to the map (a camera script)
onUpdate() {
  if (!ui.pointerOverUi && input.mouse.wheel !== 0) camera.zoomAt(input.mouse.position, 1.15 ** input.mouse.wheel, { min: 0.4, max: 2.5 });
  if (input.mouse.down("middle")) camera.panBy(input.mouse.delta);
  const map = world.find("map").bounds();
  if (map) camera.clampTo(map);
}
```

The helpers change the camera at once, but `camera.screenToWorld` answers for the last drawn frame: after a change in the same frame use the rig's `screenToWorld(sx, sy)`, or step a frame in a test.

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

A scene load stops every sound and the music, and then starts the new scene's `settings.music` (the same track again when both scenes name it). Music that should play across scenes (a menu theme into the first level) is started by a script with `audio.music(path, { persist: true })`: it survives scene loads, and a scene whose `settings.music` is the same track does not restart it.

Change a sound while it plays with `audio.setVoiceVolume(id, volume, fadeSeconds)` (`id` from `audio.play`; wind that swells, an engine hum). For music in layers (drums that come in when the fight starts) use `audio.musicLayers({ base: "assets/music/base.ogg", drums: "assets/music/drums.ogg" }, { levels: { drums: 0 } })` and then `audio.setLayer("drums", 1, 2)`: the layers start on the same sample and stay in step while they loop, as long as the clips have the same length.

Make the mix follow the game with bus effects (SCRIPTING.md, "Audio buses"). Music that ducks under every sound effect, and a muffled underwater level:

```js
audio.bus("music").duck("sfx", 0.5);              // music at half volume while any sound effect plays
audio.bus("music").lowpass(600).reverb(0.2);      // muffled music in a room
audio.bus("music").lowpass(null, { fade: 1 });    // opens again over a second
```

For a state that changes several buses at once, name it in factoria.json and apply it by name (a bus the snapshot does not list goes back to neutral, so `"normal": {}` is the way back):

```json
"audio": { "snapshots": {
  "underwater": { "fade": 0.8, "buses": { "sfx": { "lowpass": 600, "reverb": 0.3 }, "music": { "volume": 0.5, "lowpass": 400 } } },
  "normal": {} } }
```

```js
audio.snapshot("underwater");                     // or audio.snapshot("underwater", { fade: 2 })
audio.snapshot("normal");                         // when the player surfaces
```

Group sounds on a bus of your own under a parent (`"audio": { "buses": { "ambience": { "parent": "sfx" } } }`), play on it with `audio.play(clip, { bus: "ambience" })` and set it with `audio.setVolume("ambience", 0.5)`; its parent scales it too (SCRIPTING.md, "Project buses"). `audio.play` takes `onEnded` and `audio.activeVoices()` lists what plays.

Effects stay across scene loads, like volumes, so apply `normal` when you leave. `project_validate` checks the catalog (a misspelled bus or key gets a "did you mean"). To check it from outside, call `audio_bus {"bus":"music"}` or `audio_snapshot {}`; the mix is deterministic, so `factoria run --headless --record-audio out.wav` records what the effect does.

Long sounds (over 10 seconds, so music) stream by themselves: a 3-minute track costs about 40 KB of decoded audio instead of 60 MB, so do not split music into pieces to save memory. To make every sound equally loud, put `"audio": {"normalize": true}` under `defaults` in `assets.json` (section 9.23).

`project_validate` checks the asset fields of the scene (for example `Sprite.texture`, `AudioSource.clip` and `Script.path`), but not paths written in code. A missing file passed to `audio.play` shows up in `game_logs`.

To check that a sound really fires, read the play log: in a test, `expect(game.audioLog()).toContainPlayed("jump.wav")` (section 10); from MCP or the CLI, `audio_log` after `game_step`. A play whose clip failed to load is in the log with `ok: false` and does not count as played.
