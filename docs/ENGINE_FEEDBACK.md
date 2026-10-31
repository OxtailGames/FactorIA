# ENGINE_FEEDBACK.json

Every FactorIA game keeps an `ENGINE_FEEDBACK.json` at its root. AIs (and people) record there what the
engine lacked and how they worked around it. Engine developers merge many projects' files into a ranked
list of what to build next. `factoria validate` fails if the file is missing or invalid.

## When to write an entry

Immediately, whenever the engine lacked a feature, had a bug, gave a misleading error, or a doc was wrong
or missing, AND you built a workaround or dropped the feature. Do not wait until the end of the task.
Duplicates are harmless: a report similar to an open entry is merged into it.

## How

| Way | Use |
|---|---|
| Command `feedback.report` (MCP tool `feedback_report`, CLI `factoria call feedback.report '{...}'`) | Preferred: assigns id and date, merges duplicates |
| `feedback.share_preview`, `feedback.share_status`, `feedback.share`, `feedback.check_fixed` | Sharing with the engine developer (see Sharing) |
| `feedback.list`, `feedback.update` | Inspect entries; engine developers change `status` / `engineIssue` |
| `feedback.archive` (CLI `factoria feedback archive`) | Move the closed entries to the archive (see Archive) |
| Edit the JSON | Allowed; keep it valid against `schemas/engine-feedback.schema.json` |

```json
{
  "category": "physics",
  "severity": "major",
  "title": "No one-way platforms",
  "missing": "Collider2D has no one-way option, so the player cannot jump up through platforms.",
  "workaround": "scripts/one_way.js disables the platform collider while the player moves upward.",
  "workaroundFiles": ["scripts/one_way.js"],
  "suggestion": "Add Collider2D.oneWay (bool) with a configurable direction.",
  "effort": "small"
}
```

## Fields

- `category`: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation,
  tooling, ai-integration, docs, platform, performance, networking, other.
- `severity`: `blocker` (could not build it), `major` (big or fragile workaround), `minor` (small
  workaround), `nice-to-have`.
- `title`: short noun phrase; reuse the same wording for the same gap.
- `missing`, `workaround`: required. `workaroundFiles`, `suggestion`, `effort` (small/medium/large), `distinctFrom` (ids never merged with),
  `reporter` ({kind, agent, model}): optional.
- Maintained automatically: `id` (FB-0001...), `date` (UTC), `occurrences`, `notes` (one line per merged
  report: `date: workaround`), `status` (open, fixed-in-engine, wont-fix, duplicate), `engineIssue`.

## Deduplication

A new report is merged into an existing **open** entry with the same `category` and a similar `title`
(token overlap after dropping filler words such as "no", "missing", "support", or a small edit
distance). The entry's `occurrences` increases, the new workaround is appended to `notes`, the severity
is raised if the new report is more severe, and the longer `suggestion` wins. The command returns
`{id, merged: true}`.

## Archive

`ENGINE_FEEDBACK.json` keeps what is still open. Every entry whose `status` is not `open` (`fixed-in-engine`,
`wont-fix`, `duplicate`) moves to `ENGINE_FEEDBACK.archive.json` next to it, in the same format. This happens when the
editor opens the project and when you run the command `feedback.archive` (MCP `feedback_archive`, CLI
`factoria feedback archive [project]`); running it again moves nothing. The archive is written before the feedback
file, so an interruption can leave an entry in both files but never loses one. Both files are left out of exports.

- Ids stay unique across both files: a new entry never reuses an archived id.
- A report that matches an archived `fixed-in-engine` entry (same category, similar title) does not start a new
  entry: the archived one moves back to `ENGINE_FEEDBACK.json` as `open`, its `occurrences` goes up and `notes` gets
  "reported again with engine X: regression?". The command returns `reopened: true`. Archived `wont-fix` and
  `duplicate` entries are not reopened by a report.
- `feedback.update` also finds archived entries; setting one to `open` moves it back.
- `feedback.list` shows the open file only; `includeArchive: true` (CLI `feedback list --archive`) adds the archived
  entries, marked `archived: true`, and the result has `archivedCount`.
- The editor's Engine Feedback panel lists the open file; "Archive closed" moves the
  closed ones right away.
- `feedback collect` reads the archive next to each file, so its output is the same before and after archiving
  (closed entries still count only with `--include-closed`).

## Sharing with the engine developer

An entry may carry `share`: a generic copy of the gap, written in engine terms only, that can be sent to the engine
developer so the gaps of every game reach the roadmap. The rest of the entry (`title`, `missing`, `workaround`, `notes`,
files) stays in your project's file and is never sent.

`share` is `{title (8-120 characters), missing (20-1500), suggestion? (up to 1500), workaround? (up to 1500)}`. Write the gap
the way it would be true in any game: "Collider2D has no one-way option, so a body cannot pass up through a platform and
land on it." Not: "the player of Lantern Keep cannot jump through the crypt platforms in scripts/jump.js". Use engine names
(components, fields, commands, the scripting API) and nothing from the game. `reviewed: true` says that you checked against
the docs that the gap is real and about the engine, not a mistake in the game.

```json
{"category": "physics", "severity": "major", "title": "No one-way platforms",
 "missing": "Collider2D has no one-way option", "workaround": "scripts/one_way.js disables the collider going up",
 "share": {"title": "No one-way platforms",
           "missing": "Collider2D has no one-way option, so a body cannot pass up through a platform and land on it.",
           "suggestion": "Add Collider2D.oneWay (bool)."},
 "reviewed": true}
```

`feedback.report` and `factoria feedback add` take `share` and `reviewed` (CLI: `--share-title`, `--share-missing`,
`--share-suggestion`, `--share-workaround`, `--reviewed`). A `share` that is malformed or outside the limits is not stored;
the answer says why and the entry is recorded anyway. Reporting the same gap again keeps the longer `share`.

### What is sent, what never is

Sent, for each entry: `localId` (FB-0003), `category`, `severity`, `effort`, the sanitized `title`, `missing`, `suggestion`
and `workaround`, `reporterKind` (`ai` or `human`) and `reviewed`; per request, the engine version and the platform (macos,
windows, linux or other). Also sent with every request: a random installation id (UUID v4, created the first time, tied to no
project and to no person) so that one installation counts once per gap, and, only if you signed in, the credential.

Never sent: the project's name, id or version, file names and paths, scene, prefab, entity and script names, localization
keys, the entry's own `title`, `missing`, `workaround`, `workaroundFiles`, `notes`, screenshots, code or assets.

Before anything is queued a deterministic sanitizer cleans `share`: it removes paths and file names (anything with an
extension), URLs, e-mail addresses, quoted text (`"..."`, `'...'`, backticks, guillemets) except names the engine itself
defines, the project's own names, control characters and runs of more than 8 equal characters. If a field drops under its
minimum after cleaning, the entry is not sent and `shared.reason` says why. `factoria feedback share --preview` (command
`feedback.share_preview`) prints exactly what would be sent and what was removed; it sends nothing.

### Modes: only you choose

Nothing is sent until you choose, once, in your terminal:

| Command | Effect |
|---|---|
| `factoria feedback sharing always` | New shareable entries are sent as they are recorded. |
| `factoria feedback sharing ask` | They wait in the outbox; `factoria feedback share` shows them and sends what you confirm. |
| `factoria feedback sharing never` | Nothing is sent; the outbox is emptied and its entries are marked `skipped`. |
| `factoria feedback sharing` | Shows the mode, the server, whether you are signed in and the outbox. |

No command an AI can call changes the mode (`feedback.share_status` only reads it). While it is unset, `feedback.report`
answers `share.status: "not_set_up"` with how the user turns sharing on, and nothing is queued or written. The setting
lives in `feedback-sharing.json` and the outbox in `feedback-outbox.json`, both in the user config folder (`~/.factoria/` or
`%APPDATA%\factoria\`, next to `ai.json`; `FACTORIA_AI_CONFIG` moves the whole set).

Sending never makes a command fail and never waits long: with `always`, `feedback.report` makes one short attempt (3 s) and
otherwise leaves the entry in the outbox, retried after 1 minute, 10 minutes, 1 hour and then once a day while the server
is unreachable or busy (a `429` waits for its `Retry-After`). The server may refuse an entry (`shared.status: "rejected"`
with its reason) or ban an installation; neither is retried. `shared.status` is `pending`, `sent`, `rejected` or `skipped`.
`feedback.share` (AI) sends what is due and allowed by the mode; `factoria feedback share` (person) sends now, ignoring the
waiting times.

### Signing in (optional)

`factoria feedback signin github` uses GitHub's device flow: it prints a code to type at github.com/login/device. No GitHub
permission is requested. The GitHub token goes once to the feedback server, which answers a credential; only the credential
and your login are kept. `factoria feedback signout` forgets them. Reports are accepted without signing in.

### Builds without a server

The feedback server address and the GitHub client id are compiled in (CMake cache variables `FA_FEEDBACK_URL` and
`FA_FEEDBACK_GITHUB_CLIENT_ID`, empty by default). Without an address every sharing command says that sharing is not
available in this build and how to set it (`endpoint` in `feedback-sharing.json` overrides it, for tests and self-hosting).

### Fixed gaps

Each release ships a list of the gaps it fixed (`feedback/fixed.json`, embedded in the binary). When the editor opens a
project, and on `feedback.check_fixed`, every open entry with the same category (or family, e.g. `rendering-2d` and
`rendering-3d`) and a title (`title` or `share.title`) similar to one of the fix's titles becomes `fixed-in-engine`, with
`engineIssue` "FactorIA <version>" and a note to check whether your workaround can go; the next archive moves it to
`ENGINE_FEEDBACK.archive.json`. Reporting the gap again reopens it as a possible regression.

## Collecting (engine developers)

`factoria feedback collect <dirs-or-files...> [--out report.md|report.json]` groups similar entries across
projects and ranks them by `sum(occurrences) x severity weight` (blocker 8, major 4, minor 2,
nice-to-have 1). Each group lists title, category, projects affected, total occurrences, the best
suggestion and sample workarounds. Only `open` entries count unless `--include-closed` is given.

Two entries merge when their title, category, `suggestion` and `missing` text are alike enough (a title that merely
contains another needs four shared significant words). The report prints, under each group with several entries, the
similarity of each entry to the group (`Merged`), so a triage can check the merges. When two entries are different gaps
that read alike, list the id in `distinctFrom` on either one (`"distinctFrom": ["FB-0011"]`; `"<project>/FB-0011"` for an
entry of another project's file): `collect` never puts them in one group.
