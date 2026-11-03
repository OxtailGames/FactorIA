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
  fitted inside `width` x `height` (default the canvas) keeping its aspect ratio.
- **`text`**: `text` (`\n` starts a new line), `font` (default the engine's DejaVu Sans; `"builtin:pixel"` and the other
  built-in fonts, or a `.ttf` / `.otf` of the project), `size` (the em height in pixels), `color`, `align` (`left`, `center`
  or `right` of the layer's `x`) and `lineHeight` (in ems, default 1.2). `y` is the top of the first line.
- **`indexed`**: pixel art as palette indices: `rows` (text), or `width` / `height` for a blank layer, and `ai`. No masks,
  adjustments or effects (see "Pixel art").
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

### Make, look at, export

```json
{"command": "image.create", "args": {"path": "assets/art/hero.image.json", "width": 64, "height": 64,
  "layers": [{"kind": "fill", "name": "sky", "color": "#203040"}]}}
{"command": "image.info", "args": {"path": "assets/art/hero.image.json"}}
{"command": "image.export", "args": {"path": "assets/art/hero.image.json", "out": "assets/art/hero-x4.png", "scale": 4, "filter": "nearest"}}
```

- `image.create {path, width, height, background?, layers?, description?, overwrite?}` writes a new document (it refuses to
  replace one unless `overwrite`).
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
`image.edit` copies or cuts into, or `create: true` makes, is a new layer with the same picture in every frame.

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

A frame or cel you remove leaves its PNG in `<document>.layers/` (and an edited cel makes a new file); nothing deletes a file the
document no longer reads, so remove them by hand if the folder matters.

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
