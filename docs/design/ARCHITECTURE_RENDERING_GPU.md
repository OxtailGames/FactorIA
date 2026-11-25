# FactorIA architecture: the GPU interface (M77)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The engine's own GPU interface, `fa::gpu`, which the
renderer moves onto during M77 so that the D3D12 and Vulkan backends can sit next to sokol_gfx. Its code is in
`engine/render/src/gpu/` (private to `fa_render`); its tests are `engine/render/tests/gpu_interface_tests.cpp`
(ctest `render_gpu_interface_core`, no GPU needed). The Vulkan backend has a page of its own,
[ARCHITECTURE_RENDERING_VULKAN.md](ARCHITECTURE_RENDERING_VULKAN.md), the D3D12 backend on
[ARCHITECTURE_RENDERING_D3D12.md](ARCHITECTURE_RENDERING_D3D12.md); the backends' own tests are
`d3d12_device_tests.cpp` and `vulkan_device_tests.cpp` (ctests `render_d3d12_device`, `render_vulkan_device`).

## Layers

```
renderer (Renderer, Gpu, the passes)          today: sg_* calls; after M77-P2..P5: gpu::Device / gpu::CommandList
        |
gpu::Device + gpu::CommandList (device.h)     the interface: resources, capabilities, the frame, timers, readbacks
        |
SokolDevice (sokol_device.h/.cpp)             GL, GLES3, WebGL2, D3D11, Metal through sokol_gfx (stays)
D3d12Device (d3d12_device.h, M77-P7a core)    the engine's own backends (ARCHITECTURE_RENDERING_D3D12.md)
VulkanDevice (vulkan_device.h, M77-P8a core)  ("Vulkan backend" below)
RecordingDevice (recording_device.h/.cpp)     no GPU: validates every call and records the stream (tests)
```

- `gpu/types.h` is the vocabulary: handles, enums, descs, capabilities, pass and binding structs. No sokol type
  appears in it, so a D3D12 or Vulkan backend includes nothing of sokol.
- `gpu/device.h` declares `Device` and `CommandList` (pure virtual), `DeviceInit`, `make_device(Backend, DeviceInit)`
  and `built_sokol_backend()` (the one sokol backend a binary has: sokol compiles one per build). `make_device` makes
  the built sokol backend, Recording, D3D12 (Windows; with the engine's pipeline cache file) and Vulkan (where
  `FA_RENDER_VULKAN` is on, with the `DeviceInit` it was given and the engine's Vulkan pipeline cache file);
  `device_backend_compiled(b)` says which this binary can make, and every other request is a teaching error that names the backend to ask for instead.
- `gpu/sokol_device.h` holds `SokolDevice`, its immediate `SokolCommandList`, and the `to_sg` / `from_sg`
  conversions the call sites use while they move over.
- M77-P1 (this page's first version) lands the interface and its implementations only: `Gpu` does not own a
  `Device` yet, no call site changed, and the renderer's behaviour and tests are the same.

## Device and CommandList

**Device** owns everything that outlives a frame and answers what the GPU can do:

- capabilities: `backend()`, `info()` (backend, Metal target, name), `features()`, `limits()`,
  `pixel_format_caps(format)`, `environment_defaults()` (what `PixelFormat::Default` and sample count 0 mean);
- the natives: `native()`, `native_image()`, `native_buffer()` (the platform glue and the screenshots
  need the `id<MTLDevice>`, the `ID3D11Device` or a GL texture name);
- resources: `make_*` / `destroy_*` / `state()` for buffers, images, views, samplers, shaders and pipelines;
- the frame: `begin_commands(label)`, `submit(list)`, `commit()`, `frame_index()`, commit listeners,
  `reset_state_cache()`;
- queues, tokens and bindless (M77.5, below): `begin_commands(label, QueueKind)`, `submit_token(list, handoffs)`, `wait_list`,
  `wait_queue`, `bindless_index(view)`, `Features::asyncCompute`, `multiThreadRecording`, `bindless`;
- statistics (`enable_stats`, `total_stats`), GPU timers (`timer_*`), readbacks (`read_image_rgba8`,
  `read_image_rgba16f`, `read_storage_image`, `read_buffer`), `storage_image_loadable(format, why)` (whether a compute
  shader may load a storage image of that format: `"access": "readwrite"`) and asynchronous buffer reads (`request_buffer_read`,
  `poll_buffer_read`, `release_buffer_read`).

**CommandList** records one thread's part of a frame:

- passes: `begin_pass(PassDesc)` (attachments or the swapchain, load and store actions, clear values, and the
  `TargetFormat` the pipelines drawn in it must match), `begin_compute_pass(label)`, `end_pass()`, `pass_state()`;
- state: `set_pipeline`, `set_bindings(Bindings)`, `set_uniforms(slot, data)`, `set_viewport`, `set_viewport_f`,
  `set_scissor`;
- work: `draw`, `draw_ex` (base vertex, base instance), `dispatch`;
- transfers: `write_buffer`, `write_image`, `copy_buffer_to_buffer`, `copy_buffer_to_image`;
- markers: `push_debug_group` / `pop_debug_group`, `begin_timed_scope` / `end_timed_scope` (the GPU timer's scopes).

Inside a render pass go the state calls and `draw`; inside a compute pass a compute pipeline, views, samplers,
uniforms and `dispatch`; outside a pass the copies. Writes, debug groups and timed scopes go anywhere.

## Handles

- A handle (`Buffer`, `Image`, `View`, `Sampler`, `Shader`, `Pipeline`) is a 32-bit id; 0 is the invalid handle.
- A destroyed handle never names another resource: the upper 16 bits are a generation that changes when the slot is
  reused, so a stale handle's `state()` is `Invalid`. (RecordingDevice wraps a slot's generation after 65535 reuses;
  sokol has the same scheme.)
- On the sokol backends the id IS sokol's id: `gpu::Image{img.id}` and `sg_image{h.id}` name the same image. A call
  site converts one call at a time, with the other calls still on `sg_*`.
- A failed creation returns a handle in state `Failed` (destroy it like any other); a full pool returns the invalid
  handle. Neither throws.

## Threading and lifetime

- A Device is made, used for resources and destroyed on the render thread.
- A CommandList belongs to the thread that called `begin_commands()` until `submit()`. The D3D12 and Vulkan backends
  (M77.5) let several threads hold one list each in the same frame; `submit()` order is execution order.
- SokolDevice has a single immediate list: a second `begin_commands()` before `submit()`, or a call from another
  thread, is a programming error (`FA_ASSERT`).
- RecordingDevice takes lists on any thread (one mutex guards its tables), so the parallel recording of M77.5 is
  testable before those backends exist.
- A resource may be destroyed while a submitted list still uses it: a backend with frames in flight defers the
  release (sokol does; the explicit backends keep a per-frame deletion queue).
- A list is not used after `submit()`: a `CommandList&` kept across a `submit()` (or a `Gpu::commit_frame()`) names
  a list the device may already have recycled. Ask for the current one again (`Gpu::commands()`).
- SokolDevice checks the thread (`FA_ASSERT` in every build) in every entry that reaches the sokol context: the
  resources, `state()`, the frame, the statistics, the timers, the readbacks, the natives and every call of its list.
  The cached queries (`backend()`, `info()`, `features()`, `limits()`, `async_read_supported()`) do not reach the
  context and are not checked.
- `SokolDevice::create` adopts the context that is open and then ignores its `DeviceInit` entirely (environment, pool
  sizes, uniform buffer size are the open context's); it opens a context from `DeviceInit` only when none is open,
  and closes only a context it opened. Its destructor asks `sg_isvalid()` BEFORE it releases its timer and its
  asynchronous reads, so neither touches a context that is already closed.

**Uploads inside a pass.** `write_buffer` and `write_image` may be recorded inside a pass: sokol copies at once (GL,
D3D11) or into a per-frame transient slot (Metal). The explicit backends (D3D12 from M77-P7c, Vulkan) cannot copy
into a resource a pass is using: they will stage such a write in a host-visible ring buffer of the frame and copy it
before the pass (or read the ring directly), so a write inside a pass costs them a ring allocation. Keep uploads
before the pass where the code allows it.

**Asynchronous reads.** `request_buffer_read(buffer, offset, bytes)` returns a `ReadTicket{slot, generation}`: the
generation changes with every request, so a ticket that was already read or released is stale (`poll_buffer_read`
returns false, `release_buffer_read` does nothing) even when a later request reuses its slot. A ticket with
`valid() == false` and no error means every slot is in flight: ask again next frame. The offset is applied by the
backend (sokol copies `offset + bytes` and drops the first `offset`). Only buffers are read in the background;
images are read by waiting (`read_image_rgba8`, `read_image_rgba16f`, `read_storage_image`).

**RecordingDevice ranges.** Every rectangle, mip and slice range is checked in 64-bit arithmetic: a start near
`INT_MAX` plus a size cannot wrap around into a range that looks inside the image.

## Queues, tokens, threads and bindless (M77.5)

The contract is written in `gpu/device.h` (block "Queues, threads and bindless" of `Device`); this is its summary. Every
member is virtual with a default for a device with one queue, so a backend that has not built them compiles and
behaves as one queue: sokol, and D3D12/Vulkan until their packages override them.

- **Queues.** `QueueKind { Graphics, Compute, Transfer }`; `begin_commands(label)` is `Graphics`.
  `begin_commands(label, queue)` returns a list for that queue; `CommandList::queue()` says which one it really runs on
  (without `Features::asyncCompute` every list is a graphics one: the default, and sokol). A compute list takes compute
  passes, copies, writes and markers; a transfer list copies, writes and markers (no pass at all: RecordingDevice
  reports a render pass on either, a compute pass on a transfer list). A timed scope on a queue without timestamps
  (Transfer, or a backend that says so) is accepted and ignored; RecordingDevice records it as ignored. Lists of one
  queue run in `submit()` order; across queues only tokens order.
- **Tokens.** `submit_token(list)` is `submit()` that returns a `SyncToken{queue, value}`: the queue's fence value
  (from 1, never reset or reused, so a token of an earlier frame is simply satisfied; values grow but are not
  contiguous, because a backend may take values for fix-up submissions of its own: compare them, never count them;
  they need Vulkan timeline semaphores (1.2, already required) and 64-bit D3D12 fences). `wait_list(list, token)` makes the
  list start after the token (before its first command, whenever it is called while the list is open);
  `wait_queue(queue, token)` does it for everything submitted to the queue afterwards. The invalid token and a token of
  the waiter's own queue wait for nothing. The defaults of `wait_list` and `wait_queue` do nothing, which is right only
  with one queue: a backend with `asyncCompute` must override them. A token no `submit_token` returned can never be satisfied: RecordingDevice
  reports it. Only the GPU waits. `commit()` ends the frame for the graphics queue: async work nobody waited for is
  allowed, but the picture may depend only on async work a graphics list waited for.
- **Resources between queues.** A buffer or image belongs to one queue at a time; a new one belongs to Graphics. There
  is no barrier call and the backend does not guess a handover from bound views: the producer declares it at submit,
  `submit_token(list, {QueueHandoff{image or buffer, to}})` (the whole resource, never a view), and the consumer list
  on `to` waits for that token (`wait_list`, or `wait_queue` before it is submitted) before its first command that uses
  the resource. Going back is the same in the other direction. The producer's queue must own the resource at that
  moment, so the first use on the compute queue starts with a graphics list (possibly an empty one) that hands it over.
  The backend resolves it on the render thread at submit: Vulkan records the queue-family release at the end of the
  producer's list and the acquire at the head of the consumer that waits (or uses `VK_SHARING_MODE_CONCURRENT`, its
  choice); D3D12 transitions to a state the destination queue type accepts (COMMON or a read state) and the consumer
  transitions on from there. Without `asyncCompute` handoffs are accepted and ignored. RecordingDevice tracks the owner
  of every resource and, when a list is submitted (so lists can be recorded in parallel in any order), reports a
  resource used on a queue that does not own it and one used before the list waited for the handoff's token; it records
  `CommandKind::Handoff`, `Signal`, `WaitList` and `WaitQueue` and the `queue` of each `RecordedCommand`.
- **Threads.** Render thread only: `make_*`, `destroy_*`, `submit`, `submit_token`, `wait_queue`, `commit`, the commit
  listeners, statistics, timers, readbacks, natives. With `Features::multiThreadRecording`, any thread: `begin_commands`,
  every call on the list the thread holds (including `wait_list`) and the read-only queries (`features`, `limits`,
  `info`, `pixel_format_caps`, `state`, `bindless_index`...), on the condition that the renderer joins its recording
  jobs before it creates or destroys a resource, submits or commits. One list is used by one thread at a time; the
  render thread submits the lists after the join, in a fixed order. RecordingDevice has the feature on in its default
  caps and its own tests record two lists on two threads; sokol does not (a second `begin_commands()` before
  `submit()` is an `FA_ASSERT`).
- **Bindless.** `bindless_index(view)`: the slot of a texture or storage view in the global table shaders index, stable
  for the view's life; `kNoBindlessIndex` without the table (`Features::bindless` false) or for another view.
  RecordingDevice answers when its `recordingFeatures.bindless` is on (the pool slot).
- A backend class that overrides one `begin_commands` overload (or the two-argument `submit_token`) hides the other
  through its own type: add `using Device::begin_commands;` (`using Device::submit_token;`).
- How the renderer uses them (the shadow views recorded on job threads, the depth pyramid on the compute queue, the
  switches `RendererDesc::asyncCompute` and `multiThreadRecording`): [ARCHITECTURE_RENDERING_QUEUES.md](ARCHITECTURE_RENDERING_QUEUES.md).

## Barriers live inside the backends

The interface has no barrier, transition or resource-state call. A backend that needs them (D3D12, Vulkan) derives
them:

- from the pass boundaries: an attachment written by a pass becomes shader-readable when a later pass binds it;
- from the views a draw or dispatch binds: a `Texture` view reads, a `StorageImage` or `StorageBuffer` view writes;
- from the transfers: a copy's source and destination.

This keeps every call site backend-neutral, and it is why `ViewDesc` fixes a view's kind at creation.

## How sokol maps

- Enums have sokol's values (`static_cast` both ways; `sokol_device.cpp` static_asserts every enumerator, the
  `SG_MAX_*` constants and `SG_NUM_INFLIGHT_FRAMES`). Each enum's 0 is `Default` where sokol has a default, so a
  value-initialised desc means what a zeroed sokol desc means.
- Descs convert field by field (`to_sg(const BufferDesc&)` and the rest). Labels, shader sources and data ranges are
  borrowed for the call, never kept.
- The generated shader headers return `sg_shader_desc`: `generated_shader_desc(device, name_shader_desc)`
  (gpu/sokol_shaders.h) gives the `ShaderDesc` for `Device::make_shader` in the dialect of `device`: GLSL on GL,
  GLSL ES on GLES3 and WebGL2, HLSL 5 on D3D11 and D3D12, the MSL of `DeviceInfo::metalTarget` on Metal, SPIR-V on
  Vulkan, and on Recording the dialect of the open context (the built one when none is open). A header without that
  dialect logs an error and gives an empty desc, which `make_shader` refuses.
- `to_sg(const PassDesc&)` gives the `sg_pass` of a pass (the swapchain case included); a window pass is
  `PassDesc::for_swapchain(sc, device.environment_defaults())` (a test checks every field).
- The conversions are declared in gpu/sokol_device.h, which only the sokol backend's files and the tests include.
- `SokolDevice::create` adopts the sokol context that is open (the renderer's; left open at destruction) or opens one
  from `DeviceInit` (and shuts it down at destruction). `frame_index()` counts commits through a commit listener.
- Timers forward to the renderer's `GpuTimer`. Readbacks, `storage_image_loadable`, the asynchronous reads' rings
  (`gpu::AsyncBufferRead`) and the GLES fix of a new image's mip range forward to the `native_*` functions of
  gpu/sokol_native.h, which the per-backend files implement over `native()`, `native_image()` and `native_buffer()`
  (readback_metal.mm, readback_d3d11.cpp, readback_gl.cpp, image_gl.cpp): they hold no sokol call.
- Asynchronous reads come from a pool of up to 8 `AsyncBufferRead` rings of 4 slots each, made lazily (a ticket's slot is
  ring * 4 + slot): the Hi-Z cull of up to 8 cameras keeps 4 reads in flight each. A request takes the first ring with a
  free slot; when all 32 are busy it returns an invalid ticket without an error.
- sokol's `DUMMY` backend, which the engine never builds, maps to `Backend::Recording` (no GPU either way); sokol's
  WebGPU and Vulkan backends are not used.

Left out on purpose (nothing in the engine calls them, or the interface says it another way):

- the native injection fields of the descs (`gl_buffers`, `mtl_*`, `d3d11_*`, `wgpu_*` of `sg_buffer_desc` /
  `sg_image_desc`): an imported native object will be its own call when something needs one;
- `sg_alloc_*`, `sg_init_*`, `sg_uninit_*`, `sg_dealloc_*`, `sg_fail_*` (two-step creation) and
  `sg_install_trace_hooks`;
- `sg_query_*_desc`, `sg_query_*_defaults`, `sg_query_*_info`, the image and buffer getters (`sg_query_image_width`
  and the rest), `sg_query_view_*`: a call site keeps the desc it made;
- `sg_query_row_pitch` / `sg_query_surface_pitch`, `sg_write_*_unsealed` / `sg_seal_*`,
  `sg_apply_scissor_rectf`;
- the frame statistics of `sg_query_stats()` (`prev_frame`, `cur_frame`; its `total` is `total_stats()`), the
  per-backend shader, pipeline, sampler and view infos (`sg_d3d11_query_*_info`, `sg_mtl_query_*_info`), the Metal
  render and compute encoders;
- the `sg_desc` options `disable_validation`, `enforce_portable_limits`, `allocator`, the per-backend descs and
  `max_commit_listeners`.

## RecordingDevice

A Device without a GPU, for tests and for the CPU logic of the later backends. It never stops on a misuse: the call
is recorded as far as it can be, and a message goes to `errors()`. A message says what is wrong, where (the list, the
command's index in it, the open pass) and how to fix it:

```
gpu: list 'main', command #2 (set_pipeline) in pass 'hdr': pipeline 'textured' draws color=RGBA8 depth=DEPTH_STENCIL
samples=1 (1 colour targets) but the pass is color=RGBA16F depth=DEPTH_STENCIL samples=1 (1). Fix: make the pipeline
for this pass's TargetFormat (Gpu::find_or_make keys pipelines by it)
```

What it checks:

- descs: sizes, formats against `pixel_format_caps`, usage flags, view ranges, shader reflection (std140 sizes, slot
  kinds, texture-sampler pairs, stages), a pipeline's shader and vertex layout against the attributes it reads;
- passes: nesting, `end_pass` without a begin, attachment kinds and liveness, `PassDesc::format` against the
  attachments, a swapchain pass with an empty format (use `PassDesc::for_swapchain`);
- `set_pipeline`: a live pipeline of the pass's kind whose colour formats, depth format and sample count are the
  pass's (the explicit APIs bake them into the pipeline);
- `set_bindings` against the shader's reflection: every vertex buffer the layout reads, the index buffer iff the
  pipeline is indexed, each view slot's kind, liveness, multisampling and sample type, each sampler slot's
  comparison and filtering;
- `set_uniforms`: a declared slot and the exact size; `draw` / `dispatch`: the bindings and every uniform block set
  since `set_pipeline` (as sokol's validation does), and the base vertex / instance features;
- writes (`writeTransient`, bounds) and copies (`copySrc`, `copyDst`, bounds, outside a pass);
- the frame: debug groups and timed scopes balanced, `submit` of an open pass, `commit` with a list not submitted,
  double destroys and stale handles (named with their label: "destroyed buffer 'b'").

`commands()` and `stream_text()` give the device stream: every submitted list's commands in submit order, and one
`commit` per frame:

```
frame 0 [main] begin_pass 'main' color=RGBA8 depth=DEPTH_STENCIL samples=1
frame 0 [main] set_pipeline 'textured'
frame 0 [main] set_bindings vb=1 views=1 samplers=1
frame 0 [main] set_uniforms 0 32B
frame 0 [main] draw 0 36 1
frame 0 [main] end_pass
frame 0 commit
```

By default it reports a desktop GPU with compute (`DeviceInit::recordingDefaultCaps`); with that flag false it
reports exactly `recordingFeatures` and `recordingLimits`, so a test can describe a GLES3-class device. It has no GPU
memory and no clock, so its readbacks give a deterministic answer: a read a GPU would accept returns zeros of the size
it asked for and is recorded in the stream (`read_image_rgba8 image 'ldr' 0 0 16x8`, `read_buffer buffer 'hiz' 8 16`;
`CommandKind::ReadImage` / `ReadBuffer`, no list); one it would refuse (a dead handle, a format the read does not take,
a rectangle or range outside the resource, a storage read without compute) fails with a teaching error and records
nothing; a read while a list is still recording or was submitted but not committed reports to `errors()` (a GPU would
not have run that work yet) and still answers. `storage_image_loadable` is true for RGBA8, RGBA16F, R32F and RGBA32F
when the device has compute. Asynchronous reads stay unsupported (`async_read_supported()` false; a request fails with
a hint), and `timer_supported()` is false with a reason (the timed scopes are still recorded).

## How the next packages migrate

- **P2..P5** move the renderer's call sites onto the interface: `Gpu` owns a `Device` (made with
  `make_device(built_sokol_backend())`, adopting the context the renderer opened), the shared code first (`Gpu`, the
  frame graph's target pool, the pipelines cache), then the passes one file at a time. Each step keeps the goldens
  unchanged; a converted file includes no `sokol_gfx.h`.
- Handles keep sokol's ids during the move, so a converted function can hand a `gpu::Image` to one that still takes
  `sg_image` (`to_sg(h)`), and the reverse (`from_sg(img)`).
- **M77.2 / M77.3** add `D3d12Device` and `VulkanDevice` behind the same interface, and M77-P9b lets the renderer
  draw through them (`RendererDesc::backend`, "The renderer on its backend" below). RecordingDevice's checks are the
  contract they implement: a frame that RecordingDevice accepts must run on them.

## How the renderer reaches the device

`render::Gpu` (engine/render/src/render_internal.h) owns the renderer's `gpu::Device` from `init()` to `shutdown()`
and the command list of the frame being recorded. Code reaches them in one of four ways, never through a global
sokol call:

- **Code that has the Gpu** (its own resources, the pipeline cache, uploads): `gpu.device()` for resources and
  queries, `gpu.commands()` for what goes into the frame. `Gpu::commit_frame()` submits the list, commits and begins
  the next one, so a `CommandList&` is asked for again after it (see "Threading and lifetime").
- **A frame-graph pass**: `PassContext::commands()` is the list `FrameGraph::execute(pool, &gpu.commands())` was
  given, valid while the pass runs (null in the CPU-only graph tests). This is where a later backend hands each pass
  (or each thread) its own list: the pass code does not change.
- **Passes begin on a list** (`gpu::CommandList& cl = gpu.commands(); cl.begin_pass(pass)`, `cl.end_pass()`).
  The list checks that every pipeline set in a render pass was made for the pass's `PassDesc::format`, and that the
  format is what the attachments are: a debug assertion in `SokolCommandList::begin_pass` / `set_pipeline` (GL and
  D3D11 validation reject a mismatch, Metal draws wrong), an `errors()` entry on RecordingDevice. `Gpu::in_pass()` asks
  `list.pass_state()`. A window pass (`Renderer::begin_window_pass`, `present_clear`) is a pass on the sokol context
  itself (`gpu::begin_context_pass`, gpu/sokol_context.h), because it runs with no renderer; the list does not check
  the pipelines set in it (the UI painter's), since it did not begin it.
- **The Target helpers take the device** (`make_target(gpu.device(), desc)`, `destroy_target(gpu.device(), t)`,
  `Target::valid(device)`); there is no overload that asks a global device (P5a, P5d1).

Before (a sokol call site):

```cpp
sg_buffer_desc d{};
d.usage.vertex_buffer = true;
d.data = SG_RANGE(verts);
quad_ = sg_make_buffer(&d);
...
sg_write_buffer_transient(buf, SG_RANGE(data));
sg_commit();
```

After (on the interface):

```cpp
gpu::BufferDesc d;
d.usage.vertexBuffer = true;
d.data = gpu::Range{verts, sizeof(verts)};
quad_ = gpu.device().make_buffer(d);
...
gpu::BufferWrite w;
w.buffer = buf;
w.data = gpu::Range{data, sizeof(data)};
gpu.commands().write_buffer(w);
gpu.commit_frame();
```

During the move (P2 to P5d2) gpu/sg_bridge.h connected the two sides (`to_sg` / `from_sg`, and `gpu::bridged::*`
handles that converted to their sokol twins); P5d3 deleted it (see "P5d3: no sokol in the renderer"). The packages
converted, in order: gpu.cpp (Gpu, its pipelines and samplers), render_internal.h, the target helpers
(target.cpp), shader_cache.cpp and render_features.cpp; assets.cpp, custom_shader.cpp, water2d.cpp, gi2d.cpp,
renderer_lights2d.cpp, fonts.cpp, gradient_ramp.cpp, postprocess.cpp and bloom.cpp (P3: their passes open on
`gpu.commands()` or `PassContext::commands()`; a class with no Gpu member (WaterFx, GradientRamps, Gi2dSystem,
AutoExposure) remembers the `gpu::Device` it first got, and keeps an overload without a device for the callers not
converted yet); compute.cpp, light_atlas.cpp, renderer_hiz.cpp, renderer_probes_gpu.cpp and renderer_gi_gpu.cpp (they
open their passes on `gpu.commands()`); the frame graph carries the list to its passes; the 3D geometry passes of the
renderer (M77-P4a): renderer_draw.cpp (the light, shadow, prepass, subsurface, quad-motion, main and HUD passes, the
uploads and the bindings of a draw), renderer_terrain.cpp, renderer_targets.cpp, renderer_decals.cpp,
renderer_impostor.cpp, mesh_buffer_draw.cpp and renderer.cpp's `sg_commit`s (now `Gpu::commit_frame()` followed by
`note_commit()`; `present_clear` keeps its own, it runs with no Gpu). `apply_uniforms(list, slot, u)` (renderer_impl.h) is the helper a converted pass uses for its uniform blocks (a pass
begins with `cl.begin_pass(pass)`; the `begin_list_pass` wrapper P4a added was an empty forwarder and went in the review of
P5). What still touched sokol in those files then: the context lifecycle (before any device exists), the readbacks (P5d2 moved them behind the Device).
gi2d.cpp's draw_list writes its transient buffers before its pass begins. gpu_timer.cpp stays on sokol: it is
the sokol backend's own timer (the D3D11 device calls). The 3D light and environment passes
(M77-P4b): renderer_env (the sky cube and its prefilter), renderer_sky_phys, renderer_subsurface, renderer_fog,
renderer_volumetric, renderer_xmit (transmission), renderer_hdri and the read-back commits of renderer_probes. Each of
those classes makes its shaders, pipelines, images and samplers on `gpu.device()` and remembers the device in `ready()`
(`device_`), because `release()` has no `Gpu` at hand. A pass declared in the frame graph records on
`PassContext::commands()` (`c.commands() ? *c.commands() : g->commands()`); one drawn outside the graph records on
`gpu.commands()`: `Environment::draw` (the prefilter, copy and SH passes of a bake), the sky's six cube faces
(`Environment::bake_sky` begins each face on `gpu.commands()` and hands the open pass to the sky callback) and
`PhysicalSky::pass` (the tables and the sky view) never take a list of their own. `gpu_pass_order_tests.cpp` records a
fog draw and the six sky faces on a `RecordingDevice` (`Gpu::init(samples, &error, device)` takes a device for tests) and
checks the order of the calls. P4c: the 3D post-process and
upscale passes and the present (renderer_dof, renderer_ssr, renderer_ssao, renderer_taa, renderer_custom_post,
renderer_upscale, render_upscale_spatial, render_upscale_metalfx, renderer_present and the preparation pass of
renderer_metalfx). They share fullscreen_gpu.h: `pass_list(c, gpu)` (the frame's list, or the Gpu's own when a CPU-only
graph has none) and `make_triangle_pipeline`. Each class remembers the `gpu::Device` of its `ready(...)` call and makes
its pipelines before the pass begins. The MetalFX wrapper (metalfx.h, metalfx_apple.mm, metalfx.cpp) moved in
P5c, see "P5c: native_metal and the 2D painter" below.
P5a: the render targets and formats are interface types. `Target` holds `gpu::Image` / `gpu::View` made on the Gpu's
device (target.cpp; `TransientTargets` takes the device), `TargetDesc`, the format getters (`scene_format()`,
`velocity_format()`...) and the pass headers use `gpu::PixelFormat`, and `TargetFormat` / `PassDesc` have one definition
(`gpu/types.h`; gpu_types.h only brings them into `fa::render`). A window pass is `PassDesc::for_swapchain` over the
`gpu::Swapchain` of the platform's swapchain (`gpu::swapchain_of`). The readbacks and storage-image helpers, still on
sokol types at their edges after P5a, moved behind the Device in P5d2 (done).
P5b: the asset and material types are interface types. `TextureAsset` and `LutAsset` hold a `gpu::Image` / `gpu::View`
and a `gpu::PixelFormat`, `SubMesh` its `gpu::Buffer`s, `MaterialProgram` a `gpu::Shader`; ktx2.cpp picks the target
format from the device's pixel-format caps (`ktx2_target_format(device)`) and `transcode_ktx2` takes the device.
`material_shader_desc` returns a `gpu::ShaderDesc` built from the twin's reflection, with the binding numbers of every
backend the reflection names (hlsl register, msl index, wgsl and spir-v group and binding, glsl binding), and
`make_material_program` creates it with `gpu.device().make_shader`. The sokol overloads of `make_shader`
(shader_cache_sg.cpp) and `feature_env_from_sokol` (render_features_sg.cpp) are deleted: nothing called them. Draws
bind the interface handles as they are; `draw_group` no longer converts its bindings twice. The files of this list
call no `from_sg` any more; `to_sg` was left only in front of the sokol-only readbacks and storage-image helpers (gone in P5d2).

## The renderer on its backend

`RendererDesc::backend` (`GpuBackend`, fa/render/renderer.h) names the device the renderer draws through. `Default`
(and the sokol backend this binary was built with) is what the renderer always did: `init()` opens or adopts the sokol
context and `Gpu::init` makes `make_device(built_sokol_backend())` on it. `D3d12`, `Vulkan` and `Recording` make
their device with `make_device(backend, init)` (the window environment's default formats in `init`) and hand it to
`Gpu::init`; they never open, adopt or close the sokol context. Another sokol backend is an `init()` error that says
which one the binary has. Every built-in program comes from `generated_shader_desc(device, ...)`, so each device
gets its own dialect; `gpu_info().backend` names the device's backend ("d3d12", "vulkan", "dummy" for Recording).
`UiPainter::create(Renderer&, error)` makes a painter that draws where the renderer draws: on D3D12, Vulkan and
Recording the renderer's own device (not owned: destroy the painter before `Renderer::shutdown`); on the sokol backend
a device of its own over the same context, as `UiPainter::create(error)` (the editor) makes it, since `Gpu` keeps its
frame's list open between frames and a sokol device has one list at a time (the ids are shared, so it still shows the
renderer's pictures).
`Gpu::find_or_make` writes every vertex offset and stride out (`gpu::resolve_vertex_offsets`: sokol's rule, each
buffer whose offsets are all 0 is packed on its own), so a backend that packs the whole layout at once reads the
same attributes; vertex buffers say `usage.vertexBuffer`, and the lean 2D program binds only its texture and sampler.

**The window path** (gpu/device.h, "the window: swapchain and present"): `create_swapchain(SwapchainDesc)` once
(`Renderer::init` when not headless), `acquire_swapchain(windowFrame)` each frame for the `PassDesc::for_swapchain`
pass of `Renderer::present`, `present()` after the frame's commit, `resize_swapchain(w, h)`, `destroy_swapchain()`
(`Renderer::shutdown`), and `swapchain_format_supported(format, why)`, the HDR question `warm_step` asks before it
makes the RGBA16F and RGB10A2 copies. The sokol devices answer it over the window's swapchain, which the platform
made and presents (sokol_app's own, or on Windows the platform's D3D11 presenter below: create and resize record,
acquire hands the frame back, present does nothing; RGBA16F on Metal and D3D11, RGB10A2 on D3D11). D3D12 makes its own
flip-model DXGI swapchain on the HWND of `SwapchainDesc::nativeWindow` (ARCHITECTURE_RENDERING_D3D12.md, "Swapchain"),
and Vulkan a surface and swapchain on the native window (ARCHITECTURE_RENDERING_VULKAN.md, "Swapchain");
`Renderer::present` calls `resize_swapchain` when the framebuffer size changes. `RendererDesc::nativeWindow`
(`NativeWindowHandle`: the handles and the framebuffer size) and `RendererDesc::vsync` reach the device's
`SwapchainDesc`; a non-headless renderer on D3D12 or Vulkan without them fails `init()` with the swapchain's error
about the missing native window, and an `init()` that fails after the swapchain destroys it before the device. The defaults in device.cpp are the answer of a backend without a window path (Recording):
every call fails with an error that says to draw offscreen (`RendererDesc::headless`) or pick the sokol backend, so a
non-headless renderer on it fails `init()`. D3D12's and Vulkan's `make_pipeline` also resolve the vertex offsets
themselves (`resolve_vertex_offsets`), so a pipeline made outside `Gpu::find_or_make` reads the same attributes.

**Windows presentation** (engine/platform/src/d3d11_present.h, M77-P9f): on Win32 sokol_app is compiled with
`SOKOL_NOAPI` (sokol_impl.c; sokol_gfx stays `SOKOL_D3D11`, sokol_glue is not used there), so the window owns no
graphics device and a D3D12 or Vulkan swapchain can be made on its HWND. The first `app_gfx_environment()` makes the
platform's `d3d11::Presenter`: the D3D11 device (sokol_app's flags, the debug layer in a Debug build, retried without
it when Graphics Tools is missing; `IDXGIDevice1::SetMaximumFrameLatency(1)`), a two-buffer `FLIP_DISCARD` swapchain
(Windows 10 on; the old `DISCARD` model with one buffer before it, which has no HDR and always syncs), the view of
buffer 0, the `D32_FLOAT_S8X24_UINT` depth-stencil and, above one sample, the MSAA target the swapchain pass resolves
into buffer 0. `app_gfx_swapchain()` hands its views to the frame; app.cpp's frame callback calls `resize()` with
sapp's framebuffer size before the game's frame (views go, `ResizeBuffers`, views back: sokol_gfx unbinds them at
the end of every pass) and `present()` after it, with the vsync interval (`app_set_vsync`), `DXGI_PRESENT_ALLOW_TEARING`
when vsync is off and the display supports it, and no wait while Windows' modal move or resize loop draws from its
timer. A lost device (`DXGI_ERROR_DEVICE_REMOVED` / `_RESET`) is logged once with its reason and what to do, and the
window stops presenting. The HDR kinds (`fa_sapp_set_swapchain_kind`, hdr_output_win32.cpp) are the presenter's
buffer formats, and the editor's frame readback is `app_read_window_back_buffer`. `AppDesc::highDpi` false (a test's
window; games and the editor keep it on) now makes the process DPI-unaware, sokol_app's rule without D3D11: Windows
scales the window, where DXGI stretched a smaller swapchain before; the framebuffer size is the same. engine/platform/tests/d3d11_present_tests_win32.cpp draws on a
hidden window (the hardware device, else WARP), with and without MSAA, and makes and destroys a presenter twice on one
HWND. `resize()` reads the live presenter (`window_presenter_live()`: not lost), and a `ResizeBuffers` the driver
refuses is warned once per size.

**Who presents into the window** (fa/platform/app.h, M77-P9e1): a window holds one swapchain, made either by the
platform (`WindowPresenter::Platform`: sokol_app's own, or the D3D11 presenter above) or by a GPU device
(`WindowPresenter::Device`). `window_presenter_step` (window_presenter.cpp, pure, tested on every platform in
window_presenter_tests.cpp) is the state machine app.cpp acts on: `app_gfx_environment()` asks for the platform's
(refused, logged once, while a device holds the window), `app_claim_native_window(backend)` hands the native handles
to a device (refused when the window is busy: an OpenGL or GLES window, whose buffers sokol_app swaps; when a graphics
context draws with the platform's swapchain; when another device holds it) and on Windows releases an idle D3D11
presenter, and `app_release_native_window()` gives it back. While a device holds it `app_gfx_swapchain()` is invalid,
`app_gfx_formats()` gives the window's formats without a device, `app_set_vsync` is false (the present mode is the
swapchain's, set from `RendererDesc::vsync` at start), HDR output is blocked with a reason (`hdrOutput`: "not
available on the <backend> backend yet") and `swapchain_format` is empty. The runner (runners.cpp) works out
`choose_gpu_backend` before it opens anything: on D3D12 or Vulkan with a window that is not busy it makes neither the
sokol context nor the platform swapchain, and `Engine::init` claims the window, starts the renderer on it and releases
the claim after `Renderer::shutdown`. `start_gpu_backend` (fa/runtime/gpu_backend_choice.h) is the fallback rule, in
process, windowed and headless alike: the backend asked for, then `Default` when that one is not the context's
backend, keeping the first error for the warning and `startup_report`'s `gpu.backendFallback`; on the fallback the
engine makes the platform's swapchain itself. Before that fallback `start_gpu_backend` calls `EngineConfig::gpuBackendFailed`
(windowed runs): the Vulkan player of Linux and Android replaces its process with the OpenGL player there (P9e2), so the in-process
fallback never hides a Vulkan failure from it; it runs only when the callback is empty or returns. A claim refused because the
window cannot take a swapchain at all gives a reason that starts with `kGpuWindowPathReason` (`gpu_window_path_reason`), which the
marker's warning in the OpenGL player reads (`is_gpu_window_path_reason`). `EngineConfig::gpuStartFault` makes a backend fail in tests
(gpu_backend_tests.cpp), and renderer_backend_tests.cpp draws D3D12 and Vulkan into a real window (an HWND, a
CAMetalLayer on MoltenVK).

**Vulkan in a build** (`FA_RENDER_VULKAN`, engine/render/CMakeLists.txt): defines `FA_SHADERS_SPIRV` for `fa_render`,
which opens the SPIR-V of every generated header (about 3.4 MB). `AUTO` (the default, worked out again at every
configure, so turning `FA_BUILD_TESTS` on or off moves it): ON on Windows, whose player carries D3D11, D3D12 and
Vulkan; on Linux, Android and macOS it follows `FA_BUILD_TESTS`, so the suite draws the renderer on lavapipe (the
linux CI job) and MoltenVK while a release build (the players, the editor: tests off) carries no SPIR-V; OFF on iOS
and the web. `ON` / `OFF` override it (the macOS CI job builds its tests with `OFF`, so its player-size step measures
the player that ships). It needs `FA_VULKAN_BACKEND`. `renderer_backend_tests.cpp` draws a 2D and a 3D frame on
Vulkan and on the platform's sokol backend and compares them within the golden limits.

**The Vulkan player** (`FA_PLAYER_VULKAN`, on by default on Linux and Android where `FA_VULKAN_BACKEND` is on; ON on macOS
only as a build check): `factoria_player_vulkan` (`libfactoria_player_vulkan.so` on Android), next to the OpenGL
`factoria_player`, which keeps no SPIR-V. Where `FA_RENDER_VULKAN` is off, `fa_render_vulkan` (an OBJECT library) compiles
again, with `FA_RENDER_VULKAN=1 FA_SHADERS_SPIRV`, the `fa_render` sources that read either macro, directly or through a private header or a generated shader header (the list is worked out
at configure time by a grep of the sources), and the variant links those objects before `libfa_render.a`, so the linker
takes them and not the archive's members of the same sources. Where `FA_RENDER_VULKAN` is on, `fa_render_vulkan` is an
empty INTERFACE library and both players are the same build. The variant defines `FA_PLAYER_VULKAN_VARIANT`
(player/main.cpp): its `auto` is Vulkan, and it decides before the window whether it draws or hands over to the OpenGL
player (`decide_gpu_launch`, fa/runtime/gpu_launch.h; docs/RENDERING.md, "Two players on Linux and Android").
`fa_check_not_linked(factoria_player_vulkan fa_authoring)` keeps the tools out of it, and its link map is
`player/factoria_player_vulkan.map`.

## P5c: native_metal and the 2D painter

The last two sokol users outside the passes moved onto the interface.

**`Device::native_metal()`** gives MetalFX the one thing the interface had no equivalent of: `MetalNative`, with
`current_command_buffer()` (the `id<MTLCommandBuffer>` sokol has open for the frame) and `split_commit()` (ends that
buffer with a commit and opens the next, which `Scaler::encode` uses to order its own MTLCommandBuffer against sokol's
frame). It is null on every device that is not Metal, RecordingDevice included. `Scaler` takes the `Device`, so
metalfx.cpp and its tests include no `sokol_gfx.h`.

**The 2D painter** (`engine/render/include/fa/render/ui_painter.h`, implemented in `src/ui_painter.cpp`, private parts in
`src/ui_painter_internal.h`) draws what a client with its own interface needs, and the editor's Dear ImGui is the one such
client. The public header has no ImGui and no sokol type:

- the input is a `UiFrame`: draw lists of `UiVertex` (position, uv, packed colour; the layout of an `ImDrawVert`), 16-bit
  indices, and `UiDrawCommand`s (a texture view, a nearest-or-linear flag, a clip rectangle, an index range and a vertex
  offset);
- pictures are `UiTexture` ids made by `make_texture` (RGBA8 pixels) or `make_updatable_texture` + `update_texture` (a glyph
  atlas), and the renderer's own game picture is `Renderer::game_target_texture()`: both are views on the same context, so
  the editor shows the game through the painter;
- a frame is `upload(frame)` outside a pass (vertices, indices, the queued texture updates through a staging buffer: all the
  writes, then all the copies), `Renderer::begin_window_pass`, `draw(swapchain, frame)`, `Renderer::end_window_pass`,
  `Renderer::commit_context()`. The pipeline is made per `TargetFormat` of the window, with SrcAlpha / OneMinusSrcAlpha blend
  and no depth; an sRGB window gets a gamma of 2.2 on the vertex colour, as sokol_imgui did.

`UiPainter::create` makes a `SokolDevice` of its own on the open context (sokol's ids are shared by every device on it).
`make_ui_painter_on(Device&)` is the private way in for tests: the doctest "UiPainter: a frame is a pipeline, bindings per
texture..." (gpu_interface_tests.cpp) runs a whole frame on a RecordingDevice and checks the order of the calls (pipeline,
bindings per texture change, a scissor and a draw per command, commands outside the window skipped). One frame is capped at
4 Mi vertices: the lists that fit are drawn and `upload` returns false with a message. The shader is
`engine/render/shaders/ui2d.glsl` (generated header `src/shaders/ui2d.glsl.h`).

`native_window_handles(swapchain)` returns what a window screenshot needs (the frame's `CAMetalDrawable` and the
`id<MTLCommandQueue>` on Metal, the `ID3D11Device` and its context on D3D11). It is the editor's only native graphics access: the
Metal capture in tools/editor/src/backbuffer_apple.mm is a blit on that queue, which has no portable form, and the editor's
imgui_backend.cpp holds no `sg_` or `simgui_` call (its input still comes from `sapp_event`).

History: after P5c `Gpu::begin_pass`, the window pass of `Renderer::begin_window_pass` and the context lifecycle
(`open_context`, `close_context`, `commit_context`) were still on sokol. P5d removed them: `Gpu::begin_pass` went (passes
begin on a list), and the window pass and the lifecycle call gpu/sokol_context.h, a sokol backend file (P5d3).

**P5d1: no global device.** `Gpu::active()` and `Gpu::active_device()` (and the list of live Gpus behind them) are gone,
with every overload that asked them: `TaaFx::ready()`, `FogFx::ready(Prog)`, `VolumetricFx::can_draw(targets, plan)`,
`WaterFx::ready()`, `GradientRamps::sync()`, `Gi2dSystem::acquire(n, ...)`, `Gi2dSystem::float_targets_ok()` and
`Ssao::draw_apply(Gpu&, ...)`. A pass gets its device from the `Gpu&` (or `gpu::Device&`) its caller holds: the renderer's
passes pass `gpu` (or `gpu.device()`) down from `Renderer::Impl`, and a caller that can run before the Gpu has a device
(`Impl::jitter_phases`, `upscaler_caps`) checks `gpu.has_device()` first and treats "no device" as "not ready". The
`Gpu::begin_pass` / `end_pass` / `in_pass` / `pass_format` functions became members of the Gpu that owns the list they
record on (P5d3 removed all but `in_pass`); `begin_compute_pass` / `end_compute_pass` had no caller and went. `Renderer::begin_window_pass` and
`end_window_pass` use `gpu::begin_context_pass` / `end_context_pass`, which need no Gpu. History: after P5d1 the
readbacks and the storage-image helpers (moved in P5d2), `sg_bridge.h` and the context lifecycle (`open_context`,
`close_context`, `commit_context`; both moved in P5d3) were still on sokol.

**P5d2: readbacks and queries through the device.** The renderer reads pixels and buffers only with the Device's
`read_image_rgba8`, `read_image_rgba16f`, `read_storage_image` and `read_buffer` (capture, the HDR and probe reads, the
2D GI fields, the MetalFX probe; `result_ok(result, error)` in render_internal.h turns a `Result<void>` into the
renderer's bool + sentence); `render::readback_*`, `render::AsyncBufferRead` and `render::storage_image_loadable` are
gone. The per-backend files (readback_metal.mm, readback_d3d11.cpp, readback_gl.cpp) now implement the `native_*`
functions of gpu/sokol_native.h over the Device's natives (`native()`, `native_image()` with the GL texture of every
frame slot in `NativeImage::glTextures`, `native_buffer()`), and `gpu::AsyncBufferRead` keeps the Device it reads
from: none of them calls sokol. `Device::storage_image_loadable(format, why)` is a new virtual (compute.cpp asks it
for `"access": "readwrite"`); its base answer is false with a sentence that names the backend, so D3d12Device and
VulkanDevice compile unchanged until they answer it. `make_image` of a SokolDevice applies the GLES mip-range fix
itself (`native_finish_image`, image_gl.cpp), so cube and array images need no helper of their own. The adapter
query is `Renderer::gpu_info()` (public): `render::query_gpu_info(device)` reads the D3D11 adapter, the GL strings or
the Metal device through `native()`, and the gi2d read commits with `Gpu::commit_frame()`. RecordingDevice answers the
reads deterministically (see "RecordingDevice"). History: after P5d2 `sg_bridge.h` and `bridged::`, the context
lifecycle (renderer.cpp), gpu_timer.cpp (the sokol backend's own timer) and `native_window_handles` /
`UiPainter::create` (ui_painter.cpp: `sg_isvalid` and the context's native queue and device) were still on sokol; P5d3
moved them behind gpu/sokol_context.h and the sokol backend's files.

**P5d3: no sokol in the renderer.** gpu/sg_bridge.h and `gpu::bridged::*` are gone: Gpu's getters return the
interface's handles, and the conversions (`to_sg` / `from_sg`) are declared in gpu/sokol_device.h. No renderer file
calls sokol: only gpu/sokol_device.cpp and gpu/sokol_context.cpp do (`grep -rln "sg_\|SG_" engine/render/src
--include=*.cpp` also lists renderer.cpp, renderer_present.cpp, shader_cache.cpp and gpu/types.cpp, for comments and the
"sg_setup failed" message). The files that may include sokol: gpu/sokol_device.h (the two above, gpu/device.cpp, which
makes a SokolDevice, and the tests that check the GPU directly) and gpu/sokol_shaders.h (see below). The readbacks,
image_gl.cpp and gpu_timer.cpp work on the natives (`native()`, `native_image()`, `context_native()`). The code that runs while no Device exists uses gpu/sokol_context.h
(sokol-free): `open_context` / `close_context` / `commit_context` / `context_open` (Renderer's context lifecycle),
`begin_context_pass` (the window pass), `context_native` / `context_backend` / `swapchain_of` (`native_window_handles`,
`UiPainter::create`, `Renderer::backend_name`: with no open context it answers with the backend this build compiles, not "dummy"). The generated shader headers still need sokol's declarations (their
desc functions take an `sg_backend`); a file that includes one includes gpu/sokol_shaders.h first, which brings the
types and `generated_shader_desc` and nothing to call. `Gpu::begin_pass` / `end_pass` / `pass_format` went with the
format check of `find_or_make`, which only their tests used: the check is now in the command list (see "How the
renderer reaches the device"), so it covers every pass. The MSAA fallback of `Renderer::init` is in `Gpu::init`
(`device.pixel_format_caps(Rgba8).msaa`).

## How to convert an sg_* call site

| sokol | gpu interface |
|---|---|
| `sg_make_buffer(&desc)` | `device.make_buffer(BufferDesc)` (`usage.writeTransient` for a buffer rewritten each frame) |
| `sg_make_image`, `sg_make_view`, `sg_make_sampler` | `make_image(ImageDesc)`, `make_view(ViewDesc)`, `make_sampler(SamplerDesc)` |
| `sg_make_shader(name_shader_desc(backend))` | `make_shader(generated_shader_desc(name_shader_desc))` |
| `sg_make_pipeline(&desc)` | `make_pipeline(PipelineDesc)` |
| `sg_destroy_*(h)` | `destroy_*(h)` |
| `sg_query_*_state(h)` | `state(h)` |
| `sg_query_features()`, `sg_query_limits()`, `sg_query_pixelformat(f)` | `features()`, `limits()`, `pixel_format_caps(f)` |
| `sg_query_backend()` | `backend()` / `info().metalTarget` |
| `sg_query_desc().environment.defaults` | `environment_defaults()` |
| `sg_mtl_device()`, `sg_d3d11_device()`, `sg_*_query_image_info`, `sg_*_query_buffer_info` | `native()`, `native_image(h)`, `native_buffer(h)` |
| `sg_begin_pass(&pass.to_sg())` | `list.begin_pass(PassDesc)` (`PassDesc::for_swapchain(sc, device.environment_defaults())` for a window pass) |
| `sg_begin_pass` with `compute = true` | `list.begin_compute_pass(label)` |
| `sg_end_pass()`, `sg_query_pass_state()` | `list.end_pass()`, `list.pass_state()` |
| `sg_apply_pipeline`, `sg_apply_bindings`, `sg_apply_uniforms(slot, &SG_RANGE(u))` | `set_pipeline`, `set_bindings(Bindings)`, `set_uniforms(slot, Range{&u, sizeof u})` |
| `sg_apply_viewport`, `sg_apply_viewportf`, `sg_apply_scissor_rect` | `set_viewport`, `set_viewport_f`, `set_scissor` |
| `sg_draw`, `sg_draw_ex`, `sg_dispatch` | `draw`, `draw_ex`, `dispatch` |
| `sg_write_buffer_transient`, `sg_write_image_transient` | `write_buffer(BufferWrite)`, `write_image(ImageWrite)` |
| `sg_copy_buffer_to_buffer`, `sg_copy_buffer_to_image` | `copy_buffer_to_buffer`, `copy_buffer_to_image` (outside a pass) |
| `sg_push_debug_group`, `sg_pop_debug_group` | `push_debug_group`, `pop_debug_group` |
| `sg_commit()`, `sg_add_commit_listener` | `device.submit(list)` then `device.commit()`, `add_commit_listener` |
| `sg_reset_state_cache()` | `reset_state_cache()` |
| `sg_query_stats().total`, `sg_enable_stats` / `sg_disable_stats` | `total_stats()`, `enable_stats(on)` |
| `GpuTimer` | `timer_supported`, `timer_begin_frame`, `begin_timed_scope` / `end_timed_scope` on the list, `timer_poll` |
| `readback_rgba8`, `readback_rgba16f`, `readback_storage_image`, `readback_buffer` | `read_image_rgba8`, `read_image_rgba16f`, `read_storage_image`, `read_buffer` |
| `AsyncBufferRead` | `async_read_supported`, `request_buffer_read`, `poll_buffer_read`, `release_buffer_read` |
| `storage_image_loadable(format, why)` (render_internal.h) | `device.storage_image_loadable(format, why)` |
| `render::query_gpu_info()` | `Renderer::gpu_info()` (the renderer's device; private: `render::query_gpu_info(device)`) |

A test of the converted code makes a `RecordingDevice` and asserts on `errors()` (empty) and on `stream_text()`; a
test that needs pixels keeps the GPU fixture (`fa::test::gfx()`) and reads through the `SokolDevice`.

## D3D12 backend

The engine's own Direct3D 12 device (M77-P7, M77-P9) has a page of its own:
[ARCHITECTURE_RENDERING_D3D12.md](ARCHITECTURE_RENDERING_D3D12.md).

## Vulkan backend

The engine's own Vulkan device (M77-P8a, M77-P8c) has a page of its own:
[ARCHITECTURE_RENDERING_VULKAN.md](ARCHITECTURE_RENDERING_VULKAN.md).
