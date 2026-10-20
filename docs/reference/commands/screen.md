[Back to the index](../README.md)

# Commands: screen

## `screen.set_safe_area` (modifies state)

Not released yet (on main after 0.1.6).

Pretend the device has a notch, rounded corners or system bars (a notched phone, headless).

The safe area is the part of the screen a notch, rounded corners and the system bars of a phone leave free; items with `safeArea: true` are anchored to it and screen.safeArea in scripts reports it. A real phone reports it by itself; a headless run, a test or the editor has none (the whole screen), so this sets one to check a layout: either a `profile` ("phone-portrait": notch at the top and home indicator at the bottom; "phone-landscape": notch on a side; "none"), as fractions of the design size, or insets in design pixels from each edge (`left`, `top`, `right`, `bottom`, default 0). Take a game.step and a game.screenshot to see the result. A windowed run on a phone overwrites it every frame with the device's real value. Example: screen.set_safe_area {"profile":"phone-portrait"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `profile` | string | no | none, phone-portrait or phone-landscape. Replaces left/top/right/bottom. |
| `left` | number | no | Design pixels covered at the left edge. Default 0. |
| `top` | number | no | Design pixels covered at the top edge. Default 0. |
| `right` | number | no | Design pixels covered at the right edge. Default 0. |
| `bottom` | number | no | Design pixels covered at the bottom edge. Default 0. |

