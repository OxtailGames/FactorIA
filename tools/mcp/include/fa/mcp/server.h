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

#include <atomic>
#include <chrono>
#include <cstddef>
#include <functional>
#include <map>
#include <memory>
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

// The largest tool result the server sends, in bytes of JSON (the default of McpServer::set_result_cap). A client puts the
// result into its model's context (Claude Code refuses one over about 25k tokens; JSON is about 3 bytes a token), so a
// larger one is cut down first.
inline constexpr std::size_t kMcpResultCap = 80 * 1024;

// What the McpServers answering one client share: the handshake (the protocol version initialize negotiated) and the
// requests in flight, which notifications/cancelled reaches. A transport that makes one server per message (the editor's
// per-run HTTP endpoint, where requests run at the same time on their own threads) gives each of them the same session;
// a server that is not given one has its own. Thread-safe.
class McpSession {
public:
    // The handshake of the client's initialize; empty protocol until there was one.
    struct Handshake {
        std::string protocolVersion;
        Json clientInfo = Json::object();
        Json clientCapabilities = Json::object();
    };
    void set_handshake(Handshake h);
    Handshake handshake() const;

    // A transport that queues requests (stdio: one runs at a time) announces one it has read and not started yet, so that
    // a notifications/cancelled that arrives while it waits is kept: begin_request() then starts it cancelled, and the
    // server skips it (no response). Only for an id the server will begin (a string or number id, not initialize); each
    // call is consumed by one begin_request() with that id.
    void expect_request(const Json& id);
    // A request starts: its cancel flag, set by cancel() while it runs (already set when it was cancelled while queued,
    // see expect_request). Several requests with the same id (a client's mistake) are all cancelled together.
    std::shared_ptr<std::atomic<bool>> begin_request(const Json& id);
    // The request ended: forgets it and says whether it was cancelled (then no response may be sent). The decision is
    // taken under the same lock as cancel(), so a cancel that comes after it finds nothing and is ignored.
    bool end_request(const Json& id, const std::shared_ptr<std::atomic<bool>>& flag);
    // notifications/cancelled: sets the flag of the request `id`, running or queued (expect_request); false when there is
    // no such request (unknown or already answered), which is ignored.
    bool cancel(const Json& id);
    // The client is gone (stdio: stdin closed): cancels every request running or queued. Returns how many.
    std::size_t cancel_all();
    std::size_t requests_in_flight() const;
    std::size_t requests_queued() const;

private:
    mutable std::mutex mu_;
    Handshake handshake_;
    std::multimap<std::string, std::shared_ptr<std::atomic<bool>>> inFlight_;  // id.dump() -> flag
    std::multimap<std::string, bool> queued_;  // id.dump() -> cancelled while queued
};

class McpServer {
public:
    explicit McpServer(McpHost& host);

    // Handles one incoming JSON-RPC message (request, notification, response or batch).
    // Returns the serialized response (single line, no newline), or nullopt when none is due: a notification, or a
    // request the client cancelled (notifications/cancelled) while it ran, which gets no response at all (MCP spec,
    // "Cancellation"). A message that only cancels (is_cancel_notification) may be handled on another thread while a
    // request runs: that is how a transport lets a client take back a long tools/call.
    // Never throws: invalid JSON is a Parse error (-32700); a message of the wrong shape (a number for "jsonrpc" or
    // "method", an object for "id", a string for "params", a non-object in a batch) an Invalid Request (-32600) carrying
    // its id when it has a valid one; an exception while a request runs an Internal error (-32603), and a notification
    // that fails is dropped with a log line.
    std::optional<std::string> handle_message(std::string_view message);
    // True when `message` is one valid notifications/cancelled (not a batch, not an Invalid Request): a transport that handles requests one at a time
    // hands it to handle_message() at once instead of queueing it behind the request it cancels.
    static bool is_cancel_notification(std::string_view message);
    // The id of the request handle_message() runs for `msg` (and tracks in the session, McpSession::begin_request): a valid
    // JSON-RPC 2.0 object with a string method other than initialize, a string or number id and object params (or none).
    // Null for anything else (a notification, a response, an initialize, an invalid message). A transport that queues
    // requests announces this id (McpSession::expect_request), so a cancel read while it waits finds it.
    static Json runnable_request_id(const Json& msg);

    // Shares the handshake and the requests in flight with the other servers of the same client (see McpSession). A
    // session that already saw an initialize gives this server its protocol version, client info and capabilities.
    void share_session(std::shared_ptr<McpSession> session);
    const std::shared_ptr<McpSession>& session() const { return session_; }

    // A tool result is sent once, as JSON text in `content` (pretty when it fits the cap), whatever the protocol: no
    // `structuredContent`, so a client that reads only `content` misses nothing. A result with a picture (`$image`) gets an
    // image block after the text.
    // Tool results larger than `bytes` of JSON are cut down (kMcpResultCap by default; at least 8 KiB, a smaller value
    // counts as 8 KiB). The heaviest part goes first: an array or an object keeps its first items or keys, a long string
    // its start (never inside a UTF-8 sequence). An object result gets a `_truncated` field ({"note": ...}) that says what
    // was cut and which paging arguments of the command fetch the rest (or which arguments ask for less); any other result
    // is sent as {"result": <the cut result>, "_truncated": {...}}. What is sent is always valid JSON. A picture is sent
    // whole: the cap counts the JSON only.
    void set_result_cap(std::size_t bytes);

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

    // The capabilities every tools/call runs with (CommandCapabilityScope; it only narrows, so it never exceeds what the
    // calling thread has). Default capability_sets::mcp() (all but writeAnywhere): a command that needs more is refused
    // with capability_denied. `factoria mcp --read-only` sets capability_sets::mcp_read_only().
    void set_capabilities(CapabilitySet granted) { capabilities_ = granted; }
    CapabilitySet capabilities() const { return capabilities_; }

    // A tool profile: tools/list offers the core commands (fa/tooling/tool_groups.h) plus the commands of `groups` (command
    // categories, exact command names, "core") and three loader tools: `tool_load` {groups} adds groups to the list and sends
    // notifications/tools/list_changed, `tool_describe` {commands} returns the full definition of any command and
    // `tool_call` {command, arguments} runs any command, for clients that ignore list_changed. A group that matches no
    // command is refused: the result is the error text (with did-you-mean suggestions), "" when the profile is set. A list
    // with "all" (or no profile) is the default: every command, no loader tools. The command filter and
    // is_user_only_command still apply to everything loaded or called this way.
    std::string set_tool_profile(const std::vector<std::string>& groups);
    bool tool_profile_active() const;

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
    std::optional<Json> handle_one(const Json& msg);  // never throws
    std::optional<Json> handle_valid_one(const Json& msg);
    std::optional<Json> internal_error(const Json& msg, const std::string& what);
    Json handle_request(const std::string& method, const Json& params, const Json& id, const std::atomic<bool>* cancel);
    Json call_tool(const Json& params, const std::atomic<bool>* cancel);
    Json run_tool(const Json& params, const std::atomic<bool>* cancel);
    void emit(const Json& message);
    bool visible(const CommandInfo& c) const;  // not user-only, allowed by the filter
    bool listed(const CommandInfo& c) const;   // visible and in the current profile
    bool listed_locked(const CommandInfo& c) const;  // the profile part of listed(); profileMutex_ must be held
    Json tool_json(const CommandInfo& c) const;
    Json loader_tools_json() const;
    Json run_loader_tool(const std::string& tool, const Json& args, const Json& params, const std::atomic<bool>* cancel);
    std::string validate_groups(const std::vector<std::string>& groups) const;

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
    CapabilitySet capabilities_ = capability_sets::mcp();
    bool profile_ = false;                // a profile other than "all" is set
    std::vector<std::string> loaded_;     // the groups the profile and tool_load added (the core set is always in)
    mutable std::mutex profileMutex_;
    std::chrono::milliseconds progressThrottle_{3000};
    std::chrono::milliseconds progressHeartbeat_{15000};
    std::size_t resultCap_ = kMcpResultCap;
    std::shared_ptr<McpSession> session_ = std::make_shared<McpSession>();
    std::vector<std::string> queued_;
    std::mutex outMutex_;
};

}  // namespace fa
