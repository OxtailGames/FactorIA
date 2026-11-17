// input.rumble, input.stopRumble and input.gamepad(i).canRumble: what a script asks of a pad, the mistakes that teach, and
// what a headless run records (game.rumbles(), game.rumbleState()). The motors' clock is the engine's: it is tested with a
// real Engine in fa_test_runtime (pad_rumble_tests.cpp).
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("input.rumble is recorded by a headless run; canRumble follows the test pad; mistakes teach") {
    TestHost h("pad_rumble");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";

test("a pad with no motors ignores the request, a headless run records it", () => {
  expect(input.gamepad(0).canRumble).toBe(false);          // no pad in the slot
  game.gamepad(0).connect();
  expect(input.gamepad(0).canRumble).toBe(false);          // a test pad has none unless it says so
  input.rumble(0, 0.5, 0.25, 0.5);
  expect(game.rumbles()).toEqual([{ pad: 0, low: 0.5, high: 0.25, seconds: 0.5 }]);
  expect(game.rumbleState(0).low).toBe(0.5);               // Input shows what the game asked, the hardware layer ignores it
});

test("the record starts empty in the next test and the pad is gone", () => {
  expect(game.rumbles()).toEqual([]);
  expect(game.rumbleState(0)).toEqual({ low: 0, high: 0, seconds: 0 });
  expect(input.gamepad(0).canRumble).toBe(false);
});

test("a test pad that can rumble, strengths are clamped, stopRumble stops one pad or all", () => {
  game.gamepad(0).connect({ canRumble: true });
  game.gamepad(1).connect({ canRumble: true });
  expect(input.gamepad(0).canRumble).toBe(true);
  expect(input.gamepad(2).canRumble).toBe(false);
  input.rumble(0, 2, -1, 1);
  input.rumble(1, 0.25, 0.25, 2);
  expect(game.rumbles()[0]).toEqual({ pad: 0, low: 1, high: 0, seconds: 1 });
  expect(game.rumbleState(1)).toEqual({ low: 0.25, high: 0.25, seconds: 2 });
  input.stopRumble(0);
  expect(game.rumbleState(0).seconds).toBe(0);
  expect(game.rumbleState(1).seconds).toBe(2);
  input.stopRumble();
  expect(game.rumbleState(1).seconds).toBe(0);
  expect(game.rumbles().length).toBe(2 + 1 + 4);           // two requests, a stop of pad 0, a stop of every pad
  game.gamepad(1).disconnect();
  input.rumble(1, 1, 1, 1);
  expect(game.rumbleState(1).seconds).toBe(0);             // a pad that is not plugged in does not shake
  expect(input.gamepad(1).canRumble).toBe(false);
});

test("both strengths 0 is a stop; a test pad forgets canRumble when it disconnects", () => {
  game.gamepad(0).connect({ canRumble: true });
  input.rumble(0, 0.5, 0.5, 2);
  input.rumble(0, 0, 0, 2);
  expect(game.rumbleState(0)).toEqual({ low: 0, high: 0, seconds: 0 });
  expect(game.rumbles()[1]).toEqual({ pad: 0, low: 0, high: 0, seconds: 0 });
  game.gamepad(0).disconnect();
  game.gamepad(0).connect();
  expect(input.gamepad(0).canRumble).toBe(false);
  game.gamepad(0).connect({ canRumble: true });
  expect(input.gamepad(0).canRumble).toBe(true);
});

test("mistakes are explained and record nothing", () => {
  expect(() => input.rumble(4, 0.5, 0.5, 1)).toThrow("input.rumble: pad must be a whole number from 0 to 3");
  expect(() => input.rumble(0.5, 0.5, 0.5, 1)).toThrow("pad must be a whole number");
  expect(() => input.rumble(0, 0.5, 0.5, 0)).toThrow("seconds must be above 0 and up to 10");
  expect(() => input.rumble(0, 0.5, 0.5, 11)).toThrow("up to 10");
  expect(() => input.rumble(0, NaN, 0.5, 1)).toThrow("low must be a number from 0 to 1");
  expect(() => input.rumble(0, 0.5, 0.5)).toThrow("expects four numbers");
  expect(() => input.rumble("0", 0.5, 0.5, 1)).toThrow("but pad is");
  expect(() => input.stopRumble(7)).toThrow("0 to 3");
  expect(() => input.stopRumble(-1)).toThrow("0 to 3");      // -1 is no "all pads": leave the argument out
  expect(() => input.stopRumble("all")).toThrow("expects a pad number");
  expect(() => game.rumbleState(5)).toThrow("0 to 3");
  expect(() => game.gamepad(0).connect({ canRumble: "yes" })).toThrow("canRumble must be true or false");
  expect(game.rumbles()).toEqual([]);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("typescript declarations: rumble") {
    TestHost h("dts_pad_rumble");
    REQUIRE(h.start());
    const std::string dts = h.scripts.typescript_declarations();
    for (const char* needle :
         {"rumble(pad: number, low: number, high: number, seconds: number): void;", "stopRumble(pad?: number): void;",
          "readonly canRumble: boolean;", "rumbles(): { pad: number; low: number; high: number; seconds: number }[];",
          "rumbleState(pad?: number): { low: number; high: number; seconds: number };", "canRumble?: boolean"}) {
        INFO(needle);
        CHECK(dts.find(needle) != std::string::npos);
    }
}
