Part of [RENDERING.md](../RENDERING.md): the 2D items that read the picture drawn so far, `Water2D` and `DistortionZone2D`, and the scene colour a sprite material can read.

# Rendering: 2D water, distortion and the scene colour (M74.4)

Three things share one mechanism: the renderer copies the picture the camera has drawn so far, and an item that draws later reads that copy.

| What | Draws | Fields |
|---|---|---|
| `Water2D` | refraction below a surface, a mirrored reflection of what is above it, a thin highlight | `size`, `tint`, `reflection`, `refraction`, `waveAmplitude`, `waveLength`, `waveSpeed`, `layer`, `material` |
| `DistortionZone2D` | a ripple of the picture inside a rectangle (heat haze, a shockwave, a portal) | `size`, `strength`, `layer`, `material` |
| a sprite material that calls `fa_scene_color(uv)` | whatever the snippet makes of the picture (frosted glass, a mirror, a lens) | the material's own params (docs/shaders/SHADERS_SPRITES.md, "The scene colour") |

Nothing is on by default. A frame without such an item copies nothing, allocates nothing and is drawn bit-for-bit as before: `render.stats` says
`sceneCopies: 0`. `render.supports` `{"feature":"2dWater"}` and `{"feature":"spriteSceneColor"}` are true on every backend (Metal, D3D11, OpenGL,
GLES3 and WebGL2).

## What the picture "so far" is

Items draw in layer order (`layer`, then creation order). `Water2D.layer` defaults to 10 and `DistortionZone2D.layer` to 20:

- everything on a **lower** layer is under the water and is seen refracted, tinted and reflected;
- everything on a **higher** layer is drawn over the water, untouched (a log floating on the surface, the player in front of a pool, the HUD);
- two items that read the picture follow each other when nothing else is drawn between them (water on layer 10, a haze zone on layer 20): they share
  one copy and do not see each other, so the zone does not bend the water. Put a sprite on a layer between them and the zone reads a new copy that has
  the water in it.

The picture is the camera's own rectangle of the game image, in the colour space the scene is drawn in (linear when `linearColor` is on). Where a read
falls outside the camera's rectangle the nearest edge pixel is read.

## Water2D

The area is `size` (world units) centred on the entity, scaled and rotated by its transform. **The top edge is the surface**; the water is the area below it
and the strip above the area is empty. Put the entity's `position.y` half a height under the surface you want.

| Field | Values | Default | What it does |
|---|---|---|---|
| `size` | world units | 256 x 128 | Width and depth of the water. A size of 0 draws nothing. |
| `tint` | colour, alpha 0..1 | (0.2, 0.5, 0.7, 0.5) | The colour of the body of water: `alpha` is how much of it replaces the picture below the surface. Deep water also darkens, up to 35 % at the bottom. |
| `reflection` | 0..1 | 0.5 | How much of the mirror image of what is above the surface is mixed in. It fades with depth (60 % less at the bottom) and where the mirrored point would be outside the camera's rectangle. |
| `refraction` | pixels, 0..256 | 4 | How far the waves push the picture below the surface about. 0 = no bending. |
| `waveAmplitude` | world units, 0..1000 | 2 | How high the surface moves (two sines, so the crests are not all alike). 0 = a flat surface. |
| `waveLength` | world units | 64 | Distance between two crests. |
| `waveSpeed` | waves per second | 1 | The speed of the waves along the surface. 0 freezes them. |
| `layer` | integer | 10 | Draw order: the water shows what was drawn before it. |
| `material` | `*.material.json` of kind `sprite` | "" | Replaces the built-in look, see below. |

The waves follow the engine clock (it stops when the game is paused and replays exactly), never the wall clock: the same frame number gives the
same picture on every machine and in a replay. Water is not shaded by `Light2D` (it shows the lit picture below it); put a `Light2D` over the pool and its
light is in the reflection, since the reflection is of the picture.

How a point is drawn, in order: below the moving surface, the picture offset by the waves (`refraction` pixels) and mixed with `tint`; the mirrored
picture mixed in by `reflection`; a thin bright line along the surface. Above the surface line nothing is drawn.

A reflection can only show what the camera has on screen: a lantern outside the top of the screen is not in the pool (the mirror image fades out where the
mirrored point leaves the screen instead of showing a smeared edge).

### Water2D.material

`material` is a sprite material (docs/shaders/SHADERS_SPRITES.md) that draws the area instead of the built-in look. Its `fragment()` may call
`fa_scene_color(uv)`. The area is one quad whose `uv` run from 0 to 1 across (u, left to right) and from 0 at the surface down to 1 at the bottom (v;
negative in the strip above the surface that holds the wave crests). Every field below that the material **declares as a param with the same name**
arrives as its value, the others are left out (no warning): `size` (vec2, world units), `tint` (color), `reflection`, `refraction`, `waveAmplitude`,
`waveLength`, `waveSpeed` (float). The scene's seconds are `i.time`. A material that does not exist or fails to compile draws the area magenta (the error
material of every sprite material) and `render.stats` lists it in `materialFallbacks`.

### DistortionZone2D.material

The same for a zone, with the params `size` (vec2) and `strength` (float); the quad's `uv` run 0..1 over the rectangle, v from the top.

## DistortionZone2D

A rectangle of `size` world units centred on the entity. Inside it the picture is read with a travelling ripple that bends by up to `strength` pixels;
the ripple fades out over the last 30 % towards the edge, so the zone has no visible border. `strength` 0 is the picture as it is. The ripple moves with
the engine clock. For a screen-wide effect use the camera's transient effects (`rendering-screen-effects`); the zone is for a place in the world.

## What it costs and the cap

- The renderer ends the camera's pass, copies the camera's rectangle into a pooled image the size of that rectangle, and goes on: the drawn pixels, the
  depth and the stencil are kept.
- **Items that read the picture one after the other share one copy** (water and a zone on neighbouring layers, a hundred sprites with the same
  frosted-glass material). Reading items with something that does not read in between each cost a copy of their own, because the picture changed.
- **At most 8 copies per camera and frame** (a count, never time). The reading items past the eighth run read the last copy and do not see what is
  drawn between; the log says so once per renderer: "A camera has N separate runs of 2D draws that read the picture drawn so far...". Give the items
  neighbouring layers so that they share a copy.
- `render.stats` has `sceneCopies` (copies made this frame).
- The copy is half-float or 8-bit like the scene itself; its memory is one image the size of the camera's rectangle, taken from and returned to the pool
  of transient images, and only while a reading item is drawn.

## Teaching degradations

- A shader that does not compile on the backend: one error in the log, and the items are not drawn (the rest of the frame is).
- A material of `Water2D` / `DistortionZone2D` that does not exist or has errors: the area is drawn magenta and `materialFallbacks` of `render.stats`
  names it.
- A sprite material that calls `fa_scene_color` drawn where no copy exists (a pass that is not the camera's main pass, for instance the one that makes
  the shadow coverage): `fa_scene_color` returns transparent black (alpha 0), so a snippet can detect it. The built-in water and zone are not drawn there.

## Example

`examples/lantern-keep/scenes/cellar_pool.scene.json` (if you got it with `project.create {example: "lantern-keep"}`; not the start scene: `factoria run --project examples/lantern-keep --scene scenes/cellar_pool.scene.json`)
has a cellar pool that reflects two emissive lanterns, a pillar with a `ShadowCaster2D` and a heat haze over a brazier.

```json
{ "id": "pool", "components": {
    "Transform": { "position": [640, 190, 0] },
    "Water2D": { "size": [760, 220], "tint": [0.08, 0.3, 0.42, 0.5], "reflection": 0.7, "refraction": 5, "waveAmplitude": 2.5, "waveLength": 70, "waveSpeed": 0.6 } } },
{ "id": "heat_haze", "components": {
    "Transform": { "position": [1100, 470, 0] },
    "DistortionZone2D": { "size": [130, 170], "strength": 3 } } }
```
