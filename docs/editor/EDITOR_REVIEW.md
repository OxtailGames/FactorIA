Part of [EDITOR.md](../EDITOR.md): The audio and profiler views, the level generator, the review window and play sessions.

# Editor: review

## View > Audio
The Audio panel shows `audio.log`: sequence number, frame, clip path, bus, volume, the entity that played it (`source`) and whether the
clip loaded. While the game runs it asks only for plays newer than the last one it saw (`after`). **Filter by path**, **Failed only**
and **Clear** keep it readable; a clip that failed to load (`ok: false`) is highlighted in red, because a wrong path is silent in the
game itself.

## View > Profiler
While the game plays (Play), the Profiler panel shows a graph of the last frames, the milliseconds each engine system takes
(physics, scriptsUpdate, render...), a table of script behaviour classes sorted by milliseconds per frame (with the script
path and calls per frame), the GPU time, and memory (process, JavaScript heap, textures, audio, entities). An orange line
"Scripts over budget in N frame(s), worst X ms" appears once a frame's script time went over `runtime.scriptFrameBudgetMs`
(PERFORMANCE.md, "Script budgets"); the Console has the warning (category `script.budget`, so a filter on `script` does not show it) that names the slowest callbacks. Numbers are smoothed
over a few frames. The GPU shows `n/a` with the reason where the graphics backend has no timer queries (PERFORMANCE.md,
"Finding what is slow"). The **Threads** tab has one row per thread of the job pool (main, worker 1.., and `other` when a
thread outside the pool ran jobs): the milliseconds it spent in jobs per frame, how many jobs, its share of the frame and
its slowest jobs by name (hover them for the whole list). How many workers there are is `runtime.jobThreads` in
factoria.json (PERFORMANCE.md, "Job threads"). The profiler only runs while the panel is open or a play session records, so a closed panel costs
nothing. Edit mode shows nothing: nothing runs.

## Level generator
View > Level generator makes a new level from a small one you drew (the command `tilemap.generate`, AI_GUIDE.md section 9.8) and
shows it as a plan of coloured cells, one colour per tile (brighter for the tiles the sample marks as solid, a yellow dot where
a prefab such as a coin or an enemy would be placed; hover a cell for its glyph and tile). Nothing in the scene changes until
you keep a level.

1. **Sample.** Select an entity with a Tilemap (Hierarchy or Viewport) and press **Use the selected Tilemap**, or type the
   project-relative path of a level file (`{"rows": [...], "legend": {...}}`, the format of `scene.import_ascii`; a legend with
   prefabs brings spawn points, coins and enemies into the generated level). The level is made only of the patterns of the sample.
2. **Level.** Its size in cells and a **Seed**. **Previous seed**, **Next seed** and **Random seed** (a far seed, the same chain
   every time) generate at once (so do the + / - buttons of the Seed box and Enter in it; typing alone does not start a generation); the numbers under the buttons say how many attempts and dead ends the seed took, and the
   seeds you tried are buttons (an x marks a seed that made no level) so you can come back to one. The same sample, options and
   seed give the same level on every computer. Model, window `n`, `symmetry` and "wraps around its edges" are the arguments of
   the command; **More options (JSON)** takes the rest (`constraints`, `reachability`, `maxAttempts`...), merged over them. It cannot
   override what the window owns (`sample`, `size`, `seed`, `model`, `n`, `symmetry`, `periodic`): the window refuses such a key and says which field to use.
3. **Keep.** **Keep in the scene** builds the shown level in the open scene with `scene.import_ascii`, as the entity named in
   **Entity id** (to the right of the sample when the sample is an entity; the sample's tileset, tile size and solid tiles are
   copied) and one entity for every spawn point, coin or enemy of the sample: one undo step, and keeping again replaces the
   entity and its objects. It needs the editor in edit mode (a button that is greyed out says why when you hover it). **Save level file** writes the rows and legend as a level file instead
   (`levels/generated.json`, one row per line): `factoria call scene.import_ascii @levels/generated.json` builds it, `scene.ascii_edit`
   edits it by hand, and it can be the sample of the next generation. Save never replaces a file without asking: when the path
   already exists (a scene, `factoria.json`, `assets.json`, the sample itself...) a **Replace <file>?** window offers Replace or
   Cancel, and only Replace overwrites it; the Project panel lists a newly written file at once.

**Sheet of seeds** (on the Generate row, with how many: 2 to 16, 6 by default) makes the levels of the shown seed and the next ones
with the same options as one numbered review sheet and opens it in the Review window (below): pick the one you like and this window
takes that seed, sample, size and options and generates it. The sheet is made by `review.sheet` in a child `factoria` process, so the
editor keeps drawing (Cancel stops it and no sheet is made); a sample entity needs the scene saved first (the child reads the project
as it is on disk), and the sheet draws levels up to 1024 cells a side.

A generation runs in pieces of about 4 ms of each frame, so the window and the viewport keep drawing; **Cancel** stops it, closing
the window stops it (so does collapsing it or hiding its tab, and picking another sample), and loading another scene ends it quietly with a grey note instead of an error (a job belongs to the scene that started it; the last good level stays). A mistake (a
size out of range, extra options that are not JSON, a sample that cannot be found, a level the sample cannot make) is shown in red
with how to fix it, and the last good level stays on screen. The window calls the same commands as the Console
(`tilemap.generate_start` / `generate_step` / `generate_cancel`, `scene.import_ascii`, `fs.write`), so what it shows is what a script
or the AI gets for the same arguments.

**Autotest.** Section R3 of `fa_editor_autotest` imports a small level, selects it, presses Use the selected Tilemap and Generate, steps
the seed with Next and Previous seed (the first level comes back row by row), Keep (the Tilemap entity has the right size, tile size
and solid tiles, one undo step), Save level file (the file parses; saving again over it opens the Replace window, Cancel leaves the file,
Replace overwrites it) and Ctrl+Z. It is in the first shard. `fa_test_editor` covers the
model (`tools/editor/src/level_gen_model.*`) against a headless engine.

## Review window

View > Review shows the review sheets of the project (`.factoria/review/`): N candidates (pictures, scenes, prefabs, levels, vector
art, effects) drawn as ONE picture with numbered thumbnails by `review.sheet` (AI_GUIDE.md section 9.32), answered with one number.
The AI makes them when you have to choose; the editor offers each new one (from `review.sheet`, or a sheet of candidates from
`assets.generate_image` with a `count`) in a toast with an **Open in Review** button and never takes the focus away from what you are
doing.

- **The list** (left) has the sheets still waiting for an answer first, then the answered ones, newest first in each group (the 200 most
  recent). **Refresh** reads the folder again; the list also follows every `review.*` command the editor runs.
- **Sheet** shows one sheet big: fitted to the window, or zoomed with **-**, **+** and **100%** and scrolled. Click a thumbnail (or press
  its number, **1** to **9**; the **arrows** move over the grid) to select it; hover it for its label and facts. **Enter**, a double click
  or **Pick #n...** asks first: the confirmation lists every file the pick MOVES to the drop folder (`.factoria/review/dropped/<sheet>/`:
  the other items marked as candidates; nothing is deleted then, `review.cleanup` deletes them days later and moving one back undoes
  it), takes an optional note (at most 500 bytes, kept with the choice), and **Keep the other files where they are** records the choice
  only (`review.pick` with `drop: false`).
  **Pick** (or Enter again) runs the command itself in a child `factoria` (`factoria call --project ...`, the same command the
  Console and the AI call), so the window keeps drawing while the files move, and then shows what happened: the files moved and any
  warning. When a file of the sheet is open in another program (or another program is changing the sheets), nothing is picked and the
  window says to close it and try again. A pick is final: an answered sheet is read-only, with its number outlined in green. What is
  picked is the sheet, number and note shown when you confirm, even if you look at another sheet meanwhile; a pick waits a moment
  while the window is still reading pictures of that sheet. Closing the editor or opening another project waits up to 15 seconds for
  a running pick (it normally takes about a second), then stops it; a stopped pick may leave the sheet unanswered, and
  `review.info` says where it stands.
- **Compare** puts two numbers side by side, large, with their labels and facts; **The candidates' own pictures** shows the image files
  themselves (sharper than the thumbnails; other items show their thumbnail; while a pick waits or runs, which may move those files,
  it reads none of them: a picture it already has stays, the others show their thumbnail), and each side has its own Pick button.
- **History** lists the answered sheets, newest pick first: who picked which number and when, the note, and every dropped file with
  its status (`moved`: still in the drop folder; `expired`: deleted by `review.cleanup`; `gone`: moved back or deleted by hand).
  **Open** shows that sheet read-only.

A sheet of **asset candidates** (`meta.kind` `"assetCandidates"`, made by `assets.generate_image` with a `count`) shows the asset slot
it is for, and its pick runs `assets.pick` with that slot in the child `factoria`, which puts the picked file in place and records it
in `assets.json`; the editor then reloads that file, so the scene shows the new picture. Only the newest sheet of candidates of a slot
(the highest sheet number) can be picked: an older one waiting for an answer is marked *superseded* in the list and is read-only,
naming the newer sheet, and if a newer sheet appears while you pick, the window says the pick was refused as superseded and which
sheet to open. When the `factoria` tool has no `assets.pick`, the window says so and picks nothing: it never records the choice with
`review.pick` instead. A sheet of **level seeds** (the Level generator's Sheet
of seeds) brings the picked seed back to the Level generator.

Pictures are read and decoded off the UI thread (one upload to the GPU per frame), shrunk on upload (a sheet to 4096 pixels a side,
a candidate's own picture to 2048, a thumbnail to 512) and freed about two seconds after the window stops drawing them (the Compare
view's own pictures a few frames after); a picture larger than 8192 x 8192 pixels is refused from its header before it is decoded
(PNG, JPG, BMP, TGA...), and a picture file other than a PNG over 32 MB is not read.

**Autotest.** Section R4 of `fa_editor_autotest` makes a sheet of four pictures through the queued command path (the toast appears and
the window does not open by itself), opens it from the toast and from View > Review, selects with 3 and the arrows, compares 1 and 2,
picks with Enter and the confirmation in a child `factoria` (the manifest records number 3, the other three files are in the drop folder), checks History
and opens the answered sheet read-only, then makes a Sheet of seeds from the Level generator in a child `factoria` and picks one,
which sets that seed. Last, `assets.generate_image` with `count` 2 and the offline `fake` provider makes a sheet of candidates for a
slot through an AI run's command registry, as an AI calls it (its toast names the slot), and the window picks number 2 with `assets.pick` in a child
`factoria`: the slot's file is the second candidate's picture and `assets.json` records it. `fa_test_editor` covers the model, the reader and the child job (`tools/editor/tests/review_tests.cpp`).

## Play sessions

Every Play .. Stop is recorded, so the AI can see what you saw. Nothing to switch on.

- **While you play**: the editor records (with the engine's `input.record` recorder, docs/DEBUGGING.md "Recording and replaying input") the input it feeds the game, the frame times, and the warnings and errors that are logged.
- **F9 marks a problem** (the toolbar shows "F9 marks a problem" while the game runs). The game pauses on that frame, a screenshot is taken
  and a small window asks for a one-line note. **Enter** saves the mark and the game continues; **Esc** discards it.
- **On Stop** the session is written to `.factoria/sessions/<yyyymmdd-hhmmss>/`:
  `session.json` (scene, duration, frames, frame time avg/p95/max and frames over 16.7 / 33 ms, the 10 slowest frames with entity count and
  render stats, warnings/errors, marks), `input.json` (the input in the replay format of `factoria run --headless --input`) and
  `mark-<n>.png`. Frame numbers are the same in all of them. `input.json` also keeps each frame's time and fixed-step count (`timing`), so the
  headless replay runs the very same frames: it is exact even when the editor ran slower or faster than the fixed rate. Mouse wheel and typed
  text are not recorded.
- **Tell the AI**: after Stop, if the session has marks or errors, the AI Assistant panel shows a line with an **Attach** button. The
  **Attach last play session** button next to **Attach image...** does the same at any time: it adds a short summary (performance, errors, your
  notes) to the message and the mark screenshots as pictures.
- **Let the AI play**: **Play > Let the AI Play** (or the button of the same name in the **Play sessions** window, **Play > Play Sessions...**)
  runs `play.auto` ([DEBUGGING.md](../DEBUGGING.md#let-the-game-play-itself)) on the project as saved on disk: a bot plays it from the start,
  faster than real time, and finds what is stuck or broken. The window has the game seconds the bot may play (5 to 600, 60 by default)
  and a box for the pictures. The bot runs in a `factoria` process of its own (the editor keeps the GPU), so the editor never waits: the
  window shows the time elapsed and the last line the bot printed, and **Cancel** stops it (a cancelled run writes no session). It needs
  the `factoria` program next to the editor, or the one `FA_FACTORIA_EXE` names; if it is not found the window says so and nothing runs.
  The menu item is disabled while the game plays or a run is going. When the run ends a toast says how it ended (won, lost, timeout,
  stuck, broken...) and how many problems it marked, and **Open report** selects the session in the window.
  A run of an AI that works in the editor (the AI panel calls `play.auto`) is the same child process, started from the AI's own thread:
  the editor never waits for it either, and the AI panel's **Stop** kills it (a cancelled run writes no session); the Play sessions window
  lists its session when it ends. While a run goes its pictures are in `.factoria/cache/play-auto-<process id>-<n>/` and move into
  `.factoria/sessions/<name>/` only when the run ends, so a cancelled run leaves no half-written session folder (a run that is killed
  leaves only its `play-auto-*` folder in the cache, which the next run deletes). A run keeps the newest 30 sessions of `play.auto`
  (`-auto` in the name) and, once its own session is written, deletes the older ones, so playing again and again does not fill the
  disk; the sessions you recorded with Play .. Stop are never deleted. A project folder with accents works; on Windows a folder with
  characters outside the system's code page (the ANSI code page of the PC's language) cannot be handed to the child process yet, and
  the run fails with an error instead of playing.
- **Play sessions window**: lists the sessions of `.factoria/sessions/`, newest first. A session the AI's bot played is marked **AI** and
  shows how it ended; one you recorded is not. Click a row for its report (how it ended, score, phases, performance, marks and notes), with
  **Attach to the AI chat** and, for a run of the bot, **Copy replay command** (the command that plays the bot's input again). The list is read
  again when the window opens, when a session is written (Stop, or the end of a run) and with **Refresh**.
- **Attach last play session** (AI panel) picks the last session YOU played. A session of the AI's bot is attached only when you have
  none of your own, and then the editor says so (a toast, and a note in the message: "This is a session the AI's bot played with
  play.auto, not one the user played."), so the AI does not take its own bot's run for what you saw. The Play sessions window has an
  **Attach** button for the selected session, auto or not.
- **For AIs and tools**: `play.sessions` lists the recent sessions, `play.report` returns one (the latest by default) with the replay path and a `profile` section: where the time went over the session (per engine system, per script behaviour class, GPU, memory; PERFORMANCE.md).
  The report says how to replay it: `factoria run --headless --frames <n> --input .factoria/sessions/<name>/input.json`.
- **Sessions played by the bot**: `play.auto` ([DEBUGGING.md](../DEBUGGING.md#let-the-game-play-itself)) writes the same folder with `"source": "auto"`
  (phases, score, how it ended, the problems it found as marks). `play.report` and `play.sessions` read both kinds.
