# Rendering: the ray traced translucency (M79-P3b)

`render.rayTracing.translucency` traces the light that goes **through** glass and liquids: a refracted ray bent by Snell's law at every
interface of the closed mesh, tinted by Beer-Lambert absorption inside it, and shaded where it ends with the same hit shading the reflections
use. It is the third effect on the scaffold of [ARCHITECTURE_RT_EFFECTS.md](ARCHITECTURE_RT_EFFECTS.md) (one kernel, one table row, the same
bindings) and reads the same TLAS and records as every effect ([ARCHITECTURE_RT_SCENE.md](ARCHITECTURE_RT_SCENE.md)). The user-facing
description is docs/RAY_TRACING.md, "Translucency".

Code: `engine/render/shaders/rt/rt_refract.hlsl` and `rt_refract.metal` (the kernel and its twin), `rt_hit.hlsli` / `rt_hit.msli`
(`rt_trace_surface_mask`, new in this package), `engine/render/src/rt_scene.cpp` (the glass instances), `render_scene.cpp`
(`resolve_part_transmission`), `renderer_draw.cpp` (the request, the hand-over to the refraction copy), `renderer_xmit.cpp` and
`shaders/xmit.glsl` (the copy's mode 2), `shaders/brdf_layers.glsl` (`fa_transmitted`, mode 3). Tests: `engine/render/tests/rt_effect_tests.cpp`
("rt translucency: ...", the RecordingDevice, every host), `rt_scene_tests.cpp` (the glass instance) and
`engine/render/tests/rt_refract_metal_tests.cpp` (a real Metal device, macOS only).

## What is traced: the glass instance

A mesh part is **refractive** when it is drawn blended, is not unlit, has no full-shader material, and its transmission (`MeshRenderer.transmission`
or the glTF part's) is above 0. The same parts the screen-space refraction treats as transmissive, so the two never disagree about what is glass.

| | |
|---|---|
| mask | `Blended (0x04) \| Refractive (0x40)`, plus `CastsShadow (0x08)` when the mesh casts shadows |
| `cullDisable` | true: a ray meets the glass from outside and from inside |
| `opaque` | true: the glass is a solid for the traversal (it is never an any-hit candidate) |
| flag | `kRtFlagRefractive` (1 << 9) |
| record | 128 bytes (was 96): `volume = {ior, thickness, attenuationDistance, transmission}` at byte 96 and `attenuation = {r, g, b, 0}` at byte 112 |

The record grew by two float4 rows. Every instance has them: a surface that is not refractive carries `volume = {ior, 0, 0, 0}` and
`attenuation = {1, 1, 1, 0}`. The values come from `resolve_part_transmission` (the draw's own: the `MeshRenderer` field when it is not the default,
else the glTF part's; `ior` 1 to 3, `thickness` 0 to 1000 m, `attenuationDistance` 0 to 100000 m, the colour in the scene's colour space).

**What the other rays do with glass.**

- *Opaque and shadow rays.* Glass **casts a solid shadow** (the mask's `CastsShadow` bit follows `MeshRenderer.castShadows`, as the shadow map does), so
  "no caster loses its shadow" holds: the raster cascades see the same mesh. Coloured shadows are not made.
- *Ambient occlusion.* It traces the mask `Opaque | Cutout`: glass occludes nothing, as before.
- *Reflections.* They trace `Opaque | Cutout | Blended` (`kRtMaskSurfaces`): they hit glass as a solid surface with its flat colour, as they did.
- *Refraction rays.* They trace `Refractive` for the primary ray and `Opaque | Cutout | Blended` for the rest.
- *Starting surface.* A ray never hits the surface it starts from: it starts at `position + dir * (user0.x + user0.y * t)`, 2 cm plus 2 mm per metre of
  the segment it ended. A shell thinner than that offset is not refracted correctly (the ray starts behind it).

## The kernel (`rt_refract`)

One thread per pixel of the prepass (`{"rt_refract", usesRecords, usesHit, usesTlas}` in the kernel table; it reads no G-buffer and no aux image).
`user0` carries `x` the offset after an interface, `y` the offset per metre, `z` the widest cone's tangent (roughness 1, ior 1.5), `w` TMax.

1. **Primary ray.** From the camera through the pixel's centre, `tmin = 0`, `tmax` = the opaque depth along the ray (the prepass; `user0.w` where
   it holds none), mask `0x40`. A pixel whose ray meets no refractive surface in front of the opaque picture writes `0` and is not traced.
2. **Up to six segments** (`kMaxSegments = 6`, a count, not a time: two glass walls enter and leave, and a bounce or two more). At each hit:
   - the record is not refractive: shade the hit with `rt_shade_hit` and stop;
   - the record is refractive and its `thickness > 0` (a closed volume): **Snell**. Entering (`inside` false) the ray is refracted with
     `eta = 1 / ior`, the tint coefficient `-ln(attenuation) / attenuationDistance` is read and `inside` becomes true; leaving it is refracted with
     `eta = ior`, and where that is total internal reflection the ray reflects and stays inside. Inside, the throughput is multiplied by
     `exp(-coef * t)` over every segment (Beer-Lambert);
   - the record is refractive and `thickness == 0` (a thin sheet: a window pane, a bottle's label): the ray passes straight through, untinted and not bent;
   - a miss: `rt_miss_color` (the environment gradient).
3. **Roughness** widens the refracted ray once, at the first interface: a cone sample of tangent `roughness * user0.z * saturate(2 * ior - 2)`
   (no spread at ior 1), the direction from PCG hashing `frame.y` (a seed from the frame serial), `x` and `y` of the pixel: **deterministic**. One
   sample per pixel and frame.
4. **Result.** `radiance * throughput` and the encoding below.

Limits (documented, not hidden): volumes are **not nested** (a glass inside a glass is two entries; the second `inside` replaces the first's tint);
the six segments cap what a ray can do (a segment 7 is shaded as a miss: the environment in the direction the ray has); the result is for
the **nearest refractive surface of the pixel** (a pane behind it is not traced for the same pixel, and the draw of that pane, which is blended over, may
tint twice); a ray sees the flat colour of a material, a faceted normal (rt_hit's), the sun only. Where the three rays of the normal meet different
triangles (an edge, a silhouette) the surface faces the ray and the ray passes **unbent** there: a thin line of unrefracted pixels at the edge
of a box is the cost.

## The output and how the glass draw reads it

The image is RGBA32F, the prepass's size, and it is **hybrid**:

| `a` | meaning | `rgb` |
|---|---|---|
| `0` | not traced: the glass shader uses the screen-space refraction | 0 |
| `1` | traced, shaded: the light that reached the pixel | `radiance * throughput` |
| `< 0` | the ray ended on a surface the **opaque picture already shows**: read the picture there | `throughput` |

The third case avoids shading what the picture holds already (textures, lights, shadow maps of the lit pass: everything the kernel cannot
evaluate). The end position is projected into the camera; if the prepass holds a surface there at the same depth
(`|prepass.r - depth| <= 0.02 * depth + 0.05`), `a = -(1 + u + 4096 v)` with `u`, `v` the texel in 4096ths of the image.

The glass has no free texture slot, so the image does not reach the glass shader by a new binding. It goes through the refraction copy the glass already
reads (the "atlas" of `renderer_xmit.cpp`: level 0 is the opaque picture, the others its blurred reductions):

1. `Xmit::build(..., traced)` draws level 0 with mode 2 of `shaders/xmit.glsl`, which binds the traced image (`tex_rt`, `smp_pt`, nearest): `a = 1` writes `rgb` with alpha 1 (`> 0.5`); `a < 0` reads the picture at `(u, v)`
   and multiplies it by `rgb`, alpha 1; `a = 0` writes the picture's own colour with alpha 0 (nothing traced there).
2. `fa_tr_a.w == 3` makes `fa_transmitted` (`brdf_layers.glsl`) read level 0 with a box filter of radius `floor(roughness * 2 + 0.5)` (at most 5x5)
   over the texels whose alpha is above 0.5; where the centre texel is not (no ray there) it falls back to the old screen-space path, per pixel.
   A rough glass is therefore filtered by the shader's own box: **no `RtDenoiser` is used for translucency** (one cone sample per pixel and the
   box average of up to 25 neighbours is all the smoothing the effect asks for; a temporal denoiser would smear the refraction of a moving
   camera).

The pass is `<job>/rt-translucency` (after `rt-accel` and the prepass); the main pass declares it as a read. A frame whose `Xmit` cannot make its
images draws no refraction at all (blended plainly), as before.

## Fallbacks and cost

- *Setting off* (`translucency` false, or `enabled` false): `ctx.rtTranslucency.want` is false; no image, no kernel, no pipeline, no pass; the lit and
  glass shaders are the ones they were (mode 3 is a branch the draw never selects).
- *No glass in view:* `want` needs a transmissive mesh in the camera's list (`transmissive_mesh_count`): nothing is asked for.
- *A device that cannot trace, or refuses the kernel or the image:* `RtEffects::add_pass` answers `valid = false` with the reason; the renderer warns **once**
  (`rtWarnedTranslucency`, re-armed when ray tracing goes off) and the glass keeps the screen-space refraction, probes or sky behind it.
- *A pixel the kernel did not trace* (`a = 0`), or a ray that leaves the traced scene (terrain, impostors, instances over the cap): the glass shader
  takes the screen-space refraction for that pixel; a miss shows the environment gradient, which is what a mirror ray would find.
- `render.ray_tracing` reports `active` true when translucency is on and the device traces, and names it in the reason ("the refraction through
  glass and liquids").
- *Cost:* one compute dispatch (a ray and, per glass interface, a ray plus three more for the normal; a shadow ray at the end), one RGBA32F image of the
  camera's size, no extra G-buffer. It is added only for a camera that draws at least one transmissive mesh.

## Tests

`rt_effect_tests.cpp` ("rt translucency: ..."): the kernel's spec (records and hit constants, no G-buffer) and the binding contract of its shader
description in every backend's numbering; nothing declared, made or kept when the setting is off or the scene has no glass; one compute pass after the
TLAS and before the refraction copy, which gets its image, the same every frame; a device that cannot trace says so once and draws the frame it
would draw with ray tracing off. `rt_scene_tests.cpp`: the record is 128 bytes with the offsets of `volume` and `attenuation`; a glass part has
mask `0x4c`, `cullDisable` and the `Refractive` flag, and an opaque mesh has none of it. `rt_refract_metal_tests.cpp` (a real Metal GPU): a
glass slab (ior 1.5, 2 m thick, tinted) in front of a red box, a green box and a floor; the prepass made on the CPU; every traced pixel against a CPU port
of the same loop (the same ray caster, Snell, Beer-Lambert, the PCG sequence, the hit shading and the projection of the end onto the picture), smooth and
rough (colours within `2e-4`, texel positions within one 4096th for the smooth glass), the same frame twice bit-identical, another frame seed changing only
the rough glass. D3D12 and Vulkan did not run this kernel: their DXIL and SPIR-V were compiled with DXC and the contract is checked by the tests above.
