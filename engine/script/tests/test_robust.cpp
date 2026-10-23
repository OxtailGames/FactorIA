// robust() in "factoria:test": a check runs under small repeatable perturbations (M26.21, CC/FB-0055).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("robust: nudges bodies by a repeatable amount, run 0 untouched, and reports the run that failed") {
    TestHost h("robust", Json::object());
    h.file("tests/robust.test.js", R"(
import { test, expect, robust, game } from "factoria:test";

const scene = { format: "factoria.scene/1", entities: [
  { id: "a", components: { Transform: { position: [1, 2, 3] } } },
  { id: "b", components: { Transform: { position: [5, 5, 5] } } } ] };

test("run 0 is exact, the others stay within the amount, and every test run nudges the same way", () => {
  const seen = [];
  robust((p) => {
    game.loadJson(scene);
    p.nudge("a");
    const a = game.find("a").position;
    seen.push([p.run, p.runs, a.x, a.y, a.z]);
    if (p.run === 0) expect([a.x, a.y, a.z]).toEqual([1, 2, 3]);
    else {
      expect(Math.abs(a.x - 1)).toBeLessThanOrEqual(0.01);
      expect(a.x === 1 && a.y === 2 && a.z === 3).toBe(false);
    }
    expect(game.find("b").position.x).toBe(5); // only the nudged entity moves
  }, { runs: 4, nudge: 0.01 });
  expect(seen.length).toBe(4);
  const again = [];
  robust((p) => { game.loadJson(scene); p.nudge(game.find("a")); const a = game.find("a").position; again.push([p.run, p.runs, a.x, a.y, a.z]); }, { runs: 4, nudge: 0.01 });
  expect(again).toEqual(seen);
});

test("a failing run is named, with a hint", () => {
  let message = "";
  try { robust((p) => { if (p.run === 2) throw new Error("fell off the bridge"); }, { runs: 3 }); } catch (e) { message = e.message; }
  expect(message).toContain("run 2 of 3 failed");
  expect(message).toContain("fell off the bridge");
  expect(message).toContain("not an exact frame count");
});

test("unknown options and a missing entity teach", () => {
  let m1 = "", m2 = "";
  try { robust(() => {}, { run: 3 }); } catch (e) { m1 = e.message; }
  expect(m1).toContain("did you mean 'runs'");
  try { robust((p) => p.nudge("nobody")); } catch (e) { m2 = e.message; }
  expect(m2).toContain("'nobody'");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/robust.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
