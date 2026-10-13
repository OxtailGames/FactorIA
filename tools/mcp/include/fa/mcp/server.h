// Model Context Protocol server (JSON-RPC 2.0).
//
// Transport-independent: feed one JSON-RPC message at a time to
// McpServer::handle_message() and send back what it returns. run_stdio()
// (transport.h) wires it to stdin/stdout; a Streamable-HTTP transport can call
// handle_message() the same way. Server-initiated messages (tools/list_changed,
// log notifications) go to the notification sink.
//
// The host supplies everything project-specific: the CommandRegistry (each
// command becomes a tool), instructions, resources and prompts. SimpleMcpHost
// implements all of it from a registry + project directory.
#pragma once

#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct McpResource {
    std::string uri;  // "factoria://docs/SCRIPTING.md"
    std::string name;
    std::string description;
    std::string mimeType;  // "text/markdown" | "application/json"
};
struct McpResourceContent {
    std::string uri;
    std::string mimeType;
    std::string text;
};
struct McpPromptArgument {
    std::string name;
    std::string description;
    bool required = false;
};
struct McpPrompt {
    std::string name;
    std::string description;
    std::vector<McpPromptArgument> arguments;
};
struct McpPromptMessage {
    std::string role = "user";  // "user" | "assistant"
    std::string text;
};

class McpHost {
public:
    virtual ~McpHost() = default;
    virtual CommandRegistry& commands() = 0;
    virtual std::string project_dir() const { return "."; }  // resolves relative image paths and project resources
    virtual std::string server_version() const;                // default FA_ENGINE_VERSION
    virtual std::string instructions() const;                  // default: default_mcp_instructions()
    virtual std::vector<McpResource> list_resources();         // default: docs + project files
    virtual Result<McpResourceContent> read_resource(std::string_view uri);
    virtual std::vector<McpPrompt> list_prompts();             // default: make-game, add-feature, fix-bug, report-engine-gap
    virtual Result<std::vector<McpPromptMessage>> get_prompt(std::string_view name, const Json& arguments);
};

// Host built from a registry and a project directory (default resources and prompts).
class SimpleMcpHost : public McpHost {
public:
    SimpleMcpHost(CommandRegistry& registry, std::string projectDir = ".")
        : registry_(registry), projectDir_(std::move(projectDir)) {}
    CommandRegistry& commands() override { return registry_; }
    std::string project_dir() const override { return projectDir_; }

private:
    CommandRegistry& registry_;
    std::string projectDir_;
};

// Concise engine guide sent as the MCP `instructions` field.
std::string default_mcp_instructions();
std::vector<McpPrompt> default_mcp_prompts();
Result<std::vector<McpPromptMessage>> default_mcp_prompt_messages(std::string_view name, const Json& arguments);
std::vector<McpResource> default_mcp_resources(const std::string& projectDir);
Result<McpResourceContent> default_mcp_read_resource(const std::string& projectDir, std::string_view uri);

// "scene.list_entities" -> "scene_list_entities" (chars [a-zA-Z0-9_-], at most 64).
std::string mcp_tool_name(std::string_view commandName);

inline constexpr const char* kMcpLatestProtocol = "2025-11-25";
const std::vector<std::string>& mcp_supported_protocols();

class McpServer {
public:
    explicit McpServer(McpHost& host);

    // Handles one incoming JSON-RPC message (request, notification, response or batch).
    // Returns the serialized response (single line, no newline), or nullopt when none is due.
    std::optional<std::string> handle_message(std::string_view message);

    // Receives server-initiated messages. Without a sink they are queued (see drain_outgoing).
    using Sink = std::function<void(const std::string& message)>;
    void set_notification_sink(Sink sink);
    std::vector<std::string> drain_outgoing();

    // notifications/tools/list_changed (call when commands were added/removed, e.g. JS tool hot reload).
    void notify_tools_changed();
    void notify_resources_changed();
    // notifications/message; `level` is an MCP level: debug, info, notice, warning, error, critical, alert, emergency.
    void log(const std::string& level, const std::string& logger, const Json& data);

    bool initialized() const { return initialized_; }
    const std::string& protocol_version() const { return protocol_; }
    const std::string& client_name() const { return clientName_; }

    // The tools/list entries for the current registry.
    Json tools_json() const;

private:
    std::optional<Json> handle_one(const Json& msg);
    Json handle_request(const std::string& method, const Json& params, const Json& id);
    Json call_tool(const Json& params);
    void emit(const Json& message);

    McpHost& host_;
    bool initialized_ = false;
    std::string protocol_ = kMcpLatestProtocol;
    std::string clientName_;
    std::string logLevel_ = "info";
    Sink sink_;
    std::vector<std::string> queued_;
    std::mutex outMutex_;
};

}  // namespace fa
