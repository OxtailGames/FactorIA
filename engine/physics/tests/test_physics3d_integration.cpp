// Integration tests of the 3D solver's bookkeeping (M94.4g): what has to keep working when gameplay changes the scene between
// steps (a static body moved by hand while bodies rest on it, a body deleted so the indices of the others shift, an entity
// slot reused after World::clear(), layers and masks edited at run time), the order of the end events, and the movers the
// island search treats specially (long shapes with a big reach, a mesh whose origin is far from its triangles, a fast
// platform that carries a crate and a character).
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <string>
#include <utility>
#include <vector>

#include "fa/physics/physics.h"

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
    bool awake(Entity e) const {
        const std::string& id = world.id_of(e);
        for (const Json& j : physics.debug_state(world))
            if (j["entity"] == id) return j["awake"].get<bool>();
        FAIL("no debug state for " << id);
        return false;
    }
    int count(CollisionEvent::Phase ph, Entity a, Entity b) const {
        int n = 0;
        for (const CollisionEvent& e : events)
            if (e.phase == ph && ((e.a == a && e.b == b) || (e.a == b && e.b == a))) ++n;
        return n;
    }
};

Entity add_box(World& w, const char* id, Vec3 pos, Vec3 size, bool dynamic) {
    Entity e = w.create(id, id);
    w.get<Transform>(e)->position = pos;
    w.add<Collider3D>(e).size = size;
    if (dynamic) w.add<RigidBody3D>(e);
    return e;
}

Vec3 pos_of(const World& w, Entity e) { return w.world_position(e); }

std::string name_of(const World& w, Entity e) { return w.id_of(e); }

}  // namespace

// Ten boxes rest apart on a floor; gameplay lifts them all in the same step, so ten contacts end together. The events come
// out in the order of the pairs (the order the bodies were created in), the same in two runs, and each pair ends once.
TEST_CASE("3d integration: the end events of several contacts at once come out in the same order in every run") {
    std::vector<std::vector<std::string>> runs;
    for (int run = 0; run < 2; ++run) {
        Sim s;
        add_box(s.world, "floor", {0, -0.5f, 0}, {40, 1, 40}, false);
        std::vector<Entity> boxes;
        for (int i = 0; i < 10; ++i)
            boxes.push_back(add_box(s.world, ("b" + std::to_string(i)).c_str(),
                                    {-9.0f + 2.0f * float(i), 0.5f, float(i % 3)}, {1, 1, 1}, true));
        s.run(90);
        s.events.clear();
        for (Entity e : boxes) s.world.get<Transform>(e)->position.y += 5.0f;
        s.run(1);
        std::vector<std::string> order;
        for (const CollisionEvent& e : s.events)
            if (e.phase == CollisionEvent::Phase::End) order.push_back(name_of(s.world, e.a) + "|" + name_of(s.world, e.b));
        CHECK(order.size() == 10);
        runs.push_back(order);
    }
    CHECK(runs[0] == runs[1]);
    // (lower body first: the floor was created first, so every pair reads floor|bN, in the order of N)
    for (std::size_t i = 0; i < runs[0].size(); ++i) CHECK(runs[0][i] == "floor|b" + std::to_string(i));
}

// A crate rests asleep against a static wall that gameplay then moves by hand: away (the pair ends), then back into the
// crate (the crate wakes, the pair begins again, and it is pushed out of the wall).
TEST_CASE("3d integration: a static wall moved by hand ends its pair, and wakes a crate it is moved into") {
    Sim s;
    add_box(s.world, "floor", {0, -0.5f, 0}, {40, 1, 40}, false);
    Entity wall = add_box(s.world, "wall", {2.5f, 2, 0}, {1, 4, 10}, false);
    Entity crate = add_box(s.world, "crate", {1.5f, 0.5f, 0}, {1, 1, 1}, true);
    s.run(120);
    REQUIRE_FALSE(s.awake(crate));
    CHECK(s.count(CollisionEvent::Phase::Begin, wall, crate) == 1);
    s.events.clear();
    s.world.get<Transform>(wall)->position.x = 7.5f;  // away: the pair ends
    s.run(2);
    CHECK(s.count(CollisionEvent::Phase::End, wall, crate) == 1);
    CHECK(pos_of(s.world, crate).x == doctest::Approx(1.5f).epsilon(0.01));
    s.events.clear();
    s.world.get<Transform>(wall)->position.x = 2.2f;  // back, 0.3 m into the crate: it is pushed out
    s.run(1);
    CHECK(s.awake(crate));
    CHECK(s.count(CollisionEvent::Phase::Begin, wall, crate) == 1);
    s.run(120);
    CHECK(pos_of(s.world, crate).x < 1.3f);
    CHECK(pos_of(s.world, crate).y == doctest::Approx(0.5f).epsilon(0.05));
    CHECK_FALSE(s.awake(crate));
}

// A crate resting on a static slab that gameplay moves by hand is carried with it (the slab teleports, its riders keep
// their place on it): the pair stays and the crate stays asleep.
TEST_CASE("3d integration: a static slab moved by hand carries a sleeping crate that lies on it") {
    Sim s;
    add_box(s.world, "floor", {0, -0.5f, 0}, {80, 1, 40}, false);
    Entity slab = add_box(s.world, "slab", {0, 3.0f, 0}, {6, 1, 6}, false);
    Entity crate = add_box(s.world, "crate", {0, 4.0f, 0}, {1, 1, 1}, true);
    s.run(120);
    REQUIRE_FALSE(s.awake(crate));
    s.world.get<Transform>(slab)->position = {10, 5.0f, 0};
    s.run(60);
    CHECK(pos_of(s.world, crate).x == doctest::Approx(10.0f).epsilon(0.02));
    CHECK(pos_of(s.world, crate).y == doctest::Approx(6.0f).epsilon(0.02));
    CHECK_FALSE(s.awake(crate));
}

// Three columns of three boxes sleep on a floor. The bottom box of the middle column is deleted: the indices of everything
// created after it shift by one, the pairs of the sleeping columns are renumbered, and nothing of the outer columns stirs.
TEST_CASE("3d integration: deleting a body renumbers the others without waking the sleeping columns") {
    Sim s;
    add_box(s.world, "floor", {0, -0.5f, 0}, {40, 1, 40}, false);
    std::vector<std::vector<Entity>> columns(3);
    for (int level = 0; level < 3; ++level)
        for (int c = 0; c < 3; ++c)
            columns[std::size_t(c)].push_back(add_box(s.world, ("c" + std::to_string(c) + "_" + std::to_string(level)).c_str(),
                                                      {-4.0f + 4.0f * float(c), 0.5f + float(level), 0}, {1, 1, 1}, true));
    s.run(150);
    for (const auto& col : columns)
        for (Entity e : col) REQUIRE_FALSE(s.awake(e));
    std::vector<Vec3> before;
    for (int c : {0, 2})
        for (Entity e : columns[std::size_t(c)]) before.push_back(pos_of(s.world, e));
    s.events.clear();
    s.world.destroy(columns[1][0]);
    s.run(1);
    // the two boxes above it lost their support: awake and falling
    CHECK(s.awake(columns[1][1]));
    CHECK(s.awake(columns[1][2]));
    s.run(120);
    CHECK(pos_of(s.world, columns[1][1]).y == doctest::Approx(0.5f).epsilon(0.1));
    CHECK(pos_of(s.world, columns[1][2]).y == doctest::Approx(1.5f).epsilon(0.1));
    // the outer columns never moved and never woke, and none of their pairs began or ended
    std::size_t k = 0;
    for (int c : {0, 2})
        for (Entity e : columns[std::size_t(c)]) {
            CHECK_FALSE(s.awake(e));
            CHECK(pos_of(s.world, e) == before[k++]);
        }
    for (const CollisionEvent& e : s.events)
        for (int c : {0, 2})
            for (Entity x : columns[std::size_t(c)]) CHECK_FALSE((e.a == x || e.b == x));
}

// After World::clear() a new entity can get the slot (and so the index) of an old one. The physics must not hand the
// newcomer the old body's velocity, sleep state or pairs.
TEST_CASE("3d integration: an entity slot reused after World::clear() starts a fresh body") {
    Sim s;
    add_box(s.world, "floor", {0, -0.5f, 0}, {40, 1, 40}, false);
    Entity ball = add_box(s.world, "old", {0, 10, 0}, {1, 1, 1}, true);
    s.run(30);  // falling at about 5 m/s
    REQUIRE(s.world.get<RigidBody3D>(ball)->velocity.y < -4.0f);
    s.world.clear();
    add_box(s.world, "floor2", {0, -0.5f, 0}, {40, 1, 40}, false);
    Entity fresh = add_box(s.world, "new", {0, 10, 0}, {1, 1, 1}, true);
    s.run(1);
    // one step of gravity from rest is 0.003 m: with the old velocity it would be 0.08 m
    CHECK(pos_of(s.world, fresh).y > 9.99f);
    CHECK(pos_of(s.world, fresh).y < 10.0f);
    CHECK(s.world.get<RigidBody3D>(fresh)->velocity.y > -0.3f);
    s.run(150);
    CHECK(pos_of(s.world, fresh).y == doctest::Approx(0.5f).epsilon(0.05));
    CHECK_FALSE(s.awake(fresh));
}

// Layers and masks decide which bodies meet. A body that rests asleep on a floor and whose mask is changed so that it no
// longer accepts the floor's layer falls through it (and the pair ends); a mask that accepts it again lets it rest.
TEST_CASE("3d integration: layers and masks changed at run time are honoured by sleeping and touching pairs") {
    Sim s;
    Entity floor = add_box(s.world, "floor", {0, -0.5f, 0}, {40, 1, 40}, false);
    s.world.get<Collider3D>(floor)->layer = 2;
    Entity ghost = add_box(s.world, "ghost", {0, 3, 0}, {1, 1, 1}, true);
    s.world.get<Collider3D>(ghost)->layer = 1;
    Entity solid = add_box(s.world, "solid", {5, 3, 0}, {1, 1, 1}, true);
    // dropped with a mask that skips the floor's layer: it falls through at once
    Entity blind = add_box(s.world, "blind", {-5, 3, 0}, {1, 1, 1}, true);
    s.world.get<Collider3D>(blind)->mask = -1 & ~(1 << 2);
    s.run(150);
    CHECK(pos_of(s.world, ghost).y == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(pos_of(s.world, solid).y == doctest::Approx(0.5f).epsilon(0.05));
    CHECK(pos_of(s.world, blind).y < -2.0f);
    REQUIRE_FALSE(s.awake(ghost));
    s.events.clear();
    s.world.get<Collider3D>(ghost)->mask = -1 & ~(1 << 2);  // the floor is no longer something it meets
    s.run(60);
    CHECK(s.awake(ghost));
    CHECK(pos_of(s.world, ghost).y < -1.0f);
    CHECK(s.count(CollisionEvent::Phase::End, floor, ghost) == 1);
    // the other crate, whose mask never changed, is still resting where it was
    CHECK(pos_of(s.world, solid).y == doctest::Approx(0.5f).epsilon(0.05));
    CHECK_FALSE(s.awake(solid));
}

// Movers the island search treats specially: a body whose reach (its farthest point from its centre) is more than 2 m.
TEST_CASE("3d integration: long capsules and boxes with a big reach land, rest on a pile and fall asleep") {
    Sim s;
    add_box(s.world, "floor", {0, -0.5f, 0}, {40, 1, 40}, false);
    // a pile of small boxes, and a long box and a long capsule dropped across it
    for (int i = 0; i < 6; ++i)
        add_box(s.world, ("p" + std::to_string(i)).c_str(), {-2.5f + float(i), 0.5f, 0}, {1, 1, 1}, true);
    Entity plank = add_box(s.world, "plank", {0, 2.0f, 0}, {7, 0.4f, 1.2f}, true);
    Entity pole = s.world.create("pole", "pole");
    s.world.get<Transform>(pole)->position = {0, 3.5f, 4};
    {
        Collider3D& c = s.world.add<Collider3D>(pole);
        c.shape = ColliderShape3D::Capsule;
        c.radius = 0.4f;
        c.height = 6.0f;
        s.world.get<Transform>(pole)->rotation = {0, 0, 90};  // lying along x, 3 m of reach each side
        s.world.add<RigidBody3D>(pole);
    }
    s.run(400);
    // the plank lies on top of the small boxes (their top is at y = 1), the capsule on the floor beside them
    CHECK(pos_of(s.world, plank).y == doctest::Approx(1.2f).epsilon(0.08));
    CHECK(pos_of(s.world, pole).y == doctest::Approx(0.4f).epsilon(0.15));
    CHECK(std::fabs(pos_of(s.world, pole).z - 4.0f) < 0.6f);
    CHECK_FALSE(s.awake(plank));
    CHECK_FALSE(s.awake(pole));
}

// A mesh collider whose origin is 8 m from its triangles: the body's centre (the box of the shape) is far from the entity.
TEST_CASE("3d integration: a mesh collider far from its entity origin is hit where its triangles are") {
    Sim s;
    Entity ground = s.world.create("ground", "ground");
    s.world.get<Transform>(ground)->scale = {6, 1, 6};
    {
        Collider3D& c = s.world.add<Collider3D>(ground);
        c.shape = ColliderShape3D::Mesh;
        c.mesh = "cube";
        c.offset = {8.0f / 6.0f, -0.5f, 0};  // (scaled with the entity) a 6 x 1 x 6 slab centred at x = 8, its top at y = 0
    }
    Entity on = add_box(s.world, "on", {8, 3, 0}, {1, 1, 1}, true);
    Entity off = add_box(s.world, "off", {0, 3, 0}, {1, 1, 1}, true);  // over the entity's origin: nothing there
    s.run(300);
    CHECK(pos_of(s.world, on).y == doctest::Approx(0.5f).epsilon(0.1));
    CHECK(pos_of(s.world, off).y < -3.0f);
    auto r = s.physics.raycast3d(s.world, {6, 5, 0}, {0, -1, 0}, 20.0f);  // beside the crate, over the slab
    REQUIRE(r.has_value());
    CHECK(std::fabs(r->point.y) < 0.01f);
    CHECK(r->entity == ground);
    CHECK_FALSE(s.physics.raycast3d(s.world, {0, 5, 4}, {0, -1, 0}, 20.0f).has_value());  // over the entity's origin
}

// A kinematic platform at 12 m/s moves 0.2 m per step, ten times the gap in which a body counts as lying on it. A crate and a
// character standing on it still travel with it.
TEST_CASE("3d integration: a fast platform carries a crate and a character beyond the rider gap") {
    Sim s;
    add_box(s.world, "floor", {0, -0.5f, 0}, {80, 1, 20}, false);
    Entity platform = add_box(s.world, "platform", {-10, 0.8f, 0}, {8, 0.4f, 4}, false);
    {
        RigidBody3D& rb = s.world.add<RigidBody3D>(platform);
        rb.type = BodyType::Kinematic;
        rb.velocity = {0, 0, 0};
    }
    Entity crate = add_box(s.world, "crate", {-12, 1.5f, 0}, {1, 1, 1}, true);
    Entity hero = s.world.create("hero", "hero");
    s.world.get<Transform>(hero)->position = {-8, 1.95f, 0};
    s.world.add<CharacterController3D>(hero);
    float vy = 0.0f;
    auto frame = [&]() {
        auto r = s.physics.move_character(s.world, hero, {0, vy * kDt, 0});
        REQUIRE(r.has_value());
        vy = r->isGrounded ? -0.5f : vy - 9.81f * kDt;
        s.run(1);
        return r->isGrounded;
    };
    for (int i = 0; i < 40; ++i) frame();  // everything settles on the standing platform
    REQUIRE(frame());
    const float crate0 = pos_of(s.world, crate).x, hero0 = pos_of(s.world, hero).x, plat0 = pos_of(s.world, platform).x;
    s.world.get<RigidBody3D>(platform)->velocity = {12, 0, 0};
    bool grounded = true;
    float worstCrate = 0.0f, worstHero = 0.0f;
    for (int i = 0; i < 40; ++i) {
        grounded = frame() && grounded;
        const float moved = pos_of(s.world, platform).x - plat0;
        worstCrate = std::max(worstCrate, std::fabs((pos_of(s.world, crate).x - crate0) - moved));
        worstHero = std::max(worstHero, std::fabs((pos_of(s.world, hero).x - hero0) - moved));
    }
    CHECK(pos_of(s.world, platform).x - plat0 == doctest::Approx(8.0f).epsilon(0.05));
    CHECK(worstCrate < 0.5f);
    CHECK(worstHero < 0.5f);
    CHECK(pos_of(s.world, crate).y == doctest::Approx(1.5f).epsilon(0.1));  // still on top of the platform
    CHECK(pos_of(s.world, hero).y > 1.5f);
}
