// ai.session_timeline: where the time of an AI session went, from the "t" of every line of its transcript.
#include <algorithm>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <map>
#include <sstream>

#include "fa/ai/session.h"
#include "fa/core/date.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

namespace {

struct TimedLine {
    std::int64_t t = 0;
    std::string kind;
    std::string tool;  // tool_end: the tool; tool_results: the tools, comma separated; hook: "<Event> <extension>"
    bool hookFailed = false;
};

bool waits_for_user(const std::string& tool) {
    std::string l = tool;
    std::transform(l.begin(), l.end(), l.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return l.find("askuser") != std::string::npos || l.find("ask_user") != std::string::npos;
}

struct Bucket {
    double seconds = 0;
    int count = 0;
    void add(double s) { seconds += s; ++count; }
    Json to_json() const { return Json::object({{"seconds", std::round(seconds * 10) / 10}, {"count", count}}); }
};

// Where the context of each model call went (the "context" of the assistant lines: system prompt, tool definitions, conversation;
// sizes estimated from the request, see ContextSplit). Totals add the calls up: what the whole run sent, before caching.
Json context_summary(const std::vector<ContextSplit>& steps) {
    Json out = Json::object({{"known", !steps.empty()}});
    if (steps.empty()) {
        out["note"] = "This session has no context sizes: it was recorded by an engine that did not measure them, or by a CLI agent "
                      "(which sends its own tool list).";
        out["steps"] = Json::array();
        return out;
    }
    ContextSplit sum;
    Json list = Json::array();
    int n = 0;
    for (const ContextSplit& c : steps) {
        sum.systemBytes += c.systemBytes;
        sum.catalogBytes += c.catalogBytes;
        sum.toolBytes += c.toolBytes;
        sum.conversationBytes += c.conversationBytes;
        Json step = c.to_json();
        step["step"] = ++n;
        list.push_back(std::move(step));
    }
    out["steps"] = list;
    out["totals"] = Json::object({{"systemTokens", estimate_tokens(sum.systemBytes)},
                                  {"toolTokens", estimate_tokens(sum.toolBytes)},
                                  {"conversationTokens", estimate_tokens(sum.conversationBytes)},
                                  {"totalTokens", estimate_tokens(sum.totalBytes())},
                                  {"toolShare", sum.totalBytes() ? std::round(1000.0 * sum.toolBytes / sum.totalBytes()) / 1000 : 0.0}});
    return out;
}

}  // namespace

Result<std::string> find_session_file(const std::string& projectDir, const std::string& session) {
    const fsys::path dir = fsys::path(projectDir) / ".factoria" / "ai" / "sessions";
    std::error_code ec;
    std::vector<std::pair<fsys::file_time_type, fsys::path>> files;
    for (const auto& e : fsys::directory_iterator(dir, ec)) {
        if (e.is_regular_file(ec) && e.path().extension() == ".jsonl") files.push_back({e.last_write_time(ec), e.path()});
    }
    if (files.empty()) {
        return Error{"No AI session was recorded in " + dir.generic_string(),
                     "Sessions are written there while an agent runs (ai.run or the AI panel); run one first."};
    }
    if (session.empty()) {
        return std::max_element(files.begin(), files.end(), [](auto& a, auto& b) { return a.first < b.first; })->second.generic_string();
    }
    std::string want = fsys::path(session).filename().string();
    if (!ends_with(want, ".jsonl")) want += ".jsonl";
    std::vector<std::string> names;
    for (const auto& f : files) {
        if (f.second.filename().string() == want) return f.second.generic_string();
        names.push_back(f.second.stem().string());
    }
    std::sort(names.begin(), names.end());
    return Error{"No session named '" + session + "' in " + dir.generic_string(),
                 fa::did_you_mean(fsys::path(want).stem().string(), names) + " ai.session_timeline without `session` reads the newest."};
}

Json session_timeline_from_text(const std::string& text, double minGapSeconds) {
    std::vector<TimedLine> lines;
    std::vector<ContextSplit> contexts;
    int total = 0;
    std::istringstream in(text);
    std::string raw;
    while (std::getline(in, raw)) {
        if (raw.empty()) continue;
        Json j = Json::parse(raw, nullptr, false);
        if (!j.is_object()) continue;
        ++total;
        if (str(j, "kind") == "assistant") {
            if (const Json* c = child(j, "context"); c && c->is_object()) contexts.push_back(ContextSplit::from_json(*c));
        }
        std::int64_t t = 0;
        if (!parse_iso_utc_ms(str(j, "t"), t)) continue;
        TimedLine l;
        l.t = t;
        l.kind = str(j, "kind");
        if (l.kind == "tool_end") l.tool = str(j, "tool");
        if (l.kind == "hook") {  // written when the handler finished, so the gap before it is the time the hook took
            l.tool = str(j, "event") + " " + str(j, "extension");
            l.hookFailed = j.value("failed", false);
        }
        if (l.kind == "tool_results") {
            if (const Json* rs = child(j, "results"); rs && rs->is_array()) {
                for (const auto& r : *rs) {
                    const std::string n = str(r, "tool");
                    if (!n.empty() && l.tool.find(n) == std::string::npos) l.tool += (l.tool.empty() ? "" : ", ") + n;
                }
            }
        }
        lines.push_back(std::move(l));
    }
    Json out = Json::object({{"events", total}, {"timedEvents", lines.size()}, {"minGapSeconds", minGapSeconds}});
    out["context"] = context_summary(contexts);
    if (lines.size() < 2) {
        out["hasTimes"] = false;
        out["note"] = lines.empty() ? "This session has no times: it was recorded before every event carried \"t\", so no timeline can be made."
                                    : "This session has only one timed event, so there is nothing to measure.";
        out["gaps"] = Json::array();
        out["totals"] = Json::object();
        return out;
    }
    out["hasTimes"] = true;
    out["startedAt"] = iso_utc_ms(lines.front().t);
    out["endedAt"] = iso_utc_ms(lines.back().t);
    out["totalSeconds"] = std::round((lines.back().t - lines.front().t) / 100.0) / 10;

    Bucket tool, thinking, model, user, hook;
    int hooksFailed = 0;
    std::map<std::string, Bucket> byTool, byHook;
    Json gaps = Json::array();
    for (std::size_t i = 1; i < lines.size(); ++i) {
        const TimedLine& e = lines[i];
        const double seconds = std::max<std::int64_t>(0, e.t - lines[i - 1].t) / 1000.0;
        std::string activity = "model", detail = "waiting for the model";
        if (e.kind == "tool_end" || e.kind == "tool_results") {
            if (waits_for_user(e.tool)) {
                activity = "user";
                detail = "waiting for the user (" + e.tool + ")";
                user.add(seconds);
            } else {
                activity = "tool";
                detail = e.tool.empty() ? "a tool was running" : "tool " + e.tool + " was running";
                tool.add(seconds);
                byTool[e.tool.empty() ? "(unknown)" : e.tool].add(seconds);
            }
        } else if (e.kind == "hook") {
            activity = "hook";
            detail = "hook " + e.tool + (e.hookFailed ? " (failed)" : "") + " was running";
            hook.add(seconds);
            byHook[e.tool].add(seconds);
            if (e.hookFailed) ++hooksFailed;
        } else if (e.kind == "thinking") {
            activity = "thinking";
            detail = "the model was thinking";
            thinking.add(seconds);
        } else if (e.kind == "user" && lines[i - 1].kind != "start") {  // the first one is the task itself
            activity = "user";
            detail = "waiting for the user";
            user.add(seconds);
        } else {
            model.add(seconds);
        }
        if (seconds >= minGapSeconds) {
            gaps.push_back(Json::object({{"start", iso_utc_ms(lines[i - 1].t)}, {"end", iso_utc_ms(e.t)},
                                         {"seconds", std::round(seconds * 10) / 10}, {"activity", activity}, {"detail", detail},
                                         {"endedBy", e.kind}}));
        }
    }
    Json byToolJson = Json::array();
    std::vector<std::pair<std::string, Bucket>> sorted(byTool.begin(), byTool.end());
    std::sort(sorted.begin(), sorted.end(), [](auto& a, auto& b) { return a.second.seconds > b.second.seconds; });
    for (const auto& [name, b] : sorted) {
        Json j = b.to_json();
        j["tool"] = name;
        byToolJson.push_back(std::move(j));
    }
    Json toolJson = tool.to_json();
    toolJson["byTool"] = byToolJson;
    Json hookJson = hook.to_json();
    hookJson["failed"] = hooksFailed;
    Json byHookJson = Json::array();
    std::vector<std::pair<std::string, Bucket>> hooksSorted(byHook.begin(), byHook.end());
    std::sort(hooksSorted.begin(), hooksSorted.end(), [](auto& a, auto& b) { return a.second.seconds > b.second.seconds; });
    for (const auto& [name, b] : hooksSorted) {
        Json j = b.to_json();
        j["hook"] = name;
        byHookJson.push_back(std::move(j));
    }
    hookJson["byHook"] = byHookJson;
    out["gaps"] = gaps;
    out["totals"] = Json::object({{"tool", toolJson}, {"thinking", thinking.to_json()}, {"model", model.to_json()}, {"user", user.to_json()},
                                  {"hook", hookJson}});
    return out;
}

Result<Json> session_timeline(const std::string& projectDir, const std::string& session, double minGapSeconds) {
    auto path = find_session_file(projectDir, session);
    if (!path) return path.error();
    std::ifstream f(*path, std::ios::binary);
    if (!f) return Error{"Cannot read " + *path, "Check the file exists and is readable."};
    std::stringstream ss;
    ss << f.rdbuf();
    Json out = session_timeline_from_text(ss.str(), minGapSeconds);
    out["session"] = *path;
    return out;
}

}  // namespace fa::ai
