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

This page has the render targets, the depth and normals prepass, capture and HDR output. The rest is on fourteen pages (`docs.read rendering-postprocess`, `docs.read rendering-2d-shadows`, `rendering-2d-emission`, `rendering-2d-gi`, `rendering-2d-water`, `rendering-effects`, `rendering-passes`, `rendering-screen-effects`, `rendering-lighting`, `rendering-lightmaps`, `rendering-decals-fog`, `rendering-probes`, `rendering-light-probes`, `rendering-transmission`):

- 2D global illumination (`GlobalIllumination2D`, M74): a player can switch it Off, Low, Medium or High from the Graphics tab of the menu kit's options (the "2D lighting" button writes `enabled` and `quality` of every `GlobalIllumination2D` of the scene and of scenes loaded later, docs/MENUS.md); where `render.supports` says `2dGlobalIllumination` is not available the scene is drawn without it whatever the setting.
- [2D emission and light masks (M74.2)](rendering/RENDERING_2D_EMISSION.md): `Sprite.emissive` and the bloom, `lightLayers`, `Light2D.cookie`, the rim light and the normal maps generated from a sprite.
- [2D global illumination (M74.3)](rendering/RENDERING_2D_GI.md): `GlobalIllumination2D`, radiance cascades, `quality`, the cost in passes and memory, who receives the light, and when it is off.
- [Screen-space effects](rendering/RENDERING_EFFECTS.md): ambient occlusion and its cost, screen-space reflections, and the outline (both modes, where it is skipped).
- [The passes of a frame](rendering/RENDERING_PASSES.md): every pass of the post-processing stack, when it runs and what it draws.
- [Soft 2D shadows and shadow casters (M74.1)](rendering/RENDERING_2D_SHADOWS.md): `ShadowCaster2D` (box, polygon, sprite alpha), `Light2D.size` penumbra, light layers, up to 256 shadowed lights, the caches, caps and costs.
- [Lighting (M73)](rendering/RENDERING_LIGHTING.md): the Light, scene and material fields of the M73 lighting, which of them draw yet, and the `render.supports` rows.
- [Lightmaps and baked light (M73.4)](rendering/RENDERING_LIGHTMAPS.md): baked lightmaps, the bake commands, light probes and mixed lights.
- [Decals and volumetric fog (M73.5)](rendering/RENDERING_DECALS_FOG.md): `Decal` projection, volumetric fog and light shafts.
- [Reflection probes (M73)](rendering/RENDERING_PROBES.md): the `ReflectionProbe` component, realtime and baked captures, `probe.bake`, `render.probes`, the atlas and its limits.
- [Light probes and mixed lights](rendering/RENDERING_LIGHT_PROBES.md): `LightProbeGroup`, how the bake stores light for moving objects, what receives it, and what a light of each mode does to each receiver.
- [Transmission, volume and the material cost](rendering/RENDERING_TRANSMISSION.md): glass and liquids (`transmission`, `thickness`, `attenuationColor`, `attenuationDistance`), what the refraction costs, and the `render.material_cost` view.
- [2D water, distortion and the scene colour (M74.4)](rendering/RENDERING_2D_WATER.md): `Water2D`, `DistortionZone2D`, `fa_scene_color` in sprite materials, the copy of the picture and its cap.
- [The post-processing stack](rendering/RENDERING_POSTPROCESS.md): bloom, exposure, tonemap, colour grading, lens effects, colour filter, the LUT, and the commands, looks and panel that read and change the stack.
- [Frame generation (M78)](FRAME_GENERATION.md): `render.frameGeneration`, a vendor SDK's generated frames between two rendered ones (the seam and the AMD FSR 3 provider; DLSS and XeSS land in their own packages), the `minBaseFps` rule and the readout.
- [Ray tracing (M79)](RAY_TRACING.md): `render.rayTracing` and `render.ray_tracing`, the `raytracing` rows of `render.supports` per backend, and the effects traced with rays: shadows, ambient occlusion, reflections, translucency, global illumination and the path tracer.
- [Low latency (M78)](LATENCY.md): `render.latency`, the sleep before the input is read (AMD Anti-Lag 2, Intel XeLL, the engine's own pacing) and the input-to-present readout.
- [Upscaling and temporal antialiasing (M76)](UPSCALING.md): `render.upscaler`, `window.upscaler`, the `TemporalAA` effect, the spatial, temporal, MetalFX and vendor (DLSS, XeSS, FSR) upscalers, the dynamic resolution, the motion vectors and the graphics presets.
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
  (half the memory of RGBA16F, no alpha: the picture's own alpha is not used by the screen, but a CameraView, a render target or a world capture
  (`render.captureTexture` of an area) drawn in it has an opaque background, with one warning in the log), else `SRGB8A8` (8 bits that hold linear light: the GPU encodes what is written and
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
viewport shows what the game shows: after the final pass the picture itself, otherwise the renderer keeps an 8-bit encoded copy of the finished frame for it (`Renderer::set_editor_view`, made only while the scene is linear and freed when it goes back to gamma; a game never makes it). The mips of a texture made as sRGB are averaged in linear light (an exported `.ktx2` twin keeps the
mips of the export, averaged on the sRGB values). A custom material ([SHADERS.md](SHADERS.md)) gets what the GPU gives for its own textures (linear light
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

## Transient screen effects

Shockwave, heat haze, radial blur pulse, flash and fade: five short effects of the camera that the `post` pass draws over the
finished picture, started by `camera.shockwave(opts)` and its four siblings or by the `feel.*` commands, on the game clock. They
have a page of their own: [Transient screen effects](rendering/RENDERING_SCREEN_EFFECTS.md).

## Choosing the GPU backend

`"render": {"backend": "vulkan"}` in `factoria.json` asks for a GPU backend. The values are `"auto"` (the default), `"d3d11"`,
`"d3d12"`, `"vulkan"`, `"metal"`, `"gl"`, `"gles3"` and `"webgl2"`. A name that is none of them fails the load with the pointer
`/render/backend`, the valid names and a "did you mean".

- `"auto"` is the backend this build of the engine uses today: the sokol one it was built with (OpenGL on Linux, Direct3D 11 on
  Windows, Metal on Apple, OpenGL ES 3 on Android, WebGL 2 on the web). Later M77 work makes `auto` pick the best backend of the machine.
- A name this platform or binary cannot have (Metal on Windows, `d3d12` off Windows, `vulkan` in a build without `FA_RENDER_VULKAN`, which the OpenGL players of Linux and Android and the macOS player leave out (the Vulkan player of Linux and Android has it, below), or
  another sokol backend than the one built) starts the game with one warning that says which backends the binary has, and uses `auto`.
- The order at start: `EngineConfig::gpuBackend`, then the environment variable `FA_GPU_BACKEND` (same names, for tests and for players
  that tools run), then the player's own stored choice (`graphics.backend`, below), then `factoria.json`, then `auto`. A wrong name in the
  variable fails the start with the same teaching error; a stored choice that is not valid any more is a startup warning and is ignored.
- `d3d12` and `vulkan` draw into the game window with a swapchain of their own (M77-P9e1): the engine takes the window's native
  handle from the platform, which then makes no swapchain of its own (a window holds one). On Windows that is the player itself
  (it carries Direct3D 11, Direct3D 12 and Vulkan); on macOS `vulkan` presents through MoltenVK in a build that has it; on Linux
  `vulkan` takes the X11 window from OpenGL, which waits off screen and draws there again if Vulkan fails to start, and on
  Android it takes the window from OpenGL ES the same way. A headless run
  (`factoria call`, `factoria test`, the MCP server, tests) draws offscreen on the one asked for. The editor draws the game into
  its own view with the `auto` backend.
- When the backend asked for cannot start (no driver, no such GPU, a window that cannot take its swapchain), the engine falls back
  to `auto` **in the same process**, in a window and headless alike: one warning keeps the first error whole, says what draws instead
  and how to stop asking (set `"auto"`). Only `auto` failing as well leaves the run without graphics (a warning says so: no renders
  or captures). HDR output is not available while D3D12 or Vulkan draws the window (`hdrOutput` says why), and the window's vsync
  is the swapchain's present mode, set when it starts. In the Vulkan player of Linux and Android, below, another player gets the
  failure first.
- The startup report (`Engine::startup_report`, the `gpu` entry of `perf.measure`'s `startup`, and the player's "startup:" log line) has two
  separate kinds of fallback, which can both be present:
  - **In this process** (`requestedBackend`, `backendFallback`): `backend` is the backend of the renderer's device, `requestedBackend`
    the one asked for when they differ (in the Vulkan player, `auto` is Vulkan) and `backendFallback` the first error of the one asked for.
  - **Another process** (`fallbackFrom`, `fallbackReason`): this player was started because the Vulkan player (`fallbackFrom`
    `vulkan`) could not draw the game, and `fallbackReason` says why. It exists only in the OpenGL player of Linux and Android.

### Two players on Linux and Android

The OpenGL player keeps no Vulkan backend and no SPIR-V (it stays small), so the player comes in two variants:
`factoria_player` (`libfactoria_player.so` on Android), the OpenGL one, and `factoria_player_vulkan` (`libfactoria_player_vulkan.so`),
the same player whose renderer also has the engine's Vulkan backend and the SPIR-V of the built-in shaders. An export ships both
(`export.linux.vulkanPlayer` and `export.android.vulkanPlayer`, on by default; `false` ships only the OpenGL player:
[platform settings](exporting/EXPORTING_SETUP.md#exportplatform)).

- **What starts, in order.** The Vulkan player starts first, and its `auto` is Vulkan. (1) Before it opens a window it reads the choice
  in the order above and, when the choice is Vulkan, checks that a Vulkan instance and device can be made. When the choice is `gl` or
  `gles3` it runs the OpenGL player directly; when Vulkan cannot start it runs the OpenGL player with the environment variables
  `FA_GPU_FALLBACK_FROM=vulkan` and `FA_GPU_FALLBACK_REASON=<why>` (Android: the same two as intent extras). (2) Linux: in the window, a
  Vulkan start that fails (no surface, no swapchain, or a window that cannot take one) is reported to the player
  (`EngineConfig::gpuBackendFailed`) **before** the in-process fallback below, and the player runs the OpenGL player in the same way.
  (3) Only when the OpenGL player is not there, or cannot be started, does the Vulkan player draw with its own sokol (OpenGL) backend
  in this process, with the in-process warning and `backendFallback` of the section above. So on Linux a Vulkan failure always reaches the OpenGL
  player when it exists, and the in-process fallback is the last resort. The OpenGL player records the marker as `fallbackFrom` and
  `fallbackReason` in the startup report and in `graphics.backend`, and never starts another player; a player that carries the marker
  never hands over either, so there is no loop. A check run (`--input`, `--dump-state`, `--screenshot`) in `auto` runs the OpenGL
  player, so its state and pixels match `factoria run --headless` byte for byte; `FA_GPU_BACKEND=vulkan` checks the Vulkan path.
- **Linux.** The exported game's `<exe>` is the Vulkan player and `<exe>-gl` the OpenGL one, in the same folder (in a build tree:
  `player/factoria_player_vulkan` and `player/factoria_player`). The Vulkan player replaces its own process with `<exe>-gl` (`execv`,
  same arguments and environment). Without `<exe>-gl` next to it, or when that fails, it warns and draws with its own sokol (OpenGL)
  backend.
- **Android.** The launcher activity loads `libfactoria_player_vulkan.so`. To hand over it starts `factoria.engine.GlActivity`, which
  loads `libfactoria_player.so` in its own process (`:gl`), and finishes itself. That happens only before the window (step 1): a
  Vulkan start that fails in the window (no surface, no swapchain) draws with the player's own OpenGL ES 3 backend in the same
  process, since the window's OpenGL ES surface is back on it by then (below). Back from Home after a hand-over, Android starts a
  new launcher activity on top of `GlActivity` (both are `singleTask`); it sees `GlActivity` at the root of its task and brings it
  back at once, without probing Vulkan again.
- **In the window.** On Linux (M77-P9e3a) and Android (M77-P9e3b) the Vulkan player draws the game window with Vulkan: the OpenGL
  context sokol_app made with the window moves to a 1x1 pbuffer (or to no surface at all where the driver offers no pbuffer), its
  window surface goes and its swap does nothing, so the Vulkan swapchain is the window's only one; when Vulkan lets the window go
  (a start that fails after it took the window, the end of the game), the OpenGL surface comes back on it. On Android the window
  goes when the game goes to the background and a new one comes when it returns: the Vulkan swapchain is destroyed before the old
  window goes and made on the new one at the next frame. A window that cannot take a Vulkan swapchain at all (only a Linux build
  whose window draws through EGL) gives the reason `the window path is not available on this platform yet (...)`, and the warning of
  the OpenGL player then says that the window cannot take the backend, not that a driver or an install would bring Vulkan back (it
  says that only for a Vulkan that cannot start). The probe before the window is separate: a machine with no Vulkan driver hands
  over before any window opens.

### `graphics.backend`

The game's own setting of the backend, for an options menu or a tool: `graphics.backend {}` reads what draws (`active`, `sokolBackend`),
what was asked and from where (`requested`, `source`), what `auto` draws with in this player, the backends this player has
(`available`), the `fallback` that started it (`{from, reason}` or null) and the stored choice (`stored`, `storedIn`).
`graphics.backend {"name": "gl"}` stores the choice for the next start in `graphics_backend.json` in the game's save folder (in memory in
a run with in-memory storage) and returns `changed` and `takesEffect: "next start"`; the backend in use does not change. `"auto"`
forgets it. On Linux and Android the OpenGL player may store `vulkan` too: the Vulkan player reads it at the next start. A name this
platform cannot have is an `invalid_argument` error, and nothing is written.

### Async compute and multi-thread recording

On `d3d12` and `vulkan` the renderer records the shadow cascades and the spot and point light shadows on job threads (up
to four command lists, submitted in a fixed order), and runs the depth pyramid of GPU occlusion culling
(`SceneSettings.occlusionMode` `gpu` or `auto`) on the GPU's compute queue next to the drawing, where the device has a
compute queue of its own. Both are on by default and change nothing in the picture: the same draws in the same order,
the same pixels. Turn either off to compare timings or to rule out a driver problem:

```json
"render": { "asyncCompute": false, "multiThreadRecording": false }
```

A value that is not `true` or `false` fails the load with `/render/asyncCompute` (or `/render/multiThreadRecording`). The
other backends ignore both. The startup report has `asyncCompute` and `multiThreadRecording`: whether each is in use on
this device (false where the backend or the GPU has no such feature, or the setting is off).

## Temporal effects and upscaling at a glance (M76)

What each M76 feature is switched on with, which GPU backends draw it and what it costs. The contract of every setting is
[UPSCALING.md](UPSCALING.md); `render.supports {"feature": "<row>"}` says what this build and GPU draw, with the reason when not.

| Feature | Switched on with | `render.supports` row | Backends | Cost |
|---|---|---|---|---|
| Velocity image (motion vectors) | nothing: the depth prepass writes it when something reads it (temporal effects, `motionBlurMode` `object`, `render.debug_view {"view":"motionVectors"}`) | `motionVectors` | every GPU backend with RGBA16F render targets (`half`) | a second attachment (RG16F) of the prepass, 4 bytes a pixel, plus the sprites' own passes (`quad-velocity`, `quad-reactive`) in a 2D game |
| Thin G-buffer (albedo and material images) | nothing: drawn only when something reads it (DLSS Ray Reconstruction's guides, `render.debug_view {"view":"albedo"}` or `"material"`) | none (RGBA8 targets with two attachments, which every backend has) | every GPU backend | two RGBA8 images at the render size and one more draw of the opaque meshes after the prepass (the engine's design notes, repository only, not in the binary); nothing when off |
| Temporal antialiasing | `PostProcess.temporalAAEnabled` | `temporalAA` | every GPU backend | two fragment passes at the render size, one RGBA16F history (RGBA8 without half-float targets) per camera, and the depth prepass |
| Per-object motion blur | `PostProcess.motionBlurEnabled`, `motionBlurMode` `object` (the default) | `motionBlur` | every GPU that samples the depth; the `object` mode also needs an RG16F target, else the camera mode | the velocity image and 3 more passes than the `camera` mode |
| Spatial upscaler | `render.upscaler` mode `spatial` | `spatialUpscaler` | every GPU backend | two fragment passes at the window size |
| Temporal upscaler | `render.upscaler` mode `temporal` | `temporalUpscaler` | every GPU backend; one camera over the whole window, else it draws `spatial` | one history at the window size, two passes, the depth prepass |
| MetalFX | `render.upscaler` mode `metalfx` | `metalfx` | Metal only (macOS 13 or iOS 16 or later, a GPU with the MetalFX scalers, not the iOS simulator) | one more command buffer a frame; falls back to `temporal`, then `spatial` |
| DLSS, XeSS, FSR 3.1 (M78) | `render.upscaler` mode `dlss`, `xess`, `fsr` (`auto` picks the GPU maker's own) | `dlss`, `xess`, `fsr` | Windows only: D3D12, Vulkan (and D3D11 for XeSS, not for DLSS or FSR); `dlss` needs an NVIDIA RTX GPU; the SDK installed with `factoria setup streamline`, `xess` or `fidelityfx` | one history in the SDK, the depth prepass and velocity; one jittered camera, else `spatial`; fall back to `metalfx`, `temporal`, then `spatial` with the reason in `render.supports` |
| Dynamic resolution | `render.dynamic_resolution`, `window.dynamicResolution`, `render.dynamicResolution` in `factoria.json` | `dynamicResolution` | every GPU backend (GPU time where there are timer queries: Direct3D 11 and OpenGL; elsewhere the time between frames) | none of its own; the targets are made again at a step of the scale (at most twice a second) |
| Graphics presets | `graphics.preset`, `game.graphics`, `render.graphicsPreset` | none (limits on other rows) | every backend; a knob for a feature the GPU cannot draw is capped | none: it only lowers what the scene asks for |

Where a row says `false`, the mode that needs it draws as the next best one (`auto`, `dlss`, `xess`, `fsr`, `metalfx`, `temporal`, `spatial`, `stretch`) and `window.upscaler.effectiveMode`
tells which. A sprite, tile or glyph that moves writes its own velocity in a 2D game, and a particle or an additive sprite is marked in the reactive mask
(`ParticleEmitter.reactive`, `Sprite.reactive`) so it does not trail. The passes are in [The passes of a frame](rendering/RENDERING_PASSES.md).

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
  outline (depth mode), the ambient occlusion, the reflections, the fog, the sun shafts, the depth of field and the motion blur are drawn; one that has nothing to draw this frame (a depth of field with no blur, a motion blur in `camera` mode on a camera's first frame or after a cut (in the default `object` mode it asks from the first frame, for the velocity image), shafts with no sun in view) does not ask for it. The debug view below makes the image too.
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
  drawn. `"ao"` paints the ambient occlusion instead (see [Screen-space effects](rendering/RENDERING_EFFECTS.md)). `"cascades"` tints the lit meshes by the cascade of the sun's shadow that covers them (see [Lighting](rendering/RENDERING_LIGHTING.md)). `"albedo"` and `"material"` paint the thin G-buffer (the albedo of what the camera sees; the roughness as red and the metalness as green; black where no opaque mesh was drawn), which the renderer draws only while one of them is shown (or DLSS Ray Reconstruction reads it); a mesh with a custom or layered material shows its mesh renderer's own colour, roughness and metallic. `"motionVectors"` paints the motion of every pixel since the previous frame (hue = direction, brightness = length, black = still, grey = no object wrote a vector: the sky, a blended or additive particle or sprite, and a skinned mesh of more than 64 joints); it turns the velocity image on while it is shown. `FA_RENDER_DEBUG_VIEW=depth`, `normals`, `ao`, `cascades`, `motionVectors`, `albedo` or `material` in the environment sets the first view at start (C++: `Renderer::set_debug_view`).
  It is a way to check a scene, not an effect: it is not saved and a game does not set it. `game.screenshot` has no
  argument for it: set the view, step a frame, take the shot.
- **What the image holds.** `r` is the depth, clamped to 60000 (the far value) so a half-float fallback never stores infinity;
  `a` is 1 where an opaque mesh was drawn and 0 elsewhere, and is the truth about coverage, not `r` (a surface at 60000 or more has
  `r` = 60000 too). A custom material whose shader was made before the prepass has no prepass programs: it is left out of the
  image, and the renderer logs one warning at load that says so (make the shader again).
- **The velocity image (M76).** When a temporal effect, the per-object motion blur or the `motionVectors` debug view reads it, the prepass
  also writes a second attachment (`RG16F`, where each pixel was in the frame before, from unjittered matrices) where the GPU can render to
  `RG16F` (`render.supports` `motionVectors`); skinned meshes, material `vertex()` displacement, instances, terrain, foliage and impostors
  move their pixels, and in a 2D game the sprites' own passes write it. Without the attachment the temporal passes rebuild the camera's own motion from the depth. See [UPSCALING.md](UPSCALING.md).

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

- Below the curve's shoulder (display value 0.76 for `neutral`, which follows Khronos PBR Neutral above its shoulder without the black offset; 0.5 for the others) the picture is the SDR curve, so mid tones,
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
