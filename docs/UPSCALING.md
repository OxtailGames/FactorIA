# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The **temporal antialiasing**, the **spatial upscaler**, the plain
**stretch** and the **graphics presets** draw today (see below); the temporal upscaler and MetalFX are planned (`render.supports`
says `planned (M76)` for each of them, and a setting that asks for one draws as the best mode that exists).

## The engine-wide upscaler settings

The picture can be drawn at a lower resolution and brought up to the window's. One setting block, three places:

- the project: `"render": { "upscaler": { "mode": "spatial", "quality": "balanced", "sharpness": 0.5 } }` in `factoria.json`
  (schema `schemas/project.schema.json`; a wrong value fails to load with the JSON pointer and a "did you mean");
- a script: `window.upscaler` (read it, or assign an object with any of the three keys; it also reports `effectiveMode` and `scale`);
- a command: `render.upscaler` (no arguments reads; `mode`, `quality`, `sharpness` set and answer the result).

| Key | Values | Default |
|---|---|---|
| `mode` | `stretch` (the window scales the picture), `spatial`, `temporal`, `metalfx` (Apple GPUs), `auto` | `stretch` |
| `quality` | `native` (1), `quality` (1/1.5), `balanced` (1/1.7), `performance` (1/2), `ultraPerformance` (1/3) | `native` |
| `sharpness` | 0 to 1 | 0.5 |

`scale` is the share of the window's size each side is drawn at for that quality. `effectiveMode` is the mode that really
draws, so reading the setting back never lies:

- `stretch` and `spatial` draw as themselves;
- a game with `display.scaleMode` `pixelPerfect` (pixel art) is always `stretch`, drawn with the nearest-texel scaling: a filter
  would blur the pixels it keeps hard (the quality still lowers the size it is drawn at);
- `temporal`, `metalfx` and `auto` draw as `spatial` until their packages land (then `auto` picks the best of
  metalfx, temporal and spatial the GPU can draw, and `temporal` or `metalfx` fall back to the next one down);
- with no renderer (`graphics=false`) `effectiveMode` is what a GPU would draw: `stretch` for a pixel-perfect project, and otherwise
  the same as with a GPU (`spatial` for `spatial`, `auto`, `temporal` and `metalfx` until those draw).

The project's block is applied when the engine starts and again when `factoria.json` changes it.

## The render scale

The game is drawn at `window.renderScale` (0.33 to 1, the player's option) times the `scale` of the quality, never below
0.25. One function does it, so `window.renderScale`, `render.upscaler` and the project's start all agree: `Engine::Impl::apply_render_scale`
(`plan_upscale_scale` in `fa/render/upscaler.h`).

| `window.renderScale` | `quality` | drawn at (of the window's size) |
|---|---|---|
| 1 | `native` | 1: nothing to upscale |
| 1 | `performance` | 0.5 |
| 0.75 | `performance` | 0.375 |
| 0.5 | `ultraPerformance` | 0.25 (1/6 is below the floor) |

The upscale stage is on when that scale is below 1, or when the mode that draws is `spatial` and `sharpness` is above 0: at
scale 1 it is then the sharpen alone (one pass at the window's size, an extra cost the `stretch` mode never has; set
`sharpness` 0 for none). The HUD, the UI and the debug text are drawn after the stage at the window's size, so text stays sharp
(unless a screen-space bloom would make them glow: docs/design/ARCHITECTURE_RENDERING.md, "Upscale stage (M76)", repository only, not in the binary).
`game.render_stats` reports the size the game is drawn at (`width`, `height`) and the scale it used (`renderScale`);
`window.upscaler.scale` is the quality's own scale. A size held from outside (`--render-scale` of the CLI, the video recorder, a
screenshot's `scale`) is an image that many times the size: it replaces the player's scale and quality and has no stage.

## The spatial upscaler

`mode: "spatial"` (`UpscaleImpl::Spatial`, `engine/render/shaders/upscale_spatial.glsl`) runs two fragment passes, on every
backend (OpenGL, GLES3, WebGL2, D3D11, Metal; never a compute shader):

1. **Edge-adaptive upsample.** Each output pixel reads the 12 texels around it (the 4x4 block without its corners), takes the
   direction of the edge there from the luma gradient, and weighs them with a Catmull-Rom kernel measured in a stretched
   metric: narrow across the edge, long along it. A diagonal stays hard and its stairs are smoothed, which a bilinear
   stretch cannot do. The result is clamped to the lowest and highest value of the four nearest texels, so it never rings past
   the picture's own range.
2. **Contrast-adaptive sharpen** at the window's size, controlled by `sharpness` (0 = none, 1 = the strongest, a negative
   weight of 0.18 on the four neighbours). It shrinks where the local contrast is already high (no halo on a strong edge) and is
   clamped to the range of the five texels it reads.

Both passes work on the colour the post stack left. A linear HDR scene without a final pass holds light that can go far above 1,
which no filter handles without ringing, so there the filters work on `sqrt(c / (1 + c))`, a reversible tonemap close to a gamma
2 curve, and go back to linear light before writing: the picture keeps its colour space and its range. After a final pass (tonemap,
colour grading) and in an sRGB 8-bit scene the values are display values and are filtered as they are.

Costs, at a 1920x1080 window: the edge pass reads 12 texels per window pixel and the sharpen 5; the extra memory is the window-size
image the stage already needs and one more between the two passes (the same format; freed when the stage turns off). `stretch`
is one pass of one read per pixel and no extra image. The first frame after turning the mode on compiles the two programs.
If they cannot compile on a backend (logged once) the stage scales up with the plain copy, so the game is never left without a picture.

| Backend | Spatial | Notes |
|---|---|---|
| OpenGL, GLES3, WebGL2 | yes | fragment passes with `texelFetch` |
| D3D11 | yes | same |
| Metal | yes | same; `metalfx` is a separate mode |
| No renderer (`graphics=false`) | nothing is drawn | `effectiveMode` is what a GPU would draw: `stretch` for pixel-perfect projects, else per the setting |

## Temporal antialiasing

`PostProcess.temporalAAEnabled` switches the `TemporalAA` effect on (off by default; with it off there is no pass, no image, no jitter
and the picture is bit for bit the one without the effect). `temporalAAFeedback` (0.5..0.98, 0.9: the share kept from the frames
before), `temporalAASharpen` (0..1, 0.25), `temporalAAVarianceGamma` (0.5..2, 1: how far the history may stray from the neighbours
before it is clipped) and `temporalAAReactiveScale` (0..4, 1) tune it. Like every effect it is on a camera's own PostProcess or
a volume.

What it does: every frame the camera is shaken by a sub-pixel amount (a Halton sequence of 8 positions, by the engine's frame count,
so a replay is the same). The meshes, the sky and the HDRI move together, so the horizon and the meshes resolve alike; the HUD is
drawn over the finished picture and is not shaken. Two full-screen fragment passes at the **render** resolution (on every backend,
never a compute shader), after the sun shafts and before the depth of field, blend the frame with the camera's history, reproject it to where
each surface was (with the motion vectors of the frame when it has them, else from the depth prepass the effect asks for: nothing else
to switch on), clip it to the colours around the pixel, and sharpen the result. Each camera of a split screen has its own history.
`render.supports {"feature":"temporalAA"}` is `supported` on every GPU backend.

The history is one image per camera in RGBA16F. A GPU that cannot render to half-float images uses RGBA8 and says so once in the log:
colours above 1 are clipped in the history and the depth that tells a surface that was uncovered is not kept, so there is more ghosting
behind moving objects. The history starts again (that frame shows its own picture alone, jittered, and a new history begins) after:

- a **cut**: the camera did not draw the frame before, or the world clock went back or jumped more than 8 ticks (a scene load, a seek);
- a **resize** or a change of the **render scale** (the images have another size);
- a **floating-origin shift** (any rebase: one frame without antialiasing, then it continues);
- a frame the effect did not run for the camera (it was switched off, another camera drew) or another scene (a load or a reload);
- the stack losing the effect (the history is freed).

Changing `temporalAAFeedback`, `Sharpen`, `VarianceGamma` or `ReactiveScale` does not reset it. A fast thing that the reprojection cannot
follow (particles, a flash) is clipped to its neighbours, so it leaves a short trail at most; lower `temporalAAFeedback` for fewer.

Where it does not apply: the cameras of a `CameraView`, a render-target camera and `camera.capture` and the other renders of a scene
that are not a frame of the running game (thumbnails, `capture_world`) are drawn without it (no jitter, no pass, no history); a
screenshot of the running game is the antialiased frame it shows. The editor viewport draws like the
game (it is the same renderer) unless the editor's view bypasses the post stack, and then it has neither the pass nor the jitter. A custom
post pass cannot be placed `before` or `after` `temporalAA`; `before:depthOfField` runs after it.

## Graphics presets

A preset is a quality layer of the renderer, not a change of the game. Each of `low`, `medium`, `high` and `ultra` is a table of
**limits**: the most of each quality knob the renderer will use. A limit only lowers what the scene, the camera's `PostProcess` and
the lights ask for (a scene that asks for 2 shadow cascades under a limit of 4 still draws 2), so `ultra` is the game as its author
made it, and `custom` (no preset, the default) is exactly that too, bit for bit. Nothing is written into the scene, its components or
`factoria.json`: leaving a preset gives the game's own look back. Presets never touch the simulation (the physics, the scripts and
the random numbers do not read them), and the benchmark never runs inside a simulation step.

| Knob | `low` | `medium` | `high` | `ultra` / `custom` |
|---|---|---|---|---|
| `temporalAA` | off | on | on | no limit |
| `ssao` (quality) | off | on (medium) | on (high) | no limit (ultra) |
| `ssr` (steps) | off | off | on (48) | no limit (128) |
| `sunShafts` | off | off | on | no limit |
| `depthOfField` (bokeh discs) | off | on (smooth) | on (bokeh) | no limit |
| `motionBlur` (samples) | off | on (8) | on (16) | no limit (32) |
| `shadowCascades` | 1 | 2 | 3 | 4 |
| `shadowAtlasSize` / `shadowTileSize` | 1024 / 512 | 2048 / 1024 | 4096 / 2048 | 8192 / 4096 |
| `softShadows` (PCSS lights use PCF when off) | off | off | on | on |
| `localShadows` (point and spot) | off | on | on | on |
| `contactShadows` | off | off | on | on |
| `volumetricFog` (quality) | off | on (low) | on (medium) | on (high) |
| `lodDistanceScale` (the distance a level is picked at is multiplied by it, so levels switch sooner) | 2 | 1.5 | 1 | 1 |
| `foliageDensity` / `foliageDistance` | 0.4 / 0.5 | 0.7 / 0.75 | 1 / 1 | 1 / 1 |
| `terrainLodQuality` | 0.5 | 0.75 | 1 | 1 |
| `gi2d` (quality, resolution scale) | off | on (low, 0.25) | on (medium, 0.5) | on (high, 1) |
| `lightScale` (2D light buffer) | 0.5 | 0.75 | 1 | 1 |
| `realtimeGiProbesPerFrame` | 2 | 4 | 8 | 32 |
| upscaler (`mode` auto, `quality`) | `performance` | `balanced` | `quality` | none: the game's own |

The numbers are caps and never rise above what the scene asks for. The table is monotone (every knob of `medium` is at least as high
as `low`, and so on), and a test keeps it so. `graphics.preset` answers the whole `limits` object by knob name.

**What the GPU caps.** A knob for a feature the backend cannot draw is lowered too, with the same status `render.supports` gives:
the volumetric fog needs half-float targets, cascaded and local shadows need 32-bit float targets, and the shadow atlas is never
larger than the GPU's largest texture. Each cap is in the answer's `capped` list as `{knob, wanted, effective, reason}`.

**The upscaler.** `low`, `medium` and `high` also write the engine-wide upscaler (mode `auto`, the quality of the last row,
sharpness 0.5). `ultra` writes none: it leaves the game's own upscaler, so its picture is the one of `custom` bit for bit (a test
compares them pixel by pixel). The setting the game had (`render.upscaler` in `factoria.json`, or what a script or `render.upscaler`
set) is kept, and `custom` puts it back. An upscaler change made while a preset is on (`render.upscaler`, `window.upscaler`) applies
at once, and it also becomes the game's own setting: the keys it names are written over the setting from before the preset (a
change of the sharpness alone keeps the project's mode and quality), and that is what `custom` goes back to. The preset's own
upscaler is not put back by itself: applying the preset again does.

### Commands and scripts

- `graphics.preset {"name": "high"}` applies a preset and answers `{preset, previous, changed, changes, limits, capped, upscaler,
  headless}`, where `changes` lists `{knob, from, to}` for every limit (and the upscaler) that changed. With no arguments it reads
  the preset in force and changes nothing. An unknown name or argument fails with a "did you mean". `headless` is true when the
  engine has no GPU: the preset is stored, nothing is drawn, and nothing is capped.
- `graphics.detect` changes nothing. It reads the GPU (`gpu`: `backend`, `name`, `vendor`, `driver`, `memoryMB`, `unifiedMemory`,
  `software`), runs a short benchmark and answers `{preset, reason, gpu, benchmarkMs, benchmark, device}`: the preset it suggests
  and why. The benchmark draws a fixed scene of its own (about 150 lit meshes, a sun with three cascades and two point lights, at
  960 x 540, read back) once to warm up and five times to measure, and takes the median; `benchmarkMs` is the whole time, normally a
  few hundred milliseconds, and it stops by itself after four seconds. It lifts the current preset while it runs and puts it back.
  It is skipped, and the device tier decides, when there is no GPU or the renderer is a software one (llvmpipe, WARP, SwiftShader).
  A call blocks the frame it is made in: call it once, from a loading screen, never every frame.
- Rule: at most 4 ms for `ultra`, 8 ms for `high`, 16 ms for `medium`, more is `low`; a software renderer is `low`; a phone or tablet
  is capped at `medium` and a handheld at `high`; a device tier of `low`, or a discrete GPU with under 2048 MB, caps at `medium`;
  without a benchmark the tier alone decides (`low`, `medium`, `high`; never `ultra`). `reason` says which rule applied.
- Scripts: `game.graphics.preset()` reads, `game.graphics.preset("high")` applies, `game.graphics.detect()` detects; the results
  are the objects above, and a wrong name throws with the same hint.
- Project: `"render": { "graphicsPreset": "medium" }` in `factoria.json` starts the run on that preset (`custom` is the default and is
  not written). With a preset set there, `render.upscaler` of the same file is what `custom` returns to, not what the preset
  uses. A wrong name fails to load with the JSON pointer `/render/graphicsPreset` and a "did you mean".
- The engine does not save the player's choice: the menu kit's Graphics tab does (below), and a game without the kit saves what it
  wants and applies it at start.

### Menu kit and editor

- **Menu kit.** The options panel of the menu kit (docs/MENUS.md, the Graphics tab) has a second page in its Graphics tab, opened by
  the "Preset and upscaling" button: a **Preset** row (Auto, Low, Medium, High, Ultra, Custom), an **Upscaling** row (Auto and
  each mode, with the modes this GPU does not draw greyed out and the reason shown, read from `render.supports`), the upscaling
  quality, the render scale (0.33 to 1, `window.renderScale`) and the sharpness (only while `window.upscaler.effectiveMode` is not
  `stretch`). Auto runs `game.graphics.detect()` once, keeps its pick in the save and shows it. A preset drives the tab's own
  "quality" row of the screen effects (Low, Medium, High and Ultra pick low, medium, high and high), so the two never disagree. The
  choices are saved in `settings.graphics` (`preset`, `detected`, `upscaler`, `renderScale`) and applied when a scene starts; a save
  from before them loads as it did. Dynamic resolution is not part of this page yet (`gfx_dynamic_slot` is where its row goes).
- **Editor.** View > Graphics edits `render.graphicsPreset` and `render.upscaler` (`mode`, `quality`, `sharpness`) of
  `factoria.json` with Save and Revert; the values are checked by the code that loads the project and the `render.upscaler` command,
  so a wrong one is named with its JSON pointer and a "did you mean", and Save writes only those two keys (a value at its default
  removes its key). It does not preview: press Play after Save, or use the game's own menu, to see a preset or a mode.

## What a game can already ask

`render.supports` with `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution`, or `temporalAA`
(the effect's row). `temporalAA` is `supported`; `spatialUpscaler` answers true on every GPU backend; `motionVectors` answers
true where the GPU can make the image (the depth prepass writes the motion of the meshes, skinned ones of up to 32 joints and
materials with a `vertex()` included, instances, terrain, foliage and impostors, and `render.debug_view {"view":"motionVectors"}`
shows it); the others answer false with the status `planned (M76)` until their packages land.

| Row | Backends | Needs |
|---|---|---|
| `motionVectors`, `temporalUpscaler` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `spatialUpscaler`, `dynamicResolution` | every GPU backend | nothing |
| `metalfx` | Metal only (macOS, iOS) | nothing |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing (RGBA16F history where the GPU can, else RGBA8) |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
