# Rendering: the path tracer (M79, package P5a)

A reference mode, not a play mode. With `render.pathTracer.enabled` the main camera shows a progressive, unidirectional path trace of the same
scene instead of the raster's lit colour, accumulated frame after frame while nothing changes, and the command `render.pathtrace` renders it
until it converges and writes a PNG. The point is a ground truth to compare the raster (and the other ray traced effects) against: "is my
lighting wrong, or is it only different from the real thing?". The user-facing description is docs/RAY_TRACING.md, "The path tracer". The
scaffold the kernel runs on is [ARCHITECTURE_RT_EFFECTS.md](ARCHITECTURE_RT_EFFECTS.md); the scene it traces is
[ARCHITECTURE_RT_SCENE.md](ARCHITECTURE_RT_SCENE.md); how the kernels are compiled is
[ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md](ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md).

Code:

- `engine/render/shaders/rt/rt_pathtrace.hlsl` (the kernel and the source of the D3D12 and Vulkan blobs), `rt_pathtrace.metal` (the Metal twin),
  `engine/render/src/shaders/rt/rt_pathtrace.rt.h` (generated: the MSL source and the DXIL and SPIR-V blobs).
- `engine/render/src/rt_pathtrace.h` and `rt_pathtrace.cpp` (what runs on the CPU: the accumulation counter, the reset decision, the constants the
  kernel reads).
- `engine/render/include/fa/render/raytracing.h` and `src/raytracing.cpp` (`PathTracerSettings`, its parse and JSON, `PathTracerStatus`).
- `engine/render/src/rt_effect.cpp`, `rt_kernels.h` (the row of the kernel table), `renderer_draw.cpp` (the pass, the blit over the main pass),
  `gpu.cpp` (`blit_keep_over_pipeline`), `renderer_rt.cpp` (the setting and the status of the renderer).
- `engine/runtime/src/project.cpp` (`render.pathTracer` in factoria.json), `engine.cpp` (`set_path_tracer`, `path_tracer_status`),
  `shot_commands.cpp` (the commands `render.path_tracer` and `render.pathtrace`).

Tests: `engine/render/tests/rt_effect_tests.cpp` (cases named `rt pathtrace: ...`, the RecordingDevice, every host),
`engine/render/tests/rt_pathtrace_metal_tests.cpp` (a real Metal device against a CPU reference, macOS only),
`engine/runtime/tests/ray_tracing_engine_tests.cpp` (the project key, the commands, `render.pathtrace` on a device that traces).

## Free when off

Same rule as every ray traced effect: with `enabled` false no kernel is compiled, no image is made, no pass is declared and no counter exists
(`PathTraceState::clear()` runs when the setting goes off). The renderer asks for the scene's acceleration structures **by itself** when the path
tracer is on (`render.rayTracing.enabled` needs no effect on, nor even to be on): `wantPathTrace` in `plan_job` is what keeps the scene's TLAS
built. A device that cannot trace rays never gets the pass: the frame is the raster one and `render.path_tracer` says why (one `FA_WARN` per
renderer, `rtWarnedPathTrace`, when the device refuses the kernel or the image).

## The pass and its bindings

The fifth row of the kernel table (`rt_effect.cpp`): `{"rt_pathtrace", usesRecords, !usesGbuffer, usesHit, usesTlas, !usesAux, !usesLocal,
readsOut, usesLights}`. The pass is `<job>/rt-pathtrace`, declared after `<job>/rt-accel` (the TLAS) and the prepass, and read by the main
pass. Two flags are new with it:

- `readsOut`: the output image is a **read and write** storage image (the kernel reads the running mean it wrote the frame before). It needs a
  device that reads RGBA32F storage images; a device that refuses says so through `RtEffectOutput::why`.
- `usesLights`: a third constants block, `RtLightParams` (528 bytes, 33 float4: the count, then position and range, colour and type, direction and
  outer cosine, inner cosine, of up to `kPtMaxLights` = 8 lights).

| resource | HLSL | Vulkan | Metal |
|---|---|---|---|
| the TLAS | `t0` | binding 0 | `buffer(0)` |
| the image (RGBA32F, read and write) | `u0` | 1 | `texture(0)` |
| `RtEffectParams` (400 bytes) | `b0` | 2 | `buffer(1)` |
| the prepass (the raster's depth and normals) | `t1` | 3 | `texture(1)` |
| the per-instance records | `t2` | 4 | `buffer(8)` |
| `RtHitParams` (96 bytes) | `b1` | 7 | `buffer(3)` |
| `RtLightParams` (528 bytes) | `b2` | 8 | `buffer(4)` |

Metal also binds a nearest sampler for the prepass. The uniform slots of the pass are `kUniformParams` 0, `kUniformHit` 1, `kUniformLights` 2
(`rt_effect.h`); a test (`rt pathtrace: the kernel table has rt_pathtrace...`) checks the numbering in every backend.

What the kernel reads of `RtEffectParams`: `frame.x` the index of the first sample of the frame (the samples already in the image, n0), `frame.y`
the seed of the setting, `frame.z` the samples of the frame (m), `frame.w` the indirect bounces (`maxBounces - 1`, low 8 bits) with bit 8 set when
the point and spot lights are used, `user0.x` the firefly clamp. The camera is the **unjittered** one (`uRay*`): the temporal antialiasing's
jitter must not be in a picture that antialiases itself.

## The kernel

One thread per pixel, `m` samples per dispatch, each sample one path of at most `kMaxSegments` = 64 ray segments.

1. **Primary ray.** The sub-pixel position of sample `n0 + i` is the R2 low discrepancy sequence of the sample index, shifted per pixel by a PCG hash
   of the pixel and the seed: the image converges to the antialiased picture and two runs draw the same bits. A primary ray that leaves the scene
   gives `(0,0,0,0)`: the main pass keeps its own sky there. A primary hit that is **farther** than the raster's surface at the pixel (the prepass
   has something nearer: terrain, an impostor, a mesh left out of the traced scene) also gives 0, with a tolerance of
   `(pre.r * 1.02 + 0.05 + slope) * dirLength` so a surface the raster and the rays both draw is not rejected by rounding. This is what stops the
   raster-only objects from disappearing behind the path traced ones: those pixels keep the raster colour.
2. **Direct light at every hit** (`pt_direct`): the lit pass's own formula, `(diffuse + GGX) * colour * N.L` with the same Lambert and GGX terms and
   the same point and spot fall-off, so the two pictures agree where both are right. The **sun** gets one shadow ray (hard shadow); **one** of the
   up to 8 point and spot lights, picked at random with a probability, gets one more (next event estimation). `maxBounces` 1 is direct light only.
3. **Emission** is added where the path meets an emissive surface (`MeshRenderer.emissive`). The analytic lights are not geometry: only the
   direct sampling reaches them, so nothing is counted twice.
4. **Scatter.** With probability `pSpec` the ray goes into the GGX lobe (a visible-normal sample, `ggx_vndf_reflect`, weighted by the environment
   BRDF), else cosine-weighted into the Lambert lobe (weighted by the diffuse colour). **Russian roulette** from the third bounce keeps the
   survival probability from the throughput, so a dark path ends early without bias.
5. **Glass.** An instance flagged refractive (a closed volume, `thickness` above 0, the same record P3b uses) reflects with Schlick's Fresnel or
   refracts with Snell's law with the material's `ior`; inside, the throughput is tinted by Beer-Lambert absorption (`attenuationColor`,
   `attenuationDistance`); a total internal reflection stays inside. At most `kMaxGlass` = 8 interfaces per path; a thin sheet (`thickness` 0)
   is passed through unbent.
6. **Environment.** A ray that leaves the scene adds the environment gradient (the sky) **plus the ambient light**: the ambient acts as a dome of
   light over the scene, so an interior with no light still gets what the raster's ambient term gives it.
7. **Firefly clamp and NaN guard.** A sample with a NaN or an infinity in any channel is dropped (zero), tested on the bits (`0x7F800000`
   exponent), not with `isnan`/`isinf`, which the drivers' fast-math may assume never true. When `fireflyClamp` is above 0 a sample whose
   luminance exceeds it is scaled down to it before it joins the mean.
8. **Output.** `rgb` is the running mean: `n0 > 0 ? mix(old, mean, m / (n0 + m)) : mean`, so the image is always the average of the samples so far
   and a dispatch of `m` samples costs the same as `m` dispatches of one. `a` is 1 where the primary ray hit a surface the raster does not hide,
   else 0. Premultiplied: the blit over the main pass needs no divide.

### The face normal refinement (`pt_refine_normal`)

`rt_hit.hlsli` (shared by the reflections, the translucency and this kernel) finds the geometric normal with two differential rays. On a hit very
near a triangle's edge the two rays can land on different triangles, and the normal falls back to the reverse of the ray direction: a pixel with
87% to 94% of the value of its neighbours, in a thin line along every edge (the first Metal test caught it at the 9-point agreement). The shared
file is left as it is; **the path tracer's kernels** call `pt_refine_normal`, which traces the face normal again with smaller offsets (1/8, then
1/64 of the first) when the first result is the fallback. It lives in the two kernels only, so the reflections and the translucency keep the
numbers their tests pin.

## The accumulation (`rt_pathtrace.cpp`)

`PathTraceJobState` is one counter per camera (job): `started`, the samples in the image, the serial of the `RtEffectImage` they are in, the
hashes of what the image was drawn from, and its size. The effect pass calls the request's `prepare` hook just before it dispatches, and
`path_trace_step` decides the frame, **pure** (no device) so a test drives it:

| reason | when | what the frame does |
|---|---|---|
| `start` | the counter is new, or the setting came back on | samples = 0, dispatch from sample 0 (not counted in `status.resets`) |
| `image` | the image was made again (another serial or size: a resize) | samples = 0, dispatch from sample 0 |
| `camera` | `path_trace_camera_hash` changed (the rays of the unjittered camera, the position) | same |
| `scene` | the TLAS content hash changed (an instance moved, appeared, changed material) | same |
| `settings` | `path_trace_settings_hash` changed (the setting, the hit constants, the lights block) | same |
| (none) | nothing changed | dispatch `min(samplesPerFrame capped by the image, maxSamples - samples)` samples starting at `samples` |
| hold | `maxSamples` samples reached | `RtPrepare::Hold`: no dispatch, the image is kept as it is |

The order of the table is the order of the checks. Every reset but `start` increments `PathTracerStatus::resets` and sets `lastReset`
(the reason of the table: `"start"`, `"image"`, `"camera"`, `"scene"` or `"settings"`), which `render.path_tracer` returns. The hashes are
FNV-1a 64 over the bytes the kernel's picture depends on; the `seed` is part of the settings hash, **the frame number is not**: the same samples
are drawn however many frames it took to draw them, so a run is reproducible (`render.pathtrace` twice gives the same bytes on a device).
A frame the renderer draws with the path tracer on but no TLAS (the scene is empty) dispatches nothing and the raster picture stays.

**The samples a dispatch adds are capped by the image's pixels** (`path_trace_samples_cap`): at most `kPtMaxPathsPerDispatch` (2^24, 16.7 million
paths) divided by `width x height`, never fewer than 1, so a 1080p image adds at most 8 samples a frame and a 4K one 2, whatever `samplesPerFrame`
asks (64 at most). One submit then never runs long enough for a driver's watchdog (a Windows TDR is about two seconds), and the accumulation
spreads the samples over more frames: the picture after N samples is the same, only the number of frames it takes changes. The cap is a pixel
count, never a time. `render.pathtrace` asks for `min(samples, 4)` a frame; on a very big image it gets fewer, still at least one a frame, so its bound of `samples + 64` frames holds.

**The state of a camera is forgotten when it goes.** `PathTraceState::jobs` has one `PathTraceJobState` per camera (`plan.name`), stamped with
the frame that planned it (`lastFrame`); `PathTraceState::purge`, called by `rt_begin_frame`, erases the cameras no frame planned for two
frames, the delay after which `RtEffects::sweep` frees their image. A camera that comes back starts over (`"start"`).

## From the image to the screen

`main_pass` draws the image over the opaque picture with `Gpu::blit_keep_over_pipeline`, a variant of the blit that blends the premultiplied
source over the destination (`One`, `OneMinusSrcAlpha`): where the alpha is 0 the raster's picture stays (a primary ray that missed keeps the
raster's sky), where it is 1 the path traced colour replaces it, and in between (the edge of a silhouette, where some samples hit and some
missed) the two mix. The image is RGBA32F
and 32-bit float textures cannot be filtered on every device, so this pipeline has its own shader (`blitKeepOverShader_`, made on first use,
declared with an *unfilterable-float* texture and a *non-filtering* sampler): the RecordingDevice rejected the first version that shared the
filtering blit's shader. The pass reads the image's resource, so the frame graph orders it after the kernel.

What follows is the raster's own: the post stack and the tonemap treat the path traced colour as the lit colour (it is HDR in the scene's linear
space, drawn into the scene target). The SSAO apply is skipped when the path tracer drew (the occlusion is part of the picture; applying it again
would darken it twice), and so are its passes: a frame whose path tracer pass is declared (`ctx.pathTrace.res`) adds no SSAO passes, and one that
traces the pass also asks no ray traced ambient occlusion (`ctx.rtAo.want` is false while `ptState.status.failure` is empty, so the occlusion
comes back the frame after a device refuses the path tracer). The reflections, the per-pixel GI and the shadows are not skipped: they are other effects' passes (not this package's to drop) and the blended draws over the picture read them. The **blended and glass draws of the raster come after the opaque phase and are drawn again over the path traced
picture** (they are not in the kernel's picture as raster draws): glass the path tracer already refracted shows twice, which is a known limit of
this version.

## The settings and the commands

`render.pathTracer` (factoria.json) and `render.path_tracer` (the command), parsed by `parse_path_tracer_settings` with the pointer of a wrong key
and a "did you mean". Every key has a doc string in the schema:

| key | range | default | |
|---|---|---|---|
| `enabled` | bool | false | the switch |
| `maxBounces` | 1 to 32 (clamped) | 4 | path length; 1 = direct light only |
| `samplesPerFrame` | 1 to 64 (clamped) | 1 | paths per pixel each frame adds |
| `maxSamples` | 0 to 16777216 (clamped) | 0 | the accumulation holds after this many samples per pixel; 0 = never |
| `fireflyClamp` | 0 or more | 0 | 0 = off |
| `lights` | bool | true | next event estimation of the point and spot lights |
| `seed` | 0 to 2^30 | 0 | the noise pattern; the same seed draws the same picture on a device |

A number outside the range is clamped like `raysPerPixel` (never an error); a wrong name or type is an error with the pointer and nothing changes.
A project with the default value writes nothing to factoria.json. `render.ray_tracing` returns the status of the path tracer under `pathTracer`
(`render.path_tracer`'s own object): `supported`, `active`, `samples`, `width`, `height`, `resets`, `lastReset` and `reason`.

**`render.pathtrace`** renders and writes the PNG:

1. It refuses with `unavailable` (and a hint that names `graphics.backend` and `renderer.supports("raytracing")`) when there is no renderer,
   the device cannot trace or the command runs inside a frame (a script callback: the command draws frames itself, and the engine must not draw
   inside one).
2. It saves the path tracer setting and the render scale (`Restore`, a destructor, so also on an error), holds the scale at `scale` (0.25 to 4,
   native size), turns the setting on with `maxSamples` = `samples`, `samplesPerFrame` = `min(samples, 4)` and `maxBounces`, and draws frames
   (`Impl::draw`) until `samples` are in the image. The loop is bounded by a **count**, `samples + 64` frames (the first resize and the scene's
   loading take a few); `timeBudgetMs` is the optional safety net, and the result says `converged: false` when it stopped first.
3. It captures the image of the last frame (no more frames: no more samples), saves a PNG and returns `{path, samples, converged, timeMs,
   device, width, height, maxBounces}` (and `$image` for the MCP clients). `timeMs` is wall time: it is a measure, not a part of the picture.

The picture is what the engine shows: the post stack and the tonemap apply, so the file is **8-bit and tonemapped**. There is no EXR writer in the
engine; a float output would need one (a separate package), and a picture that is already tonemapped is what a person compares anyway.

## Fallbacks

| situation | what happens |
|---|---|
| `graphics=false` | the setting is remembered; `render.path_tracer` says there is no renderer; `render.pathtrace` fails with `unavailable` |
| a device without ray queries (D3D11, OpenGL, WebGPU, a Mac without Metal 3 RT) | no pass, the raster picture; the status says why and names `graphics.backend`; `render.pathtrace` fails with the teaching error |
| the device rejects the kernel or the RGBA32F read and write image | no pass, one `FA_WARN`, the raster picture, `status.failure` (the reason of `add_pass`, or the failure `RtEffects::failure_of("pathtrace")` holds for this effect only; `render.pathtrace` repeats it) |
| the scene has no TLAS (empty, or still loading) | the raster picture for that frame, `active` false |
| a mesh outside the traced scene (terrain, impostors, over `maxInstances`) | the raster draws it; a path traced pixel behind it is dropped by the depth test of step 1 |
| a camera that is not the main camera, a UI-only job | the raster picture (the path tracer replaces the main camera's lit colour only) |

## Limits

These are stated in docs/RAY_TRACING.md too, because they are the first thing a person comparing the two pictures will see.

- **No textures.** The kernel sees the `MeshRenderer`'s flat colour, roughness and metallic (and the glTF material's factors), the same record the
  reflections read; an albedo texture, a normal map and a custom `material` are not evaluated. Against the textured raster a scene looks flatter,
  and with white albedo overexposed (the sun adds at full strength on a surface the raster modulates with a texture).
- **Hard sun shadow only.** The sun is a point at infinity: the shadow's penumbra from `shadowSoftness` is not sampled.
- **Area lights are points** at their centre; a point or spot light has no radius. Only the 8 strongest point and spot lights of the frame are
  sampled; `lights` off removes them all.
- **The ambient acts as a dome**: the ambient colour is added to every escaped ray, so it lights every direction equally and is not occluded by
  the scene's geometry in the sense a probe lighting would be.
- **8-bit PNG output**, tonemapped (see above).
- **The raster glass is drawn again over the picture** (see "From the image to the screen"); with `translucency` on, the P3b image is also read by
  the raster glass shader, which is not what the path tracer shows.
- **Grazing angles.** The depth test of step 1 has a tolerance in the depth; on a wall seen almost edge on it may keep the raster's pixel where
  the rays hit the wall (a thin line, no worse than the raster's own depth precision).
- **A command cannot draw from inside a frame**: `render.pathtrace` from a script callback fails; use it from the CLI, MCP or a tool.
- **Not a game mode.** One sample per pixel and frame is noisy, and a moving camera restarts the image every frame. For play use the raster and
  the other effects of `render.rayTracing`.

## The kernel's compilation

HLSL is the source; `tools/shaders/compile_rt_shaders.sh rt_pathtrace` writes `rt_pathtrace.rt.h`: the MSL source (the Metal twin, compiled by
the driver at run time), the DXIL (DXC, `cs_6_5`) and the SPIR-V (DXC `-spirv -fspv-target-env=vulkan1.2`) blobs. The DXC version is the one
pinned in `setup.h` (1.9.2609). A host without it keeps the blobs that are in the header; the Linux CI regenerates and diffs them, so a kernel
edit without regenerated blobs fails there (`compile_rt_shaders.sh --check`). The blobs of this version were made with the real DXC on the
Windows PC.

**What runs this kernel, and what does not.** Only the Metal kernel has run on a GPU (the tests of `rt_pathtrace_metal_tests.cpp` and the
`render.pathtrace` test of the runtime, on a Mac). **No D3D12 or Vulkan test runs `rt_pathtrace`**: CI checks the blobs only (that they are DXIL
and SPIR-V containers, and that `compile_rt_shaders.sh` regenerates the committed header), never that they trace. The HLSL and the MSL are twins
by construction and by review, not by a comparison of their pictures, so a difference in a D3D12 or Vulkan picture is not caught by any test.

## Tests

`rt_effect_tests.cpp` (RecordingDevice, every host; the case names start with `rt pathtrace:`):

- off declares nothing and costs nothing, with ray tracing on or off;
- on, one compute pass after the TLAS and the prepass, the three constants blocks, the same every frame, the same bytes;
- turning it off frees the kernel and the image, and the accumulation starts over when it comes back;
- a device that cannot trace says so once and the frame is what it would be with the setting off;
- `maxSamples` holds, and a camera move, a moved mesh (the scene) or a setting change restart with the right reason;
- `path_trace_step`: start, hold and each reset reason, in the order of the table;
- the kernel table row and the binding numbering of every backend;
- the settings: the pointer of a wrong key, the clamping, the JSON round trip.

`rt_pathtrace_metal_tests.cpp` (a real Metal device, a CPU ray caster as the reference): a closed room of emitting walls (the geometric series of
the albedo at every bounce count), the sun, a point light and a spot light on a floor and two boxes at one bounce (mean error about 1e-5 to 1e-3
with the 9-point agreement at the triangle edges), and the sky floor of an escaped ray. On a host with no Metal the case says so and passes.

`ray_tracing_engine_tests.cpp`: the project key (loads, round trips, writes nothing at the default, teaches with the pointer), the command
(reads, sets, clamps, refuses without changing anything), and `render.pathtrace` (teaches where no device traces; where one does it writes the
PNG, twice the same bytes, and puts the settings back).

What no test covers: the D3D12 and Vulkan kernels run (compiled with the real DXC, never executed on a GPU), the numbers on
WARP and llvmpipe, and any picture quality measure against the raster (the pictures are compared by eye and by the Metal tests' CPU reference).
