[Back to the index](../README.md)

# Commands: world

## `foliage.clear` (modifies state)

Not released yet (on main after 0.34.0).

Remove every instance of a Foliage, or those in a rectangle.

Capabilities: read, state, writeProject

Will empty the Foliage's instances file, or only the instances inside `region` ([minX, minZ, maxX, maxZ] world metres). Result: {removed}. Example: foliage.clear {"entity":"grass"} Not built yet (planned, M75.6): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Foliage. |
| `region` | array | no | [minX, minZ, maxX, maxZ] in world metres; omit for all. |

## `foliage.paint` (modifies state)

Not released yet (on main after 0.34.0).

Add or remove foliage instances by hand in a circle on the ground.

Capabilities: read, state, writeProject

Will add instances (mode "add", `density` per square metre) or remove them (mode "remove") within `radius` metres of `center` and write the instances file back. Result: {added, removed}. Example: foliage.paint {"entity":"grass","center":[10,20],"radius":5} Not built yet (planned, M75.6): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Foliage. |
| `mode` | string ["add","remove"] | no | Add instances or remove them. Default "add". |
| `center` | array | yes | World metres [x, z]. |
| `radius` | number | yes | Brush radius in metres. |
| `density` | number | no | Instances per square metre when adding. Default 1. |

## `foliage.scatter` (modifies state)

Not released yet (on main after 0.34.0).

Fill a Foliage's instances by a ScatterRule over a terrain.

Capabilities: read, state, writeProject

Will read the ScatterRule of `rule` (an entity id; default: the Foliage entity's own ScatterRule), place instances on the Terrain it names by density, slope, height and layers, deterministically from its seed, and write the Foliage's `instances` file, with each instance's mesh index into `Foliage.meshes`. It writes into the ONE Foliage entity, whose `meshes` it sets to all the meshes of the rule. `dryRun` only counts. Result: {instances, file}. Example: foliage.scatter {"entity":"grass"} Not built yet (planned, M75.6): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Foliage. |
| `rule` | string | no | Entity id with the ScatterRule (default: the Foliage entity). |
| `dryRun` | boolean | no | Only count the instances. Default false. |

## `terrain.create` (modifies state)

Not released yet (on main after 0.34.0).

Create a Terrain entity with a heightmap file.

Capabilities: read, state, writeProject

Will create an entity with a Terrain component and write a flat 16-bit heightmap of `resolution` samples per side (or import `heightmap`), `size` metres wide, with one layer. Result: {entity, heightmap}. Example: terrain.create {"name":"ground","size":[1024,1024]} Not built yet (planned, M75.5): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Entity id of the terrain. |
| `size` | array | no | Metres [x, z] the terrain covers. |
| `resolution` | integer | no | Samples per side of a new heightmap. Default 513. |
| `heightmap` | string | no | Import this 16-bit greyscale PNG or .r16 file instead of a flat one. |
| `heightScale` | number | no | Metres of height of a white sample. Default 100. |

## `terrain.generate` (modifies state)

Not released yet (on main after 0.34.0).

Fill a Terrain's heightmap with seeded procedural noise and optional erosion.

Capabilities: read, state, writeProject

Will replace the heightmap with fractal noise (`seed`, `frequency`, `octaves`) and `erosion` iterations of hydraulic erosion, deterministically (the same arguments give the same file). Result: {heightmap, minHeight, maxHeight}. Example: terrain.generate {"entity":"ground","seed":7,"octaves":5} Not built yet (planned, M75.5): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Terrain. |
| `seed` | integer | no | The same seed gives the same terrain. Default 1. |
| `frequency` | number | no | Noise features per metre. Default 0.004. |
| `octaves` | integer | no | Layers of noise. Default 5. |
| `erosion` | integer | no | Iterations of hydraulic erosion. Default 0. |

## `terrain.holes` (modifies state)

Not released yet (on main after 0.34.0).

Cut or fill holes (caves, tunnels) in a Terrain in a circle.

Capabilities: read, state, writeProject

Will set the texels of the terrain's holes image within `radius` metres of `center` (mode "cut" makes a hole, "fill" closes it) and write it back; the collider follows. Result: {changedTexels}. Example: terrain.holes {"entity":"ground","center":[0,0],"radius":3} Not built yet (planned, M75.5): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Terrain. |
| `mode` | string ["cut","fill"] | no | Make a hole or close one. Default "cut". |
| `center` | array | yes | World metres [x, z]. |
| `radius` | number | yes | Radius in metres. |

## `terrain.paint` (modifies state)

Not released yet (on main after 0.34.0).

Paint a material layer of a Terrain in a circle.

Capabilities: read, state, writeProject

Will raise the weight of `layer` (an index into Terrain.layers) within `radius` metres of `center` by `strength` and lower the others, and write the splat map files back. Result: {changedTexels}. Example: terrain.paint {"entity":"ground","layer":1,"center":[10,10],"radius":8} Not built yet (planned, M75.5): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Terrain. |
| `layer` | integer | yes | Index into Terrain.layers. |
| `center` | array | yes | World metres [x, z]. |
| `radius` | number | yes | Brush radius in metres. |
| `strength` | number | no | How much of the brush applies. Default 0.5. |

## `terrain.sculpt` (modifies state)

Not released yet (on main after 0.34.0).

Raise, lower, smooth or flatten the heightmap of a Terrain in a circle.

Capabilities: read, state, writeProject

Will change the samples of the terrain's heightmap file within `radius` metres of `center` with the brush `tool` (raise, lower, smooth, flatten), scaled by `strength` and a smooth falloff, and write the file back. Result: {changedSamples, bounds}. Example: terrain.sculpt {"entity":"ground","tool":"raise","center":[100,50],"radius":20} Not built yet (planned, M75.5): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id of the Terrain. |
| `tool` | string ["raise","lower","smooth","flatten"] | no | The brush. Default "raise". |
| `center` | array | yes | World metres [x, z]. |
| `radius` | number | yes | Brush radius in metres. |
| `strength` | number | no | How much of the brush applies. Default 0.5. |

## `tilemap.split_cells` (modifies state)

Not released yet (on main after 0.34.0).

Cut the Tilemap of a scene into a streamed 2D world: one chunk scene per cell and an index.

Capabilities: read, state, writeProject

Reads a scene file, takes its Tilemap entity (top level, orthogonal, square tiles, no rotation or scale) and writes a 2D world index `<out>` (`dimension` "2d") plus one scene per non-empty cell in `<out without .world.json>_cells/<i>_<j>.scene.json`. A cell is `cellSize` x `cellSize` TILES of the map: cell [i, j] holds the columns from i * cellSize and the rows counted from the BOTTOM of the map from j * cellSize (the last cell of a row or column is smaller when the map does not divide). Each chunk is an entity `<id>_<i>_<j>` with the same Tilemap fields (tileset, tileSize, solidTiles, terrains, layer, light fields...) and the other components of the source entity, placed at its ABSOLUTE top-left corner, so neighbouring chunks touch exactly; the index `origin` is the map's bottom-left corner and the `bounds` of each cell are the chunk's rectangle. Cells with only empty tiles are not written. The output is deterministic (the same scene gives the same bytes) and the source scene is never changed: remove the Tilemap entity and add a StreamedWorld entity yourself (the result's `notes` say what). Existing files are only replaced with `overwrite`. `dryRun` reports without writing. Result: {index, cells, cellGrid, emptyCellsSkipped, files, written, cellList, notes}. Example: tilemap.split_cells {"scene":"scenes/level.scene.json","cellSize":32,"out":"worlds/level.world.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scene` | string | yes | The scene file with the Tilemap (project-relative *.scene.json). |
| `tilemap` | string | no | Id of the Tilemap entity; optional when the scene has only one. |
| `cellSize` | integer | no | Tiles along one side of a cell. Default 32. |
| `out` | string | no | The index file to write, ending in .world.json (default: next to the scene, named after it). |
| `overwrite` | boolean | no | Replace files of an earlier split. Without it an existing file is an error and nothing is written. Default false. |
| `dryRun` | boolean | no | Only report what would be written. Default false. |

## `world.absolute_position`

Not released yet (on main after 0.34.0).

Read an entity's position in double precision: the floating origin plus its local position.

Capabilities: read

Returns {entity, position: [x, y, z] (the origin plus the entity's world position, added in double: the number that does not change when a floating-origin rebase shifts the origin, exact to about a micrometre at 10 000 km), origin: [x, y, z], local: [x, y, z] (the entity's world position in the engine's float space, what scripts and the editor read)}. Without floating origin the origin is [0, 0, 0] and position equals local. Read-only. Example: world.absolute_position {"entity":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity id (or name). |

## `world.cells`

Not released yet (on main after 0.34.0).

List the cells of the streamed world and which are loaded.

Capabilities: read

Lists the cells of the index of the scene's StreamedWorld (docs/BIG_WORLDS.md, "Streaming"): {world, dimension, cellSize, total, matching, truncated, cells: [{id, coord: [i, j], scene, bounds: {min, max}, state: "unloaded" | "queued" | "loading" | "loaded" | "unloading", entities (under the cell's root, 0 unless loaded), distance (metres on the plane to the nearest enabled StreamingAnchor, null with none), sizeBytes?, failed?}]}, sorted by distance (cells with no distance last, then by [j, i]). `state` keeps one state, `limit` caps the list (default 1000; `total` and `matching` count them all). Reads the index at once when the streamer has not (a StreamedWorld with a wrong index answers `error`). Read-only. Example: world.cells {"state":"loaded"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `state` | string ["unloaded","queued","loading","loaded","unloading"] | no | Only the cells in this state. |
| `limit` | integer | no | The most cells to list (default 1000). |

## `world.merge_cells` (modifies state)

Not released yet (on main after 0.34.0).

Merge the cells of a split scene back into one scene file.

Capabilities: read, state, writeProject

Will read a manifest written by world.split_cells and write the entities of every cell back into one scene file (the inverse of the split, so a level can be edited as one file). `dryRun` only reports. Result: {scene, entities}. Example: world.merge_cells {"manifest":"scenes/main.world.json"} Not built yet (planned, M75.3): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `manifest` | string | yes | The manifest file written by world.split_cells. |
| `output` | string | no | The scene file to write (default: the scene the manifest was made from). |
| `dryRun` | boolean | no | Only report what would be written. Default false. |

## `world.origin`

Not released yet (on main after 0.34.0).

Read the floating origin: where the world's origin is, in double precision.

Capabilities: read

Returns {enabled, origin: [x, y, z] (metres, doubles: the world position of the engine's local (0, 0, 0)), rebases (how many times the origin moved since the scene loaded), threshold, step, anchor} from the project's `world.floatingOrigin` settings and the running world. Read-only. Result: {enabled, origin, rebases, threshold, step, anchor, anchorPosition (the anchor's local position, null when there is none)}. Example: world.origin {}

## `world.rebase` (modifies state)

Not released yet (on main after 0.34.0).

Move the floating origin now, shifting every entity so the camera is near (0, 0, 0) again.

Capabilities: read, state

Moves the origin to `origin` (double metres, world space: the NEW origin, not a delta; `offset` is the old name of the same argument and still works) or to the position of `entity`, shifting every root Transform, physics body, audio source, navigation grid and particle by the difference in one step, so nothing visible changes. The difference is rounded to a whole multiple of `world.floatingOrigin.step` on each axis (so every shifted position is exact in float and the origin stays exact in double): the origin ends up at the nearest multiple of the step, and `shift` says by how much it moved. It does what the engine does by itself when the anchor goes past `world.floatingOrigin.threshold`, on demand, for tests and cutscenes. Without `origin` and `entity` it centres on the project's anchor. Fails when floating origin is not enabled in the project (set world.floatingOrigin.enabled in factoria.json), when `origin` (or `offset`) and `entity` are both given, and when the shift is more than 16777216 steps (a float cannot hold it exactly): shift in several rebases. Scripts hear one `originShifted` event. Result: {origin, shift (the amount subtracted from every position, [x, y, z]: the `offset` of the `originShifted` event), shifted (root entities moved), rebases}. Example: world.rebase {"origin":[5000,0,0]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `origin` | array | no | The new origin (not a delta): world metres [x, y, z] as doubles, rounded to the step. |
| `offset` | array | no | Deprecated alias of `origin` (it is the new origin, not a delta, and not the `offset` of the originShifted event). |
| `entity` | string | no | Centre the origin on this entity's world position (an entity id). |

## `world.split_cells` (modifies state)

Not released yet (on main after 0.34.0).

Split a scene into streamable cells on a grid, with a manifest.

Capabilities: read, state, writeProject

Will cut the scene's entities into a grid of cells `cellSize` metres wide on X and Z, write one scene file per cell and the index `<name>.world.json` (the manifest: cell size, each cell's bounds and file, the entities that stay always loaded), and report what it wrote. `dryRun` only reports. Writes next to the scene unless `output` names a folder. Result: {cells, files, alwaysLoaded}. Example: world.split_cells {"scene":"scenes/world.scene.json","cellSize":128} Not built yet (planned, M75.3): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `scene` | string | yes | The scene file to split (project-relative path). |
| `cellSize` | number | no | Width of a cell in metres, on X and Z. Default 128. |
| `output` | string | no | Folder for the cell files (default: next to the scene). |
| `dryRun` | boolean | no | Only report what would be written. Default false. |

## `world.stream_status`

Not released yet (on main after 0.34.0).

Read what the world streaming is doing: loads in flight, budget, cells loaded.

Capabilities: read

Returns {enabled, world, cellsTotal, cellsLoaded, cellsLoading (jobs started and not applied yet), cellsQueued, cellsUnloading, inFlight, waitingToApply (read and parsed, not added to the world yet), anchors (enabled StreamingAnchor entities, and the camera with cameraLoadRadius), loadsStarted, loadsCancelled, cellsApplied, unloadsDone, bytesLoaded, appliedThisFrame, unloadedThisFrame, unitsThisFrame (the BackgroundLoader units of the last frame), maxLoadsInFlight, maxAppliesPerFrame, budget: {mode: "units" (exact, the same on every machine) | "timed", units | ms}, pending: [ids of the cells loading, then the queued ones, in the order they will be applied], lastError}. A game or a test waits until the cells around the player are in (pending empty and cellsUnloading 0). Read-only. Example: world.stream_status {}

