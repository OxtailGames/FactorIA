#include "fa/scene/ui_rect.h"

#include <algorithm>
#include <cmath>
#include <format>

namespace fa {

const char* ui_kind_name(UiKind k) {
    switch (k) {
        case UiKind::Panel: return "Panel";
        case UiKind::Button: return "Button";
        case UiKind::Toggle: return "Toggle";
        case UiKind::Slider: return "Slider";
        case UiKind::TextField: return "TextField";
        case UiKind::ScrollList: return "ScrollList";
        case UiKind::TouchStick: return "TouchStick";
        case UiKind::TouchButton: return "TouchButton";
        case UiKind::None: break;
    }
    return "";
}

UiKind ui_kind(const World& w, Entity e) {
    if (w.has<Button>(e)) return UiKind::Button;
    if (w.has<Toggle>(e)) return UiKind::Toggle;
    if (w.has<Slider>(e)) return UiKind::Slider;
    if (w.has<TextField>(e)) return UiKind::TextField;
    if (w.has<ScrollList>(e)) return UiKind::ScrollList;
    if (w.has<Panel>(e)) return UiKind::Panel;
    if (w.has<TouchStick>(e)) return UiKind::TouchStick;
    if (w.has<TouchButton>(e)) return UiKind::TouchButton;
    return UiKind::None;
}

const UiBox* ui_box(const World& w, Entity e) {
    switch (ui_kind(w, e)) {
        case UiKind::Panel: return w.get<Panel>(e);
        case UiKind::Button: return w.get<Button>(e);
        case UiKind::Toggle: return w.get<Toggle>(e);
        case UiKind::Slider: return w.get<Slider>(e);
        case UiKind::TextField: return w.get<TextField>(e);
        case UiKind::ScrollList: return w.get<ScrollList>(e);
        case UiKind::TouchStick: return w.get<TouchStick>(e);
        case UiKind::TouchButton: return w.get<TouchButton>(e);
        case UiKind::None: break;
    }
    return nullptr;
}

const UiControl* ui_control(const World& w, Entity e) {
    return ui_is_control(ui_kind(w, e)) ? static_cast<const UiControl*>(ui_box(w, e)) : nullptr;
}

Vec2 anchor_point(Vec2 anchor, bool safeArea, Vec2 designSize, const EdgeInsets& insets) {
    if (!safeArea) return {anchor.x * designSize.x, anchor.y * designSize.y};
    return {insets.left + anchor.x * (designSize.x - insets.left - insets.right),
            insets.top + anchor.y * (designSize.y - insets.top - insets.bottom)};
}

const std::vector<std::string>& safe_area_profile_names() {
    static const std::vector<std::string> names = {"none", "phone-portrait", "phone-landscape"};
    return names;
}

bool safe_area_profile(std::string_view name, Vec2 designSize, EdgeInsets& out) {
    if (name == "none") out = {};
    // iPhone 15 in points: 393 x 852, notch area 59 at the top and home indicator 34 at the bottom; turned, 59 on each
    // side and 21 at the bottom.
    else if (name == "phone-portrait") out = {0, designSize.y * (59.0f / 852.0f), 0, designSize.y * (34.0f / 852.0f)};
    else if (name == "phone-landscape") out = {designSize.x * (59.0f / 852.0f), 0, designSize.x * (59.0f / 852.0f), designSize.y * (21.0f / 393.0f)};
    else return false;
    return true;
}

std::optional<Rect> ui_rect(const World& w, Entity e, Vec2 designSize) {
    const UiBox* b = ui_box(w, e);
    if (!b) return std::nullopt;
    const Vec3 t = w.world_matrix(e).translation();
    const Vec2 a = anchor_point(b->anchor, b->safeArea, designSize, w.safe_insets());
    return Rect{t.x + a.x - b->pivot.x * b->size.x, t.y + a.y - (1.0f - b->pivot.y) * b->size.y, b->size.x, b->size.y};
}

Rect ui_intersect(const Rect& a, const Rect& b) {
    const float x0 = std::max(a.x, b.x), y0 = std::max(a.y, b.y);
    const float x1 = std::min(a.x + a.w, b.x + b.w), y1 = std::min(a.y + a.h, b.y + b.h);
    return Rect{x0, y0, std::max(0.0f, x1 - x0), std::max(0.0f, y1 - y0)};
}

std::optional<Rect> ui_clip_rect(const World& w, Entity e, Vec2 designSize) {
    std::optional<Rect> clip;
    for (Entity p = w.parent(e); p; p = w.parent(p)) {
        if (!w.has<ScrollList>(p)) continue;
        const std::optional<Rect> r = ui_rect(w, p, designSize);
        if (r) clip = clip ? ui_intersect(*clip, *r) : *r;
    }
    return clip;
}

std::pair<float, float> ui_slider_track(const Slider& s, const Rect& r) {
    const float inner0 = r.x + 8.0f, innerW = std::max(0.0f, r.w - 16.0f);
    const float labelW = s.label.empty() ? 0.0f : innerW * 0.35f;
    const float zone0 = inner0 + labelW, zoneW = innerW * (s.label.empty() ? 0.85f : 0.5f);
    return {zone0 + 8.0f, std::max(zone0 + 8.0f, zone0 + zoneW - 8.0f)};
}

std::string ui_slider_value_text(const Slider& s, float value) {
    if (s.min == 0.0f && s.max == 1.0f) return std::format("{}%", int(std::lround(value * 100.0f)));
    std::string t = std::format("{:.2f}", value);
    while (t.back() == '0') t.pop_back();
    if (t.back() == '.') t.pop_back();
    return t;
}

}  // namespace fa
