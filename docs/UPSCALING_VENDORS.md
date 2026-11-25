# Vendor upscalers: DLSS, XeSS and FSR 3.1 (M78)

This page is part of [UPSCALING.md](UPSCALING.md) (the settings, the temporal upscaler, the render scale): the three upscalers of the GPU
makers, reached through each maker's SDK.

`mode` `dlss` (NVIDIA DLSS Super Resolution, through NVIDIA Streamline), `xess` (Intel XeSS) and `fsr` (AMD FidelityFX Super Resolution 3.1)
hand the upscale to the maker's SDK. They read what the temporal upscaler reads: the jittered picture at the render size, the depth and
the motion of the depth prepass, the jitter, and the reactive mask (the same one MetalFX gets), and write into the same `upscale` stage,
with the HUD drawn after it at the window's size. They need a single jittered camera like `temporal`, so a frame of several cameras
draws `spatial`; pixel art stays `stretch`.

- **No SDK is in the engine.** The engine ships no vendor header and no vendor binary. Each SDK is reached through the engine's own
  declaration of its C interface and a function table read at run time from its library (the way DirectStorage is loaded), so a game
  built without them runs everywhere. The libraries are `sl.interposer.dll` (Streamline, with the plugin libraries `sl.common.dll`,
  `sl.dlss.dll` and `nvngx_dlss.dll` next to it), `libxess.dll` (XeSS; `libxess_dx11.dll` on D3D11) and `amd_fidelityfx_loader_dx12.dll` /
  `amd_fidelityfx_loader_vk.dll` (FidelityFX: the loader of the backend, with the upscaler DLL next to it).
- **Where the library is looked for**, in this order: the folder `$FA_STREAMLINE_DIR`, `$FA_XESS_DIR` or `$FA_FIDELITYFX_DIR` names (an
  explicit choice: if the library is not there the search stops, the other places are not tried); the folder of the executable (an
  exported game carries the libraries next to it); the newest version folder of `<factoria home>/tools/<id>/<version>/`, where
  `factoria setup streamline`, `factoria setup xess` and `factoria setup fidelityfx` install them (factoria home is `$FACTORIA_HOME`,
  else `~/.factoria`; versions compare as dotted numbers, so 2.10.0 is newer than 2.9.1). Where the licence of an SDK asks for it, the
  setup command asks the developer to accept it; the engine never downloads anything by itself.
- **Where each one runs.** Windows only. DLSS Super Resolution runs on Direct3D 12 and Vulkan (Streamline has to take part in making the
  device, and the engine's device hooks exist on those two backends only: on Direct3D 11 the `dlss` row says so), XeSS on Direct3D 12,
  Vulkan and Direct3D 11, FSR 3.1 on Direct3D 12 and Vulkan. On any other system the three modes exist and report unavailable with that
  reason. `dlss` needs an NVIDIA RTX GPU; `xess` and `fsr` may be chosen on any GPU (XeSS is fastest on Intel Arc, which has the XMX units;
  FSR runs on every GPU).
- **`auto`** tries the SDK of the GPU's maker first (NVIDIA `dlss`, Intel `xess`, AMD `fsr`) when it is installed and usable, and
  otherwise takes the M76 chain (`metalfx`, `temporal`, `spatial`). An explicit `xess` or `fsr` is never refused for the GPU's maker,
  only for what is missing; an explicit `dlss` on a GPU that is not an NVIDIA RTX is refused with that reason.
- **When one cannot draw.** `effectiveMode` says what draws instead (`metalfx`, `temporal`, then `spatial`). `render.supports` rows `dlss`,
  `xess` and `fsr` give the reason, in the order of what the machine decides: the GPU's maker (DLSS), the backend, the system, and last the
  library ("DLSS is not installed: run `factoria setup streamline` (...where it looked...)"). The log says it once, with the mode asked
  and the one that draws instead. A frame the SDK refuses (a size it does not take, a lost device) is the same: from then on every
  frame draws without it, with one warning ("fail once, stay off", as MetalFX does) and the temporal upscaler draws that frame, so
  the player never sees a missing picture.
- **What is real today.** The seam (the modes, the choice, the reasons, the loader, `render.supports`, the menu and the editor), the
  Streamline runtime with DLSS Super Resolution, the XeSS provider and the FSR provider below. Tests put fake providers, a fake
  loader and a fake Streamline in the same place the real ones go (`vendor_upscale_tests`, `xess_upscale_tests`,
  `fsr_upscale_tests`, `dlss_upscale_tests`).

## NVIDIA DLSS Super Resolution

The `dlss` mode. DLSS is reached through NVIDIA Streamline (the 2.14 series; `sl.interposer.dll`). Streamline takes part in making the graphics device, so
the engine starts it **before the device exists** (docs/design/ARCHITECTURE_RENDERING_HOOKS.md, "Streamline runtime core"; repository only, not in the binary): a Windows
build registers one device hook, and every Direct3D 12 or Vulkan device the process makes goes through it.

- **What the hook does.** It looks for the library and loads it, and starts Streamline in its manual hooking mode (the engine owns the
  device and the swapchain; Streamline only wraps them). On Direct3D 12 it hands Streamline the device and wraps the device and the DXGI
  factory (`slUpgradeInterface`), so the engine uses the wrappers from then on. On Vulkan it asks Streamline for the instance extensions,
  device extensions, device features and queues it needs, enables them, uses Streamline's own `vkGet*ProcAddr` where it hooks a function,
  and tells it the device and its queues. Nothing of this happens on a GPU that is not an NVIDIA one (the library is not even loaded) or
  when Streamline is not installed.
- **When it is off.** An NVIDIA GPU, an installed Streamline, a driver and an OS that Streamline accepts, and a GPU with RTX support are
  all needed. When one is missing the hook switches itself off with Streamline's own words and what to do (a driver that is out of date:
  "Update the NVIDIA graphics driver"; hardware-accelerated GPU scheduling off: where to turn it on; a plugin library missing: run
  `factoria setup streamline` again), the device is made as it would be without it, and the `dlss` row of `render.supports` repeats the
  reason. A device is never refused because of DLSS.
- **The quality.** The names of `quality` land on DLSS's own modes by the upscale ratio (output size over render size): native is DLAA
  (1.0), quality is Quality (1.5), balanced is Balanced (1.7, DLSS's is 1.72), performance is Performance (2.0) and ultraPerformance is
  Ultra Performance (3.0); DLSS's Ultra Quality (1.3) is the nearest mode of a ratio around it. A dynamic resolution that moves the
  ratio keeps the mode it is in within 0.13 of its ratio, so the options are not set again at every step.
- **What a frame does.** DLSS is asked its recommended render size for the mode and the output size (`slDLSSGetOptimalSettings`) whenever
  either changes. A frame drawn outside what DLSS takes (two pixels of its recommended size when it gives no range) is refused with the
  size it wanted and the setting to change (`render.upscaler.quality`), and the frame draws as the next best mode. Then, per frame:
  Streamline's frame token (counted in presents, so a frame is the same number everywhere), the constants (the jitter in render pixels,
  motion scale 1: the prepass writes motion in UV units, depth 0..1 growing with the distance, a reset flag after a cut, a resize, a change
  of the options or a frame that failed), the four images (colour, depth, motion, output) with the states the engine's native section
  declares, and the evaluation, all inside one native command section of the pass's list. The options (mode, output size, pre-exposure, HDR
  or not) are set only when one changes; DLSS is told the colour is exposed already and finds its own scene exposure.
- **What it does not read.** The reactive mask of the frame is not given to DLSS, and the camera matrices are not set (Super Resolution
  does not read them; the frame generation package sets them).
- **What it frees.** When the renderer shuts down the GPU is waited for, the options are turned off and DLSS's resources are released.
- **Not checked by the tests** (they use a fake Streamline): that the real library takes the engine's declarations as they are, that
  the picture is right, and the Direct3D 12 and Vulkan device flows on a real driver: those need a machine with an NVIDIA RTX GPU.
- **What NVIDIA asks of a game that ships DLSS** (the license of the NVIDIA RTX SDKs; `factoria setup streamline` shows it and asks for
  acceptance; an export repeats this in its next steps): notify NVIDIA before the game's commercial release
  (<https://developer.nvidia.com/sw-notification>); credit NVIDIA and show its marks (in the credits, and on a splash screen or an
  about box for DLSS); DLSS is for systems with NVIDIA GPUs only. docs/exporting/EXPORTING_SETUP.md, "Vendor SDK licences".

## Intel XeSS

The `xess` mode. Needs XeSS 3.0 or newer: `libxess.dll` for D3D12 and Vulkan on any GPU, `libxess_dx11.dll` for Direct3D 11 (Intel
Arc only: on another GPU the reason says to run the game on D3D12 or Vulkan). On Vulkan XeSS asks for instance and device extensions;
if the engine's device did not enable them the reason lists them (M78's device-creation package enables them). The library is probed
once (it must load, export every function of the backend and answer a version of 3.0 or newer). One XeSS context is made per
device and initialised again only when the render size, the output size, the quality or the input format changes (the GPU is waited
for first), never per frame; the quality is the nearest XeSS setting to the upscale ratio (1.3, 1.5, 1.7, 2.0, 2.3, 3.0; the five
names of `quality` land exactly) and a dynamic resolution that wobbles near a boundary keeps the setting it has. The engine passes
its own render size, the jitter, the exposure and the reset flag (a cut, a resize or a frame after a failure), the responsive mask
(an empty one when no item asked for a reactive mask) and an output image made with storage usage. The depth and the motion XeSS
reads are made by the same preparation pass as MetalFX's (depth 0..1, motion in UV units, with the velocity scale set to the render
size). The context is destroyed, after the GPU is idle, when the renderer shuts down. A failing call is reported with XeSS's own
words ("unsupported device", "unsupported driver", ...) and the mode is off for the run. Not checked by the tests (they use a fake
library): that the real library's picture is right, which a D3D12 or Vulkan run on a GPU shows.

## AMD FSR 3.1

`fsr` runs on D3D12 and Vulkan on any GPU (never D3D11) and needs `factoria setup fidelityfx` (the loader of the backend and the
upscaler DLL). The probe loads the loader, needs its four exports (`ffxCreateContext`, `ffxDestroyContext`, `ffxQuery`, `ffxDispatch`)
and asks `ffxQuery` which FSR versions it has for this GPU: none is "no FSR provider for this GPU" and a newest below 3.1 is refused;
on Vulkan the device must be 1.1 or newer (FSR asks for no extension the engine does not enable). One FSR context is made per device,
for the largest render size (the base scale), the output size, the quality and the flags (linear light is `HDR` input, display values
the non-linear colour space; depth is always inverted and infinite; `dynamicResolution` is set while the render size moves), and is
made again (after the GPU is idle) only when one of them changes, never per frame; a render size that moves under the maximum does
not make one. The five qualities are FSR's five modes in order (`native` 0, `quality` 1.5x, `balanced` 1.7x, `performance` 2x,
`ultraPerformance` 3x); the engine feeds its own render size, so the mode only keys the context. Each frame passes: the colour, the
depth (the preparation pass writes FSR's reversed infinite depth, `near / distance`, 0 for the sky), the motion (UV units; the motion
scale is the render size, so FSR reads pixels), the reactive mask when there is one, an output with storage usage, the jitter in
render pixels (clamped to 1), the pre-exposure (1: the scene is exposed before the stage; no exposure texture), the engine clock's
frame time in milliseconds, the camera's near and field of view, sharpening off, and the reset flag (first frame of a context, a cut,
a resize, a frame after a failure). The dispatch is recorded inside the native command section with every image declared (colour,
depth, motion and mask read, the output written). A failing call is reported with FidelityFX's code and last message, and the mode
is off for the run. Not checked by the tests (a fake library): that the real library accepts these resource states and draws the
right picture, which a D3D12 and a Vulkan run with the SDK on an AMD GPU and on another maker's show.

The **menu kit and the editor** list the three modes (DLSS, XeSS, FSR) greyed out with the reason where `render.supports` says no.
