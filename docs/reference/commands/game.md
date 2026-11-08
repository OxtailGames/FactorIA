[Back to the index](../README.md)

# Commands: game

## `game.click` (modifies state)

Since 0.4.0.

Click the game like a player: move the mouse, press, release; scripts see pressed/released and UI widgets get the click.

Give one target: `id` (a UI widget, an Interactable or a screen-space Text: its centre is clicked), `position` ([x, y] in design pixels, top-left origin, +Y down) or `world` ([x, y] or [x, y, z] in world units, projected through the main camera). It moves the mouse, presses `button` (left by default) and steps 1 frame (scripts read input.mouse.pressed in it, a Button gets its press), keeps the button down for `hold` frames in all (default 1), then releases and steps 1 more frame (input.mouse.released, the ui "click" event). The same sequence as game.click in a test, so it runs hold + 1 frames. A widget that cannot be clicked (inactive, no area, scrolled out of its ScrollList, a world-space Interactable that no camera shows where a player can reach it) is an error that says why and how to fix it; a click at a position or world point reaches only what the camera there draws. A page shown on a mesh: a camera with Camera.renderTarget draws world-space Interactables into a texture and a MeshRenderer shows it (texture "target:<name>"). A `position` over that mesh reaches the widget under it through the mesh's UVs, exactly like the real mouse, and `widget` is that widget. `id` of a widget that only such a page shows (the main camera hides it with hideTags, or it is far off screen) is aimed backwards: a point of its hit area in the target camera's view, the matching point of the mesh, its place on the screen; the command uses the first point where the pointer really reaches this widget (a mesh or widget in front is skipped) and, when there is none, says why (no mesh shows the target, the widget is outside the camera's view, the mesh is off screen or covered, a target shown inside another target is not reachable). game.input {"mouse":{"position":[x,y],"left":true}} only sets the state for the next frame and leaves the button held; a click is move + press + frame + release + frame, which this command does in one call. Returns {position, button, frames, widget, via?, frame}: `widget` is the id of the topmost UI widget or Interactable the pointer reached when the button went down (null over the world; the widget a click removes or changes in that frame is still named); `via` is {mesh, target} - the entity of the MeshRenderer and of the Camera.renderTarget camera whose page the click went through - present only when it went through a page and no screen widget was on top. Examples: game.click {"id":"play"}, game.click {"position":[640,360]}, game.click {"world":[3,-2],"button":"right"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | no | Entity id (or name) of a UI widget, an Interactable (also in world space, also one that only a render-target page shows: it is clicked through the mesh) or a screen-space Text; its centre is clicked. |
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

## `game.state_hash`

Not released yet (on main after 0.18.0).

One 64-bit hash of the whole simulation state: every entity, component and field, the clock and the random generator.

Two runs that simulate the same thing give the same hash; any difference (a float off in its last bit, an extra entity, another random number drawn) changes it. Use it to check determinism: the same game with runtime.jobThreads 0, 1 or 8 (or FA_JOB_THREADS=inline) must give the same hash at the same frame, and so must a replay. Runtime-only fields (velocities, timers) are included unless includeRuntime is false. perEntity lists one hash per entity (creation order) to find which entity differs. Example: game.state_hash {"perEntity":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `perEntity` | boolean | no | Also list one hash per entity, in creation order (at most maxEntities). Default false. |
| `includeRuntime` | boolean | no | Hash the fields that are not saved to scenes too (velocities, timers). Default true. |
| `maxEntities` | integer | no | How many entities perEntity lists. Default 200. |

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

Lists the 2D visuals (Sprite, Shape2D, Text, Tilemap, UI widgets) whose drawn box covers `position` (design pixels, origin top-left), topmost first: screen-space UI above the world, then the higher `layer`, then (world Sprites) the lower world y, then the one drawn later (component order Tilemap, Sprite, Shape2D, Text; then creation order). Each hit is {entity, name, component, layer, space: "world"|"screen"}. Use it to find which shape or sprite causes a visible artefact (a seam, a dark band) after game.screenshot {region, zoom} or render.inspect located it. The test is the oriented BOX of the visual (the same footprint as entity.bounds() and the editor's picking): a transparent corner of a sprite, the corners outside a circle and the parts of a gradient that fade out still count; an alpha-0 colour is skipped; inactive entities are skipped, and so are world visuals the camera at that pixel does not draw (Camera.showTags / hideTags). The world point is found through the primary camera; `world` in the result is that point. `widget` is the widget a click there would reach, through the same path the mouse takes: a screen widget, else a world-space Interactable, and over a mesh that shows a render target (Camera.renderTarget) the Interactable of that page under the point, or null. `via` ({mesh, target}: the MeshRenderer entity and the target camera's) is present when the point is over such a mesh (`hits` still lists what the main camera draws there: the mesh, not the page behind it). Needs graphics (the camera is the renderer's). Example: render.pick {"position":[640,360]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `position` | array | yes | [x, y] in design pixels (origin top-left). |
| `max` | integer | no | At most this many hits. Default 20. |

## `vfx.budget`

Since 0.17.0.

What an effect document costs on a phone: live particles and the screen they cover, with the fixes.

Plays the document in a scratch world with the same timeline and particle sim a game runs (no renderer, no sound, the game is not touched, the same document and seed always give the same numbers) and returns {peakParticles, peakAt, peakOverdraw, peakOverdrawAt, meanOverdraw, settledAt, perEmitter: [{part, name, peakParticles, peakAt, peakOverdraw, maxParticles, capped}], timeline: [{t, particles, overdraw}], findings: [{kind, pointer, message, hint, fix: {command, args}}], notes, limits, ok}. `overdraw` is the sum of the particles' quads in screens (1.0 = as much quad area as the view has; stacked soft sprites are what a phone's GPU pays for). `findings` are what is over the `preset`'s budget (phone: 300 live particles, 1.5 screens, 5 emitters; desktop: 2000, 4.0, 8): each names the JSON pointer and, when one edit helps, carries a vfx.edit call (`fix`) that moves the effect toward it (run vfx.budget again to see where it lands; `fix` is null when no single edit would do). With 3D emitters the numbers also depend on that camera (its lens, and the scene that is loaded), so the same document can give other numbers in another scene. The numbers are the particles the sim keeps alive: a camera that does not see them, ribbon trails and glow passes are not counted. A 3D emitter's size is in world units, so its overdraw is measured through the project's main camera (the active primary Camera with the lowest depth in the loaded scene): its quads are projected with the effect 5 m in front of the camera, on its axis (a perspective or an orthographic camera; a quad partly outside the view counts whole). `camera` in the result says which was used ({used:true, projection, distance, fov | height}); when there is no camera (no scene loaded, or none in it) a 3D emitter's particles are counted but its overdraw is 0 and not measured, and `camera` is {used:false, reason} and `notes` says so. Example: vfx.budget {"path":"assets/vfx/hit.vfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json". |
| `preset` | string ["phone","desktop"] | no | Whose budget the findings use. Default "phone". |
| `seed` | integer | no | Seed of the particle sim: a different seed is a different (equally valid) roll of the random spread. Default 1. |
| `view` | array | no | [width, height] of the view in design pixels that overdraw is measured against. Default: the project's design size. |

## `vfx.check`

Since 0.17.0.

Read an effect document (*.vfx.json) and list every problem, with its JSON pointer and the fix.

Returns {ok, path, duration, parts: [{index, name, type, at, duration}], errors: [{pointer, message, hint}], warnings: [...]}. Errors stop the effect from playing; warnings (a `rate` with no duration, too many live particles) do not. A sound whose file is missing is an error. Example: vfx.check {"path":"assets/vfx/hit.vfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json". |

## `vfx.filmstrip` (modifies state)

Since 0.17.0.

Film an effect playing in the game: one picture with a grid of frames, to see its timing and look at once.

Plays the effect at `position` (default: in a 2D game the world point in the middle of the view; in a 3D game the point 5 m in front of the main 3D camera, on its axis, which the result says in `positionNote`), steps the game and captures `region` at each step into one labelled grid PNG (label "f3 +100" = picture 3, 100 ms after the effect started), then removes the effect. THE GAME ADVANCES: the clock, the physics and the scripts run for the frames the strip takes (about 3 s at most by default), so film on a stage scene or a paused moment; the camera and the backdrop are the ones the game has, which is what the effect must read against. The first picture is the frame after the effect started. By default the strip covers the effect's length (from vfx.budget, at most 3 s) in `frames` pictures; `everyFrames` sets the game frames between two pictures instead. The view is `size` design pixels around the effect, `region` [x, y, width, height] overrides it, and `zoom` magnifies (default: a sheet about 1600 px wide). At most 64 pictures, a sheet at most 8192 px a side. Needs graphics. Without `path` the picture is temporary (the MCP server shows it then deletes the file). The effect's sound and command parts really act on the game (a feel.hitStop stretches the labelled times, an audio.music keeps playing, a feel.spawn leaves its prefab). A `position` the camera cannot project into the view fails (it is behind the camera: aim the camera or give `region`). Result: {path (only with `path`), effect, duration, width, height, frames: [{index, frame, t}], columns, rows, tileWidth, tileHeight, zoom, everyFrames, region, position: [x, y, z] (where it played), positionDefault (true when `position` was left out), positionNote (only then: which default was used), $image}. vfx.review gives the picture to a vision model with the budget numbers. Example: vfx.filmstrip {"effect":"assets/vfx/hit.vfx.json","position":[640,360],"frames":12}

| Argument | Type | Required | Description |
|---|---|---|---|
| `effect` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json". |
| `position` | array | no | [x, y] or [x, y, z]: where the effect plays, in world units. Default: the world point in the middle of the view in a 2D game; in a 3D game the point 5 m in front of the main camera on its axis (the result says which in `positionNote`). |
| `frames` | integer | no | Pictures in the strip. Default 12. |
| `everyFrames` | integer | no | Game frames between two pictures. Default: the effect's length (at most 3 s) divided over `frames`. |
| `size` | number | no | Side, in design pixels, of the square around the effect that is filmed (ignored with `region`). Default 256. |
| `region` | array | no | [x, y, width, height] in design pixels (origin top-left of the view). |
| `zoom` | number | no | Magnification of the region (default: a sheet about 1600 px wide). |
| `columns` | integer | no | Pictures per row (default: nearly square). |
| `path` | string | no | Keep the PNG here (project-relative or absolute). |

## `vfx.list`

Since 0.17.0.

The effects that play now, and the limits of an effect.

Returns {playing: [{id, effect, time, duration, loop, speed}], count, max, limits}. `time` is seconds into the effect (the document's own clock), `duration` its length. An effect started by vfx.play counts at once, before the next step (time 0). Use it in a test to see that an effect started and ended: game.step, then vfx.list. Example: vfx.list {}.

## `vfx.play` (modifies state)

Since 0.17.0.

Play an effect document (*.vfx.json) at a position, or on an entity.

Makes an entity with a Vfx component (autoDestroy on) that plays the effect: its emitters and light flash become children of it, its sounds and commands (a camera shake, a hit-stop...) fire at their times. Without `entity` the effect is in world space at `position`; with `entity` it is that entity's child at the local `position`, so it follows it. The file is read and checked now: an invalid one is an error naming the JSON pointer. At most 64 effects play at once (an ended effect counts until its emitters' particles are gone): past that the call returns {"id": null, "dropped": true} (logged once). The effect advances with the game clock (game.step, time.scale), so the same calls at the same steps give the same result. Example: vfx.play {"effect":"assets/vfx/hit.vfx.json","position":[120,64]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `effect` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json" (docs/PARTICLES.md, "Effect documents"). |
| `position` | array | no | [x, y] or [x, y, z]: world position, or relative to `entity` when that is given. Default [0, 0]. |
| `entity` | string | no | Entity (id or name) the effect follows: it becomes the effect's parent. |
| `rotation` | number | no | Degrees around z (2D). Default 0. |
| `scale` | number | no | Makes the whole effect that many times larger: positions and offsets, the emission shape, how fast and how far particles fly (start speed, gravity, turbulence), the size of particles and trails and the light radius. Times (lifetimes, the timeline) stay as written, and a command part (feel.shake, ...) calls its command with the arguments written in the file. A sub-emitter given as a prefab or an entity keeps its own size. 1 = as written. Default 1. |
| `speed` | number | no | Speed of the timeline: 2 plays the parts' times twice as fast. The particles keep their own speed. Default 1. |
| `loop` | boolean | no | Start again at the end until vfx.stop. Default false. |

## `vfx.review` (modifies state)

Since 0.17.0.

A cheap one-shot vision review of an effect: its filmstrip graded for readability, timing, palette and overdraw, with vfx.edit fixes.

The last look of the make, film, grade, fix loop for effects (docs/PARTICLES.md "Reviewing an effect"). It runs vfx.budget on the document and vfx.filmstrip on the running game (so THE GAME ADVANCES by about the length of the effect, at most 3 s, and the game must have graphics), then sends a vision model the filmstrip, the budget numbers and the document with a checklist: readability at game size, timing, palette, overdraw. It uses the model of the "fast" role of ai.json (the orchestrator when fast is off), so the model must accept pictures; with no provider, no key or a text-only model the error says what to set up (docs/AI_PROVIDERS.md) and you carry on with vfx.budget and vfx.filmstrip, which you can read yourself. One model call per review: call it once vfx.check passes and vfx.budget has no finding, not after every edit. Result: {verdict: good | fix | redo (never `good` while vfx.budget has a finding), summary, checklist: [{item, grade, note}], fixes: [{what, where, command}], budget: {peakParticles, peakOverdraw, findings, ...}, filmstrip: {frames, columns, rows, tileWidth, tileHeight, zoom, region, position (where it was filmed), positionDefault, positionNote}, role, provider, model, warnings, nextSteps}. A fix names a command, usually a vfx.edit call; one that names something this engine does not have is listed in `warnings`. The document is not changed. Pass `picturePath` to keep the filmstrip PNG. Example: {"effect":"assets/vfx/hit.vfx.json","position":[640,360],"focus":"does it read on the dark floor?"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `effect` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json". |
| `position` | array | no | [x, y] or [x, y, z]: where in the game the effect is filmed, in world units (as vfx.filmstrip). Default: the middle of the view in a 2D game, the point 5 m in front of the main camera in a 3D game (`filmstrip.position` and `filmstrip.positionNote` say which). |
| `preset` | string ["phone","desktop"] | no | Whose budget the review uses (as vfx.budget). Default phone. |
| `frames` | integer | no | Pictures in the filmstrip (as vfx.filmstrip). Default 12. |
| `focus` | string | no | What you want judged ("does it read on the dark floor?", "is the hit too long?"). Optional. |
| `picturePath` | string | no | Keep the filmstrip PNG here (project-relative or absolute). Without it the picture is deleted after the review. |

## `vfx.stop` (modifies state)

Since 0.17.0.

End an effect started by vfx.play (or a Vfx entity).

`immediate` true removes the effect's entity and its children at once (particles vanish); the default lets the emitters stop emitting and their particles finish, ends the lights, and the parts that had not started never do. Example: vfx.stop {"id":"vfx_hit_3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The entity (id or name) with the Vfx, as vfx.play returned it. |
| `immediate` | boolean | no | Remove it now instead of letting its particles finish. Default false. |

