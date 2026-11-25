# Frame generation (M78)

A frame-generation SDK puts a **generated frame between two rendered ones**: the game renders 60 frames per second and the display
shows 120. `render.frameGeneration` is the engine's one setting for the three SDKs (NVIDIA DLSS frame generation, AMD FSR 3 frame
generation, Intel XeSS frame generation). It is off by default, and the swapchain is then the engine's own, as in every earlier version.

```json
{ "render": { "frameGeneration": { "mode": "auto", "minBaseFps": 60 } } }
```

> **State of this build.** This is the seam: the setting, the choice of the provider, the refusals, the `minBaseFps` rule, the hand-off
> of the frame and the readout. **No vendor provider is registered yet**: each of the three arrives in its own package (DLSS through
> Streamline, FSR 3 through FidelityFX, XeSS frame generation), and until then every mode other than `off` is *refused* and
> `render.frame_generation` says which package fills it. Nothing is generated, nothing changes in the picture.

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
4. `framegen`: the provider gets the frame: the picture before the items (`hudless`), the picture with them (`presented`, and
   `hudDrawn` true so the SDK composites the items on its own frames), the render-sized depth and motion of the temporal upscaler, the
   unjittered projection, the matrix from this frame's view to the previous clip space, the jitter, the vertical field of view and the
   frame time;
5. the colour filter, when there is one, after that.

A frame without items has no copy: the picture is its own hudless one. The copy is made only while generation is on and is freed a few
frames after. Known limits: the colour filter (`post` colour-blindness and similar) is applied to the picture with the items and not to the
hudless source; and a frame the provider refuses is reported (`reason`), and the next frame carries a reset so the SDK drops its history.

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
