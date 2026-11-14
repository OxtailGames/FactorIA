// Heightfield colliders in the 3D physics (M94.4f): a grid of heights is static terrain. Bodies rest, roll and slide on it
// without bumps at the triangle seams, holes let them through, the queries see it, an edit costs what it touches and wakes
// only the sleeping bodies near it, and the result is the same with any number of job threads.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <functional>
#include <string>
#include <utility>
#include <vector>

#include "../src/heightfield3d.h"
#include "fa/core/hash.h"
#include "fa/core/jobs.h"
#include "fa/core/perf.h"
#include "fa/physics/physics.h"

using namespace fa;
using namespace fa::detail;

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
            if (j.value("awake", false)) ++n;
        return n;
    }
    bool awake(Entity e) const {
        const std::string id = world.id_of(e);
        for (const Json& j : physics.debug_state(world))
            if (j.value("entity", std::string()) == id) return j.value("awake", false);
        return false;
    }
    Vec3 pos(Entity e) { return world.get<Transform>(e)->position; }
};

using HeightFn = std::function<float(float, float)>;

// A component for a rows x columns grid whose sample (r, c) is fn(x, z) at the world x and z the grid puts it (centred).
Heightfield3D make_component(int rows, int cols, float cell, const HeightFn& fn) {
    Heightfield3D g;
    g.rows = rows;
    g.columns = cols;
    g.cellSize = {cell, cell};
    std::vector<float> h(std::size_t(rows) * std::size_t(cols));
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < cols; ++c)
            h[std::size_t(r) * std::size_t(cols) + std::size_t(c)] =
                fn((float(c) - 0.5f * float(cols - 1)) * cell, (float(r) - 0.5f * float(rows - 1)) * cell);
    g.heights.assign(h.data(), h.size());
    return g;
}

void copy_into(Heightfield3D& dst, const Heightfield3D& src) {
    dst.rows = src.rows;
    dst.columns = src.columns;
    dst.cellSize = src.cellSize;
    dst.heightScale = src.heightScale;
    dst.heightOffset = src.heightOffset;
    dst.heights.assign(src.heights.cdata(), src.heights.size());
    dst.holes.assign(src.holes.cdata(), src.holes.size());
}

Entity add_field(World& w, const char* id, const Heightfield3D& comp, Vec3 pos = {0, 0, 0}, float friction = 0.4f) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Heightfield;
    c.friction = friction;
    copy_into(w.add<Heightfield3D>(e), comp);
    return e;
}

Entity add_field(World& w, const char* id, int rows, int cols, float cell, const HeightFn& fn, Vec3 pos = {0, 0, 0},
                 float friction = 0.4f) {
    return add_field(w, id, make_component(rows, cols, cell, fn), pos, friction);
}

Entity add_sphere(World& w, const char* id, Vec3 p, float r = 0.4f, bool lock = false, float friction = 0.4f) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = p;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Sphere;
    c.radius = r;
    c.friction = friction;
    RigidBody3D& rb = w.add<RigidBody3D>(e);
    rb.lockRotation = lock;
    if (lock) rb.rollWithMotion = false;
    return e;
}

Entity add_box(World& w, const char* id, Vec3 p, Vec3 size = {0.8f, 0.8f, 0.8f}, bool lock = false,
               float friction = 0.4f) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = p;
    Collider3D& c = w.add<Collider3D>(e);
    c.size = size;
    c.friction = friction;
    w.add<RigidBody3D>(e).lockRotation = lock;
    return e;
}

Entity add_capsule(World& w, const char* id, Vec3 p, float r = 0.3f, float height = 1.2f, bool lock = false) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = p;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Capsule;
    c.radius = r;
    c.height = height;
    w.add<RigidBody3D>(e).lockRotation = lock;
    return e;
}

bool any_problem_has(const Physics& p, const std::string& needle) {
    for (const std::string& s : p.problems3d())
        if (s.find(needle) != std::string::npos) return true;
    return false;
}

// Deterministic noise in [0, 1).
struct Lcg {
    std::uint32_t s;
    explicit Lcg(std::uint32_t seed) : s(seed) {}
    float next() {
        s = s * 1664525u + 1013904223u;
        return float(s >> 8) / 16777216.0f;
    }
};

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

}  // namespace

TEST_CASE("heightfield3d: a grid that cannot be used is reported with the fix and has no collider") {
    auto falls_through = [](Sim& s, Entity ball) {
        s.run(90);
        return s.pos(ball).y < -2.0f;
    };
    {  // heights of the wrong length
        Sim s;
        Entity f = add_field(s.world, "field", 3, 3, 1.0f, [](float, float) { return 0.0f; });
        const float few[5] = {0, 0, 0, 0, 0};
        s.world.get<Heightfield3D>(f)->heights.assign(few, 5);
        Entity ball = add_sphere(s.world, "ball", {0, 2, 0});
        CHECK(falls_through(s, ball));
        CHECK(any_problem_has(s.physics, "Heightfield3D.heights has 5 numbers"));
        CHECK(any_problem_has(s.physics, "rows * columns = 3 * 3 = 9"));
    }
    {  // a sample that is not a number: named by index, row and column
        Sim s;
        Entity f = add_field(s.world, "field", 4, 5, 1.0f, [](float, float) { return 0.0f; });
        s.world.get<Heightfield3D>(f)->heights.set(7, std::nanf(""));
        Entity ball = add_sphere(s.world, "ball", {0, 2, 0});
        CHECK(falls_through(s, ball));
        CHECK(any_problem_has(s.physics, "Heightfield3D.heights[7]"));
        CHECK(any_problem_has(s.physics, "finite number"));
    }
    {  // too few samples
        Sim s;
        Entity f = add_field(s.world, "field", 3, 3, 1.0f, [](float, float) { return 0.0f; });
        s.world.get<Heightfield3D>(f)->rows = 1;
        Entity ball = add_sphere(s.world, "ball", {0, 2, 0});
        CHECK(falls_through(s, ball));
        CHECK(any_problem_has(s.physics, "Heightfield3D.rows = 1"));
    }
    {  // holes of the wrong length
        Sim s;
        Entity f = add_field(s.world, "field", 5, 5, 1.0f, [](float, float) { return 0.0f; });
        const std::uint8_t holes[3] = {0, 1, 0};
        s.world.get<Heightfield3D>(f)->holes.assign(holes, 3);
        Entity ball = add_sphere(s.world, "ball", {0, 2, 0});
        CHECK(falls_through(s, ball));
        CHECK(any_problem_has(s.physics, "Heightfield3D.holes has 3 numbers"));
    }
    {  // no Heightfield3D at all
        Sim s;
        Entity f = s.world.create("field", "field");
        s.world.add<Collider3D>(f).shape = ColliderShape3D::Heightfield;
        Entity ball = add_sphere(s.world, "ball", {0, 2, 0});
        CHECK(falls_through(s, ball));
        CHECK(any_problem_has(s.physics, "no Heightfield3D component"));
    }
    {  // a moving body cannot be a heightfield
        Sim s;
        Entity f = add_field(s.world, "field", 3, 3, 1.0f, [](float, float) { return 0.0f; });
        s.world.add<RigidBody3D>(f);
        Entity ball = add_sphere(s.world, "ball", {0, 2, 0});
        (void)ball;
        s.run(2);
        CHECK(any_problem_has(s.physics, "static terrain"));
    }
    {  // fixing the data brings the collider back
        Sim s;
        Entity f = add_field(s.world, "field", 3, 3, 4.0f, [](float, float) { return 0.0f; });
        s.world.get<Heightfield3D>(f)->heights.set(4, std::nanf(""));
        Entity ball = add_sphere(s.world, "ball", {0, 1, 0});
        s.run(2);
        CHECK(!s.physics.problems3d().empty());
        s.world.get<Heightfield3D>(f)->heights.set(4, 0.0f);
        s.run(120);
        CHECK(s.pos(ball).y == doctest::Approx(0.4f).epsilon(0.1));
        CHECK(s.physics.problems3d().empty());
    }
}

TEST_CASE("heightfield3d: boxes, spheres and capsules rest on a flat field and fall asleep on it") {
    Sim s;
    add_field(s.world, "field", 41, 41, 1.0f, [](float, float) { return 0.0f; });
    std::vector<Entity> balls, boxes, capsules;
    for (int i = 0; i < 6; ++i) {
        const std::string n = std::to_string(i);
        balls.push_back(add_sphere(s.world, ("s" + n).c_str(), {-8.0f + 3.1f * float(i), 0.6f, -4.3f + 0.37f * float(i)}));
        boxes.push_back(add_box(s.world, ("b" + n).c_str(), {-8.0f + 3.1f * float(i), 0.6f, 0.2f + 0.41f * float(i)}));
        capsules.push_back(add_capsule(s.world, ("c" + n).c_str(), {-8.0f + 3.1f * float(i), 0.9f, 4.7f - 0.2f * float(i)}));
    }
    s.run(420);
    CHECK(s.awake_count() == 0);
    for (Entity e : balls) CHECK(s.pos(e).y == doctest::Approx(0.4f).epsilon(0.05));
    for (Entity e : boxes) CHECK(s.pos(e).y == doctest::Approx(0.4f).epsilon(0.05));
    for (Entity e : capsules) CHECK(s.pos(e).y == doctest::Approx(0.6f).epsilon(0.05));
}

TEST_CASE("heightfield3d: boxes, spheres and capsules rest on a gentle slope held by friction and fall asleep") {
    constexpr float kSlope = 0.15f;
    Sim s;
    add_field(s.world, "field", 41, 41, 1.0f, [](float x, float) { return kSlope * x; }, {0, 0, 0}, 0.8f);
    std::vector<Entity> all;
    for (int i = 0; i < 5; ++i) {
        const std::string n = std::to_string(i);
        const float x = -6.0f + 3.0f * float(i);
        const float top = kSlope * x;
        all.push_back(add_sphere(s.world, ("s" + n).c_str(), {x, top + 0.8f, -4.0f}, 0.4f, true, 0.8f));
        all.push_back(add_box(s.world, ("b" + n).c_str(), {x, top + 1.0f, 0.0f}, {0.8f, 0.8f, 0.8f}, true, 0.8f));
        all.push_back(add_capsule(s.world, ("c" + n).c_str(), {x, top + 1.0f, 4.0f}, 0.3f, 1.2f, true));
    }
    s.run(540);
    CHECK(s.awake_count() == 0);
    for (int i = 0; i < 5; ++i) {
        const Vec3 p = s.pos(all[std::size_t(i) * 3]);
        const float dist = (p.y - kSlope * p.x) / std::sqrt(1.0f + kSlope * kSlope);
        CHECK(dist == doctest::Approx(0.4f).epsilon(0.08));
    }
}

TEST_CASE("heightfield3d: a ball rolls down a slope and follows the surface") {
    constexpr float kSlope = 0.3f;
    Sim s;
    add_field(s.world, "field", 61, 61, 1.0f, [](float x, float z) { return -kSlope * x + 0.02f * z; });
    Entity ball = add_sphere(s.world, "ball", {-12.0f, 0.3f * 12.0f + 0.5f, 0.0f});
    const float startX = s.pos(ball).x;
    float worst = 0.0f;
    for (int i = 0; i < 240; ++i) {
        s.run(1);
        if (i < 30) continue;
        const Vec3 p = s.pos(ball);
        const float nl = std::sqrt(kSlope * kSlope + 1.0f + 0.02f * 0.02f);
        const float dist = (p.y + kSlope * p.x - 0.02f * p.z) / nl;
        worst = std::max(worst, std::fabs(dist - 0.4f));
    }
    CHECK(s.pos(ball).x > startX + 6.0f);
    CHECK(worst < 0.06f);
}

TEST_CASE("heightfield3d: nothing bumps at the seams between triangles") {
    {  // flat field, no friction: the velocity and height of a sliding box and ball never change
        Sim s;
        add_field(s.world, "field", 61, 61, 1.0f, [](float, float) { return 0.0f; }, {0, 0, 0}, 0.0f);
        Entity box = add_box(s.world, "box", {-20.0f, 0.4f, 0.3f}, {0.8f, 0.8f, 0.8f}, true, 0.0f);
        Entity ball = add_sphere(s.world, "ball", {-20.0f, 0.4f, -3.7f}, 0.4f, true, 0.0f);
        s.world.get<RigidBody3D>(box)->velocity = {6.0f, 0, 0};
        s.world.get<RigidBody3D>(ball)->velocity = {6.0f, 0, 0.5f};
        s.run(20);
        float worstV = 0.0f, worstY = 0.0f;
        for (int i = 0; i < 300; ++i) {
            s.run(1);
            for (Entity e : {box, ball}) {
                const RigidBody3D* rb = s.world.get<RigidBody3D>(e);
                worstV = std::max(worstV, std::fabs(rb->velocity.x - 6.0f));
                worstV = std::max(worstV, std::fabs(rb->velocity.y));
                worstY = std::max(worstY, std::fabs(s.pos(e).y - 0.4f));
            }
        }
        CHECK(s.pos(box).x > 10.0f);
        CHECK(worstV < 0.02f);
        CHECK(worstY < 0.005f);
    }
    {  // a plane tilted across the diagonal of the cells: the velocity stays in the plane
        Sim s;
        add_field(s.world, "field", 81, 81, 1.0f, [](float x, float z) { return 0.1f * x - 0.05f * z; }, {0, 0, 0}, 0.0f);
        Entity box = add_box(s.world, "box", {12.0f, 1.32f, 7.0f}, {0.8f, 0.8f, 0.8f}, true, 0.0f);
        Entity ball = add_sphere(s.world, "ball", {12.0f, 1.48f, 3.0f}, 0.4f, true, 0.0f);
        const Vec3 n = normalize(Vec3{-0.1f, 1.0f, 0.05f});
        float worst = 0.0f;
        for (int i = 0; i < 300; ++i) {
            s.run(1);
            if (i < 20) continue;
            for (Entity e : {box, ball}) worst = std::max(worst, std::fabs(dot(s.world.get<RigidBody3D>(e)->velocity, n)));
        }
        CHECK(s.pos(box).x < 12.0f - 3.0f);
        CHECK(s.pos(ball).x < 12.0f - 3.0f);
        CHECK(worst < 0.03f);
    }
}

TEST_CASE("heightfield3d: a body falls through a hole and is held next to it") {
    Sim s;
    Heightfield3D comp = make_component(21, 21, 1.0f, [](float, float) { return 0.0f; });
    std::vector<std::uint8_t> holes(20 * 20, 0);
    for (int r = 8; r <= 10; ++r)
        for (int c = 8; c <= 10; ++c) holes[std::size_t(r) * 20 + std::size_t(c)] = 1;  // x and z in [-2, 1]
    comp.holes.assign(holes.data(), holes.size());
    add_field(s.world, "field", comp);
    Entity over = add_sphere(s.world, "over", {-0.5f, 2.0f, -0.5f});
    Entity beside = add_sphere(s.world, "beside", {-2.6f, 2.0f, -0.5f});
    Entity far = add_sphere(s.world, "far", {6.0f, 2.0f, 0.0f});
    Entity box = add_box(s.world, "box", {1.6f, 2.0f, 1.6f});
    s.run(180);
    CHECK(s.pos(over).y < -3.0f);
    CHECK(s.pos(beside).y == doctest::Approx(0.4f).epsilon(0.1));
    CHECK(s.pos(far).y == doctest::Approx(0.4f).epsilon(0.1));
    CHECK(s.pos(box).y == doctest::Approx(0.4f).epsilon(0.1));
}

namespace {
Heightfield3D bumpy_component(int rows, int cols, float cx, float cz, bool withHoles) {
    Heightfield3D g;
    g.rows = rows;
    g.columns = cols;
    g.cellSize = {cx, cz};
    g.heightScale = 2.0f;
    g.heightOffset = -1.0f;
    Lcg rng(12345);
    std::vector<float> h(std::size_t(rows) * std::size_t(cols));
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < cols; ++c)
            h[std::size_t(r) * std::size_t(cols) + std::size_t(c)] =
                0.5f + 0.5f * std::sin(0.7f * float(c)) * std::cos(0.5f * float(r)) + 0.3f * rng.next();
    g.heights.assign(h.data(), h.size());
    if (withHoles) {
        std::vector<std::uint8_t> holes(std::size_t(rows - 1) * std::size_t(cols - 1));
        for (auto& v : holes) v = rng.next() < 0.1f ? 1 : 0;
        g.holes.assign(holes.data(), holes.size());
    }
    return g;
}
}  // namespace

TEST_CASE("heightfield3d: the grid walk finds what testing every triangle finds") {
    for (const bool withHoles : {false, true}) {
        Heightfield3D comp = bumpy_component(33, 40, 0.7f, 1.3f, withHoles);
        HeightfieldShape f;
        HeightfieldEdit edit;
        REQUIRE(update_heightfield(f, "t", comp, edit).empty());
        CHECK(f.valid);
        Lcg rng(777);
        int hits = 0, misses = 0;
        const float halfX = 0.5f * float(comp.columns - 1) * 0.7f, halfZ = 0.5f * float(comp.rows - 1) * 1.3f;
        for (int i = 0; i < 400; ++i) {
            Vec3 o{(rng.next() * 2 - 1) * halfX * 1.3f, rng.next() * 7.0f - 1.5f, (rng.next() * 2 - 1) * halfZ * 1.3f};
            Vec3 d{rng.next() * 2 - 1, -0.05f - rng.next(), rng.next() * 2 - 1};
            if (i % 4 == 1) d = {1.0f, 0.0f, 0.0f};      // along a row
            else if (i % 4 == 2) d = {0.0f, 0.0f, -1.0f};  // along a column
            else if (i % 4 == 3) d = {0.0f, -1.0f, 0.0f};  // straight down
            d = normalize(d);
            float t1 = 0, t2 = 0;
            Vec3 n1{}, n2{};
            const bool a = ray_heightfield(f, o, d, 60.0f, t1, n1);
            const bool b = ray_heightfield_brute(f, o, d, 60.0f, t2, n2);
            CHECK(a == b);
            if (a && b) {
                ++hits;
                CHECK(t1 == doctest::Approx(t2).epsilon(1e-4));
                CHECK(dot(n1, n2) > 0.999f);
            } else {
                ++misses;
            }
        }
        CHECK(hits > 50);
        CHECK(misses > 5);
    }
}

TEST_CASE("heightfield3d: raycast, raycast_all, overlap_sphere and shape_cast see the field") {
    Sim s;
    const Heightfield3D comp = bumpy_component(33, 40, 0.7f, 1.3f, true);
    Entity field = add_field(s.world, "field", comp, {3.0f, 1.0f, -2.0f});
    s.world.get<Transform>(field)->scale = {2.0f, 2.0f, 2.0f};
    s.physics.sync(s.world);

    Heightfield3D copy = comp;
    HeightfieldShape f;
    HeightfieldEdit edit;
    REQUIRE(update_heightfield(f, "t", copy, edit).empty());

    Lcg rng(99);
    int agree = 0;
    for (int i = 0; i < 120; ++i) {
        const Vec3 o{3.0f + (rng.next() * 2 - 1) * 20.0f, 12.0f, -2.0f + (rng.next() * 2 - 1) * 30.0f};
        float t = 0;
        Vec3 n{};
        const Vec3 modelOrigin = (o - Vec3{3.0f, 1.0f, -2.0f}) / 2.0f;
        const bool expected = ray_heightfield_brute(f, modelOrigin, Vec3{0, -1, 0} / 2.0f, 100.0f, t, n);
        const auto hit = s.physics.raycast3d(s.world, o, {0, -1, 0}, 100.0f);
        CHECK(hit.has_value() == expected);
        if (hit && expected) {
            ++agree;
            CHECK(hit->entity == field);
            CHECK(hit->distance == doctest::Approx(t).epsilon(1e-4));
            CHECK(hit->point.y == doctest::Approx(o.y - t).epsilon(1e-4));
            CHECK(hit->normal.y > 0.0f);
            CHECK(length(hit->normal) == doctest::Approx(1.0f).epsilon(1e-3));
            const auto all = s.physics.raycast3d_all(s.world, o, {0, -1, 0}, 100.0f);
            REQUIRE(all.size() == 1);  // one hit per entity
            CHECK(all[0].distance == doctest::Approx(hit->distance));
        }
    }
    CHECK(agree > 50);

    // Find a column where the field is solid and use it for the volume queries.
    Vec3 top{};
    for (float x = -5.0f; x < 5.0f; x += 0.37f) {
        const auto h = s.physics.raycast3d(s.world, {x, 30, 0.2f}, {0, -1, 0}, 100.0f);
        if (h) {
            top = h->point;
            break;
        }
    }
    REQUIRE(top.y != 0.0f);
    CHECK(s.physics.overlap_sphere3d(s.world, top + Vec3{0, 0.3f, 0}, 0.5f).size() == 1);
    CHECK(s.physics.overlap_sphere3d(s.world, top + Vec3{0, 3.0f, 0}, 0.5f).empty());
    const auto cast = s.physics.shape_cast3d(s.world, CastShape{CastShape::Kind::Circle, 0.5f, {1, 1, 1}},
                                              top + Vec3{0, 6.0f, 0}, top - Vec3{0, 4.0f, 0});
    REQUIRE(cast.has_value());
    CHECK(cast->entity == field);
    CHECK(cast->distance > 5.0f);
    CHECK(cast->distance < 6.6f);
    CHECK(cast->normal.y > 0.2f);
    const auto boxCast = s.physics.shape_cast3d(s.world, CastShape{CastShape::Kind::Box, 0.5f, {1, 1, 1}},
                                                 top + Vec3{0, 6.0f, 0}, top - Vec3{0, 4.0f, 0});
    REQUIRE(boxCast.has_value());
    CHECK(boxCast->entity == field);
}

TEST_CASE("heightfield3d: a turned field turns its surface with it") {
    Sim s;
    Entity field = add_field(s.world, "field", 41, 41, 1.0f, [](float x, float) { return 0.5f * x; });
    s.physics.sync(s.world);
    const auto before = s.physics.raycast3d(s.world, {0, 20, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(before.has_value());
    CHECK(std::fabs(before->normal.x) == doctest::Approx(0.447f).epsilon(0.01));
    CHECK(std::fabs(before->normal.z) < 0.01f);
    s.world.get<Transform>(field)->rotation = {0, 90, 0};
    s.physics.sync(s.world);
    const auto after = s.physics.raycast3d(s.world, {0, 20, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(after.has_value());
    CHECK(std::fabs(after->normal.z) == doctest::Approx(0.447f).epsilon(0.01));
    CHECK(std::fabs(after->normal.x) < 0.01f);
}

TEST_CASE("heightfield3d: a character walks up a slope and stays on the ground") {
    constexpr float kSlope = 0.268f;  // 15 degrees
    Sim s;
    Entity field = add_field(s.world, "field", 61, 61, 1.0f, [](float x, float) { return kSlope * x; });
    Entity who = s.world.create("who", "who");
    s.world.get<Transform>(who)->position = {-10.0f, kSlope * -10.0f + 1.0f, 0.0f};
    s.world.add<CharacterController3D>(who);
    s.physics.sync(s.world);
    int ungrounded = 0;
    for (int i = 0; i < 150; ++i) {
        const auto r = s.physics.move_character(s.world, who, {0.06f, -0.2f, 0.0f});
        REQUIRE(r.has_value());
        if (i < 3) continue;
        if (!r->isGrounded || r->ground != field) ++ungrounded;
        const Vec3 p = r->position;
        CHECK(p.y - kSlope * p.x > 0.8f);
        CHECK(p.y - kSlope * p.x < 1.2f);
    }
    CHECK(ungrounded == 0);
    CHECK(s.pos(who).x > -10.0f + 6.0f);
}

TEST_CASE("heightfield3d: an edit wakes only the sleeping bodies near it and the rest keeps sleeping") {
    Sim s;
    Entity field = add_field(s.world, "field", 65, 65, 1.0f, [](float, float) { return 0.0f; });
    Entity near = add_sphere(s.world, "near", {0.5f, 0.45f, 0.5f}, 0.4f, true);
    Entity side = add_sphere(s.world, "side", {20.5f, 0.45f, 0.5f}, 0.4f, true);
    Entity far = add_sphere(s.world, "far", {-20.5f, 0.45f, 10.5f}, 0.4f, true);
    s.run(300);
    REQUIRE(s.awake_count() == 0);
    Heightfield3D* g = s.world.get<Heightfield3D>(field);

    // 1. raise the four corners of the cell under `near` by 0.3 m
    for (const std::size_t i : {32u * 65u + 32u, 32u * 65u + 33u, 33u * 65u + 32u, 33u * 65u + 33u}) g->heights.set(i, 0.3f);
    s.physics.sync(s.world);
    CHECK(s.awake(near));
    CHECK(!s.awake(side));
    CHECK(!s.awake(far));
    s.run(200);
    CHECK(s.pos(near).y > 0.5f);  // it stands on the new surface, not in it
    CHECK(s.awake_count() == 0);
    CHECK(s.pos(side).y == doctest::Approx(0.4f).epsilon(0.1));

    // 2. cut a hole under `side`: only it wakes, and it falls
    std::vector<std::uint8_t> holes(64 * 64, 0);
    holes[32 * 64 + 52] = 1;  // the cell x in [20, 21], z in [0, 1]
    g->holes.assign(holes.data(), holes.size());
    s.physics.sync(s.world);
    CHECK(s.awake(side));
    CHECK(!s.awake(near));
    CHECK(!s.awake(far));
    s.run(120);
    CHECK(s.pos(side).y < -2.0f);
    CHECK(s.pos(near).y > 0.5f);
    CHECK(!s.awake(near));
    CHECK(!s.awake(far));

    // 3. an edit that changes nothing wakes nothing
    g->heights.set(0, 0.0f);
    s.physics.sync(s.world);
    CHECK(!s.awake(far));
}

TEST_CASE("heightfield3d: one cell of a field of a million samples is edited well under a millisecond") {
    Sim s;
    constexpr int kSide = 1025;
    Entity field = add_field(s.world, "field", kSide, kSide, 0.5f, [](float x, float z) {
        return 0.4f * std::sin(0.13f * x) * std::cos(0.11f * z);
    });
    Entity ball = add_sphere(s.world, "ball", {40.0f, 3.0f, 40.0f}, 0.4f, true);
    s.run(300);  // the first sync reads the grid; the ball comes to rest and sleeps
    CHECK(!s.awake(ball));
    Heightfield3D* g = s.world.get<Heightfield3D>(field);

    constexpr int kEdits = 100;
    std::size_t at = 12345;
    const double t0 = process_cpu_seconds();
    for (int i = 0; i < kEdits; ++i) {
        at = (at * 7919u + 13u) % (std::size_t(kSide) * std::size_t(kSide));
        g->heights.set(at, 5.0f + float(i));
        s.physics.sync(s.world);
    }
    const double perEditMs = (process_cpu_seconds() - t0) * 1000.0 / kEdits;
    std::printf("heightfield3d: edit + sync of one sample in a %dx%d field: %.4f ms\n", kSide, kSide, perEditMs);
    if (kOptimized) CHECK(perEditMs < 1.0);  // measured ~0.01 ms; the margin is for a loaded 4-vCPU VM

    // the edit is really in the collider
    const std::size_t centre = std::size_t(kSide / 2) * kSide + std::size_t(kSide / 2);
    g->heights.set(centre, 7.0f);
    s.physics.sync(s.world);
    const auto hit = s.physics.raycast3d(s.world, {0, 20, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(hit.has_value());
    CHECK(hit->point.y == doctest::Approx(7.0f).epsilon(1e-3));
    g->heights.set(centre, 0.0f);
    s.physics.sync(s.world);
    const auto flat = s.physics.raycast3d(s.world, {0, 20, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(flat.has_value());
    CHECK(flat->point.y < 1.0f);
}

namespace {
std::string run_field(int threads, int frames) {
    Pool pool(threads);
    Sim s;
    add_field(s.world, "field", bumpy_component(48, 48, 1.0f, 1.0f, true), {0, 0, 0});
    Lcg rng(4242);
    std::vector<Entity> all;
    for (int i = 0; i < 70; ++i) {
        const std::string n = "d" + std::to_string(i);
        const Vec3 p{(rng.next() * 2 - 1) * 20.0f, 2.0f + 6.0f * rng.next(), (rng.next() * 2 - 1) * 20.0f};
        switch (i % 3) {
            case 0: all.push_back(add_sphere(s.world, n.c_str(), p)); break;
            case 1: all.push_back(add_box(s.world, n.c_str(), p, {0.7f, 0.5f, 0.9f})); break;
            default: all.push_back(add_capsule(s.world, n.c_str(), p)); break;
        }
    }
    Sha256 h;
    for (int f = 0; f < frames; ++f) {
        s.run(1);
        if (f % 3 == 2)
            for (Entity e : all) {
                feed(h, s.pos(e));
                feed(h, s.world.get<Transform>(e)->rotation);
                feed(h, s.world.get<RigidBody3D>(e)->velocity);
            }
    }
    return h.finish_hex();
}
}  // namespace

TEST_CASE("heightfield3d: the same replay with no pool and with 1, 2 and 8 job threads") {
    const std::string reference = run_field(-1, 180);
    CHECK(run_field(1, 180) == reference);
    CHECK(run_field(2, 180) == reference);
    CHECK(run_field(8, 180) == reference);
}
