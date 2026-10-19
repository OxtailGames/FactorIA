// Array-like vectors and colours read from components, game.screenSize, and when a promise rejection counts as unhandled.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("script values: vec2, vec4 and colour fields are array-like and keep their named parts") {
    TestHost h("values_arraylike");
    h.file("tests/values.test.js", R"(
import { test, expect } from "factoria:test";
import { world as w, vec2, color } from "factoria";

test("indexing, spread, destructuring, for...of and Array.from", () => {
  const e = w.spawn({ id: "p", components: {
    Transform: {}, Panel: { padding: [1, 2, 3, 4], size: [30, 40] }, Shape2D: { color: [0.25, 0.5, 0.75, 1] } } });
  const pad = e.get("Panel").padding, size = e.get("Panel").size, col = e.get("Shape2D").color;
  expect(pad[0]).toBe(1); expect(pad[3]).toBe(4); expect(size[1]).toBe(40);
  expect([...pad]).toEqual([1, 2, 3, 4]);
  expect([...size]).toEqual([30, 40]);
  expect(Array.from(col)).toEqual([0.25, 0.5, 0.75, 1]);
  const [l, t, r, b] = pad; expect(l + t + r + b).toBe(10);
  const [x, y] = size; expect(x * y).toBe(1200);
  let sum = 0; for (const c of col) sum += c; expect(sum).toBe(2.5);
  expect(col.length).toBe(4);
  expect(pad.x).toBe(1); expect(pad.w).toBe(4); expect(size.y).toBe(40); expect(col.g).toBe(0.5);
  col[1] = 1; expect(col.g).toBe(1);
  expect([...vec2(5, 6)]).toEqual([5, 6]);
  expect([...color("#ff0000")]).toEqual([1, 0, 0, 1]);
  expect(size.length()).toBeCloseTo(50);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/values.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 1);
}

TEST_CASE("script values: game.screenSize follows the design size") {
    TestHost h("values_screen");
    h.proj["display"] = Json::object({{"width", 800}, {"height", 600}});
    h.file("tests/screen.test.js", R"(
import { test, expect } from "factoria:test";
import { game, screen } from "factoria";
test("reads", () => { expect([...game.screenSize]).toEqual([800, 600]); expect(screen.size.x).toBe(800); });
)");
    REQUIRE(h.start());
    CHECK(h.scripts.run_tests({"tests/screen.test.js"}).ok());
    h.proj["display"] = Json::object({{"width", 1024}, {"height", 768}});
    h.file("tests/screen2.test.js", R"(
import { test, expect } from "factoria:test";
import { game } from "factoria";
test("reads", () => { expect([...game.screenSize]).toEqual([1024, 768]); });
)");
    CHECK(h.scripts.run_tests({"tests/screen2.test.js"}).ok());
}

namespace {
Json store() { return Json::parse(R"({"platform": {"achievements": [{"id": "first_win", "name": "First win"}]}})"); }
}

TEST_CASE("script values: a rejection a later microtask handles is not reported, a real one is, once") {
    TestHost h("values_reject", store());
    h.file("tests/handled.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";
test("then(store call).catch() logs nothing", async () => {
  game.platform.set({ signedIn: false });
  let chain = Promise.resolve();
  chain = chain.then(() => platform.achievements.unlock("first_win")).catch(() => {});
  await chain;
  await Promise.resolve();
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/handled.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(h.scripts.errors().empty());

    h.file("tests/real.test.js", R"(
import { test, expect, game } from "factoria:test";
import { platform } from "factoria";
test("nobody handles it", async () => {
  game.platform.set({ signedIn: false });
  platform.achievements.unlock("first_win");
  await Promise.resolve();
});
)");
    h.scripts.run_tests({"tests/real.test.js"});
    REQUIRE(h.scripts.errors().size() == 1);
    const std::string text = h.scripts.errors()[0].to_string();
    CHECK(text.find("unhandled promise rejection") != std::string::npos);
    CHECK(text.find("unhandled promise rejection", text.find("unhandled promise rejection") + 1) == std::string::npos);
}
