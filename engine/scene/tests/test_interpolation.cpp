// fa/scene/interpolation.h: the blend between the last two fixed steps, without an engine around it.
#include <doctest.h>

#include <cmath>
#include <string>
#include <tuple>

#include "fa/scene/camera_geometry.h"
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

TEST_CASE("interp_blend: position and scale lerp, rotation blends, past half a turn per step it snaps") {
    Transform a, b;
    a.position = {0, 10, 0};
    b.position = {10, 20, 4};
    a.scale = {1, 1, 1};
    b.scale = {3, 5, 1};
    a.rotation = {0, 0, 170};
    b.rotation = {0, 0, 190};
    const Transform m = interp_blend(a, b, 0.25f);
    CHECK(m.position.x == doctest::Approx(2.5f));
    CHECK(m.position.y == doctest::Approx(12.5f));
    CHECK(m.position.z == doctest::Approx(1.0f));
    CHECK(m.scale.x == doctest::Approx(1.5f));
    CHECK(m.scale.y == doctest::Approx(2.0f));
    CHECK(m.rotation.z == doctest::Approx(175.0f));  // the 2D case blends the angle itself
    CHECK(m.rotation.x == 0.0f);
    // A rotation that did not change is kept exactly.
    b.rotation = a.rotation;
    CHECK(interp_blend(a, b, 0.3f).rotation.z == 170.0f);
    // A 3D turn blends the quaternions.
    a.rotation = {0, 0, 0};
    b.rotation = {0, 90, 0};
    CHECK(interp_blend(a, b, 0.5f).rotation.y == doctest::Approx(45.0f).epsilon(0.01));
    // More than 180 degrees on an axis in one step (a fast spin, a wrap from 359 to 1) cannot be told from a short turn the
    // other way: the blend keeps the latest rotation.
    a.rotation = {0, 0, 0};
    b.rotation = {0, 0, 400};
    CHECK(interp_blend(a, b, 0.5f).rotation.z == 400.0f);
    a.rotation = {0, 0, 350};
    b.rotation = {0, 0, 10};
    CHECK(interp_blend(a, b, 0.5f).rotation.z == 10.0f);
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

TEST_CASE("interpolation: scripts, UI and picking see the real camera pose whatever alpha is") {
    struct Answer {
        Vec3 world;
        Vec2 screen;
        float geometryX, drawnGeometryX;
    };
    auto answers = [](double alpha) {
        Fixture f;
        Entity cam = f.w.create("cam", "cam");
        f.w.add<Camera>(cam).orthoSize = 90.0f;
        f.frame(0, 1.0);
        interp_begin_step(f.w);
        f.w.get<Transform>(cam)->position.x += 40.0f;
        interp_update(f.w, alpha, true);
        interp_update(f.w, alpha, false);
        const OrthoView v = ortho_view(f.w, Vec2{320, 180}, kNullEntity, nullptr);  // what scripts and UI hit tests use
        std::string warned;
        CameraTarget target;
        target.width = 320;
        target.height = 180;
        const CameraGeometry real = camera_geometry(f.w, cam, target, warned, nullptr, false, false);
        const CameraGeometry drawn = camera_geometry(f.w, cam, target, warned);
        return Answer{v.to_world({100, 50}), v.to_screen({12, 34, 0}), real.position.x, drawn.position.x};
    };
    const Answer half = answers(0.5), full = answers(1.0);
    CHECK(half.world.x == full.world.x);
    CHECK(half.world.y == full.world.y);
    CHECK(half.screen.x == full.screen.x);
    CHECK(half.screen.y == full.screen.y);
    CHECK(half.geometryX == doctest::Approx(40.0f));
    CHECK(full.geometryX == doctest::Approx(40.0f));
    CHECK(half.drawnGeometryX == doctest::Approx(20.0f));  // drawing is what blends
}

TEST_CASE("interpolation: the records are dense, one per interpolated entity, and a dead one is dropped") {
    Fixture f;
    Entity a = f.w.create("a", "a"), b = f.w.create("b", "b");
    f.frame(1, 0.5);
    CHECK(f.w.interp().records.size() == 3);
    f.w.destroy(f.box);
    f.w.flush();
    f.frame(0, 0.5);
    CHECK(f.w.interp().records.size() == 2);
    CHECK(f.w.interp().slots.size() >= 3);
    f.w.get<Transform>(b)->position.x += 1.0f;
    (void)a;
    f.frame(0, 0.5);
    CHECK(f.w.interp().records.size() == 2);
}
