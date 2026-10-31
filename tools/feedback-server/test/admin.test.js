import { test } from "node:test";
import assert from "node:assert/strict";
import {
    ADMIN_TOKEN, INSTALL, admin, entry, expectedInstallKey, expectedReporterKey, makeServer, pull, pullAll, sendReports, uuid,
} from "./helpers.js";

const seed = async (app, n, opts) => {
    for (let i = 0; i < n; i++) await sendReports(app, [entry(i + (opts?.from ?? 0))], opts);
};

test("admin endpoints need the admin token", async () => {
    const { app } = makeServer();
    const attempts = [
        new Request("https://fb.example/v1/admin/reports"),
        new Request("https://fb.example/v1/admin/reports", { headers: { authorization: "Bearer wrong" } }),
        new Request("https://fb.example/v1/admin/reports", { headers: { authorization: "Bearer " + ADMIN_TOKEN + "x" } }),
        new Request("https://fb.example/v1/admin/reports", { headers: { authorization: "Bearer " + ADMIN_TOKEN.slice(1) } }),
        new Request("https://fb.example/v1/admin/reports", { headers: { authorization: "Basic " + ADMIN_TOKEN } }),
        new Request("https://fb.example/v1/admin/reports", { headers: { authorization: "Bearer" } }),
        new Request("https://fb.example/v1/admin/stats"),
        new Request("https://fb.example/v1/admin/bans"),
        new Request("https://fb.example/v1/admin/ban", { method: "POST", body: "{}" }),
        new Request("https://fb.example/v1/admin/unban", { method: "POST", body: "{}" }),
        new Request("https://fb.example/v1/admin/reports/r_000001", { method: "DELETE" }),
    ];
    for (const req of attempts) {
        const res = await app.fetch(req);
        assert.equal(res.status, 401, req.url);
        const j = await res.json();
        assert.equal(j.error.code, "unauthorized");
        assert.ok(j.error.hint.includes("adminToken"));
    }
    assert.equal((await admin(app, "GET", "/v1/admin/stats")).status, 200);
});

test("the admin API does not work when ADMIN_TOKEN or HMAC_SECRET is not set", async () => {
    const noAdmin = makeServer({ env: { HMAC_SECRET: "s" } }).app;
    const res = await noAdmin.fetch(new Request("https://fb.example/v1/admin/stats", { headers: { authorization: "Bearer " } }));
    assert.equal(res.status, 503);
    assert.equal((await res.json()).error.code, "not_configured");
    const noSecret = makeServer({ env: { ADMIN_TOKEN } }).app;
    const r2 = await sendReports(noSecret, [entry(1)]);
    assert.equal(r2.status, 503);
});

test("unknown admin paths and methods", async () => {
    const { app } = makeServer();
    assert.equal((await admin(app, "GET", "/v1/admin/nothing")).status, 404);
    const res = await admin(app, "POST", "/v1/admin/reports");
    assert.equal(res.status, 405);
    assert.equal(res.headers.get("allow"), "GET");
    assert.equal((await admin(app, "GET", "/v1/admin/ban")).status, 405);
});

test("cursor paging: pages are contiguous, stable and complete", async () => {
    const { app } = makeServer({ limits: { install: 1000, ip: 1000, global: 1000 } });
    await seed(app, 10);

    const first = await pull(app, undefined, 4);
    assert.equal(first.reports.length, 4);
    assert.ok(typeof first.next === "string");
    // The same cursor returns the same page, also after more reports arrive.
    const second = await pull(app, first.next, 4);
    await seed(app, 3, { from: 100 });
    const again = await pull(app, first.next, 4);
    assert.deepEqual(again, second);
    assert.deepEqual(await pull(app, undefined, 4), first);

    // Paging to the end visits every report exactly once, in order of arrival.
    const ids = [];
    let cursor;
    for (;;) {
        const page = await pull(app, cursor, 3);
        if (page.reports.length === 0) break;
        ids.push(...page.reports.map((r) => r.shareId));
        cursor = page.next;
    }
    assert.equal(ids.length, 13);
    assert.equal(new Set(ids).size, 13);
    assert.deepEqual(ids, [...ids].sort());
    // An exhausted cursor stays put and new reports appear after it.
    const empty = await pull(app, cursor);
    assert.deepEqual(empty.reports, []);
    assert.equal(empty.next, cursor);
    await seed(app, 1, { from: 200 });
    assert.equal((await pull(app, cursor)).reports.length, 1);
});

test("deleting reports keeps cursors valid and never reuses their place", async () => {
    const { app } = makeServer();
    await seed(app, 5);
    const all = await pullAll(app);
    const page = await pull(app, undefined, 3);
    assert.equal((await (await admin(app, "DELETE", "/v1/admin/reports/" + all[1].shareId)).json()).deleted, all[1].shareId);
    assert.equal((await (await admin(app, "DELETE", "/v1/admin/reports/" + all[4].shareId)).json()).ok, true);
    await seed(app, 1, { from: 50 });
    const rest = await pull(app, page.next);
    assert.deepEqual(rest.reports.map((r) => r.shareId), [all[3].shareId, "r_000006"]);
});

test("invalid cursors and limits", async () => {
    const { app } = makeServer();
    for (const q of ["since=zzz", "since=" + Buffer.from("seq:-3").toString("base64url"), "since=" + Buffer.from("hello").toString("base64url")]) {
        const res = await admin(app, "GET", "/v1/admin/reports?" + q);
        assert.equal(res.status, 400, q);
        assert.equal((await res.json()).error.code, "invalid_cursor");
    }
    for (const q of ["limit=0", "limit=501", "limit=x", "limit=1.5"]) {
        const res = await admin(app, "GET", "/v1/admin/reports?" + q);
        assert.equal(res.status, 400, q);
        assert.equal((await res.json()).error.code, "invalid_request");
    }
});

test("DELETE /v1/admin/reports/<shareId>", async () => {
    const { app } = makeServer();
    await seed(app, 1);
    assert.equal((await admin(app, "DELETE", "/v1/admin/reports/nope")).status, 400);
    const missing = await admin(app, "DELETE", "/v1/admin/reports/r_zzzzzz");
    assert.equal(missing.status, 404);
    assert.equal((await missing.json()).error.code, "not_found");
    assert.equal((await admin(app, "DELETE", "/v1/admin/reports/r_000001")).status, 200);
    assert.equal((await admin(app, "DELETE", "/v1/admin/reports/r_000001")).status, 404);
    assert.equal((await pullAll(app)).length, 0);
});

test("ban an installation: 403 banned, nothing stored, no detail", async () => {
    const { app, store } = makeServer();
    await seed(app, 2);
    const key = expectedInstallKey(INSTALL);
    const ban = await (await admin(app, "POST", "/v1/admin/ban", { installKey: key, reason: "spam" })).json();
    assert.deepEqual(ban, { ok: true, banned: { kind: "install", key }, purged: 0 });
    assert.equal((await pullAll(app)).length, 2, "without purge the stored reports stay");

    const res = await sendReports(app, [entry(9)]);
    assert.equal(res.status, 403);
    const j = await res.json();
    assert.equal(j.error.code, "banned");
    assert.ok(!JSON.stringify(j).includes("spam"), "no detail about the ban");
    assert.ok(!JSON.stringify(j).includes(key));
    assert.equal((await pullAll(app)).length, 2);
    // Even an invalid body gets the same answer: the ban is checked first.
    assert.equal((await sendReports(app, "nope")).status, 403);
    assert.equal(store.reports.size, 2);

    // Other installations are fine.
    assert.equal((await sendReports(app, [entry(9)], { install: uuid() })).status, 200);

    const bans = await (await admin(app, "GET", "/v1/admin/bans")).json();
    assert.equal(bans.bans.length, 1);
    assert.equal(bans.bans[0].key, key);
    assert.equal(bans.bans[0].reason, "spam");

    const un = await (await admin(app, "POST", "/v1/admin/unban", { installKey: key })).json();
    assert.deepEqual(un, { ok: true, removed: true });
    assert.deepEqual(await (await admin(app, "POST", "/v1/admin/unban", { installKey: key })).json(), { ok: true, removed: false });
    assert.equal((await sendReports(app, [entry(10)])).status, 200);
    assert.deepEqual((await (await admin(app, "GET", "/v1/admin/bans")).json()).bans, []);
});

test("ban with purge deletes that installation's reports only", async () => {
    const { app } = makeServer();
    const other = uuid();
    await seed(app, 3);
    await seed(app, 2, { install: other, from: 20 });
    const j = await (await admin(app, "POST", "/v1/admin/ban", { installKey: expectedInstallKey(INSTALL), reason: "junk", purge: true })).json();
    assert.equal(j.purged, 3);
    const left = await pullAll(app);
    assert.equal(left.length, 2);
    assert.ok(left.every((r) => r.installKey === expectedInstallKey(other)));
});

test("ban a reporter: a valid credential of a banned GitHub account is refused, anonymous reports are not", async () => {
    const { app } = makeServer({ users: { tok: { id: 4242, login: "someone" } } });
    const auth = await (await app.fetch(new Request("https://fb.example/v1/auth/github", { method: "POST", body: JSON.stringify({ githubToken: "tok" }) }))).json();
    const withCred = { headers: { authorization: "Bearer " + auth.credential } };
    assert.equal((await sendReports(app, [entry(1)], withCred)).status, 200);
    const [r] = await pullAll(app);
    assert.equal(r.reporterKey, expectedReporterKey(4242));
    assert.equal(r.trust, "verified");

    const j = await (await admin(app, "POST", "/v1/admin/ban", { reporterKey: r.reporterKey, reason: "abuse", purge: true })).json();
    assert.deepEqual(j, { ok: true, banned: { kind: "reporter", key: r.reporterKey }, purged: 1 });
    assert.equal((await pullAll(app)).length, 0);
    const res = await sendReports(app, [entry(2)], { install: uuid(), ...withCred });
    assert.equal(res.status, 403);
    assert.equal((await res.json()).error.code, "banned");
    assert.equal((await sendReports(app, [entry(2)], { install: uuid() })).status, 200);
    assert.equal((await admin(app, "POST", "/v1/admin/unban", { reporterKey: r.reporterKey })).status, 200);
    assert.equal((await sendReports(app, [entry(3)], { install: uuid(), ...withCred })).status, 200);
});

test("ban and unban check their body", async () => {
    const { app } = makeServer();
    const key = expectedInstallKey(INSTALL);
    const bad = [
        {}, { installKey: key }, { installKey: key, reporterKey: key, reason: "x" }, { installKey: "short", reason: "x" },
        { installKey: key, reason: "x", purge: "yes" }, { installKey: key, reason: "  " }, { installKey: 5, reason: "x" },
    ];
    for (const b of bad) {
        const res = await admin(app, "POST", "/v1/admin/ban", b);
        assert.equal(res.status, 400, JSON.stringify(b));
        assert.equal((await res.json()).error.code, "invalid_request");
    }
    assert.equal((await admin(app, "POST", "/v1/admin/unban", {})).status, 400);
    const res = await app.fetch(new Request("https://fb.example/v1/admin/ban", { method: "POST", body: "{x", headers: { authorization: "Bearer " + ADMIN_TOKEN } }));
    assert.equal((await res.json()).error.code, "invalid_json");
});

test("stats count reports, installations, occurrences, bans and the days", async () => {
    const { app } = makeServer();
    await seed(app, 2);
    await sendReports(app, [entry(0)]); // merges
    await sendReports(app, [entry(7)], { install: uuid() });
    await admin(app, "POST", "/v1/admin/ban", { installKey: "AAAAAAAAAAAAAAAA", reason: "test" });
    const s = await (await admin(app, "GET", "/v1/admin/stats")).json();
    assert.deepEqual(s.totals, { reports: 3, installations: 2, occurrences: 4, bans: 1 });
    assert.equal(s.days[0].accepted, 3);
    assert.equal(s.days[0].merged, 1);
    assert.equal(s.days[1].accepted, 0);
});
