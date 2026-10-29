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
- `prefabs/`: `coin`, `enemy` (crawler), `player`, `goal` (flag). A map spawns them. The player is built in parts
  (child Sprites on a `rig`, Bone2D bones, a SpriteSkin scarf, two IK2D legs) and animated by `anim/hero_*.anim.json`
  through an Animator state machine; `crawler_rig` is the crawler built in parts, baked into `assets/crawler_sheet.png`
  by `assets.bake_sheet` (recipe in `assets.json`; `assets.regenerate` redraws it). The part art is `assets/src/svg`
  (SVG) -> `assets/src/parts` -> `assets/parts_atlas.png`. See docs/ANIMATION.md, "Example: a character built in parts".
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
  "anchor": "bottom-left", "position": [0, 0], "path": "scenes/level1.scene.json"
}
```

(The real files have 16 rows of 60 columns.) `#` is grass (tile 0), `%` dirt (1), `=` a brick platform (2), `.`
empty, `o` a coin, `E` a crawler, `P` the player, `F` the flag. Row 0 is the top row.

**Rebuild a level after editing its map.** From this folder, one `factoria call` per level. Each map file names the
scene it builds in `path`, so no `--scene` is needed and the running game, if there is one, is not touched:

```bash
factoria call scene.import_ascii @levels/level1.json    # "path": "scenes/level1.scene.json"
factoria call scene.import_ascii @levels/level2.json    # "path": "scenes/level2.scene.json"
```

(Without `path` the command edits the running world, and `"save": true` would write the running scene: the engine
refuses that when the running scene is only the default main scene, which is what a plain `factoria call` runs.)

The command replaces the `map` Tilemap and the objects of the earlier import (tag `tilemap:map`), and leaves the
camera, `level` script and HUD of the scene alone. It writes the scene in the engine's compact layout (one map
row of `tiles` per line, no `columns`: it is derived from `assets/tileset.png`). The ids stay `player`, `goal`,
`coin_1`..`coin_N` and `enemy_1`..`enemy_N` (reading order), which the scripts and tests rely on.

The camera limits need no upkeep: `scripts/follow_camera.js` takes them from the `map` Tilemap (`entity.bounds()`,
named by the `"bounds": "map"` prop of the `camera` entity), so a bigger or smaller map moves them with it. A test
checks that each scene equals what its map builds, so a forgotten rebuild fails `factoria test`.

**A new level:** copy `levels/generator_base.scene.json` to `scenes/levelN.scene.json`, set `levelIndex` in it
(the camera follows the map through `"bounds": "map"`; `minX`..`maxY` props would only narrow the map's limits, so
delete them from the copy), copy a map to `levels/levelN.json`, edit it, and run the command above for it. Make the
previous level's `F` legend `next` point at the new scene.

## Generated level

`project.generate_level` makes a random level from `width` (tiles), `seed` and `difficulty` (1..5): the same
arguments always give the same level. It composes the ASCII `rows` and a `legend` and builds the scene with the same
`scene.import_ascii` command, so it contains no tile or object coordinates.

```bash
factoria call project.generate_level '{"width":90,"seed":7,"difficulty":3}'      # rewrites scenes/generated.scene.json
factoria call project.generate_level '{"width":40,"seed":2,"dryRun":true}'      # returns rows + scene JSON, writes nothing
```

The tool calls `scene.import_ascii {path, from, edits, dryRun}`, which edits the scene FILE in a scratch world: the
running game is never touched, so there is nothing to save first or restore afterwards. `from` is
`levels/generator_base.scene.json` and `edits` patch it for this level (sky colour, camera height, level number), so
the tool writes no scratch file and does not read the base scene. The level number is an edit with `"$merge": true`
(a JSON merge-patch): only `levelIndex` changes in the level script's props, `killY` and the rest stay as the base has them. With `dryRun` nothing is written and the scene JSON comes back in `scene`.

The tool draws its random numbers from `rng.create(seed)`, an independent generator: `rng.seed(seed)` would reseed
the single world RNG that the running game draws from. The same seed gives the same level on every platform.
