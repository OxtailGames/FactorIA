#include <doctest.h>

#include <algorithm>
#include <atomic>
#include <thread>
#include <vector>

#include "fa/core/json_schema.h"

using namespace fa;

// The interpreted path's errors; the compiled path must give exactly the same ones (and the same value with its defaults), so
// every case below also tests CompiledSchema.
static std::vector<SchemaError> check(const char* schema, const char* value) {
    const Json s = Json::parse(schema), v = Json::parse(value);
    std::vector<SchemaError> errors = validate_json(s, v);
    const std::vector<SchemaError> compiled = validate_json(CompiledSchema(s), v);
    REQUIRE(compiled.size() == errors.size());
    for (std::size_t i = 0; i < errors.size(); ++i) {
        CHECK(compiled[i].pointer == errors[i].pointer);
        CHECK(compiled[i].message == errors[i].message);
        CHECK(compiled[i].hint == errors[i].hint);
    }
    return errors;
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

TEST_CASE("schema: x- annotation keys in a schema (x-fa-path) are ignored and closing keeps them") {
    Json schema = Json::parse(R"({
        "type":"object",
        "properties":{
            "out":{"type":"string","x-fa-path":"write"},
            "nested":{"type":"object","properties":{"file":{"type":"string","x-fa-path":"read"}}}}})");
    schema = close_object_schemas(schema);
    CHECK(schema["additionalProperties"] == false);
    CHECK(schema["properties"]["out"]["x-fa-path"] == "write");
    CHECK(schema["properties"]["nested"]["properties"]["file"]["x-fa-path"] == "read");
    CHECK(validate_json(schema, Json::parse(R"({"out":"a.png","nested":{"file":"b"}})")).empty());
    // The annotation changes nothing about the instance: an unknown key is still refused, a wrong type too.
    auto e = validate_json(schema, Json::parse(R"({"out":3,"x-fa-path":"write"})"));
    REQUIRE(e.size() == 2);
    CHECK(e[0].pointer == "/out");
    CHECK(e[1].message.find("unknown property") != std::string::npos);
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
    const Json schema =
        Json::parse(R"({"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z_]+[0-9]*$"}}})");
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
    CHECK(check_schema_patterns(
              Json::parse(R"({"type":"object","default":{"pattern":"(open"},"enum":[{"pattern":"("}]})"))
              .empty());
}

// ---- CompiledSchema: the same errors and defaults as the Json it was built from ---------------------------------------

// Runs one value through the interpreted and the compiled path: every error (pointer, message, hint) and the value with its
// defaults applied must be identical. Returns the errors, so a test can also say what they are.
static std::vector<SchemaError> both_paths(const Json& schema, const Json& value) {
    const CompiledSchema compiled(schema);
    const std::vector<SchemaError> a = validate_json(schema, value);
    const std::vector<SchemaError> b = validate_json(compiled, value);
    REQUIRE(a.size() == b.size());
    for (std::size_t i = 0; i < a.size(); ++i) {
        CHECK(a[i].pointer == b[i].pointer);
        CHECK(a[i].message == b[i].message);
        CHECK(a[i].hint == b[i].hint);
    }
    Json da = value, db = value;
    apply_schema_defaults(schema, da);
    apply_schema_defaults(compiled, db);
    CHECK(da.dump() == db.dump());
    // has_defaults() promises that nothing changes when it is false.
    if (!compiled.has_defaults()) CHECK(db.dump() == value.dump());
    return b;
}

TEST_CASE("compiled schema: the same errors, pointers, hints and defaults as the interpreted path") {
    const Json schema = Json::parse(R"({
        "type":"object",
        "properties":{
            "name":{"type":"string","minLength":2,"pattern":"^[a-z][a-z0-9_]*$","description":"Entity name.","default":"ab"},
            "n":{"type":["integer","null"],"minimum":0,"maximum":100.5},
            "list":{"type":"array","items":{"$ref":"#/$defs/item"},"minItems":1,"maxItems":3},
            "mode":{"enum":["fast","exact",3,null],"default":"fast"},
            "fixed":{"const":{"k":[1,2]}},
            "either":{"oneOf":[{"type":"string"},{"type":"number","minimum":1}]},
            "any":{"anyOf":[{"type":"boolean"},{"$ref":"#/$defs/item"}]},
            "mixed":{"anyOf":[{"type":"string"},{"properties":{"x":{"type":"integer"}}}]},
            "free":{"type":"object","additionalProperties":{"type":"integer"}},
            "never":false,
            "always":true,
            "weird":"not a schema",
            "opts":{"type":"object","properties":{"deep":{"default":true},"deeper":{"type":"object","properties":{"z":{"default":[1]}}}}}
        },
        "required":["name","n","list"],
        "additionalProperties":false,
        "$defs":{"item":{"type":"object","properties":{"id":{"type":"integer","default":0},
                 "kids":{"type":"array","items":{"$ref":"#/$defs/item"}}},"required":["id"],"additionalProperties":false}}
    })");
    const char* values[] = {
        R"({"name":"ab","n":1,"list":[{"id":1}]})",
        R"({"n":1,"list":[{"id":1,"kids":[{"id":2,"kids":[{"id":3}]}]}]})",
        R"({"name":"A","n":-1,"list":[]})",
        R"({"name":5,"n":"x","list":{}})",
        R"({"nmae":"x","n":101,"list":[{"id":1},{"id":2},{"id":3},{"id":4}],"extra":1})",
        R"({"name":"ab","n":null,"list":[{"id":"x"},{"idd":1,"kids":[{}]}]})",
        R"({"name":"ab","n":1.5,"list":[{"id":1}],"mode":"fats"})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"mode":4})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"mode":3,"fixed":{"k":[1,3]}})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"either":0,"any":7,"mixed":3})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"either":2.5,"any":{"id":"q"},"mixed":{"x":"s"}})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"free":{"a":1,"b/c":"s","d~e":2.5},"never":1,"always":2,"weird":3})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"opts":{"deeper":{}}})",
        R"({"name":"ab","n":1,"list":[{"id":1}],"opts":{"deep":false,"deeper":{"z":[]}}})",
        R"([1,2])",
        R"("text")",
        R"(null)",
    };
    for (const char* v : values) {
        INFO(v);
        both_paths(schema, Json::parse(v));
    }
    // The defaults are really applied by the compiled path (not just the same as the interpreted one).
    const CompiledSchema compiled(schema);
    CHECK(compiled.has_defaults());
    Json v = Json::parse(R"({"n":1,"list":[{}],"opts":{"deeper":{}}})");
    apply_schema_defaults(compiled, v);
    CHECK(v["name"] == "ab");
    CHECK(v["mode"] == "fast");
    CHECK(v["list"][0]["id"] == 0);
    CHECK(v["opts"]["deep"] == true);
    CHECK(v["opts"]["deeper"]["z"] == Json::parse("[1]"));
}

TEST_CASE("compiled schema: recursive $ref, refs that do not resolve and refs to odd places") {
    const Json tree = Json::parse(R"({
        "$ref":"#/$defs/node",
        "$defs":{"node":{"type":"object","properties":{"v":{"type":"integer","default":7},"next":{"$ref":"#/$defs/node"},
                 "kids":{"type":"array","items":{"$ref":"#/$defs/node"}}},"additionalProperties":false}}})");
    Json deep = Json::object();
    Json* at = &deep;
    for (int i = 0; i < 20; ++i) {
        (*at)["next"] = Json::object({{"v", i}});
        at = &(*at)["next"];
    }
    (*at)["next"] = Json::object({{"v", "bad"}});
    auto e = both_paths(tree, deep);
    REQUIRE(e.size() == 1);
    CHECK(e[0].pointer.rfind("/next/next", 0) == 0);
    CHECK(e[0].pointer.size() == 5 * 21 + 2);
    both_paths(tree, Json::parse(R"({"kids":[{"kids":[{"v":1.5}]}]})"));
    // The root itself, a self-reference that never consumes the value (stopped by the depth limit), and a missing target.
    both_paths(Json::parse(R"({"type":"object","properties":{"a":{"$ref":"#"}},"additionalProperties":false})"),
               Json::parse(R"({"a":{"a":{"a":1}}})"));
    both_paths(Json::parse(R"({"$ref":"#"})"), Json(1));
    both_paths(Json::parse(R"({"anyOf":[{"$ref":"#"},{"type":"string"}]})"), Json(1));
    for (const char* ref : {"#/$defs/nope", "", "other.json#/x", "#/properties/a/x"}) {
        Json schema = Json::object({{"properties", Json::object({{"a", Json::object({{"$ref", ref}})}})}});
        auto errs = both_paths(schema, Json::parse(R"({"a":1})"));
        REQUIRE(errs.size() == 1);
        CHECK(errs[0].message.find("cannot resolve $ref") != std::string::npos);
    }
    // A $ref that points at a node with a $ref of its own uses that node's keywords, not its reference; a $ref next to
    // other keywords wins over them; a $ref to a boolean or to a non-schema value checks nothing.
    both_paths(Json::parse(R"({"$defs":{"a":{"$ref":"#/$defs/b","type":"string"},"b":{"type":"integer"}},
                               "properties":{"x":{"$ref":"#/$defs/a"},"y":{"$ref":"#/$defs/b","type":"string"}}})"),
               Json::parse(R"({"x":1,"y":"s"})"));
    both_paths(Json::parse(R"({"$defs":{"no":false,"yes":true,"n":3},
                               "properties":{"a":{"$ref":"#/$defs/no"},"b":{"$ref":"#/$defs/yes"},"c":{"$ref":"#/$defs/n"}}})"),
               Json::parse(R"({"a":1,"b":2,"c":3})"));
    both_paths(Json::parse(R"({"properties":{"a":{"$ref":"#/properties"}}})"), Json::parse(R"({"a":{"a":1}})"));
    // Nested defaults reached through a $ref.
    Json filled = Json::object();
    apply_schema_defaults(CompiledSchema(tree), filled);
    CHECK(filled["v"] == 7);
}

TEST_CASE("compiled schema: defaults stop at the same depth on both paths, through a recursive $ref") {
    const Json tree = Json::parse(R"({
        "$ref":"#/$defs/node",
        "$defs":{"node":{"type":"object","properties":{"v":{"type":"integer","default":7},"next":{"$ref":"#/$defs/node"}}}}})");
    Json chain = Json::object();
    Json* at = &chain;
    for (int i = 0; i < 40; ++i) {
        (*at)["next"] = Json::object();
        at = &(*at)["next"];
    }
    Json viaJson = chain;
    Json viaCompiled = chain;
    apply_schema_defaults(tree, viaJson);
    apply_schema_defaults(CompiledSchema(tree), viaCompiled);
    CHECK(viaJson == viaCompiled);
    const Json* level = &viaCompiled;
    for (int depth = 0; depth <= 36; ++depth) {
        INFO("depth " << depth);
        CHECK(level->contains("v") == (depth <= 32));  // the defaults depth limit
        level = &(*level)["next"];
    }
}

TEST_CASE("compiled schema: a default reachable only through a $ref is applied and has_defaults sees it") {
    const Json schema = Json::parse(R"({"type":"object","properties":{
        "a":{"$ref":"#/$defs/opts"},"list":{"type":"array","items":{"$ref":"#/$defs/opts"}}},
        "$defs":{"opts":{"type":"object","properties":{"mode":{"type":"string","default":"fast"}}}}})");
    CHECK(CompiledSchema(schema).has_defaults());
    Json viaJson = Json::parse(R"({"a":{},"list":[{},{"mode":"slow"}]})");
    Json viaCompiled = viaJson;
    apply_schema_defaults(schema, viaJson);
    apply_schema_defaults(CompiledSchema(schema), viaCompiled);
    CHECK(viaJson == viaCompiled);
    CHECK(viaCompiled["a"]["mode"] == "fast");
    CHECK(viaCompiled["list"][0]["mode"] == "fast");
    CHECK(viaCompiled["list"][1]["mode"] == "slow");
    CHECK(!CompiledSchema(Json::parse(R"({"$defs":{"o":{"properties":{"m":{"type":"string"}}}},
                                          "properties":{"a":{"$ref":"#/$defs/o"}}})"))
               .has_defaults());
}

TEST_CASE("compiled schema: an invalid pattern gives the same error, at the same point") {
    const Json schema = Json::parse(R"({"type":"object","properties":{
        "a":{"type":"string","minLength":3,"pattern":"([a-z"},
        "b":{"type":"string","pattern":"^ok$"}}})");
    CHECK(both_paths(schema, Json::parse(R"({"a":"xyz","b":"ok"})")).size() == 1);  // the schema error
    CHECK(both_paths(schema, Json::parse(R"({"a":"xy","b":"no"})")).size() == 3);   // too short, schema error, mismatch
    CHECK(both_paths(schema, Json::parse(R"({"a":5,"b":"ok"})")).size() == 1);  // a number is not checked against it
    CHECK(both_paths(schema, Json::parse(R"({"b":"ok"})")).empty());            // nothing to check
    // Compiling the schema does not report the pattern: only validating a string does.
    CHECK_NOTHROW(CompiledSchema{schema});
}

TEST_CASE("compiled schema: keywords in every position, with the pointers an AI reads") {
    const char* schemas[] = {
        R"({"type":"integer","minimum":0.5,"maximum":5})",
        R"({"type":"string","minLength":0,"const":"a"})",
        R"({"type":["array","null"],"items":false})",
        R"({"type":"array","items":[{"type":"string"}],"minItems":-1})",
        R"({"type":"object","properties":{"a":{"type":"string","description":"The a."}},"required":["a","b",5],
            "additionalProperties":false})",
        R"({"type":"object","additionalProperties":false})",
        R"({"type":"object","additionalProperties":true,"properties":{"a/b":{"type":"integer"},"c~d":{"type":"integer"}}})",
        R"({"anyOf":[]})",
        R"({"anyOf":[{"type":"string"},{"type":"integer"}],"oneOf":[{"type":"string"},{"type":"number"}]})",
        R"({"oneOf":[{"properties":{"k":{"const":1}}},{"properties":{"k":{"const":2}}}]})",
        R"({"oneOf":[true,{"type":"string"}]})",
        R"({"oneOf":[false,{"type":"string"}]})",
        R"({"enum":[]})",
        R"({"enum":"x"})",
        R"({"properties":{"default":{"type":"string","default":"d"},"pattern":{"type":"integer","default":3}}})",
        R"({"type":"made-up"})",
        R"(true)",
        R"(false)",
        R"("a string")",
        R"(3)",
        R"(null)",
    };
    const char* values[] = {
        R"(null)",
        R"(true)",
        R"(0)",
        R"(3)",
        R"(5.5)",
        R"(-1)",
        R"("a")",
        R"("")",
        R"([])",
        R"(["x"])",
        R"([1,2,3])",
        R"({})",
        R"({"a":1})",
        R"({"a":"x","b":2})",
        R"({"a":"s","c":1})",
        R"({"k":1})",
        R"({"k":3})",
        R"({"a/b":"x","c~d":"y"})",
    };
    for (const char* s : schemas)
        for (const char* v : values) {
            INFO(s << " <- " << v);
            both_paths(Json::parse(s), Json::parse(v));
        }
}

TEST_CASE("compiled schema: a default CompiledSchema accepts everything, copies share the compiled schema") {
    CompiledSchema none;
    CHECK(validate_json(none, Json(1)).empty());
    CHECK_FALSE(none.has_defaults());
    Json v = Json::object();
    apply_schema_defaults(none, v);
    CHECK(v.empty());

    CompiledSchema original(Json::parse(R"({"type":"string"})"));
    CompiledSchema copy = original;
    CHECK(validate_json(copy, Json(1)).size() == 1);
    CHECK(validate_json(original, Json("a")).empty());
    // The compiled schema does not keep a reference to the Json it came from.
    CompiledSchema owned;
    {
        Json temp = Json::parse(R"({"type":"object","properties":{"a":{"type":"integer","default":4}}})");
        owned = CompiledSchema(temp);
    }
    Json x = Json::object();
    apply_schema_defaults(owned, x);
    CHECK(x["a"] == 4);
    CHECK(validate_json(owned, Json::parse(R"({"a":"s"})")).size() == 1);
}

TEST_CASE("compiled schema: validation from several threads agrees") {
    const CompiledSchema schema(Json::parse(
        R"({"type":"object","properties":{"id":{"type":"string","pattern":"^[a-z_]+[0-9]*$"}},"required":["id"]})"));
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
