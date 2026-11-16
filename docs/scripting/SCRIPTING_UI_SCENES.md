Part of [SCRIPTING.md](../SCRIPTING.md): UI widgets and HUD, assets, level generation, background loading, `scene` / `game` / `storage`, the bot, quit and clipboard.

# Scripting: ui scenes

### UI: menus, settings screens and HUD widgets
The widgets are components: `Panel` (a background that can lay out its children), `Button`, `Toggle`, `Slider`,
`TextField` and `ScrollList` (a Panel that scrolls and clips its children). They are drawn and hit-tested in SCREEN
SPACE only (design pixels, origin top-left, +Y down; there is no `space` field). `Transform.position` is the offset from
`anchor` (a fraction of the design size: `[0, 0]` top-left, `[1, 1]` bottom-right) and `pivot` says which point of the
widget sits there (`[0.5, 0.5]` centres it, `[0, 1]` puts its top-left corner on the position). Rotation and scale of UI
entities are ignored. Every field is documented in `docs.components`; the ones that matter:

- Style, on every widget: `size`, `pivot`, `anchor`, `layer` (draw order, default 200: above `Text`'s 100; a widget's
  label is drawn at `layer + 1` and its focus ring at `layer + 2`), `color` (background tint), `texture` + `slice`.
  With a `texture`, the background is drawn 9-slice: `slice` = `[left, top, right, bottom]` borders in texture pixels
  that keep their size (1 texture pixel = 1 design pixel) while the edges and the centre stretch, so one small PNG
  gives a button or panel of any size. `slice: [0, 0, 0, 0]` stretches the whole image.
- Button, Toggle, Slider and TextField also have `font`, `fontSize`, `textColor`, `accentColor` (focus ring, slider fill
  and knob, toggle check, caret), `interactable` (false: drawn at half alpha, never focused or clicked) and
  `autoFocus`. Read-only runtime flags: `focused`, `hovered`, `pressed` (a script may read them to restyle).
  Button has `text`; Toggle `label` + `value`; Slider `label`, `value`, `min`, `max`, `step`, `showValue`, `format` (`"{v:1}x"`, `"{percent}%"`; see
  the field's doc) and `formatKey`; TextField
  `text`, `placeholder`, `maxLength`.
- **Layout.** A `Panel` with `layout: "column" | "row" | "grid"` places its active children (widgets, and screen-space
  `Text`, `Sprite` and `Shape2D`) inside its rectangle minus `padding`: `spacing` between them, `align` (the cross axis:
  `start`, `center`, `end`; default center), `justify` (where the run sits along the main axis), `columns` for a grid, and
  `fit: true` makes the Panel as big as its content plus padding. Layout puts each child in its slot
  every frame without writing its `Transform.position` (since 0.30.0): that stays the child's own offset from the slot, 0 =
  exactly in it, so a script can nudge a laid-out widget by setting `position`, and reads where it is with `worldPosition`
  or `ui.rectOf`. `layout: "none"` (the default)
  leaves them where they are. Give a `Sprite` inside a container an explicit `size` (it is measured as 32 x 32 until
  the texture size is known to the layout); a `Text` is measured with the real font.
- **ScrollList.** Lays its children out as a column and shows the part inside its rectangle: everything drawn by its
  descendants (widgets, `Text`, `Sprite`, `Shape2D`) is clipped to it, and hits outside it do nothing. The mouse wheel
  over it scrolls (`scrollSpeed` pixels per notch) and moving the focus to a child scrolls it into view. `scroll` is
  the offset in pixels (scripts may write it; it is clamped). A list that has more content than it shows keeps the
  wheel: `input.mouse.wheel` reads 0 for that frame and `ui.wheelConsumed` is true (see "Pointer, hit test and the
  wheel" below), so a camera that zooms with the wheel needs no check of its own.

**Focus and navigation.** A widget can have keyboard / gamepad focus when it is a Button, Toggle, Slider or TextField,
active and `interactable`, or an `Interactable` entity that is active and `enabled` (any composition of sprites, shapes and text as a
widget, in world or screen space: docs/MENUS.md, "Widgets from your own entities"; below, "widget" means both). Nothing takes focus by itself except one thing: when no widget is focused, the first
focusable widget (top to bottom, then left to right) with `autoFocus: true` takes it. So a HUD button never reacts to the
gameplay keys; a menu marks its first item `autoFocus` (or calls `ui.focus(...)` when it opens). A focused widget that is
destroyed, deactivated or made not interactable loses focus, and `autoFocus` applies again. When every visible
`autoFocus` widget has `interactable: false` (a greyed-out buy button), the first interactable widget in reading order
takes the focus instead. The actions below move the focus to the nearest focusable widget in that direction: first among
the widgets lined up with the focused one (overlapping it across the direction, like the next tab of a row or the row
under a tab), and only when there is none, anywhere in that half of the screen (holding repeats after 0.4 s, then every
0.1 s; it does not wrap):

| action | default bindings | does |
|---|---|---|
| `ui_up` `ui_down` `ui_left` `ui_right` | arrows, d-pad, left stick | move the focus; on a focused Slider, left / right change the value by `step` |
| `ui_submit` | Enter, Space, `GamepadA` | click the focused Button, flip the focused Toggle (a TextField ignores it) |
| `ui_cancel` | Escape, `GamepadB` | send `ui.cancel` (also with nothing focused) |
| `ui_next` `ui_previous` | Tab, Shift+Tab | focus the next / previous widget in reading order, wrapping around; they need a focused widget to start from |

The engine installs these eight unless `input.actions` in `factoria.json` defines an action of the same name, so to rebind
a key, add the action there: `"ui_submit": ["Enter", "GamepadA"]` (the project's list replaces the default one).
A focused TextField takes typed characters (`maxLength` code points, UTF-8), Backspace deletes (it repeats) and the
Enter key sends `ui.submit`. The mouse (and the first touch) hovers, presses and focuses; a Button or Toggle acts when
the press is released over the same widget; a Slider follows the pointer while pressed.

**The UI works while the game is paused** (`time.scale = 0`): it runs on real time, which is what a pause menu needs.

**Events.** The UI sends game events (`world.on(name, (data, source) => ...)`, `Behaviour.onEvent`), with the widget as
`source` and `data.id` its entity id:

| event | when | `data` |
|---|---|---|
| `ui.click` | a Button or button `Interactable` was clicked (mouse, or `ui_submit` while focused) | `{ id }` |
| `ui.change` | a Toggle flipped, a Slider moved, a TextField was edited (also an `Interactable` toggle or slider) | `{ id, value }` (boolean, number, string) |
| `ui.submit` | Enter in a TextField | `{ id, value }` |
| `ui.focus` | a widget took the focus | `{ id }` |
| `ui.blur` | an `Interactable` lost the focus | `{ id }` |
| `ui.hover` | the pointer came over an `Interactable` (`value` true) or left it (false) | `{ id, value }` |
| `ui.press` | the pointer went down on an `Interactable` | `{ id }` |
| `ui.release` | the pointer went up after pressing an `Interactable` (`value` true when still over it; `ui.click` / `ui.change` follow) | `{ id, value }` |
| `ui.cancel` | `ui_cancel` was pressed | `{ id }` (`null` when nothing is focused) |

- `ui.on(type, fn)` / `ui.on(type, target, fn)` → unsubscribe function. `type` is `"click"`, `"change"`, `"submit"`, `"focus"`,
  `"cancel"`, or (`Interactable` only) `"blur"`, `"hover"`, `"press"` or `"release"`; `target` (an Entity or an entity id) limits it to one widget; `fn` gets `{ type, id, entity, value }`.
  A wrong `type` throws with a "did you mean". Inside a behaviour prefer `this.on("ui.click", (data, source) => ...)`:
  it is removed with the behaviour. Scripts do not need to poll the widgets:
  ```js
  ui.on("click", "play_button", () => scene.load("scenes/level1.scene.json"));
  ui.on("change", "music_volume", (e) => audio.setVolume("music", e.value));
  ```
- `ui.layout()` runs the UI layout now, as every frame does: change a label, call it, then read `Button.size`,
  `Panel.size` or `ui.rectOf(...)`. `Panel.usingFallback` tells whether a panel is laid out with its `fallbackLayout`.
- `ui.focus(target | null)` gives the focus to a widget (null clears it) and sends `ui.focus`; it returns `true` when the
  widget took the focus and `false`, changing nothing, when the widget has `interactable: false` (a greyed-out button: fall back to
  another one); it throws, saying why, when the entity is not a focusable widget or is inactive (a disabled `Interactable`, `enabled: false`, also gives `false`). `ui.focus(null)` holds: an open
  panel's `autoFocus` does not take the focus back until the next `ui_up` / `ui_down` / `ui_left` / `ui_right` press
  (that press only wakes `autoFocus`; it does not also move the new focus). `ui.focused` and `ui.hovered`
  are the focused widget and the one under the pointer (Entity or `null`): check `ui.hovered` so a click meant for a
  button does not also fire the gun.
- **Pointer, hit test and the wheel.** `ui.widgetAt(x, y)` is the topmost visible widget at a screen point (design
  pixels, y down) or `null`: a Button, Toggle, Slider, TextField, ScrollList, Panel (one that draws something: alpha 0
  with no texture is skipped), a shown TouchStick / TouchButton, or an `Interactable` (a world-space one is looked up through the
  camera that draws at that point; a screen-space widget wins over it). Topmost is the highest `layer`, then the entity made
  last. What a ScrollList clips away at that point, an inactive widget and empty space give `null`; a widget with
  `interactable: false` is returned (check the component). `ui.pointerOverUi` says the same for the pointer at this
  frame's UI update (an `Interactable` under the pointer counts): a game's own click or zoom skips when it is true. `ui.setPointer(x, y, { down })` replaces the
  mouse for the UI from the next frame on (hover, press, Slider drag, click on release, the wheel's target) until
  `ui.setPointer(null)`; use it for a gamepad cursor and in tests. `ui.wheelConsumed` is true on a frame whose wheel
  scrolled a ScrollList (`input.mouse.wheel` reads 0 then). A modal Panel consumes the wheel too, unless it has
  `wheelPassThrough: true`: then a script under it (a zoom in an inventory view) still reads `input.mouse.wheel`.
- **Tooltips.** `tooltip` on any widget or Panel is a string (a localization key or plain text) or
  `{ "title", "lines": [text | {text, color}], "args" }`; `ui.setTooltip(entity, fn)` registers a function that returns
  that content when the tooltip is about to show (null: none). It shows after `ui.tooltipDelay` seconds (get / set, 0 to
  60, default the `"ui": { "tooltipDelay" }` of `factoria.json` or 0.5) of rest within 5 pixels, beside the pointer and
  flipped to stay on screen, and hides when the pointer moves off, a button is pressed or another widget is reached. A widget
  without one uses the nearest ancestor's. `ui.setWorldTooltip((x, y) => content)` answers for a pointer over no widget
  (a map), `ui.showTooltip(content, { x, y })` shows one now until `ui.hideTooltip()`, a pointer move of more than 5
  pixels or a scene load, and `ui.tooltip` reads the one on screen (`null` or `{ title, lines, rect, source, widget }`;
  the same as `tooltip` in `ui.state`). The rest is counted in UI time, so `game.step` tests are exact. Look, touch and
  recipes: [MENUS.md](../MENUS.md), "Tooltips".
- **Drag and drop.** `draggable` on a widget (`true` or `{ "payload", "slop" }`) lets the player drag it. `ui.on("dragStart" |
  "dragOver" | "drop" | "dragCancel", fn)` gets `{ id, entity, source, payload, x, y, target, accepts, reason }` (`target` is
  `null` over the world); `ui.setDropTarget(widget, true | false | fn | null)` and `ui.setWorldDropTarget(...)` say what
  accepts a drop, `ui.setDragImage(widget)` makes a widget follow the pointer, `ui.cancelDrag()` ends the drag and
  `ui.dragging` is `null` or `{ source, payload, from, x, y, target, accepts }`. The click the release would make never
  happens. In tests `game.drag(from, to)`. Details: [MENUS.md](../MENUS.md), "Drag and drop".
- **A camera inside the UI.** `ui.on("viewPointer", fn)` (or `ui.on("viewPointer", view, fn)`) gets `{ id, entity, phase, x, y,
  u, v, dx, dy, wheel }` for a `CameraView`: `phase` is `"down"`, `"drag"` (while the button or finger is held and moves), `"up"`
  or `"wheel"`; `x, y` is the pointer in design pixels, `u, v` its place in the view (0..1, outside while a drag leaves it),
  `dx, dy` the move since the last event and `wheel` the notches. A script that awaits something (a spawn, a load) and then
  moves what the view shows checks that its scene is still the current one first. Details: [MENUS.md](../MENUS.md), "A camera inside the UI".
- **`active` and `activeInHierarchy`.** `entity.active = false` hides the entity and everything under it, but it does not
  change the `active` of the children: a child of a hidden Panel keeps `active` true. `activeInHierarchy` is true only when
  the entity and every ancestor are active, so ask that to know whether a menu is open (`panel.activeInHierarchy`), not
  `child.active`. `ui.rectOf` returns `null` and `ui.state` leaves out an entity whose `activeInHierarchy` is false.
- The command `ui.state` returns what is on screen: every widget with its `id`, `kind`, `rect` `[x, y, w, h]`,
  `focused`, `hovered`, `pressed`, `interactable`, `visible` and `value` / `text`, in reading order. Use it to find what
  to click (`game.input` with `mouse.position`) or which widget has the focus.
- Tests: drive a menu with pad taps and assert on events and values, no mouse needed:
  ```js
  game.loadJson(menuScene); game.step(1);
  const pad = game.gamepad();
  pad.tap("DpadDown"); pad.tap("DpadRight");   // focus the slider below, +1 step
  pad.tap("A");                                // ui_submit on the focused widget
  ```

### assets
- `assets.textureSize(path)` → `{ width, height }` (same shape as `ui.measureText`): the pixel size of the texture file at
  the project-relative `path`, for example `assets.textureSize("assets/hero.png")`. It is the size a `Sprite` without
  `size` or `region` is drawn at and the one `entity.bounds()` uses. A missing or unreadable file gives 32 × 32 (the size
  of the missing-texture checker). It reads the file, so it works headless; the result is cached per file and
  modification time, so calling it every frame is cheap. An empty or non-string `path` throws.
- `assets.preload(paths)` → a load handle ("Background loading" below): reads the files ahead of time, for assets a script uses later.

### Generating a level: `tilemap.generate(options)`
`tilemap.generate` makes a level from a small example at run time with Wave Function Collapse (the command of the same
name, docs/AI_GUIDE.md section 9.8, run in pieces). It checks the options at once (a mistake throws with its JSON pointer
and a hint), returns a handle and works a little every frame, so the game keeps drawing. The seed comes from
`rng.create`, never from the clock; the same options give the same level as the command, whatever the frame rate.

```js
const gen = scene.generation;
const job = tilemap.generate({ sample: "levels/sample.json", size: [48, 20],
    seed: rng.create(runSeed).int(0, 2147483647), constraints: { border: { tile: "#" } },
    place: { entity: "level", tilemap: { tileset: "assets/art/tiles.png", tileSize: [16, 16] } } });
job.promise.then((r) => { if (scene.generation === gen) console.log("ready", r.placed); },
                 (e) => console.error(e.message, e.hint));
```
- The handle has `progress` (0..1, never goes down: it follows the solver cell by cell inside an attempt, and a restart after a dead end keeps the bar where it was; 1 only when done), `done`, `error`, `hint`, `result` (`null` until ready), `attempts`,
  `work`, `promise` (resolves with `result`, rejects with an Error that has `.hint`) and `cancel()`.
- `place` builds the Tilemap and the sample's markers (glyphs with a `prefab`) as entities, like `scene.import_ascii`, through its in-memory twin `scene.place_ascii` (a game script may not write files);
  `into` writes only tiles into an existing Tilemap. They exclude each other. `place` is checked when you call
  `tilemap.generate` (allowed keys `entity`, `tilemap`, `position`, `anchor`, `replace`, each with its type), not after the
  generation: a mistake in it throws at once instead of costing a finished level.
- Per frame: **tests, headless runs and replays do 500000 units of generator work in all**, so the frames it takes are the same
  on every machine; **a game with a window** works until about 4 ms of the frame are used (the same budget as
  `scene.preload`). The budget is **shared by all running generations**, not given to each: with several running (up to 8) each
  gets an equal part, so starting more of them makes every one slower and never makes a frame longer. The game
  must not depend on how many frames it takes. `stats.ms` and `memoryBytes` of the result are informative and not
  deterministic (they depend on the machine): a game must not compare them. The model is built (and the options checked)
  by the `tilemap.generate` call itself, so a very big sample or many tiles makes that one frame long; after that a step
  stays near its budget, because an attempt (the reset, the solve, the output, the counts and the reachability check)
  advances in chunks of about 16384 work units. Three pieces run to their end inside one step: the rebuild of the
  solver's entropy heap (a pass over at most 4 entries per cell), the re-tiling of a Tiled (terrain) level by the
  `reachability` check, and each path search of that check (at most 16 per attempt, one per step).
- A generation belongs to the scene that started it: a scene load (a reload too) ends it with an error, places nothing
  and frees its memory. A script that awaits `promise` checks `scene.generation` before it uses the result.

### Background loading: `scene.load(path, props, { async: true })`, `scene.preload(path)`, `assets.preload(paths)`
`scene.load` reads the scene and everything it uses before the frame goes on, so a big level freezes the game for a
moment. Three calls do that work in the background while frames keep running: an IO thread reads the files, worker threads
decode them (images, models, fonts, sounds) and each frame uploads a share to the GPU (docs/PERFORMANCE.md, "Background
loading", has the threads, the budgets and the cost).

- `scene.load(path, props, { async: true })` loads the scene in the background and switches to it at the end of the frame
  its files are ready; the new scene starts as after a sync load (same world, same `game.sceneProps()`). A newer
  `scene.load` or `scene.reload()` cancels it: the last request wins, and it never switches. Its handle's `cancel()` stops
  the switch too, also in the frame its files became ready (the switch happens at the end of that frame). The loading screen
  of the menu kit (docs/MENUS.md) is built on it.
- `scene.preload(path)` reads the scene file and what it points at (prefabs, materials, scripts and their imports,
  textures, models with their `.bin` and images, audio, fonts, and the files named in them) ahead: `scene.load` of that
  scene, and the renderer and audio on first use, then read nothing from the disk.
- `assets.preload(["assets/boss.glb", "assets/boss.ogg"])` does the same for a list of files.

```js
const job = scene.load("scenes/level2.scene.json", { level: 2 }, { async: true });   // in onStart of the loading scene
// every frame: bar.get("Shape2D").size = [400 * job.progress, 16];
job.promise.catch(() => { if (!this.gone && !job.cancelled) scene.load("scenes/level2.scene.json"); });  // reports the error
```
- Each returns a handle at once: `progress` (0..1, never goes down), `done`, `files` (items done) and `total`, `bytes`
  read and `uploadedBytes` (to the GPU) so far, `error` (`""` or why it failed), `cancelled`, `promise` (resolves with
  `{ files, bytes, uploadedBytes }`, rejects with an Error that has `.hint`), `cancel()` and `release()`. Its values change
  between frames only. A script that only polls `done` is not reported for an unhandled rejection.
- Work is counted in items: the first reads the scene (or the listed files) and finds everything it names, then one item
  per texture, model, font, sound or other file, so `progress` is exact from the second frame on. Per frame: **tests,
  headless runs, the editor and replays take exactly four items**, so what a test sees (how many frames it takes, which
  `progress` values) is the same on every machine and with any `runtime.jobThreads`; **a game with a window** takes the
  items that are ready within `runtime.loadBudgetMs` (default 4 ms) and `runtime.uploadBudgetMB` (default 16 MB of GPU
  uploads) and never waits for a file, so the number of frames depends on the machine and the game must not depend on it.
- A path that does not exist throws at once with a "did you mean" list, and so does an unknown option
  (`{ asinc: true }`). A read error (or a scene that is not JSON) sets `error` and rejects the Promise; an async scene load
  then does not switch, so call the sync `scene.load` in that case, which reports it.
- `cancel()` stops the job: what it decoded is thrown away, the files it read ahead are dropped, and the Promise rejects
  with "cancelled". `release()` does the same for a running job and drops a finished job's files now.
- The Promise outlives the scene that asked: a loading scene that is left before its load is ready (a test that moves on)
  sets a flag in `onDestroy` that its callback checks, and calls `cancel()` there unless `done`. docs/MENUS.md has the
  recipe. A newer scene load cancels an async one by itself; a preload goes on across scene loads.
- Memory: the files no cache took stay for the first scene load after the job finished and are dropped at the second (or
  by `release()`), so a preload costs about one scene's files beyond the one in use. A file changed on disk since it was
  read is read again.
- Tests: `game.fileReads()` counts the files read from the disk; compare two values to prove a load read nothing.
  Commands do the same from tools: `scene.load {"path", "async": true}`, `scene.preload`, `assets.preload`, `load.status`,
  `load.cancel`.

### scene / game / storage
- Promises: a rejection nobody handles is logged once as `unhandled promise rejection: ...`, but only if it is still
  unhandled once the pending promise jobs have run (as in Node). `p.then(() => platform.achievements.unlock(id)).catch(() => {})`
  logs nothing when the store rejects.
- `scene.load(path, props?, options?)` (deferred to frame end; `{ async: true }` loads in the background, see "Background loading") · `scene.reload()` · `scene.current` · `scene.generation` (a counter that changes on every load, a reload of the same scene too) · `game.sceneProps()` (see "Scene props")
- `game.today()` (see "The date") · `game.focused` · `game.on("gamepadConnected" | "gamepadDisconnected", fn)` (see "Pads plugged in and out") · `game.on("suspend" | "resume" | "focus" | "blur", fn)` (app lifecycle,
  see MOBILE.md "Lifecycle"; `pauseOnSuspend` in `factoria.json`, default `true`, pauses the game and the music while the
  app is in the background) · `game.on("quit", fn)`: see "Window close" below
- `clipboard.read()` (a Promise of the text) · `clipboard.write(text)`: see "Clipboard" below
- `game.quit()` · `game.paused` (see `time`) · `game.project` (read-only factoria.json) · `game.screenSize` ·
  `game.platform` (`"windows"`, `"macos"`, `"linux"`, `"ios"`, `"android"` or `"web"`: e.g. no Quit button on phones)
- `game.accessibility` (read-only, frozen) → `{ textScale, reduceMotion, highContrast, screenReader }`: the player's
  operating system settings, for your options screen to start from (recipe: MENUS.md). `textScale` 1 = 100 %, clamped to
  0.5 - 4; the others are booleans. Read when the game starts and again when the window regains focus or the app
  resumes. The engine applies none of them except one: the game feel effects (shake, squash, hit-stop, flash; GAME_FEEL.md) follow `reduceMotion` unless the game sets `feel.reduceMotion` / `feel.reducedEffects` itself. You apply the rest and save the player's own choice. Where each platform reads
  them, and what it cannot: Windows (animations off, high contrast, screen reader, Text size setting), macOS (reduce
  motion, increase contrast, VoiceOver; text size always 1), iOS (reduce motion, darker colours, VoiceOver, Dynamic Type),
  Android (font scale, animator scale 0, high contrast text, TalkBack/touch exploration), Linux (GNOME settings through the
  `gsettings` program; KDE, Xfce and other desktops give `1` / `false`), web (`prefers-reduced-motion`,
  `prefers-contrast: more` or `forced-colors: active`; browsers do not tell the text size or a screen reader, so `1` and
  `false`). Headless runs, `factoria test` and the editor always give `{ textScale: 1, reduceMotion: false, highContrast:
  false, screenReader: false }`; tests change it with `game.setAccessibility({ textScale: 1.5, reduceMotion: true })`
  (reset before every test).
- `game.notices()` → `[{ name, url, license, usedFor }]`: the third-party software inside the runtime every game ships
  (FactorIA first), the parts whose license texts `factoria export` writes to `FACTORIA_NOTICES.txt`. For a credits
  screen.
- `storage.get(key, fallback)` · `storage.set(key, value, options?)` · `storage.remove(key)` · `storage.size(key)` ·
  `storage.setAsync(key, value, options?)` — persistent JSON save data. **One file per key** in
  `<user dir>/storage/` (`slot1.json`; a name keeps lowercase letters, digits, `_` and `-` and writes every other byte as
  `%XX`, so `"Slot 2"` is `%53lot%202.json` on any disk), each holding `{"key": ..., "value": ...}`: a save rewrites its
  own key only, however many other keys (or big saves) there are. A `storage.json` left by an older version is read at
  the first start, split into key files (keys that already have a file keep it) and renamed `storage.migrated.json`, so
  nothing is lost if that start is interrupted. Tests always use an empty in-memory storage per test file (it lasts the
  whole file, `game.resetState` empties it between tests) and never read or write the real save, so a save left by the
  editor or a play run cannot change a test result and a test cannot leave one behind; `factoria mcp` and `factoria
  call` keep the game's storage in memory too (`--persist-storage` opts in), while the editor and `factoria run` write
  the key files. The commands `storage.list` (MCP `storage_list`) and `storage.clear {key | all}` (`storage_clear`)
  show and delete the keys, in memory and in the save folder (`.factoria/save/storage/`), whatever the mode, so a
  stale save (a main menu that shows "Continue") is removed without a shell `rm`; the runtime can run headless with `ScriptSystem::set_storage_mode(StorageMode::Memory)`.
  Every file is written atomically (a temporary file, then a rename): a crash during a save leaves the previous file
  intact, and a leftover temporary file is ignored.
- `storage.set(key, value, {compress: true})` stores the value zlib-compressed (the file is `{"key", "z": "zlib", "n",
  "data": <base64>}`): a big, repetitive save takes a fraction of the disk space and `get` returns the same value. Any
  other option throws with a suggestion (`compress` and `encrypt` are the two options). `storage.size(key)` is the number of bytes the key's file takes (the compressed
  size for a compressed value; `0` when the key is not stored): measure a save, or choose to compress above a size.
- `storage.setAsync(key, value, options?)` returns a Promise that resolves with the file's size once the file is written
  (and rejects with the reason when it cannot be). `storage.get` returns the new value at once; the encoding, the
  compression and the write happen off the frame: on a worker thread on desktop and phones, and between frames on the web
  (a browser player has no threads). Serializing `value` to JSON still happens in the call. Writes to one key land in the
  order they were asked; `set`, `remove`, `clear` and `size` wait for the writes still running, and the game does not
  end before they finish. The writes still waiting are also made right after the `suspend` and `quit` handlers run, so a
  `setAsync` from one of them is on disk (on the web, in the copy sent to IndexedDB) before the app is hidden or closed. In a test the write is deferred to the next `game.step`, so
  `const p = storage.setAsync("slot", data); game.step(1); await p;`. A Promise outlives nothing it needs: storage is not
  tied to a scene.
- A write that fails (the disk is full, or, on Windows, another program holds the key's file open, which stops it from being
  replaced: the engine tries again for about a second first) leaves the file as it was, sealed or not: `storage.set`
  throws an Error saying the value was kept in memory but not written, `storage.setAsync` rejects and the log has a
  warning. The value stays readable in this run; save again later, or the next run loads the older file.
- `storage.corrupt` — `true` when a storage file (a key's file, or an older `storage.json`) did not parse at the first use
  of `storage` in this run. The damaged file is **kept** as `storage.corrupt.json` in the save folder
  (`storage.corrupt.2.json`, `.3`... when one is already there: an earlier one is never replaced), the engine logs a
  warning naming it, and the game starts without that file's data (the other keys load); the next save writes a new valid
  file and never touches the kept one. Check it at start to tell the player or offer a recovery. A test starts from a
  damaged save with `game.setStorageText('{"broken')` (from `factoria:test`; it sets the text the next storage load reads
  as if it were an old `storage.json` and reloads, then `storage.corrupt` is `true`).
  On the web the save folder lives in IndexedDB and the same rules apply to its copy of the files. A web page that is
  hidden or closing copies it to IndexedDB right after the `suspend` and `quit` handlers have run (see below), so a
  `storage.set` made inside one is kept.
- **Encrypted saves** (`storage.set(key, value, {encrypt: true})`, `setAsync` the same, together with `compress` if you
  like). The file is sealed with ChaCha20-Poly1305 (`{"key", "enc": "chacha20poly1305", "data": <base64>}`, plus `"z"` and
  `"n"` when compressed: the value is compressed first, then sealed): a text editor shows nothing readable and a changed
  byte, a truncated file or a file copied under another key makes the save fail authentication instead of loading edited
  gold. `storage.get` opens a sealed value like any other, and a game can turn encryption on later: the plain files its
  players already have are still read, and sealed the next time they are written (each `set` decides for its own key; a
  `set` without `encrypt` writes the key in plain again). `storage.list` marks the sealed keys (`encrypted: true`).
  A sealed file that fails authentication behaves like a damaged one: it is **kept** as `storage.corrupt.json` (`.2`,
  `.3`...), the log names it and says the save was modified, damaged, or written with another secret or game id,
  `storage.corrupt` is `true` and the game starts without that key (the others load; `storage.list` shows the
  problem under `damaged` for a file that is still in the folder). Never treat a missing sealed save as a new game
  without checking `storage.corrupt`.
  - **The key.** The project's secret is a random value in `factoria.json`, `"storage": {"encryptionSecret": "<64 hex
    characters>"}`. Create it ONCE with `factoria call project.create_storage_secret` (also from the editor console and
    MCP; `{"replace": true}` makes a new one and makes every sealed save so far unreadable; the command never prints it)
    and commit `factoria.json`. A project without it throws on `{encrypt: true}` with an Error that names the command, and
    changes nothing; the running game never creates a secret. The key of each value is HKDF-SHA256 over the secret, salted
    with the game id (`"id"`), with `factoria.storage.v1:` and the storage key as context, so a value moved to another
    key, another game or another secret does not open, and every file gets a fresh random salt and nonce. The secret is
    packed with the exported game like the rest of `factoria.json` (the exported pack is not readable text, but it is not
    a vault either), so it is the same in every build and install of the game: sealed saves survive an update or a
    reinstall and can be copied between a player's devices (the cloud copy of the Slots kit is plain text). It is never
    logged, and these channels show it as `"(hidden)"`: `project.info`, `game.project`, `fs.read` and `fs.search` of
    `factoria.json` (any file of that name, also one of a project inside the project, and the copies a checkpoint keeps under
    `.factoria/checkpoints/objects`), `checkpoint.read` of `factoria.json` (its `out` is refused for that file, so a copy over
    256 KB cannot be read: `checkpoint.restore` brings the real file back), the MCP
    `factoria://project/factoria.json` resource and the AI assistant's prompt. `fs.write` / `fs.edit` that leave `"(hidden)"` as
    the value keep the real secret, and `fs.edit` matches its `find` against the masked text, so it cannot be used to guess the secret.
    This is masking per channel, not a guarantee: the secret is a plain value in `factoria.json`,
    so it is in the project's repository, in every checkpoint, in an exported game's pack, and in what any tool that reads the
    file without these commands (a shell, a git client, an editor) sees. Do not put the project folder where a person you
    would not trust with the saves' key can read it, and replace the secret (`project.create_storage_secret {"replace": true}`)
    if it leaks. Keep the secret and the game id for the life of the game: changing either one orphans every sealed save.
  - **What it protects, and what it does not.** It depends on what the game asks for, and none of it is secrecy or anti-cheat:
    the key necessarily ships inside the game, so anyone who takes the secret out of the pack (or out of the running process)
    can read and forge saves; the file size is visible; and an older sealed file can be put back (a rollback: keep a counter or
    a timestamp in the data and check it if that matters). Do not keep passwords or purchase state in it.
    - `storage.set(key, value, {encrypt: true})` alone: a player cannot READ the save with a text or hex editor, and a sealed
      file that was edited (one changed byte, a changed flag, a file moved to another key) is refused. But `storage.get(key)`
      still reads a PLAIN file for that key, because a game that turns encryption on later must keep its players' old saves:
      a player who deletes the sealed file and writes `{"key": "slot1", "value": {...}}` by hand (the format is on this page)
      loads whatever they typed. So with `encrypt` alone a determined player CAN set their own gold.
    - `storage.get(key, fallback, {encrypted: true})` as well: a value read from a plain file is treated like one that failed
      authentication (the file is kept aside, `storage.corrupt` is `true`, the log names the key) and `fallback` comes back. Keeping
      it aside reads the file and moves it (a copy when it cannot be moved) on the calling thread, in the frame, once per such key. Now
      a player cannot write the value of that key at all without the secret. Use it for a key the game has always sealed, or
      once every player's save is sealed (`storage.isEncrypted(key)` tells; a game that already shipped plain saves would
      refuse every one of them: read the plain value, write it again with `{encrypt: true}`, and only then ask for
      `{encrypted: true}`). A value the game itself stored in plain in this run is just not returned.
    - The Slots kit: `encrypt: true` is the first case (`write` seals, `peek` still reads a plain slot); adding
      `requireEncrypted: true` is the second (a slot that is not sealed is `damaged`). Set it for a new game, or after a
      release in which every slot is sealed.

### The bot (`game.autoplay`)

`play.auto` ([DEBUGGING.md](../DEBUGGING.md#let-the-game-play-itself)) plays the game with nobody at the keyboard, headless and fast,
and reports what it found. The game says how it is played in `scripts/autoplay.js`, a file only `play.auto` imports (a shipped game
does not contain it: `factoria export` leaves it out, so nothing of it runs in a game people play):

```js
// scripts/autoplay.js
import { game, world } from "factoria";

game.autoplay((bot) => {
  const player = world.find("player");
  if (!player) return { end: "lost", note: "The player is gone." };
  const area = world.find("map").bounds();
  if (player.position.x > area.x + area.w - 96) return { end: "won", score: 12 };
  const jump = player.isGrounded() && bot.rng.chance(0.03);
  return jump ? ["move_right", "jump"] : ["move_right"];
});
```

`game.autoplay(fn)` calls `fn(bot)` once per step (at `speed` N, once per N steps) and `fn` answers what to press:

- **An array of action names** to HOLD during this step. An action you leave out is released, so `["move_right"]` runs right until
  an answer without it. Only the actions of `factoria.json` `"input"` and the menu actions (`ui_up`, `ui_down`, `ui_left`, `ui_right`,
  `ui_next`, `ui_previous`, `ui_submit`, `ui_cancel`) are accepted, because the bot's input is recorded as a replay
  (`factoria run --headless --input` plays it again). Another name throws with a "did you mean".
- **An object** `{ actions?, end?, score?, note? }`: `end: "won"` or `"lost"` finishes the run with that result (the session says
  `ended: "won"`), `score` is the number the session reports, `note` is a line of the session's notes.
- Nothing (`undefined`) presses nothing.

`bot` is read only: `time` and `step` (game time and fixed steps since the run began), `dt` (the game seconds this decision lasts), `scene`,
`sceneTime`, `phase`, `actions` (the declared actions), `uiActions`, `held` (what the previous step held), `seed` and `rng`.
Take every random choice from `bot.rng` (a generator seeded with the run's `seed`), never `Math.random`: the same `seed` then plays the same game.
`fn` may keep state in the module (the last position, a counter). It reads the world and answers with actions; it must not change the game
(no teleporting, no spawning), or the replay would not reproduce the run. `fn` must answer at once, not return a promise. A hook that throws
presses nothing in that step and the error goes to the session's `scriptErrors`; a hook that fails every step is reported as an exception loop.

`game.phase(name, { ends? })` marks a stage of the run for the report ("boss", "shop", "level 2"): the session lists it with its game time and a
screenshot. `{ ends: "won" }` or `{ ends: "lost" }` also ends the run, so a game without a hook can tell the explorer it is over
(`game.phase("victory", { ends: "won" })`). Outside `play.auto` both calls do nothing. Every scene a run loads is a phase by itself.

A game without `scripts/autoplay.js` is played by a generic explorer: it holds one or two of the declared actions for 0.5 to 1.5 game seconds, then
changes, and taps `ui_submit`, `ui_down` or `ui_next` when the scene has buttons, all drawn from the run's `seed`. That finds crashes,
stuck screens and slow frames, but not a level that needs a plan: write the hook for that. The templates ship one that finishes their sample level.

### Window close: `game.on("quit", fn)`

On a desktop window, the close button, Cmd+Q (macOS) and Alt+F4 (Windows) raise `quit` before the window closes. The
handler gets an event with `cancel()` and `cancelled`; call `event.cancel()` to keep the game running (ask "Quit
without saving?" and call `game.quit()` when the player agrees). Without a handler, or when no handler cancels, the
window closes. `game.quit()` closes the window without raising `quit` again, so a handler may call it. iOS never
raises it (the OS closes the app on its own terms), and a headless run only sees it when a test calls `game.closeWindow()`.
Cancelling is not guaranteed on every platform: a window the OS is shutting down can close anyway.

On the web, `quit` is raised when the page is going away (`pagehide`: the tab closing, a reload, leaving the site) and it
**cannot be cancelled** there: `event.cancel()` does nothing. Use the handler to save; whatever `storage.set` wrote
inside it is copied to the browser's IndexedDB at once, after the handlers have run. The browser may still drop the
page before the copy finishes (a crash, a killed tab), so a game that cannot lose progress also saves on a timer.

On Android, `quit` is raised once when the system destroys the game's activity: a Back no `input.onBack` handler
consumed, the system closing the app, or a relaunch for a theme or wallpaper-colour change (the game then starts again
from its first scene, in a new process). It **cannot be cancelled** either, and it is not raised after `game.quit()`.
The process ends right after the handlers and the `storage.setAsync` writes still waiting, within about 1.5 s (the
analytics request for the events that wait is started, not waited for): keep the handler short, and save with `storage.set` or `storage.setAsync`. A force-stop or
a kill for memory in the background raises nothing (docs/mobile/MOBILE_ANDROID.md, "Lifecycle").

**Which signals each platform raises:**

| | `blur` / `focus` | `suspend` / `resume` | `quit` |
|---|---|---|---|
| Windows, macOS, Linux | the window loses or gains focus, or is minimised and restored | never | the close button, Cmd+Q, Alt+F4; can be cancelled |
| Web | the page loses or gains focus (`window` blur and focus) | the tab is hidden or shown again (`visibilitychange`: a tab switch, a minimised window, a phone's app switcher) | the page is closing (`pagehide`); cannot be cancelled |
| Android | a system dialog over the app | the app goes to the background and comes back | the activity is destroyed (Back not consumed, the system closing or relaunching the app); cannot be cancelled |
| iOS | a system dialog over the app | the app goes to the background and comes back | never |

The web's `suspend` is also raised when the browser takes the WebGL context away. A hidden tab raises `suspend` once
however many events the browser sends, and `resume` only after a `suspend`.

```js
import { game } from "factoria";
game.on("quit", (event) => {
  if (hasUnsavedProgress()) { event.cancel(); openQuitDialog(); }
});
```

### Clipboard: `clipboard.read()` and `clipboard.write(text)`

- `clipboard.write(text)` puts a string on the system clipboard (it throws on a non-string).
- `clipboard.read()` returns a Promise of the clipboard text (`""` when it holds none). Check that its scene is still the
  current one before acting on the answer.
- `window.supports("clipboard")` is true on Windows, macOS, Linux and the web. On phones and tablets `read()` rejects with
  an Error whose `code` is `"unsupported"` and `write` does nothing. Headless runs and tests use an in-memory clipboard
  (empty at the start of every test), so `write` then `read` gives the text back.
- On the web a browser only lets a page read the clipboard while the player pastes (Ctrl/Cmd+V), and `read()`
  resolves with the text of the last paste. Prefer a `TextField` for pasting there.
- A focused `TextField` pastes with Ctrl+V (Cmd+V on macOS) and copies with Ctrl/Cmd+C by itself (docs/MENUS.md).
- Replays: a `"clipboard": "text"` entry in a `--input` file puts that text on the clipboard before its frame; editor play
  sessions record the first thing a frame read, so a replay of a paste is exact.
