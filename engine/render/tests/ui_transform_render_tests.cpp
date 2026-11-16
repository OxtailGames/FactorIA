// A widget whose Transform turns or scales it is drawn where fa_ui hits it (ui_rect.h, "Rotation and scale").
#include "test_util.h"

#include "fa/scene/bounds.h"
#include "fa/scene/ui_rect.h"

#include <algorithm>
#include <cmath>

using namespace fa;
using namespace fa::test;

TEST_CASE("ui transform: a Panel turned a quarter and a Panel scaled by 2 are drawn on their oriented rectangles") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const auto panel = [&](const char* name, Vec3 pos, Vec2 size) {
        Entity e = make(w, name, pos);
        Panel& p = w.add<Panel>(e);
        p.size = size;
        p.pivot = {0.5f, 0.5f};
        p.color = Color::white();
        return e;
    };
    const Entity turned = panel("turned", {100, 60, 0}, {100, 20});
    w.get<Transform>(turned)->rotation = {0, 0, 90};
    const Entity scaled = panel("scaled", {230, 120, 0}, {40, 10});
    w.get<Transform>(scaled)->scale = {2, 2, 1};
    const Image img = g.render(w);
    const auto bounds = [&](int rx0, int ry0, int rx1, int ry1) {
        int x0 = 1 << 20, y0 = 1 << 20, x1 = -1, y1 = -1;
        for (int y = ry0; y < ry1; ++y)
            for (int x = rx0; x < rx1; ++x)
                if (img.pixel(x, y).r > 0.5f) {
                    x0 = std::min(x0, x);
                    y0 = std::min(y0, y);
                    x1 = std::max(x1, x);
                    y1 = std::max(y1, y);
                }
        return Rect{float(x0), float(y0), float(x1 - x0 + 1), float(y1 - y0 + 1)};
    };
    const Vec2 design{float(img.width), float(img.height)};
    for (const auto& [e, region] :
         {std::pair{turned, Rect{0, 0, 160, 180}}, std::pair{scaled, Rect{170, 0, 150, 180}}}) {
        const Rect hit = *ui_rect(w, e, design);
        const Rect ink = bounds(int(region.x), int(region.y), int(region.x + region.w), int(region.y + region.h));
        CHECK(std::fabs(ink.x - hit.x) <= 1.5f);
        CHECK(std::fabs(ink.y - hit.y) <= 1.5f);
        CHECK(std::fabs(ink.w - hit.w) <= 2.0f);
        CHECK(std::fabs(ink.h - hit.h) <= 2.0f);
    }
    const Rect t = *ui_rect(w, turned, design);
    CHECK(t.w == doctest::Approx(20.0f));
    CHECK(t.h == doctest::Approx(100.0f));
}

TEST_CASE(
    "ui transform: a screen-space Shape2D child turns and scales about the Panel's anchor, so the card is rigid") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const auto card = [&](const char* name, Vec2 anchor) {
        Entity e = make(w, name);
        Panel& p = w.add<Panel>(e);
        p.size = {100, 20};
        p.pivot = {0.5f, 0.5f};
        p.anchor = anchor;
        p.color =
            Color{0, 0, 0, 0};  // not drawn: the widgets are drawn over the screen-space visuals, the card is its quad
        Entity c = make(w, "child", {30, 0, 0});  // to the right of the Panel's centre: an asymmetric case
        w.set_parent(c, e);
        Shape2D& s = w.add<Shape2D>(c);
        s.shape = ShapeType::Rectangle;
        s.size = {10, 10};
        s.color = Color{1, 0, 0, 1};
        s.anchor =
            anchor;  // like a widget child: the same anchor as the Panel, so its position is relative to the card
        s.layer = 50;
        s.space = RenderSpace::Screen;
        return e;
    };
    const Entity turned = card("turned", {0.25f, 0.5f});
    w.get<Transform>(turned)->rotation = {0, 0, 90};
    const Entity scaled = card("scaled", {0.75f, 0.5f});
    w.get<Transform>(scaled)->scale = {2, 2, 1};
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    const auto red_centre = [&](int x0, int x1) {
        double sx = 0, sy = 0, n = 0;
        for (int y = 0; y < img.height; ++y)
            for (int x = x0; x < x1; ++x) {
                const Color c = img.pixel(x, y);
                if (c.r > 0.7f && c.b < 0.3f) sx += x + 0.5, sy += y + 0.5, n += 1;
            }
        REQUIRE(n > 0);
        return Vec2{float(sx / n), float(sy / n)};
    };
    const int half = img.width / 2;
    // A quarter turn clockwise about the centre (W/4, H/2): the child at +30 to the right lands 30 below the centre.
    const Vec2 a = red_centre(0, half);
    CHECK(a.x == doctest::Approx(design.x * 0.25f).epsilon(0.02));
    CHECK(a.y == doctest::Approx(design.y * 0.5f + 30.0f).epsilon(0.02));
    const std::array<Vec2, 4> quad = *ui_quad(w, turned, design);
    CHECK(point_in_quad(a, quad));
    // Scaled by 2 about its centre (3W/4, H/2): 60 to the right.
    const Vec2 b = red_centre(half, img.width);
    CHECK(b.x == doctest::Approx(design.x * 0.75f + 60.0f).epsilon(0.02));
    CHECK(b.y == doctest::Approx(design.y * 0.5f).epsilon(0.02));
    CHECK(point_in_quad(b, *ui_quad(w, scaled, design)));
}
