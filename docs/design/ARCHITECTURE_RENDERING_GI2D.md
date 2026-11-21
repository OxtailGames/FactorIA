# FactorIA architecture: rendering, the 2D global illumination field

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The user-facing description of the component is `GlobalIllumination2D` in
[COMPONENTS.md](../COMPONENTS.md). This page is what M74.3 shares between its two packages: P3a builds the field (this page's code:
`engine/render/src/gi2d.h`, `gi2d.cpp`, `gi2d_gather.cpp`, `renderer_gi2d.cpp`, `engine/render/shaders/gi2d.glsl`), P3b builds the radiance
cascades on top of it and lights the 2D scene. P3a lights nothing: with it the picture of a scene does not change.

## What the field is

For every 2D (orthographic) camera job of a frame, when the scene has an enabled `GlobalIllumination2D` (the first one counts) and the GPU can
render to RGBA16F, the renderer keeps three RGBA16F images of the same size, the **field**:

| Image | Resource name in the frame graph | What it holds |
|---|---|---|
| emission | `<job>/gi2d-emission` | RGB: the light that glows, in linear HDR (the `emissive` colour times `emissiveIntensity` of sprites and tilemaps, the colour times intensity of a `Light2D` as a disc). Added where several emitters overlap. A is not meaningful (every emitter writes 1; do not read it). |
| occluder | `<job>/gi2d-occluder` | RGB: the albedo of what blocks light (a solid tilemap cell, a `ShadowCaster2D` box or polygon or sprite alpha). A = occupancy, 0 or 1 (an alpha-tested sprite caster writes 1 where its alpha passes the threshold). Replaced, not added: the last writer of a texel wins. |
| distance | `<job>/gi2d-distance` | The jump-flooding distance field of the occluder image. See "Distance encoding". |

`<job>` is the camera job's name (`camera:0`; the editor's views and captures have their own). The images are **imported** resources of
the frame graph (they outlive the graph, P3b's passes and the `render.gi2d_field` command read them after it), made by
`Gi2dSystem::acquire` and kept in four slots (`kGi2dMaxFields`): the first four 2D camera jobs of a frame get one, a fifth gets none.

The graph's passes of a field are named `<job>/gi-emission`, `<job>/gi-occluders`, `<job>/gi-seed`, `<job>/gi-jfa-<step>` and, last,
`<job>/gi-distance`. They exist only while the frame has a field: **without a `GlobalIllumination2D`, with `enabled` false, on a GPU
without RGBA16F render targets, or for a 3D camera, no pass is declared, no image is made and no memory is kept** (the slots are freed
before the graph runs, `Gi2dSystem::free_unused`). On a GPU without RGBA16F the log says so once, naming the backend and
`render.supports "2dGlobalIllumination"`, and `render.gi2d_field` reports `supported: false` with the same sentence. The supports row stays
`planned` until P3b draws the light (P3b flips it).

## 2D GI field: what P3b reads

**Where it is in the frame.** The three images are complete after the pass `<job>/gi-distance` of the camera job's graph, and before the
job's main pass (the scene draw): a pass of P3b that declares `reads: {plan.emission, plan.occluder, plan.distance}` (the `ResourceId`s that
`Gi2dSystem::add_passes` stores in `Gi2dJobPlan`) runs after the field is filled and before the sprites sample the result. The CPU side is
settled earlier: `Renderer::Impl::gi2d_plan` runs in the job's plan step, so `ctx.gi2d.field` is known when the cascades are planned.
`Gi2dField::valid` is true once the passes of the last frame ran. A frame drawn without the job leaves the images as they were (a capture
keeps the slots, `begin_frame(keep)`), and the first frame after a size change makes them new and fills them in that same frame.

**Texture names, slots and formats.** All three are RGBA16F colour images of `width x height` texels (`Gi2dField::emission.texView` and
`.color`, `occluder`, `distance`), sampled with a sampler of the cascade's choice (the images are not filtered by the field itself: use
`nearest` for the distance, `linear` for the emission and the occluder only where a blurred value is meant). The shader names that P3b's own
`.glsl` declares are its own; the field passes use the programs `draw`, `seed` and `jfa` of `gi2d.glsl` (`UB_gi2d_gi2d_vs_params` 0,
`UB_gi2d_gi2d_fs_params` 1, `VIEW_gi2d_tex`, `SMP_gi2d_smp`).

**World to uv and back.** The field is screen-aligned: texel `(i, j)` (`0 <= i < width`, `0 <= j < height`) is the world square
`[originX + i * texel, originX + (i + 1) * texel] x [originY + j * texel, originY + (j + 1) * texel]`, so

```
uv.x = (world.x - originX) / (texel * width)        i = floor(uv.x * width)
uv.y = (world.y - originY) / (texel * height)       j = floor(uv.y * height)
world = origin + (vec2(i, j) + 0.5) * texel         (the centre of texel (i, j))
```

`texel` (world units per field texel), `originX`, `originY`, `width` and `height` are `Gi2dGeometry`, reported by `render.gi2d_field` as
`texelSize` and `worldRect` `{x, y, width, height}`. **Texture row 0 is the smallest world y on every backend**: the draw passes flip the
y of the clip space where the backend's texture origin is at the top (Metal, D3D11), so sampling `uv.y` as written above needs no
`#if` for GL. The read-back of the command and of the tests (`gi2d_read`) puts that row first as well; the PNGs it writes have the
largest world y in their first row, as a picture of the world is read.

**Distance encoding.** The distance image comes out of jump flooding ("1+JFA": a step of 1, then steps `p, p/2, ..., 1` with `p` the largest
power of two below `max(width, height)`, one pass each; `<job>/gi-jfa-<step>`). Per texel:

- `r`, `g`: the integer texel coordinates `(i, j)` of the nearest occluder texel, as a float. Exact (RGBA16F holds integers up to 2048, which
  is why the field is capped at `kGi2dMaxSize` = 2048 texels a side). An occluder texel names itself.
- `b`: the distance to that texel in **field texels** (not world units: multiply by `texel`), `length(vec2(i, j) - seed)`, measured between
  texel indices. It is stored as a half float, so a value of 100 texels is quantised to about 0.06 texels (a relative step of 2^-11). Where a
  distance must be exact, recompute it from `r` and `g`, which are exact.
- `a`: 1 where a nearest occluder was found, 0 where not. A field with **no occluder at all** has `a = 0` and `b = 65504`
  (`kGi2dNoDistance`, the largest half float) everywhere.

Jump flooding is approximate by design: a texel can get a seed that is not the nearest one when two occluders are almost as far, and the
error stays within about one texel (the test compares every third texel of a scene against a brute-force search). A cascade that marches a
ray with `b` as the safe step size (sphere tracing) is safe: it never steps over an occluder by more than that error, so end the march
when `b < 1`. The distance is the distance to an occluder texel, whose coverage is its centre: a thin occluder narrower than a texel can
be missed by the field, which is the resolution the settings (`resolutionScale`) buy.

**Camera movement and texel snapping.** The size of the field depends on the camera's view size and on the settings only, never on where the
camera is:

```
texel  = 1 / (pixelsPerUnit * resolutionScale)        (the float's value; larger only when `capped`)
width  = ceil((visible.w + 2 * range) / texel) + 2
height = ceil((visible.h + 2 * range) / texel) + 2
originX = floor((visible.x - range) / texel) * texel   (in doubles, then stored as double)
originY = floor((visible.y - range) / texel) * texel
```

`visible` is the camera's visible rectangle in world units, `range` is `GlobalIllumination2D.range` (the margin on every side, so light from
outside the screen still reaches it). The origin therefore moves only by **whole texels**: a camera that moves less than a texel moves the
field by 0 or by one texel (when the camera crosses the boundary of the floor), so what is drawn into the field does not swim and a cascade
that is kept from frame to frame can be shifted by an integer number of texels (`(originX_new - originX_old) / texel` is an integer, to 1e-6)
instead of being re-sampled. `width` and `height` stay constant while the view and the settings do. A change of the view's size (a window
resize, a camera zoom: `visible` changes) or of `range` / `resolutionScale` makes new images and restarts any history P3b keeps.

**Caps.** A side is at most `kGi2dMaxSize` = 2048 texels (the texel grows when `(visible + 2 * range) / texel` is over that: `capped` is
true, and `texelSize` is larger than `1 / (pixelsPerUnit * resolutionScale)`), at least `kGi2dMinSize` = 8. At most `kGi2dMaxFields` = 4 fields a
frame. A field draws at most `kGi2dMaxQuads` = 60000 emitting or occluding quads; the quads over that are left out, counted in
`render.gi2d_field` as `dropped`, and logged once. The memory of a field (the three images and the two a jump-flooding step reads and
writes, 8 bytes a texel) is checked in 64 bits with saturation before it is allocated and is at most `kGi2dMaxBytes` = 256 MiB (the size cap
keeps it under 160 MiB). All of these are counts, never times: the field is the same on a slow machine.

## The CPU side: what is gathered

`gi2d_gather` (CPU) collects what touches the field's rectangle, for the camera of the frame (`Camera.showTags` / `hideTags`, `Tint` and the
drawn pose, as the sprites are drawn), as triangles in field texel coordinates:

- **Emitters** (the emission image): a `Sprite` with a non-black `emissive`, lit or not, as the sprite shows it on screen (colour times
  `emissiveIntensity`, times the `emissiveMap` rgb when there is one; a plain sprite is shaped by its own alpha, a sprite with an `emissiveMap`
  by the map's rgb and the colour's alpha, since the field draws one picture per sprite), the `emissive` cells of a `Tilemap`, and every point `Light2D` as a disc of radius `max(size, one texel)`.
- **Occluders** (the occluder image): the solid cells of a `Tilemap` with `occludesLight`, `ShadowCaster2D` boxes and polygons (triangulated by
  ear clipping, `gi2d_triangulate`), and sprites with a `ShadowCaster2D` of shape `spriteAlpha` (alpha-tested). A caster that cannot be drawn
  (a `spriteAlpha` caster without a `Sprite`, a polygon with fewer than 3 points) is counted as `skipped`.

`render.gi2d_field` reports the counts per field (`emitters`, `occluders`, `dropped`), the sizes and the world rectangle, and with `save` writes
`<save>-emission.png`, `<save>-occluders.png` and `<save>-distance.png` (the distance as grey: black at an occluder, white at the farthest
distance of the field and where there is none). It is the command to look at when a light that should reach somewhere does not.

## Tests

`engine/render/tests/gi2d_field_tests.cpp`: the geometry (sizes independent of the camera position, the 2048 cap, a view without a size), the
triangulation, the content of the three images read back (an emissive sprite, a `Light2D`, a shadow caster box and solid tiles), the distance
image against a brute-force search (within half-float precision), a scene with no occluder, the snapping of the origin, no pass or image
without GI or with `enabled` false (and the slots freed when it turns off), the report and the PNG files. `engine/runtime/tests/shot_tests.cpp`:
the command. The tests that need RGBA16F targets return early on a GPU that has none.
