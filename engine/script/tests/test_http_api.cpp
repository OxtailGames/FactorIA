// The `http` object of the "factoria" module against the fake backend (fa_services) through the script test host: nothing here
// touches the network. The system HTTP clients are tested in engine/platform, the dispatcher and the fake in engine/services.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json settings() {
    return Json::parse(R"({
      "network": {"hosts": ["api.example.com", "*.cdn.example.com", "localhost"], "purpose": "Test server."}
    })");
}

}  // namespace

TEST_CASE("http api: fetch answers what the test scripted, with status, headers, text and json()") {
    TestHost h("http_basic", settings());
    h.file("scenes/level2.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("tests/http.test.js", R"(
import { test, expect, game } from "factoria:test";
import { http, platform } from "factoria";

test("the fake backend serves http and says so", () => {
  game.platform.reset();
  expect(platform.has("http")).toBe(true);
  const state = game.platform.state();
  expect(state.httpBackend).toBe("fake");
  expect(state.networkHosts).toEqual(["api.example.com", "*.cdn.example.com", "localhost"]);
  expect(state.httpWhy).toContain("never reaches the network");
});

test("a GET resolves with the scripted answer", async () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 200, json: { scores: [3, 2, 1] }, headers: { "X-Total": "3" } });
  const r = await http.fetch("https://api.example.com/scores?top=3");
  expect(r.status).toBe(200);
  expect(r.ok).toBe(true);
  expect(r.json()).toEqual({ scores: [3, 2, 1] });
  expect(r.text).toBe('{"scores":[3,2,1]}');
  expect(r.headers["x-total"]).toBe("3");
  expect(r.headers["content-type"]).toBe("application/json");
  const call = game.platform.calls().slice(-1)[0];
  expect(call.method).toBe("http.fetch");
  expect(call.args.url).toBe("https://api.example.com/scores?top=3");
  expect(call.args.method).toBe("GET");
  expect(call.args.timeout).toBe(15);
});

test("a server error status resolves with ok false, it is not a failure", async () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 503, text: "maintenance" });
  const r = await http.fetch("https://a.cdn.example.com/x.json");
  expect(r.ok).toBe(false);
  expect(r.status).toBe(503);
  expect(r.text).toBe("maintenance");
  expect(() => r.json()).toThrow("the response body is not JSON");
  expect(() => r.json()).toThrow('it starts with "maintenance"');
});

test("an object body goes as JSON with a content type, a string goes as it is", async () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 201 }, 3);
  await http.fetch("https://api.example.com/scores", { method: "post", body: { name: "Ann", score: 10 } });
  let call = game.platform.calls().slice(-1)[0];
  expect(call.args.method).toBe("POST");
  expect(JSON.parse(call.args.body)).toEqual({ name: "Ann", score: 10 });
  expect(call.args.headers).toEqual({ "Content-Type": "application/json" });

  await http.fetch("https://api.example.com/scores", { method: "PUT", body: "plain text", headers: { "X-Key": "k", "content-type": "text/plain" }, timeout: 5 });
  call = game.platform.calls().slice(-1)[0];
  expect(call.args.body).toBe("plain text");
  expect(call.args.headers).toEqual({ "X-Key": "k", "content-type": "text/plain" });
  expect(call.args.timeout).toBe(5);

  const options = { method: "POST", body: [1, 2], headers: { "X-Key": "k" } };
  await http.fetch("https://api.example.com/scores", options);
  expect(options.headers).toEqual({ "X-Key": "k" });  // the game's object is not changed
  call = game.platform.calls().slice(-1)[0];
  expect(call.args.headers).toEqual({ "X-Key": "k", "Content-Type": "application/json" });
});

test("a failure rejects with code and hint; nobody scripted an answer: network", async () => {
  game.platform.reset();
  let err;
  await http.fetch("https://api.example.com/none").catch((e) => { err = e; });
  expect(err.code).toBe("network");
  expect(err.message).toContain('http.fetch("https://api.example.com/none") failed');
  expect(err.hint).toContain("game.platform.respond");

  game.platform.respond("http.fetch", { error: "network", message: "timed out", hint: "Try again." });
  err = undefined;
  await http.fetch("https://api.example.com/slow", { timeout: 1 }).catch((e) => { err = e; });
  expect(err.code).toBe("network");
  expect(err.message).toContain("timed out");
  expect(err.hint).toBe("Try again.");
});

test("a response is immutable", async () => {
  game.platform.reset();
  game.platform.respond("http.fetch", { status: 200, text: "x" });
  const r = await http.fetch("https://api.example.com/x");
  expect(Object.isFrozen(r)).toBe(true);
  expect(Object.isFrozen(r.headers)).toBe(true);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/http.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 6);
}

TEST_CASE("http api: a mistake in the call throws at once and says what to change") {
    TestHost h("http_mistakes", settings());
    h.file("tests/mistakes.test.js", R"(
import { test, expect, game } from "factoria:test";
import { http } from "factoria";

test("hosts and schemes", () => {
  game.platform.reset();
  expect(() => http.fetch("https://other.example.com/x")).toThrow("not declared");
  expect(() => http.fetch("https://other.example.com/x")).toThrow('http.fetch("https://other.example.com/x")');
  expect(() => http.fetch("https://api.example.co/x")).toThrow("Did you mean");
  expect(() => http.fetch("http://api.example.com/x")).toThrow("plain http://");
  expect(() => http.fetch("https://cdn.example.com/x")).toThrow("not declared");  // a wildcard covers subdomains only
  expect(() => http.fetch("ftp://api.example.com/x")).toThrow("only speaks https");
  expect(() => http.fetch("https://user:pw@api.example.com/")).toThrow("user name or password");
  expect(() => http.fetch(42)).toThrow("url");
  expect(() => http.fetch()).toThrow("url");
});

test("options", () => {
  game.platform.reset();
  const url = "https://api.example.com/x";
  expect(() => http.fetch(url, { methd: "GET" })).toThrow("did you mean 'method'");
  expect(() => http.fetch(url, "GET")).toThrow("options must be an object");
  expect(() => http.fetch(url, { method: "FETCH" })).toThrow("is not a method http.fetch sends");
  expect(() => http.fetch(url, { method: "GET", body: "x" })).toThrow("cannot have a body");
  expect(() => http.fetch(url, { method: "POST", body: () => 1 })).toThrow("body must be a string");
  expect(() => http.fetch(url, { headers: { "X-A": 1 } })).toThrow("must be a string");
  expect(() => http.fetch(url, { headers: { Host: "evil.com" } })).toThrow("set by the system");
  expect(() => http.fetch(url, { headers: ["a"] })).toThrow("must be an object");
  expect(() => http.fetch(url, { timeout: 0 })).toThrow("above 0 and at most 120");
  expect(() => http.fetch(url, { timeout: 999 })).toThrow("above 0 and at most 120");
  // Nothing of this reached the backend.
  expect(game.platform.calls().filter((c) => c.method === "http.fetch").length).toBe(0);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/mistakes.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 2);
}

TEST_CASE("http api: a game without a network section cannot fetch, and says what to declare") {
    TestHost h("http_undeclared");
    h.file("tests/none.test.js", R"(
import { test, expect, game } from "factoria:test";
import { http } from "factoria";

test("no hosts declared", () => {
  expect(() => http.fetch("https://api.example.com/x")).toThrow("declares no network hosts");
  expect(() => http.fetch("https://api.example.com/x")).toThrow('"network": {"hosts": ["api.example.com"]}');
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/none.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("http api: an answer that comes after the scene changed is told apart by scene.current") {
    TestHost h("http_stale", settings());
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("scenes/level2.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("tests/stale.test.js", R"(
import { test, expect, game } from "factoria:test";
import { http, scene } from "factoria";

// The recipe of docs/NETWORKING.md: remember the scene, check it again when the answer arrives.
test("the answer of a request made in an earlier scene is not applied to the new one", () => {
  game.platform.reset();
  scene.load("scenes/main.scene.json");
  game.step(1);
  game.platform.set({ delayFrames: 3 });
  game.platform.respond("http.fetch", { status: 200, json: { daily: 7 } }, 2);
  const here = scene.current;
  let applied = null, ignored = null;
  const ask = () => http.fetch("https://api.example.com/daily").then((r) => {
    if (scene.current !== here) ignored = r.json().daily;
    else applied = r.json().daily;
  });
  ask();
  scene.load("scenes/level2.scene.json");
  game.step(1);
  expect(scene.current).toBe("scenes/level2.scene.json");
  game.step(5);
  expect(applied).toBeNull();
  expect(ignored).toBe(7);

  // Back in the scene the request was made in, the same answer is applied.
  scene.load("scenes/main.scene.json");
  game.step(1);
  applied = null;
  const again = scene.current;
  http.fetch("https://api.example.com/daily").then((r) => { if (scene.current === again) applied = r.json().daily; });
  game.step(5);
  expect(applied).toBe(7);
  game.platform.reset();
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/stale.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
}
