#include "fa/core/utf8.h"

namespace fa {

char32_t utf8_next(std::string_view text, std::size_t& i) {
    const unsigned char lead = static_cast<unsigned char>(text[i++]);
    if (lead < 0x80) return lead;
    const int extra = lead >= 0xF0 ? (lead <= 0xF4 ? 3 : 0) : lead >= 0xE0 ? 2 : lead >= 0xC2 ? 1 : 0;
    if (extra == 0) return kReplacementChar;  // a continuation byte, or a lead byte that no valid character starts with
    // The second byte has a narrower range after E0, ED, F0 and F4: that rules out overlong forms, surrogates and
    // values above U+10FFFF (Unicode table 3-7).
    unsigned char lo = lead == 0xE0 ? 0xA0 : lead == 0xF0 ? 0x90 : 0x80;
    unsigned char hi = lead == 0xED ? 0x9F : lead == 0xF4 ? 0x8F : 0xBF;
    char32_t cp = lead & (0x3F >> extra);
    for (int k = 0; k < extra; ++k, lo = 0x80, hi = 0xBF) {
        if (i >= text.size()) return kReplacementChar;
        const unsigned char c = static_cast<unsigned char>(text[i]);
        if (c < lo || c > hi) return kReplacementChar;  // the byte is not consumed: it may start the next character
        cp = (cp << 6) | (c & 0x3F);
        ++i;
    }
    return cp;
}

std::u32string utf8_decode(std::string_view text) {
    std::u32string out;
    out.reserve(text.size());
    for (std::size_t i = 0; i < text.size();) out.push_back(utf8_next(text, i));
    return out;
}

std::size_t utf8_length(std::string_view text) {
    std::size_t n = 0;
    for (std::size_t i = 0; i < text.size(); ++n) utf8_next(text, i);
    return n;
}

void utf8_append(std::string& out, char32_t cp) {
    if (cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF)) cp = kReplacementChar;
    if (cp < 0x80) out += char(cp);
    else if (cp < 0x800) out += {char(0xC0 | (cp >> 6)), char(0x80 | (cp & 0x3F))};
    else if (cp < 0x10000) out += {char(0xE0 | (cp >> 12)), char(0x80 | ((cp >> 6) & 0x3F)), char(0x80 | (cp & 0x3F))};
    else out += {char(0xF0 | (cp >> 18)), char(0x80 | ((cp >> 12) & 0x3F)), char(0x80 | ((cp >> 6) & 0x3F)),
                 char(0x80 | (cp & 0x3F))};
}

std::string utf8_encode(char32_t cp) {
    std::string out;
    utf8_append(out, cp);
    return out;
}

std::u16string utf8_to_utf16(std::string_view text) {
    std::u16string out;
    for (std::size_t i = 0; i < text.size();) {
        const char32_t cp = utf8_next(text, i);
        if (cp < 0x10000) out += char16_t(cp);
        else out += {char16_t(0xD800 + ((cp - 0x10000) >> 10)), char16_t(0xDC00 + (cp & 0x3FF))};
    }
    return out;
}

}  // namespace fa
