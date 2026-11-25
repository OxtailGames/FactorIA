# Device hooks for vendor SDKs (M78-P2b)

Part of [ARCHITECTURE.md](ARCHITECTURE.md) (the device contract: [ARCHITECTURE_RENDERING_GPU.md](ARCHITECTURE_RENDERING_GPU.md);
the backends: [ARCHITECTURE_RENDERING_D3D12.md](ARCHITECTURE_RENDERING_D3D12.md),
[ARCHITECTURE_RENDERING_VULKAN.md](ARCHITECTURE_RENDERING_VULKAN.md)). How a vendor SDK takes part in making the
engine's D3D12 and Vulkan devices and their swapchains. The native handles of a finished device (`NativeDevice`,
`CommandList::begin_native`, "Native access for vendor SDKs" on the two backend pages) are enough for an upscaler that
only records commands. NVIDIA Streamline (DLSS, DLSS frame generation, Reflex), AMD FidelityFX (FSR 3.1 and its frame
generation, Anti-Lag 2) and Intel XeSS (XeSS frame generation, XeLL) need more:

- Vulkan instance and device extensions, feature bits and queues of their own, asked for before the device exists;
- a D3D12 factory, device or queue they wrap ("upgrade");
- a swapchain they make themselves (a proxy that inserts generated frames) or wrap;
- a call around every present.

The interface is private to `fa_render`: `engine/render/src/gpu/device_hooks.h`. The engine includes no vendor header
and ships no vendor binary. Objects cross the interface as `void*` (COM pointers, dispatchable Vulkan handles) or as
64-bit numbers (non-dispatchable Vulkan handles), and each comment names the Vulkan or DXGI type behind them.

## The interface

- **`DeviceHook`.** A provider implements it. `name()` is the only member it must write ("DLSS", "FSR 3 frame
  generation"); every callback has a default that does nothing. A backend calls the hooks in the order of the list, and
  only the ones still `available()`.
- **Handing hooks in.** `DeviceInit::hooks` takes them for one device. `register_device_hook` adds one to every device
  the process makes from then on: `make_device` appends the registered hooks after the caller's, once each
  (`with_registered_hooks`). The registry is thread safe. A hook registered after the renderer made its device takes
  part from the next device on.
- **Availability.** `available()` and `unavailable_reason()` say whether the device took the hook, and why not. A device
  marks every hook available when it starts, so a hook used again for a second device starts clean. The first reason
  stays.
- **Where hooks are called.**
  - D3D12 (`d3d12_device_win32.cpp`, `d3d12_swapchain_win32.cpp`) and Vulkan (`vulkan_device.cpp`,
    `vulkan_swapchain.cpp`) call each callback at the moment its comment names. The callbacks run on the thread that
    makes the device, or on the one that presents.
  - D3D11, GL, Metal and the `RecordingDevice` call none. `make_device` marks every hook unavailable on them: "the
    <backend> backend calls no device hooks: vendor SDKs that change how the device or the swapchain is made need the
    D3D12 or the Vulkan backend (render.backend in factoria.json)".
- **No hook installed.** Nothing changes. Each call site tests an empty list, and the present path calls the same
  function as before.

## Degrading, never failing

The device is always made. Whatever a hook asks that this machine lacks makes that hook unavailable, never the device.
The reason says what is missing and what to do. The device is made without anything that hook asked for, and the hook
gets no later callback. Each reason is also a warning of the device (`Device::warnings()`, the log): "gpu vulkan: device
hook 'DLSS' is unavailable: Apple M5 has no device extension VK_NVX_binary_import (update the GPU driver; ...)".

These make a hook unavailable:

- a required instance or device extension that is absent (an optional one is skipped and not reported);
- a feature bit the GPU does not have (the struct and the member's index are named);
- a feature struct that is not one, or a Vulkan 1.3 struct on a 1.2 device;
- a queue family with the flags asked for and no queue left (every family's flags and counts are listed);
- an `error` the hook sets itself (D3D12 device, either backend's swapchain).

If `vkCreateInstance` or `vkCreateDevice` fails with the hooks' additions, the engine makes it again without them, and
every hook that added something is marked unavailable. A device that the driver refuses even without the hooks fails as
it always did.

## Vulkan

In order, on the thread that makes the device:

1. **`vulkan_instance_request`.** Before `vkCreateInstance`: the instance extensions the hook needs, required and
   optional. The engine checks them against the loader, adds each once and logs nothing for an absent optional one.
2. **`vulkan_instance_created(instance, vkGetInstanceProcAddr)`.** Right after `vkCreateInstance`.
3. **`vulkan_resolve(name, device, fn)`.** For each instance function (`device` null) and each device function the
   engine loads and the loader gave. A non-null answer replaces it, and the next hook sees the replacement. This is
   Streamline's manual hooking: its interposer's `vkCreateSwapchainKHR`, `vkQueuePresentKHR`, `vkQueueSubmit`, ... take
   the place of the loader's. A function the loader does not give stays absent.
4. **`vulkan_device_request(physical device, request)`.** After the physical device is chosen. The request holds:
   - extensions, required and optional;
   - feature structs, each the bytes of a whole `Vk*Features` struct, added with `VulkanDeviceRequest::add_features`;
   - queues, as flags and a count.

   A feature struct of a type the engine chains already (`VkPhysicalDeviceFeatures2`, `Vulkan12`, `Vulkan13`, the
   portability subset) is ORed into the engine's own struct. Any other struct is appended to
   `VkDeviceCreateInfo::pNext`: a copy whose `pNext` the engine sets. A Vulkan 1.2 struct and the older per-feature
   structs it covers cannot share a chain, so a hook asks through `Vulkan11/12/13`. Each bit is checked first with
   `vkGetPhysicalDeviceFeatures2` on a zeroed copy of the struct.

   A queue request takes queues after the engine's own in a family whose flags hold every bit asked. A graphics request
   tries the engine's graphics family first; any other request tries, first, a family that does not draw.
5. **`vulkan_device_created`.** Once every engine object is ready, before the device is returned. The hook gets:
   - the `NativeDevice` (instance, physical device, device, queues and their families, proc addresses);
   - the queues it was granted;
   - the optional device extensions it got.

   Streamline's `slSetVulkanInfo` goes here.

The swapchain:

- **`vulkan_create_swapchain`.** Called for each swapchain the device makes: `create_swapchain`, each resize, and a
  swapchain made again when it is out of date. The hook may:
  - change the `VkSwapchainCreateInfoKHR` (more images, more usage bits, a `pNext` of its own). It must not change the
    format, the colour space or the extent: the engine's images are made for them.
  - replace any of the six functions the engine calls on this swapchain (`VulkanSwapchainFunctions`: create, destroy,
    get images, acquire, present, HDR metadata) with wrappers that call what they replace;
  - make the swapchain itself: return true and set `swapchain` and `result`.

  A hook that fails (sets `error`) has its changes undone and is marked unavailable. The engine then makes its own
  swapchain, after destroying the old one, so a swapchain the hook may have retired is never handed to Vulkan again.
- **Presents and the swapchain's end.**
  - `present_begin` and `present_end` come around `vkQueuePresentKHR`, with the device's present count as the frame id
    (1 for the first present) and the present's `VkResult`. They run under the lock of the device's queues, so they
    call the SDK (Reflex markers, pacing) and never the engine's device.
  - `swapchain_destroying` comes before a swapchain goes: `destroy_swapchain`, the old one a new one replaces, and the
    device's end.
- **The device's end.** The window's swapchain goes first, then `device_destroying`, with the GPU idle and every other
  object still alive. `slShutdown` goes there.

## D3D12

- **`d3d12_before_device`.** Before each `D3D12CreateDevice` the engine tries: on the WARP adapter, or on each hardware
  adapter in turn. The last call names the device's adapter.
- **`d3d12_device_created(factory, device, queue, adapter)`.** The device and its direct queue are made, before anything
  else is made on them. A hook may replace the factory, the device or the queue with an object that wraps it
  (Streamline's `slUpgradeInterface`):
  - the new pointer carries one reference, which the engine takes over;
  - the engine drops its own reference to the old object, so a wrapper that needs the old one AddRefs it;
  - a pointer left as the engine gave it is not a replacement and carries no reference.

  The replacements serve everything after: the device makes every resource, the queue takes every submit and the
  swapchain, and the factory makes the swapchain. A hook that sets `error` changes nothing; a replacement it handed
  anyway is released.
- **`d3d12_create_swapchain(factory, queue, hwnd, desc)`.** The hook may change the `DXGI_SWAP_CHAIN_DESC1`, but the
  engine sets its `BufferCount` and `Flags` back after each hook. A hook that makes the swapchain keeps
  `DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT` (the engine waits on it), and the engine reads the buffer count
  of the swapchain it gets (`GetDesc1`). It
  may also make the swapchain itself, as FSR 3's `ffxCreateSwapchainDX12` and XeSS frame generation do: it returns true
  and hands an `IDXGISwapChain1` with one reference. Resizes go through `ResizeBuffers` on whatever swapchain the hooks
  gave, which a proxy swapchain implements. A hook that fails is marked unavailable, its changes to the desc are undone,
  and the engine makes the swapchain.
- **`d3d12_swapchain_created(swapchain)`.** The swapchain is made, by the engine or by a hook. It may be replaced as
  above.
- **The swapchain's end and the presents.** `swapchain_destroying` comes before `destroy_swapchain` releases it.
  `present_begin` and `present_end` come around `Present`, with the frame id, the back buffer index and the `HRESULT`.
- **The device's end.** The swapchain goes first, then `device_destroying`, with the GPU idle.

## Streamline runtime core (M78-P4b)

`engine/render/src/streamline_runtime.{h,cpp}`: the first user of the hooks above, shared by every Streamline feature (DLSS
Super Resolution and Reflex today, DLSS frame generation in a later package).

- **No NVIDIA code.** The structures and functions of the Streamline C interface are the engine's own declarations in
  `sl_abi` (checked field by field against the MIT headers of tag v2.14.16, with `static_assert`s on sizes). The
  library is read at run time through `VendorLibrary` (`sl.interposer.dll`: `$FA_STREAMLINE_DIR`, the executable's folder,
  `<factoria home>/tools/streamline/<version>/`), and `StreamlineApi` is its table of functions. A test puts a fake table
  in its place (`set_vendor_loader_for_test`).
- **One process-wide `StreamlineRuntime`**, a `gpu::DeviceHook`, registered by `register_streamline_runtime()` before the renderer
  makes its device (Windows, D3D12 and Vulkan only; nothing elsewhere). It serves one device at a time: the features' options
  are those of the device that drew last.
- **Manual hooking.** `slInit` runs with `eUseManualHooking`, `eDisableCLStateTracking`, `eDisableDebugText` and
  `eUseFrameBasedResourceTagging`, before the device exists, so the engine owns the device and the swapchain and Streamline
  only wraps them.
- **D3D12.** `d3d12_before_device` reads the adapter's vendor through DXGI: on WARP or a non-NVIDIA adapter the runtime is
  unavailable with that reason and the library is not loaded. `d3d12_device_created` calls `slSetD3DDevice`, then
  `slUpgradeInterface` on the device and on the factory (replacements as the `d3d12_device_created` contract above), then
  `slIsFeatureSupported` for each feature with the adapter's LUID.
- **Vulkan.** `slGetFeatureRequirements` per feature gives the instance and device extensions, the Vulkan 1.2 and 1.3 feature
  names (`streamline_vulkan_features` builds the structs the engine merges) and the queues; `vulkan_resolve` hands the engine
  Streamline's `vkGetInstanceProcAddr` and `vkGetDeviceProcAddr` where it hooks a function; `vulkan_device_created` calls
  `slSetVulkanInfo` and `slIsFeatureSupported` with the physical device.
- **Degrading.** Any refusal marks the hook unavailable with `streamline_refusal`: Streamline's own result text and what to do
  (an NVIDIA driver update, hardware-accelerated GPU scheduling, `factoria setup streamline`). The device is made without it. The
  provider repeats the reason in `render.supports`.
- **Per frame.** The provider asks `StreamlineRuntime` for the frame token (`slGetNewFrameToken`, index = presents), sets the
  constants and tags, and evaluates inside one `begin_native` section (`render_upscale_dlss.cpp`). The runtime keeps the token of the
  index it last asked (and of the set-up that made it), so every feature that asks for the same frame, DLSS and Reflex, gets the same
  pointer. `ready_generation()` is the one cheap call a feature makes before it calls Streamline: 0 when the runtime is not ready, so
  nothing is called after the device went. The process's runtime asks for DLSS, Reflex and PCL (the latency mode is chosen after
  `slInit`).
- **Tests.** `engine/render/tests/dlss_upscale_tests.cpp` (ctest `render`): the D3D12 and Vulkan hook order on fakes, every reason
  the runtime is unavailable, the provider's options (only on a change), constants, tags and evaluation, failures that close the
  section and reset the history, release, the `auto` choice and the `render.supports` row. The real library and a real RTX GPU
  are not covered by any test.

## DLSS Ray Reconstruction (M78-P4c)

`render_upscale_dlss.cpp` (the provider), `render_upscale_rr.{h,cpp}` and `shaders/upscale_rr.glsl` (the guides), `renderer_upscale.cpp`
(the decision). Opt-in with `render.upscaler.rayReconstruction`; user text in docs/UPSCALING_VENDORS.md, "DLSS Ray Reconstruction".

- **ABI.** `sl_abi` declares, from Streamline v2.14.16 (`sl_dlss_d.h`, `sl_consts.h`), `kFeatureDlssRr` (1001), `DlssdOptions`
  (224 bytes), `DlssdOptimalSettings` (64 bytes), the buffer types Albedo (7), SpecularAlbedo (8), NormalRoughness (14) and
  `DlssdNormalRoughnessMode`, each size with a `static_assert`. The process's runtime asks for `{DLSS, DLSS-RR, Reflex, PCL}`; a
  plugin the machine lacks is only that feature's reason (`feature_reason`).
- **Probe.** `VendorUpscaler::probe_ray_reconstruction(env)`: DLSS's `probe` plus Ray Reconstruction's own `feature_reason`; the
  others answer "no ray reconstruction". The renderer asks once (`Renderer::Impl::rr_probe`) and `set_vendor_env` builds the
  `dlssRayReconstruction` row of `render.supports` from it (also not linear, DLSS off, failed earlier).
- **Decision per frame** (`Renderer::Impl::vendor_upscale`, index 0 only): the setting, a usable machine, `in.linear`,
  no dynamic resolution, a perspective camera, then the guides pass (`run_rr_guides`: world normal and roughness to colour 0, the
  hardware depth of `camera.proj` to colour 1 (R32F; `rr_depth_terms` and `rr_hardware_depth` are the formula the shader repeats), and a
  clear pass for each albedo). `UpscaleInput` carries the guide views and an `UpscaleCamera`
  (view, projection and previous-frame matrices, the camera axes and planes, from the TAA plan).
- **Provider.** `draw(in, frame, api, runtime, rr)` shares the frame token, constants and native section with Super Resolution. With `rr`
  it sets the options every frame (`slDLSSDSetOptions`: the camera's view matrices change), tags seven buffers in the order colour in,
  depth (that hardware depth, `VendorFrame::rrDepth`: the constants carry the projection, so the prepass's d / (d + 1) would not agree), motion, colour out, albedo, specular albedo, normal-roughness, and evaluates `kFeatureDlssRr`. Matrices: `fa::Mat4` is column
  major with column vectors, the same memory as Streamline's row-major `Float4x4` with row vectors, so they are copied as they are.
  A switch between the two features, a lost device or a failed frame resets the history. When Ray Reconstruction cannot draw, `upscale`
  draws the same frame with Super Resolution and sets `VendorFrame::rayReconstructionFallback`; the renderer logs it once and, for a
  frame Streamline refused, latches `rrFailed`.
- **Tests.** `dlss_upscale_tests.cpp` ("dlss ray reconstruction ..."): the probe and its reasons, the feature switch, the tags (the depth tag is the hardware-depth image, whose values `rr_hardware_depth` gives for a known distance), the options
  and matrices, every fall back, the switch back and device loss, release; `upscaler_tests.cpp` and `upscaler_commands_tests.cpp`: the
  setting.

## Low latency (M78)

`engine/render/include/fa/render/latency.h` holds the public part (`LatencySettings`, the mode and driver enums, `parse_latency_settings`);
the rest is private to `fa_render`:

- **`render_latency.{h,cpp}`: the seam.** A `LatencyProvider` is one SDK (`probe`, `start`, `configure`, `sleep`, `marker`,
  `vendor_report`, `stop`). The table has three slots, Reflex, Anti-Lag 2 and XeLL; `register_latency_provider()` fills one (the
  Reflex provider is in the table from the start; the others register the same way in a test). The
  `LatencyController` (one per renderer) chooses the driver from the mode, the GPU's maker and the probes, starts the provider when the
  device exists, and falls back to the engine's own pacing when the SDK is unavailable or a call fails. With the mode `off` its calls
  are one branch. Its clock is replaceable, so the tests drive time themselves.
- **`render_latency_antilag2.{h,cpp}`.** D3D12 through `amdxc64.dll` (loaded with `VendorLoader`, the same seam the upscalers use;
  `AmdExtD3DCreateInterface`, `UpdateAntiLagState`). Vulkan through a `DeviceHook` that asks `VK_AMD_anti_lag` on an AMD GPU, then
  takes `vkAntiLagUpdateAMD` from `vkGetDeviceProcAddr`; the INPUT stage goes at `sleep()` and the PRESENT stage at the present-start
  marker, with one frame index. The hook is registered on Windows before the device is made (`register_latency_device_hooks`).
- **`render_latency_xell.{h,cpp}`.** `libxell.dll` (the XeSS spec of `factoria setup xess`), Direct3D 12 only.
- **`render_latency_reflex.{h,cpp}`.** NVIDIA Reflex through the Streamline runtime above: `sl_abi` has the declarations of `sl_reflex.h`
  and `sl_pcl.h` (`ReflexOptions`, `ReflexState`, the PCL marker values; `static_assert`s on the sizes), and the four functions
  (`slReflexSetOptions`, `slReflexGetState`, `slReflexSleep`, `slPCLSetMarker`) come from `slGetFeatureFunction`. `probe` refuses in
  the order the user can fix (backend and Windows, the GPU's maker, Streamline not installed or not started with the device, the
  backend it started for, the plugin's `slIsFeatureSupported`, the driver's `lowLatencyAvailable`). Every call is guarded by
  `StreamlineRuntime::ready_generation()` equal to the one `start` saw. `sleep` takes the frame's token once per frame id (the
  runtime's, shared with DLSS); `marker` maps `LatencyMarker` to `sl::PCLMarker` (`reflex_pcl_marker`; the input sample has none);
  `configure` sends `slReflexSetOptions` only when the mode or the frame limit changes; `vendor_report` reads `slReflexGetState`'s
  frame reports. `engine/render/tests/reflex_latency_tests.cpp` drives it on a fake Streamline.
- **`renderer_latency.cpp`.** The renderer's API (`set_latency`, `latency_status`, `latency_report`, `latency_frame_begin`,
  `latency_mark`, `take_latency_ms`) and the three `render.supports` rows. The frame id is the number of presents done plus one, the
  `frame` of the next `PresentEvent`. The engine calls `latency_frame_begin` before the platform reads the input,
  `latency_mark(InputSample)` after, and `latency_mark(SimulationEnd)` before the render; the renderer marks the submit and the present.

## Frame generation (M78)

`engine/render/include/fa/render/framegen.h` holds the public part (`FrameGenSettings`, the mode and slot enums, `parse_frame_gen_settings`,
`effective_frame_generation`); the rest is private to `fa_render`. User text: docs/FRAME_GENERATION.md.

- **`render_framegen.{h,cpp}`: the seam.** A `FrameGenProvider` is one SDK (`probe`, `device_hook`, `start`, `swapchain_changed`, `wants_reversed_depth`,
  `configure`, `dispatch`, `generated_frames`, `stop`). The table has three slots, DLSS, FSR 3 and XeSS, **all empty** in this package; `register_framegen_provider()`
  fills one (the three provider packages call it once each) and an empty slot answers with the package that fills it
  (`framegen_absent_reason`). The table is never destroyed and tests use `set_framegen_provider_for_test`. A provider that makes or wraps the
  swapchain returns its `DeviceHook` from `device_hook()`; `Renderer::init` puts `framegen_device_hooks()` in `DeviceInit::hooks` of the device it
  is about to make when `RendererDesc::frameGeneration` is on (a window of D3D12 or Vulkan the renderer claims), and tells the controller the
  device was "hooked". **The hooks are never registered process-wide** (unlike the latency ones): a second renderer in the process that did
  not ask for frame generation makes a device none of them sees (tested with a fake hook: the device given the hooks marks it, the other leaves
  it available). The same hook object serves each device that has it and passes everything through once `stop()` ran. Without the hook the
  controller refuses with "restart the game": a swapchain cannot be taken over afterwards. A provider is told when the swapchain it runs on
  changes (`swapchain_changed`: made again after the window came back, resized, or lost with width and height 0; `Renderer::present` and
  `set_native_window` call `FrameGenController::set_swapchain`) and the next frame carries `reset`.
- **`FrameGenFrame`** is everything the three SDKs' constants need, so a provider package does not reshape it: the images (`hudless`,
  `presented`, `depth`, `motion`), the depth convention (`depthReversed` / `depthInfinite`, from `FrameGenProvider::wants_reversed_depth`: the
  upscaler's preparation pass makes either `d / (d + 1)` or the reversed infinite `near / d`, and `framegen_pass` remakes it if the upscaler left
  the other kind), the motion convention (UV fractions, previous - current, unjittered, `motionScaleX/Y`), the camera (`cameraNear`,
  `cameraFar` from the `Camera` component, `cameraFovY`, `cameraPosition`, the right, up and forward axes, `viewFromWorld`, `proj`,
  `prevFromView`, the jitter), the colour (`colorFormat`, `exposure` 1: the pictures are tonemapped and exposed, `outputEncode`,
  `hdrHeadroom`, `paperWhiteNits`) and `reset`. `reset` is the frame's own camera cut (`!upscaleTaa.prevValid`: scene change, floating-origin
  rebase, a camera that did not draw the frame before) or the controller's: first frame, a pause that ended, a refused frame, a changed output
  size (`dispatch` compares it with the last frame's), a changed swapchain.
- **`FrameGenController`** (one per renderer; attached to the device after `LatencyController`, detached before it). `apply()` decides in this
  order: the slot the mode names (auto: the GPU maker's; a maker with no SDK is a refusal naming it), the slot's probe (asked once per
  attach), `effective_frame_generation`, the hook, the provider's `start` (a failure is kept and not retried: "fail once, stay off"), then the
  frame's inputs (`set_inputs(upscaleStage, temporalFrame)`, from `render_world`). A refusal keeps a started provider started; only
  `configure(false)` puts it to sleep. `begin_frame(nowMs)` keeps 31 time stamps (30 intervals), adds the SDK's counter growth
  (`generated_frames()` restarts at 0 with each `start`) and applies the `minBaseFps` rule: off below it, on at it, back on at
  `kResumeMargin` (1.1) above it after a pause, `kMinDwellFrames` (90) between two switches, `minBaseFps` 0 never off. The clock is
  `latency_clock()`, which a test replaces.
- **The output passes** (`renderer_draw.cpp`, `finish_output`; `renderer_framegen.cpp`). The screen-space items are drawn into the output
  image itself, so the hudless picture is a **copy**: `plan_framegen_passes(dispatchWanted, hudOver)` says whether the pass `framegen-hudless`
  (a `blit_keep_pipeline` copy of `outTarget` into `hudlessTarget`) runs, and the order is `upscale`, `framegen-hudless`,
  `hud-over-upscale`, `output-color-filter` (only when the camera has a colour filter), `framegen`; the renderer logs the passes that ran in
  `outputPassLog`, read by `RendererTestAccess::output_passes`, which is what the tests check. The presented picture is the one the window
  shows: with a filter that is `output-filtered`, so the copy is drawn through the same `post_pass` filter (into `output-hudless`, in the
  display format) and `framegen` runs after the filter with `presented` = the filtered image. The frame graph keeps the order by the declared
  reads and writes (the copy reads `output` and writes `output-hudless`; `framegen` reads the shown picture, the copy, the depth and the
  motion, and writes the shown picture).
  The depth and the motion are `mfxDepth` and `mfxMotion`, made by `run_upscale_prep`; when the upscaler (the engine's own temporal one) did
  not make them this frame the `framegen` pass runs the preparation itself (`prepSerial` compares with `upscaleTaa.serial`), and the images
  are kept while generation is on. `hudlessTarget` is freed after `kOutputIdleFrames` without a copy. A frame that needs the copy and cannot
  make it is not handed over (`note_skipped`: the next dispatch carries `reset`).
- **`renderer_framegen.cpp`.** The renderer's API (`set_frame_generation`, `frame_generation`, `effective_frame_generation`,
  `frame_generation_status`, `frame_generation_report`) and the `render.supports` answers (`set_framegen_env`: the rows `dlssFrameGen`,
  `fsrFrameGen`, `xessFrameGen`; `framegen_slot_backends` adds their D3D12 and Vulkan keys).
- **The engine** (`Engine::set_frame_generation`, the command `render.frame_generation`, `profile_frame_generation`): the setting is applied
  to a windowed, non-editor renderer only (like latency); `rd.frameGeneration` is on when the project's mode is not `off` at the start.
  `ProfileSummary::set_frame_generation` stores the readout as `profile.frameGeneration`.
- **Tests.** `engine/render/tests/framegen_tests.cpp` (ctest `render`): key parsing and errors, the provider choice per GPU maker, each
  refusal's sentence, the hysteresis on a fed clock, start and stop across mode changes and a detach, the order of the output passes, and a
  real headless renderer with a fake provider (the frame it gets, the passes it runs, off stops it; `RendererTestAccess::framegen_assume_hooked`
  stands for the swapchain hook a headless run has no window for). No vendor SDK, and no D3D12 or Vulkan swapchain, is exercised.

- **Intel XeSS frame generation (M78-P5d): `render_framegen_xess.{h,cpp}`.** The provider of the `xess` slot and its `DeviceHook`: one object
  (`make_xess_framegen_provider()`, registered by the provider table). The C ABI of `xefg_swapchain.h` and `xefg_swapchain_d3d12.h` (XeSS
  3.0.2) is declared in the header (64-bit `static_assert`s on every struct), the functions come from `libxess_fg.dll` through
  `VendorLibrary::symbol`, and the tests (`framegen_xess_tests.cpp`) run against a fake table. XeSS-FG is a proxy swapchain, so the work is in
  `d3d12_create_swapchain`: XeLL's context (below), `xefgSwapChainD3D12CreateContext`, `SetLatencyReduction` **before** `InitFromSwapChainDesc`
  (`applicationSwapChain` null, one interpolated frame, `uiMode` none, flags 0: unjittered motion, non-inverted depth), then
  `GetSwapChainPtr` for `IDXGISwapChain1`, which the hook returns with its one reference. It makes no swapchain (and says nothing) on a
  GPU that is not Intel (vendor id read from `IDXGIAdapter1::GetDesc1` through the vtable, no Windows header), without the library, or
  without `libxell.dll`: the probe is what tells the user. A library that is installed and fails sets `error`, which marks the hook
  unavailable for the device. The context is destroyed lazily (when the next swapchain is made, and at `device_destroying`, the
  swapchain's references must be gone) and always before XeLL's. `start` only checks that the hook made the swapchain of this device,
  `configure` sets XeLL's sleep mode and `SetEnabled`, `dispatch` tags depth and motion (ONLY_NOW, COPY_SOURCE through `begin_native`) and the
  constants, `present_begin` calls `SetPresentId`, `present_end` counts `framesPresented - 1`. A failing call is `fail()`: logged once,
  `failure()` (a new virtual of the seam) keeps the reason, the probe and `provider_reason` repeat it and the controller stops the provider
  for the run.
- **XeLL shared (`XellShare`, `render_latency_xell.h`).** The XeLL latency provider owns the context; XeSS-FG takes a reference when it makes
  the swapchain (before the latency controller exists) and the context goes with the last reference (`LatencyProvider::xell_share()`).
  `LatencyController::require_driver(Xell)` forces XeLL on while XeSS-FG is the running provider (`Renderer::Impl::sync_framegen_latency`)
  whatever `render.latency` is; `latency_status` says so. XeLL's last sleep id is the present id of the frame's tags.
- **Open.** The hook is not told the mode (`RendererDesc::frameGeneration` is a bool): on an Intel GPU with both libraries it makes the proxy
  swapchain even when another provider's mode was chosen. Depth and projection conventions are untested on hardware.

## Tests

- **`engine/render/tests/latency_tests.cpp`.** Fakes everywhere (a recording device with a backend and a PCI vendor, a clock, providers,
  a `VendorLoader` with fake modules and a fake Vulkan device-proc table): the settings and their errors, the driver table, the order of
  calls and ids, the fallbacks, the engine's pacing, the readout, and both providers against their fake libraries. Windows-only code
  paths that load a real SDK are covered on a Windows machine with the SDK only.

- **`engine/render/tests/gpu_native_tests.cpp`.** The registry: each hook added once, the caller's first. The
  `RecordingDevice` marks every hook unavailable with the reason. The first reason stays, and `mark_available` starts a
  hook over.
- **`engine/render/tests/vulkan_hooks_tests.cpp`.** Runs on MoltenVK here and on lavapipe in the Linux CI job, with the
  validation layer. Fake hooks:
  - ask for an instance extension, a device extension, a feature merged into the engine's struct and one appended;
  - wrap `vkQueueSubmit`, and the engine's submits go through the wrapper;
  - ask for what no device has (an extension, a bad struct, an impossible queue) and become unavailable with their
    reasons, while the device works;
  - a compute queue is granted where a family has one left.

  The case is under ctest `render_gpu_native`.
- **`engine/render/tests/vulkan_device_tests.cpp`, "a device hook wraps the swapchain's creation and present".** On a
  window: the wrapped create and present are called, a resize goes through the hook again, and the old swapchain is
  announced. Each present is heard with its frame id. The back buffer's `NativeImage` carries its usage and format.
- **`engine/render/tests/d3d12_native_tests.cpp`.** On WARP: the adapter is heard before the device, a hook replaces the
  factory and the next hook sees the replacement, and a failing hook's factory is released (reference counts checked).
  `device_destroying` comes at the end.
- **`engine/render/tests/d3d12_device_tests.cpp`, "a device hook makes the swapchain itself".** A hook makes the
  swapchain on a hidden window. The engine draws and presents into it and resizes it without asking the hook again. The
  hook hears every present and the swapchain's end.
- **Not covered by a test.** The retry of `vkCreateInstance` or `vkCreateDevice` without the hooks' additions: no
  driver here refuses a device deterministically.
