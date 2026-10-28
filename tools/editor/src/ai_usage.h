// What the AI panel shows about usage: the plan limits (session / week) and token counts. Pure functions, tested without
// a window (tools/editor/tests).
#pragma once

#include <map>
#include <string>
#include <vector>

#include "fa/ai/types.h"

namespace fa::editor {

// "950", "4.7k", "47k", "470k", "1M", "1.2M"
std::string format_tokens(u64 n);
// "6%", "<1%" for a sliver, "100%"; "" for an unknown (negative) fraction.
std::string format_percent(double fraction);
// A window's name for people: five_hour = "Session (5h)", seven_day = "Week", seven_day_opus = "Week (opus)", others
// spelled out ("1_day" = "1 day").
std::string limit_label(const std::string& name);
// five_hour, seven_day, then the rest by name.
std::vector<ai::LimitWindow> sorted_limits(std::vector<ai::LimitWindow> windows);
// When a window resets, in local time: "14:30" today, "Fri 18:00" within the next days, "Oct 21 18:00" later. "" if unknown.
std::string format_clock(i64 epoch, i64 now);
// "2026-10-14 15:30" in local time.
std::string format_date_time(i64 epoch);

// A window as the panel draws it. A window whose reset time has passed has reset: it shows 0% used.
struct LimitView {
    std::string label;
    double used = 0;       // 0..1 (0 when unknown)
    bool known = false;    // false: the CLI sent no percentage, only a reset time
    bool wasReset = false;
    i64 resetsAt = 0;
};
LimitView limit_view(const ai::LimitWindow& window, i64 now);

// Plan windows per provider, as the CLI last reported them in this run of the editor. Not kept between runs: other
// Claude Code / Codex sessions use the same plan meanwhile, so remembered numbers would be wrong at the next start.
struct ProviderLimits {
    i64 updated = 0;  // when the CLI last reported them (epoch seconds)
    std::vector<ai::LimitWindow> windows;
};
using LimitsByProvider = std::map<std::string, ProviderLimits>;

// Tokens and cost of the run in progress, kept per agent: the orchestrator ("") and each sub-agent run (ai.run's id).
// An agent's Usage events carry ITS running totals, so a new event replaces that agent's entry (never another's); the
// panel shows the sum. When the run ends the totals move into the chat's own exactly once.
class RunUsage {
public:
    // The latest totals of agent `run` ("" = the orchestrator itself).
    void update(const std::string& run, const ai::Usage& usage, double costUsd);
    // Sum over the agents of what is not in the chat's totals yet.
    ai::Usage usage() const;
    double cost() const;
    bool empty() const { return runs_.empty(); }
    // The orchestrator's session ended with these final totals (its SessionResult): they replace its live ones and move
    // into `chatUsage` / `chatCost`. With `all` the sub-agents' totals move too and nothing stays; without it (a worker
    // outlived the orchestrator's turn and still spends) they stay, and `settle_all` moves what they spent later.
    void settle_orchestrator(const ai::Usage& finalUsage, double finalCost, ai::Usage& chatUsage, double& chatCost, bool all);
    void settle_all(ai::Usage& chatUsage, double& chatCost);
    void clear() { runs_.clear(); }

private:
    struct Entry {
        ai::Usage usage;
        double cost = 0;
        ai::Usage settled;  // part of it already moved into the chat
        double settledCost = 0;
    };
    static ai::Usage minus(const ai::Usage& a, const ai::Usage& b);
    std::map<std::string, Entry> runs_;
};

}  // namespace fa::editor
