# Modeling: game-ready models and tools

[Modeling](../MODELING.md) > Modeling: game-ready models and tools

## Game-ready models

A model that looks right still has to be cheap and solid in a game. The `gameReady` object of a document says how, and every bake
derives the files from it again, so changing the tree changes the LODs and the collider with it. `model.game_ready` edits it.

```json
{"format": "factoria.model/1",
 "gameReady": {"origin": "bottom_center", "merge": true,
               "lods": [{"ratio": 0.5}, {"ratio": 0.15}],
               "collider": {"shape": "convex"}},
 "nodes": [ ... ]}
```

| Setting | Meaning |
|---|---|
| `origin` | `keep` (default), `center` (bounding box middle at 0,0,0), `bottom` (lowest point at y = 0) or `bottom_center`. The model, its LODs and its collider all move together. |
| `merge` | Submeshes with the same material become one (fewer draw calls; its part name is the parts joined with `+`), identical vertices are welded and triangles are ordered for the GPU cache. The surface does not change. |
| `lods` | Up to 4 lower-detail copies. Each is `{ratio, triangles, error, distance}`: `ratio` keeps that fraction of the triangles, `triangles` at most that many (with both, the smaller), `error` the most any collapse may move the surface in metres (alone, it decides how far to go). `distance` is the camera distance in metres from which the game draws it; left out it is the model's largest dimension times 4, 8, 16, 32 for LOD1..4. |
| `lodChain` | An automatic chain of LODs drawn by screen size instead of `lods` (not both): `{enabled, levels (1..7), ratios, errors, screenSizes, minTriangles, lockBorder, normalWeight, uvWeight}`. The bake writes `<name>.lodN.glb` and a prefab whose `MeshRenderer` has `lodMode: "screenSize"`. `model.generate_lods` or `model.game_ready {lodChain}` sets it (`null` removes it); fields and defaults: docs/BIG_WORLDS_LOD.md, "Automatic LOD chain". Skinned meshes are not supported. |
| `collider` | `shape`: `none`, `box`, `sphere`, `capsule` (stands on Y), `convex` (hull), `decomposed` (several convex pieces of a concave model). `maxVertices` (4..256, default 32) limits each hull; `decomposed` also takes `maxHulls` (default 8) and `resolution` (voxels, default 100000). `part` fits the collider to the submeshes of one named part only (a pine's `"trunk"`, so the canopy does not block; it works with `merge` too; an unknown name lists the parts); `radius` (sphere, capsule) and `height` (capsule, total metres) replace the fitted value. |
| `platforms` | The budgets the report checks; default all of `desktop`, `mobile`, `web`. |

Budgets per model on screen: desktop 100000 triangles and 16 draw calls (submeshes), mobile 20000 and 8, web 40000 and 10.
`model.game_ready` with no setting measures and writes nothing: the triangles, vertices, error and switch distance of every
LOD, for each platform whether the full mesh fits, which LOD is the first that does (`firstFittingLod`, -1 if none) and whether
the submeshes fit, the collider (its volume against the model's: a `volumeRatio` far above 1 means things bump into empty
space) and the `warnings`. A bake returns the same report as `gameReady`.

**What a bake writes**, next to the `.glb` and all recorded in `assets.json` with the same recipe: `<name>.lod1.glb`... for the
LODs; `<name>.collider.glb` for a `convex` hull (`<name>.collider1.glb`... for a `decomposed` one); and `<name>.prefab.json`
(`factoria.prefab/1`) when there is an LOD or a collider: one entity with a `MeshRenderer` whose `lods` lists
`[{mesh, distance}]` and a `Collider3D` (`box`, `sphere` and `capsule` with their numbers and `offset`, `convex` with its hull
`.glb`). A body cannot be several colliders, so a decomposition becomes one static child entity per piece, each a convex
`Collider3D`. Drop the prefab in a scene to use it. A file the last bake made and this one does not (fewer LODs, another
collider) is deleted. A document whose LOD or collider file is missing is `missing` for `model.info`.

At runtime `MeshRenderer.lods` is `[{mesh, distance}]`: the renderer draws the entry with the greatest `distance` not above the
camera's distance to the entity, and `mesh` below the first. A scene can set it by hand for any model.

The operations (origin, merge, LOD, collider fit) work on any mesh, not only a document's: an `sdf` node's result is a mesh like
another, so the settings apply to it in the same way. LODs use meshoptimizer, the one simplifier the engine has (the `sdf`
mesher uses it too); each submesh is simplified on its own with its border locked, so parts stay apart and no crack opens
between them, and normals, uvs and colours weigh in the error so seams and colour edges survive. A decomposition uses V-HACD
on one thread, with its hull order and merge-queue ties made independent of the C++ standard library. Everything is serial, so a document gives the same LODs, hulls and bytes on every platform (the tests pin
triangle counts and hashes).

Limits: the capsule is always along Y (the report warns when the model is wider than tall); a decomposition that finds no
pieces falls back to the convex hull and says so; a LOD never removes a submesh entirely.

### Giving a model a skeleton

A model made of named parts can be fitted with a skeleton (humanoid, quadruped, bird, tail, chain or generic) and baked as a skinned `.glb`: see docs/RIGGING.md (`rig.create`, `rig.fit`, `rig.bake`; `skin3d.*` for the skin weights). Give limbs `segments` so there are vertices where the skin should bend. Name the nodes of the model with `part` ("head", "arm_l", "leg_r"...): the fit finds each bone from the part names.

## Looking at a model: `model.preview` and `model.check`

Two read-only commands let you (or an AI) look at a model without a graphics device, a window or Blender. Both build the
document in memory and look at the mesh the game gets: with `gameReady` settings in the document, their `origin` and `merge`
are applied first (the result says `"mesh": "gameReady"` or `"evaluated"`). Pass `path` (a `.model.json`) or `document` (the JSON
itself, to try an idea before it is a file). Nothing in the project changes.

```bash
factoria call model.preview '{"path":"assets/models/crate.model.json","views":4,"mode":"shaded_wireframe"}'
factoria call model.check   '{"path":"assets/models/crate.model.json","expectedHeight":0.5,"platforms":["mobile"]}'
```

**`model.preview`** draws one PNG, a turntable sheet: `views` sides (4 to 8, default 6) evenly spaced around the model from
`yaw` (degrees; 0 looks at the +Z side, 90 at the +X side), seen from `pitch` degrees above the horizon, each cell `cell` pixels
(96 to 640) and all framed the same way so sizes compare across the sheet. A blue figure 1.8 m tall stands beside the model
(`figure: false` removes it) on a grid at y = 0 whose two origin axes are brighter (`ground: false` removes it), so scale, how
the model stands and where its origin is read at a glance. The header names the file and gives the triangle count, the size in
metres and the number of parts. `mode` is `shaded` (default), `wireframe` (the triangle edges; hidden ones stay hidden) or
`shaded_wireframe`. A dark red surface is one seen from inside (a flipped triangle). `part` draws one part in orange. A software
renderer draws it, so the same document gives the same picture on every machine. The result has `stats` (triangles, vertices,
submeshes, bounds, `heightVersusFigure`, and the triangles of each part), the `views` angles and `picture`; the PNG comes back as
`$image` in a temporary file, and `out` (a project-relative `.png`; `overwrite` to replace one) keeps it in the project.

**`model.check`** measures what a picture cannot. Each finding has a `code`, a `severity` (`error`: the model is wrong; `warning`:
probably wrong; `info`), a `message` (what is wrong and where: the parts and bounds), a `hint` (how to fix it) and, for mesh
faults, `count`, `parts`, `bounds` and up to `samples` positions in model space. `ok` is false when there is an error.

| Code | Severity | Found when |
|---|---|---|
| `empty` | error | The mesh has no triangles. |
| `inside_out` | error | A closed piece has a negative volume: every triangle faces inward. |
| `inconsistent_winding` | error | Two neighbouring triangles disagree on which side is out: one is flipped. |
| `non_manifold` | error | An edge is shared by more than two triangles. |
| `flipped_normals` | warning | Stored normals point against their triangle's winding. |
| `open_edges` | warning | Edges used by one triangle: a hole, so the model is not a closed solid. |
| `degenerate` | warning | Triangles with no area. |
| `scale` | warning | The height differs from `expectedHeight` by more than `tolerance` (a fraction, default 0.25) or, with no `expectedHeight`, the largest side is under 2 cm or over 100 m: probably authored in the wrong unit. |
| `origin` | warning | The model is far from its own origin, so placing an entity puts it somewhere else. |
| `triangle_budget` | warning | More triangles than a platform's budget for one model (information when a LOD of the document's `gameReady` fits). |
| `draw_call_budget` | warning | More submeshes than a platform's budget. |

The budgets are the table of Game-ready models (`model.game_ready` reports the same numbers); `platforms` limits which are
checked (default all) and `ignore` lists codes not to report (an open surface that is meant to be open: `["open_edges"]`). The
result also has `mesh` (the counts behind the findings, `closedVolume`, `height`) and `checked`. With no `path` or `document`,
`model.check {}` returns the catalog of checks and budgets.

A workflow that needs no eyes on the screen: `model.create` or `model.edit`, then `model.check` until `ok` and no warning is
unexpected, then `model.preview` with `mode: "shaded_wireframe"` to see the triangles, and `model.bake`. A model whose check is
clean can still look wrong: the picture is the check for how it looks.

## The Model panel in the editor

View > Model (or a double click on a `*.model.json` in the Project panel) opens a document. The panel has three parts and
uses the commands above, so what it writes is what the Console, an AI or a script would write:

- **The operation tree**, in document order, with a checkbox per node (`enabled`), Add (the catalog's operations, into the
  selected group or modifier, or at the top level) and Remove. Picking a node highlights the part it belongs to in the viewport.
- **The viewport**: the evaluated mesh drawn by the same software renderer as `model.preview` (drag to turn, wheel to zoom;
  shaded, wireframe, the 1.8 m figure and the ground are buttons). The highlighted part is drawn in orange; the part
  list also picks one. The mesh is evaluated in the background a few frames after a change and the last picture stays until the
  next one is ready.
- **The parameters** of the selected node, from the catalog: a slider for a number or integer (with its range), a checkbox,
  a slider per axis for a vector, a combo for a choice, a text box for a string, and a reset button per field that removes it
  (back to its default). A type with no widget (a list of points or nodes, for example) is shown read-only with a note to use
  `model.edit`. While a slider is dragged the viewport follows it from a copy of the document; letting go writes ONE
  `model.edit set`, so a drag is one undo step. Ctrl+Z / Ctrl+Y undo and redo through the editor's undo stack.

The panel's edits write the document but do not bake, so the `.glb` stays as it was until **Save** (a `model.bake`, forcing a
rebuild; **Overwrite** allows replacing a file that no document baked). A change made to the file behind the panel's back is
read again. Ctrl+S saves too. The panel's **Check** button runs `model.check` on the file and lists the findings; hovering one shows its hint and picking one highlights its first part.
The viewport does not pick parts by clicking: pick them in the tree or the part list.

## Cleaning an imported mesh: `model.import_clean`

Meshes from outside (`assets.generate_model`, a downloaded `.glb`, an `.obj`) are rarely ready for a game: doubled vertices,
floating crumbs, a wrong size, the origin anywhere, far too many triangles. `model.import_clean {source}` fixes them in one
call and wraps the result in a model document:

```
factoria call model.import_clean '{"source":"assets/models/robot.glb","height":1.8,"platform":"mobile"}'
```

It writes `<name>_clean.mesh.glb` (the cleaned mesh), `<name>_clean.model.json` (a `mesh` node reading it, a `materials`
section from the source and, when it unwraps, a `uv` section) and bakes `<name>_clean.glb` like any model, so the document
can be edited afterwards (`model.edit`, `model.uv`, `model.game_ready`). Embedded textures are written next to the document
as `<name>_clean.texN.<ext>`. `out` chooses the document; an existing one needs `overwrite`.

The steps, in this order, all deterministic:

1. `upAxis` `z` turns a Blender or CAD export upright. An `.obj` goes through the importer of `assets.import` first.
2. Weld: vertices closer than `weldDistance` (default a millionth of the model's size) become one when their uv, colour and
   normal agree, so texture seams and hard edges stay. Degenerate and repeated triangles are dropped.
3. Floating pieces: the mesh is split into connected pieces; those smaller than `minPieceSize` (default 2%) of the biggest are
   removed (`removeFloating: false` keeps them). The report lists each one with its size and place.
4. Winding: neighbouring triangles are made to agree and a closed piece faces outward.
5. Scale: `height` (metres), `reference` (`"human"` is 1.8 m, or a project model whose height to match) or `scale`
   (factor), only one of them. With none the size stays; a model that is not a size anything has in a game gets a warning.
6. Origin: `bottom_center` (default; the ground centre), `center`, `bottom` or `keep`.
7. `remesh: true` (optional): the surface is rebuilt through the signed distance field path (`remeshCells` along the longest
   side, or `remeshVoxel` metres). The result is closed, manifold and free of self-intersections.
8. Decimation to `triangles` or the `platform` budget (`desktop` 100000, `mobile` 20000, `web` 40000) with meshoptimizer,
   keeping uvs, colours and part seams.
9. Unwrap with `model_uv` (xatlas) into the document's `uv` section: `unwrap` `auto` does it when the mesh has no uvs or was
   remeshed, `always` replaces the source's uvs, `never` skips it. A model whose surface is far bigger than a game object gets
   a lower `texelsPerUnit` (and a warning) so that the atlas stays near 2048 px; give `height` or `scale` instead.

**The report** answers with `report`: `before` and `after` (vertices, triangles, size, surface: boundary, non-manifold and
degenerate counts), `weld`, `pieces` (found, removed, the list), `trianglesReoriented`, `nonManifoldEdgesFixed`, `scale`
(factor and reason), `origin.offset`, `remesh` and `decimate` when they ran, and `warnings` that say what to change, and `budget`
(the triangles and draw calls against every platform). The answer also carries `summary`, the `bake` result and `nextSteps`.

**Limits.** Remeshing loses texture coordinates: base colour textures are sampled into vertex colours and the surface is
unwrapped again; thin sheets (a leaf, a flag) become thin solids; the grid is bounded by the SDF sample limit, so a very
fine `remeshCells` is an error. The decimator will not open non-manifold edges, so a thin shell or an open mesh may stay above
the budget; the report says so and `remesh` helps. Skins and animations of the source are not read. `gameReady` (LODs, collider)
is not written for you: add it with `model.game_ready` when the model is final.
