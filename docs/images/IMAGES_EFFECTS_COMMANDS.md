# Images: effects, baking and commands

[Images](../IMAGES.md) > Images: effects, baking and commands

## Adjustments and effects

`adjustments` change colours and keep alpha; `effects` may change the footprint of a layer (a shadow or an outline makes it
bigger). For one layer the order is: content -> adjustments -> masks -> effects -> clipping -> opacity -> blend onto the
canvas at `x`, `y`. Each entry is `{"type": name, ...fields}`. An `adjustment` layer applies its adjustments to the canvas
below it and mixes the result in by its masks, clipping and opacity.

An unknown `type` or key, or a value out of range, is an error with the pointer, a "did you mean" and the operation's
description; `fa::image_adjustment_types()` and `fa::image_effect_types()` return every operation with that description.
Everything is CPU, in float, deterministic (no random numbers: `noise` hashes its seed and the pixel) and works on the stored
(sRGB-encoded) values. The blurs are separable; a 1024 x 1024 layer with three adjustments and four effects took about six seconds
in a Debug build. Pixels with alpha 0 are left alone by the adjustments that quantize or dither.

### Adjustments (colour only, alpha stays; also in `adjustment` layers)

| `type` | Keys (defaults) | What it does |
|---|---|---|
| `invert` | | 1 - colour |
| `brightness` | `amount` -1..1 (0.2) | added to red, green and blue |
| `levels` | `inBlack` 0 / `inWhite` 1, `gamma` 0.1..10 (1), `outBlack` 0 / `outWhite` 1, `channel` rgb, red, green, blue | stretch input black..white to 0..1, `pow(v, 1/gamma)`, map to the output range; `inBlack` must be below `inWhite` |
| `curves` | `points` [[x, y], ...] (2-32, x increasing, 0..1), `channel` | a monotone cubic through the points (Fritsch-Carlson: never overshoots between points; flat outside the first and last) |
| `hsv` | `hue` degrees -180..180, `saturation` -1..1, `value` -1..1, `colorize` | turn the hue; saturation x (1 + `saturation`); value + `value`. With `colorize: true` the pixel gets hue `hue` (0..360) and saturation `saturation` (0..1, default 0.5) and keeps its Rec. 709 luma + `value` |
| `posterize` | `levels` 2..256 (4) | each channel rounded to `levels` evenly spaced values |
| `quantize` | `palette` "style" or [colours] ("style"), `space` oklab or rgb (oklab), `dither` (none), `strength` 0..1 (1) | every pixel takes the nearest palette colour |
| `dither` | `method` none, bayer2, bayer4, bayer8, floydSteinberg, atkinson (bayer4), `levels` 2..256 (2), `palette`, `space`, `strength` | reduces the colours with a dither: to `palette` when given, else to `levels` values per channel |
| `gradientMap` | `stops` [{`at`, `color`}] (2-64, `at` not decreasing) | the colour of the gradient at the pixel's Rec. 709 luma |
| `colorBalance` | `shadows`, `midtones`, `highlights`: [r, g, b] each -1..1 | adds 0.5 x weight x shift; weights from the luma l: shadows (1-l)^2, highlights l^2, midtones 4l(1-l) |
| `threshold` | `level` 0..1 (0.5), `above` (white), `below` (black) | luma at or above `level` becomes `above` |

`palette: "style"` is `style.palette` of `assets.json` ([ASSETS.md](../ASSETS.md)); with no style palette the render fails
saying so. "Nearest colour" is the smallest Euclidean distance in **OKLab** (a perceptual space) by default, or in the stored RGB
values with `space: "rgb"`; a tie takes the earlier palette entry. Ordered dithers add a Bayer threshold (tiled over the
layer's own pixels, so it moves with the layer's content, not with the canvas) scaled by the palette's spacing before choosing
the nearest colour; error diffusion goes left to right, top to bottom and only passes error to visible pixels (no serpentine, so
the result does not depend on direction tricks). `quantize` with a `dither` equals `dither` with the same palette.

```json
"adjustments": [
  {"type": "levels", "inBlack": 0.1, "inWhite": 0.9, "gamma": 1.2},
  {"type": "hsv", "hue": 15, "saturation": -0.1},
  {"type": "quantize", "palette": "style", "dither": "bayer4"}
]
```

### Effects (after the masks; may grow the layer, which keeps its pixels in place)

| `type` | Keys (defaults) | What it does |
|---|---|---|
| `colorOverlay` | `color`, `amount` 0..1 (1) | mixes the colour towards `color`, alpha stays |
| `outline` | `color` (black), `width` 0.5..64 (1), `position` outside, inside, center (outside), `smooth` (false) | a line around the alpha shape (a pixel is "in" when alpha > 0.5) |
| `stroke` | the same | like `outline` with `position` center by default |
| `dropShadow` | `offsetX`, `offsetY` -512..512 (2, 2), `blur` 0..64 (2), `color` (black), `opacity` 0..1 (0.5) | the shape moved by the offset, blurred (Gaussian sigma `blur` / 2), behind the layer |
| `outerGlow` | `color` (white), `size` 0..64 (4), `strength` 0..8 (1), `opacity` 0..1 (1) | the alpha blurred (sigma `size` / 2) x `strength`, behind the layer |
| `innerGlow` | the same | the same from the transparency around the layer, mixed into the layer's colour inside the edge; alpha stays |
| `blur` | `mode` gaussian, box (gaussian), `radius` 0..64 (2) | Gaussian: `radius` is sigma. Box: `radius` is the half-width (window 2r + 1, whole pixels). Colour is weighted by alpha, so an edge does not darken |
| `sharpen` | `radius` 0.1..32 (1), `amount` 0..10 (1), `threshold` 0..1 (0) | unsharp mask: colour + `amount` x (colour - blurred), where the difference reaches `threshold` |
| `noise` | `amount` 0..1 (0.1), `seed` (0), `mode` mono, color (mono) | adds uniform noise in -`amount`..`amount` to visible pixels; the value depends only on the seed and the pixel position |
| `shade` | `normalMap`, `flipGreen`, `smooth` 0..16 (1), `strength` 0..32 (3), `lightDirection`, `elevation` 1..90 (45), `intensity` 0..4 (1), `amount` 0..1 (1) | lights the layer from a normal map, or from its alpha as a height map |

- **Outline and stroke** use the exact Euclidean distance to the shape: a pixel gets the stroke when its centre is within `width`
  of the shape (outside) or of the outside (inside). Width 1 is therefore the 4-connected outline of pixel art (no diagonal
  corner pixels; width 2 adds them), with no anti-aliasing. `smooth: true` gives the stroke edge a one-pixel ramp instead. `center`
  puts `ceil(width / 2)` outside and the rest inside. An outside stroke is drawn behind the layer, an inside one over its edge.
- **shade** multiplies the colour by `1 + 2 intensity (n.L - L.z)`: a flat surface (n.L = L.z) keeps its colour, surfaces
  tilted towards the light get brighter and away from it darker. `normalMap` is a tangent-space PNG of the project with green up
  (OpenGL; `flipGreen` for DirectX), read at the layer's own pixels (flat outside it or where it is transparent). Without it the
  height map is the layer's alpha blurred by `smooth`, with slopes scaled by `strength`, so the edges of a shape bulge. The light
  comes from `lightDirection` (degrees counter-clockwise from +x; 90 is up), by default the project's `style.lightDirection`
  ([ASSETS.md](../ASSETS.md)), else 135 (upper left).
- A blur, shadow or glow grows the layer by what it needs; effects run in order, each on the result of the one before.

```json
"effects": [
  {"type": "outline", "color": "#1a1c2c", "width": 1},
  {"type": "dropShadow", "offsetX": 2, "offsetY": 2, "blur": 3, "opacity": 0.4},
  {"type": "shade", "strength": 4}
]
```

## Baking, provenance and staleness

`bake_image_document` (and `image.bake`) composites the document and writes the PNG, then records in `assets.json`, for the
PNG, a `provenance` (`origin`, `ai`, `kind: "image"`, `provider: "factoria image.bake"`, `license`, `author`, `source` the
document, `notes`, `date`) and the **recipe** `{command: "image.bake", args: {path}, inputs: the document and every file a layer
reads, each with its sha256}` ([ASSETS.md](../ASSETS.md), "Recipes: make an asset again"). So:

- `assets.regenerate {"path": "assets/art/hero.png"}` bakes it again; `{"stale": true}` bakes every picture whose document or
  source files changed.
- `factoria validate` warns about a stale bake with the exact command, like for any made asset.
- `ai` is `true` when the document has a `provider` layer or any file a layer reads is recorded as AI-made in `assets.json`
  (store disclosure, [ASSETS.md](../ASSETS.md) "Provenance and store disclosure"). A `license` and `author` a person recorded for
  the PNG are kept; otherwise the license is that of the inputs, or `CC0-1.0`.
- The PNG is not rewritten when its bytes would not change.

A document with `frames` or `tags` bakes a sprite sheet and its clips instead (see "Frames and tags"); the recipe and the staleness
rules are the same.

A baked PNG is a normal project asset: put it in a `Sprite`, an atlas group, an animation. Edit the document, never the PNG
(the next bake would replace your edit).

## Commands

Every command below edits the document (or a layer's PNG) and bakes it, and every result returns the baked picture as `$image`
and the box that changed, `region` `{x, y, width, height}` (with `changed: false` and a warning when nothing visible changed).
A layer is addressed by its **name** or by its **index path**: `"1"` is the second layer from the bottom, `"1/0"` the first
child of the group at 1. A wrong name or index is an error with "did you mean" and the list of layers.

- `image.bake {path, onlyIfNeeded?}`: bakes the document at `path`. `onlyIfNeeded` does nothing when the PNG is current (the
  recipe matches the document and every file it reads). Returns `{document, path, width, height, written, ai, sha256,
  inputs, provenance, warnings, $image, nextSteps}`.
- `image.save {path, document, bake?}`: checks `document` (the JSON of a layered image), writes it to `path` as canonical JSON
  (2-space indent) and bakes it. A document with a problem is an error and nothing is written.
- `image.tile.set`, `image.tile.check`, `image.tileset.build`, `image.tileset.info`, `image.tileset.check`,
  `image.tileset.rules`: tile mode, the seam check and the autotile generator (see "Tiles").
- `image.inpaint`, `image.generate_layer`, `image.layer.add_provider`: pictures from an image provider as layers (see "Pictures from a provider").

### Resizing the canvas: `image.resize`

`image.resize {path, width, height, anchor?, fill?}` changes the canvas of a document (1 to 4096 each) without redrawing it. `anchor`
is the part of the old canvas that stays where it is: `top-left`, `top`, `top-right`, `left`, `center` (the default), `right`,
`bottom-left`, `bottom` or `bottom-right`. With `top-left` a bigger canvas grows at the right and bottom and a smaller one is cropped
there; with `center` every side moves (an odd difference puts the extra pixel at the right/bottom). Every top-level layer moves by
that offset (a group takes its children along); a fill, gradient or procedural layer with no size just covers the new canvas, unless
it has `masks`: masks are in the layer's own pixels, so (when the offset is not 0, 0) the layer becomes a box of the OLD canvas size
(`width` / `height`, or the `texture` size) and moves with the anchor like any other layer, and it no longer covers the area a bigger
canvas adds (the result's `warnings` name each layer that became a box). An `adjustment` layer with masks moves too (its masks go with it); one without masks needs no move. An `indexed` layer cannot have masks (the document is refused), so cropping its rows at the left or top never leaves a mask behind. The text rows of an
`indexed` layer and of its cels are CUT to the part inside the new canvas, never padded (each keeps its place through its `x` / `y`, a
picture wholly outside becomes one transparent pixel), so a small pixel-art layer on a 4096 x 4096 canvas stays small; a resize that
would keep more than 64 MB of rows fails and changes nothing. Positions are clamped to the +-100000 a document allows. `palette`, `ramps`,
frames, tags and `sheet` settings are kept, and the baked sheet takes the new cell size. `fill` paints the area a bigger canvas adds
(a masked layer named `resize fill` at the bottom); without it the new area shows the document's `background` or is transparent.
The result has `resized` `{from, to, anchor, offset, filled}` and `warnings` for what cannot follow (stored selections, which must
be made again; tile mode; linked cels). In the Image panel's toolbar the canvas size button (`16x16`) opens the Resize popup, which runs the same command as ONE undo step (its Resize button is disabled while the size is the current one). Wrong sizes
and unknown anchors are errors with the JSON pointer and a "did you mean".

### Make, look at, export

```json
{"command": "image.create", "args": {"path": "assets/art/hero.image.json", "width": 64, "height": 64,
  "layers": [{"kind": "fill", "name": "sky", "color": "#203040"}]}}
{"command": "image.info", "args": {"path": "assets/art/hero.image.json"}}
{"command": "image.export", "args": {"path": "assets/art/hero.image.json", "out": "assets/art/hero-x4.png", "scale": 4, "filter": "nearest"}}
```

- `image.create {path, width, height, background?, layers?, description?, output?, overwrite?}` writes a new document (it
  refuses to replace one unless `overwrite`). `output` is the project-relative `.png` the document bakes to (the document's
  `output` field, checked like the other path arguments); without it the PNG goes next to the document. An `output` over a PNG that
  already exists (an imported one, say) is replaced by the bake without asking for `overwrite`. The file's `assets.json` record keeps
  its `origin` "imported" with its `source` and `notes` when it had them, and its `license`, `author` and `role`; the `recipe`
  (`image.bake`), `date`, `provider`, `kind`, `ai` and `sheet` are replaced, and its `analysis` is removed.
- `image.info {path}` lists the layers as a tree (index path, name, kind, size, source, number of masks, adjustments and
  effects), whether the document is valid, its palette (source, number of colours and ramps) when it has one, its bake status,
  the files it reads and its stored selections. Read-only.
- `image.export {path, out, scale?, layer?, trim?, filter?}` writes a plain PNG copy: the whole picture, or one layer or group
  (at full opacity, normal blend). `scale` resamples with `nearest` (the default when `style.pixelArt` is true) or `bilinear`.

### Layers

```json
{"command": "image.layer.add", "args": {"path": "assets/art/hero.image.json", "layer": {"kind": "text", "text": "Hi", "size": 16, "x": 4, "y": 4}}}
{"command": "image.layer.set", "args": {"path": "assets/art/hero.image.json", "layer": "shadow", "set": {"opacity": 0.4, "blend": "multiply"}}}
{"command": "image.layer.move", "args": {"path": "assets/art/hero.image.json", "layer": "glow", "index": 0}}
{"command": "image.layer.remove", "args": {"path": "assets/art/hero.image.json", "layer": "1/0"}}
```

`image.layer.add {path, layer, parent?, index?}` puts the layer on top (or at `index`, 0 = the bottom, or into the group
`parent`); `image.layer.set {path, layer, set}` merges fields (`null` removes one; the `kind` cannot change);
`image.layer.move {path, layer, index?, parent?}` (`parent: ""` is the top level); `image.layer.remove {path, layer}`.
Layer names must be distinct, because names address layers. Nothing is written when the document would have a problem.

### Selections: `image.select`

A selection is a coverage (0 to 255) for every pixel of the canvas. It is **stored by name**, as a grey PNG (white = selected)
in `.factoria/selections/<document path>/<name>.png`, so it survives between calls and sessions until you replace or clear it.
`image.edit` and `image.paint` use it by name; the name `all` is the whole canvas and needs no file. A selection made for another
canvas size is refused with a message that says so.

In an animated document `image.select` takes **`frame`** (default 0) like the editing commands: a colour, alpha or layer
selection reads the picture of that frame (a layer selection, that layer's cel in it). The stored selection is still one mask of
the canvas per document and name, the same for every frame: select on the frame where the shape is, then edit any frame inside it.

```json
{"command": "image.select", "args": {"path": "assets/art/hero.image.json", "name": "cape", "by": "color", "at": [20, 30],
  "contiguous": true, "tolerance": 20, "then": [{"grow": 1}, {"feather": 1}]}}
{"command": "image.select", "args": {"path": "assets/art/hero.image.json", "name": "cape", "mode": "subtract", "by": "rect", "x": 0, "y": 0, "width": 32, "height": 8}}
{"command": "image.select", "args": {"path": "assets/art/hero.image.json", "name": "cape", "then": [{"invert": true}]}}
```

- `by`: `color` (within `tolerance` 0..255 of `color`, or of the pixel at `at`; `contiguous` selects only the connected area
  around `at`), `alpha` (alpha at least `threshold`), `rect` and `ellipse` (`x, y, width, height`, anti-aliased), `polygon`
  (`points`), `layer` (the shape of `layer`: its alpha after masks and effects) or `all`. `color` and `alpha` read the flattened
  picture, or only `layer` when given.
- `then` reshapes the new selection in order: `{"grow": px}`, `{"shrink": px}` (round brush, hard edge), `{"feather": px}`
  (blur of sigma px/2), `{"invert": true}`.
- `mode` combines it with the stored selection of the same `name`: `replace` (default), `add`, `subtract`, `intersect`.
  Without `by`, `then` reshapes the stored selection; `clear: true` deletes it.
- The result has `selected` (pixels at 50% coverage or more), the box as `region` and the picture with the selection marked
  (unselected part dimmed, edge outlined) as `$image`.

### Editing pixels: `image.edit`

```json
{"command": "image.edit", "args": {"path": "assets/art/hero.image.json", "selection": "cape", "layer": "hero",
  "action": {"type": "recolor", "hueShift": 120}}}
{"command": "image.edit", "args": {"path": "assets/art/hero.image.json", "selection": "cape", "layer": "hero",
  "action": {"type": "transform", "scale": 2, "rotate": 15, "filter": "nearest"}}}
{"command": "image.edit", "args": {"path": "assets/art/hero.image.json", "selection": "cape", "layer": "hero",
  "action": {"type": "cut"}, "name": "cape layer"}}
```

`action.type` is one of: `fill {color, opacity?}`; `recolor {hueShift, saturation, value}` (degrees and -1..1) or
`{from, to, tolerance?, keepShading?}`; `move {dx, dy, copy?, moveSelection?}` (whole pixels; the stored selection moves along
unless `moveSelection` is false); `transform {scale, rotate, flipH, flipV, filter?, pivot?}` (the selected pixels are lifted,
transformed around `pivot`, default their middle, and put back; `scale` is a number or `[sx, sy]`, `rotate` is degrees
clockwise; the default `filter` is `nearest` when `style.pixelArt` is true, else `bilinear`); `delete`; `copy` and `cut`
(the selected pixels become a new pixels layer above `layer`, called `name`; `cut` also clears them).

**Policy for layers that are not pixels layers.** A `pixels` layer's PNG is edited in place. Any other layer (fill,
gradient, text, svg, procedural, provider) is **rasterized**: it becomes a `pixels` layer with a new PNG in
`<document>.layers/`, its masks, adjustments and effects now part of the pixels, its blend, opacity, clip and visibility
kept, and the result carries a warning. Groups and adjustment layers cannot be edited this way (the error says which layer
to pick). A layer that has masks keeps its box (the masks are in its own pixels), so pixels moved out of it are dropped
and a warning counts them; any other layer grows to the canvas to hold what you move in. A provider (AI-made) layer stays
recorded as AI-made. Undo is your version control: the PNG of a pixels layer changes in place.

### Painting: `image.paint`

```json
{"command": "image.paint", "args": {"path": "assets/art/hero.image.json", "layer": "ink", "create": true,
  "strokes": [{"points": [[4, 4], [40, 20], [12, 30]], "size": 3, "hardness": 0.8, "color": "#ff0000", "opacity": 0.9}]}}
```

Each stroke stamps a round brush of diameter `size` along the polyline: at the first point, then every `spacing` pixels of
arc length (default a fifth of the size, at least 1), and at the last point. A pixel keeps the largest coverage any stamp gives
it, so a stroke does not darken where it crosses itself; then `opacity` scales the stroke. `hardness` 1 is a hard edge (half a
pixel anti-aliased), lower values fade from `hardness * radius` to the edge. `erase: true` lowers the alpha instead. Strokes
apply in order and the same input always gives the same pixels. `create: true` makes an empty pixels layer (at the top) when
no layer has that name; `selection` limits where the strokes paint; a layer that is not a pixels layer is rasterized as in
`image.edit`.
