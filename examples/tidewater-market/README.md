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
| P2 | Production, workers, the running clock and its speed control | planned |
| P3 | Prices, markets, trade | planned |
| P4 | Population, housing, happiness | planned |
| P5 | Contracts and goals | planned |
| P6 | Saving, loading, the shop menu | planned |
| P7 | Finished art and sound under the same frame names | planned |
| P8 | Translations (es, fr, zh-Hans), accessibility, polish | planned |

## How to play (P1)

The title screen has Play, Options, Credits and Quit; Play goes through the loading scene to the map. Everything can be done
with the mouse.

| Input | Does |
|---|---|
| Palette button (right), or keys 1-9 | Pick a building; the cell under the mouse shows a ghost, green when it can go there and red with the reason in the status line when not |
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
| `data/*.json` | The tables: `terrain`, `goods`, `recipes`, `buildings`, `economy` (start, refund, undo limit, calendar), `map` (generator settings), `test_map` (a 12 x 10 map for tests), `atlas` (frame rectangles). Validated against each other, the atlas and the locale strings when the game starts, and by `project.validate_data` |
| `scripts/game/` | Pure logic with no engine calls: `iso`, `events`, `mapgen`, `map`, `rules`, `economy`, `clock`, `state`, `data`, `format`, `camera_math`. Behaviours: `game_controller`, `camera_rig`, `map_view`, `title_backdrop` |
| `scenes/` | `menu` (title), `loading`, `game` |
| `locales/en.json` | Every text the player sees. Nothing is hard-coded in a script |
| `assets/atlas.png` | One 2048 x 1024 atlas with every picture the map draws (one atlas is one draw call). `assets/src/make_atlas.py` builds it from the Kenney CC0 images in `assets/src/kenney/` plus placeholder art drawn in the script; `assets.json` has the provenance |
| `tools/` | `project.map_preview`, `project.validate_data` |
| `tests/` | map generation, rules, data tables, camera and picking, the pause menu, the mouse-only flow from the title screen, and screenshots to look at |

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
P2 produces goods with `apply(delta, "production")`; P3 sells with `apply(..., "trade")`. Undo gives back exactly what an
action cost or refunded, and is refused when the money is no longer there.

**Game events (`state.events`, a synchronous bus; `on(name, fn)` returns the unsubscribe function, `"*"` hears everything).**
`building.placed` and `building.removed` `{ building, cause }` (cause: `place`, `demolish`, `undo`, `redo`); `roads.changed`
`{ cells }`; `economy.changed` `{ coins, stock, delta, cause }`; `history.changed` `{ canUndo, canRedo, undoLabel, redoLabel }`;
`action.rejected` `{ action, code, reasons }` (refused placement, undo or redo); `clock.speed`, `clock.tick`, `clock.day`,
`clock.season`. A listener that throws is logged and the others still run. A package reacts to the game through these events
and never reaches into the view.

**The clock (`state.clock`).** A stub in P1: speed 0 (paused), so the date in the top bar stays at Spring 1, year 1.
`setSpeed(i)` picks an index of `SPEEDS = [0, 1, 2, 4]`; `advance(dt)` is called by the controller every frame with real
seconds and moves game time by `dt * SPEEDS[speed]`; `date()` gives `{ day, year, season, seasonIndex, dayOfSeason }` from
the calendar in `data/economy.json` (4 seasons of 10 days, 6 game seconds per day). `clock.tick` `{ seconds }` fires on each
advance with a speed above 0 and is what P2 drives production from; `clock.day` fires once per `advance` call that crosses a day
boundary, even if the call crossed several days (keep `dt` small, as the frame loop does). `setDay(n)` is for tests and loading.

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
