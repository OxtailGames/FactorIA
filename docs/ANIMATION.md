# Animation: skeletal and 2D clips, state machines and tweens

Tools, from "a character walks" to "a menu panel slides in":

| Tool | For | Where it lives |
|---|---|---|
| `Animator` component | Play the animation clips of a skinned glTF model, blend between them, react to clip events, switch with a small state machine | scene JSON + `entity.animator` |
| `*.rig.json` | A skeleton (humanoid, quadruped, bird, tail, chain, generic) fitted to a model document and saved as a glTF skin: the joints a model is animated with | [RIGGING.md](RIGGING.md) |
| `Animator` + `*.anim.json` | Keyframed 2D clips that animate any field of an entity and its children (a character built in parts), with layers and masks | [2D clips](animation/ANIMATION_2D.md#2d-clips-animjson) |
| `tween()` / `ease` | Move any number, vector or color over time (UI, cameras, pickups, 2D and 3D) | `import { tween, ease } from "factoria"` |
| `SpriteAnimator` | Frame-by-frame 2D sprite sheets, played by clip name | [Sprite sheets](animation/ANIMATION_2D.md#sprite-sheets-spriteanimator) |
| `Bone2D`, `SpriteSkin`, `IK2D` | 2D bones: a sprite bent by the bones it is bound to, and chains that reach for a target | [Bones and IK](animation/ANIMATION_2D.md#bones-and-ik) |
| `Animator` + `*.anim.json` (`factoria.anim3d/1`) | Keyframed clips for the bones of a skinned `.rig.glb`, made by hand or by the generators (walk, run, idle, swing, hit), retargeted between rigs | [3D bone clips](animation/ANIMATION_3D.md#3d-bone-clips) |
| `IK3D` | 3D inverse kinematics on a skinned model: two-bone limbs with a pole, look-at with limits, foot placement | [3D IK](animation/ANIMATION_3D.md#3d-ik) |

The tools run on the game clock: the fixed step and `time.scale` (a paused game pauses them), never the wall clock, so
a headless run, a replay and the test runner see exactly what a player sees.

## Pages

This page has the overview and the Animator component with its state machine. The rest is on three pages (`docs.read animation-2d`, `animation-3d`, `animation-tweens`; a heading is found on its page by itself):

- [2D animation](animation/ANIMATION_2D.md): `*.anim.json` clips, SpriteAnimator sprite sheets, rigid parts, Bone2D, SpriteSkin and IK2D.
- [3D animation](animation/ANIMATION_3D.md): 3D bone clips, 3D IK, generators, retargeting and previews.
- [Tweens and examples](animation/ANIMATION_TWEENS.md): `tween()` and `ease`, two worked examples, what is not there yet.

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

An event can also carry game feel actions, with or without a `name`: `{ "clip": "Walk", "time": 0.25, "feel": { "action":
"spawn", "prefab": "prefabs/dust.prefab.json", "lifetime": 0.5 } }` runs the effect for the entity that plays the clip when the
event fires (shake, hit-stop, flash, push, squash, spawn, sound: [GAME_FEEL.md](GAME_FEEL.md), "Effects as data").

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
