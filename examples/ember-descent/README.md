# Ember Descent

A four-floor roguelike made with FactorIA to show the level generator. Walk down through four dungeon floors, pick up
coins, step around the spikes and reach the stairs. Every floor is a new level that `tilemap.generate` (Wave Function
Collapse) grows at run time from the one drawn in `levels/sample.json`, so the dungeon looks hand-made and is different on
every run. One number, the run seed, is one whole dungeon.

```bash
factoria validate                                        # project checks
factoria test                                            # headless tests
factoria run                                             # play in a window
factoria run --headless --frames 120 --screenshot-at 119 # headless frame capture
```

Controls: arrow keys or WASD move one cell per press; click or tap beside the hero to step that way. R plays the same
dungeon again (same seed). Space, a click or a tap starts a new dungeon after you win or fall.

- Rules: 3 lives; a spike costs a life and is spent; a coin is 10 points; each floor left is 50. The stairs are the floor cell
  farthest from the start by walking; spikes are scattered, so a way around them is the usual case (the tests walk one on
  eight run seeds) but the generator does not promise it.
- `levels/sample.json`: the example the generator learns from, in the `scene.import_ascii` format (rows + legend):
  `#` wall, `.` and `,` floor, `o` coin, `x` spikes, and two glyphs that are only in the `legend`, `@` (the player) and `>`
  (the stairs): the rows never draw them, `constraints.place` puts them on the finished floor. It is an open cave with
  pillars: a sample of rooms joined by one-cell corridors would almost never pass `reachability.allConnected`.
- `scripts/dungeon.js`: the game. It draws the four floor seeds from `rng.create(runSeed)`, calls `tilemap.generate` with
  `place` (the Tilemap, the coins, the spikes, the player and the stairs become entities) and polls the handle each frame, so the game keeps
  drawing while a floor grows. The handle belongs to the scene: a reload or a restart ends it, and nothing is placed.
- `art/tiles.sheet.js` + `assets/tiles.png`: the three tiles (wall, floor, cracked floor), drawn by code with
  `assets.animate_svg`; `assets.json` has their provenance. The player, coin, spikes and stairs are `Shape2D` prefabs.
- `tests/dungeon.test.js`: the game headless: border, free start and stairs, the stairs farthest from the start, a
  trap-free route to them on eight run seeds, determinism (same seed, same dungeon), moves,
  coins, spikes and the loss, four floors to a win, R, R and a reload while a floor is growing, and a tap.
- `ENGINE_FEEDBACK.json`: engine gaps found while building this game.

## What the generator does and what the script does

The generator makes the walls, the floor, the coins and the spikes (things that repeat) and, through
`constraints.place`, exactly one player start and one set of stairs: the player on any floor cell and the stairs
`"where": "farthest"` from it, measured by the walk `reachability` describes. A glyph that is unique in a sample repeats
in the result, so those two are not drawn in the sample, only named in its `legend`. `constraints.counts` with `max`
steers the solver (the coins stop at 12, the spikes at 8). `docs/AI_GUIDE.md` section 9.8, "Generate the level, or write
its ASCII by hand?", says when to do which; this game is "generate": any floor of this style will do, and the border,
the counts and `reachability.allConnected` say what makes one bad. What the script still decides is the rules: the
moves, the lives and the score.

Try it in the editor: open the project, select nothing, View > Level generator, type `levels/sample.json` as the sample file,
size 36 x 18, `n` 3, extra options `{"constraints": {"border": {"tile": "#"}}, "reachability": {"allConnected": true,
"solidTiles": [0]}, "maxAttempts": 40}` and press Next seed.
