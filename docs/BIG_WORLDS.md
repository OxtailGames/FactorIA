# Big worlds

Levels of detail, occlusion, streamed cells, a floating origin, terrain and foliage: what a game needs when its world is
kilometres wide. **Milestone M75 builds this in parts.** The floating origin works today (the world, the physics, the audio and the renderer follow a rebase); the CPU occluders of Occlusion draw (M75.2), and the other parts below are marked "(planned, M75.n)" and none of them draws or simulates anything yet. What exists today for them is the data and the names: the components and fields (they save, load and validate, and
do nothing yet), the counters in `renderStats`, the `render.supports` rows and the
commands, which fail with the error `not_built` (planned for a coming version) and name the package that fills them in, except
`world.origin`, `world.rebase`, `world.absolute_position` and the `terrain.*` commands, which work. A game that adds the rest today loses nothing:
when a package lands, the scenes already written start to work. Nothing here changes a game that does not use it: every default
is "off" or "as before".

| Part | Package | What it adds |
|---|---|---|
| [Levels of detail](BIG_WORLDS_LOD.md#levels-of-detail-m751) | M75.1 | screen-size thresholds, `LodGroup` and dithered cross-fade (drawn); impostors and HLOD (planned) |
| [Occlusion](BIG_WORLDS_LOD.md#occlusion-m752) | M75.2 | occluders (CPU built; GPU planned), areas and portals (planned) |
| [Streaming](BIG_WORLDS_STREAMING.md#streaming-m753) | M75.3 | cells loaded and unloaded around `StreamingAnchor`s |
| [Floating origin](BIG_WORLDS_STREAMING.md#floating-origin) | M75.4 | positions stay exact far from the origin (works: the world, physics, audio and the renderer follow a rebase) |
| [Terrain](BIG_WORLDS_TERRAIN.md#terrain-m755) | M75.5 | heightmap terrain: drawn with a GPU level of detail and collision; the `terrain.*` commands sculpt, paint, cut holes and generate it, up to 8 layers blended by splat maps and holes |
| [Foliage](BIG_WORLDS_TERRAIN.md#foliage) | M75.6 | instanced vegetation and rocks: drawn from an instances file with chunk culling, fade, LOD, wind and thinning; the scatter and paint commands are planned |

`renderer.supports` (the `render.supports` command) already lists a row per renderer feature, `false` with the status
"planned (M75)" until its package lands (`impostors`, `occlusionGpu`); `occlusionCpu`, `terrain` and `foliage` are `true` on every backend. Ask
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
| `world.cells`, `world.stream_status` | M75.3 | no |
| `tilemap.split_cells` | M75.3b | yes |
| `world.split_cells`, `world.merge_cells` | M75.3 (planned) | yes |
| `model.generate_lods`, `model.bake_impostor` | M75.1 | yes |
| `terrain.create`, `terrain.sculpt`, `terrain.paint`, `terrain.holes`, `terrain.generate`, `terrain.save`, `terrain.undo`, `terrain.redo` | M75.5 (built) | yes (`terrain.undo`, `terrain.redo` only with `save`) |
| `foliage.scatter`, `foliage.paint`, `foliage.clear` | M75.6 | yes |

`factoria commands <name>` and `docs.commands {name}` print the arguments of each.
