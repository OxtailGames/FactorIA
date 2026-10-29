// tween lifetime: a tween whose target or owner is gone never resumes the code that awaits it; tween.pauseAll,
// tween.timeScale, Tween.seek, Behaviour.tween and Behaviour.wait.
#include <doctest.h>

#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {
Json ev(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    if (!r.ok()) FAIL(r.error().to_string());
    return *r;
}
double num(TestHost& h, const std::string& code) { return ev(h, code).get<double>(); }
}  // namespace

TEST_CASE("tween: awaiting a tween whose entity is destroyed never resumes and raises no error") {
    TestHost h("tween_dropped_entity");
    REQUIRE(h.start());
    ev(h, "globalThis.e = world.spawn({ id: 'box' }); globalThis.L = [];"
          "globalThis.run = async () => { await tween(e.position, { x: 10 }, { duration: 1 }).finished; L.push('after'); e.position.x = 1; };"
          "globalThis.p = run(); globalThis.q = (async () => { const t = tween(e.position, { y: 4 }, { duration: 1 }); const ok = await t.finished; L.push('cancel:' + ok); })();"
          "globalThis.t2 = tween(e.position, { z: 1 }, { duration: 1 }); t2.finished.then((v) => L.push('t2:' + v)); 0");
    h.step_frames(5);
    ev(h, "e.destroy()");
    h.step_frames(90);
    CHECK(ev(h, "L.join(',')").get<std::string>() == "");  // nothing resumed
    CHECK_FALSE(ev(h, "t2.active").get<bool>());
    CHECK(h.scripts.errors().empty());
}

TEST_CASE("tween: an explicit cancel still settles finished with false") {
    TestHost h("tween_cancel_false");
    REQUIRE(h.start());
    ev(h, "globalThis.L = []; globalThis.o = { x: 0 }; globalThis.t = tween(o, { x: 1 }, { duration: 1 }); t.finished.then((v) => L.push(v)); 0");
    h.step_frames(3);
    ev(h, "t.cancel(); 0");
    h.step_frames(1);
    CHECK(ev(h, "L.join(',')").get<std::string>() == "false");
}

TEST_CASE("tween: a scene reload drops running tweens without settling them") {
    TestHost h("tween_dropped_scene");
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[{"id":"box","components":{"Transform":{}}}]})");
    REQUIRE(h.start());
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    ev(h, "globalThis.L = []; globalThis.o = { x: 0 };"
          "(async () => { await tween(o, { x: 1 }, { duration: 1 }).finished; L.push('resumed'); })(); 0");
    h.step_frames(3);
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(120);
    CHECK(ev(h, "L.length").get<int>() == 0);
    CHECK(h.scripts.errors().empty());
}

TEST_CASE("tween: pauseAll, resumeAll, timeScale and seek") {
    TestHost h("tween_global");
    REQUIRE(h.start());
    ev(h, "globalThis.o = { x: 0 }; globalThis.t = tween(o, { x: 10 }, { duration: 1 }); 0");
    h.step_frames(30);
    CHECK(num(h, "o.x") == doctest::Approx(5.0).epsilon(0.03));
    ev(h, "tween.pauseAll(); 0");
    CHECK(ev(h, "tween.paused").get<bool>());
    h.step_frames(30);
    CHECK(num(h, "o.x") == doctest::Approx(5.0).epsilon(0.03));
    ev(h, "o.x = 99; 0");
    h.step_frames(10);
    CHECK(num(h, "o.x") == 99.0);                               // a paused tween does not overwrite what was set
    ev(h, "tween.resumeAll(); tween.timeScale = 0.5; 0");
    h.step_frames(30);
    CHECK(num(h, "t.progress") == doctest::Approx(0.75).epsilon(0.03));  // 30 frames at half speed = 0.25 s
    CHECK(ev(h, "(() => { try { tween.timeScale = -1; return ''; } catch (e) { return e.message; } })()").get<std::string>().find(">= 0") != std::string::npos);
    ev(h, "tween.timeScale = 1; t.pause(); t.seek(0.2); 0");    // seek works on a paused tween, also backwards
    CHECK(num(h, "o.x") == doctest::Approx(2.0).epsilon(0.01));
    ev(h, "t.seek(0.8); 0");
    CHECK(num(h, "o.x") == doctest::Approx(8.0).epsilon(0.01));
    ev(h, "t.seek(5); 0");
    CHECK(num(h, "o.x") == 10.0);
    CHECK_FALSE(ev(h, "t.active").get<bool>());
    CHECK(ev(h, "(() => { try { t.seek(0); return ''; } catch (e) { return e.message; } })()").get<std::string>().find("complete") != std::string::npos);
}

TEST_CASE("Behaviour.tween and Behaviour.wait: dropped when the entity is destroyed") {
    TestHost h("tween_behaviour");
    h.file("scripts/walker.js", R"(
import { Behaviour } from "factoria";
export default class Walker extends Behaviour {
  async onStart() {
    await this.wait(0.5);
    globalThis.LOG.push("waited");
    await this.tween(this.entity.position, { x: 10 }, { duration: 0.5 }).finished;
    globalThis.LOG.push("moved");
    this.entity.position.x = 0;
  }
}
)");
    h.file("scenes/main.scene.json", R"({"format":"factoria.scene/1","entities":[
      {"id":"a","components":{"Transform":{},"Script":{"path":"scripts/walker.js"}}},
      {"id":"b","components":{"Transform":{},"Script":{"path":"scripts/walker.js"}}}]})");
    REQUIRE(h.start());
    ev(h, "globalThis.LOG = []; 0");
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    h.step_frames(36);                                          // 0.6 s: both waited, both tween
    CHECK(ev(h, "LOG.join(',')").get<std::string>() == "waited,waited");
    ev(h, "world.find('a').destroy(); 0");
    h.step_frames(60);
    CHECK(ev(h, "LOG.join(',')").get<std::string>() == "waited,waited,moved");  // only b finished
    CHECK(h.scripts.errors().empty());
    // wait() of an entity destroyed before it fires never resolves.
    ev(h, "globalThis.W = []; globalThis.c = world.spawn({ id: 'c' }); 0");
    CHECK(h.load_scene_now("scenes/main.scene.json").empty());
    ev(h, "world.find('b').destroy(); 0");
    h.step_frames(90);
    CHECK(h.scripts.errors().empty());
}
