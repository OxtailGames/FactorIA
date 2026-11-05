# Particles

The `ParticleEmitter` component makes short-lived particles: sparks, smoke, fire, dust, rain, magic trails, impact bursts. This page
explains every part of it with examples that run. Each field's own doc string is in [COMPONENTS.md](COMPONENTS.md) and
`factoria call components.describe '{"name":"ParticleEmitter"}'`; an emitter written before the fields of this page existed
loads and looks exactly the same (every new field defaults to "off").

An emitter has the look of a particle (size, colour, texture), the way particles are born (rate, burst, shape, direction, speed),
what happens to them (gravity, drag, turbulence, collision) and what they leave behind (trails, sub-emitters). The simulation is
deterministic and has hard budgets (see "Budgets" below), so a mistake cannot freeze a phone.

## Over life: gradients and curves

Every particle has a position in its life, `t` from 0 (born) to 1 (dies). A **curve** is a few `[t, value]` keys evaluated between
them; a **gradient** is a few `[t, colour]` keys. Both are JSON in the field, at most 16 keys, positions outside the keys take the
first or last value:

| Field | Meaning | Empty (`[]`) means |
|---|---|---|
| `colorGradient` | colour (and alpha) over life, keys `[t, "#rrggbbaa"]` (any colour a colour field takes) | `startColor` to `endColor` |
| `sizeCurve` | multiplies the size (`startSize` to `endSize`) | 1 |
| `speedCurve` | multiplies how far the particle moves; its velocity is not changed, so `[[0,1],[1,0]]` brakes it and it picks up again if the curve rises | 1 |
| `alphaCurve` | multiplies the alpha | 1 |
| `sizeVariance` | each particle is its size times 1 +- this fraction | no variance |

A curve is `[[0, 0.4], [0.35, 1], [1, 1.5]]` (linear between the keys), `{"keys": [[0, 0], [1, 1]], "interp": "smooth"}` (`"linear"`,
`"smooth"` or `"step"`) or one number for a constant. A curve or gradient that does not parse is an error with the field's name and
the right form when a scene loads (`factoria validate` shows it with the file and JSON pointer); at run time the emitter works
as if the field was empty and logs the error once.

## Flipbook textures

`texture` can be a sheet of frames: `flipbookColumns` x `flipbookRows` cells (read left to right, top to bottom), `flipbookFrames`
of them in use (0 = all). A particle shows frame `floor(t * frames)`, so the animation plays once over its life; with
`flipbookFps > 0` it plays at that frame rate and loops instead; `flipbookRandomStart` makes each particle start at its own frame
(with no fps, it simply keeps that frame: a sheet of different sprites, each particle one of them).

## Rotation, spin, drag, turbulence

- `startRotation` `[min, max]` degrees and `spin` `[min, max]` degrees per second; `alignToVelocity` turns the particle's +x axis
  to where it flies (streaks, arrows) on top of that. Rotation is visible on a `texture`; the soft round dot looks the same turned.
- `drag` slows particles down: the velocity is divided by `1 + drag * dt` every step (about `e^-drag` per second).
- `noiseStrength` is turbulence: an acceleration (world units per second squared) from a smooth random field. `noiseScale` is
  the size of one eddy and `noiseSpeed` how fast the field drifts. The field is the same on every platform and for the same `seed`.
- `inheritVelocity` adds that fraction of a moving emitter's velocity to every particle it emits (a torch carried by a running
  character throws sparks that keep some of its motion). Only for `worldSpace`; the velocity is measured from where the emitter was
  on the previous step.

## Emission shapes

`shape` says where a particle is born, relative to the emitter's Transform (so it turns and scales with it):

| `shape` | `shapeSize` | Born |
|---|---|---|
| `point` | | at the emitter (default) |
| `circle` | radius = x | in a disc (a ball in 3D) |
| `box` | [width, height, depth] | in a rectangle (a box in 3D; the depth is only used with `is3D`) |
| `cone` | base radius = x | on a line (a disc in 3D) across `direction`: the base of a cone that points along `direction` |
| `edge` | length = x | on a line along the emitter's x axis |
| `mesh` | | on the surface of `shapeMesh` (3D; a primitive name or a model path), scaled with the emitter |

`shapeFrom: "edge"` makes particles be born on the outline (the circle's rim, the box's sides or faces, the mesh's triangle edges)
instead of in the whole area. `shapeDirection: "outward"` makes them leave away from the centre (the surface normal for a mesh,
along the cone's rim for a cone) instead of along `direction`; `spread` still fans them out, except for a cone, where `spread` is
the angle at the rim.

## Collision

`collision` makes particles stop at something. It works for `worldSpace` emitters, not for `space: "screen"`.

- `plane`: the plane `collisionPlane` = `[nx, ny, nz, d]`, the points where `dot(n, p) = d` (`[0, 1, 0, 0]` is the floor `y = 0`).
  Particles stay on the side the normal points to. The normal does not need to be a unit vector: `[0, 2, 0, -40]` is the floor
  `y = -20`, the same plane as `[0, 1, 0, -20]`.
- `tilemap`: the solid tiles (`Tilemap.solidTiles`) of the `collisionTilemap` entity, or the first active Tilemap that has solid tiles.
  Isometric maps work. Particles do not leave the map's cells: in 3D only x and y count.

On every hit a particle keeps `collisionBounce` of its speed along the surface normal (reversed) and loses `collisionFriction` of
its speed along the surface at once, loses `collisionLifetimeLoss` of its full lifetime, or dies with `collisionKill`. A particle that
only rests or slides on the surface is not a hit (it does not lose life or fire the `collision` sub-emitter again every frame);
it loses sliding speed per second instead, about `e^(-10 * collisionFriction * t)`, so a pile of sparks slows down the same at 30
and at 120 frames per second (`collisionFriction` 1 slows a sliding particle to a tenth in half a second).

## Trails

`trail: "particle"` draws a ribbon behind every particle, following the path it flew for the last `trailTime` seconds (at most
32 points per particle, so a long `trailTime` gets coarser, not heavier; all the trails of an emitter share a pool of 16 384 points,
512 trails of 32, so a swarm of 10 000 trailed particles still draws at most 16 384 ribbon quads and the particles born while the
pool is full have no trail, logged once). `trail: "emitter"` draws one ribbon along the path the
emitter itself moved (a sword swing, a comet, a wake), only for `worldSpace`; it is drawn while the emitter is emitting and
fades out after. `trailWidth` is the width of the head in world units (design pixels in screen space); `trailWidthCurve` multiplies it along the
trail, `[0, 1]` = head to tail (empty: tapers to a point); `trailGradient` is the colour along the trail, same positions (empty: the particle's
colour, fading out toward the tail). The ribbon is drawn with the emitter's `layer`, `blend` and, in 3D, faces the camera.

## Sub-emitters

`subEmitters` makes particles emit particles:

```json
{"birth": {...}, "death": {...}, "collision": {...}}
```

Each event holds one link or an array of links `{"count": 4, "chance": 1, "inherit": 0.5, ...}` and **one** of: `"emitter": {...}`
(the fields of a ParticleEmitter, the rest default), `"prefab": "prefabs/spark.prefab.json"` (the first ParticleEmitter in that
prefab) or `"entity": "spark-source"` (the emitter of another entity, copied about ten times a second, so editing it changes the effect within a tenth of a second). `count`
particles are born at the parent's position when it is born, dies or hits something, each time with probability `chance`, and
add `inherit` times the parent's velocity. A collision sub-emitter is turned so that its `direction` 90 is the surface normal
(a spray of sparks leaves the wall, whichever wall it hit).

A sub-emitter's particles use ITS fields (lifetime, speed, direction, spread, gravity, size, colour, texture, blend, layer, curves,
trails, collision, pixel mode, its own `subEmitters`) and are simulated and drawn with the emitter that owns them. They
ignore their own `rate`, `burst` and `emitting`, and are born where the parent is, so a sub-emitter has no `shape: "mesh"`.
A sub-emitter lives in the space of the emitter that owns it: its own `worldSpace` is ignored (a warning says so). Its `collision`
works like the parent's, `tilemap` included (the map is looked up once for the whole emitter; with none the children fall
through and the engine logs it once). A `prefab` or `entity` link that cannot be had yet (the file is written later, the entity is not
in the scene yet) is tried again once per second of simulated time, so it starts working when the thing appears; the log
says what is being retried.

## Pixel mode

`pixelMode: true` draws particles as hard-edged squares on a pixel grid, with colours from a palette, for pixel-art games:

- every square covers a whole number of `pixelSize` world units (at least one) and sits on that grid: the grid is the world's, so
  with a camera that shows one world unit per art pixel, particles line up with the sprites. In 3D the colours and hard edges
  apply but there is no grid, and particles are not rotated in pixel mode.
- the colours are snapped to the nearest colour of the `palette` field (`["#rrggbb", ...]`); with `palette` empty, to the
  project's palette (`style.palette` in `assets.json`: a list of colours or a palette image); with neither, each channel is
  reduced to four levels.
- alpha is kept, so a fading particle blends and the blended pixel is no longer a palette colour. For an exact palette end a
  gradient on an opaque colour, or fade in hard steps: `"alphaCurve": {"keys": [[0, 1], [0.8, 1], [1, 0]], "interp": "step"}`.

## Determinism and `seed`

The random numbers of an emitter come from its own generator, seeded from the entity's id (never `world.rng()`), so the same scene
plays the same particles every run, windowed or headless, on every platform, and gameplay randomness is not consumed by
effects. `seed` (a number, default 0) gives another, still repeatable, run of the same emitter: two torches with the same
settings look different with different seeds. A test can compare a screenshot or the particle count (`renderStats.particles`, below).

## Budgets

Particles must never become a performance problem:

- an emitter keeps at most **10 000** live particles, sub-emitter particles included (`maxParticles` only lowers it, per emitter and
  per sub-emitter); whatever does not fit is not born. A `rate` of a million particles per second makes 10 000, not a freeze.
- a trail keeps at most **32** points per particle, and an emitter's trails share **16 384** points (512 trails), so its trails
  draw at most 16 384 ribbon quads and use about 2 MB, whatever the particle count.
- sub-emitters go **two levels** below the emitter (its children and their children; deeper ones are ignored with a warning),
  at most **32** particles per event, **8** sub-emitters per emitter and **256** sub-emitter particles per frame.
- `renderStats.particles` (`play.report`, `game.state().renderStats`) is the number of live particles drawn in the frame. Keep it
  under a few thousand for a phone. Particles go through the 2D quad batcher, which merges neighbours with the same texture, blend
  and layer into one draw; trail ribbons are drawn through it too.

## Worked examples

Each block is a `ParticleEmitter` (a scene entity's component, a prefab's component, or a `"emitter"` of a sub-emitter) and is
checked by a test. Burst effects are prefabs: `world.spawnPrefab(...)`, as in [AI_GUIDE.md](AI_GUIDE.md) section 9.12.

### A hit spark

A short burst of bright streaks that fly out, are braked by drag, fall a little and cool from white to red. `trail` draws each as
a short comet. Additive blending makes them glow, especially with the camera's bloom.

Example `hit-spark`:

```json
{
  "emitting": false, "rate": 0, "burst": 14, "autoDestroy": true,
  "lifetime": 0.3, "lifetimeVariance": 0.4,
  "speed": 280, "speedVariance": 0.5, "direction": 90, "spread": 180,
  "gravity": [0, -500, 0], "drag": 5,
  "startSize": 5, "endSize": 1,
  "colorGradient": [[0, "#ffffff"], [0.3, "#ffd24a"], [1, "#ff4a1f00"]],
  "trail": "particle", "trailTime": 0.12, "trailWidth": 3,
  "blend": "additive", "seed": 1
}
```

Put it on a prefab and spawn it where the hit happened. For sparks that leave the surface that was hit, add a `collision` sub-emitter
to the thing that hits (or give the sparks a floor with `"collision": "plane"`).

### A smoke puff

Soft grey puffs that grow, rise, drift on turbulence and fade in and out. The sizes differ per puff.

Example `smoke-puff`:

```json
{
  "emitting": false, "rate": 0, "burst": 10, "autoDestroy": true,
  "lifetime": 1.6, "lifetimeVariance": 0.3,
  "shape": "circle", "shapeSize": [8, 8, 8],
  "speed": 30, "speedVariance": 0.5, "direction": 90, "spread": 35,
  "gravity": [0, 25, 0], "drag": 1.5,
  "noiseStrength": 40, "noiseScale": 48, "noiseSpeed": 0.4,
  "startSize": 18, "endSize": 18, "sizeVariance": 0.3,
  "sizeCurve": [[0, 0.4], [0.35, 1], [1, 1.5]],
  "colorGradient": [[0, "#8a8a8a"], [1, "#2a2a2a"]],
  "alphaCurve": [[0, 0], [0.15, 0.7], [1, 0]],
  "layer": 40
}
```

With a sprite sheet of puffs set `"texture": "particles/smoke.png"`, `"flipbookColumns": 4`, `"flipbookRows": 2`,
`"flipbookRandomStart": true` (each puff one of the eight drawings) and `"startRotation": [0, 360]`, `"spin": [-40, 40]`.

### A pixel-art fire

A flame on a 2-pixel grid with a five-colour palette. Embers (a sub-emitter, 15 % of the flame's particles when they die) float up
as single pixels. Each colour is a palette colour and nothing is blended, so it matches the sprites around it.

Example `pixel-fire`:

```json
{
  "rate": 40, "lifetime": 0.9, "lifetimeVariance": 0.3,
  "shape": "edge", "shapeSize": [14, 0, 0],
  "speed": 30, "speedVariance": 0.4, "direction": 90, "spread": 18,
  "gravity": [0, 40, 0],
  "noiseStrength": 60, "noiseScale": 24,
  "startSize": 10, "endSize": 2, "sizeCurve": [[0, 1], [0.6, 0.7], [1, 0.3]],
  "pixelMode": true, "pixelSize": 2,
  "palette": ["#2b0f54", "#ab1f65", "#ff4f69", "#ffa04a", "#fff7f8"],
  "colorGradient": [[0, "#fff7f8"], [0.25, "#ffa04a"], [0.6, "#ff4f69"], [1, "#2b0f54"]],
  "subEmitters": {
    "death": {
      "count": 1, "chance": 0.15,
      "emitter": {
        "lifetime": 0.7, "speed": 12, "spread": 40, "gravity": [0, 30, 0],
        "startSize": 2, "endSize": 2, "pixelMode": true, "pixelSize": 2,
        "palette": ["#ffa04a"], "colorGradient": [[0, "#ffa04a"]]
      }
    }
  }
}
```

## Effect documents (`*.vfx.json`)

A hit is rarely one emitter: sparks, a light flash, a sound, a camera shake. An **effect document** bundles them on one timeline,
so the game plays "the hit effect" with one call and the same effect is used by every enemy, weapon and level. Like a prefab, it is
a file in the project; like a prefab it is placed in a scene or spawned from a script. The engine ships no effects: you write your
own (a model or the AI writes the JSON, `vfx.check` tells what is wrong).

Sparks that fly out at once, a flash of light for a tenth of a second and a hit sound a moment later.

Effect `hit-effect`:

```json
{
  "format": "factoria.vfx/1",
  "doc": "A hit: sparks, a flash and a thud. Played where the sword lands.",
  "parts": [
    { "type": "emitter", "name": "sparks",
      "emitter": { "burst": 14, "lifetime": 0.3, "speed": 260, "spread": 180, "gravity": [0, -500, 0],
                   "startSize": 4, "endSize": 1, "blend": "additive", "maxParticles": 40 } },
    { "type": "light", "name": "flash", "duration": 0.1, "light": { "radius": 80, "intensity": 2 } },
    { "type": "sound", "at": 0.02, "clip": "assets/sfx/hit.wav", "volume": 0.8 }
  ]
}
```

Play it from a script (`vfx.play` returns the entity that runs the effect, which removes itself when the effect has ended and its
particles are gone) or from any tool, then from a test step the game and look at `vfx.list`:

```js
vfx.play("assets/vfx/hit.vfx.json", { position: enemy.position, scale: 1.5 });   // at a place
vfx.play("assets/vfx/hit.vfx.json", { entity: enemy, position: [0, 12] });       // follows the enemy
```

```
vfx.play {"effect":"assets/vfx/hit.vfx.json","position":[120,64]}
vfx.list {}
vfx.check {"path":"assets/vfx/hit.vfx.json"}
```

To put an effect in a scene, add a `Vfx` component (`{"effect": "assets/vfx/torch.vfx.json", "loop": true}`): it starts with the
scene, follows its entity, and its parts become child entities. With `autoDestroy` false (the default for a placed effect) it stays
and plays again when a script sets `playing` to true.

### The file

Top level: `format` (always `"factoria.vfx/1"`), `doc` (what it is), `duration` (seconds, optional: by default the effect lasts
until its last part has started and ended; at most 30) and `parts` (1 to 16 of them). Every part has a `type`, a `name` (the name of the child entity an emitter or
a light becomes; defaults to the type and index), an `at` (seconds after the start, default 0) and, where it matters, a `duration`:

| `type` | Fields | What it does |
|---|---|---|
| `emitter` | `emitter` (the fields of a `ParticleEmitter`, a patch over its defaults), `duration`, `offset` | A child entity with that `ParticleEmitter`, made at `at`. Its `burst` fires once. A `rate` runs for `duration` seconds, then the emitter stops emitting and its particles finish. With no `duration` only the burst happens. |
| `light` | `light` (fields of a `Light2D`), `is3D` (a 3D `Light` instead), `duration` (required), `fade` (a curve, position 0 to 1, that multiplies the intensity; default a straight fade out), `offset` | A child light that fades out over `duration` and is then removed. |
| `sound` | `clip`, `volume`, `pitch`, `bus` | Plays the clip once on the mixer bus (`sfx` by default) at `at`. |
| `command` | `command`, `args` | Calls one command once at `at`, for example `feel.shake {"amount":0.5,"duration":0.3}` or `feel.hitStop {"duration":0.06}` from the game feel API. Only these commands are allowed, by exact name: `feel.shake`, `feel.hitStop`, `feel.flash`, `feel.knockback`, `feel.squash`, `feel.spawn`, `feel.sound`, `audio.bus`, `audio.snapshot` and `audio.music`. Any other name (`audio.bake`, `audio.create`, `feel.settings`, `feel.cancel`, ...) is an error at the pointer `/parts/N/command` with "did you mean", and the runtime checks the name again before it calls the command: an effect cannot write files or change settings. `feel.spawn` instantiates a prefab from the project: give it `"lifetime"` (seconds), or the prefab has to end itself, because the spawned entity does not belong to the effect and a prefab that never ends stays in the scene. A command that fails (it does not exist in this game, or its arguments are wrong) is logged once with the reason; the rest of the effect plays. |

Emitters and lights of an effect are children of the effect's entity, so they follow its position and rotation. `vfx.play` `scale` sets the scale of that entity: the offsets of the parts and the spawn shape of an emitter that is not in `worldSpace` grow with it, but the sizes written in the file (`startSize`, a light's `radius`) do not, so scale an effect by writing a bigger one. An effect has at most 8 emitters and 8 commands. Anything else is an
error that names the file, the JSON pointer and the fix, with "did you mean" for keys and values:
`assets/vfx/hit.vfx.json /parts/1/emitter/burts: unknown field 'burts' (did you mean 'burst'?)`. `vfx.check` and `factoria validate`
list every problem, and warn about what does nothing (a `rate` with no `duration`, emitters that may hold more than 4000 live particles together).
`factoria validate` also checks that the clip of every sound part is in the project; it does not check textures named by an emitter.

### Timeline, determinism, speed

The system runs once per fixed step with the step's length times `time.scale`. It has no clock and no random numbers of its own: the
same effects at the same steps do the same things on every run and platform (the emitters keep their own seeded generator, "Determinism and `seed`"). Consequences: at `time.scale` 0 an effect waits; a
hit-stop that stops the game clock stops the effect with it; a test that steps frames sees the parts start at the frame their time falls in
(a 60 Hz game starts a part at `at` 0.1 on the 6th step). `speed` (0.05 to 20) plays the timeline faster or slower; the particles
keep their own speed. `loop` starts the effect again from the beginning when it ends (a loop is never shorter than 0.1 s); `vfx.stop`
ends it: by default the parts that did not start never do, lights end and emitters stop emitting but let their particles finish; with `immediate` everything goes at once.

### Budgets and hot reload

At most 64 effects play at once: a play past that is dropped (`vfx.play` returns `null` as the id, and it is logged once). An effect
counts from `vfx.play` until it has ended and its emitters have been removed, so a burst of plays frees the budget a moment after
the effects end; the system keeps that count, it does not scan the effects on every play.

**When an effect's entities go.** When an effect ends (its last part ended, or the file's `duration` was reached, whichever the
file says; `vfx.stop`; or a `loop` starts again) its lights are removed and its emitters stop emitting. Each emitter's entity then
stays for the longest its particles can live and is removed by the effect system itself: `lifetime * (1 + lifetimeVariance)`,
plus `trailTime` when the emitter has a trail, plus, for its sub-emitters, the longest chain of the same (a sub-emitter that
cannot be read counts 30 s) and 0.1 s of slack. The emitters of an effect do not use their own `autoDestroy`. The wait is counted in game
seconds, not by looking at the particles, so the entities that exist are the same in a windowed game, a headless test and a
server: nothing depends on a renderer or a GPU. A looping effect does not pile up: at every restart the previous loop's lights go and its emitters
stop and drain, so a loop keeps at most the emitters of the loops whose particles are still alive. An autoDestroy effect's own
entity goes with its last emitter. A document is read once and shared by every effect that plays it. When the file changes on disk, the next play reads the new version; effects already
playing finish the version they started with. A file that has become invalid is an error for the next play (`vfx.play` fails with its pointer; a placed `Vfx` logs it once and does not play), fix it and play again. The runtime state of a `Vfx` (`playing`, `time`, the child entities) is not saved: a scene saved while an effect plays
starts it again from the beginning, and the entities `vfx.play` makes are never saved with the scene.

## Problems the engine reports

`factoria validate` and scene loading report, with the file and JSON pointer: curves, gradients and palettes that do not parse
(error), a `subEmitters` with an unknown event or key, or none (or two) of `emitter`, `prefab` and `entity` (error), a zero
`collisionPlane` normal (error), and settings that do nothing (warning): collision without `worldSpace` or on a screen-space
emitter, a flipbook without a `texture`, `shape: "mesh"` without a `shapeMesh`, a `trail` of `"emitter"` without `worldSpace`, too many
flipbook frames, sub-emitters nested too deep, a sub-emitter that sets `worldSpace`. What only shows at run time (a prefab that cannot be read, an
`"entity"` that has no emitter, a mesh that cannot be loaded) is logged once with the emitter's entity id.
