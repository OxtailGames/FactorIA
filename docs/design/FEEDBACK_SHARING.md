# Feedback sharing (M46): from a user's game to the engine developer

FactorIA has one engine developer. Games made by other people record engine gaps in their `ENGINE_FEEDBACK.json`
(docs/ENGINE_FEEDBACK.md); M46 sends a generic copy of each entry to the developer's own server, so the gaps of every
game reach the roadmap. This file is the contract the four M46 packages build on: the client in the engine, the
server, the developer's side and the editor. It is for engine developers and is not embedded in the binary.

## Principles

1. **Nothing about the game leaves the machine.** What is sent describes the engine only: what it lacks and the engine
   change that would fix it. The game's name, story, characters, assets, file names and paths, the detailed workaround
   and the notes stay in the local file. The developer must never learn what a game is about from feedback.
2. **Consent first.** Nothing is sent until the user chooses, in the editor or by typing a CLI command themself:
   `always`, `ask` (preview and confirm each batch) or `never`. An AI cannot set it: there is no command for it.
3. **The server decides, not the client.** The engine is MIT and the endpoint is public: anyone can post to it without
   FactorIA. Every limit that matters (validation, rate limits, bans) is enforced by the server. Checks in the client
   (the sanitizer, the user's AI review) raise quality for honest users; they are not security.
4. **One installation, one vote.** The ranking counts installations, not reports: repeating a report cannot push a gap
   up the list.
5. **Free to run and impossible to bill.** The server is a Cloudflare Worker with D1 on the free plan. Going over a
   limit makes it refuse requests until midnight UTC; it never costs money.
6. **The user hears back.** Each engine release ships a list of fixed gaps; matching open local entries are closed with
   the version that fixed them.

## Data model

### Local entry (`ENGINE_FEEDBACK.json`, schemas/engine-feedback.schema.json)

New optional fields on an entry:

- `share`: the generic copy, written in engine terms only: `{title, missing, suggestion?, workaround?}` (same meaning as
  the top-level fields, without anything about the game). `feedback.report` takes it as an argument; the editor can ask
  the user's AI to write it. An entry without `share` is never sent.
- `reviewed` (bool): the reporter or the user's AI checked, against the docs, that the gap is real and about the engine.
- `shared`: what the client did with it: `{status: "pending" | "sent" | "rejected" | "skipped", date?, shareId?,
  reason?}`. Written by the client only.
- `remote`: on entries pulled from the server (developer side only): `{shareId, installKey, trust: "verified" |
  "anonymous", receivedAt, engineVersion?, platform?}`.

### Sanitizer (client, deterministic)

Runs on `share` before anything is queued, and its result is what the preview shows. It removes or rejects:

- paths and file names (`/`, `\`, anything with a file extension such as `.js`, `.png`, `.json`), URLs, e-mail addresses;
- quoted text (`"..."`, `'...'`, `«...»`, backticks) other than names the engine itself defines (components, fields,
  commands, JS API names found in the command registry and reflection);
- the project's own names: the project name, scene, prefab, entity and script names, localization keys;
- text over the limits below, control characters, a character repeated more than 8 times.

If a field drops under its minimum after cleaning, the entry is not sent and `shared.reason` says why. The result lists
what was removed, so the preview can show it.

### Field limits (client and server)

| Field | Min | Max |
|---|---|---|
| `title` | 8 | 120 |
| `missing` | 20 | 1500 |
| `suggestion` | 0 | 1500 |
| `workaround` | 0 | 1500 |

`category`, `severity` and `effort` use the enums of the schema.

## Client (engine)

- **Settings**, user level, next to the user `ai.json` (`~/.factoria/` or `%APPDATA%\factoria\`), in
  `feedback-sharing.json`: `{mode: "unset" | "always" | "ask" | "never", projects?: {<project key>: "always" | "ask" |
  "never"}, installId (random UUID v4, created on the first send), credential? (from GitHub sign-in), login? (shown in the
  editor)}`. `mode` is the user's default; `projects` holds the choice of single projects. The effective mode of a project is its
  own entry, else the default. The map lives in the user's file, never in the project, so a copied project does not inherit the
  choice and follows the default. The key is the project folder's absolute path (symlinks resolved, UTF-8, forward slashes, no
  trailing slash, lower-cased on Windows and on volumes that ignore case); duplicate keys resolve to the most restrictive mode
  with a warning. The installation id is not tied to any project.
- **Endpoint**: compiled in (`FA_FEEDBACK_URL`, CMake cache variable; empty = sharing unavailable, and every command
  says so with how to fix it). The user config may override it (`endpoint`) for tests and self-hosting.
- **Outbox**: `feedback-outbox.json` in the same folder, the sanitized payloads waiting to be sent, retried with backoff
  (1 min, 10 min, 1 h, then once a day). An entry is in the outbox once. An entry merged again after it was sent (its
  `occurrences` went up) is queued once more, up to 3 sends (`shared.occurrences` counts them): each send is one more
  occurrence on the server, and the ranking counts at most 3 per installation. Each item stores `project`, the key of its
  project, when it is queued; sending, waiting and dropping decide by that key, so a change of the default does not touch the
  items of a project with its own mode. A change of one project's mode moves its items (ask: queued back to waiting; never:
  dropped and the entries marked `skipped`; always: waiting queued, also the ones that waited under the default: whoever
  chooses `always` for a project or for the default answers yes for what waits there). Removing a project's own choice
  (`Follow default`, `--clear`) is not a yes: what waited stays waiting even when the default is `always`, and the CLI and the
  editor say so. Queueing again (`share_queue`) never releases an item that waits, with or without `project`: only the user
  does (`share_confirm`, or choosing `always`). Items without `project` (older versions) wait until the user decides.
  Each queued item records `confirmedBy`: `always` (the mode was `always`, or a person chose `always`) or `user` (a person
  confirmed that item). Before every send the sender checks it against the settings as they are then: an `always` item goes
  out only while its project's mode is still `always`, otherwise it goes back to waiting (this covers a settings file edited
  by hand, or by another process, after the item was queued); a `user` item goes out under `ask` and `always`. An older
  queued item without the field reads as `always`. A batch whose request is already in flight cannot be called back: choosing
  `never` stops everything that was not sent, and the editor and the CLI say that an upload already in progress finishes.
- **Keys fail closed.** A stored key is looked up exactly; if it is not there, the project folder is compared (the same
  file on disk, `std::filesystem::equivalent`) with every stored key that exists, so another spelling of the folder (another
  case on a volume that ignores it, NFC against NFD on macOS, a symlink) still finds its choice; the most restrictive match
  counts. A project folder that cannot be resolved (permissions, a broken volume) reads as `ask`, never as the default
  (`feedback.share_status` says `source: unresolved`). The same for an outbox item whose folder no longer exists and that has no
  exact entry in `projects`: it reads as `ask` (a deleted project must not be sent because the default says `always`).
  `set_project_share_mode` applies the new mode to the items whose project is the same folder under any spelling, not only the
  ones whose stored key is equal. The facts about a folder (its key, whether it exists, whether two keys are one folder) are
  asked of the file system once per call.
- **Lock**: every read-modify-write of the settings and the outbox (a flush's save, `set_share_mode`,
  `set_project_share_mode`, queueing, confirming, dropping, sign-in and sign-out, creating the installation id) runs under
  `feedback-share.lock` in the config folder, a file made with an exclusive create (`O_EXCL` on POSIX, `CREATE_NEW` on
  Windows) so the editor, the CLI and the MCP server cannot undo each other's changes. Readers do not take it (files are
  replaced atomically). The file holds an owner token (process id and a random number); the holder deletes it only while it
  still holds its own token, so a lock that was taken over is never deleted under its new owner. A lock file not written for
  10 s was left by a process that died (or is dated more than 10 s in the future: a clock set back, a shared folder) and is
  taken over, one waiter at a time: the takeover itself needs a second exclusive-create file (`feedback-share.lock.takeover`),
  and the age is checked again inside it, so two waiters never both take it. A long change (many entries written) refreshes the
  file's time (`ShareLock::keep_alive`), so a live holder never looks dead. A busy lock is waited for at most 12 s and then the
  change fails with a message (nothing is changed), so nothing blocks for good; on Windows an `access denied` answer to the
  exclusive create (a virus scanner, a file being deleted) counts as busy until that time, and the message names the code, while a
  folder that is really not writable fails at once. The editor's UI thread waits 0.3 s at most (`ShareEnv::lockWaitSec` of a
  copy, `ShareWaitCap` for a command it runs on its own thread) and tells the person; the tick of the editor retries after 10 s.
  `share_skip`, `share_drop`, `share_confirm` and `share_discard` return a `Result`: with the lock busy or the outbox unwritable
  they change nothing, and `skipped` is written into an entry only after its item is out of the outbox. `feedback.delete` and
  `feedback discard` take the entry out of the outbox first and keep it when that fails. The network request of a flush runs
  outside the lock: afterwards the flush reads the files again under the lock and applies only its own results, so a mode
  changed meanwhile is not undone. If the lock cannot be taken after the request (it is retried with five times the wait), the
  finished items are remembered in memory for the life of the process (there is no sent-log file): the next flush takes them out
  of the outbox without sending them again, and the result says so; another process would still send them. Paths in `share_status` and the outbox's `file` are UTF-8 (an outbox
  an older version wrote on Windows in the system code page is read as it is).
- **Commands** (registered with the other feedback commands; none changes the mode):
  - `feedback.report` gains `share` and `reviewed`. With mode `always` the entry is sanitized and queued at once and the
    queue is flushed in the background; with `ask` it is queued as pending confirmation; with `unset` the result says
    that sharing is not set up and how the USER turns it on (editor, or `factoria feedback sharing always|ask|never`).
  - `feedback.share_preview {ids?}`: exactly what would be sent, with what the sanitizer removed.
  - `feedback.share_status`: effective mode (with `default` and `project{mode, source}`), endpoint, signed in or not, the
    outbox (pending, waiting for confirmation, blocked by a project's `never`, failed with reason).
  - `feedback.share {ids?}`: flush the outbox now (only entries the mode allows).
- **CLI** (typed by a person): `factoria feedback sharing [always|ask|never|default] [--project <path>] [--clear]` (no argument
  prints the status), `factoria feedback share [--preview]`, `factoria feedback signin github`, `factoria feedback signout`.
- **GitHub sign-in** (optional, identity only): OAuth device flow with the public client id compiled in
  (`FA_FEEDBACK_GITHUB_CLIENT_ID`). The client gets a GitHub token, sends it once to `POST /v1/auth/github`, stores the
  returned credential and discards the GitHub token. No GitHub scope is requested (only the public profile).
- **Fixed list**: `feedback/fixed.json` (format below) is embedded in the binary. When the editor opens a project and on
  `feedback.check_fixed`, every open local entry that matches a fix (same category, or the same family, and
  `feedback_entry_similarity` of its `title`/`share.title` with one of the fix's titles at or above 0.7) becomes
  `fixed-in-engine` with `engineIssue` "FactorIA <fixedIn>" and a note "fixed in FactorIA <fixedIn>: check whether the
  workaround can go". It is archived as usual; reporting it again reopens it as a possible regression.

## Server (tools/feedback-server, Cloudflare Worker + D1)

Plain JavaScript modules, no build step; storage behind a small interface so tests run with `node --test` on an
in-memory store. All responses are JSON: `{ok: true, ...}` or `{ok: false, error: {code, message, hint}}`.

Secrets (wrangler secrets): `ADMIN_TOKEN` (the developer's), `HMAC_SECRET`. Neither is ever in the repository.

### Keys the server derives

- `installKey = base64url(HMAC(HMAC_SECRET, "install:" + installId))[0..16]`: the raw installation id is never stored.
- `reporterKey = base64url(HMAC(HMAC_SECRET, "github:" + githubUserId))[0..16]`: no GitHub login or id is stored.
- `ipKey = HMAC(HMAC_SECRET, day + ":" + ip)`: used only for rate-limit counters that expire after a day; never stored
  with a report.

### `POST /v1/reports`

Headers: `X-Factoria-Install: <uuid v4>` (required), `Authorization: Bearer <credential>` (optional).

```json
{
  "format": "factoria.feedback-share/1",
  "engineVersion": "0.11.0",
  "platform": "macos",
  "entries": [
    {"localId": "FB-0003", "category": "physics", "severity": "major", "effort": "small",
     "title": "No fluid simulation",
     "missing": "There is no liquid solver, so water cannot flow around bodies and fill a container.",
     "suggestion": "Add a particle-based Fluid2D component.",
     "workaround": "A script disables the collider while the body moves up.",
     "reporterKind": "ai", "reviewed": true}
  ]
}
```

- At most 20 entries per request and 64 KB of body; `platform` one of `macos`, `windows`, `linux`, `web`, `other`.
- Each entry is checked on its own: enums, field limits, at least 60% letters (whitespace excluded) in every text field,
  no character repeated more than 8 times, at least 4 words in `missing`, no URL or e-mail address.
- The same installation reporting the same category and a similar title (normalized: lower case, punctuation and
  filler words dropped) again is merged: the stored report's `occurrences` goes up.
- Rate limits (counted per accepted or rejected entry): 30 entries per installation per day, 100 per `ipKey` per day,
  20 000 for the whole server per day; over a limit the answer is 429 with `Retry-After` and code `rate_limited`.
- A banned installation or reporter gets 403 with code `banned` and no detail; nothing it sends is stored.

Answer:

```json
{"ok": true, "results": [{"localId": "FB-0003", "status": "accepted", "shareId": "r_8f3k2m"},
                         {"localId": "FB-0004", "status": "rejected", "code": "too_short", "reason": "missing needs at least 20 characters"}]}
```

`status` is `accepted`, `merged` or `rejected`; rejection codes: `invalid_field`, `too_short`, `too_long`,
`not_text`, `personal_data`.

### `POST /v1/auth/github`

Body `{githubToken}`. The server calls `GET https://api.github.com/user` with it, takes the numeric `id`, computes the
`reporterKey`, and answers `{ok, credential, login}`. `credential` is `base64url(json{v:1, r:reporterKey, iat}) + "." +
base64url(HMAC(HMAC_SECRET, payload))`; the server checks it on every report. The GitHub token is not stored.

### Admin (`Authorization: Bearer <ADMIN_TOKEN>`)

- `GET /v1/admin/reports?since=<cursor>&limit=500`: `{ok, reports: [{shareId, installKey, reporterKey | null, trust,
  receivedAt, occurrences, engineVersion, platform, category, severity, effort, title, missing, suggestion, workaround,
  reporterKind, reviewed}], next}`. `next` is an opaque cursor; the same cursor returns the same page.
- `POST /v1/admin/ban {installKey? | reporterKey?, reason, purge?}`: refuse that key from now on; `purge` deletes its
  stored reports.
- `POST /v1/admin/unban {installKey? | reporterKey?}`, `GET /v1/admin/bans`.
- `DELETE /v1/admin/reports/<shareId>`.
- `GET /v1/admin/stats`: counts of reports, installations, rejections and rate-limit hits of the last days.
- `POST /v1/admin/reject {rejections: [{shareId, reason}]}` (reason: plain text, 1 to 500 characters, whitespace collapsed) and `POST
  /v1/admin/unreject {shareIds}`: the verdict of the engine developers on a stored report (migration `0002_verdicts.sql`: `verdict`,
  `verdict_reason`, `verdict_at` on `reports`). Answer `{ok, rejected | restored: [shareId], notFound: [shareId]}`. The report stays
  stored; `GET /v1/admin/reports` carries `verdict` and `verdictReason` for the ones that have one.

### `POST /v1/verdicts`

An installation asks what was decided about ITS reports. Header `X-Factoria-Install` as for reports; body `{format, shareIds: [..<=100]}`.
Answer `{ok, verdicts: [{shareId, status: "rejected" | "received", reason?, at?}]}`: one item per shareId that is a report of the
installation that sent the header. A shareId of another installation, or one that does not exist, gets NO item (the two cases look the same, so
nothing about other installations leaks). `rejected` carries the reason; `received` says the report is stored with no verdict. Capped at 240
requests per installation per day (`429` with `Retry-After`; the editor asks about every 30 minutes). An older server answers 404: the
client treats it as "no verdicts here" and changes nothing; an older client never calls it. The client (`share_sync_verdicts`) turns `rejected` into `shared.status: "declined"` plus the entry status
`rejected` (`statusBy: "developer"`, `statusReason` = the reason as sanitized plain text of at most 500 characters), and a `received` for a
declined entry (the rejection was taken back) into `sent` and open again. Do not confuse `shared.status: "rejected"` (the server refused the
text of a report when it was sent) with `declined` (the engine developers rejected a report that was accepted).

### `GET /`

A short plain page: what the server stores, what it never stores, how long it keeps reports (until the developer
deletes them), that texts may be summarized in the public roadmap, the rules for reports (engine topics only, no
personal data, no illegal or abusive content, no abuse of the server; reports that break them are deleted and their
sender may be refused, without notice; sending a report lets the developer use it freely), that the server comes with
no warranty and may stop at any time, and how to stop sending (`never`).

### Deploy

`tools/feedback-server/deploy.sh` (and `deploy.ps1`): one command that logs in to Cloudflare (`wrangler login`, which
opens the browser), creates the D1 database if missing, applies the schema, generates and sets `ADMIN_TOKEN` and
`HMAC_SECRET` when they are not set yet, deploys, and writes the URL and the admin token to the developer's
`feedback-admin.json` (next to the user `ai.json`, never in the repository). It prints the URL to put in
`FA_FEEDBACK_URL`.

## Developer side (CLI)

Reads `feedback-admin.json` (`{endpoint, adminToken}`).

- `factoria feedback pull [--out DIR] [--classify | --no-classify]`: downloads new reports since the last cursor (kept in
  `feedback-admin.json`) into an inbox outside the repository (default `~/.factoria/feedback-inbox/`), one
  `ENGINE_FEEDBACK.json` per installation in `<inbox>/<installKey>/`, project name `install-<installKey>`, entries with
  `remote` and `workaround` "(not shared)" when the report had none. Never written inside a git checkout unless `--out`
  says so.
- **Classification** (default on when an AI role is configured): each new report is judged `valid`, `doubtful` or
  `junk` by a cheap model through the user's AI configuration (fa_ai), with the reason. Junk goes to
  `<inbox>/quarantine/` instead, doubtful entries carry a note. `factoria feedback quarantine [list|restore <shareId>|
  clear]`.
- `factoria feedback ban <installKey|reporterKey> [--purge] [--reason TEXT]`, `unban`, `bans`, `delete <shareId>`,
  `stats`.
- **Ranking**: `feedback collect` scores a group as the sum, over its projects (installations), of
  `severity weight x trust x min(occurrences, 3)`, with trust 1 for a local project and a verified installation and 0.5
  for an anonymous one. The report shows installations, verified installations and occurrences.
- `factoria feedback fixed add --category C --title T [--title T2] --version V [--note N]` and `feedback fixed list`:
  maintain `feedback/fixed.json`; `feedback update ... --status fixed-in-engine` on an inbox entry offers the same.

### `feedback/fixed.json`

```json
{"format": "factoria.feedback-fixed/1",
 "fixes": [{"category": "physics", "titles": ["No fluid simulation"], "fixedIn": "0.11.0",
            "note": "Fluid2D"}]}
```

## Editor

- First time a shareable entry appears (or from Settings > Feedback): a dialog that explains what is sent and what is
  not, shows the preview of the real entry, and offers Always / Ask each time / Never. Settings > Feedback shows the
  mode, the outbox and "Sign in with GitHub" (device code shown, browser opened).
- With `ask`: a notification "N feedback entries ready to send" opens the preview with Send / Don't send per entry.
- Engine Feedback panel: a column with the share state of each entry, a "New entry" form for people, and "Review with
  AI" (the user's configured AI checks the docs to see whether the gap is real, that it is about the engine, and writes
  `share` in engine terms; `reviewed: true`). Without an AI the entry goes as `reviewed: false`.
- `ai.review_feedback {id}` is the command behind that button.

## Packages

- M46.1 (L) Server: tools/feedback-server (Worker, D1 schema, in-memory store for tests, `node --test` suite added to
  ctest when Node is found), deploy scripts, privacy page, README.
- M46.2 (L) Client: schema fields, sanitizer, user settings and outbox, sending through fa/platform's HTTP client with an
  injectable transport for tests, the commands and CLI above, GitHub device flow, the embedded fixed list and
  `feedback.check_fixed`, docs/ENGINE_FEEDBACK.md "Sharing".
- M46.3 (L, after M46.2) Editor and AI: consent dialog, settings, ask-mode confirmation, panel column, new-entry form,
  `ai.review_feedback`; AI_GUIDE.md section 3, templates/common/AGENTS.md (write `share` in engine terms, check the docs
  first, a good and a bad example).
- M46.4 (L) Developer side: `feedback pull` with classification and quarantine, ban/unban/delete/stats, the new
  ranking in `collect`, `feedback fixed`, docs/EXTENDING.md section F.
