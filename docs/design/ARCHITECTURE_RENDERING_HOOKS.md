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

## Low latency (M78)

`engine/render/include/fa/render/latency.h` holds the public part (`LatencySettings`, the mode and driver enums, `parse_latency_settings`);
the rest is private to `fa_render`:

- **`render_latency.{h,cpp}`: the seam.** A `LatencyProvider` is one SDK (`probe`, `start`, `configure`, `sleep`, `marker`,
  `vendor_report`, `stop`). The table has three slots, Reflex, Anti-Lag 2 and XeLL; `register_latency_provider()` fills one (the
  Streamline provider fills Reflex with one call; until then the slot answers "arrives with the Streamline provider"). The
  `LatencyController` (one per renderer) chooses the driver from the mode, the GPU's maker and the probes, starts the provider when the
  device exists, and falls back to the engine's own pacing when the SDK is unavailable or a call fails. With the mode `off` its calls
  are one branch. Its clock is replaceable, so the tests drive time themselves.
- **`render_latency_antilag2.{h,cpp}`.** D3D12 through `amdxc64.dll` (loaded with `VendorLoader`, the same seam the upscalers use;
  `AmdExtD3DCreateInterface`, `UpdateAntiLagState`). Vulkan through a `DeviceHook` that asks `VK_AMD_anti_lag` on an AMD GPU, then
  takes `vkAntiLagUpdateAMD` from `vkGetDeviceProcAddr`; the INPUT stage goes at `sleep()` and the PRESENT stage at the present-start
  marker, with one frame index. The hook is registered on Windows before the device is made (`register_latency_device_hooks`).
- **`render_latency_xell.{h,cpp}`.** `libxell.dll` (the XeSS spec of `factoria setup xess`), Direct3D 12 only.
- **`renderer_latency.cpp`.** The renderer's API (`set_latency`, `latency_status`, `latency_report`, `latency_frame_begin`,
  `latency_mark`, `take_latency_ms`) and the three `render.supports` rows. The frame id is the number of presents done plus one, the
  `frame` of the next `PresentEvent`. The engine calls `latency_frame_begin` before the platform reads the input,
  `latency_mark(InputSample)` after, and `latency_mark(SimulationEnd)` before the render; the renderer marks the submit and the present.

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
