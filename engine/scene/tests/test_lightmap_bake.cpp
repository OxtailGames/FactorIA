// The CPU lightmap baker (fa/scene/lightmap_bake.h) and the triangle BVH it shares with the model textures (fa/scene/bvh.h): the same bits with
// any number of threads, analytic skies, direct light and shadows, colour bleeding, the gutter, cancel, progress, the budgets and the probes.
#include <doctest.h>

#include <atomic>
#include <cmath>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/jobs.h"
#include "fa/scene/bvh.h"
#include "fa/scene/lightmap_bake.h"

using namespace fa;

namespace {

// A quad from `o` along `eu` and `ev` with the normal n, its UVs the rectangle [u0,u1] x [v0,v1] of the atlas.
BakeMesh quad(const char* name, Vec3 o, Vec3 eu, Vec3 ev, Vec3 n, int atlas, float u0, float v0, float u1, float v1,
              std::uint32_t material = 0) {
    BakeMesh m;
    m.name = name;
    m.positions = {o, o + eu, o + eu + ev, o + ev};
    m.normals = {n, n, n, n};
    m.indices = {0, 1, 2, 0, 2, 3};
    m.materials = {material, material};
    m.atlas = atlas;
    if (atlas >= 0) m.lightmapUv = {{u0, v0}, {u1, v0}, {u1, v1}, {u0, v1}};
    return m;
}

BakeSettings fast_settings() {
    BakeSettings s;
    s.samples = 32;
    s.bounces = 2;
    s.shadowSamples = 1;
    s.dilatePasses = 0;
    s.denoiseRadius = 0;
    return s;
}

// A closed 1 m room, red wall at x = 0, green at x = 1, white elsewhere, a point light near the ceiling. The atlas is 64 x 32: eight tiles of
// 16 x 16, one per wall in the order back (z=0), front, floor, ceiling, left, right.
BakeScene cornell() {
    BakeScene sc;
    sc.materials = {{{0.8f, 0.8f, 0.8f}, {}}, {{0.8f, 0.05f, 0.05f}, {}}, {{0.05f, 0.8f, 0.05f}, {}}};
    sc.atlases = {{64, 32}};
    auto tile = [](int t, float& u0, float& v0, float& u1, float& v1) {
        u0 = float(t % 4) / 4.0f;
        v0 = float(t / 4) / 2.0f;
        u1 = u0 + 0.25f;
        v1 = v0 + 0.5f;
    };
    float u0, v0, u1, v1;
    tile(0, u0, v0, u1, v1);
    sc.meshes.push_back(quad("back", {0, 0, 0}, {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, 0, u0, v0, u1, v1));
    tile(1, u0, v0, u1, v1);
    sc.meshes.push_back(quad("front", {0, 0, 1}, {1, 0, 0}, {0, 1, 0}, {0, 0, -1}, 0, u0, v0, u1, v1));
    tile(2, u0, v0, u1, v1);
    sc.meshes.push_back(quad("floor", {0, 0, 0}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, 0, u0, v0, u1, v1));
    tile(3, u0, v0, u1, v1);
    sc.meshes.push_back(quad("ceiling", {0, 1, 0}, {1, 0, 0}, {0, 0, 1}, {0, -1, 0}, 0, u0, v0, u1, v1));
    tile(4, u0, v0, u1, v1);
    sc.meshes.push_back(quad("left", {0, 0, 0}, {0, 1, 0}, {0, 0, 1}, {1, 0, 0}, 0, u0, v0, u1, v1, 1));
    tile(5, u0, v0, u1, v1);
    sc.meshes.push_back(quad("right", {1, 0, 0}, {0, 1, 0}, {0, 0, 1}, {-1, 0, 0}, 0, u0, v0, u1, v1, 2));
    BakeLight light;
    light.kind = BakeLightKind::Point;
    light.position = {0.5f, 0.9f, 0.5f};
    light.range = 5;
    light.intensity = 4;
    sc.lights = {light};
    return sc;
}

Vec3 texel(const BakedAtlas& a, int x, int y) {
    const std::size_t i = (std::size_t(y) * std::size_t(a.width) + std::size_t(x)) * 3;
    return {a.rgb[i], a.rgb[i + 1], a.rgb[i + 2]};
}

BakeScene floor_scene(float side, int size) {
    BakeScene sc;
    sc.atlases = {{size, size}};
    sc.meshes.push_back(quad("floor", {0, 0, 0}, {side, 0, 0}, {0, 0, side}, {0, 1, 0}, 0, 0, 0, 1, 1));
    return sc;
}

}  // namespace

TEST_CASE("bvh: closest, occluded and nearest agree with a brute-force test") {
    std::vector<Vec3> corners;
    // a grid of small triangles on a wavy surface
    for (int i = 0; i < 12; ++i)
        for (int j = 0; j < 12; ++j) {
            const float x = float(i), z = float(j), y = 0.3f * float((i * 7 + j * 3) % 5);
            corners.insert(corners.end(), {{x, y, z}, {x + 1, y, z}, {x, y + 0.2f, z + 1}});
        }
    corners.insert(corners.end(), {{2, 2, 2}, {2, 2, 2}, {2, 2, 2}});  // a triangle with no area: ignored
    TriBvh bvh;
    bvh.build(corners.data(), corners.size() / 3);
    CHECK(bvh.triangle_count() == corners.size() / 3);
    int hits = 0;
    for (int k = 0; k < 200; ++k) {
        const Vec3 o{float(k % 11) + 0.3f, 4.0f, float((k * 5) % 11) + 0.4f};
        const Vec3 d = normalize(Vec3{0.05f * float(k % 7 - 3), -1.0f, 0.04f * float(k % 5 - 2)});
        float best = -1;
        for (std::size_t t = 0; t + 2 < corners.size() - 3; t += 3) {
            const Vec3 e1 = corners[t + 1] - corners[t], e2 = corners[t + 2] - corners[t];
            const Vec3 pv = cross(d, e2);
            const float det = dot(e1, pv);
            if (std::fabs(det) < 1e-14f) continue;
            const Vec3 tv = o - corners[t];
            const float u = dot(tv, pv) / det;
            const Vec3 qv = cross(tv, e1);
            const float v = dot(d, qv) / det;
            if (u < 0 || u > 1 || v < 0 || u + v > 1) continue;
            const float tt = dot(e2, qv) / det;
            if (tt > 1e-7f && (best < 0 || tt < best)) best = tt;
        }
        RayHit h;
        const bool got = bvh.closest(o, d, 1e30f, -1, h);
        CHECK(got == (best >= 0));
        CHECK(bvh.occluded(o, d, 1e30f, -1) == got);
        if (got) {
            ++hits;
            CHECK(h.t == doctest::Approx(best).epsilon(1e-4));
            CHECK(bvh.nearest(o, d, 1e30f, -1) == h.t);
            CHECK(h.tri >= 0);
            CHECK(!bvh.occluded(o, d, h.t * 0.5f, -1));
        }
    }
    CHECK(hits > 100);
}

TEST_CASE("lightmap bake: a constant sky lights an open floor with its radiance") {
    BakeScene sc = floor_scene(2, 16);
    sc.sky.zenith = sc.sky.horizon = sc.sky.ground = {0.5f, 0.25f, 1.0f};
    sc.sky.intensity = 2;
    BakeSettings st = fast_settings();
    st.samples = 16;
    auto r = bake_lightmap(sc, st);
    REQUIRE(r.ok());
    const BakedAtlas& a = r->atlases[0];
    CHECK(a.bakedTexels == 16u * 16u);
    for (int y : {0, 7, 15}) {
        const Vec3 t = texel(a, 5, y);
        CHECK(t.x == doctest::Approx(1.0f).epsilon(1e-3));
        CHECK(t.y == doctest::Approx(0.5f).epsilon(1e-3));
        CHECK(t.z == doctest::Approx(2.0f).epsilon(1e-3));
    }
}

TEST_CASE("lightmap bake: a gradient sky gives the cosine-weighted analytic value") {
    BakeScene sc = floor_scene(2, 8);
    sc.sky.zenith = {1.0f, 0.5f, 0.0f};
    sc.sky.horizon = sc.sky.ground = {0.1f, 0.1f, 0.4f};
    BakeSettings st = fast_settings();
    st.samples = 256;
    auto r = bake_lightmap(sc, st);
    REQUIRE(r.ok());
    // L(y) = horizon + (zenith - horizon) y over the upper hemisphere; the cosine-weighted mean of y is 2/3
    const Vec3 expect = sc.sky.horizon + (sc.sky.zenith - sc.sky.horizon) * (2.0f / 3.0f);
    const Vec3 got = texel(r->atlases[0], 3, 3);
    CHECK(got.x == doctest::Approx(expect.x).epsilon(0.01));
    CHECK(got.y == doctest::Approx(expect.y).epsilon(0.01));
    CHECK(got.z == doctest::Approx(expect.z).epsilon(0.01));
}

TEST_CASE("lightmap bake: an equirect sky image lights like its colour") {
    BakeScene sc = floor_scene(2, 8);
    sc.sky.image.width = 8;
    sc.sky.image.height = 4;
    for (int i = 0; i < 32; ++i) sc.sky.image.rgb.insert(sc.sky.image.rgb.end(), {0.25f, 0.5f, 0.75f});
    BakeSettings st = fast_settings();
    st.samples = 16;
    auto r = bake_lightmap(sc, st);
    REQUIRE(r.ok());
    const Vec3 got = texel(r->atlases[0], 2, 2);
    CHECK(got.x == doctest::Approx(0.25f).epsilon(1e-3));
    CHECK(got.z == doctest::Approx(0.75f).epsilon(1e-3));
}

TEST_CASE("lightmap bake: a directional light lights the floor and a slab shadows it") {
    BakeScene sc = floor_scene(4, 32);
    // a 1 m slab at height 1 over the floor's middle: it casts shadows and is not baked
    sc.meshes.push_back(quad("slab", {1.5f, 1, 1.5f}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, -1, 0, 0, 0, 0));
    BakeLight sun;
    sun.kind = BakeLightKind::Directional;
    sun.direction = {0, -1, 0};
    sun.intensity = 1.5f;
    sc.lights = {sun};
    BakeSettings st = fast_settings();
    st.bounces = 0;
    auto r = bake_lightmap(sc, st);
    REQUIRE(r.ok());
    const BakedAtlas& a = r->atlases[0];
    const Vec3 lit = texel(a, 2, 2),
               shadow = texel(a, 16, 16);  // the floor is 4 m: texel 16 is at 2.06 m, under the slab
    CHECK(lit.x == doctest::Approx(1.5f).epsilon(1e-4));
    CHECK(shadow.x == doctest::Approx(0.0f).epsilon(1e-4));
    CHECK((lit.x > shadow.x + 1.0f));
}

TEST_CASE("lightmap bake: a soft light gives a penumbra and a hard one does not") {
    auto scene = [](float softAngle) {
        BakeScene sc = floor_scene(4, 64);
        sc.meshes.push_back(quad("slab", {1.5f, 1, 1.5f}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, -1, 0, 0, 0, 0));
        BakeLight sun;
        sun.direction = {0, -1, 0};
        sun.softAngleDeg = softAngle;
        sc.lights = {sun};
        return sc;
    };
    auto partial = [](const BakedAtlas& a) {
        int n = 0;
        for (int x = 0; x < a.width; ++x) {
            const float v = texel(a, x, 32).x;
            if (v > 0.05f && v < 0.95f) ++n;
        }
        return n;
    };
    BakeSettings st = fast_settings();
    st.bounces = 0;
    st.shadowSamples = 16;
    auto hard = bake_lightmap(scene(0), st);
    auto soft = bake_lightmap(scene(8), st);
    REQUIRE(hard.ok());
    REQUIRE(soft.ok());
    CHECK(partial(hard->atlases[0]) == 0);
    CHECK(partial(soft->atlases[0]) >= 2);
}

TEST_CASE("lightmap bake: realtime lights are left out and indirect-only lights are not seen directly") {
    BakeScene sc = cornell();
    BakeSettings st = fast_settings();
    st.bounces = 0;
    auto base = bake_lightmap(sc, st);
    REQUIRE(base.ok());
    CHECK(texel(base->atlases[0], 8, 8).x > 0.1f);  // the back wall under the light
    sc.lights[0].mode = BakeLightMode::Realtime;
    auto none = bake_lightmap(sc, st);
    REQUIRE(none.ok());
    CHECK(texel(none->atlases[0], 8, 8).x == 0.0f);
    sc.lights[0].mode = BakeLightMode::IndirectOnly;
    auto mixed0 = bake_lightmap(sc, st);
    REQUIRE(mixed0.ok());
    CHECK(texel(mixed0->atlases[0], 8, 8).x == 0.0f);  // no bounce: nothing is baked
    st.bounces = 1;
    auto mixed1 = bake_lightmap(sc, st);
    REQUIRE(mixed1.ok());
    CHECK(texel(mixed1->atlases[0], 8, 8).x > 0.01f);  // the light that bounced off the other walls
}

TEST_CASE("lightmap bake: the Cornell box bleeds colour onto the white wall next to the coloured one") {
    BakeScene sc = cornell();
    BakeSettings st = fast_settings();
    st.samples = 64;
    st.bounces = 0;
    auto direct = bake_lightmap(sc, st);
    st.bounces = 2;
    auto indirect = bake_lightmap(sc, st);
    REQUIRE(direct.ok());
    REQUIRE(indirect.ok());
    // back wall (tile 0, atlas x 0..15, y 0..15): u runs along x, so texel x = 1 is by the red wall (x = 0) and x = 14 by the green one
    const Vec3 nearRed = texel(indirect->atlases[0], 1, 8), nearGreen = texel(indirect->atlases[0], 14, 8);
    CHECK((nearRed.x > nearRed.y * 1.15f));
    CHECK((nearGreen.y > nearGreen.x * 1.15f));
    // without bounces the wall is white-lit: the light is white
    const Vec3 d0 = texel(direct->atlases[0], 1, 8);
    CHECK(d0.x == doctest::Approx(d0.y).epsilon(1e-4));
    CHECK(d0.y == doctest::Approx(d0.z).epsilon(1e-4));
    // and the bounces add light
    CHECK(nearRed.y > d0.y);
}

TEST_CASE(
    "lightmap bake: the same bits with no pool, one worker and many workers, and another seed changes the noise") {
    const BakeScene sc = cornell();
    BakeSettings st = fast_settings();
    st.dilatePasses = 3;
    st.denoiseRadius = 1;
    auto inlineRun = bake_lightmap(sc, st);
    REQUIRE(inlineRun.ok());
    std::uint64_t pooled[2] = {0, 0};
    for (int k = 0; k < 2; ++k) {
        REQUIRE(jobs::start(jobs::Settings::threads(k == 0 ? 1 : 5)).ok());
        auto r = bake_lightmap(sc, st);
        jobs::stop();
        REQUIRE(r.ok());
        pooled[k] = hash_bake_result(*r);
        CHECK(r->stats.rays == inlineRun->stats.rays);
    }
    CHECK(pooled[0] == hash_bake_result(*inlineRun));
    CHECK(pooled[1] == hash_bake_result(*inlineRun));
    st.seed = 7;
    auto other = bake_lightmap(sc, st);
    REQUIRE(other.ok());
    CHECK(hash_bake_result(*other) != hash_bake_result(*inlineRun));
    CHECK(inlineRun->stats.rays > 0);
}

TEST_CASE("lightmap bake: the gutter fills empty texels next to baked ones") {
    // half of a 16 x 16 atlas is covered
    BakeScene sc;
    sc.atlases = {{16, 16}};
    sc.meshes.push_back(quad("floor", {0, 0, 0}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, 0, 0, 0, 0.5f, 1));
    sc.sky.zenith = sc.sky.horizon = sc.sky.ground = {1, 1, 1};
    BakeSettings st = fast_settings();
    st.samples = 4;
    st.dilatePasses = 0;
    auto none = bake_lightmap(sc, st);
    REQUIRE(none.ok());
    CHECK(none->atlases[0].bakedTexels == 8u * 16u);
    CHECK(none->atlases[0].mask[10] == kBakeEmpty);
    CHECK(none->atlases[0].dilatedTexels == 0);
    st.dilatePasses = 3;
    auto some = bake_lightmap(sc, st);
    REQUIRE(some.ok());
    const BakedAtlas& a = some->atlases[0];
    CHECK(a.mask[7] == kBakeBaked);
    CHECK(a.mask[8] == kBakeDilated);
    CHECK(a.mask[10] == kBakeDilated);
    CHECK(a.mask[11] == kBakeEmpty);  // only three texels
    CHECK(texel(a, 10, 4).x == doctest::Approx(1.0f).epsilon(1e-3));
    CHECK(texel(a, 11, 4).x == 0.0f);
    CHECK(a.dilatedTexels == 3u * 16u);

    // the standalone function on a hand-made atlas: mean of the baked neighbours, 8-connected
    std::vector<float> rgb(9 * 3, 0.0f);
    std::vector<std::uint8_t> mask(9, kBakeEmpty);
    rgb[0] = 2;
    rgb[3 * 2] = 4;
    mask[0] = mask[2] = kBakeBaked;
    CHECK(dilate_texels(3, 3, rgb, mask, 1) ==
          4);  // the row of the baked texels (1,0) and the row below it; the last row is two texels away
    CHECK(rgb[3 * 1] == doctest::Approx(3.0f));
    CHECK(mask[1] == kBakeDilated);
    CHECK(mask[8] == kBakeEmpty);
}

TEST_CASE("lightmap bake: the denoise lowers the noise and keeps a shadow edge") {
    auto scene = [] {
        BakeScene sc = floor_scene(4, 32);
        sc.sky.zenith = sc.sky.horizon = sc.sky.ground = {1, 1, 1};
        // a big slab on one side: its shadow edge crosses the floor
        sc.meshes.push_back(quad("slab", {2, 0.5f, 0}, {2, 0, 0}, {0, 0, 4}, {0, 1, 0}, -1, 0, 0, 0, 0));
        sc.meshes.back().indices = {0, 1, 2, 0, 2, 3};
        return sc;
    };
    BakeSettings st = fast_settings();
    st.samples = 8;
    st.denoiseRadius = 0;
    auto raw = bake_lightmap(scene(), st);
    st.denoiseRadius = 2;
    auto smooth = bake_lightmap(scene(), st);
    REQUIRE(raw.ok());
    REQUIRE(smooth.ok());
    auto variance =
        [](const BakedAtlas& a) {  // along a row far from the edge (x 0..11 of 32: x < 2 m is open to the sky)
            double sum = 0, sum2 = 0;
            int n = 0;
            for (int y = 4; y < 28; ++y)
                for (int x = 3; x < 9; ++x) {
                    const double v = texel(a, x, y).x;
                    sum += v;
                    sum2 += v * v;
                    ++n;
                }
            const double mean = sum / n;
            return sum2 / n - mean * mean;
        };
    CHECK(variance(raw->atlases[0]) > 0);
    CHECK(variance(smooth->atlases[0]) < variance(raw->atlases[0]));
    // the edge: the open side stays brighter than the covered side
    CHECK((texel(smooth->atlases[0], 3, 16).x > texel(smooth->atlases[0], 28, 16).x * 1.3f));
}

TEST_CASE("lightmap bake: emissive surfaces light their neighbours") {
    BakeScene sc = floor_scene(2, 8);
    sc.materials = {{{0.8f, 0.8f, 0.8f}, {}}, {{0, 0, 0}, {3, 0, 0}}};
    // a red emitter wall facing the floor edge, not baked
    sc.meshes.push_back(quad("lamp", {0, 0, 2}, {2, 0, 0}, {0, 2, 0}, {0, 0, -1}, -1, 0, 0, 0, 0, 1));
    BakeSettings st = fast_settings();
    st.samples = 128;
    st.bounces = 0;
    auto r = bake_lightmap(sc, st);
    REQUIRE(r.ok());
    const Vec3 near = texel(r->atlases[0], 4, 7), far = texel(r->atlases[0], 4, 0);
    CHECK(near.x > far.x);
    CHECK(near.x > 0.3f);
    CHECK(near.y == 0.0f);
}

TEST_CASE("lightmap bake: spot and area lights light what they face and nothing behind") {
    BakeScene sc = floor_scene(4, 16);
    BakeLight spot;
    spot.kind = BakeLightKind::Spot;
    spot.position = {2, 2, 2};
    spot.direction = {0, -1, 0};
    spot.spotAngleDeg = 20;
    spot.range = 6;
    BakeLight area;
    area.kind = BakeLightKind::Area;
    area.position = {2, 3, 2};
    area.direction = {0, -1, 0};
    area.width = area.height = 1;
    area.intensity = 4;
    BakeSettings st = fast_settings();
    st.bounces = 0;
    st.shadowSamples = 8;
    sc.lights = {spot};
    auto s = bake_lightmap(sc, st);
    REQUIRE(s.ok());
    CHECK(texel(s->atlases[0], 8, 8).x > 0.3f);   // under the spot
    CHECK(texel(s->atlases[0], 0, 0).x == 0.0f);  // outside its cone (2.8 m off axis at 2 m: 54 degrees)
    sc.lights = {area};
    auto a = bake_lightmap(sc, st);
    REQUIRE(a.ok());
    CHECK(texel(a->atlases[0], 8, 8).x > 0.1f);
    sc.lights[0].direction = {0, 1, 0};  // facing away: the one-sided rectangle lights nothing below it
    auto away = bake_lightmap(sc, st);
    REQUIRE(away.ok());
    CHECK(texel(away->atlases[0], 8, 8).x == 0.0f);
}

TEST_CASE("lightmap bake: an area light's up vector turns its rectangle (width along cross(direction, up))") {
    // A 4 m x 0.2 m strip over the middle of the floor. With up = +Z its long side runs along X, with up = +X along Z: the light reaches farther
    // along the long side, so the two bakes are mirror images of each other (the atlas axes do not matter: the ratio flips).
    auto ratio = [](Vec3 up) {
        BakeScene sc = floor_scene(4, 16);
        BakeLight area;
        area.kind = BakeLightKind::Area;
        area.position = {2, 1, 2};
        area.direction = {0, -1, 0};
        area.up = up;
        area.width = 4;
        area.height = 0.2f;
        area.intensity = 4;
        sc.lights = {area};
        BakeSettings st = fast_settings();
        st.bounces = 0;
        st.shadowSamples = 32;
        auto r = bake_lightmap(sc, st);
        REQUIRE(r.ok());
        return texel(r->atlases[0], 1, 8).x / texel(r->atlases[0], 8, 1).x;
    };
    const float a = ratio({0, 0, 1}), b = ratio({1, 0, 0});
    CHECK(((a - 1.0f) * (b - 1.0f)) < 0);
    CHECK(std::fabs(a * b - 1.0f) < 0.15f);  // mirror images: one ratio is the inverse of the other
    CHECK(std::fabs(a - 1.0f) > 0.2f);
}

TEST_CASE("lightmap bake: cancel ends it with 'cancelled', before and in the middle") {
    BakeScene sc = cornell();
    BakeSettings st = fast_settings();
    std::atomic<bool> flag{true};
    {
        CommandCancelScope cancel(&flag);
        auto r = bake_lightmap(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message == "cancelled");
    }
    flag = false;
    int messages = 0;
    std::string first;
    {
        CommandCancelScope cancel(&flag);
        CommandProgressScope progress([&](std::string_view m) {
            if (m.find(", texels ") == std::string_view::npos) return true;  // the phase messages before the rays
            if (messages++ == 0) first = std::string(m);
            if (messages == 2) flag = true;  // cancel after the second report of the rays
            return true;
        });
        auto r = bake_lightmap(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message == "cancelled");
    }
    CHECK(messages == 2);
    CHECK(first.rfind("lightmap bake: atlas 1/1, texels ", 0) == 0);
    // the same bake without a scope reports nothing and finishes
    flag = false;
    CommandCancelScope cancel(&flag);
    CHECK(bake_lightmap(sc, st).ok());
}

TEST_CASE("lightmap bake: progress is reported, ending at 100%") {
    BakeScene sc = cornell();
    std::vector<std::string> seen;
    CommandProgressScope progress([&](std::string_view m) {
        seen.emplace_back(m);
        return true;
    });
    BakeSettings st = fast_settings();
    st.samples = 4;
    st.denoiseRadius = 1;
    REQUIRE(bake_lightmap(sc, st).ok());
    REQUIRE(seen.size() >= 4);
    bool bake100 = false, denoise = false;
    for (const std::string& m : seen) {
        if (m.rfind("lightmap bake:", 0) == 0 && m.find("(100%)") != std::string::npos) bake100 = true;
        if (m.rfind("lightmap denoise:", 0) == 0) denoise = true;
    }
    CHECK(bake100);
    CHECK(denoise);
}

TEST_CASE("lightmap bake: a bake over a budget is refused before anything is allocated") {
    BakeScene sc = floor_scene(1, 16);
    BakeSettings st = fast_settings();
    // an atlas that would take hundreds of gigabytes: refused by the size cap with nothing allocated
    sc.atlases = {{16000, 16000}};
    st.maxAtlasSize = 16384;
    auto big = bake_lightmap(sc, st);
    REQUIRE(!big.ok());
    CHECK(big.error().message.find("/maxMemoryBytes") != std::string::npos);
    CHECK(big.error().message.find("MB") != std::string::npos);
    CHECK(!big.error().hint.empty());
    st.maxAtlasSize = 4096;
    auto capped = bake_lightmap(sc, st);
    REQUIRE(!capped.ok());
    CHECK(capped.error().message.find("/atlases/0/width") != std::string::npos);
    CHECK(capped.error().message.find("maximum of 4096") != std::string::npos);
    // a sum that would wrap a 32-bit size
    sc.atlases = std::vector<BakeAtlas>(4000, BakeAtlas{4096, 4096});
    st.maxMemoryBytes = ~0ull;
    (void)validate_bake(sc, st);  // 6.7e10 texels: the size maths does not wrap, nothing is allocated
    st.maxMemoryBytes = 1ull << 30;
    CHECK(!validate_bake(sc, st).ok());
    // the ray budget
    sc.atlases = {{16, 16}};
    sc.sky.zenith = sc.sky.horizon = sc.sky.ground = {1, 1, 1};
    st.samples = 1000;
    st.maxRays = 1000;
    auto rays = bake_lightmap(sc, st);
    REQUIRE(!rays.ok());
    CHECK(rays.error().message.find("/maxRays") != std::string::npos);
    st.maxRays = 50000000000ull;
    CHECK(bake_lightmap(sc, st).ok());
}

TEST_CASE("lightmap bake: bad input is refused with the field and what to change") {
    BakeSettings st = fast_settings();
    {
        BakeScene sc = floor_scene(1, 8);
        sc.meshes[0].lightmapUv.pop_back();
        auto r = bake_lightmap(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/meshes/0/lightmapUv") != std::string::npos);
        CHECK(!r.error().hint.empty());
    }
    {
        BakeScene sc = floor_scene(1, 8);
        sc.meshes[0].lightmapUv[2] = {1.5f, 0.5f};
        auto r = validate_bake(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/meshes/0/lightmapUv/2") != std::string::npos);
    }
    {
        BakeScene sc = floor_scene(1, 8);
        sc.meshes[0].indices[4] = 9;
        auto r = validate_bake(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/meshes/0/indices/4") != std::string::npos);
    }
    {
        BakeScene sc = floor_scene(1, 8);
        sc.meshes[0].atlas = 3;
        auto r = validate_bake(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/meshes/0/atlas") != std::string::npos);
    }
    {
        BakeScene sc = floor_scene(1, 8);
        sc.materials = {{{2, 0, 0}, {}}};
        auto r = validate_bake(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/materials/0/albedo") != std::string::npos);
    }
    {
        BakeScene sc = floor_scene(1, 8);
        BakeLight l;
        l.kind = BakeLightKind::Spot;
        l.spotAngleDeg = 120;
        sc.lights = {l};
        auto r = validate_bake(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/lights/0/") != std::string::npos);
    }
    {
        BakeScene sc = floor_scene(1, 8);
        BakeSettings bad = st;
        bad.samples = 0;
        auto r = validate_bake(sc, bad);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/samples") != std::string::npos);
    }
    CHECK(suggest_atlas_size(10, 16, 4096) == 64);  // 2560 texels / (2/3) = 3840: a side of 62 rounds up to 64
    CHECK(suggest_atlas_size(1e9, 100, 2048) == 2048);
    CHECK(suggest_atlas_size(0, 100, 2048) == 16);
}

TEST_CASE("sample_irradiance_sh: a constant sky gives its radiance for every normal") {
    BakeScene sc;
    sc.sky.zenith = sc.sky.horizon = sc.sky.ground = {0.5f, 1.0f, 2.0f};
    BakeSettings st = fast_settings();
    st.samples = 64;
    auto r = sample_irradiance_sh(sc, {{0, 0, 0}, {1, 2, 3}}, st);
    REQUIRE(r.ok());
    REQUIRE(r->size() == 2);
    for (const ShL2& sh : *r)
        for (Vec3 n : {Vec3{0, 1, 0}, Vec3{0, -1, 0}, normalize(Vec3{1, 1, 0})}) {
            const Vec3 e = sh_irradiance(sh, n);
            CHECK(e.x == doctest::Approx(0.5f).epsilon(0.02));
            CHECK(e.y == doctest::Approx(1.0f).epsilon(0.02));
            CHECK(e.z == doctest::Approx(2.0f).epsilon(0.02));
        }
}

TEST_CASE("sample_irradiance_sh: a roof darkens the probe, a light and a bounce add to it, and it is deterministic") {
    BakeScene sc;
    sc.sky.zenith = sc.sky.horizon = {1, 1, 1};  // the ground is black: the roof's underside has nothing to reflect
    sc.meshes.push_back(quad("roof", {-5, 1, -5}, {10, 0, 0}, {0, 0, 10}, {0, -1, 0}, -1, 0, 0, 0, 0));
    BakeSettings st = fast_settings();
    st.samples = 64;
    const std::vector<Vec3> pts = {{0, 0.5f, 0}, {20, 0.5f, 0}};  // under the roof, and far outside it
    auto r = sample_irradiance_sh(sc, pts, st);
    REQUIRE(r.ok());
    const float under = sh_irradiance((*r)[0], {0, 1, 0}).x, open = sh_irradiance((*r)[1], {0, 1, 0}).x;
    CHECK(under < 0.35f);  // L2 spherical harmonics cannot make the sky above a roof fully black
    CHECK(open > 0.95f);
    // a sun that the probe sees raises the irradiance on the normal that faces it
    BakeLight sun;
    sun.direction = {0, -1, 0};
    BakeScene lit;
    lit.lights = {sun};
    auto l = sample_irradiance_sh(lit, {{0, 0, 0}}, st);
    REQUIRE(l.ok());
    CHECK(sh_irradiance((*l)[0], {0, 1, 0}).x > 0.9f);
    CHECK(sh_irradiance((*l)[0], {0, -1, 0}).x < 0.3f);
    st.shIncludeDirect = false;
    auto noDirect = sample_irradiance_sh(lit, {{0, 0, 0}}, st);
    REQUIRE(noDirect.ok());
    CHECK(sh_irradiance((*noDirect)[0], {0, 1, 0}).x == 0.0f);
    // the same bits with a pool
    st.shIncludeDirect = true;
    auto again = sample_irradiance_sh(sc, pts, st);
    REQUIRE(jobs::start(jobs::Settings::threads(3)).ok());
    auto pooled = sample_irradiance_sh(sc, pts, st);
    jobs::stop();
    REQUIRE(again.ok());
    REQUIRE(pooled.ok());
    for (std::size_t i = 0; i < 2; ++i)
        for (int k = 0; k < 9; ++k) {
            CHECK((*again)[i].c[k].x == (*pooled)[i].c[k].x);
            CHECK((*again)[i].c[k].z == (*pooled)[i].c[k].z);
        }
}

// ---- M73.4c: progress callback, cancel in every phase, the finite checks, the automatic ray offset ----------------------------------

TEST_CASE("lightmap bake: the progress callback names every phase in order and ends at the last texel") {
    BakeScene sc = cornell();
    BakeSettings st = fast_settings();
    st.samples = 4;
    st.denoiseRadius = 1;
    st.dilatePasses = 2;
    std::vector<BakePhase> order;
    BakeProgress lastTrace;
    std::uint64_t lastRays = 0;
    bool raysGrow = true;
    auto fn = [&](const BakeProgress& p) {
        if (order.empty() || order.back() != p.phase) order.push_back(p.phase);
        if (p.phase == BakePhase::Trace) lastTrace = p;
        raysGrow = raysGrow && p.rays >= lastRays;
        lastRays = p.rays;
    };
    auto r = bake_lightmap(sc, st, fn);
    REQUIRE(r.ok());
    REQUIRE(order.size() >= 5);
    CHECK(order[0] == BakePhase::Prepare);
    CHECK(order[1] == BakePhase::Rasterize);
    CHECK(order[2] == BakePhase::Trace);
    CHECK(order[3] == BakePhase::Denoise);
    CHECK(order[4] == BakePhase::Dilate);
    CHECK(lastTrace.done == lastTrace.total);
    CHECK(lastTrace.total == r->stats.texels);
    CHECK(lastTrace.atlas == 1);
    CHECK(lastTrace.atlasCount == 1);
    CHECK(raysGrow);
    CHECK(lastRays == r->stats.rays);
}

TEST_CASE("lightmap bake: a cancel in any phase ends it with 'cancelled'") {
    const BakePhase phases[] = {BakePhase::Prepare, BakePhase::Rasterize, BakePhase::Trace, BakePhase::Denoise,
                                BakePhase::Dilate};
    for (BakePhase phase : phases) {
        CAPTURE(int(phase));
        BakeScene sc = cornell();
        BakeSettings st = fast_settings();
        st.samples = 4;
        st.denoiseRadius = 1;
        st.dilatePasses = 2;
        std::atomic<bool> flag{false};
        CommandCancelScope cancel(&flag);
        auto r = bake_lightmap(sc, st, [&](const BakeProgress& p) {
            if (p.phase == phase) flag = true;  // the phase has begun: the next look at the flag ends the bake
        });
        REQUIRE(!r.ok());
        CHECK(r.error().message == "cancelled");
    }
}

TEST_CASE("bvh: a cancelled build returns false and leaves an empty tree; an uncancelled one is complete") {
    std::vector<Vec3> corners;
    for (int i = 0; i < 400; ++i) {
        const float x = float(i % 20), z = float(i / 20);
        corners.push_back({x, 0, z});
        corners.push_back({x + 0.5f, 0, z});
        corners.push_back({x, 0, z + 0.5f});
    }
    TriBvh tree;
    std::atomic<bool> flag{true};
    CHECK_FALSE(tree.build(corners.data(), corners.size() / 3, &flag));
    RayHit hit;
    CHECK_FALSE(tree.closest({1.1f, 1, 1.1f}, {0, -1, 0}, 10.0f, -1, hit));
    flag = false;
    CHECK(tree.build(corners.data(), corners.size() / 3, &flag));
    CHECK(tree.closest({0.1f, 1, 0.1f}, {0, -1, 0}, 10.0f, -1, hit));
}

TEST_CASE("lightmap bake: non-finite rotation, soft radius and light sizes are refused with their field") {
    const float nan = std::nanf(""), inf = 1e30f * 1e30f;
    BakeSettings st = fast_settings();
    {
        BakeScene sc = cornell();
        sc.sky.image.width = 1;
        sc.sky.image.height = 1;
        sc.sky.image.rgb = {1, 1, 1};
        sc.sky.image.rotationDeg = nan;
        auto r = bake_lightmap(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("/sky/image/rotationDeg") != std::string::npos);
    }
    {
        BakeScene sc = cornell();
        sc.lights[0].softRadius = inf;
        auto r = bake_lightmap(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("softRadius") != std::string::npos);
    }
    {
        BakeScene sc = cornell();
        sc.lights[0].width = inf;  // not an area light, but the number is still garbage
        auto r = bake_lightmap(sc, st);
        REQUIRE(!r.ok());
        CHECK(r.error().message.find("width") != std::string::npos);
    }
    {
        BakeScene sc = cornell();
        sc.lights[0].height = nan;
        CHECK_FALSE(bake_lightmap(sc, st).ok());
    }
}

TEST_CASE("lightmap bake: the automatic ray offset follows the texel, not the size of the world") {
    // A 4 x 4 m floor at 16 texels per meter (texel 6 cm), a slab 2 cm above it, and a far triangle 1 km away that widens the scene: the
    // old offset (size / 10000 = 10 cm) started the shadow rays above the slab and lit the floor under it.
    BakeScene sc;
    sc.atlases = {{64, 64}};
    sc.meshes.push_back(quad("floor", {0, 0, 0}, {4, 0, 0}, {0, 0, 4}, {0, 1, 0}, 0, 0, 0, 1, 1));
    sc.meshes.push_back(quad("slab", {1.5f, 0.02f, 1.5f}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, -1, 0, 0, 0, 0));
    sc.meshes.push_back(quad("far", {1000, 0, 0}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0}, -1, 0, 0, 0, 0));
    BakeLight sun;
    sun.kind = BakeLightKind::Directional;
    sun.direction = {0, -1, 0};
    sun.intensity = 1;
    sc.lights = {sun};
    BakeSettings st = fast_settings();
    st.samples = 1;
    st.bounces = 0;
    auto r = bake_lightmap(sc, st);
    REQUIRE(r.ok());
    CHECK(texel(r->atlases[0], 32, 32).x < 0.05f);  // under the slab
    CHECK(texel(r->atlases[0], 4, 4).x > 0.9f);     // in the open
}
