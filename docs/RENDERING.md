# Rendering: cameras that draw into textures, and photographs of the world

Two ways to get a picture of the world into a texture, as opposed to onto the screen:

- **Render targets** (`Camera.renderTarget`): a camera draws into a texture, live, every frame. The texture is the id
  `"target:<name>"` and goes where any texture path goes. A screen on a 3D model, a mirror, the pages of a book with buttons
  that still work.
- **Off-screen capture** (`render.captureTexture({ entity | rect, space: "world", scale })`): a still picture of a part of the
  world, taken once, at a pixel scale you choose, even when that part is hidden, covered or nowhere near a camera.

For cameras on the screen (split screen, insets, post effects) see docs/AI_GUIDE.md, section 9.29; for a camera inside a menu
widget see docs/MENUS.md, "A camera inside the UI".

## Render targets

### Set one up

Give a `Camera` a `renderTarget` name and a size, then use `"target:<name>"` as a texture:

```json
{ "id": "page_cam", "components": {
    "Transform": { "position": [5000, 0, 0] },
    "Camera": { "renderTarget": "book", "renderTargetSize": [512, 768], "orthoSize": 384, "clearColor": [0.95, 0.9, 0.8, 1] } } }
{ "id": "page_title", "components": {
    "Transform": { "position": [5000, 300, 0] }, "Text": { "text": "Chapter 1", "fontSize": 48, "color": "#202020" } } }
{ "id": "next", "components": {
    "Transform": { "position": [5100, -330, 0] }, "Shape2D": { "size": [120, 48], "color": "#c08040" },
    "Interactable": { "kind": "button" } } }
{ "id": "book", "components": {
    "Transform": { "position": [0, 0, 0], "scale": [2, 3, 1] },
    "MeshRenderer": { "mesh": "quad", "texture": "target:book", "unlit": true } } }
```

- `Camera.renderTarget` is the name: letters, digits, `_`, `-` and `.`, up to 64 characters, unique in the scene. A second camera
  with the same name is not drawn, with an error that says which one owns the name.
- `Camera.renderTargetSize` is `[width, height]` in pixels, each 1..4096 (default `[1024, 1024]`). The camera's aspect is that
  rectangle's. An orthographic camera with `orthoSize` 0 sees one world unit per texture pixel; with an `orthoSize` it sees that
  half-height whatever the size. Changing the size or the name at run time remakes the texture. Memory is width x height x 8 bytes
  (4 more per pixel with antialiasing): a 1024 x 1024 target is about 8 MB.
- A target camera draws only into its texture. It is not drawn to the screen, ignores `viewport`, `primary` and `clear` (it always
  clears to `clearColor`, alpha included, so a transparent target composes over whatever is behind it), and it is never
  `camera.main`, never in `camera.all()` and never the audio listener. It still has to be active (the entity and its ancestors).
  The editor's viewport does not pick it either.
- Perspective and orthographic both work, 2D and 3D. A target camera sees everything in its frustum, like any camera: lights,
  sprites, shapes, text, tilemaps, particles, meshes.
- A target is drawn every frame its camera is active, whether or not something shows it (one more pass and one more image each):
  deactivate the camera while its page is not on screen. The texture is freed when the camera goes away or its name changes.
- `play.report` and `game.state().renderStats` have `renderTargets`: how many target cameras were drawn this frame.

### Where `target:<name>` goes

| Field | Shows the target |
|---|---|
| `MeshRenderer.texture` | on a 3D model: a monitor, a mirror, a page. |
| `MeshRenderer.normalMap` | as a normal map (rare, but it is the same lookup). |
| `MeshRenderer.materialParams` | a texture parameter of a custom material (docs/SHADERS.md): `{ "screen": "target:book" }`. |
| `Sprite.texture` | in the 2D world. |
| `Panel.texture` and the other UI boxes | on the screen UI. |
| `Button.icon` | as a button's icon. |

`factoria validate` accepts `target:<name>` in those fields (it does not look for a file) and reports an empty or invalid name
with the name it expected. A name that no active camera has draws the missing-texture checker and logs one error that says so and
how to add the camera.

The picture is upright on every backend, whatever the graphics API's own convention for texture origins.

### Order, and a camera that sees itself

Targets are drawn before the cameras that show them, in the same frame, so a screen on a 3D model is never a frame behind. A
target that shows another target is drawn after it (the engine orders them by what each one's view shows).

- **A camera whose own view shows its own target** (the quad with `target:book` stands in front of `page_cam`) cannot read the
  image it is drawing into. That surface is drawn as the missing-texture checker and one error says so, with the fix: move the
  entity that shows the target out of that camera's view, or keep it out of what that camera draws with `Camera.hideTags` (see
  "Choosing what a camera draws: showTags and hideTags", below). A surface the camera does not draw is not a self-view: no checker.
- **A loop** (A shows B and B shows A, a mirror facing a mirror) is allowed: the one that draws first shows the other's picture
  from the previous frame, so the loop is one frame late and never an error.

### A page of a book: world-space entities

A target camera does not draw screen-space UI (`Panel`, `Button` and the other widgets, and any item with `space: "screen"`):
those belong to the screen. What a page is made of are ordinary world-space entities: `Sprite`, `Text`, `Shape2D`, children of
one `Transform` that you move away from everything else. Give them `Interactable` components and they become widgets: hover,
click, toggles, sliders, focus.

### Choosing what a camera draws: showTags and hideTags

A camera draws every world-space entity in its frustum unless you give it a culling mask by entity tags (the `tags` of an entity,
`"tags": ["page_left"]` in a scene file, `entity.addTag("page_left")` from a script). Two fields of `Camera`, both arrays of tag names
and both `[]` by default (the camera draws everything):

- `showTags`: when it is not empty, the camera draws only the entities that have one of these tags **or have an ancestor that does**.
  Tag the root of a page and every `Sprite`, `Text`, `Shape2D` and child under it is drawn.
- `hideTags`: the camera does not draw the entities that have one of these tags or have an ancestor that does.

The rule: the camera draws entity `e` when (`showTags` is empty OR `e` or an ancestor has one of `showTags`) AND neither `e` nor an
ancestor has one of `hideTags`. `hideTags` wins. A tag in both lists is an error for `factoria validate`, which also warns about a tag
no entity or prefab carries (with a did-you-mean), because a typo there draws nothing.

```json
{ "id": "page_left_root", "tags": ["page_left"], "children": [ { "id": "title", "components": { "Text": { "text": "Chapter 1" } } } ] },
{ "id": "page_cam", "components": { "Camera": { "renderTarget": "page_left", "showTags": ["page_left"] } } },
{ "id": "main_cam", "components": { "Camera": { "hideTags": ["page_left", "page_right"] } } }
```

Here the page lives anywhere in the world, even in front of the main camera: the page camera draws only it, and the main camera
never draws it, so there is no need to put it at x = 5000.

What the mask covers, and what it leaves alone:

- It applies to everything a camera draws in world space, on a screen camera and on a render-target camera alike: `Sprite`,
  `Shape2D`, `Text`, `Tilemap`, `ParticleEmitter` and `MeshRenderer` (3D meshes and world-space items; the `Text` of a 3D scene too).
  Screen-space UI (`Panel`, `Button` and the other widgets, any item with `space: "screen"`) belongs to the screen: the mask does not
  filter it.
- Lights are not filtered. A `Light` or `Light2D` still lights everything its camera draws, whatever its tags; an entity a camera does
  not draw casts no shadow in that camera's view (a 3D mesh, a `Tilemap` that blocks 2D light).
- The pointer follows the picture: the Interactable hit tests of the camera under the pointer, the mesh that shows a render
  target (its page camera's mask decides which Interactables of the page the pointer reaches), `render.pick` and `game.click`
  `{position}`/`{world}`/`{id}` only hit what that camera draws. `game.click {id}` of an Interactable its camera hides is an error that
  says so.
- The mask is read every frame, so a tag added or removed at run time takes effect on the next frame drawn. Change the lists from a
  script by assigning a whole new array: `pageCam.get("Camera").showTags = ["page_right"]` (`pageCam` is the entity of the camera).
- The editor shows what the game shows: its viewport is the game view, drawn by the project's cameras with their masks. The debug
  overlays (`debug.line`, selection boxes) are not entities and are never filtered.
- Cost: nothing when both lists are empty. With a list the camera checks each entity's tags and its ancestors once per frame.

### A page of a book: world-space entities, in a script

A target camera does not draw screen-space UI (`Panel`, `Button` and the other widgets, and any item with `space: "screen"`):
those belong to the screen. What a page is made of are ordinary world-space entities: `Sprite`, `Text`, `Shape2D`, children of
one `Transform`. Give them `Interactable` components and they become widgets: hover, click, toggles, sliders, focus.

Keep the page apart from what the main camera draws in one of two ways. Tag the page's root and use `showTags` on the page camera and
`hideTags` on the cameras that draw the model (above): the page can then be anywhere, and a book with several pages is one tag per
page. Or, without tags, put the page where the main camera never looks (x = 5000, or far along the axis the main camera does not
see). A page you want to see both ways, in the world and on the model, needs no copy: a camera that does not hide its tag draws it.

### Pointer input through the mesh

A pointer over a mesh that shows `"target:<name>"` reaches the `Interactable`s that camera sees, at the point of the picture
under the pointer. The engine finds that point from the hit triangle's UV, so it works on a flat `quad`, on a curved model (a
cylinder, a bent screen, a sphere), on a glTF model or on a procedural mesh (`mesh.create`, docs/SCRIPTING.md), with `uvScale` taken
into account. A procedural mesh is hit-tested against its CURRENT triangles and uvs: a page you bend with `mesh.update` every frame
answers where it is drawn, and a mesh that did not change is not rebuilt (the triangles are cached per mesh version). Only the triangles
inside a submesh count, the ones the mesh draws:

```js
import { camera } from "factoria";
import { game } from "factoria:test";
// The screen point where the model shows the toggle (here: the model's point [0, 0.2, 0]); any point over the mesh will do.
const pos = camera.worldToScreen([0, 0.2, 0]);
game.mouseMove(pos);                  // ui.hover fires for the Interactable under that point of the picture
game.click(pos);                      // press + release: ui.click, ui.change (toggle / slider)
```

- Hover, press, release, click, `ui.change` of toggles and sliders, and slider dragging all work. A slider keeps
  following the pointer after it leaves the mesh: the engine extends the plane of the last triangle it was on, so a drag may end
  outside the picture and the value goes to the end of the track.
- A screen widget (a Button on the HUD, a modal Panel) under the pointer wins over the page, as it wins over the world.
- While the pointer is over a page, the world-space Interactables of the main view are not reached through that point: the page
  replaces them.

Limits, so you do not look for a bug:

- The nearest page mesh under the pointer wins. Other 3D things in front of it (a hand, a table lamp) do not stop the pointer.
- Only meshes with UVs that lay the picture out: the built-in primitives, glTF models and procedural meshes (`mesh.create`).
- A `Sprite`, `Panel` or `Button` that shows a target is only a picture: it forwards no pointer input to the page. Use a
  `CameraView` (docs/MENUS.md) when the player must drag what a camera shows inside a menu.
- `game.click(id)` of an `Interactable` that only the page shows (the main camera hides it with `hideTags`, or it is far off screen)
  is aimed through the mesh: the engine takes a point of the widget in the target camera's view, finds the matching point of a mesh
  that shows the target and clicks where the main camera puts it, but only where the pointer really reaches that widget (a mesh or
  a widget in front is skipped). When no such point exists it is an error that says why: no mesh shows the target, the mesh is
  inactive, off screen or covered, the widget is outside the target camera's view, or the mesh is itself drawn only by another render
  target (a target shown inside a target is not reached by the pointer). An `Interactable` the main view shows on screen is clicked
  where it is, as always.
- The `game.click` command (and `render.pick`) answers `widget`, the widget the pointer reached, also through a mesh, and
  `via: {mesh, target}` - the entity of the `MeshRenderer` and of the `Camera.renderTarget` camera - when the point was over a page
  mesh (and no screen widget was on top). So `game.click {"position":[x,y]}` over the model tells you which widget of the page it hit.

### Tests

A render test shows the model (`game.screenshot`) and checks pixels, or checks that a click through the model flipped the toggle:

```js
import { test, expect } from "factoria:test";
import { game, world, camera } from "factoria";
test("the page's toggle works through the model", () => {
  game.step(2);
  const pos = camera.worldToScreen([0, 0.2, 0]);          // aim at the toggle's place on the model
  game.click(pos);
  expect(world.find("toggle").get("Interactable").on).toBe(true);
});
```

Anything a test awaits (a `scene.preload`, a platform answer) must compare `scene.current` (or `scene.generation` for a reload
of the same scene) with the scene it started in before it acts: the page and the model belong to one scene.

## Render interpolation

The simulation moves in fixed steps (`physics.fixedHz`, 60 by default). On a 120 or 144 Hz display most frames run no step, so
the picture repeats a pose and then jumps. `"render": { "interpolation": true }` in `factoria.json` (default `false`) draws
every entity at the pose BETWEEN its last two fixed steps, `alpha = time since the latest step / fixed step` of the way from the
older to the newer one. The picture runs one step (16.7 ms at 60 Hz) behind the simulation, which is what makes it smooth.

- **Only the drawing changes.** The blend is applied by `World::drawn_matrix`, like shake and squash; it is never written to
  `Transform`. Scripts, physics, commands, bounds, audio, picking and saved scenes always see the real, latest pose
  (`entity.position` is where the simulation put it, the sprite is drawn up to one step behind). That includes the camera:
  `screenToWorld`, `worldToScreen`, `screenRay`, `cameraAt`, UI hit tests and picking are answered from the camera's REAL pose,
  so a click lands on the same world point whatever alpha the frame has; only the drawing uses the blended camera.
- **What is included.** Position and scale are blended linearly and rotation by quaternion slerp (a rotation about z alone, the 2D case,
  blends the angle itself, and one that did not change is kept bit for bit). A rotation that turned MORE THAN 180 degrees on an
  axis in one step (a fast spin, a wrap from 359 to 1) cannot be told from a short turn the other way, so it is not blended: it
  is drawn at the latest rotation. A child follows the blended pose of an interpolated parent (each entity of the chain is blended on its
  local pose). A `Camera` is viewed from its blended pose, so it stays in step with what it follows (see "A follow camera" below). Physics bodies (2D and 3D) are interpolated through their entity's Transform, which physics writes every
  step. Lights, particles and sounds are placed from the real pose (see "What stays at the real pose" below).
- **What stays at the real pose.** Lights (`Light2D`, shadows), particle emitters (where particles are born) and sounds read the Transform, not the blended pose, which they do not have. A sprite that moves with a light or an
  emitter is drawn up to one fixed step behind it (a light or a spark ahead of its sprite by up to 16.7 ms at 60 Hz). That is a
  limit of the quality, not an error; where it shows (a lantern carried by a character, a trail from a moving projectile), put
  `Interpolation` with `mode: "off"` on the sprite and what it carries, so both are drawn at the real pose. Likewise `Parallax`
  layers are drawn shifted for the blended camera, but `Parallax.offset` and `entity.bounds()` of a layer are the shift of the real
  camera, so they do not depend on the frame time (the drawing and the number can differ by up to one step of the camera). The
  editor draws its selection outline from the real pose too, so while the game plays with interpolation on, the outline can be
  up to one step off the picture (the move, rotate and scale handles are only shown in Edit and Pause, which draw the real pose).
- **Per entity.** The `Interpolation` component overrides the project: `mode: "on"` interpolates an entity even when the project
  does not, `"off"` never (a cursor, an entity a script moves every frame), `"inherit"` follows the project.
- **No smearing.** A pose is blended only when a fixed step moved it. These are drawn where they are: a new entity, a Transform
  written outside the fixed steps (a script's `update` / `lateUpdate`, a command, the editor), a step that moved the entity farther
  than `"interpolationSnapDistance"` (world units, 0 = no limit) and `entity.teleport()`, which a script calls right after
  setting a position in `onFixedUpdate` (a respawn, a door).
- **Determinism.** Nothing the simulation computes changes, so replays, `--frames` runs and tests give the same world. Pictures
  depend on alpha, which comes from the frame times: `Engine::step` (`game.step`, `--headless`, `--frames`, replays and the
  autoplay bot) always draws alpha 1, the real pose, and a paused game and the editor's pause and step show the real pose too. A
  windowed run with an unstable frame time draws what its frame times say.
- **Cost.** Only interpolated entities keep a record (three transforms and a few flags, 128 bytes, in a dense list, plus
  4 bytes per entity slot); each fixed step and each frame (after the steps and again before drawing) reads the Transforms, or only the
  `Interpolation` components when the project does not interpolate by default, and the work on records is proportional to the
  interpolated entities. See docs/performance/, "Render interpolation".

### A follow camera

The camera is drawn at its blended pose, so it must move together with what it follows:

- Write the camera in `onFixedUpdate` (the same step that moves the target). Both are blended by the same alpha and stay in step.
  This is the recipe to use.
- A camera written in `onLateUpdate` (or `update`) is a write outside the fixed steps: it is drawn at the pose it was given, the
  target's real pose of this frame, while the target itself is drawn up to one step behind. The camera is then ahead of the
  picture, which shows as a wobble. If the camera has to follow in `onLateUpdate`, put `Interpolation` with `mode: "off"` on the
  target (and on what it carries) so the target is drawn at its real pose too.
- `onLateUpdate` reads the real poses: `entity.position` of the target is the latest simulation pose, not the pose drawn.

## Game feel in the renderer

Camera shake and squash are a pose added to an entity's matrix when the frame is drawn (`World::drawn_matrix`), so a shaken
camera shows the whole scene moved while every Transform stays put. A flash (`entity.flash`) is drawn by the renderer without
touching the entity's colour: sprites take a flash variant of the quad shader (OpenGL, Direct3D 11, Metal and web alike),
`Shape2D` mixes the colour on the CPU, and a 3D mesh fades its surface colour out and adds the flash as emission (lit meshes
keep a little specular and image-based reflection). A flashing entity never shares a draw with a non-flashing one. `Text`,
`Tilemap`, particles and the UI are not flashed. See [GAME_FEEL.md](GAME_FEEL.md).

## Color space: gamma and linear

`SceneSettings.colorSpace` decides how the renderer adds and blends light. Nothing else in the project changes: you keep
picking colours by eye and keep the same PNG files.

- **`gamma`** (the default): lighting and blending work on the sRGB values themselves, in 8 bits (a float frame where the GPU
  has one). It is what every project made before M71 uses, and it is drawn exactly as it always was: same pixels, same goldens.
- **`linear`**: lighting and blending work in linear light, the way light adds up in the world. Two lamps add their light,
  a light fades with the square of the distance as it should, and a half-transparent white over black is half the light, which a
  display shows as 0.735, not 0.5. The picture is encoded to sRGB on its way to the screen.

### What changes in a linear scene

- **Colours you pick are converted for you** (they stay sRGB values in the scene file): sprite, shape, tilemap, text and mesh
  tints, `MeshRenderer.color` and `emissive`, a model's `materialColors`, light and ambient colours, fog, sky and horizon, the
  camera's clear colour, particle colours, gradient and flash colours. The colours a glTF model carries are already linear and are
  not converted. Alpha is coverage, not light: it is never converted.
- **Colour textures are read as sRGB:** sprites, tilemaps, particles, text, albedo and emissive maps. The GPU decodes the texels
  before it filters them (format `SRGB8A8`, and the sRGB variants of BC7, ASTC and ETC2 for exported `.ktx2` twins). Where a
  backend has no sRGB variant the shader decodes (same result, the filtering happens on the encoded values).
- **Data textures stay as plain numbers:** normal maps, metallic-roughness, occlusion, masks, the light buffer and the shadow maps.
- **One texture used both ways** (an image you use as a sprite and as a mask): the first user that loads it decides the format of
  the GPU image; every later use is corrected in the shader (a decode, or an encode) so that a colour use always sees linear light
  and a data use always sees the file's own values. The cost is that such a texture is filtered in the other space (a small
  difference, only visible on hard edges). Nothing is loaded twice.
- **The scene target holds linear light**: `RGBA16F` where the GPU renders to it (twice the memory of RGBA8), else `R11G11B10`
  (half the memory of RGBA16F, no alpha: a game target without alpha is only a problem if you read the picture's alpha, for example
  `render.captureTexture` of the frame), else `SRGB8A8` (8 bits that hold linear light: the GPU encodes what is written and
  decodes what is read, so the darks keep their precision and blending is in linear light), else plain `RGBA8` (banding in the
  darks; only a GPU with no sRGB render target, rare). `render.supports {"feature": "linearColor"}` is true on every GPU;
  `render.supports {"feature": "r11g11b10"}` says whether the packed float is there. The tests pick the formats with
  `FA_SCENE_FORMAT` (`rgba8`, `r11g11b10`).
- **A switch at run time is allowed** (a script writes `colorSpace`): the game target is made again in the other format, the
  textures, shaders and pipelines are kept, and no GPU image is left behind. A texture already made is not made again.

### Limits of this step

The final conversion to the display (tonemap, exposure, display-space HUD) arrives with the post-processing stack; for now a linear
scene is encoded by a plain sRGB encode when it is shown, values above 1 clip, the HUD and screen-space UI blend in linear light
too (their colours still come out as picked, the blending of half-transparent edges differs slightly), and bloom and the colour
filter work on the linear values. The editor's viewport shows the same encoded picture. Mips of an sRGB texture are averaged on the
sRGB values when they are made. A custom material ([SHADERS.md](SHADERS.md)) gets what the GPU gives for its own textures (linear light
when the texture was first loaded in a linear scene, the file's numbers otherwise) and its colour parameters as authored, and what
its `surface()` returns is taken as linear light in a linear scene: convert a colour parameter yourself (`pow(c, vec3(2.2))` is
close enough).

### Migrating a project

1. Switch `colorSpace` to `linear` in one scene and look at it: lit scenes get darker where the lights are weak and brighter
   where two overlap; the ambient light that looked right in gamma is now too dark (raise it, or `ambientLight` roughly to the
   colour you would see: gamma 0.5 grey is a linear 0.21).
2. Sprites and UI keep their colours; soft shadows, glows and particles that were blended with additive or alpha blending look
   different (usually cleaner). Lower the intensity of strong additive glows.
3. A texture that is not a colour (a height map, a noise or mask) works unchanged as a sprite mask or a normal map; if it is
   shown as a sprite in a linear scene it is shown as a colour, i.e. darker than its numbers say.
4. Check custom materials ([SHADERS.md](SHADERS.md)) as above.

## Off-screen capture

`render.captureTexture({ entity | rect, space: "world", scale })` draws a part of the world into a texture of its own, with a
camera of its own, and returns it as a `Texture` (docs/SCRIPTING.md, "Render"). It is not the screen: the player's camera does
not matter and no frame needs to have been drawn.

```js
// A card that is hidden (only drawn to be photographed), at 2 pixels per world unit:
const shot = render.captureTexture({ entity: world.find("Card"), space: "world", scale: 2 });
world.find("Preview").get("Sprite").texture = shot.id;

// An area of the world, one pixel per unit, for a map thumbnail:
const map = render.captureTexture({ rect: [0, 0, 1600, 900], space: "world", scale: 0.25 });
```

- `entity` photographs the subtree of an entity: its area is the union of `entity.bounds()` over the entity and its children (world-space Sprite, Shape2D,
  Text and Tilemap; particles and meshes do not give a box, but are drawn when they fall inside it). An entity with none of those
  is an error that asks for `rect`.
  `rect` is `[x, y, width, height]` in world units (x, y the lower-left corner, y up) and takes everything active in that area.
  Give exactly one.
- `scale` is pixels per world unit (default 1): the picture is `ceil(width * scale)` x `ceil(height * scale)`. Each side is at
  most 4096; a larger request is an error that names the largest scale that fits. Memory is 4 bytes a pixel in the engine and
  the same on the GPU while it is drawn, so a 4096 x 4096 picture is about 64 MB. At most 32 `Texture`s are alive at once
  (`texture.destroy()` frees one).
- The subject may be **hidden** (an `entity` is drawn even when its own `active` is off or an ancestor's is; a descendant that is
  itself inactive is not drawn), **covered** by other entities (only the subject's subtree is drawn in `entity` mode, so what
  lies on top is not in the picture), or **off camera** (the capture has its own view, centred on the area).
- The background is transparent (alpha 0 where nothing was drawn) and the colour is straight, not premultiplied. A `rect` draws
  everything active in the area, covering things included.
- The world is drawn with its lights, but without bloom or colour filter, and the HUD and the screen-space UI are not part of
  it. Meshes are drawn by an orthographic camera at z = 0 looking along -Z at the area, within 1000 units in front and behind.
- A `Sprite` that shows `"target:<name>"` appears with that target's last picture (the checker when no frame has drawn it yet).
- With `graphics` off (no renderer) the texture is a flat placeholder of the size the scale gives, and `texture.placeholder` is
  `true`.
- It is synchronous: no Promise, no scene change to wait for. The entity must still exist when you call it.

For the whole frame the player sees (at most 2048 on a side), use `render.captureTexture({ width, height })`.
