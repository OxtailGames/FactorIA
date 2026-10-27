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

This holds for **inactive** entities too: a panel spawned with `active: false`
already has its `.behaviour` (a never-shown panel can be configured by whoever
spawns it). Only its hooks wait: `onStart` runs the first time the entity is
active in the hierarchy (`active = true` on it or on an ancestor).

### Activation order
For each behaviour, in creation order:
1. First activation: `onStart()`, then `onEnable()`. So `onEnable` can rely on
   what `onStart` set up.
2. Every later `active = true` (or re-enabling the Script): `onEnable()`.
3. Every `active = false` (of the entity or any ancestor) or `Script.enabled =
   false`: `onDisable()`.
4. Destroying an entity that is active: `onDisable()`, then `onDestroy()`.

The hooks run at the start of the next callback phase of the frame and at the
latest at the end of the frame, **before it is drawn**: a panel shown by a script
(`MenuStack.show`, `panel.active = true`) never draws its prefab texts, because
`onEnable` already refreshed them. If `onStart` itself deactivates the entity,
`onEnable` is skipped. Changes made by an `onEnable`/`onDisable` hook are settled
in the same pass (bounded to 8 rounds). The order is deterministic (behaviour
creation order). Hot reload re-creates the behaviour without calling
`onDisable`/`onDestroy`, like `onDestroy`.

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
| `onStart()` | once, the first time the entity is active, before its first update and before the frame is drawn (props already applied) |
| `onEnable()` | every time the entity becomes active in the hierarchy (first time: right after `onStart`), before the frame is drawn |
| `onDisable()` | every time it stops being active, and before `onDestroy` of an active entity |
| `onUpdate(dt)` | every frame, `dt` in seconds (scaled by `time.scale`; not called while it is 0 unless `runWhilePaused`) |
| `onFixedUpdate(dt)` | every fixed step (default 60 Hz), before physics |
| `onLateUpdate(dt)` | after all updates (cameras following targets) |
| `onDestroy()` | before the entity is removed |
| `onCollisionEnter(other, info)` / `onCollisionExit(other)` | physics contacts; `info = { point, normal, impulse }` |
| `onTriggerEnter(other)` / `onTriggerExit(other)` | overlaps with trigger colliders |
| `onEvent(name, data, source)` | any `world.emit` event (also `world.on(name, fn)`) |

The engine calls these by their exact names. A method that looks like a hook but
is not one (`start()`, `update()`, `fixedUpdate()` without the `on`, or a
near-miss such as `onupdate()` or `onStrat()`; a method that takes arguments, like `start(seconds)`, is a normal
method of the class and is not reported) is never called: the first
behaviour of the class created logs ONE warning per such method with a "did you
mean", and `factoria validate` reports the same for every behaviour script (under
`scripts/` or named by a `Script.path`). Helpers with other names (`loadLevel()`)
are not affected.

A class **field** with the name of a `Behaviour` member (`on`, `after`, `every`, `world`) replaces that member for the
instance: `on = false;` makes `this.on("x", fn)` fail. The first behaviour of the class created logs ONE warning naming the
field, and `factoria validate` reports it too; rename the field (`tradeOn`).

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
| `position` | shortcut for `transform.position` (assignable: `e.position = vec2(10, 0)`). On an entity with a physics body (2D or 3D) it teleports the body (also when it was asleep: it wakes, with whatever touches it, and falls from the new place), and `isGrounded()` reflects the new place after the next physics step |
| `worldPosition` | world-space position (get/set) |
| `bounds()` | world-space rectangle of the entity's 2D visual, `Rect \| null` (see below) |
| `get(name)` | live view of a component or `null` (`e.get("Sprite").color.a = 0.5`) |
| `add(name, fields?)` | adds (or returns) a component, applies `fields` |
| `set(name, fields)` | patches fields (adds if missing) |
| `has(name)`, `remove(name)` | |
| `destroy()` | deferred to end of frame (children too); leaves physics at once (see below) |
| `parent`, `children`, `setParent(e, keepWorld?, index?)` | hierarchy; `index` puts it at a place among the new parent's other children (0 = first, up to the number of those others = last; omitted = last), also within the same parent. A negative, fractional or too large index, or an index without a parent, throws. Layout containers follow this order |
| `hasTag(t)`, `addTag(t)`, `removeTag(t)` | tags |
| `behaviour` | the script instance attached to it (or `null`) |
| `send(method, ...args)` | calls `behaviour[method](...args)` if it exists |
| `isGrounded(tolerance?)` | 2D or 3D physics: standing on something (contact normal up) |
| `isTouching(direction, tolerance?)` | solid contact against the body on that side: `isTouching([1, 0])` = wall on the right, `[0, 1]` = ceiling (2D or 3D by body type) |
| `animator` | skeletal animation of this entity's `Animator` component: `play(clip, fade?)`, `stop()`, `set(name, value)`, `get`, `trigger`, `clips`, `duration(clip)`, `on(event, fn)`, `state`, `speed`, `time` (throws without an Animator; see [ANIMATION.md](ANIMATION.md)) |
| `tilemap` | this entity's `Tilemap`: `getTile(col, row)` (-1 = empty or outside), `setTile(col, row, id)`, `cellAt(point)`, `cellToWorld(col, row)`, `width`, `height` (throws without a Tilemap; see "entity.tilemap") |
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
  `x .. x + w` and `y - h .. y` at scale 1. An empty map has no bounds (`null`). An isometric map is the box around all
  its diamonds and the images drawn on them.
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
  `game.screenSize` and their `anchor`. To know where a widget or a screen-space `Text` really is (anchor, pivot, safe
  area and layout applied), use `ui.rectOf(entityOrId)`: a `Rect` in design pixels with `(x, y)` at the TOP-LEFT and y
  growing downwards, or `null` for anything else. Layout runs each frame; call `ui.layout()` to run it now (autoSize
  and fit sizes, positions, `Panel.fallbackLayout`) and read a size right after changing a text, with no `game.step`.
  `ui.state` lists the same rectangles, screen-space `Text` included. `ui.rectOf` is also `null` for an entity that is
  hidden, by itself or by an inactive parent, and `ui.state` does not list it.
- Children are not included. `active` and colour alpha are ignored: a hidden entity still has bounds.

Component views expose exactly the reflected fields listed by `factoria api
components` (also `docs/COMPONENTS.md`). Vector/color fields are live views
(`v.x = 1` writes into the engine); enums are lowercase strings
(`body.type = "kinematic"`); asset fields are path strings; JSON fields
(`Tilemap.tiles`, `Script.props`) are plain objects — assign a new value to
write.

Vectors, colours and rects are also array-like, live views included: `padding[1]`, `size[0]`, `[...color]`,
`const [l, t, r, b] = panel.padding`, `for (const c of color)` and `Array.from(color)` give the components in the order
of the named parts (`x y z w`, `r g b a`, `x y w h`) and the named parts keep working. `Array.isArray` is still false
(they are not arrays: no `map` or `forEach`; use `Array.from(v).map(...)`). `length` is the number of components for
colours and rects; vectors keep `length()` (the magnitude), so use `[...v].length` there. `game.screenSize` and
`screen.size` are cheap to read (no copy of the project settings), but still one native call: keep the value in a local
when a loop needs it many times.

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
import { Behaviour, world, input, window, audio, physics, time, camera, debug, scene, game,
         storage, rng, fa, vec2, vec3, color, Vec2, Vec3, Color, math,
         session, particles, ui, assets, ToolError } from "factoria";
```

### world
- `find(idOrName)` → Entity | null · `findAll(name)` · `findByTag(tag)` · `entities()`
- `spawn(entityJson, { position, rotation, scale, parent, index, props })` → Entity (same format as scene files; `{ name, tags, components: {...} }`)
- `spawnPrefab(path, { position, rotation, scale, parent, index, props, overrides, childOverrides })` → Entity.
  `props` is merged into the entity's `Script.props` (on top of the prefab's own); `overrides` is entity JSON
  merged over the prefab (`{ components: { Sprite: { color: ... } } }`). `childOverrides` changes the prefab's
  descendants: `{ Title: { components: { Text: { text: "You won" } } } }`; a key is a child's id, name or a path such
  as `"Panel/Title"`, a value holds `name`, `tags`, `active` and `components`. A child or field that does not exist
  throws with a "did you mean" (docs/MENUS.md, "A panel shared between scenes").
- Destroyed entities (`entity.destroy()`, deferred to frame end) stop being returned by `find`/`findAll`/`findByTag`
  immediately and their id can be reused right away (`world.spawn({ id: "gem_1" })` right after destroying `gem_1`).
  They also leave physics immediately: from the call on, a destroyed entity has no collisions, no contact events and no
  `raycast`/`shape_cast`/overlap hits, even though it is only erased at the end of the frame. So it is safe to destroy a
  stack of rigid bodies and spawn a replacement at the same positions in the same frame: the old bodies do not push the new ones.
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
- Keys: `keyDown("Space")`, `keyPressed("A")`, `keyReleased("Escape")`. `"Ctrl"`, `"Shift"`, `"Alt"` and `"Super"` name
  either side's key: `keyDown("Shift")` is true while the left or the right Shift is held (`"LeftShift"` is one side).
- Modifier chords: a binding in `input.actions` can carry modifiers, `"Ctrl+Z"`, `"Shift+MouseLeft"`, `"Ctrl+Shift+S"`
  (modifiers are `Ctrl`, `Shift`, `Alt`, `Super`; the input is a key, a mouse button or `Touch`, not a gamepad binding).
  The chord is down while its modifiers and its input are held; extra modifiers do not stop it. When another action binds
  the same input with MORE modifiers and those are held, the shorter binding is silent: with `"undo": ["Ctrl+Z"]` and
  `"z": ["Z"]`, holding Ctrl and pressing Z fires `undo` and not `z`. `"Shift"` on its own is a binding (either Shift key).
  Chords print back in one order, `Ctrl+Alt+Shift+Super+input` (`input.bindings`, `input.buttonName` as `"Ctrl+Z"`).
  A bad chord is an error that names the part (`"Cntrl+Z"`: unknown modifier, did you mean `Ctrl`), in `factoria.json`
  (`factoria validate`), `input.rebind` and `input.player(i).rebind` alike. Per-player bindings take chords of keys in the
  player's scheme (all the modifier keys of the chord must be in it); mouse chords belong to the shared pointer, like the
  mouse. A chord starts when its input goes down with the modifiers held, or when the last modifier arrives while the
  input is already down.
- Mouse: `mouse.position` (screen, top-left origin), `mouse.world` (world coords via the camera under the pointer: the main camera when there is one),
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
  does not. Real pads are read in windowed runs only (Windows XInput, Linux joystick API, macOS/iOS GameController,
  Android's input queue, the browser's Gamepad API on the web), so headless runs and tests stay deterministic. A pad
  that stays plugged in survives the window losing focus (inputs are released meanwhile, and the pad reports its real state when focus is
  back). Face buttons are positional: `A` is the bottom one, `B` right, `X` left, `Y` top, whatever the pad prints on
  them (a Switch Pro's bottom button, printed B, is `A`). On Linux each pad is identified by its USB/Bluetooth ids and
  translated through a mapping line in the SDL GameControllerDB format. Where the line comes from, first match wins:
  (1) the standard `SDL_GAMECONTROLLERCONFIG` environment variable (newline separated lines); (2) a
  `gamecontrollerdb.txt` next to `factoria.json` in the game folder (one line per pad, `#` comments, lines for other
  platforms are skipped; read once, when the first pad is opened, so restart the game after editing it; a game author ships it for pads players reported, a player can drop one next to the game);
  (3) the built-in database, the Linux lines of the community SDL GameControllerDB (about 740 entries, 200 KB embedded in
  the binary and indexed on first use; generic HID "USB Gamepad" devices, PlayStation, Switch and many others), plus
  hand-written lines for the DualShock 4, DualSense and Switch Pro kernel drivers; (4) the Xbox (xpad) layout for a
  pad nothing lists. Inside one source an exact bus + version match beats a vendor + product match; a source beats the
  ones below it even with the worse match (the user's word is final). The engine logs each pad's GUID and the mapping it chose, and warns about
  lines it cannot read; a database line for a stick driven by buttons or a hat (N64 and Joy-Con entries) is not
  supported and is skipped. On macOS and iOS (GameController) a pad keeps its slot while connected and an unplugged pad
  frees it. On Android an unplugged pad frees its slot (checked about every 2 s through the Java
  `InputDevice`) and the pad's reported axes decide whether Z/RZ are its right stick or its triggers
  (`docs/MOBILE.md`). Real pads tried so far: an Xbox Wireless Controller on macOS; Linux and Android not yet.
  On phones the `TouchStick` and `TouchButton` components draw an on-screen pad whose fingers feed the same gamepad
  bindings, so these actions work there unchanged (docs/MOBILE.md, "On-screen gamepad"); `gamepad(index)` does not
  list it, and fingers on it are not in `touches`.
- Local players: `player(i)` (0..3) is one person's view of the same actions, for games where two to four people share the
  machine, each on their own pad and/or part of the keyboard. `player(i).use({ pad: 0, keys: "left" })` gives the player
  devices (every field is optional; `use()` takes them all away; a player with no device reads nothing). `pad` is a gamepad
  slot, `padId` (`input.gamepad(i).id`, instead of `pad`) makes the player follow that physical pad if it comes back in another
  slot and read nothing while it is unplugged. `keys` names a key scheme: `"all"`, `"left"` (Q W E R T A S D F G Z X C V B,
  1-5, Space, Tab, LeftShift...), `"right"` (the arrows, Enter, Backspace, U I O P H J K L N M, 6-0, punctuation...) or one
  from `factoria.json` `"input": { "schemes": { "pad2": { "extends": "right", "keys": [...], "actions": { "jump": ["Enter"] } } } }`
  (`extends` copies a built-in scheme, `keys` adds keys, `actions` gives the keys of some actions for players of that scheme;
  `keySchemes()` and `keySchemeKeys(name)` list them). A bad slot or scheme throws with "did you mean" and changes nothing.
  The reads are the global ones: `down`, `pressed`, `released`, `value`, `axis`, `vector`, with the same action names, and
  they hear only that player's devices: a pad binding reads that pad (not "any pad"), a key binding counts only keys of the
  player's scheme, and mouse and touch bindings belong to the shared pointer, so players do not read them. The global
  `input.down()` and the rest keep hearing every device. Each player has bindings of their own (the project's, filtered to
  the device; `schemes.<name>.actions` overrides the keys of an action): `bindings(action, family?)`, `rebind(action,
  names, family?)` (all keys or all pad names; a key outside the player's scheme or a mouse name is an error; the family
  `"keys"` or `"pad"` is optional and lets a menu edit a list the player has no device for yet), `reset(action?)` and
  `lastPressed()` (only that player's devices) are per player, and `export()` / `import(data)` move what the player
  rebound to and from `storage`: `import` skips entries that no longer fit and returns a description of each. What a player
  rebound stays with the player when its device changes. Devices are not saved: a game assigns them each time its scene
  starts, and a test starts with none (like it starts with the project's bindings). Tests drive players with `game.keyDown`
  and `game.gamepad(i)`.
  ```js
  const me = input.player(1);
  me.use({ pad: 1 });                                  // the second gamepad
  const dir = me.vector("move_left", "move_right", "move_down", "move_up");
  if (me.pressed("jump")) jump(this.entity);
  if (b = me.lastPressed()) { me.rebind("jump", [b], b.startsWith("Gamepad") ? "pad" : "keys"); storage.set("p2", me.export()); }
  ```
- Options menus (rebinding, "press any key", button labels):
  - `actions()` lists the action names; `bindings(action)` the names bound to one (`["Space", "GamepadA"]`).
    `rebind(action, bindings)` replaces ALL of an action's bindings at once (`input.rebind("jump", ["Enter",
    "GamepadX"])`); an empty array unbinds it. Names are case-insensitive and stored in their canonical spelling. An
    unknown action or binding name throws a "did you mean" error and changes nothing (all or nothing).
    `resetBindings(action?)` goes back to the `factoria.json` bindings, of one action or of all (an action a script
    created with `rebind` and the project does not list is removed). The change is live at once: `input.down` and
    friends follow the new binding. It is NOT saved: persist it yourself (recipe below).
  - `lastPressed()` is the binding that went down this frame (`"Space"`, `"MouseLeft"`, `"GamepadA"`, `"GamepadLeftStickLeft"`
    when a stick crosses halfway) or `null`. Poll it from a "press the new key" screen and pass the result to `rebind`;
    keys come first when several go down in the same frame. Mouse movement, a held key and a connected pad do not count.
    With modifiers held it is the chord (`"Ctrl+Z"`, `"Shift+MouseLeft"`), which `rebind` takes as it is. A modifier
    pressed alone is reported when it is RELEASED, by its side (`"LeftShift"`), and never when something else was pressed
    while it was held, so pressing Ctrl on the way to Ctrl+Z does not end the wait.
  - `lastDevice` is `"keyboard" | "mouse" | "touch" | "gamepad"`, whichever produced the last real input (a pad that merely
    sits plugged in never takes it), so a game can switch its on-screen hints between key caps and pad buttons.
  - `buttonName(bindingOrAction, pad = 0)` is the label a player sees: `"Space"`, `"Left Click"`, `"A"` (Xbox),
    `"Cross"` (PlayStation), `"ZL"` (Nintendo). Give it an action and it names that action's first binding for the last
    device used (the keyboard key unless the player last touched a pad). Pad families come from the pad's USB/Bluetooth
    ids and name (`input.gamepad(i).type`: `"xbox" | "playstation" | "nintendo" | "steamdeck" | "generic"`); a pad that is
    not connected, or one nothing recognizes, is `"generic"` (Xbox-style names). Android reports `"generic"` for now.
  - `text` is what the player typed this frame as UTF-8 (printable characters, emoji and accents included, no control
    keys: read Backspace/Enter/Escape with `keyPressed`). Empty most frames. `showKeyboard(on = true)` raises the on-screen
    keyboard on phones and tablets (a no-op on desktop, where the physical keyboard already types); `keyboardShown` is what
    was asked for. `platformKeyboard` is true while a native plugin's keyboard (the Steam Deck's) has the focused TextField: the menu
    kit's on-screen keyboard stays closed then (docs/PLATFORM.md, "Steam Deck keyboard"). A phone's keyboard may not deliver composed text (docs/MOBILE.md, "Phone features", lists the limits).
  - `onBack(handler)` is Android's Back button or gesture: `handler()` returns `true` (or nothing) when it closed
    something, `false` to let the next handler (the newest is asked first) or the system decide; if nobody consumes Back the
    game leaves, as Android would have. It returns a function that removes the handler, and handlers end with the scene.
    `vibrate(seconds = 0.1)` buzzes a phone (up to 5 s; on iOS only a short tap or the system buzz). No-ops where there
    is no Back button or motor.
  - `screen.safeArea` (a `Rect`), `screen.insets` (`{left, top, right, bottom}` lost at each edge) and `screen.size`, in
    design pixels: what a notch, rounded corners and system bars leave free. The whole screen on desktop and headless.
    Put `safeArea: true` on a Sprite, Shape2D, Text, ParticleEmitter or UI widget and its `anchor` is a corner or edge of
    the safe area (docs/MENUS.md, "Phones: notch and Back"). Import it with `import { screen } from "factoria"`.
  - `mouse.visible` (default true) and `mouse.locked` (default false) hide the cursor and lock it to the window for mouse
    look; while locked, `mouse.delta` is the raw movement. The window follows the request every frame and re-locks after
    the game regains focus. A headless run and tests only record the values (and reset them between tests).
  ```js
  // "Press a key" rebinding screen, saved between runs
  import { Behaviour, input, storage } from "factoria";
  for (const [action, list] of Object.entries(storage.get("bindings", {}))) {   // at startup
    try { input.rebind(action, list); } catch (e) { console.warn(`ignoring saved bindings of '${action}': ${e.message}`); }
  }
  export default class Rebind extends Behaviour {
    waiting = "jump";
    onUpdate() {
      const b = input.lastPressed();
      if (!this.waiting || !b || b === "Escape") return;
      input.rebind(this.waiting, [b]);
      storage.set("bindings", Object.fromEntries(input.actions().map((a) => [a, input.bindings(a)])));
      console.log(`${this.waiting} is now ${input.buttonName(b)}`);
      this.waiting = null;
    }
  }
  ```

### window
Settings an options menu needs. The getters work everywhere (a headless run or a test answers from `factoria.json`);
every setter throws an Error that says what to do when the run has no window (`factoria run --headless`, tests, the
editor's game view), so check `window.available` first or offer the option only in `factoria run` and exported games.
- `available` is true when a real window exists. `fullscreen` (read only) and `setFullscreen(on)`: `window.setFullscreen(true)`
  toggles at once (it takes `true` or `false`, nothing else): `setMode("fullscreen")` and `setMode("windowed")` below.
- `mode` (read only) and `setMode("windowed" | "borderless" | "fullscreen")`. Windowed has a frame and the size of
  `setSize`; the other two cover the monitor the window is on (`fullscreen` is true for both). What "fullscreen" means
  depends on the OS: **Windows and Linux** have no exclusive full screen in the engine, so `"fullscreen"` and
  `"borderless"` are the same frameless window over the monitor (the name only remembers what the player picked);
  **macOS** runs `"fullscreen"` as the OS's native full screen (a Space of its own, the menu bar slides in) and
  `"borderless"` as a frameless window over the monitor that hides the menu bar and the Dock but stays on the desktop's
  Space. On macOS, going from `"fullscreen"` straight to `"borderless"` throws (the Space takes a second to leave): set
  `"windowed"` first (the menu kit's button cycles windowed, borderless, fullscreen, so it never does). The web and
  phones have no borderless mode (`supports("borderless")` is false); phones are always `"fullscreen"`.
- `monitors()` lists `[{ index, name, size, primary, current }]`, primary first; `monitor` is the index of the one the
  window is on and `setMonitor(index)` moves the window there (centred when windowed, covering it when full screen or
  borderless). `displaySize` and `resolutions()` follow. Windows, macOS and Linux (XRandR, loaded when the game starts:
  a machine without it lists the whole screen as one monitor). Elsewhere `monitors()` has one entry and `setMonitor`
  throws; on macOS it also throws while the window is in its native full screen. Two identical monitors have the same
  `name`: show the index too. A saved choice should keep the name, since indices change when a monitor is unplugged.
- `size` (Vec2, window pixels without the title bar) and `setSize(width, height)` (whole numbers, 160 to 16384). Setting
  the size while full screen throws: leave full screen first. `displaySize` is the monitor's size.
  `resolutions()` lists `[{ width, height }]`, smallest first: 16:9 and 16:10 sizes that fit the monitor plus the game's
  design size, ready for a dropdown. The game letterboxes per `display.scaleMode`, so any size works.
- `vsync` and `setVsync(on)`; `display.vsync: false` in `factoria.json` now really turns it off (it was ignored before).
  Where it cannot be changed live (phones and tablets, a Linux driver without swap control, Windows before 10) the setter
  throws and says to set `display.vsync` instead. On macOS, vsync off lets the picture tear; the frame rate stays at the display's.
- `frameCap`: 0 (unlimited, the default) or 15 to 1000 frames per second, read and written (`window.frameCap = 60`). It
  waits at the start of each frame and does not touch the simulation (the fixed step still runs per game time), so it
  only saves power and heat; with vsync on the display rate wins when it is lower.
- Phones and tablets are always full screen, with the display's frame rate: `setFullscreen(true)` is a no-op, and
  `setFullscreen(false)`, `setSize` and `frameCap` throw with that explanation. Read `window.supports("frameCap")`
  first and hide the option where it is false instead of catching the Error.
- `supports(feature)`: `"frameCap"`, `"fullscreen"` and `"resize"` are true in a game window on a desktop (they are false
  headless and on phones and tablets, where their setters throw); `"borderless"` is true in a desktop game window
  (Windows, macOS, Linux), `"monitors"` where the monitors can be listed and chosen (the same three; it is true with one
  monitor too, so offer the choice when `window.monitors().length > 1`); `"renderScale"` is true everywhere; `"clipboard"` is
  true on Windows, macOS, Linux and the web, and in headless runs and tests (an in-memory clipboard), false on phones
  and tablets. An unknown name throws with a "did you mean".
- Window modes and monitor choice, checked by hand on: nothing yet (the script layer is covered by tests with a fake set
  of monitors). To be checked: macOS (borderless, native full screen, a second monitor), Windows (two monitors, windowed
  and full screen moves) and Linux X11 (two monitors with XRandR; `_NET_WM_FULLSCREEN_MONITORS` depends on the window
  manager).
- `renderScale`: 0.5 to 1 (default 1), read and written. The picture is drawn at that share of the size (0.5 = a quarter
  of the pixels) and scaled up, which is the cheapest saving on a weak GPU. It works in every run with a renderer,
  tests included: `game.screenshot` and `game.renderStats().width` then have the scaled size. The engine saves nothing;
  keep the player's choice with `storage.set`.

### game.device: pick a quality preset
`game.device` is `{ formFactor: "desktop" | "phone" | "tablet", gpuBackend, memoryGB, tier: "low" | "medium" | "high", steamDeck, handheld }`.
`gpuBackend` is `"metal"`, `"d3d11"`, `"glcore"`, `"gles3"`, `"wgpu"` or `"vulkan"`; `memoryGB` is the machine's physical
memory; `tier` comes from the backend and the memory (under 3.5 GB is `"low"`, under 7.5 GB `"medium"`, 5.5 on a phone
or tablet; unknown memory, as on the web, is `"medium"`). A phone and a tablet differ by the short side of the screen
(600 logical pixels). **Headless runs, tests and the editor always read** `{ formFactor: "desktop", gpuBackend:
"headless", memoryGB: 8, tier: "high", steamDeck: false, handheld: false }`, so a preset picked from it never depends on the
machine; tests pretend with `game.setDevice({ formFactor: "phone", tier: "low" })` or `game.setDevice({ steamDeck: true })`
(reset before each test). `steamDeck` is true on a Steam Deck: the Steam plugin says so when Steam is running; without the
plugin the `SteamDeck=1` environment variable decides (Steam sets it for games it starts on a Deck, as community reports
say rather than Valve's docs; a `SteamDeck=0` launch option turns it off). A Deck reports `formFactor: "desktop"`.
`handheld` is true on a Steam Deck, a phone or a tablet: use it for bigger text and pad or touch prompts.

### Pads plugged in and out: `game.on("gamepadConnected" | "gamepadDisconnected", fn)`
`fn` gets `{ slot, id, name, type }`. `slot` is what `input.gamepad(slot)` answers for; `id` is the same for the same physical
pad each time (vendor and product ids, the name and, where the platform has one, a serial or device path), so a game can give a
player their pad back; `name` is the OS name; `type` is the pad family. A pad that returns takes its old slot when it is free
(on Linux the slot is the kernel's joystick number). What goes into the id: Windows XInput has no ids, so the id says "an Xbox
pad in XInput slot N" (it ends with `#xinputN`); Linux adds the kernel serial when the pad has one; macOS, iOS and the web give
the name (the web also the vendor and product, but no serial); Android adds the InputDevice descriptor. Two pads of one model
without a serial share an id. Losing the window focus does not disconnect a pad. Pads already plugged in when the first scene
starts are not announced: read `input.gamepad(i).connected` and `.id` in the first frame. Tests: `game.gamepad(1).connect({
id: "pad-red", name: "Red pad", type: "playstation" })`, then `game.step(1)` raises the event.
```js
import { game, window, storage } from "factoria";
const preset = storage.get("quality", game.device.tier);        // the player's choice wins, else the device's tier
window.renderScale = { low: 0.7, medium: 0.85, high: 1 }[preset];
const canCap = window.supports("frameCap");                      // hide the frame cap row on a phone
```
```js
import { window, storage } from "factoria";
const s = storage.get("video", { windowMode: "windowed", vsync: true, cap: 0 });
if (window.available) {
  window.setMode(s.windowMode);   // "windowed" | "borderless" | "fullscreen"; window.setMonitor(i) first to pick the monitor
  window.setVsync(s.vsync);
  window.frameCap = s.cap;
}
// A resolution dropdown: window.resolutions().map((r) => `${r.width} x ${r.height}`); on pick: window.setSize(r.width, r.height).
```

### audio
- `play(path, { volume, pitch, pan, loop, bus, onEnded })` → voice id · `stop(id)` · `stopAll()`
- `music(path, { volume, fade, persist })` · `stopMusic(fade)` · `setVolume(bus, v)` · `getVolume(bus)` (`"master"`, `"sfx"`, `"music"`, `"ui"` or a bus of the project, see "Project buses" below; default 1; not saved: an options menu stores it)
- `activeVoices()` lists the sounds that play now, oldest first: `[{ id, path, bus, volume, pitch, pan, loop, music, source }]`
  (`volume` is the voice's own volume as last set, the volume a `setVoiceVolume` fade moves to; `music` is true for the music
  track and its layers; `source` is the entity id of the `AudioSource` or `Video` that plays it, `""` for scripts). A game that
  caps how many sounds play at once counts this list instead of keeping its own.
- `play(path, { onEnded })` calls `onEnded(voiceId)` once, in the step after the voice ended: the clip finished, a fade-out
  reached silence, `audio.stop(id)` was called, or a full mixer cut it. It is not called when `stopAll()` or a scene load cut
  the sound, nor for a sound that did not start (id 0): the scene that asked is gone. A looping sound ends only when stopped.
  An error thrown by the callback is reported like one from a timer.
- A scene load (`scene.load`, reload) stops every sound and the music, then starts the new scene's `SceneSettings.music` (the same
  track again too). `audio.music(path, { persist: true })` is the exception: that track keeps playing through scene loads, and a
  scene whose `settings.music` is the same track does not restart it (another track replaces it). `stopAll()` stops a persisted track too.
- `setVoiceVolume(id, volume, fade?)` moves the volume of a sound that plays (an id from `play`) in a straight line over `fade`
  seconds, bus and master volumes still apply; false once the voice ended. Each change that took effect is also an entry of
  `game.audioLog()` (see the last point of this list).
- `musicLayers({ drums: path, bass: path }, { volume, fade, persist, levels })` starts stems of one piece on the same audio
  sample (all in one step, so they never start in different blocks); `setLayer(name, level, fade?)` fades a stem in or out
  (0 silent, 1 full). Stems of equal length stay aligned across loops; `stopMusic` stops every layer.
- Every play request (scripts, `AudioSource`, scene music) is recorded in a play log: tests read it with
  `game.audioLog()`, agents with the `audio.log` command. Each entry has `kind`: `"play"` (with `voice`, the id the request
  got, 0 when it did not start; music started by the engine has none) or `"setVoiceVolume"` (a `setVoiceVolume` of a voice that
  plays: `voice`, `path`, `volume` is the target, `fade` the seconds, `bus`), so a test can assert that a bed followed the
  camera. `toContainPlayed` counts plays only.
- `AudioListener.zoom` scales how far positional sounds are heard (docs/COMPONENTS.md, "AudioListener"); a script moves it
  with `listenerEntity.get("AudioListener").zoom = v` each frame (or the `scene.set_component` command).
- `bus(name)` gives a handle with `lowpass`, `reverb`, `duck`, `unduck`, `volume` and `state`; `snapshot(name, { fade })` and
  `snapshots()` move every bus to a named snapshot of factoria.json. Effects and ducking are in "Audio buses" below.
- A change of a bus volume (`setVolume`, `bus(name).volume`) ramps over about 10 ms, so it never clicks.

### Audio buses
Every voice goes into the buffer of its bus (`sfx`, `music`, `ui` or a bus of the project), each bus gets its effects and its
volume, and the buses are summed into their parent and finally into the master, which has its own. `audio.bus(name)` returns a
handle on `"sfx"`, `"music"`, `"ui"`, `"master"` or a project bus (an unknown name throws with a "did you mean" and the list);
its methods return the handle, so they chain:

```js
audio.bus("music").lowpass(800).reverb(0.2);              // muffled, in a small room
audio.bus("music").duck("sfx", 0.5);                      // music at half volume while a sound effect plays
audio.bus("music").lowpass(null, { fade: 1 });            // the filter opens again over a second
audio.bus("music").unduck();                              // or duck(null)
```

| Method | What it does |
|---|---|
| `lowpass(hz, { fade })` | 12 dB per octave low-pass at `hz` (20 to 20000; 400 to 800 sounds muffled or underwater). `0` or `null` switches it off. With `fade` the cutoff slides, measured in octaves, from where it is (a bus with no filter starts at 20000). |
| `reverb(mix, { fade })` | A small room reverb: `(1 - mix)` dry plus `mix` wet, 0 to 1. `0` switches it off. The tail rings out for about 4 seconds after the bus goes silent, then the reverb stops working. |
| `duck(byBus, amount = 0.5, attack = 0.05, release = 0.5)` | Lowers this bus by `amount` (the fraction removed: 0.5 is half as loud, 1 is silent) while `byBus` (any bus but this one and the master) is louder than -40 dBFS, measured after that bus's own effects and volume. `attack` and `release` are time constants in seconds: the bus covers 63% of the way in that time and about 95% in three times it. The master cannot duck. `duck(null)` and `unduck()` switch it off. Ducking has no `fade`: it follows `byBus` by itself. |
| `volume(v, { fade })` | The bus volume, the same as `audio.setVolume(name, v)` with an optional fade (a straight line over `fade` seconds). |
| `state()` | `{ volume, snapshotVolume, lowpass, reverb, duck }`: what the bus is moving to (a fade in progress shows its end), `lowpass` is 0 and `reverb` 0 when off, `duck` is null or `{ by, amount, attack, release }`. |

The order on a bus is low-pass, reverb, volume, then ducking; the master takes a low-pass and a reverb on the sum of the
buses, then its volume. A bad value (a cutoff below 20 Hz, a mix above 1, a bus that ducks itself) throws an error that says
what to use. Effects stay across scene loads, like volumes: a game that switches them on for one level switches them off
(or applies a snapshot) when it leaves. The test runner puts every effect back to off before each test.

**Project buses.** `sfx`, `music`, `ui` and the master always exist; a project adds its own in factoria.json, each with a
parent (default `"master"`; a parent may be declared after its child):

```json
"audio": { "buses": {
  "ambience": { "parent": "sfx" },
  "birds":    { "parent": "ambience" },
  "voiceover": {}
} }
```

`audio.play(path, { bus: "ambience" })`, `audio.setVolume("ambience", 0.5)`, `audio.bus("ambience")`, `duck("voiceover")`, the
`audio.bus` command and snapshots take the new names. A bus is mixed on its own (its voices and the buses under it, then its
low-pass, reverb, volume and ducking) and the result is summed into its parent, so `setVolume("sfx", 0.5)` also halves
`ambience`, while `setVolume("ambience", 0.5)` leaves the other sound effects alone. Names are lowercase letters, digits, `_` or
`-` (`setVolume` lowercases what it gets), may not repeat a built-in name, and a chain of parents must end at a built-in bus;
`factoria validate` reports a wrong name, an unknown parent (with a "did you mean"), a loop, and a snapshot or a `duck.by` that
names a bus nobody declared. At most 32 project buses. When the buses of a project change (a reload), a bus that stays keeps its
volume and effects, and the voices of a bus that went away play on `sfx`. Ducking between buses of different depth: the
bus that ducks reads the other bus after its own effects and volume when that bus is as deep or deeper in the tree (a child of
the ducked bus's parent, for example), and as the sum of its voices and its children before its own effects when it is nearer
the master.

**Snapshots** name a whole mixer state so a script does not juggle buses one by one. They live in factoria.json:

```json
"audio": { "snapshots": {
  "underwater": { "fade": 0.8, "buses": {
    "sfx":   { "lowpass": 600, "reverb": 0.3 },
    "music": { "volume": 0.5, "lowpass": 400 } } },
  "dialogue": { "fade": 0.3, "buses": { "music": { "duck": { "by": "ui", "amount": 0.6 } } } },
  "normal": {}
} }
```

`audio.snapshot("underwater")` moves every bus to that state over the snapshot's `fade` (0.5 s when it gives none), or over
`audio.snapshot("underwater", { fade: 2 })`. A bus the snapshot does not list goes back to neutral (no effects, scale 1), so
`"normal": {}` is the way back and one snapshot replaces the last. `volume` in a snapshot is a scale on the bus volume the
player set with `setVolume` (the options menu keeps working under a snapshot); low-pass, reverb and the scale fade, ducking
switches at once. `audio.snapshots()` returns `{ names, current }`. An unknown name throws with a "did you mean", and
`factoria validate` reports a bad catalog (a typo in a bus or key, a value out of range) with its JSON pointer and a fix.
Agents use the commands `audio.bus` (`{ "bus": "music", "lowpass": 800, "fade": 0.5 }`; just `bus` reads the state) and
`audio.snapshot` (`{ "name": "underwater" }`; no name lists them). A snapshot may list project buses too. The mix is deterministic, so a test can render a clip with
`factoria run --headless --record-audio out.wav` after switching an effect on and measure the result.

Cost, on a mix of 44.1 or 48 kHz stereo: a bus with no effect does no effect work (its voices are only added into its parent,
one add per sample while it plays). A low-pass is one biquad per channel, five multiply-adds a sample, and works only while
the bus has sound. A reverb is eight comb and four all-pass filters per channel (several times a low-pass) and about 100 KB of
delay lines, allocated when first switched on; it keeps working for its 4 s tail and then stops. Ducking is a peak detector on
`byBus`, one gain computation and one multiply per sample, and stops by itself once the bus is back at full volume and `byBus`
is silent. Give `fade` when you switch a low-pass or reverb on or off in the middle of a sound, so it does not step.

### physics
- `raycast(from, to, { mask, ignore, ignoreTriggers })` → `{ entity, point, normal, distance } | null` (2D when `from` has no z)
- `raycast3d(origin, dir, maxDistance, { mask, ignore, ignoreTriggers })`. Colliders that contain the ray origin are
  skipped. From a behaviour pass the caster so it does not hit itself: `physics.raycast(a, b, { ignore: this.entity })`
  (`ignore` is an Entity or id; triggers are skipped unless `ignoreTriggers: false`; the commands `physics.raycast` and `physics.shape_cast` take the same three options). Ledge check pattern: cast a short
  ray down from just ahead of the feet and treat "no hit" as a ledge.
- `shapeCast(shape, from, to, { mask, ignore, ignoreTriggers })` → the same `{ entity, point, normal, distance } | null`
  as `raycast`, for a shape with size (2D when `from` has no z, else 3D). `shape` is `{ shape: "circle", radius: 8 }` or
  `{ shape: "box", size: [16, 24] }` in 2D, `{ shape: "sphere", radius: 0.5 }` or `{ shape: "box", size: [1, 2, 1] }` in
  3D (full sizes in pixels / meters, like the colliders), centred on the cast position and axis-aligned. `distance` is
  how far the CENTRE can travel before the shape touches something, `point` the contact point and `normal` the hit
  surface's normal (pointing back at the shape), so `from + dir * distance` is where the shape stops. Colliders the shape
  already overlaps at `from` are skipped (like a ray starting inside one); a collider it merely touches blocks the cast
  only if the shape moves towards it. `from === to` returns `null`; use `overlapBox` / `overlapCircle` to test a spot.
  A bad shape throws an Error that says why, with a "did you mean" for a misspelt name, and notes that `"sphere"` is the 3D
  name and `"circle"` the 2D one.
  ```js
  // Can a 16 x 24 body step 10 px right? Sweep its box first.
  const hit = physics.shapeCast({ shape: "box", size: [16, 24] }, p, vec2(p.x + 10, p.y), { ignore: this.entity });
  const room = hit ? hit.distance : 10;   // move at most this far
  ```
-  `overlapCircle(center, r)` · `overlapBox(rect)` · `overlapSphere(center, r)`
- `applyImpulse(entity, v)` · `applyForce(entity, v)` · `setVelocity(entity, v)`


### nav
- `nav.findPath(from, to, { radius, snap, closest, mesh })` → `{ found, points: Vec3[], length, complete, mesh }` or
  `{ found: false, reason, message, hint, nearest?, nearestDistance? }`: a walkable path over the baked `NavMesh3D`
  (around walls, up ramps, never up a step above `stepHeight`). `points[0]` is the start; walk straight to `points[1]`,
  and so on. "No route" is a result to check, not an exception; a `radius` bigger than the mesh was baked for throws an
  Error that says how to bake for it. `nav.bake(mesh?)` bakes now and returns the stats. Guide: [NAVIGATION.md](NAVIGATION.md).

- `nav.findTilePath(map, from, to, { costs, diagonals, maxNodes, closest, allowBlockedGoal })` → `{ found, complete, cells:
  {col, row}[], points: Vec2[], cost, length }` or `{ found: false, reason, message, hint }`: A* over a `Tilemap` entity
  (solid tiles block; `costs` per tile index) or your own `{ width, height, cost }` grid; `nav.tileVersion(tilemap)` counts
  the changes of the tiles. See NAVIGATION.md, section 7.
- `nav.createGrid({ width, height, cost?, origin?, cellSize? })` → a `NavGrid` kept natively (`setCost(col, row, cost)`,
  `getCost`, `setCosts`, `version`): pass it to `nav.findTilePath` instead of the array when you ask many times on one map.
  `nav.flowField(grid, goals, { diagonals })` → a `NavFlowField`: `stepToward(col, row)` is the next cell toward the nearest
  goal in O(1), `distance(col, row)` the cost, `pathFrom(col, row)` the whole way; it is rebuilt by itself after
  `grid.setCost`. See NAVIGATION.md, "Reusable grids and flow fields".

### AI: behaviour trees (`bt`)
`import { bt } from "factoria"` is a small behaviour tree in plain JS (like `tween`): you build a description once, give each
agent its own `bt.Tree` with a blackboard (the agent's state), and call `tree.tick(dt)` from `onUpdate(dt)`. Nothing runs by
itself and time only advances by the `dt` you pass, so it is deterministic and replays and tests repeat it exactly.

```js
import { Behaviour, bt, nav, world } from "factoria";
const { SUCCESS, FAILURE, RUNNING, sequence, selector, condition, action, wait, cooldown } = bt;
const brain = selector(
  sequence(condition((b) => b.seesPlayer()), cooldown(2, action((b) => { b.bite(); return SUCCESS; })), action((b, dt) => { b.chase(dt); return RUNNING; })),
  sequence(action((b, dt) => { b.wander(dt); return RUNNING; }), wait(1)),   // a node returns SUCCESS, FAILURE or RUNNING
);
export default class Rat extends Behaviour {
  onStart() { this.tree = new bt.Tree(brain, this); }   // the blackboard is the behaviour itself
  onUpdate(dt) { this.tree.tick(dt); }
}
```

- `sequence(...children)`: in order; FAILURE at the first failure, RUNNING while a child runs (the next tick resumes at that
  child WITHOUT asking the earlier conditions again), SUCCESS when all succeeded.
- `selector(...children)`: in order from the first child on every tick, the first result that is not FAILURE; so an earlier
  (more important) child interrupts a running later one.
- `parallel(...children)` / `parallel({ succeed: "any" }, ...children)`: ticks the children in order EVERY tick. The first
  FAILURE fails it (later children are not ticked that tick). Default `succeed: "all"`: SUCCESS once every child has
  succeeded (a child that succeeded is not ticked again meanwhile); `"any"`: SUCCESS at the first success. Otherwise RUNNING.
  When it finishes, the children still running are stopped: an action gets `onExit(blackboard, "aborted")` and everything
  else starts fresh next time. No children: SUCCESS for "all", FAILURE for "any".
- `repeat(child, times?)`: runs the child again each time it succeeds. RUNNING while it repeats, FAILURE as soon as the child
  fails, SUCCESS after `times` successes (a whole number >= 1); without `times` it repeats forever. One run of the child per
  tick: the next run starts on the NEXT tick, so a child that succeeds at once cannot loop forever inside one tick.
- `condition(fn)`: `fn(blackboard)` truthy = SUCCESS, falsy = FAILURE. `action(fn, { onEnter, onExit })`: `fn(blackboard, dt,
  tree)` returns `bt.SUCCESS`, `bt.FAILURE` or `bt.RUNNING` (anything else throws); `onExit(blackboard, status)` also runs with
  `"aborted"` when a tick no longer reaches a running action, or `tree.reset()` stops it.
- `wait(seconds)`: RUNNING until that much `dt` passed, then SUCCESS. `cooldown(seconds, child)`: after the child finishes,
  FAILURE for `seconds` without ticking it. `inverter(child)` swaps SUCCESS and FAILURE; `succeeder(child)` turns both into SUCCESS.
- A node that was not ticked on the previous tick starts fresh (a sequence at its first child, a wait at zero). Each `Tree`
  has its own memory per node, so one description can drive many agents. Build trees once, not every frame.
- Typical enemy: a tree decides WHAT to do (chase, flee, wander) and `nav.findTilePath` says WHERE to step; see the "enemies"
  recipe of the AI guide.

### time
`dt`, `fixedDt`, `elapsed`, `frame`, `scale`, `unscaledDt`.

`time.scale` (writable, default 1) scales gameplay: the `dt` of `onUpdate`/`onFixedUpdate`, timers (`after`, `every`),
physics steps, particles and sprite animators. `0` freezes all of them; `game.paused = true` is the same as
`time.scale = 0`, but it remembers the scale: `game.paused = false` restores the `time.scale` you had (0.5 stays 0.5;
1 if it was 0 already), and setting `time.scale` to a value above 0 while paused only changes the scale to restore.
Audio keeps playing and `time.elapsed` keeps counting fixed steps. While it is 0 the engine calls
`onUpdate`/`onLateUpdate` only on behaviours with `runWhilePaused = true` (a class field), with the real frame time as
`dt` (`time.dt` is 0 then, `time.unscaledDt` is the real one), and the UI and `world.on` listeners keep working. A pause
menu is such a behaviour:

```js
export default class PauseMenu extends Behaviour {
  runWhilePaused = true;              // keeps getting onUpdate while game.paused
  onUpdate() {
    if (input.pressed("pause")) { game.paused = !game.paused; this.world.find("pause_panel").active = game.paused; }
  }
}
```

Keep such a behaviour on an entity that stays active (an inactive entity gets no callbacks) and show or hide the panel.

### camera
`main` (the first camera drawn: the primary camera with the lowest `depth`, or null), `all` (every camera drawn, in draw
order, at most 8), `at(v)` (the camera whose viewport contains the screen point `v`, else the first), `worldToScreen(v, camera?)`,
`screenToWorld(v, depth?, camera?)` (also `screenToWorld(v, camera)`) and `screenRay(v, camera?)` (`{origin, direction}` for a 3D
pick). A camera is an Entity or its id. Without a camera, a screen point uses the camera under it (`at`), a world point the
first camera. With one camera and the default viewport nothing changes. `mouse.world` and a touch's `world` use the camera under
the pointer. Each camera draws into `Camera.viewport` (a part of the screen, 0..1, top-left origin): two or more primary cameras
make a split screen, see the recipe in AI_GUIDE section 9.29. A script that sets `viewport` live gets a value outside the
screen clamped to it, with one warning.
The `Camera` component fields are live, for example `camera.main.get("Camera").bloomIntensity = 2` changes the glow
(`bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`; see AI_GUIDE section 9.20).

### debug
`line(a, b, color?)`, `rect(x, y, w, h, color?)`, `circle(center, r, color?)`, `text(screenPos, str, color?)`.

### tween / ease / animator
`tween(target, props, options?)` moves numbers, vectors and colors of any object over time and returns a `Tween`
(`cancel()`, `pause()`, `resume()`, `next(...)`, `finished: Promise<boolean>`, `active`, `progress`); `tween(from, to, { onUpdate })`
tweens a plain number; `ease` holds the easing functions (`ease.quadOut`; the names also work as strings,
`ease: "backOut"`); `cancelTweens(target?)`. Options: `duration`, `delay`, `ease`, `repeat`, `yoyo`, `from`, `onStart`,
`onUpdate`, `onComplete`. Tweens run on the game's clock: they pause with `time.scale = 0` and are deterministic in tests.
`entity.animator` controls the `Animator` component (skinned glTF clips, cross-fades, clip events, state machine).
Both are described with examples in [ANIMATION.md](ANIMATION.md).

### entity.tilemap
`entity.tilemap` edits the `Tilemap` component one tile at a time, in place. Do not read `tiles`, change one entry and
write the whole array back: that copies the grid on every call.
- `getTile(col, row)` returns the tile index (`-1` for an empty tile or a cell outside the map). Row 0 is the top row.
- `setTile(col, row, id)` writes one tile: `-1` empties it, otherwise a tile index (with the flip/rotate flags that
  `scene.import_ascii` writes). It returns `false`, and changes nothing, for a cell outside the map or a bad value.
- `width` and `height` are the map size in tiles.
- `cellAt([x, y])` is the cell under a world point: `{col, row}`, or `null` when the point is outside the map. `cellToWorld(col, row)` is the world position of the centre of a cell (a `Vec2`; the cell may be outside the map, its position is still computed). Both apply the entity's position, rotation and scale and follow `Tilemap.projection`, so they are the way to pick a cell of an isometric map: `map.tilemap.cellAt(input.mouse.world)`. The same maths is available from outside a script as the commands `tilemap.cell_at` and `tilemap.cell_to_world`.
2D physics sees the change on the next step and rebuilds only the colliders of the tiles that changed, so `setTile(x, y,
-1)` opens a hole a body falls through. The same edit from outside a script is the command `tilemap.set_tile`
(`{id, col, row, tile}`). Writing the whole `tiles` array still works and rebuilds the colliders.

### entity.video
`entity.video` controls the `Video` component (an `.mpg` drawn in a UI rectangle, [ASSETS.md](ASSETS.md), "Video"). It plays
by itself when the scene starts (`autoplay`) and follows the game clock: it pauses with `time.scale = 0` and a test steps
it with `game.step`.
- `play()` plays (or restarts after the end), `pause()`, `stop()` (pause and back to the start), `seek(seconds)`.
- Read: `time`, `duration` (0 until the file is open), `playing`, `ended`. Read and write: `loop`, `volume`. A script
  that sets `entity.get("Video").path` opens another file.
- `on("ended", fn)` calls `fn({id, path})` when a video that does not loop reaches its end, once, and returns the function
  that unsubscribes. It is the game event `video.ended`, so `world.on("video.ended", ...)` hears every video. A
  handler that loads a scene should check `scene.current` first: the answer can arrive after the scene was left.
- A file that cannot be opened logs one error and the `Video` draws only its `color`; `duration` stays 0.
A studio intro that any button skips: [MENUS.md](MENUS.md).

### particles / ui
- `particles.burst(entity, count)` (same as `entity.emitBurst(count)`) spawns particles now from a `ParticleEmitter`,
  even with `emitting = false`. Without a renderer (headless) it is a no-op with a warning.
- `ui.overflowed(entityOrId)` → `true` when the text of a `Text` with a box (`maxWidth` / `maxHeight`) or the label of a
  Button, Toggle, Slider or TouchButton still does not fit at the size it is drawn at (after `ui.textScale`,
  `maxTextScale` and `autoShrink`). See [TEXT.md](TEXT.md), "Text that fits".
- `ui.measureText(text, { fontSize, font, maxWidth, space, maxTextScale, autoShrink, minFontSize, maxHeight, markup, bold })` →
  `{ width, height, fontSize }` laid out exactly like `Text` rendering
  (shaped, wrapped, with the fallback fonts). `space` is `"screen"` (default: HUD text and widget labels, measured at the
  size the player's text size option makes it) or `"world"`. Headless runs approximate (0.6 × fontSize per character,
  times `ui.textScale` for `"screen"`) and warn once. `markup` and `bold` are the `Text` fields of the same names
  ([TEXT.md](TEXT.md), "Rich text").
- `ui.markupProblems(text)` → `string[]`: what is wrong with the `[b]`, `[c:name]` and `[icon:name]` tags of `text`
  (unknown tag, `[` without `]`, unclosed tag, a colour or icon the project's `text` section lacks), `[]` when clean.
  A test can walk the strings of the game and fail with the list.
- `ui.textScale` (get / set, 0.5 to 3, default 1) is the player's text size option: screen-space `Text` and the labels of
  Button, Toggle, Slider and TextField are drawn and measured at `fontSize * ui.textScale`; world-space `Text` is never
  scaled. A value outside the range throws. The engine does not save it (keep it in `storage`), and each test file starts
  at 1. The command is `ui.set_text_scale`. Fonts, languages and right-to-left text: [TEXT.md](TEXT.md).
- `ui.scale` (get / set, 0.5 to 3) is the interface size option: every screen-space widget and `Text`/`Sprite`/`Shape2D` is
  laid out in UI units (the design screen divided by the scale) and drawn that many times as big; anchors do not move.
  It starts at the `"ui": { "scale" }` of `factoria.json` (default 1), each test file starts there again, and a value
  outside the range throws. `ui.rectOf` and `ui.state` rectangles are in screen pixels (they include it); `ui.measureText`
  and `Panel.size` are in UI units. The engine does not save it. The command is `ui.set_scale`; details, `Panel.minSize`
  and `maxSize` and the limits: [TEXT.md](TEXT.md), "Interface size".
- `ui.on("scale", fn)` and `ui.on("textScale", fn)` call `fn({ type, value, previous })` once per change of `ui.scale`
  or `ui.textScale` to another value, with the game events of the next frame (like `i18n.on("change")`), and return the
  function that stops listening. They have no target and end with the scene.
- `ui.speak(text, { interrupt = true })` says `text` aloud with the system's text to speech, in `i18n.language` (the system
  voice for it when there is one); `interrupt: false` queues it after what is being said. `ui.stopSpeaking()` stops and
  clears the queue. `ui.speechAvailable` is false where the system has no speech (Linux without speech-dispatcher, Android
  without a speech engine): `ui.speak` is then a no-op that logs one warning per run, so hide a "read menus aloud" option.
  Output only: it never touches the simulation. Headless runs, tests and the editor speak nothing and record every line:
  `game.spoken()` in `factoria:test` returns `[{ text, language, interrupt }]` (`game.clearSpoken()` empties it, and it
  is cleared before each test). Commands: `ui.speak`, `ui.stop_speaking`. Recipe (speak the focused widget, behind an
  option) and how to hear it on each system: [MENUS.md](MENUS.md).
- `ui.on`, `ui.focus`, `ui.focused` and `ui.hovered` belong to the widgets: see the next section.

### UI: menus, settings screens and HUD widgets
The widgets are components: `Panel` (a background that can lay out its children), `Button`, `Toggle`, `Slider`,
`TextField` and `ScrollList` (a Panel that scrolls and clips its children). They are drawn and hit-tested in SCREEN
SPACE only (design pixels, origin top-left, +Y down; there is no `space` field). `Transform.position` is the offset from
`anchor` (a fraction of the design size: `[0, 0]` top-left, `[1, 1]` bottom-right) and `pivot` says which point of the
widget sits there (`[0.5, 0.5]` centres it, `[0, 1]` puts its top-left corner on the position). Rotation and scale of UI
entities are ignored. Every field is documented in `docs/COMPONENTS.md`; the ones that matter:

- Style, on every widget: `size`, `pivot`, `anchor`, `layer` (draw order, default 200: above `Text`'s 100; a widget's
  label is drawn at `layer + 1` and its focus ring at `layer + 2`), `color` (background tint), `texture` + `slice`.
  With a `texture`, the background is drawn 9-slice: `slice` = `[left, top, right, bottom]` borders in texture pixels
  that keep their size (1 texture pixel = 1 design pixel) while the edges and the centre stretch, so one small PNG
  gives a button or panel of any size. `slice: [0, 0, 0, 0]` stretches the whole image.
- Button, Toggle, Slider and TextField also have `font`, `fontSize`, `textColor`, `accentColor` (focus ring, slider fill
  and knob, toggle check, caret), `interactable` (false: drawn at half alpha, never focused or clicked) and
  `autoFocus`. Read-only runtime flags: `focused`, `hovered`, `pressed` (a script may read them to restyle).
  Button has `text`; Toggle `label` + `value`; Slider `label`, `value`, `min`, `max`, `step`, `showValue`, `format` (`"{v:1}x"`, `"{percent}%"`; see
  the field's doc) and `formatKey`; TextField
  `text`, `placeholder`, `maxLength`.
- **Layout.** A `Panel` with `layout: "column" | "row" | "grid"` places its active children (widgets, and screen-space
  `Text`, `Sprite` and `Shape2D`) inside its rectangle minus `padding`: `spacing` between them, `align` (the cross axis:
  `start`, `center`, `end`; default center), `justify` (where the run sits along the main axis), `columns` for a grid, and
  `fit: true` makes the Panel as big as its content plus padding. Layout moves the children's `Transform.position`
  every frame, so a child's own position is only a starting point inside a laid-out Panel. `layout: "none"` (the default)
  leaves them where they are. Give a `Sprite` inside a container an explicit `size` (it is measured as 32 x 32 until
  the texture size is known to the layout); a `Text` is measured with the real font.
- **ScrollList.** Lays its children out as a column and shows the part inside its rectangle: everything drawn by its
  descendants (widgets, `Text`, `Sprite`, `Shape2D`) is clipped to it, and hits outside it do nothing. The mouse wheel
  over it scrolls (`scrollSpeed` pixels per notch) and moving the focus to a child scrolls it into view. `scroll` is
  the offset in pixels (scripts may write it; it is clamped). A list that has more content than it shows keeps the
  wheel: `input.mouse.wheel` reads 0 for that frame and `ui.wheelConsumed` is true (see "Pointer, hit test and the
  wheel" below), so a camera that zooms with the wheel needs no check of its own.

**Focus and navigation.** A widget can have keyboard / gamepad focus when it is a Button, Toggle, Slider or TextField,
active and `interactable`. Nothing takes focus by itself except one thing: when no widget is focused, the first
focusable widget (top to bottom, then left to right) with `autoFocus: true` takes it. So a HUD button never reacts to the
gameplay keys; a menu marks its first item `autoFocus` (or calls `ui.focus(...)` when it opens). A focused widget that is
destroyed, deactivated or made not interactable loses focus, and `autoFocus` applies again. When every visible
`autoFocus` widget has `interactable: false` (a greyed-out buy button), the first interactable widget in reading order
takes the focus instead. The actions below move the focus to the nearest focusable widget in that direction: first among
the widgets lined up with the focused one (overlapping it across the direction, like the next tab of a row or the row
under a tab), and only when there is none, anywhere in that half of the screen (holding repeats after 0.4 s, then every
0.1 s; it does not wrap):

| action | default bindings | does |
|---|---|---|
| `ui_up` `ui_down` `ui_left` `ui_right` | arrows, d-pad, left stick | move the focus; on a focused Slider, left / right change the value by `step` |
| `ui_submit` | Enter, Space, `GamepadA` | click the focused Button, flip the focused Toggle (a TextField ignores it) |
| `ui_cancel` | Escape, `GamepadB` | send `ui.cancel` (also with nothing focused) |

The engine installs these six unless `input.actions` in `factoria.json` defines an action of the same name, so to rebind
a key, add the action there: `"ui_submit": ["Enter", "GamepadA"]` (the project's list replaces the default one).
A focused TextField takes typed characters (`maxLength` code points, UTF-8), Backspace deletes (it repeats) and the
Enter key sends `ui.submit`. The mouse (and the first touch) hovers, presses and focuses; a Button or Toggle acts when
the press is released over the same widget; a Slider follows the pointer while pressed.

**The UI works while the game is paused** (`time.scale = 0`): it runs on real time, which is what a pause menu needs.

**Events.** The UI sends game events (`world.on(name, (data, source) => ...)`, `Behaviour.onEvent`), with the widget as
`source` and `data.id` its entity id:

| event | when | `data` |
|---|---|---|
| `ui.click` | a Button was clicked (mouse, or `ui_submit` while focused) | `{ id }` |
| `ui.change` | a Toggle flipped, a Slider moved, a TextField was edited | `{ id, value }` (boolean, number, string) |
| `ui.submit` | Enter in a TextField | `{ id, value }` |
| `ui.focus` | a widget took the focus | `{ id }` |
| `ui.cancel` | `ui_cancel` was pressed | `{ id }` (`null` when nothing is focused) |

- `ui.on(type, fn)` / `ui.on(type, target, fn)` → unsubscribe function. `type` is `"click"`, `"change"`, `"submit"`, `"focus"`
  or `"cancel"`; `target` (an Entity or an entity id) limits it to one widget; `fn` gets `{ type, id, entity, value }`.
  A wrong `type` throws with a "did you mean". Inside a behaviour prefer `this.on("ui.click", (data, source) => ...)`:
  it is removed with the behaviour. Scripts do not need to poll the widgets:
  ```js
  ui.on("click", "play_button", () => scene.load("scenes/level1.scene.json"));
  ui.on("change", "music_volume", (e) => audio.setVolume("music", e.value));
  ```
- `ui.layout()` runs the UI layout now, as every frame does: change a label, call it, then read `Button.size`,
  `Panel.size` or `ui.rectOf(...)`. `Panel.usingFallback` tells whether a panel is laid out with its `fallbackLayout`.
- `ui.focus(target | null)` gives the focus to a widget (null clears it) and sends `ui.focus`; it returns `true` when the
  widget took the focus and `false`, changing nothing, when the widget has `interactable: false` (a greyed-out button: fall back to
  another one); it throws, saying why, when the entity is not a focusable widget or is inactive. `ui.focus(null)` holds: an open
  panel's `autoFocus` does not take the focus back until the next `ui_up` / `ui_down` / `ui_left` / `ui_right` press
  (that press only wakes `autoFocus`; it does not also move the new focus). `ui.focused` and `ui.hovered`
  are the focused widget and the one under the pointer (Entity or `null`): check `ui.hovered` so a click meant for a
  button does not also fire the gun.
- **Pointer, hit test and the wheel.** `ui.widgetAt(x, y)` is the topmost visible widget at a screen point (design
  pixels, y down) or `null`: a Button, Toggle, Slider, TextField, ScrollList, Panel (one that draws something: alpha 0
  with no texture is skipped), a shown TouchStick / TouchButton. Topmost is the highest `layer`, then the entity made
  last. What a ScrollList clips away at that point, an inactive widget and empty space give `null`; a widget with
  `interactable: false` is returned (check the component). `ui.pointerOverUi` says the same for the pointer at this
  frame's UI update: a game's own click or zoom skips when it is true. `ui.setPointer(x, y, { down })` replaces the
  mouse for the UI from the next frame on (hover, press, Slider drag, click on release, the wheel's target) until
  `ui.setPointer(null)`; use it for a gamepad cursor and in tests. `ui.wheelConsumed` is true on a frame whose wheel
  scrolled a ScrollList (`input.mouse.wheel` reads 0 then).
- **Tooltips.** `tooltip` on any widget or Panel is a string (a localization key or plain text) or
  `{ "title", "lines": [text | {text, color}], "args" }`; `ui.setTooltip(entity, fn)` registers a function that returns
  that content when the tooltip is about to show (null: none). It shows after `ui.tooltipDelay` seconds (get / set, 0 to
  60, default the `"ui": { "tooltipDelay" }` of `factoria.json` or 0.5) of rest within 5 pixels, beside the pointer and
  flipped to stay on screen, and hides when the pointer moves off, a button is pressed or another widget is reached. A widget
  without one uses the nearest ancestor's. `ui.setWorldTooltip((x, y) => content)` answers for a pointer over no widget
  (a map), `ui.showTooltip(content, { x, y })` shows one now until `ui.hideTooltip()`, a pointer move of more than 5
  pixels or a scene load, and `ui.tooltip` reads the one on screen (`null` or `{ title, lines, rect, source, widget }`;
  the same as `tooltip` in `ui.state`). The rest is counted in UI time, so `game.step` tests are exact. Look, touch and
  recipes: [MENUS.md](MENUS.md), "Tooltips".
- **Drag and drop.** `draggable` on a widget (`true` or `{ "payload", "slop" }`) lets the player drag it. `ui.on("dragStart" |
  "dragOver" | "drop" | "dragCancel", fn)` gets `{ id, entity, source, payload, x, y, target, accepts, reason }` (`target` is
  `null` over the world); `ui.setDropTarget(widget, true | false | fn | null)` and `ui.setWorldDropTarget(...)` say what
  accepts a drop, `ui.setDragImage(widget)` makes a widget follow the pointer, `ui.cancelDrag()` ends the drag and
  `ui.dragging` is `null` or `{ source, payload, from, x, y, target, accepts }`. The click the release would make never
  happens. In tests `game.drag(from, to)`. Details: [MENUS.md](MENUS.md), "Drag and drop".
- **`active` and `activeInHierarchy`.** `entity.active = false` hides the entity and everything under it, but it does not
  change the `active` of the children: a child of a hidden Panel keeps `active` true. `activeInHierarchy` is true only when
  the entity and every ancestor are active, so ask that to know whether a menu is open (`panel.activeInHierarchy`), not
  `child.active`. `ui.rectOf` returns `null` and `ui.state` leaves out an entity whose `activeInHierarchy` is false.
- The command `ui.state` returns what is on screen: every widget with its `id`, `kind`, `rect` `[x, y, w, h]`,
  `focused`, `hovered`, `pressed`, `interactable`, `visible` and `value` / `text`, in reading order. Use it to find what
  to click (`game.input` with `mouse.position`) or which widget has the focus.
- Tests: drive a menu with pad taps and assert on events and values, no mouse needed:
  ```js
  game.loadJson(menuScene); game.step(1);
  const pad = game.gamepad();
  pad.tap("DpadDown"); pad.tap("DpadRight");   // focus the slider below, +1 step
  pad.tap("A");                                // ui_submit on the focused widget
  ```

### assets
- `assets.textureSize(path)` → `{ width, height }` (same shape as `ui.measureText`): the pixel size of the texture file at
  the project-relative `path`, for example `assets.textureSize("assets/hero.png")`. It is the size a `Sprite` without
  `size` or `region` is drawn at and the one `entity.bounds()` uses. A missing or unreadable file gives 32 × 32 (the size
  of the missing-texture checker). It reads the file, so it works headless; the result is cached per file and
  modification time, so calling it every frame is cheap. An empty or non-string `path` throws.
- `assets.preload(paths)` → a preload handle (below): reads the files ahead of time, for assets a script uses later.

### Preloading: `scene.preload(path)`, `assets.preload(paths)`
`scene.load` reads the scene and everything it uses before the frame goes on, so a big level freezes the game for a
moment. `scene.preload("scenes/level2.scene.json")` returns a handle at once and reads the scene file and what it points
at (prefabs, materials, textures, models with their `.bin` and images, audio, fonts, and the scripts and files named in
them) a little every frame, so a loading screen keeps running and drawing. The files then wait in memory: `scene.load` of
that scene, and the renderer and audio on first use, find them there and read nothing from the disk.
`assets.preload(["assets/boss.glb", "assets/boss.ogg"])` does the same for a list of files.

```js
const job = scene.preload("scenes/level2.scene.json");   // in onStart of the loading scene
// every frame: bar.get("Shape2D").size = [400 * job.progress, 16];
job.promise.then(() => scene.load("scenes/level2.scene.json"));
```
- The handle has `progress` (0..1, never goes down), `done`, `files` and `bytes` read so far, `error` (`""` or why it
  failed), `promise` (resolves with `{ files, bytes }`, rejects with an Error that has `.hint`) and `release()`.
  Its values change between frames only. A script that only polls `done` is not reported for an unhandled rejection.
- Work is counted in units, one per file; the first unit reads the scene (or the first assets) and finds everything it
  names, so `progress` is exact from the second frame on. Per frame: **tests, headless runs and replays do exactly four
  units**, so what a test sees (how many frames it takes, which `progress` values) is the same on every machine; **a game
  with a window** works until about 4 ms of the frame are used (at least one unit), so the number of frames depends on
  the machine and the game must not depend on it. A worker thread may do the reading later without changing the handle.
- A path that does not exist throws at once with a "did you mean" list; a read error (or a scene that is not JSON) sets
  `error` and rejects the Promise. The loading scene should still call `scene.load` in that case, which reports it.
- The Promise outlives the scene that asked: a loading scene that is left before it resolves (a test that moves on)
  sets a flag in `onDestroy` that its callback checks, and calls `release()` there unless its own `scene.load` already ran
  (releasing then would drop the files the load is about to read). docs/MENUS.md has the recipe.
- Memory: the files stay for the first scene load after the job finished and are dropped at the second (or by
  `release()`), so a preload costs about one scene's files beyond the one in use. A file changed on disk since it was read
  is read again.
- Tests: `game.fileReads()` counts the files read from the disk; compare two values to prove a load read nothing.

### scene / game / storage
- Promises: a rejection nobody handles is logged once as `unhandled promise rejection: ...`, but only if it is still
  unhandled once the pending promise jobs have run (as in Node). `p.then(() => platform.achievements.unlock(id)).catch(() => {})`
  logs nothing when the store rejects.
- `scene.load(path, props?)` (deferred to frame end) · `scene.reload()` · `scene.current` · `game.sceneProps()` (see "Scene props")
- `game.today()` (see "The date") · `game.focused` · `game.on("gamepadConnected" | "gamepadDisconnected", fn)` (see "Pads plugged in and out") · `game.on("suspend" | "resume" | "focus" | "blur", fn)` (app lifecycle,
  see MOBILE.md "Lifecycle"; `pauseOnSuspend` in `factoria.json`, default `true`, pauses the game and the music while the
  app is in the background) · `game.on("quit", fn)`: see "Window close" below
- `clipboard.read()` (a Promise of the text) · `clipboard.write(text)`: see "Clipboard" below
- `game.quit()` · `game.paused` (see `time`) · `game.project` (read-only factoria.json) · `game.screenSize` ·
  `game.platform` (`"windows"`, `"macos"`, `"linux"`, `"ios"`, `"android"` or `"web"`: e.g. no Quit button on phones)
- `game.accessibility` (read-only, frozen) → `{ textScale, reduceMotion, highContrast, screenReader }`: the player's
  operating system settings, for your options screen to start from (recipe: MENUS.md). `textScale` 1 = 100 %, clamped to
  0.5 - 4; the others are booleans. Read when the game starts and again when the window regains focus or the app
  resumes. The engine applies none of them: you apply them and save the player's own choice. Where each platform reads
  them, and what it cannot: Windows (animations off, high contrast, screen reader, Text size setting), macOS (reduce
  motion, increase contrast, VoiceOver; text size always 1), iOS (reduce motion, darker colours, VoiceOver, Dynamic Type),
  Android (font scale, animator scale 0, high contrast text, TalkBack/touch exploration), Linux (GNOME settings through the
  `gsettings` program; KDE, Xfce and other desktops give `1` / `false`), web (`prefers-reduced-motion`,
  `prefers-contrast: more` or `forced-colors: active`; browsers do not tell the text size or a screen reader, so `1` and
  `false`). Headless runs, `factoria test` and the editor always give `{ textScale: 1, reduceMotion: false, highContrast:
  false, screenReader: false }`; tests change it with `game.setAccessibility({ textScale: 1.5, reduceMotion: true })`
  (reset before every test).
- `game.notices()` → `[{ name, url, license, usedFor }]`: the third-party software inside the runtime every game ships
  (FactorIA first), the parts whose license texts `factoria export` writes to `FACTORIA_NOTICES.txt`. For a credits
  screen.
- `storage.get(key, fallback)` · `storage.set(key, value, options?)` · `storage.remove(key)` · `storage.size(key)` ·
  `storage.setAsync(key, value, options?)` — persistent JSON save data. **One file per key** in
  `<user dir>/storage/` (`slot1.json`; a name keeps lowercase letters, digits, `_` and `-` and writes every other byte as
  `%XX`, so `"Slot 2"` is `%53lot%202.json` on any disk), each holding `{"key": ..., "value": ...}`: a save rewrites its
  own key only, however many other keys (or big saves) there are. A `storage.json` left by an older version is read at
  the first start, split into key files (keys that already have a file keep it) and renamed `storage.migrated.json`, so
  nothing is lost if that start is interrupted. Tests always use an empty in-memory storage per test file and never
  touch the real save; the runtime can run headless with `ScriptSystem::set_storage_mode(StorageMode::Memory)`.
  Every file is written atomically (a temporary file, then a rename): a crash during a save leaves the previous file
  intact, and a leftover temporary file is ignored.
- `storage.set(key, value, {compress: true})` stores the value zlib-compressed (the file is `{"key", "z": "zlib", "n",
  "data": <base64>}`): a big, repetitive save takes a fraction of the disk space and `get` returns the same value. Any
  other option throws with a suggestion. `storage.size(key)` is the number of bytes the key's file takes (the compressed
  size for a compressed value; `0` when the key is not stored): measure a save, or choose to compress above a size.
- `storage.setAsync(key, value, options?)` returns a Promise that resolves with the file's size once the file is written
  (and rejects with the reason when it cannot be). `storage.get` returns the new value at once; the encoding, the
  compression and the write happen off the frame: on a worker thread on desktop and phones, and between frames on the web
  (a browser player has no threads). Serializing `value` to JSON still happens in the call. Writes to one key land in the
  order they were asked; `set`, `remove`, `clear` and `size` wait for the writes still running, and the game does not
  end before they finish. The writes still waiting are also made right after the `suspend` and `quit` handlers run, so a
  `setAsync` from one of them is on disk (on the web, in the copy sent to IndexedDB) before the app is hidden or closed. In a test the write is deferred to the next `game.step`, so
  `const p = storage.setAsync("slot", data); game.step(1); await p;`. A Promise outlives nothing it needs: storage is not
  tied to a scene.
- `storage.corrupt` — `true` when a storage file (a key's file, or an older `storage.json`) did not parse at the first use
  of `storage` in this run. The damaged file is **kept** as `storage.corrupt.json` in the save folder
  (`storage.corrupt.2.json`, `.3`... when one is already there: an earlier one is never replaced), the engine logs a
  warning naming it, and the game starts without that file's data (the other keys load); the next save writes a new valid
  file and never touches the kept one. Check it at start to tell the player or offer a recovery. A test starts from a
  damaged save with `game.setStorageText('{"broken')` (from `factoria:test`; it sets the text the next storage load reads
  as if it were an old `storage.json` and reloads, then `storage.corrupt` is `true`).
  On the web the save folder lives in IndexedDB and the same rules apply to its copy of the files. A web page that is
  hidden or closing copies it to IndexedDB right after the `suspend` and `quit` handlers have run (see below), so a
  `storage.set` made inside one is kept.

### Window close: `game.on("quit", fn)`

On a desktop window, the close button, Cmd+Q (macOS) and Alt+F4 (Windows) raise `quit` before the window closes. The
handler gets an event with `cancel()` and `cancelled`; call `event.cancel()` to keep the game running (ask "Quit
without saving?" and call `game.quit()` when the player agrees). Without a handler, or when no handler cancels, the
window closes. `game.quit()` closes the window without raising `quit` again, so a handler may call it. Phones never
raise it (the OS closes the app on its own terms), and a headless run only sees it when a test calls `game.closeWindow()`.
Cancelling is not guaranteed on every platform: a window the OS is shutting down can close anyway.

On the web, `quit` is raised when the page is going away (`pagehide`: the tab closing, a reload, leaving the site) and it
**cannot be cancelled** there: `event.cancel()` does nothing. Use the handler to save; whatever `storage.set` wrote
inside it is copied to the browser's IndexedDB at once, after the handlers have run. The browser may still drop the
page before the copy finishes (a crash, a killed tab), so a game that cannot lose progress also saves on a timer.

**Which signals each platform raises:**

| | `blur` / `focus` | `suspend` / `resume` | `quit` |
|---|---|---|---|
| Windows, macOS, Linux | the window loses or gains focus, or is minimised and restored | never | the close button, Cmd+Q, Alt+F4; can be cancelled |
| Web | the page loses or gains focus (`window` blur and focus) | the tab is hidden or shown again (`visibilitychange`: a tab switch, a minimised window, a phone's app switcher) | the page is closing (`pagehide`); cannot be cancelled |
| Android, iOS | a system dialog over the app | the app goes to the background and comes back | never |

The web's `suspend` is also raised when the browser takes the WebGL context away. A hidden tab raises `suspend` once
however many events the browser sends, and `resume` only after a `suspend`.

```js
import { game } from "factoria";
game.on("quit", (event) => {
  if (hasUnsavedProgress()) { event.cancel(); openQuitDialog(); }
});
```

### Clipboard: `clipboard.read()` and `clipboard.write(text)`

- `clipboard.write(text)` puts a string on the system clipboard (it throws on a non-string).
- `clipboard.read()` returns a Promise of the clipboard text (`""` when it holds none). Check that its scene is still the
  current one before acting on the answer.
- `window.supports("clipboard")` is true on Windows, macOS, Linux and the web. On phones and tablets `read()` rejects with
  an Error whose `code` is `"unsupported"` and `write` does nothing. Headless runs and tests use an in-memory clipboard
  (empty at the start of every test), so `write` then `read` gives the text back.
- On the web a browser only lets a page read the clipboard while the player pastes (Ctrl/Cmd+V), and `read()`
  resolves with the text of the last paste. Prefer a `TextField` for pasting there.
- A focused `TextField` pastes with Ctrl+V (Cmd+V on macOS) and copies with Ctrl/Cmd+C by itself (docs/MENUS.md).
- Replays: a `"clipboard": "text"` entry in a `--input` file puts that text on the clipboard before its frame; editor play
  sessions record the first thing a frame read, so a replay of a paste is exact.

### Render: a picture of the running game as a texture (`render.captureTexture`, `render.textureFromPNG`)

For a save slot's thumbnail, a photo mode or a minimap snapshot. A texture's `id` is accepted by `Sprite.texture`, `Panel.texture`
and `Button.icon` (docs/COMPONENTS.md).

- `render.captureTexture({ width, height, fit })` returns a `Texture`: the picture the player sees (HUD and every camera) at
  `width` x `height` pixels, each from 1 to 2048. `fit: "cover"` (default) cuts the middle part with that aspect ratio out of the
  frame, so nothing is distorted; `"stretch"` squeezes the whole frame in.
- Which frame: called from a script during a frame (an `onUpdate`, an event handler) it is the last frame that was drawn. In a
  test, before any frame was drawn and in headless runs it draws the current state first, like `game.screenshot`. A capture
  the size of the game (`game.screenSize` times `window.renderScale`) has exactly the pixels of a screenshot of that frame.
  The frame is read back from the GPU (Metal, OpenGL / GLES, Direct3D 11, WebGL2) and resampled on the CPU.
- A run with `graphics` off has no renderer: the texture is a flat colour of the size asked and `texture.placeholder` is
  `true`. Check it before you store the picture if a flat square would mislead the player.
- `texture.id` (`"runtime:3"`) goes where an asset path goes: `entity.get("Sprite").texture = tex.id`, `Panel.texture`,
  `Button.icon`. A Sprite with no `size` takes the texture's pixel size. A `Panel` samples it without smoothing.
- `texture.toPNG()` returns the picture as a PNG file Base64-encoded, a string, because `storage` keeps JSON only:
  `storage.set("slot1.pic", tex.toPNG())`. `render.textureFromPNG(text)` makes a texture of it again (a `data:image/png;base64,`
  URL works too). Both are synchronous: there is no Promise and no scene change to wait for. A Base64 string is about a third
  longer than the file, so keep pictures small (a 156 x 156 town picture is a few KB).
- At most 32 textures are alive at once. `texture.destroy()` frees one (safe to call twice; `toPNG()` then throws). Stop
  showing a texture (destroy its entity or change the texture field) before you destroy it: a frame that still names it draws
  the missing-texture checker and logs why. Every test file starts with no textures.
- The engine keeps each texture's pixels in memory as well (width x height x 4 bytes) so `toPNG()` works in every run.

```js
// Save: the picture goes into storage with the slot. Take it BEFORE a menu covers the game.
const tex = render.captureTexture({ width: 156, height: 156 });
if (!tex.placeholder) storage.set("slot1.pic", tex.toPNG());
tex.destroy();

// Show: build the texture, use its id, destroy it when the thumbnail goes away (a behaviour of the thumbnail entity).
onStart() {
  const png = storage.get("slot1.pic", null);
  if (png) {
    this.pic = render.textureFromPNG(png);          // throws a teaching Error for text that is not an image
    this.entity.get("Panel").texture = this.pic.id;
  }
}
onDestroy() { if (this.pic) this.pic.destroy(); }
```

Nothing here awaits an answer, so there is no scene to re-check; if you capture inside a `scene.preload` or `http`
callback, compare `scene.current` with the scene you started in before you act on it.

### The date: `game.today()` (never `Date`)
`new Date()` and `Date.now()` read the wall clock, so a run is different every time and a test cannot pin it. Read the
calendar date with `game.today()` instead, as you use `rng` for chance:

```js
import { game, rng } from "factoria";
const t = game.today();   // { year: 2026, month: 3, day: 14, weekday: 6, hour: 23, minute: 59, second: 30, utcOffsetMinutes: -300,
                          //   iso: "2026-03-14", utc: { year: 2026, month: 3, day: 15, iso: "2026-03-15" } }
rng.seed(t.year * 10000 + t.month * 100 + t.day);   // a daily challenge: everybody plays the same seed on the same day
```

`weekday` is 0 = Sunday to 6 = Saturday; `hour`, `minute` and `second` are the local time of day; `utcOffsetMinutes` is the
local offset from UTC and `utc` is the date of the same moment in UTC (pass `utc.iso` as a leaderboard's `options.day` for one daily board
worldwide, see PLATFORM.md, "Leaderboard periods"). In a built game the date and time are the player's real local ones,
read when the game starts, about once a minute while it runs, and each time the app comes back to the foreground or the
window gets the focus (before `game.on("resume")` / `game.on("focus")` run), so `game.today()` is at most a minute behind the
clock. When the local calendar day changes meanwhile (past midnight, a clock set to another day, a game left in the
background overnight) the game event `dayChanged` goes to `game.on("dayChanged", (today) => ...)` once, with the new
`game.today()`: refresh the daily challenge, the daily reward and the daily leaderboard there. A change of time zone or
daylight saving alone is not a new day.
In `factoria test`, `factoria run --headless`, `call`, `session`, `mcp` and `screenshot` it is the fixed date
`2026-01-01` at 00:00:00 and never moves, so runs are reproducible; `--date YYYY-MM-DD[THH:MM[:SS]]` chooses another (see
CLI.md). A replay recorded in the editor stores the date, time and offset it was played on (`date`, `time`,
`utcOffsetMinutes`) and plays back with them, so a daily run replays identically even when it was recorded at 23:59 (an
older replay without a time plays at 00:00:00, one without a date on the fixed default date). The replay keeps the date it
started on: a midnight crossed during a recorded session is not replayed. In tests `game.setDate("2026-03-14")` changes
the date (reset before each test); `game.setDate("2026-03-14T23:59:30", { utcOffsetMinutes: -300 })` also sets the time and
the time zone, and moving to another local day sends `dayChanged` once, so a test crosses midnight with two calls
(`"2026-03-14T23:59:59"`, then `"2026-03-15T00:00:01"`). An impossible date or time throws an error that says which part is
wrong.

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

const saved = r.state;                 // one 32-bit number: the whole stream, for a save game
r.float();
r.state = saved;                       // the stream resumes there: the next float() repeats
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
- **State.** `generator.state` is the 32-bit state, an integer from 0 to 4294967295: the seed advanced by `0x6d2b79f5`
  (modulo 2^32) per draw. Read it to store the stream in a save; assign it (or pass it to `rng.create`) to resume. It
  is as stable as the algorithm. Assigning something that is not such an integer throws and keeps the old state. Keep one
  generator per purpose (ships, events) so a new draw in one does not shift the others.
- 32 bits of state means a period of 2^32 draws: plenty for a level or a table, not meant for cryptography.

### math & values
- `vec2(x, y)`, `vec3(x, y, z)`, `color(r, g, b, a?)` / `color("#ffcc00")`
- `Vec2`/`Vec3` methods: `add sub mul scale div dot length lengthSq normalized distance lerp clone equals`,
  `Vec2.fromAngle(deg)`, `v.angle()`, `v.rotated(deg)`
- `math`: `clamp lerp inverseLerp remap damp moveTowards approach sign degToRad radToDeg wrapAngle`
- `console.log/warn/error` go to the engine log (category `script`).

### plugins (native code)
`plugins.<name>.<function>(...args)` calls a function of a native plugin the game declares in `factoria.json`
(`"plugins"`; [EXTENDING.md](EXTENDING.md), section G): `plugins.example.add(1, 2)`. Arguments and the result travel as
JSON. A plugin's functions and their doc strings are in `types/factoria.d.ts` (`PluginsAPI`) once the plugin is loaded.

- On a platform the plugin is not declared for, `plugins.<name>` is `undefined`: `if (plugins.steam) ...`.
- A plugin that did not load (no build for this platform, its entry point failed) is still there, and any use throws
  with the reason: `plugins.steam.unlock: the native plugin 'steam' is not loaded: ...`.
- A function that fails throws `plugins.<name>.<function> failed: <message> (hint: <hint>)`; a name the plugin does not
  have throws with a did-you-mean and the names it has.
- A plugin's commands are ordinary commands: `fa.call("example.info", {})`.

### platform (stores: achievements, purchases, cloud saves...)
`import { platform } from "factoria"`: achievements, stats, leaderboards, cloud saves, in-app purchases, the store overlay
and rich presence behind one API that every store backend answers (the fake store in development and in all tests, a
store SDK through a native plugin). **Every call returns a Promise**; ids come from the `"platform"` catalog in
`factoria.json`, and a typo throws at once with a "did you mean". Store failures reject with `e.code` and `e.hint`.

```js
if (platform.has("achievements")) platform.achievements.unlock("first_win").catch(() => {});
const r = await platform.purchases.buy("gems_100");               // { status, productId, transactionId, receipt }
if (r.status === "purchased") { addGems(100); await platform.purchases.finish(r.transactionId); } // grant, then finish
platform.on("overlay", (e) => (game.paused = e.open));            // also "purchase" and "player"
```

Members: `backend`, `has(service)`, `player`, `signIn()`, `on(event, fn)`, `achievements` (`unlock progress list reset`),
`stats` (`get set add`), `leaderboards` (`submit entries`), `cloud` (`save load list remove`), `purchases` (`products buy
finish restore`), `overlay.open(page, id?)`, `presence.set(text, data?)`, `integrity.token(challenge)` (a signed token for the game's own
server to verify). Everything about it, the catalog, the error
codes, the fake store's test hooks (`game.platform` in `factoria:test`) and how to write a backend plugin, is in
[PLATFORM.md](PLATFORM.md). `game.platform` of the `factoria` module is the operating system's name, a different thing.

### http (web requests)
`import { http } from "factoria"`: `http.fetch(url, { method, headers, body, timeout })` returns a Promise of the server's
answer `{ status, ok, headers, text, json() }`, on every platform (WinHTTP, `NSURLSession`, libcurl, `HttpURLConnection`,
the browser's `fetch`). The game declares the servers it may call in `factoria.json` (`"network": { "hosts": [...],
"purpose": "..." }`); `https://` only; an undeclared host throws at once. Tests get the fake: `game.platform.respond("http.fetch",
{ status: 200, json: {...} })`, no network. The answer may arrive after the scene changed: check `scene.current` before
using it. Limits, the recipe, replays, per-platform notes (CORS on the web, the Android permission) and the privacy side:
[NETWORKING.md](NETWORKING.md). Usage events (after the player consents) and values read from your server, both on top of
`http.fetch`: `analytics.event(name, props)` and `remoteConfig.get(key, fallback)`, in [ANALYTICS.md](ANALYTICS.md).

```js
const r = await http.fetch("https://api.example.com/daily").catch(() => null);   // rejects on a network failure
if (r && r.ok) startChallenge(r.json().seed);                                   // a 404 resolves with ok: false
```

### i18n (several languages)
`import { i18n } from "factoria"`: the strings of `locales/<language>.json` in the player's language (factoria.json
`"localization"` lists the languages; without it `t(key)` returns the key and `languages` is `[]`). A Text or widget
with a `key` is translated by the engine; `t` is for the text a script builds.

```js
label.text = i18n.t("hud.coins", { count: coins });      // "3 monedas": {placeholders} and plural forms by args.count
i18n.setLanguage("es");                                   // everything with a key changes now; the choice is not saved
const off = i18n.on("change", (e) => redraw(e.language)); // after every switch; ends with the scene, like ui.on
```

`i18n.number(1234.5)` ("1,234.5", "1234,5" in Spanish) and `i18n.duration(83.4)` ("1:23.4") write numbers and times the
way the current language does.

Members: `t(key, args?)`, `number(v, {decimals?})`, `duration(seconds, {decimals?})`, `has(key)`, `language`, `setLanguage(tag)`, `languages`, `defaultLanguage`, `systemLanguages`,
`name(tag)`, `on("change", fn)`. Every test file starts in `defaultLanguage`. All of it, the string tables and how the
start language is chosen: [LOCALIZATION.md](LOCALIZATION.md).

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

## Debugging

F5 in VS Code runs the game (or the tests) with breakpoints, stepping, the Variables view and a debug console; the
command `script.trace` gives an AI the same facts as one JSON answer. Install the VS Code extension with
`factoria setup vscode`. Guide: [DEBUGGING.md](DEBUGGING.md).

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
- `robust(check, { runs = 5, nudge = 0.005 })`: runs `check(p)` `runs` times under small repeatable perturbations and fails naming the run that failed. Run 0 is not perturbed; `p.nudge(...entitiesOrIds)` moves entities by up to `nudge` metres per axis and `p.nudgeBodies()` does it for every RigidBody2D/3D (call it after `game.load`, before the first `game.step`; the check loads its own scene). Offsets are a hash of the run, the entity id and the axis, not the RNG, so a test nudges the same way everywhere. The engine's physics gives the same bits on Linux, Windows and macOS (AI_GUIDE.md, "Physics and platforms"), but a change to a level, to a script that feeds numbers into physics, or to the engine moves a chaotic setup anyway: use `robust` where a level test would otherwise assert an exact frame count or position of such a setup, and assert what holds for every run (reached, delivered, a range, "not slower than").
- `expect(v)`: `toBe toEqual toBeCloseTo(n, digits) toBeGreaterThan toBeGreaterThanOrEqual toBeLessThan
  toBeLessThanOrEqual toBeTruthy toBeFalsy toBeNull toBeDefined toContain toHaveLength toThrow`, and `.not`;
  for sounds `expect(game.audioLog()).toContainPlayed(path, { times?, bus?, source? })` (alias `toHavePlayed`; `path`
  is a project path, a file name such as `"jump.wav"`, or a RegExp; plays whose clip failed to load do not count)
- `game`: `load(path)` (behaviours are constructed immediately, `onStart` runs on the first `step`),
  `loadJson(sceneObject)`, `step(frames = 1)`, `touch(pos, frames = 1)`, `touchStart(pos, id?)`, `touchMove(pos, id?)`,
  `touchEnd(id?)` (fill `input.touches`; `pressed` is true for the frame after `touchStart`; like a finger on a device,
  the first finger also moves the mouse and holds the left button, so `touch` alone tests mouse handling too: no
  `click` needed), `press(action)`, `release(action)`, `tap(action)`,
  `keyDown(key)`, `keyUp(key)` (hold and release; `"Ctrl"`, `"Shift"`, `"Alt"`, `"Super"` work, so `keyDown("Shift"); click(pos);
  keyUp("Shift")` is a Shift+click), `tapKey(key)` (`tapKey("Ctrl+Z")` holds Ctrl while Z is tapped), `gamepad(index = 0)`, `mouseMove(screenPos)`, `click(screenPos, button?)`, `find(idOrName)`,
  `world`, `time`, `screenshot(path, {scale?})` (scale 0.25 to 4 renders natively larger), `state()`, `audioLog()` (sounds played since the test started:
  `[{ kind, voice, fade, seq, frame, time, path, volume, pitch, pan, bus, loop, music, source, ok, layer }]`, cleared before each test),
  `today()`, `setDate("YYYY-MM-DD")` (the fixed date is `2026-01-01`; reset before each test), `focused`, `suspend()`, `resume()`,
  `focus()`, `blur()` (what the OS does to the app, so lifecycle code can be tested),
  `renderStats()` (what the renderer drew in the picture now, drawing a frame first when none was drawn: `{ drawCalls,
  triangles, lights, shadowCasters, meshes, textureMB, width, height, renderScale, ... }`; throws without graphics),
  `setDevice({ formFactor?, gpuBackend?, memoryGB?, tier?, steamDeck?, handheld? })` (see `game.device`),
  `clearAudioLog()`, `spoken()` (what `ui.speak` was asked to say: `[{ text, language, interrupt }]`, cleared before each test), `clearSpoken()`

More `game` calls for tests: `mouseDown(button = "left")` and `mouseUp(button)` hold and release a mouse button (`input.mouse.down(button)`
follows; with `mouseMove` they test a drag), `wheel(dy)` turns the wheel for the next frame
(`input.mouse.wheel`), `quitRequested` (true once the game asked to quit with `game.quit()` or an unconsumed Back; a test
run never stops because of it, and it is cleared before each test), `closeWindow()` (the player pressed the close
button: raises `game.on("quit")` and returns true when the window would close, false when a handler cancelled), `setSystemLanguages(["es-ES", "en"])` (what
`i18n.systemLanguages` answers, so a game's own first-run language choice can be tested; the engine's start language is
not picked again, a test starts in the default language; empty again before each test) and
`resetState({ storage = true, platform = true })`, which clears the save data and resets the fake store (purchases,
unlocks, ads, leaderboards; see docs/PLATFORM.md) between tests of one file. Each test file already starts clean; tests of
one file share storage and the fake store unless you call `resetState`.

**Clicking a widget.** `game.click(widget)` (also `mouseMove`, `touch`, `touchStart`, `touchMove`) given an `Entity` or an
id/name lays the UI out first, so a panel opened in the same frame (`panel.active = true`, then `game.click("close")`) is
already in place with no `game.step` or `ui.layout()` between. It throws, naming the widget and why, when the widget cannot
be clicked: it or a parent is inactive, it has no area (size 0), or it is scrolled out of its `ScrollList`. Pass a position
`{x, y}` to click a spot whatever is there.

**Keys.** `game.tapKey(key)` presses and releases a key over one frame (press, step, release, step), as `tap` does for an
action; `keyDown` / `keyUp` hold it. A `TextField` reads the Enter key itself, not an action, so this submits it:

```js
test("Enter submits the name", () => {
  game.load("scenes/menu.scene.json");
  const submitted = [];
  ui.on("submit", "name_field", (e) => submitted.push(e.value));
  game.click("name_field");                              // focuses the TextField
  game.find("name_field").set("TextField", { text: "Mara" });
  game.tapKey("Enter");                                  // the field sends ui.submit { id, value: "Mara" }
  expect(submitted).toEqual(["Mara"]);
});
```

**Saving a file from a test.** A test can call any command with `fa.call`, and `fs.write` writes a project file (text up to
8 MiB; `.factoria/` is refused except `.factoria/tmp/`): keep a recording or a layout dump to look at afterwards.

```js
test("dump the menu layout", () => {
  game.load("scenes/menu.scene.json");
  game.step(5);
  fa.call("fs.write", { path: "build/menu_layout.json", content: JSON.stringify(fa.call("ui.state"), null, 2) });
});
```

**Commands from a test.** `fa.call(name, args)` runs any command and returns its result. Scripts have no `ui.state()`
function (`ui` has `rectOf`, `widgetAt`, `focus`...): the list of widgets is the command, `fa.call("ui.state")`, and the
localization state is `fa.call("i18n.state")`.

```js
test("every widget fits and the Spanish table is complete", () => {
  game.load("scenes/menu.scene.json");
  game.step(5);
  const widgets = fa.call("ui.state").widgets;             // the current frame: ids, rect, focused, visible
  expect(widgets.some((w) => w.id === "play_button")).toBe(true);
  const es = fa.call("i18n.state").languages.find((l) => l.code === "es");
  expect(es.missing).toBe(0);                              // keys the default table has and Spanish lacks
  const report = fa.call("ui.check_layout", { textScales: [1, 2] });  // see below: it reloads the scenes
  expect(report.issues).toEqual([]);
});
```

`ui.check_layout` loads each scene again (in each language and text size) and then loads the running scene once more, so
it does not see the state of the current frame and the game state is lost: call it on a fresh scene, and read
`ui.state` before it, not after.

### Scene props

`scene.load(path, { level: 3 })` starts the scene with props: a plain JSON object (numbers, strings, booleans, arrays, objects;
not functions) that the new scene's scripts read with `game.sceneProps()`, from their first `onStart`. Each call returns a
fresh copy, so changing it changes nothing. `factoria run --props '{"level":3}'` (or a `.json` file) starts the first scene with
props; `game.load(path, props)` and `game.loadJson(scene, props)` do the same in a test.

```js
onStart() { const level = game.sceneProps().level ?? 1; }
```

- A **reload** (`scene.reload()`, the `scene.reload` command, hot reload of the scene you are running) keeps the props.
- A load **without props** (`scene.load(path)`, `game.load(path)`) gives the new scene `{}`: props never leak into the next
  scene by themselves. Pass them again to keep them: `scene.load(path, game.sceneProps())`.
- When several loads are asked in one frame, the last one wins, props included.
- `scene.load` command: `props` is an object argument with the same meaning.

**`scene.load` and `game.load` differ.** `scene.load(path)` called from a test (or from a script) takes effect at the start
of the next frame, as in a game: `scene.current` changes at once but the new scene's scripts start on the next
`game.step()`. `game.load(path)` is immediate: the scene is loaded and its behaviours constructed before it returns. After
`scene.load` step one or two frames before reading the new scene's state.

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

`game.setSlider("music_volume", 0.5)` drags a Slider to a value the way a player does: the value is clamped to `min`..`max` and
snapped to `step`, the slider takes focus and `ui.change` `{ id, value }` is sent (nothing when it already had that value). It
throws for an entity that is no Slider, or is inactive or not interactable. Writing `slider.value = 0.5` from a script is
different: it changes the value and sends NO `ui.change` (the same for a Toggle's `value` and a TextField's `text`), so a test
that wants the game's `ui.on("change", ...)` code to run uses `game.setSlider`. The same thing is the `ui.set_slider` command.

Options-menu tests: `game.typeText("héllo")` types characters (what `input.text` returns for the next step; control
characters are skipped) and `game.gamepad(i).setType("playstation")` plugs the pad in as that family, so
`input.buttonName("jump")` answers "Cross" instead of "A". `rebind`, the cursor and the keyboard request are reset
between tests. `window.*` setters throw in tests (no window): test the logic around them, not the toggle itself.

Phone tests: `game.pressBack()` is the Back button (the next `game.step` runs the `input.onBack` handlers; with none
consuming it the headless run asks to quit), `game.setSafeArea("phone-portrait")` fakes a notch (`"phone-landscape"`,
`"none"`, or `{ top, left, right, bottom }` in design pixels) so `screen.safeArea` and every `safeArea: true` item move,
and `game.vibrations()` lists the seconds `input.vibrate` was asked for. All three are cleared between tests.

Each test FILE starts from fresh module instances (module-level state is
re-created, tools are re-evaluated against them), an empty in-memory `storage`
(the real save file is never read or written) and an empty `session`. Within a
file, state carries over between tests unless you reset it.

Tests run inside the current engine (only one renderer can exist per
process). Between test files the runner reloads the project's start scene,
reseeds the world RNG with the project seed, clears input overrides, timers and
behaviours; `game.load` also reseeds. Before each test input overrides, the gamepads (unplugged),
`input.deadzone` and `ui.scale` (back to the project's value), `ui.textScale` (1), `time.scale` and the audio log are reset. Results are deterministic. Extras: `describe.skip`,
`beforeEach(fn)` / `afterEach(fn)` inside `describe`, matchers `toBeUndefined`,
`toBeNaN`, `toMatch`, `toBeInstanceOf`, `toMatchObject(subset)` (every field of the subset is in the
received object with an equal value, recursively; the object may have more). Failures print expected/received and
`file:line` of the failing `expect`. A `TypeError: ... is not a function` in a test or a script shows the source line
with a caret under the call, because QuickJS does not name the missing function.
A test that runs longer than 60 s (an endless loop, a `while` waiting for something that never happens) is stopped,
and the rest of its file is skipped; a file has no limit of its own, so split a test, not the file.

Timing in a test: `world.emit(name, data)` is queued, and its listeners (`world.on`, `onEvent`) run at the next
`game.step`, so call `game.step(1)` after emitting before you check or await a script that waits for it. The answers
of `platform.*` (the fake store) are ready at once, unless `game.platform.set({ delayFrames })` holds them. Run only some
test files with `factoria test <project> tests/saves.test.js "tests/ui*.test.js"` (MCP `project_test` takes `files`).

## Runtime notes
- `Math.random()` is routed to the deterministic world RNG (`rng.*`); never use
  wall-clock time in simulation.
- Callbacks running longer than 2 s are aborted ("script took too long") and the
  behaviour is disabled until its file is reloaded. A timer, tween or `world.on`
  listener stopped this way ends alone; the scripts after it run. Exceptions are recorded once
  per (file, line, message) with a hint; the behaviour keeps running.
- `world.on(name, fn)` listeners get `(data, source)`; `this.on(name, fn)` is the
  same. All listeners/timers are dropped when a scene loads.
- Unknown input actions, keys, components and fields throw errors with
  "did you mean" suggestions. Component views reject unknown field assignment.
- Hot reload (`reload_module`) re-imports the module and every module that
  imports it, recreates affected behaviours (entity state kept, props re-applied,
  `onStart` runs again, `onDestroy` is NOT called) and reloads tools.
- `scene.load`, `scene.reload` and `project.test` re-import every module whose file changed on disk (by mtime; the modules
  importing it too) and `scene.load`/`scene.reload` clear `script.errors`, so an MCP client sees edited scripts without a
  restart. `script.reload` does the same without touching the world (`force` re-imports everything). They also re-read
  `factoria.json` when it changed: input actions, `fixedHz` and the gamepad deadzone (window size, scale mode and the
  renderer need a restart).
- A tool never replaces a built-in command: a tool whose `project.<name>`
  already exists is rejected with a script error.
- `entity.get("Script").props` (a JSON field) returns a copy; assign to write.
