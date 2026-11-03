# Vector illustration: the `vector.*` commands

SVG is the document. You write it (`assets.rasterize_svg` draws it, see [ASSETS.md](ASSETS.md)); these commands edit it:
combine shapes, grow or shrink them, turn strokes into outlines, tidy paths, line elements up, repeat them and apply the project's
style. A second group **builds** shapes the way AIs draw badly by hand (stars, gears, speech bubbles, smooth blobs, mirrored halves, text as
outlines, shading from the light). Each command reads an SVG, changes it, **writes it back keeping its ids, groups, transforms and styles**, and returns a
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
vector.shape         add a star, gear, rounded polygon, arrow, speech bubble or ribbon
vector.blob          add a smooth blob or curve through or around a few points
vector.mirror        mirror a shape across an axis and weld the halves (or add the copy)
vector.text_to_path  text as path outlines, with the engine's own fonts
vector.shade         shadow and highlight bands from the light direction
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

## Building shapes

These commands **insert** new elements (or, for `vector.mirror`, `vector.text_to_path` with `elements` and `vector.shade`, rework existing
ones) with exact geometry. They take the same `source` / `svg` / `document` + `layer`, `dryRun`, `out`, `overwrite`, `tolerance`,
`decimals` and `previewSize` as the commands above and return the preview as `$image`. Names: `shape` builds a *named* form
(`kind`), `blob` a free-form one, `mirror` and `shade` act on shapes that exist, `text_to_path` says what happens to the text.

### Placement arguments

`vector.shape`, `vector.blob` and `vector.text_to_path` (with `text`) share these:

| Argument | Meaning |
| --- | --- |
| `id` | the new element's id (default: the kind, `star`, `blob`, `text`; a taken name gets `-2`, `-3`...). An id the SVG already has is an `exists` error |
| `parent` | ONE group (`<g>`) to put it in, at the end of the group. Coordinates are then **the group's own**, so a translated or scaled group moves and scales the shape |
| `before` | ONE element it goes in front of in the drawing order (in the same group) |
| `transform` | a `transform` attribute for the new element |
| `fill`, `stroke`, `strokeWidth`, `opacity` | the style. Default: a blue fill and no stroke for closed shapes; no fill and a dark stroke 1% of the drawing's longer side wide for open curves |
| `attributes` | any other attributes: `{"class": "body", "stroke-linejoin": "round"}` |

Positions and sizes are in the parent's coordinates (the `viewBox` at the top level). Anything left out defaults to a good size in the middle
of the drawing, so `{"kind": "star"}` works on its own. Angles are degrees, clockwise on screen, 0 pointing right, **-90 up**.

### `vector.shape`

`{"source": "assets/art/badge.svg", "kind": "star", "points": 6, "innerRatio": 0.45, "roundness": 0.3, "fill": "#f2c14e"}`

| `kind` | Arguments (defaults) |
| --- | --- |
| `star` | `center`, `radius` (to the tips), `points` 3-128 (5), `innerRatio` 0.02-0.98 (0.5: the valleys' radius over the tips'), `roundness` 0-1 (0), `rotation` (-90) |
| `gear` | `center`, `radius` (to the tooth tips), `teeth` 3-128 (8), `depth` (0.2 of the radius), `toothWidth` (0.5 of the pitch), `hole` (0.3 of the radius, 0 for none, a second sub-path), `rotation` |
| `polygon` | `center`, `radius` (to the corners), `sides` 3-128 (6), `cornerRadius` (0; a true circular fillet in the parent's units, cut down where the sides are too short), `rotation` |
| `arrow` | `from` (the tail), `to` (the tip), `shaftWidth`, `headLength`, `headWidth`, `curve` -0.5..0.5 (0 straight; the bend as a fraction of the length, positive to the right of `from` -> `to`, curves are Béziers) |
| `bubble` | `center`, `width`, `height`, `cornerRadius`, `tail` (false for none), `tailTo` (the tip, **outside** the box: the tail grows from the nearest side and points at it), `tailWidth`, `tailRoundness` 0 sharp .. 1 round |
| `ribbon` | `center`, `width`, `height` (the front band), `extent` (how far the tails stick out), `drop` (how much lower they sit, also the fold size), `notch` (V cut in the ends, 0 for straight), `foldFill` |

An argument that belongs to another kind (`teeth` on a star) is an error naming the arguments of the kind you asked for. A `bubble` whose
`tailTo` is inside the box is an error too. A `ribbon` is a `<g>` of five paths (`<id>-tail-left`, `-tail-right`, `-fold-left`, `-fold-right`,
`-band`); the band takes `fill`, the folds are a darker OKLab shade of it unless `foldFill` is given.

Result (a star, from a real run): `{"element": "badge-star", "nodes": 24, "curves": true, "bounds": [17.518, 12.721, 64.965, 74.559], "parent": "svg", "kind": "star", "points": 6, "changed": true}`.
A speech bubble pointing at `[30, 92]` in a 100 x 100 drawing: `{"kind": "bubble", "tailTo": [30, 92], "id": "say"}` gives
`<path id="say" d="M25 28 L75 28 C81.075 28 86 32.925 86 39 ... L33.815 82.694 C32.606 85.643 28.334 85.335 27.561 82.243 L25.875 75.499 ..." fill="#6d9eeb"/>`:
the tail leaves the bottom side and its rounded tip reaches y = 84.7.

### `vector.blob`

`{"source": "assets/art/cloud.svg", "points": [[20,50],[50,20],[80,50],[50,80]], "fill": "#e8eef7"}`

A smooth closed shape from a few `points` ([x, y] each, 3 or more), or with `closed: false` an open curve (2 or more; a stroke and no fill by default).

- `fit: "through"` (default): the curve passes **through** every point, as a cardinal spline. `tension` 0 is straight lines, 0.5 (default) the usual
  smooth curve, up to 1.5 loose and overshooting.
- `fit: "around"`: the points are a **control polygon**; the curve is a uniform cubic B-spline that stays inside it and never touches it, and is
  smooth at every point. `tension` does not apply (a warning says so).

The four points above give `<path id="cloud" d="M20 50 C20 40 40 20 50 20 C60 20 80 40 80 50 C80 60 60 80 50 80 C40 80 20 60 20 50 Z" .../>`.

### `vector.mirror`

`{"source": "assets/art/face.svg", "elements": ["half"], "axis": "vertical", "at": 50}`

Reflects each picked shape across the line `x = at` (`axis: "vertical"`) or `y = at` (`"horizontal"`). `at` is a number in the drawing's
coordinates, `"canvas"` (default: the drawing's middle line) or `"start"` / `"end"` (the shape's own left or top / right or bottom edge).

- `weld: true` (default): the shape and its reflection are **united into one path** that keeps the shape's id, style and group, so you draw
  half a face, a wing or a vase and get the whole. Points within `snap` of the axis (default twice the tolerance) are put on it first, so the halves
  meet without a hairline. Open lines cannot be welded: they get the copy.
- `weld: false`: the mirrored copy is added after the original as `<id>-mirror`, with the exact curves (no recomputing).

From a real run, `<path id="half" d="M50 10 L80 30 L70 90 L50 90 Z"/>` mirrored at 50 becomes `<path id="half" d="M80 30 L70 90 L30 90 L20 30 L50 10 L80 30 Z"/>`
(bounds `[20, 10, 60, 80]`); the seam has no node left. Transforms are honoured.

### `vector.text_to_path`

`{"source": "assets/art/title.svg", "text": "LEVEL 3", "font": "builtin:display", "size": 24, "at": [50, 40], "anchor": "middle"}`

Text becomes **one `<path>`** (fill rule nonzero), so the picture needs no font installed. It uses the engine's own text stack: HarfBuzz shaping
(kerning, ligatures, joining scripts such as Arabic, right-to-left), the built-in DejaVu Sans (`font` omitted or `"builtin"`) and families
`builtin:serif`, `builtin:hand`, `builtin:display`, `builtin:blackletter`, `builtin:pixel`, or a project `.ttf` / `.otf`. A character the font lacks is
drawn from DejaVu Sans, or left out with a warning.

- With `text`: `size` is the em height in the parent's units, `at` the point of the first baseline selected by `anchor` (`start`, `middle`, `end`;
  default: centred in the drawing), `letterSpacing` in ems, `lineSpacing` a multiplier (a `\n` starts a line). Result: `advance` (the widest line,
  in the parent's units), `lines`, `glyphs`, `lineHeight`.
- With `elements`: each `<text>` of the drawing becomes a path **in the same place**, keeping its id, class, fill and transform; position, `font-size` and
  `text-anchor` are read from it. Pass `font` since an SVG family name cannot be looked up.

`{"text": "GO", "size": 40, "at": [50, 65], "anchor": "middle"}` gives `advance` 62.48, 2 glyphs, bounds `[21.006, 35.313, 57.988, 30.254]`.

### `vector.shade`

`{"source": "assets/art/orb.svg", "elements": ["orb"], "light": "upper-left", "depth": 8}`

For each solid shape adds two bands right after it, with its transform: `<id>-shadow` (the part of the shape on the side **away** from the light) and
`<id>-highlight` (the part on the light's side). Both are the shape minus itself pushed along the light by `depth` (the shadow) or against it by
`highlightDepth` (default 60% of `depth`; `depth` defaults to 10% of the shape's smaller side), so they never leave the shape. `shadow: false` or
`highlight: false` builds one. A shape without a solid fill needs `shadowColour` / `highlightColour`.

- **Light.** `light` is the direction **towards the light**, in degrees counter-clockwise from the right with y up (the same as the style guide's
  `lightDirection`): 90 from above, 135 upper-left, 0 from the right; or a name (`upper-left`, `top`...). Default: the style guide's `lightDirection` (docs/ASSETS.md,
  "House style"), and 135 if the project sets none; the result says which one was used (`light.from`: `argument`, `style` or `default`).
- **Colours.** If the fill is a colour of the style palette (`assets.json` `style.palette`), the bands use the next darker and next lighter colours of
  the palette (its colour ramp when one is declared). Otherwise the fill is shifted in OKLab by `strength` (default 0.12) and a warning says the
  fill was not in the palette. `shadowColour` / `highlightColour` set them, `shadowOpacity` / `highlightOpacity` fade them. Each band reports
  `colourFrom`: `palette ramp`, `palette`, `oklab` or `argument`.

On a red disc (`#cc3333`) lit from the upper left: `orb-shadow` is `#a70000` along the lower right, `orb-highlight` `#f1645d` along the upper left.

## Errors

Every error names the argument (a JSON pointer such as `/elements/1`), what is wrong and how to fix it:

| Code | When |
| --- | --- |
| `invalid_svg` | the SVG is not well-formed XML or has no `<svg>` root (line and column named), or a shape cannot be used: path data with a mistake, a transform that scales it to nothing |
| `not_found` | an id or selector matches nothing, or the `source`/`document` does not exist; lists the ids and suggests the closest |
| `invalid_argument` | a wrong, missing or unknown argument (an unknown name gets a "did you mean"), one shape for a boolean, `vector.stroke_to_path` on shapes with no stroke, an `align` with nothing to do |
| `empty_result` | the operation leaves nothing (the shapes do not overlap, an inset removed the shape) |
| `exists` | `out` exists and `overwrite` is not true, or the `id` of a shape to add is already in the SVG |

## A workflow

1. `assets.rasterize_svg` or `vector.info` to see what there is.
2. Combine: `vector.boolean` a shield from a circle and a rectangle, `vector.offset` an inset copy for the inner line (`copy: true`).
3. `vector.stroke_to_path` the line art so its width scales with the shape; `vector.simplify` the result.
4. Build the parts you would draw badly by hand: `vector.shape` (a gear, a star, a bubble), `vector.blob` (a cloud), `vector.mirror` (half a
   face), `vector.text_to_path` (a title); then `vector.shade` them from the style's light. `vector.align` / `vector.distribute` /
   `vector.repeat` the parts into a layout; `vector.style` last, so the outline and palette are the project's.
5. Look at each `$image`; `assets.rasterize_svg` the final `.svg` to its PNG (or keep it as an svg layer of a `*.image.json`), then
   `assets.check_art` it.

## For code that builds on this

The operations live in `tools/common/src/vector_*.cpp` (`vector_svg.h`: the round-tripping SVG tree, selectors and styles; `vector.h`:
paths, the Clipper2 clipping on an integer grid, the stroker and the Bézier fitting; `vector_ops.h`: one function per command that edits
an `SvgDoc`; `vector_shapes.h`: the shape geometry). The shapes are also available without a command in `fa/tooling/vector.h`
(`vector_star_path`, `vector_gear_path`, `vector_polygon_path`, `vector_arrow_path`, `vector_bubble_path`, `vector_ribbon_paths`,
`vector_blob_path`, `vector_text_path`), each returning the `d` of a path (y down, angles clockwise on screen); text outlines come from
`outline_text` in `fa/render/fonts.h`. Clipping and offsetting use [Clipper2](https://github.com/AngusJohnson/Clipper2) (`external/clipper2`, Boost license).
