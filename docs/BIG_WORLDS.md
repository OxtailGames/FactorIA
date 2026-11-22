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
| [Levels of detail](#levels-of-detail-planned-m751) | M75.1 | screen-size thresholds, dithered cross-fade, impostors, HLOD |
| [Occlusion](#occlusion-m752) | M75.2 | occluders (CPU built; GPU planned), areas and portals (planned) |
| [Streaming](#streaming-m753) | M75.3 | cells loaded and unloaded around `StreamingAnchor`s |
| [Floating origin](#floating-origin) | M75.4 | positions stay exact far from the origin (works: the world, physics, audio and the renderer follow a rebase) |
| [Terrain](#terrain-m755) | M75.5 | heightmap terrain: drawn with a GPU level of detail and collision; the `terrain.*` commands sculpt, paint, cut holes and generate it, up to 8 layers blended by splat maps and holes |
| [Foliage](#foliage-planned-m756) | M75.6 | instanced vegetation and rocks, scatter rules |

`renderer.supports` (the `render.supports` command) already lists a row per renderer feature, `false` with the status
"planned (M75)" until its package lands (`lodCrossFade`, `impostors`, `occlusionGpu`, `foliage`); `occlusionCpu` and `terrain` are `true` on every backend. Ask
it before relying on one, as for every other feature (docs/RENDERING.md).

## Levels of detail (planned, M75.1)

`MeshRenderer.lods` already switches meshes by distance. M75.1 adds:

- `MeshRenderer.lodMode`: `"distance"` (default, the behaviour of every scene made before M75) or `"screenSize"`. With
  `screenSize`, an entry of `lods` is `{"mesh": "models/rock_lod1.glb", "screenSize": 0.25}`: the mesh replaces the one before it
  when the screen size drops below 0.25. Entries go from the largest `screenSize` to the smallest. The entries are saved and checked today: a
  `screenSize` that is not a number from 0 to 1 is an error, and an entry without the key of its mode, or whose `screenSize` is
  not below the one before it, is a warning, each with the JSON pointer of the entry.
- The screen size, for `MeshRenderer` and `LodGroup` alike, is the diameter of the world-space bounding sphere (of the mesh; of
  the whole subtree of a `LodGroup`) divided by the visible height at the entity's distance `d`: `2 * d * tan(fovY / 2)` in
  perspective, `2 * orthoSize` in orthographic. 1 = the sphere is as tall as the screen, 0.1 = a tenth of it. It is a fraction, so a
  threshold means the same at every resolution; it does change with the field of view, the zoom and the size of the object (a
  wider lens or a smaller object gives a smaller screen size), so tune thresholds with the camera the game uses.
- `MeshRenderer.lodCrossFade`: seconds a switch fades over (a dithered cross-fade, no popping). 0 = hard switch.
- `MeshRenderer.impostor` and `impostorDistance`: a baked ring of pictures that a camera-facing quad shows beyond the last LOD.
  `impostorDistance` is in the unit of `lodMode`. `impostor` empty means none.
- The `LodGroup` component on an entity whose children are the levels (child 0 the most detailed): `mode`, `thresholds` (one
  number per child but the first, at most 8, in the unit of `mode`, ordered), `crossFade`, and an HLOD proxy for a whole cell:
  `hlodProxy` (a mesh path) with `hlodThreshold` (needed when the proxy is set).
- `model.generate_lods {model, levels, ratios, errors, maxError, screenSizes, ...}` simplifies a model into lower levels
  (deterministic) and wires them for screen-size LOD: it is real, see "Automatic LOD chain" below.
  `model.bake_impostor {model, views, resolution, apply}` bakes the impostor atlas and fails with `not_built` today.
- `renderStats` gets `lodCrossFades` and `impostors` (this frame's counts).

### Automatic LOD chain

A model document's `gameReady` can make the LODs for you. `lodChain` is an alternative to the explicit `lods` list (giving both is an
error); it is an import setting like the others of `gameReady` (docs/modeling/MODELING_GAME.md):

```json
"gameReady": {"lodChain": {"enabled": true, "levels": 3, "ratios": [0.5, 0.5, 0.5], "screenSizes": [0.5, 0.25, 0.12]}}
```

| Field | Meaning |
|---|---|
| `enabled` | Make the chain (default false). |
| `levels` | 1 to 7 lower levels besides the full mesh (default 3). |
| `ratios` | One per level: the share of the triangles of the level above it keeps (default 0.5 each). Level `i` is simplified from the full mesh to the product of the first `i` ratios. |
| `errors` | One per level: the most the surface may move, metres (0 or left out = no limit). `model.generate_lods` also takes `maxError` for all levels. |
| `screenSizes` | One per level, falling (each in 0..1): the level is drawn when the model covers less than this. Default 0.5, 0.25, 0.12, 0.06, 0.03, 0.015, 0.008. |
| `minTriangles` | A level that would have fewer triangles than this, and every level after it, is not made, and a note says so (default 32). A model smaller than that gets no LODs. |
| `lockBorder` | Open edges (the borders of the surface) do not move (default true). The seams between parts are kept either way, so a part never comes apart from its neighbour. |
| `normalWeight`, `uvWeight` | How much a collapse that bends a normal (default 1) or smears a UV seam (default 0.5) costs, so seams and shading stay where the simplifier can keep them. |

The bake writes `<name>.lod1.glb`... and `<name>.prefab.json` whose `MeshRenderer` has `lodMode: "screenSize"` and
`lods: [{"mesh": "<name>.lod1.glb", "screenSize": 0.5}, ...]`. A screen size is the one defined above (bounding-sphere diameter
over the visible height), so a threshold of 0.25 means the model is a quarter of the view tall, whatever the resolution. The
same input gives the same bytes on every platform (the simplifier is serial and deterministic).

`model.generate_lods {model, levels?, ratios?, errors?, maxError?, screenSizes?, minTriangles?, lockBorder?, normalWeight?,
uvWeight?, dryRun?, bake?, overwrite?}` turns the chain on for a model document (`model` is the `.model.json` or the `.glb` it baked
to), writes the settings into it, bakes, and returns `{levels: [{level, file, triangles, vertices, ratio, error, screenSize}],
fullTriangles, prefab, notes, warnings}`; `dryRun` only reports. `model.import_clean {source, lodChain: true}` makes the chain on
import. A list of the wrong length, `screenSizes` that do not fall, or a document that already has distance `lods` is an error
with its JSON pointer, and nothing is written. `model.game_ready {path, lodChain}` changes the chain by hand and `{"lodChain": null}` removes it (the next bake deletes the `.lodN.glb` files and the prefab's `lods`).

Skinned meshes are refused: the simplifier moves and removes vertices and the skin weights would not follow, so `model.generate_lods`
on the `.glb` of a rig says so and points at the static model (`rig.bake` reads it); a `.glb` that no model document baked is
refused with `model.import_clean` as the way to make a document of it. Only the screen-size LOD of the renderer (P1a) draws the chain
by `screenSize`; until then `lodMode: "screenSize"` entries are saved and checked, not yet selected.

## Occlusion (M75.2)

Meshes hidden behind big solid ones are not drawn. **Built: the CPU occluders** (`Occluder`, `renderer.supports` `occlusionCpu`).
**Planned: `OcclusionArea`, `OcclusionPortal` and the GPU path (`occlusionGpu`)**: the two area components save and load today and do
nothing.

- `Occluder` on an entity: `shape` (`"box"` or `"mesh"`), `size` and `center` (metres, a box, before the entity's scale), `mesh`
  (the mesh to rasterise; empty = the entity's `MeshRenderer.mesh`), `enabled`. The box follows the entity's drawn matrix (its
  `Transform` scale and rotation, and its parents'). A `shape` `"mesh"` with no mesh and no `MeshRenderer`, or whose mesh cannot
  be read, hides nothing and logs one warning that names the entity.
- `OcclusionArea` (a room): `size` in metres, `areaId` 1..65535 (0 is "outside every area"). `OcclusionPortal` (a door or window
  between two areas): `size`, `areaA`, `areaB` (the ids on its -Z and +Z side), `open` (a shut door blocks sight). Meshes in an
  area are drawn only when a chain of open portals leads from the camera's area to it. **Planned**, see above.
- `renderStats` has `occluders` (the Occluders rasterised this frame, summed over the cameras), `occlusionTests` (the meshes tested
  against a depth buffer) and `meshesOccluded` (the ones proved hidden and left out of the main pass). All three are 0 when no
  enabled Occluder is in the scene.

### How the CPU path works

The renderer does nothing until an enabled `Occluder` exists in the scene (one `world.any<Occluder>()` check per frame); a scene
without one draws and counts exactly as before. With one, for every main-view camera, after the frustum test:

1. Every enabled Occluder of the camera's scene is rasterised into a small depth buffer, **256 cells across** and `256 / aspect`
   down (144 for a 16:9 camera, at least 16 and at most 512), plus a guard ring of one cell. A box is its 12 triangles, a mesh its
   triangles (`MeshRenderer.mesh` or `Occluder.mesh`, the first ones if it has more than the cap below). Only faces that look at
   the camera are drawn, the triangles are clipped against the near plane, and the work runs as jobs on the job system
   (`render.occlusion_setup`, `render.occlusion_raster` in the profiler): the buffer is the same bytes with any number of
   threads.
2. The world-space bounding box of every mesh the frustum kept (instanced and skinned meshes included: they go through the same
   gather and use the box the frustum test uses) is projected and compared with the buffer. A mesh whose box is entirely behind
   occluders is marked not visible and is left out of the main pass (`meshesOccluded`). Meshes without known bounds and the
   Occluder's own mesh are never tested.

It is **conservative**: when in doubt, the mesh is drawn. A mesh is tested against the cells its box covers and one ring of cells
around them, the depth stored in a cell is the farthest the occluder can be inside it, and the guard ring keeps a box at the
screen edge from reading outside the buffer. A box that crosses the near plane, holds the camera or has a corner behind it is
visible. A camera inside an Occluder gets no occlusion from it (its back faces are not drawn). The occluders themselves are never
culled by their own depth.

What it does not do:

- **Shadow passes are not culled.** A mesh hidden from the camera still casts its shadow, because a shadow can fall into the picture
  from an object the camera does not see. Reflection probe, GI and light-probe captures are not culled either.
- **Sprites, 2D shapes, tilemaps, particles and UI are out of scope**: only 3D meshes are culled.
- A mesh Occluder with a crack narrower than a cell (about 1/256 of the picture) hides what shows through the crack: use closed,
  simple meshes, or `"box"` (a few hundred triangles at most, a low-poly proxy of the building).
- Two neighbouring Occluders with a gap narrower than a cell (about 1/256 of the picture) between them hide what shows through the
  gap as well: overlap the walls or let them touch.
- Every cell is tested, not every pixel: an object that peeks out of the silhouette of an occluder by less than a cell or two is
  drawn anyway (that is the price of never hiding what is visible).

### Caps (counted in triangles, never in time)

| Cap | Value | When it is reached |
|---|---|---|
| Triangles of one Occluder | 4096 | only the first 4096 are rasterised (the occluder hides less, never more); one warning names the entities and the cap |
| Triangles of all the Occluders of one camera | 65536 | the nearest Occluders (distance of their origin, then entity) are kept first; the others are left out or cut; one warning names them |

The caps count source triangles, not the work of the raster: a few huge triangles that fill the view (an occluder right in front of the
camera) touch every cell, which costs at most the cells of the buffer (about 37 000 for a 16:9 camera) per triangle, and the buffer
is small on purpose. The same scene gives the same result with any number of job threads (the float rounding of different CPU architectures can differ in
the last bit, so a box exactly at the edge of an occluder may be judged differently there). Warnings are logged once per run.

### Looking at it

- `render.occlusion {save?}` reports the last frame: the size of the buffer, the Occluders and triangles rasterised, the meshes
  tested and the ones hidden; with `save` (a `.png` path) it writes the depth buffer as a grey picture (black = no occluder, the
  nearer an occluder, the brighter). The same is `Renderer::occlusion_report` in C++.
- `render.debug_view {"view":"occlusion"}` (or `FA_RENDER_DEBUG_VIEW=occlusion`) keeps the game picture and draws the Occluder
  boxes green and the boxes of the meshes the culling left out red, with a line of counts at the top left. The boxes are drawn
  from the next frame.
- `render.supports {"feature":"occlusionCpu"}` is `true` on every backend (the rasterizer runs on the CPU).
- A scene that wants to know whether the culling is worth it compares `renderStats.meshes`, `drawCalls` and `meshesOccluded` with
  the Occluders on and off (`Occluder.enabled`).

Tune: put Occluders on the big solid things (walls, buildings, hills as a few boxes), not on small props: a box costs 12
triangles and a few microseconds, and the more of the picture the occluders cover, the more the culling saves.

## Streaming (M75.3)

A big world is cut into **cells**: one scene file per square of the world, and an index file that lists them. The engine
loads the cells around the `StreamingAnchor` entities (usually the player) and unloads the ones left behind, so a world of
any size costs what the part around the player costs. The reading and parsing of a cell happen off the main thread; only the
creation of its entities is on the main thread, within a budget per frame. Nothing here changes a game without a
`StreamedWorld` component.

Parts that are not built yet: `world.split_cells` and `world.merge_cells` (they fail with `not_built`; for a tilemap use
`tilemap.split_cells`, below) and the debug view of the cells (planned, M75.3c).

### The world index

The index is a file `<name>.world.json`.

```json
{
  "format": "factoria.world/1",
  "version": 1,
  "dimension": "3d",
  "cellSize": 128,
  "origin": [0, 0],
  "cells": [
    { "coord": [0, 0], "scene": "cells/0_0.scene.json",
      "bounds": { "min": [0, 0, 0], "max": [128, 20, 128] }, "sizeBytes": 18234 },
    { "coord": [-1, 2], "scene": "cells/-1_2.scene.json",
      "bounds": { "min": [-128, 0, 256], "max": [-1, 12, 383] } }
  ]
}
```

The schema is `schemas/world.schema.json`.

- `dimension`: `"3d"` lays the cells on the XZ plane (the height never matters), `"2d"` on the XY plane (the Z of an anchor never
  matters). In a 2D index `bounds` has two numbers per corner.
- `cellSize` (0.5 to 1,000,000 units) and `origin` (two numbers): cell `[i, j]` covers `origin + [i, j] * cellSize` up to one
  `cellSize` more on each axis of the plane. `coord` is an integer pair, at most 1,000,000 in absolute value; an index has at most
  262,144 cells.
- `bounds` is what the entities of the cell cover, **absolute**, and must lie inside the cell's square. A radius is measured to
  these bounds: an anchor inside them is at distance 0.
- `scene` is a project-relative scene file. `sizeBytes` is optional (a hint for the debug view).
- Cells are listed in any order; the engine sorts them by `[j, i]` and uses that order to break every tie.

`factoria validate` (the command `project.validate`) checks every `*.world.json` of the project, every cell's scene file included however big the index is, and the
streamer checks the index when it first needs it; either refuses it with every problem found (the first
eight in the message, then "and N more"): each one has the file, the JSON pointer (`worlds/main.world.json#/cells/4/bounds/max`),
what is wrong and how to fix it. Two cells with the same `coord` name both entries; a scene file that does not exist says
"Did you mean" with the files that do; bounds outside the cell say which axis and what the cell covers. A wrong index loads
nothing and `world.stream_status` shows the text in `lastError`; it is read again only when the `StreamedWorld.world` path
changes. The streamer does not check the files of an index of more than 4096 cells when it reads it (a cell whose file is missing then
fails when it is loaded and is reported the same way); `factoria validate` always checks them all.

### The component `StreamedWorld`

Put it on one entity of the main scene. `world` is the path of the index; `enabled` (default true) turns streaming off, and
everything loaded unloads; `maxLoadsInFlight` (default 2, 1 to 16) is how many cells load at the same time; `maxAppliesPerFrame`
(default 1, 1 to 64) is how many cells are added to or removed from the world per frame; `keepLoaded` (a debug aid: it costs O(cells) per fixed tick) loads every cell whatever
the anchors say; `cameraLoadRadius` and `cameraUnloadRadius` make the active camera an anchor (0, the default, means it is not:
put a `StreamingAnchor` on the player instead; an unload radius of 0 means 1.25 times the load radius). Only the first enabled
`StreamedWorld` of the scene counts, and a second one is a warning in the log.

### Which cells are loaded

Every fixed tick the streamer reads the anchors (every enabled `StreamingAnchor` on an active entity, plus the camera when
`cameraLoadRadius` is set) and decides, from their positions alone:

- a cell is **wanted** when it is within an anchor's `loadRadius`, measured on the plane of the world from the anchor's
  absolute position to the cell's bounds. The position is the floating origin plus the local position (`World::absolute_position`, in doubles), and
  the index's bounds are absolute, so the cells loaded do not change when the origin moves;
- a cell that is loaded or loading is **kept** until it is farther than the `unloadRadius` of every anchor. The gap between the two
  radii is the hysteresis: an anchor that walks along a border does not load and unload a cell every frame;
- the wanted cells are started in the order of the highest `priority` of the anchors that want them, then the smallest distance,
  then `[j, i]`; at most `maxLoadsInFlight` at a time (a cell counts as in flight from the start of its load until it is applied);
- a load that is queued or running for a cell that is no longer kept is cancelled, and its result is thrown away; a cell that
  fails to load (a missing or broken file) is tried again after 120 fixed ticks while it is still wanted, at once when it has left
  the wanted set and come back, and `lastError` of `world.stream_status` clears when that cell loads well.

### How a cell is loaded

A cell load is a `BackgroundLoader` job of its own kind (`cell.load`, docs/design/ARCHITECTURE_THREADS.md, repository only, not in the binary): its scene file and the
files the scene names are read and parsed on the IO thread and the job pool, and the parsed scene waits for the main thread. The
job takes its share of the loader's budget like every other load: with the exact budget (tests, headless runs, the editor) four
units per frame in total, shared by the jobs in the order they started; with a window, the milliseconds of `loadBudgetMs`.
`world.stream_status` shows which of the two (`budget`). The loads and applies depend only on the anchors at the fixed ticks and
on the unit budgets, never on how fast the machine reads files: the same run loads the same cells in the same order.

Per frame the main thread then unloads first, in `[j, i]` order, and applies the loaded cells in the order their jobs started, up
to `maxAppliesPerFrame` in all. Applying a cell:

1. creates its **root entity**, named `cell i,j` with id `cell_i_j` (its `streamedCell` flag is set), at the ABSOLUTE (0, 0, 0) (its local position is minus the floating origin, and a rebase moves it like any root);
2. adds the entities of the cell scene under it, additively: their positions in the file are ABSOLUTE positions, and the scene load
   lands them under that root, so a cell lands at its absolute place whatever the origin is now (a load under a parent is placed by
   the parent: the scene load shifts only the roots of a load that has none);
3. sends the game event `cellLoaded`.

Unloading sends `cellUnloaded` and destroys the root and everything under it. A 3D collider joins the physics world when its
cell is applied and leaves it at the next fixed step after the cell is unloaded, so no stale body is left. If the main scene
changes (`scene.load`, a new game), every cell job is cancelled, nothing is applied to the new scene and the streamer starts again
from nothing.

Rules for the cell scenes:

- **Entity ids are unique across the whole world.** An id that is already taken is renamed with a warning. Name entities
  `floor_3_-2`, not `floor`.
- A reference from an entity to an entity of **another cell** cannot be resolved: that cell may not be loaded. The field stays
  empty and the loader logs a warning with the field's pointer. A reference to an entity of the main scene works. To connect two
  cells, listen to `cellLoaded` and set the field with `world.find(id)` there.
- A cell is **not part of the main scene when it is saved**: `scene.save` and the editor's save leave out the cell roots and
  everything under them. Edit the cell's own file.

### Events

`world.on("cellLoaded", (d, root) => ...)` and `world.on("cellUnloaded", (d) => ...)`. The data of `cellLoaded` is
`{ world, id: "3,-2", coord: [3, -2], scene, entities, bytes }` and `root` is the cell's root entity; `cellUnloaded` sends the
same without `bytes` (`entities` is how many the cell had) and with no source: the root is already being destroyed. The events are
queued when the cell is applied or unloaded and delivered with the other game events of the next dispatch. Listeners end with the scene, like every `world.on`.

### The streaming commands

- `world.cells {state, limit}` lists the cells of the index sorted by distance to the nearest anchor (cells with no anchor
  last): `{world, dimension, cellSize, total, matching, truncated, cells: [{id, coord, scene, bounds, state, entities, distance,
  sizeBytes?, failed?}]}`. `state` is one of `unloaded`, `queued`, `loading`, `loaded` and `unloading` and filters the list;
  `limit` is 1 to 100000 (default 1000). Without a `StreamedWorld` or with a wrong index it fails with the code
  `no_streamed_world`, and the message says why.
- `world.stream_status {}` says what streaming is doing: `enabled`, `world`, the cells per state (`cellsTotal`, `cellsLoaded`,
  `cellsLoading`, `cellsQueued`, `cellsUnloading`), `inFlight`, `waitingToApply`, `anchors`, the totals since the scene started
  (`loadsStarted`, `loadsCancelled`, `cellsApplied`, `unloadsDone`, `bytesLoaded`), what the last frame did
  (`appliedThisFrame`, `unloadedThisFrame`, `unitsThisFrame`), `maxLoadsInFlight`, `maxAppliesPerFrame`, `budget`, `pending` (the
  cells that are not at rest) and `lastError`. A test steps frames until `pending` is empty and `cellsQueued` is 0.

Both are read-only. A script that waits for them checks that its scene is still the current one first. Tests count units of work,
not milliseconds, so a result does not depend on the speed of the machine.

### Tilemap chunks (2D worlds)

A big 2D level is one `Tilemap` that is too large to keep loaded. `tilemap.split_cells {scene, tilemap?, cellSize?, out?,
overwrite?, dryRun?}` cuts it into a `"dimension": "2d"` world index plus one chunk scene per cell, and the streaming above does
the rest.

- `cellSize` is the side of a cell in TILES (1 to 4096, default 32), so a cell is `cellSize * tileSize` units wide and every cell
  edge falls on a tile edge. `tilemap` names the entity when the scene has more than one Tilemap. The index goes to `out`
  (default: the scene's name with `.world.json`) and the chunks to `<index name>_cells/<i>_<j>.scene.json`; `dryRun` lists them
  without writing; a second run over files that exist is refused unless `overwrite` is true. The result lists the files, the
  cell grid, `emptyCellsSkipped` and `notes`.
- Cell `[i, j]` covers `origin + (i, j) * cellSize` on x and y, counted from the BOTTOM-left corner of the map: the index
  `origin` is that corner (the Tilemap's position minus its height), nothing is rounded, and when the map does not divide by
  `cellSize` the top row and the right column of cells are the ones cut short, not padded. A cell with no tile at all is not
  written. Each chunk holds one Tilemap entity (the same name, tileset, tile size, `solidTiles`, `terrains`, layers and other
  fields as the source) at the cell's top-left corner, with the tiles of its square only (flip and rotation flags kept).
- Files: the index and the chunks are written under the caller's write rules (project files only, never `.git/` or
  `.factoria/`, a folder that is a symlink out of the project is refused, an absolute path only for a caller that may write
  anywhere), and never over the source scene, `overwrite` or not.
- The command is deterministic: the same scene and arguments give the same bytes. It never changes the source scene. Chunk files
  of an earlier split with more cells are not deleted: remove them by hand.
- Rendering: chunks are separate Tilemap entities at exact multiples of the tile size, so tiles line up with no seam or gap.
  Physics: each Tilemap is one static body, so a body that slides across a chunk border would catch on the hidden edge between
  two neighbouring boxes (Box2D has no ghost-edge handling for polygons). The 2D physics therefore drops the contact of a
  tile side that is shared with a solid tile of the neighbouring chunk, so tile collision across chunks is the same as in the
  unsplit map. This applies to orthogonal tilemaps; isometric and hexagonal projections and tiles that are not square are
  not given this treatment.
- Autotile: terrain rules are baked into the `tiles` when you paint, not evaluated at load, so the split map has exactly the
  tiles the unsplit one had, including the ones across a border. What does not carry over is painting with `tilemap.paint` into a
  chunk that is not loaded: the neighbour is not there to update. Paint into the source scene and split again, or load the
  neighbouring cells first.
- `project.validate` compares the chunks of every 2D index: another tileset, tile size, columns, margin, spacing or projection
  than the first chunk is an error with the file and the JSON pointer of the cell, a chunk that is off the tile grid is an
  error, and a chunk outside its cell is a warning (it reads at most 4096 cells).
- Floating origin: chunks load at their absolute position (the file's position minus the world origin), so a rebase between two
  loads leaves the tiles and the collision where they were; far from zero, keep the floating origin on, because a float32
  position loses its precision beyond about 8000 units (a tile of 16 units is still exact at 100000).

### The anchors

- `StreamingAnchor` on an entity (usually the player or the camera): `loadRadius` (metres: cells nearer than this load),
  `unloadRadius` (cells farther than this unload; it must be above `loadRadius`, the gap is the hysteresis that stops a cell from
  loading and unloading every frame), `priority` (the anchor with the higher one gets its cells first), `enabled`. The radii are
  measured on the plane of the streamed world: x and z for a world index whose dimension is `"3d"`, x and y for `"2d"`. Distances use
  absolute positions (the floating origin plus the local position), so a rebase of the origin never changes what is loaded.
- `world.split_cells {scene, cellSize, output, dryRun}` cuts a scene into a grid of cells and writes the files and the index;
  `world.merge_cells {manifest, output, dryRun}` joins them back so a level can be edited as one file. They write project files and
  fail with `not_built` today.

## Floating origin

`Transform` stays a float, which has a precision of about a millimetre at 8 km and a hand's width at 100 km. Far from the origin
things shake. The floating origin keeps what is near the camera near (0, 0, 0): the world holds a double-precision origin (`DVec3`
in `fa/core/math.h`), and when the anchor goes past a threshold the engine moves everything by a whole number of steps, at the end
of a fixed tick (so it is deterministic), in one step with no frame where two systems disagree.

Off by default and free when off (one branch per fixed tick); a game opts in in `factoria.json`:

```json
"world": { "floatingOrigin": { "enabled": true, "threshold": 2048, "step": 256, "anchor": "camera" } }
```

| Key | Default | Meaning |
|---|---|---|
| `enabled` | `false` | turn the floating origin on |
| `threshold` | `2048` | metres from the local origin at which the anchor causes a shift (16 to 10 000 000) |
| `step` | `256` | the origin moves by whole multiples of this, so repeated shifts stay exact: an integer power of two from 1 to 1 048 576 (2^20), so every shift is an exact float operation. Left out, it is the largest power of two at most `min(256, threshold)`, so `{"threshold": 128}` alone is valid (step 128). When you write it, it must not be above `threshold` |
| `anchor` | `"camera"` | `"camera"` (the first rendering camera) or `"entity:<id>"` (the entity with that id) |

A wrong key, number or anchor is an error that names the JSON pointer (`/world/floatingOrigin/step`) and the fix.
`"enabled": false` with the other keys at their defaults is not written back.

### When it shifts

After each fixed tick, when the anchor is farther than `threshold` from the local origin on ANY axis (x, y or z: a flight game
climbs, a ground game never has a large y), the engine rebases by the anchor's position rounded to the nearest multiple of `step`
on each axis. Then the anchor is near (0, 0, 0) again. A camera that is an entity of a hierarchy is measured by its world
position.

Why a whole multiple of a power of two: a float far from the origin is a multiple of its own spacing (a power of two), so
`p - k * step` with `step` at least that spacing is a float again with NO rounding, whatever `k` is. The origin (a double) only
ever holds sums of multiples of `step`, exact up to 2^53 steps, so a rebase by `+offset` and then by `-offset` gives back every
position and the origin bit for bit. An arbitrary offset (1234.567) would round every position it moves, and each shift would add
its own error to the origin. `world.rebase` refuses an offset that is not a multiple, or that is more than 16 777 216 steps
(a float cannot hold that many exactly), and says the nearest valid one.

### What moves

A rebase subtracts the offset from every ROOT `Transform` (children follow: their position is local to the parent) and adds it to
the world's origin, and in the same step:

- 3D and 2D physics: bodies, the broad phase, the contacts and their caches, kinematic targets, joint anchors pinned to a world
  point, the sleeping state (a sleeping body stays asleep, and nothing wakes) and character controllers. The 2D shift is exact in
  metres only when `pixelsPerMeter` is a power of two; with any other value (the default 100) Box2D's metres and the Transform's
  pixels convert with a rounding of about one ulp per rebase.
- Navigation: baked meshes and grids (they are shifted, not baked again) and off-mesh links. A path a script got from
  `nav.findPath` is a list of local positions it keeps: after an `originShifted` event ask again (or keep absolute positions).
- Audio: listener and source positions (velocities do not change, so there is no doppler spike).
- World-space particles and their trails, queued game-feel spawns and effects aimed at a world point, the render interpolation
  records (no jump at the next frame), light-probe group points, tweens that hold a position (`tween.position` and the like
  follow the shift, from the next tween tick on even when the shift came from a command or a script between two steps, so no
  tween ever writes the old position; a tween on a screen-space entity does not).
- A root with `Parallax` moves by `offset * factor` on x and y (z by the whole offset), not by `offset`: it is drawn at its
  position plus `camera * (1 - factor)`, so this keeps what the player sees (drawn minus camera) the same when the camera
  moves by `-offset`. Factor 1 moves as any root, factor 0 (glued to the camera) does not move. The shift is exact in float for
  a power-of-two factor (0.5, 0.25, 1); any other factor rounds the layer by about one ulp of its position per rebase.
- Roots that are screen-space do NOT move: UI widgets (`Panel`, `Button`, ...) and `Sprite`, `Shape2D`, `Text` or
  `ParticleEmitter` with `space: "screen"`. Their position is an offset on the screen.

A scene holds ABSOLUTE positions: it saves `"origin": [x, y, z]` next to its entities (only when it is not zero) and the
positions are local to that origin. A normal (non-additive) load restores the origin, so everything is where it was. An
ADDITIVE load keeps the origin of the world it joins and places what it loads at its absolute position: every loaded root
Transform (and every world-anchored joint, `NavLink3D.end` and `LightProbeGroup` point among the loaded entities, the same set
a rebase moves, a Parallax root by its factor) moves by `file origin - world origin`, computed in doubles. A file without an
`origin` has origin 0, so a cell saved at origin 0 and loaded additively into a world at origin 4096 lands at `-4096` locally
and its `absolute_position` is what the file says. Streaming relies on this. Roots loaded under a `parent` are relative to it
and do not move.

### What scripts must do

Scripts hear one `originShifted` event per rebase: `game.on("originShifted", ({ offset, origin }) => ...)`, both arrays of three
doubles (metres), `offset` what was subtracted from every local position and `origin` the new origin. It runs in the next
`dispatchEvents`, after the shift: positions read in it are already the new ones.

- Never keep a world position across a tick in a game that enables the floating origin: after a rebase it is wrong by `offset`.
  Keep `entity.absolutePosition` (an array of three doubles: the origin plus the world position) and compare in absolute terms, or
  subtract `offset` from what you kept when the event arrives.
- `entity.position`, `entity.worldPosition` and everything else you read stays local (float) and is what you write back.
- `game.origin` is the current origin (doubles).

### Floating origin commands

`world.origin {}` reads the origin; it always returns one shape, `{enabled, origin, rebases, threshold, step, anchor}` plus
`anchorPosition` (the anchor's local position, `null` when there is none); with the floating origin off `enabled` is false,
`origin` `[0, 0, 0]` and `rebases` 0. `world.rebase {origin | entity}` moves the origin on demand (tests, cutscenes): `origin` is the
NEW origin in world metres (rounded to a multiple of `step`; not a delta, and not the `offset` of the `originShifted` event, which
is what was subtracted), `entity` centres on that entity, neither centres on the anchor. `offset` is the deprecated old name of
`origin`: it still works, and giving both is an error. It
fails with `not_enabled` when the setting is off. `world.absolute_position {entity}` returns `{entity, position, origin, local}`:
`position` is the origin plus the entity's world position, in doubles, and `local` the float position everything else reads. In C++:
`World::origin()`, `absolute_position(Entity)`, `to_local(DVec3)`, `to_absolute(Vec3)`, `rebase(Vec3)`, `rebase_count()` and
`on_origin_shifted(callback)` (one call per rebase, with the offset).

### What the renderer does

The renderer is an observer of the world it draws (`World::on_origin_shifted`, registered by `update()` / `render_world()` for the
world they are given, and removed when the renderer shuts down or is given another world; a world destroyed first takes the
observer with it). On a rebase it moves, by the same offset, what it keeps in world space from one frame to the next, so the frame
drawn after a rebase is the frame it would have drawn without one: no smear, no flash, no jump.

- **Motion blur and every effect that reprojects**: the view-projection of the frame before is rebuilt as if the previous camera had
  been `offset` farther, so a static object has a zero motion vector on the frame of the rebase. The cameras `world_to_screen`,
  `entity.bounds()` and picking answer from are rebuilt at once, so a script reading them in the `originShifted` event sees the new world.
- **Shadow cascades**: the texel grid of each cascade is fixed in ABSOLUTE space (the snap is done on origin + position in double), so
  a shadow stays on the same texels through a shift, whatever the texel size. Without a floating origin it is the plain snap.
- **2D global illumination**: the field's texel grid is fixed in absolute space too, and the geometry and the history origin of the
  field move with the world. The irradiance history (the bounce) is kept: the field lies on the same absolute texels, so the shift
  between the history and the new frame is the camera's own movement (0 for a still camera), and the bounce is not primed again.
- **Realtime GI grids**: the layout and the anchor that decides whether a grid moved by half a spacing shift with the world, so no
  probe is captured again and the grid stays `ready`.
- **Height fog and volumetric fog**: `fogHeightBase` and `volumetricHeightBase` are absolute heights, so they are used as
  `base - origin.y` in local coordinates: a rebase on y does not move the fog layer. (`cloudAltitude` and the like are not positions of the
  world.)
- The occlusion debug boxes of the frame before shift too. Everything else the renderer draws from is rebuilt from the world each
  frame (the cameras, the occluders, the terrain selection and its tile boxes, the 2D shadow rows, the light clusters, the particles and
  trails, the probe volumes) or lives in a space that does not change (screen space, a terrain's own heights).

Free when unused: a world that never rebases never calls the observer, and the cost of watching a world is one pointer compare per
frame. A renderer that draws two worlds alternately registers in the one it is given each frame. The callback runs on the main thread
between frames (after a fixed tick, a command or a script), when no render job exists.

## Terrain (M75.5)

The `Terrain` component draws a heightmap with a GPU level of detail and gives it a collider. In a scene and in scripts it is
called `Terrain` (the C++ type is `Terrain3D`: `Terrain` is already the 2D autotile type). **What it does:** the heightmap is drawn as tiles that coarsen with distance, painted with up to 8 material layers blended by the
splat maps (P5d), with the holes cut out of the surface, its shadow and its collider, lit and shadowed like a mesh; `collision`;
the counters; and the commands that create, sculpt, paint, cut holes in and generate a terrain, with undo (below). The brushes in
the editor are P5c.

| Field | Meaning |
|---|---|
| `heightmap` | 16-bit greyscale PNG or `.r16` file (raw little-endian 16-bit, square: its side is `sqrt(bytes / 2)` samples, so 1025 x 1025 is 2 101 250 bytes); empty = flat at `heightOffset`. The side must be 2^n + 1 (33 to 4097); a side of 2^n is padded by one sample. An 8-bit PNG is accepted with a warning (256 heights: terraces) |
| `size` | metres `[x, z]` the terrain covers, centred on the entity, each above 0 and at most 100 000. The heightmap is stretched over it: a 1025-sample map over 2048 m has a sample every 2 m, and resolution and `size` are independent |
| `heightScale`, `heightOffset` | metres of height of a white sample, and metres added after it |
| `splatMaps` | up to 2 RGBA PNG paths; channel c of map m weights `layers[4 * m + c]` (`terrain.paint` writes them). Each map has its own size (16 to 4096) and is read bilinearly; the eight weights of a pixel are normalised to add up to 1. No map, or a pixel no layer is painted on: `layers[0]` |
| `layers` | up to 8 of `{albedo, normal, tileSize, roughness, metallic, normalScale}`. All the albedo textures share one size (at most 4096 x 4096), and so do all the normal textures: the layers become 2D texture arrays with a full mip chain, because 8 layers of separate textures would need more than the 16 sampler pairs a shader stage can read. A size that differs is an error with the pointer (`/layers/3/albedo`) and both sizes. A texture that is missing or unreadable is said once and its layer is a neutral grey (albedo) or flat (normal). `roughness`, `metallic` and `normalScale` are per layer; `tileSize` is the metres one repeat covers. Without layers the terrain is a neutral lit grey |
| `holes` | greyscale PNG; a pixel of 128 or more cuts a hole (caves, wells), one pixel per CELL (`terrain.holes` writes it). Cut out of the surface, its shadow and its collider; `terrain_sample` and `terrain_height_at` report no ground there |
| `lodQuality` | multiplier of the distances where the terrain coarsens (see below) |
| `castShadows` | the terrain casts shadows (the tiles outside the camera still cast, at the levels the camera chose) |
| `collision` | the automatic static collider (see below) |

**How it is drawn.** The terrain is a quadtree over its heightmap. A node of level `l` covers `32 * 2^l` cells and is drawn as one
shared 33 x 33 patch (2048 triangles), instanced, so the finest tiles are 32 cells wide whatever the map's size. The vertex shader
reads the height of each vertex from an RG8 texture of the heights (vertex texture fetch: GLES3 and WebGL2 need no more), and the
vertices of odd row and column morph toward the next coarser level as the camera leaves the level's range, so a tile never shows a
crack or a pop against its neighbour. The normals come from the height texture in the fragment shader (shading does not change when
a tile changes level), and the material is the mesh pipeline's: shadow maps, the depth prepass, SSAO, fog, clustered lights and the
post stack treat it as a MeshRenderer. The tiles are chosen on the CPU for each camera by the jobs system, culling every node's box
against the frustum (against nothing when `castShadows`, so the shadow cascades see the terrain around the camera).

`lodQuality` (clamped to 0.1 to 4) scales the distances: the range of level `l` is `3 * 32 * 2^l * cell * lodQuality` metres (never less than three node
sizes beyond the level below), measured on the ground plane and in the terrain's own space, before `Transform.scale`. Above 1 the finer levels reach
further, below 1 the finest levels are dropped (0.5 drops the finest, 0.25 the two finest). The default 1 draws about a tile
per 32 cells near the camera. `renderStats.terrainTiles` and `terrainTriangles` count the tiles of the main pass and their
triangles (2048 each, also in `triangles`; tiles are not in `meshes`). `render.supports {"feature": "terrain"}` is true on every
backend, and its report has a `limits` object: `maxTextureSize` (the heightmap's side: a map of 4097 samples a side needs 4097, and a
GPU that offers 4096 does not draw it: an error says so once, with the largest side that fits, and the terrain is skipped),
`maxArrayLayers` (the layers of a texture array: 8 for the layers, 3 for the splat maps and holes) and `maxArrayTextureSize` (the side
of the layer textures and of the splat maps). A terrain whose layers or splat maps do not fit them is drawn with neutral grey layers and the log says why.

**Layers and holes.** The albedo and normal textures are two texture arrays, the splat maps and the holes are the slices of a third
one (RGBA8, one mip level, bilinear), so a terrain with layers reads 3 more textures in the fragment shader; the layers are blended
in the fragment shader, and only a layer with a weight above 0 at a pixel is fetched, so a pixel costs the layers painted on it. Albedo is sRGB (or
linear in a linear scene); normals are the usual tangent-space maps scaled by `normalScale`. The normals of the terrain itself come
from 12 height fetches a pixel (it was 16; the `terrain` rows of `tools/bench`, docs/performance/PERFORMANCE_BENCH.md). A hole is cut in the
GEOMETRY: a terrain with a holes mask draws every tile with a patch of 4 vertices per cell (4 times the vertices of the shared patch,
4096 against 1089, and the same 2048 triangles), and the vertex shader collapses the quad of a cell whose mask is set, so the main
pass, the shadows and the depth prepass all lose it, with no `discard`. The cut is exactly cell by cell at the finest level; at a
coarser level a quad stands for several cells and its middle cell decides, so a far hole can be a little larger or smaller. A
terrain without a holes mask keeps the shared patch.

**Cost.** Per terrain: 2 bytes per sample on the GPU (33.5 MB for 4097 x 4097) and on the CPU (the same, plus the tile bounds), and
with `collision` 4 bytes per sample more for the collider (67 MB); the layer textures take 4/3 of 4 bytes a pixel each (about 45 MB for
8 albedo layers of 1024 x 1024, refused above 256 MB per array with an error); the control array takes `side x side x 4` bytes a
slice. A sculpt (`TerrainHeights::mark_dirty`) updates the collider and the tile bounds only where the rectangle says, and uploads
only that rectangle of the height texture (a sub-rectangle copy through a staging buffer, one a frame). The first sculpt of a
terrain converts its texture to a copyable one and sends it whole once; a stroke after that costs the bytes of its rectangle. A
backend that cannot copy sends the whole texture, 33.5 MB for 4097 x 4097, on the frame after each `mark_dirty`: batch the edits to
one `mark_dirty` per frame. A paint or a hole stroke makes the control array again (a few MB) the frame after the planes change.
Selecting the tiles for one camera is a quadtree walk that visits a few hundred nodes, also for 4097 x 4097 (the timing is printed
by the `terrain_lod_tests.cpp` bench). A scene with no `Terrain` pays nothing: no texture, no program and no job.

**Collision.** `collision` (default true) makes the entity a static heightfield collider built from the same heights the renderer
draws, with the diagonal the patch triangles use, so a ray and the picture meet within float rounding. The cells of the holes mask
are left out of it (a ray, a ball and a character go through) and follow every hole edit. It needs no `Collider3D` or
`Heightfield3D`; an entity with its own `Collider3D` keeps that one, and a non-static `RigidBody3D` on the entity is refused with a
message. `Transform` position, rotation and scale apply as for `Heightfield3D`. A map larger than `Heightfield3D`'s 4096 samples
works here (up to 4097).

**For code that edits or reads the terrain (sculpting, foliage).** `world.terrain().heights(world, entity)` returns the shared
`TerrainHeights` (`data`, `samples`, `set`, `mark_dirty(rect)`, `version`); the renderer, the collider and the tile bounds each follow
its `dirty_since` history, so one `mark_dirty` updates all three. `terrain_sample(world, entity, worldX, worldZ, out)` and
`terrain_height_at` give the height (and the normal) of the surface that is drawn and collides, through the entity's transform;
they return false in a hole (no ground there: a ray, a foliage scatter or a script sees through it), which is a change from before
holes were cut, when they answered every point inside the grid. `terrain_splat_weights` and `terrain_layer_weights(world, entity, x, z,
out)` give the normalised weight of each layer at a point (what the shader blends), for foliage and for scripts.
The declarations are in `engine/scene/include/fa/scene/terrain.h`.

### Terrain commands

`factoria commands terrain.sculpt` prints every argument. All of them are `edits_project()` commands in the `world` category.

| Command | What it does |
|---|---|
| `terrain.create {name, size, resolution, heightScale, baseHeight, position, path}` | writes a flat 16-bit PNG heightmap (`resolution` 33 ... 4097, 2^k + 1, default 513; an existing file is never overwritten) and creates the entity with a `Terrain` that uses it. The flat surface sits at `baseHeight`, half way up the `heightScale` range, so it can be sculpted down as well as up. `heightmap` uses an existing file instead and writes nothing. It adds no `layers` (each needs an albedo texture: `scene.set_component`) |
| `terrain.sculpt {entity, tool, center or points, radius, amount, strength, height, save}` | `tool` is `raise`, `lower` (`amount` metres at the middle of the brush when `strength` is 1), `smooth` or `flatten` (toward `height`, world y, default the surface under the first stamp). The brush fades smoothly to 0 at its edge |
| `terrain.paint {entity, layer, center or points, radius, strength, splatResolution, save}` | raises the weight of `layer` (0 ... 7) and lowers the other 7 in proportion; every texel's 8 weights add up to 255 |
| `terrain.holes {entity, mode, center or points, radius, save}` | `mode` `cut` (default) or `fill` the cells whose centre is in the circle |
| `terrain.generate {entity, seed, frequency, octaves, fractal, amplitude, erosion, thermal, resolution, save}` | replaces the heights by seeded fractal noise (`fbm`, `ridged` or `billow`) and then `erosion` droplets of hydraulic erosion and `thermal` passes of thermal erosion. Without a heightmap, `resolution` makes a new grid and its file |
| `terrain.save {entity}` | writes the edited files (every terrain when `entity` is left out) |
| `terrain.undo {entity, save}`, `terrain.redo {entity, save}` | take back or re-apply the newest edit of that terrain |

**A brush is a circle in world metres.** `center [x, z]` is one stamp; `points [[x, z], ...]` (up to 4096) is a stroke, applied in
order, each stamp seeing the one before. The edit is **live in memory**: the renderer, the collider and every reader of
`TerrainHeights` follow it with ONE `mark_dirty` per command, so a stroke costs one texture upload. The files are written only when
you ask: `save: true` on the command, `terrain.save`, or any scene save (`scene.save`, the editor's Save). Each file is replaced
atomically. The brushes honour the entity's transform (position, rotation about Y, scale): `center` and `radius` are world
metres, and `amount` and `height` are world metres of height too. `radius` may cover at most 1024 samples (heights) or texels
(holes, splat) across; a stroke may visit about 67 million of them in all. Both limits are counts, not times, so a result never
depends on the machine's speed, and they are checked before anything changes.

**Every file a terrain command writes** (the `path` of `terrain.create`, the default `assets/terrain/<name>.*.png` names, and the
`heightmap`, `holes` and `splatMaps` paths of a save) follows the project write rules: it must lie inside the project, so an
absolute path or one that leaves the folder with `..` is refused with the field and the fix, unless the caller has the
`WriteAnywhere` permission; a managed folder is refused too. A default name is made unique (`ground.height.png`,
`ground_2.height.png`...) when a file or another terrain already uses it, ignoring case. `terrain.create` without a `name` takes
`terrain`, `terrain_2`... the first free id; `path` together with `heightmap` is refused. `terrain.paint` makes the splat maps only
when the brush changes a texel.

**One command is one undo step, per terrain.** `terrain.undo` and `terrain.redo` put the samples of the newest sculpt, paint, holes
or generate back, bit for bit, in every plane the command touched. The history keeps 64 steps and 256 MB per terrain, is not
saved with the scene, and is cleared when the scene loads. What a command changes outside the sample data (a `Terrain.holes` or
`splatMaps` path a first edit set, a `heightmap` a `terrain.generate` chose) is not undone: the path stays and the data is what
goes back. A command that fails changes nothing and adds no step. The result of an edit has `undoDepth`, `unsaved` (files with
edits not written yet) and `undo` (the command that takes it back).

**Errors teach.** Each error names the JSON pointer of the argument (`/radius`, `/points`, `/layer`, `/resolution`), what is wrong and
the fix: a `resolution` that is not 2^k + 1 lists the ones that work, an unknown argument gets "did you mean", an entity without a
`Terrain` or without a heightmap names the command that makes one, and a `layer` beyond `Terrain.layers` says how many there are.

### Terrain data formats

All of them are PNG (or raw) files in the project, with row 0 at the **-Z edge** of the terrain and column 0 at the -X edge, in the
terrain's local space (before `Transform`).

| File | Format |
|---|---|
| heightmap | 16-bit greyscale PNG, or raw little-endian `.r16`; 2^k + 1 samples a side. Height in metres = `heightOffset` + `heightScale` * value / 65535. The samples are at the corners of the cells |
| holes (`Terrain.holes`) | 8-bit greyscale PNG, `cells x cells` pixels (heights samples - 1 a side), 255 = hole, 0 = ground; a pixel of 128 or more counts as a hole when read. Pixel (i, j) is the cell between samples (i, j) and (i + 1, j + 1) |
| splat maps (`Terrain.splatMaps[m]`) | RGBA8 PNG, linear (NOT sRGB: do not gamma-convert), each its own size (default the terrain's cells, at most 1024; 16 to 4096). Channel c of map m weights `layers[4 * m + c]`; the 8 weights of a texel add up to 255 (the commands renormalise every stamp). Texel i is centred at local x = -size/2 + (i + 0.5) * size / texels. A texel whose alpha is 0 keeps its colour channels through a save and a load |

`terrain.paint` creates map 0 as all `layers[0]` (weight 255 in the red channel) and map 1 as all zeros on the first paint of a
layer 4 to 7. A map that already exists keeps its size.

**What a renderer or a tool of its own needs** (P5c): the planes are in `TerrainHeights` (`holes`, `holesVersion`, `splat[m]`
with `rgba` and `version`, `any_unsaved()`, `undo_depth()`); follow `holesVersion` and `splat[m].version` as the collider follows
`holesVersion` and the heights follow `dirty_since`. `save_terrain_files(world, entity)` and `save_all_terrain_files(world)` write the edited
planes (each path goes through `fs::resolve_for_write`: inside the project unless the caller passes `writeAnywhere`); `TerrainStep` and `TerrainHeights::apply_step` are how an edit enters the history.

## Foliage (planned, M75.6)

`Foliage` draws many copies of a few meshes read from a data file, as GPU instances in chunks that are culled and faded by
distance, with wind. Its fields: `meshes` (an array of 1 to 16 primitive names or asset paths; the instances file stores a mesh
index into it for every instance, and its binary format is defined by the foliage package, M75.6 P6a), `instances` (the data file
that `foliage.paint` and `foliage.scatter` write; empty = none), `density` (0..1, the share drawn), `windStrength` (metres) and `windFrequency` (swings per
second), `lodDistance`, `fadeStart` and `fadeEnd` (metres; `fadeEnd` above `fadeStart`) and `castShadows`.

`ScatterRule` holds the recipe `foliage.scatter` fills the file from: `meshes` (up to 16 of `{mesh, weight}`), `density` (per square
metre), `minSpacing`, `slopeRange` (degrees), `heightRange` and `scaleRange`, `alignToNormal` (0..1), `layerMask` (bit mask of the
terrain layers it grows on, -1 = any), `seed` (the same rule and seed give the same instances) and `terrain` (the entity with the
`Terrain`; empty = this entity or its parent). `foliage.scatter` writes into ONE `Foliage` entity: it sets its `meshes` to all the
meshes of the rule and fills the instances file with their indices. `foliage.paint`, `foliage.scatter` and `foliage.clear` fail with
`not_built` today.
`renderStats` gets `foliageInstances` and `foliageInstancesCulled`.

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
