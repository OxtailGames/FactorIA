# FactorIA architecture: the GPU interface (M77)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page; the rendering page is
[ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md)). The engine's own GPU interface, `fa::gpu`, which the
renderer moves onto during M77 so that the D3D12 and Vulkan backends can sit next to sokol_gfx. Its code is in
`engine/render/src/gpu/` (private to `fa_render`); its tests are `engine/render/tests/gpu_interface_tests.cpp`
(ctest `render_gpu_interface_core`, no GPU needed).

## Layers

```
renderer (Renderer, Gpu, the passes)          today: sg_* calls; after M77-P2..P5: gpu::Device / gpu::CommandList
        |
gpu::Device + gpu::CommandList (device.h)     the interface: resources, capabilities, the frame, timers, readbacks
        |
SokolDevice (sokol_device.h/.cpp)             GL, GLES3, WebGL2, D3D11, Metal through sokol_gfx (stays)
D3D12 device (M77.2), Vulkan device (M77.3)   the engine's own backends (not built yet)
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
- the natives: `native()`, `native_image()`, `native_buffer()` (MetalFX, the ImGui backend and the platform glue
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
- A list is not used after `submit()`.

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
- `to_sg(const PassDesc&)` gives the same `sg_pass` as `render::PassDesc::to_sg()`; `from_render` / `to_render`
  convert `render::PassDesc` and `render::TargetFormat` (a test checks every field).
- `SokolDevice::create` adopts the sokol context that is open (the renderer's; left open at destruction) or opens one
  from `DeviceInit` (and shuts it down at destruction). `frame_index()` counts commits through a commit listener.
- Timers and readbacks forward to the renderer's `GpuTimer`, `readback_*.cpp/.mm` and `AsyncBufferRead`.
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
| `sg_begin_pass(&pass.to_sg())` | `list.begin_pass(PassDesc)` (`from_render(pass, swapchain)` while the pass is still a `render::PassDesc`) |
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
