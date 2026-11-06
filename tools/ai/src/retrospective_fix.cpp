// Did the fix work? (fa/ai/retrospective.h, "did the fix work?"). The comparison of a fixed efficiency entry's baseline with the same pattern
// in the transcripts written since the fix. Nothing here reads the clock, the network or a model.
#include <algorithm>
#include <cmath>
#include <cstdio>

#include "fa/ai/retrospective.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

// "0.17.2" -> {0, 17, 2}; text after the numbers (a suffix such as "-rc1") is ignored. {} when it does not start with a digit.
std::vector<long> version_parts(const std::string& v) {
    std::vector<long> parts;
    std::size_t i = 0;
    while (i < v.size() && parts.size() < 4) {
        if (!std::isdigit(static_cast<unsigned char>(v[i]))) break;
        long n = 0;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) n = std::min(n * 10 + (v[i++] - '0'), 1000000L);
        parts.push_back(n);
        if (i < v.size() && v[i] == '.') ++i;
        else break;
    }
    return parts;
}

// a >= b, component by component (a missing component is 0).
bool version_at_least(const std::string& a, const std::string& b) {
    std::vector<long> x = version_parts(a), y = version_parts(b);
    if (x.empty() || y.empty()) return false;
    const std::size_t n = std::max(x.size(), y.size());
    x.resize(n, 0);
    y.resize(n, 0);
    return x >= y;
}

// "2026-11-01" -> "20261101"; "" when it is not a date.
std::string compact_day(const std::string& day) {
    if (day.size() != 10 || day[4] != '-' || day[7] != '-') return {};
    std::string out = day.substr(0, 4) + day.substr(5, 2) + day.substr(8, 2);
    return std::all_of(out.begin(), out.end(), [](unsigned char c) { return std::isdigit(c) != 0; }) ? out : std::string();
}

double round1(double v) { return std::round(v * 10.0) / 10.0; }
double round2(double v) { return std::round(v * 100.0) / 100.0; }

// What one occurrence weighs: the tokens and the minutes the way the candidates are ranked (a minute is worth 5000 tokens); steps when
// a transcript has neither.
double weight_of(double tokens, double minutes, double steps) {
    const double w = tokens + 5000.0 * minutes;
    return w > 0 ? w : steps * 1000.0;
}

std::string per_text(const Json& side) {
    char buf[96];
    std::snprintf(buf, sizeof buf, "%.1f min, %.0fk tokens", num(side, "minutes"), num(side, "tokens") / 1000.0);
    return buf;
}

}  // namespace

Json FixCheck::to_json() const {
    Json j = Json::object({{"entry", entry}, {"pattern", pattern}, {"fixedIn", fixedIn}, {"fixedAt", fixedAt}, {"result", result},
                           {"sessionsAfter", sessionsAfter}, {"spansAfter", spansAfter}, {"ratio", ratio}, {"before", before}, {"text", text}});
    if (!after.is_null()) j["after"] = after;
    return j;
}

std::vector<FixCheck> check_efficiency_fixes(const std::vector<EfficiencySession>& sessions, const Json& entries, const std::string& engineVersion) {
    std::vector<FixCheck> out;
    if (!entries.is_array()) return out;
    for (const Json& e : entries) {
        if (!e.is_object() || str(e, "kind") != "efficiency" || str(e, "status") != "fixed-in-engine") continue;
        FixCheck c;
        c.entry = str(e, "id");
        c.pattern = str(e, "pattern");
        c.fixedIn = str(e, "fixedIn");
        c.fixedAt = str(e, "fixedAt");
        const Json* base = child(e, "fixBaseline");
        const std::string day = compact_day(c.fixedAt);
        if (c.entry.empty() || c.pattern.empty() || !base || !base->is_object() || day.empty()) continue;
        if (!version_at_least(engineVersion, c.fixedIn)) continue;  // this game does not run the fix yet
        const double baseWeight = weight_of(num(*base, "tokens"), num(*base, "minutes"), num(*base, "steps"));
        if (baseWeight <= 0) continue;
        c.before = Json::object({{"spans", num(*base, "spans")}, {"steps", num(*base, "steps")}, {"minutes", num(*base, "minutes")},
                                 {"tokens", num(*base, "tokens")}});

        // The transcripts of the days since the fix (their ids start with the day, YYYYMMDD).
        std::vector<EfficiencySession> after;
        for (const EfficiencySession& s : sessions) {
            if (s.id.size() >= 8 && std::all_of(s.id.begin(), s.id.begin() + 8, [](unsigned char ch) { return std::isdigit(ch) != 0; }) &&
                s.id.compare(0, 8, day) >= 0 && !s.steps.empty())
                after.push_back(s);
        }
        c.sessionsAfter = static_cast<int>(after.size());
        if (after.empty()) {
            c.result = "waiting";
            c.text = "No AI run of this project since the fix in FactorIA " + c.fixedIn + " (" + c.fixedAt + "): nothing to compare yet.";
            out.push_back(std::move(c));
            continue;
        }
        const std::vector<RetroCandidate> found = find_retro_candidates(after, Json(), true);
        const auto it = std::find_if(found.begin(), found.end(), [&](const RetroCandidate& r) { return r.id == c.pattern; });
        if (it == found.end() || it->spans.empty()) {
            c.result = "gone";
            c.text = "The pattern is not found in the " + std::to_string(c.sessionsAfter) + " run(s) since the fix in FactorIA " + c.fixedIn +
                     ": it worked (before: " + per_text(c.before) + " per occurrence).";
            out.push_back(std::move(c));
            continue;
        }
        const double n = static_cast<double>(it->spans.size());
        c.spansAfter = static_cast<int>(it->spans.size());
        c.after = Json::object({{"spans", c.spansAfter}, {"steps", round1(it->measured.steps / n)}, {"minutes", round1(it->measured.minutes / n)},
                                {"tokens", std::llround(static_cast<double>(it->measured.tokens) / n)}});
        const double afterWeight = weight_of(static_cast<double>(it->measured.tokens) / n, it->measured.minutes / n, it->measured.steps / n);
        c.ratio = round2(afterWeight / baseWeight);
        c.result = c.ratio <= 0.5 ? "worked" : c.ratio > 0.8 ? "no_change" : "partial";
        char pct[16];
        std::snprintf(pct, sizeof pct, "%.0f%%", c.ratio * 100.0);
        c.text = std::string(c.result == "worked" ? "Worked" : c.result == "partial" ? "Partly worked" : "No change") + ": one occurrence costs " + pct +
                 " of what it did (" + per_text(c.before) + " before, " + per_text(c.after) + " in the " + std::to_string(c.sessionsAfter) +
                 " run(s) since the fix in FactorIA " + c.fixedIn + ").";
        out.push_back(std::move(c));
    }
    std::sort(out.begin(), out.end(), [](const FixCheck& a, const FixCheck& b) { return a.entry < b.entry; });
    return out;
}

}  // namespace fa::ai
