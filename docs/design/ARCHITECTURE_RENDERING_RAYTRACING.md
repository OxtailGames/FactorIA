# Rendering: the ray tracing seam (M79)

The user page is docs/RAY_TRACING.md (the settings, the command, what each backend will do). This page is for engine
developers: the vocabulary and the calls that `fa::gpu` gained in package M79 P0a, what each backend answers today, how the
`RecordingDevice` checks them, the `raytracing` rows of `renderer.supports`, the project settings, and the route the Metal
backend takes. Read "The GPU interface" (ARCHITECTURE_RENDERING_GPU.md) first: handles, `Result<T>`, the barrier rule and the
`RecordingDevice` are used here as that page describes them. The kernels and the DXC toolchain that compiles them have a page
of their own: [ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md](ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md).

**What exists.** The interface: types, calls with refusing defaults, the `RecordingDevice` model and its checks, the
supports rows, the settings and the command. The Direct3D 12, Vulkan and Metal backends build, refit, compact and bind
acceleration structures and run inline ray queries (sections "Direct3D 12", "Vulkan" and "Metal" below). **No frame pass traces a ray yet**
(the settings change no picture). The packages that come next are the effects.

## Pages

- [The ray tracing kernels](ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md): HLSL through DXC, the generated DXIL headers,
  what CI runs (the WARP DXR probe, `FA_WARP_DIR`) and what a contributor does.

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
| `AccelCopyMode` | `Clone` (into one at least as large) or `Compact` |
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
  makes the scratch buffer and the structure once and reuses them every frame. They check counts, strides, offsets and limits,
  not buffer handles or contents (the sizes depend on counts alone; `build_blas` checks the buffers), and `tlas_sizes` takes
  no list of BLASes: a TLAS's size is a function of its instance count.
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
- `make_accel_structure` allocates the memory itself when `storage` is invalid. **Open design point** (the answers of
  Direct3D 12 and Vulkan are in their sections below; Metal refuses a valid `storage`, see "Metal"):
  with a valid `storage` (a buffer with usage `accelStorage`, offset aligned to `accel_alignment()`) the caller sub-allocates
  and may alias structures that are never live together. The `RecordingDevice` validates the buffer, the offset and the range;
  a real backend decides whether to take a `storage` of its own kind of memory (Vulkan: a buffer with the
  acceleration-structure-storage usage and a device address; D3D12: a buffer in the `ACCELERATION_STRUCTURE` state).
- A TLAS **does not keep its BLASes alive**. Destroy the TLAS first, or after the work that traces it has completed (the
  `RecordingDevice` says so: "destroy a BLAS only after the TLAS that names it"). The instances of a `TlasBuild` are read during
  the call and copied; the span is borrowed.
- **Refit** (`update` true) needs a structure built with `allowUpdate` and the same counts: the topology stays, vertices or
  transforms move. `src` invalid or equal to `dst` refits in place. A TLAS keeps the bounds of its BLASes as they were when
  it was built: **rebuild (or refit) the TLAS after a BLAS refit**, then trace; tracing a TLAS that was not rebuilt may miss
  the moved geometry (the barriers keep the order, they do not update the TLAS).
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
5. Before a build writes a structure or a scratch buffer that an earlier dispatch traced or an earlier build read: the write
   waits for those reads (write after read). The common case is a TLAS rebuilt every frame while the frame before still traces
   it. Vulkan: `ACCELERATION_STRUCTURE_READ` at stage `COMPUTE_SHADER` or `ACCELERATION_STRUCTURE_BUILD` to
   `ACCELERATION_STRUCTURE_WRITE` at stage `ACCELERATION_STRUCTURE_BUILD`.

Vulkan derives all five from one state per resource (stage and access, the same tracking as its buffers and images): a
build's `dst` is `AS_WRITE` at `BUILD` (`AS_READ | AS_WRITE` for an in-place update), its scratch `AS_READ | AS_WRITE` at
`BUILD`, its vertex, index and instance buffers `SHADER_READ` at `BUILD`, the BLASes a TLAS build names `AS_READ` at
`BUILD | COMPUTE_SHADER`, a TLAS bound for a dispatch `AS_READ` at `COMPUTE_SHADER`, a copy's source `AS_READ` and its
destination `AS_WRITE` at `BUILD`. A change of state with a write on either side is one barrier, so rules 1 to 5 fall out
of it: two builds on one scratch buffer get a barrier between them, and a write after reads waits for the reads.

`accel_structure_state` reports the state the model keeps for a structure (the `RecordingDevice`: not built, built).

## What each backend answers today

| backend | `Features::accelerationStructure` | the refusal says |
|---|---|---|
| OpenGL, GLES3, WebGL2, Direct3D 11 (`SokolDevice`) | false, for good | the API cannot trace rays; use the d3d12 or vulkan backend, or Metal on Apple |
| Direct3D 12 | true on a device with DXR tier 1.1 and shader model 6.5 | "the d3d12 device on '<adapter>' has DXR tier <t> and shader model <m>: inline ray query needs DXR tier 1.1 and shader model 6.5" and what to do |
| Vulkan | true on a GPU with `VK_KHR_acceleration_structure`, `VK_KHR_ray_query`, `VK_KHR_deferred_host_operations` and `bufferDeviceAddress` | what this GPU lacks, with its name (`ray_tracing_status`); MoltenVK has none, lavapipe lists them from Mesa 24.1 ([release notes](https://docs.mesa3d.org/relnotes/24.1.0.html); the engine's CI and the ray tracing tests ran on 25.2.8, no older Mesa was run) |
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

## Direct3D 12 (package P1d)

The calls are in `gpu/d3d12_raytracing_win32.cpp`; what needs no D3D12 header (the capabilities, the instance bytes, the build
flags, the size rounding, the geometry checks, the DXIL test) is in `gpu/d3d12_accel.cpp`, whose tests run on every host.

- **Capabilities** (`init_ray_tracing`, after the device hooks). `OPTIONS5.RaytracingTier` and the highest shader model (asked from
  the newest value down). `ID3D12Device5` and `ID3D12GraphicsCommandList4` are queried only at tier 1.1 with shader model 6.5. `rayQuery` and
  `accelerationStructure` are true when all of them are there. `rayTracingPipeline` is true from tier 1.0 (reported, never used).
  `bufferDeviceAddress` is always true (every D3D12 buffer has a GPU virtual address). The Limits are the API's: 2^24 instances,
  2^24 geometries, 2^29 triangles. Without ray tracing nothing fails: the device is made as before (feature level 11_0
  included), the features stay false, and `ray_tracing_status` names the adapter, the tier and the shader model it found.
- **Shaders.** A compute stage takes DXIL (a DXBC container with a `DXIL` part, from DXC) on a device with shader model 6.0 or
  more; a render stage keeps DXBC or HLSL source. `usesRayQuery` and the `accelStructures` slots are refused on a device without
  them and on a render shader, and a declared slot needs `usesRayQuery`. Each declared slot is a root SRV (`t<n>`, space `hlslSpace`) after
  the constant buffers, so root signature 1.0 is enough. `set_bindings` sets it to the TLAS's GPU address and refuses a slot that
  is not a live, built TLAS.
- **Memory.** Every structure lives in a buffer created in `D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE` with
  `ALLOW_UNORDERED_ACCESS`, and D3D12 allows no transition into or out of that state. The device makes one of its own when
  `storage` is invalid. A caller's `storage` must be a buffer made with `usage.accelStorage` only (no other usage, no initial
  data), and the structure takes its range at an offset aligned to 256. Such a buffer (`TrackedResource::accel`) is refused by
  `write_buffer`, `copy_buffer_to_buffer`, `copy_buffer_to_image`, `read_buffer`, `request_buffer_read`, the DirectStorage reads
  and a native section. Structures are copied with `copy_accel_structure`. `accelScratch` buffers get `ALLOW_UNORDERED_ACCESS`
  and are used in the UAV state; `accelBuildInput` buffers are read in `NON_PIXEL_SHADER_RESOURCE`. Destroying a structure is
  deferred to the end of the frames that may still use it.
- **Calls.** `blas_sizes` and `tlas_sizes` answer `GetRaytracingAccelerationStructurePrebuildInfo`, each size rounded up to 256.
  `build_blas` and `build_tlas` record `BuildRaytracingAccelerationStructure`. A refit adds `PERFORM_UPDATE` and must give the
  flags of the build. The instances are converted to `D3D12_RAYTRACING_INSTANCE_DESC` (`InstanceContributionToHitGroupIndex` 0:
  there are no hit groups) and copied into upload memory that lives until the frame ends. `query_compacted_size` writes the
  `COMPACTED_SIZE` postbuild info, 8 bytes at an 8-byte aligned offset of a storage buffer. `copy_accel_structure` is a `CLONE`
  or a `COMPACT`. Beyond the `RecordingDevice`'s checks, D3D12 also refuses a `vertexOffset` that is not a multiple of 4 and an
  `indexOffset` that is not a multiple of the index size.
- **Barriers** (how D3D12 does the list in "Barriers" above). A structure never changes state, so its order is kept by UAV
  barriers. The command list tracks the last access of each structure buffer (`accel_access`). It inserts a UAV barrier before
  a write that follows any access (a refit after a trace, a rebuild, a copy into it). It also inserts one before a read that
  follows a write: the TLAS build that reads its BLASes, the dispatch that traces a TLAS bound with `set_bindings`, a compaction
  query or a copy from it. A dispatch that traces also starts with a UAV barrier over every resource when any structure was
  written since the last such dispatch (the BLASes a TLAS points at are not bound, so a BLAS refit after the TLAS build has no
  buffer to hang a barrier on). The scratch buffer takes a UAV barrier before a build when an earlier command of the list wrote it. The tracking
  starts again with each list: across lists the backend relies on each list being its own `ExecuteCommandLists` call, whose
  writes D3D12 finishes before the next call's work.
- **Tests.** `d3d12_raytracing_tests.cpp` (ctest `render_d3d12_raytracing`). The neutral half runs everywhere. On Windows a WARP
  device builds a BLAS and a TLAS of two instances and dispatches `rt_probe`. Every pixel of the result is checked against the
  same rays on the CPU. On the frames after, it refits both, compacts the BLAS and rebuilds the TLAS over the copy, then rebuilds
  both from scratch. It also checks that the kernel given as HLSL text is refused (RayQuery needs DXIL). When the WARP has no
  tier 1.1 the case says so and passes, unless `FA_D3D12_REQUIRE_RT=1` (CMake sets it on this ctest alone with `-DFA_D3D12_REQUIRE_RT=ON`, which the
  Windows CI job passes; `FA_D3D12_REQUIRE` alone does not), which fails it with the tier, the shader model and the `d3d10warp.dll` the process loaded. With `FA_WARP_DIR`
  (exported by every Windows CI shard when the runner's WARP is older, "What CI runs" in
  ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md), the case loads that `d3d10warp.dll` before its first device. That works in
  its own ctest, where nothing loaded a WARP before. In the whole-suite ctest `render` an earlier D3D12 case may have loaded
  the system's WARP: the case then skips there (CI does not set `FA_D3D12_REQUIRE_RT` for that run), and says so. Under
  `FA_D3D12_REQUIRE_RT=1` a WARP that was defeated that way is a failure too, which names the earlier WARP: the dedicated
  ctest runs the file alone, so nothing can have loaded one before it.

## Vulkan (`vulkan_raytracing.cpp`)

- **Opt-in device.** `init_device` asks for the three extensions and the `accelerationStructure`, `rayQuery` and
  `bufferDeviceAddress` features only when the GPU has all of them; otherwise the device is made without them and
  `ray_tracing_status` names the first missing piece and the device (with the Mesa release when the device is lavapipe).
  Ray tracing never fails device creation: a `vkCreateDevice` that fails with them on is retried without them, and a driver
  that lists the extension but gives no entry point turns it off. `VK_KHR_ray_tracing_pipeline` is reported
  (`Features::rayTracingPipeline`), never enabled. A device hook that asks for the same feature structs merges into the
  engine's. `VK_KHR_ray_tracing_maintenance1` is enabled too when the GPU lists it with `synchronization2` on: it adds
  `ACCELERATION_STRUCTURE_COPY_BIT` to the stages (`accelCopyStage_`), which a structure copy then uses in its barriers;
  without it (or without sync2, whose 64-bit stage flags the bit needs) the copy is ordered at the build stage as
  before. The status line also names the driver (`VkPhysicalDeviceDriverProperties`, read only on Vulkan 1.2 or with
  `VK_KHR_driver_properties`).
- **Caps.** `Limits::maxAccelInstances`, `maxAccelGeometries` and `maxAccelPrimitives` come from
  `VkPhysicalDeviceAccelerationStructurePropertiesKHR` (clamped to 32 bits where the field is), and
  `accel_scratch_alignment()` is `minAccelerationStructureScratchOffsetAlignment`, never below 256 (`fill_ray_tracing_caps`).
- **Memory.** Buffers with usage `accelBuildInput`, `accelStorage` or `accelScratch` get the matching Vulkan usage plus
  `SHADER_DEVICE_ADDRESS` and memory allocated with `VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT`, aligned so offset 0 suits a
  structure and a scratch range. `make_accel_structure` makes its own `accelStorage` buffer when `storage` is invalid and
  takes a caller's `accelStorage` buffer at a 256-aligned offset otherwise. Sizes come from
  `vkGetAccelerationStructureBuildSizesKHR`, rounded up to 256 (structure) and to the scratch alignment.
- **Builds.** A BLAS is triangles (`R32G32B32_SFLOAT` positions at the stride given, 16- or 32-bit indices or none). A TLAS
  build copies the instances into `VkAccelerationStructureInstanceKHR` records in an instance buffer the TLAS owns (grown in
  steps of 64, the old one released with the frame) through the upload ring. An update keeps the counts, the geometries'
  shapes and the flags of the build it refits, or is refused. Two builds into one TLAS in one list are ordered by the
  tracked barriers (the second instance copy waits for the first build's read of the instance buffer, the second build
  for the first's write), so the later one is what traces; lists recorded on several threads that build into one TLAS are
  ordered only by the caller's submission order. Flags: `preferFastBuild` wins over `preferFastTrace`;
  `allowCompaction` applies to a BLAS only.
- **Compaction.** `query_compacted_size` writes the size with a query pool of its own (released with the frame) and
  `vkCmdCopyQueryPoolResults` into the storage buffer; `copy_accel_structure` runs `vkCmdCopyAccelerationStructureKHR` in
  `CLONE` or `COMPACT` mode (its barriers use the copy stage when `accelCopyStage_` is on, the build stage otherwise), and the copy inherits the source's counts and `allowUpdate`; a copy is never compacted again.
- **Destruction** is deferred like every resource: the handle goes once the frames that may use it have completed, before its
  storage.
- **Kernels.** A compute `ShaderDesc` with `usesRayQuery` takes DXC's SPIR-V as it is: the bindings its slots name
  (`BackendBinding::spirvSet` and `spirvBinding`) may sit in any descriptor set, and `move_descriptor_sets` rewrites
  their `DescriptorSet` decorations into the engine's layout: uniform blocks to set 0, views, samplers and acceleration
  structures to set 1, the binding numbers kept. Two slots of different kinds on one (set, binding) pair, and two slots
  that end on one binding of one set, are refused; a binding no slot names is left where the SPIR-V has it, and set 2 stays
  the bindless table. Any other shader is not moved: a binding outside set 0 for a uniform block or set 1 for the rest is
  refused. `ShaderAccelStructure` slots are compute-stage only and become `VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR`
  bindings of set 1; the descriptor pools hold that kind only on a device with ray tracing active (`kDescAccelStructure`),
  so such a shader on a device without it is refused first. Without ray query the shader is refused with the device's reason.
- **Tests** (`vulkan_raytracing_tests.cpp`): the caps and the set move without a device; the refusals of a device without
  ray tracing; and, on a GPU with it, the `rt_probe` kernel against a CPU trace of two instances, a BLAS refit, a TLAS
  refit after an instance moved, two builds into one TLAS in one list, a compacted copy and a TLAS rebuilt on consecutive
  frames, all under the validation layer with synchronization validation. A device
  without ray tracing skips those with its reason, also under `FA_VULKAN_REQUIRE=1`; `FA_VULKAN_REQUIRE_RT=1` makes the skip
  a failure that names the device, its driver and what it lacks. The Linux CI job sets it: it runs Mesa 25.2's lavapipe,
  which traces rays (docs/design/BUILDING_TESTS.md, "Vulkan ray tracing tests").

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
  earlier one on the queue), and go when the GPU has finished the work recorded so far. `command_buffer()` makes one when the frame has none (a destroy
  outside a frame waits at most one frame of GPU time); it is null only when the queue is lost, and then they go at once.
  `~SokolDevice` (context it opened or not) runs `split_commit()` (commits the open frame's buffer, which a wait would
  otherwise never see finish), `wait_idle()` (an empty buffer queued behind everything on sokol's queue) and only then frees
  `accel_`, all before `sg_shutdown`; a context that is already closed was waited for by its `sg_shutdown`.
- **Compaction.** `query_compacted_size` writes the size (a `uint64`) into the `storageBuffer` the caller names, with
  `MTLAccelerationStructureCommandEncoder writeCompactedAccelerationStructureSize:`; the caller reads it after the frame, makes a
  smaller structure with it and `copy_accel_structure(Compact)`; `Clone` copies into a structure at least as large.
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

- **P1d** (Direct3D 12): landed, "Direct3D 12" above.
- **P1v** (Vulkan): landed, "Vulkan" above.
- **P1m** (Metal): landed, "Metal" above.
- **P1s** (done, ARCHITECTURE_RT_SCENE.md): the renderer builds one BLAS per submesh, a TLAS per frame and the per-instance records, when
  `rt_any_effect` is true on a device that traces.
- After them, the renderer adds the effects' compute passes to the frame graph
  only when `rt_any_effect` is true; with the switch off the frame graph is what it was (`raytracing_frame_tests.cpp` guards it).
