// Anthropic Messages API (raw HTTP, no SDK).
#pragma once

#include "fa/ai/provider.h"
#include "fa/ai/sse.h"

namespace fa::ai::anthropic {

struct Auth {
    std::string apiKey;       // x-api-key
    std::string bearerToken;  // Authorization: Bearer (+ anthropic-beta oauth) when no key
};

// The credentials requests use: the API key, else (useAntCli) the `ant` token (rt.antToken; default `ant auth
// print-credentials`). An Error with a hint when there are none.
Result<Auth> resolve_auth(const ProviderConfig& cfg, const ProviderRuntime& rt);

// Request body for POST /v1/messages. Deterministic: tools sorted by name,
// stable key order. Never contains thinking/temperature/top_p; tool_choice omitted.
Json build_request(const ChatRequest& req);

// True for models that get server-side refusal fallback (Opus 5.5 / Sonnet 5.5, not Haiku).
bool supports_fallbacks(std::string_view model);

// Headers for a request (auth, version, beta flags).
std::vector<std::pair<std::string, std::string>> build_headers(const ChatRequest& req, const Auth& auth,
                                                               const ProviderConfig& cfg);

// Parses a non-streaming response body (or a message reconstructed from SSE).
Result<ChatResponse> parse_response(const Json& body);

// Incremental SSE parser: feed raw chunks, it reconstructs the final message
// identically to the non-streaming response.
class StreamAssembler {
public:
    explicit StreamAssembler(ChatHooks hooks = {})
        : hooks_(std::move(hooks)), sse_([this](const std::string& e, const std::string& d) { handle_event(e, d); }) {}
    StreamAssembler(const StreamAssembler&) = delete;
    StreamAssembler& operator=(const StreamAssembler&) = delete;
    void feed(std::string_view chunk) { sse_.feed(chunk); }
    void finish() { sse_.finish(); }  // flush a trailing partial event
    bool done() const { return done_; }
    bool has_error() const { return !error_.empty(); }
    const std::string& error() const { return error_; }
    const std::string& error_type() const { return errorType_; }
    // The reconstructed message in non-streaming shape.
    const Json& message() const { return message_; }
    bool started() const { return started_; }

private:
    void handle_event(const std::string& event, const std::string& data);
    ChatHooks hooks_;
    SseSplitter sse_;
    std::string error_, errorType_;
    Json message_ = Json::object();
    std::vector<std::string> partialJson_;  // per content block index
    bool started_ = false, done_ = false;
};

std::shared_ptr<ChatProvider> make_provider(const ProviderConfig& cfg, ProviderRuntime rt);

}  // namespace fa::ai::anthropic
