# Rendering: the ray traced effects (M79, package P2a-1)

The scaffold every ray traced effect shares, and the first effect on it, the hard shadow of the sun. One effect is one inline ray query compute
kernel that reads the camera's prepass and writes one image; the scaffold declares its pass, binds the same resources for every kernel, owns the
image and the shader, and frees them when the effect stops. Hard shadows (P2a), the ambient occlusion (P2b), the reflections (P3a) and the
translucency (P3b) are rows of one table, not four copies of the same plumbing. The user-facing description (the settings, what is traced, the
fallbacks) is docs/RAY_TRACING.md.

Code: `engine/render/src/rt_effect.h` and `rt_effect.cpp` (the scaffold), `engine/render/src/rt_kernels.h` (the kernel table, the blobs),
`engine/render/shaders/rt/rt_shadow.hlsl` and `rt_shadow.metal` (the first kernel), `renderer_draw.cpp` (the pass in the frame graph and the
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
| view 2 | the scene's `RtInstanceRecord` buffer (kernels with `usesRecords`) | `t2` | binding 4 | `buffer(2)` |
| view 3 | the G-buffer's albedo (kernels with `usesGbuffer`) | `t3` | binding 5 | `texture(2)` |
| view 4 | the G-buffer's material (kernels with `usesGbuffer`) | `t4` | binding 6 | `texture(3)` |

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
| `rt_shadow` | `render.rayTracing.shadows` = hard | prepass | r: linear view depth (1e30 on the sky); g: the sun's visibility (1 lit, 0 shadowed); b: 0; a: 1 on a mesh, 0 on the sky |

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
cutout material) is never committed: **cutouts do not cast ray traced shadows yet** (TODO P2a-2, where the any-hit alpha test and the records
come in; the first version reads no records). A blended caster casts a solid shadow, as it does in the cascades. The brief's "Opaque" mask bit was
not used because it would leave out the casters the cascades draw.

The kernel writes `float4(depth, visible, 0, 1)` on a mesh and `float4(1e30, 1, 0, 0)` on the sky. It puts the depth in `r` so the image can stand
in for the prepass where the contact shadows read depth and the mesh flag (below).

`soft` is treated as `hard`: the renderer says so once (INFO, `rtInformedSoft`, re-armed when ray tracing goes off) and draws one ray per pixel.
The soft version (the sun's angular size, several rays per pixel and the denoiser) is a later package.

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

A hard shadow needs no denoiser. A later effect that does (the soft shadows, the ambient occlusion) imports the image the same way: it lists
`RtEffectOutput::res` in the reads of its own pass, samples `RtEffectImage::texture`, and checks `ran` when it executes, as the lit pass does. The
effect's own `user0` and `user1` and the `frame` constants hold what the denoiser needs to be the same every frame (the seed, the serial); the
unjittered camera fields are what its history reprojects with.

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
  without a light; turning the setting off frees the kernel and the image and ray tracing off frees all; "soft" says so once; a device that cannot
  trace says so once and draws the raster frame.

`rt_shadow_metal_tests.cpp` (macOS, `#if defined(__APPLE__)`; a placeholder case elsewhere) makes a real Metal device, a scene of a ground, casters and
non-casters, builds the TLAS, runs the kernel and compares the visibility of every sampled pixel with a CPU ray caster, within the pixels at a
shadow boundary; the casters-only mask is checked by moving a non-caster in the way (the pixels do not change); two dispatches give the same image.
It skips, with a reason, on a machine with no GPU, no Metal or no ray tracing. The D3D12 and Vulkan kernels are compiled (DXIL with DXC, SPIR-V) and
checked for the contract by the tests above; they were not run by this package (no device of those backends was available), so their first run is
on the Windows and Linux CI machines that trace.
