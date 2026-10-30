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
    std::string mcpUrl;                // CLI agents attach this MCP endpoint (the editor's) instead of `factoria mcp`
    // A CLI agent's process started (any depth): its pid (fa/core/process.h process_tree()) and role. Runs on the thread
    // that runs the session. The editor's "check activity" asks the OS about these processes.
    std::function<void(long long pid, const std::string& role)> onProcessStart;
};

struct SessionResult {
    bool ok = false;
    std::string finalText;
    std::string stopReason;            // end_turn | max_turns | budget | refusal | cancelled | error | cli
    std::string error;
    std::string hint;
    std::string cancelCause;           // stopReason "cancelled": why (cancel_cause_text() words it), "" when nobody said
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
// Commands a read-only role (artCritic, reviewer) may use: the ones that only observe (CommandInfo::readOnly) and the ones
// that play the running game without changing the project (game.step, game.input, game.click, game.screenshot, scene.load,
// ...; see the list in session.cpp). Everything else changes the project, a file or a setting, or spends money.
bool is_read_only_tool(const CommandInfo& info);
// The tool name a CLI agent sees for a command through the MCP server (scene.spawn -> scene_spawn, at most 64 characters).
std::string mcp_tool_name_for(std::string_view commandName);
// The tools to switch off for a CLI agent running `role`, as Claude Code names them (`--disallowedTools`): its own
// sub-agent tools (Agent, Task: their work is invisible to the editor and lost when the run ends), the FactorIA tools that
// start other agents or reviews (mcp__factoria__ai_run unless `canDelegate`, always mcp__factoria__ai_review), and for the
// read-only roles also the file-editing tools, Bash and every FactorIA command that is not is_read_only_tool.
std::vector<std::string> cli_disallowed_tools(const CommandRegistry& registry, std::string_view role, bool canDelegate);
// Tool list from the registry, sorted by name (byte-stable for prompt caching). `readOnly`: only is_read_only_tool commands.
std::vector<ToolDef> tools_from_registry(const CommandRegistry& registry, bool withDelegate, bool readOnly = false);

struct PromptContext {
    std::string projectDir;
    std::string role;
    bool canDelegate = false;
    std::string extra;
    std::string delegateTool;  // the tool the orchestrator delegates with; "" = agent_delegate (CLI agents: ai_run over MCP)
    AssetSources assetSources; // the sites the user listed for assets (ai.json "assetSources"); roles that look for assets read them
    // Delegable roles the user turned off (AiConfig::disabled_delegable_roles). The orchestrator's prompt lists only the
    // others and says it does the work of these itself, with the art/audio guidance the role's own prompt would give.
    std::vector<std::string> disabledRoles;
};
// The "Asset sources" section of the prompt of the roles that look for assets: the listed sites per category, the rule (prefer
// them, or use ONLY them when `onlyListed`) and how to record where an asset came from. "" when no site is listed.
std::string asset_sources_prompt(const AssetSources& sources);
// Stable system prompt: engine guide summary + project context + rules.
std::string build_system_prompt(const PromptContext& ctx);

// Why a run was cancelled, as the host names it (set with the cancel flag, see AgentSession::set_cancel_cause): user_stop,
// stuck_stop (the Stop of the stuck warning), watchdog_process_gone, activity_check_process_gone, project_closed,
// editor_closing, editor_restart, run_ended. An unknown key is shown as it is; "" gives plain "cancelled".
std::string cancel_cause_text(const std::string& cause);
// "cancelled" or "cancelled: <cause text>": what a cancelled run's error says.
std::string cancelled_message(const std::string& cause);

inline constexpr const char* kDelegateTool = "agent_delegate";

class AgentSession {
public:
    AgentSession(CommandRegistry& registry, AiConfig config, SessionOptions options = {});

    void set_event_handler(EventHandler handler) { onEvent_ = std::move(handler); }
    void set_provider_factory(ProviderFactory f) { factory_ = std::move(f); }
    void set_cancel_flag(const CancelFlag* c) { cancel_ = c; }
    // Asked when the run ends cancelled: the cause key the host set with the flag ("" = unknown). Written in the transcript's end
    // event ("cause"), SessionResult::cancelCause and the error text.
    void set_cancel_cause(std::function<std::string()> f) { cancelCause_ = std::move(f); }

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
    bool over_budget(const Usage& usageNow, double costNow, std::string& why) const;  // with these totals instead
    void add_usage(const Usage& u, double cost);

    CommandRegistry& registry_;
    AiConfig config_;
    SessionOptions opt_;
    EventHandler onEvent_;
    ProviderFactory factory_;
    const CancelFlag* cancel_ = nullptr;
    std::function<std::string()> cancelCause_;
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
