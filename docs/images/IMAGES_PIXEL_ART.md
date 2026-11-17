# Images: pixel art

[Images](../IMAGES.md) > Images: pixel art

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
  indexed layer uses `style.palette` of `assets.json` ("House style" in [ASSETS.md](../ASSETS.md)); `image.pixel` and `image.draw`
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
- **`ai: true`** on a layer marks its pixels as AI-made; the baked PNG is then recorded as AI-made ([ASSETS.md](../ASSETS.md),
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
[selection](IMAGES_EFFECTS_COMMANDS.md#selections-imageselect): only its pixels, coverage 128 or more, may change) and `scale` / `bake` like `image.pixel`,
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
