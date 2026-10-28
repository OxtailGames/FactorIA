[Back to the index](../README.md)

# Commands: ui

## `ui.caption` (modifies state)

Since 0.2.0.

Show a subtitle line on the Captions component for a few seconds.

The same as `ui.caption(text, seconds, { key, speaker })` in a script: a line without a sound, drawn by the Captions component (docs/TEXT.md, "Captions") for `seconds` of the game clock; the newest Captions.maxLines lines show. With `key` (a localization key) the line is the translation and follows a language change. Without a Captions entity the line is only tracked and the log says so once. Example: ui.caption {"text":"Watch out!","seconds":2,"speaker":"Mara"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `text` | string | no | The line (the fallback when `key` is set and no string table has it). |
| `key` | string | no | Localization key of the line. |
| `speaker` | string | no | Name drawn before the line. |
| `seconds` | number | no | How long it shows, in game-clock seconds (default 3). |

## `ui.check_layout` (modifies state)

Since 0.2.0.

Load each screen in each language and text size and list every text that overflows its box, overlaps another text or leaves the screen.

For every scene (default: each scene with UI) and every case it loads the scene, switches the language, sets the text size, lets the scripts settle (a few frames) and reads ui.state. A text is reported when (1) `overflow`: it still does not fit its box at its effective size (the same test as ui.overflowed(id): after autoShrink and maxTextScale, see docs/TEXT.md), (2) `overlap`: two visible texts or labelled widgets (Text, Button, Toggle, Slider, TouchButton, neither the parent of the other) cover each other, (3) `offscreen`: its rectangle leaves the screen, or (4) `tooltip`: the `tooltip` of a visible widget is not a valid tooltip, or its box (the project's ui.tooltip style: maxWidth, font sizes, padding) is larger than the screen, so it cannot be placed inside it. The cases are every language x every text scale x every interface scale (`uiScales`, default: the current ui.scale), plus (with `pseudo`) a pseudo-localized pass in the default language where each translation is lengthened ("[" + vowels doubled + "]", at least 40 % longer) to show where an unknown, longer language would break. Returns {ok, checked: [{scene, cases}], skipped: [scenes with no UI], issueCount, issues: [{scene, kind, entity, path, key, text, rect, other?: {entity, path, key, text, rect}, cases: [{language, textScale, uiScale, pseudo}]}]}: one issue per problem with every case where it happens, so the fix is to the widget (autoSize, autoShrink + minFontSize, maxWidth, a bigger box, a shorter string). A widget inside a ScrollList is checked on the part the list shows (its rectangle intersected with the list's), so a row half scrolled out is not reported for the half that is clipped, and a row fully outside is skipped. `steps` runs actions per scene (clicks on widgets by name or id, keys, actions, frames) before the checks, with a layout pass between them, so a panel a click opens is checked too; the state they reach stays for every case of that scene. Only texts with a localization `key` follow the language and the pseudo pass; a text a script writes is checked at each text scale only (and in the state the steps reach). It RELOADS scenes: afterwards the running scene is loaded again and the language, text size, interface scale and pseudo mode are restored, but the game state is lost, so run it on a fresh game or session. Refused while a frame runs. The warnings, errors and scripts of each load behave as in scene.load. With `current: true` it does not load anything: it measures the scene that runs, with the panels a test or the player has opened, in every language, text size and interface scale of the cases (it steps a few frames per case so the layout settles, then puts the language, text size and scale back; the game state is kept), and `scenes` and `steps` are not allowed. A test calls it as game.checkLayout() after opening a panel. Example: ui.check_layout {"textScales":[1,2],"uiScales":[0.75,1,1.5],"pseudo":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scenes` | array | no | Project-relative scene paths to check, e.g. ["scenes/menu.scene.json"]. Default: every scene of the project that has UI (a widget or a screen-space Text). |
| `languages` | array | no | Languages to check, as in factoria.json localization.languages. Default: all of them (the current one when the game has no localization). |
| `textScales` | array | no | Text size options (ui.set_text_scale) to check. Default: [1, 2]. |
| `uiScales` | array | no | Interface scales (ui.set_scale) to check, every one with every language and text size. Default: the current ui.scale. List every size the Options menu offers. |
| `pseudo` | boolean | no | Also run the pseudo-localized pass (default language, every text scale). Default: true. |
| `steps` | object | no | Per scene (project-relative path, as in `scenes`), a list run once after the scene loads and settles, before the checks, to reach a panel or state that is not there at the start: {"click":"widget name or id"} (the centre of its laid-out rectangle; an error when it is hidden, clipped or has no area), {"key":"Enter"} (press and release), {"action":"jump"} (press and release an input action), {"frames":n} (step n frames). The UI is laid out between steps. Example: {"scenes/menu.scene.json":[{"click":"options_button"},{"frames":10}]}. |
| `current` | boolean | no | Measure the running scene as it is now (the panels open, the state reached) instead of loading each scene: no reload, the game state is kept. Not with `scenes` or `steps`. Default: false. |
| `settleFrames` | integer | no | Frames stepped after each change so scripts and layout settle. Default: 4. |

## `ui.clear_captions` (modifies state)

Since 0.2.0.

Remove every subtitle from the screen now.

The same as `ui.clearCaptions()` in a script. Sounds that have a caption keep playing. Example: ui.clear_captions {}

## `ui.set_scale` (modifies state)

Not released yet (on main after 0.2.0).

Set the interface scale: every screen-space widget and Text gets bigger or smaller.

The same as `ui.scale = value` in a script (docs/TEXT.md, "Interface size"): the size, offset, padding, spacing, margins and font size of every screen-space widget (Panel, Button, Label, Slider..., Text with space "screen") are multiplied by `scale`, on top of the text size option (ui.set_text_scale); the layout, ui.state rectangles, clicks and the drawing all follow. The widgets are laid out in a screen of design size / scale, so a Panel with anchors keeps its place and its children stay inside it. World-space Text and entities are not scaled. 1 is as authored; the range is 0.5 to 3. The project default is the "ui": {"scale"} of factoria.json. A change sends the game event `ui.scale` {value, previous}. The engine does not save the option: the game stores it (storage) and sets it at start. Look at the result with game.screenshot, and check every size you offer with ui.check_layout {"uiScales": [...]}. Example: ui.set_scale {"scale":1.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scale` | number | yes | Interface multiplier: 1 = as authored, 1.5 = 50% bigger, 0.5 = half. |

## `ui.set_slider` (modifies state)

Not released yet (on main after 0.2.0).

Set a Slider the way a drag does: clamped, snapped to step, and ui.change is sent.

For tests and tools (game.setSlider(id, value) in a test calls it). The slider takes focus, `value` is clamped to [min, max] and snapped to `step` exactly as dragging the track does, and the "ui.change" event {id, value} is sent when the number changed (not when it was already there). Writing Slider.value from a script sends no event: that is the difference. Needs an active, interactable Slider. Returns {id, value, changed}. Example: ui.set_slider {"id":"music_volume","value":0.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name) of the Slider. |
| `value` | number | yes | The wanted value; clamped to [min, max] and snapped to step. |

## `ui.set_text_scale` (modifies state)

Since 0.2.0.

Set the text size option: screen-space Text and the labels of UI widgets get bigger or smaller.

The player's "text size" setting (accessibility), the same as `ui.textScale = value` in a script: the font size of every screen-space Text (space "screen") and of the labels of Button, Toggle, Slider and TextField is multiplied by `scale`, and so is what ui.measureText returns for them (space "screen", the default). World-space Text is part of the world and is not scaled, nor is its entity.bounds(). 1 is normal size; the range is 0.5 to 3. Wrapped text keeps its maxWidth and grows taller, and widgets keep their rectangles, so lay a menu out with room for the biggest size you offer. The engine does not save the option: the game stores it (storage) and sets it at start. Look at the result with game.screenshot. Example: ui.set_text_scale {"scale":1.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scale` | number | yes | Text size multiplier: 1 = normal, 1.5 = 50% bigger, 0.5 = half. |

## `ui.speak` (modifies state)

Since 0.2.0.

Say a line aloud with the system's text to speech (or record it, headless).

The same as `ui.speak(text, { interrupt })` in a script: the line is said in the game's current language (i18n.language) with the system voice for it. `interrupt` (default true) stops what is being said first; false queues the line. Output only: it never changes the simulation. A system without speech (Linux without speech-dispatcher, Android without a speech engine) says nothing and `spoken` is false. Headless runs, tests and the editor say nothing and record the line (game.spoken() in tests). Example: ui.speak {"text":"Play"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `text` | string | yes | What to say, already localized. |
| `interrupt` | boolean | no | Stop what is being said first (default true); false queues the line. |

## `ui.state`

Since 0.1.6.

List the UI widgets on screen (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, and screen-space Text) and which has focus.

Returns {focused, hovered, tooltip, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed, interactable, visible, value?, text?}]} in reading order (top to bottom, then left to right). Only widgets that are active in the hierarchy are listed. rect is in design pixels, top-left origin, +Y down: click a widget with game.input {"mouse": {"position": [x, y], "left": true}} or move the focus with the ui_up / ui_down / ui_left / ui_right and ui_submit actions (game.input {"press": ["ui_down"]}). `visible` is false when a ScrollList clips the widget away entirely, and for an on-screen gamepad control that is hidden (touchOnly while the player is not using touch). `value` is a Toggle's boolean, a Slider's number or a TouchStick's [x, y]; `pressed` of a TouchStick or TouchButton is a finger holding it (drive one with game.input {"touch": ...}); `text` is a Button's or TouchButton's text, a Toggle's or Slider's label or a TextField's contents. Screen-space Text entities (space "screen") follow the widgets as {id, kind: "Text", rect, text} (they are never focused or pressed; use it to check where HUD text is). `textScale` is the text size option (ui.set_text_scale) and `uiScale` the interface scale (ui.set_scale); every rect already includes both. `tooltip` is the tooltip on screen now ({title, lines, rect, source, widget}, rect in pixels) or null (docs/MENUS.md, "Tooltips"). Example: ui.state {}

## `ui.stop_speaking` (modifies state)

Since 0.2.0.

Stop what is being said by ui.speak and drop the queued lines.

The same as `ui.stopSpeaking()` in a script. Does nothing when nothing is being said or the system has no speech. Example: ui.stop_speaking {}

