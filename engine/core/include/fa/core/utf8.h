// UTF-8 to code points and back, for every module that looks at the characters of a text.
//
// Malformed input never fails: each maximal ill-formed subsequence becomes one U+FFFD, as the Unicode standard
// recommends (section 3.9). Overlong forms ("\xC0\x80"), surrogates (U+D800..U+DFFF) and values above U+10FFFF are
// ill-formed.
#pragma once

#include <cstddef>
#include <string>
#include <string_view>

namespace fa {

inline constexpr char32_t kReplacementChar = 0xFFFD;

// The code point that starts at byte `i` of `text` (`i < text.size()`); moves `i` past it, or past the bytes that make
// one U+FFFD.
char32_t utf8_next(std::string_view text, std::size_t& i);
std::u32string utf8_decode(std::string_view text);
// Number of code points, counted as utf8_decode counts them.
std::size_t utf8_length(std::string_view text);

// Appends `cp` as UTF-8; a surrogate or a value above U+10FFFF appends U+FFFD, so the result is always valid UTF-8.
void utf8_append(std::string& out, char32_t cp);
std::string utf8_encode(char32_t cp);

// UTF-16 code units of `text` (Windows resources, Java escapes); code points above U+FFFF become surrogate pairs.
std::u16string utf8_to_utf16(std::string_view text);

}  // namespace fa
