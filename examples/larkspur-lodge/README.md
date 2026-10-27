# Larkspur Lodge

A 3D narrative adventure (the fifth FactorIA reference game). You play the porter of a mountain lodge on a stormy night:
you walk the rooms, look at things, pick up keys and clues, and open doors. It is built with the public engine only (no
engine change); the aim is a game ready for the Mac App Store, the Microsoft Store, the iPad and the Steam Deck.

```bash
factoria validate          # scenes, scripts, locales
factoria test              # tests/*.test.js, headless
factoria call project.validate_data   # the item catalogue against the strings and the scenes
factoria run               # play it (title screen first)
```

## Package status

The game is built in packages. Each one adds to the contracts below and replaces a stub, nothing else.

| Package | What | Status |
|---|---|---|
| P1 | The lodge, the porter and the camera: rooms, night lighting, three movement schemes, interaction, doors between areas, title / game / pause, test room, these contracts | done |
| P2 | Dialogue and story: the runner in `scripts/dialogue.js`, dialogue files, choices that set flags and give items | pending (stub) |
| P3 | Items and puzzles: the puzzle chain that ends the storm, the item uses | pending (the item catalogue and inventory exist) |
| P4 | Cut-scenes and voice: the player in `scripts/cutscene.js`, subtitles | pending (stub) |
| P5 | Saves: slots, autosave, versioning, cloud | pending (the data shape exists, nothing is written to storage) |
| P6 | Sound, options, accessibility | pending (the menu kit's options exist; the game plays no sound yet) |
| P7 | Shipping: store builds, icons, listings | pending |
| P8 | Languages: es, de, ko, he | pending (only `locales/en.json`) |

## What P1 contains

- **Areas** (`scenes/`): `ground` (hall, dining room, kitchen, library, corridors), `upstairs` (four guest rooms and the
  corridor), `cellar`, and `test_room` (a small closed set for tests; no door of the lodge leads there, tests load it).
  `menu` and `loading` are the title screen and the loading screen. The area scenes are generated:
  `python3 -I assets/src/build_lodge.py` rewrites them, then run `factoria call scene.format '{"all":true}'`.
  Edit the generator, not the scenes.
- **Models** are CC0 kits recorded in `assets.json`. The characters are Kenney's Blocky Characters: the Quaternius
  characters that were planned could not be downloaded (the Google Drive file was over its quota), so P1 uses Kenney's.
  The porter is `character-*` with an Animator (idle, walk, run).
- **Lighting**: a dim ambient colour, a moon light with shadows, and lamps in the rooms. The cellar has no moon and a lower
  ambient: it is dark on purpose, and the porter has a little emission so he still reads there.
- **Collision layers** (set by the generator): 0 floors, 1 inside walls, doorways, door leaves, stairs and tall furniture
  (these fade when they hide the porter), 2 low furniture, 3 outside walls (the camera stops at them and they fade too).
- **The camera** (`scripts/lodge_camera.js`): third person, follows with smoothing, orbits, zooms, stops short of floors and
  outside walls, and fades what hides the porter.
- **The porter** (`scripts/porter.js`): CharacterController3D plus the interaction system.
- **Title, game, pause** use the menu kit: `menu` (Play, Options, Credits, Quit) loads `loading`, which preloads and loads the
  first area; Escape / P / gamepad Start pauses (resume, options, back to the title).

## Controls

| | Keyboard and mouse | Touch | Gamepad |
|---|---|---|---|
| Walk | W A S D or arrows, relative to the camera | tap the floor: the porter walks there round furniture (NavMesh3D) | left stick (half tilt walks, full tilt runs) |
| Run | hold Left Shift | - | push the stick fully |
| Use | F or Enter; click the object or the prompt | tap the object or the prompt | A |
| Orbit | Q / E, right mouse drag, left mouse drag | one finger drag | right stick |
| Zoom | mouse wheel, R / V | pinch | shoulder buttons |
| Pause | Escape or P | - | Start |

Clicking the floor walks there with the mouse too. Any move key or stick tilt cancels a walk. The prompt shows the key,
button, "Click" or "Tap" of the last device that gave input. P1 has no on-screen touch stick: touch players tap to walk.

## Contracts

These are the contracts later packages build on. Every player-visible string is a key of `locales/en.json`.

### Story flags and events

`scripts/story.js` keeps named facts in `session.story` (they survive scene loads). `get(flag, fallback)`, `has(flag)`,
`set(flag, value = true)` (sends `flag_changed` only when the value changes), `inc(counter)` and `count(counter)` for
counters, `snapshot()`, `restore(data)`, `reset()`. Flags used so far:

| Flag | Meaning | Set by | Read by |
|---|---|---|---|
| `storm_over` | the storm stopped | P3 (puzzle chain) | the `front_door` (`requiresFlag`) |
| `intro_seen` | the opening cut-scene has played | P4 | P4 |
| `open.<door id>` | the door was opened (stays open) | `interactable.js` | `interactable.js` |
| `<once>` of an item box (e.g. `test_box_taken`) | the box was emptied | `interactable.js` | `interactable.js` |

Counters: `examined.<object id>`, the times an object was examined.

`scripts/events.js` exports `EVENTS` and `emit(name, data)`. Listeners (`world.on`) die with their scene; use the story or
`session` for anything that must outlive it.

| Event | Data |
|---|---|
| `area_ready` | `{ area, spawn, scene }` |
| `area_leaving` | `{ from, to, spawn }` |
| `interacted` | `{ id, kind, name, ok }` |
| `target_changed` | `{ id, kind, verb }` (the nearest interactable in reach changed; `id` is null when there is none) |
| `door_opened` | `{ id }` |
| `door_locked` | `{ id, requires, text }` |
| `item_picked` | `{ item, from }` |
| `inventory_changed` | `{ items }` |
| `flag_changed` | `{ flag, value, previous }` |
| `dialogue_requested` | `{ id, speaker }` (sent by `dialogue.start`) |
| `cutscene_requested` | `{ id }` (sent by `cutscene.play`) |
| `device_changed` | `{ device }` (the last device that gave input changed) |

### Interaction API

An interactable is an entity tagged `interactable`, with a `Collider3D` (so a click or tap can hit it) and
`scripts/interactable.js`. Its props:

| Prop | Meaning |
|---|---|
| `kind` | `door`, `area`, `examine`, `item` or `talk` |
| `name`, `verb` | locale keys of the object name and of the verb in the prompt (default verb by kind) |
| `point`, `reach` | `[x, z]` the object is used from (default its position) and the metres the porter may stand at (1.7) |
| `text` | examine: locale key of the line shown |
| `item`, `once` | item: item id to give, and the story flag set when taken |
| `area`, `arrive` | area: target area (a key of `AREAS` in `scripts/area.js`) and the id of the spawn entity there |
| `requiresItem`, `requiresFlag`, `lockedText` | door: item id or story flag that unlocks it, and the locale key of the line when locked |
| `dialogue` | talk: dialogue id |

`interact()` returns `{ ok, kind, id, message }`. An opened door loses its collider and its prompt for the rest of the
game. `Porter` offers `lock(reason)` / `unlock(reason)` (no input while a reason is held), `faceYaw(deg)`, `walkTo(path)`,
`goTo(point)`, `use(interactable)`, and the fields `yaw`, `speed`, `grounded`, `target`, `locked`. `Area` offers
`goTo(area, spawn)` (fade out, wait for the preloaded scene, load) and the fields `area`, `leaving`, `arrivedAt`. Spawns are
entities tagged `spawn`; every area has `spawn_default`.

### Item catalogue

`data/items.json` (format `larkspur.items/1`), 8 items: `library_key`, `room_c_key`, `room_d_key`, `test_key` (kind `key`,
`opens` lists the door entity ids), `lamp_oil`, `cellar_lantern` (kind `tool`), `guest_ledger`, `torn_letter` (kind `clue`).
Each has `nameKey`, `descriptionKey` (locale keys), `color` and `opens`. `scripts/items.js` is the inventory (`session.inventory`, ids in
pick-up order): `add(id, from)` (throws for an unknown id, with a "did you mean"), `remove`, `has`, `list`, `get`, `ids`,
`snapshot`, `restore`, `reset`. `factoria call project.validate_data` checks the table against `locales/en.json` and the
scenes (every key door and item box names a real item and the other way round) and lists every problem with file,
JSON pointer and fix; `tests/data.test.js` feeds it broken tables.

### Dialogue runner (stub)

`scripts/dialogue.js`: `start(id, { speaker })` returns `{ id, started: false, completed: false, stub: true }` and sends
`dialogue_requested`; `active()` is false. P2 fills in the body (dialogue files, choices that set flags and give items) and
removes `stub`. A `talk` interactable already calls it.

### Cut-scene player (stub)

`scripts/cutscene.js`: `play(id, { skippable })` returns `{ id, played: false, skipped: false, skippable, stub: true }` and
sends `cutscene_requested`; `active()` is false. P4 fills in the body: while one plays the porter is locked
(`lock("cutscene")`) and the pause menu still works.

### Save data shape (stub)

`scripts/save_data.js` builds and applies the plain object of a saved game and writes nothing to storage in P1:

```json
{ "format": "larkspur.save/1", "area": "ground",
  "spawn": { "position": [x, y, z], "yaw": 0 },
  "story": { "flags": {}, "counters": {} },
  "inventory": ["library_key"] }
```

`snapshot()` reads the current game; `apply(data)` restores story and inventory, stores the place to stand in
`session.restoreSpawn` and returns `{ ok, area, message, hint }` (a save of another format is refused with a hint). The caller
then loads the area scene with `scene.load(path, { restore: true })`. P5 adds the slots, autosave and versioning.

## Tests

`tests/` has movement, interaction, camera, areas, flow, data, screenshot and kit tests (`factoria test`);
`tests/helpers/lodge.js` has `enter(area, spawn)`, `stand(x, z, yaw)`, `porter()` and `cam()`. The screenshot test writes
`.factoria/screenshots/hall.png` for a look at the lighting.

## Known limits and engine gaps

See `ENGINE_FEEDBACK.json`: the HUD root carries a transparent Panel because a widget under a parent without a UI component
crashes the click handling (FB-0001), the camera and the click rays re-cast to find every hit (FB-0002), and an opened door
removes its collider because `Collider3D` has no `enabled` (FB-0003).
