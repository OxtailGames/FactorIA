[Back to the index](../README.md)

# Commands: review

## `review.info`

Not released yet (on main after 0.17.0).

The manifest of one review sheet (items, facts, the choice) and its picture.

Result: the manifest of the sheet (format factoria.review/1: id, label, createdAt, columns, rows, thumbSize, picture, dropDir, items [{n, type, label, source, candidate, ok, info, numbers, thumb, cell, picture, spec}], picked, warnings) plus `dir` and the picture as `$image`. `picked` is null until review.pick answers it. Example: review.info {"sheet":"sheet-0002"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `sheet` | string | no | The sheet: its id ("sheet-0003"), its number ("3") or "latest" (default). |

## `review.list`

Not released yet (on main after 0.17.0).

List the review sheets of the project, newest first, with what was picked.

Reads .factoria/review/. Result: {total, sheets: [{id, label, createdAt, count, picked (the number, or null while unanswered), pickedLabel, picture, dir}], unreadable?}. Use it to find a sheet that is still waiting for an answer (picked null) or to see what was chosen before. Example: review.list {"limit":5}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `limit` | integer | no | The most sheets to list, newest first. Default 20. |

## `review.pick` (modifies state)

Not released yet (on main after 0.17.0).

Record which numbered thumbnail of a review sheet the person chose, and move the other candidates' files away (never deleting them).

Call it with the number THE PERSON gave you for a sheet that review.sheet made; never pick for them (over MCP and the CLI nothing asks them, so the number must be theirs: show the sheet, ask, wait). The choice is written into the sheet's manifest (who, when, the note and the exact spec of the item: a level's seed and arguments) and is final: a sheet is picked once. With `drop` (default true) the files of every OTHER item marked `candidate` are MOVED to <dropDir>/<sheet id>/<NN>_<file name> (default .factoria/review/dropped/): nothing is deleted, the result and the manifest list each move (from, to) and moving the file back undoes it. What dropping means per item type: image, vector, scene, prefab and vfx items marked candidate: their file moves; items not marked candidate and level items (no file): only recorded. The picked item's file stays where it is. A candidate that shares its file with the picked item, or was already gone, is left alone and reported in `warnings`; assets.json is not edited (it warns when it still lists a moved file). All or nothing: if a move fails (a file open in another program) the moves already made are put back and the manifest is not changed. The manifest is changed under the project's review lock, so the editor, the CLI and an agent may use sheets at once. Errors: not_found (no such sheet), invalid_argument (a number not on the sheet, or the item failed to render), already_picked, exists (a leftover in the drop folder), busy (another process holds the lock). Result: {sheet, n, label, type, source, spec, drop, dropped: [{n, label, from, to, status}], who, at, warnings, nextSteps}. Example: review.pick {"sheet":"latest","n":3}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `sheet` | string | no | The sheet: its id ("sheet-0003"), its number ("3") or "latest" (default), the newest finished sheet. |
| `n` | integer | yes | The number printed on the thumbnail the person chose. It must come from them. |
| `drop` | boolean | no | Move the files of the other candidates to the sheet's drop folder. false: only record the choice and touch no file. Default true. |
| `note` | string | no | Why it was chosen, in the person's words (at most 500 characters); kept in the manifest. |

## `review.sheet` (modifies state)

Not released yet (on main after 0.17.0).

Show N candidates as ONE picture with big numbers (images, scenes, prefabs, level seeds, vector art, effects) so a person can answer with one number.

Make the candidates, call review.sheet, show the picture to the person, ask for ONE number, then review.pick. Do not choose for them and do not show candidates one by one. Each item is an object with exactly one of image (a PNG/JPG/BMP/TGA), scene, prefab, level (the arguments of tilemap.generate, with `seeds` next to it for one thumbnail per seed), vector (an .svg) or vfx (a .vfx.json), plus an optional label and candidate. Every thumbnail carries its number (1..N, in the item order), its label and one line of facts: an image its size, colors and how much is clear; a scene its entity count; a prefab its entities and size; a level its size, seed and tries; vector art its size, shapes and colors (counted from the file's text); an effect its peak particles and length. How each is drawn: images and vector art on the CPU as they are; a level on the CPU, one square per cell (letters on the squares when they are big enough); a scene is started and captured by the engine's renderer (`steps` frames in); a prefab is spawned on a plain stage and framed (2D from its visuals, 3D turned three quarters under a studio light); an effect is the MIDDLE picture of vfx.filmstrip (the label in its corner is its time), over a dark stage or your `stage` scene. Scenes, prefabs and effects need a graphics device like assets.preview_in_scene; without one the whole command fails with no_gpu before anything is written (images, vector art and levels need none). An item that cannot be drawn (a corrupt image, a level the solver could not make) is a red tile that review.pick refuses; if none can be drawn nothing is written; a wrong argument of a level fails the command with its JSON pointer. A level is generated with the project's engine (graphics off), at most 1024 cells a side, with `maxWork` 20000000 unless you set it, so the same arguments and seed give the same thumbnail on every machine. At most 48 items (after `seeds` are expanded; 4 to 9 is what a person judges well) and a sheet of at most 8192 px a side; the thumbnail size and the columns are chosen from the item count unless you give them. The sheet is stored under .factoria/review/<id>/ (sheet.png, manifest.json, thumbs/NN.png): the manifest records the items with their labels, facts and the exact arguments of each (a level's seed), when it was made, and later who picked what. The picture comes back as `$image` (a file in the project, not a temporary one). Mark `candidate: true` on the items whose FILES you made only for this choice (variants of an image, scene or prefab): review.pick then MOVES the ones that were not chosen to .factoria/review/dropped/<id>/ (or `dropDir`), never deleting them. A file that is not marked is never touched. Levels are not files: picking one only records its seed. Result: {sheet, dir, manifest, picture: {path, width, height}, columns, rows, thumbSize, count, items: [{n, type, label, info, ok, source, candidate}], warnings, nextSteps, $image}. Example: review.sheet {"label":"Which hero?","items":[{"image":"assets/hero_a.png","candidate":true},{"image":"assets/hero_b.png","candidate":true}]} or {"items":[{"level":{"sample":"example","size":[40,24]},"seeds":[1,2,3,4]}]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `items` | array | yes | What to show, in order: the first is number 1. |
| `label` | string | no | The question or title printed at the top of the sheet, e.g. "Which hero?" (at most 120 characters). |
| `columns` | integer | no | Thumbnails per row. Default: nearly square. |
| `thumbSize` | integer | no | Pixels of the square each thumbnail is fitted into. Default: chosen from the number of items so the sheet is about 1800 px wide. |
| `candidates` | boolean | no | Treat every file item (not levels) as a candidate unless it says `candidate: false`: the files of the items that are not picked are moved away. Default false. |
| `dropDir` | string | no | Project folder below .factoria/ that review.pick moves unpicked candidates into (a sub-folder per sheet). Default .factoria/review/dropped. |

