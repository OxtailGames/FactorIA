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

#include <chrono>
#include <functional>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
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

// Commands that install software on the user's computer: only the user starts them (the editor, the CLI). No MCP server
// lists or runs them, whatever the filter says, so an AI client (Claude Code included) cannot. Today: ai.plugin_install.
bool is_user_only_command(std::string_view commandName);

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

    // Progress of long tool calls (MCP notifications/progress). A tools/call that carries params._meta.progressToken
    // (Claude Code sends one with every call) gets progress notifications to the notification sink while its command
    // runs: whatever the command reports with report_command_progress() (fa/core/command.h; ai.run reports what its
    // sub-agent does), at most one per `throttle`, plus a "still running" heartbeat every `heartbeat` of silence, so a
    // client that aborts a call after minutes without a sign of life (Claude Code: 300 s) keeps waiting for as long as
    // the command really runs. Each message ends with the elapsed time. Without a token nothing is sent. Defaults:
    // 3 s and 15 s.
    void set_progress_timing(std::chrono::milliseconds throttle, std::chrono::milliseconds heartbeat);

    // Restricts the tools: a command for which `allow` returns false is neither listed by tools/list nor callable
    // (`factoria mcp --read-only` uses it for the read-only roles of a CLI agent that cannot disallow tools itself). No
    // filter = every command.
    using CommandFilter = std::function<bool(const CommandInfo&)>;
    void set_command_filter(CommandFilter allow) { filter_ = std::move(allow); }

    // notifications/tools/list_changed (call when commands were added/removed, e.g. JS tool hot reload).
    void notify_tools_changed();
    void notify_resources_changed();
    // notifications/message; `level` is an MCP level: debug, info, notice, warning, error, critical, alert, emergency.
    void log(const std::string& level, const std::string& logger, const Json& data);

    bool initialized() const { return initialized_; }
    const std::string& protocol_version() const { return protocol_; }
    const std::string& client_name() const { return clientName_; }
    const Json& client_capabilities() const { return clientCapabilities_; }
    const std::string& log_level() const { return logLevel_; }

    // The handshake, as a JSON object: {protocolVersion, clientInfo, clientCapabilities, logLevel}. A server that restarts
    // itself in place (fa/mcp/update_monitor.h) hands it to the new process, which restores it so that the client, which
    // initialized the old process, needs no new `initialize`. restore_session() marks the server initialized; a value that is
    // not an object, or has no protocolVersion, is refused (false) and leaves the server as it was.
    Json session_state() const;
    bool restore_session(const Json& state);

    // A note for the AI that reads the next tool result: `text` is added as a last text block of the result of the next
    // tools/call (the result itself stays the first block), once. A notice with the same `key` replaces the one still waiting.
    void add_tool_notice(const std::string& key, const std::string& text);
    // The notices waiting for a tools/call: texts in the order they were added.
    std::vector<std::string> pending_tool_notices() const;

    // The tools/list entries for the current registry.
    Json tools_json() const;

private:
    std::optional<Json> handle_one(const Json& msg);
    Json handle_request(const std::string& method, const Json& params, const Json& id);
    Json call_tool(const Json& params);
    Json run_tool(const Json& params);
    void emit(const Json& message);

    McpHost& host_;
    bool initialized_ = false;
    std::string protocol_ = kMcpLatestProtocol;
    std::string clientName_;
    Json clientInfo_ = Json::object();
    Json clientCapabilities_ = Json::object();
    std::string logLevel_ = "info";
    std::vector<std::pair<std::string, std::string>> notices_;  // {key, text} waiting for a tools/call
    mutable std::mutex noticeMutex_;
    Sink sink_;
    CommandFilter filter_;
    std::chrono::milliseconds progressThrottle_{3000};
    std::chrono::milliseconds progressHeartbeat_{15000};
    std::vector<std::string> queued_;
    std::mutex outMutex_;
};

}  // namespace fa
