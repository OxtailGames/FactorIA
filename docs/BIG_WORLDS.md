# Big worlds

Levels of detail, occlusion, streamed cells, a floating origin, terrain and foliage: what a game needs when its world is
kilometres wide. **Milestone M75 builds this in parts.** The floating origin works today (everything but what the renderer keeps,
package M75.4b); the CPU occluders of Occlusion draw (M75.2), and the other parts below are marked "(planned, M75.n)" and none of them draws or simulates anything yet. What exists today for them is the data and the names: the components and fields (they save, load and validate, and
do nothing yet), the counters in `renderStats`, the `render.supports` rows and the
commands, which fail with the error `not_built` (planned for a coming version) and name the package that fills them in, except
`world.origin`, `world.rebase` and `world.absolute_position`, which work. A game that adds the rest today loses nothing:
when a package lands, the scenes already written start to work. Nothing here changes a game that does not use it: every default
is "off" or "as before".

| Part | Package | What it adds |
|---|---|---|
| [Levels of detail](#levels-of-detail-planned-m751) | M75.1 | screen-size thresholds, dithered cross-fade, impostors, HLOD |
| [Occlusion](#occlusion-m752) | M75.2 | occluders (CPU built; GPU planned), areas and portals (planned) |
| [Streaming](#streaming-planned-m753) | M75.3 | cells loaded and unloaded around `StreamingAnchor`s |
| [Floating origin](#floating-origin) | M75.4 | positions stay exact far from the origin (the core works; the renderer follows in M75.4b) |
| [Terrain](#terrain-m755) | M75.5 | heightmap terrain: drawn with a GPU level of detail and collision (layers 1+, splat layers and holes: planned) |
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
- `model.generate_lods {model, levels, ratios, maxError, apply}` simplifies a model into lower levels (deterministic) and writes
  them; `model.bake_impostor {model, views, resolution, apply}` bakes the impostor atlas. Both fail with `not_built` today.
- `renderStats` gets `lodCrossFades` and `impostors` (this frame's counts).

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
- Every cell is tested, not every pixel: an object that peeks out of the silhouette of an occluder by less than a cell or two is
  drawn anyway (that is the price of never hiding what is visible).

### Caps (counted in triangles, never in time)

| Cap | Value | When it is reached |
|---|---|---|
| Triangles of one Occluder | 4096 | only the first 4096 are rasterised (the occluder hides less, never more); one warning names the entities and the cap |
| Triangles of all the Occluders of one camera | 65536 | the nearest Occluders (distance of their origin, then entity) are kept first; the others are left out or cut; one warning names them |

The same scene gives the same result on every machine. Warnings are logged once per run.

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

## Streaming (planned, M75.3)

A world is an index file (`<name>.world.json`: the cell size, and for each cell its bounds and its scene file) plus one scene file
per cell. Cells load additively on the IO thread and apply on the main thread within the frame's budget; unloading destroys the
cell's root.

- `StreamingAnchor` on an entity (usually the player or the camera): `loadRadius` (metres: cells nearer than this load),
  `unloadRadius` (cells farther than this unload; it must be above `loadRadius`, the gap is the hysteresis that stops a cell from
  loading and unloading every frame), `priority` (the anchor with the higher one gets its cells first), `enabled`. The radii are
  measured on the plane of the streamed world: x and z for a world index whose dimension is `"3d"`, x and y for `"2d"`. Distances use
  absolute positions (the floating origin plus the local position), so a rebase of the origin never changes what is loaded.
- `world.split_cells {scene, cellSize, output, dryRun}` cuts a scene into a grid of cells and writes the files and the index;
  `world.merge_cells {manifest, output, dryRun}` joins them back so a level can be edited as one file. They write project files and
  fail with `not_built` today.
- `world.cells {state}` lists the cells and whether each is loaded; `world.stream_status {}` says what streaming is doing (loads
  in flight, cells loaded, pending cells, the last error), so a test can wait until the cells around the player are in. Both are
  read-only and fail with `not_built` today. A script that waits for them checks that its scene is still the current one first.
- Tests count units of work, not milliseconds, so a result does not depend on the speed of the machine.

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

### What M75.4b adds

The renderer keeps some state in world space (the camera history that motion vectors, SSR and temporal effects reproject from,
the 2D global-illumination field's history, the realtime-GI grid anchors). Until M75.4b registers its `on_origin_shifted`
observer, a rebase shows one frame of ghosting in those effects, and the GI grid is laid out again. Nothing else is missing.

## Terrain (M75.5)

The `Terrain` component draws a heightmap with a GPU level of detail and gives it a collider. In a scene and in scripts it is
called `Terrain` (the C++ type is `Terrain3D`: `Terrain` is already the 2D autotile type). **What works today (P5a):** the
heightmap drawn as tiles that coarsen with distance, the material of the first layer, the shadows, `collision`, and the counters.
**Planned (P5d):** the blend of up to 8 layers by the splat maps, and holes. The fields for them are saved and checked today and
do nothing yet. The terrain sculpting and painting commands are P5b/P5c.

| Field | Meaning |
|---|---|
| `heightmap` | 16-bit greyscale PNG or `.r16` file (raw little-endian 16-bit, square: its side is `sqrt(bytes / 2)` samples, so 1025 x 1025 is 2 101 250 bytes); empty = flat at `heightOffset`. The side must be 2^n + 1 (33 to 4097); a side of 2^n is padded by one sample. An 8-bit PNG is accepted with a warning (256 heights: terraces) |
| `size` | metres `[x, z]` the terrain covers, centred on the entity, each above 0 and at most 100 000. The heightmap is stretched over it: a 1025-sample map over 2048 m has a sample every 2 m, and resolution and `size` are independent |
| `heightScale`, `heightOffset` | metres of height of a white sample, and metres added after it |
| `splatMaps` | up to 2 RGBA PNG paths; channel c of map m weights `layers[4 * m + c]` (planned: not drawn yet) |
| `layers` | up to 8 of `{albedo, normal, tileSize, roughness, metallic, normalScale}`. All the albedo textures share one size and format, and so do all the normal textures: the layers become texture arrays, because 8 layers of separate textures would need more than the 16 sampler pairs a shader stage can read. Only `layers[0]` is drawn today; without it, or without its `albedo`, the terrain is a neutral lit grey |
| `holes` | greyscale PNG; a pixel of 128 or more cuts a hole (caves, wells) (planned: no hole is cut yet, in the picture or in the collider) |
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
backend; the limit is the GPU's largest texture: a map of 4097 samples a side needs 4097, and a GPU that offers 4096 does not
draw it (an error says so once, and the terrain is skipped).

**Cost.** Per terrain: 2 bytes per sample on the GPU (33.5 MB for 4097 x 4097) and on the CPU (the same, plus the tile bounds), and
with `collision` 4 bytes per sample more for the collider (67 MB). A sculpt (`TerrainHeights::mark_dirty`) updates the collider and the
tile bounds only where the rectangle says, but **re-sends the whole height texture** (the renderer has no sub-rectangle upload
path): a brush stroke on a 4097 x 4097 map costs about 33.5 MB of upload per frame it is drawn in, so sculpting tools should
batch edits to one `mark_dirty` per frame. Selecting the tiles for one camera is a quadtree walk that visits a few hundred nodes, also for 4097 x 4097 (the timing is printed
by the `terrain_lod_tests.cpp` bench). A scene with no `Terrain` pays nothing: no texture, no program and no job.

**Collision.** `collision` (default true) makes the entity a static heightfield collider built from the same heights the renderer
draws, with the diagonal the patch triangles use, so a ray and the picture meet within float rounding. It needs no `Collider3D` or
`Heightfield3D`; an entity with its own `Collider3D` keeps that one, and a non-static `RigidBody3D` on the entity is refused with a
message. `Transform` position, rotation and scale apply as for `Heightfield3D`. A map larger than `Heightfield3D`'s 4096 samples
works here (up to 4097).

**For code that edits or reads the terrain (sculpting, foliage).** `world.terrain().heights(world, entity)` returns the shared
`TerrainHeights` (`data`, `samples`, `set`, `mark_dirty(rect)`, `version`); the renderer, the collider and the tile bounds each follow
its `dirty_since` history, so one `mark_dirty` updates all three. `terrain_sample(world, entity, worldX, worldZ, out)` and
`terrain_height_at` give the height (and the normal) of the surface that is drawn and collides, through the entity's transform.
The declarations are in `engine/scene/include/fa/scene/terrain.h`.

`terrain.create`, `terrain.sculpt`, `terrain.paint`, `terrain.holes` and `terrain.generate` (seeded noise and erosion, the same
arguments always give the same file) write the heightmap, splat and hole files. They fail with `not_built` today.

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
| `world.split_cells`, `world.merge_cells` | M75.3 | yes |
| `model.generate_lods`, `model.bake_impostor` | M75.1 | yes |
| `terrain.create`, `terrain.sculpt`, `terrain.paint`, `terrain.holes`, `terrain.generate` | M75.5 | yes |
| `foliage.scatter`, `foliage.paint`, `foliage.clear` | M75.6 | yes |

`factoria commands <name>` and `docs.commands {name}` print the arguments of each.
