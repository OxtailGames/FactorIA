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
  `feedback-sharing.json`: `{mode: "unset" | "always" | "ask" | "never", installId (random UUID v4, created on the first
  send), credential? (from GitHub sign-in), login? (shown in the editor)}`. The installation id is not tied to any
  project.
- **Endpoint**: compiled in (`FA_FEEDBACK_URL`, CMake cache variable; empty = sharing unavailable, and every command
  says so with how to fix it). The user config may override it (`endpoint`) for tests and self-hosting.
- **Outbox**: `feedback-outbox.json` in the same folder, the sanitized payloads waiting to be sent, retried with backoff
  (1 min, 10 min, 1 h, then once a day). An entry is in the outbox once. An entry merged again after it was sent (its
  `occurrences` went up) is queued once more, up to 3 sends (`shared.occurrences` counts them): each send is one more
  occurrence on the server, and the ranking counts at most 3 per installation.
- **Commands** (registered with the other feedback commands; none changes the mode):
  - `feedback.report` gains `share` and `reviewed`. With mode `always` the entry is sanitized and queued at once and the
    queue is flushed in the background; with `ask` it is queued as pending confirmation; with `unset` the result says
    that sharing is not set up and how the USER turns it on (editor, or `factoria feedback sharing always|ask|never`).
  - `feedback.share_preview {ids?}`: exactly what would be sent, with what the sanitizer removed.
  - `feedback.share_status`: mode, endpoint, signed in or not, the outbox (pending, waiting for confirmation, failed with
    reason).
  - `feedback.share {ids?}`: flush the outbox now (only entries the mode allows).
- **CLI** (typed by a person): `factoria feedback sharing [always|ask|never]` (no argument prints the status),
  `factoria feedback share [--preview]`, `factoria feedback signin github`, `factoria feedback signout`.
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
     "title": "No one-way platforms",
     "missing": "Collider2D has no one-way option, so a body cannot pass up through a platform and land on it.",
     "suggestion": "Add Collider2D.oneWay (bool) with a direction.",
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

### `GET /`

A short plain page: what the server stores, what it never stores, how long it keeps reports (until the developer
deletes them), that texts may be summarized in the public roadmap, and how to stop sending (`never`).

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
 "fixes": [{"category": "physics", "titles": ["No one-way platforms"], "fixedIn": "0.11.0",
            "note": "Collider2D.oneWay"}]}
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
