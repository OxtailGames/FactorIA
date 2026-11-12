import { test } from "node:test";
import assert from "node:assert/strict";
import { ADMIN_TOKEN, HMAC_SECRET, INSTALL, admin, body, entry, makeServer, post, pullAll, sendReports, uuid } from "./helpers.js";

const batch = (from, n) => Array.from({ length: n }, (_, i) => entry(from + i));

test("30 entries per installation per day, then 429 with Retry-After", async () => {
    const { app } = makeServer();
    assert.equal((await sendReports(app, batch(0, 20))).status, 200);
    assert.equal((await sendReports(app, batch(20, 10))).status, 200);
    const res = await sendReports(app, batch(30, 1));
    assert.equal(res.status, 429);
    const j = await res.json();
    assert.equal(j.ok, false);
    assert.equal(j.error.code, "rate_limited");
    assert.match(j.error.message, /30 entries/);
    assert.ok(j.error.hint);
    // 12:00 UTC: 12 hours to midnight.
    assert.equal(res.headers.get("retry-after"), String(12 * 3600));
    assert.equal((await pullAll(app)).length, 30);
});

test("a request that would go over is refused whole, and the hint says how many fit", async () => {
    const { app } = makeServer({ limits: { install: 5 } });
    assert.equal((await sendReports(app, batch(0, 3))).status, 200);
    const res = await sendReports(app, batch(10, 3));
    assert.equal(res.status, 429);
    const j = await res.json();
    assert.match(j.error.message, /2 left/);
    assert.match(j.error.hint, /at most 2/);
    assert.equal((await pullAll(app)).length, 3);
    // The refused request counted nothing: 2 more still fit.
    assert.equal((await sendReports(app, batch(20, 2))).status, 200);
    assert.equal((await sendReports(app, batch(30, 1))).status, 429);
});

test("rejected entries count against the limit as well", async () => {
    const { app } = makeServer({ limits: { install: 4 } });
    const bad = Array.from({ length: 4 }, (_, i) => entry(i, { title: "x" }));
    const j = await (await sendReports(app, bad)).json();
    assert.ok(j.results.every((r) => r.status === "rejected"));
    assert.equal((await sendReports(app, batch(10, 1))).status, 429);
});

test("merged entries count against the limit too", async () => {
    const { app } = makeServer({ limits: { install: 3 } });
    const same = [entry(1), entry(1), entry(1)];
    assert.equal((await sendReports(app, same)).status, 200);
    assert.equal((await sendReports(app, [entry(1)])).status, 429);
});

test("another installation is not affected by the limit of this one", async () => {
    const { app } = makeServer({ limits: { install: 2 } });
    assert.equal((await sendReports(app, batch(0, 2))).status, 200);
    assert.equal((await sendReports(app, batch(5, 1))).status, 429);
    assert.equal((await sendReports(app, batch(5, 1), { install: uuid() })).status, 200);
});

test("limit per network (CF-Connecting-IP), shared by installations", async () => {
    const { app } = makeServer({ limits: { ip: 3 } });
    const ip = { "cf-connecting-ip": "203.0.113.7" };
    assert.equal((await sendReports(app, batch(0, 2), { install: uuid(), headers: ip })).status, 200);
    assert.equal((await sendReports(app, batch(5, 1), { install: uuid(), headers: ip })).status, 200);
    const res = await sendReports(app, batch(8, 1), { install: uuid(), headers: ip });
    assert.equal(res.status, 429);
    assert.equal((await res.json()).error.code, "rate_limited");
    assert.ok(res.headers.get("retry-after"));
    // Another address is fine.
    assert.equal((await sendReports(app, batch(8, 1), { install: uuid(), headers: { "cf-connecting-ip": "203.0.113.8" } })).status, 200);
});

test("global limit for the whole server", async () => {
    const { app } = makeServer({ limits: { global: 3 } });
    assert.equal((await sendReports(app, batch(0, 2), { install: uuid(), headers: { "cf-connecting-ip": "198.51.100.1" } })).status, 200);
    assert.equal((await sendReports(app, batch(5, 1), { install: uuid(), headers: { "cf-connecting-ip": "198.51.100.2" } })).status, 200);
    const res = await sendReports(app, batch(8, 1), { install: uuid(), headers: { "cf-connecting-ip": "198.51.100.3" } });
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /server/);
});

test("limits reset at midnight UTC", async () => {
    const { app, clock } = makeServer({ limits: { install: 2, ip: 2, global: 2 } });
    assert.equal((await sendReports(app, batch(0, 2))).status, 200);
    assert.equal((await sendReports(app, batch(5, 1))).status, 429);
    clock.now = Date.UTC(2026, 5, 10, 23, 59, 59);
    assert.equal((await sendReports(app, batch(5, 1))).status, 429);
    clock.now = Date.UTC(2026, 5, 11, 0, 0, 0);
    assert.equal((await sendReports(app, batch(5, 2))).status, 200);
});

test("expired counters are deleted by the next write", async () => {
    const { app, store, clock } = makeServer();
    await sendReports(app, batch(0, 1));
    assert.ok([...store.counters.keys()].some((k) => k.startsWith("inst:2026-06-10:")));
    clock.now += 2 * 24 * 3600 * 1000;
    await sendReports(app, batch(5, 1));
    assert.ok(![...store.counters.keys()].some((k) => k.startsWith("inst:2026-06-10:")));
    assert.ok(![...store.counters.keys()].some((k) => k.startsWith("global:2026-06-10")));
});

test("the network counter holds a keyed hash, never the address", async () => {
    const { app, store } = makeServer();
    await sendReports(app, batch(0, 1), { headers: { "cf-connecting-ip": "203.0.113.99" } });
    const dump = JSON.stringify([...store.counters.keys()]) + JSON.stringify([...store.reports.values()]);
    assert.ok(!dump.includes("203.0.113.99"));
    const ipKeys = [...store.counters.keys()].filter((k) => k.startsWith("ip:"));
    assert.equal(ipKeys.length, 1);
    assert.ok(ipKeys[0].length > 30);
    assert.equal(store.counters.get(ipKeys[0]).expiresAt, Date.UTC(2026, 5, 11));
});

test("rate-limit hits and rejections show up in the stats", async () => {
    const { app } = makeServer({ limits: { install: 2 } });
    await sendReports(app, [entry(1), entry(2, { title: "x" })]);
    await sendReports(app, batch(5, 1));
    const stats = await (await admin(app, "GET", "/v1/admin/stats")).json();
    const today = stats.days[0];
    assert.equal(today.day, "2026-06-10");
    assert.equal(today.accepted, 1);
    assert.equal(today.rejected, 1);
    assert.equal(today.rateLimited, 1);
    assert.deepEqual(today.rejections, { too_short: 1 });
    assert.deepEqual(stats.totals, { reports: 1, installations: 1, occurrences: 1, bans: 0 });
    assert.equal(stats.days.length, 7);
});

// ---- network header and per-route caps (M92.3d) -------------------------------------------------------------------

const rawPost = (app, path, payload, headers) => app.fetch(new Request("https://fb.example" + path, { method: "POST", body: JSON.stringify(payload), headers: { "content-type": "application/json", ...headers } }));

test("a write request without cf-connecting-ip is refused with missing_client_ip, nothing stored", async () => {
    const { app, store, github } = makeServer({ users: { good: { id: 1, login: "a" } } });
    const routes = [
        ["/v1/reports", body([entry(1)])],
        ["/v1/verdicts", { shareIds: ["r_abcd"] }],
        ["/v1/auth/github", { githubToken: "good" }],
    ];
    for (const [path, payload] of routes) {
        const res = await rawPost(app, path, payload, { "x-factoria-install": INSTALL });
        assert.equal(res.status, 400, path);
        const j = await res.json();
        assert.equal(j.error.code, "missing_client_ip", path);
        assert.match(j.error.hint, /Cloudflare/);
        assert.match(j.error.hint, /ALLOW_NO_CLIENT_IP/);
    }
    assert.equal(store.counters.size, 0);
    assert.equal(store.reports.size, 0);
    assert.equal(github.calls.length, 0);
});

test("ALLOW_NO_CLIENT_IP lets it through into one strict bucket apart from real networks", async () => {
    const env = { ADMIN_TOKEN, HMAC_SECRET, ALLOW_NO_CLIENT_IP: "1" };
    const { app } = makeServer({ env, limits: { noIp: 3, ip: 100 } });
    const send = (install, n, from) => rawPost(app, "/v1/reports", body(batch(from, n)), { "x-factoria-install": install });
    assert.equal((await send(uuid(), 2, 0)).status, 200);
    assert.equal((await send(uuid(), 1, 5)).status, 200);
    const res = await send(uuid(), 1, 8);
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /3 entries.*network/);
    // A real address has its own bucket.
    assert.equal((await sendReports(app, batch(10, 1), { install: uuid() })).status, 200);
    // The setting is off for "0" and "false".
    for (const off of ["0", "false"]) {
        const s = makeServer({ env: { ADMIN_TOKEN, HMAC_SECRET, ALLOW_NO_CLIENT_IP: off } });
        assert.equal((await rawPost(s.app, "/v1/reports", body([entry(1)]), { "x-factoria-install": INSTALL })).status, 400);
    }
});

test("the strict bucket also limits verdicts and sign-ins", async () => {
    const env = { ADMIN_TOKEN, HMAC_SECRET, ALLOW_NO_CLIENT_IP: "1" };
    const { app } = makeServer({ env, users: { good: { id: 1, login: "a" } }, limits: { noIp: 2 } });
    for (let i = 0; i < 2; i++) assert.equal((await rawPost(app, "/v1/verdicts", { shareIds: ["r_abcd"] }, { "x-factoria-install": uuid() })).status, 200);
    assert.equal((await rawPost(app, "/v1/verdicts", { shareIds: ["r_abcd"] }, { "x-factoria-install": uuid() })).status, 429);
    for (let i = 0; i < 2; i++) assert.equal((await rawPost(app, "/v1/auth/github", { githubToken: "good" }, {})).status, 200);
    assert.equal((await rawPost(app, "/v1/auth/github", { githubToken: "good" }, {})).status, 429);
});

test("reports: fresh installation ids from one address still hit the network cap", async () => {
    const { app } = makeServer({ limits: { ip: 4, install: 100 } });
    for (let i = 0; i < 4; i++) assert.equal((await sendReports(app, batch(i * 10, 1), { install: uuid() })).status, 200);
    const res = await sendReports(app, batch(90, 1), { install: uuid() });
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /network/);
});

test("verdicts: per installation, per network (fresh ids included) and global caps", async () => {
    const ask = (app, install, ip) => post(app, "/v1/verdicts", { shareIds: ["r_abcd"] }, { "x-factoria-install": install, "cf-connecting-ip": ip });
    let s = makeServer({ limits: { verdicts: 2 } });
    assert.equal((await ask(s.app, INSTALL, "198.51.100.1")).status, 200);
    assert.equal((await ask(s.app, INSTALL, "198.51.100.1")).status, 200);
    let res = await ask(s.app, INSTALL, "198.51.100.1");
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /installation/);

    s = makeServer({ limits: { verdictsIp: 2 } });
    assert.equal((await ask(s.app, uuid(), "198.51.100.1")).status, 200);
    assert.equal((await ask(s.app, uuid(), "198.51.100.1")).status, 200);
    res = await ask(s.app, uuid(), "198.51.100.1");
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /network/);
    assert.equal((await ask(s.app, uuid(), "198.51.100.2")).status, 200);

    s = makeServer({ limits: { verdictsGlobal: 2 } });
    assert.equal((await ask(s.app, uuid(), "198.51.100.1")).status, 200);
    assert.equal((await ask(s.app, uuid(), "198.51.100.2")).status, 200);
    res = await ask(s.app, uuid(), "198.51.100.3");
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /server/);
});

test("sign-ins: global cap across networks", async () => {
    const users = { good: { id: 1, login: "a" } };
    const { app } = makeServer({ users, limits: { authGlobal: 2 } });
    const signIn = (ip) => post(app, "/v1/auth/github", { githubToken: "good" }, { "cf-connecting-ip": ip });
    assert.equal((await signIn("198.51.100.1")).status, 200);
    assert.equal((await signIn("198.51.100.2")).status, 200);
    const res = await signIn("198.51.100.3");
    assert.equal(res.status, 429);
    assert.match((await res.json()).error.message, /server/);
});

test("admin routes need the token and are not counted against the write caps", async () => {
    const { app, store } = makeServer();
    const res = await app.fetch(new Request("https://fb.example/v1/admin/stats"));
    assert.equal(res.status, 401);
    assert.equal((await admin(app, "GET", "/v1/admin/stats")).status, 200);
    assert.equal(store.counters.size, 0);
});
