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
| `factoria feedback sharing always` | New shareable entries are sent as they are recorded. |
| `factoria feedback sharing ask` | They wait in the outbox; `factoria feedback share` shows them and sends what you confirm. |
| `factoria feedback sharing never` | Nothing is sent; the outbox is emptied and its entries are marked `skipped`. |
| `factoria feedback sharing` | Shows the mode, the server, whether you are signed in and the outbox. |

In the editor the three choices are **Always**, **Ask me each time** and **Never**, with a preview of the next report exactly as
it would leave the computer.

### One project can choose differently

The mode above is your **default**. A project can have its own: **never** for a game under NDA, **always** for one you want to
share, **ask**, or no choice (it follows the default). Type it in the project (or give its folder):

| Command | Effect |
|---|---|
| `factoria feedback sharing never --project .` | This project sends nothing, whatever the default is. Its outbox items are dropped and its entries marked `skipped`. |
| `factoria feedback sharing always --project ../puzzle` | That project shares even when your default is `never` or not chosen. |
| `factoria feedback sharing default --project .` (or `--clear`) | Removes the project's choice: it follows your default again. |
| `factoria feedback sharing` | Shows your default and the effective mode of the project you are in, with its source (`its own choice` or `follows your default`). |

The effective mode of a project is its own choice if it has one, else your default. Queueing, sending, the outbox, the verdict
check, `feedback.share_preview`, `feedback.share_status` (`mode` is the effective one; `default` and `project{mode, source}` say
where it comes from) and the answer of `feedback.report` about sharing all use it. If a project is `never` (or not set up, with
no default) while items of it are in the outbox, they are not sent and `feedback.share_status` counts them in
`outbox.blocked`; going back to a mode that sends lets them go.

The choice is stored in YOUR `feedback-sharing.json` (`"projects": {"<project folder path>": "never"}`), never inside the
project, so a project you copy or download can never turn sharing on. The key is the folder's absolute path (symlinks resolved,
forward slashes, no trailing slash, case-insensitive on Windows). **Moving or renaming the project folder drops its choice back to
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
5. **Collect** what is left: `factoria feedback collect <inbox> --out roadmap.md`.

A reason is plain text, 1 to 500 characters, whitespace collapsed, and it is shown verbatim to the person who sent the report, so write
only about that report: what the engine has and where it is documented (a component, a field, a command, a doc page), or why it is not an engine
gap. Never mention other installations, other users or anything from the inbox that is not in the report itself. Start from the ready
reason of the suggestion. The server keeps the verdict; the person sees it the next time the editor asks, and can delete the entry.
