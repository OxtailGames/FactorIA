#include "fa/ui/ui.h"
#include "fa/scene/chart.h"

#include <algorithm>
#include <array>
#include <cmath>

#include "fa/core/utf8.h"
#include "fa/scene/text_fit.h"
#include "ui_internal.h"

namespace fa {

using ui_detail::control_of;
using ui_detail::depth_of;

namespace {

constexpr float kRepeatDelay = 0.4f, kRepeatInterval = 0.1f;  // seconds, real time

enum Dir { Up, Down, Left, Right };
const char* const kDirAction[4] = {"ui_up", "ui_down", "ui_left", "ui_right"};

// ---------------------------------------------------------------------------------------------------------- events --
// ui.* events: data = {id} (null without a source), plus {value} when `value` is given.
void emit(World& w, const char* name, Entity source, Json value = nullptr) {
    Json data = Json::object({{"id", source ? Json(w.id_of(source)) : Json(nullptr)}});
    if (!value.is_null()) data["value"] = std::move(value);
    w.events().game.push_back(GameEvent{name, std::move(data), source});
}

// ------------------------------------------------------------------------------------------------------------ utf-8 --
void pop_code_point(std::string& s) {
    while (!s.empty()) {
        const unsigned char c = static_cast<unsigned char>(s.back());
        s.pop_back();
        if ((c & 0xC0) != 0x80) break;
    }
}

// ----------------------------------------------------------------------------------------------------------- slider --
float snap_slider(const Slider& s, float v) {
    const double lo = s.min, hi = std::max(s.min, s.max);
    double d = std::clamp(double(v), lo, hi);
    if (s.step > 0.0f) {  // the nearest step from min, or max itself when that is nearer (a range that is not a multiple of step)
        const double grid = std::clamp(lo + std::round((d - lo) / s.step) * s.step, lo, hi);
        d = std::fabs(hi - d) < std::fabs(grid - d) ? hi : grid;
    }
    return float(d);
}

// A widget the keyboard, the pad and the pointer can act on.
struct Item {
    Entity e;
    UiKind kind = UiKind::None;
    Rect rect;
    int layer = 0;
    bool interactable = true;
    bool inScope = true;   // false: outside the modal Panel that scopes the input (listed as not interactable)
};

// Active Button / Toggle / Slider / TextField in creation order.
// Under a modal Panel the widgets outside it are listed as not interactable: no focus, navigation, hover or press.
std::vector<Item> controls(const World& w, Vec2 design, Entity modal) {
    std::vector<Item> out;
    bool any = false;
    for (const TypeInfo* t : {&World::type_of<Button>(), &World::type_of<Toggle>(), &World::type_of<Slider>(), &World::type_of<TextField>()})
        any = any || !w.entities_with(t).empty();
    if (!any) return out;
    for (Entity e : w.entities()) {
        const UiKind k = ui_kind(w, e);
        if (!ui_is_control(k) || !w.active_in_hierarchy(e)) continue;
        const UiControl* c = control_of(w, e);
        bool inScope = true;
        if (modal) {
            inScope = false;
            for (Entity a = e; a && !inScope; a = w.parent(a)) inScope = a == modal;
        }
        out.push_back({e, k, *ui_rect(w, e, design), c->layer, c->interactable && inScope, inScope});
    }
    return out;
}

// The on-screen gamepad: the rectangles of the active TouchStick / TouchButton widgets go to Input in creation order (a
// later one wins an overlap, like the pointer); the touch pad's state comes back into their runtime fields.
void touch_controls(World& w, Input& in, Vec2 design) {
    static_assert(std::size_t(PadButton::RightThumb) + 1 == std::size_t(GamepadButton::Count), "PadButton mirrors GamepadButton");
    if (w.entities_with(&World::type_of<TouchStick>()).empty() && w.entities_with(&World::type_of<TouchButton>()).empty()) {
        if (!in.touch_controls().empty()) in.set_touch_controls({});
        return;
    }
    std::vector<Input::TouchControl> list;
    for (Entity e : w.entities()) {
        const UiKind k = ui_kind(w, e);
        if ((k != UiKind::TouchStick && k != UiKind::TouchButton) || !w.active_in_hierarchy(e)) continue;
        Input::TouchControl c;
        c.id = e.bits();
        c.rect = *ui_rect(w, e, design);
        if (const TouchStick* s = w.get<TouchStick>(e)) {
            c.stick = true;
            c.rightStick = s->stick == TouchStickSide::Right;
        } else {
            c.button = GamepadButton(w.get<TouchButton>(e)->button);
        }
        list.push_back(c);
    }
    in.set_touch_controls(std::move(list));
    const bool touch = in.last_device() == InputDevice::Touch;
    for (const Input::TouchControl& c : in.touch_controls()) {
        const Entity e = Entity::from_bits(c.id);
        if (TouchStick* s = w.get<TouchStick>(e)) {
            s->value = c.value;
            s->pressed = c.down;
            s->shown = touch || !s->touchOnly;
        } else if (TouchButton* b = w.get<TouchButton>(e)) {
            b->pressed = c.down;
            b->shown = touch || !b->touchOnly;
        }
    }
}

void reading_order(std::vector<Item>& items) {
    std::stable_sort(items.begin(), items.end(), [](const Item& a, const Item& b) {
        return a.rect.y != b.rect.y ? a.rect.y < b.rect.y : a.rect.x < b.rect.x;
    });
}

// Does a ScrollList have more content than it shows? Its children sit scroll pixels above their unscrolled place.
bool scrollable(const World& w, Entity e, Vec2 design, const VisualMeasure& measure) {
    const ScrollList& s = *w.get<ScrollList>(e);
    const Rect r = *ui_layout_rect(w, e, design);  // UI units, like screen_rect, padding and scroll
    float bottom = -1e30f;
    for (Entity c : w.children(e))
        if (w.active_in_hierarchy(c))
            if (const std::optional<Rect> cr = ui_detail::screen_rect(w, c, design, measure)) bottom = std::max(bottom, cr->y + cr->h);
    if (bottom < -1e29f) return false;
    const float content = bottom + s.scroll - (r.y + s.padding.y);
    return content - (r.h - s.padding.y - s.padding.w) > 0.5f;
}

}  // namespace

Entity ui_modal_panel(const World& w) {
    Entity best;
    int bestLayer = 0;
    if (w.entities_with(&World::type_of<Panel>()).empty()) return best;
    for (Entity e : w.entities()) {
        const Panel* p = w.get<Panel>(e);
        if (!p || !p->modal || !w.active_in_hierarchy(e)) continue;
        if (!best || p->layer >= bestLayer) {
            best = e;
            bestLayer = p->layer;
        }
    }
    return best;
}

namespace {
bool within(const World& w, Entity e, Entity scope) {
    for (Entity a = e; a; a = w.parent(a))
        if (a == scope) return true;
    return false;
}
}  // namespace

Entity ui_widget_at(const World& w, Vec2 design, Vec2 p, Entity ignore) {
    Entity best;
    int bestLayer = 0;
    const Entity modal = ui_modal_panel(w);
    for (Entity e : w.entities()) {
        const UiKind k = ui_kind(w, e);
        if (k == UiKind::None || k == UiKind::Captions || !w.active_in_hierarchy(e)) continue;
        if (modal && !within(w, e, modal)) continue;
        if (ignore) {
            bool under = false;
            for (Entity a = e; a && !under; a = w.parent(a)) under = a == ignore;
            if (under) continue;
        }
        const UiBox& box = *ui_box(w, e);
        if (k == UiKind::Panel && box.color.a <= 0.0f && box.texture.empty()) continue;
        if (const TouchStick* ts = w.get<TouchStick>(e); ts && !ts->shown) continue;
        if (const TouchButton* tb = w.get<TouchButton>(e); tb && !tb->shown) continue;
        const Rect r = *ui_rect(w, e, design);
        if (!(r.w > 0) || !(r.h > 0) || !r.contains(p)) continue;
        const std::optional<Rect> clip = ui_clip_rect(w, e, design);
        if (clip && !clip->contains(p)) continue;
        if (!best || box.layer >= bestLayer) {
            best = e;
            bestLayer = box.layer;
        }
    }
    return best;
}

// --------------------------------------------------------------------------------------------------------- actions --
static Json ui_default_actions() {
    return Json::parse(R"({
        "ui_up": ["Up", "GamepadDpadUp", "GamepadLeftStickUp"],
        "ui_down": ["Down", "GamepadDpadDown", "GamepadLeftStickDown"],
        "ui_left": ["Left", "GamepadDpadLeft", "GamepadLeftStickLeft"],
        "ui_right": ["Right", "GamepadDpadRight", "GamepadLeftStickRight"],
        "ui_submit": ["Enter", "Space", "GamepadA"],
        "ui_cancel": ["Escape", "GamepadB"]})");
}

Json ui_with_default_actions(const Json& actions) {
    if (!actions.is_null() && !actions.is_object()) return actions;  // a malformed value: set_actions reports it
    Json out = actions.is_object() ? actions : Json::object();
    const Json defaults = ui_default_actions();
    for (auto it = defaults.begin(); it != defaults.end(); ++it)
        if (!out.contains(it.key())) out[it.key()] = it.value();
    return out;
}

// ---------------------------------------------------------------------------------------------------------- update --
bool UiSystem::Repeat::tick(bool pressed, bool down, float dt) {
    if (!down && !pressed) {
        held = false;
        return false;
    }
    if (pressed || !held) {  // a press edge (also when the key went up again before this frame), or a held key first seen
        held = down;
        time = 0.0f;
        next = kRepeatDelay;
        return true;
    }
    time += dt;
    if (time < next) return false;
    next += kRepeatInterval;
    return true;
}

float UiSystem::set_slider(World& w, Entity e, float value) {
    Slider& s = *w.get<Slider>(e);
    set_focus(w, e);
    const float v = snap_slider(s, value);
    if (v != s.value) {
        s.value = v;
        emit(w, "ui.change", e, to_json(s.value));
    }
    return s.value;
}

void UiSystem::release_platform_keyboard(const World* w) {
    if (!platformField_) return;
    TextInputRequest r;
    r.focused = false;
    if (w && w->alive(platformField_))
        if (const TextField* tf = w->get<TextField>(platformField_)) {
            r.text = tf->text;
            r.maxLength = tf->maxLength;
        }
    platformField_ = kNullEntity;
    if (textInput_) textInput_(r);
}

bool UiSystem::submit_text(World& w, const std::string& text) {
    TextField* tf = platformField_ && platformField_ == focus_ && w.alive(platformField_) ? w.get<TextField>(platformField_) : nullptr;
    if (!tf) return false;
    std::string clean;
    for (std::size_t i = 0; i < text.size();) {
        const char32_t c = utf8_next(text, i);
        if (c < 32 || c == 127) continue;
        if (tf->maxLength > 0 && utf8_length(clean) >= std::size_t(tf->maxLength)) break;
        utf8_append(clean, c);
    }
    if (clean != tf->text) {
        tf->text = clean;
        caretStart_ = clock_;
        emit(w, "ui.change", platformField_, Json(tf->text));
    }
    return true;
}

void UiSystem::reset() {
    release_platform_keyboard(nullptr);
    askedField_ = kNullEntity;
    focus_ = hover_ = press_ = kNullEntity;
    focusCleared_ = false;
    pointerOn_ = pointerDown_ = pointerPrevDown_ = pointerOverUi_ = wheelConsumed_ = false;
    scrollToFocus_ = false;
    for (Repeat& r : nav_) r = Repeat{};
    backspace_ = Repeat{};
    autoSizes_.clear();
    warnedFit_.clear();
    scriptTooltips_.clear();
    worldTooltip_ = false;
    tooltipRest_ = 0.0f;
    tooltipShown_ = tooltipManual_ = false;
    tooltipTarget_ = 0;
    tooltipManualContent_ = nullptr;
    tooltipWarned_.clear();
    drag_ = DragState{};
    chartHover_ = kNullEntity;
    chartHoverSeries_ = chartHoverIndex_ = -1;
    dragCand_ = dragImage_ = kNullEntity;
    dropRules_.clear();
    worldDrop_ = UiDropMode::Accept;
}

void UiSystem::update_chart_hover(World& w, Vec2 design, Vec2 mouse) {
    Entity chart;
    std::optional<ChartSample> sample;
    const Entity top = ui_widget_at(w, design, mouse, dragImage_);
    if (top && w.has<Chart>(top)) {
        const Chart& c = *w.get<Chart>(top);
        const float k = ui_scale_clamped(w.ui_scale());  // the chart is laid out in UI units, the pointer is in pixels
        sample = chart_sample_at(c, chart_series(c), *ui_layout_rect(w, top, design), mouse / k);
        if (sample) chart = top;
    }
    const std::int32_t series = sample ? sample->series : -1, index = sample ? sample->index : -1;
    if (chart == chartHover_ && series == chartHoverSeries_ && index == chartHoverIndex_) return;
    // Tell the chart the pointer left (or moved to another sample), then the new one.
    if (chartHover_ && w.alive(chartHover_))
        if (Chart* old = w.get<Chart>(chartHover_)) {
            old->hoverIndex = old->hoverSeries = -1;
            if (chart != chartHover_) {
                w.events().game.push_back(GameEvent{"ui.chartHover", Json::object({{"id", w.id_of(chartHover_)}, {"index", -1}, {"series", -1}}),
                                                    chartHover_});
            }
        }
    chartHover_ = chart;
    chartHoverSeries_ = series;
    chartHoverIndex_ = index;
    if (chart) {
        Chart& c = *w.get<Chart>(chart);
        c.hoverIndex = index;
        c.hoverSeries = series;
        w.events().game.push_back(GameEvent{"ui.chartHover",
            Json::object({{"id", w.id_of(chart)}, {"index", index}, {"series", series}, {"value", to_json(float(sample->value))}}), chart});
    }
}

bool UiSystem::set_focus(World& w, Entity e) {
    if (!e) focusCleared_ = true;
    if (e) {
        const UiControl* c = w.alive(e) ? control_of(w, e) : nullptr;
        if (!c || !c->interactable || !w.active_in_hierarchy(e)) return false;
    }
    if (e) focusCleared_ = false;
    if (e == focus_) return true;
    if (UiControl* old = focus_ && w.alive(focus_) ? control_of(w, focus_) : nullptr) old->focused = false;
    focus_ = e;
    caretStart_ = clock_;
    if (e) {
        control_of(w, e)->focused = true;
        scrollToFocus_ = true;
        emit(w, "ui.focus", e);
    }
    return true;
}

void UiSystem::update(World& w, Input& in, Vec2 design, float dt, const VisualMeasure& measure) {
    layout(w, design, measure);
    touch_controls(w, in, design);
    clock_ += dt;
    const Entity modal = ui_modal_panel(w);
    const std::vector<Item> items = controls(w, design, modal);  // creation order
    std::vector<Item> ordered = items;                    // reading order: top, then left
    reading_order(ordered);
    auto find = [&](Entity e) -> const Item* {
        for (const Item& it : items)
            if (it.e == e) return &it;
        return nullptr;
    };

    // ---- focus rules: a focused widget that cannot be focused any more loses it; then autoFocus applies
    if (focus_) {
        const Item* it = find(focus_);
        if (!it || !it->interactable) focus_ = kNullEntity;
    }
    if (press_) {
        const Item* it = find(press_);
        if (!it || !it->interactable) press_ = kNullEntity;
    }
    // set_focus(null) holds until the player navigates: the arrows' first press then lets autoFocus work again (and is
    // spent on that, it does not also move the new focus).
    bool navWoke = false;
    if (focusCleared_) {
        for (const char* a : kDirAction) navWoke = navWoke || in.action_pressed(a);
        if (navWoke) focusCleared_ = false;
    }
    if (!focus_ && !focusCleared_) {
        for (const Item& it : ordered) {
            if (!it.interactable || !control_of(w, it.e)->autoFocus) continue;  // out of scope: not interactable
            set_focus(w, it.e);
            break;
        }
        // The panel's autoFocus widget is greyed out: the first interactable widget takes the focus instead.
        if (!focus_) {
            bool anyAuto = modal != kNullEntity;  // a modal keeps the focus inside whatever its widgets are
            for (const Item& it : ordered) anyAuto = anyAuto || (it.inScope && control_of(w, it.e)->autoFocus);
            if (anyAuto)
                for (const Item& it : ordered)
                    if (it.interactable) {
                        set_focus(w, it.e);
                        break;
                    }
        }
    }

    // ---- keys and pad
    for (int d = 0; d < 4; ++d) {
        if (!nav_[std::size_t(d)].tick(in.action_pressed(kDirAction[d]), in.action_down(kDirAction[d]), dt) || !focus_ || navWoke) continue;
        const UiKind kind = ui_kind(w, focus_);
        if (d >= Left && kind == UiKind::TextField) continue;  // ponytail: no caret movement, the caret stays at the end
        if (d >= Left && kind == UiKind::Slider) {
            Slider& s = *w.get<Slider>(focus_);
            const float inc = s.step > 0.0f ? s.step : (s.max - s.min) / 20.0f;
            const float v = snap_slider(s, s.value + (d == Right ? inc : -inc));
            if (v != s.value) {
                s.value = v;
                emit(w, "ui.change", focus_, to_json(s.value));
            }
            continue;
        }
        const Item* cur = find(focus_);
        const Vec2 dir = d == Up ? Vec2{0, -1} : d == Down ? Vec2{0, 1} : d == Left ? Vec2{-1, 0} : Vec2{1, 0};
        // Widgets in the beam (overlapping the focused one across the direction: the next tab along a row, the row
        // under a tab) win, nearest first. Otherwise the nearest in that half of the screen, sideways distance doubled.
        const Rect& r = cur->rect;
        const Item* best = nullptr;
        std::array<float, 3> bestKey{};
        for (const Item& it : ordered) {
            if (it.e == focus_ || !it.interactable) continue;
            const Vec2 delta = it.rect.center() - r.center();
            const float along = dot(delta, dir);
            if (along <= 1e-3f) continue;  // not in that half-plane of the current centre
            const float across = std::fabs(dot(delta, perp(dir)));
            const Rect& o = it.rect;
            const bool inBeam = d >= Left ? o.y < r.y + r.h && r.y < o.y + o.h : o.x < r.x + r.w && r.x < o.x + o.w;
            const std::array<float, 3> key = inBeam ? std::array<float, 3>{0, along, across}
                                                    : std::array<float, 3>{1, along + 2.0f * across, 0};
            if (!best || key < bestKey) {
                best = &it;
                bestKey = key;
            }
        }
        if (best) set_focus(w, best->e);
    }

    if (in.action_pressed("ui_submit") && focus_) {
        const UiKind kind = ui_kind(w, focus_);
        if (kind == UiKind::Button) {
            emit(w, "ui.click", focus_);
            in.consume_action("ui_submit");  // handled: a script that reads the same key later does not act on it too
        } else if (kind == UiKind::Toggle) {
            Toggle& t = *w.get<Toggle>(focus_);
            t.value = !t.value;
            emit(w, "ui.change", focus_, Json(t.value));
            in.consume_action("ui_submit");
        }
    }
    const bool navCancel = in.action_pressed("ui_cancel");
    if (navCancel && !drag_.active) emit(w, "ui.cancel", focus_);  // while dragging, cancel ends the drag instead
    if (navCancel && drag_.active) in.consume_action("ui_cancel");  // the drag took it

    if (focus_) {
        if (TextField* tf = w.get<TextField>(focus_)) {
            bool changed = false;
            // A Ctrl or Cmd chord (Ctrl+V) is a command, not typing; Ctrl+Alt is AltGr, which does type.
            const bool chord = (in.key_down(Key::LeftControl) || in.key_down(Key::RightControl) || in.key_down(Key::LeftSuper) ||
                                in.key_down(Key::RightSuper)) &&
                               !in.key_down(Key::LeftAlt) && !in.key_down(Key::RightAlt);
            for (const char32_t c : chord ? std::u32string() : in.text_input()) {
                if (c < 32 || c == 127 || c > 0x10FFFF || (c >= 0xD800 && c <= 0xDFFF)) continue;
                if (tf->maxLength > 0 && utf8_length(tf->text) >= std::size_t(tf->maxLength)) break;
                utf8_append(tf->text, c);
                changed = true;
            }
            if (clipboard_ && in.paste_pressed()) {
                // Pastes at the end (the field has no caret yet): newlines and other control characters are dropped, and
                // maxLength counts code points like typing does.
                const std::string pasted = clipboard_->get();
                for (std::size_t i = 0; i < pasted.size();) {
                    const char32_t c = utf8_next(pasted, i);
                    if (c < 32 || c == 127 || (c >= 0x80 && c < 0xA0)) continue;
                    if (tf->maxLength > 0 && utf8_length(tf->text) >= std::size_t(tf->maxLength)) break;
                    utf8_append(tf->text, c);
                    changed = true;
                }
            }
            if (clipboard_ && in.copy_pressed()) clipboard_->set(tf->text);
            if (backspace_.tick(in.key_pressed(Key::Backspace), in.key_down(Key::Backspace), dt) && !tf->text.empty()) {
                pop_code_point(tf->text);
                changed = true;
            }
            if (changed) {
                caretStart_ = clock_;
                emit(w, "ui.change", focus_, Json(tf->text));
            }
            if (in.key_pressed(Key::Enter)) emit(w, "ui.submit", focus_, Json(tf->text));
        }
    }

    // ---- pointer: hovered = the top-most (highest layer, then latest) visible interactable widget under the mouse
    // The pointer: the virtual one (set_pointer) when there is one, else the mouse.
    const Vec2 mouse = pointerOn_ ? pointerPos_ : in.mouse_position();
    const bool ptrDown = pointerOn_ ? pointerDown_ : in.mouse_down(MouseButton::Left);
    const bool ptrPressed = pointerOn_ ? pointerDown_ && !pointerPrevDown_ : in.mouse_pressed(MouseButton::Left);
    const bool ptrReleased = pointerOn_ ? !pointerDown_ && pointerPrevDown_ : in.mouse_released(MouseButton::Left);
    pointerPrevDown_ = pointerOn_ && pointerDown_;
    pointerOverUi_ = modal || ui_widget_at(w, design, mouse, dragImage_) != kNullEntity;
    update_chart_hover(w, design, mouse);
    hover_ = kNullEntity;
    int hoverLayer = 0;
    for (const Item& it : items) {  // creation order, so on equal layers the later entity wins
        if (!it.interactable || !it.rect.contains(mouse)) continue;
        const std::optional<Rect> clip = ui_clip_rect(w, it.e, design);
        if (clip && !clip->contains(mouse)) continue;
        if (dragImage_) {  // the drag image is not a target
            bool onImage = false;
            for (Entity a = it.e; a && !onImage; a = w.parent(a)) onImage = a == dragImage_;
            if (onImage) continue;
        }
        if (!hover_ || it.layer >= hoverLayer) {
            hover_ = it.e;
            hoverLayer = it.layer;
        }
    }

    if (ptrPressed && hover_) {
        press_ = hover_;
        set_focus(w, hover_);
    }
    update_drag(w, design, mouse, ptrDown, ptrPressed, ptrReleased, measure, navCancel);
    if (press_) {
        if (Slider* s = w.get<Slider>(press_)) {
            const Item* it = find(press_);
            const float k = ui_scale_clamped(w.ui_scale());  // the track is laid out in UI units, the pointer is in pixels
            const Rect unitRect{it->rect.x / k, it->rect.y / k, it->rect.w / k, it->rect.h / k};
            const auto [left, right] = ui_slider_track(*s, unitRect);
            const float t = right > left ? std::clamp((mouse.x / k - left) / (right - left), 0.0f, 1.0f) : 0.0f;
            const float v = snap_slider(*s, s->min + t * (std::max(s->min, s->max) - s->min));
            if (v != s->value) {
                s->value = v;
                emit(w, "ui.change", press_, to_json(s->value));
            }
        }
        if (ptrReleased || !ptrDown) {
            if (hover_ == press_) {
                if (ui_kind(w, press_) == UiKind::Button) {
                    emit(w, "ui.click", press_);
                } else if (Toggle* t = w.get<Toggle>(press_)) {
                    t->value = !t->value;
                    emit(w, "ui.change", press_, Json(t->value));
                }
            }
            press_ = kNullEntity;
        }
    }

    // ---- wheel: scrolls the innermost ScrollList under the pointer
    wheelConsumed_ = false;
    if (in.mouse_wheel() != 0.0f) {
        ScrollList* target = nullptr;
        Entity targetEntity;
        int targetDepth = -1;
        w.each<ScrollList>([&](Entity e, ScrollList& s) {
            if (!w.active_in_hierarchy(e) || !ui_rect(w, e, design)->contains(mouse)) return;
            if (modal && !within(w, e, modal)) return;
            const std::optional<Rect> clip = ui_clip_rect(w, e, design);
            if (clip && !clip->contains(mouse)) return;
            const int depth = depth_of(w, e);
            if (depth >= targetDepth) {
                target = &s;
                targetEntity = e;
                targetDepth = depth;
            }
        });
        if (target) {
            const bool scrolls = scrollable(w, targetEntity, design, measure);  // before the scroll moves
            target->scroll -= in.mouse_wheel() * target->scrollSpeed;           // wheel up (positive) scrolls towards the top
            // A list with more to show keeps the wheel for itself, also at the end of its range (the map must not zoom there).
            if (scrolls) {
                wheelConsumed_ = true;
                in.consume_mouse_wheel();
            }
        }
    }

    const Panel* modalPanel = modal ? w.get<Panel>(modal) : nullptr;
    if (modal && in.mouse_wheel() != 0.0f && !wheelConsumed_ && !(modalPanel && modalPanel->wheelPassThrough)) {  // the wheel stays in the modal: the game below must not zoom
        wheelConsumed_ = true;
        in.consume_mouse_wheel();
    }

    // ---- tooltips: the rest timer, what shows and where (tooltip.cpp)
    lastPointer_ = mouse;
    update_tooltip(w, in, design, dt, measure, mouse, ptrDown);

    // ---- runtime flags the renderer and scripts read
    for (const Item& it : items) {
        UiControl* c = control_of(w, it.e);
        c->focused = it.e == focus_;
        c->hovered = it.e == hover_;
        c->pressed = it.e == press_;
        if (TextField* tf = w.get<TextField>(it.e))
            tf->caret = it.e == focus_ && std::fmod(clock_ - caretStart_, 1.0f) < 0.5f;
    }

    // ---- the platform's own keyboard (a native plugin): offered a TextField that a gamepad player focused, and told when
    // the player leaves it. It stays up while the field keeps the focus whatever the last input is: the Steam Deck's
    // floating keyboard types into the window as key presses, which makes the keyboard the last device.
    if (platformField_ && (focus_ != platformField_ || !w.alive(platformField_))) release_platform_keyboard(&w);
    if (textInput_) {
        const TextField* tf = focus_ ? w.get<TextField>(focus_) : nullptr;
        const bool padOnField = tf && in.last_device() == InputDevice::Gamepad;
        const bool again = padOnField && in.action_pressed("ui_submit");  // A on the field after the player closed the keyboard
        if (!padOnField && !platformField_) askedField_ = kNullEntity;
        if (padOnField && (focus_ != askedField_ || again)) {
            askedField_ = focus_;
            TextInputRequest r;
            r.rect = *ui_rect(w, focus_, design);
            r.text = tf->text;
            r.maxLength = tf->maxLength;
            if (textInput_(r)) platformField_ = focus_;
            else if (platformField_ == focus_) platformField_ = kNullEntity;
        }
    }
    in.set_platform_keyboard(platformField_ != kNullEntity);
    // Text input mode: a focused TextField takes the typed keys, so game actions bound to letters read as up meanwhile.
    in.set_ui_text_input(focus_ && w.get<TextField>(focus_));

    // ---- the phone's keyboard follows a TextField's focus: up when one gets it, down when it goes. Only the changes
    // count, so a script's input.showKeyboard() in between still works. A pad player gets the game's on-screen keyboard
    // instead (docs/MENUS.md), not the phone's.
    const bool wantKeyboard = focus_ && w.get<TextField>(focus_) && in.last_device() != InputDevice::Gamepad;
    if (wantKeyboard != keyboardRaised_) {
        keyboardRaised_ = wantKeyboard;
        in.set_keyboard_shown(wantKeyboard);
    }
}

// ----------------------------------------------------------------------------------------------------------- state --
Json UiSystem::state(const World& w, Vec2 design, const VisualMeasure& measure) const {
    std::vector<Item> items;
    for (Entity e : w.entities()) {
        const UiKind k = ui_kind(w, e);
        if (k == UiKind::None || !w.active_in_hierarchy(e)) continue;
        const UiControl* c = control_of(w, e);
        items.push_back({e, k, *ui_rect(w, e, design), 0, c && c->interactable});
    }
    reading_order(items);
    Json list = Json::array();
    for (const Item& it : items) {
        const std::optional<Rect> clip = ui_clip_rect(w, it.e, design);
        const bool visible = !clip || (clip->w > 0 && clip->h > 0 && clip->overlaps(it.rect));
        Json j = Json::object({{"id", w.id_of(it.e)}, {"kind", ui_kind_name(it.kind)},
                               {"rect", to_json(it.rect)},
                               {"focused", it.e == focus_}, {"hovered", it.e == hover_}, {"pressed", it.e == press_},
                               {"interactable", it.interactable}, {"visible", visible}});
        if (const Toggle* t = w.get<Toggle>(it.e)) {
            j["value"] = t->value;
            j["text"] = t->label;
        } else if (const Slider* s = w.get<Slider>(it.e)) {
            j["value"] = to_json(s->value);
            if (!s->label.empty()) j["text"] = s->label;
        } else if (const Button* b = w.get<Button>(it.e)) {
            j["text"] = b->text;
        } else if (const TextField* f = w.get<TextField>(it.e)) {
            j["text"] = f->text;
        } else if (const TouchStick* ts = w.get<TouchStick>(it.e)) {
            j["value"] = to_json(ts->value);
            j["pressed"] = ts->pressed;
            j["visible"] = visible && ts->shown;
        } else if (const TouchButton* tb = w.get<TouchButton>(it.e)) {
            j["pressed"] = tb->pressed;  // a finger holds it (the pointer never presses a touch control)
            j["visible"] = visible && tb->shown;
            if (!tb->text.empty()) j["text"] = tb->text;
        }
        if (ui_text_overflowed(w, it.e, design, measure)) j["overflowed"] = true;
        list.push_back(std::move(j));
    }
    // Screen-space Text is no widget, but a test checks where the HUD text is (and that it fits).
    std::vector<std::pair<Rect, Entity>> texts;
    for (Entity e : w.entities()) {
        const Text* t = w.get<Text>(e);
        if (!t || t->space != RenderSpace::Screen || !w.active_in_hierarchy(e)) continue;
        if (const std::optional<Rect> r = ui_screen_rect(w, e, design, measure)) texts.push_back({*r, e});
    }
    std::stable_sort(texts.begin(), texts.end(), [](const auto& a, const auto& b) {
        return a.first.y != b.first.y ? a.first.y < b.first.y : a.first.x < b.first.x;
    });
    for (const auto& [rect, e] : texts) {
        const std::optional<Rect> clip = ui_clip_rect(w, e, design);  // a ScrollList clips its Text children like its widgets
        const bool visible = !clip || (clip->w > 0 && clip->h > 0 && clip->overlaps(rect));
        Json j = Json::object({{"id", w.id_of(e)}, {"kind", "Text"}, {"rect", to_json(rect)}, {"text", w.get<Text>(e)->text},
                               {"focused", false}, {"hovered", false}, {"pressed", false}, {"interactable", false},
                               {"visible", visible}});
        if (ui_text_overflowed(w, e, design, measure)) j["overflowed"] = true;
        list.push_back(std::move(j));
    }
    return Json::object({{"focused", focus_ && w.alive(focus_) ? Json(w.id_of(focus_)) : Json(nullptr)},
                         {"hovered", hover_ && w.alive(hover_) ? Json(w.id_of(hover_)) : Json(nullptr)},
                         {"uiScale", ui_scale_clamped(w.ui_scale())},
                         {"tooltip", ui_tooltip_json(w.ui_tooltip(), ui_scale_clamped(w.ui_scale()))},
                         {"widgets", std::move(list)}});
}

}  // namespace fa
