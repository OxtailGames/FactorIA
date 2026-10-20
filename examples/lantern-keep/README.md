# Lantern Keep

The M21 reference game of FactorIA: a small, complete 2D platformer made the way a game maker's AI makes one (only the
project's own files, the `factoria` CLI and the AI guide). You carry a lantern through a ruined keep, find three embers in
every level and bring the light to the keep's great lantern at the end. Six short levels (30 to 60 seconds each) in two
worlds: **Courtyard** (`1-1`, `1-2`, `1-3`, daylight) and **Cellars** (`2-1`, `2-2`, `2-3`, dark: your lantern is a
`Light2D` that lights the tiles, spikes, enemies and platforms around you, over a parallax background). It plays in
English, Spanish, German and Arabic, with keyboard, mouse or gamepad.

Built by game-maker AIs in six packages (core game and menus, saves, store services, accessibility, shipping,
languages), with only the project's files, the `factoria` CLI and the AI guide. The gaps they met are in
`ENGINE_FEEDBACK.json`. The three contracts below are what the features share: do not change one without changing
everything that uses it.

```bash
factoria validate
factoria run                                     # play
factoria run --headless --scene scenes/levels/1-1.scene.json --frames 120 --screenshot-at 119
factoria test                                    # about 75 seconds
```

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` / `move_right` | A, D or the arrows | D-pad or left stick |
| `jump` | Space, W or Up | A |
| `pause` | Escape or P | Start |

Menus: arrows or D-pad to move, Enter, Space or A to choose, Escape or B to go back. Every action can be rebound in
Options > Controls.

## What is where

- `scripts/levels.js`: the ordered level list (contract 1). `scripts/progress.js`: results (contract 2). `scripts/flow.js`:
  `startLevel(id)` (through the loading screen) and `openMenu()`.
- `levels/<id>.json`: the ASCII map of each level, the arguments of `scene.import_ascii`. They start from
  `levels/base_day.scene.json` or `levels/base_dark.scene.json` (camera, HUD, the level's rules, pause menu, store events,
  the lighting and the background of the Cellars) and write `scenes/levels/<id>.scene.json`. Edit the map, then rebuild
  the scene: `factoria call scene.import_ascii @levels/1-1.json`, and `factoria call scene.format`. Editing a prefab
  (an ember, the touch controls) needs no new import: the level files keep the prefab references.
  The legend common to all maps is `levels/legend.json` (`legendFrom` in each map, the Courtyard's tiles and plain
  hazards); a map keeps in its own `legend` only what differs (the Cellars' tile numbers and lit hazards).
  Legend: `#` ground, `%` earth, `=` bricks and ledges, `*` flowers (decoration), `P` player, `X` exit, `1 2 3` embers,
  `C` checkpoint, `^` spikes, `e` and `f` enemies (walking left or right first), `m` moving platform (sideways),
  `n` moving platform (up and down), `-` one-way platform. Row 0 is the top row. To add a level: its map in `levels/`, a line in `scripts/levels.js`, its name in every `locales/*.json`, then rebuild
  the scene (`tests/levels.test.js` and `play.test.js` loop over `LEVELS`). A level scene needs the entities of the base scenes (`player`,
  `map`, `level`, `camera`, `pause_menu`, `store_events` and the HUD texts): start from a base scene.
- `scripts/player.js` (run, jump, rides moving platforms), `level.js` (timer, embers, deaths, checkpoints, exit, game
  events), `ember.js`, `checkpoint.js`, `exit.js`, `hazard.js` (spikes), `enemy.js` (patrol), `mover.js` (moving
  platform), `follow_camera.js` (follows the player inside the level, shakes), `effects.js` (the one function that shakes
  the camera on a death), `hud.js`, `ui/level_end.js` (the panel with Next / Retry / Menu), `time_format.js`.
- The menus are the recipe of `factoria docs read menus` (AI guide 9.24): `scenes/menu.scene.json`,
  `scenes/loading.scene.json`, `scripts/main_menu.js`, `settings.js`, `pause_menu.js`, `loading.js`, `store_events.js`,
  `scripts/ui/` (`menu_stack.js`, `options.js`, `credits.js`), `prefabs/ui/` (`options`, `pause`, `level_end`).
- `scripts/saves.js` (slots, format, migration, cloud), `scripts/ui/slots.js`, `delete_confirm.js`, `level_select.js` with
  `prefabs/ui/slots`, `delete_confirm` and `level_select` (see "Saves and the level select").
- Store services (section "Store services" below): `factoria.json` `"platform"` (the catalog), `scripts/store_stats.js` (stats,
  achievements and best times from the game events; one entity `store_stats` in every level), `scripts/cosmetics.js` (the
  colours, the wallet, `grant`; one entity `cosmetics` in every level puts the chosen colour on the player), `scripts/ui/shop.js`,
  `achievements.js`, `leaderboards.js` and `store_ui.js` (what the three screens share), `prefabs/ui/shop`, `achievements` and
  `leaderboards`. The main menu has a row with the three buttons; `lanternColour` is a player setting in `settings.js`.
- Accessibility (see the section below): `scripts/assist.js` (assist speed and invincibility), `scripts/effects.js` (shake and
  sparks, each gated by an option), `autoSize` on every button, toggle and slider (they grow to their label at any text size and language), the Access tab in
  `prefabs/ui/options.prefab.json` and `scripts/ui/options.js`, the options in `scripts/settings.js`.
- `locales/en.json`, `es.json`, `de.json`, `ar.json`: every text. Groups: `menu`, `loading`, `pause`, `options` (with `options.accessibility.*` and `options.tab.accessibility`), `credits` (the recipe's),
  `hud.*`, `level.*` (level and world names), `levelEnd.*`, the saves' `slots.*` and `select.*`, and the store's `achievements.*`, `leaderboards.*`, `shop.*` and
  `platform.*` (the store's messages). The four tables (`en`, `es`, `de`, `ar`) have the same keys: see "Languages".
- `prefabs/*.prefab.json`: player (with its lantern), ember, spikes, enemy, checkpoint, exit, platforms, spark.
- `assets/`: the template's tileset and jump sound, plus a few small PNGs (spikes, enemy, two background layers) and
  sounds made for this game. Records of where they came from are in `assets.json`.
- `tests/`: `levels.test.js` (every scene is what its map builds, every level has its parts), `mechanics.test.js` (run,
  jump, embers, spikes, checkpoints, enemies, the exit, one-way and moving platforms), `progress.test.js`,
  `saves.test.js` (slots, level select, autosave, migration from `tests/fixtures/save_v1.json`, damaged saves, cloud saves
  against the fake store, failures included), `play.test.js` (a bot finishes every level), `menus.test.js` (menus, pause, language and the level end panel, with the
  gamepad only), `store.test.js` (stats, achievements and leaderboard submits from the events) and `store_screens.test.js` (the
  three screens and the purchases, with the gamepad only), both against the fake store, `accessibility.test.js` (every option saved, applied and effective; every
  screen in every language at 100% and 200% text, with `tests/helpers/screens.js`), `languages.test.js` (the four tables have the same keys and
  placeholders, the language button, Arabic's mirrored HUD) and `shipping.test.js`. `tests/helpers/autoplay.js` is the bot: `playLevel("1-2")` plays a level to its exit and returns
  `{ completed, seconds, deaths, embers, events }`; `loadLevel(id)`, `listen(...eventNames)` and `teleportOnto(entity, target)`
  help other tests. The levels are built so that this bot finishes all of them.
- `screenshots/`: the main menu, the save slots, the level select, a level of each world, the level end panel and the achievements, leaderboards and shop screens;
  `a11y-*.png`: the Accessibility tab, the menu, a level and the level end panel at 200% text, and the hazards in colour and
  in greyscale; `main-menu-ar.png`, `level-select-ar.png` (Arabic) and `options-de-200.png` (German at 200% text).
- Shipping: `assets/icon.png` and `assets/icon_fg.png` (drawn by `tools/make_icon.py`), `prefabs/ui/touch_controls.prefab.json`
  (the on-screen gamepad, an entity of both base scenes), `store/` (store texts and release notes in the four languages),
  `store/screenshots/` (store screenshots made by `tools/make_screenshots.py`; not committed; `export.exclude` in
  `factoria.json` keeps `store/`, `levels/` and `screenshots/` out of exports),
  `tests/shipping.test.js` (touch controls, safe area, the settings the exports rely on, the store texts of every language), `SHIPPING.md`.

## Saves and the level select

Play opens the three **save slots** (`prefabs/ui/slots`, `scripts/ui/slots.js`): an empty one says "New game", a used one shows
levels finished n/6, embers n/18 and the sum of the best times, a damaged one says "Damaged". Choosing a slot makes it the
current one (`session.slot`), loads its progress and opens the **level select** (`level_select`): both worlds, each level with
its name, "Locked" (`progress.isUnlocked`) or its embers and best time. The level end panel's Menu returns to it
(`flow.openMenu(true)`, read by `main_menu.js`); Back goes to the slots, then the main menu. "Delete" asks first
(`delete_confirm`, the focus is on "Keep it"). **Continue** on the main menu appears when the last saved slot is usable and opens
its level select. Everything is driven with the pad, keyboard or mouse like the recipe's menus. Settings are not in the slots:
they stay under the `settings` key of `storage`.

**Files.** A slot is a string of JSON text in `storage` under `slot1`, `slot2`, `slot3` (plus `lastSlot`, a number).
`progress.record()` calls `saves.save()`, so the slot is written after every `level_completed`; before a level is finished
nothing is written. Without a chosen slot (tests, a level started from the editor) nothing is saved.

**Format.**

| version | layout |
|---|---|
| 1 (no `version` field) | `{ "cleared": ["1-1"], "best": { "1-1": 41.2 } }`. Embers were not saved. |
| 2 (now) | `{ "version": 2, "counter": 7, "levels": { "1-1": { "completed": true, "bestTime": 41.2, "embers": [true, false, true] } } }` |

`saves.parse(text)` reads any version and returns version 2 data (`migrate1` upgrades version 1: the cleared levels become
completed, with no embers). The next save writes version 2. Text that is not JSON, is not an object, has a version newer than
the game's, or levels that are not shaped like the table is **damaged**: the slot says so, cannot be chosen and can be deleted;
nothing throws. Levels the game does not know are dropped. A `storage.json` that does not parse as a whole is the engine's
job, not the game's: it keeps the file as `storage.corrupt.json` and the game starts with empty slots (`storage.corrupt` is
`true`; the game does not show a message for it, there is no screen for one). `tests/saves.test.js` starts from such a file
with `game.setStorageText`. Change the layout: bump `VERSION`, add a `migrateN`, keep the fixture of the old layout in
`tests/fixtures/` and test it.

**Cloud saves** (`platform.cloud`, see `factoria docs read platform`; no catalog entry is needed). `counter` goes up by one on
every save (never the clock, so runs repeat). After each save the slot text is uploaded under the same key. When the slot screen
opens, `saves.syncCloud()` compares each slot with its cloud copy: the higher `counter` wins, a better cloud copy replaces the
local slot (also a damaged or empty one), a better or missing cloud copy is uploaded. Equal counters keep the local copy. A
backend without cloud saves, a player not signed in or a failed upload or download changes nothing locally: the local save is
always written first and never waits for the store. Deleting a slot deletes its cloud copy; if that delete fails, the copy can
come back at the next sync (known limit).

## Shipping

`factoria.json` holds the version, icon, per-platform export settings and the `publish` ids (fake placeholders), and the
game has an on-screen gamepad and a safe-area HUD for phones. What each store needs, what the engine does, what stays
by hand and what could not be checked on the machine that prepared the export is in [`SHIPPING.md`](SHIPPING.md).

```bash
factoria export --platform windows --release        # lantern-keep.exe + game.pak
factoria export --platform android --format aab --release   # needs the Android toolchain and a keystore
python tools/make_icon.py                           # redraw the icon (Python and Pillow)
python tools/make_screenshots.py factoria           # redraw the store screenshots
```

## Languages

English (the default, and the language of the text in the scenes), Spanish, German and Arabic: `factoria.json` `localization`,
`locales/<tag>.json`, a `key` on every Text and widget the scenes write, `i18n.t` for what scripts build. Each table has the same
keys and the same `{placeholders}` (`tests/languages.test.js`); the options' Language button cycles through them, each named in
itself, and the choice is saved with the settings. No font was added: the engine's DejaVu Sans draws Latin, German and Arabic.

- **German** is the layout stress test (long words: "Bestenlisten", "Bildschirmwackeln", "Unterstützer"). It was made the way a
  studio would: `i18n.export {"format":"csv","languages":["de"],"delimiter":";"}` (the semicolon is what a German Excel
  expects), the `de` column filled in, `i18n.import` (`dryRun` first: 148 rows added, no warnings), then `factoria validate`.
  That round trip worked without surprises. Back then `i18n.import` wrote flat dotted keys for a language with no file yet,
  so the file was rewritten nested like the others (same strings, checked equal); the engine now copies the nested shape
  of the default table (engine feedback FB-0043).
- **Arabic** went through XLIFF (`format: "xliff"`, `languages: ["ar"]`, targets filled in, `i18n.import` of the `.xlf`; same
  result). Arabic has six plural forms, but the game's texts have no plural (they show `3/18`, not "3 embers"), so none
  of the six is used and the `i18n.import` check could not exercise them: a new text with a count needs `zero` to `other`.
  Letters are joined and ordered by the engine, numbers keep left-to-right inside the sentence ("1-1  أول ضوء").
  What the game does for right-to-left: `direction: "auto"` on every row panel (the main menu's row of three, the options
  tabs, the level select rows and the level end panel are mirrored by the engine), `align: "start"` on every wrapped Text,
  and the HUD corners chosen from `i18n.direction` in `hud.js` (name on the right, embers on the left): anchors and
  pivots are not mirrored by themselves. The lines of a two-line button are centred by the engine.
- **Every screen at 100% and 200% in every language** (main menu, options tabs, credits, slots, delete confirmation, level
  select, achievements, leaderboards and shop with a working and a signed-out store, HUD, pause, level end panel) is
  checked by `tests/accessibility.test.js`. Making them fit meant: `autoSize` on every button, toggle and slider (the engine
  grows them to their label, two-line labels included), a slot line breaking after "Slot 2:" when it is wide, the level select
  giving its six buttons one common size and putting the two worlds side by side with a column of three levels each when
  three buttons no longer fit a row, the shop putting its note beside the buttons when one column is taller than the screen
  (both still measured in script: LK/FB-0046, LK/FB-0047), and the achievements and leaderboards lists taking the height the
  other texts leave (`ScrollList.fill`).
- **Store texts** for every language are in `store/store.<tag>.json` and `store/whats-new-<tag>.txt`; `factoria.json` `publish`
  lists the languages for GOG and the Google Play changelogs (`SHIPPING.md`).
- **Adding a language:** add the tag to `localization.languages`, `i18n.export` it, fill the file, `i18n.import`, `factoria validate`
  (it also checks that the fonts have every glyph), then a store text, and add it to the language lists at the top of `tests/languages.test.js`,
  `tests/accessibility.test.js` and `tests/shipping.test.js`.

## Contract 1: the level list (`scripts/levels.js`)

The only place the list lives. In order:

| id | world | scene | nameKey |
|---|---|---|---|
| `1-1` | 1 | `scenes/levels/1-1.scene.json` | `level.1-1` |
| `1-2` | 1 | `scenes/levels/1-2.scene.json` | `level.1-2` |
| `1-3` | 1 | `scenes/levels/1-3.scene.json` | `level.1-3` |
| `2-1` | 2 | `scenes/levels/2-1.scene.json` | `level.2-1` |
| `2-2` | 2 | `scenes/levels/2-2.scene.json` | `level.2-2` |
| `2-3` | 2 | `scenes/levels/2-3.scene.json` | `level.2-3` |

Exports: `LEVELS` (`{ id, world, scene, nameKey }`), `WORLDS` (`{ 1: { nameKey, dark }, 2: ... }`), `EMBERS_PER_LEVEL` (3),
`find(id)`, `next(id)`, `previous(id)`.

## Contract 2: progress (`scripts/progress.js`)

The only place results are recorded. They live in `session`; `record()` also writes the chosen save slot (`scripts/saves.js`,
section "Saves and the level select"). The data is a plain JSON object:

```json
{ "levels": { "1-1": { "completed": true, "bestTime": 41.2, "embers": [true, false, true] } } }
```

A level that was never finished has no entry. `embers` are the ones found in any run; they only turn `true`.

| Function | Does |
|---|---|
| `get()` | A copy of the whole object. |
| `load(saved)` / `reset()` | Replace the whole progress (for a save) / forget everything. |
| `of(id)` | `{ completed, bestTime, embers }` of one level (`bestTime` is `null` before the first finish). |
| `record(result)` | `result` is the `level_completed` payload. Keeps the best time and the embers; returns `{ firstCompletion, newBest, bestTime, previousBest }`. `level.js` calls it when the exit is touched. |
| `isCompleted(id)` / `isUnlocked(id)` | `1-1` is always open; any other level opens after the one before it was finished. |
| `totalEmbers()` | Embers found in all levels (at most 18). |
| `nextToPlay()` | The first unlocked level that is not finished (the last level when all are). The main menu's Play opens the save slots instead, so nothing in the game calls it; it is there for other features. |

## Contract 3: game events

Sent with `world.emit` by the gameplay scripts; other features listen with `world.on(name, fn)` (store stats, achievements,
accessibility). `level` is the level id of contract 1.

| Event | Payload | Sent by | When |
|---|---|---|---|
| `level_started` | `{ level }` | `level.js` | The first frame of the level (every script of the scene has started and can listen). |
| `player_jumped` | `{ level }` | `player.js` | A jump leaves the ground. |
| `ember_collected` | `{ level, index, found }` | `level.js` (from `ember.js`) | An ember is touched: `index` 0 to 2, `found` the count so far in this run. Once per ember. |
| `checkpoint_reached` | `{ level, index }` | `level.js` (from `checkpoint.js`) | A checkpoint is touched (numbered from the left; one with a lower index than the current one does not count). |
| `player_died` | `{ level, cause }` | `level.js` | `cause` is `"spikes"`, `"enemy"` or `"fall"`. After the respawn. |
| `level_completed` | `{ level, time, embers: [bool, bool, bool], deaths, assisted }` | `level.js` | The exit is touched. `time` is seconds (to the millisecond) since the level started, in game time (it runs slower with the assist speed); `embers` are the ones found in this run; `assisted` is `true` when an assist option (slower game or invincible) was on at any moment of the level, `false` otherwise: a time with `assisted: true` does not belong on a leaderboard. The result is already in `progress` when it is sent. |

A death (`level.js` `die(cause)`) counts, sends the player back to the last checkpoint (the level start without one),
plays `hurt.wav`, shakes the camera (`effects.js` `deathShake()`: the one place an option can switch the shake off) and
sends `player_died`. Nothing can kill the player for 0.8 s after a respawn.

## Store services (achievements, stats, leaderboards, shop)

All of it runs on the `platform` API of the engine: the fake store in development and in every test, the real one when a store
plugin is added (`factoria docs read platform`), and **no store** in an exported game without a plugin. The catalog is in
`factoria.json` `"platform"`.

**Catalog.** Eight achievements: `first_light` (finish 1-1), `courtyard_clear` and `cellars_clear` (finish the three levels of a
world), `all_embers` (all 18, with progress), `untouched` (a level without dying), `quick_feet` (1-1 in under 28 s),
`jumper` (500 jumps, with progress) and `hard_lessons` (25 deaths, with progress). Stats: `jumps`, `deaths`, `embers_found`
(embers found in all levels, never counted twice) and `levels_finished`. Leaderboards: `time_1-1` ... `time_2-3` and
`time_total`, all ascending, the score being the time in milliseconds. Products: `lantern_colours` and `supporter`
(non-consumable). The names and descriptions in the catalog are for the store; the game's own screens read them from
`locales/*.json` (the catalog has no key for them: `ENGINE_FEEDBACK.json`).

**What feeds what** (`scripts/store_stats.js`, game events of contract 3):

| Event | Does |
|---|---|
| `player_jumped` | Counted in memory, sent to `jumps` in groups of ten (and on a death, a finish or leaving the level); moves `jumper`. |
| `player_died` | `deaths` + 1; moves `hard_lessons`. |
| `level_completed` | `levels_finished` + 1, `embers_found` = `progress.totalEmbers()`; `first_light`, the two world achievements and `all_embers` from `progress`; then, unless `assisted` is true, `untouched`, `quick_feet` and the best time. A missing `assisted` means false. |

Everything is best effort: a failing request is lost, never shown, and the next event brings the totals up to date. Requests
go one after the other, so a get-then-set of a stat never overlaps another one. With no store (`platform.has` is false) the
script does nothing.

**Leaderboards: one per level plus a total.** A level's board answers "how fast can I run this one" and is what a player
compares with friends on one map; the total answers "how fast is the whole keep" and rewards finishing all six. Both are cheap
(seven boards) and the screen cycles through them. A time is sent only when it beats the best this game already sent (kept in
`storage` under `leaderboardsSent`, so a slower run, a repeat and an assisted run send nothing, and a request that failed is not
marked and is tried again by the next faster time). The total is sent once all six levels have a time, and only when the sum
improves.

**Screens**, from the main menu's row of three buttons, each a prefab in `prefabs/ui/` opened with `MenuStack`:
Achievements (every achievement with "locked", "unlocked" or its percentage; asks the store again at each visit), Leaderboards
(Board cycles the six levels and the total, Show cycles Top, Around me and Friends; the player's own row is marked and their
best time is written above the list) and Shop. Each has a Refresh (which signs in) except the shop, which has Restore purchases.

**The shop sells cosmetics only** (it says so on screen): "Lantern colours" (rose, azure, jade, violet) and "Supporter" (the gold
lantern and a line in the credits). A purchase is granted into the wallet (`storage` key `wallet`) and then finished with the
store (`scripts/cosmetics.js` `grant`), once per transaction; a cancelled purchase, a pending one and every failure show a
sentence and add nothing; a purchase approved later arrives through the `purchase` event; Restore purchases adds what the
store says the player owns. The chosen colour is `lanternColour` in the settings (the shop's colour button cycles the colours the
player owns); `scripts/cosmetics.js` puts it on the player's coat, flame, `Light2D` and glow in every level, and a colour that is
no longer owned counts as amber.

**Without a store, signed out or failing.** Every screen explains in a plain sentence (`platform.*` in the locales): no store
connected, not signed in (Refresh signs in), the store cannot be reached, or any other code with the store's hint. Nothing
blocks: Back always works, the game plays on, the colours already owned stay usable, the shop's buy buttons are greyed out
(not interactable) and Restore purchases answers with the same sentence instead of doing anything. The pad still has a
focus on the shop (the first button that can be used, the colour button: the engine's `autoFocus` fallback). The overlay of
a real store pauses the level (`store_events`).

## Accessibility (Options > Access)

Saved with the other settings (`storage` key `settings`, `scripts/settings.js`) and applied when the game starts.

| Option | How it works |
|---|---|
| Text size | 100, 125, 150, 175 or 200%: `ui.textScale`. `autoSize: true` on every button, toggle and slider makes it as big as its label needs, and `ScrollList.fill` gives the achievements and leaderboards lists the height the screen leaves; the options and credits panels get wider (up to 1240 px), the level end panel puts the buttons beside the text, the HUD puts the timer on a second row when the three texts would touch. `tests/accessibility.test.js` checks every screen in every language at 100% and 200%: widgets inside the screen, labels inside their widget, no text wider than its box, every panel big enough for its content (`tests/helpers/screens.js`). |
| Game speed | 100, 90, 80, 70 or 60%: `time.scale` while playing (`assist.applySpeed()` sets it at the start of a level). The pause menu is `game.paused`: pausing remembers the `time.scale` and resuming restores it, so the assist speed survives; a speed picked in Options while paused is the one restored (engine feedback FB-0036). `flow.js` sets `time.scale = 1` when a scene is left (a scene load keeps `time.scale`), and `level.js` `refreshAssist()` marks the run as assisted at the start of a level and after each resume. Level times are game time. |
| Invincible | Spikes and enemies do nothing. A fall puts the player back at the last checkpoint (or the start) and does **not** count as a death: no `player_died`, no shake, no hurt sound. |
| Screen shake | Off: `effects.js` `deathShake()` does nothing. |
| Reduced effects | On: no spark burst when an ember is collected (`effects.js` `emberSpark()`). The game has no other particles or flashes. |

Assist mode (slower game or invincible) marks the run: `level_completed` carries `assisted: true` when either was on at any
moment of the level (turning it off again does not undo it), and the level end panel says "Assist mode was on". The best time and
the embers are still kept in `progress`; the store services keep `assisted` runs off the leaderboards.

**Hazards without colour.** Spikes are three sharp triangles with a dark outline (`assets/spikes.png`); enemies are a rounded box
with a light and a dark outline and yellow eyes (`assets/enemy.png`); embers are a diamond with a dark outline; a checkpoint is a
ring on a post (hollow until you reach it, then solid); the exit is a big lamp with a star in a dark frame. The greyscale check
(`screenshots/a11y-hazards-colour-and-grey.png`) was made outside the engine. In the Cellars the sprites are lit by the lantern,
so spikes far from the light stay dark, as designed; the outline makes them readable once they are lit.

**What the engine could not do** (all in `ENGINE_FEEDBACK.json`): a colour-blind or greyscale filter or preview, reading the
system's accessibility settings, speaking menu text (no screen reader), buttons that size themselves to their label. Not
built: colour-blind filters, subtitles (the game has no speech), screen reader, hold-or-toggle (the game has no held action:
jump is one press).

## What the engine does for this game

- **Levels are ASCII maps.** `scene.import_ascii` with `from` (a base scene with the camera, HUD and rules), `edits`
  (the level's id, the lit map) and `path` builds every level file, as prefab references (editing a prefab changes every level at once); the
  legend's `id` and `overrides` give the three embers their numbers, and `legendFrom` shares one legend between the six maps. A test rebuilds each map into a scratch file and compares it with the scene on disk.
- **Menus and settings** are the engine's own recipe, driven by tests with the gamepad only; `ui.on` events, `MenuStack`,
  `game.paused`, `input.rebind`, `storage`, `window.available`.
- **Languages.** `factoria.json` `localization`, a `key` on every Text and widget the scenes write, `i18n.t` for the text
  scripts build (timer, ember count, the level end panel), `i18n.on("change")` to write them again.
- **Light and depth.** `Light2D` on the lantern, `lit` on the Cellars' tilemap and sprites, `SceneSettings.ambientLight`,
  `Parallax` with `repeatX` for the arches behind the level.
- **Physics.** `Collider2D.oneWay` for the one-way ledges, a kinematic body with a velocity for the moving platforms
  (it carries the player),
  triggers for embers, checkpoints, spikes and the exit, `entity.isGrounded()` for jumping.
- **Camera.** `entity.bounds()` of the Tilemap limits the follow camera.
- **Panels that refresh themselves.** `onEnable()` writes the level end panel, the save slots, the level select and the
  delete question every time they are shown (before the frame is drawn); the code that shows a panel only hands it data.
- **Tests.** `game.gamepad()`, `game.audioLog()`, `fa.call("scene.import_ascii")`, events through `world.on`,
  `game.platform.set({ backend: "none" })` for a game without a store, `game.touch(id)` / `ui.rectOf(id)` for the
  on-screen controls and `toMatchObject`.

The gaps found while making the game are in `ENGINE_FEEDBACK.json`.
