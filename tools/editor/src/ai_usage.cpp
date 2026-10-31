#include "ai_usage.h"

#include <algorithm>
#include <cmath>
#include <cstdio>

#include "ai_chat.h"

namespace fa::editor {

namespace {

// (local_tm: ok = false for a time the C library cannot convert; then the callers show nothing rather than a made-up date)
std::string strftime_of(const char* format, const std::tm& tm) {
    char buf[64];
    return std::strftime(buf, sizeof buf, format, &tm) ? buf : "";
}

// 4.7 -> "4.7", 5.0 -> "5"
std::string one_decimal(double v) {
    const double r = std::round(v * 10.0) / 10.0;
    char buf[32];
    if (r == std::floor(r)) std::snprintf(buf, sizeof buf, "%d", static_cast<int>(r));
    else std::snprintf(buf, sizeof buf, "%.1f", r);
    return buf;
}

int window_rank(const std::string& name) { return name == "five_hour" ? 0 : name == "seven_day" ? 1 : 2; }

}  // namespace

std::string format_tokens(u64 n) {
    if (n < 1000) return std::to_string(n);
    if (n < 10000) return one_decimal(static_cast<double>(n) / 1000.0) + "k";
    if (n < 999500) return std::to_string(static_cast<u64>(std::llround(static_cast<double>(n) / 1000.0))) + "k";
    return one_decimal(static_cast<double>(n) / 1e6) + "M";
}

std::string format_percent(double fraction) {
    if (fraction < 0) return {};
    const long p = std::lround(std::min(fraction, 1.0) * 100.0);
    if (fraction > 0 && p < 1) return "<1%";
    return std::to_string(p) + "%";
}

std::string limit_label(const std::string& name) {
    if (name == "five_hour") return "Session (5h)";
    if (name == "seven_day") return "Week";
    if (name.starts_with("seven_day_")) return "Week (" + name.substr(10) + ")";
    if (name.starts_with("five_hour_")) return "Session (5h, " + name.substr(10) + ")";
    std::string out = name;
    std::replace(out.begin(), out.end(), '_', ' ');
    if (!out.empty()) out[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(out[0])));
    return out.empty() ? "Limit" : out;
}

std::vector<ai::LimitWindow> sorted_limits(std::vector<ai::LimitWindow> windows) {
    std::stable_sort(windows.begin(), windows.end(), [](const ai::LimitWindow& a, const ai::LimitWindow& b) {
        const int ra = window_rank(a.name), rb = window_rank(b.name);
        return ra != rb ? ra < rb : a.name < b.name;
    });
    return windows;
}

std::string format_clock(i64 epoch, i64 now) {
    if (epoch <= 0) return {};
    bool okThen = false, okNow = false;
    const std::tm t = local_tm(epoch, &okThen), n = local_tm(now, &okNow);
    if (!okThen || !okNow) return {};
    if (t.tm_year == n.tm_year && t.tm_yday == n.tm_yday) return strftime_of("%H:%M", t);
    if (epoch > now && epoch - now < 6 * 86400) return strftime_of("%a %H:%M", t);
    return strftime_of("%b %d %H:%M", t);
}

std::string format_date_time(i64 epoch) {
    if (epoch <= 0) return {};
    bool ok = false;
    const std::tm t = local_tm(epoch, &ok);
    return ok ? strftime_of("%Y-%m-%d %H:%M", t) : std::string();
}

LimitView limit_view(const ai::LimitWindow& window, i64 now) {
    LimitView v;
    v.label = limit_label(window.name);
    v.resetsAt = window.resetsAt;
    v.known = window.usedFraction >= 0;
    v.used = v.known ? std::min(window.usedFraction, 1.0) : 0.0;
    if (window.resetsAt > 0 && window.resetsAt <= now) {  // the window rolled over since the CLI reported it
        v.wasReset = true;
        v.known = true;
        v.used = 0;
    }
    return v;
}

ai::Usage RunUsage::minus(const ai::Usage& a, const ai::Usage& b) {
    auto sub = [](u64 x, u64 y) { return x > y ? x - y : u64(0); };
    ai::Usage r;
    r.inputTokens = sub(a.inputTokens, b.inputTokens);
    r.outputTokens = sub(a.outputTokens, b.outputTokens);
    r.cacheCreationTokens = sub(a.cacheCreationTokens, b.cacheCreationTokens);
    r.cacheReadTokens = sub(a.cacheReadTokens, b.cacheReadTokens);
    return r;
}

void RunUsage::update(const std::string& run, const ai::Usage& usage, double costUsd) {
    Entry& e = runs_[run];
    e.usage = usage;
    e.cost = costUsd;
}

ai::Usage RunUsage::usage() const {
    ai::Usage sum;
    for (const auto& [_, e] : runs_) sum += minus(e.usage, e.settled);
    return sum;
}

double RunUsage::cost() const {
    double sum = 0;
    for (const auto& [_, e] : runs_) sum += std::max(0.0, e.cost - e.settledCost);
    return sum;
}

void RunUsage::settle_orchestrator(const ai::Usage& finalUsage, double finalCost, ai::Usage& chatUsage, double& chatCost, bool all) {
    chatUsage += finalUsage;
    chatCost += finalCost;
    runs_.erase("");
    if (all) settle_all(chatUsage, chatCost);
}

void RunUsage::settle_all(ai::Usage& chatUsage, double& chatCost) {
    chatUsage += usage();
    chatCost += cost();
    runs_.clear();
}

}  // namespace fa::editor
