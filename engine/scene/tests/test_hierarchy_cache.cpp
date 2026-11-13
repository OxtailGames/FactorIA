// The hierarchy cache of World (world_matrix, world_position, active_in_hierarchy, pending_destroy): the answers must be the
// ones of a plain walk up the parent chain, whatever way the scene was written, and the cache must not move on a read.
#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <cstring>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

// The reference: no cache, the product from the root down, exactly what world_matrix is defined as.
Mat4 reference_matrix(const World& w, Entity e) {
    if (!w.alive(e)) return Mat4::identity();
    std::vector<Entity> chain;
    for (Entity cur = e; !cur.is_null(); cur = w.parent(cur)) chain.push_back(cur);
    Mat4 m;
    bool first = true;
    for (auto it = chain.rbegin(); it != chain.rend(); ++it) {
        const Transform* t = w.get<Transform>(*it);
        const Mat4 local = Mat4::trs(t->position, t->rotation, t->scale);
        m = first ? local : m * local;
        first = false;
    }
    return m;
}

bool reference_active(const World& w, Entity e) {
    if (!w.alive(e)) return false;
    for (Entity cur = e; !cur.is_null(); cur = w.parent(cur))
        if (!w.info(cur).active) return false;
    return true;
}

// `destroyed`: the entities destroy() ran on and flush() has not removed yet.
bool reference_pending(const World& w, const std::vector<Entity>& destroyed, Entity e) {
    if (!w.alive(e)) return false;
    for (Entity cur = e; !cur.is_null(); cur = w.parent(cur))
        if (std::find(destroyed.begin(), destroyed.end(), cur) != destroyed.end()) return true;
    return false;
}

bool same_bits(const Mat4& a, const Mat4& b) { return std::memcmp(a.m, b.m, sizeof a.m) == 0; }

// Compares every alive entity with the reference; returns how many answers differ.
int mismatches(const World& w, const std::vector<Entity>& all, const std::vector<Entity>& destroyed) {
    int bad = 0;
    for (Entity e : all) {
        if (!same_bits(w.world_matrix(e), reference_matrix(w, e))) ++bad;
        if (w.active_in_hierarchy(e) != reference_active(w, e)) ++bad;
        if (w.pending_destroy(e) != reference_pending(w, destroyed, e)) ++bad;
    }
    return bad;
}

void jitter(Transform& t, Rng& rng) {
    t.position = {rng.range(-50, 50), rng.range(-50, 50), rng.range(-5, 5)};
    t.rotation = {rng.range(-30, 30), rng.range(-90, 90), rng.range(-180, 180)};
    t.scale = {rng.range(0.5f, 2.0f), rng.range(0.5f, 2.0f), rng.range(0.5f, 2.0f)};
}

}  // namespace

TEST_CASE("hierarchy cache: the same answers as a walk up the chain after random writes by every path") {
    ensure_builtin_components();
    World w;
    Rng rng(20261113);
    std::vector<Entity> all, destroyed;
    const TypeInfo& tfType = World::type_of<Transform>();
    const TypeInfo& infoType = World::type_of<EntityInfo>();
    auto pick = [&]() { return all[rng.next_u32() % all.size()]; };
    auto make = [&](int parentChance) {
        Entity e = w.create();
        jitter(*w.get<Transform>(e), rng);
        if (!all.empty() && int(rng.next_u32() % 100) < parentChance) {
            Entity p = pick();
            if (w.alive(p) && !w.pending_destroy(p)) w.set_parent(e, p);
        }
        all.push_back(e);
        return e;
    };
    for (int i = 0; i < 200; ++i) make(85);
    REQUIRE(mismatches(w, all, destroyed) == 0);

    int checked = 0;
    for (int step = 0; step < 1500; ++step) {
        Entity e = pick();
        switch (rng.next_u32() % 14) {
            case 0:  // mutable get<T>
                if (w.alive(e)) w.get<Transform>(e)->position.x += rng.range(-3, 3);
                break;
            case 1:  // reflection: the type-erased get and a field written from JSON, as scripts and commands do
                if (w.alive(e)) {
                    void* t = w.get(e, tfType);
                    REQUIRE(field_from_json(*tfType.field("rotation"), t, Json::parse("[0, 10, 33]")).ok());
                }
                break;
            case 2: {  // each<Transform>: a callback that writes some of them
                const std::uint32_t mod = 2 + rng.next_u32() % 5;
                std::uint32_t n = 0;
                w.each<Transform>([&](Entity, Transform& t) {
                    if (n++ % mod == 0) t.scale.x += 0.01f;
                });
                break;
            }
            case 3:  // reparent, keeping the world pose or not, at a given place
                if (w.alive(e)) {
                    Entity p = (rng.next_u32() % 5 == 0) ? kNullEntity : pick();
                    if (w.check_set_parent(e, p).ok())
                        w.set_parent(e, p, rng.chance(0.5f), int(rng.next_u32() % 4) - 1);
                }
                break;
            case 4:
                w.set_world_position(e, {rng.range(-9, 9), rng.range(-9, 9), 0});
                break;
            case 5:
                w.set_active(e, rng.chance(0.6f));
                break;
            case 6:  // the mutable EntityInfo reference
                if (w.alive(e)) w.info(e).active = rng.chance(0.7f);
                break;
            case 7:  // reflection on EntityInfo
                if (w.alive(e)) {
                    void* inf = w.get(e, infoType);
                    REQUIRE(field_from_json(*infoType.field("active"), inf, Json(rng.chance(0.7f))).ok());
                }
                break;
            case 8: {  // each<EntityInfo>
                std::uint32_t n = 0;
                w.each<EntityInfo>([&](Entity, EntityInfo& i) {
                    if (n++ % 9 == 0) i.active = !i.active;
                });
                break;
            }
            case 9:  // add<Transform> hands out the existing one
                if (w.alive(e)) jitter(w.add<Transform>(e), rng);
                break;
            case 10:  // a new entity, parented or not
                make(70);
                break;
            case 11:  // a deferred destroy: the whole subtree is pending until the flush
                if (w.alive(e) && !w.pending_destroy(e) && all.size() > 40 && rng.chance(0.4f)) {
                    w.destroy(e);
                    destroyed.push_back(e);
                }
                break;
            case 12:
                if (rng.chance(0.5f)) {
                    w.flush();
                    destroyed.clear();
                }
                break;
            case 13:  // each<Sprite, Transform>: the walk starts from the smaller pool and reads the Transform with get
                if (w.alive(e) && !w.has<Sprite>(e)) w.add<Sprite>(e);
                w.each<Sprite, Transform>([&](Entity, Sprite&, Transform& t) { t.position.y += 0.5f; });
                break;
        }
        // Read a few entities after every write (so the cache is partly warm when the next write comes), all of them now
        // and then.
        for (int k = 0; k < 4; ++k) {
            Entity r = pick();
            CHECK(same_bits(w.world_matrix(r), reference_matrix(w, r)));
            CHECK(w.active_in_hierarchy(r) == reference_active(w, r));
        }
        if (step % 25 == 0) {
            REQUIRE(mismatches(w, all, destroyed) == 0);
            ++checked;
        }
    }
    w.flush();
    destroyed.clear();
    CHECK(mismatches(w, all, destroyed) == 0);
    CHECK(checked == 60);
}

TEST_CASE("hierarchy cache: reading through a const World never invalidates, a mutable access does") {
    ensure_builtin_components();
    World w;
    Entity root = w.create("root");
    Entity mid = w.create("mid");
    Entity leaf = w.create("leaf");
    w.set_parent(mid, root);
    w.set_parent(leaf, mid);
    w.get<Transform>(root)->position = {1, 2, 3};
    w.get<Transform>(mid)->position = {4, 0, 0};
    w.get<Transform>(leaf)->position = {0, 5, 0};

    const World& cw = w;
    const Mat4 first = cw.world_matrix(leaf);
    CHECK(cw.world_position(leaf).x == doctest::Approx(5.0f));
    const std::uint64_t version = cw.hierarchy_version();
    for (int i = 0; i < 100; ++i) {
        CHECK(same_bits(cw.world_matrix(leaf), first));
        CHECK(cw.active_in_hierarchy(leaf));
        const Transform* t = cw.get<Transform>(leaf);  // a const get is a read
        CHECK(t->position.y == doctest::Approx(5.0f));
        CHECK(cw.info(leaf).active);
    }
    CHECK(cw.hierarchy_version() == version);

    w.get<Transform>(mid)->position.x = 10;  // the mutable get is a write: the mid entry and the leaf below it go
    CHECK(cw.hierarchy_version() > version);
    CHECK(cw.world_position(leaf).x == doctest::Approx(11.0f));
    CHECK(cw.world_position(mid).x == doctest::Approx(11.0f));
    CHECK(cw.world_position(root).x == doctest::Approx(1.0f));

    // An entry that is already dropped does not count again.
    const std::uint64_t v2 = cw.hierarchy_version();
    w.get<Transform>(root)->position.x = 2;
    const std::uint64_t v3 = cw.hierarchy_version();
    CHECK(v3 > v2);
    w.get<Transform>(root)->position.x = 3;
    CHECK(cw.hierarchy_version() == v3);

    // Active: the leaf follows its ancestors, and a mutable info() is a write.
    CHECK(cw.active_in_hierarchy(leaf));
    w.set_active(root, false);
    CHECK_FALSE(cw.active_in_hierarchy(leaf));
    CHECK_FALSE(cw.active_in_hierarchy(mid));
    w.info(root).active = true;
    CHECK(cw.active_in_hierarchy(leaf));
    // Moving a branch under another parent changes both answers of the branch.
    Entity other = w.create("other");
    w.set_active(other, false);
    w.get<Transform>(other)->position = {100, 0, 0};
    CHECK(cw.world_position(leaf).x == doctest::Approx(3.0f + 10.0f));
    w.set_parent(mid, other);
    CHECK(cw.world_position(leaf).x == doctest::Approx(110.0f));
    CHECK_FALSE(cw.active_in_hierarchy(leaf));
    w.set_parent(mid, kNullEntity, true);  // keeping the world pose: the local transform changes, the world one does not
    CHECK(cw.world_position(leaf).x == doctest::Approx(110.0f));
    CHECK(cw.active_in_hierarchy(leaf));
}

TEST_CASE("hierarchy cache: an entity index that is reused starts with nothing cached") {
    ensure_builtin_components();
    World w;
    Entity parent = w.create("p");
    w.get<Transform>(parent)->position = {7, 0, 0};
    Entity a = w.create("a");
    w.set_parent(a, parent);
    w.set_active(parent, false);
    const World& cw = w;
    CHECK(cw.world_position(a).x == doctest::Approx(7.0f));
    CHECK_FALSE(cw.active_in_hierarchy(a));
    w.destroy(parent);
    CHECK(cw.pending_destroy(a));  // the child goes with its parent
    w.flush();
    CHECK_FALSE(cw.alive(a));
    Entity b = w.create("b");  // takes one of the freed indexes
    CHECK(cw.active_in_hierarchy(b));
    CHECK(cw.world_position(b).x == doctest::Approx(0.0f));
    CHECK_FALSE(cw.pending_destroy(b));
    CHECK(same_bits(cw.world_matrix(a), Mat4::identity()));  // a stale handle: identity, not the new entity's matrix
    CHECK_FALSE(cw.active_in_hierarchy(a));
}

TEST_CASE("hierarchy cache: several threads reading an empty cache get the reference answers") {
    ensure_builtin_components();
    World w;
    Rng rng(77);
    std::vector<Entity> all;
    for (int i = 0; i < 3000; ++i) {
        Entity e = w.create();
        jitter(*w.get<Transform>(e), rng);
        if (i > 0 && rng.chance(0.9f)) w.set_parent(e, all[rng.next_u32() % std::uint32_t(all.size())]);
        w.set_active(e, rng.chance(0.9f));
        all.push_back(e);
    }
    std::vector<Mat4> expected;
    std::vector<char> expectedActive;
    for (Entity e : all) {
        expected.push_back(reference_matrix(w, e));
        expectedActive.push_back(reference_active(w, e));
    }
    for (int round = 0; round < 4; ++round) {
        // Drop everything the cache holds (a write to every Transform and EntityInfo), then read from workers.
        w.each<Transform>([](Entity, Transform&) {});
        w.each<EntityInfo>([](Entity, EntityInfo&) {});
        jobs::Settings s = round == 0 ? jobs::Settings::inline_jobs() : jobs::Settings::threads(round == 1 ? 2 : 6);
        REQUIRE(jobs::start(s).ok());
        std::atomic<int> bad{0};
        const World& cw = w;
        auto r = jobs::parallel_for("test.hierarchy_read", all.size(), 64, [&](const jobs::Chunk& c) {
            for (std::size_t i = c.begin; i < c.end; ++i) {
                // The deepest entities first in some chunks, so the threads fill overlapping chains.
                const std::size_t k = (c.index % 2) ? all.size() - 1 - i : i;
                if (!same_bits(cw.world_matrix(all[k]), expected[k])) bad.fetch_add(1);
                if (cw.active_in_hierarchy(all[k]) != (expectedActive[k] != 0)) bad.fetch_add(1);
            }
        });
        jobs::stop();
        CHECK(r.ok());
        CHECK(bad.load() == 0);
    }
}
