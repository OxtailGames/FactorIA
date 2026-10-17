#include <doctest.h>

#include "fa/core/utf8.h"

using namespace fa;

namespace {
constexpr char32_t R = kReplacementChar;
}

TEST_CASE("utf8: one to four bytes, both ways") {
    CHECK(utf8_decode("a\xC3\xA9\xE2\x82\xAC\xF0\x9F\x98\x80") == U"a\u00E9\u20AC\U0001F600");
    CHECK(utf8_length("a\xC3\xA9\xE2\x82\xAC\xF0\x9F\x98\x80") == 4);
    CHECK(utf8_decode("").empty());
    for (char32_t cp : {0x0u, 0x7Fu, 0x80u, 0x7FFu, 0x800u, 0xD7FFu, 0xE000u, 0xFFFDu, 0xFFFFu, 0x10000u, 0x10FFFFu}) {
        CAPTURE(unsigned(cp));
        const std::string s = utf8_encode(cp);
        CHECK(s.size() == (cp < 0x80 ? 1u : cp < 0x800 ? 2u : cp < 0x10000 ? 3u : 4u));
        CHECK(utf8_decode(s) == std::u32string(1, cp));
    }
    std::string out = "x";
    utf8_append(out, 0x65E5);
    CHECK(out == "x\xE6\x97\xA5");
}

TEST_CASE("utf8: utf8_next moves past one character") {
    const std::string_view s = "\xE6\x97\xA5" "b";
    std::size_t i = 0;
    CHECK(utf8_next(s, i) == 0x65E5);
    CHECK(i == 3);
    CHECK(utf8_next(s, i) == U'b');
    CHECK(i == 4);
}

TEST_CASE("utf8: malformed bytes become U+FFFD, one per maximal ill-formed subsequence") {
    CHECK(utf8_decode("\x80") == std::u32string{R});  // a continuation byte alone
    CHECK(utf8_decode("a\xFF" "b") == std::u32string{U'a', R, U'b'});  // never a UTF-8 byte
    CHECK(utf8_decode("\xE2\x82") == std::u32string{R});  // cut short: one U+FFFD for both bytes
    CHECK(utf8_decode("\xF0\x9F\x98") == std::u32string{R});
    CHECK(utf8_decode("\xE2\x82" "A") == std::u32string{R, U'A'});  // the byte that broke the sequence is kept
    std::size_t i = 0;
    CHECK(utf8_next("\xC3" "A", i) == R);
    CHECK(i == 1);
    // The example of the Unicode standard, table 3-8.
    CHECK(utf8_decode("\x61\xF1\x80\x80\xE1\x80\xC2\x62\x80\x63\x80\xBF\x64") ==
          std::u32string{U'a', R, R, R, U'b', R, U'c', R, R, U'd'});
    CHECK(utf8_length("\x61\xF1\x80\x80\xE1\x80\xC2\x62\x80\x63\x80\xBF\x64") == 10);
}

TEST_CASE("utf8: overlong forms, surrogates and values above U+10FFFF are malformed") {
    CHECK(utf8_decode("\xC0\x80") == std::u32string{R, R});  // NUL in two bytes
    CHECK(utf8_decode("\xC1\xBF") == std::u32string{R, R});
    CHECK(utf8_decode("\xE0\x80\xAF") == std::u32string{R, R, R});  // '/' in three bytes
    CHECK(utf8_decode("\xE0\x9F\xBF") == std::u32string{R, R, R});  // U+07FF in three bytes
    CHECK(utf8_decode("\xF0\x80\x80\x80") == std::u32string{R, R, R, R});
    CHECK(utf8_decode("\xF0\x8F\xBF\xBF") == std::u32string{R, R, R, R});  // U+FFFF in four bytes
    CHECK(utf8_decode("\xED\xA0\x80") == std::u32string{R, R, R});  // U+D800
    CHECK(utf8_decode("\xED\xBF\xBF") == std::u32string{R, R, R});  // U+DFFF
    CHECK(utf8_decode("\xED\x9F\xBF") == U"\uD7FF");  // the last code point before them
    CHECK(utf8_decode("\xF4\x90\x80\x80") == std::u32string{R, R, R, R});  // U+110000
    CHECK(utf8_decode("\xF5\x80\x80\x80") == std::u32string{R, R, R, R});
    CHECK(utf8_decode("\xF4\x8F\xBF\xBF") == U"\U0010FFFF");
    // Encoding never writes them either.
    CHECK(utf8_encode(0xD800) == "\xEF\xBF\xBD");
    CHECK(utf8_encode(0xDFFF) == "\xEF\xBF\xBD");
    CHECK(utf8_encode(0x110000) == "\xEF\xBF\xBD");
}

TEST_CASE("utf8: to UTF-16") {
    CHECK(utf8_to_utf16("a\xE2\x82\xAC\xF0\x9F\x98\x80") == u"a\u20AC\U0001F600");
    CHECK(utf8_to_utf16("a\xF0\x9F\x98\x80") == std::u16string{u'a', 0xD83D, 0xDE00});
    CHECK(utf8_to_utf16("\xF4\x8F\xBF\xBF") == std::u16string{0xDBFF, 0xDFFF});
    CHECK(utf8_to_utf16("\xFF") == u"\uFFFD");
}
