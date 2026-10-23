// NavMesh3D: bake of the static colliders into a walkable grid, paths around walls, up ramps, never up a high step.
#include <doctest.h>

#include <cmath>
#include <string>

#include "fa/physics/physics.h"

using namespace fa;

namespace {

Entity add_box(World& w, const char* id, Vec3 pos, Vec3 size, Vec3 rot = {0, 0, 0}) {
    Entity e = w.create(id, id);
    Transform* t = w.get<Transform>(e);
    t->position = pos;
    t->rotation = rot;
    Collider3D& c = w.add<Collider3D>(e);
    c.shape = ColliderShape3D::Box;
    c.size = size;
    return e;
}

Entity add_navmesh(World& w, Vec3 pos, Vec3 size, float radius = 0.3f) {
    Entity e = w.create("navmesh", "navmesh");
    w.get<Transform>(e)->position = pos;
    NavMesh3D& n = w.add<NavMesh3D>(e);
    n.size = size;
    n.agentRadius = radius;
    return e;
}

// 30 x 30 floor (top y = 0), a wall at x = 0 from z = -4 to 4, a ramp (14 degrees) from (2, 0) up to a platform whose top
// is y = 1 at x 6..10, z 4..8, and a second platform of the same height at x -10..-6 with no ramp (a step of 1 m).
void build_level(World& w) {
    add_box(w, "floor", {0, -0.5f, 0}, {30, 1, 30});
    add_box(w, "wall", {0, 1.5f, 0}, {0.4f, 3, 8});
    const float ang = std::atan(0.25f), len = 4.0f / std::cos(ang);
    add_box(w, "ramp", {4.0f + 0.1f * std::sin(ang), 0.5f - 0.1f * std::cos(ang), 6}, {len, 0.2f, 3},
            {0, 0, ang * 180.0f / 3.14159265f});
    add_box(w, "platform", {8, 0.5f, 6}, {4, 1, 4});
    add_box(w, "highstep", {-8, 0.5f, 6}, {4, 1, 4});
    add_navmesh(w, {0, 2, 0}, {30, 6, 30});
}

struct Level {
    World world;
    Physics physics;
    Level() {
        physics.init(PhysicsSettings{});
        build_level(world);
        physics.sync(world);
    }
};

// True when the segment a-b passes through the wall (|x| < 0.2, |z| < 4) at any height.
bool crosses_wall(Vec3 a, Vec3 b) {
    for (int i = 0; i <= 200; ++i) {
        const float t = float(i) / 200.0f;
        const float x = a.x + (b.x - a.x) * t, z = a.z + (b.z - a.z) * t;
        if (std::fabs(x) < 0.2f && std::fabs(z) < 4.0f) return true;
    }
    return false;
}

}  // namespace

TEST_CASE("nav: bake reports cells, walkable cells and regions") {
    Level l;
    auto r = l.physics.nav_bake(l.world);
    REQUIRE(r.ok());
    REQUIRE(r.value().size() == 1);
    const NavBakeStats& s = r.value()[0];
    CHECK(s.mesh == "navmesh");
    CHECK(s.cellsX == 120);
    CHECK(s.cellsZ == 120);
    CHECK(s.walkableCells > 10000);
    CHECK(s.regions == 2);  // the floor with the ramp and platform, and the platform with no ramp
    CHECK(l.world.get<NavMesh3D>(l.world.find_by_id("navmesh"))->walkableCells == s.walkableCells);
}

TEST_CASE("nav: the path goes around the wall") {
    Level l;
    auto r = l.physics.nav_find_path(l.world, {-5, 0, 0}, {5, 0, 0});
    REQUIRE(r.ok());
    const NavPath& p = r.value();
    REQUIRE(p.found);
    CHECK(p.complete);
    CHECK(p.points.size() >= 3);
    CHECK(p.length > 10.0f);
    CHECK(p.length < 16.0f);
    CHECK(p.points.front().x == doctest::Approx(-5.0f));
    CHECK(p.points.back().x == doctest::Approx(5.0f));
    for (std::size_t i = 1; i < p.points.size(); ++i) CHECK_FALSE(crosses_wall(p.points[i - 1], p.points[i]));
}

TEST_CASE("nav: the path climbs the ramp to the platform") {
    Level l;
    auto r = l.physics.nav_find_path(l.world, {-5, 0, 0}, {8, 1, 6});
    REQUIRE(r.ok());
    const NavPath& p = r.value();
    REQUIRE(p.found);
    CHECK(p.points.back().y == doctest::Approx(1.0f).epsilon(0.1));
    float maxY = 0.0f;
    for (const Vec3& v : p.points) maxY = std::max(maxY, v.y);
    CHECK(maxY > 0.8f);
    for (std::size_t i = 1; i < p.points.size(); ++i) CHECK_FALSE(crosses_wall(p.points[i - 1], p.points[i]));
}

TEST_CASE("nav: a step higher than stepHeight is never climbed") {
    Level l;
    auto r = l.physics.nav_find_path(l.world, {-5, 0, 0}, {-8, 1, 6});
    REQUIRE(r.ok());
    CHECK_FALSE(r.value().found);
    CHECK(r.value().reason == "disconnected");
    CHECK(r.value().message.find("different walkable areas") != std::string::npos);
    CHECK(r.value().message.find("stepHeight") != std::string::npos);
    // closest: walks to the reachable point nearest the goal, never onto the platform
    NavPathOptions o;
    o.closest = true;
    auto c = l.physics.nav_find_path(l.world, {-5, 0, 0}, {-8, 1, 6}, o);
    REQUIRE(c.ok());
    REQUIRE(c.value().found);
    CHECK_FALSE(c.value().complete);
    for (const Vec3& v : c.value().points) CHECK(v.y < 0.5f);
}

TEST_CASE("nav: off-mesh start and goal teach where the nearest walkable point is") {
    Level l;
    auto r = l.physics.nav_find_path(l.world, {0, 3.2f, 0}, {5, 0, 0});  // on top of the wall, 3 m above the floor
    REQUIRE(r.ok());
    CHECK_FALSE(r.value().found);
    CHECK(r.value().reason == "start_off_mesh");
    CHECK(r.value().nearestDistance > 0.0f);
    CHECK(r.value().message.find("nearest walkable point") != std::string::npos);
    auto snapped = l.physics.nav_find_path(l.world, {0.1f, 0, 0}, {5, 0, 0});  // inside the wall: moved to the floor beside it
    REQUIRE(snapped.ok());
    CHECK(snapped.value().found);
    auto o = l.physics.nav_find_path(l.world, {5, 0, 0}, {100, 0, 0});  // outside the bounds
    REQUIRE(o.ok());
    CHECK(o.value().reason == "goal_off_mesh");
    CHECK(o.value().message.find("outside the bounds") != std::string::npos);
}

TEST_CASE("nav: a radius bigger than the baked agent is an error that says how to fix it") {
    Level l;
    NavPathOptions o;
    o.radius = 0.8f;
    auto r = l.physics.nav_find_path(l.world, {-5, 0, 0}, {5, 0, 0}, o);
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("larger than") != std::string::npos);
    CHECK(r.error().hint.find("agentRadius") != std::string::npos);
    o.radius = 0.2f;
    CHECK(l.physics.nav_find_path(l.world, {-5, 0, 0}, {5, 0, 0}, o).ok());
}

TEST_CASE("nav: no NavMesh3D in the scene is an error that says what to add") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    auto r = p.nav_find_path(w, {0, 0, 0}, {1, 0, 0});
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().hint.find("NavMesh3D") != std::string::npos);
    CHECK_FALSE(p.nav_bake(w).ok());
}

TEST_CASE("nav: two bakes of the same level are identical") {
    Level a, b;
    auto sa = a.physics.nav_bake(a.world), sb = b.physics.nav_bake(b.world);
    REQUIRE(sa.ok());
    REQUIRE(sb.ok());
    CHECK(sa.value()[0].to_json().dump() == sb.value()[0].to_json().dump());
    const auto ca = a.physics.nav_cells(a.world), cb = b.physics.nav_cells(b.world);
    REQUIRE(ca.size() == cb.size());
    for (std::size_t i = 0; i < ca.size(); ++i) {
        CHECK(ca[i].center.x == cb[i].center.x);
        CHECK(ca[i].center.y == cb[i].center.y);
        CHECK(ca[i].center.z == cb[i].center.z);
        CHECK(ca[i].region == cb[i].region);
    }
    auto pa = a.physics.nav_find_path(a.world, {-5, 0, 0}, {8, 1, 6}), pb = b.physics.nav_find_path(b.world, {-5, 0, 0}, {8, 1, 6});
    REQUIRE(pa.ok());
    REQUIRE(pb.ok());
    CHECK(pa.value().to_json().dump() == pb.value().to_json().dump());
    // and a second bake in the same world changes nothing
    auto again = a.physics.nav_bake(a.world);
    REQUIRE(again.ok());
    CHECK(again.value()[0].to_json().dump() == sa.value()[0].to_json().dump());
}

TEST_CASE("nav: a moving obstacle blocks the cells it covers and frees them when it leaves") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    add_box(w, "floor", {0, -0.5f, 0}, {10, 1, 10});
    add_navmesh(w, {0, 2, 0}, {10, 6, 10});
    Entity door = add_box(w, "door", {0, 1, 0}, {0.4f, 2, 10});
    w.get<Collider3D>(door)->navObstacle = true;
    p.sync(w);
    auto bake = p.nav_bake(w);
    REQUIRE(bake.ok());
    CHECK(bake.value()[0].regions == 1);  // the obstacle is not part of the static bake
    CHECK(bake.value()[0].obstacles == 1);
    auto blocked = p.nav_find_path(w, {-3, 0, 0}, {3, 0, 0});
    REQUIRE(blocked.ok());
    CHECK_FALSE(blocked.value().found);
    CHECK(blocked.value().reason == "disconnected");
    CHECK(blocked.value().message.find("navObstacle") != std::string::npos);
    w.get<Transform>(door)->position = {0, 1, 40};  // out of the bounds
    p.step(w, 1.0f / 60.0f);
    auto freed = p.nav_find_path(w, {-3, 0, 0}, {3, 0, 0});
    REQUIRE(freed.ok());
    CHECK(freed.value().found);
    w.get<Transform>(door)->position = {0, 1, 0};
    p.step(w, 1.0f / 60.0f);
    auto again = p.nav_find_path(w, {-3, 0, 0}, {3, 0, 0});
    REQUIRE(again.ok());
    CHECK_FALSE(again.value().found);
}
