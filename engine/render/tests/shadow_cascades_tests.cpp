// M73.2a: the CPU side of the cascaded shadow maps (src/shadow_cascades.h). No GPU: the split distances, the texel snapping that keeps
// a still shadow still, the sample matrix that takes a world position to a texel of the atlas, and the atlas layout with its budget.
#include <doctest.h>

#include <cmath>
#include <set>

#include "mesh_batch.h"
#include "shadow_cascades.h"

using namespace fa;
using namespace fa::render;

namespace {
Mat4 camera_inverse(Vec3 pos, Vec3 target, float fovY, float aspect, float nearD, float farD, bool zeroToOne) {
    const Mat4 view = Mat4::look_at(pos, target);
    const Mat4 proj = Mat4::perspective(fovY, aspect, nearD, farD, zeroToOne);
    return (proj * view).inverse();
}
bool overlap(const ShadowTile& a, const ShadowTile& b) {
    return a.x < b.x + b.size && b.x < a.x + a.size && a.y < b.y + b.size && b.y < a.y + a.size;
}
}  // namespace

TEST_CASE("shadow cascades: the split distances follow the practical scheme") {
    const auto even = cascade_splits(0.5f, 100.5f, 4, 0.0f);
    CHECK(even[0] == doctest::Approx(0.5f));
    CHECK(even[1] == doctest::Approx(25.5f));
    CHECK(even[2] == doctest::Approx(50.5f));
    CHECK(even[3] == doctest::Approx(75.5f));
    CHECK(even[4] == doctest::Approx(100.5f));

    const auto logs = cascade_splits(1.0f, 1000.0f, 3, 1.0f);
    CHECK(logs[1] == doctest::Approx(10.0f).epsilon(0.01));
    CHECK(logs[2] == doctest::Approx(100.0f).epsilon(0.01));
    CHECK(logs[3] == doctest::Approx(1000.0f));

    // The default lambda sits between both, every split grows, the ends are the range.
    const auto mid = cascade_splits(0.1f, 200.0f, 4, 0.7f);
    for (int i = 0; i < 4; ++i) CHECK(mid[std::size_t(i)] < mid[std::size_t(i + 1)]);
    CHECK(mid[0] == doctest::Approx(0.1f));
    CHECK(mid[4] == doctest::Approx(200.0f));
    CHECK(mid[1] < cascade_splits(0.1f, 200.0f, 4, 0.0f)[1]);

    // One cascade is the whole range; a count outside 1..4 is clamped; a camera with no positive near (orthographic) gets even steps.
    const auto one = cascade_splits(1.0f, 50.0f, 1, 0.7f);
    CHECK(one[0] == doctest::Approx(1.0f));
    CHECK(one[1] == doctest::Approx(50.0f));
    CHECK(cascade_splits(1.0f, 50.0f, 9, 0.5f)[4] == doctest::Approx(50.0f));
    const auto ortho = cascade_splits(-20.0f, 20.0f, 2, 1.0f);
    CHECK(ortho[1] == doctest::Approx(0.0f));
}

TEST_CASE("shadow cascades: quantize_up never shrinks and absorbs jitter") {
    for (float v : {0.37f, 1.0f, 3.3f, 17.77f, 250.1f}) CHECK(quantize_up(v, 8) >= v);
    CHECK(quantize_up(12.3401f, 6) == quantize_up(12.3402f, 6));
    CHECK(quantize_up(-1.0f, 6) == -1.0f);
    CHECK(quantize_up(0.0f, 6) == 0.0f);
}

TEST_CASE("shadow cascades: the slice sphere does not depend on where the camera looks") {
    const float fov = 60.0f, aspect = 1.6f;
    const Vec3 pos{3, 4, 5};
    float radius = -1, centre = -1;
    for (Vec3 dir : {Vec3{0, 0, -1}, Vec3{1, 0, 0}, normalize(Vec3{1, -0.4f, -2}), normalize(Vec3{-3, 1, 0.5f})}) {
        const Vec3 f = normalize(dir);
        const Mat4 inv = camera_inverse(pos, pos + f, fov, aspect, 0.1f, 200.0f, true);
        const CameraFrustum fr = camera_frustum(inv, true, pos, f);
        CHECK(fr.nearDist == doctest::Approx(0.1f).epsilon(0.01));
        CHECK(fr.farDist == doctest::Approx(200.0f).epsilon(0.01));
        const SliceSphere s = slice_sphere(fr, 10.0f, 40.0f);
        if (radius < 0) {
            radius = s.radius;
            centre = s.centreDist;
        }
        CHECK(s.radius == doctest::Approx(radius).epsilon(1e-3));
        CHECK(s.centreDist == doctest::Approx(centre).epsilon(1e-3));
    }
    // It holds the slice: every corner of the slice is inside the sphere.
    const Vec3 f{0, 0, -1};
    const CameraFrustum fr = camera_frustum(camera_inverse(pos, pos + f, fov, aspect, 0.1f, 200.0f, true), true, pos, f);
    const SliceSphere s = slice_sphere(fr, 10.0f, 40.0f);
    const Vec3 c = pos + f * s.centreDist;
    for (float d : {10.0f, 40.0f}) {
        const float t = (d - fr.nearDist) / (fr.farDist - fr.nearDist);
        for (int i = 0; i < 4; ++i) {
            const Vec3 corner = fr.nearCorner[i] + (fr.farCorner[i] - fr.nearCorner[i]) * t;
            CHECK(length(corner - c) <= s.radius * 1.001f);
        }
    }
    CHECK(s.centreDist >= 10.0f);
    CHECK(s.centreDist <= 40.0f);
}

TEST_CASE("shadow cascades: a still point lands on the same texel as the camera moves less than a texel") {
    const Vec3 light = normalize(Vec3{-0.4f, -1.0f, -0.3f});
    const int tile = 1024;
    const float radius = quantize_up(23.0f, 6);
    const Vec3 point{2.3f, 0.0f, -4.1f};
    const ShadowTile placed{0, 0, tile};
    // The texel of the point in the tile for a centre that moves by fractions of a texel.
    auto texel_of = [&](Vec3 centre) {
        const CascadeFit fit = fit_cascade(centre, radius, light, tile, -50.0f, true);
        const Mat4 m = shadow_sample_matrix(fit, placed, tile, tile, true, false);
        const Vec4 p = m * Vec4{point, 1.0f};
        return Vec3{p.x / p.w * float(tile), p.y / p.w * float(tile), p.z / p.w};
    };
    const CascadeFit base = fit_cascade(Vec3{0, 0, 0}, radius, light, tile, -50.0f, true);
    const Vec3 t0 = texel_of(Vec3{0, 0, 0});
    // Sub-texel steps of the centre (a quarter texel along every axis) snap to the same grid cell, so the point is on the same texel
    // to float precision; a step of a whole texel moves it by exactly one.
    for (int i = 1; i <= 3; ++i) {
        const float step = base.texel * 0.05f * float(i);
        const Vec3 t = texel_of(Vec3{step, step * 0.5f, -step});
        CHECK(t.x == doctest::Approx(t0.x).epsilon(1e-4));
        CHECK(t.y == doctest::Approx(t0.y).epsilon(1e-4));
    }
    const Vec3 s = normalize(cross(light, Vec3{0, 1, 0}));
    const Vec3 moved = texel_of(s * base.texel);
    CHECK(std::fabs(moved.x - t0.x) == doctest::Approx(1.0f).epsilon(0.01));
    CHECK(std::fabs(moved.y - t0.y) < 0.01f);
}

TEST_CASE("shadow cascades: the fitted map covers its sphere and the near plane reaches the casters") {
    const Vec3 light = normalize(Vec3{0.2f, -1.0f, 0.1f});
    const Vec3 centre{10, 0, 10};
    const float radius = 16.0f;
    const float casterMin = dot(centre, light) - 200.0f;  // a tall caster far up the light
    const CascadeFit fit = fit_cascade(centre, radius, light, 512, casterMin, true);
    CHECK(fit.depthRange >= 200.0f + 2.0f * radius * 0.5f);
    CHECK(fit.texel == doctest::Approx(2.0f * radius / 512.0f));
    for (bool zeroToOne : {true, false}) {
        const CascadeFit f = fit_cascade(centre, radius, light, 512, casterMin, zeroToOne);
        // The caster's point, the sphere's centre and a point on the sphere's rim all land inside the clip volume.
        const Vec3 caster = centre + light * -200.0f;
        for (Vec3 p : {centre, caster, centre + Vec3{radius * 0.9f, 0, 0}}) {
            const Vec3 q = f.viewProj.transform_point(p);
            CHECK(std::fabs(q.x) <= 1.0f);
            CHECK(std::fabs(q.y) <= 1.0f);
            CHECK(q.z >= (zeroToOne ? 0.0f : -1.0f));
            CHECK(q.z <= 1.0f);
        }
    }
}

TEST_CASE("shadow cascades: the sample matrix maps into the tile on every backend") {
    const Vec3 light = normalize(Vec3{0.1f, -1.0f, 0.2f});
    const CascadeFit fit = fit_cascade(Vec3{1, 0, 2}, 10.0f, light, 256, -50.0f, true);
    const ShadowTile tile{512, 256, 256};
    const int w = 1024, h = 1024;
    for (bool isGl : {false, true}) {
        for (bool zeroToOne : {true, false}) {
            const CascadeFit f = fit_cascade(Vec3{1, 0, 2}, 10.0f, light, 256, -50.0f, zeroToOne);
            const Mat4 m = shadow_sample_matrix(f, tile, w, h, zeroToOne, isGl);
            const Vec4 r = shadow_tile_rect(tile, w, h, isGl);
            const Vec3 q = m.transform_point(fit.centre);
            // The centre of the sphere is the centre of the tile, half way through the depth.
            CHECK(q.x == doctest::Approx((r.x + r.z) * 0.5f).epsilon(1e-4));
            CHECK(q.y == doctest::Approx((r.y + r.w) * 0.5f).epsilon(1e-4));
            CHECK(q.z > 0.0f);
            CHECK(q.z < 1.0f);
            // A point one radius to the side of the centre is on the tile's edge.
            const Vec3 sideDir = normalize(cross(light, Vec3{0, 1, 0}));
            const Vec3 e = m.transform_point(fit.centre + sideDir * 10.0f);
            CHECK(e.x == doctest::Approx(r.z).epsilon(1e-4));
            CHECK(e.x <= r.z + 1e-4f);
        }
    }
    // The rectangles of the two conventions are each other's flip.
    const Vec4 a = shadow_tile_rect(tile, 1024, 1024, false), b = shadow_tile_rect(tile, 1024, 1024, true);
    CHECK(a.x == doctest::Approx(b.x));
    CHECK(a.y == doctest::Approx(1.0f - b.w));
    CHECK(a.w == doctest::Approx(1.0f - b.y));
}

TEST_CASE("shadow atlas: four cascades pack into a compact block without overlap") {
    std::vector<ShadowTileRequest> req(4);
    for (int i = 0; i < 4; ++i) req[std::size_t(i)] = {2048, 256, i};
    const ShadowAtlasLayout l = layout_shadow_atlas(4096, req);
    REQUIRE(l.tiles.size() == 4);
    CHECK(l.shrunk == 0);
    CHECK(l.dropped == 0);
    CHECK(l.width == 4096);
    CHECK(l.height == 4096);
    for (std::size_t i = 0; i < 4; ++i) {
        CHECK(l.tiles[i].size == 2048);
        for (std::size_t j = i + 1; j < 4; ++j) CHECK_FALSE(overlap(l.tiles[i], l.tiles[j]));
    }
    // Smaller maps use a smaller atlas.
    std::vector<ShadowTileRequest> small(4, ShadowTileRequest{512, 128, 0});
    const ShadowAtlasLayout s = layout_shadow_atlas(4096, small);
    CHECK(s.width == 1024);
    CHECK(s.height == 1024);
    // One map is the whole atlas; none is an empty one.
    const ShadowAtlasLayout one = layout_shadow_atlas(4096, {ShadowTileRequest{1024, 64, 0}});
    CHECK(one.width == 1024);
    CHECK(one.tiles[0].x == 0);
    CHECK(one.tiles[0].y == 0);
    CHECK(layout_shadow_atlas(4096, {}).width == 0);
}

TEST_CASE("shadow atlas: the layout is the same for the same input") {
    std::vector<ShadowTileRequest> req;
    for (int i = 0; i < 6; ++i) req.push_back({1024 >> (i % 3), 64, i});
    const ShadowAtlasLayout a = layout_shadow_atlas(2048, req), b = layout_shadow_atlas(2048, req);
    REQUIRE(a.tiles.size() == b.tiles.size());
    for (std::size_t i = 0; i < a.tiles.size(); ++i) {
        CHECK(a.tiles[i].x == b.tiles[i].x);
        CHECK(a.tiles[i].y == b.tiles[i].y);
        CHECK(a.tiles[i].size == b.tiles[i].size);
    }
}

TEST_CASE("shadow atlas: the budget shrinks the largest and least important map first, then drops") {
    // Four 2048 maps do not fit a 2048 atlas: the least important ones are halved first.
    std::vector<ShadowTileRequest> req(4);
    for (int i = 0; i < 4; ++i) req[std::size_t(i)] = {2048, 256, i};
    const ShadowAtlasLayout l = layout_shadow_atlas(2048, req);
    CHECK(l.dropped == 0);
    CHECK(l.shrunk > 0);
    CHECK(l.tiles[0].size >= l.tiles[3].size);
    for (std::size_t i = 0; i < 4; ++i) {
        CHECK(l.tiles[i].placed());
        CHECK(l.tiles[i].x + l.tiles[i].size <= 2048);
        CHECK(l.tiles[i].y + l.tiles[i].size <= 2048);
        for (std::size_t j = i + 1; j < 4; ++j) CHECK_FALSE(overlap(l.tiles[i], l.tiles[j]));
    }

    // Twenty-one tiles that cannot shrink (a point light has six faces) do not fit 512: the least important are dropped, the most
    // important stay, and what was placed never overlaps.
    std::vector<ShadowTileRequest> many;
    for (int i = 0; i < 20; ++i) many.push_back({256, 256, i});
    const ShadowAtlasLayout m = layout_shadow_atlas(512, many);
    CHECK(m.dropped == 16);
    int placed = 0;
    for (std::size_t i = 0; i < many.size(); ++i) {
        if (!m.tiles[i].placed()) {
            CHECK(i >= 4);
            continue;
        }
        ++placed;
        for (std::size_t j = i + 1; j < many.size(); ++j)
            if (m.tiles[j].placed()) CHECK_FALSE(overlap(m.tiles[i], m.tiles[j]));
    }
    CHECK(placed == 4);

    // A request of size 0 or a non power of two: 0 is dropped, 1000 is placed as 512.
    const ShadowAtlasLayout odd = layout_shadow_atlas(2048, {ShadowTileRequest{0, 64, 0}, ShadowTileRequest{1000, 64, 1}});
    CHECK_FALSE(odd.tiles[0].placed());
    CHECK(odd.tiles[1].size == 512);
}

TEST_CASE("shadow atlas: power of two helpers") {
    CHECK(pow2_floor(0) == 0);
    CHECK(pow2_floor(1) == 1);
    CHECK(pow2_floor(1000) == 512);
    CHECK(pow2_floor(1024) == 1024);
    CHECK(pow2_ceil(0) == 1);
    CHECK(pow2_ceil(1000) == 1024);
    CHECK(pow2_ceil(1024) == 1024);
    CHECK(pow2_ceil(1025) == 2048);
}

TEST_CASE("shadow cascades: a batch lists the casters of each cascade, those whose castMask has the bit") {
    MeshRenderer mr;
    std::vector<MeshItem> items(3);
    const std::uint32_t masks[] = {0b001, 0b110, 0b101};
    for (std::size_t i = 0; i < items.size(); ++i) {
        items[i].mr = &mr;
        items[i].visible = true;
        items[i].casts = true;
        items[i].castMask = masks[i];
    }
    std::vector<MeshBatch> batches;
    std::vector<Mat4> mainMats, shadowMats;
    build_batches(items, true, batches, mainMats, shadowMats, 3);
    REQUIRE(batches.size() == 1);
    const MeshBatch& b = batches[0];
    CHECK(b.cascadeCount[0] == 2);  // items 0 and 2
    CHECK(b.cascadeCount[1] == 1);  // item 1
    CHECK(b.cascadeCount[2] == 2);  // items 1 and 2
    CHECK(shadowMats.size() == 5);
    CHECK(b.cascadeFirst[1] == b.cascadeFirst[0] + 2);
    CHECK(b.cascadeFirst[2] == b.cascadeFirst[1] + 1);
    CHECK(b.shadowFirst == b.cascadeFirst[0]);
    CHECK(b.shadowCount == b.cascadeCount[0]);
    // The default of one cascade lists the casters of the first cascade only.
    batches.clear();
    mainMats.clear();
    shadowMats.clear();
    build_batches(items, true, batches, mainMats, shadowMats);
    REQUIRE(batches.size() == 1);
    CHECK(batches[0].cascadeCount[0] == 2);  // items 0 and 2: the mask has bit 0
}
