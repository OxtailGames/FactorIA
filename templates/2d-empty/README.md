# {{PROJECT_NAME}}

An empty FactorIA 2D project: the scene has only a camera. Build the game with an AI agent (read `AGENTS.md`) or
yourself:

```bash
factoria validate
factoria run                                   # window
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

- `scenes/main.scene.json` the scene (a camera)
- `scripts/` behaviours, `tests/` headless tests (`*.test.js`), `tools/` project tools: empty for now
- `factoria.json` input actions `move_left/right/up/down` (WASD, arrows) and `action` (Space, mouse, touch)
