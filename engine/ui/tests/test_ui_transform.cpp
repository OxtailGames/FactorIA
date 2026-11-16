// Widgets whose Transform (or a parent's) rotates or scales them: layout, hit tests, drag and drop, the TextField caret and
// navigation follow the oriented rectangle (ui_rect.h, "Rotation and scale").
#include <doctest.h>

#include <cmath>
#include <string>
#include <vector>

#include "fa/scene/ui_rect.h"
#include "fa/ui/ui.h"
#include "ui_fixture.h"

using namespace fa;

namespace {
using fa_ui_test::Ui;
using fa_ui_test::V;

constexpr float kCos45 = 0.70710678f;

void turn(Ui& t, Entity e, float degrees) { t.w.get<Transform>(e)->rotation = {0, 0, degrees}; }
void zoom(Ui& t, Entity e, float s) { t.w.get<Transform>(e)->scale = {s, s, 1}; }
}  // namespace

TEST_CASE("ui transform: a widget that does not turn or scale has the identity map and the old rectangle") {
    Ui t;
    const Entity b = t.button("b", {20, 30}, {80, 20});
    t.frame();
    CHECK(ui_transform(t.w, b, t.design).is_identity());
    CHECK(*ui_rect(t.w, b, t.design) == Rect{20, 30, 80, 20});
    CHECK(*ui_rect(t.w, b, t.design) == *ui_own_rect(t.w, b, t.design));
    CHECK(*ui_footprint_rect(t.w, b, t.design) == Rect{20, 30, 80, 20});
}

TEST_CASE("ui transform: a button turned 45 degrees is hit inside its corners and not in the corners of its bounding box") {
    Ui t;
    const Entity b = t.button("b", {160, 90}, {100, 20});
    t.w.get<Button>(b)->pivot = {0.5f, 0.5f};
    turn(t, b, 45);
    t.frame();
    const Rect box = *ui_rect(t.w, b, t.design);
    CHECK(box.w == doctest::Approx(60.0f * 2 * kCos45).epsilon(0.001));
    CHECK(box.center().x == doctest::Approx(160.0f));
    CHECK(box.center().y == doctest::Approx(90.0f));
    const Vec2 along{160.0f + 40.0f * kCos45, 90.0f + 40.0f * kCos45};  // on the long axis, 40 from the middle
    const Vec2 corner{160.0f + 40.0f, 90.0f - 40.0f};                    // inside the box, off the turned button
    CHECK(box.contains(corner));
    CHECK(ui_contains(t.w, b, t.design, along));
    CHECK_FALSE(ui_contains(t.w, b, t.design, corner));
    CHECK(ui_widget_at(t.w, t.design, along) == b);
    CHECK(ui_widget_at(t.w, t.design, corner) == kNullEntity);
    t.events();
    t.click(corner);
    CHECK(t.events() == V{});
    CHECK_FALSE(t.w.get<Button>(b)->hovered);
    t.click(along);
    CHECK(t.events() == V{"ui.focus:b", "ui.click:b"});
    t.in.on_mouse_move(along);
    t.frame();
    CHECK(t.w.get<Button>(b)->hovered);
    // and the point in its own frame is the unturned one
    const Vec2 local = ui_local_point(t.w, b, t.design, along);
    CHECK(local.x == doctest::Approx(200.0f).epsilon(0.001));  // 40 right of the middle, on the button's own axis
    CHECK(local.y == doctest::Approx(90.0f).epsilon(0.001));
}

TEST_CASE("ui transform: a child scaled by 2 takes twice the room in a row; a turned one keeps its slot") {
    Ui t;
    const Entity p = t.add<Panel>("p", {0, 0}, {400, 100});
    Panel& panel = *t.w.get<Panel>(p);
    panel.layout = UiLayout::Row;
    panel.spacing = 10;
    panel.padding = {0, 0, 0, 0};
    panel.align = UiAlign::Start;
    const Entity b1 = t.button("b1", {0, 0}, {80, 20}, p);
    const Entity b2 = t.button("b2", {0, 0}, {80, 20}, p);
    const Entity b3 = t.button("b3", {0, 0}, {80, 20}, p);
    t.w.get<Button>(b2)->pivot = {0.5f, 0.5f};
    zoom(t, b2, 2);
    turn(t, b3, 30);
    t.frame(2);
    CHECK(*ui_footprint_rect(t.w, b1, t.design) == Rect{0, 0, 80, 20});
    CHECK(*ui_footprint_rect(t.w, b2, t.design) == Rect{90, 0, 160, 40});
    CHECK(*ui_footprint_rect(t.w, b3, t.design) == Rect{260, 0, 80, 20});  // turned: its slot, its size
    CHECK(*ui_rect(t.w, b2, t.design) == Rect{90, 0, 160, 40});            // drawn and hit as large as its slot
    // the scaled button is hit 70 px from its middle, where an unscaled one ends at 40
    t.events();
    t.click({170 + 70, 20});
    CHECK(t.events() == V{"ui.focus:b2", "ui.click:b2"});
    // fit: the panel is as wide as the three slots and two gaps
    panel.fit = true;
    t.frame(2);
    CHECK(panel.size.x == doctest::Approx(80 + 10 + 160 + 10 + 80));
    CHECK(panel.size.y == doctest::Approx(40));
}

TEST_CASE("ui transform: a child of a turned panel turns around the panel's origin") {
    Ui t;
    const Entity p = t.add<Panel>("p", {100, 50}, {100, 100});
    turn(t, p, 90);
    const Entity c = t.button("c", {10, 10}, {20, 20}, p);
    t.frame();
    // layout space: (110, 60) .. (130, 80); a quarter turn clockwise around (100, 50) puts it at x 70..90, y 60..80
    const Rect r = *ui_rect(t.w, c, t.design);
    CHECK(r.x == doctest::Approx(70.0f).epsilon(0.001));
    CHECK(r.y == doctest::Approx(60.0f).epsilon(0.001));
    CHECK(r.w == doctest::Approx(20.0f).epsilon(0.001));
    CHECK(r.h == doctest::Approx(20.0f).epsilon(0.001));
    CHECK(ui_widget_at(t.w, t.design, {80, 70}) == c);
    CHECK(ui_widget_at(t.w, t.design, {120, 70}) != c);  // where it would be without the turn
    t.events();
    t.click({80, 70});
    CHECK(t.events() == V{"ui.focus:c", "ui.click:c"});
}

TEST_CASE("ui transform: a drop lands on the turned target, not in the corner of its bounding box") {
    Ui t;
    const Entity src = t.button("src", {10, 10}, {40, 20});
    t.w.get<Button>(src)->draggable = Json::object({{"payload", 1}});
    const Entity target = t.add<Panel>("target", {200, 90}, {100, 40});
    t.w.get<Panel>(target)->pivot = {0.5f, 0.5f};
    turn(t, target, 45);
    t.ui.set_drop_target(target, UiDropMode::Accept);
    t.frame();
    const auto drag_over = [&](Vec2 at) {
        t.in.on_mouse_move({20, 20});
        t.in.on_mouse_button(MouseButton::Left, true);
        t.frame();
        t.in.on_mouse_move(at);
        t.frame(2);
        const Json d = t.ui.drag_json(t.w);
        const std::string id = d.is_object() && d["target"].is_string() ? d["target"].get<std::string>() : "";
        t.in.on_mouse_button(MouseButton::Left, false);
        t.frame(2);
        t.events();
        return id;
    };
    CHECK(drag_over({200 + 40 * kCos45, 90 + 40 * kCos45}) == "target");  // along its long axis
    CHECK(drag_over({200 + 30, 90 - 30}) == "");                          // in its box, off the turned panel
}

TEST_CASE("ui transform: a click on a turned TextField puts the caret where the text is under the pointer") {
    Ui t;
    const Entity e = t.add<TextField>("f", {100, 0}, {400, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.maxLength = 0;
    f.text = "hello brave world";
    turn(t, e, 90);  // the field runs downwards from (100, 0), its top edge on the left
    t.frame();
    t.events();
    // unturned a click at local x 12 + 14.4 * 2 + 2 puts the caret at 2 (test_textfield.cpp); turned a quarter, that point is
    // at (100 - y_local, x_local)
    const float xl = 12.0f + 14.4f * 2.0f + 2.0f;
    t.click({100.0f - 15.0f, xl});
    CHECK(f.caretIndex == 2);
    CHECK(f.selectionStart == 2);
    // the IME caret box follows the turned field
    t.frame();
    CHECK(f.focused);
}

TEST_CASE("ui transform: gamepad navigation follows where turned widgets are") {
    Ui t;
    const Entity p = t.add<Panel>("p", {200, 0}, {10, 10});
    turn(t, p, 90);  // a row of buttons along +x becomes a column down the screen
    const Entity b1 = t.button("b1", {0, 0}, {40, 20}, p);
    const Entity b2 = t.button("b2", {50, 0}, {40, 20}, p);
    const Entity b3 = t.button("b3", {100, 0}, {40, 20}, p);
    t.w.get<Button>(b1)->autoFocus = true;
    t.frame(2);
    CHECK(t.ui.focused() == b1);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == b2);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == b3);
    t.tap_key(Key::Right);  // nothing is to the right of a column
    CHECK(t.ui.focused() == b3);
    t.tap_key(Key::Up);
    CHECK(t.ui.focused() == b2);
}

TEST_CASE("ui transform: a turned ScrollList clips to its bounding box but the pointer hits only the turned list") {
    Ui t;
    const Entity list = t.add<ScrollList>("list", {100, 50}, {100, 100});
    turn(t, list, 45);
    const Entity b = t.button("b", {0, 0}, {20, 20}, list);
    t.frame();
    CHECK_FALSE(ui_transform(t.w, list, t.design).axis_aligned());
    CHECK(ui_transform(t.w, b, t.design).is_identity() == false);
    CHECK(ui_clip_contains(t.w, b, t.design, {100, 120}));        // inside the turned list
    CHECK_FALSE(ui_clip_contains(t.w, b, t.design, {165, 60}));  // in the bounding box only
    const Rect clip = *ui_clip_rect(t.w, b, t.design);           // the scissor
    CHECK(clip.contains({165, 60}));
    // a quarter turn stays axis aligned: no warning, an exact clip
    turn(t, list, 90);
    CHECK(ui_transform(t.w, list, t.design).axis_aligned());
}
