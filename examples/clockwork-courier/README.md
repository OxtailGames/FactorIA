# Clockwork Courier

A 3D mobile-first game about a wind-up robot courier who delivers parcels before its spring runs down. It is the
second reference game of the FactorIA engine (milestone M25). This is package P1: the playable core (movement,
camera, spring timer, touch controls, game flow) on a primitive-built test yard. Districts and enemies come later and
build on the contracts below.

## Run

```bash
factoria validate
factoria run                      # windowed
factoria run --headless --frames 120 --screenshot-at 119 --json
factoria test                     # 110 headless tests
```

The title screen (`scenes/main.scene.json`) loads `scenes/test_yard.scene.json` through Play.

## Controls

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Move (camera-relative, analog) | WASD / arrows | left stick | on-screen stick, bottom-left |
| Walk instead of run | hold Shift | push the stick gently | push the stick gently |
| Jump (about 1.2 m, coyote time and jump buffer) | Space | A | Jump button |
| Action (unused in P1) | F | X | Act button |
| Orbit the camera | Q / E, mouse drag | right stick | one-finger drag on free screen |
| Zoom (3 to 10 m) | R / V, mouse wheel | shoulders | two-finger pinch |
| Pause | Escape / P | Start | pause button, Android Back |

The touch controls appear on the first touch and hide again when a keyboard or gamepad is used; they respect the
safe area (notches).

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
| `scripts/main_menu.js`, `scripts/ui/` | Title screen and the menu kit (menu stack, options, interface sounds). |
| `scripts/hud.js`, `parcel.js`, `delivery_door.js` | Spring bar, parcel counter, pickup and delivery. |
| `tests/` | movement, animator and footsteps, camera, touch, flow (pause, spring failure, bot to results) and contracts. |

### Contract: levels (`scripts/levels.js`)

`LEVELS` is the ordered list; each entry is
`{ id, name, nameKey, district, scene, spring, parTime, parcels }` (`spring` and `parTime` in seconds). Helpers:
`byId(id)`, `byScene(path)`, `next(id)`, `first()`, `inDistrict(district)`. A level scene needs the entities
`courier`, `camera`, `spring`, `level` (script `level_flow.js`, prop `levelId`), `pause_menu` and `hud`, plus the
result and retry panels of the yard. The title's Play button goes to `levels.first()`.

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
| `parcel_delivered` | `{ door, delivered, total }` |
| `spring_wound` | `{ seconds, left }` |
| `spring_empty` | `{ time }` |
| `courier_caught` | `{ by }` (call `courier.caught(by)`) |
| `checkpoint_reached` | `{ checkpoint, position }` (moves the respawn point) |
| `level_completed` | `{ level, time, springLeft, stars }` |
| `level_failed` | `{ level, reason }` (`spring_empty` or `caught`; falling out of the world respawns at the last checkpoint) |
| `game_paused`, `game_resumed` | none |

### Contract: the autoplay bot (`tests/helpers/autoplay.js`)

`new Autoplay(game)` is a deterministic waypoint bot that plays only through input (gamepad stick axes and the jump
action), so it exercises the same path as a player. `goTo({x, z, radius, jump?}, until?)` and
`run(waypoints, until?)` return `{ reached, frames }`; `stop()` releases the controls. `YARD_ROUTE` delivers the
yard's parcel; later levels add their own routes and assert the results screen.

## Known limits (P1)

- The robot has no land or fall clips; Sitting stands in for landing and Idle for falling.
- Orbiting the camera sideways inside the covered passage pulls it to 0.3 m from the courier, so it sits close to
  the robot's head.
- Mouse drag and wheel are tested through `orbit()` and `zoom()` (ENGINE_FEEDBACK FB-0005).

## Credits

- Sounds: Kenney "Impact Sounds" and "Interface Sounds" (CC0), https://kenney.nl.
- Robot model: "Robot Expressive" by Quaternius (CC0), modified by Don McCurdy, from the three.js
  examples. Modified here: rescaled, hands removed and the meshes skinned to the skeleton (`tools/skinify.py`).
  Provenance of every asset is in `assets.json`.
