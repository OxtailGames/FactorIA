# Burrow Brigade

A top-down 2D mining game for up to four players on one screen (couch co-op), for desktop first and Steam. Dig dirt and
rock with a pick, take the ore, keep your lamp alight with oil cans, free the moles trapped in the rock, and ride the lift
up before the dark gets you. It is the third reference game of the FactorIA engine (milestone M28), built in eight
packages (P1 to P8). P1 (the miner, digging and the mine), P2 (the world and its enemies), P3 (couch co-op), P4 (camp,
progress and saves), P5 (Steam and online), P6 (sound and options), P7 (shipping) and P8 (languages) are all in; the contracts below are
what each part offers the others.

## Run

```bash
factoria validate
factoria run                      # windowed
factoria run --headless --frames 120 --screenshot-at 119
factoria test                     # headless tests
factoria call project.mine_preview '{"seed":1234}'    # a generated mine as text, with its hash
```

Flow: title -> slots (Play, Continue, Daily dig or a seed code) -> the **join screen** (`scenes/join.scene.json`) -> shift
(`scenes/shift.scene.json`, a generated mine) -> results (`scenes/results.scene.json`) -> camp (`scenes/camp.scene.json`, the
shop) -> the next shift. Every way into a run from the title passes the join screen, which goes on to the shift or, for a
continued run, the camp; the camp goes straight to the next shift with the same players. The loading screen
(`scenes/loading.scene.json`) sits between scenes. `scripts/game/progression.js` decides what follows a shift. A victory over
the Mole King starts a new run in the same slot at once (no camp); a daily dig goes back to the title instead. `scenes/test_mine.scene.json` is a small handmade mine the tests use (its layout is in `tests/helpers/mine.js`);
it is not in the player's flow.

## Controls

**Joining**: after a way into a run on the title (a slot, Continue, the daily dig or a seed code), each device joins with **A** (pad) or **Enter** (keyboard) and leaves with **B** or **Escape**. The first
player to join starts the shift with **Start** (pad) or **Enter** (keyboard). B or Escape with nobody joined goes back to the
title. Up to 4 players, each with a colour and a name (P1 to P4): one keyboard and three pads work, and so do four pads. A pad
plugged in while the screen is open joins like any other (that is how a Steam Remote Play Together guest arrives); a joined pad
that is unplugged here leaves.

A player who joins on the keyboard gets the whole keyboard (below); the others get their pad.

| Action | | Keyboard | Gamepad |
|---|---|---|
| Walk (4 directions) | WASD / arrows | left stick or d-pad |
| Dig (hold, facing a tile; Options > Access can make it press to start, press to stop) | Space / J | A or X |
| Place a torch | T | B or Y |
| Revive a downed friend (hold dig next to them) | Space / J | A or X |
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
miner makes a "blocked" sound. Bedrock never breaks. Each player rebinds their own keys and buttons in
Options > Controls (a button cycles Player 1 to 4; click an action, then press the key or button; a key replaces the keyboard list, a
button replaces the pad list of that action). The engine keeps each player's bindings (`input.player(seat)`) and the game saves
them by seat in `settings.playerBindings` (what an older version saved as left/right/up/down is moved to the project's
`move_left`... names the first time it loads, with a note in the log).

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
  `allDown` (nothing is banked).
- **Revive**: a miner who stands next to a downed friend (within 24 units) and holds dig fills a bar over the friend for 3 s (two
  friends fill it twice as fast); the bar empties 1.5 times faster than it filled when nobody holds. The friend gets up with one
  heart and 2 s of grace (`playerRevived`). A downed miner **does not bleed out**: it lies there until a friend comes or the shift
  ends, so the last miner standing is the one who can still pick the others up. Reviving does not dig or swing the pick.
- **Camera**: one shared camera follows the miners and zooms out as they spread, up to 1.5 times the normal view. A **leash**
  stops a miner from walking farther from the others than that view shows (a miner who is already far can always walk back).
  The engine has one camera only, so a real split screen is not drawn: `camera_views.js` plans the 2 to 4 views (clusters,
  viewports, hysteresis) and tests it, ready for when the engine can draw them (ENGINE_FEEDBACK FB-0013).
- **A pad unplugged mid-shift** pauses the game with "Reconnect the controller for P2". Plugging it back resumes. Any other free
  pad (A) or the keyboard (Enter, when nobody uses it) takes the miner over, and another player drops the missing one with Y (pad)
  or Backspace (keyboard): that miner leaves the mine and the shift goes on.
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

## Options (P6)

Options has five tabs; every row works with the mouse, the keyboard (arrows or Tab, Enter) and a gamepad (d-pad, A, B to go back),
is applied at once and saved in `settings` (`scripts/settings.js`). The texts are `locales/<language>.json` keys (English, Russian, Thai: see Languages below) and
the rows grow with the text size.

- **Video**: window mode (windowed or full screen), window size, vsync, frame cap, colour filter. The engine has no borderless
  mode apart from its full screen (which is the window covering the monitor) and no monitor choice, so the monitor row only shows
  the monitor's size (ENGINE_FEEDBACK FB-0027). Without a real window (headless, a test) the window rows are greyed out and a note says why.
- **Audio**: a slider per bus (master, music, effects, interface), read menus aloud, subtitles.
- **Controls**: rebinding per player.
- **Access**: sound captions (off by default), reduced flashing (starts from the system's "reduce motion"), game speed (100, 80 or
  60 %), and for each player (Player 1 to 4) dig as hold or as press to start, press to stop.
- **Language**: one row that cycles English, Русский, ไทย; every text on every screen changes at once and the choice is saved in
  `settings.language`.

Sound captions: a cue such as a beetle's bite, a cave-in, the lamp running low or the mole's call writes a short line
("Beetle bite! (right)", the direction seen from the nearest miner) in the bottom middle of the screen, clear of the four players' bars at the bottom left and of the HUD text at the top. The line stays 2.5 s and the list keeps two lines.

Reduced flashing: magma light and torch light stay nearly steady and the cave-in warning brightens slowly instead of blinking six times a second.
Dig toggle: a press turns the dig on, the next press turns it off; it also ends when the miner goes down, reaches the lift or a new shift starts.

Game speed (assist) sets `time.scale` for the shift (so movement, enemies, timers and the oil all slow down together; the clock is
the engine's, so a slow shift is as deterministic as a normal one) and puts the speed in `shiftStarted`. DECISIONS: the daily dig can be
played at any speed (it is the same seed and mine), but a run with a shift played slower than 100 % **does not post to the boards**
(`boards.status().assisted`): a board compares players, and an assist is not a rival's score. Cash, trophies and the local results
still count. The flag starts again with a run continued from a save, so a Continue followed by normal-speed shifts posts again.

Colour-free ore and hazards: each ore and hazard tile carries a small white shape with a dark outline in its top-left corner (copper a disc,
silver two bars, gold a triangle, a gem a diamond, water waves, magma a cross, a cracked floor an exclamation mark), the same in every
stratum; `assets/src/make_markers.py` paints them after `make_atlases.py`. Checked with a greyscale screenshot.

## Shipping (P7)

`SHIPPING.md` has the settings, the Steam backend, the exports and what could not be checked. Short: `store/` holds the store
texts in English, Russian and Thai (`python3 store/check_store.py` checks the Steam limits) and `store/make_store.py`, which
rebuilds the 1920x1080 screenshots, the key art, the Steam and itch.io capsules and the trailer from input replays of four
bots (`store/replays/`); the busiest floor (`scenes/busiest.scene.json`, four miners, every torch) is what `perf.json`,
the engine's perf file and `tests/render_budget.test.js` measure; `factoria export --platform macos --release` gives
the app. The Steam plugin is built per machine with Valve's SDK and is not committed.

## Languages (P8)

English, Russian (`locales/ru.json`) and Thai (`locales/th.json`), all with the same key set (`tests/languages.test.js` fails on a missing or
extra key, a changed `{placeholder}` or a plural that is not one). The first start uses the player's system language when it is one of
the three (the engine does that; the game keeps `settings.language` null until the player chooses); a saved choice wins.
Options > Language cycles the three with the mouse, the keyboard or a gamepad. Scripts that write their own text (Options rows, the
slots, boards, camp prices) rewrite it on `i18n.on("change")`.

- Russian plurals have `one`, `few`, `many`, `other` (daily tries, slot coins, miners in the presence line, volume percent).
- Thai: the engine wraps only at spaces, so the Thai table has a real space between phrases and never a space-free run over 16 base letters
  (`tools/thai_spaces.py --check`, a test). The font is `assets/fonts/NotoSansThai-Regular-subset.ttf` (SIL OFL 1.1, `assets/fonts/OFL.txt`; rebuilt by
  `assets/fonts/make_subset.py`, which keeps U+0E4D because the engine draws sara am as two letters: FB-0037). Engine gaps: FB-0036 (no Thai
  word breaking), FB-0037, FB-0038 (`ui.check_layout` and ScrollLists).
- Text size: every screen was checked at 100 % and 200 % (`ui.textScale`) in the three languages: panels that fit their content
  (`fit`), a column or grid fallback when a row gets too wide (`fallbackLayout`), `maxTextScale` on headings, `autoSize` on buttons, scrolling
  lists for the camp shop and the Options rows, and a modal consent card on the title at big sizes. `tests/layout.test.js` covers it;
  `screenshots/` has a few looks.

## Layout

```
factoria.json              input actions, the title as main scene
scenes/                    menu, loading, join, shift, results, camp, test_mine
prefabs/                   miner, mole, enemy, ui/options, ui/pause
scripts/game/              the game: see Contracts (P4: upgrades, save, cloud, daily, seed_code, clipboard, floors, suggest)
scripts/                   menu kit (main_menu, pause_menu, loading, settings, ui/*), results.js and camp.js
scripts/join.js            the join screen
scripts/ui/title_flow.js   the title's Continue, slots, delete confirmation, cloud sync, daily and code panel
tools/mine_preview.js      project.mine_preview: a mine as text
tests/                     the test files of the table below; helpers/ (mine, world, bot, camp, online: a fake game server) and
                           fixtures/ (save_v1, save_v2, news, balance)
assets/                    tiles_topsoil/crystal/magma.png, sprites.png, fog.png (+ src/make_atlases.py, then src/make_markers.py), music/*.wav
                           (+ src/make_music.py, src/make_music_layers.py), audio/*.wav,
                           achievements/*.png and glyphs/<family>/*.png (+ src/make_online_art.py)
locales/en.json            every string of the UI
scripts/title_online.js    the title's online parts; scripts/ui/boards.js the boards screen
```

## Contracts (for P4 to P8)

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
"lift" | "down", cause)`, `ensureOne()`, `clear()`, `MAX_PLAYERS` (4), `PLAYER_COLORS`, `KEY_SCHEMES` (the names of the key schemes). A player is `{ id, name, device, color,
state, hp, invulnerable }` (`MAX_HP` is 3). The shift spawns one miner per registered player (`prefabs/miner.prefab.json`, prop `playerId`) and the HUD shows one
oil bar each. `device` decides which input moves the miner (`scripts/game/miner_input.js`): `{ kind: "any" }` (the project's
actions: keyboard and every pad; one player only, the title's Play uses it), `{ kind: "keys", scheme: "wasd" | "arrows" | "ijkl" }`
or `{ kind: "pad", index }` (left stick or d-pad, A or X to dig, B or Y for a torch). The registry gives a keys or pad player to
the engine as `input.player(id).use({ keys: scheme })` or `use({ pad: index })` (factoria.json `input.schemes` defines the four key schemes) and
`miner_input.js` reads `input.player(id)`; a player on `any` reads the global input. `tests/input.test.js` drives two keyboard players and a second pad at
once. `setState` emits `playerState` and, for `"down"`, `playerDown`; a miner that is `down` does not move, dig or burn oil and
the shift's end check ignores it. `hurt` takes hearts and sets `down` at 0 (`playerHurt` is emitted); the hazards set `down`
directly with the cause "drowned", "burned" or "caveIn". `revive(id, by)` (REVIVE_HP 1, REVIVE_GRACE 2) gets a downed player up and emits
`playerState` and `playerRevived`; `setDevice(id, device)` changes a player's device (emits `playerDevice`). The device `scheme`
can also be `"keyboard"` (the whole keyboard, what the join screen gives). `scripts/join.js` fills the registry (it clears it first).

### Per-player input: `scripts/game/controls.js`

The engine does the per-player actions (`input.player(seat)`: its own device, its own bindings; docs: scripting, input); this module is
the game's side: `bindingsFor(seat, family)` (the six actions of a miner with their bindings), `rebind(seat, "keys" | "pad", action,
names)` (saved with `export()`; the same names are taken from the seat's other actions; a name the player's device cannot use throws the
engine's error), `reset(seat)`, `resetAll()`, `applySaved()` (called by `settings.apply`: imports what was saved, renaming the old
format), `label(...)`, `ACTIONS` (left, right, up, down, dig, torch). Names are the ones `input.lastPressed()` returns.

### Revive, camera and pads: `revive.js`, `camera_views.js`, `pad_watch.js`

`revive.hold(reviverId, at, dt)` (called by the miner holding dig), `progressOf(id)`, `REVIVE_TIME`, `REVIVE_RANGE`. `camera_views.js`:
`ViewPlanner.plan(points)` returns `{ mode: "shared" | "split", views: [{ players, center, ortho, viewport }] }`, `current` is the plan the
camera follows, `limitMove(id, from, to)` is the leash and `config.tether` turns it off. `pad_watch.js` is a Script of the shift scene
(`runWhilePaused`) that pauses on a missing pad and emits `controllerLost` and `controllerRestored` (`how`: reconnected, handedOver or dropped).

### Game events: `scripts/game/events.js`

A synchronous bus in a module singleton (it outlives scenes, unlike scene-bound listeners): `on(name, fn)` returns the
unsubscribe function, `emit(name, data)`, `count(name)`, `emitted(name)`, `clear()`, `history`. An unknown name throws with a
"did you mean". `EVENTS` documents every name and its data. P1 emits `shiftStarted`, `dug`, `digBlocked`, `orePicked`,
`oilPicked`, `lampLow`, `lampOut`, `liftReached`, `moleRescued`, `shiftEnded`, `playerAdded`, `playerRemoved`, `playerState`,
`playerDown` and `tileChanged`. P2 adds `hazardTriggered` (`kind` flood, magma or caveIn; `phase` start, spread, impact or hit),
`playerHurt`, `torchPlaced`, `enemyHit`, `enemyDefeated`, `oreStolen`, `oreRecovered`, `thiefEscaped`, `bossStarted`,
`bossDefeated` and `exitJammed`. P3 adds `playerRevived` (`player`, `by`, `hp`), `playerDevice`, `controllerLost` and
`controllerRestored`; `shiftEnded` can now carry the outcome `allDown`. P4 emits `upgradeBought` (`upgrade`, `level`,
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

### Music, mix and sound: `scripts/game/music.js`, `mix.js`, `sound.js`

All music goes through `music.js` (nothing else calls `audio.music`). `play(stratum)` starts the stratum's looping track with a fade-in
and returns whether the track differs from the last one; the shift calls it at every start because a scene load stops the audio.
`current()`, `forStratum(n)`, `layerPath(stratum, layer)`, `layers()`, `stop()`, `reset()`.

**Layers (emulated, FB-0025).** The engine has one music stream and cannot change a playing voice's volume, so each stratum has two
one-bar loops (`music_<stratum>_danger.wav`, `_fight.wav`, made by `assets/src/make_music_layers.py`). A layer starts at the next bar
line of the real-time music clock and stops at a bar line, so it stays in time. The *danger* layer follows a chase (an enemy sees
a miner or saw one less than 3 s ago, or the Mole King is awake) and stays 1.5 s after it ends; the *fight* layer follows an enemy
winding up or within 56 units of the miner it chases, or a miner hurt in the last 1.5 s. The music driver entity (`music` in the
shift scene) is the one behaviour that ticks every frame, also while paused.

**Mix (emulated, FB-0026).** `mix.js` is the only code that calls `audio.setVolume`: bus volume = the player's slider
(`settings.volume`) x the snapshot's factor x the duck, eased over 0.2 s. Snapshots: `normal`, `paused` (music 0.45, effects 0.35),
`underwater` (half or more of the miners in water: music 0.55, effects 0.6) and `cavern` (85 open tiles in the 11 x 11 window around the miners; a cued
sound is replayed once, 0.22 s later at 0.3 volume, as a cheap echo). Muffling is only quieter, because there is no filter. A cue with
`duck` seconds (the cave-in rumble, the Mole King's slam) lowers the music under it. `duck(seconds, depth)`, `snapshot(name)`, `level(bus)`.

**Sound cues (`sound.js`).** Effects of a shift go through `sound.play(path, opts, cue)`; a cue `{ key, x, y }` (or `tx, ty`) puts a
caption with a direction on the caption list (`game.captions()` in a test) and the `sound_captions` entity draws it when the option is on.

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
nothing). **Contract with P4**: a daily-dig run sets `run.mode = "daily"` and `run.dailyKey = "YYYY-MM-DD"` (the local date the
try began on); every other run `run.mode = "normal"` and `run.dailyKey = null` (a missing `run.mode` counts as normal). The daily
board takes the score only when `run.dailyKey` is within one day of `game.today().iso`: the engine posts to the board of the
local date at the moment of the post and cannot be told another (FB-0021), so a try that crosses midnight still posts (to the new
day's board) and an older key is skipped, with `status().lastPost.daily` saying `{ skipped: "otherDay" }`. Functions: `start`, `stop`, `idle`, `top(board, count = 10)`
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
| `coop.test.js` | the join screen with four pads, a keyboard and three pads, keyboard only and gamepad only, a Remote Play guest pad plugged in mid-lobby, a whole shift played by the bot through the join, reviving (bar, decay, no bleed-out, `allDown`), per-player rebinding (API and the Options page), the camera zoom, the leash and the split planner, a pad unplugged (pause, reconnect, hand-over, drop) |
| `bot.test.js` | a bot that presses keys and pushes sticks clears one floor of every stratum and the boss floor, alone and with four players on four devices, deterministically |
| `trophies.test.js` | each achievement unlocking from events, the four stats, no double unlock, a stratum cleared with and without a lamp going out, a store that is not there |
| `boards.test.js` | cumulative run cash on the all-time board, `dark` and `allDown` posting nothing, a daily dig on both boards, a new day, a key a day or two before today, a missing `run.mode`, an empty store |
| `presence.test.js` | the text with one and many miners, boss, results, menu and boards, the `steam_display` tokens, no repeated text |
| `glyphs.test.js` | `setType` for each family, the Deck's L1/R1, the keyboard fallback, every picture exists |
| `news.test.js` | the fixture parsed, the cap and the order, dropped items, the language object, the cache offline |
| `balance.test.js` | values applied, out-of-range, wrong type and unknown keys rejected with hints, held during a shift, the offline fallback, `reset` |
| `analytics.test.js` | nothing queued or sent without consent, the events after a yes, quit, a failed send, revoking |
| `deck.test.js` | Deck detection, the 1280x800 fit, suspend and resume, the text-entry helper |
| `languages.test.js` | the three string tables (same keys, placeholders, plural forms), Russian plurals on real counts, the Thai break rule, the language row by mouse, keyboard and gamepad, saved, a saved choice over the start language |
| `layout.test.js` | every screen, panel and Options tab in en, ru, th at 100 % and 200 %: nothing overflows, leaves the screen or overlaps; `ui.check_layout` over the scenes |
| `online_ui.test.js` | the title's news, the consent card, the hints row, leaving the title mid-request, the boards screen with the mouse and a pad, the Options switch |
| `sound.test.js` | the music layers rising in a chase and falling after it, bar-line starts, the mix (ducking, paused, underwater, cavern echo, user sliders), the sound captions with their direction and the option |
| `access.test.js` | hold and toggle dig per player, the game speed (`time.scale`, the event, no board post when assisted), reduced flashing, the Options > Access tab with mouse, keyboard only and gamepad only, the greyed Video rows |

## Assets and credits

| File | Source | Licence |
|---|---|---|
| `assets/tiles_topsoil.png`, `assets/tiles_crystal.png`, `assets/tiles_magma.png`, `assets/sprites.png`, `assets/fog.png` | Kenney, [Tiny Dungeon](https://kenney.nl/assets/tiny-dungeon) and [Roguelike Caves & Dungeons](https://kenney.nl/assets/roguelike-caves-dungeons), cut and re-packed by `assets/src/make_atlases.py`; the mole, the arrows, the cracks, the beetle, the thief, the King and the fog are drawn or recoloured by that script (a stratum's tileset is the same tiles in other colours) | CC0 |
| `assets/music/*.wav` | one looping track per stratum, synthesised by `assets/src/make_music.py` (no sample taken from anywhere) | CC0 |
| `assets/achievements/*.png`, `assets/glyphs/<xbox, playstation, nintendo, steamdeck>/*.png` | six trophy icons and the button pictures of four pad families, drawn by `assets/src/make_online_art.py` (64 px, deterministic, no outside image) | CC0 |
| `assets/music/music_<stratum>_danger.wav`, `_fight.wav` | the one-bar layers over each stratum's track, synthesised by `assets/src/make_music_layers.py` | CC0 |
| `assets/fonts/NotoSansThai-Regular-subset.ttf` | Noto Sans Thai, cut to the glyphs of `locales/th.json` by `assets/fonts/make_subset.py` | SIL OFL 1.1 (`assets/fonts/OFL.txt`) |
| `assets/audio/beetle_alert.wav`, `lamp_low.wav`, `mole_call.wav` | the cue sounds of P6, made with `assets.synth_sound` | CC0 |
| the ore and hazard shapes inside `assets/tiles_*.png` | stamped by `assets/src/make_markers.py` over the Kenney tiles | CC0 |
| `assets/audio/*.wav` | made with `assets.synth_sound` (presets footstep, hit, coin, pickup, error, powerup, whoosh, click, growl, explosion, splash, laser) | CC0 |

`assets.json` records the provenance of each file. The engine gaps found while building P1 to P7 are in `ENGINE_FEEDBACK.json`.

## Status

| Package | What | State |
|---|---|---|
| P1 | The miner, digging and the mine | done |
| P2 | World and enemies: the three strata and their hazards, torches and crystals, enemies that chase through the dug tunnels, music per stratum, a bot that clears floors | done |
| P3 | Couch co-op: join screen, per-player devices and bindings, shared then split camera, revive, a pad unplugged, Remote Play Together | done (the split view is planned and tested, not drawn: one camera in the engine) |
| P4 | Camp, progress and saves: the upgrades shop, Continue, 3 versioned save slots with migration, cloud saves, the daily dig, seed codes | done |
| P5 | Steam and online: achievements, stats and boards, rich presence, Steam Deck, glyphs, news, remote balance, opt-in analytics | done (news, balance and analytics go through a seam with no real transport: the engine has no HTTP) |
| P6 | Sound, options and accessibility: music layers, bus effects, captions, display options, game speed, reduced flashing | done (music layers, the mix and the cavern echo are emulated: FB-0025, FB-0026; no borderless mode or monitor choice: FB-0027) |
| P7 | Shipping: icon and store art, store texts, screenshots and trailer, desktop exports, budgets, SHIPPING.md | done (macOS export run here; Windows and Linux exports built, not run; the Steam plugin and app 480 check are manual: `SHIPPING.md`, FB-0028 to FB-0035) |
| P8 | Languages: Russian and Thai, every screen at 100 % and 200 % text | done (Thai cannot be wrapped by words: FB-0036; sara am glyph: FB-0037; check_layout and ScrollLists: FB-0038) |
