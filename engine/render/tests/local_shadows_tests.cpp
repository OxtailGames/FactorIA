// M73.2b: the CPU side of the shadows of point and spot lights (src/local_shadows.h). No GPU: the faces of a cube, the budget of the
// shadow atlas, the projection of a tile and its depth convention, and the records in the light data texture.
#include <doctest.h>

#include <cmath>
#include <set>

#include "light_clusters.h"
#include "local_shadows.h"

using namespace fa;
using namespace fa::render;

namespace {
LocalShadowInput input(int light, Vec3 pos, float range, float spotAngle = 0.0f, float brightness = 1.0f,
                       int resolution = 0) {
    LocalShadowInput in;
    in.light = light;
    in.position = pos;
    in.range = range;
    in.spotAngle = spotAngle;
    in.brightness = brightness;
    in.resolution = resolution;
    return in;
}
bool overlaps(const ShadowTile& a, const ShadowTile& b) {
    return a.placed() && b.placed() && a.x < b.x + b.size && b.x < a.x + a.size && a.y < b.y + b.size &&
           b.y < a.y + a.size;
}
bool same_plan(const LocalShadowPlan& a, const LocalShadowPlan& b) {
    if (a.lights.size() != b.lights.size() || a.lost != b.lost || a.atlas.tiles.size() != b.atlas.tiles.size())
        return false;
    for (std::size_t i = 0; i < a.atlas.tiles.size(); ++i)
        if (a.atlas.tiles[i].x != b.atlas.tiles[i].x || a.atlas.tiles[i].y != b.atlas.tiles[i].y ||
            a.atlas.tiles[i].size != b.atlas.tiles[i].size)
            return false;
    for (std::size_t i = 0; i < a.lights.size(); ++i)
        if (a.lights[i].light != b.lights[i].light || a.lights[i].firstTile != b.lights[i].firstTile) return false;
    return true;
}
}  // namespace

TEST_CASE(
    "local shadows: the face of a direction is the axis of its largest component, and its tile holds the direction") {
    CHECK(cube_face_of({1, 0, 0}) == 0);
    CHECK(cube_face_of({-1, 0.5f, 0.2f}) == 1);
    CHECK(cube_face_of({0.1f, 2, -1}) == 2);
    CHECK(cube_face_of({0, -3, 1}) == 3);
    CHECK(cube_face_of({0.2f, 0.3f, 4}) == 4);
    CHECK(cube_face_of({0.2f, -0.3f, -4}) == 5);
    CHECK(cube_face_of({1, 1, 1}) == 0);  // a tie goes to the lower face
    // Every face looks along its axis and has an orthogonal up.
    for (int f = 0; f < kCubeFaces; ++f) {
        const CubeFace face = cube_face_basis(f);
        CHECK(length(face.forward) == doctest::Approx(1.0f));
        CHECK(dot(face.forward, face.up) == doctest::Approx(0.0f));
        CHECK(cube_face_of(face.forward) == f);
    }
    // A direction projected by the tile of its face lands inside the tile's square (|x| <= w, |y| <= w) with a positive w: the faces
    // cover the sphere with no gap. The same is true of the 8 corners of the cube and of a sweep of directions.
    const Vec3 origin{3, 2, -1};
    std::set<int> seen;
    for (bool zeroToOne : {false, true}) {
        const LocalTileFit fit[6] = {
            fit_local_tile(origin, cube_face_basis(0).forward, cube_face_basis(0).up, 1.0f, 256, 20.0f, zeroToOne),
            fit_local_tile(origin, cube_face_basis(1).forward, cube_face_basis(1).up, 1.0f, 256, 20.0f, zeroToOne),
            fit_local_tile(origin, cube_face_basis(2).forward, cube_face_basis(2).up, 1.0f, 256, 20.0f, zeroToOne),
            fit_local_tile(origin, cube_face_basis(3).forward, cube_face_basis(3).up, 1.0f, 256, 20.0f, zeroToOne),
            fit_local_tile(origin, cube_face_basis(4).forward, cube_face_basis(4).up, 1.0f, 256, 20.0f, zeroToOne),
            fit_local_tile(origin, cube_face_basis(5).forward, cube_face_basis(5).up, 1.0f, 256, 20.0f, zeroToOne)};
        for (int i = -4; i <= 4; ++i)
            for (int j = -4; j <= 4; ++j)
                for (int k = -4; k <= 4; ++k) {
                    const Vec3 d{float(i), float(j), float(k)};
                    if (i == 0 && j == 0 && k == 0) continue;
                    const int f = cube_face_of(d);
                    seen.insert(f);
                    const Vec4 clip = fit[f].viewProj * Vec4{origin.x + d.x, origin.y + d.y, origin.z + d.z, 1.0f};
                    CAPTURE(i);
                    CAPTURE(j);
                    CAPTURE(k);
                    CHECK(clip.w > 0.0f);
                    CHECK(std::fabs(clip.x) <= clip.w * 1.0001f);
                    CHECK(std::fabs(clip.y) <= clip.w * 1.0001f);
                }
    }
    CHECK(seen.size() == 6);
}

TEST_CASE("local shadows: a tile's depth is metres along its axis, and a texel is texelCoef times the distance wide") {
    const Vec3 pos{1, 4, 2};
    for (bool zeroToOne : {false, true}) {
        const LocalTileFit fit = fit_local_tile(pos, {0, 0, -1}, {0, 1, 0}, 1.0f, 512, 30.0f, zeroToOne);
        CHECK(fit.farPlane == doctest::Approx(30.0f));
        CHECK(fit.nearPlane == doctest::Approx(0.15f));  // range / 200
        for (float c : {0.5f, 3.0f, 12.0f, 29.0f}) {
            const Vec4 clip = fit.viewProj * Vec4{pos.x, pos.y, pos.z - c, 1.0f};
            CHECK(clip.w == doctest::Approx(c));  // the clip w IS the distance along the axis
            // The window depth the shadow pass stores (0..1 on every backend) turns back into metres.
            const float ndc = clip.z / clip.w;
            const float z = zeroToOne ? ndc : 0.5f * ndc + 0.5f;
            const float metres = fit.nearPlane * fit.farPlane / (fit.farPlane - z * (fit.farPlane - fit.nearPlane));
            CHECK(metres == doctest::Approx(c).epsilon(0.001));
        }
        // The guard band makes the tile a little wider than the face: kLocalShadowGuard texels at each edge of 512.
        const Vec4 edge = fit.viewProj * Vec4{pos.x + 10.0f, pos.y, pos.z - 10.0f, 1.0f};
        CHECK(edge.x / edge.w == doctest::Approx(1.0f * (256.0f - float(kLocalShadowGuard)) / 256.0f).epsilon(0.001));
        CHECK(fit.texelCoef == doctest::Approx(2.0f * (256.0f / (256.0f - float(kLocalShadowGuard))) / 512.0f));
    }
    // A tile of a spot: the near plane never passes half of the range, a tiny range is still valid.
    const LocalTileFit tiny = fit_local_tile(pos, {0, -1, 0}, {0, 0, 1}, 0.5f, 64, 0.02f, false);
    CHECK(tiny.farPlane >= 0.1f);
    CHECK(tiny.nearPlane < tiny.farPlane);
}

TEST_CASE("local shadows: the sample matrix takes a world position to its texel of the atlas, for GL and for the other "
          "backends") {
    const Vec3 pos{0, 0, 0};
    const LocalTileFit fit = fit_local_tile(pos, {0, 0, -1}, {0, 1, 0}, 1.0f, 256, 20.0f, true);
    ShadowTile tile;
    tile.x = 512;
    tile.y = 256;
    tile.size = 256;
    const int w = 1024, h = 1024;
    for (bool isGl : {false, true}) {
        const Mat4 s = local_sample_matrix(fit, tile, w, h, isGl);
        // The axis of the tile hits the middle of the tile, at the distance along it in w.
        const Vec4 mid = s * Vec4{0, 0, -5, 1};
        CHECK(mid.w == doctest::Approx(5.0f));
        CHECK(mid.x / mid.w == doctest::Approx((512.0f + 128.0f) / 1024.0f));
        const float vmid = isGl ? (1024.0f - 256.0f - 128.0f) / 1024.0f : (256.0f + 128.0f) / 1024.0f;
        CHECK(mid.y / mid.w == doctest::Approx(vmid));
        // Up in the world is up in the picture: a point above the axis has a smaller v from the top (D3D, Metal) and a larger one in GL.
        const Vec4 up = s * Vec4{0, 1, -5, 1};
        CHECK((up.y / up.w > vmid) == isGl);
    }
}

TEST_CASE("local shadows: importance falls with the distance to the camera and equal scores go by the light's index") {
    CHECK(local_shadow_importance(1, 10, 0) == doctest::Approx(1.0f));
    CHECK(local_shadow_importance(1, 10, 10) == doctest::Approx(0.5f));
    CHECK(local_shadow_importance(2, 10, 10) > local_shadow_importance(1, 10, 10));
    CHECK(local_shadow_importance(1, 20, 20) == doctest::Approx(0.5f));
    CHECK(local_shadow_importance(1, 10, 100) < local_shadow_importance(1, 10, 50));
    // The same scores: the lower table index first, whatever the order of the inputs.
    std::vector<LocalShadowInput> in{input(7, {5, 0, 0}, 10), input(3, {-5, 0, 0}, 10), input(5, {0, 5, 0}, 10)};
    const LocalShadowPlan plan = plan_local_shadows(4096, {}, in, {0, 0, 0});
    REQUIRE(plan.lights.size() == 3);
    CHECK(plan.lights[0].light == 3);
    CHECK(plan.lights[1].light == 5);
    CHECK(plan.lights[2].light == 7);
    // A nearer, brighter light goes before them.
    in.push_back(input(9, {1, 0, 0}, 10));
    CHECK(plan_local_shadows(4096, {}, in, {0, 0, 0}).lights[0].light == 9);
}

TEST_CASE("local shadows: the size of a tile follows the resolution of the light, or its distance from the camera") {
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30, 1, 512), 5) == 512);
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30, 1, 700), 5) == 512);  // down to a power of two
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30, 1, 5000), 5) == 2048);
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30, 1, 10), 5) == 64);
    // Automatic: 1024 for a spot and 512 per face of a cube while the camera is within the range, halving as it goes away.
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30), 5) == 1024);
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 0), 5) == 512);
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30), 20) == 512);
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30), 40) == 256);
    CHECK(local_shadow_wanted_tile(input(0, {0, 0, 0}, 10, 30), 100000) == 64);
    // A spot wider than the limit takes the cube.
    CHECK(local_light_is_cube(input(0, {0, 0, 0}, 10, 0)));
    CHECK(local_light_is_cube(input(0, {0, 0, 0}, 10, 80)));
    CHECK_FALSE(local_light_is_cube(input(0, {0, 0, 0}, 10, 45)));
}

TEST_CASE("local shadows: with room everything is placed, a point light takes six tiles, a spot one") {
    std::vector<LocalShadowInput> in{input(1, {0, 0, 0}, 10), input(2, {4, 0, 0}, 10, 40), input(3, {8, 0, 0}, 10, 85)};
    const std::vector<ShadowTileRequest> sun{{1024, 128, 0}, {1024, 128, 1}};
    const LocalShadowPlan plan = plan_local_shadows(4096, sun, in, {0, 0, 5});
    CHECK(plan.lost.empty());
    CHECK(plan.shrunkLights == 0);
    REQUIRE(plan.lights.size() == 3);
    CHECK(plan.atlas.tiles.size() == 2 + 6 + 1 + 6);
    int tiles = 0;
    for (const LocalShadowLight& l : plan.lights) {
        CHECK(l.firstTile == 2 + tiles);
        CHECK(l.tiles == (l.cube ? 6 : 1));
        tiles += l.tiles;
    }
    CHECK(tiles == 13);
    // The sun's tiles come first and keep their sizes; no tile overlaps another.
    CHECK(plan.atlas.tiles[0].size == 1024);
    CHECK(plan.atlas.tiles[1].size == 1024);
    for (std::size_t a = 0; a < plan.atlas.tiles.size(); ++a)
        for (std::size_t b = a + 1; b < plan.atlas.tiles.size(); ++b)
            CHECK_FALSE(overlaps(plan.atlas.tiles[a], plan.atlas.tiles[b]));
    // No local light: exactly the layout of the sun alone.
    const LocalShadowPlan alone = plan_local_shadows(4096, sun, {}, {0, 0, 5});
    const ShadowAtlasLayout expect = layout_shadow_atlas(4096, sun);
    REQUIRE(alone.atlas.tiles.size() == expect.tiles.size());
    for (std::size_t i = 0; i < expect.tiles.size(); ++i) {
        CHECK(alone.atlas.tiles[i].x == expect.tiles[i].x);
        CHECK(alone.atlas.tiles[i].y == expect.tiles[i].y);
        CHECK(alone.atlas.tiles[i].size == expect.tiles[i].size);
    }
    CHECK(alone.atlas.width == expect.width);
}

TEST_CASE(
    "local shadows: a full atlas shrinks the maps, then drops the least important light whole, the same every time") {
    // Twelve spot lights of 512 texels (a 4x3 of tiles of a 2048 atlas would hold sixteen of 512): an atlas of 1024 holds four.
    std::vector<LocalShadowInput> in;
    for (int i = 0; i < 12; ++i) in.push_back(input(i, {float(i), 0, 0}, 10, 30, 1, 512));
    const std::vector<ShadowTileRequest> sun{{512, 128, 0}};
    const LocalShadowPlan a = plan_local_shadows(1024, sun, in, {0, 0, 0});
    const LocalShadowPlan b = plan_local_shadows(1024, sun, in, {0, 0, 0});
    CHECK(same_plan(a, b));
    CHECK(a.atlas.width <= 1024);
    CHECK(a.atlas.height <= 1024);
    CHECK(a.shrunkLights > 0);  // smaller maps come first
    CHECK(a.lights.size() + a.lost.size() == 12);
    for (const LocalShadowLight& l : a.lights)
        for (int f = 0; f < l.tiles; ++f) CHECK(a.atlas.tiles[std::size_t(l.firstTile + f)].placed());
    // The order of the inputs does not change the result.
    std::vector<LocalShadowInput> reversed(in.rbegin(), in.rend());
    CHECK(same_plan(a, plan_local_shadows(1024, sun, reversed, {0, 0, 0})));
    // Six cubes (36 tiles) in an atlas that holds sixteen tiles of the least size (64): a light has all six faces or none.
    std::vector<LocalShadowInput> cubes;
    for (int i = 0; i < 6; ++i) cubes.push_back(input(i, {float(i) * 3, 0, 0}, 10, 0, 1, 256));
    const LocalShadowPlan c = plan_local_shadows(256, {}, cubes, {0, 0, 0});
    CHECK(c.lights.size() + c.lost.size() == 6);
    CHECK_FALSE(c.lost.empty());
    for (const LocalShadowLight& l : c.lights) {
        CHECK(l.tiles == 6);
        for (int f = 0; f < 6; ++f) CHECK(c.atlas.tiles[std::size_t(l.firstTile + f)].placed());
    }
    // The ones lost are the least important: the farthest from the camera at the origin, the highest table index.
    for (int lostLight : c.lost)
        for (const LocalShadowLight& l : c.lights) CHECK(lostLight > l.light);
}

TEST_CASE(
    "local shadows: in a full atlas the local tiles shrink and are dropped before the sun's cascades lose anything") {
    // Two cascades of 1024 fill the top half of a 2048 atlas. Twelve spots of 512 do not fit the other half (eight would): the spots
    // shrink, the cascades stay as asked.
    const std::vector<ShadowTileRequest> sun{{1024, 128, 0}, {1024, 128, 1}};
    std::vector<LocalShadowInput> in;
    for (int i = 0; i < 12; ++i) in.push_back(input(i, {float(i), 0, 0}, 10, 30, 1, 512));
    const LocalShadowPlan a = plan_local_shadows(2048, sun, in, {0, 0, 0});
    REQUIRE(a.atlas.tiles.size() >= 2);
    CHECK(a.atlas.tiles[0].size == 1024);
    CHECK(a.atlas.tiles[1].size == 1024);
    CHECK(a.lights.size() == 12);
    CHECK(a.lost.empty());
    CHECK(a.shrunkLights > 0);
    // Even the local tiles at their minimum cannot fit beside a sun that takes the whole atlas: every light is lost, the sun is whole.
    const std::vector<ShadowTileRequest> fullSun{{1024, 128, 0}};
    const LocalShadowPlan b = plan_local_shadows(1024, fullSun, in, {0, 0, 0});
    CHECK(b.atlas.tiles[0].size == 1024);
    CHECK(b.lights.empty());
    CHECK(b.lost.size() == 12);
    // With no local light the sun alone is laid out as before (its largest map shrinks first, by priority among equals).
    const std::vector<ShadowTileRequest> big{{2048, 128, 0}, {2048, 128, 1}};
    const LocalShadowPlan c = plan_local_shadows(2048, big, {}, {0, 0, 0});
    CHECK(c.atlas.shrunk > 0);
    CHECK(c.atlas.dropped == 0);
    CHECK(c.atlas.tiles[0].size >= c.atlas.tiles[1].size);
}

TEST_CASE("local shadows: the views of a frame are limited, the less important light past the limit is lost") {
    std::vector<LocalShadowInput> in{input(0, {0, 0, 0}, 10), input(1, {3, 0, 0}, 10), input(2, {6, 0, 0}, 10, 30)};
    const std::vector<ShadowTileRequest> sun{{512, 128, 0}, {512, 128, 1}};
    // 2 sun views + 6 + 6 = 14: with a limit of 10 the second cube is lost, and the spot (one tile) still fits.
    const LocalShadowPlan plan = plan_local_shadows(4096, sun, in, {0, 0, 0}, 10);
    REQUIRE(plan.lights.size() == 2);
    CHECK(plan.lights[0].light == 0);
    CHECK(plan.lights[1].light == 2);
    REQUIRE(plan.lost.size() == 1);
    CHECK(plan.lost[0] == 1);
    CHECK(plan.atlas.tiles.size() == 2 + 6 + 1);
    // The default limit is the 64 bits of a caster's mask.
    std::vector<LocalShadowInput> many;
    for (int i = 0; i < 20; ++i) many.push_back(input(i, {float(i), 0, 0}, 10));
    const LocalShadowPlan big = plan_local_shadows(8192, sun, many, {0, 0, 0});
    CHECK(big.atlas.tiles.size() <= std::size_t(kMaxShadowViews));
    CHECK(big.lost.size() == 20 - big.lights.size());
}

TEST_CASE("local shadows: the shadow region is one index texel per light and a record of 2 + 6 texels per tile") {
    LocalShadowRecord spot;
    spot.light = 1;
    spot.kind = 1;
    spot.fade = 40.0f;
    spot.filter = 2;
    spot.softness = 0.25f;
    spot.bias = 0.02f;
    spot.normalBias = 0.03f;
    LocalShadowTileRecord t;
    t.sample = Mat4::identity();
    t.sample.at(3, 0) = 7.0f;  // the first row of the matrix is (1, 0, 0, 7)
    t.rect = {0.1f, 0.2f, 0.3f, 0.4f};
    t.nearPlane = 0.05f;
    t.farPlane = 12.0f;
    t.texelCoef = 0.004f;
    spot.tiles.push_back(t);
    LocalShadowRecord cube = spot;
    cube.light = 3;
    cube.kind = 2;
    cube.tiles.assign(6, t);
    const std::vector<LocalShadowRecord> records{spot, cube};
    const int lights = 5;
    CHECK(local_shadow_region_texels(lights, {}) == 0);
    const std::size_t texels = local_shadow_region_texels(lights, records);
    CHECK(texels == std::size_t(lights) + (2 + 6) + (2 + 36));
    std::vector<float> data((texels + 3) * 4, 0.0f);
    const std::size_t base = 3;
    pack_local_shadow_region(lights, records, base, data.data());
    auto at = [&](std::size_t texel, int c) { return data[(base + texel) * 4 + std::size_t(c)]; };
    CHECK(at(0, 0) == -1.0f);
    CHECK(at(2, 0) == -1.0f);
    CHECK(at(4, 0) == -1.0f);
    CHECK(at(1, 0) == float(base + lights));  // the index texels hold the texel of the record: the spot's follows them
    CHECK(at(3, 0) == float(base + lights + 8));  // then the cube's
    const std::size_t s = std::size_t(lights);
    CHECK(at(s, 0) == 1.0f);
    CHECK(at(s, 1) == 40.0f);
    CHECK(at(s, 2) == 2.0f);
    CHECK(at(s, 3) == 0.25f);
    CHECK(at(s + 1, 0) == 0.02f);
    CHECK(at(s + 1, 1) == 0.03f);
    CHECK(at(s + 2, 0) == 1.0f);  // row 0 of the matrix: (1, 0, 0, 7)
    CHECK(at(s + 2, 3) == 7.0f);
    CHECK(at(s + 3, 1) == 1.0f);  // row 1: (0, 1, 0, 0)
    CHECK(at(s + 6, 0) == 0.1f);  // the rectangle
    CHECK(at(s + 6, 3) == 0.4f);
    CHECK(at(s + 7, 0) == 0.004f);  // texelCoef, near, far
    CHECK(at(s + 7, 1) == 0.05f);
    CHECK(at(s + 7, 2) == 12.0f);
    CHECK(at(s + 8, 0) == 2.0f);  // the cube's header
}

TEST_CASE("local shadows: with no records the light texture is the one it was before, with them the region follows the "
          "lists") {
    ClusterCamera cam;
    cam.widthPx = 320;
    cam.heightPx = 180;
    cam.nearDepth = 0.1f;
    cam.farDepth = 100.0f;
    LightData sun;
    sun.rank = 0;
    LightData lamp;
    lamp.pos = {0.0f, 2.0f, -6.0f, 8.0f};
    lamp.rank = 2;
    const std::vector<LightData> table{sun, lamp};
    LightTexture none, withEmpty, with;
    pack_light_texture(table, 1, cam, nullptr, none);
    const std::vector<LocalShadowRecord> empty;
    pack_light_texture(table, 1, cam, nullptr, withEmpty, &empty);
    CHECK(none.shadowBase == -1);
    CHECK(withEmpty.shadowBase == -1);
    CHECK(none.usedTexels == withEmpty.usedTexels);
    CHECK(none.texels == withEmpty.texels);
    LocalShadowRecord r;
    r.light = 1;
    r.tiles.resize(1);
    const std::vector<LocalShadowRecord> records{r};
    pack_light_texture(table, 1, cam, nullptr, with, &records);
    CHECK(with.shadowBase == static_cast<long long>(none.usedTexels));
    CHECK(with.usedTexels == none.usedTexels + local_shadow_region_texels(2, records));
    CHECK(with.texels[std::size_t(with.shadowBase) * 4] == -1.0f);  // the sun has no record
    CHECK(with.texels[(std::size_t(with.shadowBase) + 1) * 4] ==
          float(with.shadowBase + 2));  // the lamp's is after the two index texels
}
