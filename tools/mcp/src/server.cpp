#include "fa/mcp/server.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <fstream>
#include <map>
#include <set>
#include <sstream>

#include "fa/core/strings.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

constexpr int kParseError = -32700;
constexpr int kInvalidRequest = -32600;
constexpr int kMethodNotFound = -32601;
constexpr int kInvalidParams = -32602;
constexpr int kInternalError = -32603;
constexpr int kResourceNotFound = -32002;

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
        t["description"] = desc;
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

Json McpServer::call_tool(const Json& params) {
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

    CommandResult r = host_.commands().call(command, args);
    if (!r.ok) {
        std::string code = r.error.is_object() ? r.error.value("code", "failed") : "failed";
        std::string message = r.error.is_object() ? r.error.value("message", "") : r.error.dump();
        std::string hint = r.error.is_object() ? r.error.value("hint", "") : "";
        std::string text = code + ": " + message;
        if (!hint.empty()) text += "\nhint: " + hint;
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
        if (params.is_object() && params.contains("clientInfo") && params["clientInfo"].is_object())
            clientName_ = params["clientInfo"].value("name", std::string());
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
