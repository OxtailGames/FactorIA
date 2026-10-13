#include <doctest.h>

#include "fa/scene/world.h"

using namespace fa;

TEST_CASE("world: create gives EntityInfo, Transform and unique ids") {
    World w;
    Entity a = w.create("Player", "player");
    Entity b = w.create("Other", "player");
    Entity c = w.create();
    Entity d = w.create("Named");
    CHECK(w.id_of(a) == "player");
    CHECK(w.id_of(b) == "player_2");
    CHECK(w.id_of(c) == "e1");
    CHECK(w.id_of(d) == "e2");
    CHECK(w.has<Transform>(a));
    CHECK(w.has<EntityInfo>(a));
    CHECK(w.info(a).name == "Player");
    CHECK(w.entity_count() == 4);
    CHECK(w.find("player") == a);
    CHECK(w.find("Named") == d);
    CHECK(w.find("nothing").is_null());
    CHECK(w.find_all_by_name("Other").size() == 1);
    w.info(a).tags = {"hero", "x"};
    w.info(c).tags = {"x"};
    CHECK(w.find_by_tag("x").size() == 2);
    CHECK(w.find_by_tag("x")[0] == a);
    CHECK(w.has_tag(a, "hero"));
    CHECK(!w.has_tag(b, "hero"));

    CHECK(!w.set_id(a, "player_2").ok());
    CHECK(w.set_id(a, "hero").ok());
    CHECK(w.find_by_id("hero") == a);
    CHECK(w.find_by_id("player").is_null());
    CHECK(!w.set_id(a, "").ok());
}

TEST_CASE("world: typed components") {
    World w;
    Entity e = w.create();
    CHECK(!w.has<Sprite>(e));
    Sprite& s = w.add<Sprite>(e);
    s.layer = 4;
    CHECK(w.get<Sprite>(e)->layer == 4);
    CHECK(&w.add<Sprite>(e) == &s);  // add returns the existing one
    w.set(e, Camera{});
    CHECK(w.has<Camera>(e));
    w.remove<Sprite>(e);
    CHECK(!w.has<Sprite>(e));
    w.remove<Transform>(e);  // refused
    CHECK(w.has<Transform>(e));
    const World& cw = w;
    CHECK(cw.get<Camera>(e) != nullptr);
}

TEST_CASE("world: components_of is in registration order") {
    World w;
    Entity e = w.create();
    w.add<Light>(e);  // added first, but registered after Sprite
    w.add<Sprite>(e);
    auto types = w.components_of(e);
    REQUIRE(types.size() == 4);
    CHECK(types[0]->name == "EntityInfo");
    CHECK(types[1]->name == "Transform");
    CHECK(types[2]->name == "Sprite");
    CHECK(types[3]->name == "Light");
}

TEST_CASE("world: component pointers stay stable while adding many") {
    World w;
    Entity first = w.create();
    Sprite* p = &w.add<Sprite>(first);
    p->layer = 77;
    Transform* t = w.get<Transform>(first);
    for (int i = 0; i < 1000; ++i) {
        Entity e = w.create();
        w.add<Sprite>(e).layer = i;
        w.add<Camera>(e);
    }
    CHECK(w.get<Sprite>(first) == p);
    CHECK(w.get<Transform>(first) == t);
    CHECK(p->layer == 77);
    CHECK(w.entity_count() == 1001);
}

TEST_CASE("world: iteration order is deterministic insertion order") {
    World w;
    std::vector<Entity> es;
    for (int i = 0; i < 10; ++i) es.push_back(w.create());
    for (int i : {5, 2, 8, 0}) w.add<Sprite>(es[i]);
    std::vector<Entity> seen;
    w.each<Sprite>([&](Entity e, Sprite&) { seen.push_back(e); });
    REQUIRE(seen.size() == 4);
    CHECK(seen[0] == es[5]);
    CHECK(seen[1] == es[2]);
    CHECK(seen[2] == es[8]);
    CHECK(seen[3] == es[0]);

    // Removing and re-adding must not reorder the others; the re-added goes last.
    w.remove<Sprite>(es[2]);
    w.add<Sprite>(es[2]);
    seen.clear();
    w.each<Sprite>([&](Entity e, Sprite&) { seen.push_back(e); });
    CHECK(seen == std::vector<Entity>{es[5], es[8], es[0], es[2]});

    // Many removals trigger compaction; order is preserved.
    World big;
    std::vector<Entity> v;
    for (int i = 0; i < 400; ++i) { v.push_back(big.create()); big.add<Sprite>(v.back()); }
    for (int i = 0; i < 400; ++i) if (i % 3 != 0) big.remove<Sprite>(v[i]);
    auto list = big.entities_with(&World::type_of<Sprite>());
    REQUIRE(list.size() == 134);
    for (std::size_t i = 0; i < list.size(); ++i) CHECK(list[i] == v[i * 3]);
}

TEST_CASE("world: each with several components and safe mutation") {
    World w;
    Entity a = w.create(), b = w.create(), c = w.create();
    w.add<Sprite>(a); w.add<Sprite>(b); w.add<Sprite>(c);
    w.add<Camera>(a); w.add<Camera>(c);
    int n = 0;
    w.each<Sprite, Camera>([&](Entity e, Sprite&, Camera&) {
        ++n;
        w.destroy(e);        // deferred: safe while iterating
        w.remove<Camera>(c); // removing others: safe, they are skipped
    });
    CHECK(n == 1);
    CHECK(w.entity_count() == 3);
    w.flush();
    CHECK(w.entity_count() == 2);
}

TEST_CASE("world: deferred destroy takes children along and notifies observers") {
    World w;
    Entity root = w.create("root", "root");
    Entity kid = w.create("kid", "kid");
    Entity grandkid = w.create("grandkid", "grandkid");
    Entity other = w.create("other");
    w.set_parent(kid, root);
    w.set_parent(grandkid, kid);
    w.add<Sprite>(grandkid);

    std::vector<std::string> destroyed;
    int obs = w.on_destroy([&](Entity e) {
        CHECK(w.alive(e));  // still intact when observers run
        destroyed.push_back(w.id_of(e));
    });
    w.destroy(root);
    CHECK(w.alive(root));
    CHECK(w.pending_destroy(root));
    CHECK(w.pending_destroy(kid));  // inherited
    CHECK(!w.pending_destroy(other));
    w.destroy(root);  // idempotent
    w.flush();
    CHECK(!w.alive(root));
    CHECK(!w.alive(kid));
    CHECK(!w.alive(grandkid));
    CHECK(w.alive(other));
    CHECK(destroyed.size() == 3);
    CHECK(w.entity_count() == 1);
    CHECK(w.find_by_id("kid").is_null());
    CHECK(w.entities_with(&World::type_of<Sprite>()).empty());

    // Stale handles stay dead after slot reuse.
    Entity fresh = w.create();
    CHECK(w.alive(fresh));
    CHECK(!w.alive(root));
    CHECK(w.get<Transform>(root) == nullptr);
    CHECK(w.id_of(fresh) == "e2");  // auto ids keep counting (e1 is "other")

    w.remove_observer(obs);
    w.destroy_immediate(fresh);
    CHECK(destroyed.size() == 3);
}

TEST_CASE("world: destroying a child detaches it from the parent") {
    World w;
    Entity p = w.create(), c1 = w.create(), c2 = w.create();
    w.set_parent(c1, p);
    w.set_parent(c2, p);
    w.destroy(c1);
    w.flush();
    REQUIRE(w.children(p).size() == 1);
    CHECK(w.children(p)[0] == c2);
}

TEST_CASE("world: hierarchy matrices and parenting") {
    World w;
    Entity p = w.create(), c = w.create();
    w.get<Transform>(p)->position = {10, 0, 0};
    w.get<Transform>(p)->rotation = {0, 0, 90};
    w.get<Transform>(p)->scale = {2, 2, 2};
    w.get<Transform>(c)->position = {1, 0, 0};
    w.set_parent(c, p);
    CHECK(w.parent(c) == p);
    CHECK(w.is_ancestor(p, c));
    CHECK(!w.is_ancestor(c, p));
    CHECK(w.roots() == std::vector<Entity>{p});
    // child local (1,0,0): scale 2 -> (2,0,0), roll 90 -> (0,2,0), + (10,0,0)
    Vec3 pos = w.world_position(c);
    CHECK(approx_equal(pos.x, 10.0f));
    CHECK(approx_equal(pos.y, 2.0f));
    Mat4 expected = w.world_matrix(p) * Mat4::trs({1, 0, 0}, {0, 0, 0}, {1, 1, 1});
    for (int i = 0; i < 16; ++i) CHECK(approx_equal(w.world_matrix(c).m[i], expected.m[i]));

    w.set_world_position(c, {0, 0, 0});
    CHECK(approx_equal(w.world_position(c).x, 0.0f, 1e-3f));
    CHECK(approx_equal(w.world_position(c).y, 0.0f, 1e-3f));
    Vec3 local = w.get<Transform>(c)->position;  // (-10,0,0) un-rotated by 90 deg, divided by scale 2
    CHECK(approx_equal(local.x, 0.0f, 1e-3f));
    CHECK(approx_equal(local.y, 5.0f, 1e-3f));

    // cycles are refused
    w.set_parent(p, c);
    CHECK(w.parent(p).is_null());
    w.set_parent(p, p);
    CHECK(w.parent(p).is_null());
}

TEST_CASE("world: set_parent keepWorldTransform preserves the world pose") {
    World w;
    Entity p = w.create(), c = w.create();
    w.get<Transform>(p)->position = {5, 1, -2};
    w.get<Transform>(p)->rotation = {0, 90, 0};
    w.get<Transform>(p)->scale = {2, 2, 2};
    w.get<Transform>(c)->position = {3, 4, 5};
    w.get<Transform>(c)->rotation = {10, 20, 30};
    w.get<Transform>(c)->scale = {1, 2, 3};
    Mat4 before = w.world_matrix(c);
    w.set_parent(c, p, true);
    Mat4 after = w.world_matrix(c);
    for (int i = 0; i < 16; ++i) CHECK(approx_equal(before.m[i], after.m[i], 1e-3f));
    w.set_parent(c, kNullEntity, true);
    CHECK(w.parent(c).is_null());
    Mat4 back = w.world_matrix(c);
    for (int i = 0; i < 16; ++i) CHECK(approx_equal(before.m[i], back.m[i], 1e-3f));

    // Without keepWorldTransform the local transform is kept.
    w.set_parent(c, p, false);
    CHECK(w.get<Transform>(c)->position == Vec3{3, 4, 5});
}

TEST_CASE("world: active in hierarchy") {
    World w;
    Entity p = w.create(), c = w.create();
    w.set_parent(c, p);
    CHECK(w.active_in_hierarchy(c));
    w.set_active(p, false);
    CHECK(!w.active_in_hierarchy(c));
    CHECK(w.info(c).active);
    w.set_active(p, true);
    CHECK(w.active_in_hierarchy(c));
}

TEST_CASE("world: clear resets everything") {
    World w;
    Entity e = w.create("a", "a");
    w.add<Sprite>(e);
    w.settings().fogDensity = 1.0f;
    w.clear();
    CHECK(w.entity_count() == 0);
    CHECK(!w.alive(e));
    CHECK(w.settings().fogDensity == 0.0f);
    Entity f = w.create("a", "a");
    CHECK(w.id_of(f) == "a");
    CHECK(w.entities().size() == 1);
}

TEST_CASE("world: clock and rng are deterministic") {
    World a, b;
    for (int i = 0; i < 5; ++i) CHECK(a.rng().next_u32() == b.rng().next_u32());
    a.advance_clock(0.5);
    CHECK(a.frame() == 1);
    CHECK(a.time() == doctest::Approx(0.5));
    a.reset_clock();
    CHECK(a.frame() == 0);
}
