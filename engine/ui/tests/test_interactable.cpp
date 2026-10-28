// Interactable: any entity composition as a widget (focus, hover, press, click, navigation, values), in world and screen space.
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

// The default (cameraless) view: world (x, y) is the screen point (160 + x, 90 - y) in the 320 x 180 design.
Vec2 at(float x, float y) { return {160 + x, 90 - y}; }

// A rectangle of `size` centred on `pos` in world space with an Interactable.
Entity card(Ui& t, const char* id, Vec2 pos, Vec2 size, Entity parent = kNullEntity, InteractableKind kind = InteractableKind::Button) {
    Entity e = t.w.create(id, id);
    if (parent) t.w.set_parent(e, parent);
    t.w.get<Transform>(e)->position = {pos.x, pos.y, 0};
    t.w.add<Shape2D>(e).size = size;
    t.w.add<Interactable>(e).kind = kind;
    return e;
}

Entity child_shape(Ui& t, const char* id, Entity parent, Vec2 pos, Vec2 size) {
    Entity e = t.w.create(id, id);
    t.w.set_parent(e, parent);
    t.w.get<Transform>(e)->position = {pos.x, pos.y, 0};
    t.w.add<Shape2D>(e).size = size;
    return e;
}

Json widget(Ui& t, const std::string& id) {
    const Json st = t.ui.state(t.w, t.design);
    for (const Json& j : st["widgets"])
        if (j["id"] == id) return j;
    return Json();
}

void move_to(Ui& t, Vec2 p) {
    t.in.on_mouse_move(p);
    t.frame();
}

}  // namespace

TEST_CASE("Interactable: the area is the bounds of the entity and its children, through parents that move, scale and turn") {
    Ui t;
    Entity page = t.w.create("page", "page");
    t.w.get<Transform>(page)->position = {50, 0, 0};
    t.w.get<Transform>(page)->scale = {2, 2, 1};
    Entity item = card(t, "item", {10, 0}, {20, 10}, page);
    t.frame();
    // local 20 x 10 at (10, 0) in a page scaled by 2: 40 x 20 centred on world (70, 0)
    Json w = widget(t, "item");
    REQUIRE(w.is_object());
    CHECK(w["kind"] == "Interactable");
    CHECK(w["rect"][0].get<float>() == doctest::Approx(160 + 50));
    CHECK(w["rect"][1].get<float>() == doctest::Approx(90 - 10));
    CHECK(w["rect"][2].get<float>() == doctest::Approx(40));
    CHECK(w["rect"][3].get<float>() == doctest::Approx(20));
    move_to(t, at(70, 0));
    CHECK(t.ui.hovered() == item);
    move_to(t, at(70 + 19, 9));
    CHECK(t.ui.hovered() == item);
    move_to(t, at(70 + 21, 0));
    CHECK(t.ui.hovered() == kNullEntity);
    // the page turns a quarter: the same card is now tall and thin, still under the pointer where it is
    t.w.get<Transform>(page)->rotation = {0, 0, 90};
    t.frame();
    w = widget(t, "item");
    CHECK(w["rect"][2].get<float>() == doctest::Approx(20));
    CHECK(w["rect"][3].get<float>() == doctest::Approx(40));
    const Vec2 centre{w["rect"][0].get<float>() + 10, w["rect"][1].get<float>() + 20};
    move_to(t, centre);
    CHECK(t.ui.hovered() == item);
    move_to(t, centre + Vec2{15, 0});  // inside the old, wide rectangle but outside the turned one
    CHECK(t.ui.hovered() == kNullEntity);
    move_to(t, centre + Vec2{0, 18});
    CHECK(t.ui.hovered() == item);
}

TEST_CASE("Interactable: an explicit size and offset set the area, the children do not matter") {
    Ui t;
    Entity e = card(t, "e", {0, 0}, {10, 10});
    child_shape(t, "big", e, {0, 0}, {200, 200});
    Interactable& ia = *t.w.get<Interactable>(e);
    ia.size = {40, 20};
    ia.offset = {30, 0};
    t.frame();
    const Json w = widget(t, "e");
    CHECK(w["rect"][0].get<float>() == doctest::Approx(160 + 10));
    CHECK(w["rect"][2].get<float>() == doctest::Approx(40));
    move_to(t, at(30, 5));
    CHECK(t.ui.hovered() == e);
    move_to(t, at(0, 0));  // inside the big child, outside the area
    CHECK(t.ui.hovered() == kNullEntity);
}

TEST_CASE("Interactable: a screen-space entity is hit on the screen, with its anchor and the interface scale") {
    Ui t;
    Entity e = t.w.create("hud", "hud");
    t.w.get<Transform>(e)->position = {100, 50, 0};
    Shape2D& s = t.w.add<Shape2D>(e);
    s.space = RenderSpace::Screen;
    s.size = {60, 30};
    s.pivot = {0, 1};
    t.w.add<Interactable>(e);
    t.frame();
    Json w = widget(t, "hud");
    CHECK(w["world"] == false);
    CHECK(w["rect"][0].get<float>() == doctest::Approx(100));
    CHECK(w["rect"][1].get<float>() == doctest::Approx(50));
    CHECK(w["rect"][2].get<float>() == doctest::Approx(60));
    CHECK(w["rect"][3].get<float>() == doctest::Approx(30));
    move_to(t, {130, 65});
    CHECK(t.ui.hovered() == e);
    move_to(t, {161, 65});
    CHECK(t.ui.hovered() == kNullEntity);
    t.w.set_ui_scale(2.0f);  // the layout is in UI units, the pointer in pixels
    t.frame();
    w = widget(t, "hud");
    CHECK(w["rect"][0].get<float>() == doctest::Approx(200));
    CHECK(w["rect"][2].get<float>() == doctest::Approx(120));
    move_to(t, {250, 130});
    CHECK(t.ui.hovered() == e);
}

TEST_CASE("Interactable: hover, press, release, click, focus and blur reach scripts as ui events") {
    Ui t;
    Entity a = card(t, "a", {-60, 0}, {40, 20});
    Entity b = card(t, "b", {60, 0}, {40, 20});
    t.frame();
    t.events();
    move_to(t, at(-60, 0));
    CHECK(t.events() == V{"ui.hover:a=true"});
    CHECK(t.w.get<Interactable>(a)->hovered);
    CHECK(t.w.get<Interactable>(a)->state == InteractableState::Hover);
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    CHECK(t.events() == V{"ui.focus:a", "ui.press:a"});
    CHECK(t.w.get<Interactable>(a)->pressed);
    CHECK(t.w.get<Interactable>(a)->focused);
    CHECK(t.w.get<Interactable>(a)->state == InteractableState::Pressed);
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    CHECK(t.events() == V{"ui.release:a=true", "ui.click:a"});
    CHECK(t.ui.focused() == a);
    // leaving: hover false, and a press that ends elsewhere releases without a click
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    t.events();
    move_to(t, at(0, 50));
    CHECK(t.events() == V{"ui.hover:a=false"});
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    CHECK(t.events() == V{"ui.release:a=false"});
    CHECK(t.w.get<Interactable>(a)->state == InteractableState::Focused);
    // pressing the other one moves the focus: blur of a, focus of b
    t.click(at(60, 0));
    const V ev = t.events();
    CHECK(ev == V{"ui.hover:b=true", "ui.blur:a", "ui.focus:b", "ui.press:b", "ui.release:b=true", "ui.click:b"});
    CHECK(t.ui.focused() == b);
}

TEST_CASE("Interactable: focusOnHover moves the focus when the pointer enters, once") {
    Ui t;
    Entity a = card(t, "a", {-60, 0}, {40, 20});
    Entity b = card(t, "b", {60, 0}, {40, 20});
    t.w.get<Interactable>(b)->focusOnHover = true;
    t.w.get<Interactable>(a)->autoFocus = true;
    t.frame();
    CHECK(t.ui.focused() == a);
    move_to(t, at(60, 0));
    CHECK(t.ui.focused() == b);
    // the arrow keys still move it away: only the entering counts
    t.tap_key(Key::Left);
    CHECK(t.ui.focused() == a);
    t.frame(3);
    CHECK(t.ui.focused() == a);
}

TEST_CASE("Interactable: arrows, Tab and Shift+Tab move the focus between Interactables and built-in Buttons") {
    Ui t;
    Entity b1 = t.button("b1", {10, 10}, {60, 20});
    Entity c1 = card(t, "c1", {0, 0}, {40, 20});     // screen (140..180, 80..100)
    Entity c2 = card(t, "c2", {80, -60}, {40, 20});  // screen (220..260, 140..160)
    t.w.get<Button>(b1)->autoFocus = true;
    t.frame();
    CHECK(t.ui.focused() == b1);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == c1);
    t.tap_key(Key::Down);
    CHECK(t.ui.focused() == c2);
    t.tap_key(Key::Up);
    CHECK(t.ui.focused() == c1);
    t.tap_key(Key::Left);
    CHECK(t.ui.focused() == b1);
    // Tab walks the reading order and wraps; Shift+Tab goes back
    t.tap_key(Key::Tab);
    CHECK(t.ui.focused() == c1);
    t.tap_key(Key::Tab);
    CHECK(t.ui.focused() == c2);
    t.tap_key(Key::Tab);
    CHECK(t.ui.focused() == b1);
    t.in.on_key(Key::LeftShift, true);
    t.in.on_key(Key::Tab, true);
    t.frame();
    t.in.on_key(Key::Tab, false);
    t.in.on_key(Key::LeftShift, false);
    t.frame();
    CHECK(t.ui.focused() == c2);
    // the state of a widget with focus
    CHECK(t.w.get<Interactable>(c2)->focused);
    CHECK(widget(t, "c2")["state"] == "focused");
    CHECK_FALSE(t.w.get<Button>(b1)->focused);
}

TEST_CASE("Interactable: Enter on a focused button clicks, on a toggle flips it") {
    Ui t;
    Entity b = card(t, "b", {-60, 0}, {40, 20});
    Entity g = card(t, "g", {60, 0}, {40, 20}, kNullEntity, InteractableKind::Toggle);
    t.w.get<Interactable>(b)->autoFocus = true;
    t.frame();
    t.events();
    t.tap_key(Key::Enter);
    CHECK(t.events() == V{"ui.click:b"});
    t.ui.set_focus(t.w, g);
    t.events();
    t.tap_key(Key::Space);
    CHECK(t.events() == V{"ui.change:g=true"});
    CHECK(t.w.get<Interactable>(g)->on);
    CHECK(widget(t, "g")["value"] == true);
    t.tap_key(Key::Enter);
    CHECK(t.events() == V{"ui.change:g=false"});
}

TEST_CASE("Interactable: a disabled one is never hovered, focused, pressed or clicked, and a focused one loses focus") {
    Ui t;
    Entity a = card(t, "a", {-60, 0}, {40, 20});
    Entity b = card(t, "b", {60, 0}, {40, 20});
    t.frame();
    CHECK(t.ui.set_focus(t.w, a));
    t.w.get<Interactable>(a)->enabled = false;
    t.frame();
    CHECK(t.ui.focused() == kNullEntity);
    CHECK(t.w.get<Interactable>(a)->state == InteractableState::Disabled);
    CHECK(widget(t, "a")["interactable"] == false);
    t.events();
    t.click(at(-60, 0));
    CHECK(t.events().empty());
    CHECK_FALSE(t.ui.set_focus(t.w, a));
    // navigation skips it
    t.ui.set_focus(t.w, b);
    t.tap_key(Key::Left);
    CHECK(t.ui.focused() == b);
    t.w.get<Interactable>(a)->enabled = true;
    t.click(at(-60, 0));
    CHECK(t.ui.focused() == a);
}

TEST_CASE("Interactable: a modal Panel scopes the input, widgets outside it are out of reach") {
    Ui t;
    Entity world = card(t, "world", {0, 0}, {40, 20});
    Entity panel = t.add<Panel>("dialog", {10, 10}, {100, 60});
    t.w.get<Panel>(panel)->modal = true;
    Entity yes = t.button("yes", {20, 20}, {40, 20}, panel);
    t.w.get<Button>(yes)->autoFocus = true;
    // an Interactable inside the modal panel (screen space) is reachable
    Entity inside = t.w.create("inside", "inside");
    t.w.set_parent(inside, panel);
    t.w.get<Transform>(inside)->position = {70, 20, 0};
    Shape2D& s = t.w.add<Shape2D>(inside);
    s.space = RenderSpace::Screen;
    s.size = {30, 20};
    s.pivot = {0, 1};
    t.w.add<Interactable>(inside);
    t.frame();
    t.events();
    t.click(at(0, 0));
    CHECK(t.events().empty());
    CHECK(t.ui.focused() == yes);
    t.tap_key(Key::Right);
    CHECK(t.ui.focused() == inside);
    t.tap_key(Key::Tab);
    CHECK(t.ui.focused() == yes);
    CHECK(t.ui.widget_at(t.w, t.design, at(0, 0)) != world);
    t.w.get<Panel>(panel)->modal = false;
    t.frame();
    t.events();
    t.click(at(0, 0));
    CHECK(t.ui.focused() == world);
}

TEST_CASE("Interactable: a screen widget over a world one takes the pointer") {
    Ui t;
    Entity world = card(t, "world", {0, 0}, {100, 100});
    Entity over = t.button("over", {120, 40}, {80, 20});  // screen (120..200, 40..60) is over the card
    t.frame();
    move_to(t, at(0, 40));
    CHECK(t.ui.hovered() == over);
    CHECK(t.ui.pointer_over_ui());
    move_to(t, at(0, -30));
    CHECK(t.ui.hovered() == world);
    CHECK(t.ui.pointer_over_ui());  // the pointer is on a widget either way
    move_to(t, at(0, -80));
    CHECK(t.ui.hovered() == kNullEntity);
    CHECK_FALSE(t.ui.pointer_over_ui());
}

TEST_CASE("Interactable: of two overlapping widgets the higher layer, then the later entity wins") {
    Ui t;
    Entity low = card(t, "low", {0, 0}, {60, 60});
    Entity high = card(t, "high", {0, 0}, {60, 60});
    t.frame();
    move_to(t, at(0, 0));
    CHECK(t.ui.hovered() == high);  // equal layers: the later entity
    t.w.get<Shape2D>(low)->layer = 7;
    t.w.get<Shape2D>(high)->layer = 6;
    t.frame();
    CHECK(t.ui.hovered() == low);
    CHECK(t.ui.widget_at(t.w, t.design, at(0, 0)) == low);
}

TEST_CASE("Interactable toggle: click flips `on`, and InteractableVisual shows the check mark and tints per state") {
    Ui t;
    Entity box = card(t, "box", {0, 0}, {30, 30}, kNullEntity, InteractableKind::Toggle);
    Entity check = child_shape(t, "check", box, {0, 0}, {20, 20});
    t.w.add<InteractableVisual>(check).when = VisualWhen::On;
    Entity cross = child_shape(t, "cross", box, {0, 0}, {20, 20});
    t.w.add<InteractableVisual>(cross).when = VisualWhen::Off;
    Entity glow = child_shape(t, "glow", box, {0, 0}, {80, 80});  // bigger than the box: must not grow the area
    t.w.add<InteractableVisual>(glow).when = VisualWhen::Hover;
    InteractableVisual& tint = t.w.add<InteractableVisual>(box);
    tint.mode = VisualMode::Tint;
    tint.normal = {1, 1, 1, 1};
    tint.hover = {1, 0, 0, 1};
    tint.pressed = {0, 1, 0, 1};
    tint.disabled = {0.5f, 0.5f, 0.5f, 0.5f};
    t.frame();
    CHECK_FALSE(t.w.info(check).active);
    CHECK(t.w.info(cross).active);
    CHECK_FALSE(t.w.info(glow).active);
    CHECK(widget(t, "box")["rect"][2].get<float>() == doctest::Approx(30));
    move_to(t, at(0, 0));
    CHECK(t.w.info(glow).active);
    CHECK(t.w.get<Shape2D>(box)->color.g == doctest::Approx(0));  // hover tint
    CHECK(widget(t, "box")["rect"][2].get<float>() == doctest::Approx(30));
    t.events();
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    CHECK(t.w.get<Shape2D>(box)->color.g == doctest::Approx(1));  // pressed tint
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    CHECK(t.events() == V{"ui.focus:box", "ui.press:box", "ui.release:box=true", "ui.change:box=true"});
    CHECK(t.w.get<Interactable>(box)->on);
    CHECK(t.w.info(check).active);
    CHECK_FALSE(t.w.info(cross).active);
    // a script writing `on` and `enabled` is drawn without a click
    t.w.get<Interactable>(box)->on = false;
    t.w.get<Interactable>(box)->enabled = false;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.w.info(cross).active);
    CHECK_FALSE(t.w.info(glow).active);
    CHECK(t.w.get<Shape2D>(box)->color.r == doctest::Approx(0.5f));
}

TEST_CASE("Interactable slider: dragging along the area, the arrow keys, steps, and the knob and fill follow the value") {
    Ui t;
    Entity bar = card(t, "bar", {0, 0}, {100, 10}, kNullEntity, InteractableKind::Slider);
    Entity knob = child_shape(t, "knob", bar, {0, 0}, {8, 14});
    Entity fill = child_shape(t, "fill", bar, {0, 0}, {100, 4});
    t.w.get<Shape2D>(fill)->pivot = {0, 0.5f};
    Interactable& ia = *t.w.get<Interactable>(bar);
    ia.min = 0;
    ia.max = 10;
    ia.step = 1;
    ia.knob = knob;
    ia.fill = fill;
    t.frame();
    t.events();
    // press at 3/4 of the track, drag to the far left, and past the right end
    t.in.on_mouse_move(at(25, 0));
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    CHECK(ia.value == doctest::Approx(8));  // 7.5 snaps to the nearest step: round half away from zero
    CHECK(t.events().back() == "ui.change:bar=8.0");
    t.in.on_mouse_move(at(-50, 20));
    t.frame();
    CHECK(ia.value == doctest::Approx(0));
    t.in.on_mouse_move(at(500, 0));
    t.frame();
    CHECK(ia.value == doctest::Approx(10));
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    CHECK(t.w.get<Transform>(knob)->position.x == doctest::Approx(50));
    CHECK(t.w.get<Transform>(fill)->position.x == doctest::Approx(-50));
    CHECK(t.w.get<Transform>(fill)->scale.x == doctest::Approx(1));
    // the keys: left lowers by a step, up and down move the focus instead
    t.events();
    t.tap_key(Key::Left);
    CHECK(ia.value == doctest::Approx(9));
    CHECK(t.events() == V{"ui.change:bar=9.0"});
    t.tap_key(Key::Right);
    t.tap_key(Key::Right);
    CHECK(ia.value == doctest::Approx(10));  // clamped
    ia.value = 5;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.w.get<Transform>(knob)->position.x == doctest::Approx(0));
    CHECK(t.w.get<Transform>(fill)->scale.x == doctest::Approx(0.5f));
    // ui.set_slider
    CHECK(t.ui.set_slider(t.w, bar, 3.4f) == doctest::Approx(3));
    CHECK(widget(t, "bar")["value"].get<float>() == doctest::Approx(3));
}

TEST_CASE("Interactable slider: axis y runs bottom to top and up / down change the value") {
    Ui t;
    Entity bar = card(t, "bar", {0, 0}, {10, 100}, kNullEntity, InteractableKind::Slider);
    Interactable& ia = *t.w.get<Interactable>(bar);
    ia.axis = InteractableAxis::Y;
    ia.step = 0.25f;
    t.frame();
    t.click(at(0, -50));
    CHECK(ia.value == doctest::Approx(0));
    t.in.on_mouse_move(at(0, 50));
    t.in.on_mouse_button(MouseButton::Left, true);
    t.frame();
    CHECK(ia.value == doctest::Approx(1));
    t.in.on_mouse_button(MouseButton::Left, false);
    t.frame();
    t.tap_key(Key::Down);
    CHECK(ia.value == doctest::Approx(0.75f));
    t.tap_key(Key::Left);  // across the axis: moves the focus, nothing else is there
    CHECK(ia.value == doctest::Approx(0.75f));
}

TEST_CASE("Interactable: the accessibility label comes from `label`, a key, or the first Text") {
    Ui t;
    Entity e = card(t, "play", {0, 0}, {40, 20});
    Entity txt = t.w.create("txt", "txt");
    t.w.set_parent(txt, e);
    t.w.add<Text>(txt).text = "Play";
    t.frame();
    CHECK(widget(t, "play")["text"] == "Play");
    t.w.get<Interactable>(e)->label = "Start the game";
    CHECK(widget(t, "play")["text"] == "Start the game");
}

TEST_CASE("Interactable: the camera projection hook decides where a world widget is on the screen") {
    Ui t;
    Entity e = card(t, "e", {0, 0}, {20, 20});
    t.ui.set_world_projection([](Vec3 p, const Vec2*) { return Vec2{p.x * 2 + 100, 90 - p.y * 2}; });
    t.frame();
    const Json w = widget(t, "e");
    CHECK(w["rect"][0].get<float>() == doctest::Approx(80));
    CHECK(w["rect"][2].get<float>() == doctest::Approx(40));
    move_to(t, {100, 90});
    CHECK(t.ui.hovered() == e);
    move_to(t, at(0, 0));
    CHECK(t.ui.hovered() == kNullEntity);
}

TEST_CASE("Interactable: a camera with a viewport and zoom puts the widget where the renderer draws it") {
    Ui t;
    Entity cam = t.w.create("cam", "cam");
    t.w.add<Camera>(cam).orthoSize = 45;  // half of the 180 high design: scale 2
    t.w.get<Transform>(cam)->position = {10, 0, 0};
    Entity e = card(t, "e", {10, 0}, {20, 20});
    t.frame();
    const Json w = widget(t, "e");
    CHECK(w["rect"][0].get<float>() == doctest::Approx(160 - 20));
    CHECK(w["rect"][2].get<float>() == doctest::Approx(40));
    move_to(t, {160, 90});
    CHECK(t.ui.hovered() == e);
}

TEST_CASE("Interactable: a world widget with nothing to measure has no area, and an inactive one is not listed") {
    Ui t;
    Entity e = t.w.create("empty", "empty");
    t.w.add<Interactable>(e);
    Entity b = card(t, "b", {0, 0}, {20, 20});
    t.frame();
    CHECK(widget(t, "empty").is_null());
    CHECK(widget(t, "b").is_object());
    t.w.set_active(b, false);
    CHECK(widget(t, "b").is_null());
    move_to(t, at(0, 0));
    CHECK(t.ui.hovered() == kNullEntity);
}

TEST_CASE("Interactable: ui.focus drops the focus of an Interactable that goes away, with a blur") {
    Ui t;
    Entity a = card(t, "a", {0, 0}, {20, 20});
    t.w.get<Interactable>(a)->autoFocus = true;
    t.frame();
    t.events();
    CHECK(t.ui.focused() == a);
    t.w.set_active(a, false);
    t.frame();
    CHECK(t.ui.focused() == kNullEntity);
    CHECK(t.events() == V{"ui.blur:a"});
}
