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

## Pages

- [Images: effects, baking and commands](images/IMAGES_EFFECTS_COMMANDS.md): Adjustments and effects, baking and staleness, the commands, and normal maps (`image.normal.generate`, the `normal*` adjustments, painting a slope, the PNG for `Sprite.normalMap`).
- [Images: pixel art](images/IMAGES_PIXEL_ART.md): Pixel art drawing, palettes and tools.
- [Images: frames, tags and tiles](images/IMAGES_FRAMES_TILES.md): Animation frames and tags, tiles.

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
