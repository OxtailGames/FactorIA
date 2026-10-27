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
| P2 | Dialogue and story: the runner in `scripts/dialogue.js`, dialogue files and their validator, the dialogue box, six characters, five chapters, three endings, the story bot | done |
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
| `chapter`, `interviews`, `trust`, `ending`, the clue flags | the story (P2) | the dialogue data, `scripts/chapters.js` | dialogue conditions, `scripts/cast.js`, P3; every flag has a `doc` in `data/story.json` |
| `open.<door id>` | the door was opened (stays open) | `interactable.js` | `interactable.js` |
| `<once>` of an item box (e.g. `test_box_taken`) | the box was emptied | `interactable.js` | `interactable.js` |
| `talked.<character>.<chapter>` | a conversation was held once in that chapter | the dialogue data | the dialogue data (the short "again" line) |

Counters: `examined.<object id>`, the times an object was examined. `interviews` and `trust` (P2) are number flags changed by the `add` effect, not counters.

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
| `dialogue_requested` | `{ id, speaker }` (sent by every `dialogue.start`, even for an unknown id) |
| `dialogue_started` | `{ id, speaker }` |
| `dialogue_line` | `{ id, node, speaker, textKey, voice, choices: [{ id, textKey }] }` (a line is on offer) |
| `dialogue_ended` | `{ id, speaker, completed, picked }` (`completed` is false when it was aborted) |
| `chapter_changed` | `{ chapter, previous }` |
| `story_ended` | `{ ending }` (the ending screen is up) |
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

### Dialogue (P2)

`scripts/dialogue.js` plays a conversation of `data/dialogue/ch1.json` .. `ch5.json` (format `larkspur.dialogue/1`):

```js
import * as dialogue from "./dialogue.js";
const r = dialogue.start("ch1_mara", { speaker: "npc_mara" }); // { id, started, completed, stub: false }
dialogue.active();   // a conversation runs
dialogue.current();  // { id, speaker, line: { node, speaker, textKey, voice, choices: [{ index, id, textKey }], last } } | null
dialogue.advance();  // a line without choices: the next line (the end of the last one ends the conversation)
dialogue.choose(0);  // the first visible choice of the line
dialogue.abort();    // end it now (an area change does this by itself)
dialogue.log();      // the backlog, [{ speaker, key }] oldest first, at most LOG_LIMIT (120) long
dialogue.history();  // the conversations held: [{ id, picked: [choice ids] }]
```

`start` returns `started: false` when a conversation already runs or the id is unknown (an unknown id also logs a warning with
a "did you mean"). While one runs the porter is locked (`dialogue`), and he stays locked for `POST_LOCK` (0.25 s) after it, because
the key that ended the last line is also "interact". A conversation of a scene that is gone is dropped, not carried over.
A `talk` interactable calls `start` with its `dialogue` prop.

**The table.** `{ "format": "larkspur.dialogue/1", "conversations": { "<id>": { "start": "<node>", "nodes": {...} } } }`. A node is
a line or a route. **A line** has `speaker` (a character id of `data/cast.json`, or `porter`), an optional `voice` (a snake_case
clip id for P4; no audio plays yet), `effects`, and `next` (a node id or `@end`) or `choices`. Its id `dlg.<conversation>.<name>`
is also the locale key of its text; a choice `{ id, text, if, effects, next }` keeps its text at `<node id>_c<n>`. Choices whose `if`
fails are not offered; when none is left, `next` is followed. **A route** is a silent branch,
`{ "route": [{ "if": [...], "to": "<node>" }, ...] }`: the first entry that holds wins, an entry without `if` always holds, and a
route where none holds is an error.

**Conditions** (`scripts/conditions.js`; a list means all of them): `flag`, `!flag`, `count>=3` (`= != > >= < <=`), `ending=dawn`,
`item:id`, `!item:id`. **Effects** have one key: `{"set": "flag", "value": true}`, `{"add": "flag", "by": 1}`, `{"give": "item"}`,
`{"take": "item"}`, `{"cutscene": "id"}` (asks `scripts/cutscene.js`, a stub until P4, which sends `cutscene_requested`),
`{"end": true}`. The effects of a line run when it is reached; a choice's own effects run when it is picked, before its `next`.

**Never edit the generated JSON.** The conversations are written in `assets/src/story/ch1.py` .. `ch5.py`; the flags, chapters,
endings, cast, places and interface strings are in `assets/src/build_story.py`. `python3 -I assets/src/build_story.py` rewrites
`data/dialogue/*.json`, `data/story.json`, `data/cast.json` and the `dlg`, `cast`, `chapter`, `ending` and `dialogue` subtrees of
`locales/en.json`. A new table file must also be imported in `scripts/dialogue_data.js` (the engine cannot list a folder: FB-0005).

**Checking it.** `factoria call project.validate_dialogue` (no arguments) lists every problem at once with file, JSON pointer, fix
and "did you mean": a `next` or `to` that leads nowhere, unreachable nodes, a line with no way out, unknown speakers, flags (not
declared in `data/story.json`), items and doors, missing locale strings, a conversation nobody starts, a place in no area. It
returns `{ ok: true, counts }` when all is sound. `tests/dialogue_data.test.js` feeds it `tests/fixtures/broken_dialogue.json`
and edited copies of the real tables.

**The box** (`scripts/dialogue_view.js`, prefab `prefabs/ui/dialogue.prefab.json`, one `dialogue` entity in each area scene). The
text appears at the player's text speed (Options, Audio: slow 20, normal 45, fast 90 characters per second, or instant; a system
that asks for reduced motion starts at instant). Enter, Space, gamepad A, a click or a tap on the box completes the line and then goes
on. Choices appear once the text is complete: click or tap one, arrows or d-pad plus Enter / A, or the keys 1 to 4 (actions
`choice_1`..`choice_4`). The backlog opens with L, gamepad Y or the Log button and closes with the same key, Close or Escape /
gamepad B (while it is open `MenuStack.busy` is set so that Escape does not also pause: FB-0008). Presses in the first 0.2 s of a
line are ignored.

### The night (P2)

The chapter is the flag `chapter` (1 to 5; 0 in a bare scene such as the test room, where nobody stands). `scripts/chapters.js`
(`begin`, `current`, `due`, `advance`, `ending`, and an entity `chapters` in each area scene) reads `data/story.json`:

| Chapter | Ends when | What happens |
|---|---|---|
| 1 The night shift | `vale_missing` | Mara welcomes the new porter; Hedda says Dr. Vale's door in room C is locked and he does not answer. |
| 2 Cold supper | `interviews>=3` | Tobias (cook), Haas (guest), Lucian (journalist) and Mara each give a clue and a way to win or lose trust. |
| 3 Room C | `open.guest_door_c` | Keys from the cellar crate, the library and Haas; the ledger, the torn letter and the survey. |
| 4 The old way | `vale_found` | The lantern from the cellar and the oil from the kitchen; Haas opens the adit behind the third wine shelf and Dr. Vale is brought out. |
| 5 Dawn | the `ending` flag | `storm_over` is set. Dr. Vale on the sofa: `dawn` (the truth; needs `survey_known`), `quiet` (bury it; needs `trust>=3`) or `long` (accuse). |

Between chapters the porter is locked, the screen fades, the chapter card and its intro line show, and the cast is placed again
(`chapter_changed`). A chapter waits for a running conversation to end. The ending screen (`prefabs/ui/ending.prefab.json`) sends
`story_ended` and offers the main menu. **Play** in the title menu calls `chapters.begin()`.

**The cast** (`data/cast.json`, `scripts/cast.js`): Mara Lindqvist (owner), Hedda (housekeeper), Tobias (cook), Haas (retired guide),
Lucian (journalist) and Dr. Vale (chapter 5 only). Each has a `body` (the project has four CC0 Kenney bodies, so characters that
share one are told apart by `tint`), a `schedule` (chapter -> a place of `story.json` `places`: area, x, z, yaw) and `talk`
(chapter -> conversation id). The entity `npc_<id>` is an interactable of kind `talk` like any object (prompt, F / Enter / A, click,
tap), blocks the porter, and turns to him while they talk.

**Hooks for P3.** Every flag in `data/story.json` has a `doc` saying who sets and who reads it. P3 builds on `know_oil`, `know_cellar`,
`know_page`, `know_argument` (clues said in chapter 2), `survey_known`, `hedda_letter`, `adit_known`, `adit_open`, `vale_found`,
`page_recovered`, `storm_over` (set when chapter 5 begins; the front door reads it) and the `*_taken` flags of the item boxes. P3's
code may `story.set` the same flags and the chapters follow. The cut-scene ids asked through the stub are `adit_descent` and
`adit_rescue` (P4).

**The story bot.** `tests/story_bot.test.js` plays the whole night three times from the title screen with `tests/helpers/bot.js`
(it stands next to a thing, presses the use key, picks answers from a list, waits for the fades) and pins an `fnv1a` hash of the
story state after each ending: dawn `961c7a0a`, quiet `8d892f44`, long `a5fc2711`. When the story changes the test prints the
state: check the change is meant, then update the hash.

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
`.factoria/screenshots/hall.png` for a look at the lighting. P2 adds `dialogue_data`, `dialogue_runner`, `dialogue_ui`,
`cast_chapters` and `story_bot` tests; the dialogue UI and ending tests write `dialogue_line.png`, `dialogue_choices.png` and
`ending_quiet.png` there. `tests/helpers/bot.js` has the `Bot` (`play`, `use`, `go`, `talk`, `state`) and `fnv1a`.

## Known limits and engine gaps

See `ENGINE_FEEDBACK.json`: the HUD root carries a transparent Panel because a widget under a parent without a UI component
crashes the click handling (FB-0001), the camera and the click rays re-cast to find every hit (FB-0002), and an opened door
removes its collider because `Collider3D` has no `enabled` (FB-0003). P2 adds: the dialogue text reveal pads the text because
`Text` cannot show part of a line (FB-0004), the data files are imported by hand (FB-0005), Escape is both cancel and pause
(FB-0008), and the options menu got a text speed row by hand (FB-0011). FB-0006, FB-0007, FB-0009 and FB-0010 are
documentation gaps met while writing the UI and its tests.
