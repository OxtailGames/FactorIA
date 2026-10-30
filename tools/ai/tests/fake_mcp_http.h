// A Streamable HTTP MCP server in memory, for the tests of the MCP client and of the sessions that use tool servers.
#pragma once

#include "fa/ai/mcp_client.h"
#include "test_common.h"

namespace fa::ai::test {

inline bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

inline std::string header_of(const HttpRequest& r, const std::string& name) {
    for (const auto& [k, v] : r.headers)
        if (k == name) return v;
    return {};
}

// A Streamable HTTP MCP server in memory. Answers JSON, or an SSE stream when `sse` is set.
struct FakeHttpServer {
    bool sse = false;
    bool sendSessionId = true;
    int status = 200;                 // answer every request with this status when not 200
    std::string wwwAuthenticate;      // sent with a 401
    std::string sessionId = "sess-1";
    int pages = 1;                    // tools/list is split in this many pages
    std::vector<HttpRequest> requests;
    int initializes = 0;
    int deletes = 0;
    bool forgetSessionOnce = false;   // the next request carrying a session id gets 404

    HttpTransport transport() {
        return [this](const HttpRequest& req) { return handle(req); };
    }

    static Json text_result(const std::string& text, bool isError = false) {
        return Json::object({{"content", Json::array({Json::object({{"type", "text"}, {"text", text}})})}, {"isError", isError}});
    }

    HttpResponse reply(const Json& message, const std::string& extraHeader = {}) const {
        HttpResponse r;
        r.status = 200;
        if (sse) {
            r.headers["content-type"] = "text/event-stream";
            r.body = "event: ping\ndata: {\"jsonrpc\":\"2.0\",\"method\":\"notifications/message\",\"params\":{}}\n\n"
                     "event: message\ndata: " + message.dump() + "\n\n";
        } else {
            r.headers["content-type"] = "application/json";
            r.body = message.dump();
        }
        if (!extraHeader.empty()) r.headers["mcp-session-id"] = extraHeader;
        return r;
    }

    HttpResponse handle(const HttpRequest& req) {
        requests.push_back(req);
        if (req.method == "DELETE") {
            ++deletes;
            HttpResponse r;
            r.status = 200;
            return r;
        }
        if (status != 200) {
            HttpResponse r;
            r.status = status;
            r.body = "denied";
            if (!wwwAuthenticate.empty()) r.headers["www-authenticate"] = wwwAuthenticate;
            return r;
        }
        const Json msg = Json::parse(req.body);
        const std::string method = msg.value("method", std::string());
        if (!msg.contains("id")) {
            HttpResponse r;
            r.status = 202;
            return r;
        }
        if (forgetSessionOnce && !header_of(req, "Mcp-Session-Id").empty() && method != "initialize") {
            forgetSessionOnce = false;
            HttpResponse r;
            r.status = 404;
            return r;
        }
        const Json id = msg["id"];
        const Json params = msg.contains("params") ? msg["params"] : Json::object();
        Json result = Json::object();
        std::string newSession;
        if (method == "initialize") {
            ++initializes;
            result = Json::object({{"protocolVersion", "2025-06-18"},
                                   {"capabilities", Json::object({{"tools", Json::object()}})},
                                   {"serverInfo", Json::object({{"name", "fake"}, {"title", "Fake Scenario"}, {"version", "1.2.0"}})}});
            if (sendSessionId) newSession = sessionId + "-" + std::to_string(initializes);
        } else if (method == "tools/list") {
            const std::string cursor = params.value("cursor", std::string());
            int page = cursor.empty() ? 0 : std::stoi(cursor);
            Json tools = Json::array({Json::object({{"name", "tool_" + std::to_string(page)},
                                                    {"description", "Page " + std::to_string(page) + " tool."},
                                                    {"inputSchema", Json::object({{"type", "object"}})}})});
            if (page == 0) {
                tools.push_back(Json::object({{"name", "generate image"}, {"description", "Makes an image."}}));  // no inputSchema
            }
            result = Json::object({{"tools", tools}});
            if (page + 1 < pages) result["nextCursor"] = std::to_string(page + 1);
        } else if (method == "tools/call") {
            const std::string name = params.value("name", std::string());
            const Json args = params.contains("arguments") ? params["arguments"] : Json::object();
            if (name == "tool_0") result = text_result("called " + name + " with " + args.dump());
            else if (name == "failing") result = text_result("no credits left", true);
            else if (name == "picture")
                result = Json::object({{"content", Json::array({Json::object({{"type", "image"}, {"mimeType", "image/png"}, {"data", "QUJD"}}),
                                                                Json::object({{"type", "image"}, {"mimeType", "image/tiff"}, {"data", "QUJD"}}),
                                                                Json::object({{"type", "resource_link"}, {"name", "result"}, {"uri", "https://cdn.example/a.png"}})})}});
            else if (name == "structured") result = Json::object({{"structuredContent", Json::object({{"id", 7}})}});
            else
                return reply(Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"error", Json::object({{"code", -32602}, {"message", "Unknown tool " + name}})}}));
        } else {
            return reply(Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"error", Json::object({{"code", -32601}, {"message", "no " + method}})}}));
        }
        return reply(Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"result", result}}), newSession);
    }
};

inline ResolvedToolServer http_server(const std::string& name = "scenario") {
    ResolvedToolServer s;
    s.name = name;
    s.type = "http";
    s.url = "https://mcp.example.com/mcp";
    s.headers = {{"Authorization", "Basic c2VjcmV0"}};
    s.timeoutSeconds = 20;
    return s;
}

}  // namespace fa::ai::test
