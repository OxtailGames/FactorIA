// Text that fits: the ONE place that decides at which size a text is drawn and measured, and whether it still does not
// fit. Screen-space Text, the labels of Button, Toggle, Slider and TouchButton, layout, autoSize, `ui.measureText`,
// `ui.overflowed`, the renderer and `ui.state` all go through here, so what a script measures is what is drawn.
//
// The effective font size, in pixels, is   fontSize * min(ui.textScale, maxTextScale)   (no cap when maxTextScale is 0),
// then, with autoShrink, reduced until the laid-out text fits its box, never below   minFontSize * min(ui.textScale,
// maxTextScale)   (minFontSize is in the same unit as fontSize, before the player's text size). A text that still does not
// fit at that size is `overflow`: it is drawn there (cut or sticking out, as before) and `ui.overflowed(id)` says true.
#pragma once

#include <functional>
#include <optional>
#include <string>

#include "fa/core/math.h"
#include "fa/scene/bounds.h"
#include "fa/scene/ui_rect.h"

namespace fa {

// Size {w, h} of `text` laid out with `font` ("" = built-in) at the font size `px` (final pixels, no text scale applied),
// wrapped at `wrap` (> 0). The renderer's layout, or approx_text_size without one.
using TextExtent = std::function<Vec2(const std::string& text, const std::string& font, float px, float wrap)>;

// The text scale that applies to a text with this cap: min(textScale, maxTextScale), or textScale when maxTextScale <= 0.
float effective_text_scale(float textScale, float maxTextScale);

// What fit_text needs to know about a text and its box.
struct TextFitSpec {
    float fontSize = 24.0f;       // design pixels, before the text scale
    float minFontSize = 0.0f;     // autoShrink floor, same unit as fontSize
    bool autoShrink = false;
    float maxTextScale = 0.0f;    // 0 = no cap
    bool followsTextScale = true; // false: world-space Text, which ui.textScale does not touch
    float wrap = 0.0f;            // > 0 wraps lines at this width (design pixels)
    float boxW = 0.0f, boxH = 0.0f;  // the box the text must fit, 0 = that axis is not checked
};

struct TextFit {
    float px = 0.0f;              // the effective font size to lay the text out at
    Vec2 size{0, 0};              // the laid-out size at px
    bool overflow = false;        // still wider or taller than the box at px
    bool shrunk = false;          // autoShrink made px smaller than fontSize * scale
};

// Decides the size of `text`. Deterministic: a bisection with a fixed number of steps, rounded down to a quarter pixel.
TextFit fit_text(const TextFitSpec& spec, const std::string& text, const std::string& font, float textScale,
                 const TextExtent& extent);

// The spec of a Text component: its box is maxWidth x maxHeight.
TextFitSpec text_fit_spec(const Text& t);

// A TextExtent that lays text out through VisualMeasure::textSize (a world-space Text of that size, so no text scale).
TextExtent text_extent_of(const VisualMeasure& measure);
// A TextExtent that measures with approx_text_size (no renderer).
TextExtent approx_text_extent();

// The label of a widget and the room it has inside the widget's rectangle `r` (see ui_rect.h).
struct UiLabel {
    const std::string* text = nullptr;
    const std::string* font = nullptr;
    TextFitSpec spec;             // box = the zone
    Rect zone;                    // where the label sits: Button margins, right of a Toggle's box, a Slider's label zone...
};
// nullopt for a widget without a label (Panel, ScrollList, TextField, TouchStick, Captions).
std::optional<UiLabel> ui_label(const World& w, Entity e, const Rect& r);

struct UiLabelFit {
    UiLabel label;
    TextFit fit;
};
// ui_label + fit_text; what the renderer draws and `ui.overflowed(id)` reports. nullopt when there is no label or it is empty.
std::optional<UiLabelFit> ui_label_fit(const World& w, Entity e, const Rect& r, float textScale, const TextExtent& extent);

// True when the text of `e` (a Text with a box, or a widget label) still does not fit at its effective size.
bool ui_text_overflowed(const World& w, Entity e, Vec2 designSize, const VisualMeasure& measure);

}  // namespace fa
