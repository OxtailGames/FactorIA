[Back to the index](../README.md)

# Commands: review

## `review.cleanup` (modifies state)

Since 0.18.0.

Delete the candidate files a review pick moved away long ago, and the folders of sheets that were never finished.

Capabilities: read, writeProject

review.sheet runs it by itself after each new sheet; call it to see what it would do (dryRun) or to use other ages. Two things only: (1) the files review.pick MOVED to a sheet's drop folder are deleted `droppedDays` days after the pick (the clock against the pick's time in the manifest); the manifest entry becomes status "expired" ("gone" when the file was already moved back or removed) and the empty folder goes. Nothing else is ever deleted there: only the files named `<NN>_<name>` that the pick put in <dropDir>/<sheet id>/. (2) a sheet folder with no manifest.json (the process died between starting the sheet and writing it; review.list shows these as `orphans`) is removed once nothing in it changed for `orphanMinutes` minutes. A sheet nobody has answered, the files of the picked item and every chosen file are never touched. At most 200 sheets are changed per call (`more` says there are others: call again). A file that is open in another program is kept and tried again next time. Runs under the project's review lock; busy when another process holds it (nothing changed). Result: {droppedExpired: [{sheet, files}], orphansRemoved: [ids], skipped: [{sheet, reason}], examined, more, dryRun, droppedDays, orphanMinutes}. Example: review.cleanup {"dryRun":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `droppedDays` | integer | no | Delete a dropped candidate this many days after the pick. 0: keep them for ever. Default 7. |
| `orphanMinutes` | integer | no | Remove a sheet folder without a manifest once nothing in it changed for this many minutes. 0: leave them. Default 60. |
| `dryRun` | boolean | no | Report what would be removed and remove nothing. Default false. |

## `review.info`

Since 0.18.0.

The manifest of one review sheet (items, facts, the choice) and its picture.

Capabilities: read

Result: the manifest of the sheet (format factoria.review/1: id, label, createdAt, columns, rows, thumbSize, picture, dropDir, items [{n, type, label, source, candidate, ok, info, numbers, thumb, cell, picture, spec}], picked ({n, label, at, atUnix, who, note, drop, dropped [{n, label, from, to, status: moved | expired | gone}], spec}), meta, warnings) plus `dir` and the picture as `$image`. `picked` is null until review.pick answers it. Example: review.info {"sheet":"sheet-0002"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `sheet` | any | no | The sheet: its id ("sheet-0003"), its number (3 or "3") or "latest" (default). |

## `review.list`

Since 0.18.0.

List the review sheets of the project, newest first, with what was picked.

Capabilities: read

Reads .factoria/review/. Result: {total, sheets: [{id, label, createdAt, count, picked (the number, or null while unanswered), pickedLabel, picture, meta, dir}], unreadable?, orphans?}. `orphans` are sheet folders with no manifest: a sheet being made right now, or one whose process died (review.cleanup removes the old ones). Use it to find a sheet that is still waiting for an answer (picked null) or to see what was chosen before. Example: review.list {"limit":5}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `limit` | integer | no | The most sheets to list, newest first. Default 20. |

## `review.pick` (modifies state)

Since 0.18.0.

Record which numbered thumbnail of a review sheet the person chose, and move the other candidates' files away (the pick itself deletes nothing; review.cleanup deletes the dropped files after 7 days, or never with droppedDays 0).

Capabilities: read, writeProject

Call it with the number THE PERSON gave you for a sheet that review.sheet made; never pick for them (over MCP and the CLI nothing asks them, so the number must be theirs: show the sheet, ask, wait). The choice is written into the sheet's manifest (who, when, the note and the exact spec of the item: a level's seed and arguments) and is final: a sheet is picked once. With `drop` (default true) the files of every OTHER item marked `candidate` are MOVED to <dropDir>/<sheet id>/<NN>_<file name> (default .factoria/review/dropped/): the pick deletes nothing (review.cleanup deletes the dropped files after

7 days; droppedDays 0 keeps them), the result and the manifest list each move (from, to) and moving the file back undoes it. What dropping means per item type: image, vector, scene, prefab and vfx items marked candidate: their file moves; items not marked candidate and level items (no file): only recorded. The picked item's file stays where it is. A candidate that shares its file with the picked item, or was already gone, is left alone and reported in `warnings`; assets.json is not edited (it warns when it still lists a moved file). Every file is checked again before the first one moves (the manifest is a file anyone can edit): it must be inside the project and of the kind its type needs, never factoria.json, assets.json, anything under .factoria/, a version-control folder, the main scene or a scene another item plays an effect in; the drop folder must be one review.sheet would accept; otherwise nothing is moved and the error says why. All or nothing: if a move fails (a file open in another program) the moves already made are put back and the manifest is not changed. The manifest is changed under the project's review lock, so the editor, the CLI and an agent may use sheets at once. A crash between the moves and the manifest write (a power cut) leaves the moved files in the drop folder with the sheet still unanswered: pick again (the files that are gone are reported, not an error), or move them back by hand from <dropDir>/<id>/. Errors: not_found (no such sheet), invalid_argument (a number not on the sheet, the item failed to render, or a sheet of asset candidates, which assets.pick answers), already_picked, exists (a leftover in the drop folder), busy (another process holds the lock, or a file to move is open in another program). Result: {sheet, n, label, type, source, spec, drop, dropped: [{n, label, from, to, status}], who, at, meta (the object review.sheet was given), warnings, nextSteps}. Example: review.pick {"sheet":"latest","n":3}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `sheet` | any | no | The sheet: its id ("sheet-0003"), its number (3 or "3") or "latest" (default), the newest finished sheet. |
| `n` | integer | yes | The number printed on the thumbnail the person chose. It must come from them. |
| `drop` | boolean | no | Move the files of the other candidates to the sheet's drop folder. false: only record the choice and touch no file. Default true. |
| `note` | string | no | Why it was chosen, in the person's words (at most 500 characters); kept in the manifest. |

## `review.sheet` (modifies state)

Since 0.18.0.

Show N candidates as ONE picture with big numbers (images, scenes, prefabs, level seeds, vector art, effects) so a person can answer with one number.

Capabilities: read, writeProject

Make the candidates, call review.sheet, show the picture to the person, ask for ONE number, then review.pick. Do not choose for them and do not show candidates one by one. Each item is an object with exactly one of image (a PNG/JPG/BMP/TGA), scene, prefab, level (the arguments of tilemap.generate, with `seeds` next to it for one thumbnail per seed), vector (an .svg) or vfx (a .vfx.json), plus an optional label and candidate. Every thumbnail carries its number (1..N, in the item order), its label and one line of facts: an image its size, colors and how much is clear; a scene its entity count; a prefab its entities and size; a level its size, seed and tries; vector art its size, shapes and colors (counted from the file's text); an effect its peak particles and length. Only files marked `candidate: true` are ever moved by review.pick; a file not marked is never touched.

How each is drawn: images and vector art on the CPU as they are; a level on the CPU, one square per cell (letters on the squares when they are big enough); a scene is started and captured by the engine's renderer (`steps` frames in); a prefab is spawned on a plain stage and framed (2D from its visuals, 3D turned three quarters under a studio light); an effect is the MIDDLE picture of vfx.filmstrip (the label in its corner is its time), over a dark stage or your `stage` scene. Scenes, prefabs and effects need a graphics device like assets.preview_in_scene; without one the whole command fails with no_gpu before anything is written (images, vector art and levels need none). An item that cannot be drawn (a corrupt image, a level the solver could not make) is a red tile that review.pick refuses; if none can be drawn nothing is written; a wrong argument of a level fails the command with its JSON pointer. A level is generated with the project's engine (graphics off), at most 1024 cells a side, with `maxWork`20000000 unless you set it, so the same arguments and seed give the same thumbnail on every machine; tilemap.generate's `maxSeconds` is NOT fixed here (its default of 1800 CPU seconds is only a safety net far above what a thumbnail takes), so the work cap decides, never the speed of the machine. The level's `sample` takes the forms of tilemap.generate: ASCII rows as an array of strings (with `legend` next to it), an object {rows, legend?}, one string with line breaks, a project path of a .json rows file, or the id or name of an ENTITY WITH A TILEMAP. Only the entity form needs a scene to look the entity up in: it is the project's main scene (factoria.json mainScene), or the scene you name with `sampleScene` on the item; the thumbnails never change that scene. Without a main scene and without `sampleScene` an entity sample is an error with its JSON pointer. At most 48 items (after `seeds` are expanded; 4 to 9 is what a person judges well) and a sheet of at most 8192 px a side; the thumbnail size and the columns are chosen from the item count unless you give them. The sheet is stored under .factoria/review/<id>/ (sheet.png, manifest.json, thumbs/NN.png): the manifest records the items with their labels, facts and the exact arguments of each (a level's seed), when it was made, and later who picked what. The picture comes back as `$image` (a file in the project, not a temporary one). Mark `candidate: true` on the items whose FILES you made only for this choice (variants of an image, scene, prefab, vector art or effect): review.pick then MOVES the ones that were not chosen to .factoria/review/dropped/<id>/ (or `dropDir`); the pick never deletes them (review.cleanup does, 7 days later; `droppedDays` 0 keeps them). A file that is not marked is never touched. Levels are not files: picking one only records its seed. A candidate must be a file of the project of the kind its type needs (.scene.json, .prefab.json, .vfx.json, .svg, a picture), never factoria.json, assets.json, anything under .factoria/ or a version-control folder, the main scene, or a scene another item uses as its `stage`; no other item may show a candidate's file; paths are compared after normalizing (./, backslashes, upper case), and review.pick checks all of it again before it moves anything. `meta` is your own small object (e.g. {"slot":"hero"}, at most 4096 bytes as JSON), stored with the sheet and returned untouched by review.pick, review.info and review.list. After the sheet is made, files review.pick dropped more than 7 days ago and sheet folders abandoned (no manifest) for more than 60 minutes are cleaned up (review.cleanup says what; the sheets that were not answered and the chosen files are never touched). Result: {sheet, dir, manifest, picture: {path, width, height}, columns, rows, thumbSize, count, items: [{n, type, label, info, ok, source, candidate}], meta, warnings, housekeeping?, nextSteps, $image}. Example: review.sheet {"label":"Which hero?","items":[{"image":"assets/hero_a.png","candidate":true},{"image":"assets/hero_b.png","candidate":true}]} or {"items":[{"level":{"sample":["#..#","#..#"],"legend":{"#":0,".":1},"size":[40,24]},"seeds":[1,2,3,4]}]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `items` | array | yes | What to show, in order: the first is number 1. |
| `label` | string | no | The question or title printed at the top of the sheet, e.g. "Which hero?" (at most 120 characters). |
| `columns` | integer | no | Thumbnails per row. Default: nearly square. |
| `thumbSize` | integer | no | Pixels of the square each thumbnail is fitted into. Default: chosen from the number of items so the sheet is about 1800 px wide. |
| `candidates` | boolean | no | Treat every file item (not levels) as a candidate unless it says `candidate: false`: the files of the items that are not picked are moved away. Default false. |
| `dropDir` | string | no | Project folder below .factoria/ that review.pick moves unpicked candidates into (a sub-folder per sheet). Not .factoria/tmp, not .factoria/review itself or another sheet's folder. Default .factoria/review/dropped. |
| `meta` | object | no | Your own small object (e.g. {"slot":"hero"}, at most 4096 bytes as JSON), stored with the sheet and returned by review.pick, review.info and review.list. Default {}. |

