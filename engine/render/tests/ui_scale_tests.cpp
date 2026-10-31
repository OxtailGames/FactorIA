// The interface scale (ui.scale, ui_rect.h): screen-space Text, UI labels and widget backgrounds are drawn k times as big, from
// the same anchor, while world-space Text is untouched and measure_text stays in UI units. Layout and hit tests are fa_ui's.
#include "test_util.h"

#include "fa/scene/ui_rect.h"

#include <algorithm>
#include <cmath>
#include <string>

using namespace fa;
using namespace fa::test;

namespace {

// The bounding box of the bright pixels of a white-on-black image inside a pixel rectangle.
struct Ink {
    int x0 = 1 << 20, y0 = 1 << 20, x1 = -1, y1 = -1;
    bool any() const { return x1 >= x0; }
    int w() const { return x1 - x0 + 1; }
    int h() const { return y1 - y0 + 1; }
};
Ink ink(const Image& img, int rx0, int ry0, int rx1, int ry1, float threshold = 0.35f) {
    Ink k;
    for (int y = std::max(ry0, 0); y < std::min(ry1, img.height); ++y)
        for (int x = std::max(rx0, 0); x < std::min(rx1, img.width); ++x)
            if (img.pixel(x, y).r > threshold) {
                k.x0 = std::min(k.x0, x); k.y0 = std::min(k.y0, y);
                k.x1 = std::max(k.x1, x); k.y1 = std::max(k.y1, y);
            }
    return k;
}

Entity put_text(World& w, const char* name, Vec3 pos, RenderSpace space) {
    Entity e = make(w, name, pos);
    auto& t = w.add<Text>(e);
    t.text = "HHHH";
    t.fontSize = 20;
    t.space = space;
    t.pivot = {0, 1};
    return e;
}

}  // namespace

TEST_CASE("ui scale: screen-space Text, labels and backgrounds are drawn k times as big from their anchor; world Text is not") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    World w;
    w.add<Camera>(make(w, "cam")).clearColor = Color::black();
    put_text(w, "hud", {10, 10, 0}, RenderSpace::Screen);   // top-left of the screen
    put_text(w, "world", {70, -30, 0}, RenderSpace::World);  // pixel (230, 120)
    Entity p = make(w, "panel", {150, 10, 0});
    Panel& panel = w.add<Panel>(p);
    panel.size = {60, 40};
    panel.pivot = {0, 1};
    panel.color = Color::white();
    Entity b = make(w, "btn", {10, 70, 0});
    Button& btn = w.add<Button>(b);
    btn.size = {120, 40};
    btn.pivot = {0, 1};
    btn.color = Color{0, 0, 0, 0};
    btn.text = "HHHH";
    btn.fontSize = 20;

    struct Boxes { Ink hud, world, panel, label; Image img; };
    auto draw = [&] {
        const Image img = g.render(w);
        return Boxes{ink(img, 0, 0, 140, 65), ink(img, 220, 100, 320, 180), ink(img, 140, 0, 320, 100), ink(img, 0, 65, 200, 180), img};
    };
    struct Reset { Renderer& r; ~Reset() { r.set_ui_scale(1.0f); } } reset{g.renderer};

    const Boxes one = draw();
    REQUIRE((one.hud.any() && one.world.any() && one.panel.any() && one.label.any()));
    CHECK(one.panel.x0 == 150);
    CHECK(one.panel.w() == 60);
    CHECK(one.panel.h() == 40);
    const Vec2 measured = g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::Screen);

    w.set_ui_scale(1.5f);
    g.renderer.set_ui_scale(1.5f);
    const Boxes big = draw();
    REQUIRE((big.hud.any() && big.world.any() && big.panel.any() && big.label.any()));
    // the background: the position, the size and the pivot corner all scale from the anchor (the top-left of the screen)
    CHECK(big.panel.x0 == 225);
    CHECK(big.panel.y0 == 15);
    CHECK(big.panel.w() == 90);
    CHECK(big.panel.h() == 60);
    // the text: its font size and its place
    CHECK(std::abs(big.hud.w() - 1.5 * one.hud.w()) <= 3);
    CHECK(std::abs(big.hud.h() - 1.5 * one.hud.h()) <= 3);
    CHECK(std::abs(big.hud.x0 - 1.5 * one.hud.x0) <= 3);
    CHECK(std::abs(big.hud.y0 - 1.5 * one.hud.y0) <= 3);
    // the label of a widget is centred in the scaled rectangle (15..195 x 105..165) and 1.5 times as big
    CHECK(std::abs(big.label.w() - 1.5 * one.label.w()) <= 3);
    CHECK(std::abs(big.label.h() - 1.5 * one.label.h()) <= 3);
    CHECK(std::abs((big.label.x0 + big.label.x1) / 2.0 - 105) <= 3);
    CHECK(std::abs((big.label.y0 + big.label.y1) / 2.0 - 135) <= 3);
    // world-space Text: pixel for pixel
    CHECK(big.world.x0 == one.world.x0);
    CHECK(big.world.x1 == one.world.x1);
    CHECK(big.world.y0 == one.world.y0);
    CHECK(big.world.y1 == one.world.y1);
    // measure_text answers in UI units: the same size as at scale 1
    const Vec2 measuredBig = g.renderer.measure_text("HHHH", 20, "", 0, RenderSpace::Screen);
    CHECK(measuredBig.x == doctest::Approx(measured.x).epsilon(0.05));
    CHECK(measuredBig.y == doctest::Approx(measured.y).epsilon(0.05));

    // half the size shrinks the same way
    w.set_ui_scale(0.5f);
    g.renderer.set_ui_scale(0.5f);
    const Boxes small = draw();
    const Ink half = ink(small.img, 60, 0, 140, 40);  // the panel, at 75 .. 105 x 5 .. 25 (the HUD text is smaller and elsewhere)
    REQUIRE(half.any());
    CHECK(half.x0 == 75);
    CHECK(half.w() == 30);
    CHECK(half.h() == 20);

    // back to normal: identical to the first frame
    w.set_ui_scale(1.0f);
    g.renderer.set_ui_scale(1.0f);
    const Boxes again = draw();
    CHECK(again.hud.w() == one.hud.w());
    CHECK(again.panel.x0 == one.panel.x0);
}

TEST_CASE("ui scale: the renderer clamps its scale to 0.5 .. 3 and ignores NaN") {
    Renderer r;
    CHECK(r.ui_scale() == 1.0f);
    r.set_ui_scale(1.5f);
    CHECK(r.ui_scale() == 1.5f);
    r.set_ui_scale(10.0f);
    CHECK(r.ui_scale() == kMaxUiScale);
    r.set_ui_scale(0.1f);
    CHECK(r.ui_scale() == kMinUiScale);
    r.set_ui_scale(std::nanf(""));
    CHECK(r.ui_scale() == 1.0f);
}
