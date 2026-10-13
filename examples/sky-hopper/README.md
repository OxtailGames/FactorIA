# Sky Hopper

A FactorIA 2D platformer: run, jump (variable height, coyote time, jump buffering), collect coins, stomp
crawlers, reach the flag. Two hand-made levels, then a generated one, then a win screen. Placeholder sprites and
sounds in `assets/`.

```bash
factoria validate
factoria run                                   # play (A/D or arrows, Space to jump)
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

## What is where

- `scenes/level1.scene.json`, `level2.scene.json`: the hand-made levels. `generated.scene.json`: the third level,
  made by `project.generate_level`. `win.scene.json`, `gameover.scene.json`: the end screens.
- `levels/level1.json`, `level2.json`: the ASCII map of each hand-made level, the source of truth of its tiles,
  coins, crawlers, player and flag. `levels/generator_base.scene.json`: what a level has besides the map (settings,
  camera, `level` script, HUD).
- `prefabs/`: `coin`, `enemy` (crawler), `player`, `goal` (flag). A map spawns them.
- `scripts/`: `player.js` (run/jump/collect/stomp/lives), `enemy.js` (patrol), `goal.js`, `level.js`,
  `follow_camera.js`, `hud.js`, `menu.js`, `game_state.js` (state shared between scenes).
- `tools/generate_level.js`: project tool `project.generate_level`.
- `tests/platformer.test.js`: movement, coins, enemies, goal, game over, camera, sounds (`game.audioLog()`), the
  level generator, and that each scene is what its map builds.

## Levels

A level is an ASCII map plus a legend, in the format of the engine command `scene.import_ascii`
(`factoria docs read ai-guide`, section 9.8). `levels/level1.json` looks like this:

```json
{
  "rows": [ "......o.o....F.", "..P....E.....##", "########..#####" ],
  "legend": {
    "#": 0, "%": 1, "=": 2,
    "o": { "prefab": "prefabs/coin.prefab.json" },
    "E": { "prefab": "prefabs/enemy.prefab.json", "offset": [0, -4] },
    "P": { "prefab": "prefabs/player.prefab.json", "id": "player" },
    "F": { "prefab": "prefabs/goal.prefab.json", "id": "goal", "offset": [0, 16],
           "overrides": { "Script": { "props": { "next": "scenes/level2.scene.json" } } } }
  },
  "entity": "map", "tilemap": { "tileset": "assets/tileset.png", "tileSize": [32, 32], "solidTiles": [0, 1, 2], "layer": -10 },
  "anchor": "bottom-left", "position": [0, 0], "save": true
}
```

(The real files have 16 rows of 60 columns.) `#` is grass (tile 0), `%` dirt (1), `=` a brick platform (2), `.`
empty, `o` a coin, `E` a crawler, `P` the player, `F` the flag. Row 0 is the top row.

**Rebuild a level after editing its map.** From this folder, one `factoria call` per level; `--scene` is the scene
that receives the map and is saved (`"save": true`), so always pass it:

```bash
factoria call scene.import_ascii @levels/level1.json --scene scenes/level1.scene.json
factoria call scene.import_ascii @levels/level2.json --scene scenes/level2.scene.json
```

The command replaces the `map` Tilemap and the objects of the earlier import (tag `tilemap:map`), and leaves the
camera, `level` script and HUD of the scene alone. It writes the scene in the engine's compact layout (one map
row of `tiles` per line, no `columns`: it is derived from `assets/tileset.png`). The ids stay `player`, `goal`,
`coin_1`..`coin_N` and `enemy_1`..`enemy_N` (reading order), which the scripts and tests rely on.

Things to keep in sync by hand: when you change the size of a map, set the camera limits (`maxX` = columns * 32,
`maxY` = rows * 32) in the scene's `camera` entity. A test checks it, and checks that each scene equals what its
map builds, so a forgotten rebuild fails `factoria test`.

**A new level:** copy `levels/generator_base.scene.json` to `scenes/levelN.scene.json`, set `levelIndex` and the
camera limits in it, copy a map to `levels/levelN.json`, edit it, and run the command above for it. Make the
previous level's `F` legend `next` point at the new scene.

## Generated level

`project.generate_level` makes a random level from `width` (tiles), `seed` and `difficulty` (1..5): the same
arguments always give the same level. It composes the ASCII `rows` and a `legend` and builds the scene with the same
`scene.import_ascii` command, so it contains no tile or object coordinates.

```bash
factoria call project.generate_level '{"width":90,"seed":7,"difficulty":3}'      # rewrites scenes/generated.scene.json
factoria call project.generate_level '{"width":40,"seed":2,"dryRun":true}'      # returns rows + scene JSON, writes nothing
```

`scene.import_ascii` edits the running world, so the tool works in a scratch scene: it remembers the loaded scene,
loads `levels/generator_base.scene.json`, imports the rows, saves the result to `path` (with `dryRun`, reads the
entities back with `game.state` instead), and loads the remembered scene again. The running game is therefore
reloaded from its scene file when the tool returns: save unsaved edits first.

The tool keeps its own small PRNG (`mulberry32`) instead of `rng.seed(seed)`: `rng.seed` reseeds the single world
RNG that the running game draws from, and a script cannot read that state back to restore it.
