#include <doctest.h>

#include <thread>
#include <vector>

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

TEST_CASE("command progress: reports reach the sink of the calling thread's scope, and nowhere else") {
    CHECK_FALSE(command_progress_active());
    CHECK_FALSE(report_command_progress("nobody listens"));  // a no-op without a scope

    std::vector<std::string> outer, inner;
    {
        CommandProgressScope a([&](std::string_view m) {
            outer.emplace_back(m);
            return true;
        });
        CHECK(command_progress_active());
        CHECK(report_command_progress("one"));
        {
            CommandProgressScope b([&](std::string_view m) {
                inner.emplace_back(m);
                return false;  // "nobody listens any more" comes back to the reporter
            });
            CHECK_FALSE(report_command_progress("two"));
        }
        CHECK(report_command_progress("three"));  // the outer scope is back
        bool otherThread = true;
        std::thread t([&] { otherThread = command_progress_active(); });
        t.join();
        CHECK_FALSE(otherThread);  // per thread
    }
    CHECK_FALSE(command_progress_active());
    CHECK(outer == std::vector<std::string>{"one", "three"});
    CHECK(inner == std::vector<std::string>{"two"});
}

TEST_CASE("CommandRegistry interceptor: refuse, change the arguments, add to the result, skip what it does not want") {
    CommandRegistry reg;
    for (const char* name : {"t.echo", "t.skipped", "t.refused"}) {
        CommandInfo info;
        info.name = name;
        info.summary = "Returns its arguments.";
        reg.add(info, [](const Json& a) { return Json::object({{"args", a}}); });
    }
    int afters = 0;
    double lastMs = -1;
    auto icp = std::make_shared<CommandInterceptor>();
    icp->wants = [](std::string_view n) { return n != "t.skipped"; };
    icp->before = [](std::string_view n, Json& args) -> std::optional<CommandResult> {
        if (n == "t.refused") return CommandResult{false, Json(), Json::object({{"code", "refused"}, {"message", "no"}})};
        args["added"] = 1;
        return std::nullopt;
    };
    icp->after = [&](std::string_view, const Json&, CommandResult& r, double ms) {
        ++afters;
        lastMs = ms;
        if (r.ok) r.result["seen"] = true;
    };
    CHECK_FALSE(reg.has_interceptor());
    reg.set_interceptor(icp);
    CHECK(reg.has_interceptor());

    auto refused = reg.call("t.refused");
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "refused");
    CHECK(afters == 0);  // refused: the handler did not run and `after` was not called
    auto changed = reg.call("t.echo", Json::object({{"x", 1}}));
    REQUIRE(changed.ok);
    CHECK(changed.result["args"]["added"] == 1);
    CHECK(changed.result["seen"] == true);
    CHECK(lastMs >= 0);
    auto skipped = reg.call("t.skipped");
    REQUIRE(skipped.ok);
    CHECK_FALSE(skipped.result.contains("seen"));
    CHECK(afters == 1);
    reg.set_interceptor(nullptr);
    CHECK_FALSE(reg.has_interceptor());
    CHECK_FALSE(reg.call("t.echo").result.contains("seen"));
}
