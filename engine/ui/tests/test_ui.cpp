#include <doctest.h>

#include <string>
#include <vector>

#include "fa/ui/ui.h"

using namespace fa;

namespace {

// A world with the default ui_* actions, a UiSystem and helpers to build widgets and press things. The design size is
// 320 x 180; widgets use pivot [0, 1] so their position is their top-left corner.
struct Ui {
    World w;
    Input in;
    UiSystem ui;
    Vec2 design{320, 180};
    float dt = 1.0f / 64.0f;  // exactly representable: repeat timings do not depend on rounding

    Ui() {
        ensure_builtin_components();
        in.set_actions(ui_with_default_actions(Json::object()));
    }

    template <class T>
    Entity add(const char* id, Vec2 pos, Vec2 size, Entity parent = kNullEntity) {
        Entity e = w.create(id, id);
        if (parent) w.set_parent(e, parent);
        w.get<Transform>(e)->position = {pos.x, pos.y, 0};
        T& c = w.add<T>(e);
        c.size = size;
        c.pivot = {0, 1};
        return e;
    }
    Entity button(const char* id, Vec2 pos, Vec2 size = {80, 20}, Entity parent = kNullEntity) {
        return add<Button>(id, pos, size, parent);
    }
    Rect rect(Entity e) { return *ui_rect(w, e, design); }

    void frame(int n = 1) {
        for (int i = 0; i < n; ++i) {
            ui.update(w, in, design, dt, {});
            in.begin_frame();
        }
    }
    // The ui.* events since the last call, as "name:id" or "name:id=value".
    std::vector<std::string> events() {
        std::vector<std::string> out;
        for (const GameEvent& e : w.events().game) {
            std::string s = e.name + ":" + (e.data["id"].is_null() ? std::string("null") : e.data["id"].get<std::string>());
            if (e.data.contains("value")) s += "=" + e.data["value"].dump();
            CHECK((e.source == kNullEntity) == e.data["id"].is_null());
            out.push_back(s);
        }
        w.events().game.clear();
        return out;
    }
    // Presses a key / pad button / mouse button for one frame and releases it for another.
    void tap_key(Key k) {
        in.on_key(k, true);
        frame();
        in.on_key(k, false);
        frame();
    }
    void tap_pad(GamepadButton b) {
        in.on_gamepad_button(0, b, true);
        frame();
        in.on_gamepad_button(0, b, false);
        frame();
    }
    void click(Vec2 p) {
        in.on_mouse_move(p);
        in.on_mouse_button(MouseButton::Left, true);
        frame();
        in.on_mouse_button(MouseButton::Left, false);
        frame();
    }
};

using V = std::vector<std::string>;

}  // namespace

// ------------------------------------------------------------------------------------------------------- layout --
TEST_CASE("ui layout: column places children with spacing, padding and cross-axis alignment") {
    Ui t;
    Entity p = t.add<Panel>("p", {100, 50}, {200, 150});
    Panel& panel = *t.w.get<Panel>(p);
    panel.layout = UiLayout::Column;
    panel.spacing = 10;
    panel.padding = {10, 10, 10, 10};
    Entity a = t.button("a", {0, 0}, {100, 20}, p), b = t.button("b", {5, 5}, {60, 30}, p);
    t.ui.layout(t.w, t.design, {});
    // inner box x 110..290, y 60..; align center (default): a is 100 wide, b is 60 wide
    CHECK(t.rect(a).x == doctest::Approx(150)); CHECK(t.rect(a).y == doctest::Approx(60));
    CHECK(t.rect(b).x == doctest::Approx(170)); CHECK(t.rect(b).y == doctest::Approx(90));
    panel.align = UiAlign::Start;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(a).x == doctest::Approx(110)); CHECK(t.rect(b).x == doctest::Approx(110));
    panel.align = UiAlign::End;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(a).x == doctest::Approx(190)); CHECK(t.rect(b).x == doctest::Approx(230));
    // main axis: the run is 20 + 10 + 30 = 60 high in an inner height of 130
    panel.justify = UiAlign::Center;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(a).y == doctest::Approx(60 + 35));
    panel.justify = UiAlign::End;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(b).y == doctest::Approx(60 + 130 - 30));
    t.ui.layout(t.w, t.design, {});  // idempotent
    CHECK(t.rect(b).y == doctest::Approx(60 + 130 - 30));
}

TEST_CASE("ui layout: row, grid and children that are not widgets") {
    Ui t;
    Entity p = t.add<Panel>("p", {0, 0}, {300, 100});
    Panel& panel = *t.w.get<Panel>(p);
    panel.layout = UiLayout::Row;
    panel.spacing = 5;
    panel.padding = {0, 0, 0, 0};
    panel.align = UiAlign::Start;
    Entity a = t.button("a", {40, 40}, {50, 20}, p), b = t.button("b", {0, 0}, {30, 40}, p);
    // a screen-space Text is placed by the box of its text (approximated without a renderer: 0.6 em per char)
    Entity label = t.w.create("label", "label");
    t.w.set_parent(label, p);
    Text& txt = t.w.add<Text>(label);
    txt.text = "abcd"; txt.fontSize = 10; txt.space = RenderSpace::Screen; txt.pivot = {0, 1};
    Entity hidden = t.button("hidden", {0, 0}, {10, 10}, p);
    t.w.set_active(hidden, false);
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(a).x == doctest::Approx(0));  CHECK(t.rect(a).y == doctest::Approx(0));
    CHECK(t.rect(b).x == doctest::Approx(55)); CHECK(t.rect(b).y == doctest::Approx(0));
    const Vec3 lp = t.w.world_matrix(label).translation();
    CHECK(lp.x == doctest::Approx(90));  // 55 + 30 + 5
    CHECK(lp.y == doctest::Approx(0));

    panel.layout = UiLayout::Grid;
    panel.columns = 2;
    panel.spacing = 10;
    panel.padding = {10, 10, 10, 10};
    panel.align = UiAlign::Start;
    t.ui.layout(t.w, t.design, {});
    // cells: widest child 50 (a), tallest 40 (b); three children in 2 columns
    CHECK(t.rect(a).x == doctest::Approx(10));  CHECK(t.rect(a).y == doctest::Approx(10));
    CHECK(t.rect(b).x == doctest::Approx(70));  CHECK(t.rect(b).y == doctest::Approx(10));
    CHECK(t.w.world_matrix(label).translation().x == doctest::Approx(10));
    CHECK(t.w.world_matrix(label).translation().y == doctest::Approx(60));
    panel.align = UiAlign::Center;  // inside the cell
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(b).x == doctest::Approx(70 + 10));
    CHECK(t.rect(a).y == doctest::Approx(10 + 10));
}

TEST_CASE("ui layout: fit sizes the panel to its content, nested panels are sized first") {
    Ui t;
    Entity outer = t.add<Panel>("outer", {20, 20}, {10, 10});
    Entity inner = t.add<Panel>("inner", {0, 0}, {10, 10}, outer);
    Entity a = t.button("a", {0, 0}, {100, 20}, inner), b = t.button("b", {0, 0}, {60, 30}, inner);
    Panel& o = *t.w.get<Panel>(outer);
    Panel& i = *t.w.get<Panel>(inner);
    i.layout = UiLayout::Column; i.fit = true; i.spacing = 10; i.padding = {10, 10, 10, 10};
    o.layout = UiLayout::Row; o.fit = true; o.spacing = 4; o.padding = {5, 5, 5, 5}; o.align = UiAlign::Start;
    Entity c = t.button("c", {0, 0}, {40, 90}, outer);
    t.ui.layout(t.w, t.design, {});
    CHECK(i.size.x == doctest::Approx(120)); CHECK(i.size.y == doctest::Approx(80));   // 100 + 2*10, 20+10+30 + 2*10
    CHECK(o.size.x == doctest::Approx(5 + 120 + 4 + 40 + 5)); CHECK(o.size.y == doctest::Approx(90 + 10));
    // the pivot [0, 1] keeps the top-left corner of the fitted box on the position
    CHECK(t.rect(outer).x == doctest::Approx(20)); CHECK(t.rect(outer).y == doctest::Approx(20));
    CHECK(t.rect(inner).x == doctest::Approx(25)); CHECK(t.rect(inner).y == doctest::Approx(25));
    CHECK(t.rect(a).x == doctest::Approx(25 + 10 + 0)); CHECK(t.rect(a).y == doctest::Approx(35));
    CHECK(t.rect(b).y == doctest::Approx(65));
    CHECK(t.rect(c).x == doctest::Approx(5 + 20 + 120 + 4));
    // a centred pivot keeps the centre fixed
    t.w.get<Panel>(outer)->pivot = {0.5f, 0.5f};
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(outer).center().x == doctest::Approx(20)); CHECK(t.rect(outer).center().y == doctest::Approx(20));
}

TEST_CASE("ui layout: anchor and pivot place a widget in the screen") {
    Ui t;
    Entity e = t.button("e", {0, 0}, {100, 40});
    Button& b = *t.w.get<Button>(e);
    b.anchor = {0.5f, 0.5f};
    b.pivot = {0.5f, 0.5f};
    CHECK(t.rect(e).x == doctest::Approx(110)); CHECK(t.rect(e).y == doctest::Approx(70));
    b.anchor = {1, 1}; b.pivot = {1, 0};  // bottom-right corner of the widget on the bottom-right corner of the screen
    CHECK(t.rect(e).x == doctest::Approx(220)); CHECK(t.rect(e).y == doctest::Approx(140));
    CHECK(visual_footprints(t.w, e).size() == 1);
    CHECK(std::string(visual_footprints(t.w, e)[0].component) == "Button");
}

// ------------------------------------------------------------------------------------------------ focus rules --
TEST_CASE("ui focus: nothing takes focus by itself, autoFocus takes it when nothing is focused") {
    Ui t;
    Entity a = t.button("a", {0, 0}), b = t.button("b", {0, 40});
    t.tap_key(Key::Down);
    t.tap_key(Key::Enter);
    t.tap_pad(GamepadButton::A);
    CHECK(t.ui.focused() == kNullEntity);
    CHECK(t.events().empty());  // Space / A never click a button that is not focused
    t.w.get<Button>(b)->autoFocus = true;
    t.frame();
    CHECK(t.ui.focused() == b);
    CHECK(t.events() == V{"ui.focus:b"});
    CHECK(t.w.get<Button>(b)->focused);
    t.w.get<Button>(a)->autoFocus = true;  // already focused: stays
    t.frame();
    CHECK(t.ui.focused() == b);
    CHECK(t.events().empty());
}

TEST_CASE("ui focus: the first autoFocus widget in reading order wins; focus lost -> autoFocus applies again") {
    Ui t;
    Entity low = t.button("low", {0, 100}), right = t.button("right", {100, 0}), left = t.button("left", {0, 0});
    for (Entity e : {low, right, left}) t.w.get<Button>(e)->autoFocus = true;
    t.frame();
    CHECK(t.ui.focused() == left);  // top, then left
    t.w.get<Button>(left)->interactable = false;
    t.frame();
    CHECK(t.ui.focused() == right);
    t.w.set_active(right, false);
    t.frame();
    CHECK(t.ui.focused() == low);
    t.w.destroy(low);
    t.w.flush();
    t.frame();
    CHECK(t.ui.focused() == kNullEntity);
    CHECK_FALSE(t.w.get<Button>(left)->focused);
}

TEST_CASE("ui focus: set_focus validates, reset clears") {
    Ui t;
    Entity a = t.button("a", {0, 0}), p = t.add<Panel>("p", {0, 40}, {50, 50});
    CHECK(t.ui.set_focus(t.w, a));
    CHECK(t.events() == V{"ui.focus:a"});
    CHECK_FALSE(t.ui.set_focus(t.w, p));  // a Panel cannot take focus
    CHECK(t.ui.focused() == a);
    t.w.get<Button>(a)->interactable = false;
    t.frame();  // the focused widget stopped being interactable: it loses focus
    CHECK(t.ui.focused() == kNullEntity);
    t.w.get<Button>(a)->interactable = true;
    CHECK(t.ui.set_focus(t.w, a));
    CHECK(t.ui.set_focus(t.w, kNullEntity));
    CHECK(t.ui.focused() == kNullEntity);
    CHECK(t.ui.set_focus(t.w, a));
    t.ui.reset();
    CHECK(t.ui.focused() == kNullEntity);
}

TEST_CASE("ui navigation: nearest widget in the pressed direction, no wrap") {
    Ui t;
    // 2 x 2 grid plus one far below
    Entity tl = t.button("tl", {0, 0}), tr = t.button("tr", {100, 0}), bl = t.button("bl", {0, 40}), br = t.button("br", {100, 40});
    Entity low = t.button("low", {0, 120});
    t.ui.set_focus(t.w, tl);
    t.events();
    t.tap_key(Key::Right);
    CHECK(t.ui.focused() == tr);
    t.tap_key(Key::Right);
    CHECK(t.ui.focused() == tr);  // nothing further right: stays
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == br);
    t.tap_pad(GamepadButton::DpadLeft);
    CHECK(t.ui.focused() == bl);
    t.tap_pad(GamepadButton::DpadUp);
    CHECK(t.ui.focused() == tl);
    t.tap_key(Key::Up);
    CHECK(t.ui.focused() == tl);  // no wrap
    t.tap_key(Key::Down);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == low);
    CHECK(t.events() == V{"ui.focus:tr", "ui.focus:br", "ui.focus:bl", "ui.focus:tl", "ui.focus:bl", "ui.focus:low"});
    // the left stick works too, once past the deadzone
    t.in.on_gamepad_axis(0, GamepadAxis::LeftY, 1.0f);  // +Y is up on the stick
    t.frame();
    CHECK(t.ui.focused() == bl);
    t.in.on_gamepad_axis(0, GamepadAxis::LeftY, 0.0f);
    t.frame();
    // the candidate must be in the half-plane: aligned widgets are not "to the right"
    t.ui.set_focus(t.w, bl);
    t.tap_key(Key::Left);
    CHECK(t.ui.focused() == bl);
}

TEST_CASE("ui navigation: a held direction repeats after 0.4 s, then every 0.1 s") {
    Ui t;
    std::vector<Entity> col;
    for (int i = 0; i < 12; ++i) col.push_back(t.button(("b" + std::to_string(i)).c_str(), {0, float(i) * 30}));
    t.ui.set_focus(t.w, col[0]);
    auto index = [&] { for (int i = 0; i < 12; ++i) if (t.ui.focused() == col[std::size_t(i)]) return i; return -1; };
    t.in.on_key(Key::Down, true);
    t.frame();
    CHECK(index() == 1);   // the press itself
    t.frame(19);           // 0.30 s held
    CHECK(index() == 1);
    t.frame(11);           // 0.47 s held: the first repeat came at 0.4 s
    CHECK(index() == 2);
    t.frame(30);           // 0.94 s held: about one step per 0.1 s since 0.4 s
    CHECK(index() >= 6);
    CHECK(index() <= 8);
    t.in.on_key(Key::Down, false);
    const int stopped = index();
    t.frame(30);
    CHECK(index() == stopped);
}

// ------------------------------------------------------------------------------------------------------ widgets --
TEST_CASE("ui button: ui_submit on the focused button clicks (keys and pad), mouse clicks, interactable false is inert") {
    Ui t;
    Entity a = t.button("a", {0, 0}), b = t.button("b", {100, 0});
    t.w.get<Button>(a)->autoFocus = true;
    t.frame();
    t.events();
    t.tap_key(Key::Enter);
    CHECK(t.events() == V{"ui.click:a"});
    t.tap_key(Key::Space);
    CHECK(t.events() == V{"ui.click:a"});
    t.tap_pad(GamepadButton::A);
    CHECK(t.events() == V{"ui.click:a"});
    t.tap_pad(GamepadButton::B);
    CHECK(t.events() == V{"ui.cancel:a"});
    // a click focuses and clicks the widget under the pointer (and says so)
    t.click({140, 10});
    CHECK(t.events() == V{"ui.focus:b", "ui.click:b"});
    CHECK(t.ui.focused() == b);
    // pressed on one widget and released over another: no click
    t.in.on_mouse_move({10, 10});
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    CHECK(t.w.get<Button>(a)->pressed);
    t.in.on_mouse_move({140, 10});
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    CHECK(t.events() == V{"ui.focus:a"});
    CHECK_FALSE(t.w.get<Button>(a)->pressed);
    // not interactable: never hovered, focused or clicked
    t.w.get<Button>(b)->interactable = false;
    t.click({140, 10});
    CHECK(t.events().empty());
    CHECK_FALSE(t.w.get<Button>(b)->hovered);
    CHECK(t.ui.hovered() == kNullEntity);
    // Escape with nothing focused still sends ui.cancel, with a null id (autoFocus would take the focus back)
    t.w.get<Button>(a)->autoFocus = false;
    t.ui.set_focus(t.w, kNullEntity);
    t.events();
    t.tap_key(Key::Escape);
    CHECK(t.events() == V{"ui.cancel:null"});
}

TEST_CASE("ui hover: the top-most visible widget wins (layer, then creation order)") {
    Ui t;
    Entity back = t.button("back", {0, 0}, {100, 40}), front = t.button("front", {50, 0}, {100, 40});
    t.in.on_mouse_move({60, 10});
    t.frame();
    CHECK(t.ui.hovered() == front);  // equal layers: the later entity
    CHECK(t.w.get<Button>(front)->hovered);
    t.w.get<Button>(back)->layer = 300;
    t.frame();
    CHECK(t.ui.hovered() == back);
    CHECK_FALSE(t.w.get<Button>(front)->hovered);
    t.in.on_mouse_move({10, 10});
    t.frame();
    CHECK(t.ui.hovered() == back);
    t.in.on_mouse_move({400, 10});
    t.frame();
    CHECK(t.ui.hovered() == kNullEntity);
}

TEST_CASE("ui toggle: flips on ui_submit and on click, sends ui.change with the value") {
    Ui t;
    Entity e = t.add<Toggle>("t", {0, 0}, {120, 30});
    t.w.get<Toggle>(e)->autoFocus = true;
    t.frame();
    t.events();
    t.tap_key(Key::Enter);
    CHECK(t.w.get<Toggle>(e)->value);
    CHECK(t.events() == V{"ui.change:t=true"});
    t.tap_pad(GamepadButton::A);
    CHECK_FALSE(t.w.get<Toggle>(e)->value);
    CHECK(t.events() == V{"ui.change:t=false"});
    t.click({10, 10});
    CHECK(t.w.get<Toggle>(e)->value);
    CHECK(t.events() == V{"ui.change:t=true"});
}

TEST_CASE("ui slider: left / right change the value by step, clamp, snap; the mouse drags the knob") {
    Ui t;
    Entity e = t.add<Slider>("s", {0, 0}, {320, 40});
    Slider& s = *t.w.get<Slider>(e);
    s.autoFocus = true;
    s.value = 0.5f;
    t.frame();
    t.events();
    t.tap_key(Key::Right);
    CHECK(s.value == doctest::Approx(0.6f));
    CHECK(t.events() == V{"ui.change:s=0.6"});
    t.tap_pad(GamepadButton::DpadLeft);
    t.tap_pad(GamepadButton::DpadLeft);
    CHECK(s.value == doctest::Approx(0.4f));
    for (int i = 0; i < 12; ++i) t.tap_key(Key::Left);
    CHECK(s.value == doctest::Approx(0.0f));  // clamped at min
    t.events();
    t.tap_key(Key::Left);
    CHECK(t.events().empty());                // no change, no event
    s.min = 0; s.max = 10; s.step = 3; s.value = 6;
    t.tap_key(Key::Right);
    CHECK(s.value == doctest::Approx(9.0f));
    t.tap_key(Key::Right);
    CHECK(s.value == doctest::Approx(10.0f)); // the largest value is the end of the range even off the step grid
    s.step = 0;                               // continuous: (max - min) / 20 per press
    s.value = 5;
    t.tap_key(Key::Right);
    CHECK(s.value == doctest::Approx(5.5f));
    // mouse: no label, so the track covers 8 + 8 px inside 85% of the width
    s.min = 0; s.max = 1; s.step = 0.1f;
    const auto [left, right] = ui_slider_track(s, t.rect(e));
    t.events();
    t.in.on_mouse_move({left + (right - left) * 0.73f, 20});
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    CHECK(s.value == doctest::Approx(0.7f));          // snapped to the step
    t.in.on_mouse_move({left + (right - left) * 0.2f, 100});  // dragging may leave the widget vertically
    t.frame();
    CHECK(s.value == doctest::Approx(0.2f));
    t.in.on_mouse_move({right + 50, 20});
    t.frame();
    CHECK(s.value == doctest::Approx(1.0f));
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    CHECK(t.events() == V{"ui.change:s=0.7", "ui.change:s=0.2", "ui.change:s=1.0"});
}

TEST_CASE("ui textfield: typing, backspace with repeat, maxLength in code points, Enter submits, Space types a space") {
    Ui t;
    Entity e = t.add<TextField>("f", {0, 0}, {200, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.maxLength = 5;
    t.frame();
    t.events();
    for (char32_t c : std::u32string(U"ab\x01" U"c\x7f")) t.in.on_text(c);  // control characters are skipped
    t.frame();
    CHECK(f.text == "abc");
    CHECK(t.events() == V{"ui.change:f=\"abc\""});  // one event for the frame
    t.in.on_text(U' ');
    t.in.on_key(Key::Space, true);
    t.frame();
    t.in.on_key(Key::Space, false);
    t.frame();
    CHECK(f.text == "abc ");
    t.events();
    for (char32_t c : std::u32string(U"éééé")) t.in.on_text(c);  // only one fits: maxLength counts code points
    t.frame();
    CHECK(f.text == "abc \xC3\xA9");
    t.events();
    t.in.on_key(Key::Backspace, true);
    t.frame();
    CHECK(f.text == "abc ");  // removes a whole code point
    t.frame(26);              // held 0.41 s: one repeat
    CHECK(f.text == "abc");
    t.in.on_key(Key::Backspace, false);
    t.frame();
    t.events();
    t.tap_key(Key::Enter);
    CHECK(t.events() == V{"ui.submit:f=\"abc\""});
    f.maxLength = 0;  // unlimited
    for (int i = 0; i < 20; ++i) t.in.on_text(U'x');
    t.frame();
    CHECK(f.text.size() == 23);
    // left / right do nothing, up / down would leave the field (nothing to go to here)
    t.events();
    t.tap_key(Key::Left);
    CHECK(t.events().empty());
    CHECK(t.ui.focused() == e);
    // the caret blinks on the UI clock and restarts visible after an edit
    t.frame(3);
    CHECK(f.caret);
    t.frame(40);  // 0.64 s later
    CHECK_FALSE(f.caret);
    t.in.on_text(U'y');
    t.frame();
    CHECK(f.caret);
}

TEST_CASE("ui scroll list: wheel scrolls the innermost list, clamps, focus scrolls into view, hits are clipped") {
    Ui t;
    Entity list = t.add<ScrollList>("list", {0, 0}, {100, 50});
    ScrollList& sl = *t.w.get<ScrollList>(list);
    sl.padding = {0, 0, 0, 0};
    sl.spacing = 0;
    std::vector<Entity> items;
    for (int i = 0; i < 4; ++i) items.push_back(t.button(("i" + std::to_string(i)).c_str(), {0, 0}, {100, 20}, list));
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(items[0]).y == doctest::Approx(0));
    CHECK(t.rect(items[3]).y == doctest::Approx(60));
    // the item below the list's bottom edge is clipped away: the pointer over it hits nothing
    t.in.on_mouse_move({50, 70});
    t.frame();
    CHECK(t.ui.hovered() == kNullEntity);
    t.in.on_mouse_move({50, 30});
    t.frame();
    CHECK(t.ui.hovered() == items[1]);
    // wheel down: content 80 high in 50 -> at most 30 pixels
    t.in.on_mouse_wheel(-1);
    t.frame();
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(30));  // 40 clamped
    CHECK(t.rect(items[0]).y == doctest::Approx(-30));
    CHECK(t.rect(items[3]).y == doctest::Approx(30));
    t.in.on_mouse_move({50, 5});  // over item 1 now (y -10..10)
    t.frame();
    CHECK(t.ui.hovered() == items[1]);
    t.in.on_mouse_move({50, -5});  // still over item 1, but above the list: clipped away
    t.frame();
    CHECK(t.ui.hovered() == kNullEntity);
    t.in.on_mouse_move({50, 25});  // over the list again
    t.in.on_mouse_wheel(1);
    t.frame();
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(0));
    // wheel outside the list does nothing
    t.in.on_mouse_move({200, 5});
    t.in.on_mouse_wheel(-1);
    t.frame();
    CHECK(sl.scroll == doctest::Approx(0));
    // focusing an item scrolls just enough to show it, once; the wheel can still move the list afterwards
    CHECK(t.ui.set_focus(t.w, items[3]));
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(30));
    t.in.on_mouse_move({50, 20});
    t.in.on_mouse_wheel(1);
    t.frame();
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(0));
    CHECK(t.ui.set_focus(t.w, items[2]));
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(10));  // item 2 spans 40..60, the inner box shows 10..60
    // keyboard navigation moves focus through scrolled-out items and keeps them visible
    t.ui.set_focus(t.w, items[0]);
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(0));
    for (int i = 0; i < 3; ++i) t.tap_key(Key::Down);
    CHECK(t.ui.focused() == items[3]);
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(30));
}

TEST_CASE("ui scroll list: a script may write scroll; it is clamped") {
    Ui t;
    Entity list = t.add<ScrollList>("list", {0, 0}, {100, 50});
    ScrollList& sl = *t.w.get<ScrollList>(list);
    sl.padding = {0, 0, 0, 0};
    sl.spacing = 5;
    for (int i = 0; i < 3; ++i) t.button(("i" + std::to_string(i)).c_str(), {0, 0}, {100, 30}, list);
    sl.scroll = 1000;
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(100 - 50));  // 3 * 30 + 2 * 5
    sl.scroll = -5;
    t.ui.layout(t.w, t.design, {});
    CHECK(sl.scroll == doctest::Approx(0));
}

// ------------------------------------------------------------------------------------------------------- state --
TEST_CASE("ui.state lists the widgets in reading order with their state") {
    Ui t;
    Entity b = t.button("play", {100, 0}, {80, 20});
    Entity s = t.add<Slider>("vol", {0, 40}, {160, 20});
    Entity f = t.add<TextField>("name", {0, 0}, {90, 20});
    t.add<Panel>("bg", {0, 100}, {50, 50});
    t.w.get<Button>(b)->text = "Play";
    t.w.get<Button>(b)->autoFocus = true;
    t.w.get<Slider>(s)->value = 0.25f;
    t.w.get<TextField>(f)->text = "Ann";
    t.in.on_mouse_move({150, 10});
    t.frame();
    Json st = t.ui.state(t.w, t.design);
    CHECK(st["focused"] == "play");
    CHECK(st["hovered"] == "play");
    REQUIRE(st["widgets"].size() == 4);
    CHECK(st["widgets"][0]["id"] == "name");   // top, then left
    CHECK(st["widgets"][0]["kind"] == "TextField");
    CHECK(st["widgets"][0]["text"] == "Ann");
    CHECK(st["widgets"][1]["id"] == "play");
    CHECK(st["widgets"][1]["rect"] == Json::parse("[100, 0, 80, 20]"));
    CHECK(st["widgets"][1]["focused"] == true);
    CHECK(st["widgets"][1]["hovered"] == true);
    CHECK(st["widgets"][1]["text"] == "Play");
    CHECK(st["widgets"][2]["id"] == "vol");
    CHECK(st["widgets"][2]["value"] == 0.25);
    CHECK(st["widgets"][3]["kind"] == "Panel");
    CHECK(st["widgets"][3]["interactable"] == false);
    t.w.set_active(b, false);
    CHECK(t.ui.state(t.w, t.design)["widgets"].size() == 3);  // inactive widgets are not listed
}

TEST_CASE("ui actions: the defaults are installed unless the project defines the action") {
    Json project = Json::parse(R"({"jump": ["Space"], "ui_submit": ["X"]})");
    Json merged = ui_with_default_actions(project);
    CHECK(merged["jump"] == Json::parse(R"(["Space"])"));
    CHECK(merged["ui_submit"] == Json::parse(R"(["X"])"));  // the project wins
    CHECK(merged["ui_cancel"] == Json::parse(R"(["Escape", "GamepadB"])"));
    CHECK(merged["ui_up"].size() == 3);
    CHECK(ui_with_default_actions(nullptr).size() == 6);
    Input in;
    CHECK(in.set_actions(merged).empty());  // every default binding name is valid
    CHECK(in.has_action("ui_left"));
    // a project that rebinds ui_submit: Enter no longer clicks
    Ui t;
    t.in.set_actions(merged);
    Entity a = t.button("a", {0, 0});
    t.w.get<Button>(a)->autoFocus = true;
    t.frame();
    t.events();
    t.tap_key(Key::Enter);
    CHECK(t.events().empty());
    t.tap_key(Key::X);
    CHECK(t.events() == V{"ui.click:a"});
}

// ------------------------------------------------------------------------------------------------ on-screen gamepad --
TEST_CASE("on-screen gamepad: a stick and a button feed the pad actions, several fingers at once, and keep their fingers") {
    Ui t;
    t.in.set_actions(ui_with_default_actions(Json::parse(R"({
        "move_left": ["A", "GamepadLeftStickLeft"], "move_right": ["D", "GamepadLeftStickRight"],
        "move_up": ["GamepadLeftStickUp"], "aim_right": ["GamepadRightStickRight"],
        "jump": ["Space", "GamepadA"], "fire": ["MouseLeft", "Touch"]})")));
    t.in.set_gamepad_deadzone(0.0f);  // the raw stick values reach the actions
    const Entity stick = t.add<TouchStick>("stick", {10, 80}, {80, 80});  // centre (50, 120), radius 40
    const Entity jump = t.add<TouchButton>("jump", {240, 100}, {60, 60});
    t.frame();
    CHECK_FALSE(t.w.get<TouchStick>(stick)->shown);  // touchOnly: hidden until the player touches the screen
    REQUIRE(t.in.touch_controls().size() == 2);

    t.in.on_touch_begin(1, {50, 120});  // the stick's centre
    t.in.on_touch_move(1, {90, 120});   // its right edge: full tilt
    t.in.on_touch_begin(2, {270, 130}); // a second finger on the button
    CHECK(t.in.action_value("move_right") == doctest::Approx(1.0f));
    CHECK(t.in.action_value("move_left") == 0.0f);
    CHECK(t.in.action_value("aim_right") == 0.0f);  // the left stick, not the right one
    CHECK(t.in.action_pressed("jump"));
    CHECK_FALSE(t.in.action_down("fire"));  // the fingers belong to the pad: no Touch binding, no mouse
    CHECK_FALSE(t.in.mouse_down(MouseButton::Left));
    CHECK(t.in.touches().empty());
    CHECK_FALSE(t.in.gamepad_connected(0));  // the touch pad has no number
    CHECK(t.in.last_device() == InputDevice::Touch);
    t.frame();
    CHECK(t.w.get<TouchStick>(stick)->shown);
    CHECK(t.w.get<TouchStick>(stick)->pressed);
    CHECK(t.w.get<TouchStick>(stick)->value.x == doctest::Approx(1.0f));
    CHECK(t.w.get<TouchButton>(jump)->pressed);
    CHECK(t.ui.state(t.w, t.design)["widgets"][0]["kind"] == "TouchStick");

    t.in.on_touch_move(1, {0, 70});  // outside the disc, up-left: still the stick's, clamped to full tilt
    CHECK(t.in.action_value("move_left") == doctest::Approx(0.7071f).epsilon(0.001));
    CHECK(t.in.action_value("move_up") == doctest::Approx(0.7071f).epsilon(0.001));
    t.in.on_touch_end(2);
    CHECK(t.in.action_released("jump"));
    t.in.on_touch_end(1);
    CHECK(t.in.action_value("move_left") == 0.0f);
    t.frame();
    CHECK_FALSE(t.w.get<TouchStick>(stick)->pressed);
    CHECK(t.w.get<TouchStick>(stick)->value == Vec2{0, 0});

    t.in.on_touch_begin(3, {160, 20});  // a finger anywhere else is an ordinary touch
    CHECK(t.in.action_down("fire"));
    CHECK(t.in.touches().size() == 1);
    t.in.on_touch_end(3);
    t.frame();

    t.in.on_touch_begin(4, {270, 130});
    t.frame();
    CHECK(t.in.action_down("jump"));
    t.w.set_active(jump, false);  // a held control that goes away lets go of its button
    t.frame();
    CHECK_FALSE(t.in.action_down("jump"));
    t.in.on_touch_end(4);  // its finger was the button's: it never becomes a touch
    CHECK(t.in.touches().empty());

    t.in.set_actions(ui_with_default_actions(Json::parse(R"({"right_jump": ["GamepadRightStickUp"]})")));
    t.w.get<TouchStick>(stick)->stick = TouchStickSide::Right;
    t.frame();
    t.in.on_touch_begin(5, {50, 80});  // the top edge of the right stick
    CHECK(t.in.action_value("right_jump") == doctest::Approx(1.0f));
    t.in.release_all();  // focus lost: the stick lets go too
    CHECK(t.in.action_value("right_jump") == 0.0f);

    t.in.on_key(Key::A, true);  // the player switched to the keyboard: touch-only controls hide
    t.frame();
    CHECK_FALSE(t.w.get<TouchStick>(stick)->shown);
    CHECK(t.ui.state(t.w, t.design)["widgets"][0]["visible"] == false);
    t.w.get<TouchStick>(stick)->touchOnly = false;  // forced: shown with any device
    t.frame();
    CHECK(t.w.get<TouchStick>(stick)->shown);
}
