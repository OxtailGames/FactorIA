# 3D models as data: `*.model.json`

A model document is a small JSON file that is the SOURCE of a 3D model: a tree of operations (parametric primitives, groups,
and a transform on any node) with named parts, materials and vertex colours. The `.glb` a `MeshRenderer` draws is BAKED from
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

## The document

| Field | Meaning |
|---|---|
| `format` | `"factoria.model/1"`. Required. |
| `doc` | A sentence for people and AIs; unused by the evaluation. |
| `output` | `{"path": "assets/..../name.glb"}`: where to bake. Default: the document's name with `.model.json` replaced by `.glb`. `model.bake` refuses a path outside `assets/`. |
| `materials` | `{name: {color, texture, metallic, roughness, emissive, doubleSided, blend}}`, the materials nodes refer to by name. The fields are those of a `mesh.save` material (docs/SCRIPTING.md, "Procedural meshes"); `texture` is a project file. |
| `nodes` | The tree, in order. Required, at least one node that makes a triangle. At most 2048 nodes (groups included) and 16 levels of nested groups. |

### Nodes

Every node is an object with an `op` and these fields (a field that is left out has its default):

| Field | Meaning |
|---|---|
| `op` | The operation: a primitive or `group`. |
| `id` | A name for the node, unique in the document (letters, digits, `_`, `.`, `-`, up to 64). `model.edit` finds a node by it, and it stays when the tree changes. `model.create` and `model.edit add` give a node without one an id such as `box_1`. |
| `note` | A sentence about the node; unused by the evaluation. |
| `enabled` | `false` skips the node and everything below it, without deleting it. Default `true`. |
| `part` | The name of the part this node and the nodes below it belong to (see "Parts"). |
| `material` | A key of the document's `materials`. Inherited by the nodes below. |
| `color` | Vertex colours: `[r, g, b]` or `[r, g, b, a]` in 0..1, or `"#rrggbb"` / `"#rrggbbaa"`. Inherited by the nodes below. |
| `position`, `rotation`, `scale` | The node's transform, relative to its parent. `position` in metres. `rotation` in degrees, `[x, y, z]` (pitch, yaw, roll), applied roll first, then pitch, then yaw. `scale` is a number or `[x, y, z]`; a negative entry mirrors the node (the triangles are turned so they still face out). |
| `align` | Primitives only: `"center"` (default: the primitive's bounding box is centred on its origin), `"bottom"` (it stands on y = 0) or `"top"` (it hangs from y = 0), along Y, before `position` moves it. |

The transform is scale, then rotation, then position, so a rotated node turns about its own origin. A group's transform
applies to everything inside it.

### Coordinates, winding and normals

Metres, right-handed, +Y up, as everywhere in the engine. Triangles are counter-clockwise seen from outside and every
normal points out of the solid. A mirrored node keeps that. Every primitive is built centred on its origin (`text` starts at its
baseline); use `align` and `position` to place it.

## Primitives

Sizes are in metres. The ranges below are checked: a value out of range is an error with its JSON pointer and the allowed
range. `model.info {}` lists them all with their doc strings and defaults.

| Op | What it makes | Fields (default) |
|---|---|---|
| `box` | A box centred on its origin: X width, Y height, Z depth. | `size` (1: a number or `[x, y, z]`), `segments` (1: subdivisions per axis, a number or `[x, y, z]`) |
| `rounded_box` | A box with rounded edges and corners. | `size`, `radius` (0.1: cut down to half the smallest side), `segments` (4: quads per corner arc; 1 is a bevel) |
| `cylinder` | An upright cylinder (a frustum with `radiusTop`) with flat caps, axis along Y. | `radius` (0.5), `radiusTop` (left out: same as `radius`), `height` (1), `segments` (24), `heightSegments` (1), `capBottom`, `capTop` (true) |
| `cone` | A cone, point up (a frustum when `radiusTop` is above 0). | `radius` (0.5), `radiusTop` (0), `height` (1), `segments` (24), `heightSegments` (1), `cap` (true: the base disc) |
| `sphere` | A UV sphere, poles on Y. | `radius` (0.5), `segments` (24: meridians), `rings` (left out: `segments / 2`) |
| `capsule` | A cylinder with a hemisphere at each end, upright; `height` is tip to tip. | `radius` (0.5), `height` (2, at least twice the radius), `segments` (24), `rings` (8: per hemisphere), `heightSegments` (1) |
| `torus` | A ring lying flat in XZ, its hole along Y. | `radius` (0.5: centre to the middle of the tube), `tube` (0.15, at most `radius`), `segments` (32), `sides` (16) |
| `grid` | A flat rectangle in XZ facing +Y: a floor, water, a cloth. One-sided. | `width` (1, X), `depth` (1, Z), `segments` (1: cells along X and Z, a number or `[x, z]`) |
| `stairs` | A solid staircase. It climbs towards -Z: the lowest step is at +Z. | `steps` (6), `width` (1, X), `height` (1), `depth` (1.5, Z) |
| `arch` | A wall with an arched doorway through it (round top); the doorway goes through along Z. | `width` (2, X), `height` (2.5, Y), `depth` (0.4, Z), `openingWidth` (1, less than `width`), `openingHeight` (1.8, from the bottom edge to the top of the arch, at least half of `openingWidth`, less than `height`), `segments` (12: in the half circle) |
| `pipe` | A tube: a cylinder with a round hole through it, open at both ends. | `radius` (0.5), `innerRadius` (0.4, less than `radius`), `height` (1), `segments` (24) |
| `text` | Text as a solid, from the engine's own font data. The letters stand in the XY plane, readable from +Z; thickness along Z centred on 0; the baseline of the first line at y = 0. Holes (the inside of an O) are cut out. | `text` (required, up to 200 characters, `\n` for lines), `font` (`""` = DejaVu Sans; `builtin:serif`, `builtin:hand`, `builtin:display`, `builtin:blackletter`, `builtin:pixel`; or a project `.ttf`/`.otf`), `size` (1: metres per em), `depth` (0.2), `curveSegments` (6), `anchor` (`middle`; `start`, `end`: where the text sits against the origin along X), `letterSpacing` (0, ems), `lineSpacing` (1) |
| `group` | No geometry of its own: its `children` (a list of nodes) are placed by the group's transform. | `children` |

Segment and resolution fields trade smoothness for triangles. A model above 200,000 triangles gets a warning (it is heavy
for a game asset); more than the mesh store allows is an error.

### UV coordinates

(0, 0) is the top-left of the image and `v` grows downwards (glTF).

- `box`, `rounded_box`: every face covers the whole 0..1 square; seen from outside, `u` runs left to right and `v` top to bottom.
- `cylinder`, `cone`, `sphere`, `capsule`, `torus`, `pipe`: `u` runs 0 to 1 around the Y axis (the seam is at +Z, `u` grows towards +X); `v` runs along the profile (1 at the bottom, 0 at the top; around the tube for `torus`). The flat caps use a top-down projection of the disc into the 0..1 square.
- `grid`: 0..1 over the whole rectangle; `u` grows along +X and `v` towards -Z.
- `stairs`, `arch`, `text`: the front and back faces use the planar projection of the outline onto its bounding box; the side walls use (distance along the contour / its length, position along Z).

## Parts, materials and vertex colours

A **part** is a labelled piece of the model. A node with `part` gives that name to itself and to every node below it that
does not name another one. The baked mesh has one submesh (one glTF primitive) per part and material pair, in the order they
are first used, and the primitive carries the part name in its `extras.part`, so a game finds "the door" and "the knob" in
the `.glb`. `model.info` and `model.bake` list the parts with their triangles and bounding boxes. A node with no part belongs
to the part named `""`.

`material` names an entry of the document's `materials`; a node without one (and none above it) uses the default material. A
reference to a name that is not in `materials` is an error that lists the names that are.

`color` writes vertex colours (`COLOR_0`), which a viewer multiplies with the material's colour. When only some nodes have a
colour, the vertices of the others are white.

## Determinism

The same document gives the same mesh and the same `.glb` bytes on every platform. The kernel builds with `+ - * /`, `sqrt`
and the engine's own `fa::det` trigonometry, nodes are evaluated in document order, and the only outside input is the font of
a `text` node: an engine font is data the binary ships; a project `.ttf` is a file the recipe records.

## Commands

| Command | What it does |
|---|---|
| `model.info {}` | The catalog: operations with their fields (type, range, default, doc), and the fields every node takes. |
| `model.info {path}` (or `{document}`) | Checks a document, returns the tree (pointer, op, id, part, material), where it bakes to, whether the `.glb` is fresh, and (unless `evaluate` is false) measurements: vertices, triangles, bounds and size, closed surface, volume, and the triangles and bounds of each part. A document with mistakes returns `valid: false` and ALL its issues. |
| `model.create {path, nodes?, materials?, output?, doc?, overwrite?, bake?}` | Writes a document (default: one box), gives the nodes ids, bakes it. |
| `model.edit {path, op, ...}` | `add` (`node`, `parent?`, `index?`), `set` (`target`, `values`; a null value removes a field), `remove` (`target`), `move` (`target`, `parent?`, `index?`), `document` (`doc`, `output`, `materials`). `target` and `parent` are a node id or a JSON pointer such as `/nodes/1/children/0`. The whole document is checked before anything is written. Then it bakes again. |
| `model.bake {path?, force?, dryRun?, overwrite?}` | Builds the documents whose `.glb` is missing or stale (one with `path`; `force` also the fresh ones). Writes the `.glb` the way `mesh.save` writes a mesh, with provenance and a recipe in `assets.json`. |

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

- A model has no modifiers yet (no booleans, bevel, array, mirror or deform) and no region tags; those come with later milestones. A group with negative `scale` mirrors its children.
- `text`: overlapping contours of a glyph are not merged (holes are found by nesting), and the ear-clipping triangulation may drop a sliver of almost no area; a glyph the font does not have is left out with a warning.
- `model.preview` and `model.check` (pictures and the mesh-quality checks) are not there yet: `model.info` measures what the model builds, and the numbers it returns are the checks that exist today.
- A baked `.glb` is a static mesh: no skeleton or animation.
