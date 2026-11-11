// M100.2: a test fails when the game fails. A script error (a callback, an event, a module's top level) or an engine ERROR logged
// while a test runs fails it, with the first error as its message; console.error is not an error; game.expectErrors() and the
// expectErrors option say that a test is about an error, and an expected error that never comes fails too.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

const char* kScene = R"({ "format": "factoria.scene/1", "entities": [
  { "id": "bomb", "components": { "Script": { "path": "scripts/bomb.js" } } } ] })";

const char* kBomb = R"JS(
import { Behaviour, audio } from "factoria";
export default class Bomb extends Behaviour {
  onUpdate() { if (globalThis.armed) throw new Error("bomb went off"); }
}
)JS";

bool contains(const std::string& s, const char* part) { return s.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("test errors: a throwing onUpdate fails the test that steps it, with the error as the message") {
    TestHost h("testerr_update");
    h.file("scripts/bomb.js", kBomb);
    h.file("scenes/main.scene.json", kScene);
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
test("a quiet step passes", () => {
  game.load("scenes/main.scene.json");
  game.step(2);
  expect(1 + 1).toBe(2);
});
test("armed bomb", () => {
  game.load("scenes/main.scene.json");
  globalThis.armed = true;
  game.step(2);
  expect(1 + 1).toBe(2);   // every assertion passes: the game still failed
});
test("armed bomb again", () => {
  game.load("scenes/main.scene.json");
  game.step(1);
  expect(1 + 1).toBe(2);
});
test("disarmed afterwards", () => {
  globalThis.armed = false;
  game.load("scenes/main.scene.json");
  game.step(2);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    REQUIRE(rep.cases.size() == 4);
    CHECK(rep.cases[0].passed);
    CHECK_FALSE(rep.cases[1].passed);
    CHECK(rep.cases[1].loggedError);
    CHECK(contains(rep.cases[1].message, "bomb went off"));
    CHECK(contains(rep.cases[1].message, "scripts/bomb.js"));
    // The same error again in the next test is not hidden by the engine's "log once".
    CHECK_FALSE(rep.cases[2].passed);
    CHECK(contains(rep.cases[2].message, "bomb went off"));
    CHECK(rep.cases[3].passed);
    CHECK_FALSE(rep.ok());
    CHECK(contains(rep.summary(), "2 passed, 2 failed (2 because the game logged an error"));
    CHECK(rep.to_json()["cases"][1]["loggedError"].get<bool>());
}

TEST_CASE("test errors: a missing audio file is an engine error that fails the test") {
    TestHost h("testerr_audio");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { audio } from "factoria";
test("plays a sound that is not there", () => {
  audio.play("assets/sfx/nope.wav");
  expect(1).toBe(1);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    REQUIRE(rep.cases.size() == 1);
    CHECK_FALSE(rep.cases[0].passed);
    CHECK(rep.cases[0].loggedError);
    CHECK(contains(rep.cases[0].message, "nope.wav"));
    CHECK(contains(rep.cases[0].message, "(audio)"));
}

TEST_CASE("test errors: console.error and console.assert are not errors") {
    TestHost h("testerr_console");
    h.file("tests/t.test.js", R"JS(
import { test, expect } from "factoria:test";
test("logs with console.error", () => {
  console.error("this is the game's own message", { a: 1 });
  console.assert(false, "and an assertion message");
  expect(1).toBe(1);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    REQUIRE(rep.cases.size() == 1);
    CHECK_MESSAGE(rep.cases[0].passed, rep.cases[0].message);
    CHECK(rep.ok());
}

TEST_CASE("test errors: expected errors pass, an expected error that never comes fails, an unexpected one still fails") {
    TestHost h("testerr_expect");
    h.file("scripts/bomb.js", kBomb);
    h.file("scenes/main.scene.json", kScene);
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { audio } from "factoria";
test("game.expectErrors with a regexp", () => {
  game.expectErrors(/bomb went/);
  game.load("scenes/main.scene.json");
  globalThis.armed = true;
  game.step(1);
  globalThis.armed = false;
});
test("the option, with a string", () => {
  game.load("scenes/main.scene.json");
  globalThis.armed = true;
  game.step(1);
  globalThis.armed = false;
}, { expectErrors: ["went off"] });
test("expected but never logged", () => {
  game.expectErrors(/never happens/);
  game.load("scenes/main.scene.json");
  game.step(1);
});
test("expected one error, another one comes", () => {
  game.expectErrors(/bomb went/);
  game.load("scenes/main.scene.json");
  globalThis.armed = true;
  game.step(1);
  globalThis.armed = false;
  audio.play("assets/sfx/other.wav");
});
test("an assertion that fails is reported with its own message", () => {
  game.expectErrors(/never happens/);
  expect(1).toBe(2);
});
test("a bad pattern teaches", () => {
  expect(() => game.expectErrors(42)).toThrow("regular expressions or non-empty strings");
  expect(() => game.expectErrors()).toThrow("at least one");
});
test("a bad option teaches", () => {
  expect(() => test("x", () => {}, { expectError: [] })).toThrow("unknown option 'expectError'");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    REQUIRE(rep.cases.size() == 7);
    CHECK_MESSAGE(rep.cases[0].passed, rep.cases[0].message);
    CHECK_MESSAGE(rep.cases[1].passed, rep.cases[1].message);
    CHECK_FALSE(rep.cases[2].passed);
    CHECK(rep.cases[2].loggedError);
    CHECK(contains(rep.cases[2].message, "/never happens/"));
    CHECK(contains(rep.cases[2].message, "never logged"));
    CHECK_FALSE(rep.cases[3].passed);
    CHECK(contains(rep.cases[3].message, "other.wav"));
    CHECK_FALSE(contains(rep.cases[3].message, "bomb went off\n"));
    CHECK_FALSE(rep.cases[4].passed);
    CHECK(contains(rep.cases[4].message, "expected: 2"));
    CHECK_FALSE(rep.cases[4].loggedError);  // the assertion is the failure; the expectation of a test that threw is not held against it
    CHECK_MESSAGE(rep.cases[5].passed, rep.cases[5].message);
    CHECK_MESSAGE(rep.cases[6].passed, rep.cases[6].message);
}

TEST_CASE("test errors: an error in a module's top level fails the test that loads it") {
    TestHost h("testerr_toplevel");
    h.file("scripts/bad.js", R"JS(
import { Behaviour } from "factoria";
throw new Error("top level exploded");
export default class Bad extends Behaviour {}
)JS");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
test("loads a scene whose script cannot load", () => {
  game.loadJson({ format: "factoria.scene/1", entities: [{ id: "b", components: { Script: { path: "scripts/bad.js" } } }] });
  game.step(1);
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    REQUIRE(rep.cases.size() == 1);
    CHECK_FALSE(rep.cases[0].passed);
    CHECK(contains(rep.cases[0].message, "top level exploded"));
}
