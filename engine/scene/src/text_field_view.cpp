#include "fa/scene/text_field_view.h"

#include <algorithm>
#include <cmath>

namespace fa {

namespace {

// Byte offset of code point `cp` in `s` (the end when past it).
std::size_t byte_of(const std::string& s, std::int32_t cp) {
    std::size_t i = 0;
    for (std::int32_t n = 0; n < cp && i < s.size(); ++n) utf8_next(s, i);
    return i;
}

std::string masked(std::size_t codePoints) { return std::string(codePoints, '*'); }

// Width of the first `bytes` of `s`. The measure of a text that ends in a space may drop it, so a marker is measured too.
struct Advance {
    const TextFieldMeasure& m;
    float marker;
    explicit Advance(const TextFieldMeasure& measure) : m(measure), marker(measure("|").x) {}
    float of(const std::string& s) const { return s.empty() ? 0.0f : m(s + "|").x - marker; }
};

}  // namespace

TextFieldView text_field_view(const TextField& tf, const Rect& r, const TextFieldMeasure& measure) {
    TextFieldView v;
    v.inner = Rect{r.x + kTextFieldPad, r.y, std::max(0.0f, r.w - 2.0f * kTextFieldPad), r.h};
    const Advance adv(measure);
    const float lineH = measure("|").y;
    v.lineH = lineH;
    v.lineY = r.y + (r.h - lineH) * 0.5f;

    const std::int32_t n = std::int32_t(std::min<std::size_t>(utf8_length(tf.text), 1000000));
    const std::int32_t caret = std::clamp(tf.caretIndex, 0, n);
    const std::size_t at = byte_of(tf.text, caret);
    const std::string before = tf.text.substr(0, at), after = tf.text.substr(at);
    v.composing = !tf.composition.empty();
    v.placeholder = tf.text.empty() && !v.composing;
    if (tf.password) {
        v.display = masked(utf8_length(before) + utf8_length(tf.composition) + utf8_length(after));
    } else {
        v.display = before + tf.composition + after;
    }
    // Byte offsets of the parts inside `display` (a mask is one byte per code point).
    const std::size_t compCp = utf8_length(tf.composition), beforeCp = std::size_t(caret);
    auto offset = [&](std::size_t cpIndex) {  // x of the code point `cpIndex` of `display`, from its start
        if (tf.password) return adv.of(masked(cpIndex));
        return adv.of(v.display.substr(0, byte_of(v.display, std::int32_t(cpIndex))));
    };
    const float total = v.placeholder ? 0.0f : adv.of(v.display);
    float caretAbs = offset(beforeCp);
    if (v.composing) {
        const std::int32_t cc = std::clamp(tf.compositionCaret, 0, std::int32_t(compCp));
        caretAbs = offset(beforeCp + std::size_t(cc));
    }
    // Scroll: as little as keeps the caret in view; a text that fits is not scrolled.
    const float room = std::max(0.0f, v.inner.w), most = std::max(0.0f, total + kTextFieldCaretWidth - room);
    float s = std::clamp(tf.scrollX, 0.0f, most);
    if (caretAbs - s > room - kTextFieldCaretWidth) s = caretAbs - room + kTextFieldCaretWidth;
    if (caretAbs < s) s = caretAbs;
    v.scroll = v.placeholder ? 0.0f : std::clamp(s, 0.0f, most);
    v.textX = v.inner.x - v.scroll;
    v.caretX = v.textX + caretAbs;
    if (v.composing) {
        v.compX0 = v.textX + offset(beforeCp);
        v.compX1 = v.textX + offset(beforeCp + compCp);
        if (tf.compositionSelection > 0) {
            const std::int32_t a = std::clamp(tf.compositionCaret, 0, std::int32_t(compCp));
            const std::int32_t b = std::min(a + tf.compositionSelection, std::int32_t(compCp));
            v.clauseX0 = v.textX + offset(beforeCp + std::size_t(a));
            v.clauseX1 = v.textX + offset(beforeCp + std::size_t(b));
        }
    } else if (tf.selectionStart != tf.selectionEnd) {
        const std::int32_t a = std::clamp(std::min(tf.selectionStart, tf.selectionEnd), 0, n);
        const std::int32_t b = std::clamp(std::max(tf.selectionStart, tf.selectionEnd), 0, n);
        v.hasSelection = a != b;
        v.selX0 = v.textX + offset(std::size_t(a));
        v.selX1 = v.textX + offset(std::size_t(b));
    }
    return v;
}

std::int32_t text_field_index_at(const TextField& tf, const Rect& r, const TextFieldMeasure& measure, float x) {
    TextField plain = tf;
    plain.composition.clear();  // a click lands on the text, not on what is being composed
    const TextFieldView v = text_field_view(plain, r, measure);
    const Advance adv(measure);
    const std::int32_t n = std::int32_t(std::min<std::size_t>(utf8_length(tf.text), 1000000));
    const float rel = x - v.textX;
    auto at = [&](std::int32_t i) {
        return tf.password ? adv.of(masked(std::size_t(i))) : adv.of(tf.text.substr(0, byte_of(tf.text, i)));
    };
    if (rel <= 0.0f) return 0;
    // The first index whose edge is at or after the click, then the nearer of it and the one before it.
    std::int32_t lo = 0, hi = n;
    while (lo < hi) {
        const std::int32_t mid = lo + (hi - lo) / 2;
        if (at(mid) < rel)
            lo = mid + 1;
        else
            hi = mid;
    }
    if (lo > 0 && rel - at(lo - 1) < at(lo) - rel) --lo;
    return lo;
}

}  // namespace fa
