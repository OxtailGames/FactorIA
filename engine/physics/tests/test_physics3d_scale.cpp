// 3D physics at scale (M94.4a): acceptance tests for the broadphase, the flat containers and the multi-point manifolds
// that follow. They state what the engine must keep doing with 100 stacked boxes and 1000 bodies in a pit: come to
// rest, fall asleep, cost little and give the same bits whatever the job threads setting.
// Budgets are CPU time (fa::process_cpu_seconds), generous, and the heavy ones only count in an optimized build.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "fa/core/hash.h"
#include "fa/core/jobs.h"
#include "fa/core/perf.h"
#include "fa/core/math.h"
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
    w.add<Collider3D>(e).size = size;  // no RigidBody3D: static
    return e;
}

Entity add_box(World& w, Vec3 pos, Vec3 size = {1, 1, 1}) {
    Entity e = w.create();
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    w.add<RigidBody3D>(e);
    return e;
}

// Horizontal distance of a body from where it started.
float drift_xz(const World& w, Entity e, Vec3 start) {
    const Vec3 p = w.world_position(e);
    return std::sqrt((p.x - start.x) * (p.x - start.x) + (p.z - start.z) * (p.z - start.z));
}

// `count` boxes dropped one per 1.02 m (a 2 cm gap each) on a static floor. Returns them bottom first.
std::vector<Entity> build_column(World& w, int count) {
    add_static_box(w, {0, -0.5f, 0}, {20, 1, 20});
    std::vector<Entity> out;
    for (int i = 0; i < count; ++i) out.push_back(add_box(w, {0, 0.5f + 1.02f * float(i), 0}));
    return out;
}

// A pit of four walls and a floor with `n` bodies (sphere, capsule, box in turn) in layers of 10 x 10 above it.
void build_pit(World& w, int n) {
    add_static_box(w, {0, -0.5f, 0}, {30, 1, 30});
    add_static_box(w, {-15.5f, 5, 0}, {1, 12, 32});
    add_static_box(w, {15.5f, 5, 0}, {1, 12, 32});
    add_static_box(w, {0, 5, -15.5f}, {32, 12, 1});
    add_static_box(w, {0, 5, 15.5f}, {32, 12, 1});
    Rng rng(94);
    const int perLayer = 100;
    for (int i = 0; i < n; ++i) {
        const int layer = i / perLayer, k = i % perLayer;
        const Vec3 pos{-6.3f + 1.4f * float(k % 10) + 0.01f * float(rng.next_u32() % 20), 0.8f + 1.3f * float(layer),
                       -6.3f + 1.4f * float(k / 10) + 0.01f * float(rng.next_u32() % 20)};
        Entity e = w.create();
        w.get<Transform>(e)->position = pos;
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

void feed(Sha256& h, Vec3 v) {
    const float f[3] = {v.x, v.y, v.z};
    h.update(f, sizeof f);
}

std::string run_pit_hash(int threads, int n, int frames) {
    const jobs::Settings s = threads < 0 ? jobs::Settings::inline_jobs() : jobs::Settings::threads(threads);
    REQUIRE(jobs::start(s));
    std::string out;
    {
        Sim sim;
        build_pit(sim.world, n);
        Sha256 h;
        const std::vector<Entity> all = sim.world.entities();
        for (int f = 0; f < frames; ++f) {
            sim.run(1);
            if (f % 5 == 4) {
                for (Entity e : all) {
                    const RigidBody3D* rb = sim.world.get<RigidBody3D>(e);
                    if (!rb) continue;
                    feed(h, sim.world.get<Transform>(e)->position);
                    feed(h, sim.world.get<Transform>(e)->rotation);
                    feed(h, rb->velocity);
                }
            }
        }
        out = h.finish_hex().substr(0, 16);
    }
    jobs::stop();
    return out;
}

}  // namespace

// Today (before the broadphase and manifold packages) the stack and pit tests below fail: the solver does not keep a pile
// of 100 boxes together nor put a big pile to sleep, and a pit of 1000 bodies costs more than the budget. They are
// `may_fail` so the suite stays green; the package that fixes each removes the decorator. doctest counts a may_fail test
// that passes as a pass, so nothing breaks if one starts to work earlier.

// A column of 100 boxes (2 cm gap each) on a floor. The per-box checks run on a count, so a collapse prints one line.
TEST_CASE("3d scale: a column of 100 boxes comes to rest, asleep, without collapsing" * doctest::may_fail(true)) {
    Sim s;
    const std::vector<Entity> boxes = build_column(s.world, 100);
    const double t0 = process_cpu_seconds();
    int steps = 0;
    while (steps < 60 * 10 && (steps < 10 || s.awake_count() > 0)) {
        s.run(20);
        steps += 20;
    }
    const double cpu = process_cpu_seconds() - t0;
    int misplaced = 0;
    for (std::size_t i = 0; i < boxes.size(); ++i) {  // none fell off, none sank into the floor or the box below
        const Vec3 p = s.world.world_position(boxes[i]);
        if (std::fabs(p.x) > 1.0f || std::fabs(p.z) > 1.0f || p.y < 0.45f + 0.99f * float(i) ||
            p.y > 0.5f + 1.1f * float(i))
            ++misplaced;
    }
    std::printf("[scale] column100: %d steps, awake %d, misplaced %d, top drift %.3f m, top y %.2f, cpu %.2f s\n",
                steps, s.awake_count(), misplaced, double(drift_xz(s.world, boxes.back(), {0, 0, 0})),
                double(s.world.world_position(boxes.back()).y), cpu);
    CHECK(misplaced == 0);
    CHECK(drift_xz(s.world, boxes.back(), {0, 0, 0}) < 0.5f);
    CHECK(s.awake_count() == 0);
    if (kOptimized) CHECK(cpu < 8.0 * test_speed_budget_scale());
}

// The second shape: a 5 x 5 x 4 block (100 boxes in 4 layers of 5 x 5): wide, so many contacts per box.
TEST_CASE("3d scale: a 5x5x4 block of 100 boxes comes to rest, asleep, and keeps its shape" * doctest::may_fail(true)) {
    Sim s;
    add_static_box(s.world, {0, -0.5f, 0}, {20, 1, 20});
    std::vector<Entity> boxes;
    std::vector<Vec3> start;
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 5; ++x)
            for (int z = 0; z < 5; ++z) {
                const Vec3 p{1.02f * float(x - 2), 0.5f + 1.02f * float(y), 1.02f * float(z - 2)};
                boxes.push_back(add_box(s.world, p));
                start.push_back(p);
            }
    int steps = 0;
    while (steps < 60 * 10 && (steps < 10 || s.awake_count() > 0)) {
        s.run(20);
        steps += 20;
    }
    float worst = 0;
    int low = 0;
    for (std::size_t i = 0; i < boxes.size(); ++i) {
        worst = std::max(worst, drift_xz(s.world, boxes[i], start[i]));
        if (s.world.world_position(boxes[i]).y < 0.45f) ++low;
    }
    std::printf("[scale] block5x5x4: %d steps, awake %d, worst drift %.3f m, sunk %d\n", steps, s.awake_count(),
                double(worst), low);
    CHECK(worst < 0.3f);
    CHECK(low == 0);
    CHECK(s.awake_count() == 0);
}

// The budget of the broad phase: 1000 mixed bodies from the drop (the busiest steps: every body falls, then the first
// impacts). The time of a step grows with the bodies near each other, not with every pair: a pit of 1000 bodies costs about
// 6 times a pit of 250 (the same layers, a quarter as tall), where a candidate list of every pair (the old solver's
// loops) costs about 16 times. The test checks that RATIO, measured in the same process (the faster of two runs of each, so a busy machine does
// not matter), and only a loose absolute bound: a CI VM can be several times slower than a laptop, which a number of
// milliseconds cannot know. Debug builds only run a short stretch and print; sanitizer and coverage builds are far slower
// than the scale of test_speed_budget_scale() knows, so only optimized builds check.
TEST_CASE("3d scale: 1000 bodies falling into a walled pit stay within a CPU budget") {
    const int kSteps =
        kOptimized ? 20 : 10;        // the first layer is 0.3 m above the floor: impacts start at about step 10
    auto pit_ms = [&](int bodies) {  // ms per step of the stretch, the faster of two runs
        double best = 1e30;
        for (int run = 0; run < (kOptimized ? 2 : 1); ++run) {
            Sim s;
            build_pit(s.world, bodies);
            s.run(1);  // the bodies exist after the first step
            const double t0 = process_cpu_seconds();
            s.run(kSteps);
            best = std::min(best, (process_cpu_seconds() - t0) * 1000.0 / double(kSteps));
        }
        return best;
    };
    const double small = pit_ms(250), big = pit_ms(1000);
    std::printf("[scale] pit1000: %d steps from the drop, %.2f ms/step CPU (pit250 %.2f ms/step, ratio %.1f)\n", kSteps,
                big, small, big / small);
    if (kOptimized) {
        CHECK(big / small < 10.0);
        CHECK(big < 120.0 * test_speed_budget_scale());
    }
}

// Release only (a settled Debug run of 1000 bodies takes minutes today): the pit comes to rest, every body asleep, and a
// step of sleeping bodies costs almost nothing.
TEST_CASE("3d scale: 1000 bodies in a walled pit settle asleep and then cost almost nothing" *
          doctest::may_fail(true)) {
    // Opt in (FA_PHYSICS_SCALE_SETTLE=1, an optimized build) until the broadphase package makes it cheap: today it runs
    // minutes. That package removes this line.
    if (!kOptimized || !std::getenv("FA_PHYSICS_SCALE_SETTLE")) return;
    Sim s;
    build_pit(s.world, 1000);
    s.run(1);
    int steps = 1;
    while (steps < 60 * 20 && (steps < 60 || s.awake_count() > 0)) {
        s.run(30);
        steps += 30;
    }
    int outside = 0;
    for (const Entity e : s.world.entities()) {
        if (!s.world.get<RigidBody3D>(e)) continue;
        const Vec3 p = s.world.world_position(e);
        if (p.y < -0.1f || std::fabs(p.x) > 15.0f || std::fabs(p.z) > 15.0f) ++outside;
    }
    const int awake = s.awake_count();
    const double t1 = process_cpu_seconds();
    s.run(60);
    const double nextMs = (process_cpu_seconds() - t1) * 1000.0 / 60.0;
    std::printf("[scale] pit1000 settle: %d steps, awake %d, outside %d, next step %.3f ms CPU\n", steps, awake,
                outside, nextMs);
    CHECK(outside == 0);
    CHECK(awake == 0);
    if (awake == 0) CHECK(nextMs < 1.0 * test_speed_budget_scale());
}

TEST_CASE("3d scale: a pit of 300 bodies gives the same hash inline and with 1 and 4 job threads") {
    const int n = 300, frames = kOptimized ? 60 : 20;
    const std::string reference = run_pit_hash(-1, n, frames);
    CHECK(run_pit_hash(1, n, frames) == reference);
    CHECK(run_pit_hash(4, n, frames) == reference);
}
