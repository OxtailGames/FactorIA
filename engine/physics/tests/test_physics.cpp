#include <doctest.h>

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
