// M75-P5a on a GPU: the Terrain component drawn by the mesh pipeline (renderer_terrain.h, shaders/terrain.glsl). The CPU side (loaders,
// sampling, the quadtree selection and the morph formula) is in ../../scene/tests/test_terrain.cpp and terrain_lod_tests.cpp.
// The tolerances hold on llvmpipe and WARP as well as on a real GPU; the two goldens are compared with the usual limits.
#include "test_util.h"

#include <algorithm>
#include <cmath>

#include "fa/scene/terrain.h"

using namespace fa;
using namespace fa::test;

namespace {

constexpr int kSamples = 129;
constexpr float kSide = 128.0f;  // metres: 1 m cells
constexpr float kScale = 40.0f;  // metres of a white sample

// A ridge along x (the same on every row): raw = 0.35 + 0.3 sin(1.5 turns over the side), so the top silhouette seen from the front is
// the profile itself, whatever the rows.
std::string write_ridge(const char* name, bool hill) {
    GrayImage16 g;
    g.width = g.height = kSamples;
    g.sixteenBit = true;
    g.samples.resize(std::size_t(kSamples) * kSamples);
    for (int r = 0; r < kSamples; ++r)
        for (int c = 0; c < kSamples; ++c) {
            double v = 0.35 + 0.3 * std::sin(6.283185307 * 1.5 * c / double(kSamples - 1));
            if (hill) {  // a cone in the middle: the golden's relief
                const double dx = (c - 64) / 64.0, dz = (r - 64) / 64.0;
                v = 0.15 + 0.5 * std::max(0.0, 1.0 - std::sqrt(dx * dx + dz * dz) * 1.4) + 0.04 * std::sin(c * 0.2) * std::cos(r * 0.17);
            }
            g.samples[std::size_t(r) * kSamples + std::size_t(c)] = std::uint16_t(std::clamp(v, 0.0, 1.0) * 65535.0);
        }
    const auto png = encode_png_gray16(g);
    const std::string file = fs::path_to_utf8(gfx().projectDir / name);
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
    return file;
}

void add_camera(World& w, Vec3 pos, float pitchDeg, bool ortho) {
    Entity cam = make(w, "cam", pos);
    auto& c = w.add<Camera>(cam);
    c.projection = ortho ? Projection::Orthographic : Projection::Perspective;
    c.fov = 60;
    c.orthoSize = 60.0f;
    c.farPlane = 2000.0f;
    w.get<Transform>(cam)->rotation = {pitchDeg, 0, 0};
}

Entity add_sun(World& w, bool shadows) {
    Entity sun = make(w, "sun", {0, 50, 0});
    w.get<Transform>(sun)->rotation = {-50, 35, 0};
    auto& l = w.add<Light>(sun);
    l.type = LightType::Directional;
    l.intensity = 1.6f;
    l.castShadows = shadows;
    return sun;
}

Entity add_terrain(World& w, const std::string& file) {
    Entity e = make(w, "ground", {0, 0, 0});
    auto& t = w.add<Terrain3D>(e);
    t.heightmap = file;
    t.size = {kSide, kSide};
    t.heightScale = kScale;
    return e;
}

float diff_from(const Color& a, const Color& b) {
    return std::max({std::fabs(a.r - b.r), std::fabs(a.g - b.g), std::fabs(a.b - b.b)});
}

}  // namespace

TEST_CASE("terrain: the drawn silhouette follows the CPU heights, and the stats count the tiles") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(g.renderer.supports("terrain"));
    const std::string file = write_ridge("terrain_ridge.png", false);
    World w;
    const float pitch = -30.0f;
    const Vec3 camPos{0, 40, 60};
    add_camera(w, camPos, pitch, true);
    add_sun(w, false);
    w.settings().ambientLight = Color{0.3f, 0.3f, 0.3f, 1};
    Entity ground = add_terrain(w, file);
    const Image img = g.render(w);
    const RenderStats st = g.renderer.stats();
    CHECK(st.terrainTiles > 0);
    CHECK(st.terrainTriangles == st.terrainTiles * 2048);
    CHECK(st.triangles >= st.terrainTriangles);
    CHECK(st.meshes == 0);
    // The far edge (z = -64) is the top of the terrain on screen: an orthographic camera pitched by 30 degrees puts a point at
    // v = (y - cam.y) cos(p) + (z_cam - z) sin(p) above the middle of the picture, 90 / orthoSize pixels per metre.
    const float cs = std::cos(radians(-pitch)), sn = std::sin(radians(-pitch));
    const Color sky = img.pixel(1, 1);
    int checked = 0;
    for (int px = 20; px < img.width - 20; px += 7) {
        const float x = (float(px) + 0.5f - 160.0f) / 160.0f * (60.0f * 320.0f / 180.0f);
        if (std::fabs(x) > 62.0f) continue;
        float h = 0;
        REQUIRE(terrain_height_at(w, ground, x, -64.0f, h));
        const float v = (h - camPos.y) * cs + (camPos.z + 64.0f) * sn;
        const float expectRow = 90.0f - v * (90.0f / 60.0f);
        int top = -1;
        for (int py = 0; py < img.height; ++py)
            if (diff_from(img.pixel(px, py), sky) > 0.04f) {
                top = py;
                break;
            }
        CAPTURE(px);
        CAPTURE(x);
        REQUIRE(top >= 0);
        CHECK(std::fabs(float(top) - expectRow) < 2.5f);
        ++checked;
    }
    CHECK(checked > 15);
}

TEST_CASE("terrain: a terrain with nothing to draw costs nothing, and removing one frees its texture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    add_camera(w, {0, 40, 60}, -30.0f, false);
    add_sun(w, false);
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles == 0);
    CHECK(g.renderer.stats().terrainTriangles == 0);
    const std::string file = write_ridge("terrain_ridge2.png", false);
    Entity ground = add_terrain(w, file);
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles > 0);
    // a flat terrain (no heightmap) is a flat terrain at heightOffset
    w.get<Terrain3D>(ground)->heightmap.clear();
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles > 0);
    w.get<Terrain3D>(ground)->size = {0.0f, 10.0f};  // not drawable: terrain_problems says why
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles == 0);
    w.destroy(ground);
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles == 0);
}

TEST_CASE("terrain: a sculpt (mark_dirty) shows in the next frame, and a coarser lodQuality draws fewer tiles") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = write_ridge("terrain_hill.png", true);
    World w;
    add_camera(w, {0, 45, 90}, -30.0f, false);
    add_sun(w, false);
    Entity ground = add_terrain(w, file);
    const Image before = g.render(w);
    const int tiles = g.renderer.stats().terrainTiles;
    REQUIRE(tiles > 0);
    std::string problem;
    auto heights = w.terrain().heights(w, ground, &problem);
    REQUIRE(heights);
    TerrainRect rect{0, 0, 128, 40};  // the whole far strip: the hill's back
    for (int r = rect.r0; r <= rect.r1; ++r)
        for (int c = rect.c0; c <= rect.c1; ++c) heights->set(c, r, 60000);
    heights->mark_dirty(rect);
    const Image after = g.render(w);
    int changed = 0;
    for (int y = 0; y < before.height; ++y)
        for (int x = 0; x < before.width; ++x)
            if (diff_from(before.pixel(x, y), after.pixel(x, y)) > 0.03f) ++changed;
    CHECK(changed > 500);
    w.get<Terrain3D>(ground)->lodQuality = 0.25f;
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles <= tiles);
    w.get<Terrain3D>(ground)->lodQuality = 2.0f;
    g.render(w);
    CHECK(g.renderer.stats().terrainTiles >= tiles);
}

TEST_CASE("terrain: golden from a low and a high camera, shadows on") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string file = write_ridge("terrain_hill_golden.png", true);
    for (const bool high : {false, true}) {
        World w;
        add_camera(w, high ? Vec3{0, 150, 120} : Vec3{0, 14, 80}, high ? -45.0f : -12.0f, false);
        add_sun(w, true);
        w.settings().ambientLight = Color{0.25f, 0.27f, 0.3f, 1};
        add_terrain(w, file);
        const Image img = g.render(w);
        CHECK(g.renderer.stats().terrainTiles > 0);
        expect_golden(img, high ? "3d_terrain_high" : "3d_terrain_low", 0.006);
    }
}
