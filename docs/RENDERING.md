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
  entity that shows the target out of that camera's view (there is no culling mask, see below).
- **A loop** (A shows B and B shows A, a mirror facing a mirror) is allowed: the one that draws first shows the other's picture
  from the previous frame, so the loop is one frame late and never an error.

### A page of a book: world-space entities

A target camera does not draw screen-space UI (`Panel`, `Button` and the other widgets, and any item with `space: "screen"`):
those belong to the screen. What a page is made of are ordinary world-space entities: `Sprite`, `Text`, `Shape2D`, children of
one `Transform` that you move away from everything else. Give them `Interactable` components and they become widgets: hover,
click, toggles, sliders, focus.

There is no culling mask. The page camera sees whatever is in its frustum, and the camera that draws the model sees the page too if
the page is in front of it. Put the page where the main camera never looks (the example above uses x = 5000), or far along the
axis the main camera does not see. A page you want to see both ways, in the world and on the model, is two sets of entities.

### Pointer input through the mesh

A pointer over a mesh that shows `"target:<name>"` reaches the `Interactable`s that camera sees, at the point of the picture
under the pointer. The engine finds that point from the hit triangle's UV, so it works on a flat `quad`, on a curved model (a
cylinder, a bent screen, a sphere), on a glTF model or on a procedural mesh (`mesh.create`, docs/SCRIPTING.md), with `uvScale` taken
into account. A procedural mesh is hit-tested against its CURRENT triangles and uvs: a page you bend with `mesh.update` every frame
answers where it is drawn, and a mesh that did not change is not rebuilt (the triangles are cached per mesh version). Only the triangles
inside a submesh count, the ones the mesh draws:

```js
import { game, camera } from "factoria";
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
- `game.click(id)` of an entity of the page aims at where the main view would draw that entity, not at the model. In a test pass
  the screen position: `game.click(camera.worldToScreen(modelPoint))`, or `game.mouseMove(pos)` then `game.click(pos)`.

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
