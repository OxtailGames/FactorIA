#include "ai_usage.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <ctime>
#include <fstream>

#include "ai_chat.h"

namespace fa::editor {

namespace {

// ok = false for a time the C library cannot convert (then the callers show nothing rather than a made-up date)
std::tm local_tm(i64 epoch, bool* ok = nullptr) {
    std::time_t t = static_cast<std::time_t>(epoch);
    std::tm tm{};
#ifdef _WIN32
    const bool good = localtime_s(&tm, &t) == 0;
#else
    const bool good = localtime_r(&t, &tm) != nullptr;
#endif
    if (ok) *ok = good;
    return tm;
}

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

bool starts_with(const std::string& s, const std::string& prefix) { return s.compare(0, prefix.size(), prefix) == 0; }

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
    if (starts_with(name, "seven_day_")) return "Week (" + name.substr(10) + ")";
    if (starts_with(name, "five_hour_")) return "Session (5h, " + name.substr(10) + ")";
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

Json limits_to_json(const LimitsByProvider& limits) {
    Json providers = Json::object();
    for (const auto& [name, pl] : limits) {
        Json windows = Json::array();
        for (const auto& w : pl.windows) {
            Json wj = Json::object({{"name", w.name}, {"resetsAt", w.resetsAt}});
            if (w.usedFraction >= 0) wj["usedFraction"] = w.usedFraction;
            windows.push_back(std::move(wj));
        }
        providers[name] = Json::object({{"updated", pl.updated}, {"windows", windows}});
    }
    return Json::object({{"format", "factoria.ai_limits/1"}, {"providers", providers}});
}

LimitsByProvider limits_from_json(const Json& j) {
    LimitsByProvider out;
    if (!j.is_object() || !j.contains("providers") || !j["providers"].is_object()) return out;
    for (const auto& [name, pj] : j["providers"].items()) {
        if (!pj.is_object() || !pj.contains("windows") || !pj["windows"].is_array()) continue;
        ProviderLimits pl;
        pl.updated = pj.value("updated", static_cast<i64>(0));
        for (const auto& wj : pj["windows"]) {
            if (!wj.is_object() || !wj.contains("name") || !wj["name"].is_string()) continue;
            ai::LimitWindow w;
            w.name = wj["name"].get<std::string>();
            w.usedFraction = wj.contains("usedFraction") && wj["usedFraction"].is_number() ? wj["usedFraction"].get<double>() : -1.0;
            w.resetsAt = wj.value("resetsAt", static_cast<i64>(0));
            pl.windows.push_back(std::move(w));
        }
        if (!pl.windows.empty()) out[name] = std::move(pl);
    }
    return out;
}

LimitsByProvider load_limits(const std::string& path) {
    std::ifstream in(utf8_path(path), std::ios::binary);
    if (!in) return {};
    const std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    return limits_from_json(Json::parse(text, nullptr, false));
}

bool save_limits(const std::string& path, const LimitsByProvider& limits) {
    std::error_code ec;
    std::filesystem::create_directories(utf8_path(path).parent_path(), ec);
    std::ofstream out(utf8_path(path), std::ios::binary | std::ios::trunc);
    if (!out) return false;
    out << limits_to_json(limits).dump(2, ' ', false, Json::error_handler_t::replace) << "\n";
    return static_cast<bool>(out);
}

std::string limits_path(const std::string& home) {
    return home.empty() ? std::string() : utf8_string(utf8_path(home) / ".factoria" / "ai_limits.json");
}

}  // namespace fa::editor
