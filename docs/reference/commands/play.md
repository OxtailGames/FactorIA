[Back to the index](../README.md)

# Commands: play

## `play.auto` (modifies state)

Since 0.18.0.

Let the game play itself, headless and fast, and write the run as a play session: phases, score, how it ended, problems found, pictures.

Capabilities: read, state

Run this after you build a feature and BEFORE you ask the user to play: it plays the game with nobody at the keyboard and tells you whether it can be finished, where it gets stuck and what breaks. A second headless engine in this process (fake platform, in-memory saves, fixed 1/fixedHz steps, the same `seed` plays the same game) plays up to `seconds` GAME seconds. The bot is the game's own: scripts/autoplay.js calls game.autoplay(fn) and fn(bot) answers, every step, the input actions to hold (docs/SCRIPTING.md, "The bot"; the project templates ship one that finishes their sample level). Without that file a generic explorer holds the declared input actions in seeded patterns (and taps the menu actions when the scene has buttons), so any game still gets smoke-played; bot "explorer" forces it. Example: {"seconds":120,"seed":7} or {"scene":"scenes/level2.scene.json","bot":"explorer","speed":4}.

The run ends with `ended`: "won" or "lost" (the hook returned { end } or the game called game.phase(name, { ends })), "timeout" (the seconds passed), "quit" (the game quit), "stuck" (nothing moved and nothing changed for stuckSeconds, or a menu has nobody to press it), "broken" (a script raised errors every second for 3 seconds, something pulled by gravity fell out of the world, a position became NaN, or scripts/autoplay.js could not be loaded) or "aborted" (a real-time safety net of 800 seconds, far above any normal run). Each problem becomes a mark with its `kind`, the `step`, a screenshot and a one-line note. The session is written to .factoria/sessions/<name>/ with "source": "auto" next to the editor's: session.json (perf, spikes, warnings, errors, marks, `phases` = the scenes and the game.phase("boss") marks with their game time and a screenshot, `score`, `ended`, `endedWhy`, `notes`, `scriptErrors`, `auto`), input.json (the bot's input in the replay format) and the pictures. Returns {session, dir, ended, endedWhy, score, gameSeconds, steps, frames, bot ("hook" or "explorer"), seed, speed, phases, problems, scriptErrors, warningsAndErrorsLogged, notes, avgFrameMs, maxFrameMs, screenshots, endScreenshot, replay, next} and the picture of the end ($image). Read the details with play.report {session}; replay the problem with the `replay` command (factoria run --headless --input ... --seed ...). Without a GPU the numbers, phases and marks are complete and `notes` says there are no pictures (a Linux machine without a display needs Mesa's EGL, llvmpipe). From the editor or any process that already uses the graphics card the command runs `factoria call play.auto` in a child process. The result never depends on how fast the machine is.

| Argument | Type | Required | Description |
|---|---|---|---|
| `scene` | string | no | Project-relative scene to start in (default: the project's mainScene). |
| `seconds` | number | no | How many GAME seconds to play at most (simulation time: steps / fixedHz, never the clock). The run ends "timeout" when they pass. Default 60. |
| `seed` | integer | no | Seed of the world's random numbers, of the explorer and of bot.rng in the hook: the same seed plays the same game. Default 1. |
| `speed` | integer | no | Fixed steps run per frame. The bot answers once per frame, so 4 plays about four times as much game time per second of real time, with a coarser bot. Replays keep the same timing. Default 1. |
| `stuckSeconds` | number | no | Game seconds without the player (or whatever can move) moving and without a scene, phase, score or menu-focus change before the run is called stuck. Must not be more than seconds. Default 10, or half of seconds when the run is shorter than 20. |
| `bot` | string ["auto","hook","explorer"] | no | auto: scripts/autoplay.js when the project has one, else the generic explorer. hook: the file is required (error without it). explorer: ignore the file and press the declared actions in seeded patterns. Default "auto". |
| `screenshots` | boolean | no | Take a screenshot per phase, per problem and at the end (needs a GPU; without one the session says so in its notes). false: numbers only, a little faster. Default true. |

## `play.report`

What happened while the game was played (by the user or by play.auto): perf, spikes, warnings/errors, the problem marks and screenshots.

Capabilities: read

Call it when the user says they played the game and saw problems (slow, ugly UI, bugs), and after play.auto. Example: play.report {"mark":2}

Returns the session.json content (perf: avg/p95/max frame ms and frames over 16.7/33 ms; profile: where the time went, per engine system, per script behaviour class (ms and calls per frame, slowest first), GPU ms or null + reason, memory; loading: timeToFirstFrameMs, each scene's loadMs (from the start of its load to the end of the first frame after it), files and bytes, slowestAssets (kind, path, bytes, readMs, decodeMs) and reads (count, bytes, fromPack, packStoredBytes): this machine's times, rounded, to compare runs, never a pass or a fail; spikes: slowest frames with entity count and render stats; logs: warnings and errors; marks: frame, time, note and screenshot path, 1-based `n`; for a play.auto session (`source` "auto") also `kind` and `step` of each problem the bot found, `phases` (scenes and game.phase marks with their time and screenshot), `score`, `ended` (won, lost, timeout, stuck, broken, quit, aborted) with `endedWhy`, `endScreenshot`, `notes` and `auto` (seed, speed, bot, stuckSeconds)), `replay` (the input file, absolute path) and `replayHow`. The result carries ONE picture ($image): the screenshot of mark `mark` (default 1) or, with `phase`, of that phase; a play.auto session without marks shows the picture taken when the run ended. Call again with mark 2, 3... or phase 1, 2... to see the others. `session` defaults to the latest (see play.sessions).

| Argument | Type | Required | Description |
|---|---|---|---|
| `session` | string | no | Session folder name from play.sessions. Default: the latest. |
| `mark` | integer | no | Which mark's screenshot to attach as the picture. Default 1 (when the session has marks). |
| `phase` | integer | no | Attach the screenshot of this phase (1-based, play.auto sessions) instead of a mark's. Cannot be combined with mark. |

## `play.sessions`

List the recent play sessions (recorded by the editor on Play .. Stop, or by play.auto), newest first.

Capabilities: read

Each session is a folder .factoria/sessions/<yyyymmdd-hhmmss>/ written when the user pressed Stop in the editor, or <yyyymmdd-hhmmss>-auto/ by play.auto (`source` "auto"; those rows also carry `ended` and `score`). Rows have a short summary: source, scene, duration, frame time p95/max, number of warnings/errors and the marks (the user's notes, or the problems the bot found). Call play.report {session} for the details and screenshots. Example: play.sessions {"max":5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `max` | integer | no | How many sessions to list. Default 10. |

