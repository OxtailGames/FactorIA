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
  size it wanted, the range of render sizes DLSS takes for the mode and the setting to change (`render.upscaler.quality`,
  `window.renderScale`), and the frame draws as the next best mode. Then, per frame:
  Streamline's frame token (counted in presents, so a frame is the same number everywhere), the constants (the jitter in render pixels,
  motion scale 1: the prepass writes motion in UV units, depth 0..1 growing with the distance, a reset flag after a cut, a resize, a change
  of the options or a frame that failed), the four images (colour, depth, motion, output) with the states the engine's native section
  declares, and the evaluation, all inside one native command section of the pass's list. The options (mode, output size, pre-exposure, HDR
  or not) are set only when one changes; DLSS is told the colour is exposed already and finds its own scene exposure.
- **The reactive mask.** When the frame has one (particles and other items that blend over the scene, at the render size), it is tagged
  as Streamline's `BiasCurrentColorHint`, the optional mask where DLSS Super Resolution weighs the current frame's colour more. A frame
  without one tags the four images only. Not checked on hardware (hardware checks, below).
- **The camera matrices.** Super Resolution does not read them: it gets identity matrices, the header's "not set" values for the rest of
  the camera and the plain jitter, motion scale and flags. Ray Reconstruction (below) sends the camera's real matrices, and DLSS frame
  generation sets its own constants (docs/FRAME_GENERATION.md).
- **The ids Streamline is started with.** `applicationId` is NVIDIA's id of a registered game: 0 (none) unless the environment variable
  `FA_STREAMLINE_APP_ID` holds a decimal number. `projectId` is the GUID of the game that a custom engine must give: FactorIA's own
  (`f7e365b8-d718-4b3b-9c87-73752211173b`) unless `FA_STREAMLINE_PROJECT_ID` holds a GUID (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`; any other
  text is ignored). A shipped game sets both before it starts, from its launcher; they are read when Streamline starts.
- **On a GPU that is not NVIDIA.** On Direct3D 12 the adapter is read before Streamline starts, so it never loads. On Vulkan the
  instance is made before the GPU is chosen, so Streamline has started by then: once the GPU is known not to be an NVIDIA one, the engine
  calls `slShutdown` and uses its own Vulkan functions from then on. The library itself stays loaded (the instance's function pointers
  were taken through it).
- **What it frees.** When the renderer shuts down the GPU is waited for, the options are turned off and DLSS's resources are released.
- **Not checked by the tests** (they use a fake Streamline): that the real library takes the engine's declarations as they are, that
  the picture is right, and the Direct3D 12 and Vulkan device flows on a real driver: those need a machine with an NVIDIA RTX GPU.
- **What NVIDIA asks of a game that ships DLSS** (the license of the NVIDIA RTX SDKs; `factoria setup streamline` shows it and asks for
  acceptance; an export repeats this in its next steps): notify NVIDIA before the game's commercial release
  (<https://developer.nvidia.com/sw-notification>); credit NVIDIA and show its marks (in the credits, and on a splash screen or an
  about box for DLSS); DLSS is for systems with NVIDIA GPUs only. docs/exporting/EXPORTING_SETUP.md, "Vendor SDK licences".

## DLSS Ray Reconstruction

An opt-in preview of the `dlss` mode (and of `auto` where it picks DLSS): `render.upscaler` `rayReconstruction: true` (project
`render.upscaler.rayReconstruction`, `window.upscaler.rayReconstruction`; default `false`). DLSS Ray Reconstruction (Streamline's `DLSS-D`, feature id 1001, DLSS 3.5) is a
denoiser and upscaler in one network: instead of upscaling a clean picture (Super Resolution) it takes a picture with noisy lighting plus
**guide buffers** that say what each pixel is, and gives back the denoised, upscaled picture. It needs the same machine as Super Resolution
(an NVIDIA RTX GPU, D3D12 or Vulkan, Streamline installed) plus its own plugin (`sl.dlss_d.dll` and `nvngx_dlssd.dll`, which
`factoria setup streamline` installs with the rest).

- **The plugin is asked for at start.** Streamline loads only the plugins it is told of when it starts, before the device, so the plugin of
  Ray Reconstruction is asked for only when the project's `render.upscaler.rayReconstruction` is true and its `mode` is `dlss` or
  `auto` when the game starts (a game that never uses it does not pay its load time and memory). A `window.upscaler` or `render.upscaler`
  change to true later in a run that started without the plugin is refused, and `render.supports` `dlssRayReconstruction` says which
  setting to change before the restart: `render.upscaler.rayReconstruction` when it is false in factoria.json, `render.upscaler.mode`
  (to `dlss` or `auto`) when the flag is already true and the game starts in another mode.
- **The graphics presets turn it off.** `low`, `medium` and `high` write a whole upscaler (mode `auto`, a quality, sharpness 0.5), so
  `rayReconstruction` is false while one is on; `ultra` and `custom` keep the game's own setting (docs/UPSCALING.md, "Graphics presets").

- **Without ray tracing.** The renderer is a forward renderer: a frame with no ray traced effect has little noise to remove. Ray
  Reconstruction still upscales it and reads the guides, but with approximations (below), so the result can differ from Super
  Resolution's, for better or for worse. Treat it as a preview and compare the two on your content.
- **The ray traced signals (M79).** When Ray Reconstruction will draw the frame, the engine does not denoise the ray traced
  **reflections** (`render.rayTracing.reflections`: the sharp and the glossy image, and the coverage that only exists for the denoiser)
  and the per-pixel **global illumination** (`render.rayTracing.gi` `"perPixel"`) itself: their noisy images are composited into the picture as the
  kernels wrote them (the denoiser's passes are not recorded and its histories are freed), and Ray Reconstruction denoises them together with the rest of the frame, using
  the guides below. The **ray traced AO and the shadows keep the engine's denoiser**: they are visibility, not radiance: the AO is a darkening multiplied into the picture and the shadow mask is read by the lit pass, both before the upscaler,
  so they are not a noisy diffuse or specular light that the network separates from the rest, and its guides have no input for them. The decision is made once per frame, before the ray traced passes are recorded, from the same
  conditions the frame is drawn with (the setting, the machine, linear colour, no dynamic resolution, a perspective camera, DLSS as the vendor, the
  camera the upscaler resolves, no final pass); `render.ray_tracing` `denoiser` says what it was in the last frame (`reflections` and `gi`:
  `"rayReconstruction"`, `"engine"` or `"off"`, and a `reason` when Ray Reconstruction was asked for and does not take a signal). The
  per-pixel GI also stays with the engine on a device that cannot filter 32-bit float images (the lit meshes then read the denoiser's 16-bit one).
  Only a frame that was decided "take" and that DLSS then draws with Super Resolution (the evaluation was refused, so it fails once and stays off for the run) shows its signals
  noisy, once; the next frame is the engine's denoiser from a history that starts again (its first frame is a "fresh" one), and Ray Reconstruction stays off until the game is started
  again (switching `render.upscaler.rayReconstruction` off and on does not bring it back). A frame that was handed the signals and was drawn without Ray Reconstruction with no refusal
  behind it (the decision and the frame disagreed once) keeps them with the engine's denoiser until Ray Reconstruction has drawn 8 frames in a row that the decision would have
  given the signals to, and then takes them again (a frame where it did not draw starts the count over). `denoiser` says `"off"` for a signal the last frame did not trace on any camera
  (on none of the cameras: a camera with no prepass, a refused kernel), not `"engine"` (before the first frame it says `"engine"`), and its `reason` tells it (also a terrain or impostor G-buffer shader that did not compile: the guides keep constants for it). A provider that fails a frame for good keeps the signals with the engine for the rest of the run, and the reason says so. With Ray Reconstruction off, or on and no reflections or GI traced, nothing changes: no
  extra pass, no extra image. The thin G-buffer for the guides is asked only by the camera the upscaler resolves (a split screen or several cameras are not jittered, so none asks).
- **The guides.** With Ray Reconstruction on, a pass (`shaders/upscale_rr.glsl`, "upscale-rr-guides") makes four images at the render
  size from the depth and normal prepass and the thin G-buffer (a draw for the normal, the roughness and the depth, a draw for the two albedos; two clears for the albedos when the GPU makes no G-buffer); they are made only on the
  frames that use Ray Reconstruction, never for Super Resolution. They are tagged with the colour in, the motion vectors and the colour
  out that Super Resolution takes, and a depth of their own:

  | Buffer | What the engine gives | Approximation |
  |---|---|---|
  | normals and roughness (`NormalRoughness`, packed: roughness in `w`) | the prepass normal turned into **world space** with the camera's axes (a pixel with no mesh, the sky, gets a normal facing the camera) | roughness is the material's roughness from the thin G-buffer where a mesh was drawn (a mesh with a custom or layered material writes its mesh renderer's own roughness), the constant 0.5 elsewhere |
  | diffuse albedo (`Albedo`) | the thin G-buffer's albedo times (1 - metalness) where a mesh was drawn | the constant 0.5 grey where none was |
  | specular albedo (`SpecularAlbedo`) | the thin G-buffer's mix(0.04, albedo, metalness) where a mesh was drawn | the constant 0.04, the reflectance of a dielectric at normal incidence, where none was |
  | depth (`Depth`) | **hardware depth**: clip z / clip w of the camera's unjittered projection (0..1 growing with the distance, 1 for the sky), computed from the prepass's view distance | none; it is not the depth Super Resolution reads (the prepass's d / (d + 1)), because Ray Reconstruction rebuilds the view position from the depth and the matrices it is told, and the two must agree |
  | motion vectors | the same image as Super Resolution | none |
  | specular hit distance (`SpecularHitDistance`, optional) | only while the ray traced reflections go to Ray Reconstruction: the distance the reflection rays travelled, from the reflection image's alpha: the mean over the rays of the pixel that hit a surface (the one mirror ray of a smooth pixel, or up to `raysPerPixel` glossy rays), handed over raw, in world units, with a floor of 0.0001 for a hit; 0 for a pixel not traced and for a pixel whose rays all left the scene. Made by a small pass ("upscale-rr-hit", made when the first frame that needs it is planned) into an R32F image | none; without it Ray Reconstruction still works, with less to steer the reflections' filtering by. If the pass's shader does not compile on a device, the guide is left out (one warning, `denoiser.reason` says so) and everything else of Ray Reconstruction stays |

  The G-buffer (the engine's design notes, repository only, not in the binary) is drawn only while Ray Reconstruction is on and runs as an extra pass over the opaque meshes at the render size; a GPU that cannot make it, and a camera whose images are not the render size, keep the constants. The specular motion vectors are not given (Ray Reconstruction takes them as optional: the virtual motion of a reflection is not computed, and the hit distance is the only reflection guide). The normal space the
  network expects (world or view, and the sign of the axes) is not verified on hardware: the engine sends world-space normals and the
  camera's world-to-view and view-to-world matrices, as NVIDIA's integration guide describes; if the picture shows lighting that
  follows the camera, the space is the thing to check first.
- **The options and the constants.** The options set each frame (the camera moves them): the mode of the quality (the same ratios as Super
  Resolution), the output size, packed normals and roughness, HDR colour, and the camera's `worldToCameraView` and `cameraViewToWorld`.
  The constants (frame token as for Super Resolution) now carry the camera's real matrices: the projection, its inverse, the
  clip-to-previous-clip and previous-clip-to-clip matrices (from the camera of the frame before; a cut resets the history), the camera
  position and axes, the near and far planes and the vertical field of view. The sharpness and the auto exposure of the settings are
  ignored by Ray Reconstruction.
- **When it draws as Super Resolution.** Ray Reconstruction does not support a dynamic resolution, needs linear HDR colour and a
  perspective camera. A frame where one of those fails draws with Super Resolution (the history starts again when the feature changes),
  and the reason is logged once. A machine that cannot do it (not an NVIDIA RTX GPU, no Streamline setup, the plugin missing, another
  backend, a driver that refuses it) draws as Super Resolution for the whole run. A frame that Streamline refuses (the options, the tags
  or the evaluation) draws as Super Resolution too, and Ray Reconstruction stays off for the rest of the run (fail once, stay off).
  `render.supports` with `{"feature":"dlssRayReconstruction"}` says the reason (`render.upscaler` always reports the setting you
  chose, not what drew).
- **The cost.** Ray Reconstruction is a larger network than Super Resolution (NVIDIA publishes no figure for a given GPU): expect a
  higher cost per frame than Super Resolution at the same size, and four more render-size images (one RGBA16F, one R32F, two RGBA8) with the
  guides pass, and a fifth (R32F, the hit distance, one more small pass) while the ray traced reflections go to it. Handing the reflections and the GI to Ray Reconstruction saves the engine's
  denoiser (two signals and a coverage for the reflections, one for the GI: a guide, a temporal and an a-trous pass each, and their histories) and moves that work into the network, whose cost is not
  published: measure the two ways on your GPU. Measure it with `perf.measure` on your GPU. The four guide images are kept for as long as the setting is on and the machine
  can run it: a frame that cannot use them (a dynamic resolution moving the render size, a frame with a final pass) draws as Super
  Resolution and does not free them, so they are not made again at every step. They are freed when the setting goes false, when the
  machine or a frame refuses Ray Reconstruction, or when another upscaler draws.
- **Not tested.** The tests use a fake Streamline (feature switch, the seven tags and their order, the options and matrices sent, the
  fall backs, device loss); no NVIDIA RTX hardware was available, so the picture is unseen. The G-buffer images are tested on every GPU the
  tests run on (known materials read back), and the two guide programs are built by a test on any GPU, but the guides pass itself (and the
  albedos it makes) has been run only with Ray Reconstruction on, which needs NVIDIA hardware. The ray traced signals' part is tested on the RecordingDevice with a fake provider (the
  denoiser's passes are absent when it draws and present when it does not, the hit distance image and pass, the fallback frame and the reset history, the AO's passes unchanged)
  and the tag of the hit distance (buffer 42, eighth after the seven) with the fake Streamline: **never run on NVIDIA hardware**, so how much cleaner the reflections and the GI are, whether the
  network reads the hit distance as the engine writes it (world units, 0 for no hit) and the real cost are unseen.
- **Checked against NVIDIA's header** (`sl_dlss_d.h` and `sl_core_types.h` of Streamline 2.14, read on the web, not copied): the feature
  id 1001, the GUIDs of `DLSSDOptions` and `DLSSDOptimalSettings`, the buffer ids (albedo 7, specular albedo 8, normals and roughness 14,
  specular hit distance 42) and the 224-byte layout of `DLSSDOptions` (a `static_assert` checks the member offsets). Not checked: how the
  real plugin reads them.

## DLSS hardware checks

What the tests cannot say (they use a fake Streamline) and a machine with an NVIDIA RTX GPU must, before DLSS is called done:

1. **D3D12:** the `IDXGIFactory` that `slUpgradeInterface` returns keeps the right reference count through Streamline's proxy (the device
   and the swapchain live to the end, and exit does not crash or leak a reference).
2. **Vulkan on a machine with an AMD or Intel GPU first and an NVIDIA one second** (a laptop): the NVIDIA GPU is chosen and DLSS runs, and
   on a machine with only a non-NVIDIA GPU the device is made normally after `slShutdown` (no crash on the first frame, no Streamline lines).
3. **Registration:** a build with `FA_STREAMLINE_APP_ID` and `FA_STREAMLINE_PROJECT_ID` set to NVIDIA's registration of the game starts as
   it does without them, and the id FactorIA ships with (no NVIDIA application id, a GUID that is not registered) is accepted by `slInit`.
4. **Constants:** `slSetConstants` takes the header's "not set" values (FLT_MAX for the camera, eInvalid and eFalse for the flags) in the
   frames of Super Resolution and gives no missing-input or duplicate-constants error with frame generation on.
5. **The reactive mask:** a scene with particles looks cleaner (less ghosting) with the mask than without it, and the `R8` image is
   accepted as `BiasCurrentColorHint` on D3D12 and Vulkan.
6. **Ray Reconstruction:** the picture is right with world-space normals (lighting does not follow the camera), the plugin loads only
   with the project setting on, and a run with the setting off never loads `sl.dlss_d.dll`.
7. **Frame generation on the same device** (docs/FRAME_GENERATION.md) with Super Resolution and then with Ray Reconstruction.

## Intel XeSS

The `xess` mode. Needs XeSS 3.0 or newer: `libxess.dll` for D3D12 and Vulkan on any GPU, `libxess_dx11.dll` for Direct3D 11
(Intel Arc only: on another GPU the reason says to run the game on D3D12 or Vulkan). On Vulkan XeSS asks for instance and device
extensions and device features (`xessVKGetRequiredInstanceExtensions`, `...DeviceExtensions`, `xessVKGetRequiredDeviceFeatures`):
the engine registers a device hook that loads the library before the instance exists, asks it and adds what it says to the device
(an extension the driver lacks, or a feature structure the hook does not know, makes the hook mark XeSS unavailable and the reason
says which). The probe reads what the device was granted, so a device made without them says so with the names. The library is
probed once (it must load, export every function of the backend and answer a version of 3.0 or newer).

One XeSS context is made per device. It is initialised again (the GPU is waited for first) only when the output size, the quality
or the input format changes, or when the render size leaves the range `xessGetOptimalInputResolution` gives for the quality (its
minimum and maximum). A library without that export keeps the old rule: any render size change. It is never initialised per frame,
and a size inside the range only changes the velocity scale. The context is also made again after the device was made again (the
engine's device generation counter changes, which an address cannot tell). While it is made again the probe is not blocked: the
library snapshot and the context have separate locks.

The quality is the nearest XeSS setting to the upscale ratio (1.3, 1.5, 1.7, 2.0, 2.3, 3.0; the five names of `quality` land
exactly), and a dynamic resolution that wobbles near a boundary keeps the setting it has (and inside the range, the quality of the
context). A render size outside the range of the setting in use, when the nearest setting is that same one, cannot be helped by
initialising again: XeSS is off for the rest of the run, with "the render size WxH is outside XeSS's input range AxB..CxD for
quality Q" as its reason (the picture is not cut or stretched to fit), and the usual fallback draws; a new `render.upscaler.quality` in
factoria.json takes effect at the next start. The engine passes its own render size, the jitter, the
exposure and the reset flag (a cut, a resize or a frame after a failure), the responsive mask (an empty one when no item asked for a
reactive mask) and an output image made with storage usage. The depth and the motion XeSS reads are made by the same preparation
pass as MetalFX's (depth 0..1, motion in UV units, with the velocity scale set to the render size). The context is destroyed,
after the GPU is idle, when the renderer shuts down. A failing call is reported with XeSS's own words ("unsupported device",
"unsupported driver", ...) and the mode is off for the run. Not checked by the tests (they use a fake library): that the real
library's picture is right, which a D3D12 or Vulkan run on a GPU shows.

## AMD FSR 3.1

`fsr` runs on D3D12 and Vulkan on any GPU (never D3D11) and needs `factoria setup fidelityfx` (the loader of the backend and the
upscaler DLL). The probe loads the loader, needs its four exports (`ffxCreateContext`, `ffxDestroyContext`, `ffxQuery`, `ffxDispatch`)
and asks `ffxQuery` which FSR versions it has for this GPU: none is "no FSR provider for this GPU" and a newest below 3.1 is refused;
on Vulkan the device must be 1.1 or newer (FSR asks for no extension the engine does not enable). One FSR context is made per
device, for the largest render size (the base scale), the output size, the quality and the flags. Linear light is `HDR` input,
display values the non-linear colour space, and depth is always inverted and infinite. `dynamicResolution` is set whenever the
dynamic resolution is switched on, whatever its current step, so the first step down does not make a context. The context is made
again (after the GPU is idle) only when one of them changes, never per frame; a render size that moves under the maximum does not
make one. The five qualities are FSR's five modes in order (`native` 0, `quality` 1.5x, `balanced` 1.7x, `performance` 2x,
`ultraPerformance` 3x); the engine feeds its own render size, so the mode only keys the context. Each frame passes: the colour, the
depth (the preparation pass writes FSR's reversed infinite depth, `near / distance`, 0 for the sky), the motion (UV units; the motion
scale is the render size, so FSR reads pixels), the reactive mask when there is one, an output with storage usage, the jitter in
render pixels (clamped to 1), the pre-exposure (1: the scene is exposed before the stage; no exposure texture), the engine clock's
frame time in milliseconds, the camera's near and field of view, sharpening off, and the reset flag (first frame of a context, a cut,
a resize, a frame after a failure). The dispatch is recorded inside the native command section with every image declared (colour,
depth, motion and mask read, the output written). A failing call is reported with FidelityFX's code and last message, and the mode
is off for the run. Not checked by the tests (a fake library): that the real library accepts these resource states and draws the
right picture, which a D3D12 and a Vulkan run with the SDK on an AMD GPU and on another maker's show.

What the loader does for every vendor library (FSR's loader, `libxess.dll`, Streamline): once a library has loaded, its folder is
added to the process's user DLL directories (`AddDllDirectory`, once per folder; if the call fails the engine warns with the Windows
error number). Windows searches those directories only for a load that asks for them (`LOAD_LIBRARY_SEARCH_USER_DIRS` or
`LOAD_LIBRARY_SEARCH_DEFAULT_DIRS`): a DLL the vendor library loads later that way (the upscaler DLL next to FSR's loader) is found
whatever the current folder is, while a plain `LoadLibrary` of a bare name is not helped (the engine does not change the search order
of the whole process); whether each SDK's loads find their neighbours is item 5 of the check list below. A library that fails to
load names the Windows error number of that load (`GetLastError`, read before anything else can change it). The label of the
mode in `render.supports` and the menus is "FSR 3.1+" (the library may offer a newer one), and a debug-level log line says which
versions `ffxQuery` listed. The text of the last FidelityFX message is cleared before each dispatch,
so a failure never quotes the message of an earlier call.

## Hardware check list (M78)

Everything above was written against fake libraries on a Mac: no D3D12, Vulkan, Streamline, XeSS or FidelityFX run has happened
yet. Before a release that advertises the vendor modes, run each of these on a Windows PC (the machine named in brackets) and
write the result next to the item:

1. **FSR, D3D12 and Vulkan, an AMD GPU and another maker's** (`mode` `fsr`, `render.supports` `fsr` true, a picture with motion): the
   picture is right and the debug log shows "FSR: FidelityFX offers FSR ...". The libraries accept the resource states the provider
   declares (colour, depth, motion and mask read; output written).
2. **FSR, the version chain** (`ffxCreateContextDescUpscaleVersion`): the engine does not chain it, so FidelityFX makes the newest
   upscaler it has. If the SDK has an upscaler newer than 3.1 (4.1.2 at the time of writing) and the picture or the inputs differ
   (a different depth or jitter convention), chain the version description with the version the probe found.
3. **FSR, pre-exposure**: the engine sends `preExposure` 1 because the scene is exposed before the stage and there is no exposure
   texture. Compare a dark and a bright scene with and without `FFX_UPSCALE_ENABLE_AUTO_EXPOSURE`; if FSR flickers on exposure
   changes, switch the flag on (a context flag: it also remakes the context).
4. **FSR, dynamic resolution**: with `dynamicResolution` on, the render size going up and down makes no new context (the log shows
   no hitch of a GPU wait per step in the frame times; the flag is set while the dynamic resolution is enabled, not per step).
5. **FSR and XeSS, DLL search**: the game run from another current folder, and from a folder with accents in its path, still
   finds the loader's neighbour DLLs (if not, the SDK loads them with a plain `LoadLibrary`, which `AddDllDirectory` does not
   reach: the fix is `SetDllDirectoryW` around the load), an exported game with the DLLs next to the executable too.
6. **XeSS, Vulkan**: the device is made with the instance and device extensions and features `xessVKGet...` named (the Vulkan
   device was made with them: check with the validation layer or the driver's device report), `render.supports` `xess` is true,
   and the first frame draws. A GPU without one of the extensions says so in the reason.
7. **XeSS, D3D12, Vulkan and D3D11 (Intel Arc)**: the picture is right; the **sign of the jitter and of the motion** (the engine passes
   its own: the motion is previous minus current in UV units, scaled to pixels by `xessSetVelocityScale`; the jitter is in render
   pixels) is the one XeSS wants: a still camera shows no shimmer, a moving one no ghost trail. If one is flipped, flip it at the
   one place that passes it (`render_upscale_xess.cpp`) and say so here.
8. **XeSS, dynamic resolution**: render sizes inside the range `xessGetOptimalInputResolution` gives make no `xessInit` (no GPU
   wait hitch in the frame times), a size outside it makes one (or, when the setting stays the same, a refusal that names the
   range), and a library without that export keeps working (it initialises again at every size).
9. **XeSS, device lost and made again**: after a device reset the next frame makes a new context, with no stale handle.
10. **Both, a permanent failure**: force a failing frame (a size the SDK refuses): one warning, the temporal upscaler draws from then
    on, and the depth and motion images the SDK used are given back (the GPU memory of the process drops by two render-size images).

The **menu kit and the editor** list the three modes (DLSS, XeSS, FSR) greyed out with the reason where `render.supports` says no.
