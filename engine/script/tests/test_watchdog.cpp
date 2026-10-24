// The script watchdog: a callback stopped for running too long ends only itself.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json watchdog_scene(const Json& entities) {
    return Json::object({{"format", "factoria.scene/1"}, {"entities", entities}});
}

Json script_entity(const std::string& id, const std::string& path) {
    return Json::object({{"id", id}, {"components", Json::object({{"Script", Json::object({{"path", path}})}})}});
}

int count_errors(const ScriptSystem& s, const std::string& text) {
    int n = 0;
    for (const ScriptError& e : s.errors())
        if (e.message.find(text) != std::string::npos) ++n;
    return n;
}

}  // namespace

TEST_CASE("watchdog: a timer callback stopped for running too long does not stop every later script") {
    TestHost h("watchdog_timer");
    h.file("scripts/stuck.js", R"(
import { Behaviour } from "factoria";
export default class Stuck extends Behaviour {
  onStart() { this.after(0, () => { while (true) {} }); }
}
)");
    // Real work every frame, far below the limit: tens of thousands of loop iterations (QuickJS polls the watchdog
    // every few thousand).
    h.file("scripts/busy.js", R"(
import { Behaviour } from "factoria";
globalThis.frames = 0;
export default class Busy extends Behaviour {
  onUpdate() {
    let s = 0;
    for (let i = 0; i < 100000; i++) s += i;
    if (s > 0) globalThis.frames++;
  }
}
)");
    h.file("scenes/main.scene.json",
           watchdog_scene(Json::array({script_entity("stuck", "scripts/stuck.js"), script_entity("busy", "scripts/busy.js")})).dump());
    REQUIRE(h.start());
    h.scripts.set_callback_limit(0.2);
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(10);
    for (const ScriptError& e : h.scripts.errors()) MESSAGE(e.to_string());
    CHECK(count_errors(h.scripts, "took too long") == 1);
    auto frames = h.scripts.eval("frames");
    REQUIRE(frames.ok());
    CHECK(frames->get<int>() == 10);
}

// QuickJS-ng's Array.prototype.find polls the watchdog at the top of each step and, when stopped there, freed the
// previous step's element a second time: the object was freed while the array still held it (a use after free, or the
// GC aborting in gc_decref_child). The engine replaces find, findIndex, findLast and findLastIndex (quickjs_fixes.cpp).
TEST_CASE("watchdog: a script stopped inside Array.prototype.find leaves the array's objects alive") {
    TestHost h("watchdog_find");
    // Each behaviour spins in find() over fresh objects until the watchdog stops it. Where in a step the stop lands
    // depends on how many polls came before, so the behaviours vary the array length and add a call or not before and
    // inside the loop: some of them are stopped on find's own poll after its first step.
    h.file("scripts/finder.js", R"(
import { Behaviour } from "factoria";
globalThis.refs = [];
globalThis.keep = [];
globalThis.started = 0;
function noop() {}
export default class Finder extends Behaviour {
  onUpdate() {
    const v = globalThis.started++;
    const items = [];
    for (let i = 0; i < 16 + v; i++) {
      const o = { i };
      items.push(o);
      refs.push(new WeakRef(o));
    }
    keep.push(items);
    if (v & 1) noop();
    if (v & 2) {
      while (true) {
        items.find((o) => o === null);
        noop();
      }
    }
    while (true) items.find((o) => o === null);
  }
}
)");
    constexpr int kFinders = 12;
    Json entities = Json::array();
    for (int i = 0; i < kFinders; ++i) entities.push_back(script_entity("finder" + std::to_string(i), "scripts/finder.js"));
    h.file("scenes/main.scene.json", watchdog_scene(entities).dump());
    REQUIRE(h.start());
    h.scripts.set_callback_limit(0.02);
    h.load_scene_now("scenes/main.scene.json");
    h.step_frames(2);
    CHECK(count_errors(h.scripts, "took too long") == 1);  // one error per script file; every behaviour was stopped
    auto alive = h.scripts.eval("started === 12 && keep.length === 12 && refs.every((r) => typeof r.deref() === 'object')");
    REQUIRE(alive.ok());
    CHECK(alive->get<bool>());
}

TEST_CASE("Array.prototype.find and its variants keep the standard behaviour") {
    TestHost h("array_find");
    REQUIRE(h.start());
    auto r = h.scripts.eval(R"([
  [1, 2, 3].find((x) => x > 1),
  [1, 2, 3].findIndex((x) => x > 5),
  [1, 2, 3].findLast((x) => x < 3),
  [1, 2, 3].findLastIndex((x) => x < 3),
  [1, 2, 3].find((x) => x > 5) === undefined,
  [1, 2, 3].findLast((x) => x > 5) === undefined,
  [1, 2, 3].findLastIndex((x) => x > 5),
  Array.prototype.find.call({ length: 2, 0: "a", 1: "b" }, (x, i) => i === 1),
  [5].find(function () { return this.ok; }, { ok: true }),
  [7].findIndex((x, i, a) => x === 7 && i === 0 && a.length === 1),
  [, 1].findIndex((x) => x === undefined),
  (() => { const a = [1, 2]; return a.find((x, i) => { if (i === 0) a.push(3); return x === 3; }) === undefined; })(),
  (() => { try { [1].find(3); return false; } catch (e) { return e instanceof TypeError; } })(),
  (() => { try { Array.prototype.find.call(null, () => true); return false; } catch (e) { return e instanceof TypeError; } })(),
  Array.prototype.find.length === 1 && Array.prototype.findLastIndex.name === "findLastIndex",
  Object.getOwnPropertyDescriptor(Array.prototype, "findLast").enumerable === false,
])");
    REQUIRE(r.ok());
    CHECK(r->dump() == R"([2,-1,2,1,true,true,-1,"b",5,0,0,true,true,true,true,true])");
}
