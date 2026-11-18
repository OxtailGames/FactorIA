# Rendering: cameras that draw into textures, and photographs of the world

Two ways to get a picture of the world into a texture, as opposed to onto the screen:

- **Render targets** (`Camera.renderTarget`): a camera draws into a texture, live, every frame. The texture is the id
  `"target:<name>"` and goes where any texture path goes. A screen on a 3D model, a mirror, the pages of a book with buttons
  that still work.
- **Off-screen capture** (`render.captureTexture({ entity | rect, space: "world", scale })`): a still picture of a part of the
  world, taken once, at a pixel scale you choose, even when that part is hidden, covered or nowhere near a camera.

Showing the picture on an HDR display is the last section, "HDR output".

For cameras on the screen (split screen, insets, post effects) see docs/AI_GUIDE.md, section 9.29; for a camera inside a menu
widget see docs/MENUS.md, "A camera inside the UI".

## Pages

This page has the render targets, the post-processing stack, the depth and normals prepass, capture and HDR output. The rest is on two pages (`docs.read rendering-effects`, `rendering-screen-effects`):

- [Screen-space effects](rendering/RENDERING_EFFECTS.md): ambient occlusion and its cost, screen-space reflections, and the outline (both modes, where it is skipped).
- [Transient screen effects](rendering/RENDERING_SCREEN_EFFECTS.md): Shockwave, heat haze, radial blur pulse, flash and fade of the camera, drawn by its post pass.

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
  `FA_SCENE_FORMAT` (`rgba8`, `r11g11b10`). `R11G11B10` has a 6-bit mantissa (5 for blue): between two powers of two it has 64 steps (32
  in blue), so a smooth gradient of values ABOVE 1.0 (a bright emissive surface, a glow, a sun disc) shows bands of 1.5 to 3% of the
  value (3 to 6% in blue) that `RGBA16F` does not have, and the darks keep their precision. The picture the final pass writes (sRGB
  values) is therefore never kept in it: on such a GPU the final images are plain `RGBA8`, which cannot go above white, so an HDR
  output stays within paper white there (`render.output`'s `status` says so).
- **A switch at run time is allowed** (a script writes `colorSpace`): the game target is made again in the other format, the
  textures, shaders and pipelines are kept, and no GPU image is left behind. A texture already made is not made again.

### What a linear scene shows on the screen

With nothing in the post-processing stack that converts the picture (no exposure, tonemap or colour filter), the present copy encodes
linear light to sRGB, values above 1 clip, and the HUD and screen-space UI are drawn into the scene, so they blend in linear light too
(their colours still come out as picked, the blending of half-transparent edges differs slightly). Bloom works on the linear values.
With exposure, a tonemap or a colour filter the final pass of the stack does the encode instead (see "Post-processing" below): the
picture is tonemapped, encoded and dithered once, and the HUD is drawn afterwards in display colours, as in a gamma scene. The editor's
viewport shows what the game shows: after the final pass the picture itself, otherwise the renderer keeps an 8-bit encoded copy of the finished frame for it (`Renderer::set_editor_view`, made only while the scene is linear and freed when it goes back to gamma; a game never makes it). Mips of an sRGB texture are averaged on the
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

## Post-processing: bloom, exposure, tonemap, colour grading, lens effects, colour filter

A `PostProcess` component (`docs.components`; docs/COMPONENTS.md is repository only, not in the binary) on the entity of a `Camera` is that camera's stack of screen effects; on an entity
without a camera it is a volume that blends into the stacks of the cameras inside it. Every effect is off by default, and **a frame
without any stack declares no pass and makes no render target**: the picture goes straight to the screen, as before. **Every camera
has its own stack**, also in a split screen or with a viewport smaller than the screen: its `post` pass, its prepass, its coverage
image and its automatic exposure work over that camera's rectangle of the picture only, in the camera's own pixels (the pixelate
grid, the lens centre, the vignette, the grain and the dither start at the corner of the rectangle, so the two halves of a split
screen look alike). Two things stay one per frame, taken from the camera that draws first: the **bloom** (it runs over the whole
picture, before the final passes) and the **colour filter** (it is the last step over everything the screen shows).
`Camera.bloom*` and `Camera.colorFilter` stand in for a `PostProcess` on a camera that has none (deprecated, the same picture).
The passes of camera `n` are named `camera:<n>/post`, `camera:<n>/prepass` and so on. Where the cameras' rectangles do not cover the
picture, or overlap, a `post-base` pass first draws the picture the way a frame without effects would (the encode of a linear scene, a
copy of a gamma one), and a camera without a stack over one with a stack gets that plain pass over its own rectangle, so the stack
of one camera never reaches another's pixels.

The passes of a frame, in order (`render.frame_graph` lists them, and `RenderStats::passes` times them):

| Pass | When | What |
|---|---|---|
| `bloom-bright`, `bloom-down-*`, `bloom-blur-h`, `bloom-blur-v`, `bloom-composite` | `bloomEnabled` | The glow: threshold with a soft knee, a reduced-resolution blur, added back (times the lens dirt texture). |
| `exposure-luma`, `exposure-adapt` | `exposureMode` auto | The frame reduced to 32x32 brightness values, then the stored 1x1 exposure moves toward the one that makes the average 18% grey by `1 - exp(-speed * dt)`, kept between `exposureMinEv` and `exposureMaxEv`. No read back; the engine's frame `dt`, so the same frames give the same exposure on every run. Needs a float render target; the stored exposure is a 32-bit float where the GPU can filter one (else 16-bit, which stops a little short of the target at a slow speed and a high frame rate). |
| `prepass` | `outlineEnabled` in depth mode, `ssaoEnabled` (and the effects of "Depth and normals") | The opaque meshes' depth and normals, read by the outline and the ambient occlusion (see "Depth and normals"). |
| `ssao-ao`, `ssao-blur-h`, `ssao-blur-v`, `ssao-apply` | `ssaoEnabled`, 3D meshes in the view | The ambient occlusion, before the bloom (see [Screen-space effects](rendering/RENDERING_EFFECTS.md)). |
| `fog-blend`, `shafts-rays`, `shafts-add` | `fogEnabled`, `sunShaftsEnabled` | Distance and height fog and the sun shafts (see [Screen-space effects](rendering/RENDERING_EFFECTS.md)). |
| `dof-down`, `dof-gather`, `dof-composite`, `dof-copy` | `depthOfFieldEnabled` | The depth of field (see "Depth of field and motion blur"). |
| `motion-blur`, `motion-copy` | `motionBlurEnabled` | The camera motion blur (same section). |
| `sprite-coverage` | `outlineEnabled` in sprite mode | The 2D world drawn once more into an RGBA8 image whose alpha is how much each pixel is covered, read by the sprite outline (see [The outline](rendering/RENDERING_EFFECTS.md#the-outline)). |
| `post` | exposure, tonemap, colour grading, vignette, chromatic aberration, lens distortion, sharpen, outline, pixelate, posterize, film grain, or a colour filter in a linear scene | The final pass, one full-screen pass: pixelate (the picture is read at the block centres), lens distortion and chromatic aberration (while the picture is read), exposure, tonemap (`none` clips, `neutral`, `aces`, `agx`, `reinhard`), the encode for the display, colour grading, vignette, sharpen, outline, posterize, film grain, a one-step (1/255) dither so smooth gradients do not band on an 8-bit screen (not under posterize), and the colour filter. |
| `hud-over-post` | the final pass ran and screen-space items exist | The HUD, drawn over the final picture in display colours: it is never exposed or tonemapped, and never glows. |
| `color-filter` | a colour filter with no `post` (or a HUD after it) | The accessibility filter over everything, the last pass. With `post` and no HUD it is part of `post`. |

A game in the default gamma colour space with only bloom or only a colour filter gets exactly the passes it had before the stack
existed (the old pictures are byte for byte the same). Exposure and tonemap decode the stored colours to light, work in linear
light and encode back, so `exposureEv` +1 doubles the light, not the stored number. A stack without the ten effects below runs the
same code as before: they are switched on by a bit mask, so an effect that is off costs no sample and no arithmetic.

### The effects of the final pass

Ten effects run in the `post` pass, in the order of this table (`render.supports {"feature": "<effect>"}` is true where this build
draws them). They work in display space (the encoded values the screen shows), the same on an SDR and on an HDR output, except the
two that bend the picture and the pixelation, which move the place it is read from.

| Effect | Fields (`PostProcess`) | What it does |
|---|---|---|
| `radialBlur` | `radialBlurIntensity`, `radialBlurCenter`, `radialBlurSamples` | The picture streaks away from the centre: `radialBlurSamples` taps along the line from the pixel toward `radialBlurCenter`, as far as `radialBlurIntensity` says, averaged. It reads the scene, so it acts before the grade and the other display effects. `camera.radialBlur` starts a pulse of the same blur (see "Transient screen effects"). |
| `lensDistortion` | `lensDistortionIntensity` (-1 pincushion .. 1 barrel), `lensDistortionScale` (zoom), `lensDistortionCenter` | Moves the point each pixel reads. It acts while the picture is sampled, so the bloom glow bends with it. Where the lens reads outside the picture the pixel is **black** (raise the scale to hide it). |
| `chromaticAberration` | `chromaticAberrationIntensity` | Red and blue are read at slightly different distances from the centre, growing toward the edge; green stays. Read at the same moment as the lens; the sample is clamped to the picture's edge. |
| `colorGrading` | `colorGradingTemperature`, `Tint`, `Lift`, `Gamma`, `Gain`, `Contrast`, `Saturation`, `HueShift`, `colorGradingLut`, `colorGradingLutContribution` | After the tonemap and the encode, in display space: white balance, gain, lift, gamma, contrast around mid grey, saturation, hue rotation, then the LUT. Nothing is clipped at white, so an HDR value above 1 stays above 1. The curves (`colorGradingCurve*`) are not drawn yet. |
| `vignette` | `vignetteIntensity`, `Smoothness`, `Roundness`, `Center`, `Color` | Mixes the display value toward `vignetteColor` toward the edge of the screen. The same on SDR and HDR (it works on the encoded value). |
| `sharpen` | `sharpenIntensity` | Contrast-adaptive: it reads the four neighbours (each shaded the same way as the pixel) and sharpens less where the local contrast is already high, so edges ring less. |
| `outline` | `outlineMode` (`depth`, `sprite`), `outlineColor` (alpha = opacity), `outlineWidth`, `outlineDepthThreshold`, `outlineNormalThreshold`, `outlineAlphaThreshold` | Lines at the edges of things, drawn over the sharpened picture (see [The outline](rendering/RENDERING_EFFECTS.md#the-outline)). |
| `pixelate` | `pixelateSize` | Every pixel of a block of `pixelateSize` design pixels shows the colour at the block's centre (the block grid starts at the top-left of the camera's rectangle of the picture, so a block cut by the right or bottom edge reads its centre clamped to the picture). It moves the place everything of the final pass reads (the lens, the grade, the vignette, the sharpen and the outline see the block centre, so the outline is blocky too); only the film grain and the dither stay per pixel. |
| `posterize` | `posterizeLevels` | Each colour channel of the display value is cut to `posterizeLevels` evenly spaced values (`round(c * (n - 1)) / (n - 1)`), after the grading, the vignette, the sharpen and the outline. An HDR excess above white is kept as it is. The 1/255 dither is switched off while it is on, since it would move a value off its level. |
| `filmGrain` | `filmGrainIntensity`, `Size`, `Animated`, `LuminanceResponse` | An integer hash noise added to the display value, weighted toward the mid tones by `LuminanceResponse` (1) or even (0). It is seeded by the engine's frame counter (`world.frame()`), so a recorded or replayed run gives the same grain; `filmGrainAnimated` false uses a fixed seed. It is added before the dither and the colour filter. |

### Ambient occlusion and the other screen-space effects

`ssaoEnabled` darkens creases and contact points of 3D meshes (passes `ssao-*`, drawn before the bloom). Its section, its costs, the
effects that follow it (reflections, fog) and the outline (`outlineEnabled`, depth and sprite mode) are on the page
[Screen-space effects](rendering/RENDERING_EFFECTS.md).

A gamma scene's stored colours are display values already: the effects use them as they are, and a scene with exposure or tonemap
decodes, tonemaps and encodes first. A linear scene always runs the conversion. On an HDR output the final pass goes above paper
white only when exposure or tonemap is on (see "HDR output"); a stack with only these effects is drawn in the standard range.

### Depth of field and motion blur

Two effects that read the depth prepass ("Depth and normals") and work on the **scene colour**, before the bloom and the final pass (so
they blur light, and the HUD, drawn over them, is never blurred). They need opaque 3D meshes in view: a camera without any (a 2D game)
draws a frame without them. Every camera has its own passes and its own focus (a split screen blurs each rectangle on its own). With
both off there is no pass and no prepass for them: the picture is the one without them, byte for byte.

- **`depthOfField`.** Each pixel gets a signed circle of confusion from its linear view depth: 0 inside the band of `depthOfFieldFocusRange`
  world units centred on the focus distance, growing smoothly to `depthOfFieldNearBlur` (in front) or `depthOfFieldFarBlur` (behind), in
  design pixels times the render scale. Where no mesh was drawn (the sky, sprites, shapes) the depth counts as infinite: the far blur
  applies. `dof-down` halves the picture and keeps the circle, `dof-gather` blurs it with a disc of taps (a fixed per-pixel rotation, so
  every run draws the same frame; about 4 taps per pixel of radius, at most 64), `dof-composite` mixes the sharp picture with the blur.
  A sharp object never takes colour from a blurred one behind it; a blurred near object spreads past its silhouette.
  `depthOfFieldBokeh` weights bright points so they show as discs. **Autofocus:** with `depthOfFieldTarget` the focus is that entity's
  view depth, moved toward it each frame by `1 - exp(-depthOfFieldFocusSpeed * dt)` of the way (engine clock: the same frames give the
  same focus on every machine). The focus is state of the renderer, one per camera; the first frame, a camera that did not draw the frame
  before, no target, a destroyed target or one behind the camera use `depthOfFieldFocusDistance` at once.
- **`motionBlur`.** A pixel's velocity is the screen distance between its point now and in the frame before (from the depth and the
  previous view-projection); the picture is sampled along it (`motionBlurSamples` taps, a fixed jitter) over `motionBlurIntensity` of
  it, at most 8% of the picture's larger side. **Only the camera's movement blurs**; an object that moves on its own does not. No blur
  on the first frame or after the camera did not draw (a camera switch, a deactivated camera). A camera moved to another place between
  two frames is **not** told from a very fast one: it blurs with the longest streak for that frame.
- **Both on.** `dof-down`, `dof-gather`, `dof-composite` (into a scratch image of the camera's size), `motion-blur` (reads the scratch,
  writes the picture). Each alone ends with a copy (`dof-copy`, `motion-copy`): a pass cannot read the image it writes.
- **Cost.** The prepass, a scratch image of the camera's size and, for the depth of field, two half-size `RGBA16F` images. If the GPU
  cannot make them the effects are skipped for that size, and the log says so once.

### Colour grading with a LUT

`colorGradingLut` is the project path of a `.cube` file (the 3D lookup table that DaVinci Resolve, Photoshop and most grading
tools export). `assets.import` takes a `.cube` into `assets/luts/`; the importer parses it, reports its size and title, and refuses
a file the renderer could not use, with the line number (a 1D table, a size outside 2 to 65, a domain other than 0 to 1, a wrong
row count). A table of any size from 2 to 65 is used as it is (16, 32 and 64 are the usual ones). It is stored as an 8-bit strip
texture (the slices of blue tiled side by side) and sampled with a manual trilinear blend, so the result does not depend on the
backend. The LUT adds `(lut(x) - x) * colorGradingLutContribution` to the graded colour, where `x` is the colour looked up
(clamped to 0..1), so a contribution of 0.5 is half of it and a value above 1 keeps its excess. A path that does not resolve is
skipped (the rest of the stack is drawn). The LUT is applied last, in display space: use one exported for sRGB.

Cost (a 1280x720 frame, counted by `render.frame_graph`; the extra render targets are RGBA16F where the GPU draws in float, 8 bytes a
pixel, else RGBA8):

| Setting | Extra full-screen passes | Extra memory |
|---|---|---|
| no `PostProcess` | 0 | 0 |
| `colorFilterEnabled` alone | 1 | one full-size target |
| manual `exposureEnabled` and/or `tonemapEnabled` | 1 (`post`; the HUD draws as before, into another target) | one full-size target, and with a HUD a second one with a depth buffer |
| `exposureMode` auto | 2 more (32x32 and 1x1) | a few KB |
| `bloomEnabled`, `bloomRadius` 20 | 4 (`bloom-bright`, two blurs, `bloom-composite`) | two 320x180 targets, 0.9 MB |
| `bloomEnabled`, `bloomRadius` 64 | 6 | four smaller targets, 0.6 MB |
| colour grading, vignette, chromatic aberration, lens distortion, sharpen, pixelate, posterize or film grain, alone or together | 1 (`post`; sharpen reads four more texels, the LUT one table lookup, pixelate none) | one full-size target |
| `outlineEnabled`, depth mode | 1 (`post`, reads 4 texels of the prepass) + `prepass` | one full-size target and the prepass image (16 bytes a pixel) |
| `outlineEnabled`, sprite mode | 1 (`post`, up to 17 texels of the coverage) + `sprite-coverage` (the 2D batches again) | one full-size target and one RGBA8 image (4 bytes a pixel) |
| everything on, with a HUD | 8 (`color-filter` is its own pass because the HUD went between) | the sum of the above |

The time of each pass is in `render.frame_graph` with `profileFrames` (`passTimes[].gpuMs` on D3D11 and OpenGL, `cpuMs` of the
recording everywhere; Metal has no GPU timer in sokol_gfx, so `gpuMs` is -1 there). A full-screen pass reads one texture and
writes one: on a GPU its cost is the fill rate of the frame, and bloom's chain runs at a quarter of the pixels or less.

Where to see what the effects cost: `render.frame_graph` has a `postProcess` object with the post-processing passes (`bloom-*`,
`exposure-*`, `post`...) and their summed `cpuMs` and `gpuMs`; the GPU time is `null` with `gpuStatus` `"unavailable"` and a reason where
the backend has no timer (never 0), and the editor's Profiler panel shows the same in its "Post-processing" tab. The effects that share
the single `post` pass are not timed one by one (no per-effect estimate): `post` is their total
([PERFORMANCE_PROFILING.md](performance/PERFORMANCE_PROFILING.md)).

Things to know:
- **Linear scenes.** `SceneSettings.colorSpace` `linear` with nothing that converts the picture (no exposure, tonemap or colour filter)
  adds no pass: the copy to the screen encodes it, as in "Color space". With any of them the `post` pass reads the linear light, converts
  it and encodes it once (the screen copy then only copies), and the HUD is drawn after it in display colours.
- **The HUD is not exposed.** A game that wants its HUD to follow the exposure draws it into the world instead. The colour filter
  does cover it (it is the player's setting).
- **`bloomScreenSpace`.** With `post` in the frame the HUD is drawn after it, so it never glows whatever the field says; without
  `post` the field works as before.
- **Lens dirt.** `bloomLensDirt` is a texture (stretched over the screen) that multiplies the glow by `1 + dirt * bloomLensDirtIntensity`.
- A camera that draws into a texture (`renderTarget`) never has a stack: the effects are for the picture the player sees.

### Reading and changing the stack: commands, looks and the editor panel

- `postprocess.get {"id": "camera", "resolved": true}` answers with the stack the camera draws, computed on the CPU (it works without a
  window): `layers` (the camera's own PostProcess or the deprecated `Camera.bloom*` fields, then each volume the camera is inside, with
  its priority, weight and influence) and `effects`, every effect in the order it runs with `enabled` and, for each parameter of an
  effect that runs, `{value, from, strength}`. `from` is `own`, `legacy`, `volume:<entity id>` or `default`, so "why is the picture
  this dark" has an answer: the field that sets it and the entity that owns it. Without `resolved` it reads the component's own fields.
- `postprocess.set {"id", "fields"}` writes fields of a PostProcess (added when the entity has none: on a Camera entity it is the
  camera's own stack, on an entity without a Camera a volume) and `postprocess.presets` lists the looks. `postprocess.apply_preset
  {"id", "preset"}` applies one: without `"keep": true` the look replaces every effect of the target with exactly its own (the
  volume's shape, size and priority stay), with it only the effects the look names change. The looks are data, not code
  (`engine/runtime/data/postprocess_presets.json`): `neutral` (everything off, the way back), `cinematic`, `retro`, `noir`, `dreamy`,
  `vivid` and `horror`, built only from fields that exist. A look that names an effect this renderer does not draw
  (`render.supports` says `false` with the reason: a GPU without float targets or without the depth prepass, say) still
  applies, and the answer says so: `notDrawn` lists them and `note` explains that their fields are stored and show where
  the renderer can draw them. `drawnChecked` is false when there is no renderer to ask
  (`graphics=false`).
- **View > Post-processing** (docs/EDITOR.md) is the same stack on screen: a camera chooser, each effect in the order it runs with its
  switch, a "running" or "off" mark, whether this renderer draws it (`unsupported` with the reason on hover), its fields
  with the source of each value, one button per look and a **Stack off (A/B)** check that draws the game without any post-processing
  to compare (`Renderer::set_post_bypass`: it changes no data and ends when the panel closes, collapses or is hidden behind another tab; while it is on, every capture of the game shows the picture without the stack too). Every edit goes through
  `postprocess.set` or `postprocess.apply_preset`, one undo step each, to the camera's own PostProcess or to the volume picked under
  "Edit"; an effect this renderer does not draw (unsupported on this GPU) cannot be switched on from the panel (a look that switched it on can be switched off).

## Transient screen effects

Shockwave, heat haze, radial blur pulse, flash and fade: five short effects of the camera that the `post` pass draws over the
finished picture, started by `camera.shockwave(opts)` and its four siblings or by the `feel.*` commands, on the game clock. They
have a page of their own: [Transient screen effects](rendering/RENDERING_SCREEN_EFFECTS.md).

## Depth and normals

The effects that need to know how far away something is or which way it faces (ambient occlusion, reflections, fog, sun shafts,
depth of field, motion blur, outline) read a **prepass**: the opaque meshes of the camera drawn once more, before the main pass, into
one floating-point image of their own (`RGBA32F`, else `RGBA16F`), never multisampled (a multisampled game picture keeps its samples; the prepass has one per pixel). Each
pixel holds the distance along the camera's view axis in world units (`60000` where nothing was drawn), the view-space normal
(an octahedral encoding in two channels) and 1 where a mesh is (0 elsewhere). It is the same distance for a perspective and an
orthographic 3D camera.

- **When it is made.** For each camera whose post stack has an effect that reads the
  depth or the normals and that the renderer draws, when that camera draws opaque meshes (a camera of a split screen has its own, the
  size of its rectangle). A frame without such an effect declares no
  prepass pass, makes no image and builds no shader: the draw calls are the same as before. Of the effects that read the depth the
  outline (depth mode), the ambient occlusion, the reflections, the depth of field and the motion blur are drawn so far; the rest are drawn as their M71 packages land, and the debug view below makes the image too.
- **What is in it.** Opaque meshes, skinned ones at their pose, with their material's `vertex()` displacement, the normals of their material's `surface()` and, for `alphaMode`
  `"clip"`, the same holes as the main pass. Not in it: blended meshes, the sky, sprites, particles, shapes, text, debug lines
  and the HUD. A custom material gets its own prepass programs when
  it is compiled, like its shadow programs.
- **Where it is not made.** A camera that draws into a texture (`renderTarget`), a `CameraView`, a GPU that cannot render and
  sample a float image (`render.supports` says `sampledDepth` is not available, and the effects that need it are skipped).
- **Cost.** One more draw of every opaque batch, vertex work only plus the fragment work of a depth and normal write, and 16 bytes a
  pixel of memory at `RGBA32F` (8 at `RGBA16F`), returned to the pool when the frame ends.
- **Seeing it.** The command `render.debug_view {"view":"depth"}` (or `"normals"`, `"none"` to go back; without `view` it
  reports the current one) paints the prepass over the 3D picture of the frame, so `game.step` then `game.screenshot` shows what the
  depth-based effects read: depth as a grey, `10 / (10 + distance)` (white next to the camera), normals as the view-space direction
  mapped to colours (`x`, `y`, `z` as red, green, blue: a surface that faces the camera is blue), black where no opaque mesh was
  drawn. `"ao"` paints the ambient occlusion instead (see [Screen-space effects](rendering/RENDERING_EFFECTS.md)). `FA_RENDER_DEBUG_VIEW=depth`, `normals` or `ao` in the environment sets the first view at start (C++: `Renderer::set_debug_view`).
  It is a way to check a scene, not an effect: it is not saved and a game does not set it. `game.screenshot` has no
  argument for it: set the view, step a frame, take the shot.
- **What the image holds.** `r` is the depth, clamped to 60000 (the far value) so a half-float fallback never stores infinity;
  `a` is 1 where an opaque mesh was drawn and 0 elsewhere, and is the truth about coverage, not `r` (a surface at 60000 or more has
  `r` = 60000 too). A custom material whose shader was made before the prepass has no prepass programs: it is left out of the
  image, and the renderer logs one warning at load that says so (make the shader again).

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

## HDR output

A display that can show more than white (an HDR monitor or TV on Windows, a Mac or iPhone screen with extended dynamic range)
is used when the scene asks for it: `SceneSettings.hdrOutput` `"auto"` (the default is `"off"`). Each frame the engine asks
the display the window is on and switches the window's swapchain to an HDR format, or back to the standard range, before the
frame is shown, so moving the window to another monitor or switching HDR in the OS settings takes effect on the next frame.

| Platform | What it needs | What the swapchain becomes |
|---|---|---|
| macOS, iOS 16+ (Metal) | A screen with EDR headroom (`NSScreen.maximumPotentialExtendedDynamicRangeColorComponentValue` above 1: XDR and recent built-in displays, HDR monitors with "High Dynamic Range" on) | `RGBA16Float` with `wantsExtendedDynamicRangeContent`, extended LINEAR sRGB colour space (encoding `edr`) |
| Windows 10+ (D3D11) | Settings > System > Display > **Use HDR** on for that monitor | `R16G16B16A16_FLOAT` in scRGB (encoding `scRGB`), or `R10G10B10A2` in HDR10 (ST 2084 PQ, Rec.2020; encoding `hdr10`) where the driver refuses scRGB (never with multisampling: the 10-bit swapchain has no multisampled image, so such a window stays in the standard range) |
| Linux, Android, the web (OpenGL, GLES3, WebGL2), headless runs | — | Always the standard range: these backends have no HDR swapchain, and `render.supports {"feature":"hdrOutput"}` says why |

The editor's window never switches (it shows the game in its own view, in the standard range).

### What goes above white

Only the final pass of the post-processing stack decides what is brighter than paper white: a camera with a `PostProcess` whose
exposure or tonemap is on (the colour grading, vignette, lens, sharpen and grain effects run in that pass too, in display space, but
alone they do not make the picture go above white). On an HDR output its tonemap does not stop at 1:

- Below the curve's shoulder (display value 0.76 for `neutral`, 0.5 for the others) the picture is the SDR curve, so mid tones,
  shadows and skin look the same as on an SDR screen.
- Above it, the brightest channel rolls off toward the output's headroom H (how many times paper white the display can go,
  `render.output`'s `headroom`) instead of toward 1, with `start + (H - start) x / (1 + x)`, x = slope (c - input) / (H - start),
  which meets the SDR curve with the same value and slope; the colour keeps the SDR curve's ratios between its channels.
  Between H = 1 and 2 the curve is mixed with the SDR one, so a headroom that follows the screen's brightness (EDR) never jumps.
- `tonemapMode` `none` clips at the headroom instead of at 1.

What stays at paper white whatever the display: the HUD and the screen-space UI (drawn after the final pass, at 1.0), a camera
without the final pass (no exposure or tonemap: nothing decides how to map the light above white, so it is clipped there as on an
SDR screen), a frame with a colour filter (it works on what an SDR screen shows), and a GPU that draws the picture in 8 bits
(`render.supports {"feature":"floatTargets"}` false). `render.output`'s `status` says so while the HDR swapchain is on and the
picture stays within paper white. Screenshots, `render.captureTexture` and the editor's view are 8-bit: they show the picture
clipped at paper white. That is not the SDR look: in a window on an HDR display the frame is drawn with the HDR tonemap (its
highlights rolling off toward the headroom) and the 8-bit copy then cuts everything above 1, so the brightest areas of a screenshot
are flatter than on the screen, and than the same frame on an SDR screen. A run without a window (`factoria call`, tests) draws in the standard range with the SDR tonemap, so its screenshots are the reference for how
the game looks on an SDR display. The editor's viewport clamps the same way, with an 8-bit copy of the picture when it went above
white.

The present pass encodes the picture for the swapchain:

| Encoding | Swapchain | What 1.0 (paper white) is written as |
|---|---|---|
| `sdr` | 8-bit sRGB | 1.0, everything above clipped |
| `edr` | `RGBA16Float`, extended linear sRGB | 1.0, the screen's white; values up to the current EDR headroom |
| `scRGB` | `R16G16B16A16_FLOAT`, linear Rec.709 with 1.0 = 80 nits | `paperWhiteNits / 80` (2.5 at 200 nits) |
| `hdr10` | `R10G10B10A2`, Rec.2020 primaries, ST 2084 (PQ) | the PQ signal of `paperWhiteNits` (0.58 at 200 nits) |

`SceneSettings.paperWhiteNits` (80 to 1000, default 200) is how bright white (1.0) is on an HDR display, in nits: in scRGB and
HDR10 the picture's white is placed there, and the tonemap's highlights go up to the display's peak (headroom = peak nits /
paper white). On Apple screens the system sets white itself (EDR 1.0 is the screen's current white), so paper white only
matters on Windows.

Check what the window shows with `render.output`:

```bash
factoria call --project games/my-game render.output '{}'
```

It answers `{hdrActive, encoding, swapchainFormat, requested, paperWhiteNits, maxNits, headroom, status, display}`: `encoding`
is `sdr`, `edr`, `scRGB` or `hdr10`; `headroom` is how many times brighter than white the output can go now (the screen's
current EDR headroom on Apple, peak nits / paper white on Windows); `status` is one sentence that says what is shown or why the
window stays in the standard range (hdrOutput off, Windows' HDR switch off, a screen without EDR, the platform). A `factoria call`
run is headless, so it always answers `sdr` with "there is no window". In a window, the game's log prints one `HDR output: ...`
line at the `info` level when the encoding changes, with the display's name and EDR headroom (`factoria run --log-level info`).
`render.supports {"feature":"hdrOutput"}` says whether the display the window showed its last frame on could show HDR, whatever
the scene asks.
