[Back to the index](../README.md)

# Commands: game

## `game.click` (modifies state)

Since 0.4.0.

Click the game like a player: move the mouse, press, release; scripts see pressed/released and UI widgets get the click.

Give one target: `id` (a UI widget, an Interactable or a screen-space Text: its centre is clicked), `position` ([x, y] in design pixels, top-left origin, +Y down) or `world` ([x, y] or [x, y, z] in world units, projected through the main camera). It moves the mouse, presses `button` (left by default) and steps 1 frame (scripts read input.mouse.pressed in it, a Button gets its press), keeps the button down for `hold` frames in all (default 1), then releases and steps 1 more frame (input.mouse.released, the ui "click" event). The same sequence as game.click in a test, so it runs hold + 1 frames. A widget that cannot be clicked (inactive, no area, scrolled out of its ScrollList, a world-space Interactable the camera does not draw because of Camera.showTags / hideTags) is an error that says why; a click at a position or world point reaches only what the camera there draws. game.input {"mouse":{"position":[x,y],"left":true}} only sets the state for the next frame and leaves the button held; a click is move + press + frame + release + frame, which this command does in one call. Returns {position, button, frames, widget, frame}: `widget` is the id of the topmost UI widget or Interactable under the click (null over the world). Examples: game.click {"id":"play"}, game.click {"position":[640,360]}, game.click {"world":[3,-2],"button":"right"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | no | Entity id (or name) of a UI widget, an Interactable (also in world space) or a screen-space Text; its centre is clicked. |
| `position` | array | no | Screen position [x, y] in design pixels (top-left origin, +Y down). |
| `world` | array | no | World position [x, y] or [x, y, z], projected through the main camera (needs a renderer). |
| `button` | string ["left","right","middle"] | no | Mouse button. Default "left". |
| `hold` | integer | no | Frames the button stays down before the release (1 = a tap). Default 1. |

## `game.input` (modifies state)

Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.

Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. Forms: {"action":"jump","down":true}, {"key":"Space","down":false}, {"press":["jump"],"release":["fire"]}, {"mouse":{"position":[640,360]}}, {"gamepad":{"index":0,"buttons":{"A":true},"axes":{"LeftX":-1}}}, {"touch":{"id":1,"position":[200,300],"down":true}}. gamepad: index 0..3 (default 0), connected (bool), buttons {A, B, X, Y, Start, Back, Guide, DpadLeft/Right/Up/Down, LeftShoulder, RightShoulder, LeftThumb, RightThumb: bool}, axes {LeftX, LeftY, RightX, RightY: -1..1 with +Y up; LeftTrigger, RightTrigger: 0..1}; the state stays until set again (axes back to 0 to release the stick). touch: id (default 1), position in design pixels, down (default true: a new id begins, a known id moves; false lifts); the first finger also drives the mouse like a device. gamepad and touch also take an array for several pads/fingers. {"back":true} presses the system Back button of Android: the input.onBack handlers of the game run at the next frame, and when none consumes it the game asks to quit (game.state shows quitRequested). The input is applied now and seen by the next frame: a button that goes up to down is `pressed` (and one that goes down to up `released`) exactly once there, whether that frame comes from game.step, the running game or the editor's Step button, and however many editor frames are drawn while the game is paused in between. `frames` (default 0, max 100000) steps that many frames right after applying the input, exactly like game.step (also while paused); the result then has `frames` and `frame` (the frame counter afterwards). A press stays held afterwards: release it with a later call. Example: game.input {"press":["jump"],"frames":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string | no | Action name (with `down`). |
| `key` | string | no | Key or mouse button name (with `down`). |
| `down` | boolean | no | New state for action/key. Default true. |
| `press` | array | no |  |
| `release` | array | no |  |
| `mouse` | object | no | Mouse state: position in design pixels and the buttons held. |
| `gamepad` | any | no | {index?: 0..3, connected?: bool, buttons?: {A: true, DpadLeft: false...}, axes?: {LeftX: -1, RightTrigger: 0.5...}}, or an array of those for several pads. |
| `touch` | any | no | {id?: number (default 1), position?: [x,y] design pixels, down?: bool (default true)}, or an array of those for several fingers. |
| `back` | boolean | no | true: press the system Back button (Android). |
| `frames` | integer | no | Frames to step after applying the input, like game.step (works while paused). Default 0. |

## `game.logs`

Read recent log lines (engine, scripts, assets...).

Each line has `wallTime`, the computer's local time when it was logged (ISO 8601 with offset). Use `after` (a seq from a previous call) to fetch only new lines. Example: game.logs {"minLevel":"warn","max":50}

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

Capture the game view as a PNG and show it: whole, a magnified region, or a filmstrip of frames.

Draws the game view as it is now (design resolution) and returns it; clients display the image. Scripts only run when frames are stepped: step the game first so the picture shows what you expect.
WITHOUT `path` the picture is temporary: the result is {width, height, frame, temporary: true, $image: {path, mimeType, temporary: true}}, the MCP server and the AI assistant attach the image to the message and then DELETE the file, so do not keep or read that path later. (`factoria call` only prints the result and leaves the file; the engine removes engine-named files `.factoria/screenshots/frame_<n>*.png` older than 3 days or beyond the newest 200 when a project opens.) WITH `path` the file is written there and kept, and the result has `path`. Use `path` when your client cannot show images (then open the file yourself) or when you want to compare pictures later.
`scale` (0.25 to 4, default 1) draws the same frame into an image scale times larger, sharp and not upscaled, for store screenshots: HUD, camera and visible area stay the same, so a 1280x720 game at scale 1.5 gives a 1920x1080 PNG.
`region` [x, y, width, height] (design pixels, origin top-left) with `zoom` (0.25 to 32) shows only that part magnified: use it to look at a seam, a join, a gradient end or a one-pixel gap that is invisible in the whole view. Up to zoom 4 the frame is drawn again at that render scale and cropped (lines, text and shapes are sharp, the HUD is included); above 4 the 4x picture is enlarged with nearest-neighbour sampling (hard pixel blocks, nothing blurred). The result is round(width * zoom) x round(height * zoom), at most 8192 px a side; the region is clamped to the view. `zoom` without `region` magnifies the whole view the same way.
`frames` makes a FILMSTRIP: one PNG with a grid of pictures, each labelled with its frame number ("f130 +4" = game frame 130, 4 frames after the start). The first picture is the game now, then the game is STEPPED `everyFrames` frames (default 1) and captured again until `frames` frames have passed, so frames 48 and everyFrames 4 give 13 tiles and leave the game 48 frames further. At most 64 tiles. `region` and `zoom` apply to every tile (the same region each time); without `zoom` the tiles are sized so the sheet is about 2048 px wide (never enlarged). `columns` sets the grid width (default: nearly square). Use it to see a whole transition or animation at once. A tween or script keeps running while it steps: it shows what the game does, it does not freeze anything. The result adds `tiles` [{frame, offset}], `columns`, `rows`, `tileWidth`, `tileHeight` and `zoom`.
`simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the picture to what a colour-blind viewer sees (Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in linear light; greyscale = Rec. 709 luminance) without changing what the player sees: use it to check that hazards, pickups and buttons read without their colour. Needs graphics. Examples: game.screenshot {"path":"shots/start.png","scale":1.5}; game.screenshot {"region":[600,0,80,720],"zoom":8}; game.screenshot {"frames":48,"everyFrames":4,"region":[400,200,480,300]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Output PNG (project-relative or absolute). Given: the file is kept. Omitted: a temporary picture that the client deletes after reading it. |
| `scale` | number | no | Render scale of the whole view (default 1): image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080. Not together with zoom. |
| `region` | array | no | [x, y, width, height] in design pixels (origin top-left): only this part of the view is captured, magnified by zoom. |
| `zoom` | number | no | Magnification of the region (or of the whole view): up to 4 a native sharp re-render, above 4 nearest-neighbour enlargement of the 4x picture. Default 1 (a filmstrip without zoom: sized to a sheet about 2048 px wide). |
| `frames` | integer | no | Filmstrip: the game advances this many frames in total, captured every everyFrames, into one labelled grid PNG. |
| `everyFrames` | integer | no | Filmstrip: frames between two pictures (default 1). frames / everyFrames + 1 pictures, at most 64. |
| `columns` | integer | no | Filmstrip: tiles per row (default: the grid closest to square). |
| `simulate` | string ["none","greyscale","protanopia","deuteranopia","tritanopia"] | no | Convert the picture to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged. Default "none". |

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

## `render.inspect`

Since 0.4.0.

Luminance profile of the current picture along a line, with the hard steps (seams, bands) in it.

Draws the picture as it is now and reads the pixels along the segment `from` -> `to` (design pixels, origin top-left): one sample per pixel along the longer axis, as a value 0..255 of the sRGB bytes (`channel`: luminance with Rec. 709 weights, or red, green, blue). It lists every STEP: a change of at least `threshold` (default 8 levels) within `window` samples (default 2), which is how a bright seam, a gap between two sprites or the edge of a gradient band shows in the numbers while the eye misses it. A smooth ramp has no steps; a staircase (Mach bands: two overlapping gradients) has one per riser. The edge of a sprite or a shape is a step too: find what draws it with render.pick at the step's `at`. Result: {from, to, channel, scale, count, samples: [values], min, max, steps: [{index, at: [x, y] (design pixels, the middle of the jump), width, from, to, delta}], stepCount, frame}; at most 200 steps and 4096 samples. `scale` (0.25 to 4, default 1) samples a render at that scale, so at 4 there are four samples per design pixel and a sub-pixel gap shows. Look at the area with game.screenshot {region, zoom} first, then measure it. Needs graphics. Example: render.inspect {"from":[600,360],"to":[680,360],"threshold":6}

| Argument | Type | Required | Description |
|---|---|---|---|
| `from` | array | yes | Start of the line, [x, y] in design pixels (origin top-left). |
| `to` | array | yes | End of the line, [x, y] in design pixels. |
| `threshold` | number | no | Smallest change (0..255) that counts as a step. Default 8. |
| `window` | integer | no | A step is a change of at least threshold within this many samples. Default 2. |
| `channel` | string ["luminance","red","green","blue"] | no | What to measure: Rec. 709 luminance or one colour channel of the sRGB bytes. Default "luminance". |
| `scale` | number | no | Render scale to sample at; higher finds finer gaps. Default 1. |

## `render.pick`

Since 0.4.0.

Which entities draw a design-space pixel of the picture, topmost first.

Lists the 2D visuals (Sprite, Shape2D, Text, Tilemap, UI widgets) whose drawn box covers `position` (design pixels, origin top-left), topmost first: screen-space UI above the world, then the higher `layer`, then (world Sprites) the lower world y, then the one drawn later (component order Tilemap, Sprite, Shape2D, Text; then creation order). Each hit is {entity, name, component, layer, space: "world"|"screen"}. Use it to find which shape or sprite causes a visible artefact (a seam, a dark band) after game.screenshot {region, zoom} or render.inspect located it. The test is the oriented BOX of the visual (the same footprint as entity.bounds() and the editor's picking): a transparent corner of a sprite, the corners outside a circle and the parts of a gradient that fade out still count; an alpha-0 colour is skipped; inactive entities are skipped, and so are world visuals the camera at that pixel does not draw (Camera.showTags / hideTags). The world point is found through the primary camera; `world` in the result is that point. `widget` is the UI widget a click there would reach (ui_widget_at), or null. Needs graphics (the camera is the renderer's). Example: render.pick {"position":[640,360]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `position` | array | yes | [x, y] in design pixels (origin top-left). |
| `max` | integer | no | At most this many hits. Default 20. |

