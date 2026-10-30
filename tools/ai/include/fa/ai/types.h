// Shared types for AI providers and the agent loop.
//
// The message model is provider-neutral but lossless: assistant messages keep
// the provider-native payload in `raw` and it is sent back UNCHANGED (this is
// how Anthropic thinking blocks survive between turns). History is append-only.
#pragma once

#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"

namespace fa::ai {

// Cooperative cancellation: callers set it to true; long operations poll it. Defined in fa_core (fa/core/process.h).
using fa::CancelFlag;
using fa::is_cancelled;

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

// "image/png" | "image/jpeg" | "image/gif" | "image/webp" for a file name ending in .png .jpg .jpeg .gif .webp (any case),
// "" for anything else. These are the image types the providers accept.
std::string image_media_type_for_path(std::string_view path);
// Reads an image file into base64. The error names the file and what is wrong (missing, not an accepted type, empty).
Result<ImageData> load_image_data(const std::string& path);

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
    std::vector<ImageData> images;       // user only: images the user attached to this message

    static Message user(std::string text, std::vector<ImageData> images = {});
    static Message tool_results(std::vector<ToolResult> results);
};

// Message <-> JSON (the editor saves a conversation's history with it). The base64 payloads are left out (user images and
// tool-result images become a note in the text): a saved chat stays small, and the pictures are files in the project anyway.
Json saved_message_json(const Message& m);
Message message_from_json(const Json& j);

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
    u64 maxContextTokens = 0;  // > 0: the API summarizes earlier turns past this many input tokens (Anthropic only)
};

struct ChatResponse {
    Message message;  // assistant message (raw filled in)
    StopReason stopReason = StopReason::EndTurn;
    std::string rawStopReason;
    Usage usage;
    u64 contextTokens = 0;  // input + cache of the call that answered, when the provider tells it apart from `usage`
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

// One rate-limit window of a plan, as CLI agents report them: "five_hour" is the session limit, "seven_day" the weekly
// one; other names may appear (a CLI can add windows at any time), so UIs treat names generically.
struct LimitWindow {
    std::string name;
    double usedFraction = -1;  // 0..1; negative = the CLI did not say
    i64 resetsAt = 0;          // epoch seconds when the window resets; 0 = unknown
};

// An event for UIs. Emitted by AgentSession and by CLI agents.
struct AgentEvent {
    enum class Type { SessionStart, TextDelta, ThinkingDelta, ToolStart, ToolEnd, Usage, Info, Done, Error };
    Type type = Type::Info;
    int depth = 0;        // 0 = main session, 1 = delegated sub-session
    std::string role;     // orchestrator|worker|fast|artist|audio|artCritic|reviewer|cli
    std::string text;     // text delta / info / error message / final text
    std::string toolName;
    std::string toolId;   // the provider's id of the tool call (ToolStart and its ToolEnd share it); "" when the agent gives none
    Json toolInput;
    Json toolResult;
    bool isError = false;
    ai::Usage usage;      // cumulative for Type::Usage
    double costUsd = 0;   // cumulative for Type::Usage / Done
    // Type::Usage from a CLI agent: costUsd is the engine's running estimate (the price table applied to the tokens seen
    // so far), not yet the CLI's own total. The CLI's total replaces it when the run's result arrives.
    bool costIsEstimate = false;
    // Set by a host that forwards the events of several runs (the editor, for ai.run sub-agents): which run this
    // event belongs to. Empty = the session itself.
    std::string runId;
    // Type::Usage only. An event may carry just one of these (the others stay empty / 0 = "nothing new"):
    std::vector<LimitWindow> limits;  // plan windows the CLI reported (merge them by name)
    u64 contextTokens = 0;            // tokens in the model's context after its last call (input + cache)
    u64 contextWindow = 0;            // size of the model's context window
};
const char* event_type_name(AgentEvent::Type t);
// One short line saying what an event means for someone watching ("running Bash (cmake --build build)", "writing",
// "thinking"); "" for events that say nothing new (tool results, the system init). Used for the progress an ai.run call
// reports to its MCP client and for the activity line of the editor's AI panel.
std::string describe_agent_event(const AgentEvent& e);
using EventHandler = std::function<void(const AgentEvent&)>;

}  // namespace fa::ai
