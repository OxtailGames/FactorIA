# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

## Unreleased

The AI agent is never silent

- When the editor's AI (Claude Code) hands a task to the worker, the worker's steps now stream into the chat as it works, and the
  panel shows how long the run has lasted and when the agent last did something. Before, a long delegation was a silent wait
  and Claude Code gave up on it after 5 minutes, so the worker's report never reached the chat.
- The MCP server reports progress (`notifications/progress`, with a heartbeat) on long calls over stdio and over the editor's
  HTTP endpoint, and the `.mcp.json` that `factoria new` writes carries a four-hour `timeout` for one tool call (add
  `"timeout": 14400000` to the server in an older project; `tool_timeout_sec = 14400` for Codex).
- After `limits.stuckAfterSeconds` (default 180, `ai.json`) without a sign of life, the panel warns that the agent may be stuck
  and offers **Stop** and **Check activity**, which looks at the agent's process, CPU, tool in flight, child processes and the
  project's recent file changes and says whether it is still working. A CLI process that disappears stops the run with a message.
- If the orchestrator's turn ends while the worker still runs, the panel says so, keeps showing its progress and, when the worker
  finishes, puts its report in the chat and continues the orchestrator's conversation by itself, once.
- `factoria ai run` prints the sub-agent's steps in the terminal (`  | worker > ...`), and `{"event":"progress"}` lines with `--json`.

Drawing

- `Shape2D` gets rounded corners, soft edges and gradients, one entity each instead of stacks of translucent rectangles: `cornerRadius` (rectangle), `softness` (a blurred edge of that width on a rectangle or circle: drop shadows, vignettes, light pools) and `gradient` (`linear` with `gradientAngle`, or `radial`) from `color` to `color2`, dithered so it does not band. Everything defaults to off and plain shapes draw and batch as before (Roguestory FB-0003).

Watching the game and reading the docs over MCP

- Every log line carries the computer's time. The editor Console starts each line with `HH:MM:SS.mmm` (hover it for the date, the frame and the seconds since start); `game.logs` and `game.step`'s `newWarnings` give `wallTime` (ISO 8601 with offset), and the text and JSON stderr formats show it too.
- `game.click` (MCP `game_click`) clicks like a player: by UI widget `id`, screen `position` or `world` point it moves the mouse,
  presses, steps a frame, releases and steps another, so scripts see `input.mouse.pressed` then `released` and Buttons get their
  `click`. The AI guide and the generated AGENTS.md give the recipe (Roguestory/FB-0004).
- `docs.read` fits an MCP tool result by default (`maxBytes`, 40000): a cut page carries `contents` (headings with line numbers)
  and `next`, and `heading` reads one section. `docs.components` and `docs.commands` list names with a one-line summary by
  default; `name` returns one in full, `filter` narrows the list, `full` returns everything (Roguestory/FB-0005).

## 0.3.0

FactorIA 0.3.0 is about the games themselves: four more reference games (a 3D phone game, a couch co-op game, a management
game for the browser and a 3D story adventure) were made with the engine, and everything they asked for is in.
Split screen and actions per player, gamepads that come and go and the Steam Deck; tile paths, flow fields and behaviour
trees; lights with shadows from tiles; audio buses with effects, ducking and snapshots; a video player; drag and drop,
tooltips, rich text, buttons with icons, right-to-left languages and isometric tilemaps; tests that drive the UI like a
player; ads with consent, analytics and remote config; and players for the web, Android and iOS that are checked against
the engine they were built with.

Audio without a provider

- `assets.generate_voice` names the keys it needs (`ELEVENLABS_API_KEY`, `OPENAI_API_KEY`) when no provider is configured, and
  `silent: true` writes a silent clip of the line's length (or `seconds`) to test voice-dependent code (LL/FB-0601).
- `assets.generate_loop`: a seeded, seamless noise bed (wind, fire, clock) or chord drone, as WAV or Ogg. `assets.convert_audio`:
  WAV to Ogg Vorbis with an encoder built into the engine (long blocks, mono or stereo). Larkspur Lodge's beds and scores are made
  by calls kept in `assets/src/sound/*.json`; its `make_sound.py` is gone (LL/FB-0701).

Docs for what is already there

- A Button's `key` is a localization key, not a hotkey: the field's doc string (and COMPONENTS.md) says so and where a key press
  goes instead (an input action read with `input.pressed`) (LL/FB-0006).
- docs/MENUS.md, "Anchors and pivots": anchors count Y down, widget pivots count Y up, with a picture. `factoria validate` warns
  about a widget of a scene that lies completely outside the design size, naming it, the rectangle it covers and the fix
  (LL/FB-0007).
- `platform.*` in tests: the fake serves a request inside the call (also from an event handler), and the Promise settles in the
  next microtask; docs/PLATFORM.md and SCRIPTING.md say so, and a test pins it. `fake.achievements` lists only the ids that were
  touched (LL/FB-0504).
- docs/MOBILE.md, "Tablets and the iPad": `display.scaleMode: "expand"` shows more world on a 4:3 screen instead of black bars
  (LL/FB-0803, first half).

Hangul on the on-screen keyboard

- The menu kit's on-screen keyboard has an input-method hook, `IME` in `scripts/ui/keyboard.js`: per language, `{ compose(text, ch),
  decompose(text) }` say what the field's text becomes when a key is typed and when Delete is pressed. Korean's is built in: the keys
  are Hangul jamo (Shift gives the doubled ones), jamo make syllables (ㄱ + ㅏ = 가, 가 + ㄴ = 간, 간 + ㅏ = 가나) and Delete takes the
  last jamo away. `tests/slots.test.js` types a Korean slot name with the pad through the slot dialog (LL/FB-0905).

The menu kit: text speed and save slots

- `project.add_menu_kit` has a `textSpeed` part: a "Text speed" row (slow, normal, fast, instant) in the Options Audio tab, saved as
  `settings.textSpeed` in characters per second, with `settings.revealedCharacters(seconds)` for the dialogue box. `addOptionsRow()`
  of `scripts/ui/options.js` adds a row of the game to any Options section without editing the panel (LL/FB-0011).
- A `slots` part: five named slots and an autosave in `storage`, each a record with a counter, name, chapter, play time, picture and
  the game's data; a cloud copy with a higher counter replaces the local slot; damaged slots say why and can be deleted; and a
  save / load screen whose dialog names a save, with the on-screen keyboard for a gamepad player. It brings `core` and `keyboard`
  and its own `tests/slots.test.js` (LL/FB-0501).

Shipping checks: a sandboxed save, long recordings and the iPad

- The exported player takes `--persist-storage` with `--frames`, `--input`, `--dump-state` and `--screenshot`: `storage.*` and the
  save files go to the game's real user folder (the container of a sandboxed Mac App Store build) instead of memory, so a
  replay that presses Play and saves leaves a real file with no click (LL/FB-0801). `cli_larkspur_ship` does it for Larkspur Lodge.
- `--record-video` no longer grows with the length of the recording: on macOS every frame read back from the GPU was kept until
  the end of the run (4.4 GB for 25 s at 1080p); the memory is now flat (LL/FB-0802).
- The iOS player plays an input replay in its window when started with `FA_INPUT_REPLAY=<file>` and turns the screen with
  `FA_ORIENTATION=portrait|landscape` (iOS 16 or newer). `player.run_ios_sim` installs a Simulator build on an iPhone or an
  iPad simulator, starts it with both, waits for the replay to end, takes a screenshot and stops it (LL/FB-0803). Not run on a
  real iPad.

Listing data files

- Glob import of JSON data: `import tables from "../data/dialogue/*.json"` is an object of the parsed files directly in that
  folder, keyed by file name (`"ch1.json"`) in sorted order. `*` is allowed in the file name only. Editing a matched file reloads
  the importers; a file added while the game runs is seen on the next start. The export already packs every data file, so the
  glob finds the same files in `game.pak` and on the web. The generated typings declare `*.json` modules (LL/FB-0005).
- Larkspur Lodge reads its chapter tables with a glob import: a new chapter file needs no edit to a list.

Entity and scene lifetime

- `scene.generation`: a counter that changes on every scene load (`scene.load`, `scene.reload`, `game.load` in a test), a reload
  of the same scene included. A script that awaits a timeline, a preload or an answer keeps it and drops the result when it
  changed, which `scene.current` cannot tell on a reload (LL/FB-0602).
- `world.entities()` skips entities destroyed this frame, as `find`, `findAll` and `findByTag` already did, and the doc of
  `Entity.destroy` says when an entity is gone: lookups and ids at once, the handle (`alive`) at the end of the frame
  (LL/FB-0015). Larkspur Lodge's screens no longer prefix their ids with a build serial.

Tests that drive the UI like a player

- `game.tap(action)` taps the first key (or else the first gamepad button) bound to the action, so the UI and every action on
  that key see it: `game.tap("ui_submit")` presses the focused Button or Toggle (LL/FB-0009). An action with only a stick, the
  mouse or no binding is still held as the action.
- `game.checkLayout(options?)`, and `ui.check_layout {current: true}` for the command: measures the scene that runs now, with the
  panels a test has opened, without loading anything, and keeps the game state (LL/FB-0702, TM/FB-0063).
- `game.resetState()` also stops the music (`persist: true` included) and the voices; `{ audio: false }` leaves them (LL/FB-0704).
- The fake store applies `platform.stats.add` on the value it holds when it serves the request, so two adds in one frame both
  count; the call log shows one `stats.add` instead of a `stats.get` and a `stats.set`. A real store still gets a get and a set
  (LL/FB-0502).
- Larkspur Lodge drops its `tapKey("Space")` calls, its manual layout walk, its music reset and the pause between two saves.
- New `Interactable` component: any entity made of sprites, shapes, text and children is a widget of the same focus, navigation and events
  as Button, Toggle and Slider, in world space (hit through the camera, following moving, scaled and turning parents) or on the
  screen. Hover, press, click, focus, arrows and d-pad, `Tab` / `Shift+Tab` (new default actions `ui_next` and `ui_previous`), confirm and cancel,
  `Panel.modal` scopes, `kind` toggle and slider (with a `knob` and a `fill` entity), and `InteractableVisual` children that show, hide or tint per state with no
  script. `ui.on` gets `hover`, `blur`, `press` and `release`; `game.click`, `ui.widgetAt`, `ui.rectOf`, `ui.focus`, `ui.state` and
  `ui.set_slider` find it by id. The recipe is in docs/MENUS.md, "Widgets from your own entities" (Roguestory FB-0006).

A camera inside the UI, and studio lighting

- New widget `CameraView`: it draws a named Camera inside its rectangle, clipped by a ScrollList, layered like any widget and
  under a modal Panel's own widgets, so a 3D item, a portrait or a minimap needs no hole cut in the page. The pointer over it
  is the game event `ui.viewPointer` (`ui.on("viewPointer", fn)`: down, drag, up and the wheel, with `u`, `v`, `dx`, `dy`) so a
  script can turn what it shows; `pointerEvents`, `captureWheel`, `tint` and `resolution` tune it. docs/MENUS.md, "A camera inside
  the UI". Not yet: a render texture as the source (only cameras), and in a view no bloom, colour filter or debug draw.
- `Camera.lighting: "studio"` ignores the scene's lights, ambient, sky and fog and lights with a key, fill and rim of its own
  (`studioIntensity` scales them): an item looks the same on a stage far from the level and in a bright scene.
- `Camera.viewport` says which rectangle its fractions count (the game target, the design resolution grown by Expand), and
  `Camera.viewportSpace: "design"` counts them on the design area instead (LL/FB-0014). `RenderStats` has `views`.
- Larkspur Lodge's item view is a `CameraView`: no four bands around a hole, no darkened colours; the wheel zooms it.

Input routing: a consumed action, text input mode and the wheel under a modal

- `input.consume(action)`: later readers in the frame see the press as gone, for the action and for every action on the
  same key (Escape is `ui_cancel` and `pause`). The UI consumes `ui_submit` when it clicks a focused Button or Toggle and
  `ui_cancel` when a drag takes it or a `ui.on("cancel")` handler returns `true`, so Escape closes a dialog without also
  opening the pause menu (LL/FB-0008).
- `input.textInputMode`: true while a TextField has the focus (or a script set it); actions bound to printable keys read
  as up meanwhile, so typing P in a TextField does not pause. The menu kit's on-screen keyboard sets it, its
  `ui.on("cancel")` returns `true`, and `MenuStack.busy` resets when a scene builds a `MenuStack` (LL/FB-0503).
- `Panel.wheelPassThrough`: a modal Panel leaves the mouse wheel to scripts (LL/FB-0012).
- Larkspur Lodge drops its `MenuStack.busy` routing around the dialogue log, the screens and the save dialog.

Right to left: the UI mirrors itself and a Text has a direction

- `ui.mirrorRtl` (on by default; `"ui": { "mirrorRtl": false }` in factoria.json, `ui.mirrorRtl = false` in a script, the
  `ui.set_mirror_rtl` command): in a right-to-left language (`i18n.direction` rtl) the screen-space UI is mirrored by the
  engine. The `anchor.x`, `pivot.x` and `position.x` of every widget flip, a Toggle's box sits at the right of its label, a
  Slider runs from right to left (drawing, click and arrow keys), a Button's icon changes side, and the Text, Sprite and
  Shape2D below a widget go with it. `ui.rectOf`, `ui.state`, clicks and the editor's picking follow. A project that placed
  its widgets by hand for Arabic or Hebrew turns it off, or deletes that code (LL/FB-0903).
- A `CameraView` changes side with its layout but never shows a mirrored picture, and its `ui.viewPointer` `u`, `v`, `dx` and `dy` are not
  flipped.
- `UiBox.mirror` (`mirror: false` on any widget): the widget and everything below it keep the place they were authored in,
  for a map, a 3D view or a joystick.
- `Text.direction`: `auto` (default), `ltr` or `rtl`, the base direction of the paragraphs. `auto` with a localization
  key (`key` on a Text or a widget) takes the language's direction, so a Hebrew line that starts with a key name or a
  placeholder is right to left without a U+200F mark; `rtl` also makes `align: "start"` the right edge. The `visibleCharacters`
  reveal still follows the order of the text (LL/FB-0904). docs/LOCALIZATION.md, section 6.
- Larkspur Lodge lost `kit.mx` and the U+200F marks of `locales/he.json`.

A typewriter reveal and Korean that keeps its words

- `Text.visibleCharacters` (-1 = all, the default) draws only the first n characters of a Text, counted in grapheme clusters
  (a letter with its accents, an emoji sequence or a Hangul syllable is one). The text is laid out as a whole and then
  clipped, so the box keeps the size of the full line while it reveals; a right-to-left line appears from its right end
  (LL/FB-0004). docs/TEXT.md, "Typewriter reveal".
- `Text.wordBreak`: `auto` (default), `normal` or `keepAll`. A wrapped Korean line now ends at spaces and keeps its words
  whole by default; `normal` also breaks between Hangul syllables (the old behaviour), `keepAll` makes Chinese and Japanese
  break at spaces only too (LL/FB-0902). Chinese and Japanese without spaces still wrap between characters under `auto`.
- Larkspur Lodge's dialogue box lays its line out with `maxWidth` and reveals it with `visibleCharacters`: no hand-written
  wrapping, no blank lines padding the box.

Every hit of a ray, and colliders you can switch off

- `physics.raycast3dAll(origin, dir, maxDistance, opts)` and `raycast2dAll(from, to, opts)` return every collider the ray
  crosses, nearest first, up to `opts.maxHits` (default 32); the command is `physics.raycast_all`. No more casting again
  from just past each hit.
- `Collider3D.enabled` and `Collider2D.enabled` (default true), writable at run time: a disabled collider is skipped by
  raycasts, shape casts, overlaps, contacts and trigger events and left out of the NavMesh3D bake, and the component stays,
  so a door that opened can close again. The change takes effect at the next physics sync (once a frame, before scripts).

Glyph atlas that refills its texts

- The glyph atlas grows 1024 -> 2048 -> 4096 before it clears, and says so in the log. When it grows or clears halfway
  through a frame, the frame is gathered again, so no `Text` or UI label stays blank (LL/FB-0901). `RenderStats` has
  `glyphAtlasSize` and `glyphAtlasResets`. docs/TEXT.md, Limits.

Isometric tilemaps and cell picking

- `Tilemap.projection: "isometric"` draws diamond tiles (a 2:1 city or strategy map) as one batched mesh, row by row so the
  tiles nearer the viewer cover the ones behind them. `groundHeight` is the diamond's height (0 = `tileSize.y`) and
  `groundOffset` the pixels between the top of the tile image and the diamond's top corner, so a tile can be a block, a tree or
  a house taller than its ground. The entity's position is the top corner of cell (0, 0).
- Everything that reads a Tilemap follows the projection: `solidTiles` colliders are diamonds, `occludesLight` shadows follow
  the diamonds, `nav.findTilePath` returns the diamond centres and distances, `entity.bounds()` and the editor's outline and
  click area cover the diamonds, `scene.import_ascii` and `tilemap.set_tile` work as before, and the `anchor` of
  `scene.import_ascii` places an isometric map by its bounds.
- `entity.tilemap.cellAt(point)` (a `{col, row}`, or `null` outside the map) and `entity.tilemap.cellToWorld(col, row)` for both
  projections, and the commands `tilemap.cell_at` and `tilemap.cell_to_world`.
- The sprites section of the AI guide says how items of one layer are ordered (lower y on top, then creation order).
- Tidewater Market's ground (terrain, trees and roads, about 2600 sprites) is one Tilemap with a tileset per season: its game
  scene has 246 entities instead of 2826, the title 112 instead of 2712 and the stress scene 1029 instead of 4840. The title and
  stress scenes draw one call more, because the tileset is a second texture. The trees are part of the ground now, so a
  building covers the trees in front of it.

A CJK font subset from the locales

- `assets.subset_font {source, locales, keep, out, axes}` cuts a font down to the characters of `locales/<language>.json` (the
  languages of `localization.languages` by default; the same characters `factoria validate`'s glyph check asks a font for) plus
  ASCII, Latin-1, the full-width forms, CJK punctuation and `keep`. A variable font is pinned to one instance (`wght` 400 by
  default), the shaping tables stay, and the result lists the characters the source lacks. It uses HarfBuzz's subsetter (vendored in
  `external/harfbuzz`, linked by the tools only): no Python or fontTools. Tidewater Market's 17 MB Noto Sans SC becomes a 340 KB
  subset with the command, and its `make_subset.py` is gone. TEXT.md and LOCALIZATION.md no longer send you to `pyftsubset`.

A picture of the running game as a texture

- `render.captureTexture({ width, height, fit })` makes a `Texture` of the frame the player sees (HUD included) at the size
  asked, up to 2048 px a side: `fit: "cover"` (default) cuts the middle part with that aspect ratio out, `"stretch"`
  squeezes the whole frame in. A capture at the game's size has exactly the pixels of a screenshot. `texture.id` (`"runtime:3"`)
  goes in `Sprite.texture`, `Panel.texture` or `Button.icon`. `texture.toPNG()` gives the picture as Base64 text (`storage`
  keeps JSON), `render.textureFromPNG(text)` makes a texture of it again, `texture.destroy()` frees it; 32 textures at most.
  A run with no renderer gets a flat placeholder of the right size (`texture.placeholder`), so the saving code still runs.
  The pixels come from the readback each backend already had for screenshots. See SCRIPTING.md, "Render".
- Tidewater Market's save slots (and the autosave) show a real picture of the town at the moment of the save instead of the
  run-length map; an old save with no picture keeps the map. The pictures are not part of the cloud copy.

Web audio without the deprecated node

- The web player plays through an `AudioWorkletNode` fed from the main thread by messages (no threads or `SharedArrayBuffer` needed),
  with a `ScriptProcessorNode` only where worklets are missing: no deprecation warning in the console, a smaller buffer, and no
  underruns at 60 fps. Latency is measured in EXPORTING.md (TM/FB-0054).

Gendered strings and the kit's loading line

- A string table entry can have a gender, `{"text": "Ligera", "gender": "f"}` (`f`, `m` or `n`), and a sentence picks its
  form by it: a select entry is an object with `f`, `m`, `n` and `other` forms (`"ship_the": {"f": "la {name}", "m": "el
  {name}", "other": "{name}"}`), chosen by `args.gender`. `i18n.gender(key)` gives the gender of a string; `i18n.t` falls to
  `other` (warning once) when the gender or the form is missing. `factoria validate` warns about a select entry without a form
  the language uses and about a name that lost its gender; `i18n.export` and `i18n.import` (CSV and XLIFF) carry the forms
  (`ship_the#f`) and a `key#gender` row. docs/LOCALIZATION.md, section 5c, also says how to phrase around case.
- The menu kit's loading screen writes `i18n.t("loading.progress", {percent})` (the Text has no key), so "Cargando... 40%"
  is Spanish in Spanish. Games that copied the kit keep `loading.text` until they take the new `loading.js`, scene and strings.

A chart widget

- `Chart` draws `values` (one series, or several) as bars or lines inside a widget rectangle, in one batch: the axis is
  automatic (always including the `baseline`, zero by default) unless `min` / `max` are set, a baseline rule, `marks` (vertical
  rules at sample indexes), `colors` per series, and the axis maximum and minimum written in the language's number format.
  `slots` keeps each sample's width while a rolling series fills up. The sample under the pointer is reported: `ui.on("chartHover",
  (e) => ...)` gets `index`, `series` and `value` (`index` -1 when the pointer leaves), and `Chart.hoverIndex` / `hoverSeries`
  hold it. Tidewater Market's charts panel is two Charts instead of pools of rectangles and lines.

A choice card and modal panels

- `Panel.modal`: while the panel is active the mouse, the wheel and keyboard / gamepad navigation reach only its widgets (a
  focus scope). What is under it gets no hover, press, click, focus, tooltip or drop, the focus stays inside it,
  `ui.pointerOverUi` is true everywhere and the wheel is not passed on. The topmost modal panel (highest `layer`) is the scope.
- The menu kit has a `card` part: `Card` in `scripts/ui/card.js` with `prefabs/ui/card.prefab.json` is a modal card with a
  title, a wrapped rich-text body, choice buttons that each have a detail line, a choice greyed out with its reason shown, a
  result stage with Continue and a `holdClock` option (`game.paused` while it is open); mouse, arrows and pad. See MENUS.md.
- Tidewater Market's event and story cards are the kit's card; its draw calls and entities are the same.

Atlas packing while developing

- `assets.pack_atlas {folder, out, table, maxSize, padding}` packs a folder of images into one PNG and writes the frame table
  (`rect` and `pivot` per frame) that a Sprite's `region` and `pivot` read. Packing again keeps the frames whose size did not
  change where they were, so adding a picture changes one line of the table. docs/ASSETS.md says when the export's atlas
  groups are enough and when an atlas while developing is worth it. Tidewater Market uses it instead of its Python script.

A strategy camera

- Camera helpers for a 2D camera: `camera.zoomAt(screenPoint, factor, { min, max })` zooms towards the cursor (the world point
  under it stays under it), `camera.panBy(screenDelta)` moves the world with a drag, `camera.clampTo(rect, { margin })` keeps
  the view inside a rectangle (centred when it is smaller), and `camera.zoomOf()`, `camera.setZoom(zoom)` and
  `camera.orthoSizeFor(zoom, designHeight)` convert between pixels per world unit and `Camera.orthoSize`.
- The menu kit has a `cameraRig` part: `scripts/camera_rig.js`, a behaviour for the camera entity with drag pan, keys, edge
  pan, wheel zoom to the cursor between `zoomMin` and `zoomMax`, and a limit from `entity.bounds()` (`boundsEntity`). It
  ignores the wheel and new drags over the UI and the wheel a ScrollList took. `project.add_menu_kit` adds its `camera_*`
  input actions. The recipe is AI_GUIDE.md section 9.6.1.
- Tidewater Market drops `camera_math.js` and `camera_rig.js` for the kit's rig (`scripts/game/map_camera.js` adds its gamepad
  cursor and latched drag on top); its draw calls and entities are the same.

Buttons with an icon

- `Button.icon` (a texture), `iconRegion` (a sprite-sheet frame), `iconSize` and `iconPosition` (`left`, `top` or `alone`)
  draw an icon inside the button, so a click on the icon presses it. The label sits beside or under the icon, the pair
  centred; `alone` draws the icon only. `autoSize` grows the button to hold both and `autoShrink` shrinks the label to the
  room the icon leaves. Tidewater Market's build menu items are Buttons with the building as their icon.

Drag and drop

- `draggable` on any widget or Panel (`true`, or `{ "payload", "slop" }`) lets the player drag it with the mouse, a finger or
  a gamepad cursor (`ui.setPointer`). `ui.on("dragStart" | "dragOver" | "drop" | "dragCancel", fn)` reports the source, its
  payload, the pointer and the target (a widget, or `null` over the world). `ui.setDropTarget(widget, true | false | fn)` and
  `ui.setWorldDropTarget(...)` say what accepts, `ui.setDragImage(widget)` makes a widget follow the pointer, `ui.dragging`
  tells scripts a drag is on, `ui.cancelDrag()` ends it, and `game.drag(from, to)` drives it in tests. When a drag starts the
  press is dropped: the release makes no click, and a tooltip hides. `ui_cancel` cancels a drag instead of sending `ui.cancel`.
  Tidewater Market drops its own drag code for the worker chips.

Modifier chords in input bindings

- A binding takes modifiers: `"Ctrl+Z"`, `"Shift+MouseLeft"`, `"Ctrl+Shift+S"`, in `factoria.json` `input.actions`,
  `input.rebind` and `input.player(i).rebind`. `Ctrl`, `Shift`, `Alt` and `Super` name either side's key, and so do they in
  `input.keyDown` / `keyPressed` / `keyReleased`; `"Shift"` alone is a binding too. When one action binds `Z` and another
  `Ctrl+Z`, the chord wins: `Z` does not fire while Ctrl is held. Chords print back as `Ctrl+Alt+Shift+Super+input`.
  A bad chord is an error that says which part is wrong and what to write (`"Cntrl+Z"`: did you mean `Ctrl`), in
  `factoria validate` too.
- `input.lastPressed()` (and the player's) returns the chord when modifiers are held. A modifier pressed on its own is
  now reported when it is released, not when it goes down, so a "press a key" screen can record `Ctrl+Z`. The menu kit's
  Controls tab records and shows chords (and keeps mouse chords out of per-player bindings).
- Tests: `game.keyDown("Shift")` / `keyUp("Shift")` hold a modifier (the left key), `game.tapKey("Ctrl+Z")` taps a chord. The
  `game.input` command and replay files accept `Ctrl`, `Shift`, `Alt` and `Super` as key names too.
- Tidewater Market binds Ctrl+Z, Ctrl+Y (with the plain Z and Y it had) and Shift+click (a road or a demolish takes two
  clicks, as with the hold-free option) through the engine.

Tooltips

- `tooltip` on any widget or Panel (a localization key, `{ title, lines, args }`, or a function from
  `ui.setTooltip(entity, fn)` that returns the text when it shows). It shows after `ui.tooltipDelay` seconds of rest within
  5 pixels, beside the pointer and flipped to stay on screen, is styled by the new `"ui": { "tooltipDelay", "tooltipOnTouch",
  "tooltip" }` of `factoria.json` and stays off on touch unless the project turns it on.
- `ui.showTooltip(content, { x, y })` and `ui.hideTooltip()` for what is not a widget, `ui.setWorldTooltip(fn)` for a
  pointer over no widget, and `ui.tooltip` (also `tooltip` in `ui.state`) to read what shows. `ui.check_layout` reports a
  `tooltip` issue for an invalid or screen-sized tooltip. Docs: MENUS.md, SCRIPTING.md.
- Tidewater Market drops its own Tooltips class for the engine feature (TM/FB-0007).

The web's hide and close signals, and storage that scales

- A web export raises `suspend` when its tab is hidden and `resume` when it is shown again (`visibilitychange`), and `quit`
  when the page goes away (`pagehide`; it cannot be cancelled there). The save folder is copied to IndexedDB right after
  those handlers run, so a `storage.set` inside one is kept (before, only a 500 ms timer was scheduled). SCRIPTING.md
  ("Window close") lists which of `blur`, `suspend` and `quit` each platform raises; MOBILE.md and EXPORTING.md say what the
  web does (TM/FB-0021).
- `storage` writes one file per key in `<save folder>/storage/`, so a save rewrites its own key only. An older `storage.json`
  is read at the first start, split into key files and renamed `storage.migrated.json`. `storage.size(key)` gives the bytes
  of a key's file. `storage.set(key, value, {compress: true})` stores the value zlib-compressed. `storage.setAsync(key, value,
  options?)` returns a Promise and writes off the frame (a worker thread; between frames on the web); the writes still waiting are made after the
  `suspend` and `quit` handlers. Docs: SCRIPTING.md
  (storage) (TM/FB-0022).
- Tidewater Market writes its timer and season autosaves with `storage.setAsync` (compressed) and its blur, suspend and quit
  saves at once with `storage.set`.

Tile paths on a reusable grid, and flow fields

- `nav.createGrid({ width, height, cost?, origin?, cellSize? })` keeps a cost grid in the engine. `nav.findTilePath(grid,
  from, to)` takes it instead of the `{ width, height, cost }` array, with the same options and the same paths, but a call
  no longer converts the whole array and sweeps it for its cheapest cell, so a short route stops costing the size of the
  map. `grid.setCost(col, row, cost)` changes one cell (`getCost`, `setCosts`, `version` and `findPath` are there too).
  The array form works as before.
- `nav.flowField(grid, goals, { diagonals })` searches once from one or more goal cells: `field.stepToward(col, row)` gives
  the next cell toward the nearest goal in O(1), `field.distance(col, row)` the cost and `field.pathFrom(col, row)` the
  whole way. A field made before `grid.setCost` is rebuilt the next time it is asked.
- The `nav.flow_field` command is the stateless form (distances for the whole map, plus the next step and the path from a
  cell). In a debug build, 600 walkers on a 60 x 60 map for 75 ticks cost about 228 s with the array form, 8.2 s with the
  kept grid and 0.16 s with flow fields (a benchmark test prints it). Docs: NAVIGATION.md, PERFORMANCE.md.
- Tidewater Market's own distance fields are now `nav.flowField` over a `nav.createGrid` (TM/FB-0006).

Players for a development build

- `factoria setup webplayer` (and `setup.install {component: "webplayer"}`) builds the web player from the engine checkout
  `factoria` was built from: it uses an Emscripten SDK it finds (`$EMSDK`, `emcc` on `PATH`, the checkout's `.cache/emsdk`,
  `~/emsdk`) or fetches the pinned 6.0.10 into `.cache/emsdk`, runs the `web-release` preset and leaves the player in
  `build/web-release/player`, which `factoria export --platform web` prefers. An up-to-date player is not built again.
- `factoria setup players` on a development build whose version has no release no longer stops: it takes the players of the
  newest release, installs them under this version's folder and warns that their build fingerprint will not match, so an
  export that uses them needs `allowPlayerMismatch` (`--allow-player-mismatch`).
- docs/EXPORTING.md: the Emscripten setup under Web and "A development build: players from the checkout".

The export's size report, and the web page's icon

- Every export names the five folders that weigh most in what ships (`largestFolders` in `--json`) and warns when a `store/`,
  `screenshots/` or `src/` folder, at any depth, is packed, pointing at `export.exclude`.
- A web export lists the raw and about-gzip size of each file of the zip, the total, and how long the gzip total takes to
  download at 1, 5, 20 and 100 Mbit/s (`webFiles`, `webBytes`, `webGzipBytes`, `webDownloadSeconds` in `--json`).
- A web export links a `favicon.png` (64x64) made from the game's `icon` in `index.html`, instead of an empty icon; the
  page template has a new `{{favicon}}` placeholder. A game without an icon keeps the empty icon.

Rich text: bold, colours and icons inside a text

- `Text.markup: true` reads `[b]bold[/b]`, `[c:good]coloured[/c]` and `[icon:fish]` in the text, and so does the label of a
  `Button`, `Toggle`, `Slider` or `TouchButton` with `markup: true`. Wrapping (also between CJK characters), alignment,
  `maxWidth` and `autoShrink` work on the whole line, and `ui.measureText(text, { markup: true })` and `entity.bounds()`
  measure what is drawn. An icon is a rectangle of a project texture as tall as the line. The glyphs of a Text, of any
  colour and weight, are one batch; each texture that icons come from adds one more.
- The new `text` section of `factoria.json` names the colours (`text.colors`), the icons (`text.icons`: texture and pixel
  region) and the bold file of each font (`text.fonts`). `Text.bold` (and the same field of the widgets) draws a whole text
  bold. A font without a bold file is emboldened by the engine; `factoria validate` suggests adding one, and checks the
  section, the files it names and the markup of scene texts.
- Mistakes never hide the sentence: an unknown tag, a `[` without `]` or an unknown colour shows as written, with one
  warning per text. `ui.markupProblems(text)` lists them for a test. `[[` writes a literal `[`.

An interface size, Panel minimum and maximum sizes, and events for the size options

- `ui.scale` (0.5 to 3, default 1) makes the whole screen-space interface bigger or smaller: the size, offset, padding,
  spacing, margins and font size of every widget and of screen-space `Text`, `Sprite` and `Shape2D` are multiplied by it
  (`ui.textScale` comes on top for text), and anchors do not move. `ui.rectOf`, `ui.state` and the hit test are in screen
  pixels and follow it; `Panel.size` and `ui.measureText` stay in UI units. `"ui": { "scale": 1.25 }` in `factoria.json` is
  the start value (a project reload applies it only when the file changed), `ui.set_scale` is the command and `ui.state`
  reports `uiScale`. Screen-space particle emitters are not scaled. docs/TEXT.md, "Interface size".
- `Panel.minSize` and `Panel.maxSize` (0 = no limit on an axis) bound the size of a Panel, also one with `fit: true`.
- `ui.on("scale", fn)` and `ui.on("textScale", fn)` run once per change, with `{ value, previous }`, like
  `i18n.on("change")`.
- `ui.check_layout` takes `uiScales` and crosses them with the languages and text sizes. The menu kit's Options has an
  "Interface size" button (the sizes at which its panel fits), saved as `uiScale` in `settings.js`. Games that copied the
  kit copy `scripts/settings.js`, `scripts/ui/options.js`, `prefabs/ui/options.prefab.json` and the `options.uiScale`
  string of `locales/*.json`.
- Fixed: a `Text` with `maxWidth` and a centred or right-aligned `align` is drawn in a box of `maxWidth`, but its bounds (layout,
  `ui.state`, editor) were those of its widest line, so a right-aligned note in a right-to-left Panel was drawn off its
  rectangle. Its bounds are now the box it is drawn in; left-aligned text is unchanged.

Tooling: feedback merges, perf files of several scenes, and recording progress

- `factoria feedback collect` no longer merges two gaps whose titles only share a few words: a title that contains
  another needs four shared words, the `missing` text weighs in, an entry may list `distinctFrom` ids it never merges
  with, and the report prints each merged entry's similarity to its group.
- ctest runs every `<example>.perf.json` and `<example>-*.perf.json` file of an example, so a game with a title, a game
  and a stress scene keeps a budget for each (docs/PERFORMANCE.md).
- `factoria run --record-video` prints its progress (frames written of the total) on stderr while it records.
- PLATFORM.md says that `game.platform.calls()` shows a `stats.add` as a `stats.get` and a `stats.set`.

Audio: buses of your own, the voices that play, `onEnded`, and a listener zoom

- `factoria.json` `audio.buses` declares buses with a parent (`"ambience": { "parent": "sfx" }`). A bus scales the sounds
  played on it (`audio.play(clip, { bus: "ambience" })`), its parent scales it in turn, and it takes `audio.setVolume`,
  `audio.bus(name)` effects, ducking and snapshots like the built-in ones. `factoria validate` checks the names with a
  "did you mean". The built-in buses (`master`, `sfx`, `music`, `ui`) work as before.
- `audio.activeVoices()` lists the sounds that play now, and `audio.play(path, { onEnded })` calls back once when a sound
  finishes, is stopped with `audio.stop` or is dropped by a full mixer (not on `stopAll` or a scene load).
- `game.audioLog()` has an entry for every `audio.setVoiceVolume` on a playing voice (`kind: "setVoiceVolume"`, with
  `voice` and `fade`); `toContainPlayed` skips them.
- `AudioListener.zoom` (default 1) scales how far positional sounds reach: a zoom of 2 doubles the distance.

Script helpers: the rng state, running a module, did-you-mean, a shadowed method

- A generator from `rng.create` has a `state` (a 32-bit integer) you can read and assign, documented as stable like the
  algorithm: store it in a save and assign it to resume the same stream.
- `script.eval` takes `module` (a project path), `call` (an exported function) and `args`, and returns the function's
  result: `factoria call script.eval` runs a pure module with no scene.
- `didYouMean(word, choices)` is exported from `"factoria"`; docs/EXTENDING.md has a recipe for a project tool that
  validates the cross references of `data/*.json` with file, JSON pointer, hint and did-you-mean.
- A `Behaviour` field named `on`, `after`, `every` or `world` replaced that method without a word. The first instance of
  the class now logs one warning naming the field, and `factoria validate` reports it.

`ui.rectOf` and hidden parents; docs for what was already there

- `ui.rectOf(entity)` returns `null` for a widget or screen-space Text hidden by an inactive parent, as `ui.state` already
  left it out; it used to give the rectangle it would have had. The docs now say that a child of a hidden Panel keeps
  `active` true (ask `activeInHierarchy`), that a screen-space line's `size.y` points up, how a Panel's children are
  placed, how to press the focused widget in a test, and the test section of SCRIPTING.md uses `fa.call("ui.state")`.

A wrapped text measures its widest line; a Toggle's box follows the font size

- With a renderer a wrapped text was at least as wide as its `maxWidth`, so `ui.overflowed`, `ui.check_layout` and
  `autoShrink` flagged and shrank a short label for nothing, while headless measured the widest line. Both measure the
  widest line now, so a layout test and the window agree. A wrapped Text with a pivot or centre alignment is placed by that
  width, so it can sit a little differently than before.
- A Toggle's box is one line of its label high (`fontSize` at the player's text size, times 1.2, plus 4 px), no longer the
  widget's height minus 12: a two-line label or a taller toggle keeps the same box. `Toggle.autoShrink` and `minFontSize`
  fit the label into the room right of that box.

Web, Android and iOS players are checked against the engine build

- `factoria export` compared only a desktop player with its own build. It now compares the web player
  (`factoria_player.wasm`) and the prebuilt Android and iOS libraries too: a player of another build stops the export with
  the two builds and what to do (`factoria setup players`, the checkout's `build/web-release`, or `--allow-player-mismatch`).
  A web export with no `--player` takes the player whose build matches, the checkout's `build/web-release` before the
  installed one. A script that imports an export the player lacks, or calls a method of the engine's objects it lacks,
  now gets an error naming the module and the missing export and saying the player may be older than the game's engine.

A UI hit test, a virtual pointer, the consumed wheel and an empty focus

- `ui.widgetAt(x, y)` returns the topmost visible widget or Panel at a screen point (nothing for empty space or a row a
  ScrollList clips) and `ui.pointerOverUi` says whether the pointer is over one. A game with a gamepad cursor no longer
  scans the scene itself.
- `ui.setPointer(x, y, { down })` drives hover, press and click like the mouse, from the next frame on, until
  `ui.setPointer(null)`: for a gamepad cursor and for tests.
- A ScrollList with more content than it shows keeps the mouse wheel: `input.mouse.wheel` reads 0 that frame and
  `ui.wheelConsumed` is true, so a camera that zooms with the wheel needs no check of its own.
- `ui.focus(null)` holds until the next arrow / D-pad press: an open panel's `autoFocus` no longer takes the focus back
  on the next frame.

Web exports download the game's code once

- The page of a web export handed the downloaded wasm to the player through `Module.wasmBinary`, which Emscripten 6 no
  longer reads, so the browser fetched the 8 MB file a second time on every load. It now uses `Module.instantiateWasm`:
  one download, with the progress bar, and a plain error when the browser cannot compile it. Re-export a web game to get
  the new page.

Versions for the script API

- `tools/common/api_since.json` has a `"script"` section: each function, type and member of the scripting API says which
  release added it, taken from the `api.json` of every release tag. The typings (`types/factoria.d.ts`) and the
  scripting API part of docs/COMPONENTS.md carry it as `@since` for what came after 0.1.0, so `nav.findTilePath`,
  `bt`, `http.fetch` or `game.today` tell when they appeared.

Two more behaviour tree nodes, and a tile counter that sees every change

- `bt.parallel(...children)` (or `bt.parallel({ succeed: "any" }, ...children)`) ticks all children each tick and fails at
  the first failure; `bt.repeat(child, times?)` runs the child again after each success (once per tick), forever or `times`
  times. SCRIPTING.md, "AI: behaviour trees".
- `nav.tileVersion(tilemap)` now also counts writes that replace `tiles` as a whole (`tilemap.tiles = [...]`,
  `scene.set_component`, editor edits), not only `setTile`.

A smaller player

- The linker drops the engine code no game reaches: `-dead_strip` on macOS and iOS (the macOS player goes from 10.2 to
  9.1 MB without symbols), `--gc-sections` on Linux. Android, Windows and the web already did. A game plays the same: five
  levels of the reference games give the same world state and screenshot after 1200 frames. Sizes per platform:
  docs/EXPORTING.md, "Size of the player".

Burrow Brigade drops the workarounds M29 made unnecessary

- Burrow Brigade gives every torch, crystal and magma source its own Light2D (no pool of 16), writes fog and shift tiles with
  `tilemap.setTile`, copies and pastes through the system clipboard, keys its daily dig and board by the UTC day with
  `{day}`, and detects a Steam Deck with `game.device.steamDeck`. Its feedback entries are closed with what it kept and why.
  Its perf baselines count the real lights (entities 145, lights 20, `maxLights` 24).
- Burrow Brigade's Options > Video uses the window API: windowed, borderless window and full screen with
  `window.setMode`, and a monitor button (`window.monitors()`, `window.setMonitor`) where the platform has several
  monitors; an older save's full screen flag still works. A pad player keeps its pad's `padId`, and a pad that returns
  in another slot is followed (`gamepadConnected`).

Split screen: camera viewports

- `Camera.viewport` is the part of the screen a camera draws into: `[x, y, width, height]`, each 0 to 1, origin top-left, default
  `[0, 0, 1, 1]`. Every active camera with `primary: true` draws in ascending `depth`, each with its own scissor, culling, 2D lights
  and 3D lights, and `clear` per camera. Two or more cameras make a split screen (two or four players) or an inset. The UI and every
  `space: "screen"` item is drawn once over the whole screen; bloom and `colorFilter` run once with the lowest-`depth` camera's
  settings. A scene with a bad `viewport` fails to load, naming the entity and the field; a script that sets one live is clamped
  with one warning. At most 8 cameras are drawn. A scene with one full-screen camera renders as before. Before, only the
  lowest-`depth` primary camera drew: a scene with a second active `primary: true` camera now draws it too, over the first; set
  `primary: false` on a camera that must not draw.
- Scripts: `camera.all`, `camera.at(point)`, `camera.screenRay(point, camera?)`, and `camera.worldToScreen(v, camera?)` /
  `camera.screenToWorld(v, depth?, camera?)` take an optional camera (without one, a screen point uses the camera under it, so a click
  picks what the player under the pointer sees). `input.mouse.world` and a touch's `world` use that camera. The audio listener
  without an `AudioListener` is the first camera drawn. `game.renderStats()` counts per frame, over all cameras. Recipe: AI guide
  section 9.29. Known limit: screen-space `lit` visuals get only ambient light in a frame with several cameras.
- Burrow Brigade: Options > Video > "Split screen when players part" (off by default). On, miners can part and the screen splits into
  two to four views; off keeps the shared camera and the leash.

The exported player checks a build

- `factoria_player` (the exported game) takes `--input <replay>`, `--dump-state <file>` and `--screenshot <file>` together
  with `--frames N`: the game runs headless through the same code as `factoria run --headless --frames N`, plays the replay
  `input.record` writes, writes the world state after the last frame and a PNG of the last frame. Both equal what
  `factoria run` writes for the same replay and frame count. Exit codes: 0, 1 after a script error, 2 for a missing replay,
  an unwritable output or a missing `--frames`. New test `cli_player_replay`; EXPORTING.md has "Checking an exported build".

Tile pathfinding and behaviour trees

- `nav.findTilePath(map, from, to, {costs, diagonals, maxNodes, closest, allowBlockedGoal})` and the command
  `nav.find_tile_path`: deterministic A* over the cells of a `Tilemap` (solid tiles block, `costs` per tile index) or of a
  `{width, height, cost}` grid for games that keep their own map. Diagonals never cut corners; `closest` returns the nearest
  reachable cell. The result lists `cells` and the world `points` of their centres. `nav.tileVersion(tilemap)` counts the
  `setTile` writes so a script knows a kept path is stale. NAVIGATION.md, section 7.
- `import { bt } from "factoria"`: behaviour trees in plain JS (`Tree`, `sequence`, `selector`, `condition`, `action`,
  `wait`, `cooldown`, `inverter`, `succeeder`, `SUCCESS`, `FAILURE`, `RUNNING`), ticked by the script with its own `dt`.
  SCRIPTING.md, "AI: behaviour trees", and an enemies recipe in the AI guide (section 9.27).

Steam Remote Play guests and `platform.cloud.stat`

- New platform service `remotePlay`: `platform.remotePlay.sessions()` lists the guests connected through Remote Play
  Together (`[{ id, guestName, guestId, deviceName, formFactor, resolution }]`) and `platform.on("remotePlay", ...)` gets
  `{ status: "connected" | "disconnected", session }` as each comes or goes. The Steam plugin offers it when the Steam
  library has `ISteamRemotePlay`. A guest's controls arrive as one more gamepad; the engine does not say which pad is which
  guest. The fake store has `game.platform.remotePlayConnect(info)` and `remotePlayDisconnect(id)` (commands
  `platform.remote_play_connect` and `platform.remote_play_disconnect`).
- New `platform.cloud.stat(key)`: `{ exists: false }` for a missing key, else `{ exists: true, size, modified }` without
  returning the text (`modified` in Unix seconds, `null` on Apple, which keeps no time). Steam answers the file's time,
  Google Play the snapshot's last-modified time (it opens the snapshot to count the bytes), the fake a deterministic
  counter (`game.platform.set({ cloudClock })` sets it). To tell which save is newer keep a revision counter in the saved
  value; PLATFORM.md says why.
- The Steam, Apple and Google Play code for both was checked against the mock (Steam) and by reading (Apple, Google Play)
  only: no real Remote Play session or real store was tried.

Light2D on a light buffer: shadows from solid tiles and no 16-light cap

- Point lights are now added up in a light buffer (one draw call, RGBA16F, or RGBA8 at half range on a GPU that cannot
  blend half floats) that lit sprites, tiles and shapes read, instead of every pixel looping over 16 lights. A frame keeps
  up to 256 lights (it was 16): the same choice as before (directional first, then the lights that reach the view, more of
  their radius in view first, then the brighter), the same stats (`lights2d`, `lights2dDropped`) and the same
  `perf.measure` `lights`. The look of a scene with 16 lights or fewer is unchanged (the render goldens still match).
  A lit sprite or tile WITH a normal map is still shaded per pixel by the first 16 lights, because its shading depends on
  the direction of each light; flat surfaces get all of them. A scene without Light2D, or without lit visuals, draws no
  light pass; one with them adds one draw call (the perf baselines of Burrow Brigade went from 10 to 11 draw calls).
  The light pass needs an orthographic camera; a perspective camera shades per pixel with 16 lights as before.
- New field `SceneSettings.lightScale` (0.25 to 1, default 1): the size of the light buffer as a fraction of the
  picture. 0.5 quarters the fill cost of the lights, a good setting for phones and the web.
- New `Light2D.castShadows` and `Tilemap.occludesLight` (both default false). A Tilemap with `occludesLight` makes the
  tiles of its `solidTiles` block the light of every point Light2D with `castShadows`: the far side of a wall stays
  dark, the wall's own face stays lit, and a light inside a solid tile shines out of it. Editing a tile at run time
  (`tilemap.setTile`, the command `tilemap.set_tile`) moves the shadows on the next frame. The
  shadows are traced on the CPU per light (1024 rays) and looked up on the GPU; a light that does not move reuses its rays.
  At most 32 point lights per frame cast shadows (the ones ranked first); the others shine through walls, with one
  warning per scene. The new stat `lights2dShadowed` (`renderStats()`, `game.render_stats`) counts the ones with a shadow.
- docs/PERFORMANCE.md has the cost per light and per shadow-casting light measured on a Mac, and advice for mobile and
  the web; docs/AI_GUIDE.md a recipe for lights with tile shadows. The doc strings and docs no longer say "16 lights".
- `FA_LIGHT_FORMAT=rgba16f|rgba8|none` picks the light buffer format at start-up (testing the fallbacks; `none` uses the
  per-pixel loop over 16 lights, the same as a GPU that cannot render to either format).

Analytics with consent and remote config

- New `analytics` and `remoteConfig` in `factoria`, on top of `http.fetch` (docs/ANALYTICS.md). `analytics.event(name,
  props)` queues small events and sends them in batches to the `endpoint` of the new `"analytics"` section of
  `factoria.json`, but only after `analytics.setConsent(true)`: before that nothing is kept or sent, and a refusal forgets
  the queue. A batch goes out at `batch` events, after `flushSeconds`, on suspend and on quit (the quit waits up to 3
  seconds for the request). A failed send (no connection, 408, 429, 5xx) is retried with a doubling wait, at most 3
  attempts per event; another 4xx drops the batch. `consentFromAds: true` lets the ad consent answer the question until
  the player does. `remoteConfig.get(key, fallback)` reads the JSON of the new `"remoteConfig"` section, caches the last
  good answer in `storage` for offline runs and checks each value against the type of its fallback.
- `factoria validate` checks both sections (hosts declared in `"network"`, `https://`, ranges, misspelled keys) and warns
  about an `analytics.event(` call in a game without the section. The iOS export adds a Product Interaction (Analytics, not
  linked, no tracking) entry to the privacy manifest when the section exists.
- Menu kit: new part `analyticsConsent` (the question on the first run, from the main menu) and an Options switch,
  with `analyticsConsent.*` and `options.analytics` in the locale tables. The kit's own `recipe.test.js` answers the
  question before it opens the main menu.
- Tests: `game.analytics` (`sent`, `requests`, `queued`, `restart`) and `game.remoteConfig.restart`; the answers come from
  the fake `http.fetch`. `storage.keys()` hides the engine's `factoria.*` keys and `storage.clear()` removes them.
- No new command and no `api_since` row: both services are script modules, listed in `factoria api`.
- Burrow Brigade's statistics, balance and online news now use the engine API.

Local multiplayer: actions per player

- `input.player(i)` (0..3) gives each person sharing the machine their own view of the project's actions: `down`,
  `pressed`, `released`, `value`, `axis` and `vector`, driven only by the devices assigned with `player(i).use({ pad,
  padId, keys })`. `keys` names a key scheme (`"all"`, `"left"`, `"right"` or one from the new `factoria.json`
  `input.schemes`, which can `extend` another, add `keys` and give per-action `actions`); `padId` follows a physical
  gamepad across slot changes. A player with no device reads nothing; the global `input.*` still hears every device.
  Each player has bindings of their own: `bindings`, `rebind`, `reset`, `lastPressed`, and `export` / `import` to save
  them in `storage`. A bad slot, scheme, key or action throws with "did you mean" and changes nothing. Mouse and touch
  are not read by players. `input.keySchemes()`, `input.keySchemeKeys(name)` and `input.maxPlayers` list what exists.
  Tests start with no devices; a game assigns them when its scene starts. SCRIPTING.md and the AI guide (9.28) have the
  recipe.
- The menu kit's options script has a `players` property: with more than one, the Controls tab gets a Player button and
  rebinds, resets and saves the controls of the chosen player (`settings.playerBindings`); a single-player game is
  unchanged. MENUS.md and the `en`/`es`/`ar` texts have the two new keys (`options.player`, `options.playerBinding`).
- Burrow Brigade drives its four diggers with `input.player(i)` and four key schemes in `factoria.json`; its saved
  controls move to the engine's action names the first time they are read.

Recording input and starting a scene with props

- The input recorder moved from the editor into the engine and now hears the keys, mouse, touches, Back and gamepads
  (connections, buttons, axes) itself. The new command `input.record` (`{action: "start" | "stop", path?}`) records any
  running game; `stop` returns the replay that `factoria run --input` plays (optionally written to `path`). The editor
  records its Play sessions with the same recorder. Not recorded: mouse wheel, locked-mouse movement and typed text.
- Scenes can start with props: `scene.load(path, props)`, `game.load(path, props)`, `game.loadJson(scene, props)`, the
  `scene.load` command's `props`, and `factoria run --props JSON|FILE`. `game.sceneProps()` returns them from the scene's
  first `onStart`. A reload keeps them; a load without props gives `{}`.

Monitor choice and window modes

- `window.monitors()` lists the monitors (`index`, `name`, `size`, `primary`, `current`), `window.monitor` is the one the
  window is on and `window.setMonitor(i)` moves it there (Windows, macOS, Linux; XRandR on Linux is loaded when the game
  starts, so a machine without it lists one monitor). `window.setMode("windowed" | "borderless" | "fullscreen")` and
  `window.mode` choose how the window is shown; `setFullscreen(bool)` keeps working. On Windows and Linux full screen is
  a frameless window over the monitor, so `"fullscreen"` and `"borderless"` look the same; on macOS `"fullscreen"` is the
  native Space and `"borderless"` a frameless window that hides the menu bar and the Dock. SCRIPTING.md says what each
  OS does. `window.supports("borderless")` and `window.supports("monitors")` tell what the platform can do.
- Menu kit options screen: the Full screen toggle is now a Window mode button (windowed, borderless, full screen) and a
  Monitor button (only with more than one monitor). `settings.js` saves `windowMode` and `monitor` (`{ index, name }`)
  instead of `fullscreen` (a save from the older kit is still read) and restores the monitor, then the mode, at start.
  The locale tables have `options.windowMode`, `options.mode.*` and `options.monitor` instead of `options.fullscreen`.

`http.fetch` on every platform

- `import { http } from "factoria"`: `http.fetch(url, { method, headers, body, timeout })` returns a Promise of
  `{ status, ok, headers, text, json() }`. Windows uses WinHTTP, macOS and iOS `NSURLSession`, Linux libcurl (loaded
  when first used: the player does not link it, and without it `platform.has("http")` is false), Android
  `HttpURLConnection` and the web build the browser's `fetch` (CORS applies). An HTTP error status resolves with
  `ok: false`; a request that did not complete rejects with `code` and `hint`.
- A game declares the servers it calls in `factoria.json` `"network": { "hosts": [...], "purpose": "..." }`: `https://`
  only (plain `http://` to `localhost` for a test server), the host must be listed (`"*.example.com"` covers
  subdomains), no password in the URL, redirects only to https. `factoria validate` checks the section and warns about a
  script that calls `http.fetch` with no host declared. The Android export adds the `INTERNET` permission only when
  hosts are declared.
- Tests, `factoria call`, `session`, headless runs and MCP never touch the network: the fake answers what
  `game.platform.respond("http.fetch", { status, headers, text, json, error })` scripted. An input recording
  (`input.record`, editor play sessions) keeps the answers in the `"http"` field of the replay, and
  `factoria run --headless --input` plays them back.
- `platform.state` shows `httpBackend`, `httpWhy` and `networkHosts`. A plugin cannot offer the `"http"` service.
- New [NETWORKING.md](docs/NETWORKING.md); LEGAL.md and MOBILE.md no longer say that games have no network.

Audio buses: effects, ducking and snapshots

- Every bus (`sfx`, `music`, `ui`) is mixed into its own buffer before the master, so a bus can have effects:
  `audio.bus("music").lowpass(800)` (12 dB per octave, 0 or null = off), `.reverb(0.3)` (a small room), and
  `.duck("sfx", 0.5, 0.05, 0.5)` to push the music down while a sound effect plays (`.unduck()` or `duck(null)` ends it).
  `lowpass`, `reverb` and `volume` take `{ fade }` to slide; a bus with no effect does no effect work. The master takes
  a low-pass and a reverb too, but no ducking. Effects stay across scene loads, like volumes.
- Changing a bus volume (`audio.setVolume`, `audio.bus(name).volume(v)`) now ramps over about 10 ms instead of jumping, so
  it no longer clicks; `{ fade }` makes it a longer, straight-line fade.
- Snapshots: factoria.json `audio.snapshots` names sets of bus settings (volume scale, low-pass, reverb, ducking) and
  `audio.snapshot("underwater", { fade: 1 })` moves every bus to one, a bus it does not list going back to neutral.
  `factoria validate` reports a bad catalog with the JSON pointer, a fix and a "did you mean".
- Commands `audio.bus` (set or read a bus) and `audio.snapshot` (apply one, or list them) for MCP and the CLI.
  SCRIPTING.md ("Audio buses") has the cost of each effect and a recipe.

Test runner and `ui.check_layout`

- `game.click(widget)` (and `mouseMove`, `touch`, `touchStart`, `touchMove` with a widget) lays the UI out first, so a
  panel opened in the same frame can be clicked with no `step` or `ui.layout()`. It throws, naming the widget and why,
  for a widget that is inactive, has no area or is scrolled out of its `ScrollList`, instead of clicking nowhere.
- `game.tapKey(key)` presses and releases a key over one frame; SCRIPTING.md shows `game.tapKey("Enter")` submitting a
  `TextField`, and `fa.call("fs.write", ...)` saving a file from a test.
- `ui.check_layout` judges a widget in a `ScrollList` by the part the list shows (a row half inside is no longer
  reported for its clipped half) and takes `steps` per scene (click, key, action, frames) to open a panel before the checks.

Menu kit: optional shop and age gate, a Controls tab from the actions

- `project.add_menu_kit`: the `main-menu` part no longer brings `shop` and `ageGate`. `{"parts":["main-menu"]}` writes a
  main menu without the Shop button, the shop panel and the age gate line (and without their scripts); add `shop` and
  `ageGate` to `parts` to have them (no `parts` still adds everything).
- The options screen's Controls tab lists every input action of the game except the `ui_*` ones (it was a fixed list of
  `move_left`, `move_right`, `jump`, `pause`), labelled with `options.action.<action>` or the action's name when the game
  has no such string. The `actions` property of the prefab's Script (`"props": { "actions": [...] }`) picks and orders them.

Gamepads that come and go, and the Steam Deck

- `game.on("gamepadConnected" | "gamepadDisconnected", fn)` gives `{ slot, id, name, type }`. `input.gamepad(i).id` and
  `.name` read the same. The id is stable per physical pad on Windows (XInput slot), Linux, macOS, iOS, Android and the web,
  and a pad that returns gets its old slot when it is free. Tests: `game.gamepad(i).connect({ id, name, type })`.
- `game.device.steamDeck` and `game.device.handheld`. The Steam plugin says whether this is a Deck (plugin API version 4,
  `set_device_fact`); without it the `SteamDeck=1` environment variable decides. `game.setDevice` accepts both.

Tilemap: tileset margin and spacing, `setTile` without rewriting the array

- `Tilemap.margin` and `Tilemap.spacing` (pixels, default 0) describe a tileset image with a border and gutters between
  tiles. The 2D renderer (also the normal map), the tile count, `factoria validate` and the level commands read them.
  `assets.slice_sheet` is for animation grids and does not take them.
- `entity.tilemap.setTile(col, row, id)` and `getTile(col, row)` change one tile in place, and the new command
  `tilemap.set_tile` does the same from the CLI and MCP. The renderer reads the grid in place (no copy per frame), and 2D
  physics rebuilds only the colliders of the tiles you changed; a write of the whole `tiles` array still works and is
  caught by a hash.

The time of day and the day boundary

- `game.today()` also returns `hour`, `minute`, `second` (the local time of day) and `utc: { year, month, day, iso }` (the
  date in UTC). A built game reads the clock again about once a minute and on focus or resume, and `game.on("dayChanged",
  fn)` runs once when the local calendar day changes. `game.setDate`, `--date` and replay files (`time`) take a time,
  `game.setDate(iso, { utcOffsetMinutes })` the time zone; moving a test across midnight sends `dayChanged`.
- `platform.leaderboards.submit(id, score, { day })` and `entries(id, { day })` address the daily board of a given day (the
  fake and Steam keep every day). Without `day` a daily board is the local date's; pass `game.today().utc.iso` to both
  for one board worldwide. Game Center and Play Games reject a day other than the local or UTC today with `unsupported`.

Thai line breaks and the sara am check

- A wrapped line now also breaks after U+200B ZERO WIDTH SPACE (no width, never drawn), the UAX #14 spaces (U+1680,
  U+2000-U+2006, U+2008-U+200A, U+205F) and a hyphen (`-` unless a digit follows, U+2010), so Thai, Khmer, Lao and Burmese
  text whose translator marks word boundaries with U+200B wraps there. Unmarked text still needs a dictionary and is not broken.
- `FontCoverage::missing`, `localization validate` and the runtime missing-glyph warning check U+0E33 and U+0EB3 as the parts
  HarfBuzz always decomposes them into (U+0E4D U+0E32, U+0ECD U+0EB2), so a font lacking the nikhahit is reported.

Light2D in the stats and the perf budget

- `RenderStats` (`game.render_stats`, `game.renderStats()`) gets `lights2d` and `lights2dDropped`: the Light2D lights
  that shade a frame (at most 256 since the light buffer, see above) and the ones left out. `lights` and `lightsDropped` stay the 3D lights.
- `perf.measure`'s `lights`, and so the `maxLights` budget, is now the most 2D plus 3D lights of any frame: a budget
  written for a 2D game used to watch nothing.
- The Light2D lights of a frame are the ones that light the view: directional lights first, then the point lights whose
  radius reaches the camera's visible rectangle (more of their radius in view first, then the more intense ones). A light
  entirely off-view is never kept over one in view. More than the budget (256) in view logs one warning per scene naming the count.

Clipboard and window close

- `clipboard.read()` (a Promise) and `clipboard.write(text)` work on Windows, macOS, Linux and the web
  (`window.supports("clipboard")`); phones answer `unsupported`. Headless runs and tests use an in-memory clipboard, and a
  replay's `"clipboard"` entry sets it. A focused `TextField` pastes with Ctrl+V (Cmd+V) and copies with Ctrl/Cmd+C.
- `game.on("quit", fn)` runs when the player closes the window (close button, Cmd+Q, Alt+F4); `event.cancel()` keeps the
  game running. `game.quit()` closes without asking again. Desktop only. Test helper `game.closeWindow()`.

Music: scene loads, live volume, layers

- Fixed: a scene load stopped the sounds but kept the old scene's music in the mixer's memory, so a scene with the same
  `settings.music` started nothing (state said the track played, no voice did). A scene load now restarts the new scene's
  music, the same track included. `audio.music(path, { persist: true })` keeps a track playing through scene loads; a scene
  with the same `settings.music` does not restart it, another track replaces it.
- `audio.setVoiceVolume(id, volume, fade?)` changes the volume of a playing sound, with a straight-line fade.
- `audio.musicLayers({ name: path }, { volume, fade, persist, levels })` starts stems on the same audio sample (one lock,
  so no block of audio has only some of them) and `audio.setLayer(name, level, fade?)` fades them; the play log entries
  have a `layer` field. Layers loop, are never evicted by a full mixer, and `audio.stopMusic` stops all of them.
- `assets.synth_sound` levels every preset to about -18 LUFS (peak under -1 dBFS) instead of a -3 dBFS peak: squares, saws
  and noise were around -5 LUFS and tripped `factoria validate`'s loudness warning. The bytes of every seed change.

Steam from one Mac: optional plugin, exports, app 480, capsules

- The Steam plugin logs a warning, not an ERROR, when Valve's library is missing or Steam is not running. `project.new_plugin`
  (so `platform.add_backend`) now declares the plugin `"optional": true`; pass `optional: false` for a plugin the game needs.
- `project.export` takes `allowMissingPlugins` (`--allow-missing-plugins`): a plugin whose build for the target platform is
  missing is left out instead of stopping the export, a warning names it and the result lists it in `pluginsLeftOut`. It also
  works for a plugin that is not optional (the warning says scripts that call it fail). Plugins are still built only for the
  computer you build on: EXTENDING.md and EXPORTING.md say to take the other platforms' builds from CI.
- A desktop player with no build fingerprint (release 0.2.0 and older) now gets its own error: it predates fingerprints,
  `factoria setup players` installs the same one again, so use a newer player, `--player` or `--allow-player-mismatch`.
- `publish.steam` accepts app 480 (Spacewar) in a dry run with a warning; a real upload still refuses it.
- `assets.draw_capsules` takes `safeArea` (margins the logo stays inside, per store if needed; the Microsoft poster keeps its
  bottom third free by default) and `logoAnchor` (a name or a point of the safe area), and `focus` moves the logo when the key
  art already has the capsule's proportions. Misspelt keys get a "did you mean".

Video player

- A `Video` component draws an `.mpg` (MPEG-1 video with MP2 sound, decoded by pl_mpeg on the CPU, the same on every
  platform) in a UI rectangle: `fit` (`contain`, `cover`, `stretch`), `path`, `autoplay`, `loop`, `volume`, `bus`, `tint`.
  Time follows the game clock (it pauses with the game, headless runs and tests decode the same frames) and the sound plays
  through the mixer. Scripts use `entity.video`: `play`, `pause`, `stop`, `seek`, `time`, `duration`, `playing`, and
  `on("ended", fn)` (the game event `video.ended`).
- `assets.import` converts `.mp4`, `.m4v`, `.mov`, `.webm`, `.mkv` and `.avi` to an `.mpg` in `assets/video/` with ffmpeg
  (`factoria setup ffmpeg` installs one) and records where it came from; an `.mpg` is checked and copied. `factoria
  validate` reports a `Video` whose file is missing or that the engine cannot play, with the ffmpeg command that fixes it.
- `docs/MENUS.md` has a studio-intro recipe where any button skips the video. Clockwork Courier's intro is now a 4.8 second
  video of half a megabyte (FB-0051), recorded from an animated scene kept in `store/intro/`.
- Software renderers (llvmpipe, WARP) draw a full-screen video in about half the time: batches of plain textured quads
  (sprites, panels, a video) use a shader without the branches of glyphs, shapes and 2D lights, and a `Video` leaves out
  its background when the opaque picture covers it and draws an opaque picture without blending.

Steam Deck keyboard

- Plugin API 3: `add_text_input` registers a handler the engine calls when a `TextField` takes or loses the focus with a
  gamepad (the field's rectangle in window pixels, its text, `maxLength`), and `submit_text` hands text from the platform's
  keyboard back to that field on the next frame. Plugins built for version 1 or 2 are unaffected. `input.platformKeyboard`
  is true while a plugin's keyboard has the field, and the menu kit's on-screen keyboard stays closed then.
- The Steam plugin uses it: on a Steam Deck or in Big Picture it opens Steam's floating keyboard over the field, or the
  full-screen one where the floating one is not offered. Real-Deck check steps are in `docs/PLATFORM.md`.

Navigation: off-mesh links and walkable moving bodies

- `NavLink3D` (an entity's position to `end`, `bidirectional`, `cost`) is an off-mesh link: `nav.findPath` may take it to
  cross a gap, and the result's `links` lists `{point, entity}` where each link starts. A one-way link refuses the way
  back; a link whose end is off the mesh is ignored.
- `Collider3D.navWalkable` on a kinematic or jointed body (a rope bridge, a seesaw, a moving platform) leaves it out of
  the static bake and adds its top surface as walkable cells wherever it is now, joined to the ground within
  `stepHeight`; only the cells it left and entered are re-marked. `nav.info`, `nav.bake` and the editor's "Show navmesh"
  show links and these cells (`links`, `walkableBodies`). Clockwork Courier marks its bridges, seesaw and platforms, and
  `dog.js` needs one query instead of two (CC/FB-0056).

Physics across platforms

- The engine is built with no floating-point contraction (`-ffp-contract=off`, `/fp:precise`), and the simulation no longer
  calls the C library's `sin`/`cos`/`atan2`/`asin`/`acos` (each platform rounds their last bit differently): it uses
  deterministic versions built from `+ - * / sqrt` (`fa/core/det_math.h`), so physics is meant to give the same bits on
  Linux, Windows and macOS. CI prints a physics replay hash on those jobs and compares it with one committed value
  (`FA_PHYSICS_REPLAY_HASH`).
- `robust(check, { runs, nudge })` in `factoria:test` runs a check under small repeatable nudges of the bodies, so a level
  test asserts what is robust instead of an exact frame count. Clockwork Courier's "shortcut is not slower" test uses it
  (FB-0055).

Ads with consent on Android

- A plugin backend that offers only the `"ads"` service is an **ads backend**: it works next to the game's store backend, the
  engine sends `ads.*` to it and everything else to the store backend, `platform.ads.backend` picks one when a game has
  several, and `platform.state` shows `adsBackend` and `adsWhy`. Development runs and tests keep the fake.
- `platform.add_backend {"backend": "admob"}` writes and builds the `admob` plugin: Google's consent form (UMP) first, then
  the Mobile Ads SDK, one kept rewarded ad per placement, `{rewarded: true}` only from the SDK's reward callback. The
  app id is `platform.ads.appIds.android` in factoria.json, written into the manifest by the export; a development
  export always uses Google's test app id and test rewarded ad. `factoria validate` and a release export warn about the
  sample id, a missing app id or a placement without `ids.admob`. The command `admob.status` lists what is wrong.
- `platform.ads.audience` (`"general"`, `"children"`, `"mixed"`), `platform.ads.setUnderAge(bool)` and
  `platform.ads.privacyOptions()`; `platform.ads.consent()` gains `privacyOptions`. In a `"mixed"` game nothing is requested
  until the age is told. The menu kit has an `ageGate` part for it (`project.add_menu_kit {"parts": ["ageGate"]}`), and
  its options screen shows an "Ad privacy settings" button when Google requires one. The fake store answers all of it.

Ads with consent on iOS

- The `admob` plugin now has an iOS side, written in Swift: Google's consent form (UMP) first, then, only when
  `platform.ads.trackingPrompt` is true, Apple's "Allow tracking" sheet (never for a player under age), then the Mobile Ads
  SDK and the kept rewarded ad per placement. It behaves and answers like the Android one, including the audience,
  `setUnderAge`, `privacyOptions` and `admob.status`; `platform.ads.consent().tracking` is Apple's status when the game asks
  for the sheet. macOS has no AdMob SDK: the plugin offers no ads there and `platform.has("ads")` is false.
- Google's iOS SDK is a download, never in the repository: `platform.add_backend {"backend": "admob", "sdk": "<zip or folder>"}`
  copies its two XCFrameworks into the plugin (git ignores them) and builds the Swift side with Xcode.
- A plugin's `ios/plugin.json` can list vendored `xcframeworks` (the iOS export checks them, links the slice of the SDK and
  embeds a dynamic one) and `infoPlist` keys. The export writes `GADApplicationIdentifier` (`platform.ads.appIds.ios`; a
  development export always carries Google's iOS test app id), Google's `SKAdNetworkItems` and
  `NSUserTrackingUsageDescription` (`platform.ads.trackingDescription` or `trackingDescriptionKey`, translated per language of
  the game). A placement's iOS unit is `ids.admob_ios`. `factoria validate` and the export warn about the sample or missing
  iOS app id, a placement without `ids.admob_ios`, a tracking prompt with no ads plugin for iOS, and a tracking prompt with
  `export.ios.privacy.tracking` off.

Menu kit command

- `project.add_menu_kit {parts, overwrite}` (`factoria call project.add_menu_kit`) copies the menu kit of `docs/MENUS.md`
  into a game: main menu, options, credits, shop, pause, loading screen, on-screen keyboard and subtitles, each part with
  what it needs. It merges the kit's texts into the game's `locales/<language>.json` without replacing a key, leaves a
  file the game changed alone unless `overwrite` is true, and does nothing the second time. The kit lives in
  `templates/menus/`. The Controls tab of the options leaves out an action the game does not have.

Text entry on every device

- A focused `TextField` raises the phone's keyboard and hides it on blur (not for gamepad players). The menu kit in
  `docs/MENUS.md` has an on-screen keyboard for gamepad players (Latin, Cyrillic and Greek layouts; other scripts fall
  back to Latin). The web player takes typed text on mobile browsers through a hidden input, and the web smoke types
  into a field.

A 3D example game for phones

- Clockwork Courier (`examples/clockwork-courier`) is a complete 3D game made for phones first, the way your AI makes a
  game: a wind-up robot delivers parcels across six toy-town levels before its spring runs down, with touch controls
  (stick, buttons, drag to orbit, pinch to zoom), keyboard and gamepad, imported CC0 models and sounds, guard dogs,
  physics props, a studio intro and a loading screen, achievements, leaderboards, a paint shop, a "remove ads" purchase
  and a rewarded "more time" offer on the test store, comfort and accessibility options (left-handed layout, control size,
  reduced motion, assist mode, captions), English, Spanish and Japanese, and store texts, images and a trailer. Its
  `SHIPPING.md` says how each export was run (iOS Simulator, Android emulator, browser, macOS) and what is still done by
  hand.
- With this release's fixes, Clockwork Courier dropped the rest of its workarounds: the dog and tap-to-move walk on a
  `NavMesh3D`, the level panels are three shared prefabs, the name screen uses the menu kit's keyboard, the paints are
  per-material colours, the stars are ★ and ☆, and its tests reset their state with `game.resetState` and drive the
  mouse and the wheel. `ui.check_layout` finds no issue in it. Its studio intro is a video (FB-0051) and its dogs
  follow the courier across the rope bridges (FB-0056): no entry of its feedback is open.

A couch co-op example game for the desktop

- Burrow Brigade (`examples/burrow-brigade`) is a complete 2D game for one to four players on one screen, made for the
  desktop and Steam first, the way your AI makes a game: the miners dig down through mines generated from a seed (the
  same mine on every machine), in three strata with water, cave-ins and magma, gather ore, rescue moles and ride the lift
  up before their lamps burn out, while beetles, goblin thieves and the Mole King hunt them through the tunnels they dig.
  It has a join screen for four pads or a keyboard, per-player rebinding, a shared camera, revives, a pad unplugged
  mid-game, a camp with upgrades, three save slots whose format changed once (old saves are migrated), cloud copies, a
  daily dig and seed codes, achievements, stats and all-time and daily leaderboards on the test store, rich presence and
  Steam Deck checks, a news panel, remote balance values and opt-in analytics from its own server (a fake one in tests),
  music layers, ducking and captioned sound cues, display options, hold or toggle, a game speed for assist, English,
  Russian and Thai, and store texts, images and a trailer rebuilt by scripts. Its `SHIPPING.md` says how the Windows,
  Linux and macOS exports were made and what is still done by hand, and its `ENGINE_FEEDBACK.json` what it had to work
  around: those entries rank the next milestone.

Sliders and lists

- `Slider.format` shows the value as a pattern: `"{v:1}x"`, `"{percent}%"` (the value times 100); `Slider.formatKey` takes the
  pattern from a string table, so it can differ per language. `game.setSlider(id, value)` in a test drags a slider like a
  player: clamped, snapped to `step`, `ui.change` sent (the `ui.set_slider` command); writing `Slider.value` from a script
  still sends nothing. `ScrollList.shrink` makes a list as tall as its content up to the room the other children leave, so a
  short list in a `fit` panel makes a short panel.

Tests

- `factoria:test` can hold a mouse button and turn the wheel (`game.mouseDown`, `mouseUp`, `wheel`), so a drag orbit and a
  wheel zoom are tested through the input path. `game.resetState({ storage, platform })` clears the save data and the fake
  store between tests of one file, `game.setSystemLanguages([...])` sets what `i18n.systemLanguages` answers, and a quit
  request in a test (`game.quit()`, Back nobody consumes) sets `game.quitRequested` instead of stopping the run.
  SCRIPTING.md says `scene.load` from a test takes effect next frame while `game.load` is immediate. The hook warning
  skips a method that takes arguments, like `start(seconds)`.

Animation

- Models animated by node transforms play with no change to the file: a body part that is a child of an animated bone
  (RobotExpressive) and an animated mesh node with no skin at all (Kenney's cube pets) follow their node, through a
  rigid skin the importer makes. A file with clips that nothing can play logs one warning naming the clips.
- A glTF with several skins is drawn with each mesh's own skin (it used the first skin's palette for all, which bent the
  second skin's mesh out of shape). `Animator::skinPalettes` holds one palette per skin. Clockwork Courier imports the
  original robot and dog again and drops `tools/skinify.py` (FB-0001, FB-0002).

Graphics quality

- `window.renderScale` (0.5 to 1) draws the picture at a share of the window's size, in games and in tests;
  `window.supports("frameCap" | "renderScale" | "fullscreen" | "resize")` says what this run can do (the frame cap still
  throws on a phone: read it first); `game.device` gives `formFactor`, `gpuBackend`, `memoryGB` and a `tier` (`"low"`,
  `"medium"`, `"high"`) to pick a preset, with fixed values headless; tests pretend with `game.setDevice(...)`.
- `game.renderStats()` in tests (and the `game.render_stats` command) draws a frame when none was drawn yet and adds
  `shadowCasters` and `textureMB`. `perf.measure` records `triangles`, `lights` and `textureMB`; `perf.check` fails when
  they pass the baseline (only for baselines that have them) or the new `budgets` (`maxTriangles`, `maxLights`,
  `maxTextureMB`, `maxDrawCalls`, `maxEntities`).

Rendering

- `MeshRenderer.materialColors` colours one material of a glTF model: `{"Body": [0.2, 0.8, 0.7, 1]}` replaces the
  base colour factor of the material named "Body" on its sub-meshes (its texture still multiplies it), while
  `color` keeps tinting the whole model and the other materials keep their own colour. Entities that differ only in
  `materialColors` are drawn in separate batches. `factoria validate` checks the names against the model and suggests
  the right one for a typo (FB-0031).

Scripts

- `scene.preload(path)` and `assets.preload(paths)` read a scene's files (or a list of assets) ahead of time, a few per
  frame, and return a handle with `progress` (0..1), `done` and a `promise`: a loading screen keeps animating while the
  next level is read, and the `scene.load` that follows reads nothing from the disk. Tests do a fixed amount of work per
  frame, so they give the same result on every machine; `game.fileReads()` counts disk reads. Clockwork Courier's
  loading bar now shows real progress and its intro reads the title screen while it plays (FB-0012).
- A script stopped for running too long while inside `find`, `findIndex`, `findLast` or `findLastIndex` no longer
  crashes the game (a QuickJS bug freed one of the array's objects too early; the engine replaces those four). And a
  timer, tween or `world.on` listener stopped this way ends alone: before, every script after it was stopped too.

Platform services

- Ads: the new `platform.ads` service (`available(placement)`, `showRewarded(placement)` resolving `{rewarded, reason?}`
  and `consent()`) works with the placements of `factoria.json` `platform.ads.placements`, and `platform.release` is
  false in development runs, tests and the MCP server. The fake store answers with a scripted test ad (nothing is
  drawn): `game.platform.ad("watched" | "closedEarly" | "noFill" | "consentRefused")` chooses how it ends (command `platform.set_ad`). The real
  networks (Google UMP and AdMob, Apple ATT) are not in yet: the native backends answer `unavailable`.
- A leaderboard takes `period`: `"allTime"` (default), `"daily"` or `"weekly"`. The fake keeps one board per day or
  week of `game.today()`, so a daily board is empty again after `game.setDate` moves to the next day. The store backends
  map the period too (next bullet).
- Daily and weekly leaderboards on the stores. Steam keeps one board per period, named `<store name> <periodKey>`; Game
  Center uses a recurring leaderboard of App Store Connect as it is, at its current occurrence, or reads a classic board
  with the `.today` / `.week` time scope; Play Games reads the `TIME_SPAN_DAILY` / `TIME_SPAN_WEEKLY` table. These backends
  no longer reject periods with `unavailable`. Each store starts a period at its own time (table in docs/PLATFORM.md,
  "Leaderboard periods"); `submit` and `entries` carry `periodStart` and `periodEnd` when the store says them (Game Center's
  recurring boards), on `entries` as properties of the array (FB-0030).
- Clockwork Courier uses them instead of its ad stub and its single daily board (FB-0028, FB-0030).
- The fake store can take a purchase back, as a refund does: `game.platform.revoke(productId)` in tests (command
  `platform.revoke`) removes it from `restore()` and sends the `purchase` event with `status: "revoked"`.
- `platform.purchases.finish()` of a transaction the game was not told about now rejects its Promise with code
  `unknownId` (it used to throw at the call), so `.catch()` handles it like any store failure.
- Leaderboards in factoria.json take a `nameKey` (a locale key) instead of `name`, like achievements; the request
  the backend gets carries the name in the current language. PLATFORM.md documents `game.project.platform`, the
  catalog scripts can read.

Localization

- Numbers and times follow the language: `{v:number:1}` and `{t:duration}` in a string table and `i18n.number(v, {decimals})`
  and `i18n.duration(seconds)` in scripts write 1234.5 as "1,234.5", "1234,5" (Spanish; "12.345,5" from five digits),
  "1.234,5" (German), "1 234,5" (French, narrow no-break space) or "١٬٢٣٤٫٥" (Arabic digits), and 83.4 seconds as "1:23.4".
  A small table in the engine, no ICU; a language it does not know is written like English (docs/LOCALIZATION.md).
  Clockwork Courier uses it instead of its own helper (FB-0039).
- `keyArgs` on `Text`, `Button`, `Toggle`, `Slider`, `TextField` and `TouchButton`: the values of a key's `{placeholders}`
  (and the `count` of a plural entry), so a script sets them once instead of rewriting `text` every frame, and a language
  switch keeps them. `TouchButton` has a localization `key` like the other widgets. `factoria validate` checks a key's
  placeholders against the entity's `keyArgs`: it warns for a placeholder with no arg and for an arg no translation uses,
  not for every key with placeholders.
- `ui.check_layout {scenes, languages, textScales, pseudo}` loads each screen with UI in each language and text size
  (default: every language, scales 1 and 2) plus a pseudo-localized pass that lengthens every string by 40 %, and lists
  every text that overflows its box (the `ui.overflowed` test), overlaps another or leaves the screen, with the scene,
  the entity and its path, the key and the languages and scales where it happens. Clockwork Courier's profile keys and
  intro texts that broke at 200 % now shrink (FB-0043).

Tools

- `scene.format` with neither `paths`, `all` nor `check` writes nothing and fails with `paths_required`, saying how many
  scene and prefab files would change and the first ones; `paths` names the files or folders to format and
  `"all": true` takes the whole project. `factoria validate`'s hint names the files.
- `project.new_plugin` and `platform.add_backend` take `dryRun` (they list the `files` and the `keys` of
  `factoria.json` they would write, and write nothing) and refuse an argument they do not know, with a "did you mean".
- They patch `factoria.json` instead of rewriting it: only `plugins.<name>` is added, and the other keys, their order
  and the layout stay as they were. `export` and `icon` saves (the editor, `assets.draw_icon`) use the same patcher.
- The plugin templates come with a `.gitignore` for their build output.
- `factoria api --dts` lists a native plugin that is not built without its load error, so the typings no longer
  carry this machine's folders and come out the same on every machine.

Exports and store files

- `Products.storekit` is written by every iOS export whose catalog has products, with or without the Apple plugin, and
  holds one localization per language of the game (names and descriptions from the products' `titleKey` /
  `descriptionKey` in `locales/`).
- An Android source build reads the CMake version it will use instead of requiring `cmake;3.31.6`: the SDK's, else the
  newest 3.24+ in the SDK, else a 3.24+ of the computer (passed to Gradle as `cmake.dir`), so it works offline. The error
  hint says how to get one.
- `factoria` and `factoria_player` carry a build fingerprint (the commit, `-dirty` when it had uncommitted changes;
  `factoria version` prints it). A desktop export with a player from another build stops with an error that names both
  builds; `--allow-player-mismatch` (the `export` command's `allowPlayerMismatch`) bundles it anyway.
- `setup.install {"component": "ffmpeg"}` (`factoria setup ffmpeg`) downloads a pinned static ffmpeg, so
  `factoria run --record-video trailer.mp4` works without installing it by hand; `setup.status` lists the component.

Assets

- `assets.import` of a `.glb` or `.gltf` copies the textures and buffers its `uri`s point at next to the model (with
  provenance), shares an identical file already there, warns when the destination holds a different image of the same
  name (kits that ship different `colormap.png` files) and stops on a different buffer; `factoria validate` reports a
  model whose texture or buffer file is missing.
- `assets.set_provenance` (and every command that edits `assets.json`) keeps the order of a hand-ordered file instead of
  sorting all of it; a sorted file stays sorted.
- `factoria validate`'s loudness warnings use the sound as it plays: a project with `defaults.audio.normalize` has no
  peak or loudness warning left for it.
- New `assets.synth_sound {path, preset, seed}` makes barks, growls, meows and the usual effects (coin, jump, hit,
  explosion, laser...) offline as a deterministic WAV, with its provenance; no provider and no key.

Physics

- 3D physics no longer depends on what the World held before a scene loaded: `Joint3D` constraints are solved in the
  scene's entity order instead of the order of their entity ids, so a rope bridge or a seesaw behaves the same after
  other scenes, destroyed entities or reused entity slots (a level test could take 2000 or 2800 frames depending on
  which tests ran first).
- `CharacterController3D` on moving and dynamic bodies: a kinematic platform it stands on carries it (displacement, and the
  turn of a spinning platform; `carriedByPlatforms`, default true), it presses on the dynamic body below with
  `mass` x gravity (`applyWeight`, `mass`), so a seesaw tips and a bridge plank sags, and `pushStrength` scales the push on
  the free dynamic bodies it walks into (a body held by a `Joint3D` is never shoved). Clockwork Courier dropped its
  workarounds (FB-0010, FB-0011).
- A dynamic body that starts inside a static collider is reported once in the log (both entities, the depth and the fix),
  and `factoria validate` warns about it for scenes.
- Joints form islands: a chain of planks falls asleep when it is at rest, a collision in one island no longer stops the
  rest of the world, and two bridges side by side move exactly as each would alone. Chains of three or more jointed
  bodies get more solver iterations and settle by themselves, so a rope bridge no longer needs heavy damping
  (FB-0014, FB-0015, FB-0017, FB-0053, FB-0054).
- `Joint3D.damping` (friction on the relative turning) and `Joint3D.stalled` (read only: a motor pushes and the joint
  cannot turn, for example a gate against a wall). `docs/AI_GUIDE.md` has a rope bridge recipe.
- `connected: ""` means the world on `Joint3D` and `Joint2D` in scenes, `factoria validate` and scripts.

Navigation

- Path finding for 3D characters. A `NavMesh3D` component (`size`, `cellSize`, `agentRadius`, `agentHeight`,
  `stepHeight`, `maxSlope`) is baked by itself from the static colliders inside its box into a walkable grid;
  `nav.findPath(from, to, { radius })` in scripts and `nav.find_path` return the few corner points of a path around
  walls and up ramps, never up a step above `stepHeight`. A start or goal off the walkable ground, or in another
  area, comes back as a result that says how far the nearest walkable point is and how to fix it; a `radius` bigger
  than the mesh was baked for is an error that says to bake for the bigger agent. `nav.bake` and `nav.info` report the
  cells and areas (no timing: two bakes are identical). A collider with `navObstacle` is left out of the bake and blocks
  the cells it covers each time it moves (a gate, a crate). The editor draws the walkable cells (Window > Show navmesh).
  Guide: docs/NAVIGATION.md (FB-0009).

Native plugins

- `"optional": true` on a plugin in `factoria.json` says the game runs without it: when its build for your computer is
  missing (a store SDK only some developers build), `factoria validate` warns instead of failing. Exporting for a
  platform still needs that platform's build.

Mac App Store

- `sign.macos` takes `distribution: "appStore"`: it signs the macOS export with the App Sandbox, an Apple Distribution
  certificate and a provisioning profile, and builds the signed installer `<game-slug>-macos.pkg` with `productbuild`.
  `identity: "-"` signs ad hoc so you can run the sandboxed game on your own Mac.
- `publish.appstore` uploads that `.pkg` too (`platforms: ["macos"]`).
- New `export.macos` settings: `buildNumber`, `usesNonExemptEncryption` and `entitlements`.

Microsoft Store

- `factoria export --platform windows --format msix` (or `export.windows.format: "msix"`) writes
  `<slug>-windows.msix` next to the Windows folder, from any computer: the unsigned package the Microsoft Store takes, with
  the manifest, the logos cut from your icon and the block map. The identity comes from the new `export.windows.msix`
  settings (the editor's Windows tab and Export window have them).
- New `sign.windows` signs the package with your `.pfx` (`signtool`, or `osslsigncode` on macOS and Linux) to install it on
  a PC; on Windows `testCertificate` makes a self-signed one. The password is only read from the environment.
- New `publish.microsoft` uploads the package with the Microsoft Store Developer CLI.
- The web export and the AppImage use a shared zip writer; their bytes did not change in meaning.

Scripting

- New `game.today()` returns `{ year, month, day, weekday, utcOffsetMinutes, iso }`: the player's real local date in a
  built game, the fixed date `2026-01-01` in `factoria test` and headless runs, and the date a replay recorded when it
  plays (an old replay without one uses the fixed date). `game.setDate("YYYY-MM-DD")` in `factoria:test` changes it, and
  `--date` does the same for `run`, `screenshot`, `test`, `call`, `session` and `mcp`. An impossible date (`2026-02-29`)
  or another format is an error that says what is wrong. Read the date with `game.today()`, never `Date`.
- New `game.on("suspend" | "resume" | "focus" | "blur", fn)` and `game.focused` tell scripts when the app goes to the
  background and back, or the window loses the focus. The new `factoria.json` setting `pauseOnSuspend` (default `true`)
  pauses the game and the music while the app is in the background; `game.suspend()`, `game.resume()`, `game.focus()`
  and `game.blur()` in `factoria:test` test it. A pause menu opened by a `suspend` handler stays after resume.
- Clockwork Courier uses the date and the lifecycle API instead of its workarounds (FB-0019, FB-0035).
- `factoria test` no longer stops a test file after 600 s in all: only a single test over 60 s is stopped, so a long file
  of quick tests passes in a Debug build on a busy machine. The message says which limit it was.

UI

- A child can be put at a place among its siblings, which is the order a `column` or `row` layout follows:
  `scene.set_parent {id, parent, index}` (also `scene.spawn {index}`), `entity.setParent(parent, keepWorld, index)` and
  `world.spawn(json, { parent, index })` / `world.spawnPrefab(path, { parent, index })`. 0 is first; an index outside
  0..(number of the parent's other children) is an error that says the range. The order is saved with the scene.
- One panel can serve several scenes: a prefab reference takes `overrides`, a map from a child of the prefab (its id,
  name or a path like `"Panel/Title"`) to the `name`, `tags`, `active` and `components` to change, and
  `world.spawnPrefab(path, { childOverrides })` and `scene.spawn {prefab, overrides}` do the same. A child or field that
  does not exist is an error with a "did you mean". docs/MENUS.md shows it. Clockwork Courier's FB-0032 and FB-0023.
- Text that fits: `autoShrink` (with `minFontSize`, default 10) on `Text`, `Button`, `Toggle`, `Slider` and `TouchButton`
  shrinks the font until the text fits its box (`Text.maxWidth` x the new `Text.maxHeight`, or the room the widget leaves
  its label), never under `minFontSize` times `ui.textScale`. `maxTextScale` on `Text`, every widget and `TouchButton`
  stops `ui.textScale` from growing that text past a scale (a heading at 1.3). `Toggle.maxWidth` and `Slider.maxWidth`
  wrap long labels, `Slider.labelAbove` puts the label above the track. Layout, `autoSize`, `ui.measureText` (new
  options, returns `fontSize` too), `ui.rectOf` and the 2D and 3D renderers use the same size.
- New `ui.overflowed(idOrEntity)` and `"overflowed": true` in `ui.state` say a text still does not fit its box.
- Clockwork Courier dropped its text-fit workarounds in the level select, HUD, toasts and options (FB-0041, FB-0042).

## 0.2.0

FactorIA 0.2.0 is about finishing and shipping a game: edit scenes by hand next to your AI, translate the game, add
achievements and purchases on Steam, the App Store and Google Play, and export it for desktop stores, phones and the
browser.

Edit by hand in the editor

- The editor has a Hierarchy and an Inspector now. The Hierarchy lists every entity as a tree: click one to select it (a
  click in the game view selects it there too), drag it onto another to make it a child, drop it on the empty space to
  make it a top-level entity, and right-click for create child, duplicate, rename, active and delete. There is a search box.
- The Inspector shows the selected entity's components with a field for every value: tick boxes, number drags that
  respect each field's range, vectors, colour pickers, drop-downs for choices and for other entities, file pickers for
  pictures, sounds and materials, and a text box for free-form JSON. Hover a name to read what it does. Add Component and
  the x on a component's header add and remove components.
- Everything you change by hand goes through the same commands the AI uses, so Undo works (one drag is one step) and a
  value a field does not accept is refused with the reason. While the game plays you can edit the running game; Stop
  takes those edits back.
- A `MeshRenderer` shows its material's settings with the right widgets (sliders, vectors, colour pickers) and a Reset
  button for each, and a material that does not compile shows its error right under the material field.
- The new Project panel (a tab next to Console, also in the View menu) lists the project's files with thumbnails, a folder
  tree, a type filter and a search box. Drag a picture, sound, font, mesh, script or material onto an Inspector field of that
  type to set it, drag a prefab onto the game view to spawn it where you drop it, double-click a scene to open it, and
  right-click a file to show it in the file manager, copy its path or delete it. `assets.list` now also reports `material`
  for `.material.json` files.
- New command `scene.set_parent` moves an entity under another one (or to the top level), for the AI too.
- Move, rotate and scale in the game view: select something and drag the arrows (W), the rings (E) or the handles (R) that
  appear on it; Q goes back to just selecting. The four buttons next to Undo do the same. Hold Ctrl to snap, press Esc in
  the middle of a drag to cancel it. A whole drag is one Undo step, it works for 2D and 3D, for things on the screen (like
  a score) and for things inside another, and while the game is paused it edits the running game.

Revert an AI run

- Before each AI run the editor now saves a checkpoint of the project's files. When the run changed something, the chat
  shows "This run changed N files" with a Revert button: one click (after a confirmation) puts back every file, deletes the
  ones the run created and puts the scene back as one Undo step. Undo revert takes it back, and Edit > Revert Last AI Run
  does the same from the menu. The AI is told about the revert in your next message. Checkpoints are kept in
  `.factoria/checkpoints/` (newest 30) and are also available as the commands `checkpoint.create`, `checkpoint.list`,
  `checkpoint.diff` and `checkpoint.restore`.

Debug your scripts in VS Code

- Press F5 in VS Code on a FactorIA project: the game starts and stops on your breakpoints. Step through your code line
  by line, look at every variable and at `this`, watch expressions, and type JavaScript in the debug console to read or
  change the running game. `factoria setup vscode` (or Install in the editor's Setup window) adds the extension to VS
  Code, and to Insiders, VSCodium and Cursor when you have them; new projects come with a `.vscode/launch.json`.
- Breakpoints can have a condition, a hit count or a message to print instead of stopping (a logpoint, with
  `{expressions}` filled in). The debugger can stop on every error your scripts throw or only on the ones nothing
  catches, and Pause stops the game wherever it is, even in an endless loop.
- Three ways to start: play the game in its window, run it without a window for a number of frames (with an input
  replay), or run your tests and stop inside them.
- For the AI: `script.trace` puts the same breakpoints on a headless run and returns what it saw as JSON (the call stack,
  the local variables and your watch expressions at each hit, and the logpoint lines), so it can find out why a script
  misbehaves without guessing. See `factoria docs read debugging`.
- Exported games cannot be debugged: debug the project.

Find out what makes your game slow

- A profiler: it tells you where the time of a frame goes, per part of the engine (physics, scripts, sound, drawing...) and
  per script class, with the milliseconds each class takes per frame and how often it runs, plus the GPU time (on
  Windows and Linux; other systems say why not) and memory use. It only measures: your game plays exactly the same.
- In the editor, View > Profiler shows it live while you play. Every play session you record now also keeps this
  summary in `play.report`, so the AI can see which script is the slow one.
- `perf.profile` does the same on a headless run, with an optional input replay to reach the heavy part of the game. See
  `factoria docs read performance`.

Your game in every language

- Keep your texts in string tables (`locales/en.json`, `locales/es.json`...) and show them with a `key` on a `Text` or an
  interface widget, or with `i18n.t("score", { points: 3 })` in scripts: placeholders, plural forms for each language and
  a fallback language are built in. The game starts in the player's system language, and `i18n.setLanguage("es")`
  switches at any moment, every text at once.
- Text is laid out properly in every script: Arabic letters join and right-to-left lines start from the right, Chinese,
  Japanese and Korean lines break between characters, and fallback fonts (`fallbackFonts` for the whole game,
  `languageFonts` per language, in the `localization` part of `factoria.json`) fill in the characters your main font
  does not have.
- A text size option for players: `ui.textScale` makes every on-screen text and widget label bigger or smaller.
- `factoria validate` finds missing and leftover keys (with "did you mean"), wrong placeholders and plural forms, and
  any character none of your fonts can draw, naming the text and the file.
- Send your texts to translators as a spreadsheet (CSV) or an XLIFF file with the command `i18n.export`, and bring the
  translations back with `i18n.import`.
- `factoria docs read localization` is the guide, and the ready-made menus have a Language option.

Achievements, leaderboards, cloud saves and purchases

- One script API for what a store gives a game: `platform` has achievements, stats, leaderboards, cloud saves, in-game
  purchases (with restore), the store's overlay and rich presence. You write your game once, and the store it runs in
  answers. List your achievements, leaderboards and products in the `platform` part of `factoria.json`.
- Steam, Apple (App Store purchases, Game Center, iCloud) and Google Play (Play Billing, Play Games, Play Integrity):
  `factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`, `"googleplay"`) sets one up in one step and
  lists what is left for you to do in the store's dashboard.
- While you make the game, and in every test, a pretend store answers, so your AI can test a purchase, a cancelled one
  or an achievement without a store account. An exported game with no store set up never gives purchases away.
- `platform.integrity.token` gives your game's server a signed token that vouches for the app and the device (Google
  Play).
- So far these were tried against simulated stores only: make a test purchase with the store's sandbox or test account
  before you release. `factoria docs read platform` is the guide.

Ready for the desktop stores

- `factoria export --release` on Windows, macOS and Linux puts the whole game in one file, `game.pak`, with the scripts
  compiled to bytecode. Exports no longer copy the project's top-level `README.md`.
- When an exported game crashes it writes a report (what happened, where in the code, the last lines of the log) in a
  `crashes` folder next to `log.txt`, plus a minidump on Windows. Nothing is sent anywhere: a player can send it to you.
- Upload your game to Steam (`publish.steam`, with steamcmd), itch.io (`publish.itch`, with butler), the Epic Games
  Store (`publish.epic`, with BuildPatchTool) and GOG (`publish.gog`, with Galaxy Pipeline Builder) from your AI or the
  command line, each with a dry run to try first. Passwords and keys stay in environment variables or your user
  folder, never in the project.
- macOS: `factoria call sign.macos` signs your exported app with your Developer ID, has Apple notarize it and staples
  the ticket, so players can open it without a warning.
- Linux: `factoria export --platform linux --format appimage` makes the game one AppImage file with its icon and menu
  entry. Linux games exported from the FactorIA download now run on older systems and in the Steam Linux Runtime (glibc
  2.31 or newer).
- `factoria call project.new_ci_workflow` writes a GitHub Actions workflow that validates, tests and exports your game on
  every push.

Phones and tablets

- Change to know about: `factoria export --platform android --release` now stops when your game has no signing key,
  because Google Play rejects an app signed with the debug key. The message tells you how to make a key. To try a release
  build on your own phone anyway, add `--allow-debug-key` (the export command's `allowDebugKey` option).
- Menus and heads-up displays can keep clear of the notch, rounded corners and system bars: switch on `safeArea` next to
  `anchor` on a sprite, text, shape, particle emitter or interface widget, and it is placed against the free part of the
  screen. Scripts can read it as `screen.safeArea`. You can try a notched phone without one with
  `screen.set_safe_area {"profile":"phone-portrait"}`.
- The Android Back button and gesture now reach your game as `input.onBack`: close a menu or go up one screen and the game
  stays open. If nothing handles it the game closes, as before.
- `input.vibrate()` makes a phone vibrate (a light tap on iPhones). Exported Android games include the permission for it.
- Android games can raise the on-screen keyboard for text fields and receive what is typed. Keyboards that compose words
  (predictive text, swipe typing, emoji, Asian languages) still cannot type into an Android game; physical keyboards work.
- An on-screen gamepad for games made for a controller: add a `TouchStick` and a few `TouchButton`s to a scene and players
  move with the thumb and press A, B... on the screen. They press the same gamepad buttons and stick a real controller
  does, so your game needs no other change. Several fingers work at once, the controls stay clear of the notch, and they
  only show while the player is using touch (they hide when a real controller or keyboard is used).
- Tests can press Back, fake a notch, check vibrations and touch the on-screen gamepad without a device.
- iPhone and iPad exports include the privacy file the App Store asks for (`PrivacyInfo.xcprivacy`), listing the few
  system features FactorIA uses and saying that nothing is collected or tracked. If your game or a plugin collects data,
  tracks players or uses more system features, add them under `export.ios.privacy` in `factoria.json`; mistakes in it are
  reported with the fix. The app also says it uses no special encryption, so App Store Connect stops asking at every
  upload (`export.ios.usesNonExemptEncryption` changes it).
- `factoria setup players --platforms mobile` now also downloads the iPhone and iPad libraries on Windows and Linux, so
  you can prepare an iOS project there without pointing at a macOS download. Building it still needs a Mac.
- The mobile guide lists what to answer in Google Play's Data safety form and in App Store Connect's App Privacy section.

Upload your phone builds

- Upload your iOS build to TestFlight and App Store Connect from your AI or the command line (`publish.appstore`,
  on a Mac): you archive the game in Xcode as before, FactorIA sends the `.ipa` with an App Store Connect API key. Run it
  with `dryRun` first to see the exact command.
- Upload your Android release bundle to Google Play (`publish.googleplay`, needs fastlane): pick the track (internal
  testing by default), leave the release as a draft or roll it out, and send the "What's new" text per language from
  files of your project. A bundle signed with the debug key is refused before anything is sent. Google Play still wants the
  first bundle of a new app uploaded by hand.
- Your keys stay in files outside the project and are never shown or logged.

Games in the browser

- Export your game for the web: `factoria export --platform web` (or Web in the editor's Export window) makes a folder
  with an `index.html` that plays the game in any modern browser, and a `.zip` of it ready to upload to itch.io as an
  HTML5 game. The page shows a loading bar and explains in plain words when something is wrong (an old browser, a
  download that failed).
- In the browser, saves made with `storage` are kept between visits, sound starts with the player's first click or key,
  and gamepads work. Native plugins and store services (achievements, purchases) are not available on the web.
- The web player comes with every FactorIA download; `factoria setup players --platforms web` installs it if you need it.

Better looking 3D, and much bigger 3D scenes

- Materials look like real materials: `metallic` and `roughness` now use physically based shading, and shiny surfaces
  reflect the sky of your scene (`skyColor` and `horizonColor`), so a metal sphere looks like metal without any extra
  file. Scenes you already have look close to before, with a faint sheen on plastic and stone.
- Normal maps: give a `MeshRenderer` a `normalMap` picture to add bumps, scratches or bricks without extra triangles, and
  `normalScale` to make them stronger or softer.
- glTF models keep their materials: metallic and roughness (with their textures), normal maps, ambient occlusion and
  glowing parts are read from the file. Models without tangents get them generated.
- Big scenes are cheaper: anything outside the camera's view is skipped, and many copies of the same mesh with the same
  material are drawn together. Ten thousand identical cubes now cost one draw.
- Up to 32 lights at once instead of 8. With more, the engine keeps the sun and the brightest, nearest lights.
- The render statistics (`play.report`) now also count `meshesCulled`, `meshBatches` and `lightsDropped`.
- Your own shaders: a `MeshRenderer` can use a material file (`material`) with a few lines of GLSL that change how the
  surface looks (a pulsing glow, cut-out leaves, moving water) or move its vertices. Shadows follow the moved or cut-out
  shape, each entity can change the material's values (`materialParams`), and a change to the file shows up at once
  while the game runs. A material that does not compile draws magenta and says which line is wrong.
- A new guide for your own shaders (`factoria docs read shaders`): how to write a material, the rules for its few lines
  of GLSL, and five ready examples: a pulsing glow, dissolving, water, wind on grass and a rim light. The shader
  compiler comes with FactorIA, next to `factoria` in every download, so there is nothing to install. If Windows
  Defender removes `sokol-shdc.exe` by mistake, restore it from Windows Security > Protection history, or run
  `factoria setup shaders` to get it again.
- In the editor, saving a material, a shader or a texture updates the game view right away, while editing and while
  playing. A mistake in a shader keeps the last picture that worked and shows one error in the Console with the file
  and the line.
- The Gem Roller example has glowing, pulsing gems made with a custom material.
- Not yet: an environment picture for reflections.

Animation

- 3D models with skeletons: a glTF/GLB with named animation clips plays through the new `Animator` component, which goes on
  the entity with the model's `MeshRenderer`. Switch clips with a smooth cross-fade (`entity.animator.play("Run", 0.2)`),
  change the speed, and get an event when a clip reaches a moment you chose (a footstep at 0.3 s) with `world.on`.
- A small state machine is built in: list the parameters, the states (a clip each) and the transitions in the scene file
  (`"when": "speed > 0.1"`), then your script only sets values: `entity.animator.set("speed", 3)`. Animation runs in the
  fixed step, so tests and replays give the same result every time.
- New `tween` and `ease` in the scripting API: slide a menu in, fade a sprite, grow a pickup. Works on numbers, vectors
  and colors of anything, in 2D and 3D, with 30 easings (`"backOut"`, `"bounceOut"`...), delay, repeat, yoyo, chaining and
  `await tween(...).finished`.
- Animated models are drawn deformed by the animation, shadows included (up to 64 joints per model; a model with more
  is drawn in its bind pose and a warning says so). The new guide is `factoria docs read animation`.

3D physics: new shapes, joints and a character controller

- 3D colliders can now be capsules (`shape: "capsule"` with `radius` and `height`), convex shapes (`"convex"`, the
  smallest solid that wraps a model) and triangle meshes (`"mesh"`, the exact surface of a model, for terrain, ramps and
  level geometry). For the last two, set `Collider3D.mesh` to a primitive name or to your `.glb`/`.gltf` file, usually
  the same as the entity's `MeshRenderer.mesh`. All shapes collide with each other, and raycasts, shape casts, triggers,
  sleeping and the physics debug view work with all of them.
- A mesh collider is for things that never move. Put it on a body that moves and the engine tells you once, in plain
  words, to use a convex collider or several boxes and capsules instead.
- Joints: add a `Joint3D` to an entity that has a body to make a hinge (doors, pendulums, wheels, with optional angle
  limits and a motor), a ball joint (chains, shoulders) or a fixed joint, hanging from the world or from another body.
  A swinging pendulum keeps its real period.
- Character controller: add `CharacterController3D` to an entity and call `physics.moveCharacter(entity, delta)` each
  frame. It slides along walls, steps up stairs and kerbs (`stepOffset`), refuses slopes steeper than `slopeLimit`, stays
  on the ground going down a ramp, pushes crates, and tells you if it is on the ground (`isGrounded`, `groundNormal`).
  You add your own gravity and jump.
- Limits for now: a model with more than 256 vertices used as a convex collider is simplified to 256 points, jointed
  bodies never fall asleep, and the character is not carried by moving platforms.

More for 2D games

- Flipped and rotated tiles: a tile number can carry a flip or turn, so one picture serves four directions. In
  `scene.import_ascii` a legend entry accepts `flipX`, `flipY` and `rotate` (0, 90, 180, 270). Collision follows the
  plain tile number.
- 9-slice sprites: give a `Sprite` a `slice` (left, top, right, bottom in pixels of the picture) and it stretches like a
  button background, corners intact. It works with flips and with pictures packed in an atlas.
- 2D lights: a `Light2D` entity (point or directional) lights the sprites and tilemaps that set `lit`. Add a
  `normalMap` and the sprite shows bumps that react to the light. `SceneSettings.ambientLight` is the unlit brightness.
  Up to 16 lights at once; the nearest to the camera win.
- Parallax: a `Parallax` component makes a far background move slower than the camera (or faster, for foreground), and
  a sprite can repeat endlessly with `repeatX` / `repeatY`.
- Joints: a `Joint2D` on a body ties it to the world or another body as a hinge (revolute), rope (distance), slider
  (prismatic) or glue (weld), with limits, motors and springs. Scripts can read the reaction force and switch a motor.

Accessibility, speed checks and legal texts

- Colour filters for players: `colorFilter` on the `Camera` turns the whole picture greyscale, raises the contrast, or
  corrects the colours for players who cannot tell red from green (`protanopia`, `deuteranopia`) or blue from yellow
  (`tritanopia`). Your options screen sets it from the player's choice.
- See your game as a colour-blind player does: `factoria run --headless --screenshot-at 60 --screenshot-simulate
  deuteranopia` (or `simulate` in `game.screenshot`) saves the screenshot that way without changing the game, so you or
  your AI can check that hazards still stand out.
- Read menus aloud: `ui.speak(text)` says a line with the computer's or phone's own voice, in the game's language, and
  `ui.speechAvailable` tells whether the system can speak. Speak the button that has the focus and players who cannot
  read the screen can use your menus. Tests check what would be said with `game.spoken()`, without sound.
- Start from the player's own settings: `game.accessibility` tells you the text size the player set on their system,
  and whether they asked for less motion, high contrast or use a screen reader. Use it to set your options on the first
  run; what the player then chooses in your game wins.
- Subtitles: add a `Captions` entity to your scene, then `audio.play("voice.wav", { caption: "Watch out!" })` shows the
  line while the sound plays, and `ui.caption(text)` shows one with no sound. They follow the text size and the player's
  language, and an option can turn them off. Tests list them with `game.captions()`.
- `factoria docs read menus` shows each of these as an option of the ready-made menus, and the accessibility part of
  `factoria docs read finishing` lists them all.
- Speed and memory checks: `factoria call perf.baseline` measures how much CPU time and memory your game uses and how
  many things it draws, and saves it in `perf.json`. `factoria call perf.check` then fails when the game got much
  heavier, so you notice before your players do. `factoria docs read performance` explains how to use it in your own
  checks.
- Privacy policy and license: `factoria docs read legal` says what FactorIA sends from your game (nothing by itself),
  gives a privacy policy you can copy for a game that collects nothing, the paragraphs to add when you use analytics,
  ads, accounts or cloud saves, and when you need a license agreement of your own. It is not legal advice.

Guides for finishing and publishing

- `factoria docs read finishing` takes a game that plays to a game a store accepts, step by step with Lantern Keep's
  code: menus, options that stay set, saves that survive updates, languages, accessibility, credits and tests.
- `factoria docs read publishing` has one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App
  Store, itch.io, your own site): what FactorIA does for you and what you still do by hand, with fees and review times.
- Store images and trailers: `assets.draw_capsules` makes every picture a store page asks for (Steam capsules, Epic,
  GOG, Microsoft Store, Google Play, App Store screenshots, the itch.io cover) from one picture of your game and your
  logo or title. `factoria run --headless --input replay.json --record-video trailer.avi` records a trailer from an
  input replay, with sound; ask for `trailer.mp4` when ffmpeg is installed.

A complete example game

- Lantern Keep (`examples/lantern-keep`) is a small but complete 2D platformer, made the way your AI makes a game: six
  levels, menus, three save slots with a level select and cloud saves, achievements, leaderboards and a shop of cosmetics
  on the test store, accessibility options (text size, a slower game, invincibility, no screen shake), four languages
  including Arabic, an on-screen gamepad for phones and export settings ready for the stores. Read it, copy from it, or
  point your AI at it. Its `SHIPPING.md` lists what each store needs and what is still done by hand.

Learn FactorIA

- Two tutorials for people. `factoria docs read first-game-with-ai` makes your first game with the editor and an AI in
  six rounds, starting from the 2D platformer template: what to type, what to look for and how to undo.
  `factoria docs read make-by-hand` builds a small game by hand from the empty template (collect four gems, then a "You
  win!" screen), one whole file at a time, with a check after each step.
- What a game costs to make with AI: `factoria docs read ai-costs` shows what a complete game cost in a real run, what
  makes a run cheap or expensive, how to set a spending limit and where to see what you spent.
- A browsable API reference in the FactorIA repository: `docs/reference/` has an index of every component and command,
  one page per category, and the version that added each one.
- Searching the docs (`factoria docs search`, and your AI over MCP) shows the best section of each guide first, so a
  name like `onTriggerEnter` finds the scripting reference instead of many sections of one tutorial.

Fixed while making Lantern Keep

Lantern Keep showed what a complete game still had to work around. These are now in the engine, so your AI writes less
code of its own:

- Menus fit their texts: `autoSize` on `Button`, `Toggle` and `Slider` grows the widget to its label at a big text
  size or in a longer language. A button label with several lines is centred line by line, `maxWidth` wraps it, and a
  label that still does not fit is cut at the button's edge. `ScrollList.fill` lets a list take the height the rest of a
  column leaves, and a fitted panel bigger than the screen logs a warning naming it.
- Scripts can apply the layout right away: `ui.layout()` sizes and places the widgets at once, so a script that changes
  a text can read the real sizes (`Button.size`, `Panel.size`, `ui.rectOf`) straight after, without waiting for the next
  frame.
- Panels that do not fit: `fallbackLayout` (row, column or grid) is used instead of `layout` when the panel would leave
  the screen, for example a column that becomes a row at a big text size. `uniformSize` makes the `autoSize` buttons,
  toggles and sliders in a panel all as wide as the widest one and as tall as the tallest one.
- Right-to-left languages: a `Text` with `align: "start"` or `"end"` follows the language's direction, and a panel with
  `direction: "auto"` lays out its rows right to left in Arabic or Hebrew. Scripts read `i18n.direction`.
- Panels: a script hook `onEnable()` runs every time an entity is shown and `onDisable()` every time it is hidden, before
  the frame is drawn, so a panel never shows its placeholder texts for a frame. A hidden panel already has its
  `.behaviour`.
- Focus with a gamepad or the keyboard goes to the widget you expect in the direction you press, and a greyed-out
  `autoFocus` button no longer keeps the focus.
- 2D: a moving platform carries the bodies standing on it, also when the player's script sets its speed every frame
  (that speed is now relative to the platform; drop any carry code of your own). `Shape2D.lit` lets the placeholder
  shapes be lit by `Light2D`.
- ASCII levels: `scene.import_ascii` keeps prefabs as references, so editing a prefab changes every level without
  importing the maps again, and level files stay small. Several maps can share one legend file (`legendFrom`).
- Scripts: vectors and colours work like small arrays (`const [x, y] = position`, `position[0]`, `...color`), reading
  `game.screenSize` is about 60 times faster, and a promise rejection you handle a moment later is no longer reported.
  Unpausing the game keeps the speed you set in `time.scale`.
- Saves: a save file is written in one go, so a crash cannot leave half a file. A save file that does not load is kept
  as `storage.corrupt.json` instead of being overwritten, and `storage.corrupt` tells your game.
- Store texts can be translated: achievements and products in `factoria.json` can name a key of your `locales` files
  (`nameKey`, `descriptionKey`, `titleKey`), and the game lists them in the player's language.
- Tests: `factoria test tests/saves.test.js` runs one test file (or several, or a pattern). `game.click("playButton")`
  presses a widget by its id, `ui.rectOf` gives where a widget is on screen, `expect(x).toMatchObject({...})` checks
  some fields of an object, `game.platform.set({ backend: "none" })` tests the game as on a store-less build, and a
  "not a function" error shows the line with a mark under the call.
- Exports: `export.exclude` in `factoria.json` leaves folders out of every export (`"store/**"`). A publish dry run
  works before the store's upload tool is installed and lists what is missing. The exported game takes `--frames 120` to
  run a few frames and exit, as a quick check in CI. `factoria validate` warns about pictures phones cannot compress, and
  new projects keep `build/` out of git.
- The export guide (`factoria docs read exporting`) has one table of what each export needs (downloads, Android tools,
  Xcode) and whether your computer can make it at all, offline or after a download. A new Microsoft Store section says
  what FactorIA covers and what you still do by hand.
- A game icon without an image service: `assets.draw_icon` draws your icon and the Android icon from shapes, colours and
  text, so you need no paid picture provider and no Python.
- Store screenshots at full size: `game.screenshot` takes a `scale` (so does `factoria run --render-scale`), so a
  1280x720 game makes sharp 1920x1080 pictures instead of enlarged ones. The HUD and the visible area stay the same.
- `i18n.import` for a new language keeps the shape of your main language file, and `factoria docs read` prints clean
  text on Windows.
- The reference (`factoria api`, `docs/COMPONENTS.md`, the MCP tool list) now says which version added each component,
  field and command, and marks with "Not released yet" what is only on the main branch, so you can tell what your
  installed FactorIA has.
- Editing an ASCII level no longer means counting characters: `scene.ascii_edit` changes the map file of a level with
  operations (fill a rectangle, replace a glyph, insert or delete columns, put a coin "2 tiles above the ground" of
  column 40), rewrites only the rows and rebuilds the level, and tells you where every object ended up.
- On Windows, deleting a folder that holds files with very long paths (a macOS export nests four folders) now deletes
  all of it: exporting again into the same folder, `fs.delete` and deleting a project from the editor no longer leave
  old files behind.

Smaller improvements

- The editor's Screenshot toast has a "Show in Finder" / "Show in Explorer" button (it names your file manager) that reveals
  the new PNG, and File > Open Screenshots Folder opens the hidden `.factoria/screenshots/` folder (creating it if needed).
  A toast with a button stays longer and does not vanish while the mouse is over it.
- `factoria validate` no longer warns that a hand-written scene or prefab is "not in the canonical layout": such a file is
  valid. The report has a new informational `notes` list (`note:` lines in the text, `notes` in `--json`, the
  `project.validate` result and the editor's Validation report) with ONE entry naming those files and the optional
  `factoria call scene.format`. `scene.format {check, strict}` is still the CI gate.
- On Windows `factoria` now prints LF line endings like on macOS and Linux, so a doc or a JSON answer saved with `>`
  has no carriage returns.
- A Linux game named "game" now exports with the executable `game-bin`, so it no longer clashes with the `game` data
  folder next to it.

## 0.1.6

Menus and on-screen interface

- New interface pieces for your game: buttons, toggles, sliders, text fields, scrolling lists and panels with
  stretchable backgrounds, laid out in rows, columns or grids. Players use them with the mouse, the keyboard or a
  gamepad.
- Scripts can switch to full screen, change the window size, vsync and frame-rate cap, let players remap the controls,
  show the right button names for their gamepad, take typed text, and show or hide the cursor.
- A menus guide your AI follows to build a main menu, options, a pause menu, credits and a loading screen when your game
  needs them. New projects still start empty.
- Pausing really pauses now: physics, particles and animations stop too, while a pause menu keeps working.

Art, sound and music made by AI

- Your AI can generate images, sprite sheets, sound effects, music, voices and 3D models with the providers you set up
  (OpenAI, ElevenLabs, Meshy), keeping one style and colour palette across a game.
- Every generated or imported file remembers where it came from, and exports include `AI_CONTENT_DISCLOSURE.md` with
  the answers Steam asks about AI-generated content.
- Import Aseprite, Photoshop (PSD), OBJ and FBX files (FBX needs Blender or FBX2glTF installed), and cut sprite sheets
  into frames automatically.
- Lighter games: textures are compressed for each platform and packed into atlases, long music streams instead of
  loading whole into memory, and sounds can be evened out to the same loudness.
- `factoria validate` warns about images that are too big, sounds that clip or are too quiet, and games over a store's
  size limit.

Native plugins

- A game can bring its own native code as a plugin (C or C++ on desktop, Java or Kotlin on Android, libraries on iOS)
  without changing the engine. Plugins can live outside the game's folder, for SDKs you are not allowed to share.

## 0.1.5

- Exported Windows games open without a black console window, and the `.exe` carries your game's name and version
  (Properties in File Explorer shows them).
- Every run of a game writes a `log.txt` in the game's save folder, so a player can send it to you when something goes
  wrong.
- Exporting no longer fails on Windows when the output folder is deep enough to make paths longer than 260 characters.
- When a text uses characters its font does not have (Chinese, Japanese or Korean with the default font, for example),
  the log says which characters are missing and which font has them, instead of leaving the text blank without a word.
- When a command fails, your AI assistant always gets an error it can read and act on.

## 0.1.4

- Android: export your game as an APK to test or an AAB for Google Play, signed with your own key, with its icon.
- New Export window in the editor, with a button per platform and the settings each one needs (name, version, icons).
  What an export still lacks (Android SDK, players for another system) is installed in one click, or with
  `factoria setup` from a terminal.
- macOS: FactorIA is signed and notarized by Apple, so it opens without a security warning.
- iPhone, iPad and Apple Silicon Macs: touches and clicks land where they should, and games run on real devices.
- Android: a game you leave and open again starts correctly.
- The editor's title shows the FactorIA version and the open project.
- Exporting again only replaces a folder an earlier export made, never a folder of yours.
- Scripts: a warning when a method looks like a misspelled event name (for example `onUpdat`), which would otherwise
  never be called.
- License: FactorIA is MIT and the templates are MIT-0, so your game's code is yours to license as you like. Exported
  games include the license notices they need (`FACTORIA_NOTICES.txt`).

## 0.1.3

- Windows installer: installs for your user without an administrator prompt, adds FactorIA to the Start menu and
  makes `factoria` work in any terminal.
- Linux: a single-file AppImage, besides the `.tar.gz`. macOS: one download for Apple Silicon and Intel.
- Android and iOS export work straight from the download: you no longer need the engine's source code.
- Gamepads: hundreds more models are recognised on Linux, and on Android an unplugged pad frees its slot.
- 3D physics: balls roll and spin naturally when hit off-centre, resting bodies sleep and wake like in 2D, and fast
  objects no longer pass through walls.

## 0.1.2

- Editor: fixes in the AI chat, and projects can be deleted from the project list.
- Destroying an object also removes its physics body.
- Your AI assistant can export the game by itself.
- Screenshots taken by tests always show a complete, up-to-date frame.

## 0.1.1

- Editor: Ctrl+C and Ctrl+V work.

## 0.1.0

The first release of FactorIA, a 2D and 3D game engine made for an AI to build your game.

- Games are plain text (scenes in JSON, logic in JavaScript), so an AI can read and change every part of them, check
  its work and run tests.
- The editor is built around an AI chat: send pictures as references, keep several chats with their history, see how
  much of your plan you have used, and choose the model for each AI role.
- Templates to start from: a 2D platformer, an empty 2D game and an empty 3D game.
- 2D and 3D physics, gamepads, and play sessions that can be replayed exactly, with a report your AI can read.
- Downloads for Windows, macOS and Linux. The editor offers each new version and updates itself when you say so.
