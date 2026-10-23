# Animation: skeletal clips, state machines and tweens

Three tools, from "a character walks" to "a menu panel slides in":

| Tool | For | Where it lives |
|---|---|---|
| `Animator` component | Play the animation clips of a skinned glTF model, blend between them, react to clip events, switch with a small state machine | scene JSON + `entity.animator` |
| `tween()` / `ease` | Move any number, vector or color over time (UI, cameras, pickups, 2D and 3D) | `import { tween, ease } from "factoria"` |
| `SpriteAnimator` | Frame-by-frame 2D sprite sheets | see [ASSETS.md](ASSETS.md) |

Both new tools run on the game clock: the fixed step and `time.scale` (a paused game pauses them), never the wall clock, so
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

await tween(state, { open: 1 }, { duration: 1 }).finished;         // Promise<boolean>: true done, false cancelled
tween(a, { x: 1 }).next(a, { y: 1 }).next(b, { a: 0 });             // a chain; cancelling one cancels the rest
```

Options: `duration` (default 1 s), `delay`, `ease`, `repeat` (extra plays; `Infinity` forever), `yoyo` (every second play runs
backwards), `from` (start values instead of the current ones), `onStart`, `onUpdate`, `onComplete`.

- Start values are read when the delay ends, not when `tween()` is called.
- The target's end value is set exactly when the tween ends (even for easings that overshoot).
- A destroyed target ends its tween quietly. `cancelTweens()` cancels all, `cancelTweens(target)` those of one target;
  a scene change cancels all (their `finished` resolves `false`).
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
- Morph targets, animation layers/masks and root motion are not supported.
