// ui.scale (the interface scale) and the ui.on("scale") / ui.on("textScale") events.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json eval_ok(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    if (!r.ok()) FAIL(r.error().to_string());
    return *r;
}
std::string eval_err(TestHost& h, const char* code) {
    auto r = h.scripts.eval(code);
    return r.ok() ? std::string() : r.error().message;
}
}  // namespace

TEST_CASE("ui.scale: remembered, range-checked with a teaching error, and every screen rectangle follows it") {
    TestHost h("uiscale");
    REQUIRE(h.start());
    CHECK(eval_ok(h, "ui.scale").get<double>() == doctest::Approx(1.0));
    eval_ok(h, "world.spawn({id: 'p', components: {Transform: {position: [10, 20]}, Panel: {size: [100, 50], pivot: [0, 1]}}})");
    CHECK(eval_ok(h, "ui.rectOf('p').w").get<double>() == doctest::Approx(100));
    eval_ok(h, "ui.scale = 1.5");
    CHECK(eval_ok(h, "ui.scale").get<double>() == doctest::Approx(1.5));
    CHECK(h.w.ui_scale() == doctest::Approx(1.5));
    CHECK(eval_ok(h, "ui.rectOf('p').w").get<double>() == doctest::Approx(150));
    CHECK(eval_ok(h, "ui.rectOf('p').h").get<double>() == doctest::Approx(75));
    CHECK(eval_ok(h, "ui.rectOf('p').x").get<double>() == doctest::Approx(15));
    CHECK(eval_ok(h, "ui.rectOf('p').y").get<double>() == doctest::Approx(30));
    CHECK(eval_ok(h, "world.find('p').get('Panel').size.x").get<double>() == doctest::Approx(100));  // the authored size
    // measureText answers in UI units: a label of fontSize 10 is the same size at any ui.scale
    CHECK(eval_ok(h, "ui.measureText('abcd', { fontSize: 10, space: 'screen' }).width").get<double>() == doctest::Approx(24.0));
    // a value outside 0.5 .. 3 throws, says what is accepted and what to do, and changes nothing
    for (const char* bad : {"ui.scale = 5", "ui.scale = 0.1", "ui.scale = 'big'", "ui.scale = NaN"}) {
        INFO(bad);
        const std::string m = eval_err(h, bad);
        CHECK(m.find("0.5") != std::string::npos);
        CHECK(m.find("clamp") != std::string::npos);
    }
    CHECK(eval_ok(h, "ui.scale").get<double>() == doctest::Approx(1.5));
    for (double edge : {0.5, 3.0}) {
        eval_ok(h, ("ui.scale = " + std::to_string(edge)).c_str());
        CHECK(eval_ok(h, "ui.scale").get<double>() == doctest::Approx(edge));
    }
}

TEST_CASE("ui.on(\"scale\") and ui.on(\"textScale\") fire once per change, with the new and the previous value") {
    TestHost h("uiscaleevents");
    h.file("tests/events.test.js", R"(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";

test("scale: once per change, nothing when the value stays", () => {
  const seen = [];
  const off = ui.on("scale", (e) => seen.push(`${e.type}:${e.previous}>${e.value}`));
  ui.scale = 1.5;
  expect(seen.length).toBe(0); // delivered with the frame, like i18n.on("change")
  game.step(1);
  expect(seen).toEqual(["scale:1>1.5"]);
  ui.scale = 1.5; // already there
  game.step(1);
  expect(seen.length).toBe(1);
  ui.scale = 2;
  ui.scale = 0.75; // two changes in one frame: two events, in order
  game.step(1);
  expect(seen).toEqual(["scale:1>1.5", "scale:1.5>2", "scale:2>0.75"]);
  off();
  ui.scale = 1;
  game.step(1);
  expect(seen.length).toBe(3); // stopped listening
});

test("textScale: once per change, and it is not the scale event", () => {
  const text = [], scale = [];
  ui.on("textScale", (e) => text.push(`${e.previous}>${e.value}`));
  ui.on("scale", (e) => scale.push(e.value));
  ui.textScale = 2;
  ui.textScale = 2;
  game.step(1);
  expect(text).toEqual(["1>2"]);
  expect(scale.length).toBe(0);
  ui.scale = 1.25;
  game.step(1);
  expect(text.length).toBe(1);
  expect(scale).toEqual([1.25]);
});

test("neither event takes a target: they are about no widget", () => {
  expect(() => ui.on("scale", "play", () => {})).toThrow("takes no target");
  expect(() => ui.on("textScale", "play", () => {})).toThrow("takes no target");
  expect(() => ui.on("scal", () => {})).toThrow('did you mean "scale"');
});
)");
    h.file("tests/next.test.js", R"(
import { test, expect, game } from "factoria:test";
import { ui } from "factoria";

test("a new test file starts at the defaults and hears nothing of the last file's changes", () => {
  const seen = [];
  ui.on("scale", (e) => seen.push(e.value));
  ui.on("textScale", (e) => seen.push(e.value));
  game.step(2);
  expect(ui.scale).toBe(1);
  expect(ui.textScale).toBe(1);
  expect(seen.length).toBe(0);
});
)");
    REQUIRE(h.start());
    eval_ok(h, "ui.scale = 2");  // the game's value: it comes back after the run
    h.step_frames(2);
    TestReport rep = h.scripts.run_tests({"tests/events.test.js", "tests/next.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK(rep.passed == 4);
    CHECK(eval_ok(h, "ui.scale").get<double>() == doctest::Approx(2.0));
    CHECK(h.w.ui_scale() == doctest::Approx(2.0));
}
