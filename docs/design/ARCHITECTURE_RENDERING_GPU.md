# FactorIA architecture: the GPU interface (M77)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The engine's own GPU interface, `fa::gpu`, which the
renderer moves onto during M77 so that the D3D12 and Vulkan backends can sit next to sokol_gfx. Its code is in
`engine/render/src/gpu/` (private to `fa_render`); its tests are `engine/render/tests/gpu_interface_tests.cpp`
(ctest `render_gpu_interface_core`, no GPU needed); the backends' own tests are `d3d12_device_tests.cpp` and
`vulkan_device_tests.cpp` (ctests `render_d3d12_device`, `render_vulkan_device`).

## Layers

```
renderer (Renderer, Gpu, the passes)          today: sg_* calls; after M77-P2..P5: gpu::Device / gpu::CommandList
        |
gpu::Device + gpu::CommandList (device.h)     the interface: resources, capabilities, the frame, timers, readbacks
        |
SokolDevice (sokol_device.h/.cpp)             GL, GLES3, WebGL2, D3D11, Metal through sokol_gfx (stays)
D3d12Device (d3d12_device.h, M77-P7a core)    the engine's own backends ("D3D12 backend" below)
VulkanDevice (vulkan_device.h, M77-P8a core)  ("Vulkan backend" below)
RecordingDevice (recording_device.h/.cpp)     no GPU: validates every call and records the stream (tests)
```

- `gpu/types.h` is the vocabulary: handles, enums, descs, capabilities, pass and binding structs. No sokol type
  appears in it, so a D3D12 or Vulkan backend includes nothing of sokol.
- `gpu/device.h` declares `Device` and `CommandList` (pure virtual), `DeviceInit`, `make_device(Backend, DeviceInit)`
  and `built_sokol_backend()` (the one sokol backend a binary has: sokol compiles one per build).
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
- statistics (`enable_stats`, `total_stats`), GPU timers (`timer_*`), readbacks (`read_image_rgba8`,
  `read_image_rgba16f`, `read_storage_image`, `read_buffer`) and asynchronous buffer reads (`request_buffer_read`,
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
- The generated shader headers return `sg_shader_desc`: `from_sg(*name_shader_desc(sg_query_backend()))` gives the
  `ShaderDesc` for `Device::make_shader`.
- `from_sg(const sg_pipeline_desc&)` converts the pipeline descs `Gpu::find_or_make` builds today.
- `to_sg(const PassDesc&)` gives the `sg_pass` of a pass (the swapchain case included); `swapchain_pass(sc)` is
  `PassDesc::for_swapchain` with the defaults of the open sokol context (a test checks every field).
- `SokolDevice::create` adopts the sokol context that is open (the renderer's; left open at destruction) or opens one
  from `DeviceInit` (and shuts it down at destruction). `frame_index()` counts commits through a commit listener.
- Timers and readbacks forward to the renderer's `GpuTimer`, `readback_*.cpp/.mm` and `AsyncBufferRead`.
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
memory and no clock: readbacks and asynchronous reads fail with a hint, and `timer_supported()` is false with a
reason (the timed scopes are still recorded).

## How the next packages migrate

- **P2..P5** move the renderer's call sites onto the interface: `Gpu` owns a `Device` (made with
  `make_device(built_sokol_backend())`, adopting the context the renderer opened), the shared code first (`Gpu`, the
  frame graph's target pool, the pipelines cache), then the passes one file at a time. Each step keeps the goldens
  unchanged; a converted file includes no `sokol_gfx.h`.
- Handles keep sokol's ids during the move, so a converted function can hand a `gpu::Image` to one that still takes
  `sg_image` (`to_sg(h)`), and the reverse (`from_sg(img)`).
- **M77.2 / M77.3** add `D3d12Device` and `VulkanDevice` behind the same interface; `make_device(Backend::D3d12)` and
  `Backend::Vulkan` stop returning "not built yet". RecordingDevice's checks are the contract they implement: a frame
  that RecordingDevice accepts must run on them.

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
- **`Gpu::begin_pass` / `end_pass`**: non-static members that record on this Gpu's own list (`commands()`) and remember
  the pass's `TargetFormat` for the debug check of the pipeline cache (a pipeline fetched inside the pass must be for its
  format). Converted code mostly begins its passes straight on its list (`gpu::CommandList& cl = gpu.commands();
  begin_list_pass(cl, pass)`, `cl.end_pass()`); such a pass does not set the Gpu's `inPass_` flag, so that check is skipped
  for it, while `Gpu::in_pass()` and `begin_transient_writes` also ask `list.pass_state()`. A window pass
  (`Renderer::begin_window_pass`, `present_clear`) is a pass on the sokol context itself (`gpu::begin_context_pass`),
  because it runs with no renderer.
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

While the move runs, gpu/sg_bridge.h connects the two sides (it goes with the last sg_* call site, M77-P5):

- `to_sg` / `from_sg` convert handles (the same id), enums (the same value) and descs (field by field);
- `gpu::bridged::*` is a handle that also converts to and from its sokol twin: Gpu's getters return one (pipelines,
  samplers, buffers) so the passes that still call `sg_apply_pipeline` take it unchanged. Never put one in a ternary
  next to an `sg_*` value (`t ? t->view : sg_view{}`): each side converts to the other and the compiler cannot
  choose; write `to_sg()` or `from_sg()` on one side;
- `generated_shader_desc(fn)` turns a generated shader header's desc (shaders/*.glsl.h) into a `gpu::ShaderDesc`.

A converted file includes no `sokol_gfx.h` directly; it may still see sokol's types through render_internal.h and
sg_bridge.h until P5. Converted so far: gpu.cpp (Gpu, its pipelines and samplers), render_internal.h, the target helpers
(target.cpp), shader_cache.cpp and render_features.cpp; assets.cpp, custom_shader.cpp, water2d.cpp, gi2d.cpp,
renderer_lights2d.cpp, fonts.cpp, gradient_ramp.cpp, postprocess.cpp and bloom.cpp (P3: their passes open on
`gpu.commands()` or `PassContext::commands()`; a class with no Gpu member (WaterFx, GradientRamps, Gi2dSystem,
AutoExposure) remembers the `gpu::Device` it first got, and keeps an overload without a device for the callers not
converted yet); compute.cpp, light_atlas.cpp, renderer_hiz.cpp, renderer_probes_gpu.cpp and renderer_gi_gpu.cpp (they
open their passes on `gpu.commands()`); the frame graph carries the list to its passes; the 3D geometry passes of the
renderer (M77-P4a): renderer_draw.cpp (the light, shadow, prepass, subsurface, quad-motion, main and HUD passes, the
uploads and the bindings of a draw), renderer_terrain.cpp, renderer_targets.cpp, renderer_decals.cpp,
renderer_impostor.cpp, mesh_buffer_draw.cpp and renderer.cpp's `sg_commit`s (now `Gpu::commit_frame()` followed by
`note_commit()`; `present_clear` keeps its own, it runs with no Gpu). `apply_uniforms(list, slot, u)` and
`begin_list_pass(list, pass)` (renderer_impl.h) are the two helpers a converted pass uses. What still touches sokol in
those files: the context lifecycle (before any device exists), the readbacks. A pass opened on its
own list does not set `Gpu::inPass_`: `Gpu::in_pass()` and `begin_transient_writes` also ask the list for its pass
state, and gi2d.cpp's draw_list writes its transient buffers before its pass begins. gpu_timer.cpp stays on sokol: it is
the sokol backend's own timer (the D3D11 device calls), like the `readback_*` files. The 3D light and environment passes
(M77-P4b): renderer_env (the sky cube and its prefilter), renderer_sky_phys, renderer_subsurface, renderer_fog,
renderer_volumetric, renderer_xmit (transmission), renderer_hdri and the read-back commits of renderer_probes. Each of
those classes makes its shaders, pipelines, images and samplers on `gpu.device()` and remembers the device in `ready()`
(`device_`), because `release()` has no `Gpu` at hand. A pass declared in the frame graph records on
`PassContext::commands()` (`c.commands() ? *c.commands() : g->commands()`); one drawn outside the graph records on
`gpu.commands()`. P4c: the 3D post-process and
upscale passes and the present (renderer_dof, renderer_ssr, renderer_ssao, renderer_taa, renderer_custom_post,
renderer_upscale, render_upscale_spatial, render_upscale_metalfx, renderer_present and the preparation pass of
renderer_metalfx). They share fullscreen_gpu.h: `pass_list(c, gpu)` (the frame's list, or the Gpu's own when a CPU-only
graph has none) and `make_triangle_pipeline`. Each class remembers the `gpu::Device` of its `ready(...)` call and makes
its pipelines before the pass begins. The MetalFX wrapper (metalfx.h, metalfx_apple.mm, metalfx.cpp) moved in
P5c, see "P5c: native_metal and the 2D painter" below.
P5a: the render targets and formats are interface types. `Target` holds `gpu::Image` / `gpu::View` made on the Gpu's
device (target.cpp; `TransientTargets` takes the device), `TargetDesc`, the format getters (`scene_format()`,
`velocity_format()`...) and the pass headers use `gpu::PixelFormat`, and `TargetFormat` / `PassDesc` have one definition
(`gpu/types.h`; gpu_types.h only brings them into `fa::render`). A window pass is `gpu::swapchain_pass(sc)` over a
`gpu::Swapchain` converted from the platform's `sg_swapchain`. Still on sokol types at their edges: the readbacks and the
storage-image helpers (`readback_*`, `storage_image_loadable`), which take `gpu::to_sg(...)` of a `Target`'s handles.
P5b: the asset and material types are interface types. `TextureAsset` and `LutAsset` hold a `gpu::Image` / `gpu::View`
and a `gpu::PixelFormat`, `SubMesh` its `gpu::Buffer`s, `MaterialProgram` a `gpu::Shader`; ktx2.cpp picks the target
format from the device's pixel-format caps (`ktx2_target_format(device)`) and `transcode_ktx2` takes the device.
`material_shader_desc` returns a `gpu::ShaderDesc` built from the twin's reflection, with the binding numbers of every
backend the reflection names (hlsl register, msl index, wgsl and spir-v group and binding, glsl binding), and
`make_material_program` creates it with `gpu.device().make_shader`. The sokol overloads of `make_shader`
(shader_cache_sg.cpp) and `feature_env_from_sokol` (render_features_sg.cpp) are deleted: nothing called them. Draws
bind the interface handles as they are; `draw_group` no longer converts its bindings twice. The files of this list
call no `from_sg` any more; `to_sg` is left only in front of the sokol-only readbacks and storage-image helpers.

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

Still on sokol after P5c: `Gpu::begin_pass`, the window pass of `Renderer::begin_window_pass` (P5d), and the context lifecycle
(`open_context`, `close_context`, `commit_context`).

**P5d1: no global device.** `Gpu::active()` and `Gpu::active_device()` (and the list of live Gpus behind them) are gone,
with every overload that asked them: `TaaFx::ready()`, `FogFx::ready(Prog)`, `VolumetricFx::can_draw(targets, plan)`,
`WaterFx::ready()`, `GradientRamps::sync()`, `Gi2dSystem::acquire(n, ...)`, `Gi2dSystem::float_targets_ok()` and
`Ssao::draw_apply(Gpu&, ...)`. A pass gets its device from the `Gpu&` (or `gpu::Device&`) its caller holds: the renderer's
passes pass `gpu` (or `gpu.device()`) down from `Renderer::Impl`, and a caller that can run before the Gpu has a device
(`Impl::jitter_phases`, `upscaler_caps`) checks `gpu.has_device()` first and treats "no device" as "not ready". The
`Gpu::begin_pass` / `end_pass` / `in_pass` / `pass_format` functions are members of the Gpu that owns the list they
record on; `begin_compute_pass` / `end_compute_pass` had no caller and went. `Renderer::begin_window_pass` and
`end_window_pass` use `gpu::begin_context_pass` / `end_context_pass`, which need no Gpu. Still on sokol after P5d1: the
readbacks, the storage-image helpers and `sg_bridge.h` (P5d2), and the context lifecycle (`open_context`, `close_context`,
`commit_context`).

## How to convert an sg_* call site

| sokol | gpu interface |
|---|---|
| `sg_make_buffer(&desc)` | `device.make_buffer(BufferDesc)` (`usage.writeTransient` for a buffer rewritten each frame) |
| `sg_make_image`, `sg_make_view`, `sg_make_sampler` | `make_image(ImageDesc)`, `make_view(ViewDesc)`, `make_sampler(SamplerDesc)` |
| `sg_make_shader(name_shader_desc(backend))` | `make_shader(from_sg(*name_shader_desc(backend)))` |
| `sg_make_pipeline(&desc)` | `make_pipeline(PipelineDesc)` (or `from_sg(desc)` while the desc is still built as sokol's) |
| `sg_destroy_*(h)` | `destroy_*(h)` |
| `sg_query_*_state(h)` | `state(h)` |
| `sg_query_features()`, `sg_query_limits()`, `sg_query_pixelformat(f)` | `features()`, `limits()`, `pixel_format_caps(f)` |
| `sg_query_backend()` | `backend()` / `info().metalTarget` |
| `sg_query_desc().environment.defaults` | `environment_defaults()` |
| `sg_mtl_device()`, `sg_d3d11_device()`, `sg_*_query_image_info`, `sg_*_query_buffer_info` | `native()`, `native_image(h)`, `native_buffer(h)` |
| `sg_begin_pass(&pass.to_sg())` | `list.begin_pass(PassDesc)` (`gpu::swapchain_pass(sc)` for a window pass) |
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

A test of the converted code makes a `RecordingDevice` and asserts on `errors()` (empty) and on `stream_text()`; a
test that needs pixels keeps the GPU fixture (`fa::test::gfx()`) and reads through the `SokolDevice`.

## D3D12 backend

The engine's own Direct3D 12 device (M77-P7a: the core; M77-P7c1: shaders, pipelines, passes and draws; M77-P7c2:
GPU timers and asynchronous reads; M77-P9: the window). Its code is
`engine/render/src/gpu/d3d12_device.h` and `d3d12_*_win32.cpp` (the `_win32` suffix keeps it out of every other
build); `d3d12_device.cpp` is the factory of the other platforms, which returns a teaching error ("runs on Windows
only", hint `make_device(built_sokol_backend())`). `fa_render` links `d3d12`, `dxgi` and `dxguid` on Windows.
`make_device(Backend::D3d12)` still answers "not built yet" until the renderer can run on it; tests and tools make it
with `make_d3d12_device(D3d12Options)`.

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
`D3d12Device::pso()` is the seam of the on-disk PSO cache (M77-P7b).

**Passes and draws.** `begin_pass` checks its attachments (live views of the right kind, one size, the resolve
single-sampled with the colour format, the depth sample count equal to the colour one) and that `PassDesc::format` is
what they are; it sets the targets, clears what `colorLoad` / `depthLoad` / `stencilLoad` say (Clear, or Default),
and a viewport and scissor over the whole target. `end_pass` resolves an MSAA colour attachment into `resolve`. A pass
into the window (`PassDesc::swapchain`) is an error until M77-P9. `set_pipeline` checks that the pipeline is a render
one in a render pass and a compute one in a compute pass, and that its formats, colour count and sample count equal
the pass's. `set_bindings` checks every slot against the shader (an empty slot the shader declares, a slot it does
not, a view of the wrong kind, a buffer without the usage) and `set_uniforms` the block's exact size; uniforms are
copied into the upload ring (256-byte aligned) and bound as root CBVs. Draws and dispatches check that every uniform
block was set and `set_bindings` called since `set_pipeline`. As in sokol, once a `set_pipeline`, `set_bindings` or
`set_uniforms` fails, the draws are skipped without further errors until the next `set_pipeline`, and everything
inside a pass whose `begin_pass` failed is skipped. `draw_ex`'s `baseVertex` is the index offset with an index buffer
and is added to `base` without one; dispatch counts are 0 to 65535 per dimension.

**Not yet (M77-P9).** Passes into the window.

**Tests.** `engine/render/tests/d3d12_device_tests.cpp` (ctest `render_d3d12_device`): on Windows each case makes a
WARP device with the debug layer and ends by checking that the layer reported no error. Resources: buffer and image
round trips with mips, RGBA8 and RGBA16F, both `copy_buffer_to_image` paths, deferred destruction, the ring's wrap and
the dedicated uploads, descriptor exhaustion and reuse. Drawing, each read back and checked per texel: a clear-only
pass; a uniform-colour fullscreen triangle into RGBA8 and RGBA16F; the engine's own blit shader (the HLSL of
`blit.glsl.h`) with a nearest and a linear sampler; an indexed, instanced draw with a base vertex; a depth test and a
viewport; an MSAA 4x resolve (the texels on the triangle's edge are partly covered); a compute pass writing a storage
image and a storage buffer, whose second dispatch reads the first's writes. GPU timers: timed frames with two scopes
resolving to non-negative times in order, a scope outside a timed frame, an unsubmitted scope, `timer_forget` and a
full ring. Asynchronous reads: a buffer, a 33x3 region of a 37x5 RGBA8 image (rows that are not 256-byte multiples),
bad requests, a read that outlives `destroy_buffer`, stale and released tickets, 32 reads in flight and the 33rd
refused, a slot buffer that grows. Then the PSO and root-signature caches,
the root signature of a shader with one block, two views and two samplers, and every error of `make_shader`,
`make_pipeline` and the command list. A Windows without WARP says so with a MESSAGE and passes. Elsewhere one case
checks the factory's error. `D3d12Device::counters()`, `view_heap()`, `shader_root_layout()` and
`read_image_region` exist for these tests.

## Vulkan backend

The engine's own Vulkan device (M77-P8a: the core; pipelines, passes and draws are M77-P8c). Its code is
`engine/render/src/gpu/vulkan_device.h` and `vulkan_*.cpp` (loader, device, memory, resources, commands, readback).
CMake builds it where `FA_VULKAN_BACKEND` is on: Linux, Windows and Android, and macOS for its tests only (through
MoltenVK; Vulkan is never a macOS product backend, games there use Metal); never on the web or iOS, where
`make_vulkan_device` returns a teaching error. The sources compile with `VK_NO_PROTOTYPES` against the vendored
Khronos headers (`external/vulkan_headers`) and link no Vulkan library: the loader is opened at run time
(`libvulkan.so.1`, `vulkan-1.dll`, `libvulkan.1.dylib` with the Homebrew prefixes on macOS, or
`VulkanOptions::loaderPath`), so a binary on a system without Vulkan starts and the error says what to install. There is
no volk and no VMA. `make_device(Backend::Vulkan)` still answers "not built yet" until the renderer can run on it;
tests and tools make it with `make_vulkan_device(VulkanOptions)`.

**Options and start-up.** `VulkanOptions` picks a CPU device (`cpuDevice`: lavapipe) or the best GPU (discrete, then
integrated), the validation layer, the frames in flight (1 to 3), the upload ring's size, the suballocator's block size
and dedicated threshold, the per-frame descriptor pools, the bindless table and `synchronization2`. Contradictions are
errors before any Vulkan call. The instance asks for Vulkan 1.3 where the loader has it (1.2 at least), with
`VK_EXT_debug_utils` and portability enumeration when present; the device needs Vulkan 1.2, timeline semaphores and a
graphics + compute queue, and enables `VK_KHR_portability_subset` where the driver lists it (MoltenVK:
`portability_subset()`). A GPU with a transfer-only queue family also gets that queue (`transfer_queue()`, for
M77-P8c's uploads). Without the validation layer installed, or with a layer the loader lists but cannot open, the
device is made without it, warns, and `validation_active()` is false. On macOS, Homebrew's layer manifest names its
library by a bare file name dyld does not find; once per process the device writes a copy of the manifest with the
absolute path into the temporary directory and adds it through `VK_ADD_LAYER_PATH` (unless `VK_LAYER_PATH` or
`VK_ADD_LAYER_PATH` is set already), so the user sets nothing.

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
(`counters().pendingReleases`).
`wait_idle()` drains the queue and releases everything pending, the current frame's destroyed objects included (the
frame's upload ring room waits for its `commit()`: lists still open may have written into it).

**Memory.** The engine's own suballocator: a pool of blocks (`memoryBlockBytes`) per memory type and per linear or
optimal resource (so `bufferImageGranularity` never matters), first fit with coalescing free ranges; a resource of
`dedicatedThreshold` bytes or more, and every readback buffer, takes an allocation of its own. Host-visible blocks stay
mapped; upload memory is host-coherent, and readback memory that is not is invalidated before the CPU reads it. `counters().memory` counts blocks, dedicated
allocations, live pieces and bytes.

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
barriers are merged over neighbouring mips and layers, batched and flushed before each copy, through
`vkCmdPipelineBarrier2` where the device has synchronization2 (core in 1.3) and the Vulkan 1.0
`vkCmdPipelineBarrier` otherwise (`synchronization2 = false` forces it, for its tests). Lists may be recorded on
several threads and submitted in any order, so at submit a fix-up command buffer moves every subresource from the
state the queue left it in to the one the list starts with, executed just before it (`counters().barriers`).

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
block.

**Not yet (M77-P8c).** `make_shader`, `make_pipeline`, `begin_pass` and everything inside a pass, `dispatch`, the GPU
timers and the asynchronous buffer reads report "not built yet (M77-P8c)" and record nothing (a `CommandList` method
reports once per device, `make_shader` / `make_pipeline` on every call).

**Tests.** `engine/render/tests/vulkan_device_tests.cpp` (ctest `render_vulkan_device`): each case makes a device on
the machine's Vulkan driver with the validation layer and ends by checking that the layer reported no error (buffer
and image round trips with mips, RGBA8, RGBA16F, BGRA, arrays, cubes and 3D images, every view kind, both
`copy_buffer_to_image` paths, deferred destruction, the ring's wrap and the dedicated uploads, descriptor-pool
exhaustion and reuse, the bindless table, the Vulkan 1.0 barriers, the "not yet" errors, a CPU device on request); a
machine with no loader or no Vulkan device says so with a MESSAGE and passes, and one case checks the factory's
errors (bad options, a missing loader). They run on macOS through MoltenVK (`brew install vulkan-loader molten-vk
vulkan-validationlayers`) and on Windows where a Vulkan driver is installed; Linux CI has no Vulkan driver until M77-P8b brings
lavapipe, so there they skip. `VulkanDevice::counters()`, `fn()` and `read_image_region` exist for these tests.
