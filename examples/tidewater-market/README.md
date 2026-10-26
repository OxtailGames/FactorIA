# Tidewater Market

A management game played with the mouse: build a small harbour town on an isometric map, lay roads, put up houses and
workshops, and keep the goods moving. Web and desktop first. This is the fourth FactorIA reference game (milestone M30);
it was built in eight packages, all done (the table below).

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
| P3 | The interface: build menu, inspector, tooltips, goods table, charts, notifications, overlays, worker drag and drop, shortcuts and help | done |
| P4 | Three save slots with autosave, save format v2 with the v1 migration, cloud copies, four scenarios with goals and a win screen, the slot screen and the pause menu's Save | done |
| P5 | The pier and its ships, orders, the order board, event cards, a story per scenario, achievements and stats on the store | done |
| P6 | Ambience beds that follow the camera, building work and walker sounds with a voice cap, UI sounds, five volume buses, the options screen (sizes, window, key rebinding, colour-blind safe signals, reduced motion, hold-free controls) and the gamepad cursor | done |
| P7 | Icon, key art, capsules, store texts, six screenshots and a trailer rebuilt by scripts from the game's own renders; the web and macOS exports; perf budgets; the dense-overlay fix | done; the Windows and Linux exports not checked, see SHIPPING.md |
| P8 | Spanish, French and Simplified Chinese (with a font subset), one formatting module, a language choice that applies at once, every screen checked at 100% and 200% text in every language | done |

## Shipping (P7)

The store assets (icon, key art, capsules, screenshots, texts, trailer), how to rebuild each of them, the export commands with
measured sizes, the performance budgets, the finishing checklist and what is still open for a real release are in
[SHIPPING.md](SHIPPING.md).

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
| `data/*.json` | The tables (and `ships`, `events`, `story` for P5, below): `terrain`, `goods`, `recipes`, `buildings`, `economy` (start, refund, undo limit, calendar, the `sim` knobs), `seasons` (what each season changes), `map` (generator settings), `test_map` (a 12 x 10 map for tests), `atlas` (frame rectangles). Validated against each other, the atlas and the locale strings when the game starts, and by `project.validate_data` |
| `scripts/game/` | Pure logic with no engine calls: `iso`, `events`, `mapgen`, `map`, `rules`, `economy`, `clock`, `state`, `data`, `format`, `camera_math`, and the town: `sim` (buildings' runtime state, production, money), `roadnet` (distance fields on the roads), `walkers`, `people` (villagers), `logistics` (carriers), `harbour`, `planner` and `bot` (a test player), `stress_town`, and the trade: `trade` (ships, orders, reputation, event and story cards, saving), `sea` (water routes), `rng` (the engine's `rng.create` streams with a weighted pick), `trade_data`, `richtext` and `trade_text` (the markup of the cards). Engine-facing: `nav_backend` (the engine's path finder as a route backend, tests only). Behaviours: `game_controller`, `camera_rig`, `map_view`, `walker_view`, `ship_view`, `trade_ui` (the board and the cards), `rich_view`, `achievements` (the store bridge), `music_director`, `title_backdrop` |
| `scenes/` | `menu` (title), `loading`, `game`, `stress` (the game scene with a 640-villager town built at start: `perf.measure` with `{"scene": "scenes/stress.scene.json"}`) |
| `locales/en.json` | Every text the player sees. Nothing is hard-coded in a script |
| `assets/atlas.png` | One 2048 x 2048 atlas with every picture the map draws (one atlas is one draw call). `assets/src/make_atlas.py` builds it from the Kenney CC0 images in `assets/src/kenney/` plus placeholder art drawn in the script; `assets.json` has the provenance |
| `tools/` | `project.map_preview`, `project.validate_data`, `project.grow_town` (the bot grows a town from a seed and reports it) |
| `tests/` | map generation, rules, data tables, camera and picking, the pause menu, the mouse-only flow from the title screen, the clock and seasons, the HUD speed control, the simulation (walkers, road cuts, carriers, chains, wages, sales), the bot's year, the stress town, the trade (`trade`, `trade_ui`, `rich_text`) and screenshots to look at (`.factoria/tmp/*.png`) |

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

**Ships and events in a save (P5).** While the trade is on, the save has a top-level `trade` field: `state.trade.snapshot()` (its own
`v: 1`; ships, orders, reputation, the open event card, the story, achievements and the state of its three random streams). It is
restored last, after the buildings and the clock, with `state.trade.restore`; a snapshot the trade refuses (another `v`) refuses the
whole save at `/trade`. A loaded game keeps its trade: `trade_ui.js` only starts a new one when the state has none, and starts it
for the scenario the slot screen picked (`controller.run.scenario`; the scene prop `scenario` still wins). A save made with the trade off (or by
the first v2 builds) has no `trade` field and loads with it off, and the game screen then starts it fresh from the day of the load.
A game saved while an event card was open comes back at speed 0 with the card open and goes on at x1 after the answer
(`tests/save.test.js` pins `state.trade.hash()` equal after more days; `tests/scenario_game.test.js` checks the screen).

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
or back to the title) and writes the autosave. The goal panel sits under the right-hand menu column. The tracker only reads the game, so
goals never change the state hash. The bot reaches every scenario (`tests/scenarios.test.js`).

## Interface (P3)

All of it lives in `scripts/game/ui_hud.js` (`Hud`, owned by the controller as `controller.hud`, updated once a frame),
with pure helpers in `ui_model.js` (no engine calls; unit tests in `tests/ui_model.test.js`) and spawn helpers in
`ui_kit.js` (`panel`, `label`, `button`, `icon`, `rule`, `Tooltips`). The controller still owns the tool, the hover, the map
drag and the top bar; everything else is the Hud's.

| Piece | What it does |
|---|---|
| Build menu (key B, Build button) | A bar at the bottom: category tabs, then one item per building with its picture, name and cost; an item you cannot pay is red. Picking an item sets the tool and the bar follows the tool's category |
| Inspector | A click on a building or villager (with no tool) opens it, at the bottom right: status, workers (up to four villager chips), what it makes, upkeep and refund; Rotate, Demolish, Home, Work, Release, Close. A click on bare ground or a road closes it |
| Tooltips | After the pointer rests 0.4 s: every button (with its key), the numbers in the top bar, build menu items (cost, needs, gives) and, with no tool, the building under the pointer. Flipped near the screen edges |
| Goods table (G) | Every good: stock, made and used per game day, price. Click a header to sort, again to reverse; the wheel scrolls it and does not zoom the map |
| Charts (T) | Bars over the last days: coins, the stock of one good (click the good name to cycle) or what was made |
| Notifications | Up to five at the top left; the same message for the same building stacks as (xN); a click (or N for the newest) moves the camera there and selects the building |
| Overlays (M, Map button) | Desirability, market coverage, warehouse reach, traffic; each tints the cells in view; the legend says what it shows |
| Worker drag and drop | Press a villager chip in the inspector, drag onto a workplace on the map: the chip turns green or red (and says why); a drop moves the worker and pins the job (`people.reassign`) |
| Help (F1) | Lists every shortcut (`SHORTCUTS` in `ui_model.js`) |

Keys: B build menu, X or Delete demolish tool (Delete removes the selected building when there is one), R rotate (the selected
building, free, one undo step; otherwise the next building to place), Z / Y undo and redo, G, T, M (overlays), N, F1 as above.
**Escape** puts away the newest thing the player opened: a worker drag, then open panels (help, charts, goods), the drag in
progress, the tool, the selection, the build bar, the overlay; only when none is left does it open the pause menu
(`pause_menu.js` asks `controller.escape()` first). Right-click without moving does the same.

**How a later package adds something** (the contract comment at the top of `ui_hud.js` has the same text):

- *A panel:* build a Panel with `ui_kit.js` (it starts hidden), then `hud.addPanel("name", { root, refresh, every })` and
  `hud.open("name")`, `hud.close`, `hud.toggle`. `refresh()` runs when it opens and every `every` seconds. Esc closes it, newest first, and the wheel is kept away from the map under any open panel.
- *A tooltip:* `hud.tooltips.add(entity, () => ({ title, lines: [{ text, color? }] }))`; return null for none right now.
- *A notification:* `hud.notices.push("key", args, cell, buildingId, "warn" | "bad")` with the text in `locales/en.json` at `ui.notice.<key>`; pushing the same key for the same building again raises its count instead of adding a line.
- *An overlay:* `hud.addOverlay("id", { color: [r, g, b], field(state, hud) -> { values, cells } })`; the name and hint are `ui.overlay.<id>` and `ui.overlay.hint.<id>`. The Map button cycles through every registered overlay.
- *A shortcut:* add the action to `factoria.json`, then `hud.onKey("action", fn)`.

Next to the trade UI of P5: the overlays are on **M** (O is the order board); the notification stack starts below the Orders button;
while an event card is open (it is modal) the interface keys, tooltips and the wheel wait; the top bar fitting also counts the
reputation item.

Other changes the interface made: `camera_rig.js` ignores the wheel while `rig.wheelBlocked` is true (the Hud sets it from the
panel rectangles); the date and speed buttons moved a little so the bar has room; goods that do not fit left of the date are
hidden from the end of the top bar (`fitTopBar` in `game_controller.js`; the goods table has them all). The simulation is only
changed through the same actions as before: `place`, `demolish`, `rotateBuilding` (new, refuses roads and housing),
`people.reassign` and `people.release`. At a text size of 150 % or the largest interface size the panels move out of each
other's way (P6, below; `ui_layout.test.js` checks 1280 x 720 with the inspector open).

Tests: `ui_mouse.test.js` (mouse only), `ui_keys.test.js` (keyboard only), `ui_dragdrop.test.js`, `ui_layout.test.js`. Engine gaps
found while building it are FB-0007 to FB-0018 in `ENGINE_FEEDBACK.json`.

## Ships and events (P5)

The trade is a plain object, `state.trade` (`scripts/game/trade.js`), driven by the game clock; `trade_ui.js` shows it. It is
OFF unless the scene turns it on: `trade_ui` starts it in the game scene, except for `testMap` and `stress` (so the bot's
hash and the older tests do not change). Scene props of `scenes/game.scene.json`: `scenario` (an id of `data/scenarios.json`,
default `sandbox`) and `trade` (`true` forces it on, `false` off). **P3/P4 must pass `scenario` when they load the game scene.**

**How to play it:** build a pier on a cell that touches water (`nearWater`). After a few days a ship sails in, docks and shows
one order: goods for coins. The Orders button (top left, or key `O`) opens the board; "Fill order" takes the goods through
`state.economy.apply` and pays. A ship whose deadline passes leaves and costs reputation; reputation unlocks bigger ships.
Once per season an event card opens (day 3 of the season); story cards open on their own conditions. A card is modal: the
clock waits at speed 0 and goes on at the old speed after Continue.

**Data.** `data/ships.json` (schedule, reputation, ship classes with `minReputation`, `weight`, wanted goods and `premium`),
`data/events.json` (per event: `weights` per season, `requires`, 2 or 3 `choices`; a choice is `effects`
`{ delta, reputation, shipDelay }` or a gamble `outcomes: [{ weight, effects }]`), `data/story.json` (per scenario a list of
cards with `when`: day, season, pier, ordersFilled, reputation, population, coins, built). The `$comment` of each file says
every key. `project.validate_data` checks them against the goods, buildings and locale strings.

**Add an event:** one entry in `data/events.json` and the strings `event.<id>.title`, `.body`, `.choice.<choiceId>`,
`.result.<choiceId>` (or `.result.<choiceId>.<n>` per outcome) in `locales/en.json`, then `factoria call project.validate_data`.
Every event needs a choice that costs nothing. Story cards use `story.<scenario>.<id>.*` and `story.<scenario>.name`.

**Rich text** (`scripts/game/richtext.js`, drawn by `rich_view.js`): `[b]..[/b]` (drawn twice, there is no bold font),
`[c:good|bad|gold|muted|sea|#rrggbb]..[/c]`, `[icon:wood]` (atlas frame `icon.<name>`), `[[` for a literal bracket, `\n`. A typo is
reported with its position by `rich_text.test.js`, which parses every event, story and trade string.

**Events on `state.events`:** `trade.ship.sent`, `trade.ship.docked`, `trade.order.filled`, `trade.order.missed`,
`trade.ship.left`, `trade.reputation`, `trade.class.unlocked`, `trade.card`, `trade.choice`, `trade.card.closed`,
`trade.story.finished`, `trade.achievement`, `trade.restored`.

**Saving (for P4).** `state.trade.snapshot()` returns plain JSON (`v: 1`: scenario, enabled, startDay, reputation, ships,
queue, the open card, history, story position, stats, unlocked achievements, and the state of its three random streams);
`state.trade.restore(snap)` reads it back (it throws for another `v`, restarts the scenario, then overwrites everything and
emits `trade.restored`, which makes the UI redraw). Restore after the buildings and the clock are restored. `trade.hash()` is
a fingerprint for tests. The trade keeps three `rng.create` streams (ships, events, outcomes) and saves their `state`, so a loaded game continues the same draws (`scripts/game/rng.js` adds only `weighted`); saves made when the game had its own mulberry32 still load, the algorithm and the state are the same (FB-0032).

**Store.** `factoria.json` has a `platform` catalogue: achievements `first_ship`, `ten_orders`, `harbour_master`,
`no_debt_year`, `story_first_harbour`, `story_river_mills`, `story_winter_trade`, and stats `ships_docked`, `orders_filled`,
`orders_missed`, `events_resolved`, `coins_earned`, `stories_finished`. `achievements.js` forwards them; with no store
(`platform.has` false or a refused call) the game plays on and the trade keeps its own `unlocked` list.

## Sound, options and accessibility (P6)

**Buses.** The engine has four (`master`, `music`, `sfx`, `ui`); the game adds a fifth, `ambience`, declared in `factoria.json`
(`"audio": { "buses": { "ambience": { "parent": "sfx" } } }`, FB-0041): the beds play on it, so the `sfx` and `master` volumes scale
them too. The Audio tab of the options screen sets the five volumes; `settings.apply()` sends all of them to `audio.setVolume`. Sound only reads the simulation: options and audio never
change the state hash (`6dee2f92` for the bot).

**Sounds.** `data/sounds.json` lists every clip by role (`ui`, `ambience`, `work`, `walkers`, plus the `mix` and `voices` knobs) with its own level. The voice caps (`VoiceBook`) ask the
engine which voices still play (`audio.activeVoices()`, FB-0045). To add a UI sound: put the CC0
clip in `assets/sfx/`, record it in `assets.json` (`project.validate_data` fails when a clip is not recorded), add it under `ui` and
call `playUi("name")` from `scripts/game/sfx.js`. To add an ambience emitter: add the clip under `ambience` and a rule to
`scripts/game/soundscape.js` that returns its wanted level from what the camera sees; `soundmix.js` has the pure maths (zoom gain,
screen margin, `VoiceBook`, the voice cap) the tests call. `GameSfx` plays work sounds of buildings in view and a cart or walker sound,
at most the voice cap at once (the stress town stays under it: `sound.test.js`). P2's music director is unchanged.

**Options.** `scripts/ui/options.js` (prefab `prefabs/ui/options.prefab.json`) opens from the title and the pause menu; tabs Audio,
Video, Controls, Access and Language. It edits one object saved in `storage` under `"settings"` (`scripts/settings.js`: `volume` per
bus, `windowMode`, `vsync`, `frameCap`, `colorFilter`, `bindings` (action to binding names, only the ones the player changed), `textScale`
(1, 1.25, 1.5, 2) and `uiScale` (1, 1.25, 1.5), `reducedMotion`, `safeColors`, `holdFree`, `language`, `subtitles`). `applyOnce()` applies it when the first
scene starts. Key rebinding refuses a key another action already has, says which, and keeps the old binding. Safe colours add patterns to
the overlays and a mark before each notice; reduced motion turns off camera easing, notice fades and the moving title picture; hold-free
turns roads and demolishing into two clicks, workers into click-to-carry and the pan into a toggle. Interface size is a registry in
`ui_kit.js` (FB-0042); the HUD moves the inspector, goods table, charts and help clear of the right column and the build bar.

**Gamepad cursor.** The first move of a stick or press of a button makes `input.lastDevice` `"gamepad"`; `scripts/ui/pad_cursor.js` then
draws a reticle and `scripts/game/pointer.js` moves it with the left stick (faster the further it is pushed). A clicks the widget or map
cell under it, B is Escape and puts the tool away, the shoulders open the build menu and switch its tabs, the right stick pans and the triggers
zoom. The widget under the cursor takes the focus, so it works on every panel, the title and the options screen; over nothing the focus
rests on an invisible sink widget (FB-0044). The pointer has two clicks where a mouse drags (see hold-free). `gamepad_game.test.js` plays
build, inspect, fill an order and answer an event card with the pad only.

Fix in P6: a notice that repeats (`x3`) shows the number as it is now, not the number of the day it was first pushed.

Tests: `sound.test.js`, `options.test.js`, `gamepad_game.test.js`, and the two layout tests in `ui_layout.test.js`. Engine gaps found:
FB-0040 to FB-0046 in `ENGINE_FEEDBACK.json`; FB-0015 was withdrawn (the documented behaviour).

## Languages (P8)

**Languages.** English (the reference), Spanish, French and Simplified Chinese: `locales/en.json`, `es.json`, `fr.json`, `zh-Hans.json`, listed in
`factoria.json` `localization`. Every string is translated, the data-driven names too (goods, buildings, ships, events, story cards,
scenarios, achievements and the store texts). The Language tab names each language in its own script (`i18n.name`). The first run starts in the player's system language when it is one of the four (the engine does that; a headless run
starts in English), and the Language tab of the options screen cycles through them: it applies at once, is saved in the `settings`
and the next run starts with it. A save holds ids and numbers, never words, so a game saved in Spanish loads in Chinese
(`tests/languages.test.js`).

**Formatting.** Every number, amount, list and date the player sees is written by `scripts/game/format.js`; no screen formats by hand.
The digits, the thousands separator and the decimal mark come from the engine (`i18n.number`: `12,345.5`, `12.345,5`, `12 345,5`). What a
language writes in its own way is a string in its table, so a new language needs no code: `number.units` (`"1000=k;1000000=M"`,
`"10000=万;100000000=亿"`), `format.list` (the separator of a list), `amount.coins` and `amount.villagers` (plural entries), `amount.good`
(`{n} {name}`, `{n} × {name}`, `{name}×{n}`), `hud.date` with `season.date.<season>`. Plurals use the language's rules: French counts 0 and
1 as singular, Chinese has one form. Spanish and French have grammatical gender and the engine has none (FB-0061), so the data-driven
names are nouns or phrased so that no agreement is needed.

**Chinese font.** DejaVu Sans, the engine's font, has no Chinese. `assets/fonts/NotoSansSC-Regular-subset.ttf` (Noto Sans SC, SIL Open
Font License 1.1, `assets/fonts/OFL.txt`, recorded in `assets.json`) is a subset of 1190 characters, 340 KB, listed in `localization.fallbackFonts`
so it covers every Text of every language. `factoria validate` checks every string of every language against the fonts of the chain and fails
with the missing character (`U+9F98`) and the key. Rebuild after adding or changing Chinese strings:
`python3 assets/fonts/make_subset.py --source <NotoSansSC[wght].ttf>` (fontTools needed only for this; the source font is 17 MB and not in the repository;
`--check` lists the missing characters without writing). It keeps every character of `locales/*.json`, ASCII, Latin-1 and the punctuation line breaking needs.

**Add a language.** Copy `locales/en.json` to `locales/<tag>.json` and translate it (keep the `{placeholders}` and the `[b]`, `[c:..]`,
`[icon:..]` markup of the rich strings; `tests/languages.test.js` compares both with English, key by key), add the tag to `localization.languages`
in `factoria.json`, give it `number.units`, `format.list`, the `season.date.*` strings and the plural forms of `amount.*`, and, when it needs
glyphs the fonts lack, a font in `localization.languageFonts`. Then `factoria validate` and `factoria test`. The key names of the help panel
(`ui.help.keys.*`) are strings too: the labels of the keys that have words (Del, Esc / Q / right-click, Space) are translated, the letters are not.

**Text size and the layouts.** The text size option has four steps (100, 125, 150, 200%). Texts and buttons carry `maxTextScale` (`TEXT_CAP` 1.5
in `ui_kit.js` for labels and buttons, 1.25 for headings and for the rich text of the order board and the cards, `RICH_CAP`) and `autoShrink`, so
200% makes the text bigger where there is room and no bigger where the box is fixed; panels that grow (the goal panel, the goods table) are
placed from the measured size, the goal panel under the bottom of the right menu column. The order board and the cards are laid out by script, so they redraw when the
language or the text size changes. `tests/languages_layout.test.js` opens each screen the way a player does (title, credits, slots and the
scenario list, every options tab, the HUD with the inspector open, goods table, charts, help, notices, order board, every event and story card as
asked and as answered, goal panel, win screen, pause menu), switches to each language at 100% and 200% while the screen is open, and fails
on a text that does not fit its box, a text that leaves the screen or two texts that overlap (`tests/layout_helper.js`; `ui.check_layout` finds
only one issue left, in the engine's pseudo-language at 200% on the stress scene).

Known limits: an achievement toast shows the language it was made in until it disappears; the pseudo-localisation of `ui.check_layout` makes the date
overlap the villager count on the stress scene at 200%. Tests: `languages.test.js`, `languages_layout.test.js`. Engine gaps found: FB-0060 to FB-0065
in `ENGINE_FEEDBACK.json`; FB-0005 (the menu kit's loading screen writes English over the localised Text) is worked around here and the loading text is a string
of every language.

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
