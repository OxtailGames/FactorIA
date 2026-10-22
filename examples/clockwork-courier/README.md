# Clockwork Courier

An empty FactorIA 3D project: the scene has only a perspective camera. Build the game with an AI agent (read
`AGENTS.md`) or yourself:

```bash
factoria validate
factoria run
factoria run --headless --frames 120 --screenshot-at 119
factoria test
```

- `scenes/main.scene.json` the scene (a camera at (0, 3, 8) looking slightly down)
- `scripts/` behaviours, `tests/` headless tests (`*.test.js`), `tools/` project tools: empty for now
- `factoria.json` input actions `move_forward/back/left/right` (WASD, arrows), `move_up` (E, Space), `move_down` (Q, LeftShift)

Units are meters, +Y up, the camera looks toward -Z. Add a `Light` before adding meshes.
