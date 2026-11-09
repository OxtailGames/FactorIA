// Text measuring without a GPU: the same fonts, HarfBuzz shaping, bidirectional text, wrapping, rich text and line metrics as
// Text drawing, so `measure_text` gives the same numbers with and without a renderer. The runtime uses it when a run has no
// renderer (--no-graphics, or a machine with no GPU), so UI layout, entity.bounds() and ui.measureText do not depend on
// whether the game is drawn. Renderer::measure_text goes through the very same code (render/src/font_set.h).
#pragma once

#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/rich_text.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/world.h"

namespace fa {

class TextMeasurer {
public:
    TextMeasurer();
    ~TextMeasurer();
    TextMeasurer(const TextMeasurer&) = delete;
    TextMeasurer& operator=(const TextMeasurer&) = delete;

    // Same meaning as Renderer::set_fallback_fonts, set_rich_text_style, set_text_scale and set_ui_scale (renderer.h).
    void set_fallback_fonts(std::vector<std::string> fonts);
    void set_rich_text_style(RichTextStyle style);
    void set_text_scale(float scale);
    void set_ui_scale(float scale);
    float text_scale() const { return textScale_; }
    float ui_scale() const { return uiScale_; }

    // Same meaning as Renderer::measure_text. When the built-in font itself cannot be loaded (a broken build) there is nothing to
    // shape with: the result is approx_text_size (bounds.h) and one warning says so.
    Vec2 measure_text(std::string_view text, float fontSize, std::string_view font = {}, float maxWidth = 0,
                      RenderSpace space = RenderSpace::World, TextStyle style = {}) const;
    Vec2 measure_text(const Text& text) const;

    // The fonts loaded so far: [{font, ok}], like the "fonts" of Renderer::asset_report.
    Json report() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
    float textScale_ = 1.0f, uiScale_ = 1.0f;
    mutable bool warnedApprox_ = false;
};

}  // namespace fa
