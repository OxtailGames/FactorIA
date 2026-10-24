// NavMesh3D: bake of the static colliders into a walkable grid, paths around walls, up ramps, never up a high step.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <format>
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

// ---------------------------------------------------------------- off-mesh links ----
namespace {

// Two islands (top y = 0): x -10..-4 and x 4..10, z -5..5, with a 8 m gap between them, and a NavMesh3D over both.
void build_islands(World& w) {
    add_box(w, "west", {-7, -0.5f, 0}, {6, 1, 10});
    add_box(w, "east", {7, -0.5f, 0}, {6, 1, 10});
    add_navmesh(w, {0, 2, 0}, {30, 6, 20});
}

Entity add_link(World& w, const char* id, Vec3 from, Vec3 to, bool bidirectional = true, float cost = 0.0f) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = from;
    NavLink3D& l = w.add<NavLink3D>(e);
    l.end = to;
    l.bidirectional = bidirectional;
    l.cost = cost;
    return e;
}

}  // namespace

TEST_CASE("nav: a link joins two islands and a one-way link refuses the way back") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    build_islands(w);
    add_link(w, "jump", {-5, 0, 0}, {5, 0, 0}, false);
    p.sync(w);
    auto bake = p.nav_bake(w);
    REQUIRE(bake.ok());
    CHECK(bake.value()[0].links == 1);
    CHECK(bake.value()[0].regions == 1);  // the link joins the two areas
    auto there = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(there.ok());
    const NavPath& path = there.value();
    REQUIRE(path.found);
    REQUIRE(path.links.size() == 1);
    CHECK(path.links[0].entity == "jump");
    const int at = path.links[0].point;
    REQUIRE(at >= 0);
    REQUIRE(std::size_t(at) + 1 < path.points.size());
    CHECK(path.points[std::size_t(at)].x == doctest::Approx(-5.0f).epsilon(0.2));      // starts at the entity
    CHECK(path.points[std::size_t(at) + 1].x == doctest::Approx(5.0f).epsilon(0.2));  // ends at `end`
    auto back = p.nav_find_path(w, {8, 0, 0}, {-8, 0, 0});
    REQUIRE(back.ok());
    CHECK_FALSE(back.value().found);
    CHECK(back.value().reason == "disconnected");
    // The result names the links in JSON too (scripts read it).
    CHECK(there.value().to_json()["links"][0]["entity"] == "jump");
}

TEST_CASE("nav: a two-way link works both ways, and cost makes a path prefer walking") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    build_islands(w);
    add_box(w, "bridge", {0, -0.5f, 4}, {8, 1, 2});  // a real walkway along z 3..5, 8 m long
    add_link(w, "shortcut", {-5, 0, 0}, {5, 0, 0}, true, 100.0f);
    p.sync(w);
    REQUIRE(p.nav_bake(w).ok());
    auto r = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(r.ok());
    REQUIRE(r.value().found);
    CHECK(r.value().links.empty());  // the walkway is cheaper than the link's cost
    // Without the walkway the link is the only way, in both directions.
    World w2;
    Physics p2;
    p2.init(PhysicsSettings{});
    build_islands(w2);
    add_link(w2, "shortcut", {-5, 0, 0}, {5, 0, 0});
    p2.sync(w2);
    REQUIRE(p2.nav_bake(w2).ok());
    auto a = p2.nav_find_path(w2, {-8, 0, 0}, {8, 0, 0}), b = p2.nav_find_path(w2, {8, 0, 0}, {-8, 0, 0});
    REQUIRE(a.ok());
    REQUIRE(b.ok());
    CHECK(a.value().found);
    CHECK(b.value().found);
    CHECK(b.value().links.size() == 1);
    // moving the link's end re-resolves it without a bake
    w2.get<NavLink3D>(w2.find_by_id("shortcut"))->end = {5, 0, 40};  // outside the mesh
    p2.step(w2, 1.0f / 60.0f);
    auto gone = p2.nav_find_path(w2, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(gone.ok());
    CHECK_FALSE(gone.value().found);
}

// ---------------------------------------------------------------- walkable bodies ----
namespace {

Entity add_kinematic(World& w, const char* id, Vec3 pos, Vec3 size, bool walkable = true, Vec3 rot = {0, 0, 0}) {
    Entity e = add_box(w, id, pos, size, rot);
    w.add<RigidBody3D>(e).type = BodyType::Kinematic;
    w.get<Collider3D>(e)->navWalkable = walkable;
    return e;
}

// The two islands and a 8 m gap with a bridge of kinematic planks across it.
void build_bridge(World& w, bool walkable) {
    build_islands(w);
    for (int i = 0; i < 8; ++i) {
        const std::string id = "plank" + std::to_string(i);
        add_kinematic(w, id.c_str(), {-3.5f + float(i), -0.1f, 0}, {0.95f, 0.2f, 1.6f}, walkable);
    }
}

}  // namespace

TEST_CASE("nav: a path crosses a walkable plank bridge") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    build_bridge(w, true);
    p.sync(w);
    auto bake = p.nav_bake(w);
    REQUIRE(bake.ok());
    CHECK(bake.value()[0].regions == 2);  // the bridge is not part of the static bake
    CHECK(bake.value()[0].walkableBodies == 8);
    auto r = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(r.ok());
    REQUIRE(r.value().found);
    // it walks along the bridge, not around anything
    for (const Vec3& pt : r.value().points) CHECK(std::fabs(pt.z) < 1.0f);
    CHECK(r.value().length == doctest::Approx(16.0f).epsilon(0.05));
    // the cells of the planks are drawn as moving ones
    int moving = 0;
    for (const NavCell& c : p.nav_cells(w))
        if (c.moving) ++moving;
    CHECK(moving > 20);
}

TEST_CASE("nav: planks that are not navWalkable leave the gap open") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    build_bridge(w, false);
    p.sync(w);
    REQUIRE(p.nav_bake(w).ok());
    auto r = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(r.ok());
    CHECK_FALSE(r.value().found);
    CHECK(r.value().reason == "disconnected");
}

TEST_CASE("nav: a moving platform joins the path when it docks and is disconnected when it is away") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    build_islands(w);
    Entity plat = add_kinematic(w, "lift", {0, -0.1f, 8}, {8, 0.2f, 4});  // away: beside the gap
    p.sync(w);
    REQUIRE(p.nav_bake(w).ok());
    auto away = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(away.ok());
    CHECK_FALSE(away.value().found);
    CHECK(away.value().reason == "disconnected");
    CHECK(away.value().message.find("navWalkable") != std::string::npos);
    w.get<Transform>(plat)->position = {0, -0.1f, 0};  // docks between the islands
    p.step(w, 1.0f / 60.0f);
    auto docked = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(docked.ok());
    CHECK(docked.value().found);
    // standing on the platform works too, and leaving it breaks the way again
    auto onIt = p.nav_find_path(w, {0, 0, 0}, {8, 0, 0});
    REQUIRE(onIt.ok());
    CHECK(onIt.value().found);
    w.get<Transform>(plat)->position = {0, -0.1f, 8};
    p.step(w, 1.0f / 60.0f);
    auto left = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(left.ok());
    CHECK_FALSE(left.value().found);
    // slides in from the side a few steps at a time, as a platform does
    for (int i = 0; i < 40; ++i) {
        w.get<Transform>(plat)->position = {0, -0.1f, 8.0f - 0.2f * float(i + 1)};
        p.step(w, 1.0f / 60.0f);
    }
    auto docked2 = p.nav_find_path(w, {-8, 0, 0}, {8, 0, 0});
    REQUIRE(docked2.ok());
    CHECK(docked2.value().found);
    CHECK(docked2.value().to_json().dump() == docked.value().to_json().dump());
}

TEST_CASE("nav: the same path twice gives the same bits, with walkable bodies and links") {
    auto run = [] {
        World w;
        Physics p;
        p.init(PhysicsSettings{});
        build_bridge(w, true);
        Entity plat = add_kinematic(w, "lift", {0, -0.1f, 12}, {2, 0.2f, 2});
        add_link(w, "hop", {8, 0, 4}, {8, 0, 9});
        p.sync(w);
        REQUIRE(p.nav_bake(w).ok());
        std::string out;
        for (int i = 0; i < 30; ++i) {
            w.get<Transform>(plat)->position = {-6.0f + 0.4f * float(i), -0.1f, 3.0f};
            p.step(w, 1.0f / 60.0f);
            auto r = p.nav_find_path(w, {-8, 0, 3}, {8, 0, 3});
            REQUIRE(r.ok());
            out += r.value().to_json().dump();
        }
        auto cells = p.nav_cells(w);
        out += std::to_string(cells.size());
        for (const NavCell& c : cells) out += std::to_string(c.center.x + c.center.y + c.center.z) + (c.moving ? "m" : "s");
        return out;
    };
    const std::string a = run(), b = run();
    CHECK(a == b);
    CHECK(a.size() > 100);
}

TEST_CASE("nav: re-marking a moved body gives the cells a fresh bake would") {
    World w;
    Physics p;
    p.init(PhysicsSettings{});
    build_islands(w);
    Entity plat = add_kinematic(w, "lift", {0, -0.1f, 0}, {8, 0.2f, 4});
    p.sync(w);
    REQUIRE(p.nav_bake(w).ok());
    auto describe = [&](Physics& ph, World& wd) {
        std::vector<std::string> v;
        for (const NavCell& c : ph.nav_cells(wd))
            v.push_back(std::format("{:.3f},{:.3f},{:.3f},{}", c.center.x, c.center.y, c.center.z, c.moving ? 1 : 0));
        std::sort(v.begin(), v.end());  // the dynamic cells may be listed in another order
        return v;
    };
    // wander around, and come back to the dock
    const Vec3 route[] = {{0, -0.1f, 3}, {2, -0.1f, 6}, {-1, -0.05f, 2}, {0, -0.1f, 0}};
    for (const Vec3& at : route) {
        w.get<Transform>(plat)->position = at;
        p.step(w, 1.0f / 60.0f);
    }
    const auto incremental = describe(p, w);
    // a world made with the platform already there, then baked
    World w2;
    Physics p2;
    p2.init(PhysicsSettings{});
    build_islands(w2);
    add_kinematic(w2, "lift", {0, -0.1f, 0}, {8, 0.2f, 4});
    p2.sync(w2);
    REQUIRE(p2.nav_bake(w2).ok());
    const auto fresh = describe(p2, w2);
    CHECK(!fresh.empty());
    CHECK(incremental == fresh);
}
