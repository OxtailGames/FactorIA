# {{PROJECT_NAME}}

A minimal FactorIA 3D scene: fly camera (WASD + E/Q), sun light, floor, spinning cube, ball. All
meshes are built-in primitives, so there are no binary assets.

```bash
factoria validate
factoria run
factoria run --headless --frames 120 --screenshot 120
factoria test
```

- `scenes/main.scene.json` camera, directional light, primitives
- `scripts/fly_camera.js`, `scripts/spin.js` behaviours
- `tools/spawn_cube.js` project tool: `factoria call project.spawn_cube '{"x":2,"z":-3}'`
- `tests/scene.test.js` headless tests

Units are meters, +Y up, the default camera looks toward -Z.
