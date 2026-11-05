[Back to the index](../README.md)

# Commands: feel

## `feel.cancel` (modifies state)

Not released yet (on main after 0.16.1).

Ends the game feel effects of an entity at once (flash, squash, shake, knockback), or of everything.

Without `entity` it ends every effect of the scene, hit-stops included. The entity's Transform is not touched: effects never wrote to it, except the position a body-less knockback already moved. Example: feel.cancel {}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | The entity (id or name). Default: everything. |

## `feel.flash` (modifies state)

Not released yet (on main after 0.16.1).

Draws an entity in one colour for a moment (a hit flash): sprites, shapes and 3D meshes, fading or square.

The same as `entity.flash(opts)`. The entity's own colour, material and Transform never change. Children are flashed with it. Text, Tilemap, particles and UI are not flashed. With the player's reducedEffects on (feel.settings, else the system's reduce motion) the strength is capped at 0.35 and the flash always fades, never a full-bright strobe. Example: feel.flash {"entity":"enemy","color":"#ffffff","duration":0.1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity (id or name). |
| `color` | any | no | The colour: "#rrggbb", a name or [r, g, b, a] in 0..1. Default white. Alpha is ignored. |
| `duration` | number | no | Seconds. Default 0.12. |
| `fade` | boolean | no | true: from `strength` down to 0; false: `strength` for the whole duration, then off. Default true. |
| `strength` | number | no | How much of the colour replaces the entity's own (1 = solid). Default 1. |

## `feel.hitStop` (modifies state)

Not released yet (on main after 0.16.1).

Hit-stop: freezes or slows gameplay for a moment of real time; UI, audio and the stop's own timer keep going.

The same as `time.hitStop(seconds, opts)`. Physics, onUpdate/onFixedUpdate, timers, particles and sprite animators stop (or slow to `scale`); the UI, audio, runWhilePaused behaviours, shake, flashes and squash keep running; `time.scale` and `game.paused` do not change. Overlapping calls do not add up: the longest wins and the smallest scale applies while they overlap. With reduceMotion on the duration is halved. The timer is REAL time: `game.step` frames count their fixed step. Example: feel.hitStop {"duration":0.08}

| Argument | Type | Required | Description |
|---|---|---|---|
| `duration` | number | no | Real seconds. Default 0.08. |
| `scale` | number | no | Game-time scale during the stop: 0 freezes, 0.2 is slow motion. Default 0. |

## `feel.knockback` (modifies state)

Not released yet (on main after 0.16.1).

Pushes an entity away and holds `isKnockedBack` for a moment: an impulse on its physics body, else a decaying velocity.

The same as `entity.knockback(direction, opts)`. A dynamic RigidBody2D/RigidBody3D gets `speed` added to its velocity; an entity without one moves with a velocity that decays by exp(-decay * dt) on the fixed clock. For `lockTime` seconds `entity.isKnockedBack` is true: the movement script leaves the player without control. A hit-stop freezes it. Example: feel.knockback {"entity":"player","direction":[-1,0.3],"speed":8}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity (id or name). |
| `direction` | array | no | Which way, [x, y] or [x, y, z]; any length, it is normalised. Default [1,0]. |
| `speed` | number | no | World units per second added at once. Default: 6 metres per second, which is 6 units for a 3D entity and 6 times physics.pixelsPerMeter (600 pixels per second at 100) for a 2D one. |
| `lockTime` | number | no | Seconds isKnockedBack stays true. Default 0.25. |
| `decay` | number | no | Entities without a dynamic body: the velocity falls by exp(-decay * dt) per second. Default 8. |

## `feel.settings` (modifies state)

Not released yet (on main after 0.16.1).

The accessibility choices of the game feel effects: reduceMotion and reducedEffects.

The same as `feel.reduceMotion` / `feel.reducedEffects` in a script. true or false is the player's choice, null follows the operating system's reduce motion again; a missing key stays as it is. reduceMotion shrinks shake and squash to a quarter and halves hit-stops; reducedEffects caps flashes at 0.35 and makes them fade. Applies to effects started afterwards. Returns the values in force. Example: feel.settings {"reduceMotion":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `reduceMotion` | any | no | true / false = the player's choice; null = follow the system. |
| `reducedEffects` | any | no | true / false = the player's choice; null = follow the system. |

## `feel.shake` (modifies state)

Not released yet (on main after 0.16.1).

Camera shake: adds trauma to a camera (2D and 3D); it stacks up to `cap` and dies out over `duration`.

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

## `feel.squash` (modifies state)

Not released yet (on main after 0.16.1).

Squash and stretch: a short scale pulse that keeps the volume and springs back to exactly the entity's scale.

The same as `entity.squash(opts)`. The pulse is drawn on top of the entity's own scale (volume kept: x * y in 2D, x * y * z with a mesh); `entity.scale` is never written, so nothing is left behind. amount > 0 squashes, < 0 stretches. With reduceMotion on the amount is a quarter. Example: feel.squash {"entity":"player","amount":0.35,"duration":0.25}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | The entity (id or name). |
| `amount` | number | no | > 0 squashes (flatter and wider), < 0 stretches (taller and thinner). Default 0.3. |
| `duration` | number | no | Seconds until the entity is back to its own scale. Default 0.3. |
| `axis` | string ["x","y"] | no | The axis that gets shorter when amount > 0. Default "y". |

## `feel.state`

Not released yet (on main after 0.16.1).

What the game feel effects are doing now: hit-stop, and per entity its shake, flash, squash, knockback and drawn pose.

Returns {reduceMotion, reducedEffects, reduceMotionSetting, reducedEffectsSetting, hitStop: {remaining, scale, running}, entities: [{entity, shake?, flash?, squash?, knockback?, pose?}]}. `pose` is what is added to the entity at draw time (position, rotation degrees, scale factor); its Transform is unchanged. Example: feel.state {}

