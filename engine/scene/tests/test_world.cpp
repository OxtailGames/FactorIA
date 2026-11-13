#include <doctest.h>

#include <algorithm>
#include <vector>

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
    for (int i = 0; i < 400; ++i) {
        v.push_back(big.create());
        big.add<Sprite>(v.back());
    }
    for (int i = 0; i < 400; ++i)
        if (i % 3 != 0) big.remove<Sprite>(v[i]);
    auto list = big.entities_with(&World::type_of<Sprite>());
    REQUIRE(list.size() == 134);
    for (std::size_t i = 0; i < list.size(); ++i) CHECK(list[i] == v[i * 3]);
}

TEST_CASE("world: each with several components and safe mutation") {
    World w;
    Entity a = w.create(), b = w.create(), c = w.create();
    w.add<Sprite>(a);
    w.add<Sprite>(b);
    w.add<Sprite>(c);
    w.add<Camera>(a);
    w.add<Camera>(c);
    int n = 0;
    w.each<Sprite, Camera>([&](Entity e, Sprite&, Camera&) {
        ++n;
        w.destroy(e);         // deferred: safe while iterating
        w.remove<Camera>(c);  // removing others: safe, they are skipped
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

TEST_CASE("world: destroy() hides the entity from lookups and frees its id immediately") {
    World w;
    Entity gem = w.create("Gem", "gem_1");
    w.info(gem).tags = {"gem"};
    Entity kid = w.create("GemKid", "gem_kid");
    w.info(kid).tags = {"gem"};
    w.set_parent(kid, gem);
    Entity keep = w.create("Gem", "keep");
    w.info(keep).tags = {"gem"};

    w.destroy(gem);
    CHECK(w.alive(gem));  // memory lives until flush()
    CHECK(w.find_by_id("gem_1").is_null());
    CHECK(w.find_by_id("gem_kid").is_null());  // children go with the parent
    CHECK(w.find("gem_1").is_null());
    CHECK(w.find("Gem") == keep);  // by name: skips the destroyed one
    CHECK(w.find_all_by_name("Gem").size() == 1);
    CHECK(w.find_by_tag("gem") == std::vector<Entity>{keep});

    // The id is reusable at once, unchanged (no "gem_1_2").
    Entity again = w.create("Gem", "gem_1");
    CHECK(w.id_of(again) == "gem_1");
    CHECK(w.find_by_id("gem_1") == again);
    CHECK(w.id_of(gem) == "gem_1");  // the old (pending) entity still reads fine

    w.flush();
    CHECK(!w.alive(gem));
    CHECK(w.find_by_id("gem_1") == again);  // flushing the old one must not unregister the new owner
    CHECK(w.find_by_id("keep") == keep);
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

TEST_CASE("world: count and any follow entities_with through add, remove, destroy and clear") {
    World w;
    const TypeInfo* sprite = &World::type_of<Sprite>();
    CHECK(w.count<Sprite>() == 0);
    CHECK(!w.any<Sprite>());
    CHECK(w.count(nullptr) == 0);
    CHECK(!w.any(nullptr));

    Entity a = w.create("a", "a");
    Entity b = w.create("b", "b");
    Entity c = w.create("c", "c");
    w.add<Sprite>(a);
    w.add<Sprite>(b);
    w.add<Sprite>(c);
    w.add<Sprite>(a);  // already there: not counted twice
    CHECK(w.count<Sprite>() == 3);
    CHECK(w.any<Sprite>());
    CHECK(w.count(sprite) == w.entities_with(sprite).size());

    // Removing leaves a tombstone in the pool; it is not counted.
    w.remove<Sprite>(b);
    CHECK(w.count<Sprite>() == 2);
    CHECK(w.count(sprite) == w.entities_with(sprite).size());
    w.remove<Sprite>(b);  // nothing to remove
    CHECK(w.count<Sprite>() == 2);

    // A deferred destroy still counts (as in entities_with) until flush().
    w.destroy(a);
    CHECK(w.count<Sprite>() == 2);
    CHECK(w.count(sprite) == w.entities_with(sprite).size());
    w.flush();
    CHECK(w.count<Sprite>() == 1);
    CHECK(w.count(sprite) == w.entities_with(sprite).size());
    w.destroy(c);
    w.flush();
    CHECK(w.count<Sprite>() == 0);
    CHECK(!w.any<Sprite>());

    // Many adds and removes (the pool compacts its tombstones).
    std::vector<Entity> many;
    for (int i = 0; i < 500; ++i) many.push_back(w.create());
    for (Entity e : many) w.add<Sprite>(e);
    for (std::size_t i = 0; i < many.size(); i += 2) w.remove<Sprite>(many[i]);
    CHECK(w.count<Sprite>() == 250);
    CHECK(w.entities_with(sprite).size() == 250);

    w.clear();
    CHECK(w.count<Sprite>() == 0);
    CHECK(!w.any<Sprite>());
    w.add<Sprite>(w.create());
    CHECK(w.count<Sprite>() == 1);
    CHECK(w.count<Transform>() == w.entity_count());
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

TEST_CASE("tooltip settings: factoria.json \"ui\" keys are read and every mistake says where and what to write") {
    auto ok = parse_tooltip_settings(Json::parse(R"({"tooltipDelay":0.4,"tooltipOnTouch":true,
        "tooltip":{"color":"#102030","fontSize":16,"maxWidth":280,"padding":[6,4,6,4],"layer":500}})"),
                                     "factoria.json#/ui");
    REQUIRE_MESSAGE(ok.ok(), (ok.ok() ? std::string() : ok.error().to_string()));
    CHECK(ok->delay == doctest::Approx(0.4f));
    CHECK(ok->onTouch);
    CHECK(ok->style.fontSize == doctest::Approx(16.0f));
    CHECK(ok->style.maxWidth == doctest::Approx(280.0f));
    CHECK(ok->style.padding.x == doctest::Approx(6.0f));
    CHECK(ok->style.layer == 500);
    CHECK(parse_tooltip_settings(Json::object(), "x").value() == UiTooltipSettings{});  // nothing set: the defaults
    auto bad = parse_tooltip_settings(Json::parse(R"({"tooltipDelay":-1})"), "factoria.json#/ui");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("/ui/tooltipDelay") != std::string::npos);
    CHECK_FALSE(bad.error().hint.empty());
    auto typo = parse_tooltip_settings(Json::parse(R"({"tooltip":{"fontsize":16}})"), "factoria.json#/ui");
    REQUIRE_FALSE(typo.ok());
    CHECK(typo.error().message.find("fontSize") != std::string::npos);  // did you mean
    CHECK_FALSE(parse_tooltip_settings(Json::parse(R"({"tooltip":{"maxWidth":"wide"}})"), "x").ok());
    CHECK_FALSE(parse_tooltip_settings(Json::parse(R"({"tooltip":5})"), "x").ok());
}

TEST_CASE("world: an entity being destroyed refuses a new parent, a new child and a new id") {
    World w;
    Entity root = w.create("Root", "root");
    Entity kid = w.create("Kid", "kid");
    w.set_parent(kid, root);
    Entity safe = w.create("Safe", "safe");
    Entity other = w.create("Other", "other");
    w.destroy(root);

    // The entity itself, and a child of it (its subtree is already unregistered), cannot move out.
    auto moveRoot = w.check_set_parent(root, safe);
    REQUIRE_FALSE(moveRoot.ok());
    CHECK(moveRoot.error().message.find("being destroyed") != std::string::npos);
    CHECK_FALSE(moveRoot.error().hint.empty());
    CHECK_FALSE(w.check_set_parent(kid, safe).ok());
    CHECK_FALSE(w.check_set_parent(kid, kNullEntity).ok());
    // Nobody can be put under the destroyed entity or under one of its children.
    auto under = w.check_set_parent(safe, root);
    REQUIRE_FALSE(under.ok());
    CHECK(under.error().message.find("'root'") != std::string::npos);
    CHECK_FALSE(w.check_set_parent(safe, kid).ok());
    CHECK(w.check_set_parent(safe, other).ok());  // unrelated entities still move

    // set_parent changes nothing when refused.
    w.set_parent(kid, safe);
    CHECK(w.parent(kid) == root);
    w.set_parent(safe, root);
    CHECK(w.parent(safe).is_null());
    CHECK(w.children(root) == std::vector<Entity>{kid});

    // A pending entity does not take a new id; the id of a live one is unaffected.
    auto rename = w.set_id(kid, "kid_2");
    REQUIRE_FALSE(rename.ok());
    CHECK(rename.error().message.find("being destroyed") != std::string::npos);
    CHECK(w.id_of(kid) == "kid");
    CHECK(w.set_id(safe, "safe_2").ok());
    CHECK(w.find_by_id("safe_2") == safe);

    // The lookup table never holds an id of the destroyed subtree, and after the flush the ids are free.
    CHECK(w.find_by_id("root").is_null());
    CHECK(w.find_by_id("kid").is_null());
    w.flush();
    CHECK_FALSE(w.alive(root));
    CHECK_FALSE(w.alive(kid));
    CHECK(w.id_of(w.create("Again", "kid")) == "kid");
    CHECK(w.find_by_id("safe_2") == safe);
}

namespace {
std::vector<Entity> make_sprites(World& w, int n) {
    std::vector<Entity> out;
    for (int i = 0; i < n; ++i) {
        out.push_back(w.create());
        w.add<Sprite>(out.back());
    }
    return out;
}
}  // namespace

TEST_CASE("world each: walks the pool with the fewest owners, in that pool's insertion order") {
    World w;
    const std::vector<Entity> es = make_sprites(w, 10);
    w.add<Collider2D>(es[7]);
    w.add<Collider2D>(es[3]);
    w.add<Collider2D>(es[9]);

    std::vector<Entity> seen;
    w.each<Sprite, Collider2D>([&](Entity e, Sprite&, Collider2D&) { seen.push_back(e); });
    CHECK(seen == std::vector<Entity>{es[7], es[3], es[9]});  // the colliders' order, not the sprites'
    seen.clear();
    w.each<Collider2D, Sprite>([&](Entity e, Collider2D&, Sprite&) { seen.push_back(e); });
    CHECK(seen == std::vector<Entity>{es[7], es[3], es[9]});

    // The references are the components of the entity, whichever pool drives.
    w.get<Sprite>(es[3])->color.a = 0.5f;
    w.each<Sprite, Collider2D>([&](Entity e, Sprite& s, Collider2D& c) {
        CHECK(&s == w.get<Sprite>(e));
        CHECK(&c == w.get<Collider2D>(e));
    });

    // The same count: the first type drives.
    for (Entity e : es) w.add<Camera>(e);
    seen.clear();
    w.each<Camera, Sprite>([&](Entity e, Camera&, Sprite&) { seen.push_back(e); });
    CHECK(seen == es);

    // A type nobody owns: nothing runs.
    int calls = 0;
    w.each<Sprite, Bone2D>([&](Entity, Sprite&, Bone2D&) { ++calls; });
    CHECK(calls == 0);
}

TEST_CASE("world each: removing components during the walk skips the owners that lost them") {
    World w;
    const std::vector<Entity> es = make_sprites(w, 6);
    for (Entity e : es) w.add<Camera>(e);

    std::vector<Entity> seen;
    w.each<Sprite, Camera>([&](Entity e, Sprite&, Camera&) {
        seen.push_back(e);
        if (e == es[0]) {
            w.remove<Sprite>(es[2]);  // the driving type (Sprite and Camera tie: Sprite drives)
            w.remove<Camera>(es[3]);  // the other one
            w.remove<Sprite>(es[0]);  // its own, after the fact
        }
    });
    CHECK(seen == std::vector<Entity>{es[0], es[1], es[4], es[5]});
    CHECK(w.count<Sprite>() == 4);
    CHECK(w.count<Camera>() == 5);
}

TEST_CASE("world each: entities that gain the driving component during the walk are not visited") {
    World w;
    const std::vector<Entity> es = make_sprites(w, 4);
    std::vector<Entity> added;
    std::vector<Entity> seen;
    w.each<Sprite>([&](Entity e, Sprite&) {
        seen.push_back(e);
        Entity n = w.create();
        w.add<Sprite>(n);
        added.push_back(n);
    });
    CHECK(seen == es);
    CHECK(added.size() == 4);
    CHECK(w.count<Sprite>() == 8);

    // Removed and added again: a new entry at the end, so it is not visited twice.
    seen.clear();
    w.each<Sprite>([&](Entity e, Sprite&) {
        seen.push_back(e);
        if (e == es[1]) {
            w.remove<Sprite>(es[1]);
            w.add<Sprite>(es[1]);
        }
    });
    CHECK(seen.size() == 8);
    CHECK(std::count(seen.begin(), seen.end(), es[1]) == 1);
    CHECK(w.entities_with(&World::type_of<Sprite>()).back() == es[1]);

    // Another type gaining the component of the other Ts: visited when its turn comes with all of them.
    World v;
    const std::vector<Entity> vs = make_sprites(v, 3);
    v.add<Camera>(vs[0]);
    v.add<Camera>(vs[1]);
    v.add<Camera>(vs[2]);
    std::vector<Entity> got;
    v.each<Camera, Sprite>([&](Entity e, Camera&, Sprite&) { got.push_back(e); });
    CHECK(got == vs);
}

TEST_CASE("world each: destroy inside the walk is deferred and the walk finishes") {
    World w;
    const std::vector<Entity> es = make_sprites(w, 5);
    std::vector<Entity> seen;
    w.each<Sprite>([&](Entity e, Sprite&) {
        seen.push_back(e);
        w.destroy(es[4 - (seen.size() - 1)]);  // the current one, then the ones ahead
    });
    CHECK(seen.size() == 5);  // destroy() is deferred: everything still alive when its turn comes
    w.flush();
    CHECK(w.count<Sprite>() == 0);
    int calls = 0;
    w.each<Sprite>([&](Entity, Sprite&) { ++calls; });
    CHECK(calls == 0);
}

TEST_CASE("world each: a nested walk over the same type sees every pair, and removals in it are safe") {
    World w;
    const std::vector<Entity> es = make_sprites(w, 20);
    int pairs = 0;
    w.each<Sprite>([&](Entity, Sprite&) { w.each<Sprite>([&](Entity, Sprite&) { ++pairs; }); });
    CHECK(pairs == 400);

    // The inner walk removes the sprites of the entities behind it: the outer one skips them afterwards.
    int outer = 0;
    w.each<Sprite>([&](Entity e, Sprite&) {
        ++outer;
        w.each<Sprite>([&](Entity inner, Sprite&) {
            if (inner != e && inner.index % 2 == 0) w.remove<Sprite>(inner);
        });
    });
    CHECK(outer >= 10);
    CHECK(outer < 20);
    for (Entity e : w.entities_with(&World::type_of<Sprite>())) CHECK(w.get<Sprite>(e) != nullptr);
}

TEST_CASE("world each: the pool does not compact in the middle of a walk, and does when it ends") {
    World w;
    const std::vector<Entity> es = make_sprites(w, 400);
    std::vector<Entity> seen;
    w.each<Sprite>([&](Entity e, Sprite&) {
        seen.push_back(e);
        if (e == es[0])
            for (std::size_t i = 1; i < 300; ++i) w.remove<Sprite>(es[i]);  // far past the compaction threshold
        if (e == es[350]) {
            // Adding and removing after the tombstones piled up: positions must still be right.
            for (std::size_t i = 100; i < 150; ++i) w.add<Sprite>(es[i]);
            w.remove<Sprite>(es[399]);
        }
    });
    std::vector<Entity> expected{es[0]};
    for (std::size_t i = 300; i < 399; ++i) expected.push_back(es[i]);
    CHECK(seen == expected);  // not es[399] (removed before its turn), not the re-added es[100..149]

    // Compacted by now: the order is the insertion order and every owner resolves.
    std::vector<Entity> expectedAll{es[0]};
    for (std::size_t i = 300; i < 399; ++i) expectedAll.push_back(es[i]);
    for (std::size_t i = 100; i < 150; ++i) expectedAll.push_back(es[i]);
    CHECK(w.entities_with(&World::type_of<Sprite>()) == expectedAll);
    CHECK(w.count<Sprite>() == expectedAll.size());
    for (Entity e : expectedAll) CHECK(w.get<Sprite>(e) != nullptr);
    w.remove<Sprite>(es[0]);
    CHECK(w.get<Sprite>(es[0]) == nullptr);
    CHECK(w.count<Sprite>() == expectedAll.size() - 1);
}

TEST_CASE("world each: clear() inside the walk ends it") {
    World w;
    make_sprites(w, 5);
    int calls = 0;
    w.each<Sprite>([&](Entity, Sprite&) {
        ++calls;
        w.clear();
        make_sprites(w, 5);  // new owners at the positions the walk would reach
    });
    CHECK(calls == 1);
    CHECK(w.count<Sprite>() == 5);
}
