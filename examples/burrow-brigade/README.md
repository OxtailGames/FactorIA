# Burrow Brigade

A top-down 2D mining game for up to four players on one screen (couch co-op), for desktop first and Steam. Dig dirt and
rock with a pick, take the ore, keep your lamp alight with oil cans, free the moles trapped in the rock, and ride the lift
up before the dark gets you. It is the third reference game of the FactorIA engine (milestone M28), built in eight
packages (P1 to P8). This is package P4 (camp, progress and saves) on top of P1 (the miner, digging and the mine) and P2 (the world and its enemies). The later packages build on the
contracts below.

## Run

```bash
factoria validate
factoria run                      # windowed
factoria run --headless --frames 120 --screenshot-at 119
factoria test                     # headless tests
factoria call project.mine_preview '{"seed":1234}'    # a generated mine as text, with its hash
```

Flow: title -> slots (Play, Continue, Daily dig or a seed code) -> shift (`scenes/shift.scene.json`, a generated mine) ->
results (`scenes/results.scene.json`) -> camp (`scenes/camp.scene.json`, the shop) -> the next shift. The loading screen
(`scenes/loading.scene.json`) sits between scenes. `scripts/game/progression.js` decides what follows a shift. A victory over
the Mole King starts a new run in the same slot at once (no camp); a daily dig goes back to the title instead. `scenes/test_mine.scene.json` is a small handmade mine the tests use (its layout is in `tests/helpers/mine.js`);
it is not in the player's flow.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Walk (4 directions) | WASD / arrows | left stick or d-pad |
| Dig (hold, facing a tile) | Space / J | A or X |
| Place a torch | T | B or Y |
| Pause | Escape / P | Start |
| Menus, camp, slots, code panel | arrows / Tab, Enter, mouse | d-pad or stick, A |

In the camp each shop line is a button (`buy_<id>`): move with up/down, buy with submit or click. Cash and the next price show
on the button; when the cash is short or the item is at its maximum the camp says so. "Descend" starts the next shift, "Copy
seed code" copies the code of the next floor. At the title, Continue loads the last slot; Play opens the 3 slots (a free slot
starts a run, a used one continues it, its delete button asks to confirm); "Seed code" opens a text field (type or paste, Enter
plays it).

You dig the tile you face: walk into it to turn towards it, then hold dig. A crack grows on the tile while you dig and
fills back in if you let go. Dig times with the starting pick: dirt 0.5 s, rock 1.4 s, hard rock 2.2 s, copper 0.6 s,
silver 1.5 s, gold 2.4 s, gems 2.6 s. Hard rock, gold and gems need the tier 1 pick (the camp sells it, P4): without it the
miner makes a "blocked" sound. Bedrock never breaks. Rebinding is in Options > Controls.

Holding dig with an enemy in front of you swings the pick at it instead (every 0.5 s; 1 damage plus the pick tier). With
several players on one keyboard the key blocks are: WASD + Space + E, arrows + Enter + RightShift, IJKL + U + O (dig and torch
last); a second and third player can use pads (left stick or d-pad, A or X to dig, B or Y for a torch).

## Camp, saves and codes

- **Camp** (`camp.js`): after every results screen the team sits at a fire. The shop sells six things (`upgrades.js`): pick
  tier (0 to 2) and pick speed, lamp oil and lamp radius, boots (walk speed) and torches per shift; each is a ladder whose price
  rises per level. The run autosaves on entering the camp and after each purchase.
- **Slots**: 3 save slots. New, continue and delete (delete asks to confirm). A corrupt save or one from a newer game shows a
  message that says what is wrong and what to do; it is never overwritten silently.
- **Cloud**: when the platform has a cloud, slots sync with it. The rule is in the Contracts.
- **Daily dig**: one shared seed per local calendar day. It is played once for the score; a run in daily mode does not write
  to the slots.
- **Seed codes**: a floor and seed as `XXXX-XXXX` (base32 with a check character). The results and camp screens copy it, the
  title pastes it. The clipboard is a session buffer inside the game: scripts cannot reach the system clipboard (FB-0016), so a
  code copied here is pasted here; typing a code from elsewhere works as usual.

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
- The mine is a **descent of three strata with three floors each** (nine floors): Topsoil, Crystal Caves and Magma Deep. Each
  has its own tileset, ambient light and looping music track. A shift that ends with the lift goes to the next floor (floor 1
  of the next stratum after floor 3); `dark` and `allDown` repeat the same floor with a new mine. Each shift is another mine
  (`run.seed + shiftNumber - 1`). Depth in the HUD is 30 m per stratum plus 10 m per floor. Deeper strata and floors are
  bigger, with more rock and richer ore (`STRATA` in `generator.js`).
- **Hearts**: every miner has 3 hearts per shift (shown next to its oil bar). At 0 the miner is **down**: it lies faded, does
  not move, dig or burn oil, and the shift ends without it. When every miner is down the shift ends with the outcome
  `allDown` (nothing is banked). Nobody can get up yet (revive is P3).
- **Hazards**: sealed pockets of **water** (every stratum) and **magma** (Magma Deep) spread over the floor once a
  miner digs into them; water slows a miner by half and drowns one who stays in it for 3.5 s, magma burns one on contact
  (0.5 s). **Cracked floor** brings the roof down on the 3 x 3 tiles around it 1.4 s after a miner steps on it; a miner inside
  goes down, a miner on the exit lift is safe. The floor tiles of a cave-in become rock.
- **Light**: besides the lamp, a team has 6 **torches** per shift to put down (they stay lit and reveal the tiles around them).
  Crystal walls (Crystal Caves) and magma glow. The engine draws at most 16 point lights, so `lights.js` keeps a pool and lights
  the sources nearest the miners. The mine is under **fog of war**: tiles a lamp or torch reaches in a straight line are
  clear, tiles seen once stay half dark, the rest is black, and enemies are drawn only on clear tiles.
- **Enemies**: **beetles** patrol, chase what their eyes find, wind up for 0.45 s and bite (a heart and 10 oil); **goblin
  thieves** take 25 percent of the ore the team carries and run to escape after 3 s (kill one and the ore drops); both follow
  the tunnels the miners dig. Magma Deep floor 3 holds the **Mole King**: it wakes when a miner comes near, slams the ground
  (a circle with a wind-up; it is stunned for 2.2 s afterwards, the time to hit it) and, in the second half of its health,
  charges. It has 10 hearts plus 4 per extra player, and the exit lift is jammed until it falls (`bossDefeated`).

## Layout

```
factoria.json              input actions, the title as main scene
scenes/                    menu, loading, shift, results, camp, test_mine
prefabs/                   miner, mole, enemy, ui/options, ui/pause
scripts/game/              the game: see Contracts (P4: upgrades, save, cloud, daily, seed_code, clipboard, floors, suggest)
scripts/                   menu kit (main_menu, pause_menu, loading, settings, ui/*), results.js and camp.js
scripts/ui/title_flow.js   the title's Continue, slots, delete confirmation, cloud sync, daily and code panel
tools/mine_preview.js      project.mine_preview: a mine as text
tests/                     the test files of the table below; helpers/ (mine, world, bot, camp) and fixtures/ (save_v1, save_v2)
assets/                    tiles_topsoil/crystal/magma.png, sprites.png, fog.png (+ src/make_atlases.py), music/*.wav (+ src/make_music.py), audio/*.wav
locales/en.json            every string of the UI
```

## Contracts (for P3 to P8)

Every module is plain JavaScript under `scripts/game/`, with its state in a module singleton (it survives scene loads; every
test file starts fresh). Import them with relative paths.

### Generator: `scripts/game/generator.js`

- `generate(seed, stratum = 0, floor = 1, opts?)` returns a `Mine` (plain data): `{ format, seed, stratum, floor, width,
  height, kinds[], start, exit, spawns[], moles[], rooms[], plugs[], oreCounts, oilCount, solvable, hash }`. `kinds` is
  row-major with row 0 at the top and holds the `K` constants of `tiles.js` (`FLOOR`, `DIRT`, `ROCK`, `HARD`, `BEDROCK`,
  `COPPER`, `SILVER`, `GOLD`, `GEM`, `LIFT_START`, `LIFT_EXIT`, `OIL`, and from P2 `WATER`, `MAGMA`, `SHAKY` (cracked floor) and
  `CRYSTAL`). `start`, `exit`, `spawns` (up to four free tiles next to the entry lift) and `moles` are `{ tx, ty }`. P2 adds
  `hazards` (sealed `flood` and `magma` pockets with their `door` and `volume`, open magma `pools`, `caveIn` cracked tiles),
  `enemies` (`{ kind, tx, ty }` of the beetles and thieves), `boss` (true on the Mole King's floor) and `crystals`. It uses only `rng.create` (seeded from seed, stratum and floor), never the
  world RNG or the clock: the same arguments give the same mine on every machine. `opts` is `{ width, height }`.
- `mineHash(mine)` returns an 8-hex-digit FNV-1a fingerprint of the format, seed, stratum, floor, size, tiles, lifts, spawns
  and moles; `mine.hash` is the hash at generation, and `mineHash(map.mine)` follows the digging. `tests/generator.test.js`
  pins the hash of seed 1234 floor 1 of each stratum (`2226b82f` Topsoil, `e4c8bb00` Crystal Caves, `1191412d` Magma Deep) and of
  the boss floor (`c9c03ec9`), with `MINE_FORMAT` 2: change the algorithm on purpose, raise `MINE_FORMAT` and update the test.
- `exitReachable(mine, tier)` says whether the exit can be reached digging with a pick of that tier; `generate` guarantees it
  for tier 0 (`mine.solvable`). `STRATA` (`topsoil`, `crystalCaves`, `magmaDeep`) and `stratumInfo(n)` hold, per stratum, the
  floors, the rock share, the ore weights, the hazards, enemies and crystals per floor, the ambient light and the music track;
  `isBossFloor(stratum, floor)` names the Mole King's floor.
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

`add({ device, name, color })`, `remove(id)`, `get(id)`, `all()`, `count()`, `alive()`, `hurt(id, amount, cause)`, `setState(id, "active" |
"lift" | "down", cause)`, `ensureOne()`, `clear()`, `MAX_PLAYERS` (4), `PLAYER_COLORS`, `KEY_SCHEMES`. A player is `{ id, name, device, color,
state, hp, invulnerable }` (`MAX_HP` is 3). The shift spawns one miner per registered player (`prefabs/miner.prefab.json`, prop `playerId`) and the HUD shows one
oil bar each. `device` decides which input moves the miner (`scripts/game/miner_input.js`): `{ kind: "any" }` (the project's
actions: keyboard and every pad; one player only, the title's Play uses it), `{ kind: "keys", scheme: "wasd" | "arrows" | "ijkl" }`
or `{ kind: "pad", index }` (left stick or d-pad, A or X to dig, B or Y for a torch). `tests/input.test.js` drives two keyboard players and a second pad at
once. `setState` emits `playerState` and, for `"down"`, `playerDown`; a miner that is `down` does not move, dig or burn oil and
the shift's end check ignores it. `hurt` takes hearts and sets `down` at 0 (`playerHurt` is emitted); the hazards set `down`
directly with the cause "drowned", "burned" or "caveIn". There is no join screen and no revive yet (P3).

### Game events: `scripts/game/events.js`

A synchronous bus in a module singleton (it outlives scenes, unlike scene-bound listeners): `on(name, fn)` returns the
unsubscribe function, `emit(name, data)`, `count(name)`, `emitted(name)`, `clear()`, `history`. An unknown name throws with a
"did you mean". `EVENTS` documents every name and its data. P1 emits `shiftStarted`, `dug`, `digBlocked`, `orePicked`,
`oilPicked`, `lampLow`, `lampOut`, `liftReached`, `moleRescued`, `shiftEnded`, `playerAdded`, `playerRemoved`, `playerState`,
`playerDown` and `tileChanged`. P2 adds `hazardTriggered` (`kind` flood, magma or caveIn; `phase` start, spread, impact or hit),
`playerHurt`, `torchPlaced`, `enemyHit`, `enemyDefeated`, `oreStolen`, `oreRecovered`, `thiefEscaped`, `bossStarted`,
`bossDefeated` and `exitJammed`; `shiftEnded` can now carry the outcome `allDown`. P4 emits `upgradeBought` (`upgrade`, `level`,
`cost`, `cash`) and `cashChanged` (`cash`, `delta`, `cause`: a shift's bank or an upgrade). A behaviour that subscribes unsubscribes in `onDestroy`; `startRun` clears the bus.

### Run state: `scripts/game/run_state.js`

`run` is `{ active, seed, mode, dailyKey, slot, stratum, floor, shiftNumber, cash, upgrades, ore, lamps, torches, molesRescued,
molesTotal, shiftTime, playTime, bestDepth, shiftSeed, inShift, lastShift }`.

**Contract with P5 (online):** a daily dig sets `run.mode = "daily"` and `run.dailyKey = "YYYY-MM-DD"` (the local date from
`game.today()`); every other run has `run.mode = "normal"` and `run.dailyKey = null`. `run.slot` is 1 to 3, or null for a daily
dig. Read these to tag a score or a board. `mineSeed(...)` and `depthOf(...)` give a floor's seed and its depth in metres. `upgrades` is `{ pickTier, pickSpeed, lampOil, lampRadius, walkSpeed, torches }` (`BASE_UPGRADES`); the miner
already reads every one, the camp changes them (`upgrades.js`). `lamps` maps a player id to `{ oil, max, out, low }` (`lampOf(id)`). Functions:
`startRun({ seed, stratum, floor })` (the title's Play calls it; it also clears the events bus and resets the music),
`beginShift()` (the shift scene calls it: resets ore, lamps, hearts, torches, clock and moles, and returns the mine seed), `addOre`,
`totalOre`, `oreValue`, `endShift("lift" | "dark" | "allDown")` (banks the ore value for `lift` only and builds `run.lastShift`,
which also holds the stratum and floor played), `snapshot()` and `restore(data)` (what a save holds).

### Floors and what comes next: `scripts/game/progression.js`

The one place that knows the order of the floors. `plan(summary)` (pure; the `run.lastShift` summary in) returns `{ kind:
"next" | "retry" | "victory", stratum, floor, newStratum, boss }`: a `lift` goes to the next floor (floor 1 of the next stratum after
floor 3), `dark` and `allDown` retry the same floor, and a `lift` on the boss floor is the victory. `nextScene(plan)` is the
scene that follows the results: the camp (`CAMP_SCENE`), or the title (`TITLE_SCENE`) after a daily victory. `go(plan)` sets `run.stratum` and `run.floor` (a victory starts a fresh run) and loads the scene
through the loading screen. `results.js` is its only caller.

### Hazards: `scripts/game/hazards.js`

`new Hazards(map)` (the shift makes one) reads the tiles of the map, so a mine written in `mine_ascii.js` behaves like a
generated one (`w` water, `M` magma, `x` cracked floor). `update(dt)`, `speedFactor(tile)` (0.5 in water), `dispose()`. Constants
`DROWN_TIME`, `BURN_TIME`, `WATER_WAVE`, `MAGMA_WAVE`, `CAVE_WARNING`, `CAVE_DAMAGE`. Events: `hazardTriggered` and
`playerDown` with the cause. The shift script (not the hazards) ends the shift with `allDown` once every miner is down.

### Light and fog: `scripts/game/lights.js`, `scripts/game/fog.js`

`new Lights(map)`: `placeTorch(playerId)` (true when put down; uses one of `run.torches`; a torch needs a free floor tile that is not
water, magma or cracked floor and not already holding one), `sources`, `lit`, `update(dt)`. The Light2D pool is at most 16 minus
one per miner (`ENGINE_LIGHT_CAP`); a test counts the active `Light2D` entities because `renderStats().lights` does not count them.
`new Fog(map)` is a three-state map (`UNSEEN`, `SEEN`, `VISIBLE`) drawn on its own Tilemap: `stateAt(tx, ty)`, `isVisible`,
`seen()`, `update(dt, { torches })`. Walls block sight, and digging opens it at once. `TORCH_RADIUS` is 4.5 tiles.

### Pathfinding and behaviour trees: `scripts/game/pathfinding.js`, `scripts/game/behavior_tree.js`

Both are generic (nothing in them knows this game) so another game can copy them. `navFor(map)` gives the shared `NavGrid`
whose `version` goes up when a tile changes; `findPath(from, to, { dig: { tier, cost }, dangerCost, maxNodes })` is an A* over
the tiles that can dig through what the pick can break and avoids water, magma and cracked floor unless `dangerCost` is finite;
`PathFollower` walks a path and re-plans when `version` changed; `lineOfSight(map, a, b)`; `NavGrid.reachable(from, radius)`. `Tree` runs a
description built from `sequence`, `selector`, `condition`, `action`, `wait`, `cooldown`, `inverter` and `succeeder` against a
blackboard (the header documents the one catch: a RUNNING sequence resumes without asking its conditions again).

### Enemies: `scripts/game/enemy.js`, `scripts/game/enemy_brains.js`, `prefabs/enemy.prefab.json`

The `Enemy` behaviour (prop `kind`: `beetle`, `thief` or `king`; `tx`, `ty`) is the body and the blackboard; `beetleBrain()`,
`thiefBrain()` and `kingBrain()` are the trees and `STATS` holds every number (hp, speed, ranges, wind-ups). Miners hit enemies
through `Enemy.hit(damage, from, by)` (a swing is `swingDamage(tier)`; `from` is where the blow came from), which emits `enemyHit` and `enemyDefeated`. The King's hp is 10
plus 4 per extra player; while it lives a miner on the exit lift only emits `exitJammed` and does not count as arrived. `actors.js` lists the
miners in play (`miners()`, `nearestMiner(x, y)`) for the hazards, enemies, lights and fog.

### Music: `scripts/game/music.js`

All music goes through here (P6 adds layers). `play(stratum)` starts the stratum's looping track with a fade-in and returns
whether the track differs from the last one; the shift calls it at every start because a scene load stops the audio.
`current()`, `forStratum(n)`, `reset()`.

### Camp and upgrades: `scripts/game/upgrades.js`, `scripts/camp.js`

`SHOP` (six ladders), `ITEMS`, `maxLevel(id)`, `levelOf(id)`, `offer(id)` (`{ level, value, cost }` or null at the maximum),
`buy(id)` (pays, applies, emits `cashChanged` then `upgradeBought`; refuses with `{ ok: false, reason: "max" | "cash", message,
hint }`), `upgradesAt(levels)`. An unknown id throws with a "did you mean". `run_state.addCash(delta, cause)` is the only way cash
changes.

### Saves: `scripts/game/save.js`

Format 2, in `storage` keys `burrow.slot.1` to `burrow.slot.3` (`burrow.lastSlot` remembers the last one). A save holds `{ format,
seed, mode, stratum, floor, shiftNumber, cash, upgrades, playTime, bestDepth, savedAt... }` (see `toSave`). Functions: `migrate(data)`
(v1 to v2, `{ ok, data }` or `{ ok: false, message, hint }` for a missing format, a newer one or a damaged file), `readSlot(n)`,
`slots()` (the three summaries for the title), `storageDamaged()`, `lastSlot()`, `importLegacy()` (the P1 key `burrow.save` becomes
slot 1 once), `save()`, `newRun(slot, opts)`, `continueSlot(slot)`, `load`, `apply`, `erase(slot)`. `tests/fixtures/save_v1.json` and
`save_v2.json` pin both formats; to change the format raise `SAVE_FORMAT`, add a step to `migrate` and a fixture.

### Cloud saves: `scripts/game/cloud.js`

`syncSlot(n, { allowDownload })`, `syncAll()`, `removeSlot(n)`, `available()`. Each slot is the cloud key `slot<N>`. The platform gives no
modified time (FB-0018), so the game keeps the revision it last synced (`burrow.cloudBase.N`): only local changed -> upload; only
cloud changed -> download (only when `allowDownload`, which the title sets and the camp does not, so the camp is upload-only); both
changed -> **conflict**: the copy with more progress (deeper floor, then more shifts, then more play time) wins and the loser is kept
in `burrow.backup.N` and never deleted. Answers: `unavailable`, `none`, `inSync`, `uploaded`, `downloaded`, `conflict`, `waiting`,
`blocked`, `error`. The local slot is re-read after the cloud answers, so a save made meanwhile is not lost. Tested on the fake store.

### Daily dig: `scripts/game/daily.js`

`todayKey()`, `isKey(s)`, `seedFor(key)` (FNV-1a of `burrow-brigade/daily/<key>`), `status()`, `start()`, `noteShift(...)`. The key
is the local date: `game.today()` has no time of day, so UTC cannot be derived (FB-0017). Played days are in `burrow.daily`.

### Seed codes: `scripts/game/seed_code.js`, `scripts/game/clipboard.js`

`encode(floorIndex, seed)`, `decode(text)` (a result or a teaching error with a "did you mean"), `normalize(text)`, `ALPHABET`,
`EXAMPLE`. 4 bits of floor index and 31 bits of seed as 7 characters plus a check character, shown `XXXX-XXXX`; look-alike
characters (O/0, I/1) are accepted. `clipboard.js`: `copy`, `paste`, `system`, `useSystem({ write, read })`, `reset`. It is a session
buffer today; if the engine gets a clipboard, plug it in with `useSystem`.

## Tests

`factoria test` runs `tests/*.test.js` headless:

| File | What it checks |
|---|---|
| `generator.test.js` | the same seed gives the same mine and pinned hashes (every stratum and the boss floor), other seed / stratum / floor differ, borders and a reachable exit, hazards, crystals and enemies per stratum, the text format |
| `mine.test.js` | the map, digging dirt / rock / hard rock / bedrock, the pick tier, ore pickup, oil drain, warning and darkness, the oil can, the lift ending the shift, the moles |
| `input.test.js` | the keyboard and a gamepad each drive the miner, two keyboard players and a second pad each move only their own miner, the four-player registry |
| `flow.test.js` | title -> loading -> shift -> results -> another shift or title, ore banked or lost, leaving a scene mid-wait, the pause menu, the save, the events bus |
| `recipe.test.js` | the menu kit's gamepad-only options test (three d-pad presses now: the title has Continue and Daily) |
| `upgrades.test.js` | the ladders, buying with enough and short cash, the maximum, events, the camp with pad, keyboard and mouse, upgrades reaching the miner |
| `saves.test.js` | format 2, v1 to v2 migration from fixtures, corrupt and newer saves, three slots, Continue, delete with confirmation |
| `cloud.test.js` | upload, download, conflict and backup, unavailable and failing stores, a save made while waiting |
| `daily.test.js` | the same seed per day, played once, `run.mode` and `run.dailyKey`, no slot written |
| `seed_code.test.js` | encode and decode round trips, check character, look-alikes, copy at the camp and results, paste at the title |
| `hazards.test.js` | a flood sealed then spreading, slow water and drowning, magma burning, a cave-in warning then impact, a miner on the lift spared, `allDown` with one and with three players, the results screen |
| `light.test.js` | the cap of 16 Light2D with four players, six torches and a crystal hall, the nearest sources win the pool, torch rules and the T key, fog states, walls blocking sight and digging opening it |
| `pathfinding.test.js` | the A* (dig cost, danger tiles, off the map, far), re-planning after digging, the path follower, line of sight |
| `behavior_tree.test.js` | every node of the tree, including the running-sequence catch |
| `enemies.test.js` | the three brains driven by a fake blackboard, then a beetle, a chase through a tunnel dug a moment ago, the thief stealing, fleeing, escaping or being killed, the Mole King waking, slamming, charging, scaling with players and jamming the lift |
| `strata.test.js` | the look and music of each stratum, the descent through the results over nine floors, victory then a new run, retry after `dark` and `allDown`, leaving before the results |
| `bot.test.js` | a bot that presses keys and pushes sticks clears one floor of every stratum and the boss floor, alone and with four players on four devices, deterministically |

## Assets and credits

| File | Source | Licence |
|---|---|---|
| `assets/tiles_topsoil.png`, `assets/tiles_crystal.png`, `assets/tiles_magma.png`, `assets/sprites.png`, `assets/fog.png` | Kenney, [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon) and [Roguelike Caves & Dungeons](https://kenney.nl/assets/roguelike-caves-dungeons), cut and re-packed by `assets/src/make_atlases.py`; the mole, the arrows, the cracks, the beetle, the thief, the King and the fog are drawn or recoloured by that script (a stratum's tileset is the same tiles in other colours) | CC0 |
| `assets/music/*.wav` | one looping track per stratum, synthesised by `assets/src/make_music.py` (no sample taken from anywhere) | CC0 |
| `assets/audio/*.wav` | made with `assets.synth_sound` (presets footstep, hit, coin, pickup, error, powerup, whoosh, click, growl, explosion, splash, laser) | CC0 |

`assets.json` records the provenance of each file. The engine gaps found while building P1, P2 and P4 are in `ENGINE_FEEDBACK.json`.

## Status

| Package | What | State |
|---|---|---|
| P1 | The miner, digging and the mine | done |
| P2 | World and enemies: the three strata and their hazards, torches and crystals, enemies that chase through the dug tunnels, music per stratum, a bot that clears floors | done |
| P3 | Couch co-op: join screen, per-player devices and bindings, shared then split camera, revive, a pad unplugged, Remote Play Together | to do |
| P4 | Camp, progress and saves: the upgrades shop, Continue, 3 versioned save slots with migration, cloud saves, the daily dig, seed codes | done |
| P5 | Steam and online: achievements, stats and boards, rich presence, Steam Deck, glyphs, news, remote balance, opt-in analytics | to do |
| P6 | Sound, options and accessibility: music layers, bus effects, captions, display options, game speed, reduced flashing | to do |
| P7 | Shipping: icon and store art, store texts, screenshots and trailer, desktop exports, budgets, SHIPPING.md | to do |
| P8 | Languages: Russian and Thai, every screen at 100 % and 200 % text | to do |
