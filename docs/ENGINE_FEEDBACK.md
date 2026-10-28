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
- The editor's Engine Feedback panel lists the open file; "Show archive" adds the archived entries and "Archive
  closed" moves the closed ones right away.
- `feedback collect` reads the archive next to each file, so its output is the same before and after archiving
  (closed entries still count only with `--include-closed`).

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
