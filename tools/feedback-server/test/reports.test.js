import { test } from "node:test";
import assert from "node:assert/strict";
import { INSTALL, START, body, entry, expectedInstallKey, makeServer, post, pullAll, sendReports, uuid } from "./helpers.js";

async function json(res) {
    return res.json();
}

test("GET / serves the plain privacy page and the rules", async () => {
    const { app } = makeServer();
    const res = await app.fetch(new Request("https://fb.example/"));
    assert.equal(res.status, 200);
    assert.match(res.headers.get("content-type"), /text\/html/);
    const html = await res.text();
    assert.match(html, /What is stored/);
    assert.match(html, /never stored/i);
    assert.match(html, /factoria feedback sharing never/);
    assert.match(html, /Rules for reports/);
    assert.match(html, /No warranty/);
    assert.doesNotMatch(html, /<script/i);
});

test("unknown paths and wrong methods teach", async () => {
    const { app } = makeServer();
    let res = await app.fetch(new Request("https://fb.example/nope"));
    assert.equal(res.status, 404);
    let j = await json(res);
    assert.equal(j.ok, false);
    assert.equal(j.error.code, "not_found");
    assert.ok(j.error.message && j.error.hint);
    res = await app.fetch(new Request("https://fb.example/v1/reports"));
    assert.equal(res.status, 405);
    assert.equal(res.headers.get("allow"), "POST");
    j = await json(res);
    assert.equal(j.error.code, "method_not_allowed");
});

test("a valid report is accepted and stored with derived keys only", async () => {
    const { app, store } = makeServer();
    const res = await sendReports(app, [entry(1)], { "x-ignored": 1 });
    assert.equal(res.status, 200);
    const j = await json(res);
    assert.equal(j.ok, true);
    assert.deepEqual(j.results, [{ localId: "FB-0001", status: "accepted", shareId: "r_000001" }]);

    const reports = await pullAll(app);
    assert.equal(reports.length, 1);
    const r = reports[0];
    assert.equal(r.shareId, "r_000001");
    assert.equal(r.installKey, expectedInstallKey(INSTALL));
    assert.equal(r.installKey.length, 16);
    assert.equal(r.reporterKey, null);
    assert.equal(r.trust, "anonymous");
    assert.equal(r.receivedAt, new Date(START).toISOString());
    assert.equal(r.occurrences, 1);
    assert.equal(r.engineVersion, "0.11.0");
    assert.equal(r.platform, "macos");
    assert.equal(r.category, "physics");
    assert.equal(r.severity, "major");
    assert.equal(r.effort, "small");
    assert.equal(r.reporterKind, "ai");
    assert.equal(r.reviewed, true);
    assert.match(r.missing, /one-way option/);
    assert.equal(r.titleNorm, undefined);
    assert.equal(r.seq, undefined);

    // The raw installation id is nowhere in the stored data.
    const dump = JSON.stringify([...store.reports.values()]) + JSON.stringify([...store.counters]);
    assert.ok(!dump.includes(INSTALL));
    assert.ok(!dump.includes("127.0.0.1"));
});

test("optional fields may be left out", async () => {
    const { app } = makeServer();
    const e = entry(1);
    delete e.suggestion; delete e.workaround; delete e.effort; delete e.reporterKind; delete e.reviewed;
    const j = await json(await sendReports(app, [e]));
    assert.equal(j.results[0].status, "accepted");
    const [r] = await pullAll(app);
    assert.equal(r.suggestion, "");
    assert.equal(r.workaround, "");
    assert.equal(r.effort, null);
    assert.equal(r.reviewed, false);
});

test("the request is checked before entries: install header, JSON, format, size, entries, platform, version", async () => {
    const { app } = makeServer();
    const cases = [
        [await sendReports(app, [entry(1)], { install: "not-a-uuid" }), 400, "missing_install"],
        [await post(app, "/v1/reports", body([entry(1)])), 400, "missing_install"],
        [await post(app, "/v1/reports", "{nope", { "x-factoria-install": INSTALL }), 400, "invalid_json"],
        [await post(app, "/v1/reports", "[1]", { "x-factoria-install": INSTALL }), 400, "invalid_request"],
        [await post(app, "/v1/reports", body([entry(1)], { format: "x/1" }), { "x-factoria-install": INSTALL }), 400, "invalid_format"],
        [await sendReports(app, []), 400, "invalid_request"],
        [await sendReports(app, "no"), 400, "invalid_request"],
        [await sendReports(app, Array.from({ length: 21 }, (_, i) => entry(i))), 400, "too_many_entries"],
        [await sendReports(app, [entry(1)], { platform: "plan9" }), 400, "invalid_request"],
        [await sendReports(app, [entry(1)], { engineVersion: "not a version!" }), 400, "invalid_request"],
        [await sendReports(app, [entry(1, { suggestion: "x ".repeat(40000) })]), 413, "too_large"],
    ];
    for (const [res, status, code] of cases) {
        assert.equal(res.status, status, code);
        const j = await json(res);
        assert.equal(j.ok, false);
        assert.equal(j.error.code, code);
        assert.ok(j.error.message.length > 10 && j.error.hint.length > 10, "teaches");
    }
    assert.equal((await pullAll(app)).length, 0);
});

test("exactly 20 entries are fine; the install header is case-insensitive in the key", async () => {
    const { app } = makeServer();
    const entries = Array.from({ length: 20 }, (_, i) => entry(i));
    const j = await json(await sendReports(app, entries));
    assert.equal(j.results.length, 20);
    assert.ok(j.results.every((r) => r.status === "accepted"));
    const a = await json(await sendReports(app, [entry(100)], { install: INSTALL.toUpperCase() }));
    assert.equal(a.results[0].status, "accepted");
    const reports = await pullAll(app);
    assert.equal(new Set(reports.map((r) => r.installKey)).size, 1);
});

async function rejection(app, e) {
    const j = await json(await sendReports(app, [e]));
    assert.equal(j.results[0].status, "rejected");
    assert.ok(j.results[0].reason && j.results[0].hint);
    return j.results[0];
}

test("each entry is judged on its own: one bad entry does not stop the others", async () => {
    const { app } = makeServer();
    const j = await json(await sendReports(app, [entry(1), entry(2, { title: "x" }), entry(3)]));
    assert.deepEqual(j.results.map((r) => r.status), ["accepted", "rejected", "accepted"]);
    assert.equal(j.results[1].code, "too_short");
    assert.equal(j.results[1].localId, "FB-0002");
    assert.equal(j.results[1].reason, "title needs at least 8 characters");
    assert.equal((await pullAll(app)).length, 2);
});

test("rejection invalid_field", async () => {
    const { app } = makeServer();
    for (const bad of [
        entry(1, { localId: "has space" }), entry(1, { localId: 7 }), entry(1, { category: "phisics" }),
        entry(1, { severity: "huge" }), entry(1, { effort: "tiny" }), entry(1, { reporterKind: "bot" }),
        entry(1, { reviewed: "yes" }), entry(1, { title: 12 }), entry(1, { missing: ["a"] }), entry(1, { category: undefined }),
        "text",
    ]) {
        const r = await rejection(app, bad);
        assert.equal(r.code, "invalid_field", JSON.stringify(bad));
    }
    const r = await rejection(app, entry(1, { category: "phisics" }));
    assert.match(r.hint, /Did you mean "physics"/);
});

test("rejection too_short and too_long at the limits", async () => {
    const { app } = makeServer();
    const ok = (n) => "abcdefghij ".repeat(Math.ceil(n / 11)).slice(0, n).replace(/ $/, "x");
    assert.equal((await rejection(app, entry(1, { title: ok(7) }))).code, "too_short");
    assert.equal((await rejection(app, entry(1, { missing: "too brief to say" }))).code, "too_short");
    assert.equal((await rejection(app, entry(1, { missing: "   " }))).code, "too_short");
    assert.equal((await rejection(app, entry(1, { title: ok(121) }))).code, "too_long");
    assert.equal((await rejection(app, entry(1, { missing: ok(1501) }))).code, "too_long");
    assert.equal((await rejection(app, entry(1, { suggestion: ok(1501) }))).code, "too_long");
    assert.equal((await rejection(app, entry(1, { workaround: ok(1501) }))).code, "too_long");
    // Exactly at the limits is accepted.
    const j = await json(await sendReports(app, [
        entry(1, { title: ok(8) }), entry(2, { title: ok(120) + "" , missing: ok(1500) }),
        entry(3, { missing: ok(20) + " tail word here", suggestion: "", workaround: ok(1500) }),
    ]));
    assert.deepEqual(j.results.map((r) => r.status), ["accepted", "accepted", "accepted"]);
});

test("rejection not_text", async () => {
    const { app } = makeServer();
    for (const bad of [
        entry(1, { missing: "The engine has \u0000 no way to do this thing at all today" }),
        entry(1, { title: "A title\non two lines" }),
        entry(1, { missing: "The engine cannot do this aaaaaaaaaa at all, which is a problem." }),
        entry(1, { missing: "!@#$%^&*()_+ 12345 67890 {}[]<>?/ 99999 ;;; :: ,, .. -- ~~ ``" }),
        entry(1, { missing: "words only three" + " ".repeat(10) + "now" }),
        entry(1, { missing: "123456 7890123 4567890 12345678 9012345" }),
    ]) {
        const r = await rejection(app, bad);
        assert.equal(r.code, "not_text", r.reason);
    }
    // Eight repeats are allowed, nine are not.
    let j = await json(await sendReports(app, [entry(1, { missing: "The engine needs a loooooooong fade between two scenes without a black frame." })]));
    assert.equal(j.results[0].status, "accepted");
    assert.equal((await rejection(app, entry(2, { missing: "The engine needs a looooooooong fade between two scenes without a frame." }))).code, "not_text");
});

test("rejection personal_data: URLs and e-mail addresses", async () => {
    const { app } = makeServer();
    for (const text of [
        "The engine cannot load things from https://example.com/assets in a build.",
        "The engine cannot load things from ftp://host/path in a build for me.",
        "See www.mygame.net for how the engine fails to batch these draw calls.",
        "The engine fails when I mail me@example.org the build and open it again.",
        "The engine fails to open things from github.io pages in the web player.",
    ]) {
        for (const field of ["missing", "title", "suggestion", "workaround"]) {
            const e = entry(1, { [field]: text.length > 120 && field === "title" ? text.slice(0, 100) : text });
            const r = await rejection(app, e);
            assert.equal(r.code, "personal_data", `${field}: ${r.reason}`);
        }
    }
    // Engine API names with dots are not URLs.
    const j = await json(await sendReports(app, [entry(1, { missing: "Collider2D.oneWay and physics.raycast do not agree on what a one-way platform is." })]));
    assert.equal(j.results[0].status, "accepted");
});

test("similar titles of one installation merge; others do not", async () => {
    const { app } = makeServer();
    const a = entry(1, { title: "No one-way platforms" });
    let j = await json(await sendReports(app, [a]));
    const shareId = j.results[0].shareId;

    j = await json(await sendReports(app, [entry(2, { title: "One-way platforms" }), entry(3, { title: "No one way platform support!" })]));
    assert.deepEqual(j.results.map((r) => [r.status, r.shareId]), [["merged", shareId], ["merged", shareId]]);

    // Another category, another title, another installation: separate reports.
    j = await json(await sendReports(app, [entry(4, { title: "No one-way platforms", category: "scene" }), entry(5, { title: "Missing particle trails" })]));
    assert.deepEqual(j.results.map((r) => r.status), ["accepted", "accepted"]);
    j = await json(await sendReports(app, [entry(6, { title: "No one-way platforms" })], { install: uuid() }));
    assert.equal(j.results[0].status, "accepted");
    assert.notEqual(j.results[0].shareId, shareId);

    const reports = await pullAll(app);
    assert.equal(reports.length, 4);
    assert.equal(reports.find((r) => r.shareId === shareId).occurrences, 3);
});

test("entries of one request merge with each other", async () => {
    const { app } = makeServer();
    const j = await json(await sendReports(app, [entry(1, { title: "Text outline is missing" }), entry(2, { title: "Missing text outline" }), entry(3, { title: "Text outline" })]));
    assert.deepEqual(j.results.map((r) => r.status), ["accepted", "merged", "merged"]);
    assert.ok(j.results.every((r) => r.shareId === j.results[0].shareId));
    const [r] = await pullAll(app);
    assert.equal(r.occurrences, 3);
});

test("entries keep nothing but the contract fields; extra fields are dropped", async () => {
    const { app, store } = makeServer();
    await sendReports(app, [entry(1, { gameName: "Secret Quest", path: "/Users/me/game" })]);
    assert.ok(!JSON.stringify([...store.reports.values()]).includes("Secret Quest"));
});
