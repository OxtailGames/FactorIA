#include <doctest.h>

#include "fa/core/command.h"
#include "fa/core/json_schema.h"

using namespace fa;

namespace {
CommandRegistry make_registry() {
    CommandRegistry reg;
    CommandInfo add;
    add.name = "math.add";
    add.summary = "Add two numbers.";
    add.category = "math";
    add.inputSchema = Json::parse(R"({
        "type":"object",
        "properties":{
            "a":{"type":"number"},
            "b":{"type":"number","default":10},
            "mode":{"type":"string","enum":["fast","exact"],"default":"fast"}
        },
        "required":["a"],
        "additionalProperties":false})");
    reg.add(add, [](const Json& args) {
        return Json::object({{"sum", args["a"].get<double>() + args["b"].get<double>()}, {"mode", args["mode"]}});
    });

    CommandInfo fail;
    fail.name = "test.fail";
    fail.readOnly = false;
    fail.category = "test";
    reg.add(fail, [](const Json&) -> Json { throw CommandError("not_found", "No such thing", "Use test.list."); });
    CommandInfo boom;
    boom.name = "test.boom";
    boom.category = "test";
    reg.add(boom, [](const Json&) -> Json { throw std::runtime_error("kaboom"); });
    return reg;
}
}  // namespace

TEST_CASE("command: success applies defaults") {
    auto reg = make_registry();
    auto r = reg.call("math.add", Json::parse(R"({"a": 1})"));
    REQUIRE(r.ok);
    CHECK(r.result["sum"] == 11);
    CHECK(r.result["mode"] == "fast");
    CHECK(reg.call("math.add", Json::parse(R"({"a": 1, "b": 2})")).result["sum"] == 3);
}

TEST_CASE("command: validation errors are structured and teach") {
    auto reg = make_registry();
    auto missing = reg.call("math.add", Json::object());
    REQUIRE(!missing.ok);
    CHECK(missing.error["code"] == "invalid_arguments");
    CHECK(missing.error["message"].get<std::string>().find("missing required property 'a'") != std::string::npos);

    auto typo = reg.call("math.add", Json::parse(R"({"a": 1, "bb": 2})"));
    REQUIRE(!typo.ok);
    CHECK(typo.error["message"].get<std::string>().find("/bb") != std::string::npos);
    CHECK(typo.error["hint"].get<std::string>().find("Did you mean 'b'") != std::string::npos);

    auto wrong = reg.call("math.add", Json::parse(R"({"a": "x"})"));
    REQUIRE(!wrong.ok);
    CHECK(wrong.error["message"].get<std::string>().find("/a: expected number, got string") != std::string::npos);

    auto en = reg.call("math.add", Json::parse(R"({"a": 1, "mode": "fats"})"));
    REQUIRE(!en.ok);
    CHECK(en.error["hint"].get<std::string>().find("Did you mean 'fast'") != std::string::npos);
}

TEST_CASE("command: unknown command suggests names") {
    auto reg = make_registry();
    auto r = reg.call("math.ad", Json::object());
    REQUIRE(!r.ok);
    CHECK(r.error["code"] == "unknown_command");
    CHECK(r.error["hint"].get<std::string>().find("Did you mean 'math.add'") != std::string::npos);
    auto mcp = reg.call("math_add", Json::object({{"a", 1}}));
    CHECK(!mcp.ok);
    CHECK(mcp.error["hint"].get<std::string>().find("'math.add'") != std::string::npos);
}

TEST_CASE("command: exceptions become results") {
    auto reg = make_registry();
    auto e = reg.call("test.fail");
    REQUIRE(!e.ok);
    CHECK(e.error["code"] == "not_found");
    CHECK(e.error["message"] == "No such thing");
    CHECK(e.error["hint"] == "Use test.list.");
    auto b = reg.call("test.boom");
    REQUIRE(!b.ok);
    CHECK(b.error["code"] == "failed");
    CHECK(b.error["message"].get<std::string>().find("kaboom") != std::string::npos);
}

TEST_CASE("command: listing, describe, remove") {
    auto reg = make_registry();
    CHECK(reg.has("math.add"));
    REQUIRE(reg.info("math.add") != nullptr);
    CHECK(reg.info("math.add")->summary == "Add two numbers.");
    auto all = reg.list();
    REQUIRE(all.size() == 3);
    CHECK(all[0]->name == "math.add");
    CHECK(all[2]->name == "test.fail");
    CHECK(reg.list("test").size() == 2);
    Json d = reg.describe();
    REQUIRE(d.size() == 3);
    CHECK(d[0]["name"] == "math.add");
    CHECK(d[0].contains("inputSchema"));
    CHECK(d[2]["readOnly"] == false);
    reg.remove("math.add");
    CHECK(!reg.has("math.add"));
}
