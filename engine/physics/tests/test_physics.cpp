#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/physics/physics.h"
#include "fa/scene/tilemap.h"

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

TEST_CASE("2d: a tilemap written as rows, without width/height, collides exactly where it is drawn") {
    // Same map as above, but tiles is an array of rows and width/height are NOT set. The renderer sizes the map from the
    // rows; physics must do the same (both use tilemap_grid), otherwise the floor would not exist.
    Sim s;
    Entity map = s.world.create("map", "map");
    s.world.get<Transform>(map)->position = {-80, 0, 0};  // top-left corner of the map
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {16, 16};
    REQUIRE(tm.width == 0);
    REQUIRE(tm.height == 0);
    Json rows = Json::array();
    for (int r = 0; r < 3; ++r) {
        Json row = Json::array();
        for (int c = 0; c < 10; ++c) row.push_back(r == 2 ? 1 : (r == 1 && c == 9 ? 2 : -1));
        rows.push_back(row);
    }
    tm.tiles = rows;
    tm.solidTiles = Json::array({1, 2});
    CHECK(check_tilemap(tm).empty());
    const TilemapGrid grid = tilemap_grid(tm);
    CHECK((grid.width == 10 && grid.height == 3));

    Entity box = add_box(s.world, "box", {0, 100}, {16, 16}, BodyType::Dynamic);
    s.run(180);
    // bottom row spans y in [-48, -32]: the box rests on top of it (y = -32 + 8), exactly like the flat form.
    CHECK(pos_of(s.world, box).y == doctest::Approx(-24.0f).epsilon(0.03));
    // wall tile at column 9, row 1: x in [64, 80]
    auto hit = s.physics.raycast2d(s.world, {40, -24}, {100, -24});
    REQUIRE(hit.has_value());
    CHECK(hit->point.x == doctest::Approx(64.0f).epsilon(0.01));
    CHECK_FALSE(s.physics.raycast2d(s.world, {-100, -24}, {-85, -24}).has_value());
}

TEST_CASE("2d: in rows form the rows win over stale width/height; a flat list without width is one row") {
    {
        Sim s;
        Entity map = s.world.create("map", "map");
        s.world.get<Transform>(map)->position = {-80, 0, 0};
        Tilemap& tm = s.world.add<Tilemap>(map);
        tm.tileSize = {16, 16};
        tm.width = 2;   // wrong on purpose (check_tilemap reports it); the renderer draws 10 x 1 and so does physics
        tm.height = 5;
        Json row = Json::array();
        for (int c = 0; c < 10; ++c) row.push_back(1);
        tm.tiles = Json::array({row});
        tm.solidTiles = Json::array({1});
        CHECK_FALSE(check_tilemap(tm).empty());
        Entity box = add_box(s.world, "box", {70, 100}, {16, 16}, BodyType::Dynamic);  // over column 9, outside width 2
        s.run(180);
        CHECK(pos_of(s.world, box).y == doctest::Approx(8.0f).epsilon(0.03));  // row 0 spans y in [-16, 0]: rests on y = 0
    }
    {
        Sim s;
        Entity map = s.world.create("map", "map");
        s.world.get<Transform>(map)->position = {-40, 0, 0};
        Tilemap& tm = s.world.add<Tilemap>(map);
        tm.tileSize = {16, 16};
        tm.tiles = Json::array({-1, -1, 1, 1, -1});  // no width/height: ONE row of 5 tiles, solid at columns 2 and 3
        tm.solidTiles = Json::array({1});
        Entity box = add_box(s.world, "box", {0, 100}, {16, 16}, BodyType::Dynamic);  // x in [-8, 8]: over columns 2 and 3
        s.run(180);
        CHECK(pos_of(s.world, box).y == doctest::Approx(8.0f).epsilon(0.03));  // rests on the top edge y = 0
    }
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

TEST_CASE("2d: an entity pending destroy leaves physics at once: no push on a replacement, no query hits") {
    Sim s;
    add_ground(s.world);
    Entity old = add_box(s.world, "old", {0, -180.0f + 16.0f}, {32, 32}, BodyType::Dynamic);
    Entity lone = add_box(s.world, "lone", {300, -150}, {40, 40}, BodyType::Static, false);
    s.run(60);
    const Vec3 rest = pos_of(s.world, old);
    REQUIRE(s.physics.raycast2d(s.world, {300, 100}, {300, -300}).has_value());

    s.world.destroy(old);  // deferred: no flush before the physics steps, like a script's fixed update
    s.world.destroy(lone);
    Entity fresh = add_box(s.world, "fresh", {rest.x, rest.y}, {32, 32}, BodyType::Dynamic);
    // queries ignore the entity right away, even before the next sync
    auto before = s.physics.raycast2d(s.world, {300, 100}, {300, -300});
    REQUIRE(before.has_value());
    CHECK(before->entity != lone);
    for (int i = 0; i < 3; ++i) s.physics.step(s.world, kDt);  // several fixed steps of the same frame
    CHECK(pos_of(s.world, fresh).x == doctest::Approx(rest.x).epsilon(0.01));
    CHECK(pos_of(s.world, fresh).y == doctest::Approx(rest.y).epsilon(0.01));
    CHECK(std::fabs(s.world.get<RigidBody2D>(fresh)->velocity.y) < 1.0f);
    CHECK(s.physics.debug_state(s.world).size() == 2);  // ground + fresh; old and lone have no body
    auto after = s.physics.raycast2d(s.world, {300, 100}, {300, -300});
    REQUIRE(after.has_value());
    CHECK(after->entity != lone);
    s.world.flush();
    CHECK(s.physics.debug_state(s.world).size() == 2);
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
    // sideways velocity decays through sliding friction (a rolling sphere keeps rolling: see the rolling resistance test)
    s.world.get<RigidBody3D>(ball)->rollWithMotion = false;
    s.world.get<RigidBody3D>(ball)->lockRotation = true;  // contacts do not spin it: a sliding ball
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

TEST_CASE("3d: an entity pending destroy leaves physics at once: no push on a replacement, no query hits") {
    Sim s;
    Entity ground = add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity old = add_box3(s.world, "old", {0, 0.5f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    Entity lone = add_box3(s.world, "lone", {5, 0.5f, 0}, {1, 1, 1}, BodyType::Static, false);
    s.run(60);
    const Vec3 rest = pos_of(s.world, old);
    auto lonely = s.physics.raycast3d(s.world, {5, 10, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(lonely.has_value());
    REQUIRE(lonely->entity == lone);

    s.world.destroy(old);  // deferred: no flush before the physics steps, like a script's fixed update
    s.world.destroy(lone);
    Entity fresh = add_box3(s.world, "fresh", rest, {1, 1, 1}, BodyType::Dynamic, true);
    // queries ignore the entity right away, even before the next sync
    auto before = s.physics.raycast3d(s.world, {5, 10, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(before.has_value());
    CHECK(before->entity == ground);
    for (int i = 0; i < 3; ++i) s.physics.step(s.world, kDt);  // several fixed steps of the same frame
    const Vec3 p = pos_of(s.world, fresh);
    CHECK(p.x == doctest::Approx(rest.x).epsilon(0.01));
    CHECK(p.y == doctest::Approx(rest.y).epsilon(0.01));
    CHECK(p.z == doctest::Approx(rest.z).epsilon(0.01));
    CHECK(std::fabs(s.world.get<RigidBody3D>(fresh)->velocity.y) < 0.5f);
    CHECK(s.physics.debug_state(s.world).size() == 2);  // ground + fresh; old and lone have no body
    auto after = s.physics.raycast3d(s.world, {5, 10, 0}, {0, -1, 0}, 100.0f);
    REQUIRE(after.has_value());
    CHECK(after->entity == ground);
    s.world.flush();
    CHECK(s.physics.debug_state(s.world).size() == 2);
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

// ------------------------------------------------------ 2D shape casts ----

namespace {
CastShape circle_cast(float radius) {
    CastShape s;
    s.kind = CastShape::Kind::Circle;
    s.radius = radius;
    return s;
}
CastShape box_cast(float w, float h) {
    CastShape s;
    s.kind = CastShape::Kind::Box;
    s.size = {w, h, 1};
    return s;
}
}  // namespace

TEST_CASE("2d: shape cast of a circle and a box lands on the surface, with the hit normal") {
    Sim s;
    Entity ground = add_ground(s.world);  // top at y = -180
    Entity wall = add_box(s.world, "wall", {100, 0}, {20, 100}, BodyType::Static, false);  // left face at x = 90
    Entity ball = add_box(s.world, "ball", {100, 200}, {1, 1}, BodyType::Static, false);
    Collider2D& bc = *s.world.get<Collider2D>(ball);
    bc.shape = ColliderShape::Circle;
    bc.radius = 20;  // circle collider centred at (100, 200)
    s.run(2);

    // circle r=8 falling onto the ground: the centre stops at y = -172
    auto hit = s.physics.shape_cast2d(s.world, circle_cast(8), {0, 100}, {0, -300});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    CHECK(hit->distance == doctest::Approx(272.0f).epsilon(0.0005));
    CHECK(hit->point.y == doctest::Approx(-180.0f).epsilon(0.01));
    CHECK(hit->normal.x == doctest::Approx(0.0f).epsilon(0.01));
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));

    // box 32x16 (half height 8) falling onto the ground: same stop
    hit = s.physics.shape_cast2d(s.world, box_cast(32, 16), {0, 100}, {0, -300});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    CHECK(hit->distance == doctest::Approx(272.0f).epsilon(0.0005));
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));

    // box 40x40 moving right into the wall: stops 20 px before its left face; the normal points back at the box
    hit = s.physics.shape_cast2d(s.world, box_cast(40, 40), {-100, 0}, {300, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(hit->distance == doctest::Approx(170.0f).epsilon(0.0005));
    CHECK(hit->point.x == doctest::Approx(90.0f).epsilon(0.0005));
    CHECK(hit->normal.x == doctest::Approx(-1.0f).epsilon(0.01));
    // and from the other side
    hit = s.physics.shape_cast2d(s.world, circle_cast(10), {300, 0}, {-100, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(hit->distance == doctest::Approx(300.0f - 110.0f - 10.0f).epsilon(0.0005));
    CHECK(hit->normal.x == doctest::Approx(1.0f).epsilon(0.01));

    // circle r=10 against the circle collider (r=20 at (100, 200)): centres stop 30 apart
    hit = s.physics.shape_cast2d(s.world, circle_cast(10), {-100, 200}, {300, 200});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ball);
    CHECK(hit->distance == doctest::Approx(170.0f).epsilon(0.0005));
    CHECK(hit->point.x == doctest::Approx(80.0f).epsilon(0.01));
    CHECK(hit->normal.x == doctest::Approx(-1.0f).epsilon(0.01));

    // a shape sweeps an area, a ray a line: the wall spans y in [-50, 50]; a ray along y=60 misses it, a box does not
    CHECK_FALSE(s.physics.raycast2d(s.world, {-100, 60}, {300, 60}).has_value());
    hit = s.physics.shape_cast2d(s.world, box_cast(40, 40), {-100, 60}, {300, 60});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(hit->normal.x == doctest::Approx(-1.0f).epsilon(0.01));
    // a collider rotated by 45 degrees: the normal is the face normal, not an axis
    Entity ramp = add_box(s.world, "ramp", {-500, 0}, {200, 20}, BodyType::Static, false);
    s.world.get<Transform>(ramp)->rotation.z = 45.0f;
    s.run(2);
    hit = s.physics.shape_cast2d(s.world, circle_cast(10), {-500, 300}, {-500, -300});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ramp);
    CHECK(hit->normal.x == doctest::Approx(-0.7071f).epsilon(0.01));
    CHECK(hit->normal.y == doctest::Approx(0.7071f).epsilon(0.01));
    CHECK(hit->distance == doctest::Approx(300.0f - 28.284f).epsilon(0.0005));
    // null when the path is clear, and for a zero-length cast
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box_cast(40, 40), {-100, 120}, {300, 120}).has_value());
    CHECK_FALSE(s.physics.shape_cast2d(s.world, circle_cast(8), {0, 100}, {0, 100}).has_value());
    CHECK_FALSE(s.physics.shape_cast2d(s.world, circle_cast(8), {0, 100}, {0, -100}).has_value());  // stops short of the ground
}

TEST_CASE("2d: shape cast against tilemap tiles reports the Tilemap entity") {
    Sim s;
    Entity map = s.world.create("map", "map");
    s.world.get<Transform>(map)->position = {-80, 0, 0};
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {16, 16};
    tm.width = 10;
    tm.height = 3;
    Json tiles = Json::array();
    for (int r = 0; r < 3; ++r)
        for (int c = 0; c < 10; ++c) tiles.push_back(r == 2 ? 1 : (r == 1 && c == 9 ? 2 : -1));
    tm.tiles = tiles;
    tm.solidTiles = Json::array({1, 2});
    s.run(2);
    // wall tile: x in [64, 80], y in [-32, -16]; a circle r=4 along y=-24 stops with its centre at x=60
    auto hit = s.physics.shape_cast2d(s.world, circle_cast(4), {40, -24}, {100, -24});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == map);
    CHECK(hit->distance == doctest::Approx(20.0f).epsilon(0.01));
    CHECK(hit->normal.x == doctest::Approx(-1.0f).epsilon(0.01));
    // a box falling onto the bottom row (top at y=-32): the centre stops at y=-28
    hit = s.physics.shape_cast2d(s.world, box_cast(8, 8), {0, 0}, {0, -100});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == map);
    CHECK(hit->distance == doctest::Approx(28.0f).epsilon(0.01));
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));
    // the open cell on the left lets a small shape through
    CHECK_FALSE(s.physics.shape_cast2d(s.world, circle_cast(4), {-100, -24}, {-85, -24}).has_value());
}

TEST_CASE("2d: shape cast honours mask, ignore (and descendants) and ignoreTriggers") {
    Sim s;
    Entity ground = add_ground(s.world);
    Entity crate = add_box(s.world, "crate", {200, -150}, {60, 60}, BodyType::Static, false);
    s.world.get<Collider2D>(crate)->layer = 3;
    Entity trig = add_box(s.world, "trig", {-200, -100}, {40, 40}, BodyType::Static, false);
    s.world.get<Collider2D>(trig)->isTrigger = true;
    Entity child = add_box(s.world, "child", {400, -150}, {30, 30}, BodyType::Static, false);
    s.world.set_parent(child, crate, true);
    s.run(2);
    const CastShape box = box_cast(20, 20);

    // mask: layer 0 is the ground, layer 3 the crate
    RaycastOptions o;
    o.mask = 1 << 3;
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box, {0, 100}, {0, -300}, o).has_value());
    auto hit = s.physics.shape_cast2d(s.world, box, {200, 100}, {200, -300}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == crate);
    o.mask = 1 << 0;
    hit = s.physics.shape_cast2d(s.world, box, {200, 100}, {200, -300}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);  // the crate is not in the mask: the cast reaches the ground

    // ignore skips the entity and its descendants
    o = {};
    o.ignore = crate;
    hit = s.physics.shape_cast2d(s.world, box, {200, 100}, {200, -300}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    hit = s.physics.shape_cast2d(s.world, box, {400, 100}, {400, -300}, o);  // the child's column
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    hit = s.physics.shape_cast2d(s.world, box, {400, 100}, {400, -300});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == child);
    o = {};
    o.ignore = ground;
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box, {0, 100}, {0, -300}, o).has_value());

    // triggers are invisible unless ignoreTriggers=false
    hit = s.physics.shape_cast2d(s.world, box, {-200, 100}, {-200, -300});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    o = {};
    o.ignoreTriggers = false;
    hit = s.physics.shape_cast2d(s.world, box, {-200, 100}, {-200, -300}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == trig);
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));
}

TEST_CASE("2d: shape cast skips colliders it overlaps at the start, but not ones it only touches") {
    Sim s;
    Entity ground = add_ground(s.world);  // top at y = -180
    add_box(s.world, "caster", {0, 0}, {40, 40}, BodyType::Static, false);
    Entity wall = add_box(s.world, "wall", {100, 0}, {20, 100}, BodyType::Static, false);  // left face at x = 90
    s.run(2);

    // overlapping the caster's own collider at the start: skipped, the wall is the first hit
    auto hit = s.physics.shape_cast2d(s.world, box_cast(20, 20), {0, 0}, {300, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(hit->distance == doctest::Approx(80.0f).epsilon(0.0005));
    hit = s.physics.shape_cast2d(s.world, circle_cast(10), {0, 0}, {300, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(hit->distance == doctest::Approx(80.0f).epsilon(0.0005));
    // buried in the ground: the ground is skipped
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box_cast(20, 20), {0, -190}, {0, -300}).has_value());
    CHECK_FALSE(s.physics.shape_cast2d(s.world, circle_cast(10), {500, -185}, {500, -300}).has_value());

    // touching without overlapping: the collider blocks a cast moving towards it (distance 0) and nothing else.
    // a box 20x20 sitting exactly on the ground (centre y = -170)
    hit = s.physics.shape_cast2d(s.world, box_cast(20, 20), {500, -170}, {500, -270});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    CHECK(std::fabs(hit->distance) < 0.5f);
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box_cast(20, 20), {500, -170}, {500, -100}).has_value());  // moving away
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box_cast(20, 20), {500, -170}, {800, -170}).has_value());  // sliding along
    hit = s.physics.shape_cast2d(s.world, circle_cast(10), {500, -170}, {500, -270});
    REQUIRE(hit.has_value());
    CHECK(std::fabs(hit->distance) < 0.5f);
    // touching the wall's left face (box right edge at x = 90): moving right is blocked at once, moving left is free
    hit = s.physics.shape_cast2d(s.world, box_cast(20, 20), {80, 40}, {200, 40});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(std::fabs(hit->distance) < 0.5f);
    CHECK(hit->normal.x == doctest::Approx(-1.0f).epsilon(0.01));
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box_cast(20, 20), {80, 40}, {-200, 40}).has_value());
}

TEST_CASE("2d: a body resting on the ground is touching it: a cast down hits at once, a cast up does not") {
    Sim s;
    Entity ground = add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, 100}, {32, 32}, BodyType::Dynamic);
    s.run(180);
    const Vec3 p = pos_of(s.world, box);
    REQUIRE(p.y == doctest::Approx(-164.0f).epsilon(0.02));
    RaycastOptions o;
    o.ignore = box;
    // the same shape as the body, cast from where it rests (the solver leaves it up to 0.5 px into the ground)
    auto hit = s.physics.shape_cast2d(s.world, box_cast(32, 32), {p.x, p.y}, {p.x, p.y - 50}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
    CHECK(hit->distance < 1.0f);
    CHECK(hit->normal.y == doctest::Approx(1.0f).epsilon(0.01));
    CHECK_FALSE(s.physics.shape_cast2d(s.world, box_cast(32, 32), {p.x, p.y}, {p.x, p.y + 50}, o).has_value());
    // without `ignore` the body's own collider contains the start: skipped, same result
    hit = s.physics.shape_cast2d(s.world, box_cast(32, 32), {p.x, p.y}, {p.x, p.y - 50});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == ground);
}

TEST_CASE("cast_shape_from_json parses 2D and 3D shapes and explains mistakes") {
    auto msg = [](const char* json, bool is3d) {
        auto r = cast_shape_from_json(Json::parse(json), is3d);
        REQUIRE_FALSE(r.ok());
        return r.error().to_string();
    };
    auto has = [](const std::string& s, const char* part) { return s.find(part) != std::string::npos; };

    auto c = cast_shape_from_json(Json::parse(R"({"shape":"circle","radius":8})"), false);
    REQUIRE(c.ok());
    CHECK(c->kind == CastShape::Kind::Circle);
    CHECK(c->radius == 8.0f);
    auto b = cast_shape_from_json(Json::parse(R"({"shape":"box","size":[16,24]})"), false);
    REQUIRE(b.ok());
    CHECK(b->kind == CastShape::Kind::Box);
    CHECK(b->size.x == 16.0f);
    CHECK(b->size.y == 24.0f);
    auto b2 = cast_shape_from_json(Json::parse(R"({"shape":"Box","size":{"x":2,"y":3}})"), false);
    REQUIRE(b2.ok());
    CHECK(b2->size.y == 3.0f);
    auto sp = cast_shape_from_json(Json::parse(R"({"shape":"sphere","radius":0.5})"), true);
    REQUIRE(sp.ok());
    CHECK(sp->kind == CastShape::Kind::Circle);
    auto b3 = cast_shape_from_json(Json::parse(R"({"shape":"box","size":[1,2,3]})"), true);
    REQUIRE(b3.ok());
    CHECK(b3->size.z == 3.0f);

    std::string m = msg(R"({"shape":"circel","radius":8})", false);
    CHECK(has(m, "circel"));
    CHECK(has(m, "Did you mean 'circle'"));
    CHECK(has(m, "Example"));
    m = msg(R"({"shape":"sphere","radius":8})", false);
    CHECK(has(m, "3D shape"));
    CHECK(has(m, "\"circle\""));
    m = msg(R"({"shape":"circle","radius":8})", true);
    CHECK(has(m, "2D shape"));
    CHECK(has(m, "\"sphere\""));
    m = msg(R"({"shape":"sfere","radius":1})", true);
    CHECK(has(m, "Did you mean 'sphere'"));
    CHECK(has(msg(R"({"shape":"circle"})", false), "needs \"radius\""));
    CHECK(has(msg(R"({"shape":"circle","radius":-3})", false), "-3"));
    CHECK(has(msg(R"({"shape":"circle","size":[1,2]})", false), "\"radius\", not \"size\""));
    CHECK(has(msg(R"({"shape":"box","radius":4})", false), "\"size\", not \"radius\""));
    CHECK(has(msg(R"({"shape":"circle","raduis":4,"radius":4})", false), "Did you mean 'radius'"));
    CHECK(has(msg(R"({"shape":"box","size":[1,2]})", true), "[x, y, z]"));
    CHECK(has(msg(R"({"shape":"box","size":[1,2,3]})", false), "[width, height]"));
    CHECK(has(msg(R"({"shape":"box","size":[0,2]})", false), "positive"));
    CHECK(has(msg(R"({"radius":2})", false), "no \"shape\" name"));
    CHECK(has(msg(R"("circle")", false), "object"));
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

TEST_CASE("3d: rolling sphere spins to match its motion; rollWithMotion=false with lockRotation does not") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {100, 1, 100}, BodyType::Static, false);
    Entity roll = add_sphere3(s.world, "roll", {0, 0.5f, -3}, 0.5f);
    Entity stay = add_sphere3(s.world, "stay", {0, 0.5f, 3}, 0.5f);
    s.world.get<RigidBody3D>(stay)->rollWithMotion = false;
    s.world.get<RigidBody3D>(stay)->lockRotation = true;
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

// ---------------------------------------------------- sleeping bodies ----
// Box2D puts a resting body to sleep and then ignores it, so what gameplay does to a sleeping body matters.

namespace {

// Box2D's own view of a 2D body, read through Physics::debug_state: true while it simulates.
bool body_awake(const Sim& s, const char* id) {
    for (const Json& j : s.physics.debug_state(s.world)) {
        if (j.value("entity", std::string()) == id && j.contains("awake")) return j["awake"].get<bool>();
    }
    FAIL("no 2D body '" << std::string(id) << "' in Physics::debug_state (bodies exist after the first step)");
    return false;
}

// Steps until Box2D reports the body asleep (a resting body needs about half a second of calm).
bool run_until_asleep(Sim& s, const char* id, int maxSteps = 600) {
    s.run(1);  // bodies are created by the first step
    for (int i = 0; i < maxSteps && body_awake(s, id); ++i) s.run(1);
    return !body_awake(s, id);
}

constexpr float kRestY = -180.0f + 16.0f;  // centre of a 32 px box resting on the default ground

}  // namespace

TEST_CASE("2d: a body that lands rocking keeps its Box2D body, stops generating contact events and falls asleep") {
    // A 64 px drop makes the box rock by a hair. Its world scale then comes back from the world matrix as 1 or
    // 0.99999994 depending on the rotation; that noise used to rebuild the body over and over (an awake body with
    // fresh contacts each time: begin/end events forever, never asleep).
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
    CHECK(run_until_asleep(s, "box", 300));
    CHECK(pos_of(s.world, box).y == doctest::Approx(kRestY).epsilon(0.02));
    CHECK(s.count(CollisionEvent::Phase::Begin, false) <= 3);  // landing (a bounce or two at most), not chattering
    const std::size_t seen = s.events.size();
    s.run(120);
    CHECK(s.events.size() == seen);
    CHECK_FALSE(body_awake(s, "box"));
}

// ------------------------------------- gameplay writes to sleeping bodies ----
// Teleporting (Transform), tilting, moving the ground, enabling/disabling: a sleeping body must follow all of it.

TEST_CASE("2d: writing Transform.position on a sleeping body wakes it; it falls, lands and isGrounded follows") {
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "box"));
    CHECK(pos_of(s.world, box).y == doctest::Approx(kRestY).epsilon(0.02));
    CHECK(s.physics.is_grounded(s.world, box));

    s.world.get<Transform>(box)->position.y += 28.0f;  // what a script does: teleport 28 px up
    s.run(1);
    CHECK(body_awake(s, "box"));
    CHECK_FALSE(s.physics.is_grounded(s.world, box));  // the stale ground contact is gone after one step
    s.run(3);
    CHECK(pos_of(s.world, box).y < kRestY + 28.0f);  // falling, not hovering
    CHECK_FALSE(s.physics.is_grounded(s.world, box));
    s.run(90);
    CHECK(pos_of(s.world, box).y == doctest::Approx(kRestY).epsilon(0.02));  // landed again
    CHECK(s.physics.is_grounded(s.world, box));
    CHECK(run_until_asleep(s, "box"));  // and rests until asleep once more
}

TEST_CASE("2d: a sleeping body teleported sideways off its ledge falls") {
    Sim s;
    add_box(s.world, "ledge", {0, -100}, {200, 20}, BodyType::Static, false);   // top at -90
    add_box(s.world, "floor", {0, -400}, {2000, 20}, BodyType::Static, false);  // top at -390
    Entity box = add_box(s.world, "box", {0, -60}, {32, 32}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "box"));
    CHECK(pos_of(s.world, box).y == doctest::Approx(-74.0f).epsilon(0.02));
    s.world.get<Transform>(box)->position.x = 400.0f;
    s.run(1);
    CHECK_FALSE(s.physics.is_grounded(s.world, box));
    s.run(120);
    CHECK(pos_of(s.world, box).x == doctest::Approx(400.0f).epsilon(0.01));
    CHECK(pos_of(s.world, box).y == doctest::Approx(-390.0f + 16.0f).epsilon(0.02));
}

TEST_CASE("2d: writing Transform.rotation on a sleeping body wakes it") {
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "box"));
    s.world.get<Transform>(box)->rotation.z = 30.0f;
    s.run(1);
    CHECK(body_awake(s, "box"));
    // the tilted box topples and settles flat again (a multiple of 90 degrees), then sleeps
    CHECK(run_until_asleep(s, "box"));
    float rot = std::fmod(std::fabs(s.world.get<Transform>(box)->rotation.z), 90.0f);
    CHECK(std::min(rot, 90.0f - rot) < 1.0f);
    CHECK(pos_of(s.world, box).y == doctest::Approx(kRestY).epsilon(0.03));
}

TEST_CASE("2d: writing a velocity wakes a sleeping body") {
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "box"));
    s.world.get<RigidBody2D>(box)->velocity = {0, 400};
    s.run(5);
    CHECK(body_awake(s, "box"));
    CHECK(pos_of(s.world, box).y > kRestY + 20.0f);
    REQUIRE(run_until_asleep(s, "box"));
    s.world.get<RigidBody2D>(box)->angularVelocity = 90.0f;
    s.run(2);
    CHECK(body_awake(s, "box"));
}

TEST_CASE("2d: teleporting the bottom of a sleeping stack wakes the whole pile") {
    Sim s;
    add_ground(s.world);
    Entity lower = add_box(s.world, "lower", {0, -100}, {32, 32}, BodyType::Dynamic);
    Entity upper = add_box(s.world, "upper", {0, -60}, {32, 32}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "lower"));
    REQUIRE(run_until_asleep(s, "upper"));
    CHECK(pos_of(s.world, upper).y == doctest::Approx(kRestY + 32.0f).epsilon(0.03));
    s.world.get<Transform>(lower)->position.x = 600.0f;  // pull the bottom box out
    s.run(1);
    CHECK(body_awake(s, "lower"));
    CHECK(body_awake(s, "upper"));
    s.run(90);
    CHECK(pos_of(s.world, upper).y == doctest::Approx(kRestY).epsilon(0.03));  // the top box dropped to the ground
    CHECK(pos_of(s.world, lower).y == doctest::Approx(kRestY).epsilon(0.03));
}

TEST_CASE("2d: moving a static or kinematic platform wakes the body asleep on it") {
    for (BodyType type : {BodyType::Static, BodyType::Kinematic}) {
        CAPTURE(int(type));
        Sim s;
        add_box(s.world, "floor", {0, -400}, {2000, 20}, BodyType::Static, false);  // top at -390
        Entity plat = add_box(s.world, "plat", {0, -100}, {200, 20}, type, type != BodyType::Static);
        Entity box = add_box(s.world, "box", {0, -60}, {32, 32}, BodyType::Dynamic);
        REQUIRE(run_until_asleep(s, "box"));
        CHECK(s.physics.is_grounded(s.world, box));
        s.world.get<Transform>(plat)->position.x = 700.0f;  // the platform leaves, the box stays
        s.run(1);
        CHECK(body_awake(s, "box"));
        CHECK_FALSE(s.physics.is_grounded(s.world, box));
        s.run(120);
        CHECK(std::fabs(pos_of(s.world, box).x) < 2.0f);  // it dropped straight down (it was never carried along)
        CHECK(pos_of(s.world, box).y == doctest::Approx(-390.0f + 16.0f).epsilon(0.02));
        CHECK(pos_of(s.world, plat).x == doctest::Approx(700.0f).epsilon(0.001));
        // a kinematic body can be teleported while it is the one asleep, too
        if (type == BodyType::Kinematic) {
            s.world.get<Transform>(plat)->position = {0, -300, 0};
            s.run(1);
            CHECK(pos_of(s.world, plat).y == doctest::Approx(-300.0f).epsilon(0.001));
            CHECK(pos_of(s.world, plat).x == doctest::Approx(0.0f).epsilon(0.001));
        }
    }
}

TEST_CASE("2d: moving a tilemap wakes the body asleep on it") {
    Sim s;
    add_box(s.world, "floor", {0, -400}, {2000, 20}, BodyType::Static, false);  // top at -390
    Entity map = s.world.create("map", "map");
    s.world.get<Transform>(map)->position = {-80, -100, 0};
    Tilemap& tm = s.world.add<Tilemap>(map);
    tm.tileSize = {16, 16};
    tm.width = 10;
    tm.height = 1;
    Json tiles = Json::array();
    for (int c = 0; c < 10; ++c) tiles.push_back(1);
    tm.tiles = tiles;
    tm.solidTiles = Json::array({1});  // one row of solid tiles, top edge at y = -100
    Entity box = add_box(s.world, "box", {0, -60}, {16, 16}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "box"));
    CHECK(pos_of(s.world, box).y == doctest::Approx(-92.0f).epsilon(0.02));
    s.world.get<Transform>(map)->position.x = 900.0f;
    s.run(1);
    CHECK(body_awake(s, "box"));
    s.run(120);
    CHECK(pos_of(s.world, box).y == doctest::Approx(-390.0f + 8.0f).epsilon(0.02));
}

TEST_CASE("2d: sleeping bodies wake when their entity or their ground is enabled, disabled or destroyed") {
    // The entity is disabled while asleep, teleported while disabled, and enabled again.
    {
        Sim s;
        add_ground(s.world);
        Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
        REQUIRE(run_until_asleep(s, "box"));
        s.world.set_active(box, false);
        s.run(2);
        s.world.get<Transform>(box)->position = {50, 100, 0};
        s.run(2);
        s.world.set_active(box, true);
        s.run(1);
        CHECK(body_awake(s, "box"));
        s.run(120);
        CHECK(pos_of(s.world, box).x == doctest::Approx(50.0f).epsilon(0.01));
        CHECK(pos_of(s.world, box).y == doctest::Approx(kRestY).epsilon(0.02));
    }
    // The ground under a sleeping box is disabled, then destroyed.
    for (int mode = 0; mode < 2; ++mode) {
        CAPTURE(mode);
        Sim s;
        Entity ground = add_ground(s.world);
        Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
        REQUIRE(run_until_asleep(s, "box"));
        if (mode == 0) s.world.set_active(ground, false);
        else s.world.destroy(ground);
        s.run(30);
        CHECK(body_awake(s, "box"));
        CHECK(pos_of(s.world, box).y < kRestY - 100.0f);  // nothing holds it any more
    }
}

TEST_CASE("2d: changing the body type of a sleeping body takes effect") {
    Sim s;
    add_ground(s.world);
    Entity box = add_box(s.world, "box", {0, -100}, {32, 32}, BodyType::Dynamic);
    REQUIRE(run_until_asleep(s, "box"));
    s.world.get<RigidBody2D>(box)->type = BodyType::Kinematic;
    s.world.get<RigidBody2D>(box)->velocity = {120, 0};
    s.run(30);
    CHECK(pos_of(s.world, box).x == doctest::Approx(60.0f).epsilon(0.05));
    s.world.get<RigidBody2D>(box)->type = BodyType::Dynamic;
    s.world.get<RigidBody2D>(box)->velocity = {0, 0};
    s.world.get<Transform>(box)->position.y += 28.0f;
    s.run(90);
    CHECK(pos_of(s.world, box).y == doctest::Approx(kRestY).epsilon(0.03));
}

TEST_CASE("3d: bodies never sleep; writing Transform.position moves a resting body and drops grounded") {
    Sim s;
    add_box3(s.world, "ground", {0, -0.5f, 0}, {40, 1, 40}, BodyType::Static, false);
    Entity ball = add_sphere3(s.world, "ball", {0, 2, 0}, 0.5f);
    s.run(240);
    CHECK(pos_of(s.world, ball).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(s.physics.is_grounded(s.world, ball));
    s.world.get<Transform>(ball)->position.y += 2.0f;
    s.run(1);
    CHECK_FALSE(s.physics.is_grounded(s.world, ball));
    s.run(2);
    CHECK(pos_of(s.world, ball).y < 2.5f);  // falling
    s.run(120);
    CHECK(pos_of(s.world, ball).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(s.physics.is_grounded(s.world, ball));
    // a ground teleported by gameplay carries the body resting on it (documented 3D rider behaviour), which keeps
    // resting: nothing is left behind on stale contacts
    Sim s2;
    Entity ground = add_box3(s2.world, "ground", {0, -0.5f, 0}, {4, 1, 4}, BodyType::Static, false);
    Entity cube = add_box3(s2.world, "cube", {0, 3, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    s2.run(240);
    CHECK(pos_of(s2.world, cube).y == doctest::Approx(0.5f).epsilon(0.02));
    s2.world.get<Transform>(ground)->position.x = 100.0f;
    s2.run(60);
    CHECK(pos_of(s2.world, cube).x == doctest::Approx(100.0f).epsilon(0.01));
    CHECK(pos_of(s2.world, cube).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(s2.physics.is_grounded(s2.world, cube));
}

// ------------------------------------------- 3D physics 2.0 (M5 package A) ----

namespace {
Entity add_turned_box3(World& w, const char* id, Vec3 pos, Vec3 size, Vec3 rotation, BodyType type, bool withBody) {
    Entity e = add_box3(w, id, pos, size, type, withBody);
    w.get<Transform>(e)->rotation = rotation;
    return e;
}
Entity add_static_sphere3(World& w, const char* id, Vec3 pos, float radius) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Sphere;
    c.radius = radius;
    return e;
}
void no_gravity(Sim& s) { s.world.settings().gravity3D = {0, 0, 0}; }
// Deterministic pseudo-random value in [0, 1) (golden-ratio style sequence): i-th term of the sequence for step k.
float frac(int i, float k) { float x = float(i) * k; return x - std::floor(x); }
float deg_apart(Vec3 a, Vec3 b) { return std::max({std::fabs(a.x - b.x), std::fabs(a.y - b.y), std::fabs(a.z - b.z)}); }
}  // namespace

TEST_CASE("3d: a box rotated 45 degrees about Y blocks a sphere at its rotated edge, not at the AABB corner") {
    // A 4x2x4 box turned 45 degrees is a diamond: its vertices are 2.83 m from the centre, its AABB is 5.66 m wide.
    // A sphere (r 0.3) rolling along +x at z = 2.5 would be stopped by the AABB at x = -3.13, but the diamond's
    // face -x + z = 2.83 only reaches it at x = -0.75.
    Sim s;
    no_gravity(s);
    Entity box = add_turned_box3(s.world, "box", {0, 0, 0}, {4, 2, 4}, {0, 45, 0}, BodyType::Static, false);
    Entity ball = add_sphere3(s.world, "ball", {-8, 0, 2.5f}, 0.3f);
    s.world.get<RigidBody3D>(ball)->velocity = {5, 0, 0};
    for (int i = 0; i < 300 && s.events.empty(); ++i) s.run(1);
    REQUIRE_FALSE(s.events.empty());
    const CollisionEvent& ev = s.events.front();
    REQUIRE(ev.phase == CollisionEvent::Phase::Begin);
    CHECK(ev.a == box);
    CHECK(pos_of(s.world, ball).x == doctest::Approx(-0.75f).epsilon(0.15));
    CHECK(pos_of(s.world, ball).x > -3.0f);  // it travelled through the corner region of the AABB
    const float inv = 1.0f / std::sqrt(2.0f);
    CHECK(dot(ev.normal, Vec3{-inv, 0, inv}) > 0.99f);  // the rotated face's normal, from the box to the ball

    // A sphere resting in that corner region touches nothing; one next to the rotated face does.
    Sim t;
    no_gravity(t);
    Entity b2 = add_turned_box3(t.world, "box", {0, 0, 0}, {4, 2, 4}, {0, 45, 0}, BodyType::Static, false);
    Entity far = add_sphere3(t.world, "far", {-2.5f, 0, 2.5f}, 0.3f);
    t.run(30);
    CHECK(t.events.empty());
    CHECK(pos_of(t.world, far) == Vec3{-2.5f, 0, 2.5f});
    auto has = [](const std::vector<Entity>& v, Entity e) { return std::find(v.begin(), v.end(), e) != v.end(); };
    CHECK_FALSE(has(t.physics.overlap_sphere3d(t.world, {-2.0f, 0, 2.0f}, 0.3f), b2));  // inside the AABB, off the box
    CHECK(has(t.physics.overlap_sphere3d(t.world, {-1.5f, 0, 1.5f}, 0.3f), b2));
    CHECK_FALSE(t.physics.is_touching3d(t.world, far, {1, 0, -1}));
}

TEST_CASE("3d: a sphere hitting a rotated face bounces along the face normal") {
    Sim s;
    no_gravity(s);
    Entity box = add_turned_box3(s.world, "box", {0, 0, 0}, {4, 2, 4}, {0, 45, 0}, BodyType::Static, false);
    s.world.get<Collider3D>(box)->restitution = 1.0f;
    // 3 m out from the middle of the face -x + z = 2.83, flying straight at it
    const float inv = 1.0f / std::sqrt(2.0f);
    Entity ball = add_sphere3(s.world, "ball", {-1.414f - 3.0f * inv, 0, 1.414f + 3.0f * inv}, 0.3f);
    s.world.get<RigidBody3D>(ball)->velocity = {5.0f * inv, 0, -5.0f * inv};
    s.run(90);
    Vec3 v = s.world.get<RigidBody3D>(ball)->velocity;
    CHECK(v.x == doctest::Approx(-5.0f * inv).epsilon(0.05));
    CHECK(v.z == doctest::Approx(5.0f * inv).epsilon(0.05));
    CHECK(std::fabs(v.y) < 0.01f);
}

TEST_CASE("3d: raycast against a rotated box hits the rotated face with its normal") {
    Sim s;
    add_turned_box3(s.world, "box", {0, 0, 0}, {4, 2, 4}, {0, 45, 0}, BodyType::Static, false);
    s.physics.sync(s.world);
    const float inv = 1.0f / std::sqrt(2.0f);
    // along +x at z = 1.414 the face -x + z = 2.83 is met at x = -1.414 (the AABB would say -2.83)
    auto hit = s.physics.raycast3d(s.world, {-8, 0, 1.414f}, {1, 0, 0}, 100.0f);
    REQUIRE(hit.has_value());
    CHECK(hit->distance == doctest::Approx(8.0f - 1.414f).epsilon(0.002));
    CHECK(hit->point.x == doctest::Approx(-1.414f).epsilon(0.005));
    CHECK(dot(hit->normal, Vec3{-inv, 0, inv}) > 0.999f);
    // a ray at z = 2.7 slips past the AABB-wide corner and reaches the diamond near its vertex only at x = -0.13
    hit = s.physics.raycast3d(s.world, {-8, 0, 2.7f}, {1, 0, 0}, 100.0f);
    REQUIRE(hit.has_value());
    CHECK(std::fabs((hit->point.x) - (-0.128f)) < 0.01);
    // the top face is still the top face
    hit = s.physics.raycast3d(s.world, {0.5f, 10, 0.5f}, {0, -1, 0}, 100.0f);
    REQUIRE(hit.has_value());
    CHECK(hit->distance == doctest::Approx(9.0f).epsilon(0.001));
    CHECK(hit->normal.y == doctest::Approx(1.0f));
    // a ray from inside the box does not hit it, and a miss is a miss
    CHECK_FALSE(s.physics.raycast3d(s.world, {0, 0, 0}, {1, 0, 0}, 100.0f).has_value());
    CHECK_FALSE(s.physics.raycast3d(s.world, {-8, 0, 3.2f}, {1, 0, 0}, 100.0f).has_value());
}

TEST_CASE("3d: oriented box vs box: resting on a rotated slab, pushed out along a shared face, stopped by a rotated wall") {
    // (a) a cube lands on a slab turned 45 degrees about Y and rests on its top face
    Sim a;
    add_turned_box3(a.world, "slab", {0, -0.5f, 0}, {10, 1, 10}, {0, 45, 0}, BodyType::Static, false);
    Entity cube = add_box3(a.world, "cube", {0, 3, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    a.run(240);
    CHECK(pos_of(a.world, cube).y == doctest::Approx(0.5f).epsilon(0.03));
    CHECK(a.physics.is_grounded(a.world, cube));

    // (b) a cube turned like a wall, overlapping it by 0.1 m, is pushed out along the wall's normal
    const float inv = 1.0f / std::sqrt(2.0f);
    const Vec3 n{inv, 0, -inv}, tangent{inv, 0, inv};  // the wall's local x axis for a 45 degree yaw
    Sim b;
    no_gravity(b);
    add_turned_box3(b.world, "wall", {0, 0, 0}, {0.4f, 4, 6}, {0, 45, 0}, BodyType::Static, false);
    Entity pushed = add_turned_box3(b.world, "cube", n * 0.6f, {1, 1, 1}, {0, 45, 0}, BodyType::Dynamic, true);
    b.run(20);
    Vec3 p = pos_of(b.world, pushed);
    CHECK(std::fabs((dot(p, n)) - (0.7f)) < 0.012);
    CHECK(std::fabs(dot(p, tangent)) < 0.005f);
    CHECK(std::fabs(p.y) < 0.005f);

    // (c) an unturned cube flying at the wall along its normal stops with a corner against the face
    Sim c;
    no_gravity(c);
    add_turned_box3(c.world, "wall", {0, 0, 0}, {0.4f, 4, 6}, {0, 45, 0}, BodyType::Static, false);
    Entity flyer = add_box3(c.world, "cube", n * 4.0f, {1, 1, 1}, BodyType::Dynamic, true);
    c.world.get<RigidBody3D>(flyer)->velocity = n * -3.0f;
    c.run(120);
    p = pos_of(c.world, flyer);
    CHECK(std::fabs((dot(p, n)) - (0.2f + 0.7071f)) < 0.02);  // wall half thickness + cube half diagonal
    CHECK(std::fabs(dot(p, tangent)) < 0.02f);
    CHECK(length(c.world.get<RigidBody3D>(flyer)->velocity) < 0.05f);
    REQUIRE_FALSE(c.events.empty());
    CHECK(std::fabs(dot(c.events.front().point, n)) < 0.25f);  // the contact point is on the wall
    CHECK(dot(c.events.front().normal, n) > 0.99f);
}

TEST_CASE("3d: the collider offset turns with the entity; a dynamic body with an offset is not displaced") {
    // a box 2 m to the +x side of an entity yawed 90 degrees sits 2 m toward -z (R = Ry: x -> -z)
    Sim s;
    Entity e = add_turned_box3(s.world, "arm", {0, 0, 0}, {1, 1, 1}, {0, 90, 0}, BodyType::Static, false);
    s.world.get<Collider3D>(e)->offset = {2, 0, 0};
    s.physics.sync(s.world);
    auto hit = s.physics.raycast3d(s.world, {0, 0, -10}, {0, 0, 1}, 100.0f);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == e);
    CHECK(hit->distance == doctest::Approx(7.5f).epsilon(0.002));
    hit = s.physics.raycast3d(s.world, {0, 0, 10}, {0, 0, -1}, 100.0f);  // from the other side: the far face, z = -1.5
    REQUIRE(hit.has_value());
    CHECK(hit->distance == doctest::Approx(11.5f).epsilon(0.002));
    CHECK_FALSE(s.physics.raycast3d(s.world, {10, 0, 0}, {-1, 0, 0}, 100.0f).has_value());  // nothing at +x (unrotated offset)

    // a dynamic sphere whose collider is offset keeps its entity where gameplay put it and lands on the ground
    Sim d;
    add_box3(d.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity ball = add_sphere3(d.world, "ball", {0, 2, 0}, 0.5f);
    d.world.get<Collider3D>(ball)->offset = {0, 0, 1};
    d.run(1);
    CHECK(std::fabs((pos_of(d.world, ball).x) - (0.0f)) < 0.001);
    CHECK(std::fabs((pos_of(d.world, ball).z) - (0.0f)) < 0.001);
    d.run(239);
    CHECK(pos_of(d.world, ball).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(std::fabs((pos_of(d.world, ball).z) - (0.0f)) < 0.001);
}

TEST_CASE("3d: debug_shapes and debug_state report the box rotation") {
    Sim s;
    add_box3(s.world, "flat", {0, 0, 0}, {1, 2, 3}, BodyType::Static, false);
    add_turned_box3(s.world, "tilted", {5, 0, 0}, {1, 2, 3}, {20, 30, 40}, BodyType::Static, false);
    add_static_sphere3(s.world, "orb", {9, 0, 0}, 1.0f);
    s.physics.sync(s.world);
    auto shapes = s.physics.debug_shapes(s.world);
    REQUIRE(shapes.size() == 3);
    CHECK(shapes[0].euler == Vec3{});
    CHECK(shapes[0].rotation == 0.0f);
    CHECK(deg_apart(shapes[1].size, {1, 2, 3}) < 1e-5f);  // local, unrotated extents (not the AABB of the turned box)
    CHECK(deg_apart(shapes[1].euler, {20, 30, 40}) < 0.05f);
    CHECK(shapes[1].rotation == doctest::Approx(40.0f).epsilon(0.002));
    CHECK(shapes[2].kind == Physics::DebugShape::Sphere);
    CHECK(shapes[2].euler == Vec3{});
    Json state = s.physics.debug_state(s.world);
    REQUIRE(state.size() == 3);
    CHECK(state[0]["shapes"][0]["rotation"][1].get<float>() == 0.0f);
    CHECK(state[1]["shapes"][0]["rotation"][0].get<float>() == doctest::Approx(20.0f).epsilon(0.002));
    CHECK(state[1]["shapes"][0]["rotation"][1].get<float>() == doctest::Approx(30.0f).epsilon(0.002));
    CHECK(state[1]["shapes"][0]["rotation"][2].get<float>() == doctest::Approx(40.0f).epsilon(0.002));
    // a child of a turned parent uses the world rotation: parent 30 degrees + child 15 degrees about Y
    Entity parent = s.world.create("parent", "parent");
    s.world.get<Transform>(parent)->rotation = {0, 30, 0};
    Entity kid = add_turned_box3(s.world, "kid", {0, 0, 0}, {1, 1, 1}, {0, 15, 0}, BodyType::Static, false);
    s.world.set_parent(kid, parent, false);
    s.physics.sync(s.world);
    shapes = s.physics.debug_shapes(s.world);
    REQUIRE(shapes.size() == 4);
    CHECK(shapes[3].euler.y == doctest::Approx(45.0f).epsilon(0.002));
}

TEST_CASE("3d: a spinning kinematic box turns its collider with the entity") {
    Sim s;
    no_gravity(s);
    Entity bar = add_box3(s.world, "bar", {0, 0, 0}, {4, 1, 1}, BodyType::Kinematic, true);
    s.world.get<RigidBody3D>(bar)->angularVelocity = {0, 90, 0};
    s.run(30);
    s.physics.sync(s.world);
    auto shapes = s.physics.debug_shapes(s.world);
    REQUIRE(shapes.size() == 1);
    CHECK(shapes[0].euler.y == doctest::Approx(45.0f).epsilon(0.01));
    // after a quarter turn the 4 m bar lies along z: a ray along x at z = 1.5 hits it; along z at x = 1.5 it misses
    s.run(30);
    s.physics.sync(s.world);
    CHECK(s.physics.raycast3d(s.world, {-5, 0, 1.5f}, {1, 0, 0}, 20.0f).has_value());
    CHECK_FALSE(s.physics.raycast3d(s.world, {1.5f, 0, -5}, {0, 0, 1}, 20.0f).has_value());
}

TEST_CASE("3d: continuous collision: a 60 m/s sphere never passes a 0.2 m wall in 900 trials") {
    // Deterministic trials: golden-ratio sequences vary the start (also against the sub-step grid), the aim and the
    // wall's orientation. Zero gravity and restitution 0, so the sphere ends up pressed against / sliding along the wall.
    int trials = 0, missed_wall = 0;
    for (int variant = 0; variant < 3; ++variant) {
        for (float radius : {0.1f, 0.25f}) {
            for (int i = 0; i < 150; ++i) {
                // variant 0: wall facing +x; 1 and 2: wall turned (yaw 35 and -50 plus 10 degrees of pitch)
                const Vec3 wallRot = variant == 0 ? Vec3{} : (variant == 1 ? Vec3{10, 35, 0} : Vec3{10, -50, 0});
                Sim s;
                no_gravity(s);
                add_turned_box3(s.world, "wall", {0, 0, 0}, {0.2f, 80, 80}, wallRot, BodyType::Static, false);
                // Everything below is built in the wall's own frame (x = its normal) and turned into the world.
                const Mat4 toWorld = Mat4::rotate_euler_deg(wallRot);
                const Vec3 normal = toWorld.transform_dir({1, 0, 0});
                const float yaw = (frac(i, 0.754877f) - 0.5f) * 80.0f;    // +-40 degrees off the normal
                const float pitch = (frac(i, 0.569840f) - 0.5f) * 40.0f;  // +-20 degrees
                const Vec3 dir = toWorld.transform_dir({std::cos(radians(yaw)) * std::cos(radians(pitch)),
                                                        std::sin(radians(pitch)),
                                                        std::sin(radians(yaw)) * std::cos(radians(pitch))});
                // start 5..5.25 m in front of the wall plane (a different phase against the 0.25 m sub-step each time)
                const Vec3 start = toWorld.transform_dir({-(5.0f + 0.25f * frac(i, 0.618034f)),
                                                          3.0f * (frac(i, 0.324717f) - 0.5f),
                                                          3.0f * (frac(i, 0.465571f) - 0.5f)});
                Entity ball = add_sphere3(s.world, "ball", start, radius);
                s.world.get<RigidBody3D>(ball)->velocity = dir * 60.0f;
                float front = -1e9f;  // how far the sphere's leading surface got along the wall normal
                for (int f = 0; f < 20; ++f) {
                    s.run(1);
                    front = std::max(front, dot(pos_of(s.world, ball), normal) + radius);
                }
                ++trials;
                if (s.count(CollisionEvent::Phase::Begin, false) == 0) ++missed_wall;
                // the contact solver resolved the hit: nothing still drives the sphere into the wall
                if (dot(s.world.get<RigidBody3D>(ball)->velocity, normal) > 1.0f) {
                    FAIL("still moving into the wall: variant " << variant << " radius " << radius << " trial " << i);
                }
                // the wall's front face is at -0.1; a sphere that got through would have its surface beyond +0.1
                if (front > -0.1f + 0.02f) {
                    FAIL("tunnelled: variant " << variant << " radius " << radius << " trial " << i << " front " << front);
                }
            }
        }
    }
    CHECK(trials == 900);
    CHECK(missed_wall == 0);  // every shot actually hit the wall
}

TEST_CASE("3d: continuous collision also stops a fast thin dynamic box, and leaves slow bodies alone") {
    for (int i = 0; i < 60; ++i) {
        Sim s;
        no_gravity(s);
        add_box3(s.world, "wall", {0, 0, 0}, {0.1f, 40, 40}, BodyType::Static, false);
        Entity cube = add_turned_box3(s.world, "cube", {-4.0f - 0.33f * frac(i, 0.618034f), 3.0f * frac(i, 0.41f) - 1.5f, 0},
                                      {0.2f, 0.2f, 0.2f}, {0, float(i % 5) * 17.0f, 0}, BodyType::Dynamic, true);
        s.world.get<RigidBody3D>(cube)->velocity = {80, 0, 0};
        float maxX = -1e9f;
        for (int f = 0; f < 12; ++f) {
            s.run(1);
            maxX = std::max(maxX, pos_of(s.world, cube).x);
        }
        // the cube may be wider than 0.2 m along x when turned (up to 0.28 m): its centre stays on the near side
        CHECK(maxX < 0.0f);
    }
    // a bouncy bullet comes back: the swept hit is resolved by the contact solver, restitution included
    Sim u;
    no_gravity(u);
    Entity wall = add_box3(u.world, "wall", {0, 0, 0}, {0.2f, 40, 40}, BodyType::Static, false);
    u.world.get<Collider3D>(wall)->restitution = 0.8f;
    Entity bullet = add_sphere3(u.world, "bullet", {-5, 0, 0}, 0.1f);
    u.world.get<RigidBody3D>(bullet)->velocity = {60, 0, 0};
    u.run(30);
    CHECK(u.world.get<RigidBody3D>(bullet)->velocity.x == doctest::Approx(-48.0f).epsilon(0.02));
    CHECK(pos_of(u.world, bullet).x < -0.2f);
    // a slow ball (well under half its radius per sub-step) is not swept: it lands and rests as before
    Sim t;
    add_box3(t.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity ball = add_sphere3(t.world, "ball", {0, 5, 0}, 0.5f);
    t.run(240);
    CHECK(pos_of(t.world, ball).y == doctest::Approx(0.5f).epsilon(0.02));
}

TEST_CASE("3d: a rolling sphere keeps rolling (rolling resistance); a sliding one stops within a second") {
    // Both balls are launched at 3 m/s on friction-0.5 ground with friction-0.5 colliders.
    auto launch = [](bool rolling, float* seconds) {
        Sim s;
        Entity ground = add_box3(s.world, "ground", {0, -0.5f, 0}, {400, 1, 400}, BodyType::Static, false);
        s.world.get<Collider3D>(ground)->friction = 0.5f;
        Entity ball = add_sphere3(s.world, "ball", {0, 0.5f, 0}, 0.5f);
        s.world.get<Collider3D>(ball)->friction = 0.5f;
        s.world.get<RigidBody3D>(ball)->rollWithMotion = rolling;
        s.world.get<RigidBody3D>(ball)->lockRotation = !rolling;  // the sliding ball: contacts do not spin it
        s.run(30);
        const float x0 = pos_of(s.world, ball).x;
        s.world.get<RigidBody3D>(ball)->velocity = {3, 0, 0};
        int frames = 0;
        while (frames < 1500 && std::fabs(s.world.get<RigidBody3D>(ball)->velocity.x) > 0.01f) {
            s.run(1);
            ++frames;
        }
        *seconds = float(frames) * kDt;
        return pos_of(s.world, ball).x - x0;
    };
    const float g = 9.81f;
    float tRoll = 0, tSlide = 0;
    const float rolled = launch(true, &tRoll);
    const float slid = launch(false, &tSlide);
    // decay = rollingFriction (0.02 default) * g => distance v^2 / (2 mu g) = 22.9 m, time v / (mu g) = 15.3 s
    CHECK(rolled == doctest::Approx(9.0f / (2.0f * 0.02f * g)).epsilon(0.05));
    CHECK(tRoll == doctest::Approx(3.0f / (0.02f * g)).epsilon(0.05));
    CHECK(tSlide < 1.0f);
    CHECK(slid == doctest::Approx(9.0f / (2.0f * 0.5f * g)).epsilon(0.1));

    // rollingFriction is the knob: 0 never slows the ball (no other drag), 0.1 stops it in 3 m / (0.1 g) = 3.1 s
    Sim s;
    Entity ground = add_box3(s.world, "ground", {0, -0.5f, 0}, {400, 1, 400}, BodyType::Static, false);
    s.world.get<Collider3D>(ground)->friction = 0.5f;
    Entity free = add_sphere3(s.world, "free", {0, 0.5f, 0}, 0.5f);
    Entity heavy = add_sphere3(s.world, "heavy", {0, 0.5f, 5}, 0.5f);
    s.world.get<RigidBody3D>(free)->rollingFriction = 0.0f;
    s.world.get<RigidBody3D>(heavy)->rollingFriction = 0.1f;
    s.run(30);
    s.world.get<RigidBody3D>(free)->velocity = {3, 0, 0};
    s.world.get<RigidBody3D>(heavy)->velocity = {3, 0, 0};
    s.run(240);  // 4 s
    CHECK(s.world.get<RigidBody3D>(free)->velocity.x == doctest::Approx(3.0f).epsilon(0.002));
    CHECK(std::fabs(s.world.get<RigidBody3D>(heavy)->velocity.x) < 1e-3f);
}

TEST_CASE("3d: shape_cast3d sweeps spheres and boxes against boxes, a rotated box and a sphere") {
    Sim s;
    Entity wall = add_box3(s.world, "wall", {5, 0, 0}, {1, 4, 4}, BodyType::Static, false);            // near face x = 4.5
    Entity behind = add_box3(s.world, "behind", {8, 0, 0}, {1, 4, 4}, BodyType::Static, false);        // near face x = 7.5
    Entity diamond = add_turned_box3(s.world, "diamond", {5, 0, 10}, {2, 2, 2}, {0, 45, 0}, BodyType::Static, false);
    Entity orb = add_static_sphere3(s.world, "orb", {5, 0, -10}, 1.0f);
    s.physics.sync(s.world);
    CastShape sphere;  // radius 0.5
    CastShape cube;
    cube.kind = CastShape::Kind::Box;
    cube.size = {1, 1, 1};

    auto cast = [&](const CastShape& shape, Vec3 from, Vec3 to, const RaycastOptions& o = {}) {
        return s.physics.shape_cast3d(s.world, shape, from, to, o);
    };
    // a sphere and a box against a box: the centre travels until the surface touches (4.5 - 0.5)
    auto hit = cast(sphere, {0, 0, 0}, {10, 0, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(std::fabs((hit->distance) - (4.0f)) < 0.002);
    CHECK(std::fabs((hit->normal.x) - (-1.0f)) < 0.001);
    CHECK(std::fabs((hit->point.x) - (4.5f)) < 0.01);
    hit = cast(cube, {0, 0, 0}, {10, 0, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    CHECK(std::fabs((hit->distance) - (4.0f)) < 0.002);
    CHECK(std::fabs((hit->normal.x) - (-1.0f)) < 0.001);
    // the distance is along the whole path even for a diagonal cast
    hit = cast(sphere, {0, 0, 0}, {12, 0, 0});
    REQUIRE(hit.has_value());
    CHECK(std::fabs((hit->distance) - (4.0f)) < 0.002);
    // a rotated box: its vertex points at -x at 5 - 1.414 = 3.586
    hit = cast(sphere, {0, 0, 10}, {10, 0, 10});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == diamond);
    CHECK(std::fabs((hit->distance) - (3.586f - 0.5f)) < 0.003);
    CHECK(std::fabs((hit->normal.x) - (-1.0f)) < 0.01);
    hit = cast(cube, {0, 0, 10}, {10, 0, 10});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == diamond);
    CHECK(std::fabs((hit->distance) - (3.586f - 0.5f)) < 0.003);
    CHECK(std::fabs((hit->normal.x) - (-1.0f)) < 0.01);
    // aimed head-on at a face of the diamond instead (relative to its centre: the face -x + z = 1.414)
    hit = cast(sphere, {5 - 4.0f, 0, 10 + 4.0f}, {5 - 1.0f, 0, 10 + 1.0f});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == diamond);
    CHECK(dot(hit->normal, normalize(Vec3{-1, 0, 1})) > 0.99f);
    CHECK(std::fabs((hit->distance) - (4.657f - 0.5f)) < 0.01);  // the start is 4.657 m from the face -x + z = 1.414
    // a sphere
    hit = cast(sphere, {0, 0, -10}, {10, 0, -10});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == orb);
    CHECK(std::fabs((hit->distance) - (3.5f)) < 0.002);
    CHECK(std::fabs((hit->normal.x) - (-1.0f)) < 0.01);
    hit = cast(cube, {0, 0, -10}, {10, 0, -10});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == orb);
    CHECK(std::fabs((hit->distance) - (3.5f)) < 0.002);
    CHECK(std::fabs((hit->normal.x) - (-1.0f)) < 0.01);
    // short of the target, off to the side, or not moving: no hit
    CHECK_FALSE(cast(sphere, {0, 0, 0}, {3.4f, 0, 0}).has_value());
    CHECK_FALSE(cast(sphere, {0, 0, 4}, {10, 0, 4}).has_value());
    CHECK_FALSE(cast(sphere, {0, 0, 0}, {0, 0, 0}).has_value());
    CHECK_FALSE(cast(sphere, {0, 0, 0}, {-10, 0, 0}).has_value());

    // a collider the shape already overlaps at `from` is skipped, the next one behind it is hit
    hit = cast(sphere, {5, 0, 0}, {12, 0, 0});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == behind);
    CHECK(std::fabs((hit->distance) - (2.0f)) < 0.002);

    // mask
    s.world.get<Collider3D>(wall)->layer = 3;
    s.physics.sync(s.world);
    RaycastOptions o;
    o.mask = 1 << 0;
    hit = cast(sphere, {0, 0, 0}, {10, 0, 0}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == behind);  // the wall (layer 3) is masked out
    o.mask = 1 << 3;
    hit = cast(sphere, {0, 0, 0}, {10, 0, 0}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == wall);
    o.mask = 1 << 5;
    CHECK_FALSE(cast(sphere, {0, 0, 0}, {10, 0, 0}, o).has_value());

    // ignore skips the entity and its descendants
    Entity holder = s.world.create("holder", "holder");
    s.world.get<Transform>(holder)->position = {0, 0, 20};
    Entity kid = add_box3(s.world, "kid", {5, 0, 20}, {1, 4, 4}, BodyType::Static, false);
    s.world.set_parent(kid, holder, true);
    s.physics.sync(s.world);
    hit = cast(sphere, {0, 0, 20}, {10, 0, 20});
    REQUIRE(hit.has_value());
    CHECK(hit->entity == kid);
    o = {};
    o.ignore = holder;
    CHECK_FALSE(cast(sphere, {0, 0, 20}, {10, 0, 20}, o).has_value());
    o.ignore = wall;
    hit = cast(sphere, {0, 0, 0}, {10, 0, 0}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == behind);

    // triggers are skipped unless ignoreTriggers = false
    Entity zone = add_box3(s.world, "zone", {5, 0, 30}, {1, 4, 4}, BodyType::Static, false);
    s.world.get<Collider3D>(zone)->isTrigger = true;
    s.physics.sync(s.world);
    CHECK_FALSE(cast(sphere, {0, 0, 30}, {10, 0, 30}).has_value());
    o = {};
    o.ignoreTriggers = false;
    hit = cast(sphere, {0, 0, 30}, {10, 0, 30}, o);
    REQUIRE(hit.has_value());
    CHECK(hit->entity == zone);
    CHECK(std::fabs((hit->distance) - (4.0f)) < 0.002);
}

TEST_CASE("3d: determinism with rotated boxes and fast bodies") {
    auto run = [] {
        Sim s;
        add_turned_box3(s.world, "slab", {0, -0.5f, 0}, {20, 1, 20}, {0, 25, 8}, BodyType::Static, false);
        add_turned_box3(s.world, "wall", {6, 2, 0}, {0.2f, 6, 10}, {0, 20, 0}, BodyType::Static, false);
        std::vector<Entity> bodies;
        for (int i = 0; i < 4; ++i) {
            bodies.push_back(add_turned_box3(s.world, ("c" + std::to_string(i)).c_str(), {float(i) * 0.7f, 1.0f + 1.5f * float(i), 0},
                                             {1, 1, 1}, {10.0f * float(i), 15.0f * float(i), 5.0f * float(i)}, BodyType::Dynamic, true));
            s.world.get<RigidBody3D>(bodies.back())->angularVelocity = {0, 30.0f * float(i), 0};
        }
        for (int i = 0; i < 3; ++i) {
            bodies.push_back(add_sphere3(s.world, ("s" + std::to_string(i)).c_str(), {-4, 1.0f + 0.4f * float(i), float(i)}, 0.2f));
            s.world.get<RigidBody3D>(bodies.back())->velocity = {60, 3, 0};
        }
        s.run(200);
        std::vector<float> out;
        for (Entity e : bodies) {
            Vec3 p = pos_of(s.world, e);
            out.insert(out.end(), {p.x, p.y, p.z});
        }
        return out;
    };
    auto a = run(), b = run();
    REQUIRE(a.size() == b.size());
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
}

TEST_CASE("3d: shape_cast3d from a body resting on the ground hits the ground going down, not up or sideways") {
    Sim s;
    Entity ground = add_box3(s.world, "ground", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity ball = add_sphere3(s.world, "ball", {0, 0.5f, 0}, 0.5f);
    s.run(60);  // settles ~1 mm into the ground
    const Vec3 c = s.world.world_position(ball);
    REQUIRE(c.y < 0.5f);
    CastShape sphere;  // radius 0.5, the ball's own shape
    RaycastOptions o;
    o.ignore = ball;
    auto down = s.physics.shape_cast3d(s.world, sphere, c, c - Vec3{0, 2, 0}, o);
    REQUIRE(down.has_value());
    CHECK(down->entity == ground);
    CHECK(down->distance < 0.001f);
    CHECK(down->normal.y > 0.99f);
    CHECK_FALSE(s.physics.shape_cast3d(s.world, sphere, c, c + Vec3{0, 2, 0}, o).has_value());
    CHECK_FALSE(s.physics.shape_cast3d(s.world, sphere, c, c + Vec3{3, 0, 0}, o).has_value());
}

// ------------------------------- 3D rotation dynamics and continuous collision (M7 package A) ----

namespace {
// The three world-space axes of an entity's box (Transform.rotation, no parent).
void box_axes(World& w, Entity e, Vec3* ax) {
    const Mat4 m = Mat4::rotate_euler_deg(w.get<Transform>(e)->rotation);
    ax[0] = m.transform_dir({1, 0, 0});
    ax[1] = m.transform_dir({0, 1, 0});
    ax[2] = m.transform_dir({0, 0, 1});
}
// Degrees between the box's local +y axis and world up.
float tilt_y(World& w, Entity e) {
    Vec3 ax[3];
    box_axes(w, e, ax);
    return degrees(std::acos(clamp(ax[1].y, -1.0f, 1.0f)));
}
// Degrees the box is away from resting on one of its faces (0 = a face points straight down).
float off_flat(World& w, Entity e) {
    Vec3 ax[3];
    box_axes(w, e, ax);
    const float best = std::max({std::fabs(ax[0].y), std::fabs(ax[1].y), std::fabs(ax[2].y)});
    return degrees(std::acos(clamp(best, 0.0f, 1.0f)));
}
float spin_of(World& w, Entity e) { return length(w.get<RigidBody3D>(e)->angularVelocity); }
}  // namespace

TEST_CASE("3d rotation: a box with its centre past a ledge edge tips over and falls off") {
    Sim s;
    add_box3(s.world, "ledge", {-2.0f, -0.5f, 0}, {4, 1, 4}, BodyType::Static, false);  // x in [-4, 0], top at y = 0
    Entity box = add_box3(s.world, "box", {0.1f, 0.5f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    float maxTilt = 0.0f;
    int fellAt = -1;
    for (int f = 0; f < 180; ++f) {  // 3 s
        s.run(1);
        maxTilt = std::max(maxTilt, tilt_y(s.world, box));
        if (fellAt < 0 && pos_of(s.world, box).y < -0.5f) fellAt = f;
    }
    MESSAGE("max tilt " << maxTilt << " deg, below the ledge at frame " << fellAt << ", y " << pos_of(s.world, box).y);
    CHECK(maxTilt > 45.0f);
    CHECK(fellAt >= 0);
    CHECK(pos_of(s.world, box).y < 0.0f);
    CHECK(pos_of(s.world, box).x > 0.0f);  // it went over the edge
    // the same box with its centre over the ledge (0.1 m inside the edge) stays put
    Sim t;
    add_box3(t.world, "ledge", {-2.0f, -0.5f, 0}, {4, 1, 4}, BodyType::Static, false);
    Entity safe = add_box3(t.world, "box", {-0.1f, 0.5f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    t.run(180);
    CHECK(pos_of(t.world, safe).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(tilt_y(t.world, safe) < 3.0f);
}

TEST_CASE("3d rotation: a box dropped at a 20 degree tilt settles face down, comes to rest and stays still") {
    Sim s;
    add_box3(s.world, "floor", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity box = add_turned_box3(s.world, "box", {0, 1.5f, 0}, {1, 1, 1}, {0, 0, 20}, BodyType::Dynamic, true);
    float firstRest = -1.0f;
    s.run(60);
    for (int f = 60; f < 240; ++f) {  // up to 4 s
        s.run(1);
        if (firstRest < 0.0f && f > 70 && spin_of(s.world, box) < 1.0f && length(s.world.get<RigidBody3D>(box)->velocity) < 0.05f)
            firstRest = float(f) * kDt;
    }
    MESSAGE("first at rest after " << firstRest << " s, off flat " << off_flat(s.world, box) << " deg, spin "
            << spin_of(s.world, box) << " deg/s, y " << pos_of(s.world, box).y);
    CHECK(off_flat(s.world, box) < 2.0f);
    CHECK(pos_of(s.world, box).y == doctest::Approx(0.5f).epsilon(0.02));
    CHECK(spin_of(s.world, box) < 1.0f);
    CHECK(firstRest > 0.0f);
    // no jitter afterwards: one more second moves nothing
    const Vec3 p0 = pos_of(s.world, box), r0 = s.world.get<Transform>(box)->rotation;
    float maxMove = 0.0f, maxTurn = 0.0f, maxSpin = 0.0f;
    for (int f = 0; f < 60; ++f) {
        s.run(1);
        maxMove = std::max(maxMove, length(pos_of(s.world, box) - p0));
        maxTurn = std::max(maxTurn, deg_apart(s.world.get<Transform>(box)->rotation, r0));
        maxSpin = std::max(maxSpin, spin_of(s.world, box));
    }
    MESSAGE("jitter: moved " << maxMove << " m, turned " << maxTurn << " deg, spin " << maxSpin);
    CHECK(maxMove < 0.002f);
    CHECK(maxTurn < 0.1f);
    CHECK(maxSpin < 1.0f);
}

TEST_CASE("3d rotation: a stack of three boxes stays standing for 10 seconds") {
    Sim s;
    add_box3(s.world, "floor", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    std::vector<Entity> boxes;
    for (int i = 0; i < 3; ++i)
        boxes.push_back(add_box3(s.world, ("b" + std::to_string(i)).c_str(), {0.03f * float(i), 0.5f + float(i), 0},
                                 {1, 1, 1}, BodyType::Dynamic, true));
    float worstTilt = 0.0f, worstDrift = 0.0f;
    for (int f = 0; f < 600; ++f) {
        s.run(1);
        for (int i = 0; i < 3; ++i) {
            worstTilt = std::max(worstTilt, tilt_y(s.world, boxes[i]));
            worstDrift = std::max(worstDrift, std::fabs(pos_of(s.world, boxes[i]).x - 0.03f * float(i)));
        }
    }
    MESSAGE("stack: worst tilt " << worstTilt << " deg, worst x drift " << worstDrift);
    for (int i = 0; i < 3; ++i) {
        CHECK(pos_of(s.world, boxes[i]).y == doctest::Approx(0.5f + float(i)).epsilon(0.02));
        CHECK(spin_of(s.world, boxes[i]) < 1.0f);
    }
    CHECK(worstTilt < 3.0f);
    CHECK(worstDrift < 0.1f);
}

TEST_CASE("3d rotation: a tall stack of centred boxes stays up") {
    Sim s;
    add_box3(s.world, "floor", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    std::vector<Entity> boxes;
    for (int i = 0; i < 6; ++i)
        boxes.push_back(add_box3(s.world, ("b" + std::to_string(i)).c_str(), {0, 0.5f + 1.02f * float(i), 0}, {1, 1, 1},
                                 BodyType::Dynamic, true));
    s.run(360);
    for (int i = 0; i < 6; ++i) {
        CHECK(std::fabs(pos_of(s.world, boxes[i]).x) < 0.02f);
        CHECK(std::fabs(pos_of(s.world, boxes[i]).z) < 0.02f);
        CHECK(tilt_y(s.world, boxes[i]) < 1.0f);
    }
    CHECK(pos_of(s.world, boxes[5]).y == doctest::Approx(0.5f + 5.0f).epsilon(0.02));
}

TEST_CASE("3d rotation: a sphere hitting a resting box off-centre spins it; with lockRotation it does not") {
    float spun[2] = {0, 0};
    for (int lock = 0; lock < 2; ++lock) {
        Sim s;
        add_box3(s.world, "floor", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
        Entity box = add_box3(s.world, "box", {0, 0.5f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
        s.world.get<RigidBody3D>(box)->lockRotation = lock == 1;
        Entity ball = add_sphere3(s.world, "ball", {-6, 0.9f, 0}, 0.1f);  // aims 0.4 m above the box's centre
        s.world.get<RigidBody3D>(ball)->gravityScale = 0.0f;
        s.world.get<RigidBody3D>(ball)->mass = 2.0f;
        s.world.get<RigidBody3D>(ball)->velocity = {8, 0, 0};
        for (int f = 0; f < 150; ++f) {
            s.run(1);
            spun[lock] = std::max(spun[lock], spin_of(s.world, box));
        }
        CHECK(s.count(CollisionEvent::Phase::Begin, false) >= 2);  // the box landed (floor) and the ball hit it
        CHECK(pos_of(s.world, box).x > 0.5f);                     // pushed by the hit either way
    }
    MESSAGE("max spin of the box: free " << spun[0] << " deg/s, locked " << spun[1] << " deg/s");
    CHECK(spun[0] > 200.0f);
    CHECK(spun[1] == 0.0f);
}

TEST_CASE("3d rotation: lockRotation keeps a box upright over a ledge, angularDamping slows a spin") {
    Sim s;
    add_box3(s.world, "ledge", {-2.0f, -0.5f, 0}, {4, 1, 4}, BodyType::Static, false);
    Entity box = add_box3(s.world, "box", {0.1f, 0.5f, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    s.world.get<RigidBody3D>(box)->lockRotation = true;
    s.run(180);
    CHECK(s.world.get<Transform>(box)->rotation == Vec3{});  // no torque from the ledge edge: still unturned
    CHECK(pos_of(s.world, box).y == doctest::Approx(0.5f).epsilon(0.02));
    // gameplay-written angularVelocity still turns a locked box
    s.world.get<RigidBody3D>(box)->gravityScale = 0.0f;
    s.world.get<RigidBody3D>(box)->angularVelocity = {0, 90, 0};
    s.run(30);
    CHECK(s.world.get<Transform>(box)->rotation.y == doctest::Approx(45.0f).epsilon(0.02));

    Sim t;
    Entity spinner = add_box3(t.world, "spinner", {0, 10, 0}, {1, 2, 3}, BodyType::Dynamic, true);
    t.world.get<RigidBody3D>(spinner)->gravityScale = 0.0f;
    t.world.get<RigidBody3D>(spinner)->angularVelocity = {0, 100, 0};
    t.world.get<RigidBody3D>(spinner)->angularDamping = 2.0f;
    t.run(60);
    // divided by (1 + dt * damping) every sub-step: e^-2 = 0.135
    CHECK(t.world.get<RigidBody3D>(spinner)->angularVelocity.y == doctest::Approx(100.0f * std::exp(-2.0f)).epsilon(0.03));
    CHECK(t.world.get<RigidBody3D>(spinner)->angularVelocity.x == 0.0f);
}

TEST_CASE("3d rotation: a box under a rotated parent settles on a face, in world space") {
    Sim s;
    add_box3(s.world, "floor", {0, -0.5f, 0}, {20, 1, 20}, BodyType::Static, false);
    Entity parent = s.world.create("parent", "parent");
    s.world.get<Transform>(parent)->rotation = {0, 90, 0};
    s.world.get<Transform>(parent)->position = {2, 0, 0};
    Entity box = add_turned_box3(s.world, "box", {0, 2.0f, 0}, {1, 1, 1}, {0, 0, 20}, BodyType::Dynamic, true);
    s.world.set_parent(box, parent);
    s.run(300);
    const Mat4 m = s.world.world_matrix(box);
    const float up = std::max({std::fabs(m.at(0, 1)), std::fabs(m.at(1, 1)), std::fabs(m.at(2, 1))});
    CHECK(degrees(std::acos(clamp(up, 0.0f, 1.0f))) < 2.0f);
    CHECK(s.world.world_position(box).y == doctest::Approx(0.5f).epsilon(0.03));
}

TEST_CASE("3d rotation: a box slides down a 30 degree ramp flat on it (friction acts at the contact points)") {
    Sim s;
    const float sq = 0.5f, cq = std::sqrt(0.75f);  // sin, cos of 30 degrees
    // the ramp rises towards +x: its top face has the normal (-sin, cos, 0)
    const Vec3 normal{-sq, cq, 0}, down{-cq, -sq, 0};
    add_turned_box3(s.world, "ramp", normal * -0.5f, {40, 1, 10}, {0, 0, 30}, BodyType::Static, false);
    Entity box = add_turned_box3(s.world, "box", normal * 0.5f + Vec3{6.0f * cq, 6.0f * sq, 0}, {1, 1, 1}, {0, 0, 30}, BodyType::Dynamic, true);
    const Vec3 start = pos_of(s.world, box);
    s.run(60);  // 1 s: a = g (sin - mu cos) = 9.81 * (0.5 - 0.4 * 0.866) = 1.5 m/s^2 after the first sub-steps settle in
    const float slid = dot(pos_of(s.world, box) - start, down);
    MESSAGE("slid " << slid << " m down the ramp in 1 s (0.75 expected), off the face by "
                    << dot(pos_of(s.world, box) - start, normal) << ", turned " << deg_apart(s.world.get<Transform>(box)->rotation, {0, 0, 30}));
    CHECK(slid == doctest::Approx(0.5f * 9.81f * (sq - 0.4f * cq)).epsilon(0.1));
    CHECK(deg_apart(s.world.get<Transform>(box)->rotation, {0, 0, 30}) < 1.0f);
    CHECK(std::fabs(dot(pos_of(s.world, box) - start, normal)) < 0.01f);
    // a 20 degree ramp holds the same box (tan 20 = 0.36 < friction 0.4)
    Sim t;
    const float s2 = std::sin(radians(20.0f)), c2 = std::cos(radians(20.0f));
    const Vec3 n2{-s2, c2, 0};
    add_turned_box3(t.world, "ramp", n2 * -0.5f, {40, 1, 10}, {0, 0, 20}, BodyType::Static, false);
    Entity held = add_turned_box3(t.world, "box", n2 * 0.5f, {1, 1, 1}, {0, 0, 20}, BodyType::Dynamic, true);
    t.run(180);
    CHECK(length(pos_of(t.world, held) - n2 * 0.5f) < 0.05f);
}

TEST_CASE("3d rotation: a thrown, spinning box tumbles and ends at rest on a face") {
    Sim s;
    add_box3(s.world, "floor", {0, -0.5f, 0}, {60, 1, 60}, BodyType::Static, false);
    Entity box = add_turned_box3(s.world, "box", {-8, 3, 0}, {1, 0.6f, 1.6f}, {10, 20, 30}, BodyType::Dynamic, true);
    s.world.get<RigidBody3D>(box)->velocity = {7, 2, 1};
    s.world.get<RigidBody3D>(box)->angularVelocity = {200, -150, 320};
    s.world.get<Collider3D>(box)->restitution = 0.3f;
    s.run(60 * 8);
    const Vec3 p = pos_of(s.world, box);
    MESSAGE("came to rest at " << p.x << " " << p.y << " " << p.z << ", off flat " << off_flat(s.world, box) << " deg, spin " << spin_of(s.world, box));
    CHECK(std::isfinite(p.x + p.y + p.z));
    CHECK(off_flat(s.world, box) < 1.0f);
    CHECK(spin_of(s.world, box) < 1.0f);
    CHECK(length(s.world.get<RigidBody3D>(box)->velocity) < 0.05f);
    // the resting height is half the extent along the axis that points up: 0.3, 0.5 or 0.8
    CHECK((std::fabs(p.y - 0.3f) < 0.02f || std::fabs(p.y - 0.5f) < 0.02f || std::fabs(p.y - 0.8f) < 0.02f));
}

TEST_CASE("3d rotation: a pile of boxes and spheres dropped into a bin settles; nothing escapes or explodes") {
    Sim s;
    add_box3(s.world, "floor", {0, -0.5f, 0}, {8, 1, 8}, BodyType::Static, false);
    add_box3(s.world, "wall_w", {-4.25f, 2, 0}, {0.5f, 6, 9}, BodyType::Static, false);
    add_box3(s.world, "wall_e", {4.25f, 2, 0}, {0.5f, 6, 9}, BodyType::Static, false);
    add_box3(s.world, "wall_n", {0, 2, -4.25f}, {9, 6, 0.5f}, BodyType::Static, false);
    add_box3(s.world, "wall_s", {0, 2, 4.25f}, {9, 6, 0.5f}, BodyType::Static, false);
    std::vector<Entity> bodies;
    for (int i = 0; i < 12; ++i) {
        const Vec3 pos{6.0f * (frac(i, 0.754877f) - 0.5f), 1.0f + 1.2f * float(i), 6.0f * (frac(i, 0.569840f) - 0.5f)};
        if (i % 3 == 2) {
            bodies.push_back(add_sphere3(s.world, ("s" + std::to_string(i)).c_str(), pos, 0.3f + 0.2f * frac(i, 0.3f)));
        } else {
            bodies.push_back(add_turned_box3(s.world, ("b" + std::to_string(i)).c_str(), pos,
                                             {0.6f + 0.8f * frac(i, 0.41f), 0.5f + 0.6f * frac(i, 0.73f), 0.6f + 0.8f * frac(i, 0.19f)},
                                             {40.0f * frac(i, 0.3f), 360.0f * frac(i, 0.61f), 40.0f * frac(i, 0.77f)}, BodyType::Dynamic, true));
        }
    }
    s.run(60 * 10);
    float fastest = 0.0f, lowest = 1e9f, highest = -1e9f;
    for (Entity e : bodies) {
        const Vec3 p = pos_of(s.world, e);
        REQUIRE(std::isfinite(p.x + p.y + p.z));
        CHECK(std::fabs(p.x) < 4.0f);
        CHECK(std::fabs(p.z) < 4.0f);
        lowest = std::min(lowest, p.y);
        highest = std::max(highest, p.y);
        fastest = std::max(fastest, length(s.world.get<RigidBody3D>(e)->velocity));
    }
    MESSAGE("pile: lowest " << lowest << " highest " << highest << " fastest " << fastest);
    CHECK(lowest > 0.05f);   // nothing fell through the floor
    CHECK(highest < 5.0f);   // the pile is lower than the walls' tops (5 m)
    CHECK(fastest < 0.5f);   // and has settled
}

TEST_CASE("3d rotation: gameplay writing Transform.rotation re-orients a rotating box") {
    Sim s;
    no_gravity(s);
    Entity box = add_box3(s.world, "box", {0, 5, 0}, {1, 1, 1}, BodyType::Dynamic, true);
    s.world.get<RigidBody3D>(box)->angularVelocity = {0, 0, 90};
    s.run(30);
    CHECK(s.world.get<Transform>(box)->rotation.z == doctest::Approx(45.0f).epsilon(0.02));
    s.world.get<Transform>(box)->rotation = {0, 0, 0};  // reset the pose; the spin goes on from there
    s.run(30);
    CHECK(s.world.get<Transform>(box)->rotation.z == doctest::Approx(45.0f).epsilon(0.02));
    s.world.get<Transform>(box)->rotation = {0, 90, 0};
    s.world.get<RigidBody3D>(box)->angularVelocity = {0, 0, 0};
    s.run(10);
    CHECK(s.world.get<Transform>(box)->rotation == Vec3{0, 90, 0});  // no spin: the written value stays untouched
}

TEST_CASE("3d rotation: tipping scene is deterministic") {
    auto run = [] {
        Sim s;
        add_box3(s.world, "ledge", {-2.0f, -0.5f, 0}, {4, 1, 4}, BodyType::Static, false);
        add_box3(s.world, "floor", {4, -6.0f, 0}, {12, 1, 12}, BodyType::Static, false);
        std::vector<Entity> boxes;
        for (int i = 0; i < 3; ++i)
            boxes.push_back(add_turned_box3(s.world, ("b" + std::to_string(i)).c_str(),
                                            {0.1f + 0.3f * float(i), 0.5f + 1.1f * float(i), 0.1f * float(i)}, {1, 1, 1},
                                            {0, 7.0f * float(i), 3.0f * float(i)}, BodyType::Dynamic, true));
        Entity ball = add_sphere3(s.world, "ball", {-5, 0.4f, 0.2f}, 0.2f);
        s.world.get<RigidBody3D>(ball)->velocity = {4, 0, 0};
        s.run(300);
        std::vector<float> out;
        for (Entity e : boxes) {
            const Vec3 p = pos_of(s.world, e), r = s.world.get<Transform>(e)->rotation;
            out.insert(out.end(), {p.x, p.y, p.z, r.x, r.y, r.z});
        }
        return out;
    };
    const auto a = run(), b = run();
    REQUIRE(a.size() == b.size());
    CHECK(std::memcmp(a.data(), b.data(), a.size() * sizeof(float)) == 0);
    CHECK(a[1] < -0.5f);  // the first box did fall off (the scene is not trivially still)
}

TEST_CASE("3d continuous collision: two spheres at 60 m/s head-on never pass through each other (400 trials)") {
    for (int i = 0; i < 400; ++i) {
        Sim s;
        no_gravity(s);
        const float ra = 0.1f + 0.1f * frac(i, 0.618034f), rb = 0.1f + 0.1f * frac(i, 0.414214f);
        const float sum = ra + rb;
        const float dy = (frac(i, 0.754877f) - 0.5f) * 1.2f * sum, dz = (frac(i, 0.569840f) - 0.5f) * 0.8f * sum;
        Entity a = add_sphere3(s.world, "a", {-1.5f - 0.25f * frac(i, 0.324717f), 0, 0}, ra);
        Entity b = add_sphere3(s.world, "b", {1.5f + 0.25f * frac(i, 0.465571f), dy, dz}, rb);
        s.world.get<RigidBody3D>(a)->velocity = {60, 0, 0};
        s.world.get<RigidBody3D>(b)->velocity = {-60, 0, 0};
        s.world.get<RigidBody3D>(a)->mass = 0.5f + 2.5f * frac(i, 0.7548f);
        s.world.get<RigidBody3D>(b)->mass = 0.5f + 2.5f * frac(i, 0.2599f);
        for (int f = 0; f < 20; ++f) {
            s.run(1);
            const Vec3 d = pos_of(s.world, b) - pos_of(s.world, a);
            const float lateral = std::sqrt(d.y * d.y + d.z * d.z);
            // either b is still on its side, or the two went past each other touching (sliding around one another)
            if (d.x <= 0.0f && lateral < sum - 0.03f)
                FAIL("passed through: trial " << i << " frame " << f << " d " << d.x << " " << d.y << " " << d.z << " sum " << sum);
        }
        // the hit happened: a glancing one lets them fly apart again (no contact left at a frame end), but a was deflected
        if (length(s.world.get<RigidBody3D>(a)->velocity - Vec3{60, 0, 0}) < 1.0f) FAIL("never touched: trial " << i);
    }
}

TEST_CASE("3d continuous collision: a kinematic wall at 40 m/s pushes a resting sphere and never ends up behind it") {
    for (int i = 0; i < 200; ++i) {
        Sim s;
        no_gravity(s);
        const float wallX = -3.0f - 0.2f * frac(i, 0.618034f);
        Entity wall = add_box3(s.world, "wall", {wallX, 0, 0}, {0.02f, 8, 8}, BodyType::Kinematic, true);
        s.world.get<RigidBody3D>(wall)->velocity = {40, 0, 0};
        Entity ball = add_sphere3(s.world, "ball", {0, 2.0f * (frac(i, 0.754877f) - 0.5f), 2.0f * (frac(i, 0.569840f) - 0.5f)}, 0.05f);
        for (int f = 0; f < 30; ++f) {
            s.run(1);
            // in front of the wall's front face (half thickness 0.01) by about the radius, never behind it
            const float gap = pos_of(s.world, ball).x - pos_of(s.world, wall).x;
            if (gap < 0.01f + 0.05f - 0.02f) FAIL("behind the wall: trial " << i << " frame " << f << " gap " << gap);
        }
        CHECK(s.world.get<RigidBody3D>(ball)->velocity.x == doctest::Approx(40.0f).epsilon(0.05));
    }
}

TEST_CASE("3d continuous collision: a 60 m/s sphere hitting a 45 degree ramp keeps sliding along it in the same step") {
    Sim s;
    no_gravity(s);
    const float sq = std::sqrt(0.5f);
    const Vec3 normal{-sq, sq, 0}, tangent{sq, sq, 0};  // the ramp's top face, and the way up the slope
    Entity ramp = add_turned_box3(s.world, "ramp", normal * -0.5f, {20, 1, 20}, {0, 0, 45}, BodyType::Static, false);
    s.world.get<Collider3D>(ramp)->friction = 0.0f;
    const float r = 0.2f, y0 = 3.0f;
    const float xHit = y0 - r / sq;  // the ball's centre touches the face (its distance to the face plane = r) here
    Entity ball = add_sphere3(s.world, "ball", {xHit - 0.1f, y0, 0}, r);  // 0.1 m before the face, i.e. early in sub-step 1
    s.world.get<Collider3D>(ball)->friction = 0.0f;
    s.world.get<RigidBody3D>(ball)->rollWithMotion = false;
    s.world.get<RigidBody3D>(ball)->velocity = {60, 0, 0};
    s.run(1);
    const Vec3 hit{xHit, y0, 0};
    const Vec3 moved = pos_of(s.world, ball) - hit;
    // 0.1 m take 1/600 s; the remaining 15 ms are spent sliding at 60 * cos 45 = 42.4 m/s along the face
    const float expected = 42.426f * (kDt - 0.1f / 60.0f);
    MESSAGE("slid " << dot(moved, tangent) << " m along the ramp (expected " << expected << "), off the face by " << dot(moved, normal));
    CHECK(dot(moved, tangent) == doctest::Approx(expected).epsilon(0.03));
    CHECK(std::fabs(dot(moved, normal)) < 0.01f);
    const Vec3 v = s.world.get<RigidBody3D>(ball)->velocity;
    CHECK(dot(v, tangent) == doctest::Approx(42.426f).epsilon(0.01));
    CHECK(std::fabs(dot(v, normal)) < 0.1f);
    CHECK(s.count(CollisionEvent::Phase::Begin, false) == 1);
}

// ---------------------- 3D spheres as rigid bodies (rollWithMotion off, M7 leftovers) ----

TEST_CASE("3d sphere: without rollWithMotion a sphere on a 30 degree slope rolls without slipping; locked it slides") {
    const float sq = 0.5f, cq = std::sqrt(0.75f), r = 0.5f, g = 9.81f;
    const Vec3 normal{-sq, cq, 0}, down{-cq, -sq, 0};  // the ramp rises towards +x; its top face has this normal
    struct Run { float dist = 0, speed = 0; Vec3 spin, rotation; };
    auto slope = [&](bool rollWithMotion, bool lockRotation) {
        Sim s;
        add_turned_box3(s.world, "ramp", normal * -0.5f, {40, 1, 10}, {0, 0, 30}, BodyType::Static, false);
        Entity ball = add_sphere3(s.world, "ball", normal * r + Vec3{6.0f * cq, 6.0f * sq, 0}, r);
        RigidBody3D* rb = s.world.get<RigidBody3D>(ball);
        rb->rollWithMotion = rollWithMotion;
        rb->lockRotation = lockRotation;
        const Vec3 start = pos_of(s.world, ball);
        s.run(90);  // 1.5 s
        Run out;
        out.dist = dot(pos_of(s.world, ball) - start, down);
        out.speed = dot(rb->velocity, down);
        out.spin = rb->angularVelocity * kDegToRad;
        out.rotation = s.world.get<Transform>(ball)->rotation;
        return out;
    };
    const Run rigid = slope(false, false), locked = slope(false, true);
    MESSAGE("rigid: slid " << rigid.dist << " m at " << rigid.speed << " m/s, spin " << length(rigid.spin) << " rad/s (v / r = "
                           << rigid.speed / r << ")");
    // a solid sphere rolling down a slope: a = 5/7 g sin(theta) (0.5 * 3.5 * 1.5^2 = 3.9 m in 1.5 s), spin = v / r about
    // the axis normal x velocity
    CHECK(rigid.dist == doctest::Approx(0.5f * (5.0f / 7.0f) * g * sq * 1.5f * 1.5f).epsilon(0.05));
    CHECK(length(rigid.spin) * r == doctest::Approx(rigid.speed).epsilon(0.05));
    CHECK(length(rigid.spin - cross(normal, down) * (rigid.speed / r)) < 0.05f * length(rigid.spin));
    // friction 0.4 on a 30 degree slope would give a = g (sin - 0.4 cos) = 1.5 m/s^2 for a sliding sphere
    CHECK(locked.dist == doctest::Approx(0.5f * g * (sq - 0.4f * cq) * 1.5f * 1.5f).epsilon(0.08));
    CHECK(locked.spin == Vec3{});
    CHECK(locked.rotation == Vec3{});
    CHECK(rigid.dist > locked.dist * 1.8f);
}

TEST_CASE("3d sphere: an off-centre hit spins both rigid spheres and conserves angular momentum; arcade spheres stay unspun") {
    for (int rigid = 0; rigid < 2; ++rigid) {
        Sim s;
        no_gravity(s);
        Entity a = add_sphere3(s.world, "a", {-3, 0, 0}, 0.5f);
        Entity b = add_sphere3(s.world, "b", {0, 0, 0.3f}, 0.5f);
        for (Entity e : {a, b}) s.world.get<RigidBody3D>(e)->rollWithMotion = rigid == 0;
        s.world.get<RigidBody3D>(a)->velocity = {5, 0, 0};
        s.run(60);
        const RigidBody3D* ra = s.world.get<RigidBody3D>(a);
        const RigidBody3D* rb = s.world.get<RigidBody3D>(b);
        MESSAGE(std::string(rigid ? "rigid" : "arcade") << ": spin a " << ra->angularVelocity.y << " b " << rb->angularVelocity.y << " deg/s");
        CHECK(s.count(CollisionEvent::Phase::Begin, false) == 1);
        if (!rigid) {
            CHECK(ra->angularVelocity == Vec3{});
            CHECK(rb->angularVelocity == Vec3{});
            continue;
        }
        // A's tangential velocity at the contact drags B's surface along it: B spins about -y (a hit on B's -x side, 0.3 m
        // towards +z), A is spun the same way by the reaction. Friction (mu 0.4) removes the whole slip of 5 * 0.3 = 1.5 m/s:
        // impulse 1.5 / (2/m + 2 r^2 / I) = 0.214, spin 0.214 * r / I = 1.07 rad/s = 61 deg/s each.
        CHECK(rb->angularVelocity.y == doctest::Approx(-61.3f).epsilon(0.08));
        CHECK(ra->angularVelocity.y == doctest::Approx(-61.3f).epsilon(0.08));
        CHECK(std::fabs(rb->angularVelocity.x) < 1e-2f);
        CHECK(std::fabs(rb->angularVelocity.z) < 1e-2f);
        // nothing but the two spheres exchanged impulses: total angular momentum about the origin stays 0 (I = 2/5 m r^2)
        const float inertia = 0.4f * 1.0f * 0.25f;
        Vec3 total{};
        for (Entity e : {a, b}) {
            const RigidBody3D* body = s.world.get<RigidBody3D>(e);
            total += cross(pos_of(s.world, e), body->velocity) + body->angularVelocity * kDegToRad * inertia;
        }
        CHECK(length(total) < 0.02f);
    }
}
