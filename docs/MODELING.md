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

## Selections and edits

Some edits work on PART of a surface: push a panel out of a wall, sink a recess, round the rim of a lid, open the top of a box,
move the top faces into another part. For these the document does not name triangles (`face 17`): triangle numbers change as
soon as a box gets more segments or a primitive changes size, and an index that meant "the top" yesterday means "a corner"
today. A **selection is a query by meaning**, written in the node and evaluated on the mesh that reaches it every time the
document is built:

- `extrude_faces`, `inset_faces`, `delete_faces` and `assign_faces` take `faces`, a **face query**;
- `bevel_edges` takes `edges`, an **edge query**;
- `loop_cut` needs no selection: it cuts a ring at a height.

Like a modifier, an edit node WRAPS its `children` (the mesh it works on is the merged mesh of the children), has the common
fields (`id`, `part`, `position`...), and is edited by id. `model.info {}` lists every query with its fields under `selections`;
`model.select` tries one and says what it matched (below). Every query below is checked when the document is read: a wrong
field, an unknown `by`, a box with `min` above `max` or a zero direction is an error with its JSON pointer and a fix, with "did
you mean" for names.

### Face queries

A query is an object with `by` and the fields that `by` takes.

| `by` | Chooses | Fields (default) |
|---|---|---|
| `normal` | faces pointing in a direction | `direction` (`top`, `bottom`, `front`, `back`, `left`, `right`, or `[x, y, z]`), `tolerance` (30 degrees), `space` |
| `part` | faces of a part (`""`: nodes with no part) | `part`, or `parts` (a list) |
| `top` / `bottom` | the highest / lowest faces along an axis | `axis` (`y`), `within` (0.01% of the extent), `of` (look only among the faces this query chooses), `space` |
| `box` | faces inside an axis-aligned box | `min`, `max`, `contain` (`center`; `all`, `any`), `space` |
| `sphere` | faces inside a ball | `center`, `radius`, `contain`, `space` |
| `halfspace` | faces on one side of a plane | `point`, `normal` (the side that is chosen), `contain`, `space` |
| `all` | every face | |
| `and` / `or` | faces that all / any of the queries in `of` choose | `of` (a list) |
| `not` | every face that `of` does not choose | `of` |
| `grow` / `shrink` | the faces plus (minus) the ring of neighbours that share an edge | `of`, `steps` (1) |

Directions and distances are in the space of the edit node's children (before the node's own `position`, `rotation` and `scale`):
a box 1 m wide is [-0.5, 0.5] whatever the node does. `"space": "model"` measures in the model's space instead, through the
transforms of this node and of the groups above it (a `normal` query with `"direction": "top"` and `"space": "model"` picks the
faces that point up in the finished model even when the group they are in is tilted). `top` / `bottom` choose by the position of the
faces, not by where they point, so they find the cap of a cylinder and the top row of a wall; `normal` finds every face that points
that way.

### Edge queries

| `by` | Chooses | Fields (default) |
|---|---|---|
| `border` | the edges around a group of faces (a chosen face on one side only) | `faces` (a face query) |
| `sharp` | edges where the two faces turn by more than an angle | `angle` (30), `faces` (only edges that touch these faces) |
| `between_parts` | the seam where one part meets another | `a`, `b` (both: that seam; one: every seam of that part; none: all seams) |
| `loop` | the edges in the plane perpendicular to an axis at a height | `axis` (`y`), `at` (a coordinate) or `ratio` (0 to 1 of the extent along the axis; 0.5), `tolerance`, `space` |
| `all`, `and`, `or`, `not` | as for faces | |

### The edits

| Op | What it does | Fields (default) |
|---|---|---|
| `extrude_faces` | Pushes the chosen faces out of the surface and joins them with walls. | `faces`, `distance` (0.1; negative sinks them), `direction` (the average of the faces' normals around each vertex), `newPart`, `newMaterial` |
| `inset_faces` | Shrinks the chosen faces inside their border and fills the gap with a ring of faces; with a `depth` the ring slopes up or down to the inner faces. | `faces`, `thickness` (0.05), `depth` (0; raises or sinks the inner faces), `newPart`, `newMaterial` |
| `loop_cut` | Splits every face the plane crosses along a ring of edges; the shape does not change. | `axis` (`y`), `at` or `ratio` or `count` (evenly spaced cuts, 1 to 64) |
| `bevel_edges` | Rounds or chamfers only the chosen edges (like `bevel`, which does every sharp edge). | `edges`, `width` (0.05), `segments` (2), `roundness` (1) |
| `delete_faces` | Removes the chosen faces; the hole is left open. | `faces` |
| `assign_faces` | Moves the chosen faces to another part and/or material without changing the shape. | `faces`, `toPart`, `toMaterial` (at least one) |

**Parts are kept.** Every face keeps the part of the face it came from. The walls of an extrusion and the ring of an inset
are new faces: they take `newPart` / `newMaterial` (a part name of your choice, or a key of `materials`) or, left out, the
part of the face they grew from. An extrusion gives its moved faces and its walls the same new part (the thing that was pushed
out), an inset gives only the ring. `loop_cut` splits a face and both halves keep its part. `assign_faces` is how an existing
surface changes part, and it is what lets `between_parts` find a seam.

**Stable when the model changes.** The query, not the result, is stored. With a `box` of `segments` [1, 1, 1] or [8, 8, 8],
`{"by": "normal", "direction": "top"}` chooses the faces of the top (2 or 128 triangles) and the extrusion moves exactly those;
change the box's `size` and `loop_cut` with `ratio` stays at the same fraction of the height. Nothing refers to triangle numbers,
and the result depends only on the geometry, so building twice gives the same bytes.

**Empty selections teach.** A query that matches nothing does not fail the build (a parametric model should survive a tweak
upstream): the edit leaves the mesh as it is and a warning says why: which part names exist and the closest one ("did you mean"),
how many degrees the closest face is from the direction, the bounds the mesh spans when a box or sphere missed, the nearest height
for a `loop`. An edit that cannot be built is an error that says how to fix it: an inset wider than the faces ("the most these faces
allow is about 0.21"), a result with more than a million triangles.

### Trying a selection: `model.select`

`model.select {path, node, faces | edges}` evaluates the document up to the node (its id or JSON pointer) and runs the query on
the mesh that node receives: the merged children of a group or modifier, or the mesh a primitive made. It answers how many faces
(or edges) matched out of how many, their area (or length), their bounds and how many belong to each part, or the warning above.
Without `faces` / `edges` it uses the node's own selection, so it tells what an edit node will edit. `model.info` lists the same
numbers for every edit node under `measurements.edits`.

```
factoria call model.select '{"path":"assets/models/crate.model.json","node":"body","faces":{"by":"normal","direction":"top"}}'
{"select": "faces", "matched": 2, "total": 12, "area": 1.0, "bounds": {"min": [-0.5, 0.5, -0.5], "max": [0.5, 0.5, 0.5], ...},
 "parts": [{"part": "body", "count": 2}]}
```

### Examples

A raised button on the top of a crate. The inset frames the top (its ring is the part `frame`, the inner faces stay `body`),
then only the inner top faces, the ones that point up and are still `body`, are pushed out as the part `button`:

```json
{
  "format": "factoria.model/1",
  "doc": "A crate with a button raised from its top.",
  "nodes": [
    {"op": "extrude_faces", "id": "button", "distance": 0.1, "newPart": "button",
     "faces": {"by": "and", "of": [{"by": "normal", "direction": "top"}, {"by": "part", "part": "body"}]},
     "children": [
       {"op": "inset_faces", "id": "frame", "thickness": 0.15, "newPart": "frame",
        "faces": {"by": "normal", "direction": "top"},
        "children": [{"op": "box", "id": "crate", "size": [1, 0.4, 1], "part": "body"}]}]}
  ]
}
```

A lid with a rounded rim. The top faces move to the part `lid`; the seam between the lid and the body is found by meaning and
only it is bevelled:

```json
{
  "format": "factoria.model/1",
  "doc": "A box whose lid has a bevelled rim.",
  "nodes": [
    {"op": "bevel_edges", "id": "rim", "width": 0.04, "edges": {"by": "between_parts", "a": "lid", "b": "body"},
     "children": [
       {"op": "assign_faces", "id": "lid", "toPart": "lid", "faces": {"by": "normal", "direction": "top"},
        "children": [{"op": "box", "size": [1, 0.5, 1], "part": "body"}]}]}
  ]
}
```

A belt round a barrel. `loop_cut` makes two rings at a third and two thirds of the height; the faces between them are chosen by
a box and pushed out along their normals:

```json
{
  "format": "factoria.model/1",
  "doc": "A drum with a raised belt.",
  "nodes": [
    {"op": "extrude_faces", "id": "belt", "distance": 0.04, "newPart": "belt",
     "faces": {"by": "box", "min": [-1, -0.17, -1], "max": [1, 0.17, 1], "contain": "all"},
     "children": [{"op": "loop_cut", "id": "rings", "count": 2, "children": [{"op": "cylinder", "radius": 0.4, "height": 1, "part": "drum"}]}]}
  ]
}
```

A recess in a panel. `inset_faces` with a negative `depth` sinks the inner faces; the ring between the border and them slopes
down to the new depth, so it is a tray with sloped sides (the ring takes the part `recess`):

```json
{
  "format": "factoria.model/1",
  "doc": "A panel with a recess.",
  "nodes": [
    {"op": "inset_faces", "id": "recess", "thickness": 0.1, "depth": -0.05, "newPart": "recess",
     "faces": {"by": "and", "of": [{"by": "normal", "direction": "front"}, {"by": "box", "min": [-1, -1, 0], "max": [1, 1, 1], "contain": "all"}]},
     "children": [{"op": "box", "size": [1, 1, 0.1], "part": "panel"}]}
  ]
}
```

Limits: an edit works on the triangles it is given, so a selection can only be as fine as the mesh (give the primitive more
`segments`, or `loop_cut`, to get a face of the size you want). `extrude_faces` moves the vertices along the average of the
selected normals, so on a curved selection the walls are not exactly `distance` thick; a negative `distance` on the whole outer
surface of a solid (every top face of a box, with no inset first) leaves the old side faces in place and gives a surface that
overlaps itself: sink a region with `inset_faces` first (a rim stays). `bevel_edges` leaves flat, open or shared edges alone and says so.

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
colour, the vertices of the others are white. A `vertexColors` section colours whole parts from a palette instead, and a `texturing` section bakes the colours, textures and wear into a texture: see "Texturing".

## Texturing

A model can carry its colour in three ways, and a document may use them together:

- **Vertex colours from a palette** (`vertexColors`): no texture at all, a low-poly look. Colours are written into the mesh while the document is evaluated.
- **A baked texture** (`texturing`): the CPU paints the model's colour into the UV atlas of the `uv` section: material colours and tiling textures (projected triplanar), the vertex colours, baked ambient occlusion, wear that comes from baked curvature, thickness and occlusion, and decals. The result is a layered image document (`*.image.json`, see docs/IMAGES.md) next to the model that you can open and paint on, and its PNG is the model's texture in the `.glb` and in every LOD.
- **A texture through the primitives' uvs** (`material.texture` with the default `mapping: "uv"`, no `texturing` section): the `.glb` references the image and the game draws it. Nothing is baked.

Everything in this section is CPU, deterministic (a fixed low-discrepancy sequence for the rays, a hash of the position for the noise; no clock, no `rand()`) and needs no program besides FactorIA. `model.texture`, `model.decal`, `model.palette` and `model.bake_maps` are the commands.

### Materials with a tiling texture

A material takes the usual `color`, `texture` (a project image, for instance an `assets.generate_texture` output) and these fields for a baked texture:

| Field | Meaning |
|---|---|
| `mapping` | `"triplanar"`: the texture is projected along the three axes and blended by the surface normal, and baked into the atlas. `"uv"`: it goes through the model's uvs and the `.glb` references the image. Default: `"triplanar"` when the document has a `texturing` section, else `"uv"`. A document with `texturing` refuses `"uv"` on a material with a texture (the atlas would have two textures); remove `texturing` or use triplanar. |
| `textureScale` | Metres one repeat of the texture covers (0.001 to 1000, default 1). A texture of bricks that should be 20 cm wide gets `0.2`. Scale is in metres, so the same texture has the same size on a small part and a large one. |
| `textureOffset` | `[x, y, z]` metres the texture is shifted by. |
| `sharpness` | 1 (soft) to 16 (almost a hard edge), default 4: how fast the three projections hand over to each other where the surface turns. |
| `tint` | A colour multiplying the texture and the material colour in the bake. |

A material with no texture bakes its `color`. A triplanar texture has no seams on the model (the projection is in model space) and does not need the surface to be unwrapped well; the atlas only decides where it is stored.

### Vertex colours: `vertexColors`

```json
{"format": "factoria.model/1",
 "vertexColors": {"palette": ["#8c5a3c", "#d9c7a0", "#3f6b3a"], "flat": true, "variation": 0.06, "seed": 7,
                  "color": 1,
                  "parts": {"roof": {"color": 0}, "bush": {"gradient": {"from": 2, "to": "#a8d070", "axis": "y"}}}},
 "nodes": [ ... ]}
```

| Field | Meaning |
|---|---|
| `palette` | `"style"` (the `style.palette` of the project's `assets.json`) or a list of colours (`"#rrggbb"`, `"#rrggbbaa"` or `[r, g, b, a]` from 0 to 1). |
| `snap` | With a palette every colour moves to the nearest colour of the palette (default true). |
| `color` | The colour of the parts that have no entry: a colour, or the position (an integer) of a palette colour. |
| `parts` | By part name (`""` for nodes with no part): `color` or a `gradient` `{axis, from, to, via?, range?}` along a model axis (`range` in metres; default the part's own extent), and its own `variation`. A name that is not a part of the model is a warning. |
| `flat` | One colour per triangle: vertices are split so colours do not blend (the faceted low-poly look). The triangles keep their order and parts. |
| `variation`, `seed` | Brightness changes by up to this much (0 to 0.5) either way per triangle (flat) or vertex, chosen by a hash of the triangle and the seed. |

The colours multiply the colours the nodes already have and the material colour. They go into the `.glb` as `COLOR_0` unless the document also has a `texturing` section with `vertexColors: "bake"` (the default), when they are painted into the texture and left out of the mesh; `"keep"` leaves them on the mesh too. With `palette: "style"` the recipe records the palette, so a bake is stale when the style's palette changes. `model.palette` edits the section and returns the report (triangles coloured, distinct colours, vertices before and after) and a picture of the palette.

### The `texturing` section

```json
{"format": "factoria.model/1",
 "materials": {"wood": {"color": "#ffffff", "texture": "assets/textures/wood.png", "textureScale": 0.5}},
 "uv": {"method": "unwrap", "textureSize": 1024},
 "texturing": {"ao": true,
               "maps": {"write": ["curvature"]},
               "wear": [{"mask": "edges", "color": "#d9d2c0"}, {"mask": "cavity", "color": "#2a2018", "amount": 0.6}],
               "decals": [{"name": "label", "image": "assets/textures/label.png", "position": [0, 0.2, 0.5], "normal": "front", "size": [0.4, 0.25]}]},
 "nodes": [ ... ]}
```

The section needs a `uv` section with layout `atlas` (`model.texture` adds `{"method": "unwrap"}` when there is none and reports `uvAdded`). The whole model is stored in one atlas.

| Field | Meaning |
|---|---|
| `size` | Side of the texture, 16 to 4096. 0 (default): the size the `uv` section made the atlas for. |
| `bleed` | Texels the colours are spread beyond each piece, against seams in mipmaps (0 to 32; default the uv `padding`). |
| `vertexColors` | `"bake"` (default) or `"keep"`, see above. |
| `background` | The colour of the texels no triangle covers (default mid grey). |
| `document` | The image document the layers are written to (default `<model>.texture.image.json` next to the model). |
| `ao` | `true` or `{strength, parts}`: bake ambient occlusion and multiply it in (`strength` 0 to 1, default 0.7; `parts` darkens only those). |
| `maps` | How the maps are measured: `samples` (rays per texel, 4 to 256, default 16), `distance` (metres an occluder may be away; 0 = 15% of the model's diagonal), `thicknessDistance` (0 = 50%), `edgeAngle` (degrees, default 20), `edgeWidth` (metres of the band along an edge; 0 = 3% of the diagonal) and `write`: the maps also kept as grey PNGs next to the model (`<name>.ao.png`, `.curvature.png`, `.thickness.png`). |
| `wear` | A list of wear entries (below). |
| `decals` | A list of decals (below). |

**The maps** are grey pictures the size of the atlas. `ao`: 1 (white) is open, lower is occluded by the rest of the model. `curvature`: 0.5 is flat, lighter is a convex edge, darker a concave corner (an edge counts when the surface turns by at least `edgeAngle`). `thickness`: the distance from the surface to the inside of the opposite surface, up to `thicknessDistance`; darker is thinner, an open surface is white. `model.bake_maps` measures them without writing anything, so you can choose thresholds first.

**Wear** paints a colour over the base colour where a mask is high. Each entry: `mask` (`edges`: along convex sharp edges, for chipped paint; `cavity`: concave corners and occluded places, for dirt; `ao`: wherever there is occlusion; `thickness`: where the shell is thin), `color` (default light for edges and thickness, dark for cavity and ao), `amount` (opacity at the strongest, 0.8), `width` (metres of the band for `edges` and `cavity`; default `maps.edgeWidth`), `threshold` (the mask below this is nothing, 0.1), `noise` and `noiseScale` (how much noise, 0 to 1, breaks the mask up and how big its features are in metres), `seed`, `upBias` (-1 to 1: dust and snow on surfaces that look up, or the opposite), `parts` and a `name` for the report. All entries are composited in order into one transparent layer.

**Decals** are pictures projected on the model: `image` (a project PNG or JPG, for instance the PNG of an image document), `position` (the centre, in model space), `normal` (the way the surface it sits on faces: `[x, y, z]`, or `top`, `bottom`, `front`, `back`, `left`, `right`; the picture is projected along the opposite), `size` (metres, `[w, h]` or one number), `rotation` (degrees around the normal), `opacity`, `tint`, `depth` (how far from the plane through `position` the projection reaches, each way; 0: the smaller side of the decal), `maxAngle` (surfaces turned more than this away from `normal` are left alone, 75), `parts` and `faces` (a selection query, see "Selections and edits") to limit where it lands. Transparent pixels of the image stay transparent. `model.decal` adds, replaces and removes them one at a time. The report counts the texels each decal painted: 0 means it missed the surface.

### The texture is an image document

A bake writes the pictures next to the model and composes them in the image document (default `assets/models/crate.texture.image.json` for `crate.model.json`), bottom first:

| Layer | Content |
|---|---|
| `model: base` | The material colours, textures and (with `vertexColors: "bake"`) the vertex colours. |
| `model: decals` | The decals (only when there are some). |
| `model: wear` | The wear (only when there is some). |
| `model: occlusion` | The baked occlusion, blend mode `multiply` (only with `ao`). |
| `model: uv` | The edges of the triangles, a colour per part. Hidden. Turn it on to see where to paint. |
| `paint` | A blank layer made by the first bake, yours. |

The PNG of the document (`crate.texture.png`) is what the `.glb` uses as the base colour texture (the material colour becomes white, so the texture is not tinted twice), and so do `crate.lod1.glb` and the other LODs: the uvs of an LOD are the model's, so one picture serves all of them. The document opens in the Image panel and every `image.*` command works on it: `image.info`, `image.layer.add`, `image.paint`, `image.bake`.

**What a re-bake keeps and what it rewrites.** Every model bake rewrites the pictures of the layers named `model: ...` (their files, listed in the recipe as extras of the model) and nothing else. It keeps: every other layer, in its place, with its pixels; the `paint` layer and its `crate.paint.png`; and the settings you gave any layer, including the `model: ...` ones (opacity, blend mode, visibility, masks, position among the layers), because only the `source` of those is renewed. A layer named `model: ...` that this bake does not make (the wear removed from the document) is removed from the document. Anything you want to keep, paint on `paint` or on a layer of your own; do not paint on a `model: ...` layer, the next bake replaces its picture.

The pixels you painted are stored at the atlas positions of the moment you painted them. If a later bake changes the layout (another `uv` method, a changed density or size) they keep their pixels and no longer line up with the model; the bake warns ("The uv layout changed since the last bake..." or "The texture is NxN now...") when a layer with content is there. Settle the unwrap before you paint. Changing colours, textures, wear, decals or `ao` leaves the layout alone, so what you painted stays aligned.

`model.texture {clear: true}` removes the section. The next bake deletes the layer pictures it made (`.base.png`, `.decals.png`, ... they are extras of the model, removed with it) and the `.glb` goes back to the material colours, but the image document, its PNG and `paint.png` stay in the project: they may hold your work. Delete them by hand if you do not want them.

**Staleness.** The recipe of the model records the image document (its hash and the layers it reads), the decal images and the textures of the materials, and the style palette for `vertexColors.palette: "style"`. A change to any of them, or an image document whose picture is not current, makes the model stale for `model.info`, `project.validate` and `assets.regenerate`; the bake then renews the texture and the `.glb`.

**Cost and limits.** The occlusion and thickness maps trace `samples` rays per texel of the atlas, so the time grows with `size` squared times `samples`. Use `model.bake_maps` with a small `size` to try values, and bake at the final size once (a model is baked again whenever anything it depends on changes). The atlas holds the whole model in one picture: a model with several textures per part, or a texture per instance, is not possible. Texels that two triangles share (the `overlap` of the report, from projected parts such as `planar`) show what is painted on both. Rays see the model as built: nothing else of the scene occludes it.

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
| `collider` | `shape`: `none`, `box`, `sphere`, `capsule` (stands on Y), `convex` (hull), `decomposed` (several convex pieces of a concave model). `maxVertices` (4..256, default 32) limits each hull; `decomposed` also takes `maxHulls` (default 8) and `resolution` (voxels, default 100000). |
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
on one thread. Everything is serial, so a document gives the same LODs, hulls and bytes on every platform (the tests pin
triangle counts and hashes).

Limits: the capsule is always along Y (the report warns when the model is wider than tall); a decomposition that finds no
pieces falls back to the convex hull and says so; a LOD never removes a submesh entirely.

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
| `model.game_ready {path, origin?, merge?, lods?, collider?, platforms?, clear?, bake?}` | Sets the game-ready settings of a document (each value given replaces that setting; null removes it; `clear` removes all), then bakes the `.glb`, LODs, collider and prefab. With no setting it only reports the budget check. See Game-ready models. |
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
