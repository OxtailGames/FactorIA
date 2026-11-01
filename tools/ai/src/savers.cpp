#include "fa/ai/savers.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <mutex>
#include <sstream>

#include "fa/ai/session.h"
#include "fa/ai/tool_catalog.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

namespace {

std::mutex g_storeMutex;  // runs of one process share the file; two processes at once lose at most one run's counts

std::string one_line(std::string s, std::size_t max) {
    for (char& c : s)
        if (c == '\n' || c == '\r' || c == '\t') c = ' ';
    std::string out;
    for (char c : s) {
        if (c == ' ' && !out.empty() && out.back() == ' ') continue;
        out += c;
    }
    while (!out.empty() && out.back() == ' ') out.pop_back();
    if (out.size() > max) {
        out.resize(max);
        while (!out.empty() && (static_cast<unsigned char>(out.back()) & 0xC0) == 0x80) out.pop_back();  // not in the middle of a UTF-8 character
        if (!out.empty() && (static_cast<unsigned char>(out.back()) & 0x80)) out.pop_back();
        out += "...";
    }
    return out;
}

fsys::path store_path(std::string_view projectDir) { return fsys::path(std::string(projectDir)) / kSaversFile; }

Json fresh_store() { return Json::object({{"version", 1}, {"runs", Json::object()}, {"groups", Json::object()}, {"facts", Json::object()}}); }

Json load_store(std::string_view projectDir) {
    Json j = fresh_store();
    if (projectDir.empty()) return j;
    std::ifstream in(store_path(projectDir), std::ios::binary);
    if (!in) return j;
    std::stringstream ss;
    ss << in.rdbuf();
    Json parsed = parse(ss.str());
    if (!parsed.is_object()) return j;
    for (const char* key : {"runs", "groups", "facts"}) {
        if (const Json* v = child(parsed, key); v && v->is_object()) j[key] = *v;
    }
    return j;
}

Result<void> save_store(std::string_view projectDir, const Json& j) { return fs::write_text(store_path(projectDir).string(), dump_pretty(j) + "\n"); }

std::string fact_id(const std::string& command, const std::string& code) { return command + ":" + code; }

// The one line for AGENTS.md.
std::string fact_line(const std::string& command, const std::string& code, const std::string& message, const std::string& hint,
                      const std::string& fixArgs) {
    std::string line = "- `" + command + "` fails with `" + code + "`";
    if (!message.empty()) line += " (\"" + one_line(message, 110) + "\")";
    if (!fixArgs.empty()) line += "; a call that worked used `" + one_line(fixArgs, 100) + "`";
    if (!hint.empty()) line += ". " + one_line(hint, 120);
    else line += ".";
    return line;
}

bool group_loaded_up_front(const AiConfig& cfg, const std::string& role, const std::string& group) {
    const RoleConfig rc = cfg.role(role);
    const std::vector<std::string> groups = rc.toolGroups ? *rc.toolGroups : default_tool_groups(role);
    return std::ranges::any_of(groups, [&](const std::string& g) { return g == group || g == "all"; });
}

u64 group_bytes(const CommandRegistry& registry, const std::string& group) {
    u64 bytes = 0;
    for (const CommandInfo* info : registry.list()) {
        if (info->category != group || is_agent_tool_excluded(info->name)) continue;
        const ToolDef def = tool_def_for_command(*info);
        bytes += def.name.size() + def.description.size() + dump(def.inputSchema).size();
    }
    return bytes;
}

}  // namespace

// --- loop guard ------------------------------------------------------------------------------------------------------------

std::optional<LoopRedirect> LoopGuard::record(const std::string& command, bool ok, const std::string& code, const std::string& message,
                                              const std::string& hint) {
    if (ok) {
        for (auto it = entries_.begin(); it != entries_.end();) {
            if (it->first.compare(0, command.size() + 1, command + "\n") == 0) it = entries_.erase(it);
            else ++it;
        }
        return std::nullopt;
    }
    Entry& e = entries_[command + "\n" + code];
    ++e.failures;
    if (e.redirected || e.failures < kLoopGuardFailures) return std::nullopt;
    e.redirected = true;
    LoopRedirect r;
    r.command = command;
    r.code = code;
    r.message = message;
    r.hint = hint;
    r.count = e.failures;
    r.text = loop_redirect_text(r);
    return r;
}

std::string loop_redirect_text(const LoopRedirect& r) {
    std::string text = "[Loop guard] `" + r.command + "` has now failed " + std::to_string(r.count) + " times with the same error (" +
                       (r.code.empty() ? std::string("no code") : r.code) + ")";
    if (!r.message.empty()) text += ": " + one_line(r.message, 200);
    else text += ".";
    if (!text.empty() && text.back() != '.') text += ".";
    if (!r.hint.empty()) text += " Hint: " + one_line(r.hint, 240);
    if (!text.empty() && text.back() != '.') text += ".";
    text += " Repeating the same call will not work. Try a different way (other arguments, another command, or read the docs), or tell the user what blocks you.";
    return text;
}

std::string loop_judge_prompt(const LoopRedirect& r, const std::string& lastArguments) {
    std::string p = "An AI agent that builds a game with the FactorIA engine is stuck in a loop: the command `" + r.command + "` failed " +
                    std::to_string(r.count) + " times with the same error code.\n\nError code: " + r.code + "\nMessage: " + one_line(r.message, 400) +
                    "\nHint from the engine: " + one_line(r.hint, 400) + "\nLast arguments: " + one_line(lastArguments, 400) +
                    "\n\nWrite the message to hand to the agent: at most three sentences, plain text. Say what is wrong and what to try instead "
                    "(a different approach, not the same call again). Do not apologise and do not repeat the error text.";
    return p;
}

std::string loop_judge_redirect(const LoopRedirect& r, const std::string& answer) {
    const std::string body = one_line(answer, 600);
    if (body.empty()) return {};
    return "[Loop guard] `" + r.command + "` failed " + std::to_string(r.count) + " times with " + (r.code.empty() ? std::string("the same error") : r.code) +
           ". " + body;
}

// --- RunLearner ------------------------------------------------------------------------------------------------------------

RunLearner::RunLearner(std::string projectDir, std::string role, bool groups, bool facts)
    : projectDir_(std::move(projectDir)), role_(std::move(role)), groups_(groups), facts_(facts) {}

void RunLearner::tool_loaded(const std::string& command, const std::string& category) {
    if (!groups_ || command.empty() || category.empty()) return;
    loaded_[category].insert(command);
}

void RunLearner::command_result(const std::string& command, bool ok, const std::string& code, const std::string& message,
                                const std::string& hint, const Json& args) {
    if (!facts_ || command.empty()) return;
    const std::string argsText = args.is_object() && !args.empty() ? dump(args) : std::string();
    if (!ok) {
        if (code.empty() || code == "cancelled" || code == "truncated" || code == "blocked_by_hook") return;
        Pending p{command, code, message, hint, argsText};
        pending_[command + "\n" + code] = std::move(p);
        return;
    }
    for (auto it = pending_.begin(); it != pending_.end();) {
        if (it->second.command == command) {
            Resolved r;
            r.failure = it->second;
            r.fixArgs = argsText != it->second.failedArgs ? argsText : std::string();
            resolved_[it->first] = std::move(r);
            it = pending_.erase(it);
        } else {
            ++it;
        }
    }
}

void RunLearner::commit() {
    if (projectDir_.empty() || (loaded_.empty() && resolved_.empty())) return;
    std::error_code ec;
    if (!fsys::is_directory(fsys::path(projectDir_), ec)) return;
    std::lock_guard<std::mutex> lock(g_storeMutex);
    Json store = load_store(projectDir_);
    store["runs"][role_] = static_cast<int>(num(store["runs"], role_.c_str(), 0)) + 1;
    for (const auto& [category, commands] : loaded_) {
        Json& g = store["groups"][role_][category];
        if (!g.is_object()) g = Json::object();
        g["runs"] = static_cast<int>(num(g, "runs", 0)) + 1;
        if (!g.contains("commands") || !g["commands"].is_object()) g["commands"] = Json::object();
        for (const std::string& c : commands) g["commands"][c] = static_cast<int>(num(g["commands"], c.c_str(), 0)) + 1;
    }
    for (const auto& [key, r] : resolved_) {
        const std::string id = fact_id(r.failure.command, r.failure.code);
        Json& f = store["facts"][id];
        if (!f.is_object()) f = Json::object();
        f["command"] = r.failure.command;
        f["code"] = r.failure.code;
        f["runs"] = static_cast<int>(num(f, "runs", 0)) + 1;
        f["line"] = fact_line(r.failure.command, r.failure.code, r.failure.message, r.failure.hint, r.fixArgs);
        if (!f.contains("status")) f["status"] = "";
    }
    (void)save_store(projectDir_, store);  // a project folder that cannot be written just learns nothing
}

// --- proposals and answers -------------------------------------------------------------------------------------------------

std::vector<std::string> accepted_tool_groups(std::string_view projectDir, std::string_view role) {
    std::vector<std::string> out;
    if (projectDir.empty()) return out;
    std::lock_guard<std::mutex> lock(g_storeMutex);
    const Json store = load_store(projectDir);
    const Json* r = child(store["groups"], std::string(role).c_str());
    if (!r || !r->is_object()) return out;
    for (const auto& [group, g] : r->items())
        if (str(g, "status") == "accepted") out.push_back(group);
    return out;
}

std::vector<GroupProposal> group_proposals(const AiConfig& cfg, const CommandRegistry& registry, std::string_view projectDir) {
    std::vector<GroupProposal> out;
    if (projectDir.empty()) return out;
    std::lock_guard<std::mutex> lock(g_storeMutex);
    const Json store = load_store(projectDir);
    for (const auto& [role, groups] : store["groups"].items()) {
        if (!groups.is_object()) continue;
        for (const auto& [group, g] : groups.items()) {
            const int runs = static_cast<int>(num(g, "runs", 0));
            if (runs < kGroupProposalRuns || !str(g, "status").empty() || group_loaded_up_front(cfg, role, group)) continue;
            GroupProposal p;
            p.role = role;
            p.group = group;
            p.runs = runs;
            std::vector<std::pair<int, std::string>> byCount;
            if (const Json* cs = child(g, "commands"); cs && cs->is_object())
                for (const auto& [c, n] : cs->items()) byCount.push_back({n.is_number() ? n.get<int>() : 0, c});
            std::sort(byCount.begin(), byCount.end(), [](auto& a, auto& b) { return a.first != b.first ? a.first > b.first : a.second < b.second; });
            for (const auto& [n, c] : byCount) p.commands.push_back(c);
            p.definitionBytes = group_bytes(registry, group);
            out.push_back(std::move(p));
        }
    }
    return out;
}

std::vector<FactProposal> fact_proposals(std::string_view projectDir) {
    std::vector<FactProposal> out;
    if (projectDir.empty()) return out;
    std::lock_guard<std::mutex> lock(g_storeMutex);
    const Json store = load_store(projectDir);
    for (const auto& [id, f] : store["facts"].items()) {
        const int runs = static_cast<int>(num(f, "runs", 0));
        if (runs < kFactProposalRuns || !str(f, "status").empty()) continue;
        out.push_back({id, str(f, "command"), str(f, "code"), runs, str(f, "line")});
    }
    return out;
}

Json savers_report(const AiConfig& cfg, const CommandRegistry& registry, std::string_view projectDir) {
    Json out = Json::object();
    out["switches"] = Json::object({{"loopGuard", cfg.savers.loopGuard},
                                    {"loopGuardJudge", cfg.savers.loopGuardJudge},
                                    {"learnedToolGroups", cfg.savers.learnedToolGroups},
                                    {"projectFacts", cfg.savers.projectFacts}});
    out["thresholds"] = Json::object({{"loopGuardFailures", kLoopGuardFailures}, {"groupProposalRuns", kGroupProposalRuns}, {"factProposalRuns", kFactProposalRuns}});
    out["projectFile"] = Json::object({{"path", projectDir.empty() ? std::string() : store_path(projectDir).string()}});
    Json store;
    {
        std::lock_guard<std::mutex> lock(g_storeMutex);
        store = load_store(projectDir);
    }
    std::error_code ec;
    out["projectFile"]["exists"] = !projectDir.empty() && fsys::exists(store_path(projectDir), ec);
    out["runs"] = store["runs"];
    out["groups"] = store["groups"];
    Json accepted = Json::object();
    for (const auto& [role, groups] : store["groups"].items()) {
        Json list = Json::array();
        for (const auto& [group, g] : groups.items())
            if (str(g, "status") == "accepted") list.push_back(group);
        if (!list.empty()) accepted[role] = list;
    }
    out["acceptedGroups"] = accepted;
    Json groupJson = Json::array();
    for (const GroupProposal& p : group_proposals(cfg, registry, projectDir))
        groupJson.push_back(Json::object({{"role", p.role}, {"group", p.group}, {"runs", p.runs}, {"commands", p.commands},
                                          {"definitionBytes", p.definitionBytes}}));
    Json factJson = Json::array();
    for (const FactProposal& p : fact_proposals(projectDir))
        factJson.push_back(Json::object({{"id", p.id}, {"command", p.command}, {"code", p.code}, {"runs", p.runs}, {"line", p.line}}));
    Json facts = Json::object();
    for (const auto& [id, f] : store["facts"].items()) facts[id] = Json::object({{"runs", f.value("runs", 0)}, {"status", str(f, "status")}, {"line", str(f, "line")}});
    out["facts"] = facts;
    out["proposals"] = Json::object({{"toolGroups", groupJson}, {"facts", factJson}});
    return out;
}

std::optional<SaverAnswer> parse_saver_answer(std::string_view text) {
    if (text == "accept") return SaverAnswer::Accept;
    if (text == "decline") return SaverAnswer::Decline;
    if (text == "forget") return SaverAnswer::Forget;
    return std::nullopt;
}

namespace {
const char* status_for(SaverAnswer a) { return a == SaverAnswer::Accept ? "accepted" : a == SaverAnswer::Decline ? "declined" : ""; }
}  // namespace

Result<Json> answer_tool_group(const CommandRegistry& registry, std::string_view projectDir, std::string_view role, std::string_view group,
                               SaverAnswer answer) {
    if (projectDir.empty()) return make_error("No project is open", "Run it from a project folder (--project) or open one in the editor.");
    if (!is_known_role(role)) {
        const std::vector<std::string> names(std::begin(kAllRoles), std::end(kAllRoles));
        return make_error("No role named '" + std::string(role) + "'", fa::did_you_mean(role, names));
    }
    std::set<std::string> categories;
    for (const CommandInfo* info : registry.list())
        if (!is_agent_tool_excluded(info->name) && !info->category.empty()) categories.insert(info->category);
    if (!categories.count(std::string(group))) {
        const std::vector<std::string> names(categories.begin(), categories.end());
        return make_error("No tool group named '" + std::string(group) + "'", fa::did_you_mean(group, names) + " A group is a command category.");
    }
    std::lock_guard<std::mutex> lock(g_storeMutex);
    Json store = load_store(projectDir);
    Json& g = store["groups"][std::string(role)][std::string(group)];
    if (!g.is_object()) g = Json::object({{"runs", 0}, {"commands", Json::object()}});
    g["status"] = status_for(answer);
    if (auto ok = save_store(projectDir, store); !ok) return ok.error();
    Json out = Json::object({{"role", std::string(role)}, {"group", std::string(group)}, {"status", status_for(answer)}});
    out["note"] = answer == SaverAnswer::Accept ? "From the next run the " + std::string(role) + " role in this project loads the '" + std::string(group) + "' commands in full."
                  : answer == SaverAnswer::Decline ? "It will not be proposed again. The commands stay reachable through the catalog."
                                                   : "Undecided again; it is proposed again once the runs need it.";
    return out;
}

Result<Json> answer_fact(std::string_view projectDir, std::string_view id, SaverAnswer answer, std::string_view lineOverride) {
    if (projectDir.empty()) return make_error("No project is open", "Run it from a project folder (--project) or open one in the editor.");
    std::lock_guard<std::mutex> lock(g_storeMutex);
    Json store = load_store(projectDir);
    Json* f = nullptr;
    if (auto it = store["facts"].find(std::string(id)); it != store["facts"].end()) f = &*it;
    if (!f || !f->is_object()) {
        std::vector<std::string> names;
        for (const auto& [k, v] : store["facts"].items()) names.push_back(k);
        return make_error("No project fact with id '" + std::string(id) + "'", names.empty() ? "`ai.savers` lists the facts the runs of this project learned (none yet)."
                                                                                              : fa::did_you_mean(id, names));
    }
    Json out = Json::object({{"id", std::string(id)}, {"status", status_for(answer)}});
    if (answer == SaverAnswer::Accept) {
        std::string line = std::string(lineOverride).empty() ? str(*f, "line") : one_line(std::string(lineOverride), 400);
        if (line.rfind("- ", 0) != 0) line = "- " + line;
        const fsys::path file = fsys::path(std::string(projectDir)) / "AGENTS.md";
        std::string text;
        if (std::ifstream in(file, std::ios::binary); in) {
            std::stringstream ss;
            ss << in.rdbuf();
            text = ss.str();
        }
        if (text.find(line) == std::string::npos) {
            const std::size_t at = text.find(std::string("\n") + kFactsHeading);
            const bool hasHeading = text.rfind(kFactsHeading, 0) == 0 || at != std::string::npos;
            if (!hasHeading) {
                if (!text.empty() && text.back() != '\n') text += "\n";
                text += std::string(text.empty() ? "" : "\n") + kFactsHeading + "\n\n" + line + "\n";
            } else {
                const std::size_t start = text.rfind(kFactsHeading, 0) == 0 ? 0 : at + 1;
                std::size_t next = text.find("\n## ", start + 1);
                std::size_t end = next == std::string::npos ? text.size() : next + 1;
                std::string section = text.substr(start, end - start);
                while (!section.empty() && (section.back() == '\n')) section.pop_back();
                section += "\n" + line + "\n";
                if (next != std::string::npos) section += "\n";
                text = text.substr(0, start) + section + text.substr(end);
            }
            if (auto ok = fs::write_text(file.string(), text); !ok) return ok.error();
        }
        out["written"] = line;
        out["file"] = file.string();
    }
    (*f)["status"] = status_for(answer);
    if (auto ok = save_store(projectDir, store); !ok) return ok.error();
    return out;
}

}  // namespace fa::ai
