# Animation: skeletal clips, state machines and tweens

Four tools, from "a character walks" to "a menu panel slides in":

| Tool | For | Where it lives |
|---|---|---|
| `Animator` component | Play the animation clips of a skinned glTF model, blend between them, react to clip events, switch with a small state machine | scene JSON + `entity.animator` |
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
- Morph targets, animation layers/masks and root motion are not supported.
