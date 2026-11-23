# Big worlds

Levels of detail, occlusion, streamed cells, a floating origin, terrain and foliage: what a game needs when its world is
kilometres wide. **Milestone M75 built all of it.** Levels of detail with a dithered cross-fade, impostor cards and HLOD proxies; occlusion on the CPU (occluders, areas and portals) and on the GPU (a depth pyramid); a world streamed in cells around anchors; a floating origin that keeps positions exact far from zero (the world, the physics, the audio and the renderer follow a rebase); heightmap terrain with a GPU level of detail and collision; and instanced foliage with an editor brush. Every component, field and command below is real: the scenes save, load, validate and draw or simulate what they say, and the counters in `renderStats`, the `render.supports` rows and the commands report it. Nothing here changes a game that does not use it: every default
is "off" or "as before".

| Part | Package | What it adds |
|---|---|---|
| [Levels of detail](BIG_WORLDS_LOD.md#levels-of-detail-m751) | M75.1 | screen-size thresholds, `LodGroup`, dithered cross-fade, impostor cards and the HLOD proxy with `world.bake_hlod` (all drawn) |
| [Occlusion](BIG_WORLDS_LOD.md#occlusion-m752) | M75.2 | occluders (CPU) and a depth pyramid of the camera's picture (GPU) built, areas and portals (CPU) built |
| [Streaming](BIG_WORLDS_STREAMING.md#streaming-m753) | M75.3 | cells loaded and unloaded around `StreamingAnchor`s; cells that are not loaded draw their HLOD proxy (`StreamedWorld.hlodDistance`, `world.bake_cell_hlods`, [HLOD proxies](BIG_WORLDS_STREAMING.md#hlod-proxies)) |
| [Floating origin](BIG_WORLDS_STREAMING.md#floating-origin) | M75.4 | positions stay exact far from the origin (works: the world, physics, audio and the renderer follow a rebase) |
| [Terrain](BIG_WORLDS_TERRAIN.md#terrain-m755) | M75.5 | heightmap terrain: drawn with a GPU level of detail and collision; the `terrain.*` commands sculpt, paint, cut holes and generate it, up to 8 layers blended by splat maps and holes |
| [Foliage](BIG_WORLDS_TERRAIN.md#foliage) | M75.6 | instanced vegetation and rocks: drawn from an instances file with chunk culling, fade, LOD, wind and thinning; `foliage.scatter`, `foliage.paint` and `foliage.clear` fill it (the editor's foliage brush: View > Foliage tool, [Editing foliage in the editor](BIG_WORLDS_TERRAIN.md#editing-foliage-in-the-editor)) |

`renderer.supports` (the `render.supports` command) lists a row per renderer feature: `impostors`, `occlusionCpu`, `occlusionPortals`, `terrain` and
`foliage` are `true` on every backend and `occlusionGpu` where the GPU has compute shaders (D3D11, Metal, OpenGL 4.3). Ask
it before relying on one, as for every other feature (docs/RENDERING.md).

## Pages

This page has the overview, the errors and the command list. Each part has its own page (each stays under 60 KB):

- [Levels of detail and occlusion](BIG_WORLDS_LOD.md) (M75.1, M75.2)
- [Streaming and the floating origin](BIG_WORLDS_STREAMING.md) (M75.3, M75.4)
- [Terrain and foliage](BIG_WORLDS_TERRAIN.md) (M75.5, M75.6)

## The errors a scene gets today

The loader checks these components when it loads a scene, and `factoria validate` prints the same text: the file, the JSON pointer,
what is wrong and how to fix it, with a "did you mean" for a misspelt name. A contradiction between fields (an `unloadRadius` that
is not above `loadRadius`, a `fadeEnd` that is not above `fadeStart`, an `hlodProxy` without `hlodThreshold`, more layers than
the splat maps weight) is reported before anything is built from it. A setting that does nothing (an `impostorDistance` with no
`impostor`) is a warning.

## Commands

| Command | Package | Writes files |
|---|---|---|
| `world.origin`, `world.rebase`, `world.absolute_position` | M75.4 (built) | no |
| `world.cells`, `world.stream_status` | M75.3 (built) | no |
| `tilemap.split_cells` | M75.3b (built) | yes |
| `world.split_cells`, `world.merge_cells` | M75.3c (built) | yes |
| `model.generate_lods`, `model.bake_impostor` | M75.1 (built) | yes |
| `terrain.create`, `terrain.sculpt`, `terrain.paint`, `terrain.holes`, `terrain.generate`, `terrain.save`, `terrain.undo`, `terrain.redo` | M75.5 (built) | yes (`terrain.undo`, `terrain.redo` only with `save`) |
| `foliage.scatter`, `foliage.paint`, `foliage.clear`, `foliage.undo`, `foliage.redo` | M75.6 (built) | yes |

`factoria commands <name>` and `docs.commands {name}` print the arguments of each.
