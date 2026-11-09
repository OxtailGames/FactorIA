#include <doctest.h>

#include "fa/core/strings.h"

using namespace fa;

TEST_CASE("strings: basic helpers") {
    CHECK(to_lower("AbC") == "abc");
    CHECK(iequals("Sprite", "sPRITE"));
    CHECK(!iequals("a", "ab"));
    CHECK(starts_with("assets/x.png", "assets/"));
    CHECK(ends_with("a.png", ".png"));
    CHECK(trim("  hi \n") == "hi");
    CHECK(replace_all("a-b-c", "-", "::") == "a::b::c");
    auto parts = split("a,,b,c", ',');
    REQUIRE(parts.size() == 3);
    CHECK(parts[2] == "c");
    CHECK(split("a,,b", ',', false).size() == 3);
    CHECK(join(parts, "+") == "a+b+c");
}

TEST_CASE("strings: edit distance and suggestions") {
    CHECK(edit_distance("kitten", "sitting") == 3);
    CHECK(edit_distance("Sprite", "sprite") == 0);
    std::vector<std::string> names = {"Sprite", "Transform", "Camera", "RigidBody2D"};
    CHECK(closest_match("Sprit", names) == "Sprite");
    CHECK(closest_match("transfrom", names) == "Transform");
    CHECK(closest_match("Banana", names).empty());
    std::string msg = did_you_mean("Camra", names);
    CHECK(msg.find("Did you mean 'Camera'?") != std::string::npos);
    CHECK(msg.find("Valid: Sprite, Transform") != std::string::npos);
    CHECK(did_you_mean("zzzzzz", names).find("Did you mean") == std::string::npos);
}

TEST_CASE("strings: base64") {
    CHECK(base64_encode("", 0) == "");
    CHECK(base64_encode("f", 1) == "Zg==");
    CHECK(base64_encode("fo", 2) == "Zm8=");
    CHECK(base64_encode("foo", 3) == "Zm9v");
    CHECK(base64_encode("foobar", 6) == "Zm9vYmFy");
    auto d = base64_decode("Zm9vYmE=");
    CHECK(std::string(d.begin(), d.end()) == "fooba");
    std::vector<unsigned char> bin = {0, 255, 1, 254, 128};
    auto rt = base64_decode(base64_encode(bin.data(), bin.size()));
    CHECK(rt == bin);
}

TEST_CASE("glob_match: * and ? stay in a folder, ** crosses folders") {
    CHECK(glob_match("tests/*.test.js", "tests/a.test.js"));
    CHECK_FALSE(glob_match("tests/*.test.js", "tests/ui/a.test.js"));
    CHECK(glob_match("tests/**/*.test.js", "tests/ui/deep/a.test.js"));
    CHECK(glob_match("tests/**/*.test.js", "tests/a.test.js"));
    CHECK(glob_match("**/a?.test.js", "tests/ui/ab.test.js"));
    CHECK_FALSE(glob_match("tests/a?.test.js", "tests/a.test.js"));
    CHECK(glob_match("store/**", "store/a/b.png"));
    CHECK_FALSE(glob_match("store/*", "store/a/b.png"));
}

#include "fa/core/compress.h"

TEST_CASE("zlib_compress and zlib_decompress round-trip, and shrink repeated text") {
    std::string text;
    for (int i = 0; i < 200; ++i) text += "{\"id\":\"villager_" + std::to_string(i) + "\",\"job\":\"baker\"},";
    const std::string z = fa::zlib_compress(text);
    CHECK(!z.empty());
    CHECK(z.size() < text.size() / 3);
    CHECK(fa::zlib_compress(text) == z);  // deterministic
    auto back = fa::zlib_decompress(z, text.size());
    REQUIRE(back.ok());
    CHECK(back.value() == text);
    auto guessed = fa::zlib_decompress(z);
    REQUIRE(guessed.ok());
    CHECK(guessed.value() == text);
    CHECK(!fa::zlib_decompress(z.substr(0, z.size() / 2)).ok());
    CHECK(!fa::zlib_decompress("not a zlib stream").ok());
}

TEST_CASE("strings: is_valid_utf8 accepts well-formed UTF-8 only") {
    CHECK(is_valid_utf8(""));
    CHECK(is_valid_utf8("plain ascii"));
    CHECK(is_valid_utf8("Ca\xc3\xb1\xc3\xb3n \xe2\x82\xac \xf0\x9f\x98\x80"));  // Cañón € and an emoji
    CHECK_FALSE(is_valid_utf8("Ca\xf1\xf3n"));                                 // "Cañón" in Windows-1252
    CHECK_FALSE(is_valid_utf8("\xc3"));                                        // cut short
    CHECK_FALSE(is_valid_utf8("\xe2\x82"));                                    // cut short
    CHECK_FALSE(is_valid_utf8("\x80"));                                        // a continuation byte alone
    CHECK_FALSE(is_valid_utf8("\xc0\x80"));                                    // overlong
    CHECK_FALSE(is_valid_utf8("\xe0\x80\x80"));                                // overlong
    CHECK_FALSE(is_valid_utf8("\xed\xa0\x80"));                                // a surrogate
    CHECK_FALSE(is_valid_utf8("\xf4\x90\x80\x80"));                            // beyond U+10FFFF
}
