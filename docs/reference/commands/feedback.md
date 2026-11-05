[Back to the index](../README.md)

# Commands: feedback

## `feedback.archive` (modifies state)

Since 0.4.0.

Move the closed feedback entries (fixed-in-engine, wont-fix, duplicate, rejected) to the archive file.

ENGINE_FEEDBACK.json should only hold what is still open: this moves every entry whose status is not open to ENGINE_FEEDBACK.archive.json next to it (same format). Ids stay unique across both files and keep counting up; a new report that matches an archived fixed-in-engine entry reopens it (feedback.report says reopened). The editor runs this when it opens the project. Safe to repeat: with nothing closed it changes nothing. feedback.list with includeArchive and `factoria feedback collect` still see the archived entries.

## `feedback.check`

Since 0.16.1.

Check, before filing, whether the engine already has what a feedback report says is missing.

feedback.report runs this check itself and refuses a report that calls missing something the engine has (a component, a field such as Collider2D.oneWay, a command, a scripting member): the answer names what exists, its doc string and the page that documents it. Call it first with the title, missing and suggestion you are about to file to find out. `exists: true` means do not file: read the docs; if it does not work as documented, file a BUG that says what you tried. `exists: false` lists `related` documentation to read before you decide. A request for an extra option on an existing component (the field is not there) passes. With `entries: true` it checks the OPEN entries already in this project's ENGINE_FEEDBACK.json instead, and with `reject: true` too it rejects the ones it catches (status rejected, statusBy engine, the reason says what exists); a person can reopen one and it is not rejected again. Example: {"title":"No fluid simulation","missing":"There is no liquid solver."}

| Argument | Type | Required | Description |
|---|---|---|---|
| `title` | string | no | The title you would file. |
| `missing` | string | no | What you say the engine lacks. |
| `suggestion` | string | no | The engine change you would propose. |
| `entries` | boolean | no | Check the open entries of this project's feedback file instead of a new report. |
| `reject` | boolean | no | With entries: reject the entries the check catches (statusBy engine). |

## `feedback.check_fixed` (modifies state)

Since 0.10.0.

Close the open feedback entries whose gap this engine version fixed.

Every FactorIA release ships a list of the gaps it fixed (feedback/fixed.json, embedded). Each open entry of this project's ENGINE_FEEDBACK.json with the same category (or family) and a similar title (`title` or `share.title`, similarity 0.7) becomes fixed-in-engine with engineIssue "FactorIA <version>" and a note to check whether the workaround can go; feedback.archive then moves it to the archive. The editor runs this when it opens the project. Reporting the gap again reopens it as a possible regression. Safe to repeat. Example: {}

## `feedback.delete` (modifies state)

Since 0.16.1.

Delete a closed feedback entry (rejected, wont-fix, duplicate, fixed) from the file and its archive.

Removes entry `id` from ENGINE_FEEDBACK.json or ENGINE_FEEDBACK.archive.json for good, and takes it out of the sharing outbox. Only a closed entry can go (any status but open), or an open one the engine developer refused (its `shared` says rejected or declined): an open entry is a question for the engine developers, so close it first with feedback.update. Its id is not given again. What was already sent to the engine developer stays with them. The editor's Feedback panel offers this with a confirmation. Example: {"id":"FB-0004"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entry id, e.g. FB-0004. |

## `feedback.list`

List the engine-feedback entries recorded for this project.

Check this before reporting to see what is already recorded. Filters are optional. The file only holds what is still open (plus entries closed since the last feedback.archive): entries that are fixed, rejected or duplicates live in the archive file next to it; pass includeArchive to list them too (each marked "archived": true). Example: {"status":"open","category":"physics"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate","rejected"] | no | Only entries with this status. |
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | no | Only this category. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | no | Only this severity. |
| `includeArchive` | boolean | no | Also list the archived (closed) entries, marked archived: true. |

## `feedback.report` (modifies state)

Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.

CALL THIS WHENEVER the engine lacked a feature or had a bug/limitation and you built a workaround or gave up on something, right when it happens (not at the end). Examples: a component field you expected does not exist; an error message did not say how to fix the problem; a documented API behaves differently; you had to emulate a feature in JavaScript; a command you wanted is missing.
The entry is appended to the project's ENGINE_FEEDBACK.json, which engine developers aggregate to decide what to build next. Reporting a gap similar to an open one merges into it (occurrences + 1), so duplicates are harmless. A gap the engine already fixed (archived, see feedback.archive) and that you report again reopens the archived entry as a possible regression.
CHECK BEFORE YOU FILE: models often report as missing something the engine has (a component field, a command, a scripting member). Search first: docs.search for the thing, docs.components for the fields of the component you mean, or call feedback.check with your title/missing/suggestion. This command runs the same check and REFUSES a report whose missing thing exists, naming what exists and the page that documents it. If it exists but does not work as documented, file a BUG instead: say what you set, what you expected and what happened. A request for an extra option on an existing component is fine. The examples below are INVENTED to show the shape: do not copy or adapt them.
Write 'title' as a short noun phrase ("No fluid simulation"), 'missing' as what you needed and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the concrete engine change that would remove the workaround.
SHARE (optional, strongly recommended): `share` is the same gap written for the ENGINE DEVELOPER, who must never learn what the game is about. Write it in engine terms only: components, fields, commands and API names that exist (or that you propose), and NOTHING about the game: no game, character, level, scene, entity, asset or script names, no file names or paths, no quotes from the game, no story. {title (8-120 characters), missing (20-1500, at least 4 words), suggestion?, workaround? (the kind of workaround, without project details)}. Good (invented): {"title":"No fluid simulation","missing":"There is no liquid solver, so water cannot flow around bodies and fill a container.","suggestion":"Add a particle-based Fluid2D component.","workaround":"A script moves sprites to fake a water surface."}. Bad: "The knight in Dungeon of Ash cannot jump through scripts/ledge.js platforms" (names the game, a character and a file). Check the docs first (docs.search) so the gap is real and about the engine, then pass reviewed: true. An entry without `share` is never sent. Whether anything is sent is the USER's choice (mode always, ask or never): the result's `share` says what happened, and no command changes the mode, so do not try; if it says sharing is not set up, tell the user how to turn it on, once.
Example (an invented gap, only to show the fields): {"category":"physics","severity":"major","title":"No fluid simulation","missing":"There is no liquid solver, so water cannot flow around bodies and fill a container.","workaround":"scripts/water.js moves sprites to fake a water surface.","workaroundFiles":["scripts/water.js"],"suggestion":"Add a particle-based Fluid2D component.","share":{"title":"No fluid simulation","missing":"There is no liquid solver, so water cannot flow around bodies and fill a container.","suggestion":"Add a particle-based Fluid2D component."},"reviewed":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | yes | Engine area of the gap. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | yes | blocker: could not build the feature at all; major: large/fragile workaround; minor: small workaround; nice-to-have: convenience. |
| `title` | string | yes | Short noun phrase naming the gap; reuse wording for the same gap. |
| `missing` | string | yes | What the engine lacked or got wrong, and what you were trying to do. |
| `workaround` | string | yes | What you did instead (or 'none: feature dropped'). |
| `workaroundFiles` | array | no | Project-relative files implementing the workaround. |
| `suggestion` | string | no | How the engine could fix it (field, command, API). |
| `effort` | string ["small","medium","large"] | no | Your estimate of the engine-side effort to fix it. |
| `share` | object | no | The generic copy for the engine developer, in ENGINE TERMS ONLY: nothing about the game (no names, story, characters, assets, file names, paths or quotes). {title, missing, suggestion?, workaround?}. Without it the entry is never sent. |
| `reviewed` | boolean | no | true when you checked against the docs (docs.search, docs.components) that the gap is real and about the engine. |
| `reporter` | object | no | Who is reporting. Defaults to {"kind":"ai"}; include your agent and model if you know them. |

## `feedback.share` (modifies state)

Since 0.10.0.

Send the queued feedback to the engine developer now (only what the user's mode allows).

With mode `always`: queues the shareable entries of this project that are not queued yet and sends the outbox (one request of up to 20 entries; failed ones keep their retry time). With mode `ask`: entries wait for the user's confirmation, which only the user gives (editor, or `factoria feedback share`); nothing is sent here. With mode `unset` or `never` nothing is sent and the result says why. Result: counts, per-entry results and the outcome (sent, failed, rate_limited, banned, off, unavailable, idle). Example: {"ids":["FB-0003"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `ids` | array | no | Entry ids (FB-0003). Empty or missing = every shareable entry. |

## `feedback.share_preview`

Since 0.10.0.

Show exactly what sharing would send for the entries that have a `share`, and what the sanitizer removed.

Runs the deterministic sanitizer on the `share` of each shareable entry and returns the entry as the engine developer's server would receive it (`sent`), plus `removed`: every path, file name, URL, e-mail address, quoted text and project name that was cut out. An entry whose text drops under its minimum after cleaning is `ok: false` with the reason: rewrite `share` in engine terms only. Nothing is sent and nothing is written. Example: {"ids":["FB-0003"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `ids` | array | no | Entry ids (FB-0003). Empty or missing = every shareable entry. |

## `feedback.share_status`

Since 0.10.0.

Sharing with the engine developer: the mode, the server, whether the user signed in, and the outbox.

Reports the mode that applies to this project (unset, always, ask or never): its own choice if the user made one, else the user's default (`default` and `project` say which; no command changes either). Also whether this build has a feedback server, whether the user signed in with GitHub, and the outbox: entries queued, waiting for the user's confirmation, and failed ones with their reason and when they are retried. Use it to tell the user why a report was not sent.

## `feedback.update` (modifies state)

Change the status of a feedback entry (with a reason when it is rejected) or link it to an engine issue.

Engine developers use this when a gap is fixed (status fixed-in-engine), will not be done (wont-fix) or duplicated; the entry moves to the archive on the next feedback.archive (the editor runs it when it opens the project). Status `rejected` means the entry claims a gap the engine does not have (the thing exists, or it is not about the engine): it REQUIRES `statusReason`, a sentence the person reads in the editor (what exists and where it is documented). A reason may also be given with wont-fix and duplicate. An archived entry is found too, and set to open it moves back to the file (its reason is removed). Example: {"id":"FB-0001","status":"fixed-in-engine","engineIssue":"#42"} or {"id":"FB-0002","status":"rejected","statusReason":"The field exists: see the Collider2D page of the reference."}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entry id, e.g. FB-0001. |
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate","rejected"] | no | New status. |
| `statusReason` | string | no | Why (at most 500 characters, plain text). Required with status rejected; shown to the person in the editor. |
| `engineIssue` | string | no | Issue/PR link or id. |

## `feedback.verdicts` (modifies state)

Since 0.16.1.

Ask the feedback server what the engine developers decided about the reports this installation sent.

Asks POST /v1/verdicts for the entries of this project's ENGINE_FEEDBACK.json (and its archive) that were sent, by their shareIds, authenticated by the installation header: only this installation's reports are answered. A report the engine developers rejected becomes status rejected (statusBy developer, statusReason = their reason, shared.status declined); a rejection they took back reopens it. The editor asks by itself about every 30 minutes. Needs the sharing mode always or ask; a server without verdicts changes nothing. Result: {outcome, checked, declined, restored, changed[], message}. Example: {}

