Part of [EDITOR.md](../EDITOR.md): The asset panels: project, image, vector, sound and music.

# Editor: panels

## Project panel

View > Project (a tab next to Console; the View menu reopens it). A folder tree on the left (**Project** is every file; hidden
folders, `build`, `node_modules`, `dist` and `export` are left out) and the files on the right: a thumbnail for pictures, a
badge (`WAV`, `JS`, `SCN`, `PFB`, `MAT`...) for the rest. Hover a file for its path, type and size.

- **Type filter** (all, texture, audio, font, mesh, script, scene, prefab, material; the same types as `assets.list` and the
  Inspector's file lists, one classifier: `asset_type_of`) and **search** (case-insensitive part of the path; a search looks
  through the whole project, not only the chosen folder). **Sort** by name, type or size.
- The listing is cached: the panel does not read the disk every frame. It reads again on **Refresh**, when you click into the
  panel and after the editor itself writes or deletes a file (a command that changes files, such as `fs.write`, `fs.delete`,
  `prefab.save` or `scene.save`, from you, the Console or the AI; or Save). A file another program adds shows up on Refresh.
- **Drag a file** (the payload `FA_ASSET` is its project-relative path). Onto an Inspector file field: only a file of the field's
  type is taken (a picture on `Sprite.texture`; a sound there is refused) and it is written like picking it from the list.
  Onto the Viewport: a `.prefab.json` is spawned with `scene.spawn {prefab, position}` and the new entity is selected (one Undo
  step). The position is the world point under the mouse: in 2D on the z = 0 plane; in 3D where the mouse ray meets the
  ground plane (y = 0), and 10 units in front of the camera when it misses it (the ray points up or the ground is farther than
  1000 units). Other types do nothing on the Viewport (the tooltip says only prefabs).
- **Double-click** a `.scene.json` to open it (with the same "Unsaved changes" question as File > Open Scene).
- **Sprite sheets.** Select a picture that has a `sheet` entry in `assets.json` and a strip appears under the file list: a menu
  of its clips ("(all frames)" first) and the chosen clip playing, frame by frame at the clip's `fps`, the way a
  `SpriteAnimator` plays it (same code: padding and a non-looping clip's last frame included), with the frame number and
  range. A picture without a `sheet` entry shows no strip.
- **Right-click** a file: **Show in Finder** (Explorer, file manager), **Copy path**, **Delete...** (asks first, then `fs.delete`;
  it is not an Undo step, the file is gone from disk).

## Image panel

View > Image opens the Image panel; double-clicking a `*.image.json` in the Project panel opens that document in it
([IMAGES.md](../IMAGES.md)). It is a floating window the first time (1100 x 720; dock it like any panel) and edits ONE document at a time.
Every edit runs the same `image.*` command an AI would call (`image.layer.*`, `image.paint`, `image.select`, `image.edit`) and the
brush, fill and transform use the code of `fa/tooling/image_paint.h`, so a stroke, a fill or a selection made with the mouse is the
same pixels the command writes. The picture on the canvas is drawn by the one compositor (`composite_image_document`), never a second
one. An edit writes the document (and the layer's PNG) as it happens; the baked picture next to the document is written only by
**Save** (the toolbar shows "baked" or "not baked"; the tooltip of "not baked" says why: stale, missing...), like `image.save`.

- **Toolbar.** The document (a menu of the project's `*.image.json`), **New** (a name and a square size: `image.create` makes `assets/<name>.image.json` with a white background layer),
  **Save**, **Reload** (re-reads the files; the panel also re-reads them by itself when they change on disk and no gesture is
  running), **Fit**, **1:1**, a zoom percentage, **Grid** (a pixel grid from 800% up) and **Checker** (the transparency
  checkerboard).
- **Canvas.** The wheel zooms around the pointer, Ctrl+wheel (a trackpad pinch) too; Shift+wheel and a sideways wheel pan, and so do
  the middle button or Space + left drag. Above 100% the picture is drawn with nearest-neighbour sampling, below it smoothed. The
  selection is outlined with marching ants (they crawl up to 3000 edges, stand still above that, and a selection of more than 60000
  edges is shown as a tint only); **Tint** shows it as a tint as well.
- **Tools** (left column, shortcut in brackets): Move (V), Brush (B), Eraser (E), Fill (G), Picker (I; Alt+click picks with any
  Brush, Eraser and Fill), Rectangle and Ellipse selection (M, Shift+M), Lasso and Polygon selection (L, Shift+L; a click on the first
  point, a double click or Enter closes a polygon, Esc drops it), Magic wand (W) and Transform (T). `[` and `]` change the brush size. The options bar above the canvas has
  the brush colour, size, hardness and opacity, the wand's tolerance and contiguous switch, and the selection operation.
- **Painting** draws on the selected layer, inside the selection if there is one, as one undo step per stroke. On an `indexed` layer
  the brush paints palette indices only (hardness and opacity do not apply). A locked layer or a layer that is not `pixels` or
  `indexed` is not painted on (the status line says why). The right mouse button paints, erases and fills with the secondary colour
  (X swaps the two).
- **Pixel-art tools** (a document with a palette). The **Grid** box draws the pixel grid from a zoom of 800% (a stronger line every 8
  pixels, or at the tile size in a tile document) and the tools that work on one pixel (Fill, Picker, Magic wand) outline the pixel
  under the mouse; the picture is always drawn with nearest-neighbour filtering when zoomed in. The **Tiled** box shows the picture
  repeated 3 x 3 so the seams show (a `tile` document opens with it on; the tools still work on the middle copy). A document that
  has a `tileset` layer gets a **Terrain preview** under the layer list: a small map painted with the sheet's tiles, each one chosen
  from its neighbours by the same autotile rules the `Tilemap` uses.
- **Palette bar** (under the canvas, for a document with a palette). A swatch: left click = primary colour (white frame), right
  click = secondary colour (orange frame). **+** adds a colour at the end (hex and optional name, `image.palette`), **Edit** changes
  the primary colour (every pixel that uses it changes with it), **<** and **>** move it (`image.palette.move`: the pixels follow
  it), **Remove** deletes it (`image.palette.remove`: its pixels take the secondary colour, or become transparent when the secondary
  is the same colour) and **Swap** swaps primary and secondary. Each is one undo step and is off while the game plays.
- **Selections.** Plain drag replaces the selection, Shift adds, Alt subtracts and Shift+Alt intersects (the same as the operation
  menu). All (Ctrl+A), None (Ctrl+D), Invert, Grow, Shrink and Feather are buttons of the options bar. The selection is the stored
  selection `image.select` writes, so a command sees it too.
- **Light** (the last row of the options bar). A preview of the picture lit by a normal map, to see what a normal-map
  edit does without leaving the panel ([Normal maps](../images/IMAGES_EFFECTS_COMMANDS.md#normal-maps)). Turn **Light**
  on and pick the layer that holds the normal map (it starts with the selected layer when that is hidden, else the first
  hidden one; `image.normal.generate` adds a hidden layer). The canvas then draws the picture with every pixel
  multiplied by `max(0, 1 + 2 * strength * (n . L - L.z))`, the formula of the `shade` adjustment, with a lamp that
  follows the mouse (a small marker shows it); **Orbit** circles it instead. **Height** is how far above the picture the
  lamp is, **Strength** how strongly the normals change the colour and **Flip green** reads a DirectX map. It is a look
  only: it writes nothing, adds no undo step and stays on while you paint on the normal layer (a stroke in progress on
  the normal layer, or an operation you are still previewing there, shows in the lit picture once it is applied; the
  rest of the picture is live). The lit picture is made on the CPU from at most 640 pixels on the long side, so a big
  document lights as fast as a small one; the preview says why when there is no picture to light (no layer picked, a
  layer with no pixels...).
- **Provider pictures.** Under the layer list, **Inpaint selection...** and **Generate layer...** ask for a prompt and make what
  `image.inpaint` and `image.generate_layer` make ([IMAGES.md](../IMAGES.md), "Pictures from a provider"): the plan (provider, selection,
  size) is made first, on the same thread as the call and before anything is paid for, so a mistake is shown under the panel as a
  failure with nothing charged; the plan, the cost check and the provider call run on that thread (the
  panel stays usable, a line shows the seconds and a **Cancel** button) and the picture is added as one undo step, selected, as a new
  `provider` layer masked by the selection. The popup shows the estimate for the provider's call (looked up when it opens), and **Make it** is your approval of that cost: the
  spending limits still hold, and a refusal is shown in the panel. The two are off, with a tooltip saying why, when no image provider is configured, the
  configured one cannot inpaint, there is no selection (Inpaint) or the game is running. An answer that arrives after another document
  was opened is dropped with a message instead of being added to it.
- **Transform** shows a box with eight handles around the selected pixels (or the whole layer without a selection): drag a handle to
  scale, inside the box to move, outside it to rotate; Shift keeps the aspect ratio or snaps the angle to 15 degrees. The numeric
  fields of the options bar do the same by value, and the **Nearest** box chooses hard pixel edges (on by default in a document with a
  palette) or smooth ones. **Apply** (or Enter) runs `image.edit` once, **Cancel** (Esc) drops it. It works on the pixels of a
  `pixels` layer only; for another kind the status line says to convert the layer first.
- **Layers** (right column, top layer first): a kind badge, an eye (visible), a padlock (locked), the name (double-click to rename),
  a triangle that opens or closes a group; drag a row to reorder it or to drop it into a group; **+ Add** (pixels, indexed, fill,
  gradient, text, group, adjustment), **Duplicate** and **Remove**. The lock and the open/closed state of a group are kept for this
  editor session only, by layer name: they are not in the document. Procedural, svg and provider layers are added with the Console
  (`image.layer.add`); once there they can be selected, reordered, hidden and have their opacity, blend mode and offset edited.
- **Layer inspector.** Visible, clip, opacity, blend mode, offset, and the fields of the layer's kind (colour, text, gradient angle).
  Under it the **Adjustments** and **Effects** lists: add one by type, remove, reorder, and edit each field. A slider previews on the
  canvas while it is dragged, writes nothing until it is released and is then one undo step. The curve and stops fields (`curves`,
  `gradientMap`) are typed as JSON text.
- **Frame timeline** (under the palette bar; a pixel-art document shows it even with one frame). One button per frame, **Add**
  (an empty frame after the current one; the first one makes the picture an animation), **Duplicate**, **Delete**, **<** and **>**
  (move the frame) and a duration box in milliseconds (Enter applies): they run `image.frame.add`, `.remove`, `.move` and `.set`, one
  undo step each. **Play** shows the frames one after the other for their durations: only the frame shown changes, nothing is
  written, and a click on the canvas stops it. **Onion skin** draws the frames before (red) and after (blue) faint under the current
  one; the boxes set how many on each side (0 to 8), how strong the nearest ghost is and whether the frames wrap around. It is a
  preview the bake never has ([IMAGES.md](../IMAGES.md), "Onion skin"). Switching frame only changes what the panel shows and where
  painting goes.
- **Undo and redo** are the editor's (Ctrl+Z, Ctrl+Shift+Z, Edit menu): each stroke, selection, layer edit, adjustment edit and
  transform is one step, and one slider drag is one step. An undo puts back the files the edit changed (the document, the PNGs of
  the layers, the stored selection) from a table the panel keeps in memory; a step of another document opens that document first. The
  editor's stacks hold only a pointer to the step, so the files are not part of a scene's undo history on disk.
- **Speed.** While a stroke, a slider or a transform is live, the shared compositor draws the document with the changing layer taken
  from memory instead of its PNG on disk, and nothing is written until the gesture ends. The layers under the one being edited are
  composited once and reused for every frame of the gesture (the layers above it, and the whole picture when the edited layer is
  clipped or the onion skin is on, are drawn each time). The status line shows the last composite time in ms.

## Vector panel

View > Vector opens the Vector panel; double-clicking a `*.svg` in the Project panel opens that drawing in it, and **Edit in Vector
panel** in the Image panel's inspector opens the svg layer of the selected layer ([IMAGES.md](../IMAGES.md)). It is a floating window the first
time (1100 x 720) and edits ONE drawing at a time. SVG is the document: every edit that is kept runs the `vector.*` command an AI would
call (`vector.add`, `vector.nodes`, `vector.transform`, `vector.set`, `vector.boolean`, `vector.reorder`, ...), so the SVG keeps its ids,
groups, transforms and untouched text exactly as [VECTOR.md](../VECTOR.md) says, and a person and an AI can take turns on the same file.
The picture on the canvas is the engine's own SVG rasterizer (`vector_rasterize`, the one `assets.rasterize_svg` uses), never a second
renderer. While a handle, a slider or a box is being dragged the canvas shows the same command run with `dryRun` on the text in memory;
nothing is written until the mouse is released, and then the edit is ONE undo step. Edits are written to the file as they happen (the
toolbar's **Save** says so); for an svg layer of an image document the edits go into the layer without baking, and **Save + bake**
(`image.save`) bakes the document's PNG. The panel reads the file again by itself when it changes on disk (an AI, the Console, the Image
panel) and no gesture is running.

- **Toolbar.** The drawing (a menu of the project's `*.svg`), **New** (a name and a square size: writes `assets/<name>.svg` with a `viewBox`),
  **Save**, **Reload**, **Fit**, **1:1** and a zoom percentage, then the snapping switches **Grid**, **Points** and **Guides** and **Snap...**
  (the grid size and the guides). Grid snaps to a grid of that size in drawing units; Points snaps to the nodes, bounding-box corners and
  centres of the other shapes and to the canvas corners and centre (a point wins over the grid and the guides); Guides are vertical and
  horizontal lines added in **Snap...** by their position. Snapping applies to the Pen, the shape tools, node drags and moving shapes.
- **Canvas.** The wheel zooms around the pointer, Shift+wheel and a sideways wheel pan, and so do the middle button or Space + left drag.
  The drawing is drawn as a texture of the visible part (plus a margin, at most 4096 px a side) that is made again when the drawing
  changes or, after the view stops moving for a few frames, when it no longer covers the view or the zoom changed; while the view moves
  the old picture is stretched. The status line shows the selection's size, the zoom and the milliseconds the last read and picture took.
- **Tools** (left column, shortcut in brackets): Select (V), Node (A), Pen (P), Rectangle (R), Ellipse (O), Line (L) and Shape (S).
  Below them the style new shapes start with (fill, an optional line, its width and, when the project has a style palette in
  `assets.json`, the palette's swatches).
- **Select.** A click picks the topmost unlocked shape at the current group level (a click on a shape inside a group picks the group; a
  double click on a group goes into it, a double click on empty space or Esc with nothing selected leaves it). A drag from empty space is a marquee: left to right picks the
  shapes it contains, right to left the shapes it only touches; Shift adds and toggles. The selection's box has eight handles (drag to
  scale, Shift keeps the aspect ratio, Alt scales from the centre), a drag outside a corner rotates (Shift snaps to 15 degrees) and a drag
  inside moves (Shift locks to an axis). The arrow keys nudge by 1 drawing unit, with Shift by 10. Moving, scaling and rotating write a
  `vector.transform` on the selection (the shapes keep their ids and get a `transform`, their nodes are not rewritten). Esc during a drag cancels it and changes nothing.
- **Pen.** A click adds a corner, a drag adds a curve node (the out handle follows the mouse, the in handle is its mirror), a click on the
  first node closes the path, Enter or a double click ends an open path, Esc drops it. A click on the end node of an open path continues
  it from there (from its start, the new nodes are added before the first one and the path keeps its direction). A path needs two nodes.
  The result is `vector.add` (a new path) or `vector.nodes` with `append` (a continued one).
- **Node.** Shows the anchors and handles of the selected shapes. Drag an anchor or a handle; Alt while dragging a handle breaks the link
  to the other handle; a double click on a segment inserts a node there; a double click on a node switches corner and smooth;
  Shift-click and a marquee select several nodes, Delete removes them and the arrow keys push them (1 unit, 10 with Shift). When several shapes are selected a drag moves the selected
  nodes of the shape that was grabbed. The **Nodes** row has Add node, Delete, Corner, Smooth, Symmetric, Break, Join, Close and Reverse:
  each is a `vector.nodes` op (move, handle, insert, delete, convert, break, join, close, reverse, append).
- **Rectangle, Ellipse, Line, Shape.** Drag a box (Shift makes it square or a circle, Alt draws from the centre; Shift on a Line snaps the
  angle to 45 degrees). **Shape** drags out one of the `vector.shape` kinds chosen in the tools column (star, gear, polygon, arrow,
  bubble, ribbon) with `parametric: true`: the element keeps `data-fa-shape` and `data-fa-args`, and the inspector shows its parameters
  (points, inner ratio, teeth, sides, tail...) as live fields that call `vector.shape` with `replace`. Editing its nodes makes it a plain path.
- **Actions.** Rows of buttons above the canvas, each one command and one undo step: **Shapes** (Union, Subtract, Intersect, Exclude =
  `vector.boolean`; Group, Ungroup, Front, Back), **Path** (Offset..., Simplify..., Smooth..., Mirror..., Outline = `vector.stroke_to_path`),
  **Arrange** (Align..., Distribute...) and **Style** (House style = `vector.style`, To palette, Shade... = `vector.shade`). The
  buttons that need numbers open a small popup with the command's own arguments. A button that cannot act (too few shapes selected)
  is greyed; a command that fails shows its message with the fix in a toast and the status line, and changes nothing.
- **Layers** (right column, in drawing order, the top one first): the elements of the SVG as a tree of groups and shapes, each with an eye
  (hide = `display="none"`), a padlock (lock = `data-locked="true"`: the canvas does not pick or move it), its id (double-click to rename: it
  updates the `href` and `url(#...)` that point to it) and a triangle that opens or closes a group. Click selects (Ctrl, Cmd or Shift toggle a row of the same group level);
  drag a row onto another to reorder it or drop it into a group (`vector.reorder` with `parent` and `before`, which compensates the
  transforms of the old and new group so the picture does not change). Elements with no id show their selector in grey; an edit gives
  them an id first (`vector.assign_ids`, in the same undo step), or **Give them ids** names every one.
- **Inspector** (below the layers): the position and size of the selection (typing moves or scales it), Flip H, Flip V and Rotate 90,
  fill and stroke (a colour popup, **none**, and, when the project has a palette, its swatches: the exact palette colour is written),
  stroke width, opacity and fill rule, and the parameters of a parametric shape. A slider previews on the canvas while it is dragged
  and is one undo step when released; a colour is one step when its popup closes. With several shapes selected it edits them all (the fields show the first one's values).
- **Keys** (while the panel has the keyboard): V A P R O L S pick the tool, Delete and Backspace delete the selection, Ctrl+A selects
  everything at the group level, Ctrl+D duplicates (a copy 10 units down and to the right), Ctrl+G and Ctrl+Shift+G group and ungroup,
  Home fits the view, Esc drops the pen path, then the node selection, then the shape selection, then leaves the group. Ctrl+S saves.
- **Undo and redo** are the editor's (Ctrl+Z, Ctrl+Shift+Z, Edit menu), the same stacks as the Image panel's: each edit is one step, and
  an undo puts the files the edit changed back from a table the panel keeps in memory (so a file written byte for byte is restored
  byte for byte); a step of another drawing, or of an svg layer, opens it first. The stacks hold only a pointer to the step.
- **Speed.** A drawing of 600 paths, measured in a Release build on an Apple M-series Mac (the `vector_tests` case "a drawing of several
  hundred paths" prints the times on every run): open and read in about 2 ms, a drag step (the command run with `dryRun` on the text in
  memory) in about 1 ms, the edit written to the file in about 2.5 ms and a 1024 x 1024 picture of the drawing in about 21 ms. A Debug
  build is ten to twenty times slower. The status line shows the last read and picture times. The hit test, the marquee and the snapping
  use the scene read once per edit (bounds and flattened outlines), not the SVG text.

## Sound panel

View > Sound opens the Sound panel; double-clicking a `*.sfx.json`, a `*.audio.json`, a `.wav` or an `.ogg` in the Project panel opens
that sound in it. It edits ONE sound at a time and is a floating window the first time. The documents are the source ([SOUND.md](../SOUND.md)):
every edit that is kept runs the command an AI would call (`sfx.tweak` for the knobs, `sfx.edit` for any other field and for adding,
removing and moving list items, `sfx.preset`, `sfx.family`, `audio.edit` for the steps of an audio document, `audio.create` for a
new one), so a person and an AI can take turns on the same file and an edit is ONE step of the editor's Undo. The sound you hear is the
engine's own offline renderer (`render_sound` in `fa/tooling/audio_view.h`, which calls `render_sfx` and the audio document renderer that `sfx.render` and `audio.render` use), never a second synthesizer.
Edits are written to the document as they happen and the picture and the sound follow after a short pause (the render runs on a worker
thread and the last request wins); **Save + bake** writes the WAV (`sfx.render`, with `variants` when the patch has variations, or
`audio.bake`) and its recipe. A plain `.wav` or `.ogg` is shown read-only, with **Make an audio document from this**. The panel reads
the file again by itself when it changes on disk and no gesture is running.

- **Toolbar.** The sound (a menu of the project's patches, documents and recordings), **Save + bake**, **Replace foreign file** (bake
  over a WAV the engine did not make; off by default), **Reload**.
- **Waveform.** Drag to select a range, Shift-drag or middle-drag to pan, the wheel to zoom (Shift + wheel scrolls), click to place the play cursor.
  **-**, **+**, **Fit** and **To selection** zoom too. The playhead moves while it plays. A **Spectrogram** (frequency against time) can
  be shown under it, and the measurements (length, LUFS, peak, true peak, centroid, dominant band) are listed from the rendered samples.
- **Transport.** Play / Stop (Space while the panel has focus), **Loop** and **Selection** (play only the selected range). Playback goes
  through the engine's audio mixer; on a machine with no audio device the null device is advanced by the panel so the playhead still runs.
- **Macros.** One knob per macro of the patch (`brightness`, `tail`, ...) with the macro's doc as tooltip; drag up and down (Shift for fine steps, double click for 0); the
  edit is debounced and kept as one `sfx.tweak` undo step.
- **Inspector.** Every field of the patch, taken from `schemas/sfx.schema.json`, so a new field of the format appears with its
  description, minimum, maximum and default as the tooltip. Lists (layers, oscillators, effects, modulators, variations) can be
  added to, removed from and reordered. **Start from a preset** replaces the patch; **Make a UI family** runs `sfx.family` with the
  `ui` preset (click, hover, confirm, cancel, error, ...).
- **Variants and A/B.** The variations of a patch are listed with a play button each; two of them can be put in slots A and B and
  heard in turn. **Same loudness** matches their levels by the measured LUFS so the louder one does not win. **Swap** exchanges the slots.
- **Audio documents.** The chain of steps is a list: add a step of any type, move it up or down, switch it off, hear the chain up to
  it, remove it, and edit its fields. A `loop` step shows two draggable markers on the waveform, the loop start and the loop end.
  The source and the output are shown with the recipe's freshness.

**Autotest.** Section K3 of `fa_editor_autotest` opens a patch, drags a macro knob (one undo step, a brighter centroid), plays and stops,
selects and zooms the waveform, adds variations and compares A and B with and without level matching, undoes and redoes, saves
(the variant WAVs exist), then builds an audio document, adds a step, moves and enables it, drags the loop end marker, undoes it
and saves again (`loopEnd` in `assets.json`).

## Music panel

View > Music opens the Music panel; double-clicking a `*.song.json` in the Project panel opens that song in it. It edits ONE song at a time and
is a floating window the first time. The document is the source ([MUSIC.md](../MUSIC.md)): every edit that is kept runs the command an AI would
call (`music.edit` for notes, drum grids, sections, layers, tracks, buses and the master; `music.chord`, `music.arpeggio`, `music.bassline` and
`music.drums` for the helpers, `music.mix` for the loudness), so a person and an AI can take turns on the same file and an edit is ONE step of
the editor's Undo. The sound you hear is the engine's own: the song is rendered by the same code a game's `MusicPlayer` uses
(`music_render_source`, the live mode) and played through `MusicTransport`, so what the panel plays with its intensity slider is what
`entity.music.setIntensity` plays in the game. Edits are written to the song as they happen and **do not bake**; a few frames after a change
the song is rendered again on a worker thread (the last request wins) and the next Play hears it. **Save + bake** runs `music.render`
(the mix and, when the song declares layers, one stem per layer) and records the recipe. The panel reads the file again by itself when it
changes on disk (an AI's edit, another editor) and no gesture is running; the undo steps stay.

- **Toolbar.** The song (a menu of the project's `*.song.json`), **Save + bake** (Ctrl+S while the panel has the keyboard), **Replace foreign file**
  (bake over a WAV the engine did not make; off by default), **Reload**, and the last edit's name ("Undo: Mute arp").
- **Transport.** Play / Stop (Space), the **section** menu, **Play section** (starts at the first pass of that section: a section is the granularity of
  play-from-here), **Loop** (the section plays again and again), the **intensity** slider with **Calm** (0), **Tense** (0.5) and **Intense** (1) buttons, and the
  gain of each layer as a row of bars. The position reads `bar 3 beat 2  00:05.4  loop`; a playhead runs through the roll and the grid while it plays. On a
  machine with no audio device the null device is advanced by the panel so the playhead still runs. Edits wait while it plays: Stop first.
- **Piano roll.** The tracks' patterns as notes on a keyboard. Click and drag on empty space to **draw** a note (it takes the snap length and stretches as you drag),
  drag a note to **move** it (with the other selected notes), drag its right edge to **resize** it, right click or Delete to **delete**, Shift-click to add to the
  selection. **Snap** (1/4 to 1/32 and triplets) and the **velocity** a new note gets are in the roll's toolbar, **Scale** shades the rows outside the song's key and mode,
  **-/+** zoom and **Up/Down** an octave. A **velocity lane** under the roll sets a note's velocity by dragging its bar. A drag is a working copy: letting go makes ONE `music.edit set_pattern`
  with the notes as a list, so it is ONE undo step. The playhead of the pattern shows when the track plays it. The pattern menu, **New pattern**, **Remove pattern** and the bars
  **-/+** change the pattern; **Insert chord** (a name such as `Am7`) adds the chord's notes at the yellow cursor, **Arpeggio** and **Bass line** replace the pattern with a
  generated one over a progression.
- **Drums.** A kit track's patterns as a grid: one row per lane, one cell per step. A click on a cell steps it through hit, accent, ghost note and empty, a right click clears it; the step value
  (`4` to `32` and triplets) and the bars are set above it, **Add lane** / **Remove last lane**, **Clear**, and **Generate** a groove in a style (`music.drums`, with a tom fill).
- **Arrangement.** The sections in order with their kind, the **repeat** count (**-** / **+**), **up** / **down**, **remove**, **play**, and **Add section**; under each, what every
  track plays there (the pattern names, `a a b*2`, or `rest`) and a **muted** box that silences the track in that section only. **Layers** lists the song's layers with the intensity each fades in at
  and the tracks in it; **Add layer** makes one.
- **Mixer.** One strip per track: volume, pan, **M**ute, **S**olo, its sends to the buses, its effects chain (add and remove any effect the engine has, with every field
  and its range from `audio_step_types()`), and the instrument. **Buses** with volume, mute and effects; the **master** with the song volume, the limiter and its ceiling, the
  loudness target (`style`, `off` or a LUFS number) and **Measure loudness** (`music.mix`: LUFS and peak of the whole mix).

A change a command refuses (an unknown pattern, a bar that does not add up) is shown in the panel's status line with the command's hint and the file stays as it was. Dragging a
number (volume, pan, a repeat) is one edit when the mouse is released, not one per frame.

**Autotest.** Section M3 of `fa_editor_autotest` opens a layered song, draws a note by dragging on the roll, moves it, deletes it with a right click and walks
Undo and Redo through the editor's stack, clicks a snare into the drum grid, raises a section's repeat and mutes a track in the mixer (each one undo step), plays and
checks that the playhead moves, fades the top layer in and out with the Intense and Calm buttons, loops a section, and saves (the mix and the stems exist).

## Lightmap panel

View > Lightmap bakes the open scene's lightmaps: the same bake as the `lightmap.bake_start`, `lightmap.bake_status` and `lightmap.bake_cancel`
commands (docs/rendering/RENDERING_LIGHTING.md, "Baking"), on a job thread, so the editor keeps drawing and you can keep working.

- **Options.** Texels per meter (16 is a good start; 64 is sharp and 16 times heavier), Samples (gather rays per texel: 16 is a draft, 64 is
  smooth), Shadow samples, Page size, Sky (`auto`, `environment`, `gradient`, `ambient`, `none`) and the Manifest path (empty: next to the
  scene, `scenes/main.lightmap.json`). Each has its tooltip.
- **Start and Cancel.** Start is disabled while a bake runs and while the game plays. The bar shows the phase (geometry, layout, prepare,
  rasterize, trace, denoise, dilate, writing), the percentage and, after a few seconds, the time left; Cancel stops it within a moment and no
  file is changed.
- **The result.** A finished bake lists its pages (file and size), the texels, the meshes, the rays and the time, the skipped entities with
  their reason, and the warnings (a physical sky that fell back to the gradient, a Tube light baked as a rectangle).
- **Light probes.** The bake also bakes the `LightProbeGroup` entities of the scene (phase `probes`) and the result says how many probes there are and how many lie inside geometry (ignored). **Show probes** draws them in the 3D viewport: a sphere per probe coloured by the light it baked (grey before the first bake or after the group was edited, a red cross for a probe inside geometry); `LightProbeGroup.showGizmo` hides one group (docs/rendering/RENDERING_LIGHT_PROBES.md). View > Show light probes is the same switch. At most 2048 probes are drawn in all (a stride over every group, so a big scene shows a sample) and probes behind the camera are not drawn. When groups were edited after the bake, the panel shows an orange line "N light probe groups changed since the last bake" (the same groups are grey in the viewport): bake again to refresh them.
- **The scene.** The panel starts the bake without `apply` and then sets `SceneSettings.lightmaps` through the editor's own edit path: one undo
  step, the scene marked as changed (Save keeps it). It does not set it when another scene was opened meanwhile or the game is running; the
  panel says so and where the files are.
- **Errors.** A refused start (no mesh to light, a bad option, a manifest outside the project, a bake already running) or a failed one (a file
  that is open in another program cannot be replaced on Windows) is shown in the panel with what to change; nothing is half written.

## Terrain tool

View > Terrain tool opens a panel (a tab next to Inspector) and, while one of its three modes is on and an entity with a `Terrain`
component is selected, the viewport paints on the terrain instead of selecting and moving: the gizmo is off and a click and drag is a
brush stroke. Click the mode again to leave it. It works in edit mode only (the brush changes the scene; Stop the game first). The
tool is the editor's face of `terrain.sculpt`, `terrain.paint` and `terrain.holes` (docs/BIG_WORLDS.md, "Terrain"): every stroke is
those commands, so a script or the AI can do the same.

- **Sculpt.** Raise, Lower, Smooth, Flatten. Raise and Lower take an `amount` in metres (the change at the middle of the brush for
  one stamp at full strength; the stamps are a quarter of the radius apart, so the ground under the brush gets several). Hold Ctrl
  while you stroke to do the other one (Raise lowers, Lower raises). Flatten levels to the height under your first click (the
  default) or to a height you type; **Pick from the terrain** (or Alt+click) takes that height from the ground under the next click.
- **Paint.** The layers of `Terrain.layers` as a list with their albedo texture's thumbnail and file name; pick one and stroke. A
  terrain with no layers says to add them in the Inspector. The first stroke makes the splat map and sets `Terrain.splatMaps`.
- **Holes.** Cut or Fill (Ctrl swaps them). The first cut sets `Terrain.holes`. A brush smaller than a cell can miss every cell. The brush aims at the surface as if no cell were cut, so a hole can be aimed at and filled again.
- **Brush.** Radius in metres (never more than half the terrain or about 900 samples), strength 0 to 1 and falloff 0 to 1 (1 fades from
  the middle to the edge, 0 is a hard edge). With the mouse over the viewport: `[` and `]` make the radius smaller and bigger, Shift+`[`
  and Shift+`]` change the strength, Esc takes the stroke you are drawing back.
- **The cursor.** A ring of the brush's radius lies on the terrain under the mouse, following its relief (yellow for sculpt, blue for
  paint, red for holes); a second, fainter ring inside it shows where the effect is at full strength (radius times one minus falloff).
- **A stroke is one undo step.** While the mouse is down the stamps (one every radius / 4 along the path) go to the terrain as the mouse
  moves, so you see the ground change. They are sent as a few command calls that share ONE step of the terrain's own history
  (`continueStroke`): a call per frame would push the 64 steps of that history out in a second. When you let go the editor records one
  undo entry that runs `terrain.undo` (Ctrl+Z; the whole stroke goes back, sample for sample) and `terrain.redo` (Ctrl+Shift+Z, Ctrl+Y),
  and marks the scene as changed. A stroke stops at 20000 stamps.
- **Saving.** The terrain's files (heightmap, holes image, splat maps) are not in the scene file; Save writes them after it. If one
  cannot be written (a folder where the file goes, a file open in another program) a toast says which and why, nothing is marked as
  saved and every edit is still in memory. Closing the editor, reloading the scene and opening another one ask first when a terrain has
  edits not written yet, even if the scene itself is clean (a terrain changed by a command from the Console or the AI counts too).
- **What an undo does not do.** Ctrl+Z of another edit (a moved entity), Play and Stop reload the scene from a snapshot; a terrain with
  unsaved edits or history is kept across that, so those edits and their Ctrl+Z are not lost. The terrain's history keeps 64 steps: once
  the 65th is made the oldest stroke can no longer be undone and its Ctrl+Z says so. The `Terrain.holes` and `Terrain.splatMaps` paths a
  first stroke sets are not taken back by Undo (the data is).

The brush itself (settings, stamps along the mouse path, the ring, the ray to the ground) is the editor's shared `brush.h`, which the
other viewport brush tools use too.

## Scene settings panel

View > Scene settings opens a window with the settings of the open scene, the ones the file keeps under `settings` and the
Inspector never shows because they belong to no entity (`SceneSettings`, listed by `docs.components`). The fields come from the
component's reflection, in groups (Sky, Fog, Lighting, Physics, Music, Output; a field added to `SceneSettings` later lands in
"Other" and is never hidden), each with its doc as a tooltip, drawn by the same widgets as the Inspector.

- **Sky material.** `skyMaterial` is a picker of the project's `*.material.json` files. Under it the panel says what the material is
  (a sky one, another kind that cannot draw the sky, a file that cannot be read, a build error the renderer reported) and, for a sky
  material, shows one control per param typed by `material.info`, each with a Reset that removes its override
  ([SHADERS.md](../SHADERS.md), "Sky materials"). The reflections and the ambient light of the meshes keep following `skyColor` and `horizonColor`.
- **Reset.** A field that differs from its default shows a **Reset** next to it; one click writes the default back.
- **Undo.** Every edit is `scene.set_component` on `SceneSettings` (no `id`; `skyMaterialParams` merges), so it is ONE step of the
  editor's Undo and Redo in order with the other panels' edits (a drag of a colour or a number is one step), and a refused value
  (a wrong type, an unknown setting) changes nothing and leaves no step. An AI or a script calls the same command.

**Autotest.** Section Q3 of `fa_editor_autotest` (at 1024x642 too) opens the panel from the menu, picks a sky material, sees its params
typed, sets one and takes it back with the param's Reset, takes the material back with the field's Reset, walks the four steps back
with Undo and forward with Redo, and checks that a refused value leaves no step. The panel's rules (`scene_settings_model.*`) have
unit tests in `scene_settings_tests.cpp`.

## Graph panel

View > Graph opens the Graph panel, which edits the node graph of ONE `*.material.json` ([SHADERS.md](../SHADERS.md), "Node graphs"). Open a material in it by
double-clicking a `.material.json` that has a `graph` in the Project panel, by **Edit graph** under a material field of the Inspector, or with the file menu in
its toolbar. **New graph material** writes `assets/materials/graph.material.json` (or the next free `graphN`) with an empty graph (just the output node), and a material
with no graph offers **Start a graph in this material**. The panel reads and writes the same JSON an AI writes, and **Save** runs the command an AI would call
(`material.graph.generate`: it writes the graph and the shader snippet, with `graphHash`), so a person and an AI can take turns on one file. Nothing is written
before Save; the toolbar's status line says when there are unsaved edits and what state the snippet is in (in sync, the graph changed, edited by hand, unreadable with the reason as its tooltip, ...). Switching
to another material with unsaved edits asks first ("Discard the graph changes?"). A file that someone else changed on disk (an AI, a script, another editor) is looked at again
when you press Save: the panel does not replace it but asks "The file changed on disk" with **Overwrite** (the graph as edited replaces the file), **Reload** (the file as it
is, your edits gone) and **Cancel** (nothing is written, the unsaved graph stays). **New graph material** makes the material file whole or not at all: it is written under a
temporary name and published only if the name is still free, and when the snippet cannot be written the material file it made is removed again, so a failed New leaves nothing behind
and never replaces a file made meanwhile (on a volume with hard links; on one without, a look and a rename leave a very small window). If the name of the snippet the material would get (`shaders/<name>.surface.glsl`) is already taken by a hand-written file, the next free name is used for both. Closing the material (or opening another) clears the Params and Textures forms and their messages.
The combo next to **New graph material** picks the kind: `mesh` (the default), `sprite` (a 2D item: `assets/materials/sprite_graph.material.json`, `"kind": "sprite"`, the snippet `shaders/sprite_graph.fragment.glsl`; the output has `color`, `rgb`, `alpha` and `vertexOffset` and starts with a colour) or `post` (a full-screen pass: `assets/materials/post_graph.material.json`, `"kind": "post"`, the snippet `shaders/post_graph.post.glsl`; the output has `color` and `rgb`, and the graph starts as `post.scene` linked into `rgb`, the picture unchanged).
The kind of an open material is the file's `kind`: a sprite or post graph's palette leaves out the nodes of the other kinds (a sprite lacks `fresnel`, `triplanar`, `parallax`, `texture.normal`, `normal.world`, `view.dir`, `position.view`, `vertex.color`, `position.world`; a post pass has the `post.*` nodes instead), and a search that matches a node of another kind (by name, category or description) says what to use instead.

- **Canvas.** Nodes are boxes with their input ports on the left and output ports on the right, coloured by type (float, vec2, vec3, vec4). Drag a node to move it
  (all the selected ones move together; the position is saved as the node's `pos`). Press on a port and drag to another port to link them; dragging from an input
  that is already linked picks that link up and moves it, and dropping on empty canvas removes it. A link that would add a problem `material.graph.validate` reports (a cycle, a type that does not fit) is not made and the
  checker's sentence is shown. Click a link to select it (Delete
  removes it). Drag on empty canvas to select with a rectangle, Shift or Ctrl/Cmd click to add to the selection. The mouse wheel zooms around the pointer (30 % to 250 %);
  right-drag or middle-drag pans. **Fit** (or F) frames the graph.
- **Add nodes.** A right click on empty canvas opens the **palette**: every node of the library (`material.graph.nodes`) with a search box (it has the keyboard when it opens;
  type and press Enter) and each node's doc as a tooltip. The node appears where you clicked. **Add node** in the toolbar does the same at the centre of the view.
- **Keys** (while the canvas is hovered): Delete or Backspace removes the selection (the output node cannot be removed), Ctrl/Cmd+A selects all, C, X and V copy, cut and paste
  nodes with the links between them (the text goes on the system clipboard, so it pastes into another material), D duplicates, S saves.
- **Inspector** (the right side, under the preview). For the selected node: its type and doc, a combo for `param` and `texture` nodes that lists the material's own params
  and textures (a new one made in the Params or Textures list below is offered at once), the constant of each unlinked input (a number, a vector or a colour), shown
  dimmed with the default when the node does not set it, **Cut** for a linked input, and **Delete node** and **Duplicate**. A selected link shows its ends and **Cut link**. A drag on a number is one undo step.
- **Problems.** The list `material.graph.validate` gives for the document as it is now, each with its JSON pointer and the fix; a click selects the node or link it names.
- **Preview.** A lit sphere, cube or quad drawn with the material the graph would generate (what is being edited, not what is saved), using the engine's renderer. After an edit it
  waits a fraction of a second, then compiles on a worker thread and shows the picture, so dragging a slider never freezes the editor. **Animate** turns the shape so the lighting and
  `time` change. The preview compiles through sokol-shdc ([SHADERS.md](../SHADERS.md), "Compiler"): without it the panel says so and the rest still works. The files it writes (the
  material and snippet it compiles and the copies the renderer loads) are in `.factoria/material-preview/`, which a new project's `.gitignore` leaves out with the rest of `.factoria/`;
  deleting the folder is safe, the next edit makes it again. Each preview (the one on the canvas and the saved copy for Compare) stages its compile in files of its own
  (`stage-<id>.*`), and changing project or quitting the editor waits at most two seconds for a compile in flight before it lets the worker finish alone (closing the panel does not destroy the preview). Files a worker left behind when the editor quit (`stage-*`, `saved-stage-*`) are deleted by the next preview once they are a few minutes old, and the errors of a compile name the material or the snippet, not the stage file. The shader compile is cached in `.factoria/shader-cache`; when that result cannot be saved (a full disk, a read-only
  folder) the preview shows an error and does not compile on the editor's thread.
  - **Params.** Each param of the material (`params`; the ones the generator adds itself are left out) has a slider, a drag box or a colour editor under the preview. Moving one
    changes the PREVIEW only (`MeshRenderer.materialParams` of the scratch entity): the file is not touched, nothing compiles again, the name turns amber with "(preview only)", and
    **Reset** puts that one back. **Reset values** resets all. The values go away when another material is opened or the param is removed. **Set as default** writes the value as
    the param's `default` in the material file (`material.param.set_default`, one set of code with the Console and an AI) at once, without saving the graph's other unsaved edits,
    and is one undo step (Undo writes the old default back; it refuses when the file's default is not the one the step expects).
  - **Making, renaming and deleting params and textures.** **+ Param** and **+ Texture** open a small form (name; type, default and optional range, or the sampler; a doc line) and
    **Create** writes the entry into the material file at once through `material.param.create` / `material.texture.create`, the commands an AI calls, so the same checks apply (a name
    the material already has, a GLSL word, `fa_` or the `gn_` prefix of the graph's helper functions, a default outside the range: the sentence appears in the form and nothing is
    written). Every row has **Rename** and **Delete**. Rename (`material.param.rename`, `material.texture.rename`) writes the new name into the file and points the nodes that read
    the old name at the new one, saved or not; scenes and prefabs that set a param by name in `MeshRenderer.materialParams` are NOT changed. Delete (`material.param.delete`,
    `material.texture.delete`) is refused while a node of the graph as it is now reads the entry: the message names the nodes and the panel selects them, so you point them at another
    entry or delete them first. The commands themselves can also remove those nodes (`force: true`, for an AI that means it); the panel never does, because a click that deletes nodes
    nobody chose is not what the button says. A file whose shader snippet is the one the graph generated (state "in sync") gets its snippet generated again, so it never names a param
    that is gone; a hand-edited snippet is left alone (the toolbar keeps saying so). Each of the three is ONE undo step, in order with the graph's own edits (Undo and Redo run the
    inverse command: they write the file again, and refuse with the command's sentence when it cannot run, e.g. the name was taken or removed by an AI meanwhile). The preview
    compiles again once the edits stop, because a new or removed param changes the material's uniforms. When the command says something the panel would otherwise hide (the
    snippet was not written again and why, or a hand-written snippet that still uses the old name), the sentence is shown in amber under the list instead of being dropped.
    Undo of a delete puts the entry back at the place it had (the `index` the command returned), not at the end.
  - **Kinds.** The preview draws the three kinds a graph can be made for, each its own way. A `mesh` material is drawn on the sphere, cube or quad. A `sprite` material is drawn on a flat 2D quad (a `Sprite` with the material and its params, on the material's first default texture or a grey checker), and the shape buttons are replaced by a note. A `post` material is drawn as the only entry of `PostProcess.customPasses` of a camera over a small scene (a floor and four lit shapes at different depths, over a sky), four frames in a row so `post.history` has a frame before it; the project's own post effects are not applied. Its shape buttons are replaced by a note and the **Try on scene camera** button (enabled once the material is saved), which adds the material to the `customPasses` of the camera that draws the scene as one undo step. A `sky` or `compute` material is not drawn, and the panel says why (a sky needs the scene around it, a compute material draws nothing) instead of drawing something wrong. The autotest section G3 draws the mesh, the sprite and the post preview (a post graph with a node added must change the picture) and tries the material on the scene camera.
  - **Compare.** The **Compare** check box draws the last SAVED version of the graph (the file as it was read or saved) next to the current one, with the same shape and the same param
    values, so you see what the edits changed. The saved version compiles on its own worker. A graph that was never saved (a draft) says so. A save, a reload and a new default make a
    new saved version.
  - **Errors.** A graph with problems, or a compiler error, keeps the last picture and shows the message. The generator keeps a map from every line of the snippet to the node that
    wrote it, so when the compiler complains about such a line (its message names the line of the generated snippet) that node is painted red on the canvas with the message under it
    (and in its tooltip); a line no node wrote (a helper, a brace) or an error of the material file stays only in the panel, whole.
- **Save and the hand-edit rule.** If the snippet on disk is not what the graph last wrote (edited by hand, or never generated), Save asks "Overwrite the shader snippet?":
  **Overwrite** passes `force`, **Cancel** changes nothing. If the file changed on disk after the panel read it, Save says so before it overwrites it.
- **Undo.** Every edit that is kept (a node added, moved or removed, a link, a constant, a paste) is ONE step of the editor's Undo and Redo, in order with the other panels' edits.
  Undo changes the open graph, not the file: Save writes it. (The params and textures steps and "Set as default" are the exception: they are written to the file at once, and so are their
  undo and redo.) A link dropped on the input it already feeds, a drag that ends where it began, and a rename to the same name make no step. While a node or link is being dragged the checker
  does not run again for every mouse move: the problems list and the red marks are those of the graph as it was when the drag began, and update when the mouse is released.
- **The file changed behind the panel.** The panel looks at the file every few frames. A change with nothing unsaved is read again ("The file changed on disk and was read again");
  with unsaved edits the toolbar says so and **Reload** takes the file. A file that lost its `graph` (its shader became hand-written) is said ONCE, and the panel keeps its graph as a
  draft (Save writes it back into the file) instead of reading the file again at every look.

**Autotest.** Section G3 of `fa_editor_autotest` (at 1024x642 too) writes a dissolve material with a one-node graph, opens it, adds three nodes from the palette (a right click
and the search box), drags four links with the mouse, sets two constants, waits for the preview and checks that it drew pixels (a skip when there is no renderer or no
sokol-shdc, unless `FA_REQUIRE_SHDC=1`), checks that a sky material is not drawn (the reason is shown), that a param override redraws the preview without touching the file or
compiling again, that **Set as default** writes the file as one undo step (and Undo and Redo write it back and forth) and that **Compare** draws the saved version beside the current one,
checks that a link the checker refuses gives its sentence, saves (the material and the snippet exist), edits the snippet by hand and checks
that Save asks, that Cancel changes nothing and that Overwrite writes it, then undoes and redoes every step. The model (`graph_model.*`) has its own unit tests (`graph_tests.cpp`).
