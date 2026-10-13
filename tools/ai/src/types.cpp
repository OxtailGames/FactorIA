#include "fa/ai/types.h"

#include "util.h"

namespace fa::ai {

Message Message::user(std::string text) {
    Message m;
    m.role = Role::User;
    m.text = std::move(text);
    return m;
}

Message Message::tool_results(std::vector<ToolResult> results) {
    Message m;
    m.role = Role::User;
    m.toolResults = std::move(results);
    return m;
}

const char* stop_reason_name(StopReason r) {
    switch (r) {
        case StopReason::EndTurn: return "end_turn";
        case StopReason::ToolUse: return "tool_use";
        case StopReason::MaxTokens: return "max_tokens";
        case StopReason::PauseTurn: return "pause_turn";
        case StopReason::Refusal: return "refusal";
        case StopReason::Other: return "other";
    }
    return "other";
}

const char* event_type_name(AgentEvent::Type t) {
    switch (t) {
        case AgentEvent::Type::SessionStart: return "session_start";
        case AgentEvent::Type::TextDelta: return "text";
        case AgentEvent::Type::ThinkingDelta: return "thinking";
        case AgentEvent::Type::ToolStart: return "tool_start";
        case AgentEvent::Type::ToolEnd: return "tool_end";
        case AgentEvent::Type::Usage: return "usage";
        case AgentEvent::Type::Info: return "info";
        case AgentEvent::Type::Done: return "done";
        case AgentEvent::Type::Error: return "error";
    }
    return "info";
}

Usage& Usage::operator+=(const Usage& o) {
    inputTokens += o.inputTokens;
    outputTokens += o.outputTokens;
    cacheCreationTokens += o.cacheCreationTokens;
    cacheReadTokens += o.cacheReadTokens;
    return *this;
}

Json Usage::to_json() const {
    return Json::object({{"inputTokens", inputTokens},
                         {"outputTokens", outputTokens},
                         {"cacheCreationTokens", cacheCreationTokens},
                         {"cacheReadTokens", cacheReadTokens}});
}

// Prices are USD per 1M tokens for prompts <= 100K tokens (estimates only).
Pricing builtin_pricing(std::string_view model) {
    auto has = [&](std::string_view s) { return model.find(s) != std::string_view::npos; };
    if (has("opus-5")) return {4.0, 20.0, 0.20, 5.0, true};
    if (has("sonnet-5")) return {2.0, 10.0, 0.20, 2.5, true};
    if (has("haiku-5")) return {0.10, 0.50, 0.01, 0.125, true};
    return {};
}

double estimate_cost(const Usage& u, const Pricing& p) {
    if (!p.known) return 0;
    return (static_cast<double>(u.inputTokens) * p.input + static_cast<double>(u.outputTokens) * p.output +
            static_cast<double>(u.cacheReadTokens) * p.cacheRead +
            static_cast<double>(u.cacheCreationTokens) * p.cacheWrite) / 1e6;
}

}  // namespace fa::ai
