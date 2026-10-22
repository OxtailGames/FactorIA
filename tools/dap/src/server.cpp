// DapServer: requests in, responses and events out; the DebugClient of the game's ScriptDebugger.
#include "fa/dap/server.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/script/script.h"

namespace fa {

namespace fsys = std::filesystem;

namespace {

// Windows and macOS file systems ignore case: the paths a client sends may differ from the module names in case only.
#if defined(_WIN32) || defined(__APPLE__)
constexpr bool kCaseInsensitivePaths = true;
#else
constexpr bool kCaseInsensitivePaths = false;
#endif

std::string lowered(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

std::string normalised(const std::string& path) {
    std::error_code ec;
    fsys::path canon = fsys::weakly_canonical(fsys::path(path), ec);
    if (ec) canon = fsys::path(path).lexically_normal();
    std::string s = canon.generic_string();
    while (s.size() > 1 && s.back() == '/') s.pop_back();
    return s;
}

// `rel` as it is spelled on disk: on case-insensitive systems a client may send "Scripts/Player.js" for scripts/player.js.
std::string disk_spelling(const std::string& root, const std::string& rel) {
    if (!kCaseInsensitivePaths) return rel;
    std::error_code ec;
    fsys::path dir(root);
    std::string out;
    std::size_t pos = 0;
    while (pos <= rel.size()) {
        std::size_t slash = rel.find('/', pos);
        std::string part = rel.substr(pos, slash == std::string::npos ? std::string::npos : slash - pos);
        std::string actual = part;
        if (!part.empty() && !fsys::exists(dir / part, ec)) {
            for (const auto& e : fsys::directory_iterator(dir, ec))
                if (lowered(e.path().filename().string()) == lowered(part)) {
                    actual = e.path().filename().string();
                    break;
                }
        }
        out += (out.empty() ? "" : "/") + actual;
        dir /= actual;
        if (slash == std::string::npos) break;
        pos = slash + 1;
    }
    return out;
}

std::string base_name(const std::string& path) {
    std::size_t slash = path.find_last_of("/\\");
    return slash == std::string::npos ? path : path.substr(slash + 1);
}

std::string str_of(const Json& j, const char* key, const std::string& def = {}) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : def;
}

int int_of(const Json& j, const char* key, int def = 0) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return it != j.end() && it->is_number() ? static_cast<int>(it->get<double>()) : def;
}

Json capabilities() {
    Json filters = Json::array();
    filters.push_back(Json::object({{"filter", "uncaught"}, {"label", "Uncaught Exceptions"},
                                    {"description", "Stop where an exception is about to reach the engine."}, {"default", true}}));
    filters.push_back(Json::object({{"filter", "all"}, {"label", "All Exceptions"},
                                    {"description", "Stop at every throw, also the exceptions your code catches."}, {"default", false}}));
    return Json::object({{"supportsConfigurationDoneRequest", true},
                         {"supportsConditionalBreakpoints", true},
                         {"supportsHitConditionalBreakpoints", true},
                         {"supportsLogPoints", true},
                         {"supportsEvaluateForHovers", true},
                         {"supportsSetVariable", true},
                         {"supportsTerminateRequest", true},
                         {"exceptionBreakpointFilters", filters}});
}

const char* dap_reason(const std::string& reason) {
    if (reason == "breakpoint" || reason == "debugger") return "breakpoint";
    if (reason == "step") return "step";
    if (reason == "pause") return "pause";
    if (reason == "exception") return "exception";
    if (reason == "entry") return "entry";
    return "pause";
}

const std::vector<std::string>& supported_requests() {
    static const std::vector<std::string> v = {
        "initialize", "launch",     "setBreakpoints", "setExceptionBreakpoints", "configurationDone", "threads",
        "pause",      "stackTrace", "scopes",         "variables",               "evaluate",          "setVariable",
        "continue",   "next",       "stepIn",         "stepOut",                 "source",            "disconnect",
        "terminate"};
    return v;
}

}  // namespace

DapServer::DapServer(Sink sink, ScriptInstrumenter instrumenter) : sink_(std::move(sink)), instrumenter_(std::move(instrumenter)) {}
DapServer::~DapServer() = default;

// ------------------------------------------------------------------------------------------------------------ sending
void DapServer::send_json(Json message) {
    std::lock_guard<std::mutex> lock(sendMutex_);
    message["seq"] = seq_++;
    if (sink_) sink_(message);
}

void DapServer::send_event(const std::string& event, Json body) {
    Json m = Json::object({{"type", "event"}, {"event", event}});
    if (!body.empty()) m["body"] = std::move(body);
    send_json(std::move(m));
}

void DapServer::send_response(const Json& request, bool success, Json body, const std::string& message) {
    Json m = Json::object({{"type", "response"},
                           {"request_seq", request.value("seq", 0)},
                           {"success", success},
                           {"command", request.value("command", std::string())}});
    if (!success) m["message"] = message;
    if (success || !body.empty()) m["body"] = std::move(body);
    send_json(std::move(m));
}

void DapServer::send_output(const std::string& category, const std::string& text, const std::string& file, int line) {
    Json body = Json::object({{"category", category}, {"output", text}});
    if (!file.empty() && !launch_.projectDir.empty()) {
        body["source"] = Json::object({{"name", base_name(file)}, {"path", absolute_path(file)}});
        if (line > 0) body["line"] = line_to_client(line);
    }
    send_event("output", std::move(body));
}

void DapServer::handle_protocol_error(const std::string& text) { send_output("stderr", "factoria dap: " + text + "\n"); }

// ------------------------------------------------------------------------------------------------------------- paths
std::string DapServer::module_name(const std::string& absolutePath, std::string& why) const {
    if (projectCanon_.empty()) {
        why = "the debug session has not started a project yet";
        return {};
    }
    fsys::path given(absolutePath);
    if (!given.is_absolute()) given = fsys::path(launch_.projectDir) / given;
    const std::string canon = normalised(given.string());
    const std::string prefix = projectCanon_ + "/";
    const bool inside = canon.size() > prefix.size() &&
                        (kCaseInsensitivePaths ? lowered(canon.substr(0, prefix.size())) == lowered(prefix) : canon.compare(0, prefix.size(), prefix) == 0);
    if (!inside) {
        why = "'" + absolutePath + "' is outside the project folder '" + launch_.projectDir +
              "': only the scripts of the project being debugged can have breakpoints";
        return {};
    }
    std::string rel = canon.substr(prefix.size());
    const std::string ext = lowered(fsys::path(rel).extension().string());
    if (ext != ".js" && ext != ".mjs") {
        why = "'" + rel + "' is not a JavaScript module (.js): breakpoints work in the scripts the game runs";
        return {};
    }
    return disk_spelling(projectCanon_, rel);
}

std::string DapServer::absolute_path(const std::string& moduleName) const {
    return (fsys::path(launch_.projectDir) / moduleName).make_preferred().string();
}

// -------------------------------------------------------------------------------------------------------- requests
void DapServer::handle_message(const Json& msg) {
    if (!msg.is_object() || str_of(msg, "type") != "request" || str_of(msg, "command").empty()) {
        handle_protocol_error("ignored a message that is not a request: " + msg.dump().substr(0, 200) +
                              ". Requests look like {\"seq\":1,\"type\":\"request\",\"command\":\"initialize\",\"arguments\":{}}");
        return;
    }
    const std::string command = msg["command"].get<std::string>();
    Json args = msg.contains("arguments") && msg["arguments"].is_object() ? msg["arguments"] : Json::object();
    try {
        bool answered = false;
        Json body = dispatch(command, args, msg, answered);
        if (!answered) send_response(msg, true, std::move(body));
    } catch (const Failure& f) {
        send_response(msg, false, Json::object(), f.message);
    } catch (const std::exception& e) {
        send_response(msg, false, Json::object(), "malformed '" + command + "' request: " + e.what());
    }
}

Json DapServer::dispatch(const std::string& command, const Json& args, const Json& request, bool& answered) {
    if (command == "initialize") {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            initialized_ = true;
            linesStartAt1_ = args.value("linesStartAt1", true);
            columnsStartAt1_ = args.value("columnsStartAt1", true);
        }
        send_response(request, true, capabilities());
        send_event("initialized");  // breakpoints may come before launch: setBreakpoints waits for it
        answered = true;
        return {};
    }
    if (command == "launch") return on_launch(args, request, answered);
    if (command == "setBreakpoints") {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (!launched_ && !launchFailed_) {  // the project is not known yet: answered when launch is handled
                deferred_.push_back(request);
                answered = true;
                return {};
            }
        }
        return set_breakpoints_now(args);
    }
    if (command == "setExceptionBreakpoints") return on_set_exception_breakpoints(args);
    if (command == "configurationDone") {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            configDone_ = true;
        }
        cv_.notify_all();
        return Json::object();
    }
    if (command == "threads") return Json::object({{"threads", Json::array({Json::object({{"id", 1}, {"name", "Game"}})})}});
    if (command == "pause") {
        if (debugger_) debugger_->request_pause();
        return Json::object();
    }
    if (command == "source") return on_source(args);
    if (command == "disconnect" || command == "terminate") {
        send_response(request, true);  // before the game can end: the client must see the answer
        answered = true;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            terminate_ = true;
            if (command == "disconnect") disconnected_ = true;
        }
        if (debugger_) debugger_->request_terminate();
        cv_.notify_all();
        return {};
    }
    static const std::vector<std::string> pausedOnly = {"stackTrace", "scopes",   "variables", "evaluate",
                                                        "setVariable", "continue", "next",      "stepIn", "stepOut"};
    if (std::find(pausedOnly.begin(), pausedOnly.end(), command) != pausedOnly.end()) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (paused_) {
            queue_.push_back({request});
            answered = true;
            cv_.notify_all();
            return {};
        }
        if (command == "evaluate") {
            if (finished_) throw Failure{"The game has ended, there is nothing to evaluate in."};
            if (launched_ && !debugger_)
                throw Failure{"This session runs without debugging (noDebug), so the debug console is not connected to the game. Start it with F5 instead of Ctrl+F5."};
            evalPending_.push_back(request);  // answered by poll() at the start of the next frame
            answered = true;
            return {};
        }
        if (command == "continue") return Json::object({{"allThreadsContinued", true}});
        if (command == "next" || command == "stepIn" || command == "stepOut") return Json::object();  // the game is not stopped: nothing to do
        if (command == "stackTrace") return Json::object({{"stackFrames", Json::array()}, {"totalFrames", 0}});
        throw Failure{"The game is not stopped, so '" + command + "' has nothing to read. Stop it first: set a breakpoint or press Pause."};
    }
    throw Failure{"This debugger does not support the request '" + command + "'. " + did_you_mean(command, supported_requests())};
}

Json DapServer::on_launch(const Json& args, const Json& request, bool& answered) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (launched_) throw Failure{"The session was already launched. Start a new debug session instead of sending launch twice."};
    }
    std::error_code ec;
    auto parsed = parse_dap_launch(args, fsys::current_path(ec).string());
    if (!parsed.ok()) {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            launchFailed_ = true;
        }
        apply_deferred(false);
        throw Failure{parsed.error().message + (parsed.error().hint.empty() ? "" : " " + parsed.error().hint)};
    }
    launch_ = *parsed;
    projectCanon_ = normalised(launch_.projectDir);
    if (!launch_.noDebug) {
        debugger_ = std::make_shared<ScriptDebugger>(*this, instrumenter_, launch_.projectDir);
        debugger_->set_exception_filters(exceptionAll_, exceptionUncaught_);
        debugger_->set_stop_on_entry(launch_.stopOnEntry);
    }
    send_response(request, true);
    answered = true;
    apply_deferred(true);
    cv_.notify_all();
    return {};
}

void DapServer::apply_deferred(bool launched) {
    std::vector<Json> list;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        list.swap(deferred_);
        if (launched) launched_ = true;
    }
    for (const Json& req : list) {
        try {
            Json args = req.contains("arguments") && req["arguments"].is_object() ? req["arguments"] : Json::object();
            send_response(req, true, set_breakpoints_now(args));
        } catch (const Failure& f) {
            send_response(req, false, Json::object(), f.message);
        } catch (const std::exception& e) {
            send_response(req, false, Json::object(), std::string("malformed setBreakpoints request: ") + e.what());
        }
    }
}

Json DapServer::set_breakpoints_now(const Json& args) {
    const Json source = args.contains("source") ? args["source"] : Json::object();
    const std::string path = str_of(source, "path");
    if (path.empty())
        throw Failure{"setBreakpoints needs source.path (the absolute path of a script of the project). Got " + source.dump() + "."};
    std::vector<DebugBreakpoint> wanted;
    if (args.contains("breakpoints") && args["breakpoints"].is_array()) {
        for (const Json& b : args["breakpoints"]) {
            DebugBreakpoint bp;
            bp.line = line_from_client(int_of(b, "line"));
            bp.condition = str_of(b, "condition");
            bp.hitCondition = str_of(b, "hitCondition");
            bp.logMessage = str_of(b, "logMessage");
            wanted.push_back(std::move(bp));
        }
    } else if (args.contains("lines") && args["lines"].is_array()) {
        for (const Json& l : args["lines"]) {
            DebugBreakpoint bp;
            bp.line = line_from_client(l.is_number() ? static_cast<int>(l.get<double>()) : 0);
            wanted.push_back(std::move(bp));
        }
    }
    std::string why;
    std::string module = module_name(path, why);
    if (!module.empty() && !debugger_) {
        why = "this session runs without debugging (noDebug)";
        module.clear();
    }
    Json out = Json::array();
    if (module.empty()) {
        for (const DebugBreakpoint& bp : wanted)
            out.push_back(Json::object({{"verified", false}, {"line", line_to_client(bp.line)}, {"message", why}}));
    } else {
        const std::vector<DebugBreakpointState> states = debugger_->set_breakpoints(module, wanted);
        for (const DebugBreakpointState& st : states) {
            Json j = Json::object({{"id", st.id}, {"verified", st.verified}, {"line", line_to_client(st.line)}});
            if (!st.message.empty()) j["message"] = st.message;
            out.push_back(std::move(j));
        }
    }
    return Json::object({{"breakpoints", out}});
}

Json DapServer::on_set_exception_breakpoints(const Json& args) {
    bool all = false, uncaught = false;
    if (args.contains("filters") && args["filters"].is_array())
        for (const Json& f : args["filters"]) {
            if (!f.is_string()) continue;
            if (f == "all") all = true;
            else if (f == "uncaught") uncaught = true;
            else throw Failure{"Unknown exception filter '" + f.get<std::string>() + "'. " + did_you_mean(f.get<std::string>(), std::vector<std::string>{"uncaught", "all"})};
        }
    {
        std::lock_guard<std::mutex> lock(mutex_);
        exceptionAll_ = all;
        exceptionUncaught_ = uncaught;
    }
    if (debugger_) debugger_->set_exception_filters(all, uncaught);
    return Json::object();
}

Json DapServer::on_source(const Json& args) {
    const Json source = args.contains("source") ? args["source"] : Json::object();
    std::string path = str_of(source, "path");
    if (path.empty()) throw Failure{"source needs source.path: this debugger shows project files from disk and has no virtual sources."};
    std::string why;
    const std::string module = module_name(path, why);
    if (module.empty()) throw Failure{why};
    auto text = fs::read_text(absolute_path(module));
    if (!text) throw Failure{"cannot read '" + path + "': " + text.error().message};
    return Json::object({{"content", *text}, {"mimeType", "text/javascript"}});
}

// ----------------------------------------------------------------------------------------------------- main thread
bool DapServer::wait_for_start() {
    std::unique_lock<std::mutex> lock(mutex_);
    cv_.wait(lock, [&] { return (launched_ && configDone_) || terminate_ || disconnected_; });
    return launched_ && configDone_ && !terminate_ && !disconnected_;
}

std::shared_ptr<ScriptDebugger> DapServer::debugger() const { return debugger_; }

bool DapServer::terminate_requested() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return terminate_;
}

bool DapServer::wait_for_disconnect(std::chrono::milliseconds timeout) {
    std::unique_lock<std::mutex> lock(mutex_);
    return cv_.wait_for(lock, timeout, [&] { return disconnected_; });
}

void DapServer::handle_eof() {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        terminate_ = true;
        disconnected_ = true;
    }
    if (debugger_) debugger_->request_terminate();
    cv_.notify_all();
}

void DapServer::finish(int exitCode) {
    std::vector<Json> waiting;
    bool disconnected;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        finished_ = true;
        waiting.swap(evalPending_);
        disconnected = disconnected_;
    }
    for (const Json& r : waiting) send_response(r, false, Json::object(), "The game ended before this expression could run.");
    if (disconnected) return;
    send_event("exited", Json::object({{"exitCode", exitCode}}));
    send_event("terminated");
}

// --------------------------------------------------------------------------------------------- DebugClient (game)
void DapServer::output(std::string_view category, std::string_view text, const std::string& file, int line) {
    std::string t(text);
    if (t.empty() || t.back() != '\n') t += '\n';  // logpoint text comes without one
    send_output(std::string(category), t, file, line);
}

void DapServer::poll(ScriptSystem& scripts) {
    std::vector<Json> list;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        list.swap(evalPending_);
    }
    for (const Json& req : list) {
        const Json args = req.contains("arguments") && req["arguments"].is_object() ? req["arguments"] : Json::object();
        const std::string expr = str_of(args, "expression");
        Result<Json> r = scripts.eval(expr);
        if (!r.ok()) {
            send_response(req, false, Json::object(), r.error().message);
            continue;
        }
        send_response(req, true, Json::object({{"result", r->dump()}, {"variablesReference", 0}}));
    }
}

Json DapServer::value_body(const DebugValue& v) const {
    Json j = Json::object({{"result", v.value}, {"variablesReference", v.variablesReference}});
    if (!v.type.empty()) j["type"] = v.type;
    if (v.namedVariables > 0) j["namedVariables"] = v.namedVariables;
    if (v.indexedVariables > 0) j["indexedVariables"] = v.indexedVariables;
    return j;
}

DebugResume DapServer::paused(const DebugStop& stop, PausedScripts& scripts) {
    {
        std::lock_guard<std::mutex> lock(mutex_);
        if (terminate_) return DebugResume::Continue;
        paused_ = true;
        for (Json& r : evalPending_) queue_.push_back({std::move(r)});  // typed while running: answered with the frame
        evalPending_.clear();
    }
    Json body = Json::object({{"reason", dap_reason(stop.reason)},
                              {"description", stop.description},
                              {"threadId", 1},
                              {"allThreadsStopped", true}});
    if (!stop.exceptionText.empty()) body["text"] = stop.exceptionText;
    else if (!stop.description.empty()) body["text"] = stop.description;
    if (!stop.hitBreakpointIds.empty()) body["hitBreakpointIds"] = stop.hitBreakpointIds;
    send_event("stopped", std::move(body));

    DebugResume resume = DebugResume::Continue;
    for (;;) {
        Item item;
        {
            std::unique_lock<std::mutex> lock(mutex_);
            cv_.wait(lock, [&] { return !queue_.empty() || terminate_; });
            if (terminate_) break;  // disconnect or terminate while stopped: let the game go so it can end
            item = std::move(queue_.front());
            queue_.pop_front();
        }
        if (run_paused_request(item, scripts, resume)) break;
    }
    std::deque<Item> leftover;
    {
        std::lock_guard<std::mutex> lock(mutex_);
        paused_ = false;
        leftover.swap(queue_);
    }
    for (const Item& it : leftover)
        send_response(it.request, false, Json::object(), "The game was resumed before this request ran.");
    return resume;
}

bool DapServer::run_paused_request(const Item& item, PausedScripts& scripts, DebugResume& resume) {
    const Json& req = item.request;
    const std::string command = req.value("command", std::string());
    const Json args = req.contains("arguments") && req["arguments"].is_object() ? req["arguments"] : Json::object();
    try {
        if (command == "continue" || command == "next" || command == "stepIn" || command == "stepOut") {
            resume = command == "continue" ? DebugResume::Continue
                     : command == "next"   ? DebugResume::StepOver
                     : command == "stepIn" ? DebugResume::StepIn
                                           : DebugResume::StepOut;
            send_response(req, true, command == "continue" ? Json::object({{"allThreadsContinued", true}}) : Json::object());
            return true;
        }
        if (command == "stackTrace") {
            send_response(req, true, stack_trace_body(args, scripts));
        } else if (command == "scopes") {
            Json arr = Json::array();
            for (const DebugScope& s : scripts.scopes(int_of(args, "frameId"))) {
                Json j = Json::object({{"name", s.name}, {"variablesReference", s.variablesReference}, {"expensive", s.expensive}});
                if (s.name == "Locals") j["presentationHint"] = "locals";
                arr.push_back(std::move(j));
            }
            send_response(req, true, Json::object({{"scopes", arr}}));
        } else if (command == "variables") {
            Json arr = Json::array();
            for (const DebugValue& v : scripts.variables(int_of(args, "variablesReference"), int_of(args, "start"), int_of(args, "count"))) {
                Json j = Json::object({{"name", v.name}, {"value", v.value}, {"variablesReference", v.variablesReference}});
                if (!v.type.empty()) j["type"] = v.type;
                if (v.namedVariables > 0) j["namedVariables"] = v.namedVariables;
                if (v.indexedVariables > 0) j["indexedVariables"] = v.indexedVariables;
                arr.push_back(std::move(j));
            }
            send_response(req, true, Json::object({{"variables", arr}}));
        } else if (command == "evaluate") {
            auto r = scripts.evaluate(int_of(args, "frameId"), str_of(args, "expression"));
            if (!r.ok()) send_response(req, false, Json::object(), r.error().message);
            else send_response(req, true, value_body(*r));
        } else if (command == "setVariable") {
            auto r = scripts.set_variable(int_of(args, "variablesReference"), str_of(args, "name"), str_of(args, "value"));
            if (!r.ok()) {
                send_response(req, false, Json::object(), r.error().message);
            } else {
                Json b = value_body(*r);
                b["value"] = b["result"];
                b.erase("result");
                send_response(req, true, std::move(b));
            }
        } else {
            send_response(req, false, Json::object(), "unexpected request '" + command + "' while stopped");
        }
    } catch (const std::exception& e) {
        send_response(req, false, Json::object(), "'" + command + "' failed: " + e.what());
    }
    return false;
}

Json DapServer::stack_trace_body(const Json& args, PausedScripts& scripts) {
    const std::vector<DebugFrame> frames = scripts.stack();
    const int start = std::max(0, int_of(args, "startFrame"));
    const int levels = int_of(args, "levels");
    Json arr = Json::array();
    for (int i = start; i < static_cast<int>(frames.size()) && (levels <= 0 || i < start + levels); ++i) {
        const DebugFrame& f = frames[static_cast<std::size_t>(i)];
        Json j = Json::object({{"id", f.id}, {"name", f.name}, {"line", line_to_client(f.line)}, {"column", column_to_client(f.column)}});
        if (!f.file.empty()) j["source"] = Json::object({{"name", base_name(f.file)}, {"path", absolute_path(f.file)}});
        arr.push_back(std::move(j));
    }
    return Json::object({{"stackFrames", arr}, {"totalFrames", static_cast<int>(frames.size())}});
}

}  // namespace fa
