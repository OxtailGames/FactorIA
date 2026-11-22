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

## `world.absolute_position`

Not released yet (on main after 0.34.0).

Read an entity's position in double precision: the floating origin plus its local position.

Capabilities: read

Will return {entity, position: [x, y, z] (the origin plus the entity's world position, in doubles), origin: [x, y, z], local: [x, y, z] (the entity's world position in the engine's float space)} so a game far from the origin still knows where things are. Read-only. Example: world.absolute_position {"entity":"player"} Not built yet (planned, M75.4): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity id. |

## `world.cells`

Not released yet (on main after 0.34.0).

List the cells of the streamed world and which are loaded.

Capabilities: read

Will list every cell of the streamed world (the cells world.split_cells wrote): {cells: [{id, bounds: {min, max}, state: "unloaded" | "loading" | "loaded" | "unloading", entities, distance}]}, sorted by distance to the nearest StreamingAnchor. `state` filters the list. Read-only. Example: world.cells {"state":"loaded"} Not built yet (planned, M75.3): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `state` | string ["unloaded","loading","loaded","unloading"] | no | Only the cells in this state. |

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

Will return {enabled, origin: [x, y, z] (metres, doubles: the world position of the engine's local (0, 0, 0)), rebases (how many times the origin moved since the scene loaded), threshold, step, anchor} from the project's `world.floatingOrigin` settings and the running world. Read-only. Result (one shape, also when the floating origin is off, then enabled is false and origin [0, 0, 0]): {enabled, origin, rebases, threshold, step, anchor}. Example: world.origin {} Not built yet (planned, M75.4): the command exists so its name and arguments are fixed.

## `world.rebase` (modifies state)

Not released yet (on main after 0.34.0).

Move the floating origin now, shifting every entity so the camera is near (0, 0, 0) again.

Capabilities: read, state

Will move the origin to `offset` (double metres, world space) or to the position of `entity`, shifting every Transform, physics body, audio source and particle by the difference in one step, so nothing visible changes. It does what the engine does by itself when the anchor goes past `world.floatingOrigin.threshold`, on demand, for tests and cutscenes. Without `offset` and `entity` it centres on the project's anchor. Fails when floating origin is not enabled in the project. Result: {origin, shifted (entities moved)}. Example: world.rebase {"offset":[5000,0,0]} Not built yet (planned, M75.4): the command exists so its name and arguments are fixed.

| Argument | Type | Required | Description |
|---|---|---|---|
| `offset` | array | no | The new origin: world metres [x, y, z] as doubles. |
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

Will return {cellsLoaded, cellsLoading, cellsTotal, anchors, loadsStarted, unloadsDone, bytesLoaded, frameBudgetMs, pending: [cell ids waiting], lastError} so a game or a test can wait until the cells around the player are in. Read-only. Result: the fields above. Example: world.stream_status {} Not built yet (planned, M75.3): the command exists so its name and arguments are fixed.

