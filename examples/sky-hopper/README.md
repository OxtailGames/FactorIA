# Sky Hopper

A FactorIA 2D platformer starter. Run, jump, collect coins. No binary assets: everything is
`Shape2D`, so you can restyle it later by swapping in `Sprite` components.

```bash
factoria validate
factoria run
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

- `scenes/main.scene.json` ground, two platforms, player, three coins, HUD, follow camera
- `scripts/player.js` run/jump/collect, `follow_camera.js`, `hud.js` (listens to `coin_collected`)
- `tools/spawn_coin.js` project tool: `factoria call project.spawn_coin '{"x":300,"y":-150}'`
- `tests/platformer.test.js` landing, running, jumping, coin collection

Ideas to extend: enemies, a goal flag that loads the next scene, one-way platforms (the engine
may lack them: record it in ENGINE_FEEDBACK.json).
