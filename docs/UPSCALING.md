# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The **temporal antialiasing**, the **spatial upscaler**, the **temporal upscaler**
and the plain **stretch** draw today (see below); MetalFX and the graphics presets are planned (`render.supports` says `planned
(M76)` for each of them, and a setting that asks for one draws as the best mode that exists).

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
- `auto` picks the best the GPU can draw: `metalfx` (when it lands), `temporal`, `spatial`; where `temporal` cannot run it is
  `spatial`. `metalfx` draws as `temporal` (or `spatial`) until its package lands;
- with no renderer (`graphics=false`) `effectiveMode` is what a GPU would draw for a game with one camera and no history to
  fail: `stretch` for a pixel-perfect project, and otherwise `spatial` for `spatial`, `auto`, `temporal` and `metalfx`
  (the temporal upscaler needs a renderer to know that its shaders compile, so a host without one reports the spatial one).

The project's block is applied when the engine starts and again when `factoria.json` changes it.

## The temporal upscaler

`mode` `temporal` (or `auto`) draws the game below the window's size, with the camera jittered, and **accumulates a history at the
window's size** with the same resolve as the temporal antialiasing (`taa_shared.glsl`; its Gaussian is as narrow as an output pixel when
the picture is smaller than the output), then sharpens it (`sharpness`: 0 none, 0.5 the effect's own, 1 twice as much). The jitter has
`ceil(8 * (output / render)^2)` phases (at most 128): 32 at half the size, 72 at a third. One seam serves it: the `upscale` stage of the
frame graph, which the spatial upscaler (P3b) and MetalFX (P5) use too, with the HUD drawn after it at the window's size, never jittered.

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

`graphics.preset {"name":"low|medium|high|ultra"}` and `graphics.detect` exist and answer `not_built` (nothing is changed).
The names are `Low`, `Medium`, `High`, `Ultra` and `Custom` (what the game set itself).

## What a game can already ask

`render.supports` with `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution`, or `temporalAA`
(the effect's row). `temporalAA`, `spatialUpscaler` and `temporalUpscaler` are `supported` on every GPU backend; `motionVectors` answers
true where the GPU can make the image (the depth prepass writes the motion of the meshes, instances, terrain, foliage and
impostors, and `render.debug_view {"view":"motionVectors"}` shows it); the others answer false with the status
`planned (M76)` until their packages land.

| Row | Backends | Needs |
|---|---|---|
| `motionVectors` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `temporalUpscaler` | every GPU backend | nothing (RGBA16F history where the GPU can, else RGBA8, as the temporal antialiasing) |
| `spatialUpscaler`, `dynamicResolution` | every GPU backend | nothing |
| `metalfx` | Metal only (macOS, iOS) | nothing |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing (RGBA16F history where the GPU can, else RGBA8) |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
