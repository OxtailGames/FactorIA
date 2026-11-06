#include "fa/ai/retrospective.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <map>
#include <set>
#include <sstream>

#include "fa/ai/savers.h"
#include "fa/ai/text_model.h"
#include "fa/core/build_info.h"
#include "fa/core/date.h"
#include "fa/core/strings.h"
#include "fa/tooling/feedback.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

std::atomic<bool> g_running{false};
thread_local bool t_runningHere = false;

// One retrospective at a time in a process (a second one would read the same transcripts and file the same entries), and never one
// inside another: the holder is the only thing that can start the model call that could lead to a run.
class RetrospectiveGuard {
public:
    RetrospectiveGuard() {
        bool expected = false;
        held_ = g_running.compare_exchange_strong(expected, true);
        if (held_) t_runningHere = true;
    }
    ~RetrospectiveGuard() {
        if (held_) {
            t_runningHere = false;
            g_running = false;
        }
    }
    RetrospectiveGuard(const RetrospectiveGuard&) = delete;
    RetrospectiveGuard& operator=(const RetrospectiveGuard&) = delete;
    bool held() const { return held_; }

private:
    bool held_ = false;
};

double round2(double v) { return std::round(v * 100.0) / 100.0; }

std::string category_of(const std::string& command) {
    const std::size_t dot = command.find('.');
    return dot == std::string::npos ? std::string() : command.substr(0, dot);
}
bool is_engine_command(const EfficiencyToolCall& c) { return c.command.find('.') != std::string::npos && c.command.find(' ') == std::string::npos; }

bool is_doc_read(const EfficiencyToolCall& c) { return starts_with(c.command, "docs.") && !c.ref.empty(); }
bool is_file_read(const EfficiencyToolCall& c) {
    const std::string n = to_lower(c.name);
    return (n == "read" || n == "read_file" || c.command == "file.read" || c.command == "fs.read") && !c.ref.empty();
}
bool is_screenshot(const EfficiencyToolCall& c) {
    return to_lower(c.command).find("screenshot") != std::string::npos || to_lower(c.name).find("screenshot") != std::string::npos;
}

// A piece of evidence a detector found, with the share of its numbers a fix could remove.
struct Part {
    EfficiencySpan span;
    EfficiencyMeasure measure;
    double share = 0;
};

struct Acc {
    RetroCandidate c;
    std::vector<Part> parts;
    std::set<std::string> sessions;
    std::uint64_t maxBytes = 0;     // big_result: the largest result
    std::int64_t waitMs = 0;        // long_wait: the time the calls took
    int streaks = 0;                // screenshots
    int loopSteps = 0;              // loop
};

using Map = std::map<std::string, Acc>;

Acc& acc_for(Map& m, const std::string& id, const char* pattern) {
    Acc& a = m[id];
    if (a.c.id.empty()) {
        a.c.id = id;
        a.c.pattern = pattern;
    }
    return a;
}

// Adds a part unless it overlaps one of the same session already kept (the same steps are never counted twice).
bool add_part(Acc& a, const EfficiencySession& s, int from, int to, double share) {
    from = std::max(1, from);
    to = std::min(to, static_cast<int>(s.steps.size()));
    if (from > to) return false;
    for (const Part& p : a.parts)
        if (p.span.session == s.id && from <= p.span.toStep && to >= p.span.fromStep) return false;
    Part p;
    p.span = {s.id, from, to};
    p.measure = measure_span(s, from, to);
    p.share = std::clamp(share, 0.01, 1.0);
    a.parts.push_back(std::move(p));
    a.sessions.insert(s.id);
    return true;
}

std::string fmt_kb(std::uint64_t bytes) { return std::to_string((bytes + 512) / 1024) + " KB"; }
std::string fmt_minutes(std::int64_t ms) {
    std::ostringstream o;
    o << std::round(static_cast<double>(ms) / 6000.0) / 10.0;
    return o.str();
}

// ---- the detectors ----------------------------------------------------------------------------------------------------------

// The same (command, error code) failing kRetroMinFailures times in a session. The span runs from the first failure to the last call
// of that command (the one that worked, when one did).
void detect_failures(const EfficiencySession& s, Map& out) {
    std::map<std::pair<std::string, std::string>, std::vector<int>> failures;
    for (const EfficiencyStep& st : s.steps)
        for (const EfficiencyToolCall& c : st.calls)
            if (c.failed && !c.code.empty() && is_engine_command(c) && c.code != "cancelled") failures[{c.command, c.code}].push_back(st.number);
    for (const auto& [key, steps] : failures) {
        if (static_cast<int>(steps.size()) < kRetroMinFailures) continue;
        int last = steps.back();
        for (const EfficiencyStep& st : s.steps)
            if (st.number > last && std::any_of(st.calls.begin(), st.calls.end(), [&](const auto& c) { return c.command == key.first; })) last = st.number;
        const int spanSteps = last - steps.front() + 1;
        Acc& a = acc_for(out, "failure:" + key.first + ":" + key.second, "failure");
        a.c.command = key.first;
        a.c.code = key.second;
        a.c.suggestedFix = "doc";
        a.c.appliesTo = "feature";
        a.c.count += static_cast<int>(steps.size());
        // Each failed call was a step the model would not have needed.
        add_part(a, s, steps.front(), last, std::min(0.9, static_cast<double>(steps.size()) / std::max(1, spanSteps)));
    }
}

// The same doc (or file) read again and again.
void detect_rereads(const EfficiencySession& s, Map& out) {
    std::map<std::pair<std::string, std::string>, std::vector<int>> reads;  // (command, ref) -> steps
    for (const EfficiencyStep& st : s.steps) {
        std::set<std::pair<std::string, std::string>> seen;
        for (const EfficiencyToolCall& c : st.calls) {
            if (c.failed || !(is_doc_read(c) || is_file_read(c))) continue;
            if (seen.insert({c.command, c.ref}).second) reads[{c.command, c.ref}].push_back(st.number);
        }
    }
    for (const auto& [key, steps] : reads) {
        if (static_cast<int>(steps.size()) < kRetroMinRepeats) continue;
        const bool file = !starts_with(key.first, "docs.");
        Acc& a = acc_for(out, "reread:" + key.first + ":" + key.second, "reread");
        a.c.command = key.first;
        a.c.ref = key.second;
        a.c.suggestedFix = "doc";
        a.c.appliesTo = file ? "this-game" : "feature";
        a.c.projectOnly = file;
        a.c.count += static_cast<int>(steps.size());
        const int spanSteps = steps.back() - steps.front() + 1;
        // Everything after the first read was a repeat.
        add_part(a, s, steps.front(), steps.back(), std::min(0.8, static_cast<double>(steps.size() - 1) / std::max(1, spanSteps)));
    }
}

// Tool results over the size budget: the model reads them on this step and carries them on the next ones.
void detect_big_results(const EfficiencySession& s, Map& out) {
    std::map<std::string, std::vector<std::pair<int, std::uint64_t>>> big;  // command -> (step, bytes)
    for (const EfficiencyStep& st : s.steps)
        for (const EfficiencyToolCall& c : st.calls)
            if (is_engine_command(c) && c.resultBytes >= kRetroBigResultBytes) big[c.command].push_back({st.number, c.resultBytes});
    for (const auto& [command, hits] : big) {
        if (static_cast<int>(hits.size()) < kRetroMinBigResults) continue;
        Acc& a = acc_for(out, "big_result:" + command, "big_result");
        a.c.command = command;
        a.c.suggestedFix = "commandOption";
        a.c.appliesTo = "every-game";
        a.c.count += static_cast<int>(hits.size());
        for (const auto& [step, bytes] : hits) {
            a.maxBytes = std::max(a.maxBytes, bytes);
            const int to = std::min(step + 1, static_cast<int>(s.steps.size()));
            const EfficiencyMeasure m = measure_span(s, step, to);
            if (m.tokens == 0) continue;
            // The result's own tokens (about 3.75 bytes each) that a smaller answer would not have carried, most of them.
            const double share = 0.8 * (static_cast<double>(bytes) / 3.75) / static_cast<double>(m.tokens);
            add_part(a, s, step, to, std::min(0.9, share));
        }
    }
}

// Screenshots in a row.
void detect_screenshots(const EfficiencySession& s, Map& out) {
    int run = 0;
    auto close = [&](int endStep) {
        if (run >= kRetroScreenshotStreak) {
            Acc& a = acc_for(out, "screenshots", "screenshots");
            a.c.suggestedFix = "commandOption";
            a.c.appliesTo = "every-game";
            a.c.count += run;
            if (add_part(a, s, endStep - run + 1, endStep, static_cast<double>(run - 2) / run)) ++a.streaks;  // the first two are the check
        }
        run = 0;
    };
    for (const EfficiencyStep& st : s.steps) {
        if (std::any_of(st.calls.begin(), st.calls.end(), is_screenshot)) ++run;
        else close(st.number - 1);
    }
    close(static_cast<int>(s.steps.size()));
}

// A tool that kept the run waiting.
void detect_waits(const EfficiencySession& s, Map& out) {
    struct Wait {
        std::int64_t ms = 0;
        int longCalls = 0;
        std::vector<int> steps;
    };
    std::map<std::string, Wait> waits;
    for (const EfficiencyStep& st : s.steps) {
        for (const EfficiencyToolCall& c : st.calls) {
            if (!is_engine_command(c) || c.ms <= 0) continue;
            Wait& w = waits[c.command];
            w.ms += c.ms;
            if (c.ms >= kRetroLongWaitMs) {
                ++w.longCalls;
                if (w.steps.empty() || w.steps.back() != st.number) w.steps.push_back(st.number);
            }
        }
    }
    for (const auto& [command, w] : waits) {
        if (w.steps.empty() || (w.longCalls < 2 && w.ms < kRetroLongWaitTotalMs)) continue;
        Acc& a = acc_for(out, "long_wait:" + command, "long_wait");
        a.c.command = command;
        a.c.suggestedFix = "commandOption";
        a.c.appliesTo = "feature";
        a.c.count += w.longCalls;
        a.waitMs += w.ms;
        for (int step : w.steps) {
            const EfficiencyMeasure m = measure_span(s, step, step);
            std::int64_t stepWait = 0;
            for (const EfficiencyToolCall& c : s.steps[static_cast<std::size_t>(step - 1)].calls)
                if (c.command == command && c.ms >= kRetroLongWaitMs) stepWait += c.ms;
            if (m.minutes <= 0) continue;
            add_part(a, s, step, step, std::min(0.9, (static_cast<double>(stepWait) / 60000.0) / m.minutes));
        }
    }
}

// A long run of steps that stay on one or two systems and keep calling the same command: edit, run, check, again.
void detect_loops(const EfficiencySession& s, Map& out) {
    const int n = static_cast<int>(s.steps.size());
    auto categories = [&](int idx) {
        std::set<std::string> cats;
        for (const EfficiencyToolCall& c : s.steps[static_cast<std::size_t>(idx)].calls)
            if (is_engine_command(c) && !starts_with(c.command, "docs.")) cats.insert(category_of(c.command));
        return cats;
    };
    int i = 0;
    while (i < n) {
        std::set<std::string> cats = categories(i);
        if (cats.empty()) { ++i; continue; }
        int j = i + 1;
        while (j < n) {
            std::set<std::string> next = categories(j);
            std::set<std::string> merged = cats;
            merged.insert(next.begin(), next.end());
            if (merged.size() > 2) break;
            cats = std::move(merged);
            ++j;
        }
        const int len = j - i;
        std::map<std::string, int> uses;
        int most = 0;
        for (int k = i; k < j; ++k) {
            std::set<std::string> once;
            for (const EfficiencyToolCall& c : s.steps[static_cast<std::size_t>(k)].calls)
                if (is_engine_command(c) && once.insert(c.command).second) most = std::max(most, ++uses[c.command]);
        }
        int regulars = 0;  // an edit-run-check loop uses at least two commands over and over
        for (const auto& [command, n] : uses)
            if (n >= kRetroLoopRepeats / 2) ++regulars;
        if (len >= kRetroLoopSteps && most >= kRetroLoopRepeats && regulars >= 2) {
            std::string key;
            for (const std::string& c : cats) key += (key.empty() ? "" : "+") + c;
            Acc& a = acc_for(out, "loop:" + key, "loop");
            a.c.command = key;
            a.c.suggestedFix = "guide";
            a.c.appliesTo = "feature";
            a.c.count += len;
            if (add_part(a, s, i + 1, j, 0.4)) a.loopSteps += len;
        }
        i = j > i ? j : i + 1;
    }
}

// A command the project's ENGINE_FEEDBACK says needs a workaround, called again and again.
void detect_workarounds(const EfficiencySession& s, const Json& entries, Map& out) {
    if (!entries.is_array()) return;
    std::map<std::string, std::vector<int>> calls;  // command -> steps
    for (const EfficiencyStep& st : s.steps) {
        std::set<std::string> once;
        for (const EfficiencyToolCall& c : st.calls)
            if (is_engine_command(c) && once.insert(c.command).second) calls[c.command].push_back(st.number);
    }
    for (const Json& e : entries) {
        if (!e.is_object() || str(e, "status", "open") != "open" || str(e, "kind") == "efficiency") continue;
        const std::string text = str(e, "workaround") + " " + str(e, "missing") + " " + str(e, "title");
        for (const auto& [command, steps] : calls) {
            if (static_cast<int>(steps.size()) < kRetroLoopRepeats || text.find(command) == std::string::npos) continue;
            Acc& a = acc_for(out, "workaround:" + str(e, "id") + ":" + command, "workaround");
            a.c.command = command;
            a.c.relatedEntry = str(e, "id");
            a.c.suggestedFix = "commandOption";
            a.c.appliesTo = "feature";
            a.c.count += static_cast<int>(steps.size());
            const int spanSteps = steps.back() - steps.front() + 1;
            add_part(a, s, steps.front(), steps.back(), std::min(0.5, static_cast<double>(steps.size()) / std::max(1, spanSteps)));
        }
    }
}

std::string summarize(const Acc& a, int sessionCount) {
    const RetroCandidate& c = a.c;
    const std::string in = sessionCount > 1 ? " in " + std::to_string(sessionCount) + " sessions" : std::string();
    if (c.pattern == "failure") return "`" + c.command + "` failed with `" + c.code + "` " + std::to_string(c.count) + " times" + in;
    if (c.pattern == "reread")
        return "`" + c.command + " " + c.ref + "` was read " + std::to_string(c.count) + " times" + in;
    if (c.pattern == "big_result")
        return "`" + c.command + "` returned " + std::to_string(c.count) + " results over " + fmt_kb(kRetroBigResultBytes) + " (the largest " +
               fmt_kb(a.maxBytes) + ")" + in;
    if (c.pattern == "screenshots")
        return std::to_string(c.count) + " steps in a row took a screenshot (" + std::to_string(a.streaks) + (a.streaks == 1 ? " streak)" : " streaks)") + in;
    if (c.pattern == "long_wait")
        return "`" + c.command + "` kept the run waiting " + fmt_minutes(a.waitMs) + " minutes in total, " + std::to_string(c.count) +
               " calls of a minute or more" + in;
    if (c.pattern == "loop")
        return std::to_string(a.loopSteps) + " steps stayed on " + c.command + " calling one command again and again (edit, run, check)" + in;
    if (c.pattern == "workaround")
        return "`" + c.command + "` was called in " + std::to_string(c.count) + " steps, the workaround " + c.relatedEntry + " of ENGINE_FEEDBACK records" + in;
    return c.id;
}

// The lowest saving any fix can be justified from: what a candidate must be able to remove to be worth a model's attention.
void lowest_threshold(double& minutes, std::uint64_t& tokens) {
    minutes = 0;
    tokens = 0;
    for (const EfficiencyThreshold& t : efficiency_thresholds()) {
        if (t.minutes > 0 && (minutes == 0 || t.minutes < minutes)) minutes = t.minutes;
        if (t.tokens > 0 && (tokens == 0 || t.tokens < tokens)) tokens = t.tokens;
    }
}

double rank_score(const RetroCandidate& c) { return static_cast<double>(c.potential.tokens) + 5000.0 * c.potential.minutes; }

}  // namespace

Json RetroCandidate::to_json() const {
    Json spanList = Json::array();
    for (const EfficiencySpan& sp : spans) spanList.push_back(sp.to_json());
    Json j = Json::object({{"id", id}, {"pattern", pattern}, {"summary", summary}, {"count", count}, {"spans", spanList},
                           {"measured", measured.to_json()}, {"maxShare", maxShare}, {"potentialSaving", potential.to_json()},
                           {"suggestedFix", suggestedFix}, {"appliesTo", appliesTo}, {"projectOnly", projectOnly}});
    if (!command.empty()) j["command"] = command;
    if (!ref.empty()) j["ref"] = ref;
    if (!code.empty()) j["code"] = code;
    if (!relatedEntry.empty()) j["relatedEntry"] = relatedEntry;
    return j;
}

std::vector<RetroCandidate> find_retro_candidates(const std::vector<EfficiencySession>& sessions, const Json& feedbackEntries,
                                                  bool keepBelowThreshold) {
    Map map;
    for (const EfficiencySession& s : sessions) {
        if (s.steps.empty()) continue;
        detect_failures(s, map);
        detect_rereads(s, map);
        detect_big_results(s, map);
        detect_screenshots(s, map);
        detect_waits(s, map);
        detect_loops(s, map);
        detect_workarounds(s, feedbackEntries, map);
    }
    double minMinutes = 0;
    std::uint64_t minTokens = 0;
    lowest_threshold(minMinutes, minTokens);
    std::vector<RetroCandidate> out;
    for (auto& [id, a] : map) {
        if (a.parts.empty()) continue;
        // The largest spans first (by what they cost), kept to kRetroMaxSpans; then in the order of the transcripts.
        std::sort(a.parts.begin(), a.parts.end(), [](const Part& x, const Part& y) {
            const double wx = static_cast<double>(x.measure.tokens) + 5000.0 * x.measure.minutes;
            const double wy = static_cast<double>(y.measure.tokens) + 5000.0 * y.measure.minutes;
            if (wx != wy) return wx > wy;
            if (x.span.session != y.span.session) return x.span.session < y.span.session;
            return x.span.fromStep < y.span.fromStep;
        });
        if (static_cast<int>(a.parts.size()) > kRetroMaxSpans) a.parts.resize(kRetroMaxSpans);
        double num = 0, den = 0;
        for (const Part& p : a.parts) {
            const double w = static_cast<double>(p.measure.tokens) + 5000.0 * p.measure.minutes + 1.0;
            num += p.share * w;
            den += w;
            a.c.spans.push_back(p.span);
            a.c.measured += p.measure;
        }
        a.c.maxShare = std::clamp(round2(den > 0 ? num / den : 0.0), 0.01, 1.0);
        a.c.potential = scale_measure(a.c.measured, a.c.maxShare);
        if (!keepBelowThreshold && !(a.c.potential.minutes >= minMinutes || a.c.potential.tokens >= minTokens)) continue;  // not worth a fix of any kind
        a.c.summary = summarize(a, static_cast<int>(a.sessions.size()));
        out.push_back(a.c);
    }
    // A loop is the weakest finding: when the steps of another candidate (the failures, the rereads...) already explain it, it is not
    // reported on top of them (the same waste would be filed twice).
    out.erase(std::remove_if(out.begin(), out.end(),
                             [&](const RetroCandidate& c) {
                                 if (c.pattern != "loop") return false;
                                 return std::all_of(c.spans.begin(), c.spans.end(), [&](const EfficiencySpan& sp) {
                                     return std::any_of(out.begin(), out.end(), [&](const RetroCandidate& other) {
                                         return other.pattern != "loop" &&
                                                std::any_of(other.spans.begin(), other.spans.end(), [&](const EfficiencySpan& o) {
                                                    return o.session == sp.session && sp.fromStep <= o.toStep && sp.toStep >= o.fromStep;
                                                });
                                     });
                                 });
                             }),
              out.end());
    std::sort(out.begin(), out.end(), [](const RetroCandidate& x, const RetroCandidate& y) {
        const double sx = rank_score(x), sy = rank_score(y);
        if (sx != sy) return sx > sy;
        return x.id < y.id;
    });
    if (!keepBelowThreshold && static_cast<int>(out.size()) > kRetroMaxCandidates) out.resize(kRetroMaxCandidates);
    return out;
}

bool retrospective_due(const Savers& savers, int steps, double costUsd) {
    if (!savers.retrospective) return false;
    return steps >= savers.retrospectiveSteps || costUsd >= savers.retrospectiveCostUsd;
}

bool retrospective_running_here() { return t_runningHere; }

Json RetrospectiveResult::to_json() const {
    Json cands = Json::array();
    for (const RetroCandidate& c : candidates) cands.push_back(c.to_json());
    Json j = Json::object({{"sessions", sessions}, {"candidates", cands}, {"alreadyFiled", alreadyFiled}, {"filed", filed},
                           {"fixChecks", fixChecks}, {"dropped", dropped}, {"facts", facts}, {"model", model}, {"costUsd", std::round(costUsd * 1e6) / 1e6},
                           {"usage", usage.to_json()}, {"note", note}});
    return j;
}

// ---- the model's turn ------------------------------------------------------------------------------------------------------

namespace {

const char* kSystem =
    "You turn measured waste in the AI sessions that build games with the FactorIA game engine into efficiency feedback for the "
    "engine's developers. The numbers were measured by the engine from the session transcripts: you never change them, and you do not "
    "choose steps. You are given candidates (c1, c2, ...) with what happened, the measured steps, minutes and tokens, the largest "
    "share of them a fix could remove (maxShare), and the cheapest fix type that usually helps.\n"
    "Pick AT MOST THREE candidates that a fix in the ENGINE (not in this game) would really remove, and write each as an entry. The "
    "fix is part of the entry and its cost decides: the cheapest one that removes the waste wins, in this order: doc (a section in an "
    "existing doc, or its title and keywords), guide (an on-demand topic guide), example, commandOption (an option on a command that "
    "exists), newCommand, engineChange. commandOption, newCommand and engineChange need `whyNotCheaper`: why a doc section, a guide "
    "and an example would not have removed the waste. A guide is not free: text loaded on every step costs on every step, so propose "
    "on-demand guides, not lines in the system prompt.\n"
    "Do NOT write an entry for: a different model, effort or limit (those are the user's settings); something true only of this game "
    "(a file of the project read again and again, a name, a layout): that is a project fact, give it in `facts` as one line for the "
    "project's AGENTS.md instead; or a saving you cannot explain in one sentence. Skip a candidate when in doubt.\n"
    "Write in engine terms only: command, component and field names. No names of the game, its levels, characters or files.\n"
    "Answer with ONE JSON object and nothing else:\n"
    "{\"entries\":[{\"candidate\":\"c1\",\"category\":\"<engine area>\",\"title\":\"<short noun phrase>\",\"suggestion\":\"<the fix, one sentence>\","
    "\"waste\":\"<what took the time, in engine terms, one or two sentences>\",\"fixType\":\"doc\",\"appliesTo\":\"every-game|genre|feature\","
    "\"saveShare\":0.5,\"saveWhy\":\"<one line: why the fix removes that share>\",\"whyNotCheaper\":\"\",\"searched\":[],"
    "\"factLine\":\"\"}],\"facts\":[{\"candidate\":\"c2\",\"line\":\"- one line for AGENTS.md\"}]}\n"
    "`saveShare` is the share (0.01 to 1) of the candidate's measured span the fix removes; it can not be above maxShare. Leave "
    "`searched` empty unless the candidate is a doc that exists but was not found: then list the words that did not find it, and make "
    "the fix the doc's title and keywords. `factLine` is only for an entry that turns out to be about this game alone. Empty lists are "
    "fine.";

std::string json_object_in(const std::string& text) {
    const std::size_t a = text.find('{'), b = text.rfind('}');
    if (a == std::string::npos || b == std::string::npos || b < a) return {};
    return text.substr(a, b - a + 1);
}

std::string slug(const std::string& id) {
    std::string out;
    for (char c : id) {
        const unsigned char u = static_cast<unsigned char>(c);
        if (std::isalnum(u) || c == '.' || c == '_' || c == '-') out += c;
        else if (!out.empty() && out.back() != '-') out += '-';
    }
    if (out.size() > 80) out.resize(80);
    return out;
}

std::string prompt_for(const std::vector<RetroCandidate>& list) {
    std::ostringstream o;
    o << "Engine area (category), one of: " << join(feedback_categories(), ", ") << ".\n";
    o << "Fix types and the saving per game that justifies each (the engine refuses an entry under its row):\n"
      << efficiency_threshold_table() << "\n";
    o << "## Candidates\n";
    for (std::size_t i = 0; i < list.size(); ++i) {
        const RetroCandidate& c = list[i];
        o << "c" << (i + 1) << ": " << c.summary << "\n"
          << "  pattern: " << c.pattern << (c.projectOnly ? " (about the project's own files: a project fact)" : "") << "\n"
          << "  measured: " << c.measured.steps << " steps, " << c.measured.toolCalls << " tool calls, " << c.measured.minutes << " minutes, "
          << c.measured.tokens << " tokens" << (c.measured.estimated ? " (estimated from bytes)" : "") << "\n"
          << "  maxShare: " << c.maxShare << " (a fix removes at most " << c.potential.minutes << " minutes, " << c.potential.tokens << " tokens)\n"
          << "  usual fix: " << c.suggestedFix << ", applies to " << c.appliesTo << "\n";
        if (!c.relatedEntry.empty()) o << "  the workaround is recorded in ENGINE_FEEDBACK entry " << c.relatedEntry << "\n";
    }
    return o.str();
}

// An open efficiency entry already holds this evidence.
bool evidence_held(const RetroCandidate& c, const Json& entries) {
    if (!entries.is_array() || c.spans.empty()) return false;
    std::vector<EfficiencySpan> held;
    for (const Json& e : entries) {
        if (!e.is_object() || str(e, "kind") != "efficiency" || str(e, "status", "open") != "open") continue;
        const Json* ev = child(e, "evidence");
        if (!ev || !ev->is_array()) continue;
        for (const Json& sp : *ev)
            held.push_back({str(sp, "session"), static_cast<int>(num(sp, "fromStep")), static_cast<int>(num(sp, "toStep"))});
    }
    return std::all_of(c.spans.begin(), c.spans.end(), [&](const EfficiencySpan& s) {
        return std::any_of(held.begin(), held.end(), [&](const EfficiencySpan& h) {
            return h.session == s.session && s.fromStep <= h.toStep && s.toStep >= h.fromStep;
        });
    });
}

std::int64_t since_ms(const std::string& text, Error& error, bool& bad) {
    bad = false;
    if (text.empty()) return 0;
    auto d = parse_calendar_date(text, "since");
    if (!d.ok()) {
        bad = true;
        error = d.error();
        return 0;
    }
    const CalendarDate& c = d.value();
    return static_cast<std::int64_t>(c.days_since_epoch()) * 86400000LL + (static_cast<std::int64_t>(c.hour) * 3600 + c.minute * 60 + c.second) * 1000LL;
}

}  // namespace

Result<RetrospectiveResult> run_retrospective(const AiConfig& cfg, const RetrospectiveOptions& options, const std::string& projectDir) {
    if (projectDir.empty())
        return make_error("A retrospective needs a project: its transcripts are in <project>/.factoria/ai/sessions.",
                          "Run it from a project folder (--project) or open one in the editor.");
    RetrospectiveGuard guard;
    if (!guard.held())
        return make_error("busy: a retrospective is already running.",
                          "Wait for it: it reads the same transcripts and files into the same ENGINE_FEEDBACK.json.");

    Error sinceError;
    bool badSince = false;
    const std::int64_t sinceUnixMs = since_ms(options.since, sinceError, badSince);
    if (badSince)
        return make_error("since: " + sinceError.message, "Write a UTC date like 2026-11-01, or a date and time like 2026-11-01T09:30.");

    // Which transcripts.
    std::vector<std::string> ids;
    if (!options.sessions.empty()) {
        ids = options.sessions;
    } else {
        std::vector<std::string> all = list_efficiency_sessions(projectDir);
        std::string sinceDay;
        if (sinceUnixMs > 0) {
            std::string iso = iso_utc_ms(sinceUnixMs - 86400000LL);  // the id's own stamp is local time: look one day further back
            sinceDay = iso.substr(0, 4) + iso.substr(5, 2) + iso.substr(8, 2);
        }
        int examined = 0;
        for (auto it = all.rbegin(); it != all.rend() && static_cast<int>(ids.size()) < kRetroMaxSessions && examined < kRetroMaxSessionsExamined; ++it) {
            ++examined;
            if (!options.idPrefix.empty() && !starts_with(*it, options.idPrefix)) continue;
            if (!sinceDay.empty() && it->size() >= 8 && std::isdigit(static_cast<unsigned char>((*it)[0])) && it->substr(0, 8) < sinceDay) continue;
            ids.push_back(*it);
        }
    }

    RetrospectiveResult result;
    std::vector<EfficiencySession> sessions;
    for (const std::string& id : ids) {
        if (is_cancelled(options.cancel)) return make_error("cancelled", "");
        auto loaded = load_efficiency_session(projectDir, id);
        if (!loaded.ok()) {
            if (options.sessions.empty()) continue;  // one transcript too big to read must not stop the others
            return loaded.error();
        }
        EfficiencySession s = std::move(loaded.value());
        if (s.steps.empty()) continue;
        if (sinceUnixMs > 0 && s.startMs > 0 && s.startMs < sinceUnixMs) continue;
        const EfficiencyMeasure all = measure_span(s, 1, static_cast<int>(s.steps.size()));
        Json info = Json::object({{"id", s.id}, {"agent", s.agent}, {"steps", all.steps}, {"minutes", all.minutes}, {"tokens", all.tokens},
                                  {"costUsd", all.costUsd}, {"estimated", all.estimated}});
        if (s.truncated) info["truncated"] = true;
        result.sessions.push_back(std::move(info));
        sessions.push_back(std::move(s));
    }

    const std::string feedbackPath = feedback_file_for_project(projectDir);
    Json entries = Json::array();
    if (auto doc = load_feedback(feedbackPath); doc.ok() && doc.value().is_object() && doc.value().contains("entries") && doc.value()["entries"].is_array())
        entries = doc.value()["entries"];

    // How the fixes of earlier entries did: their pattern in the transcripts since the fix, against what it cost before. The entries that
    // were fixed are closed, so they are in the file or in its archive.
    Json closed = entries;
    if (const std::string archivePath = feedback_archive_path(feedbackPath); archivePath != feedbackPath) {
        if (auto archive = load_feedback(archivePath); archive.ok() && archive.value().is_object() && archive.value().contains("entries") &&
                                                       archive.value()["entries"].is_array())
            for (const Json& e : archive.value()["entries"]) closed.push_back(e);
    }
    const std::vector<FixCheck> checks = check_efficiency_fixes(sessions, closed, options.engineVersion.empty() ? std::string(engine_version()) : options.engineVersion);
    std::map<std::string, std::string> afterFix;  // pattern -> the version whose fix did not remove it
    for (const FixCheck& c : checks) {
        result.fixChecks.push_back(c.to_json());
        if (c.result == "no_change" || c.result == "partial") afterFix[c.pattern] = c.fixedIn;
        if (options.candidatesOnly || c.result == "waiting") continue;
        Json stored = c.to_json();
        for (const char* key : {"entry", "pattern", "fixedIn", "fixedAt"}) stored.erase(key);
        (void)record_fix_check(feedbackPath, c.entry, stored);  // a file that cannot be written only loses the note: the result is returned anyway
    }

    std::vector<RetroCandidate> found = find_retro_candidates(sessions, entries);
    sessions.clear();  // the gate reads the transcripts again, one at a time: nothing big is held while the model works
    sessions.shrink_to_fit();
    if (!options.candidatesOnly) {
        std::vector<RetroCandidate> fresh;
        for (RetroCandidate& c : found) {
            if (evidence_held(c, entries)) ++result.alreadyFiled;
            else fresh.push_back(std::move(c));
        }
        found = std::move(fresh);
    }
    result.candidates = std::move(found);

    if (result.sessions.empty()) {
        result.note = "No transcript to look at: no AI run of this project was recorded" + std::string(options.since.empty() ? "" : " since " + options.since) + ".";
        return result;
    }
    if (result.candidates.empty()) {
        result.note = result.alreadyFiled > 0 ? "Nothing new: what the runs wasted is already in efficiency entries of ENGINE_FEEDBACK.json."
                                              : "Nothing measured reaches the smallest saving that justifies a fix: the runs look efficient.";
        return result;
    }
    if (options.candidatesOnly) {
        result.note = std::to_string(result.candidates.size()) + " candidate(s) found by the mechanical pass; no model was asked and nothing was filed.";
        return result;
    }
    if (is_cancelled(options.cancel)) return make_error("cancelled", "");

    // One short call of the fast role.
    std::vector<RetroCandidate> asked = result.candidates;
    if (static_cast<int>(asked.size()) > kRetroModelCandidates) asked.resize(kRetroModelCandidates);
    TextModelOptions mo;
    mo.role = options.role.empty() ? std::string(kRoleFast) : options.role;
    mo.providerFactory = options.providerFactory;
    mo.runtime = options.runtime;
    mo.onUsage = [&](const Usage& u, double cost) {
        result.usage += u;
        result.costUsd += cost;
        if (options.onUsage) options.onUsage(u, cost);
    };
    TextModelInfo modelInfo;
    auto model = make_text_model(cfg, mo, &modelInfo);
    if (!model.ok()) {
        result.note = std::to_string(result.candidates.size()) + " candidate(s) found, but no model could be asked to write them up: " + model.error().message +
                      (model.error().hint.empty() ? "" : " " + model.error().hint);
        return result;
    }
    result.model = Json::object({{"role", modelInfo.role}, {"provider", modelInfo.provider}, {"model", modelInfo.model}});
    auto answer = (*model)(kSystem, prompt_for(asked));
    if (!answer.ok()) {
        result.note = "The " + modelInfo.role + " model did not answer (" + answer.error().message + "); the candidates are returned and nothing was filed.";
        return result;
    }
    const Json reply = parse(json_object_in(*answer));
    if (!reply.is_object()) {
        result.note = "The " + modelInfo.role + " model did not answer with the JSON object the retrospective needs; nothing was filed.";
        return result;
    }

    auto candidate_of = [&](const std::string& name) -> const RetroCandidate* {
        if (name.size() < 2 || name[0] != 'c') return nullptr;
        const int n = std::atoi(name.c_str() + 1);
        return n >= 1 && n <= static_cast<int>(asked.size()) ? &asked[static_cast<std::size_t>(n - 1)] : nullptr;
    };
    std::set<std::string> used;
    int filedCount = 0, factCount = 0;
    const std::string projectName = feedback_project_name(projectDir);
    auto drop = [&](const std::string& candidate, const std::string& code, const std::string& reason) {
        result.dropped.push_back(Json::object({{"candidate", candidate}, {"code", code}, {"reason", reason}}));
    };
    auto add_fact = [&](const RetroCandidate& c, const std::string& line) {
        if (factCount >= kRetroMaxFacts) { drop(c.id, "over_limit", "more than " + std::to_string(kRetroMaxFacts) + " project facts in one retrospective"); return; }
        if (!cfg.savers.projectFacts) { drop(c.id, "facts_off", "savers.projectFacts is off, so no project fact is proposed"); return; }
        const std::string id = "retro:" + slug(c.id);
        if (!propose_fact(projectDir, id, c.command, line)) { drop(c.id, "failed", "the project's .factoria/ai/savers.json could not be written"); return; }
        ++factCount;
        result.facts.push_back(Json::object({{"candidate", c.id}, {"id", id}, {"line", line}}));
    };

    if (const Json* list = child(reply, "entries"); list && list->is_array()) {
        for (const Json& e : *list) {
            if (!e.is_object()) continue;
            const std::string name = str(e, "candidate");
            const RetroCandidate* c = candidate_of(name);
            if (!c) { drop(name, "unknown_candidate", "the model named a candidate that does not exist"); continue; }
            if (!used.insert(c->id).second) continue;
            if (filedCount >= kRetroMaxEntries) { drop(c->id, "over_limit", "more than " + std::to_string(kRetroMaxEntries) + " entries in one retrospective"); continue; }
            Json spans = Json::array();
            for (const EfficiencySpan& sp : c->spans) spans.push_back(sp.to_json());
            const double share = std::clamp(num(e, "saveShare", c->maxShare), 0.01, c->maxShare);
            Json args = Json::object({{"waste", str(e, "waste")}, {"evidence", spans}, {"fixType", str(e, "fixType")},
                                      {"appliesTo", str(e, "appliesTo")},
                                      {"expectedSaving", Json::object({{"share", round2(share)}, {"why", str(e, "saveWhy")}})}});
            if (!str(e, "whyNotCheaper").empty()) args["whyNotCheaper"] = str(e, "whyNotCheaper");
            if (const Json* s = child(e, "searched"); s && s->is_array()) args["searched"] = *s;
            FeedbackInput base;
            base.category = str(e, "category");
            base.title = str(e, "title");
            base.suggestion = str(e, "suggestion");
            base.reporter = Json::object({{"kind", "ai"}, {"agent", "retrospective"}, {"model", modelInfo.model}});
            // The pattern is kept on the entry, so a later retrospective can compare it after a fix; a pattern an earlier fix did not remove
            // says so (afterFix), and that is what tells the engine developer the fix saved less than expected.
            EfficiencyOrigin origin;
            origin.pattern = c->id;
            if (auto fx = afterFix.find(c->id); fx != afterFix.end()) origin.afterFix = fx->second;
            EfficiencyFiling f = file_efficiency_feedback(projectDir, feedbackPath, base, args, projectName, origin);
            if (f.refusal) {
                const std::string line = str(e, "factLine");
                if (f.refusal->code == "project_fact" && !line.empty()) add_fact(*c, line);
                else drop(c->id, f.refusal->code, f.refusal->message + " " + f.refusal->hint);
                continue;
            }
            if (f.added.alreadyCounted) { drop(c->id, "already_counted", "an entry already counts this evidence"); continue; }
            ++filedCount;
            Json row = Json::object({{"candidate", c->id}, {"id", f.added.id}, {"merged", f.added.merged}, {"alreadyCounted", false},
                                     {"title", base.title}, {"fixType", str(e, "fixType")}, {"saving", f.verdict.saving.to_json()},
                                     {"measured", f.verdict.measured.to_json()}});
            result.filed.push_back(std::move(row));
        }
    }
    if (const Json* list = child(reply, "facts"); list && list->is_array()) {
        for (const Json& f : *list) {
            if (!f.is_object()) continue;
            const RetroCandidate* c = candidate_of(str(f, "candidate"));
            if (!c || str(f, "line").empty()) continue;
            if (!used.insert(c->id).second) continue;
            add_fact(*c, str(f, "line"));
        }
    }
    for (std::size_t i = 0; i < asked.size(); ++i)
        if (!used.count(asked[i].id)) drop(asked[i].id, "not_chosen", "the model did not pick this candidate");

    std::ostringstream note;
    note << result.filed.size() << " efficiency entr" << (result.filed.size() == 1 ? "y" : "ies") << " filed, " << result.facts.size()
         << " project-fact proposal" << (result.facts.size() == 1 ? "" : "s") << ", " << result.dropped.size() << " candidate"
         << (result.dropped.size() == 1 ? "" : "s") << " dropped";
    if (!result.dropped.empty()) {  // the first reasons, so a panel or a terminal shows why without the full `dropped` list
        note << " (";
        for (std::size_t i = 0; i < result.dropped.size() && i < 3; ++i)
            note << (i ? "; " : "") << result.dropped[i].value("candidate", std::string()) << ": " << result.dropped[i].value("code", std::string());
        note << (result.dropped.size() > 3 ? "; ..." : "") << "; the reasons are in `dropped`)";
    }
    note << ".";
    result.note = note.str();
    return result;
}

}  // namespace fa::ai
