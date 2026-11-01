// One question to a model and its answer as text: no tools, no conversation. For small jobs that the engine does for a person
// and that must not touch the project (ai.review_feedback; the developer's `feedback pull` classification could use it too).
#pragma once

#include <functional>
#include <string>

#include "fa/ai/config.h"
#include "fa/ai/session.h"
#include "fa/core/types.h"

namespace fa::ai {

// The system text is the instructions, the user text the data. The answer is the model's text.
using TextModel = std::function<Result<std::string>(const std::string& system, const std::string& user)>;

struct TextModelOptions {
    // The role whose provider, model and effort answer. A role the user turned off falls back to the orchestrator, so a
    // person who only configured one model still gets answers; the choice is reported in TextModelInfo.
    std::string role = kRoleFast;
    // Used instead of the real providers (tests; the editor passes nothing). Used for every provider kind, with no key check.
    ProviderFactory providerFactory;
    ProviderRuntime runtime;  // HTTP transport and environment of the real providers
    // Folder a CLI agent (Claude Code, Codex...) runs in: an empty one, so the model sees nothing of the project. Created when
    // missing. Empty = a folder in the system temp directory.
    std::string cliWorkDir;
};

struct TextModelInfo {
    std::string role;      // the role that answers (the requested one, or "orchestrator" when it is off)
    std::string provider;
    std::string model;
};

// The model of `options.role`. Error (with a hint) when the role names no provider, the CLI is not installed, the provider only
// makes assets or the API provider has no key. Chat providers are called with no tools and 4096 output tokens at most; CLI
// agents run read-only with every tool that changes things or reaches the network disallowed.
Result<TextModel> make_text_model(const AiConfig& cfg, const TextModelOptions& options = {}, TextModelInfo* info = nullptr);

}  // namespace fa::ai
