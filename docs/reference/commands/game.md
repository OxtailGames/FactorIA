[Back to the index](../README.md)

# Commands: game

## `game.input` (modifies state)

Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.

Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. Forms: {"action":"jump","down":true}, {"key":"Space","down":false}, {"press":["jump"],"release":["fire"]}, {"mouse":{"position":[640,360]}}, {"gamepad":{"index":0,"buttons":{"A":true},"axes":{"LeftX":-1}}}, {"touch":{"id":1,"position":[200,300],"down":true}}. gamepad: index 0..3 (default 0), connected (bool), buttons {A, B, X, Y, Start, Back, Guide, DpadLeft/Right/Up/Down, LeftShoulder, RightShoulder, LeftThumb, RightThumb: bool}, axes {LeftX, LeftY, RightX, RightY: -1..1 with +Y up; LeftTrigger, RightTrigger: 0..1}; the state stays until set again (axes back to 0 to release the stick). touch: id (default 1), position in design pixels, down (default true: a new id begins, a known id moves; false lifts); the first finger also drives the mouse like a device. gamepad and touch also take an array for several pads/fingers. {"back":true} presses the system Back button of Android: the input.onBack handlers of the game run at the next frame, and when none consumes it the game asks to quit (game.state shows quitRequested). The input is applied now and seen by the next frame (game.step). Example: game.input {"press":["jump"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string | no | Action name (with `down`). |
| `key` | string | no | Key or mouse button name (with `down`). |
| `down` | boolean | no | New state for action/key. Default true. |
| `press` | array | no |  |
| `release` | array | no |  |
| `mouse` | object | no | {position:[x,y] in design pixels, left/right/middle: bool}. |
| `gamepad` | any | no | {index?: 0..3, connected?: bool, buttons?: {A: true, DpadLeft: false...}, axes?: {LeftX: -1, RightTrigger: 0.5...}}, or an array of those for several pads. |
| `touch` | any | no | {id?: number (default 1), position?: [x,y] design pixels, down?: bool (default true)}, or an array of those for several fingers. |
| `back` | boolean | no | true: press the system Back button (Android). |

## `game.logs`

Read recent log lines (engine, scripts, assets...).

Use `after` (a seq from a previous call) to fetch only new lines. Example: game.logs {"minLevel":"warn","max":50}

| Argument | Type | Required | Description |
|---|---|---|---|
| `minLevel` | string ["trace","debug","info","warn","error"] | no |  Default "info". |
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `max` | integer | no |  Default 100. |

## `game.pause` (modifies state)

Pause the simulation (frame() stops simulating; game.step still works).

Example: game.pause {}

## `game.render_stats`

Since 0.3.0.

What the renderer drew in the picture now: draw calls, triangles, lights, shadow casters, texture memory.

Draws a frame first when none was drawn since the last change (a headless run or an on-demand render may not have drawn one yet), then returns {drawCalls, sprites, shapes, textGlyphs, particles, meshes, meshesCulled, meshBatches, triangles, views, shadowCasters, lights, lightsDropped, lights2d, lights2dDropped, lights2dShadowed, materials, materialFallbacks, textureMB, width, height, renderScale}. lights and lightsDropped count the 3D lights of the main pass (at most 32); lights2d and lights2dDropped count the Light2D lights (at most 256: the ones that reach the camera view are kept first), lights2dShadowed those with a shadow (castShadows, at most 32). views counts the CameraViews drawn. width and height are the size of the picture in pixels (design size * window.renderScale). Same as game.renderStats() in tests. Needs graphics. Example: game.render_stats {}

## `game.resume` (modifies state)

Resume the simulation after game.pause.

Example: game.resume {}

## `game.screenshot`

Capture the game view as a PNG and show it.

Draws the game view as it is now (design resolution), saves it and returns the path; clients display the image. Scripts only run when frames are stepped: step the game first so the picture shows what you expect. Default path .factoria/screenshots/frame_<n>.png. `scale` (0.25 to 4, default 1) draws the same frame into an image scale times larger, sharp and not upscaled, for store screenshots: HUD, camera and visible area stay the same, so a 1280x720 game at scale 1.5 gives a 1920x1080 PNG. `simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the saved PNG to what a colour-blind viewer sees (Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in linear light; greyscale = Rec. 709 luminance) without changing what the player sees: use it to check that hazards, pickups and buttons read without their colour. Example: game.screenshot {"path":"shots/start.png","scale":1.5} or game.screenshot {"path":"shots/deut.png","simulate":"deuteranopia"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Output PNG (project-relative or absolute). |
| `scale` | number | no | Render scale: image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080. Default 1. |
| `simulate` | string ["none","greyscale","protanopia","deuteranopia","tritanopia"] | no | Convert the saved PNG to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged. Default "none". |

## `game.state`

Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.

Filters: entities (ids), components (names to include), includeDefaults, maxEntities (default 200). Example: game.state {"entities":["player"],"components":["Transform","RigidBody2D"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entities` | array | no | Only these entity ids. |
| `components` | array | no | Only these components per entity. |
| `includeDefaults` | boolean | no |  Default false. |
| `maxEntities` | integer | no |  Default 200. |

## `game.step` (modifies state)

Advance the simulation by N fixed frames (deterministic) and return a state summary.

Each frame is exactly 1/fixedHz seconds. `press` holds actions/keys down and `release` lets go; they are applied BEFORE the first frame and stay in effect (a press without release stays held). To tap a button use game.step {"frames":1,"press":["jump"]} then game.step {"frames":1,"release":["jump"]}. Works while paused. Example: game.step {"frames":60,"press":["move_right"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | Number of frames. Default 1. |
| `press` | array | no | Actions/keys to press first. |
| `release` | array | no | Actions/keys to release first. |

## `input.record` (modifies state)

Since 0.3.0.

Record the input the game receives as an input replay (start / stop).

`start` begins recording every key, mouse, touch, gamepad and Back event the game receives (from a window, a test, game.input or a replay), the dt and fixed steps of each frame, the clipboard reads, the answers of http.fetch and the calendar date; what is held at that moment (keys, buttons, pads) is part of it. `stop` ends it and returns the replay in `replay`: the JSON that `factoria run --headless --input <file>` plays (frame numbers count from the start; typed text, the mouse wheel and locked-mouse movement have no field in the format and are not recorded). `path` (with stop) also writes the replay to that project-relative file. A replay run from the same scene, seed and props reaches the same state. Start and stop between frames. Starting while recording begins again. Example: input.record {"action":"start"} ... input.record {"action":"stop","path":"replays/run1.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string ["start","stop"] | yes | start: begin recording now. stop: end it and return the replay. |
| `path` | string | no | stop only: also write the replay to this project-relative file (e.g. replays/run1.json). |

