# Layered images: `*.image.json`

A layered image is a small JSON file that is the SOURCE of a picture: a canvas and a list of layers (a PNG, a fill, a
gradient, a procedural texture, an SVG, text, a picture from an image provider, a group, an adjustment), each with an
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

Implemented now: adjustments `invert` and `brightness` (`amount` -1..1, default 0.2), effect `colorOverlay` (`color`,
`amount` 0..1). The lists exist so that more operations are one entry in `image_doc_ops.cpp` each; an unknown `type` is an
error that lists the known ones. `fa::image_adjustment_types()` and `fa::image_effect_types()` return them with a description.

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
  effects), whether the document is valid, its bake status, the files it reads and its stored selections. Read-only.
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

`factoria validate` reports a document that does not load as an **error** (file, pointer, hint), and a document never baked,
or whose PNG `assets.json` does not record as its bake, as a **warning** with the `image.bake` call. `factoria export` bakes
every document whose PNG is missing or stale before it packs the game (so the PNG ships), and stops, before it writes
anything, when a document does not load.

## For code that builds on this

`fa/tooling/image_doc.h` (library `fa_tooling`, no GPU): `parse_image_document` / `load_image_document` (all problems in
`ImageIssue`s), `composite_image_document` (-> `Image` straight RGBA8 plus the files read), `bake_image_document`,
`image_bake_status` (`Fresh`, `Missing`, `Stale`, `Unrecorded`, `Broken`), `save_image_document` (what an editor or a command
calls after changing the JSON), `list_image_documents` and `bake_image_documents_if_needed`.
