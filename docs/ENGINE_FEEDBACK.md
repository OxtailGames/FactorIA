# ENGINE_FEEDBACK.json

Every FactorIA game keeps an `ENGINE_FEEDBACK.json` at its root. AIs (and people) record there what the
engine lacked and how they worked around it. Engine developers merge many projects' files into a ranked
list of what to build next. `factoria validate` fails if the file is missing or invalid.

## When to write an entry

Immediately, whenever the engine lacked a feature, had a bug, gave a misleading error, or a doc was wrong
or missing, AND you built a workaround or dropped the feature. Do not wait until the end of the task.
Duplicates are harmless: a report similar to an open entry is merged into it.

Before you write a gap down, look for it: `factoria docs search "<the thing>"`, `components.list`, the API reference. An entry that says
the engine lacks something it has is refused (next section) or rejected later, so it costs time for nobody's benefit. The example
below is invented: "No fluid simulation" is NOT a report to file, only an illustration of the shape of one.

## The check before filing

`feedback.report` (MCP, CLI, `factoria feedback add`) and the editor's Add feedback window run a check first: does the
engine already have what the report says is missing? The words of the report are compared with the names the engine publishes (the
reflected components and their fields, the commands, the scripting API). The report is REFUSED when its own words tie the claim to
an existing name: a lead like "no", "missing", "add", "lacks", "without", "needs", "does not have" right before it, or "does not
exist" / "is missing" right after it; the name is an identifier (`Collider2D.oneWay`) or a field written as words ("one-way" is
`oneWay`) of a component the report names, or distinctive on its own; and nothing in the report says the thing exists but
misbehaves. The refusal teaches: what exists, its doc string, where it is documented, and what to do if it does not work.

- **Not working as documented is a bug, and a bug is accepted.** Say what you tried and what happened ("I set `Collider2D.oneWay`
  to true on the platform and a body still collides from below"): words like "ignored", "has no effect", "does not work", "I set"
  switch the check off, and the report goes in as any other.
- **An extra option on an existing component is accepted**: "Collider2D has no bounce curve" names a field that is not there, so
  nothing is refused. When in doubt the check accepts.
- `feedback.check` (CLI `factoria feedback check --title T --missing TEXT`) runs the check without filing: `{exists, matches[], related[]}`,
  with the related docs to read. With `entries: true` (CLI `--entries`) it checks the open entries of the project, and with `reject: true`
  (`--reject`) it also rejects the ones that fail. `factoria validate` warns about each open entry that fails it.

## Rejected entries

An open entry that fails the check is not a gap. It gets the status `rejected`, with who decided and why:

- `status: "rejected"`, `statusReason`: plain text, one line, at most 500 characters (what exists and where it is documented, or why
  it is not an engine gap) and `statusBy`: `engine` (the check, when the editor opens the project or after `factoria feedback check --entries
  --reject`), `user` (a person picked it in the editor, which asks for the reason) or `developer` (the engine developers rejected the
  report you shared: see Sharing). A rejection always has a reason; `feedback.update` with `status: "rejected"` and no
  `statusReason` is an error.
- A rejected entry is closed: it moves to `ENGINE_FEEDBACK.archive.json` like any other. The editor's Engine Feedback panel lists it when
  you tick **closed**, with the status and a `*` marker; hover the status for who decided and why. Its window shows the reason.
- A person who disagrees reopens it (status `open`): the entry then carries `claimCheck: "dismissed"` and the engine never rejects it again.
- Do not confuse it with `shared.status: "rejected"`: that one says the feedback SERVER refused the text of a report (privacy or format
  check, docs/design/FEEDBACK_SHARING.md). A report the engine developers refused is `shared.status: "declined"`.
- Delete: `feedback.delete` (CLI `factoria feedback discard <id>`; the editor's Delete button asks first). It removes a closed entry (from the
  file or the archive) or an open entry the engine developers refused. An open entry that is somebody's question for the engine
  developers is refused with the reason. Ids are never reused (`nextId` in both files), and what was already sent stays with the
  engine developers. The entry also leaves the outbox.

## How

| Way | Use |
|---|---|
| Command `feedback.report` (MCP tool `feedback_report`, CLI `factoria call feedback.report '{...}'`) | Preferred: assigns id and date, merges duplicates |
| `feedback.share_preview`, `feedback.share_status`, `feedback.share`, `feedback.check_fixed` | Sharing with the engine developer (see Sharing) |
| `feedback.list`, `feedback.update`, `feedback.check`, `feedback.delete` | Inspect entries; engine developers change `status` / `engineIssue` (`rejected` needs `statusReason`); check a claim; delete a closed entry |
| `feedback.archive` (CLI `factoria feedback archive`) | Move the closed entries to the archive (see Archive) |
| Edit the JSON | Allowed; keep it valid against `schemas/engine-feedback.schema.json` |

```json
{
  "category": "physics",
  "severity": "major",
  "title": "No fluid simulation",
  "missing": "There is no liquid solver, so water cannot flow around bodies and fill a container.",
  "workaround": "scripts/water.js moves sprites to fake a water surface.",
  "workaroundFiles": ["scripts/water.js"],
  "suggestion": "Add a particle-based Fluid2D component.",
  "effort": "small"
}
```

## Fields

- `category`: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation,
  tooling, ai-integration, docs, platform, performance, networking, other.
- `severity`: `blocker` (could not build it), `major` (big or fragile workaround), `minor` (small
  workaround), `nice-to-have`.
- `kind`: `gap` (the default: what the engine lacks or gets wrong) or `efficiency` (see Efficiency feedback, which has more fields).
- `title`: short noun phrase; reuse the same wording for the same gap.
- `missing`, `workaround`: required. `workaroundFiles`, `suggestion`, `effort` (small/medium/large), `distinctFrom` (ids never merged with),
  `reporter` ({kind, agent, model}): optional.
- Maintained automatically: `id` (FB-0001...), `date` (UTC), `occurrences`, `notes` (one line per merged
  report: `date: workaround`), `status` (open, fixed-in-engine, wont-fix, duplicate, rejected), `engineIssue`, and for a closed entry `statusReason` / `statusBy`
  (see Rejected entries).

## Deduplication

A new report is merged into an existing **open** entry with the same `category` and a similar `title`
(token overlap after dropping filler words such as "no", "missing", "support", or a small edit
distance). The entry's `occurrences` increases, the new workaround is appended to `notes`, the severity
is raised if the new report is more severe, and the longer `suggestion` wins. The command returns
`{id, merged: true}`.

## Efficiency feedback

The other kind of entry: the engine lacked nothing and nothing was wrong, but the work took many more steps, minutes or tokens than a
doc, a guide, an example or a command option could have made it ("with a guide for X this game would have taken 40 fewer steps").
File it with `feedback.report` and `kind: "efficiency"` (CLI `factoria feedback add --kind efficiency`). The retrospective
(`ai.retrospective`, docs/AI_PROVIDERS.md, "Retrospective") finds the candidates for you; you can also file one by hand. An efficiency
entry has the same `category` list, and is only worth filing when it is **measured** and **worth its fix**.

**When to file.** After a run, not during it: when you look back and one stretch of it (a system you understood only after forty steps, a
doc you read five times, the same command called ten times where one call with an option would do) cost more than the thresholds below
and a doc, a guide, an example or a command option would have removed it. File at most three per run, the ones with the biggest
saving. Do not file what only cost this game (a project fact), what is about the model you ran (the user's setting), or a saving that
is under its threshold: the gate refuses all of those, with the reason, before anything is written.

From the editor, the Feedback panel's **Retrospective** button runs the retrospective in the background and says what it filed; the
panel also adds up what the open efficiency entries' fixes would save per game. With `savers.retrospective` on in `ai.json` it also
runs after a long run (150 model calls or $3 by default).

```json
{
  "kind": "efficiency",
  "category": "scripting",
  "title": "Boss fight phases",
  "waste": "Making a boss that changes its behaviour at health thresholds took 40 steps of wiring states and timers by hand.",
  "evidence": [{"session": "20261014-153012-main", "fromStep": 12, "toStep": 52}],
  "fixType": "guide",
  "expectedSaving": {"share": 0.7, "why": "a guide gives the three calls that took the other 30 steps to find"},
  "appliesTo": "genre",
  "suggestion": "A boss fight topic guide: phases at health thresholds, attack timers, a telegraphed attack."
}
```

(Invented, like the example above: file only what your own transcripts show.)

- **Measured, not guessed.** `evidence` names the steps of a transcript (`.factoria/ai/sessions/<id>.jsonl`; `ai.session_timeline` lists
  the steps). The engine computes `measured` from them, `{steps, toolCalls, minutes, tokens, costUsd, estimated}`, and `saving` =
  `measured` times `expectedSaving.share`; the AI never writes the numbers. A step is one model call of the built-in agent (its own
  tokens and cost); for Claude Code, Codex and other CLI agents a step is one model turn, its tokens are estimated from the bytes (as
  `ai.session_timeline` does), the cost is not known and `estimated` is true. The minutes of a span run from the end of the step
  before it to the end of its last step. At most 10 spans per report; spans must not overlap.
- **The cheapest fix that removes the waste wins.** `fixType` is, cheapest first, `doc`, `guide`, `example`, `commandOption`,
  `newCommand`, `engineChange`. From a command option up, `whyNotCheaper` must say why a doc, a guide and an example would not have done.
- **Text loaded on every step costs on every step.** A fix that adds text to AGENTS.md or the system prompt must give `everyStepTokens`
  and save more than that times the steps of the named sessions; most fixes belong in an on-demand guide (`fixType: guide`).
- **Only what helps other games.** `appliesTo` is `every-game`, `genre`, `feature` (one feature of the engine) or `this-game`. A lesson
  true only for this game is a project fact (`savers.projectFacts`), not feedback: the report is refused with `project_fact`. A different
  model, effort or limit is the user's setting: refused with `user_setting`.
- **The saving must reach the threshold of its fix**, per game where it applies:

| Fix type | Saving per game where it applies | Applies to | What the fix is |
|---|---|---|---|
| `doc` | 10 minutes or 100k tokens | any engine feature | a section in an existing doc, or its title and keywords |
| `guide` | 10 minutes or 100k tokens | any engine feature | an on-demand topic guide (a skill), not text loaded on every step |
| `example` | 15 minutes or 200k tokens | any engine feature | an example project or scene to copy |
| `commandOption` | 30 minutes or 500k tokens | every game or a genre (wider than one feature) | an option on a command that exists |
| `newCommand` | 30 minutes or 500k tokens | every game or a genre (wider than one feature) | a command that does in one call what takes several |
| `engineChange` | 60 minutes or $5 | every game or a genre (wider than one feature) | a change to the engine (a candidate for triage) |

  A saving under the threshold is refused with `below_threshold`, and the refusal says which fix types that saving does justify.
  An `engineChange` is only a **candidate**: it goes on the roadmap when the reports that ask for it add up, across games, to $1000 or
  20 hours.
- **A "missing guide" for a doc that exists is refused** (`exists_in_docs`): the gate runs `docs.search` with the words of the report's
  title and suggestion, and a section of the docs that carries them is the answer. If you could not FIND it, it is a findability
  report: list in `searched` the words you gave `docs.search`; they are accepted only when they do NOT find that section, the entry
  stores `existingDoc` (where it is) and the fix is that section's title and keywords.

A refusal says the field (a JSON pointer such as `/evidence/0/toStep`), what is wrong and what to do; its `code` is `invalid_argument`,
`no_evidence`, `not_cheapest`, `costs_every_step`, `project_fact`, `user_setting`, `exists_in_docs` or `below_threshold`. Nothing is
written when a report is refused. An accepted one answers `{id, kind, merged, alreadyCounted, occurrences, measured, saving, message}`.

**Deduplication by fix.** An efficiency entry is merged into an open efficiency entry with the same category, the same `fixType` and a
similar `title` or `suggestion`: `occurrences` goes up, the `measured` and `saving` numbers of the new spans are ADDED, and a note is
appended. Reporting steps the entry already counts changes nothing (`alreadyCounted: true`), so a retry or a second retrospective of the
same session never counts twice. `feedback.list` and `factoria feedback list` take `kind` / `--kind` (`gap` or `efficiency`) and show the
saving of efficiency entries.

### Three reports that pass the gate, three that are refused

The report at the top of this section (a boss fight guide) is the first good one. Two more, a command option and an example (invented like the
first; a test runs all three through the gate against a transcript of the length they name, so they stay valid):

```json
{
  "kind": "efficiency",
  "category": "scene",
  "title": "Placing many entities of one prefab",
  "waste": "Filling a level took one prefab spawn call per entity, 50 calls where one call with a list of positions would do.",
  "evidence": [{"session": "20261014-153012-main", "fromStep": 8, "toStep": 58}],
  "fixType": "commandOption",
  "whyNotCheaper": "A doc cannot shorten the calls: each entity still needs its own call, and an example only shows the 50 calls.",
  "expectedSaving": {"share": 0.8, "why": "one call with a positions list replaces the 40 calls that only repeated the first"},
  "appliesTo": "every-game",
  "suggestion": "A positions list on the prefab spawn command, so one call places all the copies."
}
```

```json
{
  "kind": "efficiency",
  "category": "ui",
  "title": "A gamepad-navigable menu",
  "waste": "Making a menu that the gamepad and the keyboard both move through took 26 steps of wiring focus by hand.",
  "evidence": [{"session": "20261014-153012-main", "fromStep": 5, "toStep": 30}],
  "fixType": "example",
  "expectedSaving": {"share": 0.7, "why": "a menu scene to copy has the focus wiring, so the 26 steps become a rename"},
  "appliesTo": "feature",
  "suggestion": "An example menu scene with focus navigation for the gamepad and the keyboard."
}
```

Three reports the gate refuses. Each refusal is what the gate answers (`code`, `message`, `hint`); nothing is written.

1. **"Rewrite the scene format to save 2k tokens."** An `engineChange` for 2000 tokens (0.4 minutes, $0.02). An engine change is justified
   from 60 minutes or $5 per game, and goes on the roadmap only when the reports add up to $1000 or 20 hours across games.

```text
code: below_threshold
message: The saving is 0.4 minutes, 2000 tokens, $0.02 per game (the measured span times /expectedSaving/share); an engineChange is justified from 60 minutes or $5.
hint: Not worth filing. Waste this small is part of how the work goes; it is not engine feedback. (An engine change goes on the roadmap only when the reports add up to $1000 or 20 hours across games.)
```

2. **"Use a cheaper model."** The model, the effort and the limits are the user's settings, not something the engine can fix.

```text
code: user_setting
message: The report asks for a different model, effort or limit: those are the user's settings, not engine feedback.
hint: The retrospective can suggest them to the user (ai.settings, the AI panel); an efficiency entry is about what the ENGINE could do so that any model needs fewer steps.
```

3. **"A guide for off-mesh links"** when docs/NAVIGATION.md already has the section and `docs.search` finds it. If you could not find it, say
   so: list in `searched` the words you gave `docs.search`, and the report becomes a findability report on that section's title and keywords.

```text
code: exists_in_docs
message: The docs already have a section that carries the words of this report: docs/NAVIGATION.md:83 (4. Off-mesh links: jumps, climbs and drops). A "missing guide" for something docs.search finds is not a missing guide.
hint: Read it. If you did and it did not help, say what is missing from it. If you could not FIND it, this is a findability report: list in /searched the words you gave docs.search (they must not find this section), and make the fix the title and keywords of docs/NAVIGATION.md:83 (4. Off-mesh links: jumps, climbs and drops).
```

(The line number in `docs/NAVIGATION.md:83` follows that file; a test compares these blocks with the gate's answers apart from it.)

### Sharing an efficiency entry

An efficiency entry is shared like a gap (the same modes, the same lock, the same outbox; "Sharing with the engine developer" below), and
it sends two things:

- the **text**: the entry's `waste`, cleaned by the same sanitizer as a gap's `share` (no path, file name, URL, quoted text or project name).
  An entry written by `feedback.report` derives its `share` from the waste and the suggestion, so there is nothing more to write; if the
  cleaned text is too short the entry is not sent and `shared.reason` says why;
- an **`efficiency` block** of numbers and words from the engine's own fixed lists: `fixType`, `appliesTo`, `measured` and `saving`
  (`steps`, `toolCalls`, `minutes`, `tokens`, `costUsd`, `estimated`), the expected share of the fix, how many stretches of runs the numbers
  add up (`spans`), and, for an entry filed after a fix did not remove the waste, `afterFix` (the engine version of that fix).

Never sent: `evidence`, the session ids (they carry the time a run started), the AI's other words, the local `pattern`, the game's names. An entry whose
`appliesTo` is `this-game` is a project fact and is not shared at all. The numbers are cumulative, so an entry that gets a new report
(another span of the same waste) is sent again (up to 20 times) and the server keeps the latest numbers of that installation instead of adding
them. `factoria feedback share --preview` shows the block with the rest.

### Did the fix work?

An efficiency entry the engine developer fixed (`fixed-in-engine`, with the version in `engineIssue` such as "FactorIA 0.17.2") records on
the entry: `fixedIn` (the version), `fixedAt` (the day), `fixBaseline` (what ONE occurrence cost before: steps, minutes, tokens, over its
spans) and, when the retrospective found it, `pattern` (the id of the waste pattern, local only). A later `ai.retrospective` of a game whose
engine is at least `fixedIn` reads the transcripts that began on or after `fixedAt` (the transcripts do not say which engine they ran on,
so the version of the running engine and the day stand for it) and compares the SAME pattern with the baseline. Its `fixChecks` answer, also
recorded on the entry as `fixCheck {result, ratio, ...}`:

| result | meaning |
|---|---|
| `waiting` | no run since the fix: nothing to compare yet (not recorded) |
| `gone` | the pattern is not found in the runs since the fix: it worked |
| `worked` | one occurrence costs half or less of what it did |
| `partial` | it costs less, but more than half (up to 80%) |
| `no_change` | it costs more than 80% of what it did: the fix saved nothing |

A pattern a fix did not remove (`partial`, `no_change`) that the retrospective files again carries `afterFix` (the version), which is
shared and shows in the engine developer's ranking, so a fix that saved nothing is visible. Nothing here asks a model, and `candidatesOnly`
returns the checks without writing them.

## Archive

`ENGINE_FEEDBACK.json` keeps what is still open. Every entry whose `status` is not `open` (`fixed-in-engine`,
`wont-fix`, `duplicate`, `rejected`) moves to `ENGINE_FEEDBACK.archive.json` next to it, in the same format. This happens when the
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
- The editor's Engine Feedback panel lists the open file. It moves an entry that is not open to the archive on its own, as
  soon as it sees it (when the project opens and when you change the status in the panel); there is no button for it.
- `feedback collect` reads the archive next to each file, so its output is the same before and after archiving
  (closed entries still count only with `--include-closed`).

## Sharing with the engine developer

An entry may carry `share`: a generic copy of the gap, written in engine terms only, that can be sent to the engine
developer so the gaps of every game reach the roadmap. The rest of the entry (`title`, `missing`, `workaround`, `notes`,
files) stays in your project's file and is never sent.

`share` is `{title (8-120 characters), missing (20-1500), suggestion? (up to 1500), workaround? (up to 1500)}`. Write the gap
the way it would be true in any game: "There is no liquid solver, so water cannot flow around bodies and fill a
container." Not: "the player of Lantern Keep cannot jump through the crypt platforms in scripts/jump.js". Use engine names
(components, fields, commands, the scripting API) and nothing from the game. `reviewed: true` says that you checked against
the docs that the gap is real and about the engine, not a mistake in the game.

```json
{"category": "physics", "severity": "major", "title": "No fluid simulation",
 "missing": "There is no liquid solver", "workaround": "scripts/water.js moves sprites to fake a water surface",
 "share": {"title": "No fluid simulation",
           "missing": "There is no liquid solver, so water cannot flow around bodies and fill a container.",
           "suggestion": "Add a particle-based Fluid2D component."},
 "reviewed": true}
```

An AI that reports a gap should always include `share`: it knows the engine's names, and the person then sends what the AI wrote
(the editor only makes a text from the entry when there is none). `feedback.report` and `factoria feedback add` take `share` and `reviewed` (CLI: `--share-title`, `--share-missing`,
`--share-suggestion`, `--share-workaround`, `--reviewed`). A `share` that is malformed or outside the limits is not stored;
the answer says why and the entry is recorded anyway. Reporting the same gap again keeps the longer `share`.

### What is sent, what never is

Sent, for each entry: `localId` (FB-0003), `category`, `severity`, `effort`, the sanitized `title`, `missing`, `suggestion`
and `workaround`, `reporterKind` (`ai` or `human`) and `reviewed`; per request, the engine version and the platform (macos,
windows, linux or other). Also sent with every request: a random installation id (UUID v4, created the first time, tied to no
project and to no person) so that one installation counts once per gap, and, only if you signed in, the credential.

An efficiency entry also sends a block of numbers and fixed words (fix type, where it applies, what was measured and what the fix would
save; "Sharing an efficiency entry" above) and nothing of its evidence or session ids.

Never sent: the project's name, id or version, file names and paths, scene, prefab, entity and script names, localization
keys, the entry's own `title`, `missing`, `workaround`, `workaroundFiles`, `notes`, screenshots, code or assets.

Before anything is queued a deterministic sanitizer cleans `share`: it removes paths and file names (anything with an
extension), URLs, e-mail addresses, quoted text (`"..."`, `'...'`, backticks, guillemets) except names the engine itself
defines, the project's own names, control characters and runs of more than 8 equal characters. If a field drops under its
minimum after cleaning, the entry is not sent and `shared.reason` says why. `factoria feedback share --preview` (command
`feedback.share_preview`) prints exactly what would be sent and what was removed; it sends nothing.

### Modes: only you choose

Nothing is sent until you choose, once, in the editor (the consent dialog it shows the first time, or File > Feedback
Settings; docs/EDITOR.md, "Sharing feedback") or in your terminal:

| Command | Effect |
|---|---|
| `factoria feedback sharing always` | New shareable entries are sent as they are recorded; entries that waited for your answer are sent too. |
| `factoria feedback sharing ask` | They wait in the outbox; `factoria feedback share` shows them and sends what you confirm. Items queued but not sent yet go back to waiting. |
| `factoria feedback sharing never` | Nothing is sent; the outbox items of every project that follows your default are dropped and their entries marked `skipped`. A project with its own choice keeps its items and its mode. |
| `factoria feedback sharing` | Shows the mode, the server, whether you are signed in and the outbox. |

In the editor the three choices are **Always**, **Ask me each time** and **Never**, with a preview of the next report exactly as
it would leave the computer.

### One project can choose differently

The mode above is your **default**. A project can have its own: **never** for a game under NDA, **always** for one you want to
share, **ask**, or no choice (it follows the default). Type it in the project (or give its folder):

| Command | Effect |
|---|---|
| `factoria feedback sharing never --project .` | This project sends nothing, whatever the default is. Its outbox items are dropped and its entries marked `skipped`. |
| `factoria feedback sharing always --project ../puzzle` | That project shares even when your default is `never` or not chosen. Choosing `always` for a project is a yes for what waited there, also what waited under the default. |
| `factoria feedback sharing ask --project .` | That project asks, whatever the default is; its queued items go back to waiting for your answer. |
| `factoria feedback sharing default --project .` (or `--clear`, alone) | Removes the project's choice: it follows your default again, and its queued items are handled as that default says (a default of `never` drops them). Removing a choice is not a yes: what waited for your answer under the project's `ask` stays waiting even when your default is `always` (the command and the editor say so) until you confirm it with `factoria feedback share`. |
| `factoria feedback sharing` | Shows your default and the effective mode of the project you are in, with its source (`its own choice` or `follows your default`). |

`--project <path>` takes the project's folder or any folder inside it (the nearest `factoria.json` upwards is the project); a folder
that is not in a project is an error that says so, and the command prints the project it used. `--clear` with a mode is a usage
error.

The effective mode of a project is its own choice if it has one, else your default. Queueing, sending, the outbox, the verdict
check, `feedback.share_preview`, `feedback.share_status` (`mode` is the effective one; `default` and `project{mode, source}` say
where it comes from) and the answer of `feedback.report` about sharing all use it. If a project is `never` (or not set up, with
no default) while items of it are in the outbox, they are not sent and `feedback.share_status` counts them in
`outbox.blocked`; going back to a mode that sends lets them go. Each outbox item stores the key of the project it came from when
it is queued, and every later decision (send, wait, drop) uses that key, so changing your default never moves the items of a
project with its own choice: a default of `always` does not send what a project set to `ask` or `never` holds, and a default of
`never` does not drop what a project set to `always` holds. Items written by an older version have no key: they wait (as in `ask`)
until you decide in the editor or with `factoria feedback share`. Queueing again never releases an item that waits: only you do (a
confirmation, or choosing `always`). Each queued item also remembers whether `always` or you confirmed it: before it is sent, an item
queued by `always` is checked against the settings as they are at that moment, and if its project is no longer on `always` (you changed
it in another window, or edited the file) it goes back to waiting instead of leaving. `never` stops every batch that was not sent yet; a
batch whose upload had already started when you chose it finishes, and the editor and the command say so. `factoria feedback share`
only handles the project you are in: with no ENGINE_FEEDBACK.json there, or outside a project, it says so and sends nothing (not even
what another project left in the outbox).

If the folder of a project cannot be resolved (a permission, a disconnected volume), its mode reads as `ask`, never as your default;
`feedback.share_status` says `unresolved`. The same holds for an item in the outbox whose project folder no longer exists (deleted,
moved, an unplugged drive) and that has no choice of its own listed under that exact path: it waits for your answer instead of following
the default. Another spelling of the same folder in your settings file (another case on a volume that
ignores it, NFC against NFD on macOS, a symlink) finds the same choice. The settings and the outbox are changed under a lock file
(`feedback-share.lock` next to them), so the editor, the terminal and the MCP server never undo each other's changes: a lock left by
a program that died (its file not refreshed for 10 seconds, or dated in the future) is taken over, and a change that finds the lock
busy for 12 seconds fails with a message and changes nothing. That holds for every change: choosing a mode, skipping, dropping,
confirming or discarding an entry (`feedback.delete` and `factoria feedback discard` keep the entry when the outbox cannot be updated, so
a deleted entry never stays sendable), and the command line says so and exits with an error. The editor never waits more than a third
of a second for it: it tells you ("could not be queued for sharing yet", or the action's own message) and tries again.

Writing `ENGINE_FEEDBACK.json` itself (a report, an efficiency entry a retrospective files, the note of a fix check) takes the same
lock, so two programs writing the file at once never lose an entry. A report must not need your user folder: when `~/.factoria`
cannot be written (a read-only home, a sandbox), the report is filed under a lock of the same kind in the project's own
`.factoria` folder instead, and only when neither folder can be written does it fail, with a message that names both.

The choice is stored in YOUR `feedback-sharing.json` (`"projects": {"<project folder path>": "never"}`), never inside the
project, so a project you copy or download does not inherit the choice: it follows your default. The key is the folder's absolute
path (symlinks resolved, UTF-8, forward slashes, no trailing slash, lower-cased on Windows and on a volume that ignores case, as
macOS does by default). If the file has two keys for the same folder (edited by hand), the most restrictive mode wins and a warning
says so; the next save writes one entry. **Moving or renaming the project folder drops its choice back to
your default**; set it again from the new place. No command an AI can call sets it.

In the editor you never write a share text. The Engine Feedback panel has two buttons. **Add feedback** opens a form
(category, severity, title, what is missing, workaround, suggestion) that only records the entry. **Send feedback** opens a
window that lists every entry that would go (open, not sent yet, not refused by the server), all checked, each with the exact
text that leaves the computer: the entry's `share` when it has one, otherwise a text the editor makes from the entry's title,
what is missing and suggestion with the sanitizer's cuts applied (an entry too short to make a text from is listed unchecked
with the reason). **Send** stores that text in the entry, queues the checked entries and sends them at once; what you uncheck is
marked `skipped` and offered again, unchecked, the next time. **Cancel** changes nothing. When an AI model is set up, each text
that was not reviewed is checked in the background while the window is open (see Review with AI): a pass can replace the text
with the engine-terms rewrite, a fail unchecks the row and says why; with no model the texts are shown as they are. In Always
mode an entry that already has a `share` still goes out as it is written; the entries without one wait for Send feedback.
In Ask mode the editor notifies you when entries with a `share` wait and the notification opens the same window. The panel's
table has a share column (not sent, waiting, sent, rejected with its reason, skipped). With sharing set to Never the Send
feedback button is disabled.

No command an AI can call changes the mode (`feedback.share_status` only reads it). While it is unset, `feedback.report`
answers `share.status: "not_set_up"` with how the user turns sharing on, and nothing is queued or written. The setting
lives in `feedback-sharing.json` and the outbox in `feedback-outbox.json`, both in the user config folder (`~/.factoria/` or
`%APPDATA%\factoria\`, next to `ai.json`; `FACTORIA_AI_CONFIG` moves the whole set).

Sending never makes a command fail and never waits long: with `always`, `feedback.report` makes one short attempt (3 s) and
otherwise leaves the entry in the outbox, retried after 1 minute, 10 minutes, 1 hour and then once a day while the server
is unreachable or busy (a `429` waits for its `Retry-After`). The server may refuse an entry (`shared.status: "rejected"`
with its reason) or ban an installation; neither is retried. `shared.status` is `pending`, `sent`, `rejected`, `skipped` or `declined` (the engine developers rejected the report).
Hitting a gap again after it was sent (the entry is merged and its `occurrences` go up) sends it once more, so the
developer sees it matters to you; `shared.occurrences` counts the sends, and after 3 nothing more goes (the developer's
ranking counts at most 3 per installation).
`feedback.share` (AI) sends what is due and allowed by the mode; `factoria feedback share` (person) sends now, ignoring the
waiting times.

### The engine developers' answer

The engine developers may reject a report you shared (it claims a gap the engine does not have, or it is not about the engine) and say
why. Your installation asks the server about this on its own, about every 30 minutes while sharing is on (Always or Ask): `POST
/v1/verdicts` with the `shareId`s of the entries of THIS file that were sent, authenticated by the installation header; the server only
answers for reports of that installation. A rejected report becomes `status: "rejected"`, `statusBy: "developer"`, `statusReason` = their
reason (shown as it is, 500 characters at most), and `shared.status: "declined"`; it moves to the archive and is not sent again. If the
engine developers take the rejection back the entry is sent and open again. `factoria feedback share --verdicts` asks at once. A server
that does not know verdicts yet (older) answers 404 and nothing changes. You can delete a declined entry (see Rejected entries).

### Review with AI

`ai.review_feedback {id}` (the editor runs it for you on every text in the Send feedback window; `share` optionally passes a
candidate text to check instead of the stored one, and then nothing is written) has a cheap model check a `share` text
before it can leave the machine: the gap is real, it is about the engine and not about the game, and the engine cannot do it
already (it reads the command list and the documentation). The text also goes through the sanitizer. On a pass the entry is
marked `reviewed: true` and `share` is rewritten in engine terms if it needed it; on a fail nothing changes and the answer has
`reasons` and `fix`. It runs on the `fast` role of `ai.json` (the orchestrator when `fast` is off; docs/AI_PROVIDERS.md), spends
tokens, sends nothing and never changes the mode. An AI writes `share` in engine terms and may run it after `feedback.report`;
a person can run it too (`factoria call ai.review_feedback '{"id":"FB-0003"}'`).

### Signing in (optional)

`factoria feedback signin github` (in the editor: Feedback Settings > Sign in with GitHub, which shows the code and opens the
address) uses GitHub's device flow: the code is typed at github.com/login/device. No GitHub
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
projects and ranks them. Each group lists title, category, installations (projects), verified installations, total
occurrences, the best suggestion and sample workarounds. Only `open` entries count unless `--include-closed` is given.

The score of a group is the sum, over the projects (a pulled installation is one project) that have an entry in it, of
`severity weight x trust x min(occurrences, 3)`:

- Severity weight: blocker 8, major 4, minor 2, nice-to-have 1 (the highest in that project's entries of the group).
- Trust: 1 for a project of your own and for a pulled entry whose `remote.trust` is `verified` (the installation
  signed in with GitHub); 0.5 for an anonymous one (`remote.trust` `anonymous`).
- Occurrences of one project are capped at 3, so one installation that reports the same gap 50 times counts as 3, and
  ten installations that each report it once count as ten. `totalOccurrences` in the report is not capped.

A score with a half shows one decimal (1.5). The entries that `factoria feedback pull` writes
(see docs/EXTENDING.md, section F) are collected like any project: `factoria feedback collect ~/.factoria/feedback-inbox`.
The inbox's `quarantine/` folder holds `quarantine.json`, not an `ENGINE_FEEDBACK.json`, so collect ignores it.

Two entries merge when their title, category, `suggestion` and `missing` text are alike enough (a title that merely
contains another needs four shared significant words). The report prints, under each group with several entries, the
similarity of each entry to the group (`Merged`), so a triage can check the merges. When two entries are different gaps
that read alike, list the id in `distinctFrom` on either one (`"distinctFrom": ["FB-0011"]`; `"<project>/FB-0011"` for an
entry of another project's file): `collect` never puts them in one group.

### Efficiency entries

`collect` (and `feedback pull`, which prints the top of the same list) ranks the efficiency entries apart from the gaps, because what
matters is what a fix would SAVE, not how many people asked. Entries group by category, fix type and similar title, and a doc fix never merges
with a command's. Each group shows:

- the **total saving** across installations: for each installation (a pulled installation or a local project) its own entries' savings added
  once, however many reports it sent, an anonymous installation weighted 0.5 and a verified or local one 1; in minutes, tokens, dollars, and
  `hours` (the larger of the minutes and the dollars at $50 an hour, the exchange of the $1000 / 20 hours roadmap bar); and the same per game;
- the **fix cost** in hours of work (doc 0.5, guide 2, example 4, command option 4, new command 16; an engine change costs what the roadmap
  asks of the reports that want it);
- the **verdict**: `doc now` (a doc, guide or example), `command: worth it` or `command: not yet (H of the C hours it costs)` (the hours
  saved against the cost), `engine change: below threshold (N of the $1000 / 20 hours it needs)` or `engine change: reached the roadmap bar`;
- a **ready reason** (`rejectReason`, plain text, only that entry's own numbers) for each entry of a `doc now` or `below threshold` group, to
  pass to `feedback reject` when the entry is not worth doing; a command or an engine change that reached its bar has none (that is a
  decision, not a refusal), and a command that is `not yet` has none either: it waits for more reports;
- `afterFix`: the versions whose fix a report says did not remove the waste.

Sorted by hours saved, then dollars, tokens and title; minutes round to 0.1, dollars to cents, so the same inbox always prints the same list.
In `--format json` it is the `efficiency` array. A gap's score is unchanged.

## Triage loop (engine developers, usually an AI in this repository)

The engine-developer side reads what installations sent and answers each report. Nothing here asks a question: every command takes
its arguments, exits 0 when everything was done and 1 when a `shareId` is not on the server, and `--json` prints the result.

1. **Pull**: `factoria feedback pull` (an incremental pull; `--full` now and then). New reports go to the inbox, one
   `ENGINE_FEEDBACK.json` per installation. Every new report is also run through the check of `feedback add`: the ones that claim a gap the
   engine already has carry a `suggestedRejection` with a ready reason, and the command lists them ("SUGGESTED rejections").
2. **Check** the suggestions yourself: read the reason, open the doc it names, and decide per report. `factoria feedback check --title T --missing
   TEXT` runs the check on any text; `factoria docs search` finds the docs. The check is conservative, but a report that says the thing exists
   and misbehaves is a BUG: keep it (a bug is worth more than a missing feature).
3. **Reject or keep.**
   - `factoria feedback reject --suggested` rejects every suggested report with its ready reason; add shareIds to narrow it
     (`reject --suggested r_8f3k2m`), `--reason TEXT` to replace the ready reason.
   - `factoria feedback reject r_8f3k2m r_9abcde --reason "Collider2D.oneWay exists (docs/COMPONENTS.md). File a bug if it fails."`: the same
     reason for each; `--file batch.json` takes `[{"shareId": "r_8f3k2m", "reason": "..."}]`, one reason each.
   - `factoria feedback reject --quarantined --reason TEXT` tells the installations of the quarantined (junk) reports why (only the text you write is sent).
   - `factoria feedback keep r_8f3k2m` drops a wrong suggestion (without shareIds: all); nothing is sent.
4. **Unreject** a mistake: `factoria feedback unreject r_8f3k2m`: the installation's next check turns the entry back into a sent, open one.
5. **Collect** what is left: `factoria feedback collect <inbox> --out roadmap.md`. Efficiency entries come ranked by what their fix saves, each with its verdict
   and a ready reason ("Efficiency entries" above): do the `doc now` ones, build a command only when it is `worth it`, and for the `doc now` and
   `below threshold` ones that are not done, `feedback reject <shareId> --reason "<the entry's rejectReason>"` (the reason names only that
   entry's own numbers).
6. **Record the fix.** When an efficiency entry is fixed, `feedback update --status fixed-in-engine` with "FactorIA <version>" in the text
   (`feedback fixed add` for the list that ships) records `fixedIn`, `fixedAt` and the baseline; the retrospectives of the games on
   that version compare the same pattern before and after ("Did the fix work?"), and an entry filed again with `afterFix` is the proof that
   a fix saved nothing.

A reason is plain text, 1 to 500 characters, whitespace collapsed, and it is shown verbatim to the person who sent the report, so write
only about that report: what the engine has and where it is documented (a component, a field, a command, a doc page), or why it is not an engine
gap. Never mention other installations, other users or anything from the inbox that is not in the report itself. Start from the ready
reason of the suggestion. The server keeps the verdict; the person sees it the next time the editor asks, and can delete the entry.
