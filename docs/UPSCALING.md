# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. **Nothing here draws yet**: the settings are stored and reported, and
`render.supports` says `planned (M76)` for each feature. A game can set them today; they take effect when the passes land.

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

`PostProcess.temporalAAEnabled` (and `temporalAAFeedback`, `temporalAASharpen`, `temporalAAVarianceGamma`,
`temporalAAReactiveScale`) are the fields of the `TemporalAA` effect, between the exposure and the depth of field. They are
reflected and validated now; the effect does not draw yet, so the camera is not jittered and the picture is the one without it.
A custom post pass cannot be placed `before` or `after` `temporalAA`.

## Graphics presets

`graphics.preset {"name":"low|medium|high|ultra"}` and `graphics.detect` exist and answer `not_built` (nothing is changed).
The names are `Low`, `Medium`, `High`, `Ultra` and `Custom` (what the game set itself).

## What a game can already ask

`render.supports` with `motionVectors`, `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dynamicResolution`, or `temporalAA`
(the effect's row). All answer false with the status `planned (M76)`.

| Row | Backends | Needs |
|---|---|---|
| `motionVectors`, `temporalUpscaler` | every GPU backend | RGBA16F render targets that blend and filter (`half`) |
| `spatialUpscaler`, `dynamicResolution` | every GPU backend | nothing |
| `metalfx` | Metal only (macOS, iOS) | nothing |
| `temporalAA` | every GPU backend (it is an effect row, see `postprocess.get`'s `order`) | nothing |

How jitter and motion vectors are shared between the passes is in docs/design/ARCHITECTURE_RENDERING_POST.md, "Motion vectors and jitter (M76)" (repository only, not in the binary).
