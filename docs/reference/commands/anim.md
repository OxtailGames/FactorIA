[Back to the index](../README.md)

# Commands: anim

## `anim.add_event` (modifies state)

Since 0.7.0.

Add an event to a clip: a game event sent when the clip passes its time.

The event {t, name, data?} reaches world.on(name, fn) and entity.animator.on(name, fn) with {id, clip, time} plus `data` (an object; the keys id, clip and time are reserved), once per loop. Events stay sorted by t. A time past the duration is refused unless `extendDuration`. Result: {path, event (index), undo}. Example: anim.add_event {"path":"anim/hero_walk.anim.json","t":0.2,"name":"footstep","data":{"foot":"left"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `t` | number | yes | Seconds from the start of the clip. |
| `name` | string | yes | The game event name. |
| `data` | object | no | Extra fields sent with the event. |
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
| `events` | array | no | Events [{t, name, data?}] sent to the game when the clip passes t. |
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

`event` is the event's index, or {t, name?}. Result: {path, removed: {t, name, data?}, undo}. Example: anim.remove_event {"path":"anim/hero_walk.anim.json","event":{"t":0.2,"name":"footstep"}}

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

Rename an event of a clip or replace its data.

`event` is the event's index, or {t, name?}. Give `name` and/or `data` (an object that REPLACES the event's data; {} clears it). Result: {path, event, undo}. Example: anim.set_event {"path":"anim/hero_walk.anim.json","event":0,"name":"step","data":{"foot":"right"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The clip file (.anim.json). |
| `event` | any | yes | Index of the event, or {t, name?}. |
| `name` | string | no | The new event name. |
| `data` | object | no | The new data object. |

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

