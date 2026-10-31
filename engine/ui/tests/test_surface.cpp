// The pointer through a page: a render target shown on a mesh. The UI is given the page behind the pointer (UiSurfaceFn); the
// world-space Interactables are then the ones the page's camera sees, hit-tested at the point where the pointer lands on the page.
// Hover, click and slider drags are tested here with a fake page; the real mapping (mesh UVs) is tested in the runtime tests.
#include <doctest.h>

#include <string>
#include <vector>

#include "fa/scene/components.h"
#include "fa/ui/ui.h"
#include "ui_fixture.h"

using namespace fa;
using fa_ui_test::Ui;
using fa_ui_test::V;

namespace {

// The "screen": the design rectangle (100, 50, 100 x 50) shows a page of 200 x 100 pixels whose camera sits at world (1000, 0),
// one world unit per page pixel (page pixel = (100 + x - 1000, 50 - y)).
const Rect kScreen{100, 50, 100, 50};

struct Page {
    Ui t;
    Entity mesh;
    int calls = 0;

    Page() {
        mesh = t.w.create("screen", "screen");
        t.ui.set_surface_pointer([this](Vec2 p, const UiSurfacePin* pin) -> std::optional<UiSurface> {
            ++calls;
            if (!pin && !kScreen.contains(p)) return std::nullopt;
            UiSurface s;
            s.point = {(p.x - kScreen.x) * 2.0f, (p.y - kScreen.y) * 2.0f};  // a pinned pointer may be outside the rectangle
            s.project = [](Vec3 w, const Vec2*) { return Vec2{100.0f + (w.x - 1000.0f), 50.0f - w.y}; };
            s.pin = UiSurfacePin{mesh, 0};
            return s;
        });
    }

    // A rectangle of `size` page pixels centred on page pixel (px, py) (the page's camera looks at (1000, 0): y up).
    Entity item(const char* id, float px, float py, Vec2 size, InteractableKind kind = InteractableKind::Button) {
        Entity e = t.w.create(id, id);
        t.w.get<Transform>(e)->position = {1000.0f + px - 100.0f, 50.0f - py, 0};
        t.w.add<Shape2D>(e).size = size;
        t.w.add<Interactable>(e).kind = kind;
        return e;
    }
    // The screen point of page pixel (px, py).
    static Vec2 screen(float px, float py) { return {kScreen.x + px / 2.0f, kScreen.y + py / 2.0f}; }
    void move(Vec2 p) {
        t.in.on_mouse_move(p);
        t.frame();
    }
    void down() {
        t.in.on_mouse_button(MouseButton::Left, true);
        t.frame();
    }
    void up() {
        t.in.on_mouse_button(MouseButton::Left, false);
        t.frame();
    }
};

}  // namespace

TEST_CASE("surface pointer: an Interactable on the page is hovered and clicked through the page, off the main view") {
    Page p;
    Entity btn = p.item("btn", 40, 50, {40, 20});
    p.t.frame();
    p.t.events();
    p.move(Page::screen(40, 50));
    CHECK(p.t.ui.hovered() == btn);
    CHECK(p.t.w.get<Interactable>(btn)->hovered);
    p.move(Page::screen(40, 80));  // below the button on the page
    CHECK(p.t.ui.hovered() == kNullEntity);
    CHECK_FALSE(p.t.w.get<Interactable>(btn)->hovered);
    p.move(Page::screen(50, 55));
    p.t.events();
    p.down();
    CHECK(p.t.w.get<Interactable>(btn)->pressed);
    p.up();
    const V ev = p.t.events();
    std::string all;
    for (const std::string& s : ev) all += s + " ";
    const V want{"ui.focus:btn", "ui.press:btn", "ui.release:btn=true", "ui.click:btn"};
    CHECK_MESSAGE(ev == want, all);
    // Off the page, at the same screen point of the main view, nothing is there.
    p.move({10, 10});
    CHECK(p.t.ui.hovered() == kNullEntity);
    p.t.events();
    p.t.click({10, 10});
    CHECK(p.t.events().empty());
}

TEST_CASE("surface pointer: the page's Interactables replace the main view's while the pointer is on the page") {
    Page p;
    Entity onPage = p.item("onPage", 100, 50, {60, 30});
    // A world button of the main view that sits where the pointer is: the default view puts world (x, y) at (160 + x, 90 - y).
    Entity main = p.t.w.create("main", "main");
    p.t.w.get<Transform>(main)->position = {0, 0, 0};
    p.t.w.add<Shape2D>(main).size = {20, 20};
    p.t.w.add<Interactable>(main);
    p.t.frame();
    p.move({160, 90});  // the middle of the screen rectangle: page pixel (120, 80), not on "onPage" (centre (100, 50), 60 x 30)
    CHECK(p.t.ui.hovered() == kNullEntity);
    p.move({210, 90});  // outside the rectangle: the main view again
    p.move({160, 90 + 40});
    CHECK(p.t.ui.hovered() == kNullEntity);
    p.move(Page::screen(100, 50));
    CHECK(p.t.ui.hovered() == onPage);
    // A pointer off the page sees the main view's button.
    Page q;
    Entity m2 = q.t.w.create("main", "main");
    q.t.w.get<Transform>(m2)->position = {-100, 0, 0};
    q.t.w.add<Shape2D>(m2).size = {20, 20};
    q.t.w.add<Interactable>(m2);
    q.t.frame();
    q.move({60, 90});
    CHECK(q.t.ui.hovered() == m2);
}

TEST_CASE("surface pointer: a screen widget wins over the page under it") {
    Page p;
    p.item("btn", 100, 50, {80, 40});
    Entity screenButton = p.t.button("ok", {150, 70}, {20, 10});  // a built-in Button over the page's middle
    p.t.frame();
    p.move({160, 75});
    CHECK(p.t.ui.hovered() == screenButton);
    p.move({140, 70});  // page pixel (80, 40): on the page button, off the screen one
    CHECK(p.t.ui.hovered() != screenButton);
    CHECK(p.t.ui.hovered() != kNullEntity);
}

TEST_CASE("surface pointer: a button pressed on the page is not clicked when the pointer is released off it") {
    Page p;
    Entity btn = p.item("btn", 100, 50, {60, 30});
    p.t.frame();
    p.move(Page::screen(100, 50));
    p.t.events();
    p.down();
    p.move({300, 150});  // far outside the screen rectangle: the drag stays on the page, off the button
    CHECK(p.t.ui.hovered() == kNullEntity);
    CHECK(p.t.w.get<Interactable>(btn)->pressed);
    p.up();
    const V ev = p.t.events();
    CHECK(ev.back() == "ui.release:btn=false");
    for (const std::string& e : ev) CHECK(e != "ui.click:btn");
    // Back on the button it is a click again.
    p.move(Page::screen(100, 50));
    p.down();
    p.move(Page::screen(110, 55));
    p.up();
    CHECK(p.t.events().back() == "ui.click:btn");
}

TEST_CASE("surface pointer: a slider on the page follows a drag, beyond the ends of the screen rectangle too") {
    Page p;
    // 80 page pixels wide, from page x 60 to 140: min at the left.
    Entity bar = p.item("bar", 100, 50, {80, 10}, InteractableKind::Slider);
    Interactable& ia = *p.t.w.get<Interactable>(bar);
    ia.min = 0;
    ia.max = 100;
    p.t.frame();
    p.move(Page::screen(80, 50));  // a quarter of the track
    p.down();
    CHECK(ia.value == doctest::Approx(25));
    p.move(Page::screen(120, 50));
    CHECK(ia.value == doctest::Approx(75));
    p.move(Page::screen(120, 100));  // dragged off the bar vertically: still the value along the track
    CHECK(ia.value == doctest::Approx(75));
    p.move({1000, 90});  // far off the rectangle to the right of the screen: clamps to the end, the drag is not lost
    CHECK(ia.value == doctest::Approx(100));
    p.move({-500, 90});
    CHECK(ia.value == doctest::Approx(0));
    p.up();
    CHECK(p.t.ui.pointer_over_ui() == false);
    p.move(Page::screen(60, 50));
    CHECK(ia.value == doctest::Approx(0));  // released: moving does not drag any more
}

TEST_CASE("surface pointer: widget_at answers through the page") {
    Page p;
    Entity btn = p.item("btn", 40, 50, {40, 20});
    p.t.frame();
    CHECK(p.t.ui.widget_at(p.t.w, p.t.design, Page::screen(40, 50)) == btn);
    CHECK(p.t.ui.widget_at(p.t.w, p.t.design, Page::screen(150, 50)) == kNullEntity);
    CHECK(p.t.ui.widget_at(p.t.w, p.t.design, {10, 10}) == kNullEntity);
}

TEST_CASE("surface pointer: without a page hook nothing changes") {
    Ui t;
    Entity e = t.w.create("m", "m");
    t.w.get<Transform>(e)->position = {0, 0, 0};
    t.w.add<Shape2D>(e).size = {20, 20};
    t.w.add<Interactable>(e);
    t.frame();
    t.in.on_mouse_move({160, 90});
    t.frame();
    CHECK(t.ui.hovered() == e);
}
