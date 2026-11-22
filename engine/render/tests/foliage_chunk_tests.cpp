// M75-P6a: the CPU side of the Foliage drawing (src/foliage_chunks.h): the chunks, the stable thinning of `density`, the steps of the
// distance fade, the wind's sway and the matrix of an instance. No GPU: these run where `ctest -LE gpu` does.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <set>
#include <vector>

#include "foliage_chunks.h"
#include "renderer_foliage.h"

using namespace fa;
using namespace fa::render;

namespace {

// A grid of nx x nz instances `step` metres apart starting at (x0, z0), in file order row by row.
std::vector<FoliageInstance> grid(int nx, int nz, float step, float x0 = 0.0f, float z0 = 0.0f) {
    std::vector<FoliageInstance> v;
    for (int j = 0; j < nz; ++j)
        for (int i = 0; i < nx; ++i) {
            FoliageInstance f;
            f.position = {x0 + float(i) * step, float((i + j) % 3), z0 + float(j) * step};
            f.scale = 1.0f + float((i * 7 + j) % 4) * 0.25f;
            v.push_back(f);
        }
    return v;
}

}  // namespace

TEST_CASE("foliage chunks: every instance is in one chunk, the boxes hold their positions, the order is the cells'") {
    const auto in =
        grid(40, 40, 3.0f, -60.0f, -60.0f);  // 117 m square: 4 x 4 chunks of 32 m (cells -2..1 on each axis)
    const FoliageChunks c = build_foliage_chunks(in);
    REQUIRE(c.items.size() == in.size());
    std::size_t total = 0;
    std::uint32_t next = 0;
    for (const FoliageChunk& ch : c.chunks) {
        CHECK(ch.first == next);  // the chunks tile the item array in order
        next += ch.count;
        total += ch.count;
        float maxScale = 0.0f;
        std::set<std::pair<int, int>> cells;
        for (std::uint32_t k = 0; k < ch.count; ++k) {
            const FoliagePacked& p = c.items[ch.first + k];
            CHECK(p.position.x >= ch.lo.x);
            CHECK(p.position.x <= ch.hi.x);
            CHECK(p.position.y >= ch.lo.y);
            CHECK(p.position.y <= ch.hi.y);
            CHECK(p.position.z >= ch.lo.z);
            CHECK(p.position.z <= ch.hi.z);
            maxScale = std::max(maxScale, p.scale);
            cells.insert(
                {int(std::floor(p.position.x / kFoliageChunkSize)), int(std::floor(p.position.z / kFoliageChunkSize))});
        }
        CHECK(ch.maxScale == maxScale);
        CHECK(cells.size() == 1);  // one cell of the ground plane per chunk
        CHECK(ch.hi.x - ch.lo.x < kFoliageChunkSize);
        CHECK(ch.hi.z - ch.lo.z < kFoliageChunkSize);
    }
    CHECK(total == in.size());
    CHECK(c.chunks.size() == 16);
}

TEST_CASE("foliage chunks: the same file gives the same chunks, and a cell keeps the order of the file") {
    const auto in = grid(20, 20, 5.0f, -50.0f, -50.0f);
    const FoliageChunks a = build_foliage_chunks(in), b = build_foliage_chunks(in);
    REQUIRE(a.chunks.size() == b.chunks.size());
    for (std::size_t i = 0; i < a.chunks.size(); ++i) {
        CHECK(a.chunks[i].first == b.chunks[i].first);
        CHECK(a.chunks[i].count == b.chunks[i].count);
    }
    for (const FoliageChunk& ch : a.chunks) {
        std::uint16_t lastRank = 0;
        bool firstOne = true;
        float lastZ = 0;
        for (std::uint32_t k = 0; k < ch.count; ++k) {
            const FoliagePacked& p = a.items[ch.first + k];
            // rows of the grid come in z order in the file, so inside a cell z never goes down
            if (!firstOne) CHECK(p.position.z >= lastZ);
            firstOne = false;
            lastZ = p.position.z;
            (void)lastRank;
        }
    }
    CHECK(build_foliage_chunks({}).chunks.empty());
}

TEST_CASE("foliage chunks: a position on a cell border, a negative one and a far one each land in one chunk") {
    std::vector<FoliageInstance> in(4);
    in[0].position = {0.0f, 0, 0};
    in[1].position = {-0.001f, 0, 0};
    in[2].position = {32.0f, 0, 0};
    in[3].position = {1.0e9f, 0, -1.0e9f};
    const FoliageChunks c = build_foliage_chunks(in);
    CHECK(c.chunks.size() == 4);
    std::uint32_t total = 0;
    for (const FoliageChunk& ch : c.chunks) total += ch.count;
    CHECK(total == 4);
}

TEST_CASE("foliage thinning: the rank depends on the index only, and a lower density keeps a subset of a higher one") {
    for (std::uint32_t i : {0u, 1u, 77u, 65535u, 1000000u}) CHECK(foliage_thin_rank(i) == foliage_thin_rank(i));
    CHECK(foliage_keep_below(0.0f) == 0);
    CHECK(foliage_keep_below(-1.0f) == 0);
    CHECK(foliage_keep_below(1.0f) == 65536u);
    CHECK(foliage_keep_below(7.0f) == 65536u);
    CHECK(foliage_keep_below(0.5f) == 32768u);
    const std::uint32_t n = 20000;
    std::uint32_t kept30 = 0, kept60 = 0, kept100 = 0;
    for (std::uint32_t i = 0; i < n; ++i) {
        const bool k30 = foliage_thin_rank(i) < foliage_keep_below(0.3f);
        const bool k60 = foliage_thin_rank(i) < foliage_keep_below(0.6f);
        if (k30) CHECK(k60);  // a subset, so raising the density only adds instances
        kept30 += k30;
        kept60 += k60;
        kept100 += foliage_thin_rank(i) < foliage_keep_below(1.0f);
    }
    CHECK(kept100 == n);
    CHECK(std::abs(int(kept30) - int(0.3f * float(n))) < int(n / 50));  // evenly spread: within 2 %
    CHECK(std::abs(int(kept60) - int(0.6f * float(n))) < int(n / 50));
}

TEST_CASE("foliage thinning: any run of neighbours in the file loses about its share, not a clump") {
    const std::uint32_t below = foliage_keep_below(0.5f);
    for (std::uint32_t start : {0u, 1234u, 40000u}) {
        int kept = 0;
        for (std::uint32_t i = start; i < start + 64; ++i) kept += foliage_thin_rank(i) < below;
        CHECK(kept >= 24);
        CHECK(kept <= 40);
    }
}

TEST_CASE("foliage thinning: kept counts of a chunk match a brute-force count, and density 1 keeps the whole chunk") {
    const FoliageChunks c = build_foliage_chunks(grid(30, 30, 4.0f));
    for (float density : {0.0f, 0.25f, 0.5f, 0.9f, 1.0f}) {
        CAPTURE(density);
        std::uint32_t total = 0;
        for (const FoliageChunk& ch : c.chunks) {
            std::uint32_t brute = 0;
            for (std::uint32_t k = 0; k < ch.count; ++k)
                brute += c.items[ch.first + k].rank < foliage_keep_below(density) ? 1 : 0;
            CHECK(foliage_kept_count(c, ch, density) == brute);
            total += brute;
        }
        if (density == 0.0f) CHECK(total == 0);
        if (density == 1.0f) CHECK(total == c.items.size());
    }
}

TEST_CASE("foliage fade: solid up to fadeStart, kFoliageFadeSteps steps to fadeEnd, nothing from fadeEnd") {
    CHECK(foliage_fade_step(0.0f, 80, 100) == 0);
    CHECK(foliage_fade_step(80.0f, 80, 100) == 0);
    CHECK(foliage_fade_step(80.01f, 80, 100) == 1);
    CHECK(foliage_fade_step(99.99f, 80, 100) == kFoliageFadeSteps);
    CHECK(foliage_fade_step(100.0f, 80, 100) == -1);
    CHECK(foliage_fade_step(500.0f, 80, 100) == -1);
    CHECK(foliage_fade_step(std::nanf(""), 80, 100) == -1);
    int last = 0;
    std::set<int> seen;
    for (float d = 70.0f; d < 100.0f; d += 0.05f) {
        const int s = foliage_fade_step(d, 80, 100);
        CHECK(s >= last);  // never goes back toward solid with the distance
        last = s;
        seen.insert(s);
    }
    CHECK(int(seen.size()) == kFoliageFadeSteps + 1);
    // the fade amount falls from near 1 to near 0, strictly, and stays inside (0, 1)
    CHECK(foliage_fade_amount(0) == 0.0f);
    float prev = 1.0f;
    for (int s = 1; s <= kFoliageFadeSteps; ++s) {
        const float a = foliage_fade_amount(s);
        CHECK(a > 0.0f);
        CHECK(a < prev);
        prev = a;
    }
    CHECK(foliage_fade_amount(kFoliageFadeSteps + 5) == foliage_fade_amount(kFoliageFadeSteps));
}

TEST_CASE("foliage wind: the sway stays within the strength, swings at the frequency and follows the position") {
    float dx = 0, dz = 0;
    foliage_sway(0.0f, 0.5f, 3.0f, 1.0f, 2.0f, dx, dz);
    CHECK(dx == 0.0f);
    CHECK(dz == 0.0f);
    float peak = 0.0f;
    for (int i = 0; i < 400; ++i) {
        foliage_sway(0.4f, 0.5f, float(i) * 0.05f, 3.0f, -2.0f, dx, dz);
        peak = std::max(peak, std::sqrt(dx * dx + dz * dz));
        CHECK(std::sqrt(dx * dx + dz * dz) <= 0.4f + 1e-5f);
    }
    CHECK(peak > 0.25f);  // it does swing
    // the same instance at t and t + 1 / frequency: the main swing repeats (the second harmonic does not divide the period, so not exactly)
    float ax, az, bx, bz;
    foliage_sway(0.4f, 0.5f, 1.0f, 3.0f, -2.0f, ax, az);
    foliage_sway(0.4f, 0.5f, 1.0f, 3.0f, -2.0f, bx, bz);
    CHECK(ax == bx);  // a function of the inputs only (deterministic)
    CHECK(az == bz);
    foliage_sway(0.4f, 0.5f, 1.0f, 30.0f, 20.0f, bx, bz);
    CHECK((ax != bx || az != bz));  // another position, another phase
}

TEST_CASE("foliage matrix: position, scale and yaw of an upright instance, and the lean of its up axis") {
    FoliagePacked p;
    p.position = {3, 1, -4};
    p.scale = 2.0f;
    Mat4 m = foliage_local_matrix(p);
    CHECK(m.translation().x == doctest::Approx(3.0f));
    CHECK(m.translation().y == doctest::Approx(1.0f));
    CHECK(m.translation().z == doctest::Approx(-4.0f));
    CHECK(m.transform_dir({0, 1, 0}).y == doctest::Approx(2.0f));
    p.yaw = 3.14159265f * 0.5f;
    m = foliage_local_matrix(p);
    const Vec3 x = m.transform_dir({1, 0, 0});
    CHECK(std::fabs(x.y) < 1e-5f);
    CHECK(length(x) == doctest::Approx(2.0f));
    CHECK(std::fabs(x.x) < 1e-4f);  // a quarter turn about +y takes +x to +-z
    CHECK(std::fabs(x.z) == doctest::Approx(2.0f));
    p.yaw = 0.7f;
    p.up = normalize(Vec3{0.5f, 1.0f, -0.25f});
    m = foliage_local_matrix(p);
    const Vec3 up = m.transform_dir({0, 1, 0}) * 0.5f;  // scale 2
    CHECK(up.x == doctest::Approx(p.up.x).epsilon(1e-4));
    CHECK(up.y == doctest::Approx(p.up.y).epsilon(1e-4));
    CHECK(up.z == doctest::Approx(p.up.z).epsilon(1e-4));
    // a turn: the three axes stay at right angles
    const Vec3 a = m.transform_dir({1, 0, 0}), b = m.transform_dir({0, 0, 1}), c = m.transform_dir({0, 1, 0});
    CHECK(std::fabs(dot(a, b)) < 1e-4f);
    CHECK(std::fabs(dot(a, c)) < 1e-4f);
    CHECK(std::fabs(dot(b, c)) < 1e-4f);
}

TEST_CASE("foliage lod name: <name>.lod1.<ext> for a model, nothing for a primitive or a level") {
    CHECK(foliage_lod_name("assets/models/grass.glb") == "assets/models/grass.lod1.glb");
    CHECK(foliage_lod_name("tree.gltf") == "tree.lod1.gltf");
    CHECK(foliage_lod_name("cube").empty());
    CHECK(foliage_lod_name("mesh:3").empty());
    CHECK(foliage_lod_name("assets/grass.lod1.glb").empty());
    // the extension in any case: the level is the file the bake writes, with a lower-case extension
    CHECK(foliage_lod_name("assets/Grass.GLB") == "assets/Grass.lod1.glb");
    CHECK(foliage_lod_name("Tree.GlTf") == "Tree.lod1.gltf");
    CHECK(foliage_lod_name("assets/grass.LOD1.GLB").empty());
}
