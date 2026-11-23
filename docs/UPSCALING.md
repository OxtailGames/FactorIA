# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The **spatial upscaler** and the plain **stretch** draw today; the temporal
upscaler, MetalFX, the temporal antialiasing and the graphics presets are planned (`render.supports` says `planned (M76)` for
each of them, and a setting that asks for one draws as the best mode that exists).

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
- with no GPU (`graphics=false`) there is nothing to draw: `stretch`, as a host with no renderer reports the mode a GPU would draw.

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
| No GPU (`graphics=false`) | no | `effectiveMode` is `stretch` |

## Temporal antialiasing

`PostProcess.temporalAAEnabled` (and `temporalAAFeedback`, `temporalAASharpen`, `temporalAAVarianceGamma`,
`temporalAAReactiveScale`) are the fields of the `TemporalAA` effect, between the exposure and the depth of field. They are
reflected and validated now; the effect does not draw yet, so the camera is not jittered and the picture is the one without it.
A custom post pass cannot be placed `before` or `after` `temporalAA`.

## Graphics presets

`graphics.preset {"name":"low|medium|high|ultra"}` and `graphics.detect` exist and answer `not_built` (nothing is changed).
The names are `Low`, `Medium`, `High`, `Ultra` and `Custom` (what the game set itself).

## What a game can already ask

`render.supports` with `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution`, or `temporalAA`
(the effect's row). `spatialUpscaler` answers true on every GPU backend; the others answer false with the status `planned (M76)`
until their packages land.

| Row | Backends | Needs |
|---|---|---|
| `motionVectors`, `temporalUpscaler` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `spatialUpscaler`, `dynamicResolution` | every GPU backend | nothing |
| `metalfx` | Metal only (macOS, iOS) | nothing |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
