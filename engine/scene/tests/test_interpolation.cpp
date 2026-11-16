// fa/scene/interpolation.h: the blend between the last two fixed steps, without an engine around it.
#include <doctest.h>

#include <cmath>

#include "fa/scene/camera_query.h"
#include "fa/scene/interpolation.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

// What Engine::frame does around the fixed steps: `steps` steps (each moves `mover` by +10 on x) and then the blend at alpha.
struct Fixture {
    World w;
    Entity box;
    Fixture() {
        ensure_builtin_components();
        w.interp().enabled = true;
        box = w.create("box", "box");
        w.add<Sprite>(box);
        interp_update(w, 1.0, true);  // the first frame: records appear
    }
    void step(Entity e, float dx) {
        interp_begin_step(w);
        w.get<Transform>(e)->position.x += dx;
    }
    void frame(int steps, double alpha, float dx = 10.0f) {
        for (int i = 0; i < steps; ++i) step(box, dx);
        interp_update(w, alpha, steps > 0);
        interp_update(w, alpha, false);  // the call before drawing
    }
    float drawn_x(Entity e) { return w.drawn_matrix(e).translation().x; }
};

}  // namespace

TEST_CASE("interp_alpha: the part of a step the frame is past, clamped to 0..1") {
    CHECK(interp_alpha(0.0, 1.0 / 60.0) == doctest::Approx(0.0));
    CHECK(interp_alpha(1.0 / 120.0, 1.0 / 60.0) == doctest::Approx(0.5));
    CHECK(interp_alpha(1.0, 1.0 / 60.0) == doctest::Approx(1.0));
    CHECK(interp_alpha(-1.0, 1.0 / 60.0) == doctest::Approx(0.0));
    CHECK(interp_alpha(0.5, 0.0) == doctest::Approx(1.0));
}

TEST_CASE("interp_blend: position and scale lerp, rotation takes the short way round") {
    Transform a, b;
    a.position = {0, 10, 0};
    b.position = {10, 20, 4};
    a.scale = {1, 1, 1};
    b.scale = {3, 5, 1};
    a.rotation = {0, 0, 350};
    b.rotation = {0, 0, 10};
    const Transform m = interp_blend(a, b, 0.25f);
    CHECK(m.position.x == doctest::Approx(2.5f));
    CHECK(m.position.y == doctest::Approx(12.5f));
    CHECK(m.position.z == doctest::Approx(1.0f));
    CHECK(m.scale.x == doctest::Approx(1.5f));
    CHECK(m.scale.y == doctest::Approx(2.0f));
    CHECK(m.rotation.z == doctest::Approx(-5.0f).epsilon(0.01));  // 350 -> 10 passes through 0, not through 180
    // A rotation that did not change is kept exactly.
    b.rotation = a.rotation;
    CHECK(interp_blend(a, b, 0.3f).rotation.z == 350.0f);
}

TEST_CASE("interpolation: the drawn pose is between the last two steps, the Transform stays the real one") {
    Fixture f;
    f.frame(1, 0.0);
    CHECK(f.drawn_x(f.box) == doctest::Approx(0.0f));  // alpha 0: still at the pose before the step
    f.frame(0, 0.5);
    CHECK(f.drawn_x(f.box) == doctest::Approx(5.0f));
    f.frame(0, 1.0);
    CHECK(f.drawn_x(f.box) == doctest::Approx(10.0f));
    CHECK(f.w.get<Transform>(f.box)->position.x == 10.0f);
    CHECK(f.w.world_matrix(f.box).translation().x == doctest::Approx(10.0f));  // simulation reads the real pose
    f.frame(1, 0.25);
    CHECK(f.drawn_x(f.box) == doctest::Approx(12.5f));
    CHECK(f.w.get<Transform>(f.box)->position.x == 20.0f);
}

TEST_CASE("interpolation: several steps in a frame blend the last two") {
    Fixture f;
    f.frame(3, 0.5);  // 0 -> 10 -> 20 -> 30: between 20 and 30
    CHECK(f.drawn_x(f.box) == doctest::Approx(25.0f));
}

TEST_CASE("interpolation: off by default draws exactly the Transform") {
    World w;
    ensure_builtin_components();
    Entity e = w.create("e", "e");
    for (int i = 0; i < 3; ++i) {
        interp_begin_step(w);
        w.get<Transform>(e)->position.x += 10.0f;
        interp_update(w, 0.5, true);
        interp_update(w, 0.5, false);
    }
    CHECK(w.interp().poseCount == 0);
    CHECK(w.interp().records.empty());
    CHECK(w.drawn_matrix(e).translation().x == 30.0f);
}

TEST_CASE("interpolation: the component overrides the project default") {
    Fixture f;
    Entity off = f.w.create("off", "off");
    f.w.add<Interpolation>(off).mode = InterpolationMode::Off;
    Entity inh = f.w.create("inh", "inh");
    f.w.add<Interpolation>(inh).mode = InterpolationMode::Inherit;
    f.frame(0, 1.0);
    interp_begin_step(f.w);
    for (Entity e : {f.box, off, inh}) f.w.get<Transform>(e)->position.x += 10.0f;
    interp_update(f.w, 0.5, true);
    interp_update(f.w, 0.5, false);
    CHECK(f.drawn_x(f.box) == doctest::Approx(5.0f));
    CHECK(f.drawn_x(inh) == doctest::Approx(5.0f));
    CHECK(f.drawn_x(off) == doctest::Approx(10.0f));
    // Project default off: only "on" entities are blended.
    f.w.interp().enabled = false;
    Entity on = f.w.create("on", "on");
    f.w.add<Interpolation>(on);  // default mode: on
    interp_update(f.w, 1.0, true);
    interp_begin_step(f.w);
    for (Entity e : {f.box, on}) f.w.get<Transform>(e)->position.x += 10.0f;
    interp_update(f.w, 0.5, true);
    interp_update(f.w, 0.5, false);
    CHECK(f.drawn_x(f.box) == doctest::Approx(20.0f));
    CHECK(f.drawn_x(on) == doctest::Approx(5.0f));
}

TEST_CASE("interpolation: a new entity, a teleport, a write outside the steps and a long jump are not smeared") {
    Fixture f;
    f.frame(1, 0.5);
    // A spawn during a step appears where it is.
    interp_begin_step(f.w);
    Entity spawned = f.w.create("s", "s");
    f.w.get<Transform>(spawned)->position.x = 100.0f;
    interp_update(f.w, 0.5, true);
    interp_update(f.w, 0.5, false);
    CHECK(f.drawn_x(spawned) == 100.0f);
    // The next step moves it: now it blends.
    interp_begin_step(f.w);
    f.w.get<Transform>(spawned)->position.x = 110.0f;
    interp_update(f.w, 0.5, true);
    CHECK(f.drawn_x(spawned) == doctest::Approx(105.0f));
    // Teleport inside a step.
    interp_begin_step(f.w);
    f.w.get<Transform>(spawned)->position.x = 500.0f;
    f.w.interp_teleport(spawned);
    interp_update(f.w, 0.5, true);
    CHECK(f.drawn_x(spawned) == 500.0f);
    // Written outside the fixed step (a script's update): drawn where it is, and the next step blends from there.
    f.w.get<Transform>(spawned)->position.x = 700.0f;
    interp_update(f.w, 0.5, false);
    CHECK(f.drawn_x(spawned) == 700.0f);
    interp_begin_step(f.w);
    f.w.get<Transform>(spawned)->position.x = 710.0f;
    interp_update(f.w, 0.5, true);
    CHECK(f.drawn_x(spawned) == doctest::Approx(705.0f));
    // A step that moves farther than snapDistance.
    f.w.interp().snapDistance = 50.0f;
    interp_begin_step(f.w);
    f.w.get<Transform>(spawned)->position.x = 900.0f;
    interp_update(f.w, 0.5, true);
    CHECK(f.drawn_x(spawned) == 900.0f);
    interp_begin_step(f.w);
    f.w.get<Transform>(spawned)->position.x = 910.0f;
    interp_update(f.w, 0.5, true);
    CHECK(f.drawn_x(spawned) == doctest::Approx(905.0f));
}

TEST_CASE("interpolation: children follow an interpolated parent and the cached world matrices stay real") {
    Fixture f;
    Entity child = f.w.create("child", "child");
    f.w.set_parent(child, f.box);
    f.w.get<Transform>(child)->position.x = 1.0f;
    f.frame(0, 1.0);
    f.frame(1, 0.5);
    CHECK(f.drawn_x(child) == doctest::Approx(6.0f));  // 5 + 1
    CHECK(f.w.world_matrix(child).translation().x == doctest::Approx(11.0f));
}

TEST_CASE("interpolation: a camera is viewed from its blended pose") {
    Fixture f;
    Entity cam = f.w.create("cam", "cam");
    f.w.add<Camera>(cam).orthoSize = 90.0f;
    f.frame(0, 1.0);
    interp_begin_step(f.w);
    f.w.get<Transform>(cam)->position.x += 40.0f;
    interp_update(f.w, 0.5, true);
    interp_update(f.w, 0.5, false);
    CHECK(f.w.drawn_matrix(cam).translation().x == doctest::Approx(20.0f));
    CHECK(f.w.world_matrix(cam).translation().x == doctest::Approx(40.0f));
}

TEST_CASE("interpolation: a scene clear forgets the records, a destroyed entity's slot is not blended for a new one") {
    Fixture f;
    f.frame(1, 0.5);
    CHECK(f.w.interp().poseCount > 0);
    f.w.destroy(f.box);
    f.w.flush();
    Entity again = f.w.create("again", "again");
    f.w.get<Transform>(again)->position.x = 7.0f;
    interp_update(f.w, 0.5, false);
    CHECK(f.drawn_x(again) == 7.0f);
    f.w.clear();
    CHECK(f.w.interp().records.empty());
    CHECK(f.w.interp().enabled);  // a setting, not a scene's
}
