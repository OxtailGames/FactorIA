// Hooks for every provider: events, matching, running the handlers and reading what they answer (hooks.h, docs/HOOKS.md).
#include "fa/ai/hooks.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <deque>
#include <mutex>
#include <regex>
#include <set>

#include "fa/core/strings.h"
#include "fa/ai/hook_js.h"
#include "util.h"

namespace fa::ai {

using util::child;

namespace {

constexpr std::size_t kMaxOutput = 4000;  // of stdout and of stderr kept in a record

struct EventInfo {
    HookEvent event;
    const char* name;
};
constexpr EventInfo kEvents[] = {
    {HookEvent::SessionStart, "SessionStart"},
    {HookEvent::UserPromptSubmit, "UserPromptSubmit"},
    {HookEvent::PreToolUse, "PreToolUse"},
    {HookEvent::PostToolUse, "PostToolUse"},
    {HookEvent::PostToolUseFailure, "PostToolUseFailure"},
    {HookEvent::Stop, "Stop"},
    {HookEvent::SessionEnd, "SessionEnd"},
    {HookEvent::BeforeCommand, "beforeCommand"},
    {HookEvent::AfterCommand, "afterCommand"},
};

std::string clip(std::string s, std::size_t max = kMaxOutput) {
    if (s.size() <= max) return s;
    std::size_t cut = max;
    while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80) --cut;  // not inside a UTF-8 character
    return s.substr(0, cut) + "... (" + std::to_string(s.size() - cut) + " more bytes)";
}

std::string trim(std::string s) {
    while (!s.empty() && std::isspace(static_cast<unsigned char>(s.back()))) s.pop_back();
    std::size_t i = 0;
    while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
    return s.substr(i);
}

std::vector<std::string> split_names(std::string_view matcher) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : matcher) {
        if (c == '|' || c == ',') {
            if (!trim(cur).empty()) out.push_back(trim(cur));
            cur.clear();
        } else {
            cur += c;
        }
    }
    if (!trim(cur).empty()) out.push_back(trim(cur));
    return out;
}

// Letters, digits, _ - space , | (and . * for command names): the list form of a matcher.
bool is_name_list(std::string_view m, bool commandNames) {
    for (char c : m) {
        const bool ok = std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-' || c == ' ' || c == ',' || c == '|' ||
                        (commandNames && (c == '.' || c == '*'));
        if (!ok) return false;
    }
    return true;
}

bool glob_match(std::string_view pattern, std::string_view text) {
    std::size_t p = 0, t = 0, star = std::string_view::npos, mark = 0;
    while (t < text.size()) {
        if (p < pattern.size() && pattern[p] == '*') {
            star = p++;
            mark = t;
        } else if (p < pattern.size() && pattern[p] == text[t]) {
            ++p;
            ++t;
        } else if (star != std::string_view::npos) {
            p = star + 1;
            t = ++mark;
        } else {
            return false;
        }
    }
    while (p < pattern.size() && pattern[p] == '*') ++p;
    return p == pattern.size();
}

std::string quote_arg(const std::string& s) {
    bool plain = !s.empty();
    for (char c : s)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-' || c == '.' || c == '/' || c == ':' || c == '\\')) plain = false;
    if (plain) return s;
#ifdef _WIN32
    std::string out = "\"";
    for (char c : s) out += c == '"' ? std::string("\\\"") : std::string(1, c);
    return out + "\"";
#else
    std::string out = "'";
    for (char c : s) out += c == '\'' ? std::string("'\\''") : std::string(1, c);
    return out + "'";
#endif
}

std::int64_t now_ms() {
    return std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
}

}  // namespace

const char* hook_event_name(HookEvent e) {
    for (const auto& i : kEvents)
        if (i.event == e) return i.name;
    return "?";
}

std::optional<HookEvent> parse_hook_event(std::string_view s) {
    for (const auto& i : kEvents)
        if (s == i.name) return i.event;
    return std::nullopt;
}

std::vector<std::string> engine_hook_event_names() {
    std::vector<std::string> out;
    for (const auto& i : kEvents) out.push_back(i.name);
    return out;
}

bool is_command_hook_event(HookEvent e) { return e == HookEvent::BeforeCommand || e == HookEvent::AfterCommand; }

bool hook_event_has_matcher(HookEvent e) { return e != HookEvent::UserPromptSubmit && e != HookEvent::Stop; }

bool hook_event_can_block(HookEvent e) {
    return e == HookEvent::PreToolUse || e == HookEvent::UserPromptSubmit || e == HookEvent::Stop || e == HookEvent::BeforeCommand;
}

std::string hook_matcher_problem(std::string_view matcher) {
    if (matcher.empty() || matcher == "*") return {};
    if (is_name_list(matcher, true)) return {};
    try {
        std::regex re{std::string(matcher)};
    } catch (const std::regex_error& e) {
        return "'" + std::string(matcher) + "' is not a valid regular expression (" + e.what() +
               "). Use tool or command names separated by | (\"Edit|Write\", \"scene.*|assets.generate_*\"), or a regular expression such as \"mcp__.*\".";
    }
    return {};
}

bool hook_matches(HookEvent event, std::string_view matcher, std::string_view value) {
    if (matcher.empty() || matcher == "*" || !hook_event_has_matcher(event)) return true;
    const bool commandNames = is_command_hook_event(event);
    if (is_name_list(matcher, commandNames)) {
        for (const std::string& name : split_names(matcher)) {
            if (commandNames ? glob_match(name, value) : name == value) return true;
        }
        return false;
    }
    try {
        return std::regex_search(std::string(value), std::regex{std::string(matcher)});
    } catch (const std::regex_error&) {
        return false;
    }
}

std::string hook_module_problem(std::string_view module) {
    const std::string m(module);
    if (m.empty()) return "a hook of type \"js\" needs its \"module\", a file of the hooks/ folder such as hooks/guard.js";
    if (m.find('\\') != std::string::npos || m.find(':') != std::string::npos || m[0] == '/' || m[0] == '~')
        return "module '" + m + "' must be a path inside the project written with / and relative to it, such as hooks/guard.js";
    if (m.rfind(std::string(kProjectHooksFolder) + "/", 0) != 0)
        return "module '" + m + "' is not in the hooks/ folder of the project. Move it there and write \"module\": \"hooks/" +
               (m.rfind('/') == std::string::npos ? m : m.substr(m.rfind('/') + 1)) + "\"";
    std::size_t pos = 0;
    while (pos <= m.size()) {
        const std::size_t slash = m.find('/', pos);
        const std::string part = m.substr(pos, slash == std::string::npos ? std::string::npos : slash - pos);
        if (part == ".." || part == "." || (part.empty() && slash != std::string::npos))
            return "module '" + m + "' leaves the hooks/ folder or has an empty path part; write a plain path such as hooks/guard.js";
        if (slash == std::string::npos) break;
        pos = slash + 1;
    }
    if (m.size() < 4 || m.substr(m.size() - 3) != ".js") return "module '" + m + "' is not a .js file; a JavaScript hook is a module such as hooks/guard.js";
    return {};
}

std::string HookHandler::label() const {
    return clip(extension + ": " + (type == "js" ? module : command), 100);
}

bool HookSet::has_event(HookEvent e) const {
    return std::any_of(groups.begin(), groups.end(), [&](const HookGroup& g) { return g.event == e; });
}

std::vector<const HookGroup*> HookSet::matching(HookEvent event, std::string_view value) const {
    std::vector<const HookGroup*> out;
    for (const HookGroup& g : groups)
        if (g.event == event && hook_matches(event, g.matcher, value)) out.push_back(&g);
    return out;
}

HookSet HookSet::only(const std::function<bool(HookEvent)>& keep) const {
    HookSet out;
    out.notRun = notRun;
    for (const HookGroup& g : groups)
        if (keep(g.event)) out.groups.push_back(g);
    return out;
}

HookSet make_hook_set(const std::vector<HookSource>& sources) {
    HookSet set;
    std::set<std::string> noted;
    for (const HookSource& src : sources) {
        if (!src.hooks.is_object()) continue;
        for (auto it = src.hooks.begin(); it != src.hooks.end(); ++it) {
            const auto event = parse_hook_event(it.key());
            if (!event || !it.value().is_array()) continue;
            for (const Json& group : it.value()) {
                HookGroup g;
                g.event = *event;
                g.matcher = util::str(group, "matcher", util::str(group, "match"));
                const Json* handlers = child(group, "hooks");
                if (!handlers || !handlers->is_array()) continue;
                for (const Json& h : *handlers) {
                    HookHandler handler;
                    handler.type = util::str(h, "type");
                    handler.command = util::str(h, "command");
                    handler.module = util::str(h, "module");
                    handler.timeoutSeconds = util::num(h, "timeout", 0);
                    handler.extension = src.extension;
                    handler.source = src.source;
                    if (handler.runs_here()) {
                        g.handlers.push_back(std::move(handler));
                    } else {
                        const std::string note = src.extension + ": the " + it.key() + " hook of type " + handler.type + " runs only in Claude Code";
                        if (noted.insert(note).second) set.notRun.push_back(note);
                    }
                }
                if (!g.handlers.empty()) set.groups.push_back(std::move(g));
            }
        }
    }
    return set;
}

Json hooks_for_claude_code(const Json& hooks, const std::string& factoriaCommand, const std::string& projectDir) {
    Json out = Json::object();
    if (!hooks.is_object()) return out;
    for (auto it = hooks.begin(); it != hooks.end(); ++it) {
        const auto engineEvent = parse_hook_event(it.key());
        if (engineEvent && is_command_hook_event(*engineEvent)) continue;  // engine events: Claude Code does not know them
        if (!it.value().is_array()) continue;
        Json groups = Json::array();
        for (const Json& group : it.value()) {
            Json g = group;
            if (g.is_object() && g.contains("match")) {
                if (!g.contains("matcher")) g["matcher"] = g["match"];
                g.erase("match");
            }
            if (g.is_object() && g.contains("hooks") && g["hooks"].is_array()) {
                for (Json& h : g["hooks"]) {
                    if (util::str(h, "type") != "js") continue;
                    Json command = Json::object();
                    command["type"] = "command";
                    command["command"] = quote_arg(factoriaCommand) + " hooks run " + quote_arg(util::str(h, "module")) + " --project " + quote_arg(projectDir);
                    if (h.contains("timeout")) command["timeout"] = h["timeout"];
                    h = command;
                }
            }
            groups.push_back(std::move(g));
        }
        out[it.key()] = std::move(groups);
    }
    return out;
}

Json HookRunRecord::to_json() const {
    Json j = Json::object();
    j["event"] = hook_event_name(event);
    if (!matched.empty()) j["matched"] = matched;
    j["extension"] = extension;
    j["source"] = source;
    j["type"] = type;
    j["target"] = target;
    j["startedMs"] = startedMs;
    j["ms"] = std::round(ms * 10) / 10;
    if (type == "command") j["exitCode"] = exitCode;
    if (timedOut) j["timedOut"] = true;
    j["failed"] = failed;
    if (!error.empty()) j["error"] = error;
    if (!decision.empty()) j["decision"] = decision;
    if (!reason.empty()) j["reason"] = reason;
    if (!output.empty()) j["output"] = output;
    if (!stderrText.empty()) j["stderr"] = stderrText;
    return j;
}

bool HookOutcome::anyFailed() const {
    return std::any_of(runs.begin(), runs.end(), [](const HookRunRecord& r) { return r.failed; });
}

std::string HookOutcome::failures() const {
    std::string out;
    for (const HookRunRecord& r : runs) {
        if (!r.failed) continue;
        out += (out.empty() ? "" : "\n") + r.extension + ": " + r.target + ": " + r.error;
    }
    return out;
}

Json hook_outcome_json(const HookOutcome& o) {
    Json j = Json::object({{"blocked", o.blocked}, {"stop", o.stop}, {"allowed", o.allowed}, {"failed", o.anyFailed()}});
    if (!o.reason.empty()) j["reason"] = o.reason;
    if (!o.blockedBy.empty()) j["blockedBy"] = o.blockedBy;
    if (!o.stopReason.empty()) j["stopReason"] = o.stopReason;
    j["context"] = o.context;
    j["feedback"] = o.feedback;
    j["systemMessages"] = o.systemMessages;
    if (o.updatedInput) j["updatedInput"] = *o.updatedInput;
    if (o.updatedToolOutput) j["updatedToolOutput"] = *o.updatedToolOutput;
    Json runs = Json::array();
    for (const HookRunRecord& r : o.runs) runs.push_back(r.to_json());
    j["runs"] = std::move(runs);
    return j;
}

namespace {
std::mutex gRunsMutex;
std::deque<HookRunRecord> gRuns;
constexpr std::size_t kRecentRuns = 300;
}  // namespace

void note_hook_run(const HookRunRecord& rec) {
    std::lock_guard<std::mutex> lock(gRunsMutex);
    gRuns.push_back(rec);
    while (gRuns.size() > kRecentRuns) gRuns.pop_front();
}

std::vector<HookRunRecord> recent_hook_runs(std::size_t max) {
    std::lock_guard<std::mutex> lock(gRunsMutex);
    const std::size_t n = std::min(max, gRuns.size());
    return std::vector<HookRunRecord>(gRuns.end() - static_cast<std::ptrdiff_t>(n), gRuns.end());
}

void clear_recent_hook_runs() {
    std::lock_guard<std::mutex> lock(gRunsMutex);
    gRuns.clear();
}

Json hook_common_input(HookEvent event, const HookRunContext& ctx) {
    Json j = Json::object();
    j["session_id"] = ctx.sessionId;
    j["transcript_path"] = ctx.transcriptPath;
    j["cwd"] = ctx.projectDir;
    j["permission_mode"] = ctx.permissionMode;
    j["hook_event_name"] = hook_event_name(event);
    if (!ctx.agentType.empty()) j["agent_type"] = ctx.agentType;
    return j;
}

namespace {

void join_into(std::string& dst, const std::string& more) {
    if (more.empty()) return;
    dst += (dst.empty() ? "" : "\n") + more;
}

}  // namespace

void apply_hook_answer(HookEvent event, const Json& answer, const std::string& label, HookOutcome& out, HookRunRecord& rec) {
    if (!answer.is_object()) return;
    auto block = [&](const std::string& reason) {
        out.blocked = true;
        if (out.blockedBy.empty()) out.blockedBy = label;
        join_into(out.reason, reason);
        rec.decision = "block";
        join_into(rec.reason, reason);
    };
    if (const Json* c = child(answer, "continue"); c && c->is_boolean() && !c->get<bool>()) {
        out.stop = true;
        const std::string why = util::str(answer, "stopReason");
        join_into(out.stopReason, why);
        rec.decision = "stop";
        join_into(rec.reason, why);
    }
    if (const std::string msg = util::str(answer, "systemMessage"); !msg.empty()) out.systemMessages.push_back(msg);

    const std::string decision = util::str(answer, "decision");
    const std::string reason = util::str(answer, "reason");
    if (decision == "block") {
        switch (event) {
            case HookEvent::PostToolUse:
            case HookEvent::PostToolUseFailure:
                out.feedback.push_back(reason.empty() ? "A hook flagged this result." : reason);  // the tool already ran
                rec.decision = "block";
                join_into(rec.reason, reason);
                break;
            case HookEvent::SessionStart:
            case HookEvent::SessionEnd:
            case HookEvent::AfterCommand:
                break;  // nothing left to refuse
            default:
                block(reason);
                break;
        }
    } else if (decision == "approve" && event == HookEvent::PreToolUse) {
        out.allowed = true;  // Claude Code's older form of permissionDecision "allow"
        if (rec.decision.empty()) rec.decision = "allow";
    }

    const Json* specific = child(answer, "hookSpecificOutput");
    if (specific && specific->is_object()) {
        if (const std::string ctx = util::str(*specific, "additionalContext"); !ctx.empty()) {
            out.context.push_back(ctx);
            if (rec.decision.empty()) rec.decision = "context";
        }
        const std::string pd = util::str(*specific, "permissionDecision");
        if (event == HookEvent::PreToolUse && !pd.empty()) {
            const std::string pr = util::str(*specific, "permissionDecisionReason");
            if (pd == "deny") {
                block(pr);
            } else if (pd == "allow") {
                out.allowed = true;
                if (rec.decision.empty()) rec.decision = "allow";
                if (rec.reason.empty()) rec.reason = pr;
            } else if (pd == "ask" || pd == "defer") {
                // FactorIA's loop has nobody to ask: the call goes ahead as if the hook had said nothing.
                if (rec.decision.empty()) rec.decision = pd;
                join_into(rec.reason, pr);
            }
        }
        if (event == HookEvent::PreToolUse) {
            if (const Json* in = child(*specific, "updatedInput"); in && in->is_object()) out.updatedInput = *in;
        }
        if (event == HookEvent::PostToolUse || event == HookEvent::PostToolUseFailure) {
            if (const Json* o = child(*specific, "updatedMCPToolOutput")) out.updatedToolOutput = *o;
        }
    }
}

namespace {

void note_start(HookRunRecord& rec, const HookEvent event, const std::string& matched, const HookHandler& h) {
    rec.event = event;
    rec.matched = matched;
    rec.extension = h.extension;
    rec.source = h.source;
    rec.type = h.type;
    rec.target = h.type == "js" ? h.module : h.command;
    rec.startedMs = now_ms();
}

std::string first_line(const std::string& s) {
    const std::string t = trim(s);
    const std::size_t eol = t.find('\n');
    return clip(eol == std::string::npos ? t : t.substr(0, eol), 300);
}

// What a program printed on stdout when it exited 0: JSON (the decisions) or plain text (context for two events).
void read_stdout(HookEvent event, const std::string& text, const std::string& label, HookOutcome& out, HookRunRecord& rec) {
    const std::string body = trim(text);
    if (body.empty()) return;
    if (body[0] == '{') {
        Json answer = util::parse(body);
        if (answer.is_object()) {
            apply_hook_answer(event, answer, label, out, rec);
            return;
        }
        rec.failed = true;
        rec.error = "printed text that starts with { but is not valid JSON. Print one JSON object such as {\"decision\": \"block\", \"reason\": \"...\"}, or plain text with no leading {.";
        return;
    }
    if (event == HookEvent::SessionStart || event == HookEvent::UserPromptSubmit) {
        out.context.push_back(body);
        rec.decision = "context";
    }
}

void run_command_handler(const HookHandler& h, HookEvent event, const std::string& stdinText, double timeout, const HookRunContext& ctx,
                         HookOutcome& out, HookRunRecord& rec) {
    ProcessOptions po;
#ifdef _WIN32
    po.argv = {"cmd.exe", "/C", h.command};
#else
    po.argv = {"/bin/sh", "-c", h.command};
#endif
    po.workingDir = ctx.projectDir;
    po.env["CLAUDE_PROJECT_DIR"] = ctx.projectDir;
    po.env["FACTORIA_PROJECT_DIR"] = ctx.projectDir;
    po.env["FACTORIA_HOOK_EVENT"] = hook_event_name(event);
    po.env["FACTORIA_IN_HOOK"] = "1";  // a factoria this hook starts runs no hooks of its own: no loop
    po.stdinText = stdinText;
    po.cancel = ctx.cancel;
    po.timeoutSeconds = timeout;
    po.endWithChild = true;
    const auto t0 = std::chrono::steady_clock::now();
    auto r = run_process(po);
    rec.ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    if (!r) {
        rec.failed = true;
        rec.error = "could not start: " + r.error().message + (r.error().hint.empty() ? "" : " " + r.error().hint) +
                    " Check the command and that the program exists and can be run from the project folder.";
        return;
    }
    rec.exitCode = r->exitCode;
    rec.timedOut = r->timedOut;
    rec.output = clip(r->stdoutText);
    rec.stderrText = clip(r->stderrText);
    if (r->cancelled) return;  // the run was stopped: not the hook's fault
    if (r->timedOut) {
        rec.failed = true;
        rec.error = "took longer than " + std::to_string(int(timeout)) + " s and was stopped. Make it faster, or give it a longer \"timeout\" (seconds) in its hook.";
        return;
    }
    const std::string label = h.label();
    if (r->exitCode == 0) {
        read_stdout(event, r->stdoutText, label, out, rec);
        return;
    }
    if (r->exitCode == 2) {
        const std::string why = trim(r->stderrText).empty() ? "the hook exited with code 2 and said nothing on stderr" : trim(r->stderrText);
        if (hook_event_can_block(event)) {
            out.blocked = true;
            if (out.blockedBy.empty()) out.blockedBy = label;
            join_into(out.reason, why);
            rec.decision = "block";
            rec.reason = clip(why, 1000);
        } else if (event == HookEvent::PostToolUse || event == HookEvent::PostToolUseFailure) {
            out.feedback.push_back(why);
            rec.decision = "block";
            rec.reason = clip(why, 1000);
        } else {
            out.systemMessages.push_back(label + ": " + why);  // this event cannot refuse anything: the user sees stderr
        }
        return;
    }
    rec.failed = true;
    rec.error = "exited with code " + std::to_string(r->exitCode) +
                (trim(r->stderrText).empty() ? std::string() : ": " + first_line(r->stderrText)) +
                ". Exit 0 lets the action go on and prints JSON decisions; exit 2 blocks it with stderr as the reason; any other code is a failure of the hook, "
                "reported and ignored.";
}

void run_js_handler(const HookHandler& h, HookEvent event, const Json& input, double timeout, const HookRunContext& ctx, HookOutcome& out,
                    HookRunRecord& rec) {
    const auto t0 = std::chrono::steady_clock::now();
    JsHookResult r = run_js_hook(ctx.projectDir, h.module, event, input, timeout);
    rec.ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
    for (const std::string& line : r.logs) rec.stderrText += (rec.stderrText.empty() ? "" : "\n") + line;
    rec.stderrText = clip(rec.stderrText);
    rec.timedOut = r.timedOut;
    if (!r.ok) {
        rec.failed = true;
        rec.error = r.error;
        return;
    }
    if (r.value.is_null()) return;
    rec.output = clip(r.value.is_string() ? r.value.get<std::string>() : util::dump(r.value));
    const std::string label = h.label();
    if (r.value.is_object()) {
        apply_hook_answer(event, r.value, label, out, rec);
    } else if (r.value.is_string()) {
        if (event == HookEvent::SessionStart || event == HookEvent::UserPromptSubmit) {
            out.context.push_back(r.value.get<std::string>());
            rec.decision = "context";
        }
    } else {
        rec.failed = true;
        rec.error = "returned " + std::string(r.value.type_name()) + ". Return an object such as {decision: \"block\", reason: \"...\"}, a string (context for SessionStart and UserPromptSubmit) or nothing.";
    }
}

}  // namespace

HookOutcome run_hooks(const HookSet& set, HookEvent event, std::string_view matchValue, const Json& input, const HookRunContext& ctx) {
    HookOutcome out;
    const auto groups = set.matching(event, matchValue);
    if (groups.empty()) return out;
    Json full = hook_common_input(event, ctx);
    if (input.is_object())
        for (auto it = input.begin(); it != input.end(); ++it) full[it.key()] = it.value();
    const std::string stdinText = util::dump(full);
    std::set<std::string> done;  // the same handler listed twice runs once, as Claude Code does
    for (const HookGroup* g : groups) {
        for (const HookHandler& h : g->handlers) {
            if (is_cancelled(ctx.cancel)) return out;
            if (!done.insert(h.type + "\n" + h.command + "\n" + h.module).second) continue;
            HookRunRecord rec;
            note_start(rec, event, std::string(matchValue), h);
            const double timeout = h.timeoutSeconds > 0 ? std::min(h.timeoutSeconds, kMaxHookTimeoutSeconds)
                                   : ctx.defaultTimeoutSeconds > 0 ? ctx.defaultTimeoutSeconds
                                                                   : kDefaultHookTimeoutSeconds;
            if (h.type == "js") {
                run_js_handler(h, event, full, timeout, ctx, out, rec);
            } else {
                run_command_handler(h, event, stdinText, timeout, ctx, out, rec);
            }
            if (rec.failed) rec.decision.clear();
            out.runs.push_back(rec);
            note_hook_run(rec);
            if (ctx.onRun) ctx.onRun(rec);
            if (out.blocked || out.stop) return out;  // what comes after the refusal is not asked
        }
    }
    return out;
}

}  // namespace fa::ai
