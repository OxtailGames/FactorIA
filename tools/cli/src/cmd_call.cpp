// call, commands, api
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <map>
#include <sstream>

#include "common.h"
#include "fa/core/json.h"
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

std::unique_ptr<Session> open_tool_session(const Context& ctx, Gfx gfx, const SessionOptions* base = nullptr,
                                          std::size_t posIndex = 99) {
    std::string dir = find_project_dir_or_empty(ctx, posIndex);
    if (!dir.empty() && !fsys::exists(fsys::path(dir) / kProjectFileName))
        throw CliError("'" + dir + "' is not a FactorIA project: " + kProjectFileName + " not found.",
                       "Pass --project <folder containing factoria.json>, or run from inside a project.");
    SessionOptions so = base ? *base : SessionOptions{};
    so.gfx = gfx;
    auto s = Session::open(dir, so);
    register_cli_commands(s->registry(), s->project_dir(), &s->engine());
    return s;
}

// Flags shared by `call` and `session`: one engine, optionally pre-positioned.
const std::vector<FlagSpec>& engine_flags() {
    static const std::vector<FlagSpec> f = {
        {"project", "DIR", "Project folder (default: the project containing the current directory)."},
        {"scene", "PATH", "Start scene (default: the project's mainScene)."},
        {"seed", "N", "World RNG seed (default 1)."},
        {"frames-before", "N", "Step N headless frames before the first command."},
        {"press", "A,B", "Hold these actions/keys down before the first command (comma separated)."},
        {"input", "FILE", "Input replay JSON (see 'factoria run --help') applied while stepping; steps through its last frame unless --frames-before says otherwise."},
        {"no-graphics", "", "No GPU context (game.screenshot unavailable, faster start)."},
        {"render-all", "", "Draw every frame (default: only when a screenshot is taken)."},
        {"persist-storage", "", "Let scripts' storage.* read/write the real save file (default: in memory)."}};
    return f;
}

SessionOptions session_options(const Context& ctx) {
    SessionOptions so;
    so.scene = ctx.args.str("scene");
    so.seed = ctx.args.uinteger("seed", 1);
    so.gfx = ctx.args.has("no-graphics") ? Gfx::None : Gfx::Auto;
    so.renderMode = ctx.args.has("render-all") ? RenderMode::Always : RenderMode::OnDemand;
    so.memoryStorage = !ctx.args.has("persist-storage");
    return so;
}

// Applies --press / --input / --frames-before to a freshly opened session.
void prepare_session(Context& ctx, Session& session) {
    Engine& engine = session.engine();
    if (ctx.args.has("press")) {
        Json names = Json::array();
        for (const auto& part : split(ctx.args.str("press"), ',')) {
            std::string n(trim(part));
            if (!n.empty()) names.push_back(n);
        }
        CommandResult r = session.registry().call("game.input", Json::object({{"press", names}}));
        if (!r.ok) throw UsageError("--press: " + r.error.value("message", std::string("failed")), r.error.value("hint", std::string()));
    }
    int before = ctx.args.integer("frames-before", -1);
    if (ctx.args.has("input")) {
        auto rep = load_json_file(absolute_path(ctx.args.str("input")));
        if (!rep.ok()) throw CliError("Cannot read input replay: " + rep.error().to_string());
        const Json* frames = rep->is_object() && rep->contains("frames") ? &(*rep)["frames"] : nullptr;
        if (!frames || !frames->is_object())
            throw UsageError("Input replay must look like {\"frames\": {\"0\": {\"press\": [\"jump\"]}}}.");
        std::map<int, Json> entries;
        int last = 0;
        for (auto it = frames->begin(); it != frames->end(); ++it) {
            try {
                entries[std::stoi(it.key())] = *it;
                last = std::max(last, std::stoi(it.key()));
            } catch (...) {
                throw UsageError("Input replay frame key '" + it.key() + "' is not a number.");
            }
        }
        int total = before >= 0 ? before : last + 1;
        std::vector<std::string> problems;
        for (int f = 0; f < total; ++f) {
            if (auto e = entries.find(f); e != entries.end()) engine.apply_input_entry(e->second, problems, f);
            engine.step(1);
        }
        for (const auto& p : problems) ctx.err << "warning: " << p << "\n";
        return;
    }
    if (before > 0) engine.step(before);
}

void print_command_error(Context& ctx, const Json& error) {
    ctx.err << "error: " << error.value("code", std::string("failed")) << ": " << error.value("message", std::string()) << "\n";
    if (error.contains("hint") && error["hint"].is_string() && !error["hint"].get<std::string>().empty())
        ctx.err << "  hint: " << error["hint"].get<std::string>() << "\n";
    if (error.contains("data") && !error["data"].is_null()) ctx.err << "  data: " << error["data"].dump(2, ' ', false, Json::error_handler_t::replace) << "\n";
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
    c.summary = "Run engine commands on a headless engine and print the JSON result (one command, or a --batch).";
    c.usage = "<command> ['<json args>'] [options]   |   --batch '<json array>' | --batch-file F.json";
    c.details =
        "The same commands MCP exposes as tools (list them with 'factoria commands'). Arguments are a JSON object;\n"
        "use @args.json to read them from a file or - for stdin. Without a project in the current directory a scratch\n"
        "project is used, so docs.*, project.create etc. work anywhere. Failures print the error with its hint to\n"
        "stderr and exit 1. Images (game.screenshot) are returned as file paths.\n\n"
        "Every call starts a NEW engine, so state does not carry over between calls. To act on one running game use:\n"
        "  --batch '[{\"command\":\"game.step\",\"args\":{\"frames\":30}},{\"command\":\"script.eval\",\"args\":{\"code\":\"1+1\"}}]'\n"
        "(commands run in order on ONE engine; prints {ok, results:[{ok,result|error}]}; stops at the first failure\n"
        "unless --keep-going; exit 1 if any failed), or 'factoria session' for an interactive JSON-lines loop.\n"
        "--scene, --press and --input position the game before the first command.";
    c.maxPositional = 2;
    c.flags = engine_flags();
    c.flags.push_back({"batch", "JSON", "Array of {\"command\", \"args\"} to run in order on one engine (instead of a positional command)."});
    c.flags.push_back({"batch-file", "FILE", "Same as --batch, read from a file ('-' = stdin)."});
    c.flags.push_back({"json", "", "On a failed single command also print {\"ok\":false,\"error\":{code,message,hint,data}} on stdout (batch always does)."});
    c.flags.push_back({"keep-going", "", "Batch: continue after a failed command."});
    c.examples = {"factoria call scene.list_entities",
                  "factoria call scene.spawn '{\"name\":\"Enemy\",\"components\":{\"Transform\":{\"position\":[100,50,0]}}}'",
                  "factoria call game.screenshot '{\"path\":\"/tmp/s.png\"}' --frames-before 60",
                  "factoria call game.state --scene scenes/level2.scene.json --press move_right --frames-before 30",
                  "factoria call --batch '[{\"command\":\"game.step\",\"args\":{\"frames\":30}},{\"command\":\"script.eval\",\"args\":{\"code\":\"game.time\"}}]'",
                  "factoria call docs.search '{\"query\":\"collision\"}'"};
    c.run = [](Context& ctx) {
        const bool batch = ctx.args.has("batch") || ctx.args.has("batch-file");
        if (!batch && ctx.args.positional().empty())
            throw UsageError("Missing command name.", "Usage: factoria call <command> ['<json>']  or  factoria call --batch '[...]'. List commands with 'factoria commands'.");
        if (batch && ctx.args.has("batch") && ctx.args.has("batch-file")) throw UsageError("Use --batch or --batch-file, not both.");
        Json requests = Json::array();
        if (batch) {
            if (!ctx.args.positional().empty()) throw UsageError("--batch replaces the positional command.", "Put every command in the batch array.");
            std::string body;
            if (ctx.args.has("batch")) {
                body = ctx.args.str("batch");
                if (body == "-") body = read_all(ctx.in);
                else if (!body.empty() && body[0] == '@') {
                    std::ifstream f(body.substr(1), std::ios::binary);
                    if (!f) throw UsageError("Cannot read batch file '" + body.substr(1) + "'.");
                    body = read_all(f);
                }
            } else {
                std::string file = ctx.args.str("batch-file");
                if (file == "-") body = read_all(ctx.in);
                else {
                    std::ifstream f(absolute_path(file), std::ios::binary);
                    if (!f) throw UsageError("Cannot read batch file '" + file + "'.");
                    body = read_all(f);
                }
            }
            auto j = parse_json(body, "<batch>");
            if (!j.ok()) throw UsageError("--batch is not valid JSON: " + j.error().message,
                                          "Example: --batch '[{\"command\":\"game.step\",\"args\":{\"frames\":30}}]'");
            if (!j->is_array()) throw UsageError("--batch must be a JSON array of {\"command\", \"args\"} objects, got " + describe_json_value(*j) + ".");
            requests = *j;
        } else {
            requests.push_back(Json::object({{"command", ctx.args.pos(0)}, {"args", parse_call_args(ctx, ctx.args.pos(1))}}));
        }
        ToolSession ts;
        SessionOptions so = session_options(ctx);
        ts.session = open_tool_session(ctx, so.gfx, &so);
        prepare_session(ctx, *ts.session);
        if (!batch) {
            Json out = run_command_json(ts.session->registry(), requests[0]);
            if (!out["ok"].get<bool>()) {
                print_command_error(ctx, out["error"]);
                if (ctx.args.has("json")) print_json(ctx.out, out);  // {ok:false, error:{code,message,hint,data}}
                return 1;
            }
            print_json(ctx.out, out["result"]);
            return 0;
        }
        Json results = Json::array();
        bool allOk = true;
        for (const Json& req : requests) {
            Json out = run_command_json(ts.session->registry(), req);
            results.push_back(out);
            if (!out["ok"].get<bool>()) {
                allOk = false;
                print_command_error(ctx, out["error"]);
                if (!ctx.args.has("keep-going")) break;
            }
        }
        print_json(ctx.out, Json::object({{"ok", allOk}, {"results", results}}));
        return allOk ? 0 : 1;
    };
    return c;
}

Command make_session_command() {
    Command c;
    c.name = "session";
    c.summary = "Interactive JSON-lines loop on ONE engine: a request per stdin line, a result per stdout line (no MCP needed).";
    c.usage = "[project] [options]";
    c.details =
        "Starts a headless engine for the project and reads one JSON request per line from stdin:\n"
        "  {\"command\": \"game.step\", \"args\": {\"frames\": 30}}\n"
        "and answers with one line of JSON on stdout:\n"
        "  {\"ok\": true, \"result\": {...}}   or   {\"ok\": false, \"error\": {\"code\", \"message\", \"hint\"}}\n"
        "State persists between lines (the game keeps running), so an AI without MCP can step, poke and inspect the\n"
        "same game. A line may also be an array of requests (answered with an array). The first line printed is\n"
        "{\"ready\": true, ...}. Stops at EOF or on {\"command\": \"session.quit\"}. Logs go to stderr.";
    c.maxPositional = 1;
    c.flags = engine_flags();
    c.examples = {"printf '%s\\n' '{\"command\":\"game.step\",\"args\":{\"frames\":30}}' '{\"command\":\"game.state\"}' | factoria session",
                  "factoria session games/my-game --scene scenes/level2.scene.json"};
    c.run = [](Context& ctx) {
        ToolSession ts;
        SessionOptions so = session_options(ctx);
        ts.session = open_tool_session(ctx, so.gfx, &so, 0);
        prepare_session(ctx, *ts.session);
        CommandRegistry& reg = ts.session->registry();
        auto emit = [&](const Json& j) { ctx.out << j.dump() << "\n" << std::flush; };
        emit(Json::object({{"ready", true}, {"project", ts.session->project_dir()}, {"graphics", ts.session->has_graphics()},
                           {"frame", ts.session->engine().frame_index()}, {"commands", reg.list().size()}}));
        std::string line;
        while (std::getline(ctx.in, line)) {
            if (!line.empty() && line.back() == '\r') line.pop_back();
            if (line.find_first_not_of(" \t") == std::string::npos) continue;
            auto j = parse_json(line, "<session line>");
            if (!j.ok()) {
                emit(Json::object({{"ok", false}, {"error", Json::object({{"code", "invalid_json"}, {"message", j.error().message},
                                    {"hint", "Send one JSON object per line: {\"command\":\"game.step\",\"args\":{\"frames\":1}}"}})}}));
                continue;
            }
            bool quit = false;
            auto handle = [&](const Json& req) {
                if (req.is_object() && req.value("command", std::string()) == "session.quit") {
                    quit = true;
                    return Json::object({{"ok", true}, {"result", Json::object({{"bye", true}})}});
                }
                return run_command_json(reg, req);
            };
            if (j->is_array()) {
                Json outs = Json::array();
                for (const Json& req : *j) {
                    outs.push_back(handle(req));
                    if (quit) break;
                }
                emit(outs);
            } else {
                emit(handle(*j));
            }
            if (quit) break;
        }
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
