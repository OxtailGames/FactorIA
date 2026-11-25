# Low latency (M78)

The time from a press to the frame that shows it has two big parts the game can shorten: the frames queued ahead of the display
(the CPU runs ahead of the GPU) and the wait for the display's next refresh. `render.latency` makes the loop **sleep before it reads
the input**, so the input is as fresh as possible when the frame is drawn. It is off by default.

```json
{ "render": { "latency": { "mode": "auto", "boost": false } } }
```

`mode`:

| mode | what runs |
|---|---|
| `off` (default) | nothing: no call, no sleep. The loop is the one of a game without this setting. |
| `auto` | the SDK of the GPU's maker when it is usable: AMD Anti-Lag 2, Intel XeLL, NVIDIA Reflex; else the engine's own pacing. |
| `reflex` | NVIDIA Reflex: Windows, an NVIDIA GPU (GeForce GTX 900 series or newer, driver 456.38 or newer), Direct3D 12 or Vulkan, with NVIDIA Streamline installed (`factoria setup streamline`). |
| `antilag2` | AMD Anti-Lag 2: Windows, an AMD Radeon GPU, Direct3D 12 or Vulkan. Part of the Radeon driver: nothing to install. |
| `xell` | Intel XeSS Low Latency: Windows, Direct3D 12, any GPU, with the XeSS SDK installed (`factoria setup xess`). |

`boost` keeps the GPU clocks up while the game waits, for less latency at more power. XeLL and Reflex (Low Latency Boost) have it; Anti-Lag 2 and the
engine's own pacing ignore it.

The setting is read and changed with the command `render.latency` (`{"mode":"antilag2"}`; no argument reads it). The project file
sets it at start; the command changes it while the game runs (the SDK is started or stopped at once). A wrong name fails with the
valid values and a "did you mean", and changes nothing.

## Where to set it

- **Project file:** `render.latency` in `factoria.json`, or the command `project.graphics {"latency":{"mode":"auto"}}` (it writes only that key).
- **Editor:** View > Graphics, group **Low latency**: the **Mode** combo (off, auto, reflex, antilag2, xell), a **Boost** checkbox and a line
  that says what the mode does on this machine. A mode that `render.supports` says cannot run here (`reflex`, `antilag2` or `xell`, with the
  row's reason) is greyed out in the combo and its reason is the tooltip; **Boost** is greyed out for the modes without one (off,
  antilag2). **Save** writes `render.latency` (removed again when the mode is off with no boost), **Revert** reads the file. A project that
  names a mode this machine cannot run still opens: the line shows the reason and that a run uses the engine's own pacing. Only a run of the
  game paces, so there is nothing to preview in the editor's viewport; the Profiler shows the input-to-present time of a run.
- **Menu kit** (`docs/MENUS.md`): the third page of the options' Graphics tab (Low latency) has a row of buttons (`gfx_latency_off`,
  `_auto`, `_reflex`, `_antilag2`, `_xell`) and a boost switch (`gfx_latency_boost`, shown for the modes that have one). Like the upscaler
  modes, a mode this machine cannot run is greyed out and named with its reason in the note under the rows. The choice is applied at once with
  `render.latency`, saved in `settings.graphics.latency` (`{mode, boost}`, only the keys the player chose) and applied again at each start.

## What runs: the driver

`render.latency` returns `driver`, the path that really runs:

- `none`: the mode is `off`, or there is nothing to pace (a headless run, the editor's own loop, a game without graphics: the value is
  only remembered).
- `pacing`: the engine's own pacing, which runs when the mode names an SDK that cannot run here (`auto` on a GPU without one, an SDK not
  installed, a backend it does not support, a call that failed).
- `reflex`, `antilag2`, `xell`: that SDK.

`reason` says why the driver is not the one the mode names (the SDK's own words: what is missing and what to do), and `modes` says per SDK
whether it is usable here and why not. A SDK that cannot start never fails the device or the game: the mode reports itself unavailable,
logs one warning, and the engine's own pacing runs. An SDK that failed to start is not tried again until the game restarts or a new
device is made.

The vendor SDKs are **Windows only** (the code of the other systems is built and tested with fakes). `render.supports` has the rows
`reflex`, `antilag2` and `xell`; each answers with the reason when it is false.

## The engine's own pacing

Where no SDK runs, the engine sleeps itself. It needs a game window that is presented to (not a headless run, not the editor), vsync on,
no `window.frameCap`, a continuous render mode and a display refresh rate it knows (the platform's, or the estimate of
UPSCALING.md, "The display's refresh rate"); otherwise it adds no sleep. It measures how long the frame's work takes (from the end of the
sleep to the start of the present step, smoothed: a longer frame counts at once, a shorter one slowly) and starts the next frame so that the
work ends about one refresh interval after the last present returned, with a 15% and 1 ms margin. The sleep is a `sleep_for` and a
short yield at the end, never above 250 ms. It does not change the simulation: the fixed steps are the same, only the moment the
frame starts moves. The time spent in the sleep (the engine's or the SDK's) is waiting, not work: the profiler lists it as its own zone
`Latency` (while a driver runs) and not inside the Platform system's time.

## The markers

Each SDK is fed the same points of a frame, with the id of the present that will show it (`PresentEvent::frame` of the device hooks):

1. before the input: the sleep call of the SDK (`Sleep` of XeLL, the input stage of Anti-Lag 2 on Vulkan, the delay of Anti-Lag 2 on
   Direct3D 12) and the simulation start;
2. the input sample (after the platform has read the input, `platform.frame()`);
3. the end of the simulation (scripts, physics and animation are done, before the scene is drawn);
4. the start of the render submit (the frame is recorded);
5. the start of the present step. It is marked before the window's image is acquired, because the acquire can wait for the display
   (Direct3D 12 waits for the swapchain's frame-latency object), and that wait is not the frame's work;
6. the end of the render submit: the last pass (the blit to the window) needs the image, so it is submitted after the acquire and the
   end comes after the start of the present step, not before it as the SDKs' numbering lists them (see "Hardware checks");
7. the end of the present call. When the window's image cannot be acquired the frame ends right after the start of the present step
   (the present end is still sent, so the frame's id is closed).

A frame that does not present (the render mode skipped it) gives its id to the next one. With the mode `off` every one of these
points is one branch and calls nothing.

## AMD Anti-Lag 2

- **Direct3D 12:** the driver's own interface, made from `amdxc64.dll` (already loaded in the game's process by the Radeon driver) with
  `AmdExtD3DCreateInterface`. The engine sends the state off at the start, on and off when the mode changes, and `UpdateAntiLagState`
  with no data before the input of each frame. Direct3D 12 takes no markers.
- **Vulkan:** the device extension `VK_AMD_anti_lag`, asked for when the device is made, on an AMD GPU, on Windows (a device hook; the
  extension is requested whatever the mode, so a mode changed later works). The input stage is sent at the sleep
  point and the present stage at the present-start marker (before the image is acquired), with the same frame index.
- **Direct3D 11** is not supported: the mode says so and the engine's own pacing runs.
- The driver decides the delay; `boost` has no meaning.
- Needs an AMD driver that has the feature; the reason names what the driver did not answer.

## Intel XeLL

`libxell.dll` (installed next to `libxess.dll` by `factoria setup xess`, version 1.0 or newer) on Direct3D 12 only. One context is made
for the device, `xellSetSleepMode` says low latency (and boost), `xellSleep` runs before the input and `xellAddMarkerData` gets the
markers above. On Vulkan and Direct3D 11 the mode is unavailable and says so. Intel XeSS frame generation (FRAME_GENERATION.md) cannot run
without XeLL, so XeLL also runs while it does, whatever `render.latency` says (the readout says "XeLL runs because XeSS frame generation needs it").

## NVIDIA Reflex

Reflex is reached through NVIDIA Streamline, the runtime that also draws DLSS (UPSCALING_VENDORS.md, "NVIDIA DLSS Super
Resolution"): `factoria setup streamline` installs its DLLs (`sl.interposer.dll`, `sl.reflex.dll`, `sl.pcl.dll`), and the engine
asks Streamline for the Reflex and PC latency plugins whenever it starts it, because the latency mode can change after the device
is made. The engine ships no NVIDIA code.

- **Where it runs.** Windows, an NVIDIA GPU, Direct3D 12 or Vulkan: Streamline has to take part in making the device, which the
  engine's device hooks do on those two backends only (Direct3D 11 says so in the reason). Streamline must have started with the
  device: a game that installed it after it started says "restart the game". The driver has to offer Reflex Low Latency
  (`slReflexGetState`); an older one says what to update.
- **What it does.** At the start Reflex is set off; `reflex` (or `auto`) sets Low Latency and `boost` sets Low Latency Boost, with
  no frame limit (the driver decides). `slReflexSleep` runs once per frame before the input is read, and each marker of "The
  markers" goes to `slPCLSetMarker` with the frame's token, except the input sample (its PCL marker is deprecated: Reflex finds
  the input itself). Reflex, DLSS and DLSS frame generation share the token of the frame, so a game that uses them gives
  Streamline one frame to follow. Turning the mode off sets Reflex off again, **unless DLSS frame generation runs**: it cannot
  generate without Reflex's markers, so the engine keeps Reflex on (Low Latency, no boost; `reflex`, and `auto` on an NVIDIA GPU,
  keep their `boost`) while it runs, whatever the mode, and `render.latency`'s `reason` says "NVIDIA Reflex is on because DLSS
  frame generation needs it" (only while Reflex runs: when it failed to start the reason names why, and says nothing of the sort).
  The mode itself does not change, and the state before comes back when frame generation stops (FRAME_GENERATION.md, "NVIDIA DLSS
  frame generation"). Without the PC latency plugin Reflex still sleeps, only the markers are not sent, and the engine logs one
  warning at the start that says so (it is not repeated per frame). Each refusal names its feature: a hint about the Reflex plugin
  is not given for a PCL call, nor the other way round.
- **When it stops.** A refusal of any call logs one warning and the frame goes on; once the device is destroyed the provider calls
  Streamline no more (its library shuts down with the device).
- **The report.** `render.latency`'s `vendor` has `source` `Reflex`, `frames` (how many of Reflex's last frames it measured),
  `lastFrameId`, the time from the start of the simulation to the end of the present of the last frame and on average
  (`lastSimulationToPresentMs`, `avgSimulationToPresentMs`) and `avgGpuFrameMs`, in milliseconds of Reflex's own clock. The report
  is read on the thread that runs the frame (the profiler's); a call from another thread answers `null`, because Streamline's
  state calls are not thread safe.
- **What NVIDIA asks of a game that ships Reflex or DLSS** (the license of the NVIDIA RTX SDKs; `factoria setup streamline` shows
  it and asks for acceptance; UPSCALING_VENDORS.md, last item of "NVIDIA DLSS Super Resolution"): notify NVIDIA before the game's
  commercial release (<https://developer.nvidia.com/sw-notification>), credit NVIDIA and show its marks.
- **Known limit.** Streamline loads its Reflex and PC latency plugins before the device exists, so they are requested whatever
  `render.latency` is at the start (the mode can be changed in the game's settings afterwards). Likewise the Vulkan extensions
  Reflex needs are asked for with the mode `off`. Gating them on the setting would break that switch; it needs a hardware check
  (an RTX and a GTX).
- **Not checked by the tests** (they use a fake Streamline): that the real library takes the engine's declarations as they are and
  that the latency gets shorter; that needs a machine with an NVIDIA GPU.

## Hardware checks

The tests use fake SDKs; these need a machine with the hardware:

- **Marker order (Reflex's PC latency markers, XeLL).** A frame sends `PresentStart` before `RenderSubmitEnd` ("The markers", points 5
  and 6), while the SDKs number the markers `RenderSubmitEnd` (3) before `PresentStart` (4). Check that PCL (Reflex's latency report
  and the overlay's numbers) and XeLL's report (`render.latency`'s `vendor`) still measure the frame, and that neither drops the
  frames or reports a negative or zero render-submit time. If one does, the render-submit end has to be sent before the acquire.
- **Anti-Lag 2 on Vulkan (an AMD GPU).** The present stage (`VK_AMD_anti_lag`) is sent at `PresentStart`, before the acquire and the
  blit, and not right before `vkQueuePresentKHR` as AMD's sample does. Check that the delay still shortens the latency (the readout of
  `render.latency` against `off`) and that the validation layer has no complaint about the stage order.
- **Reflex without the PC latency plugin, Reflex on a GTX and an RTX** (see "NVIDIA Reflex", "Known limit").

## What the number is

The profiler (`perf.profile`, `play.report`'s `profile`, the editor's View > Profiler) shows **input to present**: the time from the
input sample to the end of the present call, in milliseconds, per frame: `avgMs`, `p95Ms` and `maxMs` over the frames measured. It is
what the CPU sees: after the present call the frame still waits for the display's refresh, so this is a measure to compare settings
(`off` against `auto`), not the photon latency of a screen. `render.latency` returns the same in `report` (`lastMs`, `avgMs`, `p95Ms`,
`maxMs`, `samples` over the last 120 frames) and, when the SDK reports its own times (XeLL and Reflex: the time from the start of the simulation to
the end of the present, from its own clock), `vendor`.

No frame is measured while the driver is `none`; `profile.latency.reason` says why.

## Limits

- Windows is where the SDKs are; every other system runs the engine's own pacing (a window, vsync on).
- The swapchain's own frame-latency wait (two frames in flight on Direct3D 12) stays as it is: the engine has no runtime call to change it.
- A press is shown on the frame after its sample at the soonest; a game that already holds its frame time to the display's refresh with
  few frames queued gains less than one that runs ahead.
