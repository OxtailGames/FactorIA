# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The **temporal antialiasing** draws (see below). The upscaler settings, the
graphics presets and the other `render.supports` rows are stored and reported only: they say `planned (M76)` and take effect when
their passes land.

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

`scale` is the share of the window's size each side is drawn at for that quality. `effectiveMode` is the mode that will
actually draw: until the passes land it is always `stretch`, whatever `mode` says, so reading the setting back never lies.
The project's block is applied when the engine starts and again when `factoria.json` changes it.

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
(the effect's row). `temporalAA` is `supported`; the others answer false with the status `planned (M76)`.

| Row | Backends | Needs |
|---|---|---|
| `motionVectors`, `temporalUpscaler` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `spatialUpscaler`, `dynamicResolution` | every GPU backend | nothing |
| `metalfx` | Metal only (macOS, iOS) | nothing |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing (RGBA16F history where the GPU can, else RGBA8) |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
