# Vector illustration: the `vector.*` commands

SVG is the document. You write it (`assets.rasterize_svg` draws it, see [ASSETS.md](ASSETS.md)); these commands edit it:
combine shapes, grow or shrink them, turn strokes into outlines, tidy paths, line elements up, repeat them and apply the project's
style. Each command reads an SVG, changes it, **writes it back keeping its ids, groups, transforms and styles**, and returns a
rasterized preview of the result as `$image`, so you look at the picture after every step.

```text
vector.info          list the shapes, their ids, bounds and node counts
vector.boolean       union, subtract, intersect, exclude
vector.offset        grow (offset path) or shrink (inset) a shape
vector.stroke_to_path   a stroke becomes a filled outline
vector.simplify      fewer nodes within a tolerance
vector.smooth        round corners into Bezier curves
vector.align         line elements up (selection, canvas, key element)
vector.distribute    equal gaps or equal centres along an axis
vector.repeat        copies in a grid or around a circle
vector.style         the project's style guide: outline and palette snapping
```

## Where the SVG comes from

Every command takes exactly one of:

| Argument | The SVG is | The edit goes to |
| --- | --- | --- |
| `source` | a project `.svg` file, `"assets/art/crest.svg"` | the same file, or `out` |
| `svg` | text in the call | nowhere, unless `out`; the edited text comes back in the result's `svg` |
| `document` (+ `layer`) | an `svg` layer of a `*.image.json` ([IMAGES.md](IMAGES.md)) | the layer (see below) |

`out` writes the result to another `.svg` file (an existing one needs `overwrite: true`); the source stays as it was. `dryRun: true`
computes and previews the result and writes nothing. `previewSize` (32 to 2048, default 512) is the longer side of the `$image` picture.

**A layer of an image document.** `{"document": "assets/art/hero.image.json", "layer": "crest"}`: the layer by name or index path
(`"1"`, `"1/0"`; optional when the document has exactly one svg layer). An inline layer (`svg`) has its text replaced and the document is
saved and baked like `image.layer.set` does (`bake: false` skips the bake); the result is the picture of the whole document. A layer with
`source` rewrites that `.svg` file, and the document is baked again because its recipe reads the file. Other layers are not touched.

## What is edited, and what is kept

- **The text round-trips.** Comments, whitespace, indentation, attribute order and quoting, `<defs>`, `<style>`, CDATA and everything the
  command did not change are written back byte for byte. Only the start tags of the elements that changed are rewritten.
- **A shape that is replaced keeps its identity:** a rect, circle, polygon or path that gets a new outline becomes a `<path>` in the same
  place of the document with the same `id`, `class`, `fill`, `stroke`, `style`, `transform` and every other attribute (only `d`
  changes, and `x`, `y`, `width`, `height`, `cx`, `r`, `points`... of the old shape type go).
- **Transforms are honoured.** Every shape is measured in the drawing space (the `viewBox` units) with its own `transform` and those of its
  groups. The result is mapped back into the shape's own space, so a scaled, rotated or skewed shape keeps its transform and still lands
  where the operation says. Distances (`distance`, `tolerance`, `spacing`) are in drawing units whatever the shape's transform. A shape
  whose transform scales it to nothing cannot be mapped back, and the call fails with `invalid_svg` naming it.
- **Curves come back as curves.** The operations work on the exact outline of the shape (arcs and Béziers are flattened finely), then fit
  cubic Béziers to the result again, keeping real corners sharp (`cornerAngle`, default 28 degrees of turn; `curves: false` keeps the
  polygon). A circle that is subtracted from stays a handful of Béziers, not hundreds of lines. `tolerance` is the largest distance the
  result may be from the exact outline (default: 1/4000 of the drawing's longer side, 1/500 for `vector.simplify`).
- **Atomic.** A call computes everything first and writes after. When anything fails (a missing id, an empty result, a bad argument) the
  file is exactly as it was.
- **Same call, same bytes.** The operations are deterministic.
- **Not edited:** `<text>` (it has no outline here), shapes inside `<defs>`, `<clipPath>`, `<mask>`, `<pattern>`, `<symbol>`, `<marker>`,
  and `<use>` instances (the shape they point to is). CSS rules in `<style>` are not read: `fill`, `stroke`, `stroke-width` and
  `fill-rule` come from attributes and `style="..."` (with inheritance from groups), and the result carries a warning when the SVG has
  such rules. Gradients and filters stay as they are.

## Picking elements

`elements` (or `element`, `key`) takes an SVG id, a selector, or a list of them. A group stands for the shapes in it, in document order.
Selectors: `#id`, `.class`, a tag (`path`), `[attr]`, `[attr=value]` (also `~= ^= $= *= |=`), `*`, `:first-child`, `:last-child`,
`:nth-child(2)`, compounds (`path.ring`), descendants (`g path`), children (`g > path`) and lists (`#a, .b`). A word that is an id is
an id. An id or selector that matches nothing is an error with the ids that exist and a "did you mean".

## Commands

### `vector.info`

Lists the drawable elements: `tag`, `id`, `bounds` `[x, y, w, h]` in the drawing space, `nodes`, `curves`, `closed`, `fill`, `stroke`,
`transform`; groups with the number of children. Also `canvas` (the viewBox) and `declaredSize`. Read-only. Use it first to find ids.

### `vector.boolean`

`{"source": "assets/art/badge.svg", "op": "subtract", "elements": ["disc", "hole"]}`

`op`: `union` (all merged), `subtract` (the later shapes removed from the first), `intersect` (what all cover), `exclude` (what an odd
number cover). The result is ONE `<path>` that takes the place, id, style and transform of the **first** shape; the other shapes are
removed (`keepInputs: true` keeps them). A group as an operand stands for the union of its shapes. `fill-rule` (`evenodd` or `nonzero`) is
read per shape, so a ring drawn with an even-odd hole is a ring. Needs two or more shapes; an empty result (`intersect` of shapes that do
not overlap) is an error, never an empty path. A group that is emptied stays in the document (with its id and transform). Result:
`result` (the id), `removed`, `nodes`, `nodesBefore`, `bounds`.

### `vector.offset`

`{"source": "...", "elements": ["disc"], "distance": -3, "join": "round", "copy": true}`

Moves the outline by `distance` (positive grows, negative insets). `join`: `round` (default), `miter` (sharp, up to `miterLimit` times
the distance, then bevelled), `bevel`, `square`. Holes move the opposite way, as in any offset path. Each shape keeps its id, or with
`copy: true` stays and a copy `<id>-offset` follows it. Insetting by more than the shape is thick is an `empty_result` error. Result:
`results` (`element`, `nodes`, `bounds`).

### `vector.stroke_to_path`

`{"source": "...", "elements": ["swoosh"], "cap": "round", "dashes": [6, 4]}`

Turns the stroke into a filled outline using SVG's own rules: `stroke-width`, `stroke-linecap`, `stroke-linejoin`,
`stroke-miterlimit`, `stroke-dasharray` and `stroke-dashoffset`, read with inheritance, or the overrides `width`, `cap`, `join`,
`miterLimit`, `dashes` (`[]` = solid), `dashOffset`. The width is in the shape's own units, so a scaled shape keeps its look.

- A shape with **no fill** (line art) becomes the outline: fill = its stroke colour, `stroke="none"`, same id.
- A shape with a fill keeps its fill and id; the outline is added **after** it as `<id>-stroke`.
- A shape with no stroke is skipped with a warning (`color` strokes it anyway, with `width`); when none of the shapes has a stroke the call is an
  error.

Result: `results` (`element`, `from`, `role` `stroke`, `nodes`, `bounds`).

### `vector.simplify` and `vector.smooth`

`{"source": "assets/art/tree.svg", "tolerance": 0.4}`

`vector.simplify` rewrites each picked shape (default: all) with fewer nodes. A path with curves is refitted from its outline with as few
cubic Béziers as `tolerance` allows; a path of straight lines loses every vertex within `tolerance` of the line between its neighbours.
Corners stay corners. A shape that cannot lose nodes (a `<rect>`, a `<circle>`, an already minimal path) is left as it is and listed in
`unchanged`; the call then reports `changed: false` and writes nothing. To turn a polygon into curves use `vector.smooth`.

`vector.smooth` gives every node that is not a sharp corner smooth handles, so a polygon or a rough hand-drawn path flows through the
same nodes. `smoothness` 0 to 1 (default 1); nodes that turn more than `cornerAngle` stay sharp. Curves already in the path are kept;
only its straight segments get handles. A square, whose corners all turn 90 degrees, comes back unchanged.

### `vector.align` and `vector.distribute`

`{"source": "...", "elements": ["a", "b", "c"], "vertical": "middle", "to": "key", "key": "a"}`

`vector.align`: `horizontal` (`left`, `center`, `right`) and/or `vertical` (`top`, `middle`, `bottom`), relative to `to`: `selection` (the
union of the elements' bounds, the default for two or more), `canvas` (the viewBox, the default for one element) or `key` (given with
`key`: that element stays put). `vector.distribute`: `axis` and `by` (`gaps`, default: equal gaps between edges; `centers`: equal
distance between centres), or `spacing` for a fixed gap (the first element stays and the rest follow, negative overlaps). The elements
are ordered by position and the first and last stay put; three or more are needed.

A group moves as one piece (its bounds are the union of its shapes). Bounds are `visual` by default (they include half the stroke
width) or `geometry` (`bounds`). Elements are moved with their own `transform` attribute (a `translate(...)` is added or updated), so
ids, groups, styles and the coordinates of the shapes stay as they are; the move is computed in the drawing space, so parent transforms
(a scaled group) are honoured. Result: `moved` (`element`, `dx`, `dy`, in the drawing).

### `vector.repeat`

`{"source": "...", "element": "petal", "mode": "radial", "count": 8, "center": [50, 50]}`

Adds copies of ONE element (a shape or a group). `mode: "grid"`: `columns` x `rows` (the original included) with `spacing` between the
copies' bounds (a number or `[x, y]`). `mode: "radial"`: `count` elements in total around `center` (or `radius` away from the element) over
`sweep` degrees (default 360), turned to follow the circle (`orient: false` keeps them upright). `rotation` turns each copy that many
degrees more than the last about its own centre. Angles are in degrees, clockwise on screen, 0 pointing right.

Copies are clones placed with a `transform` attribute, named `<id>-2`, `<id>-3`... (ids inside a copied group get the same suffix) and
placed right after the original in the drawing. Result: `original`, `copies`, `count`.

### `vector.style`

`{"source": "assets/art/crest.svg"}`

Applies the `style` of `assets.json` ([ASSETS.md](ASSETS.md), "House style"):

- `outline` (`color`, `width` in pixels of the SVG's *declared* size) is put on every **filled** shape as `stroke` and `stroke-width`.
  The width is converted to viewBox units (`width="200"` over `viewBox="0 0 100 100"`: a 2 px outline is 1 unit) and divided by the
  shape's own scale, so the line is the same width on screen. Line art (no fill) already has its strokes and is skipped
  (`outlineSkippedNoFill`).
- `palette` snaps every `fill`, `stroke` and gradient `stop-color` to the nearest colour of `style.palette` (nearest in RGB; alpha is
  kept). `url(...)`, `none` and `currentColor` are left alone. Result: `recoloured` and the first `colours` mapped.

With neither argument both are applied, whichever the guide defines. One asked for alone applies only that one (`{"outline": true}`);
one switched off alone applies the other (`{"outline": false}`). Give values instead of `true` to override the guide:
`{"outline": {"width": 2, "color": "#101018"}}`, `{"palette": ["#101018", "#e8e0d0"]}`. `elements` limits it to some shapes (default:
the whole drawing). A guide with neither an outline nor a palette is an error that says how to add them.

## Errors

Every error names the argument (a JSON pointer such as `/elements/1`), what is wrong and how to fix it:

| Code | When |
| --- | --- |
| `invalid_svg` | the SVG is not well-formed XML or has no `<svg>` root (line and column named), or a shape cannot be used: path data with a mistake, a transform that scales it to nothing |
| `not_found` | an id or selector matches nothing, or the `source`/`document` does not exist; lists the ids and suggests the closest |
| `invalid_argument` | a wrong, missing or unknown argument (an unknown name gets a "did you mean"), one shape for a boolean, `vector.stroke_to_path` on shapes with no stroke, an `align` with nothing to do |
| `empty_result` | the operation leaves nothing (the shapes do not overlap, an inset removed the shape) |
| `exists` | `out` exists and `overwrite` is not true |

## A workflow

1. `assets.rasterize_svg` or `vector.info` to see what there is.
2. Combine: `vector.boolean` a shield from a circle and a rectangle, `vector.offset` an inset copy for the inner line (`copy: true`).
3. `vector.stroke_to_path` the line art so its width scales with the shape; `vector.simplify` the result.
4. `vector.align` / `vector.distribute` / `vector.repeat` the parts into a layout; `vector.style` last, so the outline and palette are the
   project's.
5. Look at each `$image`; `assets.rasterize_svg` the final `.svg` to its PNG (or keep it as an svg layer of a `*.image.json`), then
   `assets.check_art` it.

## For code that builds on this

The operations live in `tools/common/src/vector_*.cpp` (`vector_svg.h`: the round-tripping SVG tree, selectors and styles; `vector.h`:
paths, the Clipper2 clipping on an integer grid, the stroker and the Bézier fitting; `vector_ops.h`: one function per command that edits
an `SvgDoc`). Clipping and offsetting use [Clipper2](https://github.com/AngusJohnson/Clipper2) (`external/clipper2`, Boost license).
