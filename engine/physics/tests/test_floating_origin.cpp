// M75-P4a: a rebase in the middle of a physics simulation (World::rebase + Physics::origin_shifted) changes nothing in the world:
// bodies fall, collide, sleep and are carried exactly as if the origin had never moved (docs/BIG_WORLDS.md "Floating origin").
#include <doctest.h>

#include <cmath>
#include <string>
#include <utility>
#include <vector>

#include "fa/physics/physics.h"
#include "fa/scene/tilemap.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct Sim {
    World world;
    Physics physics;
    std::vector<CollisionEvent> events;
    Sim() { physics.init(PhysicsSettings{}); }
    void run(int steps) {
        for (int i = 0; i < steps; ++i) {
            world.events().clear();
            physics.step(world, kDt);
            for (const CollisionEvent& e : world.events().collisions) events.push_back(e);
            world.advance_clock(kDt);
            world.flush();
        }
    }
    // What the engine does at the end of a fixed step when the anchor went far: the world and then the physics.
    void rebase(Vec3 offset) {
        world.rebase(offset);
        physics.origin_shifted(world, offset);
    }
    bool awake(Entity e) const {
        const std::string& id = world.id_of(e);
        for (const Json& j : physics.debug_state(world))
            if (j["entity"] == id) return j["awake"].get<bool>();
        FAIL("no debug state for " << id);
        return false;
    }
    int begins() const {
        int n = 0;
        for (const CollisionEvent& e : events)
            if (e.phase == CollisionEvent::Phase::Begin && !e.trigger) ++n;
        return n;
    }
};

Entity box3(World& w, const char* id, Vec3 pos, Vec3 size, bool dynamic) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    if (dynamic) w.add<RigidBody3D>(e);
    return e;
}

Entity box2(World& w, const char* id, Vec2 pos, Vec2 size, bool dynamic) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = {pos.x, pos.y, 0};
    w.add<Collider2D>(e).size = size;
    if (dynamic) w.add<RigidBody2D>(e).type = BodyType::Dynamic;
    return e;
}

// The 3D scene: a floor and a box dropped 4 m onto it, with a ball rolling in from the side; at x = 1000 (far from the origin).
struct Scene3 {
    Entity floor, box, ball;
    explicit Scene3(Sim& s) {
        floor = box3(s.world, "floor", {1000, -0.5f, 0}, {200, 1, 200}, false);
        box = box3(s.world, "box", {1000, 5.0f, 0}, {1, 1, 1}, true);
        ball = s.world.create("ball", "ball");
        s.world.get<Transform>(ball)->position = {1004, 0.5f, 0};
        Collider3D& c = s.world.add<Collider3D>(ball);
        c.shape = ColliderShape3D::Sphere;
        c.radius = 0.5f;
        s.world.add<RigidBody3D>(ball).velocity = {-3.0f, 0, 0};
    }
};

}  // namespace

TEST_CASE("floating origin 3d: a body falling, colliding and resting across rebases behaves like one without") {
    Sim plain, moved;
    Scene3 a(plain), b(moved);
    // Rebases while it falls, as it lands (the box reaches the floor near step 57) and while it rests; one of them also on y.
    const int rebaseAt[] = {20, 55, 62, 120};
    const Vec3 offsets[] = {{768, 0, 0}, {-256, 256, 256}, {256, -256, 0}, {0, 0, -512}};
    int done = 0;
    for (int step = 0; step < 240; ++step) {
        plain.run(1);
        moved.run(1);
        if (done < 4 && step == rebaseAt[done]) moved.rebase(offsets[done++]);
    }
    REQUIRE(done == 4);
    CHECK(moved.world.rebase_count() == 4);
    for (const auto& [x, y] : {std::pair{a.box, b.box}, std::pair{a.ball, b.ball}, std::pair{a.floor, b.floor}}) {
        const Vec3 pa = plain.world.world_position(x);
        const DVec3 pb = moved.world.absolute_position(y);
        CHECK(std::fabs(pb.x - pa.x) < 5e-3);
        CHECK(std::fabs(pb.y - pa.y) < 5e-3);
        CHECK(std::fabs(pb.z - pa.z) < 5e-3);
    }
    CHECK(moved.begins() == plain.begins());
    CHECK(plain.begins() >= 1);
    // The box rests on the floor, not inside it and not floating.
    CHECK(moved.world.absolute_position(b.box).y == doctest::Approx(0.5).epsilon(0.02));
}

TEST_CASE("floating origin 3d: a sleeping body stays asleep across a rebase and wakes when something lands on it") {
    Sim s;
    Entity floor = box3(s.world, "floor", {0, -0.5f, 0}, {100, 1, 100}, false);
    Entity rock = box3(s.world, "rock", {3000, 0.5f, 0}, {1, 1, 1}, true);
    s.world.get<Transform>(floor)->position.x = 3000;
    s.run(150);
    REQUIRE_FALSE(s.awake(rock));
    s.rebase({2816, 0, 0});  // 11 * 256
    s.run(30);
    CHECK_FALSE(s.awake(rock));
    CHECK(s.world.absolute_position(rock).x == doctest::Approx(3000.0).epsilon(1e-6));
    Entity dropped = box3(s.world, "dropped", {s.world.world_position(rock).x + 0.2f, 4.0f, 0}, {1, 1, 1}, true);
    bool woke = false;
    for (int i = 0; i < 90; ++i) {
        s.run(1);
        woke = woke || s.awake(rock);  // the broad phase and the contacts work in the new coordinates
    }
    CHECK(woke);
    CHECK(s.world.absolute_position(dropped).y > 0.9);  // it landed on the rock, not through the floor
}

TEST_CASE("floating origin 3d: a character controller keeps standing and walking across a rebase") {
    Sim s;
    box3(s.world, "floor", {2000, -0.5f, 0}, {400, 1, 40}, false);
    Entity hero = s.world.create("hero", "hero");
    s.world.get<Transform>(hero)->position = {2000, 1.0f, 0};
    s.world.add<CharacterController3D>(hero);
    auto walk = [&]() {
        auto r = s.physics.move_character(s.world, hero, {0.05f, -0.1f, 0});
        REQUIRE(r.has_value());
        s.run(1);
        return r->isGrounded;
    };
    for (int i = 0; i < 20; ++i) walk();
    const double x0 = s.world.absolute_position(hero).x;
    s.rebase({1792, 0, 0});  // 7 * 256
    bool grounded = true;
    for (int i = 0; i < 20; ++i) grounded = walk() && grounded;
    CHECK(grounded);
    CHECK(s.world.absolute_position(hero).x == doctest::Approx(x0 + 1.0).epsilon(1e-3));
    CHECK(s.world.absolute_position(hero).y == doctest::Approx(0.92).epsilon(0.1));
}

TEST_CASE("floating origin 2d: a body falling and colliding across rebases behaves like one without") {
    Sim plain, moved;
    auto build = [](Sim& s) {
        box2(s.world, "ground", {30000, -200}, {4000, 40}, false);
        return box2(s.world, "box", {30000, 100}, {32, 32}, true);
    };
    const Entity a = build(plain), b = build(moved);
    const int rebaseAt[] = {10, 40, 90};
    const Vec3 offsets[] = {{29696, 0, 0}, {0, 512, 0}, {-256, -512, 0}};  // 116 * 256 on x
    int done = 0;
    for (int step = 0; step < 240; ++step) {
        plain.run(1);
        moved.run(1);
        if (done < 3 && step == rebaseAt[done]) moved.rebase(offsets[done++]);
    }
    REQUIRE(done == 3);
    const Vec3 pa = plain.world.world_position(a);
    const DVec3 pb = moved.world.absolute_position(b);
    CHECK(std::fabs(pb.x - pa.x) < 0.05);  // pixels
    CHECK(std::fabs(pb.y - pa.y) < 0.05);
    CHECK(pa.y == doctest::Approx(-180.0f + 16.0f).epsilon(0.03));  // it landed on the ground
    CHECK(moved.begins() == plain.begins());
    CHECK(plain.begins() >= 1);
}

TEST_CASE("floating origin 2d: a body asleep stays asleep") {
    Sim s;
    box2(s.world, "ground", {5000, -200}, {4000, 40}, false);
    Entity rock = box2(s.world, "rock", {5000, -160}, {32, 32}, true);
    s.run(200);
    const std::string rockId = s.world.id_of(rock);
    auto asleep = [&]() {
        for (const Json& j : s.physics.debug_state(s.world))
            if (j["entity"] == rockId) return !j["awake"].get<bool>();
        return false;
    };
    REQUIRE(asleep());
    const Vec3 before = s.world.world_position(rock);
    s.rebase({4864, 0, 0});  // 19 * 256
    s.run(30);
    CHECK(asleep());
    CHECK(s.world.absolute_position(rock).x == doctest::Approx(double(before.x)).epsilon(1e-6));
    CHECK(s.world.absolute_position(rock).y == doctest::Approx(double(before.y)).epsilon(1e-4));
}

TEST_CASE(
    "floating origin 3d: a baked navigation mesh moves with the world, is not baked again and gives the same paths") {
    Sim s;
    box3(s.world, "floor", {0, -0.5f, 0}, {30, 1, 30}, false);
    box3(s.world, "wall", {0, 1.5f, 0}, {0.4f, 3, 8}, false);
    Entity nav = s.world.create("navmesh", "navmesh");
    s.world.get<Transform>(nav)->position = {0, 2, 0};
    s.world.add<NavMesh3D>(nav).size = {30, 6, 30};
    s.physics.sync(s.world);
    auto before = s.physics.nav_find_path(s.world, {-5, 0, 0}, {5, 0, 0});
    REQUIRE(before.ok());
    REQUIRE(before->found);
    const Json info0 = s.physics.nav_info(s.world);
    REQUIRE(info0.is_array());
    REQUIRE(info0.size() == 1);
    REQUIRE(info0[0]["baked"].get<bool>());

    s.rebase({1024, 0, -512});
    s.run(2);  // a step after the shift: a changed signature would bake again here
    auto after = s.physics.nav_find_path(s.world, {-5 - 1024, 0, 0 + 512}, {5 - 1024, 0, 512});
    REQUIRE(after.ok());
    REQUIRE(after->found);
    CHECK(after->length == doctest::Approx(before->length).epsilon(1e-4));
    CHECK(after->points.size() == before->points.size());
    const Json info1 = s.physics.nav_info(s.world);
    CHECK_FALSE(info1[0]["staleSinceBake"].get<bool>());
    CHECK(info1[0]["boundsMin"][0].get<double>() == doctest::Approx(info0[0]["boundsMin"][0].get<double>() - 1024.0));
    CHECK(info1[0]["boundsMin"][2].get<double>() == doctest::Approx(info0[0]["boundsMin"][2].get<double>() + 512.0));
    CHECK(info1[0]["stats"]["cells"] == info0[0]["stats"]["cells"]);
}

TEST_CASE("floating origin 2d: a joint pinned to a world point keeps holding and swinging across rebases") {
    Sim plain, moved;
    auto build = [](Sim& s) {
        const Vec2 pivot{30000, 0};
        const float a = radians(60.0f);
        const Vec2 p{pivot.x + 100.0f * std::sin(a), pivot.y - 100.0f * std::cos(a)};
        Entity bob = s.world.create("bob", "bob");
        s.world.get<Transform>(bob)->position = {p.x, p.y, 0};
        Collider2D& c = s.world.add<Collider2D>(bob);
        c.size = {8, 8};
        c.mask = 0;
        RigidBody2D& rb = s.world.add<RigidBody2D>(bob);
        rb.type = BodyType::Dynamic;
        rb.linearDamping = 0.0f;
        Joint2D& j = s.world.add<Joint2D>(bob);
        j.type = JointType2D::Revolute;
        j.anchor = {pivot.x - p.x, pivot.y - p.y};
        j.connectedAnchor = pivot;  // `connected` empty: a world position
        return bob;
    };
    const Entity a = build(plain), b = build(moved);
    const int rebaseAt[] = {10, 40};
    const Vec3 offsets[] = {{29696, 0, 0}, {-256, 512, 0}};
    int done = 0;
    float lowest = 1e9f;
    for (int step = 0; step < 180; ++step) {
        plain.run(1);
        moved.run(1);
        lowest = std::min(lowest, plain.world.world_position(a).y);
        if (done < 2 && step == rebaseAt[done]) moved.rebase(offsets[done++]);
    }
    REQUIRE(done == 2);
    CHECK(lowest < -60.0f);  // it did swing down from 60 degrees
    const Vec3 pa = plain.world.world_position(a);
    const DVec3 pb = moved.world.absolute_position(b);
    CHECK(std::fabs(pb.x - pa.x) < 0.05);
    CHECK(std::fabs(pb.y - pa.y) < 0.05);
    // The joint still holds the same point of the world, and the body is still the distance from it the joint keeps.
    const Joint2D* j = moved.world.get<Joint2D>(b);
    CHECK(double(j->connectedAnchor.x) + moved.world.origin().x == doctest::Approx(30000.0));
    CHECK(double(j->connectedAnchor.y) + moved.world.origin().y == doctest::Approx(0.0));
    CHECK(std::hypot(pb.x - 30000.0, pb.y) == doctest::Approx(100.0).epsilon(0.01));
}

TEST_CASE("floating origin 3d: a hinge pinned to a world point keeps holding and swinging across rebases") {
    Sim plain, moved;
    auto build = [](Sim& s) {
        const Vec3 pivot{1000, 10, 0};
        Entity bob = box3(s.world, "bob", pivot + Vec3{2, 0, 0}, {0.5f, 0.5f, 0.5f}, true);
        Joint3D& j = s.world.add<Joint3D>(bob);
        j.axis = {0, 0, 1};
        j.anchor = {-2, 0, 0};
        j.autoAnchor = false;
        j.connectedAnchor = pivot;  // `connected` empty: a world position
        return bob;
    };
    const Entity a = build(plain), b = build(moved);
    const int rebaseAt[] = {20, 60};
    const Vec3 offsets[] = {{768, 0, 0}, {0, -256, 256}};
    int done = 0;
    float lowest = 1e9f;
    for (int step = 0; step < 150; ++step) {
        plain.run(1);
        moved.run(1);
        lowest = std::min(lowest, plain.world.world_position(a).y);
        if (done < 2 && step == rebaseAt[done]) moved.rebase(offsets[done++]);
    }
    REQUIRE(done == 2);
    CHECK(lowest < 8.5f);  // it swung down from the horizontal
    const Vec3 pa = plain.world.world_position(a);
    const DVec3 pb = moved.world.absolute_position(b);
    CHECK(std::fabs(pb.x - pa.x) < 5e-3);
    CHECK(std::fabs(pb.y - pa.y) < 5e-3);
    CHECK(std::fabs(pb.z - pa.z) < 5e-3);
    const Joint3D* j = moved.world.get<Joint3D>(b);
    CHECK(double(j->connectedAnchor.x) + moved.world.origin().x == doctest::Approx(1000.0));
    CHECK(double(j->connectedAnchor.y) + moved.world.origin().y == doctest::Approx(10.0));
    CHECK(std::hypot(pb.x - 1000.0, pb.y - 10.0) == doctest::Approx(2.0).epsilon(0.01));  // still on the rod
}

TEST_CASE("floating origin 2d: a Tilemap's colliders move with the world and a body still lands on them") {
    Sim plain, moved;
    auto build = [](Sim& s) {
        Entity map = s.world.create("map", "map");
        s.world.get<Transform>(map)->position = {29900, -200, 0};  // the top-left corner of the map
        Tilemap& tm = s.world.add<Tilemap>(map);
        tm.tileSize = {8, 8};
        tm.solidTiles = Json::array({1});
        set_tilemap_grid(tm, 40, 1, std::vector<int>(40, 1));
        return box2(s.world, "box", {30000, 100}, {16, 16}, true);
    };
    const Entity a = build(plain), b = build(moved);
    auto shapes = [](Sim& s) {
        for (const Json& j : s.physics.debug_state(s.world))
            if (j.value("kind", "") == "tilemap") return j["shapeCount"].get<int>();
        return -1;
    };
    const int rebaseAt[] = {10, 40};
    const Vec3 offsets[] = {{29696, 0, 0}, {-256, 512, 0}};
    int done = 0;
    for (int step = 0; step < 200; ++step) {
        plain.run(1);
        moved.run(1);
        if (done < 2 && step == rebaseAt[done]) moved.rebase(offsets[done++]);
    }
    REQUIRE(done == 2);
    REQUIRE(shapes(plain) > 0);
    CHECK(shapes(moved) == shapes(plain));  // the colliders were moved, not rebuilt into something else
    const Vec3 pa = plain.world.world_position(a);
    const DVec3 pb = moved.world.absolute_position(b);
    CHECK(std::fabs(pb.x - pa.x) < 0.05);
    CHECK(std::fabs(pb.y - pa.y) < 0.05);
    CHECK(pa.y ==
          doctest::Approx(-192.0f).epsilon(0.03));  // it rests on the tiles' top edge (y = -200) by its half size
    CHECK(moved.begins() == plain.begins());
    CHECK(plain.begins() >= 1);
}
