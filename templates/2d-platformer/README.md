# {{PROJECT_NAME}}

A FactorIA 2D platformer starter: run, jump and collect coins on a tile level that scrolls with a follow camera.
The level is an ASCII map; the art is a tiny tileset (`assets/tileset.png`) plus `Shape2D` for the player and the
coins, and there are two small sounds (jump, coin).

```bash
factoria validate
factoria run
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

- `levels/level1.json` the level as an ASCII map: the arguments of `scene.import_ascii`, the source of truth of its tiles, coins and player spawn
- `scenes/main.scene.json` the camera, the HUD and the level built from that map
- `prefabs/` `coin.prefab.json` and `player.prefab.json`, placed by the map
- `assets/` `tileset.png` (32x32 tiles: grass 0, dirt 1, brick 2, flowers 3) and `sfx/jump.wav`, `sfx/coin.wav`
- `scripts/player.js` run/jump/collect (plays the sounds), `follow_camera.js` (follows on both axes, stays inside the map), `hud.js` (listens to `coin_collected`)
- `tools/spawn_coin.js` project tool: `factoria call project.spawn_coin '{"x":300,"y":200}'`
- `tests/platformer.test.js` movement, jumping, coins, sounds (`game.audioLog()`), camera; `tests/level.test.js` the scene is what the map builds, and canonical layout

## Editing the level

1. Edit `levels/level1.json`. `rows` is the map, one character per tile, top row first. The `legend` says what each
   character is: `#` grass, `%` dirt, `=` brick, `*` flowers (drawn, not solid), `o` a coin, `P` the player, `.` empty.
2. Rebuild the scene with one command, from this folder: `factoria call scene.import_ascii @levels/level1.json`.
   It rewrites the map and re-places the coins and the player in `scenes/main.scene.json` (the camera and the HUD stay).
   It never touches a running game, and you do not compute any positions.
3. `factoria validate`, then take a screenshot and look at it. `factoria test` fails if the scene is not what the map builds.

The camera limits are not copied anywhere: `follow_camera.js` reads them from the map (`bounds: "map"`), so a bigger or
smaller map needs no other change. After editing prefabs or scenes by hand, `factoria call scene.format '{"paths":["prefabs","scenes"]}'` puts them in
the canonical layout (`'{"check":true}'` only lists what is not).

Ideas to extend: enemies (a patrol script, AI guide section 9.14), a goal that loads the next level (a second
`levels/level2.json` with its own `path`), one-way ledges (`Collider2D.oneWay`), particles when a coin is collected.
