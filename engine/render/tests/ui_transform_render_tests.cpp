// A widget whose Transform turns or scales it is drawn where fa_ui hits it (ui_rect.h, "Rotation and scale").
#include "test_util.h"

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
    for (const auto& [e, region] : {std::pair{turned, Rect{0, 0, 160, 180}}, std::pair{scaled, Rect{170, 0, 150, 180}}}) {
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
