// Agent loop for chat providers (API keys) and the wrapper that runs CLI agents.
#pragma once

#include <map>
#include <memory>

#include "fa/ai/cli_agent.h"
#include "fa/ai/config.h"
#include "fa/ai/provider.h"
#include "fa/ai/types.h"
#include "fa/core/command.h"

namespace fa::ai {

// What carries a chat from one message to the next. The caller (the editor) keeps it between `AgentSession::run` calls:
// pass the previous `SessionResult::conversation` in `SessionOptions::conversation`.
//   * CLI agents with a {session} placeholder in their argv (Claude Code): the CLI's own session id; a follow-up resumes
//     it and sends only the new task (the system prompt is already part of it).
//   * API chat providers: the messages so far (append-only, assistant payloads untouched).
// `key` says who produced it ("<provider>" for a CLI, "<provider>/<model>" for a chat provider): a run with another key
// (the user switched provider or model) starts a new conversation instead of feeding one provider another one's state.
struct Conversation {
    std::string key;
    std::string cliSessionId;
    double cliCostUsd = 0;             // running total the CLI reported for the session (Claude Code counts cumulatively)
    std::vector<Message> history;
    bool empty() const { return cliSessionId.empty() && history.empty(); }
    Json to_json() const;
    static Conversation from_json(const Json& j);
};

struct SessionOptions {
    std::string projectDir;            // project root (context, transcripts, MCP --project)
    Conversation conversation;         // continue this conversation (empty = start a new one)
    std::string role = kRoleOrchestrator;
    std::string providerOverride;      // replaces the role's provider (depth 0 only)
    std::string modelOverride;         // replaces the role's model (depth 0 only)
    int maxTurns = 0;                  // 0 = config limits.maxTurns
    double maxCostUsd = -1;            // <0 = config limits; 0 = unlimited
    u64 maxTotalTokens = 0;            // 0 = config limits
    bool stream = true;
    bool saveTranscript = true;        // <project>/.factoria/ai/sessions/*.jsonl
    bool allowDelegation = true;       // orchestrator gets agent_delegate
    std::string extraSystem;           // appended to the system prompt
};

struct SessionResult {
    bool ok = false;
    std::string finalText;
    std::string stopReason;            // end_turn | max_turns | budget | refusal | cancelled | error | cli
    std::string error;
    std::string hint;
    Usage usage;
    double costUsd = 0;
    int turns = 0;
    std::string transcriptPath;        // main session transcript ("" when disabled)
    Conversation conversation;         // pass it back in SessionOptions::conversation to continue the chat
    Json to_json() const;
};

using ProviderFactory = std::function<Result<std::shared_ptr<ChatProvider>>(const ProviderConfig&)>;

// Commands the model must not call (recursion): "ai.*".
bool is_agent_tool_excluded(std::string_view commandName);
// "scene.spawn" -> "scene_spawn" (provider-safe tool names).
std::string tool_name_for_command(std::string_view commandName);
// Tool list from the registry, sorted by name (byte-stable for prompt caching).
std::vector<ToolDef> tools_from_registry(const CommandRegistry& registry, bool withDelegate);

struct PromptContext {
    std::string projectDir;
    std::string role;
    bool canDelegate = false;
    std::string extra;
    std::string delegateTool;  // the tool the orchestrator delegates with; "" = agent_delegate (CLI agents: ai_run over MCP)
};
// Stable system prompt: engine guide summary + project context + rules.
std::string build_system_prompt(const PromptContext& ctx);

inline constexpr const char* kDelegateTool = "agent_delegate";

class AgentSession {
public:
    AgentSession(CommandRegistry& registry, AiConfig config, SessionOptions options = {});

    void set_event_handler(EventHandler handler) { onEvent_ = std::move(handler); }
    void set_provider_factory(ProviderFactory f) { factory_ = std::move(f); }
    void set_cancel_flag(const CancelFlag* c) { cancel_ = c; }

    // Runs the task to completion (synchronously). `imageFiles` are pictures (absolute paths, .png .jpg .jpeg .gif .webp)
    // the user attached to this message; an unreadable one fails the run before anything is sent.
    SessionResult run(const std::string& task, const std::vector<std::string>& imageFiles = {});

private:
    SessionResult run_role(const std::string& role, const std::string& task, int depth);
    SessionResult run_chat(const std::string& role, const RoleConfig& rc, const ProviderConfig& pc,
                           const std::string& task, int depth);
    SessionResult run_cli(const std::string& role, const RoleConfig& rc, const ProviderConfig& pc,
                          const std::string& task, int depth);
    ToolResult execute_tool(const ToolCall& call, const std::string& role, int depth);
    void emit(AgentEvent e, int depth, const std::string& role);
    bool over_budget(std::string& why) const;
    void add_usage(const Usage& u, double cost);

    CommandRegistry& registry_;
    AiConfig config_;
    SessionOptions opt_;
    EventHandler onEvent_;
    ProviderFactory factory_;
    const CancelFlag* cancel_ = nullptr;
    std::map<std::string, std::shared_ptr<ChatProvider>> providers_;
    std::map<std::string, std::string> toolToCommand_;
    Usage totalUsage_;
    double totalCost_ = 0;
    int delegateCount_ = 0;
    std::string stamp_;
    std::string systemCache_;
    std::vector<ImageData> images_;          // the attached pictures of the current run (depth 0 only)
    std::vector<std::string> imagePaths_;
};

}  // namespace fa::ai
