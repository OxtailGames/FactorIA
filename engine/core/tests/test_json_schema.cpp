#include <doctest.h>

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
