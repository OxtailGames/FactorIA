// Test fixtures: a server over the in-memory store, a fake GitHub, and request builders.

import { createHmac, randomUUID } from "node:crypto";
import { createApp } from "../src/app.js";
import { MemoryStore } from "../src/store_memory.js";

export const ADMIN_TOKEN = "test-admin-token-0123456789";
export const HMAC_SECRET = "test-hmac-secret-0123456789";
export const START = Date.UTC(2026, 5, 10, 12, 0, 0);

/** A fake api.github.com: `users` maps a token to {id, login}; every call is recorded in `calls`. */
export function fakeGithub(users) {
    const calls = [];
    const fn = async (url, init) => {
        calls.push({ url: String(url), headers: init?.headers || {} });
        if (fakeGithub.fail === "network") throw new TypeError("fetch failed");
        if (fakeGithub.fail) return new Response("{}", { status: fakeGithub.fail });
        const token = /^Bearer (.*)$/.exec(init?.headers?.authorization || "")?.[1];
        const user = users[token];
        if (!user) return new Response(JSON.stringify({ message: "Bad credentials" }), { status: 401 });
        return new Response(JSON.stringify(user), { status: 200 });
    };
    fn.calls = calls;
    return fn;
}
fakeGithub.fail = null;

export function makeServer({ limits, users = {}, env, start = START } = {}) {
    const store = new MemoryStore();
    const github = fakeGithub(users);
    fakeGithub.fail = null;
    const clock = { now: start };
    let counter = 0;
    const app = createApp({
        store,
        env: env ?? { ADMIN_TOKEN, HMAC_SECRET },
        fetch: github,
        now: () => clock.now,
        randomId: () => "r_" + String(++counter).padStart(6, "0"),
        limits,
    });
    return { app, store, github, clock };
}

export function entry(n, extra = {}) {
    return {
        localId: "FB-" + String(n).padStart(4, "0"),
        category: "physics",
        severity: "major",
        effort: "small",
        title: "Engine gap " + code(n),
        missing: "Collider2D has no one-way option, so a body cannot pass up through a platform and land on it.",
        suggestion: "Add Collider2D.oneWay as a bool with a direction.",
        workaround: "A script disables the collider while the body moves up.",
        reporterKind: "ai",
        reviewed: true,
        ...extra,
    };
}

const WORDS = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel", "india", "juliet", "kilo", "lima",
    "mike", "november", "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey", "xray",
    "yankee", "zulu"];
/** A distinct word per n, so entries made from different n do not merge. */
export function words(n) {
    return WORDS[n % WORDS.length] + " " + WORDS[Math.floor(n / WORDS.length) % WORDS.length] + " " + WORDS[(n * 7 + 3) % WORDS.length];
}

/** A pseudo-word per n made of letters only, so titles of different n never merge. */
export function code(n) {
    let out = "";
    do {
        out = String.fromCharCode(97 + (n % 26)) + out;
        n = Math.floor(n / 26);
    } while (n > 0);
    return "k" + out;
}

export function body(entries, extra = {}) {
    return { format: "factoria.feedback-share/1", engineVersion: "0.11.0", platform: "macos", entries, ...extra };
}

export function post(app, path, payload, headers = {}) {
    const text = typeof payload === "string" ? payload : JSON.stringify(payload);
    return app.fetch(new Request("https://fb.example" + path, { method: "POST", body: text, headers: { "content-type": "application/json", ...headers } }));
}

export function sendReports(app, entries, { install = INSTALL, headers = {}, ...extra } = {}) {
    return post(app, "/v1/reports", body(entries, extra), { "x-factoria-install": install, ...headers });
}

export const INSTALL = "6f1f3c52-3f0c-4f7e-9a41-6b0c2f0d9a11";
export const uuid = () => randomUUID();

export function admin(app, method, path, payload) {
    const init = { method, headers: { authorization: "Bearer " + ADMIN_TOKEN } };
    if (payload !== undefined) {
        init.body = JSON.stringify(payload);
        init.headers["content-type"] = "application/json";
    }
    return app.fetch(new Request("https://fb.example" + path, init));
}

export async function pull(app, since, limit) {
    const q = [since ? "since=" + since : "", limit ? "limit=" + limit : ""].filter(Boolean).join("&");
    return (await admin(app, "GET", "/v1/admin/reports" + (q ? "?" + q : ""))).json();
}

export async function pullAll(app) {
    const out = [];
    let cursor;
    for (;;) {
        const page = await pull(app, cursor, 500);
        out.push(...page.reports);
        if (page.reports.length === 0) return out;
        cursor = page.next;
    }
}

// Independent derivations of the keys (node:crypto), to check the server computes them as the contract says.
export function b64u(buf) {
    return Buffer.from(buf).toString("base64url");
}
export const expectedInstallKey = (id) => b64u(createHmac("sha256", HMAC_SECRET).update("install:" + id).digest()).slice(0, 16);
export const expectedReporterKey = (githubId) => b64u(createHmac("sha256", HMAC_SECRET).update("github:" + githubId).digest()).slice(0, 16);
