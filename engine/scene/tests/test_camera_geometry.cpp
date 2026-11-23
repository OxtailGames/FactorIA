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

// ---- M76: the sub-pixel jitter of the drawn projection (fa/scene/jitter.h) -------------------------------------------------------------------

#include "fa/scene/jitter.h"

TEST_CASE("jitter: Halton(2,3) values, the offsets, the phases") {
    CHECK(halton(0, 2) == 0.0f);
    CHECK(halton(1, 2) == doctest::Approx(0.5f));
    CHECK(halton(2, 2) == doctest::Approx(0.25f));
    CHECK(halton(3, 2) == doctest::Approx(0.75f));
    CHECK(halton(4, 2) == doctest::Approx(0.125f));
    CHECK(halton(1, 3) == doctest::Approx(1.0f / 3.0f));
    CHECK(halton(2, 3) == doctest::Approx(2.0f / 3.0f));
    CHECK(halton(3, 3) == doctest::Approx(1.0f / 9.0f));
    CHECK(halton(5, 1) == 0.0f);  // a base below 2 is no sequence
    // Frame f uses element (f mod phases) + 1, centred on the pixel: x = halton2 - 0.5, y = halton3 - 0.5.
    const Vec2 f0 = jitter_offset_pixels(0);
    CHECK(f0.x == doctest::Approx(0.0f));
    CHECK(f0.y == doctest::Approx(1.0f / 3.0f - 0.5f));
    const Vec2 f1 = jitter_offset_pixels(1);
    CHECK(f1.x == doctest::Approx(-0.25f));
    CHECK(f1.y == doctest::Approx(2.0f / 3.0f - 0.5f));
    // The sequence repeats after `phases` frames and never leaves the pixel.
    for (const int phases : {1, 8, 16}) {
        for (std::uint64_t f = 0; f < 40; ++f) {
            const Vec2 a = jitter_offset_pixels(f, phases), b = jitter_offset_pixels(f + std::uint64_t(phases), phases);
            CHECK(a.x == b.x);
            CHECK(a.y == b.y);
            CHECK(std::fabs(a.x) < 0.5f);
            CHECK(std::fabs(a.y) < 0.5f);
        }
    }
    // `phases` is clamped to 1 .. kJitterPhasesMax: 0 and negative read as 1, 100 as 16; and 8 differs from 16.
    CHECK(jitter_offset_pixels(5, 0).x == jitter_offset_pixels(0, 1).x);
    CHECK(jitter_offset_pixels(5, -3).y == jitter_offset_pixels(0, 1).y);
    CHECK(jitter_offset_pixels(11, 100).x == jitter_offset_pixels(11, kJitterPhasesMax).x);
    CHECK(jitter_offset_pixels(10, 16).x != jitter_offset_pixels(10, 8).x);
    // The 8 offsets of the default sequence are all different.
    for (int i = 0; i < kJitterPhasesDefault; ++i)
        for (int k = i + 1; k < kJitterPhasesDefault; ++k) {
            const Vec2 a = jitter_offset_pixels(std::uint64_t(i)), b = jitter_offset_pixels(std::uint64_t(k));
            CHECK((a.x != b.x || a.y != b.y));
        }
}

TEST_CASE("jitter: pixels to NDC flips y and scales by the image size") {
    const Vec2 n = jitter_pixels_to_ndc({0.5f, 0.25f}, 1000.0f, 500.0f);
    CHECK(n.x == doctest::Approx(0.001f));
    CHECK(n.y == doctest::Approx(-0.001f));
    const Vec2 tiny = jitter_pixels_to_ndc({1.0f, 1.0f}, 0.0f, -4.0f);  // a size below 1 reads as 1
    CHECK(tiny.x == doctest::Approx(2.0f));
    CHECK(tiny.y == doctest::Approx(-2.0f));
}

TEST_CASE("camera geometry: a jitter moves the drawn matrices only; jitter 0 is today's matrices") {
    for (const bool perspective : {false, true}) {
        for (const bool zeroToOne : {false, true}) {
            World w;
            const Entity cam = add_camera(w, "cam", {10, 5});
            if (perspective) {
                w.get<Camera>(cam)->projection = Projection::Perspective;
                w.get<Transform>(cam)->position = {10, 5, 20};
            }
            CameraTarget t = target_1280x720();
            t.zeroToOne = zeroToOne;
            std::string warned;
            CameraGeometry g = camera_geometry(w, cam, t, warned);
            // Before apply_jitter the drawn matrices are the plain ones.
            CHECK(g.drawProj.m[0] == g.proj.m[0]);
            for (int i = 0; i < 16; ++i) {
                CHECK(g.drawViewProj.m[i] == g.viewProj.m[i]);
                CHECK(g.drawProj.m[i] == g.proj.m[i]);
            }
            CHECK(g.jitterPx.x == 0.0f);
            CHECK(g.jitterNdc.y == 0.0f);
            const CameraGeometry plain = g;
            g.apply_jitter({0.0f, 0.0f}, 1280.0f, 720.0f);  // jitter 0: identical to today
            for (int i = 0; i < 16; ++i) {
                CHECK(g.drawViewProj.m[i] == plain.viewProj.m[i]);
                CHECK(g.drawProj.m[i] == plain.proj.m[i]);
            }
            g.apply_jitter({0.25f, -0.4f}, 1280.0f, 720.0f);
            // Nothing a query reads moves.
            for (int i = 0; i < 16; ++i) {
                CHECK(g.proj.m[i] == plain.proj.m[i]);
                CHECK(g.view.m[i] == plain.view.m[i]);
                CHECK(g.viewProj.m[i] == plain.viewProj.m[i]);
                CHECK(g.invViewProj.m[i] == plain.invViewProj.m[i]);
                CHECK(g.queryViewProj.m[i] == plain.queryViewProj.m[i]);
                CHECK(g.queryInvViewProj.m[i] == plain.queryInvViewProj.m[i]);
            }
            const Vec3 p{12, 6, 0};
            CHECK(g.world_to_screen(p, {1280, 720}).x == plain.world_to_screen(p, {1280, 720}).x);
            CHECK(g.world_to_screen(p, {1280, 720}).y == plain.world_to_screen(p, {1280, 720}).y);
            // The drawn point moved by the jitter, in pixels of the 1280 x 720 image (x right, y down), whatever its depth.
            for (const Vec3 q : {Vec3{12, 6, 0}, Vec3{-30, 20, -5}}) {
                const Vec4 a = plain.viewProj * Vec4{q, 1.0f}, b = g.drawViewProj * Vec4{q, 1.0f};
                const float ax = a.x / a.w, ay = a.y / a.w, bx = b.x / b.w, by = b.y / b.w;
                CHECK((bx - ax) * 640.0f == doctest::Approx(0.25f).epsilon(0.01));
                CHECK((by - ay) * -360.0f == doctest::Approx(-0.4f).epsilon(0.01));
                CHECK(b.z / b.w == doctest::Approx(a.z / a.w));  // the depth is not jittered
            }
            CHECK(g.jitterPx.x == 0.25f);
            CHECK(g.jitterNdc.x == doctest::Approx(2.0f * 0.25f / 1280.0f));
            // A new call replaces the jitter, it does not add; a NaN is no jitter.
            g.apply_jitter({0.0f, 0.0f}, 1280.0f, 720.0f);
            for (int i = 0; i < 16; ++i) CHECK(g.drawViewProj.m[i] == plain.viewProj.m[i]);
            g.apply_jitter({std::nanf(""), 0.1f}, 1280.0f, 720.0f);
            CHECK(g.jitterPx.x == 0.0f);
            CHECK(g.jitterPx.y == 0.0f);
        }
    }
}
