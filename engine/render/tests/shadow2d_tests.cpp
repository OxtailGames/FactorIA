// M74.1 soft 2D shadows and ShadowCaster2D: the contour of an alpha image, the rows casters add to a light's distances, the
// penumbra of a light with a size, light layers, self-shadowing, more than 32 shadowed lights, the caches (docs/rendering/
// RENDERING_2D_SHADOWS.md). Default camera: the 320x180 target shows world (x, y) at pixel (160 + x, 90 - y).
#include "test_util.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/log.h"

#include "../src/frame.h"
#include "../src/render_internal.h"
#include "../src/renderer_test_access.h"
#include "../src/shadow2d.h"
#include "fa/scene/tilemap.h"

using namespace fa;
using namespace fa::test;
using namespace fa::render;

namespace {

// ------------------------------------------------------------------------------------------------ pure functions

CasterSet one_box(float x0, float y0, float x1, float y1, bool selfShadow, std::int32_t layers = -1) {
    CasterSet set;
    ShadowBody b;
    b.first = std::uint32_t(set.segs.size());
    set.segs.push_back({x0, y0, x1, y0});
    set.segs.push_back({x1, y0, x1, y1});
    set.segs.push_back({x1, y1, x0, y1});
    set.segs.push_back({x0, y1, x0, y0});
    b.count = 4;
    b.x0 = x0;
    b.y0 = y0;
    b.x1 = x1;
    b.y1 = y1;
    b.layers = layers;
    b.selfShadow = selfShadow;
    b.hash = 7;
    set.bodies.push_back(b);
    return set;
}

std::vector<float> fresh_row(float radius) { return std::vector<float>(std::size_t(kShadowAngles), radius); }

}  // namespace

TEST_CASE("contour_from_alpha: a square, a ring, a threshold") {
    std::vector<std::uint8_t> a(16 * 16, 0);
    for (int y = 4; y < 12; ++y)
        for (int x = 4; x < 12; ++x) a[std::size_t(y * 16 + x)] = 255;
    ContourLoops loops = contour_from_alpha(a.data(), 16, 16, 0.5f, 64);
    REQUIRE(loops.size() == 1);
    CHECK(loops[0].size() >= 4);
    CHECK(loops[0].size() <= 8);  // a square simplifies to its corners
    float x0 = 99, x1 = -99, y0 = 99, y1 = -99;
    for (const Vec2& p : loops[0]) {
        x0 = std::min(x0, p.x);
        x1 = std::max(x1, p.x);
        y0 = std::min(y0, p.y);
        y1 = std::max(y1, p.y);
    }
    CHECK(x0 == doctest::Approx(4.0f).epsilon(0.1));
    CHECK(x1 == doctest::Approx(12.0f).epsilon(0.1));
    CHECK(y0 == doctest::Approx(4.0f).epsilon(0.1));
    CHECK(y1 == doctest::Approx(12.0f).epsilon(0.1));

    // A hole inside is a second loop.
    for (int y = 7; y < 9; ++y)
        for (int x = 7; x < 9; ++x) a[std::size_t(y * 16 + x)] = 0;
    CHECK(contour_from_alpha(a.data(), 16, 16, 0.5f, 64).size() == 2);

    // Half-transparent pixels are inside only below the threshold.
    std::vector<std::uint8_t> soft(16 * 16, 0);
    for (int y = 4; y < 12; ++y)
        for (int x = 4; x < 12; ++x) soft[std::size_t(y * 16 + x)] = 100;
    CHECK(contour_from_alpha(soft.data(), 16, 16, 0.5f, 64).empty());
    CHECK(contour_from_alpha(soft.data(), 16, 16, 0.3f, 64).size() == 1);
    CHECK(contour_from_alpha(a.data(), 0, 0, 0.5f, 64).empty());

    // A disc: many pixels on its edge, few points after simplification, and never more than the budget.
    std::vector<std::uint8_t> disc(64 * 64, 0);
    for (int y = 0; y < 64; ++y)
        for (int x = 0; x < 64; ++x)
            if ((x - 31.5f) * (x - 31.5f) + (y - 31.5f) * (y - 31.5f) < 28.0f * 28.0f)
                disc[std::size_t(y * 64 + x)] = 255;
    const ContourLoops dl = contour_from_alpha(disc.data(), 64, 64, 0.5f, 24);
    REQUIRE(dl.size() == 1);
    CHECK(dl[0].size() <= 24);
    CHECK(dl[0].size() >= 8);
    // Deterministic: the same pixels give the same points.
    const ContourLoops again = contour_from_alpha(disc.data(), 64, 64, 0.5f, 24);
    REQUIRE(again.size() == 1);
    REQUIRE(again[0].size() == dl[0].size());
    for (std::size_t i = 0; i < dl[0].size(); ++i) {
        CHECK(again[0][i].x == dl[0][i].x);
        CHECK(again[0][i].y == dl[0][i].y);
    }
}

TEST_CASE("cast_casters: the near face with selfShadow, the far face without, a light inside is not blocked") {
    const CasterSet farFace = one_box(10, -5, 20, 5, false);
    const CasterSet nearFace = one_box(10, -5, 20, 5, true);
    const std::vector<std::uint32_t> list{0};
    std::vector<float> row = fresh_row(100);
    cast_casters(farFace, list, 0, 0, 100, row.data());
    CHECK(row[0] == doctest::Approx(20.0f).epsilon(0.01));  // east: the ray leaves the box at x = 20
    CHECK(row[std::size_t(kShadowAngles / 4)] == 100.0f);   // north: nothing there
    CHECK(row[std::size_t(kShadowAngles / 2)] == 100.0f);   // west: nothing there
    row = fresh_row(100);
    const std::uint64_t work = cast_casters(nearFace, list, 0, 0, 100, row.data());
    CHECK(row[0] == doctest::Approx(10.0f).epsilon(0.01));  // east: the ray meets the box at x = 10
    CHECK(work > 0);
    CHECK(work < 1024);  // the angles the box covers, never 4 x all 1024
    // The same twice: the work is a count.
    row = fresh_row(100);
    CHECK(cast_casters(nearFace, list, 0, 0, 100, row.data()) == work);

    // A ray through a corner of the box is neither missed nor counted twice: a box edge-on to the ray stays continuous.
    row = fresh_row(100);
    cast_casters(farFace, list, 0, 0, 100, row.data());
    int dark = 0;
    for (int i = 0; i < kShadowAngles / 8; ++i) dark += row[std::size_t(i)] < 100.0f ? 1 : 0;
    // The box spans atan(5/10) = 26.6 degrees on each side of east: 75.7 texels one side.
    CHECK(dark >= 70);
    CHECK(dark <= 80);
    // No texel holds a zero-length spike (a ray that "hit" at distance 0).
    for (float d : row) CHECK(d > 9.0f);

    // The light inside the outline: the caster does not block it.
    const CasterSet around = one_box(-5, -5, 5, 5, true);
    row = fresh_row(100);
    cast_casters(around, list, 0, 0, 100, row.data());
    for (float d : row) CHECK(d == 100.0f);

    // Out of reach: nothing is touched and almost no work is done.
    row = fresh_row(5);
    CHECK(cast_casters(farFace, list, 0, 0, 5, row.data()) == 0);
}

TEST_CASE("casters_in_reach: reach, light layers, the per-light cap") {
    const CasterSet set = one_box(10, -5, 20, 5, false, 2);
    std::vector<std::uint32_t> out;
    bool over = false;
    casters_in_reach(set, 0, 0, 100, -1, out, over);
    CHECK(out.size() == 1);
    casters_in_reach(set, 0, 0, 100, 2, out, over);
    CHECK(out.size() == 1);
    casters_in_reach(set, 0, 0, 100, 1, out, over);  // no bit in common: the light shines through
    CHECK(out.empty());
    casters_in_reach(set, 0, 0, 9, -1, out, over);  // the disc stops before the box
    CHECK(out.empty());
    CHECK_FALSE(over);

    // The work of 100 casters and 64 lights is a count of segment/angle pairs far under 100 x 64 x 4 x 1024.
    CasterSet many;
    for (int i = 0; i < 100; ++i) {
        const CasterSet b = one_box(float(i % 10) * 30.0f, float(i / 10) * 30.0f, float(i % 10) * 30.0f + 12.0f,
                                    float(i / 10) * 30.0f + 12.0f, false);
        ShadowBody body = b.bodies[0];
        body.first = std::uint32_t(many.segs.size());
        many.segs.insert(many.segs.end(), b.segs.begin(), b.segs.end());
        many.bodies.push_back(body);
    }
    std::uint64_t work = 0;
    for (int l = 0; l < 64; ++l) {
        const float px = 20.0f + float(l % 8) * 35.0f, py = 20.0f + float(l / 8) * 35.0f;
        casters_in_reach(many, px, py, 90, -1, out, over);
        std::vector<float> row = fresh_row(90);
        work += cast_casters(many, out, px, py, 90, row.data());
    }
    CHECK(work < 64u * 100u * 4u * 120u);
    CHECK(work > 0);
}

// ------------------------------------------------------------------------------------------------ renders

namespace {

Image solid_image(int w, int h, Color c) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * std::size_t(h) * 4);
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x) img.set_pixel(x, y, c);
    return img;
}

Entity camera_at(World& w) {
    Entity cam = make(w, "cam", {0, 0, 0});
    w.add<Camera>(cam).clearColor = Color::black();
    return cam;
}

Entity lit_sprite(World& w, Vec3 pos, Vec2 size) {
    Entity e = make(w, "floor", pos);
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/white16.png";
    sp.size = size;
    sp.lit = true;
    return e;
}

// A flat lit floor over the whole view with no ambient light: only the lights show.
void lit_floor(World& w) {
    camera_at(w);
    w.settings().ambientLight = Color{0, 0, 0, 1};
    lit_sprite(w, {0, 0, 0}, {320, 180});
}

Entity lamp(World& w, Vec3 pos, float radius, float size, float falloff = 0.01f) {
    Entity e = make(w, "lamp", pos);
    auto& l = w.add<Light2D>(e);
    l.radius = radius;
    l.falloff = falloff;
    l.castShadows = true;
    l.size = size;
    return e;
}

Entity box_caster(World& w, Vec3 pos, Vec2 size, bool selfShadow = false) {
    Entity e = make(w, "caster", pos);
    auto& c = w.add<ShadowCaster2D>(e);
    c.shape = ShadowCaster2DShape::Box;
    c.size = size;
    c.selfShadow = selfShadow;
    return e;
}

float at(const Image& img, float x, float y) { return img.pixel(int(160 + x), int(90 - y)).r; }

// The number of pixels of column x (world) from y = 0 up whose brightness is between 10% and 90% of the lit value.
int penumbra_pixels(const Image& img, float x) {
    const float lit = at(img, x, 85);
    int n = 0;
    for (int y = 0; y < 88; ++y) {
        const float v = at(img, x, float(y));
        if (v > 0.1f * lit && v < 0.9f * lit) ++n;
    }
    return n;
}

}  // namespace

TEST_CASE("soft shadows: the penumbra grows with Light2D.size and size 0 is a hard edge") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    int widths[4] = {};
    const float sizes[4] = {0.0f, 2.0f, 4.0f, 8.0f};
    for (int k = 0; k < 4; ++k) {
        World w;
        lit_floor(w);
        lamp(w, {-150, 0, 0}, 600, sizes[k]);
        box_caster(w, {-100, 0, 0}, {10, 20});
        Image img = g.render(w);
        widths[k] = penumbra_pixels(img, 140);
        // The umbra is dark and the open floor is lit whatever the size.
        CHECK(at(img, 140, 0) < 0.05f);
        CHECK(at(img, 140, 85) > 0.7f);
        CHECK(g.renderer.stats().lights2dShadowed == 1);
    }
    CHECK(widths[0] <= 3);
    CHECK(widths[1] > widths[0] + 8);
    CHECK(widths[2] > widths[1] + 8);
    CHECK(widths[3] > widths[2] + 8);
}

TEST_CASE("soft shadows: the penumbra widens with the distance past the occluder") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    World w;
    lit_floor(w);
    lamp(w, {-150, 0, 0}, 600, 3.0f);
    box_caster(w, {-120, 0, 0}, {6, 12});
    Image img = g.render(w);
    const int nearW = penumbra_pixels(img, -60), farW = penumbra_pixels(img, 140);
    CHECK(farW > nearW + 4);
}

TEST_CASE("ShadowCaster2D: a box, a polygon and the alpha of a sprite block light; selfShadow, layers and the disabled "
          "flag") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    // A 32x32 disc: opaque in the middle, transparent in the corners.
    Image disc = solid_image(32, 32, Color{1, 1, 1, 0});
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x)
            if ((x - 15.5f) * (x - 15.5f) + (y - 15.5f) * (y - 15.5f) < 13.0f * 13.0f)
                disc.set_pixel(x, y, Color::white());
    REQUIRE(save_png(disc, "assets/disc32.png").ok());

    // spriteAlpha: the disc's shadow is narrower than the sprite's square would make it.
    {
        World w;
        lit_floor(w);
        lamp(w, {-100, 0, 0}, 600, 0.0f);
        Entity e = make(w, "ball", {0, 0, 0});
        auto& sp = w.add<Sprite>(e);
        sp.texture = "assets/disc32.png";
        sp.color = Color{1, 1, 1, 0};  // invisible: only its shadow shows
        sp.size = {32, 32};
        w.add<ShadowCaster2D>(e);
        Image img = g.render(w);
        CHECK(at(img, 60, 0) < 0.05f);  // behind the disc
        CHECK(at(img, 60, 25) > 0.7f);  // a square of the same size would reach y = 30 here
        CHECK(at(img, 60, -25) > 0.7f);
        // The contour is made once: a second frame and a moved sprite reuse it.
        // (compared with the count before: the Gfx singleton keeps the renderer, and its cache, across test cases)
        const int made = render::renderer_shadow_rows_stats(g.renderer).contours;
        CHECK(made >= 1);
        g.render(w);
        CHECK(render::renderer_shadow_rows_stats(g.renderer).contours == made);
        w.get<Transform>(e)->position = {10, 5, 0};
        g.render(w);
        CHECK(render::renderer_shadow_rows_stats(g.renderer).contours == made);
        // A flipped sprite is the same contour mirrored.
        w.get<Sprite>(e)->flipX = true;
        g.render(w);
        CHECK(render::renderer_shadow_rows_stats(g.renderer).contours == made);
        // A higher threshold than any alpha: nothing blocks (a new contour, empty).
        w.get<ShadowCaster2D>(e)->alphaThreshold = 1.0f;
        w.get<Transform>(e)->position = {0, 0, 0};
        Image open = g.render(w);
        CHECK(at(open, 60, 0) > 0.7f);
    }

    // polygon: a triangle pointing at the light.
    {
        World w;
        lit_floor(w);
        lamp(w, {-100, 0, 0}, 600, 0.0f);
        Entity e = make(w, "tri", {0, 0, 0});
        auto& c = w.add<ShadowCaster2D>(e);
        c.shape = ShadowCaster2DShape::Polygon;
        const float pts[] = {-10, 0, 10, 20, 10, -20};
        c.points.assign(pts, 6);
        Image img = g.render(w);
        CHECK(at(img, 60, 0) < 0.05f);
        CHECK(at(img, 60, 50) > 0.7f);  // the shadow reaches y = +-20 * 160/110 = 29 at x = 60
        // The same polygon turned off.
        w.get<ShadowCaster2D>(e)->enabled = false;
        img = g.render(w);
        CHECK(at(img, 60, 0) > 0.7f);
        CHECK(g.renderer.stats().lights2dShadowed == 0);
    }

    // light layers: a caster on layer 2 does not block a light on layer 1, and does block one on layer 2.
    {
        World w;
        lit_floor(w);
        Entity l = lamp(w, {-100, 0, 0}, 600, 0.0f);
        Entity c = box_caster(w, {0, 0, 0}, {20, 20});
        w.get<ShadowCaster2D>(c)->lightLayers = 2;
        w.get<Light2D>(l)->lightLayers = 1;
        Image img = g.render(w);
        CHECK(at(img, 60, 0) > 0.7f);
        w.get<Light2D>(l)->lightLayers = 2;
        img = g.render(w);
        CHECK(at(img, 60, 0) < 0.05f);
        w.get<Light2D>(l)->lightLayers = -1;
        img = g.render(w);
        CHECK(at(img, 60, 0) < 0.05f);
    }

    // selfShadow: a lit sprite that is its own caster is lit with false, dark behind the near face with true.
    {
        World w;
        camera_at(w);
        w.settings().ambientLight = Color{0, 0, 0, 1};
        lamp(w, {-100, 0, 0}, 600, 0.0f);
        Entity box = lit_sprite(w, {0, 0, 0}, {40, 40});
        w.get<Transform>(box)->position = {0, 0, 0};
        auto& sc = w.add<ShadowCaster2D>(box);
        sc.shape = ShadowCaster2DShape::Box;
        sc.size = {40, 40};
        sc.selfShadow = false;
        Image img = g.render(w);
        CHECK(at(img, 0, 0) > 0.7f);    // inside the outline, lit like the face of a tile
        CHECK(at(img, 60, 0) < 0.05f);  // behind it: shadow
        w.get<ShadowCaster2D>(box)->selfShadow = true;
        img = g.render(w);
        CHECK(at(img, 0, 0) < 0.3f);  // the caster darkens itself
    }
}

TEST_CASE("ShadowCaster2D spriteAlpha: a SpriteAnimator frame is its own contour; a reloaded texture makes a new one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    // A 32x16 sheet of two 16x16 frames: the left one opaque, the right one empty.
    Image sheet = solid_image(32, 16, Color{1, 1, 1, 0});
    for (int y = 0; y < 16; ++y)
        for (int x = 0; x < 16; ++x) sheet.set_pixel(x, y, Color::white());
    REQUIRE(save_png(sheet, "assets/sc_sheet.png").ok());
    World w;
    lit_floor(w);
    lamp(w, {-100, 0, 0}, 600, 0.0f);
    Entity e = make(w, "anim", {0, 0, 0});
    auto& sp = w.add<Sprite>(e);
    sp.texture = "assets/sc_sheet.png";
    sp.color = Color{1, 1, 1, 0};
    sp.size = {16, 16};
    w.add<ShadowCaster2D>(e);
    auto& an = w.add<SpriteAnimator>(e);
    an.columns = 2;
    an.rows = 1;
    an.firstFrame = an.lastFrame = 0;
    an.playing = false;
    // What the code does: apply_sprite_frames writes the frame's rectangle into Sprite.region before the casters are
    // gathered, so the contour follows the frame (one contour per frame and threshold, each made once).
    Image img = g.render(w);
    CHECK(at(img, 60, 0) < 0.05f);  // frame 0 is opaque: it blocks
    const int first = render::renderer_shadow_rows_stats(g.renderer).contours;
    w.get<SpriteAnimator>(e)->firstFrame = w.get<SpriteAnimator>(e)->lastFrame = 1;
    img = g.render(w);
    CHECK(at(img, 60, 0) > 0.7f);  // frame 1 is empty: nothing blocks
    const int second = render::renderer_shadow_rows_stats(g.renderer).contours;
    CHECK(second == first + 1);
    w.get<SpriteAnimator>(e)->firstFrame = w.get<SpriteAnimator>(e)->lastFrame = 0;
    img = g.render(w);
    CHECK(at(img, 60, 0) < 0.05f);  // back to frame 0: its contour is reused
    CHECK(render::renderer_shadow_rows_stats(g.renderer).contours == second);

    // A texture reloaded from a changed file gets a new image id, so its contour is made again.
    World r;
    lit_floor(r);
    lamp(r, {-100, 0, 0}, 600, 0.0f);
    Entity b = make(r, "reloaded", {0, 0, 0});
    auto& rs = r.add<Sprite>(b);
    rs.texture = "assets/sc_reload.png";
    rs.color = Color{1, 1, 1, 0};
    rs.size = {16, 16};
    r.add<ShadowCaster2D>(b);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/sc_reload.png").ok());
    img = g.render(r);
    CHECK(at(img, 60, 0) < 0.05f);
    const int before = render::renderer_shadow_rows_stats(g.renderer).contours;
    REQUIRE(save_png(solid_image(16, 16, Color{1, 1, 1, 0}), "assets/sc_reload.png").ok());
    g.renderer.reload_asset("assets/sc_reload.png");
    img = g.render(r);
    CHECK(at(img, 60, 0) > 0.7f);  // the new picture is empty
    CHECK(render::renderer_shadow_rows_stats(g.renderer).contours == before + 1);
}

TEST_CASE("Light2D.size softens the shadow on the per-pixel path of a lit sprite with a normal map") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    REQUIRE(save_png(solid_image(16, 16, Color{0.5f, 0.5f, 1.0f, 1}), "assets/flat_n.png").ok());
    int widths[2] = {};
    const float sizes[2] = {0.0f, 6.0f};
    for (int k = 0; k < 2; ++k) {
        World w;
        lit_floor(w);
        w.get<Sprite>(w.find("floor"))->normalMap = "assets/flat_n.png";
        lamp(w, {-150, 0, 0}, 600, sizes[k]);
        box_caster(w, {-100, 0, 0}, {10, 20});
        Image img = g.render(w);
        widths[k] = penumbra_pixels(img, 140);
        CHECK(at(img, 140, 0) < 0.05f);
        CHECK(at(img, 140, 85) > 3.0f * at(img, 140, 0));  // lit is well above the umbra, though this path is dimmer
    }
    CHECK(widths[0] <= 3);
    CHECK(widths[1] > widths[0] + 8);
}

TEST_CASE("Tilemap.lightLayers selects the lights its solid tiles block") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    World w;
    lit_floor(w);
    Entity map = make(w, "wall", {0, 96, 0});
    auto& tm = w.add<Tilemap>(map);
    tm.tileset = "assets/white16.png";
    tm.tileSize = {16, 16};
    Json rows = Json::array();
    for (int r = 0; r < 12; ++r) rows.push_back(Json::array({0}));
    set_tilemap_tiles(tm, rows);
    tm.solidTiles = Json::array({0});
    tm.occludesLight = true;
    tm.layer = -20;
    Entity l = lamp(w, {-80, 0, 0}, 300, 0.0f, 1.0f);
    Image img = g.render(w);
    CHECK(at(img, 40, 0) < 0.02f);  // defaults: tilemap 1, light -1 share a bit, the wall blocks
    w.get<Tilemap>(map)->lightLayers = 2;
    w.get<Light2D>(l)->lightLayers = 1;
    img = g.render(w);
    CHECK(at(img, 40, 0) > 0.3f);  // no bit in common: the light shines through
    w.get<Light2D>(l)->lightLayers = 3;
    img = g.render(w);
    CHECK(at(img, 40, 0) < 0.02f);
}

TEST_CASE("more than 32 shadowed lights: every light gets a shadow") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    World w;
    lit_floor(w);
    for (int i = 0; i < 40; ++i) lamp(w, {-146.0f + float(i) * 7.5f, 60, 0}, 80, 0.0f, 1.0f);
    Entity bar = box_caster(w, {0, 40, 0}, {320, 4});
    Image img = g.render(w);
    CHECK(g.renderer.stats().lights2d == 40);
    CHECK(g.renderer.stats().lights2dShadowed == 40);
    w.get<ShadowCaster2D>(bar)->enabled = false;
    Image open = g.render(w);
    CHECK(g.renderer.stats().lights2dShadowed == 0);
    for (int i : {0, 10, 20, 33, 39}) {
        const float x = -146.0f + float(i) * 7.5f;
        CHECK(at(open, x, 20) > 0.3f);
        CHECK(at(img, x, 20) < 0.05f);  // under the bar: every light, the 40th too, is blocked
    }
}

TEST_CASE("shadow rows: a still scene uploads nothing, a moving light uploads again") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    World w;
    lit_floor(w);
    Entity l = lamp(w, {-100, 0, 0}, 300, 3.0f);
    box_caster(w, {0, 0, 0}, {20, 20});
    g.render(w);
    const int first = render::renderer_shadow_rows_stats(g.renderer).uploads;
    CHECK(first >= 1);
    for (int i = 0; i < 3; ++i) g.render(w);
    CHECK(render::renderer_shadow_rows_stats(g.renderer).uploads == first);
    w.get<Transform>(l)->position = {-100, 10, 0};
    g.render(w);
    CHECK(render::renderer_shadow_rows_stats(g.renderer).uploads == first + 1);
}

TEST_CASE("soft shadows, casters and tiles together (golden)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    Image disc = solid_image(32, 32, Color{1, 1, 1, 0});
    for (int y = 0; y < 32; ++y)
        for (int x = 0; x < 32; ++x)
            if ((x - 15.5f) * (x - 15.5f) + (y - 15.5f) * (y - 15.5f) < 13.0f * 13.0f)
                disc.set_pixel(x, y, Color::white());
    REQUIRE(save_png(disc, "assets/disc32.png").ok());
    World w;
    camera_at(w);
    w.settings().ambientLight = Color{0.06f, 0.06f, 0.09f, 1};
    lit_sprite(w, {0, 0, 0}, {320, 180});
    Entity big = lamp(w, {-110, 20, 0}, 300, 6.0f, 1.0f);
    w.get<Light2D>(big)->color = Color{1.0f, 0.85f, 0.6f, 1};
    Entity small = lamp(w, {90, -50, 0}, 160, 0.0f, 1.0f);
    w.get<Light2D>(small)->color = Color{0.5f, 0.7f, 1.0f, 1};
    box_caster(w, {-40, 30, 0}, {14, 40});
    Entity ball = make(w, "ball", {10, -20, 0});
    {
        auto& sp = w.add<Sprite>(ball);
        sp.texture = "assets/disc32.png";
        sp.color = Color{0.9f, 0.5f, 0.3f, 1};
        sp.size = {32, 32};
        sp.layer = 5;
        w.add<ShadowCaster2D>(ball);
    }
    Entity tri = make(w, "tri", {60, 40, 0});
    {
        auto& c = w.add<ShadowCaster2D>(tri);
        c.shape = ShadowCaster2DShape::Polygon;
        const float pts[] = {-12, -10, 12, -10, 0, 16};
        c.points.assign(pts, 6);
        auto& sh = w.add<Shape2D>(tri);
        sh.shape = ShapeType::Triangle;
        sh.size = {24, 26};
        sh.color = Color{0.4f, 0.8f, 0.4f, 1};
        sh.layer = 5;
    }
    Image img = g.render(w);
    CHECK(g.renderer.stats().lights2dShadowed == 2);
    expect_golden(img, "2d_soft_shadows");
}

namespace {

// Collects the warnings the renderer logs while it is alive.
struct WarnLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    WarnLog()
        : id(add_log_sink([l = shared](const LogEntry& e) {
              if (e.level < LogLevel::Warn) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~WarnLog() { remove_log_sink(id); }
    WarnLog(const WarnLog&) = delete;
    WarnLog& operator=(const WarnLog&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        int n = 0;
        for (const std::string& l : shared->lines)
            if (l.find(needle) != std::string::npos) ++n;
        return n;
    }
};

}  // namespace

// The cost of the budget scene of the performance page: 100 casters and 64 shadowed lights, every light moving every frame
// (so no row is cached), and the same scene still. Reported, never asserted: the numbers depend on the machine.
TEST_CASE("shadow casters: 100 casters and 64 moving soft lights (reported, never asserted)") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    World w;
    lit_floor(w);
    for (int i = 0; i < 100; ++i)
        box_caster(w, {-140.0f + float(i % 10) * 30.0f, -70.0f + float(i / 10) * 15.0f, 0}, {12, 8});
    std::vector<Entity> lights;
    for (int i = 0; i < 64; ++i)
        lights.push_back(lamp(w, {-150.0f + float(i % 8) * 40.0f, -60.0f + float(i / 8) * 17.0f, 0}, 120, 3.0f, 1.0f));
    g.render(w);
    CHECK(g.renderer.stats().lights2dShadowed == 64);
    auto frames = [&](bool move) {
        const auto t0 = std::chrono::steady_clock::now();
        for (int f = 0; f < 10; ++f) {
            if (move)
                for (std::size_t i = 0; i < lights.size(); ++i)
                    w.get<Transform>(lights[i])->position.x += (i % 2 ? 0.25f : -0.25f);
            g.render(w);
        }
        return std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count() / 10.0;
    };
    const double moving = frames(true), still = frames(false);
    for (Entity l : lights) w.get<Light2D>(l)->size = 0.0f;
    g.render(w);
    const double hardStill = frames(false);
    MESSAGE("100 casters x 64 soft lights: " << int(moving * 10) / 10.0 << " ms a frame with every light moving, "
                                             << int(still * 10) / 10.0 << " ms still, " << int(hardStill * 10) / 10.0
                                             << " ms still with size 0");
}

TEST_CASE("shadow lights: every one of the 256 lights a frame shades has its shadow, the cap is warned once") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    WarnLog log;
    World w;
    lit_floor(w);
    // 300 small lights in a row just above a bar: each one reaches the caster.
    for (int i = 0; i < 300; ++i)
        lamp(w, {-150.0f + float(i % 30) * 10.0f, 10.0f + float(i / 30) * 0.5f, 0}, 20, 0.0f, 1.0f);
    box_caster(w, {0, 0, 0}, {320, 4});
    g.render(w);
    CHECK(g.renderer.stats().lights2d == kMaxLights2D);  // the cap of lights a frame shades is the cap of shadows
    CHECK(g.renderer.stats().lights2dShadowed == kMaxShadowLights2D);
    g.render(w);
    CHECK(log.count("a frame shades at most 256") == 1);  // once, not once per frame
}

// ------------------------------------------------------------------------------------------------ caps and warnings

namespace {

// A caster of 256 segments that all run from x = -100 to x = 100 just above a light at the origin: every segment spans about
// 400 of the 1024 angles, so one caster costs about 98,000 segment-by-angle tests and eleven pass kMaxRowWork2D.
void add_zigzag(CasterSet& set, float y) {
    ShadowBody b;
    b.first = std::uint32_t(set.segs.size());
    b.count = 256;
    b.y0 = y;
    b.y1 = y + 6.0f;
    b.x0 = -100;
    b.x1 = 100;
    b.hash = 11 + set.bodies.size();
    for (int i = 0; i < 256; ++i) {
        const float ya = y + float(i) * 0.02f, yb = y + float(i + 1) * 0.02f;
        set.segs.push_back(i % 2 == 0 ? ShadowSegment{-100, ya, 100, yb} : ShadowSegment{100, ya, -100, yb});
    }
    set.bodies.push_back(b);
}

}  // namespace

TEST_CASE("cast_casters: the per-row work cap cuts the same casters on every run") {
    CasterSet set;
    for (int i = 0; i < 12; ++i) add_zigzag(set, 10.0f + float(i) * 8.0f);
    // The last caster is a box below the light: it is after the cut, so it must not block anything.
    const CasterSet below = one_box(-20, -30, 20, -20, false);
    ShadowBody boxBody = below.bodies[0];
    boxBody.first = std::uint32_t(set.segs.size());
    set.segs.insert(set.segs.end(), below.segs.begin(), below.segs.end());
    set.bodies.push_back(boxBody);

    std::vector<std::uint32_t> all;
    for (std::uint32_t i = 0; i < set.bodies.size(); ++i) all.push_back(i);
    std::vector<float> a = fresh_row(300), b = fresh_row(300);
    bool cutA = false, cutB = false;
    const std::uint64_t workA = cast_casters(set, all, 0, 0, 300, a.data(), &cutA);
    const std::uint64_t workB = cast_casters(set, all, 0, 0, 300, b.data(), &cutB);
    CHECK(cutA);
    CHECK(cutB);
    CHECK(workA == workB);  // a count, never time
    CHECK(a == b);
    CHECK(workA >= kMaxRowWork2D);
    CHECK(workA < kMaxRowWork2D + 1024u);                 // it stops at the segment that crossed the cap
    CHECK(a[std::size_t(kShadowAngles) * 3 / 4] == 300);  // straight down: the box after the cut blocks nothing

    // The box alone is read in full: the cap, not the geometry, is what left the light unshadowed below.
    std::vector<float> alone = fresh_row(300);
    bool cutAlone = false;
    cast_casters(set, {12}, 0, 0, 300, alone.data(), &cutAlone);
    CHECK_FALSE(cutAlone);
    CHECK(alone[std::size_t(kShadowAngles) * 3 / 4] < 300);

    {
        const CasterSet box = one_box(50, -5, 60, 5, false);  // fills about 11 degrees of the light's view
        std::vector<float> row = fresh_row(300);
        const std::uint64_t work = cast_casters(box, {0}, 0, 0, 300, row.data());
        CHECK(work > 60);  // about 80: what docs/rendering/RENDERING_2D_SHADOWS.md says a box costs a row
        CHECK(work < 100);
    }

    // Five of those casters are under half the cap: nothing is cut.
    std::vector<float> few = fresh_row(300);
    bool cutFew = false;
    cast_casters(set, {0, 1, 2, 3, 4}, 0, 0, 300, few.data(), &cutFew);
    CHECK_FALSE(cutFew);
}

TEST_CASE("warn_once: fixed keys are never pushed out by per-entity keys, and a scene change resets both") {
    WarnLog log;
    ContourCache c;
    for (int i = 0; i < 200; ++i) warn_once(c, "entity" + std::to_string(i), "per-entity problem", true);
    CHECK(log.count("per-entity problem") == int(kMaxEntityWarnings2D));
    warn_once(c, "rowWork", "fixed problem");
    warn_once(c, "rowWork", "fixed problem");
    CHECK(log.count("fixed problem") == 1);  // shown although 200 per-entity keys came first
    reset_warnings(c);
    warn_once(c, "rowWork", "fixed problem");
    warn_once(c, "entity0", "per-entity problem", true);
    CHECK(log.count("fixed problem") == 2);
    CHECK(log.count("per-entity problem") == int(kMaxEntityWarnings2D) + 1);
}

TEST_CASE("gather_shadow_casters: the contour cache ages once per gather pass") {
    World w;
    Entity cam = camera_at(w);
    box_caster(w, {0, 0, 0}, {10, 10});
    Frame f;
    f.cam.entity = cam;
    f.mask = CameraMask::of(w, cam);
    ContourCache cache;
    CasterSet set;
    CHECK(cache.tick == 0);
    gather_shadow_casters(w, f, cache, set);
    CHECK(cache.tick == 1);
    CHECK(set.bodies.size() == 1);
    gather_shadow_casters(w, f, cache, set);  // a second camera of the same frame is a second pass
    CHECK(cache.tick == 2);
    gather_shadow_casters(w, f, cache, set);
    CHECK(cache.tick == 3);
}

TEST_CASE("row work cap in a scene: warned once with a hint, again after a scene change") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    REQUIRE(save_png(solid_image(16, 16, Color::white()), "assets/white16.png").ok());
    WarnLog log;
    World w;
    w.set_scene_path("scenes/a.json");
    lit_floor(w);
    Entity l = lamp(w, {0, 0, 0}, 300, 0.0f);
    for (int i = 0; i < 12; ++i) {
        Entity e = make(w, "zigzag", {0, float(i) * 8.0f, 0});
        auto& c = w.add<ShadowCaster2D>(e);
        c.shape = ShadowCaster2DShape::Polygon;
        for (int k = 0; k < 256; ++k) {
            c.points.push_back(k % 2 == 0 ? -100.0f : 100.0f);
            c.points.push_back(10.0f + float(k) * 0.02f);
        }
    }
    g.render(w);
    CHECK(log.count("segment-by-angle tests") == 1);
    CHECK(log.count("Hint: use a smaller radius") == 1);
    w.get<Transform>(l)->position.x = 1.0f;  // a new row: the cap is met again, the warning stays once
    g.render(w);
    CHECK(log.count("segment-by-angle tests") == 1);
    w.set_scene_path("scenes/b.json");
    w.get<Transform>(l)->position.x = 2.0f;
    g.render(w);
    CHECK(log.count("segment-by-angle tests") == 2);
}
