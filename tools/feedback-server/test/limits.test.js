import { test } from "node:test";
import assert from "node:assert/strict";
import { admin, entry, makeServer, pullAll, sendReports, uuid } from "./helpers.js";

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
