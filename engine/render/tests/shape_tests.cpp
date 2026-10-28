// Shape2D: the diamond, polygon and star primitives, the inward triangle outline and the triangle pivot (centroid) recipe.
#include "test_util.h"

#include "fa/scene/serialize.h"

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

// Nothing outside the pixel box [x0, x1] x [y0, y1] is lit: the shape stays inside its size box.
bool dark_outside(const Image& img, int x0, int y0, int x1, int y1) {
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x)
            if ((x < x0 || x > x1 || y < y0 || y > y1) && img.pixel(x, y).r >= 0.05f) return false;
    return true;
}

// Every stroked pixel of `ring` is inside the filled shape: an outline has the silhouette of the filled one.
bool within(const Image& ring, const Image& filled) {
    for (int y = 0; y < ring.height; ++y)
        for (int x = 0; x < ring.width; ++x)
            if (ring.pixel(x, y).r > 0.3f && filled.pixel(x, y).r <= 0.1f) return false;
    return true;
}

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

TEST_CASE("Shape2D triangle: the outline grows inward, evenly thick on all edges, and never pokes out of the size box") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    for (RenderSpace space : {RenderSpace::World, RenderSpace::Screen}) {
        INFO((space == RenderSpace::World ? "world space" : "screen space"));
        const Vec3 pos = space == RenderSpace::World ? Vec3{0, 0, 0} : Vec3{160, 90, 0};
        World w;
        black_camera(w);
        // 60x60 box centred on the target: pixels x 130..189, y 60..119. Apex (160,60), base along y = 120.
        shape_at(w, ShapeType::Triangle, pos, {60, 60}, Color::white(), false, 6.0f, {0.5f, 0.5f}, space);
        Image ring = g.render(w);
        CHECK(dark_outside(ring, 130, 60, 189, 119));  // nothing leaves the size box (a centred stroke poked out by t/2)
        CHECK_FALSE(drawn(ring, 160, 100));                           // hollow (incentre)
        CHECK_FALSE(drawn(ring, 160, 90));
        CHECK(drawn(ring, 160, 63));  CHECK(drawn(ring, 160, 70));    // the sharp apex is stroked
        CHECK(drawn(ring, 133, 117)); CHECK(drawn(ring, 186, 117));   // so are the base corners
        CHECK(drawn(ring, 160, 117)); CHECK_FALSE(drawn(ring, 160, 110));
        // Equal thickness: the base stroke is 6 px tall; a leg crossed horizontally measures 6 / cos = ~6.7 px.
        int base = 0, leg = 0;
        for (int y = 100; y < 120; ++y) base += drawn(ring, 160, y) ? 1 : 0;
        for (int x = 100; x < 160; ++x) leg += drawn(ring, x, 100) ? 1 : 0;
        CHECK(base >= 5);  CHECK(base <= 7);
        CHECK(leg >= 5);   CHECK(leg <= 8);

        // The silhouette is the filled triangle's.
        World f;
        black_camera(f);
        shape_at(f, ShapeType::Triangle, pos, {60, 60}, Color::white(), true, 6.0f, {0.5f, 0.5f}, space);
        CHECK(within(ring, g.render(f)));

        // A stroke thicker than the triangle fills it instead of inverting.
        World t;
        black_camera(t);
        shape_at(t, ShapeType::Triangle, pos, {60, 60}, Color::white(), false, 500.0f, {0.5f, 0.5f}, space);
        Image thick = g.render(t);
        CHECK(drawn(thick, 160, 100));  CHECK(drawn(thick, 160, 63));  CHECK(drawn(thick, 133, 117));
        CHECK_FALSE(drawn(thick, 133, 63));
    }
    // Degenerate sizes do not break the frame.
    World z;
    black_camera(z);
    shape_at(z, ShapeType::Triangle, {0, 0, 0}, {0, 0}, Color::white(), false, 3.0f);
    shape_at(z, ShapeType::Triangle, {50, 0, 0}, {40, 0}, Color::white(), false, 3.0f);
    shape_at(z, ShapeType::Triangle, {-50, 0, 0}, {-30, 30}, Color::white(), false, 3.0f);
    CHECK(g.render(z).width == 320);
}

TEST_CASE("Shape2D polygon: a regular polygon on the ellipse inscribed in the size box, first vertex up") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    // Hexagon (the default 6 sides) of circumradius 30 around pixel (160, 90): vertices (160,60) (186,75) (186,105)
    // (160,120) (134,105) (134,75); the vertical edges sit at x = 134 and 186.
    shape_at(w, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white());
    Image img = g.render(w);
    CHECK(drawn(img, 160, 90));
    CHECK(drawn(img, 160, 63));   CHECK(drawn(img, 160, 116));   // just inside the top and bottom vertices
    CHECK(drawn(img, 137, 77));   CHECK(drawn(img, 183, 77));    // just inside the four side vertices
    CHECK(drawn(img, 137, 103));  CHECK(drawn(img, 183, 103));
    CHECK(drawn(img, 137, 90));   CHECK(drawn(img, 183, 90));    // the flat sides, just inside
    CHECK_FALSE(drawn(img, 131, 90));  CHECK_FALSE(drawn(img, 189, 90));
    CHECK_FALSE(drawn(img, 131, 61));  CHECK_FALSE(drawn(img, 188, 61));     // the 4 corners of the size box
    CHECK_FALSE(drawn(img, 131, 118)); CHECK_FALSE(drawn(img, 188, 118));
    CHECK_FALSE(drawn(img, 160, 57));  CHECK_FALSE(drawn(img, 160, 123));    // beyond the vertices
    CHECK(dark_outside(img, 129, 59, 190, 120));                               // nothing leaves the size box

    // sides = 4 is a diamond (first vertex up) stretched by the 60x40 box; sides = 3 an upward triangle.
    World sq;
    black_camera(sq);
    Entity four = shape_at(sq, ShapeType::Polygon, {0, 0, 0}, {60, 40}, Color::white());
    sq.get<Shape2D>(four)->sides = 4;
    Image dia = g.render(sq);
    CHECK(drawn(dia, 160, 73));   CHECK(drawn(dia, 133, 90));    // top and left points of the 60x40 rhombus
    CHECK_FALSE(drawn(dia, 145, 76));  CHECK_FALSE(drawn(dia, 131, 71));
    World tri;
    black_camera(tri);
    Entity three = shape_at(tri, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white());
    tri.get<Shape2D>(three)->sides = 3;
    Image up = g.render(tri);
    CHECK(drawn(up, 160, 63));    CHECK_FALSE(drawn(up, 133, 63));
    CHECK(drawn(up, 140, 101));   CHECK(drawn(up, 180, 101));    // bottom corners at angles 210 and 330 degrees

    // Many sides approach the circle; out-of-range counts are clamped instead of breaking the frame.
    World many;
    black_camera(many);
    Entity round = shape_at(many, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white());
    for (int sides : {-5, 0, 1, 2, 64, 65, 100000}) {
        many.get<Shape2D>(round)->sides = sides;
        Image n = g.render(many);
        CHECK(drawn(n, 160, 90));
        CHECK_FALSE(drawn(n, 131, 61));
    }
}

TEST_CASE("Shape2D polygon: the outline grows inward and matches the filled silhouette") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    shape_at(w, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white(), false, 6.0f);
    Image ring = g.render(w);
    CHECK_FALSE(drawn(ring, 160, 90));  CHECK_FALSE(drawn(ring, 150, 90));  // hollow
    CHECK(drawn(ring, 137, 90));  CHECK(drawn(ring, 183, 90));             // the flat sides are stroked (x 134..139)
    CHECK(drawn(ring, 160, 63));  CHECK(drawn(ring, 160, 116));            // the vertices stay sharp
    CHECK_FALSE(drawn(ring, 131, 61));  CHECK_FALSE(drawn(ring, 188, 118));
    World f;
    black_camera(f);
    shape_at(f, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white());
    CHECK(within(ring, g.render(f)));

    World t;
    black_camera(t);
    shape_at(t, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white(), false, 500.0f);
    Image thick = g.render(t);
    CHECK(drawn(thick, 160, 90));  CHECK(drawn(thick, 137, 77));
    CHECK_FALSE(drawn(thick, 131, 61));
}

TEST_CASE("Shape2D star: tips on the outer radius, notches in between, outline grows inward") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    // 5 points, innerRadius 0.5, outer radius 40 around pixel (160, 90). Tips at 90, 162, 234, 306 and 18 degrees;
    // the notches (radius 20) sit at 126, 198, 270, 342 and 54 degrees.
    World w;
    black_camera(w);
    shape_at(w, ShapeType::Star, {0, 0, 0}, {80, 80}, Color::white());
    Image img = g.render(w);
    CHECK(drawn(img, 160, 90));
    CHECK(drawn(img, 160, 54));                                   // top tip, 4 px from its end
    CHECK(drawn(img, 127, 79));   CHECK(drawn(img, 193, 79));     // the side tips (6 px from their ends)
    CHECK(drawn(img, 140, 118));  CHECK(drawn(img, 180, 118));    // the bottom tips
    CHECK_FALSE(drawn(img, 139, 61));  CHECK_FALSE(drawn(img, 181, 61));   // between the tips, near the outer radius
    CHECK_FALSE(drawn(img, 122, 100)); CHECK_FALSE(drawn(img, 198, 100));
    CHECK_FALSE(drawn(img, 160, 134));                                     // the bottom notch (radius 20 at 270 degrees)
    CHECK(drawn(img, 160, 106));                                           // ... which is solid closer to the centre
    CHECK_FALSE(drawn(img, 121, 51));  CHECK_FALSE(drawn(img, 199, 51));   // corners of the size box
    CHECK(dark_outside(img, 119, 49, 200, 130));                            // nothing leaves the size box

    World ring;
    black_camera(ring);
    shape_at(ring, ShapeType::Star, {0, 0, 0}, {80, 80}, Color::white(), false, 4.0f);
    Image outline = g.render(ring);
    CHECK_FALSE(drawn(outline, 160, 90));  CHECK_FALSE(drawn(outline, 160, 100));   // hollow
    CHECK(drawn(outline, 160, 54));  CHECK(drawn(outline, 127, 79));               // the tips are stroked
    CHECK_FALSE(drawn(outline, 139, 61));
    CHECK(within(outline, img));                                                     // same silhouette as the filled star

    // More points, a fatter or thinner star, and a thick stroke that fills it.
    World more;
    black_camera(more);
    Entity e = shape_at(more, ShapeType::Star, {0, 0, 0}, {80, 80}, Color::white());
    Shape2D& s = *more.get<Shape2D>(e);
    s.points = 8;
    Image eight = g.render(more);
    CHECK(drawn(eight, 160, 54));  CHECK(drawn(eight, 185, 65));  // tips at 90 and 45 degrees (radius 36 from the centre)
    CHECK_FALSE(drawn(eight, 175, 56));                              // the notch between them, near the outer radius
    s.points = 5;
    s.innerRadius = 1.0f;  // notches at the full radius: a regular decagon
    Image fat = g.render(more);
    CHECK(drawn(fat, 139, 61));  CHECK(drawn(fat, 160, 54));
    s.innerRadius = 0.0f;  // needles that all meet at the centre
    CHECK(g.render(more).width == 320);
    s.innerRadius = 0.5f;
    s.filled = false;
    s.thickness = 500.0f;
    Image solid = g.render(more);
    CHECK(drawn(solid, 160, 90));  CHECK(drawn(solid, 160, 54));  CHECK_FALSE(drawn(solid, 139, 61));
    s.filled = true;
    for (int points : {-1, 0, 2, 3, 64, 65, 100000}) {  // clamped to 3..64
        s.points = points;
        CHECK(drawn(g.render(more), 160, 90));
    }
}

TEST_CASE("Shape2D polygon and star: pivot, screen space, rotation and zero size work like the other shapes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    // World, pivot [0,0]: the bottom-left of the 40x40 box is at the position (centre at pixel (180, 70)).
    shape_at(w, ShapeType::Polygon, {0, 0, 0}, {40, 40}, Color{1, 0, 0, 1}, true, 2.0f, {0, 0});
    // Screen, pivot [0,1]: visual top-left corner at the position (box x 20..59, y 20..59, centre (40,40)).
    shape_at(w, ShapeType::Star, {20, 20, 0}, {40, 40}, Color{0, 1, 0, 1}, true, 2.0f, {0, 1}, RenderSpace::Screen);
    // Screen, anchored bottom-right, pivot [1,0]: box x 270..309, y 130..169, centre (290, 150).
    Entity br = shape_at(w, ShapeType::Polygon, {-10, -10, 0}, {40, 40}, Color{0, 0, 1, 1}, true, 2.0f, {1, 0},
                         RenderSpace::Screen);
    w.get<Shape2D>(br)->anchor = {1, 1};
    Image img = g.render(w);
    CHECK(img.pixel(180, 70).r > 0.9f);   CHECK(img.pixel(180, 70).g < 0.1f);
    CHECK(img.pixel(180, 53).r > 0.9f);   CHECK(img.pixel(161, 51).r < 0.1f);
    CHECK(img.pixel(40, 40).g > 0.9f);    CHECK(img.pixel(40, 23).g > 0.9f);    // the star's top tip points UP on screen
    CHECK(img.pixel(40, 57).g < 0.1f);                                           // ... and its bottom is a notch
    CHECK(img.pixel(290, 150).b > 0.9f);  CHECK(img.pixel(271, 131).b < 0.1f);

    // A hexagon turned by 60 degrees (its symmetry) looks the same.
    World a, b;
    black_camera(a);
    black_camera(b);
    shape_at(a, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white());
    Entity spun = shape_at(b, ShapeType::Polygon, {0, 0, 0}, {60, 60}, Color::white());
    b.get<Transform>(spun)->rotation = {0, 0, 60};
    ImageDiff d = diff_images(g.render(a), g.render(b), 8.0f / 255.0f);
    CHECK(d.differingPixels < 40);

    // Zero and negative sizes do not break the frame.
    World z;
    black_camera(z);
    for (ShapeType type : {ShapeType::Polygon, ShapeType::Star}) {
        shape_at(z, type, {0, 0, 0}, {0, 0}, Color::white(), false, 3.0f);
        shape_at(z, type, {50, 0, 0}, {40, 0}, Color::white(), true);
        shape_at(z, type, {-50, 0, 0}, {-30, 30}, Color::white(), false, 3.0f);
    }
    CHECK(g.render(z).width == 320);
}

TEST_CASE("Shape2D polygon and star: golden image next to the other shapes") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x20242c);
    shape_at(w, ShapeType::Polygon, {-110, 40, 0}, {56, 56}, Color::hex(0xe05050));
    Entity pent = shape_at(w, ShapeType::Polygon, {-45, 40, 0}, {56, 56}, Color::hex(0x50e0e0), false, 4.0f);
    w.get<Shape2D>(pent)->sides = 5;
    Entity oct = shape_at(w, ShapeType::Polygon, {20, 40, 0}, {64, 40}, Color::hex(0xf0c040));
    w.get<Shape2D>(oct)->sides = 8;
    shape_at(w, ShapeType::Star, {90, 40, 0}, {60, 60}, Color::hex(0x50e050));
    shape_at(w, ShapeType::Star, {-110, -40, 0}, {60, 60}, Color::hex(0xc050f0), false, 3.0f);
    Entity thin = shape_at(w, ShapeType::Star, {-40, -40, 0}, {60, 60}, Color::hex(0xff9040));
    w.get<Shape2D>(thin)->points = 7;
    w.get<Shape2D>(thin)->innerRadius = 0.3f;
    Entity fat = shape_at(w, ShapeType::Star, {30, -40, 0}, {60, 60}, Color::hex(0x40a0ff), false, 5.0f);
    w.get<Shape2D>(fat)->points = 6;
    w.get<Shape2D>(fat)->innerRadius = 0.7f;
    w.get<Transform>(fat)->rotation = {0, 0, 15};
    shape_at(w, ShapeType::Triangle, {100, -40, 0}, {50, 50}, Color::hex(0xe0e050), false, 5.0f);
    shape_at(w, ShapeType::Star, {24, 156, 0}, {28, 28}, Color::hex(0xffffff), true, 2.0f, {0.5f, 0.5f}, RenderSpace::Screen);
    expect_golden(g.render(w), "2d_polygons");
}

// ---- cornerRadius, softness and gradients (the SDF shader path, mode 7) ----

namespace {
Entity fx_rect(World& w, Vec3 p, Vec2 size, Color c, float radius, float softness = 0.0f) {
    Entity e = shape_at(w, ShapeType::Rectangle, p, size, c);
    w.get<Shape2D>(e)->cornerRadius = radius;
    w.get<Shape2D>(e)->softness = softness;
    return e;
}
}  // namespace

TEST_CASE("Shape2D FX fields: defaults leave a shape flat and crisp, json round trip") {
    Shape2D s;
    CHECK(s.cornerRadius == 0.0f);
    CHECK(s.softness == 0.0f);
    CHECK(s.gradient == ShapeGradient::None);
    CHECK(s.gradientAngle == 0.0f);
    World w;
    Entity e = fx_rect(w, {}, {40, 20}, Color::white(), 6.0f, 3.0f);
    w.get<Shape2D>(e)->gradient = ShapeGradient::Radial;
    w.get<Shape2D>(e)->color2 = Color{0, 0, 1, 0.5f};
    Json j = component_to_json(w, e, World::type_of<Shape2D>());
    CHECK(j["cornerRadius"].get<float>() == doctest::Approx(6.0f));
    CHECK(j["softness"].get<float>() == doctest::Approx(3.0f));
    CHECK(j["gradient"] == "radial");
}

TEST_CASE("Shape2D cornerRadius: corners are cut, edge middles and the centre stay filled") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    // 100x60 box centred on the target: pixels x 110..209, y 60..119; radius 20.
    fx_rect(w, {0, 0, 0}, {100, 60}, Color::white(), 20.0f);
    Image img = g.render(w);
    CHECK(drawn(img, 160, 90));
    CHECK(drawn(img, 160, 61));  CHECK(drawn(img, 160, 118));    // edge middles, a pixel in
    CHECK(drawn(img, 111, 90));  CHECK(drawn(img, 208, 90));
    CHECK_FALSE(drawn(img, 111, 61));  CHECK_FALSE(drawn(img, 208, 61));    // the corner pixels are outside the arc
    CHECK_FALSE(drawn(img, 111, 118)); CHECK_FALSE(drawn(img, 208, 118));
    CHECK(drawn(img, 118, 68));  // 8 px in along both axes: 16.3 px from the arc's centre, inside the radius 20
    CHECK(dark_outside(img, 110, 60, 209, 119));
    // A radius larger than half the short side is clamped: a pill whose ends are semicircles of radius 30.
    World p;
    black_camera(p);
    fx_rect(p, {0, 0, 0}, {100, 60}, Color::white(), 500.0f);
    Image pill = g.render(p);
    CHECK(drawn(pill, 160, 90));
    CHECK_FALSE(drawn(pill, 111, 61));
    CHECK(drawn(pill, 140, 61));
}

TEST_CASE("Shape2D softness: the edge fades over its width, centred on the outline; the footprint reaches softness/2 out") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    black_camera(w);
    fx_rect(w, {0, 0, 0}, {100, 60}, Color::white(), 0.0f, 20.0f);  // box x 110..209; the fade runs x 100..119 and 200..219
    Image img = g.render(w);
    CHECK(img.pixel(160, 90).r > 0.99f);                     // the middle is solid
    CHECK(img.pixel(209, 90).r == doctest::Approx(0.5f).epsilon(0.15));  // half way across the outline
    float prev = 2.0f;
    for (int x = 200; x <= 219; ++x) {  // monotonic fall-off across the right edge
        float r = img.pixel(x, 90).r;
        CHECK(r <= prev + 0.02f);
        prev = r;
    }
    CHECK(img.pixel(219, 90).r < 0.05f);
    CHECK(img.pixel(100, 90).r < 0.06f);
    CHECK(img.pixel(205, 90).r > img.pixel(214, 90).r);
    CHECK(dark_outside(img, 98, 48, 221, 131));
}

TEST_CASE("Shape2D gradient: linear runs colour to colour2 along the angle, radial from the centre out") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    {
        World w;
        black_camera(w);
        Entity e = shape_at(w, ShapeType::Rectangle, {0, 0, 0}, {200, 100}, Color{1, 0, 0, 1});
        Shape2D& s = *w.get<Shape2D>(e);
        s.gradient = ShapeGradient::Linear;
        s.color2 = Color{0, 0, 1, 1};  // 0 degrees: left red -> right blue; box x 60..259
        Image img = g.render(w);
        CHECK(img.pixel(62, 90).r > 0.95f);   CHECK(img.pixel(62, 90).b < 0.06f);
        CHECK(img.pixel(257, 90).b > 0.95f);  CHECK(img.pixel(257, 90).r < 0.06f);
        CHECK(img.pixel(160, 90).r == doctest::Approx(0.5f).epsilon(0.05));
        CHECK(img.pixel(160, 90).b == doctest::Approx(0.5f).epsilon(0.05));
        CHECK(img.pixel(160, 41).r == doctest::Approx(img.pixel(160, 139).r).epsilon(0.05));  // no change along y
        s.gradientAngle = 90.0f;  // bottom (colour) -> top (colour2)
        Image up = g.render(w);
        CHECK(up.pixel(160, 138).r > 0.9f);
        CHECK(up.pixel(160, 41).b > 0.9f);
        CHECK(up.pixel(70, 90).r == doctest::Approx(up.pixel(250, 90).r).epsilon(0.05));
    }
    {
        World w;
        black_camera(w);
        Entity e = shape_at(w, ShapeType::Circle, {0, 0, 0}, {100, 100}, Color{1, 1, 1, 1});
        Shape2D& s = *w.get<Shape2D>(e);
        s.gradient = ShapeGradient::Radial;
        s.color2 = Color{1, 1, 1, 0};  // white centre fading to nothing: a light pool
        Image img = g.render(w);
        CHECK(img.pixel(160, 90).r > 0.97f);
        const float a = img.pixel(160 + 15, 90).r, b = img.pixel(160 + 30, 90).r, c = img.pixel(160 + 45, 90).r;
        CHECK(a > b);  CHECK(b > c);
        CHECK(c < 0.2f);
        CHECK(b == doctest::Approx(0.5f).epsilon(0.1));
        CHECK(img.pixel(160, 90 + 30).r == doctest::Approx(b).epsilon(0.08));  // the same all round
    }
}

TEST_CASE("Shape2D FX: outline of a rounded rectangle, soft circle, additive light pool, golden image") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0xd8cba8);  // paper
    // Drop shadow under a rounded card, then the card with a gradient, then an outlined rounded rect.
    Entity shadow = fx_rect(w, {-78, 22, 0}, {90, 70}, Color{0, 0, 0, 0.45f}, 12.0f, 18.0f);
    w.get<Shape2D>(shadow)->layer = 0;
    Entity card = fx_rect(w, {-84, 30, 0}, {90, 70}, Color::hex(0xfff6dc), 12.0f);
    w.get<Shape2D>(card)->gradient = ShapeGradient::Linear;
    w.get<Shape2D>(card)->color2 = Color::hex(0xe0cfa0);
    w.get<Shape2D>(card)->gradientAngle = 0.0f;
    w.get<Shape2D>(card)->layer = 1;
    Entity ring = shape_at(w, ShapeType::Rectangle, {50, 30, 0}, {80, 50}, Color::hex(0x3a2a1a), false, 4.0f);
    w.get<Shape2D>(ring)->cornerRadius = 14.0f;
    // A soft dark circle (vignette blob) and a radial additive glow.
    Entity blob = shape_at(w, ShapeType::Circle, {-60, -52, 0}, {60, 60}, Color{0.1f, 0.05f, 0, 0.6f});
    w.get<Shape2D>(blob)->softness = 30.0f;
    Entity glow = shape_at(w, ShapeType::Circle, {60, -48, 0}, {90, 90}, Color{1, 0.8f, 0.4f, 0.9f});
    w.get<Shape2D>(glow)->gradient = ShapeGradient::Radial;
    w.get<Shape2D>(glow)->color2 = Color{1, 0.8f, 0.4f, 0};
    w.get<Shape2D>(glow)->blend = BlendMode::Additive;
    // Screen space version (y down) next to the world ones.
    Entity hud = shape_at(w, ShapeType::Rectangle, {300, 20, 0}, {30, 20}, Color::hex(0x336699), true, 2.0f, {0.5f, 0.5f},
                          RenderSpace::Screen);
    w.get<Shape2D>(hud)->cornerRadius = 8.0f;
    Image img = g.render(w);
    CHECK(img.pixel(210, 37).r < 0.4f);    // the ring's top edge: 4 px of dark inside its box (centre pixel y 60, box y 35..84)
    CHECK(img.pixel(210, 60).r > 0.7f);    // its hollow middle shows the paper
    expect_golden(img, "2d_shape_fx", 0.008);
}
