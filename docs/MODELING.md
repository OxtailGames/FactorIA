# 3D models as data: `*.model.json`

A model document is a small JSON file that is the SOURCE of a 3D model: a tree of operations (parametric primitives, shapes
turned or swept from a profile, modifiers that change the mesh of their children, groups, and a transform on any node) with
named parts, materials and vertex colours. The `.glb` a `MeshRenderer` draws is BAKED from
it next to the document (`door.model.json` -> `door.glb`), the way the other offline makers write their files
([ASSETS.md](ASSETS.md)). You change the model by changing the document and baking again; nothing needs a GPU, a window,
Blender or any other program, and the same document gives the same bytes.

```json
{
  "format": "factoria.model/1",
  "doc": "A wooden door with a brass knob.",
  "materials": {
    "wood": {"color": [0.55, 0.35, 0.2, 1], "roughness": 0.8},
    "brass": {"color": [0.8, 0.65, 0.3, 1], "metallic": 1, "roughness": 0.3}
  },
  "nodes": [
    {"op": "box", "id": "panel", "size": [1, 2, 0.08], "align": "bottom", "part": "door", "material": "wood"},
    {"op": "sphere", "id": "knob", "radius": 0.05, "position": [0.4, 1, 0.07], "part": "knob", "material": "brass"}
  ]
}
```

`factoria call model.bake '{"path":"assets/models/door.model.json"}'` builds it and writes `assets/models/door.glb`.
`factoria call model.create '{"path":"assets/models/door.model.json","nodes":[...]}'` writes the document (checking it first)
and bakes it. The schema is `schemas/model.schema.json`; `$schema` may point at it for editor completion. `model.info {}`
returns the same catalog this page describes, with every field, range and default.

## Pages

- [Modeling: shapes](modeling/MODELING_SHAPES.md): Primitives, profile shapes, modifiers and sdf.
- [Modeling: editing, UVs and texturing](modeling/MODELING_EDITING.md): Selections and edits, UVs, parts, materials and texturing.
- [Modeling: game-ready models and tools](modeling/MODELING_GAME.md): Game-ready models, preview and check, the Model panel and cleaning an imported mesh.

## The document

| Field | Meaning |
|---|---|
| `format` | `"factoria.model/1"`. Required. |
| `doc` | A sentence for people and AIs; unused by the evaluation. |
| `output` | `{"path": "assets/..../name.glb"}`: where to bake. Default: the document's name with `.model.json` replaced by `.glb`. `model.bake` refuses a path outside `assets/`. |
| `materials` | `{name: {color, texture, metallic, roughness, emissive, doubleSided, blend}}`, the materials nodes refer to by name. The fields are those of a `mesh.save` material (docs/SCRIPTING.md, "Procedural meshes"); `texture` is a project file. |
| `uv` | How the model gets its UVs (below, "UVs"). Left out: every primitive keeps its own UVs (the list in "UV coordinates"). |
| `nodes` | The tree, in order. Required, at least one node that makes a triangle. At most 2048 nodes (groups and modifiers included) and 16 levels of nested groups and modifiers. |

### Nodes

Every node is an object with an `op` and these fields (a field that is left out has its default):

| Field | Meaning |
|---|---|
| `op` | The operation: a primitive, a modifier or `group`. |
| `id` | A name for the node, unique in the document (letters, digits, `_`, `.`, `-`, up to 64). `model.edit` finds a node by it, and it stays when the tree changes. `model.create` and `model.edit add` give a node without one an id such as `box_1`. |
| `note` | A sentence about the node; unused by the evaluation. |
| `enabled` | `false` skips the node and everything below it, without deleting it. Default `true`. |
| `part` | The name of the part this node and the nodes below it belong to (see "Parts"). |
| `material` | A key of the document's `materials`. Inherited by the nodes below. |
| `color` | Vertex colours: `[r, g, b]` or `[r, g, b, a]` in 0..1, or `"#rrggbb"` / `"#rrggbbaa"`. Inherited by the nodes below. |
| `position`, `rotation`, `scale` | The node's transform, relative to its parent. `position` in metres. `rotation` in degrees, `[x, y, z]` (pitch, yaw, roll), applied roll first, then pitch, then yaw. `scale` is a number or `[x, y, z]`; a negative entry mirrors the node (the triangles are turned so they still face out). |
| `align` | Primitives only (`lathe`, `sweep` and `loft` included; not modifiers or groups): `"center"` (default: the primitive's bounding box is centred on its origin), `"bottom"` (it stands on y = 0) or `"top"` (it hangs from y = 0), along Y, before `position` moves it. |

The transform is scale, then rotation, then position, so a rotated node turns about its own origin. A group's transform
applies to everything inside it.

### Coordinates, winding and normals

Metres, right-handed, +Y up, as everywhere in the engine. Triangles are counter-clockwise seen from outside and every
normal points out of the solid. A mirrored node keeps that. Every primitive is built centred on its origin (`text` starts at its
baseline); use `align` and `position` to place it.

## Determinism

The same document gives the same mesh and the same `.glb` bytes on every platform. The kernel builds with `+ - * /`, `sqrt`
and the engine's own `fa::det` trigonometry, nodes are evaluated in document order, and the only outside input is the font of
a `text` node: an engine font is data the binary ships; a project `.ttf` is a file the recipe records.

## Commands

| Command | What it does |
|---|---|
| `model.info {}` | The catalog: operations with their fields (type, range, default, doc), and the fields every node takes. |
| `model.info {path}` (or `{document}`) | Checks a document, returns the tree (pointer, op, id, part, material), where it bakes to, whether the `.glb` is fresh, and (unless `evaluate` is false) measurements: vertices, triangles, bounds and size, closed surface, volume, and the triangles and bounds of each part. A document with mistakes returns `valid: false` and ALL its issues. |
| `model.select {path, node, faces? | edges?}` | Tries a face or edge selection chosen by meaning on the mesh a node receives and reports how many matched, their area or length, bounds and parts, with a teaching warning when nothing matched. |
| `model.create {path, nodes?, materials?, uv?, texturing?, vertexColors?, output?, doc?, overwrite?, bake?}` | Writes a document (default: one box), gives the nodes ids, bakes it. |
| `model.edit {path, op, ...}` | `add` (`node`, `parent?`, `index?`), `set` (`target`, `values`; a null value removes a field), `remove` (`target`), `move` (`target`, `parent?`, `index?`), `document` (`doc`, `output`, `materials`, `uv`, `texturing`, `vertexColors`, `gameReady`; each replaces the whole field, null removes it). `target` and `parent` are a node id or a JSON pointer such as `/nodes/1/children/0`. The whole document is checked before anything is written. Then it bakes again. |
| `model.uv {path, set?, replace?, clear?, bake?, overwrite?, picture?}` | Gives the model UVs: merges `set` into the document's `uv` section (or replaces or clears it), checks the whole document, bakes the `.glb` again and returns the measurements and the layout picture. With neither `set` nor `clear` it only measures. See "UVs". |
| `model.texture {path, set?, replace?, clear?, bake?, overwrite?, picture?}` | Edits the `texturing` section (triplanar material textures, ambient occlusion, wear, decals, maps) the way `model.uv` edits `uv`, checks the whole document, bakes the model and its texture (an image document you can paint on) and returns the measurements and the texture picture. See "Texturing". |
| `model.decal {path, add?, remove?, clear?, bake?, overwrite?, picture?}` | Adds, replaces, removes or lists the decals of the `texturing` section; reports the texels each one painted. |
| `model.palette {path, set?, replace?, clear?, bake?, overwrite?, picture?}` | Edits the `vertexColors` section (style palette or your colours, a colour or gradient per part, flat low-poly faces, variation) and returns the report and the palette swatches. |
| `model.bake_maps {path, maps?, size?, samples?, distance?, thicknessDistance?, edgeAngle?, edgeWidth?, picture?}` | Measures the occlusion, curvature and thickness maps that wear is built from and returns them as a picture. Writes nothing; keep a map with `texturing.maps.write`. |
| `model.import_clean {source, out?, height? | reference? | scale?, platform?, triangles?, remesh?, ...}` | Cleans a `.glb`, `.gltf` or `.obj` (weld, floating pieces, scale, ground-centre origin, optional remesh, decimation to the platform budget, unwrap) into a baked model document with a `mesh` node, and reports what it did. See "Cleaning an imported mesh". |
| `model.game_ready {path, origin?, merge?, lods?, collider?, platforms?, clear?, bake?}` | Sets the game-ready settings of a document (each value given replaces that setting; null removes it; `clear` removes all), then bakes the `.glb`, LODs, collider and prefab. With no setting it only reports the budget check. See Game-ready models. |
| `model.generate_lods {model, levels?, ratios?, errors?, maxError?, screenSizes?, minTriangles?, lockBorder?, normalWeight?, uvWeight?, dryRun?, bake?, overwrite?}` | Turns on `gameReady.lodChain`, an automatic chain of simplified LODs drawn by screen size, bakes it and reports triangles, error and screen size per level. See docs/BIG_WORLDS.md, "Automatic LOD chain". |
| `model.bake {path?, force?, dryRun?, overwrite?}` | Builds the documents whose `.glb` is missing or stale (one with `path`; `force` also the fresh ones). Writes the `.glb` the way `mesh.save` writes a mesh, with provenance and a recipe in `assets.json`. |
| `model.preview {path \| document, views?, yaw?, pitch?, cell?, mode?, figure?, ground?, part?, out?, overwrite?}` | A turntable sheet PNG (4 to 8 views, shaded and/or wireframe) beside a 1.8 m figure, with the triangle count and size; returns the picture and `stats`. Read-only. See "Looking at a model". |
| `model.check {path \| document, expectedHeight?, tolerance?, platforms?, ignore?, samples?}` | Scale, origin, flipped and inconsistent triangles, open and non-manifold edges, degenerate triangles and the platform budgets, each finding with where, what and how to fix. Read-only; with no document it returns the catalog. |

`assets.regenerate` rebuilds a stale model, `project.validate` lists documents that do not load (an error per issue) or were
never baked (a warning), and `factoria export` bakes the stale ones first. A file at the output that no model document
baked is never replaced unless `overwrite` is true.

### Staleness

The recipe in `assets.json` records the hash of the document and of every file it reads (a project font, a material
texture). When any of them changes the `.glb` is stale: `model.info` says so, `project.validate` warns, and `model.bake` or
`assets.regenerate {"stale": true}` builds it again.

## Errors

Every problem of a document is reported at once, each with its JSON pointer, what is wrong and how to fix it, with "did you
mean" for operation names, fields, ids and materials:

```json
{"valid": false, "issues": [
  {"pointer": "/nodes/0/sise", "message": "\"sise\" is not a field of box nodes",
   "hint": "Did you mean 'size'? Valid: op, id, note, enabled, part, material, color, position, rotation, scale, align, size, ... (1 more)."},
  {"pointer": "/nodes/1/radius", "message": "radius must be from 0.001 to 1000, got -1", "hint": "Radius in metres."}]}
```

A bad `model.edit` writes nothing.

## Limits and known gaps

- A model has no region tags yet; that comes with a later milestone. A group with negative `scale` mirrors its children.
- `sdf`: no sharp features (a box is rounded to about a cell; use the `box` primitive for a crisp one), a feature thinner than a cell can vanish, and The distance of an ellipsoid and of a shape with a non-uniform `scale` is an approximation, exact on the surface, so a `smooth` next to one is a little wider or narrower than its number. An `sdf` node is meshed on its own: two `sdf` nodes do not blend into each other (put both in one).
- `bevel` leaves an edge sharp where it ends inside a smooth surface or meets other bevelled edges in a way it cannot join cleanly, and `subdivide` merges triangle pairs into quads only when they are coplanar. `smooth` with `taubin` can move the extremes of a shape a little outside its original bounds. A `bend` keeps the model straight beyond `from` and `to`.
- `text`: overlapping contours of a glyph are not merged (holes are found by nesting), and the ear-clipping triangulation may drop a sliver of almost no area; a glyph the font does not have is left out with a warning.
- Texturing: the whole model shares one atlas (one texture per model, not per part), the maps see only the model itself, the pixels you paint on the texture do not follow a changed UV layout, and a large `size` with many `samples` is slow (CPU only). See "Texturing", "Cost and limits".
- A baked `.glb` is a static mesh: no skeleton or animation.
