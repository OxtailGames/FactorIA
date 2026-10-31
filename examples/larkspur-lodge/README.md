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
| P3 | Items, clues and puzzles: the inventory page with a 3D item view and combining, the notebook, the deduction board with undo, four puzzles (drawer lock, timetable, torn letter, cellar fuse box) whose chain ends the storm | done |
| P4 | Cut-scenes and voice: the player in `scripts/cutscene.js`, ten cut-scenes, captions, the voice pipeline | done (no voice clips yet: see Cut-scenes) |
| P5 | Saves: five slots and an autosave, the save / load screen, versioned format (v1 -> v2), cloud, chapter select, achievements and stats | done |
| P6 | Sound, options, accessibility: ambience per room, footsteps per floor, music per chapter, five options tabs, rebinding, glyphs, read aloud | done (the ambience and the score are generated, not recorded: see Sound and options) |
| P7 | Shipping: store builds, icons, listings | done (see `SHIPPING.md`: Mac App Store pkg run sandboxed, iPad built and shown on the simulator, MSIX and Linux built not run) |
| P8 | Languages: es, de, ko, he | done (see Languages; the translations need a native reader before release: `SHIPPING.md`) |

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
  first area; Escape / gamepad Start pauses (resume, options, back to the title).

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
| `storm_over` | the storm stopped | P3: the fuse box puzzle (`scripts/puzzles.js`) | the `front_door` (`requiresFlag`) |
| `power_out` | the storm cut the power (chapter 4 begins with it) | the chapter 4 `enter` | the fuse box (`puzzles.availability`) |
| `drawer_open`, `switch_card_found`, `timetable_solved`, `letter_pieced`, `fuse_fixed` | a puzzle solved (`switch_card_found` also by the drawer) | `scripts/puzzles.js` | the notebook clues, Haas (`fuse_fixed` opens the adit choice) |
| `ded.<deduction id>` | a deduction stands on the board (cleared by undo) | `scripts/notebook.js` | dialogue and the notebook |
| `intro_seen` | the opening cut-scene has played or was skipped | the end state of the `intro` cut-scene | `scripts/chapters.js` (a new game plays the intro once) |
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
| `cutscene_started` | `{ id, skippable }` |
| `cutscene_ended` | `{ id, skipped }` (the end state is in place) |
| `device_changed` | `{ device }` (the last device that gave input changed) |
| `puzzle_solved` | `{ id }` (`drawer`, `timetable`, `letter`, `fuse`) |
| `board_changed` | `{ deductions, made, undone }` (a deduction made, undone or redone) |
| `items_combined` | `{ a, b, result }` |

### Interaction API

An interactable is an entity tagged `interactable`, with a `Collider3D` (so a click or tap can hit it) and
`scripts/interactable.js`. Its props:

| Prop | Meaning |
|---|---|
| `kind` | `door`, `area`, `examine`, `item`, `talk` or `puzzle` |
| `name`, `verb` | locale keys of the object name and of the verb in the prompt (default verb by kind) |
| `point`, `reach` | `[x, z]` the object is used from (default its position) and the metres the porter may stand at (1.7) |
| `text` | examine: locale key of the line shown |
| `item`, `once` | item: item id to give, and the story flag set when taken |
| `area`, `arrive` | area: target area (a key of `AREAS` in `scripts/area.js`) and the id of the spawn entity there |
| `requiresItem`, `requiresFlag`, `lockedText` | door: item id or story flag that unlocks it, and the locale key of the line when locked |
| `dialogue` | talk: dialogue id |
| `puzzle` | puzzle: `drawer`, `timetable`, `letter` or `fuse` (opens its screen, or says why it cannot yet) |

`interact()` returns `{ ok, kind, id, message }`. An opened door loses its collider and its prompt for the rest of the
game. `Porter` offers `lock(reason)` / `unlock(reason)` (no input while a reason is held), `faceYaw(deg)`, `walkTo(path)`,
`goTo(point)`, `use(interactable)`, and the fields `yaw`, `speed`, `grounded`, `target`, `locked`. `Area` offers
`goTo(area, spawn)` (fade out, wait for the preloaded scene, load) and the fields `area`, `leaving`, `arrivedAt`. Spawns are
entities tagged `spawn`; every area has `spawn_default`.

### Item catalogue

`data/items.json` (format `larkspur.items/1`), 11 items: `library_key`, `room_c_key`, `room_d_key`, `test_key` (kind `key`,
`opens` lists the door entity ids), `lamp_oil`, `cellar_lantern`, `fuse_wire`, `fuse_cartridge`, `fuse_mended` (kind `tool`),
`guest_ledger`, `torn_letter` (kind `clue`). Each has `nameKey`, `descriptionKey` (locale keys), `color`, `opens` and `view` (the
primitive parts of its 3D view), and `readKey` when it has a text to read. `scripts/items.js` is the inventory (`session.inventory`, ids in
pick-up order): `add(id, from)` (throws for an unknown id, with a "did you mean"), `remove`, `has`, `list`, `get`, `ids`,
`snapshot`, `restore`, `reset`. `factoria call project.validate_data` checks the table against `locales/en.json` and the
scenes (every key door and item box names a real item and the other way round) and lists every problem with file,
JSON pointer and fix; `tests/data.test.js` feeds it broken tables.

### Items, clues and puzzles (P3)

**The journal** (`scripts/screens.js`, one `screens` entity per area scene, built from code with `scripts/ui/kit.js`) has three pages:
*Items* (what the porter carries, a 3D view of the selected item, **Combine**, **Piece together** for the letter), *Notebook* (every
clue known and every deduction made, in rich text; picking an entry opens it on the board) and *Board* (clues as cards; pick two to
link them; **Undo** / **Redo**). The puzzles open from their objects in the lodge (`kind: "puzzle"`), the letter also from the Items page.
While a screen is up the porter is locked (`lock("screen")`), `scripts/lodge_camera.js` ignores drags, and Escape closes the screen
instead of pausing (its `ui.on("cancel")` handler returns true, which consumes `ui_cancel`: FB-0008). A scene change with a screen open releases all of it (`onDestroy`).

| | Keyboard and mouse | Touch | Gamepad |
|---|---|---|---|
| Open items / notebook | I / N, or the two buttons top right | the two buttons top right | X / Back |
| Change page | click the tab, Tab, PageUp / PageDown | tap the tab | shoulder buttons |
| Pick, combine, link | click | tap | D-pad and A |
| Turn the item | drag inside the view, Q / E | one finger drag | right stick |
| Zoom the item | R / V, the + / - buttons | pinch, the buttons | triggers |
| Undo / redo (board) | Z / Y, the buttons | the buttons | left / right trigger |
| Back / close | Escape | Close | B |

**Combining** is data (`data/combos.json`: `{ id, a, b, result, textKey }`, either order): `items.combine(a, b)` uses both up and gives
the result, or refuses with `combo.refuse` and loses nothing. Today: `fuse_wire` + `fuse_cartridge` -> `fuse_mended`.

**The notebook** (`data/notebook.json`, `scripts/notebook.js`): a clue is known while its story flag is set (the clues are not stored);
a deduction links two known nodes (clues or earlier deductions) and sets `ded.<id>`. `link(a, b)`, `undo()`, `redo()`, `made()`,
`entries()`. Making a new deduction clears the redo list; redo refuses a deduction whose clue is no longer known.
Locale keys: `notebook.clue.<id>.title|text`, `notebook.ded.<id>.title|text`.

**The puzzles** (`data/puzzles.json`, `scripts/puzzles.js`, plain logic; the screens only draw it). The chain that ends the storm:
the cellar crate gives `library_key`, the library gives the ledger, the torn letter is pieced together (swap strips), the board
deduces the date from the whole letter and the ledger (`d_date`), the date is the code of the library desk drawer (`0403`; gives
`fuse_wire`), the kitchen corner box gives `fuse_cartridge`, the two combine into `fuse_mended`, the reception timetable is put in
order (mail, milk, goods, coach), and the cellar fuse box (needs `power_out`) takes the fuse and the four breakers thrown in that
order (they stand in a different order in the box; a wrong one trips them all back). That sets `fuse_fixed` and `storm_over`; Haas
opens the adit only after it.

**State in `session`** (plain JSON, for P5's save; `save_data.js` snapshots it as `puzzles` and `notebook`):

| Key | Shape |
|---|---|
| `session.inventory` | `["library_key", ...]` ids in pick-up order |
| `session.puzzles` | `{ drawer: { dials: [0,0,0,0], tries }, timetable: { order: ["coach", ...] }, letter: { order: [2,0,3,1] }, fuse: { fitted, thrown: [...], trips } }` (created on first use) |
| `session.board` | `{ deductions: ["d_trail"], redo: ["d_motive"] }` made in order; undone, last first |
| `session.notebook` | `{ seen: ["oil"] }` clues already announced on the HUD |

A solved puzzle is a story flag, not session state. `puzzles.restore` and `notebook.restore` drop what does not fit the data.

**Tests.** `puzzles.test.js` (every puzzle, combining, the board with undo), `screens.test.js` (the screens through their real buttons,
the keys, a gamepad-only and a touch-only run, saves), `data_puzzles.test.js` (broken tables), and `story_bot.test.js` plays the
chain. They write `.factoria/screenshots/p3_*.png`.

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
`{"take": "item"}`, `{"cutscene": "id"}` (asks `scripts/cutscene.js`, which plays it, or queues it behind the one that plays),
`{"end": true}`. The effects of a line run when it is reached; a choice's own effects run when it is picked, before its `next`.

**Never edit the generated JSON.** The conversations are written in `assets/src/story/ch1.py` .. `ch5.py`; the flags, chapters,
endings, cast, places and interface strings are in `assets/src/build_story.py`. `python3 -I assets/src/build_story.py` rewrites
`data/dialogue/*.json`, `data/story.json`, `data/cast.json` and the `dlg`, `cast`, `chapter`, `ending` and `dialogue` subtrees of
`locales/en.json`. `scripts/dialogue_data.js` reads the folder with a glob import (`../data/dialogue/*.json`), so a new table file needs no other edit.

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
gamepad B (the cancel handler returns true, which consumes `ui_cancel` so that Escape does not also pause: FB-0008). Presses in the first 0.2 s of a
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
| 5 Dawn | the `ending` flag | Dr. Vale on the sofa: `dawn` (the truth; needs `survey_known`), `quiet` (bury it; needs `trust>=3`) or `long` (accuse). |

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
`page_recovered`, `storm_over` (set by the fuse box puzzle of P3; the front door reads it) and the `*_taken` flags of the item boxes. P3's
code may `story.set` the same flags and the chapters follow. The cut-scenes `adit_descent` and
`adit_rescue` exist; P3 asks for them with `cutscene.play(id)` or a `{"cutscene": id}` effect.

**The story bot.** `tests/story_bot.test.js` plays the whole night three times from the title screen with `tests/helpers/bot.js`
(it stands next to a thing, presses the use key, picks answers from a list, waits for the fades) and pins an `fnv1a` hash of the
story state after each ending: dawn `39eadb04`, quiet `6117fdc3`, long `2c786cb1` (P3 re-pinned them: chapter 4 now plays the puzzle chain, `bot.fixTheFuse()`). When the story changes the test prints the
state: check the change is meant, then update the hash.

### Cut-scenes (P4)

`scripts/cutscene.js`: `play(id, { skippable })` returns `{ id, played, queued, skippable, reason? }` (a second one asked while one
plays waits its turn), `active()` is true from `play()` until the end state is in place (P5 refuses to save while it is), `skip()`,
`seen()` (`[{ id, skipped }]` since the game began) and `busy()`. The player runs on the engine clock, so it stops with the pause
menu and a test with `game.step()` sees the same. While one plays the porter is locked (`lock("cutscene")`) and puppeted, the
camera is directed (`lodge_camera.direct()`), `cutscene_started` / `cutscene_ended` are sent and the pause menu still works (the
timeline and the voice wait, the line that was speaking starts again when the game goes on). It needs the HUD (`cutscene_ui` in
`prefabs/ui/hud.prefab.json` drives the tick, the bars, the captions, the title card and the Skip button); without one `play()`
answers `played: false` with a reason. Its state is dropped when the scene it started in is no longer the current one or its porter
is gone.

**Skipping** (`skip_cutscene`: Space, gamepad B; the Skip button, a tap on a phone) finishes every move and camera move, stops the
voice, clears the captions and applies the end state, so a skipped and a watched cut-scene leave the game the same.

**Data.** `data/cutscenes/<id>.cutscene.json` (format `larkspur.cutscene/1`: `id`, `doc`, `duration`, `room`, `area`, `skippable`,
`actors`, `timeline` of steps `fade`, `camera`, `caption`, `card`, `move`, `face`, `anim`, and `end { fade, set }`). The files are
written by `assets/src/build_cutscenes.py`: edit that, never the JSON, then add a new file to `scripts/cutscene_data.js` and
`data/story.json` `cutscenes` by hand (the file still lists its imports one by one; `dialogue_data.js` uses the glob import of FB-0005, and this one could). `data/cutscenes/rooms.json` gives each room its reverb.
`project.validate_cutscenes` (also run by the tests) checks every file with its file, JSON pointer, a hint and a "did you mean"
(unknown room, actor, step, flag, string key, voice id, bad ranges, steps out of order, a clip that does not exist or is longer
than its step).

**When they play.** `intro`: a new game from the title (`session.introPending`, once, `intro_seen`). `chapter_2`..`chapter_5`: when
the chapter begins, before the chapter card. `adit_descent` and `adit_rescue`: asked by the dialogue data or by P3.
`ending_dawn`, `ending_quiet`, `ending_long`: just before the ending screen.

**Captions and voice.** Every caption step names a locale key and a speaker; the caption shows `Speaker: text` through `ui.caption`
and lasts as long as its voice clip, or its `seconds` when there is none. `data/cutscenes/voice_script.json` lists the 24 lines to
speak; `data/cutscenes/voice.json` maps a line id to `{ path, seconds }` once a clip exists. **No clip ships yet**: no voice provider
was available to `assets.generate_voice` (ENGINE_FEEDBACK FB-0601), so captions run on their placeholder timing; adding the clips
to `voice.json` is all it takes. Without a provider, `assets.generate_voice {silent: true}` writes a silent clip of the line's
length to test with. Voice plays on the `voiceover` bus (`factoria.json` `audio.buses`), with the reverb of the
cut-scene's room and the music ducked under it (`scripts/mix.js`).

### Save data (P5)

`scripts/save_data.js` builds and applies the plain object of a saved game; `scripts/saves.js` keeps it in the kit's slots.
The current format is **version 2**, `larkspur.save/2`:

```json
{ "format": "larkspur.save/2",
  "playTime": 3725.5,
  "place": { "area": "ground", "position": [x, y, z], "yaw": 0 },
  "state": { "story": { "flags": {}, "counters": {} },
             "inventory": ["library_key"],
             "dialogue": { "history": [], "log": [] } } }
```

Version 1 (`larkspur.save/1`, P1 and P2) kept the place as `area` + `spawn`, had `story` and `inventory` at the top and no play
time. v2 gathers the place in one object, moves every part under `state` (one entry per registered part) and adds the play
time and the dialogue history. `upgrade(raw)` migrates a v1 save (play time 0, empty history) and checks the result (area
against the lodge's areas with a "did you mean", position, story): a damaged save is refused with a message and a hint, a save
of a newer version says to update the game. Fixtures of both versions are in `tests/fixtures/` (`save_v1.json`,
`save_v2.json`); `tests/saves.test.js` loads the v1 one in the v2 game.

`snapshot()` reads the current game; `apply(data)` accepts any version, restores every part and the play time, stores the
place to stand in `session.restoreSpawn` and returns `{ ok, area, message, hint }`. `saves.launch(data)` then goes through the
loading screen (`session.loadRestore`) and loads the area with `{ restore: true }`.

**Plugging a part in (for P3: inventory extras, the notebook, the deduction board).** The state that is not the place is a
table of named parts. A package registers its own without editing `save_data.js`:

```js
import * as save_data from "./save_data.js";
// a plain JSON object kept in session.board: saved as it is, restored by assigning it, reset to a copy of the fallback
save_data.registerSession("board", { links: [] });
// anything else: snapshot() returns a JSON value, restore(data) puts it back, reset() is a new game (or a save without the part)
save_data.register("notebook", {
  snapshot: () => session.notebook,
  restore: (data) => { session.notebook = data; },
  reset: () => { session.notebook = { entries: [] }; },
});
```

Call it when the module loads (at the top level). A save that was applied before the module was imported keeps its entry in
`session.savePending`; `register()` hands it over, and `snapshot()` writes it back untouched meanwhile, so no part is lost by
a scene that does not import it. The title screen's Play, and the chapter select, call `save_data.resetAll()`.

**Slots.** The records and the screen are the menu kit's `slots` part (`scripts/slots.js`, `scripts/ui/slot_screen.js`, the `slots` and `slot_dialog` prefabs); `scripts/saves.js` is the lodge's side of it (the save layout, when saving is refused, the chapter autosave, launching a slot). Five manual slots (`slot1`..`slot5`) and the autosave (`slot_auto`) in `storage`. A slot holds
a record `{ counter, name, chapter, playTime, pic, data }`: `data` is the versioned save, `pic` a 192x108 PNG of the game
(base64, or null when nothing could be drawn), `counter` goes up on every save and decides which copy wins between a cloud
copy and a local one (the wall clock is never read). A slot that holds a bare v1 file reads as a record with no name or
picture. **Saving is refused** (`saves.cannotSave()` gives the locale key of the reason, the Save button is greyed) when no
game is running, during a cut-scene (`cutscene.active()`), during a conversation, and while the porter changes area or chapter.
Anywhere else, in any area, the pause menu's Save game works.

**Autosave.** `scripts/pause_menu.js` (one per level) autosaves once per chapter, as soon as the chapter has begun and the game
may be saved; the same record is what the chapter select starts from. Loading a slot does not autosave over anything.

**Screens.** Pause menu: Save game and Load game; title screen: Load game. Six rows (the autosave, which is never a save
target, and the slots), each with its picture, name, chapter and play time and a Delete button that asks first. A click or a
tap on a slot saves or loads; the gamepad walks the same buttons. Saving opens a dialog with a TextField for the name
(default: the chapter's title); a gamepad player gets the on-screen keyboard of the menu kit (`scripts/ui/keyboard.js`)
because the TextField is focused, and the first B closes the keyboard, the second the dialog. While the name is typed the pause
action does not open or close the menus (P is a letter), Escape cancels the dialog.

**Cloud.** With a signed-in store (`platform.has("cloudSave")`) every save is uploaded under the slot's key, a delete removes the
copy, and opening the save / load screen compares each slot with its copy: the higher `counter` wins (a cloud copy replaces
a damaged or older local one, a better local one is uploaded). A store that is down or a player who is signed out changes
nothing locally. The screen redraws after the sync only if its scene is still the current one.

**Chapter select, achievements and stats.** `scripts/progress.js` keeps in `storage "progress"` the endings reached and the save
data taken at each chapter start. After the first ending the title screen shows Chapter select: chapter 1 is a new game, a
later chapter is open once a game has begun it and starts a new run from the story the player had then. Achievements
(`ending_dawn`, `ending_quiet`, `ending_long`, `all_endings`, `all_clues`: every clue flag in one game) and stats
(`endings_seen`, `play_minutes`, `saves_made`) are declared in `factoria.json` "platform" and sent best effort to the store.
Not tested: saving during a real cut-scene (`cutscene.active()` is always false until P4 lands; the check is in `cannotSave()`).

### Sound and options (P6)

**Sound** (`scripts/sound.js`, tuned in `data/sound.json`). One `sound` entity per area scene (added by `assets/src/build_lodge.py`).
It finds the room under the porter from the floor entities `f_<room>` and gives each room a surface and a level for four looping
beds: `wind`, `fire`, `clock` and `cellar_air`. A bed is a looping voice on the project bus `ambience` (a child of `sfx`, in
`factoria.json` "audio.buses"); it starts silent the first time a room wants it and is faded with `audio.setVoiceVolume`, so
walking between rooms crossfades. After the flag `storm_over` the wind is `stormOverWind` (0.35) of what it was. Footsteps play
on `sfx` every `stride` metres walked while grounded, from three clips of the surface (carpet, wood, concrete), taking turns by a
counter (never `rng`, so the story bot is unaffected). Chapter music: `audio.music(track, {persist: true})` when the chapter
changes (`session.musicTrack` remembers what runs); chapter 0 has none, the title screen plays `music_title.wav` from
`scripts/main_menu.js`. `scripts/mix.js` (P4) still ducks `music` and `sfx` (so `ambience`) under `voiceover`; `sound.js` only
calls `mix.setup()`. Test fields of the behaviour: `room`, `surface`, `bedLevels`, `steps`, `track`, `rects`.
The footsteps are Kenney CC0 clips imported with `assets.import`; the beds and the five chapter scores plus the title
theme are made by `assets.generate_loop` (seeded, offline) and recorded as `origin: "original"`: no CC0 pack had them (FB-0701).
The call of each file is in `assets/src/sound/<name>.json`; run `factoria call assets.generate_loop @assets/src/sound/wind.json`
(they all say `overwrite: true`) and the same bytes come back. They are placeholders in quality: replace the files, keep the names.
`assets.convert_audio` would turn any of them into an Ogg if the size ever mattered.

**Options** (`scripts/settings.js`, saved in `storage "settings"`, never in a save slot). `settings.save()` emits
`EVENTS.settingsChanged`; the camera, the dialogue box, the cut-scene player and the glyph prompts listen to it, and it applies the
caption background to the `captions` entity at once. Keys: the six volumes (`volume.master, music, sfx, ambience, voiceover, ui`),
`textScale` (1, 1.25, 1.5, 2), `reducedMotion`, `colorFilter`, `subtitles`, `captionBackground` (clear, dark, solid),
`captionSpeakers`, `textSpeed`, `autoAdvance` (off, slow, normal, fast), `glyphs` (auto, keyboard, gamepad, touch),
`cameraSensitivity` (0.25 to 2), `cameraInvertX`, `cameraInvertY`, `readAloud` and `bindings` (action -> binding names).
The options panel (`prefabs/ui/options.prefab.json`, `scripts/ui/options.js`) has a column of tabs (Video, Audio, Accessibility,
Controls, Language, Back) and a scrolling page for each, so it fits at 200 % text.
- Reduced motion: no head bob (`lodge_camera.bobOffset` is 0) and a cut-scene `camera` step cuts to its shot (`seconds` 0).
- Auto-advance: `dialogue_view.autoTimer` counts down the reading time of a finished line without choices; choices always wait.
- Rebinding: `bind_<action>` rows in Controls; the new key replaces the bindings of the device pressed and is saved in
  `bindings`; `settings.apply` puts them back at start. Reset restores the defaults.
- Glyphs: `scripts/glyphs.js` gives the key or button of an action for the device in use (`input.lastDevice`, or the forced one).
  The interaction prompt and the cut-scene Skip button use it; touch says "Tap" and "Skip".
- Read aloud: `readAloud` makes `scripts/ui/read_aloud.js` call `ui.speak` as focus moves (tests: `game.spoken()`).
Tests: `tests/sound.test.js` (beds per room, footsteps per surface, music per chapter, the ducking set-up) and
`tests/options.test.js` (every option, each tab at 100 % and 200 % through `ui.overflowed`, mouse, gamepad and touch, rebinding,
read aloud). The story bot hashes did not change (dawn 764bcd5e, quiet 7b2010b5, long 8388b733).

## Languages

`factoria.json` lists en, es, de, ko and he; each has a table `locales/<tag>.json` with the same keys as `locales/en.json`
(a dialogue line is the key of its own node id, so every language has every line, choice, chapter, ending, note and caption).
The voice stays English in every language; the captions follow the language. The language option (Options > Language)
changes every open screen at once: the engine re-translates the texts it owns and the screens, the HUD and the dialogue box write
their own again on `i18n.on("change")`. Read-aloud speaks the focused widget in the current language.

- **Korean** uses a subset of Noto Sans KR as a fallback font (`assets/fonts/`, OFL, provenance in `assets.json`). The subset holds the Hangul jamo and the 2350 syllables of KS X 1001 (a save name typed on the on-screen keyboard) and the
  characters of the tables: after editing a Korean string run `python3 -I assets/src/build_fonts.py` (it uses the engine command
  `assets.subset_font`), or `factoria validate` names the missing character.
- **Hebrew** is right to left. The engine mirrors the screen-space UI (`ui.mirrorRtl`: anchors, pivots, positions, Toggle boxes, Sliders)
  and Text and Panel rows follow the language (`direction: auto`, `align: start`), so the builders of `scripts/ui/kit.js` place every
  widget as if for English, the 3D item view (a `CameraView`) included. A Hebrew
  string that starts with a key name or a placeholder is a right-to-left paragraph through `Text.direction` (the hint labels, the
  prompt) or a `key` (the Skip button); the translations have no U+200F (FB-0903, FB-0904).
- **German** is the longest language: labels shrink (`autoShrink`, `minFontSize`) inside fixed boxes and the panels have heights, so
  nothing overflows at 200 % text (`ui.overflowed`, checked per language).
- The dialogue validator (`project.validate_dialogue`) also reports a line, choice, chapter, ending or name that one language lacks,
  naming the language, the key and the file.
- The store texts are in `store/<lang>/` for the same five languages (`store/check_store.py`).

Tests: `tests/languages.test.js` (every language in one file: the glyph atlas grows and refills its texts, FB-0901) walks the title, the five options tabs, the
notebook, the board, the items page, the dialogue and the save slots at 100 % and 200 % text with no missing key, placeholder or
overflow, switches the language live and checks what read-aloud says, and a cut-scene caption. The screenshots are in
`.factoria/screenshots/lang/<tag>_<100|200>_<screen>.png`. `tests/keyboard_layout.test.js` covers the on-screen keyboard keys. P8 adds
FB-0901 to FB-0905 (glyph atlas clear leaves texts blank, Korean line breaking, RTL mirroring of anchors and toggles, base direction of
a line, no Hangul on the on-screen keyboard: fixed by the kit's IME hook, M33.14).

## Tests

`tests/` has movement, interaction, camera, areas, flow, data, screenshot and kit tests (`factoria test`);
`tests/helpers/lodge.js` has `enter(area, spawn)`, `stand(x, z, yaw)`, `porter()` and `cam()`. The screenshot test writes
`.factoria/screenshots/hall.png` for a look at the lighting. P4 adds `cutscene_data` (the files and the validator, with
`tests/fixtures/broken_cutscene.json`) and `cutscene` (playing, skipping by keyboard, gamepad and touch, captions in time with
voice, `tests/fixtures/test_voice.wav` made by `assets/src/make_test_voice.py`); it writes `cutscene_caption.png`, `cutscene_card.png` and `cutscene_fade.png`. P2 adds `dialogue_data`, `dialogue_runner`, `dialogue_ui`,
`cast_chapters` and `story_bot` tests; the dialogue UI and ending tests write `dialogue_line.png`, `dialogue_choices.png` and
`ending_quiet.png` there. `tests/helpers/bot.js` has the `Bot` (`play`, `use`, `go`, `talk`, `state`, and from P3 `openPuzzle`, `closePuzzle`, `fixTheFuse`) and `fnv1a`. P5 adds `saves.test.js` (the formats and their
migration, every slot, the screens with mouse, gamepad and touch, the cloud on the fake store, chapter select, achievements and stats;
it writes `slots_load.png` and `chapter_select.png`).

## Known limits and engine gaps

See `ENGINE_FEEDBACK.json`: the 36 gaps the game met while it was built (LL/FB-0001 to FB-0905) are all fixed in the engine
(M33; each entry names the commit), and the game dropped the workarounds: no transparent HUD root Panel, no re-cast rays or
removed colliders, no padded typewriter text, no `MenuStack.busy` routing for Escape, no serial entity ids, no hand-made
mirroring and no U+200F in `he.json`, no bands around the item view, no `make_sound.py`. What stays: the game keeps its own
Text speed row in `options.js` (it predates the kit's `textSpeed` part) and its cut-scene files are imported one by one.
Windows and Linux players of a development build still come from a release (TM/FB-0051, LL/FB-0804, a duplicate).
