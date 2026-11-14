// Physics on the job system (M70.2b): the same simulation, bit for bit, whatever the job threads setting. The scenes are
// big enough to cross the thresholds that send a step to the pool (B2JobTasks), so the pool really takes part; the hash
// covers every body's pose and velocity each frame and every collision event in the order it was reported.
#include <doctest.h>

#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/hash.h"
#include "fa/core/jobs.h"
#include "fa/physics/physics.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

void feed(Sha256& h, float v) {
    std::uint32_t bits;
    std::memcpy(&bits, &v, sizeof bits);
    h.update(&bits, sizeof bits);
}
void feed(Sha256& h, Vec3 v) {
    feed(h, v.x);
    feed(h, v.y);
    feed(h, v.z);
}
void feed(Sha256& h, std::uint64_t v) { h.update(&v, sizeof v); }

// Starts the pool for one run and stops it at the end; `threads` -1 is inline mode and kNoPool leaves the pool stopped.
constexpr int kNoPool = -2;
struct Pool {
    explicit Pool(int threads) : started_(threads != kNoPool) {
        if (!started_) return;
        const jobs::Settings s = threads < 0 ? jobs::Settings::inline_jobs() : jobs::Settings::threads(threads);
        REQUIRE(jobs::start(s));
    }
    ~Pool() {
        if (started_) jobs::stop();
    }
    bool started_;
};

void add_static_box(World& w, const char* id, Vec3 pos, Vec3 size) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    w.add<Collider2D>(e).size = {size.x, size.y};
    w.add<RigidBody2D>(e).type = BodyType::Static;
}

// A basin of walls with `n` circles, boxes and capsules dropped in, a one-way platform, a sensor and a few hinged pairs.
void build_basin_2d(World& w, int n) {
    add_static_box(w, "floor", {0, -20, 0}, {900, 40, 0});
    add_static_box(w, "wallL", {-450, 300, 0}, {40, 700, 0});
    add_static_box(w, "wallR", {450, 300, 0}, {40, 700, 0});
    {
        Entity e = w.create("shelf", "shelf");
        w.get<Transform>(e)->position = {0, 120, 0};
        Collider2D& c = w.add<Collider2D>(e);
        c.size = {300, 12};
        c.oneWay = true;
        w.add<RigidBody2D>(e).type = BodyType::Static;
    }
    {
        Entity e = w.create("zone", "zone");
        w.get<Transform>(e)->position = {-200, 60, 0};
        Collider2D& c = w.add<Collider2D>(e);
        c.size = {120, 100};
        c.isTrigger = true;
        w.add<RigidBody2D>(e).type = BodyType::Static;
    }
    for (int i = 0; i < n; ++i) {
        Entity e = w.create("b" + std::to_string(i), "b" + std::to_string(i));
        const int col = i % 25, row = i / 25;
        w.get<Transform>(e)->position = {-360.0f + 29.0f * float(col) + (row % 2 ? 6.0f : 0.0f),
                                         80.0f + 27.0f * float(row), 0};
        w.get<Transform>(e)->rotation = {0, 0, float((i * 37) % 90)};
        Collider2D& c = w.add<Collider2D>(e);
        switch (i % 3) {
            case 0:
                c.shape = ColliderShape::Circle;
                c.radius = 11.0f;
                break;
            case 1: c.size = {22, 18}; break;
            default:
                c.shape = ColliderShape::Capsule;
                c.size = {16, 30};
                break;
        }
        c.restitution = (i % 7 == 0) ? 0.4f : 0.0f;
        w.add<RigidBody2D>(e);
    }
    for (int i = 0; i + 1 < n && i < 40; i += 2) {  // hinged pairs
        Joint2D& j = w.add<Joint2D>(w.find("b" + std::to_string(i)));
        j.connected = w.find("b" + std::to_string(i + 1));
        j.anchor = {14, 0};
        j.connectedAnchor = {-14, 0};
    }
}

// Many identical pairs of dynamic boxes, each pair dropped together on a wide floor: they bounce apart a little (a contact
// between two dynamic bodies ends, so Box2D marks the island as one that must be split before it sleeps), then settle on
// the SAME step, so their sleep times are bit-equal. Which island Box2D splits next is picked among the candidates the
// workers found, and a tie there is broken by the island id: the pieces a task is cut into must not depend on the pool.
void build_tied_islands_2d(World& w, int pairs) {
    add_static_box(w, "floor", {0, -20, 0}, {40.0f * float(pairs) + 400.0f, 40, 0});
    for (int i = 0; i < pairs; ++i) {
        for (int k = 0; k < 2; ++k) {
            const std::string id = "t" + std::to_string(i) + "_" + std::to_string(k);
            Entity e = w.create(id, id);
            w.get<Transform>(e)->position = {40.0f * float(i), 14.0f + 90.0f * float(k), 0};
            Collider2D& c = w.add<Collider2D>(e);
            c.size = {20, 20};
            c.restitution = 0.35f;
            w.add<RigidBody2D>(e);
        }
    }
}

// `submitted` (if given) gets the number of jobs the run queued.
std::string run_2d(int threads, int n, int frames, int* submitted = nullptr, bool tied = false) {
    Pool pool(threads);
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    if (tied)
        build_tied_islands_2d(world, n);
    else
        build_basin_2d(world, n);
    Sha256 h;
    const std::vector<Entity> all = world.entities();
    const bool bench = std::getenv("FA_PHYSICS_BENCH") != nullptr;
    double stepMs = 0;
    for (int f = 0; f < frames; ++f) {
        world.events().clear();
        const auto t0 = std::chrono::steady_clock::now();
        physics.step(world, kDt);
        stepMs += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        world.advance_clock(kDt);
        world.flush();
        for (const CollisionEvent& ev : world.events().collisions) {
            feed(h, std::uint64_t(ev.phase == CollisionEvent::Phase::Begin ? 1 : 2));
            feed(h, ev.a.bits());
            feed(h, ev.b.bits());
            feed(h, std::uint64_t(ev.trigger));
            feed(h, ev.point);
            feed(h, ev.normal);
            feed(h, ev.impulse);
        }
        if (f % 3 == 2 || tied) {
            for (Entity e : all) {
                if (!world.get<RigidBody2D>(e)) continue;
                const Transform* t = world.get<Transform>(e);
                feed(h, t->position);
                feed(h, t->rotation);
                feed(h, Vec3{world.get<RigidBody2D>(e)->velocity.x, world.get<RigidBody2D>(e)->velocity.y, 0});
            }
        }
    }
    if (bench) std::printf("FA_PHYSICS_BENCH 2d n=%d threads=%d step avg %.3f ms\n", n, threads, stepMs / frames);
    if (submitted) {
        jobs::end_frame();  // closes the statistics of the whole run
        *submitted = jobs::info().submittedLastFrame;
    }
    return h.finish_hex().substr(0, 16);
}

void add_static_box3(World& w, const char* id, Vec3 pos, Vec3 size) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    w.add<RigidBody3D>(e).type = BodyType::Static;
}

// A walled yard with `n` boxes, balls and capsules dropped in, hinged chains, a trigger and a moving kinematic platform.
void build_yard_3d(World& w, int n) {
    add_static_box3(w, "floor", {0, -0.5f, 0}, {60, 1, 60});
    add_static_box3(w, "wallN", {0, 3, -30}, {60, 6, 1});
    add_static_box3(w, "wallS", {0, 3, 30}, {60, 6, 1});
    add_static_box3(w, "wallE", {30, 3, 0}, {1, 6, 60});
    add_static_box3(w, "wallW", {-30, 3, 0}, {1, 6, 60});
    add_static_box3(w, "ramp", {8, 1, 0}, {8, 0.4f, 6});
    w.get<Transform>(w.find("ramp"))->rotation = {0, 0, 15};
    {
        Entity e = w.create("zone", "zone");
        w.get<Transform>(e)->position = {-10, 1, 5};
        Collider3D& c = w.add<Collider3D>(e);
        c.size = {6, 3, 6};
        c.isTrigger = true;
        w.add<RigidBody3D>(e).type = BodyType::Static;
    }
    {
        Entity e = w.create("lift", "lift");
        w.get<Transform>(e)->position = {-15, 0.3f, -10};
        w.add<Collider3D>(e).size = {4, 0.4f, 4};
        RigidBody3D& rb = w.add<RigidBody3D>(e);
        rb.type = BodyType::Kinematic;
        rb.velocity = {1.5f, 0, 0};
    }
    for (int i = 0; i < n; ++i) {
        Entity e = w.create("b" + std::to_string(i), "b" + std::to_string(i));
        const int col = i % 16, row = (i / 16) % 16, layer = i / 256;
        w.get<Transform>(e)->position = {-20.0f + 2.4f * float(col) + (row % 2 ? 0.4f : 0.0f),
                                         1.0f + 1.3f * float(layer * 3 + row % 3), -20.0f + 2.4f * float(row)};
        w.get<Transform>(e)->rotation = {float((i * 29) % 90), float((i * 53) % 90), float((i * 11) % 90)};
        Collider3D& c = w.add<Collider3D>(e);
        switch (i % 3) {
            case 0:
                c.shape = ColliderShape3D::Sphere;
                c.radius = 0.5f;
                break;
            case 1: c.size = {0.9f, 0.7f, 0.8f}; break;
            default:
                c.shape = ColliderShape3D::Capsule;
                c.radius = 0.3f;
                c.height = 1.2f;
                break;
        }
        c.restitution = (i % 7 == 0) ? 0.3f : 0.0f;
        RigidBody3D& rb = w.add<RigidBody3D>(e);
        rb.angularVelocity = {float(i % 5) * 20.0f, 10.0f, -float(i % 4) * 15.0f};
    }
    for (int i = 0; i + 1 < n && i < 60; i += 2) {  // hinged pairs
        Joint3D& j = w.add<Joint3D>(w.find("b" + std::to_string(i)));
        j.connected = w.find("b" + std::to_string(i + 1));
        j.axis = {0, 0, 1};
        j.anchor = {0.6f, 0, 0};
        j.connectedAnchor = {-0.6f, 0, 0};
        j.autoAnchor = false;
    }
}

// The hash of a 3D run; `submitted` (if given) gets the number of jobs it queued.
std::string run_3d(int threads, int n, int frames, int* submitted = nullptr) {
    Pool pool(threads);
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    build_yard_3d(world, n);
    Sha256 h;
    const std::vector<Entity> all = world.entities();
    const bool bench = std::getenv("FA_PHYSICS_BENCH") != nullptr;
    double stepMs = 0;
    for (int f = 0; f < frames; ++f) {
        world.events().clear();
        const auto t0 = std::chrono::steady_clock::now();
        physics.step(world, kDt);
        stepMs += std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
        world.advance_clock(kDt);
        world.flush();
        for (const CollisionEvent& ev : world.events().collisions) {
            feed(h, std::uint64_t(ev.phase == CollisionEvent::Phase::Begin ? 1 : 2));
            feed(h, ev.a.bits());
            feed(h, ev.b.bits());
            feed(h, std::uint64_t(ev.trigger));
            feed(h, ev.point);
            feed(h, ev.normal);
            feed(h, ev.impulse);
        }
        if (f % 3 == 2) {
            for (Entity e : all) {
                const RigidBody3D* rb = world.get<RigidBody3D>(e);
                if (!rb) continue;
                const Transform* t = world.get<Transform>(e);
                feed(h, t->position);
                feed(h, t->rotation);
                feed(h, rb->velocity);
                feed(h, rb->angularVelocity);
            }
        }
    }
    if (bench) std::printf("FA_PHYSICS_BENCH 3d n=%d threads=%d step avg %.3f ms\n", n, threads, stepMs / frames);
    if (submitted) {
        jobs::end_frame();
        *submitted = jobs::info().submittedLastFrame;
    }
    return h.finish_hex().substr(0, 16);
}

}  // namespace

TEST_CASE("physics jobs 2D: a big basin gives the same hash inline and with 1, 2 and 8 job threads") {
    // The defaults keep a basin this size on the calling thread (a job would cost more than it gains); lower them so
    // that the pool really runs the step.
    const ScopedPhysicsJobThresholds lowered({256, 512});
    int inlineJobs = -1, jobs1 = -1, jobs2 = -1, jobs8 = -1;
    const char* benchN = std::getenv("FA_PHYSICS_BENCH_N");  // timing runs of other sizes (FA_PHYSICS_BENCH=1)
    const int n = benchN ? std::atoi(benchN) : 420;
    const std::string reference = run_2d(-1, n, 150, &inlineJobs);
    CHECK(run_2d(1, n, 150, &jobs1) == reference);
    CHECK(run_2d(2, n, 150, &jobs2) == reference);
    CHECK(run_2d(8, n, 150, &jobs8) == reference);
    CHECK(inlineJobs == 0);  // inline mode: Box2D's tasks run on the calling thread, nothing is queued
    CHECK(jobs1 > 150);      // the pool really takes part: several tasks per step
    CHECK(jobs2 == jobs1);   // what is queued depends on the scene, not on the thread count
    CHECK(jobs8 == jobs1);
}

TEST_CASE("physics jobs 2D: tied islands that settle on the same step give the same hash with the pool stopped, inline "
          "and on 1 and 8 threads") {
    const ScopedPhysicsJobThresholds lowered({64, 128});
    const int pairs = 90, frames = 200;  // 180 bodies: every task is cut into 4 pieces
    const std::string reference = run_2d(1, pairs, frames, nullptr, true);
    CHECK(run_2d(kNoPool, pairs, frames, nullptr, true) == reference);
    CHECK(run_2d(-1, pairs, frames, nullptr, true) == reference);
    CHECK(run_2d(0, pairs, frames, nullptr, true) == reference);
    CHECK(run_2d(8, pairs, frames, nullptr, true) == reference);
}

TEST_CASE("physics jobs 2D: a step below the default thresholds queues nothing") {
    CHECK(physics_job_thresholds().awakeBodies == 1536);
    int queued = -1;
    const std::string reference = run_2d(-1, 420, 60);
    CHECK(run_2d(3, 420, 60, &queued) == reference);
    CHECK(queued == 0);
}

TEST_CASE("physics jobs 2D: a small scene (below the thresholds) gives the same hash with and without threads") {
    const std::string reference = run_2d(-1, 40, 120);
    int queued = -1;
    CHECK(run_2d(3, 40, 120, &queued) == reference);
    CHECK(queued == 0);  // a small step never leaves the calling thread
}

TEST_CASE("physics jobs 3D: a big yard gives the same hash inline and with 1, 2 and 8 job threads") {
    int inlineJobs = -1, jobs1 = -1, jobs2 = -1, jobs8 = -1;
    const char* benchN = std::getenv("FA_PHYSICS_BENCH_N");  // timing runs of other sizes (FA_PHYSICS_BENCH=1)
    const int n = benchN ? std::atoi(benchN) : 320;  // over kMinParallelRows (256) rows, or no scan runs on the pool
    const std::string reference = run_3d(-1, n, 150, &inlineJobs);
    CHECK(run_3d(1, n, 150, &jobs1) == reference);
    CHECK(run_3d(2, n, 150, &jobs2) == reference);
    CHECK(run_3d(8, n, 150, &jobs8) == reference);
    CHECK(inlineJobs == 0);
    CHECK(jobs1 > 0);
    CHECK(jobs2 == jobs1);
    CHECK(jobs8 == jobs1);
}

TEST_CASE("physics jobs 3D: a small yard (below the thresholds) gives the same hash and queues nothing") {
    const std::string reference = run_3d(-1, 40, 120);
    int queued = -1;
    CHECK(run_3d(3, 40, 120, &queued) == reference);
    CHECK(queued == 0);
}
