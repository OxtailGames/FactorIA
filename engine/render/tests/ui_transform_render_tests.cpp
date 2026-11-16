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
        // not at the anchor: the turn is about the Panel, not about the anchor
        w.get<Transform>(e)->position = {20, 10, 0};
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
    // A quarter turn clockwise about the centre (W/4 + 20, H/2 + 10): the child at +30 to the right lands 30 below it.
    const Vec2 a = red_centre(0, half);
    CHECK(a.x == doctest::Approx(design.x * 0.25f + 20.0f).epsilon(0.02));
    CHECK(a.y == doctest::Approx(design.y * 0.5f + 10.0f + 30.0f).epsilon(0.02));
    const std::array<Vec2, 4> quad = *ui_quad(w, turned, design);
    CHECK(point_in_quad(a, quad));
    // Scaled by 2 about its centre (3W/4 + 20, H/2 + 10): 60 to the right.
    const Vec2 b = red_centre(half, img.width);
    CHECK(b.x == doctest::Approx(design.x * 0.75f + 20.0f + 60.0f).epsilon(0.02));
    CHECK(b.y == doctest::Approx(design.y * 0.5f + 10.0f).epsilon(0.02));
    CHECK(point_in_quad(b, *ui_quad(w, scaled, design)));
}

TEST_CASE(
    "ui transform: a screen-space Shape2D under a turned Panel inside a turned Panel lands where the chain puts it") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const auto panel = [&](const char* name, Vec3 pos, Entity parent) {
        Entity e = make(w, name, pos);
        if (parent) w.set_parent(e, parent);
        Panel& p = w.add<Panel>(e);
        p.size = {40, 10};
        p.pivot = {0.5f, 0.5f};
        p.anchor = {0.5f, 0.5f};
        p.color = Color{0, 0, 0, 0};
        return e;
    };
    const Entity outer = panel("outer", {20, 10, 0}, kNullEntity);
    w.get<Transform>(outer)->rotation = {0, 0, 90};
    const Entity inner = panel("inner", {30, 0, 0}, outer);
    w.get<Transform>(inner)->rotation = {0, 0, 90};
    const Entity shape = make(w, "shape", {20, 0, 0});
    w.set_parent(shape, inner);
    Shape2D& s = w.add<Shape2D>(shape);
    s.shape = ShapeType::Rectangle;
    s.size = {8, 8};
    s.color = Color{1, 0, 0, 1};
    s.anchor = {0.5f, 0.5f};
    s.layer = 50;
    s.space = RenderSpace::Screen;
    w.get<Transform>(shape)->rotation = {0, 0, 45};  // its own turn does not move its centre
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    double sx = 0, sy = 0, n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            if (c.r > 0.7f && c.b < 0.3f) sx += x + 0.5, sy += y + 0.5, n += 1;
        }
    REQUIRE(n > 0);
    // In layout space the shape is at the anchor + (20 + 30 + 20, 10). The inner Panel (at +30) turns its +20 into
    // +20 down; then the outer turn (about its centre, at +20, +10) takes (30, 20) to (-20, 30).
    CHECK(float(sx / n) == doctest::Approx(design.x * 0.5f + 20.0f - 20.0f).epsilon(0.02));
    CHECK(float(sy / n) == doctest::Approx(design.y * 0.5f + 10.0f + 30.0f).epsilon(0.02));
}

TEST_CASE(
    "ui transform: a laid-out child is drawn in its slot, with Transform.position at 0, under a turned parent too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const auto panel = [&](const char* name, Vec3 pos, Entity parent, Vec2 size) {
        Entity e = make(w, name, pos);
        if (parent) w.set_parent(e, parent);
        Panel& p = w.add<Panel>(e);
        p.size = size;
        p.pivot = {0, 1};
        p.color = Color{0, 0, 0, 0};
        return e;
    };
    const Entity flat = panel("flat", {60, 40, 0}, kNullEntity, {100, 50});
    const Entity flatChild = panel("flatChild", {0, 0, 0}, flat, {20, 10});
    w.get<Panel>(flatChild)->color = Color::white();
    w.set_ui_layout_offset(flatChild, {30, 10});  // what the layout writes: the slot, relative to the parent
    const Entity turned = panel("turned", {200, 40, 0}, kNullEntity, {60, 50});
    w.get<Transform>(turned)->rotation = {0, 0, 90};
    const Entity turnedChild = panel("turnedChild", {0, 0, 0}, turned, {20, 10});
    w.get<Panel>(turnedChild)->color = Color::white();
    w.set_ui_layout_offset(turnedChild, {10, 20});
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    const auto ink = [&](int rx0, int rx1) {
        int x0 = 1 << 20, y0 = 1 << 20, x1 = -1, y1 = -1;
        for (int y = 0; y < img.height; ++y)
            for (int x = rx0; x < rx1; ++x)
                if (img.pixel(x, y).r > 0.5f) {
                    x0 = std::min(x0, x);
                    y0 = std::min(y0, y);
                    x1 = std::max(x1, x);
                    y1 = std::max(y1, y);
                }
        REQUIRE(x1 >= x0);
        return Rect{float(x0), float(y0), float(x1 - x0 + 1), float(y1 - y0 + 1)};
    };
    const Rect a = ink(0, 170);
    CHECK(std::fabs(a.x - 90.0f) <= 1.5f);  // 60 + 30
    CHECK(std::fabs(a.y - 50.0f) <= 1.5f);  // 40 + 10
    CHECK(a.w == doctest::Approx(20.0f).epsilon(0.1));
    const Rect hitA = *ui_rect(w, flatChild, design);
    CHECK(hitA.x == doctest::Approx(90.0f));
    CHECK(hitA.y == doctest::Approx(50.0f));
    CHECK(std::as_const(w).get<Transform>(flatChild)->position == Vec3{0, 0, 0});
    const Rect b = ink(170, img.width);
    const Rect hitB = *ui_rect(w, turnedChild, design);
    CHECK(std::fabs(b.x - hitB.x) <= 1.5f);
    CHECK(std::fabs(b.y - hitB.y) <= 1.5f);
    CHECK(std::fabs(b.w - hitB.w) <= 2.0f);
    CHECK(std::fabs(b.h - hitB.h) <= 2.0f);
    CHECK(hitB.w == doctest::Approx(10.0f));  // 20 x 10 turned a quarter
}

namespace {

// The centre of the red pixels of the image (a Shape2D drawn in pure red), as pixel coordinates.
Vec2 red_centre_of(const Image& img) {
    double sx = 0, sy = 0, n = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Color c = img.pixel(x, y);
            if (c.r > 0.7f && c.b < 0.3f) sx += x + 0.5, sy += y + 0.5, n += 1;
        }
    REQUIRE(n > 0);
    return Vec2{float(sx / n), float(sy / n)};
}

// A Panel (not drawn: the card is its quad) with a red screen-space Shape2D child.
Entity red_card(World& w, Vec2 panelAnchor, Vec2 panelPivot, Vec3 panelPos, Vec2 childAnchor, Vec3 childPos) {
    Entity e = make(w, "card", panelPos);
    Panel& p = w.add<Panel>(e);
    p.size = {100, 20};
    p.pivot = panelPivot;
    p.anchor = panelAnchor;
    p.color = Color{0, 0, 0, 0};
    Entity c = make(w, "red", childPos);
    w.set_parent(c, e);
    Shape2D& s = w.add<Shape2D>(c);
    s.shape = ShapeType::Rectangle;
    s.size = {8, 8};
    s.color = Color{1, 0, 0, 1};
    s.anchor = childAnchor;
    s.layer = 50;
    s.space = RenderSpace::Screen;
    return e;
}

}  // namespace

TEST_CASE("ui transform: a child whose anchor is not its Panel's turns about the Panel's origin, not its own anchor") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const Entity card = red_card(w, {0.5f, 0.5f}, {0.5f, 0.5f}, {20, 10, 0}, {0.5f, 0.25f}, {30, 0, 0});
    w.get<Transform>(card)->rotation = {0, 0, 90};
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    // In layout space the red square is at (W/2 + 20 + 30, H/4 + 10), the Panel's origin at (W/2 + 20, H/2 + 10): the offset
    // (30, -H/4) turns a quarter clockwise to (H/4, 30).
    const Vec2 c = red_centre_of(img);
    CHECK(c.x == doctest::Approx(design.x * 0.5f + 20.0f + design.y * 0.25f).epsilon(0.02));
    CHECK(c.y == doctest::Approx(design.y * 0.5f + 10.0f + 30.0f).epsilon(0.02));
}

TEST_CASE("ui transform: a Panel pivoted at its corner turns about its origin and its child follows") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    // pivot [0, 1]: the rectangle hangs right and down from the origin (W/4 + 20, H/2 + 10); the child is 30 right, 10 below it.
    const Entity card = red_card(w, {0.25f, 0.5f}, {0.0f, 1.0f}, {20, 10, 0}, {0.25f, 0.5f}, {30, 10, 0});
    w.get<Transform>(card)->rotation = {0, 0, 90};
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    const Vec2 c = red_centre_of(img);
    // A quarter turn clockwise about the origin takes (30, 10) to (-10, 30), inside the turned rectangle.
    CHECK(c.x == doctest::Approx(design.x * 0.25f + 20.0f - 10.0f).epsilon(0.02));
    CHECK(c.y == doctest::Approx(design.y * 0.5f + 10.0f + 30.0f).epsilon(0.02));
    CHECK(point_in_quad(c, *ui_quad(w, card, design)));
}

TEST_CASE("ui transform: under ui.mirrorRtl the turned card is its own mirror image, child included") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    w.set_rtl(true);  // ui_mirror_rtl is on by default
    const Entity card = red_card(w, {0.25f, 0.5f}, {0.5f, 0.5f}, {20, 10, 0}, {0.25f, 0.5f}, {30, 0, 0});
    w.get<Transform>(card)->rotation = {0, 0, 90};
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    REQUIRE(ui_mirrored(w, card));
    // The left-to-right card puts the square at (W/4 + 20, H/2 + 10 + 30); mirrored, x becomes W - x.
    const Vec2 c = red_centre_of(img);
    CHECK(c.x == doctest::Approx(design.x - (design.x * 0.25f + 20.0f)).epsilon(0.02));
    CHECK(c.y == doctest::Approx(design.y * 0.5f + 10.0f + 30.0f).epsilon(0.02));
    CHECK(point_in_quad(c, *ui_quad(w, card, design)));
}

TEST_CASE("ui transform: a plain group (no widget) that scales still scales its child's offset and keeps its anchor") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    const Entity group = make(w, "group", {0, 0, 0});
    w.get<Transform>(group)->scale = {2, 2, 1};
    Entity c = make(w, "red", {10, 0, 0});
    w.set_parent(c, group);
    Shape2D& s = w.add<Shape2D>(c);
    s.shape = ShapeType::Rectangle;
    s.size = {8, 8};
    s.color = Color{1, 0, 0, 1};
    s.anchor = {0.5f, 0.5f};
    s.layer = 50;
    s.space = RenderSpace::Screen;
    const Image img = g.render(w);
    const Vec2 design{float(img.width), float(img.height)};
    // Not the widget map: the group's scale multiplies the child's own offset (10 -> 20) and the anchor stays at the centre.
    const Vec2 p = red_centre_of(img);
    CHECK(p.x == doctest::Approx(design.x * 0.5f + 20.0f).epsilon(0.02));
    CHECK(p.y == doctest::Approx(design.y * 0.5f).epsilon(0.02));
}
