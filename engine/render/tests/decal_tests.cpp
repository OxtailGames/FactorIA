// M73.5b: projected decals, the CPU half (src/light_clusters.h, src/decal_atlas.h; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Decals").
// No GPU: these run where `ctest -LE gpu` does. The decal boxes are binned into the same cluster grid as the lights and compared with a
// brute-force reference (a point inside a box must be in the decal list of its cluster), the lists must be the same bytes with any number of
// job threads, the data texture holds the decal region in the layout shaders/light_data.glsl reads (and a view without decals the same
// texels as before), and the atlas layout is deterministic, never overlaps and reports what it had to shrink or leave out.
#include <doctest.h>

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <limits>
#include <map>
#include <string>
#include <vector>

#include "fa/core/jobs.h"

#include "decal_atlas.h"
#include "light_clusters.h"

using namespace fa;
using namespace fa::render;

namespace {

struct Lcg {
    std::uint32_t s;
    explicit Lcg(std::uint32_t seed) : s(seed) {}
    float next() {
        s = s * 1664525u + 1013904223u;
        return float(s >> 8) / float(1u << 24);
    }
    float range(float a, float b) { return a + (b - a) * next(); }
};

struct View {
    ClusterCamera cam;
    ClusterGrid grid;
};

View make_view(int w, int h, bool zeroToOne, Vec3 eye = {0, 0, 0}, Vec3 target = {0, 0, -1}) {
    View v;
    const Mat4 view = Mat4::look_at(eye, target);
    const Mat4 proj = Mat4::perspective(60.0f, float(w) / float(h), 0.1f, 200.0f, zeroToOne);
    v.cam.viewProj = proj * view;
    v.cam.position = eye;
    v.cam.forward = normalize(target - eye);
    v.cam.nearDepth = 0.1f;
    v.cam.farDepth = 200.0f;
    v.cam.widthPx = w;
    v.cam.heightPx = h;
    v.grid = make_cluster_grid(w, h, 0.1f, 200.0f);
    return v;
}

DecalBox box_of(const Mat4& world) {
    DecalBox b;
    for (int i = 0; i < 8; ++i)
        b.corners[i] =
            world.transform_point(Vec3{(i & 1) ? 0.5f : -0.5f, (i & 2) ? 0.5f : -0.5f, (i & 4) ? 0.5f : -0.5f});
    return b;
}

struct RandomDecals {
    std::vector<Mat4> worlds;
    std::vector<DecalBox> boxes;
};

RandomDecals random_decals(std::uint32_t seed, int count, float spread) {
    Lcg r(seed);
    RandomDecals d;
    for (int i = 0; i < count; ++i) {
        const Vec3 pos{r.range(-spread, spread), r.range(-spread * 0.5f, spread * 0.5f), r.range(-spread * 2.0f, 0.0f)};
        const Mat4 m = Mat4::translate(pos) * Mat4::rotate_y_deg(r.range(0.0f, 360.0f)) *
                       Mat4::scale(Vec3{r.range(0.5f, 4.0f), r.range(0.5f, 4.0f), r.range(0.2f, 2.0f)});
        d.worlds.push_back(m);
        d.boxes.push_back(box_of(m));
    }
    return d;
}

bool cluster_of(const ClusterUniforms& u, const ClusterGrid& g, Vec3 p, int& out) {
    const float cx = u.vpx[0] * p.x + u.vpx[1] * p.y + u.vpx[2] * p.z + u.vpx[3];
    const float cy = u.vpy[0] * p.x + u.vpy[1] * p.y + u.vpy[2] * p.z + u.vpy[3];
    const float cw = u.vpw[0] * p.x + u.vpw[1] * p.y + u.vpw[2] * p.z + u.vpw[3];
    if (!(cw > 1e-4f)) return false;
    const float nx = cx / cw, ny = cy / cw;
    if (nx < -1.0f || nx > 1.0f || ny < -1.0f || ny > 1.0f) return false;
    const float depth = u.fwd[0] * p.x + u.fwd[1] * p.y + u.fwd[2] * p.z + u.fwd[3];
    if (depth < g.nearDepth) return false;
    out = cluster_index(g, cluster_tile(nx, g.tilesX), cluster_tile(ny, g.tilesY), cluster_slice(g, depth));
    return true;
}

}  // namespace

TEST_CASE("decals: every point inside a decal box is in the decal list of its cluster (brute-force reference)") {
    for (const bool zeroToOne : {false, true}) {
        CAPTURE(zeroToOne);
        const View v = make_view(1280, 720, zeroToOne);
        const RandomDecals d = random_decals(11, 60, 30.0f);
        ClusterLists lists;
        build_decal_clusters(v.cam, v.grid, d.boxes, lists);
        REQUIRE(lists.first.size() == std::size_t(v.grid.clusters()));
        CHECK(lists.clippedEntries == 0);
        CHECK(lists.lightsAssigned > 0);
        LightTexture tex;
        pack_light_texture({}, 0, v.cam, &lists, tex);
        Lcg r(5);
        int checked = 0, inside = 0;
        for (int n = 0; n < 8000; ++n) {
            const std::size_t i = std::size_t(r.next() * float(d.worlds.size())) % d.worlds.size();
            // A point inside decal i, found in its box space.
            const Vec3 p =
                d.worlds[i].transform_point(Vec3{r.range(-0.5f, 0.5f), r.range(-0.5f, 0.5f), r.range(-0.5f, 0.5f)});
            int c = 0;
            if (!cluster_of(tex.uniforms, v.grid, p, c)) continue;
            ++checked;
            const std::uint32_t first = lists.first[std::size_t(c)], count = lists.count[std::size_t(c)];
            const auto* b = lists.indices.data() + first;
            ++inside;
            CHECK_MESSAGE(std::binary_search(b, b + count, std::uint32_t(i)),
                          "decal " << i << " holds point " << n << " but is not in cluster " << c);
        }
        CHECK(checked > 500);
        CHECK(inside == checked);
        for (std::size_t c = 0; c < lists.first.size(); ++c) {
            const auto* b = lists.indices.data() + lists.first[c];
            for (std::uint32_t k = 1; k < lists.count[c]; ++k) CHECK(b[k - 1] < b[k]);
        }
    }
}

TEST_CASE("decals: a box behind the camera or far outside the view reaches no cluster") {
    const View v = make_view(1280, 720, false);
    std::vector<DecalBox> boxes;
    boxes.push_back(box_of(Mat4::translate({0, 0, 20}) * Mat4::scale({2, 2, 2})));     // behind
    boxes.push_back(box_of(Mat4::translate({500, 0, -20}) * Mat4::scale({2, 2, 2})));  // far to the side
    boxes.push_back(box_of(Mat4::translate({0, 0, -400}) * Mat4::scale({2, 2, 2})));   // beyond the far plane
    ClusterLists lists;
    build_decal_clusters(v.cam, v.grid, boxes, lists);
    CHECK(lists.lightsAssigned == 0);
    CHECK(lists.indices.empty());
    // One in view is found.
    boxes.push_back(box_of(Mat4::translate({0, 0, -10}) * Mat4::scale({2, 2, 2})));
    build_decal_clusters(v.cam, v.grid, boxes, lists);
    CHECK(lists.lightsAssigned == 1);
    CHECK(lists.indices.size() > 0);
}

TEST_CASE("decals: the lists are the same bytes with the pool stopped, inline and with 1, 2 and 8 workers") {
    const View v = make_view(1920, 1080, false);
    const RandomDecals d = random_decals(23, 200, 40.0f);
    struct Mode {
        const char* name;
        bool start;
        jobs::Settings settings;
    };
    std::vector<Mode> modes{{"stopped", false, {}}, {"inline", true, jobs::Settings::inline_jobs()}};
    if (jobs::threads_supported()) {
        modes.push_back({"1 worker", true, jobs::Settings::threads(1)});
        modes.push_back({"2 workers", true, jobs::Settings::threads(2)});
        modes.push_back({"8 workers", true, jobs::Settings::threads(8)});
    }
    ClusterLists reference;
    bool haveReference = false;
    for (const Mode& m : modes) {
        CAPTURE(m.name);
        if (m.start) {
            auto r = jobs::start(m.settings);
            REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().to_string()));
        }
        ClusterLists lists;
        build_decal_clusters(v.cam, v.grid, d.boxes, lists);
        if (m.start) jobs::stop();
        CHECK(lists.indices.size() > 200);
        if (!haveReference) {
            reference = lists;
            haveReference = true;
            continue;
        }
        CHECK(lists.first == reference.first);
        CHECK(lists.count == reference.count);
        CHECK(lists.indices == reference.indices);
        CHECK(lists.clippedEntries == reference.clippedEntries);
        CHECK(lists.maxPerCluster == reference.maxPerCluster);
    }
}

TEST_CASE("decals: a cluster keeps its first 32 decals, a view at most 131072 entries; what is lost is counted") {
    const View v = make_view(1280, 720, false);
    // 50 decals that cover the whole view: every cluster wants 50.
    std::vector<DecalBox> boxes(50, box_of(Mat4::translate({0, 0, -100}) * Mat4::scale({400, 400, 300})));
    ClusterLists lists;
    build_decal_clusters(v.cam, v.grid, boxes, lists);
    const std::size_t clusters = std::size_t(v.grid.clusters());
    CHECK(lists.indices.size() <= std::size_t(kMaxDecalIndices));
    CHECK(lists.maxPerCluster == std::size_t(kMaxDecalsPerCluster));
    CHECK(lists.clippedEntries > 0);
    std::size_t kept = 0;
    for (std::size_t c = 0; c < clusters; ++c) {
        CHECK(lists.count[c] <= std::uint32_t(kMaxDecalsPerCluster));
        kept += lists.count[c];
        for (std::uint32_t k = 0; k < lists.count[c]; ++k)
            CHECK(lists.indices[lists.first[c] + k] == k);  // the lowest survive
    }
    CHECK(kept == lists.indices.size());
    CHECK(kept + lists.clippedEntries == clusters * 50);
    // A normal count (a tenth of the cluster cap) loses nothing.
    std::vector<DecalBox> few(3, boxes[0]);
    build_decal_clusters(v.cam, v.grid, few, lists);
    CHECK(lists.clippedEntries == 0);
    CHECK(lists.maxPerCluster == 3);
}

TEST_CASE("decals: the data texture holds the decal region after the light lists, and a view without decals has the "
          "old texels") {
    const View v = make_view(640, 360, false);
    LightData sun;
    sun.pos = {0.0f, 1.0f, 0.0f, 0.0f};
    sun.color = {2.0f, 1.5f, 1.0f, 0.0f};
    sun.rank = 0;
    LightData point;
    point.pos = {1.0f, 2.0f, -10.0f, 15.0f};
    point.color = {1, 1, 1, 1};
    point.rank = 2;
    const std::vector<LightData> table{sun, point};
    ClusterLists lights;
    build_light_clusters(v.cam, v.grid, {{0, 0, 0, 0}, {1.0f, 2.0f, -10.0f, 15.0f}}, lights);

    DecalPack pack;
    const Mat4 world = Mat4::translate({0, 0, -10}) * Mat4::scale({4, 4, 2});
    const Mat4 inv = world.inverse();
    for (int n = 0; n < 2; ++n) {
        DecalRecord r;
        for (int row = 0; row < 3; ++row)
            for (int c = 0; c < 4; ++c) r.rows[row * 4 + c] = inv.at(c, row);
        r.albedoRect[0] = 0.25f;
        r.albedoRect[1] = 0.5f;
        r.albedoRect[2] = 0.5f;
        r.albedoRect[3] = 0.75f;
        r.tint[0] = 0.5f;
        r.opacity = 0.75f;
        r.normalStrength = 2.0f;
        r.angleScale = 4.0f;
        r.layers = float(n == 0 ? 65535 : 2);
        pack.records.push_back(r);
    }
    build_decal_clusters(v.cam, v.grid, {box_of(world), box_of(world)}, pack.lists);
    pack.atlasWidth = 256;
    pack.atlasHeight = 128;
    pack.colorMode = 2;

    LightTexture plain, withDecals;
    pack_light_texture(table, 1, v.cam, &lights, plain);
    pack_light_texture(table, 1, v.cam, &lights, withDecals, nullptr, &pack);
    CHECK(plain.uniforms.decalBase == 0.0f);
    const std::size_t lightTexels = table.size() * std::size_t(kLightTexels);
    const std::size_t clusters = std::size_t(v.grid.clusters());
    const std::size_t indexTexels = (lights.indices.size() + 3) / 4;
    CHECK(plain.usedTexels == lightTexels + clusters + indexTexels);
    const std::size_t base = lightTexels + clusters + indexTexels;
    CHECK(withDecals.uniforms.decalBase == float(base));
    const std::size_t idxBase = base + kDecalHeaderTexels + 2 * kDecalTexels;
    CHECK(withDecals.usedTexels == idxBase + (pack.lists.indices.size() + 3) / 4);
    auto texel = [&](const LightTexture& t, std::size_t i, int c) { return t.texels[i * 4 + std::size_t(c)]; };
    // Everything the lights use is the same, except z and w of the cluster texels (the decal slots).
    for (std::size_t i = 0; i < base; ++i)
        for (int c = 0; c < 4; ++c) {
            const bool decalSlot = i >= lightTexels && i < lightTexels + clusters && c >= 2;
            if (!decalSlot)
                CHECK(texel(withDecals, i, c) == texel(plain, i, c));
            else
                CHECK(texel(plain, i, c) == 0.0f);
        }
    for (std::size_t c = 0; c < clusters; ++c) {
        CHECK(texel(withDecals, lightTexels + c, 2) == float(pack.lists.first[c]));
        CHECK(texel(withDecals, lightTexels + c, 3) == float(pack.lists.count[c]));
    }
    // The header: count, atlas size and the first index texel, then the colour mode.
    CHECK(texel(withDecals, base, 0) == 2.0f);
    CHECK(texel(withDecals, base, 1) == 256.0f);
    CHECK(texel(withDecals, base, 2) == 128.0f);
    CHECK(texel(withDecals, base, 3) == float(idxBase));
    CHECK(texel(withDecals, base + 1, 0) == 2.0f);
    // Decal 1: three rows of the world -> box matrix, the albedo rect, the normal rect (none), the tint, the numbers.
    const std::size_t d1 = base + kDecalHeaderTexels + kDecalTexels;
    for (int row = 0; row < 3; ++row)
        for (int c = 0; c < 4; ++c) CHECK(texel(withDecals, d1 + std::size_t(row), c) == inv.at(c, row));
    CHECK(texel(withDecals, d1 + 3, 0) == 0.25f);
    CHECK(texel(withDecals, d1 + 3, 3) == 0.75f);
    CHECK(texel(withDecals, d1 + 4, 0) == 0.0f);
    CHECK(texel(withDecals, d1 + 5, 0) == 0.5f);
    CHECK(texel(withDecals, d1 + 6, 0) == 0.75f);
    CHECK(texel(withDecals, d1 + 6, 1) == 2.0f);
    CHECK(texel(withDecals, d1 + 6, 2) == 4.0f);
    CHECK(texel(withDecals, d1 + 6, 3) == 2.0f);
    // The decal indices after the records, four to a texel.
    std::size_t nonEmpty = 0;
    for (std::size_t c = 0; c < clusters; ++c) {
        for (std::uint32_t k = 0; k < pack.lists.count[c]; ++k) {
            const std::size_t slot = pack.lists.first[c] + k;
            CHECK(texel(withDecals, idxBase + slot / 4, int(slot % 4)) == float(pack.lists.indices[slot]));
        }
        nonEmpty += pack.lists.count[c] > 0 ? 1 : 0;
    }
    CHECK(nonEmpty > 0);
    // A pack that does not match the grid (or has no record) is ignored: the texels are those of a view without decals.
    DecalPack empty;
    LightTexture ignored;
    pack_light_texture(table, 1, v.cam, &lights, ignored, nullptr, &empty);
    CHECK(ignored.texels == plain.texels);
    CHECK(ignored.uniforms.decalBase == 0.0f);
    // A view with decals and no lights at all (clusters of an empty light table).
    ClusterLists none;
    build_light_clusters(v.cam, v.grid, {}, none);
    LightTexture decalsOnly;
    pack_light_texture({}, 0, v.cam, &none, decalsOnly, nullptr, &pack);
    CHECK(decalsOnly.uniforms.decalBase == float(clusters));
    // With a shadow region (M73.2b) the decals come after it: one cursor, lights | clusters | indices | shadows | decals.
    std::vector<LocalShadowRecord> shadows(1);
    shadows[0].light = 0;
    shadows[0].tiles.resize(1);
    LightTexture both, shadowsOnly;
    pack_light_texture(table, 1, v.cam, &lights, shadowsOnly, &shadows, nullptr);
    pack_light_texture(table, 1, v.cam, &lights, both, &shadows, &pack);
    const std::size_t shadowTexels = local_shadow_region_texels(int(table.size()), shadows);
    REQUIRE(shadowTexels > 0);
    CHECK(shadowsOnly.shadowBase == static_cast<long long>(base));
    CHECK(both.shadowBase == static_cast<long long>(base));
    CHECK(both.uniforms.decalBase == float(base + shadowTexels));
    CHECK(both.usedTexels ==
          base + shadowTexels + kDecalHeaderTexels + 2 * kDecalTexels + (pack.lists.indices.size() + 3) / 4);
    // The shadow region is untouched by the decals, and the decal header sits right after it.
    for (std::size_t i = base * 4; i < (base + shadowTexels) * 4; ++i) CHECK(both.texels[i] == shadowsOnly.texels[i]);
    CHECK(texel(both, base + shadowTexels, 0) == 2.0f);
}

namespace {

std::vector<DecalTexture> textures(std::initializer_list<DecalTexture> l) { return std::vector<DecalTexture>(l); }

bool overlap(const DecalTile& a, const DecalTile& b) {
    // The cells (the tile and its gutter) must not overlap.
    const int g = kDecalGutter;
    return a.x - g < b.x + b.w + g && b.x - g < a.x + a.w + g && a.y - g < b.y + b.h + g && b.y - g < a.y + a.h + g;
}

}  // namespace

TEST_CASE("decal atlas: tiles are scaled to 1024, packed without overlap in a power-of-two square, and never depend on "
          "the input order") {
    CHECK_NOTHROW([] {
        int w = 0, h = 0;
        decal_tile_size(4096, 2048, w, h);
        CHECK(w == 1024);
        CHECK(h == 512);
        decal_tile_size(100, 50, w, h);
        CHECK(w == 100);
        CHECK(h == 50);
        decal_tile_size(5000, 1, w, h);
        CHECK(w == 1024);
        CHECK(h == 1);
    }());
    const std::vector<DecalTexture> input = {{"b/dirt.png", 512, 512},   {"a/crack.png", 256, 256},
                                             {"c/blood.png", 128, 300},  {"a/crack_n.png", 256, 256},
                                             {"d/huge.png", 4000, 3000}, {"e/tiny.png", 8, 8}};
    DecalAtlasLayout first = layout_decal_atlas(input, 4096);
    REQUIRE(first.tiles.size() == 6);
    CHECK(first.dropped.empty());
    CHECK((first.width & (first.width - 1)) == 0);
    CHECK((first.height & (first.height - 1)) == 0);
    CHECK(first.height <= first.width);
    for (std::size_t i = 0; i < first.tiles.size(); ++i) {
        const DecalTile& t = first.tiles[i];
        CAPTURE(t.path);
        if (i > 0) CHECK(first.tiles[i - 1].path < t.path);
        CHECK(t.x >= kDecalGutter);
        CHECK(t.y >= kDecalGutter);
        CHECK(t.x + t.w + kDecalGutter <= first.width);
        CHECK(t.y + t.h + kDecalGutter <= first.height);
        CHECK((t.x - kDecalGutter) % 16 == 0);
        CHECK((t.y - kDecalGutter) % 16 == 0);
        for (std::size_t j = i + 1; j < first.tiles.size(); ++j) CHECK_FALSE(overlap(t, first.tiles[j]));
    }
    CHECK(first.find("d/huge.png")->w == 1024);
    CHECK(first.find("d/huge.png")->h == 768);
    CHECK(first.find("e/tiny.png")->w == 8);
    CHECK(first.find("nothing.png") == nullptr);
    // Any order of the same textures (and a repeated one) gives the same rectangles.
    for (int n = 0; n < 4; ++n) {
        std::vector<DecalTexture> shuffled = input;
        Lcg r(std::uint32_t(n) + 1);
        for (std::size_t i = shuffled.size(); i > 1; --i)
            std::swap(shuffled[i - 1], shuffled[std::size_t(r.next() * float(i)) % i]);
        shuffled.push_back(input[0]);
        const DecalAtlasLayout again = layout_decal_atlas(shuffled, 4096);
        REQUIRE(again.tiles.size() == first.tiles.size());
        CHECK(again.width == first.width);
        CHECK(again.height == first.height);
        for (std::size_t i = 0; i < again.tiles.size(); ++i) {
            CHECK(again.tiles[i].path == first.tiles[i].path);
            CHECK(again.tiles[i].x == first.tiles[i].x);
            CHECK(again.tiles[i].y == first.tiles[i].y);
            CHECK(again.tiles[i].w == first.tiles[i].w);
            CHECK(again.tiles[i].h == first.tiles[i].h);
        }
    }
    // Nothing to pack: an empty layout.
    const DecalAtlasLayout none = layout_decal_atlas({}, 4096);
    CHECK(none.width == 0);
    CHECK(none.tiles.empty());
    // A texture without a size is left out, by name.
    const DecalAtlasLayout bad = layout_decal_atlas(textures({{"x.png", 0, 10}, {"y.png", 16, 16}}), 4096);
    CHECK(bad.tiles.size() == 1);
    REQUIRE(bad.dropped.size() == 1);
    CHECK(bad.dropped[0] == "x.png");
}

TEST_CASE("decal atlas: when the tiles do not fit the biggest ones are halved, then the last are left out; both are "
          "reported") {
    // Four 1024 px tiles need 2048+ px of atlas; with a 1024 limit the biggest are halved until they fit.
    std::vector<DecalTexture> big;
    for (int i = 0; i < 4; ++i) big.push_back({"big" + std::to_string(i) + ".png", 1024, 1024});
    const DecalAtlasLayout shrunk = layout_decal_atlas(big, 1024);
    CHECK(shrunk.dropped.empty());
    REQUIRE(shrunk.tiles.size() == 4);
    CHECK(shrunk.width <= 1024);
    int shrunkCount = 0;
    for (const DecalTile& t : shrunk.tiles) {
        shrunkCount += t.shrunk ? 1 : 0;
        CHECK(t.w <= 512);
    }
    CHECK(shrunkCount > 0);
    // Too many tiles even at the smallest size: the last of the order are left out, and the rest still fit.
    std::vector<DecalTexture> many;
    for (int i = 0; i < 200; ++i) many.push_back({"t" + std::to_string(1000 + i) + ".png", 64, 64});
    const DecalAtlasLayout full = layout_decal_atlas(many, 64);
    CHECK(full.width == 64);
    CHECK(full.tiles.size() + full.dropped.size() == 200);
    CHECK(!full.dropped.empty());
    CHECK(!full.tiles.empty());
    for (const DecalTile& t : full.tiles) CHECK(t.x + t.w + kDecalGutter <= 64);
    for (std::size_t i = 1; i < full.dropped.size(); ++i) CHECK(full.dropped[i - 1] < full.dropped[i]);
    // The same again: the same ones are left out.
    const DecalAtlasLayout again = layout_decal_atlas(many, 64);
    CHECK(again.dropped == full.dropped);
}

TEST_CASE("decal atlas: build_decal_atlas copies each tile with a gutter that repeats its edge, and names what it "
          "could not read") {
    DecalSource src;
    src.size = [](const std::string& p) -> Result<ImageSize> {
        if (p == "missing.png") return make_error("file not found: missing.png");
        return ImageSize{32, 16};
    };
    src.load = [](const std::string& p) -> Result<Image> {
        if (p == "broken.png") return make_error("cannot decode broken.png");
        Image img;
        img.width = 32;
        img.height = 16;
        img.rgba.resize(32 * 16 * 4);
        for (int y = 0; y < 16; ++y)
            for (int x = 0; x < 32; ++x) {
                std::uint8_t* px = img.rgba.data() + (std::size_t(y) * 32 + std::size_t(x)) * 4;
                px[0] = std::uint8_t(x * 4);
                px[1] = std::uint8_t(y * 8);
                px[2] = p == "a.png" ? 10 : 200;
                px[3] = 255;
            }
        return img;
    };
    const DecalAtlasImage built = build_decal_atlas({"a.png", "b.png", "broken.png", "missing.png"}, src, 4096);
    CHECK(built.layout.tiles.size() == 3);  // the missing one has no size and no tile
    REQUIRE(built.failed.size() == 2);
    CHECK(built.failed[0].find("missing.png") == 0);
    CHECK(built.failed[1].find("broken.png") == 0);
    REQUIRE(built.image.width == built.layout.width);
    REQUIRE(built.image.height == built.layout.height);
    REQUIRE(built.image.rgba.size() == std::size_t(built.image.width) * std::size_t(built.image.height) * 4);
    auto at = [&](int x, int y) {
        return built.image.rgba.data() + (std::size_t(y) * std::size_t(built.image.width) + std::size_t(x)) * 4;
    };
    const DecalTile* a = built.layout.find("a.png");
    REQUIRE(a != nullptr);
    CHECK(a->w == 32);
    CHECK(a->h == 16);
    // The tile's own pixels, its gutter repeating the edge (left, right, top, bottom and the corner).
    CHECK(at(a->x + 5, a->y + 3)[0] == 20);
    CHECK(at(a->x + 5, a->y + 3)[1] == 24);
    CHECK(at(a->x + 5, a->y + 3)[2] == 10);
    CHECK(at(a->x - 1, a->y + 3)[0] == 0);
    CHECK(at(a->x - kDecalGutter, a->y + 3)[0] == 0);
    CHECK(at(a->x + a->w, a->y + 3)[0] == 31 * 4);
    CHECK(at(a->x + a->w + kDecalGutter - 1, a->y + 3)[0] == 31 * 4);
    CHECK(at(a->x + 5, a->y - 1)[1] == 0);
    CHECK(at(a->x + 5, a->y + a->h + kDecalGutter - 1)[1] == 15 * 8);
    CHECK(at(a->x - 1, a->y - 1)[0] == 0);
    CHECK(at(a->x - 1, a->y - 1)[1] == 0);
    // An unreadable tile is transparent with the flat normal (so a normal map that failed adds no relief).
    const DecalTile* broken = built.layout.find("broken.png");
    REQUIRE(broken != nullptr);
    CHECK(at(broken->x + 2, broken->y + 2)[0] == 128);
    CHECK(at(broken->x + 2, broken->y + 2)[2] == 255);
    CHECK(at(broken->x + 2, broken->y + 2)[3] == 0);
    // The same inputs give the same bytes.
    const DecalAtlasImage again = build_decal_atlas({"missing.png", "broken.png", "b.png", "a.png"}, src, 4096);
    CHECK(again.image.rgba == built.image.rgba);
    CHECK(again.layout.width == built.layout.width);
}
