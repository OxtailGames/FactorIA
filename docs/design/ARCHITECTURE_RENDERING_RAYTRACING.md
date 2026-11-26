# Rendering: the ray tracing seam (M79)

The user page is docs/RAY_TRACING.md (the settings, the command, what each backend will do). This page is for engine
developers: the vocabulary and the calls that `fa::gpu` gained in package M79 P0a, what each backend answers today, how the
`RecordingDevice` checks them, the `raytracing` rows of `renderer.supports`, the project settings, and the route the Metal
backend takes. Read "The GPU interface" (ARCHITECTURE_RENDERING_GPU.md) first: handles, `Result<T>`, the barrier rule and the
`RecordingDevice` are used here as that page describes them.

**What exists.** The interface: types, calls with refusing defaults, the `RecordingDevice` model and its checks, the
supports rows, the settings and the command; and the Metal backend (package P1m, see "Metal"), which builds acceleration structures
and traces them on a GPU with Metal ray tracing. **No frame pass traces a ray yet** (the settings change no picture). The packages
that come next fill the other backends in (P1v Vulkan, P1d Direct3D 12) and then the effects.

## Decision D1: inline ray query only

Every effect that traces rays is a **compute pass** whose shader binds one top-level acceleration structure and asks it
questions with an inline ray query (`RayQuery` in HLSL DXR 1.1, `GL_EXT_ray_query` in Vulkan GLSL, `intersector<>` in Metal
Shading Language). The shader shades what it hits. There are **no ray tracing pipelines, no shader binding tables, no hit,
miss or ray-generation shaders**. One kernel therefore runs on all three APIs, and the interface needs no pipeline or table
objects: the `Device` and `CommandList` gain acceleration structures and nothing else.

`Features::rayTracingPipeline` exists only so `renderer.supports("raytracingPipeline")` can tell a user that their GPU has
pipelines too; nothing uses it.

## The vocabulary (`gpu/types.h`, `gpu/accel.h`)

`gpu/accel.h` is private to `fa_render`, like the rest of `gpu/`. It holds:

| type | what it is |
|---|---|
| `AccelStructure` (in `types.h`) | the handle (`Handle<AccelStructureTag>`) of a BLAS or a TLAS |
| `AccelKind` | `Blas` (the triangles of one mesh) or `Tlas` (instances of BLASes); `accel_kind_name` |
| `AccelBuildFlags` | `allowUpdate`, `preferFastTrace` (default true), `preferFastBuild` (wins when both are set), `allowCompaction` (BLAS only) |
| `AccelTriangles` | one geometry: vertex buffer, offset, stride, count, format; optional index buffer, offset, type, count; `opaque`; `primitive_count()` |
| `AccelSizes` | `structure`, `buildScratch`, `updateScratch` in bytes (the backend's own, rounded to what its API demands) |
| `AccelStructureDesc` | `kind`, `size`, optional `storage` buffer and `storageOffset`, `label` |
| `AccelInstance` | row-major 3x4 `transform[12]`, 24-bit `customIndex`, `mask`, `opaque`, `cullDisable`, `blas` |
| `BlasBuild`, `TlasBuild` | `dst`, the geometries or instances (borrowed spans), `flags`, `update`, `src`, `scratch`, `scratchOffset` |
| `AccelCopyMode` | `Clone` (same size) or `Compact` |
| `accel_unavailable_reason(Backend)`, `accel_refusal(Backend, call)` | the sentence and the `Error` a device without ray tracing answers |

`types.h` gained:

- `Features::rayQuery`, `accelerationStructure`, `rayTracingPipeline` and `bufferDeviceAddress` (all default false, so a
  backend that does not know them answers false without an edit);
- `Limits::maxAccelInstances`, `maxAccelGeometries`, `maxAccelPrimitives` (the `RecordingDevice` reports 1048576, 4096 and
  2^28; a real backend reports what the API says);
- `BufferUsage::accelBuildInput` (vertex and index buffers a build reads), `accelStorage` (a buffer that holds structures) and
  `accelScratch` (the scratch memory of builds);
- `ShaderDesc::usesRayQuery` and `ShaderDesc::accelStructures[]` (`ShaderAccelStructure`: the slot a compute shader declares);
- `Bindings::accelStructures[]` (up to `kMaxAccelStructureBindings` = 4): the TLASes a compute dispatch binds.

## The calls (`gpu/device.h`)

On `Device` (render thread only, like every `make_*`):

- `ray_tracing_status(std::string* why)`: whether the engine can trace on this device, and one sentence for a player when not.
- `blas_sizes(geometries, flags)`, `tlas_sizes(instanceCount, flags)`: the sizes **before anything is made**, so the caller
  makes the scratch buffer and the structure once and reuses them every frame. They check counts and limits, not buffer
  contents.
- `make_accel_structure(desc)`, `destroy_accel_structure(structure)`, `accel_structure_state(structure)` (named apart from
  `state()` because an overload would hide the others in a derived class, `-Woverloaded-virtual`).
- `accel_alignment()` and `accel_scratch_alignment()`: 256 by default, what D3D12 and Vulkan ask of a storage offset and of a
  scratch offset.

On `CommandList` (outside a pass, on a Graphics or Compute list; an error records nothing):

- `build_blas(const BlasBuild&)`, `build_tlas(const TlasBuild&)`: a full build, or with `update` a refit.
- `query_compacted_size(blas, dstBuffer, dstOffset)`: the GPU writes the compacted size as one little-endian `uint64`.
- `copy_accel_structure(src, dst, mode)`: compaction or a clone.
- `backend()`: the API behind the list, named in the errors.

**Every call is optional.** The defaults of a device without ray tracing return `accel_refusal(backend, call)`:
`gpu: build_blas: <reason>` with a hint that names `renderer.supports("raytracing")`. Nothing is recorded, nothing crashes and
nothing is a silent no-op. `Device::ray_tracing_status` uses `features()` and `accel_unavailable_reason(backend())`; a backend
whose package has landed overrides it to say what its GPU lacks ("this GPU lacks VK_KHR_ray_query").

### The memory model

- A caller asks the sizes, makes the scratch `Buffer` (usage `accelScratch`, at least `buildScratch` or `updateScratch` bytes
  from the offset) and the structure (`make_accel_structure` with `size = AccelSizes::structure`), then builds. A size is never
  guessed: a backend rounds it as its API needs.
- `make_accel_structure` allocates the memory itself when `storage` is invalid. **Open design point, left to P1v and P1d (Metal refuses a valid `storage`, see "Metal"):**
  with a valid `storage` (a buffer with usage `accelStorage`, offset aligned to `accel_alignment()`) the caller sub-allocates
  and may alias structures that are never live together. The `RecordingDevice` validates the buffer, the offset and the range;
  a real backend decides whether to take a `storage` of its own kind of memory (Vulkan: a buffer with the
  acceleration-structure-storage usage and a device address; D3D12: a buffer in the `ACCELERATION_STRUCTURE` state).
- A TLAS **does not keep its BLASes alive**. Destroy the TLAS first, or after the work that traces it has completed (the
  `RecordingDevice` says so: "destroy a BLAS only after the TLAS that names it"). The instances of a `TlasBuild` are read during
  the call and copied; the span is borrowed.
- **Refit** (`update` true) needs a structure built with `allowUpdate` and the same counts: the topology stays, vertices or
  transforms move. `src` invalid or equal to `dst` refits in place.
- **Compaction**: build with `allowCompaction`, `query_compacted_size` into a storage buffer, read it after the frame (an
  asynchronous read), make a smaller BLAS and `copy_accel_structure(Compact)`; the original is destroyed once the copy has run.

### Barriers

The caller records none: the backend derives them, as everywhere in `gpu/`. What it must insert (the list is also the comment
at `CommandList::build_blas` in `gpu/device.h`):

1. Before a build: the vertex, index and scratch buffers it reads or writes are in the build-input or scratch state. D3D12:
   `NON_PIXEL_SHADER_RESOURCE | ACCELERATION_STRUCTURE` read for the BLASes a TLAS build reads. Vulkan: a memory barrier from the
   earlier writes to `ACCELERATION_STRUCTURE_BUILD_KHR`.
2. Between two builds that share scratch, and between a BLAS build and the TLAS build that reads it: a barrier from the
   structure's write to the next build's read and scratch use. D3D12: a UAV barrier on the structure and scratch memory. Vulkan:
   `ACCELERATION_STRUCTURE_WRITE` to `READ | WRITE` at stage `ACCELERATION_STRUCTURE_BUILD`.
3. After a build and before the next dispatch that traces: the write is visible to a compute shader's ray query. D3D12: a UAV
   barrier. Vulkan: `ACCELERATION_STRUCTURE_WRITE` to `ACCELERATION_STRUCTURE_READ` at stage `COMPUTE_SHADER`. Metal: the build
   is its own encoder, ordered before the compute encoder that traces.
4. Before `query_compacted_size` and `copy_accel_structure`: the build that wrote the source has finished.

`accel_structure_state` reports the state the model keeps for a structure (the `RecordingDevice`: not built, built).

## What each backend answers today

| backend | `Features::accelerationStructure` | the refusal says |
|---|---|---|
| OpenGL, GLES3, WebGL2, Direct3D 11 (`SokolDevice`) | false, for good | the API cannot trace rays; use the d3d12 or vulkan backend, or Metal on Apple |
| Direct3D 12 | false until P1d | "the d3d12 backend does not build acceleration structures yet (package P1d of milestone 79)" |
| Vulkan | false until P1v | the same with "vulkan" and "package P1v" |
| Metal (`SokolDevice` on Apple) | true when `MTLDevice.supportsRaytracing` and macOS 13 / iOS 16 (see "Metal"); `rayTracingPipeline` false | on a GPU or OS without it: the GPU and the OS version named, and what Metal needs |
| `RecordingDevice` | what it was made with (`DeviceInit::recordingRayTracing`) | a plain one refuses and says it was made without ray tracing |

`Device::backend()` and `CommandList::backend()` were added (the D3D12, Vulkan and sokol devices override them) so a refusal can
name the API.

## RecordingDevice, with ray tracing (`DeviceInit::recordingRayTracing`)

A `RecordingDevice` made with `recordingRayTracing = true` reports the features and limits above, keeps a pool of acceleration
structures (generations, like every pool), records each call as a command (`BuildBlas`, `BuildTlas`, `QueryCompactedSize`,
`CopyAccelStructure`; `stream_text()` prints them, for example `frame 0 [rt]` followed by the build lines) and **validates**
every call with an error that names the call, the field and what to change (they go to `errors()`, and the call returns the
same error):

- the destination is a live structure of the right kind; the count of geometries is 1 to `maxAccelGeometries` and the triangles
  at most `maxAccelPrimitives` ("N geometries are more than this device's limit 4096 (Limits::maxAccelGeometries)");
- every vertex and index buffer is live, has the usage `accelBuildInput` and holds the range it names;
- the scratch buffer is live, has the usage `accelScratch` and holds the size from the offset ("scratch buffer 'x' has N bytes
  from scratchOffset 0, but this build needs M (AccelSizes::buildScratch)"), with the offset aligned;
- `instances[i].blas` is a live, built BLAS ("instances[i].blas is ... destroy a BLAS only after the TLAS that names it");
- a refit of a structure "built without flags.allowUpdate";
- compaction of a structure built without `allowCompaction`, a compacted target too small, a clone of another size;
- a dispatch that binds a BLAS where a ray query needs a TLAS ("accelStructures[0] is the BLAS 'rock', but a ray query traces
  against a TLAS"), a TLAS never built ("which build_tlas has not built yet"), or a structure bound where the shader declares
  none ("accelStructures[1] is bound but shader ... declares no acceleration structure there");
- a shader that sets `usesRayQuery` on a render shader (ray queries run in compute) or on a device without `rayQuery`, and one that
  declares an acceleration structure without `usesRayQuery`.

The model's sizes are a stand-in, deterministic and monotonic, so tests can reason about them; a real backend answers what its
API says:

- BLAS `structure` = round256(4096 + 64 * primitives + 128 * geometries (+ 16 * primitives with `allowUpdate`)), `buildScratch` =
  round256(1024 + 32 * primitives), `updateScratch` = `allowUpdate` ? round256(512 + 16 * primitives) : 0.
- TLAS `structure` = round256(4096 + 128 * n (+ 32 * n with `allowUpdate`)), `buildScratch` = round256(1024 + 64 * n),
  `updateScratch` = `allowUpdate` ? round256(512 + 32 * n) : 0.

Tests: `engine/render/tests/raytracing_tests.cpp` (the refusals, the model, the misuse cases, the supports rows, the settings) and
`raytracing_frame_tests.cpp` (a frame with ray tracing settings on draws the same passes as before).

## The supports rows (`render_features.cpp`)

`renderer.supports_report()` has two rows, `raytracing` and `raytracingPipeline`, each with a documentation string, a status and
a reason:

- `raytracing` is true when the device has `Features::rayQuery` **and** `accelerationStructure`. `Renderer::supports("raytracing")`
  answers it; so does `render.supports {"feature":"raytracing"}`.
- `raytracingPipeline` is **capability only**: true when the GPU has ray tracing pipelines. Nothing uses it.
- When false, the reason is, in order: the reason the device gave (`FeatureEnv::rayTracingWhy`, from
  `Device::ray_tracing_status`); for a headless run with a `RecordingDevice`, the "no GPU" sentence; otherwise
  `accel_unavailable_reason(backend)`.

`FeatureBackend` folds D3D12 and Vulkan into one `Headless`-like case for the other rows, so the environment gained
`FeatureEnv::gpuBackend` (the real `gpu::Backend`), `rayTracing`, `rayTracingPipeline` and `rayTracingWhy`, set by
`set_ray_tracing_env`; the two rows are decided before the headless check. `feature_report` (the one that lists every backend
at once, for the docs) shows D3D12 and Vulkan as true for both rows, since those backends are meant to bring it.

## The settings and the command (`fa/render/raytracing.h`, `engine/runtime`)

`render::RayTracingSettings` is the `render.rayTracing` object of `factoria.json`:

| field | type | default | notes |
|---|---|---|---|
| `enabled` | bool | false | the master switch; off = free |
| `shadows` | `RtShadows` (`Off`, `Hard`, `Soft`) | `Off` | `rt_shadows_name` |
| `ao`, `reflections`, `translucency` | bool | false | |
| `gi` | `RtGi` (`Off`, `Probes`, `PerPixel`) | `Off` | `rt_gi_name` |
| `raysPerPixel` | int | 1 | clamped to 1..16 (`kRtMinRaysPerPixel`, `kRtMaxRaysPerPixel`) |
| `maxInstances` | int | 65536 | clamped to 1..1048576 (`kRtMinMaxInstances`, `kRtMaxMaxInstances`) |

`rt_any_effect(settings)` is true when `enabled` and any effect is on: the one test the renderer will make before it adds a pass.
`parse_ray_tracing_settings(json, where, base)` reads an object over `base` (a key left out keeps it) and answers a `Result`; a
wrong key, name or type gives an error with the JSON pointer and a "did you mean". Numbers are clamped in 64-bit before they are
narrowed to `int`. `ray_tracing_to_json(settings)` writes every key.

In `ProjectSettings` (`rayTracing`), the project file keeps the object only when it differs from the defaults, so a project that
never touched ray tracing is byte-identical. `Engine` holds the settings (`set_ray_tracing`, `ray_tracing`,
`ray_tracing_status`) and applies the project's at start; `render.ray_tracing` reads and changes them
(`changes_state` capability). **`active` is always false in this version**, because nothing reads the settings yet.

## Metal

Metal is driven by `SokolDevice` (sokol_gfx owns the `MTLDevice`, the queue and the command buffers). Ray tracing
(`MTLAccelerationStructure`, `MTLAccelerationStructureCommandEncoder`, `intersection_query` in the Metal Shading Language) is not in
sokol, and the engine does not patch `external/`. The code is `engine/render/src/gpu/metal_accel.h` (plain C++, included by
`sokol_device.h`) and `metal_accel_apple.mm` (the Objective-C++ half, built with ARC); `SokolDevice` on Metal owns one `MetalAccel`
and forwards the calls to it. There is no new `Backend` value and no second device class: the renderer does not know which API
traces.

- **When it is on.** `SokolDevice` reports `Features::rayQuery` and `accelerationStructure` (and the `maxAccel*` limits) when
  `MTLDevice.supportsRaytracing` is true and the OS is macOS 13 / iOS 16 or later (the MSL 2.4 the kernels are written in).
  Otherwise every call refuses with a sentence that names the GPU and the OS version, and `Device::ray_tracing_status` and
  `renderer.supports("raytracing")` give the same text. `rayTracingPipeline` is always false. The simulator and older GPUs refuse. The limits it reports (1048576 instances, 4096
  geometries, 2^28 triangles) are the engine's conservative ones, the same as the `RecordingDevice`'s: Metal documents no numbers.
- **The structures live outside sokol.** `make_accel_structure` allocates an `MTLAccelerationStructure`
  (`newAccelerationStructureWithSize:`) kept in the pool of `MetalAccel` and named by the `AccelStructure` handle. A valid
  `AccelStructureDesc::storage` is **refused** with an error that says Metal allocates the memory itself (leave `storage` empty): the
  open design point of "The calls" is settled this way on Metal. The size comes from `blas_sizes` / `tlas_sizes`, which ask
  `accelerationStructureSizesWithDescriptor:`. Metal needs neither a buffer nor the BLAS list to size a TLAS, so the interface keeps
  `tlas_sizes(instanceCount, flags)`. `accel_alignment()` and `accel_scratch_alignment()` stay 256 (Metal takes any scratch offset;
  one number for every backend). The scratch and storage buffers are ordinary sokol buffers: `accelScratch` and `accelStorage` map
  to sokol storage buffers, and `accelBuildInput` only marks the buffer as a build input.
- **`bufferDeviceAddress` means "explicit GPU addresses"** (Vulkan and D3D12 need them for the structure memory and instance data).
  Metal has none and binds by index, so its row stays false and the `accelBuildInput`, `accelStorage` and `accelScratch` buffer usages
  are accepted without it (they were tied to it in P0a; `RecordingDevice` no longer requires it either).
- **Builds run on sokol's command buffer.** `build_blas`, `build_tlas`, `query_compacted_size` and `copy_accel_structure` finish
  sokol's blit encoder (`fa_sg_mtl_command_buffer`, reached through `MetalNative::current_command_buffer()`), open an
  `MTLAccelerationStructureCommandEncoder` on that command buffer, encode and end it. They are refused inside a pass and inside a
  native section (`begin_native`). Metal orders the encoders of one command buffer through the hazard tracking of the resources they
  use (the structures and sokol's buffers are tracked), so a BLAS build, the TLAS build that reads it and the compute dispatch that
  traces it run in that order with no barrier: this is barrier rule 3 on Metal. A refit with `update` and `src` invalid or equal to
  `dst` refits in place; `allowUpdate` and the preconditions are checked before Metal sees them (Metal aborts the process on a bad
  descriptor, so every check of the `RecordingDevice` that Metal would assert on is made first, with the same messages).
- **Instances.** `build_tlas` converts the `AccelInstance` array into `MTLAccelerationStructureUserIDInstanceDescriptor` records
  (row-major 3x4 to Metal's column-major 4x3, `customIndex` to the user id, `mask`, `opaque` and `cullDisable` to the options) in a
  buffer of its own. The TLAS keeps the BLASes its last build named alive (and resident for a trace) until it is built again or
  destroyed: a BLAS destroyed while a TLAS still names it stays in memory until the next build or destroy of that TLAS, so a
  destroyed BLAS handle cannot free memory the GPU still reads. The rule of "The memory model" (destroy the TLAS first) is still
  the one to follow, because the other backends do not do this.
- **Lifetime against the GPU.** sokol acquires its command buffer *without* retained references (`commandBufferWithUnretainedReferences`),
  so neither the acceleration structure encoder nor `useResource:` keeps a structure alive while a command buffer in flight still
  uses it. `destroy_accel_structure`, and a rebuild or copy that replaces the BLAS array of a TLAS, therefore do not release the
  Metal objects at once: the references move into a completion handler of the current command buffer (it completes after every
  earlier one on the queue), and go when the GPU has finished the work recorded so far. With no command buffer they go at once.
- **Compaction.** `query_compacted_size` writes the size (a `uint64`) into the `storageBuffer` the caller names, with
  `MTLAccelerationStructureCommandEncoder writeCompactedAccelerationStructureSize:`; the caller reads it after the frame, makes a
  smaller structure with it and `copy_accel_structure(Compact)`; `Clone` copies a structure of the same size.
- **The trace.** The kernel is an ordinary sokol compute shader (`ShaderDesc::computeFunc.source` holds the MSL; sokol compiles it at
  `make_shader`). sokol knows no acceleration structure, so `SokolDevice` keeps the `accelStructures` slots of each compute shader
  and, right after `sg_apply_bindings`, `MetalAccel::bind_compute` calls `setAccelerationStructure:atBufferIndex:` on sokol's open
  compute encoder (`sg_mtl_compute_command_encoder`) for the TLAS and `useResource:` for the TLAS and for every BLAS it names (a TLAS
  does not make them resident). A binding the dispatch needs and cannot have (a TLAS that is missing, destroyed or never built, a
  slot the shader does not declare) is logged with the shader's label and the dispatch is skipped; nothing aborts.
- **Tests.** `engine/render/tests/metal_raytracing_tests.cpp` runs on a Mac with Metal ray tracing: a BLAS and a TLAS of two
  instances traced by `rt_probe` against a CPU ray caster, rebuilds of one TLAS on consecutive frames, a refit after moving vertices,
  compaction and clone, and the refusals. A machine whose GPU or OS cannot trace rays says why and skips them (the refusal case
  checks the reasons there instead); it never fails a runner for lacking the hardware.
- Inline queries are the only model the interface has, and `intersection_query` is the same one; the MSL of an effect is a sibling of
  its HLSL and GLSL source in the shader packs, found by the usual rules (docs/design/ARCHITECTURE_RENDERING.md, "Start-up order and
  the shader cache").

## What the next packages do

- **P1v** (Vulkan): `VK_KHR_acceleration_structure`, `VK_KHR_ray_query`, `VK_KHR_deferred_host_operations` (required by the first),
  `bufferDeviceAddress`; the extension and feature request goes through the device hooks (ARCHITECTURE_RENDERING_HOOKS.md).
- **P1d** (Direct3D 12): DXR 1.1 (`D3D12_RAYTRACING_TIER_1_1`), `ID3D12GraphicsCommandList4`, structures in
  `ACCELERATION_STRUCTURE` state buffers.
- **P1m** (Metal): done, see "Metal".
- After them, the renderer builds one BLAS per mesh, a TLAS per frame, and adds the effects' compute passes to the frame graph
  only when `rt_any_effect` is true; with the switch off the frame graph is what it was (`raytracing_frame_tests.cpp` guards it).
