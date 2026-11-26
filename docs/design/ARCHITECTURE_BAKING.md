# FactorIA architecture: baked lighting (the CPU baker)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page). This page describes the core of the lightmap
baker of M73.4: `engine/scene/include/fa/scene/lightmap_bake.h` and `bvh.h`, with `src/lightmap_bake.cpp` and `src/bvh.cpp`. It is
plain data in and float buffers out: no renderer, no file format and no command (the lightmap runtime and the UV generation landed in M73.4a, [ARCHITECTURE_RENDERING_LIGHTING.md](ARCHITECTURE_RENDERING_LIGHTING.md),
"Lightmaps"; the `lightmap.bake` commands that write the files, the light probes and the GPU bake (M79) are the last sections).

## The pieces

- **`TriBvh` (`bvh.h`).** A bounding volume hierarchy over triangles (three points each, copied in). The tree depends only on the
  triangles: a median split on the longest axis of the centroids, ties broken by triangle index. `closest()` gives the nearest hit
  (distance, triangle, barycentric weights), `occluded()` stops at the first one, `nearest()` is the distance only. Both faces
  are hit and a triangle with no area is left out. The model texture maps (`model_texture_maps.cpp`, ambient occlusion and
  thickness) use the same class, so their results did not change when it was promoted from `src/`. (`engine/physics` has
  another BVH, for shapes; the scene module is below physics and does not use it.)
- **`BakeScene`.** Meshes in world space (positions, optional normals, one lightmap UV per vertex that is 0..1 of its atlas, a
  material per triangle), materials (`albedo` 0..1 and `emissive` radiance), lights, the atlas sizes and a sky. A mesh with
  `atlas = -1` only shadows and bounces; `castsShadow = false` only receives. `validate_bake()` checks all of it and names the
  field with a JSON-pointer-like path (`/meshes/2/lightmapUv/17`) and what to change.
- **`bake_lightmap(scene, settings)`.** One `BakedAtlas` per atlas: `rgb` (three floats per texel, row 0 first; v = 0 is row 0),
  a `mask` (`kBakeEmpty`, `kBakeBaked`, `kBakeDilated`) and counts, plus `BakeStats` (texels, rays, the budgets used).
  `hash_bake_result()` is a 64-bit hash of every bit of it, for tests and logs.
- **`sample_irradiance_sh(scene, points, settings)`.** The light around each point as nine spherical-harmonics coefficients
  (`ShL2`, bands 0..2; the first four are an L1 probe) from the same tracer; `sh_irradiance(sh, normal)` evaluates the diffuse
  light for a normal (the radiance convolved with the clamped cosine). The probe grid and the mixed lights are a later package.
- **Helpers.** `dilate_texels()` (the gutter, usable on any atlas), `suggest_atlas_size(area, texelsPerMeter, maxSize)`.

## Units

A texel value is the light a white diffuse surface shows: the runtime multiplies it by the albedo. So a sky or an emissive surface
of radiance L lights an open surface with L (the stored value is irradiance / pi), and a directional light of intensity I lights
a surface that faces it with I (the realtime light loop has no 1/pi either). A point or spot light keeps the realtime falloff
`(1 - (d / range)^2)^2` and the realtime cone (a smoothstep from the cosine of the half angle to a quarter of the way to 1) by
default, so the baked and the realtime light of the same lamp match; `BakeFalloff::InverseSquare` gives `1 / d^2` instead. An
area light is a one-sided rectangle with the radiance `intensity`. Colors are linear. +Y is up and the sky is a gradient
(zenith, horizon, ground, scaled by `intensity`) or an equirectangular float image (`u = 0.5 + atan2(z, x) / 2 pi`, `v = acos(y) / pi`)
that replaces it. Emissive surfaces light the others, not themselves.

## The algorithm

1. **Validate and budget.** Settings ranges, atlas sizes (`maxAtlasSize`, the texel density cap), indices, finite numbers, UV range,
   materials, lights and sky. The memory estimate is `texels * 80 + triangles * 320` bytes (the flattened triangle data, the BVH's corners and nodes, and a margin) (probes: 160 per point) in 64-bit
   saturating maths (a 32-bit `size_t` on wasm cannot wrap it) and is compared with `maxMemoryBytes` before anything is allocated.
2. **Flatten.** Corners, shading normals, UVs, face normals (turned to the side the vertex normals point to), materials; the BVH
   over the triangles that cast shadows; `rayEpsilon` (0 = a ten-thousandth of the scene's size, at most 1 cm and for a lightmap at most 1/20 of a texel).
3. **Rasterise each atlas.** A texel belongs to the first triangle (in mesh and triangle order) whose UV triangle covers the texel's
   centre; its barycentric weights place a point on the surface. UVs that overlap are counted (`overlappedTexels`). The covered texels are the work list. The ray budget
   `maxRays` is checked now, before any ray: `texels * (samples * (1 + bounces * (1 + lights)) + shadowSamples * lights)`.
4. **Trace each texel** (the same code serves a probe, from any point and direction):
   - the *direct* light: for every light that is `Baked`, `shadowSamples` points on the light (a disc facing the texel for a sphere
     light, the sun disc for a directional light, the rectangle for an area light), each with a shadow ray; the average of what
     passes, times N.L;
   - the *gather*: `samples` rays with a cosine-weighted direction (a Hammersley set shifted per texel). A ray that escapes adds the sky.
     A ray that hits a surface adds its emission, then (while `bounces` allows) the direct light that reaches the hit point times its
     albedo (`IndirectOnly` lights count here, so a mixed light bakes only what it bounces), and continues with a new cosine-weighted
     direction and the throughput times the albedo. From the second hit on, Russian roulette ends a path with
     probability `1 - max(throughput)` (at least 5 % survive) and weighs the survivors by `1 / p`.
   - `bounces = 0` is direct light, the visible sky and emitters; each further bounce reflects the light once more.
   A shading normal that leans below the face discards the rays that go into the surface.
5. **Post.** A cross-bilateral denoise (`denoiseRadius`, `denoiseSigma`): neighbours in the atlas weigh by distance, by the
   agreement of their normals (cos^8) and planes (in texel spacings of the surface) and by how close their light is relative to the
   light itself, so shadow edges stay. Then the gutter: `dilatePasses` passes copy the mean of the filled 8-neighbours into empty
   texels (`kBakeDilated`). Seams between pieces are not stitched yet.

## Determinism

The rules are those of the jobs (docs/design/ARCHITECTURE_THREADS.md, "Jobs and threads"), and the test case "the same bits with no pool,
one worker and many workers" holds them:

- No `rand()`, no clock, no thread id. Every random number is `hash(seed, atlas, texel, sample, bounce, dimension)`
  (a SplitMix64 finaliser), so a texel gets the same numbers whichever thread traces it.
- Each texel writes only its own slot (colour, mask, position, normal), and the count of rays is the sum of per-chunk
  counts added in chunk order (`parallel_map_chunks`). Chunk bounds depend only on the counts. The denoise reads one buffer and
  writes another.
- Only `+ - * /`, `sqrt`, `floor` and `fa::det` trigonometry and `exp`; the build has no floating-point contraction, so the bits
  are the same on every platform too (not asserted by a committed hash yet).
- Progress and cancel work on batches: the work list is cut into batches of `max(256, count / 40)` texels, each a `parallel_for`
  (chunks of 16 texels; 256 for the denoise, 2 for probes); after each batch the calling thread reports
  `lightmap bake: atlas 1/2, texels 2048/4096 (50%)` through `report_command_progress` (the sink is per thread, so only this
  thread reports) and reads the cancel flag of its `CommandCancelScope`. Every chunk also polls that flag for each texel (the flag is
  per thread too, so it is read once on the calling thread and the pointer is shared). A cancelled bake returns the error
  `cancelled` and no result. Cutting into batches changes nothing in the result.

## Budgets and refusals

`maxAtlasSize` (default 4096), `maxMemoryBytes` (1 GiB) and `maxRays` (5e10) are deterministic work counts, never times. Each refusal is
an `fa::Result` error that names the field, the numbers and what to change, and says that nothing was allocated or traced.

## Not done yet

Textured albedo and emission (a material is one color per triangle), seam stitching, importance sampling of a bright sun in an
HDRI (a very bright small light is noisy; use a directional light for it). The GPU bake (M79) is a preview next to this baker, the last
section of this page.

## The lightmap.bake commands (M73.4c)

`tools/authoring/src/lightmap_bake_job.{h,cpp}` (the bake without the command plumbing) and `lightmap_commands.cpp` (`lightmap.bake`,
`lightmap.bake_start`, `lightmap.bake_status`, `lightmap.bake_cancel`). They live in `fa_authoring`: they write project files, so they are
never in `engine/runtime`. The user page is "Baking" in [RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md).

- **Plan, then execute.** `make_plan` reads the World on the calling (main) thread and makes plain data (`Plan`: meshes sorted by entity id,
  `BakeLight`s, the sky, the options, a settings hash, warnings), so the job never touches the World again and a scene edit cannot reach it.
  `execute` runs on a job thread: geometry per mesh name (the unwrap of `fa/render/lightmap_geometry.h`, once per mesh), a square per
  receiver, the pages, the `BakeScene`, `bake_lightmap`, the writes. It reads the cancel flag of its thread in every stage and reports
  `(phase, progress 0..1, rays)`; the baker's own progress is mapped into 0.12..0.95.
- **Mapping.** Baked -> `Baked`, Mixed -> `IndirectOnly`, Realtime left out (a warning names it). Directional/Point/Spot map one to one
  (the `Light.range` falloff, `falloff` engine or inverse-square, the spot cone, `shadowSoftness` of a PCSS light as its softness). An
  area light is `BakeLightKind::Area` with its `up` taken from the entity's rotation; Disc and Tube are rectangles (the disc a square of
  the same area, `0.8862 * size.x` a side; the tube length by thickness) and the tube gets a warning. The sky: `Auto` is the environment map
  when `SceneSettings.environmentMap` is set, else the ambient colour; the equirect is shrunk to at most 1024 wide and its rotation is
  `environmentRotation + 90` degrees (the baker's `u = 0.5 + atan2(z, x) / 2pi + rotation / 360` against the renderer's `hdri_uv`; the test
  "environment rotation versus hdri_uv" holds it). A physical sky or a sky material falls back to the gradient with a warning.
- **Layout.** Each receiver gets a square of `clamp(ceil(sqrt(area / 0.66) * texelsPerMeter), 8, maxPageSize - gap)` texels (0.66 is the
  fill of an unwrap's charts); a shelf packer puts them on pages (largest first, ties by id), shrinks each page to what it uses and refuses
  more than `kLightmapMaxPages` (256) with the fix. `scaleOffset` is rounded to 6 digits.
- **Files.** Pages are `<stem>.lightmap.<8 hex of hash_bake_result>.<n>.hdr`, so a rebake that changes nothing writes nothing and one that
  changes something never overwrites a page a running game still reads. Pages first (a page already there with the same bytes is kept),
  the manifest last, each through the atomic writer of `fa/core/fs.h`; if any write fails the pages this call made are deleted and the
  error names the path with what to do (close the file in the other program, call again, or pass another `path`). After success the older
  pages of the same stem that no manifest line names are deleted, then every file of the stem named like a bake's (`<stem>.lightmap.<8 hex>.<n>.hdr`
  or `.<8 hex>.probes`) that the new manifest does not use (a page or probe file a previous bake left because it was open on Windows). A file
  that is still open stays for the next bake. The cancel flag is not read while writing: a half-written set is
  worse than a finished bake.
- **Jobs.** `bake_start` calls `make_plan` in the handler (so argument errors and "nothing to bake" are immediate), then
  `jobs::submit`s `execute`; the status fields (state, phase, progress, rays) are written by the job under the job's mutex and read by
  `bake_status`, which waits only when the pool has no worker (`jobThreads` 0: the job runs in that `jobs::wait` or in `jobs::end_frame`); with `jobThreads` "inline" `jobs::submit` runs the whole job inside `bake_start`. A second
  bake of the same manifest while one runs is refused (`busy`). The registry keeps the last 8 finished jobs (`unknown_job` for an older one), plus every done job whose `apply` was not handed over yet (up to 64, until a `bake_status` hands it over). While the
  game runs (`Engine::play_world()`, set by the editor) `lightmap.bake` and `bake_start` are refused (`game_running`: the edit would go to the
  play copy of the scene), and a job that was started before gives `applied: false` with a note. `Engine::Impl::shutdownHooks`
  (run at the start of `Engine::shutdown`) cancels running bakes, so closing the editor never waits for a trace.
- **Hand-over.** The first `bake_status` that sees `done` sets `SceneSettings.lightmaps` (when `apply` and the engine's current scene is still
  the scene the plan was made for) and calls `Renderer::reload_asset(manifest)`; `handOver` in the answer says what happened. The editor
  passes `apply: false` and edits the setting itself with `edit_command` (an undo step, a dirty scene), after checking that its own open
  scene is still the one the job started on and that the game is not running.
- **Determinism.** `texelsPerMeter`, the scene and the settings give the same pages with any number of threads (the tests bake with 1 and 4
  workers and compare the bytes). The settings hash quantises floats to 1e-4.

## Light probes and mixed lights (M73.4d)

User page: [RENDERING_LIGHT_PROBES.md](../rendering/RENDERING_LIGHT_PROBES.md). Code: `engine/scene/{include/fa/scene,src}/light_probes.{h,cpp}` (data, file,
interpolation), `sample_probes` in `lightmap_bake.cpp`, the `probes` phase in `tools/authoring/src/lightmap_bake_job.cpp`, the runtime in
`engine/render/src/render_scene.cpp` and `renderer_draw.cpp`, the shaders `mesh_common.glsl` and `light_loop.glsl`.

- **Probe radiance.** `sample_probes(scene, points, settings, progress)` traces `samples` rays per probe (hash seeds from the probe index, never a
  thread index: the same bytes with 1 and 4 workers), adds the direct light of the `Baked` lights (a probe has no lightmap texel) and the bounce of
  `IndirectOnly` ones, and projects the radiance to ShL2 (nine RGB coefficients, `c[0] = L * sqrt(4 pi)`). A probe is `valid` unless more than
  `probeBackfaceTolerance` (0.25) of its rays first hit a back face: it is inside geometry and its SH is zeros. Progress is phase `Probes`.
- **Groups and file.** `add_probe_group` appends the grid (`axis_count(size, spacing)` per axis, centred at entity position + `offset`) and the
  points of a component to a `ProbeSet` (`groups`, `positions`, and after the bake `sh` and `valid`). Caps: 16384 grid probes per group, 256
  points, 65536 probes and 4096 groups per scene, each a refusal naming the field. The file is `FAPR` v1 (little-endian, the groups, then the
  positions, SH and flags); `decode_probe_set` checks every count against the size before it allocates (wasm32 safe). The job writes it as
  `<stem>.lightmap.<hash8>.probes` after the pages and before the manifest (the manifest's `probes: {file, count, invalid}`), through the same
  atomic writer and the same clean-up of old files. A bake with only probes (no receiver mesh) is valid; both empty is "nothing to bake".
- **Interpolation.** `probe_light_at(set, p)`: per grid, trilinear over the eight corners with the invalid ones left out and renormalised, times a
  coverage that falls from 1 to 0 over one `spacing` outside the box; a point probe weighs `(1 - d / 5 m)^2`. The groups are summed by weight and
  the mean SH is `ProbeLight.sh`, with `coverage = min(1, total weight)`. `probe_light_key` quantises SH and coverage to 1/1024 into a hash
  (0 = none). `probe_point()` snaps the sample point to a 0.25 m lattice, so nearby meshes share one key and one instanced draw;
  `build_batches` ignores the key for the shadow runs (the shadow pass never reads the SH).
- **Where the per-draw SH lives.** The nine coefficients are `vec4 fa_probe_sh[9]` at the end of `fa_mesh_fs_params` (and its copy in
  `mesh_full_common.glsl`, which must stay the same size): `[k].xyz` is coefficient k, `[0].w` the coverage (0 = no probe). No texture unit is
  added (the mesh fragment shader uses all 16). The CPU computes `probe_light_at` for each `SceneMesh` in the `render.mesh_cull` job
  (`RenderScene::probeLights_`, sized only when baked probes exist) at `probe_point()`: the `probeAnchor` entity's drawn position when alive and active, else
  the centre of the mesh's bounds through its model matrix. Eligible: `receiveGI`, not `unlit`, no lightmap, and a material that is null or
  engine-shaded without compute buffers. `SceneMesh`, `MeshItem` and `SortFields` carry the pointer and `probeKey`, and `probeKey` is part of
  `material_key`, `order_key` and the `Rest` sort key, so the batcher merges only draws with the same SH. `fill_fs` writes the uniform (zeros when
  there is none, so a scene without probes feeds the shader the same bits as before).
- **Shader.** `fa_indirect_diffuse` returns `mix(fa_ambient_light(n), fa_sh_eval(c, n), clamp(cover, 0, 1))` when `cover > 0`; the SH basis and
  constants are the baker's, so a probe and the sky are interchangeable, and a custom `ambient()` hook sees it.
- **Mixed and baked lights.** In the bake `Mixed` is `IndirectOnly` (bounce only) and `Baked` is the whole light; nothing else changes for a
  mixed light at run time. For a `Baked` light the shader's `fa_baked_keep(li)` (`light_loop.glsl`) is 0 on a lightmapped receiver (the old rule),
  `1 - coverage` on a probe-covered one, 1 elsewhere; `keep <= 0` skips the light with no shadow lookup, otherwise the attenuation is
  scaled. `renderer_draw.cpp` treats a receiver the probes cover completely like a lightmapped one when it decides whether the shadow maps of
  baked lights are needed.
- **Runtime query.** `Renderer::light_probes(world)` (the loaded `ProbeSet`) and `light_probes_report(world, entity)` answer `render.light_probes`;
  the editor's probe gizmo (`tools/editor/src/probe_gizmo.cpp`) reads the first.
- **Not done.** No occlusion between a probe and the receiver (a probe through a thin wall counts), no run-time update of the probes, no
  probe specular (reflections stay with the sky and the reflection probes).

## The GPU bake (M79-P5b)

A fast PREVIEW next to the CPU baker, which stays the reference (decision D10: the CPU path is bit-exact, the GPU path has a tolerance).
`lightmap.bake {"device":"gpu"}` (or `"auto"`) runs the path tracer of "The algorithm" as a compute kernel with inline ray queries
(`engine/render/shaders/rt/rt_bake.hlsl` for D3D12 and Vulkan, `rt_bake.metal` for Metal, the generated `rt_bake.rt.h`; the table row is in
`engine/render/src/rt_kernels.h`). The default is `"cpu"`: a bake that must be the same bytes on every machine, a CI golden or a final build
asks for no more, and a GPU image can differ in the last bits between GPUs and drivers.

- **A hook, not a second baker.** `bake_lightmap(scene, settings, progress, tracer)` (`fa/scene/lightmap_bake.h`) takes an optional
  `BakeTexelTracer`. With one, the validation, the budgets, the BVH-free flattening, the atlas rasterization, the progress phases, the cancel, the
  denoise, the gutter and the mask are the CPU's own code; only "the value of each texel" comes from the tracer: `begin(BakeTraceScene)` once
  (the triangles that cast a shadow with their normal, albedo and emission, the lights as plain numbers, the sky, eps, the counts) and
  `trace_atlas(atlasKey, texels, progress, rgb)` per atlas. `fa::render::LightmapGpuTracer` (`fa/render/lightmap_gpu_bake.h`, module render,
  private `fa::gpu` inside) is the one implementation; `fa_scene` knows nothing about GPUs. `BakeStats::rays` is then the budget's upper
  bound (the device does not count).
- **The same random numbers.** The kernel computes the hash of "Determinism" (`mix64`, `combine`, SplitMix64) with 64-bit integers emulated
  as pairs of 32-bit ones, the same Hammersley sequence with the same per-texel shift, the same cosine hemisphere, the same Russian roulette
  from the third hit, the same keys (`combine(atlasKey, texelIndex)`, `0xD1` direct, `0x10000 + s` per gather sample, `0x2000 + depth` per
  bounce). So the GPU image is the CPU image up to float rounding: `sin`, `cos`, the ray-triangle test and a fused multiply-add differ, and
  a path whose rounding flips a Russian roulette draw or a hit differs. On the Apple M5 the Cornell room of the tests has a mean error of
  2e-7 on a mean value of 5.1 (the largest 3e-6); the tests allow 0.5% of the mean and 25% for the largest, so another GPU passes.
- **The scene.** One BLAS of every shadow-casting triangle in the order of the CPU's caster list (a scene with none gets one degenerate
  triangle) and a TLAS of one instance, built once per bake (`maxAccelPrimitives` is checked first: a scene over it says so and the bake
  goes to the CPU or fails). It is the bake's own scene, not the renderer's: same geometry and materials as the CPU, no instance cap, no
  alpha test. Lights, casters (normal, albedo, emission) and the sky image go into two read-only storage buffers; a hit's primitive index is
  the caster's index. Buffers over 256 MiB are refused (64-bit sizes, checked before anything is allocated).
- **Cuts.** The work is cut by COUNTS only, never by time: a dispatch is at most 2^23 "ray units" (texels per dispatch from the work of one
  texel, then the samples per dispatch from what is left), so no dispatch comes near the 2 s after which Windows resets a GPU, and the
  same request is cut the same way on every machine. The kernel writes the direct light (only in the dispatch that starts at sample 0) and the
  SUM of the gather over its samples into an RGBA32F image (two pixels per texel); the CPU adds the sums in order, divides by the number of
  samples and reads one image per dispatch back. Progress (`lightmap bake: atlas a/N, texels d/t`) and cancel are looked at after each
  dispatch; a cancel returns `cancelled`, drops the result and leaves the CPU baker's rules for files (nothing is written).
- **Where it runs.** The tracer opens its own device (`LightmapGpuTracer::open`, one at a time per process): Windows D3D12 then Vulkan,
  Linux and Android Vulkan, macOS Metal through a hidden `HeadlessGpu` context. Sokol is a singleton with one thread: a process that already
  has a graphics context (the editor, a game, an engine without `--no-graphics`) cannot lend it to a bake thread
  (`LightmapGpuTracer::open_needs_helper_process()`: Apple, Metal, a context open). There the texels are traced in a helper process (next
  bullet); D3D12 and Vulkan devices are independent of the window's and trace in the process itself. The commands run the tracer on the job
  thread that bakes.
- **A helper process (editor, MCP, `factoria call` with graphics on a Mac).** The alternatives were a second Metal device inside the process
  (the singleton forbids it), borrowing the window's context (it belongs to the UI thread, and a bake would stall the editor) and
  a service that stays up (state, versions, a thing to stop). A child `factoria session --project <root> --no-graphics --no-scene` is the engine's own
  headless session with an empty world (the bake reads the plan, not a scene: the child loads no scene and runs no script, so a project's start
  scene cannot slow the bake or fail it): no new protocol, the existing job commands do the talking. The parent turns its `Plan` (the data `make_plan` read from the
  world; `plan_to_json` / `plan_from_json` in `lightmap_plan_json.cpp`, checked field by field with JSON pointers) into the argument of
  `lightmap.bake_plan_start`, polls `lightmap.bake_status` every 100 ms and passes the child's phase and progress to its own `report`, and
  on the cancel flag sends `lightmap.bake_cancel`; at the end it sends `session.quit`. The child writes the pages and the manifest with the
  same code (`execute_here`), so the files are the ones an in-process bake writes; `device.process` says `"helper"`. A plan says where the
  job writes, so `lightmap.bake_plan_start` is not a command for callers: it answers only a process that has `FA_LIGHTMAP_HELPER_SESSION=1`
  (`run_in_helper` sets it in the child and nowhere else), refuses with `internal_command` otherwise, and even then checks the plan like an argument:
  `plan_from_json` holds the ranges of `lightmap.bake_start` (`check_bake_settings`, page size, texels per meter), finite floats, probe groups that stay
  inside their positions and grids with `nx * ny * nz` probes, names without `..` or a drive, and the command resolves `manifestProject` with the
  project's write sandbox (`resolve_caller_write_path`, the rule of `x-fa-path: write`): a `.lightmap.json` inside the project that `manifestAbs` names. The child is a
  `fa::ChildProcess`: it is killed with its tree when the parent lets go, a child silent for 15 minutes or one that ignores a cancel for 2
  minutes is killed (the request line carrying the plan is megabytes in a big scene: it is written by a thread of its own, so a child that stopped
  reading cannot block the job: the cancel and the 2-minute limit end the wait, and the child is killed), and a crash or a GPU reset (TDR) in it never reaches the editor: `gpu` fails with the reason (`device "gpu": the helper
  process ended ...`), `auto` bakes on the CPU in the parent with the reason in `device.note`. No `factoria` found (it is looked for in
  `$FA_FACTORIA_EXE`, this program when it is `factoria`, then next to it) is the same case. `FA_LIGHTMAP_HELPER=always|never` forces the choice
  for a process (tests; `always` makes the child fall back to the CPU by itself where it has no ray tracing). The bake that has no lightmap
  texels (only probes) never starts a helper.
- **No device, no failure of `auto`.** `device: "gpu"` with no GPU that traces rays (or a tracer that fails: a scene too big, a refused
  buffer) fails with the reason and the hint `device: "cpu"`; `"auto"` bakes on the CPU (it also leaves out a software
  rasteriser, WARP or lavapipe: `open(allowSoftware=false)`; only `"gpu"` takes one, and no CI test asks for it) and puts the reason in the result's `device.note` and
  `warnings` once. The result's `device` is `{requested, used, name, note, process}`. The `settingsHash` includes the requested device when it is
  not `"cpu"` (the CPU's hash is what it was), so `lightmap.status` calls a GPU preview stale once a CPU bake is asked for. The light
  probes (`sample_probes`) always bake on the CPU, and the result says so in `warnings`.
- **Tests.** `engine/render/tests/lightmap_gpu_bake_tests.cpp`: on a Mac with a tracing GPU the Cornell room of the CPU tests (and a 64 times
  bigger one for the timing) is baked by both, compared texel by texel, baked twice on the GPU (same bytes) and cancelled; the
  RecordingDevice tests refuse a device without ray tracing with a teaching message and run the whole call sequence on one with it. D3D12
  and Vulkan compile the same HLSL with DXC (the blobs are in `rt_bake.rt.h`) and run it nowhere in this suite. The planner is tested for the
  budget (no dispatch over 2^23 ray units, minimum batch included). `tools/authoring/tests/lightmap_commands_tests.cpp`: a tracer of the
  test (`set_tracer_opener`) that fails after N texels (auto bakes on the CPU with the same bytes, gpu fails and keeps the old manifest), only
  probes (note and warning), samples out of range refused, the plan surviving its JSON byte for byte, and (POSIX) a fake `factoria` shell
  script that streams progress, is cancelled, dies or never becomes ready. `tools/cli/tests/lightmap_bake_test.cpp` runs the real child
  (`FA_FACTORIA_EXE`): the device report, progress, cancel, and no process left behind (`process_tree()`); where there is no ray tracing the
  child falls back to the CPU by itself, so the test passes on every CI machine. The editor autotest L4 bakes with Device Auto and GPU
  (on a Mac through the helper). A real GPU ran only on the Mac; D3D12 and Vulkan never.
