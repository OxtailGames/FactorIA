# Gem Roller

A FactorIA 3D arcade game: roll a ball across floating platforms, ride two moving ones, and collect every gem
before the 90 second timer runs out. A fall costs 5 seconds and puts you back at the last checkpoint. Meshes are
built-in primitives plus one gem model, `assets/models/gem.glb`, baked from the recipe `assets/models/gem.model.json` (a cut-gem outline turned with `lathe`, flat shaded: edit it with `model.edit`, look at it with `model.preview` and `model.check`, or open it in the editor's Model panel, then bake with `model.bake`); the sounds are placeholders in `assets/sfx/`. The two textures, `assets/textures/ball.png` and `tile.png`, are baked from layered image documents (`ball.image.json`, `tile.image.json`: fills in a few layers): change a layer and run `image.bake` to remake the PNG.

```bash
factoria validate
factoria run                                   # play
factoria run --headless --frames 60 --screenshot-at 59
factoria test
```

Controls: W/A/S/D or the arrows roll the ball relative to the camera, Space jumps, Q/E orbit the camera, R restarts.

## What is where

- `scenes/main.scene.json`: the level. A start platform, four more platforms, the goal platform, two kinematic
  movers (`mover_1`, `mover_2`), three checkpoints, the ball, the chase camera, a sun, the game manager and the HUD.
- `scripts/`: `ball.js` (camera-relative control, jump, respawn), `chase_camera.js` (orbiting chase camera),
  `mover.js` (kinematic platform), `checkpoint.js`, `gem.js` (pickup), `game.js` (timer, counter, HUD, win/lose).
- `assets/models/gem.model.json`: the gem's model document (docs/MODELING.md). `gem.glb` next to it is what it bakes to;
  the test fails when the .glb is older than the document.
- `assets/vfx/gem_burst.vfx.json`: the pickup effect a gem plays when it is picked up: sparks, a flash of light and the sound.
- `scripts/scatter_gems.js` places N gems on the platforms (entities tagged `platform`), deterministically from a
  seed; `game.js` imports it on start, so the layout is the same on every run and the exported game needs no tool
  (`tools/` is not shipped). `tools/scatter_gems.js` is the project tool `project.scatter_gems` over the same module:
  `factoria call project.scatter_gems '{"count":8,"seed":7,"clear":true}'`.
- `assets/models/scout.model.json`, `scout.rig.json`, `assets/anim/scout_walk.anim.json`, `scout_idle.anim.json`: the scout, a character
  made entirely with the engine, no imported file. The model is primitives (capsules, a sphere, rounded boxes; docs/MODELING.md); `rig.create`
  fitted a humanoid skeleton to it with automatic skin weights and baked `scout.rig.glb` (docs/RIGGING.md; `scout.glb` is the plain model);
  `anim3d.generate` made the walk and the idle from the skeleton's proportions (docs/ANIMATION.md, "Generators"). Open a clip in the editor's
  Animation panel (3D bone clips) to key it by hand. `scripts/scout.js` walks a loop at the walk clip's ground speed (no foot sliding) and
  cross-fades to the idle clip while the ball is near, turned towards it.
- `tests/gem_roller.test.js`: movement, rolling, moving platforms, gems, falling, the timer, winning, restart and
  every sound (`game.audioLog()`).

## What the engine does for this game

The scripts are short because the engine covers these things (see `docs/AI_GUIDE.md` sections 9.4, 9.12, 9.17-9.19):

- **Moving platforms.** `mover.js` only sets the `velocity` of a kinematic `RigidBody3D`. A dynamic body resting on
  it is carried by the platform, so the ball's own `velocity` is relative to the ground and `ball.js` needs no
  platform bookkeeping.
- **Rolling.** The ball is a sphere `RigidBody3D` with the default `rollWithMotion`, so the engine spins its mesh to
  match its motion. A rolling sphere is slowed by `rollingFriction` (default 0.02), not by sliding friction, and
  `ball.js` sets the velocity directly every frame, so nothing slows it noticeably.
- **Ground check.** `physics.raycast3d(origin, [0, -1, 0], dist, { ignore: this.entity })` from the ball centre.
  No collider layers are needed to keep the ray from hitting the ball.
- **HUD.** Panels and texts use `anchor` and `pivot`, so they stay glued to the screen corners (and the win/lose
  overlay and messages to the centre) at any window size.
- **Gem sparkle.** `assets/vfx/gem_burst.vfx.json` is an effect document: a 3D `ParticleEmitter` burst of 40
  sparks, a short point-light flash and the pickup sound on one timeline, played with `vfx.play(path, { position })`.
  The effect removes itself when its last particle has died. It was graded with the review loop: `vfx.budget`
  (40 live particles, well inside a phone's budget) and `vfx.filmstrip` (in a 3D game it plays the effect 5 m in front of the main camera unless a `position` is given).
  The first version used additive white-cyan sparks, which vanished on the pale floor in the filmstrip; the
  saturated cyan-to-teal gradient with normal blending reads.
- **Ids.** `world.destroy()` frees an id at once, so `project.scatter_gems` with `clear` always produces
  `gem_1` ... `gem_N`.

Units are meters, +Y up. The camera looks toward -Z at yaw 0; "forward" for the ball is away from the camera.
