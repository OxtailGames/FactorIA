// What a 3D physics step allocates once the scene has stopped growing (M94.4g). The solver keeps its working vectors
// in Physics3D::sc_ and clears them instead of freeing, so a step of a settled scene must not allocate for them. This
// test counts the allocations of Physics::step (the replaced global operator new below counts and forwards to malloc,
// for the whole test executable) and checks that the count does not grow with the number of bodies. What is left per
// step is a fixed number: one list of the entities per backend (World::entities() returns a copy; the 3D sync takes it
// once per step and shares it with the joint sync, the 2D backend takes its own) and whatever the standard library
// allocates for an empty container.
#include <doctest.h>

#include <atomic>
#include <cstdio>
#include <cstdlib>
#include <new>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/core/math.h"
#include "fa/physics/physics.h"

namespace {
std::atomic<std::size_t> g_allocations{0};
}

void* operator new(std::size_t n) {
    g_allocations.fetch_add(1, std::memory_order_relaxed);
    if (void* p = std::malloc(n != 0 ? n : 1)) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t n) {
    g_allocations.fetch_add(1, std::memory_order_relaxed);
    if (void* p = std::malloc(n != 0 ? n : 1)) return p;
    throw std::bad_alloc();
}
// The nothrow forms too: libstdc++'s std::stable_sort takes its temporary buffer with them and frees it with the plain
// delete below, which AddressSanitizer reports as a new/free mismatch when only the throwing forms are replaced.
void* operator new(std::size_t n, const std::nothrow_t&) noexcept {
    g_allocations.fetch_add(1, std::memory_order_relaxed);
    return std::malloc(n != 0 ? n : 1);
}
void* operator new[](std::size_t n, const std::nothrow_t&) noexcept {
    g_allocations.fetch_add(1, std::memory_order_relaxed);
    return std::malloc(n != 0 ? n : 1);
}
void operator delete(void* p, const std::nothrow_t&) noexcept { std::free(p); }
void operator delete[](void* p, const std::nothrow_t&) noexcept { std::free(p); }
void operator delete(void* p) noexcept { std::free(p); }
void operator delete[](void* p) noexcept { std::free(p); }
void operator delete(void* p, std::size_t) noexcept { std::free(p); }
void operator delete[](void* p, std::size_t) noexcept { std::free(p); }

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct Sim {
    World world;
    Physics physics;
    Sim() { physics.init(PhysicsSettings{}); }
    void run(int steps) {
        for (int i = 0; i < steps; ++i) {
            world.events().clear();
            physics.step(world, kDt);
            world.advance_clock(kDt);
            world.flush();
        }
    }
};

Entity add_static_box(World& w, Vec3 pos, Vec3 size) {
    Entity e = w.create();
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    return e;
}

// Spheres, capsules and boxes in layers of 10 x 10 above a floor and four walls (the pit of test_physics3d_scale.cpp).
void build_pit(World& w, int n) {
    add_static_box(w, {0, -0.5f, 0}, {30, 1, 30});
    add_static_box(w, {-15.5f, 5, 0}, {1, 12, 32});
    add_static_box(w, {15.5f, 5, 0}, {1, 12, 32});
    add_static_box(w, {0, 5, -15.5f}, {32, 12, 1});
    add_static_box(w, {0, 5, 15.5f}, {32, 12, 1});
    for (int i = 0; i < n; ++i) {
        const int layer = i / 100, k = i % 100;
        Entity e = w.create();
        w.get<Transform>(e)->position = {-6.3f + 1.4f * float(k % 10) + 0.003f * float(i % 7),
                                         0.8f + 1.3f * float(layer),
                                         -6.3f + 1.4f * float(k / 10) + 0.003f * float(i % 5)};
        Collider3D& c = w.add<Collider3D>(e);
        switch (i % 3) {
            case 0:
                c.shape = ColliderShape3D::Sphere;
                c.radius = 0.5f;
                break;
            case 1:
                c.shape = ColliderShape3D::Capsule;
                c.radius = 0.3f;
                c.height = 1.2f;
                break;
            default: c.size = {0.9f, 0.9f, 0.9f}; break;
        }
        w.add<RigidBody3D>(e);
    }
}

std::size_t allocations_of(Sim& s, int steps) {
    const std::size_t before = g_allocations.load();
    s.run(steps);
    return g_allocations.load() - before;
}

// The count of a step depends on the standard library (an empty std::map or std::unordered_set allocates when it is
// built on MSVC and not on libc++ or libstdc++), so the tests do not state a number: they state that the count does
// not grow with the bodies. The same 30 steps are counted in a small and in a big scene, and the big one may make
// only a few more allocations (a vector that still grows) than the small one; per body it would be hundreds more.
// The absolute counts are printed. The counter sees every thread, so no pool may be running.
bool pool_is_off() { return !jobs::running() || jobs::inline_mode(); }

// A pit of `bodies` bodies, run through the drop and the first impacts so every working vector has met its biggest
// scene, then counted over 30 steps in which bodies still fall, collide and begin or end contacts.
std::size_t awake_pit_allocations(int bodies) {
    Sim s;
    build_pit(s.world, bodies);
    s.run(120);
    return allocations_of(s, 30);
}

// Everything asleep: a step is the sync only.
std::size_t sleeping_allocations(int boxes) {
    Sim s;
    add_static_box(s.world, {0, -0.5f, 0}, {40, 1, 40});
    for (int i = 0; i < boxes; ++i) {
        Entity e = s.world.create();
        s.world.get<Transform>(e)->position = {-9.0f + 1.0f * float(i % 20), 0.5f, -5.0f + 1.0f * float(i / 20)};
        s.world.add<Collider3D>(e).size = {1, 1, 1};
        s.world.add<RigidBody3D>(e);
    }
    s.run(120);  // the boxes rest on the floor and sleep
    return allocations_of(s, 30);
}

}  // namespace

// Before the working vectors were members a step made about 40 allocations of its own for any scene (over 1000 in
// these 30 steps for a pit of 300, the buffers of std::inplace_merge among them).
TEST_CASE("3d alloc: the allocations of a step of an awake pit do not grow with the bodies") {
    REQUIRE(pool_is_off());
    const std::size_t small = awake_pit_allocations(50);
    const std::size_t big = awake_pit_allocations(300);
    std::printf("[alloc] awake pit: %zu allocations in 30 steps with 50 bodies, %zu with 300\n", small, big);
    CHECK(big <= small + 30 * 2);
}

TEST_CASE("3d alloc: the allocations of a step of a sleeping scene do not grow with the bodies") {
    REQUIRE(pool_is_off());
    const std::size_t small = sleeping_allocations(20);
    const std::size_t big = sleeping_allocations(200);
    std::printf("[alloc] sleeping: %zu allocations in 30 steps with 20 bodies, %zu with 200\n", small, big);
    CHECK(big <= small + 30 * 2);
}
