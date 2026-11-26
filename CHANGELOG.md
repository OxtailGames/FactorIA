# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.37](changelog/0.37.md), [0.36](changelog/0.36.md), [0.35](changelog/0.35.md), [0.34](changelog/0.34.md), [0.33](changelog/0.33.md), [0.32](changelog/0.32.md), [0.31](changelog/0.31.md), [0.30](changelog/0.30.md), [0.29](changelog/0.29.md), [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- **Lightmaps bake on the GPU, as a fast preview (M79-P5b):** `lightmap.bake` and `lightmap.bake_start` take `device`: `"cpu"` (the default,
  unchanged and bit-exact), `"gpu"` or `"auto"`. The GPU traces the texels with the CPU baker's own random numbers (the same hash, Hammersley
  sequences, cosine hemisphere and Russian roulette) in a compute kernel with inline ray queries over an acceleration structure of the bake's own
  scene; the validation, budgets, atlas layout, denoise, gutter, progress and cancel are the CPU's code, so the pages have the same format and
  the same light up to the GPU's rounding (mean error 2e-7 on a mean value of 5 in the Cornell room test on an Apple M5). A Cornell room of 98,000
  texels with 64 samples: 5.2 s on the CPU, 45 ms on the GPU. The result's `device` says `{requested, used, name, note}`; `"gpu"` without a GPU
  that traces rays fails with the reason and `"cpu"` as the hint, `"auto"` bakes on the CPU and says why. On a Mac the GPU bake needs a process
  without a graphics context (`factoria call --no-graphics`); D3D12 and Vulkan run next to a window. The Metal kernel is tested on a real GPU;
  the D3D12 and Vulkan blobs are compiled with DXC and run nowhere in the suite. The light probes always bake on the CPU.
  docs/design/ARCHITECTURE_BAKING.md, docs/rendering/RENDERING_LIGHTMAPS.md, docs/RAY_TRACING.md.
- **Ray traced shadows of point, spot and area lights (M79-P2a-3):** with `render.rayTracing.shadows` on, up to three shadow-casting lights per
  camera and frame (the most important by brightness, range and distance; a light keeps its slot with a hysteresis of 25%) get their shadow from
  rays instead of their shadow maps: `hard` casts one ray to the light's centre, `soft` casts `raysPerPixel` rays over the cone of a point or spot
  light (the angular size of its `shadowSoftness`) or to points of an area light's emitter (rectangle, disc, tube), denoised by the `RtDenoiser`
  as one signal (id 6, a light that enters or leaves a slot starts it again). The three visibilities are packed into the image the sun's shadow
  uses and the lit shader reads them (`min` with the map where a caster the rays miss exists, as for the sun); the maps of the traced lights are
  not drawn when nothing else reads them (the volumetric fog's light shafts do: a traced light with `volumetric` above 0 keeps its map while the fog is drawn). Lights beyond the cap keep their maps. Off, or on a device that cannot trace: nothing changes, nothing is
  allocated. `render.ray_tracing` answers `localShadows {cap, candidates, traced}` and its reason says it. The Metal kernel is tested on a real GPU
  against a CPU ray caster; D3D12 and Vulkan have compiled the HLSL with DXC and run it nowhere yet. The committed twins of the render tests'
  fixture materials were regenerated (the mesh template changed). docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RT_SHADOWS.md.
- **Ray traced translucency (M79-P3b):** `render.rayTracing.translucency = true` now draws: a camera that draws glass or a liquid (a mesh with
  `transmission` above 0) casts one ray per pixel through it, bent by Snell's law with the material's `ior` where it enters and leaves the closed mesh
  (up to six interfaces, total internal reflection stays inside) and tinted by Beer-Lambert absorption (`attenuationColor`, `attenuationDistance`);
  a `thickness` of 0 is a thin sheet the ray passes straight through. Where the ray ends, the camera's own picture is read if it shows that surface
  (textures, lights and shadows included), else the kernel shades the hit as the reflections do. `roughness` widens the ray into one cone sample per
  pixel from the frame's seed (the glass shader's own box filter smooths it; no denoiser). It replaces the screen-space refraction per pixel: a pixel
  the kernel did not trace, a device that cannot trace and a mesh outside the traced scene keep it. Glass is in the traced scene (mask `0x40`, traced
  from both sides, still casts a solid shadow and is a solid in a reflection); the instance record grew from 96 to 128 bytes (`volume`, `attenuation`)
  and `rt_trace_surface_mask` was added to the hit include (additive). `render.ray_tracing` counts translucency as active once it draws. The Metal
  kernel is tested on a real GPU against a CPU port; the D3D12 and Vulkan kernels have only been compiled. docs/RAY_TRACING.md,
  docs/design/ARCHITECTURE_RT_TRANSLUCENCY.md.
- **Glossy ray traced reflections, denoised, with a per-pixel fallback (M79-P3a-2):** `render.rayTracing.reflections` now traces rough
  surfaces too: under roughness 0.25 one mirror ray, as before (the same bits); from 0.25 to 0.65 `raysPerPixel` rays (1 to 16) sampled from the
  GGX distribution of visible normals with a deterministic per-pixel sequence from the frame serial. The glossy pixels are denoised by the
  `RtDenoiser` (a `Specular` signal for the radiance and the new `Coverage` kind for the share of pixels whose rays hit), which now reprojects a
  reflection to where the image behind the mirror was (the virtual position along the view ray, by the hit distance) instead of where the surface
  was, and filters only between pixels of a similar roughness. The screen-space reflections' pass composites both: the traced share fades out
  between roughness 0.5 and 0.65 and wherever the rays left the scene, and the screen-space march and the probes fill the rest, so there is no seam;
  a device that cannot trace, a rougher surface and the sky keep the old reflections. A sharp ray that leaves the scene now lets the screen-space
  march look for the reflection (it used to leave the lit picture alone). Off: nothing is made and no denoiser history is kept. The project key
  stays `reflections` (off or on); its description says the new range. The Metal kernel is tested on a real GPU against a CPU port of the sampler
  (mean error 4e-6, the same frame bit for bit); D3D12 and Vulkan have compiled the HLSL with DXC and run it nowhere yet.
  docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RT_EFFECTS.md, docs/design/ARCHITECTURE_DENOISE.md.
- **Ray traced soft sun shadows, and no caster loses its shadow (M79-P2a-2):** `render.rayTracing.shadows = "soft"` now draws: `raysPerPixel` rays
  (1 to 16) per pixel toward points of the sun's disc (its angular diameter is the scene's `skySunSize`, 0.53 degrees by default) with a
  deterministic per-pixel sequence from the frame serial, denoised by the `RtDenoiser` (`Visibility`) and packed into the image the lit pass reads;
  `hard` stays one ray and no denoiser. Terrain, impostors, GPU-driven meshes, cutouts (the ray kernel has no alpha texture), meshes over
  `maxInstances` and meshes whose acceleration structure is not built yet are counted each frame (`RtSceneStats::untracedCasters`): when there is
  one the lit pass takes the darker of the ray traced and the cascaded shadow, so none loses its shadow; with none the ray traced shadow stands
  alone. Point, spot and area lights keep their shadow maps. Also from the review of P2a-1: a compute pipeline the driver rejects and a prepass
  of another size are warned once and `render.ray_tracing` answers `active: false` with the reason; no ray pass is recorded with the shadows or
  the cascades off; the denoiser and the scene release in the opposite order of their making; the shadow depth tolerance follows the surface's
  slope under MSAA; RAY_TRACING.md's image size is 8.3 MB. The Metal kernel is tested on a real GPU (penumbra widens with the sun's size, umbra
  equals the hard result); the D3D12 and Vulkan kernels have run nowhere yet. docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RT_EFFECTS.md.
- **Vulkan ray tracing polish (M79):** a structure copy now barriers at `ACCELERATION_STRUCTURE_COPY_BIT` when the GPU has
  `VK_KHR_ray_tracing_maintenance1` and `synchronization2` (the engine enables the extension itself); tests for a TLAS refit and for two
  builds into one TLAS in one list; the ray tracing tests match the key phrase of a refusal and still require its hint; the
  whole-suite `render` ctest leaves them to `render_vulkan_raytracing`; the status line names the driver only where the driver
  properties exist, and the lavapipe remark only when ray queries are what is missing.
- **Ray traced ambient occlusion (M79-P2b):** `render.rayTracing.ao = true` now draws: with ray tracing on and a device that can trace, the
  main camera casts `raysPerPixel` rays (1 to 16) per pixel in a cosine-weighted hemisphere around its surface normal, up to an occlusion radius,
  and the renderer's denoiser (temporal accumulation and an edge-aware filter) makes the share of rays that got out a clean visibility. It replaces
  the screen-space occlusion of that camera: the result goes through the same apply as SSAO (after the opaque meshes, before glass, sprites and the
  HUD, the debug view `ao` shows it) with the camera's `PostProcess.ssaoRadius` and `ssaoIntensity` (their defaults when it has no SSAO), and the
  `ssao-*` passes are not drawn. Opaque and alpha-tested meshes occlude (**a cutout occludes as a solid**: the kernel reads no texture), blended
  ones let the ambient light through. Like SSAO it multiplies the picture where it draws, so it darkens the direct light too. A device that cannot
  trace, or refuses the kernel, says so once and keeps the camera's screen-space occlusion if it has one. Off, nothing is made. `render.ray_tracing`
  reports `active: true` with `ao` on and says what is traced. The Metal kernel is tested against a CPU hemisphere ray caster on a real GPU; the
  DXIL and SPIR-V kernels are built but have run nowhere yet. docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RT_EFFECTS.md.
- **Ray traced hard shadows (M79-P2a-1):** `render.rayTracing.shadows = "hard"` now draws: with ray tracing on, a device that can trace
  and a sun with `castShadows`, one compute pass per camera casts one ray per pixel from the surface toward the sun against the scene's
  top-level structure (the meshes that cast a shadow in the shadow pass), and the lit pass takes the sun's shadow of an opaque mesh from
  that mask instead of the cascades, wherever the mask holds the same surface; on a silhouette edge, for a full-shader material, a blended
  draw and every other light, the shadow is the one it was (a cutout's rays pass through it: its shadow is the cascade's, M79-P2a-2). The
  cascades are still drawn. `"soft"` is the next entry; a device that traces but refuses the kernel says so once and keeps the cascades.
  Off, nothing is made. The effects share one scaffold (`rt_effect.h`: the pass, the bindings, a 400-byte constants block, the output
  image, freed when the effect stops) that the ambient occlusion, reflections and translucency packages build on. `render.ray_tracing`
  reports `active: true` with the shadows on a device that traces, and its reason says so. The DXIL and SPIR-V blobs are built, the Metal
  kernel is tested against a CPU ray caster on a real GPU; the D3D12 and Vulkan kernels have run nowhere yet. docs/RAY_TRACING.md,
  docs/design/ARCHITECTURE_RT_EFFECTS.md.
- **Ray traced sharp reflections (M79-P3a-1):** `render.rayTracing.reflections: true` traces one mirror ray per pixel for the surfaces
  smoother than roughness 0.25 (a compute pass after the TLAS, the prepass and the thin G-buffer), shades what the ray hits (the sun with a
  shadow ray, the ambient light, the environment gradient, the emission, from the instance's constants: no textures, a faceted normal) and
  blends it into the lit picture where the screen-space reflections feed it, with the same Fresnel weight; rougher pixels, the sky and a
  device that cannot trace keep the screen-space reflections and the probes (a frame with no G-buffer says so once). The kernel also writes the
  hit distance, the denoiser's hook. The shading is one include, `engine/render/shaders/rt/rt_hit.hlsli` (Metal twin `rt_hit.msli`), that the
  later ray traced effects reuse; `render.ray_tracing` reports `active` with `reflections` on. On Metal the records buffer of the effect
  kernels is `buffer(8)` (Sokol's storage buffer range), not `buffer(2)`. Metal runs the kernel against a CPU reference in the tests;
  the D3D12 and Vulkan kernels are built but have run nowhere yet. docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RT_EFFECTS.md.
- **Ray tracing, the shared interface (M79):** `fa::gpu` gains acceleration structures for inline ray queries in compute passes
  (decision: no ray tracing pipelines): `Device::blas_sizes`, `tlas_sizes`, `make_accel_structure`, and `CommandList::build_blas`,
  `build_tlas`, `query_compacted_size`, `copy_accel_structure`. A device that cannot trace rays (OpenGL, GLES3, WebGL2, Direct3D 11, or a
  Direct3D 12, Vulkan or Metal GPU without it) refuses them with a reason that names what is missing, and the `RecordingDevice` made with `recordingRayTracing` records and checks
  them, so the code that builds structures is tested without a GPU. `render.supports` has the rows `raytracing` and
  `raytracingPipeline` (capability only), the project setting `render.rayTracing` (`enabled`, `shadows`, `ao`, `reflections`,
  `translucency`, `gi`, `raysPerPixel`, `maxInstances`; off by default and free when off) and the command `render.ray_tracing` read
  and change it. **No effect draws with rays yet:** turning the settings on changes no picture (Direct3D 12, Vulkan and Metal
  build acceleration structures, below). docs/RAY_TRACING.md, docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md.
- **Ray tracing, the scene's acceleration structures (M79-P1s):** with `render.rayTracing` enabled, an effect on and a device that can trace
  rays, the renderer builds one bottom-level structure per submesh of every mesh the main camera draws (once per mesh asset, compacted
  after the first build, freed when the mesh goes) and rebuilds the top-level structure every frame from meshes, instanced batches and
  foliage (one level of detail per instance; terrain, impostors and the fading-out level of a LOD cross-fade are left
  out). The scene holds at most `maxInstances` instances (or what the GPU allows): over it, the nearest to the main camera stay and the
  log says once how many were left out. A per-instance record buffer (colour, roughness, metalness, emissive, flags; layout shared with
  the kernels) is written beside it, and the floating origin moves the cached records. Off, or on a device that cannot trace, nothing is
  built and the frame is the same (one message says why). Nothing reads the structures yet, so the picture does not change.
  docs/design/ARCHITECTURE_RT_SCENE.md, docs/RAY_TRACING.md.
- **Ray tracing on Metal (M79):** the Metal device (`SokolDevice` on macOS 13 / iOS 16 and later, on a GPU where
  `MTLDevice.supportsRaytracing` is true) reports `rayQuery` and `accelerationStructure`, builds, refits, compacts and clones
  bottom-level structures and builds the top-level one (`MTLAccelerationStructureCommandEncoder` on sokol's command buffer), and a
  compute dispatch of a ray-query kernel binds the TLAS: the shipped `rt_probe` kernel traces two instances and matches a CPU ray
  caster in the tests. A GPU or OS without it refuses with a sentence that names the GPU and the OS. Metal allocates the structures
  itself, so `AccelStructureDesc::storage` is refused there; `bufferDeviceAddress` now means explicit GPU addresses only, and the
  acceleration structure buffer usages no longer need it. Nothing in the frame traces yet. docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md,
  "Metal".
- **Ray tracing, skinned meshes (M79-P1k):** a skinned mesh (an `Animator`) is now in the ray tracing scene in the pose it is drawn in. A
  compute kernel (`rt_skin.glsl`) blends the same four joints with the same palette as the vertex shader into a position buffer, and each
  skinned instance has its own bottom-level structure built from it (never compacted): a refit every frame, a full rebuild every 60 frames
  or when the extent of its bones jumps, freed after the frames in flight when the instance leaves. The scene skins at most 4096 instances
  and 4194304 vertices a frame (the nearest to the main camera stay; the log says once what was left out). The records have a new `Skinned`
  flag. With ray tracing off nothing is allocated or dispatched. `RtSceneStats.skippedSkinned` now counts only what the budget leaves out.
  docs/design/ARCHITECTURE_RT_SCENE.md, "Skinned meshes".
- **Ray query shaders and the DXC toolchain (M79):** the engine's first ray tracing kernel, `rt_probe` (one inline ray query per pixel), is
  written once in HLSL and compiled by DXC to DXIL (D3D12, `cs_6_5`) and SPIR-V (Vulkan, `SPV_KHR_ray_query`), with a hand-written
  MSL 2.4 twin for Metal; the three are committed as `engine/render/src/shaders/rt/rt_probe.rt.h`, so a build needs no DXC. New
  `factoria setup dxc` installs the pinned DXC 1.9.2609 (Windows x64/arm64, Linux x86_64; SHA-256 checked, licences kept, `$FA_DXC_DIR`
  for your own) into `~/.factoria/tools/dxc/`, for contributors who edit those kernels (`tools/shaders/compile_rt_shaders.sh`, with
  `--check`); macOS and Linux Arm are `unsupported` and the install says where the DXIL comes from. The Linux CI job regenerates the
  headers and fails with the regenerated files as an artifact when they are stale; CI also reports lavapipe's and WARP's ray tracing
  support. Design: `docs/design/ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md`.
- **Thin G-buffer (M79-P0c):** the renderer can draw two RGBA8 images of what the camera sees after the depth prepass, the albedo (linear
  colour, alpha 1 where an opaque mesh was drawn) and the material (red roughness, green metalness), for meshes, alpha-tested cutouts, skinned
  meshes, instances and foliage, LOD levels, terrain and impostors; a custom or layered material writes its mesh renderer's own colour,
  roughness and metallic. They exist only while something reads them (no pass, image or shader when nothing does, and the same picture):
  DLSS Ray Reconstruction now takes its roughness and its diffuse and specular albedo guides from them instead of constants, and
  `render.debug_view` has two new views, `albedo` and `material` (`FA_RENDER_DEBUG_VIEW` too). The fixtures of the render tests were made again
  for the new mesh template. docs/design/ARCHITECTURE_RENDERING_GBUFFER.md.
- Internal piece of M79: the renderer's own spatio-temporal denoiser for the ray traced signals (shadows, occlusion, diffuse and specular radiance): temporal accumulation with reprojection and variance-guided a-trous iterations, with its history, debug views and tests; no ray pass uses it yet (docs/design/ARCHITECTURE_DENOISE.md).
- **Direct3D 12 builds acceleration structures (M79):** on a GPU (or a WARP that has them) with DXR tier 1.1 and shader model 6.5, the D3D12
  backend answers `rayQuery` and `accelerationStructure` true. It builds, refits, compacts and clones BLASes and TLASes, takes
  compute shaders as DXIL, binds a TLAS to a ray-query kernel and derives the barriers between builds and traces. On an older GPU
  or driver the device is made as before, and `render.supports` names the adapter, its DXR tier and its shader model instead of
  the package that would bring it. No effect traces rays yet. docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, "Direct3D 12".
- **Vulkan builds acceleration structures and runs ray query kernels (M79):** on a GPU with `VK_KHR_acceleration_structure`,
  `VK_KHR_ray_query`, `VK_KHR_deferred_host_operations` and `bufferDeviceAddress` the Vulkan device turns them on (never a reason
  for device creation to fail) and answers every acceleration structure call: sizes, BLAS and TLAS builds and refits, compaction
  and clones, with the barriers derived by the backend (two builds on one scratch buffer, a TLAS rebuilt while the frame before
  traces it). A compute shader with `usesRayQuery` binds a TLAS, with its DXC bindings moved into the engine's descriptor sets.
  `Features` and `Limits` come from the GPU's acceleration structure properties; a GPU without ray tracing (MoltenVK, lavapipe
  before Mesa 24.1) says what it lacks in `render.supports` and in every refusal. The tests trace on Mesa 25.2's lavapipe in
  the Linux CI job, where `FA_VULKAN_REQUIRE_RT=1` makes a missing feature a failure. docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md,
  "Vulkan".

## 0.38.0

Vendor upscaling, frame generation and low latency (M78): `render.upscaler` modes `dlss` (NVIDIA DLSS Super Resolution through
Streamline, with opt-in Ray Reconstruction), `fsr` (AMD FSR 3.1) and `xess` (Intel XeSS) draw with the vendor SDKs on D3D12 and
Vulkan, `render.frameGeneration` runs DLSS frame generation, FSR 3 frame generation and XeSS-FG behind one seam, and
`render.latency` runs NVIDIA Reflex, AMD Anti-Lag 2 and Intel XeLL next to the engine's own frame pacing. `factoria setup
streamline`, `setup xess` and `setup fidelityfx` fetch the SDKs, device hooks let them take part in the engine's own D3D12 and
Vulkan devices, `render.supports` says why a vendor path cannot run, and the editor's Graphics window and the menu kit's options
offer all of it to players. The vendor paths are tested with stand-in runtimes; they were not run on NVIDIA, AMD or Intel
hardware.

- **Intel XeSS frame generation (M78):** mode `xess` (and `auto` on an Intel GPU) of `render.frameGeneration` now runs XeSS-FG's proxy
  swapchain on Windows, Direct3D 12, an Intel Arc GPU, with `libxess_fg.dll` and `libxell.dll` of `factoria setup xess`. XeLL runs with it
  even when `render.latency` is off (one shared context; a missing `libxell.dll` is refused with the fix), `render.supports` has real reasons
  in `xessFrameGen`, and an SDK failure while it runs is logged once and keeps it off for the run. Not tested on Intel hardware.
  docs/FRAME_GENERATION.md, "XeSS Frame Generation".
- **Frame generation in the editor and the menu kit (M78):** the editor's Graphics window has a Frame generation group (mode combo with
  the unsupported modes greyed out and their reason, minimum base fps slider, the latency advice, the profiler's state) and
  `project.graphics` takes `frameGeneration {mode, minBaseFps}`; the menu kit's options page has a fourth Graphics page with the same
  rows, saved as `settings.graphics.frameGeneration` and applied at each start. The Graphics window reads `render.supports` again only
  when it opens, on Revert and every 10 seconds (it was every 3). The low-latency page has room for longer translations and its
  layout test also runs with every mode unsupported. FRAME_GENERATION.md, MENUS.md.
- **Frame generation seam (M78):** `render.frameGeneration` (project key `render.frameGeneration {mode, minBaseFps}` and the command
  `render.frame_generation`): `mode` off, auto (the GPU maker's SDK), dlss, fsr or xess, and the base frame rate below which generation
  switches off (default 60, back on at 10% above). This package is the seam and no vendor SDK yet: a provider interface with one empty slot
  per SDK (each says which package fills it), the controller (provider choice, refusals that say what to fix, the `minBaseFps` hysteresis),
  and the output stage's hand-off: the picture before the screen-space items is copied, the items are drawn, then the provider is given the
  frame with the depth, motion, camera and jitter of the temporal upscaler. `render.supports` has the rows `dlssFrameGen`, `fsrFrameGen`
  and `xessFrameGen`; the profiler (`perf.profile`, editor Profiler) reports base fps, presented fps, generated frames and the provider or
  the reason (`profile.frameGeneration`). FRAME_GENERATION.md.
- **DLSS Ray Reconstruction, opt-in (M78):** `render.upscaler` has a new `rayReconstruction` flag (project, `render.upscaler`,
  `window.upscaler`; default off). With mode `dlss` on an NVIDIA RTX GPU where Streamline's Ray Reconstruction plugin is installed, the
  renderer draws with DLSS Ray Reconstruction in place of Super Resolution, giving it world-space normals, roughness and albedo guides
  (approximations: the renderer has no ray-traced signals yet, M79 adds them) and the camera's matrices. A machine or frame that
  cannot draw it falls back to Super Resolution with the reason; `render.supports` has the new row `dlssRayReconstruction`.
  docs/UPSCALING_VENDORS.md, "DLSS Ray Reconstruction". Not tested on hardware.
- **DLSS frame generation (M78):** `render.frameGeneration` modes `dlss` and `auto` (on an NVIDIA GPU) now run NVIDIA DLSS frame generation
  through Streamline on D3D12 and Vulkan (RTX 40 series or newer, Windows, hardware-accelerated GPU scheduling on, `factoria setup
  streamline`). The engine tags the depth, the motion vectors and, only when screen-space items are drawn, the picture before them, sets the
  camera constants of each frame and generates one frame between two rendered ones; `generatedFrames` and `presentedFps` come from Streamline's
  own counter. DLSS-G needs Reflex's markers, so Reflex runs while it does, whatever `render.latency` says (the player's mode is not changed).
  A machine that cannot run it says why in `render.supports` and `render.frame_generation` (a GPU or driver Streamline refuses, no plugin, a
  game started with frame generation `off`); an orthographic camera is refused. Verified with a fake Streamline only; needs a check on an
  RTX 40 series machine. FRAME_GENERATION.md, LATENCY.md.
- **FSR 3 frame generation (M78):** `render.frameGeneration` mode `fsr` (also `auto` on an AMD GPU) now generates frames through AMD
  FidelityFX on D3D12 and Vulkan (Windows, any GPU, after `factoria setup fidelityfx`). FidelityFX makes the window's swapchain when the game
  starts with the setting on (`RendererDesc::frameGenerationMode` tells each provider's hook whether to take part); the engine hands it the
  picture before the screen-space items and the depth, motion, camera and jitter of the temporal upscaler, and the swapchain interpolates when
  it presents. Every FidelityFX failure is a refusal with its result code and what to do; the `render.supports` row `fsrFrameGen` is true
  where it can run. FRAME_GENERATION.md, "AMD FSR 3 frame generation".
- **FSR 3.1 upscaler (M78):** the `fsr` upscaler mode now runs AMD FidelityFX Super Resolution on D3D12 and Vulkan (any GPU; `auto` picks it on
  an AMD GPU) once `factoria setup fidelityfx` has installed the SDK. One FSR context per device, made again only when the sizes, quality or
  flags change; the five qualities are FSR's five modes; `render.supports` says why it is unavailable and lists its D3D12 and Vulkan backends.
  docs/UPSCALING.md, "Vendor upscalers".
- **Vendor SDKs for upscaling, frame generation and low latency (M78):** `factoria setup streamline`, `setup xess` and `setup fidelityfx`
  download the redistributable x64 DLLs of NVIDIA Streamline (DLSS, DLSS Frame Generation, Reflex), Intel XeSS (with XeLL) and the
  AMD FidelityFX SDK (FSR) when you ask, pinned by SHA-256, into `~/.factoria/tools/<id>/<version>/` (older versions are removed;
  nothing of them is committed to the repository or bundled). Each shows the vendor's license first and installs only after you accept
  it (`--accept-licenses`, the terminal's `[y/N]`, the editor's license dialog; without it `setup.install` fails with
  `license_required`). A Windows export copies the installed SDKs the project can use next to the game, with their license texts in
  `licenses/<id>/`, as the new `export.pack.vendorSdks` says (`"auto"` by default, `"none"`, or a list of ids; a listed SDK that is
  not installed fails the export naming `factoria setup <id>`). The export's next steps repeat NVIDIA's obligations (notify NVIDIA before
  a commercial release, credits). EXPORTING_SETUP.md, "Vendor SDK licences".
- **Device hooks for vendor SDKs (M78, engine side):** the engine's D3D12 and Vulkan devices let an SDK take part in making the
  device and the swapchain (Vulkan instance and device extensions, feature structs, queues and wrapped functions; D3D12 factory,
  device and queue replaced by wrappers; a swapchain made or wrapped by the SDK; callbacks around every present with a frame id).
  What the machine lacks makes that SDK unavailable with a reason, never the device. The Vulkan swapchain's images now report
  their usage and format to native access, and D3D11's `end_native` clears the context's state. ARCHITECTURE_RENDERING_HOOKS.md.
- **NVIDIA DLSS Super Resolution through Streamline (M78):** `render.upscaler` mode `dlss` now draws with DLSS when Streamline is
  installed (`factoria setup streamline`) on an NVIDIA RTX GPU, on Direct3D 12 and Vulkan (Windows). The engine starts Streamline
  before the device exists (its own declarations of the C interface; no NVIDIA header or binary is in the repository), picks the
  DLSS mode nearest to the quality's upscale ratio, sets the options only when they change and tells DLSS the jitter, depth, motion and
  exposure each frame. What the machine lacks (the GPU, a driver, the library) makes `dlss` unavailable with Streamline's own reason in
  `render.supports`, never the device; `auto` picks DLSS on an NVIDIA GPU; a failing frame turns the mode off for the run and the
  temporal upscaler draws. NVIDIA asks a game to notify it before a commercial release and to credit it. UPSCALING_VENDORS.md,
  "NVIDIA DLSS Super Resolution"; ARCHITECTURE_RENDERING_HOOKS.md, "Streamline runtime core".
- **Intel XeSS Super Resolution (M78):** `render.upscaler` mode `xess` now draws with XeSS 3.x when `libxess.dll` is installed
  (`factoria setup xess`): D3D12 and Vulkan on any GPU, Direct3D 11 on Intel Arc, and `auto` picks it on an Intel GPU. One context is made
  per device and initialised again only when the size, quality or input format changes; a call that fails turns the mode off for the
  run, with XeSS's own reason, and the temporal upscaler draws. The depth and motion XeSS reads come from the preparation pass MetalFX
  uses, now on every GPU backend. UPSCALING_VENDORS.md, "Intel XeSS".
- **Low latency (M78):** `render.latency` (project key `render.latency {mode, boost}` and command) sleeps before the input is read so a
  press reaches the screen sooner: AMD Anti-Lag 2 (Direct3D 12 and Vulkan, Windows), Intel XeLL (Direct3D 12, `factoria setup xess`),
  NVIDIA Reflex (Direct3D 12 and Vulkan, through Streamline), or the engine's own pacing where no SDK runs. `auto` picks the maker's SDK. An
  SDK that cannot start reports why and the pacing runs instead, never a device failure. The profiler (`perf.profile`, editor
  Profiler) shows the input-to-present time, and `render.supports` has the rows `reflex`, `antilag2` and `xell`. LATENCY.md.
- **NVIDIA Reflex (M78):** `render.latency` mode `reflex` (and `auto` on an NVIDIA GPU) now runs NVIDIA Reflex through the Streamline
  runtime of DLSS: Low Latency or, with `boost`, Low Latency Boost, `slReflexSleep` once per frame before the input is read and the PC
  latency markers of the frame, on Direct3D 12 and Vulkan after `factoria setup streamline`. DLSS and Reflex share one frame token;
  the report has Reflex's own simulation-to-present time. A GPU, a driver or a backend without Reflex says why in `render.supports` and the
  engine's own pacing runs. The engine ships no NVIDIA code (its own declarations of the C interface of Streamline 2.14.16). LATENCY.md,
  "NVIDIA Reflex".
- **Low-latency settings in the editor and the menu kit (M78):** the editor's View > Graphics window has a **Low latency** group (mode combo,
  Boost checkbox, a line saying what the mode does on this machine; a mode `render.supports` says cannot run is greyed out with its reason as
  the tooltip) that Saves `render.latency`, and `project.graphics` takes `latency {mode, boost}`. The menu kit's Graphics tab (third page, "Low latency") has
  a Low latency row of mode buttons and a boost switch, hidden or greyed out by `render.supports` like the upscaler modes, saved in
  `settings.graphics.latency` and applied at start. LATENCY.md, "Where to set it".

### Rendering

- **Smaller web, Android and Linux players:** the GLSL text of the built-in shaders (GLSL ES 3.00 and GLSL 4.30, spirv-cross output) is kept
  as one zstd frame per header and dialect, made with the engine's own encoder, and decoded the first time a shader is made: 941,595 bytes
  of GLSL ES text became 158,753 (GLSL 4.30: 889,035 to 157,544). The driver gets the same bytes as before. `compile_shaders.sh` builds the
  packer (`tools/shaders/shader_pack`) itself. The Vulkan probe of the start-up (`gpu_probe.cpp`) names the Vulkan backend only in a build that has it (`FA_VULKAN_BACKEND`).
