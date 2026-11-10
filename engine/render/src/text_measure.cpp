// Text measuring that needs no GPU (fa/render/text_measure.h), and the two functions Renderer::measure_text shares with it.
#include "fa/render/text_measure.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "fa/render/renderer.h"
#include "fa/scene/bounds.h"
#include "fa/scene/ui_rect.h"
#include "font_set.h"

namespace fa {

namespace render {

Vec2 measure_plain_text(FontSet& fonts, std::string_view text, float fontSize, std::string_view font, float maxWidth, RenderSpace space,
                        TextStyle style, float textScale, float uiScale) {
    if (text.empty() || fontSize <= 0.0f) return {0, 0};
    Text t;
    t.markup = style.markup;
    t.bold = style.bold;
    t.wordBreak = style.wordBreak;
    t.text = std::string(text);
    t.font = std::string(font);
    t.fontSize = fontSize;
    t.maxWidth = maxWidth;
    // The very layout of Text drawing at entity scale 1 (and of UI labels in screen space). Screen-space text is drawn at the
    // interface scale (ui.scale), rasterized k times as large, so it is measured at that raster size too (the result is in
    // UI units, not multiplied by k).
    const bool screen = space == RenderSpace::Screen;
    return fonts.measure(t, screen ? fontSize * textScale : fontSize, screen ? uiScale : 1.0f).value_or(Vec2{0, 0});
}

Vec2 measure_text_component(FontSet& fonts, const Text& text, float textScale, float uiScale) {
    if (text.text.empty() || text.fontSize <= 0.0f) return {0, 0};
    const bool screen = text.space == RenderSpace::Screen;
    const TextExtent extent = [&fonts, screen, uiScale](const std::string& s, const std::string& font, float px, float wrap, TextStyle style) {
        Text t;
        t.text = s;
        t.font = font;
        t.maxWidth = wrap;
        t.markup = style.markup;
        t.bold = style.bold;
        t.wordBreak = style.wordBreak;
        return fonts.measure(t, px, screen ? uiScale : 1.0f).value_or(Vec2{0, 0});  // px is final: no text scale
    };
    return fit_text(text_fit_spec(text), text.text, text.font, textScale, extent).size;
}

}  // namespace render

struct TextMeasurer::Impl {
    render::FontSet fonts{[](const std::string& font, const std::string& error, const std::string& hint) {
        const bool hinted = hint.empty() || error.find(hint) != std::string::npos;
        FA_ERROR("render", "{}{} (font '{}', text measuring without a renderer)", error, hinted ? std::string() : " Hint: " + hint, font);
    }};
};

TextMeasurer::TextMeasurer() : impl_(std::make_unique<Impl>()) {}
TextMeasurer::~TextMeasurer() = default;

void TextMeasurer::set_fallback_fonts(std::vector<std::string> fonts) { impl_->fonts.set_fallback_fonts(std::move(fonts)); }
void TextMeasurer::set_rich_text_style(RichTextStyle style) { impl_->fonts.set_rich_style(style); }
void TextMeasurer::set_text_scale(float scale) { textScale_ = std::isfinite(scale) ? std::clamp(scale, kMinTextScale, kMaxTextScale) : 1.0f; }
void TextMeasurer::set_ui_scale(float scale) { uiScale_ = std::isfinite(scale) ? std::clamp(scale, kMinUiScale, kMaxUiScale) : 1.0f; }

Vec2 TextMeasurer::measure_text(std::string_view text, float fontSize, std::string_view font, float maxWidth, RenderSpace space,
                                TextStyle style) const {
    if (text.empty() || fontSize <= 0.0f) return {0, 0};
    if (!impl_->fonts.face("")->ok) {  // not even the built-in font loads
        if (!warnedApprox_) {
            warnedApprox_ = true;
            FA_WARN("render", "text measuring: the built-in font cannot be loaded, so text sizes are an approximation (0.6 em per character). "
                              "Hint: this build is broken; reinstall the engine");
        }
        return approx_text_size(std::string(text), space == RenderSpace::Screen ? fontSize * textScale_ : fontSize, maxWidth, style.markup);
    }
    return render::measure_plain_text(impl_->fonts, text, fontSize, font, maxWidth, space, style, textScale_, uiScale_);
}

Vec2 TextMeasurer::measure_text(const Text& text) const {
    if (text.text.empty() || text.fontSize <= 0.0f) return {0, 0};
    if (!impl_->fonts.face("")->ok) {
        if (!warnedApprox_) {
            warnedApprox_ = true;
            FA_WARN("render", "text measuring: the built-in font cannot be loaded, so text sizes are an approximation (0.6 em per character). "
                              "Hint: this build is broken; reinstall the engine");
        }
        return approx_text_size(text, textScale_);
    }
    return render::measure_text_component(impl_->fonts, text, textScale_, uiScale_);
}

Json TextMeasurer::report() const { return impl_->fonts.report(); }

}  // namespace fa
