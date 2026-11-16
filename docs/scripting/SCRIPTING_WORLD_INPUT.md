Part of [SCRIPTING.md](../SCRIPTING.md): `world`, `input`, `window`, device presets and gamepads: the entity API and the first modules.

# Scripting: world input

## Entity

| Member | Description |
|---|---|
| `id`, `name`, `tags`, `active`, `alive` | identity (`id` is the stable scene id) |
| `transform` | `Transform` view: `position`, `rotation`, `scale` (Vec3 views) |
| `position` | shortcut for `transform.position` (assignable: `e.position = vec2(10, 0)`). On an entity with a physics body (2D or 3D) it teleports the body (also when it was asleep: it wakes, with whatever touches it, and falls from the new place), and `isGrounded()` reflects the new place after the next physics step |
| `worldPosition` | world-space position (get/set) |
| `bounds()` | world-space rectangle of the entity's 2D visual, `Rect \| null` (see below) |
| `get(name)` | live view of a component or `null` (`e.get("Sprite").color.a = 0.5`). The same entity and component give the same view object (`e.get("Sprite") === e.get("Sprite")`), so keeping it in a variable costs nothing; it holds no data, every read and write goes to the engine. After `remove(name)` its fields throw "has no Sprite component" until the component is added again, and after the entity is destroyed they throw "entity 'x' was destroyed" |
| `add(name, fields?)` | adds (or returns) a component, applies `fields` |
| `set(name, fields)` | patches fields (adds if missing) |
| `has(name)`, `remove(name)` | |
| `destroy()` | deferred to end of frame (children too); leaves physics at once and is not drawn from then on, not even in the frame it is called in (see below) |
| `parent`, `children`, `setParent(e, keepWorld?, index?)` | hierarchy; `index` puts it at a place among the new parent's other children (0 = first, up to the number of those others = last; omitted = last), also within the same parent. A negative, fractional or too large index, an index without a parent, a cycle, an entity being destroyed this frame (`destroy()` ran) or a parent being destroyed throws. Layout containers follow this order |
| `hasTag(t)`, `addTag(t)`, `removeTag(t)` | tags |
| `behaviour` | the script instance attached to it (or `null`) |
| `send(method, ...args)` | calls `behaviour[method](...args)` if it exists |
| `isGrounded(tolerance?)` | 2D or 3D physics: standing on something (contact normal up) |
| `isTouching(direction, tolerance?)` | solid contact against the body on that side: `isTouching([1, 0])` = wall on the right, `[0, 1]` = ceiling (2D or 3D by body type) |
| `animator` | skeletal animation of a glTF, or keyframed 2D clips (`*.anim.json`), of this entity's `Animator` component: `play(clip, fade?)`, `stop()`, `set(name, value)`, `get`, `trigger`, `clips`, `duration(clip)`, `on(event, fn)`, `state`, `speed`, `time`, and for 2D clips `sample(clip, t)`, `setLayerWeight(layer, w)`, `playLayer(layer, clip, fade?)` (throws without an Animator; see [ANIMATION.md](../ANIMATION.md)) |
| `tilemap` | this entity's `Tilemap`: `getTile(col, row)` (-1 = empty or outside), `setTile(col, row, id)`, `paintTerrain(terrain, cells)`, `eraseTerrain(terrain, cells)`, `retile()`, `terrainAt(col, row)`, `cellAt(point)`, `cellToWorld(col, row)`, `width`, `height` (throws without a Tilemap; see "entity.tilemap") |
| `emitBurst(n)` | spawn `n` particles from this entity's `ParticleEmitter` (works with `emitting` off and in a run without graphics: the particles are born in the next simulation step) |
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
- **Tilemap.** The size of the map as it is drawn and collides (`width` x `height`, as the renderer reads it;
  the same helper) times `tileSize`. The entity position is the map's TOP-left corner, so the map spans
  `x .. x + w` and `y - h .. y` at scale 1. An empty map has no bounds (`null`). An isometric map is the box around all
  its diamonds and the images drawn on them.
- **Sprite, Shape2D.** The drawn box from `size` and `pivot`. A sprite without `size` uses its `region`, else the
  texture's pixel size (32 x 32 for a plain colour quad or a missing texture). A circle is its bounding square
  (diameter `size.x`), a line is the stroked segment from the origin to `size`, and the outline `thickness` of the other
  shapes is ignored.
- **Text.** The laid-out text box (`pivot` and `maxWidth` as drawn). The size is the same with and without
  graphics, as for `ui.measureText`.
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
components` (also the `docs.components` command). Vector/color fields are live views
(`v.x = 1` writes into the engine); enums are lowercase strings
(`body.type = "kinematic"`); asset fields are path strings; JSON fields
(`Tilemap.tiles`, `Script.props`) are plain objects — assign a new value to
write.

A bent or waving sprite is one `Sprite` with `meshColumns` / `meshRows` and a script that writes the whole `vertexOffsets`
array each frame (`sprite.vertexOffsets = offsets`, a plain array or a `Float32Array`; reading it gives a `Float32Array`; `sprite.vertexOffsets[3] = 2` does not write back, because the property
returns a copy). `Shape2D.gradientStops` is written the same way (`shape.gradientStops = [[0, "#ff0000"], [1, [0, 0, 1, 1]]]`).
`Tint.color` is a live colour view: `menu.get("Tint").color.a = progress` fades the menu's whole subtree. See the "Tint, gradient
stops, skew and bent sprites" recipe in `docs_read {"name":"ai-guide","heading":"9.26"}`. A script that awaits something before writing to
such a component (a `texture.load`, a tween) checks that its entity is still alive and the scene the same first.

Vectors, colours and rects are also array-like, live views included: `padding[1]`, `size[0]`, `[...color]`,
`const [l, t, r, b] = panel.padding`, `for (const c of color)` and `Array.from(color)` give the components in the order
of the named parts (`x y z w`, `r g b a`, `x y w h`) and the named parts keep working. `Array.isArray` is still false
(they are not arrays: no `map` or `forEach`; use `Array.from(v).map(...)`). `length` is the number of components for
colours and rects; vectors keep `length()` (the magnitude), so use `[...v].length` there. `game.screenSize` and
`screen.size` are cheap to read (no copy of the project settings), but still one native call: keep the value in a local
when a loop needs it many times.

### world
- `find(idOrName)` → Entity | null · `findAll(name)` · `findByTag(tag)` · `entities()`
- `spawn(entityJson, { position, rotation, scale, parent, index, props })` → Entity (same format as scene files; `{ name, tags, components: {...} }`)
- `spawnPrefab(path, { position, rotation, scale, parent, index, props, overrides, childOverrides })` → Entity.
  `props` is merged into the entity's `Script.props` (on top of the prefab's own); `overrides` is entity JSON
  merged over the prefab (`{ components: { Sprite: { color: ... } } }`). `childOverrides` changes the prefab's
  descendants: `{ Title: { components: { Text: { text: "You won" } } } }`; a key is a child's id, name or a path such
  as `"Panel/Title"`, a value holds `name`, `tags`, `active` and `components`. A child or field that does not exist
  throws with a "did you mean" (docs/MENUS.md, "A panel shared between scenes").
  A `parent` that is being destroyed (`destroy()` ran this frame) makes both throw before they create anything: the
  new entity would outlive its parent at the top level. Spawn it without that parent, or after the frame.
- Destroyed entities (`entity.destroy()`, deferred to frame end) stop being returned by `find`/`findAll`/`findByTag`
  immediately and their id can be reused right away (`world.spawn({ id: "gem_1" })` right after destroying `gem_1`).
  They also leave physics immediately: from the call on, a destroyed entity has no collisions, no contact events and no
  `raycast`/`shape_cast`/overlap hits, even though it is only erased at the end of the frame. So it is safe to destroy a
  stack of rigid bodies and spawn a replacement at the same positions in the same frame: the old bodies do not push the new ones.
  `world.entities()` skips them too; a handle you hold stays `alive` until the end of the frame. So a screen can destroy
  its root and spawn the rebuilt one with the same ids in the same frame, and `world.find` returns the new widgets.
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
- Consumed presses and text input. `input.consume(action)` says this frame's press of the action is handled: until the next
  frame `input.pressed` reads false for it and for every other action that shares a binding that went down (Escape is
  `pause` and `ui_cancel`; `down` and `value` keep reading the held input). The UI runs before scripts and consumes
  `ui_submit` when it clicks a focused Button or Toggle, and `ui_cancel` when a drag took it or when a
  `ui.on("cancel", fn)` handler returns `true`, so `ui.on("cancel", () => { if (!dialog.open) return false; dialog.close();
  return true; })` closes a dialog on Escape without the pause handler of the same frame opening the pause menu.
  `input.textInputMode` is true while a TextField has the focus (or a script set it, for its own text entry such as the
  menu kit's on-screen keyboard; a scene load clears the script's flag): actions bound to printable keys (letters, digits,
  Space, punctuation, alone or with Shift) then read as not down, pressed or released for those bindings, so typing P in a
  save-name field does not pause. Enter, Escape, arrows, F keys and Ctrl/Alt/Super chords stay actions.
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
  does not. Real pads are read in windowed runs only (Windows XInput and Raw Input/HID, Linux joystick API, macOS/iOS GameController,
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
  supported and is skipped. On Windows, Xbox pads (XInput) and the other pads (Raw Input and HID: DualShock 4, DualSense
  and Switch Pro have their full reports read by the engine's own drivers, the DualShock 4's and DualSense's analog
  triggers included, while the Switch Pro's ZL and ZR are buttons, so their trigger axes read 0 or 1; generic pads go
  through the Windows lines of SDL GameControllerDB) share the slots 0..3: a pad keeps its slot while connected, and a pad
  that appears takes the slot it had last time when that is free, else the lowest free one (an Xbox pad no longer takes its
  XInput user index). A pad Windows does not describe yet when it arrives is tried again every 250 ms for 1.5 s, then
  every 2 s; an Xbox pad is looked for the same way after Windows announces a device, and every 2 s otherwise. A remapper that shows a PlayStation or Switch pad to games as a virtual Xbox pad (DS4Windows, Steam
  Input outside Steam's own games) makes the engine see two pads, the virtual XInput one and the physical HID one, each in
  its slot: turn the remapper off for the game, or have it hide the physical pad (DS4Windows' "Hide DS4 Controller", which
  uses HidHide), so one pad is one slot. On macOS and iOS (GameController) a pad keeps its slot while connected and an
  unplugged pad frees it. On Android an unplugged pad frees its slot (checked about every 2 s through the Java
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

### Pad rumble: `input.rumble(pad, low, high, seconds)`
`input.rumble(0, 0.7, 0.3, 0.2)` shakes the motors of the pad in slot 0 (the slot `input.gamepad(i)` reads): `low` is the heavy,
low-frequency motor (the left one of an Xbox pad), `high` the light, high-frequency one, each 0..1 (a value outside is clamped),
for `seconds` above 0 and up to 10 (0.05 to 0.15 is a tap, 0.3 a hit, 1 an explosion). A new call on the same pad replaces the
one playing; `input.stopRumble(pad)` stops one pad and `input.stopRumble()` all of them (a request with both strengths 0 is a
stop too). A pad that is not connected or cannot rumble ignores the call, so a game need not check;
`input.gamepad(i).canRumble` says whether it will do something, to show a Vibration option only where it works (it is already
right in the frame a pad connects and in its `gamepadConnected` handler). This is a different motor from a phone's
`input.vibrate()`.

- The time runs on the frames' own duration, not on the wall clock of the hardware and not scaled by `time.scale`: the rumble
  ends when `seconds` of frames have passed (a slow-motion hit-stop does not stretch it) and a request made in a scene's
  `onStart` plays. To go on, ask again before it ends.
- The engine stops every pad when the game pauses itself (`game.paused = true` or `time.scale` 0, and the editor's pause), when
  the window loses the focus or the app is suspended, when a pad is unplugged, on a scene change and on quit, so a pad never
  keeps shaking. A request made in the same frame that pauses the game is stopped before it reaches the pad (no buzz of one
  frame); one made while the game stays paused (a click in a pause menu) plays, and ends with its `seconds`. On Windows the
  process also stops the motors as it exits, after the engine: the XInput motors that were set, and every PlayStation or
  Switch pad still playing (with at most about 100 ms of waiting for all of them). After an unhandled exception (an access
  violation...) the XInput motors are zeroed too (the crash report goes on as before). After that exception a PlayStation
  pad keeps shaking, while a Switch Pro stops by itself about 50 ms later (its rumble needs the report repeated). What does
  not go through that path leaves every motor on until the pad is switched off or another program sets it: `abort()` (an
  assert, `std::terminate`), a bad CRT call, a hang, a debugger that stops the game and a killed process.
- The editor's Game view reads no physical gamepad, so no pad connects there and nothing rumbles: try rumble in a game run on its
  own (`factoria run`, an export), or test it with `game.rumbles()` below.
- Mistakes throw with a hint: a pad outside 0..3 (`input.stopRumble(-1)` too), a strength or `seconds` that is not a number,
  `seconds` outside 0..10.
- Where it works today, and how:

  | Platform | Pads | How | Needs |
  |---|---|---|---|
  | Windows | XInput pads (Xbox 360, One, Series and pads that present themselves as one) | XInput motors | nothing |
  | Windows | DualShock 4, DualSense (and Edge), Switch Pro, over USB or Bluetooth | the pad's own output report, sent through its HID device: the two motors of a DualShock 4, the DualSense's compatible vibration, and on the Switch Pro HD rumble at fixed frequencies (`low` on the 160 Hz band, `high` on the 320 Hz band, both grips alike) | no other program holding the pad exclusively (DS4Windows or HidHide in exclusive mode) |
  | Linux | pads whose kernel driver offers force feedback (`FF_RUMBLE`: Xbox, DualShock 4, DualSense, Switch Pro with the usual drivers) | evdev: one rumble effect per pad on `/dev/input/eventN` | write access to that node |
  | macOS, iOS | pads GameController gives haptics (Xbox One/Series, DualShock 4, DualSense) | CoreHaptics: `low` on the left handle, `high` on the right, one engine plays the stronger when the pad has no handles | macOS 11, iOS 14 |
  | Android | pads whose `InputDevice` has vibrators | API 31+: `getVibratorManager()` (one vibrator plays the stronger of `low` and `high`, two play `low` on the first and `high` on the second); API 26 to 30: `getVibrator()` | nothing beyond the `VIBRATE` permission the player already has |
  | Chrome-based browsers | Xbox and PlayStation pads | `gamepad.vibrationActuator` | a button pressed on the pad or a click on the page first (until then `canRumble` is `false` with that reason, and a rumble still running starts once it is `true`) |

  Everything else answers `canRumble: false` with the reason: other Windows pads (generic HID pads: "this pad gives no rumble the
  engine can drive"), a Windows pad another program holds exclusively or that stopped taking reports (the reason says which;
  plug it in again), and Firefox and Safari, which have no browser API. On Linux the reason names what to do when `/dev/input/eventN`
  cannot be opened for writing: add the user to the `input` group (`sudo usermod -aG input $USER`, log in again) or add a udev
  rule such as `KERNEL=="event*", SUBSYSTEM=="input", TAG+="uaccess"`; a refused open is tried again every few seconds (udev may
  set the permissions a moment after the pad appears), and a change of the rules reaches a pad that is already plugged in
  after `udevadm trigger` or a replug. Strengths are not the same motor on every pad: the 0..1 maps to the motor's whole range, and Android
  amplitudes are 1..255 (a tiny strength still runs the motor). A phone or tablet pad may expose no vibrator to Android at all,
  most often over Bluetooth, and then `canRumble` is `false`. On Windows a report the pad does not take is sent again a few
  times, 100 ms apart, before the pad answers `canRumble: false`; a pad that is gone answers it at once. What the Windows
  drivers change on the pad: a Switch Pro is put on its full report and, when the game exits, asked for its simple one again (not yet tried on a real pad; over USB the pad may not
  answer it); a
  DualShock 4 or DualSense over Bluetooth stays on its full report until it is switched off or connected again, so an old
  DirectInput program started meanwhile may not read it (over USB these pads always send their full report).
- Tests and headless runs: a test pad has no motors unless `game.gamepad(i).connect({ canRumble: true })`. `game.rumbles()` lists
  the requests the game made (strengths already clamped, `seconds` 0 for a stop, at most 256) and `game.rumbleState(pad)` says
  what the motors do now (the seconds left run down with `game.step`). A test pad that disconnects forgets `canRumble`: say it
  again at every `connect()`.
- For a tool or an AI: the command `game.rumble` (`{pad, low, high, seconds}` or `{pad, stop: true}`; without a pad, all pads;
  `seconds` without `low` or `high` is refused) does the same on a running game and answers with every pad's `canRumble` and the reason when it is false.
```js
import { Behaviour, input } from "factoria";
export default class Hurt extends Behaviour {
  onHit(damage) {
    input.rumble(0, Math.min(1, damage / 50), 0.4, 0.25);   // a stronger hit shakes the heavy motor more
  }
}
```

### game.device: pick a quality preset
`game.device` is `{ formFactor: "desktop" | "phone" | "tablet", gpuBackend, memoryGB, tier: "low" | "medium" | "high", steamDeck, handheld }`.
`gpuBackend` is `"metal"`, `"d3d11"`, `"glcore"`, or `"gles3"`; `memoryGB` is the machine's physical
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
pad in XInput slot N" (it ends with `#xinputN`), while the other Windows pads (HID) give the vendor and product, the name
and the serial number when the pad has one (a Bluetooth pad's address); Linux adds the kernel serial when the pad has one; macOS, iOS and the web give
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
