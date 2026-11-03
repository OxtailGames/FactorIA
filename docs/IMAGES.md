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

A baked PNG is a normal project asset: put it in a `Sprite`, an atlas group, an animation. Edit the document, never the PNG
(the next bake would replace your edit).

## Commands

- `image.bake {path, onlyIfNeeded?}`: bakes the document at `path`. `onlyIfNeeded` does nothing when the PNG is current (the
  recipe matches the document and every file it reads). Returns `{document, path, width, height, written, ai, sha256,
  inputs, provenance, warnings, $image, nextSteps}`.
- `image.save {path, document, bake?}`: checks `document` (the JSON of a layered image), writes it to `path` as canonical JSON
  (2-space indent) and bakes it. A document with a problem is an error and nothing is written.

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
