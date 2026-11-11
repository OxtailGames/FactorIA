[Back to the index](../README.md)

# Commands: anim

## `anim.add_event` (modifies state)

Since 0.7.0.

Add an event to a clip: a game event and/or game feel actions run when the clip passes its time.

The event {t, name?, data?, feel?} reaches world.on(name, fn) and entity.animator.on(name, fn) with {id, clip, time} plus `data` (an object; the keys id, clip and time are reserved), once per loop. `feel` is one game feel action or an array of them (hitStop, shake, flash, knockback or push, squash, spawn, sound: docs/GAME_FEEL.md, "Effects as data"), run on the entity that plays the clip; they are checked now, so a typo is refused with the option names. An event needs `name` or `feel`. Events stay sorted by t. A time past the duration is refused unless `extendDuration`. Result: {path, event (index), undo}. Example: anim.add_event {"path":"anim/hero_attack.anim.json","t":0.3,"feel":[{"action":"hitStop","duration":0.06},{"action":"shake","amount":0.3}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `t` | number | yes | Seconds from the start of the clip. |
| `name` | string | no | The game event name. Optional when `feel` is given. |
| `data` | object | no | Extra fields sent with the event. |
| `feel` | any | no | Game feel action(s) to run, each {action: shake\|hitStop\|flash\|knockback\|push\|squash\|spawn\|sound, ...options}. |
| `extendDuration` | boolean | no |  Default false. |

## `anim.add_track` (modifies state)

Since 0.7.0.

Add a track to a clip, with keys or the part's current value as its first key.

`track` is {path, component?, field}. Give `keys` (as anim.set_keys), or `entity` (the entity that plays the clip) to start the track with one key at t=0 holding the part's current value; with neither it is refused. An existing track of the same field is refused (use anim.set_keys to edit it); two tracks may not drive the same field channel. Result: {path, track (index), keys, undo}. Example: anim.add_track {"path":"anim/hero_walk.anim.json","track":{"path":"body","field":"position.y"},"entity":"hero"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `keys` | array | no | The first keys [{t, value, interp?}]. |
| `entity` | string | no | Entity that plays the clip: checks the part and gives the first key its current value. |
| `extendDuration` | boolean | no | Raise the duration when a key is later than it. Default false. |
| `track` | object | yes |  |

## `anim.check` (modifies state)

Since 0.7.0.

Find what is wrong with a clip, and with how it fits its character.

Checks clips and returns {checked, findings, ok, samples, notes}. Each finding is {kind, severity, clip, track?, part?, message, hint}: it names the track or part and says how to fix it. Kinds: `no_change` (a track whose keys all hold one value), `loop_jump` (a looping clip whose last pose differs from its first, so it snaps every cycle; angles take the short way round), `unknown_part` (a track that names no part of the entity, or a part without the component), `leaves_view` (a part that is in the camera view in some poses and completely outside it in others), `ik_out_of_reach` (an IK2D whose target cannot be reached in some poses) and `invalid_clip` (the file does not load). With `path` alone only the first two run (the clip file alone); with `entity` the clip is also posed `samples` times along its length (the entity is put back as it was) for the rest, and all of the Animator's clips are checked unless `clip` names one. Example: anim.check {"entity":"hero"} or anim.check {"path":"anim/hero_walk.anim.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | Entity with the Animator whose clips to check (id or name). |
| `path` | string | no | One clip file to check (with `entity`: checked against that entity). |
| `clip` | string | no | With `entity`: check only this clip of Animator.clips. |
| `samples` | integer | no | Poses to check along the clip. Default 24. |

## `anim.create_clip` (modifies state)

Since 0.7.0.

Write a new keyframed 2D clip file (*.anim.json).

Creates the file with `duration` seconds, `loop`, and optionally its `tracks` and `events` in the format of docs/ANIMATION.md ("2D clips", schemas/anim.schema.json). Everything is checked with the loader's own rules and nothing is written if it is wrong (errors name the JSON pointer). It refuses to replace a file unless `overwrite` is true. Result: {path, duration, loop, tracks, events, undo} where `undo` is {command, args} that puts the file back (or deletes the new file); run it with anim.restore. Then add keys with anim.set_keys and play it from an Animator: Animator.clips {"walk": path}. Example: anim.create_clip {"path":"anim/hero_walk.anim.json","duration":0.8,"loop":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file ending in .anim.json. |
| `duration` | number | yes | Length of the clip in seconds. |
| `loop` | boolean | no | true repeats the clip, false stops on the last pose (anim.finished). Default true. |
| `doc` | string | no | What the clip shows. |
| `tracks` | array | no | Tracks [{path, component, field, keys:[{t, value, interp?}]}]; none = an empty clip to fill with anim.set_keys. |
| `events` | array | no | Events [{t, name?, data?, feel?}]: a game event and/or game feel actions run when the clip passes t. |
| `overwrite` | boolean | no | Replace the file if it exists. Default false. |

## `anim.filmstrip`

Since 0.7.0.

One picture with a grid of a clip's poses, to see the whole motion at once.

Poses the entity as `clip` at `frames` evenly spaced times (a looping clip: 0, d/n, ... never the duplicate end pose; otherwise 0 .. duration) and captures each, into one labelled grid PNG (label "f3 +250" = pose 3, 250 ms into the clip). The game is not stepped: only the pose changes, and the entity is put back as it was afterwards. By default the view is the box around the entity's visuals over all poses (plus a margin), magnified so the sheet is about 1600 px wide; `region` [x, y, width, height] (design pixels) and `zoom` override it. `onionSkin: true` draws each pose over faint copies of the previous and next ones, so a stride or a swing shows its arc and a jump between two poses shows as a double image. At most 64 poses, a sheet at most 8192 px a side. Needs graphics. Without `path` the picture is temporary (the MCP server shows it then deletes the file); with `path` it is kept. Result: {width, height, frames: [{index, t}], columns, rows, tileWidth, tileHeight, zoom, region, $image}. Example: anim.filmstrip {"entity":"hero","clip":"walk","frames":8,"onionSkin":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity with the Animator (id or name). |
| `clip` | string | yes | Clip name from Animator.clips, or its file. |
| `frames` | integer | no | Number of poses. Default 8. |
| `columns` | integer | no | Tiles per row (default: nearly square). |
| `onionSkin` | boolean | no | Draw faint copies of the neighbouring poses under each pose. Default false. |
| `region` | array | no | [x, y, width, height] in design pixels; default: around the character. |
| `zoom` | number | no | Magnification of the region (default: a sheet about 1600 px wide). |
| `path` | string | no | Keep the PNG here (project-relative or absolute). |

## `anim.list`

Since 0.7.0.

List the 2D clips of an entity's Animator (or of a clip file): tracks, events, layers and the current state.

With `entity`: its Animator's state (`clip`, `time`, `playing`, `state`, `speed`, `loop`), its `layers` and every clip of Animator.clips as {name, file, duration, loop, tracks: [{index, path, component, field, keys, first, last, stepped}], events: [{t, name}], problems}; `problems` lists tracks that name no part of this entity, and a clip file that does not load has `error` and `issues` instead. With `path`: the same description of one clip file (no entity). With neither: every Animator that plays clip files in the scene. `full: true` adds `source`, the whole file, for editors. The track `index` is what the anim.* editing commands accept as `track`. Example: anim.list {"entity":"hero"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | Entity with the Animator (id or name). |
| `path` | string | no | A clip file to describe on its own. |
| `full` | boolean | no | Include `source`, the whole clip document. Default false. |

## `anim.move_event` (modifies state)

Since 0.7.0.

Move an event of a clip to another time.

`event` is the event's index in the clip's events, or {t, name?} (name needed when two events share the time). Events stay sorted, so the index in the result is the new one. Result: {path, event, from, to, undo}. Example: anim.move_event {"path":"anim/hero_walk.anim.json","event":{"t":0.2,"name":"footstep"},"to":0.25}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `event` | any | yes | Index of the event, or {t, name?}. |
| `to` | number | yes | The new time in seconds. |
| `extendDuration` | boolean | no |  Default false. |

## `anim.move_keys` (modifies state)

Since 0.7.0.

Move and scale a selection of keys in time.

`keys` selects keys as [{track, t}] (`track` is the index in the clip's tracks or {path, component, field}; anim.list shows them). Each selected key goes to `pivot + (t - pivot) * scale + offset` (scale first, about `pivot`; the default pivot is the earliest selected key, scale 1, offset 0). Keys that are not selected stay. Refused (nothing written) when a key would land on another key of its track, before 0, or after the duration (unless `extendDuration`). Result: {path, moved, keys: [{track, from, to}], undo}. Example: slow the swing down by half from its start: anim.move_keys {"path":"anim/hero_walk.anim.json","keys":[{"track":0,"t":0.2},{"track":0,"t":0.4}],"scale":2,"extendDuration":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `keys` | array | yes |  |
| `offset` | number | no | Seconds added after scaling (negative moves earlier). Default 0. |
| `scale` | number | no | Time scale about the pivot: 2 doubles the spacing, 0.5 halves it. Default 1. |
| `pivot` | number | no | Seconds the scale is about (default: the earliest selected key). |
| `extendDuration` | boolean | no | Raise the duration when a key moves past it. Default false. |

## `anim.pose` (modifies state)

Since 0.7.0.

Pose an entity as one of its clips is at a time, and leave it there.

`clip` is a name of Animator.clips (or the file one of them names), `t` seconds into it (clamped to the clip). The entity's parts, bones, skins and IK take that pose and the Animator pauses there until play() or a new `clip`; save the scene only if you want the pose kept. Result: {entity, clip, t, duration, values: [{track, value}]} with the sampled value of every track. Use it with game.screenshot to look at one pose, or anim.filmstrip to look at many. Example: anim.pose {"entity":"hero","clip":"walk","t":0.2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity with the Animator (id or name). |
| `clip` | string | yes | Clip name from Animator.clips, or its file. |
| `t` | number | no | Seconds into the clip. Default 0. |

## `anim.remove_event` (modifies state)

Since 0.7.0.

Remove an event from a clip.

`event` is the event's index, or {t, name?}. Result: {path, removed: {t, name?, data?, feel?}, undo}. Example: anim.remove_event {"path":"anim/hero_walk.anim.json","event":{"t":0.2,"name":"footstep"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `event` | any | yes | Index of the event, or {t, name?}. |

## `anim.remove_keys` (modifies state)

Since 0.7.0.

Remove keys of one track of a clip, by time or all of them.

`times` lists the times (seconds) of the keys to remove; each must be a key of the track (the error lists its times). `all` removes every key, which removes the track (a track needs at least one key). Result: {path, removed, trackRemoved, undo}. Example: anim.remove_keys {"path":"anim/hero_walk.anim.json","track":{"path":"body","field":"rotation.z"},"times":[0.4]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `times` | array | no | Times of the keys to remove. |
| `all` | boolean | no | Remove every key (and so the track). Default false. |
| `track` | any | yes | Index in the clip's tracks, or {path, component, field}. |

## `anim.remove_track` (modifies state)

Since 0.7.0.

Remove a whole track (all its keys) from a clip.

`track` is the index in the clip's tracks or {path, component, field}. The tracks after it shift down by one. Result: {path, removed: {path, component, field, keys}, undo}. Example: anim.remove_track {"path":"anim/hero_walk.anim.json","track":{"path":"body","field":"rotation.z"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `track` | any | yes | Index in the clip's tracks, or {path, component, field}. |

## `anim.restore` (modifies state)

Since 0.7.0.

Put a clip file back to a whole document, or delete it: the undo and redo of the anim.* edits.

Every editing command returns `undo` = {command: "anim.restore", args: {path, clip}}; calling it writes `clip` (the whole previous document, checked like any clip) or, when `clip` is null, deletes the file (the undo of anim.create_clip). Its own result carries the `undo` that goes forward again (redo). Example: anim.restore {"path":"anim/hero_walk.anim.json","clip":null}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `clip` | any | yes | The whole clip document to write, or null to delete the file. |

## `anim.set_clip` (modifies state)

Since 0.7.0.

Set the duration, loop or description of a clip.

Give any of `duration` (seconds), `loop` and `doc`. A duration shorter than the last key or event is refused, naming the key (move it with anim.move_keys first). Result: {path, duration, loop, undo}. Example: anim.set_clip {"path":"anim/hero_walk.anim.json","duration":1.2,"loop":false}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `duration` | number | no | Length of the clip in seconds. |
| `loop` | boolean | no | true repeats the clip, false stops on the last pose. |
| `doc` | string | no | What the clip shows. |

## `anim.set_event` (modifies state)

Since 0.7.0.

Rename an event of a clip, or replace its data or its game feel actions.

`event` is the event's index, or {t, name?}. Give `name`, `data` (an object that REPLACES the event's data; {} clears it) and/or `feel` (an action or an array of actions that REPLACE the event's; null or [] removes them). `name` null removes the name; an event keeps `name` or `feel`. Result: {path, event, undo}. Example: anim.set_event {"path":"anim/hero_walk.anim.json","event":0,"name":"step","data":{"foot":"right"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `event` | any | yes | Index of the event, or {t, name?}. |
| `name` | any | no | The new event name; null removes it (the event then needs `feel`). |
| `data` | object | no | The new data object. |
| `feel` | any | no | The new game feel action(s); null or [] removes them. |

## `anim.set_interp` (modifies state)

Since 0.7.0.

Set how selected keys reach the next key: interp or easing, and bezier tangents.

`keys` selects keys as [{track, t}] (as anim.move_keys). `interp` is linear, step, bezier or a tween easing (quadIn, quadOut, backInOut, elasticOut...). `in` and `out` set the bezier tangents of the selected keys (slope in field units per second, shaped like the value); without them a bezier key gets a smooth tangent through its neighbours. Result: {path, changed, undo}. Example: anim.set_interp {"path":"anim/hero_walk.anim.json","keys":[{"track":0,"t":0.4}],"interp":"quadOut"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `keys` | array | yes |  |
| `interp` | string | yes | linear, step, bezier or an easing of tween(). |
| `in` | any | no | bezier: incoming slope for every selected key. |
| `out` | any | no | bezier: outgoing slope for every selected key. |

## `anim.set_keys` (modifies state)

Since 0.7.0.

Add or replace keys of one track of a clip, creating the track if it is missing.

`track` is {path, component?, field}: the part (names from the entity that plays the clip, "" = itself), the component (default Transform) and the field with an optional channel ("rotation.z", "position", "color.a"). Each key is {t, value, interp?, in?, out?}: a key at an existing time REPLACES that key, any other time adds one; the keys stay sorted. Numbers, vectors, colours and angles interpolate (`interp`: linear, step, bezier with in/out tangents, or a tween easing such as quadOut); bool, int, enum, asset and rect fields only step. With `entity` (the entity that plays the clip) the track's part and component must exist on it, with "did you mean" over the names. A key past the duration is refused unless `extendDuration` is true (the duration grows to it). Result: {path, track (index), added, replaced, keys, undo}. Example: anim.set_keys {"path":"anim/hero_walk.anim.json","track":{"path":"body/arm_l","field":"rotation.z"},"keys":[{"t":0,"value":-30},{"t":0.4,"value":30,"interp":"quadInOut"},{"t":0.8,"value":-30}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `keys` | array | yes |  |
| `entity` | string | no | Entity that plays the clip (id or name): the track's part and component are checked against it. |
| `extendDuration` | boolean | no | Raise the clip's duration when a key is later than it. Default false. |
| `track` | object | yes |  |

## `anim3d.add_event`

Since 0.16.0.

Add an event to a 3D clip: a game event and/or game feel actions the Animator runs when the clip passes its time.

The event {t, name?, data?, feel?} reaches world.on(name, fn) and entity.animator.on(name, fn) with {id, clip, time} plus `data` (an object; the keys id, clip and time are reserved), once per loop. `feel` is one game feel action or an array (hitStop, shake, flash, knockback or push, squash, spawn, sound: docs/GAME_FEEL.md, "Effects as data") run on the entity that plays the clip; they are checked now. An event needs `name` or `feel`. Events stay sorted by t. A time past the duration is refused unless `extendDuration`. Result: the clip summary plus {event, undo}. Example: {"path":"anim/hero_walk.anim.json","t":0.2,"name":"footstep","data":{"foot":"left"}} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `t` | number | yes | Seconds from the start of the clip. |
| `name` | string | no | The game event name. Optional when `feel` is given. |
| `data` | object | no | Extra fields sent with the event. |
| `feel` | any | no | Game feel action(s) to run, each {action: shake\|hitStop\|flash\|knockback\|push\|squash\|spawn\|sound, ...options}; on set_event they replace the old ones, null or [] removes them. |
| `extendDuration` | boolean | no | Lengthen the clip when t is past its end. |

## `anim3d.create`

Since 0.16.0.

Write a new, empty 3D bone clip (*.anim.json, format factoria.anim3d/1) for a skinned rig; add tracks with anim3d.set_keys.

Creates the file with `duration` seconds and `loop`, no tracks. `rotation` is "euler" (keys are [pitch, yaw, roll] degrees, the default) or "quat" (keys are [x, y, z, w]). `rig` (optional) records the rig the clip is for and its template (retargeting and anim3d.preview read it). It refuses to replace a file unless `overwrite` is true. For a whole walk, run, idle, swing or hit clip use anim3d.generate instead. Format: schemas/anim3d.schema.json, docs/ANIMATION.md, "3D bone clips". Example: {"path":"anim/hero_wave.anim.json","duration":1.2,"loop":false,"rig":"assets/models/hero.rig.glb"} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `duration` | number | no | Length of the clip in seconds (default 1). |
| `loop` | boolean | no | true repeats the clip (default), false stops on its last pose. |
| `rotation` | string ["euler","quat"] | no | How rotation keys are written: euler degrees (default) or quaternions. |
| `rig` | string | no | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `doc` | string | no | What the clip shows and when it is used. |
| `overwrite` | boolean | no | Replace the file if it exists. |

## `anim3d.generate`

Since 0.16.0.

Generate a 3D bone clip for a baked rig from parameters: walk and run (stride, cadence, bounce, arm swing), quadruped trot and gallop, idle breathing, swings of tails and chains, hit reactions. Planted feet do not slide.

Writes `out` (default anim/<rig>_<kind>.anim.json), an ordinary 3D clip you can then edit key by key (anim3d.set_keys). `kind`: walk, run (biped legs; walk also fits a quadruped), trot, gallop (a quadruped's four legs), idle (spine breathing, a little sway), swing (the bones of a tail or chain swinging with a phase delay), hit (a reaction that recoils and settles). `params` are the kind's own (anim3d.generators lists them with ranges; an unknown name is an error with 'did you mean'). A gait is solved with the rig's own proportions: each foot follows a path that stands still on the ground in stance (the clip's `contacts` say when) and the clip's `groundSpeed` is the speed to move the entity at so the planted feet do not slide. The clip records the kind and every parameter used in `generated`, so the same call writes the same bits. A rig that lacks what the kind needs (legs, spine, tail) is an error that says which template has it. Refuses to replace a file unless `overwrite`.

Example: {"rig":"assets/models/hero.rig.glb","kind":"walk","params":{"strideLength":1.2,"cadence":1.0},"out":"anim/hero_walk.anim.json"} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `rig` | string | yes | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `kind` | string ["walk","run","trot","gallop","idle","swing","hit"] | yes | What to generate. |
| `params` | object | no | The kind's parameters (anim3d.generators lists them): strideLength, cadence, bounce, armSwing, fps... |
| `out` | string | no | Where to write the clip (ending in .anim.json). Default anim/<rig name>_<kind>.anim.json. |
| `overwrite` | boolean | no | Replace the file if it exists. |

## `anim3d.generators`

Since 0.16.0.

List the clip generators of anim3d.generate (walk, run, trot, gallop, idle, swing, hit) with their parameters, ranges and defaults.

The catalog behind anim3d.generate: for each kind what it makes, the rig templates it fits and every parameter with its meaning, default and range. Defaults that scale with the leg are written as 'N x leg' (the leg is hip to ankle in the rig's rest pose). The gait tables are in docs/ANIMATION.md, "Generators". Nothing is written. Example: {}

## `anim3d.info`

Since 0.16.0.

Describe a 3D bone clip (duration, tracks, events, contacts, how it was generated) and, with `rig`, check its bones against a baked rig; with no `path`, list the 3D clips of the project.

Reads the clip with the loader's own rules, so a file the game could not play comes back as an error with the JSON pointer of each problem. The result gives the length, whether it loops, the ground speed, the tracks (bone, channel, key count, first and last time), the events and the contacts (stretches where a foot is on the ground), and, for a generated clip, `generated` (kind and parameters). With `rig` it also reports bones the rig does not have (with 'did you mean'). Example: {"path":"anim/hero_walk.anim.json","rig":"assets/models/hero.rig.glb"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The 3D clip file, project-relative, ending in .anim.json. |
| `rig` | string | no | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |

## `anim3d.mirror_pose`

Since 0.16.0.

Key the left/right mirror of a 3D clip's pose at a time: swap both sides, or copy one side onto the other (bones are paired by canonical name: thigh_l <-> thigh_r).

Samples the clip at `time`, mirrors the pose across the character's mid plane and writes it as keys at `to` (default `time`) for every bone the clip animates: `from` "swap" (default) puts each side's pose on the other side and mirrors the bones with no side (spine, head, root) in place; "left" copies the left side onto the right bones; "right" the other way. A mirrored rotation keeps pitch and flips yaw and roll (a quaternion (x, y, z, w) becomes (x, -y, -z, w)); a translation flips x. Only channels the clip has a track for are keyed. `rig` defaults to the clip's own. Use it to build the second half of a cycle from the first. Result: the clip summary plus {time, from, keys, bones, undo}. Example: {"path":"anim/hero_walk.anim.json","time":0,"to":0.5} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `rig` | string | no | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `time` | number | yes | Seconds into the clip: the pose to mirror. |
| `to` | number | no | Where to key the mirrored pose (default: `time`). |
| `from` | string ["swap","left","right"] | no | swap (default), left or right: which side's pose is copied. |
| `interp` | string | no | Interpolation of the new keys (default: what an existing key has, else linear). |

## `anim3d.move_keys`

Since 0.16.0.

Move keys of a 3D clip in time by dt seconds (a dopesheet drag); a moved key replaces the key it lands on.

`keys` selects keys as [{bone, channel?, t}]; each moves to t + dt (rounded to 0.1 ms). A key may not leave the clip: before 0 is an error, past the duration is an error unless `extendDuration`. Two moved keys of one track landing on the same time is an error; a moved key replaces an unselected key at its new time. Bezier keys get smooth tangents again. Result: the clip summary plus {moved, dt, undo}. Example: {"path":"anim/hero_walk.anim.json","keys":[{"bone":"thigh_l","t":0.5}],"dt":0.05} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `keys` | array | yes | The keys, each {bone, channel (default rotation), t}. |
| `dt` | number | yes | Seconds to move by (negative = earlier). |
| `extendDuration` | boolean | no | Lengthen the clip when a key moves past its end. |

## `anim3d.preview`

Since 0.16.0.

Draw a 3D bone clip as a filmstrip: the baked rig posed at evenly spaced times, shaded, on a ground grid, with the feet that are on the ground marked; returns the PNG.

The way to SEE a clip without a window. It poses the rig's skin with the clip at `frames` times (a looping clip does not repeat its first pose at the end) and draws each with the software renderer of model.preview (no graphics device, the same pixels on every machine), all framed the same way so the motion reads across the strip. Under each pose: its time and the bones the clip's contacts say are on the ground. The mesh is skinned with the vertex weights stored in the .glb (rigid per bone as rig.bake writes them). `yaw` picks the side (default -70: from the character's right and a little in front); `yaws` (a list, e.g. [-70, 0, 90]) draws one row of poses per side in one sheet, which is how a pose is checked from several angles at once; the picture is returned as $image in a temporary file, pass `out` (a .png) to keep it. Nothing in the project changes otherwise. Example: {"path":"anim/hero_walk.anim.json","rig":"assets/models/hero.rig.glb","frames":8}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `rig` | string | no | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `frames` | number | no | How many poses, 2 to 12 (default 8), evenly spaced over the clip. |
| `cell` | number | no | Pixels per side of each pose (default 200). |
| `yaw` | number | no | The side to look from in degrees: 0 the front (+Z), 90 the character's left (+X), -90 its right (default -70). |
| `yaws` | array | no | Several sides in one sheet: one row of `frames` poses per angle (instead of `yaw`), at most 6 angles and 48 poses. Example [-70, 0, 90]. |
| `pitch` | number | no | Degrees above the horizon (default 10). |
| `out` | string | no | Keep the picture as a PNG at this project-relative path. Left out, it is a temporary file. |
| `overwrite` | boolean | no | Replace the file at `out` if it exists. |

## `anim3d.remove_event`

Since 0.16.0.

Remove an event from a 3D clip.

`event` is the event's index in the clip's events, or {t, name?}. Result: the clip summary plus {removed, undo}. Example: {"path":"anim/hero_walk.anim.json","event":0} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `event` | any | yes | The event: its index in the clip's events, or {t, name?}. |

## `anim3d.remove_keys`

Since 0.16.0.

Delete keys of a 3D clip by bone, channel and time; a track left with no key goes away.

`keys` selects keys as [{bone, channel?, t}] (anim3d.info lists the tracks; a time within 1 ms matches). Result: the clip summary plus {removed, tracksRemoved, undo}. Example: {"path":"anim/hero_walk.anim.json","keys":[{"bone":"thigh_l","t":0.5}]} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `keys` | array | yes | The keys, each {bone, channel (default rotation), t}. |

## `anim3d.remove_track`

Since 0.16.0.

Remove the tracks of one bone from a 3D clip (all its channels, or the one in `channel`).

The clip is checked with the loader's rules and written in canonical form. A bone with no track is an error that lists the bones that have one. Example: {"path":"anim/hero_walk.anim.json","bone":"hand_l"} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `bone` | string | yes | The bone whose track to remove. |
| `channel` | string ["rotation","translation","scale"] | no | Which channel of the bone (default rotation). |

## `anim3d.restore`

Since 0.16.0.

Put a 3D clip file back to a whole document, or delete it: the undo and redo of the anim3d.* edits.

Every writing anim3d.* command returns `undo` = {command: "anim3d.restore", args: {path, clip}}; calling it writes `clip` (the whole previous document, checked with the loader's rules) or, when `clip` is null, deletes the file (the undo of a command that created it). Its own result carries the `undo` that goes forward again (redo). Example: {"path":"anim/hero_walk.anim.json","clip":null}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `clip` | any | yes | The whole clip document to write, or null to delete the file. |

## `anim3d.retarget`

Since 0.16.0.

Carry a 3D clip from one baked rig to another (other proportions, a different template) by bone role, index and side; root motion and feet are scaled and planted feet stay planted.

Bones are matched by (role, index, side). Rotations are copied (every rig.bake bone rests with an identity rotation), a chain with a different bone count keeps its total bend, a bone the target lacks is dropped and listed in `dropped`, a bone the clip does not move rests. Root translation, ground speed and feet are scaled by the ratio of the leg lengths (hip to ankle) or `scale`; with `plantFeet` (default) the legs the clip has contacts for are solved again with the two-bone solver so planted feet stay planted on the new proportions (`planted`); a foot the new legs cannot reach stretches straight and is reported in `notes`. `from` defaults to the rig recorded in the clip. Result: {path, scale, mapped, dropped, resampled, planted, notes}. Example: {"path":"anim/hero_walk.anim.json","to":"assets/models/guard.rig.glb","out":"anim/guard_walk.anim.json"} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `from` | string | no | The rig the clip was made for (default: the rig recorded in the clip). |
| `to` | string | yes | The rig to carry the clip to. |
| `out` | string | yes | Where to write the retargeted clip (ending in .anim.json). |
| `plantFeet` | boolean | no | Solve the legs with a contact again so planted feet stay planted (default true). |
| `scale` | number | no | Factor for root motion, ground speed and feet; 0 (default) = the ratio of the leg lengths. |
| `fps` | number | no | Keys per second of the legs solved again (default 30). |
| `overwrite` | boolean | no | Replace the file at `out` if it exists. |

## `anim3d.set_clip`

Since 0.16.0.

Set the duration, loop, ground speed or description of a 3D clip.

Give any of `duration` (seconds; shorter than the last key or event is refused), `loop`, `groundSpeed` (model units per second the planted feet move back at; 0 = in place) and `doc`. Result: the clip summary plus {undo}. Example: {"path":"anim/hero_walk.anim.json","duration":1.2,"loop":false} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `duration` | number | no | Length of the clip in seconds. |
| `loop` | boolean | no | true repeats the clip, false stops on its last pose. |
| `groundSpeed` | number | no | Model units per second the ground moves under the planted feet; 0 = in place. |
| `doc` | string | no | What the clip shows. |

## `anim3d.set_event`

Since 0.16.0.

Move, rename or change the data or the game feel actions of an event of a 3D clip.

`event` is the event's index in the clip's events, or {t, name?} (name needed when two events share the time). Give any of `t` (move it), `name`, `data` (an empty object or null clears it) and `feel` (an action or an array that REPLACES the event's; null or [] removes them). Events stay sorted by t. Result: the clip summary plus {undo}. Example: {"path":"anim/hero_walk.anim.json","event":{"t":0.2,"name":"footstep"},"t":0.25} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `event` | any | yes | The event: its index in the clip's events, or {t, name?}. |
| `t` | number | no | The new time in seconds. |
| `name` | string | no | The new event name. |
| `data` | object | no | The new data (replaces the old). |
| `feel` | any | no | Game feel action(s) to run, each {action: shake\|hitStop\|flash\|knockback\|push\|squash\|spawn\|sound, ...options}; on set_event they replace the old ones, null or [] removes them. |
| `extendDuration` | boolean | no | Lengthen the clip when t is past its end. |

## `anim3d.set_interp`

Since 0.16.0.

Set how selected keys of a 3D clip reach the next key: linear, step, bezier or an easing (the M42 curves).

`keys` selects keys as [{bone, channel?, t}]; `interp` is linear, step, bezier (smooth tangents through the neighbours) or an easing name (quadIn, quadOut, quadInOut, backOut, elasticOut... as tween()). A quaternion clip takes linear, step or an easing. Result: the clip summary plus {changed, interp, undo}. Example: {"path":"anim/hero_walk.anim.json","keys":[{"bone":"thigh_l","t":0.5}],"interp":"quadInOut"} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `keys` | array | yes | The keys, each {bone, channel (default rotation), t}. |
| `interp` | string | yes | linear, step, bezier or an easing name. |

## `anim3d.set_keys`

Since 0.16.0.

Add or replace keys of one bone's track in a 3D clip (rotation as euler degrees or quaternion, translation, scale); a key at the time of an existing one replaces it.

Edits one track (`bone` + `channel`, made when it does not exist): each key is {t, value, interp, in, out} as in the file (schemas/anim3d.schema.json). `value` is [x, y, z] (rotation: pitch, yaw, roll degrees; translation: an offset from the rest position in the parent's frame, model units; scale: a multiplier) or [x, y, z, w] for a quaternion clip. `interp` is linear (default), step, bezier or an easing name (quadInOut, backOut...). Keys within 0.1 ms of an existing key replace it; the rest are added; keys end up in time order. `duration` sets the length of the clip (a key later than it is an error). `rig` (optional) checks that the bone exists in that rig (with 'did you mean'). The whole clip is checked with the loader's rules and nothing is written if it is wrong. The file is written in canonical form. Example: {"path":"anim/hero_wave.anim.json","bone":"arm_upper_l","keys":[{"t":0,"value":[0,0,0]},{"t":0.4,"value":[0,0,150],"interp":"quadOut"}]} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `bone` | string | yes | Canonical bone name: role[_index][_side], e.g. "spine_1", "thigh_l", "root". |
| `channel` | string ["rotation","translation","scale"] | no | Which channel of the bone (default rotation). |
| `keys` | array | yes | [{t, value, interp?, in?, out?}]: seconds from the start and the value (3 numbers, or 4 for a quaternion). |
| `duration` | number | no | Set the clip's length in seconds (it must reach the last key). |
| `rig` | string | no | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |

## `ik3d.check`

Since 0.16.0.

Check the `solvers` of an IK3D component against a baked rig: types, keys, number ranges, bone names ('did you mean') and chains (root -> mid -> end).

The same check project.validate runs on every IK3D in a scene, available before the scene exists. Each problem has a JSON pointer into `solvers` ("/2/root"), what is wrong and how to fix it. The result also lists the rig's bones. Nothing is written. Example: {"rig":"assets/models/hero.rig.glb","solvers":[{"type":"lookAt","bone":"head","target":"player"},{"type":"foot","thigh":"thigh_l","shin":"shin_l","foot":"foot_l"}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `rig` | string | yes | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `solvers` | array | yes | The solvers as an IK3D component holds them. |

## `ik3d.key`

Since 0.16.0.

Solve a 3D IK solver (two-bone with pole, or look-at) on a clip's pose at a time and key the bones it moved: the way an IK handle poses a chain.

Poses the rig with the clip at `time`, runs `solver` (one entry of IK3D.solvers with [x, y, z] targets in the model's space, as ik3d.solve) and writes rotation keys at that time for every bone the solver changed (translation for a foot solver that lowers the pelvis). The keys are ordinary ones: anim3d.set_keys, anim3d.move_keys and the Animation panel edit them. Result: the clip summary plus {time, keyed: [{bone, channel}], solved (as ik3d.solve), undo}. An error says the solver changed nothing when the pose already satisfied it. Example: {"path":"anim/hero_wave.anim.json","time":0.4,"solver":{"type":"twoBone","root":"arm_upper_r","mid":"arm_lower_r","end":"hand_r","target":[-0.4,1.5,0.4],"pole":[-0.5,1.2,-0.5]}} The result carries `undo`: {command: "anim3d.restore", args} puts the whole clip file back as it was (or deletes a file this call created), which is how the editor undoes it.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The 3D clip file, project-relative, ending in .anim.json. |
| `rig` | string | no | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `time` | number | yes | Seconds into the clip to key. |
| `solver` | object | yes | One IK3D solver with fixed [x, y, z] targets (twoBone, lookAt or foot). |
| `interp` | string | no | Interpolation of the new keys (default: what an existing key has, else linear). |
| `groundHeight` | number | no | Height of the flat ground a foot solver stands on (default 0). |

## `ik3d.solve`

Since 0.16.0.

Run one IK3D solver offline on a baked rig (its rest pose, or a clip's pose at a time) and report whether it reached, the error and where the bones ended up.

`solver` is one entry of IK3D.solvers whose targets are positions [x, y, z] in the model's space (an entity target is an error: there is no scene). twoBone moves root, mid and end so the end reaches `target` bending towards `pole`; lookAt aims `bone` within its yaw and pitch limits; foot puts the ankle at the height of a flat ground at `groundHeight` over where it is. Result: for a limb {reached, error, target, bones: [{bone, head}]}, for lookAt {clamped, yaw, pitch, aim}. Use it to find a target the limb can reach and limits that look right. Nothing is written. Example: {"rig":"assets/models/hero.rig.glb","solver":{"type":"twoBone","root":"arm_upper_r","mid":"arm_lower_r","end":"hand_r","target":[-0.4,1.3,0.5]}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `rig` | string | yes | The baked rig: a .rig.glb written by rig.bake, or the .rig.json that bakes it. Project-relative. |
| `solver` | object | yes | One IK3D solver with fixed [x, y, z] targets. |
| `clip` | string | no | A 3D clip to pose the rig with first (default: the rest pose). |
| `time` | number | no | Seconds into `clip` (default 0). |
| `groundHeight` | number | no | Height of the flat ground a foot solver stands on (default 0). |

