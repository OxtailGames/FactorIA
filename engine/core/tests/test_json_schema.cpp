#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <thread>
#include <vector>

#include "fa/core/json_schema.h"

using namespace fa;

static std::vector<SchemaError> check(const char* schema, const char* value) {
    return validate_json(Json::parse(schema), Json::parse(value));
}

TEST_CASE("schema: types") {
    CHECK(check(R"({"type":"integer"})", "3").empty());
    CHECK(check(R"({"type":"integer"})", "3.0").empty());
    CHECK(!check(R"({"type":"integer"})", "3.5").empty());
    CHECK(check(R"({"type":"number"})", "3.5").empty());
    CHECK(check(R"({"type":["string","null"]})", "null").empty());
    auto e = check(R"({"type":"string"})", "5");
    REQUIRE(e.size() == 1);
    CHECK(e[0].pointer.empty());
    CHECK(e[0].message == "expected string, got integer");
    CHECK(e[0].to_string().find("(root): expected string") == 0);
}

TEST_CASE("schema: objects, pointers and required") {
    const char* schema = R"({
        "type":"object",
        "properties":{
            "name":{"type":"string","description":"Entity name."},
            "pos":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":3},
            "child":{"type":"object","properties":{"hp":{"type":"integer","minimum":0,"maximum":10}}}
        },
        "required":["name"],
        "additionalProperties":false})";
    CHECK(check(schema, R"({"name":"a","pos":[1,2]})").empty());

    auto e = check(schema, R"({"nmae":"a"})");
    REQUIRE(e.size() == 2);
    bool missing = false, unknown = false;
    for (auto& x : e) {
        if (x.message == "missing required property 'name'") {
            missing = true;
            CHECK(x.hint.find("Entity name.") != std::string::npos);
            CHECK(x.hint.find("did you mean 'name'") != std::string::npos);
        }
        if (x.pointer == "/nmae") {
            unknown = true;
            CHECK(x.hint.find("Did you mean 'name'") != std::string::npos);
        }
    }
    CHECK(missing);
    CHECK(unknown);

    auto deep = check(schema, R"({"name":"a","pos":[1,"x"],"child":{"hp":11}})");
    REQUIRE(deep.size() == 2);
    CHECK(deep[0].pointer == "/pos/1");
    CHECK(deep[1].pointer == "/child/hp");
    CHECK(deep[1].message.find("above the maximum 10") != std::string::npos);
    CHECK(check(schema, R"({"name":"a","pos":[1]})")[0].message.find("minimum is 2") != std::string::npos);
}

TEST_CASE("schema: enum, const, pattern, length") {
    auto e = check(R"({"enum":["circle","square"]})", "\"cirle\"");
    REQUIRE(e.size() == 1);
    CHECK(e[0].hint.find("Did you mean 'circle'") != std::string::npos);
    CHECK(check(R"({"enum":[1,2]})", "3").size() == 1);
    CHECK(check(R"({"const":"a"})", "\"a\"").empty());
    CHECK(!check(R"({"const":"a"})", "\"b\"").empty());
    CHECK(check(R"({"type":"string","pattern":"^[a-z_]+$"})", "\"ab_c\"").empty());
    CHECK(!check(R"({"type":"string","pattern":"^[a-z_]+$"})", "\"AB\"").empty());
    CHECK(!check(R"({"type":"string","minLength":3})", "\"ab\"").empty());
}

TEST_CASE("schema: anyOf / oneOf") {
    const char* color = R"({"anyOf":[{"type":"array","items":{"type":"number"},"minItems":3},{"type":"string"}]})";
    CHECK(check(color, "[1,0,0]").empty());
    CHECK(check(color, "\"red\"").empty());
    auto e = check(color, "5");
    REQUIRE(e.size() == 1);
    CHECK(e[0].message == "expected array or string, got integer");
    auto short_arr = check(color, "[1,0]");
    REQUIRE(short_arr.size() == 1);
    CHECK(short_arr[0].message.find("minimum is 3") != std::string::npos);
    CHECK(check(R"({"oneOf":[{"type":"integer"},{"type":"number"}]})", "1").size() == 1);  // matches both
    CHECK(check(R"({"oneOf":[{"type":"integer"},{"type":"string"}]})", "1").empty());
}

TEST_CASE("schema: $ref and additionalProperties schema") {
    const char* schema = R"({
        "type":"object",
        "$defs":{"Vec":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2}},
        "properties":{"a":{"$ref":"#/$defs/Vec"}},
        "additionalProperties":{"type":"integer"}})";
    CHECK(check(schema, R"({"a":[1,2],"x":3})").empty());
    auto e = check(schema, R"({"a":[1],"x":"s"})");
    REQUIRE(e.size() == 2);
    CHECK(e[0].pointer == "/a");
    CHECK(e[1].pointer == "/x");
    auto bad = check(R"({"$ref":"#/$defs/Nope"})", "1");
    REQUIRE(bad.size() == 1);
    CHECK(bad[0].message.find("cannot resolve") != std::string::npos);
}

TEST_CASE("schema: pointer escaping and defaults") {
    auto e = check(R"({"type":"object","properties":{"a/b":{"type":"string"}}})", R"({"a/b":1})");
    REQUIRE(e.size() == 1);
    CHECK(e[0].pointer == "/a~1b");

    Json schema = Json::parse(R"({
        "type":"object",
        "properties":{
            "count":{"type":"integer","default":5},
            "opts":{"type":"object","properties":{"deep":{"default":true}}},
            "list":{"type":"array","items":{"type":"object","properties":{"k":{"default":"v"}}}}}})");
    Json v = Json::parse(R"({"opts":{},"list":[{},{"k":"x"}]})");
    apply_schema_defaults(schema, v);
    CHECK(v["count"] == 5);
    CHECK(v["opts"]["deep"] == true);
    CHECK(v["list"][0]["k"] == "v");
    CHECK(v["list"][1]["k"] == "x");
}

TEST_CASE("schema: a pattern is compiled once and validation from several threads agrees") {
    const Json schema = Json::parse(R"({"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z_]+[0-9]*$"}}})");
    std::atomic<int> wrong{0};
    std::vector<std::thread> threads;
    for (int t = 0; t < 4; ++t)
        threads.emplace_back([&] {
            for (int i = 0; i < 200; ++i) {
                if (!validate_json(schema, Json::parse(R"({"id":"coin_3"})")).empty()) ++wrong;
                auto bad = validate_json(schema, Json::parse(R"({"id":"Coin 3"})"));
                if (bad.size() != 1 || bad[0].pointer != "/id") ++wrong;
            }
        });
    for (auto& th : threads) th.join();
    CHECK(wrong == 0);
}

TEST_CASE("schema: many different patterns keep giving the right answer (the cache starts over when full)") {
    for (int i = 0; i < 1500; ++i) {
        Json schema = Json::object({{"type", "string"}, {"pattern", "^p" + std::to_string(i) + "$"}});
        CHECK(validate_json(schema, Json("p" + std::to_string(i))).empty());
        CHECK(validate_json(schema, Json("q" + std::to_string(i))).size() == 1);
    }
}

TEST_CASE("schema: an invalid pattern is a teaching error, in the validation and when the schema is checked") {
    auto e = check(R"({"type":"string","pattern":"([a-z"})", "\"abc\"");
    REQUIRE(e.size() == 1);
    CHECK(e[0].message.find("invalid pattern") != std::string::npos);
    CHECK_FALSE(e[0].hint.empty());
    // The same answer the second time (the failure is cached too).
    CHECK(check(R"({"type":"string","pattern":"([a-z"})", "\"abc\"").size() == 1);

    auto bad = check_schema_patterns(Json::parse(R"({"type":"object","properties":{
        "ok":{"type":"string","pattern":"^a+$"},
        "name":{"type":"array","items":{"type":"string","pattern":"(unclosed"}}}})"));
    REQUIRE(bad.size() == 1);
    CHECK(bad[0].pointer == "/properties/name/items/pattern");
    CHECK_FALSE(bad[0].hint.empty());
    CHECK(check_schema_patterns(Json::parse(R"({"type":"string","pattern":"^[a-z]+$"})")).empty());
    // A property that is named "pattern" is a schema, not a regex.
    CHECK(check_schema_patterns(Json::parse(R"({"properties":{"pattern":{"type":"string"}}})")).empty());
    // A property named like a data keyword ("default", "enum"...) holds a schema and is checked; the keyword itself is data.
    auto named = check_schema_patterns(Json::parse(R"({"type":"object","properties":{
        "default":{"type":"string","pattern":"(open"},
        "enum":{"type":"string","pattern":"[abc"}}})"));
    REQUIRE(named.size() == 2);
    std::vector<std::string> pointers{named[0].pointer, named[1].pointer};
    std::sort(pointers.begin(), pointers.end());
    CHECK(pointers[0] == "/properties/default/pattern");
    CHECK(pointers[1] == "/properties/enum/pattern");
    CHECK(check_schema_patterns(Json::parse(R"({"type":"object","default":{"pattern":"(open"},"enum":[{"pattern":"("}]})")).empty());
}
