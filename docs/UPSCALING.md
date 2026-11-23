# Upscaling and temporal antialiasing (M76)

This page is the contract of the M76 settings. The upscaler and temporal antialiasing settings are stored and reported, and
`render.supports` says `planned (M76)` for each feature that does not draw yet. The graphics presets (last section but one) work
now: they lower the quality knobs of the renderer that exist today.

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
| upscaler (`mode` auto, `quality`) | `performance` | `balanced` | `quality` | `native` |

The numbers are caps and never rise above what the scene asks for. The table is monotone (every knob of `medium` is at least as high
as `low`, and so on), and a test keeps it so. `graphics.preset` answers the whole `limits` object by knob name.

**What the GPU caps.** A knob for a feature the backend cannot draw is lowered too, with the same status `render.supports` gives:
the volumetric fog needs half-float targets, cascaded and local shadows need 32-bit float targets, and the shadow atlas is never
larger than the GPU's largest texture. Each cap is in the answer's `capped` list as `{knob, wanted, effective, reason}`. `temporalAA`
is capped while its row says `planned`, so it appears there on every GPU until the effect lands (it changes nothing: the effect does
not draw).

**The upscaler.** `low`, `medium`, `high` and `ultra` also write the engine-wide upscaler (mode `auto`, the quality of the last row,
sharpness 0.5). The setting the game had (`render.upscaler` in `factoria.json`, or what a script or `render.upscaler` set) is kept,
and `custom` puts it back. An upscaler change made while a preset is on (`render.upscaler`, `window.upscaler`) is the game's new own
setting: it is what `custom` goes back to, and the preset's upscaler stays until then.

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
- Saving the player's choice and the settings menu page are not part of this layer yet; a game applies the preset it wants.

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
