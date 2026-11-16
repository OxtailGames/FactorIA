# Mobile: Android and iOS, page 4 of 4

Part of [Mobile: Android and iOS](../MOBILE.md) (the entry page lists every page).

## Touch input

The platform layer maps touches to the same `Input` object scripts use:

- every finger is a touch (`Input::touches()`; begin/move/end) in design coordinates;
- the first finger also drives the mouse: position plus `MouseLeft` down/up, so
  UI and scripts written for the mouse work unchanged (this is done by `Input` itself, so `game.touch` in tests and
  any other feed behave the same);
- input actions bound to `"Touch"` or `"MouseLeft"` in `factoria.json` fire on touch;
- an optional on-screen gamepad (`TouchStick`, `TouchButton`) plays a game written for a pad, see "On-screen gamepad"
  below. The on-screen keyboard, the Back button, the notch and vibration are in "Phone features" below.
- Physical gamepads: iOS (and macOS) read them through the GameController framework (extended gamepads: MFi, Xbox,
  PlayStation, Switch Pro). The framework names the buttons by position, like the engine (`A` is the bottom one). A pad
  keeps its slot while connected, an unplugged pad frees it (logged as `gamepad: pad 0 connected: Controller (Xbox
  One)`). Run on macOS with an Xbox Wireless Controller over Bluetooth (every button, both sticks with +Y up, triggers
  0..1, unplug and plug back); on iOS it is the same code, built and run but not yet with a real pad. The iOS Simulator
  shows a virtual pad of its own (`Gamepad (MFi)`) in slot 0. Pads in a browser are in "Web" below. Bindings such as `"GamepadA"` are
  accepted everywhere.
- Android gamepads (Bluetooth or USB pads that Android itself supports: Xbox, DualShock/DualSense, Switch Pro, most
  generic ones) come from the NativeActivity input queue: the button keys (`AKEYCODE_BUTTON_A`..`MODE`, the D-pad
  keys), and the joystick axes (left stick X/Y, right stick Z/RZ or RX/RY, triggers `LTRIGGER`/`RTRIGGER` or
  `BRAKE`/`GAS`, D-pad `HAT_X`/`HAT_Y`). Android's own key layouts already give pads the Xbox naming, so there is no
  mapping table; the face buttons are positional like everywhere (`GamepadA` is the bottom one). The engine takes
  these events through sokol_app's `sapp_desc.android.native_event_cb` hook (installed by `to_sapp_desc()`) and
  marks them handled, so pad buttons never act as Back or touches. System Back (the Back key or gesture) is a
  separate event, `input.onBack` (see "Phone features"). Pads fill slots 0..3 in the order they first send an event.
  The NDK has no device enumeration, so `gamepad_android.cpp` asks `android.view.InputDevice` through JNI when a pad is
  new, about every 2 s, and when the app is back after a pause. `getDevice(id)` returning null means the pad was
  unplugged: its slot is freed (the game sees it disconnect, the other pads keep their numbers, the next pad takes the
  free slot). `getMotionRange(axis)` says which axes a pad has: `Z`+`RZ` without `RX`+`RY` means the right stick is
  Z/RZ; with `RX`+`RY` too and no trigger axes (`LTRIGGER`/`RTRIGGER`/`BRAKE`/`GAS`) the right stick is RX/RY and Z/RZ
  are the triggers (-1 released .. +1 pulled); a pad with both pairs AND trigger axes, or not asked yet, uses whichever
  pair is further from rest. Limits: a pad with only Z/RZ and no trigger axes is taken to have its right stick there;
  an unplugged pad is noticed within about 2 s; without JNI it keeps its slot until a fifth pad needs one. Never run
  on a device: the decisions are unit tested on every OS, the JNI glue is only built by CI.
- Losing focus or backgrounding releases all inputs and fires `Suspended`/`Resumed`; pads that are still connected
  report their real state again afterwards.

### Device and pads

`game.device.handheld` is true on a phone or tablet (and on a Steam Deck); `game.on("gamepadConnected" | "gamepadDisconnected")`
reports Bluetooth pads on Android and iOS, with an id that is stable per pad (Android: the InputDevice descriptor). See
docs/SCRIPTING.md, "Pads plugged in and out".

### On-screen gamepad

A game that plays with a gamepad plays on a phone with two UI components and no change to its scripts. A `TouchStick` is
a disc with a knob that follows the finger; a `TouchButton` is a disc with an optional label. A finger on them moves a
stick or holds a button of the **touch pad**, a virtual pad the action bindings read like a real one: an action bound to
`"GamepadLeftStickRight"` gets the stick's push, one bound to `"GamepadA"` fires while the `A` button is held. The default
`ui_*` actions include the left stick and `GamepadA` / `GamepadB`, so the stick also walks menus.

```json
{ "id": "move", "components": { "Transform": { "position": [40, -40] },
    "TouchStick": { "anchor": [0, 1], "pivot": [0, 0], "size": [220, 220] } } },
{ "id": "jump", "components": { "Transform": { "position": [-40, -60] },
    "TouchButton": { "anchor": [1, 1], "pivot": [1, 0], "button": "A", "text": "A" } } },
{ "id": "dash", "components": { "Transform": { "position": [-160, -40] },
    "TouchButton": { "anchor": [1, 1], "pivot": [1, 0], "button": "B", "text": "B" } } }
```

with `"jump": ["Space", "GamepadA"]`, `"move_left": ["A", "GamepadLeftStickLeft"]`... in `factoria.json` `input.actions`.

- **Where**: they are UI widgets (screen space, `anchor`, `pivot`, `size`, `layer`, `color`, a `texture` instead of the
  disc), and `safeArea` is on by default, so the anchor is a corner of the safe area and the notch never covers them.
  A Panel can lay them out like any widget.
- **When**: with `touchOnly` (the default) they are drawn only while the player uses touch (`input.lastDevice` is
  `"touch"`; a phone starts that way), so they disappear when the player picks up a real pad or the keyboard and come back
  on the next touch. A finger landing on one always works. `touchOnly: false` draws them on any device: desktop previews,
  screenshots, tests. To judge the layout on a desktop without editing the scene, force the touch interface: `factoria run
  --touch` (windowed or `--headless`), the command `ui.force_touch {"enabled": true}` or `game.screenshot {"forceTouch": true}`.
  All three set one switch: the game behaves as if the last input were always a finger (`input.lastDevice` says `"touch"`,
  the controls and touch prompts are shown at once, no step needed) until `ui.force_touch {"enabled": false}`. (`game.screenshot
  {"forceTouch"}` sets it only for that picture and puts the previous setting back afterwards.) It sends no
  finger; drive the controls with `game.touch` as below.
- **Fingers**: each control takes the finger that lands on it and keeps it until it lifts, even when the finger slides
  off (the stick stays at full tilt in that direction). Several fingers work at once: move and jump together. A finger a
  control holds is the pad's: it is not in `input.touches`, does not fire `"Touch"` or move the mouse, so a game's own
  touch handling never sees it. When controls overlap, the one created later takes the finger.
- **Values**: the stick's edge (half its shorter side) is full tilt; the pad deadzone (`input.deadzone` in
  `factoria.json`, default 0.2) applies like on a real stick. The components show the state at run time: `value` and
  `pressed` on a `TouchStick`, `pressed` on a `TouchButton`, `shown` on both; `ui.state` lists them too.
- **What it is not**: the touch pad has no number (`input.gamepad(0)` and the numbered pad queries never see it) and does
  not make `input.lastDevice` `"gamepad"`, so button prompts stay on touch. A mouse click does not press the controls.
  The stick is fixed where it is drawn (no floating stick that appears under the thumb).

Test it headless like any touch: `game.touchStart("jump")`, `game.touchMove`, `game.touchEnd` (or the command
`game.input {"touch": ...}`) on the control's rectangle, then check the action (`input.vector("move_left", "move_right",
"move_down", "move_up")`). `game.touch`, `game.touchStart` and `game.click` take a widget id or an Entity in place of a
position and use the centre of its laid-out rectangle, safe area included; `ui.rectOf(id)` (or the `rect` of `ui.state`)
gives the rectangle itself. Controls anchored to the safe area move with it, so never tap fixed coordinates under a
notch. The rectangles follow `game.setSafeArea` / `screen.set_safe_area` one step later: take a `game.step(1)` after
changing the safe area and before reading a rectangle or touching a control.

### Tablets and the iPad: `display.scaleMode: "expand"`

A tablet is closer to 4:3 than a phone is (an iPad Pro 13-inch is 4:3, a 16:9 design on it shows black bars with the
default `"fit"`, about a quarter of the screen). Set `"display": { "scaleMode": "expand" }` in `factoria.json` to keep
the design's scale and show more world instead: the visible area grows on the long axis (a 1280 x 720 design on a 4:3
landscape screen becomes 1280 x 960), with no bars. The UI follows the grown
screen: widgets with `anchor` at an edge or corner (`[1, 0]`, `[0.5, 1]`) stay on the screen's edges, so a HUD anchored to
them fits any tablet, a phone and a window of any shape. A widget placed from the top-left corner with a large `position` is
not moved. The world a 2D camera shows grows on the long axis; with an `orthoSize` the design's height (its width, on a screen
taller than the design) stays fixed.
`"fit"` stays the right choice when the level is built to the exact frame (a puzzle board, pixel art that must not show
what is outside the room); the bars are then the price.

## Phone features

What a phone has that a desktop does not, in the scripts (`import { screen, input } from "factoria"`). Every call is a
safe no-op on desktop, and a headless run records it, so a game can be tested without a device.

### Notch and system bars: the safe area

`screen.safeArea` is the part of the screen a notch, rounded corners, the camera hole, the home indicator and the system bars
leave free, as a `Rect` in design pixels (y down). `screen.insets` is the same as four numbers (`left`, `top`, `right`,
`bottom`: how much each edge loses) and `screen.size` is the design size. On a phone they follow the device, also when it is
turned; on desktop and in a headless run the safe area is the whole screen.

The scene follows it without a line of script: set `safeArea: true` next to `anchor` on a `Sprite`, `Shape2D`, `Text`,
`ParticleEmitter` or a UI widget (`Button`, `Panel`, ...) and the anchor is a corner or an edge of the safe area instead of
the screen. A score in the top left corner (`anchor: [0, 0]`, `safeArea: true`) never hides under the notch; a background
(`safeArea: false`, the default) still fills the whole screen. Layouts, hit testing, drawing and the editor use the same rule.

- Android: the window insets of the decor view (system bars and display cutout; API 30+ `WindowInsets.getInsets`, older
  releases `getSystemWindowInset*` and the API 28 `DisplayCutout`). The game is full screen, so the bars only count when
  the user pulls them in. Read again about every 15 frames and on every resize and rotation.
- iOS: `UIView.safeAreaInsets` of the game view, the same way.
- A phone that reports nothing (an old Android) gets the whole screen.

To look at a layout without the phone, pretend to have a notch: `game.setSafeArea("phone-portrait")` (or
`"phone-landscape"`, `"none"`, or `{ top: 40, left: 10 }` in design pixels) in a script test, or the command
`screen.set_safe_area {"profile":"phone-portrait"}` followed by `game.step` and `game.screenshot`. The profiles are an iPhone
15 (393 x 852 points: 59 at the top and 34 at the bottom; turned, 59 on each side and 21 at the bottom) as fractions of the
design size. The test hook ends with each test.

### The Back button

Android's Back (the key or the gesture) reaches the game as `input.onBack(handler)`. The newest handler is asked first and
the first one that does not return `false` consumes Back (return `true`, or nothing); if none consumes it, the game
leaves, which is what Android would have done. Close the pause menu, go up one screen, and let the main menu return
`false`:

```js
const off = input.onBack(() => {
  if (!pauseMenu.visible) return false; // nothing to close here: ask the next handler, or leave
  pauseMenu.close();
  return true;
});
```

Handlers end with the scene, like `ui.on`; call the returned function to remove one earlier. In a test, `game.pressBack()`
sends it (the command `game.input {"back": true}` does the same). iOS and desktop have no Back button: nothing calls it.
The exported manifest sets `android:enableOnBackInvokedCallback="false"`: from Android 16 an app that targets API 36 gets
Back through the new predictive-back callback instead of a key event (and a `NativeActivity` would simply finish), and
this attribute asks for the key event, which is what the engine reads. The game therefore has no predictive-back
animation. Not tried on an Android 16 device or emulator.

### Vibration

`input.vibrate(seconds = 0.1)` buzzes the phone for up to 5 seconds. Android uses the `Vibrator` service (`VibrationEffect`
on API 26+), and the exported manifest always carries the `VIBRATE` permission (a normal permission: nothing to ask the
player). iOS cannot choose the length: up to 0.05 s is a light tap, up to 0.15 s a medium one, up to 0.3 s a heavy one,
and anything longer the system vibration (about half a second). Devices without a motor (tablets, iPads, the emulator)
do nothing. A headless run records the calls: `game.vibrations()` in a test returns the list of seconds asked for.

### The on-screen keyboard

A `TextField` with focus raises the keyboard by itself and hides it when it loses the focus; `input.showKeyboard(on)` does
it from a script. What is typed arrives in `input.text` (and Enter, Backspace as `keyPressed`).

The UI does this in its focus step, for every game: when a `TextField` gains the focus it asks for the keyboard
(`input.keyboardShown` becomes true and the window passes it on to the platform: iOS, Android, the web), and when the
focus goes to anything else, or nowhere, it asks to hide it. Only those changes count, so a script that hides the keyboard
with `input.showKeyboard(false)` while the field keeps the focus is not overruled. Desktop ignores the request. When the
last input was a **gamepad** (`input.lastDevice`) the phone keyboard stays down: that player gets the game's on-screen
keyboard instead ([MENUS.md](../MENUS.md), "On-screen keyboard (gamepad players)"). A test sees the request in
`input.keyboardShown`.

- iOS: sokol_app's hidden text field. Composed text (accents, dictation, swipe typing) arrives; a character outside the
  Basic Multilingual Plane (emoji) is dropped by sokol_app. Verified in the source only: the iOS keyboard was not run on a
  device for this change.
- Android: a `NativeActivity` has no text editor, so the keyboard is shown with `InputMethodManager` on the decor view
  (`showSoftInput`, `toggleSoftInput` as a fallback; the NativeActivity method sokol_app uses does nothing on many
  devices) and what is typed comes as key events, from which the engine asks Android for the character the key makes. That
  gives letters, digits, punctuation, Space, Enter and Backspace in the keyboard's layout, and accents through dead keys.
  Limits: a keyboard that composes words or emoji (predictive text, swipe, CJK input methods, emoji panels, voice typing)
  cannot send them to a `NativeActivity`, and some keyboards send nothing until a hardware-style key is pressed. A hardware
  keyboard works the same way (also on a tablet). Written against the NDK headers and checked for syntax only: it was not
  run on a device or in the emulator, and the calls are made from the game's thread instead of the Android UI thread, which
  works on the releases known to the author but is not guaranteed by Android.

## Web

A game also runs in a browser page: the player is compiled to WebAssembly with Emscripten and draws with WebGL 2
(`docs/design/BUILDING.md`, "Web"; repository only, not in the binary). `factoria export --platform web` writes the page and the files next to it (docs/EXPORTING.md):

| File | What it is |
|---|---|
| `index.html` | `platforms/web/shell.html` with the game's name and the two file sizes filled in: a loading screen with a progress bar, readable error messages (no WebGL 2, a download that failed, a game that does not start), the canvas filling the window |
| `factoria_player.js`, `factoria_player.wasm` | the player (`createFactoriaPlayer`, built with `-sMODULARIZE=1`) |
| `game.pak` | the game, the same pack `--release` writes on desktop; the page puts it at `/game.pak` of the player's file system and the player runs from it |

Nothing else is needed on the server: any static host works (itch.io, GitHub Pages, a plain folder behind `http`). The
player uses **no threads**, so the page needs no `SharedArrayBuffer` and no COOP/COEP headers. A page opened from
`file://` cannot download its files: serve the folder, or export one self-contained page (`--single-file`, below).

### Play on a phone

The quickest way to see the game on a phone is the editor's File > Play on Phone... (the same as the command
`project.serve_web {"lan": true}`; docs/EXPORTING.md, "Serving the web build"):

1. Press **Start**. The editor exports the web build (the first time takes a few seconds; the web player must be installed:
   `factoria setup players --platforms web`) and serves it on this computer's local network, on a random port, under a random
   token in the address.
2. Point the phone's camera at the **QR code** (drawn by the engine) and open the link, or type the address shown under it
   (**Copy address** copies it). With several network addresses the window has a menu to pick which one the code shows.
3. Change a script or an asset in the editor: the build is exported again and the phone's page reloads by itself. What the
   game logs on the phone (`console.log/warn/error` and uncaught errors) comes back to the editor's Console with category
   `phone`.

When the phone cannot open the address:

- **Same Wi-Fi.** The phone must be on the same Wi-Fi as this computer (or on this computer's hotspot). Mobile data cannot
  reach it. Open the address with **Open on this computer** first: if that works and the phone does not, it is the network.
- **Firewall.** The first time, Windows asks whether the program may talk on the network (tick *Private networks* and
  *Allow*) and macOS asks whether the application may accept incoming network connections (*Allow*). If you said no, allow it
  in Windows Security > Firewall & network protection > Allow an app through firewall, or System Settings > Network > Firewall.
- **Guest networks.** A guest Wi-Fi, a hotel or an office network often isolates devices from each other, so the phone cannot
  see the computer. Use a home network or a hotspot.
- **VPN.** A VPN on either device can hide the local network.

The page is plain `http`: the phone's browser may say "not secure", and a feature that needs a secure context is not
available in it (the log shows what the browser refused). The address stops working when you press **Stop**, close the
editor or switch project.

### One file: `--single-file`

`factoria export --platform web --single-file` writes ONE `.html` with the player, the wasm and the game inside, which runs
offline from a double click (`file://`). It is for small games and demos (default limit 64 MB; docs/EXPORTING.md, "One HTML
file"). A browser on a phone opens a local `.html` only in some cases, so use Play on a phone to test there.

- **Window**: the canvas follows the size of the browser window and `devicePixelRatio`; the design size of `factoria.json` is the
  design size as everywhere, and `display.scaleMode` decides how it fits (letterbox bars where the window has another shape).
  `display.fullscreen` is ignored at start (a browser lets a page go fullscreen only after a click or key press);
  `window.setFullscreen(true)` from a script takes effect on the next click or key press. `window.setSize` has no meaning in
  a page. The title is the page's.
- **Audio**: a browser keeps audio silent until the player clicks, touches or presses a key on the page. The player keeps
  trying to resume the audio context on every such event until it runs, so the first click or key press starts the sound.
  The log shows `audio: output device open` when the device is created and `audio: stream running` when it really plays.
- **Saves** (`storage`, anything the game writes in its save folder) live in the browser's **IndexedDB**, one database per
  game id (`/save/<game id>`), loaded before the game starts and copied back half a second after a write (several writes
  become one copy). The tab being hidden or closed raises `suspend` or `quit` (`visibilitychange`, `pagehide`) and the
  copy starts right after the handlers have run, so a `storage.set` made in one is kept (the browser can still drop a page
  before the copy ends). Each `storage` key is its own file in that folder. They belong to the site: they survive reloads and visits, they are lost when
  the player clears the site's data, and a private window keeps them only until it closes. `log.txt` and crash reports are
  not written: the log goes to the browser console (`console.log`, `console.warn` and `console.error` by level), which is
  where a player or a developer looks.
- **Gamepads**: the browser's Gamepad API. A pad shows up after one button press (browsers hide pads until then). Pads with
  the `standard` mapping (Xbox, PlayStation, Switch Pro, Steam Deck: every current browser maps them) work like on desktop,
  up to four; the family on the button prompts comes from the pad's name. A pad without that mapping is tried with the same
  numbering and logged. Run in Chrome with a pad's id and values faked; not yet with a physical pad.
- **Touch**: touch screens give touches as on a phone (`TouchStick`, `TouchButton` and the other touch features work);
  the mouse and the keyboard work as on desktop. `input.onBack` is not used (the browser has its own). On a touch
  device the on-screen keyboard is raised by a hidden `<input>` that takes the focus while a `TextField` has it (see
  "Typing text" in [TEXT.md](../TEXT.md#typing-text)); iOS Safari only shows a keyboard for a focus made inside a tap, so
  the player may need a second tap on the field. Not run on a phone or tablet browser yet. `input.vibrate` calls `navigator.vibrate`, which Android browsers honour and iOS Safari ignores.
- **Language**: the game starts in the first of `navigator.languages` it has, like the system language elsewhere.
- **Not available**: native plugins (a browser cannot `dlopen`; the engine says so in a warning, and platform services use no
  backend), starting other programs, crash reports, `factoria run --headless` style runs (use the desktop `factoria`), and
  multithreaded loading: textures and sounds load on the main thread, so a large game starts a little slower than on
  desktop. Box2D runs without SIMD, which gives the same simulation as the other platforms.
- **Memory**: the pack and the decoded assets live in the page's memory (the heap grows up to 2 GB). Keep browser games
  small; a phone browser may kill a tab that uses several hundred MB.

The run marker for a smoke test is the console line `player: 60 frames rendered`, the one the Android and iOS tests wait
for. `platforms/web/smoke.mjs` serves an export folder, opens it in a headless Chrome or Edge and waits for it.
