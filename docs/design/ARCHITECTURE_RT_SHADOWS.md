# Rendering: ray traced shadows of point, spot and area lights (M79, package P2a-3)

The shadows of the lights other than the sun, drawn with rays, on the scaffold of [ARCHITECTURE_RT_EFFECTS.md](ARCHITECTURE_RT_EFFECTS.md) (read its
"Free when off", the bindings and the sun's shadow first). The user-facing description is docs/RAY_TRACING.md, "Shadows".

Code: `engine/render/src/rt_local_shadows.h` / `.cpp` (which lights are traced, the constants of the kernel), `engine/render/shaders/rt/rt_shadow_local.hlsl`
and `.metal` (the trace kernel), `rt_shadow_local_pack.hlsl` and `.metal` (the pack kernel), `rt_effect.h` (`RtLocalLight`, `RtLocalParams`),
`renderer_draw.cpp` (candidates, the two passes, the skipped maps, the lit pass flags), `engine/render/shaders/mesh_common.glsl`
(`fa_shadow_local_rt`), `light_loop.glsl` (its two calls), `light_data.glsl` (the slot in the light table), `engine/runtime/src/engine.cpp` (the status).
Tests: `engine/render/tests/rt_local_shadow_tests.cpp` (selection, parameters, the RecordingDevice frames, the shader text, every host) and
`rt_shadow_local_metal_tests.cpp` (a real Metal device, against a CPU ray caster; macOS only).

## Which lights are traced

A candidate is a point, spot or area light that casts a shadow and that the maps' own planner (`shadow_bounds`) would give a map: a caster can
reach it and it is inside its shadow distance. At most `kRtLocalShadowMaxLights` = 3 per camera and frame are traced. They are picked by the
importance the maps' budget uses (`local_shadow_importance`: brightness, range, distance from the camera) in `pick_rt_local_lights`:

- A slot is sticky: a light keeps its slot while it stays a candidate, and a newcomer takes the weakest holder's slot only when it is
  `kRtLocalSwapFactor` = 1.25 times more important (two lights of equal importance never swap; ties go to the lower index of the light table).
- A light whose importance is 0, negative or NaN is never traced.
- The lights beyond the cap keep their shadow maps, and `render.ray_tracing` says how many asked and how many were traced.
- `RtLocalPick::changed` is true when a light entered or left a slot this frame.

## Two kernels, two images

`rt_shadow_local` (`usesLocal`: `RtLocalParams`, 256 bytes, in uniform slot 1, b1 / binding 7 / buffer(3)) writes an Rgba32F image: r, g, b = the visibility
of light 0, 1, 2 and a = 1 where a mesh is drawn. A pixel outside the light's reach, behind an area light's emitter, or outside a spot's cone is 1
(lit, no ray is cast). The ray starts at the surface (the sun's normal offset and its growth with depth) and ends just short of the light
(`header.y`, a fraction of its length), so the emitter's own geometry never shadows it. A cutout casts no shadow in the rays (its alpha
texture is not readable by the kernel): such a frame has untraced casters, see below.

- Hard (`shadows = "hard"`, or soft with every traced light of size 0): one ray to the light's centre.
- Soft (`shadows = "soft"`, `raysPerPixel` rays): a point or spot light jitters the ray inside a cone of tangent `tan(0.05 * shadowSoftness)`
  around the direction to its centre (the angular size of the PCSS of its map); an area light takes points of its emitter (rectangle, disc,
  tube), the half sizes scaled by `shadowSoftness`. The sequence is the R2 sequence shifted by the pixel's interleaved gradient noise and
  `rt_effect_seed(frameSerial)`: no clock, no `rand()`. A light with no size in a soft frame gives the same image as the hard one.
- The mode is soft only when some traced light is soft (`anySoft`); otherwise the whole job is the hard one and the denoiser is not run.

`rt_shadow_local_pack` (`rt_effect.h` spec: `usesAux`, the trace image as view 5) turns the visibilities into the image the lit pass reads: it
**replaces the sun's image** at fragment view 28 (the screen slot of the sun's visibility). F = (r: the prepass depth, g: the sun's visibility when
the sun is traced, else 1, b: three bytes `round(visibility * 255) << (8 * slot)`, an empty slot is 255, a: the mesh flag). The sky gives
(depth, 1, 16777215, 0). Packing three visibilities in one float channel keeps 24 bits exact (a float32 holds integers up to 2^24).

## Denoising

The soft image goes through the `RtDenoiser` as **one signal**, `kRtLocalSignalId` = 6 (`renderer_impl.h`; the sun is 1, the ambient occlusion 2, the
reflections 3 and 4), kind `Diffuse`, `fireflyClamp = 0`, name "local-shadows", with the luminance edge-stop of that kind over the three channels. The
history is the three slots' together: when a light enters or leaves a slot (`RtLocalPick::changed`) the renderer drops the whole signal
(`drop_signal`) and the next frame starts from the raw image, because a slot's history belongs to the light that held it. A hard frame runs no
denoiser and keeps no history.

## What the lit pass reads

The light data texture holds, per light, `z = rtSlot`: 0 not traced, 1..3 the slot. In the loop (`light_loop.glsl`) a shadowed light calls
`fa_shadow_local_rt(slot, v)` in place of the map lookup where `fa_ct_b[3]` says the image is valid: it decodes the byte
(`mod(floor(b / 256^slot), 256) / 255`) and returns it, or `min(rt, map)` when `fa_ct_b.z` is set, i.e. when `RtSceneStats::untracedCasters > 0`
(the sun's rule: a caster the rays miss keeps its shadow from the map; terrain, impostors, GPU-driven meshes, cutouts, meshes over the instance
cap or without a built acceleration structure). The full-shader template (`mesh_full_common.glsl`) still calls the map version: a material with a
full shader keeps its shadow maps.

## The maps that are not drawn

A traced light's maps are skipped at execution (`skipView` in the shadow pass; the atlas is still allocated and cleared, so the layout and the
sun's cascades do not change) only when nothing would read them: the traced pass is declared, the TLAS is valid, `untracedCasters == 0`, no RT effect has
failed, and the job has no blended mesh, decal, terrain, transmissive or subsurface draw and no full-shader material (those draws read the map).
The **volumetric fog** reads the maps too (its march, `vol_shadow_local` in `volumetric.glsl`): the map of a traced light is skipped only when
the camera does not draw the fog (`postPlan.vol.on`) or that light's `Light.volumetric` is 0; a traced light that shines in the fog keeps its map
(one light is decided apart from the others: a traced light with no volumetric share still skips it). With any
of them the maps are drawn and the lit pass still takes the traced value (`min` with the map where the untraced casters are). CPU culling of the
shadow casters still runs (it is cheap and the maps' budget needs it).

## Fallbacks and cost

- Off, or a device that cannot trace: no pass, no image, no kernel, the raster maps; the frame is the one of ray tracing off.
- The pipeline or the image of either kernel refused: one WARN (`rtWarnedLocal`) and the lights keep their maps. The passes are declared (or
  refused) while the frame graph is built, before the shadow pass runs, so the maps are skipped only when both passes are valid: no frame has a
  light with neither its map nor its rays.
- No `Light.shadowDistance` fade for a traced light: the rays reach as far as the light's range.
- Memory: two RGBA32F images per camera (the trace and the pack, the size of the prepass) plus the denoiser's history for signal 6. They are freed two frames after the last use.
- `render.ray_tracing` answers `localShadows: { cap, candidates, traced }` (the last whole frame) and its `reason` names the lights and the cap.

D3D12 and Vulkan: the HLSL is compiled with DXC (DXIL cs_6_5, SPIR-V with SPV_KHR_ray_query) and committed in `src/shaders/rt/*.rt.h`; it was
not run on a device in this package. Metal is tested on a real GPU against a CPU ray caster (hard, soft, repeatability, the pack).
