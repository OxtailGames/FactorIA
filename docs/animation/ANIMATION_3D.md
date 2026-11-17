# Animation: 3D bone clips and IK

Part of [Animation](../ANIMATION.md): 3D bone clips, 3D IK, generators, retargeting and previews.

## 3D bone clips

A skinned model made by `rig.bake` ([RIGGING.md](../RIGGING.md)) is animated with the same `*.anim.json` files, whose `format` is
`factoria.anim3d/1` (`schemas/anim3d.schema.json`). A 2D clip drives fields of entities; a 3D clip drives the **bones** of the
skin, each named by its canonical name (`thigh_l`, `spine_2`, `root`). The keys (`t`, `value`, `interp`, `in`, `out`), the easings
and the events are the ones of the 2D clips.

```json
{ "format": "factoria.anim3d/1",
  "rig": "assets/models/hero.rig.json", "template": "humanoid",
  "duration": 1.0, "loop": true, "groundSpeed": 1.26,
  "tracks": [
    { "bone": "thigh_l", "channel": "rotation",
      "keys": [ { "t": 0, "value": [-28, 0, 0] }, { "t": 0.5, "value": [24, 0, 0], "interp": "quadInOut" }, { "t": 1, "value": [-28, 0, 0] } ] },
    { "bone": "root", "channel": "translation",
      "keys": [ { "t": 0, "value": [0, -0.03, 0] }, { "t": 0.25, "value": [0, 0, 0] }, { "t": 0.5, "value": [0, -0.03, 0] } ] } ],
  "events": [ { "t": 0.0, "name": "footstep", "data": { "bone": "foot_l" } } ],
  "contacts": [ { "bone": "foot_l", "from": 0.0, "to": 0.6 } ] }
```

- **Channels.** `rotation` is the bone's rotation from its rest pose, in degrees as `(x, y, z)` = (pitch, yaw, roll) in the
  engine's order (`Quat::from_euler_deg`), in the bone's local frame; with `"rotation": "quat"` at the top of the file the values
  are quaternions `(x, y, z, w)`. Every `rig.bake` bone rests with an identity rotation, so the rotation is the bone's local
  rotation in a frame with the model's axes (+Y up, the character faces +Z; +X rotation tips an upward-pointing bone towards +Z).
  `translation` is an offset from the rest position in the parent's frame, in model units (normally only `root` has one).
  `scale` multiplies the rest scale per axis. A bone with no track rests.
- **`contacts`** say when a bone rests on the ground (`from`/`to` in seconds; `from > to` wraps through the end of a looping clip).
  `groundSpeed` is the speed in model units per second at which the ground moves under the feet in stance. The generators write
  both; retargeting uses them to keep feet planted; `anim3d.info` and the preview show them. A hand-made clip may leave them out.
- **`rig`/`template`** record what the clip was made for (informational; `anim3d.retarget` reads them). `generated` records the
  generator and its parameters.
- Errors name the file and a JSON pointer like the 2D clips: a track on a bone the rig lacks gets "did you mean", a key out of
  order or after `duration` says how to fix it. Numbers are written with 7 digits so the files stay stable and readable.

### Playing them

Put the clips in the `Animator.clips` of the entity that has the skinned model (its `MeshRenderer.mesh` or `Animator.model` is the
`.rig.glb`):

```json
{ "components": {
    "MeshRenderer": { "mesh": "assets/models/hero.rig.glb" },
    "Animator": { "clips": { "walk": "anim/hero_walk.anim.json", "idle": "anim/hero_idle.anim.json" }, "clip": "idle" } } }
```

An Animator whose model is a glTF treats `clips` as 3D clips (without a model they are the 2D clips above). The clips sit next to
the glTF's own animations: `clip`, `animator.play("walk", fade)` with cross-fades, `states` and `transitions`, `speed`, `loop` and
`events` work as they do for those (a state's own `loop` wins, else the file's `loop`; a clip name in `clips` wins over a glTF
animation of the same name). The clip's own events are sent when its time passes them, with `{clip, time}` plus the event's
`data`, to `world.on(name, fn)` and `entity.animator.on(name, fn)`. A bone the model lacks is skipped with one warning that
points at `anim3d.retarget`; a file that does not load, or is a 2D clip, is skipped with one warning and `play` of its name says
why. Nothing is baked into the `.glb`; assigning `clips` again rebuilds the bindings (the files are cached by path and
modification time). The pose is the same on every platform: sampling uses `+ - * /` and `fa::det` trigonometry only.

`factoria validate` checks the 3D clips (the file, the bones against the model of the Animator that names it) and an `IK3D` against the model's
bones. A 3D clip is made, edited and previewed with the commands below, and the editor's Animation panel edits it too: its dopesheet,
the rotation gizmo and the IK handles in a 3D viewport of the posed model are these commands (see [EDITOR.md](../EDITOR.md), "Animation panel", "3D bone clips").

### Commands for 3D clips

| Command | What it does |
|---|---|
| `anim3d.generators {}` | The catalog of generators with every parameter's doc, default and range. |
| `anim3d.generate {rig, kind, params?, out?, overwrite?}` | Makes a clip for a rig (`.rig.glb` or `.rig.json`): `kind` is `walk`, `run`, `trot`, `gallop`, `idle`, `swing` or `hit`; `out` defaults to `anim/<rig>_<kind>.anim.json`. Returns the contacts and the Animator snippet. |
| `anim3d.create {path, duration, loop?, rotation?, rig?, doc?, overwrite?}` | An empty clip, to fill with `anim3d.set_keys`. |
| `anim3d.set_keys {path, bone, channel?, keys, duration?, rig?}` | Adds or replaces keys (within 1e-4 s of an existing key replaces it) of one bone's channel; with `rig` the bone must exist. The whole clip is checked before it is written, so a refused edit leaves the file untouched. |
| `anim3d.remove_track {path, bone, channel?}` | Removes the track of that channel, or every track of the bone without `channel`. |
| `anim3d.info {path?, rig?}` | The clip's bones, channels, keys, events and contacts, or (no path) every 3D clip of the project; with `rig` it also lists the bones the rig lacks (`rigCheck`). |
| `anim3d.retarget {path, to, from?, out?, plantFeet?, scale?, fps?, overwrite?}` | See "Retargeting". |
| `anim3d.preview {path, rig, frames?, cell?, yaw?, yaws?, pitch?, out?, overwrite?}` | See "Previewing a clip". |
| `anim3d.move_keys {path, keys, dt, extendDuration?}` | Moves keys by `dt` seconds. `keys` is `[{bone, channel?, t}]` (channel `rotation`, `translation` or `scale`). Refused when a key would land before 0, on another key, or past the end without `extendDuration`. |
| `anim3d.remove_keys {path, keys}` | Removes those keys (a track left with no key is removed too). |
| `anim3d.set_interp {path, keys, interp}` | Sets how the segment after each key is interpolated: `linear`, `step`, `bezier` or an easing name of `tween()`. |
| `anim3d.set_clip {path, duration?, loop?, groundSpeed?, doc?}` | Changes the clip's own fields (the file is parsed again before it is written, so a clip the format refuses is not saved). |
| `anim3d.add_event {path, t, name?, data?, feel?, extendDuration?}` / `anim3d.set_event {path, event, t?, name?, data?, feel?, extendDuration?}` / `anim3d.remove_event {path, event}` | Clip events (`event` is the index in the clip's list, in time order). |
| `anim3d.mirror_pose {path, rig, time?, from?, to?, interp?}` | Keys the pose at `time` mirrored left/right at `to` (default the same time): `from` is `swap` (the default: both sides trade places), `left` (the left pose is copied onto the right) or `right` (the other way). Bones are paired by their `_l` / `_r` names; bones on the mid plane are mirrored in place. |
| `ik3d.key {path, rig, time?, solver, interp?, groundHeight?}` | Runs one IK solver (a `two_bone` with a pole, or a `look_at`, the objects of `ik3d.solve`) on the clip's pose at `time` and keys the bones it moved. |
| `anim3d.restore {path, clip, provenance?}` | Writes `clip` (the whole document) back, or deletes the file and its `assets.json` record when `clip` is null. `provenance` (what every `undo` carries) is the record to put back exactly, with its recipe (it needs `origin` and `date`; null removes it; ignored with a null `clip`). Every writing `anim3d.*` command returns the call that undoes it as `undo`; the editor keeps that on its undo stack. |
| `ik3d.check {rig, solvers}` | Checks `IK3D.solvers` against a rig: every problem with its JSON pointer, what is wrong and how to fix it. |
| `ik3d.solve {rig, solver, clip?, time?, groundHeight?}` | Runs one solver offline on the rig's rest pose or a clip's pose at `time` and tells where the bones end up. |

## 3D IK

The `IK3D` component goes on the entity that has the `Animator` of a skinned model. After the Animator has posed the bones in
the fixed step (`update_animators`), the engine runs `update_ik3d` ("After the Animator, before drawing" in `engine.cpp`), copies the animated
pose, applies the `solvers` in order and draws the result. The animated pose is not modified: with `enabled: false`, `weight: 0` or no
solvers the model is drawn as the clip posed it. `weight` multiplies every solver's own `weight`.

```json
"IK3D": { "solvers": [
  { "type": "lookAt", "bone": "head", "target": "player", "yawLimit": 70, "pitchLimit": 40 },
  { "type": "twoBone", "limb": "arm", "side": "r", "target": "lever_handle", "pole": [0.5, 1.2, -0.5] },
  { "type": "foot", "side": "l" }, { "type": "foot", "side": "r" } ] }
```

A target (`target`, `pole`) is an entity id or name, a world position `[x, y, z]`, or `{"entity": "player", "offset": [x, y, z]}`.
Every solver also has `name`, `weight` (0..1) and `enabled`. A solver with a problem (a bone the model lacks, a wrong key) is
skipped and logged once; its entry in `IK3D.status` says `problem: true`, and `ik3d.check` lists every problem with its pointer.

| Solver | Keys | What it does |
|---|---|---|
| `twoBone` | `limb` (`arm`\|`leg`) + `side` (`l`\|`r`), or `root`, `mid`, `end` bone names; `target`; `pole`? | Turns the two bones so the head of `end` (a hand or an ankle) reaches the target. The middle joint bends towards `pole` (the plane of root, target and pole); without a pole it keeps the side it bends to. Out of reach the limb stretches straight towards the target (`reached: false` in the status, `error` is the distance left). `arm` is `arm_upper`, `arm_lower`, `hand` (the front leg of a quadruped too), `leg` is `thigh`, `shin`, `foot`. |
| `lookAt` | `bone`; `target`; `forward` (`"+z"` default, an axis name or `[x, y, z]`); `yawLimit` (70); `pitchLimit` (45); `turnSpeed` (360 degrees per second, 0 = snap) | Turns the bone so its `forward` axis points at the target, within the limits measured from where the animation aims it. The status has `clamped` (the target is beyond the limits: the bone aims as far as they allow), `yaw` (positive turns +Z towards +X, character-left) and `pitch`. With no target the bone eases back to the animated aim. |
| `foot` | `side` or `thigh`, `shin`, `foot`; `footHeight`; `alignToGround` (true); `maxFootAngle` (30) | Foot placement: casts a ray down from each foot, puts the ankle on the ground (the foot's rest height above the model's origin, or `footHeight`) and tilts the foot to the ground's normal up to `maxFootAngle`. The ankle only follows the ground while the animated foot is near it (a foot in the air in a swing keeps its path). |

Foot placement is shared by all `foot` solvers (it runs at the first one): the **pelvis** bone (`IK3D.pelvis`, `root` by default)
moves down to the lowest ground under the feet (at most `maxPelvisDrop`, or up `maxPelvisRise`) so the legs can reach it, and
`pelvisSmooth` seconds smooth the changes so steps do not jerk. The ray starts `rayUp` world units above the animated foot and reaches
`rayDown` below it, hits the layers of `groundMask`, and ignores the entity's own colliders. It needs a physics world with colliders;
without a hit (no ground under the foot) the foot keeps the animated pose. Only the geometry the physics world has can be hit.

`IK3D.status` is an array, one object per solver `{name, type, active, ...}` with the results above (`reached`/`error`,
`clamped`/`yaw`/`pitch`, `contact`/`lift` for feet), readable from scripts: `e.get("IK3D").status`. Scripts change a target by
assigning `solvers` (or the solver's `target`) and read or set any other field the same way, the way they do any component.

```js
const ik = this.entity.get("IK3D");
ik.solvers = [{ type: "lookAt", bone: "head", target: "player" }];   // look at the player
this.after(2, () => { ik.weight = 0; });                              // two seconds later, stop
```

## Generators

`anim3d.generate {rig, kind, params}` makes a clip from the rig's proportions and a few numbers instead of keys typed by hand.
The result is an ordinary 3D clip that `anim3d.set_keys` can then change key by key. Every parameter is optional, unknown ones are an
error with "did you mean", and the clip's `generated` records the kind and every value used, so the same call writes the same bytes.
`anim3d.generators` lists them all with ranges and defaults.

| Kind | For | Makes |
|---|---|---|
| `walk` | humanoid, bird, quadruped | A walk cycle with planted feet; the lateral-sequence walk on four legs. |
| `run` | humanoid, bird, quadruped | A run with a flight phase (the gallop on four legs). |
| `trot`, `gallop` | quadruped | The diagonal-pair trot and the transverse gallop. |
| `idle` | humanoid, bird, quadruped | Breathing, a slow weight shift and a swaying tail; the feet do not move. |
| `swing` | any rig with those bones | A tail, tentacle, antenna or chain swinging (`bones`, `period`, `amplitude`, `lag`, `growth`...). |
| `hit` | humanoid, bird, quadruped | A hit reaction: the torso recoils from `fromAngle`, the head lags, everything settles; plays once and sends `event`. |

A gait is built from foot paths, not from joint angles: each foot stands still on the ground in stance (relative to the ground it
moves back at the walking speed), lifts, passes the body and lands one `strideLength` further; the pelvis follows a bounce curve
(`bounce`, `crouch`), lowered only as far as the legs need; a two-bone solver puts each ankle on its path. So the feet do not
slide: the clip's `contacts` say when each is planted and `groundSpeed` (= `strideLength` x `cadence`) is the speed a character must
move at for the feet to stand still on the floor. Stride, cadence and duty (the fraction of the cycle on the ground; below 0.5 both
feet leave the ground, a run) default to values proportional to the leg length of the rig, so a giant and a dwarf each get a fitting
stride. The arms swing against the legs (`armSwing`, `elbowBend`), the torso leans and twists (`lean`, `twist`), the hips sway
(`hipSway`) and the tail follows (`tailSwing`). A `footstep` event (`footstepEvent`, empty = none) is sent when a foot lands, with
`data.bone`. Errors say what the rig lacks (legs, spine, tail) and which template has it.

Example: `factoria call anim3d.generate '{"rig":"assets/models/hero.rig.glb","kind":"walk","params":{"strideLength":1.6}}'`
writes `anim/hero_walk.anim.json` (the default `out` is `anim/<rig file name without .rig.glb>_<kind>.anim.json`).

The clip gets a provenance record in `assets.json` with a recipe whose input is the rig, so `assets.regenerate {"stale": true}`
makes it again after the rig is fitted again. `anim3d.retarget` does the same (inputs: the source clip and both rigs). Editing
a clip by hand (`anim3d.set_keys`...) removes the recipe.

## Retargeting

`anim3d.retarget {path, to, out, from?}` carries a clip from one rig to another: a walk made for one humanoid plays on another
humanoid with other proportions (or a bird, or the legs of a quadruped). `from` defaults to the rig the clip says it was made for.

- Bones are matched by their canonical **(role, index, side)** triple, not by name.
- A matched bone gets the source's track: rotations are copied (every rest pose is an identity rotation, so a rotation means the
  same on either rig), translations are scaled.
- A chain with a different number of bones (`spine_1..3` against `spine_1..2`, a longer tail) keeps its total bend: the source's
  rotations are composed and shared evenly; the keys of such a chain become linear keys at the union of the source key times
  (`resampled` lists the roles).
- A bone with no counterpart (a tail on a rig without one, toes) is `dropped` and listed; the target's bones the clip does not move
  rest.
- The root translation, the `groundSpeed` and the feet are scaled by the ratio of the leg lengths (hip to ankle), or by `scale`.
- **Planted feet.** If the clip has `contacts` and `plantFeet` is true (the default), the legs with a contact are solved again with
  the two-bone solver: each ankle follows the source ankle's path (its offset from the rest pose, scaled), so a foot that stands still on
  the ground in the source stands still in the result whatever the proportions. The legs are sampled at `fps` keys per second (30)
  for that. A leg that cannot reach is stretched straight and told in `notes`. Without contacts the rotations are simply copied.

The result has `scale`, `mapped`, `dropped`, `resampled`, `planted` and `notes`, and is written to `out` (required; `overwrite` replaces a file). Its
`rig` is the target rig; a retargeted clip keeps the source's `generated`.

## Previewing a clip

`anim3d.preview {path, rig, frames?, cell?, yaw?, yaws?, pitch?, out?}` skins the model on the CPU at `frames` (2 to 12, default 8) evenly
spaced times of the clip and draws them with the software renderer of `model.preview` into one labelled picture (the time under each
cell, the bones in contact marked). No window or GPU is needed, the picture is the same on every machine, and the poses are the ones the
Animator plays (foot placement and look-at are not part of it: `ik3d.solve` shows a solver). The cells share one framing so the
walking distance is visible. `yaw` -90 shows a character that faces +Z from the side, facing right (the default is -70); `out` keeps a PNG
(`overwrite` replaces one). `yaws` is a list of 1 to 6 angles (degrees, 0 = front, 90 = the character's left; at most 48 poses in all) and makes a filmstrip: one row of cells per angle, the same times in
every row (give `yaws` or `yaw`, not both), so a gait is seen from the side, the front and the back at once; the Animation panel's
**Filmstrip** button calls it with `[-70, 0, 90]`. A bad rig, a clip that drives bones the rig lacks or a missing file is an error that says which.
