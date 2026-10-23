#include "fa/scene/text_fit.h"

#include <algorithm>
#include <cmath>

namespace fa {

namespace {

bool overflows(const TextFitSpec& s, Vec2 size) {
    return (s.boxW > 0 && size.x > s.boxW + 0.5f) || (s.boxH > 0 && size.y > s.boxH + 0.5f);
}

}  // namespace

float effective_text_scale(float textScale, float maxTextScale) {
    return maxTextScale > 0.0f ? std::min(textScale, maxTextScale) : textScale;
}

TextFit fit_text(const TextFitSpec& spec, const std::string& text, const std::string& font, float textScale,
                 const TextExtent& extent) {
    TextFit out;
    if (text.empty() || spec.fontSize <= 0.0f) return out;
    const float k = spec.followsTextScale ? effective_text_scale(textScale, spec.maxTextScale) : 1.0f;
    const float hi = spec.fontSize * k;
    out.px = hi;
    out.size = extent(text, font, hi, spec.wrap);
    out.overflow = overflows(spec, out.size);
    if (!out.overflow || !spec.autoShrink) return out;
    const float lo = std::min(std::max(spec.minFontSize, 1.0f), spec.fontSize) * k;
    if (lo >= hi) return out;
    const Vec2 atLo = extent(text, font, lo, spec.wrap);
    if (overflows(spec, atLo)) {  // it does not fit even at the smallest allowed size: draw it there
        out.px = lo;
        out.size = atLo;
        out.shrunk = true;
        return out;
    }
    float fits = lo, tooBig = hi;
    Vec2 fitsSize = atLo;
    for (int i = 0; i < 10; ++i) {
        const float mid = 0.5f * (fits + tooBig);
        const Vec2 s = extent(text, font, mid, spec.wrap);
        if (overflows(spec, s)) {
            tooBig = mid;
        } else {
            fits = mid;
            fitsSize = s;
        }
    }
    const float snapped = std::max(lo, std::floor(fits * 4.0f) / 4.0f);  // quarter pixels: few distinct raster sizes
    out.px = snapped;
    out.size = snapped == fits ? fitsSize : extent(text, font, snapped, spec.wrap);
    out.overflow = overflows(spec, out.size);
    out.shrunk = true;
    return out;
}

TextFitSpec text_fit_spec(const Text& t) {
    TextFitSpec s;
    s.fontSize = t.fontSize;
    s.minFontSize = t.minFontSize;
    s.autoShrink = t.autoShrink;
    s.maxTextScale = t.maxTextScale;
    s.followsTextScale = t.space == RenderSpace::Screen;
    s.wrap = t.maxWidth;
    s.boxW = t.maxWidth;
    s.boxH = t.maxHeight;
    return s;
}

TextExtent text_extent_of(const VisualMeasure& measure) {
    return [&measure](const std::string& text, const std::string& font, float px, float wrap) {
        Text t;
        t.text = text;
        t.font = font;
        t.fontSize = px;
        t.maxWidth = wrap;
        t.space = RenderSpace::World;  // px is final: no text scale
        return measure.textSize ? measure.textSize(t) : approx_text_size(text, px, wrap);
    };
}

TextExtent approx_text_extent() {
    return [](const std::string& text, const std::string&, float px, float wrap) { return approx_text_size(text, px, wrap); };
}

Vec2 approx_text_size(const Text& t, float textScale) {
    return fit_text(text_fit_spec(t), t.text, t.font, textScale, approx_text_extent()).size;
}

std::optional<UiLabel> ui_label(const World& w, Entity e, const Rect& r) {
    UiLabel l;
    if (const Button* b = w.get<Button>(e)) {
        l.text = &b->text;
        l.font = &b->font;
        l.spec = {b->fontSize, b->minFontSize, b->autoShrink, b->maxTextScale, true, b->maxWidth, 0, 0};
        l.zone = {r.x + 8, r.y + 4, std::max(1.0f, r.w - 16), std::max(1.0f, r.h - 8)};
    } else if (const Toggle* t = w.get<Toggle>(e)) {
        l.text = &t->label;
        l.font = &t->font;
        l.spec = {t->fontSize, t->minFontSize, t->autoShrink, t->maxTextScale, true, t->maxWidth, 0, 0};
        const float side = std::max(0.0f, r.h - 12.0f), x0 = r.x + 6 + side + 10;
        l.zone = {x0, r.y + 2, std::max(1.0f, r.x + r.w - 12 - x0), std::max(1.0f, r.h - 4)};
    } else if (const Slider* s = w.get<Slider>(e)) {
        l.text = &s->label;
        l.font = &s->font;
        l.spec = {s->fontSize, s->minFontSize, s->autoShrink, s->maxTextScale, true, s->maxWidth, 0, 0};
        if (ui_slider_label_above(*s))
            l.zone = {r.x + 8, r.y + 2, std::max(1.0f, r.w - 16), std::max(1.0f, r.h - kUiSliderRowHeight - 2)};
        else
            l.zone = {r.x + 8, r.y + 2, std::max(1.0f, (r.w - 16) * 0.35f - 8), std::max(1.0f, r.h - 4)};
    } else if (const TouchButton* tb = w.get<TouchButton>(e)) {
        l.text = &tb->text;
        l.font = &tb->font;
        l.spec = {tb->fontSize, tb->minFontSize, tb->autoShrink, tb->maxTextScale, true, 0, 0, 0};
        const float side = tb->texture.empty() ? std::min(r.w, r.h) * 0.7f : std::min(r.w, r.h) - 8.0f;  // inside the disc
        l.zone = Rect::from_center(r.center(), {std::max(1.0f, side), std::max(1.0f, side)});
    } else {
        return std::nullopt;
    }
    l.spec.boxW = l.zone.w;
    l.spec.boxH = l.zone.h;
    return l;
}

std::optional<UiLabelFit> ui_label_fit(const World& w, Entity e, const Rect& r, float textScale, const TextExtent& extent) {
    std::optional<UiLabel> l = ui_label(w, e, r);
    if (!l || l->text->empty()) return std::nullopt;
    UiLabelFit out{*l, {}};
    out.fit = fit_text(l->spec, *l->text, *l->font, textScale, extent);
    return out;
}

bool ui_text_overflowed(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure) {
    const TextExtent extent = text_extent_of(measure);
    if (const std::optional<Rect> r = ui_rect(w, e, designSize)) {
        const std::optional<UiLabelFit> f = ui_label_fit(w, e, *r, measure.textScale, extent);
        return f && f->fit.overflow;
    }
    if (const Text* t = w.get<Text>(e))
        return fit_text(text_fit_spec(*t), t->text, t->font, measure.textScale, extent).overflow;
    return false;
}

}  // namespace fa
