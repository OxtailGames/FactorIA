[Back to the index](../README.md)

# Commands: feedback

## `feedback.list`

List the engine-feedback entries recorded for this project.

Check this before reporting to see what is already recorded. Filters are optional. Example: {"status":"open","category":"physics"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate"] | no | Only entries with this status. |
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | no | Only this category. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | no | Only this severity. |

## `feedback.report` (modifies state)

Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.

CALL THIS WHENEVER the engine lacked a feature or had a bug/limitation and you built a workaround or gave up on something, right when it happens (not at the end). Examples: a component field you expected does not exist; an error message did not say how to fix the problem; a documented API behaves differently; you had to emulate a feature in JavaScript; a command you wanted is missing.
The entry is appended to the project's ENGINE_FEEDBACK.json, which engine developers aggregate to decide what to build next. Reporting a gap similar to an open one merges into it (occurrences + 1), so duplicates are harmless. Write 'title' as a short noun phrase ("No one-way platforms"), 'missing' as what you needed and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the concrete engine change that would remove the workaround.
Example: {"category":"physics","severity":"major","title":"No one-way platforms","missing":"Collider2D has no one-way option so the player cannot jump up through platforms.","workaround":"scripts/one_way.js disables the platform collider while the player moves upward.","workaroundFiles":["scripts/one_way.js"],"suggestion":"Add Collider2D.oneWay (bool)."}

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
| `reporter` | object | no | Who is reporting. Defaults to {"kind":"ai"}; include your agent and model if you know them. |

## `feedback.update` (modifies state)

Change the status of a feedback entry or link it to an engine issue.

Engine developers use this when a gap is fixed (status fixed-in-engine), rejected (wont-fix) or duplicated. Example: {"id":"FB-0001","status":"fixed-in-engine","engineIssue":"#42"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entry id, e.g. FB-0001. |
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate"] | no | New status. |
| `engineIssue` | string | no | Issue/PR link or id. |

