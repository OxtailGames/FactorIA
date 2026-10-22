// script.trace (fa/tooling/script_trace.h): a headless run whose DebugClient records every traced line instead of stopping.
#include "fa/tooling/script_trace.h"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <cmath>
#include <filesystem>
#include <format>
#include <map>
#include <memory>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/platform/app.h"
#include "fa/runtime/engine.h"
#include "fa/script/debugger.h"
#include "fa/tooling/script_instrument.h"
#include "headless_run.h"
#include "util.h"

namespace fa {

namespace {

namespace stdfs = std::filesystem;

constexpr int kDefaultFrames = 300;
constexpr int kDefaultMaxHits = 20;
constexpr int kDefaultDepth = 1;
constexpr int kMaxDepth = 6;
constexpr int kMaxChildren = 100;  // entries of one object or array that `depth` expands

// ------------------------------------------------------------------------------------------------ values as JSON
bool is_index(const std::string& s) {
    return !s.empty() && std::all_of(s.begin(), s.end(), [](unsigned char c) { return std::isdigit(c) != 0; });
}

// A variable as JSON: numbers stay numbers, strings strings, booleans booleans, null null. An object or function is
// expanded into JSON while `depth` > 0 (arrays become JSON arrays); deeper, and everything else (undefined, symbols,
// BigInt, NaN) is its short preview as a string.
Json value_json(PausedScripts& ps, const DebugValue& v, int depth) {
    if (v.type == "number") {
        double d = 0;
        const char* b = v.value.data();
        const char* e = b + v.value.size();
        auto r = std::from_chars(b, e, d);
        if (r.ec == std::errc() && r.ptr == e && std::isfinite(d)) {
            if (d == std::floor(d) && std::fabs(d) < 9e15 && !(d == 0 && std::signbit(d))) return Json(static_cast<std::int64_t>(d));
            return Json(d);
        }
        return Json(v.value);  // NaN, Infinity, -0
    }
    if (v.type == "string") {
        Json s = Json::parse(v.value, nullptr, false);
        return s.is_string() ? s : Json(v.value);
    }
    if (v.type == "boolean") return Json(v.value == "true");
    if (v.type == "null") return Json(nullptr);
    if (v.variablesReference > 0 && depth > 0) {
        std::vector<DebugValue> kids = ps.variables(v.variablesReference, 0, kMaxChildren + 1);
        const bool more = static_cast<int>(kids.size()) > kMaxChildren;
        if (more) kids.resize(kMaxChildren);
        kids.erase(std::remove_if(kids.begin(), kids.end(), [](const DebugValue& k) { return k.name == "[[Prototype]]"; }), kids.end());
        const bool array = !kids.empty() && std::all_of(kids.begin(), kids.end(), [](const DebugValue& k) { return is_index(k.name); });
        Json out = array ? Json::array() : Json::object();
        for (const DebugValue& k : kids) {
            Json child = value_json(ps, k, depth - 1);
            if (array) out.push_back(std::move(child));
            else out[k.name] = std::move(child);
        }
        if (more) {
            const std::string note = std::format("... more than {} entries, not shown", kMaxChildren);
            if (array) out.push_back(note);
            else out["..."] = note;
        }
        return out;
    }
    return Json(v.value);
}

// ------------------------------------------------------------------------------------------------ the recording client
struct TracePoint {
    std::string file, condition, log;
    std::vector<std::string> watch;
    int line = 0;          // as asked
    int resolvedLine = 0;  // where the hook is
    int hits = 0;          // recorded hits (or log lines)
    bool active = true;
};

class TraceClient final : public DebugClient {
public:
    std::vector<TracePoint> points;
    int maxHits = kDefaultMaxHits;
    int depth = kDefaultDepth;
    ScriptDebugger* debugger = nullptr;

    Json hits = Json::array(), logs = Json::array(), errors = Json::array();
    bool truncated = false;

    // Sends the active points of `file` to the debugger (it replaces the file's breakpoints) and remembers which
    // breakpoint id is which point. Returns the breakpoint states, in the order of `used`.
    std::vector<DebugBreakpointState> apply(const std::string& file, std::vector<int>* used = nullptr) {
        std::vector<DebugBreakpoint> bps;
        std::vector<int> order;
        for (std::size_t i = 0; i < points.size(); ++i) {
            const TracePoint& p = points[i];
            if (p.file != file || !p.active) continue;
            DebugBreakpoint bp;
            bp.line = p.line;
            bp.condition = p.condition;
            bp.logMessage = p.log;
            bps.push_back(std::move(bp));
            order.push_back(static_cast<int>(i));
        }
        std::vector<DebugBreakpointState> states = debugger->set_breakpoints(file, bps);
        for (std::size_t k = 0; k < states.size() && k < order.size(); ++k) {
            idToPoint_[states[k].id] = order[k];
            if (states[k].verified) points[static_cast<std::size_t>(order[k])].resolvedLine = states[k].line;
        }
        if (used) *used = order;
        return states;
    }

    DebugResume paused(const DebugStop& stop, PausedScripts& scripts) override {
        if (stop.hitBreakpointIds.empty()) {  // a condition that threw stops with no breakpoint: that is an error to report
            if (!stop.description.empty()) add_error(stop.description);
            return DebugResume::Continue;
        }
        std::set<std::string> changed;
        std::vector<DebugFrame> stack;
        for (int id : stop.hitBreakpointIds) {
            auto it = idToPoint_.find(id);
            if (it == idToPoint_.end()) continue;
            TracePoint& p = points[static_cast<std::size_t>(it->second)];
            if (!p.active) continue;
            if (p.hits >= maxHits) {  // one more than asked: there is more to see, so say so and stop recording this point
                truncated = true;
                p.active = false;
                changed.insert(p.file);
                continue;
            }
            ++p.hits;
            if (stack.empty()) stack = scripts.stack();
            if (stack.empty()) continue;
            hits.push_back(record(it->second, p, stack, scripts));
        }
        for (const std::string& f : changed) apply(f);
        return DebugResume::Continue;
    }

    void output(std::string_view category, std::string_view text, const std::string& file, int line) override {
        if (category == "console") {
            std::set<std::string> changed;
            const int frameNow = std::max(frame_, 0);
            bool counted = false;
            for (TracePoint& p : points) {
                if (!p.active || p.log.empty() || p.file != file || p.resolvedLine != line) continue;
                if (!counted) {
                    counted = true;
                    if (p.hits >= maxHits) {
                        truncated = true;
                        for (TracePoint& q : points)
                            if (q.active && !q.log.empty() && q.file == file && q.resolvedLine == line) {
                                q.active = false;
                                changed.insert(q.file);
                            }
                        break;
                    }
                    ++p.hits;
                    logs.push_back(Json::object({{"frame", frameNow}, {"file", file}, {"line", line}, {"text", std::string(text)}}));
                }
            }
            for (const std::string& f : changed) apply(f);
        } else if (category == "stderr" && text.rfind("Breakpoint condition", 0) == 0) {
            add_error((file.empty() ? std::string() : file + ":" + std::to_string(line) + ": ") + std::string(text));
        }
    }

    void poll(ScriptSystem&) override { ++frame_; }

private:
    int frame_ = -1;  // the frame being simulated: poll runs at the start of each one
    std::map<int, int> idToPoint_;

    void add_error(const std::string& text) {
        for (const Json& e : errors)
            if (e == text) return;
        errors.push_back(text);
    }

    Json record(int pointIndex, const TracePoint& p, const std::vector<DebugFrame>& stack, PausedScripts& scripts) {
        const DebugFrame& top = stack.front();
        Json stackJson = Json::array();
        for (const DebugFrame& f : stack) stackJson.push_back(std::format("{} {}:{}", f.name, f.file, f.line));
        Json locals = Json::object();
        std::vector<DebugScope> scopes = scripts.scopes(top.id);
        if (!scopes.empty())
            for (const DebugValue& v : scripts.variables(scopes.front().variablesReference, 0, 0)) locals[v.name] = value_json(scripts, v, depth);
        Json watch = Json::object();
        for (const std::string& expr : p.watch) {
            auto r = scripts.evaluate(top.id, expr);
            watch[expr] = r.ok() ? value_json(scripts, *r, depth) : Json("<error: " + r.error().message + ">");
        }
        return Json::object({{"point", pointIndex}, {"frame", std::max(frame_, 0)}, {"file", top.file}, {"line", top.line},
                             {"function", top.name}, {"stack", stackJson}, {"locals", locals}, {"watch", watch}});
    }
};

// ------------------------------------------------------------------------------------------------ validation
std::vector<std::string> project_scripts(const std::string& projectDir) {
    std::vector<std::string> out;
    std::error_code ec;
    stdfs::path root(fs::os_path(projectDir));
    for (stdfs::recursive_directory_iterator it(root, stdfs::directory_options::skip_permission_denied, ec), end; !ec && it != end;
         it.increment(ec)) {
        const std::string name = it->path().filename().string();
        if (it->is_directory(ec)) {
            if (name.starts_with(".") || name == "node_modules" || name == "build" || name == "export") it.disable_recursion_pending();
            continue;
        }
        const std::string ext = it->path().extension().string();
        if (it->is_regular_file(ec) && (ext == ".js" || ext == ".mjs")) out.push_back(stdfs::relative(it->path(), root, ec).generic_string());
    }
    std::sort(out.begin(), out.end());
    return out;
}

[[noreturn]] void bad(const std::string& pointer, const std::string& message, const std::string& hint) {
    throw CommandError("invalid_argument", pointer + ": " + message, hint);
}

Json require_object(const Json& j, const std::string& pointer, const char* what) {
    if (!j.is_object()) bad(pointer, std::string("must be an object (") + what + ").", "Example: {\"file\":\"scripts/player.js\",\"line\":17}.");
    return j;
}

void check_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& known) {
    for (auto it = obj.begin(); it != obj.end(); ++it)
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            bad(pointer + "/" + tooling_detail::escape_token(it.key()), "unknown field '" + it.key() + "'.", did_you_mean(it.key(), known));
}

int int_arg(const Json& a, const char* key, int def, int min, int max, const char* why) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) return def;
    if (!it->is_number_integer() || it->get<long long>() < min || it->get<long long>() > max)
        bad(std::string("/") + key, std::string("must be an integer from ") + std::to_string(min) + " to " + std::to_string(max) + ".", why);
    return it->get<int>();
}

std::string string_field(const Json& obj, const char* key, const std::string& pointer) {
    auto it = obj.find(key);
    if (it == obj.end() || it->is_null()) return {};
    if (!it->is_string()) bad(pointer + "/" + key, "must be a string.", "Example: \"this.body.velocity.y > 0\".");
    return it->get<std::string>();
}

// Reads and checks "points". Every problem names the JSON pointer of the value to fix.
std::vector<TracePoint> parse_points(const Json& args, const std::string& projectDir) {
    auto it = args.find("points");
    if (it == args.end() || !it->is_array() || it->empty())
        bad("/points", "give at least one point: an array of {file, line, condition?, watch?, log?}.",
            "Example: {\"points\":[{\"file\":\"scripts/player.js\",\"line\":17,\"watch\":[\"dt\"]}],\"frames\":120}.");
    std::vector<std::string> scripts;
    bool scriptsListed = false;
    std::map<std::string, std::vector<int>> breakable;  // per file
    std::vector<TracePoint> points;
    for (std::size_t i = 0; i < it->size(); ++i) {
        const std::string at = "/points/" + std::to_string(i);
        const Json p = require_object((*it)[i], at, "one traced line");
        check_keys(p, at, {"file", "line", "condition", "watch", "log"});
        TracePoint tp;
        tp.file = string_field(p, "file", at);
        std::replace(tp.file.begin(), tp.file.end(), '\\', '/');
        if (tp.file.starts_with("./")) tp.file = tp.file.substr(2);
        if (tp.file.empty()) bad(at + "/file", "is required: the project-relative script to trace.", "Example: \"scripts/player.js\".");

        const bool escapes = tp.file.starts_with("/") || tp.file.find("..") != std::string::npos;
        std::error_code ec;
        const stdfs::path onDisk = stdfs::path(fs::os_path(projectDir)) / tp.file;
        if (escapes || !stdfs::is_regular_file(onDisk, ec)) {
            if (!scriptsListed) {
                scripts = project_scripts(projectDir);
                scriptsListed = true;
            }
            bad(at + "/file", "'" + tp.file + "' is not a script of this project. " + did_you_mean(tp.file, scripts),
                "Use the project-relative path of a script (see fs.list), e.g. scripts/player.js.");
        }

        auto lineIt = p.find("line");
        if (lineIt == p.end() || !lineIt->is_number_integer() || lineIt->get<long long>() < 1)
            bad(at + "/line", "must be an integer >= 1 (1-based) naming a line of " + tp.file + " that starts a statement.",
                "Open the file with fs.read to see its line numbers.");
        tp.line = lineIt->get<int>();

        auto b = breakable.find(tp.file);
        if (b == breakable.end()) {
            auto text = fs::read_text(onDisk.generic_string());
            if (!text.ok()) bad(at + "/file", "cannot read '" + tp.file + "': " + text.error().message, text.error().hint);
            auto inst = instrument_script(tp.file, *text, -1);
            if (!inst.ok())
                bad(at + "/file", tp.file + " does not parse, so it cannot be traced: " + inst.error().message,
                    "Fix the syntax error first (project.validate reports it too).");
            b = breakable.emplace(tp.file, inst->info.breakable_lines()).first;
        }
        const std::vector<int>& lines = b->second;
        if (!std::binary_search(lines.begin(), lines.end(), tp.line)) {
            auto next = std::upper_bound(lines.begin(), lines.end(), tp.line);
            std::string near;
            if (next != lines.begin()) near = "line " + std::to_string(*(next - 1));
            if (next != lines.end()) near += (near.empty() ? "line " : " and line ") + std::to_string(*next);
            if (near.empty()) near = "none: the file has no statements";
            bad(at + "/line", tp.file + ":" + std::to_string(tp.line) + " has no statement to stop on (blank, a comment, the middle of a statement or a declaration header). Nearest lines that do: " + near + ".",
                "Pick one of those lines; a statement starts a line such as 'this.x = 1;' or 'if (...) {'.");
        }
        tp.resolvedLine = tp.line;

        tp.condition = string_field(p, "condition", at);
        tp.log = string_field(p, "log", at);
        if (auto w = p.find("watch"); w != p.end() && !w->is_null()) {
            if (!w->is_array()) bad(at + "/watch", "must be an array of JavaScript expressions.", "Example: [\"this.body.velocity\",\"dt\"].");
            for (std::size_t k = 0; k < w->size(); ++k) {
                if (!(*w)[k].is_string())
                    bad(at + "/watch/" + std::to_string(k), "must be a string (a JavaScript expression).", "Example: \"this.body.velocity\".");
                tp.watch.push_back((*w)[k].get<std::string>());
            }
        }
        points.push_back(std::move(tp));
    }
    return points;
}

Json run_trace(const Json& args, const std::string& projectDir) {
    tooling_detail::require_project_dir(projectDir, "script.trace");
    check_keys(args, "", {"points", "frames", "input", "scene", "maxHits", "depth"});
    const int frames = int_arg(args, "frames", kDefaultFrames, 1, 1000000, "Run a few hundred frames, e.g. 300.");
    const int maxHits = int_arg(args, "maxHits", kDefaultMaxHits, 1, 100000, "A few dozen hits are enough to see a pattern; use a condition to narrow.");
    const int depth = int_arg(args, "depth", kDefaultDepth, 0, kMaxDepth, "0 = previews only, 1 = one level of fields (the default), up to 6.");
    const std::string input = tooling_detail::arg_string(args, "input", false);
    const std::string scene = tooling_detail::arg_string(args, "scene", false);

    auto client = std::make_unique<TraceClient>();
    client->points = parse_points(args, projectDir);
    client->maxHits = maxHits;
    client->depth = depth;
    auto debugger = std::make_shared<ScriptDebugger>(*client, script_instrumenter(), projectDir);
    client->debugger = debugger.get();

    std::vector<std::string> files;
    for (const TracePoint& p : client->points)
        if (std::find(files.begin(), files.end(), p.file) == files.end()) files.push_back(p.file);
    for (const std::string& f : files) {
        std::vector<int> used;
        auto states = client->apply(f, &used);
        for (std::size_t k = 0; k < states.size(); ++k)
            if (!states[k].verified)
                bad("/points/" + std::to_string(used[k]) + "/line", f + ":" + std::to_string(client->points[static_cast<std::size_t>(used[k])].line) + ": " + states[k].message,
                    "Pick a line that starts a statement.");
    }

    // The run starts its own engine; a process that already has a GPU device (the editor, a window) gets one without graphics,
    // because sokol allows one device per process. Scripts do not need the renderer to run (only to read camera helpers).
    EngineConfig cfg = tooling_detail::headless_engine_config(projectDir, scene, !gfx_device_active(), RenderMode::OnDemand);
    cfg.scriptDebugger = debugger;
    HeadlessRunOptions ho;
    ho.frames = frames;
    ho.failOnScriptError = false;
    if (!input.empty()) ho.inputReplayPath = tooling_detail::project_path(projectDir, input);
    Json report;
    const int code = run_headless(cfg, ho, &report);
    if (code != 0 || !report.contains("frames")) {
        throw CommandError("failed", "The traced run did not finish cleanly (exit code " + std::to_string(code) + "): " + report.value("error", std::string("see problems")),
                           "Run 'factoria run --headless --frames " + std::to_string(frames) + "' to see the problem.");
    }

    Json errors = Json::array();
    for (const char* key : {"scriptErrors", "sceneErrors", "problems"})
        if (report.contains(key) && report[key].is_array())
            for (const Json& e : report[key]) errors.push_back(e);
    for (const Json& e : client->errors) errors.push_back(e);
    return Json::object({{"hits", client->hits}, {"logs", client->logs}, {"errors", errors},
                         {"framesRun", report.value("frames", 0)}, {"truncated", client->truncated}});
}

}  // namespace

void register_script_trace_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo c;
    c.name = "script.trace";
    c.category = "script";
    c.readOnly = true;
    c.summary = "Debug scripts: run the game headless and record the stack, locals and watch expressions each time chosen lines run.";
    c.description =
        "The way to find out WHY a script misbehaves without an IDE. Runs the project headless for `frames` fixed steps (a second engine in this process, fake platform, in-memory storage, fixed dt: the same "
        "input gives the same answer) with the scripts instrumented, and at each traced line records what is there instead of stopping. A point is {file, line, condition?, watch?, log?}: "
        "`file` a project-relative script, `line` a line that starts a statement (an error names the nearest ones when it does not), `condition` a JavaScript expression that must be true for the point to record, "
        "`watch` expressions evaluated at every hit, `log` a message with {expression} parts that turns the point into a logpoint (it writes into `logs` and records no hit; cheaper than a hit with locals). "
        "Returns {hits: [{point (index in points), frame (0-based fixed frame), file, line, function (e.g. Player.onUpdate), stack (innermost first, \"fn file:line\"), locals: {name: value}, watch: {expression: value}}], "
        "logs: [{frame, file, line, text}], errors (script errors raised during the run, scene problems, conditions that threw), framesRun, truncated}. Values are JSON: numbers, strings and booleans as such; "
        "objects are expanded `depth` levels (0 = a short preview string, 1 = the fields as JSON with nested objects as previews); an expression that throws gives \"<error: ...>\". After `maxHits` hits of a point "
        "it stops recording and `truncated` is true. A point in code that never runs gives no hits (check `scene` and `input`). Debugging slows the scripts 2-4x. "
        "See docs/DEBUGGING.md. Example: {\"points\":[{\"file\":\"scripts/player.js\",\"line\":17,\"condition\":\"dt > 0\",\"watch\":[\"this.body.velocity\"]}],\"frames\":120,\"maxHits\":5}.";
    c.inputSchema = Json::parse(R"({"type":"object","required":["points"],"properties":{
        "points":{"type":"array","minItems":1,"description":"The lines to trace.","items":{"type":"object","required":["file","line"],"properties":{
            "file":{"type":"string","description":"Project-relative script, e.g. scripts/player.js."},
            "line":{"type":"integer","minimum":1,"description":"Line (1-based) that starts a statement; otherwise the error lists the nearest lines that do."},
            "condition":{"type":"string","description":"JavaScript expression evaluated in the frame; the point records only when it is truthy, e.g. \"this.body.velocity.y > 0\"."},
            "watch":{"type":"array","items":{"type":"string"},"description":"JavaScript expressions evaluated in the frame at every hit and recorded under hits[].watch, e.g. [\"this.body.velocity\",\"dt\"]."},
            "log":{"type":"string","description":"If non-empty the point is a logpoint: this text, with {expression} parts evaluated, goes to logs and no hit is recorded, e.g. \"vy={this.body.velocity.y}\"."}}}},
        "frames":{"type":"integer","default":300,"minimum":1,"description":"How many fixed frames to run."},
        "input":{"type":"string","description":"Project-relative input replay JSON (a recorded session, play.report gives the path) applied during the run."},
        "scene":{"type":"string","description":"Start scene (default: the project's mainScene)."},
        "maxHits":{"type":"integer","default":20,"minimum":1,"description":"Hits (or log lines) recorded per point; one more sets truncated and the point stops recording."},
        "depth":{"type":"integer","default":1,"minimum":0,"maximum":6,"description":"How far objects in locals and watch are expanded into JSON (0 = previews only; nested objects beyond the depth are previews). An object shows at most 100 entries."}}})");
    registry.add(c, [projectDir](const Json& a) { return run_trace(a, projectDir); });
}

}  // namespace fa
