// The request handler of the feedback server: every endpoint of docs/design/FEEDBACK_SHARING.md ("Server").
//
//   const app = createApp({store, env: {ADMIN_TOKEN, HMAC_SECRET}, fetch?, now?, randomId?, limits?});
//   const response = await app.fetch(request);
//
// `fetch` is what reaches api.github.com (injected by the tests, globalThis.fetch in production); `now` is the clock in
// epoch milliseconds; `limits` overrides the daily rate limits.

import { PRIVACY_HTML } from "./privacy.js";
import * as keys from "./keys.js";
import { normalizeTitle, PLATFORMS, similarTitles, validateEntry } from "./validate.js";
import { ApiError, base64url, base64urlDecode, errorResponse, json, nextMidnight, safeEqual, utcDay, utf8, utf8Decode } from "./util.js";

export const FORMAT = "factoria.feedback-share/1";
export const MAX_ENTRIES = 20;
export const MAX_BODY_BYTES = 64 * 1024;
export const DEFAULT_LIMITS = { install: 30, ip: 100, global: 20000, auth: 20 };
const MERGE_WINDOW = 500;
const STATS_DAYS = 7;
const STATS_TTL_MS = 35 * 24 * 3600 * 1000;
const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const VERSION = /^[0-9A-Za-z][0-9A-Za-z.+_-]{0,31}$/;
const SHARE_ID = /^r_[a-z0-9]{4,16}$/;
const ID_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz";

function defaultRandomId() {
    const bytes = crypto.getRandomValues(new Uint8Array(8));
    let id = "r_";
    for (const b of bytes) id += ID_ALPHABET[b % ID_ALPHABET.length];
    return id;
}

async function readBody(request, maxBytes) {
    const declared = Number(request.headers.get("content-length"));
    if (Number.isFinite(declared) && declared > maxBytes) throw tooLarge(maxBytes);
    const text = await request.text();
    if (utf8(text).length > maxBytes) throw tooLarge(maxBytes);
    return text;
}

function tooLarge(maxBytes) {
    return new ApiError(413, "too_large", `The request body is over ${maxBytes / 1024} KB.`, `Send at most ${MAX_ENTRIES} entries and ${MAX_BODY_BYTES / 1024} KB per request; split a bigger batch.`);
}

function parseJson(text, what) {
    let value;
    try {
        value = JSON.parse(text);
    } catch (e) {
        throw new ApiError(400, "invalid_json", `The body of ${what} is not valid JSON (${e.message}).`, "Send a JSON object with Content-Type application/json.");
    }
    if (!value || typeof value !== "object" || Array.isArray(value)) {
        throw new ApiError(400, "invalid_request", `The body of ${what} must be a JSON object.`, "Wrap the fields in {...}.");
    }
    return value;
}

function bearer(request) {
    const header = request.headers.get("authorization");
    if (header === null) return null;
    const m = /^Bearer\s+(\S+)\s*$/i.exec(header);
    return m ? m[1] : "";
}

export function createApp({ store, env, fetch: fetchImpl, now, randomId, limits } = {}) {
    const clock = now || (() => Date.now());
    const newId = randomId || defaultRandomId;
    const github = fetchImpl || ((...args) => globalThis.fetch(...args));
    const caps = { ...DEFAULT_LIMITS, ...(limits || {}) };

    function secret() {
        if (!env || !env.HMAC_SECRET) {
            throw new ApiError(503, "not_configured", "The server has no HMAC_SECRET.", "The server owner must run tools/feedback-server/deploy.sh (or deploy.ps1), which sets it.");
        }
        return env.HMAC_SECRET;
    }

    function retryAfter(ms) {
        return Math.max(1, Math.ceil((nextMidnight(ms) - ms) / 1000));
    }

    function stat(day, name, by, ms) {
        return { key: `stat:${day}:${name}`, by, expiresAt: ms + STATS_TTL_MS };
    }

    async function ipCounterKey(ms, request) {
        const ip = request.headers.get("cf-connecting-ip") || "unknown";
        return "ip:" + (await keys.ipKey(secret(), utcDay(ms), ip));
    }

    // ---- POST /v1/reports ------------------------------------------------------------------------------------

    async function postReports(request) {
        const s = secret();
        const ms = clock();
        const day = utcDay(ms);
        const installId = request.headers.get("x-factoria-install");
        if (!installId || !UUID_V4.test(installId)) {
            throw new ApiError(400, "missing_install", installId ? "X-Factoria-Install is not a UUID v4." : "The X-Factoria-Install header is missing.", "Send the installation id (a random UUID v4) in X-Factoria-Install; the engine creates it on the first send.");
        }
        const install = await keys.installKey(s, installId.toLowerCase());

        let reporter = null;
        const token = bearer(request);
        if (token !== null) {
            reporter = token ? await keys.checkCredential(s, token) : null;
            if (!reporter) {
                throw new ApiError(401, "invalid_credential", "The credential in Authorization is not valid.", "Sign in with GitHub again (factoria feedback signin github), or send the report without the Authorization header.");
            }
        }

        const toCheck = [{ kind: "install", key: install }];
        if (reporter) toCheck.push({ kind: "reporter", key: reporter });
        if ((await store.getBans(toCheck)).length > 0) {
            await store.commit({ counters: [stat(day, "banned", 1, ms)], now: ms });
            throw new ApiError(403, "banned", "This installation is not accepted.", "Sending feedback from it is switched off.");
        }

        const body = parseJson(await readBody(request, MAX_BODY_BYTES), "POST /v1/reports");
        if (body.format !== FORMAT) {
            throw new ApiError(400, "invalid_format", `format must be "${FORMAT}".`, `Set "format": "${FORMAT}" in the body.`);
        }
        if (!Array.isArray(body.entries) || body.entries.length === 0) {
            throw new ApiError(400, "invalid_request", "entries must be a non-empty array.", `Send 1 to ${MAX_ENTRIES} entries.`);
        }
        if (body.entries.length > MAX_ENTRIES) {
            throw new ApiError(400, "too_many_entries", `A request has at most ${MAX_ENTRIES} entries; this one has ${body.entries.length}.`, `Split the entries into requests of ${MAX_ENTRIES} or fewer.`);
        }
        if (!PLATFORMS.includes(body.platform)) {
            throw new ApiError(400, "invalid_request", `platform must be one of: ${PLATFORMS.join(", ")}.`, 'Use "other" when none fits.');
        }
        let engineVersion = null;
        if (body.engineVersion !== undefined && body.engineVersion !== null) {
            if (typeof body.engineVersion !== "string" || !VERSION.test(body.engineVersion)) {
                throw new ApiError(400, "invalid_request", "engineVersion must be a version string such as 0.11.0.", "Send the engine's version or leave engineVersion out.");
            }
            engineVersion = body.engineVersion;
        }

        // Rate limits: counted per entry, accepted or rejected, and checked for the whole request before any is stored.
        const n = body.entries.length;
        const counterKeys = { install: `inst:${day}:${install}`, ip: await ipCounterKey(ms, request), global: `global:${day}` };
        const used = await store.getCounters(Object.values(counterKeys), ms);
        const dayEnd = nextMidnight(ms);
        for (const [scope, label] of [["install", "this installation"], ["ip", "this network"], ["global", "the server"]]) {
            const left = caps[scope] - used[counterKeys[scope]];
            if (n > left) {
                await store.commit({ counters: [stat(day, "ratelimited", 1, ms)], now: ms });
                throw new ApiError(
                    429,
                    "rate_limited",
                    `The daily limit of ${caps[scope]} entries for ${label} is reached${left > 0 ? ` (${left} left, this request has ${n})` : ""}.`,
                    left > 0 && scope !== "global"
                        ? `Send at most ${left} entries now, or wait until midnight UTC (Retry-After seconds).`
                        : "Wait until midnight UTC (Retry-After seconds); the engine retries by itself.",
                    { "retry-after": String(retryAfter(ms)) },
                );
            }
        }

        const known = (await store.listForMerge(install, MERGE_WINDOW)).map((r) => ({ ...r, pending: false }));
        const inserts = [];
        const bumps = new Map();
        const results = [];
        const tally = { accepted: 0, merged: 0, rejected: 0 };
        const codes = new Map();
        const receivedAt = new Date(ms).toISOString();

        for (const raw of body.entries) {
            const checked = validateEntry(raw);
            if (!checked.ok) {
                tally.rejected++;
                codes.set(checked.code, (codes.get(checked.code) || 0) + 1);
                results.push({ localId: typeof raw?.localId === "string" ? raw.localId.slice(0, 64) : null, status: "rejected", code: checked.code, reason: checked.reason, hint: checked.hint });
                continue;
            }
            const e = checked.entry;
            const norm = normalizeTitle(e.title);
            const same = known.find((k) => k.category === e.category && similarTitles(k.titleNorm, norm));
            if (same) {
                tally.merged++;
                if (same.pending) same.report.occurrences++;
                else bumps.set(same.shareId, (bumps.get(same.shareId) || 0) + 1);
                results.push({ localId: e.localId, status: "merged", shareId: same.shareId });
                continue;
            }
            const report = {
                shareId: newId(), installKey: install, reporterKey: reporter, receivedAt, occurrences: 1, engineVersion,
                platform: body.platform, category: e.category, severity: e.severity, effort: e.effort, title: e.title,
                titleNorm: norm, missing: e.missing, suggestion: e.suggestion, workaround: e.workaround,
                reporterKind: e.reporterKind, reviewed: e.reviewed,
            };
            inserts.push(report);
            known.unshift({ shareId: report.shareId, category: e.category, titleNorm: norm, pending: true, report });
            tally.accepted++;
            results.push({ localId: e.localId, status: "accepted", shareId: report.shareId });
        }

        const counters = [
            { key: counterKeys.install, by: n, expiresAt: dayEnd },
            { key: counterKeys.ip, by: n, expiresAt: dayEnd },
            { key: counterKeys.global, by: n, expiresAt: dayEnd },
        ];
        for (const name of ["accepted", "merged", "rejected"]) if (tally[name]) counters.push(stat(day, name, tally[name], ms));
        for (const [code, count] of codes) counters.push(stat(day, "code:" + code, count, ms));
        await store.commit({
            inserts,
            bumps: [...bumps].map(([shareId, by]) => ({ shareId, by })),
            counters,
            now: ms,
        });
        return json(200, { ok: true, results });
    }

    // ---- POST /v1/auth/github --------------------------------------------------------------------------------

    async function postAuthGithub(request) {
        const s = secret();
        const ms = clock();
        const body = parseJson(await readBody(request, 4096), "POST /v1/auth/github");
        const token = body.githubToken;
        if (typeof token !== "string" || token.length < 1 || token.length > 512 || /\s/.test(token)) {
            throw new ApiError(400, "invalid_request", "githubToken must be the GitHub access token as a string.", 'Send {"githubToken": "<token from the device flow>"}.');
        }
        // Not in the contract: the endpoint calls GitHub, so one network may not use the server as a proxy without limit.
        const ipCounter = (await ipCounterKey(ms, request)).replace(/^ip:/, "auth:");
        const used = (await store.getCounters([ipCounter], ms))[ipCounter];
        if (used >= caps.auth) {
            throw new ApiError(429, "rate_limited", `This network already signed in ${caps.auth} times today.`, "Try again after midnight UTC (Retry-After seconds).", { "retry-after": String(retryAfter(ms)) });
        }
        await store.commit({ counters: [{ key: ipCounter, by: 1, expiresAt: nextMidnight(ms) }], now: ms });

        let res;
        try {
            res = await github("https://api.github.com/user", {
                headers: { authorization: `Bearer ${token}`, accept: "application/vnd.github+json", "user-agent": "factoria-feedback-server", "x-github-api-version": "2022-11-28" },
            });
        } catch {
            throw new ApiError(502, "github_unavailable", "GitHub could not be reached.", "Try again in a few minutes.");
        }
        if (res.status === 401 || res.status === 403) {
            throw new ApiError(401, "invalid_github_token", "GitHub did not accept the token.", "Sign in again (factoria feedback signin github) to get a new token.");
        }
        if (!res.ok) {
            throw new ApiError(502, "github_unavailable", `GitHub answered ${res.status}.`, "Try again in a few minutes.");
        }
        let user;
        try {
            user = await res.json();
        } catch {
            user = null;
        }
        if (!user || !Number.isSafeInteger(user.id) || user.id <= 0) {
            throw new ApiError(502, "github_unavailable", "GitHub's answer has no account number.", "Try again in a few minutes.");
        }
        const reporter = await keys.reporterKey(s, String(user.id));
        const credential = await keys.makeCredential(s, reporter, Math.floor(ms / 1000));
        return json(200, { ok: true, credential, login: typeof user.login === "string" ? user.login : null });
    }

    // ---- admin ------------------------------------------------------------------------------------------------

    async function requireAdmin(request) {
        if (!env || !env.ADMIN_TOKEN) {
            throw new ApiError(503, "not_configured", "The server has no ADMIN_TOKEN.", "The server owner must run tools/feedback-server/deploy.sh (or deploy.ps1), which sets it.");
        }
        const token = bearer(request);
        if (token === null || !(await safeEqual(token, env.ADMIN_TOKEN))) {
            throw new ApiError(401, "unauthorized", "The admin token is missing or wrong.", "Send Authorization: Bearer <adminToken> (from feedback-admin.json).");
        }
    }

    function encodeCursor(seq) {
        return base64url(utf8("seq:" + seq));
    }

    function decodeCursor(cursor) {
        const bytes = base64urlDecode(cursor);
        const m = bytes ? /^seq:(\d{1,15})$/.exec(utf8Decode(bytes)) : null;
        if (!m) throw new ApiError(400, "invalid_cursor", "since is not a cursor this server gave.", "Pass the `next` value of a previous answer, or leave since out to start from the beginning.");
        return Number(m[1]);
    }

    async function adminReports(url) {
        const since = url.searchParams.get("since");
        const after = since ? decodeCursor(since) : 0;
        let limit = 500;
        if (url.searchParams.has("limit")) {
            limit = Number(url.searchParams.get("limit"));
            if (!Number.isInteger(limit) || limit < 1 || limit > 500) {
                throw new ApiError(400, "invalid_request", "limit must be an integer from 1 to 500.", "Use limit=500 or less.");
            }
        }
        const rows = await store.listReports(after, limit);
        const reports = rows.map((r) => ({
            shareId: r.shareId, installKey: r.installKey, reporterKey: r.reporterKey || null,
            trust: r.reporterKey ? "verified" : "anonymous", receivedAt: r.receivedAt, occurrences: r.occurrences,
            engineVersion: r.engineVersion, platform: r.platform, category: r.category, severity: r.severity,
            effort: r.effort, title: r.title, missing: r.missing, suggestion: r.suggestion, workaround: r.workaround,
            reporterKind: r.reporterKind, reviewed: r.reviewed,
        }));
        const next = rows.length > 0 ? encodeCursor(rows[rows.length - 1].seq) : since || null;
        return json(200, { ok: true, reports, next });
    }

    function banTarget(body) {
        const hasInstall = body.installKey !== undefined;
        const hasReporter = body.reporterKey !== undefined;
        if (hasInstall === hasReporter) {
            throw new ApiError(400, "invalid_request", "Give exactly one of installKey and reporterKey.", 'Send {"installKey": "<16 characters>"} or {"reporterKey": "<16 characters>"}.');
        }
        const kind = hasInstall ? "install" : "reporter";
        const key = hasInstall ? body.installKey : body.reporterKey;
        if (typeof key !== "string" || !keys.KEY_PATTERN.test(key)) {
            throw new ApiError(400, "invalid_request", `${kind}Key must be a 16-character key as shown by the admin reports.`, "Copy the key from `feedback pull` or from GET /v1/admin/reports.");
        }
        return { kind, key };
    }

    async function adminBan(request) {
        const body = parseJson(await readBody(request, 16 * 1024), "POST /v1/admin/ban");
        const { kind, key } = banTarget(body);
        if (typeof body.reason !== "string" || body.reason.trim() === "" || body.reason.length > 300) {
            throw new ApiError(400, "invalid_request", "reason must be a text of 1 to 300 characters.", "Say why, so a later unban can be judged.");
        }
        if (body.purge !== undefined && typeof body.purge !== "boolean") {
            throw new ApiError(400, "invalid_request", "purge must be true or false.", "Send purge: true to delete the stored reports of that key.");
        }
        await store.addBan({ kind, key, reason: body.reason.trim(), createdAt: new Date(clock()).toISOString() });
        const purged = body.purge ? await store.purge(kind === "install" ? { installKey: key } : { reporterKey: key }) : 0;
        return json(200, { ok: true, banned: { kind, key }, purged });
    }

    async function adminUnban(request) {
        const body = parseJson(await readBody(request, 16 * 1024), "POST /v1/admin/unban");
        const { kind, key } = banTarget(body);
        return json(200, { ok: true, removed: await store.removeBan(kind, key) });
    }

    async function adminStats() {
        const ms = clock();
        const totals = await store.totals();
        const bans = await store.listBans();
        const counters = await store.listCounters("stat:", ms);
        const days = [];
        for (let i = 0; i < STATS_DAYS; i++) {
            const day = utcDay(ms - i * 24 * 3600 * 1000);
            const entry = { day, accepted: 0, merged: 0, rejected: 0, rateLimited: 0, banned: 0, rejections: {} };
            for (const c of counters) {
                if (!c.key.startsWith(`stat:${day}:`)) continue;
                const name = c.key.slice(`stat:${day}:`.length);
                if (name === "ratelimited") entry.rateLimited = c.count;
                else if (name.startsWith("code:")) entry.rejections[name.slice(5)] = c.count;
                else if (name in entry) entry[name] = c.count;
            }
            days.push(entry);
        }
        return json(200, { ok: true, totals: { ...totals, bans: bans.length }, days });
    }

    // ---- routing ----------------------------------------------------------------------------------------------

    async function route(request) {
        const url = new URL(request.url);
        const path = url.pathname.length > 1 ? url.pathname.replace(/\/+$/, "") : url.pathname;
        const method = request.method;
        const allow = (...methods) => {
            if (!methods.includes(method)) {
                throw new ApiError(405, "method_not_allowed", `${path} does not accept ${method}.`, `Use ${methods.join(" or ")}.`, { allow: methods.join(", ") });
            }
        };

        if (path === "/") {
            allow("GET");
            return new Response(PRIVACY_HTML, { headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=3600" } });
        }
        if (path === "/v1/reports") {
            allow("POST");
            return postReports(request);
        }
        if (path === "/v1/auth/github") {
            allow("POST");
            return postAuthGithub(request);
        }
        if (path.startsWith("/v1/admin/")) {
            const rest = path.slice("/v1/admin/".length);
            const known = ["reports", "ban", "unban", "bans", "stats"];
            const m = /^reports\/([^/]+)$/.exec(rest);
            if (!known.includes(rest) && !m) {
                throw new ApiError(404, "not_found", `${path} is not an endpoint.`, "Admin endpoints: reports, ban, unban, bans, stats, reports/<shareId>.");
            }
            await requireAdmin(request);
            if (m) {
                allow("DELETE");
                let shareId = m[1];
                try {
                    shareId = decodeURIComponent(shareId);
                } catch {
                    // left as typed: the pattern check below rejects it
                }
                if (!SHARE_ID.test(shareId)) throw new ApiError(400, "invalid_request", "A shareId looks like r_8f3k2m.", "Copy it from `feedback pull` or GET /v1/admin/reports.");
                if (!(await store.deleteReport(shareId))) throw new ApiError(404, "not_found", `No report ${shareId}.`, "It may have been deleted or purged already.");
                return json(200, { ok: true, deleted: shareId });
            }
            if (rest === "reports") { allow("GET"); return adminReports(url); }
            if (rest === "ban") { allow("POST"); return adminBan(request); }
            if (rest === "unban") { allow("POST"); return adminUnban(request); }
            if (rest === "bans") { allow("GET"); return json(200, { ok: true, bans: await store.listBans() }); }
            allow("GET");
            return adminStats();
        }
        throw new ApiError(404, "not_found", `${path} is not an endpoint.`, "Endpoints: GET /, POST /v1/reports, POST /v1/auth/github, /v1/admin/*. See docs/design/FEEDBACK_SHARING.md.");
    }

    return {
        async fetch(request) {
            try {
                return await route(request);
            } catch (e) {
                if (e instanceof ApiError) return errorResponse(e);
                console.error("feedback server error:", e && e.stack ? e.stack : e);
                return errorResponse(new ApiError(500, "internal_error", "The server failed on this request.", "Try again later; if it persists, tell the engine developer."));
            }
        },
    };
}
