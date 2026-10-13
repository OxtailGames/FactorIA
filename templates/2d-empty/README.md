# {{PROJECT_NAME}}

A minimal FactorIA 2D game. Open it with an AI agent (read `AGENTS.md`) or run it yourself:

```bash
factoria validate
factoria run                                   # window
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

- `scenes/main.scene.json` camera, a player square, a title
- `scripts/player.js` movement with input actions
- `tools/spawn_box.js` example project tool (`factoria call project.spawn_box '{"x":100}'`)
- `tests/player.test.js` headless tests
