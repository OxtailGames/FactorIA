// The developer's verdict on a report: admin reject / unreject, and POST /v1/verdicts, where an installation reads the
// verdicts of its OWN reports (and nothing else).

import { test } from "node:test";
import assert from "node:assert/strict";
import { ADMIN_TOKEN, INSTALL, admin, entry, makeServer, pullAll, post, sendReports, uuid } from "./helpers.js";

const OTHER = "0a9d5bb1-6f35-4c4e-8d8b-0c1d2e3f4a5b";

async function seed(app, n = 2, install = INSTALL) {
    const ids = [];
    for (let i = 0; i < n; i++) {
        const j = await (await sendReports(app, [entry(i + (install === INSTALL ? 0 : 100))], { install })).json();
        ids.push(j.results[0].shareId);
    }
    return ids;
}

const verdicts = (app, shareIds, install = INSTALL) => post(app, "/v1/verdicts", { shareIds }, { "x-factoria-install": install });

test("admin reject stores the reason, pull shows it, unreject clears it", async () => {
    const { app } = makeServer();
    const [a, b] = await seed(app);
    const res = await admin(app, "POST", "/v1/admin/reject", { shareId: a, reason: "  Collider2D\n\tsupports   it:\u0000 see docs/reference/components/physics.md.  " });
    assert.equal(res.status, 200);
    const j = await res.json();
    assert.deepEqual(j, { ok: true, rejected: [a], notFound: [] });
    const reports = await pullAll(app);
    const ra = reports.find((r) => r.shareId === a);
    assert.equal(ra.verdict, "rejected");
    assert.equal(ra.verdictReason, "Collider2D supports it: see docs/reference/components/physics.md.");
    assert.equal(reports.find((r) => r.shareId === b).verdict, null);

    const un = await (await admin(app, "POST", "/v1/admin/unreject", { shareId: a })).json();
    assert.deepEqual(un, { ok: true, restored: [a], notFound: [] });
    const again = (await pullAll(app)).find((r) => r.shareId === a);
    assert.equal(again.verdict, null);
    assert.equal(again.verdictReason, null);
});

test("admin reject in a batch: some missing ids are listed, the rest are rejected", async () => {
    const { app } = makeServer();
    const [a, b] = await seed(app);
    const j = await (await admin(app, "POST", "/v1/admin/reject", {
        rejections: [{ shareId: a, reason: "exists" }, { shareId: "r_zzzzzz", reason: "x" }, { shareId: b, reason: "also exists" }],
    })).json();
    assert.deepEqual(j.rejected, [a, b]);
    assert.deepEqual(j.notFound, ["r_zzzzzz"]);
    const un = await (await admin(app, "POST", "/v1/admin/unreject", { shareIds: [a, b, "r_nothere"] })).json();
    assert.deepEqual(un.restored, [a, b]);
    assert.deepEqual(un.notFound, ["r_nothere"]);
});

test("admin reject refuses bad input with an error that teaches", async () => {
    const { app } = makeServer();
    const [a] = await seed(app, 1);
    const bad = [
        [{ shareId: "nope", reason: "x" }, /shareId/],
        [{ shareId: a }, /reason/],
        [{ shareId: a, reason: "   \n " }, /empty/],
        [{ shareId: a, reason: "x".repeat(501) }, /501|limit is 500/],
        [{ rejections: [] }, /rejections/],
        [{ rejections: [{ shareId: a, reason: "ok" }, 5] }, /rejections\[1\]/],
        [{ rejections: Array.from({ length: 51 }, () => ({ shareId: a, reason: "x" })) }, /rejections/],
    ];
    for (const [payload, pattern] of bad) {
        const res = await admin(app, "POST", "/v1/admin/reject", payload);
        assert.equal(res.status, 400, JSON.stringify(payload).slice(0, 60));
        const j = await res.json();
        assert.equal(j.error.code, "invalid_request");
        assert.match(j.error.message, pattern);
        assert.ok(j.error.hint.length > 5);
    }
    assert.equal((await admin(app, "POST", "/v1/admin/unreject", {})).status, 400);
    // nothing was changed by the failed calls
    assert.equal((await pullAll(app))[0].verdict, null);
});

test("the reject and unreject endpoints need the admin token", async () => {
    const { app } = makeServer();
    for (const path of ["/v1/admin/reject", "/v1/admin/unreject"]) {
        assert.equal((await post(app, path, { shareId: "r_000001", reason: "x" })).status, 401);
        const res = await app.fetch(new Request("https://fb.example" + path, { method: "GET", headers: { authorization: "Bearer " + ADMIN_TOKEN } }));
        assert.equal(res.status, 405);
    }
});

test("an installation reads the verdicts of its own reports", async () => {
    const { app } = makeServer();
    const [a, b] = await seed(app);
    await admin(app, "POST", "/v1/admin/reject", { shareId: a, reason: "Exists: Collider2D.oneWay." });
    const res = await verdicts(app, [a, b]);
    assert.equal(res.status, 200);
    const j = await res.json();
    assert.equal(j.ok, true);
    const byId = Object.fromEntries(j.verdicts.map((v) => [v.shareId, v]));
    assert.equal(byId[a].status, "rejected");
    assert.equal(byId[a].reason, "Exists: Collider2D.oneWay.");
    assert.match(byId[a].at, /^\d{4}-\d\d-\d\dT/);
    assert.deepEqual(byId[b], { shareId: b, status: "received" });

    await admin(app, "POST", "/v1/admin/unreject", { shareId: a });
    const back = await (await verdicts(app, [a])).json();
    assert.deepEqual(back.verdicts, [{ shareId: a, status: "received" }]);
});

test("verdicts never leak another installation's reports", async () => {
    const { app } = makeServer();
    const [mine] = await seed(app, 1);
    const [theirs] = await seed(app, 1, OTHER);
    await admin(app, "POST", "/v1/admin/reject", { shareId: theirs, reason: "private reason of the other installation" });
    // asking for the other installation's id, or for an id that does not exist, gets no answer at all (the same answer)
    const j = await (await verdicts(app, [mine, theirs, "r_zzzzzz"])).json();
    assert.deepEqual(j.verdicts.map((v) => v.shareId), [mine]);
    assert.ok(!JSON.stringify(j).includes("private reason"));
    // the other side sees its own
    const k = await (await verdicts(app, [mine, theirs], OTHER)).json();
    assert.deepEqual(k.verdicts.map((v) => v.shareId), [theirs]);
    // a brand-new installation sees nothing
    const none = await (await verdicts(app, [mine, theirs], uuid())).json();
    assert.deepEqual(none.verdicts, []);
});

test("verdicts validates its request", async () => {
    const { app } = makeServer();
    const noHeader = await post(app, "/v1/verdicts", { shareIds: ["r_000001"] });
    assert.equal(noHeader.status, 400);
    assert.equal((await noHeader.json()).error.code, "missing_install");
    const h = { "x-factoria-install": INSTALL };
    for (const payload of [{}, { shareIds: [] }, { shareIds: "r_000001" }, { shareIds: [5] }, { shareIds: ["../etc"] }, { shareIds: Array.from({ length: 101 }, (_, i) => "r_" + String(i).padStart(6, "0")) }]) {
        const res = await post(app, "/v1/verdicts", payload, h);
        assert.equal(res.status, 400, JSON.stringify(payload).slice(0, 50));
        assert.equal((await res.json()).error.code, "invalid_request");
    }
    assert.equal((await app.fetch(new Request("https://fb.example/v1/verdicts"))).status, 405);
    assert.equal((await post(app, "/v1/verdicts", "not json", h)).status, 400);
});

test("verdicts has a daily limit per installation, that resets at midnight", async () => {
    const { app, clock } = makeServer({ limits: { verdicts: 3 } });
    const [a] = await seed(app, 1);
    for (let i = 0; i < 3; i++) assert.equal((await verdicts(app, [a])).status, 200);
    const res = await verdicts(app, [a]);
    assert.equal(res.status, 429);
    assert.ok(Number(res.headers.get("retry-after")) > 0);
    assert.equal((await verdicts(app, [a], OTHER)).status, 200); // another installation has its own budget
    clock.now += 24 * 3600 * 1000;
    assert.equal((await verdicts(app, [a])).status, 200);
});

test("a verdict stays when the same gap is reported again", async () => {
    const { app } = makeServer();
    const [a] = await seed(app, 1);
    await admin(app, "POST", "/v1/admin/reject", { shareId: a, reason: "exists" });
    const again = await (await sendReports(app, [entry(0)])).json();
    assert.equal(again.results[0].status, "merged");
    assert.equal(again.results[0].shareId, a);
    assert.equal((await (await verdicts(app, [a])).json()).verdicts[0].status, "rejected");
});

test("deleting a report removes its verdict", async () => {
    const { app } = makeServer();
    const [a] = await seed(app, 1);
    await admin(app, "POST", "/v1/admin/reject", { shareId: a, reason: "exists" });
    assert.equal((await admin(app, "DELETE", "/v1/admin/reports/" + a)).status, 200);
    assert.deepEqual((await (await verdicts(app, [a])).json()).verdicts, []);
});
