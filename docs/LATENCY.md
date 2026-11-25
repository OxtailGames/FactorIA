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
| `auto` | the SDK of the GPU's maker when it is usable: AMD Anti-Lag 2, Intel XeLL (NVIDIA Reflex when its provider lands); else the engine's own pacing. |
| `reflex` | NVIDIA Reflex. It arrives with the Streamline provider (M78): until then `render.supports {"feature":"reflex"}` says "arrives with the Streamline provider" and the engine's own pacing runs. |
| `antilag2` | AMD Anti-Lag 2: Windows, an AMD Radeon GPU, Direct3D 12 or Vulkan. Part of the Radeon driver: nothing to install. |
| `xell` | Intel XeSS Low Latency: Windows, Direct3D 12, any GPU, with the XeSS SDK installed (`factoria setup xess`). |

`boost` keeps the GPU clocks up while the game waits, for less latency at more power. XeLL has it (and Reflex will); Anti-Lag 2 and the
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
- `antilag2`, `xell` (`reflex` later): that SDK.

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
sleep to the call that presents, smoothed: a longer frame counts at once, a shorter one slowly) and starts the next frame so that the
work ends about one refresh interval after the last present returned, with a 15% and 1 ms margin. The sleep is a `sleep_for` and a
short yield at the end, never above 250 ms. It does not change the simulation: the fixed steps are the same, only the moment the
frame starts moves.

## The markers

Each SDK is fed the same points of a frame, with the id of the present that will show it (`PresentEvent::frame` of the device hooks):

1. before the input: the sleep call of the SDK (`Sleep` of XeLL, the input stage of Anti-Lag 2 on Vulkan, the delay of Anti-Lag 2 on
   Direct3D 12) and the simulation start;
2. the input sample (after the platform has read the input, `platform.frame()`);
3. the end of the simulation (scripts, physics and animation are done, before the scene is drawn);
4. the start and the end of the render submit (the frame is recorded and sent to the GPU);
5. the start and the end of the present call.

A frame that does not present (the render mode skipped it) gives its id to the next one. With the mode `off` every one of these
points is one branch and calls nothing.

## AMD Anti-Lag 2

- **Direct3D 12:** the driver's own interface, made from `amdxc64.dll` (already loaded in the game's process by the Radeon driver) with
  `AmdExtD3DCreateInterface`. The engine sends the state off at the start, on and off when the mode changes, and `UpdateAntiLagState`
  with no data before the input of each frame. Direct3D 12 takes no markers.
- **Vulkan:** the device extension `VK_AMD_anti_lag`, asked for when the device is made, on an AMD GPU, on Windows (a device hook; the
  extension is requested whatever the mode, so a mode changed later works). The input stage is sent at the sleep
  point and the present stage right before the present, with the same frame index.
- **Direct3D 11** is not supported: the mode says so and the engine's own pacing runs.
- The driver decides the delay; `boost` has no meaning.
- Needs an AMD driver that has the feature; the reason names what the driver did not answer.

## Intel XeLL

`libxell.dll` (installed next to `libxess.dll` by `factoria setup xess`, version 1.0 or newer) on Direct3D 12 only. One context is made
for the device, `xellSetSleepMode` says low latency (and boost), `xellSleep` runs before the input and `xellAddMarkerData` gets the
markers above. On Vulkan and Direct3D 11 the mode is unavailable and says so.

## What the number is

The profiler (`perf.profile`, `play.report`'s `profile`, the editor's View > Profiler) shows **input to present**: the time from the
input sample to the end of the present call, in milliseconds, per frame: `avgMs`, `p95Ms` and `maxMs` over the frames measured. It is
what the CPU sees: after the present call the frame still waits for the display's refresh, so this is a measure to compare settings
(`off` against `auto`), not the photon latency of a screen. `render.latency` returns the same in `report` (`lastMs`, `avgMs`, `p95Ms`,
`maxMs`, `samples` over the last 120 frames) and, when the SDK reports its own times (XeLL: the time from the start of the simulation to
the end of the present, from its own clock), `vendor`.

No frame is measured while the driver is `none`; `profile.latency.reason` says why.

## Limits

- Windows is where the SDKs are; every other system runs the engine's own pacing (a window, vsync on).
- The swapchain's own frame-latency wait (two frames in flight on Direct3D 12) stays as it is: the engine has no runtime call to change it.
- A press is shown on the frame after its sample at the soonest; a game that already holds its frame time to the display's refresh with
  few frames queued gains less than one that runs ahead.
