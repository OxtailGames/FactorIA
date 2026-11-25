[Back to the index](../README.md)

# Commands: game

## `compute.create_buffer` (modifies state)

Since 0.32.0.

Makes a GPU storage buffer shaped like one buffer of a compute material; returns its id.

Capabilities: read, state

A zero-filled buffer of `count` elements, each laid out like the element of the material's buffer `buffer` (its "buffers" entry: fields of float, vec2, vec3, vec4, int, uint). `initial` fills the first elements. The buffer lives until compute.destroy_buffer or the end of the game, whatever the scene (it is not part of one). Returns {id, count, stride, bytes}. Example: compute.create_buffer {"material":"materials/boids.material.json","buffer":"boids","count":1000,"initial":[{"pos":[0,0],"vel":[1,0]}]}

Limits: 64 live buffers, 256 MiB each, 1 GiB in all; over one is `invalid_argument` with the number it hit. Errors: `unavailable` on a backend without compute shaders (GLES3, WebGL2, macOS OpenGL 4.1: the message names the backend and what to do; ask render.supports computeShaders first) or without graphics; `invalid_argument` for a material that is not a compute material or does not build, an unknown buffer name (did you mean), and an `initial` value that does not fit a field (the message has its JSON pointer).

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the compute material, e.g. materials/boids.material.json. |
| `buffer` | string | yes | Name of one of the material's buffers (its "buffers" entry). |
| `count` | integer | yes | Number of elements (at most 256 MiB / the element stride). |
| `initial` | array | no | Optional {field: value} objects for the first elements (a vecN field is an array); fields left out are 0. |

## `compute.create_image` (modifies state)

Since 0.32.0.

Makes a GPU storage image a compute material writes and a material shows; returns its id.

Capabilities: read, state

A zero-filled 2D image shaped like one image of a compute material (its "images" entry: format rgba8, rgba16f, r32f or rgba32f). `width` and `height` default to the size the material declares. The image lives until compute.destroy_image or the end of the game, whatever the scene. Returns {id, material, image, format, access, width, height, bytes, textureId}: put `textureId` ("compute:<id>") in a Sprite.texture, MeshRenderer.texture or the texture param of a mesh, sprite or post material to show it (rgba8 and rgba16f filter everywhere; r32f and rgba32f may not on this GPU, then the checker shows and the log says why). Example: compute.create_image {"material":"materials/noise.material.json","image":"field","width":512,"height":512}

Limits: 32 live images, 8192 pixels a side (or what the GPU allows), 256 MiB each, 512 MiB in all; over one is `invalid_argument` with the number it hit. A format the backend cannot write as a storage image is refused with the formats that work. Errors: `unavailable` on a backend without compute shaders (GLES3, WebGL2, macOS OpenGL 4.1: the message names the backend and the CPU path) or without graphics.

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the compute material, e.g. materials/noise.material.json. |
| `image` | string | yes | Name of one of the material's images (its "images" entry). |
| `width` | integer | no | Width in pixels. Default: the material's size. |
| `height` | integer | no | Height in pixels. Default: the material's size. |

## `compute.destroy_buffer` (modifies state)

Since 0.32.0.

Frees a compute storage buffer.

Capabilities: read, state

Destroys the GPU buffer; its id is not used again. Returns {destroyed: id}. Example: compute.destroy_buffer {"buffer":1}

Errors: `invalid_argument` for an id that is not alive (compute.list_buffers lists the live ones).

| Argument | Type | Required | Description |
|---|---|---|---|
| `buffer` | integer | yes | Buffer id from compute.create_buffer. |

## `compute.destroy_image` (modifies state)

Since 0.32.0.

Frees a compute storage image.

Capabilities: read, state

Destroys the GPU image; its id is not used again and a material that still shows its textureId gets the checker (the log says why). Returns {destroyed: id}. Example: compute.destroy_image {"image":1}

Errors: `invalid_argument` for an id that is not alive (compute.list_images lists the live ones).

| Argument | Type | Required | Description |
|---|---|---|---|
| `image` | integer | yes | Image id from compute.create_image. |

## `compute.dispatch` (modifies state)

Since 0.32.0.

Runs a compute material once over its storage buffers.

Capabilities: read, state

`groups` counts WORKGROUPS of the material's workgroupSize threads each, not threads: ceil(work / workgroupSize.x) for a one-dimensional job. `buffers` gives a buffer id for every buffer of the material and `images` an image id for every storage image of it; `params` its param values and texture paths (like MeshRenderer.materialParams; what is left out keeps the material's default). The call returns when the work is recorded; compute.read_buffer and compute.read_image wait for it, and a draw of the same frame sees the image the dispatch wrote. Returns {dispatched: [x, y, z]}. Example: compute.dispatch {"material":"materials/boids.material.json","buffers":{"boids":1},"params":{"speed":2},"groups":[16,1,1]}

Each dimension of `groups` is 1 to 65535. A buffer or image must have been made for the same buffer or image of the same material (same layout or format), and one buffer or image cannot be bound twice. An image cannot also be one of the dispatch's texture params. Errors: `unavailable` without compute (see compute.create_buffer); `invalid_argument` for a missing or unknown buffer, image or param (did you mean), a value of the wrong type, or groups out of range.

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the compute material. |
| `buffers` | object | no | The material's buffer name -> buffer id from compute.create_buffer; every buffer of the material (omit it for a material with none). |
| `images` | object | no | The material's storage image name -> image id from compute.create_image; every image of the material (omit it for a material with none). |
| `params` | object | no | {param: number or array} and {texture: path}; left out keeps the material's default. |
| `groups` | array | no | Workgroups in x, y, z; a missing dimension is 1. Default [1,1,1]. |

## `compute.list_buffers`

Since 0.32.0.

Lists the live compute storage buffers and whether this backend runs compute.

Capabilities: read

Returns {available, status, buffers: [{id, material, buffer, count, stride, bytes}]}. `available` is the answer of render.supports computeShaders; when it is false `status` says which backend cannot and what to do, and `buffers` is empty. Example: compute.list_buffers {}

Without graphics (graphics=false) `available` is false too.

## `compute.list_images`

Since 0.32.0.

Lists the live compute storage images and whether this backend runs compute.

Capabilities: read

Returns {available, status, images: [{id, material, image, format, access, width, height, bytes, textureId}]}. `available` is the answer of render.supports computeShaders; when it is false `status` says which backend cannot and the CPU path to use instead, and `images` is empty. Example: compute.list_images {}

Without graphics (graphics=false) `available` is false too.

## `compute.read_buffer`

Since 0.32.0.

Reads elements of a compute storage buffer back to the game (waits for the GPU).

Capabilities: read

Submits the recorded GPU work, waits for it and returns `count` elements from `first` as an array of {field: value} objects: a vecN field is an array, floats have 7 significant digits, a NaN or infinity is null. A read back stalls the frame: do it for a result you need, not every frame. Example: compute.read_buffer {"buffer":1,"first":0,"count":10}

At most 1048576 elements in one call (read a large buffer in parts). Errors: `unavailable` without compute (see compute.create_buffer); `invalid_argument` for an unknown buffer id or a range outside the buffer.

| Argument | Type | Required | Description |
|---|---|---|---|
| `buffer` | integer | yes | Buffer id from compute.create_buffer. |
| `first` | integer | no | Index of the first element to read. Default 0. |
| `count` | integer | no | Number of elements to read. Default: from `first` to the end (at most 1048576 elements and 4194304 numbers per call: read bigger buffers in chunks with first/count). |

## `compute.read_image`

Since 0.32.0.

Reads pixels of a compute storage image back to the game (waits for the GPU).

Capabilities: read

Submits the recorded GPU work, waits for it and returns {x, y, width, height, format, channels, data}: `data` is a flat array, row by row from the top, pixel by pixel, `channels` numbers each (rgba8: integers 0..255; rgba16f and rgba32f: r, g, b, a floats; r32f: one float), floats with 7 significant digits, a NaN or infinity is null. A read back stalls the frame: do it for a result you need, not every frame. Example: compute.read_image {"image":1,"x":0,"y":0,"width":4,"height":4}

x and y default to 0, and width and height to the right and bottom edge; when both are left out of an image too large for one call, you get the top rows that fit (width from x to the right edge). At most 4194304 numbers in one call (read a large image in rectangles). Errors: `unavailable` without compute; `invalid_argument` for an id that is not alive or a rectangle outside the image.

| Argument | Type | Required | Description |
|---|---|---|---|
| `image` | integer | yes | Image id from compute.create_image. |
| `x` | integer | no | Left pixel of the rectangle. Default 0. |
| `y` | integer | no | Top pixel of the rectangle. Default 0. |
| `width` | integer | no | Width of the rectangle; 0 or left out = to the right edge. |
| `height` | integer | no | Height of the rectangle; 0 or left out = to the bottom edge. |

## `compute.resize_image` (modifies state)

Since 0.32.0.

Gives a compute storage image another size (its pixels are lost, its texture id stays).

Capabilities: read, state

Makes the image `width` x `height` and zero-fills it; `textureId` stays valid, so a Sprite or material that shows it follows the new size. Run the dispatch again to fill it. Returns the image as compute.list_images lists it. Example: compute.resize_image {"image":1,"width":1024,"height":1024}

Same limits as compute.create_image. Errors: `unavailable` without compute; `invalid_argument` for an id that is not alive or a size over a limit.

| Argument | Type | Required | Description |
|---|---|---|---|
| `image` | integer | yes | Image id from compute.create_image. |
| `width` | integer | yes | New width in pixels. |
| `height` | integer | yes | New height in pixels. |

## `compute.write_buffer` (modifies state)

Since 0.32.0.

Overwrites elements of a compute storage buffer with values from the game.

Capabilities: read, state

Writes `elements` ({field: value} objects) from element `first` on; a field left out is written as 0, the other elements stay as the GPU left them. Returns {written}. Example: compute.write_buffer {"buffer":1,"first":0,"elements":[{"pos":[0,0],"vel":[1,0]}]}

At most 1048576 elements in one call. Errors: `unavailable` without compute (see compute.create_buffer); `invalid_argument` for an unknown buffer id (compute.list_buffers), a range outside the buffer, or a value that does not fit its field (the message has its JSON pointer).

| Argument | Type | Required | Description |
|---|---|---|---|
| `buffer` | integer | yes | Buffer id from compute.create_buffer. |
| `first` | integer | no | Index of the first element to overwrite. Default 0. |
| `elements` | array | yes | {field: value} objects, one per element. |

## `game.click` (modifies state)

Since 0.4.0.

Click the game like a player: move the mouse, press, release; scripts see pressed/released and UI widgets get the click.

Capabilities: read, state

Give one target: `id` (a UI widget, an Interactable or a screen-space Text: its centre is clicked), `position` ([x, y] in design pixels, top-left origin, +Y down) or `world` ([x, y] or [x, y, z] in world units, projected through the main camera). It moves the mouse, presses `button` (left by default) and steps 1 frame (scripts read input.mouse.pressed in it, a Button gets its press), keeps the button down for `hold` frames in all (default 1), then releases and steps 1 more frame (input.mouse.released, the ui "click" event). The same sequence as game.click in a test, so it runs hold + 1 frames. A widget that cannot be clicked (inactive, no area, scrolled out of its ScrollList, a world-space Interactable that no camera shows where a player can reach it) is an error that says why and how to fix it; a click at a position or world point reaches only what the camera there draws. A page shown on a mesh: a camera with Camera.renderTarget draws world-space Interactables into a texture and a MeshRenderer shows it (texture "target:<name>"). Examples: game.click {"id":"play"}, game.click {"position":[640,360]}, game.click {"world":[3,-2],"button":"right"}

A `position` over that mesh reaches the widget under it through the mesh's UVs, exactly like the real mouse, and `widget` is that widget. `id` of a widget that only such a page shows (the main camera hides it with hideTags, or it is far off screen) is aimed backwards: a point of its hit area in the target camera's view, the matching point of the mesh, its place on the screen; the command uses the first point where the pointer really reaches this widget (a mesh or widget in front is skipped) and, when there is none, says why (no mesh shows the target, the widget is outside the camera's view, the mesh is off screen or covered, a target shown inside another target is not reachable). game.input {"mouse":{"position":[x,y],"left":true}} only sets the state for the next frame and leaves the button held; a click is move + press + frame + release + frame, which this command does in one call. Returns {position, button, frames, widget, via?, frame}: `widget` is the id of the topmost UI widget or Interactable the pointer reached when the button went down (null over the world; the widget a click removes or changes in that frame is still named); `via` is {mesh, target} - the entity of the MeshRenderer and of the Camera.renderTarget camera whose page the click went through - present only when it went through a page and no screen widget was on top.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | no | Entity id (or name) of a UI widget, an Interactable (also in world space, also one that only a render-target page shows: it is clicked through the mesh) or a screen-space Text; its centre is clicked. |
| `position` | array | no | Screen position [x, y] in design pixels (top-left origin, +Y down). |
| `world` | array | no | World position [x, y] or [x, y, z], projected through the main camera (needs a renderer). |
| `button` | string ["left","right","middle"] | no | Mouse button. Default "left". |
| `hold` | integer | no | Frames the button stays down before the release (1 = a tap). Default 1. |

## `game.input` (modifies state)

Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.

Capabilities: read, state

Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. Forms: {"action":"jump","down":true}, {"key":"Space","down":false}, {"press":["jump"],"release":["fire"]}, {"mouse":{"position":[640,360]}}, {"gamepad":{"index":0,"buttons":{"A":true},"axes":{"LeftX":-1}}}, {"touch":{"id":1,"position":[200,300],"down":true}}. gamepad: index 0..3 (default 0), connected (bool), buttons {A, B, X, Y, Start, Back, Guide, DpadLeft/Right/Up/Down, LeftShoulder, RightShoulder, LeftThumb, RightThumb: bool}, axes {LeftX, LeftY, RightX, RightY: -1..1 with +Y up; LeftTrigger, RightTrigger: 0..1}; the state stays until set again (axes back to 0 to release the stick). touch: id (default 1), position in design pixels, down (default true: a new id begins, a known id moves; false lifts); the first finger also drives the mouse like a device. gamepad and touch also take an array for several pads/fingers. Example: game.input {"press":["jump"],"frames":1}

{"back":true} presses the system Back button of Android: the input.onBack handlers of the game run at the next frame, and when none consumes it the game asks to quit (game.state shows quitRequested). The input is applied now and seen by the next frame: a button that goes up to down is `pressed` (and one that goes down to up `released`) exactly once there, whether that frame comes from game.step, the running game or the editor's Step button, and however many editor frames are drawn while the game is paused in between. `frames` (default 0, max 100000) steps that many frames right after applying the input, exactly like game.step (also while paused); the result then has `frames` and `frame` (the frame counter afterwards). A press stays held afterwards: release it with a later call.

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

Capabilities: read

Each line has `wallTime`, the computer's local time when it was logged (ISO 8601 with offset). Use `after` (a seq from a previous call) to fetch only new lines. Script `console.*` lines have category `script`; the warning of a frame over runtime.scriptFrameBudgetMs has category `script.budget`. Example: game.logs {"minLevel":"warn","max":50}

| Argument | Type | Required | Description |
|---|---|---|---|
| `minLevel` | string ["trace","debug","info","warn","error"] | no |  Default "info". |
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `max` | integer | no |  Default 100. |

## `game.pause` (modifies state)

Pause the simulation (frame() stops simulating; game.step still works).

Capabilities: read, state

Example: game.pause {}

## `game.render_stats`

Since 0.3.0.

What the renderer drew in the picture now: draw calls, triangles, lights, shadow casters, texture memory.

Capabilities: read

Draws a frame first when none was drawn since the last change (a headless run or an on-demand render may not have drawn one yet), then returns {drawCalls, sprites, shapes, textGlyphs, particles, meshes, meshesCulled, meshBatches, triangles, views, shadowCasters, lights, lightsDropped, lightsCulled, lightClusters, lightClusterEntries, lightClusterClipped, lightMaxPerCluster, decals, decalsDropped, decalClusterClipped, volumetricCameras, volumetricLights, volumetricLightsDropped, contactShadowLights, subsurfaceCameras, subsurfaceDraws, lights2d, lights2dDropped, lights2dShadowed, sceneCopies, materials, materialResolves, materialFallbacks, sortKeyFallbacks, textureMB, width, height, renderScale}. materialResolves is the 2D material lookups (one per material and params). sortKeyFallbacks counts, since the renderer started, the times the 3D scene of a frame (or of a capture of one entity) had more distinct meshes, textures or materials than a sort key holds, so its opaque meshes were sorted by the slower comparator (the picture is the same; 0 is normal; it is not reset each frame, it only grows). For the time of each pass see render.frame_graph.

lights and lightsDropped count the 3D lights of the main pass (at most 1024, 32 of them directional; lightsDropped are the ones over those limits, lightsCulled the local lights whose range is outside the view, lightClusters the clusters of the view, lightClusterEntries the light-list entries they hold, lightMaxPerCluster the longest list and lightClusterClipped the entries lost to the limits of 128 lights per cluster and 524288 entries per view: 0 is normal; decals the Decal components drawn, decalsDropped those left out (over 256 per view, or a texture that is unreadable or does not fit the atlas) and decalClusterClipped the decal-list entries lost to the 32 per cluster and 131072 per view: 0 is normal; volumetricCameras the cameras that drew the volumetric fog, volumetricLights the lights whose shafts they drew and volumetricLightsDropped the lights with Light.volumetric above 0 that the quality setting left out; contactShadowLights the lights whose contact-shadow ray (Light.contactShadowLength, SceneSettings.contactShadows) the meshes marched, counted once for each camera that drew them: 0 when no camera could make the depth prepass; subsurfaceCameras the cameras that scattered the light of MeshRenderer.subsurface and subsurfaceDraws the draw calls of the scattering meshes: 0 when no mesh scatters or the GPU cannot, see render.supports); lights2d and lights2dDropped count the Light2D lights (at most 256: the ones that reach the camera view are kept first), lights2dShadowed those with a shadow (castShadows, at most 256); sceneCopies the copies of the picture drawn so far that Water2D, DistortionZone2D and sprite materials that call fa_scene_color made (at most 8 per camera; 0 when nothing reads it). terrainTiles counts the Terrain tiles drawn in the main pass (after the level of detail and the culling) and terrainTriangles their triangles (also in triangles; tiles are not counted in meshes). lodCrossFades counts the meshes drawn in the main view as one level of a dithered LOD cross-fade, summed over the cameras (a fading entity counts two; probe and GI captures do not count; MeshRenderer.lodCrossFade, LodGroup.crossFade). hlodProxies counts the HLOD proxy meshes drawn in the main view, summed over the cameras (a LodGroup past its hlodThreshold draws its hlodProxy instead of its children; one fading out counts too; and the proxy of a streamed cell that is not loaded, StreamedWorld.hlodDistance). occluders (the Occluders rasterised), occlusionTests (the meshes tested against them) and meshesOccluded (the ones hidden behind them and left out of the main pass, also in meshesCulled) count the CPU occlusion culling of docs/BIG_WORLDS_LOD.md: 0 when no enabled Occluder is in the scene. impostors counts the cards (MeshRenderer.impostor beyond impostorDistance, docs/BIG_WORLDS_LOD.md) drawn in the main pass, 0 when none is. portalsVisited (the distinct open OcclusionPortals the camera's walk went through, summed over the cameras) and meshesCulledByArea (the meshes left out of the main pass because no chain of open portals leads from the camera's area to theirs, also in meshesCulled) count the area and portal culling: 0 when no enabled OcclusionArea is in the scene. foliageInstances counts the instances of Foliage drawn in the main pass (not in meshes) and foliageInstancesCulled the ones left out of the picture (outside the view, behind an Occluder, beyond fadeEnd, or past the 262144 a camera takes at once; one kept only for the shadow maps counts too): both 0 with no Foliage (docs/BIG_WORLDS_TERRAIN.md). views counts the CameraViews drawn. width and height are the size in pixels the game is drawn at (design size * window.renderScale * the upscaler quality's scale; the HUD and a screenshot are at the design size). Same as game.renderStats() in tests. Needs graphics. Example: game.render_stats {}

## `game.resume` (modifies state)

Resume the simulation after game.pause.

Capabilities: read, state

Example: game.resume {}

## `game.rumble` (modifies state)

Since 0.30.0.

Rumble a gamepad (the heavy and the light motor, 0..1, for some seconds), stop it, or just read what every pad does and whether it can rumble.

Capabilities: read, state

Give `low` (the heavy, low-frequency motor), `high` (the light, high-frequency one) and `seconds` (above 0, up to 10) to start the motors of pad `pad` (0..3, default 0); the same as input.rumble() in a script. `stop: true` stops the pad instead (without `pad`, every pad). With neither, nothing changes and the result only reports. The result lists every pad: connected, canRumble, reason (why it cannot, e.g. the pad has no motors the platform can drive), and the motors now (low, high, seconds left). Strengths outside 0..1 are clamped, and a request with both at 0 is a stop; a request for a pad that is not connected or cannot rumble is accepted and does nothing. The seconds run down with the frames' own duration (game.step), not scaled by time.scale; the engine stops every pad when the game pauses itself (time.scale 0), changes scene or quits.

Example: game.rumble {"pad":0,"low":0.6,"high":0.2,"seconds":0.3}, then game.rumble {"stop":true}. A headless run has no hardware: connect a test pad first (game.input {"gamepad":{"index":0,"connected":true}}) and read the motors in the result; real motors need a game running in its own window (`factoria run`, an export; the editor's Game view reads no physical pads): Windows pads (XInput, DualShock 4, DualSense, Switch Pro), Linux pads with kernel force feedback, macOS and iOS pads with GameController haptics, Android pads with vibrators, Chrome-based browsers.

| Argument | Type | Required | Description |
|---|---|---|---|
| `pad` | integer | no | Gamepad slot 0..3 (default 0; with `stop`, default every pad). |
| `low` | number | no | Strength of the heavy, low-frequency motor, 0..1 (clamped). |
| `high` | number | no | Strength of the light, high-frequency motor, 0..1 (clamped). |
| `seconds` | number | no | How long, above 0 and up to 10. Required with low or high. |
| `stop` | boolean | no | true: stop the pad (every pad when `pad` is left out). Default false. |

## `game.screenshot` (modifies state)

Capture the game view as a PNG and show it: whole, a magnified region, or a filmstrip of frames.

Capabilities: read, state

Draws the game view as it is now (design resolution) and returns it; clients display the image. Scripts only run when frames are stepped: step the game first so the picture shows what you expect.
WITHOUT `path` the picture is temporary: the result is {width, height, frame, temporary: true, $image: {path, mimeType, temporary: true}}, the MCP server and the AI assistant attach the image to the message and then DELETE the file, so do not keep or read that path later. (`factoria call` only prints the result and leaves the file; the engine removes engine-named files `.factoria/screenshots/frame_<n>*.png` older than 3 days or beyond the newest 200 when a project opens.) WITH `path` the file is written there and kept, and the result has `path`. Use `path` when your client cannot show images (then open the file yourself) or when you want to compare pictures later.

Examples: game.screenshot {"path":"shots/start.png","scale":1.5}; game.screenshot {"region":[600,0,80,720],"zoom":8}; game.screenshot {"frames":48,"everyFrames":4,"region":[400,200,480,300]}

`scale` (0.25 to 4, default 1) draws the same frame into an image scale times larger, sharp and not upscaled, for store screenshots: HUD, camera and visible area stay the same, so a 1280x720 game at scale 1.5 gives a 1920x1080 PNG.
A PNG holds 8 bits, at most paper white. In a window on an HDR display the frame is drawn with the HDR tonemap and what it puts above white is clipped, so the brightest areas look flatter than on the screen; a run without a window draws in the standard range, the SDR look (see docs/RENDERING.md, "HDR output").
`region` [x, y, width, height] (design pixels, origin top-left) with `zoom` (0.25 to 32) shows only that part magnified: use it to look at a seam, a join, a gradient end or a one-pixel gap that is invisible in the whole view. Up to zoom 4 the frame is drawn again at that render scale and cropped (lines, text and shapes are sharp, the HUD is included); above 4 the 4x picture is enlarged with nearest-neighbour sampling (hard pixel blocks, nothing blurred). The result is round(width * zoom) x round(height * zoom), at most 8192 px a side; the region is clamped to the view. `zoom` without `region` magnifies the whole view the same way.
`frames` makes a FILMSTRIP: one PNG with a grid of pictures, each labelled with its frame number ("f130 +4" = game frame 130, 4 frames after the start). The first picture is the game now, then the game is STEPPED `everyFrames` frames (default 1) and captured again until `frames` frames have passed, so frames 48 and everyFrames 4 give 13 tiles and leave the game 48 frames further. At most 64 tiles. `region` and `zoom` apply to every tile (the same region each time); without `zoom` the tiles are sized so the sheet is about 2048 px wide (never enlarged). `columns` sets the grid width (default: nearly square). Use it to see a whole transition or animation at once. A tween or script keeps running while it steps: it shows what the game does, it does not freeze anything. The result adds `tiles` [{frame, offset}], `columns`, `rows`, `tileWidth`, `tileHeight` and `zoom`.
`simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the picture to what a colour-blind viewer sees (Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in linear light; greyscale = Rec. 709 luminance) without changing what the player sees: use it to check that hazards, pickups and buttons read without their colour. Needs graphics.
`forceTouch` true shows the touch interface first (the touch-only TouchStick and TouchButton, which a desktop hides): it is set just before the picture and put back afterwards (ui.force_touch {"enabled":true} keeps it on).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Output PNG, inside the project (needs the writeProject capability; absolute paths need writeAnywhere, and the managed folders are refused). Given: the file is kept. Omitted: a temporary picture that the client deletes after reading it. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `scale` | number | no | Render scale of the whole view (default 1): image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080. Not together with zoom. |
| `region` | array | no | [x, y, width, height] in design pixels (origin top-left): only this part of the view is captured, magnified by zoom. |
| `zoom` | number | no | Magnification of the region (or of the whole view): up to 4 a native sharp re-render, above 4 nearest-neighbour enlargement of the 4x picture. Default 1 (a filmstrip without zoom: sized to a sheet about 2048 px wide). |
| `frames` | integer | no | Filmstrip: the game advances this many frames in total, captured every everyFrames, into one labelled grid PNG. |
| `everyFrames` | integer | no | Filmstrip: frames between two pictures (default 1). frames / everyFrames + 1 pictures, at most 64. |
| `columns` | integer | no | Filmstrip: tiles per row (default: the grid closest to square). |
| `simulate` | string ["none","greyscale","protanopia","deuteranopia","tritanopia"] | no | Convert the picture to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged. Default "none". |
| `forceTouch` | boolean | no | true: show the touch interface (the touch-only TouchStick and TouchButton) before the picture; false: the real last input. Only for this call: the previous setting is restored afterwards (ui.force_touch keeps it). |

## `game.state`

Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.

Capabilities: read

Filters: entities (ids), components (names to include), includeDefaults, maxEntities (default 200). Example: game.state {"entities":["player"],"components":["Transform","RigidBody2D"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entities` | array | no | Only these entity ids. |
| `components` | array | no | Only these components per entity. |
| `includeDefaults` | boolean | no |  Default false. |
| `maxEntities` | integer | no |  Default 200. |

## `game.state_hash`

Since 0.19.0.

One 64-bit hash of the whole simulation state: every entity, component and field, the live particles of every emitter, the clock and the random generator.

Capabilities: read

Two runs that simulate the same thing give the same hash; any difference (a float off in its last bit, an extra entity, another random number drawn) changes it. Use it to check determinism: the same game with runtime.jobThreads 0, 1 or 8 (or FA_JOB_THREADS=inline) must give the same hash at the same frame, and so must a replay. Runtime-only fields (velocities, timers) are included unless includeRuntime is false. perEntity lists one hash per entity (creation order) to find which entity differs. components limits the hash to the named component types (and leaves the particles, the clock and the random generator out): compare two runs on, say, ["SpriteAnimator","Sprite"] only. Example: game.state_hash {"perEntity":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `perEntity` | boolean | no | Also list one hash per entity, in creation order (at most maxEntities). Default false. |
| `includeRuntime` | boolean | no | Hash the fields that are not saved to scenes too (velocities, timers). Default true. |
| `maxEntities` | integer | no | How many entities perEntity lists. Default 200. |
| `components` | array | no | Hash only the components of these types (names as in the component list, e.g. ["Sprite","SpriteAnimator"]); the particles, the clock and the random generator are left out. Default: everything. |

## `game.step` (modifies state)

Advance the simulation by N fixed frames (deterministic) and return a state summary.

Capabilities: read, state

Each frame is exactly 1/fixedHz seconds. `press` holds actions/keys down and `release` lets go; they are applied BEFORE the first frame and stay in effect (a press without release stays held). To tap a button use game.step {"frames":1,"press":["jump"]} then game.step {"frames":1,"release":["jump"]}. Works while paused. Example: game.step {"frames":60,"press":["move_right"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | Number of frames. Default 1. |
| `press` | array | no | Actions/keys to press first. |
| `release` | array | no | Actions/keys to release first. |

## `graphics.backend` (modifies state)

Not released yet (on main after 0.36.0).

Reads which GPU backend draws the game, or stores the one the next start draws with ("takes effect at the next start").

Capabilities: read, state

With no argument it reads and changes nothing: {active, sokolBackend, requested, source, auto, available, fallback, stored, storedIn}. `active` is the backend the renderer draws with ("none" without graphics), `requested` the name asked for and `source` where it came from ("EngineConfig", "FA_GPU_BACKEND", "user settings", "factoria.json" or "default"), `auto` what auto draws with in this player, `available` the backends this player has, `fallback` {from, reason} when another player could not start its backend and started this one in its place (the Vulkan player of Linux and Android, which hands over to the OpenGL one), else null. With `name` it stores that choice for the next start in the game's user settings (`storedIn`: graphics_backend.json in the save folder, or memory in a run with in-memory storage) and returns the same report plus {changed, takesEffect: "next start"}; the backend in use does not change. "auto" forgets the choice. Example: graphics.backend {"name":"gl"}

The order at start: EngineConfig.gpuBackend, the FA_GPU_BACKEND environment variable, the stored choice, factoria.json render.backend, auto. On Linux and Android an exported game ships two players: the Vulkan one starts first and runs the OpenGL one when the choice is gl or gles3 or when Vulkan cannot start (docs/RENDERING.md, "Choosing the GPU backend"); there `vulkan` may be stored from the OpenGL player too. Errors: `invalid_argument` for an unknown name (with a "did you mean"), a backend this platform cannot have, or an unknown argument; `io_error` when the save folder cannot be written. Nothing changes on an error.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string ["auto","gl","gles3","webgl2","d3d11","metal","d3d12","vulkan"] | no | The backend the next start draws with; "auto" forgets the stored choice. Leave it out to read. |

## `graphics.detect`

Since 0.36.0.

Measures this GPU with a short benchmark and suggests the graphics preset that suits it. Changes nothing.

Capabilities: read

Reads the GPU (backend, adapter name, vendor, video memory where the graphics API says it, software renderer or not) and the device (game.device: tier, form factor, handheld), draws a fixed scene about 150 meshes with shadows at 960x540 off-screen a few times, and answers the preset that machine can hold. The scene is drawn with the engine's own world, never the game's: the simulation, its clock and its random numbers are not touched, and the graphics preset in force is lifted while it runs so every GPU is measured on the same work. One warm-up picture (pipelines are made then, not timed) and 5 timed ones; the median is the score; a safety net stops the timed ones after 4 seconds in total. Returns {preset, reason, gpu: {backend, name, vendor, driver, memoryMB, unifiedMemory, software}, benchmarkMs, benchmark: {ran, why, samples, frameMs, totalMs, width, height}, device: {tier, formFactor, handheld}}. Example: graphics.detect {}

The rule: a median of 4 ms or less is ultra, up to 8 ms high, up to 16 ms medium, slower low; a software renderer (llvmpipe, SwiftShader, WARP) is low and is not benchmarked; a phone or tablet is capped at medium, a handheld (Steam Deck) at high, a low device tier or under 2 GB of video memory at medium. Without graphics (graphics=false) or on the dummy backend nothing is drawn (`benchmark.ran` is false and says why) and the device tier decides. `benchmarkMs` is the whole benchmark, warm-up included (about the time the player waits); on a slow GPU or a cold shader cache it takes seconds, and the call blocks the frame it is made in, whether from a command or from a script's update: call it behind a loading screen or the first-run options page, never during play. On the web it is not run (the page would freeze while the pipelines are made) and the device tier decides. The benchmark draws in the colour space the game's targets are in, so the game's targets are not made again. Times are rounded to 0.1 ms and differ run to run: a game uses `preset`, not the number, and `reason` never holds a time. The same is game.graphics.detect() in scripts, which leaves out `benchmarkMs`, `benchmark.frameMs` and `benchmark.totalMs` (machine-dependent numbers a script could branch on): only tools and MCP read them.

## `graphics.preset` (modifies state)

Since 0.36.0.

Reads or applies a graphics preset (low, medium, high, ultra, custom): a quality layer over the render settings of the game.

Capabilities: read, state

A preset is a set of limits on what the scene, its cameras' PostProcess and its lights ask for (shadows, ambient occlusion, reflections, depth of field, motion blur, fog, level of detail, foliage, terrain, 2D lighting, global illumination) plus the upscaler. A limit only lowers; nothing is written into the scene or factoria.json. `custom` is no layer: the game looks as its author made it. With `name` it applies that preset; with no argument it reads the current one. Returns {preset, previous, changed, changes: [{knob, from, to}], limits, capped: [{knob, wanted, effective, reason}], upscaler, headless}. Example: graphics.preset {"name":"high"} With no argument it only reads and changes nothing (the command is not marked read-only because it also writes). The table of each preset: docs/UPSCALING.md, "Graphics presets".

A limit only lowers: a scene that asks for 2 cascades under a limit of 4 still draws 2, and the simulation never reads a preset. The presets also write the upscaler (mode auto, a quality; ultra none); `custom` puts back the one the game had before the first preset, and a render.upscaler or window.upscaler change while a preset is on applies at once and becomes what `custom` brings back (its keys over the setting from before the preset). Knobs the GPU cannot draw are capped (render.supports says which) and `capped` names each with the reason; `limits` is the layer in force after the caps (a limit at its largest value means no limit), `changes` the limits and the upscaler that differ from before. `headless` is true when the engine runs without graphics: the preset is remembered, nothing is drawn and no GPU cap was looked at. The default preset of a game is factoria.json "render": {"graphicsPreset": "high"}; the engine does not remember the player's choice (keep it with storage.set(); graphics.detect suggests one for a first run). Errors: `invalid_argument` for an unknown name (with a "did you mean") or argument; nothing changes. The same is game.graphics.preset() in scripts.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string ["low","medium","high","ultra","custom"] | no | The preset to apply. Leave it out to read the current preset. |

## `input.record` (modifies state)

Since 0.3.0.

Record the input the game receives as an input replay (start / stop).

Capabilities: read, state, writeProject

`start` begins recording every key, mouse, touch, gamepad and Back event the game receives (from a window, a test, game.input or a replay), the dt and fixed steps of each frame, the clipboard reads, the answers of http.fetch and the calendar date; what is held at that moment (keys, buttons, pads) is part of it. `stop` ends it and returns the replay in `replay`: the JSON that `factoria run --headless --input <file>` plays (frame numbers count from the start; typed text, the mouse wheel and locked-mouse movement have no field in the format and are not recorded). `path` (with stop) also writes the replay to that project-relative file. A replay run from the same scene, seed and props reaches the same state. Start and stop between frames. Starting while recording begins again. Example: input.record {"action":"start"} ... input.record {"action":"stop","path":"replays/run1.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string ["start","stop"] | yes | start: begin recording now. stop: end it and return the replay. |
| `path` | string | no | stop only: also write the replay to this project-relative file inside the project (e.g. replays/run1.json; absolute paths need writeAnywhere). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |

## `render.debug_view` (modifies state)

Since 0.31.0.

Show the depth or the normals of the depth and normal prepass, the ambient occlusion, the cascades of the sun's shadow or the occlusion culling, instead of the game picture, or report which view is on.

Capabilities: read, state

A way to look at the data the depth-based post effects (ssao, depth of field, fog...) read: `depth` paints the prepass depth as a grey (10 / (10 + distance), white next to the camera), `normals` the view-space normal as colours (a surface that faces the camera is blue), black where no opaque mesh was drawn; `ao` paints the ambient occlusion alone as a grey (white = open or no mesh, dark = occluded) over the camera's rectangle, with the camera's own PostProcess ssao settings or, when it has none, the defaults; `cascades` tints every mesh by the cascade of the directional light's shadow it falls in (red, green, blue, yellow for the first to the fourth, grey past the last or with no shadow); `none` shows the game again. It is a look at the data for a person or an AI checking a scene, not an effect: it is not saved and a game does not set it. Without `view` it only reports the current one. Result: {view, previous}. The view shows from the next frame (game.step, then game.screenshot). Example: render.debug_view {"view":"depth"}

`motionVectors` paints the per-pixel motion image the prepass writes for temporal antialiasing (the direction of the motion as a hue, its length as the brightness, black = still, grey = no object wrote a vector: the sky, blended or additive particles and sprites, a skinned mesh of more than 64 joints); it turns that image on while it is shown. `occlusion` keeps the game picture and draws the Occluder boxes green and the boxes of the meshes the occlusion culling left out red, with a line of counts (docs/BIG_WORLDS_LOD.md, "Occlusion"; render.occlusion saves its depth buffer). The environment variable FA_RENDER_DEBUG_VIEW sets the first view at start. The picture changes only on a frame that draws the prepass (a post effect that reads the depth is on, see docs/RENDERING.md, "Depth and normals"; `cascades` needs only a directional light with castShadows). Errors: `invalid_arguments` for a `view` that is not none, depth, normals, ao, cascades, occlusion or motionVectors (with a did-you-mean); `unavailable` without graphics (graphics=false). The same is Renderer::set_debug_view in C++.

| Argument | Type | Required | Description |
|---|---|---|---|
| `view` | string ["none","depth","normals","ao","cascades","occlusion","motionVectors"] | no | none (the game picture), depth, normals, ao (the ambient occlusion), cascades (the meshes tinted by the cascade of the sun's shadow they fall in), occlusion (wire boxes: Occluders green, meshes the occlusion culling hid red) or motionVectors (the per-pixel motion of the opaque meshes: the direction as a hue, the length as brightness, grey where no mesh wrote a vector). Omitted: report the current view. |

## `render.dynamic_resolution` (modifies state)

Since 0.36.0.

Reads or changes the dynamic resolution: the render scale follows the frame time so the game holds a target.

Capabilities: read, state

While `enabled`, the engine measures the frame (the GPU's time on Direct3D 11 and OpenGL, the time between frames elsewhere) and moves a factor between `minScale` and `maxScale` so the frame time stays at `targetMs` (0 or null: one refresh of the display: the rate the OS reports for the monitor the window is on, else one estimated from the time between presented frames, else 60 Hz; see refreshHz). The factor multiplies window.renderScale and the upscaler's quality scale (never below 0.25), on a grid of 32 steps, at most twice a second. Off (the default) draws at the fixed render scale, exactly as before. With no argument it returns the setting; with any key it changes those and keeps the rest. Example: render.dynamic_resolution {"enabled":true,"targetMs":16.7,"minScale":0.6} The reasoning and the limits: docs/UPSCALING.md, "Dynamic resolution".

Returns {enabled, targetMs, minScale, maxScale, effectiveTargetMs, scale, frameMs, source, refreshHz, refreshSource, changed}: scale is the factor in force (1 while off), frameMs the smoothed measured frame time (0 until measured), source what is measured ("gpu", "interval", "injected", "none"). refreshHz is the display refresh rate a targetMs of 0 follows (rounded to 0.1 Hz, reported while off too) and refreshSource where it comes from: "platform" (the OS: macOS and iOS maximumFramesPerSecond, the Windows display mode, the Linux XRandR mode, Android Display.getRefreshRate), "estimated" (the median time between presented frames, where the OS does not say: the web, a Windows driver that answers the hardware's default, Linux without libXrandr), "default" (60: no window, as with graphics=false, vsync off, window.frameCap set, or the estimate still measuring). The renderer makes its images again only when the factor steps. The start value is factoria.json "render": {"dynamicResolution": {...}}; window.dynamicResolution in scripts is the same setting. A wrong key or number fails with `invalid_argument`, the JSON pointer and the valid range, and changes nothing. Works with graphics=false too (the value is only remembered; a headless run measures no frame time). The factor is a measurement of this machine: it is never part of the simulation, a replay or a screenshot test's state.

| Argument | Type | Required | Description |
|---|---|---|---|
| `enabled` | boolean | no | true turns the controller on; false (default) draws at the fixed render scale. |
| `targetMs` | any | no | The frame time to hold in ms (33.3 = 30 fps, 16.7 = 60 fps), 4..100; 0 or null follows the display's refresh rate. |
| `minScale` | number | no | The smallest share of the render size's width and height, 0.25..1 (default 0.5). |
| `maxScale` | number | no | The largest share and where it starts, minScale..1 (default 1). |

## `render.frame_graph`

Since 0.28.0.

Where the last frame's time went, pass by pass: the frame graph with the CPU and GPU time of every pass.

Capabilities: read

Returns the frame graph of the last frame the renderer drew and what each of its passes cost, so you can see which job and which pass makes a frame slow. Result: {source, backend, frame, profileFrames, graph, passTimes, jobTimes, gpu, postProcess}. `passTimes` has one {name, job, cpuMs, gpuMs} per pass that ran, in order (cpuMs: time to record the pass on the CPU; gpuMs: GPU time, or -1 when not measured: D3D11 and desktop OpenGL only, while the profiler is on); `jobTimes` adds them per job; `gpu` says whether GPU times exist and why not. Compare passes with each other, not the decimals. Draws a frame first when none is current. The GPU times need the profiler: with `profileFrames` (default 8, 0 to 60) this command switches it on for the call when it is off and the backend can time the GPU, draws the current state up to that many times until the GPU times arrive, and puts the profiler back; `profileFrames: 0` is the call that only reads: it neither switches the profiler on nor draws a frame again (gpuMs is then -1 unless a profile or the editor's Profiler panel already runs). Example: render.frame_graph {"profileFrames":8}

`frame` is the engine's frame counter (the same number as game.state's `frame`) when the graph was read: the graph itself is the one of the last frame drawn. `profileFrames` is how many frames this call drew with the profiler switched on to get the GPU times (0 when it did not need to: the profiler was already on, or profileFrames was 0, or the backend has no GPU timer; `gpu.reason` says which). `source` is "frame" (a normal frame) or "capture" (the last graph was the picture of one entity's subtree, not a frame of the game: the next frame shows the game's own). `backend` is the graphics backend (metal, d3d11, glcore, gles3, dummy). READ `graph` like this: a JOB is one picture the frame draws: `camera:<i>` (a camera of the frame, in depth order), `screen` (the screen-space items of a split frame), `view:<n>` (a CameraView's image), `target:<name>` (a Camera.renderTarget texture) or `capture`; a PASS is named `<job>/<pass>` (`game` draws the world, `light-buffer` the 2D lights, `shadow` the shadow map, `bloom-*` the glow, `hud-over-bloom`, `color-filter`, `flip`). graph.resources are the images the passes read and write: `imported` ones are owned by the renderer and persist (the game image, a view's image, the light buffer, the shadow map); `transient` ones exist only inside the frame (the bloom levels) and share a physical target when their lifetimes do not overlap (`aliasSlot`, listed in graph.aliasSlots; `firstUse` and `lastUse` are positions in `order`). graph.passes lists every declared pass with what it reads and writes; a pass is `culled` when nothing reads what it writes and it has no side effect, so it did not run (graph.culled names them) and it has no time. graph.order is the order the live passes ran. graph.cycleBreaks lists passes that ran before a pass they waited for because two render targets show each other: the one that went first shows the other's picture of the PREVIOUS frame (empty is normal). `passTimes` has one entry per pass that ran, in `order`: {name, job, cpuMs, gpuMs}. cpuMs is the wall-clock time the pass took to record its GPU commands on the CPU (a pass that is cheap here can still be slow on the GPU). gpuMs is the GPU time of that pass in a recent frame (timer queries are read a few frames late and never waited for), or -1 when it was not measured; the numbers jitter from frame to frame, so compare passes against each other rather than reading the decimals. `jobTimes` adds the passes of each job: {job, passes, cpuMs, gpuMs} (gpuMs is -1 when no pass of the job has one). `gpu` says whether GPU times exist: {supported, measuring, reason, maxTimedPasses}: they exist on Direct3D 11 (Windows) and desktop OpenGL (Linux), only while the profiler is on (this command's profileFrames, perf.profile, play.report's profile, the editor's Profiler panel), and at most maxTimedPasses passes per frame are timed; `reason` says why there are none (Metal, GLES3 and WebGL2 have no timer queries here). `postProcess` is the post-processing alone: {passes: [{name, job, cpuMs, gpuMs}], cpuMs, gpuMs, gpuStatus, gpuReason, gpuPassesTimed, gpuPartial, note}, the passes named bloom-*, exposure-*, post and the other effect passes (prepass and sprite-coverage are not in it), with their summed times. `gpuMs` is null, `gpuStatus` "unavailable" and `gpuReason` the reason (the `gpu.reason` text, which says when the profiler is off, or that the frame has no post pass) when no GPU time exists, never 0. When only some passes came back with a time, `gpuMs` is their sum, `gpuPassesTimed` counts them and `gpuPartial` is true: a lower bound, not the whole cost. The effects folded into the single `post` pass (vignette, grain, grading, sharpen, outline...) are not timed one by one: `post` is their total, and no per-effect estimate is made. The same pass times are in the profiler's `zones`. Like game.render_stats it draws a frame first when none was drawn since the last change (a headless run draws on demand). Errors: `unavailable` without graphics, or when no frame could be drawn, and `invalid_argument` for a profileFrames that is not an integer from 0 to 60. Example: render.frame_graph {"profileFrames":8}

| Argument | Type | Required | Description |
|---|---|---|---|
| `profileFrames` | integer | no | GPU times need the profiler: when it is off and the backend can time the GPU, switch it on for this call and draw the current state up to this many times, stopping as soon as GPU times arrive; then put it back. 0 = read what is there (gpuMs -1 unless the profiler is already on). Default 8. |

## `render.gi2d_field` (modifies state)

Since 0.34.0.

The 2D global illumination field of the last frame: its size, texel size and world rectangle, what fills it and its cascades; optionally the images as PNGs.

Capabilities: read, state

Draws a frame when none is current and reports the field that a GlobalIllumination2D makes for each 2D camera job (docs/design/ARCHITECTURE_RENDERING_GI2D.md, "2D GI field: what P3b reads"): an emission image, an occluder/albedo image (alpha = occupancy) and a jump-flooding distance field, RGBA16F, covering the view plus `range` on every side at `resolutionScale`, and the radiance cascades that turn it into the irradiance the lit 2D visuals receive (docs/rendering/RENDERING_2D_GI.md). With `save` it also writes the images as PNGs. Errors: `unavailable` without graphics. Example: render.gi2d_field {"save": ".factoria/tmp/gi"}. See docs/design/ARCHITECTURE_RENDERING_GI2D.md, "2D GI field: what P3b reads".

Result: {enabled, supported, message? (why not supported: the backend and render.supports "2dGlobalIllumination"), fieldLimit, maxSize, format, settings: {quality, intensity, bounce, range, resolutionScale}, bytes, fields: [{slot, job, ready, width, height, texelSize, worldRect: {x, y, width, height}, capped, bytes, passes, cascades: {cascades, probeSpacing, raysPerProbe, steps, reachTexels, irradianceWidth, irradianceHeight, primed}, emitters: {sprites, tiles, lights}, occluders: {solidTiles, boxes, polygons, spriteAlpha, skipped}, dropped}]}. `fields` is empty without an enabled GlobalIllumination2D, on a 3D camera, or where the GPU has no RGBA16F render targets (then `supported` is false and `message` says what to do). With `save` (a path without extension) the images of the field of `job` (default: the first) are written as <save>-emission.png, <save>-occluders.png and <save>-distance.png and, once a frame of cascades has run, <save>-irradiance.png (one pixel a probe of cascade 0, rgb the light that reaches the probe, alpha 1 where the probe is free and 0 inside an occluder or an emitter); row 0 of a file is the largest world y; they are listed in `files`; a failure is in `error`. `cascades.primed` is true when the last frame had no history of the bounce and ran the priming chain (the first frame, a new size, a camera that moved by more than the field). Errors: `unavailable` without graphics; `invalid_argument` for a `save` or `job` that is not a string, and for a `save` that ends in .png or in a folder separator (it is a prefix: the command adds the names).
The distance image holds the nearest occluder texel's coordinates in r and g (exact), the distance to it in field texels in b (a half float: about 3 significant digits) and 1 in a where an occluder exists (b is 65504 and a is 0 for a field without occluders; a texel with a = 0 holds -1 in r and g). The `save` PNG of the distance is grey: black at an occluder, white at the farthest distance of the field (white everywhere without occluders). `save` reads the GPU back: look, do not call it every frame. `save` needs the writeProject capability.

| Argument | Type | Required | Description |
|---|---|---|---|
| `save` | string | no | Path prefix without extension (inside the project; absolute paths need writeAnywhere): the images are written as <save>-emission.png, <save>-occluders.png, <save>-distance.png and <save>-irradiance.png (never end it in .png or in a folder separator). Omitted: nothing is written. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `job` | string | no | The camera job whose field `save` writes (the "job" of fields[], e.g. "camera:0"). Default: the first field that is ready. |

## `render.gi_grid`

Since 0.33.0.

The realtime GI's probe grids: probe count, update progress, memory and the probes that are inside geometry.

Capabilities: read

Reads the state of the RealtimeGI grids after drawing a frame when none is current. Result: {frame, captures, capturesPerFrame (last 64 frames), probeLimit, atlas: {width, height, format, bytes, blocksUsed}, grids: [{entity, state, message?, probes, dimensions, spacing, origin, resolution, probesPerFrame, captured, progress (0..1), cycles, framesPerCycle, bytes, notCaptured, invalidProbes, invalid: [{index, position}] (up to 64)}]}. `state` is "updating" (probes not captured yet), "ready", "invalid" (`message` names the field and the fix), "noRoom" (more than `probeLimit` probes), "failed" (a capture could not be made: it is retried after 30 frames, and `state` and `message` stay until the next capture succeeds) or "unsupported" (no RGBA16F blending). `invalidProbes` counts the probes inside a mesh (back faces hit beyond `backfaceTolerance`), found by one atlas readback: call this to look, not every frame. `meshesRead` is true when the lit meshes read the grid (it is ready and the renderer supports it). {grids: [], atlas: null} while no RealtimeGI was drawn. Errors: `unavailable` without graphics. Example: render.gi_grid {} See docs/rendering/RENDERING_LIGHT_PROBES.md, "Realtime global illumination".

Other result fields: passes, probesPerFrameLimit, capturesLastFrame, firstBlock. A grid costs `probes` x 10 x 11 texels x 8 bytes of the probe atlas (1760 bytes for two probes) and `probesPerFrame` x 6 faces of `resolution` x `resolution` texels a frame; the atlas grows by 132 rows (about 1 MB) while any RealtimeGI exists. `ready` means every probe was captured once; the others are refreshed in turn, `framesPerCycle` frames for all.

## `render.inspect`

Since 0.4.0.

Luminance profile of the current picture along a line, with the hard steps (seams, bands) in it.

Capabilities: read

Draws the picture as it is now and reads the pixels along the segment `from` -> `to` (design pixels, origin top-left): one sample per pixel along the longer axis, as a value 0..255 of the sRGB bytes (`channel`: luminance with Rec. 709 weights, or red, green, blue). It lists every STEP: a change of at least `threshold` (default 8 levels) within `window` samples (default 2), which is how a bright seam, a gap between two sprites or the edge of a gradient band shows in the numbers while the eye misses it. A smooth ramp has no steps; a staircase (Mach bands: two overlapping gradients) has one per riser. The edge of a sprite or a shape is a step too: find what draws it with render.pick at the step's `at`. Result: {from, to, channel, scale, count, samples: [values], min, max, steps: [{index, at: [x, y] (design pixels, the middle of the jump), width, from, to, delta}], stepCount, frame}; at most 200 steps and 4096 samples. `scale` (0.25 to 4, default 1) samples a render at that scale, so at 4 there are four samples per design pixel and a sub-pixel gap shows. Look at the area with game.screenshot {region, zoom} first, then measure it. Needs graphics. Example: render.inspect {"from":[600,360],"to":[680,360],"threshold":6}

| Argument | Type | Required | Description |
|---|---|---|---|
| `from` | array | yes | Start of the line, [x, y] in design pixels (origin top-left). |
| `to` | array | yes | End of the line, [x, y] in design pixels. |
| `threshold` | number | no | Smallest change (0..255) that counts as a step. Default 8. |
| `window` | integer | no | A step is a change of at least threshold within this many samples. Default 2. |
| `channel` | string ["luminance","red","green","blue"] | no | What to measure: Rec. 709 luminance or one colour channel of the sRGB bytes. Default "luminance". |
| `scale` | number | no | Render scale to sample at; higher finds finer gaps. Default 1. |

## `render.light_probes`

Since 0.33.0.

The baked light probes of the scene and the light a MeshRenderer receives from them.

Capabilities: read

Light probes (M73.4d) are the LightProbeGroup components baked by lightmap.bake into the .probes file of the scene's lightmap manifest (SceneSettings.lightmaps): a mesh without a lightmap (a moving object, lightmapScale 0, a skinned mesh) receives their spherical harmonics in place of the sky's ambient, interpolated at the centre of its bounds (or at MeshRenderer.probeAnchor). Without `entity`: {lightmaps, baked, probes, invalid, groups: [{id, kind: "grid" | "points", count, invalid, stale}], unbaked: [ids]}; `invalid` probes sit inside geometry and are skipped. With `entity` (a MeshRenderer): also {entity: {id, name, source: "probes" | "lightmap" | "sky" | "none", position, coverage (0..1: how much of the light comes from the probes, the rest from the sky), probesUsed, sh (nine [r, g, b] coefficients), ambient: {up, down, east, west, north, south} (the diffuse light a surface facing that way gets), note}}; `sky` means no probe reaches it. Floats are rounded to 3 digits. Needs graphics. Example: render.light_probes {"entity":"Player"}

A group is `stale` when its LightProbeGroup was edited (moved, resized, other spacing or points) since the bake; `unbaked` lists the scene's groups the baked file does not hold (added or edited since): bake again for both. Both are left out when the scene has no baked probes. Errors: `invalid_argument` for an `entity` that is not a string; `not_found` for an entity that does not exist; `unavailable` without graphics (graphics=false). The same is Renderer::light_probes_report in C++.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The MeshRenderer entity (id or name) whose received light to report. Default: only the scene's probes. |

## `render.material_cost`

Since 0.33.0.

What the material of a mesh entity costs the renderer: its extra passes, its phase and the features that only add shader work.

Capabilities: read

The one list the Inspector's cost view shows: for the MeshRenderer of entity `id` it says which features are on and what each adds to the frame. Returns {id, extraPasses, phase, summary, features: [{name, field, active, cost, extraPasses, note}]}. `phase` is "opaque" or "blended" (blended meshes are drawn after the opaque ones, far to near, without writing depth; a transmissive mesh is one of them). `cost` of a feature is "extraPass" (transmission copies the opaque picture once per camera that sees such a mesh: a pass for each reduced half, one that writes the atlas and the second half of the main pass; a full-shader material draws the mesh once per pass), "phase" (blended: no pass, a different place in the frame) or "shader" (clear coat, sheen, anisotropy: more work per pixel, no pass). `extraPasses` counts the passes of an active feature (0 when it is off), and the top-level one adds them up; the pass count of transmission follows the size of the picture (a small one has fewer halves). The decision is the renderer's own (a MeshRenderer field replaces the model's, a full-shader material gets no layers and no transmission). Example: render.material_cost {"id":"window"}

Errors: `not_found` for an `id` that is not in the scene, `invalid_argument` when the entity has no MeshRenderer, `unavailable` without graphics (graphics=false). It loads the entity's mesh and material when they are not loaded yet. The same answer is Renderer::material_cost in C++.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The id of an entity with a MeshRenderer. |

## `render.occlusion` (modifies state)

Since 0.35.0.

The occlusion culling of the last frame (CPU Occluders and the GPU depth pyramid): Occluders rasterised, meshes tested and hidden; optionally the depth picture as a PNG.

Capabilities: read, state

Draws a frame when none is current and reports what the CPU occlusion culling did for the last camera that had an enabled Occluder (docs/BIG_WORLDS_LOD.md, "Occlusion"), and in `gpu` what the depth pyramid did (SceneSettings.occlusionMode "gpu" or "auto" on a backend with compute shaders): the size of its depth buffer, the Occluders and triangles rasterised, the meshes tested against it and the ones it proved hidden (they are in renderStats.meshesOccluded too). With `save` it also writes the depth buffer as a grey PNG (black = no occluder, the nearer an occluder the brighter) so you can see what hides what; render.debug_view {"view":"occlusion"} draws the boxes over the game picture. Errors: `unavailable` without graphics; `invalid_argument` for a `save` that is not a string or does not end in .png. Example: render.occlusion {"save": ".factoria/tmp/occlusion.png"}

Result: {supported, debugView, active, limits: {width, trianglesPerOccluder, trianglesPerCamera}, camera, width, height, occluders, triangles, coveredCells, tests, hidden, file?, error?, gpu: {mode, supported, why?, active, limits, camera?, cameras?, usableCameras?, width?, height?, levels?, coveredCells?, ageFrames?, tests?, hidden?, testResults?: {hidden, visible, noPyramid, cut, behindNear, outsideView, tooMuchMotion, noOccluder}, drewEverythingBecause?, reducePasses?, level?, file?, error?, message?}}. `active` is false when no camera of the last frame had an enabled Occluder (then only `message`, `limits` and `gpu` follow). In `gpu`, `ageFrames` is how old the depth picture was (1 is the frame before) and `testResults` counts the meshes tested by why they were or were not culled. With `save` and no Occluder buffer, the file is the pyramid's `level` (0 = 256 cells across). `width` x `height` is the buffer without its one-cell guard ring (256 across; 256 / aspect down). `save` needs the writeProject capability.

| Argument | Type | Required | Description |
|---|---|---|---|
| `save` | string | no | A .png path (inside the project; absolute paths need writeAnywhere) for the depth buffer as a grey picture. Omitted: nothing is written. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `level` | integer | no | Which mip of the GPU depth pyramid `save` writes when no Occluder buffer exists (0 = the finest, 256 cells across; each level halves it). Default 0. |

## `render.output`

Since 0.31.0.

What the game window shows: the standard range or HDR, in which encoding, and what the display can do.

Capabilities: read

The window's swapchain switches to HDR when SceneSettings.hdrOutput is "auto", the display the window is on can show HDR and the renderer writes that encoding (docs/RENDERING.md, "HDR output"); this command says what happened and why. Returns {hdrActive, encoding, swapchainFormat, requested, paperWhiteNits, maxNits, headroom, status, display}. Example: render.output {}

`encoding` is "sdr" (8-bit sRGB), "edr" (macOS and iOS: 16-bit float in extended linear sRGB, 1.0 = the display's white), "scRGB" (Windows: 16-bit float, linear, 1.0 = 80 nits) or "hdr10" (Windows: 10-bit ST 2084 PQ in Rec.2020). Only the tonemap of a PostProcess goes above paper white; while the picture stays within it (no exposure or tonemap, a colour filter, an 8-bit GPU) `status` says so. `swapchainFormat` is "BGRA8", "RGBA16F" or "RGB10A2" ("" without a window or before the first frame). `requested`: the current scene's hdrOutput is auto. `headroom`: how many times brighter than paper white the output can go now (the screen's current EDR headroom; maxNits / paperWhiteNits in scRGB and HDR10; 1 in sdr), rounded to 2 decimals. `status`: one sentence, what is shown or why the window stays in the standard range (hdrOutput off, Windows' HDR switch off, a screen without EDR, the editor, a platform without HDR output). `display`: {known, hdr, name, offers: [encodings], maxNits, minNits, maxFullFrameNits, maxHeadroom, headroom, why}; nits are 0 where the platform does not report them (macOS, iOS), headrooms are 1 outside Apple. The answer is the one of the last frame the window presented (the display is asked once per frame: moving the window to another monitor or switching HDR in the OS settings shows on the next one). Headless runs, graphics=false, Linux, Android and the web answer sdr with display.known false or the platform's reason. The same answer is Renderer::output_info() in C++.

## `render.pick`

Since 0.4.0.

Which entities draw a design-space pixel of the picture, topmost first.

Capabilities: read

Lists the 2D visuals (Sprite, Shape2D, Text, Tilemap, UI widgets) whose drawn box covers `position` (design pixels, origin top-left), topmost first: screen-space UI above the world, then the higher `layer`, then (world Sprites) the lower world y, then the one drawn later (component order Tilemap, Sprite, Shape2D, Text; then creation order). Each hit is {entity, name, component, layer, space: "world"|"screen"}. Use it to find which shape or sprite causes a visible artefact (a seam, a dark band) after game.screenshot {region, zoom} or render.inspect located it. The test is the oriented BOX of the visual (the same footprint as entity.bounds() and the editor's picking): a transparent corner of a sprite, the corners outside a circle and the parts of a gradient that fade out still count; an alpha-0 colour is skipped; inactive entities are skipped, and so are world visuals the camera at that pixel does not draw (Camera.showTags / hideTags). The world point is found through the primary camera; `world` in the result is that point. Example: render.pick {"position":[640,360]}

`widget` is the widget a click there would reach, through the same path the mouse takes: a screen widget, else a world-space Interactable, and over a mesh that shows a render target (Camera.renderTarget) the Interactable of that page under the point, or null. `via` ({mesh, target}: the MeshRenderer entity and the target camera's) is present when the point is over such a mesh (`hits` still lists what the main camera draws there: the mesh, not the page behind it). Needs graphics (the camera is the renderer's).

| Argument | Type | Required | Description |
|---|---|---|---|
| `position` | array | yes | [x, y] in design pixels (origin top-left). |
| `max` | integer | no | At most this many hits. Default 20. |

## `render.probe_refresh` (modifies state)

Since 0.33.0.

Capture a realtime reflection probe again (or every realtime probe) as soon as the frame budget allows.

Capabilities: read, state

Queues one more capture of the ReflectionProbe `entity` (or of every realtime probe when `entity` is left out): the one that an `onDemand` probe waits for, and a way to refresh a `timeSliced` or `everyFrame` probe after the scene around it changed. The capture is made in the next frames, a few cube faces each (render.probes shows `facesDone` and `captures`; the faces per frame are the renderer's budget, 2 by default), so draw a few frames before reading it. Result: {refreshed: [entity ids], skipped: [{entity, reason}]}. Without `entity`, a probe that has no tile yet is listed in `skipped` with the reason; with `entity` it is an error. Example: render.probe_refresh {"entity": "lobby"}

Errors: `invalid_arguments` for an `entity` that is not a string; `not_found` for an `entity` that does not exist; `invalid_argument` when the named entity has no ReflectionProbe or is a baked one; `unavailable` without graphics (graphics=false) or when the named probe has no tile in the atlas. The same is Renderer::probe_refresh in C++.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The probe's entity (id or name). Default: every realtime probe. |

## `render.probes`

Since 0.33.0.

The reflection probes the renderer keeps: the atlas, each probe's tile, state and last capture.

Capabilities: read

Reads the state of the reflection probes (ReflectionProbe components, docs/design/ARCHITECTURE_PROBES.md) after drawing a frame when none is current. Result: {atlas: {size, format ("RGBA16F" or "RGBA8"), tiles, usedTexels, reservedTexels, capacityTexels, created}, sky: {state, tile, writtenFrame}, faceBudget, frame, passes, overLimit, probes: [{entity, mode, update, state, message?, resolution, importance, tile: {x, y, resolution} or null, captures, lastFrame, facesDone | bakedMap, hash?}]}. `state` is "ready", "pending", "capturing", "noRoom", "noBake" or "failed". The lit meshes sample the atlas (the sky is its entry 0, `sky`). The result is {probes: [], atlas: null} while no ReflectionProbe has been drawn. With `entity` (a mesh), the result also has `mesh: {probes: [{entity, share}], sky}`: which probes that mesh reflected in the last frame and how much of its reflection each holds (0..1, steps of 1/32; the probes and the sky add up to 1). Errors: `unavailable` without graphics; `invalid_argument` for an `entity` that is not a string or has no MeshRenderer. Example: render.probes {} or render.probes {"entity": "sphere"}. What each state means: docs/rendering/RENDERING_PROBES.md, the render.probes item.

The first ask for a mesh draws one more frame (the renderer keeps the picks of that one mesh only): the debug-draw lines queued since the last draw are consumed and a time-sliced capture moves on by a frame. An ask without `entity` ends that watch.

`state`: "ready"; "pending" (waiting for its first capture); "capturing" (facesDone of 6 faces drawn); "noRoom" (the atlas has no tile for it: `message` says why); "noBake" (a baked probe with no readable bakedMap: run probe.bake); "failed" (retried after 30 frames). `overLimit` counts the active probes beyond the 256 the renderer keeps (those with the smallest importance): they have no entry in `probes`. A capture is asked again with render.probe_refresh. `lastFrame` counts the frames that had probes. A mesh no probe reaches reflects the sky. The atlas of the realtime and baked probes is one image 1024 texels wide (1024 x 1024, 8 MB as RGBA16F, unless a RealtimeGI makes it taller); `usedTexels` is what the tiles cover and `reservedTexels` what their shelves hold, so a large gap means fragmentation by resolution.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | A mesh entity (id or name): the result also says which probes it reflects. |

## `render.reset_post_history` (modifies state)

Since 0.32.0.

Start again the history of the custom post passes that read their own output of the frame before (fa_history).

Capabilities: read, state

A custom post material whose snippet calls fa_history(uv) (trails, feedback, accumulation; docs/shaders/SHADERS_POST.md, "History") keeps its output of the frame before. This forgets it for one camera (`entity`) or every camera: from the next frame fa_history_valid is false and fa_history(uv) gives the picture, so the effect starts clean. The renderer already does it by itself in the first frame, after a resize or a change of render scale, when a camera was not drawn in the frame before, and when the scene or the world's clock jumps; call it at a cut the renderer cannot see (a camera switch inside one scene). Nothing is freed: the images stay for the next frame. Result: {reset: "all" or the camera}. Example: render.reset_post_history {}

A camera without such passes is accepted and nothing changes. Errors: `invalid_arguments` for an `entity` that is not a string; `not_found` for an `entity` that does not exist; `unavailable` without graphics (graphics=false). The same is Renderer::reset_post_history in C++.

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name). Default: every camera. |

## `render.supports`

Since 0.31.0.

What this renderer can do on this graphics backend and GPU: float targets, linear colour, HDR output, post effects.

Capabilities: read

Answers from the renderer's table per backend (GL, GLES3, WebGL2, D3D11, Metal, headless) and from what the GPU reports, so a game or a tool can ask before it relies on a feature. Without `feature`: {backend, backendLabel, features: [{name, kind, supported, status, doc, backends}]}; with `feature`: {feature, backend, supported, status}. A feature the renderer does not draw is false with the status "planned (<milestone>)" (the lighting of M73 is, until each part lands): this command never claims what is not drawn. Example: render.supports {"feature":"floatTargets"}

`kind` is capability (a fact of the GPU: floatTargets, r11g11b10, sampledDepth, computeShaders, float32Targets), engine (linearColor, hdrOutput, and the lighting rows of M73: clusteredLights, areaLights, lightCookies, iesProfiles, cascadedShadows, pointShadows, spotShadows, contactShadows, environmentMap, reflectionProbes, physicalSky, lightmaps, lightProbes, volumetricFog, decals, subsurface, realtimeGI, clearCoat, sheen, anisotropy, transmission, and the 2D rows of M74: 2dSoftShadows, 2dShadowCasters, 2dEmission, 2dLightLayers, 2dLightCookies, 2dRimLight, 2dGeneratedNormals, 2dGlobalIllumination, 2dWater, spriteSceneColor, and the big-world rows of M75: lodCrossFade, hlod, impostors, occlusionCpu, occlusionPortals, occlusionGpu, terrain, foliage, and the upscaling rows of M76, drawn: motionVectors, spatialUpscaler, temporalUpscaler, dynamicResolution, metalfx (Metal only: the reason says when this OS or GPU lacks it); temporalAA is the effect row of the same name) or effect (one per PostProcess effect: ssao, ssr, fog, sunShafts, exposure, depthOfField, motionBlur, radialBlur, lensDistortion, chromaticAberration, bloom, tonemap, colorGrading, vignette, sharpen, outline, pixelate, posterize, filmGrain, colorFilter, temporalAA); `backends` says on which backends the feature can ever run. `status` is "supported", "planned (<milestone>)" for an engine feature or effect the renderer does not draw (the M73 lighting rows until their step lands; clusteredLights, areaLights, lightCookies, iesProfiles, lightmaps, lightProbes, reflectionProbes, volumetricFog, subsurface and transmission are drawn), or one sentence that names the backend or the missing GPU capability. hdrOutput is true when the display the window showed its last frame on can show HDR in an encoding the renderer writes (EDR on Metal, scRGB or HDR10 on D3D11), whatever the scene asks; its status otherwise says why (the display or the OS setting); render.output says what the window shows. The headless dummy backend (no GPU) answers false to everything; a headless run with Mesa/EGL is a GL or GLES3 backend like any other. Errors: `invalid_argument` for a `feature` that is not in the list (with a did-you-mean); `unavailable` without graphics (graphics=false). The same answer is Renderer::supports(name) in C++. The whole list also has `limits` {maxTextureSize, maxArrayLayers, maxArrayTextureSize}: the sizes this GPU reports (the Terrain's heightmap, layers, splat maps and holes must fit them).

| Argument | Type | Required | Description |
|---|---|---|---|
| `feature` | string | no | One feature name (floatTargets, r11g11b10, sampledDepth, computeShaders, float32Targets, linearColor, hdrOutput, a lighting feature of M73 such as cascadedShadows, or a post effect such as bloom or ssao). Omitted: every feature. |

## `render.upscaler` (modifies state)

Since 0.36.0.

Reads or changes the upscaler setting: how a picture drawn at a lower resolution reaches the screen.

Capabilities: read, state

The engine-wide upscaler of M76 (docs/UPSCALING.md): `mode` (stretch, spatial, temporal, metalfx, auto), `quality` (native, quality, balanced, performance, ultraPerformance) and `sharpness` (0 to 1). With no argument it returns the setting; with any of the three it changes those and keeps the rest. Returns {mode, quality, sharpness, effectiveMode, scale, changed}: effectiveMode is the mode the renderer really draws with and scale the share of the output's width and height the quality draws. Example: render.upscaler {"mode":"auto","quality":"balanced"}

The renderer draws "stretch", "spatial" (an edge-adaptive upscale and a contrast-adaptive sharpen), "temporal" (the camera is jittered and the frames accumulate in an output-size history) and "metalfx" (Apple's MetalFX on the Metal backend, its temporal scaler on a jittered frame of one camera, its spatial scaler where the GPU has only that one); "auto" picks the best of those. temporal draws as spatial on a frame of several cameras and where its history cannot be made, metalfx draws as temporal (then spatial) where this OS or GPU has no MetalFX or it failed (one warning in the log), and a pixel-perfect display (display.scaleMode) always draws stretch, so effectiveMode says what is on the screen. The game is drawn at window.renderScale times `scale` (never below 0.25) and brought up to the window's size, the HUD at that size; at native quality the spatial mode is the sharpen alone (none at sharpness 0) and temporal draws nothing extra. The start value is factoria.json "render": {"upscaler": {...}}; window.upscaler in scripts is the same setting. A wrong name or number fails with `invalid_argument`, the valid values and a "did you mean", and changes nothing. Works with graphics=false too (the value is only remembered).

| Argument | Type | Required | Description |
|---|---|---|---|
| `mode` | string ["stretch","spatial","temporal","metalfx","auto"] | no | stretch (the plain blit), spatial (edge-adaptive upscale + sharpen), temporal (jittered frames accumulated), metalfx (Apple, Metal only), auto (the best this GPU can draw). |
| `quality` | string ["native","quality","balanced","performance","ultraPerformance"] | no | How much smaller than the output the frame is drawn: 1, 1/1.5, 1/1.7, 1/2, 1/3 of its width and height. |
| `sharpness` | number | no | Contrast-adaptive sharpen strength of the spatial and temporal modes, 0..1. |

## `vfx.budget`

Since 0.17.0.

What an effect document costs on a phone: live particles and the screen they cover, with the fixes.

Capabilities: read

Plays the document in a scratch world with the same timeline and particle sim a game runs (no renderer, no sound, the game is not touched, the same document and seed always give the same numbers) and returns {peakParticles, peakAt, peakOverdraw, peakOverdrawAt, meanOverdraw, settledAt, perEmitter: [{part, name, peakParticles, peakAt, peakOverdraw, maxParticles, capped}], timeline: [{t, particles, overdraw}], findings: [{kind, pointer, message, hint, fix: {command, args}}], notes, limits, ok}. `overdraw` is the sum of the particles' quads in screens (1.0 = as much quad area as the view has; stacked soft sprites are what a phone's GPU pays for). `findings` are what is over the `preset`'s budget (phone: 300 live particles, 1.5 screens, 5 emitters; desktop: 2000, 4.0, 8): each names the JSON pointer and, when one edit helps, carries a vfx.edit call (`fix`) that moves the effect toward it (run vfx.budget again to see where it lands; `fix` is null when no single edit would do). With 3D emitters the numbers also depend on that camera (its lens, and the scene that is loaded), so the same document can give other numbers in another scene. Example: vfx.budget {"path":"assets/vfx/hit.vfx.json"}

The numbers are the particles the sim keeps alive: a camera that does not see them, ribbon trails and glow passes are not counted. A 3D emitter's size is in world units, so its overdraw is measured through the project's main camera (the active primary Camera with the lowest depth in the loaded scene): its quads are projected with the effect 5 m in front of the camera, on its axis (a perspective or an orthographic camera; a quad partly outside the view counts whole). `camera` in the result says which was used ({used:true, projection, distance, fov | height}); when there is no camera (no scene loaded, or none in it) a 3D emitter's particles are counted but its overdraw is 0 and not measured, and `camera` is {used:false, reason} and `notes` says so.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json". |
| `preset` | string ["phone","desktop"] | no | Whose budget the findings use. Default "phone". |
| `seed` | integer | no | Seed of the particle sim: a different seed is a different (equally valid) roll of the random spread. Default 1. |
| `view` | array | no | [width, height] of the view in design pixels that overdraw is measured against. Default: the project's design size. |

## `vfx.check`

Since 0.17.0.

Read an effect document (*.vfx.json) and list every problem, with its JSON pointer and the fix.

Capabilities: read

Returns {ok, path, duration, parts: [{index, name, type, at, duration}], errors: [{pointer, message, hint}], warnings: [...]}. Errors stop the effect from playing; warnings (a `rate` with no duration, too many live particles) do not. A sound whose file is missing is an error. Example: vfx.check {"path":"assets/vfx/hit.vfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project path of the effect document, e.g. "assets/vfx/hit.vfx.json". |

## `vfx.filmstrip` (modifies state)

Since 0.17.0.

Film an effect playing in the game: one picture with a grid of frames, to see its timing and look at once.

Capabilities: read, state

Plays the effect at `position` (default: in a 2D game the world point in the middle of the view; in a 3D game the point 5 m in front of the main 3D camera, on its axis, which the result says in `positionNote`), steps the game and captures `region` at each step into one labelled grid PNG (label "f3 +100" = picture 3, 100 ms after the effect started), then removes the effect. THE GAME ADVANCES: the clock, the physics and the scripts run for the frames the strip takes (about 3 s at most by default), so film on a stage scene or a paused moment; the camera and the backdrop are the ones the game has, which is what the effect must read against. The first picture is the frame after the effect started. By default the strip covers the effect's length (from vfx.budget, at most 3 s) in `frames` pictures; `everyFrames` sets the game frames between two pictures instead. The view is `size` design pixels around the effect, `region` [x, y, width, height] overrides it, and `zoom` magnifies (default: a sheet about 1600 px wide). At most 64 pictures, a sheet at most 8192 px a side. Needs graphics. Example: vfx.filmstrip {"effect":"assets/vfx/hit.vfx.json","position":[640,360],"frames":12}

Without `path` the picture is temporary (the MCP server shows it then deletes the file). The effect's sound and command parts really act on the game (a feel.hitStop stretches the labelled times, an audio.music keeps playing, a feel.spawn leaves its prefab). A `position` the camera cannot project into the view fails (it is behind the camera: aim the camera or give `region`). Result: {path (only with `path`), effect, duration, width, height, frames: [{index, frame, t}], columns, rows, tileWidth, tileHeight, zoom, everyFrames, region, position: [x, y, z] (where it played), positionDefault (true when `position` was left out), positionNote (only then: which default was used), $image}. vfx.review gives the picture to a vision model with the budget numbers.

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
| `path` | string | no | Keep the PNG here, inside the project (needs the writeProject capability; absolute paths need writeAnywhere, and the managed folders are refused). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |

## `vfx.list`

Since 0.17.0.

The effects that play now, and the limits of an effect.

Capabilities: read

Returns {playing: [{id, effect, time, duration, loop, speed}], count, max, limits}. `time` is seconds into the effect (the document's own clock), `duration` its length. An effect started by vfx.play counts at once, before the next step (time 0). Use it in a test to see that an effect started and ended: game.step, then vfx.list. Example: vfx.list {}.

## `vfx.play` (modifies state)

Since 0.17.0.

Play an effect document (*.vfx.json) at a position, or on an entity.

Capabilities: read, state

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

Capabilities: read, state, network, process, spend

The last look of the make, film, grade, fix loop for effects (docs/PARTICLES.md "Reviewing an effect"). It runs vfx.budget on the document and vfx.filmstrip on the running game (so THE GAME ADVANCES by about the length of the effect, at most 3 s, and the game must have graphics), then sends a vision model the filmstrip, the budget numbers and the document with a checklist: readability at game size, timing, palette, overdraw. It uses the model of the "fast" role of ai.json (the orchestrator when fast is off), so the model must accept pictures; with no provider, no key or a text-only model the error says what to set up (docs/AI_PROVIDERS.md) and you carry on with vfx.budget and vfx.filmstrip, which you can read yourself. One model call per review: call it once vfx.check passes and vfx.budget has no finding, not after every edit. Example: {"effect":"assets/vfx/hit.vfx.json","position":[640,360],"focus":"does it read on the dark floor?"}

Result: {verdict: good | fix | redo (never `good` while vfx.budget has a finding), summary, checklist: [{item, grade, note}], fixes: [{what, where, command}], budget: {peakParticles, peakOverdraw, findings, ...}, filmstrip: {frames, columns, rows, tileWidth, tileHeight, zoom, region, position (where it was filmed), positionDefault, positionNote}, role, provider, model, warnings, nextSteps}. A fix names a command, usually a vfx.edit call; one that names something this engine does not have is listed in `warnings`. The document is not changed. Pass `picturePath` to keep the filmstrip PNG.

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

Capabilities: read, state

`immediate` true removes the effect's entity and its children at once (particles vanish); the default lets the emitters stop emitting and their particles finish, ends the lights, and the parts that had not started never do. Example: vfx.stop {"id":"vfx_hit_3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | The entity (id or name) with the Vfx, as vfx.play returned it. |
| `immediate` | boolean | no | Remove it now instead of letting its particles finish. Default false. |

