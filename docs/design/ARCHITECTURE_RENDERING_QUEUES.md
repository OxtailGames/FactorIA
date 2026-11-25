# Rendering on several queues and threads (M77-P10d)

Part of [ARCHITECTURE.md](ARCHITECTURE.md) (rendering: [ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md); the device
contract it builds on: [ARCHITECTURE_RENDERING_GPU.md](ARCHITECTURE_RENDERING_GPU.md), "Queues, tokens, threads and
bindless"). How the renderer uses what the D3D12 and Vulkan devices offer since M77-P10a to P10c: command lists recorded
on job threads (`Features::multiThreadRecording`) and a compute queue next to the graphics one (`Features::asyncCompute`).
Both stay deterministic: the frame is the same picture, with the same draws, as on one thread and one queue.

## The switches

`RendererDesc::asyncCompute` and `RendererDesc::multiThreadRecording` (both `true` by default), from `factoria.json`'s
`render.asyncCompute` and `render.multiThreadRecording` (`ProjectSettings::renderAsyncCompute`,
`renderMultiThreadRecording`; docs/RENDERING.md, "Async compute and multi-thread recording"). `Gpu::set_queue_options`
keeps each one only where the device has the feature, so the sokol backends never use either; `Gpu::async_compute()`
and `Gpu::parallel_recording()` answer what is in use, and `Renderer::startup_report()` has them as `asyncCompute` and
`multiThreadRecording`. A RecordingDevice has both features in its default caps, so the renderer on it records the
shadow lists on threads; it has no asynchronous reads, so the depth pyramid (and with it the compute queue) never runs
there.

## Shadow views on job threads

Which work: the shadow pass (`Renderer::Impl::shadow_pass`, renderer_draw.cpp), the views of the shadow atlas: the sun's
cascades and the tiles of the spot and point lights. It is the only part of the frame that qualifies today. Its views
are independent of each other (each draws into its own tile, viewport and scissor), it has one draw per batch and view
(the most draws of a 3D frame after the main pass), and nothing else in the frame writes the atlas. The other passes
either read what the pass before wrote (the post stack, the prepass and the main pass), are a few draws (the 2D lights,
the decals) or are compute.

How:

1. The views the atlas places are split into at most four groups of consecutive views (`kShadowRecordGroups`); the
   split depends on the number of views only, never on the thread count. Fewer than two views: one pass on the frame's
   list, as before.
2. Each group is recorded on the render thread into a `render::CommandCapture` (command_capture.h): a `CommandList`
   that runs nothing and keeps every call with a copy of the bytes it points at (uniforms, writes, labels). The draw
   loop (`shadow_views`) makes pipelines, reads the asset and material caches and counts `stats.drawCalls`: work of the
   render thread, which the device contract also asks for (`make_*` on the render thread only).
3. One graphics list per group is begun on the render thread; `jobs::parallel_for("render.shadow_record", groups, 1)`
   replays each capture into its own list on the job threads. That is where D3D12 and Vulkan spend their recording time
   (descriptor writes, `vkCmd*`, the D3D12 command lists' calls).
4. `Gpu::submit_in_order` submits the frame's list so far, then the group lists in group order, and begins a new frame
   list. Lists of one queue run in submission order, so the GPU sees the order of the single list.

The first group's pass clears the atlas colour (the shadow depth lives in the colour); the later groups load it. Each
pass clears the depth attachment, which only orders the draws inside one tile and is not kept. Every tile is drawn by
one group only, so the atlas is the one the single pass draws. Without the pool (`jobs::parallel_for` inline), the
replays run on the render thread one after the other: the same lists.

## The depth pyramid on the compute queue

Which work: the `hiz-reduce` pass of GPU occlusion (`Renderer::Impl::hiz_reduce_pass`, renderer_hiz.cpp;
[ARCHITECTURE_RENDERING_BIGWORLDS.md](ARCHITECTURE_RENDERING_BIGWORLDS.md), "Occlusion culling on the GPU, the depth pyramid (M75.2b)"). It is the frame's only compute
pass (scripts' `compute.dispatch` runs outside the frame graph), it reads the prepass and writes a buffer of its own
(the cells), and nothing in the same frame reads that buffer: it is read back after the commit and used the next frame.
Its result does not depend on which queue ran it.

The feature table (render_features.cpp) has no D3D12 or Vulkan column yet (`feature_backend_of` maps both to Headless),
so `hiz_resolve` asks those two devices directly (`Features::compute`). GPU occlusion runs on them since M77-P10d;
`render.supports {"feature": "occlusionGpu"}` still answers from the table there until their columns land.

How (`Gpu::begin_async_compute`, `end_async_compute`):

1. The frame's list is submitted with `submit_token` and a `QueueHandoff` of the prepass image and the cells buffer to
   `Compute`; a new frame list begins.
2. A compute list (`begin_commands("hiz-reduce", QueueKind::Compute)`) waits for that token (`wait_list`), records the
   compute pass and is submitted with `submit_token` handing both back to `Graphics`. The token and the pool handle of the
   prepass target (the guard) go on `Gpu`'s pending list.
3. The graphics passes after it run meanwhile. The frame graph's `PassHooks::before` (set only while async compute is in
   use) gives `Gpu::wait_compute_for` the pool handles of the next pass's reads and writes; the first pass that declares
   the prepass target makes the graphics queue wait (`submit` of the frame list, `wait_queue(Graphics, token)`, a new
   frame list). `Gpu::commit_frame` waits for what is still pending after the frame's last list, so the read-back of the
   cells, the next frame and `shutdown` see the work done and both resources back on the graphics queue. A wait for the
   latest pending token covers the ones before it (one compute queue runs its lists in submission order).

The camera's main pass declares the prepass as a read (contact shadows and the effects sample it), so the graphics
queue waits there at the latest, or at an earlier pass that declares it (ambient occlusion, volumetric fog, the sprites'
velocity): the reduce overlaps with the graph's passes between it and that first reader. The wait never needs a guess:
it is the frame graph's declared reads, so a pass added later that reads the prepass waits too.

## Tests

engine/render/tests/render_queues_tests.cpp: a `CommandCapture` replays every call as the direct recording makes it; on
a RecordingDevice the Gpu's async compute hands both resources over and back in the contract's order and the graphics
queue waits once (at the pass that reads, or at the commit); the renderer's shadow lists on a RecordingDevice hold the
single list's commands with the pool stopped, inline, with 2 and 8 workers; on Vulkan (validation on, a compute queue of
another family where the machine has one: MoltenVK; lavapipe has none, so only the recording on threads runs there) and
on D3D12 WARP (Windows) a scene of four cascades, a spot shadow and GPU occlusion draws the same pixels with both
switches on and off, with no validation error. The sokol frame is untouched (graphics_same_hash, the perf budgets).
