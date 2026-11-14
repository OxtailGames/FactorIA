// The 3D scene queries (raycast, raycast_all, shape_cast, overlap_sphere, is_touching, the character controller's sweeps)
// ask the broad phase's tree for the bodies they can touch. They must answer exactly what testing every body answers: the
// same hit, the same order, the same entities, for worlds with sleeping, static, kinematic, trigger and disabled bodies, all
// shapes, and for bodies created or moved since the last step (a script queries between steps).
#include <doctest.h>

#include <cstdint>
#include <string>
#include <vector>

#include "../src/physics_internal.h"
#include "fa/physics/physics.h"

using namespace fa;
using fa::detail::Physics3D;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct QRng {
    std::uint64_t s;
    explicit QRng(std::uint64_t seed) : s(seed * 2685821657736338717ull + 1) {}
    std::uint32_t next() {
        s ^= s >> 12;
        s ^= s << 25;
        s ^= s >> 27;
        return std::uint32_t((s * 2685821657736338717ull) >> 32);
    }
    float unit() { return float(next() >> 8) / float(1u << 24); }
    float range(float lo, float hi) { return lo + (hi - lo) * unit(); }
    int pick(int n) { return int(next() % std::uint32_t(n)); }
};

struct Scene {
    World world;
    Physics3D p;
    std::vector<Entity> all;
    Scene() { p.init(PhysicsSettings{}); }
    void step(int n) {
        for (int i = 0; i < n; ++i) {
            world.events().clear();
            p.step(world, kDt);
            world.advance_clock(kDt);
            world.flush();
        }
    }
};

// What is wrong with the tree, except for its balance: a rotation may leave one subtree two levels taller than its sibling
// after many moves (the height stays logarithmic; the structure test of test_broadphase3d.cpp covers the rotations).
std::string tree_problems(const Scene& s) { return s.p.broadphase_problems(false); }

// One random body: shape (mesh only static), type, trigger, layer, rotation, size.
Entity add_random(Scene& s, QRng& rng, float extent, bool allowDisabled) {
    Entity e = s.world.create();
    Transform* t = s.world.get<Transform>(e);
    t->position = {rng.range(-extent, extent), rng.range(0.0f, 6.0f), rng.range(-extent, extent)};
    if (rng.pick(3) == 0) t->rotation = {rng.range(0, 360), rng.range(0, 360), rng.range(0, 360)};
    Collider3D& c = s.world.add<Collider3D>(e);
    const int type = rng.pick(10);  // 0-5 dynamic, 6-7 static, 8 kinematic, 9 static mesh
    const int shape = type == 9 ? 4 : rng.pick(4);
    switch (shape) {
        case 0:
            c.shape = ColliderShape3D::Box;
            c.size = {rng.range(0.3f, 2.5f), rng.range(0.3f, 2.5f), rng.range(0.3f, 2.5f)};
            break;
        case 1:
            c.shape = ColliderShape3D::Sphere;
            c.radius = rng.range(0.2f, 1.2f);
            break;
        case 2:
            c.shape = ColliderShape3D::Capsule;
            c.radius = rng.range(0.2f, 0.6f);
            c.height = rng.range(1.3f, 2.6f);
            break;
        case 3:
            c.shape = ColliderShape3D::Convex;
            c.mesh = "cube";
            t->scale = {rng.range(0.4f, 2.0f), rng.range(0.4f, 2.0f), rng.range(0.4f, 2.0f)};
            break;
        default:
            c.shape = ColliderShape3D::Mesh;
            c.mesh = "cube";
            t->scale = {rng.range(0.5f, 3.0f), rng.range(0.5f, 3.0f), rng.range(0.5f, 3.0f)};
            break;
    }
    c.isTrigger = rng.pick(8) == 0;
    c.layer = rng.pick(4);
    c.enabled = !(allowDisabled && rng.pick(12) == 0);
    if (type != 6 && type != 7 && type != 9) {
        RigidBody3D& rb = s.world.add<RigidBody3D>(e);
        rb.type = type == 8 ? BodyType::Kinematic : BodyType::Dynamic;
        if (type == 8) {
            rb.velocity = {rng.range(-1, 1), 0, rng.range(-1, 1)};
            c.isTrigger = false;
        }
    }
    if (rng.pick(40) == 0) s.world.set_active(e, false);  // inactive in the hierarchy: no body is enabled
    s.all.push_back(e);
    return e;
}

int g_rayHits = 0, g_castHits = 0, g_overlapHits = 0;  // what the comparisons found (they must not compare empty answers)

std::string brute_vs_tree(Scene& s, QRng& rng, int rays, int casts, int overlaps) {
    World& w = s.world;
    auto vec = [&](float r) { return Vec3{rng.range(-r, r), rng.range(-1.0f, 7.0f), rng.range(-r, r)}; };
    auto same_hit = [](const RaycastHit& a, const RaycastHit& b) {
        return a.entity == b.entity && a.distance == b.distance && a.point == b.point && a.normal == b.normal;
    };
    for (int i = 0; i < rays; ++i) {
        Vec3 o = vec(30.0f), d = vec(1.0f) - Vec3{0, 3, 0};
        const int mode = rng.pick(6);
        if (mode == 0) d = {1, 0, 0};  // axis aligned: exact zeros in the slab test
        if (mode == 1) d = {0, -1, 0};
        if (mode == 2) d = {0, 0, 1};
        if (mode == 3) o = {o.x, rng.pick(3) * 1.0f, o.z};
        RaycastOptions opt;
        opt.ignoreTriggers = rng.pick(2) == 0;
        opt.mask = rng.pick(3) == 0 ? (1 << rng.pick(4)) : -1;
        opt.maxHits = 1 + rng.pick(40);
        if (rng.pick(5) == 0 && !s.all.empty()) opt.ignore = s.all[std::size_t(rng.pick(int(s.all.size())))];
        const float maxD = rng.pick(4) == 0 ? 3.0f : rng.range(5.0f, 80.0f);
        s.p.set_brute_force_queries(true);
        auto b1 = s.p.raycast(w, o, d, maxD, opt);
        auto b2 = s.p.raycast_all(w, o, d, maxD, opt);
        s.p.set_brute_force_queries(false);
        auto t1 = s.p.raycast(w, o, d, maxD, opt);
        auto t2 = s.p.raycast_all(w, o, d, maxD, opt);
        g_rayHits += b1.has_value() ? 1 : 0;
        if (b1.has_value() != t1.has_value() || (b1 && !same_hit(*b1, *t1))) return "raycast differs, ray " + std::to_string(i);
        if (b2.size() != t2.size()) return "raycast_all count differs, ray " + std::to_string(i);
        for (std::size_t k = 0; k < b2.size(); ++k)
            if (!same_hit(b2[k], t2[k])) return "raycast_all differs, ray " + std::to_string(i) + " hit " + std::to_string(k);
    }
    for (int i = 0; i < casts; ++i) {
        CastShape shape;
        if (rng.pick(2) == 0) {
            shape.kind = CastShape::Kind::Box;
            shape.size = {rng.range(0.2f, 1.5f), rng.range(0.2f, 1.5f), rng.range(0.2f, 1.5f)};
        } else {
            shape.radius = rng.range(0.1f, 0.9f);
        }
        const Vec3 from = vec(25.0f), to = from + vec(10.0f) - Vec3{5, 3, 5};
        RaycastOptions opt;
        opt.ignoreTriggers = rng.pick(2) == 0;
        s.p.set_brute_force_queries(true);
        auto b = s.p.shape_cast(w, shape, from, to, opt);
        s.p.set_brute_force_queries(false);
        auto t = s.p.shape_cast(w, shape, from, to, opt);
        g_castHits += b.has_value() ? 1 : 0;
        if (b.has_value() != t.has_value() || (b && !same_hit(*b, *t))) return "shape_cast differs, cast " + std::to_string(i);
    }
    for (int i = 0; i < overlaps; ++i) {
        const Vec3 c = vec(28.0f);
        const float r = rng.range(0.0f, 6.0f);
        const std::int32_t mask = rng.pick(3) == 0 ? (1 << rng.pick(4)) : -1;
        s.p.set_brute_force_queries(true);
        auto b = s.p.overlap_sphere(w, c, r, mask);
        s.p.set_brute_force_queries(false);
        auto t = s.p.overlap_sphere(w, c, r, mask);
        g_overlapHits += b.empty() ? 0 : 1;
        if (b != t) return "overlap_sphere differs, query " + std::to_string(i);
        if (i % 10 == 0 && !s.all.empty()) {
            const Entity e = s.all[std::size_t(rng.pick(int(s.all.size())))];
            const Vec3 dir{0, -1, 0};
            s.p.set_brute_force_queries(true);
            const bool bt = s.p.is_touching(w, e, dir, 0.1f);
            s.p.set_brute_force_queries(false);
            if (bt != s.p.is_touching(w, e, dir, 0.1f)) return "is_touching differs, query " + std::to_string(i);
        }
    }
    return {};
}

}  // namespace

TEST_CASE("3d queries: the tree answers what testing every body answers (awake, sleeping, static, trigger, disabled)") {
    Scene s;
    QRng rng(7);
    Entity floor = s.world.create();
    s.world.get<Transform>(floor)->position = {0, -0.5f, 0};
    s.world.add<Collider3D>(floor).size = {80, 1, 80};
    s.all.push_back(floor);
    for (int i = 0; i < 260; ++i) add_random(s, rng, 24.0f, true);
    s.p.sync(s.world);
    CHECK(tree_problems(s).empty());
    CHECK(brute_vs_tree(s, rng, 400, 80, 120) == "");  // before any step: everything just created

    s.step(30);
    CHECK(tree_problems(s) == "");
    CHECK(brute_vs_tree(s, rng, 400, 80, 120) == "");  // falling

    s.step(240);  // most of it is asleep now
    CHECK(tree_problems(s) == "");
    CHECK(brute_vs_tree(s, rng, 1000, 200, 300) == "");
    CHECK(g_rayHits > 500);
    CHECK(g_castHits > 100);
    CHECK(g_overlapHits > 200);
}

TEST_CASE("3d queries: a body created, teleported, resized, disabled or destroyed since the last step is found at once") {
    Scene s;
    QRng rng(11);
    for (int i = 0; i < 120; ++i) add_random(s, rng, 20.0f, false);
    s.p.sync(s.world);
    s.step(200);

    // Spawned this frame: a raycast right after sync finds it.
    Entity box = s.world.create();
    s.world.get<Transform>(box)->position = {100, 0, 0};
    s.world.add<Collider3D>(box).size = {2, 2, 2};
    s.p.sync(s.world);
    auto hit = s.p.raycast(s.world, {90, 0, 0}, {1, 0, 0}, 50, RaycastOptions{});
    REQUIRE(hit);
    CHECK(hit->entity == box);
    CHECK(hit->distance == doctest::Approx(9.0f));
    CHECK(tree_problems(s) == "");
    CHECK(s.p.overlap_sphere(s.world, {100, 0, 0}, 0.5f, -1) == std::vector<Entity>{box});

    // Teleported (it was asleep or at rest): found at the new place, gone from the old one.
    s.world.get<Transform>(box)->position = {100, 40, 0};
    s.p.sync(s.world);
    CHECK(tree_problems(s) == "");
    CHECK(!s.p.raycast(s.world, {90, 0, 0}, {1, 0, 0}, 50, RaycastOptions{}));
    hit = s.p.raycast(s.world, {90, 40, 0}, {1, 0, 0}, 50, RaycastOptions{});
    REQUIRE(hit);
    CHECK(hit->entity == box);

    // Resized: a bigger box is hit from further away.
    s.world.get<Collider3D>(box)->size = {10, 2, 2};
    s.p.sync(s.world);
    hit = s.p.raycast(s.world, {90, 40, 0}, {1, 0, 0}, 50, RaycastOptions{});
    REQUIRE(hit);
    CHECK(hit->distance == doctest::Approx(5.0f));

    // Disabled, then enabled, then destroyed.
    s.world.get<Collider3D>(box)->enabled = false;
    s.p.sync(s.world);
    CHECK(!s.p.raycast(s.world, {90, 40, 0}, {1, 0, 0}, 50, RaycastOptions{}));
    CHECK(tree_problems(s) == "");
    s.world.get<Collider3D>(box)->enabled = true;
    s.p.sync(s.world);
    CHECK(s.p.raycast(s.world, {90, 40, 0}, {1, 0, 0}, 50, RaycastOptions{}));
    s.world.destroy(box);
    s.world.flush();
    s.p.sync(s.world);
    CHECK(!s.p.raycast(s.world, {90, 40, 0}, {1, 0, 0}, 50, RaycastOptions{}));
    CHECK(tree_problems(s) == "");

    // A random burst of edits between steps, compared with testing every body each time.
    for (int round = 0; round < 6; ++round) {
        for (int k = 0; k < 10; ++k) {
            const Entity e = s.all[std::size_t(rng.pick(int(s.all.size())))];
            if (!s.world.alive(e)) continue;
            switch (rng.pick(4)) {
                case 0:
                    s.world.get<Transform>(e)->position = {rng.range(-20, 20), rng.range(0, 6), rng.range(-20, 20)};
                    break;
                case 1: s.world.get<Collider3D>(e)->enabled = !s.world.get<Collider3D>(e)->enabled; break;
                case 2: s.world.get<Transform>(e)->rotation = {rng.range(0, 90), rng.range(0, 90), 0}; break;
                default: add_random(s, rng, 20.0f, false); break;
            }
        }
        s.p.sync(s.world);
        CHECK(tree_problems(s) == "");
        CHECK(brute_vs_tree(s, rng, 150, 40, 60) == "");
        s.step(round % 2 ? 1 : 20);
        CHECK(tree_problems(s) == "");
        CHECK(brute_vs_tree(s, rng, 150, 40, 60) == "");
    }
}

TEST_CASE("3d queries: a character that walked between steps is found where it is, and its own sweeps use the tree") {
    Scene s;
    QRng rng(5);
    Entity floor = s.world.create();
    s.world.get<Transform>(floor)->position = {0, -0.5f, 0};
    s.world.add<Collider3D>(floor).size = {60, 1, 60};
    for (int i = 0; i < 80; ++i) {
        Entity e = s.world.create();
        s.world.get<Transform>(e)->position = {rng.range(-20, 20), 0.5f, rng.range(-20, 20)};
        s.world.add<Collider3D>(e).size = {1, 1, 1};
    }
    Entity hero = s.world.create();
    s.world.get<Transform>(hero)->position = {-25, 1, 0};
    s.world.add<CharacterController3D>(hero);
    s.p.sync(s.world);
    s.step(5);

    // Walk the same course with the tree and with every body tested: same end point, same flags.
    auto walk = [&](bool brute) {
        s.world.get<Transform>(hero)->position = {-25, 1, 0};
        s.p.sync(s.world);
        s.p.set_brute_force_queries(brute);
        std::vector<Vec3> track;
        QRng r(99);
        for (int i = 0; i < 300; ++i) {
            auto res = s.p.move_character(s.world, hero, {0.15f, 0.0f, r.range(-0.1f, 0.1f)});
            REQUIRE(res);
            track.push_back(res->position);
            track.push_back({res->isGrounded ? 1.0f : 0.0f, res->hitWall ? 1.0f : 0.0f, 0});
            CHECK(tree_problems(s) == "");
        }
        s.p.set_brute_force_queries(false);
        return track;
    };
    const auto withTree = walk(false);
    const auto brute = walk(true);
    REQUIRE(withTree.size() == brute.size());
    for (std::size_t i = 0; i < brute.size(); ++i) CHECK(withTree[i] == brute[i]);

    // Between steps a raycast sees the capsule where the move left it.
    const Vec3 at = s.world.world_position(hero);
    auto hit = s.p.raycast(s.world, at + Vec3{0, 5, 0}, {0, -1, 0}, 20, RaycastOptions{});
    REQUIRE(hit);
    CHECK(hit->entity == hero);
}

TEST_CASE("3d queries: equal distances keep the order of the bodies, whatever the tree looks like") {
    Scene s;
    // Ten identical boxes in the same place: raycast answers the last created, raycast_all lists them in creation order.
    std::vector<Entity> twins;
    for (int i = 0; i < 10; ++i) {
        Entity e = s.world.create();
        s.world.get<Transform>(e)->position = {5, 0, 0};
        s.world.add<Collider3D>(e).size = {1, 1, 1};
        twins.push_back(e);
    }
    for (int i = 0; i < 40; ++i) {  // filler so the tree has several levels
        Entity e = s.world.create();
        s.world.get<Transform>(e)->position = {float(i) * 3.0f, 10, float(i % 5) * 4.0f};
        s.world.add<Collider3D>(e).size = {1, 1, 1};
    }
    s.p.sync(s.world);
    auto first = s.p.raycast(s.world, {0, 0, 0}, {1, 0, 0}, 20, RaycastOptions{});
    REQUIRE(first);
    CHECK(first->entity == twins.back());
    auto all = s.p.raycast_all(s.world, {0, 0, 0}, {1, 0, 0}, 20, RaycastOptions{});
    REQUIRE(all.size() == 10);
    for (std::size_t i = 0; i < 10; ++i) CHECK(all[i].entity == twins[i]);
    s.p.set_brute_force_queries(true);
    auto firstBrute = s.p.raycast(s.world, {0, 0, 0}, {1, 0, 0}, 20, RaycastOptions{});
    REQUIRE(firstBrute);
    CHECK(firstBrute->entity == first->entity);
}
