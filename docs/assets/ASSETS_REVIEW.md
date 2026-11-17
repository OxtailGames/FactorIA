# Assets: checking, choosing and store art

[Assets](../ASSETS.md) > Assets: checking, choosing and store art

### Checking a sheet: assets.preview_sheet

`assets.preview_sheet {"path":"assets/art/coin_spin.png"}` draws the sheet as a labelled grid (a temporary picture, returned as
`$image`, that an AI can look at): the frame numbers (`f0`, `f1`...), the frame rectangle (cyan) and the cell edge (grey,
which differs from the frame when there is `padding`), and the pivot (a magenta cross). `clip` shows only that clip's frames
(an unknown name is an error with the clip list and the closest name); `onion: true` overlays the previous frame in red and the
next in blue at 40% so you can see how far things move between frames. The grid is the `sheet` entry of the texture, or the
arguments `columns`, `rows`, `frameWidth`, `frameHeight` and `padding` when the sheet has none (without either the error
`no_grid` says what to pass). `scale` and `tileColumns` set the size and the layout of the picture. It reads the sheet and writes
only the temporary picture, and its `warnings` are the checks: the grid does not match the image, more frames than the grid
holds, a clip outside the sheet, an empty frame, ink touching the edge of the cell, the drawing jumping between frames (the
centre of its ink moves by more than 30% of the frame) and a looping clip whose last frame jumps from the first or repeats it.
The result also has `frames` (for each shown frame: `empty` and the `bbox` of its ink in frame pixels) and `nextSteps`.
The Project panel plays the same clips (see [EDITOR.md](../EDITOR.md)).

### Judging a set of assets: assets.contact_sheet

`assets.contact_sheet {"paths":["assets/hero.png","assets/slime.png"],"sizes":[32,64]}` draws the pictures side by side at the
size the player sees them, over a light background, a dark one and the clear colour of the first primary camera of the main
scene, plus a last row in greyscale (`greyscale: false` leaves it out). Each column is labelled with the file name and its size
in the font that comes with the engine. It is the way to see what disappears: an outline that vanishes when small, a shape that
merges with one background, two sprites with the same value in greyscale. The result is a picture returned as `$image` (like
`assets.preview_sheet`); nothing is written unless you pass `path`, and an existing file is then not replaced without
`overwrite: true`. The same inputs give the same picture (CPU only, except models).

- `sizes` are pixels of the longest side as the player sees it (Sprite.size on screen times the render scale); each picture is
  drawn once per size, shrunk with averaging or grown with hard pixels. Without `sizes` a picture is drawn at its native size
  (at most 512).
- `backgrounds` (1 to 6 colours, such as `"#3a7d44"`) replaces the default rows; the camera colour is then not added.
- `columns` (default 8) sets the cells per line; the picture grows downwards and is capped at 2048 pixels (a warning says so).
  More than 160 cells is an error.
- A PNG, JPG, BMP or TGA is drawn as it is. A sprite sheet (a `sheet` entry in assets.json) shows its first frame, or every
  frame with `allFrames: true`.
- A `.glb` is drawn as a thumbnail by the renderer (studio light, turned three quarters, transparent around it). That needs a
  graphics device: without one the command fails with `no_gpu`, and you can leave the models out. A model in the real scene,
  with its lighting, is `assets.preview_in_scene`.

The result has `warnings`, `nextSteps` (they name `assets.preview_in_scene`, `game.screenshot` and `assets.preview_sheet`) and
`backgrounds`, `rows`, `cells`, `picture` (width, height, scale) and `written` (with `path`).

### A new asset in a real scene: assets.preview_in_scene

`assets.preview_in_scene {"path":"assets/hero.png","scene":"scenes/level1.scene.json","at":[0,0]}` places a PNG as a `Sprite`
(or a `.glb` as a `MeshRenderer`) in a copy of the scene running in a second, headless engine, and returns screenshots at phone
(540x1170) and desktop (1280x720) resolutions, as one picture with the screens side by side and labelled (the MCP result
carries a single image). `resolutions` takes `"phone"`, `"tablet"` (1024x768), `"desktop"` or `"WxH"`, up to four. The scene
file is never changed and no temporary entity is left: the asset exists only in that second engine. It needs a renderer; headless
without a graphics device it fails with `no_gpu` and says to use `assets.contact_sheet` or `game.screenshot`.

- Position: `at` ([x, y] or [x, y, z]) or `entity` (an entity of the scene). With `entity`, `placement: "beside"` (default)
  puts the asset to the right of it (the gap is a rough estimate from the entity's `Sprite` or `Shape2D` size, else 64 units)
  and `"replace"` puts it at the entity's position with that entity hidden in the picture. `offset` ([x, y]) moves it from there.
  With neither, it goes to the middle of the view.
- `size`: for a sprite a number (longest side) or [width, height] in world units, default its size in pixels; for a model its
  largest dimension in meters, default its own size.
- `steps` (default 2) is how many frames the scene runs before the asset is placed, so scripts and spawners have started.
- `center: true` (2D scenes) moves the camera onto the asset so it is in view at every resolution; a camera script can move it
  back. Without it an asset outside the view is a warning that says where it would land.
- The size of the screens comes from the resolution you ask for, not from the project's design resolution.

The result has `asset`, `scene`, `screens`, `sceneFileChanged: false`, `warnings` and `nextSteps`.

### Choosing between candidates: review.sheet and review.pick

`review.sheet {"items":[{"image":"assets/hero_a.png","candidate":true},{"image":"assets/hero_b.png","candidate":true}],"label":"Which hero?"}`
puts N candidates on ONE picture, each in a cell with a big number (1..N, in the order of `items`), its label and one line of facts, so
a person answers with one number. The picture comes back as `$image` and is kept in the project: `.factoria/review/sheet-NNNN/` holds
`sheet.png`, `thumbs/NN.png` (each thumbnail alone) and `manifest.json`. The guide to the loop (make N, show one sheet, ask for one
number) is [AI_GUIDE.md](../AI_GUIDE.md), section 9.32.

Each item has exactly one of these keys, plus `label` (default: the file name) and `candidate`:

| Key | What is drawn | The line of facts | GPU |
|---|---|---|---|
| `image` | the picture as it is (shrunk with averaging, grown by a whole factor with hard pixels) | size, colours (counted up to 1000), % clear | no |
| `vector` | the .svg rasterized like `assets.rasterize_svg` | size, shapes and colours (counted from the file's text) | no |
| `level` | `tilemap.generate` with these arguments (`seeds`: one thumbnail per seed); one square per cell, a letter on it when it is big enough | size, seed, tries | no |
| `scene` | the scene started and run for `steps` frames (default 2), then captured | entities, picture size | yes |
| `prefab` | spawned on a plain stage and framed: 2D from its visuals, 3D turned three quarters under a studio light | entities, size | yes |
| `vfx` | the middle picture of `vfx.filmstrip`, over a dark stage or the scene given as `stage` | peak particles, length | yes |

- A level's `sample` takes the forms of `tilemap.generate`: ASCII rows as an array of strings (with `legend` next to it), an object
  `{rows, legend?}`, one string with line breaks, the project path of a `.json` rows file, or the id or name of an ENTITY WITH A TILEMAP.
  Only the entity form needs a scene to look the entity up in: the project's main scene (`mainScene` in `factoria.json`), or the scene
  the item names with `sampleScene` (`{"level":{"sample":"town","size":[40,24]},"sampleScene":"scenes/town.scene.json","seeds":[1,2]}`).
  The scene is read, never changed, and the manifest keeps it as `spec.sampleScene`, so `tilemap.generate` afterwards sees the same
  entity. With neither a main scene nor `sampleScene` an entity sample is an error with the JSON pointer. `maxSeconds` of a level is
  not fixed by the sheet (the 1800 CPU seconds of `tilemap.generate` are only a safety net); `maxWork` is, at 20 million unless set.
- Items that need a GPU fail the whole command with `no_gpu` before any file is written, like `assets.preview_in_scene`; images, vector
  art and levels need none, and the same input gives the same thumbnails on every machine.
- Limits: 48 items (a level's `seeds` count one each), 12 columns, a thumbnail of 64 to 512 pixels (`thumbSize`; by default chosen
  from the number of items, about 1800 pixels wide) and a sheet of at most 8192 pixels a side and 16 million pixels. A level thumbnail
  is generated up to 1024 cells a side, with `maxWork` 20 million unless the item sets it. A request over a limit, a level with `into`,
  or `seed` together with `seeds` is refused first, with the JSON pointer of the item and what to change. Each picture is fitted into
  its thumbnail as soon as it is drawn and the original is dropped, a picture whose header announces more than 64 million pixels
  (PNG, JPG, BMP or TGA) is refused before it is decoded, so a sheet of 48 big pictures stays small.
- `candidate: true` is for files you made for the choice: it needs the right kind of file (`.png/.jpg/.bmp/.tga`, `.svg`,
  `.scene.json`, `.prefab.json` or `.vfx.json`, so `factoria.json` and `assets.json` can never be one), never the main scene, anything under
  `.factoria/` or `.git`, nor a file that another item shows or plays in as the `stage` of an effect. The request is refused with the
  pointer of the item, and `review.pick` checks every file again before it moves it (the manifest is a file anyone can edit), through
  the same project-path rules as the other commands (no absolute path, no `..`, no link that leads out of the project).
- `meta` is your own small object (at most 4096 bytes as JSON, for example `{"slot":"hero"}`): `review.sheet` stores it in the manifest
  and `review.pick`, `review.info` and `review.list` return it untouched.
- An item that cannot be drawn (a corrupt picture, a level the solver could not make in its attempts) is a red tile that
  `review.pick` refuses, with the reason in `warnings`; if no item can be drawn nothing is written.
- The manifest (`factoria.review/1`) records each item (`n`, `type`, `label`, `source`, `candidate`, `info`, `numbers`, `spec`, where its
  cell and picture are on the sheet), when the sheet was made (from the engine's clock), and `picked`: null until `review.pick`
  answers. `review.list` and `review.info` read it, and the files are plain JSON and PNG, so any tool can list the sheets and their history.

`review.pick {"sheet":"latest","n":2}` records the number the person chose (who picked, when, an optional `note`, and the item's
`spec`, so a picked level's seed is kept). With `drop` (default true) it MOVES the files of the other items that were marked
`candidate: true` to `.factoria/review/dropped/<sheet id>/<NN>_<file name>` (another folder below `.factoria/` with `dropDir` on the
sheet); the pick itself deletes nothing (`review.cleanup` deletes the dropped files 7 days later; `droppedDays: 0` keeps them), and the result and the manifest list each move (`from`, `to`), so moving a file back undoes it. The
picked item's file, files that are not marked, the main scene and files in `.git` are never moved, and `assets.json` is not edited
(the result warns when it still lists a moved file). It is all or nothing: if a move fails (code `busy` when the file is open in another
program, `failed` otherwise) the ones already made are put back and the manifest does not change; a leftover in the drop folder (`exists`) stops it before any move. The manifest is changed under a lock in
`.factoria/review/`, so the editor, the CLI and an agent can use sheets at the same time. A sheet can be picked once. A crash (a power cut) between the moves and the manifest write leaves the moved files in the drop folder
with the sheet still unanswered: pick again (a file that is already gone is reported, not an error), or move the files back by hand.
`dropDir` is a folder below `.factoria/`, not `.factoria/tmp`, not `.factoria/review` itself and not another sheet's folder.

**Housekeeping.** The files a pick moved are kept 7 days after the pick; `review.cleanup` (it also runs after every new `review.sheet`;
failures there are only warnings) then deletes them, marks them `expired` (or `gone` when they were moved back) in the manifest and
removes the empty folder. It only deletes the file `<dropDir>/<sheet id>/<NN>_<name>` that a pick recorded, never the chosen file, never
anything of a sheet nobody answered, and `droppedDays: 0` keeps them for ever. A sheet folder without a manifest (the process died while
it was made) is listed by `review.list` as an `orphan` and removed by `review.cleanup` once nothing in it changed for 60 minutes
(`orphanMinutes`). `dryRun: true` reports what would go and deletes nothing.

**Over MCP and the CLI nothing asks the person: `review.pick` must get the number THEY gave you.** Never choose for them: ask in the conversation, show the sheet,
wait for the number.

### Candidates for one asset: assets.generate_image count and assets.pick

`assets.generate_image {"prompt":"a red potion bottle","path":"assets/items/potion.png","width":64,"height":64,"count":3}` makes
three candidates for the slot `assets/items/potion.png` instead of the file itself, and one review sheet that shows them:

- The candidates are written next to the slot as `potion.candidate-1.png`, `potion.candidate-2.png`... (`count` is 1 to 4; 1 is the
  plain call that writes the slot). Each has its own seed (`seed`, `seed+1`...; without `seed` the first comes from the prompt, so the
  same prompt gives the same seeds) and its own provenance in `assets.json`, with `candidate: {slot, n, count}`.
- Everything that can be refused is refused before the provider is called: a `count` out of 1..4 (with the pointer `/count`), a slot
  that exists, candidate files that exist (left by an earlier call) unless `overwrite` is true, and a slot path so long that the sheet's
  `meta` would pass its 4 KB limit. With `overwrite`, a file replaced that `assets.json` did not record as a candidate of this slot
  is named in `warnings`. The same prompt without `seed` gives the same pictures again with providers that honour seeds: for different
  ones change the prompt or pass another `seed`.
- The cost estimate, the limits and the approval cover all the candidates at once, before the first picture (docs/AI_COSTS.md,
  "Asset generation"): one question, one yes, for the batch. When the provider fails part way, the error lists the candidates that were
  written (kept, with their provenance), the estimated cost of those, and gives the rest of the estimate back; no sheet is made then.
- The sheet is an ordinary `review.sheet` (the section above): every item is `candidate: true`, its label is the seed, the sheet's label
  is the prompt, its `dropDir` is `.factoria/assets/candidates`, and its `meta` is
  `{"kind":"assetCandidates","slot":...,"command":"assets.generate_image","count":...,"candidates":[...],"overwrite":...,"estimatedCostUsd":...,"sha256":[...]}`
  (`sha256`: of each candidate file as written). The result carries the sheet id, the candidates, the cost, the sheet picture as
  `$image` and the next steps. Only the newest candidates sheet of a slot can be answered: when this sheet replaces one that was not
  answered yet, the result names it in `replacedSheet` and `warnings` (show the new sheet, not the old one).

Show the sheet, ask the person for ONE number, then `assets.pick {"slot":"assets/items/potion.png","n":2}`:

- It answers the newest candidates sheet of that slot, with `review.pick` itself: the same lock, the same file checks, the same all
  or nothing, the choice and `note` recorded in the manifest. `sheet` (an id or its number) must be that newest sheet: an older one
  (its thumbnails may show pictures a regeneration with `overwrite` replaced) is refused with `superseded` and a hint naming the
  current sheet, and so is a candidate whose file no longer matches its `sha256` on the sheet (an edit, or a regeneration that
  failed part way). Plain `review.pick` refuses these sheets and names `assets.pick`.
- Candidate 2 is moved to the slot. The slot's entry in `assets.json` gets that candidate's provenance (prompt, provider, model, seed)
  plus `candidates: {sheet, picked, count, estimatedCostUsd, costIsEstimate}`, and the candidates' own entries are removed.
- The other candidates move to `.factoria/assets/candidates/<sheet id>/NN_<name>`, where `review.cleanup` deletes them 7 days later,
  like the files of any picked sheet. A slot file that exists needs `overwrite` (in the generate call or the pick) and is kept there as
  `00_<name>` for the same 7 days.
- When a file cannot be moved (open in a viewer: code `busy`) or `assets.json` cannot be written, every move is put back and nothing
  changes. A slot whose newest sheet was answered is refused with `already_picked`, never answered from an older sheet (make new
  candidates, with a changed prompt or another `seed`, to choose again); a slot with no candidates sheet is `not_found`, with the slots
  that have one as suggestions.
- Until the pick the candidates are files under `assets/`, so an export would ship them: pick (or delete them) before exporting.

Never pick for the person. The editor's Review window answers these sheets with the same call, `assets.pick {"sheet":..., "n":..., "slot":...}`,
for every sheet whose `meta.kind` is `"assetCandidates"`.

### Checking art: assets.check_art

`assets.check_art {"path":"assets/hero.png"}` (or `{"paths":[...]}`, up to 12 pictures, checked one by one and as a set) looks
at a picture the way the game shows it and returns a temporary annotated picture (`$image`) plus numbers. It reads the
project and writes only the temporary picture (and the cache `.factoria/art-cache/`), and it is deterministic. Every rule in the
result has a `value`, a `threshold` (the limit of `ok`), usually a `failThreshold` (the limit of `warn`), a `verdict` (`ok`,
`warn` or `fail`), a `message` with the numbers of this picture and, unless `ok`, a `hint` that names a real command or setting.
The asset's verdict, the result's and the `counts` are the worst of their rules.

Arguments:

- `backgrounds`: what the picture is drawn over, a list of colours (`"#203040"`, a name, `[r, g, b]`) and project image
  paths (an image stands for its dark, middle and light parts). Without it: the clear colour and the large background sprites (covering at
  least half of the view, on a lower layer) of the scenes that draw the picture, else a light and a dark default.
  `assets[].backgrounds.source` says which: `explicit`, `scenes` or `default`.
- `onScreenPx`: the longer side of the sprite on screen, in screen pixels (a number or up to 4). Without it the size comes from
  the scenes (Sprite size, the scale of the entity and its parents, the camera's `orthoSize`) on two reference screens: a phone, 844 x 390
  points, and a desktop monitor, 1920 x 1080 (turned for a `portrait` project), with the design resolution of
  `factoria.json` `display` fitted inside (`fit`). A picture no scene draws is not judged for readability (a `note` says so).
- `style: false`: skip the rules of `style` (below).

The rules (default thresholds; `style` rules override only what they set):

| Rule | What it measures | ok | warn |
|---|---|---|---|
| `contrast` | per background: the WCAG contrast ratio of the silhouette edge pixels (over the background) | at least 3:1 | at least 1.5:1 |
| `readability.size` | per screen: the longer side of the sprite on screen | 16 px or more | 8 px or more |
| `readability.silhouette` | share of the silhouette still there after shrinking to the on-screen size | 85% | 60% |
| `readability.edge` | thickness of the outline line on screen (only when the picture has one) | 0.7 px | 0.4 px |
| `fringe.partial` | share of the partly transparent edge pixels that are darker or lighter than every opaque pixel they touch | at most 10% | at most 30% |
| `fringe.bleed` | share of the transparent pixels next to the shape that hold a far colour, for a picture drawn with a smooth filter | at most 20% (warn above) | |
| `outline.color` | share of the edge pixels near the colour of `style.outline` (RGB distance up to 48) | 80% | 50% |
| `outline.width` | median thickness of the outline against `style.outline.width` | within 1 px | within 2 px |
| `value.min`, `value.max` | the darkest and the lightest pixels against `style.value` | inside, or up to 0.05 beyond | up to 0.15 beyond |
| `saturation.min`, `saturation.max` | mean saturation against `style.saturation` | inside, or up to 0.05 beyond | up to 0.15 beyond |
| `lightDirection` | which way the shading gets brighter against `style.lightDirection` | within 45 degrees | within 90 degrees |
| `pixelArt.edges` | share of partly transparent pixels (`style.pixelArt`) | at most 1% | at most 5% |
| `pixelArt.colours` | distinct colours (`style.pixelArt`) | at most 64 | at most 256 |
| `palette.offShare` | share of pixels farther than 40 (2 for pixel art) from every colour of `style.palette` | at most 20% (0.1% pixel art) | at most 50% (2%) |
| `texelsPerUnit` | texture pixels per world unit, median of the scenes' uses, against `style.texelsPerUnit` | within 15% | within 35% |

Anything beyond the `warn` limit is `fail`. Style rules need the rule to be set in `style` (and `style.ignore` removes the
file); a rule the picture cannot answer is left out of the result (no silhouette, a light with no clear lean,
`texelsPerUnit` of a texture no scene draws). `fringe.bleed` does not mean the file is wrong:
a picture with black transparent pixels is normal, and it only shows as a dark line when the sprite is drawn with the smooth filter (set
`Sprite.pixelArt` true for pixel art). The edge pixels of a picture are those with alpha of at least 128 next to a pixel under 128. A sprite
sheet is measured in its cells, so the light does not mix frames.

With `paths` the result also has `set.rules`: `set.density` (the pixel density of the scenes' uses differs by more than 15%
between two pictures, warn above 50%), `set.pixelSize` (pixel art drawn with different pixel sizes), `set.outlineColour` and
`set.outlineWidth` (pictures with an outline that differ: the colour by more than 48, warn; the thickness by 1 px), and `set.paletteSpread` (the share of
pixels with a colour that no other picture has, within 24: ok up to 60%, warn up to 90%). Set rules are `warn` at most
(except density and the spread, which can be `fail`).

The picture has one row per asset, with numbered tiles listed in `assets[].tiles`: the picture on a checkerboard, its value
(greyscale on grey: is the shape readable without colour?), the picture over each background, and the picture at each
on-screen size (shrunk, then magnified by whole steps so you see what a player sees). The result has `assets[]` (`palette`
with the commonest colours, `measure`, `backgrounds`, `onScreen`, `scenes`, `rules`, `tiles`, `notes`), `set`, `style` (whether
rules were applied, and any `problems` found in `style`), `picture` and `nextSteps`. The rules are the very ones
`factoria validate` uses for the style, so a fix that clears one clears the other.

sky-hopper adopts it as the example: its `assets.json` `style` sets `texelsPerUnit` 1, `saturation` 0.3 to 0.9 and `ignore`s the two sheets that are baked at twice the size (`assets/crawler_sheet.png`,
`assets/parts_atlas.png`). Its art was not repainted, and `factoria validate` is clean.

### Reviewing art: assets.review

`assets.review {"path":"assets/hero.png","focus":"does the outline match the references?"}` (or `{"paths":[...]}`, up to 4 pictures
as a set) is the optional last look of the loop *make, preview, check, fix*: one call to a vision model, made by the AI that is
building the game (the user-only art critics of `ai.review` are a different, costlier thing). It is **grounded**: it first runs
`assets.check_art` on the same pictures, then sends the model the check's numbers (every rule with value, threshold, verdict and
hint), the `style` of `assets.json` as written, the `style.references` images (the first 3 that exist), the pictures (a file over
1 MB is shrunk to 1024 px on its long side) and the annotated picture of the check. The model is asked what numbers cannot say:
does it match the references and the style, does it read at its on-screen size, does it suit its use, are there artifacts.

Result: `verdict` (`good`, `fix` or `redo`; never `good` while the check has a `fail`), `summary`, `fixes` (each `{what, where,
command}`: the problem and the change, the picture and the part of it, and the command or `assets.json` setting to use), `checkArt`
(the check's verdict, counts, per-asset measures and rules), `role`, `provider`, `model`, `warnings` (a style reference that could
not be sent, a fix that names a command this engine does not have, a `good` overruled by the check) and `nextSteps`. It writes
nothing to the project.

It needs a model that accepts pictures. It uses the "fast" role of `ai.json` (the orchestrator when fast is off), because it is a
cheap one-shot question and the "artist" role is usually an image generator, not a viewer. API providers get the pictures as image
blocks (Anthropic) or `image_url` data URLs (OpenAI-compatible: OpenAI, Gemini, Ollama...); a CLI agent gets them inline or as
files in its empty work folder; a provider that only makes assets is refused. With no provider, no key or a text-only model it fails
with `no_model` or `review_failed` and a hint, and the loop goes on with `assets.check_art` alone. Call it once the check shows no
`fail`, not after every edit: each call is a paid request.

### The game icon without a provider: assets.draw_icon

A game made without an image provider still gets a real icon. `assets.draw_icon` draws one from a short description,
on the CPU (anti-aliased, the same bytes on every machine, no GPU, so it works headless and in CI), and writes the
1024x1024 icon plus the Android adaptive-icon foreground (432x432, transparent). They go where the export already looks:
`path` defaults to the `icon` of `factoria.json` (else `assets/icon.png`), `foreground` to
`export.android.adaptiveIcon.foreground` (else `assets/icon_fg.png`; `false` writes none). A path `factoria.json` does
not name yet is added to it. Provenance is recorded as `original`, not AI. Existing files are replaced, so change the
description and call again.

Drawing space: x and y run 0..100 across the icon, origin top-left, y down; every size and radius is in the same units
(shapes may reach past 0..100: the icon crops them). The foreground scales that 0..100 box into the 66/108 safe zone of the
adaptive layer, so nothing inside it is cut by a launcher mask. `background` is `color` (optional `colorBottom` for a
vertical gradient) and `shape`: `square` (the default: fills the canvas, what the stores want), `rounded`, `circle` or
`transparent`. `layers` are drawn in order:

| `type` | Fields |
|---|---|
| `rect` | `x`, `y` (top-left), `w`, `h` |
| `roundRect` | `x`, `y`, `w`, `h`, `radius` |
| `circle` | `x`, `y` (centre), `radius` |
| `ellipse` | `x`, `y` (centre), `rx`, `ry` |
| `polygon` | `points`: `[[x, y], ...]` |
| `text` | `text`, `x`, `y` (centre of the text), `size` (em height), `font` (a project `.ttf`; default DejaVu Sans), one line, no shaping |

Shapes take `fill` and/or `outline` (colours `"#rrggbb"`, `"#rrggbbaa"` or names), `fillBottom` (gradient from `fill`
at the top of the icon to this colour at the bottom), `outlineWidth` (default 2) and `softness` (feathers the edge: a
glow). Text takes `fill`. `"foreground": false` on a layer keeps it out of the Android foreground (a backdrop: the
adaptive icon has its own background colour, `export.android.adaptiveIcon.background`). Unknown keys and types are errors
with a JSON pointer and a suggestion.

```json
{"background": {"color": "#141428", "shape": "square"},
 "layers": [{"type": "circle", "x": 50, "y": 50, "radius": 30, "fill": "#ffcc44", "outline": "#ffffff"},
            {"type": "text", "text": "K", "x": 50, "y": 50, "size": 34, "fill": "#141428"}]}
```

Run it with `factoria call assets.draw_icon @tools/icon.json` (keep the JSON in the project) and look at the PNGs.
The Lantern Keep example draws a lantern this way (`examples/lantern-keep/tools/icon.json`, if you got it with `project.create {example: "lantern-keep"}`); the format above is all you need to draw your own (the example's is a lantern of 16 layers).

### Store page images without a provider: assets.draw_capsules

`assets.draw_capsules` makes the images of the store pages (capsules, heroes, covers) from one piece of key art, at the size
each store asks for (the table is in [EXPORTING.md](../exporting/EXPORTING_STORES.md#store-page-material), as of 2026-10). `keyArt` is an image
in the project, usually a screenshot taken natively large (`game.screenshot {scale: 1.5}`, or `factoria run --render-scale 1.5`).
It is cover-cropped around `focus` (`[x, y]`, fractions of the art; default the middle) and written to
`store/capsules/<store>/<name>_<w>x<h>.png` (`name` defaults to the project name; files are replaced; `overwrite: false`
keeps them). `stores` picks from `steam`, `epic`, `gog`, `microsoft`, `googleplay`, `appstore`, `itch` (default all).

The `logo` is `{"image": "assets/logo.png"}` (a PNG with a transparent background) or `{"text": "My Game", "font", "fill",
"outline"}`, the title drawn with the text rasterizer of `assets.draw_icon` (white with a dark outline by default;
`"outline": false` for none). Each asset has a rule for it: capsules and covers get it centred, Microsoft's posters and box art
in the upper part, heroes, page backgrounds and screenshots none, and Steam's library logo and Epic's logo are a transparent
PNG with only the logo (skipped when no logo is given). `orientation: "portrait"` turns the phone and tablet screenshot sizes
of Google Play and the App Store. The result lists every `written` file with its size.

```
factoria call assets.draw_capsules '{"keyArt":"store/keyart.png","focus":[0.5,0.4],"logo":{"text":"Lantern Keep"},"stores":["steam"]}'
```


#### Scoping the style rules

The rules fit the art of the game, not every picture in the folder: an interface picture is never on a mesh and a flame lights
itself. Three ways to leave a rule out, from the narrowest:

- `style.ignore {path, rules?}` records an entry in `style.ignore`: `path` is a file, a folder ending in a slash or a glob
  (`assets/fx/**`). With `rules` (`outline`, `value`, `saturation`, `lightDirection`, `texelsPerUnit`, `pixelArt`, `palette`, or a
  sub-rule such as `value.max`; a name also covers the rules under it) only those rules are skipped and the others still check, so
  a real problem is not hidden; without `rules` every rule is skipped for the path (the plain-string entry). `remove: true` takes an
  entry, or the named rules of it, back. In assets.json: `"ignore": ["assets/old/**", {"path": "assets/fx/spark.png", "rules": ["outline"]}]`.
  An entry with no `rules` already skips every rule, so naming rules for it changes nothing (the result says so in `notes`); to
  narrow it, remove the entry and add the rules. Skipping every rule for a path that had only some rules widens the entry (also said in `notes`).
  `path` is a project path: a `..` segment is refused, a name such as `a..b.png` is fine.
- A **role**: `style.set_role {path, role}` writes `style.roles` (`{"assets/ui/**": "ui"}`; `remove: true` deletes the glob), and
  `assets.set_provenance` accepts `role` for one asset (it wins over a glob; assets.set_provenance without `role` keeps it, and
  `assets.regenerate`, importing the file again, `assets.generate_image`, `assets.generate_texture` and `assets.draw_icon` over the file keep it too). `role: ""` (or null) in
  `assets.set_provenance` takes the asset's role back. `ui` and `icon` turn off `texelsPerUnit` and `lightDirection`;
  `effect` also turns off `outline`, `value` and `saturation`. The other rules keep checking.
- `texelsPerUnit` is only judged for textures a scene draws; a texture no scene uses is left out already.

`assets.check_art` still checks a file you name, applies the rule-level entries and roles, and lists what it left out under
`styleSkipped` (`{rule, reason}`: the `style.ignore` entry, or the role and whether it came from provenance or a glob) and
`role` (`{role, from}`); `factoria validate` applies the same scope.
