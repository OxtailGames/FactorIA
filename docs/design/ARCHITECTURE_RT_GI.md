# Rendering: the realtime GI probes updated by rays (M79-P4a)

`render.rayTracing.gi = "probes"` changes how the probes of the `RealtimeGI` grids (M73, [ARCHITECTURE_RENDERING_PROBES.md](ARCHITECTURE_PROBES.md))
are updated: a compute kernel with inline ray queries replaces the six raster captures of a probe. What the lit shader reads does not change at all:
the same atlas, the same blocks, the same meta texel. The user-facing description (the settings, what is shown by `render.ray_tracing`) is
docs/RAY_TRACING.md, "Global illumination"; the per-grid settings are the doc strings of `RealtimeGI` (`raysPerProbe`, `rtProbesPerFrame`).
`gi = "perPixel"` (M79-P4b-1, the section "Per pixel") traces a bounce for every pixel instead; the two modes do not run together.

Code: `engine/render/src/rt_gi.h` and `rt_gi.cpp` (the constants block, the CPU twin of the ray set, the pass and the band image),
`engine/render/shaders/rt/rt_gi.hlsl` and `rt_gi.metal` (the kernel), `renderer_gi.cpp` (`gi_plan_rays`: which probes, the constants and the pass;
`gi_finish`: the blend into the atlas and the status), `renderer_probes_gpu.cpp` (`ProbeGpu::blit_gi`), `renderer_rt.cpp` (`ray_tracing_gi_status`),
`engine/runtime/src/engine.cpp` (`ray_tracing_status`). Tests: `engine/render/tests/rt_gi_tests.cpp` (RecordingDevice, every host) and
`rt_gi_metal_tests.cpp` (a real Metal device, macOS only).

## Free when off

With `enabled` false, `gi` other than `probes`, or no `RealtimeGI` in the scene: no shader, no image, no pass and no uniform exists, and the
frame is the one the raster captures make. `rt_begin_frame` releases `RtGiProbes` (the kernel, the band image and the records view) when the mode
goes off and `sweep` frees them two frames after their last use. A device that cannot trace rays (`rtScene.active()` false) never reaches the
pass: the raster captures update the grids as before and the status says why (`giProbes.reason`).

## One frame

1. `gi_plan` lays the grids out and, after `++g.frame`, calls `gi_plan_rays` when `gi = "probes"`. It picks the probes with the same `gi_pick` the
   raster path uses: the ones never captured first, then the ones updated longest ago (round robin; nothing looks at the camera: the camera
   priority of the brief is **not** made). A grid takes at most `rtProbesPerFrame` probes and all grids together at most `kGiRtMaxFrameProbes`
   (64, the size of the constants block); `quality.realtimeGiProbesPerFrame` caps the raster captures only (the preset's lever for the rays is
   `QualityLimits::rtGi`, applied to the setting before the renderer reads it). The grids are visited in the order of their entity
   ids, starting each frame one grid further (`rtStart`), so with many grids every one gets its share of the 64 instead of the first ones taking
   it all. The budget is a count, never a time, so the result does not depend on the CPU's speed.
2. One `RtGiDispatch` (the constants block `RtGiParams`, 1120 bytes) per grid with picks, then one compute pass `gi-probes` (a side-effect pass, so
   the graph keeps it) is declared after the main camera's `<job>/rt-accel` (the TLAS and the records). The kernel is dispatched once per grid, one
   thread group per probe (`dispatch(probes, 1, 1)`), 64 threads per group.
3. The kernel writes the new estimate of each probe's block into the **band image**, an RGBA16F storage image of `kProbeAtlasSize x kGiBandHeight`
   (1024 x 132: the atlas's block rows without the first 1024 rows), with the blend weight in alpha.
4. After the graph has run, `gi_finish` draws each probe's block of the band image into the atlas with `ProbeGpu::blit_gi` (the Blit program with
   `SrcAlpha, OneMinusSrcAlpha` blending, one draw a probe, counted in the draw calls). The lit shader samples the grids exactly as before.
5. A pass that did not run (the scene has no TLAS yet, the driver refused the compute pipeline) gives the picks back (`last` and the serial of
   the grid are restored), says why in the status and the raster captures do the frame. A kernel or image the device refuses is kept as refused
   and logged once at WARN (`RtGiProbes::note_failure`).

## The kernel (`rt_gi`)

Bindings are the contract of every ray traced kernel ([ARCHITECTURE_RT_EFFECTS.md](ARCHITECTURE_RT_EFFECTS.md), "Bindings"): the output view is the
band image, the "prepass" slot holds the **probe atlas** as a read-only texture (the multi-bounce reads it), the records buffer is the scene's,
the first uniform block is `RtGiParams` (the `paramsSize` of the kernel's spec row, not the 400-byte `RtEffectParams`) and the second the shared
`RtHitParams`. The spec row also says the output is RGBA16F (`outHalf`).

- **The rays.** `frame.z` rays per probe (`raysPerProbe`, 16 to 256, default 64) on a spherical Fibonacci set, rotated by a unit quaternion drawn
  from a PCG hash of the frame seed (`rt_effect_seed(frame)`) and the probe's index: a different rotation in every update, the same for the same
  frame and probe. `rt_gi_pcg`, `rt_gi_rotation`, `rt_gi_fibonacci` and `rt_gi_direction` in `rt_gi.h` are the CPU twin (the tests trace the same rays).
- **A hit** is shaded by `rt_trace_surface` and `rt_shade_hit` of the hit include (the sun, its shadow ray, the emission, the environment's
  gradient, [ARCHITECTURE_RT_EFFECTS.md](ARCHITECTURE_RT_EFFECTS.md), "Hit shading"). With `bounce` above 0 the kernel adds the light that the
  grid's own probes (the atlas, as it stood at the start of the frame) give at the hit point, times `bounce` and the albedo: the multi-bounce, one
  bounce more each time a probe is updated. **A miss** returns the environment (the sky).
- **The projection.** The radiance of each ray is projected onto nine SH coefficients (`4 pi / n` weight) and written to the probe's SH row
  (row 10 of its block, texels 0 to 8). The hit distance of each ray, normalised by `maxDistance`, goes into the 10 x 10 depth map (the
  8 x 8 octahedral map and its border) as the two Chebyshev moments, weighted by a cosine lobe of `4 + n / 16` around each texel's direction.
  Texel 9 of the SH row is the meta texel: `r` the fraction of rays that hit a back face (`backfaceTolerance` discards probes inside walls), `g` = 1
  (captured).
- **The hysteresis** is the blend weight in alpha: 1 for a probe never updated (the first update replaces the block), otherwise
  `clamp(1 - hysteresis, 0.01, 1)`. The blit does the mix, so the temporal filter is `atlas = old * (1 - w) + new * w`, the same as the raster
  path's `filter_gi`.
- **One query site.** Metal allows one `intersection_query` call site per kernel: the closest hit, the shadow rays and the normal's two extra rays
  all go through `rt_closest_hit_ff` (`rt_hit.hlsli` / `rt_hit.msli`), which also returns the hardware's front-face flag
  (`RtSurface.front`, additive: the other kernels are unchanged).
- **The front-face sense.** The back-face fraction needs to know which side of a triangle the flag calls the front. `flags.x` of the constants says
  it, `rt_gi_front_sense(backend)`: +1 on Metal, **measured** by `rt_gi_front_tests.cpp` (a probe in the open reads 0 back faces, one inside a box
  reads 1); **0 on D3D12 and Vulkan**, which have not been measured: with 0 the kernel counts no back faces at all (the probes inside walls are
  not discarded, a light leak, but no probe goes black because of a guessed sign). `rt_gi_front_tests.cpp` runs the
  same two probes on the backend of the build (on a machine with ray tracing), prints the sign it measures and checks it against `rt_gi_front_sense` once that is not 0; put the
  measured value in `rt_gi_front_sense` to turn the discard on. A two-sided instance (`kRtFlagTwoSided`) never counts as a back face.

## Status

`render.ray_tracing` answers `giProbes {active, reason, grids, probesPerFrame, budget}` (docs/RAY_TRACING.md) and `render.gi_grid` per grid
`updatedBy` (`"rays"` or `"captures"`), `raysPerProbe`, `rtProbesPerFrame` and `rtUpdatesLastFrame`, with `framesPerCycle` for the mode in use.
The numbers are those of the last frame that ran the planner (`rtGiStatus`, under `rtGiStatusMutex`: the command runs on another thread).

## Determinism and limits

The same frame twice records the same stream and writes the same bytes (the real-Metal test compares two dispatches). A GPU's `sin`, `cos`
and `pow` differ from the CPU's in the last digits, so the tests compare the CPU reference with tolerances and never branch on them. The block
of a grid is read only after all its probes were captured once (`gr.captured == count`), as with the raster path. `gi_pick` skips nothing that
the budget allows, so a grid of N probes at `rtProbesPerFrame` P is complete after `ceil(N / P)` frames (`framesPerCycle`).

## Tests

`rt_gi_tests.cpp` (RecordingDevice with ray tracing recorded; every host): the HLSL and MSL `RtGiParams` field names against `kRtGiParamNames`; the
kernel table, the spec and the shader description in every backend; one `intersection_query` site in the MSL text; the CPU ray set (the
same for the same seed, different for another, uniform on the sphere); `gi = "off"` records nothing and spends nothing; with `probes` one compute
pass after the TLAS build with a 1120-byte uniform and `dispatch 4 1 1` for four probes; the cap of 64 probes; two runs record the same stream; a
device that cannot trace falls back to the raster captures and says why; turning the mode off frees the kernel and the image; a scene without
a `RealtimeGI` says so.

`rt_gi_metal_tests.cpp` (macOS, `#if defined(__APPLE__)`; a placeholder case elsewhere): two probes (one in the open above a floor, one inside an
emissive box), the records of the instances, a zero atlas and the engine's own `RtGiParams`; the SH row (9 coefficients x RGB), the meta
texel and the 100 depth texels of each block are compared with a CPU ray caster over the same rays (within the tolerance of a GPU's trigonometry and
of the half float, and of a few edge rays), the weights in alpha are checked, the back-face fraction of the probe in the box is above 0.9 and
that of the probe in the open below 0.1, two dispatches give the same bytes, another seed another image, and a bounce over an empty atlas
changes nothing. It skips, with a reason, on a machine with no GPU, no Metal or no ray tracing. **Not run by any test:** the kernel on D3D12 and
Vulkan (DXC compiled it: DXIL and SPIR-V in `rt_gi.rt.h`), the blit into the atlas on a real GPU (RecordingDevice only), and a bounce that reads
captured probes.

## Per pixel

`render.rayTracing.gi = "perPixel"` (M79-P4b-1; user doc: docs/RAY_TRACING.md, "Global illumination") draws the indirect diffuse light of every pixel
of the main camera with rays and gives it to the lit shader in place of the probe and ambient term. Code: `shaders/rt/rt_gi_pixel.hlsl` and
`.metal` (the kernel), `rt_gi_grid.hlsli` and `.msli` (the grid sampling, shared with `rt_gi`: `gi_grid_light`), `rt_effect.h` / `.cpp`
(`RtGiPixelParams`, `usesAtlas`), `renderer_draw.cpp` (`plan_job`, the block of `build_graph`, `main_pass`, `fill_fs`, `bind_textures`),
`renderer_rt.cpp` (`rt_gi_pixel_finish`, `ray_tracing_gi_pixel_status`), `mesh_common.glsl` (`fa_indirect_diffuse`, `fa_gi_px`).
Tests: `rt_gi_pixel_tests.cpp` (RecordingDevice), `rt_gi_pixel_metal_tests.cpp` (a real Metal device, macOS only) and
`rt_gi_pixel_picture_tests.cpp` (the whole renderer on the real device of the build).

- **The pass.** `rt-gipixel` is an ordinary `RtEffects` pass (kernel table row `rt_gi_pixel`, effect `gipixel`), declared after the camera's
  `rt-accel`: the prepass (depth, normal), the records, `RtHitParams`, and the probe atlas as a texture at `kViewAlbedo` (`usesAtlas`: t3 /
  binding 5 / texture(2); a kernel with `usesGbuffer` cannot use it). The constants are `RtGiPixelParams` (672 bytes): the common
  `RtEffectParams` and the **tail**, the realtime GI grids (up to four) the lit pass reads, copied from `probes.gi.records` (rebuilt at the start of the
  frame by `gi_build_records`: the same rows the lit shader gets). The atlas view is asked when the pass runs (`RtEffectRequest::atlas`), because the
  atlas is made again when the probes change size; a view that is not valid makes the pass not run (`ran` false). The image is RGBA32F.
- **The rays.** `raysPerPixel` (1 to 16) per pixel. `state = pcg(x + pcg(y + pcg(frame.y)))`, then for ray i two draws `u1 = (i + unit) / n` and `u2`
  (stratified in u1) give the cosine-weighted direction in the frame of the normal (`sqrt(u1)` radius, `2 pi u2` angle); the origin is the surface
  point moved along the normal by `user0.y + user0.z * depth` (2 cm and 2 mm per metre). The seed is the frame serial, never the clock.
- **A hit** is `rt_trace_surface` plus `rt_shade_hit` (the sun, its shadow ray, the emission and the environment, as the reflections). With grids in
  the tail and a lit surface it adds `diffuse * (grids' light * intensity * bounce - ambient * covered)`: what the grids give at the hit replaces the
  ambient the hit shading already counts, as in `rt_gi`'s own multi-bounce. There is **no recursion**: one traced bounce and the cached tail. A
  **miss** is `rt_miss_color` (the environment). The output is the mean of the rays: the cosine-weighted mean of the incoming radiance (the
  irradiance over pi), **without** the surface's albedo, alpha 1; a sky pixel writes 0.
- **One query site** (Metal): `rt_trace_surface` and `rt_shade_hit` go through `rt_closest_hit_ff`, as in every kernel.
- **Denoise.** One function, the `denoise` lambda of the `build_graph` block, calls `RtDenoiser::add_passes` with `DenoiseKind::Diffuse`, signal id
  `kRtGiPixelSignalId` (7) and the name `gipixel`. The image is already demodulated (it has no albedo), so the denoiser needs no albedo input and the
  lit shader multiplies the result by the surface's albedo as it does the ambient. `DenoiseSignal::enabled = false` there (DLSS Ray Reconstruction taking
  the signal, see "Ray Reconstruction" below) makes the main pass read the noisy image.
- **The composite.** `main_pass` takes the image view (the denoised transient, else the kernel's) when `img->ran` is true, so a pass that did not run
  never gives the lit shader an image it did not write. For the opaque draws with no lightmap `fill_fs` sets `fa_gi_px.x` and `bind_textures`
  binds the view at the **lightmap slot** (the mesh shader has no free texture unit: 16 are used): `fa_indirect_diffuse` returns the texel at
  the pixel (`fa_ct_vp*` project the world position, `fa_ct_a.zw` is the image size, `fa_ct_a.y` flips the rows on GL) before it reads the
  lightmap or the grids, and the existing code multiplies it by the albedo and the occlusion. The branch changes only `fa_indirect_diffuse`,
  and the `fa_mesh_fs_params` block grew by one `vec4` (`fa_gi_px`) in `mesh_common.glsl` and `mesh_full_common.glsl`. `fill_fs` sets `fa_gi_px.x` once the draw's
  baked light is known, so a baked lightmap or baked light probes (`fa_probe_sh[0].w > 0`) keep priority, and only for a draw the prepass drew
  (`prepass_draws_part`, the function `prepass_pass` skips with, so the two never differ: the image holds the surface of the prepass at each pixel, and a
  draw it skipped would read the one behind it) that is not a terrain node or an impostor card (`gi_pixel_receiver_for`). The full-shader materials
  (their own template), blended draws and the meshes the subsurface pass scatters (`ctx.sssOn && sss_scatters`: that pass runs before the main
  pass and lights its A image with the probes, and its delta `strength * (blur(A) - A)` is added over that same light) keep the probes and the
  ambient. The image is read with a texel fetch on the `fa_env_smp` sampler of the lightmap slot, not a dedicated nearest sampler: a new
  (view, sampler) pair would be the 17th of the mesh shader and WebGL2/GLES3 allow 16. The denoiser's RGBA16F image is always filterable; the
  kernel's own RGBA32F one is bound only where `pixel_format_caps(Rgba32F).filter` is true, else the draws keep the probes (`fa_gi_px` 1 only
  where the view was bound) and `giPixel.active` is false with the reason saying so (`rtGiPixelFrame.bound`).
- **Free when off.** Without `perPixel` (or `enabled`, or a device that traces) `plan_job` asks for no prepass normals, declares no pass, and
  `rt_begin_frame` lets the image and the denoiser slot go through the usual sweep; `fa_gi_px` stays 0 and the lightmap slot keeps what it had.
- **Fallback** (counted in frames, `frameSerial`, never in time). A failed `add_pass` (the kernel or the image refused, the request invalid) sets
  `rtGiPixelFallbackUntil = frameSerial + kGiRtRetryFrames` (120) at once and logs once at WARN (`rtWarnedGiPixel`). A pass that was declared but
  did not run (`img->ran` false: no TLAS, the atlas not valid) counts `rtGiPixelMisses`; at `kGiRtMissFrames` (2) in a row it starts the same
  fallback. While the fallback runs `plan_job` does not declare the pass and the lit shader keeps the probes and the ambient; after it the rays are
  tried again. `rt_gi_pixel_finish` (after the graph has run) sets the status; `ray_tracing_gi_pixel_status` reads it under `rtGiStatusMutex`.
- **Status.** `render.ray_tracing` answers `giPixel {active, wanted, reason}` (`Engine::ray_tracing_status`): `active` is true when the last frame's
  pass ran and the main pass bound its image (`rtGiPixelFrame.bound`). `gi = "perPixel"` also counts for `active` of the whole setting.
- **Limits and what was not measured.** Not made: the kernel in a second camera, the terrain's own bounce, a recursion deeper than one traced
  bounce, a debug view of the raw image. The D3D12 and Vulkan kernels (DXIL, SPIR-V in `rt_gi_pixel.rt.h`) were compiled by DXC and never ran. On
  Metal the kernel is compared with a CPU reference; the picture-level test shows a lit wall's colour on a white floor with the mode on.
  Whether the Apple GPU compiler accepts the early return of `fa_indirect_diffuse` on every driver is verified by the render tests on the Mac only.
- **Tests.** `rt_gi_pixel_tests.cpp`: the HLSL, MSL and C++ field lists of the constants (sizes 672), the spec row and the bindings of every
  backend, one `intersection_query` site, the pass sequence (`rt-gipixel` after `build_tlas`, before the denoiser and `begin_pass 'game'`),
  free when off, the fallback with `RecordingDevice::inject_faults` (a refused pipeline at once, a TLAS that never comes after two frames,
  the retry after 120), a device that cannot trace, determinism (two runs record the same stream), the `giPixel` status, and the two GLSL
  blocks. `rt_gi_pixel_metal_tests.cpp`: the kernel on the real GPU against the CPU port of the same rays (about 2000 pixels of a floor and a box,
  worst error 1e-4; a normal with n.z of 1e-8 picks one of two tangent frames, so the test accepts either), the sky pixels at zero, two runs with the
  same bytes, another seed, and a far grid that changes nothing. `rt_gi_pixel_picture_tests.cpp`: a grey floor beside a red wall under a black sky,
  through the renderer: with `perPixel` the floor beside the wall turns red (0.22 to 0.29 on Metal), the farther floor less, and turning the mode off
  gives the first picture back bit for bit; a device that cannot trace skips it.

## Ray Reconstruction (P4b-2)

DLSS Ray Reconstruction takes the signal through `DenoiseSignal::enabled = false` in the `denoise` lambda. `build_graph` asks
`Renderer::Impl::rr_signals` once per frame, before any RT pass is recorded (`DrawContext::rr`); it answers `{asked, reflections, gi, why}` from the
state `vendor_upscale` draws with, and the per-pixel GI is taken only if the device filters a 32-bit float image (`pixel_format_caps(Rgba32F).filter`: the
main pass binds the noisy RGBA32F image, and a device that cannot filter it keeps the engine's 16-bit denoised one; `DeviceInit::recordingFilterFloat32`
lets the tests choose). The decision is remembered (`rrSignalsFrame`, `rrSignalsDeclared`), `vendor_upscale` records whether Ray Reconstruction drew
(`rrDrewFrame`), and `rrSignalsLost` keeps the signals with the engine when a frame was handed them and not drawn by it. `rt_gi_pixel_finish` publishes the
result as `RtDenoiserStatus` (`ray_tracing_denoiser_status`, `render.ray_tracing` `denoiser`). Free denoiser signal ids: 8 and up
(7 is this one, 6 the local shadows). Never run on NVIDIA hardware (docs/UPSCALING_VENDORS.md, "DLSS Ray Reconstruction").
