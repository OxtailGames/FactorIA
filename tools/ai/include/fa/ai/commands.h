// Commands exposed by the AI module: ai.providers, ai.models and ai.run.
#pragma once

#include "fa/ai/config.h"
#include "fa/ai/session.h"
#include "fa/core/command.h"

namespace fa::ai {

struct AiCommandOptions {
    // Where config comes from. Default: load_config() (FACTORIA_AI_CONFIG / ~/.factoria/ai.json).
    std::function<Result<AiConfig>()> loadConfig;
    // Receives events while ai.run executes (CLI progress output).
    EventHandler onEvent;
    // Used instead of the real providers (tests).
    ProviderFactory providerFactory;
    // Project directory when the call does not pass one. Default: fa::fs::project_root().
    std::function<std::string()> projectDir;
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
