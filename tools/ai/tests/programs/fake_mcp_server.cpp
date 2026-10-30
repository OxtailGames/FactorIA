// A tiny MCP server over stdio for the tests of fa_ai (test_mcp_client.cpp): one JSON-RPC message per line on stdin, one per line
// on stdout. Tools: echo {text}, shout {text}, env {name} (the value of an environment variable of this process), fail
// (a tool that runs and reports an error), image (a 1x1 png), crash (the program ends without an answer), ping_first (asks the
// client a ping before it answers, as a server may), big (a long text).
#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <string>

#include "fa/core/json.h"

using fa::Json;

namespace {

void send(const Json& message) {
    std::cout << message.dump() << "\n";
    std::cout.flush();
}

Json text_result(const std::string& text, bool isError = false) {
    return Json::object({{"content", Json::array({Json::object({{"type", "text"}, {"text", text}})})}, {"isError", isError}});
}

Json tool(const std::string& name, const std::string& description, const Json& properties = Json::object()) {
    return Json::object({{"name", name},
                         {"description", description},
                         {"inputSchema", Json::object({{"type", "object"}, {"properties", properties}})}});
}

}  // namespace

int main() {
    std::string line;
    while (std::getline(std::cin, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) continue;
        const Json msg = Json::parse(line, nullptr, false);
        if (!msg.is_object()) continue;
        const std::string method = msg.value("method", std::string());
        if (!msg.contains("id")) {
            if (method == "notifications/initialized") std::cerr << "fake_mcp_server: initialized\n";
            continue;  // notifications get no answer
        }
        const Json id = msg["id"];
        const Json params = msg.contains("params") ? msg["params"] : Json::object();
        Json result = Json::object();
        if (method == "initialize") {
            result = Json::object({{"protocolVersion", "2025-06-18"},
                                   {"capabilities", Json::object({{"tools", Json::object()}})},
                                   {"serverInfo", Json::object({{"name", "FakeStdio"}, {"version", "0.1"}})}});
        } else if (method == "tools/list") {
            result = Json::object({{"tools", Json::array({tool("echo", "Repeats the text.", Json::object({{"text", Json::object({{"type", "string"}})}})),
                                                          tool("env", "Reads an environment variable."), tool("fail", "Always fails."),
                                                          tool("image", "Returns a picture."), tool("crash", "Ends the program."),
                                                          tool("ping_first", "Asks the client a ping first."), tool("big", "A very long text.")})}});
        } else if (method == "tools/call") {
            const std::string name = params.value("name", std::string());
            const Json args = params.contains("arguments") ? params["arguments"] : Json::object();
            if (name == "echo") {
                result = text_result("echo: " + args.value("text", std::string()));
            } else if (name == "env") {
                const char* v = std::getenv(args.value("name", std::string()).c_str());
                result = text_result(v ? v : "(unset)");
            } else if (name == "fail") {
                result = text_result("the tool failed on purpose", true);
            } else if (name == "image") {
                result = Json::object(
                    {{"content", Json::array({Json::object({{"type", "text"}, {"text", "here is the picture"}}),
                                              Json::object({{"type", "image"}, {"mimeType", "image/png"},
                                                            {"data", "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="}})})},
                     {"isError", false}});
            } else if (name == "crash") {
                std::_Exit(3);
            } else if (name == "ping_first") {
                send(Json::object({{"jsonrpc", "2.0"}, {"id", "srv-1"}, {"method", "ping"}}));
                std::string reply;
                std::getline(std::cin, reply);  // the client's answer to the ping
                result = text_result(reply.find("srv-1") != std::string::npos ? "pinged" : "no pong");
            } else if (name == "big") {
                result = text_result(std::string(150000, 'x'));
            } else {
                send(Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"error", Json::object({{"code", -32602}, {"message", "Unknown tool: " + name}})}}));
                continue;
            }
        } else if (method == "ping") {
            result = Json::object();
        } else {
            send(Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"error", Json::object({{"code", -32601}, {"message", "Method not found: " + method}})}}));
            continue;
        }
        send(Json::object({{"jsonrpc", "2.0"}, {"id", id}, {"result", result}}));
    }
    return 0;
}
