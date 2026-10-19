// game.paused remembers time.scale; the test game object has `paused` and rejects unknown members with a suggestion.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("pause: game.paused = false restores time.scale; the test game object reads it and rejects typos") {
    TestHost h("pause_scale", Json::object());
    h.file("tests/pause.test.js", R"(
import { test, expect, game } from "factoria:test";
import { time, game as g } from "factoria";

test("resume restores the scale", () => {
  time.scale = 0.5;
  g.paused = true;
  expect(time.scale).toBe(0);
  expect(game.paused).toBe(true);
  g.paused = false;
  expect(time.scale).toBe(0.5);
  expect(game.paused).toBe(false);
});

test("time.scale set while paused is what resume restores", () => {
  time.scale = 0.5;
  game.paused = true;
  time.scale = 2;
  expect(time.scale).toBe(0);
  game.paused = false;
  expect(time.scale).toBe(2);
});

test("an unknown member throws naming the right one", () => {
  expect(() => game.pasued).toThrow("paused");
  expect(() => game.pasued).toThrow("did you mean");
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/pause.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 3);
}
