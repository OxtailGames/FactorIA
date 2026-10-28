// Chat-with-tools provider interface (API providers) and factory.
#pragma once

#include <memory>

#include "fa/ai/config.h"
#include "fa/ai/http.h"
#include "fa/ai/types.h"

namespace fa::ai {

class ChatProvider {
public:
    virtual ~ChatProvider() = default;
    virtual std::string name() const = 0;
    // One model turn. Network/API failures are returned as Error (already
    // retried where appropriate). Never throws.
    virtual Result<ChatResponse> chat(const ChatRequest& request, const ChatHooks& hooks, const CancelFlag* cancel) = 0;
};

struct ProviderRuntime {
    HttpTransport transport;                       // default: http_request
    EnvLookup env = system_env();
    std::function<void(double seconds)> sleep;     // default: real sleep (cancel-aware); tests inject no-ops
    // Runs `ant auth print-credentials --access-token`; default uses the process runner.
    std::function<std::string()> antToken;
};

// Creates the provider for a config entry. CLI kinds are rejected (use CliAgent).
Result<std::shared_ptr<ChatProvider>> make_chat_provider(const ProviderConfig& cfg, ProviderRuntime rt = {});

// A model a provider offers (list_models).
struct ModelInfo {
    std::string id;           // the value for roles.<role>.model: "opus", "claude-opus-5-5", "gpt-5"...
    std::string name;         // display name ("Opus 5.5"); empty when the provider gives none
    std::string description;  // one line; may be empty
    std::string resolved;     // the model an alias stands for ("claude-opus-5-5" for "opus"); empty otherwise
};

// Asks the provider which models it offers: Claude Code through its CLI (the initialize request: no model call, no
// usage), the Anthropic and OpenAI-compatible APIs through GET /models (rt.transport, rt.env). Codex and generic CLIs
// cannot list their models: an Error with the hint to type the name. Failures are Errors that say what to check.
Result<std::vector<ModelInfo>> list_models(const ProviderConfig& cfg, ProviderRuntime rt = {});

// The models a provider always accepts, for a model list when list_models cannot answer (the CLI is not installed or
// not logged in yet): Claude Code's aliases default / opus / sonnet / haiku. Empty for every other kind.
std::vector<ModelInfo> fallback_models(ProviderKind kind);

}  // namespace fa::ai
