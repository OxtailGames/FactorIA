// Entity and scene lifetime: a destroyed entity is gone for lookups at once, scene.generation changes on every load.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

TEST_CASE("lifetime: find, findAll and entities skip an entity destroyed this frame; its id is free at once") {
    TestHost h("lifetime_find", Json::object());
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[
      {"id":"panel","name":"Panel","components":{"Transform":{}}}]})");
    h.file("tests/find.test.js", R"(
import { test, expect, game } from "factoria:test";
import { world } from "factoria";

test("destroy hides the entity from lookups at once", () => {
  game.load("scenes/main.scene.json");
  const old = world.find("panel");
  expect(old).not.toBeNull();
  old.destroy();
  expect(old.alive).toBe(true);                 // the handle works until the end of the frame
  expect(world.find("panel")).toBeNull();
  expect(world.findAll("Panel").length).toBe(0);
  expect(world.entities().some((e) => e.id === "panel")).toBe(false);
  const fresh = world.spawn({ id: "panel", name: "Panel", components: { Transform: {} } });
  expect(fresh.id).toBe("panel");               // no suffix: the id was free
  expect(world.find("panel").$h === fresh.$h || world.find("panel").id === "panel").toBe(true);
  expect(world.findAll("Panel").length).toBe(1);
  game.step(1);
  expect(old.alive).toBe(false);
  expect(world.find("panel").alive).toBe(true);
  expect(world.findAll("Panel").length).toBe(1);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/find.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}

TEST_CASE("lifetime: scene.generation changes on every load, a reload of the same scene included") {
    TestHost h("lifetime_generation", Json::object());
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("scenes/level2.scene.json", R"({"format":"factoria.scene/1","entities":[]})");
    h.file("tests/gen.test.js", R"(
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("generation counts the loads", () => {
  game.load("scenes/main.scene.json");
  const a = scene.generation;
  expect(typeof a).toBe("number");
  expect(scene.generation).toBe(a);             // steady while nothing loads
  game.step(3);
  expect(scene.generation).toBe(a);
  game.load("scenes/main.scene.json");          // the same scene again
  const b = scene.generation;
  expect(scene.current).toBe("scenes/main.scene.json");
  expect(b).toBeGreaterThan(a);
  scene.reload();                               // deferred to the end of the frame
  expect(scene.generation).toBe(b);
  game.step(1);
  const c = scene.generation;
  expect(c).toBeGreaterThan(b);
  scene.load("scenes/level2.scene.json");
  game.step(1);
  expect(scene.generation).toBeGreaterThan(c);
});

test("a result of an earlier load is told apart from the scene itself", () => {
  game.load("scenes/main.scene.json");
  const gen = scene.generation;
  let applied = false;
  Promise.resolve().then(() => { if (scene.generation === gen) applied = true; });
  game.load("scenes/main.scene.json");          // reloaded before the promise job ran
  game.step(1);
  expect(applied).toBe(false);
});
)");
    REQUIRE(h.start());
    TestReport rep = h.scripts.run_tests({"tests/gen.test.js"});
    MESSAGE(rep.summary());
    CHECK(rep.ok());
}
