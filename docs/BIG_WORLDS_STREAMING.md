# Big worlds: streaming and the floating origin

Part of [Big worlds](BIG_WORLDS.md) (the entry page lists every page).

## Streaming (M75.3)

A big world is cut into **cells**: one scene file per square of the world, and an index file that lists them. The engine
loads the cells around the `StreamingAnchor` entities (usually the player) and unloads the ones left behind, so a world of
any size costs what the part around the player costs. The reading and parsing of a cell happen off the main thread; only the
creation of its entities is on the main thread, within a budget per frame. Nothing here changes a game without a
`StreamedWorld` component.

`world.split_cells` and `world.merge_cells` cut a scene into cells and join them back (for a tilemap use `tilemap.split_cells`,
below); the editor's Cells panel edits the cells of a streamed world ("Editing a streamed world", below). The debug view of
the cells is the Cells panel's grid in the editor's viewport; a running game has none.

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
- `persistent` is optional: the scene that holds what is not part of any cell (the camera, the lights, the player, the
  `StreamedWorld` itself and the scene's settings). `world.split_cells` writes it and `world.merge_cells` and the editor read it;
  the streamer ignores it (the open scene is what stays loaded).
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
- `world.split_cells {scene, cellSize, out?, dimension?, overwrite?, dryRun?}` cuts a scene into cells and writes the index, one
  scene file per cell and the persistent scene; `world.merge_cells {world, out, overwrite?, dryRun?}` joins them back into one scene
  so a level can be edited as one file. A `StreamedWorld` of the persistent scene stays in the merged scene (the entities are
  written as they are, so split then merge gives the same ones) and the result's `warnings` name each one: playing the merged scene
  would stream the cells it already holds, so remove it with `scene.remove_component {id, component: "StreamedWorld"}`. Both write project files under the project's write rules and never change the files they
  read. See below.

### Editing a streamed world

**Cutting a scene.** `world.split_cells` puts every ROOT entity, whole with its children, in the cell its position is in: cell
`[i, j]` is `floor((position - origin) / cellSize)` on the plane (XZ for `"3d"`, XY for `"2d"`), a border belongs to the higher
cell. The GLOBAL entities stay in the persistent scene together with the scene's `settings`: an entity whose subtree has a
Camera, an AudioListener, a MusicPlayer, a StreamedWorld, a StreamingAnchor, a user-interface component or a directional Light,
one without a Transform, or one tagged `global`. Cells that would be empty are not written. The entities are written exactly as
the source scene has them, so `world.merge_cells` gives back the same entities with the same ids (the order of the roots follows the
cells); two files with the same entity id make the merge fail before it writes. A reference from a component of one cell to an
entity of another is reported in `warnings`: while the other cell is not loaded it is empty (the streamer drops it the same way).
A scene with a floating `origin` is refused: rebase it first.

**In the editor** (View > Cells, [Cells panel](editor/EDITOR_PANELS.md#cells-panel)) a scene with a `StreamedWorld` is edited cell by
cell:

- Edit mode never streams by distance (the engine is paused; no anchor is read), so what is loaded is what you chose: the cells
  you load from the panel, or the cells within a radius of the camera ("Load around the view": nearest first, at most 64 per
  click, at most 256 loaded in all). A loaded cell is an ordinary root entity `cell_<i>_<j>` with its entities under it, at their
  absolute positions, exactly as the streamer shapes it, so every tool of the editor works on them.
- A loaded cell is **unsaved** when its entities, written the way a save writes them, differ from its file; Undo back to the
  saved state clears the mark. The editor's undo snapshots carry the loaded cells, so Undo and Redo work across cells (they use
  memory in proportion to the loaded cells: unload what you are done with). Closing the scene, quitting or unloading a cell
  with unsaved changes asks first.
- **Save** (the toolbar's, Ctrl+S, or the panel's Save cells) writes each unsaved cell to its own file and the open scene's file
  only if it changed; the index is written only when a cell was added, or a saved cell's height range or listed `sizeBytes` changed
  (the plane rectangle of a cell never changes; in a 3D world the height range is recomputed from the lowest and highest position of
  the cell's entities, the same rule as `world.split_cells`, so it also shrinks; a cell with no entities keeps its range; `sizeBytes`,
  when the index lists it, is set to the size of the file just written). Before anything is written every path and the index the save
  implies are checked (the write rules, an index that would be invalid), and a cell file that is not in the index is never
  overwritten; a save that fails changes nothing in the editor either (no cell is made, no entity re-filed).
- **Moving an entity into another cell** is just moving it (the Transform gizmos, the Inspector, a command). There is no command for it: Save files every top-level entity of a loaded cell into the cell its position is in, loading
  that cell for the purpose, or making a new one (a file `<index name>_cells/<i>_<j>.scene.json`, listed in the index). The
  Inspector says "Save moves it there" while the entity is in the wrong cell. Its children go with it; its id and components
  do not change. An entity that is dragged back before Save never moves.
- **Global entities** live in the open scene (the persistent scene of a split world is what you open to edit them), not in
  the cells: the editor only writes what is under a cell root.
- A reference from an entity to one in a cell that is not loaded is empty, as in the game (the load warns about it). Deleting the
  root entity of a cell closes it without changing its file; when the cell had unsaved changes it stays loaded as unsaved and
  empty instead (the Cells list says "root deleted"): Save writes the cell with no entities and closes it, Undo brings the entities
  back, and "Discard changes and unload" gives the edits up. Nothing is dropped without being asked.
- **Play** streams the world as the game does and **Stop** brings back the cells you had loaded, with their unsaved changes;
  nothing you do while playing reaches a cell file.
- The floating origin does not change any of this: cell contents are absolute, the root sits at the origin's negative and the
  grid in the viewport is drawn through the same conversion, so a scene with a rebased origin shows its cells in the same place.

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
