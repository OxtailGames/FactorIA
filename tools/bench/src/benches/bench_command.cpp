// Command dispatch benchmark: CommandRegistry::call with a registry the size of the engine's (about 300 commands).
#include <memory>
#include <string>
#include <vector>

#include "benches.h"
#include "fa/core/command.h"
#include "fa/core/json_schema.h"

namespace fa::bench {

namespace {

constexpr int kCommands = 300;
constexpr int kCalls = 20000;

Json bench_schema() {
    return Json::parse(R"({
        "type":"object",
        "properties":{
            "a":{"type":"number"},
            "b":{"type":"number","default":10},
            "name":{"type":"string"},
            "mode":{"type":"string","enum":["fast","exact"],"default":"fast"},
            "tags":{"type":"array","items":{"type":"string"}},
            "pos":{"type":"object","properties":{"x":{"type":"number"},"y":{"type":"number"}}}
        },
        "required":["a"],
        "additionalProperties":false})");
}

// The schema work of command.call on its own, with the schema as a Json (what call did before schemas were compiled at
// registration: every call walked the Json) or as a CompiledSchema.
Bench schema_validate(bool compiled) {
    Bench b;
    b.name = compiled ? "schema.compiled" : "schema.interpreted";
    b.summary = std::string("Defaults and validation of x20000 arguments against a command schema, on a ") +
                (compiled ? "CompiledSchema" : "Json schema") + "; every 50th set of arguments is refused";
    b.make = [compiled] {
        struct State {
            Json schema;
            CompiledSchema compiled;
            std::vector<Json> goodArgs;
            Json badArgs;
        };
        auto s = std::make_shared<State>();
        s->schema = close_object_schemas(bench_schema());
        s->compiled = CompiledSchema(s->schema);
        for (int i = 0; i < 16; ++i)
            s->goodArgs.push_back(Json::object({{"a", i},
                                                {"name", "entity" + std::to_string(i)},
                                                {"tags", Json::array({"x", "y", "z"})},
                                                {"pos", Json::object({{"x", 1.5}, {"y", double(i)}})}}));
        s->badArgs = Json::object({{"a", "not a number"}, {"colour", 3}});
        Prepared p;
        p.items = kCalls;
        p.unit = "validations";
        p.run = [s, compiled] {
            double sum = 0;
            for (int i = 0; i < kCalls; ++i) {
                Json args = i % 50 == 49 ? s->badArgs : s->goodArgs[std::size_t(i) % s->goodArgs.size()];
                if (compiled) {
                    apply_schema_defaults(s->compiled, args);
                    sum += double(validate_json(s->compiled, args).size());
                } else {
                    apply_schema_defaults(s->schema, args);
                    sum += double(validate_json(s->schema, args).size());
                }
            }
            return sum;
        };
        return p;
    };
    return b;
}

Bench command_call() {
    Bench b;
    b.name = "command.call";
    b.summary =
        "CommandRegistry::call x20000 over 300 commands: schema validation (compiled at registration), defaults, "
        "the handler; every 50th call is refused";
    b.make = [] {
        struct State {
            CommandRegistry reg;
            std::vector<std::string> names;
            std::vector<Json> goodArgs;
            Json badArgs;
        };
        auto s = std::make_shared<State>();
        const Json schema = bench_schema();
        for (int i = 0; i < kCommands; ++i) {
            CommandInfo info;
            info.name = "bench.cmd" + std::to_string(i);
            info.summary = "A command of the benchmark.";
            info.category = "bench";
            info.inputSchema = schema;
            s->names.push_back(info.name);
            s->reg.add(info, [](const Json& args) {
                return Json::object(
                    {{"sum", args["a"].get<double>() + args["b"].get<double>()}, {"mode", args["mode"]}});
            });
        }
        for (int i = 0; i < 16; ++i)
            s->goodArgs.push_back(Json::object({{"a", i},
                                                {"name", "entity" + std::to_string(i)},
                                                {"tags", Json::array({"x", "y", "z"})},
                                                {"pos", Json::object({{"x", 1.5}, {"y", double(i)}})}}));
        s->badArgs = Json::object({{"a", "not a number"}, {"colour", 3}});
        Prepared p;
        p.items = kCalls;
        p.unit = "calls";
        p.run = [s] {
            double sum = 0;
            for (int i = 0; i < kCalls; ++i) {
                const std::string& name = s->names[std::size_t(i * 7) % s->names.size()];
                if (i % 50 == 49) {
                    CommandResult r = s->reg.call(name, s->badArgs);
                    sum += r.ok ? 1000.0 : 1.0;
                } else {
                    CommandResult r = s->reg.call(name, s->goodArgs[std::size_t(i) % s->goodArgs.size()]);
                    sum += r.ok ? r.result["sum"].get<double>() : 1000.0;
                }
            }
            return sum;
        };
        return p;
    };
    return b;
}

}  // namespace

void add_command_benches(std::vector<Bench>& out) {
    out.push_back(command_call());
    out.push_back(schema_validate(false));
    out.push_back(schema_validate(true));
}

}  // namespace fa::bench
