#include <doctest.h>

#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/core/i18n.h"
#include "fa/scene/localize.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/ui_rect.h"
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

TEST_CASE("ui slider: set_slider is a drag to a value: clamped, snapped, focused, one ui.change") {
    Ui t;
    Entity e = t.add<Slider>("s", {0, 0}, {320, 40});
    Slider& s = *t.w.get<Slider>(e);
    s.value = 0.5f;
    t.frame();
    t.events();
    CHECK(t.ui.set_slider(t.w, e, 0.73f) == doctest::Approx(0.7f));  // snapped to step 0.1
    CHECK(t.events() == V{"ui.focus:s", "ui.change:s=0.7"});
    CHECK(t.ui.focused() == e);
    CHECK(t.ui.set_slider(t.w, e, 0.7f) == doctest::Approx(0.7f));   // already there: no event
    CHECK(t.events().empty());
    CHECK(t.ui.set_slider(t.w, e, 5.0f) == doctest::Approx(1.0f));   // clamped to max
    CHECK(t.events() == V{"ui.change:s=1.0"});
    s.value = 0.2f;                                                   // a script's own write sends nothing
    t.frame();
    CHECK(t.events().empty());
    s.min = 0; s.max = 10; s.step = 3;
    CHECK(t.ui.set_slider(t.w, e, 9.9f) == doctest::Approx(10.0f));   // the end of the range even off the grid
}

TEST_CASE("ui slider: format writes the value as a pattern: {v}, {v:N}, {percent}, braces; formatKey translates it") {
    Slider s;
    CHECK(ui_slider_value_text(s, 0.6f) == "60%");                    // default for 0..1
    s.min = 0.4f; s.max = 2.5f;
    CHECK(ui_slider_value_text(s, 1.0f) == "1");
    CHECK(ui_slider_value_text(s, 1.25f) == "1.25");
    s.format = "{v}x";
    CHECK(ui_slider_value_text(s, 1.2f) == "1.2x");
    s.format = "{v:1}x ({percent}%)";
    CHECK(ui_slider_value_text(s, 1.0f) == "1.0x (100%)");
    s.min = 0.3f; s.max = 1.0f;
    s.format = "{percent}%";
    CHECK(ui_slider_value_text(s, 0.3f) == "30%");                    // value x 100, not the place in the range
    s.format = "{{v}} = {v:3} {oops} {v:9}";
    CHECK(ui_slider_value_text(s, 0.5f) == "{v} = 0.500 {oops} {v:9}");

    World w;
    I18n i18n;
    i18n.configure("en", {"en", "fr"});
    for (auto [lang, text] : {std::pair{"en", "{percent}%"}, std::pair{"fr", "{percent} %"}}) {
        StringTable tb;
        tb.language = lang;
        tb.entries["slider.pct"].text = text;
        REQUIRE(i18n.add_table(std::move(tb)).ok());
    }
    Entity e = w.create("vol", "vol");
    Slider& vs = w.add<Slider>(e);
    vs.formatKey = "slider.pct";
    localize_entity(w, e, i18n);
    CHECK(vs.format == "{percent}%");                                 // the placeholders survive the translation
    i18n.set_language("fr");
    localize_entity(w, e, i18n);
    CHECK(vs.format == "{percent} %");
    CHECK(ui_slider_value_text(vs, 0.25f) == "25 %");
}

TEST_CASE("ui scroll list shrink: inside a fit column the list is as tall as its content up to the room left") {
    Ui t;
    t.design = {1280, 720};
    Entity col = t.add<Panel>("col", {640, 360}, {10, 10});
    Panel& p = *t.w.get<Panel>(col);
    p.layout = UiLayout::Column;
    p.fit = true;
    p.pivot = {0.5f, 0.5f};
    p.spacing = 12;
    p.padding = {16, 16, 16, 16};
    Entity list = t.add<ScrollList>("list", {0, 0}, {400, 100}, col);
    ScrollList& l = *t.w.get<ScrollList>(list);
    l.shrink = true;
    l.spacing = 4;
    l.padding = {8, 8, 8, 8};
    Entity back = t.button("back", {0, 0}, {240, 56}, col);
    for (int i = 0; i < 3; ++i) t.button(("item" + std::to_string(i)).c_str(), {0, 0}, {300, 40}, list);
    t.ui.layout(t.w, t.design, {});
    CHECK(l.size.y == doctest::Approx(8 + 3 * 40 + 2 * 4 + 8));       // content: padding + items + gaps
    CHECK(p.size.y == doctest::Approx(16 + l.size.y + 12 + 56 + 16)); // the panel is short too
    CHECK(t.rect(col).h < 720.0f / 2);
    for (int i = 3; i < 40; ++i) t.button(("item" + std::to_string(i)).c_str(), {0, 0}, {300, 40}, list);
    t.ui.layout(t.w, t.design, {});
    CHECK(l.size.y == doctest::Approx(720 - 32 - 12 - 56));           // stops at the room left
    CHECK(t.rect(col).y + t.rect(col).h <= 720.5f);
    CHECK(t.rect(back).y + t.rect(back).h <= t.rect(col).y + t.rect(col).h);
    // Two lists: the short one takes what it needs, the long one the rest. fill wins over shrink.
    Entity second = t.add<ScrollList>("second", {0, 0}, {400, 100}, col);
    ScrollList& l2 = *t.w.get<ScrollList>(second);
    l2.shrink = true;
    t.button("only", {0, 0}, {300, 40}, second);
    t.button("other", {0, 0}, {300, 40}, second);
    t.ui.layout(t.w, t.design, {});
    CHECK(l2.size.y == doctest::Approx(8 + 40 + 8 + 40 + 8));
    CHECK(l.size.y == doctest::Approx(720 - 32 - 24 - 56 - l2.size.y));
    l2.fill = true;
    t.ui.layout(t.w, t.design, {});
    CHECK(l.size.y + l2.size.y == doctest::Approx(720 - 32 - 24 - 56).epsilon(0.01));
    CHECK(l.size.y == doctest::Approx(l2.size.y).epsilon(0.01));      // both need more than half: equal share
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

TEST_CASE("ui navigation: widgets in the beam win; the nearest in the half-plane is the fallback") {
    Ui t;
    // A row of tabs above a wide button that overlaps the first tab: its centre is nearer to t1 than t2 is, so the
    // half-plane search alone sends Right from t1 down to it (LK/FB-0033). t2 is in t1's beam, the button is not.
    Entity t1 = t.button("t1", {0, 0}, {60, 20}), t2 = t.button("t2", {120, 0}, {60, 20}), t3 = t.button("t3", {240, 0}, {60, 20});
    Entity wide = t.button("wide", {0, 35}, {100, 20});
    t.ui.set_focus(t.w, t1);
    t.tap_key(Key::Right);
    CHECK(t.ui.focused() == t2);
    t.tap_key(Key::Right);
    CHECK(t.ui.focused() == t3);
    // nothing below t3 is in its beam: the half-plane fallback still reaches the button
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == wide);
    // in the beam both ways between t1 and the button
    t.tap_key(Key::Up);
    CHECK(t.ui.focused() == t1);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == wide);
    // a lone widget far to the lower right is outside every beam but still reached
    Ui u;
    Entity a = u.button("a", {0, 0}), far = u.button("far", {100, 150});
    u.ui.set_focus(u.w, a);
    u.tap_key(Key::Right);
    CHECK(u.ui.focused() == far);
    // An options panel: a narrow tab above a wide, offset slider row and a Back button further down. Back is closer to
    // the tab's direction (within 45 degrees) and scores lower in the half-plane, but Down goes to the row under the tab.
    Ui m;
    Entity tab = m.button("tab", {0, 0}, {60, 20}), row = m.button("row", {40, 30}, {260, 20});
    Entity back = m.button("back", {80, 120}, {60, 20});
    m.ui.set_focus(m.w, tab);
    m.tap_key(Key::Down);
    CHECK(m.ui.focused() == row);
    m.tap_key(Key::Down);
    CHECK(m.ui.focused() == back);
    m.tap_key(Key::Up);
    CHECK(m.ui.focused() == row);
    m.tap_key(Key::Up);
    CHECK(m.ui.focused() == tab);
}

TEST_CASE("ui focus: a greyed-out autoFocus button hands the focus to the first interactable widget") {
    Ui t;
    Entity buy = t.button("buy", {0, 0}), other = t.button("other", {0, 40});
    t.button("back", {0, 80});
    t.w.get<Button>(buy)->autoFocus = true;
    t.w.get<Button>(buy)->interactable = false;
    t.frame();
    CHECK(t.ui.focused() == other);
    // an interactable autoFocus widget still wins over the first interactable one
    Ui u;
    Entity x = u.button("x", {0, 0}), z = u.button("z", {0, 80});
    u.button("y", {0, 40});
    u.w.get<Button>(x)->interactable = false;
    u.w.get<Button>(x)->autoFocus = true;
    u.w.get<Button>(z)->autoFocus = true;
    u.frame();
    CHECK(u.ui.focused() == z);
    // no autoFocus widget at all: nothing takes the focus (HUD buttons stay out of gamepad play)
    Ui h;
    h.button("hud", {0, 0});
    h.frame();
    CHECK(h.ui.focused() == kNullEntity);
}

TEST_CASE("ui.state lists screen-space Text, and ui_screen_rect finds it with the safe area applied") {
    Ui t;
    t.button("play", {10, 10});
    Entity hud = t.w.create("score", "score");
    t.w.get<Transform>(hud)->position = {20, 30, 0};
    Text& tx = t.w.add<Text>(hud);
    tx.text = "Score: 0";
    tx.space = RenderSpace::Screen;
    Entity world = t.w.create("label", "label");
    t.w.add<Text>(world);  // world space: not listed
    t.frame();
    Json st = t.ui.state(t.w, t.design);
    REQUIRE(st["widgets"].size() == 2);
    CHECK(st["widgets"][1]["kind"] == "Text");
    CHECK(st["widgets"][1]["id"] == "score");
    CHECK(st["widgets"][1]["text"] == "Score: 0");
    CHECK(st["widgets"][1]["rect"][0] == 20);
    CHECK(st["widgets"][1]["rect"][1] == 30);
    CHECK(ui_screen_rect(t.w, hud, t.design)->x == doctest::Approx(20));
    CHECK_FALSE(ui_screen_rect(t.w, world, t.design).has_value());
    tx.safeArea = true;
    t.w.set_safe_insets({40, 0, 0, 0});
    CHECK(ui_screen_rect(t.w, hud, t.design)->x == doctest::Approx(60));  // the notch pushes it in
}

namespace {

// Text sizes like the renderer's, at the player's text size: the approximation scaled for screen-space text.
VisualMeasure measure_at(float textScale) {
    VisualMeasure m;
    m.textScale = textScale;
    m.textSize = [textScale](const Text& t) { return approx_text_size(t, textScale); };
    return m;
}

}  // namespace

TEST_CASE("ui autoSize: a button is at least its design size and grows to its label at textScale 1 and 2") {
    Ui t;
    t.design = {1280, 720};
    Entity b = t.button("b", {10, 10}, {240, 56});
    Button& btn = *t.w.get<Button>(b);
    btn.autoSize = true;
    btn.text = "Play";
    for (float scale : {1.0f, 2.0f}) {
        t.ui.layout(t.w, t.design, measure_at(scale));
        CHECK(btn.size.x == doctest::Approx(240));  // "Play" at 24 px: 58 px (116 at 200 %) + 32 fits
        CHECK(btn.size.y == doctest::Approx(scale == 1.0f ? 56 : 74));  // 28.8 x 2 + 16 = 73.6 > 56 at 200 %
    }
    btn.text = "Volver al menu principal";  // a Spanish label: 24 characters
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(btn.size.x > 240);
    CHECK(btn.size.x == doctest::Approx(std::ceil(24 * 0.6f * 24 + 32)));
    t.ui.layout(t.w, t.design, measure_at(2.0f));
    CHECK(btn.size.x == doctest::Approx(std::ceil(24 * 0.6f * 48 + 32)));
    // a shorter label (another language) gives the design size back
    btn.text = "Jugar";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(btn.size.x == doctest::Approx(240));
    // a size written by a script is the new design size
    btn.text = "Volver al menu principal";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    btn.size = {500, 56};
    btn.text = "Ok";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(btn.size.x == doctest::Approx(500));
    // without autoSize nothing changes
    btn.autoSize = false;
    btn.text = "Volver al menu principal";
    t.ui.layout(t.w, t.design, measure_at(2.0f));
    CHECK(btn.size.x == doctest::Approx(500));
}

TEST_CASE("ui autoSize: maxWidth wraps a button label, so it grows taller instead of wider") {
    Ui t;
    Entity b = t.button("b", {10, 10}, {240, 56});
    Button& btn = *t.w.get<Button>(b);
    btn.autoSize = true;
    btn.maxWidth = 300;
    btn.text = "A long label that cannot fit one line of the button at all";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(btn.size.x <= 332);  // wrap width + 2 x 16
    CHECK(btn.size.x > 240);
    CHECK(btn.size.y > 56);
}

TEST_CASE("ui autoSize: toggles and sliders grow to their label at textScale 1 and 2") {
    Ui t;
    t.design = {1280, 720};
    Entity tg = t.add<Toggle>("tg", {10, 10}, {240, 40});
    Entity sl = t.add<Slider>("sl", {10, 60}, {320, 40});
    Toggle& toggle = *t.w.get<Toggle>(tg);
    Slider& slider = *t.w.get<Slider>(sl);
    toggle.autoSize = slider.autoSize = true;
    toggle.label = "Mute";
    slider.label = "Music";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(toggle.size.x == doctest::Approx(240));
    CHECK(slider.size.x == doctest::Approx(320));
    toggle.label = "Reducir los movimientos de la camara";
    slider.label = "Volumen de la musica de fondo";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    const Vec2 toggle1 = toggle.size, slider1 = slider.size;
    CHECK(toggle1.x > 240);
    CHECK(slider1.x > 320);
    t.ui.layout(t.w, t.design, measure_at(2.0f));
    CHECK(toggle.size.x > toggle1.x);
    CHECK(slider.size.x > slider1.x);
    // the label fits inside the slider's label zone (35% of the inner width)
    const Rect r = t.rect(sl);
    CHECK(0.35f * (r.w - 16) >= 29 * 0.6f * 48);
    CHECK(toggle.size.y >= 2 * 28.8f + 16 - 1);
}

TEST_CASE("ui scroll list fill: a column with a fill list stays inside the screen at textScale 1 and 2") {
    Ui t;
    t.design = {1280, 720};
    Entity col = t.add<Panel>("col", {640, 360}, {10, 10});
    Panel& p = *t.w.get<Panel>(col);
    p.layout = UiLayout::Column;
    p.fit = true;
    p.pivot = {0.5f, 0.5f};
    p.spacing = 12;
    p.padding = {16, 16, 16, 16};
    Entity title = t.w.create("title", "title");
    t.w.set_parent(title, col);
    Text& tx = t.w.add<Text>(title);
    tx.text = "Achievements";
    tx.fontSize = 48;
    tx.space = RenderSpace::Screen;
    Entity list = t.add<ScrollList>("list", {0, 0}, {400, 100}, col);
    t.w.get<ScrollList>(list)->fill = true;
    for (int i = 0; i < 40; ++i) t.button(("item" + std::to_string(i)).c_str(), {0, 0}, {300, 40}, list);
    Entity back = t.button("back", {0, 0}, {240, 56}, col);
    for (float scale : {1.0f, 2.0f}) {
        t.ui.layout(t.w, t.design, measure_at(scale));
        const Rect pr = t.rect(col);
        INFO("scale " << scale << " panel " << pr.y << " + " << pr.h);
        CHECK(pr.y >= -0.5f);
        CHECK(pr.y + pr.h <= 720.5f);
        const float other = 48 * 1.2f * scale + 56;
        CHECK(t.w.get<ScrollList>(list)->size.y == doctest::Approx(std::floor(720 - 32 - 24 - other)));
        CHECK(t.rect(back).y + t.rect(back).h <= pr.y + pr.h);
    }
}

TEST_CASE("ui scroll list fill: a column without fit gives the list the rest of its own height; other parents are ignored") {
    Ui t;
    Entity col = t.add<Panel>("col", {0, 0}, {200, 150});
    Panel& p = *t.w.get<Panel>(col);
    p.layout = UiLayout::Column;
    p.spacing = 10;
    p.padding = {10, 10, 10, 10};
    t.button("top", {0, 0}, {100, 30}, col);
    Entity list = t.add<ScrollList>("list", {0, 0}, {100, 20}, col);
    t.w.get<ScrollList>(list)->fill = true;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.w.get<ScrollList>(list)->size.y == doctest::Approx(150 - 20 - 10 - 30));
    Entity loose = t.add<ScrollList>("loose", {0, 0}, {100, 20});
    t.w.get<ScrollList>(loose)->fill = true;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.w.get<ScrollList>(loose)->size.y == doctest::Approx(20));
}

TEST_CASE("ui layout: a fit panel larger than the screen logs one warning naming it") {
    Ui t;
    clear_recent_logs();
    Entity col = t.add<Panel>("huge_menu", {0, 0}, {10, 10});
    Panel& p = *t.w.get<Panel>(col);
    p.layout = UiLayout::Column;
    p.fit = true;
    for (int i = 0; i < 12; ++i) t.button(("b" + std::to_string(i)).c_str(), {0, 0}, {100, 30}, col);  // 12 x 30 > 180
    const auto warnings = [] {
        int n = 0;
        for (const LogEntry& e : recent_logs(200, LogLevel::Warn))
            if (e.message.find("huge_menu") != std::string::npos) ++n;
        return n;
    };
    t.ui.layout(t.w, t.design, {}, false);  // ui.layout() from a script: it is still changing the menu
    CHECK(warnings() == 0);
    for (int i = 0; i < 3; ++i) t.ui.layout(t.w, t.design, {});
    CHECK(warnings() == 1);
}

// ------------------------------------------------------------------------------- right-to-left layouts --
TEST_CASE("ui layout: direction auto lays a row out right to left in a right-to-left language only") {
    Ui t;
    Entity p = t.add<Panel>("p", {0, 0}, {300, 100});
    Panel& panel = *t.w.get<Panel>(p);
    panel.layout = UiLayout::Row;
    panel.spacing = 5;
    panel.padding = {10, 0, 20, 0};  // inner box x 10 .. 280
    panel.align = UiAlign::Start;
    Entity a = t.button("a", {0, 0}, {50, 20}, p), b = t.button("b", {0, 0}, {30, 40}, p);

    for (UiDirection d : {UiDirection::Ltr, UiDirection::Auto}) {  // English: both read left to right
        panel.direction = d;
        t.w.set_rtl(false);
        t.ui.layout(t.w, t.design, {});
        CHECK(t.rect(a).x == doctest::Approx(10));
        CHECK(t.rect(b).x == doctest::Approx(65));
    }
    panel.direction = UiDirection::Auto;
    t.w.set_rtl(true);  // Arabic: the first child is at the right edge of the padded box, start = right
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(a).x == doctest::Approx(230));  // 280 - 50
    CHECK(t.rect(b).x == doctest::Approx(195));  // 230 - 5 - 30
    panel.direction = UiDirection::Ltr;  // an explicit ltr ignores the language
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(a).x == doctest::Approx(10));
    panel.direction = UiDirection::Rtl;  // an explicit rtl ignores it too
    t.w.set_rtl(false);
    panel.justify = UiAlign::End;  // end = the left edge of an rtl panel
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(b).x == doctest::Approx(10));
    CHECK(t.rect(a).x == doctest::Approx(45));  // 10 + 30 + 5
}

TEST_CASE("ui layout: a wrapped Text sits at the start side of a column, left in English and right in Arabic") {
    Ui t;
    Entity p = t.add<Panel>("p", {0, 0}, {300, 200});
    Panel& panel = *t.w.get<Panel>(p);
    panel.layout = UiLayout::Column;
    panel.padding = {10, 10, 10, 10};
    panel.align = UiAlign::Start;
    panel.direction = UiDirection::Auto;
    Entity label = t.w.create("note", "note");
    t.w.set_parent(label, p);
    Text& txt = t.w.add<Text>(label);
    txt.text = "a long note that wraps inside its box";
    txt.fontSize = 10;
    txt.space = RenderSpace::Screen;
    txt.pivot = {0, 1};
    txt.maxWidth = 120;
    txt.align = Align::Start;
    t.ui.layout(t.w, t.design, {});
    const Rect en = *ui_screen_rect(t.w, label, t.design);
    CHECK(en.x == doctest::Approx(10));
    t.w.set_rtl(true);
    t.ui.layout(t.w, t.design, {});
    const Rect ar = *ui_screen_rect(t.w, label, t.design);
    CHECK(ar.x + ar.w == doctest::Approx(290));  // the box ends at the right edge of the padded box
    CHECK(ar.w == doctest::Approx(en.w));
}

TEST_CASE("ui Panel.uniformSize: autoSize widgets inside share the largest size and shrink back with it") {
    Ui t;
    t.design = {1280, 720};
    Entity root = t.add<Panel>("root", {0, 0}, {800, 400});
    Entity rowA = t.add<Panel>("rowA", {0, 0}, {400, 60}, root);
    Entity rowB = t.add<Panel>("rowB", {0, 100}, {400, 60}, root);
    t.w.get<Panel>(rowA)->layout = t.w.get<Panel>(rowB)->layout = UiLayout::Row;
    Entity a = t.button("a", {0, 0}, {40, 30}, rowA);
    Entity b = t.button("b", {0, 0}, {40, 30}, rowA);
    Entity c = t.button("c", {0, 0}, {40, 30}, rowB);
    Entity plain = t.button("plain", {0, 0}, {50, 20}, rowB);
    for (Entity e : {a, b, c}) t.w.get<Button>(e)->autoSize = true;
    t.w.get<Button>(a)->text = "Hi";
    t.w.get<Button>(b)->text = "A much longer label";
    t.w.get<Button>(c)->text = "Mid label";
    t.w.get<Button>(plain)->text = "A much longer label, not autoSize";
    const auto sz = [&](Entity e) { return t.w.get<Button>(e)->size; };

    t.ui.layout(t.w, t.design, measure_at(1.0f));  // uniformSize false: each button has its own size
    CHECK(sz(a).x < sz(b).x);
    CHECK(sz(c).x < sz(b).x);

    t.w.get<Panel>(root)->uniformSize = true;
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    const Vec2 big = sz(b);
    CHECK(big.x > 40);
    for (Entity e : {a, c}) CHECK(sz(e).x == doctest::Approx(big.x));
    for (Entity e : {a, c}) CHECK(sz(e).y == doctest::Approx(big.y));
    CHECK(sz(plain).x == doctest::Approx(50));
    t.ui.layout(t.w, t.design, measure_at(1.0f));  // stable on the next frame
    CHECK(sz(a).x == doctest::Approx(big.x));

    t.w.get<Button>(b)->text = "Ok";  // the longest is now "Mid label": all shrink to it
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(sz(b).x < big.x);
    CHECK(sz(a).x == doctest::Approx(sz(c).x));
    CHECK(sz(b).x == doctest::Approx(sz(c).x));
    CHECK(sz(plain).x == doctest::Approx(50));
}

// ----------------------------------------------------------------------------------------------- fallbackLayout --
namespace {

Entity fit_panel(Ui& t, const char* id, UiLayout layout, UiLayout fallback, Entity parent = kNullEntity) {
    Entity e = t.add<Panel>(id, {0, 0}, {10, 10}, parent);
    Panel& p = *t.w.get<Panel>(e);
    p.layout = layout;
    p.fallbackLayout = fallback;
    p.fit = true;
    p.padding = {0, 0, 0, 0};
    p.spacing = 10;
    p.align = UiAlign::Start;
    return e;
}

Entity auto_button(Ui& t, const char* id, Vec2 design, Entity parent) {
    Entity e = t.button(id, {0, 0}, design, parent);
    t.w.get<Button>(e)->autoSize = true;
    t.w.get<Button>(e)->text = "Hola";  // 4 characters at 24 px
    return e;
}

}  // namespace

TEST_CASE("ui fallbackLayout: a fit column taller than the screen becomes a row, and a column again when the text shrinks") {
    Ui t;  // 320 x 180
    Entity col = fit_panel(t, "col", UiLayout::Column, UiLayout::Row);
    Entity a = auto_button(t, "a", {100, 50}, col), b = auto_button(t, "b", {100, 50}, col);
    const Panel& p = *t.w.get<Panel>(col);
    t.ui.layout(t.w, t.design, measure_at(1.0f));  // 50 + 10 + 50
    CHECK_FALSE(p.usingFallback);
    CHECK(t.rect(b).y == doctest::Approx(60));
    CHECK(t.rect(b).x == doctest::Approx(t.rect(a).x));
    t.w.get<Button>(a)->text = "Hola\nHola";
    t.w.get<Button>(b)->text = "Hola\nHola";
    t.ui.layout(t.w, t.design, measure_at(2.0f));  // each button is 131 tall: a column of two is 272
    CHECK(p.usingFallback);
    CHECK(t.rect(b).y == doctest::Approx(t.rect(a).y));
    CHECK(t.rect(b).x > t.rect(a).x);
    CHECK(p.size.y < 180);
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK_FALSE(p.usingFallback);
    CHECK(t.rect(b).y > t.rect(a).y);
}

TEST_CASE("ui fallbackLayout: level-select shape, rows stack first and then the worlds stand side by side") {
    Ui t;
    t.design = {400, 300};
    Entity root = fit_panel(t, "root", UiLayout::Column, UiLayout::None);
    Entity worlds = fit_panel(t, "worlds", UiLayout::Column, UiLayout::Row, root);
    Entity rows[2], btns[2][3];
    for (int w = 0; w < 2; ++w) {
        Entity world = fit_panel(t, w ? "world2" : "world1", UiLayout::Column, UiLayout::None, worlds);
        Entity title = t.button(w ? "title2" : "title1", {0, 0}, {150, 30}, world);
        (void)title;
        rows[w] = fit_panel(t, w ? "row2" : "row1", UiLayout::Row, UiLayout::Column, world);
        for (int i = 0; i < 3; ++i) btns[w][i] = auto_button(t, ("b" + std::to_string(w) + std::to_string(i)).c_str(), {100, 40}, rows[w]);
    }
    t.ui.layout(t.w, t.design, measure_at(1.0f));  // rows 320 x 45: everything fits
    CHECK_FALSE(t.w.get<Panel>(rows[0])->usingFallback);
    CHECK_FALSE(t.w.get<Panel>(worlds)->usingFallback);
    CHECK(t.rect(btns[0][1]).y == doctest::Approx(t.rect(btns[0][0]).y));
    CHECK(t.rect(btns[1][0]).y > t.rect(btns[0][0]).y);
    t.ui.layout(t.w, t.design, measure_at(2.0f));  // buttons 148 x 74: a row is 464 wide, a stacked column is 282 tall
    for (int w = 0; w < 2; ++w) {
        CHECK(t.w.get<Panel>(rows[w])->usingFallback);
        CHECK(t.rect(btns[w][1]).y > t.rect(btns[w][0]).y);
        CHECK(t.rect(btns[w][1]).x == doctest::Approx(t.rect(btns[w][0]).x));
    }
    CHECK(t.w.get<Panel>(worlds)->usingFallback);  // two stacked worlds would be 574 tall
    CHECK(t.rect(btns[1][0]).y == doctest::Approx(t.rect(btns[0][0]).y));
    CHECK(t.rect(btns[1][0]).x > t.rect(btns[0][0]).x);
    CHECK_FALSE(t.w.get<Panel>(root)->usingFallback);
    t.ui.layout(t.w, t.design, measure_at(1.0f));  // and back
    CHECK_FALSE(t.w.get<Panel>(rows[0])->usingFallback);
    CHECK_FALSE(t.w.get<Panel>(worlds)->usingFallback);
}

TEST_CASE("ui layout: autoSize sizes are current right after UiSystem::layout, with no update") {
    Ui t;
    t.design = {1280, 720};
    Entity b = t.button("b", {10, 10}, {240, 56});
    Button& btn = *t.w.get<Button>(b);
    btn.autoSize = true;
    btn.text = "Ok";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(btn.size.x == doctest::Approx(240));
    btn.text = "Volver al menu principal";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(btn.size.x == doctest::Approx(std::ceil(24 * 0.6f * 24 + 32)));
    CHECK(t.rect(b).w == doctest::Approx(btn.size.x));
}

TEST_CASE("ui fallbackLayout: a fill ScrollList in a column that became a row is not resized") {
    Ui t;  // 320 x 180
    Entity col = fit_panel(t, "col", UiLayout::Column, UiLayout::Row);
    Entity a = auto_button(t, "a", {100, 50}, col);
    t.w.get<Button>(a)->text = "Hola\nHola";
    Entity list = t.add<ScrollList>("list", {0, 0}, {100, 100}, col);
    t.w.get<ScrollList>(list)->fill = true;
    t.ui.layout(t.w, t.design, measure_at(2.0f));  // the button is ~131 tall: the list gets its 64 px minimum, 205 in all
    CHECK(t.w.get<Panel>(col)->usingFallback);
    CHECK(t.rect(list).y == doctest::Approx(t.rect(a).y));
    CHECK(t.rect(list).x > t.rect(a).x);
    CHECK(t.w.get<ScrollList>(list)->size.y == doctest::Approx(64));  // left as the column pass set it, not re-filled
}

// ---- text that fits (M26.6) ------------------------------------------------------------------------------------------------

TEST_CASE("text fit: a German label in a fixed button shrinks at 200 % text, stays inside and never goes under minFontSize") {
    Ui t;
    t.design = {1280, 720};
    Entity b = t.button("b", {10, 10}, {200, 48});
    Button& btn = *t.w.get<Button>(b);
    btn.text = "Einstellungen";
    btn.minFontSize = 8;
    const Rect r = t.rect(b);
    const VisualMeasure m = measure_at(2.0f);
    // Without autoShrink the label is drawn at 24 * 2 = 48 px and does not fit: 13 characters of 28.8 px.
    auto fit = ui_label_fit(t.w, b, r, 2.0f, text_extent_of(m));
    REQUIRE(fit.has_value());
    CHECK(fit->fit.px == doctest::Approx(48));
    CHECK(fit->fit.overflow);
    CHECK(ui_text_overflowed(t.w, b, t.design, m));
    // With it the text shrinks until it is inside the button, and not further than needed.
    btn.autoShrink = true;
    fit = ui_label_fit(t.w, b, r, 2.0f, text_extent_of(m));
    REQUIRE(fit.has_value());
    CHECK_FALSE(fit->fit.overflow);
    CHECK(fit->fit.shrunk);
    CHECK(fit->fit.px < 48);
    CHECK(fit->fit.px >= 8 * 2);                       // minFontSize is scaled with the text size
    CHECK(fit->fit.size.x <= r.w - 16 + 0.5f);          // inside the button's margins
    CHECK(fit->fit.size.y <= r.h - 8 + 0.5f);
    CHECK(fit->fit.size.x > r.w - 16 - 8);              // ... and the largest quarter-pixel size that does
    CHECK_FALSE(ui_text_overflowed(t.w, b, t.design, m));
    // At 100 % the label fits at its own size: nothing shrinks.
    btn.size = {220, 48};
    fit = ui_label_fit(t.w, b, t.rect(b), 1.0f, text_extent_of(measure_at(1.0f)));
    CHECK(fit->fit.px == doctest::Approx(24));
    CHECK_FALSE(fit->fit.shrunk);
    // A label too long even at the floor is drawn AT the floor and reported as overflowed.
    btn.text = "Einstellungen und Optionen fuer Fortgeschrittene";
    fit = ui_label_fit(t.w, b, r, 2.0f, text_extent_of(m));
    CHECK(fit->fit.px == doctest::Approx(16));
    CHECK(fit->fit.overflow);
    CHECK(ui_text_overflowed(t.w, b, t.design, m));
    // ui.state lists it
    t.frame();
    Json st = t.ui.state(t.w, t.design, m);
    CHECK(st["widgets"][0]["overflowed"] == true);
}

TEST_CASE("text fit: maxTextScale caps the growth of a heading and of a label, and only the growth") {
    Text heading;
    heading.text = "Clockwork Courier";
    heading.fontSize = 40;
    heading.space = RenderSpace::Screen;
    const float plain = approx_text_size(heading, 2.0f).y;
    CHECK(plain == doctest::Approx(40 * 2 * 1.2f));
    heading.maxTextScale = 1.3f;
    CHECK(approx_text_size(heading, 2.0f).y == doctest::Approx(40 * 1.3f * 1.2f));
    CHECK(approx_text_size(heading, 3.0f).y == doctest::Approx(40 * 1.3f * 1.2f));
    CHECK(approx_text_size(heading, 1.0f).y == doctest::Approx(40 * 1.2f));      // below the cap: the player's size
    CHECK(approx_text_size(heading, 0.5f).y == doctest::Approx(40 * 0.5f * 1.2f));
    heading.space = RenderSpace::World;                                         // world space never scales
    CHECK(approx_text_size(heading, 2.0f).y == doctest::Approx(40 * 1.2f));
    CHECK(effective_text_scale(2.0f, 0.0f) == 2.0f);
    CHECK(effective_text_scale(2.0f, 1.3f) == 1.3f);
    // layout reads the cap of a widget: an autoSize button stops growing with it
    Ui t;
    t.design = {1280, 720};
    Entity b = t.button("b", {10, 10}, {100, 30});
    Button& btn = *t.w.get<Button>(b);
    btn.autoSize = true;
    btn.text = "Play now please";
    t.ui.layout(t.w, t.design, measure_at(2.0f));
    const float uncapped = btn.size.x;
    btn.maxTextScale = 1.3f;
    t.ui.layout(t.w, t.design, measure_at(2.0f));
    CHECK(btn.size.x < uncapped);
    CHECK(btn.size.x == doctest::Approx(std::ceil(15 * 0.6f * 24 * 1.3f + 32)));
}

TEST_CASE("text fit: Text autoShrink fits its maxWidth x maxHeight box") {
    Text card;
    card.text = "Deliveries completed today";
    card.fontSize = 24;
    card.space = RenderSpace::Screen;
    card.maxWidth = 200;
    card.maxHeight = 30;  // one line
    card.minFontSize = 8;
    const TextExtent extent = approx_text_extent();
    TextFit f = fit_text(text_fit_spec(card), card.text, card.font, 1.0f, extent);
    CHECK(f.overflow);  // two or three wrapped lines of 28.8 px
    card.autoShrink = true;
    f = fit_text(text_fit_spec(card), card.text, card.font, 1.0f, extent);
    CHECK_FALSE(f.overflow);
    CHECK(f.size.y <= 30.5f);
    CHECK(f.px < 24);
    CHECK(f.px >= 8);
    f = fit_text(text_fit_spec(card), card.text, card.font, 2.0f, extent);  // 200 %: smaller still, floor 16
    CHECK(f.px >= 16);
    // an unbounded text never overflows
    card.maxWidth = card.maxHeight = 0;
    CHECK_FALSE(fit_text(text_fit_spec(card), card.text, card.font, 3.0f, extent).overflow);
}

TEST_CASE("text fit: a long Toggle label wraps at maxWidth and the toggle grows taller, not wider") {
    Ui t;
    t.design = {1280, 720};
    Entity tg = t.add<Toggle>("tg", {10, 10}, {240, 40});
    Toggle& toggle = *t.w.get<Toggle>(tg);
    toggle.autoSize = true;
    toggle.label = "Reduce screen shake and flashing lights during combat";
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    const Vec2 oneLine = toggle.size;
    CHECK(oneLine.x > 600);
    toggle.maxWidth = 260;
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(toggle.size.y > oneLine.y);
    CHECK(toggle.size.x < oneLine.x);
    CHECK(toggle.size.x <= 260 + toggle.size.y + 16 + 1);
    t.ui.layout(t.w, t.design, measure_at(2.0f));  // 200 %: more lines, still no wider than the wrap width
    CHECK(toggle.size.x <= 260 + toggle.size.y + 16 + 1);
    // the label zone the renderer draws into holds the wrapped label
    const Rect r = t.rect(tg);
    const auto fit = ui_label_fit(t.w, tg, r, 2.0f, text_extent_of(measure_at(2.0f)));
    REQUIRE(fit.has_value());
    CHECK(fit->fit.size.x <= 260 + 0.5f);
    CHECK_FALSE(fit->fit.overflow);
}

TEST_CASE("text fit: Slider labelAbove gives the track the whole width and maxWidth wraps the label") {
    Ui t;
    t.design = {1280, 720};
    Entity sl = t.add<Slider>("sl", {10, 10}, {320, 40});
    Slider& slider = *t.w.get<Slider>(sl);
    slider.label = "Music volume for the whole game";
    const Rect r = t.rect(sl);
    const auto [beside, besideR] = ui_slider_track(slider, r);
    slider.labelAbove = true;
    const auto [above, aboveR] = ui_slider_track(slider, r);
    CHECK(above < beside);
    CHECK(aboveR - above > besideR - beside);
    CHECK(ui_slider_mid_y(slider, r) == doctest::Approx(r.y + r.h - kUiSliderRowHeight * 0.5f));
    slider.autoSize = true;
    slider.maxWidth = 200;
    t.ui.layout(t.w, t.design, measure_at(1.0f));
    CHECK(slider.size.y > 40 + 20);  // two label lines plus the track row
    const auto fit = ui_label_fit(t.w, sl, t.rect(sl), 1.0f, text_extent_of(measure_at(1.0f)));
    REQUIRE(fit.has_value());
    CHECK_FALSE(fit->fit.overflow);
    CHECK(fit->fit.size.x <= 200.5f);
    // a TouchButton label shrinks inside its disc
    Entity tb = t.w.create("tb", "tb");
    TouchButton& touch = t.w.add<TouchButton>(tb);
    touch.text = "Interact";
    touch.autoShrink = true;
    touch.minFontSize = 5;
    touch.maxTextScale = 1.5f;
    const Rect disc = *ui_rect(t.w, tb, t.design);
    const auto tf = ui_label_fit(t.w, tb, disc, 2.0f, text_extent_of(measure_at(2.0f)));
    REQUIRE(tf.has_value());
    CHECK_FALSE(tf->fit.overflow);
    CHECK(tf->fit.size.x <= 96 * 0.7f + 0.5f);
    CHECK(tf->fit.px <= 32 * 1.5f);
}

TEST_CASE("ui textfield: the phone's keyboard goes up with the focus and down with the blur, not for a pad") {
    Ui t;
    Entity f = t.add<TextField>("f", {0, 0}, {200, 30});
    Entity b = t.button("b", {0, 60});
    t.frame();
    CHECK_FALSE(t.in.keyboard_shown());  // nothing focused
    CHECK(t.ui.set_focus(t.w, f));
    t.frame();
    CHECK(t.in.keyboard_shown());
    CHECK(t.ui.set_focus(t.w, b));  // a Button: down
    t.frame();
    CHECK_FALSE(t.in.keyboard_shown());
    // A script that hides it while the field keeps the focus is not overruled: only changes count.
    t.ui.set_focus(t.w, f);
    t.frame();
    CHECK(t.in.keyboard_shown());
    t.in.set_keyboard_shown(false);
    t.frame(3);
    CHECK_FALSE(t.in.keyboard_shown());
    t.ui.set_focus(t.w, kNullEntity);  // blur
    t.frame();
    CHECK_FALSE(t.in.keyboard_shown());
    // The last input was a pad: the game's on-screen keyboard is for that, the phone's stays down.
    t.in.set_last_device(InputDevice::Gamepad);
    t.ui.set_focus(t.w, f);
    t.frame();
    CHECK_FALSE(t.in.keyboard_shown());
    // A finger on the field raises it.
    t.in.set_last_device(InputDevice::Touch);
    t.ui.set_focus(t.w, b);
    t.frame();
    t.ui.set_focus(t.w, f);
    t.frame();
    CHECK(t.in.keyboard_shown());
}

TEST_CASE("ui textfield: Ctrl+V pastes (no newlines or control characters, maxLength, at the end), Ctrl+C copies") {
    Ui t;
    MemoryClipboard clip;
    t.ui.set_clipboard(&clip);
    Entity e = t.add<TextField>("f", {0, 0}, {200, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    f.maxLength = 8;
    t.frame();
    t.events();
    f.text = "ab";
    clip.set("cd\r\nef\tg\x01h");
    t.in.on_key(Key::LeftControl, true);
    t.in.on_text(U'v');  // some platforms also send the letter of the chord: it is not typed
    t.in.on_key(Key::V, true);
    t.frame();
    CHECK(f.text == "abcdefgh");  // CR, LF, tab and the control character are dropped; 8 code points fit
    CHECK(t.events() == V{"ui.change:f=\"abcdefgh\""});
    t.in.on_key(Key::V, false);
    t.frame();
    t.in.on_key(Key::V, true);  // full: nothing more is taken
    t.frame();
    CHECK(f.text == "abcdefgh");
    t.in.on_key(Key::V, false);
    f.maxLength = 0;
    clip.set("\xC3\xA9");  // a code point of two bytes
    t.in.on_key(Key::V, true);
    t.frame();
    CHECK(f.text == "abcdefgh\xC3\xA9");
    t.in.on_key(Key::V, false);
    t.frame();
    t.in.on_key(Key::C, true);  // copy
    t.frame();
    CHECK(clip.get() == "abcdefgh\xC3\xA9");
    t.in.on_key(Key::C, false);
    t.in.on_key(Key::LeftControl, false);
    // Without Ctrl, V pastes nothing.
    clip.set("zzz");
    t.in.on_key(Key::V, true);
    t.frame();
    CHECK(f.text == "abcdefgh\xC3\xA9");
    t.in.on_key(Key::V, false);
}

TEST_CASE("ui textfield: the web pastes on the paste event, not on the V key") {
    Ui t;
    MemoryClipboard clip;
    t.ui.set_clipboard(&clip);
    t.in.set_paste_from_events(true);
    Entity e = t.add<TextField>("f", {0, 0}, {200, 30});
    TextField& f = *t.w.get<TextField>(e);
    f.autoFocus = true;
    t.frame();
    clip.set("hi");
    t.in.on_key(Key::LeftSuper, true);
    t.in.on_key(Key::V, true);
    t.frame();
    CHECK(f.text.empty());
    t.in.on_paste();
    t.frame();
    CHECK(f.text == "hi");
}

// ------------------------------------------------------------------------------- hit test, pointer, wheel, focus --
TEST_CASE("ui widget_at: the topmost widget, a Panel, nothing over empty space or a row a ScrollList clips") {
    Ui t;
    Entity panel = t.add<Panel>("panel", {10, 10}, {200, 100});
    Entity under = t.button("under", {20, 20}, {60, 30}, panel);
    Entity over = t.button("over", {50, 20}, {60, 30}, panel);  // made later: wins where they overlap
    t.w.get<Button>(over)->layer = t.w.get<Button>(under)->layer;
    auto at = [&](float x, float y) { return ui_widget_at(t.w, t.design, {x, y}); };
    CHECK(at(30, 30) == under);
    CHECK(at(60, 30) == over);
    CHECK(at(100, 30) == over);
    CHECK(at(150, 90) == panel);  // the Panel itself
    CHECK(at(300, 170) == kNullEntity);
    t.w.get<Button>(under)->layer = 500;  // a higher layer wins over a later entity
    CHECK(at(60, 30) == under);
    t.w.get<Button>(under)->interactable = false;  // still a widget
    CHECK(at(30, 30) == under);
    t.w.set_active(under, false);
    CHECK(at(30, 30) == panel);
    t.w.get<Panel>(panel)->color.a = 0.0f;  // a Panel that draws nothing is not hit
    CHECK(at(150, 90) == kNullEntity);

    Entity list = t.add<ScrollList>("list", {0, 120}, {100, 50});
    ScrollList& sl = *t.w.get<ScrollList>(list);
    sl.padding = {0, 0, 0, 0};
    sl.spacing = 0;
    std::vector<Entity> rows;
    for (int i = 0; i < 4; ++i) rows.push_back(t.button(("row" + std::to_string(i)).c_str(), {0, 0}, {100, 20}, list));
    t.ui.layout(t.w, t.design, {});
    CHECK(at(50, 130) == rows[0]);
    CHECK(at(50, 175) == kNullEntity);  // row 3 is at y 180 and below the list: clipped, and the list ends at 170
    CHECK(at(50, 169) == rows[2]);
    sl.scroll = 30;
    t.ui.layout(t.w, t.design, {});
    CHECK(at(50, 125) == rows[1]);  // the part of row 0 above the list is clipped; row 1 spans 110..130 and shows from 120
    CHECK(at(50, 100) == kNullEntity);
}

TEST_CASE("ui pointer: set_pointer hovers, presses and clicks like the mouse, until it is cleared") {
    Ui t;
    Entity a = t.button("a", {10, 10}), b = t.button("b", {150, 10});
    t.in.on_mouse_move({20, 20});  // the real mouse is over a, but a virtual pointer takes over
    t.ui.set_pointer({160, 20}, false);
    t.frame();
    CHECK(t.ui.hovered() == b);
    CHECK(t.ui.pointer_over_ui());
    CHECK(t.events().empty());
    t.ui.set_pointer({160, 20}, true);
    t.frame();
    CHECK(t.ui.focused() == b);
    CHECK(t.w.get<Button>(b)->pressed);
    t.ui.set_pointer({160, 20}, false);
    t.frame();
    CHECK(t.events() == V{"ui.focus:b", "ui.click:b"});
    // released away from the button: no click
    t.ui.set_pointer({160, 20}, true);
    t.frame();
    t.ui.set_pointer({100, 100}, false);
    t.frame();
    CHECK(t.events() == V{});
    CHECK(!t.ui.pointer_over_ui());
    t.ui.clear_pointer();
    t.frame();
    CHECK(t.ui.hovered() == a);  // the mouse again
    CHECK(t.ui.pointer_over_ui());
    (void)a;
}

TEST_CASE("ui wheel: a list with more to show consumes it; a short list, a bare spot and the end of the range differ") {
    Ui t;
    Entity list = t.add<ScrollList>("list", {0, 0}, {100, 50});
    ScrollList& sl = *t.w.get<ScrollList>(list);
    sl.padding = {0, 0, 0, 0};
    sl.spacing = 0;
    for (int i = 0; i < 4; ++i) t.button(("i" + std::to_string(i)).c_str(), {0, 0}, {100, 20}, list);
    Entity shortList = t.add<ScrollList>("short", {150, 0}, {100, 100});
    t.w.get<ScrollList>(shortList)->padding = {0, 0, 0, 0};
    t.button("only", {0, 0}, {100, 20}, shortList);
    t.ui.layout(t.w, t.design, {});
    t.in.on_mouse_move({50, 25});
    t.in.on_mouse_wheel(-1);
    t.frame();
    CHECK(t.ui.wheel_consumed());
    CHECK(sl.scroll > 0);
    // the wheel is spent for the rest of this frame
    t.in.on_mouse_wheel(-1);
    t.in.on_mouse_move({50, 25});
    float seen = -1;
    t.ui.update(t.w, t.in, t.design, t.dt, {});
    seen = t.in.mouse_wheel();
    CHECK(seen == 0.0f);
    t.in.begin_frame();
    // the end of the range: still consumed (the page must not zoom there)
    sl.scroll = 30;
    t.ui.layout(t.w, t.design, {});
    t.in.on_mouse_wheel(-1);
    t.frame();
    CHECK(t.ui.wheel_consumed());
    // a list that fits its content, empty space: the wheel passes through
    t.in.on_mouse_move({200, 20});
    t.in.on_mouse_wheel(-1);
    t.ui.update(t.w, t.in, t.design, t.dt, {});
    CHECK(!t.ui.wheel_consumed());
    CHECK(t.in.mouse_wheel() == -1.0f);
    t.in.begin_frame();
    t.in.on_mouse_move({300, 170});
    t.in.on_mouse_wheel(-1);
    t.ui.update(t.w, t.in, t.design, t.dt, {});
    CHECK(!t.ui.wheel_consumed());
    CHECK(t.in.mouse_wheel() == -1.0f);
    t.in.begin_frame();
    t.frame();
    CHECK(!t.ui.wheel_consumed());
}

TEST_CASE("ui focus: set_focus(null) holds over frames until a navigation press, which only wakes autoFocus") {
    Ui t;
    Entity a = t.button("a", {10, 10}), b = t.button("b", {10, 60});
    t.w.get<Button>(a)->autoFocus = true;
    t.frame();
    CHECK(t.ui.focused() == a);
    CHECK(t.ui.set_focus(t.w, kNullEntity));
    t.frame(5);
    CHECK(t.ui.focused() == kNullEntity);
    CHECK(!t.w.get<Button>(a)->focused);
    t.tap_key(Key::Down);  // wakes autoFocus: the press is spent on that
    CHECK(t.ui.focused() == a);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == b);
    // a pointer press focuses and ends the hold too
    t.ui.set_focus(t.w, kNullEntity);
    t.frame(2);
    CHECK(t.ui.focused() == kNullEntity);
    t.click({20, 20});
    CHECK(t.ui.focused() == a);
}
