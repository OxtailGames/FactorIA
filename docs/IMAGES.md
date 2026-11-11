# Layered images: `*.image.json`

A layered image is a small JSON file that is the SOURCE of a picture: a canvas and a list of layers (a PNG, a fill, a
gradient, a procedural texture, an SVG, text, a picture from an image provider, a group, an adjustment, indexed pixel art), each with an
opacity, a blend mode, masks, clipping and an offset. The PNG a `Sprite` draws is BAKED from it next to the document
(`hero.image.json` -> `hero.png`), the way the other offline makers write their files ([ASSETS.md](ASSETS.md)). You change the
picture by changing the document and baking again; nothing needs a GPU, a window or another program.

```json
{
  "format": "factoria.image/1",
  "width": 128,
  "height": 128,
  "background": "#101820",
  "layers": [
    {"kind": "gradient", "gradient": {"type": "linear", "angle": 0,
      "stops": [{"at": 0, "color": "#203a5c"}, {"at": 1, "color": "#e08040"}]}},
    {"kind": "procedural", "blend": "overlay", "opacity": 0.5, "texture": {"preset": "parchment", "seed": 3}},
    {"kind": "svg", "source": "assets/art/crest.svg", "width": 64, "height": 64, "x": 32, "y": 16,
      "masks": [{"type": "ellipse", "x": 0, "y": 0, "width": 64, "height": 64, "feather": 2}]},
    {"kind": "text", "text": "FACTORIA", "size": 18, "color": "#ffffff", "align": "center", "x": 64, "y": 92}
  ]
}
```

`factoria call image.bake '{"path":"assets/art/hero.image.json"}'` draws it, writes `assets/art/hero.png` and returns the
picture (`$image`). The schema is `schemas/image.schema.json`; `$schema` may point at it for editor completion.

## The document

| Field | Meaning |
|---|---|
| `format` | `"factoria.image/1"`. May be left out. |
| `width`, `height` | The canvas, whole pixels, 1 to 4096 each. Required. |
| `background` | A colour the canvas starts with. Without it the canvas starts fully transparent. |
| `output` | The PNG to bake, project-relative, ending in `.png`. Default: the document's name with `.image.json` replaced by `.png`. |
| `description` | A sentence for people and AIs; unused by the drawing. |
| `palette`, `ramps` | The colours the `indexed` layers are locked to, and their shades (see "Pixel art"). |
| `tile` | Tile mode: the picture repeats, so editing wraps around the edges of a tile (see "Tiles"). `true`, or `{"width", "height"}` for a sheet of tiles. |
| `frames`, `tags`, `sheet` | Make the document an animation: how long each frame shows, named runs of frames, the sheet's layout (see "Frames and tags"). |
| `layers` | The layers, **bottom first**: a later layer is drawn over the earlier ones. |

Colours are `"#rrggbb"`, `"#rrggbbaa"`, `"#rgb"`, a CSS name (`"white"`) or `[r, g, b]` / `[r, g, b, a]` with components in
0..1 (bytes when any is above 1). They are used as stored: nothing is converted to linear light.

## Layers

Every layer has `kind` and these optional fields.

| Field | Default | Meaning |
|---|---|---|
| `name` | | A label for people; unused by the drawing. |
| `visible` | `true` | `false` leaves the layer out (a hidden layer that other layers are clipped to hides them too). |
| `opacity` | `1` | 0..1, multiplies the layer's alpha. |
| `blend` | `"normal"` | How the layer mixes with what is below (see "Blend modes"). Not for `adjustment` layers. |
| `x`, `y` | `0` | Where the layer's own top-left corner lands on the canvas (or on its group), whole pixels, may be negative. Parts outside the canvas are cut. |
| `clip` | `false` | Draw only where the layer below is opaque (see "Clipping"). |
| `masks` | | Masks that hide parts of the layer (see "Masks"). |
| `adjustments` | | Colour operations on the layer's pixels, in order (see "Adjustments and effects"). |
| `effects` | | Operations that may change the layer's footprint, in order. Not for `adjustment` layers. |

The kinds and the fields they add:

- **`pixels`**: `source`, a PNG of the project, drawn at its own size. Transparency is kept.
- **`fill`**: `color`, and `width` / `height` for the layer's box (default: the canvas).
- **`gradient`**: `gradient` and `width` / `height`. `gradient.type` is `linear` (default) or `radial`; `stops` are two or
  more `{"at": 0..1, "color"}` in increasing `at`. Linear: `angle` in degrees, `0` runs from the top to the bottom and `90`
  from the left to the right. Radial: `center` as fractions of the box (default `[0.5, 0.5]`) and `radius` (`1` reaches the
  corners of the box, `0.5` the middle of its sides). Colours and alpha are interpolated premultiplied, so a fade to
  transparent has no dark fringe.
- **`procedural`**: `texture`, the picture arguments of `assets.generate_texture` (`preset`, `seed`, `color`, `scale`,
  `tileable`, ... `width` / `height` default to the canvas). It is the same generator, so the pixels are those the command
  writes for the same arguments. Run `docs.commands` on `assets.generate_texture` for the presets.
- **`svg`**: `svg` (the SVG text) or `source` (an `.svg` of the project), rasterized with the engine's SVG rasterizer and
  fitted inside `width` x `height` (default the canvas) keeping its aspect ratio. The `vector.*` commands edit the SVG of an svg layer
  in place (`{"document": "assets/art/hero.image.json", "layer": "crest"}`): boolean operations, offsets, strokes to outlines,
  alignment, repeats and the project style, keeping its ids and transforms and baking the document ([VECTOR.md](VECTOR.md)). The
  editor's Vector panel draws on such a layer by hand (pen, nodes, shapes, layers): see "The Image panel" below.
- **`text`**: `text` (`\n` starts a new line), `font` (default the engine's DejaVu Sans; `"builtin:pixel"` and the other
  built-in fonts, or a `.ttf` / `.otf` of the project), `size` (the em height in pixels), `color`, `align` (`left`, `center`
  or `right` of the layer's `x`) and `lineHeight` (in ems, default 1.2). `y` is the top of the first line.
- **`indexed`**: pixel art as palette indices: `rows` (text), or `width` / `height` for a blank layer, and `ai`. No masks,
  adjustments or effects (see "Pixel art").
- **`tileset`**: the 16 or 47 tiles of an autotile set, built from a few parts (`mode`, `tileWidth`, `tileHeight`, `parts`,
  `columns`, `variations`, `seed`, `terrain`), drawn onto the canvas at its `x` and `y` like any layer (see "Tiles").
- **`provider`**: a PNG made by an image provider (`source`), drawn like `pixels`, plus `provenance`: the record of how it was
  made (`provider`, `model`, `prompt`, `seed`, `references`, `license`, `author`, `notes`). A provider layer makes the
  baked picture AI-made (see "Baking"); the record goes to `assets.json` for the source PNG when it has none yet.
- **`group`**: `layers`, a list of layers (bottom first) drawn together onto a transparent canvas of their own, then drawn
  like one layer with the group's opacity, blend, masks, clip and offset. A group is **isolated**: a child's blend mode acts
  inside the group only, so a multiply layer in a group multiplies with the group's other layers, not with the canvas.
  Groups nest up to 16 deep.
- **`adjustment`**: `adjustments` that apply to everything drawn so far below it, instead of drawing pixels of its own. Its
  `opacity`, `masks`, `clip` and offset decide where and how much. See below.

Only the fields a kind lists are allowed; any other is an error that names the nearest valid one.

## Blend modes

`normal`, `multiply`, `screen`, `overlay`, `darken`, `lighten`, `colorDodge`, `colorBurn`, `hardLight`, `softLight`,
`difference`, `exclusion`, `add`, `subtract`, `hue`, `saturation`, `color`, `luminosity`.

All but `add` and `subtract` are the W3C "Compositing and Blending Level 1" modes that Photoshop, GIMP and
the browsers agree on (`hue`, `saturation`, `color` and `luminosity` are its non-separable ones). `add` is
`min(1, backdrop + source)` per channel and `subtract` is `max(0, backdrop - source)`. `fa::blend_pixel(mode, backdrop, source)`
(fa/tooling/image_doc.h) draws one pixel with a mode and is the reference the tests compare to.

## Colour and alpha

Decided once, for every layer kind and every tool built on this:

- Pixels are blended in the stored, sRGB-encoded values, like Photoshop, GIMP and Aseprite do, so a multiply layer looks as it
  does there. There is no linear-light conversion anywhere, and gradients interpolate the stored values too.
- PNGs and every layer's pixels are **straight alpha** (colour not multiplied by alpha); the compositor works in 32-bit float
  with the W3C compositing formula, so a half-transparent layer never darkens or tints its edge. Gradients, masks and blurs
  interpolate premultiplied values.
- The result is quantized to 8 bits once, at the end. A fully transparent pixel is written as `(0, 0, 0, 0)`; a picture
  with no transparent pixel is saved as an RGB PNG.
- No clock, no random numbers and no threads are used: the same document and files give the same bytes on the same build.
  (Another compiler or CPU may differ in the last bit of a float, which can change a byte.)

## Masks

`masks` is a list whose coverages are multiplied together, then multiply the layer's alpha. All coordinates are the layer's
OWN pixels (before `x` / `y` move it), so a mask follows its layer.

| `type` | Fields |
|---|---|
| `rect` | `x`, `y`, `width`, `height` |
| `ellipse` | the same box; the ellipse is inscribed in it, anti-aliased |
| `polygon` | `points`: at least three `[x, y]` corners |
| `path` | `path`: SVG path data (`M L H V C S Q T A Z`, absolute or relative); every subpath is closed and filled with the non-zero rule |
| `pixels` | `source`: a PNG (white shows, black hides, its alpha counts; outside it everything is hidden), `x`, `y` where it sits |

Every mask also takes `invert` (default `false`) and `feather` (pixels of soft edge, 0 to 512; a Gaussian blur of the mask
with sigma `feather / 2`; 0 is a hard edge). Vector masks have 4 sub-scanlines of vertical and exact horizontal
anti-aliasing.

## Clipping

A layer with `"clip": true` is drawn only where the nearest layer below that is not clipped itself (its "base") has
alpha (its alpha after its masks and effects, before its opacity), multiplied by that alpha. Several clipped layers in a row
follow the same base. If the base is hidden, so are the layers clipped to it. `clip` on the bottom layer is an error: there
is nothing below.

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

`palette: "style"` is `style.palette` of `assets.json` ([ASSETS.md](ASSETS.md)); with no style palette the render fails
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
  ([ASSETS.md](ASSETS.md)), else 135 (upper left).
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
reads, each with its sha256}` ([ASSETS.md](ASSETS.md), "Recipes: make an asset again"). So:

- `assets.regenerate {"path": "assets/art/hero.png"}` bakes it again; `{"stale": true}` bakes every picture whose document or
  source files changed.
- `factoria validate` warns about a stale bake with the exact command, like for any made asset.
- `ai` is `true` when the document has a `provider` layer or any file a layer reads is recorded as AI-made in `assets.json`
  (store disclosure, [ASSETS.md](ASSETS.md) "Provenance and store disclosure"). A `license` and `author` a person recorded for
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

## Pixel art

Pixel art needs exact pixels, a fixed palette and shapes without anti-aliasing. An `indexed` layer is that: its pixels are
palette INDICES written as text, so the file is readable, a change shows up in a diff, and a colour that is not in the palette
cannot be there. Baking draws each index in its palette colour through the normal compositor (alpha 255; `.` is transparent),
so an indexed layer takes `opacity`, `blend`, `clip`, `x`, `y` and sits in groups like any other. It takes no `masks`,
`adjustments` or `effects` (they would blend colours that are not in the palette); `image.layer.convert` to `pixels` first if
you want them.

```json
{
  "format": "factoria.image/1", "width": 8, "height": 8,
  "palette": [{"name": "outline", "color": "#1a1c2c"}, {"name": "skin-dark", "color": "#b06a40"},
              {"name": "skin", "color": "#e0a070"}, {"name": "skin-light", "color": "#f8d0a8"}],
  "ramps": [["skin-dark", "skin", "skin-light"]],
  "layers": [{"kind": "indexed", "name": "orb", "rows": [
    "..0000..",
    ".033320.",
    "03322220",
    "03222220",
    "02222110",
    "02221110",
    ".011110.",
    "..0000.."]}]
}
```

- **The palette** is the document's `palette`: a list of 1 to 81 different opaque colours, each `"#rrggbb"` (or any colour the
  engine reads) or `{"name", "color"}`; names are unique ignoring case and are what commands use (`"skin"`). Left out, an
  indexed layer uses `style.palette` of `assets.json` ("House style" in [ASSETS.md](ASSETS.md)); `image.pixel` and `image.draw`
  then copy it into the document, so changing the style later does not recolour finished art. `"palette": "style"` says it
  explicitly and keeps following the style (bake again after changing it: the recipe does not track `assets.json`).
- **The index characters** are `0-9a-zA-Z!#$%&*+-/:;<=>?@^_~`: position N is palette colour N (`0` the first, `a` the eleventh);
  `.` is transparent. All rows have the same length. An index beyond the palette is an error with its row and column.
- **Replacing the palette keeps the indices**, so the pixels change colour: append colours to keep the old ones.
- **Ramps** (`ramps`) group palette colours from the darkest to the lightest. `{"step": -1}` in a command is one step darker
  along the ramp of the colour already in the pixel, `{"step": 1}` one lighter, `{"color": "skin", "step": 1}` the colour one
  step lighter than `skin`; the step stops at the end of the ramp. A colour in no ramp steps to the palette colour nearest to
  it in OKLab that has a lower (higher) lightness, so shading works without declaring ramps; the same palette always gives the
  same answer. `image.palette` lists every colour's `shade` and `light`.
- **`ai: true`** on a layer marks its pixels as AI-made; the baked PNG is then recorded as AI-made ([ASSETS.md](ASSETS.md),
  "Provenance and store disclosure"). `image.layer.convert` sets it when it converts an AI-made picture.

A colour in a command is a palette index (`3`), a name (`"skin"`), the index character (`"3"`), a colour that IS in the palette
(`"#e0a070"`), or `null` / `"."` / `"transparent"` for transparent. Anything else is refused with a teaching error:

```
error: invalid_argument: image.pixel /pixels/1/2: The colour #e0a071 is not in the palette. The nearest palette colour is skin #e0a070 (index 2).
  hint: Use that colour, or add the new colour to the document's palette (image.palette).
```

An unknown name suggests the near names ("did you mean skin?"), and a document whose rows hold a wrong character or an index
the palette does not have is refused with the JSON pointer of the row (`/layers/0/rows/4`).

### Commands

All of them work on one document, make no anti-aliased pixel, write the document, bake it, and return the baked picture, the
changed `region` and `changed` like the other `image.*` commands. The `$image` of these four is the picture MAGNIFIED with hard
pixels (`scale` 1 to 32, default as large as fits 512 pixels; `previewScale` tells which; the preview file is
`.factoria/previews/<document>.png`), so every pixel is visible.

- `image.pixel {path, layer, pixels?, runs?, stamp?, create?, scale?, bake?}`: exact pixels. `pixels` is `[[x, y, colour], ...]`,
  `runs` is `[[x, y, length, colour], ...]` (to the right), `stamp` is `{x, y, rows, clear?}` with text rows in the document's own
  characters (`.` leaves the pixel alone, or erases it with `clear: true`). `layer` is an indexed layer's name or index path; with
  `create: true` an unknown name makes a blank canvas-sized indexed layer on top. Coordinates are canvas pixels (the layer's
  own `x`, `y` and those of its groups are accounted for); pixels outside the layer are counted in a warning.
- `image.draw {path, layer, shapes, create?, scale?, bake?}`: shapes drawn in order.
  - `line` `{points, color, perfect?, closed?}`: Bresenham between consecutive points. `perfect: true` removes the L-corner of a
    bend, so the line is one pixel thick everywhere (a straight or diagonal run is unchanged; a point where the line turns
    loses its corner pixel).
  - `rect` `{x, y, width, height, color?, fill?}` and `ellipse` `{x, y, width, height, color?, fill?}`: the box includes its
    last row and column (`x: 2, width: 5` covers columns 2 to 6); the ellipse is inscribed in it (midpoint algorithm, odd and
    even sizes, symmetric). `color` is the outline, `fill` the inside (a colour, or `true` for `color`); the fill goes first so
    the outline stays on top.
  - `polygon` `{points, color?, fill?}`: at least three corners; the fill takes the pixels whose centre is inside (even-odd)
    plus the outline.
  - `fill` `{at, color, connectivity?}`: the pixels connected to `at` that hold the same colour (or transparency) as it. `4` (the
    default) goes through edges and does not leak through a diagonal gap in an outline; `8` goes through corners too.
- `image.palette {path, palette?, ramps?}`: without `palette` or `ramps` it reads the palette, each colour with its index and
  character, name, `#rrggbb`, how many pixels use it, its ramp, `shade` and `light`. With them it rewrites them (`null` removes)
  and bakes.
- `image.palette.move {path, from, to, bake?}`: moves a palette colour (index, name or `#rrggbb`) to the position of `to`; the
  colours between shift by one, the rows of every indexed layer, cel and tileset part and the ramps are rewritten, so the picture
  does not change. `image.palette.remove {path, index, replaceWith?, bake?}`: takes a colour out; its pixels take `replaceWith`
  or become transparent (a warning counts them), the other pixels keep their colour. The palette keeps at least one colour. The
  Image panel's palette bar runs them (docs/EDITOR.md, "Image panel").
- `image.layer.convert {path, layer, to, palette?, dither?, space?, strength?, alphaThreshold?}`: `to: "indexed"` draws the layer
  alone (with its masks, adjustments and effects), crops it to what it shows and gives each pixel its nearest palette colour
  (OKLab, or `space: "rgb"`), with the optional `dither` of the `dither` adjustment (`bayer2`, `bayer4`, `bayer8`,
  `floydSteinberg`, `atkinson`) at `strength`. Pixels at least `alphaThreshold` (0.5) opaque stay, the rest become transparent;
  a pixel that already is a palette colour keeps it. `to: "pixels"` writes the layer's PNG (in `<document>.layers/`) and turns it
  into a pixels layer, which is the way back to `image.edit`, `image.paint` and the effects.

`image.paint` and `image.edit` REFUSE an indexed layer with an error that names `image.pixel`, `image.draw` and
`image.layer.convert`: a soft brush would put colours outside the palette on it. `image.select` and `image.export` work with it
like with any layer.

### A 16x16 face, step by step

Make the document with its palette and a ramp (the picture is empty until the first layer):

```json
{"command": "image.create", "args": {"path": "assets/art/face.image.json", "width": 16, "height": 16,
  "palette": [{"name": "outline", "color": "#1a1c2c"}, {"name": "skin-dark", "color": "#b06a40"},
              {"name": "skin", "color": "#e0a070"}, {"name": "skin-light", "color": "#f8d0a8"},
              {"name": "white", "color": "#ffffff"}],
  "ramps": [["skin-dark", "skin", "skin-light"]]}}
```

A filled circle with an outline, on a new indexed layer:

```json
{"command": "image.draw", "args": {"path": "assets/art/face.image.json", "layer": "face", "create": true,
  "shapes": [{"type": "ellipse", "x": 1, "y": 1, "width": 14, "height": 14, "fill": "skin", "color": "outline"}]}}
```

Eyes and a mouth that bends without doubled pixels:

```json
{"command": "image.draw", "args": {"path": "assets/art/face.image.json", "layer": "face", "shapes": [
  {"type": "rect", "x": 4, "y": 5, "width": 2, "height": 3, "fill": "outline"},
  {"type": "rect", "x": 10, "y": 5, "width": 2, "height": 3, "fill": "outline"},
  {"type": "line", "points": [[4, 10], [6, 12], [10, 12], [12, 10]], "color": "outline", "perfect": true}]}}
```

A glint in each eye, and a shade one step darker along the bottom (the outline has no darker colour, so it stays):

```json
{"command": "image.pixel", "args": {"path": "assets/art/face.image.json", "layer": "face",
  "pixels": [[4, 5, "white"], [10, 5, "white"]],
  "runs": [[3, 13, 10, {"step": -1}], [5, 14, 6, {"step": -1}]]}}
```

A highlight stamped from text (`3` is `skin-light`, `.` leaves the pixel as it is):

```json
{"command": "image.pixel", "args": {"path": "assets/art/face.image.json", "layer": "face",
  "stamp": {"x": 3, "y": 2, "rows": ["..333", "3333."]}}}
```

The layer in the document now reads:

```
................
......0000......
....03332200....
...3333222220...
..022222222220..
..024022224020..
.02200222200220.
.02200222200220.
.02222222222220.
.02222222222220.
..020222222200..
..022022222020..
...0220000020...
....00111100....
......0000......
................
```

Every command returned the baked `assets/art/face.png` and a magnified preview; the document is the source, so a later
`image.pixel` edits single pixels of it and the diff shows exactly which.

### Pixel helpers

The finishing work of pixel art, done on an INDEXED layer by palette index only, so nothing is ever blended and the art stays
palette-exact. All of them take `layer` (an indexed layer), `frame` or `frames` (below), `selection` (a stored
[selection](#selections-imageselect): only its pixels, coverage 128 or more, may change) and `scale` / `bake` like `image.pixel`,
and they answer like it: the baked picture, the changed `region`, `changed`, `pixelsChanged` and `$image` magnified with hard pixels,
plus the counts of the helper. A helper that changes nothing says so in `warnings`. A layer of any other kind is refused: turn a
painted one into pixel art with `image.to_pixel_art`.

- `image.pixel.outline {path, layer, side?, mode?, color?, connectivity?, shade?, litShade?, light?}`: `side` `outer` (default;
  on the transparent pixels around the shape) or `inner` (the shape's own edge pixels); `connectivity` 4 (default; a thin outline
  whose corners stay open) or 8 (corners closed). `mode` `flat` paints `color`; `darkest` (default without `color`) takes, for each
  outline pixel, the darkest colour of the ramp of the fill it touches; `selective` is sel-out: the fill it touches `shade` steps
  darker (default 2) and, on the side facing the light, only `litShade` (default `shade - 1`), so the outline is lighter where the
  light hits. Without a light direction every pixel is `shade` steps darker, and a `note` says so.
- `image.pixel.shade {path, layer, light?, shadowWidth?, shadowLevels?, highlightWidth?, highlightLevels?, dither?}`: lights the
  shape (its non-transparent pixels, or the `selection`) from `light`. Along the light's axis, `shadowLevels` bands of
  `shadowWidth` pixels at the edge facing away step the colour darker (the outermost the most) and `highlightLevels` bands of
  `highlightWidth` at the edge facing the light step it lighter, along the colour's ramp (`{"step": -1}` above). `dither` N turns
  the first N pixels of each following band into a Bayer-ordered mix with the stronger band, so the transition is not a hard line.
  Shading reads the pixel as it is, so run it once on flat-coloured shapes (select a part with `selection` and shade it as its
  own shape). The light is `light` (degrees counter-clockwise from the right, 135 = upper-left; a name such as `upper-left`;
  `"style"`), else `style.lightDirection` of assets.json; with neither the command stops and says how to give one. The result
  names it in `light` {degrees, name, from}.
- `image.pixel.dither {path, layer, colors | ramp, level | gradient, pattern?, onlyFilled?, rect?}`: fills the `selection` / `rect`
  (else the whole layer box) with pixels of exactly the given palette colours arranged by an ordered pattern: `pattern` `bayer4`
  (default; also `bayer2` with 5 levels, `bayer8` with 65, and `checker`). `level` (0 to 1) is a constant share of the second
  colour; `gradient` {from [x, y], to [x, y]} runs the first colour into the last along that line, through any colours between
  them. `ramp` names any colour of a declared ramp and uses the whole ramp (a gradient then runs from its lightest to its darkest).
  `onlyFilled` leaves transparent pixels alone. The pattern lines up with the canvas, so two layers dithered alike match.
- `image.pixel.cleanup {path, layer, passes?, holes?, connectivity?, tolerance?, keep?}`: `orphans` (a pixel with no neighbour of
  its colour takes the commonest opaque colour around it, or goes when only transparency is around), `doubles` (the corner pixel
  of a one-pixel line where it bends in an L; the right-angled corners of shapes stay) and `jaggies` (a nearly straight line with
  uneven steps, 3-3-1-3, is redrawn evenly between its ends when `tolerance` allows). `keep` lists colours never touched: a
  one-pixel eye highlight is an orphan to the command, so keep its colour. The result has `orphans`, `doubles`, `jaggies` (pixels
  changed by each) and `changedPixels` (canvas `[x, y]`, the first 100).
- `image.pixel.rotate {path, layer, angle, method?, pivot?}`: turns the layer's pixels (or the `selection`'s) `angle` degrees
  clockwise about `pivot` (default their centre) and draws them back; the layer's box grows to hold them. A multiple of 90 is an
  exact permutation of the pixels. Otherwise `rotsprite` (default) enlarges 8 times with Scale2x, rotates by nearest sample and
  takes the commonest colour of each 8x8 block, which keeps edges and one-pixel lines far better than `nearest`; only palette
  colours can appear. RotSprite takes at most 256 x 256 pixels. A one-pixel line still frays: rotate big, then clean up.
- `image.pixel.scale {path, layer, factor | size, method?, pivot?}`: `factor` (2, 0.5 or `[2, 1]`) or `size` {width, height} (one
  keeps the proportions). `method` `nearest` repeats pixels (a whole factor makes exact blocks), `mode` takes the commonest colour
  of the old pixels each new one covers (the clean way to shrink), `scale2x` / `scale3x` enlarge by exactly 2 / 3 rounding corners
  instead of copying them, and `auto` (default) picks nearest to enlarge and mode to shrink. A non-integer enlargement works but
  repeats some rows and not others; a warning says so.
- `image.to_pixel_art {path, source | png, into, width? height? | pixelSize?, method?, palette?, dither?, strength?, space?,
  alphaThreshold?, orphans?, outline?, x?, y?}`: converts a layer of the document (any kind, drawn alone with its masks and effects)
  or a project PNG into the indexed layer `into` (created on top, or replaced). The size is `width` and/or `height` (one keeps the
  proportions) or `pixelSize` (source pixels per art pixel). `method` `dominant` (default) maps every source pixel to its
  nearest palette colour (OKLab) and gives each art pixel the commonest colour of the area it covers, so edges stay crisp;
  `average` averages the area (a box filter with exact fractional edges, not bilinear) and quantizes with the `dither` of
  `image.layer.convert` (`none`, `bayer2/4/8`, `floydSteinberg`, `atkinson`). Then it removes orphans (`orphans`, default true, but
  false with a `dither`, which is made of single pixels) and can add an outer outline (`outline`: a colour, or `darkest`). The
  palette is the document's, else `palette`, else `style.palette`. The art lands where the source's pixels were (a PNG at 0, 0);
  the result has `sourceSize`, `size`, `at`, `colorsUsed`, `orphansFixed`, `outlinePixels`.

**Frames.** `frame` (default 0) changes one cel; `frames` changes several in one call: `"all"`, a list `[0, 2]` or
`{"from": 1, "to": 3}`. The same change is made on each frame's cel, `perFrame` lists the counts per frame, and the picture and
`region` are the first frame's. Only a frame that shows the layer's own cel is changed in place; as with `image.pixel`, a frame
that held a copy of an earlier cel gets its own cel first.

A worked example, from real runs in a project whose `assets.json` has `"style": {"lightDirection": "upper-left"}` and a 16x16
document with a red ramp (`red-dark`, `red`, `red-light`). A 12x12 ellipse of `red` is the starting point
(`image.draw {layer: "ball", create: true, shapes: [{type: "ellipse", x: 2, y: 2, width: 12, height: 12, fill: "red"}]}`).

```
image.pixel.shade {path, layer: "ball", shadowWidth: 3, highlightWidth: 1}
-> pixelsChanged 49, light {degrees: 135, name: "upper-left", from: "style.lightDirection"}
......2222......        ......3333......
....22222222....        ....33322221....
...2222222222...   ->   ...3322222221...      (3 = red-light, 1 = red-dark: light on the upper left,
...2222222222...        ...3222222221...       shadow on the lower right, along the ramp)
```

Then `image.pixel.outline {layer: "ball", mode: "selective"}` (`pixelsChanged` 36) puts a ring around
it that is `red` (2) on the lit upper-left and `red-dark` (1) elsewhere, from the same style light:

```
......2222......
....22333311....
...2333222211...
..233222222211..
...
```

`image.pixel.dither {layer: "ball", colors: ["red", "red-dark"], gradient: {from: [8, 9], to: [12, 13]}, onlyFilled: true, rect:
{x: 8, y: 9, width: 6, height: 5}}` softens the shadow (10 pixels), and `image.pixel.cleanup {layer: "ball"}` then reports
`orphans 0, doubles 1, jaggies 0` and a one-pixel `region` at the single double it removed. A sword of 4 x 7 pixels rotated with
`image.pixel.rotate {angle: 45}` (RotSprite) keeps its two colours and its shape:

```
......2.....
......2.....                    .......22...
.....22.....                    .....222....
.....22.....        ->          ...2222.....
.....22.....                    ....22......
....2222....                    ....12......
......1.....
```

and `image.to_pixel_art {source: "sky", into: "art", width: 8, method: "average", dither: "bayer4"}` turns a 16x16 gradient layer into
an 8x8 indexed layer of four palette colours (the first four rows) (`sourceSize` 16x16, `size` 8x8, `colorsUsed` 4, `orphansFixed` 0):

```
13131313
32434242
23243423
43434342
```

## Frames and tags

A document becomes an animation when it has several frames. The layers stay as they are; each `pixels` or `indexed` layer
gets a picture (a **cel**) per frame, and the bake is a **sprite sheet** (the frames in a grid) plus the `sheet` entry of
`assets.json` with one SpriteAnimator **clip** per tag. A game plays a tag by its name: `SpriteAnimator {"clip": "bounce"}` or
`entity.spriteAnimator.play("bounce")` ([ANIMATION.md](ANIMATION.md)), with `Sprite.texture` the baked PNG. A document without
`frames` or `tags` is one still picture and is baked exactly as before.

```json
{
  "width": 4, "height": 3,
  "palette": [{"name": "ball", "color": "#e04040"}],
  "frames": [{"duration": 80}, {"duration": 80}, {"duration": 160}],
  "tags": [{"name": "bounce", "from": 0, "to": 2, "direction": "pingpong"}],
  "sheet": {"columns": 3},
  "layers": [
    {"kind": "indexed", "name": "ball", "rows": [".00.", ".00.", "...."],
     "cels": [{"frame": 1, "rows": ["....", ".00.", ".00."]},
              {"frame": 2, "link": 0}]}
  ]
}
```

Frame 0 is the layer's own `rows`, frame 1 has its own cel, and frame 2 shows frame 0's picture again. The worked example below has a real one.

| Field | Meaning |
|---|---|
| `frames` | One `{"duration": ms}` per frame (1 to 60000, default 100). Its length is the number of frames; without it the document has one frame. |
| `tags` | `{"name", "from", "to", "direction"?, "repeat"?}`: frames `from` to `to` (inclusive), `direction` `forward` (default), `reverse` or `pingpong`, `repeat` times (0 or missing: the clip loops for ever; N plays N times and stops). The name is the clip name and is unique. Tags may overlap. |
| `sheet` | `{"columns"}`: cells per row of the baked sheet. Default: about square (`ceil(sqrt(cells))`). All cells are the size of the canvas; a sheet may be at most 16384 pixels per side. |
| `cels` (on a layer) | The layer's pictures after frame 0: `{"frame", ...}` with `source` (pixels) or `rows` (indexed) and `x`, `y`, `opacity`; or `link` (show what an EARLIER frame shows); or `empty: true` (nothing). Frame 0 is the layer itself (`source` / `rows`, `x`, `y`; a pixels layer with `cels` may leave `source` out: it is empty in frame 0). |

A frame with no cel HOLDS the one before it, so a layer that does not move needs no `cels`, and a walk that changes only the
legs lists only the legs. Layers of other kinds (fills, gradients, text, groups...) are the same in every frame. A cel's own
`opacity` is relative to the layer's; a pixels cel at frame 0 always has opacity 1 (bake it into the picture or set the layer's).

### What the sheet holds

The cells of the sheet are the frames in order. SpriteAnimator plays a contiguous run of cells at ONE speed, either forward
and looping or once. A tag that already is that gets the clip `firstFrame..lastFrame` of its frames, with `fps` = `1000 *
frames / milliseconds` (two decimals). A tag that is not (reverse, ping-pong, repeated, or with frames of different
durations) gets **extra cells after the frames** that spell its order out, and its clip points at them: the sheet keeps its
frames as they are and only grows. The cell time is the greatest common divisor of the tag's durations, so a 160 ms frame
among 80 ms ones takes two cells. A looping ping-pong of two frames, and a tag of one frame, need no extra cells. A tag that
would need too many cells (more than 512) plays every frame for the average time instead, and the bake warns. A sheet larger
than 16384 pixels on a side is an error that suggests `sheet.columns`, fewer frames or a smaller canvas.

### Commands

The frame commands change the frames of the document, write it and bake the sheet, and return the baked sheet as `$image`
with `sheet` (grid and clips), `animation` `{frameCount, totalMs, frames, tags}` and the next steps to play it. None of them
touches a layer of the document that has no cels.

- `image.frame.add {path, count?, at?, from?, blank?, duration?}`: inserts frames. The first call makes a still image an
  animation. New frames copy the frame before `at` (or `from`), or are empty on every pixels and indexed layer with `blank: true`.
  Tags after `at` move along, a tag the new frames land inside grows.
- `image.frame.remove {path, frame}`, `image.frame.move {path, frame, to}`: delete or reorder a frame on every layer, with its
  duration; tags follow their frames (a tag that is left with no frame is removed, with a warning). Removing the last frame
  that is left, when there are no tags, makes the document a still again.
- `image.frame.set {path, frame, duration}`: how long frames show; `frame` is a number, `[first, last]` or `"all"`.
- `image.frame.cel {path, layer, frame, from? | clear?}`: what one layer shows in one frame: what it shows in frame `from`
  (the two share one file or one set of rows), or nothing. A way to reuse a pose or hide a layer for a few frames.
- `image.frame.sheet {path, columns}`: cells per row (`null` for the automatic grid).
- `image.tag.set {path, name, from?, to?, direction?, repeat?}`: creates a tag or changes the fields you give of it;
  `image.tag.remove {path, name}` deletes it (the frames stay and the clip leaves the sheet).

`image.pixel`, `image.draw`, `image.edit`, `image.paint` and `image.export` take **`frame`** (default 0) and edit or export that
frame: the layer's cel for it is changed and the other frames keep what they show (the picture is copied on write, so a cel
shared with another frame by a hold or a `link` becomes its own). On a document that is a still, without `frame`, they behave
as they always did. Their result then has `frame` and `frames`, and their `$image` is that frame, not the sheet. A layer that
`image.edit` copies or cuts into, or `create: true` makes, shows its picture only in the `frame` you gave (it is empty in the
others, so the cut piece or the new effect is not drawn over every frame); without `frame` it is the same picture in every frame,
as in a still. `image.select` takes `frame` too: its colour, alpha and layer selections read that frame, and the stored selection
stays one mask per document.

`image.info` lists `animation` (frames with their durations and tags, and the `sheet` the bake will write) and, for a layer
with cels, `celFrames`: the frames where it changes.

### Onion skin

`image.pixel`, `image.draw`, `image.edit` and `image.paint` take `onion` to draw with the neighbouring frames ghosted in the
returned picture (a preview: the document and the bake never have them): `true`, or `{"before": 1, "after": 1, "opacity": 0.4,
"beforeColor": "#ff4040", "afterColor": "#4080ff", "loop": false}`. `before` and `after` are how many frames (0 to 8); the
nearest ghost has `opacity`, the next ones 1/2, 1/3 of it; the frames before are tinted red, the ones after blue, and they are
drawn UNDER the frame being edited. `loop: true` makes the frame before 0 the last one. It does nothing on a document with one frame.

### A bouncing ball, step by step

An 8x10 ball and a floor. The ball is drawn once, then the document gets two more frames:

```json
{"command": "image.create", "args": {"path": "assets/art/ball.image.json", "width": 8, "height": 10,
  "palette": [{"name": "outline", "color": "#1a1c2c"}, {"name": "red", "color": "#e04040"},
              {"name": "shine", "color": "#f8d0a8"}, {"name": "floor", "color": "#5d275d"}]}}
{"command": "image.draw", "args": {"path": "assets/art/ball.image.json", "layer": "floor", "create": true,
  "shapes": [{"type": "line", "points": [[0, 9], [7, 9]], "color": "floor"}]}}
{"command": "image.draw", "args": {"path": "assets/art/ball.image.json", "layer": "ball", "create": true,
  "shapes": [{"type": "ellipse", "x": 1, "y": 0, "width": 6, "height": 6, "fill": "red", "color": "outline"}]}}
{"command": "image.pixel", "args": {"path": "assets/art/ball.image.json", "layer": "ball", "pixels": [[2, 1, "shine"]]}}
{"command": "image.frame.add", "args": {"path": "assets/art/ball.image.json", "count": 2, "duration": 80}}
```

`image.frame.add` copied frame 0 twice and the bake is now a 16x20 sheet of 2x2 cells. The ball falls in frame 1 and squashes on
the floor in frame 2, so each frame clears the copy and draws its own pose (the floor is shared by all three):

```json
{"command": "image.frame.cel", "args": {"path": "assets/art/ball.image.json", "layer": "ball", "frame": 1, "clear": true}}
{"command": "image.frame.cel", "args": {"path": "assets/art/ball.image.json", "layer": "ball", "frame": 2, "clear": true}}
{"command": "image.draw", "args": {"path": "assets/art/ball.image.json", "layer": "ball", "frame": 1,
  "shapes": [{"type": "ellipse", "x": 1, "y": 2, "width": 6, "height": 6, "fill": "red", "color": "outline"}]}}
{"command": "image.draw", "args": {"path": "assets/art/ball.image.json", "layer": "ball", "frame": 2, "onion": true,
  "shapes": [{"type": "ellipse", "x": 0, "y": 4, "width": 8, "height": 5, "fill": "red", "color": "outline"}]}}
```

The last result is the magnified frame 2 with frame 1 in red under it. Then the timing (frame 2, the squash, lasts twice as
long) and the tag:

```json
{"command": "image.frame.set", "args": {"path": "assets/art/ball.image.json", "frame": 0, "duration": 80}}
{"command": "image.frame.set", "args": {"path": "assets/art/ball.image.json", "frame": 2, "duration": 160}}
{"command": "image.tag.set", "args": {"path": "assets/art/ball.image.json", "name": "bounce", "from": 0, "to": 2, "direction": "pingpong"}}
```

The last call returns

```json
{"path": "assets/art/ball.png", "width": 24, "height": 30,
 "sheet": {"columns": 3, "rows": 3, "frameWidth": 8, "frameHeight": 10, "frames": 8,
           "clips": [{"name": "bounce", "firstFrame": 3, "lastFrame": 7, "fps": 12.5, "loop": true}]}}
```

Cells 0 to 2 are the three frames; the clip is the extra cells 3 to 7: frames 0, 1, 2, 2, 1 at 80 ms each (the squash takes
two cells, and the loop returns to frame 0 by itself). The document now holds the ball's cels for frames 1 and 2 and the three
durations:

```json
"frames": [{"duration": 80}, {"duration": 80}, {"duration": 160}],
"tags": [{"name": "bounce", "from": 0, "to": 2, "direction": "pingpong"}]
```

A game plays it with `{"Sprite": {"texture": "assets/art/ball.png"}, "SpriteAnimator": {"clip": "bounce"}}`. The recipe of
`assets/art/ball.png` is `image.bake` of the document, so a later `image.pixel ... "frame": 1` makes it stale and
`assets.regenerate {"stale": true}` (or the next `image.*` call) bakes it again.

### Aseprite files

`assets.import` of an `.aseprite` / `.ase` file makes an image document next to the PNG (`hero.aseprite` -> `hero.image.json`,
`hero.png`, and each cel's picture in `hero.layers/<layer>-<frame>.png`): layers (with their visibility, opacity and blend
mode), cels (a linked cel is a `link`), frame durations and tags (direction and repeat count). Hidden layers stay, hidden;
groups are flattened into their layers; an empty layer and a reference layer are left out. An indexed file keeps its palette as
an indexed document (layers of `indexed` kind) when its colours fit a document palette (opaque, no repeats, at most 81);
otherwise the layers are pixels layers and the result says why. A file with one frame and no tags is a document without
`frames`. The PNG is baked from the document, so the sheet and its clips follow every edit you make with the `image.*`
commands. `flat: true` keeps the old import (one PNG sheet and its clips, no document), see [ASSETS.md](ASSETS.md), "Aseprite".

A cel picture nothing reads any more is deleted in the same save as the change that left it behind (`image.frame.remove`,
`image.frame.cel` with `clear`, a cel painted or edited again, `image.layer.remove`, converting a layer...), and the result
lists the paths in `removedFiles` (the file and its `assets.json` entry go). Only a PNG directly inside the document's own
`<document>.layers/` folder is a candidate, only in a document that is or was an animation, and it stays when anything else
still names it: another frame, layer or `link` of the document, or any other image document of the project. A file you put
somewhere else and pointed a cel at is never deleted.

## Tiles

A ground, a wall or a whole tile set is a picture that REPEATS, and a repeating picture shows a line wherever one copy meets
the next. Three things in the document help, all offline and deterministic:

- **tile mode** (`tile`): editing wraps around the edges of a tile, so the edges keep matching while you draw;
- the **seam check** (`image.tile.check`): compares the pixels that touch when the tile repeats, and shows 3 x 3 copies with the
  bad pixels marked (`image.tileset.check` does the same for a tile set, inside the tiles too);
- the **`tileset` layer** (`image.tileset.build`): builds the 16 or 47 tiles of an autotile set from a few parts (inside, edge,
  corner), bakes the sheet and writes the `Tilemap` rules, with variations picked by a seed.

### Tile mode

`image.tile.set {"path": "assets/art/ground.image.json"}` writes `"tile": true` into the document: the whole canvas is ONE tile.
`{"path": ..., "width": 16, "height": 16}` writes `"tile": {"width": 16, "height": 16}`: the canvas is a sheet of tiles of that
size (each size must divide the canvas). `"enabled": false` removes it. With tile mode on:

- `image.pixel`, `image.draw` (every shape, `fill` too), `image.paint` and the `move` action of `image.edit` wrap: what leaves
  the right edge comes back in on the left, what leaves the bottom comes back at the top. A line from (14, 3) to (20, 3) in a
  16-pixel tile is drawn from 14 to 15 and from 0 to 4.
- A shape wraps inside the ONE tile that holds its anchor (a pixel, the first point of a line, the corner of a rectangle, the
  `at` of a fill, the first point of a stroke), so on a sheet a stroke never spills into the next tile. `fill` is a flood that
  also crosses the edges. A brush wider than the tile is stamped once for every copy of the tile that it reaches.
- The pixel helpers `image.pixel.outline`, `shade`, `dither` and `cleanup` work on each tile as if it repeated: the pixels
  across an edge are the pixels on the opposite edge of the same tile.
- `image.pixel.rotate`, `image.pixel.scale`, `image.to_pixel_art` and the `transform` action of `image.edit` do NOT wrap (the
  result warns): run `image.tile.check` afterwards, or draw the result again with `image.pixel` / `image.draw`.
- A dither pattern is laid out from the canvas, not from the tile: keep the tile size a multiple of the pattern's size (2 for
  `checker` and `bayer2`, 4 for `bayer4`, 8 for `bayer8`) and the pattern continues across the seam.

### The seam check: `image.tile.check`

`image.tile.check {"path": "assets/art/ground.image.json"}` bakes nothing: it reads the document as it is and compares, for every
tile that is not empty, its right column with its own left column and its bottom row with its top row. The tile is the
document's `tile`, or `tileWidth` / `tileHeight`, or the whole canvas. It returns `seamless`, the `tolerance` used and
`problems` (the tile, the side, the runs of mismatching pixels in canvas coordinates, how many and how far apart), and writes
a preview to `.factoria/previews/` (also returned as `$image`): the tile 3 x 3 with a red line on every mismatching pixel of the
central copy.

`tolerance` (0 to 255) is how far apart two touching pixels may look. Without it a picture with a palette (or
`style.pixelArt`) gets 0, because pixel art keeps hard colours; any other picture gets 1.5 times the mean difference between
neighbouring pixels inside the tiles, rounded up, so a soft texture is not failed for its own gradient. The result says which
one was used.

An autotile set is checked with `image.tileset.check` (see "The `tileset` layer"), which also compares the joins INSIDE each
tile.

### The `tileset` layer

A `tileset` layer builds an autotile sheet from parts. Each part is ONE tile picture drawn for ONE orientation, and the
generator makes the other orientations by flipping (and, for square tiles, transposing) it.

| Field | Meaning |
|---|---|
| `mode` | `"blob47"` (default): the 47 tiles of the 8 neighbours. `"basic16"`: the 16 tiles of the 4 orthogonal neighbours (no inner corners). |
| `tileWidth`, `tileHeight` | One tile in pixels, both even (a tile is cut into four quadrants). Giving one makes the tile square. |
| `parts` | The pictures, below. |
| `columns` | Tiles per row of the sheet. Default 4 for basic16 and 8 for blob47. |
| `variations`, `seed` | Pictures per tile (1 to 8) and the seed that picks variants of the parts for the others. |
| `terrain` | The terrain's name in the rules file. Default: the layer's name, else `terrain`. |

The parts, each a PNG path, `{"source": "x.png"}` (exactly one tile big), `{"rows": [...]}` (text rows of the document's
`palette`, as in an `indexed` layer) or `{"color": "#4a8a2c"}` (one flat colour), or a list of those for variants:

| Part | Draw | Needed |
|---|---|---|
| `inside` | a flat tile of the terrain | always |
| `edge` | the terrain's TOP edge: terrain below, nothing above | always |
| `corner` | the terrain's top-left OUTER corner | always |
| `innerCorner` | an inside tile with the top-left corner cut out | blob47 |
| `edgeLeft` | the terrain's left edge | a tile that is not square |
| `edgeBottom`, `edgeRight`, `cornerNE`, `cornerSW`, `cornerSE`, `innerCornerNE`, `innerCornerSW`, `innerCornerSE` | an orientation drawn by hand instead of derived | never |

A tile is built from four quadrants (a quarter of the tile each). What a quadrant shows depends on the two neighbours next to
it and the diagonal one between them: with neither neighbour it is the outer corner; with only one it is the edge facing the
missing neighbour; with both and the diagonal missing it is the inner corner (blob47 only); with all three it is the inside.
Each quadrant is cut from the part, flipped to its orientation. Draw a part so that it can be flipped: a light source from the
top left is wrong on the right and bottom edges, so give `edgeRight` / `edgeBottom` (and the other optional parts) when the
flipped copy would look wrong. Variation 0 of a tile always uses the first variant of every part; variation `v` >= 1 picks a variant
of each quadrant from `seed`, `v` and the tile, so the same seed always gives the same sheet. A tile whose parts have fewer variants
than variations repeats an earlier one, and the result warns with the tiles affected.

Tile `s * variations + v` of the sheet is variation `v` of slot `s`, row by row, left to right: the numbering of the `Tilemap`
autotile rules (docs/AI_GUIDE.md, section 9.8).

### Commands

- `image.tileset.build {path, mode, tileWidth, tileHeight, parts, ...}`: creates the document (or adds the layer to an existing
  one, or updates it), sets the canvas to the sheet and `tile` to the tile size, bakes the PNG and writes the rules file
  (default `<document>.terrains.json`). Running it again changes only the keys you pass: `parts` merge by name (`null` removes a
  part) and the PNG and the rules are rewritten in place. A rules file that is not this layer's is not replaced without
  `overwrite`. The result has `tileset` (layer, layout, parts), `rules`, `terrain` and `tilemap` (the `Tilemap` fields to set).
- `image.tileset.info`: what the parts are, with a drawing of each, which ones the tile shape needs, and the table of slots with
  their neighbour masks. With `path` it also lists every tile with its place in the sheet.
- `image.tileset.check {path}`: every part is present and exactly one tile big (an error names its JSON pointer), then the
  seams between every pair of tiles that can stand side by side in a map are compared. Tile A east of tile B needs A to have an
  east neighbour and B a west one. For blob47 the whole seam is compared. For basic16 the set has no tile for the cell on the
  diagonal, so only the half of the seam where both tiles have the neighbour (or both lack it) is compared. The result and the
  preview (`.factoria/previews/<document>.tilesetcheck.png`, red marks on the failing sides) work as in `image.tile.check`.
  It also compares the joins INSIDE each tile. A generated tile is four quadrants, and where two of them are cut from different
  parts (corner next to edge, edge next to inside, inner corner next to edge...) the two parts must continue into each other
  across the middle line: they have to show the same pixels (within the tolerance, 0 for pixel art) in the two columns or rows
  next to it, so a detail that sits ON the middle line of one part must be in the other part too. Two quadrants cut from the
  same picture agree with themselves and are not compared. A join that fails is a problem with the axis `centreColumn` (the
  quadrants are side by side) or `centreRow` (one above the other), the tile in `a` and `b`, the `half` (`top`, `bottom`,
  `left`, `right`), the two `parts` and the `runs` of rows or columns of the tile that differ; the preview marks those runs red
  on the middle line of the tile.
- `image.tileset.rules {path}`: writes the rules file alone. `image.tileset.build` already does; this is the command the recipe of
  the rules file records.

### The files and when they go stale

`image.tileset.build` writes the sheet PNG next to the document and records, in `assets.json`, the recipe of two outputs. The PNG is
an ordinary bake (`image.bake`), with every part PNG as an input. The rules file has the recipe `image.tileset.rules` with the
document as input. Change a part PNG and the sheet is stale; change the document and both are. `assets.regenerate {"stale": true}`
redraws what is stale in place, and `factoria validate` warns about a sheet that was never baked or no longer matches. The rules
file is a JSON of format `factoria.terrains/1`: `{"terrains": [{"name", "mode", "seed", "tiles"}]}`, the tile of every neighbour
combination (a list of tiles when `variations` is more than 1).

### A ground tile set, step by step

A 47-tile ground from four 8 x 8 parts and three palette colours.

1. Build it. The `rows` use the palette in order: `0` the dark outline, `1` the grass, `2` a lighter speck. `.` is transparent.

   ```json
   {"path": "assets/art/ground.image.json", "mode": "blob47", "tileWidth": 8, "tileHeight": 8, "terrain": "ground",
    "palette": ["#1e4a14", "#4a8a2c", "#5fa23a"],
    "parts": {
      "inside": {"rows": ["11111111", "11211111", "11111111", "11111111", "11111111", "11111121", "11111111", "11111111"]},
      "edge": {"rows": ["........", "........", "00000000", "11111111", "11111111", "11111111", "11111111", "11111111"]},
      "corner": {"rows": ["........", "........", "..000000", "..011111", "..011111", "..011111", "..011111", "..011111"]},
      "innerCorner": {"rows": ["..011111", "..011111", "00011111", "11111111", "11111111", "11111111", "11111111", "11111111"]}}}
   ```

   `factoria call image.tileset.build @ground.json` writes `assets/art/ground.image.json`, bakes the 64 x 48 sheet
   `assets/art/ground.png` (47 tiles, 8 per row) and writes `assets/art/ground.terrains.json`.
2. Check that the tiles fit: `factoria call image.tileset.check '{"path":"assets/art/ground.image.json"}'` says
   `seamless: true` with `badSeams: 0` (486 seams compared, the joins inside the tiles among them). A part that does not match its
   neighbour lists the pair or the join, and the preview marks the sides in red.
3. Make a level with a Tilemap and give it the rules. In one engine (the batch), build an empty map, load the rules and paint:

   ```json
   [
    {"command": "scene.import_ascii", "args": {"entity": "map", "rows": ["............", "............", "............", "............", "............", "............", "............", "............"], "legend": {".": -1}, "tilemap": {"tileset": "assets/art/ground.png", "tileSize": [8, 8]}}},
    {"command": "tilemap.set_terrains", "args": {"id": "map", "path": "assets/art/ground.terrains.json"}},
    {"command": "tilemap.paint_terrain", "args": {"id": "map", "terrain": "ground", "rect": {"col": 2, "row": 1, "width": 7, "height": 5}}},
    {"command": "tilemap.paint_terrain", "args": {"id": "map", "terrain": "ground", "erase": true, "cells": [[5, 3]]}}
   ]
   ```

   Painting writes the tile that fits each cell and re-tiles the cells around it: the 7 x 5 block gets its edges and corners,
   and erasing the middle cell leaves a hole that is ringed with the right edges and inner corners. Each changed cell is written the way
   `tilemap.set_tile` writes it, so solid tiles keep their collision.
4. More looks: run the build again with `"variations": 3, "seed": 7` and a list for a part, for example
   `"parts": {"inside": [{"rows": [...]}, {"rows": [...]}, {"rows": [...]}]}`. The sheet has 141 tiles, the rules number them, and
   `tilemap.retile` re-picks the tiles of a painted map. With fewer variants than variations the build warns with the tiles that
   repeat.
5. Change a part later and run `image.tileset.build` again (only the part), or `assets.regenerate {"stale": true}`.

The `Tilemap` side (the `terrains` field, `tilemap.paint_terrain`, `retile`, `terrains`, `set_terrains` and the script calls
`paintTerrain`, `eraseTerrain`, `retile`, `terrainAt`) is described in [AI_GUIDE.md](AI_GUIDE.md), section 9.8, and
[SCRIPTING.md](SCRIPTING.md).

## The Image panel

The editor opens a document in the Image panel (View > Image, or a double click on a `*.image.json` in the Project panel):
a canvas with the composite, a layer list and inspector, brush, fill, eraser and picker, the five selection tools, a transform box, the
adjustment and effect lists with live previews and a frame strip. It is a front end for the commands of this page, not a second
editor: every edit it makes calls the same command (`image.layer.add/set/move/remove`, `image.select`, `image.edit`, `image.paint`,
`image.pixel`, `image.draw` and `image.palette`), the brush and the transform use the functions of `fa/tooling/image_paint.h` that those commands
use, and the canvas is drawn by `composite_image_document`. So a stroke you paint is the stroke `image.paint` writes, pixel for
pixel (in tile mode too: the brush and a move wrap around the edges of the tile in the panel as they do in the commands), and an AI and a person can take turns on the same document. An edit writes the document at once; the PNG next to it is baked
by **Save** (the panel says "not baked" until then), the way `image.save` bakes. Each edit is one step of the editor's Undo. The panel's
section of [EDITOR.md](EDITOR.md) lists the tools, shortcuts and what is kept only for the session.

An **svg** layer is edited in the Vector panel: its inspector has **Edit in Vector panel**, which opens that layer's SVG there (the
`source` file, or the inline text of the layer). The Vector panel runs the `vector.*` commands with `document` and `layer`, so each edit
is written into the layer at once, with `bake: false`, and the Image panel shows the new picture; **Save + bake** in the Vector panel (or
**Save** in the Image panel) calls `image.save`, which bakes the PNG. An svg layer is an ordinary SVG there: ids, groups and transforms are
kept, so the layers of the drawing (its groups) can be hidden, locked, renamed and reordered in the Vector panel's own layer list.

## Pictures from a provider

An image provider ([AI_PROVIDERS.md](AI_PROVIDERS.md), "Asset providers") can paint inside a document. The picture always arrives as a
`provider` layer with its provenance, so it can be hidden, moved, masked or removed like any other layer, and the rest of the document
is untouched. Two commands make one, and both need a provider assigned to `assets.image` (or a `provider` argument):

- `image.inpaint {path, selection, prompt, layer?, frame?, name?, selectionName?, seed?, references?, style?, quantize?, provider?, model?, author?, dryRun?, bake?}`
  sends the composite of the document (or `layer` alone, at `frame`) and the selection as the **mask** to a provider that can
  inpaint, and adds the answer as a layer over the whole canvas whose `pixels` mask is the selection, feather included. `selection`
  is the name of a stored selection (`image.select`), `"all"`, or an object with the arguments of `image.select`, which is stored
  under `selectionName` (default `inpaint`) so you can reuse it. A picture smaller than 512 px on its longest side is magnified by
  whole pixels before it is sent and the answer is shrunk back, because providers need room to paint.
- `image.generate_layer {path, prompt, selection?, size?, placement?, transparent?, name?, ...}` adds a generated picture: the whole canvas by
  default, or `size` `{width, height}` at `placement` (`"center"`, `"fill"` or `{x, y}`). A `selection` masks it so it shows only there.
  `transparent: true` asks for a transparent background (sprites, props).

Both take `dryRun`, which returns the plan (provider, model, the size that would be sent, the selected pixels, how many images) and sends
and writes nothing, and `seed`, which is recorded in the layer's provenance when the provider takes one (`fake`, an `asset-command` with
`{seed}`). Both are synchronous and cost what the provider charges for one image, so look at a `dryRun` first and use the `fake` provider
(`"provider": "fake"`) to try a flow for free. A `provider` layer is **never regenerated by itself**: the PNG and its provenance are the
record of what was paid for, the bake only reads it, and the PNG has no recipe, so `assets.regenerate` has nothing to run. To try again, call the
command again (with another `name`, or remove the old layer first), which is the choice to pay twice.

The layer carries `provenance` (`provider`, `model`, `prompt`, `seed`, `references`, `license`, `author`, `notes` with the selection and
the source) and the PNG is recorded in `assets.json`, so the baked picture counts as AI-made. The house style (`style.prompt` and
`style.references` of `assets.json`) is added to the prompt unless `style: false`. The layer's PNG is written next to the document, in
`<document>.layers/`.

**Palettes.** In a document with a palette (an indexed document) the answer is reduced to it with the pixel-art downscale (palette colours
only, no blends, no new colours); `quantize: false` keeps the provider's colours. `quantize: true` in a document without a palette is an
error that says to give it one.

**Without a provider**, or with one that cannot inpaint, the command fails with the code `no_provider` and an error that says what is
missing, how to configure one (`ai.json`, AI Settings, [AI_PROVIDERS.md](AI_PROVIDERS.md)) and the offline route with the exact commands
for this document: `image.edit` fills a selection, `image.paint` and `image.draw` / `image.pixel` draw inside it, `assets.generate_texture`
and `assets.rasterize_svg` make a picture you add with `image.layer.add`, and `svg`, `gradient` and `procedural` layers draw it directly.
Providers that can inpaint: the built-in `openai` (the `/images/edits` endpoint, where the transparent pixels of the mask are the ones
repainted), `fake` (a placeholder pattern, deterministic, offline) and an `asset-command` provider whose `argv` has `{input}` and `{mask}`.

`image.layer.add_provider {path, source, provenance, name?, selection?, x?, y?, parent?, index?, opacity?, blend?, bake?}` is the second
half of both commands and never calls a provider: it adds a `provider` layer from a PNG of the project (made outside the engine, or by a
script), copies `selection` next to it as the layer's `pixels` mask (so editing the selection later does not move the mask) and requires
`provenance.provider`. Unlike the two commands, it does not write the PNG's record into `assets.json`: `assets.set_provenance` does.

In the Image panel the layer list has **Inpaint selection...** and **Generate layer...**. Each asks for a prompt, calls the same planning,
provider call and storing as the commands (the call runs in the background, with a Cancel button) and adds the result as one undo step.
They are disabled, with a tooltip that teaches the same things, when no image provider is configured or the configured one cannot
inpaint, and Inpaint also needs a selection. A picture that arrives after another document was opened is not added to it.

## Validation

A document is checked completely before anything is drawn: every problem is collected, and the error names the file, the
JSON pointer, what is wrong and how to fix it, with "did you mean" for names:

```
art/bad.image.json /layers/1/blend: Unknown blend mode 'multiplyy'. (and 2 more problems)
  hint: Did you mean 'multiply'? Blend modes: normal, multiply, ...
```

- Unknown kinds, blend modes, mask types, adjustment and effect types, fonts and unknown keys, with a suggestion.
- Wrong types and values out of range (`opacity` 2, a canvas of 0 or 5000 pixels, stops out of order, `clip` on the bottom layer).
- A `source`, mask picture, SVG or font that is not in the project (or climbs out of it).
- A `procedural` layer's `texture` arguments are checked by the texture generator (a wrong preset lists the real ones).
- A `tile` that does not divide the canvas; a `tileset` layer's mode, odd or missing tile size, `columns`, `variations` and parts (a
  missing required part, a picture that is not exactly one tile big, a part with two of `source`, `rows` and `color`), each with its pointer.
- An `indexed` layer's `rows` (equal lengths, valid characters, indices inside the palette) and the `palette` and `ramps` (unique names, unique opaque colours, at most 81, ramps that name palette colours), each with its pointer.

`factoria validate` reports a document that does not load as an **error** (file, pointer, hint), and a document never baked,
or whose PNG `assets.json` does not record as its bake, as a **warning** with the `image.bake` call. `factoria export` bakes
every document whose PNG is missing or stale before it packs the game (so the PNG ships), and stops, before it writes
anything, when a document does not load.

## For code that builds on this

`fa/tooling/image_doc.h` (library `fa_tooling`, no GPU): `parse_image_document` / `load_image_document` (all problems in
`ImageIssue`s), `composite_image_document` (-> `Image` straight RGBA8 plus the files read), `bake_image_document`,
`image_bake_status` (`Fresh`, `Missing`, `Stale`, `Unrecorded`, `Broken`), `save_image_document` (what an editor or a command
calls after changing the JSON), `list_image_documents` and `bake_image_documents_if_needed`.
