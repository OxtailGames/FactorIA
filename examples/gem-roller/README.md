# Gem Roller

A FactorIA 3D arcade game: roll a ball across floating platforms, ride two moving ones, and collect every gem
before the 90 second timer runs out. A fall costs 5 seconds and puts you back at the last checkpoint. Meshes are
built-in primitives plus one `.glb` gem; the sounds are placeholders in `assets/sfx/`.

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
- `prefabs/gem_burst.prefab.json`: the one-shot sparkle a gem spawns when it is picked up.
- `tools/scatter_gems.js`: project tool `project.scatter_gems`. Places N gems on the platforms (entities tagged
  `platform`), deterministically from a seed. The game manager calls it on start, so the layout is the same on
  every run: `factoria call project.scatter_gems '{"count":8,"seed":7,"clear":true}'`.
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
- **Gem sparkle.** `gem_burst.prefab.json` is a `ParticleEmitter` with `emitting: false`, `burst: 40` and
  `autoDestroy: true`: it bursts when spawned and removes itself when the last particle dies.
- **Ids.** `world.destroy()` frees an id at once, so `project.scatter_gems` with `clear` always produces
  `gem_1` ... `gem_N`.

Units are meters, +Y up. The camera looks toward -Z at yaw 0; "forward" for the ball is away from the camera.
