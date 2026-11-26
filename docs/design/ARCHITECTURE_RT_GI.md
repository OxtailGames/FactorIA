# Rendering: the realtime GI probes updated by rays (M79-P4a)

`render.rayTracing.gi = "probes"` changes how the probes of the `RealtimeGI` grids (M73, [ARCHITECTURE_RENDERING_PROBES.md](ARCHITECTURE_PROBES.md))
are updated: a compute kernel with inline ray queries replaces the six raster captures of a probe. What the lit shader reads does not change at all:
the same atlas, the same blocks, the same meta texel. The user-facing description (the settings, what is shown by `render.ray_tracing`) is
docs/RAY_TRACING.md, "Global illumination"; the per-grid settings are the doc strings of `RealtimeGI` (`raysPerProbe`, `rtProbesPerFrame`).
`gi = "perPixel"` is not made yet (P4b extends this page; see the last section).

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
   (64, the size of the constants block) and the preset's `quality.realtimeGiProbesPerFrame`. The grids are visited in the order of their entity
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

## Extending it (P4b: `gi = "perPixel"`)

What the next package can reuse: `RtGiProbes` is the pattern for a kernel with its own constants block and output format (add a row to the kernel
table with `paramsSize` and `outHalf`, a pass declared after `rt-accel`); `rt_trace_surface`, `rt_shade_hit` and `RtSurface.front` for what a ray
sees; `gi_grid_light` in `rt_gi.hlsl`/`rt_gi.metal` is the kernel's port of the lit shader's grid sampling (trilinear over the eight probes,
with the backface and Chebyshev visibility weights), so a per-pixel bounce can ask the same function for the light a ray's hit receives; the
atlas is bound as a texture at the "prepass" slot. Free denoiser signal ids: 7 and up (6 is the local shadows). What stays: the key `gi`,
`giProbes` in the status (a `giPerPixel` object next to it), the rule that the lit shader reads the grids unchanged.
