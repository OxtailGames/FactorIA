# Modeling: editing, UVs and texturing

[Modeling](../MODELING.md) > Modeling: editing, UVs and texturing

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
