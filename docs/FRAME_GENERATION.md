# Frame generation (M78)

A frame-generation SDK puts a **generated frame between two rendered ones**: the game renders 60 frames per second and the display
shows 120. `render.frameGeneration` is the engine's one setting for the three SDKs (NVIDIA DLSS frame generation, AMD FSR 3 frame
generation, Intel XeSS frame generation). It is off by default, and the swapchain is then the engine's own, as in every earlier version.

```json
{ "render": { "frameGeneration": { "mode": "auto", "minBaseFps": 60 } } }
```

> **State of this build.** The seam (the setting, the choice of the provider, the refusals, the `minBaseFps` rule, the hand-off of the
> frame and the readout) and **all three providers**: NVIDIA DLSS frame generation, AMD FSR 3 frame generation and Intel XeSS frame
> generation (each in its section below). Where one cannot run (not Windows, its SDK not installed, a GPU or driver it does not support)
> its mode is refused with the reason. The providers are written from the SDKs' public headers and tested against fake libraries; **none
> has been run on its maker's GPU yet**.

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
- **Which games get its swapchain.** Only a game started with `xess`, or with `auto` on an Intel GPU; `dlss` and `fsr` leave the window's
  swapchain to their own providers.

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
only); a row is false with the provider's reason while no provider is there or the provider cannot run here.

## NVIDIA DLSS frame generation

DLSS frame generation (DLSS-G) is reached through NVIDIA Streamline, the runtime that also draws DLSS and Reflex (`factoria setup
streamline` installs `sl.interposer.dll`, `sl.dlss_g.dll`, `nvngx_dlssg.dll` and the Reflex plugins; the engine ships no NVIDIA code).

- **Where it runs.** Windows, an **NVIDIA GeForce RTX 40 series GPU or newer**, Direct3D 12 or Vulkan, a recent NVIDIA driver and, on
  Windows, "Hardware-accelerated GPU scheduling" turned on. Streamline answers whether the machine qualifies; when it says no,
  `render.frame_generation` returns `modes.dlss.reason` with Streamline's own words, what it needs and what to update or turn on. Direct3D 11
  never runs it. Streamline loads its plugins before the device exists: the engine adds DLSS frame generation to the list of Streamline's
  features when the game starts with `render.frameGeneration` set to anything but `off` (which is why a game started with `off` cannot turn it
  on later: the reason says "restart the game"). A game with frame generation set to `fsr` on an NVIDIA GPU also loads that plugin; it is not
  used.
- **Reflex is turned on for it.** DLSS-G reads the markers of NVIDIA Reflex in every frame (its status says "Reflex not detected" without
  them), so while this provider runs the engine runs Reflex whatever `render.latency` says: the mode `off` (or the one of another maker)
  becomes `reflex`, `reflex` and `auto` keep their own `boost`. The setting itself is not changed and comes back when frame generation stops
  (`render.latency` says "NVIDIA Reflex is on because DLSS frame generation needs it" in its `reason`). If Reflex cannot start, the frame is
  refused with that reason and nothing is generated. Streamline's Reflex and PC latency plugins must be installed.
- **What it does.** Every frame the engine gives Streamline the camera (`slSetConstants`: the unjittered projection, the matrix to the
  previous frame's clip space, the jitter, the planes, the camera's place and axes; the depth is the reversed infinite one, `near / d`) and the
  tags: the depth and the motion vectors of the render size and, **only when the frame has screen-space items** (UI, text, debug overlay),
  the picture before them (`hudless`). Streamline generates the frame between two rendered ones inside Present, from the picture the window
  shows, which still has the items: with a hudless tag it composites the generated frame without smearing them. No UI colour-and-alpha buffer
  is tagged (the items are in the final picture). It generates **one frame** between two rendered ones (`numFramesToGenerate` is 1;
  the multi-frame generation of the RTX 50 series is not used).
- **The frame rate.** `generatedFrames` is what Streamline reports (`slDLSSGGetState`, once per rendered frame) and `presentedFps` follows. The
  `minBaseFps` rule turns generation off with `slDLSSGSetOptions` (the resources stay allocated, so it comes back at once) and the engine
  gives them back when the provider stops.
- **What refuses a frame.** An orthographic camera (the depth reprojection of DLSS-G is built for a perspective lens; the reason says to use
  a perspective camera or turn frame generation off). A projection that is not a number. A status of Streamline's after the frame went out: a
  picture smaller than the SDK allows (the reason gives the minimum), the swapchain's HDR format, constants Streamline cannot use. The inputs
  of such a frame are still sent, so the next present can recover; the report's `reason` says why and the next frame resets the history.
- **Not checked by the tests** (they use a fake Streamline, and this host has no RTX GPU): that the real library accepts the declarations as
  they are, that it generates and that the motion and depth give no artefacts. Things to look at on a machine with an RTX 40 series GPU:
  whether Streamline refuses the camera constants as a duplicate of the ones the DLSS upscaler sets earlier in the same frame (the engine keeps
  going and logs it once), the colour encoding of the hudless picture against the window's (display-linear in the engine, as `presented`), and
  an orthographic camera (refused today).
- **What NVIDIA asks of a game that ships DLSS** (the license of the NVIDIA RTX SDKs; UPSCALING_VENDORS.md, last item of "NVIDIA DLSS Super
  Resolution"): notify NVIDIA before the game's commercial release, credit NVIDIA and show its marks.

## AMD FSR 3 frame generation

Mode `fsr` (also `auto` on an AMD GPU). It runs on Windows, on Direct3D 12 and on Vulkan, on any maker's GPU, through AMD FidelityFX's frame
generation. `factoria setup fidelityfx` installs the SDK (the engine ships no AMD header or library); it is the same installation the FSR 3.1
upscaler uses (docs/UPSCALING.md, "Vendor upscalers").

How it takes part: FidelityFX makes the window's swapchain. When the game starts with `render.frameGeneration.mode` `fsr` (or `auto` on an
AMD GPU), the engine lets FidelityFX create it: on Direct3D 12 a proxy swapchain that presents the rendered and the generated frames, on
Vulkan the swapchain functions FidelityFX replaces (the device then also asks for three queues: async compute, present and image acquire; the present queue must come from a family that can present to the window, and when none does the swapchain is refused with the reason).
A swapchain can not be taken over later, so changing to `fsr` while the game runs says "restart the game". On the first frame the provider
makes the frame generation context for the display size and the swapchain's format; each frame it tells the swapchain whether to generate, which
picture is the one before the screen-space items, and the frame number, and it hands over the depth, the motion, the camera and the jitter of
the temporal upscaler. The swapchain interpolates when it presents. The context is made again when the display size or the depth flags change,
with the history reset. Below `minBaseFps` generation is turned off and the swapchain presents the rendered frames only. When the game shuts
down, generation is turned off, the presents in flight finish, the GPU goes idle and the contexts are destroyed.

Why `fsr` is refused, in the words of `render.frame_generation`:

- not Windows, or a backend other than D3D12 and Vulkan: the sentence names the backend;
- no library: "run `factoria setup fidelityfx`"; a library that does not load, or lacks an export, says which;
- the library lists no frame generation provider for this GPU or driver: update the driver or install the whole SDK;
- a swapchain FidelityFX could not make (the reason carries its result code): the engine then keeps its own swapchain, so the game still runs
  without generation;
- `auto` on a GPU that is not AMD's takes no part (name `fsr` to use it anyway).

A frame FidelityFX refuses is reported with its result code and the next frame resets the history; nothing crashes the game. Not verified
without an AMD machine: the interpolated picture itself, on each of the two backends.

## For a provider

The private seam is in `engine/render/src/render_framegen.h`, described in docs/design/ARCHITECTURE_RENDERING_HOOKS.md (repository only, not in the binary), "Frame
generation (M78)": a package that adds an SDK implements `FrameGenProvider` and calls `register_framegen_provider()` once (the FSR 3 provider is made with the table); nothing else
changes. A provider that makes the swapchain answers `device_hook_for(mode)` with its hook only for the modes it serves, so an FSR swapchain
is never made when the game asked for `dlss`.
