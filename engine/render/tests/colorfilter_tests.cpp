// Camera.colorFilter: the last post-process pass, applied to the finished frame so screenshots show it.
#include "test_util.h"

#include <cmath>

using namespace fa;
using namespace fa::test;

namespace {

constexpr int kW = 320;
constexpr int kH = 180;
const Color kClear{0.2f, 0.2f, 0.2f, 1.0f};

struct Swatch {
    Vec3 pos;
    Color color;
};
// Six flat 40x40 swatches in a row at y = 0 (pixels y 70..109), centres at x = 60, 100, ... 260.
const Swatch kSwatches[] = {{{-100, 0, 0}, {1, 0, 0, 1}},       {{-60, 0, 0}, {0, 1, 0, 1}},    {{-20, 0, 0}, {0, 0, 1, 1}},
                            {{20, 0, 0}, {1, 1, 1, 1}},         {{60, 0, 0}, {0.5f, 0.5f, 0.5f, 1}}, {{100, 0, 0}, {1, 0.6f, 0.1f, 1}}};

struct FilterScene {
    World world;
    Entity cam;
    FilterScene() {
        cam = make(world, "cam");
        world.add<Camera>(cam).clearColor = kClear;
        for (const Swatch& s : kSwatches) {
            Entity e = make(world, "swatch", s.pos);
            auto& sh = world.add<Shape2D>(e);
            sh.shape = ShapeType::Rectangle;
            sh.size = {40, 40};
            sh.color = s.color;
        }
    }
    void filter(ColorFilter f) { world.get<Camera>(cam)->colorFilter = f; }
};

Color swatch_pixel(const Image& img, int i) { return img.pixel(60 + 40 * i, 90); }

bool near_color(Color a, Color b, float tol = 3.0f / 255.0f) {
    return std::fabs(a.r - b.r) <= tol && std::fabs(a.g - b.g) <= tol && std::fabs(a.b - b.b) <= tol;
}

}  // namespace

TEST_CASE("colorFilter: none draws exactly what a camera without the field draws") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    Image plain = g.render(s.world);
    CHECK(near_color(swatch_pixel(plain, 0), Color{1, 0, 0, 1}));
    s.filter(ColorFilter::Greyscale);
    Image grey = g.render(s.world);
    CHECK_FALSE(grey.rgba == plain.rgba);
    s.filter(ColorFilter::None);  // back to none: no residue of the filtered image
    Image again = g.render(s.world);
    CHECK(again.rgba == plain.rgba);
}

TEST_CASE("colorFilter: greyscale, protanopia, deuteranopia and tritanopia match the CPU simulation for white and grey") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    // White and grey carry no colour: dichromacy and greyscale leave them as they are (this also pins the sRGB round trip).
    for (ColorFilter f : {ColorFilter::Greyscale, ColorFilter::Protanopia, ColorFilter::Deuteranopia, ColorFilter::Tritanopia}) {
        s.filter(f);
        Image img = g.render(s.world);
        CHECK(near_color(swatch_pixel(img, 3), Color{1, 1, 1, 1}));
        CHECK(near_color(swatch_pixel(img, 4), Color{0.5f, 0.5f, 0.5f, 1}));
        CHECK(near_color(img.pixel(5, 5), kClear));
        CHECK(img.pixel(5, 5).a == doctest::Approx(1.0f));
    }
}

TEST_CASE("colorFilter: greyscale equals the CPU luminance conversion of the unfiltered frame") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    Image plain = g.render(s.world);
    s.filter(ColorFilter::Greyscale);
    Image grey = g.render(s.world);
    Image expected = plain;
    simulate_color_vision(expected, ColorSimulation::Greyscale);
    ImageDiff d = diff_images(expected, grey, 3.0f / 255.0f);
    INFO("meanError=" << d.meanError << " maxError=" << d.maxError);
    CHECK(d.differingPixels == 0);
}

TEST_CASE("colorFilter: highContrast stretches around mid grey") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    s.filter(ColorFilter::HighContrast);
    Image img = g.render(s.world);
    CHECK(near_color(swatch_pixel(img, 4), Color{0.5f, 0.5f, 0.5f, 1}));      // mid grey stays
    CHECK(near_color(swatch_pixel(img, 5), Color{1.0f, 0.68f, 0.0f, 1}));     // (1, .6, .1) -> (1, .68, 0)
    CHECK(near_color(img.pixel(5, 5), Color{0.0f, 0.0f, 0.0f, 1}));           // the 0.2 clear darkens to 0
}

TEST_CASE("colorFilter: daltonize moves the lost red/green difference into the visible channels") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    s.filter(ColorFilter::Deuteranopia);
    Image img = g.render(s.world);
    // Pure red and pure green no longer look alike to a deuteranope: the correction makes them differ in blue.
    Color red = swatch_pixel(img, 0), green = swatch_pixel(img, 1);
    CHECK(red.b > green.b + 0.2f);
    // The correction only adds to green and blue: red keeps its red channel.
    CHECK(red.r == doctest::Approx(1.0f).epsilon(0.02));
    // Worked by hand in linear light: red -> (1, 0.163, 0.455), green -> (0, 0.725, 0).
    CHECK(near_color(red, Color{1.0f, 0.4531f, 0.7049f, 1}, 4.0f / 255.0f));
    CHECK(near_color(green, Color{0.0f, 0.8677f, 0.0f, 1}, 4.0f / 255.0f));
}

TEST_CASE("colorFilter: golden image of every filter") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    struct Case {
        ColorFilter filter;
        const char* name;
    };
    for (const Case& c : {Case{ColorFilter::Greyscale, "2d_filter_greyscale"}, Case{ColorFilter::HighContrast, "2d_filter_highcontrast"},
                          Case{ColorFilter::Protanopia, "2d_filter_protanopia"}, Case{ColorFilter::Deuteranopia, "2d_filter_deuteranopia"},
                          Case{ColorFilter::Tritanopia, "2d_filter_tritanopia"}}) {
        s.filter(c.filter);
        INFO(c.name);
        expect_golden(g.render(s.world), c.name);
    }
}

TEST_CASE("colorFilter: bloom runs before the filter and the filter is the last pass") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    FilterScene s;
    Camera& c = *s.world.get<Camera>(s.cam);
    c.bloom = true;
    c.bloomThreshold = 0.5f;
    Image bloomed = g.render(s.world);
    c.colorFilter = ColorFilter::Greyscale;
    Image both = g.render(s.world);
    Image expected = bloomed;
    simulate_color_vision(expected, ColorSimulation::Greyscale);
    ImageDiff d = diff_images(expected, both, 4.0f / 255.0f);
    INFO("meanError=" << d.meanError << " maxError=" << d.maxError);
    CHECK(d.differingPixels == 0);
}
