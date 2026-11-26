# Rendering: the ray traced effects (M79, packages P2a-1 and P2a-2)

The scaffold every ray traced effect shares, and the first effect on it, the shadow of the sun (hard, and soft with the denoiser). One effect is one inline ray query compute
kernel that reads the camera's prepass and writes one image; the scaffold declares its pass, binds the same resources for every kernel, owns the
image and the shader, and frees them when the effect stops. Hard shadows (P2a), the ambient occlusion (P2b), the reflections (P3a) and the
translucency (P3b) are rows of one table, not four copies of the same plumbing. The user-facing description (the settings, what is traced, the
fallbacks) is docs/RAY_TRACING.md. The translucency kernel (`rt_refract`, M79-P3b) has its own page,
[ARCHITECTURE_RT_TRANSLUCENCY.md](ARCHITECTURE_RT_TRANSLUCENCY.md). The realtime GI probes (`rt_gi`, M79-P4a), a kernel with its own constants block
and an RGBA16F output, have theirs: [ARCHITECTURE_RT_GI.md](ARCHITECTURE_RT_GI.md). The path tracer (`rt_pathtrace`, M79-P5a; the first kernel that reads
its own output and the lights block) has its own page, [ARCHITECTURE_RT_PATHTRACER.md](ARCHITECTURE_RT_PATHTRACER.md).

Code: `engine/render/src/rt_effect.h` and `rt_effect.cpp` (the scaffold), `engine/render/src/rt_kernels.h` (the kernel table, the blobs),
`engine/render/shaders/rt/rt_shadow.hlsl`, `rt_shadow.metal`, `rt_shadow_pack.hlsl` and `rt_shadow_pack.metal` (the first kernels), `renderer_draw.cpp` (the pass in the frame graph and the
lit pass's use of the image), `engine/render/shaders/mesh_common.glsl` (`fa_shadow_factor`), `renderer_rt.cpp` (the settings and the messages).
The scene's TLAS it traces is [ARCHITECTURE_RT_SCENE.md](ARCHITECTURE_RT_SCENE.md); the seam is
[ARCHITECTURE_RENDERING_RAYTRACING.md](ARCHITECTURE_RENDERING_RAYTRACING.md); how the kernels are compiled and committed is
[ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md](ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md). Tests: `engine/render/tests/rt_effect_tests.cpp`
(the RecordingDevice, every host) and `engine/render/tests/rt_shadow_metal_tests.cpp` (a real Metal device, macOS only).

## Free when off

No shader, no pipeline, no image and no pass exist until `RtEffects::add_pass` is called, and the renderer calls it only for an effect that is on,
in the job that collected the scene (`rtScene.active()`), with the camera's prepass declared. A setting that is off, a job that does not draw the
world, a scene with no mesh, a sun that casts no shadow: none of them reach `add_pass`. When an effect stops asking, its image is freed by
`sweep` two frames after its last use (and the kernels with it, once no image is left); when ray tracing goes off, `release` frees everything.
A kernel the device refused is kept as refused so it is not compiled again every frame.

A device that cannot trace rays never gets here. `rt_begin_frame` (renderer_rt.cpp) says so once ("Ray tracing is on ... but this device cannot
trace rays", WARN) and the frame is the raster one. Nothing else is said for that device: the effect code is not reached, so there is no second
message. A device that does trace but refuses this kernel (no blob for the backend, a compile failure, an image it cannot make or cannot write
from a compute shader) gets one separate WARN, "render.rayTracing.shadows is on but the ray traced shadows cannot run on this device (reason)",
once until the setting goes off and on again (`rtWarnedEffect`), and the sun keeps its cascades.

## The pass in the frame graph

`add_pass` imports the output image into the graph (`<job>/rt-<effect>-image`, RGBA32F, the size of the prepass) and declares one pass named
`<job>/rt-<effect>`:

- reads: the prepass (and the G-buffer's two images when the kernel's spec asks);
- writes: the imported image;
- `after`: `<job>/rt-accel`, the pass that builds the TLAS (an effect never traces a TLAS that is not built).

The execute lambda binds, begins a compute pass, sets the pipeline, the bindings and the constants, dispatches `ceil(w/8) x ceil(h/8)` groups
(the kernels are `numthreads(8, 8, 1)`), and ends the pass. It adds one to `RenderStats::drawCalls`. `RtEffectImage::ran` is cleared at the start
and set only when the dispatch was recorded: no TLAS (the scene has no instance this frame), the prepass image gone or of another size, a
pipeline that is not valid, or a missing records view leave it false. A consumer reads the image only when `ran` is true at the time it draws.
The renderer lists `RtEffectOutput::res` in the reads of the pass that samples the image, so the graph orders and keeps the pass.

## Bindings (the contract of every kernel)

A kernel declares only the resources it reads; the numbers never change. The engine's `Bindings::views` slots:

| Slot | Resource | HLSL (D3D12) | Vulkan (set 0) | Metal |
| --- | --- | --- | --- | --- |
| accel 0 | the scene's TLAS | `t0` | binding 0 | `buffer(0)` |
| view 0 | the output, a storage image | `u0` | binding 1 | `texture(0)` |
| uniform 0 | `RtEffectParams`, 400 bytes | `b0` | binding 2 | `buffer(1)` |
| view 1 | the prepass | `t1` | binding 3 | `texture(1)` |
| view 2 | the scene's `RtInstanceRecord` buffer (kernels with `usesRecords`) | `t2` | binding 4 | `buffer(8)` |
| view 3 | the G-buffer's albedo (kernels with `usesGbuffer`) | `t3` | binding 5 | `texture(2)` |
| view 4 | the G-buffer's material (kernels with `usesGbuffer`) | `t4` | binding 6 | `texture(3)` |
| uniform 1 | `RtHitParams`, 96 bytes (kernels with `usesHit`) | `b1` | binding 7 | `buffer(3)` |

**Metal's buffer numbers.** Sokol numbers the uniform blocks `buffer(0)` to `buffer(7)` and the storage buffers `buffer(8)` to `buffer(23)`, so the
records are `buffer(8)` (a kernel that declared `buffer(2)` fails at pipeline creation, `METAL_STORAGEBUFFER_MSL_BUFFER_SLOT_OUT_OF_RANGE`; no
kernel read the records before the reflections, so the first contract's `buffer(2)` was never run). The acceleration structure is `buffer(0)` and
the constants `buffer(1)`, the same as the table says, because they are not storage buffers.

`rt_effect_shader_desc` builds the `ShaderDesc` of a kernel for a backend from its `RtKernelSpec`: the blob the backend takes (DXIL on D3D12,
SPIR-V on Vulkan, the MSL text on Metal and on the RecordingDevice), `usesRayQuery`, the acceleration structure, the views, the uniform block and,
where needed, the sampler. It is pure (no device is touched), so the tests read the contract for every backend on every host.

**The sampler on Metal.** Sokol refuses a texture view that no texture-sampler pair names, even when the kernel reads it with `read` and has no
sampler parameter (a validation error, `TEXVIEW_NOT_REFERENCED_BY_TEXTURE_SAMPLER_PAIRS`). `rt_effect_needs_sampler` is true for Metal and the
RecordingDevice that stands for it: their `ShaderDesc` gets one sampler slot (`RtEffectBindings::kSampler`) and one pair per texture view, and
the execute lambda binds the nearest sampler there. The MSL kernels have no sampler parameter; the pair only satisfies the validation. D3D12
and Vulkan are bound without one. The RecordingDevice cannot catch this class of error, only a real device can (the Metal test did).

## The constants: `RtEffectParams`

25 float4 (400 bytes), the same struct in C++ (`rt_effect.h`), in every `.hlsl` and every `.metal` file between the lines `// BEGIN RtEffectParams`
and `// END RtEffectParams`; a test compares the three field lists with `kRtEffectParamNames`. A kernel reads the fields it needs.

| Fields | Meaning |
| --- | --- |
| `camera` | xyz: the camera's position (the renderer's space, so a floating origin is already applied); w: 1 for an orthographic camera |
| `lightDir` | xyz: the unit vector from a surface toward the sun; w: 0 |
| `image` | xy: the output size in pixels; zw: 1 / size |
| `frame` (uint4) | x: the frame serial; y: the seed of the frame; z: rays per pixel (1 to 64); w: 0 |
| `rayO0, rayOX, rayOY, rayD0, rayDX, rayDY` | the camera the prepass was drawn with, jitter included |
| `uRayO0 ... uRayDY` | the same camera without the temporal jitter (what history and reprojection use) |
| `viewRight, viewUp, viewBack` | the camera's axes: a view-space normal `(x, y, z)` is `right x + up y + back z` |
| `viewProj0 ... viewProj3` | the rows of the unjittered view-projection matrix |
| `user0, user1` | the effect's own numbers |

A pixel's world position from the prepass's linear depth `d` (its `r`), with `ndc = (2 (x + 0.5) / w - 1, 1 - 2 (y + 0.5) / h)`:

```
pos = rayO0 + ndc.x rayOX + ndc.y rayOY + (rayD0 + ndc.x rayDX + ndc.y rayDY) d
```

The direction vectors are scaled so that their component along the camera's forward axis is 1, so `d` multiplies them as it is. The formula is
exact for a perspective and for an orthographic camera (the origin terms are the ones that move across the image), for both depth ranges, jittered
or not; `fill_rt_effect_camera` fills it and a test checks it against the camera's own matrices. The prepass's `gb` are the octahedral normal in
view space, `a` is 1 on a mesh and 0 on the sky.

`rt_effect_seed(frameSerial)` is a splitmix64 of the frame serial: no wall clock, no `rand()`. The same frame serial gives the same seed on every
machine, so a recorded frame is the same every time (a test records two and compares them).

## The kernel table

`find_rt_effect_spec(name)` returns the `RtEffectKernelSpec` of a kernel of the table in `rt_kernels.h`: whether it reads the scene's records and
the G-buffer. The probe kernel of the tests is not an effect and has no spec.

| Kernel | Effect | Reads | Output (Rgba32F) |
| --- | --- | --- | --- |
| `rt_shadow` | `render.rayTracing.shadows` = hard (`user1.y` = 0) | prepass | r: linear view depth (1e30 on the sky); g: the sun's visibility (1 lit, 0 shadowed); b: 0; a: 1 on a mesh, 0 on the sky |
| `rt_shadow` | `shadows` = soft (`user1.y` = 1), effect `shadows-trace` | prepass | r: the visibility, the fraction of the rays that reached the sun (a multiple of 1 / rays; 1 on the sky); g: linear view depth (1e30 on the sky); b: 0; a: 1 on a mesh, 0 on the sky. The noisy input of the denoiser |
| `rt_shadow_pack` | `shadows` = soft, the last pass | no TLAS (`usesTlas` false); the trace image and the denoised one (`usesAux`) | the hard layout above: r: depth, g: the denoised visibility clamped to 0..1, a: the mesh flag |
| `rt_reflect` | `render.rayTracing.reflections` | prepass, G-buffer, records, `RtHitParams` | rgb: the radiance of the mirror ray times the tint; a: 0 not traced, > 0 the hit distance in metres, -1 a miss |
| `rt_ao` | `render.rayTracing.ao` | prepass | r: the share of the pixel's rays that got out (1 open, 0 closed in; 1 on the sky); g, b: 0; a: 1 on a mesh, 0 on the sky |
| `rt_gi` | `render.rayTracing.gi` = probes ([ARCHITECTURE_RT_GI.md](ARCHITECTURE_RT_GI.md)) | the probe atlas (at the prepass slot), records, `RtHitParams`; its own 1120-byte constants (`paramsSize`) | **Rgba16F** (`outHalf`), 1024 x 132: the new blocks of the probes of this frame, the blend weight in alpha. It is not an `RtEffects` pass: `RtGiProbes` owns it |

To add an effect (P2b, P3a, P3b):

1. Write `rt_<name>.hlsl` and `rt_<name>.metal` with the contract above (the same `RtEffectParams` block, the same algorithm), and run
   `tools/shaders/compile_rt_shaders.sh` (docs/design/ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md) to embed both blobs in the generated
   `src/shaders/rt/rt_<name>.rt.h`; add its row to `rt_kernels.h`.
2. Add its `RtEffectKernelSpec` to `find_rt_effect_spec` (`usesRecords` for the hit's material, `usesGbuffer` for the albedo and the material).
3. In `renderer_draw.cpp`, fill an `RtEffectRequest` (the kernel, the effect name, the prepass, the camera, `raysPerPixel`, `user0`, `user1`) and
   call `rtEffects.add_pass` after the prepass and the G-buffer are declared. List `out.res` in the reads of what samples the image.
4. Extend the tests: the table and the spec, the shader description per backend, the recorded pass and a real Metal comparison.

## The first effect: hard shadows

`render.rayTracing.shadows = "hard"` casts one ray per pixel from the surface toward the sun. The kernel (`rt_shadow`) reads the prepass, rebuilds
the position and the world normal, and starts the ray at `pos + n (user0.x + user0.y d)`: the normal offset is 2 cm plus 2 mm per metre of view
depth (the prepass's depth is as exact as a pixel, so the offset grows with the distance); `TMin = user0.z = 0`, `TMax = user0.w = 10000`
metres; the direction is `lightDir`. It uses `accept_any_intersection` (a shadow ray needs a hit, not the nearest one) and the instance mask
`0x08` (CastsShadow, rt_records.h), so only the instances that cast a shadow in the raster pass block the ray. A candidate that is not opaque (a
cutout material) is never committed: **a cutout casts no ray of its own** (the kernel binds no alpha texture, so it cannot run the alpha test; the
lit pass takes the cascades' shadow too wherever the frame holds one, "No caster loses its shadow" below). A blended caster casts a solid shadow, as it does in the cascades. The brief's "Opaque" mask bit was
not used because it would leave out the casters the cascades draw.

The kernel writes `float4(depth, visible, 0, 1)` on a mesh and `float4(1e30, 1, 0, 0)` on the sky. It puts the depth in `r` so the image can stand
in for the prepass where the contact shadows read depth and the mesh flag (below).

`soft` is the next section; it adds the sun's angular size, several rays per pixel and the denoiser to this kernel.

## Soft shadows (P2a-2)

`shadows = "soft"` runs the same `rt_shadow` kernel with `user1.y = 1`, `raysPerPixel` rays (the renderer clamps the setting to 1..16, the kernel
to 1..64 in `frame.z`) and the sun's size in `user1.x`, the tangent of its angular radius (`SceneSettings.skySunSize` is the diameter in degrees,
0.1..10, default 0.53, so a real sun has a penumbra of well under a pixel unless the setting is raised). Ray `k` of a pixel goes to the point
of the sun's disc `lightDir + (t cos a + b sin a) r tan`, with `r` and `a` from the R2 low discrepancy sequence of `k` shifted per pixel by an
interleaved gradient noise and per frame by the seed (`frame.y`, a hash of the frame serial): the same frame is the same image, a new frame
has new noise for the denoiser to average. A pixel's visibility is the fraction of its rays that reached the sun. A sun of no size is the hard
ray, bit for bit (a test checks it on Metal).

The pass sequence is `rt-shadows-trace` (the kernel, into the persistent image `<job>/shadows-trace`), the `RtDenoiser`'s passes for
`DenoiseKind::Visibility` (rtd-guide, rtd-temporal, five rtd-atrous: [ARCHITECTURE_DENOISE.md](ARCHITECTURE_DENOISE.md)), and `rt-shadows-pack`
(`rt_shadow_pack`, the effect `shadows`, no TLAS: it reads the trace image through `srcImage`, bound where the prepass goes, and the denoised
image as `aux`, binding `kViewAux`). The denoiser keeps its own layout (the visibility in `r`); the pack kernel writes the layout the lit pass reads
(depth in `r`, visibility in `g`, the mesh flag in `a`), so the lit pass and `fa_shadow_factor` do not know which version ran. Hard stays one
ray and no denoiser: no extra pass, no extra image. A denoiser that cannot be used is said once, with its reason, and the sun keeps the cascades.

### No caster loses its shadow

The ray traced shadow sees only what the scene's TLAS holds, and some casters are not in it or cannot block a ray. `RtSceneStats::untracedCasters`
counts, each frame, the parts that cast a shadow in the raster pass and that the rays miss: terrain nodes, impostor cards, meshes drawn from GPU
buffers, parts with no triangles or no vertex buffer, skinned parts over the skinning budget, the farthest instances over `maxInstances`, parts
whose BLAS failed or waits for its build (the instances the frame's `record` found not ready), and cutouts (in the TLAS, but their triangles never
commit a hit). The design is one bit per frame, not a per-pixel mask:

- `untracedCasters == 0`: the lit pass takes the ray traced visibility alone (`fa_ct_b.z` = 0). Nothing casts a shadow that the rays do not see,
  and the rays see no shadow the cascades would not draw (the casters of the TLAS are the ones of the shadow pass).
- `untracedCasters > 0`: the lit pass takes `min(rt.g, cascade)` (`fa_ct_b.z` = 1). The ray traced result keeps its soft or exact edges where it
  is darker; wherever a caster the rays miss shadows the pixel, the cascade shadow darkens it, so that caster keeps its shadow. A cutout's
  shadow is therefore the cascade's (the alpha-tested texture in the shadow map), with the cascades' resolution and seams.

The trade-off: with one untraced caster anywhere in the frame, every pixel of every mesh with a mask also takes the cascade's shadow, so a
soft edge the rays made is hardened wherever the cascade is dark (a cascade shadow is a hard-ish map edge; `min` never lights a pixel the
cascade shadows). A per-caster answer would need the kernel to know which instances are traced for each ray's origin, which is not worth a
second image. The count is of the frame's collected scene, so a frame with no such caster has the pure ray traced shadow, and the cascade passes
stay drawn either way (they are needed for the edges and the other lights). The shadows of the point, spot and area lights are traced by their own
kernels and read the same `untracedCasters` rule: [ARCHITECTURE_RT_SHADOWS.md](ARCHITECTURE_RT_SHADOWS.md).

### The sun's constants and the status

`kRtShadowUser0` (`rt_effect.h`: `{0.02, 0.002, 0.0, 10000}`, the normal offset, its growth per metre of depth, TMin, TMax) is the one set of
constants the renderer and the real Metal test send; `kRtShadowLayoutHard` and `kRtShadowLayoutSoft` are the two values of `user1.y`. The kernels
and the pack kernel are created by `RtEffects` each frame (a pipeline handle is never cached) and a kernel unused for two frames is freed, so
turning soft off frees the trace image and the `rt_shadow_pack` kernel; the `rt_shadow` kernel stays (hard uses it), and the denoiser frees its images
when the soft shadows go off but keeps its shaders until ray tracing is off. When the driver rejects a compute pipeline, or the prepass does
not have the size of the output, the effect does not run: `RtEffects::failure` keeps the reason, the renderer warns once, the lit pass keeps the
cascades and `render.ray_tracing` answers `active: false` with that reason (`Renderer::ray_tracing_failure`). With the shadows or the cascades
off (`doShadows` false or no cascade) no ray pass is made at all.

### How the lit pass uses the image

`main_pass` sets `ctx.screenView`, the screen slot (view 28, `fa_screen_tex`) the contact shadows already read, to the effect's image when it
`ran`; the prepass stands in for it otherwise. Each opaque draw that receives shadows with a program of the engine's template sets
`fa_ct_b.y = 1` when the image is the one bound; a full-shader material and a blended draw never do (a full shader has no cascades to replace and a
blended draw has no prepass depth at the screen slot), so they keep the cascades. `fa_shadow_factor(n, l)` in `mesh_common.glsl`, which only the
directional light of the fragment calls (a test checks that nothing else reads the mask), then:

1. projects the fragment's world position with the unjittered view-projection rows of the lit pass and fetches the texel it lands on (`texelFetch`
   on view 28, no filtering);
2. takes `rt.g` only if the texel holds the same surface: `rt.a > 0.5` and `|d - rt.r| <= 0.002 d + 0.01`, with `d` the fragment's linear view
   depth;
3. otherwise returns the cascades' answer (`fa_shadow_sun`), which is what happens on a silhouette edge, on a pixel the camera's jitter moved
   across, off screen and for a draw that takes no mask.

The cascade shadow passes are still drawn when the mask is on (the fallback and the edges need them, and the point and spot lights keep their
own); turning the cascades off for the sun when the mask is on is an optimisation of a later package. The contact shadows and the screen space
ambient occlusion still read the screen slot where they run (they read depth in `r` and the mesh flag in `a`, which the image holds the same).

### The denoiser hookup

A hard shadow needs no denoiser; the soft one runs it (above). A later effect that does (the ambient occlusion) imports the image the same way: it lists
`RtEffectOutput::res` in the reads of its own pass, samples `RtEffectImage::texture`, and checks `ran` when it executes, as the lit pass does. The
effect's own `user0` and `user1` and the `frame` constants hold what the denoiser needs to be the same every frame (the seed, the serial); the
unjittered camera fields are what its history reprojects with.

## The second effect: ambient occlusion (M79-P2b)

`render.rayTracing.ao = true` replaces the screen-space occlusion (`renderer_ssao.h`, GTAO) of the camera that owns the scene's meshes (the
main camera: the one whose items `RtScene::collect` took) with rays. Per frame and per such camera, in this order:

1. `rt-ao` (the kernel `rt_ao`, `<job>/rt-ao`, after `<job>/rt-accel` and the prepass) writes the noisy visibility: for each pixel `frame.z`
   (`raysPerPixel`, 1 to 16) rays leave the surface in a **cosine-weighted hemisphere** around the prepass's normal, each an inline ray query
   with `RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH` (an occlusion ray needs a hit, not the nearest one), `TMin = user0.w = 0` and
   `TMax = user0.x`, the occlusion radius in metres. The result is `open / count` in `r`.
2. The renderer's denoiser (`RtDenoiser`, `ARCHITECTURE_DENOISE.md`) with `DenoiseKind::Occlusion` and signal id 2 (`kRtAoSignalId`; a camera
   denoises several signals, an effect that denoises another one takes another id) makes it a clean visibility: temporal accumulation along the
   camera's reprojection, then the a-trous filter guided by the prepass. The noisy input is the imported RGBA32F image
   (`DenoiseImage::res` set, `targets` null, `view` = `RtEffectImage::texture`); `RtDenoiser::push_if` adds the read whenever `res` is valid, so
   the graph orders the temporal pass after the kernel even though the image is not a transient. A denoiser that cannot run (its shaders did not
   compile, the histories are over the budget) leaves the noisy image to be applied as it is.
3. The main pass draws `Ssao::draw_apply` after the opaque meshes, as it does for the screen-space occlusion, with the denoised image: the
   visibility raised to `intensity * 1.5` (a gamma scene gets the 2.2th root) multiplied into the picture with a `DST_COLOR` blend. The
   pixels drawn after it (glass, sprites, particles, the HUD) are not darkened. **What it darkens is the whole opaque picture at that
   pixel, as SSAO does today, not only the ambient term**: the lit pass (`light_loop.glsl`) has no separate ambient output to multiply, and
   reusing the apply keeps the look, the debug view `ao` and the intensity the same. A change to darkening only the ambient and indirect light
   is a change of the lit pass and belongs with the global illumination package.

**What replaces what.** The radius and the intensity are the stack's `PostProcess.ssaoRadius` and `ssaoIntensity` when the camera has the
screen-space occlusion on (`ssao_rt_settings`), else the defaults of the component (0.5 m, 1.0); `ssaoQuality` is not read (the ray count is
`raysPerPixel`). No separate radius key exists so one control gives the same look with or without ray tracing. When `ao` is on and the device
traces, the `ssao-*` passes are not declared (the apply still draws, with the traced image). When the device cannot trace, `rt_begin_frame`
says so once and the camera keeps its SSAO if the stack has it, else nothing: `ao` alone does not turn the screen-space effect on. A device
that traces but refuses the kernel says so once (`rtWarnedAo`) and the SSAO passes are declared as if `ao` were off. The main pass applies the traced image only when
`RtEffectImage::ran` is true as it draws (the scene had a TLAS that frame), else the picture is not darkened (SSAO is not drawn in its place:
the graph was built with the other passes).

**Guards of the apply.** The traced image is drawn by the screen-space occlusion's apply, so `Ssao::apply_available` (RGBA16F targets that
render, blend and filter, and `Gpu::ssao_ready()`) is asked before `rt_ao` is declared. A GPU without them says so once (`rtWarnedAo`) and draws
neither effect. The radius is clamped to the SSAO's own range (0.001 to 20 m) and the intensity to 0 to 4, and a NaN falls back to the defaults,
before either reaches the kernel or the power of the apply.

**A frame without the kernel.** The graph is built before it runs, so the denoiser's passes are declared even on a frame where `rt-ao` does not
dispatch (the scene had no TLAS yet: `RtEffectImage::ran` is false). The denoiser then accumulates what the image holds (the last visibility the
kernel wrote, or nothing the first time) into its history, and the main pass skips the apply, so the picture is not darkened. The history of
that frame is not a measurement; the temporal pass's own rejection (disocclusion, camera cut) recovers within a few frames. Gating the
denoiser by `ran` would need a pass that decides when it executes, which the frame graph does not have.

**What occludes.** Instances with the mask `0x03` (`kRtMaskOpaque | kRtMaskCutout`, `rt_records.h`). Blended surfaces (glass, water) let
the ambient light through. An **alpha-tested instance occludes as a solid**: the kernel binds no texture and no records, so the ray is
`RAY_FLAG_FORCE_OPAQUE` (Metal: `forced_opacity::opaque`) and a cutout's whole triangle counts. A leaf card therefore darkens more than its
leaves would; the any-hit alpha test comes with the packages that read the records.

**The sequence.** `state = pcg(x + pcg(y + pcg(seed)))` with the seed of the frame (`frame.y`, a hash of the frame serial), and each ray takes
two draws of the state (`u1`, `u2`, 24 bits each); the rays of a pixel are stratified (`u1` of ray `i` of `n` lies in `[i/n, (i+1)/n)`), the
basis around the normal is Duff's branchless one. The integer sequence is the same in the HLSL and the MSL and is reproduced by the Metal test on
the CPU, so no clock and no `rand()` are involved, and the next frame's seed gives other noise for the denoiser to average.

**Lifecycle.** `Renderer::Impl::rtDenoiser` is empty until the first AO frame (no shader, no history); `rt_begin_frame` sweeps the signals no
camera asked for in the frame before (`sweep(postSerial + 1)`), `RtDenoiser::release` runs when ray tracing goes off or at shutdown, and a resize or a
lost target calls `forget_targets` (`destroy_targets`). The effect image is the scaffold's own (freed two frames after its last use).

**Cost.** One dispatch of `raysPerPixel` rays a pixel, one RGBA32F image of the camera's size (16 bytes a pixel), the denoiser's histories (two
colour images, two moment images and the camera's guide: `make_denoise_plan`) and its fragment passes (a guide pass, a temporal pass and the a-trous
iterations, 5 by default); the three passes of the SSAO are not drawn.

## Determinism

One effect pass depends only on the scene, the camera and the frame serial: the seed is a hash of the serial, nothing reads a clock. The
RecordingDevice test records the frame twice with the same serial and compares the command streams byte for byte. The real Metal test (below)
dispatches the kernel twice and compares the two images.

## Tests

`rt_effect_tests.cpp` runs on the RecordingDevice with ray tracing support recorded (`DeviceInit::recordingRayTracing`), so every host runs it:

- the rays rebuild a pixel's position from the linear depth (perspective and orthographic, both depth ranges, jittered or not), the seed, the
  C++/HLSL/MSL struct equality, the kernel table and the spec;
- the shader description of the kernel per backend (the numbers of the contract in HLSL, Vulkan and Metal numbering, the sampler pairs);
- the lit shader: only `fa_shadow_factor` reads the mask;
- the renderer: with the setting off nothing is declared, made or kept; with "hard" one compute pass is recorded after the TLAS and the prepass
  with `dispatch`, `set_uniforms` of 400 bytes and the right views; the same frame is the same every time; no pass without a casting sun or
  without a light; turning the setting off frees the kernel and the image and ray tracing off frees all; "soft" adds the trace, the denoiser's passes and the pack
  pass (and "hard" none of them), the same frame twice is the same stream; no ray pass is recorded when the shadows or the cascades are off; a rejected compute
  pipeline and a prepass of another size are said once and shown by the status; a frame with an untraced caster (terrain, a cutout, a mesh over
  `maxInstances`, a BLAS not built yet) sets `fa_ct_b.z` for the draws that read the mask, and a frame without them does not (the draw counters
  `RendererTestAccess::rt_shadow_draws`, since the recording does not keep uniform contents); the render scale remakes the image; two cameras
  trace the main one only; a device that cannot trace says so once and draws the raster frame.

`rt_shadow_metal_tests.cpp` (macOS, `#if defined(__APPLE__)`; a placeholder case elsewhere) makes a real Metal device, a scene of a ground, casters and
non-casters, builds the TLAS, runs the kernel and compares the visibility of every sampled pixel with a CPU ray caster, within the pixels at a
shadow boundary; the casters-only mask is checked by moving a non-caster in the way (the pixels do not change); two dispatches give the same image.
It skips, with a reason, on a machine with no GPU, no Metal or no ray tracing. The D3D12 and Vulkan kernels are compiled (DXIL with DXC, SPIR-V) and
checked for the contract by the tests above; they were not run by this package (no device of those backends was available), so their first run is
on the Windows and Linux CI machines that trace.

The same file's soft case runs the kernel with a sun of no size (the hard image in the soft layout, to the bit), three sun sizes against a CPU
reference (the umbra, the fully lit pixels and the count of penumbra pixels, which grows with the size), two seeds (fewer rays change more
between them), the same serial twice (bit-identical) and the pack kernel (the denoised visibility clamped, the depth passed on, the sky). Nothing
of the MSAA depth tolerance of `fa_shadow_factor` (`0.002 d + 0.01 + min(1.5 fwidth(d), 0.1 d)`) runs on a real GPU in this package: a text test
checks the shader.

`rt_effect_tests.cpp` also covers `rt_ao` (M79-P2b): the table, the spec and the shader description of the kernel; the frame with `ao` on (one
`rt-ao` compute pass between the TLAS and the main pass, the denoiser's passes after it, no `ssao-*` pass, the apply still drawn); the same
recorded frame every frame; nothing when `ao` is off (and the SSAO passes still there); `ao` with the sun's shadow (two compute passes); the
image, the kernel and the denoiser freed when the effect stops and when ray tracing goes off; a device that cannot trace keeping the SSAO and
saying so once; a resize making the image again. `rt_ao_metal_tests.cpp` runs the MSL on a real GPU: a ground and a box that occlude, a blended
box (mask `0x04`: does not occlude) and an alpha-tested one (`0x02`: occludes), a prepass made on the CPU, and a CPU hemisphere ray caster that
draws the same rays from the same sequence; every pixel must agree within two of the eight rays (all but a few are bit-exact), the visibility at
the contact edge is lower than far from every box, and two dispatches give the same image while another seed gives another one. D3D12 and Vulkan
have only been compiled.

## Hit shading (`rt_hit.hlsli`, `rt_hit.msli`) and the reflections (P3a-1)

What a ray that ends on a surface sees there is one include, not a copy per kernel: `engine/render/shaders/rt/rt_hit.hlsli` (HLSL) and its
twin `rt_hit.msli` (MSL; a `#include "rt_hit.msli"` line of a `.metal` file is expanded by `compile_rt_shaders.sh` into the blob, and the hash of
both blobs is taken over the expanded text). The reflections use it first; the translucency (P3b), the global illumination (P4a, P4b) and the
path tracer (P5a) are the next readers. A kernel that includes it gets, in one place, the bindings of the part of the contract hit shading reads
and declares the rest itself. `rt_shadow` does not include it and is unchanged.

**Bindings the include declares.** The acceleration structure `g_tlas` (binding 0), the records `g_records` (binding 4, `t2`) and the block
`RtHitParams` `g_hit` (binding 7, `b1`; Metal `buffer(3)`, uniform slot 1). A kernel that includes it asks for them in its table row
(`usesRecords`, `usesHit`), declares `g_out` (binding 1), `RtEffectParams` (binding 2), the prepass (3) and, if it reads the G-buffer, 5 and 6.
MSL has no global resources, so each function takes `tlas`, `records` and `hit` as arguments.

**`RtHitParams`** (96 bytes, the renderer fills it each frame from the scene's settings and the lit pass's sun; `RtEffectRequest::hit`):
`sunDir` (toward the sun), `sunColor` (colour times intensity, 0 = no sun that lights), `ambient`, `sky` (`w` = 1 when the environment is a
texture the kernel cannot read), `horizon`, `limits` (x, y: the shadow ray's offset along the normal in metres and per metre of ray length; z: its
TMax; w: the differential rays' offset as a fraction of the hit distance).

**Functions.**

| Function | Returns |
| --- | --- |
| `rt_trace_surface(origin, dir, tmin, tmax, s)` | `false` for a miss; otherwise the closest surface of mask `Opaque \| Cutout \| Blended` as an `RtSurface`: position, normal, albedo, roughness, metalness, emissive, unlit, distance `t` and the record's index |
| `rt_shade_hit(s, toViewer)` | the colour of the surface: ambient times diffuse, the environment times the environment BRDF, the sun (Lambert and GGX) when a shadow ray (mask `0x08`) finds nothing, plus the emission; an unlit surface is its albedo plus its emission |
| `rt_miss_color(dir)` | the environment's gradient in that direction |

**Limits.** A hit has the record's constants only, no texel (a textured mesh is its flat colour). There is no vertex buffer, so the normal is the
face's: two more rays parallel to the first, offset by `limits.w` of the distance, give two more points of the plane; when they land on another
triangle or instance (an edge, a thin mesh) the surface faces the ray. A cutout is never a hit (its triangles are candidates and the kernels commit
none); a blended mesh is solid. One shadow ray, for the sun only; no fog, decals, probes or second bounce. The Metal twin makes all of a kernel's
rays through one function (`rt_closest_hit`, with an `anyHit` flag for the shadow ray): a second `intersection_query` with other parameters in the
same kernel made Apple's GPU compiler service crash (`XPC_ERROR_CONNECTION_INTERRUPTED` at pipeline creation).

**Using it from a later kernel.** Write `rt_<name>.hlsl` with `#include "rt_hit.hlsli"` first, declare `g_out`, `RtEffectParams` and the views the
kernel reads, call `rt_trace_surface` and `rt_shade_hit`; write the `.metal` twin with `#include "rt_hit.msli"` and pass `tlas`, `records` and
`hit` to the same functions; give the table row `usesRecords` and `usesHit` and fill `RtEffectRequest::hit`; run `compile_rt_shaders.sh`.

### What the reflections do

`render.rayTracing.reflections` runs `rt_reflect` after the TLAS, the prepass and the G-buffer (`<job>/rt-reflections`). It reads the G-buffer's
roughness (material `r`), metalness (`g`) and albedo, and the prepass's depth and normal. Constants: `user0` = (ray offset along the normal in
metres, more of it per metre of view depth, the sharp cutoff 0.25, TMax 10000), `user1.x` = the glossy limit 0.65 (`kRtReflectLimit`,
`renderer_ssr.h`), `frame.z` = rays per pixel. Output (RGBA32F): `a = 0` where nothing was traced (the sky, no G-buffer texel, a surface at the
limit or rougher), `a > 0` the mean hit distance (at least 1e-4), `a = -1` where every ray left the scene (rgb is 0 then); `rgb` is the mean of
the rays that hit, each shaded and times `lerp(1, albedo, metalness)`. The request needs the G-buffer: a frame that draws none keeps the old
reflections and warns once (`rtWarnedReflectGbuffer`), a device that refuses the kernel or the image warns once (`rtWarnedReflect`); both are
re-armed when ray tracing goes off.

**Rays (M79-P3a-2).** Under the cutoff a pixel gets ONE ray along `reflect(view, n)`, as in P3a-1 (a sharp pixel's bits do not change; the Metal
test compares them with the frame without glossy). From the cutoff to the limit it gets `clamp(frame.z, 1, 16)` rays (`raysPerPixel` of the
settings): the directions are GGX visible-normal samples (Heitz 2018, `ggx_vndf_reflect`) with alpha = roughness squared, in the tangent basis of
Duff et al., drawn from a PCG chain seeded by `rt_effect_seed(frameSerial)` and the pixel, with `u1` stratified over the pixel's rays; a sample
that points under the surface takes the mirror direction. Integer hashing and the same sequence of draws make the same frame the same image on
every GPU and on the CPU (the Metal test ports it). Why 0.65: the screen-space march and the probes blur like a rough lobe at little cost, a
few noisy rays do not, and the rays cost the most where the lobe is widest; the traced share is faded out from 0.5 (`kRtReflectFade`).

**The denoiser.** After the kernel the renderer declares two signals of the camera with `RtDenoiser` (ids `kRtReflectSignalId` 3, `Specular`,
and `kRtReflectCoverageSignalId` 4, `Coverage`), both on the kernel's image, the prepass and the G-buffer's roughness. `Specular` is the
radiance, with the hit distance in `a`; `Coverage` reads `a > 0` as 1, else 0 (so the kernel's rgb, a mean of the hits, is averaged over time
as the share of frames that had a hit and the coverage is that share: radiance / coverage is the hit colour). A reflection does not move with
its surface, so both reproject with the virtual position (the point `hit` further along the view ray, behind the mirror) first and with the
surface's motion only where no history pixel passes there, and the a-trous filter weighs pixels by the roughness difference
(docs/design/ARCHITECTURE_DENOISE.md). History resets are the denoiser's (first frame, resize, a gap, another scene, an origin shift, a cut, a
changed kind or settings). If the denoiser cannot run, both are invalid and the composite reads the raw image for every traced pixel.

**The composite** is the screen-space reflections' trace pass (`renderer_ssr.cpp`, `ssr.glsl`): `SsrRtGlossy` carries the denoised images and
the roughness; `b.w` says what is bound (0 none, 1 the raw image only, 2 the denoised ones too). A pixel under the sharp cutoff reads the raw
image (no history: it would lag a reflection that moves unlike its surface); a rougher one reads the denoised radiance and coverage, faded out
between 0.5 and 0.65. The mix is `here * (1 - k * cover) + radiance * k` with the Fresnel weight `k` (capped at `SSR_MAX_MIX`); the rest of the
pixel (`1 - cover`: rays that left the scene, the fade, a pixel not traced) goes to the screen-space march with its mix scaled by `1 - cover`,
and then stays what the lit pass drew (the probes). So there is no seam at either end and no pixel loses its reflection when the traced one is
absent. A sharp ray that misses used to leave the picture alone; it now lets the march look too (when the stack has reflections). A camera
whose stack has no screen-space reflections gets the same pass with intensity 0 (`make_ssr_rt_plan`), which only changes the traced pixels.

**Tests.** `rt_effect_tests.cpp` ("rt reflect: ...", the RecordingDevice, every host): the G-buffer request and the pass when on, nothing when
off, the two denoise signals between the kernel and the composite (and their history freed when off), the fallback on a device that cannot trace
(no kernel, no denoiser), the shader description (the bindings of the table above in HLSL, Vulkan and Metal numbering, including the `RtHitParams`
block) and the `RtHitParams` fields against the HLSL and the MSL. `rt_denoise_tests.cpp` / `rt_denoise_plan_tests.cpp`: the `Coverage` kind
converges to the share of hits, a reflection follows the virtual position when the camera moves, the kind changes the config key (a reset).
`rt_reflect_metal_tests.cpp` (macOS, a real GPU): a mirror floor under a red and a green box and the sky, every traced pixel against a CPU port
of the kernel; the glossy floor (roughness 0.45, 8 rays) and the green box (0.3) against a CPU port of the PCG chain and the VNDF sampler (mean
error under 1% of the mean radiance; measured 4e-6), the same frame twice bit for bit, another seed other rays, the mirror floor unchanged and
the red box (0.8) not traced. D3D12 and Vulkan did not run this kernel (their DXIL and SPIR-V are built with DXC on the Windows PC and checked
for the contract by the tests above); the number of rays is not seen by the RecordingDevice (it does not keep the constants), only by the Metal
test.
