[Back to the index](../README.md)

# Commands: feel

## `feel.cancel` (modifies state)

Since 0.17.0.

Ends the game feel effects of an entity at once (flash, squash, shake, knockback, and the screen effects of a camera), or of everything.

Capabilities: read, state

Without `entity` it ends every effect of the scene, hit-stops and screen effects (a held fade too) included. For a camera it ends the screen effects drawn on that camera only. The entity's Transform is not touched: effects never wrote to it, except the position a body-less knockback already moved. Example: feel.cancel {}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The entity (id or name). Default: everything. |

## `feel.fade` (modifies state)

Since 0.31.0.

Fades the screen to a colour (default black) and holds it, or from that colour back to the picture.

Capabilities: read, state

The same as `camera.fadeOut(opts)` / `camera.fadeIn(opts)`. direction "out" goes from the picture to the colour over `duration` and STAYS there until a fade in or feel.cancel; "in" goes from the colour to the picture and ends (with no fade running it starts from the full colour: the way to open a scene). A new fade on the camera continues from the opacity the old one had reached. Drawn over the picture at the end of the camera's post pass, before the colour filter. `entity` limits it to one camera. A scene load clears it. Example: feel.fade {"direction":"out","duration":0.8}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name) that draws it. Default: every camera. |
| `direction` | string ["out","in"] | no | "out": to the colour (held); "in": from the colour to the picture. Default "out". |
| `color` | any | no | The colour: "#rrggbb", a name or [r, g, b, a] in 0..1. Default black. Alpha is ignored. |
| `duration` | number | no | Seconds; 0 is instant. Default 0.5. |

## `feel.flash` (modifies state)

Since 0.17.0.

Draws an entity in one colour for a moment (a hit flash): sprites, shapes and 3D meshes, fading or square.

Capabilities: read, state

The same as `entity.flash(opts)`. The entity's own colour, material and Transform never change. Children are flashed with it. Text, Tilemap, particles and UI are not flashed. With the player's reducedEffects on (feel.settings, else the system's reduce motion) the strength is capped at 0.35 and the flash always fades, never a full-bright strobe. Example: feel.flash {"entity":"enemy","color":"#ffffff","duration":0.1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity (id or name). |
| `color` | any | no | The colour: "#rrggbb", a name or [r, g, b, a] in 0..1. Default white. Alpha is ignored. |
| `duration` | number | no | Seconds. Default 0.12. |
| `fade` | boolean | no | true: from `strength` down to 0; false: `strength` for the whole duration, then off. Default true. |
| `strength` | number | no | How much of the colour replaces the entity's own (1 = solid). Default 1. |

## `feel.heatHaze` (modifies state)

Since 0.31.0.

Heat haze: a rippling distortion over a region of the screen for a while.

Capabilities: read, state

The same as `camera.heatHaze(opts)`. The picture inside `region` is pushed sideways by a smooth ripple that travels upwards; it fades in and out over 0.15 s at its ends. Strength is a fraction of the picture's height (0.004 is a gentle shimmer). `entity` limits it to one camera; a camera draws the newest 2 hazes. Runs on the game clock. With reduceMotion on the strength is a quarter. Example: feel.heatHaze {"region":[0,0.5,1,0.5],"duration":3}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name) that draws it. Default: every camera. |
| `region` | array | no | [x, y, width, height] in fractions of the camera's rectangle, (0, 0) top-left. Default [0,0,1,1]. |
| `duration` | number | no | Seconds. Default 2. |
| `strength` | number | no | How far the picture is pushed, a fraction of its height. Default 0.004. |
| `frequency` | number | no | Ripples per picture height. Default 10. |
| `speed` | number | no | Cycles per second the ripples travel. Default 1. |

## `feel.hitStop` (modifies state)

Since 0.17.0.

Hit-stop: freezes or slows gameplay for a moment of real time; UI, audio and the stop's own timer keep going.

Capabilities: read, state

The same as `time.hitStop(seconds, opts)`. Physics, onUpdate/onFixedUpdate, timers, particles and sprite animators stop (or slow to `scale`); the UI, audio, runWhilePaused behaviours, shake, flashes and squash keep running; `time.scale` and `game.paused` do not change. Overlapping calls do not add up: the longest wins and the smallest scale applies while they overlap. With reduceMotion on the duration is halved. The timer is REAL time: `game.step` frames count their fixed step. Example: feel.hitStop {"duration":0.08}

| Argument | Type | Required | Description |
|---|---|---|---|
| `duration` | number | no | Real seconds. Default 0.08. |
| `scale` | number | no | Game-time scale during the stop: 0 freezes, 0.2 is slow motion. Default 0. |

## `feel.knockback` (modifies state)

Since 0.17.0.

Pushes an entity away and holds `isKnockedBack` for a moment: an impulse on its physics body, else a decaying velocity.

Capabilities: read, state

The same as `entity.knockback(direction, opts)`. A dynamic RigidBody2D/RigidBody3D gets `speed` added to its velocity; an entity without one moves with a velocity that decays by exp(-decay * dt) on the fixed clock. For `lockTime` seconds `entity.isKnockedBack` is true: the movement script leaves the player without control. A hit-stop freezes it. Example: feel.knockback {"entity":"player","direction":[-1,0.3],"speed":8}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity (id or name). |
| `direction` | array | no | Which way, [x, y] or [x, y, z]; any length, it is normalised. Default [1,0]. |
| `speed` | number | no | World units per second added at once. Default: 6 metres per second, which is 6 units for a 3D entity and 6 times physics.pixelsPerMeter (600 pixels per second at 100) for a 2D one. |
| `lockTime` | number | no | Seconds isKnockedBack stays true. Default 0.25. |
| `decay` | number | no | Entities without a dynamic body: the velocity falls by exp(-decay * dt) per second. Default 8. |
| `local` | boolean | no | true: `direction` is in the entity's own space (a mirrored sprite is pushed the other way). Default false. |

## `feel.radialBlur` (modifies state)

Since 0.31.0.

A radial blur pulse: the picture streaks away from a point and settles, for a speed or impact burst.

Capabilities: read, state

The same as `camera.radialBlur(opts)`. Draws the same blur as PostProcess.radialBlurEnabled, with an intensity that dies out over `duration`; when the camera's PostProcess has the blur on, the larger of the two is drawn. `screen` or `world` is the centre (see feel.shockwave). `entity` limits it to one camera. With reduceMotion on the intensity is a quarter. Example: feel.radialBlur {"intensity":0.5,"duration":0.4}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name) that draws it. Default: every camera. |
| `screen` | array | no | The centre, [x, y] in fractions of the camera's rectangle. Default [0.5,0.5]. |
| `world` | array | no | The centre as a world point; wins over `screen`. |
| `duration` | number | no | Seconds until the blur is gone. Default 0.35. |
| `intensity` | number | no | The blur at the start, same scale as PostProcess.radialBlurIntensity. Default 0.4. |
| `samples` | integer | no | Taps along each streak: more is smoother and costs more. Default 12. |

## `feel.screenFlash` (modifies state)

Since 0.31.0.

Flashes the whole screen in one colour for a moment (a damage or pickup flash), drawn over the finished picture.

Capabilities: read, state

The same as `camera.flash(opts)`. Not to be confused with feel.flash, which flashes one entity. The colour is blended over the picture at the end of the camera's post pass (before the colour filter), at `strength` and fading to 0 over `duration` (or held, with fade false). With reducedEffects on (feel.settings) the strength is capped at 0.35 and it always fades. `entity` limits it to one camera. Example: feel.screenFlash {"color":"#ffffff","duration":0.15}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name) that draws it. Default: every camera. |
| `color` | any | no | The colour: "#rrggbb", a name or [r, g, b, a] in 0..1. Default white. Alpha is ignored. |
| `duration` | number | no | Seconds. Default 0.15. |
| `strength` | number | no | How much of the colour covers the picture at the start. Default 1. |
| `fade` | boolean | no | true: from `strength` down to 0; false: `strength` for the whole duration, then off. Default true. |

## `feel.settings` (modifies state)

Since 0.17.0.

The accessibility choices of the game feel effects: reduceMotion and reducedEffects.

Capabilities: read, state

The same as `feel.reduceMotion` / `feel.reducedEffects` in a script. true or false is the player's choice, null follows the operating system's reduce motion again; a missing key stays as it is. reduceMotion shrinks shake and squash to a quarter and halves hit-stops; reducedEffects caps flashes at 0.35 and makes them fade. Applies to effects started afterwards. Returns the values in force. Example: feel.settings {"reduceMotion":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `reduceMotion` | any | no | true / false = the player's choice; null = follow the system. |
| `reducedEffects` | any | no | true / false = the player's choice; null = follow the system. |

## `feel.shake` (modifies state)

Since 0.17.0.

Camera shake: adds trauma to a camera (2D and 3D); it stacks up to `cap` and dies out over `duration`.

Capabilities: read, state

The same as `camera.shake(amount, opts)` in a script. Adds `amount` (0..1) of trauma; the shake is trauma squared, smooth noise seeded from the world's RNG (deterministic), and only what is DRAWN moves: the camera's Transform does not change. A 2D camera moves in x, y and roll, a 3D one also looks a little around. With the player's reduceMotion on (feel.settings, else the system's) the amount is a quarter. Example: feel.shake {"amount":0.5,"duration":0.3}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name). Default: the first camera drawn (camera.main). |
| `amount` | number | no | Trauma to add, 0..1. Default 0.4. |
| `duration` | number | no | Seconds the shake takes to die out (a longer one already running is kept). Default 0.4. |
| `frequency` | number | no | Noise samples per second: how jittery. Default 25. |
| `maxOffset` | number | no | Largest offset at trauma 1, world units. Default: 2.5% of an orthographic camera's visible height, 0.3 for a perspective one. |
| `maxAngle` | number | no | Largest turn at trauma 1, degrees. Default 2. |
| `cap` | number | no | Trauma never goes above this: stacked hits stop here. Default 1. |

## `feel.shockwave` (modifies state)

Since 0.31.0.

Screen shockwave: a ring that expands from a point and bends the picture, drawn by the camera's post-processing pass.

Capabilities: read, state

The same as `camera.shockwave(opts)` in a script. The ring leaves the centre fast and slows down, and its push dies out as it grows. `screen` is the centre as fractions of the camera's rectangle ((0.5, 0.5) is the middle, (0, 0) top-left); `world` is a world point each camera projects itself (it is not drawn behind a perspective camera) and wins over `screen`. Strength, radius and width are fractions of the picture's height, so the ring looks the same at every resolution. `entity` limits it to one camera (a split screen); without it every camera draws it. At most 16 screen effects are alive and a camera draws the newest 4 shockwaves; a new call never fails, the oldest effect goes. It runs on the game clock (time.scale 0 holds it) and needs no PostProcess component. With reduceMotion on (feel.settings) the strength is a quarter. Example: feel.shockwave {"screen":[0.5,0.4],"strength":0.05,"duration":0.7}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The camera (id or name) that draws it. Default: every camera. |
| `screen` | array | no | The centre, [x, y] in fractions of the camera's rectangle. Default [0.5,0.5]. |
| `world` | array | no | The centre as a world point [x, y] or [x, y, z]; wins over `screen`. |
| `duration` | number | no | Seconds until the ring is gone. Default 0.6. |
| `strength` | number | no | How far the ring pushes the picture, a fraction of its height. Default 0.04. |
| `radius` | number | no | The radius the ring reaches, a fraction of the picture's height. Default 0.6. |
| `width` | number | no | The width of the ring, same unit. Default 0.1. |

## `feel.sound` (modifies state)

Since 0.17.0.

Plays a sound once through the audio system (the same one a clip event's "sound" action uses).

Capabilities: read, state

The sound starts on the next audio update, on its bus, and shows in `audio.log` like any other play. Example: feel.sound {"path":"audio/hit.wav","volume":0.8,"pitch":1.1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The entity the sound belongs to (id or name); optional, only named in logs. |
| `path` | string | yes | Project-relative path of the sound. |
| `volume` | number | no | Volume. Default 1. |
| `pitch` | number | no | Playback speed and pitch. Default 1. |
| `pan` | number | no | -1 left to 1 right. Default 0. |
| `bus` | string | no | "sfx", "music", "ui" or a bus of the project. Default "sfx". |

## `feel.spawn` (modifies state)

Since 0.17.0.

Makes an effect appear: instantiates a prefab at an entity (or at a point) the next frame.

Capabilities: read, state

The same as the "spawn" action of a clip event (docs/GAME_FEEL.md, "Effects as data"). The prefab appears at the entity's world position plus `offset`, or at `offset` itself without an entity, the next time the frame's game feel pass runs. Spawned entities are left out of saved scenes. Give `lifetime` to have it destroyed after that many seconds; without it the prefab has to end itself. Example: feel.spawn {"entity":"enemy","prefab":"prefabs/hit_spark.prefab.json","lifetime":0.4}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The entity the effect appears at (id or name). Default: the world origin plus `offset`. |
| `prefab` | string | yes | Project-relative path of the prefab. |
| `offset` | array | no | Added to the entity's world position, [x, y] or [x, y, z]. Default [0,0]. |
| `local` | boolean | no | true: `offset` is in the entity's own space (a mirrored sprite puts it on the other side). Default false. |
| `lifetime` | number | no | Seconds of game time until the spawned entity is destroyed (a hit-stop, time.scale 0 or a pause holds the count); 0 = the prefab ends itself. Default 0. |

## `feel.squash` (modifies state)

Since 0.17.0.

Squash and stretch: a short scale pulse that keeps the volume and springs back to exactly the entity's scale.

Capabilities: read, state

The same as `entity.squash(opts)`. The pulse is drawn on top of the entity's own scale (volume kept: x * y in 2D, x * y * z with a mesh); `entity.scale` is never written, so nothing is left behind. amount > 0 squashes, < 0 stretches. With reduceMotion on the amount is a quarter. Example: feel.squash {"entity":"player","amount":0.35,"duration":0.25}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity (id or name). |
| `amount` | number | no | > 0 squashes (flatter and wider), < 0 stretches (taller and thinner). Default 0.3. |
| `duration` | number | no | Seconds until the entity is back to its own scale. Default 0.3. |
| `axis` | string ["x","y"] | no | The axis that gets shorter when amount > 0. Default "y". |

## `feel.state`

Since 0.17.0.

What the game feel effects are doing now: hit-stop, and per entity its shake, flash, squash, knockback and drawn pose.

Capabilities: read

Returns {reduceMotion, reducedEffects, reduceMotionSetting, reducedEffectsSetting, hitStop: {remaining, scale, running}, queued: {sounds, spawns, spawnLifetimes} (sounds and spawns waiting for the next frame, spawned effects that will be destroyed), screenEffects: [{kind, camera (null = every camera), elapsed, duration, alpha? (flash, fade), held? (fade)}], entities: [{entity, shake?, flash?, squash?, knockback?, pose?}]}. `pose` is what is added to the entity at draw time (position, rotation degrees, scale factor); its Transform is unchanged. Example: feel.state {}

