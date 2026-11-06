// Commands exposed by the AI module: ai.providers, ai.tool_servers, ai.models and ai.run.
#pragma once

#include <functional>
#include <string>

#include "fa/ai/asset_cost.h"
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
    // The user's ai.json, for the project-aware paths (the resolution of the project's settings, ai.settings.get/set, the refusal of
    // a role the project turned off). "" = default_config_path(env). Its ai-trust.json lies next to it (tests point both at a temp dir).
    std::string aiConfigPath;
    // Called after ai.settings.set (scope "user") wrote the user's ai.json, on the thread that ran the command (an AI or MCP thread in
    // the editor: hand the work to the UI thread). The editor reloads its copy of ai.json and its AI windows from it.
    std::function<void()> onUserConfigChanged;
    // Called after ai.settings.set (scope "project") wrote or removed the project's settings file; same thread rules. The editor drops
    // its cache of the project's resolution.
    std::function<void()> onProjectConfigChanged;
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
    // Why `cancel` was set (a cause key, see cancel_cause_text()); read when a run ends cancelled, so its error and the ai.run
    // result say who stopped it. Empty = unknown.
    std::function<std::string()> cancelCause;
    // The run the asset-generating commands of this registry count into ("per run" in limits.maxAssetCostUsd, "Approve all for this
    // run"): the editor passes the chat id of the run. "" = the commands count into the run of the calling thread (AssetRunScope),
    // which is the whole process for the CLI and MCP.
    std::string assetRunKey;
    // Who is asked when an asset-generating command of this registry needs the user's yes (a paid call above limits.askAboveUsd):
    // the editor's approval card. It runs on the thread of the call and may block until the user answers; it must give up with
    // Cancel when the run's cancel flag is set. Empty = the call returns a needsApproval answer (CLI, MCP, scripts).
    AssetApprover assetApprover;
    // MCP endpoint a CLI sub-agent attaches (SessionOptions::mcpUrl): the editor's, so ai.run edits its world too.
    std::string mcpUrl;
    // HTTP transport and environment of ai.models (tests inject fakes). Default: the real ones.
    ProviderRuntime runtime;
};

// Registers "ai.providers" (list/doctor), "ai.settings.get" / "ai.settings.set" (the AI settings of the project and the user's
// own), "ai.models" (the models each provider offers) and "ai.run" (run a task synchronously with the configured role, under the
// project's AI settings). The registry is also the tool source for the agent (ai.* commands are hidden from the model to avoid
// recursion). It must outlive the registered handlers.
void register_ai_commands(CommandRegistry& registry, AiCommandOptions options = {});

}  // namespace fa::ai
