# FactorIA architecture: rendering, the 2D global illumination field

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The user-facing description of the component is `GlobalIllumination2D` in
[COMPONENTS.md](../COMPONENTS.md). This page is M74.3's design: P3a builds the field (its code is
`engine/render/src/gi2d.h`, `gi2d.cpp`, `gi2d_gather.cpp`, `renderer_gi2d.cpp` and `engine/render/shaders/gi2d.glsl`), P3b builds the radiance
cascades on top of it (same files, "The CPU side" and the sections after it) and lights the 2D scene. The user page is
[RENDERING_2D_GI.md](../rendering/RENDERING_2D_GI.md). Without a `GlobalIllumination2D` nothing of it exists and the picture of a scene does
not change.

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
without RGBA16F render targets, or for a 3D camera, no pass is declared, no image is made and no new memory is kept** (the slots are freed
before the graph runs, `Gi2dSystem::free_unused`; the `TargetPool` keeps the transient targets of the jump flooding and the cascades, which were
free targets of the last frames, for `maxIdleFrames` = 4 frames before it releases them, so the memory of a scene that turns the GI off
goes down a few frames later, not in the same one). On a GPU without RGBA16F the log says so once, naming the backend and
`render.supports "2dGlobalIllumination"`, and `render.gi2d_field` reports `supported: false` with the same sentence. The supports row is a
real one (P3b flipped it from `planned`).

**Which jobs.** `gi2d_plan` returns without a field for a job whose `plan.view` is set (a view job: `target:<name>`, a `CameraView`'s
image, the editor's `view:<n>` and the `capture` of a camera: `plan_view_job`), for a 3D camera and for a job with no pixels. Those jobs
draw their lit visuals with the white image bound at the GI view, so they get no GI term (decision of P3b: a view job is a picture of its
own, usually smaller than the game's, drawn in the middle of the frame; a field for each would multiply the memory and the history slots;
the user page says so). The GI term is also bound only for **the world group** of a job (`ctx.gWorld`): the screen-space group (`gScreen`) and the
debug groups (`gDebugScreen`, `gDebugWorld`) are drawn with the white image at the GI view, so a lit visual of the HUD is not lit by the scene's GI.

## 2D GI field: what P3b reads

**Where it is in the frame.** The three images are complete after the pass `<job>/gi-distance` of the camera job's graph, and before the
main pass of that job (the scene draw): the cascade passes declare `reads: {plan.emission, plan.occluder, plan.distance, ...}` (the `ResourceId`s that
`Gi2dSystem::add_passes` stores in `Gi2dJobPlan`) and run after the field is filled; the main pass reads `plan.irradiance`, so it runs after them. The CPU side is
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
  (`kGi2dNoDistance`, the largest half float) everywhere. **A texel with `a = 0` also holds `r = g = -1`** (not a texel coordinate: the
  jump-flooding pass writes -1, -1 for "no seed", and a reader must test `a` first). The emitter distance image of P3b has the same
  encoding over the emission image.

Jump flooding is approximate by design: a texel can get a seed that is not the nearest one when two occluders are almost as far, and the
error stays within about one texel (the test compares every third texel of a scene against a brute-force search). A cascade that marches a
ray with `b` as the safe step size (sphere tracing) is safe: it never steps over an occluder by more than that error, so end the march
when `b < 1`. The distance is the distance to an occluder texel, whose coverage is its centre: a thin occluder narrower than a texel can
be missed by the field, which is the resolution the settings (`resolutionScale`) buy.

**Camera movement and texel snapping.** The size of the field depends on the camera's view size and on the settings only, never on where the
camera is:

```
texel  = 1 / (pixelsPerUnit * resolutionScale)        (the float's value; larger only when `capped`)
width  = ceil((visible.w + 2 * range) / texel) + 2, then up to a multiple of kGi2dSizeStep (32), at most kGi2dMaxSize
height = ceil((visible.h + 2 * range) / texel) + 2, the same
originX = floor((visible.x - range) / texel) * texel   (in doubles, then stored as double)
originY = floor((visible.y - range) / texel) * texel
```

`visible` is the camera's visible rectangle in world units, `range` is `GlobalIllumination2D.range` (the margin on every side, so light from
outside the screen still reaches it). The origin therefore moves only by **whole texels**: a camera that moves less than a texel moves the
field by 0 or by one texel (when the camera crosses the boundary of the floor), so what is drawn into the field does not swim and a cascade
that is kept from frame to frame can be shifted by an integer number of texels (`(originX_new - originX_old) / texel` is an integer, to 1e-6)
instead of being re-sampled. `width` and `height` stay constant while the view and the settings do, and since P3b they are rounded UP to a multiple
of 32 (the largest probe spacing of any quality, so a cascade image holds whole probes): a zoom that adds a few texels keeps the images and
only crossing the next multiple makes new ones (this is the hysteresis of an animated zoom; before it every frame of a zoom reallocated).
A change of the size (a window resize, a zoom past a multiple of 32, `range` / `resolutionScale`) makes new images and **no history is
kept across it**: the irradiance history restarts (`Gi2dField::irrValid` false), the next frame runs the priming chain.

**Caps.** A side is at most `kGi2dMaxSize` = 2048 texels (the texel grows when `(visible + 2 * range) / texel` is over that: `capped` is
true, and `texelSize` is larger than `1 / (pixelsPerUnit * resolutionScale)`), at least `kGi2dMinSize` = 32. At most `kGi2dMaxFields` = 4 fields a
frame. A field draws at most `kGi2dMaxQuads` = 60000 emitting or occluding quads; the quads over that are left out, counted in
`render.gi2d_field` as `dropped`, and logged once. The memory of a field (`kGi2dFieldImages` = 8 field-sized RGBA16F images alive together: emission, occluders, distance, the two
jump-flooding images of a chain, the emitter distance and the cascade images in flight; 64 bytes a texel) plus the two irradiance images is
checked in 64 bits before anything is allocated, against `kGi2dMaxBytes` = 320 MiB (desktop; a 2048 x 2048 field with
`high` is 272 MiB) or `kGi2dMaxBytesMobile` = 96 MiB (GLES 3 and iOS): over it `gi2d_cascade_plan` says so and the job has no field. The fields of the
cameras of one frame share a total (`gi2d_total_budget_why`: the bytes of the fields already planned plus this one, a saturating 64-bit sum, against
`kGi2dMaxTotalBytes` = 640 MiB, and `kGi2dMaxTotalBytesMobile` = 96 MiB, the same as one field, on a phone or a browser): the job that would go over has
no field and warns. The defaults (range 512, resolutionScale 0.5) on a view of 1920 x 1080 need about 103 MiB, so they are over the mobile
budget: the warning and the `render.supports` row say to use range 128 or resolutionScale 0.25. All of these are counts, never times: the field is the same on a slow machine.

## The CPU side: what is gathered

`gi2d_gather` (CPU) collects what touches the field's rectangle, for the camera of the frame (`Camera.showTags` / `hideTags`, `Tint` and the
drawn pose, as the sprites are drawn), as triangles in field texel coordinates:

- **Emitters** (the emission image): a `Sprite` with a non-black `emissive`, lit or not, as the sprite shows it on screen (colour times
  `emissiveIntensity`, times the `emissiveMap` rgb when there is one; a plain sprite is shaped by its own alpha, a sprite with an `emissiveMap`
  by the map's rgb and the colour's alpha, since the field draws one picture per sprite), the `emissive` cells of a `Tilemap`, and every point `Light2D` as a disc of radius `max(size, one texel)`.
- **Occluders** (the occluder image): the solid cells of a `Tilemap` with `occludesLight`, `ShadowCaster2D` boxes and polygons (triangulated by
  ear clipping, `gi2d_triangulate`), and sprites with a `ShadowCaster2D` of shape `spriteAlpha` (alpha-tested). A caster that cannot be drawn
  (a `spriteAlpha` caster without a `Sprite`, a polygon with fewer than 3 points or more than `kGi2dMaxPolygonPoints` = 512) is counted as `skipped`.
  The ear clipping is O(n^3), so it has a **counted** budget (`kGi2dMaxTriangulateWork` = 2 000 000 point tests for all the polygons of one gather, not a time):
  when it is spent the polygon being cut keeps the triangles it has and the polygons after it get only the triangle that needs no test (a polygon of 3 corners), the others being counted as `skipped`; the same on every machine.
  The tilemap loop stops at `kGi2dMaxQuads` (`dropped` rises by one when the loop stops at the cap: it says that cells were left out, not how many) instead of walking the rest of the map.

`render.gi2d_field` reports the counts per field (`emitters`, `occluders`, `dropped`), the sizes, the world rectangle and the `cascades` object, and with
`save` (a path PREFIX: with a `.png` suffix or a trailing `/` it is refused with `invalid_argument` and a hint) writes `<save>-emission.png`, `<save>-occluders.png`, `<save>-distance.png` (the distance as grey: black at an occluder, white at the farthest
distance of the field and where there is none) and `<save>-irradiance.png` (one pixel a probe; the alpha is the probe's validity). It is the command to look at when a light that should reach somewhere does not.

## The cascades (P3b)

Code: `Gi2dSystem::add_passes` (gi2d.cpp), `gi2d_cascade_plan` (gi2d_gather.cpp), the programs `seed_emit`, `cascade` and `irradiance` of
gi2d.glsl, and the apply term of quad_common.glsl. They exist only for a job that has a field and a cascade plan that is `ok`.

**Plan** (pure, `gi2d_quality_counts`, `gi2d_cascade_plan`): a quality is `{spacing0, cascades, steps}` = low {4, 3, 20}, medium {2, 4, 28}, high {2, 5, 40}.
Cascade `i` has probes every `spacing0 * 2^i` texels with that spacing squared rays each (four times the rays of the cascade below, a quarter of
the probes: the same number of rays in total), covers the interval `end(i-1) .. end(i)` texels with `end(i) = 2 * spacing0 * (4^(i+1) - 1) / 3`,
and the plan stops adding cascades when the last interval reaches the field's diagonal. The plan is over budget (`ok` false, a teaching `why`) when
the quality has more cascades than the platform allows (`kGi2dMaxCascades` = 5, `kGi2dMaxCascadesMobile` = 4) or the bytes (field images plus irradiance)
are over `kGi2dMaxBytes` / `kGi2dMaxBytesMobile`; `gi2d_plan` then warns (`Gi2dSystem::budgetWhys` holds the reasons already warned about, so two cameras failing differently warn once each, and `warnedTargets_` the missing render targets: the warning is
said again when the reason changes, after `free_images`, and after a scene change, so a second scene is not silent) and the job draws without GI. A job with GI
off in every job of a frame (none calls `note_gi_asked()`) makes the next `begin_frame` call `reset_warnings()`; a frame that mixes a job with GI and one without does not.

**Passes** (names `<job>/<pass>`): after the field's passes, the emitter chain (`gi-emit-seed`, `gi-emit-jfa-<step>`, last `gi-emit-distance`, a
transient: the same jump flooding over the emission image, so a ray cannot step over a thin emitter), then for `i = cascades - 1 .. 0` `gi-cascade-<i>`
and `gi-irradiance`; when the bounce has no history the same chain runs once more first, named `gi-prime-cascade-<i>` and `gi-prime-irradiance`, into the history
image. Passes per frame: field `3 + J`, emitters `1 + J`, cascades `C`, irradiance 1 (`J` = the jump-flooding passes: the step of 1 and one for each
power of two below the larger side).

**A cascade image** is field-sized and cut into `S x S` tiles (`S` = the cascade's spacing): tile `j` holds ray `j` of every probe, so one sampler
read between probes of the same ray interpolates the probes (the merge and the final read are bilinear). Ray `j` has the angle `2 pi (j + 0.5) / S^2`; its
children are rays `4j .. 4j + 3` of the cascade above (spacing `2S`). The ray sphere-traces on `min(occluder distance, emitter distance)` from `end(i-1)` to `end(i)`
for at most `steps` steps and ends at the first texel within 1 of a blocker or an emitter. An emitter hit returns its emission; a blocker hit returns
`emission + bounce x albedo x history irradiance` (the occluder's albedo, last frame's irradiance at the hit); a ray that leaves the field ends with 0;
a ray that hits nothing in its interval returns the average of its four children read at the probe's position (the top cascade has none: 0).
**`gi-irradiance`** averages the `S0^2` rays of each cascade-0 probe into an image of `width / S0 x height / S0` texels: rgb times the validity, a = 1 where the probe
is free and 0 inside a blocker or an emitter (`quad_common.glsl` divides by it: `gi_irradiance()`).

**History.** `Gi2dField::irradiance[2]` ping-pong: this frame writes `irradiance[irrCur ^ 1]` and reads `irradiance[irrCur]`, shifted by the whole-texel difference of
the field's origin, as last frame's light. It is valid (`histOk`) when `bounce > 0`, `irrValid`, the same texel size, and the shift is under the size.
It also needs `histJob == job name` and `histCamera == camera` (the bits of the `Camera` entity of the job): the job names are "camera:" plus an index, and the
slots go by the order of the active jobs, so a camera that disappears hands its slot, with its history, to the next one. That history is
another camera's light, so it is not used: the new camera is `primed`. Otherwise `primed`: the priming chain makes the history first, without history itself. The state (`irrCur`, `irrValid`, `histTexel`, `histOrigin`) is committed
by the callback of the last irradiance pass, not at plan time, so a graph that does not run (a `countPost` frame) leaves it as it was. `bounce` 0 neither
reads nor primes. The `bounce` used is capped at `kGi2dMaxBounceGain` = 0.95: the history feeds the blockers, which feed the history, so in a closed room
of white walls a loop gain of 1 would add light every frame without end; below 1 the sum is bounded (about `1 / (1 - gain)` times what the emitters give).
The gather clamps the albedo of a blocker to 0..1 for the same reason.

**Apply.** `quad_fs_params` has `gi_xf` (uv = world x `xy` + `zw`: the field's world rectangle) and `gi_p` (x = `intensity`, 0 = none); texture view 14
(`kQuadGiView`, `fx_gi_tex`, sampled with `light_smp`) is the irradiance image, or the white image when the batch gets none. `draw_group` fills them when the job's
GI is `active`, its `cascadePasses > 0`, the batch is the main pass (not the sprite-coverage pass) and `intensity > 0`. `lit_color` adds `gi_irradiance()` to
the light `total` before the albedo multiplies it. Unlit quads never call `lit_color`, so they are the same pixels; the default scene binds the white view and
`gi_p.x = 0`, so it has the same draw calls (no extra pass, no extra batch split). `lightLayers` is not read by the GI (decision: see the user page).
A custom sprite material's engine views include 14 since P3b (docs/shaders/SHADERS_SPRITES.md).

## Tests

`engine/render/tests/gi2d_cascade_tests.cpp` (P3b): quality counts and the cascade plan (intervals, budgets, the mobile limits), the irradiance image read
back (an emitter lights the probes around it, less far away, an occluder shadows what is behind it), the bounce of a coloured wall (the first frame
already, none with `bounce` 0), the history across a camera move and a size change, unlit pixels equal with and without GI, and the golden `2d_gi`.
Also in `gi2d_cascade_tests.cpp`: a camera that takes the slot of another one does not inherit its history, a closed box with `bounce` 1 stays bounded for 150
frames, and a lit screen-space sprite is the same pixels with and without GI. In `gi2d_field_tests.cpp`: the work counts of the triangulation, the shared budget
of the cameras, the wording of the phone's warning, an unlit sprite and an unlit tilemap with `emissive` emitting into the field, and a map of more
cells than `kGi2dMaxQuads` cut at the cap.
`engine/render/tests/gi2d_field_tests.cpp`: the geometry (sizes independent of the camera position, the 2048 cap, a view without a size), the
triangulation, the content of the three images read back (an emissive sprite, a `Light2D`, a shadow caster box and solid tiles), the distance
image against a brute-force search (within half-float precision), a scene with no occluder, the snapping of the origin, no pass or image
without GI or with `enabled` false (and the slots freed when it turns off), the report and the PNG files. `engine/runtime/tests/shot_tests.cpp`:
the command. The GPU tests REQUIRE the RGBA16F targets on GLCORE, D3D11 and Metal (`Own::gi_ready`); only a GLES 3 GPU without them returns early, with a message.
