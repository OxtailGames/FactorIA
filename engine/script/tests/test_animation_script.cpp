// tween() / ease and entity.animator (the Animator component's script side).
#include <doctest.h>

#include <fstream>
#include <sstream>

#include "fa_test_paths.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

Json ev(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    if (!r.ok()) FAIL(r.error().to_string());
    return *r;
}
std::string ev_err(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    return r.ok() ? std::string() : r.error().message;
}
double num(TestHost& h, const std::string& code) { return ev(h, code).get<double>(); }

std::string read_all(const std::string& rel) {
    std::ifstream f(std::string(FA_REPO_ROOT) + "/" + rel, std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

}  // namespace

TEST_CASE("tween: moves plain numbers with the fixed clock, easing and completion") {
    TestHost h("tween_basic");
    REQUIRE(h.start());
    ev(h, "globalThis.o = { x: 0, y: 10 }; globalThis.done = []; globalThis.t = tween(o, { x: 10, y: 0 }, { duration: 1, onComplete: () => done.push('c') });"
          "t.finished.then((v) => done.push('p:' + v));");
    h.step_frames(30);
    CHECK(num(h, "o.x") == doctest::Approx(5.0).epsilon(0.02));
    CHECK(num(h, "o.y") == doctest::Approx(5.0).epsilon(0.02));
    CHECK(num(h, "t.progress") == doctest::Approx(0.5).epsilon(0.02));
    h.step_frames(40);
    CHECK(num(h, "o.x") == 10.0);  // lands exactly on the end value
    CHECK(num(h, "o.y") == 0.0);
    CHECK(ev(h, "done.join(',')").get<std::string>() == "c,p:true");
    CHECK_FALSE(ev(h, "t.active").get<bool>());
}

TEST_CASE("tween: delay, repeat and yoyo") {
    TestHost h("tween_repeat");
    REQUIRE(h.start());
    ev(h, "globalThis.o = { x: 0 }; globalThis.t = tween(o, { x: 8 }, { duration: 0.5, delay: 0.25, repeat: 1, yoyo: true });");
    h.step_frames(9);                                           // 0.15 s: still waiting
    CHECK(num(h, "o.x") == 0.0);
    h.step_frames(30);                                          // 0.65 s: 0.4 s into the first play
    CHECK(num(h, "o.x") == doctest::Approx(6.4).epsilon(0.02));
    h.step_frames(24);                                          // 1.05 s: 0.8 s in = 0.3 s into the backwards play
    CHECK(num(h, "o.x") == doctest::Approx(3.2).epsilon(0.03));
    h.step_frames(30);                                          // over: yoyo with one repeat ends back at the start
    CHECK(num(h, "o.x") == 0.0);
    CHECK_FALSE(ev(h, "t.active").get<bool>());
}

TEST_CASE("tween: vectors and colors of components, chaining, cancel and pause with time.scale") {
    TestHost h("tween_components");
    REQUIRE(h.start());
    ev(h, "globalThis.e = world.spawn({ id: 'box', components: { Sprite: { color: [0, 0, 0, 1] } } });");
    ev(h, "tween(e.position, { x: 100, y: -50 }, { duration: 1 }); tween(e.get('Sprite'), { color: '#ff0000' }, { duration: 1 });");
    h.step_frames(30);
    CHECK(num(h, "e.position.x") == doctest::Approx(50.0).epsilon(0.02));
    CHECK(num(h, "e.get('Sprite').color.r") == doctest::Approx(0.5).epsilon(0.02));
    h.step_frames(40);
    CHECK(num(h, "e.position.y") == -50.0);
    CHECK(num(h, "e.get('Sprite').color.r") == 1.0);
    CHECK(num(h, "e.get('Sprite').color.a") == 1.0);  // channels the end value does not mention keep their value

    ev(h, "globalThis.L = []; globalThis.a = tween(e.position, { x: 0 }, { duration: 0.5, onComplete: () => L.push('a') });"
          "globalThis.b = a.next(e.position, { y: 0 }, { duration: 0.5, onComplete: () => L.push('b') });");
    h.step_frames(20);
    CHECK(num(h, "e.position.y") == -50.0);                     // b has not started
    h.step_frames(20);
    CHECK(ev(h, "L.join(',')").get<std::string>() == "a");
    ev(h, "time.scale = 0");
    const double y = num(h, "e.position.y");
    h.step_frames(30);
    CHECK(num(h, "e.position.y") == y);                         // paused with the game clock
    ev(h, "time.scale = 1");
    ev(h, "b.cancel()");
    h.step_frames(60);
    CHECK(ev(h, "L.join(',')").get<std::string>() == "a");      // a cancelled tween never completes
    CHECK_FALSE(ev(h, "b.active").get<bool>());
}

TEST_CASE("tween: a destroyed target ends its tween quietly; mistakes teach") {
    TestHost h("tween_errors");
    REQUIRE(h.start());
    ev(h, "globalThis.e = world.spawn({ id: 'box' }); globalThis.t = tween(e.position, { x: 10 }, { duration: 1 });");
    h.step_frames(5);
    ev(h, "e.destroy()");
    h.step_frames(5);
    CHECK_FALSE(ev(h, "t.active").get<bool>());
    CHECK(h.scripts.errors().empty());
    CHECK(ev_err(h, "tween({ x: 0 }, { x: 1 }, { ease: 'quadOutt' })").find("quadOut") != std::string::npos);
    CHECK(ev_err(h, "tween({ x: 0 }, { x: 1 }, { duration: -1 })").find("duration") != std::string::npos);
    CHECK(ev_err(h, "tween(0, 5, {})").find("onUpdate") != std::string::npos);
    ev(h, "globalThis.bad = tween({ posx: 0 }, { pos_x: 1 })");
    h.step_frames(2);                                           // the unknown property is reported when the tween starts
    CHECK_FALSE(h.scripts.errors().empty());
    CHECK(h.scripts.errors()[0].message.find("posx") != std::string::npos);
}

TEST_CASE("ease: every easing starts at 0, ends at 1 and keeps its known shape") {
    TestHost h("ease");
    REQUIRE(h.start());
    CHECK(ev(h, "Object.keys(ease).every((k) => Math.abs(ease[k](0)) < 1e-9 && Math.abs(ease[k](1) - 1) < 1e-9)").get<bool>());
    CHECK(num(h, "ease.quadOut(0.5)") == doctest::Approx(0.75));
    CHECK(num(h, "ease.quadInOut(0.25)") == doctest::Approx(0.125));
    CHECK(num(h, "ease.cubicIn(0.5)") == doctest::Approx(0.125));
    CHECK(num(h, "ease.sineInOut(0.5)") == doctest::Approx(0.5));
    CHECK(num(h, "ease.backOut(0.6)") > 1.0);                   // overshoots
    CHECK(num(h, "ease.bounceOut(0.5)") == doctest::Approx(0.765625));
    CHECK(num(h, "Object.keys(ease).length") == 31);
    // The numbers form: tween(from, to, { onUpdate }).
    ev(h, "globalThis.v = []; tween(0, 100, { duration: 0.5, ease: 'quadIn', onUpdate: (x) => v.push(x) });");
    h.step_frames(40);
    CHECK(num(h, "v[v.length - 1]") == 100.0);
    CHECK(num(h, "v[14]") == doctest::Approx(100.0 * 0.5 * 0.5).epsilon(0.03));  // frame 15 of 30 = half the time = a quarter of the way
}

TEST_CASE("entity.animator: play, parameters, events and a state machine from scripts") {
    TestHost h("anim_js");
    h.file("assets/models/rig.gltf", read_all("engine/render/tests/data/skinned_two_bone.gltf"));
    REQUIRE(h.start());
    ev(h, R"(globalThis.e = world.spawn({ id: 'hero', components: {
        MeshRenderer: { mesh: 'assets/models/rig.gltf' },
        Animator: { clip: 'Slide',
                    events: [{ clip: 'Bend', time: 0.5, name: 'half' }],
                    params: { speed: 0 },
                    states: { idle: { clip: 'Slide' }, run: { clip: 'Bend', onEnter: 'run_started' } },
                    transitions: [{ from: 'idle', to: 'run', when: 'speed > 1', fade: 0.1 }] } } });
        globalThis.L = [];
        world.on('half', (d, s) => L.push('half:' + d.id + ':' + s.id));
        e.animator.on('run_started', (d) => L.push('mine:' + d.state));
        world.on('anim.finished', (d) => L.push('fin:' + d.clip));)");
    h.step_frames(2);
    CHECK(ev(h, "e.animator.clips").dump() == R"(["Bend","Slide","Spline"])");
    CHECK(num(h, "e.animator.duration('Bend')") == 1.0);
    CHECK(ev(h, "e.animator.state").get<std::string>() == "idle");
    CHECK(num(h, "e.animator.time") > 0.0);
    CHECK(ev(h, "e.animator.get('speed')").get<int>() == 0);
    ev(h, "e.animator.set('speed', 3)");
    h.step_frames(2);
    CHECK(ev(h, "e.animator.state").get<std::string>() == "run");
    CHECK(ev(h, "e.animator.clip").get<std::string>() == "Bend");
    h.step_frames(70);                                          // more than one Bend loop at 60 steps per second
    const std::string log = ev(h, "L.join(',')").get<std::string>();
    CHECK(log.find("mine:run") != std::string::npos);
    CHECK(log.find("half:hero:hero") != std::string::npos);
    // play() with a bad clip name lists the clips; stop() returns to the bind pose.
    const std::string err = ev_err(h, "e.animator.play('Bnd')");
    CHECK(err.find("Bend") != std::string::npos);
    CHECK(ev_err(h, "e.animator.set('spead', 1)").find("speed") != std::string::npos);
    ev(h, "e.animator.play('Spline', 0)");
    CHECK(ev(h, "e.animator.clip").get<std::string>() == "Spline");
    ev(h, "e.animator.stop()");
    CHECK_FALSE(ev(h, "e.animator.playing").get<bool>());
    ev(h, "globalThis.cube = world.spawn({ id: 'cube', components: { MeshRenderer: {} } })");
    CHECK(ev_err(h, "cube.animator").find("Animator") != std::string::npos);
}
