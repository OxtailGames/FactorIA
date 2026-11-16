# Animation: tweens and worked examples

Part of [Animation](../ANIMATION.md): tweens, two worked examples and what is not there yet.

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

**A dawn: tween the scene's environment.** `world.settings` is the scene's `SceneSettings` (`skyColor`, `horizonColor`,
`ambientLight`, `fogColor`, `fogDensity`, `lightScale`...), and it is a tween target like any component: colours move
together, so the whole sky changes in one call and no script writes six values every frame.

```js
import { tween } from "factoria";

world.settings.skyColor = "#05060f";                    // night
world.settings.ambientLight = [0.05, 0.05, 0.1, 1];
world.settings.fogDensity = 0.08;

await tween(world.settings, {                           // five seconds to dawn
    skyColor: "#ffb070", horizonColor: "#ffd9a0",
    ambientLight: [0.6, 0.45, 0.4, 1],
    fogColor: "#f4d6b0", fogDensity: 0.01,
}, { duration: 5, ease: "sineInOut" }).finished;
```

Fields the tween does not name keep their value. The tween belongs to the scene: if another scene loads, the tween is
dropped and the `await` never returns, so nothing after it runs. A directional `Light`
entity (the sun or moon) is tweened the same way, `tween(sun.get("Light"), { color: "#ffcc88", intensity: 1.2 }, ...)`.

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

## Example: a character built in parts (Sky Hopper)

(To get the parts, joints, hierarchy and `Bone2D`s from one SVG with no hand work, see `vector.to_rig` in
[VECTOR.md](../VECTOR.md), "Characters in parts": it writes the atlas and the prefab, and a wave clip for it is the worked example there.)

`examples/sky-hopper` draws its hero and its crawler this way. Nothing here is a skinned 3D model or a drawn sprite sheet:
the art is SVG parts, the motion is data.

1. **Parts.** One SVG per part (`assets/src/svg/hero/*.svg`) goes through `assets.rasterize_svg` to PNGs in
   `assets/src/parts/hero`, and `assets.pack_atlas` packs them into `assets/parts_atlas.png` with a frame table that keeps
   each part's pivot (`pivots.json`). The recipes are in `assets.json`: change an SVG and `assets.regenerate` redraws the
   PNG and then the atlas. `export.exclude: ["assets/src/**"]` keeps the sources out of the shipped game.
2. **Hierarchy.** `prefabs/player.prefab.json` is a root (the physics body, the Animator, a `Tint` that fades the whole
   subtree) with a `rig` child and one child Sprite per part: `body`, `head`, `arm_f`, `arm_b`, a `hip` with
   `thigh_*` / `shin_*`, and a `foot` under each IK target. A Sprite's `region` is its rectangle in the atlas and its
   `pivot` is the joint (the shoulder, the hip, the knee), so rotating the entity turns the part about the joint. The
   `layer` orders the parts (back arm and back leg below the body, head and front arm above); inside one layer the draw
   order is by y, so give parts that must not swap different layers. Mirroring the character is
   `rig.transform.scale.x = -1`: every part flips and the IK keeps the knees pointing forward.
3. **Bones.** The legs are `Bone2D` chains (`thigh` and `shin`, `length` to the next joint) with an `IK2D` on each shin
   (`twoBone`, `chainLength` 2, `bend` so the knee faces forward). The scarf is one Sprite with a `SpriteSkin` over two bones
   (`s1`, `s2`), `weights: "auto"`: it is the only part that bends, so it is the only one that is skinned.
4. **Clips.** `anim/hero_idle.anim.json`, `hero_walk` and `hero_jump` are keyframed tracks on the parts by path
   (`"rig/body/hip/thigh_f"`; a nested bone spells every level: `"rig/body/scarf/s1/s2"`). The walk clip moves two marker
   entities, `gait_f` and `gait_b` (a stride along x and a lift while the foot swings), not the legs: the IK moves the legs
   to where the foot goes. The walk has a `footstep` event on each plant.
5. **State machine.** The Animator of the prefab has `params` `speed` and `grounded`, states `idle`, `walk` and `jump`
   (`loop: false`) and transitions with a `fade`: `idle` to `walk` when `speed > 0.1`, any state to `jump` when `!grounded`,
   `jump` back to `walk` or `idle` when it lands.
6. **Script.** `scripts/player.js` only feeds it, once per fixed step. The feet are data: each shin's `IK2D` has
   `groundMask: 1`, `groundReach`, `groundOffset` and `groundRest`, so the engine aims the foot at the floor under the marker
   the walk clip moves and keeps the swing lift. The script switches the snapping off in the air:

```js
onFixedUpdate(dt) {
  const grounded = this.entity.isGrounded();
  const speed = Math.abs(this.body.velocity.x);
  this.anim.set("speed", speed);
  this.anim.set("grounded", grounded);
  this.anim.speed = this.anim.state === "walk" ? Math.min(1.5, Math.max(0.6, speed / 200)) : 1;  // stride follows speed
  for (const ik of this.legs) ik.groundMask = grounded ? 1 : 0;  // this.legs: the IK2D of each shin
}
```

   A script's `onFixedUpdate` sees the pose of the previous step (see "Frame order and where IK goes"), and the IK, which
   runs right after the Animator, reaches the target of the same step. In the air (`groundMask = 0`) the marker alone decides
   and the legs tuck. The character has a `RigidBody2D`: that entity is the `root` of the rule in "Planted feet".
7. **Bake what does not need to be alive.** The crawler is built in parts too (`prefabs/crawler_rig.prefab.json`, clips
   `crawl` and `alert`), but there can be many of them, so it is baked: `assets.bake_sheet` with
   `clips: [{"name":"crawl","clip":"crawl"},{"name":"alert","clip":"alert"}]` and `scale: 2` writes
   `assets/crawler_sheet.png` (10 frames) with its `sheet` entry, and the game draws one Sprite and a `SpriteAnimator` per
   crawler, 1 entity instead of 6. The recipe is in the provenance (docs/ASSETS.md, "Bake by clip name"); the player stays
   a live rig because its feet follow the ground.

## Not there yet

- More than 64 joints in one skin: that part is drawn in its bind pose (not animated) and a warning names the limit;
  re-export it with fewer joints (rigid parts are split over several skins of 64 joints, so they have no such limit).
- Morph targets and root motion are not supported for glTF models (a 3D clip's `root` translation moves the model inside its
  entity; the entity moves at the clip's `groundSpeed` only if a script does it). Animation layers and masks exist for 2D clips only
  (see "2D clips").
- The editor's Animation panel edits 3D bone clips of a rigged model (keys, gizmo, IK handles, events), but one clip at a time and
  without `IK3D`: `anim3d.preview` and `ik3d.solve` show a clip or a solver without a scene, and the preview poses the clip only. Foot placement needs 3D colliders to hit and a flat, mostly-horizontal ground
  (a step taller than `rayUp`/`rayDown` or the pelvis limits is not followed).
- A clip poses bones the same way it moves any entity, through their Transform (see [Bones and IK](ANIMATION_2D.md#bones-and-ik)). The
  editor's Animation panel edits one clip at a time: `Animator.layers` and the state machine are set in the Inspector.
