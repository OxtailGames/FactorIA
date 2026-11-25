# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.35](changelog/0.35.md), [0.34](changelog/0.34.md), [0.33](changelog/0.33.md), [0.32](changelog/0.32.md), [0.31](changelog/0.31.md), [0.30](changelog/0.30.md), [0.29](changelog/0.29.md), [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- The test suites no longer leave temporary project folders behind in the temp folder (the render tests' project folder, the menu kit,
  tool catalog, menu screenshot and layout check tests, the windowed runtime tests, the editor autotest's MCP config copy):
  `fs::make_temp_dir_until_exit` makes a scratch folder that is removed when the program ends.

### Rendering

- The Vulkan backend presents to a window (M77-P9d): `create_swapchain` makes a surface on the native window (an HWND, an X11 window
  with its display, an `ANativeWindow`, a `CAMetalLayer` on macOS through MoltenVK) and a swapchain of frames in flight + 1 images (FIFO
  with vsync, else MAILBOX or IMMEDIATE; SDR, scRGB and HDR10 formats where the surface offers them; MSAA resolved into the acquired
  image), `acquire_swapchain` and `present` run on the graphics queue, and a window that changed (out of date or suboptimal) gets its
  swapchain made again at the next acquire, as `resize_swapchain` does. The renderer does not draw into a window on it yet: it does
  not hand the device the window's native handle, so `init()` without `headless` says so. Also on Vulkan: in a layout that mixes a
  vertex buffer whose offsets are all 0 with one that gives offsets, the first is packed as on the other backends; a buffer with no
  usage flag binds as a vertex buffer; the renderer's device keeps its pipeline cache in `<cache dir>/shaders/vulkan-pipelines.bin`;
  GPU timer results are no longer lost on MoltenVK; and the timers' query pools go only once the frames that write them finished.
- On Windows the window no longer owns a D3D11 device (M77-P9f): sokol_app runs without a graphics API there, and the platform makes the
  D3D11 device and the window's DXGI flip-model swapchain itself, resizes it and presents it (vsync interval, tearing when vsync is off
  and the display allows it, the same frame latency as before), so the D3D12 and Vulkan backends can present on the same window. A lost
  device is logged once with its reason and what to do. HDR output, the editor's frame readback, fullscreen and HiDPI work as before (with `AppDesc::highDpi=false` the process is now DPI-unaware and Windows scales the window, as sokol_app does without D3D11).
- A game chooses its GPU backend (M77-P9a): `"render": {"backend": "auto" | "d3d11" | "d3d12" | "vulkan" | "metal" | "gl" | "gles3" |
  "webgl2"}` in `factoria.json` (a wrong name fails with `/render/backend`, the valid names and a did-you-mean; one the platform or binary
  lacks warns and uses `auto`, which is still the sokol backend of the build), the `FA_GPU_BACKEND` environment variable and
  `EngineConfig::gpuBackend` override it. Headless runs use D3D12 or Vulkan; a window falls back to `auto` with one warning until their
  swapchains land. The startup report names the device's backend and the asked one when it differs (docs/RENDERING.md, "Choosing the GPU backend").
- The D3D12 backend presents into a window (M77-P9c): `create_swapchain` makes a flip-model DXGI swapchain on the HWND of
  `SwapchainDesc::nativeWindow` (one buffer more than the frames in flight, a frame-latency wait in `acquire_swapchain`, tearing when vsync is
  off and the system allows it), passes made with `PassDesc::for_swapchain` draw into the frame's back buffer, `present()` shows it and
  `resize_swapchain` remakes the buffers once the GPU is done with them. `swapchain_format_supported` answers Default (SDR), Rgba16F
  (scRGB) and Rgb10A2 (HDR10), whose colour space `create_swapchain` checks with the display. The renderer resizes the device's swapchain
  when the framebuffer changes size (the renderer does not hand D3D12 its window yet, so it draws offscreen there for now), and D3D12's
  `make_pipeline` resolves packed vertex offsets with sokol's per-buffer rule. A renderer case draws the 2D and 3D test scenes on D3D12
  WARP against the sokol backend (`FA_D3D12_WARP=1` and `FA_D3D12_DEBUG=1` pick WARP and the debug layer for `make_device`).
- The D3D12 backend runs lists on three queues (M77-P10b): `begin_commands(label, QueueKind::Compute)` records for a COMPUTE queue and
  `QueueKind::Transfer` for a COPY queue, each with its own fence; `submit_token` returns the list's token, `wait_list` and `wait_queue` make
  a queue wait for another's, and `QueueHandoff` moves a buffer or image between queues (a list that uses what its queue does not own is
  dropped with an error that names the handoff to add). `features()` now says `asyncCompute`, `multiThreadRecording` (lists record on any
  thread) and `bindless` (every live texture view has a slot of the bindless table, `bindless_index`). Compute lists' timed scopes are
  measured, copy lists' are ignored, and a list kept open no longer lets the timer ring reuse its slot. On binding tier 1 a writable view
  that several stages see counts once against the limit. `D3d12Options::asyncQueues = false` keeps one queue.
- The renderer uses the queues and threads of D3D12 and Vulkan (M77-P10d): the shadow views (sun cascades, spot and point light tiles)
  are recorded on job threads into up to four command lists submitted in a fixed order (`render.shadow_record`), and the depth-pyramid
  reduce of GPU occlusion runs on the compute queue, handing the prepass and its cells buffer over and back, with the graphics queue
  waiting at the first pass that reads the prepass. The picture and the draws are the same as on one thread and one queue (a test
  compares them on Vulkan and D3D12 WARP); the sokol backends are untouched. `"render": {"asyncCompute": false}` and
  `{"multiThreadRecording": false}` in `factoria.json` (`RendererDesc::asyncCompute`, `multiThreadRecording`) turn each off, and the
  startup report says whether each is in use (docs/RENDERING.md, "Async compute and multi-thread recording"). GPU occlusion culling
  (the depth pyramid) now runs on D3D12 and Vulkan devices with compute shaders, and the light data upload names its rectangle
  (RecordingDevice reported an empty one).
- The D3D12 backend keeps its PSOs on disk (M77-P7b): an `ID3D12PipelineLibrary` in `<cache dir>/shaders/d3d12-pipelines.bin`, loaded
  when the device starts and written atomically when it ends or on `save_pipeline_cache()`; a file from another GPU or driver, or a damaged
  one, is thrown away with one warning (deleting the file clears the cache). The shader cache report has a `pipelineCache` object. The
  backend also answers `storage_image_loadable` from the GPU's typed UAV loads, refuses a view of the pass's own attachment in
  `set_bindings`, checks the writable-view limit of binding tier 1, and an asynchronous read that finds no free slot on a lost device says
  the device was lost. A renderer on D3D12 (`RendererDesc::backend`, M77-P9b) uses the file.
- The renderer draws through the device `RendererDesc::backend` names (`GpuBackend`, M77-P9b): `Default` is the platform's sokol
  backend as before; `D3d12` (Windows) and `Vulkan` draw offscreen (`headless`) on the engine's own backends, and `Recording` on
  none (tests). Asked for a window they fail `init()` with an error that says to draw offscreen or pick the sokol backend (their
  swapchains come later); a backend the build lacks names the one it has. Each built-in shader is taken in the device's dialect
  (`gpu::generated_shader_desc(device, ...)`), `gpu_info().backend` names the device's backend ("d3d12", "vulkan"), the window goes
  through a swapchain interface of the device (create, acquire, present, resize, the HDR format question), and
  `UiPainter::create(Renderer&, error)` paints where the renderer draws (its device, or on the sokol backend a device of its own over
  the same context). `FA_RENDER_VULKAN` (`AUTO`, worked out at every configure: ON on Windows; on Linux, Android and macOS only in a
  build with the tests, so the suite draws on lavapipe and MoltenVK; OFF on iOS and the web) compiles the SPIR-V of the built-in
  shaders (about 3.4 MB) into `fa_render`: the Windows player now carries it, with D3D11, D3D12 and Vulkan in one binary, and its
  size budget grew with it; the Linux, Android, Apple and web players do not. A test draws a 2D and a 3D frame on Vulkan and on the
  sokol backend and compares them. The renderer now gives every pipeline explicit vertex offsets (the
  per-buffer packing of sokol_gfx, `gpu::resolve_vertex_offsets`), says `vertexBuffer` on its mesh and UI vertex buffers, and binds
  only the slots the lean 2D program declares, which the stricter backends ask for.
- The editor draws its interface through a public 2D painter of the renderer, `fa::render::UiPainter` (`fa/render/ui_painter.h`): triangle lists
  with a texture and a scissor rectangle per command, pictures made by `make_texture`, the game's picture from `Renderer::game_target_texture()`
  (it replaces `game_target_image_id()` / `game_target_view_id()`). The editor no longer calls sokol_gfx or sokol_imgui, and the screenshots
  of the autotest look the same. MetalFX orders its work against the frame through `gpu::Device::native_metal()`.
- What the graphics API says about the GPU (`GpuInfo`: name, vendor, driver, unified memory, software) is `Renderer::gpu_info()`, asked of the
  renderer's own device; the free function `fa::render::query_gpu_info()` is gone (M77-P5d2). The renderer's own read-backs (captures, HDR
  and probe reads) go through the private GPU interface, `gpu::Device`.
- Shaders for the Vulkan backend (M77): `tools/shaders/compile_shaders.sh` also asks sokol-shdc for `spirv_vk`, so every built-in
  shader (the compute Hi-Z one too) has its SPIR-V in the generated headers, behind `#if defined(SOKOL_VULKAN) ||
  defined(FA_SHADERS_SPIRV)`, which only a build that can run the renderer on Vulkan sets (`FA_RENDER_VULKAN`,
  above); the headers grow by a quarter, 75 MB to 95 MB in the repository. The pinned sokol-shdc already supports it, so the pin
  does not move.
- The engine's own Vulkan backend draws and computes (M77; the renderer runs on it offscreen, above): shaders from
  sokol-shdc's SPIR-V with its descriptor sets (uniform blocks in set 0, views and samplers in set 1, the bindless table in set 2),
  cached set layouts, pipeline layouts, render passes and pipelines over a `VkPipelineCache`, render and compute passes with
  load/store/clear and MSAA resolve, viewports, scissors, bindings, uniforms, indexed and instanced draws with a base vertex, and
  dispatches, with automatic barriers and errors that name what is wrong. On it a custom material takes its `spirv_vk` twin, whose
  base64 stages `render::make_shader` decodes. GPU timers and asynchronous reads come next (until then they say so), passes into
  the window after that. docs/design/ARCHITECTURE_RENDERING_VULKAN.md.
- The Vulkan backend measures GPU time (timestamp query pools, the D3D12 backend's timed frames and scopes) and reads buffers and
  image regions in the background (32 generation-checked tickets), answers `storage_image_loadable` per format, and passes the
  validation layer's synchronization validation: a read in a second stage after a write waits for the write, descriptor sets are
  bound in order, the Vulkan 1.0 barriers keep the storage and sampled bits above bit 31, and a texture and a storage image view of
  one subresource in one dispatch is a teaching error. Its tests run on Linux CI on Mesa's lavapipe with the validation layers
  (`FA_VULKAN_REQUIRE=1` makes a skip fail) (M77-P8b1).
- The Vulkan backend keeps its pipeline cache on disk (`VulkanOptions::pipelineCacheFile`): the file carries the GPU, driver
  and cache UUID it was made with and a SHA-256 of its data, a foreign or damaged file is thrown away with one warning, and the
  save is atomic and keeps the old file when it cannot write (a file open in another process on Windows). Its descriptor pools
  chain up to `frameDescriptorPools` a frame instead of refusing a full one; a destroyed shader's pipelines and layouts, and a
  destroyed view's framebuffers, leave the caches (framebuffers are now cached across lists); new uniforms bind set 0 alone.
  `make_shader` refuses SPIR-V whose instruction word counts do not add up, a point list needs a vertex stage that writes
  `gl_PointSize`, a storage buffer view stops at `maxStorageBufferRange`, BGRA8 is never a loadable storage image, the Windows
  loader takes an absolute `loaderPath` written with '/', and the notices carry the Vulkan headers' Apache-2.0 and MIT texts
  in full (M77-P8b2).
- The Vulkan backend runs lists on three queues (M77-P10c): graphics, async compute (a compute-only family, else a second
  graphics-family queue) and transfer, each with its own timeline semaphore and command pools, through
  `begin_commands(label, queue)`, `submit_token`, `wait_list` and `wait_queue`; a GPU without them runs every list on the
  graphics queue. A resource handed to a queue of another family moves by a queue family ownership transfer (images stay
  `EXCLUSIVE`, which keeps their compression), and using a resource of another queue, or one whose handoff token the list did
  not wait for, is reported. Lists record on several threads (`multiThreadRecording`), every texture view gets a bindless slot
  (`bindless_index`), timed scopes off the graphics queue are ignored, and a pipeline destroyed while an open list binds it is
  no longer freed by `wait_idle` before that list is submitted.
- Custom materials: a twin can have a `spirv_vk` dialect, `<material>.json.spirv_vk.shader`: each stage (`vs`/`fs`, or `cs`) is the SPIR-V in
  base64 (`"binary": "base64"`), and the reflection keeps the descriptor set and binding numbers of sokol-shdc as integers
  (`spirv_set0_binding_n` for uniform blocks, `spirv_set1_binding_n` for views and samplers). It is not compiled by default;
  `ShaderCompileOptions::dialects` asks for it, and an export (`ExportOptions::vulkan`) adds it only for windows, linux and android.
  The material inspector reads the same fields as before.

### Export

- **Game packs can hold GDeflate (M77, first part of DirectStorage):** `game.pak` blocks can now be compressed with `gdeflate`, the Deflate64 stream in 64 KiB tiles that DirectStorage 1.1 decompresses on the GPU, written for the engine (`Codec::GDeflate`, levels 1 to 12; the decoder reads it on the CPU, about the ratio of zlib, somewhat slower than zstd and about half as fast as lz4). Choose it with `export.pack.codecs` per extension or with the new `export.pack.codec` (`"auto"`, `"lz4"`, `"zstd"`, `"gdeflate"`; `"auto"` keeps today's choice). `export.pack.directStorage` (default false, read and saved now) makes a Windows export with `"auto"` pack as `gdeflate`; the DirectStorage reader is the next entry. The pack stays format version 2, but an older FactorIA cannot read a pack with gdeflate files. docs/design/ARCHITECTURE_FILES.md, "GDeflate".
- **DirectStorage reads game.pak on Windows (M77):** on 64-bit Windows, the blocks of gdeflate files in `game.pak` are read through
  Microsoft's DirectStorage when `dstorage.dll` and `dstoragecore.dll` lie next to the game (loaded at run time, 1.1 or newer; the engine
  declares the interfaces it calls, no SDK is needed to build it). Whole blocks decompress straight into the caller's buffer, in batches
  on one queue; nothing changes for `fs::read_file`, `IoQueue` or the streaming readers. With memory destinations DirectStorage
  decompresses on its own CPU worker threads; decompression on the GPU comes with GPU destinations. Any failure (no DLLs, a runtime
  older than 1.1, a failed request, a raw block with a wrong checksum) logs once and falls back to the CPU decoder, never a crash;
  `FA_DIRECTSTORAGE=0` turns it off. New `factoria setup directstorage` downloads the NuGet package Microsoft.Direct3D.DirectStorage
  1.3.0 (pinned SHA-256) and keeps the two x64 DLLs; a Windows `--release` export with `export.pack.directStorage` copies them next
  to the executable, or warns to run that command and still succeeds. The Windows CI job checks the GDeflate test vectors against
  DirectStorage's own codec both ways. docs/design/ARCHITECTURE_FILES.md, "DirectStorage".
- DirectStorage reads of game.pak no longer wait for ever when every one of the 32 read slots has been taken out of use (Windows could not make an event): the read fails with an error that says what to do, and the pack is read on the CPU.
- **DirectStorage writes into D3D12 buffers and textures (M77):** the D3D12 backend's `read_pack_to_buffer` and `read_pack_to_image`
  read a range of a `game.pak` file into a buffer or a texture region and return a ticket that is polled. A gdeflate file goes through
  DirectStorage on a queue tied to the device, so GDeflate is decompressed on the GPU where the GPU can; DirectStorage writes in the
  COMMON state, which the backend's state tracking follows. A pack in memory, another codec, no DLLs, a texture region whose rows do not
  fill whole blocks or a failed request is decoded on the CPU and uploaded instead, with one warning. The game's renderer does not use
  them yet. A lost device ends a read with an error that gives the removal reason, a block-compressed mip smaller than 4x4 is
  read whole, and the device closes a pack's file once the pack and its reads are gone. The reader's waits no longer hold a lock, are bounded (a warning after 30 s, the requests cancelled after 10 minutes) and are
  never woken by another read; a read whose status says complete while its event does not come is checked a second later
  with a probe event that ends the wait once DirectStorage is past the read, instead of being cancelled and stopping the process. The 2045-block limit holds only for reads
  DirectStorage really takes (a large read that falls back to the CPU is read whole), and a partial block that finds no
  upload memory is an error in `errors()` that names the bytes not written; `FA_DIRECTSTORAGE_VERIFY=1` also checks the stored checksums of compressed blocks (a debugging aid).
  `factoria setup directstorage` keeps NOTICES.txt next to the license; `setup.status` reports it `unsupported` off Windows (no longer
  missing, and `factoria setup` alone skips it), and the editor's setup window has an Install button for it on Windows.

## 0.36.0

Temporal antialiasing and open upscalers (M76): the renderer writes a velocity image (meshes, skins, terrain, foliage, impostors, 2D sprites, shapes, tiles and quads, with a reactive mask for particles and additive items) and uses it for temporal antialiasing (`PostProcess.temporalAAEnabled`, Halton jitter, a texture LOD bias) and per-object motion blur; `render.upscaler` draws the picture below the window's size and brings it up with a spatial upscaler (edge-adaptive filter and sharpen), a temporal upscaler, or Apple's MetalFX; dynamic resolution moves the render scale to hold a frame time; graphics presets (Low to Ultra, `graphics.preset`, `graphics.detect` with a benchmark) cap the costly features, and the menu kit and the editor have a Graphics page for all of it. docs/UPSCALING.md explains each part. The entries below list them.

### Rendering

- MetalFX (`render.upscaler` mode `metalfx`, Apple GPUs): the reactive mask of the temporal upscaler (`ParticleEmitter.reactive`, `Sprite.reactive`,
  every additive item) is now handed to MetalFX's temporal scaler too (macOS 14.4 / iOS 17.4 or later), so a bright additive particle or sprite no
  longer blends with the history behind it; an older OS draws as before. The tests also cover a MetalFX command buffer that fails (the queue does not
  stall, the renderer falls back with one warning) on any Metal GPU.

- `window.renderScale` now goes from 0.33 to 1 (it was 0.5 to 1) and the game is drawn smaller but the HUD and the UI (screen-space
  Text, Sprite, Shape2D, UI widgets) are drawn after the scale-up at the full window size, so their text stays sharp. Only when the post
  stack would not change them anyway: a bloom with `bloomScreenSpace` true (the default) and no final pass makes the HUD glow, so
  then it stays in the smaller picture, scaled up with it, as before; set `bloomScreenSpace` to false (or use no bloom) for the
  sharp HUD. The picture
  the engine returns for `game.screenshot` and the like is the full size picture with the HUD (before, it had the scaled size and
  a blurred HUD); `game.renderStats().width` and `height` stay the size the game is drawn at. The scale-up keeps hard pixel edges
  with `PixelPerfect` scaling. Scale 1 is unchanged (no extra image, the same pixels). With a camera colour filter the filter is
  applied after the HUD. The CLI's `--render-scale` and the screenshot `scale` option still mean "an image that many times the size".
  Internally the scale-up is a frame-graph stage (`src/render_upscale.h`) that the temporal antialiasing and the open upscalers
  of M76 plug into; docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)".

- Upscale stage polish (M76): the decision to draw the HUD at the output size looks at the same cameras the frame draws (a camera whose
  viewport has no pixel does not count) and at whether the post program can run, the output depth image is made only for a frame that has
  items to draw, a frame without a HUD no longer declares an empty game-HUD pass, the output images are freed when the stage turns off
  by itself (the render scale went back to 1), and a temporal upscaler whose history does not fit the memory budget draws the spatial
  upscaler from the first frame (one log line) without turning off the `TemporalAA` of the cameras. `Engine::hold_render_scale` (the CLI's
  `--render-scale`, the video recorder) is a size again after the player set `window.renderScale`: the quality no longer multiplies into
  it. A temporal or MetalFX mode at `native` quality keeps the stage flag on so that a frame with several cameras (which draws `spatial`)
  gets its sharpen.

- Polish: an Occluder whose mesh could not be read is tried again after 600 frames (it was never read again until the game restarted), and the error for an unknown mesh name no longer says "collider mesh" when an Occluder asked for it.

### Per-object motion blur (M76-P1e)

- `PostProcess.motionBlurMode` (`"object"`, the default, or `"camera"`) and `motionBlurMaxRadius` (design pixels, 1 to 64, default 24). In
  `object` mode the motion blur reads the velocity image of the depth prepass: a moving object blurs along its own motion and a still one
  next to it stays sharp, with McGuire's tile-max / neighbour-max / depth-aware gather (passes `motion-velocity`, `motion-tile-x`,
  `motion-tile-y`, `motion-blur`), the taps bounded by `motionBlurSamples`; where no object wrote a velocity (the sky) it falls back to the
  camera's own motion from the depth. It runs after the temporal antialiasing and reads the unjittered motion. `camera` mode is the old
  blur, bit for bit, and the effect off changes nothing. `object` is the default: a project that already had `motionBlur` on now blurs moving objects and pays the velocity attachment of the prepass and 3 more passes; set `motionBlurMode` to `camera` for the old look and cost. A project with the effect off (the default) is not changed;
  docs/rendering/RENDERING_POSTPROCESS.md, "Depth of field and motion blur".

### Temporal antialiasing and open upscalers: the shared API (M76)

- Texture mip bias for the temporal passes: while the temporal upscaler (`temporal`, `metalfx`) or the temporal antialiasing accumulates
  jittered frames, the scene's textures are read at the level of `log2(render width / output width)` plus an offset, so they keep the detail
  of the output size (what FSR 2, DLSS and XeSS ask of a game). New field `PostProcess.temporalAAMipBias` (-2..0, default -0.5; at scale 1
  with the antialiasing alone it is the whole bias; 0 gives the pure resolution ratio). It reaches meshes, terrain layers, impostors,
  the material graph's `texture`, `texture.normal` and `triplanar` nodes and `fa_base_sample()` of full shaders; custom shaders read
  `fa_mip_bias` (a `float`, mesh and full shaders only). Sprites, tiles, text, the UI, the shadow maps and the post passes take none, and
  every frame without a jittered camera is the same picture bit for bit as before. The default -0.5 applies to every camera that has
  `temporalAAEnabled` on (also at render scale 1, where it used to read the textures at their plain level), and to the temporal upscaler's
  camera whether or not its stack has the effect; set `temporalAAMipBias` to 0 to keep the previous level at scale 1. The bias follows the dynamic resolution step by step.
  docs/UPSCALING.md, "Texture mip bias".
- New effect `PostEffect::TemporalAA` (`PostProcess.temporalAAEnabled`, `temporalAAFeedback`, `temporalAASharpen`,
  `temporalAAVarianceGamma`, `temporalAAReactiveScale`), between the exposure and the depth of field. It is drawn now (see
  "Temporal antialiasing" below); `render.supports` says `supported` on every backend.
- New engine-wide upscaler settings: `"render": {"upscaler": {mode, quality, sharpness}}` in `factoria.json`, the command
  `render.upscaler` and `window.upscaler` in scripts (docs/UPSCALING.md). `effectiveMode` says what draws: `stretch`, `spatial` and
  `temporal`, and `metalfx` on Apple GPUs (M76-P5b); `auto` draws as the best that exists, and `temporal` draws as `spatial`
  where it cannot run.
- The temporal upscaler is drawn (M76-P4): `render.upscaler` / `window.upscaler` / `factoria.json` with mode `temporal` (or `auto`)
  draw the game at the quality's size (`quality` 1/1.5, 1/1.7, 1/2 or 1/3 of the window, times `window.renderScale`, at least 0.25) with
  the camera jittered over `ceil(8 * (output / render)^2)` phases (at most 128) and resolve it into a history at the window's size with
  the temporal antialiasing's own resolve (RGBA16F, RGBA8 on a GPU without float targets), then sharpen it (`sharpness`). The HUD stays
  sharp at the window's size. `effectiveMode` and `render.supports` `temporalUpscaler` say it is drawn; a game with `PixelPerfect`
  draws as `stretch`; a frame with more than one camera, or a history the GPU cannot make, draws as `spatial` (the spatial upscaler, and `effectiveMode` says so); native quality draws nothing extra. The camera's own `TemporalAA` pass is
  skipped while it runs (its fields still tune it). It resolves after the post stack, so the post effects see a jittered image; 2D
  sprites and tiles have a velocity, particles a reactive mask (see the motion vectors below); the textures are not biased to a finer mip (not done: sokol samplers have no bias).
  The objects' motion vectors (M76-P1a) feed its reprojection (it asks the prepass for them). Off (`stretch`) is free: no pass, no
  image, no jitter, the same pixels. `UpscalerCaps` gets `temporal` (the TAA shaders compiled) and `multiCamera` (the frame has no single
  full-window camera); `kJitterPhasesMax` is 128 (was 16); `docs/UPSCALING.md`, "The temporal upscaler".
- MetalFX is drawn (M76-P5b): on the Metal backend (macOS 13 or iOS 16 or later, a GPU with the MetalFX scalers; not the iOS simulator),
  `render.upscaler` / `window.upscaler` / `factoria.json` with mode `metalfx` (and `auto`, which now prefers it) hand the upscale to
  Apple's MetalFX. Its temporal scaler takes the jittered picture at the render size (the same phases and quality sizes as `temporal`),
  a 0..1 depth and a motion image that a small pass makes from the prepass and the velocity image (where no object wrote a velocity
  the camera's own movement is reprojected, as the temporal upscaler does), and keeps its history at the window's size; the spatial
  scaler draws a frame the temporal one cannot take. The history resets on a camera cut, another scene, a floating-origin shift, a change
  of the render size or quality and a new scaler. A frame with more than one camera draws `spatial`, as for `temporal`. If MetalFX cannot be
  made or fails in a frame, the renderer drops to `temporal` (then `spatial`) for the rest of the run with one warning, and
  `effectiveMode` says it. `render.supports` `metalfx` is `supported` where it is available, with the reason where not;
  `render.upscaler` reports `metalfx` also for a headless project on an Apple build where it is available. `sharpness` does not apply to it.
  The CI machines have no MetalFX (the macOS VM has a paravirtual GPU): its tests skip there with a message. Docs/UPSCALING.md, "MetalFX".
- Fix: the motion vectors the temporal upscaler reprojects with (M76-P1a) were asked for after the culling had decided whether the draws
  keep their previous models, so with the upscaler alone (no motion blur, no TemporalAA effect) the image was never made and every pixel
  reprojected from the camera. It is asked for before, and moving objects now reproject with their own motion.
- Fixes in the temporal resolve (`taa_shared.glsl`, antialiasing too): a NaN in the picture or in the history is dropped and never stays in
  the history for ever (on a GPU that keeps NaN through `max`), and the depth rejection no longer discards the history of the sky when the
  camera turns fast.
- New commands `graphics.preset` and `graphics.detect` (Low, Medium, High, Ultra, Custom): see "Graphics presets" below.
- New `render.supports` rows `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution`
  (`motionVectors`, `spatialUpscaler` and `temporalUpscaler` are drawn, see below; `temporalAA` is the effect's own row, drawn; the others are planned M76).
- Temporal antialiasing is drawn: with `PostProcess.temporalAAEnabled` the camera is jittered by a sub-pixel amount every frame
  (meshes, sky and HDRI together, the HUD not) and two fragment passes at the render resolution (every backend, no compute) blend the
  frame with the camera's history, reprojected with the motion vectors when the frame has them and from the depth prepass otherwise,
  clipped to the neighbours (`temporalAAVarianceGamma`), with `temporalAAFeedback` of the history kept and `temporalAASharpen` given
  back. The history (RGBA16F, RGBA8 with a note in the log where the GPU cannot render to half floats) starts again after a cut, a
  resize or render-scale change, a floating-origin shift, a scene load or a frame the camera did not draw. CameraView, render-target and
  `camera.capture` cameras are not antialiased. Off, as by default: no pass, no image, no jitter, the same pixels (docs/UPSCALING.md).
- Motion vectors: the depth prepass can write the motion of every pixel (RG16F, `uvPrev - uvCurr` from the unjittered matrices) as a
  second attachment, for static and moving meshes, instances, terrain, foliage and impostors (a floating-origin shift and a camera cut
  are no motion). Skinned meshes (any skin up to the 64 joints of the engine: the pose of the frame before is an RGBA32F image the vertex stage
  fetches, the current one stays in its uniform block) and materials with a custom `vertex()` (run again with the previous model and the previous frame's game time) write it
  too; sprites, shapes, tiles and text come with the next entry, and particles are marked reactive instead. It is written only when something asks (the new debug view, the temporal antialiasing); otherwise frames are bit-identical. New debug view
  `render.debug_view {"view":"motionVectors"}` (`FA_RENDER_DEBUG_VIEW=motionVectors`): hue is the direction, brightness the length,
  grey where nothing wrote a vector. docs/design/ARCHITECTURE_RENDERING_TEMPORAL.md, "Who writes the velocity (M76-P1a)".
- Motion vectors and a reactive mask for the 2D quads (M76-P1d). With a temporal effect on (or the debug view), the sprites, shapes, tiles and
  text of the world that are alpha-tested cutouts (coverage of one half or more) write their translation since the frame before into the
  velocity image, in a 2D scene too (no prepass: an image of their own, the depth then is the camera's far plane, which is right for an
  orthographic camera) and behind meshes in a perspective one (tested against the prepass's depth). Blended and additive quads never overwrite
  a velocity: a new reactive mask (R8, the MAX of the values) marks them, and the temporal resolve and the temporal upscaler trust the
  current frame where it is set, scaled by `PostProcess.temporalAAReactiveScale`. New fields `ParticleEmitter.reactive` (0..1, default 1; an
  additive or blended particle or trail is marked; 0 opts out) and `Sprite.reactive` (-1..1, default -1 = by blend: an additive sprite counts as 1; 0 opts out, an additive sprite too; a sprite
  with a value above 0 writes the mask instead of a vector). A bright additive square moving over a busy background is six times closer to the
  truth with the mask (`quad_motion_tests.cpp`); the mask holds the pixels a particle covers now and does not clear the trail it left.
  The vectors follow the entity's rotation and scale per corner (a sprite that turns has tangential vectors), a sprite
  material of its own writes the mask but no velocity, and a capture with `taa.on` false builds neither pass.
  Limitations: a change of `size` or `region` is not followed, the whole box of a `Shape2D`, no velocity for particles or instanced sprites, and a batch with a clip rectangle is skipped. The passes rasterise with the jittered matrix of the colour, so they cover the colour's pixels. A tilemap moved by its
  Transform has its own velocity. With the temporal effects off
  there is no pass and the frames are bit-identical. The motion vectors debug view shows the new writers. The tests of the two sentinel paths
  of the previous joint palettes (a GPU with no RGBA32F sampling, more rows than the image holds) are in `velocity_tests.cpp`. Every camera job of a frame has its own previous-palette image now (a second camera used to overwrite the first one's).
  docs/design/ARCHITECTURE_RENDERING_TEMPORAL.md, "Who writes the velocity".
- The spatial upscaler (`render.upscaler {"mode":"spatial"}`): the game drawn at a lower resolution is brought to the window's size
  by an edge-adaptive upsample (12 texels, a kernel narrow across an edge and long along it, clamped so it never rings) and a
  contrast-adaptive sharpen controlled by `sharpness`, two fragment passes on every backend (no compute). A hard diagonal or a thin
  stroke is several times narrower than with the plain stretch (measured on a test pattern). In a linear HDR scene the filters work on a reversible
  tonemap so bright values do not ring. Pixel-perfect games keep the nearest scaling (`effectiveMode` says `stretch`); `stretch`
  (the default) is bit-identical to before, with no extra pass.
- The render scale is now `window.renderScale` times the quality's scale (`performance` = 0.5 ...), never below 0.25, decided in one
  place for `window.renderScale`, `window.upscaler`, `render.upscaler` and the project's start; before, the quality did not change
  the size. At native quality the spatial mode with `sharpness` above 0 adds one sharpen pass at the window's size (set `sharpness`
  to 0 for none). `game.render_stats` `width`, `height` and `renderScale` are the size and scale really drawn, quality included.
- Renderer: the projection of the drawn picture can be jittered (Halton 2,3, 8 phases) and keeps the previous frame's
  jittered matrices; culling, picking and every query use the unjittered ones. Nothing jitters while no effect needs it,
  so frames are unchanged. The velocity image contract is in docs/design/ARCHITECTURE_RENDERING_TEMPORAL.md.

### Graphics page of the menu kit and the editor's Graphics window (M76)

- Menu kit: the Graphics tab of the options panel has a second page ("Preset and upscaling") with a Preset row (Auto, Low, Medium,
  High, Ultra, Custom), an Upscaling row (Auto and each mode this GPU draws; the others greyed out with the reason), the upscaling
  quality, the render scale (0.33 to 1) and the sharpness (only where the mode uses it). Auto runs `game.graphics.detect()` once and
  keeps its pick. A preset drives the tab's "quality" row of screen effects, so the two do not fight. Everything is saved in
  `settings.graphics` (`preset`, `detected`, `upscaler`, `renderScale`; an old save loads as before) and applied when a scene
  starts. docs/MENUS.md (the Graphics tab); new texts in the kit's `en`, `es` and `ar` tables; `tests/graphics.test.js` covers it.
- Editor: View > Graphics edits `render.graphicsPreset` and `render.upscaler` (mode, quality, sharpness) of `factoria.json` with
  Save and Revert, checked by the engine's own parsers (a wrong value is named with its JSON pointer and a "did you mean"); only
  those two keys of the file are written. There is no preview of a preset or mode in the editor: press Play after Save.

### The display's refresh rate (M76)

- Dynamic resolution's "one display refresh" (`targetMs` 0, the menu kit's "Display refresh") now follows the display the window is
  on: 8.3 ms on a 120 Hz display, 6.9 ms on a 144 Hz one (it was 60 Hz everywhere). The rate comes from the OS (macOS and iOS
  `maximumFramesPerSecond`, the Windows display mode, the Linux XRandR mode, Android `Display.getRefreshRate()`), asked again every
  2 s so a window moved to another monitor follows it. Where the OS does not say (the web) it is estimated from the median time
  between presented frames while vsync paces them; with vsync off, a frame cap, on-demand rendering or no window that fallback is
  60 Hz. `render.dynamic_resolution` and
  `window.dynamicResolution` report `refreshHz` and `refreshSource` (`"platform"`, `"estimated"`, `"default"`).
  docs/UPSCALING.md, "The display's refresh rate".
- `window.monitors()` entries have `refreshHz`, each monitor's rate as the OS reports it (0 where it does not say), and the
  platform layer has `app_display_refresh_hz()` and `MonitorInfo::refreshHz` (fa/platform/app.h).

### Graphics presets (M76)

- `graphics.preset {"name"}` applies Low, Medium, High or Ultra, and `custom` takes the layer away; with no arguments it reads. A
  preset is a set of limits the renderer applies over what the scene asks for (post effects, shadows, volumetric fog, level of detail,
  foliage, terrain, 2D lighting, realtime GI) and the upscaler; nothing is written into the scene or the project, so `custom` and
  `ultra` give the game's own look back bit for bit. Knobs a backend cannot draw are capped, and the answer lists each with its reason.
  The per-preset table is in docs/UPSCALING.md, "Graphics presets".
- `graphics.detect` reads the GPU (backend, adapter, vendor, memory) and runs a benchmark (a fixed scene: a few hundred milliseconds
  on a good GPU, seconds on a slow one; the timed pictures stop after four seconds; never on a software renderer or on the web), and
  suggests a preset with the reason. It changes nothing, draws in the colour space the game's targets are in, and `game.graphics.detect()`
  leaves out the machine-dependent times (`benchmarkMs`, `benchmark.frameMs`, `benchmark.totalMs`) that the command gives to tools.
- New command `project.graphics` (CLI, MCP) reads and writes `render.graphicsPreset`, `render.upscaler` and `render.dynamicResolution`
  in `factoria.json`, with the checks of the project loader and the editor's Graphics window (which now shares its code).
- New script API `game.graphics` (`preset(name?)`, `detect()`) with typings, and the project key `"render": {"graphicsPreset"}` with
  validation and a "did you mean".

### Dynamic resolution (M76)

- The render scale can follow the frame time so a game holds a target. Off by default (the picture and the frame are those of a build
  without it, bit for bit). Settings: `"render": {"dynamicResolution": {enabled, targetMs, minScale, maxScale}}` in `factoria.json`, the
  command `render.dynamic_resolution` and `window.dynamicResolution` in scripts, with errors that name the JSON pointer and the valid
  range. The controller measures the GPU time where the backend has timer queries (Direct3D 11, OpenGL) and the time between frames
  elsewhere, smooths it, and moves a factor between `minScale` and `maxScale` on a grid of 32 steps with a dead band, hold times and at
  most two changes a second; its factor multiplies into the render scale in one place (`apply_render_scale`). A step makes the render
  targets again (rate-limited for that reason); the temporal upscaler's history survives the steps. `game.render_stats` and
  `window.upscaler` report `dynamicScale` and `frameMs` (read-only), and `render.supports` `dynamicResolution` is drawn. No preset turns it
  on. docs/UPSCALING.md, "Dynamic resolution".
- The menu kit's Graphics page has a Dynamic resolution row (Off, 30 fps, 60 fps, Display refresh; saved as
  `settings.graphics.dynamicResolution`, `null` in an older save), and the editor's Graphics window edits `render.dynamicResolution`.
