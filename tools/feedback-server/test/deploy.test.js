// The pure parts of scripts/deploy.mjs; the deploy itself needs a Cloudflare account and is not run here.

import { test } from "node:test";
import assert from "node:assert/strict";
import {
    DB_NAME, configDir, extractJson, findDatabaseId, mergeAdminFile, parseCreatedId, parseWorkerUrl, secretNames, withDatabaseId,
} from "../scripts/deploy.mjs";
import { readFileSync } from "node:fs";

const ID = "0b9e5d1c-6a47-4b4f-8d58-3f1e2a7c9d10";

test("findDatabaseId reads wrangler d1 list --json among banners", () => {
    const out = ` ⛅️ wrangler 4.0\n[\n  {"uuid": "${ID}", "name": "${DB_NAME}", "created_at": "x"},\n  {"uuid": "other", "name": "x"}\n]\n`;
    assert.equal(findDatabaseId(out), ID);
    assert.equal(findDatabaseId('[{"uuid":"1","name":"nope"}]'), null);
    assert.equal(findDatabaseId("garbage"), null);
    assert.equal(findDatabaseId("[]"), null);
});

test("parseCreatedId reads the snippet wrangler d1 create prints", () => {
    assert.equal(parseCreatedId(`Created!\n[[d1_databases]]\nbinding = "DB"\ndatabase_name = "x"\ndatabase_id = "${ID}"\n`), ID);
    assert.equal(parseCreatedId('{"d1_databases": [{"database_id": "' + ID + '"}]}'), ID);
    assert.equal(parseCreatedId("nothing"), null);
});

test("secretNames", () => {
    assert.deepEqual(secretNames('[{"name":"HMAC_SECRET","type":"secret_text"}]\n'), ["HMAC_SECRET"]);
    assert.deepEqual(secretNames("No secrets"), []);
});

test("withDatabaseId replaces the placeholder and nothing else", () => {
    const toml = readFileSync(new URL("../wrangler.toml", import.meta.url), "utf8");
    const out = withDatabaseId(toml, ID);
    assert.match(out, new RegExp(`database_id = "${ID}"`));
    assert.equal(out.split("\n").length, toml.split("\n").length);
    assert.ok(!out.includes("00000000-0000"));
    assert.throws(() => withDatabaseId("name = 'x'", ID), /database_id/);
});

test("parseWorkerUrl", () => {
    assert.equal(parseWorkerUrl("Deployed factoria-feedback triggers\n  https://factoria-feedback.me.workers.dev\nVersion"), "https://factoria-feedback.me.workers.dev");
    assert.equal(parseWorkerUrl("no url"), null);
});

test("configDir is next to ai.json on each OS", () => {
    assert.equal(configDir({}, "darwin", "/Users/a"), "/Users/a/.factoria");
    assert.equal(configDir({}, "linux", "/home/a"), "/home/a/.factoria");
    assert.match(configDir({ APPDATA: "C:\\Users\\a\\AppData\\Roaming" }, "win32", "C:\\Users\\a"), /AppData.Roaming.factoria$/);
});

test("mergeAdminFile keeps the pull cursor and the old token unless a new one is given", () => {
    assert.deepEqual(mergeAdminFile("", "https://x", "t1"), { endpoint: "https://x", adminToken: "t1" });
    const old = JSON.stringify({ endpoint: "https://old", adminToken: "t0", cursor: "c" });
    assert.deepEqual(mergeAdminFile(old, "https://x", null), { endpoint: "https://x", adminToken: "t0", cursor: "c" });
    assert.deepEqual(mergeAdminFile(old, "https://x", "t2"), { endpoint: "https://x", adminToken: "t2", cursor: "c" });
    assert.deepEqual(mergeAdminFile("{broken", "https://x", "t"), { endpoint: "https://x", adminToken: "t" });
    assert.deepEqual(extractJson('x {"a":1} y'), { a: 1 });
});
