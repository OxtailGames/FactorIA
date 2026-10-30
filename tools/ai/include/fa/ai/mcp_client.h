// MCP client: lets the built-in agent (API providers) use the external tool servers the user configured in ai.json
// ("mcpServers"; docs/AI_PROVIDERS.md, "External tools (MCP servers)"). CLI agents (Claude Code, Codex...) connect to the
// servers themselves; this is for the sessions FactorIA runs.
//
// Transports: Streamable HTTP (one POST per JSON-RPC message; the reply is JSON or a Server-Sent Events stream; the
// Mcp-Session-Id the server hands out is sent back) and stdio (a local program kept alive; one JSON message per line).
// OAuth is not implemented: a server must accept a header or a key.
#pragma once

#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/http.h"
#include "fa/ai/types.h"
#include "fa/core/child_process.h"

namespace fa::ai {

// One tool a server offers (tools/list).
struct McpToolInfo {
    std::string name;
    std::string description;
    Json inputSchema = Json::object();
};

// What tools/call returned, flattened for the model: the text parts joined, the images apart.
struct McpCallResult {
    bool isError = false;  // the tool ran and reported a failure (its text says what)
    std::string text;
    std::vector<ImageData> images;
};

struct McpOptions {
    HttpTransport transport;            // empty = http_request (tests inject a fake server)
    const CancelFlag* cancel = nullptr; // set to true: a running call stops waiting
    double connectTimeoutSeconds = 30;  // initialize and tools/list
    std::string clientVersion = "dev";
};

class McpClient {
public:
    // Connects (initialize, then tools/list). The Error says which server and what failed: unreachable, refused the
    // credentials (HTTP 401/403), not an MCP server, program missing...
    static Result<std::unique_ptr<McpClient>> connect(const ResolvedToolServer& server, McpOptions options = {});
    ~McpClient();  // ends the session (HTTP DELETE) / the program (stdio)

    const std::string& name() const { return server_.name; }
    const std::vector<McpToolInfo>& tools() const { return tools_; }
    // "Scenario 1.2.0" as the server introduced itself ("" when it did not).
    const std::string& server_description() const { return description_; }

    // Calls one tool. Error = the call did not complete (timeout, transport, protocol error). A tool that ran and failed
    // is a successful Result with isError.
    Result<McpCallResult> call_tool(const std::string& tool, const Json& arguments);

private:
    McpClient() = default;
    // One JSON-RPC request; returns its "result" (or the server's error as an Error).
    Result<Json> request(const std::string& method, const Json& params, double timeoutSeconds);
    void notify(const std::string& method, const Json& params);
    Result<void> initialize();
    Result<Json> request_http(const std::string& method, const Json& params, double timeoutSeconds, bool retried);
    Result<Json> request_stdio(const std::string& method, const Json& params, double timeoutSeconds);
    Error transport_error(const std::string& what, const std::string& hint) const;

    ResolvedToolServer server_;
    McpOptions options_;
    std::mutex mu_;
    long long nextId_ = 1;
    std::string sessionId_;        // http: Mcp-Session-Id
    std::string protocolVersion_;  // negotiated
    std::string description_;
    std::vector<McpToolInfo> tools_;
    std::unique_ptr<ChildProcess> child_;  // stdio
};

// The name a model sees for a server's tool: "<server>__<tool>", reduced to [A-Za-z0-9_-] and at most 64 characters (longer
// ones are cut and get a short hash so two long names stay different).
std::string mcp_tool_def_name(const std::string& server, const std::string& tool);

// The connected servers of one run and the tools they add to the model's tool list.
class McpToolSet {
public:
    // Connects every server (those that fail are skipped: `notes` gets one line per failure or skipped server, ready for
    // an Info event). `env` fills in {key} and ${ENV}.
    void connect(const std::vector<const ToolServer*>& servers, const EnvLookup& env, const McpOptions& options,
                 std::vector<std::string>& notes);
    bool empty() const { return clients_.empty(); }
    // Sorted by name.
    std::vector<ToolDef> tool_defs() const;
    bool owns(const std::string& toolName) const { return routes_.count(toolName) > 0; }
    // Calls the tool and shapes the answer like any other tool result (text; images; isError).
    ToolResult call(const ToolCall& call);
    // The servers that connected, with how many tools each offers: [{name, tools, description}].
    const std::vector<std::shared_ptr<McpClient>>& clients() const { return clients_; }

private:
    struct Route {
        std::shared_ptr<McpClient> client;
        std::string tool;
    };
    std::vector<std::shared_ptr<McpClient>> clients_;
    std::map<std::string, Route> routes_;
};

}  // namespace fa::ai
