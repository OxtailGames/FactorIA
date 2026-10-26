# Tidewater Market

A management game played with the mouse: build a small harbour town on an isometric map, lay roads, put up houses and
workshops, and keep the goods moving. Web and desktop first. This is the fourth FactorIA reference game (milestone M30);
it is built in eight packages, and the table below says where it stands.

```bash
factoria validate
factoria run                                   # window: title screen, then Play
factoria run --headless --frames 120 --screenshot-at 119
factoria test                                  # all tests (about 10 s)
factoria test --filter "undo"                  # some of them
factoria call --project . project.map_preview '{"seed": 7}'   # look at a map as text, with its hash
factoria call --project . project.validate_data               # check data/*.json against each other
```

## Status

| Package | What | State |
|---|---|---|
| P1 | Map, camera, building, undo, data tables, title screen, HUD | done |
| P2 | Villagers and walkers, carriers, production chains, the running clock and its speed control, seasons and their music, wages and sales, the bot, the stress scene | done |
| P3 | Prices, markets, trade | planned |
| P4 | Population, housing, happiness | planned |
| P5 | Contracts and goals | planned |
| P6 | Saving, loading, the shop menu | planned |
| P7 | Finished art and sound under the same frame names | planned |
| P8 | Translations (es, fr, zh-Hans), accessibility, polish | planned |
| P4 (progress) | Three save slots with autosave, save format v2 with the v1 migration, cloud copies, four scenarios with goals and a win screen, the slot screen and the pause menu's Save | done |

## How to play (P1, P2)

The title screen has Play, Options, Credits and Quit; Play goes through the loading scene to the map, with the camera on the
harbour (the sea is in view). Everything can be done with the mouse. The game starts at x1; the town lives from the first
house: villagers move in, walk to work, carry goods and shop at the market (see "Economy and simulation").

| Input | Does |
|---|---|
| Speed buttons (top, left of the date: pause, 1x, 2x, 4x), keys 1 (pause), 2 (x1), 3 (x2), 4 (x4) | Set the speed of the clock; Space pauses and goes on at the speed it had |
| Palette button (right) | Pick a building; the cell under the mouse shows a ghost, green when it can go there and red with the reason in the status line when not |
| Left click | Place the picked building (the footprint is centred on the cell under the mouse); with no tool, nothing but the info line |
| Left drag with Road | Lay a road: along the longer side first, then the other; one payment, one undo step |
| Rotate button, R | Turn the next building (its door faces +c, +r, -c, -r; the rotation is kept between picks) |
| Demolish button, X | Left click or drag removes buildings and roads and hands half of the cost back (rounded down per item) |
| Right click without moving, Q | Put the tool away (or cancel a drag in progress) |
| Right or middle drag, WASD, arrows, the screen edge | Move the map; it never leaves the map plus a margin |
| Mouse wheel, PageUp, PageDown | Zoom (0.35 to 2.5) towards the cursor |
| Undo / Redo buttons, Z / Y | Take back or redo the last action; a refused undo says why |
| Escape, P | Pause menu (resume, options, main menu) |

Picking uses the ground cell under the mouse, not the picture of a building: a click on the upper part of a tall building picks
the ground cell behind it, not the building.

## Where things live

| Path | What |
|---|---|
| `data/*.json` | The tables: `terrain`, `goods`, `recipes`, `buildings`, `economy` (start, refund, undo limit, calendar, the `sim` knobs), `seasons` (what each season changes), `map` (generator settings), `test_map` (a 12 x 10 map for tests), `atlas` (frame rectangles). Validated against each other, the atlas and the locale strings when the game starts, and by `project.validate_data` |
| `scripts/game/` | Pure logic with no engine calls: `iso`, `events`, `mapgen`, `map`, `rules`, `economy`, `clock`, `state`, `data`, `format`, `camera_math`, and the town: `sim` (buildings' runtime state, production, money), `roadnet` (distance fields on the roads), `walkers`, `people` (villagers), `logistics` (carriers), `harbour`, `planner` and `bot` (a test player), `stress_town`. Engine-facing: `nav_backend` (the engine's path finder as a route backend, tests only). Behaviours: `game_controller`, `camera_rig`, `map_view`, `walker_view`, `music_director`, `title_backdrop` |
| `scenes/` | `menu` (title), `loading`, `game`, `stress` (the game scene with a 640-villager town built at start: `perf.measure` with `{"scene": "scenes/stress.scene.json"}`) |
| `locales/en.json` | Every text the player sees. Nothing is hard-coded in a script |
| `assets/atlas.png` | One 2048 x 1024 atlas with every picture the map draws (one atlas is one draw call). `assets/src/make_atlas.py` builds it from the Kenney CC0 images in `assets/src/kenney/` plus placeholder art drawn in the script; `assets.json` has the provenance |
| `tools/` | `project.map_preview`, `project.validate_data`, `project.grow_town` (the bot grows a town from a seed and reports it) |
| `tests/` | map generation, rules, data tables, camera and picking, the pause menu, the mouse-only flow from the title screen, the clock and seasons, the HUD speed control, the simulation (walkers, road cuts, carriers, chains, wages, sales), the bot's year, the stress town, and screenshots to look at (`.factoria/tmp/*.png`) |

## Contracts for the next packages

Every later package reads and writes the same objects. In a behaviour, `world.find("controller").behaviour.state` is the
`GameState`; pure code takes a `GameState` as an argument (`createGame({seed, testMap})` makes one with no engine).

**Map API (`state.map`, `GameMap`).** Cell (c, r) is column c, row r; `width`, `height`, `seed`; `terrainAt(c, r)` gives a
terrain id (`water`, `sand`, `grass`, `forest`, `rock`) or null outside the map; `occupantAt(c, r)` is the id of the building
on it (0 = free; a road is a building of kind `road`); `touchesWater(c, r)`; `hash()` is 8 hex digits that identify the terrain
(one seed gives the same map and hash on every machine, no `Math.random` and no clock are used). Screen maths is in
`scripts/game/iso.js` (`cellToWorld`, `worldToCell`, `mapBounds`; a tile is a 100 x 50 diamond, `x = (c - r) * 50`,
`y = -(c + r) * 25`). Placement questions: `state.check(type, x, y, rot)` and `state.checkAt(type, c, r, rot)` return
`{ ok, reasons: [{ code, detail }] }`; the codes are those of `locales/en.json` `reason.*`.

**Building catalogue (`data/buildings.json`, `state.data.buildings`).** One entry per building: `kind` (`road` or `building`),
`category`, `size` `[along c, along r]` at rotation 0 (odd rotations swap it), `cost` (coins and goods), `terrain` the cells
may stand on, optional `nearWater`, `requireRoad` (`frontage`: a road on the row of cells just outside the door), and the
numbers later packages read: `housing`, `workers`, `storage`, `recipes` (ids from `data/recipes.json`, each with `inputs`,
`outputs` and `seconds`). The name and description of building `x` are the locale strings `building.x.name` and
`building.x.desc`. Adding a building means adding its entry, its two strings and its four atlas frames
(`building.<id>.0` to `.3`); it then appears in the palette by itself. A placed building is
`{ id, type, x, y, rot, w, h }` (`x`, `y` the footprint's minimum corner, `w`, `h` its size at that rotation; ids are never reused);
`state.list(type?)`, `state.buildingAt(c, r)`, `state.place(type, x, y, rot)`, `state.placeAt`, `state.placeRoads(cells)`,
`state.demolish(c, r)`, `state.demolishCells(cells)`, `state.undo()`, `state.redo()` are the actions. `place` returns `{ ok, building }` or `{ ok: false, reasons }`; `placeRoads` returns `{ ok, placed, skipped }`; `demolish` returns `{ ok, building, refund }`; `demolishCells` returns `{ ok, removed }`.

**Economy state (`state.economy`).** `coins` and `stock` (good id -> number). `get(key)` takes `"coins"` or a good id. Changes go through
`apply(delta, cause)`, where a delta is a flat object `{ coins: -40, wood: -4 }`; it refuses (returns false, changes nothing)
when a balance would go below zero, and emits `economy.changed`. `canAfford(cost)` and `canApply(delta)` say what is missing.
The simulation uses the causes `dispatch` (a carrier takes goods out of the stock), `delivery` (it puts goods in), `wages`, `upkeep`
and `sales`; goods being made are not in the stock until a carrier delivers them (they wait in the building's outbox). Undo gives back exactly what an
action cost or refunded, and is refused when the money is no longer there.

**Game events (`state.events`, a synchronous bus; `on(name, fn)` returns the unsubscribe function, `"*"` hears everything).**
`building.placed` and `building.removed` `{ building, cause }` (cause: `place`, `demolish`, `undo`, `redo`); `roads.changed`
`{ cells }`; `economy.changed` `{ coins, stock, delta, cause }`; `history.changed` `{ canUndo, canRedo, undoLabel, redoLabel }`;
`action.rejected` `{ action, code, reasons }` (refused placement, undo or redo); `clock.speed` `{ speed }`, `clock.tick`,
`clock.day`, `clock.season` (above); from the simulation: `villager.arrived` `{ villager, house }`, `villager.left`
`{ villager, reason }` (`starved`, `home_lost`), `production.done` `{ building, recipe, outputs }`, `delivery`
`{ goods }` (a carrier unloaded at a warehouse), `payday` `{ wages, upkeep, owed, broke }` (once per day, after `clock.day`),
`market.sale` `{ market, villager, items, coins }`. A listener that throws is logged and the others still run. A package reacts to the game through these events
and never reaches into the view.

**The clock (`state.clock`, P2).** The API of P1 is kept. A new clock is paused; the game screen starts it at x1.
`setSpeed(i)` picks an index of `SPEEDS = [0, 1, 2, 4]` and emits `clock.speed`; `advance(dt, maxSteps)` is called by the
controller every frame with real seconds, multiplies them by the speed, cuts the result into FIXED steps of
`calendar.tickSeconds` (0.2 game seconds) and runs one `tick(step)` for each, so x1, x2 and x4 and every frame rate give the same
town (a speed decides how many steps run per frame, never how long a step is). A frame that took too long runs at most
`maxSteps` steps (the controller passes 12) and drops the rest. `date()` gives `{ day, year, season, seasonIndex, dayOfSeason }`
(`day` = whole days since the start, `dayOfSeason` counts from 1) from the calendar in `data/economy.json`: 4 seasons of 10
days, 30 game seconds per day, 150 steps per day, 40 days a year. `dayFraction()` is the time of day 0..1 (an integer count of
steps, no drift). Events, always in this order within a step: `clock.day` `{ day, date }` when the day changes, `clock.season`
`{ date }` right after it when the season (or year) changes, then `clock.tick` `{ seconds }`, once per fixed step, which is
what the whole simulation runs from. Nothing in the simulation reads the frame time or a wall clock. `setDay(n)` is for tests
and loading (it moves the date without events; the simulation reads the season from the clock, not from the event).

**Seasons (`data/seasons.json`).** One entry per season id of the calendar: `production` (speed multiplier per recipe id, a
missing one is 1, 0 = the building waits: "out of season"), `demand` (multiplier on a good's base price at the market),
`tint` (colour multiplied onto the grass, sand and trees; `map_view` applies it on `clock.season`), `music` and `musicVolume`
(the loop `music_director` crossfades to; the loops are in `assets/music/`, made by `assets/src/make_music.py`). P3 prices read
`sim.priceOf(good)`, which already multiplies by the season's demand.

## Economy and simulation (P2)

`state.sim` (`scripts/game/sim.js`) is the town. It listens to `building.placed` / `building.removed` and runs one step on
every `clock.tick`, in this order: villagers (`people`), carriers (`logistics`), walkers, production. It has no random number
and no clock of its own, so one seed and one sequence of player actions give one town (`state.hash()` includes it).

**The day** (fractions of the 30-second day, `sim` in `data/economy.json`): from `workStartDay` 0.05 (plus up to
`departSpreadDay` 0.1 by villager id, so they do not leave together) the employed walk to their workplace and stay until
`workEndDay` 0.7 (the market's staff until `marketCloseDay` 0.92). After work a hungry villager walks to an open market that
has food, then everybody walks home. A villager is either inside a building (`at`) or one walker on the road (`walkers.list`).

**Villagers (`sim.people`).** `{ id, home, job, at, state, purpose, food, hunger, lastShop, trip }`. A house (4 beds) takes in
a villager `firstArrivalSeconds` 4 after it is built and then one every `growthSeconds` 12, as long as it has a road to it and:
below `founders` 6 villagers always; from then on nobody is hungry, fewer than `unemployedLimit` 3 villagers lack a job, and
`sim.people.townFood()` (stock and market shelves, not the packs) is at least `(population + 1) * foodPerDay * growthFoodDays`.
A villager eats `foodPerDay` 0.6 a day from a pack of `foodBuffer` 3; once a day, after work starts, it walks to the nearest
open market that has food when its pack is below `shopBelow` 1.2 and fills the pack there (cheapest nutrition per coin first);
with the pack empty for `hungerLimitDays` 6 days it leaves (`villager.left`, reason `starved`); demolishing its house
sends it away too (`home_lost`). `people.moveIn(houseId)` puts one in at once (tests, the stress town).
Jobs (`people.assign`): workplaces by `jobPriority` of `data/buildings.json` (market 0, warehouse 1, farm, dock, camp,
sawmill, mill, bakery, smokehouse 3, quarry 4, workshop 5) take the nearest unemployed villager by road, in two rounds (one
worker for every workplace first, then the rest), and a more important workplace may take a worker from a less important one.
Villagers hold no money: the wage is a cost of the town, paid at the start of each day (below).

**Walkers (`sim.walkers`, `sim.net`).** `walkers.start(id, kind, fromBuilding, goalBuilding, speed)` makes a walker follow a
list of road cells (cells per game second: `walkSpeed.villager` 2.4, `walkSpeed.carrier` 2.0); `x, y, px, py` are fractional
cells (`walker_view` draws at `px + (x - px) * clock.alpha`). Roads are `RoadNet` (`roadnet.js`): one breadth-first distance
field per goal building, cached until `net.version` (any road change) moves. A walker re-checks its way every step: a road
cut under it sends it round by another way from where it stands, with no way it waits `patienceSeconds` 15 and gives up
(`walkers.gaveUp` counts them; the villager is put back inside its home, and a carrier's errand is dropped). Plug-in: `net.setFinder(fn)` replaces the fields with a
single-pair path finder `fn(road, width, height, fromCell, toCell) -> cells | null` (`nav_backend.js` wraps the engine's
`nav.findTilePath`; slower for crowds, see "Stress scene").

**Production.** A building with `recipes` and `workers` runs the first recipe whose inputs are in its inbox and whose outputs
fit its outbox. Progress per step is `dt * (present / workers) * seasonRate * productionRate` (3.5, halved by
`unpaidEfficiency` 0.5 while the town is broke), so one worker runs half speed and an empty building stops. Why a building is
not running is `rt.stall`: `no_staff`, `closed` (nobody inside right now), `no_input`, `output_full`, `season` (strings in
`locales/en.json` `sim.stall.*`), `""` while it runs. Chains (data only: `data/recipes.json`): fish -> smokehouse -> smoked
fish; grain -> mill -> flour -> bakery -> bread (a bakery also bakes bread straight from grain, less); wood -> sawmill -> planks.
The goods with a `nutrition` in `data/goods.json` (fish, bread, smoked fish) are what the market shelves and villagers eat.
Winter stops the farms (`harvest_grain` 0), autumn almost doubles them.
`production.done` fires per finished cycle.

**Carriers and stock (`sim.logistics`).** The workers of a warehouse are the carriers; every `dispatchSeconds` 1 the planner
lists what has to move and gives each job to an idle carrier of the warehouse nearest by road: `supply` (stock -> a producer
whose inbox needs the goods, or a market whose shelf is below `marketTarget` 16), `collect` (an outbox with goods -> stock).
A carrier takes at most `carrierCapacity` 12 and reserves the room and the goods, so two carriers never fetch the same goods.
All warehouses share ONE stock, `state.economy.stock`, at most `sim.capacity()` of each good (`baseStorage` 80 plus 400 per
warehouse); a delivery that does not fit is lost (`ledger.lost`) and a producer with a full outbox waits (`output_full`).
Without a warehouse nothing moves: producers fill their outbox and stop and the market stays empty. A producer keeps at most
`outboxCycles` 2 cycles of output and `inboxCycles` 2 cycles of input.

**Money.** At the start of each day (`payday`, after `clock.day`): `wagePerDay` 1 coin per employed villager and the `upkeep`
of every building (`data/buildings.json`), as far as the coins go; what could not be paid sets `sim.broke` until the next
payday that can. Income is the market: a villager that buys food pays `sim.priceOf(good)` per unit into the town's coins
(`market.sale`). `sim.ledger` counts, since the start: `produced`, `consumed`, `eaten`, `lost` per good, and `sales`, `wages`,
`upkeep`, `wagesShort` in coins; `sim.inventory(good)` counts a good wherever it is (stock, inbox, outbox, shelf, in a carrier's
hands), which is how tests check that nothing appears or disappears.
**Plug-ins for later packages:** P3 replaces `sim.priceOf(good)` (called at every sale and by the bot) and may add its own coin
flows through `economy.apply(delta, cause)` with a new `cause`; P4 changes the growth rule in `people.grow` and the hunger
constants in `sim`; P5 reads `sim.summary()` (`{ population, housing, employed, jobs, unemployed, hungry, walkers, broke,
ledger }`) and the events above; P6 has to save `clock.day`/`dayTick`, `economy`, the buildings, `people.villagers` with their
`food`, `hunger`, `job`, `sim.rt` per building (`inbox`, `outbox`, `shelf`, `progress`, `cur`) and `sim.ledger`; walkers and
carriers' trips are not saved by anything yet, so a saved game should put a villager that is outside back inside its home; P7
replaces pictures only.
Every number named above is in `data/economy.json` `sim`; `tools/validate_data.js` checks them.

## The bot and the planner (P2)

`scripts/game/bot.js` is a rule-based player that uses only the public actions, so it tests the economy the way a player
would: `growTown({ seed, testMap, days, state, maxBuildsPerDay })` runs it for `days` game days (40 = a year) and returns
`{ state, bot, history, summary }` (`history`: one `snapshot` per day with `population`, `housing`, `employed`, `jobs`, `hungry`,
`coins`, `buildings`, `hash`). Its rules: build a house when 3 or fewer beds are free (6 when food is short); when 3 villagers have no
job build the next workplace (warehouse, market, smokehouse, bakery, mill, lumber camp, sawmill, farm and fisher dock in
balance, in that order of need); a farm, dock or bakery when food is short and fewer than 2 jobs are open; a warehouse when
a stock fills up. Every day it builds what it wants in that order while the coins stay above a reserve, and it waits (builds
nothing cheaper) when it is saving for the next one.
`planner.js` answers where: roads follow a street lattice every 5 cells through the harbour (`harbour.js`, the shore cell the
camera starts on), round rock and trees, and every building goes at the free site nearest the harbour that touches a road
joined to it (`Planner.build(type)`, `buildMany(type, n)`, `sites(type)`, `layRoads(n)`). The tool
`factoria call --project . project.grow_town '{"seed": 20261026, "days": 40}'` prints the same report.
Pinned in `tests/bot.test.js` (seed 20261026, the default map): after a year the town has 30 villagers in 40 beds, 30 of 35 jobs
filled, 350 coins and hash `6dee2f92`; the test also keeps the numbers inside a sane range (population 24..45, coins 0..5000,
no more than 3 broke days, hungry at most 8) so a tuning change that breaks the economy fails with a reason, not only a hash.
Change the economy on purpose: run the test, read the report, update the pinned hash and say why in the commit.

## Stress scene (P2)

`scenes/stress.scene.json` is the game scene with `stress: 640` in the controller's props: a flat 60 x 60 map, 160 houses with
640 villagers, 23 farms and bakeries, 4 markets and 3 warehouses, laid out one step per frame in the first frames
(`stress_town.js`, `stressTownSteps`; a script callback may not run over 2 s), then the clock runs at x4 (`startSpeed` 3).
About 600 villagers are on the roads at once in the morning (`tests/stress.test.js` pins at least 500 and no one giving up).
`factoria call --project . perf.measure '{"scene": "scenes/stress.scene.json", "frames": 450}'` measured, in a DEBUG build on
an Apple M5 (Metal): `cpuMsAvg` 29.8, `cpuMsP95` 30.0, `cpuMsMax` 1325 (the frames that build the town), `drawCalls` 27,
`entities` 4682, `peakMemoryMB` 91.4. These are not budgets: P7 sets them on a release build and the CI runners.
Walker routes: the distance fields cost 442 ms for 75 steps of 600 walkers against 5978 ms through `nav.findTilePath` on the
same 60 x 60 map (see FB-0006 in `ENGINE_FEEDBACK.json`), which is why the game uses the fields.

## Saves and scenarios (P4)

**Slots.** Play on the title opens the slot screen: three slots, each with a manual save and an autosave, showing name, scenario,
in-game date, play time and a small map of the town (the engine cannot give a script a screenshot as a texture: FB-0020). An empty
slot starts a new game (pick one of the scenarios); a taken one loads; Continue loads the newest entry; Rename and Delete (asks
first) work on a slot. The pause menu's Save game saves into a slot (asks before replacing one) and the game then belongs to that
slot. Everything works with the mouse alone and with the keyboard alone (`tests/slots_screen.test.js`).
A game sent to the game scene is described by `session.boot`: `{ slot, kind }` loads, `{ slot, scenario, name }` starts a new game.

**Autosave** (`scripts/game/autosave.js`, wired by `scripts/save_controller.js`) writes the autosave entry of the game's slot when a
season ends (at the end of the frame, never inside a clock step), every 120 s of play when the town changed, when a goal is won, and
when the window loses the focus, the app is suspended or the desktop window closes. A game with no slot (slot 0) is never
autosaved. Play time counts real seconds (a frame counts at most 1 s) and stops while the window has no focus. A write that fails
(storage full or refused) keeps the old entry and shows a toast.

**Save format** (`scripts/game/savegame.js`, the only file that knows the layout). `tidewater.save`, `VERSION = 2`: the map with its
terrain as run lengths, the clock, the economy, the buildings (roads laid in a line are one array each), the simulation (villagers,
walkers where they stand, the ledger) and the scenario with its goal progress. A loaded game continues exactly as the saved one
(same `state.hash()` after any number of days; `tests/save.test.js`). Not saved: undo history, camera, current tool.
A damaged file, a file that is not a save, one with an unknown format, one written by a newer game (`future_version`) or one too
old to migrate is refused with a sentence, a hint and a JSON pointer; nothing starts and the slot is left as it was.
Measured for the stress town (640 villagers, 532 walking): 281 KB, 143 ms to write and 75 ms to read and restore, in a debug build
(`tests/stress.test.js` prints them; FB-0022).

**How to bump the version.** 1. Change the layout in `serializeGame` / `restoreGame` and raise `VERSION`. 2. Add `MIGRATIONS[n]` (the
old version n) that returns a save of version n + 1; `readSave` runs the steps in order. 3. Write a new fixture with
`tools/save_fixture.js` (`tests/fixtures/save_vN.json`, `slot_vN.json`) and a test that loads it. 4. NEVER regenerate an old fixture:
it is the proof that old saves still load.

**What later packages add to a save.** `serializeGame(state, extra)` keeps the fields of `extra` at the top level of the save and
`readSave` ignores fields it does not know, so a package that adds state (ships and events, prices, translations of names) puts its
own field there, restores it in `restoreGame` after the buildings and the clock, and adds a `MIGRATIONS` step for saves that lack it.
`GoalTracker.saveFields()` is the model.

**Cloud copies** (`scripts/game/cloud_sync.js`) go through `platform.cloud` when `platform.has("cloudSave")`: every entry written is
pushed (`tm_slot_N`, `tm_slot_N_auto` = `{ revision, meta, save }`), and the slot screen syncs when it opens. The rule when device
and cloud differ: the higher `revision` (a counter of device writes that a pull raises) wins; equal: the greater play time; equal:
the device. The copy that lost is kept in `tm.conflict.<slot>`. No cloud (no store backend) means the game saves on the device only.

**Scenarios** (`data/scenarios.json`, `scripts/game/scenarios.js`). Ids are the contract for later packages: `first_harbour`,
`river_mills`, `winter_trade`, `sandbox` (no goals). A goal is `population`, `coins` or `produced_in_season` (a good made in one
season), is sticky once reached, and emits `goal.done`; the last one emits `scenario.won`, which shows the win screen (keep playing
or back to the title) and writes the autosave. The goal panel sits under the top bar, left. The tracker only reads the game, so
goals never change the state hash. The bot reaches every scenario (`tests/scenarios.test.js`).

## Plug-in points

- **HUD:** `controller.addHudItem(id, atlasFrame, text)` adds an icon and a number to the top bar and returns the Text
  entity; goods with `"hud": true` in `data/goods.json` are added by the controller itself.
- **Palette:** a new entry in `data/buildings.json` is a new button.
- **Text:** a new string in `locales/en.json`; the data check fails when a building or good has no name.
- **Pictures:** frames are in `data/atlas.json` (`rect` in atlas pixels, `pivot`); P7 replaces `atlas.png` and keeps the names.
- **Rules:** `checkPlacement` in `scripts/game/rules.js` returns a list of reasons; a new rule is a new reason code plus
  its `reason.<code>` string.
- **Menu:** the menu kit scripts (`settings.js`, `main_menu.js`, `pause_menu.js`, `ui/*`) are the kit's own; Escape is both the
  pause action and the kit's `ui_cancel`, which `pause_menu.js` handles.

## Assets

Terrain, road and tree pictures are from Kenney's Isometric Roads pack (CC0, www.kenney.nl), imported with `assets.import` and
recorded in `assets.json`. The buildings, the rock tile and the goods icons are placeholder art drawn by
`assets/src/make_atlas.py` (run it from this folder with Pillow: `python3 assets/src/make_atlas.py`).

Gaps found in the engine while building this are in `ENGINE_FEEDBACK.json`.
