// Efficiency entries: the measured numbers and the fix type ride along, are validated, merge by fix type, and come out of
// the admin pull next to the text.

import { test } from "node:test";
import assert from "node:assert/strict";
import { entry, makeServer, pullAll, sendReports } from "./helpers.js";

const measure = (steps, minutes, tokens, costUsd) => ({ steps, toolCalls: Math.floor(steps / 2), minutes, tokens, costUsd, estimated: false });

function efficiencyEntry(n, block = {}, extra = {}) {
    return entry(n, {
        title: "Tilemap collision layers took many steps",
        missing: "Understanding how Tilemap layers map to collision took many steps of reading components and trying values.",
        efficiency: {
            fixType: "doc", appliesTo: "every-game", measured: measure(120, 14.5, 400000, 1.2), saving: measure(96, 11.6, 320000, 0.96),
            expectedShare: 0.8, spans: 2, ...block,
        },
        ...extra,
    });
}

test("an efficiency entry is stored with its block and comes out of the admin pull", async () => {
    const { app } = makeServer();
    const j = await (await sendReports(app, [efficiencyEntry(1)])).json();
    assert.equal(j.results[0].status, "accepted");
    const [r] = await pullAll(app);
    assert.equal(r.kind, "efficiency");
    assert.equal(r.efficiency.fixType, "doc");
    assert.equal(r.efficiency.measured.steps, 120);
    assert.equal(r.efficiency.saving.costUsd, 0.96);
    assert.equal(r.efficiency.expectedShare, 0.8);
});

test("a gap report has kind gap and no efficiency block", async () => {
    const { app } = makeServer();
    await sendReports(app, [entry(1)]);
    const [r] = await pullAll(app);
    assert.equal(r.kind, "gap");
    assert.equal("efficiency" in r, false);
});

test("a bad block is rejected with a hint, and unknown block fields are dropped", async () => {
    const { app } = makeServer();
    const bad = [
        efficiencyEntry(1, { fixType: "docs" }),
        efficiencyEntry(2, { appliesTo: "this-game" }),
        efficiencyEntry(3, { expectedShare: 3 }),
        efficiencyEntry(4, { measured: measure(-1, 1, 1, 0) }),
        efficiencyEntry(5, { saving: { ...measure(1, 1, 1, 0), tokens: 1e15 } }),
        efficiencyEntry(6, { spans: 2.5 }),
        efficiencyEntry(7, { afterFix: "0.1 0" }),
        efficiencyEntry(8, { measured: null }),
        efficiencyEntry(10, { afterFix: "v0.17.0" }),  // a version starts with a digit (the schema and the engine say so too)
    ];
    const j = await (await sendReports(app, bad)).json();
    for (const r of j.results) {
        assert.equal(r.status, "rejected", JSON.stringify(r));
        assert.equal(r.code, "invalid_field");
        assert.ok(r.hint.length > 5);
    }
    assert.match(j.results[0].hint, /Did you mean "doc"/);
    const ok = await (await sendReports(app, [efficiencyEntry(9, { waste: "Game Name Hero Quest", session: "20260101-abc" })])).json();
    assert.equal(ok.results[0].status, "accepted");
    const [r] = await pullAll(app);
    assert.deepEqual(Object.keys(r.efficiency).sort(), ["afterFix", "appliesTo", "candidate", "expectedShare", "fixType", "measured", "saving", "spans"]);
    assert.ok(!JSON.stringify(r).includes("Hero Quest"));
});

test("a resend of the same entry merges and the latest cumulative numbers replace the stored ones", async () => {
    const { app } = makeServer();
    const first = await (await sendReports(app, [efficiencyEntry(1)])).json();
    const second = await (
        await sendReports(app, [efficiencyEntry(1, { measured: measure(240, 29, 800000, 2.4), saving: measure(192, 23.2, 640000, 1.92), spans: 4 })])
    ).json();
    assert.equal(second.results[0].status, "merged");
    assert.equal(second.results[0].shareId, first.results[0].shareId);
    const reports = await pullAll(app);
    assert.equal(reports.length, 1);
    assert.equal(reports[0].occurrences, 2);
    assert.equal(reports[0].efficiency.measured.steps, 240);
    assert.equal(reports[0].efficiency.spans, 4);
});

test("the same title with another fix type, or a gap with the same title, does not merge", async () => {
    const { app } = makeServer();
    await sendReports(app, [efficiencyEntry(1)]);
    const j = await (await sendReports(app, [efficiencyEntry(2, { fixType: "newCommand" }), entry(3, { title: "Tilemap collision layers took many steps" })])).json();
    assert.deepEqual(j.results.map((r) => r.status), ["accepted", "accepted"]);
    const reports = await pullAll(app);
    assert.deepEqual(reports.map((r) => r.kind), ["efficiency", "efficiency", "gap"]);
    assert.equal(reports.length, 3);
});

test("two efficiency entries of one request that say the same thing merge before they are stored", async () => {
    const { app } = makeServer();
    const j = await (await sendReports(app, [efficiencyEntry(1), efficiencyEntry(2, { measured: measure(300, 40, 1, 0) })])).json();
    assert.deepEqual(j.results.map((r) => r.status), ["accepted", "merged"]);
    const [r] = await pullAll(app);
    assert.equal(r.efficiency.measured.steps, 300);
});
