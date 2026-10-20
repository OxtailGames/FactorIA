[Back to the index](../README.md)

# Commands: ui

## `ui.set_text_scale` (modifies state)

Not released yet (on main after 0.1.6).

Set the text size option: screen-space Text and the labels of UI widgets get bigger or smaller.

The player's "text size" setting (accessibility), the same as `ui.textScale = value` in a script: the font size of every screen-space Text (space "screen") and of the labels of Button, Toggle, Slider and TextField is multiplied by `scale`, and so is what ui.measureText returns for them (space "screen", the default). World-space Text is part of the world and is not scaled, nor is its entity.bounds(). 1 is normal size; the range is 0.5 to 3. Wrapped text keeps its maxWidth and grows taller, and widgets keep their rectangles, so lay a menu out with room for the biggest size you offer. The engine does not save the option: the game stores it (storage) and sets it at start. Look at the result with game.screenshot. Example: ui.set_text_scale {"scale":1.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scale` | number | yes | Text size multiplier: 1 = normal, 1.5 = 50% bigger, 0.5 = half. |

## `ui.state`

Since 0.1.6.

List the UI widgets on screen (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, and screen-space Text) and which has focus.

Returns {focused, hovered, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed, interactable, visible, value?, text?}]} in reading order (top to bottom, then left to right). Only widgets that are active in the hierarchy are listed. rect is in design pixels, top-left origin, +Y down: click a widget with game.input {"mouse": {"position": [x, y], "left": true}} or move the focus with the ui_up / ui_down / ui_left / ui_right and ui_submit actions (game.input {"press": ["ui_down"]}). `visible` is false when a ScrollList clips the widget away entirely, and for an on-screen gamepad control that is hidden (touchOnly while the player is not using touch). `value` is a Toggle's boolean, a Slider's number or a TouchStick's [x, y]; `pressed` of a TouchStick or TouchButton is a finger holding it (drive one with game.input {"touch": ...}); `text` is a Button's or TouchButton's text, a Toggle's or Slider's label or a TextField's contents. Screen-space Text entities (space "screen") follow the widgets as {id, kind: "Text", rect, text} (they are never focused or pressed; use it to check where HUD text is). `textScale` is the text size option (ui.set_text_scale). Example: ui.state {}

