Part of [MENUS.md](../MENUS.md): Save slots, text speed, anchors, gamepad cursor, choice cards, widgets from entities, tooltips, drag and drop, charts, a camera in the UI, a studio intro.

# Menus: recipes

## Save slots

The `slots` part is the save / load screen of a game with several saves: five named slots and an autosave, each a record
`{ version, counter, name, chapter, playTime, pic, data }` in `storage` (key `slot1`..`slot5`, `slot_auto`), where `data` is whatever the game
saves. `counter` goes up by one on every save, so with cloud saves (`platform.has("cloudSave")`) the copy with the higher counter wins
when the screen opens (`slots.syncCloud()`); a delete removes the cloud copy too. A text in a slot that has no `data` is read as a bare
save (a game can start with plain saves), and one that cannot be read, is from a newer version of the game or is refused by `upgrade` is
`damaged`: the row says so, with the reason, and the player can delete it. The game supplies two things: what is saved (`snapshot`, or `save` to write the slot
yourself) and how a slot is loaded (`launch`). Everything else is the kit's: the screen builds `prefabs/ui/slots.prefab.json` and
`slot_dialog.prefab.json`, a click on a slot in save mode opens the dialog with a TextField for the name (the on-screen keyboard opens
by itself for a gamepad player), an empty name saves under `defaultName()`, and a delete asks first. `cannotSave()` returns a string-table
key (`"slots.busy"`) while the game may not be saved (a cut-scene, a loading screen); the save rows are greyed out and the key is shown
under the title. A cloud answer that arrives after the scene changed draws nothing (the screen compares `scene.generation`).

```js
const slots = new Slots({ version: 2, encrypt: true, requireEncrypted: true, upgrade: migrate, describe: (d) => ({ chapter: d.level, playTime: d.seconds }) });
const screen = new SlotScreen(menus, {
  slots,
  launch: (data) => startFrom(data),                              // load
  snapshot: () => ({ data: mySave(), chapter: 3, playTime: 3725 }), // save
  cannotSave: () => (inCutscene ? "slots.busy" : ""),
  getPic: () => pic,                                              // capturePic() taken before the menu opened
});
screen.open("save");                                             // or "load"; call screen.tick() every frame
```

**Version and migration.** `version` (a whole number, default 0) is the layout of `data` this build writes; every record carries it.
When a slot is read, `upgrade(data, fromVersion)` gets the data and the version it was written with (a bare save and a record from
before this field are version 0) and returns `{ ok: true, data }` in the newest layout, or `{ ok: false, message, hint }` to damage the
slot. Raise `version` by one whenever the layout of `data` changes and let `upgrade` step an old save forward
(`if (from < 1) ...; if (from < 2) ...`); it is called on every read, also for data already at `version`, and must leave that as it is.
A record from a NEWER build (higher version than this one), or with a `version` that is not a whole number, is not guessed at: the slot is `damaged` ("update the game" for the first). The record
the screen and `peek` return shows the version the data has now.

**Encryption.** `encrypt: true` writes every slot with `storage.set(key, text, { encrypt: true })`: the file is sealed, so a text
editor shows nothing and an edited or damaged slot is refused instead of loaded (kept aside as a damaged file; `storage.corrupt`
is `true` and the slot looks empty). It needs the project's secret: run `factoria call project.create_storage_secret` once and commit
`factoria.json` (without it, the first `write` throws an Error that names that command). The secret ships with the game, so this is
tamper-evidence against casual editing, not secrecy or anti-cheat: read "Encrypted saves" in `docs/scripting/SCRIPTING_UI_SCENES.md`
before relying on it. A slot saved before `encrypt` was turned on is still read and is sealed when it is written next, and that is also
what a player gets by deleting a sealed slot file and writing a plain one by hand: it loads. `requireEncrypted: true` (needs `encrypt`)
closes that: a slot that is not sealed is `damaged` ("this slot is not encrypted ...", the player can delete it) and the kit reads
the others with `storage.get(key, null, { encrypted: true })`. Turn it on for a new game, or once your players' slots are sealed (a
game that shipped plain saves would show all of them as damaged). The counter and
last-slot keys and the cloud copies stay plain text (the cloud copy that wins a sync is sealed when it is stored locally). Slots are
sealed per storage key, so a cloud copy moves between a player's devices of the same game.

The files are read with `docs.read menu-kit` (see "The files" below). `tests/slots.test.js` builds its own scene, so it passes in any game with the part.

## Text speed

`{"parts":["textSpeed"]}` (or the whole kit) adds a "Text speed" button to the Options Audio tab: slow, normal, fast and instant
(`TEXT_SPEEDS` in `scripts/settings.js`), kept as `settings.load().textSpeed` in characters per second (0 = a whole line at once; the
default is 45, or 0 when the system asks to reduce motion). The kit does not draw dialogue lines: the game's dialogue box sets
`Text.visibleCharacters = settings.revealedCharacters(secondsSinceTheLineAppeared)`. For any other row of the game, call
`addOptionsRow("audio", { id, text, click })` of `scripts/ui/options.js` before the panel is spawned (its comment says how).

## Anchors and pivots

A widget is placed by two points that count Y in opposite directions. `anchor` is a point of the screen as a fraction,
counted from the top-left with Y DOWN (`[0, 0]` top-left, `[1, 1]` bottom-right). `pivot` is a point of the widget, counted
with Y UP (`[0, 0]` its bottom-left corner, `[1, 1]` its top-right, `[0.5, 0.5]` its centre). The widget's pivot sits on
the anchor point, moved by `position`. So a bar on the bottom edge is `anchor [0.5, 1]` with `pivot [0.5, 0]`: its bottom
edge rests on the screen's bottom edge. With `pivot [0.5, 1]` the same bar would hang below the screen.

```
anchor Y (down)            pivot Y (up)

(0,0)---------(1,0)        (0,1)---------(1,1)    pivot [0.5, 0] = middle of the
  |   screen     |           |    widget    |      bottom edge, so with
  |              |           |      x       |      anchor [0.5, 1] the widget
(0,1)---------(1,1)        (0,0)---------(1,0)    stands ON the screen's bottom
```

`factoria validate` warns about a widget of a scene that lies completely outside the design size, which is what a wrong
pivot Y usually does: the warning names the widget, the rectangle it covers and the fix.

## Rotating and scaling a widget

`Transform.rotation.z` (degrees, clockwise on the screen, the way a screen-space Text turns) and `Transform.scale` (x, y) of a
widget, and of every entity above it, turn and scale what is drawn around the widget's own origin: its `position` plus its
anchor point, which is where its pivot sits. What is drawn is also what is hit: a point in the corner of the bounding box that
the turned widget does not cover hits nothing, and hovering, clicking, the wheel, drag and drop, the tooltip, a modal panel's
"inside", a Slider's knob and a TextField's click-to-caret all use the turned rectangle. `ui.rectOf(widget)` is the
bounding box of the turned rectangle. Gamepad and keyboard navigation pick the neighbour by the centres of those boxes (the
"in the beam" test is on the boxes, so a widget turned by 45 degrees counts a little wider than it is).

Where a laid-out child is (since 0.30.0): a child of a Panel `layout` or a ScrollList is put in its slot every frame, and the
layout does **not** write the child's `Transform.position` any more; it keeps the place apart (not saved, not in an undo
snapshot, gone with the entity). So `position` of a laid-out child is your own **offset from its slot**: `[0, 0]` is exactly in
the slot, a script or the inspector can nudge it (the layout keeps the nudge, it does not fight it, and it takes no room from
the neighbours), and a scene file holds only that offset. Everything that looks at where the child is (drawing, `ui.rectOf`,
hit tests, hover, `entity.bounds()`, `entity.worldPosition`, the viewport) sees the placed result; `entity.position` is only the
offset. Under `ui.mirrorRtl` the offset is mirrored with the rest of the screen (a positive x nudges to the left). Dragging a
laid-out child in the editor viewport changes that offset. Moving a widget into a Panel or ScrollList that lays out (`scene.set_parent`,
the hierarchy drag, `setParent(parent, true)` in a script) puts it in its slot: its position becomes 0, rotation and scale stay;
reordering inside the same parent changes only the order. The offset is added in layout space, before the turn and scale of
the sections below, so a nudge of 10 to the right under a Panel turned a quarter lands 10 below it.

A scene saved by an older version has the layout's placement baked into those positions (the layout used to add its delta to
`position` every frame). Loaded now it would be placed twice (the slot plus the old delta), so the engine logs a warning once per
widget when a laid-out child's position equals the place the layout gives it ("... is laid out by its parent and its
Transform.position is ..."); the command `ui.reset_layout_positions` sets those positions to 0 and returns `{ count, ids }`; save
the scene afterwards (`ui.reset_layout_positions {"dryRun": true}` only lists them). The test is a guess: a nudge you chose on
purpose that equals the slot offset is reset too, and a ScrollList scrolled since the scene was loaded can hide a baked
position, so run it right after loading. A position that is not the layout's place is not touched. In the editor it is one Undo step.

How a parent's layout (`Panel.layout`, a ScrollList) sees a turned or scaled child:

- **Scale makes room.** A child at `scale 2` takes twice the width and height in its slot, around its pivot, so a row or column
  makes room for it and a `fit` panel grows. (Unity's layout groups and Godot's containers ignore scale; CSS `zoom` does not.
  FactorIA follows the CSS one, so what you see is what the layout counted.)
- **Rotation keeps the slot.** A turned child stays in its slot and turns in place around its pivot, over its neighbours if it
  is long (CSS `transform: rotate`, Unity's `RectTransform.rotation` and Godot's `Control.rotation` do the same). The slot is
  the unturned, scaled rectangle.
- **A turned or scaled parent** lays its children out as if it were not, and then turns and scales them with it, each around the
  parent's origin: a rotated Panel is a rigid card.
- A screen-space Text, Sprite or Shape2D that is a child of a layout counts the same way: its own scale makes room, its own
  rotation does not. Drawn, it turns and scales with the parent like a widget child: about the parent's origin (its position
  plus its anchor point), with the child's own `anchor` and position taken in the same layout space (give the child the
  anchor of the Panel to place it relative to the card). Under `ui.mirrorRtl` the card is its mirror image as a whole: the
  visual's anchor, position and own rotation flip like a widget's. This only applies under a turned or scaled WIDGET (a Panel,
  a Button...): a plain group that scales multiplies the child's own offset and leaves its anchor where it is, so a HUD group
  that animates its scale stays on screen. The visual is placed from the Transform and the game feel pose, while the widgets'
  hit areas read the Transform alone: during a shake or squash of a visual its hit area does not follow it.
- `TouchStick` and `TouchButton` are the exception: the touch pad takes an axis-aligned rectangle, so a turned one is drawn turned
  but a finger is tested against the bounding box of its turned rectangle. Keep their rotation at 0.

One limit: a ScrollList clips with a scissor rectangle, which cannot turn. A ScrollList that is turned (itself or a parent) by an angle that is not
a multiple of 90 degrees clips what it draws to the rectangle that bounds the turned list, so rows can show in
its corners; the engine says so once in the log (`ScrollList 'id' is turned ...`). The pointer is not affected: it still hits
only the turned list. Quarter turns and scales keep the rectangle axis-aligned and clip exactly.

## Pressing the focused widget in a test

`game.tap("ui_submit")` presses the focused widget, like Enter, Space or the pad's A: it holds the action for one frame,
steps, releases it and steps again, so the widget gets one click (`ui.focus("play_button")` first to choose it).
`game.press("ui_submit")` holds the action until `game.release("ui_submit")`; the UI reacts to the frame the action goes
down, so pressing it again while it is still held presses nothing. Use `tap` for a click and `press`/`release` only to test a
hold; after a `press`, `release` it before the next one.

```js
ui.focus("play_button");
game.tap("ui_submit");          // one click on Play
game.press("ui_submit");        // clicks the focused widget once, now held...
game.step(3);
game.press("ui_submit");        // ...so this presses nothing
game.release("ui_submit");
```

## A gamepad cursor over the menus (and the game)

A game played mostly with the mouse that also supports a pad moves a cursor with a stick. The UI needs no scan of the
scene for it. Each frame: add the stick to the cursor position, then `ui.setPointer(x, y, { down: input.down("primary") })`
(the UI takes the pointer and left button from there from the next frame on: `ui.hovered`, the press, the click on
release, a Slider drag and the wheel's target all follow it); `ui.widgetAt(x, y)` answers what is under a point
(the topmost visible widget or Panel, nothing for a row a ScrollList clips) and `ui.pointerOverUi` whether the cursor is
over any. When the mouse moves again call `ui.setPointer(null)`. If the same button is also bound to `ui_submit`
(`GamepadA` is, by default), a focused widget is clicked by that action as well, so either clear the focus while the
cursor rests (`ui.focus(null)` stays empty until the next D-pad press, an open panel's `autoFocus` does not take it back)
or move only the hover (`down: false`) and let `ui_submit` press the widget you focused under the cursor.

## A choice card, and modal panels

An event, a story beat or a decision in a management game is a card: a title, a body, two or three choices that each say
what they cost, one choice greyed out because the player cannot pay for it, and then what happened. The `card` part is that
card: `new Card(options)` spawns `prefabs/ui/card.prefab.json`, `card.ask(...)` shows the question and `card.answer(...)` the
result with a Continue button, and `card.close()` removes it.

```js
import { Card } from "./ui/card.js";

const card = new Card({
  holdClock: true, // game.paused while the card is open (what was paused before stays paused)
  onChoose: (id) => {
    const result = resolve(id); // the game's own rules
    card.answer({ body: result.text, effects: result.effects }); // "[c:#8fe38f]+4 wood[/c]"
  },
  onContinue: () => card.close(),
});
card.ask({
  kind: "Event",
  title: "A stranger at the gate",
  body: "Asks for [b]shelter[/b].", // rich text: [b], [c:colour], [icon:name] (Text.markup)
  choices: [
    { id: "help", text: "Help", detail: "Costs 2 wood" },
    { id: "buy", text: "Buy the map", disabled: "Needs 50 coins" }, // greyed out, and the line under it says why
    { id: "leave", text: "Leave", detail: "Nothing happens" },
  ],
});
```

- **Modal.** The card's backdrop Panel has `modal: true` (`Panel.modal`, see `docs.components`): while it is
  active the mouse, the wheel, the arrows and the pad reach only the widgets inside it. A button under it gets no hover, no
  press and no click, a tooltip does not show over it, nothing under it takes a drop, the focus leaves it for the card and
  never goes back until the card closes, and `ui.pointerOverUi` is true everywhere, so a map camera or a click-to-build
  handler stands down. It does not pause the game: that is `holdClock`, which sets `game.paused` (scripts that must keep
  running meanwhile set `runWhilePaused`). A game with its own clock (a speed control) leaves `holdClock` off and holds
  that clock itself, as Tidewater Market does.
- **The wheel and Escape under a modal.** A modal consumes the mouse wheel (a ScrollList inside still scrolls); set
  `wheelPassThrough: true` on it when a script should keep the wheel, such as a zoom in an inventory view. Escape is
  `ui_cancel` and usually `pause`: a `ui.on("cancel", ...)` handler that closes the panel returns `true`, which consumes
  the press (`input.consume("ui_cancel")`), so the pause handler of the same frame does not also open the pause menu. While
  a TextField or the on-screen keyboard has the focus, actions bound to letters read as not pressed (`input.textInputMode`),
  so typing P does not pause. The kit's `MenuStack` resets `MenuStack.busy` when a scene builds one.
- **Mouse, keyboard, pad.** The choices are Buttons in a column: up and down (arrows, D-pad, left stick) move between the
  ones that can be chosen, Enter, Space or gamepad A picks, a click picks. The first choice that can be chosen has the focus,
  Continue has it on the result stage. A disabled choice is not focusable and a click on it does nothing: its `disabled`
  text is drawn in its detail line (`reasonColor` changes the colour; `[c:...]` names the game's `text.colors`).
  Escape and gamepad B do nothing: the card is answered with a choice.
- **Looks.** Everything is laid out by the engine (column layouts, wrapped texts, fit panels), so a longer translation or a bigger
  text size (`ui.textScale`, up to 125 % here) makes the card taller, not clipped. Copy the prefab to change the size, the
  colours or the fonts; `new Card({ prefab })` takes the copy. Ids are stable (`card_title`, `card_body`, `choice_<id>`,
  `choice_<id>_detail`, `card_effects`, `card_continue`) for tests.
- **Test.** `tests/card.test.js` shows a click under the card doing nothing, the arrows skipping a disabled choice, the pad
  and the result stage. `Panel.modal` alone works on any panel (a confirm dialog, the pause menu): set `"modal": true` on the
  root Panel of a screen that must own the input.

## Widgets from your own entities

A shop sign you hit with the mouse, a book whose pages turn, a menu painted on a wall in a 3D-looking scene, a card hand,
a map marker: these are not rectangles in a Panel. Give any entity the `Interactable` component and it is a widget of the same
system as Button, Toggle and Slider, whatever it is made of (sprites, shapes, text, children), in world space or on the
screen. There is no second UI behind it: it takes focus, arrow-key and pad navigation, `Tab`, `ui_submit` and `ui_cancel`,
hover and press, `Panel.modal` scopes, `game.click`, `ui.widgetAt`, `ui.rectOf` and the `ui.*` commands exactly like a Button.

```json
{ "id": "start", "components": {
    "Transform": { "position": [-60, 40] },
    "Shape2D": { "size": [60, 20] },
    "Interactable": { "autoFocus": true } },
  "children": [
    { "id": "start_glow", "components": {
        "Shape2D": { "size": [64, 24], "color": [1, 1, 0, 1] },
        "InteractableVisual": { "mode": "show", "when": "hover" } } } ] }
```

- **The hit area.** `size` and `offset` give a rectangle in the entity's own space (so it scales and turns with the entity and its
  parents). With `size` `[0, 0]` the area is the box around the visuals of the entity and its active children (sprites, shapes,
  text); not counted are a child that is an `InteractableVisual` which shows and hides with the state (a glow that
  appears on hover must not make the area grow), a slider's `knob` and `fill`, and a child that is an Interactable itself (it
  is a widget of its own). An entity with no area cannot be hit or clicked: `game.click` says so.
- **World or screen.** `space: "auto"` is screen space when the entity or a child draws in screen space (a `Text` or `Sprite`
  with `space: "screen"`), else world space; `"world"` and `"screen"` force it. A world-space area is projected through the
  camera that draws at the pointer (several cameras with viewports work, each pointer position uses the one drawing there), so a
  widget on a swaying sign or a page turning in 3D is hit where it is drawn, and follows parents that move, scale or rotate.
  A screen-space widget wins over a world-space one under the same point, and a modal `Panel` blocks the Interactables
  outside it like any other widget outside it. An Interactable on an entity that is also a Button, Toggle, Slider,
  TextField, Panel or other UI-box component is ignored: the built-in widget wins. The hit test is the quad of the
  area's four projected corners (exact under a perspective camera too); a slider drag measures how far along the projected
  track the pointer is, which is only approximate under strong perspective.
- **`kind`.** `button` sends `ui.click {id}` when the pointer is released over it after being pressed on it, or on `ui_submit`
  while it has the focus. `toggle` flips `on` the same way and sends `ui.change {id, value}` (a boolean; a toggle sends no
  `click`). `slider` keeps a number `value` between `min` and `max`, snapped to `step`: dragging along the area, or
  left / right (down / up with `axis: "y"`) while focused, sets it and sends `ui.change {id, value}`. The track is the area along
  `axis`. `knob` (a child of the Interactable) is moved along the track to the value, and `fill` (a child with its pivot at the
  start of the track) is scaled along `axis` to the fraction; they are placed in world space, or in screen space when `size`
  is set. Scripts may write `on` and `value`: no event is sent for a write (`game.setSlider(id, value)` and the
  `ui.set_slider` command do send it, as a drag would). In a script, `knob` and `fill` may name children spawned after the slider: `world.spawn` leaves them empty with a warning and links them when an entity with that id appears (or put the children in the same call with `children`); a field set by hand in between wins, and an id that never appears is reported again after about 10 seconds of frames.
- **States, without code.** `Interactable.state` is the one state the visuals show: `disabled` (`enabled` is false), else
  `pressed`, else `hover`, else `focused`, else `normal`; `hovered`, `focused` and `pressed` are the flags (read-only, written by the
  UI). Put `InteractableVisual` on a child of the Interactable (or set `target`): `mode: "show"` makes that entity active only while
  `when` holds (`hover`, `pressed`, `focused`, `highlighted` = hovered OR focused, one look for the pointer and the keyboard / gamepad, `normal`, `disabled`, `on` / `off` for a toggle, `always`); `mode: "tint"` sets the colour
  of its Sprite, Shape2D or Text from `normal`, `hover`, `pressed`, `focused` and `disabled`. A check mark that shows while a toggle is on
  is a child with `when: "on"`. `InteractableVisual` on the Interactable's own entity does nothing in `show` mode.
- **Focus and navigation.** The same rules as the built-in widgets (see SCRIPTING.md, "Focus and navigation"): nothing is
  focused until an `autoFocus` widget takes it, the arrows and the d-pad move the focus to the nearest widget in that direction
  among Buttons and Interactables alike (using their areas as seen on the screen), `ui_cancel` sends `ui.cancel`. `Tab` (`ui_next`) and
  `Shift+Tab` (`ui_previous`) walk the focusable widgets in reading order, wrapping around (new default actions for every widget); like the arrows they need a focus
  to start from (focus one with `autoFocus` or `ui.focus(entity)`). `focusOnHover: true` moves the focus to the widget when the
  pointer enters it, once per entry (a widget that appears, or is switched on, under a resting pointer is an entry too, so a page turn leaves the focus and the hover tint on the same widget); the default, like a Button, moves it on a press. `enabled: false` makes it a greyed-out
  widget: never hovered, focused or clicked, skipped by navigation.
- **Events** (`ui.on`, or `this.on("ui.<type>", ...)`): `click`, `change`, `focus` and `cancel` as for the built-ins, plus
  `hover` (`value` true when the pointer came over it, false when it left), `blur` (the focus left it), `press` (the pointer went down
  on it) and `release` (the pointer went up; `value` is true when it was still over the widget, and then `click` follows). `hover`,
  `blur`, `press` and `release` come from Interactables only; Button, Toggle and Slider do not send them.
- **Finding it.** `ui.widgetAt(x, y)` returns it, `ui.rectOf(id)` is the box of its area on the screen (design pixels, y down), `ui.focus(id)` focuses it
  (false when it is disabled), `ui.state` lists it with `kind: "Interactable"`, `interactableKind`, `state`, `world`, `value` (a toggle's or slider's)
  and `text` (its accessibility label), and `game.click(id)` / `game.mouseMove(id)` / the `game.click` command aim at the centre of its area.
  `label` is the accessibility label; empty, it is the first `Text` among the entity and its children; `key` and `keyArgs` translate it
  like a Button's. There are no tooltips on an Interactable yet.
- **A test plays it like a person.** Nothing in this menu is a Button, and the test only presses, moves and clicks:

```js
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";
import menu from "../scenes/main.scene.json";

test("the world menu works with the pointer and the keyboard", () => {
  game.loadJson(menu);
  game.step(1);
  expect(ui.focused.id).toBe("start");                // autoFocus
  game.mouseMove("music");                            // the centre of its area, as the camera shows it
  game.step(1);
  expect(ui.hovered.id).toBe("music");
  game.click("music");                                // a toggle: press, release, ui.change
  expect(game.find("music").get("Interactable").on).toBe(true);
  expect(game.find("music_tick").active).toBe(true);  // an InteractableVisual child with when: "on"
  game.tap("ui_down");                                // the arrows walk world widgets like Buttons
  game.setSlider("volume", 0.5);                      // a slider Interactable: ui.change, and the knob moves
  const track = ui.rectOf("volume");
  game.drag("volume", [track.x + track.w, track.y + track.h / 2]);      // dragging to the end of the track
  expect(game.find("volume").get("Interactable").value).toBe(1);
});
```

The engine's own test of this (`engine/runtime/tests/ui_tests.cpp`, "a world-space menu of plain entities") runs a menu of a button with a
hover glow, a toggle with a tick, a slider with a knob and a disabled card, next to a screen-space Button.

## Tooltips

A tooltip is a small box with a title and lines that shows beside the pointer after it rests on something. The engine
keeps the timer, the placement and the drawing; the game says what it says.

```json
{ "id": "buy", "components": { "Button": { "text": "Buy", "tooltip": { "title": "tip.buy.title", "lines": ["tip.buy.cost"], "args": { "cost": 12 } } } } }
```

- **Content.** A string (one line), or `{ "title": text, "lines": [text | {"text", "color"}], "args": {...} }`. Every text
  is a localization key when localization is on and the current language has that key (`args` fills its `{placeholders}`;
  the box follows a language change while it shows), and plain text otherwise. Empty lines are skipped.
- **Where it can be set.** The `tooltip` field of any widget or Panel. The pointer's widget is the topmost one
  (`ui.widgetAt`); if it has no tooltip, its nearest ancestor with one is used, so a tooltip on a Panel covers its children.
  A Panel that draws nothing (alpha 0, no texture) is not hit, so it shows none. `Text` is not hit either: put the tooltip on
  a Panel around it, or use `ui.setWorldTooltip`.
- **From a script.** `ui.setTooltip(entity, () => ({ title: "Wheat", lines: [`${n} in stock`] }))` calls the function
  when the pointer has rested for the delay and again every frame while the box shows, so the numbers stay current;
  returning `null` shows nothing. `ui.setTooltip(entity, content)` writes the field, `ui.setTooltip(entity, null)` clears
  it. `ui.setWorldTooltip((x, y) => content | null)` is asked when the pointer rests over no widget. Registrations end
  with the scene. A game that pauses its scripts returns null from its functions while paused.
- **Not a widget.** `ui.showTooltip(content, { x, y })` shows at once, at `x, y` in design pixels (default the pointer),
  and stays until `ui.hideTooltip()`, a pointer move of more than 5 pixels, or a scene load.
- **When.** After `ui.tooltipDelay` seconds of rest (default 0.5; the pointer may drift 5 pixels), counted with the UI
  clock, not wall time. Moving farther, reaching another target, pressing the pointer button or loading a scene hides it. On
  a phone it stays off until the last input was not a touch, unless `"tooltipOnTouch": true`.
- **Placement.** Down and right of the pointer by `gap`; if that crosses the screen edge (4 pixels margin) it flips to the
  other side of the pointer, and in the end it is clamped inside the screen.
- **Theme**, in `factoria.json`:

```json
"ui": {
  "tooltipDelay": 0.4,
  "tooltipOnTouch": false,
  "tooltip": { "color": [0.03, 0.04, 0.07, 0.96], "textColor": [0.92, 0.94, 0.98, 1], "titleColor": [1, 0.82, 0.3, 1],
               "font": "assets/fonts/ui.ttf", "fontSize": 18, "titleSize": 20, "maxWidth": 300, "spacing": 3,
               "padding": [10, 8, 10, 8], "gap": 16, "layer": 1000, "texture": "assets/ui/tip.png", "slice": [8, 8, 8, 8] }
}
```

  Sizes are UI units, so `ui.scale` and `ui.textScale` apply. A line longer than `maxWidth` wraps. `layer` is the draw
  order (1000: above every widget). An unknown key or a wrong type is an error that names the key and what it accepts.
- **Tests.** `ui.tooltip` is `null` or `{ title, lines, rect, source, widget }` (`source` is `"widget"`, `"script"`,
  `"world"` or `"manual"`; `rect` is `[x, y, w, h]` in screen pixels). Move the pointer with `ui.setPointer(x, y)`,
  `game.step` past `ui.tooltipDelay`, and assert. `ui.check_layout` reports a `tooltip` issue for a visible widget
  whose static tooltip is invalid or whose box is larger than the screen in some language or size.

## Drag and drop

A widget with `draggable` can be picked up with the pointer and put down on another widget or on the world (the map). The
engine does the press, the slop, the target under the pointer and the events; the game decides what a drop means.

```json
{ "id": "worker_3", "components": { "Button": { "text": "#3", "draggable": { "payload": { "worker": 3 }, "slop": 6 } } } }
```

```js
ui.setDropTarget("farm_slot", (d) => canWork(d.payload.worker));   // true, false or a function; null removes the rule
ui.on("dragStart", (e) => ui.setDragImage("drag_chip"));            // the chip follows the pointer
ui.on("drop", (e) => assign(e.payload.worker, e.target ? e.target.id : mapCellAt(e.x, e.y)));
ui.on("dragCancel", (e) => hideChip());                             // e.reason: "rejected" | "cancel" | "gone" | "script"
```

- **Starting.** `draggable` is `true` or `{ "payload": any JSON, "slop": pixels }` (slop 0 to 100, default 6). A press on
  the widget, or on a child that is not draggable itself, followed by a move of `slop` pixels starts the drag: `dragStart`.
  A press released before that is an ordinary click. A Slider or a TextField under the press keeps the pointer for itself.
  When the drag starts the press is dropped, so the release makes no `click` and flips no Toggle, and a tooltip hides.
- **Events** (`ui.on`): `dragStart`, `dragOver` (the pointer moved, or the thing under it or whether it accepts changed:
  once per frame at most), `drop` and `dragCancel`. Each has `id` / `entity` / `source` (the dragged widget), `payload`,
  `x`, `y` (the pointer, design pixels), `target` (an Entity, or `null` over the world) and `accepts`; `dragCancel` also has
  `reason`. `ui.on("drop", widget, fn)` filters by the drop target, the other three by the dragged widget.
- **Targets.** The target is the topmost widget under the pointer (`ui.widgetAt`, the drag image left out), moved up to the
  nearest ancestor that has a rule when one does. A rule is set with `ui.setDropTarget(widget, true | false | fn | null)`;
  a function gets `{ source, payload, x, y }` every frame the drag is over the widget, so it can also colour the target. A
  widget with no rule refuses. The world (no widget under the pointer) accepts, unless `ui.setWorldDropTarget(false | fn)`
  says otherwise. Rules end with the scene.
- **Ending.** Releasing the button over a target that accepts sends `drop`. Anywhere else it sends `dragCancel` with
  `reason: "rejected"`. `ui_cancel` (Escape, the pad's B) cancels with `"cancel"` and then does not send `ui.cancel`;
  `ui.cancelDrag()` with `"script"`; a source that is destroyed or deactivated with `"gone"`. A scene load ends a drag
  silently. After a `drop` or `dragCancel` the mouse button is still down for a while: nothing else reacts to it.
- **The image.** `ui.setDragImage(widget)` (call it from `dragStart`) keeps that widget's centre under the pointer; it
  is ignored by hover and by `widgetAt`. The engine only moves it: show it in `dragStart`, hide it in `drop` and
  `dragCancel`. It moves the widget's own `position` by the step that brings its centre under the pointer, so keep it out of a layout parent (it would take a slot there).
- **Reading it.** `ui.dragging` is `null`, or `{ source, payload, from: {x, y}, x, y, target, accepts }`. A script that
  reads the mouse for the map skips while `ui.dragging` is set, and a press that began on the UI is already ignored by
  `ui.pointerOverUi`.
- **Gamepad and tests.** A drag follows the UI pointer, so a gamepad cursor drags by holding `ui.setPointer(x, y,
  { down: true })` and moving it, and a touch drags like the mouse. `game.drag(from, to)` presses on a position or
  widget, moves to the other in four frames and releases: `game.drag("worker_3", "farm_slot")`, or a position such as
  `{ x: 640, y: 650 }` for a drop over the world. A press-and-click mode for players who cannot hold a button is the
  game's own (two clicks); the engine's drag needs the held button.

## Charts

A `Chart` draws numbers as bars or lines inside its rectangle. It is a widget like a Panel: placed by `size`, `anchor`,
`pivot` and `layer`, with `color` as the background, a `tooltip` of its own, and a child of a Panel or a ScrollList like
the others. The UI layer draws all its bars or lines in one batch, so a chart of hundreds of samples costs one draw call
more than its background.

```json
{ "id": "coins_chart", "components": { "Chart": { "size": [540, 110], "kind": "line", "colors": ["#ffd166"], "includeBaseline": false } } }
```

```js
const chart = world.find("coins_chart").get("Chart");
chart.values = history;                                  // [3, 5, 2, ...] or [[3, 5], [1, 4]] for two series
ui.on("chartHover", "coins_chart", (e) => {              // e.index: -1 when the pointer left the chart
  if (e.index >= 0) ui.showTooltip({ title: `Day ${e.index + 1}`, lines: [String(e.value)] });
  else ui.hideTooltip();
});
```

- **Data.** `values` is an array of numbers (one series) or an array of arrays (a series each, oldest value first). A
  value that is not a number counts as 0. Write a whole new array when the data changes; the chart redraws every frame.
- **Kinds.** `bar` (default) gives each sample a column, the series side by side in it, each bar growing from `baseline`
  with `barGap` empty between columns; a bar is at least one unit tall. `line` draws one polyline per series through its
  points, spanning the plot edge to edge with `lineWidth`.
- **The axis.** Automatic: the lowest and highest value, always including `baseline` (0 unless you set it), so bars scale to
  the maximum and start at zero. `includeBaseline: false` fits the data tightly (a line of coins that stays near 5000),
  `min` and `max` fix a side. The maximum and minimum are written in the plot's top-left and bottom-left corners (`showLabels`,
  `decimals`, `font`, `fontSize`, `textColor`) in the current language's number format: "1,234.5" in English, "1.234,5" in
  Spanish. The rule at `baseline` is `showBaseline`; `marks` is a list of sample indexes that get a thin vertical rule (the
  first day of a season).
- **Slots.** A series shorter than `slots` is right-aligned: a chart that fills over time keeps each sample's width, the
  empty room is on the left. With `slots` 0 the plot has room for the longest series.
- **Hover.** The pointer over the plot is reported as the sample under it: for bars the column (and the bar of it, in
  `series`), for lines the point closest horizontally (and the closest series vertically). `ui.on("chartHover", fn)` (or
  `ui.on("chartHover", chart, fn)` for one chart) gets `{ id, entity, index, series, value }` each time that sample changes
  and `index` and `series` -1, no `value`, when the pointer leaves the plot or the chart. `Chart.hoverIndex` and `hoverSeries`
  hold the same. A chart is not focusable, but it counts as a widget for `ui.pointerOverUi` and `ui.widgetAt`, so a click on
  it does not reach the world. `game.mouseMove([x, y])` and one `game.step()` hover it in a test; a chart is also listed in
  `ui.state` as kind `Chart`.

## A camera inside the UI

A `CameraView` draws a `Camera` inside its rectangle: an item turning on a stage in an inventory, a character portrait, a
minimap of a 3D level, a small second view of the world. It is a widget like a Panel (`size`, `anchor`, `pivot`, `layer`,
`color` as the background, a child of a Panel or a ScrollList), so the picture is clipped by a ScrollList and is covered by
a modal Panel or a Button with a higher layer, with no hole to leave in the page. The camera is drawn into an image the size of the rectangle (so its aspect follows the
rectangle, whatever `Camera.viewport` says), before the frame's UI, and the UI then draws that image in the rectangle at
`layer` + 1 (the background is at `layer`: a widget meant to sit on the picture needs a layer of at least `layer` + 2).

```json
{ "id": "item_stage", "components": {
    "Transform": { "position": [0, 300, 4] },
    "Camera": { "projection": "perspective", "fov": 35, "primary": false, "lighting": "studio", "clearColor": [0.09, 0.1, 0.15, 1] } } }
{ "id": "item_view", "components": {
    "CameraView": { "camera": "item_stage", "size": [400, 360], "layer": 305 } } }
```

```js
const spin = { yaw: 0 };
ui.on("viewPointer", "item_view", (e) => {               // e.phase: "down" | "drag" | "up" | "wheel"
  if (e.phase === "drag") spin.yaw += e.dx * 0.7;        // e.dx, e.dy: pixels moved since the last event
  if (e.phase === "wheel") zoom = Math.min(1.5, Math.max(0.45, zoom - e.wheel * 0.1));
});
```

- **The camera.** `CameraView.camera` is an entity id (or a name). Give that Camera `primary: false`: a primary one also draws
  in the main view. The camera and the widget both have to be active. A camera that is missing, inactive or not yet made draws
  only the widget's `color` (the script may spawn it a frame later); nothing is logged. The same camera can be shown by several
  views, each with its own image.
- **Studio lighting.** `Camera.lighting: "studio"` ignores the scene's `Light`s, ambient, sky and fog and lights what the camera
  sees with its own key, fill and rim lights (fixed directions relative to the camera) and a soft ambient, so a model looks
  the same on a stage far from the level or in the middle of a bright scene. `Camera.studioIntensity` (default 1) scales the
  rig. Add `emissive` to a part if it should glow. `lighting: "scene"` (default) uses the scene's lights, as any camera does.
- **Pointer.** A press over the view, a move while it is held and the release send the game event `ui.viewPointer`
  (`ui.on("viewPointer", fn)`, or with a target `ui.on("viewPointer", "item_view", fn)`): `{ id, entity, phase, x, y, u, v, dx,
  dy, wheel }` where `x, y` is the pointer in design pixels, `u, v` its place in the view (0..1 from the top-left; outside that
  while a drag leaves the view), `dx, dy` the move since the previous event and `wheel` the notches of a "wheel" phase. The
  widget under the pointer decides: a Button above the view keeps its click, a view under a modal Panel hears nothing, a view
  clipped by a ScrollList hears only the visible part. A drag ends with the release wherever the pointer is. A finger works like
  the mouse. `pointerEvents: false` turns all of it off (the view still blocks clicks to the world). `captureWheel` (default true)
  makes the wheel over the view a "wheel" event and keeps it from `input.mouse.wheel` and from the list under it.
  The view is not focusable: keys and a pad turn what it shows from your own script (`input.axis`).
- **Cost and limits.** Every view is one more render pass of its camera per frame and one image of its size (`resolution`, 1 by
  default: 0.5 for a soft, cheap picture, up to 2). The images of views that went away are freed in the same frame. A view
  draws the world its camera sees, not the UI or the `space: "screen"` items (so a CameraView cannot show another); `bloom`,
  `colorFilter` and the debug draw belong to the main frame and are not applied in it; 2D lights are read per pixel, so a view
  of a 2D scene with many lights costs more than the main frame does; a studio camera draws no sky. Only a camera can be shown, not a
  texture. To put a camera's live picture on a `Panel.texture` or a `Button.icon` instead, give that camera a
  `Camera.renderTarget` and use `"target:<name>"` there (docs/RENDERING.md, "Render targets"): the widget shows the picture and
  forwards no pointer input to the world behind it, so use a CameraView when the player has to drag what the camera shows.
- **Test.** `game.mouseMove`, `game.mouseDown`, `game.wheel` and `game.touchStart` over the rectangle send the events; a
  render test compares pixels of the view (the engine's own tests do this with a cube on a stage).

## A studio intro: a video that any button skips

A game that opens with a logo film uses a `Video` component and a few lines of script. It is not part of the kit (the
film is yours); Clockwork Courier's `scenes/intro.scene.json` and `scripts/intro.js` are this recipe running.

1. **The file.** An MPEG-1 video with MP2 sound in a `.mpg` (that is the only format the engine decodes; a clip of a few
   seconds at 640x360 is well under a megabyte). Bring any other video with
   `factoria call assets.import '{"source":"C:/art/logo.mp4"}'`: it converts the file with ffmpeg (`factoria setup ffmpeg`
   installs one) into `assets/video/logo.mpg`, scales it down to at most 1280 pixels wide, and records where it came from.
2. **The scene.** A camera, a `Video` that fills the screen (`anchor` and `pivot` at the centre, `size` the design size,
   `fit: "contain"` keeps the picture's shape and shows `color` in the bars), and an entity with the script. A visible
   Skip button helps touch players; any tap, key or pad button skips too.
3. **The script.** It loads the next scene when the video ends or when the player presses anything.

```json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "camera", "components": { "Transform": { "position": [640, 360, 0] }, "Camera": { "clearColor": [0, 0, 0, 1] } } },
    { "id": "intro_video",
      "components": {
        "Video": { "path": "assets/video/logo.mpg", "size": [1280, 720], "anchor": [0.5, 0.5], "pivot": [0.5, 0.5],
                   "fit": "contain", "color": [0, 0, 0, 1], "bus": "sfx" } } },
    { "id": "intro", "components": { "Script": { "path": "scripts/intro.js" } } }
  ]
}
```

```js
// @ts-check
// scripts/intro.js: plays scenes/intro.scene.json (the Video plays by itself: autoplay is on) and goes to the menu when
// the video ends or the player presses anything.
import { Behaviour, scene, input, world } from "factoria";

const SCENE = "scenes/intro.scene.json";
const NEXT = "scenes/menu.scene.json";

export default class Intro extends Behaviour {
  onStart() {
    this.frames = 0;
    this.left = false;
    // "ended" comes once, when the video reaches its end (never for a Video with loop on).
    this.offEnded = world.find("intro_video")?.video.on("ended", () => this.leave());
    // Android Back skips the intro instead of quitting the game in the middle of it.
    this.offBack = input.onBack(() => {
      this.leave();
      return true;
    });
  }

  onDestroy() {
    this.offEnded?.();
    this.offBack?.();
  }

  /** Loads the next scene once, and only while this intro is the scene that is playing. */
  leave() {
    if (this.left || scene.current !== SCENE) return;
    this.left = true;
    scene.load(NEXT);
  }

  onUpdate() {
    // Any key, tap, click or pad button. The first frame is skipped: the press that started the game must not skip the film.
    if (this.frames > 0 && input.lastPressed()) this.leave();
    this.frames += 1;
  }
}
```

- **Once.** To show the intro only on the first launch, `storage.set("introSeen", true)` in `onStart` and call
  `scene.load(NEXT)` at once when `storage.get("introSeen", false)` is true (Clockwork Courier does).
- **The check on `scene.current`.** The `ended` event and a press can come in the same frame, or after another script
  moved to a different scene; `leave()` only acts while this intro is still the current scene, so a late answer never
  loads the menu over a level.
- **Time is the game clock.** The film pauses with the game (`time.scale` 0), and a headless test steps it with
  `game.step`: `game.step(60 * 6)` plays a five-second film to its end, which is how a test checks that the
  intro ends. `video.time`, `video.duration`, `video.playing` and `video.ended` are readable; `video.seek(s)`,
  `video.pause()`, `video.play()` and `video.stop()` control it ([SCRIPTING.md](../SCRIPTING.md), `entity.video`).
- **A video with no sound** works (the file just has no audio track); `factoria validate` reports a `.mpg` the engine
  cannot play (a different codec inside the file, or not an MPEG file) with the ffmpeg command that fixes it.

## Manual check: hear the speech

Tests cannot hear anything, so once per system run the game (`factoria run <project>` or the exported game), open
Options > Audio, turn "Read menus aloud" on (you hear "Read menus aloud"), go back and move the focus with the arrows or
the pad: each widget is said. Change the language in Options > Language and move again: the voice should follow it when
the system has a voice for that language (otherwise the default voice reads it, possibly with the wrong accent).

- **Windows.** Needs nothing: SAPI 5 voices are part of Windows (Settings > Time & language > Speech lists them; add a
  language's voice there). The voice is chosen by the language's locale.
- **macOS.** Nothing to install; extra voices are in System Settings > Accessibility > Spoken Content > System voice.
- **Linux.** Install speech-dispatcher and a speech engine (`sudo apt install speech-dispatcher espeak-ng`; the game
  loads `libspeechd.so.2` when it first speaks) and start the dispatcher (`spd-say hello` must be audible). Without
  them `ui.speechAvailable` is false and the first `ui.speak` logs one warning.
- **Android.** Needs a speech engine (Google Speech Services is on most phones; Settings > System > Languages & input >
  Text-to-speech output). The first line spoken right after the game starts is kept until the engine is ready.
- **iOS.** Nothing to install; check with the device's volume up and the ringer switch in both positions.
- **Web.** Open the exported page in a browser and click or press a key in it once (browsers refuse to speak before the
  player has touched the page). The voices are the browser's.
