# FactorIA architecture: the Vulkan backend (M77)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the GPU interface it implements is
[ARCHITECTURE_RENDERING_GPU.md](ARCHITECTURE_RENDERING_GPU.md)). The engine's own Vulkan device: M77-P8a built the core
(loader, device, memory, resources, barriers, transfers, descriptors, readbacks), M77-P8c the shaders, pipelines,
passes, draws and dispatches, M77-P8b1 the GPU timers, the asynchronous reads and the synchronization fixes that
lavapipe's synchronization validation asks for. The on-disk pipeline cache, growing descriptor pools, cache eviction and
SPIR-V validation are M77-P8b2's, passes into the window M77-P9's.

## Where it is built

Its code is `engine/render/src/gpu/vulkan_device.h` and `vulkan_*.cpp` (loader, device, memory, resources, pipelines,
commands, readback). CMake builds it where `FA_VULKAN_BACKEND` is on: Linux, Windows and Android, and macOS for its
tests only (through MoltenVK; Vulkan is never a macOS product backend, games there use Metal); never on the web or iOS,
where `make_vulkan_device` returns a teaching error. The sources compile with `VK_NO_PROTOTYPES` against the vendored
Khronos headers (`external/vulkan_headers`) and link no Vulkan library: the loader is opened at run time
(`libvulkan.so.1`, `vulkan-1.dll`, `libvulkan.1.dylib` with the Homebrew prefixes on macOS, or
`VulkanOptions::loaderPath`), so a binary on a system without Vulkan starts and the error says what to install. There is
no volk and no VMA. `make_device(Backend::Vulkan)` still answers "not built yet" until the renderer can run on it;
tests and tools make it with `make_vulkan_device(VulkanOptions)`.

## The core (M77-P8a)

**Options and start-up.** `VulkanOptions` picks a CPU device (`cpuDevice`: lavapipe) or the best GPU (discrete, then
integrated), the validation layer, the frames in flight (1 to 3), the upload ring's size, the suballocator's block size
and dedicated threshold, the per-frame descriptor pools, the bindless table and `synchronization2`. Contradictions are
errors before any Vulkan call. The instance asks for Vulkan 1.3 where the loader has it (1.2 at least), with
`VK_EXT_debug_utils` and portability enumeration when present; the device needs Vulkan 1.2, timeline semaphores and a
graphics + compute queue, and enables `VK_KHR_portability_subset` where the driver lists it (MoltenVK:
`portability_subset()`). A GPU with a transfer-only queue family also gets that queue (`transfer_queue()`). Without the
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

**Frames, the timeline, deferred destruction.** One graphics + compute queue and one timeline semaphore: each submit
signals the next value. `commit()` signals the frame's value, and once more frames than `framesInFlight` were committed
it waits (up to 120 s, then an error) for the oldest one, whose descriptor pool and ring room the new frame reuses.
`destroy_*` frees the handle at once and keeps the Vulkan object, its memory and its bindless slot in a deferred list
tagged with the current frame; they are released once the semaphore passed that frame's value
(`counters().pendingReleases`). `wait_idle()` drains the queue and releases everything pending, the current frame's
destroyed objects included (the frame's upload ring room waits for its `commit()`: lists still open may have written
into it).

**Memory.** The engine's own suballocator: a pool of blocks (`memoryBlockBytes`) per memory type and per linear or
optimal resource (so `bufferImageGranularity` never matters), first fit with coalescing free ranges; a resource of
`dedicatedThreshold` bytes or more, and every readback buffer, takes an allocation of its own. Host-visible blocks stay
mapped; upload memory is host-coherent, and readback memory that is not is invalidated before the CPU reads it.
`counters().memory` counts blocks, dedicated allocations, live pieces and bytes.

**Resources.** Buffers; 2D, array, cube and 3D images with mips and MSAA; every `ViewDesc` kind (a sampled view, a
storage image, a storage buffer range, colour, depth and resolve attachments: their Vulkan image views); samplers. A
format table maps each `PixelFormat` to its `VkFormat`, texel or block size and aspect, and `caps()` asks the driver
what each format can do. A 2D view of a 3D image needs `imageView2DOn3DImage`, which the portability subset may lack.

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

**Descriptors.** One descriptor pool per frame in flight (`frameDescriptorSets` sets, `frameDescriptors` of each kind),
reset when the frame's slot comes round again; the device counts the room itself, so a full pool is refused with the
same error on every driver, naming the option to raise. The bindless table is one update-after-bind set of
`bindlessDescriptors` sampled images (descriptor indexing, partially bound): `bindless_add(view)` writes a free slot,
`bindless_remove(slot)` frees it once the frames that may read it are finished. A count over what the device binds in
one stage or puts in one set (MoltenVK: 1212) is lowered with a warning; a device without descriptor indexing has no
table.

**Readbacks.** `read_buffer`, `read_image_rgba8` (BGRA is swizzled to RGBA), `read_image_rgba16f`,
`read_storage_image` and, for tests, `read_image_region(image, mip, layer, x, y, w, h)` copy into a host buffer of
their own on an internal command buffer, wait for the timeline, invalidate non-coherent memory and unpack the rows. They
block. A copy that cannot be submitted returns an error instead of waiting.

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
begin ends the open one, submit ends the last). `timer_poll` reads, without waiting, the frames whose timeline value
passed: ticks masked to the queue family's `timestampValidBits`, times `timestampPeriod` nanoseconds; a scope whose
list was not submitted before the frame ended is never read, so no query that was never written is asked for.
`timer_forget` drops the frames in flight. A queue family without timestamps (`timestampValidBits` 0) or a driver
without a timestamp period makes `timer_supported()` false with a reason naming the device.

**`storage_image_loadable(format)`** is true where the format has `VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT` with optimal
tiling: the engine's shaders always declare a storage image's format, so a load needs nothing more
(`shaderStorageImageReadWithoutFormat` is not used). Otherwise false with a reason naming the device and the format and
the formats every Vulkan GPU stores (rgba8, rgba16f, r32f, rgba32f).

**Robustness.** A full buffer or image pool is found before the Vulkan object or its upload is made; a Vulkan object
made while another thread took the last slot is released with its frame, never while the prelude may copy into it. A
list Vulkan could not give is a dead list that ignores everything and lives as long as the device. A device whose
driver lacks a function is destroyed through `vkGetDeviceProcAddr`'s own `vkDestroyDevice`. On Windows the loader is
opened with `LoadLibraryExW`: `vulkan-1.dll` from System32 only, an absolute `loaderPath` from its own directory.

## Shaders (M77-P8c)

**SPIR-V only.** `make_shader` (`vulkan_pipelines.cpp`) takes each stage as SPIR-V bytecode: sokol-shdc's `spirv_vk`
output. A stage given as source text is refused ("Vulkan takes SPIR-V"), and bytecode that is not a whole number of
32-bit words with the SPIR-V magic number and header is refused too. `tools/shaders/compile_shaders.sh` asks for
`spirv_vk` for every built-in shader and opens the guard of its SPIR-V to `FA_SHADERS_SPIRV` next to `SOKOL_VULKAN`: a
translation unit that drives this backend while sokol runs another one defines `FA_SHADERS_SPIRV` before including a
generated header and calls `<program>_shader_desc(SG_BACKEND_VULKAN)`; every other translation unit carries none of it.
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
(`pipeline_cache()`; M77-P8b saves and loads its data); when two threads make the same one, the first is kept.
Viewport, scissor, blend constants and stencil reference are dynamic state, set by the command list. Pipelines and
their layouts live as long as the device.

**Render passes.** Dynamic rendering is off (MoltenVK and the Vulkan 1.2 baseline): a `VkRenderPass` is cached by its
formats, sample count and load/store operations (`counters().renderPassCacheHits` / `renderPassCacheMisses`). Its
attachments are colour 0, colour 1, depth-stencil and the resolve target; each starts and ends in the layout the pass
uses it in, and the command list's barriers put it there. A graphics pipeline is made against a pass with its own
formats and sample count; Vulkan's compatibility rule ignores load/store operations and layouts, and a single-subpass
pass's resolve attachments, so every pass with those formats draws with it. A `VkFramebuffer` is made per pass and
kept by the list until the list is opened again.

## The command list (M77-P8c)

**Passes.** `begin_pass` makes the same checks as the D3D12 backend, with the same texts: the attachments are live
views of the right kind, of one size, with the formats and sample count `PassDesc::format` says, and the resolve target
single-sampled; a pass into the window (`PassDesc::swapchain`) reports that it comes in M77-P9. A failed pass reports
once and skips what is recorded in it without another error. Load actions are Vulkan load operations (`Clear` takes
`clearColor`, `clearDepth`, `clearStencil`); a resolve attachment makes the pass resolve the MSAA colour at its end.

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
type and sample type) and the storage buffer offset against `minStorageBufferOffsetAlignment`; then it writes set 1
from the frame's descriptor pool, bound with sets 0 and 2 before the next draw or dispatch. `set_uniforms` copies the data into the upload ring, aligned to
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

**Not yet.** M77-P8b2: the pipeline cache saved to and loaded from disk, descriptor pools that grow instead of
refusing a full frame, eviction of the layout and pipeline caches, and SPIR-V validated before `vkCreateShaderModule`.
M77-P9: a pass into the window.

## Tests

`engine/render/tests/vulkan_device_tests.cpp` (ctest `render_vulkan_device`): each case makes a device on the
machine's Vulkan driver with the validation layer and its synchronization validation (`VulkanOptions::
synchronizationValidation`, through `VK_EXT_validation_features`) and ends by checking that the layer reported no
error. The core:
buffer and image round trips with mips, RGBA8, RGBA16F, BGRA, arrays, cubes and 3D images, every view kind, both
`copy_buffer_to_image` paths, deferred destruction, the ring's wrap and the dedicated uploads, descriptor-pool
exhaustion and reuse, the bindless table, the Vulkan 1.0 barriers, a CPU device on request. The drawing cases use the
SPIR-V of `engine/render/tests/shaders/vulkan_test.glsl` (the twins of `d3d12_device_tests.cpp`'s HLSL shaders,
compiled by `compile_shaders.sh` into `vulkan_test.glsl.h` next to it) and the engine's blit shader, and check their
targets per texel: a clear, a uniform fill into RGBA8 and RGBA16F, two views through two samplers, an indexed
instanced draw with a base vertex, the depth test with a viewport, a scissor, an MSAA resolve, a compute pass that
writes a storage image and buffer and a second dispatch that reads them, the caches' counters and the layout of a
shader, and the errors of `make_shader`, `make_pipeline` and the command list. M77-P8b1 added timed frames with two
scopes over several frames (and the untimed, late, forgotten and full-ring cases), async reads of a buffer and an
image region with ticket reuse and all 32 slots in flight, a texture written by compute and read by a second compute
pass and a fragment shader (with synchronization2 and with the 1.0 barriers), pipelines with different set-0 layouts
drawn in turn, the texture + storage image conflict in a dispatch, and `storage_image_loadable`. A machine with no
loader, no Vulkan device, a loader older than 1.2 or a driver that does not start (`VK_ERROR_INITIALIZATION_FAILED`)
says so with a MESSAGE and passes, and one case checks the factory's errors (bad options, a missing loader). They run on
macOS through MoltenVK (`brew install vulkan-loader molten-vk vulkan-validationlayers`), on Windows where a Vulkan
driver is installed, and on the Linux CI job, which installs Mesa's lavapipe and the validation layers
(`mesa-vulkan-drivers libvulkan1 vulkan-validationlayers`) and sets `FA_VULKAN_REQUIRE=1`: there a skip or a missing
validation layer fails the case.
`VulkanDevice::counters()`, `fn()`, `pipeline_state()` and `read_image_region` exist for these tests.
