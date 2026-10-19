# Lantern Keep

The M21 reference game of FactorIA: a small, complete 2D platformer made the way a game maker's AI makes one (only the
project's own files, the `factoria` CLI and the AI guide). You carry a lantern through a ruined keep, find three embers in
every level and bring the light to the keep's great lantern at the end. Six short levels (30 to 60 seconds each) in two
worlds: **Courtyard** (`1-1`, `1-2`, `1-3`, daylight) and **Cellars** (`2-1`, `2-2`, `2-3`, dark: your lantern is a
`Light2D` that lights the tiles, spikes, enemies and platforms around you, over a parallax background). It plays in
English and Spanish, with keyboard, mouse or gamepad.

This is the first package (core game, menus, languages) of the reference game. Next packages add save slots and a
level select (progress goes to disk), store services (stats, achievements, a cosmetics shop), accessibility, shipping
(export, icons, store pages) and more languages. They build on the three contracts below: do not change them without
changing every package that uses them.

```bash
factoria validate
factoria run                                     # play
factoria run --headless --scene scenes/levels/1-1.scene.json --frames 120 --screenshot-at 119
factoria test                                    # about 50 seconds
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
  the scene: `factoria call scene.import_ascii @levels/1-1.json`, and `factoria call scene.format`.
  Legend: `#` ground, `%` earth, `=` bricks and ledges, `*` flowers (decoration), `P` player, `X` exit, `1 2 3` embers,
  `C` checkpoint, `^` spikes, `e` and `f` enemies (walking left or right first), `m` moving platform (sideways),
  `n` moving platform (up and down), `-` one-way platform. Row 0 is the top row.
- `scripts/player.js` (run, jump, rides moving platforms), `level.js` (timer, embers, deaths, checkpoints, exit, game
  events), `ember.js`, `checkpoint.js`, `exit.js`, `hazard.js` (spikes), `enemy.js` (patrol), `mover.js` (moving
  platform), `follow_camera.js` (follows the player inside the level, shakes), `effects.js` (the one function that shakes
  the camera on a death), `hud.js`, `ui/level_end.js` (the panel with Next / Retry / Menu), `time_format.js`.
- The menus are the recipe of `factoria docs read menus` (AI guide 9.24): `scenes/menu.scene.json`,
  `scenes/loading.scene.json`, `scripts/main_menu.js`, `settings.js`, `pause_menu.js`, `loading.js`, `store_events.js`,
  `scripts/ui/` (`menu_stack.js`, `options.js`, `credits.js`), `prefabs/ui/` (`options`, `pause`, `level_end`). The shop
  of the recipe is left out until the store package.
- `locales/en.json`, `locales/es.json`: every text. Groups: `menu`, `loading`, `pause`, `options`, `credits` (the recipe's),
  `hud.*`, `level.*` (level and world names), `levelEnd.*`. Later packages add their own groups.
- `prefabs/*.prefab.json`: player (with its lantern), ember, spikes, enemy, checkpoint, exit, platforms, spark.
- `assets/`: the template's tileset and jump sound, plus a few small PNGs (spikes, enemy, two background layers) and
  sounds made for this game. Records of where they came from are in `assets.json`.
- `tests/`: `levels.test.js` (every scene is what its map builds, every level has its parts), `mechanics.test.js` (run,
  jump, embers, spikes, checkpoints, enemies, the exit, one-way and moving platforms), `progress.test.js`,
  `play.test.js` (a bot finishes every level), `menus.test.js` (menus, pause, language and the level end panel, with the
  gamepad only). `tests/helpers/autoplay.js` is the bot: `playLevel("1-2")` plays a level to its exit and returns
  `{ completed, seconds, deaths, embers, events }`; `loadLevel(id)`, `listen(...eventNames)` and `teleportOnto(entity, target)`
  help other tests. The levels are built so that this bot finishes all of them.
- `screenshots/`: the main menu, a level of each world and the level end panel.

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

The only place results are recorded. For now they live in `session` (memory, until the game closes); the save package keeps the
same functions and puts storage behind them. The data is a plain JSON object:

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
| `nextToPlay()` | The first unlocked level that is not finished (the last level when all are): what the main menu's Play starts. |

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
| `level_completed` | `{ level, time, embers: [bool, bool, bool], deaths }` | `level.js` | The exit is touched. `time` is seconds (to the millisecond) since the level started; `embers` are the ones found in this run; the result is already in `progress` when it is sent. |

A death (`level.js` `die(cause)`) counts, sends the player back to the last checkpoint (the level start without one),
plays `hurt.wav`, shakes the camera (`effects.js` `deathShake()`: the one place an option can switch the shake off) and
sends `player_died`. Nothing can kill the player for 0.8 s after a respawn.

## What the engine does for this game

- **Levels are ASCII maps.** `scene.import_ascii` with `from` (a base scene with the camera, HUD and rules), `edits`
  (the level's id, the lit map) and `path` builds every level file; the legend's `id` and `overrides` give the three embers
  their numbers. A test rebuilds each map into a scratch file and compares it with the scene on disk.
- **Menus and settings** are the engine's own recipe, driven by tests with the gamepad only; `ui.on` events, `MenuStack`,
  `game.paused`, `input.rebind`, `storage`, `window.available`.
- **Languages.** `factoria.json` `localization`, a `key` on every Text and widget the scenes write, `i18n.t` for the text
  scripts build (timer, ember count, the level end panel), `i18n.on("change")` to write them again.
- **Light and depth.** `Light2D` on the lantern, `lit` on the Cellars' tilemap and sprites, `SceneSettings.ambientLight`,
  `Parallax` with `repeatX` for the arches behind the level.
- **Physics.** `Collider2D.oneWay` for the one-way ledges, a kinematic body with a velocity for the moving platforms,
  triggers for embers, checkpoints, spikes and the exit, `entity.isGrounded()` for jumping.
- **Camera.** `entity.bounds()` of the Tilemap limits the follow camera.
- **Tests.** `game.gamepad()`, `game.audioLog()`, `fa.call("scene.import_ascii")`, events through `world.on`.

The gaps found while making the game are in `ENGINE_FEEDBACK.json`.

## Notes for the next packages

- Add a new level by adding its map to `levels/`, a line to `scripts/levels.js`, its two names to `locales/*.json`, and
  rebuilding; `tests/levels.test.js` and `tests/play.test.js` loop over `LEVELS`, so they pick it up.
- A level scene needs the entities of the base scenes: `player`, `map`, `level`, `camera`, `pause_menu`, `store_events`
  and the HUD texts. The simplest way to keep that true is to start from a base scene.
- Save slots: call `progress.load(saved)` at start and persist `progress.get()` after `level_completed`.
