// MCP client (Streamable HTTP and stdio): see fa/ai/mcp_client.h.
#include "fa/ai/mcp_client.h"

#include <algorithm>
#include <cctype>
#include <chrono>

#include "fa/ai/sse.h"
#include "fa/core/hash.h"
#include "util.h"

namespace fa::ai {

using util::child;
using util::dump;
using util::str;

namespace {

constexpr const char* kProtocolVersion = "2025-06-18";
constexpr std::size_t kMaxResultText = 100000;
constexpr std::size_t kMaxDescription = 4000;

double now_seconds() {
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

std::string clip(std::string s, std::size_t n) {
    if (s.size() > n) {
        s.resize(n);
        s += "...";
    }
    return s;
}

bool image_type_ok(const std::string& t) {
    return t == "image/png" || t == "image/jpeg" || t == "image/gif" || t == "image/webp";
}

// The JSON-RPC message with this id inside an SSE stream (or "" payload when none).
Json find_in_sse(const std::string& body, const Json& id) {
    Json found;
    SseSplitter splitter([&](const std::string&, const std::string& data) {
        Json m = util::parse(data);
        if (m.is_object() && m.contains("id") && m["id"] == id && (m.contains("result") || m.contains("error"))) found = m;
    });
    splitter.feed(body);
    splitter.finish();
    return found;
}

std::string content_type_of(const HttpResponse& r) { return util::lower(r.header("content-type")); }

}  // namespace

std::string mcp_tool_def_name(const std::string& server, const std::string& tool) {
    std::string raw = server + "__" + tool;
    for (char& c : raw) {
        const bool ok = std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-';
        if (!ok) c = '_';
    }
    if (raw.size() <= 64) return raw;
    Sha256 h;
    h.update(server + "__" + tool);
    return raw.substr(0, 55) + "_" + h.finish_hex().substr(0, 8);
}

McpClient::~McpClient() {
    if (!server_.is_stdio() && !sessionId_.empty() && !is_cancelled(options_.cancel)) {
        HttpRequest req;
        req.method = "DELETE";
        req.url = server_.url;
        for (const auto& h : server_.headers) req.headers.push_back(h);
        req.headers.emplace_back("Mcp-Session-Id", sessionId_);
        req.timeoutSeconds = 3;
        req.connectTimeoutSeconds = 2;
        auto send = options_.transport ? options_.transport : HttpTransport(http_request);
        (void)send(req);  // best effort: a server may refuse to end the session
    }
}

Error McpClient::transport_error(const std::string& what, const std::string& hint) const {
    return Error{"Tool server '" + server_.name + "': " + what, hint};
}

Result<std::unique_ptr<McpClient>> McpClient::connect(const ResolvedToolServer& server, McpOptions options) {
    std::unique_ptr<McpClient> c(new McpClient());
    c->server_ = server;
    c->options_ = std::move(options);
    if (server.is_stdio()) {
        ChildOptions co;
        co.argv.push_back(server.command);
        for (const auto& a : server.args) co.argv.push_back(a);
        co.env = server.env;
        auto child = ChildProcess::start(co);
        if (!child)
            return Error{"Tool server '" + server.name + "': " + child.error().message,
                         child.error().hint.empty() ? "Check \"command\" and \"args\" of the server in AI settings > External tools."
                                                    : child.error().hint};
        c->child_ = std::move(*child);
    }
    std::lock_guard<std::mutex> lk(c->mu_);
    if (auto ok = c->initialize(); !ok) return ok.error();
    std::string cursor;
    for (int page = 0; page < 20; ++page) {
        Json params = Json::object();
        if (!cursor.empty()) params["cursor"] = cursor;
        auto r = c->request("tools/list", params, c->options_.connectTimeoutSeconds);
        if (!r) return r.error();
        if (const Json* list = child(*r, "tools"); list && list->is_array()) {
            for (const Json& t : *list) {
                McpToolInfo info;
                info.name = str(t, "name");
                if (info.name.empty()) continue;
                info.description = clip(str(t, "description", str(t, "title")), kMaxDescription);
                if (const Json* schema = child(t, "inputSchema"); schema && schema->is_object()) info.inputSchema = *schema;
                if (!info.inputSchema.contains("type")) info.inputSchema["type"] = "object";
                c->tools_.push_back(std::move(info));
            }
        }
        cursor = str(*r, "nextCursor");
        if (cursor.empty()) break;
    }
    return c;
}

Result<void> McpClient::initialize() {
    Json params = Json::object({{"protocolVersion", kProtocolVersion},
                                {"capabilities", Json::object()},
                                {"clientInfo", Json::object({{"name", "factoria"}, {"version", options_.clientVersion}})}});
    sessionId_.clear();
    protocolVersion_.clear();
    auto r = request("initialize", params, options_.connectTimeoutSeconds);
    if (!r) return r.error();
    protocolVersion_ = str(*r, "protocolVersion", kProtocolVersion);
    if (const Json* info = child(*r, "serverInfo")) {
        description_ = str(*info, "title", str(*info, "name"));
        if (auto v = str(*info, "version"); !v.empty()) description_ += (description_.empty() ? "" : " ") + v;
    }
    notify("notifications/initialized", Json::object());
    return {};
}

Result<Json> McpClient::request(const std::string& method, const Json& params, double timeoutSeconds) {
    return server_.is_stdio() ? request_stdio(method, params, timeoutSeconds)
                              : request_http(method, params, timeoutSeconds, false);
}

void McpClient::notify(const std::string& method, const Json& params) {
    Json msg = Json::object({{"jsonrpc", "2.0"}, {"method", method}, {"params", params}});
    if (server_.is_stdio()) {
        if (child_) child_->write(dump(msg) + "\n");
        return;
    }
    HttpRequest req;
    req.url = server_.url;
    req.body = dump(msg);
    req.headers = server_.headers;
    req.headers.emplace_back("Content-Type", "application/json");
    req.headers.emplace_back("Accept", "application/json, text/event-stream");
    if (!sessionId_.empty()) req.headers.emplace_back("Mcp-Session-Id", sessionId_);
    if (!protocolVersion_.empty()) req.headers.emplace_back("MCP-Protocol-Version", protocolVersion_);
    req.timeoutSeconds = 10;
    req.connectTimeoutSeconds = options_.connectTimeoutSeconds;
    req.cancel = options_.cancel;
    auto send = options_.transport ? options_.transport : HttpTransport(http_request);
    (void)send(req);  // a notification has no answer to wait for
}

Result<Json> McpClient::request_http(const std::string& method, const Json& params, double timeoutSeconds, bool retried) {
    const long long id = nextId_++;
    Json msg = Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"method", method}, {"params", params}});
    HttpRequest req;
    req.url = server_.url;
    req.body = dump(msg);
    req.headers = server_.headers;
    req.headers.emplace_back("Content-Type", "application/json");
    req.headers.emplace_back("Accept", "application/json, text/event-stream");
    if (!sessionId_.empty()) req.headers.emplace_back("Mcp-Session-Id", sessionId_);
    if (!protocolVersion_.empty() && method != "initialize") req.headers.emplace_back("MCP-Protocol-Version", protocolVersion_);
    req.timeoutSeconds = timeoutSeconds;
    req.connectTimeoutSeconds = std::min(options_.connectTimeoutSeconds, timeoutSeconds);
    req.cancel = options_.cancel;
    auto send = options_.transport ? options_.transport : HttpTransport(http_request);
    HttpResponse resp = send(req);

    if (resp.cancelled || is_cancelled(options_.cancel))
        return transport_error("the call was cancelled", "");
    if (resp.status == 0) {
        return transport_error("cannot reach " + server_.url + ": " + (resp.error.empty() ? "no answer" : resp.error),
                               "Check the address in AI settings > External tools, and your internet connection or proxy.");
    }
    if (resp.status == 404 && !sessionId_.empty() && !retried && method != "initialize") {
        // The server forgot our session (it restarted or expired it): start a new one and ask again.
        if (auto ok = initialize(); !ok) return ok.error();
        return request_http(method, params, timeoutSeconds, true);
    }
    if (resp.status == 401 || resp.status == 403) {
        const bool oauth = !resp.header("www-authenticate").empty();
        return transport_error("refused the credentials (HTTP " + std::to_string(resp.status) + ")",
                               std::string("Check the key: the header in AI settings > External tools and the environment "
                                           "variable or API key it uses. ") +
                                   (oauth ? "This server may want OAuth, which the built-in agent and Codex do not support: "
                                            "use a server key/API token if it offers one, or use it through Claude Code "
                                            "(log in once there with /mcp)."
                                          : ""));
    }
    if (!resp.ok()) {
        std::string body = clip(resp.body, 300);
        return transport_error("HTTP " + std::to_string(resp.status) + " from " + server_.url + (body.empty() ? "" : ": " + body),
                               resp.status == 404 || resp.status == 405
                                   ? "Is the address the server's Streamable HTTP endpoint (often ending in /mcp)? The old "
                                     "SSE address (/sse) is not supported."
                                   : "See the server's documentation.");
    }
    if (auto sid = resp.header("mcp-session-id"); !sid.empty()) sessionId_ = sid;

    Json message;
    if (content_type_of(resp).find("text/event-stream") != std::string::npos) {
        message = find_in_sse(resp.body, Json(id));
    } else {
        Json parsed = util::parse(resp.body);
        if (parsed.is_array()) {
            for (const Json& m : parsed)
                if (m.is_object() && m.contains("id") && m["id"] == Json(id)) message = m;
        } else if (parsed.is_object()) {
            message = parsed;
        }
    }
    if (!message.is_object() || (!message.contains("result") && !message.contains("error"))) {
        return transport_error("answered " + method + " with something that is not an MCP reply: " + clip(resp.body, 200),
                               "Is the address an MCP server (Streamable HTTP)? Servers that only offer SSE are not supported.");
    }
    if (const Json* err = child(message, "error")) {
        return transport_error(method + " failed: " + str(*err, "message", "unknown error") +
                                   " (code " + std::to_string(static_cast<long long>(util::num(*err, "code"))) + ")",
                               "");
    }
    return message["result"];
}

Result<Json> McpClient::request_stdio(const std::string& method, const Json& params, double timeoutSeconds) {
    if (!child_ || !child_->running()) {
        auto tail = child_ ? child_->stderr_tail() : std::string();
        return transport_error("the program has exited" + (tail.empty() ? std::string() : ": " + clip(tail, 400)),
                               "Run the command by hand to see why. Is it installed (npx, uvx, node...)?");
    }
    const long long id = nextId_++;
    Json msg = Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"method", method}, {"params", params}});
    if (!child_->write(dump(msg) + "\n")) return transport_error("cannot write to the program (it has exited)", "");
    const double start = now_seconds();
    std::string line;
    for (;;) {
        double left = timeoutSeconds > 0 ? timeoutSeconds - (now_seconds() - start) : 0;
        if (timeoutSeconds > 0 && left <= 0) left = 0.001;
        auto st = child_->read_line(line, left, options_.cancel);
        if (st == ChildProcess::Read::Cancelled) {
            notify("notifications/cancelled", Json::object({{"requestId", id}, {"reason", "cancelled by the user"}}));
            return transport_error("the call was cancelled", "");
        }
        if (st == ChildProcess::Read::Timeout) {
            notify("notifications/cancelled", Json::object({{"requestId", id}, {"reason", "timed out"}}));
            return transport_error(method + " timed out after " + std::to_string(static_cast<int>(timeoutSeconds)) + " s",
                                   "Raise \"timeoutSeconds\" of the server in AI settings > External tools if the tool needs "
                                   "longer.");
        }
        if (st == ChildProcess::Read::Closed) {
            auto tail = child_->stderr_tail();
            return transport_error("the program exited" + (tail.empty() ? std::string() : ": " + clip(tail, 400)),
                                   "Run the command by hand to see why it stops.");
        }
        if (line.empty()) continue;
        Json m = util::parse(line);
        if (!m.is_object()) continue;  // a log line on stdout
        if (m.contains("method")) {
            if (m.contains("id")) {  // a request from the server: answer ping, refuse the rest
                Json reply = Json::object({{"jsonrpc", "2.0"}, {"id", m["id"]}});
                if (str(m, "method") == "ping") reply["result"] = Json::object();
                else reply["error"] = Json::object({{"code", -32601}, {"message", "FactorIA does not support this request"}});
                child_->write(dump(reply) + "\n");
            }
            continue;
        }
        if (!m.contains("id") || !(m["id"] == Json(id))) continue;  // a late reply to an earlier call
        if (const Json* err = child(m, "error")) {
            return transport_error(method + " failed: " + str(*err, "message", "unknown error") + " (code " +
                                       std::to_string(static_cast<long long>(util::num(*err, "code"))) + ")",
                                   "");
        }
        return m.contains("result") ? m["result"] : Json::object();
    }
}

Result<McpCallResult> McpClient::call_tool(const std::string& tool, const Json& arguments) {
    std::lock_guard<std::mutex> lk(mu_);
    Json params = Json::object({{"name", tool}, {"arguments", arguments.is_object() ? arguments : Json::object()}});
    auto r = request("tools/call", params, server_.timeoutSeconds);
    if (!r) return r.error();
    McpCallResult out;
    out.isError = util::flag(*r, "isError");
    std::string text;
    auto add = [&](const std::string& part) {
        if (part.empty()) return;
        if (!text.empty()) text += "\n";
        text += part;
    };
    if (const Json* content = child(*r, "content"); content && content->is_array()) {
        for (const Json& part : *content) {
            const std::string type = str(part, "type");
            if (type == "text") add(str(part, "text"));
            else if (type == "image") {
                const std::string mt = str(part, "mimeType");
                if (image_type_ok(mt) && !str(part, "data").empty()) out.images.push_back({mt, str(part, "data")});
                else add("[image of type '" + mt + "' not shown: only png, jpeg, gif and webp can be looked at]");
            } else if (type == "resource_link") {
                add(str(part, "name") + (str(part, "name").empty() ? "" : ": ") + str(part, "uri"));
            } else if (type == "resource") {
                if (const Json* res = child(part, "resource")) {
                    if (!str(*res, "text").empty()) add(str(*res, "text"));
                    else add("[resource " + str(*res, "uri") + "]");
                }
            } else if (type == "audio") {
                add("[audio result not shown]");
            }
        }
    }
    if (text.empty() && out.images.empty()) {
        if (const Json* sc = child(*r, "structuredContent")) text = dump(*sc);
    }
    if (text.size() > kMaxResultText) text = text.substr(0, kMaxResultText) + "\n...(result cut at 100000 characters)";
    out.text = std::move(text);
    return out;
}

void McpToolSet::connect(const std::vector<const ToolServer*>& servers, const EnvLookup& env, const McpOptions& options,
                         std::vector<std::string>& notes) {
    for (const ToolServer* s : servers) {
        auto resolved = resolve_tool_server(*s, env);
        if (!resolved) {
            notes.push_back("External tool server '" + s->name + "' skipped: " + resolved.error().message +
                            (resolved.error().hint.empty() ? "" : " (" + resolved.error().hint + ")"));
            continue;
        }
        auto client = McpClient::connect(*resolved, options);
        if (!client) {
            notes.push_back("External tool server '" + s->name + "' not available: " + client.error().message +
                            (client.error().hint.empty() ? "" : " (" + client.error().hint + ")"));
            continue;
        }
        std::shared_ptr<McpClient> shared(std::move(*client));
        int added = 0;
        for (const McpToolInfo& t : shared->tools()) {
            const std::string defName = mcp_tool_def_name(s->name, t.name);
            if (routes_.count(defName)) continue;
            routes_[defName] = {shared, t.name};
            ++added;
        }
        clients_.push_back(shared);
        notes.push_back("External tool server '" + s->name + "' connected: " + std::to_string(added) + " tool" +
                        (added == 1 ? "" : "s") + ".");
    }
}

std::vector<ToolDef> McpToolSet::tool_defs() const {
    std::vector<ToolDef> defs;
    for (const auto& [defName, route] : routes_) {
        for (const McpToolInfo& t : route.client->tools()) {
            if (t.name != route.tool) continue;
            ToolDef d;
            d.name = defName;
            d.description = "[tool server '" + route.client->name() + "'] " + t.description;
            d.inputSchema = t.inputSchema;
            defs.push_back(std::move(d));
            break;
        }
    }
    return defs;  // routes_ is a map: already sorted by name
}

ToolResult McpToolSet::call(const ToolCall& call) {
    ToolResult tr;
    tr.toolUseId = call.id;
    auto it = routes_.find(call.name);
    if (it == routes_.end()) {
        tr.isError = true;
        tr.content = "Unknown tool server tool '" + call.name + "'.";
        return tr;
    }
    auto r = it->second.client->call_tool(it->second.tool, call.input);
    if (!r) {
        tr.isError = true;
        tr.content = r.error().message + (r.error().hint.empty() ? "" : " Hint: " + r.error().hint);
        return tr;
    }
    tr.isError = r->isError;
    tr.content = r->text.empty() && !r->images.empty() ? "(the tool returned " + std::to_string(r->images.size()) + " image" +
                                                              (r->images.size() == 1 ? "" : "s") + ", attached)"
                                                        : r->text;
    tr.images = std::move(r->images);
    return tr;
}

}  // namespace fa::ai
