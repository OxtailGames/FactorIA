// Shape2D: the diamond primitive and the triangle pivot (centroid) recipe.
#include "test_util.h"

#include <algorithm>
#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

Entity shape_at(World& w, ShapeType type, Vec3 p, Vec2 size, Color c, bool filled = true, float thickness = 2.0f,
                Vec2 pivot = {0.5f, 0.5f}, RenderSpace sp = RenderSpace::World) {
    Entity e = make(w, "shape", p);
    auto& s = w.add<Shape2D>(e);
    s.shape = type;
    s.size = size;
    s.color = c;
    s.filled = filled;
    s.thickness = thickness;
    s.pivot = pivot;
    s.space = sp;
    return e;
}

Entity black_camera(World& w) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    return cam;
}

bool drawn(const Image& img, int x, int y) { return img.pixel(x, y).r > 0.6f; }

// Area centroid of the lit pixels (weighted by brightness), in pixel coordinates.
Vec2 lit_centroid(const Image& img) {
    double sx = 0, sy = 0, sw = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            double weight = img.pixel(x, y).r;
            sx += weight * (x + 0.5);
            sy += weight * (y + 0.5);
            sw += weight;
        }
    REQUIRE(sw > 100.0);
    return Vec2{float(sx / sw), float(sy / sw)};
}

}  // namespace

TEST_CASE("Shape2D diamond: filled, points at the middles of the size box edges, corners empty") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    // 60x40 box centred on the target centre: pixels x 130..189, y 70..109. Points: (160,70) (160,110) (130,90) (190,90).
    shape_at(w, ShapeType::Diamond, {0, 0, 0}, {60, 40}, Color::white());
    Image img = g.render(w);
    CHECK(drawn(img, 160, 90));                                  // centre
    CHECK(drawn(img, 160, 73));  CHECK(drawn(img, 160, 106));    // just inside the top and bottom points
    CHECK(drawn(img, 133, 90));  CHECK(drawn(img, 186, 90));     // just inside the left and right points
    CHECK(drawn(img, 150, 82));  CHECK(drawn(img, 170, 98));     // inside, towards the edges (|dx|/30 + |dy|/20 = 0.8)
    CHECK_FALSE(drawn(img, 131, 71));  CHECK_FALSE(drawn(img, 188, 71));     // the 4 corners of the size box
    CHECK_FALSE(drawn(img, 131, 108)); CHECK_FALSE(drawn(img, 188, 108));
    CHECK_FALSE(drawn(img, 145, 76));  CHECK_FALSE(drawn(img, 175, 104));    // outside the edges (|dx|/30 + |dy|/20 = 1.2)
    CHECK_FALSE(drawn(img, 160, 66));  CHECK_FALSE(drawn(img, 126, 90));     // beyond the box
    for (int y = 0; y < img.height; ++y)                                      // nothing leaves the size box
        for (int x = 0; x < img.width; ++x)
            if (x < 129 || x > 190 || y < 69 || y > 110) REQUIRE(img.pixel(x, y).r < 0.05f);
}

TEST_CASE("Shape2D diamond: outlined, the stroke grows inward and the silhouette matches the filled one") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    shape_at(w, ShapeType::Diamond, {0, 0, 0}, {60, 40}, Color::white(), false, 6.0f);
    Image ring = g.render(w);
    CHECK_FALSE(drawn(ring, 160, 90));                                // hollow
    CHECK_FALSE(drawn(ring, 150, 90));  CHECK_FALSE(drawn(ring, 160, 80));
    CHECK(drawn(ring, 160, 73));  CHECK(drawn(ring, 160, 106));       // the 4 points are stroked
    CHECK(drawn(ring, 133, 90));  CHECK(drawn(ring, 186, 90));
    CHECK(drawn(ring, 148, 82));  CHECK(drawn(ring, 172, 98));        // on the stroke (|dx|/30 + |dy|/20 = 0.76, in 0.64..1)
    CHECK(drawn(ring, 172, 82));  CHECK(drawn(ring, 148, 98));
    CHECK_FALSE(drawn(ring, 131, 71));  CHECK_FALSE(drawn(ring, 188, 71));
    CHECK_FALSE(drawn(ring, 131, 108)); CHECK_FALSE(drawn(ring, 188, 108));
    CHECK_FALSE(drawn(ring, 145, 76));  CHECK_FALSE(drawn(ring, 175, 104));

    // Every stroked pixel lies inside the filled diamond (same silhouette).
    World f;
    black_camera(f);
    shape_at(f, ShapeType::Diamond, {0, 0, 0}, {60, 40}, Color::white());
    Image filled = g.render(f);
    for (int y = 0; y < ring.height; ++y)
        for (int x = 0; x < ring.width; ++x)
            if (ring.pixel(x, y).r > 0.3f) REQUIRE(filled.pixel(x, y).r > 0.1f);

    // A stroke thicker than the shape fills it completely instead of inverting.
    World t;
    black_camera(t);
    shape_at(t, ShapeType::Diamond, {0, 0, 0}, {60, 40}, Color::white(), false, 500.0f);
    Image thick = g.render(t);
    CHECK(drawn(thick, 160, 90));
    CHECK(drawn(thick, 133, 90));
    CHECK_FALSE(drawn(thick, 131, 71));
    // Degenerate sizes do not break the frame.
    World z;
    black_camera(z);
    shape_at(z, ShapeType::Diamond, {0, 0, 0}, {0, 0}, Color::white(), false, 3.0f);
    shape_at(z, ShapeType::Diamond, {50, 0, 0}, {40, 0}, Color::white(), true);
    shape_at(z, ShapeType::Diamond, {-50, 0, 0}, {-30, 30}, Color::white(), false, 3.0f);
    CHECK(g.render(z).width == 320);
}

TEST_CASE("Shape2D diamond: pivot, screen space, anchor, blend and layer work like the other shapes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    // World, pivot [0,0]: the bottom-left corner of the 40x40 box is at the position, so the centre is at pixel
    // (180, 70); its top point is (180, 50) and its right point (200, 70).
    shape_at(w, ShapeType::Diamond, {0, 0, 0}, {40, 40}, Color{1, 0, 0, 1}, true, 2.0f, {0, 0});
    // Screen, pivot [0,1] = visual top-left corner at the position: box x 20..59, y 20..59, centre (40,40).
    shape_at(w, ShapeType::Diamond, {20, 20, 0}, {40, 40}, Color{0, 1, 0, 1}, true, 2.0f, {0, 1}, RenderSpace::Screen);
    // Screen, anchored bottom-right, pivot [1,0] = visual bottom-right corner 10 px inside the screen corner.
    Entity br = shape_at(w, ShapeType::Diamond, {-10, -10, 0}, {40, 40}, Color{0, 0, 1, 1}, true, 2.0f, {1, 0},
                         RenderSpace::Screen);
    w.get<Shape2D>(br)->anchor = {1, 1};  // box x 270..309, y 130..169, centre (290,150)
    Image img = g.render(w);
    CHECK(img.pixel(180, 70).r > 0.9f);   CHECK(img.pixel(180, 70).g < 0.1f);
    CHECK(img.pixel(180, 53).r > 0.9f);   CHECK(img.pixel(197, 70).r > 0.9f);       // top and right points
    CHECK(img.pixel(161, 51).r < 0.1f);   CHECK(img.pixel(198, 88).r < 0.1f);       // corners of its box stay empty
    CHECK(img.pixel(40, 40).g > 0.9f);    CHECK(img.pixel(40, 23).g > 0.9f);
    CHECK(img.pixel(21, 21).g < 0.1f);
    CHECK(img.pixel(290, 150).b > 0.9f);  CHECK(img.pixel(290, 133).b > 0.9f);
    CHECK(img.pixel(271, 131).b < 0.1f);

    // Additive blend adds the light of overlapping diamonds; with alpha a higher layer covers a lower one.
    World w2;
    black_camera(w2);
    Entity a = shape_at(w2, ShapeType::Diamond, {-10, 0, 0}, {60, 60}, Color{0.4f, 0.0f, 0.0f, 1});
    Entity b = shape_at(w2, ShapeType::Diamond, {10, 0, 0}, {60, 60}, Color{0.0f, 0.4f, 0.0f, 1});
    w2.get<Shape2D>(a)->blend = BlendMode::Additive;
    w2.get<Shape2D>(b)->blend = BlendMode::Additive;
    Image add = g.render(w2);
    CHECK(add.pixel(160, 90).r > 0.35f);  CHECK(add.pixel(160, 90).g > 0.35f);       // the overlap has both
    CHECK(add.pixel(135, 90).r > 0.35f);  CHECK(add.pixel(135, 90).g < 0.05f);
    w2.get<Shape2D>(a)->blend = BlendMode::Alpha;
    w2.get<Shape2D>(b)->blend = BlendMode::Alpha;
    w2.get<Shape2D>(a)->layer = 5;  // a (red) now draws on top of b (green)
    Image layered = g.render(w2);
    CHECK(layered.pixel(160, 90).r > 0.35f);
    CHECK(layered.pixel(160, 90).g < 0.05f);
}

TEST_CASE("Shape2D diamond: golden image next to the other shapes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x20242c);
    shape_at(w, ShapeType::Diamond, {-100, 30, 0}, {60, 60}, Color::hex(0xe05050));
    shape_at(w, ShapeType::Diamond, {-20, 30, 0}, {60, 40}, Color::hex(0x50e0e0), false, 4.0f);
    shape_at(w, ShapeType::Diamond, {70, 30, 0}, {50, 50}, Color::hex(0xf0c040), true, 2.0f, {0.5f, 0.5f});
    Entity spin = shape_at(w, ShapeType::Diamond, {-60, -45, 0}, {50, 30}, Color::hex(0x50e050));
    w.get<Transform>(spin)->rotation = {0, 0, 30};
    Entity ring = shape_at(w, ShapeType::Diamond, {40, -45, 0}, {50, 50}, Color::hex(0xc050f0), false, 3.0f);
    w.get<Transform>(ring)->rotation = {0, 0, 45};  // a square diamond turned 45 degrees is an axis-aligned square
    shape_at(w, ShapeType::Diamond, {16, 120, 0}, {24, 24}, Color::hex(0xffffff), true, 2.0f, {0, 1}, RenderSpace::Screen);
    expect_golden(g.render(w), "2d_diamonds");
}

TEST_CASE("Shape2D triangle: pivot [0.5, 1/3] spins it about its centroid, the default pivot makes it wobble") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (RenderSpace space : {RenderSpace::World, RenderSpace::Screen}) {
        INFO((space == RenderSpace::World ? "world space" : "screen space"));
        // The entity sits at the exact centre of the 320x180 target: world (0,0) / screen (160,90).
        const Vec3 pos = space == RenderSpace::World ? Vec3{0, 0, 0} : Vec3{160, 90, 0};
        float worstCentroid = 0.0f, worstDefault = 0.0f;
        for (float angle : {0.0f, 30.0f, 90.0f, 137.0f, 200.0f, 315.0f}) {
            INFO("rotation " << angle);
            World w;
            black_camera(w);
            Entity e = shape_at(w, ShapeType::Triangle, pos, {60, 60}, Color::white(), true, 2.0f, {0.5f, 1.0f / 3.0f}, space);
            w.get<Transform>(e)->rotation = {0, 0, angle};
            Vec2 c = lit_centroid(g.render(w));
            worstCentroid = std::max({worstCentroid, std::fabs(c.x - 160.0f), std::fabs(c.y - 90.0f)});

            World d;  // the same triangle with the default pivot
            black_camera(d);
            Entity e2 = shape_at(d, ShapeType::Triangle, pos, {60, 60}, Color::white(), true, 2.0f, {0.5f, 0.5f}, space);
            d.get<Transform>(e2)->rotation = {0, 0, angle};
            Vec2 c2 = lit_centroid(g.render(d));
            worstDefault = std::max(worstDefault, std::hypot(c2.x - 160.0f, c2.y - 90.0f));
        }
        INFO("worst centroid drift with pivot [0.5, 1/3]: " << worstCentroid << " px, default pivot: " << worstDefault);
        CHECK(worstCentroid < 0.75f);  // the centroid stays put (sub-pixel: rasterization noise only)
        CHECK(worstDefault > 8.0f);    // the box centre is h/6 = 10 px from the centroid: the default pivot wobbles
    }
}

TEST_CASE("Shape2D triangle: the apex points up in world and screen space, base on the bottom edge of the box") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (RenderSpace space : {RenderSpace::World, RenderSpace::Screen}) {
        INFO((space == RenderSpace::World ? "world space" : "screen space"));
        const Vec3 pos = space == RenderSpace::World ? Vec3{0, 0, 0} : Vec3{160, 90, 0};
        World w;
        black_camera(w);
        shape_at(w, ShapeType::Triangle, pos, {60, 60}, Color::white(), true, 2.0f, {0.5f, 0.5f}, space);  // box y 60..119
        Image img = g.render(w);
        CHECK(drawn(img, 160, 63));                  // near the apex (top middle)
        CHECK_FALSE(drawn(img, 140, 63));
        CHECK(drawn(img, 133, 116));                 // near the bottom-left corner of the base
        CHECK(drawn(img, 186, 116));
        CHECK_FALSE(drawn(img, 133, 63));            // top corners of the box are empty
    }
}
