// Shared types for AI providers and the agent loop.
//
// The message model is provider-neutral but lossless: assistant messages keep
// the provider-native payload in `raw` and it is sent back UNCHANGED (this is
// how Anthropic thinking blocks survive between turns). History is append-only.
#pragma once

#include <atomic>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::ai {

// Cooperative cancellation: callers set it to true; long operations poll it.
using CancelFlag = std::atomic<bool>;
inline bool is_cancelled(const CancelFlag* f) { return f && f->load(std::memory_order_relaxed); }

enum class Role { User, Assistant };

struct ToolDef {
    std::string name;         // provider-safe name (no '.')
    std::string description;
    Json inputSchema;         // JSON Schema object
};

struct ToolCall {
    std::string id;
    std::string name;
    Json input = Json::object();
    std::string inputError;  // non-empty when the model's arguments were not valid JSON
};

struct ImageData {
    std::string mediaType;  // "image/png"
    std::string base64;
};

struct ToolResult {
    std::string toolUseId;
    std::string content;  // text (usually compact JSON)
    bool isError = false;
    std::vector<ImageData> images;
};

struct Message {
    Role role = Role::User;
    std::string text;                    // user text, or concatenated assistant text
    std::vector<ToolCall> toolCalls;     // assistant only
    std::vector<ToolResult> toolResults; // user only: ALL results of one assistant turn
    Json raw;                            // assistant only: provider-native payload, resent verbatim

    static Message user(std::string text);
    static Message tool_results(std::vector<ToolResult> results);
};

enum class StopReason { EndTurn, ToolUse, MaxTokens, PauseTurn, Refusal, Other };
const char* stop_reason_name(StopReason r);

struct Usage {
    u64 inputTokens = 0;
    u64 outputTokens = 0;
    u64 cacheCreationTokens = 0;
    u64 cacheReadTokens = 0;
    Usage& operator+=(const Usage& o);
    u64 total() const { return inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens; }
    Json to_json() const;
};

// USD per 1M tokens.
struct Pricing {
    double input = 0, output = 0, cacheRead = 0, cacheWrite = 0;
    bool known = false;
};
// Built-in table for Claude models (matched by substring, e.g. "claude-opus-5-5").
Pricing builtin_pricing(std::string_view model);
// Estimated cost in USD (0 when pricing unknown).
double estimate_cost(const Usage& u, const Pricing& p);

struct ChatRequest {
    std::string model;
    std::string effort;       // "low|medium|high|xhigh|max" or empty
    int maxTokens = 0;        // 0 = provider default
    std::string system;       // stable system prompt
    std::vector<ToolDef> tools;  // sorted by name by the caller for byte-stable caching
    std::vector<Message> messages;
    bool stream = false;
};

struct ChatResponse {
    Message message;  // assistant message (raw filled in)
    StopReason stopReason = StopReason::EndTurn;
    std::string rawStopReason;
    Usage usage;
    std::string model;
    std::string refusalCategory;     // only when stopReason == Refusal
    std::string refusalExplanation;
};

// Streaming callbacks (all optional).
struct ChatHooks {
    std::function<void(std::string_view)> onText;
    std::function<void(std::string_view)> onThinking;
    std::function<void(const std::string& toolName)> onToolUseStart;
    std::function<void(const std::string& message)> onRetry;  // transient failure, about to retry
};

// An event for UIs. Emitted by AgentSession and by CLI agents.
struct AgentEvent {
    enum class Type { SessionStart, TextDelta, ThinkingDelta, ToolStart, ToolEnd, Usage, Info, Done, Error };
    Type type = Type::Info;
    int depth = 0;        // 0 = main session, 1 = delegated sub-session
    std::string role;     // orchestrator|worker|fast|cli
    std::string text;     // text delta / info / error message / final text
    std::string toolName;
    Json toolInput;
    Json toolResult;
    bool isError = false;
    ai::Usage usage;      // cumulative for Type::Usage
    double costUsd = 0;   // cumulative for Type::Usage / Done
};
const char* event_type_name(AgentEvent::Type t);
using EventHandler = std::function<void(const AgentEvent&)>;

}  // namespace fa::ai
