// The developer's side of efficiency feedback: what an entry sends, and how many entries from many installations are ranked
// (fa/tooling/efficiency.h, "Sharing and the developer's ranking"). Nothing here reads the clock, the network or a model.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <map>

#include "fa/tooling/efficiency.h"

namespace fa {

namespace {

double round_to(double v, double scale) { return std::round(v * scale) / scale; }
bool has(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::string str_of(const Json& j, const char* key) {
    if (!j.is_object()) return {};
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}

// The most a measure can hold: a transcript has at most kEfficiencyMaxSteps steps, and an entry keeps at most 200 spans of them.
constexpr double kMaxSteps = 20000.0 * 200.0;
constexpr double kMaxMinutes = 1.0e7;
constexpr double kMaxTokens = 1.0e12;
constexpr double kMaxUsd = 1.0e6;

EfficiencyMeasure clamped_measure(const Json& j) {
    EfficiencyMeasure m = EfficiencyMeasure::from_json(j);
    m.steps = static_cast<int>(std::clamp<double>(m.steps, 0, kMaxSteps));
    m.toolCalls = static_cast<int>(std::clamp<double>(m.toolCalls, 0, kMaxSteps * 50));
    m.minutes = round_to(std::clamp(m.minutes, 0.0, kMaxMinutes), 10);
    m.tokens = static_cast<std::uint64_t>(std::min<double>(static_cast<double>(m.tokens), kMaxTokens));
    m.costUsd = round_to(std::clamp(m.costUsd, 0.0, kMaxUsd), 10000);
    return m;
}

bool version_text_ok(const std::string& v) {
    if (v.empty() || v.size() > 32) return false;
    if (!std::isalnum(static_cast<unsigned char>(v[0]))) return false;
    for (char c : v)
        if (!std::isalnum(static_cast<unsigned char>(c)) && c != '.' && c != '+' && c != '_' && c != '-') return false;
    return true;
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------------ sharing

namespace {

Json block_from(const std::string& fixType, const std::string& appliesTo, const Json& measured, const Json& saving, double expectedShare,
                int spans, const std::string& afterFix, bool candidate) {
    Json b = Json::object();
    b["fixType"] = fixType;
    b["appliesTo"] = appliesTo;
    b["measured"] = clamped_measure(measured).to_json();
    b["saving"] = clamped_measure(saving).to_json();
    b["expectedShare"] = round_to(std::clamp(expectedShare, 0.0, 1.0), 100);
    b["spans"] = std::clamp(spans, 0, 200);
    if (version_text_ok(afterFix)) b["afterFix"] = afterFix;
    if (candidate) b["candidate"] = true;
    return b;
}

}  // namespace

Json efficiency_share_block(const Json& e) {
    if (!e.is_object() || str_of(e, "kind") != "efficiency") return Json();
    const std::string fixType = str_of(e, "fixType"), appliesTo = str_of(e, "appliesTo");
    if (!has(efficiency_fix_types(), fixType) || !has(efficiency_applies_to(), appliesTo) || appliesTo == "this-game") return Json();
    if (!e.contains("measured") || !e["measured"].is_object() || !e.contains("saving") || !e["saving"].is_object()) return Json();
    double share = 0;
    if (e.contains("expectedSaving") && e["expectedSaving"].is_object() && e["expectedSaving"].contains("share") &&
        e["expectedSaving"]["share"].is_number())
        share = e["expectedSaving"]["share"].get<double>();
    const int spans = e.contains("evidence") && e["evidence"].is_array() ? static_cast<int>(e["evidence"].size()) : 0;
    const bool candidate = e.contains("candidate") && e["candidate"].is_boolean() && e["candidate"].get<bool>();
    return block_from(fixType, appliesTo, e["measured"], e["saving"], share, spans, str_of(e, "afterFix"), candidate);
}

Json efficiency_clean_block(const Json& b) {
    if (!b.is_object()) return Json();
    const std::string fixType = str_of(b, "fixType"), appliesTo = str_of(b, "appliesTo");
    if (!has(efficiency_fix_types(), fixType) || !has(efficiency_applies_to(), appliesTo)) return Json();
    if (!b.contains("measured") || !b["measured"].is_object() || !b.contains("saving") || !b["saving"].is_object()) return Json();
    const double share = b.contains("expectedShare") && b["expectedShare"].is_number() ? b["expectedShare"].get<double>() : 0.0;
    const int spans = b.contains("spans") && b["spans"].is_number() ? static_cast<int>(b["spans"].get<double>()) : 0;
    const bool candidate = b.contains("candidate") && b["candidate"].is_boolean() && b["candidate"].get<bool>();
    return block_from(fixType, appliesTo, b["measured"], b["saving"], share, spans, str_of(b, "afterFix"), candidate);
}

// ------------------------------------------------------------------------------------------------------------------ ranking

double efficiency_fix_cost_hours(const std::string& fixType) {
    if (fixType == "doc") return 0.5;
    if (fixType == "guide") return 1.0;
    if (fixType == "example") return 2.0;
    if (fixType == "commandOption") return 4.0;
    if (fixType == "newCommand") return 8.0;
    return kEfficiencyRoadmapHours;  // engineChange (and anything unknown): the bar the roadmap asks
}

namespace {

std::string fmt(const char* format, double v) {
    char buf[48];
    std::snprintf(buf, sizeof buf, format, v);
    return buf;
}
// "6.4" and "$212.50": the numbers of a verdict.
std::string hours_text(double h) { return fmt("%.1f", h); }
std::string usd_text(double d) { return "$" + fmt("%.2f", d); }

double hours_of(const EfficiencyMeasure& m) { return std::max(m.minutes / 60.0, m.costUsd / kEfficiencyUsdPerHour); }

struct Triage {
    std::string code, text;
};

Triage triage_of(const std::string& fixType, const EfficiencyMeasure& total) {
    const double minutesHours = total.minutes / 60.0;
    if (fixType == "doc" || fixType == "guide" || fixType == "example") return {"doc-now", "doc now"};
    if (fixType == "commandOption" || fixType == "newCommand") {
        const double cost = efficiency_fix_cost_hours(fixType);
        if (hours_of(total) >= cost) return {"command-worth-it", "command: worth it"};
        return {"command-not-yet", "command: not yet (" + hours_text(hours_of(total)) + " of the " + hours_text(cost) + " hours it costs)"};
    }
    const std::string n = hours_text(minutesHours) + " of the " + fmt("%g", kEfficiencyRoadmapHours) + " hours / " + usd_text(total.costUsd) +
                          " of the $" + fmt("%g", kEfficiencyRoadmapUsd);
    if (minutesHours >= kEfficiencyRoadmapHours || total.costUsd >= kEfficiencyRoadmapUsd)
        return {"engine-roadmap", "engine change: reached the roadmap bar (" + n + ")"};
    return {"engine-below-threshold", "engine change: below threshold (" + n + " it needs)"};
}

// "about 12.5 minutes", "about 120k tokens" or "about 14 steps": what this entry measured, in its own words.
std::string own_saving_text(const EfficiencyMeasure& s) {
    if (s.minutes >= 1.0) return "about " + fmt("%.0f", std::round(s.minutes)) + " minutes";
    if (s.tokens >= 1000) return "about " + fmt("%.0f", std::round(static_cast<double>(s.tokens) / 1000.0)) + "k tokens";
    if (s.steps > 0) return "about " + std::to_string(s.steps) + " steps";
    return "very little";
}

std::string reject_reason_for(const std::string& code, const std::string& fixType, const EfficiencyMeasure& own) {
    const std::string mine = own_saving_text(own);
    if (code == "doc-now")
        return "This is answered by documentation, not by new engine code: a doc section or guide will carry it. Thank you for the measured "
               "report (" + mine + " saved where it was filed); look for it in the docs.";
    if (code == "command-worth-it" || code == "engine-roadmap")
        return "Not taken as proposed: the saving measured here (" + mine + ") is real, and the engine developer chose to cover it another "
               "way. Check the docs of the commands for it.";
    if (code == "command-not-yet")
        return "Not taken yet: a " + std::string(fixType == "commandOption" ? "command option" : "command") +
               " is built when the time it saves adds up to more than it costs to make, and this report alone shows " + mine +
               ". The commands that exist cover it for now.";
    return "Not taken as an engine change: a change like this is made only when the time it saves adds up to many hours across games, and "
           "this report shows " + mine + ". A doc section or a guide may cover it instead.";
}

std::string trust_of(const std::string& t) { return t == "verified" ? "verified" : t == "anonymous" ? "anonymous" : "local"; }

}  // namespace

Json rank_efficiency(std::vector<EfficiencyGroup> groups) {
    struct Item {
        Json j;
        double hours = 0, usd = 0;
        double tokens = 0;
        std::string title;
    };
    std::vector<Item> items;
    for (EfficiencyGroup& g : groups) {
        if (g.voices.empty()) continue;
        // Deterministic voices: by project, then id.
        std::stable_sort(g.voices.begin(), g.voices.end(), [](const EfficiencyVoice& a, const EfficiencyVoice& b) {
            if (a.project != b.project) return a.project < b.project;
            return a.id < b.id;
        });
        // An installation counts once: its entries here are added, and its weight is its best trust.
        struct Install {
            EfficiencyMeasure saving;
            double weight = 0;
            bool verified = false;
        };
        std::map<std::string, Install> installs;
        long reports = 0;
        std::vector<std::string> afterFix;
        for (const EfficiencyVoice& v : g.voices) {
            Install& in = installs[v.project];
            in.saving += v.saving;
            const std::string trust = trust_of(v.trust);
            in.weight = std::max(in.weight, trust == "anonymous" ? kEfficiencyAnonymousWeight : 1.0);
            in.verified = in.verified || trust == "verified";
            reports += std::max(1, v.occurrences);
            if (!v.afterFix.empty() && !has(afterFix, v.afterFix)) afterFix.push_back(v.afterFix);
        }
        std::sort(afterFix.begin(), afterFix.end());
        EfficiencyMeasure total;
        int verified = 0;
        for (const auto& [project, in] : installs) {
            total += scale_measure(in.saving, in.weight);
            if (in.verified) ++verified;
        }
        const double hours = round_to(hours_of(total), 10);
        const Triage verdict = triage_of(g.fixType, total);
        const double games = static_cast<double>(installs.size());

        Json j = Json::object();
        j["title"] = g.title;
        j["category"] = g.category;
        j["fixType"] = g.fixType;
        j["appliesTo"] = g.appliesTo;
        if (!g.suggestion.empty()) j["suggestion"] = g.suggestion;
        j["installations"] = static_cast<long>(installs.size());
        j["verifiedInstallations"] = static_cast<long>(verified);
        j["reports"] = reports;
        Json totalJson = total.to_json();
        totalJson["costUsd"] = round_to(total.costUsd, 100);
        totalJson["hours"] = hours;
        j["total"] = totalJson;
        j["perGame"] = Json::object({{"minutes", round_to(total.minutes / games, 10)},
                                     {"tokens", static_cast<std::uint64_t>(std::llround(static_cast<double>(total.tokens) / games))},
                                     {"costUsd", round_to(total.costUsd / games, 100)}});
        Json cost = Json::object({{"hours", efficiency_fix_cost_hours(g.fixType)}});
        if (g.fixType == "engineChange") cost["usd"] = kEfficiencyRoadmapUsd;
        j["fixCost"] = cost;
        j["verdict"] = Json::object({{"code", verdict.code}, {"text", verdict.text}});
        if (!afterFix.empty()) j["afterFix"] = afterFix;
        Json entries = Json::array();
        for (const EfficiencyVoice& v : g.voices) {
            Json e = Json::object({{"project", v.project}, {"id", v.id}, {"trust", trust_of(v.trust)}, {"occurrences", v.occurrences},
                                   {"saving", v.saving.to_json()}, {"measured", v.measured.to_json()},
                                   {"rejectReason", reject_reason_for(verdict.code, g.fixType, v.saving)}});
            if (!v.shareId.empty()) e["shareId"] = v.shareId;
            entries.push_back(std::move(e));
        }
        j["entries"] = std::move(entries);
        items.push_back({std::move(j), hours, round_to(total.costUsd, 100), static_cast<double>(total.tokens), g.title});
    }
    std::stable_sort(items.begin(), items.end(), [](const Item& a, const Item& b) {
        if (a.hours != b.hours) return a.hours > b.hours;
        if (a.usd != b.usd) return a.usd > b.usd;
        if (a.tokens != b.tokens) return a.tokens > b.tokens;
        return a.title < b.title;
    });
    Json out = Json::array();
    int rank = 1;
    for (Item& it : items) {
        Json j = Json::object({{"rank", rank++}});
        for (auto f = it.j.begin(); f != it.j.end(); ++f) j[f.key()] = f.value();
        out.push_back(std::move(j));
    }
    return out;
}

}  // namespace fa
