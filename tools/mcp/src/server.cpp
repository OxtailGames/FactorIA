#include "fa/mcp/server.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <map>
#include <memory>
#include <set>
#include <sstream>
#include <thread>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/tool_groups.h"
#include "result_shape.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

constexpr int kParseError = -32700;
constexpr int kInvalidRequest = -32600;
constexpr int kMethodNotFound = -32601;
constexpr int kInvalidParams = -32602;
constexpr int kInternalError = -32603;
constexpr int kResourceNotFound = -32002;

// "42s", "3m 05s", "1h 02m": the elapsed time that ends every progress message.
std::string elapsed_label(std::chrono::seconds s) {
    const long long n = s.count();
    if (n < 60) return std::to_string(n) + "s";
    char buf[32];
    if (n < 3600) std::snprintf(buf, sizeof buf, "%lldm %02llds", n / 60, n % 60);
    else std::snprintf(buf, sizeof buf, "%lldh %02lldm", n / 3600, (n / 60) % 60);
    return buf;
}

// Sends notifications/progress for one tools/call: what the command reports (throttled), plus a heartbeat while it is
// silent. report() runs on the calling thread, the heartbeat on a thread of its own; `send` must be thread-safe. Once the
// request is cancelled (`cancel`, may be null) nothing more is sent.
class ProgressPump {
public:
    ProgressPump(Json token, std::function<void(const Json&)> send, std::chrono::milliseconds throttle,
                 std::chrono::milliseconds heartbeat, const std::atomic<bool>* cancel)
        : token_(std::move(token)),
          cancel_(cancel),
          send_(std::move(send)),
          throttle_(throttle),
          heartbeat_(heartbeat),
          start_(std::chrono::steady_clock::now()),
          lastSent_(start_),
          message_("working"),
          thread_([this] { run(); }) {}
    ~ProgressPump() {
        {
            std::lock_guard<std::mutex> lock(mu_);
            done_ = true;
        }
        cv_.notify_all();
        thread_.join();
    }
    ProgressPump(const ProgressPump&) = delete;
    ProgressPump& operator=(const ProgressPump&) = delete;

    bool report(std::string_view message) {
        if (cancelled()) return false;  // nobody listens any more
        std::lock_guard<std::mutex> lock(mu_);
        message_ = std::string(message);
        fresh_ = true;
        const auto now = std::chrono::steady_clock::now();
        if (now - lastSent_ >= throttle_) send_locked(now);  // else the thread sends it when the throttle is over
        return true;
    }

private:
    bool cancelled() const { return cancel_ && cancel_->load(std::memory_order_relaxed); }
    void send_locked(std::chrono::steady_clock::time_point now) {
        lastSent_ = now;
        fresh_ = false;
        if (cancelled()) return;
        const auto secs = std::chrono::duration_cast<std::chrono::seconds>(now - start_);
        send_(Json::object(
            {{"jsonrpc", "2.0"},
             {"method", "notifications/progress"},
             {"params", Json::object({{"progressToken", token_},
                                      {"progress", ++counter_},
                                      {"message", message_ + " [" + elapsed_label(secs) + "]"}})}}));
    }
    void run() {
        std::unique_lock<std::mutex> lock(mu_);
        while (!done_) {
            const auto now = std::chrono::steady_clock::now();
            auto due = lastSent_ + heartbeat_;
            if (fresh_) due = std::min(due, lastSent_ + throttle_);
            if (now >= due) {
                send_locked(now);
                continue;
            }
            cv_.wait_until(lock, due);
        }
    }

    Json token_;
    const std::atomic<bool>* cancel_;
    std::function<void(const Json&)> send_;
    std::chrono::milliseconds throttle_, heartbeat_;
    std::chrono::steady_clock::time_point start_, lastSent_;
    std::string message_;
    bool fresh_ = false;  // a message that has not been sent yet
    bool done_ = false;
    double counter_ = 0;
    std::mutex mu_;
    std::condition_variable cv_;
    std::thread thread_;  // last: starts when everything above exists
};

std::string dump_line(const Json& j) { return j.dump(-1, ' ', false, Json::error_handler_t::replace); }
std::string dump_pretty(const Json& j) { return j.dump(2, ' ', false, Json::error_handler_t::replace); }

Json error_response(const Json& id, int code, const std::string& message, Json data = nullptr) {
    Json err = Json::object({{"code", code}, {"message", message}});
    if (!data.is_null()) err["data"] = std::move(data);
    return Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"error", std::move(err)}});
}

Json ok_response(const Json& id, Json result) {
    return Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"result", std::move(result)}});
}

// `obj[key]` when it is a string, "" otherwise (a client's value of another type is never read as one: Json::value() would
// throw).
std::string string_field(const Json& obj, const char* key) {
    if (!obj.is_object()) return {};
    const auto it = obj.find(key);
    return it != obj.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// JSON-RPC 2.0: an id is a string, a number or null.
bool valid_id(const Json& id) { return id.is_string() || id.is_number() || id.is_null(); }

// Why `msg` is not a JSON-RPC 2.0 message this server can take, or "" when it is. Checked before any field is read, so a
// value of the wrong type (a number for "jsonrpc", an object for "id", a string for "params") is an Invalid Request, never
// an exception.
std::string invalid_message_reason(const Json& msg) {
    if (!msg.is_object()) return "a JSON-RPC message is an object (or a batch: an array of objects)";
    if (const auto id = msg.find("id"); id != msg.end() && !valid_id(*id)) return "\"id\" must be a string or a number";
    const auto rpc = msg.find("jsonrpc");
    if (rpc == msg.end() || !rpc->is_string() || rpc->get<std::string>() != "2.0") return "expected \"jsonrpc\":\"2.0\"";
    if (const auto m = msg.find("method"); m != msg.end() && !m->is_string()) return "\"method\" must be a string";
    if (const auto p = msg.find("params"); p != msg.end() && !p->is_object() && !p->is_null())
        return "\"params\" must be an object";
    return {};
}

// The id an answer to `msg` carries: its own when it has a valid one, null otherwise.
Json reply_id(const Json& msg) {
    if (!msg.is_object()) return nullptr;
    const auto id = msg.find("id");
    return id != msg.end() && valid_id(*id) ? *id : Json(nullptr);
}

std::string humanize(const std::string& name) {
    std::string s = name;
    for (char& c : s) if (c == '.' || c == '_') c = ' ';
    if (!s.empty()) s[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(s[0])));
    return s;
}

int level_rank(const std::string& l) {
    static const char* levels[] = {"debug", "info", "notice", "warning", "error", "critical", "alert", "emergency"};
    for (int i = 0; i < 8; ++i)
        if (l == levels[i]) return i;
    return -1;
}

Json text_result(const std::string& text, bool isError) {
    return Json::object({{"content", Json::array({Json::object({{"type", "text"}, {"text", text}})})}, {"isError", isError}});
}

}  // namespace

const std::vector<std::string>& mcp_supported_protocols() {
    static const std::vector<std::string> v = {"2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"};
    return v;
}

void McpSession::set_handshake(Handshake h) {
    std::lock_guard<std::mutex> lock(mu_);
    handshake_ = std::move(h);
}

McpSession::Handshake McpSession::handshake() const {
    std::lock_guard<std::mutex> lock(mu_);
    return handshake_;
}

void McpSession::expect_request(const Json& id) {
    std::lock_guard<std::mutex> lock(mu_);
    queued_.emplace(id.dump(), false);
}

std::shared_ptr<std::atomic<bool>> McpSession::begin_request(const Json& id) {
    auto flag = std::make_shared<std::atomic<bool>>(false);
    const std::string key = id.dump();
    std::lock_guard<std::mutex> lock(mu_);
    const auto queued = queued_.find(key);  // the first one queued with this id is the one that starts
    if (queued != queued_.end()) {
        flag->store(queued->second);
        queued_.erase(queued);
    }
    inFlight_.emplace(key, flag);
    return flag;
}

bool McpSession::end_request(const Json& id, const std::shared_ptr<std::atomic<bool>>& flag) {
    std::lock_guard<std::mutex> lock(mu_);
    const auto range = inFlight_.equal_range(id.dump());
    for (auto it = range.first; it != range.second; ++it)
        if (it->second == flag) {
            inFlight_.erase(it);
            break;
        }
    return flag->load();
}

bool McpSession::cancel(const Json& id) {
    const std::string key = id.dump();
    std::lock_guard<std::mutex> lock(mu_);
    const auto range = inFlight_.equal_range(key);
    for (auto it = range.first; it != range.second; ++it) it->second->store(true);
    const auto queued = queued_.equal_range(key);
    for (auto it = queued.first; it != queued.second; ++it) it->second = true;
    return range.first != range.second || queued.first != queued.second;
}

std::size_t McpSession::cancel_all() {
    std::lock_guard<std::mutex> lock(mu_);
    for (auto& [key, flag] : inFlight_) flag->store(true);
    for (auto& [key, cancelled] : queued_) cancelled = true;
    return inFlight_.size() + queued_.size();
}

std::size_t McpSession::requests_in_flight() const {
    std::lock_guard<std::mutex> lock(mu_);
    return inFlight_.size();
}

std::size_t McpSession::requests_queued() const {
    std::lock_guard<std::mutex> lock(mu_);
    return queued_.size();
}

std::string mcp_tool_name(std::string_view commandName) {
    std::string out;
    for (char c : commandName) {
        unsigned char u = static_cast<unsigned char>(c);
        out += (std::isalnum(u) || c == '_' || c == '-') ? c : '_';
    }
    if (out.size() > 64) out.resize(64);
    return out;
}

McpServer::McpServer(McpHost& host) : host_(host) {}

void McpServer::share_session(std::shared_ptr<McpSession> session) {
    if (!session) return;
    session_ = std::move(session);
    McpSession::Handshake h = session_->handshake();
    if (h.protocolVersion.empty()) return;  // the client has not initialized yet: this server's initialize will
    protocol_ = std::move(h.protocolVersion);
    clientInfo_ = std::move(h.clientInfo);
    clientName_ = string_field(clientInfo_, "name");
    clientCapabilities_ = std::move(h.clientCapabilities);
    initialized_ = true;
}

void McpServer::set_result_cap(std::size_t bytes) { resultCap_ = std::max(bytes, mcp_detail::kMinResultCap); }

bool McpServer::is_cancel_notification(std::string_view message) {
    if (message.find("notifications/cancelled") == std::string_view::npos) return false;  // cheap test first
    Json parsed = parse_json_lenient(message);
    // A valid message only: an invalid one gets its Invalid Request answer in order, from the transport's loop.
    return invalid_message_reason(parsed).empty() && !parsed.contains("id") && parsed.contains("method") &&
           parsed["method"].get<std::string>() == "notifications/cancelled";
}

void McpServer::set_notification_sink(Sink sink) {
    std::vector<std::string> queued;
    {
        std::lock_guard<std::mutex> lock(outMutex_);
        sink_ = std::move(sink);
        queued.swap(queued_);
    }
    if (sink_) for (const auto& m : queued) sink_(m);
}

std::vector<std::string> McpServer::drain_outgoing() {
    std::lock_guard<std::mutex> lock(outMutex_);
    std::vector<std::string> out;
    out.swap(queued_);
    return out;
}

void McpServer::emit(const Json& message) {
    std::string line = dump_line(message);
    std::lock_guard<std::mutex> lock(outMutex_);
    if (sink_) sink_(line);
    else queued_.push_back(std::move(line));
}

void McpServer::set_progress_timing(std::chrono::milliseconds throttle, std::chrono::milliseconds heartbeat) {
    progressThrottle_ = throttle;
    progressHeartbeat_ = heartbeat;
}

void McpServer::notify_tools_changed() {
    emit(Json::object({{"jsonrpc", "2.0"}, {"method", "notifications/tools/list_changed"}}));
}
void McpServer::notify_resources_changed() {
    emit(Json::object({{"jsonrpc", "2.0"}, {"method", "notifications/resources/list_changed"}}));
}

void McpServer::log(const std::string& level, const std::string& logger, const Json& data) {
    int rank = level_rank(level), min = level_rank(logLevel_);
    if (rank < 0 || rank < min) return;
    emit(Json::object({{"jsonrpc", "2.0"},
                       {"method", "notifications/message"},
                       {"params", Json::object({{"level", level}, {"logger", logger}, {"data", data}})}}));
}

bool is_user_only_command(std::string_view commandName) { return commandName == "ai.plugin_install"; }

bool McpServer::visible(const CommandInfo& c) const { return !is_user_only_command(c.name) && (!filter_ || filter_(c)); }

bool McpServer::listed(const CommandInfo& c) const {
    if (!visible(c)) return false;
    std::lock_guard<std::mutex> lock(profileMutex_);
    return listed_locked(c);
}

bool McpServer::listed_locked(const CommandInfo& c) const {  // profileMutex_ held; c is visible
    if (!profile_ || is_core_command(c.name)) return true;
    for (const std::string& g : loaded_)
        if (command_in_tool_group(c, g)) return true;
    return false;
}

namespace {
// True when a schema property (at any depth) is marked "x-fa-path": "write": the command can write a file the caller names.
bool schema_writes_path(const Json& schema) {
    if (schema.is_object()) {
        auto it = schema.find("x-fa-path");
        if (it != schema.end() && it->is_string() && it->get<std::string>() == "write") return true;
        for (const auto& kv : schema.items())
            if (schema_writes_path(kv.value())) return true;
    } else if (schema.is_array()) {
        for (const Json& v : schema)
            if (schema_writes_path(v)) return true;
    }
    return false;
}
}  // namespace

bool mcp_command_is_read_only(const CommandInfo& c) {
    // {read} only. Exceptions, each tested: an optional argument that writes (a schema property marked x-fa-path "write":
    // checkpoint.read `out`, model.preview `out`...) and the commands whose handler asks for writeProject at run time
    // without a path (feedback.check `reject`).
    if (!CapabilitySet{Capability::Read}.has_all(c.capabilities)) return false;
    if (c.name == "feedback.check") return false;
    return !schema_writes_path(c.inputSchema);
}

Json McpServer::tool_json(const CommandInfo& c) const {
    Json t = Json::object();
    t["name"] = mcp_tool_name(c.name);
    t["title"] = humanize(c.name);
    std::string desc = c.summary;
    if (!c.description.empty()) desc += "\n\n" + c.description;
    if (!c.details.empty()) desc += "\n\n" + command_details_pointer(c);
    const std::string since = api_since("commands", c.name);
    if (!since.empty() && since != "0.1.0") desc += "\n\n" + api_since_label(since) + ".";
    t["description"] = desc;
    t["_meta"] = Json::object({{"factoria/capabilities", c.capabilities.to_json()},
                               {"factoria/capabilitiesDeclared", c.capabilitiesDeclared}});
    if (!since.empty()) t["_meta"]["since"] = since;
    Json schema = c.inputSchema.is_object() ? c.inputSchema : Json::object();
    if (!schema.contains("type")) schema["type"] = "object";
    t["inputSchema"] = schema;
    const CapabilitySet caps = c.capabilities;
    const bool readOnlyHint = mcp_command_is_read_only(c);
    // Commands whose default behaviour writes only under .factoria/ (game.screenshot...) declare {read, state}, so they are
    // not destructive; the ones that write project files declare writeProject. A command that only writes a file the caller
    // names through an optional argument (x-fa-path "write") is not read-only but not destructive either.
    const bool destructiveHint = !readOnlyHint && (caps.has(Capability::WriteAnywhere) || caps.has(Capability::Publish) ||
                                                    caps.has(Capability::Spend) || caps.has(Capability::WriteProject));
    const bool openWorldHint = caps.has(Capability::Network) || caps.has(Capability::Publish) || caps.has(Capability::Spend);
    t["annotations"] = Json::object({{"title", humanize(c.name)},
                                     {"readOnlyHint", readOnlyHint},
                                     {"destructiveHint", destructiveHint},
                                     {"openWorldHint", openWorldHint}});
    return t;
}

namespace {
constexpr const char* kToolLoad = "tool_load";
constexpr const char* kToolDescribe = "tool_describe";
constexpr const char* kToolCall = "tool_call";
bool is_loader_tool(const std::string& n) { return n == kToolLoad || n == kToolDescribe || n == kToolCall; }
}  // namespace

std::string McpServer::validate_groups(const std::vector<std::string>& groups) const {
    std::vector<const CommandInfo*> commands;
    for (const CommandInfo* c : host_.commands().list())
        if (visible(*c)) commands.push_back(c);
    for (const std::string& g : groups) {
        bool found = false;
        for (const CommandInfo* c : commands)
            if (command_in_tool_group(*c, g)) {
                found = true;
                break;
            }
        if (!found) {
            // A group that names commands this server hides (--read-only hides every command that changes state) is not a typo.
            for (const CommandInfo* c : host_.commands().list())
                if (!visible(*c) && command_in_tool_group(*c, g))
                    return "Tool group '" + g + "' only has commands this server does not offer (a --read-only server hides the commands "
                           "that change state; some commands are for the user only). Use a group that has read-only commands, or start "
                           "the server without --read-only.";
            return "Tool group '" + g + "' matches no command category and no command. " + tool_group_hint(g, commands);
        }
    }
    return {};
}

std::string McpServer::set_tool_profile(const std::vector<std::string>& groups) {
    if (groups.empty() || std::find(groups.begin(), groups.end(), "all") != groups.end()) {
        std::lock_guard<std::mutex> lock(profileMutex_);
        profile_ = false;
        loaded_.clear();
        return {};
    }
    if (std::string err = validate_groups(groups); !err.empty()) return err;
    std::lock_guard<std::mutex> lock(profileMutex_);
    profile_ = true;
    loaded_ = groups;
    return {};
}

bool McpServer::tool_profile_active() const {
    std::lock_guard<std::mutex> lock(profileMutex_);
    return profile_;
}

Json McpServer::loader_tools_json() const {
    // The groups the model can ask for: command categories with their command counts, as many as the description budget
    // (tools/cli/tests/mcp_description_budget_test.cpp: 1.5 KB) leaves room for.
    std::map<std::string, int> counts;
    for (const CommandInfo* c : host_.commands().list())
        if (visible(*c)) ++counts[c->category.empty() ? "other" : c->category];
    std::string groups;
    std::size_t shown = 0;
    for (const auto& [cat, n] : counts) {
        const std::string item = (groups.empty() ? "" : ", ") + cat + " (" + std::to_string(n) + ")";
        if (groups.size() + item.size() > 650) break;
        groups += item;
        ++shown;
    }
    if (shown < counts.size())
        groups += ", and " + std::to_string(counts.size() - shown) + " more (tool_load with no groups lists all)";
    // tool_call runs any command this server offers: on a server that offers only read-only commands (--read-only) it cannot
    // change anything, so it says so; otherwise it is a write tool like the commands behind it.
    bool callIsReadOnly = true;
    for (const CommandInfo* c : host_.commands().list())
        if (visible(*c) && !c->readOnly) { callIsReadOnly = false; break; }
    auto make = [](const char* name, const char* title, const std::string& desc, const char* schema, bool readOnly) {
        Json t = Json::object();
        t["name"] = name;
        t["title"] = title;
        t["description"] = desc;
        t["inputSchema"] = Json::parse(schema);
        t["annotations"] = Json::object({{"title", title}, {"readOnlyHint", readOnly}, {"destructiveHint", !readOnly}, {"openWorldHint", false}});
        return t;
    };
    Json out = Json::array();
    out.push_back(make(kToolLoad, "Load tool groups",
                       "This server lists only its core tools; the other commands are in groups. Load groups to add their tools "
                       "to the tool list (the server sends tools/list_changed; if your tool list does not change, use "
                       "tool_describe and tool_call instead). A group is a category, an exact command name "
                       "(assets.slice_sheet) or all. Without groups it lists the groups. Groups (commands): " + groups + ".",
                       R"({"type":"object","properties":{"groups":{"type":"array","items":{"type":"string"},"description":
                       "Categories or command names to load, e.g. [\"anim\", \"physics\"]."}},"additionalProperties":false})",
                       true));
    out.push_back(make(kToolDescribe, "Describe commands",
                       "Full definition (description and input schema) of any command of this server, loaded or not. Names are "
                       "dotted (assets.slice_sheet) or tool names (assets_slice_sheet). Several at once.",
                       R"({"type":"object","properties":{"commands":{"type":"array","items":{"type":"string"},"minItems":1,
                       "description":"Command names."}},"required":["commands"],"additionalProperties":false})",
                       true));
    out.push_back(make(kToolCall, "Call a command",
                       "Run any command of this server by name, loaded or not: same arguments and result as its own tool; wrong "
                       "arguments come back with its input schema (see tool_describe).",
                       R"({"type":"object","properties":{"command":{"type":"string","description":
                       "Command name, e.g. assets.slice_sheet."},"arguments":{"type":"object","description":
                       "The command's arguments. {} when it takes none."}},"required":["command"],"additionalProperties":false})",
                       callIsReadOnly));
    return out;
}

Json McpServer::run_loader_tool(const std::string& tool, const Json& args, const Json& params, const std::atomic<bool>* cancel) {
    auto find_command = [&](const std::string& name) -> const CommandInfo* {
        for (const CommandInfo* c : host_.commands().list())
            if (visible(*c) && (c->name == name || mcp_tool_name(c->name) == name)) return c;
        return nullptr;
    };
    auto visible_names = [&] {
        std::vector<std::string> names;
        for (const CommandInfo* c : host_.commands().list())
            if (visible(*c)) names.push_back(c->name);
        return names;
    };
    if (tool == kToolCall) {
        if (!args.contains("command") || !args["command"].is_string())
            return text_result("invalid_params: tool_call needs `command` (string), e.g. \"assets.slice_sheet\".", true);
        const std::string name = args["command"].get<std::string>();
        if (args.contains("arguments") && !args["arguments"].is_null() && !args["arguments"].is_object())
            return text_result("invalid_params: tool_call `arguments` must be an object with the command's arguments ({} when it takes none), got " +
                                   std::string(args["arguments"].type_name()) + ".",
                               true);
        const CommandInfo* c = find_command(name);
        if (!c)
            return text_result("unknown_command: No command named '" + name + "'. " + did_you_mean(name, visible_names()) +
                                   "\nhint: tool_load with no groups lists the groups; tool_describe shows a command.",
                               true);
        Json inner = Json::object({{"name", mcp_tool_name(c->name)},
                                   {"arguments", args.contains("arguments") && !args["arguments"].is_null() ? args["arguments"] : Json::object()}});
        if (params.contains("_meta")) inner["_meta"] = params["_meta"];
        return run_tool(inner, cancel);
    }
    if (tool == kToolDescribe) {
        if (!args.contains("commands") || !args["commands"].is_array() || args["commands"].empty())
            return text_result("invalid_params: tool_describe needs `commands`, a non-empty array of command names.", true);
        Json commands = Json::array(), unknown = Json::array();
        std::set<std::string> done;
        for (const Json& n : args["commands"]) {
            const std::string name = n.is_string() ? n.get<std::string>() : std::string();
            const CommandInfo* c = find_command(name);
            if (!c) {
                unknown.push_back(Json::object({{"name", name},
                                                {"message", "No command named '" + name + "'"},
                                                {"hint", did_you_mean(name, visible_names())}}));
                continue;
            }
            if (!done.insert(c->name).second) continue;
            commands.push_back(Json::object({{"name", c->name},
                                             {"tool", mcp_tool_name(c->name)},
                                             {"category", c->category},
                                             {"summary", c->summary},
                                             {"description", c->full_description()},
                                             {"readOnly", c->readOnly},
                                             {"capabilities", c->capabilities.to_json()},
                                             {"capabilitiesDeclared", c->capabilitiesDeclared},
                                             {"inputSchema", c->inputSchema}}));
        }
        const bool none = commands.empty();
        Json out = Json::object({{"commands", std::move(commands)}});
        if (!unknown.empty()) out["unknown"] = std::move(unknown);
        return text_result(dump_pretty(out), none);
    }
    // tool_load
    std::vector<std::string> groups;
    if (args.contains("groups")) {
        if (!args["groups"].is_array()) return text_result("invalid_params: `groups` must be an array of strings.", true);
        for (const Json& g : args["groups"]) {
            if (!g.is_string()) return text_result("invalid_params: `groups` must be an array of strings.", true);
            groups.push_back(g.get<std::string>());
        }
    }
    if (groups.empty()) {
        std::map<std::string, std::pair<int, int>> counts;  // category -> {commands, listed now}
        for (const CommandInfo* c : host_.commands().list()) {
            if (!visible(*c)) continue;
            auto& e = counts[c->category.empty() ? "other" : c->category];
            ++e.first;
            if (listed(*c)) ++e.second;
        }
        Json arr = Json::array();
        for (const auto& [cat, n] : counts) arr.push_back(Json::object({{"group", cat}, {"commands", n.first}, {"loaded", n.second}}));
        Json out = Json::object({{"groups", std::move(arr)},
                                 {"hint", "Call tool_load with {\"groups\": [\"<group>\", ...]} to load some."}});
        return text_result(dump_pretty(out), false);
    }
    if (std::string err = validate_groups(groups); !err.empty())
        return text_result("unknown_group: " + err + "\nhint: nothing was loaded.", true);
    // What was listed before, the change and the recount happen under one lock: two tool_load calls at once each report their own
    // additions, and tools/list never sees a half-changed set.
    Json added = Json::array();
    std::int64_t addedCount = 0, total = 0;
    {
        std::lock_guard<std::mutex> lock(profileMutex_);
        std::set<std::string> before;
        for (const CommandInfo* c : host_.commands().list())
            if (visible(*c) && listed_locked(*c)) before.insert(c->name);
        for (const std::string& g : groups)
            if (std::find(loaded_.begin(), loaded_.end(), g) == loaded_.end()) loaded_.push_back(g);
        for (const CommandInfo* c : host_.commands().list()) {
            if (!visible(*c) || !listed_locked(*c)) continue;
            ++total;
            if (before.count(c->name)) continue;
            ++addedCount;
            if (added.size() < 40) added.push_back(mcp_tool_name(c->name));
        }
    }
    if (addedCount > 0) notify_tools_changed();
    Json out = Json::object({{"loaded", groups}, {"added", addedCount}, {"addedTools", std::move(added)}, {"toolsListed", total}});
    out["note"] = addedCount == 0 ? "Those groups were loaded already."
                                  : "The tool list changed (notifications/tools/list_changed). If your client keeps its old list, "
                                    "call these through tool_call {command, arguments}.";
    return text_result(dump_pretty(out), false);
}

Json McpServer::tools_json() const {
    Json tools = Json::array();
    std::set<std::string> seen;
    for (const CommandInfo* c : host_.commands().list()) {
        if (!listed(*c)) continue;
        if (!seen.insert(mcp_tool_name(c->name)).second) continue;  // name collision after mapping: first wins
        tools.push_back(tool_json(*c));
    }
    if (tool_profile_active())
        for (Json& t : loader_tools_json()) tools.push_back(std::move(t));
    return tools;
}

Json McpServer::session_state() const {
    return Json::object({{"protocolVersion", protocol_},
                         {"clientInfo", clientInfo_},
                         {"clientCapabilities", clientCapabilities_},
                         {"logLevel", logLevel_}});
}

bool McpServer::restore_session(const Json& state) {
    if (!state.is_object() || !state.contains("protocolVersion") || !state["protocolVersion"].is_string()) return false;
    protocol_ = state["protocolVersion"].get<std::string>();
    clientInfo_ = state.contains("clientInfo") && state["clientInfo"].is_object() ? state["clientInfo"] : Json::object();
    clientName_ = string_field(clientInfo_, "name");
    clientCapabilities_ =
        state.contains("clientCapabilities") && state["clientCapabilities"].is_object() ? state["clientCapabilities"] : Json::object();
    if (state.contains("logLevel") && state["logLevel"].is_string() && level_rank(state["logLevel"].get<std::string>()) >= 0)
        logLevel_ = state["logLevel"].get<std::string>();
    initialized_ = true;
    session_->set_handshake({protocol_, clientInfo_, clientCapabilities_});
    return true;
}

void McpServer::add_tool_notice(const std::string& key, const std::string& text) {
    std::lock_guard<std::mutex> lock(noticeMutex_);
    for (auto& n : notices_)
        if (n.first == key) {
            n.second = text;
            return;
        }
    notices_.emplace_back(key, text);
}

std::vector<std::string> McpServer::pending_tool_notices() const {
    std::lock_guard<std::mutex> lock(noticeMutex_);
    std::vector<std::string> out;
    for (const auto& n : notices_) out.push_back(n.second);
    return out;
}

// The result of a tools/call, with the notices that wait for one added as a last text block.
Json McpServer::call_tool(const Json& params, const std::atomic<bool>* cancel) {
    Json out = run_tool(params, cancel);
    std::string text;
    {
        std::lock_guard<std::mutex> lock(noticeMutex_);
        for (const auto& n : notices_) text += (text.empty() ? "" : "\n\n") + n.second;
        notices_.clear();
    }
    if (!text.empty() && out.contains("content") && out["content"].is_array())
        out["content"].push_back(Json::object({{"type", "text"}, {"text", "[FactorIA notice] " + text}}));
    return out;
}

Json McpServer::run_tool(const Json& params, const std::atomic<bool>* cancel) {
    if (!params.is_object() || !params.contains("name") || !params["name"].is_string())
        throw CommandError("invalid_params", "tools/call needs params.name (string).");
    const std::string toolName = params["name"].get<std::string>();
    Json args = params.contains("arguments") && !params["arguments"].is_null() ? params["arguments"] : Json::object();
    if (!args.is_object()) throw CommandError("invalid_params", "tools/call params.arguments must be an object.");

    if (is_loader_tool(toolName) && tool_profile_active()) return run_loader_tool(toolName, args, params, cancel);

    // Map tool name back to a command.
    std::string command;
    std::vector<std::string> toolNames;
    for (const CommandInfo* c : host_.commands().list()) {
        if (!visible(*c)) continue;
        std::string n = mcp_tool_name(c->name);
        if (n == toolName && command.empty()) command = c->name;
        toolNames.push_back(n);
    }
    if (command.empty()) {
        for (const CommandInfo* c : host_.commands().list())
            if (!is_user_only_command(c->name) && mcp_tool_name(c->name) == toolName && !visible(*c))
                return text_result("tool_not_available: '" + toolName + "' is not served by this server (it only serves the tools tools/list shows).\nhint: ask the user to run it themselves (`factoria call " + c->name +
                                       "`) or to start `factoria mcp` without --read-only.",
                                   true);
    }
    if (command.empty())
        return text_result("unknown_tool: " + did_you_mean(toolName, toolNames) + "\nhint: call tools/list to see the available tools.", true);
    std::vector<std::string> pagingArgs, narrowingArgs;  // read now: the command may replace itself while it runs
    if (const CommandInfo* info = host_.commands().info(command)) {
        pagingArgs = mcp_detail::paging_arguments(info->inputSchema);
        narrowingArgs = mcp_detail::narrowing_arguments(info->inputSchema);
    }

    // Progress: only when the client asked for it with a progressToken. The pump's thread sends the heartbeats; the
    // scope lets the command report what it does (this thread only: see CommandProgressScope).
    std::unique_ptr<ProgressPump> pump;
    if (params.contains("_meta") && params["_meta"].is_object() && params["_meta"].contains("progressToken") &&
        (params["_meta"]["progressToken"].is_string() || params["_meta"]["progressToken"].is_number()))
        pump = std::make_unique<ProgressPump>(params["_meta"]["progressToken"], [this](const Json& m) { emit(m); },
                                              progressThrottle_, progressHeartbeat_, cancel);
    std::optional<CommandProgressScope> scope;
    if (pump) scope.emplace([p = pump.get()](std::string_view message) { return p->report(message); });
    // A tools/call is an AI client's call (Claude Code, a CLI agent attached to the editor): commands that only the user may run
    // with some arguments (ai.settings.set, scope "user") refuse it. notifications/cancelled sets `cancel`: the command
    // stops at its next nested call, or sooner if it polls command_cancelled().
    CommandResult r;
    {
        CommandCallerScope caller(CommandCaller::Mcp);
        CommandCapabilityScope granted(capabilities_);
        CommandCancelScope cancelled(cancel);
        r = host_.commands().call(command, args);
    }
    scope.reset();
    pump.reset();  // no progress after the reply
    if (!r.ok) {
        std::string code = r.error.is_object() ? r.error.value("code", "failed") : "failed";
        std::string message = r.error.is_object() ? r.error.value("message", "") : r.error.dump();
        std::string hint = r.error.is_object() ? r.error.value("hint", "") : "";
        std::string text = code + ": " + message;
        if (!hint.empty()) text += "\nhint: " + hint;
        if (r.error.is_object() && r.error.contains("data") && !r.error["data"].is_null())
            text += "\ndata: " + dump_line(r.error["data"]);  // e.g. the problems a check tool found (ToolError data)
        if (text.size() > resultCap_) {
            const std::size_t full = text.size();
            text = std::string(mcp_detail::utf8_prefix(text, resultCap_ - mcp_detail::kNoteReserve));
            text += "\n[truncated] This error is " + std::to_string(full) + " bytes; the first " + std::to_string(text.size()) +
                    " are shown.";
        }
        return text_result(text, true);
    }

    Json result = std::move(r.result);
    Json image;  // null when none
    if (result.is_object() && result.contains("$image") && result["$image"].is_object()) {
        Json spec = result["$image"];
        std::string mime = spec.value("mimeType", "image/png");
        std::string b64;
        std::string note;
        if (spec.contains("base64") && spec["base64"].is_string()) {
            b64 = spec["base64"].get<std::string>();
        } else if (spec.contains("path") && spec["path"].is_string()) {
            stdfs::path p = fs::path_from_utf8(spec["path"].get<std::string>());
            if (p.is_relative()) p = fs::path_from_utf8(host_.project_dir()) / p;
            std::ifstream in(p, std::ios::binary);
            if (in) {
                std::ostringstream ss;
                ss << in.rdbuf();
                std::string bytes = ss.str();
                b64 = base64_encode(bytes.data(), bytes.size());
                in.close();
                // A screenshot without `path` is temporary: now that its bytes are in the reply the file can go.
                if (!b64.empty() && discard_temporary_image(spec, host_.project_dir())) {
                    spec.erase("path");
                    spec["note"] = "Attached to this reply as an image; the temporary file was deleted. Pass `path` to keep a screenshot.";
                    result["$image"] = spec;
                }
            } else {
                note = "image file not found: " + fs::path_to_utf8(p);
            }
        }
        if (!b64.empty()) {
            image = Json::object({{"type", "image"}, {"data", b64}, {"mimeType", mime}});
            if (spec.contains("base64")) spec["base64"] = "<" + std::to_string(b64.size()) + " base64 chars, attached as image>";
            result["$image"] = spec;
        } else if (!note.empty()) {
            result["$image"]["error"] = note;
        }
    }

    // Over the cap: cut down, with a `_truncated` note that says how to get the rest (the cut result stays valid JSON).
    const bool over = mcp_detail::json_size(result) > resultCap_;
    auto shape = [&](Json value) {
        mcp_detail::ShapedResult shaped = mcp_detail::shape_result(std::move(value), resultCap_);
        const std::string truncation = mcp_detail::truncation_note(shaped, resultCap_, pagingArgs, narrowingArgs);
        const Json mark = Json::object({{"note", truncation}});
        Json out;
        if (shaped.value.is_object()) {
            out = std::move(shaped.value);
            out["_truncated"] = mark;
        } else if (shaped.replaced) {
            out = Json::object({{"_truncated", mark}});
        } else {
            out = Json::object({{"result", std::move(shaped.value)}, {"_truncated", mark}});
        }
        if (mcp_detail::json_size(out) > resultCap_) out = Json::object({{"_truncated", mark}});  // a very long note
        return out;
    };

    // Sent once, as text: every client reads `content` (MCP asks a server that sends structuredContent to send the same
    // JSON as text too, so it would go twice; no tool declares an outputSchema that would call for it).
    std::string text;
    if (over) {
        text = dump_line(shape(std::move(result)));
    } else {
        text = dump_pretty(result);
        if (text.size() > resultCap_) text = dump_line(result);  // the indentation alone would pass the cap
    }
    Json content = Json::array({Json::object({{"type", "text"}, {"text", std::move(text)}})});
    if (!image.is_null()) content.push_back(std::move(image));
    return Json::object({{"content", std::move(content)}, {"isError", false}});
}

Json McpServer::handle_request(const std::string& method, const Json& params, const Json& id, const std::atomic<bool>* cancel) {
    if (method == "initialize") {
        const std::string requested = string_field(params, "protocolVersion");
        const auto& sup = mcp_supported_protocols();
        protocol_ = std::find(sup.begin(), sup.end(), requested) != sup.end() ? requested : std::string(kMcpLatestProtocol);
        if (params.is_object() && params.contains("clientInfo") && params["clientInfo"].is_object()) {
            clientInfo_ = params["clientInfo"];
            clientName_ = string_field(clientInfo_, "name");
        }
        clientCapabilities_ =
            params.is_object() && params.contains("capabilities") && params["capabilities"].is_object() ? params["capabilities"] : Json::object();
        initialized_ = true;
        session_->set_handshake({protocol_, clientInfo_, clientCapabilities_});
        Json caps = Json::object({{"tools", Json::object({{"listChanged", true}})},
                                  {"resources", Json::object({{"listChanged", true}})},
                                  {"prompts", Json::object()},
                                  {"logging", Json::object()}});
        Json info = Json::object({{"name", "factoria"}, {"title", "FactorIA"}, {"version", host_.server_version()}});
        return ok_response(id, Json::object({{"protocolVersion", protocol_},
                                             {"capabilities", caps},
                                             {"serverInfo", info},
                                             {"instructions", host_.instructions()}}));
    }
    if (method == "ping") return ok_response(id, Json::object());
    if (method == "tools/list") return ok_response(id, Json::object({{"tools", tools_json()}}));
    if (method == "tools/call") {
        try {
            return ok_response(id, call_tool(params, cancel));
        } catch (const CommandError& e) {
            return error_response(id, kInvalidParams, e.what());
        }
    }
    if (method == "resources/list") {
        Json arr = Json::array();
        for (const auto& r : host_.list_resources())
            arr.push_back(Json::object({{"uri", r.uri}, {"name", r.name}, {"description", r.description}, {"mimeType", r.mimeType}}));
        return ok_response(id, Json::object({{"resources", arr}}));
    }
    if (method == "resources/templates/list") return ok_response(id, Json::object({{"resourceTemplates", Json::array()}}));
    if (method == "resources/read") {
        if (!params.is_object() || !params.contains("uri") || !params["uri"].is_string())
            return error_response(id, kInvalidParams, "resources/read needs params.uri (string).");
        std::string uri = params["uri"].get<std::string>();
        auto r = host_.read_resource(uri);
        if (!r.ok())
            return error_response(id, kResourceNotFound, r.error().message, Json::object({{"uri", uri}, {"hint", r.error().hint}}));
        Json content = Json::object({{"uri", r->uri}, {"mimeType", r->mimeType}, {"text", r->text}});
        return ok_response(id, Json::object({{"contents", Json::array({content})}}));
    }
    if (method == "prompts/list") {
        Json arr = Json::array();
        for (const auto& p : host_.list_prompts()) {
            Json args = Json::array();
            for (const auto& a : p.arguments)
                args.push_back(Json::object({{"name", a.name}, {"description", a.description}, {"required", a.required}}));
            arr.push_back(Json::object({{"name", p.name}, {"title", humanize(p.name)}, {"description", p.description}, {"arguments", args}}));
        }
        return ok_response(id, Json::object({{"prompts", arr}}));
    }
    if (method == "prompts/get") {
        if (!params.is_object() || !params.contains("name") || !params["name"].is_string())
            return error_response(id, kInvalidParams, "prompts/get needs params.name (string).");
        Json args = params.contains("arguments") && params["arguments"].is_object() ? params["arguments"] : Json::object();
        auto r = host_.get_prompt(params["name"].get<std::string>(), args);
        if (!r.ok()) return error_response(id, kInvalidParams, r.error().message, Json::object({{"hint", r.error().hint}}));
        Json messages = Json::array();
        for (const auto& m : r.value())
            messages.push_back(Json::object({{"role", m.role}, {"content", Json::object({{"type", "text"}, {"text", m.text}})}}));
        std::string description;
        for (const auto& p : host_.list_prompts())
            if (p.name == params["name"].get<std::string>()) description = p.description;
        return ok_response(id, Json::object({{"description", description}, {"messages", messages}}));
    }
    if (method == "logging/setLevel") {
        const std::string level = string_field(params, "level");
        if (level_rank(level) < 0)
            return error_response(id, kInvalidParams, "Invalid log level '" + level + "'.",
                                  Json::object({{"hint", "Use debug, info, notice, warning, error, critical, alert or emergency."}}));
        logLevel_ = level;
        return ok_response(id, Json::object());
    }
    return error_response(id, kMethodNotFound, "Method not found: " + method);
}

Json McpServer::runnable_request_id(const Json& msg) {
    if (!invalid_message_reason(msg).empty()) return nullptr;
    const auto id = msg.find("id");
    const auto method = msg.find("method");
    if (id == msg.end() || id->is_null() || method == msg.end() || method->get<std::string>() == "initialize") return nullptr;
    return *id;
}

std::optional<Json> McpServer::handle_one(const Json& msg) {
    // Nothing a client sends ends the server: an exception that gets this far (a bug, out of memory) answers the request
    // with an Internal error, and a notification is dropped with a log line.
    try {
        return handle_valid_one(msg);
    } catch (const std::exception& e) {
        return internal_error(msg, e.what());
    } catch (...) {
        return internal_error(msg, "unknown exception");
    }
}

std::optional<Json> McpServer::internal_error(const Json& msg, const std::string& what) {
    const Json id = reply_id(msg);
    const bool request = msg.is_object() && msg.contains("method") && msg.contains("id") && !id.is_null();
    if (!request) {
        ::fa::log(LogLevel::Warn, "mcp", "Dropped a message that failed: " + what);
        return std::nullopt;
    }
    return error_response(id, kInternalError, "Internal error: " + what);
}

std::optional<Json> McpServer::handle_valid_one(const Json& msg) {
    if (const std::string why = invalid_message_reason(msg); !why.empty())
        return error_response(reply_id(msg), kInvalidRequest, "Invalid Request: " + why + ".",
                              Json::object({{"hint", "Send one JSON-RPC 2.0 object per message: {\"jsonrpc\":\"2.0\", "
                                                     "\"id\":1, \"method\":\"tools/list\", \"params\":{}}."}}));
    const bool hasId = msg.contains("id") && !msg["id"].is_null();
    if (!msg.contains("method")) return std::nullopt;  // a response to a server request, or garbage: ignore
    const std::string method = msg["method"].get<std::string>();
    Json params = msg.contains("params") && msg["params"].is_object() ? msg["params"] : Json::object();
    if (!hasId) {
        // Notification. notifications/cancelled stops the request it names (MCP "Cancellation"): its command is told,
        // and it gets no response. One for a request that is unknown or already answered is ignored, as the spec asks.
        // The others (notifications/initialized, roots/list_changed...) need nothing.
        if (method == "notifications/cancelled" && params.contains("requestId") &&
            (params["requestId"].is_string() || params["requestId"].is_number()))
            session_->cancel(params["requestId"]);
        return std::nullopt;
    }
    const Json& id = msg["id"];
    if (method == "initialize") {  // never cancelled (MCP spec)
        try {
            return handle_request(method, params, id, nullptr);
        } catch (const std::exception& e) {
            return error_response(id, kInternalError, std::string("Internal error: ") + e.what());
        }
    }
    const std::shared_ptr<std::atomic<bool>> cancel = session_->begin_request(id);
    std::optional<Json> response;
    if (!cancel->load()) {  // set already: cancelled while it waited in the transport's queue, so it does not run
        try {
            response = handle_request(method, params, id, cancel.get());
        } catch (const std::exception& e) {
            response = error_response(id, kInternalError, std::string("Internal error: ") + e.what());
        } catch (...) {
            response = error_response(id, kInternalError, "Internal error: unknown exception");
        }
    }
    if (session_->end_request(id, cancel)) return std::nullopt;  // cancelled while it ran: no response at all
    return response;
}

std::optional<std::string> McpServer::handle_message(std::string_view message) {
    Json parsed;
    if (json_nesting_overflow(message) >= 0)
        return dump_line(error_response(nullptr, kParseError, "Parse error: nesting deeper than " + std::to_string(kMaxJsonDepth) + " levels."));
    try {
        parsed = Json::parse(message.begin(), message.end());
    } catch (const std::exception& e) {
        return dump_line(error_response(nullptr, kParseError, std::string("Parse error: ") + e.what()));
    }
    if (parsed.is_array()) {
        if (parsed.empty()) return dump_line(error_response(nullptr, kInvalidRequest, "Invalid Request: empty batch."));
        Json responses = Json::array();
        for (const auto& m : parsed)
            if (auto r = handle_one(m)) responses.push_back(std::move(*r));
        if (responses.empty()) return std::nullopt;
        return dump_line(responses);
    }
    auto r = handle_one(parsed);
    if (!r) return std::nullopt;
    return dump_line(*r);
}

}  // namespace fa
