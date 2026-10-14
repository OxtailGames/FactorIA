# Block Push

A Sokoban-style puzzle made with FactorIA. Push every box onto a target. Three levels.

```bash
factoria validate                                        # project checks
factoria test                                            # headless tests
factoria call project.check_levels '{}' --project .      # level data checks (exit 1 + report in error.data if a level is broken)
factoria run --headless --frames 120 --screenshot-at 119 # headless frame capture
factoria run                                             # play in a window
```

Controls: arrow keys or WASD move one tile per press. Click or tap a neighbouring tile to step there.
Z undoes a move, R restarts the level, and Space or Enter (or a click or tap) goes on after a solved level.

- `levels/levels.json`: the level maps as text, one string per row (JSON, imported by the board and the check tool).
  `#` wall, `.` target, `$` box, `@` player, space floor. Add a level by appending `{ "name": ..., "map": [...] }`.
- `scripts/board.js`: builds a level from its text by spawning entities, and runs the rules. It also sizes the panel
  behind the banner from `ui.measureText`.
- `scenes/main.scene.json`: camera, HUD, help line and the completion banner. The HUD is pinned with `anchor`/`pivot`:
  the level info to the top-left corner, the help line to the bottom-left corner, the banner to the screen centre.
- `tools/check_levels.js`: project tool `project.check_levels`. Checks box and target counts, one player, and closed
  walls. A clean check returns the report; a level with an error throws a `ToolError`, so `factoria call` exits 1 and
  the full report is in `error.data` (print it with `factoria call project.check_levels '{}' --project . --json`).
- `tests/board.test.js`: headless tests for moves, pushes, walls, undo, restart, completion (keyboard, mouse and touch),
  the HUD anchors, the banner panel size, the check tool (clean and broken data) and a full solution of every level.
- `ENGINE_FEEDBACK.json`: engine gaps found while building this game.
