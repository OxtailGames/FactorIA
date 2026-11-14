// 3D physics at scale (M94.4a): acceptance tests for the broadphase, the flat containers and the multi-point manifolds
// that follow. They state what the engine must keep doing with 100 stacked boxes and 1000 bodies in a pit: come to
// rest, fall asleep, cost little and give the same bits whatever the job threads setting.
// Budgets are CPU time (fa::process_cpu_seconds), generous, and the heavy ones only count in an optimized build.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
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

// A column of N boxes (2 cm gap each) on a floor, run until everything sleeps. A tall column is an inverted pendulum
// (any lean of the stack grows by a factor e every ~1.7 s), so it only stands if the solver treats the points of a contact
// alike and its contacts are soft enough to settle without bouncing; the contacts then sag a little under the weight (about
// 1.5 cm per joint at the bottom of 100 boxes, 0.8% of the height overall), which the checks allow for.
struct ColumnResult {
    int steps = 0, awake = 0, misplaced = 0;
    float drift = 0, topY = 0;
    double cpu = 0;
};
ColumnResult run_column(int count, int maxSteps) {
    Sim s;
    const std::vector<Entity> boxes = build_column(s.world, count);
    const double t0 = process_cpu_seconds();
    ColumnResult r;
    while (r.steps < maxSteps && (r.steps < 10 || s.awake_count() > 0)) {
        s.run(20);
        r.steps += 20;
    }
    r.cpu = process_cpu_seconds() - t0;
    r.awake = s.awake_count();
    float below = -0.5f;  // the height of the box below (the floor's top is y = 0: the first box rests at 0.5)
    for (std::size_t i = 0; i < boxes.size(); ++i) {  // none fell off, none sank into the floor or the box below
        const Vec3 p = s.world.world_position(boxes[i]);
        const float gap = p.y - below - 1.0f;  // 0 for boxes in touch
        below = p.y;
        if (std::fabs(p.x) > 0.1f || std::fabs(p.z) > 0.1f || gap < -0.03f || gap > 0.03f) ++r.misplaced;
    }
    r.drift = drift_xz(s.world, boxes.back(), {0, 0, 0});
    r.topY = s.world.world_position(boxes.back()).y;
    return r;
}

// A column of 100 boxes (2 cm gap each) on a floor. The per-box checks run on a count, so a collapse prints one line.
// It sleeps after about 260 steps (4.3 s): the limit is 3.5 times that.
TEST_CASE("3d scale: a column of 100 boxes comes to rest, asleep, without collapsing") {
    const ColumnResult r = run_column(100, 60 * 15);
    std::printf("[scale] column100: %d steps, awake %d, misplaced %d, top drift %.3f m, top y %.2f, cpu %.2f s\n",
                r.steps, r.awake, r.misplaced, double(r.drift), double(r.topY), r.cpu);
    CHECK(r.misplaced == 0);
    CHECK(r.drift < 0.05f);
    CHECK(r.topY > 98.0f);  // 99.5 without any sag; the sag is under 1.5%
    CHECK(r.awake == 0);
    if (kOptimized) CHECK(r.cpu < 1.5 * test_speed_budget_scale());  // 0.13 s measured: 11x the margin
}

// The column of 50: it used to lean a few degrees and keep moving.
TEST_CASE("3d scale: a column of 50 boxes stands straight and falls asleep") {
    const ColumnResult r = run_column(50, 60 * 10);  // sleeps in about 140 steps: 4x the margin
    std::printf("[scale] column50: %d steps, awake %d, misplaced %d, top drift %.3f m, top y %.2f\n", r.steps, r.awake,
                r.misplaced, double(r.drift), double(r.topY));
    CHECK(r.misplaced == 0);
    CHECK(r.drift < 0.05f);
    CHECK(r.awake == 0);
}

// The second shape: a 5 x 5 x 4 block (100 boxes in 4 layers of 5 x 5): wide, so many contacts per box.
TEST_CASE("3d scale: a 5x5x4 block of 100 boxes comes to rest, asleep, and keeps its shape") {
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
    while (steps < 200 && (steps < 10 || s.awake_count() > 0)) {  // it sleeps after about 40 steps: 5x the margin
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
// 6 times a pit of 250 (the same layers, a quarter as tall), where a candidate list of every pair (the old solver's loops)
// costs about 16 times. The test checks that RATIO, measured in the same process (the faster of two runs of each, so a
// busy machine does not matter), and only a loose absolute bound: a CI VM can be several times slower than a laptop,
// which a number of milliseconds cannot know. A non-optimized build runs the same short stretch once and prints it;
// sanitizer and coverage builds are far slower than the scale of test_speed_budget_scale() knows, so only optimized
// builds check.
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

// Optimized builds only (a settled Debug run of 1000 bodies takes minutes): the pit comes to rest, every body asleep,
// and a step of sleeping bodies costs almost nothing (the sync only: no sub-steps, no broad phase). The pile is asleep
// after about 1560 steps (a Release run measured 65 s of CPU on an M-series laptop, almost all of it the awake steps of
// the creep: a pile of 1000 bodies keeps a few bodies above the sleep speed for a long while, and one awake body keeps
// its island awake). The limit of 5400 steps (90 s of simulated time) is 3.5 times that.
TEST_CASE("3d scale: 1000 bodies in a walled pit settle asleep and then cost almost nothing") {
    if (!kOptimized) return;
    Sim s;
    build_pit(s.world, 1000);
    s.run(1);
    int steps = 1;
    while (steps < 60 * 90 && (steps < 60 || s.awake_count() > 0)) {
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
    CHECK(nextMs < 2.0 * test_speed_budget_scale());  // 0.4 ms measured: 5x the margin
}

TEST_CASE("3d scale: a pit of 300 bodies gives the same hash inline and with 1 and 4 job threads") {
    const int n = 300, frames = kOptimized ? 60 : 20;
    const std::string reference = run_pit_hash(-1, n, frames);
    CHECK(run_pit_hash(1, n, frames) == reference);
    CHECK(run_pit_hash(4, n, frames) == reference);
}
