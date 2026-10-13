// OpenAI-compatible Chat Completions API (OpenAI, OpenRouter, Gemini, Groq,
// DeepSeek, Ollama, LM Studio, ...).
#pragma once

#include "fa/ai/provider.h"
#include "fa/ai/sse.h"

namespace fa::ai::openai {

// Body for POST {baseUrl}/chat/completions.
Json build_request(const ChatRequest& req, const ProviderConfig& cfg);
std::string chat_completions_url(const ProviderConfig& cfg);

Result<ChatResponse> parse_response(const Json& body);

// Incremental SSE parser for streamed chat completions ("data: {...}" / "data: [DONE]").
class StreamAssembler {
public:
    explicit StreamAssembler(ChatHooks hooks = {})
        : hooks_(std::move(hooks)), sse_([this](const std::string&, const std::string& d) { handle_data(d); }) {}
    StreamAssembler(const StreamAssembler&) = delete;
    StreamAssembler& operator=(const StreamAssembler&) = delete;
    void feed(std::string_view chunk) { sse_.feed(chunk); }
    void finish() { sse_.finish(); }
    bool done() const { return done_; }
    bool has_error() const { return !error_.empty(); }
    const std::string& error() const { return error_; }
    // Reconstructed non-streaming-shaped body ({"choices":[{"message":..., "finish_reason":..}], "usage":..}).
    Json body() const;

private:
    void handle_data(const std::string& data);
    ChatHooks hooks_;
    SseSplitter sse_;
    std::string error_;
    std::string content_, reasoning_, finish_, model_;
    struct Tc { std::string id, name, args; };
    std::vector<Tc> calls_;
    Json usage_;
    bool done_ = false;
};

std::shared_ptr<ChatProvider> make_provider(const ProviderConfig& cfg, ProviderRuntime rt);

}  // namespace fa::ai::openai
