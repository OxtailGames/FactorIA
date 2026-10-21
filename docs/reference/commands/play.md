[Back to the index](../README.md)

# Commands: play

## `play.report`

What happened while the user played: perf, spikes, warnings/errors, their problem marks and screenshots.

Call it when the user says they played the game and saw problems (slow, ugly UI, bugs). Returns the session.json content (perf: avg/p95/max frame ms and frames over 16.7/33 ms; profile: where the time went, per engine system, per script behaviour class (ms and calls per frame, slowest first), GPU ms or null + reason, memory; spikes: slowest frames with entity count and render stats; logs: warnings and errors; marks: frame, time, note and screenshot path, 1-based `n`), `replay` (the input file, absolute path) and `replayHow`. The result carries ONE picture ($image): the screenshot of mark `mark` (default 1); call again with mark 2, 3... to see the others. `session` defaults to the latest (see play.sessions). Example: play.report {"mark":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `session` | string | no | Session folder name from play.sessions. Default: the latest. |
| `mark` | integer | no | Which mark's screenshot to attach as the picture. Default 1. |

## `play.sessions`

List the recent play sessions recorded by the editor (Play .. Stop), newest first.

Each session is a folder .factoria/sessions/<yyyymmdd-hhmmss>/ written when the user pressed Stop in the editor. Rows have a short summary: scene, duration, frame time p95/max, number of warnings/errors and the user's marks (notes). Call play.report {session} for the details and screenshots. Example: play.sessions {"max":5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `max` | integer | no | How many sessions to list. Default 10. |

