Part of [RENDERING.md](../RENDERING.md): the 2D global illumination of M74.3, drawn with radiance cascades.

# Rendering: 2D global illumination

Light that bounces: a red wall tints the floor beside it, a glowing sprite lights the room around it, a pillar between a lamp and the
floor leaves a soft shadow, all without baking. It is **off by default**: a scene without a `GlobalIllumination2D` component (or with
`enabled` false) draws the same pixels with the same draw calls as before, and makes no new memory for it (the renderer's pool of transient
targets keeps what the last frames used for a few frames, so a scene that turns the GI off gives its memory back a few frames later). `render.supports
{"feature": "2dGlobalIllumination"}` says whether this GPU and platform can draw it.

## Turn it on

Add one `GlobalIllumination2D` to any entity of the scene (the first enabled one counts):

| Field | What it does |
|---|---|
| `quality` | `low`, `medium` (default) or `high`: how many cascades, how far apart the probes are and how many rays and steps they take (the table below). Counts, the same on every machine. |
| `bounce` | 0..1. How much of the light that reached a blocker (last frame's irradiance) it throws back, times its colour. 0 = no bounce: only emitters light the scene. The engine uses at most 0.95, so the light of a closed room of bright walls stays bounded instead of growing every frame. |
| `intensity` | 0..16. Multiplies the light a lit visual receives. 0 = none. |
| `range` | World units around the view that the field covers. A lamp or a wall off screen but inside this margin still counts; farther away does not exist for the GI. Default 512. |
| `resolutionScale` | 0.1..1. Field texels per screen pixel (default 0.5: the field has half the screen's resolution). |

**Emitters** are the sprites and tilemaps with a non-black `emissive` (lit or not, as they look on screen: [2D emission](RENDERING_2D_EMISSION.md))
and every point `Light2D`, drawn as a small disc of its colour times its intensity. **Blockers** are the solid cells of a `Tilemap` with
`occludesLight` and every `ShadowCaster2D` (box, polygon, sprite alpha). The colour of a blocker is its albedo: a `ShadowCaster2D` on a
green `Sprite` bounces green light (the sprite's `color`), a solid tile its tilemap's colour, and a caster with no `Sprite` bounces
grey (0.5).

A scene lit by a `Light2D` keeps lighting its sprites as before; the GI adds the light that reaches them indirectly, and the `Light2D`'s
own disc is also an emitter. Lower `intensity` or `bounce` if a room gets too bright with both.

## What it does with them

1. **The field** (`render.gi2d_field`): per 2D camera, the emission and the blockers are drawn into images that cover the view plus `range`
   at `resolutionScale`, and jump flooding turns the blockers into a distance field (docs/design/ARCHITECTURE_RENDERING_GI2D.md, repository only, not in the binary).
   A second flood does the same for the emitters, so a ray can see a thin lamp it would step over.
2. **The cascades.** Cascade 0 has a probe every `probeSpacing` texels, each with `probeSpacing`^2 rays. Each cascade above it has probes
   twice as far apart and four times the rays per probe, and takes over the part of the ray that starts where the one below ends (the
   intervals 0..8, 8..40, 40..168 texels for low; 0..4, 4..20, 20..84, 84..340, 340..1364 for medium and high). A ray steps through
   the distance field (sphere tracing, at most `steps` steps) and ends where it touches a blocker or an emitter, or leaves the field.
   A ray that ends on an emitter returns its light; one that ends on a blocker returns `bounce` x its albedo x the irradiance it received
   last frame; one that hits nothing takes the average of the four rays of the cascade above it, read at the probe's position. The
   cascades are drawn from the top down, so every merge reads the finished one above it.
3. **The irradiance.** A last pass averages the rays of each probe of cascade 0 into one image, one pixel a probe (`irradianceWidth` x
   `irradianceHeight` in `render.gi2d_field`). A probe inside a blocker or an emitter is not valid: its pixel has alpha 0.
4. **The visuals.** A lit visual reads that image at its world position with a linear filter (the valid probes around it, weighted) and
   adds `irradiance x intensity` to its light before the light is multiplied by its colour, the same way the ambient light is added: the
   result is `albedo x irradiance x intensity`. Every lit 2D visual receives it, with and without a normal map.

The light a ray carries is limited by its interval: with `medium`, a point sees emitters up to 340 texels away (`reachTexels`, times
`texelSize` world units: 680 world units at the default scale of 0.5), `low` up to 168, `high` up to 1364 (a small field needs fewer
cascades: the last one reaches the field's diagonal, no more). Within that reach the light falls off the way light does in 2D: a small
emitter fills fewer of a probe's rays the farther away it is.

### Quality and cost

The counts of each quality, for a field big enough to use every cascade:

| quality | cascades | probe spacing (cascade 0) | rays per probe (cascade 0) | steps per ray | reach (texels) |
|---|---|---|---|---|---|
| low | 3 | 4 | 16 | 20 | 168 |
| medium | 4 | 2 | 4 | 28 | 340 |
| high | 5 | 2 | 4 | 40 | 1364 |

**Passes.** Every frame that draws the field and the cascades runs `2 x J + C + 5` passes, one draw each, with `C` the cascades and `J`
the jump-flooding passes of the field (the step of 1 and one pass for each power of two below the field's size: 12 for a 1504-texel
field). A 1504 x 1056 field with `medium` is 33 passes. The first frame, a frame after the field changed size and a frame after the camera
moved farther than the field have no history for the bounce, so they run a priming chain of `C + 1` more passes (`cascades.primed` in
`render.gi2d_field`); `bounce` 0 never primes. Every cascade pass draws one field-sized image, so the work grows with
`cascades x field texels x steps`; halve `resolutionScale` for a quarter of it.

**Memory.** A field is `width x height` texels, each side rounded UP to a multiple of 32 (see "Zooming and moving"), with 64 bytes a
texel (eight RGBA16F images alive together: the emission, the blockers, the distance, the jump-flooding and cascade images) plus 16 bytes
a probe of cascade 0 for the two irradiance images. Examples, for a view of `W x H` world units at one unit a pixel:

| view | `range` | `resolutionScale` | field | memory (medium) |
|---|---|---|---|---|
| 640 x 360 | 64 | 1 | 800 x 512 | 27 MiB |
| 1280 x 720 | 64 | 0.5 | 736 x 448 | 22 MiB |
| 1280 x 720 | 512 (default) | 0.5 | 1184 x 896 | 69 MiB |
| 1920 x 1080 | 512 (default) | 0.5 | 1504 x 1056 | 103 MiB |

A side is at most 2048 texels (the texel grows past that: `capped`). The persistent part, the three field images and the irradiance (about
three eighths of the total), is what `bytes` in `render.gi2d_field` reports. The measured time of a frame is not claimed here: it depends on
the GPU. Use `render.frame_graph {"profileFrames": 8}` (the `cpuMs` and `gpuMs` of every `<job>/gi-*` pass) on the target device, and lower
`range` first: the default 512 on a view of 1920 x 1080 costs twice the memory of a margin of 128.

The counted triangulation budget (`kGi2dMaxTriangulateWork`, 2,000,000 point-in-triangle tests per gather per frame) is a worst case, worth about ten ms of CPU with pathological casters (polygons of many corners with crossing or nearly flat edges); normal casters use a tiny part of it.

**On a phone or a browser the defaults do not fit.** The budget there is 96 MiB and the defaults (`range` 512, `resolutionScale` 0.5) on a
view of 1920 x 1080 need 103 MiB, so the scene is drawn without GI and the log says why. Use `range` 128 (about 52 MiB) or `resolutionScale` 0.25
(about 27 MiB), and `quality` `medium` or `low`; `render.supports {"feature": "2dGlobalIllumination"}` tells the same. The fields of all the
cameras of a frame share one total: 640 MiB on a desktop, 96 MiB on a phone or a browser; a camera that would go over it is drawn without GI
and the warning names the numbers.

### When it is off, and what you are told

The scene is drawn without GI, with one warning in the log for the whole run (not one per frame), when:

- the GPU has no RGBA16F render targets that blend and filter (GLCORE, D3D11 and Metal always have them; some GLES 3.0 phones do not):
  `render.supports "2dGlobalIllumination"` and `render.gi2d_field` say `supported: false` with the reason;
- the quality needs more cascade passes than the platform budgets: 5 on a desktop, 4 on a phone or a browser (GLES 3, iOS), so `high`
  is off there and the warning says to use `medium` or `low`;
- the field needs more memory than the platform budgets: 320 MiB on a desktop, 96 MiB on a phone or a browser. The warning gives the
  size and says to lower `range` or `resolutionScale`. The 2048 x 2048 field of the largest `range` is 272 MiB with `high`: inside the
  desktop budget and over the mobile one. The fields of the cameras of a frame together have a budget too (640 MiB, 96 MiB on a phone or
  a browser).

The warning is said again when the reason changes (a new setting, another camera over the budget) and when another scene is loaded, so
a second scene that cannot draw the GI is not silent.

These are counts, never times: the same scene gets the same answer on a fast machine and a slow one.

## Who receives the light

- **Lit visuals only.** A visual with `lit` false (the default for sprites) is drawn exactly as it was: the same pixels with and without
  the component, and nothing to switch off. Emission is added after the lighting and is not changed. 3D meshes get no GI (use the 3D
  lighting).
- **`lightLayers` is not applied to the GI.** `lightLayers` pairs a `Light2D` with the visuals it lights; the GI has no such pairing: it is
  an ambient-like term of the whole scene, so it reaches every lit visual of the view, and every blocker blocks it, whatever the
  `lightLayers` of the casters and the visuals say. To keep a visual out of the GI, make it unlit.
- **The inside of a blocker.** A probe that falls inside a blocker or an emitter is not valid, and the visual reads its light from the
  valid probes around: a thin wall (a few probes across) is lit by the free probes next to it, but the inside of a thick lit block gets only
  the ambient light and the `Light2D`s. A solid tilemap that must look lit all over should be drawn with an ambient light or a `Light2D`
  that reaches it.
- **The screen-space layer gets no GI.** A sprite or tilemap with `space` `screen` (the HUD) and the debug drawing of the camera are
  drawn without the GI term even when they are `lit`: the GI is the light of the world.
- **Pictures drawn into their own image get no GI.** The GI is made for the cameras that draw the game: `camera:<n>` jobs in the frame
  graph. A camera that draws into a render target (`Camera.renderTarget`, `target:<name>`), a `CameraView`, an editor view and a camera capture
  (`capture`, `view:<n>`) draws its lit visuals without the GI term, and they keep no field. A scene that must look the same in a render
  target as on screen should not depend on the GI there.

## Zooming and moving

- The field's sides are rounded up to a multiple of 32 texels, so a zoom that adds a few texels does not make new images: the size changes
  only when the view grows past the next multiple, and shrinks back past the previous one. **No history is kept across a size
  change**: the images are made again and the bounce starts from the priming chain (one extra frame's work, no flicker).
- The field's origin is snapped to whole texels, so a camera that moves keeps the bounce history by shifting it by whole texels. A move
  of more than the field's size drops the history.
- The bounce history belongs to one camera: when a camera goes away (or another is created before it) and another takes its place in the
  frame, the new one starts from the priming chain instead of showing the light of the other.
- At most four 2D camera jobs a frame have a field (`kGi2dMaxFields`); a fifth is drawn without GI.

## Looking at it

`render.gi2d_field` reports each field (size, texel size, world rectangle, bytes, passes, the cascades and the counts of emitters and blockers) and, with
`save`, writes `<save>-emission.png`, `<save>-occluders.png`, `<save>-distance.png` and `<save>-irradiance.png`. The irradiance PNG is one
pixel a probe: rgb is the light that reaches it and alpha is 0 where the probe is not valid. Read it first when light that should reach
a visual does not.

In the distance image `r` and `g` are the integer coordinates of the nearest blocker texel, `b` is the distance to it in field texels
(a half float) and `a` is 1 where a blocker was found. **Where `a` is 0 (no blocker anywhere in the field), `r` and `g` hold -1 and -1 and `b` holds 65504**: a reader must test `a`, never use `r` and `g` as coordinates without it.

## Recipe

```json
{ "components": { "GlobalIllumination2D": { "quality": "medium", "bounce": 0.6, "range": 128, "resolutionScale": 0.5 } } }
```

Then give a sprite `lit: true` and a `ShadowCaster2D`, another sprite an `emissive` colour with `emissiveIntensity` 3, and look at the
result with `capture` or `render.gi2d_field {"save": ".factoria/tmp/gi"}`. Start with a `range` just over what the player can see
coming (a quarter of the view is often enough), lower `resolutionScale` before quality, and keep `high` for desktop builds.
