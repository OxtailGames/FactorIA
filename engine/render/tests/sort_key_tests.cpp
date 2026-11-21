// M95.2: the sort keys of the opaque meshes (mesh_batch.h, SortKeyTable). No GPU: items are built by hand. The keys
// must give the order and the batches the old comparator gave, whatever the job threads, and fall back to it when a
// field has more values than its bits hold.
#include "test_util.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <deque>
#include <limits>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/jobs.h"

#include "mesh_batch.h"
#include "render_scene.h"

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
        if (x.rep != y.rep || x.mainFirst != y.mainFirst || x.mainCount != y.mainCount || x.runCount != y.runCount)
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

TEST_CASE("sort key: NaN and signed zero in a value order and batch as the comparator does") {
    const float nan = std::numeric_limits<float>::quiet_NaN();
    for (int variant = 0; variant < 3; ++variant) {  // which field carries the odd values
        INFO("variant " << variant);
        Pool pool;
        std::vector<MeshItem> plain = random_items(pool, 21 + std::uint32_t(variant), 60, 3);
        const float odd[] = {nan, 0.0f, -0.0f, 1.0f};
        for (std::size_t i = 0; i < plain.size(); ++i) {
            MeshRenderer& r = *const_cast<MeshRenderer*>(plain[i].mr);
            const float v = odd[i % 4];
            if (variant == 0) r.color.r = v;
            if (variant == 1) r.roughness = v;
            if (variant == 2) r.uvScale.x = v;
        }
        std::vector<MeshItem> keyed = plain;
        SortKeyTable table;
        REQUIRE(key_all(keyed, table));
        CHECK(same(run(keyed), run(plain)));
        // -0 and +0 are one value: the same key where everything else is equal (as the comparator's ==).
        MeshItem a = keyed[0], b = keyed[0];
        MeshRenderer ra = *a.mr, rb = *b.mr;
        ra.metallic = 0.0f;
        rb.metallic = -0.0f;
        a.mr = &ra;
        b.mr = &rb;
        std::vector<MeshItem> zeros{a, b};
        zeros[1].entity = Entity::from_bits(999);
        SortKeyTable tz;
        REQUIRE(key_all(zeros, tz));
        CHECK(zeros[0].sortKey == zeros[1].sortKey);
        // Two NaNs (any payload) order alike: one rank.
        ra.metallic = nan;
        rb.metallic = -nan;
        std::vector<MeshItem> nans{a, b};
        nans[1].entity = Entity::from_bits(999);
        SortKeyTable tn;
        REQUIRE(key_all(nans, tn));
        CHECK(nans[0].sortKey == nans[1].sortKey);
        std::uint64_t ka = 0;
        CHECK(tn.key_of(fields_of(nans[0]), ka));
        CHECK(ka == nans[0].sortKey);
    }
}

TEST_CASE("sort key: a skinned item (a real Animator) is ranked by its entity and never shares a batch") {
    Pool pool;
    MeshAsset& skinned = pool.meshes.emplace_back();
    skinned.key = "rig";
    skinned.bmin = {-1, -1, -1};
    skinned.bmax = {1, 1, 1};
    skinned.parts.emplace_back().skinVb.id = 7;  // a part with a skin buffer: drawn deformed
    std::array<Animator, 3> anims;               // an Animator belongs to one entity
    for (Animator& a : anims) a.palette = {Mat4::identity()};
    std::vector<MeshItem> items(4);
    MeshRenderer& r = pool.renderers.emplace_back();
    for (std::size_t i = 0; i < items.size(); ++i) {
        MeshItem& it = items[i];
        it.mr = &r;
        it.mesh = &skinned;
        it.entity = Entity::from_bits(10 + i);
        const Animator* animator = i < 3 ? &anims[i] : nullptr;  // item 3: the same mesh, unskinned
        mesh_cull_bounds(skinned, animator, it.bmin, it.bmax, it.anim);
        CHECK((it.anim != nullptr) == (animator != nullptr));
    }
    std::vector<MeshItem> keyed = items;
    SortKeyTable table;
    REQUIRE(key_all(keyed, table));
    CHECK(keyed[0].sortKey != keyed[1].sortKey);  // two skinned entities: two ranks, so two batches
    CHECK(keyed[0].sortKey != keyed[3].sortKey);  // skinned and not
    CHECK(same(run(keyed), run(items)));
    CHECK(run(keyed).batches.size() == 4);
    std::uint64_t key = 0;  // the camera's own look-up of the same item
    REQUIRE(table.key_of(fields_of(keyed[1]), key));
    CHECK(key == keyed[1].sortKey);
}

TEST_CASE("sort key: the cost of one build over 2000 items (reported, never asserted)") {
    Pool pool;
    std::vector<MeshItem> items = random_items(pool, 3, 2000, 6);
    std::vector<SortFields> fields;
    for (const MeshItem& m : items) fields.push_back(fields_of(m));
    SortKeyTable table;
    std::vector<std::uint64_t> keys;
    std::vector<double> us;
    for (int i = 0; i < 41; ++i) {
        const auto t0 = std::chrono::steady_clock::now();
        const bool ok = table.build(fields, {}, keys);
        const auto t1 = std::chrono::steady_clock::now();
        CHECK(ok);
        us.push_back(std::chrono::duration<double, std::micro>(t1 - t0).count());
    }
    std::sort(us.begin(), us.end());
    MESSAGE("SortKeyTable::build over 2000 items: median " << us[us.size() / 2] << " us (min " << us.front() << ")");
}

TEST_CASE(
    "sort key: the limits are named; the empty texture name counts; colour and normal maps share the texture bits") {
    Pool pool;
    std::vector<MeshItem> items(1100);
    for (int i = 0; i < 2048; ++i) pool.textures.emplace_back().path = "t" + std::to_string(i);
    pool.renderers.emplace_back();
    for (std::size_t i = 0; i < items.size(); ++i) {
        items[i].mr = &pool.renderers.back();
        items[i].entity = Entity::from_bits(i + 1);
        items[i].tex = &pool.textures[i];
        items[i].normalTex = &pool.textures[(i + 500) % 1100];  // the same 1100 names: they fit
    }
    SortKeyTable table;
    CHECK(key_all(items, table));
    CHECK(table.overflow() == nullptr);
    items.resize(2048);  // 2048 colour names, and the empty one (a null normal map): 2049 > 2048
    for (std::size_t i = 1100; i < items.size(); ++i) {
        items[i].mr = &pool.renderers.back();
        items[i].entity = Entity::from_bits(i + 1);
        items[i].tex = &pool.textures[i];
        items[i].normalTex = nullptr;
    }
    CHECK_FALSE(key_all(items, table));
    REQUIRE(table.overflow() != nullptr);
    CHECK(std::string(table.overflow()) == "textures");
    items.back().tex = &pool.textures[0];  // 2047 names and the empty one: 2048 fit
    CHECK(key_all(items, table));
    // A normal map name counts against the same 2048 as the colour names.
    items.back().normalTex = &pool.textures[2047];
    items.back().tex = &pool.textures[2046];
    CHECK_FALSE(key_all(items, table));
}

TEST_CASE("sort key: two assets with one name (different pointers) get one rank, one key and the comparator's order") {
    Pool pool;
    std::vector<MeshItem> items = random_items(pool, 9, 40, 4);
    // Twin assets: another object for each mesh and texture, with the same name.
    const std::size_t meshes = pool.meshes.size(), texes = pool.textures.size();
    for (std::size_t i = 0; i < meshes; ++i) pool.meshes.emplace_back().key = pool.meshes[i].key;
    for (std::size_t i = 0; i < texes; ++i) pool.textures.emplace_back().path = pool.textures[i].path;
    // The twin of each asset by address (a deque is not contiguous: no pointer arithmetic across its elements).
    std::unordered_map<const void*, std::size_t> meshIndex, texIndex;
    for (std::size_t i = 0; i < meshes; ++i) meshIndex[&pool.meshes[i]] = i;
    for (std::size_t i = 0; i < texes; ++i) texIndex[&pool.textures[i]] = i;
    std::vector<MeshItem> twins = items;
    for (MeshItem& m : twins) {
        m.mesh = &pool.meshes[meshIndex.at(m.mesh) + meshes];
        if (m.tex) m.tex = &pool.textures[texIndex.at(m.tex) + texes];
    }
    SortKeyTable table;
    std::vector<MeshItem> both = items;
    both.insert(both.end(), twins.begin(), twins.end());
    REQUIRE(key_all(both, table));
    for (std::size_t i = 0; i < items.size(); ++i) {
        CHECK(both[i].sortKey == both[i + items.size()].sortKey);
        std::uint64_t key = 0;
        REQUIRE(table.key_of(fields_of(both[i + items.size()]), key));
        CHECK(key == both[i].sortKey);
    }
    std::vector<MeshItem> viaKeys = both, viaComparator = both;
    for (MeshItem& m : viaComparator) m.keyed = false;
    CHECK(same(run(viaKeys), run(viaComparator)));
}

// M73.6a: two MeshRenderers that differ only in a material layer are two draws, never one instanced draw with the
// representative's layers (the shader reads the layers from the uniform block of the batch's first item).
TEST_CASE(
    "batches: items that differ only in a material layer are not merged, by the comparator and by the sort keys") {
    using Setter = void (*)(MeshRenderer&);
    const Setter setters[] = {
        [](MeshRenderer& r) { r.clearcoat = 1.0f; },
        [](MeshRenderer& r) { r.clearcoatRoughness = 0.5f; },
        [](MeshRenderer& r) { r.sheenColor = Color{0.5f, 0.0f, 0.0f, 1.0f}; },
        [](MeshRenderer& r) { r.sheenColor = Color{0.0f, 0.5f, 0.0f, 1.0f}; },
        [](MeshRenderer& r) { r.sheenColor = Color{0.0f, 0.0f, 0.5f, 1.0f}; },
        [](MeshRenderer& r) { r.sheenRoughness = 0.9f; },
        [](MeshRenderer& r) { r.anisotropy = 0.5f; },
        [](MeshRenderer& r) { r.anisotropyRotation = 30.0f; },
        [](MeshRenderer& r) { r.specular = 0.5f; },
        [](MeshRenderer& r) { r.ior = 2.0f; },
        // M73-P6b: transmission and its volume.
        [](MeshRenderer& r) { r.transmission = 0.5f; },
        [](MeshRenderer& r) { r.thickness = 0.5f; },
        [](MeshRenderer& r) { r.attenuationColor = Color{0.5f, 1.0f, 1.0f, 1.0f}; },
        [](MeshRenderer& r) { r.attenuationColor = Color{1.0f, 0.5f, 1.0f, 1.0f}; },
        [](MeshRenderer& r) { r.attenuationColor = Color{1.0f, 1.0f, 0.5f, 1.0f}; },
        [](MeshRenderer& r) { r.attenuationDistance = 2.0f; },
        // M73.5: the subsurface strength, radius and colour of a mesh that scatters are part of the key.
        [](MeshRenderer& r) { r.subsurface = 0.5f; },
        [](MeshRenderer& r) {
            r.subsurface = 0.5f;
            r.subsurfaceRadius = 0.05f;
        },
        [](MeshRenderer& r) {
            r.subsurface = 0.5f;
            r.subsurfaceColor = Color{1.0f, 1.0f, 1.0f, 1.0f};
        },
    };
    for (Setter set : setters) {
        for (bool keyed : {false, true}) {
            Pool pool;
            pool.meshes.emplace_back().key = "sphere";
            std::vector<MeshItem> items(2);
            for (std::size_t i = 0; i < 2; ++i) {
                MeshRenderer& r = pool.renderers.emplace_back();
                if (i == 1) set(r);
                items[i].mr = &r;
                items[i].entity = Entity::from_bits(i + 1);
                items[i].mesh = &pool.meshes[0];
                items[i].visible = true;
                items[i].casts = false;
            }
            if (keyed) {
                SortKeyTable table;
                REQUIRE(key_all(items, table));
            }
            CHECK(run(items).batches.size() == 2);
            // And the same values are still one batch.
            items[1].mr = items[0].mr;
            if (keyed) {
                SortKeyTable table;
                REQUIRE(key_all(items, table));
            }
            CHECK(run(items).batches.size() == 1);
        }
    }
}
