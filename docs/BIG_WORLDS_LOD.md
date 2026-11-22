# Big worlds: levels of detail and occlusion

Part of [Big worlds](BIG_WORLDS.md) (the entry page lists every page).

## Levels of detail (M75.1)

Drawn since M75-P1a: the selection by distance or screen size, `LodGroup`, and the dithered cross-fade. Not drawn yet: the
HLOD proxy and the impostors (`hlodProxy`, `impostor`: saved and checked, no effect), and the two commands that make their
files.

`MeshRenderer.lods` switches meshes by distance, as it always did (a scene that does not use the new fields draws exactly
as before). The levels are numbered from 0: level 0 is `MeshRenderer.mesh` (or the first child of a `LodGroup`), level k is
`lods[k-1]` (or child k).

- `MeshRenderer.lodMode`: `"distance"` (default) or `"screenSize"`. With
  `screenSize`, an entry of `lods` is `{"mesh": "models/rock_lod1.glb", "screenSize": 0.25}`: the mesh replaces the one before it
  when the screen size drops below 0.25 (at exactly 0.25 the nearer level stays). Entries go from the largest `screenSize` to the smallest. A
  `screenSize` that is not a number from 0 to 1 is an error, and an entry without the key of its mode, or whose `screenSize` is
  not below the one before it, is a warning, each with the JSON pointer of the entry (an entry without the key of the mode in use is
  ignored when drawing).
- The screen size, for `MeshRenderer` and `LodGroup` alike, is the diameter of the world-space bounding sphere divided by the
  visible height at the entity's distance `d`: `2 * d * tan(fovY / 2)` in perspective, `2 * orthoSize` in orthographic. 1 = the
  sphere is as tall as the screen, 0.1 = a tenth of it. `d` is the distance from the camera to the entity's origin (the group
  entity's origin for a `LodGroup`, like `distance` mode). For a `MeshRenderer` the sphere is the diagonal of the full-detail mesh's box times the
  entity's largest scale; for a `LodGroup` it is the sphere that bounds the meshes of its whole subtree (every level, so the
  group does not change size when it changes level). It is a fraction, so a threshold means the same at every resolution; it
  does change with the field of view, the zoom and the size of the object (a wider lens or a smaller object gives a smaller
  screen size), so tune thresholds with the camera the game uses.
- `LodGroup` on an entity whose children are the levels (child 0 the most detailed): `mode`, `thresholds` (one number per child
  but the first, at most 8, in the unit of `mode`: they grow in `distance`, shrink in `screenSize`), `crossFade`. A threshold
  is reached when the distance is at or above it, or the screen size is below it. Only the meshes in the subtree of the chosen
  child are drawn; the meshes of the other children and everything below them are skipped. Lights, particles, colliders and
  scripts of the skipped children are not touched. A child's own `MeshRenderer.lods` still work, but with no fade while the
  group fades. A child past the ninth level is never drawn.
- **Which camera chooses.** The camera of the main view (the first camera job of the frame) chooses every level. The shadow
  passes and the probe and global-illumination captures draw the level that camera chose, so a shadow is the shadow of what the
  player sees and a capture does not pop. In split screen, and for a `CameraView` or a camera that draws to a render target,
  each camera chooses for its own view (its own distance, field of view and fade). An entity that no camera sees keeps no
  state.
- `MeshRenderer.lodCrossFade` and `LodGroup.crossFade`: seconds a switch fades over. 0 = a hard switch. During the fade
  both levels are drawn (`renderStats.lodCrossFades` counts them: two per fading entity), each one through a screen-space
  dither (interleaved gradient noise on the pixel) that is the complement of the other's, so every pixel of the silhouette
  shows exactly one of the two levels and the share of the new one grows from 0 to 1. There is no blending: the dither is a
  `discard` driven by one per-draw number, so it works with the depth prepass, the opaque pass and every backend
  (`render.supports` `lodCrossFade` is true everywhere). Only the draws that fade have a program with that `discard`: the
  engine's own mesh and prepass programs get a variant for it (`mesh_lod`, `mesh_skin_lod`, `prepass_lod`, `prepass_skin_lod`,
  compiled the first time a fade draws), and a custom material with `alphaMode` `"clip"` dithers inside the `discard` it
  already has. Every other draw keeps the programs it had, with no `discard` (a tile-based GPU keeps its early depth test and
  hidden surface removal for them). The variants are about 120 KB of GLSL ES and 155 KB of WGSL more in the player. The fade state
  is render-only: it advances with the frame delta, is never saved, and a script cannot read it. Details:
  - A new entity, or one that comes back into view, starts settled at its level: it does not fade in from nothing.
  - If the level goes back while a fade runs, the fade turns round where it is (no restart); a third level cuts the fade and
    fades from the level that was fading in.
  - Shadows: a fading entity casts the shadow of the new level only, and the level that leaves casts nothing. The shadow shader never
    dithers, so a shadow does not flicker.
  - Instancing: draws are batched per level. An entity that is fading is drawn on its own (its two levels are two draws), so a
    fade costs two draws and a lost batch for the entity, only while it runs.
  - A mesh switches at once, with no fade (only the new level is drawn), when its material is a full-shader material
    (docs/shaders/) or a custom material that is not `alphaMode` `"clip"` (their programs have no dither), and when it has
    subsurface scattering (its extra pass).
  - Cost. A scene with no `lods` and no `LodGroup` draws with the programs it always had and checks one flag per scene: the
    `render.frame3d` bench stays within its noise (the same machine, back to back, with and without the feature: best run
    5.32 ms against 5.38 ms for 8 frames of 1600 meshes, a Debug `-O1` build). A scene with `lods` pays the pick of each mesh and
    the draws the levels split into: `render.lod3d` (the same 1600 meshes with two lower levels each and 40 `LodGroup`s, no fade
    running) took 11.7 to 15.3 ms against 5.4 ms for `render.frame3d` in that build, on the CPU
    (docs/performance/PERFORMANCE_BENCH.md). Only while an entity fades does it also pay two draws and a lost batch for it.
    With `crossFade` 0 the pick keeps no state.
- `MeshRenderer.impostor` and `impostorDistance`, and `LodGroup.hlodProxy` and `hlodThreshold` (the HLOD proxy of a whole cell):
  saved and checked, **no effect yet**.
- `model.generate_lods {model, levels, ratios, errors, maxError, screenSizes, ...}` simplifies a model into lower levels
  (deterministic) and wires them for screen-size LOD: it is real, see "Automatic LOD chain" below.
  `model.bake_impostor {model, views, resolution, apply}` bakes the impostor atlas and fails with `not_built` today.
- `renderStats.lodCrossFades` is drawn; `impostors` stays 0.

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
**Built: areas and portals** (`OcclusionArea`, `OcclusionPortal`, `renderer.supports` `occlusionPortals`). **Planned: the GPU path
(`occlusionGpu`)**.

- `Occluder` on an entity: `shape` (`"box"` or `"mesh"`), `size` and `center` (metres, a box, before the entity's scale), `mesh`
  (the mesh to rasterise; empty = the entity's `MeshRenderer.mesh`), `enabled`. The box follows the entity's drawn matrix (its
  `Transform` scale and rotation, and its parents'). A `shape` `"mesh"` with no mesh and no `MeshRenderer`, or whose mesh cannot
  be read, hides nothing and logs one warning that names the entity.
- `OcclusionArea` (a room): `size` in metres, `areaId` 1..65535 (0 is "outside every area"). `OcclusionPortal` (a door or window
  between two areas): `size`, `areaA`, `areaB` (the ids on its -Z and +Z side), `open` (a shut door blocks sight). Meshes in an
  area are drawn only when a chain of open portals in view leads from the camera's area to it: see "Areas and portals" below.
- `renderStats` has `occluders` (the Occluders rasterised this frame, summed over the cameras), `occlusionTests` (the meshes tested
  against a depth buffer) and `meshesOccluded` (the ones proved hidden and left out of the main pass). All three are 0 when no
  enabled Occluder is in the scene. `portalsVisited` (the distinct open portals the camera's walk went through, summed over the
  cameras) and `meshesCulledByArea` (the meshes left out because no chain of portals leads to their area) are 0 when no enabled
  OcclusionArea is in the scene.

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

### Areas and portals

An `OcclusionArea` is the oriented box of its entity: `size` before `Transform.scale`, placed by the entity's drawn matrix (its scale,
rotation and parents; a floating-origin shift needs nothing). A `OcclusionPortal` is a box the same way. Nothing happens until the scene
has one enabled (active) OcclusionArea (one `world.any<OcclusionArea>()` check per frame); a scene without one draws and counts exactly
as before. With one, for every main-view camera, after the frustum test and before the Occluder test:

1. **Membership.** A mesh belongs to every area whose box holds the centre of its world bounds; a mesh in no area belongs to area 0
   ("outside"). Meshes with no known bounds are not tested. Two boxes with the same `areaId` are one area (a room of several boxes).
2. **The camera's area** is the area whose box holds the camera position; where boxes overlap, the smallest volume wins and the
   lower entity breaks a tie, so the result never depends on the order of the world. In no box: area 0.
3. **The walk.** From the camera's area, with the whole picture as its view, every open portal that touches the current area and
   whose box is in the current view leads to its other area, and the view is narrowed to the portal's own screen rectangle (classic
   portal culling: what is seen through a door is only what the door's rectangle lets through). A portal box that crosses the near
   plane is clipped at it and never narrows the view below what is visible; a camera inside a portal's box sees through it. A
   closed portal (`open: false`) blocks the walk. Area 0 is an area like any other: a portal with `areaA` or `areaB` 0 joins the
   building to the outside, in both directions.
4. **The cull.** A mesh none of whose areas the walk reached is left out of the main pass (`meshesCulledByArea`); it still casts
   shadows. A mesh that belongs to a reached area, and the Occluder test after it, are as without areas.

Guards (counts, never time): a portal back to an area already on the current path is never taken (a cycle ends), an area is entered
again only with a view that no earlier visit of it held, a chain longer than 32 portals or more than 4096 portal tests ends the walk
and the camera then draws everything (an unknown answer never hides). Reflection probe, GI and light-probe captures are not culled,
and neither are shadow passes, sprites, 2D shapes and UI.

Mistakes teach, once per entity in the log: a portal whose `areaA` or `areaB` names an id no OcclusionArea has (with a did-you-mean over
the existing ids), a portal with `areaA` equal to `areaB`, and an OcclusionArea with an `areaId` outside 1..65535. Such a portal
connects nothing and such an area is ignored; the same mistakes are warnings of `scene.validate` where they can be seen in the file.
Think of the outside when you place areas: a camera in a room with no portal to area 0 does not draw the meshes outside every area,
the ground included, so give such a room a front door (or a window) to area 0, or box the outside too.

`render.supports {"feature":"occlusionPortals"}` is `true` on every backend (the walk runs on the CPU).

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
