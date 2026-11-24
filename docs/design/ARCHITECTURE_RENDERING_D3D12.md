# FactorIA architecture: the D3D12 backend (M77)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the GPU interface it implements is
[ARCHITECTURE_RENDERING_GPU.md](ARCHITECTURE_RENDERING_GPU.md)).

## D3D12 backend

The engine's own Direct3D 12 device (M77-P7a: the core; M77-P7c1: shaders, pipelines, passes and draws; M77-P7c2:
GPU timers and asynchronous reads; M77-P9b: the renderer on it, offscreen). Its code is
`engine/render/src/gpu/d3d12_device.h` and `d3d12_*_win32.cpp` (the `_win32` suffix keeps it out of every other
build); `d3d12_device.cpp` is the factory of the other platforms, which returns a teaching error ("runs on Windows
only", hint `make_device(built_sokol_backend())`). `fa_render` links `d3d12`, `dxgi` and `dxguid` on Windows.
`make_device(Backend::D3d12)` makes it with `DeviceInit` and `pipelineCacheFile = d3d12_pipeline_cache_file()` (the
renderer's `RendererDesc::backend = GpuBackend::D3d12`); tests make it with `make_d3d12_device(D3d12Options)`.

**Options and start-up.** `D3d12Options` picks WARP or the first hardware adapter (high-performance preference), the
debug layer (and GPU-based validation, which needs it), the frames in flight (1 to 3), the upload ring's size and the
descriptor counts. Contradictions are errors before any D3D12 call. Without the "Graphics Tools" feature the debug
layer is missing: the device is made without it, warns, and `debug_layer_active()` is false. A device needs feature
level 11.0. On resource binding tier 1 (no unbounded descriptor ranges) the device makes no bindless table whatever
`bindlessDescriptors` asks, and warns when it asked for one; `resource_binding_tier()` and `bindless_descriptors()`
say what it found and made.

**Errors.** Every failed HRESULT becomes a message with its hex value and name (`hr_text`) and, after a device
removal, `GetDeviceRemovedReason`. With the debug layer, the InfoQueue keeps ERROR, CORRUPTION and WARNING messages;
the device moves them into `errors()` / `warnings()` (prefixed `gpu d3d12 debug layer:`) and the log after each
commit and whenever `errors()` or `warnings()` is read. A misuse the backend catches itself (a write past a buffer's
end, a destroyed handle) is reported the same way and records nothing. `make_shader` and `make_pipeline` report on
every failing call (`gpu d3d12: make_shader '<label>': ...`) and return a handle whose state is `Failed`; a
`CommandList` method reports `gpu d3d12: CommandList::<method> in list '<label>': ...` and records nothing.

**Frames, fences, deferred destruction.** One direct queue and one fence. `submit(list)` closes the list and executes
it, then signals the fence; `commit()` signals the frame's fence value, and once more frames than `framesInFlight`
were committed it waits (up to 120 s, then an error) for the oldest one, whose descriptor segment and ring room the
new frame reuses. `destroy_*` frees the handle at once and keeps the D3D12 object (and its descriptors) in a deferred
list tagged with the current frame; it is released once that frame's fence passed (`counters().pendingReleases`).
`execute` keeps every resource a submitted list used alive until that frame is done, so a resource destroyed while
the GPU still reads it lives on. `wait_idle()` drains the queue and releases everything pending. A list must be
submitted in the frame `begin_commands` gave it (its uniforms and descriptors sit in that frame's ring room and
descriptor segment): one submitted after a `commit()` is dropped with an error.

**Descriptors.** Four CPU heaps (views, colour attachments, depth attachments, samplers) with LIFO free lists; a full
heap fails the view or sampler (state `Failed`) with an error that names the `D3d12Options` field to raise. The
shader-visible CBV/SRV/UAV heap keeps `[0, bindlessDescriptors)` for the bindless table (null SRVs until something
is put there) and then one segment of `frameViewDescriptors` per frame in flight; the sampler heap has the segments
only (D3D12 allows 2048 samplers in all). `set_bindings` copies the bound views and samplers into the frame's segment
(one table per stage); a frame that uses its segment up fails the `set_bindings` with an error that names the option.
The segment is reset when the frame's slot comes round again.

**Uploads.** `write_buffer`, `write_image` and the initial data of `make_buffer` / `make_image` copy through one
persistently mapped upload ring shared by the frames in flight (rounded up to whole 64 KiB). An upload that does not
fit (bigger than the ring, or the frames in flight hold it all) takes a buffer of its own, released with its frame
(`counters().dedicatedUploads`, `uploadRingWraps`). Initial data is recorded into an internal "prelude" list that
runs before the next submitted list, commit, readback or `wait_idle`.

**Barriers.** Each resource keeps one state per subresource (mip x layer x plane). A list tracks, per resource it
touches, the state it needs first and the state it leaves; its transitions are batched and flushed before each copy.
Lists may be recorded on several threads and submitted in any order, so the state a list needs first is not known
while it records: at submit a small fix-up list moves every subresource from the state the queue left it in to the
one the list starts with, executed just before it. Buffers start in COMMON and decay back to COMMON at the end of
every `ExecuteCommandLists`: after a submit their tracked state is COMMON, the fix-up list skips them and their first
use in the next list promotes them implicitly (a COMMON -> state fix-up would contradict the state the debug layer
promoted them to, BEFORE_AFTER_MISMATCH #527). Inside a list, the bindings drive the states: a texture view (or a
read-only storage buffer) bound for reading is moved to NON_PIXEL_SHADER_RESOURCE | PIXEL_SHADER_RESOURCE, a storage
image or written storage buffer to UNORDERED_ACCESS, a colour attachment to RENDER_TARGET, depth to DEPTH_WRITE,
vertex and index buffers to VERTEX_AND_CONSTANT_BUFFER and INDEX_BUFFER, and an MSAA resolve to RESOLVE_SOURCE /
RESOLVE_DEST. A draw or dispatch after one that wrote a bound UAV gets a UAV barrier first, so a second dispatch reads
what the first wrote.

**Copies.** `copy_buffer_to_image` copies straight from the buffer when its offset is 512-byte aligned and its row
pitch 256-byte aligned; otherwise it repacks the rows into a scratch buffer on the GPU first
(`features().copyBufferToImageRelaxedBytesPerRow`). Zero `bytesPerRow` / `bytesPerSlice` mean a whole mip's pitch and
zero sizes the rest of the mip, as in sokol. `push_debug_group` / `pop_debug_group` are PIX events.

**Readbacks.** `read_buffer`, `read_image_rgba8` (BGRA is swizzled to RGBA), `read_image_rgba16f`,
`read_storage_image` and, for tests, `read_image_region(image, mip, layer, x, y, w, h)` copy into a READBACK buffer on
an internal list, wait for it and unpack the rows. They block. The region's layout in the buffer comes from
`GetCopyableFootprints` (rows 256-byte aligned) and is repacked to tight rows.

**Asynchronous reads.** `request_buffer_read` (and, D3D12 only, `request_image_read(image, mip, layer, x, y, w, h)`)
copy on an internal list executed at once, behind every list submitted so far, into one of 32 slots (as SokolDevice's
8 rings of 4); each slot keeps a READBACK buffer, grown to the next 64 KiB when a read needs more. The slot's fence
value says when the bytes are there: `poll_buffer_read` hands them over (an image region tightly packed) once the
fence passed, never waits unless asked to (`wait`, bounded like every fence wait), and makes the ticket stale. A
ticket is `{slot, generation}`: a stale or released one is ignored even after its slot was reused, and a released slot
is reused only once its copy finished. Every slot busy = an invalid ticket with ok. A read keeps its source alive
through `destroy_buffer`.

**Pack reads** (`d3d12_pack_reads_win32.cpp`, M77). `read_pack_to_buffer` and `read_pack_to_image` write a range of a
`game.pak` file into a buffer or a texture region and return a ticket (`poll_pack_read`, `release_pack_read`, 64
slots). A gdeflate file of a pack opened from disk goes through DirectStorage with the device set on its queue (GDeflate
decoded on the GPU where it can): the texture's subresource first moves to COMMON on an internal list, the requests
follow once that list finished, and the queue waits for DirectStorage's fence before later lists. Anything else is
decoded on the CPU and uploaded, with one warning per reason. ARCHITECTURE_FILES.md, "DirectStorage", has the rules;
`d3d12_pack_reads_tests.cpp` tests both paths on WARP.

**GPU timers.** Timestamp queries on the direct queue (`GetTimestampFrequency`; `timer_supported` is false with the
reason when the queue cannot give one or the query heaps cannot be made). Like GpuTimer on D3D11 and GL: a ring of 6
timed frames, each with its own query heap and READBACK buffer (a full ring skips the frame), query 0 and 1 the
frame's start and end, two per scope after them, at most 64 scopes per frame. `timer_begin_frame` and
`timer_end_frame` record their timestamps on the internal list; the end also resolves the frame's queries into its
buffer and executes it, and its fence value says when `timer_poll` can read it (in order, never waiting). Scopes do
not nest (a begin ends the one still open, submit ends one left open) and do nothing outside a timed frame; a scope
whose list was not submitted before `timer_end_frame` is not reported. `timer_last_scopes` is the newest resolved
frame's scopes in the order they ran; `timer_forget` drops what is in flight.

**Shaders.** `make_shader` takes shader model 5.x DXBC (`bytecode`, which must start with `DXBC`; DXIL is not taken)
or HLSL `source`, which it compiles to vs_5_1 / ps_5_1 / cs_5_1 with `D3DCompile` from `d3dcompiler_47.dll`, loaded at
run time, with the flags of the D3D11 path; the compiler's own lines go into the error. Through
`render::make_shader` (shader_cache.cpp) the engine compiles the stages itself and keeps the DXBC in the disk cache,
under keys of their own (`d3d12|...`), so the shaders of the generated headers (sokol-shdc's `hlsl5` output) reach
the device as bytecode. The reflection is `ShaderDesc`: each uniform block, view and sampler names its `hlslRegister`
and `hlslSpace` (views: `t` for textures and read-only storage buffers, `u` for storage images and written storage
buffers, `hlslRegisterU`). Two slots of a stage on one register, a slot in a stage the shader does not have, a block
of 0 or more than 65536 bytes, a `t` register in space1 (the bindless table's) and a desc with both compute and
render stages are errors before any D3D12 call.

**Root signatures.** Version 1.0, one per register layout, cached by a key text of every slot's stage, register and
space (`counters().rootSignatures`, `rootSignatureCacheHits`): every uniform block is a root CBV visible to its stage;
then each stage has one descriptor table of its views (SRV and UAV ranges, one descriptor per slot, in slot order) and
one of its samplers; then, when `bindlessDescriptors` > 0, an unbounded SRV table at t0, space1, visible to every
stage. A render root signature allows the input assembler and denies the hull, domain and geometry stages.
`D3d12Device::shader_root_layout(shader)` returns where each slot sits (for tests).

**Pipelines.** `make_pipeline` builds a graphics or compute PSO from `PipelineDesc` with sokol's defaults (packed
vertex offsets when every offset is 0, stride 0 = the packed size, Default formats = the context's). It checks what
D3D12 would refuse or misdraw first: a vertex attribute without an HLSL semantic in the shader or with format Int10N2
(D3D has none), a colour target this GPU cannot render to, blend or multisample, a depth format that is not one, a
sample count other than 1, 2, 4 or 8, a compute pipeline with a render shader or the reverse, a failed shader. PSOs
are cached in memory by a key text of the bytecode's SHA-256, the root signature's key and every field
(`counters().psos`, `psoCacheHits`, `psoCacheMisses`): equal descs share one PSO, which lives as long as the device.
On resource binding tier 1 a shader with more writable views (storage buffers and images, all stages) than the tier
binds (8 at feature level 11.0, 64 above) fails with the count and the limit. `storage_image_loadable` asks the
format's `UAV_TYPED_LOAD` support (and `TypedUAVLoadAdditionalFormats` for all but R32F) and says which one is missing.

**Pipeline cache on disk (M77-P7b).** With `D3d12Options::pipelineCacheFile` set (the engine's file is
`d3d12_pipeline_cache_file()`: `<cache dir>/shaders/d3d12-pipelines.bin`, next to the shader cache) the device keeps an
`ID3D12PipelineLibrary`: `pso()` loads a PSO from it by the SHA-256 of its key before compiling, and stores what it
compiles. The file is a 120-byte header (`PipelineCacheFile`: magic `FAPSOLIB`, version, the adapter's vendor, device,
subsystem and revision ids, the driver version, the payload's size and SHA-256) and the library's bytes. A file that
fails a check, or that `CreatePipelineLibrary` refuses (`E_INVALIDARG`, `D3D12_ERROR_ADAPTER_NOT_FOUND`,
`D3D12_ERROR_DRIVER_VERSION_MISMATCH`), is thrown away with one warning (`warnings()` and the log) that says why: the
PSOs are compiled again and the file written anew. `save_pipeline_cache()` writes the file when the library holds PSOs
it does not (also when the device is destroyed), atomically through `fs::write_bytes`; a failure (another process holds
the file, a full disk) keeps the old file and warns. Deleting the file clears the cache. `counters()` has
`pipelineLibrary`, `psoLibraryHits`, `psoLibraryMisses`, `pipelineCacheStored` and `pipelineCacheDiscarded`; the
process totals are the `pipelineCache` object of the shader cache report (`ShaderBuildStats::to_json`, the `gpu` part
of `loading.startup`). `make_device(Backend::D3d12)`, the renderer's way to the device, sets it.

**Passes and draws.** `begin_pass` checks its attachments (live views of the right kind, one size, the resolve
single-sampled with the colour format, the depth sample count equal to the colour one) and that `PassDesc::format` is
what they are; it sets the targets, clears what `colorLoad` / `depthLoad` / `stencilLoad` say (Clear, or Default),
and a viewport and scissor over the whole target. `end_pass` resolves an MSAA colour attachment into `resolve`. A pass
into the window (`PassDesc::swapchain`) is an error that says the backend has no window path yet and to pick the
sokol backend for a window. `set_pipeline` checks that the pipeline is a render
one in a render pass and a compute one in a compute pass, and that its formats, colour count and sample count equal
the pass's. `set_bindings` checks every slot against the shader (an empty slot the shader declares, a slot it does
not, a view of the wrong kind, a buffer without the usage, a view of a mip and layer the pass draws into) and `set_uniforms` the block's exact size; uniforms are
copied into the upload ring (256-byte aligned) and bound as root CBVs. Draws and dispatches check that every uniform
block was set and `set_bindings` called since `set_pipeline`. As in sokol, once a `set_pipeline`, `set_bindings` or
`set_uniforms` fails, the draws are skipped without further errors until the next `set_pipeline`, and everything
inside a pass whose `begin_pass` failed is skipped. `draw_ex`'s `baseVertex` is the index offset with an index buffer
and is added to `base` without one; dispatch counts are 0 to 65535 per dimension.

**Not yet.** The window: `create_swapchain` and the calls after it fail with the default's teaching error (the DXGI
swapchain is a later package).

**Tests.** `engine/render/tests/d3d12_device_tests.cpp` (ctest `render_d3d12_device`): on Windows each case makes a
WARP device with the debug layer and ends by checking that the layer reported no error. Resources: buffer and image
round trips with mips, RGBA8 and RGBA16F, both `copy_buffer_to_image` paths, deferred destruction, the ring's wrap and
the dedicated uploads, descriptor exhaustion and reuse. Drawing, each read back and checked per texel: a clear-only
pass; a uniform-colour fullscreen triangle into RGBA8 and RGBA16F; the engine's own blit shader (the HLSL of
`blit.glsl.h`) with a nearest and a linear sampler; an indexed, instanced draw with a base vertex; a depth test and a
viewport; an MSAA 4x resolve (the texels on the triangle's edge are partly covered); a compute pass writing a storage
image and a storage buffer, whose second dispatch reads the first's writes. GPU timers: timed frames with two scopes
resolving to non-negative times in order, a scope outside a timed frame, an unsubmitted scope, `timer_forget` and a
full ring, a dropped frame's slot, a scope whose slot was reused. Asynchronous reads: a buffer, a 33x3 region of a 37x5 RGBA8 image (rows that are not 256-byte multiples),
bad requests, a read that outlives `destroy_buffer`, stale and released tickets, 32 reads in flight and the 33rd
refused, a slot buffer that grows. The pipeline cache file: a second device loads every PSO from it; a damaged
file, another GPU's, another driver's, a cut one and one that is not a cache are each thrown away with one warning; a
held file keeps its old bytes. `storage_image_loadable` for RGBA8, R32F and a format it never loads; a view of the
pass's own attachment. Then the PSO and root-signature caches,
the root signature of a shader with one block, two views and two samplers, and every error of `make_shader`,
`make_pipeline` and the command list. A Windows without WARP says so with a MESSAGE and passes. Elsewhere one case
checks the factory's error. `D3d12Device::counters()`, `view_heap()`, `shader_root_layout()` and
`read_image_region` exist for these tests.
