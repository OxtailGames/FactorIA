# Block Push

A Sokoban-style puzzle made with FactorIA. Push every box onto a target. Three levels.

```bash
factoria validate                                        # project checks
factoria test                                            # headless tests
factoria call project.check_levels '{}' --project .      # level data checks
factoria run --headless --frames 120 --screenshot-at 119 # headless frame capture
factoria run                                             # play in a window
```

Controls: arrow keys or WASD move one tile per press. Click a neighbouring tile to step there.
Z undoes a move, R restarts the level, and Space or Enter (or a click) goes on after a solved level.

- `levels/levels.js`: the level maps as text. `#` wall, `.` target, `$` box, `@` player.
- `scripts/board.js`: builds a level from its text by spawning entities, and runs the rules.
- `scenes/main.scene.json`: camera, HUD, help line and the completion banner.
- `tools/check_levels.js`: project tool `project.check_levels`. Checks box and target counts, one player, and closed walls.
- `tests/board.test.js`: headless tests for moves, pushes, walls, undo, restart, completion and a full solution of every level.
- `ENGINE_FEEDBACK.json`: engine gaps found while building this game.
