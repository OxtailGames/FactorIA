// call, commands, api
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <map>
#include <sstream>

#include "common.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/scene/serialize.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/validate.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

// Opens a session with every CLI command registered. Empty project => scratch project.
struct ToolSession {
    std::unique_ptr<Session> session;
    ~ToolSession() { set_script_check_hook(nullptr); }
};

std::unique_ptr<Session> open_tool_session(const Context& ctx, Gfx gfx, const SessionOptions* base = nullptr) {
    std::string dir = find_project_dir_or_empty(ctx, 99);
    if (!dir.empty() && !fsys::exists(fsys::path(dir) / kProjectFileName))
        throw CliError("'" + dir + "' is not a FactorIA project: " + kProjectFileName + " not found.",
                       "Pass --project <folder containing factoria.json>, or run from inside a project.");
    SessionOptions so = base ? *base : SessionOptions{};
    so.gfx = gfx;
    auto s = Session::open(dir, so);
    register_cli_commands(s->registry(), s->project_dir(), &s->engine());
    install_script_check(s->engine());
    return s;
}

std::string read_all(std::istream& in) { return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>()); }

Json parse_call_args(Context& ctx, const std::string& text) {
    if (text.empty()) return Json::object();
    std::string body = text;
    if (text == "-") {
        body = read_all(ctx.in);
    } else if (text[0] == '@') {
        std::ifstream f(text.substr(1), std::ios::binary);
        if (!f) throw UsageError("Cannot read arguments file '" + text.substr(1) + "'.");
        body = read_all(f);
    }
    auto j = parse_json(body, "<command arguments>");
    if (!j.ok()) throw UsageError("Command arguments are not valid JSON: " + j.error().message,
                                  "Quote the JSON for your shell, e.g. '{\"name\":\"Enemy\"}'; or pass @file.json / - (stdin).");
    if (!j->is_object()) throw UsageError("Command arguments must be a JSON object, got " + describe_json_value(*j) + ".");
    return *j;
}

void write_file(const std::string& path, const std::string& text) {
    std::error_code ec;
    if (fsys::path(path).has_parent_path()) fsys::create_directories(fsys::path(path).parent_path(), ec);
    std::ofstream f(path, std::ios::binary);
    if (!f) throw CliError("Cannot write '" + path + "'.", "Check the folder exists and is writable.");
    f << text;
}

}  // namespace

Command make_call_command() {
    Command c;
    c.name = "call";
    c.summary = "Run any engine command on a headless engine and print the JSON result.";
    c.usage = "<command> ['<json args>'] [--project DIR] [--frames-before N]";
    c.details =
        "The same commands MCP exposes as tools (list them with 'factoria commands'). Arguments are a JSON object;\n"
        "use @args.json to read them from a file or - for stdin. Without a project in the current directory a scratch\n"
        "project is used, so docs.*, project.create etc. work anywhere. Failures print the error with its hint to\n"
        "stderr and exit 1. Images (game.screenshot) are returned as file paths.";
    c.maxPositional = 2;
    c.flags = {{"project", "DIR", "Project folder (default: the project containing the current directory)."},
               {"scene", "PATH", "Start scene override."},
               {"frames-before", "N", "Step N headless frames before running the command."},
               {"seed", "N", "World RNG seed (default 1)."}};
    c.examples = {"factoria call scene.list_entities",
                  "factoria call scene.spawn '{\"name\":\"Enemy\",\"components\":{\"Transform2D\":{\"position\":[100,50]}}}'",
                  "factoria call game.screenshot '{\"path\":\"/tmp/s.png\"}' --frames-before 60",
                  "factoria call docs.search '{\"query\":\"collision\"}'"};
    c.run = [](Context& ctx) {
        if (ctx.args.positional().empty())
            throw UsageError("Missing command name.", "Usage: factoria call <command> ['<json>']. List commands with 'factoria commands'.");
        std::string name = ctx.args.pos(0);
        Json args = parse_call_args(ctx, ctx.args.pos(1));
        SessionOptions so;
        so.scene = ctx.args.str("scene");
        so.seed = ctx.args.uinteger("seed", 1);
        ToolSession ts;
        ts.session = open_tool_session(ctx, Gfx::Auto, &so);
        int before = ctx.args.integer("frames-before", 0);
        if (before > 0) ts.session->engine().step(before);
        CommandResult r = ts.session->registry().call(name, args);
        if (!r.ok) {
            ctx.err << "error: " << r.error.value("code", std::string("failed")) << ": " << r.error.value("message", std::string()) << "\n";
            if (r.error.contains("hint") && !r.error["hint"].get<std::string>().empty()) ctx.err << "  hint: " << r.error["hint"].get<std::string>() << "\n";
            return 1;
        }
        print_json(ctx.out, r.result);
        return 0;
    };
    return c;
}

Command make_commands_command() {
    Command c;
    c.name = "commands";
    c.summary = "List the engine commands (the tools MCP and the AI agent get).";
    c.usage = "[prefix-or-name] [--project DIR] [--json]";
    c.details = "With a prefix (scene) lists that area; with an exact name (scene.spawn) shows its description and argument schema.";
    c.maxPositional = 1;
    c.flags = {{"project", "DIR", "Project folder (default: the project containing the current directory)."},
               {"json", "", "Machine-readable list (name, summary, description, inputSchema, readOnly, category)."}};
    c.examples = {"factoria commands", "factoria commands scene", "factoria commands scene.spawn", "factoria commands --json"};
    c.run = [](Context& ctx) {
        ToolSession ts;
        ts.session = open_tool_session(ctx, Gfx::None);
        CommandRegistry& reg = ts.session->registry();
        std::string filter = ctx.args.pos(0);
        if (!filter.empty() && reg.has(filter)) {
            const CommandInfo* info = reg.info(filter);
            if (ctx.args.has("json")) {
                print_json(ctx.out, Json::object({{"name", info->name}, {"summary", info->summary}, {"description", info->description},
                                                  {"inputSchema", info->inputSchema}, {"readOnly", info->readOnly}, {"category", info->category}}));
                return 0;
            }
            ctx.out << info->name << " - " << info->summary << (info->readOnly ? "" : "  [modifies state]") << "\n\n"
                    << info->description << "\n\nArguments (JSON schema):\n" << info->inputSchema.dump(2) << "\n";
            return 0;
        }
        Json all = Json::array();
        std::map<std::string, std::vector<const CommandInfo*>> byCat;
        std::vector<std::string> names;
        for (const CommandInfo* i : reg.list()) {
            names.push_back(i->name);
            if (!filter.empty() && !starts_with(i->name, filter) && !starts_with(i->name, filter + ".")) continue;
            byCat[i->category.empty() ? "other" : i->category].push_back(i);
            all.push_back(Json::object({{"name", i->name}, {"summary", i->summary}, {"description", i->description},
                                        {"inputSchema", i->inputSchema}, {"readOnly", i->readOnly}, {"category", i->category}}));
        }
        if (all.empty()) return report_failure(ctx.err, "No command matches '" + filter + "'.", fa::did_you_mean(filter, names));
        if (ctx.args.has("json")) {
            print_json(ctx.out, all);
            return 0;
        }
        for (const auto& [cat, list] : byCat) {
            ctx.out << cat << ":\n";
            for (const CommandInfo* i : list) ctx.out << "  " << i->name << (i->readOnly ? "" : " *") << "  " << i->summary << "\n";
        }
        ctx.out << "\n(* modifies state)  Details: factoria commands <name>   Run: factoria call <name> '<json>'\n";
        return 0;
    };
    return c;
}

Command make_api_command() {
    Command c;
    c.name = "api";
    c.summary = "Print the engine API: components, commands and the scripting API (Markdown, JSON, .d.ts, schemas).";
    c.usage = "[--md | --json | --dts | --schema scene|prefab|project] [--out FILE] [--project DIR]";
    c.details =
        "--dts writes the TypeScript declarations scripts are type-checked against. With --project (and no --out)\n"
        "it writes <project>/types/factoria.d.ts. --md is the default.";
    c.maxPositional = 0;
    c.flags = {{"md", "", "Markdown reference (default)."},
               {"json", "", "JSON: {components, commands, scripting}."},
               {"dts", "", "TypeScript declarations for scripts."},
               {"schema", "KIND", "JSON Schema of scene, prefab or project files."},
               {"out", "FILE", "Write to FILE instead of stdout."},
               {"project", "DIR", "Project folder (for --dts: writes types/factoria.d.ts there)."}};
    c.examples = {"factoria api", "factoria api --json --out api.json", "factoria api --dts --project games/my-game",
                  "factoria api --schema scene --out scene.schema.json"};
    c.run = [](Context& ctx) {
        const Args& a = ctx.args;
        int modes = int(a.has("md")) + int(a.has("json")) + int(a.has("dts")) + int(a.has("schema"));
        if (modes > 1) throw UsageError("Choose one of --md, --json, --dts, --schema.");
        std::string text;
        std::string out = a.has("out") ? absolute_path(a.str("out")) : "";
        if (a.has("schema")) {
            std::string kind = a.str("schema");
            Json schema;
            if (kind == "scene") schema = scene_json_schema();
            else if (kind == "prefab") schema = prefab_json_schema();
            else if (kind == "project") schema = project_json_schema();
            else throw UsageError("Unknown schema '" + kind + "'.", "Valid: scene, prefab, project.");
            text = dump_json(schema);
        } else {
            ToolSession ts;
            ts.session = open_tool_session(ctx, Gfx::None);
            Session& s = *ts.session;
            if (a.has("dts")) {
                text = s.engine().scripts().typescript_declarations();
                if (out.empty() && !s.scratch() && a.has("project")) out = (fsys::path(s.project_dir()) / "types" / "factoria.d.ts").string();
            } else if (a.has("json")) {
                Json j = Json::object();
                j["components"] = export_components_json();
                j["commands"] = export_commands_json(s.registry());
                j["scripting"] = s.engine().scripts().api_manifest();
                text = dump_json(j);
            } else {
                text = export_components_markdown() + "\n" + export_commands_markdown(s.registry()) +
                       "\n## Scripting API (TypeScript declarations)\n\n```ts\n" + s.engine().scripts().typescript_declarations() + "\n```\n";
            }
        }
        if (out.empty()) {
            ctx.out << text;
            if (text.empty() || text.back() != '\n') ctx.out << "\n";
        } else {
            write_file(out, text);
            ctx.out << "Wrote " << out << " (" << text.size() << " bytes)\n";
        }
        return 0;
    };
    return c;
}

}  // namespace fa::cli
