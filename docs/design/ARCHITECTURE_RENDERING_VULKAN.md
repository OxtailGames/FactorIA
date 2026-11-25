# FactorIA architecture: the Vulkan backend (M77)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the GPU interface it implements is
[ARCHITECTURE_RENDERING_GPU.md](ARCHITECTURE_RENDERING_GPU.md)). The engine's own Vulkan device: M77-P8a built the core
(loader, device, memory, resources, barriers, transfers, descriptors, readbacks), M77-P8c the shaders, pipelines,
passes, draws and dispatches, M77-P8b1 the GPU timers, the asynchronous reads and the synchronization fixes that
lavapipe's synchronization validation asks for, M77-P8b2 the pipeline cache on disk, the descriptor pool chains, the
eviction of the caches, the framebuffer cache and the SPIR-V checks. M77-P9b lets the renderer draw through it
offscreen (`RendererDesc::backend = GpuBackend::Vulkan`, [ARCHITECTURE_RENDERING_GPU.md](ARCHITECTURE_RENDERING_GPU.md),
"The renderer on its backend"); M77-P9d gives it the window: a swapchain on the native window ("Swapchain" below), which
the renderer reaches once it hands the device the window's native handle (a later package).

## Where it is built

Its code is `engine/render/src/gpu/vulkan_device.h` and `vulkan_*.cpp` (loader, device, memory, resources, pipelines,
commands, readback). CMake builds it where `FA_VULKAN_BACKEND` is on: Linux, Windows and Android, and macOS for its
tests only (through MoltenVK; Vulkan is never a macOS product backend, games there use Metal); never on the web or iOS,
where `make_vulkan_device` returns a teaching error. The sources compile with `VK_NO_PROTOTYPES` against the vendored
Khronos headers (`external/vulkan_headers`) and link no Vulkan library: the loader is opened at run time
(`libvulkan.so.1`, `vulkan-1.dll`, `libvulkan.1.dylib` with the Homebrew prefixes on macOS, or
`VulkanOptions::loaderPath`), so a binary on a system without Vulkan starts and the error says what to install. There is
no volk and no VMA. `make_device(Backend::Vulkan)` makes it (`DeviceInit` and the other options at their defaults)
where `FA_RENDER_VULKAN` is on: the renderer's built-in shaders need their SPIR-V, which that option compiles into
`fa_render` (by default ON on Windows; on Linux, Android and macOS only in a build with the tests; never on iOS or
the web).
Tests make it with `make_vulkan_device(VulkanOptions)`.

## The core (M77-P8a)

**Options and start-up.** `VulkanOptions` picks a CPU device (`cpuDevice`: lavapipe) or the best GPU (discrete, then
integrated), the validation layer, the frames in flight (1 to 3), the upload ring's size, the suballocator's block size
and dedicated threshold, the per-frame descriptor pools, the bindless table and `synchronization2`. Contradictions are
errors before any Vulkan call. The instance asks for Vulkan 1.3 where the loader has it (1.2 at least), with
`VK_EXT_debug_utils` and portability enumeration when present; the device needs Vulkan 1.2, timeline semaphores and a
graphics + compute queue, and enables `VK_KHR_portability_subset` where the driver lists it (MoltenVK:
`portability_subset()`). It also takes an async compute queue and a transfer queue where the GPU has them ("Queues"
below). Without the
validation layer installed, or with a layer the loader lists but cannot open, the device is made without it, warns, and
`validation_active()` is false. On macOS, Homebrew's layer manifest names its library by a bare file name dyld does not
find; once per process the device writes a copy of the manifest with the absolute path into the temporary directory and
adds it through `VK_ADD_LAYER_PATH` (unless `VK_LAYER_PATH` or `VK_ADD_LAYER_PATH` is set already), so the user sets
nothing.

**Errors.** Every failed `VkResult` becomes a message with its name (`result_text`). With the validation layer, a
debug messenger (also chained into `vkCreateInstance`) sends ERROR messages to `errors()` and WARNING ones to
`warnings()`, prefixed `gpu vulkan validation:`, and to the log. A misuse the backend catches itself (a write past a
buffer's end, a destroyed handle, an image used with a usage it was not made with) is reported the same way and
records nothing.

**Frames, the timeline, deferred destruction.** One timeline semaphore per queue: each submit signals that queue's
next value. `commit()` records every queue's value for the frame, and once more frames than `framesInFlight` were
committed it waits (up to 120 s, then an error) for the oldest one on every queue, whose descriptor pool and ring room
the new frame reuses. `destroy_*` frees the handle at once and keeps the Vulkan object, its memory and its bindless slot
in a deferred list tagged with the current frame; they are released once every queue passed that frame's value
(`counters().pendingReleases`). `wait_idle()` drains every queue and releases everything pending, the current frame's
destroyed objects included, unless a list is still open (its command buffer may name a view, sampler or framebuffer
destroyed since it recorded it: those wait for the frame). The frame's upload ring room waits for its `commit()`
either way: lists still open may have written into it.

**Memory.** The engine's own suballocator: a pool of blocks (`memoryBlockBytes`) per memory type and per linear or
optimal resource (so `bufferImageGranularity` never matters), first fit with coalescing free ranges; a resource of
`dedicatedThreshold` bytes or more, and every readback buffer, takes an allocation of its own. Host-visible blocks stay
mapped; upload memory is host-coherent, and readback memory that is not is invalidated before the CPU reads it.
`counters().memory` counts blocks, dedicated allocations, live pieces and bytes.

**Resources.** Buffers; 2D, array, cube and 3D images with mips and MSAA; every `ViewDesc` kind (a sampled view, a
storage image, a storage buffer range, colour, depth and resolve attachments: their Vulkan image views); samplers. A
format table maps each `PixelFormat` to its `VkFormat`, texel or block size and aspect, and `caps()` asks the driver
what each format can do. A 2D view of a 3D image needs `imageView2DOn3DImage`, which the portability subset may lack:
without it a 3D image is made without `VK_IMAGE_CREATE_2D_ARRAY_COMPATIBLE_BIT` and a colour attachment view of one of
its slices is refused (draw into a 2D array image instead); the tests turn it off to check that path
(`set_image_view_2d_on_3d_for_tests`).

**Uploads.** `write_buffer`, `write_image` and the initial data of `make_buffer` / `make_image` copy through one
persistently mapped upload ring shared by the frames in flight (rounded up to whole 64 KiB). An upload that does not
fit takes a buffer of its own, released with its frame (`counters().dedicatedUploads`, `uploadRingWraps`). Initial
data is recorded into an internal prelude list that runs before the next submitted list, commit, readback or
`wait_idle`.

**Barriers.** Each image keeps one layout and access per subresource (mip x layer; images start `UNDEFINED`), each
buffer one access. A list tracks, per resource it touches, the state it needs first and the state it leaves; its
barriers are merged over neighbouring mips and layers, batched and flushed before each copy, pass and dispatch, through
`vkCmdPipelineBarrier2` where the device has synchronization2 (core in 1.3) and the Vulkan 1.0
`vkCmdPipelineBarrier` otherwise (`synchronization2 = false` forces it, for its tests; the synchronization2 stage and
access bits above bit 31, such as `SHADER_STORAGE_WRITE`, are mapped to the 1.0 bits that cover them). Lists may be
recorded on several threads and submitted in any order, so at submit a fix-up command buffer moves every subresource
from the state the queue left it in to the one the list starts with, executed just before it (`counters().barriers`);
the fix-up is skipped only for a read whose layout, stages and access the queue's state already covers.

**The synchronization model.** A write followed by a read is a barrier from the write's stages and access to the
read's. A read followed by a read in the same layout needs no barrier, but a read in a stage the last barrier did not
reach (a texture written by a compute pass, sampled by a second compute pass and then by a fragment shader) does: the
list remembers each subresource's last barrier source (`Use::since`) and, when a read adds stages or access that
barrier did not cover, barriers again from that write to the new read, so the chain of execution dependencies always
starts at the write. A list's state changes on the queue only when its submit succeeds: a list that fails to end or
submit is dropped (its resources released with the frame), and the queue's states stay those of the last list that
ran. Descriptor sets are bound in order before each draw or dispatch that needs them, set 0 (uniforms), set 1 (views
and samplers), set 2 (the bindless table), all three again after a pipeline change, so a set 0 of another layout never
disturbs a set 1 bound before it.

**Copies.** `copy_buffer_to_image` copies straight from the buffer when its offset and row pitch are whole texels (or
blocks) and the slice pitch is whole rows; otherwise it repacks the rows into a scratch buffer on the GPU first, one
buffer copy per row (`features().copyBufferToImageRelaxedBytesPerRow`). Zero `bytesPerRow` / `bytesPerSlice` mean a
whole mip's pitch and zero sizes the rest of the mip, as in sokol. `push_debug_group` / `pop_debug_group` are
`VK_EXT_debug_utils` labels, and every object carries its label as its debug name.

**Descriptors.** One chain of descriptor pools per frame in flight. Each pool holds `frameDescriptorSets` sets and
`frameDescriptors` descriptors of each kind; a frame that fills one goes on to the next, made the first time a frame
needs it, up to `frameDescriptorPools` (default 8, 1 to 64) pools a frame (`counters().frameDescriptorPools` says how
many this frame took). The chain is reset when the frame's slot comes round again, and the pools stay made. The device
counts the room itself, so a set larger than one pool, or a frame past its last pool, is refused with the same error on
every driver, naming the option to raise. The bindless table is one update-after-bind set of
`bindlessDescriptors` sampled images (descriptor indexing, partially bound): `make_view` of a Texture view writes one free slot (`bindless_index(view)`
says which; a full table leaves the view without one and warns once), and `destroy_view` frees it once the frames
that may read it are finished. A view never has a second slot. A count over what the device binds in
one stage or puts in one set (MoltenVK: 1212) is lowered with a warning; a device without descriptor indexing has no
table.

**Readbacks.** `read_buffer`, `read_image_rgba8` (BGRA is swizzled to RGBA), `read_image_rgba16f`,
`read_storage_image` and, for tests, `read_image_region(image, mip, layer, x, y, w, h)` copy into a host buffer of
their own on an internal command buffer, wait for the timeline, invalidate non-coherent memory and unpack the rows. They
block. A copy that cannot be submitted returns an error instead of waiting. A readback runs on the graphics queue, so
one of a resource the compute or transfer queue owns is refused ("belongs to the compute queue", hint: hand it
back with `submit_token` and `wait_queue`), and so is one of a swapchain image made without transfer-source usage
(a surface that does not allow it).

**Asynchronous reads (M77-P8b1).** `async_read_supported()` is true. `request_buffer_read(buffer, offset, bytes)` and
`request_image_read(image, mip, layer, x, y, w, h)` (a rectangle of one mip and slice, tightly packed rows, checked as
the blocking reads are) record the copy on an internal list and submit it at once, behind every list submitted so far,
into one of 32 slots, each with a host-visible buffer of its own (whole 64 KiB, grown when a read is bigger). The ticket
is the slot and a generation: `poll_buffer_read(ticket, out, wait)` hands the bytes over once the timeline passed the
copy (`wait` blocks for it), and a ticket that was read to the end or released (`release_buffer_read`) is stale and
ignored, even after its slot was reused. A slot is free again only once its copy finished, so release never waits;
with every slot busy a request returns an invalid ticket and no error (ask again next frame). A read survives
`destroy_buffer` of its source (the copy holds it). Bad requests (no live buffer, zero bytes, past the end, outside
the image) are teaching errors.

**GPU timers (M77-P8b1, `vulkan_timers.cpp`).** The contract of the D3D12 backend: a ring of 6 timed frames, each a
`VK_QUERY_TYPE_TIMESTAMP` pool of 130 queries (the frame's start and end, then two per scope, at most 64 scopes);
`timer_begin_frame` resets the frame's pool and writes its start timestamp on the prelude, `timer_end_frame` writes the
end one and submits the prelude, and a full ring skips the frame instead of waiting. `CommandList::begin_timed_scope`
writes a `BOTTOM_OF_PIPE` timestamp into the list (in the pass's secondary when a pass is open); scopes do not nest (a
begin ends the open one, submit ends the last). `timer_poll` reads the frames whose timeline value passed, never one
still in flight, and never waits: it asks with `VK_QUERY_RESULT_WITH_AVAILABILITY_BIT` (and no `WAIT_BIT`), and a frame
whose results are not available yet (a driver signals the timeline before they are visible, as MoltenVK does from a
command buffer's completion handler) stays for the next poll, at most 120 polls; after that the frame is dropped (its
time is never reported) with one warning, and `VulkanDevice::timer_dropped_frames()` counts the frames dropped so. A
frame that was never really begun (its start timestamps were lost with a failed prelude) and a scope of a pass whose
secondary command buffer failed are dropped, not read. Ticks masked to the queue family's `timestampValidBits`, times
`timestampPeriod` nanoseconds; a scope whose list was not submitted before the frame ended is never read, so no query
that was never written is asked for. `timer_forget` drops the frames in flight, and `destroy_timer` waits for the frames
ended and not read yet before it destroys their pools. A queue family without timestamps (`timestampValidBits` 0) or a
driver without a timestamp period makes `timer_supported()` false with a reason naming the device. The timers time the
graphics queue: `begin_timed_scope` on a list of the compute or transfer queue, or of any queue whose family has no
timestamps, is ignored (its list records no query).

**`storage_image_loadable(format)`** is true where the format has `VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT` with optimal
tiling: the engine's shaders always declare a storage image's format, so a load needs nothing more
(`shaderStorageImageReadWithoutFormat` is not used). Otherwise false with a reason naming the device and the format and
the formats every Vulkan GPU stores (rgba8, rgba16f, r32f, rgba32f). BGRA8 is always false: SPIR-V has no format
qualifier for it, so no shader can declare such a storage image, whatever the driver lists.

**Robustness.** A full buffer or image pool is found before the Vulkan object or its upload is made; a Vulkan object
made while another thread took the last slot is released with its frame, never while the prelude may copy into it. A
list Vulkan could not give is a dead list that ignores everything and lives as long as the device. A device whose
driver lacks a function is destroyed through `vkGetDeviceProcAddr`'s own `vkDestroyDevice`. On Windows the loader is
opened with `LoadLibraryExW`: `vulkan-1.dll` from System32 only, an absolute `loaderPath` from its own directory.

## Queues (M77-P10c)

The contract is `gpu/device.h`'s "Queues, threads and bindless"; this is how the Vulkan backend keeps it.

**Which queues.** `VulkanOptions::queues`. `Auto`: the graphics queue is queue 0 of the chosen graphics + compute
family; async compute takes a compute-only family, else a second queue of the graphics family, else there is none
(`Features::asyncCompute` false, and a `QueueKind::Compute` list runs on the graphics queue). The transfer queue exists
only next to an async compute queue: a transfer-only family whose `minImageTransferGranularity` is 1x1x1, else a
transfer list runs on the compute queue. `GraphicsOnly`: every list on the graphics queue. `OtherFamilies`: as `Auto`,
but without a compute-only family or a second graphics queue it takes another family that computes (one that draws
too), and without a transfer-only family a third family that copies single texels. It exists for the tests: MoltenVK
exposes identical families of one queue each, so `Auto` finds no async compute there and `OtherFamilies` runs the queue
family ownership transfers. `queue(kind)`, `queue_family(kind)`, `queue_index(kind)`, `resolve_queue(kind)` and
`timestamp_valid_bits(kind)` answer for the queue a kind maps to.

**Lists, tokens and waits.** Each queue has a timeline semaphore and up to 64 lists (`kMaxLists`), each list a command
pool of its queue's family (and a second command buffer for its fix-ups), so `Features::multiThreadRecording` is true:
`begin_commands` picks (or makes) and opens a list under the queue lock, and recording touches the list's own pool and
the shared state behind its locks (the upload ring, the resource pools). A list's
`queue()` is the queue it runs on, after the fallback. `submit_token(list, handoffs)` submits and returns `{queue,
value}` of that submission's timeline signal. `wait_list(list, token)` (any thread, while the list is open) and
`wait_queue(queue, token)` (render thread; every later submission on that queue) add a wait for the token's timeline
value, with stage `ALL_COMMANDS`, to the submission; a wait on the list's own queue is dropped (the queue's order holds),
and a token whose value its queue has not signalled yet is a teaching error ("was never returned by submit_token()")
and is left out. Internal lists (the prelude of initial uploads, readbacks, the timers' frame queries) run on the
graphics queue.

**Resources between queues: EXCLUSIVE and ownership transfers.** Every image and buffer is made with
`VK_SHARING_MODE_EXCLUSIVE`; a `QueueHandoff` to a queue of another family is a queue family ownership transfer. The
producer's list ends with the release (from the state the list leaves each subresource in, the layout unchanged), and
the consumer's first list that uses the resource starts with the acquire in its fix-up command buffer, followed by the
usual fix-up into the state that list needs. A resource handed over but not used by the next list of its new queue
stays waiting for its acquire, and a list that hands it on without using it records that acquire just before its own
release. Image subresources still `UNDEFINED`, and buffers the GPU never used, take no part (nothing is kept, and a
transfer cannot leave `UNDEFINED`). Between two queues of one family (async compute on a second graphics-family queue)
only the owner changes: the timeline wait is the execution and memory dependency, and the fix-up barriers do the rest.
`CONCURRENT` sharing was rejected for images: it turns off the compression GPUs keep on render targets and storage
images (AMD DCC, and the like on other vendors) for the whole life of the image, and the backend cannot know at
creation which images will cross queues. The cost of the transfers is two barriers per subresource that crosses, only
on the frames that hand a resource over; the merge joins neighbouring mips and layers in the same layout. The two
halves must name the same subresource ranges, so a transfer merges on its layouts, families and destination state
alone (the release's source stages and accesses differ with what the producer did to each mip; the merged barrier
waits for their union), and both halves skip the same `UNDEFINED` subresources in the same order. The upload buffers (the ring
and an upload too big for it) are the exception: written by the CPU and read by every queue's lists, they are
`CONCURRENT` over the device's families when there are several (a buffer loses nothing by it).

**What is checked.** At submit, a resource a list of another queue owns ("belongs to the graphics queue, but the list
runs on the compute queue") and a resource handed to this queue whose token the list did not wait for (through
`wait_list` or `wait_queue`) are reported; the list still runs. A handoff that names no live resource, both or neither
of image and buffer, a resource the list's queue does not own, or a resource twice is reported and left out. A render
pass on a list that is not of the graphics queue, and a compute pass on a transfer list, fail as other command list
misuse does. The readbacks and asynchronous reads run on the graphics queue, so a resource another queue owns is refused ("belongs to
the compute queue") until it is handed back to the graphics queue. A handoff of a resource the list does not use is
checked as the owner checks are: the list must have waited for the handoff that brought the resource to its queue. A
handoff is marked settled only once the submission that waited for it worked; a list that uses the swapchain image
and does not run on the graphics queue is reported and not submitted.

**Locks.** `queueMutex_` guards the queues, lists and timelines; `resMutex_` the resource pools and their tracked
states. `resMutex_` may be taken while `queueMutex_` is held (submit validating handoffs, the owner checks naming a
resource), never the other way round.

**Bindless.** Where the bindless table exists (`Features::bindless`), `make_view` gives every texture view a slot of it
and `bindless_index(view)` answers it (any thread, under the resource lock); storage views, attachments and destroyed
views answer `kNoBindlessIndex`. A full table leaves the view without an index and warns once per device. `destroy_view` frees
the slot with the view's frame.

**A pipeline destroyed while a list binds it.** Each list holds the pipeline state of every `set_pipeline` it recorded
until it is submitted or dropped, so `destroy_pipeline` and `wait_idle` never free a `VkPipeline` an unsubmitted command
buffer names.

## Shaders (M77-P8c)

**SPIR-V only.** `make_shader` (`vulkan_pipelines.cpp`) takes each stage as SPIR-V bytecode: sokol-shdc's `spirv_vk`
output. A stage given as source text is refused ("Vulkan takes SPIR-V"), and bytecode that is not a whole number of
32-bit words with the SPIR-V magic number and header is refused too, and so is SPIR-V whose instructions' word counts
do not add up (a count of 0, or one that runs past the end: the error names the word and the opcode). The driver never
sees such bytes. `tools/shaders/compile_shaders.sh` asks for
`spirv_vk` for every built-in shader and opens the guard of its SPIR-V to `FA_SHADERS_SPIRV` next to `SOKOL_VULKAN`: a
translation unit that drives this backend while sokol runs another one defines `FA_SHADERS_SPIRV` before including a
generated header and calls `<program>_shader_desc(SG_BACKEND_VULKAN)`; every other translation unit carries none of it.
`fa_render` defines it where `FA_RENDER_VULKAN` is on, and `generated_shader_desc(device, ...)` asks a Vulkan device's
headers for `SG_BACKEND_VULKAN`.
A custom material's `spirv_vk` twin keeps each stage in base64 (`custom_shader.cpp`'s dialect for `Backend::Vulkan`);
`render::make_shader` (`shader_cache.cpp`) decodes the stages given as text into bytecode before the device sees them,
and a stage that is not base64 of whole 32-bit words goes to the device as it is, which reports it. There is no disk
cache of shaders on Vulkan: SPIR-V needs no compiling, and the driver's work is in the pipeline cache below.

**Slots and bindings.** The device lays the descriptors out as sokol-shdc does: set 0 holds the uniform blocks (dynamic
uniform buffers, `spirv_set0_binding_n`), set 1 the views and samplers (`spirv_set1_binding_n`; sokol-shdc puts the
samplers from binding 32 on), set 2 the bindless table when the device has one. `make_shader` checks every slot before
any Vulkan call: its stage belongs to the shader's kind (a compute shader's slots are `Compute`, a render shader's
`Vertex` or `Fragment`), a uniform block has 1 to `min(maxUniformBufferRange, 64 KiB)` bytes, each slot is in its set,
and no two slots share a binding; the error names the slot, the set and the binding. A shader keeps its modules and a
SHA-256 of its SPIR-V and entry names (`codeKey`), the pipeline cache's key for its code.

**Layouts.** A descriptor set layout is cached by its bindings (binding, type, stages), a pipeline layout by every slot
with its binding, type and stage plus whether the bindless set is there: two shaders with the same bindings share one,
and two whose slots map to the bindings differently do not (the command list reads the slot -> binding map from it).
`PipelineLayoutInfo` keeps the map, what one set of each kind holds (for the descriptor pools), the stage that reads
each view (what its barriers wait for) and the order of the dynamic offsets (the uniform blocks by binding).
`counters().layoutCacheHits` / `layoutCacheMisses` count both caches.

## Pipelines and render passes (M77-P8c)

**Pipelines.** `make_pipeline` checks the desc against this GPU (vertex formats, `Int10N2` without
`features().vertexFormatInt10N2`, strides that are not multiples of 4 on the portability subset, `stepRate` above 1,
colour formats that do not render, blend or multisample here, dual-source blending, at most the two colour targets a
pass has, sample counts 1, 2, 4 or 8) and says which field is wrong. Its key is the kind, the shader's `codeKey`, the
layout's key and every value of the state; equal keys share one `VkPipeline` (`counters().pipelineCacheHits` /
`pipelineCacheMisses`), so two `Pipeline` handles of the same desc, or of two shaders with the same SPIR-V and slots,
are one Vulkan object. A pipeline is made outside the cache's lock through the device's `VkPipelineCache`
(`pipeline_cache()`, saved to disk: "The pipeline cache file" below); when two threads make the same one, the first is
kept. Viewport, scissor, blend constants and stencil reference are dynamic state, set by the command list. A point
list (`PrimitiveType::Points`) needs a vertex stage that stores to `gl_PointSize` (`spirv_writes_point_size`: a store,
not the declaration, which glslang emits in every vertex shader): otherwise `make_pipeline` refuses it and says to add
`gl_PointSize = 1.0;`, since Vulkan draws such points at an undefined size.

**Eviction.** The caches hold their objects by reference count. A cached `VkPipeline` stays while a live shader has its
code (`codeKey`): `destroy_shader` of the last shader with that code takes its pipelines out of the cache, and a
destroyed `Pipeline` handle lets go of its own reference. Set and pipeline layouts stay while a shader or pipeline
holds them. An object nobody holds any more goes to the deferred release queue and is destroyed once the frames that
may use it are finished, so reloading shaders does not grow the device. `counters().pipelinesCached`,
`pipelineLayoutsCached`, `setLayoutsCached` and `framebuffersCached` count what the caches hold now. Render passes,
which a few formats bound, live as long as the device.

**The pipeline cache file.** `VulkanOptions::pipelineCacheFile` (empty: none; `vulkan_pipeline_cache_file()` is the
engine's place, `shaders/vulkan-pipelines.bin` in the user's cache directory) is read when the device is made and
gives the `VkPipelineCache` its data. The file has a header of its own: the magic `FAVKPSO`, a format version, the
`vendorID`, `deviceID`, `driverVersion` and `pipelineCacheUUID` it was made with, the data's size and its SHA-256. Then
comes the driver's data, whose `VkPipelineCacheHeaderVersionOne` is checked too. A file that is too large, cut,
corrupt, of another format version, or made on another GPU or driver is thrown away with one warning (`warnings()`)
before the driver sees a byte, and so is data the driver refuses; the pipelines are then compiled again and the file is
written anew. `save_pipeline_cache()` writes it, and so does the destructor: only when pipelines were made since the
file was read and the data differs. The write is atomic (a temporary file, then a rename, through `fs::write_bytes`,
which takes long Windows paths and removes its temporary on a failure). A failure (a directory that cannot be made, a
file another process holds open on Windows, a full disk) is one warning plus an error from `save_pipeline_cache()`,
and the old file stays. `counters().pipelineCacheLoaded`, `pipelineCacheFileBytes`, `pipelineCacheStored`,
`pipelineCacheDiscarded` and `pipelineCacheStoreFailed` follow it, like `D3d12Counters` on D3D12.
`make_device(Backend::Vulkan)`, the renderer's device, passes `vulkan_pipeline_cache_file()`.

**Render passes.** Dynamic rendering is off (MoltenVK and the Vulkan 1.2 baseline): a `VkRenderPass` is cached by its
formats, sample count and load/store operations (`counters().renderPassCacheHits` / `renderPassCacheMisses`). Its
attachments are colour 0, colour 1, depth-stencil and the resolve target; each starts and ends in the layout the pass
uses it in, and the command list's barriers put it there. A graphics pipeline is made against a pass with its own
formats and sample count; Vulkan's compatibility rule ignores load/store operations and layouts, and a single-subpass
pass's resolve attachments, so every pass with those formats draws with it. A `VkFramebuffer` is cached by its render
pass, its size and the serial number of each attachment view (`counters().framebufferCacheHits` / `framebufferCacheMisses`), so a pass
into the same targets reuses it list after list; `destroy_view` of an attachment view takes every framebuffer of that view out of the cache (a view destroyed while a
framebuffer was being made is found after the insert, and `begin_pass` fails with an error naming it)
and releases it once its frame is done.

## The command list (M77-P8c)

**Passes.** `begin_pass` makes the same checks as the D3D12 backend, with the same texts: the attachments are live
views of the right kind, of one size, with the formats and sample count `PassDesc::format` says, and the resolve target
single-sampled; a pass into the window (`PassDesc::swapchain`) is a pass into the views of the image
`acquire_swapchain()` took ("Swapchain" below), and one with no image acquired reports that. A failed pass reports
once and skips what is recorded in it without another error. Load actions are Vulkan load operations (`Clear` takes
`clearColor` and `clearDepth`; the stencil is cleared to 0, as on D3D12); a resolve attachment makes the pass resolve the MSAA colour at its end.

**Recording into a secondary command buffer.** A render pass's commands are recorded into a secondary command buffer
(`RENDER_PASS_CONTINUE`) of the list's pool. While the pass is open the list gathers what each attachment and each
bound buffer, view and sampled image needs (layout, stages, access); at `end_pass` it records those barriers on the
list's primary command buffer, begins the render pass with `SECONDARY_COMMAND_BUFFERS`, executes the secondary and ends
the pass. So the barriers a draw needs land before the pass begins, as Vulkan requires (no barrier may change a layout
inside a render pass). Two consequences:
- Draws in one pass get no barrier between them. A subresource used two ways in one pass (drawn into and sampled,
  sampled and written as storage) is refused at `set_bindings` with the mip and layer: draw into it in one pass and
  read it in the next, or read another mip, layer or a copy.
- A transfer called while a pass is open (`write_buffer`, `write_image`, the copies) is recorded on the primary, so it
  runs before the whole pass, not between its draws.

Debug groups follow the command buffer: a group opened in the pass and still open at `end_pass` ends in the secondary
and opens again on the list after the pass; a pop in the pass of a group opened before it is done after the pass.

**Compute passes** record straight into the primary. Before each dispatch the list records the barriers its bound
views need, so a second dispatch that reads what the first wrote waits for it.

**Viewport and scissor.** Y points up as on the other backends: the viewport has a negative height (core in Vulkan
1.1). `begin_pass` sets the whole pass; `set_viewport` with no area skips the draws until the next viewport with one
(Vulkan takes no empty viewport); `set_scissor` is clipped to the pass, in 64 bits.

**Bindings and uniforms.** `set_pipeline` binds the pipeline, the blend constants and the stencil reference (the sets
are bound at the next draw or dispatch, in order: see "The synchronization model"). `set_bindings` checks the vertex and index buffers the pipeline reads (slot by slot, with the index
offset's alignment), each view against the type the shader declares (texture, storage buffer, storage image, its image
type; the sample type is not checked) and the storage buffer offset against `minStorageBufferOffsetAlignment`; then it writes set 1
from the frame's descriptor pool, bound before the next draw or dispatch. A storage buffer's descriptor covers the rest
of the buffer from its offset (`VK_WHOLE_SIZE`) when that fits `maxStorageBufferRange`, and that limit otherwise (128
MiB on Mali, `storage_buffer_range`). Each set has a dirty flag of its own: new uniforms bind set 0 again (with the
same layout, sets 1 and 2 stay bound), new bindings set 1, a new pipeline all three (`counters().descriptorSetBinds`). `set_uniforms` copies the data into the upload ring, aligned to
`minUniformBufferOffsetAlignment` (16 to 256 bytes), and checks its size against the block; before the next draw or
dispatch set 0 is bound with one dynamic offset per block, and the set itself is made once per layout and ring buffers
in a list. A draw before the uniforms or bindings its shader needs reports which and draws nothing.

**Draws and dispatches.** `draw` and `draw_ex` (indexed when the pipeline has an index type, instanced, with a base
vertex) check their counts in 64 bits; `dispatch` takes counts up to `min(65535, maxComputeWorkGroupCount)` per axis
and says the range otherwise. Every misuse is reported as on D3D12 (the list's label, the method, what is wrong, a
hint) and records nothing.

A texture view and a storage image view of one subresource in the same dispatch (one layout cannot serve both) is
refused at the dispatch with the mip and layer and what to do instead (bind another mip or layer, read the storage
image in the shader, or copy the image).

## Swapchain (M77-P9d)

`vulkan_surface.cpp` makes the `VkSurfaceKHR` of `SwapchainDesc::nativeWindow`: an HWND (`VK_KHR_win32_surface`), an
X11 `Window` with its `Display*` in `nativeDisplay` (`VK_KHR_xlib_surface`, declared locally so no Xlib header is
needed), an `ANativeWindow*` (`VK_KHR_android_surface`) or a `CAMetalLayer*` (macOS on MoltenVK,
`VK_EXT_metal_surface`). The instance asks for `VK_KHR_surface`, the platform's surface extension and
`VK_EXT_swapchain_colorspace` where the loader has them, the device for `VK_KHR_swapchain`; without them
`swapchain_format_supported()` is false and `create_swapchain` says the driver has no window path (offscreen drawing
still works). `vulkan_swapchain.cpp` does the rest, on the render thread:

- **`create_swapchain`** checks the desc before it touches the window (a swapchain already, a null `nativeWindow`, a
  negative size, a sample count that is not 1, 2, 4 or 8, a format the backend does not show, a format that cannot be
  multisampled), then makes the surface, checks that the graphics queue family presents to it, and picks its format:
  `Bgra8`/`Rgba8` (and their sRGB twins) in `SRGB_NONLINEAR`, `Rgba16F` in `EXTENDED_SRGB_LINEAR` (scRGB), `Rgb10A2` in
  `HDR10_ST2084`; `Default` is the device's SDR format, or the other 8-bit order of the same kind (`Bgra8` then `Rgba8`;
  the sRGB twin when the default is an sRGB one) when the surface lacks it (Android offers only RGBA). The device's
  default colour format (`environment_defaults().colorFormat`, what a pipeline's `Default` colour target and
  `PassDesc::for_swapchain` mean) then becomes the one picked once the swapchain is made (a swapchain that fails leaves
  the default as it was), before any pipeline is made; when a pipeline or an image was made with the old default
  already, `create_swapchain` fails ("pipelines or images made with that default exist already") and says to make the
  device with `DeviceInit::environment.defaults.colorFormat` set to the format the window offers. The surface's formats
  are asked again from the driver for every new surface and every time the swapchain is made again (a surface recreated
  on Android, a display whose HDR setting changed), and a swapchain made again whose format the surface no longer offers
  fails with a teaching error. The list sits behind a mutex, and `swapchain_format_supported` (const) reads from any
  thread only a copy of the list already loaded: the driver query runs on the render thread (`create_swapchain` and each
  swapchain made again load the list once); a call that finds no list loaded (after a failed query) asks the driver
  itself, so ask from the render thread then. A swapchain that could not be made again leaves its surface, and
  `create_swapchain` destroys that surface before it makes a new one (Android refuses a second surface on a window).
  The present mode is FIFO with `vsync`, else MAILBOX, then IMMEDIATE, then FIFO. A size of 0 is the window's size.
- **The swapchain** has `max(minImageCount, frames in flight + 1)` images (capped by `maxImageCount`), opaque
  composite alpha first, colour-attachment usage plus transfer-source where the surface allows (readbacks). Its
  images are adopted into the device's image pool as external records (their states tracked like any other image's,
  never destroyed by the device), each with a view and a render-finished semaphore; the swapchain's depth-stencil image
  (`EnvironmentDefaults::depthFormat`) and, with `sampleCount > 1`, its multisampled colour image are ordinary images
  of the device. There is one acquire semaphore more than images, each reused only once the timeline value of the
  submission that waited for it passed.
- **`acquire_swapchain`** (a second call in the same frame hands back the same image) waits, at most 100 ms, for the
  next image; when none comes (`VK_TIMEOUT` or `VK_NOT_READY`) it fails (once a warning in the log) and the caller skips
  the frame and acquires again at the next one: the swapchain is untouched. The device does not wait longer (a hidden
  window would stall every frame); the swapchain test cases of a loaded CI VM, where a lavapipe frame can take longer
  than 100 ms, acquire through a helper that tries again up to 20 times, about 2 s in all, before it reports the frame
  as skipped. Then it marks the image `UNDEFINED` (its contents are not kept), and makes the first graphics list
  submitted after it that uses the image wait for the acquire semaphore at `COLOR_ATTACHMENT_OUTPUT`. A
  `PassDesc::for_swapchain` pass (`begin_pass`) becomes a pass into views: the acquired image (or the MSAA image,
  resolved into the acquired one at `end_pass`) and the depth-stencil image; a `Swapchain` of another size is refused.
- **No pre-rotation.** The renderer draws upright, so the swapchain's `preTransform` is IDENTITY wherever the surface
  offers it and the presentation engine turns the picture as the display is turned (M77-P9e3b: on Android, with
  `currentTransform` ROTATE_90 or ROTATE_270, SurfaceFlinger rotates it as it does OpenGL ES's frames; a composition
  pass a pre-rotating renderer would save). Android's loader then answers `VK_SUBOPTIMAL_KHR` at every present; while
  the surface's `currentExtent` is still the swapchain's size that answer keeps the swapchain (a new size still makes
  it again; the surface is asked once per frame, the acquire and the present of a frame share the answer). Only a
  surface without IDENTITY gets its `currentTransform`, and the picture comes out turned:
  `swapchain_pre_rotation_degrees()` says how far and a nonzero value is warned once.
  Only the lists of the graphics queue wait for the acquire semaphore: another queue's list that uses the acquired
  image is reported and not submitted. HDR10 (`Rgb10A2`) also sets its mastering metadata (`vkSetHdrMetadataEXT`:
  Rec. 2020 primaries, D65, 1000 nits) where `VK_EXT_hdr_metadata` exists. The MSAA colour image is a plain device
  image (not transient or lazily allocated: `ImageUsage` has no transient flag yet).
- **`present`** submits the device's own list that moves the image to `PRESENT_SRC_KHR`, signals the image's
  render-finished semaphore, and calls `vkQueuePresentKHR` on the graphics queue (under the queue lock).
- **Out of date.** `VK_ERROR_OUT_OF_DATE_KHR` or `VK_SUBOPTIMAL_KHR` (from acquire or present: the window changed)
  marks the swapchain stale, and the next `acquire_swapchain()` makes it again at the window's size (the surface's
  `currentExtent`; a surface without one keeps the asked size) with `oldSwapchain`, then acquires once more.
  `resize_swapchain(w, h)` makes it again at that size (refused between acquire and present; nothing to do when the
  size and the images are the same). A window with no area (minimised) is an error at that acquire, so the caller
  skips the frame. Before the images go, an image acquired and never drawn into has its acquire semaphore consumed by an
  empty submission, and the device waits for the GPU and the presentation engine (`vkDeviceWaitIdle`: presentation is
  on no timeline).
- **`destroy_swapchain`** (and the device's destructor, first) releases the images' records, views and semaphores,
  then the swapchain and the surface.

## Tests

`engine/render/tests/vulkan_device_tests.cpp` (ctest `render_vulkan_device`): each case makes a device on the machine's
Vulkan driver with the validation layer and its synchronization validation (`VulkanOptions:: synchronizationValidation`,
through `VK_EXT_validation_features`) and ends by checking that the layer reported no error. The core: buffer and image
round trips with mips, RGBA8, RGBA16F, BGRA, arrays, cubes and 3D images, every view kind, both `copy_buffer_to_image`
paths, deferred destruction, the ring's wrap and the dedicated uploads, descriptor-pool exhaustion and reuse, the
bindless table, the Vulkan 1.0 barriers, a CPU device on request. The drawing cases use the SPIR-V of
`engine/render/tests/shaders/vulkan_test.glsl` (the twins of `d3d12_device_tests.cpp`'s HLSL shaders, compiled by
`compile_shaders.sh` into `vulkan_test.glsl.h` next to it) and the engine's blit shader, and check their targets per
texel: a clear, a uniform fill into RGBA8 and RGBA16F, two views through two samplers, an indexed instanced draw with a
base vertex, the depth test with a viewport, a scissor, an MSAA resolve, a compute pass that writes a storage image and
buffer and a second dispatch that reads them, the caches' counters and the layout of a shader, and the errors of
`make_shader`, `make_pipeline` and the command list. M77-P8b1 added timed frames with two scopes over several frames
(and the untimed, late, forgotten and full-ring cases), async reads of a buffer and an image region with ticket reuse
and all 32 slots in flight, a texture written by compute and read by a second compute pass and a fragment shader (with
synchronization2 and with the 1.0 barriers), pipelines with different set-0 layouts drawn in turn, the texture + storage
image conflict in a dispatch, and `storage_image_loadable`. M77-P8b2 added the pipeline cache file (a second device made
with the first one's file, the destructor's save, a file of another GPU or driver, with a changed UUID, cut, corrupt or
of another format thrown away and written anew, a directory that cannot be made and a file another reader holds open: a
warning and the old file kept), the descriptor pool chain, damaged SPIR-V, a point list without `gl_PointSize`, the
binds of set 0 alone per draw, the eviction of a destroyed shader's pipelines and layouts, the framebuffer cache, a 3D
image without 2D views and the storage buffer range. M77-P10c added the queues, on a device made with `queues =
OtherFamilies` (on MoltenVK: compute family 1, transfer family 2, so the ownership transfers run; a GPU with no second
queue skips them with a MESSAGE): a buffer and an image that go graphics -> compute -> graphics -> compute -> graphics
with `wait_list` and `wait_queue`, a buffer written on the transfer queue, an image written by compute and sampled by a
graphics compute pass and a fragment shader, an image whose mips the producer left in different states (copied, sampled
by compute, sampled by a fragment shader, `UNDEFINED`) handed to compute and back (with synchronization2 and with the
1.0 barriers, so both carry ownership transfers), rows that need repacking uploaded on the transfer queue (the repack
buffer belongs to the list's queue) and sampled on graphics, a timed scope on the compute queue that is ignored, and the
misuse errors (a token never issued, a resource of another queue, a handoff from a queue that does not own it, a render
pass on a compute list); and, on every device, the `GraphicsOnly` fallback, two threads recording while the render
thread makes and destroys other resources, `bindless_index`, and a pipeline destroyed while an open list binds it,
across `wait_idle`. The path of a second queue of the graphics family runs on no machine of the project (MoltenVK and
lavapipe expose one queue per family). A machine with no loader, no Vulkan device, a loader older than 1.2 or a driver
that does not start (`VK_ERROR_INITIALIZATION_FAILED`) says so with a MESSAGE and passes, and one case checks the
factory's errors (bad options, a missing loader). They run on macOS through MoltenVK (`brew install vulkan-loader
molten-vk vulkan-validationlayers`), on Windows where a Vulkan driver is installed, and on the Linux CI job, which
installs Mesa's lavapipe and the validation layers (`mesa-vulkan-drivers libvulkan1 vulkan-validationlayers`) and sets
`FA_VULKAN_REQUIRE=1`: there a skip or a missing validation layer fails the case. M77-P9d added the swapchain, on a
native window each case makes itself (a `CAMetalLayer` through the Objective-C runtime on macOS, an X11 window of
`$DISPLAY` through libX11 opened at run time on Linux, a hidden popup HWND on Windows): the errors of a desc, three
frames cleared, presented and the first read back, a second acquire in a frame, `present` without an acquire,
`resize_swapchain` (and a resize between acquire and present refused), a swapchain marked out of date made again at the
next acquire, an image acquired and never drawn into when the swapchain goes, a swapchain without vsync, a 4x MSAA
swapchain resolved into the acquired image, an acquire that times out (injected through
`inject_acquire_result_for_tests`: the teaching error, the swapchain untouched, the bounded retry), a readback of a
window image the surface made without `TRANSFER_SRC` (refused), the format fallback succeeding where the asked format is
hidden (the device made with `Rgba8` as its default, the surface's `Rgba8` hidden) and a swapchain that fails
(`fail_next_swapchain_for_tests`) leaving the default format as it was, a swapchain lost with its surface kept
(`lose_swapchain_keep_surface_for_tests`) made again by `create_swapchain` without a leak, and `swapchain_format_supported` called from a
second thread while the swapchain is made again. The timer case with `hide_timer_results_for_tests` checks the frame
dropped after 120 polls, and the queue-misuse case a transfer list that begins a render or a compute pass. A machine
with no window or no window path skips them with a MESSAGE; under `FA_VULKAN_REQUIRE=1` (lavapipe's X11 WSI under xvfb)
that fails. `VulkanDevice::counters()`, `fn()`, `pipeline_state()`, `read_image_region` and the `swapchain_*` accessors
exist for these tests.
