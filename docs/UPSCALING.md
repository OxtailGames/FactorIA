# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The **temporal antialiasing** and the **temporal upscaler** draw (see below). The
other upscaler modes, the graphics presets and the other `render.supports` rows are stored and reported only: they say `planned (M76)`
and take effect when their passes land.

## The engine-wide upscaler settings

The picture can be drawn at a lower resolution and brought up to the window's. One setting block, three places:

- the project: `"render": { "upscaler": { "mode": "temporal", "quality": "balanced", "sharpness": 0.5 } }` in `factoria.json`
  (schema `schemas/project.schema.json`; a wrong value fails to load with the JSON pointer and a "did you mean");
- a script: `window.upscaler` (read it, or assign an object with any of the three keys; it also reports `effectiveMode` and `scale`);
- a command: `render.upscaler` (no arguments reads; `mode`, `quality`, `sharpness` set and answer the result).

| Key | Values | Default |
|---|---|---|
| `mode` | `stretch` (the window scales the picture), `spatial`, `temporal`, `metalfx` (Apple GPUs), `auto` | `stretch` |
| `quality` | `native` (1), `quality` (1/1.5), `balanced` (1/1.7), `performance` (1/2), `ultraPerformance` (1/3) | `native` |
| `sharpness` | 0 to 1 | 0.5 |

`scale` is the share of the window's size each side is drawn at for that quality. The game is drawn at `scale` times the player's
render scale (`window.renderScale`; at least 0.25) with the upscale stage on (the HUD stays sharp at the window's size, see
docs/RENDERING.md), so `quality` alone makes the game cheaper. `effectiveMode` is the mode that really draws, so reading the setting
back never lies: `temporal` (and `auto`, which prefers it) draws as `temporal` where the renderer can (below), `stretch` stays
`stretch`, and `spatial` and `metalfx` read `stretch` until their passes land. A game with `scaleMode` `PixelPerfect` always reads
`stretch`: pixel art is never blended. The project's block is applied when the engine starts and again when `factoria.json` changes it.

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
  the next one). With a split screen or an overlay camera the frame is drawn as `stretch`. Cameras that draw into a texture are not
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
(the effect's row). `temporalAA` and `temporalUpscaler` are `supported`; the others answer false with the status `planned (M76)`.

| Row | Backends | Needs |
|---|---|---|
| `motionVectors` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `temporalUpscaler` | every GPU backend | nothing (RGBA16F history where the GPU can, else RGBA8, as the temporal antialiasing) |
| `spatialUpscaler`, `dynamicResolution` | every GPU backend | nothing |
| `metalfx` | Metal only (macOS, iOS) | nothing |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing (RGBA16F history where the GPU can, else RGBA8) |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
