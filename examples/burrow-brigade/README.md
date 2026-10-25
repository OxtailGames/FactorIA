# Burrow Brigade

A top-down 2D mining game for up to four players on one screen (couch co-op), for desktop first and Steam. Dig dirt and
rock with a pick, take the ore, keep your lamp alight with oil cans, free the moles trapped in the rock, and ride the lift
up before the dark gets you. It is the third reference game of the FactorIA engine (milestone M28), built in eight
packages (P1 to P8). This is package P1: the miner, digging and the mine. The later packages build on the contracts below.

## Run

```bash
factoria validate
factoria run                      # windowed
factoria run --headless --frames 120 --screenshot-at 119
factoria test                     # headless tests
factoria call project.mine_preview '{"seed":1234}'    # a generated mine as text, with its hash
```

The title (`scenes/menu.scene.json`) goes through Play and `scenes/loading.scene.json` to a shift
(`scenes/shift.scene.json`, a generated mine), then to the results (`scenes/results.scene.json`), then another shift or
the title. `scenes/test_mine.scene.json` is a small handmade mine the tests use (its layout is in `tests/helpers/mine.js`);
it is not in the player's flow.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Walk (4 directions) | WASD / arrows | left stick or d-pad |
| Dig (hold, facing a tile) | Space / J | A or X |
| Pause | Escape / P | Start |

You dig the tile you face: walk into it to turn towards it, then hold dig. A crack grows on the tile while you dig and
fills back in if you let go. Dig times with the starting pick: dirt 0.5 s, rock 1.4 s, hard rock 2.2 s, copper 0.6 s,
silver 1.5 s, gold 2.4 s, gems 2.6 s. Hard rock, gold and gems need the tier 1 pick (P2 sells it): without it the
miner makes a "blocked" sound. Bedrock never breaks. Rebinding is in Options > Controls.

## The shift

- The **lamp** holds 120 s of oil and burns one per second while the miner is working. Its light shrinks as the oil falls and
  fades out over the last 3 s; under a quarter the HUD bar turns red and a warning shows. An **oil can** (on the floor) refills
  40 percent of a full lamp and is used up.
- **Ore** goes into the miner's pockets the moment its tile is dug: copper 1, silver 3, gold 8, gem 20 cash each.
  The generator guarantees a way to the exit that needs no better pick than the starting one.
- A **trapped mole** sits in a sealed pocket next to a tunnel; dig in and walk close to free it.
- The shift ends when every miner that is not down stands on the **exit lift** (outcome `lift`: the ore value is banked as
  cash) or when every lamp has been out for 2 s (outcome `dark`: the ore is lost). The results screen shows the outcome, the
  ore by kind, its value, the time, the moles rescued and the cash.
- Each shift of a run is another mine (`run.seed + shiftNumber - 1`). Depth in the HUD is 30 m per stratum plus 10 m per
  floor. Deeper strata and floors are bigger, with more rock and richer ore (`STRATA` in `generator.js`).

## Layout

```
factoria.json              input actions, the title as main scene
scenes/                    menu, loading, shift, results, test_mine
prefabs/                   miner, mole, ui/options, ui/pause
scripts/game/              the game: see Contracts
scripts/                   menu kit (main_menu, pause_menu, loading, settings, ui/*) and results.js
tools/mine_preview.js      project.mine_preview: a mine as text
tests/                     generator, mine, input and flow tests; helpers/mine.js
assets/                    tiles.png, sprites.png (+ src/make_atlases.py), audio/*.wav
locales/en.json            every string of the UI
```

## Contracts (for P2 to P8)

Every module is plain JavaScript under `scripts/game/`, with its state in a module singleton (it survives scene loads; every
test file starts fresh). Import them with relative paths.

### Generator: `scripts/game/generator.js`

- `generate(seed, stratum = 0, floor = 1, opts?)` returns a `Mine` (plain data): `{ format, seed, stratum, floor, width,
  height, kinds[], start, exit, spawns[], moles[], rooms[], plugs[], oreCounts, oilCount, solvable, hash }`. `kinds` is
  row-major with row 0 at the top and holds the `K` constants of `tiles.js` (`FLOOR`, `DIRT`, `ROCK`, `HARD`, `BEDROCK`,
  `COPPER`, `SILVER`, `GOLD`, `GEM`, `LIFT_START`, `LIFT_EXIT`, `OIL`). `start`, `exit`, `spawns` (up to four free tiles next
  to the entry lift) and `moles` are `{ tx, ty }`. It uses only `rng.create` (seeded from seed, stratum and floor), never the
  world RNG or the clock: the same arguments give the same mine on every machine. `opts` is `{ width, height }`.
- `mineHash(mine)` returns an 8-hex-digit FNV-1a fingerprint of the format, seed, stratum, floor, size, tiles, lifts, spawns
  and moles; `mine.hash` is the hash at generation, and `mineHash(map.mine)` follows the digging. `tests/generator.test.js`
  pins `generate(1234, 0, 1).hash` (`3b3dde14`): change the algorithm on purpose, raise `MINE_FORMAT` and update the test.
- `exitReachable(mine, tier)` says whether the exit can be reached digging with a pick of that tier; `generate` guarantees it
  for tier 0 (`mine.solvable`). `STRATA` (`topsoil`, `rockLayers`, `deep`) and `stratumInfo(n)` hold the rock share and the
  ore weights.
- `mine_ascii.js`: `toRows(mine)` and `fromRows(rows, opts)` turn a mine into text and back (one character per tile, the legend
  is at the top of the file). Handmade mines for scenes and tests use `fromRows` through the `rows` prop of the Shift script.

### Map and dig: `scripts/game/mine_map.js`

`new MineMap(mine)` wraps a mine and edits `mine.kinds` in place. The shift scene creates it and publishes it as `live.map`
(and `live.mine`); both are `null` outside a shift. World mapping: the Tilemap entity is at (0, 0), tiles are 16 units, tile
(tx, ty) has its centre at `((tx + 0.5) * 16, -(ty + 0.5) * 16)` (world y goes up, rows count down).

- Queries: `inBounds`, `kindAt(tx, ty)` (off the map is bedrock), `isSolid`, `isWalkable`, `tileAt(x, y)`,
  `tileCenter(tx, ty)`, `count(kind)`, `canDig(tx, ty, tier)` -> `{ ok, reason? }` (`air`, `bedrock`, `tier`).
- Changes: `dig(tx, ty, { tier, by })` turns a diggable tile into floor and returns `{ ok, kind, ore, value }` (it emits
  `dug`; for bedrock or a pick that is too weak it returns `{ ok: false, reason }` and emits `digBlocked`);
  `setKind(tx, ty, kind, cause)` writes any tile.
- Notification: `map.onChange(fn)` calls `fn({ tx, ty, from, to, cause })` for every changed tile and returns the unsubscribe
  function; the same notice goes out as the `tileChanged` event. The shift scene uses it to rewrite the Tilemap once per frame.
- Collision for walkers: `moveBox(x, y, halfW, halfH, dx, dy)` moves an axis-aligned box and stops it at solid tiles;
  `boxHitsSolid(x, y, halfW, halfH)`.

### Players registry: `scripts/game/players.js`

`add({ device, name, color })`, `remove(id)`, `get(id)`, `all()`, `count()`, `alive()`, `setState(id, "active" | "lift" |
"down")`, `ensureOne()`, `clear()`, `MAX_PLAYERS` (4), `PLAYER_COLORS`, `KEY_SCHEMES`. A player is `{ id, name, device, color,
state }`. The shift spawns one miner per registered player (`prefabs/miner.prefab.json`, prop `playerId`) and the HUD shows one
oil bar each. `device` decides which input moves the miner (`scripts/game/miner_input.js`): `{ kind: "any" }` (the project's
actions: keyboard and every pad; one player only, the title's Play uses it), `{ kind: "keys", scheme: "wasd" | "arrows" | "ijkl" }`
or `{ kind: "pad", index }` (left stick or d-pad, A or X). `tests/input.test.js` drives two keyboard players and a second pad at
once. `setState` emits `playerState` and, for `"down"`, `playerDown`; a miner that is `down` does not move, dig or burn oil and
the shift's end check ignores it. Nothing in P1 sets `down`; P4 does. There is no join screen yet (P3).

### Game events: `scripts/game/events.js`

A synchronous bus in a module singleton (it outlives scenes, unlike scene-bound listeners): `on(name, fn)` returns the
unsubscribe function, `emit(name, data)`, `count(name)`, `emitted(name)`, `clear()`, `history`. An unknown name throws with a
"did you mean". `EVENTS` documents every name and its data. P1 emits `shiftStarted`, `dug`, `digBlocked`, `orePicked`,
`oilPicked`, `lampLow`, `lampOut`, `liftReached`, `moleRescued`, `shiftEnded`, `playerAdded`, `playerRemoved`, `playerState`,
`playerDown` and `tileChanged`. `upgradeBought`, `cashChanged` (P2) and `hazardTriggered` (P4) are reserved: they can be
subscribed to but nothing emits them yet. A behaviour that subscribes unsubscribes in `onDestroy`; `startRun` clears the bus.

### Run state: `scripts/game/run_state.js`

`run` is `{ active, seed, stratum, floor, shiftNumber, cash, upgrades, ore, lamps, molesRescued, molesTotal, shiftTime,
inShift, lastShift }`. `upgrades` is `{ pickTier, pickSpeed, lampOil, lampRadius, walkSpeed }` (`BASE_UPGRADES`); the miner
already reads every one, P2 changes them. `lamps` maps a player id to `{ oil, max, out, low }` (`lampOf(id)`). Functions:
`startRun({ seed, stratum, floor })` (the title's Play calls it), `beginShift()` (the shift scene calls it: resets ore, lamps,
clock and moles, and returns the mine seed), `addOre`, `totalOre`, `oreValue`, `endShift("lift" | "dark")` (banks the ore value
for `lift` and builds `run.lastShift`), `snapshot()` and `restore(data)` (what a save holds).

### Save stub: `scripts/game/save.js`

`save()` writes `{ format: SAVE_FORMAT, seed, stratum, floor, shiftNumber, cash, upgrades }` to `storage` key `burrow.save` when a
shift ends; `load()`, `apply()` (puts a save into the run state) and `erase()`. `migrate(data)` is where a later format is
brought up to date: today it only checks the `format` field and answers `{ ok: false, message, hint }` for a file with no format
or a newer one. Nothing reads the save at the title yet (P2 adds Continue).

## Tests

`factoria test` runs `tests/*.test.js` headless:

| File | What it checks |
|---|---|
| `generator.test.js` | the same seed gives the same mine and a pinned hash, other seed / stratum / floor differ, borders and a reachable exit, richer deep strata, the text format |
| `mine.test.js` | the map, digging dirt / rock / hard rock / bedrock, the pick tier, ore pickup, oil drain, warning and darkness, the oil can, the lift ending the shift, the moles |
| `input.test.js` | the keyboard and a gamepad each drive the miner, two keyboard players and a second pad each move only their own miner, the four-player registry |
| `flow.test.js` | title -> loading -> shift -> results -> another shift or title, ore banked or lost, leaving a scene mid-wait, the pause menu, the save, the events bus |
| `recipe.test.js` | the menu kit's gamepad-only options test |

## Assets and credits

| File | Source | Licence |
|---|---|---|
| `assets/tiles.png`, `assets/sprites.png` | Kenney, [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon) and [Roguelike Caves & Dungeons](https://kenney.nl/assets/roguelike-caves-dungeons), cut and re-packed by `assets/src/make_atlases.py`; the mole, the arrows and the cracks are drawn by that script | CC0 |
| `assets/audio/*.wav` | made with `assets.synth_sound` (presets footstep, hit, coin, pickup, error, powerup, whoosh, click) | CC0 |

`assets.json` records the provenance of each file. The engine gaps found while building P1 are in `ENGINE_FEEDBACK.json`.

## Status

| Package | What | State |
|---|---|---|
| P1 | The miner, digging and the mine | done |
| P2 to P8 | The shop and the campaign (Continue from the save), local co-op, hazards, audio, polish, Steam | to do |
