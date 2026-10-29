# Animation: skeletal and 2D clips, state machines and tweens

Four tools, from "a character walks" to "a menu panel slides in":

| Tool | For | Where it lives |
|---|---|---|
| `Animator` component | Play the animation clips of a skinned glTF model, blend between them, react to clip events, switch with a small state machine | scene JSON + `entity.animator` |
| `Animator` + `*.anim.json` | Keyframed 2D clips that animate any field of an entity and its children (a character built in parts), with layers and masks | [2D clips](#2d-clips-animjson) |
| `tween()` / `ease` | Move any number, vector or color over time (UI, cameras, pickups, 2D and 3D) | `import { tween, ease } from "factoria"` |
| `SpriteAnimator` | Frame-by-frame 2D sprite sheets, played by clip name | [Sprite sheets](#sprite-sheets-spriteanimator) |
| `Bone2D`, `SpriteSkin`, `IK2D` | 2D bones: a sprite bent by the bones it is bound to, and chains that reach for a target | [Bones and IK](#bones-and-ik) |

The tools run on the game clock: the fixed step and `time.scale` (a paused game pauses them), never the wall clock, so
a headless run, a replay and the test runner see exactly what a player sees.

## The Animator component

Put it on the entity that has the animated model (skinned, or made of rigid parts that follow animated nodes, see
"Rigid parts"):

```json
{ "id": "hero",
  "components": {
    "MeshRenderer": { "mesh": "assets/models/hero.glb" },
    "Animator": { "clip": "Idle" } } }
```

- `clip` is the name of a glTF animation (`entity.animator.clips` lists them; a wrong name is an error that lists them).
  Empty plays nothing: the model shows in its bind pose, the pose it was exported in.
- `model` overrides the glTF to animate; empty uses the `mesh` of the MeshRenderer on the same entity.
- `speed` (1 = authored), `loop` (default true), `playing`, `fade` (seconds of cross-fade when you assign `clip`).
- Runtime fields (not saved): `time` (seconds into the clip; assigning seeks) and `values` (the state machine parameters).

From a script:

```js
const anim = hero.animator;
anim.play("Run", 0.2);          // cross-fade 0.2 s from whatever pose it is in
anim.play("Idle");               // fade = the component's `fade` (0.2 s by default)
anim.speed = 1.5;               // faster
anim.clip = "Jump";             // also switches, with the component's `fade`
anim.stop();                    // bind pose, paused
anim.duration("Jump");          // seconds
```

Playing the clip that already plays does nothing (it does not restart). Starting a clip while a cross-fade runs drops the older
clip of that fade.

### Clip events

List them on the component, per clip, and they arrive as game events the step the clip's time passes them, once per loop:

```json
"Animator": { "clip": "Walk",
  "events": [ { "clip": "Walk", "time": 0.25, "name": "footstep" },
              { "clip": "Walk", "time": 0.75, "name": "footstep" } ] }
```

```js
hero.animator.on("footstep", () => audio.play("assets/step.wav"));   // this entity only
world.on("footstep", (data, source) => {});                           // every animator; data = { id, clip, time }
```

A non-looping clip (`loop: false`) stops on its last pose and sends `anim.finished` with `{ id, clip }`. Seeking with
`animator.time = x` does not fire the events it jumps over.

### State machine

A data-driven state machine is built into the component: parameters, states (a clip each) and transitions. No script is
needed to walk, run and jump; the script only sets parameters.

```json
"Animator": {
  "params": { "speed": 0, "grounded": true },
  "states": {
    "idle": { "clip": "Idle" },
    "run":  { "clip": "Run", "speed": 1, "onEnter": "started_running" },
    "jump": { "clip": "Jump", "loop": false }
  },
  "transitions": [
    { "from": "idle", "to": "run",  "when": "speed > 0.1 && grounded", "fade": 0.15 },
    { "from": "run",  "to": "idle", "when": "speed <= 0.1", "fade": 0.2 },
    { "to": "jump", "when": "jump", "fade": 0.1 },
    { "from": "jump", "to": "idle", "onFinish": true }
  ]
}
```

```js
hero.animator.set("speed", Math.abs(velocity.x));   // a parameter declared in `params`
hero.animator.set("grounded", hero.isGrounded());
if (input.pressed("jump")) hero.animator.trigger("jump");   // true for one step only
hero.animator.on("started_running", () => particles.burst(dust));
console.log(hero.animator.state);                    // "run"
console.log(hero.animator.get("speed"));             // a parameter's current value (tests read it the same way)
```

Rules, all checked in the fixed step:
- The start state is `state` (set in the scene) or the first of `states`. Entering a state plays its clip (`loop` default
  true, `speed` default 1) and sends the game event named by its `onEnter`, with `{ id, state, from }`.
- `transitions` are tried in order and the first that matches fires. `from` is a state name; leave it out or write `"*"`
  for any state. A transition to the state you are already in is ignored.
- `when` is conditions joined by `&&`: `speed > 0.1`, `grounded`, `!grounded`, `hp <= 0`, `state == 2`. Operators:
  `> >= < <= == !=`. A bare name is true for a non-zero number, `true`, or a `trigger()` this step. Booleans count as 1/0.
- `onFinish: true` fires when the current non-looping clip has ended (alone, or together with `when`). A transition needs a
  `when` or `onFinish`; one without would fire every step and is skipped.
- `fade` is the cross-fade in seconds (default 0.2).
- `set()` of a name not in `params` is an error that lists the declared ones ("did you mean"). `trigger()` needs no
  declaration.

## 2D clips: `*.anim.json`

An Animator with no glTF `model` plays keyframed clips from files. A clip animates fields of the entity that has the
Animator and of the entities under it, so a character made of child sprites (body, arm, hand...) moves by rotating and
moving those parts. The schema is `schemas/anim.schema.json`; the format is `factoria.anim/1`.

```json
{ "format": "factoria.anim/1",
  "duration": 0.8,
  "loop": true,
  "tracks": [
    { "path": "body", "component": "Transform", "field": "position.y",
      "keys": [ { "t": 0, "value": 0 },
                { "t": 0.4, "value": 6, "interp": "quadOut" },
                { "t": 0.8, "value": 0, "interp": "quadIn" } ] },
    { "path": "body/arm_l", "component": "Transform", "field": "rotation.z",
      "keys": [ { "t": 0, "value": -30 }, { "t": 0.4, "value": 30 }, { "t": 0.8, "value": -30 } ] },
    { "path": "body/arm_l", "component": "Sprite", "field": "flipX",
      "keys": [ { "t": 0, "value": false }, { "t": 0.4, "value": true } ] }
  ],
  "events": [ { "t": 0.4, "name": "footstep", "data": { "foot": "left" } } ] }
```

The Animator names the files; the keys of `clips` are the clip names everything else uses (`clip`, `play()`, `states`):

```json
{ "id": "hero",
  "components": {
    "Animator": { "clips": { "walk": "anim/hero_walk.anim.json", "idle": "anim/hero_idle.anim.json" },
                  "clip": "walk" } },
  "children": [ { "name": "body", "components": { "Sprite": { "texture": "assets/hero_body.png" } },
                  "children": [ { "name": "arm_l", "components": { "Sprite": { "texture": "assets/hero_arm.png" } } } ] } ] }
```

An Animator uses 2D clips when `clips` is a non-empty object, `model` is empty and the entity's MeshRenderer (if any)
does not point at a `.gltf` or `.glb`. Otherwise `clip` and `events` mean what they meant above (glTF animations).

### The file

- `duration` (required): seconds. No key or event is later than it. `loop` (default true) is the clip's own choice;
  `doc` is free text.
- A **track** drives one field. `path` names the entity as the `name` of each entity from the Animator's entity down,
  joined with `/` (`"body/arm_l"`; `""`, the default, is the entity itself; the first child with each name is used).
  `component` (default `"Transform"`) and `field` say which reflected field. A field can be given one channel:
  `rotation.z`, `position.x`, `scale.y`, `color.a` (x y z w, or r g b a for a colour); the other channels are not touched.
  Two tracks cannot drive the same channel (an error).
- A **key** is `{t, value, interp}`: `t` in seconds, ascending, one key per time. Before the first key and after the
  last one the track holds that key's value. `value` has the shape of the field: a number, an array for a vector or colour,
  a bool, an integer, an enum name, an asset path or a rect.
- An **event** is `{t, name, data}`. See "Events" below.

What can be animated:

| Field kinds | Between two keys |
|---|---|
| Numbers (float), vectors (`position`, `scale`), colours, one channel of those, angles | interpolates |
| Bool, int, enum, asset path (`Sprite.texture`), rect (`Sprite.region`) | **steps**: keeps the key's value until the next key |

`interp` on a key says how its value reaches the next key (a field that only steps ignores it):

| `interp` | Curve |
|---|---|
| `linear` (default) | straight line |
| `step` | holds the value until the next key |
| `bezier` | cubic Hermite curve using the `out` tangent of this key and the `in` tangent of the next one. Tangents are slopes in field units per second, a number or an array shaped like the value. A bezier key with no tangent gets a smooth one made from its neighbours (zero at both ends of the track). |
| an easing name | linear in value, shaped by the curve of `tween()`: `quadIn`, `quadOut`, `quadInOut`, `cubic...`, `quart...`, `quint...`, `sine...`, `expo...`, `circ...`, `back...`, `elastic...`, `bounce...` (`ease` in the scripting API). `back` and `elastic` overshoot. |

Angles are `Transform.rotation` (degrees) and any float named `angle` or ending in `Angle`. They interpolate between keys
like any number; they differ only when clips are blended (below), where they take the short way round.

### Playing

Everything of the glTF Animator works with these clips:

```js
const anim = hero.animator;
anim.play("walk", 0.2);     // cross-fade from the current clip over 0.2 s
anim.speed = 1.5;           // playback speed
anim.time = 0.3;            // seeks (no events fire for the jump)
anim.loop = false;          // stops on the last pose and sends "anim.finished"
anim.clips;                 // ["walk", "idle"]
anim.duration("walk");      // 0.8
anim.sample("walk", 0.4);   // poses the parts at 0.4 s and pauses (below)
```

- Whether a clip loops: the Animator's `loop` and the clip's own `loop` must both be true; a state of the state machine
  that writes `loop` decides alone. A clip that does not loop stops on its last pose, the Animator's `playing` becomes
  false and `anim.finished` is sent with `{ id, clip }`.
- The state machine (`params`, `states`, `transitions`, `onFinish`, `onEnter`) is the one above; a state's `clip` is a key
  of `clips`.
- Playing the clip that already plays does not restart it.

**Cross-fade.** While a fade runs, the fields both clips drive are lerped between the old clip's pose and the new one's.
Angles take the short way round (a fade from 350 to 10 degrees passes through 360, not through 180). Fields that only
step (a bool, an enum, a texture) keep the old clip's value until half the fade and switch to the new clip's after it.

**What a clip does not drive.** Every field a clip has driven has a rest value: what it held before the first clip
touched it. A field the current clip does not drive goes back to its rest value, so switching from `attack` (which moves
the arm) to `idle` (which does not) leaves the arm where it was authored. `stop()` and clearing `clip` also restore the
rest pose. A cross-fade to a clip that leaves a channel out lerps to that rest value.

### Layers

`layers` play more clips on top of the main one, each with a weight and, optionally, a mask that limits it to some parts:

```json
"Animator": {
  "clips": { "walk": "anim/walk.anim.json", "shoot": "anim/shoot.anim.json", "breathe": "anim/breathe.anim.json" },
  "clip": "walk",
  "layers": [
    { "name": "arms",   "clip": "shoot",   "weight": 0, "mask": ["body/arm_l", "body/arm_r"] },
    { "name": "breath", "clip": "breathe", "weight": 1, "mode": "additive" } ] }
```

| Key | Meaning |
|---|---|
| `name` | Used by `setLayerWeight` and `playLayer`; also in the `layer` field of its events. Default `layer<index>`. |
| `clip` or `states` | One clip, or a state machine of its own (`states` and `transitions` like the Animator's, reading the same parameters; `state` picks the first one). `states` wins when both are given. |
| `weight` | 0 to 1 (default 1). A layer at weight 0 is not playing: it starts from its first pose when the weight rises, and its clip events do not fire. |
| `mode` | `override` (default): the layer's pose is lerped over the pose below it by `weight`. `additive`: the CHANGE of the clip from its first pose is added, scaled by `weight`: a breathing clip that goes 1.00 to 1.04 adds +0.04 to whatever the walk gives. |
| `mask` | Paths (as in a track's `path`). Only the tracks of the clip at or under one of them apply. Empty or absent: all of them. |
| `speed`, `loop` | Playback speed (default 1) and whether the layer's clip loops (default: the clip's own `loop`). |

Layers apply in order, after the main clip. A layer's clip only changes the fields it drives. Fields that only step
(`flipX`, a texture) switch to the layer's value once its weight is 0.5 or more in an `override` layer, and are ignored by an
`additive` one (there is no "difference" of a bool).

```js
hero.animator.setLayerWeight("arms", 1);               // raise a layer (e.g. while the shoot button is down)
hero.animator.playLayer("arms", "reload", 0.1);        // the layer plays another clip, with a fade
```

`playLayer` is for layers with a `clip`; a layer with `states` is driven by the parameters. Both throw with the layer
names when there is no such layer. Setting `layers` from a script (or the editor) rebuilds them: a layer that keeps its
name and its `clip` keeps playing.

### Events

Events of the clip file are sent as game events when the clip's time passes `t`, once per loop (an event at `duration`
fires when the clip wraps; one at 0 fires when the clip starts):

```js
hero.animator.on("footstep", (d) => audio.play("assets/step.wav"));   // d = { id, clip, time, foot: "left" }
world.on("footstep", (d, source) => {});                               // every animator
```

`data` is merged into the event next to `id`, `clip` (the name in `clips`) and `time` (the event's `t`); a layer's events
also carry `layer`. Those three keys are the engine's: a file that uses them in `data` is an error. The component's
`events` list (`{clip, time, name}`) works for 2D clips too. `anim.finished` carries `{ id, clip }` and `layer` when it comes from a layer.

### The pose is a runtime state

The fields a clip drives hold the pose of the current frame, like the transform of a physics body. **`scene.save`, prefabs
and the editor's Play/Stop write the rest value of a driven field, not the pose**, so a saved scene does not freeze a
character in mid-step. Inspecting commands (`entity.get`, the scene description, `entity.toJSON()`) show the pose that is
on screen. Duplicating an entity in the editor, or `entity.clone()`, copies what the fields hold now, pose included. An
Animator that is copied starts with no runtime state and binds to its own copy of the tree.

`animator.sample(clip, t)` poses the parts at `t` seconds of `clip` (clamped to the clip) without playing: it pauses the
Animator on that pose. The clip files are read once and shared by every Animator that names them (cached by path and
modification time).

### Frame order and where IK goes

The Animator runs in the fixed step, after physics (`update_animators`). The poses it wrote are what is drawn, so
anything that must correct the pose runs **after the Animator and before drawing**: in `engine.cpp` the point sits right
after `update_animators`, marked "After the Animator, before drawing". `IK2D` runs there ([Bones and IK](#bones-and-ik)), and skinned sprites are deformed
from the bones when drawing. Code that reads the
parts' transforms in `onFixedUpdate` sees the pose of the previous step.

### Hot reload, validation and errors

The Animator checks its clip files and the entities its tracks name every 15 updates (0.25 s at 60 Hz): a file saved with
new keys plays from the next check, and a part that was added to the tree starts being animated. A file with an error keeps
the last good version playing and logs the error once. The first update of an Animator logs, once per problem, every clip
whose tracks do not fit its entity.

Errors name the file, a JSON pointer, what is wrong and how to fix it:

```
anim/hero_walk.anim.json /tracks/1/path: no entity named 'bdy' under 'hero' (path 'bdy/arm_l')
    Did you mean 'body'? Valid: body.
anim/hero_walk.anim.json /tracks/0/field: Animator.clip cannot be animated: a string cannot be interpolated or switched by a clip
    Animatable fields of Animator: (the fields it lists)
anim/hero_walk.anim.json /tracks/2/keys/3/t: t is 0.5, not after the previous key (t 0.8): keys must be in ascending order of t
anim/hero_walk.anim.json /tracks/3/field: Transform.position.x on 'body' is already driven by an earlier track (position)
```

A file with problems lists the first one and "(and N more problems)". `animator.play(clip)` from a script is strict: a track
that names a missing entity or component is an error that lists the entities. The state machine, `clip` and the start of
the game are lenient: they warn once and play the tracks that resolve.

### Commands for clips

An AI (or a timeline editor) makes and fixes clips with commands, never by editing JSON by hand. Each one checks the whole file
with the loader's own rules before it writes, so nothing invalid reaches the disk, and every one that writes returns `undo`:
`{command: "anim.restore", args: {path, clip}}`. Calling `anim.restore` puts the whole previous document back (or deletes the file
when `clip` is null, the undo of `anim.create_clip`) and returns the `undo` that goes forward again.

| Command | What it does |
|---|---|
| `anim.create_clip {path, duration, loop?, doc?, tracks?, events?, overwrite?}` | Writes a new clip file; refuses to replace one unless `overwrite`. |
| `anim.set_keys {path, track, keys, entity?, extendDuration?}` | Adds or replaces keys of a track (`track` is `{path, component?, field}`), creating the track. With `entity`, the part and component must exist on it. |
| `anim.remove_keys {path, track, times \| all}` | Removes keys; a track left without keys disappears. |
| `anim.move_keys {path, keys: [{track, t}], offset?, scale?, pivot?}` | Moves and scales selected keys in time; refused if one would land on another key or outside the clip. |
| `anim.set_interp {path, keys, interp, in?, out?}` | `linear`, `step`, `bezier` (tangents) or a tween easing, for the selected keys. |
| `anim.add_track` / `anim.remove_track` | Adds a track (with keys, or the part's current value as its first key) or removes one; `track` is an index or `{path, component, field}`. |
| `anim.add_event` / `anim.move_event` / `anim.set_event` / `anim.remove_event` | Events `{t, name, data?}`; `event` is an index or `{t, name?}`. |
| `anim.set_clip {path, duration?, loop?, doc?}` | Duration (refused when shorter than the last key or event), loop, description. |
| `anim.list {entity \| path, full?}` | The Animator's clips with their tracks (the `index` the commands take), events and problems; `full` adds the whole file. |
| `anim.pose {entity, clip, t}` | Poses the entity (parts, bones, skins, IK) as the clip is at `t` and leaves it there; the Animator pauses. |
| `anim.filmstrip {entity, clip, frames?, onionSkin?, region?, zoom?, path?}` | One labelled picture with a grid of poses (the game is not stepped, the entity is put back). `onionSkin` draws faint neighbours under each pose. Needs graphics. |
| `anim.check {entity \| path, clip?, samples?}` | Findings `{kind, severity, clip, track?, part?, message, hint}`: `no_change`, `loop_jump`, `unknown_part`, `leaves_view`, `ik_out_of_reach`, `invalid_clip`. |
| `bones.create {parent, points, names?}` | A chain of `Bone2D` entities along joint positions. |
| `skin.bind {entity, root \| bones, mesh?}`, `skin.auto_weights`, `skin.set_weights {entity, vertices, bone, weight, mode}` | Skin a Sprite to bones, write the automatic weights out, and paint them (`set`, `add`, `smooth`). |

`anim.check` with only `path` looks at the file (`no_change`, `loop_jump`); with `entity` it also poses the clip `samples` times
(the entity is put back afterwards) to find a part that is in the camera's view in some poses and completely outside it in
others, and an `IK2D` target the bones cannot reach in some poses. A clip with a track that names no part is reported once as
`unknown_part` and the posed checks are skipped for it until it is fixed. `leaves_view` needs an orthographic primary Camera.

`factoria validate` checks every `*.anim.json` of the project (hidden folders, `node_modules` and a top-level `build/` skipped),
and every clip an `Animator` of a scene or prefab names: a missing file (with "did you mean" over the project's clips), and
tracks that resolve to no part of that Animator's entity or to a part without the component.

## Sprite sheets: SpriteAnimator

`SpriteAnimator` plays the frames of a sprite sheet on the `Sprite` of the same entity (it sets the sprite's `region` every
frame). A sheet that `assets.animate_svg`, `assets.bake_sheet`, `assets.slice_sheet` or an Aseprite import made has a `sheet`
entry in `assets.json` with its grid, `padding`, `pivot` and named clips (`firstFrame`, `lastFrame`, `fps`, `loop`); the
game plays a clip by its name:

```json
{ "Sprite": { "texture": "assets/art/hero.png" },
  "SpriteAnimator": { "clip": "run" } }
```

- `clip` is a clip name of the sheet of `Sprite.texture`. A wrong name is an error that lists the clips and suggests the
  closest (`project.validate` reports it for scenes and prefabs). Empty plays the numeric range below.
- `columns`, `rows`, `firstFrame`, `lastFrame`, `fps` and `loop` are still there. With a `clip`, a value you set overrides the
  one of the clip (`fps` 24 over a clip's 12); one you leave at its default is taken from the clip. `loop` is the exception:
  only `loop: false` overrides (a looping clip then plays once); `loop: true` cannot make a clip baked as non-looping
  repeat, bake it with `loop: true`.
- `mode` is `forward` (default), `reverse` or `pingpong` (forward then back, without repeating the end frames; one that does not loop stops back on its first frame).
- The sheet's `padding` is skipped by itself; the sheet's `pivot` (and the clip's) is used when the Sprite has no pivot of its
  own. The sheet counts the pivot from the TOP-left, `Sprite.pivot` from the bottom-left (y flipped); see
  [ASSETS.md](ASSETS.md). `sheetPivot: false` ignores it.
- A clip that does not loop stops on its last frame and sends the game event `clipEnded` with `{id, clip}` once. `ended` is
  true meanwhile (runtime, not saved).

From a script:

```js
const fx = world.spawn({ name: "Boom", components: {
  Transform: { position: [x, y, 0] },
  Sprite: { texture: "assets/art/shockwave.png" },
  SpriteAnimator: { clip: "boom" } } });
fx.spriteAnimator.on("clipEnded", () => fx.destroy());   // the handler only gets this entity's event
fx.spriteAnimator.play("pop");        // switch clip by name; play("pop", true) restarts it; throws on a wrong name
fx.spriteAnimator.clips;              // ["pop", "boom"]
fx.spriteAnimator.clipInfo("pop");    // {name, firstFrame, lastFrame, fps, loop, pivot}
```

The renderer steps the animators with the game clock, so the animation advances in a headless run, a replay and
`factoria test` as it does for a player (a run with no graphics at all does not draw, and does not step them).
`assets.preview_sheet` shows the clips and checks them before you wire them in; the editor's Project panel plays them.
`examples/neon-swarm` makes its kill effect this way.

## Where it runs and what the renderer reads

`update_animators` (`fa/scene/animation.h`, in `fa_scene`: no GPU needed) runs once per FIXED step, after physics and
before the step's game events are dispatched, so clip events reach `world.on` in the step that produced them. It does not
run while `time.scale` is 0. Headless runs animate exactly as windowed ones.

The result is `Animator::skinPalettes` (`components.h`): per skin of the model, one skinning matrix per joint, in the glTF's
model space (`jointGlobal * inverseBindMatrix`); `Animator::palette` is the first one. Entities without a skin or rigid
part keep empty palettes. `skeleton.h` reads the rig (`load_skeleton`: nodes, skins, clips, and the
`JOINTS_0`/`WEIGHTS_0` of every skinned primitive) and `animation.h` samples clips (`sample_clip`, `blend_poses`,
`skin_palette`), both testable without a GPU. LINEAR, STEP and CUBICSPLINE samplers are supported; morph-target weights
are not read yet.

## Rigid parts

Many models are not skinned: every body part is a plain mesh under a bone node (RobotExpressive, Blender exports with no
weight painting), or the mesh nodes themselves are animated (Kenney's cube pets). The Animator plays them with no change
to the file. The importer (`parse_skeleton`) gives every mesh with no skin of its own that sits on an animated node, or
under one, a rigid skin: one joint per animated node, every vertex 100% on its joint, the inverse bind matrix the inverse
of that node's rest matrix. A part follows its nearest animated ancestor (itself included). Meshes with no animated node
above them stay static, and a file with clips that nothing can play (no skin, no mesh on an animated node) logs one
warning that names the clips.

## How it is drawn

A skinned model with an `Animator` is drawn on the GPU: every vertex blends up to 4 joint matrices of the palette. Before
the first fixed step there is no palette yet and the model shows in its bind pose. Limits and choices:

- **Several skins:** each mesh is drawn with the palette of its own skin (a file with two skins over the same joints, one
  per hand, draws both right). The skins of a file are numbered as in the glTF; the importer's rigid skins come after.
- **At most 64 joints per skin** (3x4 matrices, 192 vec4 uniforms: fits the 256 vec4 minimum of WebGL2/GLES3). Over
  the limit the model is drawn in bind pose and a warning says so.
- Shadows follow the animation (the shadow pass uses the same palette).
- Each animated model is its own draw (a palette per entity): skinned entities never join an instanced batch, even with
  the same model. Many static copies of a model (no Animator) still instance.
- **Culling bounds:** the bounds of an animated model are the box of its bind pose carried by every joint of the palette,
  joined. It is recomputed every frame, never too small, and a little generous when a joint moves far from its vertices.
  The same box decides the camera and the shadow-light culling.

## Bones and IK

A 2D skeleton is plain entities with a `Bone2D` component, a sprite that follows them (`SpriteSkin`) and, where a limb must
reach a point, an `IK2D`. It is all `fa_scene` code: no GPU, the same numbers in a headless run, a replay and a window.

```json
{ "id": "arm", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Sprite": { "texture": "assets/arm.png", "size": [100, 24], "pivot": [0, 0.5], "meshColumns": 10, "meshRows": 2 },
    "SpriteSkin": { "bones": ["upper", "lower"] } },
  "children": [
    { "id": "arm_upper", "name": "upper", "components": { "Bone2D": { "length": 50 } }, "children": [
      { "id": "arm_lower", "name": "lower", "components": {
          "Transform": { "position": [50, 0, 0] },
          "Bone2D": { "length": 50, "minAngle": 0, "maxAngle": 150 },
          "IK2D": { "target": "hand_goal", "bend": "positive" } } } ] } ] }
```

### Bone2D

A bone is an entity of the hierarchy with a `Bone2D`. It starts at the entity's origin and runs `length` world units along
the entity's local +X axis, so the bone of a child normally sits at `position: [parent.length, 0]`. A bone is posed by its
`Transform`: write `Transform.rotation.z` (degrees) from a script, a tween or an `onFixedUpdate`; a child bone follows its
parent as every child does. Nothing is drawn for a bone unless you ask (`debug.bones()`, the editor overlay).

`minAngle` and `maxAngle` are the range `Transform.rotation.z` may take. **Only `IK2D` enforces them**: a script that
writes the rotation directly is not clamped. A range of 360 degrees or more is free (the default, -180 to 180, is free).

### SpriteSkin

`SpriteSkin` bends the picture of the `Sprite` on the same entity. It deforms the sprite's 2D mesh, which is the
`meshColumns` x `meshRows` grid of the sprite (`Sprite` doc: mesh) or, with `outline: true`, a grid cut to the opaque pixels
of the texture. A skin on a sprite with neither says so (one warning) and the sprite is drawn as a plain quad.

- `bones` lists up to 64 bones, in the order the `weights` use. An entry is a name, a path of names (`"hip/knee"`, direct
  children one after the other) or an entity id. Names are looked up under the sprite's entity first, then under each of
  its parents (so a prefab instance finds its own skeleton, wherever the sprite sits in it), then ids anywhere. A name that
  matches no `Bone2D` is left out of the skin and one warning says which and suggests the nearest names.
- **Bind pose.** The skin remembers where the bones were relative to the sprite when it was bound (`bindPose`: six numbers
  per bone, the bone's matrix in the sprite's local space; written by the engine, you do not edit it). A bone that has
  moved from there drags its vertices by the difference, so a skeleton that is moved as a whole with the sprite deforms
  nothing, and bones at the bind pose draw the sprite exactly as it is. The engine binds a skin when the scene loads, at
  the start of every fixed step (before anything moves a bone) and before drawing, whenever it has bones and no valid
  `bindPose`: pose the skeleton the way the picture was drawn, in the scene file. A skin whose bones are not all found
  yet stays unbound, draws undeformed, and is tried again each step. Set `bindPose` to `[]` to bind again at the current pose.
- **Weights.** `weights: "auto"` (the default) gives each vertex to its nearest bones: the weight of a bone is
  `1 / (d^2 + 0.25)` with `d` the distance from the vertex to the bone's segment at the bind pose, the 4 heaviest bones are
  kept, those under 2% of the total are dropped and the rest are normalised; equal weights go to the lower bone index.
  It is a pure function of the bind pose, so it is the same everywhere. For your own weights give an array with one entry
  per vertex of the grid, in the order of `Sprite.vertexOffsets` (row 0 is the top edge, left to right): each entry is
  `[bone, weight, bone, weight, ...]` with `bone` an index into `bones` and up to 4 pairs, normalised on use; a vertex
  with no valid pair follows no bone. For an `outline` skin the array is indexed by the full grid (columns x rows below).
- **Outline.** `outline: true` replaces the `meshColumns` grid: a grid with `outlineDetail` cells along the longer side of the
  sprite (2 to 64) is laid over the picture and a cell is kept when one of its pixels (plus one pixel around, so the filtered
  edge is not cut) has alpha above 5%. Transparent margins cost no fill. The traced grid is cached per texture file and
  region and forgotten when the texture is reloaded. It reads the image file itself: a texture that exists only as a
  packed atlas or as a `.ktx2` twin, or a runtime texture, cannot be traced, so the full grid is drawn and one warning
  says why. A sprite without a texture (a colour quad) is opaque everywhere.
- **Drawing.** The vertices are deformed on the CPU into the same 2D vertex stream a mesh sprite uses: no new shader, a skinned
  sprite batches with its neighbours like any mesh sprite (a hundred of them are one draw call with the same texture and
  blend), and `Sprite.vertexOffsets` (applied before the bones), `skew`, `flipX`, `tint`, lights and `layer` work as they do on a
  mesh sprite. For each vertex the order is: grid place, `vertexOffsets`, bones, `skew`, the entity's matrix. Only
  world-space sprites are skinned; a screen-space sprite with a `SpriteSkin` is drawn undeformed.
- `entity.bounds()`, the editor's picking and the selection outline use the deformed mesh.

### IK2D

`IK2D` goes on the **last bone of the chain** (the entity needs a `Bone2D`) and turns the bones above it so the tip of that
bone (its origin plus `length` along its X axis) reaches `target`, the entity whose position it follows.

| Field | Meaning |
|---|---|
| `target` | Entity to reach, by id; its world position (x, y) is the goal. |
| `solver` | `twoBone` (default): exact, for a limb of exactly two bones (this bone and its parent, which needs a `Bone2D`); `ccd`: iterative, for `chainLength` bones up the parents (1 to 16, all with a `Bone2D`). |
| `chainLength` | Bones turned by `ccd`, counting this one. |
| `bend` | `twoBone` only: which way the joint folds. `positive`: this bone ends up turned counter-clockwise from its parent (its `rotation.z` greater), `negative`: clockwise. Under a mirrored parent the result is the mirror image, so a flipped character keeps its knees. |
| `weight` | 0 to 1: how much of the solution replaces the pose the bones had before the solver ran (0 leaves it alone, 1 is the full solution, a blend turns each bone the short way). |

The solver runs once per fixed step, **after the animators have posed the bones and before the frame is drawn**, in the
order the `IK2D` components were added (when two chains share a bone the later one has the last word). It writes
`Transform.rotation.z` of the chain's bones, so whatever a clip or a script set on those bones in the same step is
replaced by the solution (use `weight` to keep part of it); the other bones keep their pose. It does not run while
`time.scale` is 0.

- **Out of reach** the chain stretches straight toward the target and stops there; `twoBone` also stops at the nearest the two
  bones can fold (the difference of their lengths) when the target is too close.
- **Angle limits** (`minAngle`, `maxAngle` of each bone) are kept: when a limit forbids the way to the target the tip falls short
  instead of breaking the joint. `ccd` repeats (at most 24 sweeps, until the tip is within 0.01 of the target) and keeps
  the limits on every turn.
- A broken `IK2D` (no `Bone2D` on its entity, no target, a parent without a `Bone2D` for `twoBone`, a `chainLength` longer than
  the bones above it) changes nothing and logs one warning for that component that says how to fix it.
- The solvers use `fa::det` trigonometry and the skin only `+ - * /`, so the same scene gives the same bits on every
  platform and in a replay.

### Scripts, debugging and cost

```js
import { Behaviour, debug, input, world } from "factoria";
export default class Reach extends Behaviour {
  onUpdate() {
    world.find("hand_goal").position = [input.mouse.world.x, input.mouse.world.y]; // the IK2D follows it at the next fixed step
    debug.bones(this.entity);                               // draws every Bone2D of this entity and below, for one frame
  }
}
```

`debug.bones(root?, color?)` draws a thin kite from the origin to the tip of every `Bone2D` of `root` and its descendants (all
the bones of the scene without `root`). In the editor, **Selection overlay** draws the bones of the selected entity and
those its `SpriteSkin` names. `Bone2D`, `SpriteSkin` and `IK2D` are components like any other: `entity.get("Bone2D").length`,
`entity.add("IK2D", { target: goal })`, `entity.transform.rotation = [0, 0, 30]`.

A skinned vertex costs one weighted sum of at most 4 matrices, so skins are cheap: the `skinned-sprites` fixture
(`tools/cli/tests/fixtures/skinned-sprites`: 50 skinned 8 x 2 sprites, 10 with `IK2D`, bones swung by a script every frame) is
one draw call, and its `drawCalls` and `entities` are checked by `tools/cli/tests/perf/skinned-sprites.perf.json`. Keep grids
small (8 x 8 is plenty for a limb; an outline of 16 to 24 cells for a body).

Not there yet: a bone editor in the viewport (bones are moved with the Transform gizmos and the Inspector) and weight painting,
3D bones (use the `Animator` with a glTF skin), and skinning of screen-space sprites.

## Tweens

```js
import { tween, ease, cancelTweens } from "factoria";

tween(panel.position, { x: 0 }, { duration: 0.4, ease: "backOut" });           // vectors: x / y / z
tween(sprite, { color: "#ff0000" }, { duration: 1 });                           // colors: "#rrggbb", [r,g,b,a], {r,g,b,a}
tween(sprite.color, { a: 0 }, { duration: 0.5, delay: 1 });                     // single channels
tween(hero.transform, { rotation: [0, 180, 0] }, { duration: 1, ease: ease.sineInOut });
tween(0, 100, { duration: 2, onUpdate: (v) => label.text = String(Math.round(v)) });   // just a number

const t = tween(coin.position, { y: 2 }, { duration: 0.5, yoyo: true, repeat: Infinity, ease: "quadInOut" });
t.cancel();                                  // values stay where they are; t.pause() / t.resume() also exist

await tween(state, { open: 1 }, { duration: 1 }).finished;         // Promise<boolean>: true done, false if YOU cancel it
await this.tween(this.entity.position, { y: 3 }).finished;         // in a Behaviour: dropped if the entity dies (see below)
tween(a, { x: 1 }).next(a, { y: 1 }).next(b, { a: 0 });             // a chain; cancelling one cancels the rest
```

Options: `duration` (default 1 s), `delay`, `ease`, `repeat` (extra plays; `Infinity` forever), `yoyo` (every second play runs
backwards), `from` (start values instead of the current ones), `onStart`, `onUpdate`, `onComplete`.

- Start values are read when the delay ends, not when `tween()` is called.
- The target's end value is set exactly when the tween ends (even for easings that overshoot).
- `cancelTweens()` cancels all, `cancelTweens(target)` those of one target, `tween.cancel()` one: their `finished`
  resolves `false`, because your own code asked for it.
- A tween is DROPPED, not cancelled, when its target entity is destroyed, when the Behaviour that started it with
  `this.tween(...)` is destroyed, or when the scene is reloaded or unloaded. A dropped tween ends quietly and its
  `finished` promise stays pending forever, so the code awaiting it never resumes: `await tween(e.position, {y: 3}).finished;
  e.position.x = 0;` cannot throw `entity was destroyed` after the entity is gone, and needs no `if (e.alive)`.
  Nothing is leaked: the pending promise and the suspended function are garbage as soon as the tween is dropped. The
  price is that a dropped `finished` never settles either: do not `await Promise.all([...finished])` where the code after
  it must always run; use `onComplete` or check `t.active` there. `this.wait(seconds)` is the same for a timer: a
  Promise that resolves after `seconds` of game time and never resolves if the entity is destroyed first.
- Freezing and inspecting: tweens run on the game clock, so `game.pause` freezes them (the engine simulates nothing) and
  `game.step` moves them by exactly the frames you ask; `time.scale = 0` freezes them too. `tween.pauseAll()` /
  `tween.resumeAll()` freeze every tween (also ones started later) without touching `time.scale`, so a script or an
  agent can set a pose and look at it without a tween overwriting it; `tween.timeScale = 0.5` runs all tweens at half
  speed (on top of `time.scale`; 0 freezes; negative throws). A scene load resets both. `t.seek(seconds)` jumps one
  tween to a time after its creation (the delay counts), also backwards and also while paused, and applies the values
  at once; past the end it completes. It throws on a tween that already completed or was cancelled.
- The easings: `linear` and, for each of `quad cubic quart quint sine expo circ back elastic bounce`, the names ending in
  `In`, `Out` and `InOut` (`"quadOut"`, `"bounceOut"`). `ease.<name>` is the function `(t) => t` if you want to call it
  yourself; `ease` is also what you pass as `ease: myFunction`. `InOut` plays the In curve for the first half and its
  mirror image for the second (back and elastic are symmetric, a little different from CSS).
- Tweens advance in the engine's update with the game's `dt`, in the order they were created.

## Example: a character that walks, runs and jumps

```js
import { Behaviour, input, audio } from "factoria";

export default class Hero extends Behaviour {
  onStart() {
    this.anim = this.entity.animator;
    this.anim.on("footstep", () => audio.play("assets/sounds/step.wav", { volume: 0.5 }));
  }
  onFixedUpdate(dt) {
    const x = input.axis("move_left", "move_right");
    this.anim.set("speed", Math.abs(x) * 6);
    this.anim.set("grounded", this.entity.isGrounded());
    if (input.pressed("jump")) this.anim.trigger("jump");
  }
}
```

## Not there yet

- More than 64 joints in one skin: that part is drawn in its bind pose (not animated) and a warning names the limit;
  re-export it with fewer joints (rigid parts are split over several skins of 64 joints, so they have no such limit).
- Morph targets and root motion are not supported for glTF models. Animation layers and masks exist for 2D clips only
  (see "2D clips").
- 2D clips have no timeline or keyframe recording in the editor yet: write the `*.anim.json` by hand or with a script. A
  clip poses bones the same way it moves any entity, through their Transform (see [Bones and IK](#bones-and-ik)).
