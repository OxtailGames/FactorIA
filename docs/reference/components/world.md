[Back to the index](../README.md)

# Components: World

## StreamedWorld

Not released yet (on main after 0.34.0).

Turns this scene into a streamed world: `world` names an index file (<name>.world.json: the cell size and, for each cell, its bounds and its scene file). The engine loads the cells near the enabled StreamingAnchor entities on the IO thread (a BackgroundLoader job per cell, several at once), adds each to the scene under a root entity named "cell i,j" and, when the anchors move away, destroys that root. Put it on ONE entity (the first enabled one is used). The cells' files are separate from this scene: scene.save never writes them. `world.cells` and `world.stream_status` say what is loaded; scripts hear the game events `cellLoaded` and `cellUnloaded` (world.on("cellLoaded", (data, root) => ...); docs/BIG_WORLDS_STREAMING.md, "Streaming").

| Field | Type | Default | Description |
|---|---|---|---|
| `world` | asset (any) | `""` | Project-relative path of the world index, a *.world.json file. Read once when the scene starts (or when this field changes). "" (default) = nothing is streamed. |
| `enabled` | bool | `true` | true (default) = cells load around the anchors. false = no cell loads and the loaded ones are unloaded. |
| `maxLoadsInFlight` | int | `2` | 1..16: how many cells are read at once; the rest wait, nearest to the highest-priority anchor first. Each cell is a BackgroundLoader job, so its files also share the frame's load budget (project loadBudgetMs; headless runs and tests count 4 units a frame). Default 2. Range 1..16. |
| `maxAppliesPerFrame` | int | `1` | 1..64: how many cells are added to the scene, plus cells removed from it, in one frame, on the main thread (a cell with thousands of entities costs milliseconds to add; unloads go first). Counts cells only: the frame's load budget limits the reading, not this. Default 1. Range 1..64. |
| `keepLoaded` | bool | `false` | Debug: true loads every cell and never unloads one, whatever the anchors say (to look at the whole world). It costs O(cells) per fixed tick, so leave it off in a game with a big index. Default false. |
| `cameraLoadRadius` | float | `0.0` | Metres, 0..1000000. Above 0 the active camera (the one with the lowest depth) is an anchor with this load radius and priority 0, besides the StreamingAnchor entities. Default 0: the camera is not an anchor. Range 0.0..1000000.0. |
| `cameraUnloadRadius` | float | `0.0` | Metres, 0..1000000: the unload radius of the camera anchor; must be above cameraLoadRadius. 0 (default) = 1.25 times cameraLoadRadius. Range 0.0..1000000.0. |

## StreamingAnchor

Not released yet (on main after 0.34.0).

Makes the world around this entity load and unload as it moves: a streamed scene is cut into cells (the `world.cells` command lists them), and the cells nearer than loadRadius to any enabled anchor are loaded, those farther than unloadRadius from all of them are unloaded. Put it on the player or on the camera. A scene with no anchor loads every cell. No effect yet: M75.3 builds the streaming (docs/BIG_WORLDS_STREAMING.md, "Streaming").

| Field | Type | Default | Description |
|---|---|---|---|
| `loadRadius` | float | `256.0` | Metres: a cell whose bounds are nearer than this to the anchor is loaded. Measured on the plane of the streamed world: x and z for a world index whose dimension is "3d", x and y for "2d". Distances use absolute positions (the floating origin plus the local position), so a rebase of the floating origin never changes what is loaded. 1..1000000. Default 256. Range 1.0..1000000.0. |
| `unloadRadius` | float | `320.0` | Metres: a loaded cell whose bounds are farther than this from every anchor is unloaded. Must be above loadRadius (the gap keeps a cell on the border from flickering). 1..1000000. Default 320. Range 1.0..1000000.0. |
| `priority` | int | `0` | -100..100: when two anchors want cells loaded, the anchor with the higher priority gets its cells first. Default 0. Range -100..100. |
| `enabled` | bool | `true` | false = this anchor loads nothing and keeps nothing loaded. |

