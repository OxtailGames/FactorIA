# Images: frames, tags and tiles

[Images](../IMAGES.md) > Images: frames, tags and tiles

## Frames and tags

A document becomes an animation when it has several frames. The layers stay as they are; each `pixels` or `indexed` layer
gets a picture (a **cel**) per frame, and the bake is a **sprite sheet** (the frames in a grid) plus the `sheet` entry of
`assets.json` with one SpriteAnimator **clip** per tag. A game plays a tag by its name: `SpriteAnimator {"clip": "bounce"}` or
`entity.spriteAnimator.play("bounce")` ([ANIMATION.md](../ANIMATION.md)), with `Sprite.texture` the baked PNG. A document without
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
commands. `flat: true` keeps the old import (one PNG sheet and its clips, no document), see [ASSETS.md](../ASSETS.md), "Aseprite".

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

### Frame and tile commands

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
`paintTerrain`, `eraseTerrain`, `retile`, `terrainAt`) is described in [AI_GUIDE.md](../AI_GUIDE.md), section 9.8, and
[SCRIPTING.md](../SCRIPTING.md).
