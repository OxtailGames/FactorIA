// What phones add to the scripts: screen.safeArea and its test profiles, the Back button (input.onBack) and vibration.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json display_800x600() { return Json::parse(R"({"display": {"width": 800, "height": 600}})"); }

}  // namespace

TEST_CASE("screen: the whole screen by default, a notched phone profile reports insets") {
    TestHost h("mobile_screen", display_800x600());
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { screen } from "factoria";

test("without a notch the safe area is the whole screen", () => {
  expect(screen.size.x).toBe(800);
  expect(screen.insets).toEqual({ left: 0, top: 0, right: 0, bottom: 0 });
  const a = screen.safeArea;
  expect([a.x, a.y, a.w, a.h]).toEqual([0, 0, 800, 600]);
});

test("a notched portrait phone leaves out the top and the bottom", () => {
  game.setSafeArea("phone-portrait");
  const i = screen.insets;
  expect(i.top).toBeGreaterThan(0);
  expect(i.bottom).toBeGreaterThan(0);
  expect(i.left).toBe(0);
  const a = screen.safeArea;                       // top-left corner, y down
  expect(a.x).toBe(0);
  expect(a.y).toBeCloseTo(i.top, 3);
  expect(a.w).toBe(800);
  expect(a.h).toBeCloseTo(600 - i.top - i.bottom, 3);
});

test("the insets of one test do not leak into the next", () => {
  expect(screen.insets.top).toBe(0);
  game.setSafeArea("phone-landscape");
  expect(screen.insets.left).toBeGreaterThan(0);
  expect(screen.insets.right).toBe(screen.insets.left);
  expect(screen.insets.bottom).toBeGreaterThan(0);
});

test("explicit insets, in design pixels; omitted sides are 0", () => {
  game.setSafeArea({ top: 40, left: 10 });
  expect(screen.insets).toEqual({ left: 10, top: 40, right: 0, bottom: 0 });
  const a = screen.safeArea;
  expect([a.x, a.y, a.w, a.h]).toEqual([10, 40, 790, 560]);
  game.setSafeArea("none");
  expect(screen.insets).toEqual({ left: 0, top: 0, right: 0, bottom: 0 });
});

test("mistakes are explained", () => {
  expect(() => game.setSafeArea("phone-portait")).toThrow("Did you mean 'phone-portrait'");
  expect(() => game.setSafeArea({ top: -5 })).toThrow("'top' must be a number of design pixels, 0 or more");
  expect(() => game.setSafeArea(12)).toThrow("expects { left, top, right, bottom }");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("input.onBack: the newest handler first, false passes it on, the first other answer consumes it") {
    TestHost h("mobile_back_consumed");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";

test("a handler that closes something consumes Back: the game stays", () => {
  const log = [];
  input.onBack(() => { log.push("menu"); return true; });
  game.pressBack();
  game.step(1);
  expect(log).toEqual(["menu"]);
  game.step(1);
  expect(log).toEqual(["menu"]);                   // one press, one call
});

test("handlers run newest first; false asks the next one", () => {
  const log = [];
  input.onBack(() => { log.push("screen"); return true; });
  input.onBack(() => { log.push("popup"); return false; });
  game.pressBack();
  game.step(1);
  expect(log).toEqual(["popup", "screen"]);
});

test("returning nothing consumes it too, and the remover works", () => {
  const log = [];
  const off = input.onBack(() => { log.push("a"); });
  input.onBack(() => { log.push("b"); });
  game.pressBack(); game.step(1);
  expect(log).toEqual(["b"]);                      // b consumed it: a was not asked
  off();
  game.pressBack(); game.step(1);
  expect(log).toEqual(["b", "b"]);
});

test("a handler that throws is reported and still consumes", () => {
  input.onBack(() => { throw new Error("boom"); });
  game.pressBack();
  game.step(1);
});

test("bad arguments teach", () => {
  expect(() => input.onBack("close")).toThrow("input.onBack(fn) expects a function");
});

test("handlers end with the scene", () => {
  const log = [];
  input.onBack(() => { log.push("old"); return true; });
  game.loadJson({ format: "factoria.scene/1", entities: [] });
  game.pressBack();
  game.step(1);
  expect(log).toEqual([]);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("Back leaves the game when no handler consumes it") {
    SUBCASE("no handler") {
        TestHost h("mobile_back_none");
        h.file("tests/t.test.js", R"JS(
import { test, game } from "factoria:test";
test("Back with nobody listening", () => { game.pressBack(); game.step(1); });
)JS");
        REQUIRE(h.start());
        CHECK_FALSE(h.quitRequested);
        CHECK(h.scripts.run_tests({"tests/t.test.js"}).ok());
        CHECK(h.quitRequested);
    }
    SUBCASE("every handler passes") {
        TestHost h("mobile_back_pass");
        h.file("tests/t.test.js", R"JS(
import { test, game } from "factoria:test";
import { input } from "factoria";
test("Back with a handler that has nothing to close", () => { input.onBack(() => false); game.pressBack(); game.step(1); });
)JS");
        REQUIRE(h.start());
        CHECK(h.scripts.run_tests({"tests/t.test.js"}).ok());
        CHECK(h.quitRequested);
    }
    SUBCASE("a consuming handler keeps the game") {
        TestHost h("mobile_back_keep");
        h.file("tests/t.test.js", R"JS(
import { test, game } from "factoria:test";
import { input } from "factoria";
test("Back closes the menu", () => { input.onBack(() => true); game.pressBack(); game.step(1); });
)JS");
        REQUIRE(h.start());
        CHECK(h.scripts.run_tests({"tests/t.test.js"}).ok());
        CHECK_FALSE(h.quitRequested);
    }
    SUBCASE("nothing pressed, nothing happens") {
        TestHost h("mobile_back_idle");
        h.file("tests/t.test.js", R"JS(
import { test, game } from "factoria:test";
test("a quiet frame", () => { game.step(3); });
)JS");
        REQUIRE(h.start());
        CHECK(h.scripts.run_tests({"tests/t.test.js"}).ok());
        CHECK_FALSE(h.quitRequested);
    }
}

TEST_CASE("input.vibrate is recorded by a headless run and checked") {
    TestHost h("mobile_vibrate");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";

test("a pulse is recorded", () => {
  expect(game.vibrations()).toEqual([]);
  input.vibrate(0.05);
  input.vibrate();
  expect(game.vibrations()).toEqual([0.05, 0.1]);   // the default is a short buzz
});

test("the record starts empty in the next test", () => {
  expect(game.vibrations()).toEqual([]);
});

test("mistakes are explained", () => {
  expect(() => input.vibrate(0)).toThrow("input.vibrate(seconds) expects a number above 0 and up to 5");
  expect(() => input.vibrate(9)).toThrow("up to 5");
  expect(() => input.vibrate("long")).toThrow("but got");
  expect(game.vibrations()).toEqual([]);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("typescript declarations: screen, onBack, vibrate and the test helpers") {
    TestHost h("dts_mobile");
    REQUIRE(h.start());
    const std::string dts = h.scripts.typescript_declarations();
    for (const char* needle : {"export interface ScreenAPI {", "export const screen: ScreenAPI;", "readonly safeArea: Rect;",
                               "readonly insets: ScreenInsets;", "onBack(handler: () => boolean | void): () => void;",
                               "vibrate(seconds?: number): void;", "pressBack(): void;", "setSafeArea(insets:",
                               "vibrations(): number[];"}) {
        CAPTURE(needle);
        CHECK(dts.find(needle) != std::string::npos);
    }
}
