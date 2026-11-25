# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.36](changelog/0.36.md), [0.35](changelog/0.35.md), [0.34](changelog/0.34.md), [0.33](changelog/0.33.md), [0.32](changelog/0.32.md), [0.31](changelog/0.31.md), [0.30](changelog/0.30.md), [0.29](changelog/0.29.md), [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- **Vendor SDKs for upscaling, frame generation and low latency (M78):** `factoria setup streamline`, `setup xess` and `setup fidelityfx`
  download the redistributable x64 DLLs of NVIDIA Streamline (DLSS, DLSS Frame Generation, Reflex), Intel XeSS (with XeLL) and the
  AMD FidelityFX SDK (FSR) when you ask, pinned by SHA-256, into `~/.factoria/tools/<id>/<version>/` (older versions are removed;
  nothing of them is committed to the repository or bundled). Each shows the vendor's license first and installs only after you accept
  it (`--accept-licenses`, the terminal's `[y/N]`, the editor's license dialog; without it `setup.install` fails with
  `license_required`). A Windows export copies the installed SDKs the project can use next to the game, with their license texts in
  `licenses/<id>/`, as the new `export.pack.vendorSdks` says (`"auto"` by default, `"none"`, or a list of ids; a listed SDK that is
  not installed fails the export naming `factoria setup <id>`). The export's next steps repeat NVIDIA's obligations (notify NVIDIA before
  a commercial release, credits). EXPORTING_SETUP.md, "Vendor SDK licences".

## 0.37.0

Modern GPU backends (M77): the engine has its own D3D12 and Vulkan devices next to the sokol ones. A game picks its backend with `render.backend` (`auto`, `d3d11`, `d3d12`, `vulkan`, `metal`, `gl`, `gles3`), `FA_GPU_BACKEND` or the `graphics.backend` command, and the game window draws on D3D12 (Windows) and Vulkan (Windows, Linux, Android) with a fallback to the platform's backend in the same process when the asked one cannot start; Linux and Android also ship a Vulkan player that hands the game to the OpenGL player when Vulkan is missing. Both backends run graphics, async compute and copy queues, record the shadow views on several threads, keep their pipeline caches on disk and measure GPU time; the shader tool emits SPIR-V for Vulkan, and on Windows DirectStorage reads GDeflate blocks of `game.pak` straight into D3D12 buffers and textures. The entries below list them.

- The test suites no longer leave temporary project folders behind in the temp folder (the render tests' project folder, the menu kit,
  tool catalog, menu screenshot and layout check tests, the windowed runtime tests, the editor autotest's MCP config copy):
  `fs::make_temp_dir_until_exit` makes a scratch folder that is removed when the program ends.

### Rendering

- **Two players on Linux and Android (M77-P9e2):** next to the OpenGL player, `factoria_player_vulkan`
  (`libfactoria_player_vulkan.so` on Android, CMake option `FA_PLAYER_VULKAN`, on by default there) carries the engine's Vulkan
  backend and the built-in shaders' SPIR-V, and its `auto` is Vulkan. It starts first and, before the window, checks that Vulkan can
  start: where it cannot, or when the game's choice is `gl`/`gles3`, it hands the game to the OpenGL player with the marker
  `FA_GPU_FALLBACK_FROM=vulkan` and the reason (Linux: `execv` of `<exe>-gl` next to it; Android: it starts `factoria.engine.GlActivity`,
  process `:gl`, with the same two as intent extras, and finishes). The OpenGL player records them as `gpu.fallbackFrom` and
  `fallbackReason` in the startup report and never hands back. On Linux a Vulkan start that fails in the window (`EngineConfig::gpuBackendFailed`)
  reaches the player before the in-process fallback of the game window (M77-P9e1), so the OpenGL player takes over; the in-process
  fallback is the last resort when it is not there. A hand-over because the window cannot take the swapchain says so (`the window path
  is not available on this platform yet`), not that a driver update would bring Vulkan back. Linux and Android exports ship both players (`<exe>` and `<exe>-gl`; the APK's two libraries
  and GlActivity); `export.linux.vulkanPlayer` / `export.android.vulkanPlayer: false` ship the OpenGL player only, and so do
  players or prebuilt libraries without the Vulkan one. `factoria setup players` copies the Linux Vulkan player of a release that has
  it. The new command `graphics.backend` reads which backend draws, what was asked and from where, the fallback that started this
  player and the stored choice, and with `{"name"}` stores the backend for the next start in the game's save folder
  (`graphics_backend.json`), which the start reads after `FA_GPU_BACKEND` and before `factoria.json`. CI and the release measure
  both players (`linux-x64-vulkan`, `android-<abi>-vulkan`, no budget yet) and the Android emulator smoke follows the game into the
  `:gl` process when the handover happens. docs/RENDERING.md, "Two players on Linux and Android".
- The player's `log.txt` keeps the whole start when the Vulkan player hands the game to the OpenGL player: the first one starts the file and the OpenGL player appends to it (it starts a new file otherwise).
- Vulkan backend leftovers (M77 polish): a window surface that lacks the device's default 8-bit colour order (Android offers only RGBA)
  gives the swapchain the other one and the device's default colour format follows it, or fails with a hint naming
  `DeviceInit::environment.defaults.colorFormat` when pipelines made with the old default exist; `acquire_swapchain` waits 100 ms and the
  caller skips the frame (it was 10 s); a swapchain whose images could not all be made is made again at the next acquire; HDR10 sets its
  mastering metadata (`VK_EXT_hdr_metadata`); a readback of a swapchain image without transfer-source usage, or of a resource the compute
  or transfer queue owns, is a teaching error; a list of the compute or transfer queue that uses the acquired swapchain image is reported;
  a handoff of a resource its list does not use must wait for the handoff that brought it; a texture view has one bindless slot
  (`bindless_add` and `bindless_remove` are gone); `timer_poll` never waits (it asks for availability and retries on the next poll, then
  drops the frame with one warning); a framebuffer is not cached for a view destroyed meanwhile; a pipeline cache blob smaller than
  Vulkan's own header is not written, and a discarded file of another format version names both versions.
- The game window draws on D3D12 and Vulkan (M77-P9e1): with `render.backend` (or `FA_GPU_BACKEND`) on `d3d12` or `vulkan` the engine
  takes the window's native handle from the platform (`app_claim_native_window`) and the renderer makes its swapchain on it
  (`RendererDesc::nativeWindow`, `RendererDesc::vsync`); the platform then makes no swapchain of its own, since a window holds one
  (`WindowPresenter`, a state machine tested on every platform). On Windows that is the player itself; on macOS `vulkan` presents
  through MoltenVK in a build that has it (Linux and Android: see below). A backend that cannot
  start falls back to `auto` in the same process, in a window and headless alike: one warning keeps its first error, and the startup
  report names it in `gpu.backendFallback`. While D3D12 or Vulkan holds the window, HDR output says it is not available on that
  backend and the vsync is the swapchain's present mode. Also on Windows: the D3D11 presenter's resize reads only a live presenter,
  and a `ResizeBuffers` the driver refuses is warned once per size, not every frame.
- Vulkan draws the game window on Android (M77-P9e3b): the window's OpenGL ES context moves to a 1x1 pbuffer (or to no surface,
  `EGL_KHR_surfaceless_context`) and its EGL window surface goes while the Vulkan device holds the window, as on Linux; the Android
  window is no longer busy, so the Vulkan player draws a windowed game with Vulkan instead of OpenGL ES. When the game goes to the
  background the Vulkan swapchain is destroyed before the window goes, and it is made again on the new window when the game comes back
  (`app_set_native_window_listener`, `Renderer::set_native_window`); a Vulkan `VK_ERROR_SURFACE_LOST_KHR` destroys the swapchain, and
  the next frame makes it again. A Vulkan start that fails in the window falls back to OpenGL ES in the same process, with the EGL
  surface back on the window. The window-path reason (`the window path is not available on this platform yet`) is now given only by a
  Linux build whose window draws through EGL. Back from Home after a hand-over to `GlActivity`, the new launcher activity Android
  starts on top of it (`singleTask`) brings it back at once instead of probing Vulkan again (`android_gl_activity_in_task`), so a
  probe that now succeeds no longer starts a second game. Two Vulkan fixes the Android window needed: the swapchain takes the
  IDENTITY `preTransform` and SurfaceFlinger rotates the picture (with the surface's own ROTATE_90 transform a landscape game came out
  turned and squeezed on a phone), and the suboptimal answer Android's loader gives for that at every present no longer makes the
  swapchain again; the swapchain gets no debug name on Android (the handle is the loader's, and the emulator's Mesa driver aborted the
  process on it).
- Vulkan draws the game window on Linux (M77-P9e3a): with `render.backend` on `vulkan` the X11 window's OpenGL context moves to a
  1x1 pbuffer (or to no drawable where the driver has no pbuffers) and its swap stops, so the Vulkan device makes its swapchain on
  the window; when the device lets the window go the OpenGL surface comes back on it with its vsync, so a Vulkan start that fails
  after the claim falls back to OpenGL in the same process. A driver that refuses both keeps OpenGL and the warning
  says why. `EngineConfig::gpuStartFault` now runs after the window is claimed, so tests cover that release.
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
- The D3D12 backend keeps its PSOs on disk (M77-P7b): an `ID3D12PipelineLibrary` in `<cache dir>/shaders/d3d12-pipelines-<program>-<hash>.bin`
  (one file per program: the editor's, the CLI's, each exported game's, and the one the SDK's `factoria_player` shares between the
  projects it runs; the hash of the whole program name keeps names that look alike once cleaned up apart), loaded
  when the device starts and written atomically when it ends or on `save_pipeline_cache()`; a file from another GPU or driver, or a damaged
  one, is thrown away with one warning (deleting the file clears the cache); the adapter's LUID, new at every boot, is not compared. A
  library over `D3d12Options::pipelineCacheTrimBytes` (64 MiB) is rebuilt at save with only the PSOs that run used, so the file does not
  grow without bound. A save that fails (serializing, a library over 1 GiB, a reader that holds the file, a full disk) is a warning that
  names the file and keeps the old one, and waits for a reader at most three 1 ms tries instead of about a second (a scanner that holds
  the temporary file is waited for up to 8 x 20 ms: 160 ms nominal, about 250 ms with the Windows timer steps); a read-only cache file gets a hint that names the attribute to clear, and a failed
  write is tried again at the next save or the next run; temporary files a crashed save left in the folder are removed at load; a write
  is logged with its size. After a trim, PSOs the file holds that this run had not asked for yet are still loaded from it. The shader
  cache report has a `pipelineCache` object (`trimmed` counts the rebuilds). The
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
