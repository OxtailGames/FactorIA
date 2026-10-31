import { test } from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import {
    HMAC_SECRET, INSTALL, b64u, entry, expectedReporterKey, fakeGithub, makeServer, post, pullAll, sendReports, uuid,
} from "./helpers.js";

const users = { good: { id: 9001, login: "octocat" }, other: { id: 9002, login: "hubot" } };
const signIn = (app, token, headers) => post(app, "/v1/auth/github", { githubToken: token }, headers);

function sign(payload) {
    return b64u(createHmac("sha256", HMAC_SECRET).update(payload).digest());
}

test("sign-in calls api.github.com/user and returns a credential and the login", async () => {
    const { app, github } = makeServer({ users });
    const res = await signIn(app, "good");
    assert.equal(res.status, 200);
    const j = await res.json();
    assert.equal(j.ok, true);
    assert.equal(j.login, "octocat");
    assert.equal(github.calls.length, 1);
    assert.equal(github.calls[0].url, "https://api.github.com/user");
    assert.equal(github.calls[0].headers.authorization, "Bearer good");

    // The credential has the documented format: base64url(json{v:1,r,iat}) "." base64url(HMAC(payload)).
    const [payload, sig] = j.credential.split(".");
    assert.equal(sig, sign(payload));
    const body = JSON.parse(Buffer.from(payload, "base64url").toString());
    assert.deepEqual(Object.keys(body).sort(), ["iat", "r", "v"]);
    assert.equal(body.v, 1);
    assert.equal(body.r, expectedReporterKey(9001));
    assert.equal(body.iat, Math.floor(Date.UTC(2026, 5, 10, 12) / 1000));
});

test("a report with the credential is verified; the GitHub account is stored nowhere", async () => {
    const { app, store } = makeServer({ users });
    const { credential } = await (await signIn(app, "good")).json();
    const h = { headers: { authorization: "Bearer " + credential } };
    const first = await (await sendReports(app, [entry(1)], h)).json();
    assert.equal(first.results[0].status, "accepted");
    // The same account from another installation is the same reporter.
    await sendReports(app, [entry(2)], { install: uuid(), ...h });
    const reports = await pullAll(app);
    assert.equal(reports.length, 2);
    for (const r of reports) {
        assert.equal(r.trust, "verified");
        assert.equal(r.reporterKey, expectedReporterKey(9001));
    }
    const dump = JSON.stringify([...store.reports.values()]) + JSON.stringify([...store.counters]) + JSON.stringify([...store.bans]);
    for (const secret of ["octocat", "9001", "good", credential, INSTALL]) assert.ok(!dump.includes(secret), secret);
    // Different accounts get different keys.
    const other = await (await signIn(app, "other")).json();
    assert.notEqual(JSON.parse(Buffer.from(other.credential.split(".")[0], "base64url")).r, expectedReporterKey(9001));
});

test("a rejected GitHub token", async () => {
    const { app } = makeServer({ users });
    const res = await signIn(app, "bad");
    assert.equal(res.status, 401);
    const j = await res.json();
    assert.equal(j.ok, false);
    assert.equal(j.error.code, "invalid_github_token");
    assert.ok(j.error.hint);
    assert.equal(j.credential, undefined);
});

test("GitHub down or unreachable is a 502, not a crash", async () => {
    const { app } = makeServer({ users });
    fakeGithub.fail = 503;
    let res = await signIn(app, "good");
    assert.equal(res.status, 502);
    assert.equal((await res.json()).error.code, "github_unavailable");
    fakeGithub.fail = "network";
    res = await signIn(app, "good");
    assert.equal(res.status, 502);
    fakeGithub.fail = null;
});

test("GitHub answers without an account number", async () => {
    const { app } = makeServer({ users: { weird: { login: "x" }, str: { id: "12", login: "y" } } });
    assert.equal((await signIn(app, "weird")).status, 502);
    assert.equal((await signIn(app, "str")).status, 502);
});

test("sign-in checks its body", async () => {
    const { app, github } = makeServer({ users });
    for (const b of [{}, { githubToken: 5 }, { githubToken: "" }, { githubToken: "a b" }, { githubToken: "x".repeat(600) }, []]) {
        const res = await post(app, "/v1/auth/github", b);
        assert.equal(res.status, 400, JSON.stringify(b).slice(0, 40));
        assert.equal((await res.json()).error.code, "invalid_request");
    }
    assert.equal((await post(app, "/v1/auth/github", "{x")).status, 400);
    assert.equal(github.calls.length, 0, "GitHub is not called for a bad request");
});

test("sign-ins are limited per network", async () => {
    const { app, github } = makeServer({ users, limits: { auth: 2 } });
    const ip = { "cf-connecting-ip": "203.0.113.5" };
    assert.equal((await signIn(app, "good", ip)).status, 200);
    assert.equal((await signIn(app, "bad", ip)).status, 401);
    const res = await signIn(app, "good", ip);
    assert.equal(res.status, 429);
    assert.ok(res.headers.get("retry-after"));
    assert.equal(github.calls.length, 2);
    assert.equal((await signIn(app, "good", { "cf-connecting-ip": "203.0.113.6" })).status, 200);
});

test("credential tampering is refused with 401 and nothing is stored", async () => {
    const { app } = makeServer({ users });
    const { credential } = await (await signIn(app, "good")).json();
    const [payload, sig] = credential.split(".");
    const forgedPayload = b64u(Buffer.from(JSON.stringify({ v: 1, r: expectedReporterKey(1), iat: 1 })));
    const resigned = b64u(createHmac("sha256", "another-secret").update(forgedPayload).digest());
    const flip = (s) => s.slice(0, -1) + (s.endsWith("A") ? "B" : "A");
    const tampered = [
        flip(credential),
        payload + "." + flip(sig),
        flip(payload) + "." + sig,
        forgedPayload + "." + sig, // someone else's key with the real signature
        forgedPayload + "." + resigned, // forged with another secret
        payload, // no signature
        payload + ".", ".", "." + sig, payload + "." + sig + ".extra",
        "garbage", "a".repeat(2000),
        // a correct signature over a payload that is not a credential
        b64u(Buffer.from("not json")) + "." + sign(b64u(Buffer.from("not json"))),
        b64u(Buffer.from(JSON.stringify({ v: 2, r: expectedReporterKey(1), iat: 1 }))) + "." + sign(b64u(Buffer.from(JSON.stringify({ v: 2, r: expectedReporterKey(1), iat: 1 })))),
    ];
    for (const c of tampered) {
        const res = await sendReports(app, [entry(1)], { headers: { authorization: "Bearer " + c } });
        assert.equal(res.status, 401, c.slice(0, 40));
        const j = await res.json();
        assert.equal(j.error.code, "invalid_credential");
        assert.ok(j.error.hint);
    }
    for (const h of ["Bearer ", "Basic abc", "Token " + credential, credential]) {
        const res = await sendReports(app, [entry(1)], { headers: { authorization: h } });
        assert.equal(res.status, 401, h.slice(0, 20));
    }
    assert.equal((await pullAll(app)).length, 0);
    // The genuine one still works.
    assert.equal((await sendReports(app, [entry(1)], { headers: { authorization: "Bearer " + credential } })).status, 200);
});

test("a credential stops working when the server secret changes", async () => {
    const { app } = makeServer({ users });
    const { credential } = await (await signIn(app, "good")).json();
    const rotated = makeServer({ env: { ADMIN_TOKEN: "t", HMAC_SECRET: "a-new-secret" } }).app;
    const res = await sendReports(rotated, [entry(1)], { headers: { authorization: "Bearer " + credential } });
    assert.equal(res.status, 401);
});
