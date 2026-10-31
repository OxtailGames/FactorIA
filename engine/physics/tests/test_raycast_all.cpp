// physics.raycast2d_all / raycast3d_all and Collider2D/3D.enabled.
#include <doctest.h>

#include "fa/physics/physics.h"

using namespace fa;

namespace {
Entity wall3(World& w, const char* id, float x, float sx = 1.0f) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = {x, 0, 0};
    Collider3D& c = w.add<Collider3D>(e);
    c.size = {sx, 4, 4};
    return e;
}
Entity wall2(World& w, const char* id, float y) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = {0, y, 0};
    w.add<Collider2D>(e).size = {100, 10};
    return e;
}
}  // namespace

TEST_CASE("raycast3d_all: every hit in distance order, capped by maxHits") {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    // created out of order on purpose
    Entity c = wall3(world, "c", 15), a = wall3(world, "a", 5), b = wall3(world, "b", 10);
    physics.sync(world);

    auto hits = physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 100);
    REQUIRE(hits.size() == 3);
    CHECK(hits[0].entity == a);
    CHECK(hits[1].entity == b);
    CHECK(hits[2].entity == c);
    CHECK(hits[0].distance == doctest::Approx(4.5f));
    CHECK(hits[1].distance == doctest::Approx(9.5f));
    CHECK(hits[2].distance == doctest::Approx(14.5f));
    CHECK(hits[0].normal.x == doctest::Approx(-1.0f));

    RaycastOptions two;
    two.maxHits = 2;
    auto near2 = physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 100, two);
    REQUIRE(near2.size() == 2);
    CHECK(near2[0].entity == a);
    CHECK(near2[1].entity == b);

    // maxDistance cuts the far one; the first hit equals raycast3d
    auto cut = physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 12);
    CHECK(cut.size() == 2);
    auto first = physics.raycast3d(world, {0, 0, 0}, {1, 0, 0}, 100);
    REQUIRE(first);
    CHECK(first->entity == hits[0].entity);

    CHECK(physics.raycast3d_all(world, {0, 0, 0}, {-1, 0, 0}, 100).empty());
    two.maxHits = 0;
    CHECK(physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 100, two).empty());
}

TEST_CASE("Collider3D.enabled: a disabled collider is let through by every query and back") {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    Entity a = wall3(world, "a", 5), b = wall3(world, "b", 10);
    physics.sync(world);
    CHECK(physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 100).size() == 2);

    world.get<Collider3D>(a)->enabled = false;
    physics.sync(world);
    auto hits = physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 100);
    REQUIRE(hits.size() == 1);
    CHECK(hits[0].entity == b);
    auto first = physics.raycast3d(world, {0, 0, 0}, {1, 0, 0}, 100);
    REQUIRE(first);
    CHECK(first->entity == b);
    CHECK(physics.overlap_sphere3d(world, {5, 0, 0}, 1).empty());
    CHECK(world.get<Collider3D>(a) != nullptr);  // the component stays

    world.get<Collider3D>(a)->enabled = true;
    physics.sync(world);
    CHECK(physics.raycast3d_all(world, {0, 0, 0}, {1, 0, 0}, 100).size() == 2);
    CHECK(physics.overlap_sphere3d(world, {5, 0, 0}, 1).size() == 1);
}

TEST_CASE("Collider3D.enabled: a disabled floor lets a body fall through") {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    Entity floor = world.create("floor", "floor");
    world.get<Transform>(floor)->position = {0, -1, 0};
    world.add<Collider3D>(floor).size = {20, 1, 20};
    Entity ball = world.create("ball", "ball");
    world.get<Transform>(ball)->position = {0, 2, 0};
    world.add<Collider3D>(ball).shape = ColliderShape3D::Sphere;
    world.add<RigidBody3D>(ball).type = BodyType::Dynamic;
    world.get<Collider3D>(floor)->enabled = false;
    for (int i = 0; i < 120; ++i) { physics.step(world, 1.0f / 60.0f); world.flush(); }
    CHECK(world.get<Transform>(ball)->position.y < -2.0f);
}

TEST_CASE("Collider3D.enabled: a disabled collider stays out of the NavMesh bake") {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    auto box = [&](const char* id, Vec3 pos, Vec3 size) {
        Entity e = world.create(id, id);
        world.get<Transform>(e)->position = pos;
        world.add<Collider3D>(e).size = size;
        return e;
    };
    box("floor", {0, -0.5f, 0}, {30, 1, 30});
    Entity wall = box("wall", {0, 1.5f, 0}, {0.4f, 3, 8});
    Entity nav = world.create("navmesh", "navmesh");
    world.get<Transform>(nav)->position = {0, 2, 0};
    NavMesh3D& n = world.add<NavMesh3D>(nav);
    n.size = {30, 6, 30};
    n.agentRadius = 0.3f;
    physics.sync(world);

    auto around = physics.nav_find_path(world, {-5, 0, 0}, {5, 0, 0});
    REQUIRE(around.ok());
    REQUIRE(around.value().found);
    CHECK(around.value().length > 12.0f);  // detour around the wall

    world.get<Collider3D>(wall)->enabled = false;
    physics.sync(world);
    auto through = physics.nav_find_path(world, {-5, 0, 0}, {5, 0, 0});
    REQUIRE(through.ok());
    REQUIRE(through.value().found);
    CHECK(through.value().length == doctest::Approx(10.0f).epsilon(0.02));  // straight through the disabled wall

    world.get<Collider3D>(wall)->enabled = true;
    physics.sync(world);
    auto back = physics.nav_find_path(world, {-5, 0, 0}, {5, 0, 0});
    REQUIRE(back.ok());
    CHECK(back.value().length > 12.0f);
}

TEST_CASE("raycast2d_all: every hit in distance order, maxHits, and Collider2D.enabled") {
    World world;
    Physics physics;
    physics.init(PhysicsSettings{});
    Entity low = wall2(world, "low", -200), high = wall2(world, "high", 100), mid = wall2(world, "mid", -50);
    physics.sync(world);

    auto hits = physics.raycast2d_all(world, {0, 300}, {0, -400});
    REQUIRE(hits.size() == 3);
    CHECK(hits[0].entity == high);
    CHECK(hits[1].entity == mid);
    CHECK(hits[2].entity == low);
    CHECK(hits[0].distance == doctest::Approx(195.0f).epsilon(0.01));
    CHECK(hits[0].normal.y == doctest::Approx(1.0f));

    RaycastOptions one;
    one.maxHits = 1;
    auto first = physics.raycast2d_all(world, {0, 300}, {0, -400}, one);
    REQUIRE(first.size() == 1);
    CHECK(first[0].entity == high);

    world.get<Collider2D>(high)->enabled = false;
    physics.sync(world);
    hits = physics.raycast2d_all(world, {0, 300}, {0, -400});
    REQUIRE(hits.size() == 2);
    CHECK(hits[0].entity == mid);
    auto single = physics.raycast2d(world, {0, 300}, {0, -400});
    REQUIRE(single);
    CHECK(single->entity == mid);
    CHECK(physics.overlap_box2d(world, Rect{-10, 95, 20, 10}).empty());

    world.get<Collider2D>(high)->enabled = true;
    physics.sync(world);
    CHECK(physics.raycast2d_all(world, {0, 300}, {0, -400}).size() == 3);
}
