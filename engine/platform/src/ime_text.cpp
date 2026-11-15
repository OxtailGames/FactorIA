#include "ime_text.h"

#include <algorithm>

namespace fa::ime_text {

namespace {
bool is_high(char16_t c) { return c >= 0xD800 && c <= 0xDBFF; }
bool is_low(char16_t c) { return c >= 0xDC00 && c <= 0xDFFF; }
// The UTF-16 units the code point that starts at `i` takes (a lone surrogate takes one).
std::size_t cp_units(std::u16string_view t, std::size_t i) {
    return is_high(t[i]) && i + 1 < t.size() && is_low(t[i + 1]) ? 2 : 1;
}
}  // namespace

std::u32string utf16_to_utf32(std::u16string_view text) {
    std::u32string out;
    out.reserve(text.size());
    for (std::size_t i = 0; i < text.size();) {
        const std::size_t n = cp_units(text, i);
        if (n == 2)
            out.push_back(char32_t(0x10000 + ((char32_t(text[i]) - 0xD800) << 10) + (char32_t(text[i + 1]) - 0xDC00)));
        else if (is_high(text[i]) || is_low(text[i]))
            out.push_back(char32_t(0xFFFD));
        else
            out.push_back(char32_t(text[i]));
        i += n;
    }
    return out;
}

CpRange utf16_range_to_cp(std::u16string_view text, std::size_t loc, std::size_t len) {
    loc = std::min(loc, text.size());
    const std::size_t end = len > text.size() - loc ? text.size() : loc + len;
    int start = 0, stop = 0, index = 0;
    for (std::size_t i = 0; i < text.size(); ++index) {
        const std::size_t n = cp_units(text, i);
        if (i + n <= loc) start = index + 1;  // the code point ends at or before the range: the range starts after it
        if (i < end) stop = index + 1;        // it starts before the range's end: the range reaches it
        i += n;
    }
    if (end == loc) stop = start;
    else if (stop < start) stop = start;
    return {start, stop - start};
}

Marked marked_from_utf16(std::u16string_view text, std::size_t selLoc, std::size_t selLen, std::span<const Run> runs) {
    Marked m;
    m.text = utf16_to_utf32(text);
    if (selLen > 0) {
        const CpRange r = utf16_range_to_cp(text, selLoc, selLen);
        m.caret = r.start;
        m.selLength = r.length;
        return m;
    }
    for (const Run& run : runs) {
        if (!run.emphasized || run.length == 0 || run.start >= text.size()) continue;
        const CpRange r = utf16_range_to_cp(text, run.start, run.length);
        m.caret = r.start;
        m.selLength = r.length;
        return m;
    }
    m.caret = utf16_range_to_cp(text, selLoc, 0).start;
    return m;
}

KeyAction decide_key(const KeyOutcome& o) {
    // A key the IME used leaves nothing for the game, so Enter that confirms a conversion does not also submit the field. A
    // command asked while composing (the IME did not want the key) is the game's.
    if (o.consumed || o.composing || (o.wasComposing && !o.command)) return KeyAction::Swallow;
    if (o.plainText && !o.plainTextIsEventText) return KeyAction::GameWithoutText;
    return KeyAction::Game;
}

}  // namespace fa::ime_text
