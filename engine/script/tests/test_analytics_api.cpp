// The `analytics` and `remoteConfig` objects of the "factoria" module (docs/ANALYTICS.md) against the fake HTTP backend: no event
// before consent, a batch after it, a refusal forgets the queue, the quit flush, the cache of the remote config.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json settings() {
    return Json::parse(R"({
      "id": "com.example.stats", "version": "1.2.3",
      "network": {"hosts": ["stats.example.com", "cfg.example.com"], "purpose": "Stats."},
      "analytics": {"endpoint": "https://stats.example.com/events", "batch": 3, "flushSeconds": 5},
      "remoteConfig": {"url": "https://cfg.example.com/game.json"}
    })");
}

}  // namespace

TEST_CASE("analytics api: nothing is queued before consent, a batch goes out after it") {
    TestHost h("an_consent", settings());
    h.file("tests/an.test.js", R"(
import { test, expect, game } from "factoria:test";
import { analytics } from "factoria";

test("no consent, no event", () => {
  game.platform.reset();
  expect(analytics.configured).toBe(true);
  expect(analytics.consent()).toBe("unknown");
  expect(analytics.event("level_done", { level: 1 })).toBe(false);
  expect(analytics.status().queued).toBe(0);
  game.step(2000);
  expect(game.platform.calls().filter((c) => c.method === "http.fetch").length).toBe(0);
});

test("after consent a full batch is POSTed", () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 204 }, 5);
  analytics.setConsent(true);
  expect(analytics.consent()).toBe("granted");
  expect(analytics.event("a", { n: 1 })).toBe(true);
  expect(analytics.event("b")).toBe(true);
  expect(analytics.status().queued).toBe(2);
  analytics.event("c", { ok: true });
  game.step(2);
  const sent = game.analytics.sent();
  expect(sent.map((e) => e.name)).toEqual(["a", "b", "c"]);
  const call = game.platform.calls().filter((c) => c.method === "http.fetch").slice(-1)[0];
  expect(call.args.method).toBe("POST");
  const body = JSON.parse(call.args.body);
  expect(body.game).toBe("com.example.stats");
  expect(body.version).toBe("1.2.3");
  expect(body.events.length).toBe(3);
  expect(game.analytics.requests()[0].reason).toBe("batch");
});

test("a refusal forgets the queue and stops the sending", () => {
  game.platform.reset();
  game.analytics.restart();
  analytics.setConsent(true);
  analytics.event("x");
  analytics.setConsent(false);
  expect(analytics.consent()).toBe("denied");
  expect(game.analytics.queued().length).toBe(0);
  expect(analytics.event("y")).toBe(false);
  analytics.flush();
  game.step(2000);
  expect(game.platform.calls().filter((c) => c.method === "http.fetch").length).toBe(0);
});

test("mistakes throw and teach", () => {
  analytics.setConsent(true);
  expect(() => analytics.event("1bad")).toThrow("name must be");
  expect(() => analytics.event("ok", { nested: { a: 1 } })).toThrow("a string, a number, a boolean or null");
  expect(() => analytics.event("ok", { s: "x".repeat(500) })).toThrow("never what the player typed");
  expect(() => analytics.setConsent("yes")).toThrow("true or false");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/an.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("analytics api: the timer, the suspend and the quit flush send what waits; a failure is retried") {
    TestHost h("an_flush", settings());
    h.file("tests/flush.test.js", R"(
import { test, expect, game } from "factoria:test";
import { analytics } from "factoria";

function fresh() { game.platform.reset(); game.analytics.restart(); analytics.setConsent(true); }
const posts = () => game.platform.calls().filter((c) => c.method === "http.fetch").length;

test("the timer sends an old event", () => {
  fresh();
  game.platform.respond("http.fetch", { status: 200 }, 5);
  analytics.event("old");
  game.step(60);
  expect(posts()).toBe(0);
  game.step(60 * 6);
  expect(game.analytics.sent().map((e) => e.name)).toEqual(["old"]);
  expect(game.analytics.requests()[0].reason).toBe("timer");
});

test("a server error keeps the events and retries later; a 4xx drops them", () => {
  fresh();
  game.platform.respond("http.fetch", { status: 503 }, 1);
  analytics.event("keep");
  analytics.flush();
  game.step(2);
  expect(game.analytics.queued().map((e) => e.name)).toEqual(["keep"]);
  expect(analytics.status().failures).toBe(1);
  game.platform.respond("http.fetch", { status: 400 }, 1);
  game.step(60 * 20);
  expect(game.analytics.queued().length).toBe(0);
  expect(analytics.status().dropped).toBe(1);
});

test("an offline player keeps the queue", () => {
  fresh();
  analytics.event("a");
  analytics.flush();
  game.step(2);
  expect(game.analytics.queued().length).toBe(1);
  expect(game.analytics.requests()[0].ok).toBe(false);
});

test("the quit flush sends what waits", () => {
  fresh();
  game.platform.respond("http.fetch", { status: 200 }, 5);
  analytics.event("last");
  game.closeWindow();
  game.step(2);
  expect(game.analytics.sent().map((e) => e.name)).toEqual(["last"]);
  expect(game.analytics.requests()[0].reason).toBe("quit");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/flush.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("remote config api: the server's values, the cache offline, and a bad answer never half applied") {
    TestHost h("rc_basic", settings());
    h.file("tests/rc.test.js", R"(
import { test, expect, game } from "factoria:test";
import { remoteConfig } from "factoria";

test("defaults when nothing was fetched", () => {
  game.platform.reset();
  game.remoteConfig.restart();
  expect(remoteConfig.configured).toBe(true);
  expect(remoteConfig.get("speed", 1)).toBe(1);
});

test("the server's values win, and type mismatches fall back", async () => {
  game.platform.reset();
  game.remoteConfig.restart();
  game.platform.respond("http.fetch", { status: 200, json: { speed: 2.5, name: 7, hard: true } });
  const src = await remoteConfig.refresh();
  expect(src).toBe("remote");
  expect(remoteConfig.get("speed", 1)).toBe(2.5);
  expect(remoteConfig.get("name", "none")).toBe("none");
  expect(remoteConfig.get("hard", false)).toBe(true);
});

test("offline: the cache of the last good answer", async () => {
  game.platform.reset();
  game.remoteConfig.restart();
  const src = await remoteConfig.ready(1);
  expect(src).toBe("cache");
  expect(remoteConfig.get("speed", 1)).toBe(2.5);
});

test("a bad answer keeps what was there", async () => {
  game.platform.reset();
  game.remoteConfig.restart();
  await remoteConfig.ready(1);
  game.platform.respond("http.fetch", { status: 200, text: "<html>captive portal</html>" });
  await remoteConfig.refresh();
  expect(remoteConfig.source()).toBe("cache");
  expect(remoteConfig.get("speed", 1)).toBe(2.5);
  game.platform.respond("http.fetch", { status: 500, json: { speed: 99 } });
  await remoteConfig.refresh();
  expect(remoteConfig.get("speed", 1)).toBe(2.5);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/rc.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("analytics api: a game without the sections says what to add") {
    TestHost h("an_none");
    h.file("tests/none.test.js", R"(
import { test, expect } from "factoria:test";
import { analytics, remoteConfig } from "factoria";

test("not configured", () => {
  expect(analytics.configured).toBe(false);
  expect(analytics.consent()).toBe("unknown");
  expect(() => analytics.event("a")).toThrow('"analytics": { "endpoint"');
  expect(remoteConfig.configured).toBe(false);
  expect(remoteConfig.get("k", 5)).toBe(5);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/none.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
