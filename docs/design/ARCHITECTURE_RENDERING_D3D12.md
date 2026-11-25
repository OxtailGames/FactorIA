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

**Frames, fences, deferred destruction.** Three queues, each with its own 64-bit fence (see "Queues" below).
`submit(list)` closes the list and executes it on its queue, then signals that queue's fence; `commit()` signals the
graphics fence and records the frame's value of every queue's fence, and once more frames than `framesInFlight` were
committed it waits (up to 120 s, then an error) for the oldest one on every queue, whose descriptor segment and ring
room the new frame reuses. `destroy_*` frees the handle at once and keeps the D3D12 object (and its descriptors) in a
deferred list tagged with the current frame; it is released once every queue passed that frame's value
(`counters().pendingReleases`).
`execute` keeps every resource a submitted list used alive until that frame is done, so a resource destroyed while
the GPU still reads it lives on. `wait_idle()` drains the queue and releases everything pending. A list must be
submitted in the frame `begin_commands` gave it (its uniforms and descriptors sit in that frame's ring room and
descriptor segment): one submitted after a `commit()` is dropped with an error.

**Queues (M77-P10b).** A direct queue (Graphics), a COMPUTE queue (Compute) and a COPY queue (Transfer, the copy
engine), each with its own fence, command allocators and lists of its type; `D3d12Options::asyncQueues = false`, or a
GPU that cannot make one, leaves it out: Transfer lists then run on the compute queue (or the direct one), Compute
lists on the direct one, and `CommandList::queue()` says which. `features().asyncCompute` is true when the compute queue exists.
`submit_token(list, handoffs)` returns `{queue, fence value}`; a dropped list still signals, so its token can be
waited for. `wait_list` records the token in the list (any thread) and its submit makes the queue `Wait` on the other
queue's fence before the list and its fix-up list; `wait_queue` waits at once. Waiting for a token no `submit_token`
returned is reported and ignored. Handoffs are resolved at submit, on the render thread: every resource remembers its
owner queue (new ones: Graphics) and the token of its last handoff. A handoff of a texture moves it to COMMON at the end
of the producer's list (buffers are COMMON between lists anyway); the consumer's fix-up list moves it on from there,
on the consumer's queue type. A list that uses a resource its queue does not own is dropped with an error naming the
resource, the queues and the `QueueHandoff` that fixes it; one that uses a handed-over resource without waiting for
its token is reported and the wait is added. The device's own lists (uploads, readbacks: direct) may touch what
another queue owns: their queue waits for that queue first, leaves its textures in COMMON, and that queue waits for
them in turn. A COPY list sets no descriptor heap and its resources decay to COMMON after it ran; a Compute list reads
bound textures as NON_PIXEL_SHADER_RESOURCE only, and a Transfer list records no pass.

**Threads (M77-P10b).** `features().multiThreadRecording` is true: `begin_commands`, every list call and `wait_list`
may run on any thread, each list with its own allocator. The resource pools share one lock; the CPU descriptor heaps,
the upload ring, the shader-visible heaps, the timers and the lists each have their own, so different lists record at
the same time. The descriptor copies of `set_bindings` and the attachment lookups of `begin_pass` run under the
resource lock, so a `destroy_*` on the render thread never removes a record one of them is reading. Lock order: queue, then timers; resources, then the
heaps and the bindless slots (always last).

**Bindless (M77-P10b).** `features().bindless` is true when the device made a bindless table. Every live texture view
gets a slot of it when it is made (a copy of its SRV, `bindless_index(view)`), `kNoBindlessIndex` once the table is
full or for any other view. The slot goes back with the view's descriptors once the frames that may read it are done,
after a null SRV is written into it. The root signatures are version 1.0 (volatile descriptors), so a slot is written
while other lists run.

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
reason when the queue cannot give one or the query heaps cannot be made). Scopes of a compute list are timed with the
compute queue's own frequency (when it has one; the frame's resolve waits for the compute fence value they end at);
scopes of a copy list are ignored. Like GpuTimer on D3D11 and GL: a ring of 6
timed frames, each with its own query heap and READBACK buffer (a full ring skips the frame), query 0 and 1 the
frame's start and end, two per scope after them, at most 64 scopes per frame. `timer_begin_frame` and
`timer_end_frame` record their timestamps on the internal list; the end also resolves the frame's queries into its
buffer and executes it, and its fence value says when `timer_poll` can read it (in order, never waiting). Scopes do
not nest (a begin ends the one still open, submit ends one left open) and do nothing outside a timed frame; a scope
whose list was not submitted before `timer_end_frame` is not reported. A slot is not taken again while a list that
holds one of its scopes is open, nor before every queue finished writing its queries. `timer_last_scopes` is the newest resolved
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
On resource binding tier 1 a shader with more writable views (storage buffers and images, all stages; a view that
several stages see counts once) than the tier binds (8 at feature level 11.0, 64 above) fails with the count and the
limit. `storage_image_loadable` asks the
format's `UAV_TYPED_LOAD` support (and `TypedUAVLoadAdditionalFormats` for all but R32F) and says which one is missing.

**Pipeline cache on disk (M77-P7b).** With `D3d12Options::pipelineCacheFile` set (the engine's file is
`d3d12_pipeline_cache_file()`: `<cache dir>/shaders/d3d12-pipelines-<program>-<hash>.bin`, next to the shader cache) the device
keeps an `ID3D12PipelineLibrary`: `pso()` loads a PSO from it by the SHA-256 of its key before compiling, and stores
what it compiles. Each program has its own file (`d3d12_pipeline_cache_name(d3d12_program_name())`: the executable's
name without its extension, lower case, every character but `a-z`, `0-9`, `-` and `_` made `_`, at most 48 of them, then
the first 8 hex digits of the SHA-256 of the whole lower-cased name, so accented names or names cut at 48 characters
never collide): the editor, the CLI and each exported game's player share no file, so one never overwrites the PSOs
another stored (a library cannot be merged: its PSOs can be loaded only with their descs). The SDK's `factoria_player`
is one program: it keeps one file for all the projects it runs, so their PSOs share it until a library over the trim
size is rebuilt with only the PSOs of the run that saves it. The file is a 120-byte header (`PipelineCacheFile`: magic `FAPSOLIB`,
version, the adapter's vendor, device, subsystem and revision ids, the driver version, the adapter's LUID, the
payload's size and SHA-256) and the library's bytes. `pipeline_cache_mismatch` (d3d12_device.cpp, tested on every
platform) checks it; the LUID is recorded but not compared, since Windows gives an adapter a new one at every boot. A
file that fails a check, that is over `PipelineCacheFile::kMaxBytes` (1 GiB), or that `CreatePipelineLibrary` refuses
(`E_INVALIDARG`, `D3D12_ERROR_ADAPTER_NOT_FOUND`, `D3D12_ERROR_DRIVER_VERSION_MISMATCH`), is thrown away with one
warning (`warnings()` and the log) that says why: the PSOs are compiled again and the file written anew. Reading it is
one read of the whole file, before the first present, so it counts once in the startup report's
`diskReadsAtFirstPresent`. The header key is the vendor, device, subsystem and revision ids and the driver version; the
LUID is not part of it. At load the temporary files of this cache file (`<file>.fa-tmp<pid>_<n>`) that are at least a
minute old are deleted (a crashed save left them; one another process still holds fails to delete and stays, and a
younger one may belong to a save running now).

`save_pipeline_cache()` (also called when the device is destroyed) writes the file when the library holds PSOs it does
not. A library over `D3d12Options::pipelineCacheTrimBytes` (default 64 MiB; 0 = never) is first rebuilt with only the
PSOs this device made or loaded, once per device, and replaces the old one when it is smaller: PSOs no run asks for
leave the file instead of piling up (the old library stays alive with the PSOs loaded from it, and `pso()` looks in
it, after the current library, for a PSO the run asks for later; one found there is stored into the current library, so
the next file keeps it). `pipelineCacheTrimmed` and the process total `trimmed` count a trim when a file holds it: a
trimmed library whose write failed counts at the save that writes it. A run that made no PSO
keeps the file as it is. The write goes to a temporary file next to the cache, then `MoveFileExW` with
`MOVEFILE_REPLACE_EXISTING`: a reader never sees half a file. A reader that holds the old file open (Windows replaces
no open file) is waited for three 1 ms tries (up to about 50 ms with Windows' timer steps), not the second of
`fs::replace_file`, since a cache is only a speed-up; when the move fails because the TEMPORARY file is the one held (an
antivirus or indexer scanning what was just written: opening the temporary file for delete is a sharing violation) the
save waits up to 8 x 20 ms (bounded: 160 ms nominal, about 250 ms with the Windows timer steps). Access denied is told apart by probing: the old file
read-only (a hint that says to clear the attribute, `attrib -r <file>`), the old file held (as a reader), or neither
(the folder's or the file's permissions, or a program that holds the file with delete sharing, a mapped view, which
answers access denied too: the hint names both). `d3d12_classify_cache_write_error`,
`d3d12_cache_replace_policy` and `d3d12_cache_write_hint` are the pure parts, tested on every platform. Every failure
(serializing the library, a library over 1 GiB, a reader, a full disk) keeps the old file, counts in `storeFailed`,
leaves the library to the next save (or the next run, when the device is destroyed first), and is a warning that
names the file and what to do; a write is logged (info) with its size, and a trimmed one with what it dropped.
Deleting the file clears the cache. `counters()` has `pipelineLibrary`, `psoLibraryHits`, `psoLibraryMisses`,
`pipelineCacheStored`, `pipelineCacheDiscarded` and `pipelineCacheTrimmed`; the process totals are the `pipelineCache`
object of the shader cache report (`ShaderBuildStats::to_json`, the `gpu` part of `loading.startup`: `hits`, `misses`,
`filesLoaded`, `stored`, `discarded`, `storeFailed`, `trimmed`). `make_device(Backend::D3d12)`, the renderer's way to
the device, sets it.

**Passes and draws.** `begin_pass` checks its attachments (live views of the right kind, one size, the resolve
single-sampled with the colour format, the depth sample count equal to the colour one) and that `PassDesc::format` is
what they are; it sets the targets, clears what `colorLoad` / `depthLoad` / `stencilLoad` say (Clear, or Default),
and a viewport and scissor over the whole target. `end_pass` resolves an MSAA colour attachment into `resolve`. A pass
into the window (`PassDesc::swapchain`) draws into the back buffer of the frame ("Swapchain" below). `set_pipeline` checks that the pipeline is a render
one in a render pass and a compute one in a compute pass, and that its formats, colour count and sample count equal
the pass's. `set_bindings` checks every slot against the shader (an empty slot the shader declares, a slot it does
not, a view of the wrong kind, a buffer without the usage, a view of a mip and layer the pass draws into) and `set_uniforms` the block's exact size; uniforms are
copied into the upload ring (256-byte aligned) and bound as root CBVs. Draws and dispatches check that every uniform
block was set and `set_bindings` called since `set_pipeline`. As in sokol, once a `set_pipeline`, `set_bindings` or
`set_uniforms` fails, the draws are skipped without further errors until the next `set_pipeline`, and everything
inside a pass whose `begin_pass` failed is skipped. `draw_ex`'s `baseVertex` is the index offset with an index buffer
and is added to `base` without one; dispatch counts are 0 to 65535 per dimension.

**Swapchain** (d3d12_swapchain_win32.cpp, M77-P9c). `create_swapchain(SwapchainDesc)` makes a flip-model DXGI swapchain
on the HWND of `nativeWindow` (`CreateSwapChainForHwnd` on the graphics queue, `DXGI_SWAP_EFFECT_FLIP_DISCARD`, one buffer
more than the frames in flight, at least 2, so the GPU never waits for a buffer still queued for the display;
Alt+Enter left to the window). It checks the desc before any DXGI work: a
null or destroyed window, a negative size (0 is the window's client size), a sample count that is not 1, 2, 4 or 8, a
format it does not take, MSAA of a format that cannot, MSAA of an sRGB format (the back buffers are UNORM and
`ResolveSubresource` needs one format on both sides), a size over the GPU's largest image. Where DXGI allows tearing
(`DXGI_FEATURE_PRESENT_ALLOW_TEARING`) the swapchain is made with it and `present()` tears only when `vsync` is off. A
frame-latency waitable (`SetMaximumFrameLatency` = frames in flight) is waited for in `acquire_swapchain`, at most one
second (a hidden or occluded window may never signal it; the wait is then counted, `swapchain_wait_timeouts()`, and the
frame goes on; with no buffers after a failed resize it is not waited for). `ResizeBuffers` and `Present` run on the
render thread, not the one pumping the window's messages: DXGI may send that window messages and wait for them, so the
window thread must never block on the render thread while it resizes or presents. The formats (`swapchain_format_supported`, which asks the GPU for DISPLAY and RENDER_TARGET support of
the buffer format): Default is the device's SDR format (Bgra8); Bgra8, Sbgr8A8, Rgba8, Srgb8A8 make UNORM buffers (the
sRGB ones get sRGB views); Rgba16F is scRGB (`DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709`) and Rgb10A2 is HDR10
(`G2084_NONE_P2020`). For those two `create_swapchain` asks `CheckColorSpaceSupport` and sets the space; a display that
does not present it is an error that says to turn HDR on or ask for Default.

The back buffers join the image pool as images with a colour-attachment view each (a resolve view when the swapchain is
multisampled, which adds an MSAA image), and a depth image of the device's depth format; their tracked state starts as
PRESENT. `acquire_swapchain` hands back a `Swapchain` with the size, sample count and formats; a pass made with
`PassDesc::for_swapchain` over it is rewritten by `begin_pass` into a pass into the frame's back buffer (or the MSAA
image resolving into it) and the depth view, after checking that the frame was acquired and that the `Swapchain` has
the current size. `present()` ends the frame: an internal list on the graphics queue moves the back buffer to PRESENT
behind the frame's lists, then `IDXGISwapChain::Present` (`DXGI_STATUS_OCCLUDED` is a success). `resize_swapchain(w, h)`
(0 is the client size; the same size with whole buffers does nothing) is refused between acquire and present; it
destroys the views and images, waits for the GPU to finish with the buffers, calls `ResizeBuffers` with the creation
flags and makes the views again (a failure makes the old buffers again and returns the error). `destroy_swapchain()`
(also in the destructor) releases everything the same way. `swapchain_image()` (the back buffer of the frame, for a
test's read-back), `swapchain_buffer_count()` and `swapchain_tearing()` are D3D12 only.

The renderer resizes the device's swapchain in `Renderer::present` when the framebuffer size changes (an error is
logged once). The window comes in `RendererDesc::nativeWindow`: the runtime claims the HWND from the platform, which
destroys its D3D11 presenter first (one flip-model swapchain per window; ARCHITECTURE_RENDERING_GPU.md, "Windows
presentation"). A renderer without one still fails `init()` with the swapchain's own "nativeWindow is null" error.

**Tests.** `engine/render/tests/d3d12_device_tests.cpp` (ctest `render_d3d12_device`): on Windows each case makes a
WARP device with the debug layer and ends by checking that the layer reported no error. Resources: buffer and image
round trips with mips, RGBA8 and RGBA16F, both `copy_buffer_to_image` paths, deferred destruction, the ring's wrap and
the dedicated uploads, descriptor exhaustion and reuse. Drawing, each read back and checked per texel: a clear-only
pass; a uniform-colour fullscreen triangle into RGBA8 and RGBA16F; the engine's own blit shader (the HLSL of
`blit.glsl.h`) with a nearest and a linear sampler; an indexed, instanced draw with a base vertex; a depth test and a
viewport; an MSAA 4x resolve (the texels on the triangle's edge are partly covered); a compute pass writing a storage
image and a storage buffer, whose second dispatch reads the first's writes. GPU timers: timed frames with two scopes
resolving to non-negative times in order, a scope outside a timed frame, an unsubmitted scope, `timer_forget` and a
full ring, a dropped frame's slot, a list open over the whole ring that keeps its slot. Queues: lists of each queue,
tokens and a made-up one, a device without the side queues; a buffer from graphics to compute and back (and the errors
of a missing handoff and a missing wait); a texture written by compute and sampled by graphics, three frames over; two
threads recording on the graphics and compute queues while the render thread destroys other resources; bindless slots
of live views, read by a shader, and a freed slot reused; a timed scope on a copy list ignored, graphics and compute
scopes measured. Asynchronous reads: a buffer, a 33x3 region of a 37x5 RGBA8 image (rows that are not 256-byte multiples),
bad requests, a read that outlives `destroy_buffer`, stale and released tickets, 32 reads in flight and the 33rd
refused, a slot buffer that grows. The pipeline cache file: a second device loads every PSO from it; a damaged
file, another GPU's, another driver's, a cut one and one that is not a cache are each thrown away with one warning; a
held file keeps its old bytes. `storage_image_loadable` for RGBA8, R32F and a format it never loads; a view of the
pass's own attachment. The swapchain: on a hidden 64x48 Win32 window, three frames cleared to three colours, each back
buffer read back before present, a resize to 96x64 and a frame, the same size again, then destroy; the mistakes
(present before acquire, a second create, a resize between acquire and present, a pass with a stale size, acquire
after destroy); a null window, a bad sample count and format, the HDR format query, and an scRGB swapchain that is
either made or refused with a teaching error. Then the PSO and root-signature caches,
the root signature of a shader with one block, two views and two samplers, and every error of `make_shader`,
`make_pipeline` and the command list. A Windows without WARP says so with a MESSAGE and passes. Elsewhere one case
checks the factory's error. `D3d12Device::counters()`, `view_heap()`, `shader_root_layout()` and
`read_image_region` exist for these tests. `make_device(Backend::D3d12)` reads two hooks of the environment:
`FA_D3D12_WARP=1` makes the device on WARP and `FA_D3D12_DEBUG=1` turns the debug layer on. The renderer case of
`renderer_backend_tests.cpp` sets both and draws the 2D and 3D scenes on D3D12 against the sokol backend's pictures
(the Vulkan case's tolerance); it skips with a MESSAGE without WARP, unless `FA_D3D12_REQUIRE=1` (the Windows CI job).

## Native access for vendor SDKs (M78)

The upscalers and latency SDKs of M78 (Streamline, XeSS, FSR 3.1) record their own D3D12 commands into the engine's
command list. The interface is the same as on Vulkan ([ARCHITECTURE_RENDERING_VULKAN.md](ARCHITECTURE_RENDERING_VULKAN.md),
"Native access for vendor SDKs", which lists the checks of each entry); here is what D3D12 does with it.

- **Which GPU.** `DeviceInfo::gpu` comes from the adapter's `DXGI_ADAPTER_DESC1`: `vendorId`, `deviceId`, the LUID
  (`luidValid` always true), `vendor` through `gpu_vendor_from_pci`, and `software` on WARP (Microsoft 0x1414). The
  sokol D3D11 backend fills the same fields from its device's DXGI adapter (`software` for WARP's 0x1414 / 0x8C).
- **The objects.** `native()` gives `device` (`ID3D12Device*`), `context` (the direct `ID3D12CommandQueue*`),
  `computeQueue` (the compute queue) and `adapter` (`IDXGIAdapter1*`; D3D11: its `IDXGIAdapter*`), all borrowed: they
  live as long as the `Device`, and an SDK that keeps one longer `AddRef`s it. `native_image()` adds `resource` and
  `nativeFormat` (the resource's `DXGI_FORMAT`, typeless for depth); `native_buffer()` gives the `ID3D12Resource*`;
  `native_view()` gives the view's CPU descriptor (`d3d12Descriptor`, in the engine's non-shader-visible heap of its
  kind: copy it, never write into it; a storage buffer's is its raw view as `R32_TYPELESS`) and its format (the RTV or
  DSV format for an attachment view, the SRV format otherwise), image, mips and slices.
- **Recording.** `begin_native(uses)` makes the same checks as on Vulkan, then moves each range to its state through
  the engine's tracking (a UAV barrier first for an `UnorderedAccess` entry the engine left in that state, so its
  writes finish before the SDK's), flushes the barriers and answers `NativeCommands{D3d12, ID3D12GraphicsCommandList*,
  queue}`. `Common` is `COMMON`, `ShaderRead` `PIXEL_SHADER_RESOURCE | NON_PIXEL_SHADER_RESOURCE` (only
  `NON_PIXEL_SHADER_RESOURCE` on a compute list), `UnorderedAccess` `UNORDERED_ACCESS`, `RenderTarget` `RENDER_TARGET`,
  `DepthWrite` `DEPTH_WRITE`, `DepthRead` `DEPTH_READ` with the shader-resource states, `CopySource` `COPY_SOURCE`,
  `CopyDest` `COPY_DEST`.
- **After the section.** `end_native(leftIn)` checks that each `leftIn` subresource was declared, then sets the tracked
  state of each one to its `leftIn` state with no barrier (the native commands recorded their own transitions); the
  next engine use transitions from there, and a UAV the engine binds again gets its UAV barrier. It sets the engine's
  two shader-visible descriptor heaps again and resets the bind state (root signature, pipeline, tables). While the
  section is open `begin_pass` and `begin_compute_pass` fail the pass; a list submitted with its section open is
  reported and closed as declared. The native commands may not close, reset or submit the list.
- **Tests.** `engine/render/tests/d3d12_native_tests.cpp` (ctest `render_gpu_native`, Windows, on WARP; it skips with a
  MESSAGE without WARP unless `FA_D3D12_REQUIRE=1`): the identity (Microsoft, software, the LUID of `GetDesc1`), the
  native formats against `d3d12::format_info`, a `ClearRenderTargetView` through `native_view`'s descriptor and a
  `CopyBufferRegion` read back by the engine, a `ResourceBarrier` to the shader-resource states handed back in
  `leftIn` and read back, and the refusals, with no debug-layer error (where the Graphics Tools are installed).
- **Not built yet (M78-P2b).** A hook before the device is made and around the swapchain (what Streamline needs) has no
  entry point yet.
