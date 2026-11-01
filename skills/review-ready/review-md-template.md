# REVIEW.md (template)

Copy this to `REVIEW.md` at the project root and fill it in. It is never exported with the game.

## How to play
Controls (the input actions of `factoria.json`), the goal, and what a session of the first five minutes looks like.

## Status
- Finished: ...
- Placeholder (do not judge as final): ...

## Reach everything fast
| Scene / state | How to get there in one step |
|---|---|
| Main menu | `scene_load {"path": "scenes/menu.scene.json"}` |
| Last level | `scene_load {"path": "scenes/level_5.scene.json"}` |
| Boss fight | project tool `project_goto_boss` (tools/goto_boss.js) |
| Game over | debug key F9, or `review/game_over.json` loaded by the tool above |

## Bot-playable flows
Replays or tests that play the first minutes, a whole level, the ending (`tests/`, `review/*.replay.json`).

## Known issues
What not to report again.
