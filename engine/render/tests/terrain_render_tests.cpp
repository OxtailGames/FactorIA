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
                v = 0.15 + 0.5 * std::max(0.0, 1.0 - std::sqrt(dx * dx + dz * dz) * 1.4) +
                    0.04 * std::sin(c * 0.2) * std::cos(r * 0.17);
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
    {
        // The limits the terrain's layers, splat maps and holes need are in the report: 8 layers and 3 control slices of 4096 pixels.
        const Json limits = g.renderer.supports_report()["limits"];
        CHECK(limits["maxTextureSize"].get<int>() >= 2048);
        CHECK(limits["maxArrayLayers"].get<int>() >= 8);
        CHECK(limits["maxArrayTextureSize"].get<int>() >= 2048);
    }
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
    // The first sculpt made the texture one that takes copies; the next one sends only its rectangle (not the 33 KB of the whole texture).
    const auto upBefore = g.renderer.terrain_uploads();
    TerrainRect small{60, 100, 70, 110};
    for (int r = small.r0; r <= small.r1; ++r)
        for (int c = small.c0; c <= small.c1; ++c) heights->set(c, r, 20000);
    heights->mark_dirty(small);
    const Image carved = g.render(w);
    const auto upAfter = g.renderer.terrain_uploads();
    CHECK(upAfter.rects == upBefore.rects + 1);
    CHECK(upAfter.whole == upBefore.whole);
    int carvedPixels = 0;
    for (int y = 0; y < after.height; ++y)
        for (int x = 0; x < after.width; ++x)
            if (diff_from(after.pixel(x, y), carved.pixel(x, y)) > 0.03f) ++carvedPixels;
    CHECK(carvedPixels > 20);
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

// ---- M75-P5d: layers blended by splat maps, and holes ----

namespace {

// A flat terrain file (every sample at 0.1 of the scale: 4 m) and a solid RGBA picture, both written into the test project.
std::string write_flat(const char* name) {
    GrayImage16 g;
    g.width = g.height = kSamples;
    g.sixteenBit = true;
    g.samples.assign(std::size_t(kSamples) * kSamples, std::uint16_t(0.1 * 65535.0));
    const auto png = encode_png_gray16(g);
    const std::string file = fs::path_to_utf8(gfx().projectDir / name);
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
    return file;
}

std::string write_solid(const char* name, int size, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    Image img;
    img.width = img.height = size;
    img.rgba.resize(std::size_t(size) * std::size_t(size) * 4);
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) {
        img.rgba[i] = r;
        img.rgba[i + 1] = g;
        img.rgba[i + 2] = b;
        img.rgba[i + 3] = 255;
    }
    const auto png = encode_png(img);
    const std::string file = fs::path_to_utf8(gfx().projectDir / name);
    REQUIRE(fs::write_bytes(file, png.data(), png.size()).ok());
    return file;
}

// A camera straight above the middle of the terrain, orthographic: one pixel is 0.667 m, the picture is 213 x 120 m.
void add_top_camera(World& w) { add_camera(w, {0, 100, 0}, -90.0f, true); }

// The pixel of the world position (x, z) seen by add_top_camera (the terrain's -Z edge is the top of the picture).
Color top_pixel(const Image& img, float x, float z) {
    const int px = int(std::floor(160.0f + x * 1.5f));
    const int py = int(std::floor(90.0f + z * 1.5f));
    return img.pixel(px, py);
}

}  // namespace

TEST_CASE("terrain: two layers blended by a splat map, normalised, and layer 0 alone without a map") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string flat = write_flat("terrain_flat_layers.png");
    World w;
    add_top_camera(w);
    Entity sun = add_sun(w, false);
    w.get<Transform>(sun)->rotation = {-90, 0, 0};
    w.settings().ambientLight = Color{0.2f, 0.2f, 0.2f, 1};
    Entity ground = add_terrain(w, flat);
    {
        auto& t = *w.get<Terrain3D>(ground);
        t.layers = Json::array();
        t.layers.push_back(Json{{"albedo", write_solid("terrain_red.png", 8, 230, 20, 20)}, {"tileSize", 8.0}});
        t.layers.push_back(Json{{"albedo", write_solid("terrain_blue.png", 8, 20, 20, 230)}, {"tileSize", 8.0}});
    }
    // No splat map: layer 0 (red) everywhere.
    Image img = g.render(w);
    const Color a = top_pixel(img, -40.0f, 20.0f), b = top_pixel(img, 40.0f, -20.0f);
    CHECK(a.r > a.b + 0.1f);
    CHECK(b.r > b.b + 0.1f);
    CHECK(diff_from(a, b) < 0.03f);
    const std::uint64_t builtBefore = g.renderer.terrain_uploads().arrays;
    // A 4 x 4 splat map: the two left columns paint layer 0 (channel R), the two right ones layer 1 (channel G).
    std::string problem;
    auto heights = w.terrain().heights(w, ground, &problem);
    REQUIRE(heights);
    TerrainSplat& map = heights->splat[0];
    map.size = 4;
    map.rgba.assign(4 * 4 * 4, 0);
    for (int y = 0; y < 4; ++y)
        for (int x = 0; x < 4; ++x) map.rgba[std::size_t(y * 4 + x) * 4 + (x < 2 ? 0u : 1u)] = 255;
    ++map.version;
    img = g.render(w);
    const Color left = top_pixel(img, -40.0f, 10.0f), right = top_pixel(img, 40.0f, 10.0f),
                mid = top_pixel(img, 0.0f, 10.0f);
    CHECK(left.r > left.b + 0.1f);
    CHECK(right.b > right.r + 0.1f);
    // Halfway between the two texels' centres the weights are half and half: both colours show.
    CHECK(mid.r > 0.05f);
    CHECK(mid.b > 0.05f);
    CHECK(std::fabs(mid.r - mid.b) < 0.5f * std::fabs(left.r - left.b));
    CHECK(g.renderer.terrain_uploads().arrays > builtBefore);
    // The weights are normalised: 100 + 100 (of 255 each) is half and half, not two dim layers.
    for (int i = 0; i < 16; ++i) {
        map.rgba[std::size_t(i) * 4] = 100;
        map.rgba[std::size_t(i) * 4 + 1] = 100;
    }
    ++map.version;
    img = g.render(w);
    const Color halves = top_pixel(img, 0.0f, 10.0f), far = top_pixel(img, 50.0f, -30.0f);
    CHECK(diff_from(halves, far) < 0.03f);
    CHECK(std::fabs(halves.r - halves.b) < 0.05f);
    CHECK(halves.r > 0.1f);
    // Nothing changed: no array is made again.
    const std::uint64_t built = g.renderer.terrain_uploads().arrays;
    g.render(w);
    CHECK(g.renderer.terrain_uploads().arrays == built);
}

TEST_CASE("terrain: a hole shows what is behind it, and the shadow has the hole too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    const std::string flat = write_flat("terrain_flat_holes.png");
    // The cells 48..79 on both axes are the hole: x and z from -16 to 16 m.
    auto cut = [&](World& w, Entity ground) {
        std::string problem;
        auto heights = w.terrain().heights(w, ground, &problem);
        REQUIRE(heights);
        heights->holes.assign(std::size_t(128) * 128, 0);
        for (int r = 48; r < 80; ++r)
            for (int c = 48; c < 80; ++c) heights->holes[std::size_t(r) * 128 + std::size_t(c)] = 1;
        ++heights->holesVersion;
    };
    {
        World w;
        add_top_camera(w);
        Entity sun = add_sun(w, false);
        w.get<Transform>(sun)->rotation = {-90, 0, 0};
        Entity ground = add_terrain(w, flat);
        const Image whole = g.render(w);
        const Color terrainColor = top_pixel(whole, 0.0f, 0.0f);
        const Color sky = whole.pixel(1, 1);
        CHECK(diff_from(terrainColor, sky) > 0.05f);
        cut(w, ground);
        const Image holed = g.render(w);
        CHECK(diff_from(top_pixel(holed, 0.0f, 0.0f), sky) < 0.02f);
        CHECK(diff_from(top_pixel(holed, -10.0f, 12.0f), sky) < 0.02f);
        CHECK(diff_from(top_pixel(holed, 12.0f, -10.0f), sky) < 0.02f);
        // Outside the hole, to its very edge, the ground is still there.
        CHECK(diff_from(top_pixel(holed, 20.0f, 0.0f), terrainColor) < 0.03f);
        CHECK(diff_from(top_pixel(holed, 0.0f, -20.0f), terrainColor) < 0.03f);
        CHECK(diff_from(top_pixel(holed, -50.0f, 50.0f), terrainColor) < 0.03f);
        // Closing the hole again.
        auto heights = w.terrain().heights(w, ground, nullptr);
        std::fill(heights->holes.begin(), heights->holes.end(), std::uint8_t(0));
        ++heights->holesVersion;
        CHECK(diff_from(top_pixel(g.render(w), 0.0f, 0.0f), terrainColor) < 0.02f);
    }
    {
        // A floor under the terrain: seen through the hole it is as bright with the terrain's shadow as without it (the shadow map has the
        // hole too).
        World w;
        add_top_camera(w);
        Entity sun = add_sun(w, true);
        w.get<Transform>(sun)->rotation = {-90, 0, 0};
        Entity floorE = make(w, "floor", {0, -5, 0});
        auto& m = w.add<MeshRenderer>(floorE);
        m.mesh = "cube";
        m.color = Color{0.05f, 0.4f, 0.1f, 1.0f};
        w.get<Transform>(floorE)->scale = {400, 1, 400};
        Entity ground = add_terrain(w, flat);
        cut(w, ground);
        const Image img = g.render(w);
        // The same picture with a terrain that casts no shadow: what the floor looks like where nothing shades it.
        w.get<Terrain3D>(ground)->castShadows = false;
        const Image unshaded = g.render(w);
        for (const Vec2 at : {Vec2{0.0f, 0.0f}, Vec2{-8.0f, 8.0f}, Vec2{9.0f, -9.0f}})
            CHECK(diff_from(top_pixel(img, at.x, at.y), top_pixel(unshaded, at.x, at.y)) < 0.02f);
        CHECK(diff_from(top_pixel(img, 40.0f, 0.0f), top_pixel(img, 0.0f, 0.0f)) >
              0.1f);  // the terrain itself, not the floor
    }
}
