# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The **temporal antialiasing**, the **spatial upscaler**, the **temporal upscaler**,
**MetalFX** (Apple GPUs), the plain **stretch**, the **graphics presets** and the **dynamic resolution** draw today (see below). A
mode the GPU cannot draw draws as the best mode that exists, and `render.supports` says why.

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
- `temporal` draws as itself where the renderer can (the TAA shaders compiled, histories that fit) and the frame has one camera
  that covers the window; otherwise it draws as `spatial` (several cameras or a split screen, a history the GPU cannot make). The
  fallback is the spatial upscaler, never a bare stretch: the picture is the one of the mode `spatial`;
- `metalfx` draws as itself on the Metal backend (macOS 13 or iOS 16 or later, a GPU with the MetalFX scalers, not the iOS simulator)
  until one of its frames fails; it draws as `temporal` (then `spatial`) where it cannot, with the reason in `render.supports` and one
  warning in the log. Its temporal scaler has one history like the temporal upscaler, so a frame of several cameras draws `spatial`
  too; a GPU that has only MetalFX's spatial scaler keeps `metalfx` on every frame (the section "MetalFX" below);
- `auto` picks the best the GPU can draw: `metalfx`, `temporal`, `spatial`; where `temporal` cannot run it is `spatial`;
- with no renderer (`graphics=false`) `effectiveMode` is what a GPU here would draw for a game with one camera and no history to
  fail: `stretch` for a pixel-perfect project, and otherwise the setting itself (`spatial`, `temporal`), with `auto` and `metalfx`
  reported as `metalfx` on a Mac or iPhone build where MetalFX is available (the system is asked, no window is made) and as `temporal`
  everywhere else. It cannot know that a particular GPU's shaders compile or that a frame has several cameras, so a game that does that
  draws `spatial` where this reports `temporal` or `metalfx`.

The project's block is applied when the engine starts and again when `factoria.json` changes it.

## The temporal upscaler

`mode` `temporal` (or `auto`) draws the game below the window's size, with the camera jittered, and **accumulates a history at the
window's size** with the same resolve as the temporal antialiasing (`taa_shared.glsl`; its Gaussian is as narrow as an output pixel when
the picture is smaller than the output), then sharpens it (`sharpness`: 0 none, 0.5 the effect's own, 1 twice as much). The jitter has
`ceil(8 * (output / render)^2)` phases (at most 128): 32 at half the size, 72 at a third. One seam serves it: the `upscale` stage of the
frame graph, which the spatial upscaler (P3b) and MetalFX (P5b) use too, with the HUD drawn after it at the window's size, never jittered.

- **Quality.** `quality` sets the render size (`scale` above); `native` is the whole size, so the stage is off and nothing is jittered
  (for antialiasing at the full size turn `temporalAAEnabled` on). `sharpness` is the output sharpen. A change of the output size, the
  render size or the quality starts the history again, like a cut, a floating-origin shift and the first frame.
- **The camera's TemporalAA.** While the upscaler draws, the camera's own render-size `TemporalAA` pass is skipped (the upscaler does
  that job in one pass). Its fields (`temporalAAFeedback`, `Sharpen`, `VarianceGamma`, `ReactiveScale`) still tune the upscaler; without the
  effect on the camera the defaults apply.
- **One camera.** The frame needs exactly one camera that covers the whole window (the jitter of a camera would show in the rectangle of
  the next one). With a split screen or an overlay camera the frame is drawn with the spatial upscaler (`effectiveMode` says `spatial`; it is `temporal` again on the first frame with one camera). Cameras that draw into a texture are not
  jittered and are not resolved.
- **The post stack sees a jittered image.** The history is resolved after the post stack, at the end, not before it as the antialiasing
  does: bloom, depth of field, motion blur and the other effects work on the jittered render-size image, and the resolve smooths what they
  leave. That is the price of one seam for every upscaler; thin bright details can shimmer through a strong bloom.
- **Motion.** The resolve reprojects with the camera's movement and, where the renderer wrote them, with per-object velocities
  (`render.supports` `motionVectors`). A 2D game has no velocity: a sprite that moves leaves a short trail; keep the quality high or
  use `stretch` for it. The HUD stays in the game image (blurred like the game) when a glowing bloom (`bloomScreenSpace` true) is on,
  as with the stretch stage (docs/RENDERING.md). The output's alpha is 1.
- **Pixel art.** `PixelPerfect` draws as `stretch` (hard pixels, no blend, no jitter).
- **Costs.** One RGBA16F history of the window's size, two images (RGBA8 on a GPU without float targets, softer), and two draws
  (resolve and sharpen) in the `upscale` pass; the render-size frame plus a depth prepass for the reprojection. Off (`stretch`) costs nothing:
  no pass, no image, no jitter, the same pixels.
- **Not done yet: texture LOD bias.** The textures are sampled with the mip level of the render size, not biased by `log2(render / output)`
  as the best upscalers do (sokol's samplers have no bias; it needs a uniform and a change at every `texture()` of the mesh, terrain, foliage and
  material shaders). The accumulated frames and the sharpen recover most of the detail; very fine textures look a little softer than at
  the full size.

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
`sharpness` 0 for none). The `temporal` mode at scale 1 draws nothing extra (nothing to upscale; turn `temporalAAEnabled` on for antialiasing). The HUD, the UI and the debug text are drawn after the stage at the window's size, so text stays sharp
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
| Metal | yes | same; MetalFX is a separate mode |
| No renderer (`graphics=false`) | nothing is drawn | `effectiveMode` is what a GPU would draw: `stretch` for pixel-perfect projects, else per the setting |

## MetalFX (Apple GPUs)

`mode` `metalfx` (or `auto` on Metal) hands the upscale to Apple's MetalFX framework, loaded at run time (a player built with it still
starts on an OS without it). It draws in the same `upscale` stage as the other modes, with the HUD drawn after it at the window's size.

- **Temporal scaler** (the usual case). The camera is jittered exactly as for the temporal upscaler (the same `ceil(8 * (output / render)^2)`
  phases) and MetalFX gets the picture at the render size, a depth image, a motion image and the jitter, and keeps its own history at the
  window's size. A small pass at the render size prepares the two images: the depth of the camera's prepass squashed to 0..1 (1 for the sky
  and for pixels no mesh wrote), and the motion in UV units as the velocity image holds it. Where no object wrote a velocity (the sentinel
  `1024`: particles, sprites, skins of more than 32 joints, the sky) MetalFX does **not** get the sentinel: the pass reprojects the camera's own
  movement from the depth, as the temporal upscaler does, so those pixels move with the camera. The history resets on the events of the
  temporal upscaler: a camera cut, another scene, a floating-origin shift, a change of the render size or the quality, a frame MetalFX did not
  draw in between, and a new scaler (a change of the window's size). `sharpness` has no effect on MetalFX (it sharpens as it sees fit).
  The motion image is in UV units as MetalFX reads it: from the pixel to where it was (previous minus current position), scaled by the
  render size. `metalfx_tests` checks that convention with a moving pattern: that sign is clearly better than the opposite one or none.
  **Open:** in the renderer's own scenes `metalfx_renderer_tests` could not make the output depend on the sign of the motion image (a
  square that moves leaves the same few pixels of ghost with either sign, or none), although the image has the right values and the
  history does not reset; the tests there check what holds (no trail, the history resets and converges, the fallbacks) and not the sign.
  If a moving scene shows ghosts on a Mac, `render.upscaler` mode `temporal` is the same upscale without MetalFX.
- **Spatial scaler.** A GPU that has only this one (or a frame the temporal one cannot take: no camera plan) draws the picture, unjittered,
  through it. At `native` quality the stage is off and MetalFX has nothing to do, like the other modes.
- **Where it runs in the frame.** MetalFX encodes into its own command buffer, so the frame is split there: the passes drawn so far (the
  picture) are submitted, MetalFX runs behind them, and the HUD, the colour filter and the present run behind it. It costs one more command
  buffer a frame. A change of the render size (dynamic changes of the quality, a resize) makes a new scaler, which takes a moment to build.
- **The colour.** The picture is the scene colour after the post stack, as for the other modes: linear light above 1 in an HDR scene, display
  values after a final pass. MetalFX's temporal scaler is told the exposure is 1 (the scene is exposed before the stage).
- **Fallbacks.** Where MetalFX is missing (the OS is older, the iOS simulator, a GPU without it, the OpenGL backend) the effective mode is
  the next best (`temporal`, then `spatial`) and the log says why once; `render.supports` `metalfx` carries the same reason. If MetalFX fails
  at creation or in a frame (a size it refuses, a lost device) the renderer drops to the temporal upscaler (the spatial one if that cannot
  draw) for the rest of the run, with one warning, and `effectiveMode` says it.
- **The tests.** The tests that need MetalFX (`metalfx_tests`, `metalfx_renderer_tests`) run on a Mac or an iPhone build with a real GPU.
  A machine without it, such as the macOS VM of CI, which has a paravirtual GPU with no MetalFX, skips them with an explicit message in the
  test output (a `MESSAGE` that names the reason), never silently.

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

Limitations of the motion vectors it reads: particles, sprites and quads write none (they are reprojected as if still, so a fast one
trails), and neither do a mesh whose material needs more vertex attributes than the previous position leaves room for (without a skin, more
than 4 extra `vec4`s; with one, 3 or more) or draws from storage buffers. Everything else, skinned meshes of up to 64 joints and a material's
`vertex()` included, has a vector. A custom `vertex()` is run twice and only `fa_time.x` differs in the second run, so motion that depends on the
instance data, a material parameter or the distance to the camera is not seen. A GPU with no RG16F render target has no vectors at all: one
warning in the log, and the effect reprojects from the depth and the camera alone, which smears a moving object.

Where it does not apply: the cameras of a `CameraView`, a render-target camera and `camera.capture` and the other renders of a scene
that are not a frame of the running game (thumbnails, `capture_world`) are drawn without it (no jitter, no pass, no history); a
screenshot of the running game is the antialiased frame it shows. The editor viewport draws like the
game (it is the same renderer) unless the editor's view bypasses the post stack, and then it has neither the pass nor the jitter. A custom
post pass cannot be placed `before` or `after` `temporalAA`; `before:depthOfField` runs after it.

## Dynamic resolution

The render scale can follow the frame time, so a game holds a target (30 fps, 60 fps, one refresh of the display) on a machine that
cannot draw its full-size frame in time, and draws sharper on one that can. It is **off by default**, and off is the picture and the
frame of a build without the feature, bit for bit. One setting block, three places, like the upscaler:

- the project: `"render": { "dynamicResolution": { "enabled": true, "targetMs": 16.7, "minScale": 0.6, "maxScale": 1 } }` in
  `factoria.json` (schema `schemas/project.schema.json`); every key is optional. A wrong value fails to load with the JSON pointer
  (`/render/dynamicResolution/minScale`), what is wrong and the valid range, and a misspelt key gets a "did you mean";
- the command `render.dynamic_resolution` (no argument reads; any key changes those and keeps the rest; a wrong value fails with
  `invalid_argument` and changes nothing);
- scripts: `window.dynamicResolution` reads `{enabled, targetMs, minScale, maxScale}` plus the read-only `effectiveTargetMs`, `scale`
  (the factor in force, 1 while off), `frameMs` (the smoothed frame time the controller sees, 0 until one was measured) and `source`;
  writing it takes any of the four keys (a read can be written back).

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `false` | the controller runs |
| `targetMs` | unset (0) | the frame time to hold, 4 to 100 ms (33.3 = 30 fps, 16.7 = 60 fps, 8.3 = 120 fps); 0 or unset holds one refresh of the display |
| `minScale` | 0.5 | the smallest share of the base size's width and height the controller uses, 0.25 to 1 |
| `maxScale` | 1 | the largest share, `minScale` to 1; the controller starts here |

**Where it applies.** The factor multiplies into the scale in `Engine::Impl::apply_render_scale` and nowhere else: the drawn scale is
`window.renderScale` times the quality's scale times the factor, never below 0.25 (`plan_upscale_scale` takes it as an argument;
1 changes nothing). So a game at `performance` quality (0.5) with the range 0.6 to 1 is drawn between 0.3 and 0.5 of the window and
brought up by the upscaler of its choice (the `stretch` mode scales the lower picture plainly). It does not apply to a scale held as
a size (`--render-scale`, the video recorder, a screenshot's `scale`), in the editor's own viewport, or with no renderer; there it
reads as 1. `game.render_stats` and `window.upscaler` report `dynamicScale` (the factor) and `frameMs` (read-only; setting
`window.upscaler` ignores them). Nothing of the simulation reads the factor, so a replay or a script's result never depends on it.

**What it measures.** Where the backend has timer queries (Direct3D 11 and OpenGL), the GPU time of the frame: `source` is `"gpu"`, the
mean of the frames the renderer timed since the last tick (a result arrives a few frames late). Elsewhere (Metal, GLES3, WebGL2) and
whenever a window is on screen without it, the time between frames the platform measured, `"interval"`. A window that renders only
on demand is not measured. No clock is read by the engine: the tick is fed numbers, and tests inject them (`Engine::set_dynamic_resolution_frame_ms`,
`source` `"injected"`). "One refresh of the display" is 16.7 ms (60 Hz): the platform layer has no refresh-rate query on every
platform yet, so the controller does not follow a 120 Hz or 144 Hz display by itself; set `targetMs` for those.

**How it moves** (`render::DynamicResolutionController`, deterministic: the same numbers give the same scales on every machine):

- the measured time is smoothed (an exponential average with a 0.3 s time constant, clamped to three times the target, so a load
  hitch moves it, not the whole way);
- the factor lives on a grid of 32 steps between `minScale` and `maxScale`. The picture's cost follows its area, so a move aims at the
  step whose predicted time (the smoothed time times the area ratio) is the middle of a dead band, never at its edge: with a GPU
  time the band is 80 % to 95 % of the target and it aims at 87.5 %, with the interval time 90 % to 108 % and it aims at 97 %;
- a change needs the smoothed time to stay outside the band (down 0.3 s, up 1 s) and a hold since the last change (down 0.5 s, up 1.5 s),
  so a one-frame hitch changes nothing and the scale changes at most twice a second. One change moves at most a quarter of the range
  down or an eighth up;
- with only the interval time the headroom is hidden (vsync pins it at the refresh rate while the game is fast enough), so the
  controller goes down by prediction and tries one step up after 3 s inside the band. A try that fails (the time goes over again within
  3 s) doubles the next wait (up to 48 s) and the step that failed is not tried again for a minute or more, so it settles under it
  instead of swinging.

**Reallocation.** A step makes the render targets again (the scene's color, depth and post chain at the new size); it does not
change the window or the swap chain. That costs a few milliseconds at the step, which is why the controller is rate-limited to two
changes a second and quantised, never per frame: a viewport inside fixed-size targets would avoid it at the price of every pass
reading a sub-rectangle (the post chain, the temporal history and the bloom chain all assume the whole texture). The **temporal history
survives the steps**: the history of the `temporal` upscaler lives at the output size and is kept, and its key follows the scale the
game asked for, without the factor, so a step does not reset it. The jitter sequence is rounded up to a multiple of 4 phases while a
factor is on, so the phase changes smoothly when the size does.

**Presets.** No preset turns it on. A preset is a static set of limits that gives the same picture on every machine; this one decides
at run time from a measurement of this machine, and a game that wants it says so (`factoria.json`, or the player's choice in the menu
kit). `ultra` therefore stays the game as its author made it, bit for bit like `custom`; presets never write `dynamicResolution`, and
the `low` preset's lower upscaler quality is the fixed answer for a weak machine.

`render.supports` with `dynamicResolution` says `supported` on every GPU backend.

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
  from before them loads as it did. A **Dynamic resolution** row (`gfx_dynamic`, in `gfx_dynamic_slot`; hidden where
  `render.supports` says `dynamicResolution` is not drawn) cycles Off, 30 fps, 60 fps and Display refresh; it turns
  `window.dynamicResolution` on or off with that `targetMs` and keeps the game's own `minScale` and `maxScale`, and is saved as
  `settings.graphics.dynamicResolution` (`null` until the player chooses: an older save changes nothing, and the row shows what the
  game set, "Custom" for a target that is none of the three).
- **Editor.** View > Graphics edits `render.graphicsPreset`, `render.upscaler` (`mode`, `quality`, `sharpness`) and
  `render.dynamicResolution` (`enabled`, `targetMs`, `minScale`, `maxScale`) of `factoria.json` with Save and Revert; the values are
  checked by the code that loads the project and the `render.upscaler` and `render.dynamic_resolution` commands, so a wrong one is
  named with its JSON pointer and a "did you mean", and Save writes only those three keys (a value at its default removes its key). It does not preview: press Play after Save, or use the game's own menu, to see a preset or a mode.

## What a game can already ask

`render.supports` with `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution`, or `temporalAA`
(the effect's row). `temporalAA`, `spatialUpscaler`, `temporalUpscaler` and `dynamicResolution` are `supported` on every GPU
backend; `metalfx` is `supported` on Metal where the OS and the GPU have MetalFX (else false, with the reason: the OS version, the
iOS simulator, the GPU, or the OpenGL/D3D11 backend of this build); `motionVectors` answers
true where the GPU can make the image (the depth prepass writes the motion of the meshes, skinned ones of up to 32 joints and
materials with a `vertex()` included, instances, terrain, foliage and impostors, and `render.debug_view {"view":"motionVectors"}`
shows it).

| Row | Backends | Needs |
|---|---|---|
| `motionVectors` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `temporalUpscaler` | every GPU backend | nothing (RGBA16F history where the GPU can, else RGBA8, as the temporal antialiasing) |
| `spatialUpscaler` | every GPU backend | nothing |
| `dynamicResolution` | every GPU backend | nothing (the GPU time needs timer queries: Direct3D 11 and OpenGL; elsewhere the time between frames) |
| `metalfx` | Metal only (macOS, iOS) | macOS 13 or iOS 16 or later and a GPU with the MetalFX scalers (`reason` names what is missing) |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing (RGBA16F history where the GPU can, else RGBA8) |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
