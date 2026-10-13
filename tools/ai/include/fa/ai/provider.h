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

}  // namespace fa::ai
