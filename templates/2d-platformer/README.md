# {{PROJECT_NAME}}

A FactorIA 2D platformer starter: run, jump and collect coins on a tile level that scrolls with a follow camera.
The level is an ASCII map; the art is a tiny tileset (`assets/tileset.png`) plus `Shape2D` for the player and the
coins, and there are two small sounds (jump, coin). It is a complete game shell: a main menu, a loading screen, a pause
menu, options (video, audio, controls) saved between runs, and credits. Everything works with a keyboard, a mouse or
only a gamepad.

```bash
factoria validate
factoria run
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

- `levels/level1.json` the level as an ASCII map: the arguments of `scene.import_ascii`, the source of truth of its tiles, coins and player spawn
- `scenes/menu.scene.json` the main menu (Play, Options, Credits, Quit), the start scene (`mainScene` in `factoria.json`)
- `scenes/loading.scene.json` shown while Play loads the level
- `scenes/main.scene.json` the camera, the HUD, the pause overlay and the level built from that map
- `prefabs/` `coin.prefab.json` and `player.prefab.json`, placed by the map; `ui/options.prefab.json`, the options
  panel of both the main menu and the pause menu
- `assets/` `tileset.png` (32x32 tiles: grass 0, dirt 1, brick 2, flowers 3) and `sfx/jump.wav`, `sfx/coin.wav`
- `scripts/player.js` run/jump/collect (plays the sounds), `follow_camera.js` (follows on both axes, stays inside the map), `hud.js` (listens to `coin_collected`)
- `scripts/main_menu.js`, `pause_menu.js`, `loading.js`, `ui/options.js`, `ui/credits.js` the menus;
  `ui/menu_stack.js` opens panels over each other and goes back (B, Escape or a button tagged `back`);
  `settings.js` loads, saves (`storage`) and applies the player's settings at start
- `tools/spawn_coin.js` project tool: `factoria call project.spawn_coin '{"x":300,"y":200}'`
- `tests/platformer.test.js` movement, jumping, coins, sounds (`game.audioLog()`), camera; `tests/level.test.js` the scene is what the map builds, and canonical layout;
  `tests/menus.test.js` the menus driven with gamepad presses only (options, saved volume, rebinding, pause, credits)

## Editing the level

1. Edit `levels/level1.json`. `rows` is the map, one character per tile, top row first. The `legend` says what each
   character is: `#` grass, `%` dirt, `=` brick, `*` flowers (drawn, not solid), `o` a coin, `P` the player, `.` empty.
2. Rebuild the scene with one command, from this folder: `factoria call scene.import_ascii @levels/level1.json`.
   It rewrites the map and re-places the coins and the player in `scenes/main.scene.json` (the camera, the HUD and the
   pause overlay stay).
   It never touches a running game, and you do not compute any positions.
3. `factoria validate`, then take a screenshot and look at it. `factoria test` fails if the scene is not what the map builds.

The camera limits are not copied anywhere: `follow_camera.js` reads them from the map (`bounds: "map"`), so a bigger or
smaller map needs no other change. After editing prefabs or scenes by hand, `factoria call scene.format` puts them in
the canonical layout (`'{"check":true}'` only lists what is not).

## Menus

The menus are UI widgets (`Panel`, `Button`, `Toggle`, `Slider`, `ScrollList`) in screen space; `factoria docs read
components` lists their fields. The first button of a panel has `autoFocus`, so a gamepad or the arrow keys work at once;
scripts react with `ui.on("click", "play", fn)`. To add an option: add a widget to `prefabs/ui/options.prefab.json`, read
and write its value in `scripts/ui/options.js`, and keep it in `scripts/settings.js` (`DEFAULTS` and `apply`). The
Language tab is a placeholder until FactorIA has localization.

Ideas to extend: enemies (a patrol script, AI guide section 9.14), a goal that loads the next level (a second
`levels/level2.json` with its own `path`), one-way ledges (`Collider2D.oneWay`), particles when a coin is collected.
