Part of [SCRIPTING.md](../SCRIPTING.md): `audio`, buses, `physics`, `nav`, behaviour trees, `time`, `camera`, tweens, tilemaps, video, music, particles.

# Scripting: audio world

### audio
- `play(path, { volume, pitch, pan, loop, bus, onEnded, priority, position, range })` → voice id (0 when it did not play) · `stop(id)` · `stopAll()`
- `position: [x, y, z]` (`[x, y]` in a 2D game, or `{x, y, z}`) plays the sound from a place without an entity, heard from the
  `AudioListener` like an `AudioSource` with `spatial: true`; `range` is the distance where it reaches 0 (default 800). It
  does not follow anything (docs/sound/SOUND_SPATIAL.md, "A sound at a place").
- `priority` (0..255, default 128) decides who keeps a voice when all 64 play: a new sound replaces the lowest priority voice,
  the quietest of those, when its priority is higher, or the same and it is louder; otherwise it does not play and `play`
  returns 0. Age never decides; music is never replaced (docs/sound/SOUND_MIXER.md, "Voice stealing").
- `music(path, { volume, fade, persist })` · `stopMusic(fade)` · `setVolume(bus, v)` · `getVolume(bus)` (`"master"`, `"sfx"`, `"music"`, `"ui"` or a bus of the project, see "Project buses" below; default 1; not saved: an options menu stores it)
- `activeVoices()` lists the sounds that play now, oldest first: `[{ id, path, bus, volume, pitch, pan, loop, music, source }]`
  (`volume` is the voice's own volume as last set, the volume a `setVoiceVolume` fade moves to; `music` is true for the music
  track and its layers; `source` is the entity id of the `AudioSource` or `Video` that plays it, `""` for scripts). A game that
  caps how many sounds play at once counts this list instead of keeping its own.
- `play(path, { onEnded })` calls `onEnded(voiceId)` once, in the step after the voice ended: the clip finished, a fade-out
  reached silence, `audio.stop(id)` was called, or a sound of a higher priority took its voice. It is not called when `stopAll()` or a scene load cut
  the sound, nor for a sound that did not start (id 0): the scene that asked is gone. A looping sound ends only when stopped.
  An error thrown by the callback is reported like one from a timer.
- A scene load (`scene.load`, reload) stops every sound and the music, then starts the new scene's `SceneSettings.music` (the same
  track again too). `audio.music(path, { persist: true })` is the exception: that track keeps playing through scene loads, and a
  scene whose `settings.music` is the same track does not restart it (another track replaces it). `stopAll()` stops a persisted track too.
- `setVoiceVolume(id, volume, fade?)` moves the volume of a sound that plays (an id from `play`) in a straight line over `fade`
  seconds, bus and master volumes still apply; false once the voice ended. Each change that took effect is also an entry of
  `game.audioLog()` (see the last point of this list).
- `musicLayers({ drums: path, bass: path }, { volume, fade, persist, levels })` starts stems of one piece on the same audio
  sample (all in one step, so they never start in different blocks); `setLayer(name, level, fade?)` fades a stem in or out
  (0 silent, 1 full). Stems of equal length stay aligned across loops; `stopMusic` stops every layer.
- Every play request (scripts, `AudioSource`, scene music) is recorded in a play log: tests read it with
  `game.audioLog()`, agents with the `audio.log` command. Each entry has `kind`: `"play"` (with `voice`, the id the request
  got, 0 when it did not start; music started by the engine has none) or `"setVoiceVolume"` (a `setVoiceVolume` of a voice that
  plays: `voice`, `path`, `volume` is the target, `fade` the seconds, `bus`), so a test can assert that a bed followed the
  camera. `toContainPlayed` counts plays only.
- `AudioListener.zoom` scales how far positional sounds are heard (docs.components, "AudioListener"); a script moves it
  with `listenerEntity.get("AudioListener").zoom = v` each frame (or the `scene.set_component` command).
- `bus(name)` gives a handle with `lowpass`, `reverb`, `duck`, `unduck`, `volume` and `state`; `snapshot(name, { fade })` and
  `snapshots()` move every bus to a named snapshot of factoria.json. Effects and ducking are in "Audio buses" below.
- A change of a bus volume (`setVolume`, `bus(name).volume`) ramps over about 10 ms, so it never clicks.

### Audio buses
Every voice goes into the buffer of its bus (`sfx`, `music`, `ui` or a bus of the project), each bus gets its effects and its
volume, and the buses are summed into their parent and finally into the master, which has its own. `audio.bus(name)` returns a
handle on `"sfx"`, `"music"`, `"ui"`, `"master"` or a project bus (an unknown name throws with a "did you mean" and the list);
its methods return the handle, so they chain:

```js
audio.bus("music").lowpass(800).reverb(0.2);              // muffled, in a small room
audio.bus("music").duck("sfx", 0.5);                      // music at half volume while a sound effect plays
audio.bus("music").lowpass(null, { fade: 1 });            // the filter opens again over a second
audio.bus("music").unduck();                              // or duck(null)
```

| Method | What it does |
|---|---|
| `lowpass(hz, { fade })` | 12 dB per octave low-pass at `hz` (20 to 20000; 400 to 800 sounds muffled or underwater). `0` or `null` switches it off. With `fade` the cutoff slides, measured in octaves, from where it is (a bus with no filter starts at 20000). |
| `reverb(mix, { fade })` | A small room reverb: `(1 - mix)` dry plus `mix` wet, 0 to 1. `0` switches it off. The tail rings out for about 4 seconds after the bus goes silent, then the reverb stops working. |
| `duck(byBus, amount = 0.5, attack = 0.05, release = 0.5)` | Lowers this bus by `amount` (the fraction removed: 0.5 is half as loud, 1 is silent) while `byBus` (any bus but this one and the master) is louder than -40 dBFS, measured after that bus's own effects and volume. `attack` and `release` are time constants in seconds: the bus covers 63% of the way in that time and about 95% in three times it. The master cannot duck. `duck(null)` and `unduck()` switch it off. Ducking has no `fade`: it follows `byBus` by itself. |
| `volume(v, { fade })` | The bus volume, the same as `audio.setVolume(name, v)` with an optional fade (a straight line over `fade` seconds). |
| `state()` | `{ volume, snapshotVolume, lowpass, reverb, duck }`: what the bus is moving to (a fade in progress shows its end), `lowpass` is 0 and `reverb` 0 when off, `duck` is null or `{ by, amount, attack, release }`. |

The order on a bus is low-pass, reverb, volume, then ducking; the master takes a low-pass and a reverb on the sum of the
buses, then its volume. A bad value (a cutoff below 20 Hz, a mix above 1, a bus that ducks itself) throws an error that says
what to use. Effects stay across scene loads, like volumes: a game that switches them on for one level switches them off
(or applies a snapshot) when it leaves. The test runner puts every effect back to off before each test.

**Project buses.** `sfx`, `music`, `ui` and the master always exist; a project adds its own in factoria.json, each with a
parent (default `"master"`; a parent may be declared after its child):

```json
"audio": { "buses": {
  "ambience": { "parent": "sfx" },
  "birds":    { "parent": "ambience" },
  "voiceover": {}
} }
```

`audio.play(path, { bus: "ambience" })`, `audio.setVolume("ambience", 0.5)`, `audio.bus("ambience")`, `duck("voiceover")`, the
`audio.bus` command and snapshots take the new names. A bus is mixed on its own (its voices and the buses under it, then its
low-pass, reverb, volume and ducking) and the result is summed into its parent, so `setVolume("sfx", 0.5)` also halves
`ambience`, while `setVolume("ambience", 0.5)` leaves the other sound effects alone. Names are lowercase letters, digits, `_` or
`-` (`setVolume` lowercases what it gets), may not repeat a built-in name, and a chain of parents must end at a built-in bus;
`factoria validate` reports a wrong name, an unknown parent (with a "did you mean"), a loop, and a snapshot or a `duck.by` that
names a bus nobody declared. At most 32 project buses. When the buses of a project change (a reload), a bus that stays keeps its
volume and effects, and the voices of a bus that went away play on `sfx`. Ducking between buses of different depth: the
bus that ducks reads the other bus after its own effects and volume when that bus is as deep or deeper in the tree (a child of
the ducked bus's parent, for example), and as the sum of its voices and its children before its own effects when it is nearer
the master.

A sound with baked variations (`sfx.bake` writes `step_01.wav` ... `step_06.wav` for a patch that declares `variations`, docs/SOUND.md) plays one take per call: `audio.play("assets/audio/step.wav", { variants: 6 })` picks with the world's seeded random numbers (a replay hears the same takes) and never the same take twice in a row; `audio.variantPath(path, n, count)` returns the file of take `n` (1-based). The `AudioSource.variants` field does the same for a source in a scene.

**Snapshots** name a whole mixer state so a script does not juggle buses one by one. They live in factoria.json:

```json
"audio": { "snapshots": {
  "underwater": { "fade": 0.8, "buses": {
    "sfx":   { "lowpass": 600, "reverb": 0.3 },
    "music": { "volume": 0.5, "lowpass": 400 } } },
  "dialogue": { "fade": 0.3, "buses": { "music": { "duck": { "by": "ui", "amount": 0.6 } } } },
  "normal": {}
} }
```

`audio.snapshot("underwater")` moves every bus to that state over the snapshot's `fade` (0.5 s when it gives none), or over
`audio.snapshot("underwater", { fade: 2 })`. A bus the snapshot does not list goes back to neutral (no effects, scale 1), so
`"normal": {}` is the way back and one snapshot replaces the last. `volume` in a snapshot is a scale on the bus volume the
player set with `setVolume` (the options menu keeps working under a snapshot); low-pass, reverb and the scale fade, ducking
switches at once. `audio.snapshots()` returns `{ names, current }`. An unknown name throws with a "did you mean", and
`factoria validate` reports a bad catalog (a typo in a bus or key, a value out of range) with its JSON pointer and a fix.
Agents use the commands `audio.bus` (`{ "bus": "music", "lowpass": 800, "fade": 0.5 }`; just `bus` reads the state) and
`audio.snapshot` (`{ "name": "underwater" }`; no name lists them). A snapshot may list project buses too. The mix is deterministic, so a test can render a clip with
`factoria run --headless --record-audio out.wav` after switching an effect on and measure the result.

Cost, on a mix of 44.1 or 48 kHz stereo: a bus with no effect does no effect work (its voices are only added into its parent,
one add per sample while it plays). A low-pass is one biquad per channel, five multiply-adds a sample, and works only while
the bus has sound. A reverb is eight comb and four all-pass filters per channel (several times a low-pass) and about 100 KB of
delay lines, allocated when first switched on; it keeps working for its 4 s tail and then stops. Ducking is a peak detector on
`byBus`, one gain computation and one multiply per sample, and stops by itself once the bus is back at full volume and `byBus`
is silent. Give `fade` when you switch a low-pass or reverb on or off in the middle of a sound, so it does not step.

### physics
- `raycast(from, to, { mask, ignore, ignoreTriggers })` → `{ entity, point, normal, distance } | null` (2D when `from` has no z)
- `raycast3d(origin, dir, maxDistance, { mask, ignore, ignoreTriggers })`. Colliders that contain the ray origin are
  skipped. From a behaviour pass the caster so it does not hit itself: `physics.raycast(a, b, { ignore: this.entity })`
  (`ignore` is an Entity or id; triggers are skipped unless `ignoreTriggers: false`; the commands `physics.raycast` and `physics.shape_cast` take the same three options). Ledge check pattern: cast a short
  ray down from just ahead of the feet and treat "no hit" as a ledge.
- `raycast3dAll(origin, dir, maxDistance, { mask, ignore, ignoreTriggers, maxHits })` and `raycast2dAll(from, to, opts)` →
  an array of `{ entity, point, normal, distance }` sorted by distance (nearest first), at most `maxHits` (default 32), one hit
  per entity. Same filters as `raycast3d`. Use it for everything between the camera and the player (what to fade) or to click
  through colliders that only exist to be faded: take the first hit that is not one of those. The command is
  `physics.raycast_all`.
- Switch a collider off and on with `entity.get("Collider3D").enabled = false` (or `Collider2D`): queries (raycasts, shape
  casts, overlaps) pass through it, it makes no contacts or trigger events, the NavMesh3D bake leaves it out, and the
  component and its settings stay (an open door; closing it is `enabled = true`). The physics world learns the change at its
  next sync (once a frame, before scripts run), so a cast later in the same frame still sees the old state.
- `shapeCast(shape, from, to, { mask, ignore, ignoreTriggers })` → the same `{ entity, point, normal, distance } | null`
  as `raycast`, for a shape with size (2D when `from` has no z, else 3D). `shape` is `{ shape: "circle", radius: 8 }` or
  `{ shape: "box", size: [16, 24] }` in 2D, `{ shape: "sphere", radius: 0.5 }` or `{ shape: "box", size: [1, 2, 1] }` in
  3D (full sizes in pixels / meters, like the colliders), centred on the cast position and axis-aligned. `distance` is
  how far the CENTRE can travel before the shape touches something, `point` the contact point and `normal` the hit
  surface's normal (pointing back at the shape), so `from + dir * distance` is where the shape stops. Colliders the shape
  already overlaps at `from` are skipped (like a ray starting inside one); a collider it merely touches blocks the cast
  only if the shape moves towards it. `from === to` returns `null`; use `overlapBox` / `overlapCircle` to test a spot.
  A bad shape throws an Error that says why, with a "did you mean" for a misspelt name, and notes that `"sphere"` is the 3D
  name and `"circle"` the 2D one.
  ```js
  // Can a 16 x 24 body step 10 px right? Sweep its box first.
  const hit = physics.shapeCast({ shape: "box", size: [16, 24] }, p, vec2(p.x + 10, p.y), { ignore: this.entity });
  const room = hit ? hit.distance : 10;   // move at most this far
  ```
-  `overlapCircle(center, r)` · `overlapBox(rect)` · `overlapSphere(center, r)`
- `applyImpulse(entity, v)` · `applyForce(entity, v)` · `setVelocity(entity, v)`


### nav
- `nav.findPath(from, to, { radius, snap, closest, mesh })` → `{ found, points: Vec3[], length, complete, mesh }` or
  `{ found: false, reason, message, hint, nearest?, nearestDistance? }`: a walkable path over the baked `NavMesh3D`
  (around walls, up ramps, never up a step above `stepHeight`). `points[0]` is the start; walk straight to `points[1]`,
  and so on. "No route" is a result to check, not an exception; a `radius` bigger than the mesh was baked for throws an
  Error that says how to bake for it. `nav.bake(mesh?)` bakes now and returns the stats. Guide: [NAVIGATION.md](../NAVIGATION.md).

- `nav.findTilePath(map, from, to, { costs, diagonals, maxNodes, closest, allowBlockedGoal })` → `{ found, complete, cells:
  {col, row}[], points: Vec2[], cost, length }` or `{ found: false, reason, message, hint }`: A* over a `Tilemap` entity
  (solid tiles block; `costs` per tile index) or your own `{ width, height, cost }` grid; `nav.tileVersion(tilemap)` counts
  the changes of the tiles (a number read from the array's change counter: it costs nothing). See NAVIGATION.md, section 7.
- `nav.createGrid({ width, height, cost?, origin?, cellSize? })` → a `NavGrid` kept natively (`setCost(col, row, cost)`,
  `getCost`, `setCosts`, `version`): pass it to `nav.findTilePath` instead of the array when you ask many times on one map.
  `nav.flowField(grid, goals, { diagonals })` → a `NavFlowField`: `stepToward(col, row)` is the next cell toward the nearest
  goal in O(1), `distance(col, row)` the cost, `pathFrom(col, row)` the whole way; it is rebuilt by itself after
  `grid.setCost`. See NAVIGATION.md, "Reusable grids and flow fields".

### AI: behaviour trees (`bt`)
`import { bt } from "factoria"` is a small behaviour tree in plain JS (like `tween`): you build a description once, give each
agent its own `bt.Tree` with a blackboard (the agent's state), and call `tree.tick(dt)` from `onUpdate(dt)`. Nothing runs by
itself and time only advances by the `dt` you pass, so it is deterministic and replays and tests repeat it exactly.

```js
import { Behaviour, bt, nav, world } from "factoria";
const { SUCCESS, FAILURE, RUNNING, sequence, selector, condition, action, wait, cooldown } = bt;
const brain = selector(
  sequence(condition((b) => b.seesPlayer()), cooldown(2, action((b) => { b.bite(); return SUCCESS; })), action((b, dt) => { b.chase(dt); return RUNNING; })),
  sequence(action((b, dt) => { b.wander(dt); return RUNNING; }), wait(1)),   // a node returns SUCCESS, FAILURE or RUNNING
);
export default class Rat extends Behaviour {
  onStart() { this.tree = new bt.Tree(brain, this); }   // the blackboard is the behaviour itself
  onUpdate(dt) { this.tree.tick(dt); }
}
```

- `sequence(...children)`: in order; FAILURE at the first failure, RUNNING while a child runs (the next tick resumes at that
  child WITHOUT asking the earlier conditions again), SUCCESS when all succeeded.
- `selector(...children)`: in order from the first child on every tick, the first result that is not FAILURE; so an earlier
  (more important) child interrupts a running later one.
- `parallel(...children)` / `parallel({ succeed: "any" }, ...children)`: ticks the children in order EVERY tick. The first
  FAILURE fails it (later children are not ticked that tick). Default `succeed: "all"`: SUCCESS once every child has
  succeeded (a child that succeeded is not ticked again meanwhile); `"any"`: SUCCESS at the first success. Otherwise RUNNING.
  When it finishes, the children still running are stopped: an action gets `onExit(blackboard, "aborted")` and everything
  else starts fresh next time. No children: SUCCESS for "all", FAILURE for "any".
- `repeat(child, times?)`: runs the child again each time it succeeds. RUNNING while it repeats, FAILURE as soon as the child
  fails, SUCCESS after `times` successes (a whole number >= 1); without `times` it repeats forever. One run of the child per
  tick: the next run starts on the NEXT tick, so a child that succeeds at once cannot loop forever inside one tick.
- `condition(fn)`: `fn(blackboard)` truthy = SUCCESS, falsy = FAILURE. `action(fn, { onEnter, onExit })`: `fn(blackboard, dt,
  tree)` returns `bt.SUCCESS`, `bt.FAILURE` or `bt.RUNNING` (anything else throws); `onExit(blackboard, status)` also runs with
  `"aborted"` when a tick no longer reaches a running action, or `tree.reset()` stops it.
- `wait(seconds)`: RUNNING until that much `dt` passed, then SUCCESS. `cooldown(seconds, child)`: after the child finishes,
  FAILURE for `seconds` without ticking it. `inverter(child)` swaps SUCCESS and FAILURE; `succeeder(child)` turns both into SUCCESS.
- A node that was not ticked on the previous tick starts fresh (a sequence at its first child, a wait at zero). Each `Tree`
  has its own memory per node, so one description can drive many agents. Build trees once, not every frame.
- Typical enemy: a tree decides WHAT to do (chase, flee, wander) and `nav.findTilePath` says WHERE to step; see the "enemies"
  recipe of the AI guide.

### time
`dt`, `fixedDt`, `elapsed`, `frame`, `scale`, `unscaledDt`. `time.hitStop(seconds, { scale })` freezes or slows gameplay for real seconds (UI and audio keep going; `time.hitStopRemaining`; GAME_FEEL.md). `time.scale` reads the value you set, not the hit-stop's.

`time.scale` (writable, default 1) scales gameplay: the `dt` of `onUpdate`/`onFixedUpdate`, timers (`after`, `every`),
physics steps, particles and sprite animators. `0` freezes all of them; `game.paused = true` is the same as
`time.scale = 0`, but it remembers the scale: `game.paused = false` restores the `time.scale` you had (0.5 stays 0.5;
1 if it was 0 already), and setting `time.scale` to a value above 0 while paused only changes the scale to restore.
Audio keeps playing and `time.elapsed` keeps counting fixed steps. While it is 0 the engine calls
`onUpdate`/`onLateUpdate` only on behaviours with `runWhilePaused = true` (a class field), with the real frame time as
`dt` (`time.dt` is 0 then, `time.unscaledDt` is the real one), and the UI and `world.on` listeners keep working. A pause
menu is such a behaviour:

```js
export default class PauseMenu extends Behaviour {
  runWhilePaused = true;              // keeps getting onUpdate while game.paused
  onUpdate() {
    if (input.pressed("pause")) { game.paused = !game.paused; this.world.find("pause_panel").active = game.paused; }
  }
}
```

Keep such a behaviour on an entity that stays active (an inactive entity gets no callbacks) and show or hide the panel.

### camera
`main` (the first camera drawn: the primary camera with the lowest `depth`, or null), `all` (every camera drawn, in draw
order, at most 8), `at(v)` (the camera whose viewport contains the screen point `v`, else the first), `worldToScreen(v, camera?)`,
`screenToWorld(v, depth?, camera?)` (also `screenToWorld(v, camera)`) and `screenRay(v, camera?)` (`{origin, direction}` for a 3D
pick). A camera is an Entity or its id. Without a camera, a screen point uses the camera under it (`at`), a world point the
first camera. With one camera and the default viewport nothing changes. `mouse.world` and a touch's `world` use the camera under
the pointer. Each camera draws into `Camera.viewport` (a part of the screen, 0..1, top-left origin): two or more primary cameras
make a split screen, see the recipe in AI_GUIDE section 9.29. A script that sets `viewport` live gets a value outside the
screen clamped to it, with one warning.
The `Camera` component fields are live, for example `camera.main.get("Camera").bloomIntensity = 2` changes the glow
(`bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`; see AI_GUIDE section 9.20).

### debug
`line(a, b, color?)`, `rect(x, y, w, h, color?)`, `circle(center, r, color?)`, `text(screenPos, str, color?)`.

### tween / ease / animator
`tween(target, props, options?)` moves numbers, vectors and colors of any object over time and returns a `Tween`
(`cancel()`, `pause()`, `resume()`, `seek(seconds)`, `next(...)`, `finished: Promise<boolean>`, `active`, `progress`); `tween(from, to, { onUpdate })`
tweens a plain number; `ease` holds the easing functions (`ease.quadOut`; the names also work as strings,
`ease: "backOut"`); `cancelTweens(target?)`. Options: `duration`, `delay`, `ease`, `repeat`, `yoyo`, `from`, `onStart`,
`onUpdate`, `onComplete`. Tweens run on the game's clock: they pause with `time.scale = 0` and with `game.pause` (they move only with
`game.step` then) and are deterministic in tests. `tween.pauseAll()` / `tween.resumeAll()` / `tween.timeScale` control all of them.
`finished` resolves `true` on completion and `false` on your own `cancel()`; a tween whose target entity or owning behaviour was
destroyed, or whose scene was reloaded, is dropped and `finished` never settles, so `await tween(...).finished` followed by
code that touches the entity is safe with no alive check. In a Behaviour, `this.tween(...)` (same as `tween`, owned by the
entity) and `this.wait(seconds)` (a Promise) follow the same rule. Details in [ANIMATION.md](../ANIMATION.md).
`entity.animator` controls the `Animator` component (skinned glTF clips, cross-fades, clip events, state machine).
Both are described with examples in [ANIMATION.md](../ANIMATION.md).

### entity.tilemap
`entity.tilemap` edits the `Tilemap` component one tile at a time, in place. Do not read `tiles`, change one entry and
write the whole array back for a single tile: that copies the grid on every call.
- `getTile(col, row)` returns the tile index (`-1` for an empty tile or a cell outside the map). Row 0 is the top row.
- `setTile(col, row, id)` writes one tile: `-1` empties it, otherwise a tile index (with the flip/rotate flags that
  `scene.import_ascii` writes). It returns `false`, and changes nothing, for a cell outside the map or a bad value.
- `width` and `height` are the map size in tiles.
- `cellAt([x, y])` is the cell under a world point: `{col, row}`, or `null` when the point is outside the map. `cellToWorld(col, row)` is the world position of the centre of a cell (a `Vec2`; the cell may be outside the map, its position is still computed). Both apply the entity's position, rotation and scale and follow `Tilemap.projection`, so they are the way to pick a cell of an isometric map: `map.tilemap.cellAt(input.mouse.world)`. The same maths is available from outside a script as the commands `tilemap.cell_at` and `tilemap.cell_to_world`.
2D physics sees the change on the next step and rebuilds only the colliders of the tiles that changed, so `setTile(x, y,
-1)` opens a hole a body falls through. The same edit from outside a script is the command `tilemap.set_tile`
(`{id, col, row, tile}`). Writing the whole `tiles` array still works and rebuilds the colliders.

`Tilemap.tiles` is a flat `Int32Array` of `width * height` entries (row-major, row 0 on top, `-1` = empty). Reading
`component.tiles` gives a COPY, so `comp.tiles[i] = x` writes into that copy and changes nothing. To rewrite many tiles at
once, copy, change and assign the array back; the engine compares it with the old one and only the cells that differ count
as changed:
```js
const comp = map.get("Tilemap");
const t = comp.tiles;               // Int32Array copy
for (let i = 0; i < t.length; i++) if (t[i] === DIRT) t[i] = FLOOR;
comp.tiles = t;                     // writes the whole field (a plain array of numbers works too)
```
A file, `world.spawn` or a whole-component `set(...)` may still give `tiles` as an array of rows (`[[0, 1], [1, 0]]`); it is stored
flat and the rows set `width` and `height`. The `tiles` field setter (`comp.tiles = ...`) takes flat numbers only and refuses rows
with an error: flatten them (`rows.flat()`) and set `width` and `height` yourself.

**Autotile (terrains).** A `Tilemap` with `terrains` rules (`docs.components`, `Tilemap.terrains`; the rules file
of a tileset made by `image.tileset.build`, [IMAGES.md](../IMAGES.md), "Tiles") draws the edge, corner or inside tile that fits the
cells around a cell, so you paint a terrain and the shore draws itself:
- `paintTerrain(terrain, cells)` sets the cells (`[col, row]` pairs or `{col, row}` objects) to the terrain and re-tiles them and
  the 8 cells around each one. It returns `{painted, outside, changed, changes: [{col, row, from, to}]}`. A cell that belongs
  to no terrain (a tile placed by hand) is not re-tiled. The tile among a look's variations depends on the column, row and the
  terrain's `seed` only, so the same painting looks the same every run.
- `eraseTerrain(terrain, cells)` empties the cells (`-1`) and re-tiles their neighbours (removing a lake cell turns the cells
  next to it into shore). `terrain` names the rules the neighbours are re-tiled with.
- `retile()` recomputes every terrain cell (after `setTile` calls or a change of `terrains`). `terrainAt(col, row)` is the name
  of the terrain a cell belongs to, or `null` (empty, outside the map, or a tile of no terrain).
- A `terrain` that is not in the map's rules throws an Error that lists the terrains (with a did-you-mean), and so does a rule
  that does not parse (the message starts with its JSON pointer). From outside a script: `tilemap.paint_terrain`,
  `tilemap.retile`, `tilemap.terrains` (the rules, their slots, how many cells belong to each terrain and every problem of the rules) and `tilemap.set_terrains` (from a rules
  file). They change the running world; `scene.save` keeps it.

### entity.video
`entity.video` controls the `Video` component (an `.mpg` drawn in a UI rectangle, [ASSETS.md](../ASSETS.md), "Video"). It plays
by itself when the scene starts (`autoplay`) and follows the game clock: it pauses with `time.scale = 0` and a test steps
it with `game.step`.
- `play()` plays (or restarts after the end), `pause()`, `stop()` (pause and back to the start), `seek(seconds)`.
- Read: `time`, `duration` (0 until the file is open), `playing`, `ended`. Read and write: `loop`, `volume`. A script
  that sets `entity.get("Video").path` opens another file.
- `on("ended", fn)` calls `fn({id, path})` when a video that does not loop reaches its end, once, and returns the function
  that unsubscribes. It is the game event `video.ended`, so `world.on("video.ended", ...)` hears every video. A
  handler that loads a scene should check `scene.current` first: the answer can arrive after the scene was left.
- A file that cannot be opened logs one error and the `Video` draws only its `color`; `duration` stays 0.
A studio intro that any button skips: [MENUS.md](../MENUS.md).

### entity.music
`entity.music` controls a `MusicPlayer` component: a song document played as layers, sections and stingers ([MUSIC.md](../MUSIC.md), "Playing a song in a game").
The entity throws if it has no `MusicPlayer` (`entity.get("MusicPlayer")` answers null). The component starts by itself (`playOnStart`); the calls below ask the mixer, and a
change with a `quantize` (`"none"`, `"beat"`, `"bar"`, `"section"`; default: the component's `quantize`, `layerQuantize` for the intensity) lands on that boundary's exact audio frame.
- `play(song?)` or `play({song, section, intensity})` starts at once (a hard start); `stop({quantize, fade})`; `setIntensity(0..1, {quantize})`;
  `goToSection(name, {quantize, fade})`; `playStinger({clip | section, quantize, volume, tail, bus, duck, duckAttack, duckHold, duckRelease})` (a string is the clip);
  `crossfadeTo(song, {section, quantize, bars})` (the other song starts at `section` or its beginning). `setIntensity`, `goToSection` and `crossfadeTo` return `{frame, time, quantize}`, where the change lands (null `frame` and `time` while nothing plays). A section that does not exist, a song file that does not exist, a stinger with neither `clip` nor `section`
  or a stinger with nothing playing throws an Error that says what to do; a misspelled option or event name gets a "did you mean".
- Read: `ready`, `playing`, `song`, `section`, `sections` (the names), `bar`, `beat` (1-based), `tempo`, `intensity` (= `requestedIntensity`, the last value set), `appliedIntensity` (the one the layers follow), `pendingSong`, `pendingSection`, `pendingAt` (the next queued jump or crossfade, null when none waits), `status` (everything, including `stemGains`, `pending` and `error`).
- `on(name, fn)` listens to one player and returns the function that unsubscribes: `ready`, `beat`, `bar`, `section`, `loop`, `ended`, `stinger`, `crossfade`. `fn(data)` gets
  `id`, `song`, `frame` (the audio frame it sounded on) and `time` (seconds), plus `bar`, `beat`, `section`, `index` for a beat; `bar`, `section`, `count` for a bar; `section`, `pass`, `bar` for a
  section; `count` for a loop; `stopped` for `ended`; `kind` and `section` for a stinger; `mode` for `ready`. They are the game events `music.beat`... too, so `world.on("music.bar", ...)`
  hears every player. Events reach the script one frame after they sound.
- Headless, the music is rendered at the first frame and the mixer advances with `game.step`, so a test can step to a bar line and assert the section. A handler that reacts
  to a section change by loading a scene should check `scene.current` first.
```js
const theme = world.find("theme").music;
theme.on("section", (d) => log("now in " + d.section));
theme.setIntensity(0.8, { quantize: "bar" });
```
Tools: `audio.music_state` (what every player does) and `audio.music` (the same calls).

### particles / ui
- `particles.burst(entity, count)` (same as `entity.emitBurst(count)`) spawns particles from a `ParticleEmitter`, even
  with `emitting = false`. They are born in the next simulation step (or in the picture drawn before it) and the call works
  in a run without graphics too; an entity with no emitter is ignored.
- `ui.overflowed(entityOrId)` → `true` when the text of a `Text` with a box (`maxWidth` / `maxHeight`) or the label of a
  Button, Toggle, Slider or TouchButton still does not fit at the size it is drawn at (after `ui.textScale`,
  `maxTextScale` and `autoShrink`). See [TEXT.md](../TEXT.md), "Text that fits".
- `ui.measureText(text, { fontSize, font, maxWidth, space, maxTextScale, autoShrink, minFontSize, maxHeight, markup, bold })` →
  `{ width, height, fontSize }` laid out exactly like `Text` rendering
  (shaped, wrapped, with the fallback fonts). `space` is `"screen"` (default: HUD text and widget labels, measured at the
  size the player's text size option makes it) or `"world"`. A run without graphics (`graphics=false`, `--no-graphics`)
  gives the same numbers: it shapes the text on the CPU with the same fonts. `markup` and `bold` are the `Text` fields of the same names
  ([TEXT.md](../TEXT.md), "Rich text").
- `ui.markupProblems(text)` → `string[]`: what is wrong with the `[b]`, `[i]`, `[c:name]` and `[icon:name]` tags of `text`
  (unknown tag, `[` without `]`, unclosed tag, a colour or icon the project's `text` section lacks), `[]` when clean.
  A test can walk the strings of the game and fail with the list.
- `ui.textScale` (get / set, 0.5 to 3, default 1) is the player's text size option: screen-space `Text` and the labels of
  Button, Toggle, Slider and TextField are drawn and measured at `fontSize * ui.textScale`; world-space `Text` is never
  scaled. A value outside the range throws. The engine does not save it (keep it in `storage`), and each test file starts
  at 1. The command is `ui.set_text_scale`. Fonts, languages and right-to-left text: [TEXT.md](../TEXT.md).
- `ui.scale` (get / set, 0.5 to 3) is the interface size option: every screen-space widget and `Text`/`Sprite`/`Shape2D` is
  laid out in UI units (the design screen divided by the scale) and drawn that many times as big; anchors do not move.
  It starts at the `"ui": { "scale" }` of `factoria.json` (default 1), each test file starts there again, and a value
  outside the range throws. `ui.rectOf` and `ui.state` rectangles are in screen pixels (they include it); `ui.measureText`
  and `Panel.size` are in UI units. The engine does not save it. The command is `ui.set_scale`; details, `Panel.minSize`
  and `maxSize` and the limits: [TEXT.md](../TEXT.md), "Interface size".
- `ui.on("scale", fn)` and `ui.on("textScale", fn)` call `fn({ type, value, previous })` once per change of `ui.scale`
  or `ui.textScale` to another value, with the game events of the next frame (like `i18n.on("change")`), and return the
  function that stops listening. They have no target and end with the scene.
- `ui.speak(text, { interrupt = true })` says `text` aloud with the system's text to speech, in `i18n.language` (the system
  voice for it when there is one); `interrupt: false` queues it after what is being said. `ui.stopSpeaking()` stops and
  clears the queue. `ui.speechAvailable` is false where the system has no speech (Linux without speech-dispatcher, Android
  without a speech engine): `ui.speak` is then a no-op that logs one warning per run, so hide a "read menus aloud" option.
  Output only: it never touches the simulation. Headless runs, tests and the editor speak nothing and record every line:
  `game.spoken()` in `factoria:test` returns `[{ text, language, interrupt }]` (`game.clearSpoken()` empties it, and it
  is cleared before each test). Commands: `ui.speak`, `ui.stop_speaking`. Recipe (speak the focused widget, behind an
  option) and how to hear it on each system: [MENUS.md](../MENUS.md).
- `ui.on`, `ui.focus`, `ui.focused` and `ui.hovered` belong to the widgets: see the next section.
