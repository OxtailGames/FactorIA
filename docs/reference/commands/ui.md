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

## `ui.clear_captions` (modifies state)

Since 0.2.0.

Remove every subtitle from the screen now.

The same as `ui.clearCaptions()` in a script. Sounds that have a caption keep playing. Example: ui.clear_captions {}

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

Returns {focused, hovered, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed, interactable, visible, value?, text?}]} in reading order (top to bottom, then left to right). Only widgets that are active in the hierarchy are listed. rect is in design pixels, top-left origin, +Y down: click a widget with game.input {"mouse": {"position": [x, y], "left": true}} or move the focus with the ui_up / ui_down / ui_left / ui_right and ui_submit actions (game.input {"press": ["ui_down"]}). `visible` is false when a ScrollList clips the widget away entirely, and for an on-screen gamepad control that is hidden (touchOnly while the player is not using touch). `value` is a Toggle's boolean, a Slider's number or a TouchStick's [x, y]; `pressed` of a TouchStick or TouchButton is a finger holding it (drive one with game.input {"touch": ...}); `text` is a Button's or TouchButton's text, a Toggle's or Slider's label or a TextField's contents. Screen-space Text entities (space "screen") follow the widgets as {id, kind: "Text", rect, text} (they are never focused or pressed; use it to check where HUD text is). `textScale` is the text size option (ui.set_text_scale). Example: ui.state {}

## `ui.stop_speaking` (modifies state)

Since 0.2.0.

Stop what is being said by ui.speak and drop the queued lines.

The same as `ui.stopSpeaking()` in a script. Does nothing when nothing is being said or the system has no speech. Example: ui.stop_speaking {}

