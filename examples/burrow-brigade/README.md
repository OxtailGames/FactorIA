# Burrow Brigade

A top-down 2D mining game for up to four players on one screen (couch co-op), for desktop first and Steam. Dig dirt and
rock with a pick, take the ore, keep your lamp alight with oil cans, free the moles trapped in the rock, and ride the lift
up before the dark gets you. It is the third reference game of the FactorIA engine (milestone M28), built in eight
packages (P1 to P8). This is package P5 (Steam and online) on top of P1 (the miner, digging and the mine) and P2 (the world and its enemies). The later packages build on the
contracts below.

## Run

```bash
factoria validate
factoria run                      # windowed
factoria run --headless --frames 120 --screenshot-at 119
factoria test                     # headless tests
factoria call project.mine_preview '{"seed":1234}'    # a generated mine as text, with its hash
```

The title (`scenes/menu.scene.json`) goes through Play and `scenes/loading.scene.json` to a shift
(`scenes/shift.scene.json`, a generated mine), then to the results (`scenes/results.scene.json`), then the next floor, the
same floor again or the title (`scripts/game/progression.js` decides which). `scenes/test_mine.scene.json` is a small handmade mine the tests use (its layout is in `tests/helpers/mine.js`);
it is not in the player's flow.

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Walk (4 directions) | WASD / arrows | left stick or d-pad |
| Dig (hold, facing a tile) | Space / J | A or X |
| Place a torch | T | B or Y |
| Pause | Escape / P | Start |

You dig the tile you face: walk into it to turn towards it, then hold dig. A crack grows on the tile while you dig and
fills back in if you let go. Dig times with the starting pick: dirt 0.5 s, rock 1.4 s, hard rock 2.2 s, copper 0.6 s,
silver 1.5 s, gold 2.4 s, gems 2.6 s. Hard rock, gold and gems need the tier 1 pick (the camp sells it, P4): without it the
miner makes a "blocked" sound. Bedrock never breaks. Rebinding is in Options > Controls.

Holding dig with an enemy in front of you swings the pick at it instead (every 0.5 s; 1 damage plus the pick tier). With
several players on one keyboard the key blocks are: WASD + Space + E, arrows + Enter + RightShift, IJKL + U + O (dig and torch
last); a second and third player can use pads (left stick or d-pad, A or X to dig, B or Y for a torch).

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
scenes/                    menu, loading, shift, results, test_mine
prefabs/                   miner, mole, enemy, ui/options, ui/pause
scripts/game/              the game: see Contracts
scripts/                   menu kit (main_menu, pause_menu, loading, settings, ui/*) and results.js
tools/mine_preview.js      project.mine_preview: a mine as text
tests/                     the test files of the table below; helpers/mine.js, world.js, bot.js and online.js (a fake game server); fixtures/news.json and balance.json
assets/                    tiles_topsoil/crystal/magma.png, sprites.png, fog.png (+ src/make_atlases.py), music/*.wav (+ src/make_music.py), audio/*.wav,
                           achievements/*.png and glyphs/<family>/*.png (+ src/make_online_art.py)
locales/en.json            every string of the UI (P5: achievements, stats, boards, presence, online, textEntry)
scripts/title_online.js    the title's online parts; scripts/ui/boards.js the boards screen
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
`bossDefeated` and `exitJammed`; `shiftEnded` can now carry the outcome `allDown`. `upgradeBought` and `cashChanged` (P4) are
reserved: they can be subscribed to but nothing emits them yet. A behaviour that subscribes unsubscribes in `onDestroy`; `startRun` clears the bus.

### Run state: `scripts/game/run_state.js`

`run` is `{ active, seed, stratum, floor, shiftNumber, cash, upgrades, ore, lamps, torches, molesRescued, molesTotal,
shiftTime, inShift, lastShift }`. `upgrades` is `{ pickTier, pickSpeed, lampOil, lampRadius, walkSpeed, torches }` (`BASE_UPGRADES`); the miner
already reads every one, the camp changes them (P4). `lamps` maps a player id to `{ oil, max, out, low }` (`lampOf(id)`). Functions:
`startRun({ seed, stratum, floor })` (the title's Play calls it; it also clears the events bus and resets the music),
`beginShift()` (the shift scene calls it: resets ore, lamps, hearts, torches, clock and moles, and returns the mine seed), `addOre`,
`totalOre`, `oreValue`, `endShift("lift" | "dark" | "allDown")` (banks the ore value for `lift` only and builds `run.lastShift`,
which also holds the stratum and floor played), `snapshot()` and `restore(data)` (what a save holds).

### Floors and what comes next: `scripts/game/progression.js`

The one place that knows the order of the floors. `plan(summary)` (pure; the `run.lastShift` summary in) returns `{ kind:
"next" | "retry" | "victory", stratum, floor, newStratum, boss }`: a `lift` goes to the next floor (floor 1 of the next stratum after
floor 3), `dark` and `allDown` retry the same floor, and a `lift` on the boss floor is the victory. `nextScene(plan)` is the
scene that follows the results: today the shift scene. **P4 puts the camp between the results and the next floor by changing
`nextScene` and nothing else.** `go(plan)` sets `run.stratum` and `run.floor` (a victory starts a fresh run) and loads the scene
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

### Save stub: `scripts/game/save.js`

`save()` writes `{ format: SAVE_FORMAT, seed, stratum, floor, shiftNumber, cash, upgrades }` to `storage` key `burrow.save` when a
shift ends; `load()`, `apply()` (puts a save into the run state) and `erase()`. `migrate(data)` is where a later format is
brought up to date: today it only checks the `format` field and answers `{ ok: false, message, hint }` for a file with no format
or a newer one. Nothing reads the save at the title yet (P4 adds Continue).

### Achievements and stats: `scripts/game/trophies.js`

Driven only by the events bus; the catalog (ids, `nameKey`, `descriptionKey`, the Steam ids `ACH_*` and `Num*`) is `factoria.json`
`"platform"` with app id 480 for tests and the Steam backend. `start()` (idempotent; `services.start()` calls it) subscribes with
`events.keep`, `stop()`, `idle()` (a Promise: every store call made so far is answered), `list()` for a screen and `statValues()`.
Stats are counted for ever by the store: `oreDug` (`orePicked`, one per piece), `molesRescued` (`moleRescued`), `floorsCleared`
(`shiftEnded` with outcome `lift`), `enemiesDefeated` (`enemyDefeated`). Achievements, with a 64 px CC0 icon each:

| Id | Unlocks when |
|---|---|
| `first_ore` | `oreDug` reaches 1 |
| `mole_rescuer` | `molesRescued` reaches 10 (over all runs) |
| `mole_king` | `bossDefeated` |
| `bright_stratum` | the last floor of a stratum ends on the lift and no `lampOut` happened in that stratum (a retry of a floor after a bad shift does not reset the count) |
| `full_house` | a shift with 4 players ends on the lift |
| `bug_squasher` | `enemiesDefeated` reaches 25 |

A store that is missing, signed out or failing never reaches the player: the calls are best effort (a warning in the log).

### Leaderboards: `scripts/game/boards.js`

Two boards in the catalog: `best_run_cash` (all time, descending) and `daily_run_cash` (daily, descending). The score is the cash
banked over the run so far: each shift that ends on the lift adds its banked cash and posts the sum (`dark` and `allDown` post
nothing). **Contract with P4**: a daily-dig run sets `run.mode = "daily"` and `run.dailyKey = "YYYY-MM-DD"` (the UTC date of the
daily seed); every other run `run.mode = "normal"` and `run.dailyKey = null` (a missing `run.mode` counts as normal). The daily
board takes the score only when `run.dailyKey` is within one day of `game.today().iso`: the engine picks the day of a daily
board from the LOCAL date and cannot be told another (ENGINE_FEEDBACK), so a run keyed by a UTC date far from the local one is
skipped and `status().lastPost.daily` says `{ skipped: "otherDay" }`. Functions: `start`, `stop`, `idle`, `top(board, count = 10)`
(rows `{ rank, name, score, isPlayer }`; `[]` when the store has no boards), `status()`, `BOARDS`, `modeOf`, `dailyKeyOf`,
`dailyOpen`. `boardPosted { board, score, period }` is emitted after a post and `achievementUnlocked { id, name }` after an unlock.
The boards screen (`scripts/ui/boards.js`, the Boards button of the title) has the tabs All time, Daily dig and Trophies and works
with a pad (ui_up and ui_down scroll, ui_cancel goes back); an answer that arrives after it closed or after the scene changed is dropped.

### Services, presence and Steam Deck: `services.js`, `presence.js`, `deck.js`, `glyphs.js`, `text_entry.js`

`services.start()` (idempotent; the title and the pause menu call it) starts trophies, boards, presence, balance and analytics;
`stop()`, `isStarted()`, `idle()`. `events.keep(name, fn)` subscribes like `on` but survives `startRun` (which clears the bus);
the services use it.

- **Rich presence** (`presence.js`): the text comes from the locale keys `presence.*` (plural by miners), the data carries
  `steam_display` (`#Menu`, `#Boards`, `#Digging`, `#Boss`, `#Results`) plus `stratum`, `floor`, `miners`. `describe(state)` is pure,
  `set(state)` sends only when the text changed, `forget()` makes the next one go, `current()`, `idle()`. P8's languages only
  need to add the `presence.*` strings.
- **Glyphs** (`glyphs.js`): `glyph(binding, pad)` returns `{ family, label, icon }` for `xbox`, `playstation`, `nintendo` or
  `steamdeck` (a generic pad counts as Xbox) with a 64 px picture under `assets/glyphs/<family>/`; `prompt(action, pad, device)`
  picks the pad glyph, the key or the mouse button by `input.lastDevice`; `promptText(action)` is the label alone. The title's
  `hints` row uses it.
- **Steam Deck** (`deck.js`): `isDeck()` is true while a connected pad is of type `steamdeck` (the engine has no other way to
  tell), `keyboardKind()` is `steam` (Steam's keyboard through `input.platformKeyboard`), `onscreen`, `touch` or `keyboard`, `fit(w, h)`
  is where the 1280x720 design lands in a window (1280x800: scale 1 and bars of 40 above and below; the UI is anchored, so
  nothing is cut), and `watchLife({ pause, resumed })` listens to suspend (pause, flush analytics) and resume (send the presence
  again). The pause menu uses it, so waking the Deck lands on the pause menu, never in a live shift.
- **Text entry for P4's seed-code field** (`text_entry.js`): `bind(fieldId, { maxLength, alphabet, onChange, onSubmit })` cleans
  what is typed in a `TextField` to `CODE_ALPHABET` (capitals and digits without 0, O, 1, I) and returns the unsubscribe function;
  `focus(fieldId)`; `normalize(text, opts)`; `hint(action)` is the localized line that tells how to type on this device
  (`textEntry.keyboard` / `pad` / `deck`). On a Deck or a pad, focusing the field and pressing the button opens Steam's or the
  system's on-screen keyboard through the engine's `input.platformKeyboard`.

### Online: `online.js`, `news.js`, `balance.js`, `analytics.js`

The engine has no HTTP API, so everything that talks to a server goes through one seam: `online.request(method, path, body)`
(never throws; resolves `{ ok: true, data }` or `{ ok: false, code, message }`). The default transport is **offline** (always
fails), `setTransport(t)` (returns the old one) plugs in a real one: `{ name, request(method, path, body) -> Promise }`;
tests use `fakeServer` of `tests/helpers/online.js`. Paths (`PATHS`): `/v1/news.json`, `/v1/balance.json`, `/v1/events`. No test
and no default build touches a network.

- **News** (`news.js`): `{ "version": 1, "items": [{ "id", "date": "YYYY-MM-DD", "title", "body" }] }` where `title` and `body`
  are a string or `{ "en": "...", "ru": "..." }` (the language of the game, else `en`). `parse` drops items with no id or title, strips control characters, cuts the
  title at 48 characters and the body at 160, sorts newest first and keeps three. `refresh()` resolves
  `{ source: "server" | "cache" | "none", items }` and remembers the last good answer in storage (`burrow.news`); the title shows
  the newest item at once from that memory and again when the server answers (if the title is still there).
- **Remote balance** (`balance.js`): `{ "version": 1, "values": { "beetle.hp": 4 } }`. Each value is checked against `RANGES`
  (range, whole number or not); a bad value is rejected with a reason and a hint (unknown keys get a "did you mean") and the
  rest still apply; `king.chargeMinDist` above `king.chargeMaxDist` rejects both. Values change `STATS` of `enemy_brains.js` and `TUNING`
  of `hazards.js` in place and only between shifts (held while one runs, put in at `shiftEnded`). Nothing is cached: offline
  or with a bad file the shipped numbers stay (`refresh()` says `source: "offline"` or `"invalid"`). `apply(values)`, `reset()`,
  `defaults()`, `current()`, `flush()`. The keys:

| Key | Default | Range | What |
|---|---|---|---|
| `beetle.hp` | 3 | 1 to 30 (whole) | hearts of a beetle |
| `beetle.sight` | 112 | 16 to 600 | how far a beetle sees a miner (units) |
| `beetle.patrolSpeed` | 26 | 1 to 400 | walking speed while patrolling |
| `beetle.chaseSpeed` | 52 | 1 to 400 | speed while chasing |
| `beetle.biteRange` | 15 | 4 to 64 | distance at which it starts to bite |
| `beetle.biteWindup` | 0.45 | 0.1 to 5 | seconds between starting to bite and the bite |
| `beetle.biteCooldown` | 1.4 | 0.2 to 20 | seconds before it can bite again |
| `beetle.biteOil` | 10 | 0 to 100 | oil a bite takes from the lamp |
| `thief.hp` | 2 | 1 to 30 (whole) | hearts of a goblin thief |
| `thief.sight` | 128 | 16 to 600 | how far it sees |
| `thief.wanderSpeed` | 30 | 1 to 400 | speed while wandering |
| `thief.approachSpeed` | 58 | 1 to 400 | speed while going for the ore |
| `thief.fleeSpeed` | 62 | 1 to 400 | speed while running away |
| `thief.stealRange` | 14 | 4 to 64 | distance at which it steals |
| `thief.stealShare` | 0.25 | 0 to 1 | share of the carried ore it takes (0 to 1) |
| `thief.escapeAfter` | 3 | 0.5 to 30 | seconds after the steal before it leaves the mine |
| `thief.escapeDistance` | 176 | 32 to 600 | distance from the nearest miner at which a thief that has stolen counts as far enough to escape |
| `king.hp` | 10 | 1 to 200 (whole) | hearts of the Mole King with one miner |
| `king.hpPerExtraPlayer` | 4 | 0 to 50 (whole) | hearts added per extra miner |
| `king.sight` | 144 | 16 to 600 | how far it sees |
| `king.wakeRange` | 144 | 16 to 600 | distance at which a miner wakes it |
| `king.chaseSpeed` | 30 | 1 to 400 | walking speed |
| `king.slamTrigger` | 56 | 8 to 200 | distance at which it starts a slam |
| `king.slamRadius` | 42 | 8 to 200 | radius of the slam circle |
| `king.slamWindup` | 0.9 | 0.1 to 5 | seconds of warning before the slam |
| `king.slamStun` | 2.2 | 0.1 to 10 | seconds it is stunned after a slam |
| `king.slamCooldown` | 3.5 | 0.5 to 30 | seconds between slams |
| `king.chargeMinDist` | 64 | 8 to 600 | nearest distance for a charge (must not exceed chargeMaxDist) |
| `king.chargeMaxDist` | 176 | 8 to 600 | farthest distance for a charge |
| `king.chargeWindup` | 0.6 | 0.1 to 5 | seconds of warning before a charge |
| `king.chargeSpeed` | 170 | 20 to 400 | speed of the charge |
| `king.chargeLength` | 150 | 16 to 600 | how far a charge runs |
| `king.chargeStun` | 1.2 | 0.1 to 10 | seconds it is stunned after a charge |
| `king.chargeCooldown` | 6 | 0.5 to 30 | seconds between charges |
| `king.chargeHit` | 14 | 4 to 64 | reach of the charge's hit |
| `hazards.waterWave` | 1.2 | 0.2 to 10 | seconds between steps of a spreading flood |
| `hazards.magmaWave` | 2.2 | 0.2 to 10 | seconds between steps of spreading magma |
| `hazards.waveTiles` | 3 | 1 to 12 (whole) | tiles the flood or magma front gains each step |
| `hazards.drownTime` | 3.5 | 0.5 to 30 | seconds in water before a miner drowns |
| `hazards.burnTime` | 0.5 | 0.1 to 10 | seconds on magma before it burns |
| `hazards.waterSlow` | 0.5 | 0.1 to 1 | speed factor in water (0.5 = half) |
| `hazards.caveWarning` | 1.4 | 0.5 to 10 | seconds between stepping on cracked floor and the roof falling |

- **Analytics** (`analytics.js`): OFF by default. The title shows a card in its top-right corner (`consent`, "Anonymous play
  statistics": Yes, send / No, thanks) at every launch until one is pressed; it does not take the focus or hide the menu, and
  ignoring it is a no (a modal prompt hid the menu from the pad-only tests). Options has the same switch (`analytics` toggle).
  Only after a yes: `floor_reached { stratum, floor, players }` at each shift start, `shift_ended { outcome, stratum, floor,
  players, banked, seconds }` at each end (then the queue is sent), and `quit { shifts }` from the Quit button of the title (the
  engine has no window-close event). No id, name, device or seed is sent. A failed send keeps up to 50 events for the next one; saying no
  throws the queue away. `consent()`, `asked()`, `enabled()`, `setConsent(bool)`, `record` (private), `queued()`, `flush()`, `quit()`.

## Tests

`factoria test` runs `tests/*.test.js` headless:

| File | What it checks |
|---|---|
| `generator.test.js` | the same seed gives the same mine and pinned hashes (every stratum and the boss floor), other seed / stratum / floor differ, borders and a reachable exit, hazards, crystals and enemies per stratum, the text format |
| `mine.test.js` | the map, digging dirt / rock / hard rock / bedrock, the pick tier, ore pickup, oil drain, warning and darkness, the oil can, the lift ending the shift, the moles |
| `input.test.js` | the keyboard and a gamepad each drive the miner, two keyboard players and a second pad each move only their own miner, the four-player registry |
| `flow.test.js` | title -> loading -> shift -> results -> another shift or title, ore banked or lost, leaving a scene mid-wait, the pause menu, the save, the events bus |
| `recipe.test.js` | the menu kit's gamepad-only options test |
| `hazards.test.js` | a flood sealed then spreading, slow water and drowning, magma burning, a cave-in warning then impact, a miner on the lift spared, `allDown` with one and with three players, the results screen |
| `light.test.js` | the cap of 16 Light2D with four players, six torches and a crystal hall, the nearest sources win the pool, torch rules and the T key, fog states, walls blocking sight and digging opening it |
| `pathfinding.test.js` | the A* (dig cost, danger tiles, off the map, far), re-planning after digging, the path follower, line of sight |
| `behavior_tree.test.js` | every node of the tree, including the running-sequence catch |
| `enemies.test.js` | the three brains driven by a fake blackboard, then a beetle, a chase through a tunnel dug a moment ago, the thief stealing, fleeing, escaping or being killed, the Mole King waking, slamming, charging, scaling with players and jamming the lift |
| `strata.test.js` | the look and music of each stratum, the descent through the results over nine floors, victory then a new run, retry after `dark` and `allDown`, leaving before the results |
| `bot.test.js` | a bot that presses keys and pushes sticks clears one floor of every stratum and the boss floor, alone and with four players on four devices, deterministically |
| `trophies.test.js` | each achievement unlocking from events, the four stats, no double unlock, a stratum cleared with and without a lamp going out, a store that is not there |
| `boards.test.js` | cumulative run cash on the all-time board, `dark` and `allDown` posting nothing, a daily dig on both boards, a new day, the UTC key a day or two off, a missing `run.mode`, an empty store |
| `presence.test.js` | the text with one and many miners, boss, results, menu and boards, the `steam_display` tokens, no repeated text |
| `glyphs.test.js` | `setType` for each family, the Deck's L1/R1, the keyboard fallback, every picture exists |
| `news.test.js` | the fixture parsed, the cap and the order, dropped items, the language object, the cache offline |
| `balance.test.js` | values applied, out-of-range, wrong type and unknown keys rejected with hints, held during a shift, the offline fallback, `reset` |
| `analytics.test.js` | nothing queued or sent without consent, the events after a yes, quit, a failed send, revoking |
| `deck.test.js` | Deck detection, the 1280x800 fit, suspend and resume, the text-entry helper |
| `online_ui.test.js` | the title's news, the consent card, the hints row, leaving the title mid-request, the boards screen with the mouse and a pad, the Options switch |

## Assets and credits

| File | Source | Licence |
|---|---|---|
| `assets/tiles_topsoil.png`, `assets/tiles_crystal.png`, `assets/tiles_magma.png`, `assets/sprites.png`, `assets/fog.png` | Kenney, [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon) and [Roguelike Caves & Dungeons](https://kenney.nl/assets/roguelike-caves-dungeons), cut and re-packed by `assets/src/make_atlases.py`; the mole, the arrows, the cracks, the beetle, the thief, the King and the fog are drawn or recoloured by that script (a stratum's tileset is the same tiles in other colours) | CC0 |
| `assets/music/*.wav` | one looping track per stratum, synthesised by `assets/src/make_music.py` (no sample taken from anywhere) | CC0 |
| `assets/achievements/*.png`, `assets/glyphs/<xbox, playstation, nintendo, steamdeck>/*.png` | six trophy icons and the button pictures of four pad families, drawn by `assets/src/make_online_art.py` (64 px, deterministic, no outside image) | CC0 |
| `assets/audio/*.wav` | made with `assets.synth_sound` (presets footstep, hit, coin, pickup, error, powerup, whoosh, click, growl, explosion, splash, laser) | CC0 |

`assets.json` records the provenance of each file. The engine gaps found while building P1, P2 and P5 are in `ENGINE_FEEDBACK.json`.

## Status

| Package | What | State |
|---|---|---|
| P1 | The miner, digging and the mine | done |
| P2 | World and enemies: the three strata and their hazards, torches and crystals, enemies that chase through the dug tunnels, music per stratum, a bot that clears floors | done |
| P3 | Couch co-op: join screen, per-player devices and bindings, shared then split camera, revive, a pad unplugged, Remote Play Together | to do |
| P4 | Camp, progress and saves: the upgrades shop, Continue, 3 versioned save slots with migration, cloud saves, the daily dig, seed codes | to do |
| P5 | Steam and online: achievements, stats and boards, rich presence, Steam Deck, glyphs, news, remote balance, opt-in analytics | done |
| P6 | Sound, options and accessibility: music layers, bus effects, captions, display options, game speed, reduced flashing | to do |
| P7 | Shipping: icon and store art, store texts, screenshots and trailer, desktop exports, budgets, SHIPPING.md | to do |
| P8 | Languages: Russian and Thai, every screen at 100 % and 200 % text | to do |
