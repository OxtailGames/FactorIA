// Sleeping bodies cost (almost) nothing in the 3D solver (M94.4e): a big pile asleep with a few bodies awake elsewhere
// steps like the awake bodies alone, the pile is not touched by anything that happens away from it, and it still wakes when
// something reaches it. Budgets are CPU time (fa::process_cpu_seconds), generous, and only counted in an optimized build.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/hash.h"
#include "fa/core/jobs.h"
#include "fa/core/perf.h"
#include "fa/physics/physics.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

#ifdef NDEBUG
constexpr bool kOptimized = true;
#else
constexpr bool kOptimized = false;
#endif

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
    int awake_count() const {
        int n = 0;
        for (const Json& j : physics.debug_state(world))
            if (j.contains("awake") && j["awake"].get<bool>()) ++n;
        return n;
    }
};

Entity add_static_box(World& w, Vec3 pos, Vec3 size) {
    Entity e = w.create();
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    return e;
}

// `count` unit boxes resting in layers of 20 x 10 (touching) on a floor, in x -10..10 and z -5..5. Returns them.
std::vector<Entity> build_pile(World& w, int count) {
    add_static_box(w, {0, -0.5f, 0}, {200, 1, 200});
    std::vector<Entity> out;
    for (int i = 0; i < count; ++i) {
        const int layer = i / 200, k = i % 200;
        Entity e = w.create();
        w.get<Transform>(e)->position = {-9.5f + float(k % 20), 0.5f + float(layer), -4.5f + float(k / 20)};
        w.add<Collider3D>(e).size = {1, 1, 1};
        w.add<RigidBody3D>(e);
        out.push_back(e);
    }
    return out;
}

// `count` spheres, capsules and boxes falling from different heights, 30 m away from the pile (x 30..48).
std::vector<Entity> add_fallers(World& w, int count) {
    std::vector<Entity> out;
    for (int i = 0; i < count; ++i) {
        Entity e = w.create();
        w.get<Transform>(e)->position = {30.0f + 2.0f * float(i % 10), 3.0f + 0.4f * float(i % 4), 2.0f * float(i / 10)};
        Collider3D& c = w.add<Collider3D>(e);
        if (i % 3 == 0) {
            c.shape = ColliderShape3D::Sphere;
            c.radius = 0.5f;
        } else if (i % 3 == 1) {
            c.shape = ColliderShape3D::Capsule;
            c.radius = 0.3f;
            c.height = 1.2f;
        } else {
            c.size = {0.9f, 0.9f, 0.9f};
        }
        w.add<RigidBody3D>(e);
        out.push_back(e);
    }
    return out;
}

// The bits of position, rotation and velocity of every body (a changed bit is a moved body).
std::vector<std::uint32_t> state_bits(const World& w, const std::vector<Entity>& bodies) {
    std::vector<std::uint32_t> out;
    auto push = [&](Vec3 v) {
        std::uint32_t b[3];
        std::memcpy(b, &v, sizeof b);
        out.insert(out.end(), b, b + 3);
    };
    for (Entity e : bodies) {
        push(w.get<Transform>(e)->position);
        push(w.get<Transform>(e)->rotation);
        push(w.get<RigidBody3D>(e)->velocity);
        push(w.get<RigidBody3D>(e)->angularVelocity);
    }
    return out;
}

void feed(Sha256& h, Vec3 v) {
    const float f[3] = {v.x, v.y, v.z};
    h.update(f, sizeof f);
}

// Stops the job system when the scope ends, also when a REQUIRE below throws.
struct JobsGuard {
    ~JobsGuard() { jobs::stop(); }
};

// What the pile and the fallers end at, whatever the job threads setting.
std::string run_mostly_asleep_hash(int threads) {
    const jobs::Settings s = threads < 0 ? jobs::Settings::inline_jobs() : jobs::Settings::threads(threads);
    REQUIRE(jobs::start(s));
    JobsGuard guard;
    std::string out;
    {
        Sim sim;
        const std::vector<Entity> pile = build_pile(sim.world, 300);
        sim.run(80);
        std::vector<Entity> all = pile;
        const std::vector<Entity> fallers = add_fallers(sim.world, 100);  // enough rows for the scans to split in chunks
        all.insert(all.end(), fallers.begin(), fallers.end());
        Sha256 h;
        for (int f = 0; f < 60; ++f) {
            sim.run(1);
            if (f % 5 == 4) {
                for (Entity e : all) {
                    feed(h, sim.world.get<Transform>(e)->position);
                    feed(h, sim.world.get<Transform>(e)->rotation);
                    feed(h, sim.world.get<RigidBody3D>(e)->velocity);
                }
            }
        }
        out = h.finish_hex().substr(0, 16);
    }
    return out;
}

}  // namespace

TEST_CASE("3d asleep: a pile asleep is not touched by what happens far from it") {
    Sim s;
    const std::vector<Entity> pile = build_pile(s.world, 400);
    s.run(80);
    REQUIRE(s.awake_count() == 0);
    const std::vector<std::uint32_t> before = state_bits(s.world, pile);
    // Fast bodies landing 30 m away: time-of-impact events and the position pass of their islands, every sub-step.
    const std::vector<Entity> fallers = add_fallers(s.world, 20);
    for (Entity e : fallers) s.world.get<RigidBody3D>(e)->velocity = {0, -40.0f, 0};
    int mostAwake = 0;
    for (int i = 0; i < 90; ++i) {
        s.run(1);
        mostAwake = std::max(mostAwake, s.awake_count());
        if (i == 5) REQUIRE(mostAwake > 0);
    }
    CHECK(mostAwake <= 20);                         // only the fallers ever were awake
    CHECK(state_bits(s.world, pile) == before);      // the pile is exactly where, how and as it was
    for (Entity e : fallers) CHECK(s.world.world_position(e).y > 0.0f);  // none went through the floor
}

TEST_CASE("3d asleep: the pile wakes when a body lands on it and holds it up") {
    Sim s;
    const std::vector<Entity> pile = build_pile(s.world, 200);
    s.run(80);
    REQUIRE(s.awake_count() == 0);
    // A heavy box dropped on the middle of the pile, and a sphere thrown against its side.
    Entity dropped = s.world.create();
    s.world.get<Transform>(dropped)->position = {0.5f, 5.0f, 0.5f};
    s.world.add<Collider3D>(dropped).size = {1, 1, 1};
    s.world.add<RigidBody3D>(dropped).mass = 5.0f;
    Entity thrown = s.world.create();
    s.world.get<Transform>(thrown)->position = {-14.0f, 0.5f, 0.0f};
    Collider3D& c = s.world.add<Collider3D>(thrown);
    c.shape = ColliderShape3D::Sphere;
    c.radius = 0.5f;
    s.world.add<RigidBody3D>(thrown).velocity = {12.0f, 0.0f, 0.0f};
    const std::vector<std::uint32_t> before = state_bits(s.world, pile);
    int mostAwake = 0;
    for (int i = 0; i < 90; ++i) {
        s.run(1);
        mostAwake = std::max(mostAwake, s.awake_count());
    }
    CHECK(mostAwake > 2);                                   // the bodies it hit woke up
    CHECK(state_bits(s.world, pile) != before);             // and moved
    CHECK(s.world.world_position(dropped).y > 0.9f);        // the box did not sink through the pile
    for (Entity e : pile) CHECK(s.world.world_position(e).y > 0.3f);  // nothing was pushed through the floor
    s.run(240);
    CHECK(s.awake_count() == 0);  // and everything falls asleep again
}

TEST_CASE("3d asleep: a pile asleep with bodies awake elsewhere gives the same bits with 0, 1 and 4 job threads") {
    const std::string inl = run_mostly_asleep_hash(-1);
    const std::string one = run_mostly_asleep_hash(1);
    const std::string four = run_mostly_asleep_hash(4);
    CHECK(inl == one);
    CHECK(inl == four);
    std::printf("[asleep] hash %s\n", inl.c_str());
}

// A step of the 1000 asleep + 20 awake world costs about what the 20 awake bodies alone cost (a sleeping body is read by the
// sync of its components and the tree queries of the pair rows). Before M94.4e it was 130 times as much; measured now:
// 5.8x (the bench) to 9x (this test, whose awake-only world is smaller); the limit is 25x.
TEST_CASE("3d asleep: 1000 bodies asleep and 20 awake step in about the time of the 20 awake alone") {
    const int pileSize = kOptimized ? 1000 : 400;
    const int kSteps = 30;
    auto timed = [&](bool withPile) {
        Sim s;
        if (withPile) {
            build_pile(s.world, pileSize);
            s.run(80);
            REQUIRE(s.awake_count() == 0);
        } else {
            add_static_box(s.world, {0, -0.5f, 0}, {200, 1, 200});
        }
        add_fallers(s.world, 20);
        s.run(2);  // (the sync that creates the bodies, the broad phase tree)
        const double t0 = process_cpu_seconds();
        s.run(kSteps);
        const double t = process_cpu_seconds() - t0;
        CHECK(s.awake_count() > 0);
        return t;
    };
    double alone = 1e9, mostly = 1e9;
    for (int run = 0; run < (kOptimized ? 3 : 1); ++run) {
        alone = std::min(alone, timed(false));
        mostly = std::min(mostly, timed(true));
    }
    std::printf("[asleep] %d asleep + 20 awake: %.2f ms/step, the 20 alone: %.2f ms/step (ratio %.1f)\n", pileSize,
                mostly * 1000.0 / kSteps, alone * 1000.0 / kSteps, mostly / std::max(alone, 1e-9));
    if (kOptimized) CHECK(mostly < 25.0 * alone + 0.01 * test_speed_budget_scale());
}

// The position pass after a time-of-impact stop only touches the islands that had the stop (M94.4e): a box resting on the
// ground, awake (nothing sleeps yet), keeps exactly the pose, velocity and contact state it has without the ball that
// hits a wall far away. Before, the pass ran for every body whenever any body had a stop.
TEST_CASE("3d asleep: a far time-of-impact stop does not move an awake box resting on the ground") {
    auto run = [](bool withBall, std::vector<std::uint32_t>& bits, bool& stopped, int& awakeSteps) {
        Sim s;
        add_static_box(s.world, {0, -0.5f, 0}, {200, 1, 200});
        Entity box = s.world.create();
        s.world.get<Transform>(box)->position = {0, 0.52f, 0};  // 2 cm above the ground: it lands and settles
        s.world.add<Collider3D>(box).size = {1, 1, 1};
        s.world.add<RigidBody3D>(box);
        Entity ball{};
        if (withBall) {
            add_static_box(s.world, {50, 5, 0}, {0.2f, 10, 10});  // the wall
            ball = s.world.create();
            s.world.get<Transform>(ball)->position = {40, 3, 0};
            Collider3D& c = s.world.add<Collider3D>(ball);
            c.shape = ColliderShape3D::Sphere;
            c.radius = 0.5f;
            s.world.add<RigidBody3D>(ball).velocity = {150, 0, 0};  // 2.5 m per step: a sweep, not a contact
        }
        awakeSteps = 0;
        stopped = false;
        for (int i = 0; i < 30; ++i) {
            s.run(1);
            if (s.awake_count() > (withBall ? 1 : 0)) ++awakeSteps;  // the box is awake (the ball is not counted)
            const std::vector<std::uint32_t> now = state_bits(s.world, {box});
            bits.insert(bits.end(), now.begin(), now.end());
            if (withBall && s.world.get<RigidBody3D>(ball)->velocity.x < 100.0f) stopped = true;
        }
    };
    std::vector<std::uint32_t> alone, withBall;
    bool stoppedAlone = false, stopped = false;
    int awakeAlone = 0, awakeWith = 0;
    run(false, alone, stoppedAlone, awakeAlone);
    run(true, withBall, stopped, awakeWith);
    CHECK(stopped);  // the ball did hit the wall (its speed changed: a time-of-impact stop, then the contact)
    CHECK(awakeAlone > 5);  // the box was awake while the ball hit
    CHECK(alone == withBall);
}

// A force applied to a body that is disabled is dropped, and one applied just before it is disabled does not fire when the
// body is enabled again (the step clears the force of the awake bodies only).
TEST_CASE("3d asleep: a force on a disabled body does not wait for it to be enabled") {
    for (int how = 0; how < 2; ++how) {
        Sim s;
        Entity e = s.world.create();
        s.world.add<Collider3D>(e).size = {1, 1, 1};
        s.world.add<RigidBody3D>(e).gravityScale = 0.0f;
        s.run(2);
        if (how == 0) {  // disabled when the force comes
            s.world.set_active(e, false);
            s.run(1);
            s.physics.apply_force(s.world, e, {0, 5000.0f, 0});
        } else {  // disabled after the force came, before the step
            s.physics.apply_force(s.world, e, {0, 5000.0f, 0});
            s.world.set_active(e, false);
        }
        s.run(5);
        s.world.set_active(e, true);
        s.run(3);
        INFO("how " << how);
        CHECK(s.world.get<RigidBody3D>(e)->velocity.y == 0.0f);
        CHECK(s.world.world_position(e).y == 0.0f);
    }
}
