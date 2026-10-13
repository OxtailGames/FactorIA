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
