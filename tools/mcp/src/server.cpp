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

#include "fa/core/strings.h"
#include "fa/tooling/api_export.h"

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
// silent. report() runs on the calling thread, the heartbeat on a thread of its own; `send` must be thread-safe.
class ProgressPump {
public:
    ProgressPump(Json token, std::function<void(const Json&)> send, std::chrono::milliseconds throttle,
                 std::chrono::milliseconds heartbeat)
        : token_(std::move(token)),
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
        std::lock_guard<std::mutex> lock(mu_);
        message_ = std::string(message);
        fresh_ = true;
        const auto now = std::chrono::steady_clock::now();
        if (now - lastSent_ >= throttle_) send_locked(now);  // else the thread sends it when the throttle is over
        return true;
    }

private:
    void send_locked(std::chrono::steady_clock::time_point now) {
        lastSent_ = now;
        fresh_ = false;
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

}  // namespace

const std::vector<std::string>& mcp_supported_protocols() {
    static const std::vector<std::string> v = {"2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"};
    return v;
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

Json McpServer::tools_json() const {
    Json tools = Json::array();
    std::set<std::string> seen;
    for (const CommandInfo* c : host_.commands().list()) {
        std::string name = mcp_tool_name(c->name);
        if (!seen.insert(name).second) continue;  // name collision after mapping: first wins
        Json t = Json::object();
        t["name"] = name;
        t["title"] = humanize(c->name);
        std::string desc = c->summary;
        if (!c->description.empty()) desc += "\n\n" + c->description;
        const std::string since = api_since("commands", c->name);
        if (!since.empty() && since != "0.1.0") desc += "\n\n" + api_since_label(since) + ".";
        t["description"] = desc;
        if (!since.empty()) t["_meta"] = Json::object({{"since", since}});
        Json schema = c->inputSchema.is_object() ? c->inputSchema : Json::object();
        if (!schema.contains("type")) schema["type"] = "object";
        t["inputSchema"] = schema;
        t["annotations"] = Json::object({{"title", humanize(c->name)},
                                         {"readOnlyHint", c->readOnly},
                                         {"destructiveHint", !c->readOnly},
                                         {"openWorldHint", false}});
        tools.push_back(std::move(t));
    }
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
    clientName_ = clientInfo_.value("name", std::string());
    clientCapabilities_ =
        state.contains("clientCapabilities") && state["clientCapabilities"].is_object() ? state["clientCapabilities"] : Json::object();
    if (state.contains("logLevel") && state["logLevel"].is_string() && level_rank(state["logLevel"].get<std::string>()) >= 0)
        logLevel_ = state["logLevel"].get<std::string>();
    initialized_ = true;
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
Json McpServer::call_tool(const Json& params) {
    Json out = run_tool(params);
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

Json McpServer::run_tool(const Json& params) {
    if (!params.is_object() || !params.contains("name") || !params["name"].is_string())
        throw CommandError("invalid_params", "tools/call needs params.name (string).");
    const std::string toolName = params["name"].get<std::string>();
    Json args = params.contains("arguments") && !params["arguments"].is_null() ? params["arguments"] : Json::object();
    if (!args.is_object()) throw CommandError("invalid_params", "tools/call params.arguments must be an object.");

    // Map tool name back to a command.
    std::string command;
    std::vector<std::string> toolNames;
    for (const CommandInfo* c : host_.commands().list()) {
        std::string n = mcp_tool_name(c->name);
        if (n == toolName && command.empty()) command = c->name;
        toolNames.push_back(n);
    }
    auto textResult = [](const std::string& text, bool isError) {
        return Json::object({{"content", Json::array({Json::object({{"type", "text"}, {"text", text}})})}, {"isError", isError}});
    };
    if (command.empty())
        return textResult("unknown_tool: " + did_you_mean(toolName, toolNames) + "\nhint: call tools/list to see the available tools.", true);

    // Progress: only when the client asked for it with a progressToken. The pump's thread sends the heartbeats; the
    // scope lets the command report what it does (this thread only: see CommandProgressScope).
    std::unique_ptr<ProgressPump> pump;
    if (params.contains("_meta") && params["_meta"].is_object() && params["_meta"].contains("progressToken") &&
        (params["_meta"]["progressToken"].is_string() || params["_meta"]["progressToken"].is_number()))
        pump = std::make_unique<ProgressPump>(params["_meta"]["progressToken"], [this](const Json& m) { emit(m); },
                                              progressThrottle_, progressHeartbeat_);
    std::optional<CommandProgressScope> scope;
    if (pump) scope.emplace([p = pump.get()](std::string_view message) { return p->report(message); });
    CommandResult r = host_.commands().call(command, args);
    scope.reset();
    pump.reset();  // no progress after the reply
    if (!r.ok) {
        std::string code = r.error.is_object() ? r.error.value("code", "failed") : "failed";
        std::string message = r.error.is_object() ? r.error.value("message", "") : r.error.dump();
        std::string hint = r.error.is_object() ? r.error.value("hint", "") : "";
        std::string text = code + ": " + message;
        if (!hint.empty()) text += "\nhint: " + hint;
        if (r.error.is_object() && r.error.contains("data") && !r.error["data"].is_null())
            text += "\ndata: " + r.error["data"].dump();  // e.g. the problems a check tool found (ToolError data)
        return textResult(text, true);
    }

    Json result = r.result;
    Json content = Json::array();
    Json image;  // null when none
    if (result.is_object() && result.contains("$image") && result["$image"].is_object()) {
        Json spec = result["$image"];
        std::string mime = spec.value("mimeType", "image/png");
        std::string b64;
        std::string note;
        if (spec.contains("base64") && spec["base64"].is_string()) {
            b64 = spec["base64"].get<std::string>();
        } else if (spec.contains("path") && spec["path"].is_string()) {
            stdfs::path p = spec["path"].get<std::string>();
            if (p.is_relative()) p = stdfs::path(host_.project_dir()) / p;
            std::ifstream in(p, std::ios::binary);
            if (in) {
                std::ostringstream ss;
                ss << in.rdbuf();
                std::string bytes = ss.str();
                b64 = base64_encode(bytes.data(), bytes.size());
            } else {
                note = "image file not found: " + p.string();
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
    content.push_back(Json::object({{"type", "text"}, {"text", dump_pretty(result)}}));
    if (!image.is_null()) content.push_back(std::move(image));
    Json out = Json::object({{"content", std::move(content)}, {"isError", false}});
    if (result.is_object()) out["structuredContent"] = result;
    return out;
}

Json McpServer::handle_request(const std::string& method, const Json& params, const Json& id) {
    if (method == "initialize") {
        std::string requested = params.is_object() ? params.value("protocolVersion", std::string()) : std::string();
        const auto& sup = mcp_supported_protocols();
        protocol_ = std::find(sup.begin(), sup.end(), requested) != sup.end() ? requested : std::string(kMcpLatestProtocol);
        if (params.is_object() && params.contains("clientInfo") && params["clientInfo"].is_object()) {
            clientInfo_ = params["clientInfo"];
            clientName_ = clientInfo_.value("name", std::string());
        }
        clientCapabilities_ =
            params.is_object() && params.contains("capabilities") && params["capabilities"].is_object() ? params["capabilities"] : Json::object();
        initialized_ = true;
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
            return ok_response(id, call_tool(params));
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
        std::string level = params.is_object() ? params.value("level", std::string()) : std::string();
        if (level_rank(level) < 0)
            return error_response(id, kInvalidParams, "Invalid log level '" + level + "'.",
                                  Json::object({{"hint", "Use debug, info, notice, warning, error, critical, alert or emergency."}}));
        logLevel_ = level;
        return ok_response(id, Json::object());
    }
    return error_response(id, kMethodNotFound, "Method not found: " + method);
}

std::optional<Json> McpServer::handle_one(const Json& msg) {
    if (!msg.is_object() || msg.value("jsonrpc", std::string()) != "2.0")
        return error_response(msg.is_object() && msg.contains("id") ? msg["id"] : Json(nullptr), kInvalidRequest,
                              "Invalid Request: expected a JSON-RPC 2.0 object with \"jsonrpc\":\"2.0\".");
    const bool hasId = msg.contains("id") && !msg["id"].is_null();
    if (!msg.contains("method")) return std::nullopt;  // a response to a server request, or garbage: ignore
    if (!msg["method"].is_string())
        return error_response(hasId ? msg["id"] : Json(nullptr), kInvalidRequest, "Invalid Request: \"method\" must be a string.");
    const std::string method = msg["method"].get<std::string>();
    Json params = msg.contains("params") ? msg["params"] : Json::object();
    if (!hasId) {
        // Notification: notifications/initialized, notifications/cancelled, roots/list_changed... nothing to do.
        return std::nullopt;
    }
    try {
        return handle_request(method, params, msg["id"]);
    } catch (const std::exception& e) {
        return error_response(msg["id"], kInternalError, std::string("Internal error: ") + e.what());
    }
}

std::optional<std::string> McpServer::handle_message(std::string_view message) {
    Json parsed;
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
