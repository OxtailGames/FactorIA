// M95.2: the sort keys of the opaque meshes (mesh_batch.h, SortKeyTable). No GPU: items are built by hand. The keys
// must give the order and the batches the old comparator gave, whatever the job threads, and fall back to it when a
// field has more values than its bits hold.
#include "test_util.h"

#include <algorithm>
#include <deque>
#include <string>
#include <vector>

#include "fa/core/jobs.h"

#include "mesh_batch.h"

using namespace fa;
using namespace fa::render;

namespace {

struct Pool {
    std::deque<MeshAsset> meshes;
    std::deque<TextureAsset> textures;
    std::deque<MaterialAsset> materials;
    std::deque<MeshRenderer> renderers;
    std::deque<Animator> animators;
};

std::uint32_t next(std::uint32_t& s) {
    s = s * 1664525u + 1013904223u;
    return s >> 8;
}

// Items drawn at random from a few meshes, textures, materials and colours, some skinned, some flashing, some with
// override hashes. The names are given out of order, so a name order and an creation order differ.
std::vector<MeshItem> random_items(Pool& pool, std::uint32_t seed, int count, int names) {
    std::uint32_t s = seed;
    for (int i = 0; i < names; ++i) {
        pool.meshes.emplace_back().key = "mesh" + std::to_string((i * 7) % names);
        pool.textures.emplace_back().path = "tex" + std::to_string((i * 5) % names);
        pool.materials.emplace_back().path = "mat" + std::to_string((i * 3) % names);
    }
    std::vector<MeshItem> items(static_cast<std::size_t>(count));
    for (int i = 0; i < count; ++i) {
        MeshItem& it = items[std::size_t(i)];
        MeshRenderer& r = pool.renderers.emplace_back();
        r.color = Color{float(next(s) % 3) / 2, float(next(s) % 2), 0.5f, next(s) % 4 ? 1.0f : 0.5f};
        r.metallic = float(next(s) % 3) / 2;
        r.roughness = float(next(s) % 2);
        r.unlit = next(s) % 5 == 0;
        r.receiveShadows = next(s) % 7 != 0;
        r.uvScale = {1.0f + float(next(s) % 2), 1.0f};
        it.mr = &r;
        it.entity = Entity::from_bits(std::uint64_t(i + 1));
        it.mesh = &pool.meshes[next(s) % std::uint32_t(names)];
        if (next(s) % 3) it.tex = &pool.textures[next(s) % std::uint32_t(names)];
        if (next(s) % 4 == 0) it.normalTex = &pool.textures[next(s) % std::uint32_t(names)];
        if (next(s) % 3 == 0) it.material = &pool.materials[next(s) % std::uint32_t(names)];
        if (next(s) % 6 == 0) it.anim = &pool.animators.emplace_back();  // an Animator belongs to one entity
        it.paramsHash = next(s) % 5 == 0 ? next(s) % 3 + 1 : 0;
        it.colorsHash = next(s) % 9 == 0 ? next(s) % 2 + 1 : 0;
        if (next(s) % 11 == 0) it.flash = Color{1, 1, 1, 0.5f};
        it.visible = next(s) % 5 != 0;
        it.casts = next(s) % 3 == 0;
    }
    return items;
}

bool key_all(std::vector<MeshItem>& items, SortKeyTable& table) {
    std::vector<SortFields> fields;
    for (const MeshItem& m : items) fields.push_back(fields_of(m));
    std::vector<std::uint64_t> keys;
    const bool ok = table.build(fields, {}, keys);
    for (std::size_t i = 0; i < items.size(); ++i) {
        items[i].keyed = ok;
        items[i].sortKey = ok ? keys[i] : 0;
    }
    return ok;
}

struct Batched {
    std::vector<std::uint64_t> order;
    std::vector<MeshBatch> batches;
    std::size_t mats = 0, shadows = 0;
};

Batched run(std::vector<MeshItem> items) {
    Batched r;
    std::vector<Mat4> mainMats, shadowMats;
    build_batches(items, true, r.batches, mainMats, shadowMats);
    for (const MeshItem& m : items) r.order.push_back(m.entity.bits());
    r.mats = mainMats.size();
    r.shadows = shadowMats.size();
    return r;
}

bool same(const Batched& a, const Batched& b) {
    if (a.order != b.order || a.mats != b.mats || a.shadows != b.shadows || a.batches.size() != b.batches.size())
        return false;
    for (std::size_t i = 0; i < a.batches.size(); ++i) {
        const MeshBatch &x = a.batches[i], &y = b.batches[i];
        if (x.rep != y.rep || x.mainFirst != y.mainFirst || x.mainCount != y.mainCount ||
            x.shadowFirst != y.shadowFirst || x.shadowCount != y.shadowCount)
            return false;
    }
    return true;
}

}  // namespace

TEST_CASE("sort key: the fields sit in the documented order and a rank that does not fit is refused") {
    std::uint64_t key = 0;
    REQUIRE(pack_sort_key(1, 2, 3, 4, key));
    CHECK(key == ((std::uint64_t(1) << 52) | (std::uint64_t(2) << 41) | (std::uint64_t(3) << 30) | 4));
    REQUIRE(pack_sort_key((1u << kSortMeshBits) - 1, (1u << kSortTexBits) - 1, (1u << kSortNormalBits) - 1,
                          (1u << kSortRestBits) - 1, key));
    CHECK(key == ~std::uint64_t(0));
    // A mesh decides before a texture, a texture before the normal map, that before the rest.
    std::uint64_t a = 0, b = 0;
    REQUIRE(pack_sort_key(1, 0, 0, 0, a));
    REQUIRE(pack_sort_key(0, 2047, 2047, (1u << 30) - 1, b));
    CHECK(a > b);
    // Overflow of any field: false, key untouched.
    key = 77;
    CHECK_FALSE(pack_sort_key(1u << kSortMeshBits, 0, 0, 0, key));
    CHECK_FALSE(pack_sort_key(0, 1u << kSortTexBits, 0, 0, key));
    CHECK_FALSE(pack_sort_key(0, 0, 1u << kSortNormalBits, 0, key));
    CHECK_FALSE(pack_sort_key(0, 0, 0, std::uint64_t(1) << kSortRestBits, key));
    CHECK(key == 77);
}

TEST_CASE("sort key: batches and order equal the comparator's on random items") {
    for (std::uint32_t seed : {1u, 2u, 3u, 12345u}) {
        INFO("seed " << seed);
        Pool pool;
        std::vector<MeshItem> plain = random_items(pool, seed, 700, 6);
        std::vector<MeshItem> keyed = plain;
        SortKeyTable table;
        REQUIRE(key_all(keyed, table));
        const Batched expected = run(plain);  // unkeyed: the comparator
        CHECK(expected.batches.size() > 20);
        CHECK(same(run(keyed), expected));
        // Equal keys exactly where the comparator finds the items equal.
        for (std::size_t i = 1; i < keyed.size(); ++i) {
            std::vector<MeshItem> two{keyed[i - 1], keyed[i]};
            std::vector<MeshItem> twoPlain{plain[i - 1], plain[i]};
            std::vector<MeshBatch> bk, bp;
            std::vector<Mat4> m1, m2;
            build_batches(two, true, bk, m1, m2);
            m1.clear();
            m2.clear();
            build_batches(twoPlain, true, bp, m1, m2);
            CHECK(bk.size() == bp.size());
        }
    }
}

TEST_CASE("sort key: a value the table has no room for leaves the items to the comparator") {
    Pool pool;
    std::vector<MeshItem> plain = random_items(pool, 9, 40, 4);
    for (int i = 0; i < 2100; ++i) pool.textures.emplace_back().path = "t" + std::to_string(i);
    for (std::size_t i = 0; i < plain.size(); ++i) plain[i].tex = &pool.textures[4 + i % 2100];  // 40 distinct only
    // 2100 distinct texture names among the items: more than the 11 bits hold.
    std::vector<MeshItem> many(2100);
    for (std::size_t i = 0; i < many.size(); ++i) {
        pool.renderers.emplace_back();
        many[i].mr = &pool.renderers.back();
        many[i].entity = Entity::from_bits(i + 1);
        many[i].tex = &pool.textures[4 + i];
    }
    std::vector<MeshItem> keyed = many;
    SortKeyTable table;
    CHECK_FALSE(key_all(keyed, table));
    CHECK_FALSE(table.valid());
    for (const MeshItem& m : keyed) CHECK_FALSE(m.keyed);
    const Batched r = run(keyed);  // still sorted, by the comparator
    CHECK(r.order.size() == 2100);
    CHECK(same(r, run(many)));
    // The table is rebuilt from nothing: a smaller set fits again.
    std::vector<MeshItem> few(plain.begin(), plain.end());
    CHECK(key_all(few, table));
    CHECK(table.valid());
}

TEST_CASE("sort key: a camera's own value is ranked again, and a value the table lacks is refused") {
    Pool pool;
    std::vector<MeshItem> items = random_items(pool, 5, 50, 5);
    SortKeyTable table;
    REQUIRE(key_all(items, table));
    MeshItem swapped = items[0];
    std::uint64_t key = 0;
    swapped.mesh = items[1].mesh;
    REQUIRE(table.key_of(fields_of(swapped), key));
    CHECK(key != items[0].sortKey);
    swapped.mesh = items[0].mesh;
    REQUIRE(table.key_of(fields_of(swapped), key));
    CHECK(key == items[0].sortKey);
    MeshAsset unknown;
    unknown.key = "not in the table";
    swapped.mesh = &unknown;
    CHECK_FALSE(table.key_of(fields_of(swapped), key));
}

TEST_CASE("sort key: the order does not depend on the job threads") {
    Pool pool;
    std::vector<MeshItem> items = random_items(pool, 77, 3000, 8);  // above the parallel sort threshold
    std::vector<MeshItem> keyed = items;
    SortKeyTable table;
    REQUIRE(key_all(keyed, table));
    const Batched reference = run(items);
    std::vector<jobs::Settings> settings{jobs::Settings::inline_jobs()};
    if (jobs::threads_supported()) {
        settings.push_back(jobs::Settings::threads(1));
        settings.push_back(jobs::Settings::threads(16));
    }
    CHECK(same(run(keyed), reference));  // pool stopped
    for (const jobs::Settings& st : settings) {
        auto r = jobs::start(st);
        REQUIRE(r.ok());
        const bool ok = same(run(keyed), reference) && same(run(items), reference);
        jobs::stop();
        CHECK(ok);
    }
}
