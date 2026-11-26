# Rendering: the scene's acceleration structures (M79, package P1s)

What the renderer puts in the BLASes and the TLAS each frame, and the record buffer the ray query kernels read. The seam it is written
against (`fa::gpu`'s `build_blas`, `build_tlas`, `query_compacted_size`, `copy_accel_structure`, the sizes and the barriers) is in
[ARCHITECTURE_RENDERING_RAYTRACING.md](ARCHITECTURE_RENDERING_RAYTRACING.md); the user-facing description (the instance cap, which objects
are traced) is docs/RAY_TRACING.md. Code: `engine/render/src/rt_scene.h`, `rt_scene.cpp` (the scene), `rt_scene_skin.cpp` and `rt_skin.h` (skinned meshes), `rt_records.h` (the record layout),
`renderer_rt.cpp` (the settings and the device), `engine/render/shaders/rt/rt_records.hlsli` (the layout for the kernels), `engine/render/shaders/rt_skin.glsl` (the skinning kernel). Tests:
`engine/render/tests/rt_scene_tests.cpp`.

The scene is written against `fa::gpu` only and is tested on the `RecordingDevice` made with `DeviceInit::recordingRayTracing`: every
build, size query and copy is recorded and checked, so what a backend will receive is what the tests read. No backend is involved.

## When it runs: free when off

`Renderer::set_ray_tracing(settings)` (called by the engine at start-up and by `Engine::set_ray_tracing`, so by `render.ray_tracing`) and
`Renderer::Impl::rt_begin_frame` (once per frame, in `begin_frame`) decide whether the scene is on:

- Wanted = `rt_any_effect(settings)` (the master switch **and** an effect, the same rule the effects' passes will use) and a device.
  The master switch alone builds nothing: an acceleration structure that nothing reads would cost memory and builds for no picture.
- On = wanted and `Device::ray_tracing_status()` is true. A device that cannot trace logs ONE warning (the reason of the device, that
  nothing is traced and nothing built, and `factoria call render.ray_tracing`), says it again only after the setting was turned off and on
  again, and the frame is the one with ray tracing off (a test compares the recorded command streams).
- Off = `RtScene::configure(nullptr, ...)`: every buffer, BLAS and the TLAS are freed on that frame, `Assets::set_accel_input(false)`,
  and every call of the scene is a branch that returns. No pass is added to the frame graph. The frame is identical to one with the
  feature absent.

## Mesh buffers: `accelBuildInput`

A BLAS is built from a submesh's vertex and index buffers, so they need `BufferUsage::accelBuildInput`. `Assets` gives it to every new
mesh buffer while the scene is on (`set_accel_input(true)`). Meshes loaded before the setting turned on are reloaded in place (the same
`MeshAsset`, new buffers; a procedural mesh is uploaded again on its next use, `geometryVersion` + 1) so the BLASes are built from buffers
the device allows. Turning it off keeps the buffers made so far (the usage flag is harmless) and the next ones are made without it. A game
that never turns ray tracing on makes every buffer as it always did. Nothing changes in the buffers' contents or in the draw.

## One BLAS per submesh

`RtScene::blas_for` makes one BLAS for every part (`SubMesh`) of a mesh asset, keyed by the asset, never by the instance: a thousand
instances of one rock share one BLAS. The geometry is the part's vertex buffer (position first in a 52-byte `MeshVertex`; stride 52,
`Float3`) and its `uint32` index buffer at `ibOffset`. `AccelTriangles::opaque` is false in the BLAS and the **instance** carries the
opaque bit (an opaque material forces the instance opaque; an alpha-tested one does not, so a ray query lets the kernel test the alpha
with the record's `Cutout` flag). Both offsets are validated by the `RecordingDevice` (`vertexOffset % 4`, `indexOffset % index width`,
with messages that name the field); `ibOffset` of a part is always a multiple of 4.

A BLAS is rebuilt when the asset's `geometryVersion` or the buffer ids of its parts change (a procedural mesh updated, a mesh loaded
again) and freed when the asset goes: `Assets` calls the release hook (`set_mesh_release_hook`) at the start of `destroy_mesh` and
`destroy_procedural`, before the buffers are destroyed, and `RtScene::forget` frees the asset's BLASes. A TLAS never keeps a BLAS alive
(`Device::destroy_accel_structure` defers only for lists that use the structure directly, and a BLAS built long ago is used by no recent
list), so **a BLAS is never destroyed at once**: `RtScene::retire_blas` puts its structure in a graveyard with the frame number, and
`begin_frame` destroys it `kRetireFrames` = `kInflightFrames` + 1 frames later, when no TLAS of a frame in flight can name it. The same
goes for the original of a compaction after the swap and for every BLAS an asset or a geometry change frees. Only `release()` (ray tracing
turned off, another device, the renderer's shutdown) destroys everything at once, after one `Device::wait_idle()`. An animated procedural
mesh whose geometry changes every frame rebuilds its BLAS every frame (and the retired ones wait their frames); a skinned mesh does not: it
has the refit of "Skinned meshes".

A part with no vertex buffer a build can read (a placeholder while a mesh loads, no triangle) is `untraceable`: its instances are left out.
A build the device refuses logs one `WARN` with the device's message (one flag per cause: sizing or making, building a BLAS, making or
building the TLAS, making a buffer) and leaves the part's instances out **of that very frame's TLAS** (the instance list is filtered again
after the builds; `skippedNoBlas` counts them); the others go on. A buffer of the scene (scratch, records) the device could not make gives
the frame up with one `WARN`: nothing is built and the next frame tries again.

### Build budget and compaction

`kMaxBuildsPerFrame` = 256 BLAS builds per frame (a deterministic work count: a scene with more waits for the next frames, and the
instances of a BLAS that waits are left out of that frame's TLAS, counted in `skippedNoBlas`).

Every BLAS is built with `allowCompaction` and `preferFastTrace`, then compacted without a stall:

1. Frame N: `build_blas`, then `query_compacted_size` into one of 4096 8-byte slots of a storage buffer.
2. Frame N+1, `begin_frame`: the slots are read (`request_buffer_read`/`poll_buffer_read` where the device reads asynchronously;
   otherwise, as on the `RecordingDevice` and headless runs, the work is committed and the slots read at once, so a result never depends on
   the GPU's speed). A smaller structure is made for each answer. That synchronous `read_buffer` **blocks the render thread** until the GPU has
   finished the frames before it: it is the path of the `RecordingDevice` and of headless runs (where it costs nothing or is what makes a
   result deterministic); a device that reads asynchronously never takes it, so a window never waits here.
3. Frame N+1, the pass: `copy_accel_structure(Compact)` into it.
4. Frame N+2, `begin_frame`: the compacted structure replaces the original (the instances of this frame's TLAS name it) and the original
   is retired (the TLAS of frame N+1 names it, so it is destroyed `kRetireFrames` frames later). State names for a test: `pending`, `built`, `queried`, `reading`, `compact-pending`, `swap`, `compacted`, `failed`, `gone`.

A BLAS with no free slot is not compacted (it stays valid and `built`). A read that cannot be asked for logs one `WARN`, and the BLAS stays
as it is built.

## The TLAS, every frame

`Renderer::gather_meshes` of the **main camera's job** (the one named `camera:`, never a shadow or a probe job, never the LOD-follow job)
calls `RtScene::collect` with its opaque and blended lists, after the LOD pick and before the view culling decides what to draw: every item
is offered, including the ones outside the view (a ray may hit them). The cap cut comes first and the BLASes after it: an item the cap
leaves out makes no BLAS. Because the items come from the same pick the draw makes, **one LOD
level per instance** is traced: the level the main camera sees. A foliage's instances and the instances of a GPU-instanced batch are mesh
items like the others.

What is **not** traced, and why (each has a counter in `RtSceneStats`):

| item | counter | why |
|---|---|---|
| nodes of a `Terrain` | `skippedTerrain` | heightfield tiles; the terrain's own ray path comes later, and a tile is not a mesh asset |
| impostor cards | `skippedImpostor` | a card is a picture of a mesh, not a surface. While an entity is an impostor it is **not traced** (a choice: a flat card would cast a card-shaped shadow and show a flat picture in a reflection, and an impostor is far away by definition) |
| skinned meshes over the skinned budget, or with no skinning program | `skippedSkinned` | a skinned mesh **is traced** ("Skinned meshes" below); only what the budget or a driver that refuses the kernel leaves out is counted, with one teaching `WARN` |
| the level fading out of a LOD cross-fade | `skippedFading` | the level fading in is traced (one level per instance). A foliage's fade is a distance fade, not a cross-fade: it is traced |
| meshes drawn from compute buffers (`MaterialAsset::buffers`) | `skippedGpuDriven` | their instances are where the buffer puts them, which only the GPU knows |
| placeholders, parts with no triangles | `skippedUntraceable` | nothing a build can read |

### The instance cap

cap = min(`render.rayTracing.maxInstances`, `Limits.maxAccelInstances` of the device, 2^24 = `kRtMaxInstanceIndex + 1`), never below 1.
Over the cap the scene keeps the instances **nearest to the main camera** (distance of the item's origin, a stable sort on
`rjobs::order_float`, ties by the order the items came in, so a scene always keeps the same instances) and warns once: the count the
scene holds, the cap, the setting to change and the device's limit when it is the lower. `droppedOverCap` says how many were left out.
One mesh with several submeshes counts one instance per submesh (each is an instance of the TLAS).

### The instance mask

| bit | name | set when |
|---|---|---|
| 0x01 | `kRtMaskOpaque` | an opaque lit surface (not alpha-tested, not in the blended list) |
| 0x02 | `kRtMaskCutout` | alpha-tested: a custom material with `alphaMode` `clip` (the instance is not forced opaque) |
| 0x04 | `kRtMaskBlended` | the item is in the blended or transmissive list |
| 0x08 | `kRtMaskCastsShadow` | `MeshRenderer.castShadows`; a shadow ray uses this bit |
| 0x10 | `kRtMaskFoliage` | an instance of a `Foliage` |
| 0x20 | `kRtMaskEmissive` | emissive colour times strength above 0 |
| 0x40 | `kRtMaskRefractive` | a glass the translucency kernel bends rays at (blended, lit, no full shader, transmission above 0; M79-P3b) |
| 0x80 | reserved | the effects of later packages; a kernel never sets or tests it |

Every instance has exactly one of the first three. `kRtMaskSurfaces` (0x07) is what a ray that wants every visible surface uses.
The instance's `opaque` is true except for a cutout; `cullDisable` is true for a double-sided mesh or material.

### The record buffer

`RtInstanceRecord` (`rt_records.h`, 128 bytes, std430-compatible: three float4 rows of the object-to-world 3x4, albedo, emissive, then
roughness, metalness, flags, blasId, then `volume` (ior, thickness, attenuationDistance, transmission) and `attenuation` (the tint colour), the
last two rows added by the translucency, M79-P3b; `static_assert`s on every offset) is written for every instance into one storage buffer, and the
instance's **`customIndex` is its record's position**: a kernel that commits a hit reads `records[CommittedRayQueryInstanceCustomIndex()]`.
The HLSL twin is `engine/render/shaders/rt/rt_records.hlsli` (the Metal kernels declare the same struct); a test compares the flag and
mask values, the member order and the sizes of the two files.

The constants are the draw's: `MeshRenderer.color` times the part's glTF base colour factor (`part_base_color`, in the scene's colour space),
roughness and metalness from the part when the model has PBR values and from the `MeshRenderer` otherwise, emissive =
(`MeshRenderer.emissive` + the part's emissive factor) times the strength. **A custom material** (`MaterialAsset`) is not evaluated: the
record has the `MeshRenderer`'s constants and the `CustomMaterial` flag, so the kernel knows the colour is an approximation. An unlit mesh
(`unlit`, a material with `lighting: "unlit"`, or a material that failed to compile) has the `Unlit` flag.

The flags (`kRtFlag*`, the same values in `rt_records.hlsli`): `Opaque` 1<<0, `Cutout` 1<<1, `TwoSided` 1<<2, `Blended` 1<<3, `Unlit` 1<<4,
`Foliage` 1<<5, `CastsShadow` 1<<6, `CustomMaterial` 1<<7, `Skinned` 1<<8 (the BLAS is the instance's own and holds the pose of this frame), `Refractive` 1<<9 (the mask's 0x40 bit; the
`volume` row is meaningful: ior, thickness, tint distance, transmission). A glass instance is traced from both sides (`cullDisable`), so its back faces
are what shadow and reflection rays hit too: it casts a solid shadow and is a solid in a reflection. Details: [ARCHITECTURE_RT_TRANSLUCENCY.md](ARCHITECTURE_RT_TRANSLUCENCY.md).

Buffers: the records buffer (`storageBuffer` + `writeTransient`, grown by powers of two, at least 256 records) is written with one
`write_buffer` before the TLAS build; the TLAS is made again when its capacity grows; the scratch buffer (`accelScratch`) is the larger of
the builds' needs (the static BLAS builds of a frame all use its start: their large builds are few and each one fills the GPU, and the
backend derives a barrier between two builds on the same scratch; keeping the buffer at the largest need instead of the sum is what stops it
growing with the number of builds a frame. The skinned builds, many small ones, are laid side by side, see "Skinned meshes"). The records and the TLAS are valid (`tlas()`, `records_buffer()`) once a frame has an instance; with none they are the
invalid handles.

## Skinned meshes

A skinned draw moves its vertices in the vertex shader (`fa_skin_matrix`, the Animator's palette), so a BLAS of the bind pose would put the
shadow and the reflection of a character where it is not. A skinned item (`mi.anim` set and the part with a skin buffer) is therefore traced
from a **BLAS of its own** that holds the pose of the frame. Only while the scene is on: with ray tracing off or unsupported nothing of this
exists (no kernel program, no palette buffer, no BLAS, no dispatch) and the frame is the one it was.

**The kernel.** `engine/render/shaders/rt_skin.glsl` (sokol-shdc, a compute shader, 64 threads a group, like `hiz.glsl`) does for each vertex
the blend of the vertex shader: the same four joints (the joint bytes of the skin buffer, clamped to 63), the same weights, the same palette
(64 joints, three `vec4` rows each; `rt_skin_pack_palette` in `rt_skin.h` writes it like `pack_palette` of the draw, the joints the palette
does not have are the identity), the rows blended first and the three dots after. It writes the model-space position (three floats, no padding)
into a buffer the BLAS is built from; the instance keeps its own `mi.model`. `rt_skin_position` in `rt_skin.h` is the same maths on the CPU; a
test checks it against the formula. The kernel reads the part's vertex and skin buffers as storage: `Assets` gives them `storageBuffer` usage
(next to `accelBuildInput`) while the scene is on and the device has compute. The program is made on first use by
`Renderer::Impl::rt_skin_pipeline` and handed to the scene as a provider (`RtScene::skinKernel`); the scene asks for it **in every frame that
skins** and never keeps the handle, because the renderer's pipeline cache destroys one nobody asked for in a while (`Gpu::sweep_pipelines`). A
driver that refuses it leaves the skinned instances out (`skippedSkinned`, one `WARN`).

**One BLAS per instance** (key: entity, mesh asset, part), not per asset: two characters of one asset have two poses. Its geometry is the
output buffer (stride 12, `Float3`) and the asset's index buffer, of the LOD level the item draws. It is built with `allowUpdate`,
`preferFastTrace` and **never compacted** (it changes every frame). Static parts of the same asset keep their shared BLAS (made on the first
non-animated item that draws them).

**Per frame, in the `rt-accel` pass** (the backends derive the barriers between the steps): write the frame's palettes (one `write_buffer`; an
Animator shared by several items is one palette), the compute pass `rt-skin` (one dispatch per instance), the static builds, the skinned builds,
the compaction copies and records, the TLAS. Scratch is per build: the builds are laid side by side in the scratch buffer (aligned, up to
`kSkinScratchBytes` = 64 MiB; past it the builds share the start of the buffer and the backend serializes them).

**Refit or rebuild.** A first build is a build from scratch; after it every frame is a refit (`update`, in place, same counts), which is cheap
but makes the structure worse the more the mesh moves from the pose it was built for. So an instance is **rebuilt** from scratch every
`kSkinRebuildFrames` (60) frames (from then on, at the first frame whose number plus the BLAS id is a multiple of `kSkinRebuildSpread` = 16, so
BLASes made in one frame do not all rebuild in one: a crowd's rebuilds are spread over 16 frames), and at once when the box of its bones' reach jumps by more than `kSkinExtentJump` (0.35) of the largest side
of the box it was built for (a teleported bone, a changed clip; NaN counts as a jump). A rebuild spends the frame's build budget
(`kMaxBuildsPerFrame` minus the static builds) and is a refit when none is left (the rebuild is a later frame's). First builds take the budget
first (id order); the rebuilds that are due share the rest, a box jump first and then the oldest build first, and a BLAS that is a whole
spread (`kSkinRebuildSpread` frames) past its due frame no longer waits for its phase: a crowd whose rebuilds outnumber the budget (4096
instances over 16 frames of 256 builds) is rebuilt oldest first, and no id waits for ever. Every choice depends on the frame count and the palettes only, never on the clock.

**Budget** (deterministic work counts): at most `kMaxSkinnedInstances` (4096) instances and `kMaxSkinnedVertices` (2^22) skinned vertices a
frame, the nearest to the main camera first (a stable sort, ties in the order the items came), and parts of at most `kRtSkinMaxPartVertices`
(65535 groups x 64) vertices. What is over is left out of the TLAS, counted in `skippedSkinned`, with one `WARN` that names a mesh, the
limits and the fix (fewer vertices, a lower LOD, fewer animated characters in view).

**Freeing.** An instance that stops coming, or an asset that goes (`forget`), frees its BLAS: the structure goes to the **graveyard**
(`retire_blas`, the one of "One BLAS per submesh": destroyed `kInflightFrames` + 1 frames later, because a TLAS built in an earlier frame may
still name it); the output buffer and its view are destroyed at once (the device defers them). A BLAS whose mesh changed (its buffers) is freed
and made again.

**Known gaps.** (1) When the LOD level of an instance changes, the BLAS of the old level is freed at once and the new one waits for its build:
with the frame's build budget spent (`kMaxBuildsPerFrame`) the instance is out of the TLAS (`skippedNoBlas`) until it is built, a frame or more
later. (2) A skinned BLAS whose build the device refused stays `failed` (and out of the TLAS, with one `WARN`) while its mesh is unchanged, like
a static one: a refusal is a size, memory or limit answer that does not change by asking again, and an instance that leaves the frame and comes back is tried again.

Counters of `RtSceneStats`: `skinnedInstances`, `skinnedDispatches`, `skinnedBuilds`, `skinnedRefits`, `skinnedVertices` (of the last frame).

Tests (`rt_scene_tests.cpp`, "rt skin: ..."): one dispatch and one build with `allowUpdate` in the first frame, refits to frame 60 and one rebuild
at its phase in the 16 frames after, an extent jump rebuilds and a small move does not, two instances of one asset have two BLASes (and a static one a third), the kernel is asked for in every frame that skins (a pipeline destroyed in between is not used), removal frees
the buffer at once and the structure after the frames in flight, off allocates and records nothing, no program and over the budget warn once,
the same stream twice, the CPU twin against the formula, and a real skinned glTF through the renderer with rays on and off.
The kernel itself is not run in these tests (the `RecordingDevice` runs nothing, and the suite has no compute readback on a real device):
its maths is the CPU twin's and the bytes it reads are those of the draw.

## The frame graph pass

`rt-accel` is the first pass of the main camera's job (a **side-effect** pass: nothing in the graph reads what it makes yet, and a pass
with a side effect is never culled). It records outside any render pass, in this order: the skinning (palettes, `rt-skin` compute pass), each new BLAS build followed by its
compaction query, the skinned builds and refits, the compaction copies, the records' `write_buffer`, the TLAS build (the backends put the barriers between them, ARCHITECTURE_RENDERING_RAYTRACING.md, "Barriers"). The effects of
later packages add their compute passes after it and declare the TLAS they read.

## The floating origin

The TLAS and the records live in the renderer's rebased space (the positions the draw uses), so a rebase leaves them correct when they are
rebuilt: they are rebuilt every frame from the items. `Renderer::Impl::origin_shifted` calls `RtScene::shift(offset)`, which moves the
world-space cache of the frame before (`previous_records()`: what a later package's temporal reuse reads) by the same offset, like
`prevViewProj` and the Hi-Z pose. A test moves the origin and checks the cache and the next frame's transforms
(docs/design/ARCHITECTURE_RENDERING_BIGWORLDS.md, "The floating origin").

## Determinism

Every walk is in an order that does not depend on the run: the BLASes are in a `std::map` by id, ids count up from 1 and are never reused,
pending builds and copies are in creation order, the cap sorts stably by a float turned into an integer order. A test records the same
scene twice, on two devices, and compares the command texts line by line.

## Tests

`rt_scene_tests.cpp`: the scene on its own (a BLAS once per submesh, compaction over three frames, freed with the asset, rebuilt when the
geometry version changes; the records, masks and customIndex of plain, cutout, custom, unlit, emissive and blended items; each skipped kind;
the cap and its one warning; the cap with the device's limit; determinism; off allocates nothing; `shift`; a BLAS the device refuses; the
layout twin; the `RecordingDevice`'s offset checks) and the renderer's frame (off and unsupported are the same stream, plus one warning;
BLASes once and a TLAS every frame; the LOD pick; foliage; the cap; the floating origin; `clear_asset_cache` frees the BLASes; determinism).
