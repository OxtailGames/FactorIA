// game.today() / game.setDate and the app lifecycle events (suspend, resume, focus, blur, pauseOnSuspend).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("date: game.today() defaults to the fixed date, game.setDate seeds a daily run and resets per test") {
    TestHost h("calendar_date", Json::object());
    h.file("tests/date.test.js", R"(
import { test, expect, game } from "factoria:test";
import { game as g } from "factoria";

function dailySeed(iso) {
  let s = 0;
  for (const c of iso) s = (s * 31 + c.charCodeAt(0)) >>> 0;
  return s;
}

test("fixed default", () => {
  const t = g.today();
  expect(t.iso).toBe("2026-01-01");
  expect(t.year).toBe(2026);
  expect(t.month).toBe(1);
  expect(t.day).toBe(1);
  expect(t.weekday).toBe(4);
  expect(t.utcOffsetMinutes).toBe(0);
});

test("setDate drives the daily seed", () => {
  game.setDate("2026-03-14");
  const a = dailySeed(g.today().iso);
  expect(g.today().weekday).toBe(6);
  game.setDate("2026-03-15");
  const b = dailySeed(g.today().iso);
  expect(a === b).toBe(false);
  game.setDate("2026-03-14");
  expect(dailySeed(g.today().iso)).toBe(a);
});

test("date resets between tests", () => {
  expect(g.today().iso).toBe("2026-01-01");
});

test("impossible dates teach", () => {
  expect(() => game.setDate("2026-02-29")).toThrow("not a real date");
  expect(() => game.setDate("tomorrow")).toThrow("YYYY-MM-DD");
  game.setDate("2028-02-29");
  expect(g.today().iso).toBe("2028-02-29");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/date.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("lifecycle: suspend/resume/focus/blur events, a pause menu opened by suspend, pauseOnSuspend") {
    TestHost h("lifecycle", Json::object());
    h.file("tests/life.test.js", R"(
import { test, expect, game } from "factoria:test";
import { game as g, time } from "factoria";

test("events fire and game.focused follows", () => {
  const seen = [];
  g.on("suspend", () => seen.push("suspend"));
  g.on("resume", () => seen.push("resume"));
  g.on("blur", () => seen.push("blur"));
  g.on("focus", () => seen.push("focus"));
  expect(g.focused).toBe(true);
  game.blur();
  expect(g.focused).toBe(false);
  game.focus();
  expect(g.focused).toBe(true);
  game.suspend();
  game.resume();
  expect(seen.join(",")).toBe("blur,focus,suspend,resume");
});

test("suspend freezes the game and resume restores it", () => {
  expect(g.paused).toBe(false);
  game.suspend();
  expect(time.scale).toBe(0);
  game.resume();
  expect(time.scale).toBe(1);
});

test("a handler can open its own pause menu, which outlives resume", () => {
  let menu = false;
  g.on("suspend", () => { menu = true; g.paused = true; });
  game.suspend();
  game.resume();
  expect(menu).toBe(true);
  expect(g.paused).toBe(true);
  g.paused = false;
});

test("unknown event names are rejected with a suggestion", () => {
  expect(() => g.on("suspnd", () => {})).toThrow("did you mean");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/life.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
}

TEST_CASE("lifecycle: pauseOnSuspend false keeps the game running") {
    TestHost h("lifecycle_off", Json::object({{"pauseOnSuspend", false}}));
    h.file("tests/life.test.js", R"(
import { test, expect, game } from "factoria:test";
import { time } from "factoria";

test("no freeze", () => {
  game.suspend();
  expect(time.scale).toBe(1);
  game.resume();
  expect(time.scale).toBe(1);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/life.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
}
