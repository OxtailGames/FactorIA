// fa/scene/camera_geometry.h: the camera maths a run with no renderer answers with (CameraSet), the Parallax offset, and the live
// particles in the world hash.
#include <doctest.h>

#include <cmath>

#include "fa/scene/camera_geometry.h"
#include "fa/scene/components.h"
#include "fa/scene/particle_store.h"
#include "fa/scene/state_hash.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

CameraTarget target_1280x720() {
    CameraTarget t;
    t.width = 1280;
    t.height = 720;
    t.designWidth = 1280;
    t.designHeight = 720;
    return t;
}

Entity add_camera(World& w, const char* id, Vec2 pos, std::int32_t depth = 0) {
    const Entity e = w.create(id);
    w.add<Camera>(e).depth = depth;
    w.add<Transform>(e).position = {pos.x, pos.y, 0.0f};
    return e;
}

}  // namespace

TEST_CASE("camera set: empty until refreshed, then answers world <-> screen for the camera") {
    World w;
    const Entity cam = add_camera(w, "cam", {100, 50});
    CameraSet set;
    CHECK(set.all().empty());
    CHECK(set.cameras().empty());
    set.refresh(w, target_1280x720());
    REQUIRE(set.all().size() == 1);
    CHECK(set.cameras().front() == cam);
    // The camera's own position is the centre of the screen; +Y is up in the world and down on the screen.
    const Vec2 centre = set.world_to_screen({100, 50, 0});
    CHECK(centre.x == doctest::Approx(640.0f));
    CHECK(centre.y == doctest::Approx(360.0f));
    const Vec2 right = set.world_to_screen({110, 60, 0});
    CHECK(right.x == doctest::Approx(650.0f));
    CHECK(right.y == doctest::Approx(350.0f));
    const Vec3 back = set.screen_to_world({650, 350}, 0.0f);
    CHECK(back.x == doctest::Approx(110.0f));
    CHECK(back.y == doctest::Approx(60.0f));
    // The same call again gives the very same bits: a hash may depend on it.
    const Vec3 again = set.screen_to_world({650, 350}, 0.0f);
    CHECK(again.x == back.x);
    CHECK(again.y == back.y);
}

TEST_CASE("camera set: it is a snapshot, a moved camera is seen by the next refresh") {
    World w;
    const Entity cam = add_camera(w, "cam", {0, 0});
    CameraSet set;
    set.refresh(w, target_1280x720());
    w.get<Transform>(cam)->position.x = 40.0f;
    CHECK(set.screen_to_world({640, 360}, 0.0f).x == doctest::Approx(0.0f));  // as the frame began
    set.refresh(w, target_1280x720());
    CHECK(set.screen_to_world({640, 360}, 0.0f).x == doctest::Approx(40.0f));
}

TEST_CASE(
    "camera set: split screen picks the camera whose viewport holds the pointer; a camera being destroyed is skipped") {
    World w;
    const Entity left = add_camera(w, "left", {0, 0}, 0);
    const Entity right = add_camera(w, "right", {500, 0}, 1);
    w.get<Camera>(left)->viewport = {0, 0, 0.5f, 1};
    w.get<Camera>(right)->viewport = {0.5f, 0, 0.5f, 1};
    CameraSet set;
    set.refresh(w, target_1280x720());
    REQUIRE(set.all().size() == 2);
    CHECK(set.camera_at({100, 300}) == left);
    CHECK(set.camera_at({1000, 300}) == right);
    // The answer for a point on the right half uses the right camera's position.
    CHECK(set.screen_to_world({960, 360}, 0.0f).x == doctest::Approx(500.0f));
    w.destroy(right);
    set.refresh(w, target_1280x720());
    CHECK(set.all().size() == 1);
    CHECK(set.camera_at({1000, 300}) == left);
}

TEST_CASE("update_parallax: the offset is the camera position times one minus the factor") {
    World w;
    const Entity layer = w.create("layer");
    w.add<Parallax>(layer).factor = {0.25f, 0.5f};
    update_parallax(w, {100.0f, 40.0f});
    const Parallax* p = w.get<Parallax>(layer);
    REQUIRE(p);
    CHECK(p->offset.x == doctest::Approx(75.0f));
    CHECK(p->offset.y == doctest::Approx(20.0f));
}

TEST_CASE("world hash: the live particles are part of it") {
    World a, b;
    for (World* w : {&a, &b}) {
        const Entity e = w->create("sparks");
        auto& em = w->add<ParticleEmitter>(e);
        em.emitting = false;
        em.rate = 0;
        em.burst = 10;
        em.lifetime = 1.0f;
        em.speed = 20;
        em.seed = 9;
    }
    a.particles().update(a, 1.0f / 60.0f);
    b.particles().update(b, 1.0f / 60.0f);
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);
    a.particles().update(a, 1.0f / 60.0f);  // one more step: the particles moved and aged in `a` only
    CHECK(world_state_hash(a).hash != world_state_hash(b).hash);
    b.particles().update(b, 1.0f / 60.0f);
    CHECK(world_state_hash(a).hash == world_state_hash(b).hash);
}

TEST_CASE("world hash: an emitter's random sequence and emission accumulator are part of it") {
    // The emission accumulator: no particle is born yet in either world (10 and 20 per second, one 60 Hz step), so only the fraction
    // owed differs.
    World a, b;
    int i = 0;
    for (World* w : {&a, &b}) {
        const Entity e = w->create("stream");
        auto& em = w->add<ParticleEmitter>(e);
        em.rate = (i++ == 0) ? 10.0f : 20.0f;
        em.lifetime = 1.0f;
        em.seed = 5;
        w->particles().update(*w, 1.0f / 60.0f);
    }
    REQUIRE(a.particles().find(a.find("stream"))->sim.particles.empty());
    REQUIRE(b.particles().find(b.find("stream"))->sim.particles.empty());
    CHECK(world_state_hash(a).hash != world_state_hash(b).hash);

    // The random sequence: two seeds, every particle dead again (the shortest life is 0.01 s), the same clock and counters.
    World c, d;
    i = 0;
    for (World* w : {&c, &d}) {
        const Entity e = w->create("puff");
        auto& em = w->add<ParticleEmitter>(e);
        em.emitting = false;
        em.rate = 0;
        em.burst = 4;
        em.lifetime = 0.01f;
        em.speed = 20;
        em.speedVariance = 0.5f;
        em.seed = (i++ == 0) ? 1 : 2;
        w->particles().update(*w, 1.0f / 60.0f);
        w->particles().update(*w, 1.0f / 60.0f);
    }
    REQUIRE(c.particles().find(c.find("puff"))->sim.particles.empty());
    REQUIRE(d.particles().find(d.find("puff"))->sim.particles.empty());
    CHECK(world_state_hash(c).hash != world_state_hash(d).hash);
}
