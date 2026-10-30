// Commands exposed by the AI module: ai.providers, ai.tool_servers, ai.models and ai.run.
#pragma once

#include <functional>
#include <string>

#include "fa/ai/config.h"
#include "fa/ai/session.h"
#include "fa/core/command.h"

namespace fa::ai {

// One ai.run call, as the callbacks below see it.
struct AiRunInfo {
    std::string id;        // "run-1", "run-2"...: unique in this process, ties a run's events and its end together
    std::string role;      // the role the run uses: orchestrator|worker|fast|artist|audio
    std::string task;      // the task text the caller gave
};

struct AiCommandOptions {
    // Where config comes from. Default: load_config() (FACTORIA_AI_CONFIG / ~/.factoria/ai.json).
    std::function<Result<AiConfig>()> loadConfig;
    // Receives events while ai.run executes (CLI progress output).
    EventHandler onEvent;
    // Used instead of the real providers (tests).
    ProviderFactory providerFactory;
    // Project directory when the call does not pass one. Default: fa::fs::project_root().
    std::function<std::string()> projectDir;
    // The editor's live view of a sub-agent. ai.run calls onRunStart, then onRunEvent for every event of the run, then
    // onRunEnd with its outcome (also when it failed or was stopped). All three run on the thread that executes ai.run
    // (not the UI thread): hand the data over, do not draw. `report` is the run's final text, "" on failure.
    std::function<void(const AiRunInfo&)> onRunStart;
    std::function<void(const AiRunInfo&, const AgentEvent&)> onRunEvent;
    std::function<void(const AiRunInfo&, bool ok, const std::string& report, const std::string& error)> onRunEnd;
    // The run's CLI agent process started (its pid, for process_tree()); same thread rules.
    std::function<void(const AiRunInfo&, long long pid)> onRunProcess;
    // Stops a running ai.run (the editor's Stop). nullptr = it runs to the end.
    const CancelFlag* cancel = nullptr;
    // MCP endpoint a CLI sub-agent attaches (SessionOptions::mcpUrl): the editor's, so ai.run edits its world too.
    std::string mcpUrl;
    // HTTP transport and environment of ai.models (tests inject fakes). Default: the real ones.
    ProviderRuntime runtime;
};

// Registers "ai.providers" (list/doctor), "ai.models" (the models each provider offers) and "ai.run" (run a task
// synchronously with the configured role). The registry is also the tool source for the agent
// (ai.* commands are hidden from the model to avoid recursion). It must outlive
// the registered handlers.
void register_ai_commands(CommandRegistry& registry, AiCommandOptions options = {});

}  // namespace fa::ai
