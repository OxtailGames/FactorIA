// Tooltips: reads the `tooltip` of a widget (or a script function's answer), times the pointer's rest, builds the view and places
// it. The data (style, view) lives in the World (scene/ui_tooltip.h) and fa_render draws it. docs/MENUS.md, "Tooltips".
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/log.h"
#include "fa/ui/ui.h"
#include "ui_internal.h"

namespace fa {

namespace {

constexpr float kSlop = 5.0f;     // pixels the pointer may wander and still count as resting
constexpr float kMargin = 4.0f;   // pixels kept free at the screen edges
constexpr u64 kWorldTarget = ~u64(0);


// One text of the content: a locale key when the language table has it, else the text as written.
std::string resolve_text(const std::string& s, const I18n* i18n, const Json& args) {
    if (i18n && i18n->enabled()) {
        if (std::optional<std::string> t = i18n->translate(s, args)) return *t;
    }
    return s;
}

}  // namespace

std::optional<UiTooltipText> ui_tooltip_text(const Json& content, const I18n* i18n, std::string* error) {
    auto fail = [&](std::string m) -> std::optional<UiTooltipText> {
        if (error) *error = std::move(m);
        return std::nullopt;
    };
    UiTooltipText out;
    if (content.is_null()) return out;
    if (content.is_string()) {
        const std::string t = resolve_text(content.get<std::string>(), i18n, nullptr);
        if (!t.empty()) out.lines.push_back({t, std::nullopt});
        return out;
    }
    if (!content.is_object())
        return fail("a tooltip is a string (a locale key or the text) or an object {title, lines}, got " + content.dump() +
                    ". Write \"Gold: 120\" or {\"title\": \"Gold\", \"lines\": [\"120 coins\", {\"text\": \"low\", \"color\": \"#ff6\"}]}.");
    const Json args = content.contains("args") ? content["args"] : Json(nullptr);
    if (auto it = content.find("title"); it != content.end() && !it->is_null()) {
        if (!it->is_string()) return fail("tooltip title must be a string (a locale key or the text), got " + it->dump() + ".");
        out.title = resolve_text(it->get<std::string>(), i18n, args);
    }
    if (auto it = content.find("lines"); it != content.end() && !it->is_null()) {
        if (!it->is_array()) return fail("tooltip lines must be an array of strings or {text, color}, got " + it->dump() + ".");
        for (const Json& l : *it) {
            UiTooltipText::Line line;
            if (l.is_string()) {
                line.text = resolve_text(l.get<std::string>(), i18n, args);
            } else if (l.is_object() && l.contains("text") && l["text"].is_string()) {
                line.text = resolve_text(l["text"].get<std::string>(), i18n, args);
                if (auto c = l.find("color"); c != l.end() && !c->is_null()) {
                    Color col;
                    std::string err;
                    if (!json_to(*c, col, &err)) return fail("tooltip line colour " + c->dump() + ": " + err);
                    line.color = col;
                }
            } else {
                return fail("a tooltip line is a string or {text, color}, got " + l.dump() + ".");
            }
            if (!line.text.empty()) out.lines.push_back(std::move(line));  // an empty line is skipped: a function can return "" for "no row"
        }
    }
    return out;
}

namespace {
Vec2 measure_line(const std::string& s, const UiTooltipStyle& st, float size, const VisualMeasure& m) {
    Text t;
    t.text = s;
    t.font = st.font;
    t.fontSize = size;
    t.maxWidth = st.maxWidth;
    t.space = RenderSpace::Screen;
    return m.textSize ? m.textSize(t) : approx_text_size(t, m.textScale);
}
}  // namespace

Vec2 ui_tooltip_size(const UiTooltipText& text, const UiTooltipStyle& st, const VisualMeasure& m) {
    float w = 0, h = 0;
    int n = 0;
    auto add = [&](const std::string& s, float size) {
        const Vec2 sz = measure_line(s, st, size, m);
        w = std::max(w, sz.x);
        h += sz.y + (n++ > 0 ? st.spacing : 0.0f);
    };
    if (!text.title.empty()) add(text.title, st.titleSize);
    for (const auto& l : text.lines) add(l.text, st.fontSize);
    return {std::ceil(w) + st.padding.x + st.padding.z, std::ceil(h) + st.padding.y + st.padding.w};
}

Vec2 ui_tooltip_place(Vec2 pointer, Vec2 size, Vec2 screen, float gap) {
    float x = pointer.x + gap;
    float y = pointer.y + gap + 6.0f;  // a little lower than it is wide: the cursor's tip is at the top-left of its image
    if (x + size.x > screen.x - kMargin) x = pointer.x - gap - size.x;
    if (y + size.y > screen.y - kMargin) y = pointer.y - gap - size.y;
    x = std::max(kMargin, std::min(x, screen.x - size.x - kMargin));
    y = std::max(kMargin, y);
    return {x, y};
}

UiTooltipView ui_tooltip_layout(const UiTooltipText& text, const UiTooltipStyle& st, const VisualMeasure& m, Vec2 pointer,
                                Vec2 screenPx, float k) {
    UiTooltipView v;
    if (text.empty()) return v;
    const Vec2 size = ui_tooltip_size(text, st, m);
    const Vec2 at = ui_tooltip_place(pointer, size * k, screenPx, st.gap * k) / k;
    v.shown = true;
    v.rect = Rect{at.x, at.y, size.x, size.y};
    float y = at.y + st.padding.y;
    auto add = [&](const std::string& s, float fontSize, Color col, bool title) {
        UiTooltipLine l;
        l.text = s;
        l.color = col;
        l.fontSize = fontSize;
        l.title = title;
        l.pos = {at.x + st.padding.x, y};
        y += measure_line(s, st, fontSize, m).y + st.spacing;
        v.lines.push_back(std::move(l));
    };
    if (!text.title.empty()) add(text.title, st.titleSize, st.titleColor, true);
    for (const auto& l : text.lines) add(l.text, st.fontSize, l.color.value_or(st.textColor), false);
    return v;
}

void UiSystem::set_script_tooltip(Entity e, bool on) {
    if (on) scriptTooltips_.insert(e.bits());
    else scriptTooltips_.erase(e.bits());
}

Result<void> UiSystem::show_tooltip(World& w, const Json& content, Vec2 at, Vec2 design, const VisualMeasure& measure) {
    std::string err;
    const std::optional<UiTooltipText> text = ui_tooltip_text(content, i18n_, &err);
    if (!text) return make_error("ui.showTooltip: " + err, "Pass a string or {title, lines}.");
    tooltipManual_ = true;
    tooltipManualContent_ = content;
    manualAt_ = at;
    tooltipAnchor_ = lastPointer_;
    UiTooltipView v = ui_tooltip_layout(*text, w.ui_tooltip_settings().style, measure, at, design, ui_scale_clamped(w.ui_scale()));
    v.source = "manual";
    w.ui_tooltip() = std::move(v);
    return {};
}

void UiSystem::hide_tooltip(World& w) {
    tooltipManual_ = false;
    tooltipManualContent_ = nullptr;
    tooltipShown_ = false;
    tooltipRest_ = 0.0f;
    w.ui_tooltip() = UiTooltipView{};
}

void UiSystem::update_tooltip(World& w, const Input& in, Vec2 design, float dt, const VisualMeasure& measure, Vec2 mouse,
                              bool pointerDown) {
    const UiTooltipSettings& cfg = w.ui_tooltip_settings();
    tooltipDelay_ = cfg.delay;
    const float k = ui_scale_clamped(w.ui_scale());
    UiTooltipView& view = w.ui_tooltip();
    const bool off = pointerDown || (in.last_device() == InputDevice::Touch && !cfg.onTouch);

    if (tooltipManual_) {
        if (distance(mouse, tooltipAnchor_) <= kSlop) {
            // Rebuilt every frame, so a language change or a resized window shows.
            if (auto text = ui_tooltip_text(tooltipManualContent_, i18n_)) {
                UiTooltipView v = ui_tooltip_layout(*text, cfg.style, measure, manualAt_, design, k);
                v.source = "manual";
                view = std::move(v);
                return;
            }
        }
        tooltipManual_ = false;
        tooltipManualContent_ = nullptr;
        view = UiTooltipView{};
    }

    // What is under the pointer: the first widget from the top up to the root with a tooltip, else the world's function.
    Json content;
    std::string source, widgetId;
    u64 target = 0;
    bool have = false;
    if (!off) {
        const Entity under = ui_widget_at(w, design, mouse);
        for (Entity a = under; a && !have; a = w.parent(a)) {
            if (tooltipHooks_.widget && scriptTooltips_.count(a.bits())) {
                Json c = tooltipHooks_.widget(a);
                if (!c.is_null()) {
                    content = std::move(c);
                    source = "script";
                    have = true;
                }
            }
            if (!have) {
                if (const UiBox* b = ui_box(w, a); b && !b->tooltip.is_null()) {
                    content = b->tooltip;
                    source = "widget";
                    have = true;
                }
            }
            if (have) {
                target = a.bits();
                widgetId = w.id_of(a);
            }
        }
        if (!have && !under && worldTooltip_ && tooltipHooks_.world) {
            Json c = tooltipHooks_.world(mouse);
            if (!c.is_null()) {
                content = std::move(c);
                source = "world";
                target = kWorldTarget;
                have = true;
            }
        }
    }

    std::optional<UiTooltipText> text;
    if (have) {
        std::string err;
        text = ui_tooltip_text(content, i18n_, &err);
        if (!text) {
            const std::string msg = std::format("Tooltip of '{}': {}", widgetId.empty() ? source : widgetId, err);
            if (msg != tooltipWarned_) FA_WARN("ui", "{}", msg);
            tooltipWarned_ = msg;
            have = false;
        } else if (text->empty()) {
            have = false;
        }
    }

    if (!have || target != tooltipTarget_ || distance(mouse, tooltipAnchor_) > kSlop) {
        tooltipRest_ = 0.0f;
        tooltipShown_ = false;
        tooltipAnchor_ = mouse;
        tooltipTarget_ = have ? target : 0;
        view = UiTooltipView{};
        if (!have) return;
    }
    tooltipRest_ += dt;
    if (tooltipRest_ < cfg.delay) return;
    tooltipShown_ = true;
    UiTooltipView v = ui_tooltip_layout(*text, cfg.style, measure, tooltipAnchor_, design, k);
    v.source = source;
    v.widget = widgetId;
    view = std::move(v);
}

}  // namespace fa
