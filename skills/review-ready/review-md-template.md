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
`scripts/autoplay.js`: the hook that `play.auto` runs (it plays the first minutes, a whole level, the ending; say which
phases it marks). Also replays or tests (`tests/`, `review/*.replay.json`). The game reviewers play by hand first and run
`play.auto` after, to learn what they did not reach.

## Known issues
What not to report again.
