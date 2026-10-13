#include <doctest.h>

#include "fa/core/json.h"

using namespace fa;

TEST_CASE("json: parse errors carry source, line, column and a hint") {
    auto r = parse_json("{\n  \"a\": 1,\n  \"b\": [1, 2,]\n}", "scenes/x.scene.json");
    REQUIRE(!r.ok());
    CHECK(r.error().message.find("scenes/x.scene.json:3:") == 0);
    CHECK(r.error().message.find("invalid JSON") != std::string::npos);
    CHECK(r.error().hint.find("trailing comma") != std::string::npos);

    auto r2 = parse_json("{'a': 1}", "q");
    REQUIRE(!r2.ok());
    CHECK(r2.error().message.find("q:1:") == 0);
    CHECK(r2.error().hint.find("double quotes") != std::string::npos);

    auto r3 = parse_json("{\"a\": 1", "trunc");
    REQUIRE(!r3.ok());
    CHECK(r3.error().hint.find("ends too early") != std::string::npos);

    auto ok = parse_json("{\"a\": [1, 2]}");
    REQUIRE(ok.ok());
    CHECK(ok.value()["a"].size() == 2);
}

TEST_CASE("json: vectors accept several spellings") {
    std::string err;
    Vec2 v2;
    CHECK(json_to(Json::parse("[1, 2]"), v2, &err));
    CHECK(v2 == Vec2{1, 2});
    CHECK(json_to(Json::parse("{\"x\": 3, \"y\": 4}"), v2, &err));
    CHECK(v2 == Vec2{3, 4});
    CHECK(!json_to(Json::parse("[1]"), v2, &err));
    CHECK(err.find("expected [x, y]") != std::string::npos);

    Vec3 v3;
    CHECK(json_to(Json::parse("[1, 2]"), v3, &err));  // z defaults to 0
    CHECK(v3 == Vec3{1, 2, 0});
    CHECK(json_to(Json::parse("{\"x\":1,\"y\":2,\"z\":3}"), v3, &err));
    CHECK(v3 == Vec3{1, 2, 3});
    CHECK(!json_to(Json::parse("\"abc\""), v3, &err));
    CHECK(err.find("got string \"abc\"") != std::string::npos);
    CHECK(!json_to(Json::parse("{\"x\":1,\"q\":2}"), v3, &err));
    CHECK(err.find("unknown key 'q'") != std::string::npos);

    Vec4 v4;
    CHECK(json_to(Json::parse("[1,2,3,4]"), v4, &err));
    CHECK(v4.w == 4);
    CHECK(!json_to(Json::parse("[1,2,3]"), v4, &err));

    Rect r;
    CHECK(json_to(Json::parse("{\"x\":1,\"y\":2,\"w\":3,\"h\":4}"), r, &err));
    CHECK(r == Rect{1, 2, 3, 4});
}

TEST_CASE("json: scalars") {
    std::string err;
    int i;
    CHECK(json_to(Json::parse("3"), i, &err));
    CHECK(i == 3);
    CHECK(json_to(Json::parse("4.0"), i, &err));
    CHECK(i == 4);
    CHECK(!json_to(Json::parse("4.5"), i, &err));
    CHECK(err.find("integer") != std::string::npos);
    float f;
    CHECK(json_to(Json::parse("2"), f, &err));
    CHECK(f == 2.0f);
    CHECK(!json_to(Json::parse("\"x\""), f, &err));
    bool b;
    CHECK(!json_to(Json::parse("1"), b, &err));
    std::string s;
    CHECK(!json_to(Json::parse("5"), s, &err));
}

TEST_CASE("json: colors") {
    std::string err;
    Color c;
    CHECK(json_to(Json::parse("[1, 0.5, 0]"), c, &err));
    CHECK(c == Color{1, 0.5f, 0, 1});
    CHECK(json_to(Json::parse("[0.1, 0.2, 0.3, 0.4]"), c, &err));
    CHECK(c.a == doctest::Approx(0.4f));
    CHECK(json_to(Json::parse("[255, 128, 0]"), c, &err));  // any component > 1 -> bytes
    CHECK(c.r == doctest::Approx(1.0f));
    CHECK(c.g == doctest::Approx(128 / 255.0f));
    CHECK(c.a == doctest::Approx(1.0f));
    CHECK(json_to(Json::parse("[255, 0, 0, 128]"), c, &err));
    CHECK(c.a == doctest::Approx(128 / 255.0f));
    CHECK(json_to(Json::parse("\"#f00\""), c, &err));
    CHECK(c == Color{1, 0, 0, 1});
    CHECK(json_to(Json::parse("\"#00ff00\""), c, &err));
    CHECK(c == Color{0, 1, 0, 1});
    CHECK(json_to(Json::parse("\"#0000ff80\""), c, &err));
    CHECK(c.b == 1.0f);
    CHECK(c.a == doctest::Approx(128 / 255.0f));
    for (auto n : color_names()) {
        CHECK(parse_color(n, c));
        CHECK(parse_color(std::string(n) + "", c));
    }
    CHECK(json_to(Json::parse("\"RED\""), c, &err));
    CHECK(c == Color::red());
    CHECK(json_to(Json::parse("\"transparent\""), c, &err));
    CHECK(c.a == 0.0f);
    CHECK(color_names().size() >= 15);  // grows as AI-friendly names are added

    CHECK(!json_to(Json::parse("\"rde\""), c, &err));
    CHECK(err.find("Did you mean 'red'") != std::string::npos);
    CHECK(!json_to(Json::parse("\"#12\""), c, &err));
    CHECK(!json_to(Json::parse("[1,2]"), c, &err));
    CHECK(!json_to(Json::parse("5"), c, &err));
}

TEST_CASE("json: writers round floats to 4 decimals") {
    CHECK(to_json(Vec3{0.1f, 1.0f / 3.0f, 2}).dump() == "[0.1,0.3333,2.0]");
    CHECK(to_json(Color{0.2f, 0.4f, 0.6f, 1.0f}).dump() == "[0.2,0.4,0.6,1.0]");
    CHECK(to_json(0.12345678f).dump() == "0.1235");
    CHECK(to_json(Vec2{1, 2}).dump() == "[1.0,2.0]");
    CHECK(to_json(Rect{1, 2, 3, 4}).size() == 4);
}

TEST_CASE("json: json_at and json_merge") {
    Json j = Json::parse(R"({"entities":[{"name":"a"},{"name":"b"}],"x":{"y/z":1}})");
    REQUIRE(json_at(j, "/entities/1/name") != nullptr);
    CHECK(*json_at(j, "/entities/1/name") == "b");
    CHECK(json_at(j, "/entities/5") == nullptr);
    CHECK(json_at(j, "/nope") == nullptr);
    CHECK(json_at(j, "bad pointer") == nullptr);
    CHECK(json_at(j, "") == &j);
    CHECK(*json_at(j, "/x/y~1z") == 1);

    Json target = Json::parse(R"({"a":{"b":1,"c":2},"d":[1,2]})");
    json_merge(target, Json::parse(R"({"a":{"b":9},"d":[3],"e":true})"));
    CHECK(target["a"]["b"] == 9);
    CHECK(target["a"]["c"] == 2);
    CHECK(target["d"].size() == 1);
    CHECK(target["e"] == true);
}

TEST_CASE("json: key order is preserved") {
    Json j = Json::object();
    j["zeta"] = 1;
    j["alpha"] = 2;
    CHECK(j.dump() == "{\"zeta\":1,\"alpha\":2}");
    CHECK(dump_json(j).back() == '\n');
}
