# Big worlds: terrain and foliage

Part of [Big worlds](BIG_WORLDS.md) (the entry page lists every page).

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
