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
| `lathe` | A profile turned about the Y axis (a vase, a chess piece, a column). See "Shapes from a profile". | `profile` (required), `segments` (24), `angle` (360), `cap` (true), `creaseAngle` (40) |
| `sweep` | A closed profile moved along a path (a pipe, a rail, a handle). | `profile`, `path` (required), `smooth`, `pathSegments` (8), `closed`, `scaleStart`, `scaleEnd`, `twist`, `cap`, `creaseAngle` (50) |
| `loft` | A skin through several cross-sections (a hull, a bottle). | `sections` (required), `closed` (true), `smooth` (true), `steps` (4), `cap`, `creaseAngle` (50) |
| `group` | No geometry of its own: its `children` (a list of nodes) are placed by the group's transform. | `children` |

Segment and resolution fields trade smoothness for triangles. A model above 200,000 triangles gets a warning (it is heavy
for a game asset); more than the mesh store allows is an error.

### UV coordinates

(0, 0) is the top-left of the image and `v` grows downwards (glTF).

- `box`, `rounded_box`: every face covers the whole 0..1 square; seen from outside, `u` runs left to right and `v` top to bottom.
- `cylinder`, `cone`, `sphere`, `capsule`, `torus`, `pipe`: `u` runs 0 to 1 around the Y axis (the seam is at +Z, `u` grows towards +X); `v` runs along the profile (1 at the bottom, 0 at the top; around the tube for `torus`). The flat caps use a top-down projection of the disc into the 0..1 square.
- `grid`: 0..1 over the whole rectangle; `u` grows along +X and `v` towards -Z.
- `lathe`: `u` runs 0 to 1 around the Y axis (seam at +Z, `u` grows towards +X); `v` is 1 at the first profile point and 0 at the last, by length along the outline. `sweep`: `u` along the profile, `v` along the path, 0 to 1. `loft`: `u` along the points of a section, `v` along the sections. The caps of all three use the planar projection of their outline.
- `stairs`, `arch`, `text`: the front and back faces use the planar projection of the outline onto its bounding box; the side walls use (distance along the contour / its length, position along Z).

## Shapes from a profile: `lathe`, `sweep`, `loft`

These are primitives (they take `align`) that build a surface from a list of points written in the document.

```json
{"op": "lathe", "id": "vase", "align": "bottom", "segments": 32,
 "profile": [[0, 0], [0.3, 0], [0.4, 0.3], [0.25, 0.7], [0.15, 0.9], [0.2, 1.0]]}
```

- `lathe`: `profile` is `[radius, height]` points (2 to 256, radius 0 or more), walked either way round. It turns through `angle`
  degrees from +Z towards +X. A point at radius 0 is one vertex on the axis. With `cap` true (the default) an end of the outline
  that is off the axis is joined to the axis, so the turned shape is a solid; `cap: false` leaves the ends open (a bowl's rim, a
  pipe). If the last point equals the first the outline is a loop and is turned as it is: that makes a tube with a hole through it.
  A partial `angle` is closed with a flat wall at each end. Corners sharper than `creaseAngle` stay sharp.
- `sweep`: `profile` is a closed `[x, y]` outline (3 to 256 points) drawn in the plane perpendicular to the path, `x` to the right of
  the direction of travel and `y` up. `path` is `[x, y, z]` points (2 to 256). With `smooth` the path is a Catmull-Rom curve
  with `pathSegments` pieces between points, otherwise straight pieces with mitred joints. The frame is rotation-minimising: a path
  with no twist of its own gives a surface with none. `scaleStart`/`scaleEnd` grow or shrink the profile along the path, `twist`
  turns it by that many degrees from end to end, `closed: true` makes the path a loop (3 or more points; the twist is spread so
  the ends meet), `cap` closes an open path with the profile at both ends.
- `loft`: `sections` is a list of cross-sections (2 to 64), each a list of `[x, y, z]` points (2 to 256) with the same number in
  every section: point i of one is joined to point i of the next. `closed` true treats each section as a ring (3 points or more); `smooth` passes a curve through three or more
  sections with `steps` rows between each pair; `cap` closes the first and last section of ring sections.

## Modifiers

A modifier is a node that takes the mesh of its `children`, changes it and passes the result up, with the node's own transform
applied last. Modifiers WRAP their children rather than stacking on a node: to bevel then mirror a box you write
`mirror > bevel > box`, which reads in the order the work is done, a modifier can wrap a group or another modifier, `model.edit`
addresses every step by id, and a node's `enabled: false` switches the whole step off. (A modifier stack as a list on the node would
need a second kind of ordering next to the tree.) The children are merged into one mesh first, in document order, with their own
transforms, parts, materials and colours; the modifier keeps those (see "Modifiers and parts"). `align` is for primitives only.

Every modifier is a catalogue entry: `model.info {}` lists its fields with range, default and doc string, the schema knows them,
and a wrong value is an error with the JSON pointer and a fix. A modifier with nothing to work on gives a warning, not an error.

| Op | What it does | Fields (default) |
|---|---|---|
| `boolean` | Union, difference or intersection of closed solids. | `mode` (`union`; `difference`, `intersection`) |
| `mirror` | Adds the mirror image across a plane. | `axis` (`x`), `offset` (0), `merge` (true), `mergeDistance` (0.001) |
| `array` | Repeats the children along a step. | `count` (2, up to 4096), `offset` ([1,0,0]), `relative` (false), `stepRotation`, `stepScale`, `merge` (false), `mergeDistance` |
| `radial_array` | Repeats the children round an axis. | `count` (6, up to 1024), `axis` (`y`), `angle` (360), `center`, `faceCenter` (true), `merge`, `mergeDistance` |
| `bevel` | Rounds or chamfers sharp edges. | `width` (0.05), `segments` (2, 1 to 16), `angle` (30), `roundness` (1) |
| `subdivide` | Catmull-Clark subdivision. | `levels` (1 to 4), `creaseAngle` (180) |
| `solidify` | Gives a surface thickness, or hollows a solid. | `thickness` (0.05), `offset` (-1), `even` (true) |
| `bend` | Bends along an axis into an arc. | `axis` (`y`), `angle` (90), `direction` (0), `from`, `to` |
| `twist` | Twists about an axis. | `axis`, `angle` (90), `from`, `to` |
| `taper` | Scales the cross-section along an axis. | `axis`, `startScale` (1), `endScale` (0.5), `from`, `to` |
| `noise` | Roughens with seeded value noise. | `amplitude` (0.05), `frequency` (3), `octaves` (1 to 6), `seed` (0), `alongNormal` (true) |
| `smooth` | Laplacian or Taubin smoothing. | `iterations` (4), `factor` (0.5), `taubin` (true), `lockBoundary` (true), `sharpAngle` (180) |
| `weld` | Joins vertices closer than a distance. | `distance` (0.001) |
| `shade` | Flat, smooth or angle-based shading. | `mode` (`auto`; `flat`, `smooth`), `angle` (30) |

One small example of each (the children are written short; any nodes will do):

```json
{"op": "mirror", "axis": "x", "children": [{"op": "box", "size": [1, 1, 1], "position": [0.8, 0, 0]}]}
```
Two boxes, one each side of x = 0. With `merge` the vertices within `mergeDistance` of the plane lie exactly on it and are joined to
their copy, so a half face with a seam at the plane becomes one surface. The mirrored copy is turned so its faces still point out.

```json
{"op": "array", "count": 5, "offset": [1.2, 0, 0], "children": [{"op": "box", "size": [1, 1, 1]}]}
```
Five boxes in a row. `relative: true` takes `offset` in sizes of the children's bounding box (`[1, 0, 0]` puts them edge to edge);
`stepRotation` and `stepScale` are applied per copy, so `{"stepRotation": [0, 15, 0], "offset": [0, 0.2, 0]}` is a spiral staircase.

```json
{"op": "radial_array", "count": 8, "axis": "y", "children": [{"op": "box", "size": [0.1, 0.1, 1], "position": [0, 0, 0.5]}]}
```
Eight spokes round Y. `angle` below 360 spreads them over an arc (the first at 0, the last at `angle`); `faceCenter: false` moves the copies
without turning them.

```json
{"op": "bevel", "width": 0.04, "segments": 3, "children": [{"op": "box", "size": [1, 0.5, 1]}]}
```
Every edge whose faces turn by more than `angle` degrees becomes a strip of `segments` rows; big faces stay flat, the strips are shaded
smooth (`roundness` 0: straight rows, flat). A `width` too big for the faces is an error that says how wide it can be. An edge that ends
inside a smooth surface, or at a vertex that is not a clean manifold corner, is left sharp.

```json
{"op": "subdivide", "levels": 2, "creaseAngle": 60, "children": [{"op": "box", "size": [1, 1, 1]}]}
```
Catmull-Clark: each level multiplies the faces by 4 and rounds the shape. Edges whose faces turn by more than `creaseAngle` (and open
borders) are kept sharp (180: nothing is). Two triangles that make a flat quad are treated as that quad.

```json
{"op": "solidify", "thickness": 0.04, "children": [{"op": "grid", "width": 2, "depth": 2, "segments": 8}]}
```
A slab with walls along the open edges. On a closed solid it adds an inverted inner surface, making a hollow shell. `offset` -1 grows
the wall against the normals, 1 along them, 0 centred.

```json
{"op": "boolean", "mode": "difference", "children": [
  {"op": "box", "size": [2, 2, 2], "part": "block"},
  {"op": "cylinder", "radius": 0.5, "height": 3, "rotation": [90, 0, 0], "part": "hole"}]}
```
A block with a round hole through it. `union` joins all the children, `difference` takes the first enabled child and removes all the
others, `intersection` keeps what all share. Each child (a group counts as one) is an operand with its own transform, and every
operand must be a closed solid with its faces out: an open one (a `grid`, a `cone` without `cap`) is an error that names the operand by
JSON pointer and says how to fix it. Touching and coplanar faces work. The faces a difference cuts inside the first operand take the part
and material of the operand that cut them. Booleans use the vendored Manifold library (external/manifold, Apache-2.0), run on one
thread and give the same result every time; the operands together may have at most 400000 triangles.

```json
{"op": "bend", "axis": "y", "angle": 90, "children": [{"op": "box", "size": [0.3, 2, 0.3], "segments": [1, 16, 1]}]}
```
The part between `from` and `to` (default: the model's own extent along the axis) curves through `angle` degrees about a centre
on the side of `direction` (0 degrees bends towards +Z for `axis` y, towards +Y for x, towards +X for z; 90 degrees towards the next axis in that cycle). Beyond `from` and `to` the model continues straight. A box with one segment along the axis only tilts:
split it with `segments`.

```json
{"op": "twist", "axis": "y", "angle": 180, "children": [{"op": "box", "size": [0.4, 2, 0.4], "segments": [1, 24, 1]}]}
```
Turns each slice about the axis by a share of `angle` that grows from `from` to `to`.

```json
{"op": "taper", "axis": "y", "startScale": 1, "endScale": 0.2, "children": [{"op": "box", "size": [1, 3, 1], "segments": [1, 8, 1]}]}
```
Scales the cross-section from `startScale` at `from` to `endScale` at `to` (a tower that narrows; `endScale` 0 pinches to a point).

```json
{"op": "noise", "amplitude": 0.06, "frequency": 4, "octaves": 3, "seed": 7, "children": [{"op": "sphere", "radius": 0.5, "segments": 48}]}
```
Rock. A vertex moves along its normal by value noise of its own position, so a seam moves the same way on both sides and the surface
stays closed. The same `seed` always gives the same rock; the noise is made with integer hashes, not `rand()`.

```json
{"op": "smooth", "iterations": 6, "children": [{"op": "noise", "children": [{"op": "sphere", "segments": 48}]}]}
```
Moves each vertex towards the average of its neighbours; with `taubin` a second, opposite step keeps the shape from shrinking (it
may still move the extremes slightly past the original bounds). `sharpAngle` 60 keeps the corners of a box in place;
`lockBoundary` keeps the vertices of an open edge.

```json
{"op": "weld", "distance": 0.002, "children": [{"op": "box", "position": [-0.5005, 0, 0]}, {"op": "box", "position": [0.5005, 0, 0]}]}
```
Moves vertices closer than `distance` to their common centre and joins them; triangles that collapse are dropped. It closes
hairline gaps between pieces made to touch (two boxes welded face to face stay two shells that share a seam; use `boolean` `union` to fuse solids).

```json
{"op": "shade", "mode": "auto", "angle": 40, "children": [{"op": "rounded_box", "size": [1, 1, 1], "radius": 0.2}]}
```
`flat`: every face has its own normal (cut gem, low poly). `smooth`: normals are averaged over shared vertices (a ball). `auto`:
corners join only where the faces turn by less than `angle`, so a box stays sharp and a rounded edge is smooth. It changes normals only.
The modifiers that move vertices recompute the normals of the result in the same spirit (hard edges stay hard).

### Modifiers and parts

Parts, materials, colours and UVs follow the triangles through a modifier: a triangle made from a source triangle keeps its part,
material, colour and (interpolated) UV, so a later edit by meaning ("everything of part `handle`") still finds it after a mirror,
bevel or subdivision. The exceptions are the faces that did not exist before: the walls `solidify` adds take the part of the surface
they grow from, each half of the strip a `bevel` adds takes the part of the face it is next to, and a boolean's cut faces take the part of the cutter
(above). `part`, `material` and `color` given on the modifier node itself are inherited by the children that name none, like on a group.

### Limits of modifiers

- A node's result may have at most 1,000,000 triangles (400,000 across the operands of one boolean). Every modifier that can grow the
  mesh (`array`, `radial_array`, `mirror`, `subdivide`, `bevel`, `solidify`, `boolean`) checks before it builds and the error says
  what to lower (`count`, `levels`, `segments` of the children).
- Booleans refuse open surfaces and inside-out solids (a node with a negative `scale` on one axis is mirrored, which turns a solid inside
  out for a boolean: use `mirror`), and name the operand.
- Everything is deterministic: no `rand()`, no wall clock, noise from integer hashes, trigonometry from `fa::det`, booleans single-threaded. The
  same document gives the same mesh bytes.

## Organic shapes: `sdf`

Booleans and modifiers work on triangles; a creature, a rock or a tree is easier to say as a SOLID: "a body, a head melted into it, an
ear cut out". An `sdf` node says exactly that. Its `children` are signed-distance shapes, joined in order, and the engine turns
the solid into a triangle mesh. The result is an ordinary mesh node: `align` and the transform place it, a modifier can wrap it
(`mirror`, `subdivide`, `bend`...) and a `boolean` can take it as an operand.

| Node | What it is |
|---|---|
| `sdf` | The mesh of its children. `quality` or `voxelSize`, `targetTriangles` or `maxError`, and the noise fields. |
| `sdf_sphere` | `radius`. |
| `sdf_capsule` | `radius`, `radiusTop` (left out: the same, a capsule; otherwise a round cone), `height` tip to tip, along Y. |
| `sdf_ellipsoid` | `radii` [x, y, z]. |
| `sdf_box` | `size`, `round` (radius of the rounded edges). |
| `sdf_cylinder` | `radius`, `height`, `round`. |
| `sdf_cone` | `radius` (base), `radiusTop` (0: a point), `height`; point up. |
| `sdf_torus` | `radius` of the ring, `tube`; the hole is along Y. |
| `sdf_group` | Several of the above treated as one (they can hold more groups), with `mirror`. |

Every shape and group has the common fields (`position`, `rotation`, `scale`, `part`, `material`, `color`, `enabled`, `id`) and two
that say how it joins the shapes BEFORE it in the same list: `blend` (`union`, the default; `subtract`, cut it out of what is there;
`intersect`, keep what both have) and `smooth` (metres, 0 is a hard edge). The first shape of a list starts the solid and its `blend`
is ignored. A group is placed by its own transform, evaluates its children in order as a solid of their own and then joins the
shapes before it as one more shape: put a cut inside a group to cut only that group (the mushroom's cap below), or in the `sdf` to cut
everything before it. `mirror` (`x`, `y` or `z`) repeats the group on the other side of the plane through its origin: model the left
side, write the right for free (the shapes should sit on the positive side: what is on the negative side of the plane is left out and
replaced by the mirror image of the positive side). A shape or group is only valid inside an `sdf`, and an `sdf` holds nothing else: to mix a triangle primitive with an sdf,
put both under a `boolean` or a `group` outside it.

`smooth` is the quadratic smooth minimum: two surfaces closer than `smooth` melt into each other, a union fills the crease between a body and a leg, a
subtraction rounds the rim of the cut. It lowers the distance by at most a quarter of `smooth`, which is how far a smooth union can bulge past the hard one.

### What decides a triangle's part and colour

The meshed surface keeps what the shapes said. A triangle belongs to the `part` and `material` of the shape that OWNS its centre: far from any
join that is the nearest shape; inside a smooth blend it is the one with the larger share of the blend (the nearer one, by the same
numbers the blend uses); on the walls of a subtraction it is the CUTTER (the same rule as `boolean`'s `difference`: the cut faces take
the part of the cutter). A vertex takes the `color` at its position and melts it across a blend by the same shares, so a head
blended into a body fades from the head's colour to the body's. Shapes without a `color` give white to a model that has
coloured shapes elsewhere in the same `sdf`. The decimation keeps the borders between parts where they are, so a part never loses its edge
(`model.info` lists the triangles of every part).

### Meshing, resolution and cost

The field is sampled on a regular grid; `voxelSize` is the size of a cell in metres, and when it is left out `quality` picks the
number of cells along the longest side of the shape: `draft` 40, `normal` 96 (default), `fine` 160, `ultra` 200. A feature thinner
than a cell can vanish, and a shape with nothing left (everything subtracted away) gives a warning and no triangles.

The grid is cut into tetrahedra (marching tetrahedra) and every vertex is placed on the zero of the field along a cell edge. This is the
choice of method: surface nets and dual contouring put one vertex per cell and need rules for the cells where two opposite corners
are inside; a thin part or a tight blend through such a cell leaves a pinched vertex or an edge with four triangles, and a later
`boolean` or `bevel` refuses the mesh. Marching tetrahedra has no ambiguous case, so the surface is a closed manifold whatever the shapes do, and
nothing downstream has to repair it. Sharp edges of a box are rounded to about a cell, which suits organic shapes (a box wanted sharp is
a `box` primitive). It makes many thin triangles; the decimation below removes them.

Decimation (`targetTriangles`, `maxError`) is a quadric error metric: it collapses the edge whose collapse changes the surface least, and
keeps the surface closed and manifold (it refuses a collapse that would open it, flip a triangle or merge two parts' borders).
`targetTriangles` stops at about that many triangles; `maxError` (metres, the root mean square distance of the new vertex from the planes
it replaced) stops when the cheapest collapse costs more. With neither, the limit is a quarter of a cell; with only `targetTriangles` there is no error limit,
so ask for what the shape needs. `maxError` 0 with no `targetTriangles` turns decimation off (the creature below then has about 98,000 triangles instead of 3,000).

A request that would sample more than 12 million points, or evaluate more than 300 million (points x shapes), is refused before it runs, with the
voxel size that fits. The cost grows with the cube of the resolution: halving `voxelSize` is 8 times the samples.

`noiseAmplitude` (metres), `noiseFrequency` (features per metre), `noiseOctaves` and `noiseSeed` add seeded value noise to the field: the
surface moves along its normal by up to about the amplitude. It is for rock, bark and hide; the same seed gives the same rock on every
platform. Normals are the gradient of the whole field, noise included, so the result is smooth without a `shade` node. UV coordinates are a box
projection, one unit per metre, with vertices split where the projection changes axis.

### Examples

Each was checked with `model.info` (all `valid`, `closed` with no boundary or non-manifold edge, no warnings). The numbers are what the
current engine returns; the times are CPU seconds of `factoria call model.info` in a Release build on an Apple M-series laptop,
process start (0.07 s) included.

**A small creature** (7 shapes in 6 parts, 2212 vertices, 3000 triangles, 0.3 s). The ears, legs and eyes are groups with `mirror: "z"`: only the
shapes on the +Z side are written.

```json
{
  "format": "factoria.model/1",
  "doc": "A small round creature: body, head, mirrored ears, legs and eyes, and a tail.",
  "materials": {
    "fur": {"color": [0.78, 0.55, 0.35, 1], "roughness": 0.9},
    "eye": {"color": [0.04, 0.04, 0.06, 1], "roughness": 0.2}
  },
  "nodes": [
    {"op": "sdf", "id": "creature", "align": "bottom", "targetTriangles": 3000, "children": [
      {"op": "sdf_ellipsoid", "id": "body", "radii": [0.45, 0.38, 0.38], "position": [0, 0.5, 0], "part": "body", "material": "fur"},
      {"op": "sdf_sphere", "id": "head", "radius": 0.26, "position": [0.42, 0.78, 0], "smooth": 0.15, "part": "head", "material": "fur"},
      {"op": "sdf_group", "id": "ears", "mirror": "z", "smooth": 0.06, "part": "ears", "material": "fur", "children": [
        {"op": "sdf_capsule", "radius": 0.06, "height": 0.34, "position": [0.4, 1.06, 0.14], "rotation": [-12, 0, 0]}]},
      {"op": "sdf_group", "id": "legs", "mirror": "z", "smooth": 0.1, "part": "legs", "material": "fur", "children": [
        {"op": "sdf_capsule", "radius": 0.09, "radiusTop": 0.07, "height": 0.42, "position": [0.25, 0.21, 0.2]},
        {"op": "sdf_capsule", "radius": 0.09, "radiusTop": 0.07, "height": 0.42, "position": [-0.25, 0.21, 0.2]}]},
      {"op": "sdf_capsule", "id": "tail", "radius": 0.08, "radiusTop": 0.04, "height": 0.5, "position": [-0.58, 0.68, 0], "rotation": [0, 0, 55],
       "smooth": 0.12, "part": "tail", "material": "fur"},
      {"op": "sdf_group", "id": "eyes", "mirror": "z", "part": "eyes", "material": "eye", "children": [
        {"op": "sdf_sphere", "radius": 0.045, "position": [0.62, 0.84, 0.1]}]}]}
  ]
}
```

**A rock** (997 vertices, 1500 triangles, 0.3 s). Two ellipsoids melted together, a pit cut out of one side, rough from seeded noise. Change `noiseSeed` for another rock.

```json
{
  "format": "factoria.model/1",
  "doc": "A boulder: two lumps melted together, a pit cut into one side, rough by seeded noise.",
  "materials": {"stone": {"color": [0.5, 0.49, 0.46, 1], "roughness": 1}},
  "nodes": [
    {"op": "sdf", "id": "rock", "align": "bottom", "material": "stone", "part": "rock", "noiseAmplitude": 0.05, "noiseFrequency": 3,
     "noiseOctaves": 3, "noiseSeed": 7, "targetTriangles": 1500, "children": [
      {"op": "sdf_ellipsoid", "id": "base", "radii": [0.8, 0.5, 0.6]},
      {"op": "sdf_ellipsoid", "id": "lump", "radii": [0.5, 0.4, 0.45], "position": [0.3, 0.2, 0.1], "rotation": [0, 30, 0], "smooth": 0.1},
      {"op": "sdf_sphere", "id": "pit", "radius": 0.22, "position": [0.55, 0.15, 0.4], "blend": "subtract", "smooth": 0.08}]}
  ]
}
```

**A tree** (479 vertices, 560 triangles, 0.23 s, `trunk` and `leaves` parts). No `targetTriangles`: the default error limit does the decimation.

```json
{
  "format": "factoria.model/1",
  "doc": "A tree: a trunk that flares into roots and a canopy of three blobs, bark and leaves as separate parts.",
  "materials": {"bark": {"color": [0.4, 0.28, 0.18, 1], "roughness": 1}, "leaves": {"color": [0.25, 0.55, 0.22, 1], "roughness": 0.8}},
  "nodes": [
    {"op": "sdf", "id": "tree", "align": "bottom", "noiseAmplitude": 0.03, "noiseFrequency": 4, "noiseSeed": 2, "children": [
      {"op": "sdf_cone", "id": "trunk", "radius": 0.22, "radiusTop": 0.1, "height": 1.8, "position": [0, 0.9, 0], "part": "trunk", "material": "bark"},
      {"op": "sdf_group", "id": "roots", "mirror": "x", "smooth": 0.15, "part": "trunk", "material": "bark", "children": [
        {"op": "sdf_capsule", "radius": 0.07, "height": 0.7, "position": [0.2, 0.06, 0], "rotation": [0, 0, 70]}]},
      {"op": "sdf_sphere", "id": "crown", "radius": 0.75, "position": [0, 2.2, 0], "smooth": 0.3, "part": "leaves", "material": "leaves"},
      {"op": "sdf_sphere", "id": "left", "radius": 0.5, "position": [-0.55, 1.95, 0.15], "smooth": 0.3, "part": "leaves", "material": "leaves"},
      {"op": "sdf_sphere", "id": "right", "radius": 0.55, "position": [0.5, 2.0, -0.1], "smooth": 0.3, "part": "leaves", "material": "leaves"}]}
  ]
}
```

**A mushroom** (2028 vertices, 2500 triangles, 0.46 s). The cap is a group that cuts its own underside flat; the spots are another part with another material.

```json
{
  "format": "factoria.model/1",
  "doc": "A mushroom: a stem, a cap cut flat underneath and white spots, each its own part.",
  "materials": {"stem": {"color": [0.92, 0.88, 0.78, 1]}, "cap": {"color": [0.75, 0.15, 0.12, 1], "roughness": 0.5}, "spots": {"color": [0.96, 0.95, 0.9, 1]}},
  "nodes": [
    {"op": "sdf", "id": "mushroom", "align": "bottom", "targetTriangles": 2500, "children": [
      {"op": "sdf_cylinder", "id": "stem", "radius": 0.12, "height": 0.5, "round": 0.04, "position": [0, 0.25, 0], "part": "stem", "material": "stem"},
      {"op": "sdf_group", "id": "cap", "smooth": 0.05, "part": "cap", "material": "cap", "position": [0, 0.5, 0], "children": [
        {"op": "sdf_ellipsoid", "radii": [0.4, 0.28, 0.4]},
        {"op": "sdf_box", "size": [1.2, 0.6, 1.2], "position": [0, -0.3, 0], "blend": "subtract", "smooth": 0.02}]},
      {"op": "sdf_group", "id": "spots", "part": "spots", "material": "spots", "children": [
        {"op": "sdf_sphere", "radius": 0.06, "position": [0.12, 0.77, 0.08]},
        {"op": "sdf_sphere", "radius": 0.05, "position": [-0.14, 0.74, 0.14]},
        {"op": "sdf_sphere", "radius": 0.045, "position": [0.0, 0.79, -0.15]}]}]}
  ]
}
```

Edit by id like any model: `model.edit {"path": "assets/models/rock.model.json", "op": "set", "target": "pit", "values": {"radius": 0.3}}`; to add a
shape to an `sdf`, `{"op": "add", "parent": "rock", "node": {"op": "sdf_sphere", ...}}`.

## UVs

The primitives' own UVs (see "UV coordinates") are fine for a texture that repeats on a box, but they overlap between parts and
differ in scale from one primitive to the next. A `uv` section on the document gives the WHOLE model new UVs, made after every node
(modifiers, booleans and `sdf` included; an `sdf` result gets them in place of its default box projection):

```json
{"format": "factoria.model/1",
 "uv": {"method": "unwrap", "texelsPerUnit": 256, "parts": {"wheel": {"method": "cylinder", "axis": "x"}}},
 "nodes": [...]}
```

`factoria call model.uv '{"path":"assets/models/cart.model.json","set":{"method":"unwrap"}}'` writes the section, bakes the `.glb`,
measures the result and returns a picture of the layout (the texture square with every triangle at its UVs, a colour per part,
mirrored triangles red). `model.uv {path}` alone only measures (a document with no `uv` section is measured on its primitives' own
UVs). `set` merges into the section (a field set to null is removed, `parts` merges part by part), `replace: true` puts `set` in
place of the section, `clear: true` removes it. The whole document is checked first; a mistake returns every issue with its JSON
pointer and writes nothing.

| Field | Meaning |
|---|---|
| `layout` | `"atlas"` (default): every piece is packed into one 0..1 square, a texture painted for this model. `"tile"`: world-scale UVs that continue across the whole model and repeat (a seamless texture); nothing is cut or packed, the default method is `box`, and `unwrap` is an error. |
| `method` | `"unwrap"` (atlas default), `"box"` (tile default), `"cylinder"`, `"sphere"` or `"planar"`. See below. |
| `axis` | `"x"`, `"y"` (default) or `"z"`: the axis of a cylinder or sphere, the direction a `planar` projection looks along. |
| `texelsPerUnit` | Texels per metre of surface. Left out: the project's `assets.json` `style.texelsPerUnit`, else 128. 1 to 16384. |
| `textureSize` | Side of the square texture in texels, 16 to 4096. 0 (default): the smallest power of two the pieces fit in. A fixed size they do not fit at the density lowers the density for the whole model, and the report says so. For `tile` it is the size of the texture that repeats (0: 1024); one repeat is `textureSize / texelsPerUnit` metres. |
| `padding` | Empty texels kept around each piece of an atlas, 0 to 32 (default 2), so filtering and mipmaps do not bleed one piece into the next. |
| `seams` | `unwrap` only: `"few"` cuts the surface into fewer, bigger pieces (fewer seams, more risk of stretch), `"many"` into more, smaller ones; `"balanced"` (default) is in between. It does not promise less stretch: read `stretch` in the report. |
| `rotate` | Atlas: the packer may turn pieces by 90 degrees to fill the texture. Default: true when every part is unwrapped, false when a part is projected, so a texture drawn on a projected part stays upright. |
| `parts` | `{part name: {method, axis, texelsPerUnit}}`: override those three for one part. The part `""` is the nodes that name no part. A name that is not a part of the model is a warning with "did you mean". |

**Methods.** `unwrap` is xatlas (vendored, MIT): it cuts the surface into charts that flatten with little stretch and packs
them. A part is unwrapped on its own, so a seam never crosses from one part to another. The projections give a texture that reads
upright and not mirrored when the surface is seen from outside:

- `box`: each face goes on the axis plane it looks at most. One piece per run of connected faces on the same plane. Faces that look up or down put -Z at the top of the image.
- `cylinder`: around `axis`, `u` is the distance along the circle at the part's mean radius (the radius of the sides, not of the caps), `v` the height. The seam is on the -e1 side (-Z for `y`, -Y for `x`, -X for `z`). Faces that look along the axis (the caps) are projected flat.
- `sphere`: longitude and latitude around `axis`, `v` from the +axis pole (0) to the opposite one. A triangle that contains a pole can come out mirrored (it is a pole: the whole top row of the texture is one point); the report counts them in `flippedTriangles`.
- `planar`: everything along `axis`. On a closed shape the near and far side overlap, and the report warns about it. Use it for a flat panel or a decal.

**Density.** Every piece is scaled so that a metre of surface is `texelsPerUnit` texels (per part when a part gives its own), so a
texture has the same detail on the door and on the roof. The report measures it: `texelsPerMeter` (mean, min, max, also per part).
An `unwrap` keeps the metric; a projection stretches only where the shape departs from its projection.

**What the report says.** `model.uv` returns, and `model.info`/`model.create`/`model.edit` carry under `measurements.uv`:
`layout`, `textureSize`, `texelsPerUnit` (asked) and `texelsPerUnitUsed` (reached), `triangles`, `charts`, `seams` (`edges` and
`length` in metres), `surfaceArea`, `texelsPerMeter`, `stretch` (the ratio of the largest to the smallest scale of the map, 1 =
none, 2 = twice as long one way: mean by area and worst triangle), `flippedTriangles` (mirrored against the rest of their chart:
a texture reads backwards there), `utilization` (share of the texture covered), `overlap` (share of the covered texels that two
triangles share; a texture painted there shows on both), `outsideTriangles`, `parts` and `warnings`. `project.validate` repeats the
warnings of a document with a `uv` section, so a model that smears is found without asking.

**Style and staleness.** When the section gives no `texelsPerUnit` the project's `style.texelsPerUnit` is used, and the recipe
records it: change the style and the `.glb` is stale (`assets.regenerate` builds it again). The `uv` section is part of the
document, so changing it makes the `.glb` stale like any other edit.

**For code.** `fa/scene/model_uv.h` (`model_uv_apply`, `model_uv_measure`) works on any `ModelMesh` and the part of each triangle,
not only on documents. The result is the same triangles in the same order with vertices split along the seams. It is single
threaded and deterministic: the same mesh and settings give the same UVs on every platform.

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
| `model.create {path, nodes?, materials?, uv?, output?, doc?, overwrite?, bake?}` | Writes a document (default: one box), gives the nodes ids, bakes it. |
| `model.edit {path, op, ...}` | `add` (`node`, `parent?`, `index?`), `set` (`target`, `values`; a null value removes a field), `remove` (`target`), `move` (`target`, `parent?`, `index?`), `document` (`doc`, `output`, `materials`, `uv`; each replaces the whole field, null removes it). `target` and `parent` are a node id or a JSON pointer such as `/nodes/1/children/0`. The whole document is checked before anything is written. Then it bakes again. |
| `model.uv {path, set?, replace?, clear?, bake?, overwrite?, picture?}` | Gives the model UVs: merges `set` into the document's `uv` section (or replaces or clears it), checks the whole document, bakes the `.glb` again and returns the measurements and the layout picture. With neither `set` nor `clear` it only measures. See "UVs". |
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

- A model has no region tags yet; that comes with a later milestone. A group with negative `scale` mirrors its children.
- `sdf`: no sharp features (a box is rounded to about a cell; use the `box` primitive for a crisp one), a feature thinner than a cell can vanish, and The distance of an ellipsoid and of a shape with a non-uniform `scale` is an approximation, exact on the surface, so a `smooth` next to one is a little wider or narrower than its number. An `sdf` node is meshed on its own: two `sdf` nodes do not blend into each other (put both in one).
- `bevel` leaves an edge sharp where it ends inside a smooth surface or meets other bevelled edges in a way it cannot join cleanly, and `subdivide` merges triangle pairs into quads only when they are coplanar. `smooth` with `taubin` can move the extremes of a shape a little outside its original bounds. A `bend` keeps the model straight beyond `from` and `to`.
- `text`: overlapping contours of a glyph are not merged (holes are found by nesting), and the ear-clipping triangulation may drop a sliver of almost no area; a glyph the font does not have is left out with a warning.
- `model.preview` and `model.check` (pictures and the mesh-quality checks) are not there yet: `model.info` measures what the model builds, and the numbers it returns are the checks that exist today.
- A baked `.glb` is a static mesh: no skeleton or animation.
