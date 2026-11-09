#include <doctest.h>

#include <atomic>
#include <condition_variable>
#include <mutex>
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

TEST_CASE("command: handler() lets a caller wrap a command") {
    auto reg = make_registry();
    CHECK_FALSE(reg.handler("nope"));
    CommandHandler inner = reg.handler("math.add");
    REQUIRE(inner);
    int seen = 0;
    CommandInfo info = *reg.info("math.add");
    reg.add(info, [inner, &seen](const Json& args) {
        ++seen;
        return inner(args);
    });
    const CommandResult r = reg.call("math.add", Json{{"a", 2}, {"b", 3}});
    REQUIRE(r.ok);
    CHECK(r.result == reg.call("math.add", Json{{"a", 2}, {"b", 3}}).result);
    CHECK(seen == 2);
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

TEST_CASE("command caller: the user outside any scope, the stricter caller inside nested ones, per thread") {
    CHECK(command_caller() == CommandCaller::User);
    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        CHECK(command_caller() == CommandCaller::Mcp);
        {
            CommandCallerScope agent(CommandCaller::Agent);  // inside an MCP call: still refused as an MCP client
            CHECK(command_caller() == CommandCaller::Mcp);
        }
        CHECK(command_caller() == CommandCaller::Mcp);
        CommandCaller other = CommandCaller::Mcp;
        std::thread t([&] { other = command_caller(); });
        t.join();
        CHECK(other == CommandCaller::User);  // per thread
    }
    CHECK(command_caller() == CommandCaller::User);
    {
        CommandCallerScope agent(CommandCaller::Agent);
        CHECK(command_caller() == CommandCaller::Agent);
    }
    CHECK(command_caller() == CommandCaller::User);
    CHECK(std::string(command_caller_name(CommandCaller::Agent)) == "an AI agent");
}

TEST_CASE("command caller floor: a process started by an AI is never the user, on every thread, and only gets stricter") {
    CHECK_FALSE(command_caller_from_env_value(nullptr).has_value());
    CHECK_FALSE(command_caller_from_env_value("").has_value());
    CHECK(command_caller_from_env_value("agent") == CommandCaller::Agent);
    CHECK(command_caller_from_env_value("mcp") == CommandCaller::Mcp);
    CHECK(command_caller_from_env_value("user") == CommandCaller::Agent);     // never the user
    CHECK(command_caller_from_env_value("whatever") == CommandCaller::Agent);  // unknown: restricted
    CHECK(command_caller() == CommandCaller::User);
    {
        CommandCallerFloor agent(CommandCaller::Agent);
        CHECK(command_caller() == CommandCaller::Agent);
        CommandCaller other = CommandCaller::User;
        std::thread t([&] { other = command_caller(); });
        t.join();
        CHECK(other == CommandCaller::Agent);  // any thread, unlike a scope
        {
            CommandCallerFloor user(CommandCaller::User);  // cannot loosen
            CHECK(command_caller() == CommandCaller::Agent);
        }
        CHECK(command_caller() == CommandCaller::Agent);
        {
            CommandCallerScope mcp(CommandCaller::Mcp);  // a scope inside a floor that is not User keeps the outer caller
            CHECK(command_caller() == CommandCaller::Agent);
        }
    }
    CHECK(command_caller() == CommandCaller::User);
}

TEST_CASE("CommandRegistry interceptor: refuse, change the arguments, add to the result, skip what it does not want") {
    CommandRegistry reg;
    for (const char* name : {"t.echo", "t.skipped", "t.refused"}) {
        CommandInfo info;
        info.name = name;
        info.summary = "Returns its arguments.";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{"x":{"type":"integer"},"added":{"type":"integer"}}})");
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

// ---------------------------------------------------------------------------------------------------------------------
// Closed by default: a key the schema does not declare is an error, not something silently ignored.
// ---------------------------------------------------------------------------------------------------------------------

namespace {
CommandRegistry closed_registry() {
    CommandRegistry reg;
    CommandInfo in;
    in.name = "game.input";
    in.summary = "Press things.";
    in.inputSchema = Json::parse(R"({"type":"object","properties":{
        "press":{"type":"array","items":{"type":"string"}},
        "entity":{"type":"string"},
        "mouse":{"type":"object","properties":{"x":{"type":"number"},"y":{"type":"number"}}},
        "pads":{"type":"array","items":{"type":"object","properties":{"index":{"type":"integer"},"buttons":{"type":"array"}}}}}})");
    reg.add(in, [](const Json& a) { return Json::object({{"args", a}}); });

    CommandInfo open;
    open.name = "scene.set_values";
    open.inputSchema = Json::parse(R"({"type":"object","properties":{
        "id":{"type":"string"},
        "fields":{"type":"object","additionalProperties":true},
        "free":{"type":"object"},
        "typed":{"type":"object","additionalProperties":{"type":"number"}}},
        "additionalProperties":true})");
    reg.add(open, [](const Json& a) { return Json::object({{"args", a}}); });

    CommandInfo none;  // the default schema: no properties
    none.name = "game.state";
    reg.add(none, [](const Json&) { return Json::object(); });
    return reg;
}
}  // namespace

TEST_CASE("command: an undeclared top-level key is rejected with its pointer, near misses and the accepted keys") {
    auto reg = closed_registry();
    auto r = reg.call("game.input", Json::parse(R"({"press":["back"],"frames":2})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_arguments");
    const std::string message = r.error["message"].get<std::string>();
    CHECK(message.find("'game.input'") != std::string::npos);
    CHECK(message.find("/frames") != std::string::npos);
    CHECK(message.find("unknown property 'frames'") != std::string::npos);
    const std::string hint = r.error["hint"].get<std::string>();
    for (const char* key : {"press", "entity", "mouse", "pads"}) CHECK(hint.find(key) != std::string::npos);

    auto typo = reg.call("game.input", Json::parse(R"({"entiy":"hero"})"));
    REQUIRE_FALSE(typo.ok);
    CHECK(typo.error["hint"].get<std::string>().find("Did you mean 'entity'") != std::string::npos);

    CHECK(reg.call("game.input", Json::parse(R"({"press":["back"],"entity":"hero"})")).ok);
}

TEST_CASE("command: a command with no declared arguments takes none") {
    auto reg = closed_registry();
    CHECK(reg.call("game.state").ok);
    CHECK(reg.call("game.state", Json::object()).ok);
    auto r = reg.call("game.state", Json::parse(R"({"verbose":true})"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_arguments");
    CHECK(r.error["message"].get<std::string>().find("/verbose") != std::string::npos);
    CHECK(r.error["hint"].get<std::string>().find("takes no properties") != std::string::npos);
}

TEST_CASE("command: nested objects that declare properties are closed too, arrays of them as well") {
    auto reg = closed_registry();
    auto mouse = reg.call("game.input", Json::parse(R"({"mouse":{"x":1,"y":2,"z":3}})"));
    REQUIRE_FALSE(mouse.ok);
    CHECK(mouse.error["message"].get<std::string>().find("/mouse/z") != std::string::npos);
    CHECK(mouse.error["hint"].get<std::string>().find("Valid: x, y") != std::string::npos);

    auto pads = reg.call("game.input", Json::parse(R"({"pads":[{"index":0},{"index":1,"buton":[]}]})"));
    REQUIRE_FALSE(pads.ok);
    CHECK(pads.error["message"].get<std::string>().find("/pads/1/buton") != std::string::npos);
    CHECK(pads.error["hint"].get<std::string>().find("Did you mean 'buttons'") != std::string::npos);

    CHECK(reg.call("game.input", Json::parse(R"({"mouse":{"x":1},"pads":[{"index":0,"buttons":[]}]})")).ok);
}

TEST_CASE("command: additionalProperties true (or a schema) is the explicit opt-out") {
    auto reg = closed_registry();
    // Root opened explicitly.
    auto root = reg.call("scene.set_values", Json::parse(R"({"id":"a","anything":[1,2]})"));
    REQUIRE(root.ok);
    CHECK(root.result["args"]["anything"].size() == 2);
    // A nested object that says true, a nested object with no properties at all, and one that types its values.
    CHECK(reg.call("scene.set_values", Json::parse(R"({"fields":{"hp":3,"whatever":"x"}})")).ok);
    CHECK(reg.call("scene.set_values", Json::parse(R"({"free":{"hp":3,"whatever":"x"}})")).ok);
    CHECK(reg.call("scene.set_values", Json::parse(R"({"typed":{"a":1,"b":2}})")).ok);
    auto typed = reg.call("scene.set_values", Json::parse(R"({"typed":{"a":"one"}})"));
    REQUIRE_FALSE(typed.ok);
    CHECK(typed.error["message"].get<std::string>().find("/typed/a") != std::string::npos);
}

TEST_CASE("command: the stored schema is the closed one, so describe shows what call enforces") {
    auto reg = closed_registry();
    const CommandInfo* in = reg.info("game.input");
    REQUIRE(in != nullptr);
    CHECK(in->inputSchema["additionalProperties"] == false);
    CHECK(in->inputSchema["properties"]["mouse"]["additionalProperties"] == false);
    CHECK(in->inputSchema["properties"]["pads"]["items"]["additionalProperties"] == false);
    const CommandInfo* open = reg.info("scene.set_values");
    CHECK(open->inputSchema["additionalProperties"] == true);
    CHECK(open->inputSchema["properties"]["fields"]["additionalProperties"] == true);
    CHECK_FALSE(open->inputSchema["properties"]["free"].contains("additionalProperties"));
    CHECK(reg.info("game.state")->inputSchema["additionalProperties"] == false);
    // describe() carries the same schema, and re-adding a stored schema changes nothing.
    CHECK(reg.describe()[0]["inputSchema"] == reg.info(reg.describe()[0]["name"].get<std::string>())->inputSchema);
    CommandRegistry again;
    again.add(*in, [](const Json&) { return Json::object(); });
    CHECK(again.info("game.input")->inputSchema == in->inputSchema);
}

TEST_CASE("command: a transport key in the arguments (MCP _meta) is not an unknown argument") {
    auto reg = closed_registry();
    auto r = reg.call("game.input", Json::parse(R"({"press":["back"],"_meta":{"progressToken":"t1"}})"));
    REQUIRE(r.ok);
    CHECK_FALSE(r.result["args"].contains("_meta"));  // the handler never sees it
    CHECK(reg.call("game.state", Json::parse(R"({"_meta":{"progressToken":7}})")).ok);
    // Other unknown keys next to it are still refused.
    CHECK_FALSE(reg.call("game.state", Json::parse(R"({"_meta":{},"verbose":1})")).ok);
}

TEST_CASE("close_object_schemas: properties get closed, $defs too, objects without properties are left alone") {
    Json s = close_object_schemas(Json::parse(R"({"type":"object","properties":{
        "a":{"oneOf":[{"type":"object","properties":{"x":{"type":"number"}}},{"type":"string"}]},
        "b":{"$ref":"#/$defs/Point"},
        "c":{"type":"object"},
        "default":{"type":"object","default":{"properties":{"k":1}}}},
        "$defs":{"Point":{"type":"object","properties":{"x":{"type":"number"}}}}})"));
    CHECK(s["additionalProperties"] == false);
    CHECK(s["properties"]["a"]["oneOf"][0]["additionalProperties"] == false);
    CHECK_FALSE(s["properties"]["a"]["oneOf"][1].contains("additionalProperties"));
    CHECK(s["$defs"]["Point"]["additionalProperties"] == false);
    CHECK_FALSE(s["properties"]["c"].contains("additionalProperties"));
    CHECK(s["properties"]["default"]["default"] == Json::parse(R"({"properties":{"k":1}})"));  // data, not a schema
    CHECK(close_object_schemas(Json::object({{"type", "string"}})) == Json::object({{"type", "string"}}));
}

TEST_CASE("command: the before-call hook runs for the outermost call of a thread only, never for a nested call") {
    CommandRegistry reg;
    std::atomic<int> hooks{0};
    reg.set_before_call([&](std::string_view) { ++hooks; });
    CommandInfo inner;
    inner.name = "t.inner";
    reg.add(inner, [](const Json&) { return Json::object(); });
    CommandInfo outer;
    outer.name = "t.outer";
    reg.add(outer, [&reg](const Json&) {
        reg.call("t.inner");
        reg.call("t.inner");
        return Json::object();
    });
    CHECK(reg.call("t.outer").ok);
    CHECK(hooks == 1);  // the two nested calls did not run it
    CHECK(reg.call("t.inner").ok);
    CHECK(hooks == 2);  // the depth went back to 0 after the first call

    // A second registry called from a handler is its own outermost call.
    CommandRegistry other;
    std::atomic<int> otherHooks{0};
    other.set_before_call([&](std::string_view) { ++otherHooks; });
    CommandInfo plain;
    plain.name = "t.plain";
    other.add(plain, [](const Json&) { return Json::object(); });
    CommandInfo crossing;
    crossing.name = "t.cross";
    reg.add(crossing, [&other](const Json&) {
        other.call("t.plain");
        return Json::object();
    });
    CHECK(reg.call("t.cross").ok);
    CHECK(otherHooks == 1);
}

TEST_CASE("command: calls on several threads at once keep their own depth") {
    constexpr int kThreads = 4;
    constexpr int kCalls = 25;
    CommandRegistry reg;
    std::atomic<int> hooks{0};
    std::atomic<int> insideHandlers{0};
    std::atomic<int> maxInside{0};
    // A rendezvous inside the handler: every thread waits for all the others, so the calls overlap in every round
    // whatever the speed of the machine. Each thread makes exactly kCalls calls, so nobody waits for a partner that is gone.
    std::mutex rvMutex;
    std::condition_variable rvCv;
    int arrived = 0;
    long generation = 0;
    reg.set_before_call([&](std::string_view) { ++hooks; });
    CommandInfo inner;
    inner.name = "t.inner";
    reg.add(inner, [](const Json&) { return Json::object(); });
    CommandInfo outer;
    outer.name = "t.outer";
    reg.add(outer, [&](const Json&) {
        const int now = ++insideHandlers;
        int seen = maxInside.load();
        while (now > seen && !maxInside.compare_exchange_weak(seen, now)) {}
        {
            std::unique_lock<std::mutex> lock(rvMutex);
            const long myGeneration = generation;
            if (++arrived == kThreads) {
                arrived = 0;
                ++generation;
                rvCv.notify_all();
            } else {
                rvCv.wait(lock, [&] { return generation != myGeneration; });
            }
        }
        reg.call("t.inner");
        --insideHandlers;
        return Json::object();
    });
    std::atomic<int> failures{0};
    std::vector<std::thread> threads;
    for (int t = 0; t < kThreads; ++t)
        threads.emplace_back([&] {
            for (int i = 0; i < kCalls; ++i)
                if (!reg.call("t.outer").ok) ++failures;
        });
    for (auto& th : threads) th.join();
    CHECK(failures == 0);
    CHECK(maxInside.load() == kThreads);  // the rendezvous guarantees all four handlers were open at the same time
    CHECK(hooks == kThreads * kCalls);    // every outermost call ran the hook once; no nested call did
}
