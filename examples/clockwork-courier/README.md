# Clockwork Courier

A 3D mobile-first game about a wind-up robot courier who delivers parcels before its spring runs down. It is the
second reference game of the FactorIA engine (milestone M25). P1 is the playable core (movement, camera, spring
timer, touch controls, game flow). P2 (this state) adds the world: six levels in two districts, guard dogs, physics
props, music, particles and a loading screen. Menus polish, saves UI and publishing come later and build on the
contracts below.

## Run

```bash
factoria validate
factoria run                      # windowed
factoria run --headless --frames 120 --screenshot-at 119 --json
factoria test                     # 165 headless tests (the six levels are played by a bot)
```

The title screen (`scenes/main.scene.json`) goes through Play and `scenes/loading.scene.json` to the first level of the
list (`rooftops_1`). The test yard (`scenes/test_yard.scene.json`) and the prop arena (`scenes/test_arena.scene.json`)
stay loadable for tests but are not in the player's list.

## Controls

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Move (camera-relative, analog) | WASD / arrows | left stick | on-screen stick, bottom-left |
| Walk instead of run | hold Shift | push the stick gently | push the stick gently |
| Jump (about 1.2 m, coyote time and jump buffer) | Space | A | Jump button |
| Action (pull a lever) | F | X | Act button |
| Orbit the camera | Q / E, mouse drag | right stick | one-finger drag on free screen |
| Zoom (3 to 10 m) | R / V, mouse wheel | shoulders | two-finger pinch |
| Pause | Escape / P | Start | pause button, Android Back |

The touch controls appear on the first touch and hide again when a keyboard or gamepad is used; they respect the
safe area (notches).

## The levels

Two districts, three levels each. Every level has a main route that delivers every parcel (also the optional one) and
an expert shortcut (a longer jump, a ledge, a bridge skipped). Times are what the autoplay bot needs; a new player
should take two to three times as long. Stars: 1 for delivering, 2 with one bonus goal, 3 with two or more. The
bonus goals are `fast` (within `parTime`), `springy` (at least 25 percent of the spring left) and `thorough` (every
optional parcel delivered).

| Level | Name | Spring | Par | Bot main / shortcut | What is in it |
|---|---|---|---|---|---|
| `rooftops_1` | First Roofs | 110 s | 50 s | 22 / 18 s | gaps, a key, two checkpoints, an optional parcel, chimney steam |
| `rooftops_2` | Chimney Row | 140 s | 70 s | 31 / 29 s | two parcels, a gate and lever, crates, a dog, a key |
| `rooftops_3` | Clock Square | 200 s | 100 s | 47 / 36 s | a seesaw, a rope bridge, two moving platforms, crates, two dogs |
| `market_1` | Lantern Lane | 130 s | 60 s | 26 / 25 s | night, lantern lights, canals with footbridges, a slalom |
| `market_2` | Stall Street | 170 s | 80 s | 36 / 35 s | a gate and lever, hurdles, a crate puzzle, a dog near the door |
| `market_3` | Midnight Rush | 220 s | 100 s | 45 / 34 s | three parcels, a rope bridge, a gate and lever, a moving platform, two dogs |

The rooftops are by day (sky, fog, sun); the market is at night (14 to 16 point lights from lantern prefabs, emissive
windows and signs, fog, fireflies). Both are built from static boxes and the Kenney Fantasy Town and Platformer kits
(models in `assets/`). Busiest level (market_3): 119 draw calls, 232 meshes (25 culled), about 27 000 triangles and
under 1 ms of CPU per frame headless (`factoria call perf.measure`); market_2 has the most triangles (about 30 000).
Each level keeps under the 32 lights per frame the engine draws.

![rooftops_1](screenshots/rooftops_1.png) ![rooftops_3](screenshots/rooftops_3.png)
![market_1](screenshots/market_1.png) ![market_3](screenshots/market_3.png)

The levels are scenes of prefab instances: edit them like any scene (`factoria call scene.format` with `paths`).

## The level objects

| Prefab / script | What it does | Fields (scene props) |
|---|---|---|
| `parcel` (`scripts/parcel.js`) | picked up by touching, carried visibly on the robot's back | `optional` (the bonus parcel) |
| `delivery_door` | hands the parcel in; the level ends when all required parcels are in | |
| `wind_key` | winds the spring, sparks, bell | `seconds` |
| `checkpoint` | flag; the last one touched is the respawn point for a fall or a catch | |
| `gate` + `lever` | hinge gate (`Joint3D` motor) opened and shut by a lever (the Act button) | `openAngle`, `direction`, `closeAfter`; lever `targets`, `once` |
| `seesaw` | a plank on a hinge; the end the courier stands on goes down | `along`, `maxAngle`, `rest` |
| `rope_bridge` | planks chained by hinges, built by the script between two points | `from`, `to`, `planks`, `width`, `sag` |
| `mover` | kinematic moving platform that carries the courier | `offset`, `speed`, `wait`, `phase` |
| `crate` | pushable dynamic crate; thud and scrape sounds | `mass` |
| `dog` (`scripts/dog.js`) | guard dog, see below | `route`, `loop`, `sightRange`, `sightAngle`, `hearRadius`, `alertTime`, `giveUpTime`, `leash` |

### Guard dogs

A dog patrols its route, notices the courier inside its view cone (with a clear line-of-sight ray) or very close when
the courier runs, barks for 0.7 s (`dog_alerted`), then chases at 4.6 m/s (the courier runs at 5) along a path found by
`scripts/nav.js`, and gives up after 5 s without seeing it (`dog_gave_up`) or when it strays 18 m from home. A catch
calls `courier.caught("dog")`: the courier lies down for 1.4 s, pays 5 s of spring, and gets up at the last checkpoint with
1.5 s of safety (`courier.grace`). Walking (Shift or a half-tilted stick, below 2.3 m/s) shortens the sight range to 60
percent and the dog does not hear it: sneaking past a dog is how the levels teach it.

The engine has no navmesh, so `scripts/nav.js` is a lazy grid A* over the physics world (a downward ray for the ground
height, `physics.overlapSphere` for obstacles, step height limit). It serves the dogs and tap-to-move.

### Tap to move

`scripts/tap_move.js` (one `tap_move` entity per level): tap the ground and the courier walks there around obstacles.
Off by default; it is the `tapToMove` field of `settings.load()` and the "Tap to move" switch of Options > Play. The
stick or a jump cancels the walk.

### Comfort and accessibility (P5)

Everything is an option on one of the Options tabs (Video, Audio, Play, Touch, Controls, Language; the Controls tab
is hidden on a phone). Each option is saved at once and applied at once, in the title, in the pause menu and in a level.
`settings.load()` returns the defaults plus the player's saved differences, so a key the player never touched keeps
following the system (`game.accessibility`, the platform).

| Option (`settings` key) | What it does |
|---|---|
| Quality (`quality`: low, medium, high) | Sun shadows, view distance (fog), ambient particle counts and one lantern light in three on low. A phone starts at medium. |
| Frame cap (`frameCap`: 30, 60, 0) | Where the platform lets the game set it (greyed out on a phone, which starts at 30). |
| Color filter (`colorFilter`) | `Camera.colorFilter`: greyscale, high contrast and three kinds of colour blindness. |
| Assist mode (`assist`) | Spring drains at 60 percent, dogs run at 75 percent, give up after half the time, bark 1.6 times longer, coyote time and jump buffer 0.25 s. The numbers are `accessibility.ASSIST`. |
| Reduced motion (`reducedMotion`) | Follows `game.accessibility.reducedMotion` until the player chooses; props stop bobbing and spinning, the camera follows softer, particles and the low-spring pulse stop. |
| Vibration (`haptics`) | `input.vibrate` pulses (`scripts/haptics.js`): a landing, a catch, a delivery, the spring running low. |
| Text size (`textScale`) | `ui.textScale`: 85 to 150 percent; starts from the system's text size. |
| Left-handed layout, Control size, Control opacity (`leftHanded`, `controlSize`, `controlOpacity`) | Mirror the touch controls; scale them (0.8 to 1.4) and their distance to the edge; scale their opacity (0.3 to 1). |
| Camera speed, Invert camera Y (`cameraSensitivity`, `invertY`) | Scale the orbit speed (0.4 to 2.5) and flip the tilt. |
| Tap to move (`tapToMove`) | See above. |

Captions: every sound that matters (a key, a delivery, a dog's bark, a catch, the spring running low) is played with
`caption` and `captionKey` (`captions.*` in the locales), drawn by the `Captions` entity inside the safe area, and the
Subtitles option of the Audio tab switches them. The spring-low warning is a yellow triangle with "!" and the word
"Low" next to the bar, so it reads without colour; doors, keys and gates differ by shape (a gate has a diagonal brace, a
key a T handle on a base) and a dog that noticed the courier shows a bright "!" on a dark ball over its head, as well
as barking.

On a phone: the game pauses when the app goes to the background (`scripts/comfort.js`, see ENGINE_FEEDBACK FB-0035 for
how it knows); Android Back closes the top screen everywhere (an options tab or panel, the pause menu, credits), pauses
in a level, is ignored on the loading screen and, on the title with nothing open, asks "Quit the game?" first
(`prefabs/ui/quit_confirm.prefab.json`). Every screen is laid out inside the safe area (`tests/comfort.test.js` checks
the rectangles with a notch).

### Music, sounds and effects

`scripts/music.js` (one `music` entity per scene) streams the title theme, the rooftops loop or the market loop
(`levels.MUSIC`), fades between tracks and ducks the music bus to 30 percent under the pause menu and under the
delivery, completion and failure jingles. Tests read `track`, `duck` and `duckTarget`. The user's music volume is
multiplied by the duck (`settings.js` keeps the saved value untouched). `scripts/fx.js` has the particle looks
(`dust`, `sparks`, `confetti`, `steam`, `fireflies`) as 3D `ParticleEmitter`s and honours the `reducedEffects` setting.

### Loading screen

`scenes/loading.scene.json`: the main menu and the results panel's Next level put the target in `session.nextScene`
and load it. The engine has no asynchronous scene load, so the bar cannot show real progress (ENGINE_FEEDBACK): it
counts the three frames the script really runs before the blocking `scene.load` (`progress` 1/3, 2/3, then the load).

## The yard

`scenes/test_yard.scene.json` is built from primitives (generated once, then edited as a normal scene): flat ground,
a 19 degree ramp, three steps, a 60 degree slope the courier cannot climb, a wall, a 0.9 m hurdle, a covered
passage, a wooden walkway (wood footsteps), one parcel and one delivery door. Pick the parcel, deliver it to the
door before the 60 s spring runs out. Stars: 1 for delivering, 2 with at least 25 percent of the spring left,
3 if also within the level's par time.

## Code map

| File | What |
|---|---|
| `scripts/courier.js` | `CharacterController3D` driven by `physics.moveCharacter`; every tunable is a class field (speeds, accelerations, turn speed, gravity, jump height, coyote time, jump buffer, kill height). Drives the Animator and the footstep surface (wood when the ground has the tag `wood`). |
| `scripts/follow_camera.js` | Smoothed follow camera with sphere-cast wall collision, orbit and zoom (fields: distance, pitch, sensitivity, invertX/Y, limits). `orbit(dx, dy)` and `zoom(d)` are the entry points of every input. |
| `scripts/spring.js` | Seconds of spring left; `fill(s)`, `wind(s)`, `stop()`, `fraction`; sends `spring_empty` once. |
| `scripts/level_flow.js` | Starts a level from `levels.js`, scores it, saves progress, shows the results and retry screens. |
| `scripts/pause_menu.js` | Pause (key, Start, touch button, Android Back) with Resume, Options, Restart, Quit to title. |
| `scripts/dog.js`, `nav.js`, `tap_move.js` | Guard dogs, the grid path finder, tap-to-move. |
| `scripts/gate.js`, `lever.js`, `seesaw.js`, `rope_bridge.js`, `mover.js`, `crate.js` | Physics props (joints, kinematic platforms, dynamic bodies). |
| `scripts/wind_key.js`, `checkpoint.js`, `stars.js`, `loading.js`, `music.js`, `fx.js` | Keys, checkpoints, star rules, loading screen, music director, particles. |
| `scripts/main_menu.js`, `scripts/ui/` | Title screen and the menu kit (menu stack, options, interface sounds). The title asks before quitting on Android Back. |
| `scripts/settings.js`, `accessibility.js`, `haptics.js`, `comfort.js` | Saved options and what they change in a scene; assist, reduced motion and quality numbers; vibration pulses; per-level comfort entity (suspend pause, low-spring warning, catch and delivery haptics). |
| `scripts/hud.js`, `parcel.js`, `delivery_door.js` | Spring bar, parcel counter, pickup and delivery. |
| `tests/` | movement, animator and footsteps, camera, touch, flow, contracts, `levels.test.js` (the bot plays all six levels, main route and shortcut), `mechanics.test.js` (keys, checkpoints, dogs, nav, tap-to-move, gate and lever, seesaw, bridge, platform, crates, particles, stars, music, loading). |
| `tests/helpers/routes.js` | The bot's waypoints for every level (main and shortcut). Generated with the levels; edit by hand when a level changes. |

### Contract: levels (`scripts/levels.js`)

`LEVELS` is the ordered list; each entry is
`{ id, name, nameKey, district, scene, spring, parTime, parcels, optionalParcels, music }` (`spring` and `parTime` in seconds; `music` is the district track). `TEST_LEVELS` holds the yard and the arena (found by `byId`/`byScene`, never listed). Helpers:
`byId(id)`, `byScene(path)`, `next(id)`, `first()`, `inDistrict(district)`. A level scene needs the entities
`courier`, `camera`, `spring`, `level` (script `level_flow.js`, prop `levelId`), `pause_menu` and `hud`, plus the
result and retry panels of the yard. The title's Play button goes to `levels.first()` through the loading screen. P3 and later: show the stars of a level with `progress.resultFor(id)` (`goals` says which bonus goals were met) and `stars.evaluate(level, result)` / `stars.maxStars()`; the star counter belongs on the results panel and the level select.

### Contract: progress (`scripts/progress.js`)

Saved in `storage` under the key `progress` as `{ version: 1, results: { [levelId]: { time, springLeft, stars } } }`.
`load()`, `resultFor(id)`, `record(id, result)` (keeps the better result: more stars, then less time; returns whether
it replaced the old one), `isUnlocked(id)` (first level always, then the previous one needs a result), `reset()`.
A damaged save loads as empty.

### Contract: events (`scripts/events.js`)

`EVENTS` names the strings sent with `world.emit` and `emit(name, data)` sends them. Listeners use
`world.on(EVENTS.x, fn)`; they end with the scene.

| Event | Data |
|---|---|
| `level_started` | `{ level, spring, parcels }` |
| `parcel_picked` | `{ parcel, carrying }` |
| `parcel_delivered` | `{ door, delivered, total, optional }` |
| `spring_wound` | `{ seconds, left }` |
| `spring_empty` | `{ time }` |
| `courier_caught` | `{ by }` (call `courier.caught(by)`): the courier gets up at the last checkpoint, the level goes on |
| `dog_alerted` | `{ dog, position }` |
| `dog_gave_up` | `{ dog }` |
| `checkpoint_reached` | `{ checkpoint, position }` (moves the respawn point) |
| `level_completed` | `{ level, time, springLeft, stars, goals: { fast, springy, thorough }, best }` |
| `level_failed` | `{ level, reason }` (`spring_empty`; a catch and a fall respawn at the last checkpoint) |
| `game_paused`, `game_resumed` | none |
| `daily_route_finished` | `{ date: "YYYY-MM-DD", level, time }`, sent by whoever runs the daily route (not sent by P5) |

### Contract: the autoplay bot (`tests/helpers/autoplay.js`)

`new Autoplay(game)` is a deterministic waypoint bot that plays only through input (gamepad stick axes and the jump
action), so it exercises the same path as a player. `goTo({x, z, radius, jump?}, until?)` and
`run(waypoints, until?)` return `{ reached, frames }`; `stop()` releases the controls. A waypoint also takes `walk`
(sneak), `act` (press the Act button), `wait` (frames) and `hold` (wait for a moving platform). `YARD_ROUTE` delivers the
yard's parcel; `tests/helpers/routes.js` has `ROUTES[levelId] = { main, shortcut }` for the six levels.

## Known limits

- The levels are short: the bot needs 22 to 47 s, a new player two to three times as much, so each takes about one to
  two minutes, not the two to four of the brief. They are built to grow: add slabs to the generator's route.
- The robot has no bark or animal sounds in the kits: the dog's bark is a pitched impact (ENGINE_FEEDBACK).
- Characters do not weigh on dynamic bodies and kinematic platforms do not carry a `CharacterController3D`; the
  seesaw, the bridge and the moving platforms emulate both in script (ENGINE_FEEDBACK).
- The rope bridge needs heavy damping to stop ringing; narrower planks than 2 m are unstable.
- The loading bar counts steps, not real progress.
- Quality presets only change what scripts own (shadows, fog, particles, lights): the engine has no render scale or GPU
  info API (FB-0036). The pause on suspend is a long-frame heuristic (FB-0035).
- The same level can end a few seconds apart depending on what ran before it in one test engine (physics props,
  FB-0033); the level tests allow 10 percent between the main route and the shortcut.
- Control size and camera speed sliders show the plain multiplier (1), not a percentage (FB-0037).

### From P1

- The robot has no land or fall clips; Sitting stands in for landing and Idle for falling.
- Orbiting the camera sideways inside the covered passage pulls it to 0.3 m from the courier, so it sits close to
  the robot's head.
- Mouse drag and wheel are tested through `orbit()` and `zoom()` (ENGINE_FEEDBACK FB-0005).

## Credits

- Level kits: Kenney "Fantasy Town Kit", "Platformer Kit" and "Cube Pets" (CC0), https://kenney.nl.
- Music: "Cozy Puzzle Title" and "Urban Shop" by MintoDog, "Loop City" by Fupi (CC0), https://opengameart.org.
- Jingles: Kenney "Music Jingles" (CC0).
- Sounds: Kenney "Impact Sounds" and "Interface Sounds" (CC0), https://kenney.nl.
- Robot model: "Robot Expressive" by Quaternius (CC0), modified by Don McCurdy, from the three.js
  examples. Modified here: rescaled, hands removed and the meshes skinned to the skeleton (`tools/skinify.py`).
  Provenance of every asset is in `assets.json`.
