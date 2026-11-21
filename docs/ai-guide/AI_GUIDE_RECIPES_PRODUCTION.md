# AI guide: recipes for production

Part of [AI guide](../AI_GUIDE.md): recipes 9.26 to 9.32: 2D production, enemy AI, multiplayer, split screen, render targets, game feel, choices.

### 9.26 2D production: flipped tiles, 9-slice, lights, parallax, joints

- **Flipped and rotated tiles.** A tile value in `Tilemap.tiles` is the index plus flag bits: `+268435456` flip X, `+536870912` flip Y, `+1073741824` transpose (applied first, then X, then Y). Turn 90 degrees clockwise = `1342177280 + i`, 180 = `805306368 + i`, 90 counter-clockwise = `1610612736 + i`. `solidTiles`, the tileset range check and collision use the plain index only. In `scene.import_ascii` a legend object takes `{"tile": 3, "flipX": true, "flipY": false, "rotate": 90}` (rotate is clockwise: 0, 90, 180, 270) so you never write the numbers.
- **9-slice sprites.** `Sprite.slice` = `[left, top, right, bottom]` in pixels of the picture (of the `region` when set). The corners keep their size, the edges and centre stretch to `size`. Works with `flipX/flipY`, `region` and atlas textures. A size smaller than the corners shrinks them evenly.
- **Lights.** Add `Light2D` entities (`type` point or directional, `color`, `intensity`, `radius`, `falloff`, `height` for point lights, `direction` and `elevation` for directional ones). Only a `Sprite`, `Tilemap` or `Shape2D` (world space) with `lit: true` is lit (a lit shape is flat: no normal map, outlines and lines included); the base brightness is `SceneSettings.ambientLight`. `Sprite.normalMap` (needs `lit`) gives bumps; the normal map may be another size or packed in an atlas. Point lights are added up in a light buffer, so a frame keeps up to 256 lights: directional lights first, then the point lights whose radius reaches the camera view (the ones with more of their radius in view first, then the brighter ones; an off-view light is never kept over one in view). More than 256 in view logs one warning per scene; `game.renderStats().lights2d` and `lights2dDropped` show what was kept and left out, and `perf.measure`'s `lights` (so `maxLights`) counts 2D and 3D lights together. A lit sprite or tile WITH a normal map is still shaded per pixel by the first 16 lights of that order (the light's direction matters there). Lights ignore layers. Unlit sprites cost nothing extra, and a scene without Light2D pays nothing. Shadows: see the recipe below.
- **Lights and shadows from tiles.** A dungeon or cave: `Tilemap.occludesLight = true` makes the tiles of `solidTiles` (the ones that already collide) block light, and `Light2D.castShadows = true` on a point light makes it cast: the far side of a wall stays dark, the wall's own face stays lit, and editing a tile at run time (`tilemap.setTile`, the command `tilemap.set_tile`) moves the shadows on the next frame. Both default to false. Every point light with `castShadows` that reaches a wall gets a shadow, up to the 256 lights a frame shades (`renderStats().lights2dShadowed` counts them): give `castShadows` to the torch the player carries and the few that matter, not to every candle, because each one costs a row of rays on the CPU when it or the walls near it move. A light that does not move does not recompute its shadow rays (only its pixels cost, frame after frame). `SceneSettings.lightScale` (0.25 to 1, default 1) is the size of the light buffer as a fraction of the picture: use 0.5 on phones and the web with many lights. Costs: PERFORMANCE.md, "2D lights".
  ```js
  // a wall of solid tiles that blocks light, a torch that casts shadows
  const map = world.find("walls");
  map.get("Tilemap").occludesLight = true;          // solidTiles already says which tiles are walls
  world.spawn({ name: "Torch", components: {
    Transform: { position: [120, 80, 0] },
    Light2D: { radius: 260, intensity: 1.2, castShadows: true } } });
  map.tilemap.setTile(5, 3, -1);                      // a wall opens: the light flows through next frame
  ```
- **Shadows from sprites, props and characters; soft shadows.** `ShadowCaster2D` on an entity makes it block the light of every `Light2D` with `castShadows`, like a solid tile does: `shape` `"spriteAlpha"` (default, the contour of the entity's own `Sprite` above `alphaThreshold`), `"polygon"` (`points: [x0, y0, x1, y1, ...]`, local space) or `"box"` (`size`). Use `box` or `polygon` for anything simple (a crate, a pillar) and `spriteAlpha` for a tree or a character: the contour is made once per texture and region, but a texture packed into an atlas by an export or a missing file falls back to the sprite's rectangle with one warning. `selfShadow: false` (default) keeps the caster lit like the face of a tile; a lamp inside the outline is not blocked. `lightLayers` (bit mask, default -1) chooses which lights it blocks, and a `Tilemap` with `occludesLight` blocks only the lights whose `lightLayers` share a bit with the tilemap's (default 1 against -1: all of them). `Light2D.size` (world units, default 0) gives the shadows a penumbra that widens with the distance past the occluder (about `2 x size x (d - b) / b` wide; a candle 2 to 4, a street lamp 8 to 20): it costs the light's pixels up to 44 row reads instead of 2, so set it on the lights the player looks at. A scene with no `ShadowCaster2D` and `size` 0 pays nothing new. A frame reads at most 2048 casters and a light's row at most 512 (merge static props into one `polygon`); docs/rendering/RENDERING_2D_SHADOWS.md has the costs.
  ```js
  // a crate that blocks light, a torch with a soft shadow
  world.spawn({ name: "Crate", components: { Transform: { position: [60, 0, 0] },
    Sprite: { texture: "assets/crate.png", lit: true },
    ShadowCaster2D: { shape: "box", size: [32, 32] } } });
  world.spawn({ name: "Torch", components: { Transform: { position: [0, 0, 0] },
    Light2D: { radius: 240, castShadows: true, size: 6 } } });
  ```
- **Rounded corners, soft shadows, gradients and vignettes (one Shape2D each, no stacking).** `cornerRadius` rounds a `rectangle` (clamped to half the short side: a big value makes a pill). `softness` is the width in world units of a blurred edge, centred on the outline (the shape grows by `softness / 2` on every side), for a `rectangle` or `circle`. `gradient` (`"linear"` or `"radial"`) blends `color` into `color2` per pixel, dithered, so there is no banding: linear along `gradientAngle` degrees (0 = left to right, 90 = bottom to top, box corner to corner), radial from the centre to the edge of the box; both colours' alpha counts, so `color2: [0, 0, 0, 0]` fades out. All default to off and cost nothing then; triangles, diamonds, polygons, stars and lines ignore them, and an outline (`filled: false`) takes `cornerRadius` and `softness` but no gradient. Lit shapes (`lit: true`) and `blend` work with them.
  ```js
  // paper page with a soft drop shadow, a gutter shading and a vignette over the whole desk (layers: shadow 1, page 2, gutter 3, vignette 90)
  world.spawn({ name: "PageShadow", components: { Transform: { position: [6, -8, 0] },
    Shape2D: { size: [300, 200], cornerRadius: 10, softness: 24, color: [0, 0, 0, 0.45], layer: 1 } } });
  world.spawn({ name: "Page", components: { Transform: { position: [0, 0, 0] },
    Shape2D: { size: [300, 200], cornerRadius: 8, color: [1, 0.97, 0.88, 1], layer: 2 } } });
  world.spawn({ name: "Gutter", components: { Transform: { position: [140, 0, 0] },   // darkens towards the spine on the right
    Shape2D: { size: [24, 200], gradient: "linear", color: [0.4, 0.3, 0.2, 0], color2: [0.4, 0.3, 0.2, 0.5], layer: 3 } } });
  world.spawn({ name: "Vignette", components: { Transform: { position: [0, 0, 0] },    // clear in the middle (a transparent `color` is fine: only a shape whose colours are all transparent is skipped), dark at the edge of the box
    Shape2D: { size: [1600, 900], gradient: "radial", color: [0, 0, 0, 0], color2: [0, 0, 0, 0.6], layer: 90 } } });
  // a light pool: a circle, white at the centre fading to nothing, additive
  // Shape2D: { shape: "circle", size: [240, 240], gradient: "radial", color: [1, 0.8, 0.4, 0.8], color2: [1, 0.8, 0.4, 0], blend: "additive" }
  ```
- **Tint, gradient stops, skew and bent sprites.**
  - `gradientStops` (a Shape2D with `gradient`, rectangle or circle) lists up to 8 `[position 0..1, colour]` pairs and replaces the
    `color` -> `color2` blend; `gradientEase` (`"smoothstep"`, `"quadOut"`, `"cubicInOut"`, ... the names of the tween easings in
    `docs_read {"name":"animation"}`) bends the position first. Stops are sorted by position; two at the same position make a hard
    edge; colours blend premultiplied, so fading to a transparent colour does not grey. Up to 256 different gradients are on screen
    at once (more draw as the first and last stop blended linearly). A malformed stop is skipped with a warning.
  - `Tint` multiplies its colour and opacity into the entity and everything under it (Sprite, Shape2D, Text with rich colours, Tilemap,
    ParticleEmitter, screen-space UI widgets; not 3D meshes, lights or debug draw). A nested `Tint` multiplies with its parent's.
    Do not use it as a replacement for `Sprite.color` on one sprite; it is for a group.
  - `Sprite.skew = [20, 0]` leans the top edge right (degrees, about the pivot, clamped to +-80). `meshColumns` / `meshRows` make a
    sprite a grid of cells (at most 128 per side, 4096 cells) and `vertexOffsets` moves its vertices: a flat `[dx0, dy0, dx1, dy1, ...]`,
    top row first, +y up, `(meshColumns + 1) * (meshRows + 1)` pairs. The texture stretches with the vertices; still one entity and one
    draw call; `slice` is ignored. A script writes the whole array each frame (a changed element of the array it read does not write back). `vertexOffsets`, `vertexColors` and `SpriteSkin.bindPose` are float arrays: on disk a flat JSON array of numbers, an element that is not a number is a load error naming its index.
    `vertexColors` is a flat `[r, g, b, a, ...]` with one RGBA per grid vertex in the same order (exactly `(meshColumns + 1) * (meshRows + 1) * 4`
    numbers, else a scene load error / one warning), multiplied with `color`: light and dark along a bent page without an overlay sprite.
  ```js
  // a flag: 8 columns x 4 rows waving (a script's onUpdate; `time.elapsed` counts fixed steps in seconds)
  world.spawn({ name: "Flag", components: { Transform: { position: [0, 0, 0] },
    Sprite: { texture: "assets/flag.png", size: [96, 64], meshColumns: 8, meshRows: 4 } } });
  // each frame:
  const flag = world.find("Flag").get("Sprite"), offsets = [];
  for (let r = 0; r <= 4; ++r) for (let c = 0; c <= 8; ++c) offsets.push(0, Math.sin(time.elapsed * 4 + c * 0.7) * 2 * (c / 8));
  flag.vertexOffsets = offsets;
  // fade a whole menu in: world.find("Menu").get("Tint").color.a = progress;   // Tint on the menu's root entity
  // a shadow without a visible edge: Shape2D { gradient: "linear", gradientAngle: 90, gradientEase: "quadOut", color: [0,0,0,0.5], color2: [0,0,0,0] }
  ```
- **Parallax.** `Parallax.factor` 1 follows the world, 0 sticks to the screen, 0.5 moves at half the camera's speed (use a value above 1 for a foreground). `repeatX` / `repeatY` with `repeatSize` tile a Sprite endlessly over the view. It works with the camera follow of 9.6: the offset is computed from the camera position each frame, so `entity.bounds()` and the editor pick follow it and replays stay deterministic.
- **Joints.** `Joint2D` goes on the body entity. `connected` is another entity with a body, or empty to pin to the world (then `connectedAnchor` is a world position). `anchor` is on this entity, `connectedAnchor` on the other, in local pixels. Types: `revolute` (hinge; `enableLimit` with `lowerLimit`/`upperLimit` in degrees, 0 = the pose at creation), `distance` (a rope of `length`, 0 = the starting distance; `enableSpring` with `springHertz`/`dampingRatio` makes it elastic), `prismatic` (slides along `axis`, limits in pixels), `weld` (glue). `enableMotor` with `motorSpeed` (degrees/s or px/s) and `maxMotorTorque`. Limits, motor and spring change live from scripts; the type, anchors, axis and `connected` rebuild the joint. `reactionForce`, `reactionTorque`, `angle` and `translation` are read-only runtime fields.

```js
const j = this.entity.get("Joint2D");
j.enableMotor = true; j.motorSpeed = 180;        // a wheel starts spinning
if (Math.hypot(j.reactionForce.x, j.reactionForce.y) > 5000) this.world.destroy(this.entity); // a rope that takes too much
```

### 9.27 Enemies that think and find their way: `bt` plus `nav.findTilePath`

A behaviour tree (`bt`, SCRIPTING.md "AI: behaviour trees") picks WHAT the enemy does; `nav.findTilePath` (NAVIGATION.md,
section 7) says WHERE to step on a tile map. Search again only when the goal's cell changed or the map did
(`nav.tileVersion(map)`, which also counts a whole `tiles` replacement), not every frame. Many enemies heading for the same
place (a crowd chasing the player, walkers going to a building) share one `nav.flowField(grid, goals)` over a grid from
`nav.createGrid`: `field.stepToward(col, row)` is the next cell in O(1), and `grid.setCost` keeps the grid current. `bt.parallel` runs
several children at once (move and shoot) and `bt.repeat(child, times?)` repeats one (SCRIPTING.md).

```js
import { Behaviour, bt, nav, world } from "factoria";
const { RUNNING, FAILURE, selector, sequence, condition, action } = bt;

export default class Enemy extends Behaviour {
  speed = 40;                                   // world units per second
  onStart() {
    this.map = world.find("ground");            // a Tilemap whose solidTiles are the walls
    this.player = world.find("player");
    this.path = []; this.goalKey = ""; this.version = -1;
    this.tree = new bt.Tree(selector(
      sequence(condition((e) => e.distanceTo(e.player) < 200), action((e, dt) => e.chase(dt))),   // sees the player
      action(() => RUNNING),                                                                      // otherwise idle
    ), this);                                   // the blackboard is this behaviour
  }
  onUpdate(dt) { this.tree.tick(dt); }
  distanceTo(other) { return other.position.sub(this.entity.position).length(); }
  cellOf(p) {                                   // world position -> { col, row } (the map's top-left corner is its position)
    const o = this.map.position, t = this.map.get("Tilemap").tileSize;
    return { col: Math.floor((p.x - o.x) / t.x), row: Math.floor((o.y - p.y) / t.y) };
  }
  chase(dt) {
    const goal = this.cellOf(this.player.position), key = `${goal.col},${goal.row}`;
    if (key !== this.goalKey || this.version !== nav.tileVersion(this.map)) {
      const r = nav.findTilePath(this.map, this.cellOf(this.entity.position), goal, { diagonals: true, closest: true });
      this.path = r.found ? r.points.slice(1) : [];                 // points[0] is the cell we stand on
      this.goalKey = key; this.version = nav.tileVersion(this.map);
    }
    if (this.path.length === 0) return FAILURE;
    const to = this.path[0], p = this.entity.position, dx = to.x - p.x, dy = to.y - p.y, d = Math.hypot(dx, dy);
    if (d < 1) { this.path.shift(); return RUNNING; }
    const step = Math.min(d, this.speed * dt);
    this.entity.position = [p.x + dx / d * step, p.y + dy / d * step, p.z];
    return RUNNING;
  }
}
```


Digging or building (`entity.tilemap.setTile`) bumps the version, so the next `chase` finds the new way. A game whose real
map is not a Tilemap passes its own `{width, height, cost}` grid instead of `this.map`.

### 9.28 Local multiplayer: one player per pad or key block

Two to four people on one machine, each with their own controls and the same action names. Do not read `input.gamepad(i)` button by button and do not write a second set of key tables: declare the actions once in `factoria.json`, give each player a device, and read `input.player(i)`.

```json
"input": {
  "actions": { "move_left": ["A", "Left", "GamepadDpadLeft", "GamepadLeftStickLeft"], "move_right": ["D", "Right", "GamepadDpadRight", "GamepadLeftStickRight"], "jump": ["Space", "Up", "GamepadA"] },
  "schemes": { "arrows": { "extends": "right", "actions": { "jump": ["Enter"] } } }
}
```

- **Devices.** `input.player(i).use({ pad: 0 })` (a gamepad slot), `use({ padId: input.gamepad(0).id })` (follow that physical pad if it returns in another slot) and `use({ keys: "left" })` (a key scheme). A player may have a pad and a key scheme; with neither (`use()`) it reads nothing. The schemes are `"all"`, `"left"` (the WASD half of the keyboard), `"right"` (the arrows half) and the ones in `factoria.json` `input.schemes` (`extends` a built-in one, `keys` to add keys, `actions` to give a scheme its own keys for some actions); `input.keySchemes()` lists them. A bad slot or scheme throws and says what exists. Assign the devices every time your scene starts: a test starts with none.
- **Reading.** `down`, `pressed`, `released`, `value`, `axis(neg, pos)` and `vector(left, right, down, up)` have the names of the global `input`, and answer only for that player's device: pad bindings of an action read that pad alone, key bindings count only keys of the player's scheme (`"left"`: `A` and `D` yes, `Left` no), and the mouse and touch belong to nobody. The global `input.down("jump")` still hears every device, which is right for menus.
- **Bindings per player.** Defaults are the project's bindings filtered to the device. `input.player(i).rebind("jump", ["Q"])` changes this player only (all names keys, or all pad buttons; pass `"keys"` or `"pad"` as the third argument to say which list, also when the player has no such device yet). `bindings(action, family)`, `reset(action?)` and `lastPressed()` are per player too. Save with `storage.set("p" + i, input.player(i).export())` and restore with `input.player(i).import(saved)`, which returns what it had to skip.
- **Tests.** `game.keyDown("A")` and `game.gamepad(1).press("A")` drive them; assert that each player's action moves only their character.

```js
import { Behaviour, input } from "factoria";

export default class Runner extends Behaviour {
  index = 0;       // the player: set per instance in the scene with Script.props
  speed = 300;
  jumpSpeed = 620;

  onStart() {
    this.me = input.player(this.index);
    this.body = this.entity.get("RigidBody2D");
    // players 0 and 1 on pads 0 and 1, player 2 on the left half of the keyboard, player 3 on the "arrows" scheme of factoria.json (jump is Enter there)
    this.me.use(this.index < 2 ? { pad: this.index } : { keys: this.index === 2 ? "left" : "arrows" });
  }

  onUpdate() {
    this.body.velocity.x = this.me.axis("move_left", "move_right") * this.speed;
    if (this.me.pressed("jump") && this.entity.isGrounded()) this.body.velocity.y = this.jumpSpeed;
  }
}
```

### 9.29 Split screen: two or four players, one camera each

Every active `Camera` with `primary: true` draws into its own `viewport` (`[x, y, width, height]`, each 0..1, `[0, 0]` is the
TOP-LEFT of the screen, +Y down), in ascending `depth`. A split screen is two or more cameras whose viewports share the screen;
each one culls, sorts and lights its own view (a `Light2D` only lights the cameras it reaches, a 3D camera has its own 3D
lights), and each clears its own rectangle. The UI and every `space: "screen"` item is drawn once over the WHOLE screen after
the cameras, so a shared HUD stays in the middle or the corners of the screen, not in each view. Bloom and `colorFilter` are
applied once to the finished frame with the settings of the lowest-`depth` camera (the other cameras' values are ignored). At
most 8 cameras are drawn (the ones with the lowest `depth`; one warning names the rest).

```json
{ "id": "cam1", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Camera": { "projection": "orthographic", "orthoSize": 200, "primary": true, "depth": 0, "viewport": [0, 0, 0.5, 1], "clearColor": [0.05, 0.05, 0.08, 1] },
    "Script": { "path": "scripts/follow_target.js", "props": { "target": "p1" } } } },
{ "id": "cam2", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Camera": { "projection": "orthographic", "orthoSize": 200, "primary": true, "depth": 1, "viewport": [0.5, 0, 0.5, 1], "clearColor": [0.05, 0.05, 0.08, 1] },
    "Script": { "path": "scripts/follow_target.js", "props": { "target": "p2" } } } }
```

Two players side by side: viewports `[0, 0, 0.5, 1]` and `[0.5, 0, 0.5, 1]`. Four players: `[0, 0, 0.5, 0.5]`, `[0.5, 0, 0.5, 0.5]`,
`[0, 0.5, 0.5, 0.5]` and `[0.5, 0.5, 0.5, 0.5]`. An inset (a minimap) is a second camera on top (a higher `depth`) with a small
viewport such as `[0.72, 0.04, 0.24, 0.24]` and `clear: true`. Give the cameras the SAME `orthoSize` so every player has the same
zoom: the visible HEIGHT is `2 * orthoSize` in every viewport and the visible width follows the rectangle (a half-width view
sees half the width). With `orthoSize: 0` the camera keeps one world unit per design pixel, so a half-width view sees half the
world. A `viewport` outside 0..1 or without size makes the scene fail to load with the entity and the field in the message.

The fractions count the GAME TARGET: the design resolution, grown on the long axis by `display.scaleMode: "expand"` (the letterbox
bars of `fit` are not part of it). With `viewportSpace: "design"` they count the design area from its top-left corner
instead, so a minimap placed with `[0.72, 0.04, 0.24, 0.24]` keeps the same design pixels when Expand makes the window wider
(the camera is kept inside the target). `Camera.viewport` is ignored by a camera a `CameraView` shows: the view's own rectangle
decides ([MENUS.md](../MENUS.md), "A camera inside the UI").

```js
// scripts/follow_target.js (one per camera; `target` is the id of the player it follows)
import { Behaviour, world } from "factoria";
export default class FollowTarget extends Behaviour {
  target = "";
  catchUp = 8;
  onLateUpdate(dt) {
    const t = world.find(this.target);
    if (!t) return;
    const k = Math.min(1, this.catchUp * dt), p = this.entity.position;
    p.x += (t.position.x - p.x) * k;
    p.y += (t.position.y - p.y) * k;
  }
}
```

Per-player input: each player's script reads `input.player(i)` (section 9.28) with its own pad or key scheme, so the
camera scripts only follow the players and the controls stay the same with one screen or four.

Screen points and cameras: `camera.all` lists the cameras drawn (draw order), `camera.at(point)` is the one whose viewport
contains a screen point (the one drawn last, on top, when viewports overlap; a point outside every viewport gives the first camera), and `camera.screenToWorld(point)`,
`camera.screenRay(point)`, `input.mouse.world` and the `world` of a touch use that camera by default, so a click picks what
the player under the pointer sees. Name the camera to convert for another one: `camera.worldToScreen(p, cam2)` (inside `cam2`'s
viewport when `p` is in its view) and `camera.screenToWorld(point, 0, cam2)`. `camera.main` is the first camera drawn (player
one's). Tools that read "the camera" (screenshots, `game.screenshot`, the editor viewport, `perf.measure`) see the whole frame.
`game.renderStats()`: `drawCalls`, `triangles`, `lights` and the rest are per FRAME, added up over every camera, so a four-camera
frame costs about four times a one-camera frame in `drawCalls` (docs/PERFORMANCE.md). Screen-space visuals with `lit: true` get
only the scene's ambient light (no `Light2D`) in a split-screen frame. Keep it to two or three cameras on phones.

### 9.30 A camera in a texture: a screen on a model, a mirror, a book with working pages

Full guide: `docs_read {"name":"rendering"}` ([RENDERING.md](../RENDERING.md)). The short version:

1. Make the page out of ordinary WORLD-space entities (`Sprite`, `Text`, `Shape2D`, children of one `Transform`); the screen-space
   UI (`Panel`, `Button`, `space: "screen"`) is not drawn into a target. Tag the page's root (`"tags": ["page"]`) and give the
   target camera `showTags: ["page"]` and the camera that draws the model `hideTags: ["page"]` (a culling mask: an entity is drawn
   when it or an ancestor has a showTags tag and no hideTags tag), or put the page where the main camera never looks (x = 5000).
   Give the buttons, toggles and sliders of the page an `Interactable`.
2. Add a `Camera` with `renderTarget: "book"` and `renderTargetSize: [512, 768]` over the page (orthographic, `orthoSize` half
   the page height in world units, or 0 for one unit per texture pixel). It never draws to the screen and is never `camera.main`.
3. Show it: `MeshRenderer { mesh: "quad", texture: "target:book", unlit: true }` (or a curved glTF model, or a custom material's
   `materialParams`), `Sprite.texture`, `Panel.texture`, `Button.icon`. The target is drawn before the cameras that show it.
4. The pointer over the mesh reaches the page's Interactables through the mesh's UV (hover, click, toggles, slider drags, even off
   a curved surface). Only meshes with UVs (primitives, glTF); the nearest page mesh wins; Sprite/Panel/Button showing a target
   forward nothing; `game.click {"id"}` of a widget only the page shows is clicked through the mesh (and says why when it cannot be:
   outside the target camera's view, mesh off screen / covered), and `game.click` returns the `widget` it reached and `via: {mesh, target}`.
5. A camera that sees the model showing its own target draws a checker there with one error; two targets that show each other
   are fine (one frame late).

Photographs: `render.captureTexture({ entity | rect, space: "world", scale })` draws a hidden, covered or off-camera part of
the world into a transparent texture of `ceil(size * scale)` pixels (at most 4096 a side), with no frame drawn first. The HUD is
not in it. Details in RENDERING.md, "Off-screen capture".

### 9.31 Game feel: shake, hit-stop, flash, knockback, squash

Full guide: `docs_read {"name":"game-feel"}` ([GAME_FEEL.md](../GAME_FEEL.md)). A hit in four lines, none of which changes a Transform:

```js
enemy.flash({ color: "#ffffff", duration: 0.1 });   // drawn white for 0.1 s (sprites, shapes, 3D meshes)
enemy.knockback(dirAwayFromHit, { speed: 7 });      // body impulse, else a decaying velocity; enemy.isKnockedBack = no control
camera.shake(0.35);                                 // trauma, squared; deterministic, 2D and 3D
time.hitStop(0.07);                                 // real seconds; UI and audio keep going; overlapping calls do not add up
```

The camera has screen effects too, drawn over the finished picture by its post pass (no PostProcess needed, they run on the game
clock and a scene load ends them; `docs_read {"name":"rendering-screen-effects"}`):

```js
camera.main.shockwave({ world: bomb.position, strength: 0.05, duration: 0.7 });   // a ring that bends the picture
camera.main.radialBlur({ intensity: 0.5, duration: 0.4 });                          // a dash or a big hit
camera.main.flash({ color: "#ff3030", duration: 0.15 });                            // damage
camera.main.heatHaze({ region: [0, 0.5, 1, 0.5], duration: 3 });                    // a shimmer over the lower half
camera.main.fadeOut({ duration: 0.6 });                                             // holds black; open a scene with fadeIn()
```

`entity.squash({ amount: 0.3 })` keeps the volume and springs back to exactly the entity's scale. The player's reduce motion
and reduced effects are honoured by the engine (`feel.reduceMotion`, `feel.reducedEffects`); tools and tests use the
`feel.*` commands (`feel.state` shows what is running).

An effect you draw (a hit spark, a pickup, a fire) is made in a loop: draft with `assets_animate_svg` (a `ramp` from the style's
palette, `layers` back/front/light), film it at the size it is drawn at (`assets_contact_sheet` with `sizes`, `allFrames` and the
greyscale row), judge readability, anticipation, impact, recovery and palette, change one thing and bake again:
`docs_read {"name":"effects"}` has the loop and three worked examples with the real calls.

The same effects, plus `spawn` (a prefab, with a `lifetime`) and `sound`, are JSON actions that an animation event can carry, so a
hit lands on the frame the sword does: `{ "t": 0.3, "feel": [{ "action": "hitStop", "duration": 0.06 }, { "action": "sound", "path":
"audio/hit.wav" }] }` in a clip file (2D or 3D), in `Animator.events` (`{clip, time, feel}`) or in `SpriteAnimator.events`
(`{frame, clip?, feel}`). An event needs a `name`, `feel` or both. `anim.add_event` and `anim3d.add_event` take `feel`.

### 9.32 Show choices: make N, show ONE sheet, ask for ONE number

When the person has to choose (which hero portrait, which level layout, which effect), do not describe the options and do not
show them one by one: make N candidates, put them on ONE picture and ask for ONE number. `review.sheet` draws every candidate
as a numbered thumbnail (a big number, its label and a line of facts) and returns the picture as `$image`; look at it, show it,
ask "which number?", and then record the answer with `review.pick`:

```
review.sheet {"label":"Which hero?","items":[
  {"image":"assets/hero_a.png","label":"A: round","candidate":true},
  {"image":"assets/hero_b.png","label":"B: tall","candidate":true},
  {"image":"assets/hero_c.png","label":"C: tiny","candidate":true}]}
review.sheet {"items":[{"level":{"sample":"example","size":[40,24]},"seeds":[11,12,13,14]}]}   # four layouts, one thumbnail per seed
                                                                                          # (entity "example" with a Tilemap, in the main scene)
review.pick {"sheet":"latest","n":2}                                                       # only after the person said "2"
```

- Items: `image`, `vector` (an .svg), `level` (the arguments of `tilemap.generate`, drawn on the CPU), and `scene`, `prefab`, `vfx`
  (drawn by the engine's renderer; they need a graphics device and fail with `no_gpu` before anything is written, so leave them out
  on a machine without one). A level's `sample` is ASCII rows, a rows file, or the id or name of an entity with a Tilemap; for the
  entity the scene is the main scene, or the one named by `sampleScene` on the item (`{"level":{"sample":"town",...},"sampleScene":"scenes/town.scene.json"}`).
  Four to nine candidates is what a person judges well; the most is 48 and the sheet is at most
  8192 pixels a side.
- **Never pick for the person.** `review.pick` records THEIR number. Over MCP and the CLI nothing asks them, so the number must come from the person in the conversation; if you do not have it, ask.
- Candidates are MOVED by the pick, never deleted by it (`review.cleanup` deletes the dropped files 7 days later; `droppedDays: 0` keeps them). Mark `candidate: true` on the items whose files you made only for this choice (variants of an
  image, a scene, a prefab). `review.pick` then moves the files of the items that were not chosen to
  `.factoria/review/dropped/<sheet id>/` (`drop: false` touches no file, `dropDir` picks another folder under `.factoria/`), and
  its result lists every move (`from`, `to`): moving a file back undoes it. The main scene, a file in `.git` and a file that is not marked
  are never moved (nor `factoria.json`, `assets.json`, anything under `.factoria/`, or the stage scene of an effect on the sheet).
  A level is not a file: picking it records its seed in the manifest, and `tilemap.generate` with the same arguments and
  that seed makes the very level.
- Every sheet is kept under `.factoria/review/sheet-NNNN/` (`sheet.png`, `thumbs/NN.png` and `manifest.json` with the items, their facts,
  when it was made and what was picked). `review.list` shows the sheets (newest first, which are still waiting for an answer),
  `review.info {"sheet":"sheet-0003"}` one manifest and its picture. A choice is final: to choose again, make a new sheet.
  `meta` (a small object of yours, e.g. `{"slot":"hero"}`) is stored with the sheet and returned by `review.pick`, `review.info` and `review.list`.
  Dropped files are deleted 7 days after the pick by `review.cleanup` (it runs after each new sheet; the chosen file is never touched).
- An effect is drawn as the middle picture of `vfx.filmstrip`; a prefab on a plain stage, framed from its visuals (2D) or turned
  three quarters under a studio light (3D). An item that cannot be drawn is a red tile that cannot be picked; the others still show.
- **In the editor** the person can answer on their own: each sheet you make (and each sheet of candidates `assets.generate_image`
  `{count}` makes) is offered in a toast ("Open in Review"), and the Review window (View > Review, EDITOR.md "Review window") shows it
  big and lets them pick with the keys 1-9 and Enter. So make the sheet, say in one line what it is for, ask for one number, and stop
  there: you never pick for them. Then read `review.info {"sheet":"<its id>"}`:
  - if `picked` is set, they answered in the window: the choice is done (and for candidates, the picked file is already the slot);
    do not call a pick yourself, a second pick of an answered sheet fails;
  - otherwise wait until they tell you the number in the conversation, and only then call `review.pick {"sheet":..., "n":...}`, or
    `assets.pick {"slot":..., "n":...}` for a sheet of asset candidates (never `review.pick` on those: it refuses them).
