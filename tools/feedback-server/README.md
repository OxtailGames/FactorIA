# FactorIA feedback server

The server behind M46 (feedback sharing). The engine sends a generic copy of each `ENGINE_FEEDBACK.json` entry to it
when its user chose `always` or `ask`; the engine developer pulls them to decide what to build next. It is a
Cloudflare Worker with a D1 database, in plain JavaScript modules: no build step, no runtime npm dependency (`wrangler`
is a devDependency, locked in `package-lock.json`).

The contract is [docs/design/FEEDBACK_SHARING.md](../../docs/design/FEEDBACK_SHARING.md) (sections Principles, Data
model limits, Server, Deploy). This folder implements its "Server" section; read it for the exact request and answer
formats.

## Cost

Free. It runs on Cloudflare's free plan (Workers and D1) and needs no card, so it can never be billed: going over a
free limit makes Cloudflare refuse requests until midnight UTC. The server also limits itself well below the free
quotas: 30 entries per installation, 100 per network and 20 000 for the whole server per day.

## Deploy

You need Node.js 20 or newer and a free Cloudflare account (https://dash.cloudflare.com/sign-up).

```bash
tools/feedback-server/deploy.sh                 # macOS / Linux
powershell -NoProfile -ExecutionPolicy Bypass -File tools\feedback-server\deploy.ps1   # Windows
```

One command, safe to repeat. It installs wrangler from the lock file (`npm ci`), logs in to Cloudflare if needed
(`wrangler login` opens the browser), creates the D1 database `factoria-feedback` if missing (its id goes into
`wrangler.local.toml`, a copy of `wrangler.toml` that git ignores), applies `migrations/`, deploys, sets the secrets
`HMAC_SECRET` and `ADMIN_TOKEN` only when they are not set yet (random values, never printed), writes
`{endpoint, adminToken}` to `feedback-admin.json` next to the user `ai.json` (`~/.factoria/` on macOS and Linux,
`%APPDATA%\factoria\` on Windows; the pull cursor of `factoria feedback pull` lives in the same file and is kept) and
prints the URL. Build the engine with that URL as `FA_FEEDBACK_URL` (`cmake -DFA_FEEDBACK_URL=https://...`).

- `--rotate-admin` sets a new `ADMIN_TOKEN` (needed when the secret exists but `feedback-admin.json` was lost).
- Never rotate `HMAC_SECRET`: installation keys, reporter keys and sign-in credentials derive from it.
- Reports are stored until you delete them (`DELETE /v1/admin/reports/<shareId>`, or a ban with `purge`).

## Tests

```bash
cd tools/feedback-server && npm ci && npm test       # = node --test test
```

`npm ci` is only for `wrangler`; the tests need nothing but Node.js. They call the same `fetch` handler the Worker uses,
over an in-memory store and a fake GitHub, so they never touch the network. ctest runs them as `feedback_server` when it
finds Node.js 20 or newer, and leaves them out when it does not.

To try the real D1 store locally (no account needed): put `ADMIN_TOKEN=...` and `HMAC_SECRET=...` in `.dev.vars` (git
ignored), then `npx wrangler d1 migrations apply factoria-feedback --local` and `npx wrangler dev --local`.
`npx wrangler deploy --dry-run` checks `wrangler.toml` and the bundle.

## Layout

| File | What |
|---|---|
| `src/index.js` | Worker entry: binds D1 and the secrets to the handler |
| `src/app.js` | Every endpoint, rate limits, merge, bans, admin |
| `src/validate.js` | Entry validation, field limits, title normalization |
| `src/keys.js` | `installKey`, `reporterKey`, `ipKey`, credential format and check |
| `src/store_d1.js`, `src/store_memory.js` | The storage interface: D1 (production) and memory (tests) |
| `migrations/0001_init.sql` | Schema: reports (pull order `seq`), bans, expiring counters |
| `scripts/deploy.mjs` | The deploy steps behind `deploy.sh` / `deploy.ps1` |

## API summary

Every answer is JSON, `{ok: true, ...}` or `{ok: false, error: {code, message, hint}}`.

| Endpoint | What |
|---|---|
| `GET /` | Plain privacy page: what is stored, what never is, how to stop sending |
| `POST /v1/reports` | Up to 20 entries, 64 KB. Header `X-Factoria-Install` (UUID v4), optional `Authorization: Bearer <credential>`. Per entry: `accepted`, `merged` or `rejected` (`invalid_field`, `too_short`, `too_long`, `not_text`, `personal_data`). Errors: `400` (`missing_install`, `invalid_json`, `invalid_format`, `invalid_request`, `too_many_entries`), `401 invalid_credential`, `403 banned`, `413 too_large`, `429 rate_limited` + `Retry-After` |
| `POST /v1/auth/github` | `{githubToken}` -> `{credential, login}`; calls `api.github.com/user` once, stores nothing about the account. `401 invalid_github_token`, `502 github_unavailable`, `429` after 20 sign-ins per network per day |
| `GET /v1/admin/reports?since=&limit=` | Reports in arrival order and an opaque `next` cursor; a cursor always returns the same page |
| `POST /v1/admin/ban`, `POST /v1/admin/unban`, `GET /v1/admin/bans` | Refuse / allow an `installKey` or `reporterKey` (`purge` deletes its reports) |
| `DELETE /v1/admin/reports/<shareId>` | Delete one report |
| `GET /v1/admin/stats` | Totals and the last 7 days: accepted, merged, rejected (by code), rate-limit hits, banned |

Admin endpoints need `Authorization: Bearer <ADMIN_TOKEN>` (compared in constant time).

Behaviours worth knowing:

- A merged report only raises `occurrences`; its place in the pull order does not change, so a report already pulled is
  not sent again with the new count (a full pull from the start shows the current counts).
- A request that would take an installation, network or the server over its daily limit is refused whole with `429`;
  the hint says how many entries still fit.
- Counters are read, then written: two requests at the very same moment can overshoot a limit by a few entries.
