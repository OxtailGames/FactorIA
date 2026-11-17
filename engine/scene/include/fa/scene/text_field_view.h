// Where the parts of a TextField are: the ONE definition behind drawing (fa_render), the caret rectangle handed to the IME and
// the pointer hit test (fa_ui). Everything is in UI UNITS (ui_rect.h), in the coordinates of the `rect` given, and measures
// text with the callback the caller has for its label font, so the UI and the renderer agree to the pixel.
#pragma once

#include <functional>
#include <string>

#include "fa/core/math.h"
#include "fa/scene/components.h"

namespace fa {

// Size {w, h} of `s` drawn in the field's font and size (UI units). Called with non-empty strings.
using TextFieldMeasure = std::function<Vec2(const std::string& s)>;

constexpr float kTextFieldPad =
    12.0f;  // the text starts this far inside the field's left edge, and stops this far from the right
constexpr float kTextFieldCaretWidth = 2.0f;

struct TextFieldView {
    Rect inner;  // where the text is visible (the clip)
    std::string
        display;  // what is drawn: text with the composition at the caret, every character a '*' in a password field
    bool placeholder = false;          // text and composition are empty: the placeholder is drawn instead of `display`
    float textX = 0.0f;                // x of the first character of `display` (inner.x - scroll)
    float lineY = 0.0f, lineH = 0.0f;  // the text line, centred in the field
    float scroll = 0.0f;               // how far the text is scrolled left: store it in TextField::scrollX
    float caretX = 0.0f;               // x of the caret (inside the composition while composing)
    bool hasSelection = false;         // selectionStart != selectionEnd and not composing
    float selX0 = 0.0f, selX1 = 0.0f;
    bool composing = false;                  // `composition` is not empty
    float compX0 = 0.0f, compX1 = 0.0f;      // the composition's extent
    float clauseX0 = 0.0f, clauseX1 = 0.0f;  // the part the IME is converting (empty when compositionSelection == 0)
};

// Lays the field out. `scroll` starts from tf.scrollX and is moved the least that keeps the caret inside `inner`.
TextFieldView text_field_view(const TextField& tf, const Rect& rect, const TextFieldMeasure& measure);
// The code point index of `text` nearest to x (same coordinates as the view), for a click or a drag.
std::int32_t text_field_index_at(const TextField& tf, const Rect& rect, const TextFieldMeasure& measure, float x);
// The code point index of the character whose box holds x (0 left of the text, the last one right of it), for a
// double click.
std::int32_t text_field_char_at(const TextField& tf, const Rect& rect, const TextFieldMeasure& measure, float x);

}  // namespace fa
