# Big worlds: terrain and foliage

Part of [Big worlds](BIG_WORLDS.md) (the entry page lists every page).

## Terrain (M75.5)

The `Terrain` component draws a heightmap with a GPU level of detail and gives it a collider. In a scene and in scripts it is
called `Terrain` (the C++ type is `Terrain3D`: `Terrain` is already the 2D autotile type). **What it does:** the heightmap is drawn as tiles that coarsen with distance, painted with up to 8 material layers blended by the
splat maps (P5d), with the holes cut out of the surface, its shadow and its collider, lit and shadowed like a mesh; `collision`;
the counters; and the commands that create, sculpt, paint, cut holes in and generate a terrain, with undo (below). The brushes in
the editor are P5c: View > Terrain tool ("Editing in the editor", below).

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
| `terrain.sculpt {entity, tool, center or points, radius, amount, strength, falloff, height, continueStroke, save}` | `tool` is `raise`, `lower` (`amount` metres at the middle of the brush when `strength` is 1), `smooth` or `flatten` (toward `height`, world y, default the surface under the first stamp). `falloff` 0 ... 1 (default 1) is the share of the radius the effect fades over: 1 fades from the middle to the edge, 0 is a hard edge. The brush fades smoothly to 0 at its edge |
| `terrain.paint {entity, layer, center or points, radius, strength, falloff, splatResolution, continueStroke, save}` | raises the weight of `layer` (0 ... 7) and lowers the other 7 in proportion; every texel's 8 weights add up to 255 |
| `terrain.holes {entity, mode, center or points, radius, continueStroke, save}` | `mode` `cut` (default) or `fill` the cells whose centre is in the circle |
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
saved with the scene, and is cleared when the scene loads. A first `terrain.holes` or `terrain.paint` that made the mask or the
splat maps also sets `Terrain.holes` or `Terrain.splatMaps`: `terrain.undo` takes those paths back (the mask or maps are gone again,
or the ones the scene had come back) and `terrain.redo` makes them again, with the same paths; a file a save already wrote stays on
disk, unused. A `heightmap` a `terrain.generate` chose is not undone: the path stays and the data is what goes back. A command that fails changes nothing and adds no step. The result of an edit has `undoDepth`, `unsaved` (files with
edits not written yet) and `undo` (the command that takes it back).

**A stroke in pieces: `continueStroke`.** A command that edits (sculpt, paint, holes) takes `continueStroke: true` to add its changes
to the newest undo step instead of making one: a tool that applies a stroke live, a few stamps per frame, makes the first call without it
and the others with it, and the whole stroke is ONE step of `terrain.undo`. It is refused (with the pointer `/continueStroke`) when the
terrain has no step to continue, when an edit was undone since, and when the newest step was made by another command. A piece that
changes nothing adds nothing (and the stroke's first piece must have changed something for the next ones to continue it). Cut into pieces, a stroke gives the same ground as one call up to the rounding of
the stamps' blending (at most two raw 16-bit units of a sample, about 0.003 m at a height scale of 100).

**Errors teach.** Each error names the JSON pointer of the argument (`/radius`, `/points`, `/layer`, `/resolution`), what is wrong and
the fix: a `resolution` that is not 2^k + 1 lists the ones that work, an unknown argument gets "did you mean", an entity without a
`Terrain` or without a heightmap names the command that makes one, and a `layer` beyond `Terrain.layers` says how many there are.

### Editing in the editor

View > Terrain tool ([docs/editor/EDITOR_PANELS.md](editor/EDITOR_PANELS.md#terrain-tool)) is a brush on the selected `Terrain`: sculpt
(raise, lower, smooth, flatten), paint a layer, cut or fill holes, with radius, strength and falloff, a cursor ring on the ground under the
mouse and `[` `]` for the radius. It sends the commands above (`terrain.sculpt`, `terrain.paint`, `terrain.holes`) a few stamps at a time
while the mouse moves, with `continueStroke`, and records ONE editor undo entry at the release (`terrain.undo` / `terrain.redo`), so
Ctrl+Z takes a whole stroke back. A terrain command from the Console, the AI or MCP is an undo entry too (one per call), and Play
edits a copy of the terrain that Stop throws away, so a game never changes what the editor holds. A scene save writes the terrain files; a write error names the file and keeps every edit in memory.

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

## Foliage

`Foliage` draws many copies of a few meshes (grass, flowers, rocks) read from a data file. It works on every backend, with no compute
shader (`renderer.supports` `foliage` is `true`). Its fields: `meshes` (an array of 1 to 16 primitive names or asset paths; every
instance stores the index of its mesh in this array), `instances` (the data file; empty = none), `density` (0..1, the share
drawn), `windStrength` (metres) and `windFrequency` (swings per second), `lodDistance`, `fadeStart` and `fadeEnd` (metres;
`fadeEnd` above `fadeStart`) and `castShadows`. The Foliage entity's own transform moves and rotates all the instances (their
positions are local to it); the floating origin works, as for any entity.

### The instances file

Little endian, versioned; `fa/scene/foliage.h` reads and writes it (`read_foliage`, `write_foliage`, `encode_foliage`,
`decode_foliage`), so a tool or a script of the engine never needs to know the layout:

| Bytes | Meaning |
|---|---|
| 0..3 | the magic `FAFO` |
| 4..5 | version, `u16` (1) |
| 6..7 | flags, `u16` (0; a bit this version does not know is refused) |
| 8..11 | instance count, `u32` (at most 2000000) |
| 12..15 | mesh count, `u32` (how many meshes the writer's `Foliage.meshes` had; every mesh index is below it) |
| 16.. | one 26-byte record per instance |

A record is `x, y, z, yaw, scale` as `f32` (metres in the local space of the Foliage entity; yaw in radians about the instance's own up
axis; scale uniform), the mesh index as `u16`, the up axis `nx, ny, nz` as three `i8` in 1/127 units (a lean towards the ground's
normal; `0,0,0` = upright) and one reserved byte (0). A file that is
too short, has the wrong size for its count, a NaN or infinity, a scale of 0 or less, or a mesh index past `Foliage.meshes` is
invalid (so is a version, flags or magic this engine does not know): the message names the file, the byte and what to change ("foliage file 'x' at byte 40: ...").

### Loading

The renderer reads and chunks the file on a worker thread: a big file never stalls a frame, the instances appear when the job ends
(a frame or two later for a small file, more for 2 million instances; `renderStats` `foliageInstances` is 0 until then) and a screenshot
or capture taken before that does not contain them. The file is checked on disk every 30 frames (its modified time and size):
saving it again, from `write_foliage` or a tool, shows the new instances without a restart, and changing `meshes` or `instances` reloads too.
A missing or invalid file draws nothing and is warned about once (again only when its text changes); the file is not read again until it
changes.

### Drawing

The instances are grouped in chunks of 32 m with a bounding box. A frame draws, nearest chunk first:

- a chunk whose box is farther than `fadeEnd` is skipped; one outside the view frustum is skipped (the box is widened by the mesh
  radius and the wind sway), and so is one hidden by the CPU occlusion buffer when an occluder is present (`occlusionCpu`,
  docs/BIG_WORLDS_LOD.md). With `castShadows`, a chunk up to 24 m outside the view still goes into the shadow passes, as a shadow only.
- between `fadeStart` and `fadeEnd` an instance fades out with a dithered fade in 8 steps (the dither of the LOD cross-fade, so no
  alpha blending and no sorting; the fade is not counted in `renderStats.lodCrossFades`).
- beyond `lodDistance` an instance uses the next LOD of its mesh: for `assets/models/grass.glb`, the file `assets/models/grass.lod1.glb`
  (the name the model LOD chain bake gives its first level); when that file does not exist the mesh stays. There is no cross-fade between
  the two (the switch is one hard step). Instances of the same mesh and LOD are drawn as one instanced draw, like any other meshes.
- `density` keeps the instances whose fixed pseudo-random rank (from the instance index) is below it: the same instances stay when you
  raise or lower it, so nothing flickers.
- `windStrength` shears the instance sideways in proportion to its height: the base is fixed, the top moves by up to `windStrength`
  metres, with a phase that depends on the instance position, at `windFrequency` swings per second of the world time (so it pauses with the game and a
  replay sways the same). It is done on the CPU when the instance is handed to the draw, so it
  costs time per visible instance: it is meant for the near instances, and the fade removes the far ones.
- `castShadows` puts the instances (with the wind and the fade) in the shadow maps; false (default) leaves them out.

At most 262144 instances, over every Foliage entity together, are handed to the draw in a frame per camera (a camera with shadow passes
counts its own). Whole chunks are taken, nearest first, and the rest counts as culled, with one warning in the log: lower `fadeEnd` or `density`, or split the
field into several entities with a shorter reach. Costs: an empty scene or one with no `Foliage` pays nothing; with a field of 100000
instances in view, the cost is the CPU time of one draw item per visible instance plus the instanced draws.

`renderStats` has `foliageInstances` (instances drawn in the main view this frame) and `foliageInstancesCulled` (the ones the
frame skipped: chunk culling, beyond `fadeEnd`, the per-instance frustum test and the shadow-only ones). Foliage instances are not
added to `renderStats.meshes`; each (mesh, LOD) batch is one entry of `meshBatches`.

`ScatterRule` holds the recipe `foliage.scatter` fills the file from: `meshes` (up to 16 of `{mesh, weight}`), `density` (per square
metre), `minSpacing`, `slopeRange` (degrees), `heightRange` and `scaleRange`, `alignToNormal` (0..1), `layerMask` (bit mask of the
terrain layers it grows on, -1 = any), `seed` (the same rule and seed give the same instances) and `terrain` (the entity with the
`Terrain`; empty = this entity or its parent). `foliage.scatter` writes into ONE `Foliage` entity: it sets its `meshes` to all the
meshes of the rule and fills the instances file with their indices. `foliage.paint`, `foliage.scatter` and `foliage.clear` fail with
`not_built` today (M75 P6b): the file is written with `write_foliage` until then.
