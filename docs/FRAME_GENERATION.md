# Frame generation (M78)

A frame-generation SDK puts a **generated frame between two rendered ones**: the game renders 60 frames per second and the display
shows 120. `render.frameGeneration` is the engine's one setting for the three SDKs (NVIDIA DLSS frame generation, AMD FSR 3 frame
generation, Intel XeSS frame generation). It is off by default, and the swapchain is then the engine's own, as in every earlier version.

```json
{ "render": { "frameGeneration": { "mode": "auto", "minBaseFps": 60 } } }
```

> **State of this build.** The seam (the setting, the choice of the provider, the refusals, the `minBaseFps` rule, the hand-off of the
> frame and the readout) and **the `xess` provider** (Intel XeSS frame generation, below) are in. The `dlss` and `fsr` providers arrive in
> their own packages: until then those two modes are *refused* and `render.frame_generation` says which package fills each. The `xess`
> provider is written from the SDK's public headers and tested against fake libraries; **it has not been run on an Intel GPU**.

`mode`:

| mode | what runs |
|---|---|
| `off` (default) | nothing. No SDK is loaded, the swapchain is the engine's own. |
| `auto` | the SDK of the GPU's maker: NVIDIA `dlss`, AMD `fsr`, Intel `xess`. A GPU of another maker (Apple, an unknown one) is refused, with the reason. |
| `dlss` | NVIDIA DLSS frame generation: Windows, Direct3D 12 or Vulkan, an RTX GPU, through Streamline (`factoria setup streamline`). |
| `fsr` | AMD FSR 3 frame generation: Windows, Direct3D 12 or Vulkan, any GPU, FidelityFX (`factoria setup fidelityfx`). |
| `xess` | Intel XeSS frame generation: Windows, Direct3D 12, an Intel Arc GPU (`factoria setup xess`). |

`minBaseFps` (a whole number of 0 to 1000, default 60) is the frame rate the game **renders** at, not counting generated frames, below
which generation switches off: a generated frame between two slow ones adds delay and shows artefacts, so the display is better left to
the rendered frames. 0 never switches off for a low frame rate.

## What it needs

Generation runs only when every line holds; `render.frame_generation` returns `state: "refused"` and a `reason` that says which one
fails and what to change:

- a **game window** on Direct3D 12 or Vulkan (the engine's own backends). The editor's own loop and a headless run never generate;
- the provider's **SDK** installed and this GPU able to run it (`modes` of the command says it per SDK);
- the **temporal upscaler**: generation reads the depth, the motion and the jitter of the upscaler's frame, so `render.upscaler` must
  run the stage (a render scale below 1, `window.renderScale` or the quality of a vendor upscaler) with one full-viewport camera. A game
  drawn at render scale 1 has no such frame and is refused with that sentence;
- the **start of the run**: a provider takes part in making the window's swapchain (it makes it or wraps it), and that happens when the
  game starts. A game started with `mode: "off"` therefore cannot turn a provider on while it runs (the reason says "restart"), while a
  game started with a provider can switch it off and on again with the command. Set `render.frameGeneration` in factoria.json for the
  game to start with it.

An SDK that cannot start is not tried again until the game restarts (one logged warning, never a device failure), and the reason is
kept.

## The command

`render.frame_generation` reads the setting (no argument) or changes it (`{"mode":"auto"}`, `{"minBaseFps":45}`; the keys not given are
kept). A wrong name fails with the valid values and a "did you mean", and changes nothing. It returns:

- `mode`, `minBaseFps`: the setting;
- `provider`: what runs (`none`, `dlss`, `fsr`, `xess`);
- `state`: `off`, `refused`, `measuring` (a provider is ready and the frame rate has not been measured over a full window yet), `paused`
  (the base frame rate is below `minBaseFps`) or `active`;
- `reason`: why the state is not `active` (the SDK's own words where it has them);
- `modes`: per SDK `{available, reason, setupId}`, where `setupId` is what `factoria setup <id>` installs;
- `changed`, and `report`: the readout below.

## XeSS Frame Generation

Mode `xess` (or `auto` on an Intel GPU): Intel's XeSS frame generation on Windows, Direct3D 12, an Intel Arc GPU. `factoria setup xess`
installs `libxess_fg.dll` and `libxell.dll` (XeSS 3.0.2, next to `libxess.dll`); the engine ships none of Intel's code and loads the two
libraries at run time. **Not tested on Intel hardware**: it is written from the SDK's headers and tested against fake libraries, so what
the real swapchain does with the engine's depth and motion (the depth convention, the projection) is for a machine with an Arc GPU to
confirm.

- **The swapchain.** XeSS-FG is a proxy swapchain: the library makes the window's swapchain itself and presents the rendered and the
  generated frames in order. The engine hands it the window's description when the game starts, which is why `render.frameGeneration`
  must be set before the game starts (see "What it needs"). The provider asks for no interface composition (`uiMode` none): the screen-space
  items are in the picture XeSS-FG interpolates.
- **XeLL runs with it.** XeSS-FG needs Intel XeLL (low latency) and cannot run without it, so **XeLL starts whenever XeSS frame
  generation runs, even when `render.latency` is `off`** (the setting itself is untouched; `render.latency` and the profiler's latency
  line say that XeLL runs because of frame generation). XeLL's context is shared, so choosing `xell` for `render.latency` as well uses
  the same one. The frame ids XeLL is given are the present ids XeSS-FG is tagged with. A machine without `libxell.dll` is refused with
  "run `factoria setup xess`".
- **What each frame gives it.** The depth and the motion of the temporal upscaler's frame (copy-source state, this frame only, at the
  render size), the camera's view and projection matrices (unjittered), the jitter, the frame time, and a history reset after a camera
  cut.
- **When it says no.** `render.supports` has the row `xessFrameGen` and `render.frame_generation` the reason: not an Intel GPU, not
  Direct3D 12, not Windows, the SDK or XeLL not installed (`factoria setup xess`), a driver too old for the swapchain API, or a failure
  earlier in this run. A call of the SDK that fails while the game runs is logged once with its name and result, and XeSS frame generation
  stays off until the game restarts (it never fails the device).
- **Known limit.** The game's mode is not told to the swapchain hook: on an Intel GPU with both libraries installed, a game started with
  any mode other than `off` gets XeSS-FG's swapchain, also when the mode was `dlss` or `fsr` (which an Intel GPU refuses anyway).

## The minimum base frame rate

The controller measures the base frame rate over the last 30 rendered frames and decides once per frame:

- generation turns **on** when the rate reaches `minBaseFps`;
- it turns **off** when the rate falls below `minBaseFps`;
- after it was turned off for a low rate it turns on again only at **10% above** `minBaseFps` (60: back on at 66);
- two switches are at least 90 rendered frames apart, so a rate that hovers at the limit does not flap.

The first 30 frames after a start only measure (`state: "measuring"`). The rate is measured with the engine clock of the frame, not the
display's refresh, so it is the game's own, whatever the generated frames add.

## The picture the SDK is given

The SDK generates from the game, not from the menus: text between two frames would smear. When the frame has screen-space items (UI,
text, debug overlay) they are drawn after the upscaler, so the output stage is:

1. `upscale`: the temporal upscaler fills the output picture;
2. `framegen-hudless`: a copy of that picture (the one the SDK generates from);
3. `hud-over-upscale`: the items are drawn over it, at the output size;
4. `output-color-filter`, when the camera has a colour filter (colour-blindness and the like): the picture with the items, filtered, is the
   picture the window shows. The copy of step 2 is drawn through the same filter, so both pictures the SDK gets are graded alike (a generated
   frame between two graded ones is graded too: no colour flicker);
5. `framegen`: the provider gets the frame: the picture before the items (`hudless`), the picture the window shows (`presented`: with
   the items, filtered when there is a filter, and `hudDrawn` true so the SDK composites the items on its own frames), the render-sized depth and
   motion of the temporal upscaler, the camera (unjittered projection, near and far planes, field of view, position and axes, view matrix,
   the matrix from this frame's view to the previous clip space, the jitter), the colour description (format, output encoding, HDR headroom) and
   the frame time.

A frame without items has no copy (and no filter pass: the filter is part of the render-sized picture then): the picture is its own
hudless one. The copy is made only while generation is on and is freed a few frames after. A frame the provider refuses is reported
(`reason`), and the next frame carries a reset so the SDK drops its history; so does a camera cut, a change of the output size, a new or
resized window swapchain and the end of a pause.

## The readout

`render.frame_generation` returns `report`, the engine's profiler shows it, and `perf.profile` / `play.report` carry it as
`profile.frameGeneration`:

| field | meaning |
|---|---|
| `provider`, `state`, `generating` | as above; `generating` is true while generation is on this frame |
| `baseFps` | frames the game renders per second over the last 30 frames (0 until measured) |
| `presentedFps` | the same plus the frames the SDK generated in that window (the SDK's own counter) |
| `renderedFrames`, `generatedFrames` | since the controller started or was reset |
| `reason` | why nothing runs, or why generation is paused; empty while active |

The editor's Profiler window shows the same line. In a run with no window (a headless `perf.profile`, an automatic run) the block says
`state: "off"` or `"refused"` and why, with zero frames; nothing is invented.

`render.supports` has the rows `dlssFrameGen`, `fsrFrameGen` and `xessFrameGen` with their Direct3D 12 and Vulkan keys (XeSS: Direct3D 12
only); a row is false with the provider's reason while no provider is there.

## For a provider

The private seam is in `engine/render/src/render_framegen.h`, described in docs/design/ARCHITECTURE_RENDERING_HOOKS.md (repository only, not in the binary), "Frame
generation (M78)": a package that adds an SDK implements `FrameGenProvider` and calls `register_framegen_provider()` once; nothing else
changes.
