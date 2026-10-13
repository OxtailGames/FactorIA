#include <doctest.h>

#include <cmath>
#include <cstring>

#include "fa/physics/physics.h"

using namespace fa;

namespace {

constexpr float kDt = 1.0f / 60.0f;

struct Sim {
    World world;
    Physics physics;
    std::vector<CollisionEvent> events;  // everything emitted so far
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
    int count(CollisionEvent::Phase ph, bool trigger) const {
        int n = 0;
        for (const auto& e : events) if (e.phase == ph && e.trigger == trigger) ++n;
        return n;
    }
};

Entity add_box(World& w, const char* id, Vec2 pos, Vec2 size, BodyType type, bool withBody = true) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = {pos.x, pos.y, 0};
    Collider2D& c = w.add<Collider2D>(e);
    c.size = size;
    if (withBody) {
        RigidBody2D& rb = w.add<RigidBody2D>(e);
        rb.type = type;
    }
    return e;
}

Entity add_ground(World& w, float topY = -180.0f, const char* id = "ground") {
    return add_box(w, id, {0, topY - 20}, {2000, 40}, BodyType::Static, false);
}

Vec3 pos_of(const World& w, Entity e) { return w.world_position(e); }

}  // namespace

TEST_CASE("2d: falling body lands on static ground and rests") {
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, 100}, {32, 32}, BodyType::Dynamic);
    s.run(180);
    Vec3 p = pos_of(s.world, box);
    CHECK(p.y == doctest::Approx(-180.0f + 16.0f).epsilon(0.02));
    CHECK(std::fabs(s.world.get<RigidBody2D>(box)->velocity.y) < 1.0f);
    s.run(60);
    CHECK(pos_of(s.world, box).y == doctest::Approx(p.y).epsilon(0.01));
    // landing produced a collision begin event between box and ground
    CHECK(s.count(CollisionEvent::Phase::Begin, false) >= 1);
}

TEST_CASE("2d: velocity written by gameplay moves the body") {
    Sim s;
    s.world.settings().gravity2D = {0, 0};
    Entity e = add_box(s.world, "mover", {0, 0}, {16, 16}, BodyType::Dynamic);
    s.world.get<RigidBody2D>(e)->velocity = {60, 0};
    s.run(60);
    CHECK(pos_of(s.world, e).x == doctest::Approx(60.0f).epsilon(0.03));
    s.world.get<RigidBody2D>(e)->velocity = {0, 0};
    float x = pos_of(s.world, e).x;
    s.run(30);
    CHECK(pos_of(s.world, e).x == doctest::Approx(x).epsilon(0.01));
    // writeback of velocity: after a free fall the component reflects the speed
    s.world.settings().gravity2D = {0, -980};
    s.run(30);
    CHECK(s.world.get<RigidBody2D>(e)->velocity.y < -300.0f);
}

TEST_CASE("2d: kinematic bodies follow their velocity") {
    Sim s;
    Entity e = add_box(s.world, "platform", {0, 0}, {64, 16}, BodyType::Kinematic);
    s.world.get<RigidBody2D>(e)->velocity = {0, 30};
    s.run(60);
    CHECK(pos_of(s.world, e).y == doctest::Approx(30.0f).epsilon(0.03));
}

TEST_CASE("2d: moving the Transform teleports the body") {
    Sim s;
    s.world.settings().gravity2D = {0, 0};
    Entity e = add_box(s.world, "t", {0, 0}, {16, 16}, BodyType::Dynamic);
    s.run(5);
    s.world.get<Transform>(e)->position = {500, 300, 0};
    s.run(1);
    CHECK(pos_of(s.world, e).x == doctest::Approx(500.0f).epsilon(0.001));
    CHECK(pos_of(s.world, e).y == doctest::Approx(300.0f).epsilon(0.001));
    s.world.get<RigidBody2D>(e)->velocity = {0, -60};
    s.run(60);
    CHECK(pos_of(s.world, e).y == doctest::Approx(240.0f).epsilon(0.03));
    CHECK(pos_of(s.world, e).x == doctest::Approx(500.0f).epsilon(0.001));
}

TEST_CASE("2d: trigger produces begin and end events (trigger flag set)") {
    Sim s;
    Entity zone = add_box(s.world, "zone", {0, 0}, {100, 100}, BodyType::Static, false);
    s.world.get<Collider2D>(zone)->isTrigger = true;
    Entity ball = s.world.create("ball", "ball");
    s.world.get<Transform>(ball)->position = {0, 250, 0};
    s.world.add<RigidBody2D>(ball);
    Collider2D& bc = s.world.add<Collider2D>(ball);
    bc.shape = ColliderShape::Circle;
    bc.radius = 10;
    s.run(150);
    CHECK(s.count(CollisionEvent::Phase::Begin, true) == 1);
    CHECK(s.count(CollisionEvent::Phase::End, true) == 1);
    // no solid response: the ball fell through the zone
    CHECK(pos_of(s.world, ball).y < -100.0f);
    for (const auto& e : s.events) {
        if (e.trigger && e.phase == CollisionEvent::Phase::Begin) {
            CHECK(((e.a == zone && e.b == ball) || (e.a == ball && e.b == zone)));
        }
    }
}

TEST_CASE("2d: collision layers and masks filter collisions") {
    Sim s;
    Entity ground = add_ground(s.world);
    s.world.get<Collider2D>(ground)->layer = 2;
    Entity ghost = add_box(s.world, "ghost", {-100, 0}, {20, 20}, BodyType::Dynamic);
    s.world.get<Collider2D>(ghost)->layer = 1;
    s.world.get<Collider2D>(ghost)->mask = ~(1 << 2);  // ignores layer 2
    Entity solid = add_box(s.world, "solid", {100, 0}, {20, 20}, BodyType::Dynamic);
    s.world.get<Collider2D>(solid)->layer = 1;
    s.run(150);
    CHECK(pos_of(s.world, ghost).y < -300.0f);  // fell through
    CHECK(pos_of(s.world, solid).y == doctest::Approx(-170.0f).epsilon(0.03));
}

TEST_CASE("2d: raycast and overlap queries") {
    Sim s;
    Entity ground = add_ground(s.world);
    Entity crate = add_box(s.world, "crate", {200, -150}, {60, 60}, BodyType::Static, false);
    s.world.get<Collider2D>(crate)->layer = 3;
    Entity trig = add_box(s.world, "trig", {-200, -100}, {40, 40}, BodyType::Static, false);
    s.world.get<Collider2D>(trig)->isTrigger = true;
    s.run(2);

    auto hit = s.physics.raycast2d(s.world, {0, 100}, {0, -300});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    CHECK(hit->point.y == doctest::Approx(-180.0f).epsilon(0.01));
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(hit->distance == doctest::Approx(280.0f).epsilon(0.01));

    // mask excludes layer 0 -> misses the ground (layer 0) but hits the crate (layer 3)
    CHECK_FALSE(s.physics.raycast2d(s.world, {0, 100}, {0, -300}, 1 << 3).has_value());
    auto hit2 = s.physics.raycast2d(s.world, {200, 100}, {200, -300}, 1 << 3);
    REQUIRE(hit2.has_value());
    CHECK(hit2->entity == crate);

    // triggers are invisible to raycasts
    CHECK_FALSE(s.physics.raycast2d(s.world, {-200, 100}, {-200, -100 + 15}).has_value());

    auto ov = s.physics.overlap_circle2d(s.world, {200, -150}, 10);
    REQUIRE(ov.size() == 1);
    CHECK(ov[0] == crate);
    CHECK(s.physics.overlap_circle2d(s.world, {0, 100}, 10).empty());
    auto ovb = s.physics.overlap_box2d(s.world, Rect{180, -140, 40, 40});
    REQUIRE(ovb.size() == 1);
    CHECK(ovb[0] == crate);
    CHECK(s.physics.overlap_box2d(s.world, Rect{180, -140, 40, 40}, 1 << 0).empty());
}

TEST_CASE("2d: tilemap solid tiles collide (origin = top-left corner)") {
    Sim s;
    Entity map = s.world.create("map", "map");
    s.world.get<Transform>(map)->position = {-80, 0, 0};  // top-left corner of the map
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {16, 16};
    tm.width = 10;
    tm.height = 3;
    Json tiles = Json::array();
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 10; ++c) tiles.push_back(r == 2 ? 1 : (r == 1 && c == 9 ? 2 : -1));
    tm.tiles = tiles;
    tm.solidTiles = Json::array({1, 2});
    Entity box = add_box(s.world, "box", {0, 100}, {16, 16}, BodyType::Dynamic);
    s.run(180);
    // bottom row spans y in [-48, -32]; box rests on top (y = -32 + 8)
    CHECK(pos_of(s.world, box).y == doctest::Approx(-24.0f).epsilon(0.03));
    // wall tile at column 9, row 1: x in [64, 80], y in [-32, -16]
    auto hit = s.physics.raycast2d(s.world, {40, -24}, {100, -24});
    REQUIRE(hit.has_value());
    CHECK(hit->point.x == doctest::Approx(64.0f).epsilon(0.01));
    // empty tile on the left: ray passes through the open cell
    CHECK_FALSE(s.physics.raycast2d(s.world, {-100, -24}, {-85, -24}).has_value());
}

TEST_CASE("2d: is_grounded2d") {
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, 60}, {32, 32}, BodyType::Dynamic);
    s.run(3);
    CHECK_FALSE(s.physics.is_grounded2d(s.world, box));
    s.run(120);
    CHECK(s.physics.is_grounded2d(s.world, box));
    // jump: grounded turns false in the air
    s.physics.apply_impulse(s.world, box, {0, 400, 0});
    s.run(10);
    CHECK_FALSE(s.physics.is_grounded2d(s.world, box));
    CHECK(s.world.get<RigidBody2D>(box)->velocity.y != 0.0f);
}

TEST_CASE("2d: child entities use world transforms; inactive entities have no body") {
    Sim s;
    Entity parent = s.world.create("parent", "parent");
    s.world.get<Transform>(parent)->position = {300, 50, 0};
    Entity child = add_box(s.world, "child", {20, 0}, {40, 40}, BodyType::Static, false);
    s.world.set_parent(child, parent);
    s.run(2);
    auto hit = s.physics.raycast2d(s.world, {320, 200}, {320, -100});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == child);
    CHECK(hit->point.y == doctest::Approx(70.0f).epsilon(0.01));
    // moving the parent teleports the static collider
    s.world.get<Transform>(parent)->position = {600, 50, 0};
    s.run(1);
    CHECK_FALSE(s.physics.raycast2d(s.world, {320, 200}, {320, -100}).has_value());
    CHECK(s.physics.raycast2d(s.world, {620, 200}, {620, -100}).has_value());
    // deactivate
    s.world.set_active(parent, false);
    s.run(1);
    CHECK_FALSE(s.physics.raycast2d(s.world, {620, 200}, {620, -100}).has_value());
    s.world.set_active(parent, true);
    s.run(1);
    CHECK(s.physics.raycast2d(s.world, {620, 200}, {620, -100}).has_value());
}

TEST_CASE("2d: destroyed entities and removed components free their bodies") {
    Sim s;
    Entity a = add_box(s.world, "a", {0, 0}, {20, 20}, BodyType::Static, false);
    Entity b = add_box(s.world, "b", {100, 0}, {20, 20}, BodyType::Static, false);
    s.run(1);
    CHECK(s.physics.debug_state(s.world).size() == 2);
    s.world.destroy(a);
    s.run(2);
    CHECK(s.physics.debug_state(s.world).size() == 1);
    s.world.remove<Collider2D>(b);
    s.run(1);
    CHECK(s.physics.debug_state(s.world).empty());
    CHECK(s.physics.debug_shapes(s.world).empty());
}

TEST_CASE("2d: collider changes rebuild the body") {
    Sim s;
    s.world.settings().gravity2D = {0, 0};
    Entity e = add_box(s.world, "e", {0, 0}, {20, 20}, BodyType::Static, false);
    s.run(1);
    CHECK(s.physics.raycast2d(s.world, {50, 0}, {-50, 0}).has_value());
    s.world.get<Collider2D>(e)->size = {200, 20};
    s.run(1);
    auto hit = s.physics.raycast2d(s.world, {300, 0}, {-300, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->point.x == doctest::Approx(100.0f).epsilon(0.01));
    auto shapes = s.physics.debug_shapes(s.world);
    REQUIRE(shapes.size() == 1);
    CHECK(shapes[0].size.x == doctest::Approx(200.0f));
}

TEST_CASE("2d: determinism - two identical runs produce identical positions") {
    auto run = [] {
        Sim s;
        add_ground(s.world);
        std::vector<Entity> bodies;
        for (int i = 0; i < 12; ++i) {
            Entity e = add_box(s.world, ("b" + std::to_string(i)).c_str(), {float(i % 3) * 7.0f - 7.0f, 40.0f + float(i) * 40.0f},
                               {30, 30}, BodyType::Dynamic);
            if (i % 2) {
                s.world.get<Collider2D>(e)->shape = ColliderShape::Circle;
                s.world.get<Collider2D>(e)->radius = 14;
            }
            bodies.push_back(e);
        }
        s.run(240);
        std::vector<float> out;
        for (Entity e : bodies) {
            Vec3 p = pos_of(s.world, e);
            out.push_back(p.x);
            out.push_back(p.y);
            out.push_back(s.world.get<Transform>(e)->rotation.z);
        }
        return out;
    };
    auto a = run(), b = run();
    REQUIRE(a.size() == b.size());
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
}

// ------------------------------------------------------------------ 3D ----

namespace {
Entity add_box3(World& w, const char* id, Vec3 pos, Vec3 size, BodyType type, bool withBody) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Box;
    c.size = size;
    if (withBody) w.add<RigidBody3D>(e).type = type;
    return e;
}
Entity add_sphere3(World& w, const char* id, Vec3 pos, float radius) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Sphere;
    c.radius = radius;
    w.add<RigidBody3D>(e);
    return e;
}
}  // namespace

TEST_CASE("3d: sphere falls onto a box ground and rests") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity ball = add_sphere3(s.world, "ball", {0, 5, 0}, 0.5f);
    s.run(240);
    CHECK(pos_of(s.world, ball).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(std::fabs(s.world.get<RigidBody3D>(ball)->velocity.y) < 0.05f);
    CHECK(s.count(CollisionEvent::Phase::Begin, false) >= 1);
    // sideways velocity decays through friction
    s.world.get<RigidBody3D>(ball)->velocity = {3, 0, 0};
    s.run(30);
    float x = pos_of(s.world, ball).x;
    CHECK(x > 0.5f);
    s.run(300);
    CHECK(std::fabs(s.world.get<RigidBody3D>(ball)->velocity.x) < 0.1f);
}

TEST_CASE("3d: restitution bounces, trigger events, queries") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity ball = add_sphere3(s.world, "ball", {0, 4, 0}, 0.5f);
    s.world.get<Collider3D>(ball)->restitution = 0.8f;
    Entity zone = add_box3(s.world, "zone", {0, 2, 0}, {2, 1, 2}, BodyType::Static, false);
    s.world.get<Collider3D>(zone)->isTrigger = true;
    float maxUp = -1e9f;
    bool bounced = false;
    for (int i = 0; i < 240; ++i) {
        s.run(1);
        float vy = s.world.get<RigidBody3D>(ball)->velocity.y;
        if (vy > 1.0f) bounced = true;
        if (bounced) maxUp = std::max(maxUp, pos_of(s.world, ball).y);
    }
    CHECK(bounced);
    CHECK(maxUp > 1.5f);
    CHECK(s.count(CollisionEvent::Phase::Begin, true) >= 1);
    CHECK(s.count(CollisionEvent::Phase::End, true) >= 1);

    // raycast / overlap
    auto hit = s.physics.raycast3d(s.world, {5, 10, 5}, {0, -1, 0}, 100.0f);
    REQUIRE(hit.has_value());
    CHECK(hit->point.y == doctest::Approx(0.0f).epsilon(0.01));
    CHECK(hit->normal.y == doctest::Approx(1.0f));
    CHECK(hit->distance == doctest::Approx(10.0f).epsilon(0.01));
    CHECK_FALSE(s.physics.raycast3d(s.world, {5, 10, 5}, {0, -1, 0}, 5.0f).has_value());
    CHECK_FALSE(s.physics.raycast3d(s.world, {5, 10, 5}, {0, -1, 0}, 100.0f, 1 << 4).has_value());
    auto ov = s.physics.overlap_sphere3d(s.world, {0, 0, 0}, 1.0f);
    CHECK(ov.size() >= 1);
}

TEST_CASE("3d: box vs box stacking and kinematic push") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity b1 = add_box3(s.world, "b1", {0, 0.6f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    Entity b2 = add_box3(s.world, "b2", {0, 2.0f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    s.run(240);
    CHECK(pos_of(s.world, b1).y == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(pos_of(s.world, b2).y == doctest::Approx(1.5f).epsilon(0.05));
}

TEST_CASE("3d: determinism") {
    auto run = [] {
        Sim s;
        add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
        std::vector<Entity> bodies;
        for (int i = 0; i < 8; ++i)
            bodies.push_back(add_sphere3(s.world, ("s" + std::to_string(i)).c_str(), {float(i % 2) * 0.3f, 1.0f + float(i), 0}, 0.5f));
        s.run(300);
        std::vector<float> out;
        for (Entity e : bodies) {
            Vec3 p = pos_of(s.world, e);
            out.insert(out.end(), {p.x, p.y, p.z});
        }
        return out;
    };
    auto a = run(), b = run();
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
}

// ------------------------------------------------- raycast options etc. ----

TEST_CASE("2d: raycast skips colliders containing the origin, honours ignore and triggers") {
    Sim s;
    Entity caster = add_box(s.world, "caster", {0, 0}, {40, 40}, BodyType::Static, false);
    Entity wall = add_box(s.world, "wall", {100, 0}, {20, 100}, BodyType::Static, false);
    Entity trig = add_box(s.world, "trig", {50, 0}, {10, 10}, BodyType::Static, false);
    s.world.get<Collider2D>(trig)->isTrigger = true;
    s.run(2);
    // from the caster's centre the caster itself is skipped; the trigger is skipped; the wall is hit
    auto hit = s.physics.raycast2d(s.world, {0, 0}, {300, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(hit->distance == doctest::Approx(90.0f).epsilon(0.01));
    RaycastOptions o;
    o.ignore = wall;
    CHECK_FALSE(s.physics.raycast2d(s.world, {0, 0}, {300, 0}, o).has_value());
    o = {};
    o.ignoreTriggers = false;
    auto th = s.physics.raycast2d(s.world, {-100, 0}, {300, 0}, o);
    REQUIRE(th.has_value());
    CHECK(th->entity == caster);  // from outside the caster it is the first thing hit
    o.ignore = caster;
    th = s.physics.raycast2d(s.world, {-100, 0}, {300, 0}, o);
    if (th) CHECK(th->entity == trig);
    // ignore covers children
    Entity child = add_box(s.world, "child", {0, 0}, {10, 10}, BodyType::Static, false);
    s.world.set_parent(child, wall, true);
    s.run(2);
    RaycastOptions o2;
    o2.ignore = wall;
    CHECK_FALSE(s.physics.raycast2d(s.world, {60, 0}, {300, 0}, o2).has_value());
}

TEST_CASE("3d: raycast from inside the caster, ignore option, triggers") {
    Sim s;
    Entity ball = add_sphere3(s.world, "ball", {0, 1, 0}, 0.5f);
    add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity trig = add_box3(s.world, "trig", {0, 0.4f, 0}, {4, 0.2f, 4}, BodyType::Static, false);
    s.world.get<Collider3D>(trig)->isTrigger = true;
    s.world.get<RigidBody3D>(ball)->gravityScale = 0.0f;
    s.run(2);
    auto hit = s.physics.raycast3d(s.world, {0, 1, 0}, {0, -1, 0}, 10.0f);
    REQUIRE(hit.has_value());
    CHECK(hit->entity != ball);
    CHECK(hit->distance == doctest::Approx(1.0f).epsilon(0.02));
    RaycastOptions o;
    o.ignore = hit->entity;
    CHECK_FALSE(s.physics.raycast3d(s.world, {0, 1, 0}, {0, -1, 0}, 10.0f, o).has_value());
    o = {};
    o.ignoreTriggers = false;
    auto th = s.physics.raycast3d(s.world, {0, 1, 0}, {0, -1, 0}, 10.0f, o);
    REQUIRE(th.has_value());
    CHECK(th->entity == trig);
    // origin inside the ground is skipped too
    CHECK_FALSE(s.physics.raycast3d(s.world, {0, -0.2f, 0}, {0, -1, 0}, 10.0f).has_value());
}

TEST_CASE("3d: kinematic platform carries a rider; friction is relative to the platform") {
    Sim s;
    Entity plat = add_box3(s.world, "plat", {0, -0.5f, 0}, {6, 1, 6}, BodyType::Kinematic, true);
    s.world.get<RigidBody3D>(plat)->velocity = {2, 0, 0};
    Entity box = add_box3(s.world, "rider", {0, 0.5f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    Entity ball = add_sphere3(s.world, "ball", {1, 0.5f, 1}, 0.5f);
    s.world.get<RigidBody3D>(ball)->rollWithMotion = false;
    s.run(60);
    float platX = pos_of(s.world, plat).x;
    CHECK(platX == doctest::Approx(2.0f).epsilon(0.05));
    CHECK(std::fabs((pos_of(s.world, box).x) - (platX)) < 0.1);
    CHECK(std::fabs((pos_of(s.world, ball).x - 1.0f) - (platX)) < 0.15);
    CHECK(std::fabs((pos_of(s.world, box).y) - (0.5f)) < 0.05);
    // a teleported (moved) static platform carries too
    Sim t;
    Entity sp = add_box3(t.world, "sp", {0, -0.5f, 0}, {6, 1, 6}, BodyType::Static, false);
    Entity r = add_box3(t.world, "r", {0, 0.6f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    t.run(60);
    t.world.get<Transform>(sp)->position.x += 1.5f;
    t.run(1);
    CHECK(std::fabs((pos_of(t.world, r).x) - (1.5f)) < 0.05);
}

TEST_CASE("2d: dynamic body rides a moving kinematic platform") {
    Sim s;
    Entity plat = add_box(s.world, "plat", {0, -20}, {400, 40}, BodyType::Kinematic);
    s.world.get<RigidBody2D>(plat)->velocity = {100, 0};
    Entity box = add_box(s.world, "box", {0, 16}, {32, 32}, BodyType::Dynamic);
    s.world.get<Collider2D>(box)->friction = 1.0f;
    s.world.get<Collider2D>(plat)->friction = 1.0f;
    s.run(90);
    float px = pos_of(s.world, plat).x, bx = pos_of(s.world, box).x;
    CHECK(px == doctest::Approx(150.0f).epsilon(0.05));
    CHECK(std::fabs(bx - px) < 25.0f);
    CHECK(s.physics.is_grounded(s.world, box));
}

TEST_CASE("3d: angularVelocity integrates into Transform.rotation") {
    Sim s;
    Entity e = add_box3(s.world, "spinner", {0, 10, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    s.world.get<RigidBody3D>(e)->gravityScale = 0.0f;
    s.world.get<RigidBody3D>(e)->angularVelocity = {0, 90, 0};
    s.run(60);
    CHECK(s.world.get<Transform>(e)->rotation.y == doctest::Approx(90.0f).epsilon(0.02));
    CHECK(s.world.get<RigidBody3D>(e)->angularVelocity.y == doctest::Approx(90.0f));
    // kinematic too
    Entity k = add_box3(s.world, "k", {5, 10, 0}, {1, 1, 1}, BodyType::Kinematic, true);
    s.world.get<RigidBody3D>(k)->angularVelocity = {0, 0, 180};
    s.run(30);
    CHECK(s.world.get<Transform>(k)->rotation.z == doctest::Approx(90.0f).epsilon(0.02));
}

TEST_CASE("3d: rolling sphere spins to match its motion; rollWithMotion=false does not") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {100, 1, 100}, BodyType::Static, false);
    Entity roll = add_sphere3(s.world, "roll", {0, 0.5f, -3}, 0.5f);
    Entity stay = add_sphere3(s.world, "stay", {0, 0.5f, 3}, 0.5f);
    s.world.get<RigidBody3D>(stay)->rollWithMotion = false;
    s.run(30);
    s.world.get<RigidBody3D>(roll)->velocity = {2, 0, 0};
    s.world.get<RigidBody3D>(stay)->velocity = {2, 0, 0};
    s.run(10);
    // v = (2,0,0): axis = up x v = (0,0,-2)/2 -> angular z = -|v|/r rad/s = -4 rad/s
    Vec3 w = s.world.get<RigidBody3D>(roll)->angularVelocity;
    CHECK(w.z < -100.0f);
    CHECK(std::fabs(w.x) < 1e-3f);
    CHECK(s.world.get<Transform>(roll)->rotation.z < -5.0f);
    CHECK(s.world.get<RigidBody3D>(stay)->angularVelocity == Vec3{});
    CHECK(s.world.get<Transform>(stay)->rotation == Vec3{});
}

TEST_CASE("3d: is_grounded and is_touching3d") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {40, 1, 40}, BodyType::Static, false);
    add_box3(s.world, "wall", {3.5f, 2, 0}, {1, 4, 10}, BodyType::Static, false);
    Entity ball = add_sphere3(s.world, "ball", {0, 3, 0}, 0.5f);
    s.run(2);
    CHECK_FALSE(s.physics.is_grounded(s.world, ball));
    s.run(100);
    CHECK(s.physics.is_grounded(s.world, ball));
    CHECK(s.physics.is_touching3d(s.world, ball, {0, -1, 0}));
    CHECK_FALSE(s.physics.is_touching3d(s.world, ball, {0, 1, 0}));
    CHECK_FALSE(s.physics.is_touching3d(s.world, ball, {1, 0, 0}));
    s.world.get<RigidBody3D>(ball)->velocity = {5, 0, 0};
    s.run(60);
    CHECK(s.physics.is_touching3d(s.world, ball, {1, 0, 0}));
    CHECK_FALSE(s.physics.is_touching3d(s.world, ball, {-1, 0, 0}));
    s.physics.apply_impulse(s.world, ball, {0, 6, 0});
    s.run(8);
    CHECK_FALSE(s.physics.is_grounded(s.world, ball));
    CHECK_FALSE(s.physics.is_grounded(s.world, kNullEntity));
}

TEST_CASE("2d: is_touching2d walls, ground, ceiling") {
    Sim s;
    add_ground(s.world);
    add_box(s.world, "wallR", {116, 0}, {20, 400}, BodyType::Static, false);
    add_box(s.world, "wallL", {-116, 0}, {20, 400}, BodyType::Static, false);
    add_box(s.world, "ceil", {0, 60}, {400, 20}, BodyType::Static, false);
    Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
    s.world.get<Collider2D>(box)->friction = 0.0f;
    s.run(60);
    CHECK(s.physics.is_touching2d(s.world, box, {0, -1}));
    CHECK_FALSE(s.physics.is_touching2d(s.world, box, {0, 1}));
    CHECK_FALSE(s.physics.is_touching2d(s.world, box, {1, 0}));
    CHECK_FALSE(s.physics.is_touching2d(s.world, box, {-1, 0}));
    // a character holding a direction re-applies its velocity every step
    auto push = [&](Vec2 v, int steps) {
        for (int i = 0; i < steps; ++i) { s.world.get<RigidBody2D>(box)->velocity = v; s.run(1); }
    };
    push({300, 0}, 60);
    CHECK(s.physics.is_touching2d(s.world, box, {1, 0}));
    CHECK_FALSE(s.physics.is_touching2d(s.world, box, {-1, 0}));
    push({-300, 0}, 90);
    CHECK(s.physics.is_touching2d(s.world, box, {-1, 0}));
    CHECK_FALSE(s.physics.is_touching2d(s.world, box, {1, 0}));
    push({0, 600}, 60);
    CHECK(s.physics.is_touching2d(s.world, box, {0, 1}));
}

TEST_CASE("2d: one-way platform lands from above and lets bodies jump through from below") {
    Sim s;
    add_ground(s.world, -200.0f);
    Entity plat = add_box(s.world, "plat", {0, 0}, {200, 16}, BodyType::Static, false);
    s.world.get<Collider2D>(plat)->oneWay = true;
    // lands from above
    Entity a = add_box(s.world, "a", {0, 100}, {32, 32}, BodyType::Dynamic);
    s.run(120);
    CHECK(std::fabs((pos_of(s.world, a).y) - (8.0f + 16.0f)) < 1.5f);
    CHECK(s.physics.is_grounded(s.world, a));
    // jumps through from below, then lands on top
    Entity b = add_box(s.world, "b", {60, -100}, {32, 32}, BodyType::Dynamic);
    s.world.get<RigidBody2D>(b)->velocity = {0, 600};
    float maxY = -1e9f;
    for (int i = 0; i < 20; ++i) { s.run(1); maxY = std::max(maxY, pos_of(s.world, b).y); }
    s.run(200);
    CHECK(maxY > 20.0f);  // went through
    CHECK(pos_of(s.world, b).y > 8.0f);
    CHECK(s.physics.is_grounded(s.world, b));
    // sides never block
    Sim s2;
    Entity plat2 = add_box(s2.world, "plat", {0, 0}, {200, 16}, BodyType::Static, false);
    s2.world.get<Collider2D>(plat2)->oneWay = true;
    Entity c = add_box(s2.world, "c", {-300, 0}, {32, 32}, BodyType::Dynamic);
    s2.world.get<RigidBody2D>(c)->gravityScale = 0.0f;
    s2.world.get<RigidBody2D>(c)->velocity = {400, 0};
    s2.run(60);
    CHECK(pos_of(s2.world, c).x > 90.0f);
}
