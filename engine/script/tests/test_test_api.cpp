// The `factoria:test` calls added for M26.11: mouse buttons and wheel, quitRequested, setSystemLanguages and resetState.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json settings() {
    return Json::parse(R"({ "localization": { "defaultLanguage": "en", "languages": ["en", "es"] },
      "platform": { "products": [{"id": "remove_ads", "type": "nonConsumable", "title": "Remove ads", "price": 2.99}] } })");
}

void write_tables(TestHost& h) {
    h.file("locales/en.json", R"({ "$name": "English", "hi": "Hi" })");
    h.file("locales/es.json", R"({ "$name": "Español", "hi": "Hola" })");
}

}  // namespace

TEST_CASE("test api: mouseDown, mouseUp and wheel drive input.mouse") {
    TestHost h("testapi_mouse");
    h.file("scripts/zoom.js", R"JS(
import { Behaviour, input } from "factoria";
export default class Zoom extends Behaviour {
  seen = [];
  onUpdate() { this.seen.push(input.mouse.wheel); }
}
)JS");
    h.file("scenes/main.scene.json", R"({ "format": "factoria.scene/1", "entities": [
      { "id": "zoom", "components": { "Script": { "path": "scripts/zoom.js" } } } ] })");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { input } from "factoria";

test("a drag and a wheel notch", () => {
  game.mouseMove([100, 100]);
  game.mouseDown();
  game.step(1);
  expect(input.mouse.down("left")).toBe(true);
  game.mouseMove([140, 90]);
  game.step(1);
  expect(input.mouse.position.x).toBe(140);
  expect(input.mouse.down("left")).toBe(true);
  game.mouseUp();
  game.step(1);
  expect(input.mouse.down("left")).toBe(false);
  game.mouseDown("right");
  expect(input.mouse.down("right")).toBe(true);
  expect(input.mouse.down("left")).toBe(false);
  game.mouseUp("right");
});
test("a wheel notch reaches onUpdate of the next frame", () => {
  game.load("scenes/main.scene.json");
  game.wheel(-2);
  game.step(1);
  game.wheel(1);
  game.wheel(1);
  game.step(2);
  expect(game.find("zoom").behaviour.seen).toEqual([-2, 2, 0]);
});
test("bad arguments teach", () => {
  expect(() => game.wheel("up")).toThrow("game.wheel(dy) expects a number");
  expect(() => game.mouseDown("side")).toThrow("unknown mouse button");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("test api: quitRequested records app.quit() and is cleared for each test") {
    TestHost h("testapi_quit");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { game as app } from "factoria";

test("quit only sets the flag", () => {
  expect(game.quitRequested).toBe(false);
  app.quit();
  expect(game.quitRequested).toBe(true);
  game.step(2); // the run is not stopped
});
test("the next test starts clean", () => { expect(game.quitRequested).toBe(false); game.step(1); });
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
    CHECK_FALSE(h.quitRequested);
}

TEST_CASE("test api: setSystemLanguages feeds i18n.systemLanguages and resets for each test") {
    TestHost h("testapi_lang", settings());
    write_tables(h);
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { i18n } from "factoria";

test("a Spanish device", () => {
  game.setSystemLanguages(["es-ES", "en"]);
  expect(i18n.systemLanguages).toEqual(["es-ES", "en"]);
});
test("reset", () => { expect(i18n.systemLanguages).toEqual([]); });
test("bad input teaches", () => {
  expect(() => game.setSystemLanguages("es")).toThrow("expects an array of language tags");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("test api: resetState clears storage and the fake store between tests of one file") {
    TestHost h("testapi_reset", settings());
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { storage, platform } from "factoria";

test("state accumulates in a file", async () => {
  storage.set("coins", 5);
  await platform.purchases.buy("remove_ads");
  expect(storage.get("coins")).toBe(5);
});
test("it is still there", async () => {
  expect(storage.get("coins")).toBe(5);
  expect((await platform.purchases.restore()).length).toBeGreaterThan(0);
});
test("resetState clears both", async () => {
  game.resetState();
  expect(storage.get("coins")).toBeUndefined();
  expect(await platform.purchases.restore()).toEqual([]);
});
test("only storage", async () => {
  storage.set("a", 1);
  await platform.purchases.buy("remove_ads");
  game.resetState({ storage: true, platform: false });
  expect(storage.get("a")).toBeUndefined();
  expect((await platform.purchases.restore()).length).toBeGreaterThan(0);
  game.resetState({ storage: false });
  expect(await platform.purchases.restore()).toEqual([]);
});
test("bad options teach", () => {
  expect(() => game.resetState({ storge: true })).toThrow("did you mean 'storage'");
  expect(() => game.resetState({ storage: 1 })).toThrow("must be true or false");
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("test api: scene.load from a test is deferred to the next frame, game.load is immediate") {
    TestHost h("testapi_sceneload");
    h.file("scenes/a.scene.json", R"({ "format": "factoria.scene/1", "entities": [ { "id": "a", "components": {} } ] })");
    h.file("scenes/b.scene.json", R"({ "format": "factoria.scene/1", "entities": [ { "id": "b", "components": {} } ] })");
    h.file("tests/t.test.js", R"JS(
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("game.load is immediate", () => {
  game.load("scenes/a.scene.json");
  expect(game.find("a")).toBeTruthy();
});
test("scene.load takes effect next frame", () => {
  game.load("scenes/a.scene.json");
  scene.load("scenes/b.scene.json");
  expect(game.find("a")).toBeTruthy();
  game.step(1);
  expect(game.find("b")).toBeTruthy();
});
)JS");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/t.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
