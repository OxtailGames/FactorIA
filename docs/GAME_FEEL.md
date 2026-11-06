# Game feel: shake, hit-stop, flash, knockback, squash and stretch

The short effects that make a hit, a landing or an explosion read on screen. Each is one call in a script, one `feel.*` command
and one JSON action (the form the events of an animation clip carry, "Effects as data"), and all three run the same C++
(`fa/scene/feel.h`). Two more actions, `spawn` (an effect prefab) and `sound`, exist as actions and commands only.

| Effect | Script | Command | What moves |
|---|---|---|---|
| Camera shake | `camera.shake(amount, opts)` | `feel.shake` | what the camera DRAWS |
| Hit-stop | `time.hitStop(seconds, opts)` | `feel.hitStop` | the game clock |
| Flash | `entity.flash(opts)` | `feel.flash` | the colour an entity is DRAWN in |
| Knockback | `entity.knockback(direction, opts)` | `feel.knockback` | a body's velocity, else the entity's position |
| Squash and stretch | `entity.squash(opts)` | `feel.squash` | the scale an entity is DRAWN at |

`feel.cancel` ends them, `feel.settings` sets the accessibility choices and `feel.state` shows what is running.

## The rule: an effect never changes the scene

Shake, flash and squash are a pose added when the frame is DRAWN. The `Transform`, the colour of the `Sprite`, the physics
bodies, the saves and every script see exactly what they set: `entity.transform.scale` is the scale you gave it after a hundred
squashes, a follow camera never chases its own shake, and a scene saved in the middle of an effect has no trace of it. The only
effect that writes to the scene is the knockback of an entity WITHOUT a physics body (it moves the position, like any movement
script would), and the knockback impulse of a body (its velocity). Loading a scene (that is not additive) drops every running
effect and every hit-stop; the player's accessibility choices stay.

Effects are deterministic: the shake noise is seeded from the world's RNG state without consuming it, so adding a shake never
changes the random numbers the game gets, and a replay shakes the same way.

## Camera shake

```js
import { camera } from "factoria";

camera.shake(0.5);                                       // a hit
camera.shake(0.2, { duration: 0.15 });                   // a footstep
camera.shake(1, { duration: 0.8, maxOffset: 0.6, maxAngle: 4 }); // an explosion
camera.shake(0.3, { camera: minimapCamera });            // another camera (default: camera.main)
```

`amount` (0 to 1) is trauma added to the camera; trauma stacks (up to `cap`, default 1) and decays to 0 over `duration` seconds,
and the shake you see is trauma SQUARED: small bumps stay small and a pile of hits shakes hard. The motion is smooth noise,
`frequency` samples per second (default 25: higher is jitterier). `maxOffset` is the largest offset at trauma 1 in world units
(default 2.5 % of the visible height of an orthographic camera, 0.3 for a perspective one); `maxAngle` is the largest turn in
degrees (default 2). A 2D camera moves in x, y and rolls; a 3D camera moves and looks a little around. The camera's `Transform`
does not change; the pointer (`input.pointer.world`, `camera.screenToWorld`) maps through the shaken view (offset and roll), so
the point under the cursor is the point of the scene that is drawn under it. A scene with no active camera has nothing to shake:
`camera.shake` and `feel.shake` do nothing there and log one warning (not an error, so a hit in a loading scene does not stop a
script); pass `camera:` to shake a camera that is not the active one.

Command: `feel.shake {"amount":0.5,"duration":0.3}`. Action: `{"action":"shake","amount":0.5}`.

## Hit-stop

```js
import { time } from "factoria";

time.hitStop(0.08);                 // freeze the game for 80 ms of real time
time.hitStop(0.2, { scale: 0.2 });  // slow motion at 20 % instead of a freeze
time.hitStopRemaining;              // seconds left (0 = none)
```

The stop is measured in REAL time and freezes (or slows to `scale`) what `time.scale` scales: physics, `onUpdate` and
`onFixedUpdate`, `after`/`every` timers, particles, sprite animators and knockback. It does NOT stop the UI, audio, behaviours
with `runWhilePaused`, the shake, the flashes and the squash: the picture stays alive while the simulation holds its breath,
which is what sells the impact. `time.scale` and `game.paused` are not changed (`time.scale` reads the user's value; the
effective one inside a stop is `scale` times it). A `game.paused` game stays paused through a stop and when the stop is over the
pause is unbroken. A stop's timer runs on the real frame time (a `game.step` in a test counts its fixed step).

Overlapping calls do not add up: the longest one wins, and while several overlap the smallest `scale` applies. Ten hits in a row
never freeze the game longer than the longest of them. A duration above 5 seconds is an error (almost always a unit mix-up).

Command: `feel.hitStop {"duration":0.08}`. Action: `{"action":"hitStop","duration":0.08,"scale":0}`.

## Flash

```js
enemy.flash();                                          // white for 0.12 s, fading
enemy.flash({ color: "#ff3030", duration: 0.2 });       // red
enemy.flash({ color: "#ffffff", duration: 0.1, fade: false }); // a square pulse: solid white then off
enemy.flash({ strength: 0.5 });                         // half-way to white
```

The entity is drawn in `color` instead of its own: `strength` 1 replaces it completely, 0.5 mixes half, and with `fade`
(default) the strength falls to 0 over `duration`. The children are flashed with it. The entity's own colour, material and
`Transform` never change.

What is flashed: sprites (including 9-slice and flipped ones), `Shape2D` shapes (the colour is mixed on the CPU before
drawing; a lit shape is mixed before the light is applied) and 3D meshes (the surface colour fades out and the flash colour is
added as emission, so it shows in the dark too; a lit mesh keeps a little of its specular and image-based reflection, so a
very glossy surface is not a perfectly flat silhouette). The same on OpenGL, Direct3D 11, Metal and the web. What is NOT
flashed: `Text`, `Tilemap`, particles and the screen-space UI.

Command: `feel.flash {"entity":"enemy","color":"#ffffff","duration":0.1}`.
Action: `{"action":"flash","color":"#ffffff","duration":0.1,"fade":true,"strength":1}`.

## Knockback

```js
player.knockback([-1, 0.3]);                             // away from the hit, a little up (default speed)
enemy.knockback(enemy.transform.position.sub(hitPoint), { speed: 6, lockTime: 0.3 });

// in the player's movement script: no control while it lasts
onFixedUpdate() {
  if (this.entity.isKnockedBack) return;
  this.move();
}
```

`direction` is any vector (`[x, y]` or `[x, y, z]`, normalised; a 2D body ignores z). `speed` is in world units per second and its
default is 6 METRES per second: 6 units for a 3D entity, and 6 times `physics.pixelsPerMeter` for a 2D one (600 pixels per second
at the default 100), so the same call pushes a 2D and a 3D entity the same visible distance. Pass `speed` yourself and it is used
as given, in the units of the entity's world. An entity with a DYNAMIC `RigidBody2D` or
`RigidBody3D` gets `speed` world units per second ADDED to its velocity at once (an impulse: the physics engine's friction and
damping slow it down). An entity without a dynamic body moves with a velocity that decays by `exp(-decay * dt)` on the fixed
clock (`decay` default 8) until it is under 0.01 units per second, and its `Transform` position is what changes, so give a
body-less enemy a `Collider` and a movement script that respects walls if it must not go through them.

`entity.isKnockedBack` is true for `lockTime` seconds (default 0.25), `entity.knockbackRemaining` says how long is left: the
loss of control. The engine does not take control away by itself; your movement script checks the flag. Knockback runs on
the simulation clock, so a hit-stop freezes it too.

Command: `feel.knockback {"entity":"player","direction":[-1,0.3]}` (`speed` is optional).
Action: `{"action":"knockback","direction":[-1,0.3],"speed":6,"lockTime":0.25,"decay":8}`.

## Squash and stretch

```js
player.squash({ amount: 0.35, duration: 0.25 });                // a landing: flatter and wider
player.squash({ amount: -0.3, duration: 0.2 });                 // a jump: taller and thinner
player.squash({ amount: 0.3, axis: "x" });                      // squash along x instead (a wall hit)
```

`amount` above 0 shortens the `axis` (default `"y"`) and widens the other; below 0 stretches. The volume is kept (x times y
in 2D, x times y times z for an entity with a mesh), the pulse eases out and back to exactly the entity's own scale after
`duration` seconds. It is drawn on top of the scale you set: `entity.transform.scale` is never written, so nothing can be left
behind by a squash that was interrupted by a scene load, a death or another squash (a new one replaces the running one).
`amount` goes from -1.5 to 1.5.

Command: `feel.squash {"entity":"player","amount":0.35,"duration":0.25}`.
Action: `{"action":"squash","amount":0.35,"duration":0.25,"axis":"y"}`.

## Clocks

| Effect | Runs on | While `time.scale = 0` / paused | During a hit-stop |
|---|---|---|---|
| Shake, flash, squash | real frame time times `time.scale` | stops | keeps going |
| Knockback | the fixed clock times the effective scale | stops | stops |
| Hit-stop timer | real time | keeps counting | counts |

A paused game does not shake or flash; a frozen-by-hit-stop one does.

## Accessibility

Two settings, both read from the player's choice when the game set one and from the operating system's "reduce motion"
(`game.accessibility.reduceMotion`) otherwise:

| Setting | Script | What it changes (when an action STARTS) |
|---|---|---|
| `reduceMotion` | `feel.reduceMotion = true` | shake amount x0.25, squash amount x0.25, hit-stop duration x0.5 |
| `reducedEffects` | `feel.reducedEffects = true` | flash strength at most 0.35 and always fading: never a full-bright pulse or a square wave |

`feel.reduceMotion = null` (and `reducedEffects`) goes back to following the system. A choice belongs to one run of the game: a new
engine starts following the system, and so does the editor when a Play session stops (a test of the game started its own
choice, the editor's own scene never keeps it). Knockback has no reduced form: it is
gameplay, not decoration. Effects already running are not changed when a setting changes. The menu kit's `settings.js`
(`applyFeel`, called by `apply()` and by every options row of the template when it changes) sets both from its "reduced effects"
option, so a game made from the kit already honours the player's choice. The option starts as `null` ("follow the system") and a
row the player never touched stays `null` when the settings are saved, so it keeps following the OS setting; a game of your own does the same once at start:

```js
import { feel, game } from "factoria";
const saved = loadSettings();
feel.reduceMotion = saved.reducedEffects ?? game.accessibility.reduceMotion;
feel.reducedEffects = saved.reducedEffects ?? game.accessibility.reduceMotion;
```

The settings outlive scene loads and reset before every test (`feel.settings {"reduceMotion":true}` sets them from a tool).

## Effects as data

Everything above is also a JSON action `{ "action": "shake" | "hitStop" | "flash" | "knockback" | "push" | "squash" | "spawn" |
"sound", ...options }` with the same option names (`push` is another name for `knockback`). This is the form scripts, tools
and animation clip events run:

```js
import { feel } from "factoria";
feel.do({ action: "flash", color: "#ffffff", duration: 0.1 }, enemy);   // target = the entity (or the camera for shake)
feel.do({ action: "hitStop", duration: 0.06 });
feel.do({ action: "spawn", prefab: "prefabs/dust.prefab.json", lifetime: 0.6 }, hero);
feel.cancel(enemy);   // ends this entity's effects; feel.cancel() ends everything, hit-stops included
```

Unknown keys, wrong types and out-of-range values are errors that name the field and say what to pass.

Two actions make something outside the entity, both from the same JSON form (and the commands `feel.spawn`, `feel.sound`):

- `spawn {prefab, offset?, local?, lifetime?}` puts the prefab (a project-relative path) at the entity's world position plus
  `offset`. With `local: true` the offset is in the entity's own space, so a mirrored sprite flips its x and the dust appears
  behind a character that faces left. The spawned entity is created the next time the engine updates the effects (never in the
  middle of an iteration over the scene) and is marked as script-spawned. `lifetime` is a number of seconds of game time
  after which it is destroyed (a hit-stop, `time.scale` 0 or a paused game holds the count); with `0`, the default, the prefab has to end itself (a particle burst that
  stops, an animation that destroys its entity), or the effects pile up (`project.validate` warns about a clip event whose
  `spawn` has no `lifetime` and whose prefab has no Script or `autoDestroy` particles). A missing prefab is logged once and
  nothing appears; a prefab that loads only in part (a child with a component that does not exist) is removed whole, so no
  half effect stays in the scene. At most 64 spawns wait for one frame: past that `feel.spawn` and `feel.do` return an error
  (a clip event logs it once per scene) and the effect is not queued (a clip event that fires on every step, or a script that
  calls `feel.spawn` in a loop, makes this).
- `sound {path, volume?, pitch?, pan?, bus?}` plays a sound once: `volume` 0 to 4 (default 1), `pitch` 0.1 to 4 (default 1),
  `pan` -1 to 1 (default 0) and `bus` (`sfx` by default). The sound waits in a queue that the audio system drains every frame,
  so a headless run without audio only holds it (`feel.state` lists the `queued` sounds and spawns; when more than 64 sounds
  wait and nobody plays them, the oldest are dropped, with one warning per scene). A sound whose file cannot be played is
  logged once; the audio system does not try that path again until the scene changes. The audio play log (`audio.log`) shows the
  entity whose action asked for the sound as its `source`.
- `knockback` and `push` take `local: true` too: the direction is in the entity's own space, so `[1, 0]` is "forward" for a
  sprite that faces left.

### Clip events that do it

An event of a clip can carry `feel`: one action or an array of them, in the same form. The actions run for the entity that plays
the clip, in the step the event fires, deterministically (once per loop pass, and a long step does not skip any event).
An event needs a `name`, `feel`, or both: a nameless event only runs its actions.

```json
{ "t": 0.3, "feel": [ { "action": "hitStop", "duration": 0.06 }, { "action": "shake", "amount": 0.3 },
                      { "action": "sound", "path": "audio/hit.wav" } ] }
```

This works in the three places that have events:

- the 2D clip files (`anim.schema.json`) and the 3D bone clip files (`anim3d.schema.json`): `events: [{t, name?, data?, feel?}]`;
- the `events` list of an `Animator` component: `[{clip, time, name?, feel?}]`;
- the `events` list of a `SpriteAnimator`, one per frame of the sheet: `[{frame, clip?, name?, data?, feel?}]`. `frame` is the
  absolute frame of the sheet's grid (row by row, as `firstFrame` and `lastFrame` count), `clip` limits the event to one clip of the
  sheet. Each pass of the animation fires a frame once (a loop fires it again at every pass), a step that skips frames fires
  the ones it skipped, in order, and a seek back fires nothing.

`anim.add_event` and `anim.set_event` take `feel` (a `null` or `[]` removes it), the same for `anim3d.add_event` and
`anim3d.set_event`. The editor's Animation panels (2D and 3D) have a `feel` box in the event inspector (JSON) and, for 2D, a
preset button for each action. Loading a clip checks every action: a typo in an action name, an unknown key, a value out of
range and an event with neither `name` nor `feel` are errors with their JSON pointer (`/events/2/feel/0/action`) and a "did you
mean". `project.validate` also checks that the prefab or the sound file of a `spawn` or `sound` action exists. An action that fails while the game runs (for example a prefab
deleted since) is logged once per scene and the rest of the event still runs: an event never stops an animation. The same goes
for an inline event (`Animator.events`, `SpriteAnimator.events`) written with the wrong JSON type, for example `"action": 5` or
`"name": 5`: the frame loop never throws, the event is skipped, and one warning per scene names the component, the JSON pointer
(`events/1/name`) and the fix; `project.validate` reports the same mistakes as errors with a "did you mean" for a misspelt key.

A `shake` in a clip event shakes the entity that plays the clip when it is a camera, else the main camera.

```bash
factoria call --project . feel.shake '{"amount":0.5}'
factoria call --project . feel.state '{}'      # hit-stop, and per entity its shake, flash, squash, knockback and pose
```

## Worked example: a sword hit

```js
import { Behaviour, camera, time } from "factoria";

export default class Sword extends Behaviour {
  hit(enemy, from) {
    enemy.flash({ color: "#ffffff", duration: 0.1 });
    enemy.squash({ amount: 0.25, duration: 0.2 });
    enemy.knockback(enemy.transform.position.sub(from), { speed: 7, lockTime: 0.3 });
    camera.shake(0.35, { duration: 0.25 });
    time.hitStop(0.07);
  }
}
```

A test can check it without a window: call `hit`, then `game.step(1)` and read `feel.state` (or `entity.isKnockedBack`).

## Drawing the effect that goes with it

The spark, the ring and the sparkle that appear on a hit or a pickup are a sprite sheet baked from code
(`assets.animate_svg` with `ramp` and `layers`) and played by a `spawn` action; making one, looking at it at the game's size
and refining it is the loop of [EFFECTS.md](EFFECTS.md), with three worked examples (an impact, a pickup, a fire loop).
An effect made of particles, lights, sounds and these feel commands on one timeline is an effect document (`*.vfx.json`,
[PARTICLES.md](PARTICLES.md)): its `command` parts call `feel.shake`, `feel.hitStop` and the others.
Sky Hopper (`examples/sky-hopper`) uses it for its coins, and the shake, hit-stop, flash and squash of its stomp, hurt and jump.

## Limits

- Shake and squash are visual, and gameplay never sees them: `entity.transform`, `entity.bounds()`, physics, the UI hit-test of
  an `Interactable`, `light2d` and the animation commands all use the true position, so a hit box, a button or a shadow does
  not wobble with a squash. Only drawing uses the posed matrix. The one thing that does move with the picture is the pointer:
  the camera's shake (offset and roll) is part of the view the pointer is mapped through, so a click lands on what is drawn
  under the cursor; the camera's own true rotation is not part of the script-side mapping when no renderer is running.
- The camera's shake moves everything the camera draws (sprites, tilemaps, text and particles in the world) but not the
  screen-space UI, which stays put on purpose; shake a panel with a `tween` when you want it to move.
- A rotated orthographic camera decides what to draw with the rectangle that encloses its view, so a shake never shows a
  missing edge; it can draw a little more than it shows.
- `Text`, `Tilemap`, particles and the screen-space UI are not flashed (see "Flash").
