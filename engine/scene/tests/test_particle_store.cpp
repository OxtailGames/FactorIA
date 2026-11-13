// The per-world particle state (fa/scene/particle_store.h): the emitters of a World live in the World, so two worlds that hold an entity
// with the very same bits (the editor's scene and its Play session, a scene loaded again) never see each other's particles.
#include <doctest.h>

#include "fa/scene/components.h"
#include "fa/scene/particle_store.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

Entity add_emitter(World& w, const char* id, int burst, bool autoDestroy = false) {
    const Entity e = w.create(id);
    auto& em = w.add<ParticleEmitter>(e);
    em.emitting = false;
    em.rate = 0;
    em.burst = burst;
    em.lifetime = 1.0f;
    em.lifetimeVariance = 0;
    em.speed = 10;
    em.seed = 7;
    em.autoDestroy = autoDestroy;
    return e;
}

}  // namespace

TEST_CASE("particle store: two worlds with the same entity bits do not interfere") {
    World a, b;
    const Entity ea = add_emitter(a, "sparks", 12);
    const Entity eb = add_emitter(b, "sparks", 30);
    REQUIRE(ea.bits() == eb.bits());  // the first entity of a fresh world: the same index and generation
    a.particles().update(a, 1.0f / 60.0f);
    CHECK(a.particles().particle_count() == 12);
    CHECK(b.particles().particle_count() == 0);  // b never stepped
    b.particles().update(b, 1.0f / 60.0f);
    CHECK(a.particles().particle_count() == 12);
    CHECK(b.particles().particle_count() == 30);
    // Clearing one world's store (a scene load) leaves the other's particles where they are.
    a.particles().clear();
    CHECK(a.particles().particle_count() == 0);
    CHECK(b.particles().particle_count() == 30);
    // An emitter that finishes in one world is destroyed there only.
    const Entity da = add_emitter(a, "done", 5, true);
    const Entity db = add_emitter(b, "done", 5, true);
    REQUIRE(da.bits() == db.bits());
    b.particles().update(b, 1.0f / 60.0f);
    for (int i = 0; i < 90; ++i) a.particles().update(a, 1.0f / 60.0f);  // 1.5 s: the 1 s lifetime is over
    CHECK_FALSE(a.find("done"));
    CHECK(b.find("done"));
    CHECK(b.particles().find(db) != nullptr);
    CHECK(a.particles().find(da) == nullptr);
}

TEST_CASE("particle store: the same emitter in two worlds draws the same random numbers, and a queued burst is born in "
          "the next step") {
    World a, b;
    const Entity ea = add_emitter(a, "sparks", 0);
    const Entity eb = add_emitter(b, "sparks", 0);
    a.particles().queue_burst(a, ea, 10);
    b.particles().queue_burst(b, eb, 10);
    for (int i = 0; i < 20; ++i) {
        a.particles().update(a, 1.0f / 60.0f);
        b.particles().update(b, 1.0f / 60.0f);
    }
    const ParticleEmitterState* sa = a.particles().find(ea);
    const ParticleEmitterState* sb = b.particles().find(eb);
    REQUIRE(sa);
    REQUIRE(sb);
    REQUIRE(sa->sim.particles.size() == 10);
    REQUIRE(sb->sim.particles.size() == 10);
    for (std::size_t i = 0; i < 10; ++i) {
        CHECK(sa->sim.particles[i].pos.x == sb->sim.particles[i].pos.x);
        CHECK(sa->sim.particles[i].pos.y == sb->sim.particles[i].pos.y);
    }
    // A burst for an entity that is not an emitter, or a count that is not positive, queues nothing.
    const Entity plain = a.create("plain");
    a.particles().queue_burst(a, plain, 5);
    a.particles().queue_burst(a, ea, 0);
    a.particles().queue_burst(a, ea, -3);
    a.particles().update(a, 1.0f / 60.0f);
    CHECK(a.particles().find(plain) == nullptr);
    CHECK(a.particles().find(ea)->sim.particles.size() == 10);
}

TEST_CASE("particle store: a settle pass (dt 0) keeps the motion an emitter made between two fixed steps") {
    World w;
    const Entity e = add_emitter(w, "trail", 0);
    ParticleEmitter* em = w.get<ParticleEmitter>(e);
    REQUIRE(em);
    em->worldSpace = true;
    em->inheritVelocity = 1.0f;
    em->speed = 0;
    Transform* t = w.get<Transform>(e);
    REQUIRE(t);
    w.particles().update(w, 1.0f / 60.0f);  // the emitter is seen at x = 0
    t->position.x += 6.0f;                  // a script or a tween moves it during the next step ...
    w.particles().update(w, 0.0f);          // ... and the end-of-frame settle pass must not forget where it was
    w.particles().queue_burst(w, e, 1);
    w.particles().update(w, 1.0f / 60.0f);
    const ParticleEmitterState* st = w.particles().find(e);
    REQUIRE(st);
    REQUIRE(st->sim.particles.size() == 1);
    // 6 units in 1/60 s: the particle inherits 360 units/s (a settle pass that took the place as seen would make it 0).
    CHECK(st->sim.particles[0].vel.x == doctest::Approx(360.0f).epsilon(0.05));
}
