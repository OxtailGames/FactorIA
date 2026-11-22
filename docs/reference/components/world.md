[Back to the index](../README.md)

# Components: World

## StreamingAnchor

Not released yet (on main after 0.34.0).

Makes the world around this entity load and unload as it moves: a streamed scene is cut into cells (the `world.cells` command lists them), and the cells nearer than loadRadius to any enabled anchor are loaded, those farther than unloadRadius from all of them are unloaded. Put it on the player or on the camera. A scene with no anchor loads every cell. No effect yet: M75.3 builds the streaming (docs/BIG_WORLDS.md, "Streaming").

| Field | Type | Default | Description |
|---|---|---|---|
| `loadRadius` | float | `256.0` | Metres: a cell whose bounds are nearer than this to the anchor (on the ground plane, x and z) is loaded. 1..1000000. Default 256. Range 1.0..1000000.0. |
| `unloadRadius` | float | `320.0` | Metres: a loaded cell whose bounds are farther than this from every anchor is unloaded. Must be above loadRadius (the gap keeps a cell on the border from flickering). 1..1000000. Default 320. Range 1.0..1000000.0. |
| `priority` | int | `0` | -100..100: when two anchors want cells loaded, the anchor with the higher priority gets its cells first. Default 0. Range -100..100. |
| `enabled` | bool | `true` | false = this anchor loads nothing and keeps nothing loaded. |

