// The `websocket` object of the "factoria" module against the memory client (fa_platform) through the script test host: nothing
// here touches the network. The codec, the test server and the system clients are tested in engine/platform, the host policy in
// engine/services.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json settings() {
    return Json::parse(R"({
      "network": {"hosts": ["game.example.com", "*.live.example.com", "localhost"], "purpose": "Test server."}
    })");
}

}  // namespace

TEST_CASE("websocket api: open, messages both ways, close") {
    TestHost h("ws_basic", settings());
    h.file("tests/ws.test.js", R"(
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

test("the memory client serves websocket and says so", () => {
  game.websocket.reset();
  expect(websocket.supported).toBe(true);
  expect(websocket.backend).toBe("memory");
  expect(websocket.unsupportedReason).toBe("");
});

test("open, a text and a binary message, send, close", () => {
  game.websocket.reset();
  const log = [];
  const ws = websocket.connect("wss://game.example.com/room?id=7", { protocols: ["chat.v1", "chat.v2"], headers: { "X-Token": "abc" } });
  expect(ws.readyState).toBe("connecting");
  expect(ws.url).toBe("wss://game.example.com/room?id=7");
  expect(ws.send("too early")).toBe(false);
  ws.on("open", (e) => log.push("open:" + e.protocol + ":" + e.reconnected));
  ws.on("message", (e) => log.push(e.binary ? "bin:" + Array.from(new Uint8Array(e.data)).join(",") : "text:" + e.data));
  ws.on("close", (e) => log.push("close:" + e.code + ":" + e.reason + ":" + e.wasClean + ":" + e.willReconnect));

  const c = game.websocket.connections();
  expect(c.length).toBe(1);
  expect(c[0].url).toBe("wss://game.example.com/room?id=7");
  expect(c[0].protocols).toEqual(["chat.v1", "chat.v2"]);
  expect(c[0].headers).toEqual({ "X-Token": "abc" });

  game.step();
  expect(log).toEqual(["open::false"]);
  expect(ws.readyState).toBe("open");

  game.websocket.send(0, "hello");
  game.websocket.send(0, new Uint8Array([1, 2, 3]));
  game.websocket.send(0, "");
  game.step();
  expect(log.slice(1)).toEqual(["text:hello", "bin:1,2,3", "text:"]);

  expect(ws.send("from the game")).toBe(true);
  expect(ws.send(new Uint8Array([9, 8]))).toBe(true);
  expect(ws.send(new Uint8Array(0))).toBe(true);
  const raw = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7]).buffer;
  expect(ws.send(new DataView(raw, 2, 3))).toBe(true);           // a DataView sends the bytes it shows
  expect(ws.send(new Uint16Array(raw, 2, 2))).toBe(true);        // so does a typed array with an offset
  game.websocket.send(0, new DataView(raw, 5, 2));
  game.step();
  expect(log[log.length - 1]).toBe("bin:5,6");                    // the game sees the bytes the DataView shows, not the whole buffer
  const got = game.websocket.connections()[0].received;
  expect(got.length).toBe(5);
  expect(Array.from(new Uint8Array(got[3]))).toEqual([2, 3, 4]);
  expect(Array.from(new Uint8Array(got[4]))).toEqual([2, 3, 4, 5]);
  expect(got[0]).toBe("from the game");
  expect(Array.from(new Uint8Array(got[1]))).toEqual([9, 8]);
  expect(got[2].byteLength).toBe(0);

  ws.close(1000, "bye");
  expect(ws.readyState).toBe("closing");
  expect(ws.send("late")).toBe(false);
  game.step();
  expect(log[log.length - 1]).toBe("close:1000:bye:true:false");
  expect(ws.readyState).toBe("closed");
  const after = game.websocket.connections()[0];
  expect(after.closedByGame).toBe(true);
  expect(after.closeCode).toBe(1000);
  expect(after.closeReason).toBe("bye");
});

test("the server picks a subprotocol and closes with its own code", () => {
  game.websocket.reset();
  game.websocket.autoAccept(false);
  const ws = websocket.connect("ws://localhost:8080/", { protocols: ["a", "b"] });
  const log = [];
  ws.on("open", (e) => log.push("open:" + e.protocol));
  ws.on("close", (e) => log.push("close:" + e.code + ":" + e.reason + ":" + e.wasClean));
  game.step();
  expect(log).toEqual([]);
  expect(() => game.websocket.accept(0, "c")).toThrow("did not offer");
  game.websocket.accept(0, "b");
  game.step();
  expect(ws.protocol).toBe("b");
  game.websocket.close(0, 4001, "kicked");
  game.step();
  expect(log).toEqual(["open:b", "close:4001:kicked:true"]);
});

test("a refused handshake and a dropped connection give an error, then a close with 1006", () => {
  game.websocket.reset();
  game.websocket.autoAccept(false);
  const a = websocket.connect("wss://game.example.com/a");
  const log = [];
  a.on("error", (e) => log.push("error:" + e.httpStatus + ":" + e.message));
  a.on("close", (e) => log.push("close:" + e.code + ":" + e.wasClean));
  game.websocket.refuse(0, "no room", 403);
  game.step();
  expect(log).toEqual(["error:403:no room", "close:1006:false"]);

  game.websocket.autoAccept(true);
  const b = websocket.connect("wss://game.example.com/b");
  const lb = [];
  b.on("error", (e) => lb.push("error:" + e.message));
  b.on("close", (e) => lb.push("close:" + e.code + ":" + e.wasClean));
  game.step();
  game.websocket.drop(1, "cable pulled");
  game.step();
  expect(lb).toEqual(["error:cable pulled", "close:1006:false"]);
  expect(b.readyState).toBe("closed");
});

test("handlers can be removed and a handler that throws does not stop the others", () => {
  game.websocket.reset();
  game.expectErrors("boom");
  const ws = websocket.connect("wss://game.example.com/");
  const log = [];
  const off = ws.on("message", (e) => log.push("a:" + e.data));
  ws.on("message", () => { throw new Error("boom"); });
  ws.on("message", (e) => log.push("c:" + e.data));
  game.step();
  game.websocket.send(0, "1");
  game.step();
  off();
  game.websocket.send(0, "2");
  game.step();
  expect(log).toEqual(["a:1", "c:1", "c:2"]);
});

test("a message that is too long is refused and a send of the wrong kind throws", () => {
  game.websocket.reset();
  const ws = websocket.connect("wss://game.example.com/", { maxMessageBytes: 100 });
  game.step();
  expect(() => ws.send("x".repeat(101))).toThrow("100");
  expect(() => ws.send({ a: 1 })).toThrow("JSON.stringify");
  expect(() => ws.send(42)).toThrow("string, an ArrayBuffer or a typed array");
  expect(ws.send("x".repeat(100))).toBe(true);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/ws.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 6);
}

TEST_CASE("websocket api: reconnects with a growing, repeatable delay") {
    TestHost h("ws_reconnect", settings());
    h.file("tests/reconnect.test.js", R"(
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

function run(url) {
  game.websocket.reset();
  const ws = websocket.connect(url, { reconnect: { maxAttempts: 4, minDelay: 1, maxDelay: 5, factor: 2, jitter: 0.25 } });
  const log = [];
  ws.on("open", (e) => log.push("open:" + e.reconnected));
  ws.on("close", (e) => log.push("close:" + e.willReconnect));
  ws.on("reconnecting", (e) => log.push(e));
  return { ws, log };
}
function stepSeconds(s) { game.step(Math.round(s * 60)); }

test("the delays grow, stay within the jitter and are the same on every run", () => {
  const delaysOf = (url) => {
    const { ws, log } = run(url);
    game.step();
    game.websocket.refuseNext(3);
    game.websocket.drop(0);
    game.step();
    const delays = [];
    for (let i = 0; i < 4; i++) {
      const last = log.filter((e) => typeof e === "object").slice(-1)[0];
      delays.push(last.delay);
      stepSeconds(last.delay + 0.1);
    }
    game.step(2);
    return { ws, log, delays };
  };
  const one = delaysOf("wss://game.example.com/a");
  const [d1, d2, d3, d4] = one.delays;
  expect(d1).toBeGreaterThan(0.75 - 1e-9);
  expect(d1).toBeLessThan(1.25 + 1e-9);
  expect(d2).toBeGreaterThan(1.5 - 1e-9);
  expect(d2).toBeLessThan(2.5 + 1e-9);
  expect(d3).toBeGreaterThan(3 - 1e-9);
  expect(d3).toBeLessThan(5 + 1e-9);
  expect(d4).toBeGreaterThan(3.75 - 1e-9);
  expect(d4).toBeLessThan(5 + 1e-9);
  const two = delaysOf("wss://game.example.com/a");
  expect(two.delays).toEqual(one.delays);
  const other = delaysOf("wss://game.example.com/b");
  expect(other.delays).not.toEqual(one.delays);
  expect(other.ws.readyState).toBe("open");
  expect(two.log.filter((e) => typeof e === "string").slice(-2)).toEqual(["close:true", "open:true"]);
  expect(two.ws.attempt).toBe(0);
});

test("the server dropping an open connection reconnects; close() ends it for good", () => {
  const { ws, log } = run("wss://game.example.com/room");
  game.step();
  expect(log).toEqual(["open:false"]);
  game.websocket.drop(0);
  game.step();
  expect(ws.readyState).toBe("connecting");
  expect(ws.attempt).toBe(1);
  expect(log.slice(1, 3)).toEqual(["close:true", { attempt: 1, delay: log[2].delay }]);
  expect(game.websocket.connections().length).toBe(1);
  stepSeconds(2);
  expect(game.websocket.connections().length).toBe(2);
  game.step();
  expect(ws.readyState).toBe("open");
  expect(ws.attempt).toBe(0);
  expect(log[log.length - 1]).toBe("open:true");
  ws.close();
  game.step();
  expect(ws.readyState).toBe("closed");
  stepSeconds(10);
  expect(game.websocket.connections().length).toBe(2);
});

test("close() while it waits cancels the reconnect; maxAttempts ends it", () => {
  let r = run("wss://game.example.com/wait");
  game.step();
  game.websocket.drop(0);
  game.step();
  expect(r.ws.readyState).toBe("connecting");
  r.ws.close();
  expect(r.ws.readyState).toBe("closed");
  stepSeconds(10);
  expect(game.websocket.connections().length).toBe(1);

  r = run("wss://game.example.com/giveup");
  game.step();
  game.websocket.refuseNext(100);
  game.websocket.drop(0);
  for (let i = 0; i < 30; i++) stepSeconds(2);
  expect(r.ws.readyState).toBe("closed");
  expect(game.websocket.connections().length).toBe(5);  // the first try and four reconnects
  expect(r.log.filter((e) => e === "close:true").length).toBe(4);
  expect(r.log.filter((e) => e === "close:false").length).toBe(1);
});

test("a handler of close can stop the reconnect", () => {
  const { ws, log } = run("wss://game.example.com/stop");
  ws.on("close", () => ws.close());
  game.step();
  game.websocket.drop(0);
  game.step();
  expect(ws.readyState).toBe("closed");
  expect(log.filter((e) => typeof e === "object").length).toBe(0);
  stepSeconds(10);
  expect(game.websocket.connections().length).toBe(1);
});

test("the options of reconnect are checked", () => {
  game.websocket.reset();
  const url = "wss://game.example.com/x";
  expect(() => websocket.connect(url, { reconnect: { maxAtempts: 3 } })).toThrow("did you mean 'maxAttempts'");
  expect(() => websocket.connect(url, { reconnect: { minDelay: 0 } })).toThrow("reconnect.minDelay");
  expect(() => websocket.connect(url, { reconnect: { minDelay: 5, maxDelay: 1 } })).toThrow("reconnect.maxDelay");
  expect(() => websocket.connect(url, { reconnect: { jitter: 2 } })).toThrow("reconnect.jitter");
  expect(() => websocket.connect(url, { reconnect: "yes" })).toThrow("true, false or an object");
  expect(game.websocket.connections().length).toBe(0);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/reconnect.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 5);
}

TEST_CASE("websocket api: a mistake in the call throws at once and says what to change") {
    TestHost h("ws_mistakes", settings());
    h.file("tests/mistakes.test.js", R"(
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

test("hosts and schemes", () => {
  game.websocket.reset();
  expect(() => websocket.connect("wss://other.example.com/x")).toThrow("not declared");
  expect(() => websocket.connect("wss://other.example.com/x")).toThrow('websocket.connect("wss://other.example.com/x")');
  expect(() => websocket.connect("wss://game.example.co/x")).toThrow("Did you mean");
  expect(() => websocket.connect("wss://live.example.com/x")).toThrow("not declared");  // a wildcard covers subdomains only
  expect(() => websocket.connect("wss://a.live.example.com/x")).not.toThrow();
  expect(() => websocket.connect("https://game.example.com/x")).toThrow("wss");
  expect(() => websocket.connect("wss://user:pw@game.example.com/")).toThrow("user name or password");
  expect(() => websocket.connect(42)).toThrow("url");
  expect(() => websocket.connect()).toThrow("url");
  expect(game.websocket.connections().length).toBe(1);  // only the one that was allowed
});

test("options", () => {
  game.websocket.reset();
  const url = "wss://game.example.com/x";
  expect(() => websocket.connect(url, { protocol: ["a"] })).toThrow("did you mean 'protocols'");
  expect(() => websocket.connect(url, "x")).toThrow("options must be an object");
  expect(() => websocket.connect(url, { protocols: "a" })).toThrow("array of strings");
  expect(() => websocket.connect(url, { headers: { A: 1 } })).toThrow("object of strings");
  expect(() => websocket.connect(url, { headers: { "Bad Name": "x" } })).toThrow();
  expect(() => websocket.connect(url, { headers: { A: "x\r\nB: y" } })).toThrow();
  expect(() => websocket.connect(url, { timeout: 0 })).toThrow("timeout");
  expect(game.websocket.connections().length).toBe(0);
});

test("events and close codes", () => {
  game.websocket.reset();
  const ws = websocket.connect("wss://game.example.com/x");
  expect(() => ws.on("mesage", () => {})).toThrow("did you mean 'message'");
  expect(() => ws.on("open", 5)).toThrow("must be a function");
  expect(() => ws.close(1005)).toThrow("1005");
  expect(() => ws.close(1000, "x".repeat(124))).toThrow("124");
  expect(ws.readyState).toBe("connecting");
  ws.close(3000, "ok");
  expect(ws.readyState).toBe("closing");
});

test("more than 32 connections at once are refused", () => {
  game.websocket.reset();
  for (let i = 0; i < 32; i++) websocket.connect("wss://game.example.com/" + i);
  expect(() => websocket.connect("wss://game.example.com/33")).toThrow("32");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/mistakes.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("websocket api: a game with no network section is told what to declare") {
    TestHost h("ws_undeclared");
    h.file("tests/none.test.js", R"(
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

test("no hosts declared", () => {
  expect(() => websocket.connect("wss://game.example.com/x")).toThrow("declares no network hosts");
  expect(() => websocket.connect("wss://game.example.com/x")).toThrow('"network": {"hosts": ["game.example.com"]}');
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/none.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("websocket api: a scene change closes every connection and drops what the old scene's server sends") {
    TestHost h("ws_scene", settings());
    h.file("scenes/level2.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("tests/scene.test.js", R"(
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

test("loading a scene ends the connections without an event", () => {
  game.websocket.reset();
  const log = [];
  const ws = websocket.connect("wss://game.example.com/room", { reconnect: true });
  ws.on("open", () => log.push("open"));
  ws.on("message", (e) => log.push("message:" + e.data));
  ws.on("close", () => log.push("close"));
  ws.on("reconnecting", () => log.push("reconnecting"));
  game.step();
  game.websocket.send(0, "before");
  game.step();
  expect(log).toEqual(["open", "message:before"]);

  game.websocket.send(0, "in flight");  // queued by the server, not yet seen by the game
  game.load("scenes/level2.scene.json");
  expect(ws.readyState).toBe("closed");
  expect(ws.send("x")).toBe(false);
  game.step();
  game.step(600);  // no reconnect either
  expect(log).toEqual(["open", "message:before"]);
  expect(game.websocket.connections().length).toBe(1);
  expect(game.websocket.connections()[0].closedByGame).toBe(true);
  expect(game.websocket.connections()[0].closeCode).toBe(1001);
});

test("a connection made in the new scene works", () => {
  game.websocket.reset();
  const ws = websocket.connect("wss://game.example.com/room2");
  const log = [];
  ws.on("message", (e) => log.push(e.data));
  game.step();
  game.websocket.send(0, "hi");
  game.step();
  expect(log).toEqual(["hi"]);
  game.load("scenes/level2.scene.json");
  const ws2 = websocket.connect("wss://game.example.com/room3");
  ws2.on("message", (e) => log.push("2:" + e.data));
  game.step();
  game.websocket.send(0, "stale");
  game.websocket.send(1, "fresh");
  game.step();
  expect(log).toEqual(["hi", "2:fresh"]);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/scene.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 2);
}

TEST_CASE("websocket api: a platform without a client fails the connection at the next frame, once") {
    TestHost h("ws_unavailable", settings());
    auto unavailable =
        make_unavailable_websocket_client("unavailable", "WebSocket client for testing lands in M98.2b/c/d");
    h.websocketOverride = unavailable.get();
    h.file("tests/unavailable.test.js", R"(
import { test, expect, game } from "factoria:test";
import { websocket } from "factoria";

test("supported is false and connect fails with an error and a close", () => {
  expect(websocket.supported).toBe(false);
  expect(websocket.backend).toBe("unavailable");
  expect(websocket.unsupportedReason).toContain("lands in M98.2b/c/d");
  const log = [];
  const ws = websocket.connect("wss://game.example.com/room", { reconnect: true });
  ws.on("error", (e) => log.push("error:" + e.message));
  ws.on("close", (e) => log.push("close:" + e.code + ":" + e.willReconnect));
  expect(ws.readyState).toBe("connecting");
  game.step();
  expect(log.length).toBe(2);
  expect(log[0]).toContain("lands in M98.2b/c/d");
  expect(log[1]).toBe("close:1006:false");
  expect(ws.readyState).toBe("closed");
  game.step(600);
  expect(log.length).toBe(2);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/unavailable.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
}
