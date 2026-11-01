#include "fa/ai/session.h"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <mutex>

#include "fa/ai/extension_plan.h"
#include "fa/ai/tool_catalog.h"
#include "fa/core/date.h"
#include "fa/core/log.h"
#include "fa/core/screenshot_files.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

namespace {

constexpr std::size_t kMaxToolResultChars = 60000;
constexpr const char* kPlaceholderModel = "CHANGE_ME";

class Transcript {
public:
    void open(const std::string& projectDir, const std::string& name) {
        if (projectDir.empty()) return;
        std::error_code ec;
        fsys::path dir = fsys::path(projectDir) / ".factoria" / "ai" / "sessions";
        fsys::create_directories(dir, ec);
        path_ = (dir / (name + ".jsonl")).generic_string();  // forward slashes on every OS (stable for tools/AIs)
        f_.open(path_, std::ios::binary | std::ios::app);
        if (!f_) path_.clear();
    }
    // Every line gets "t", the UTC time it was written ("2026-10-30T14:03:22.481Z"), unless the caller set one.
    void write(Json line) {
        if (!f_.is_open()) return;
        const std::int64_t now = unix_time_ms_now();
        if (!line.contains("t")) line["t"] = iso_utc_ms(now);
        f_ << dump(line) << "\n";
        f_.flush();
        lastMs_ = now;
    }
    // An event of a CLI agent. Adds "ms": a thinking event, the time since the line before it (the model was thinking
    // that long, also when the text is hidden and the event has none); a tool_end, the time since its tool_start (the
    // tool's own duration, matched by the tool call id, else the oldest running tool of that name).
    void write_event(const AgentEvent& ev, Json line) {
        if (!f_.is_open()) return;
        const std::int64_t now = unix_time_ms_now();
        if (ev.type == AgentEvent::Type::ThinkingDelta && lastMs_ > 0) line["ms"] = std::max<std::int64_t>(0, now - lastMs_);
        if (ev.type == AgentEvent::Type::ToolStart) {
            running_.push_back({ev.toolId, ev.toolName, now});
        } else if (ev.type == AgentEvent::Type::ToolEnd) {
            for (auto it = running_.begin(); it != running_.end(); ++it) {
                if (ev.toolId.empty() ? it->name == ev.toolName : it->id == ev.toolId) {
                    line["ms"] = std::max<std::int64_t>(0, now - it->startMs);
                    running_.erase(it);
                    break;
                }
            }
        }
        if (!ev.toolId.empty()) line["id"] = ev.toolId;
        write(std::move(line));
    }
    const std::string& path() const { return path_; }

private:
    struct Running {
        std::string id, name;
        std::int64_t startMs = 0;
    };
    std::ofstream f_;
    std::string path_;
    std::int64_t lastMs_ = 0;
    std::vector<Running> running_;
};

// "20261014-153012", with "-2", "-3"... when another session of this process already took that second: several runs started
// together (the editor runs more than one chat at a time) must not append to one transcript file.
std::string make_stamp() {
    static std::mutex mu;
    static std::time_t lastSecond = 0;
    static int sameSecond = 0;
    auto t = std::time(nullptr);
    int sequence = 0;
    {
        std::lock_guard<std::mutex> lock(mu);
        sameSecond = (t == lastSecond) ? sameSecond + 1 : 0;
        lastSecond = t;
        sequence = sameSecond;
    }
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    char buf[32];
    std::strftime(buf, sizeof buf, "%Y%m%d-%H%M%S", &tm);
    return sequence == 0 ? std::string(buf) : std::string(buf) + "-" + std::to_string(sequence + 1);
}

std::string clip_text(std::string s, std::size_t n) {
    if (s.size() > n) {
        s.resize(n);
        s += "\n...[truncated " + std::to_string(s.size() - n) + " chars]";
    }
    return s;
}

}  // namespace

Json SessionResult::to_json() const {
    Json j = Json::object({{"ok", ok},
                           {"finalText", finalText},
                           {"stopReason", stopReason},
                           {"error", error},
                           {"hint", hint},
                           {"usage", usage.to_json()},
                           {"costUsd", costUsd},
                           {"turns", turns},
                           {"transcript", transcriptPath}});
    if (!conversation.cliSessionId.empty()) j["sessionId"] = conversation.cliSessionId;
    return j;
}

Json Conversation::to_json() const {
    Json hist = Json::array();
    for (const auto& m : history) hist.push_back(saved_message_json(m));
    return Json::object({{"key", key}, {"cliSessionId", cliSessionId}, {"cliCostUsd", cliCostUsd}, {"history", hist}});
}

Conversation Conversation::from_json(const Json& j) {
    Conversation c;
    c.key = str(j, "key");
    c.cliSessionId = str(j, "cliSessionId");
    c.cliCostUsd = num(j, "cliCostUsd");
    if (const Json* hist = child(j, "history"); hist && hist->is_array()) {
        for (const auto& m : *hist) c.history.push_back(message_from_json(m));
    }
    return c;
}

// The ai.* commands are for people (they start other agents or spend money); ai.review_feedback is the exception: the agent that
// writes a feedback entry's `share` text checks it with it.
bool is_agent_tool_excluded(std::string_view name) { return fa::starts_with(name, "ai.") && name != "ai.review_feedback"; }

std::string tool_name_for_command(std::string_view name) {
    std::string out(name);
    for (auto& c : out) {
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-')) c = '_';
    }
    return out;
}

bool is_read_only_tool(const CommandInfo& info) {
    if (info.readOnly) return true;
    // Playing the game changes the running session, not the project's files.
    static const char* const kPlay[] = {"game.step",         "game.input",       "game.click",     "game.pause",
                                        "game.resume",       "game.screenshot",  "scene.load",     "scene.reload",
                                        "ui.set_text_scale", "ui.set_scale",     "ui.set_slider",  "ui.check_layout",
                                        "i18n.set_language", "screen.set_safe_area"};
    for (const char* name : kPlay) {
        if (info.name == name) return true;
    }
    return false;
}

std::string mcp_tool_name_for(std::string_view commandName) {
    std::string out = tool_name_for_command(commandName);
    if (out.size() > 64) out.resize(64);
    return out;
}

std::vector<std::string> cli_disallowed_tools(const CommandRegistry& registry, std::string_view role, bool canDelegate) {
    std::vector<std::string> out = {"Agent", "Task"};
    if (!canDelegate) out.push_back("mcp__factoria__ai_run");
    out.push_back("mcp__factoria__ai_review");
    if (is_review_role(role)) {
        for (const char* t : {"Edit", "MultiEdit", "Write", "NotebookEdit", "Bash"}) out.push_back(t);
        for (const CommandInfo* info : registry.list()) {
            if (info->name == "ai.run" || info->name == "ai.review") continue;  // already listed
            if (!is_read_only_tool(*info)) out.push_back("mcp__factoria__" + mcp_tool_name_for(info->name));
        }
    }
    return out;
}

ToolDef delegate_tool_def() {
    ToolDef d;
    d.name = kDelegateTool;
    d.description =
        "Delegate a self-contained task to a sub-agent with its own context and a cheaper model. role \"worker\" "
        "implements features and fixes; role \"fast\" does small mechanical edits; role \"artist\" makes the game's "
        "art (images, textures, sprites, models, the look); role \"audio\" makes its sound effects, music, voice "
        "and mixing. The sub-agent has the same tools but cannot delegate and does not see this conversation: include "
        "all needed context in `task`. Returns the sub-agent's final report. (Art critics and game reviewers are not "
        "available here: the user asks for reviews.)";
    d.inputSchema = Json::parse(R"({"type":"object","properties":{"role":{"type":"string","enum":["worker","fast","artist","audio"],
            "description":"Which sub-agent runs the task."},"task":{"type":"string","description":"Complete task description with file paths and acceptance criteria."}},
            "required":["role","task"],"additionalProperties":false})");
    return d;
}

std::vector<ToolDef> tools_from_registry(const CommandRegistry& registry, bool withDelegate, bool readOnly) {
    std::vector<ToolDef> tools;
    for (const CommandInfo* info : registry.list()) {  // sorted by name
        if (is_agent_tool_excluded(info->name)) continue;
        if (readOnly && !is_read_only_tool(*info)) continue;
        tools.push_back(tool_def_for_command(*info));
    }
    if (withDelegate) tools.push_back(delegate_tool_def());
    std::stable_sort(tools.begin(), tools.end(), [](const ToolDef& a, const ToolDef& b) { return a.name < b.name; });
    return tools;
}

std::string cancel_cause_text(const std::string& cause) {
    static const std::map<std::string, std::string> words = {
        {"user_stop", "the user pressed Stop"},
        {"stuck_stop", "the user pressed Stop on the no-activity warning"},
        {"watchdog_process_gone", "the editor's watchdog thought the agent process was gone"},
        {"activity_check_process_gone", "Check activity found the agent process gone"},
        {"project_closed", "the project was closed"},
        {"editor_closing", "the editor was closing"},
        {"editor_restart", "the editor was restarting"},
        {"run_ended", "the run had already ended"},
    };
    auto it = words.find(cause);
    return it != words.end() ? it->second : cause;
}

std::string cancelled_message(const std::string& cause) {
    return cause.empty() ? std::string("cancelled") : "cancelled: " + cancel_cause_text(cause);
}

AgentSession::AgentSession(CommandRegistry& registry, AiConfig config, SessionOptions options)
    : registry_(registry), config_(std::move(config)), opt_(std::move(options)) {
    factory_ = [](const ProviderConfig& pc) { return make_chat_provider(pc); };
}

void AgentSession::emit(AgentEvent e, int depth, const std::string& role) {
    e.depth = depth;
    if (e.role.empty()) e.role = role;
    if (onEvent_) onEvent_(e);
}

void AgentSession::add_usage(const Usage& u, double cost) {
    totalUsage_ += u;
    totalCost_ += cost;
}

bool AgentSession::over_budget(std::string& why) const { return over_budget(totalUsage_, totalCost_, why); }

bool AgentSession::over_budget(const Usage& usageNow, double costNow, std::string& why) const {
    double maxCost = opt_.maxCostUsd >= 0 ? opt_.maxCostUsd : config_.limits.maxCostUsd;
    u64 maxTokens = opt_.maxTotalTokens > 0 ? opt_.maxTotalTokens : config_.limits.maxTotalTokens;
    if (maxCost > 0 && costNow >= maxCost) {
        why = "Cost budget reached ($" + std::to_string(costNow) + " >= $" + std::to_string(maxCost) + ")";
        return true;
    }
    if (maxTokens > 0 && usageNow.total() >= maxTokens) {
        why = "Token budget reached (" + std::to_string(usageNow.total()) + " >= " + std::to_string(maxTokens) + ")";
        return true;
    }
    return false;
}

SessionResult AgentSession::run(const std::string& task, const std::vector<std::string>& imageFiles) {
    totalUsage_ = {};
    totalCost_ = 0;
    delegateCount_ = 0;
    stamp_ = make_stamp();
    images_.clear();
    imagePaths_.clear();
    SessionResult r;
    for (const auto& path : imageFiles) {
        auto img = load_image_data(path);
        if (!img) {
            r.stopReason = "error";
            r.error = img.error().message;
            r.hint = img.error().hint;
            r.conversation = opt_.conversation;
            break;
        }
        images_.push_back(std::move(*img));
        imagePaths_.push_back(path);
    }
    if (r.error.empty()) r = run_role(opt_.role, task, 0);
    if (r.conversation.key.empty()) r.conversation = opt_.conversation;  // nothing ran: the conversation is as it was
    r.usage = totalUsage_;
    r.costUsd = totalCost_;
    AgentEvent e;
    e.type = r.ok ? AgentEvent::Type::Done : AgentEvent::Type::Error;
    e.text = r.ok ? r.finalText : r.error;
    e.isError = !r.ok;
    e.usage = totalUsage_;
    e.costUsd = totalCost_;
    emit(e, 0, opt_.role);
    return r;
}

SessionResult AgentSession::run_role(const std::string& role, const std::string& task, int depth) {
    RoleConfig rc = config_.effective_role(role);  // a review role that is off runs on the orchestrator's model
    if (depth == 0) {
        if (!opt_.providerOverride.empty()) {
            rc.provider = opt_.providerOverride;
            if (opt_.modelOverride.empty()) {
                const ProviderConfig* p = config_.provider(rc.provider);
                rc.model = p ? p->defaultModel : "";
                if (p && p->kind == ProviderKind::Anthropic) {
                    rc.model = config_.effective_role(role).model;
                }
            }
        }
        if (!opt_.modelOverride.empty()) rc.model = opt_.modelOverride;
    }
    const ProviderConfig* pc = config_.provider(rc.provider);
    SessionResult res;
    if (!pc) {
        std::vector<std::string> names;
        for (const auto& [n, _] : config_.providers) names.push_back(n);
        res.stopReason = "error";
        res.error = "Role '" + role + "' uses unknown provider '" + rc.provider + "'";
        res.hint = fa::did_you_mean(rc.provider, names);
        return res;
    }
    return is_cli_kind(pc->kind) ? run_cli(role, rc, *pc, task, depth) : run_chat(role, rc, *pc, task, depth);
}

// The skills this role is offered, for its system prompt (docs/SKILLS.md). `native`: the CLI lists them itself.
static void add_prompt_skills(PromptContext& pctx, const AiConfig& config, const SessionOptions& opt, const std::string& role, bool native) {
    SkillsContext sctx;
    sctx.projectDir = opt.projectDir;
    sctx.env = opt.env;
    pctx.skills = skills_for_prompt(scan_skills(config, sctx), role, config.disabled_delegable_roles());
    pctx.skillsKnown = true;
    pctx.skillsNative = native;
}

SessionResult AgentSession::run_cli(const std::string& role, const RoleConfig& rc, const ProviderConfig& pc,
                                    const std::string& task, int depth) {
    SessionResult res;
    // A CLI orchestrator delegates through the FactorIA MCP server it is attached to: ai.run starts the role from ai.json.
    const bool canDelegate = depth == 0 && role == kRoleOrchestrator && opt_.allowDelegation && config_.can_delegate_to_anyone();
    PromptContext pctx{opt_.projectDir, role, canDelegate, opt_.extraSystem, "ai_run", config_.assetSources, config_.disabled_delegable_roles()};
    // The user's external tool servers for this role: the CLI connects to them itself (Claude Code through the MCP config
    // file, Codex through -c arguments, a generic CLI through {mcp_config}). A server whose key is missing is left out.
    std::vector<ResolvedToolServer> resolvedServers;
    std::vector<std::string> serverNotes;
    {
        const auto servers = config_.tool_servers_for(role);
        const bool takesServers = pc.kind == ProviderKind::ClaudeCode || (pc.kind == ProviderKind::Codex && pc.argv.empty()) ||
                                  std::any_of(pc.argv.begin(), pc.argv.end(),
                                              [](const std::string& a) { return a.find("{mcp_config}") != std::string::npos; });
        if (!servers.empty() && !takesServers) {
            serverNotes.push_back("External tool servers are not passed to provider '" + pc.name +
                                  "': its \"argv\" has no {mcp_config} placeholder, so it cannot be given an MCP config. Use "
                                  "Claude Code, Codex (default argv) or the built-in agent to use them.");
        } else {
            const EnvLookup env = opt_.env ? opt_.env : system_env();
            for (const ToolServer* s : servers) {
                auto r = resolve_tool_server(*s, env);
                if (!r) {
                    serverNotes.push_back("External tool server '" + s->name + "' skipped: " + r.error().message +
                                          (r.error().hint.empty() ? "" : " (" + r.error().hint + ")"));
                    continue;
                }
                pctx.toolServers.push_back({s->name, s->note, pc.kind == ProviderKind::ClaudeCode ? "mcp__" + s->name + "__" : ""});
                resolvedServers.push_back(std::move(*r));
            }
        }
    }
    // The extensions (plugins, skills, hooks) of the user and of the project for this role, and what this provider takes of them.
    ExtensionContext extCtx = make_extension_context(config_, opt_.projectDir, opt_.env);
    if (!opt_.extensionsTrustPath.empty()) extCtx.trustPath = opt_.extensionsTrustPath;
    const ExtensionPlan extPlan = plan_extensions(config_, pc, role, extCtx);
    for (const std::string& note : extPlan.notes) serverNotes.push_back(note);
    // Claude Code lists the skills itself. Codex also finds them (.agents/skills of the project), but the prompt keeps its lines: a
    // Codex that does not scan that folder (an older one) still knows the names and reads them with skills_read.
    add_prompt_skills(pctx, config_, opt_, role, extPlan.support.skills && pc.kind == ProviderKind::ClaudeCode);
    const std::string fullPrompt = build_system_prompt(pctx) + "\n\n# Task\n" + task;
    // A follow-up message continues the CLI's session: the system prompt is already part of it, so only the task is sent.
    const bool canResume = depth == 0 && cli_supports_resume(pc);
    const Conversation& prev = opt_.conversation;
    const bool resuming = canResume && !prev.cliSessionId.empty() && prev.key == pc.name;
    CliRunRequest req;
    req.prompt = resuming ? task : fullPrompt;
    req.sessionId = resuming ? prev.cliSessionId : std::string();
    if (depth == 0) {
        req.images = images_;
        req.imagePaths = imagePaths_;
    }
    req.model = rc.model == kPlaceholderModel ? std::string() : rc.model;
    req.projectDir = opt_.projectDir;
    req.mcpUrl = opt_.mcpUrl;
    // The agent delegates only through ai_run (and the read-only roles change nothing): its own sub-agent tools and, for
    // artCritic and reviewer, the tools that edit, are switched off (cli_disallowed_tools).
    req.disallowedTools = cli_disallowed_tools(registry_, role, canDelegate);
    req.readOnly = is_review_role(role);
    req.webDomains = asset_source_hosts(config_.assetSources);  // Claude Code: WebFetch for these sites, only these with onlyListed
    req.webOnlyListed = config_.assetSources.onlyListed;
    req.toolServers = resolvedServers;
    req.pluginDirs = extPlan.pluginDirs;
    req.skillDirs = extPlan.skillDirs;
    req.skillDirs.insert(req.skillDirs.end(), extPlan.implicitSkillDirs.begin(), extPlan.implicitSkillDirs.end());
    req.hooks = extPlan.hooks;
    req.userPluginsOff = extPlan.userPluginsOff;
    req.projectSettingsOff = extPlan.projectSettingsOff;
    if (opt_.onProcessStart) req.onStart = [this, role](long long pid) { opt_.onProcessStart(pid, role); };

    AgentEvent start;
    start.type = AgentEvent::Type::SessionStart;
    start.text = pc.name + (req.model.empty() ? "" : "/" + req.model) + " (CLI agent, runs its own loop)";
    emit(start, depth, role);
    for (const std::string& note : serverNotes) {
        AgentEvent info;
        info.type = AgentEvent::Type::Info;
        info.text = note;
        emit(info, depth, role);
    }

    Transcript tr;
    if (opt_.saveTranscript) tr.open(opt_.projectDir, stamp_ + "-" + role + (depth ? "-" + std::to_string(++delegateCount_) : ""));
    tr.write(Json::object({{"kind", "start"}, {"role", role}, {"provider", pc.name}, {"model", req.model}, {"task", task}}));
    res.transcriptPath = tr.path();

    // The role's context limit: Claude Code compacts the session when it reaches this window. Shown as the window too.
    ProviderConfig cliPc = pc;
    const u64 window = pc.kind == ProviderKind::ClaudeCode ? rc.maxContextTokens : 0;
    if (window > 0) cliPc.env["CLAUDE_CODE_AUTO_COMPACT_WINDOW"] = std::to_string(window);
    CliAgent agent(cliPc);
    // Claude Code's total_cost_usd counts the whole resumed session (checked with 2.1.296): subtract what the earlier
    // messages already cost, so every message reports its own.
    double costBase = resuming ? prev.cliCostUsd : 0;
    const auto onEvent = [&](const AgentEvent& ev) {
        AgentEvent copy = ev;
        // The CLI's own total counts the whole resumed session; the engine's estimate counts this run only.
        if (ev.type == AgentEvent::Type::Usage && !ev.costIsEstimate && copy.costUsd >= costBase) copy.costUsd -= costBase;
        if (ev.type == AgentEvent::Type::Usage && window > 0 && (copy.contextWindow == 0 || copy.contextWindow > window)) {
            copy.contextWindow = window;
        }
        tr.write_event(ev, Json::object({{"kind", event_type_name(ev.type)}, {"text", ev.text}, {"tool", ev.toolName},
                                         {"input", ev.toolInput}, {"result", ev.toolResult}}));
        emit(copy, depth, "cli");
    };
    // The run's limits see the live numbers: the CLI is killed as soon as its tokens or cost cross them.
    std::string budgetWhy;
    req.stopWhen = [&](const Usage& u, double cliCost, bool isEstimate) {
        Usage soFar = totalUsage_;
        soFar += u;
        double c = totalCost_ + ((!isEstimate && cliCost >= costBase) ? cliCost - costBase : cliCost);
        return over_budget(soFar, c, budgetWhy);
    };
    auto run = agent.run(req, onEvent, cancel_);
    if (resuming && run && !run->ok && !run->cancelled &&
        run->error.find("No conversation found") != std::string::npos) {
        // The CLI forgot the session (its data was cleaned up, or the project moved): carry on in a new one.
        AgentEvent info;
        info.type = AgentEvent::Type::Info;
        info.text = "The earlier conversation could not be resumed (" + std::string(fa::trim(run->error)) + "); starting a new one.";
        emit(info, depth, role);
        req.sessionId.clear();
        req.prompt = fullPrompt;
        costBase = 0;
        budgetWhy.clear();
        run = agent.run(req, onEvent, cancel_);
    }
    if (!run) {
        res.stopReason = "error";
        res.error = run.error().message;
        res.hint = run.error().hint;
        return res;
    }
    double cost = !run->costIsEstimate && run->costUsd >= costBase ? run->costUsd - costBase : run->costUsd;
    if (depth == 0 && canResume) {
        res.conversation = prev.key == pc.name ? prev : Conversation{};
        res.conversation.key = pc.name;
        if (!run->sessionId.empty()) {
            res.conversation.cliSessionId = run->sessionId;
            res.conversation.cliCostUsd = run->costIsEstimate ? costBase + run->costUsd : run->costUsd;
        }
    }
    add_usage(run->usage, cost);
    res.finalText = run->finalText;
    res.turns = run->turns;
    res.ok = run->ok;
    res.stopReason = run->cancelled ? "cancelled" : (run->ok ? "cli" : "error");
    res.error = run->error;
    res.hint = run->hint;
    if (run->cancelled && is_cancelled(cancel_)) {
        res.cancelCause = cancelCause_ ? cancelCause_() : std::string();
        res.error = cancelled_message(res.cancelCause);
    }
    if (!budgetWhy.empty() && run->cancelled && !is_cancelled(cancel_)) {
        res.stopReason = "budget";
        res.error = budgetWhy;
        res.hint = "Raise limits in ~/.factoria/ai.json or ai.run options.";
    }
    Json endEvent = Json::object({{"kind", "end"}, {"ok", res.ok}, {"text", res.finalText}, {"error", res.error}});
    if (!res.cancelCause.empty()) endEvent["cause"] = res.cancelCause;
    tr.write(endEvent);
    return res;
}

ToolResult AgentSession::execute_tool(const ToolCall& original, const std::string& role, int depth, McpToolSet* toolServers,
                                      const ToolPlan* plan) {
    const bool catalog = plan && plan->useCatalog;
    const bool readOnlyRole = is_review_role(role);
    // tool_call runs a command under the command's own name: the events, the read-only check and the argument errors below
    // see the command, not the wrapper. A call the wrapper cannot resolve keeps its own name and fails further down.
    ToolCall call = original;
    bool viaCall = false;
    std::string wrapCode, wrapMessage, wrapHint;
    if (catalog && original.name == kToolCall && original.inputError.empty()) {
        const std::string command = str(original.input, "command");
        const Json* args = child(original.input, "arguments");
        if (command.empty()) {
            wrapCode = "invalid_arguments";
            wrapMessage = "tool_call needs \"command\": the name of a command from the catalog";
            wrapHint = "Call tool_call {\"command\": \"scene.spawn\", \"arguments\": {...}}; tool_describe shows the arguments.";
        } else if (args && !args->is_null() && !args->is_object()) {
            wrapCode = "invalid_arguments";
            wrapMessage = "tool_call \"arguments\" must be a JSON object, not " + std::string(args->type_name());
            wrapHint = "Pass the command's arguments as an object, or {} when it takes none.";
        } else {
            std::string why, hint;
            if (const CommandInfo* info = resolve_command(registry_, command, readOnlyRole, why, hint)) {
                call.name = tool_name_for_command(info->name);
                call.input = args && args->is_object() ? *args : Json::object();
                viaCall = true;
            } else {
                wrapCode = why.rfind("No command", 0) == 0 ? "unknown_command" : "not_allowed";
                wrapMessage = why;
                wrapHint = hint;
            }
        }
    }
    ToolResult tr;
    tr.toolUseId = call.id;
    AgentEvent start;
    start.type = AgentEvent::Type::ToolStart;
    start.toolName = call.name;
    start.toolInput = call.input;
    emit(start, depth, role);

    auto finish = [&](ToolResult r, Json shown) {
        AgentEvent end;
        end.type = AgentEvent::Type::ToolEnd;
        end.toolName = call.name;
        end.toolResult = std::move(shown);
        end.isError = r.isError;
        emit(end, depth, role);
        return r;
    };
    auto fail = [&](const std::string& code, const std::string& msg, const std::string& hint) {
        tr.isError = true;
        Json err = Json::object({{"code", code}, {"message", msg}});
        if (!hint.empty()) err["hint"] = hint;
        tr.content = dump(err);
        return finish(tr, err);
    };

    if (!call.inputError.empty()) {
        return fail("invalid_arguments", "The arguments of tool '" + call.name + "' were not valid JSON: " + call.inputError,
                    "Call the tool again with a JSON object matching its input schema.");
    }
    if (!wrapCode.empty()) return fail(wrapCode, wrapMessage, wrapHint);
    if (catalog && call.name == kToolDescribe) {
        std::vector<std::string> names;
        if (const Json* list = child(call.input, "commands"); list && list->is_array()) {
            for (const Json& n : *list) if (n.is_string()) names.push_back(n.get<std::string>());
        } else if (const std::string one = str(call.input, "commands", str(call.input, "command")); !one.empty()) {
            names.push_back(one);
        }
        if (names.empty()) {
            return fail("invalid_arguments", "tool_describe needs \"commands\": a list of command names from the catalog",
                        "Call tool_describe {\"commands\": [\"assets.slice_sheet\"]}.");
        }
        bool ok = false;
        Json described = describe_commands(registry_, names, readOnlyRole, ok);
        tr.isError = !ok;
        tr.content = clip_text(dump(described), kMaxToolResultChars);
        return finish(tr, described);
    }
    if (call.name == kDelegateTool && depth == 0 && role == kRoleOrchestrator && opt_.allowDelegation) {
        std::string r = str(call.input, "role");
        std::string task = str(call.input, "task");
        if (is_review_role(r)) {
            return fail("not_delegable", "Role '" + r + "' cannot be delegated to: critics and reviewers run only when the user asks",
                        "The user starts reviews with the review buttons of the editor's AI panel (or `factoria ai review`). "
                        "When they send you a review, act on it. Delegate with role worker, fast, artist or audio.");
        }
        if (!is_delegable_role(r) || task.empty()) {
            return fail("invalid_arguments",
                        "agent_delegate needs role (\"worker\", \"fast\", \"artist\" or \"audio\") and a non-empty task", "");
        }
        if (!config_.role_enabled(r)) {
            return fail("role_off", role_off_message(r), role_off_hint(r));
        }
        AgentEvent info;
        info.type = AgentEvent::Type::Info;
        info.text = "Delegating to " + r + ": " + clip_text(task, 200);
        emit(info, depth, role);
        SessionResult sub = run_role(r, task, depth + 1);
        if (!sub.ok) {
            tr.isError = true;
            tr.content = dump(Json::object({{"code", "delegate_failed"},
                                            {"message", sub.error.empty() ? "sub-agent stopped: " + sub.stopReason : sub.error},
                                            {"stopReason", sub.stopReason},
                                            {"partialResult", sub.finalText}}));
            return finish(tr, Json::parse(tr.content));
        }
        tr.content = sub.finalText.empty() ? "(sub-agent finished without a report)" : sub.finalText;
        return finish(tr, Json(tr.content));
    }
    if (toolServers && toolServers->owns(call.name)) {  // a tool of one of the user's external tool servers
        ToolResult r = toolServers->call(call);
        r.content = clip_text(r.content, kMaxToolResultChars);
        return finish(r, Json(r.content));
    }
    auto it = toolToCommand_.find(call.name);
    if (it == toolToCommand_.end()) {
        std::vector<std::string> names;
        for (const auto& [n, _] : toolToCommand_) names.push_back(n);
        return fail("unknown_tool", "No tool named '" + call.name + "'", fa::did_you_mean(call.name, names));
    }
    Json callInput = call.input.is_object() ? call.input : Json::object();
    // A skill is read as the role that asks: the skills switched off for it are not readable (docs/SKILLS.md).
    if (it->second == "skills.read" || it->second == "skills.list") callInput["role"] = role;
    CommandResult cr = registry_.call(it->second, callInput);
    if (!cr.ok) {
        // A command the model has not seen the definition of (listed in the catalog, not offered in full): the schema comes
        // with the error, so one failed call is enough to learn the arguments.
        if (cr.error.is_object() && str(cr.error, "code") == "invalid_arguments" && catalog) {
            const bool offered = std::any_of(plan->tools.begin(), plan->tools.end(), [&](const ToolDef& t) { return t.name == call.name; });
            if (const CommandInfo* info = registry_.info(it->second); info && (viaCall || !offered)) {
                cr.error["inputSchema"] = info->inputSchema;
            }
        }
        tr.isError = true;
        tr.content = clip_text(dump(cr.error), kMaxToolResultChars);
        return finish(tr, cr.error);
    }
    Json shown = cr.result;
    // Image conventions (both attach the image to the model message):
    //   {"image": {"mediaType"|"mimeType", "data"|"base64"}}
    //   {"$image": {"path": "...", "mimeType": "image/png"}} or {"$image": {"base64": "...", "mimeType": ...}}
    if (shown.is_object()) {
        for (const char* key : {"image", "$image"}) {
            const Json* img = child(shown, key);
            if (!img || !img->is_object()) continue;
            std::string data = str(*img, "data", str(*img, "base64"));
            std::string mt = str(*img, "mediaType", str(*img, "mimeType", "image/png"));
            if (data.empty()) {
                std::string path = str(*img, "path");
                if (!path.empty()) {
                    fsys::path fp(path);
                    if (fp.is_relative() && !opt_.projectDir.empty()) fp = fsys::path(opt_.projectDir) / fp;
                    std::ifstream in(fp, std::ios::binary);
                    if (in) {
                        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
                        data = fa::base64_encode(bytes.data(), bytes.size());
                        in.close();
                        // A screenshot without `path` is temporary: its bytes are in the message now, the file can go.
                        if (!data.empty()) fa::discard_temporary_image(*img, opt_.projectDir);
                    }
                }
            }
            if (!data.empty()) {
                tr.images.push_back({mt, data});
                shown[key] = "(attached to this message)";
            }
        }
    }
    tr.content = clip_text(dump(shown), kMaxToolResultChars);
    return finish(tr, shown);
}

SessionResult AgentSession::run_chat(const std::string& role, const RoleConfig& rc, const ProviderConfig& pc,
                                     const std::string& task, int depth) {
    SessionResult res;
    if (rc.model.empty() || rc.model == kPlaceholderModel) {
        res.stopReason = "error";
        res.error = "No model configured for role '" + role + "' (provider '" + pc.name + "')";
        res.hint = "Set roles." + role + ".model (and provider) in ~/.factoria/ai.json, e.g. \"model\": \"your-model-name\".";
        return res;
    }
    std::shared_ptr<ChatProvider>& provider = providers_[pc.name];
    if (!provider) {
        auto made = factory_(pc);
        if (!made) {
            res.stopReason = "error";
            res.error = made.error().message;
            res.hint = made.error().hint;
            return res;
        }
        provider = *made;
    }

    const bool canDelegate = depth == 0 && role == kRoleOrchestrator && opt_.allowDelegation && config_.can_delegate_to_anyone();
    PromptContext pctx{opt_.projectDir, role, canDelegate, opt_.extraSystem, "", config_.assetSources, config_.disabled_delegable_roles()};
    // The user's external tool servers for this role: connect now (a program is started, a service is asked for its tools);
    // the ones that fail only give a note, the run goes on without them. They close when this function returns.
    McpToolSet toolServers;
    std::vector<std::string> serverNotes;
    if (const auto servers = config_.tool_servers_for(role); !servers.empty()) {
        McpOptions mo;
        mo.transport = opt_.toolServerTransport;
        mo.cancel = cancel_;
        toolServers.connect(servers, opt_.env ? opt_.env : system_env(), mo, serverNotes);
        for (const auto& client : toolServers.clients()) {
            const ToolServer* s = nullptr;
            for (const ToolServer* c : servers) if (c->name == client->name()) s = c;
            pctx.toolServers.push_back({client->name(), s ? s->note : std::string(), client->name() + "__"});
        }
    }
    {   // The API providers do not use extensions yet: say so when the role has any, instead of ignoring them silently.
        ExtensionContext extCtx = make_extension_context(config_, opt_.projectDir, opt_.env);
        if (!opt_.extensionsTrustPath.empty()) extCtx.trustPath = opt_.extensionsTrustPath;
        for (const std::string& note : plan_extensions(config_, pc, role, extCtx).notes) serverNotes.push_back(note);
    }
    ChatRequest req;
    req.model = rc.model;
    req.effort = rc.effort;
    req.maxTokens = rc.maxTokens;
    req.maxContextTokens = rc.maxContextTokens;  // only the Anthropic provider sends it (server-side compaction)
    const bool readOnly = is_review_role(role);  // critics and reviewers observe and play, they change nothing
    // The tool list and the catalog are fixed for the whole run (and, as long as the registry does not change, for the whole
    // conversation): tool definitions and the system prompt are the start of the prompt cache's prefix.
    ToolPlanOptions planOptions;
    planOptions.withDelegate = canDelegate;
    planOptions.readOnly = readOnly;
    planOptions.groups = rc.toolGroups ? *rc.toolGroups : default_tool_groups(role);
    planOptions.catalog = opt_.toolCatalog;
    const ToolPlan plan = plan_tools(registry_, planOptions);
    pctx.toolCatalog = plan.catalogText;
    add_prompt_skills(pctx, config_, opt_, role, false);
    req.system = build_system_prompt(pctx);
    req.tools = plan.tools;
    if (!toolServers.empty()) {
        for (ToolDef& d : toolServers.tool_defs()) req.tools.push_back(std::move(d));
        std::sort(req.tools.begin(), req.tools.end(), [](const ToolDef& a, const ToolDef& b) { return a.name < b.name; });
    }
    req.stream = opt_.stream;
    toolToCommand_.clear();
    for (const CommandInfo* info : registry_.list()) {
        if (is_agent_tool_excluded(info->name)) continue;
        if (readOnly && !is_read_only_tool(*info)) continue;  // not offered, and not callable either
        toolToCommand_[tool_name_for_command(info->name)] = info->name;
    }

    AgentEvent start;
    start.type = AgentEvent::Type::SessionStart;
    start.text = pc.name + "/" + rc.model + (rc.effort.empty() ? "" : " effort=" + rc.effort);
    emit(start, depth, role);
    for (const std::string& note : serverNotes) {
        AgentEvent info;
        info.type = AgentEvent::Type::Info;
        info.text = note;
        emit(info, depth, role);
    }
    for (const std::string& note : plan.notes) {
        AgentEvent info;
        info.type = AgentEvent::Type::Info;
        info.text = "roles." + role + ".toolGroups: " + note;
        emit(info, depth, role);
    }

    Transcript tr;
    if (opt_.saveTranscript) tr.open(opt_.projectDir, stamp_ + "-" + role + (depth ? "-" + std::to_string(++delegateCount_) : ""));
    tr.write(Json::object({{"kind", "start"}, {"role", role}, {"provider", pc.name}, {"model", rc.model},
                           {"effort", rc.effort}, {"tools", req.tools.size()}, {"catalogCommands", plan.catalog.size()},
                           {"toolGroups", plan.loadedGroups}, {"task", task}}));
    res.transcriptPath = tr.path();

    ChatHooks hooks;
    hooks.onText = [&](std::string_view t) {
        AgentEvent e;
        e.type = AgentEvent::Type::TextDelta;
        e.text = std::string(t);
        emit(e, depth, role);
    };
    hooks.onThinking = [&](std::string_view t) {
        AgentEvent e;
        e.type = AgentEvent::Type::ThinkingDelta;
        e.text = std::string(t);
        emit(e, depth, role);
    };
    hooks.onRetry = [&](const std::string& m) {
        AgentEvent e;
        e.type = AgentEvent::Type::Info;
        e.text = m;
        emit(e, depth, role);
    };

    const int maxTurns = opt_.maxTurns > 0 ? opt_.maxTurns : config_.limits.maxTurns;
    const Pricing pricing = pc.pricing.known ? pc.pricing : builtin_pricing(rc.model);
    // Append-only. A follow-up message continues the history of the same provider+model (the assistant payloads in it are
    // provider-native, so another model never gets them).
    const std::string convKey = pc.name + "/" + rc.model;
    std::vector<Message> history;
    if (depth == 0 && opt_.conversation.key == convKey) history = opt_.conversation.history;
    history.push_back(Message::user(task, depth == 0 ? images_ : std::vector<ImageData>{}));
    Json userLine = Json::object({{"kind", "user"}, {"text", task}});
    if (depth == 0 && !imagePaths_.empty()) userLine["images"] = imagePaths_;
    tr.write(userLine);
    int pauseStreak = 0;

    auto finish_with = [&](bool ok, const std::string& stop, const std::string& text, const std::string& error,
                           const std::string& hint) {
        res.ok = ok;
        res.stopReason = stop;
        res.finalText = text;
        res.error = error;
        res.hint = hint;
        if (depth == 0) {
            res.conversation.key = convKey;
            res.conversation.history = history;
        }
        Json endEvent = Json::object({{"kind", "end"}, {"ok", ok}, {"stopReason", stop}, {"text", text}, {"error", error}});
        if (stop == "cancelled") {
            res.cancelCause = cancelCause_ ? cancelCause_() : std::string();
            res.error = cancelled_message(res.cancelCause);
            endEvent["error"] = res.error;
            if (!res.cancelCause.empty()) endEvent["cause"] = res.cancelCause;
        }
        tr.write(endEvent);
        return res;
    };

    for (int turn = 1;; ++turn) {
        if (is_cancelled(cancel_)) return finish_with(false, "cancelled", res.finalText, "cancelled", "");
        if (turn > maxTurns) {
            return finish_with(false, "max_turns", res.finalText,
                               "Stopped after " + std::to_string(maxTurns) + " turns",
                               "Raise limits.maxTurns in ~/.factoria/ai.json or split the task.");
        }
        if (std::string why; over_budget(why)) {
            return finish_with(false, "budget", res.finalText, why, "Raise limits in ~/.factoria/ai.json or ai.run options.");
        }
        res.turns = turn;
        req.messages = history;
        ContextSplit split = estimate_context(req);  // what this call carries: system prompt, tool definitions, conversation
        split.catalogBytes = plan.catalogText.size();
        split.catalogCount = static_cast<int>(plan.catalog.size());
        const std::int64_t chatStartMs = unix_time_ms_now();
        auto resp = provider->chat(req, hooks, cancel_);
        const std::int64_t chatMs = unix_time_ms_now() - chatStartMs;
        if (!resp) {
            if (is_cancelled(cancel_)) return finish_with(false, "cancelled", res.finalText, "cancelled", "");
            return finish_with(false, "error", res.finalText, resp.error().message, resp.error().hint);
        }
        const double cost = estimate_cost(resp->usage, pricing);
        add_usage(resp->usage, cost);
        {
            AgentEvent u;
            u.type = AgentEvent::Type::Usage;
            u.usage = totalUsage_;
            u.costUsd = totalCost_;
            u.contextTokens = resp->contextTokens ? resp->contextTokens
                                                  : resp->usage.inputTokens + resp->usage.cacheCreationTokens + resp->usage.cacheReadTokens;
            if (pc.kind == ProviderKind::Anthropic) u.contextWindow = rc.maxContextTokens;  // compacts there; 0 = unknown
            u.contextSplit = split;
            emit(u, depth, role);
        }
        history.push_back(resp->message);  // APPEND the assistant message unchanged (raw content kept)
        tr.write(Json::object({{"kind", "assistant"}, {"stopReason", resp->rawStopReason}, {"text", resp->message.text},
                               {"content", resp->message.raw}, {"usage", resp->usage.to_json()}, {"costUsd", cost},
                               {"ms", chatMs}, {"context", split.to_json()}}));
        if (!resp->message.text.empty()) res.finalText = resp->message.text;

        switch (resp->stopReason) {
            case StopReason::Refusal: {
                std::string msg = "The model refused to continue";
                if (!resp->refusalCategory.empty()) msg += " (category: " + resp->refusalCategory + ")";
                if (!resp->refusalExplanation.empty()) msg += ": " + resp->refusalExplanation;
                return finish_with(false, "refusal", res.finalText, msg,
                                   "Rephrase the task, or switch the role to another model in ~/.factoria/ai.json.");
            }
            case StopReason::PauseTurn:
                if (++pauseStreak > 8) return finish_with(false, "error", res.finalText, "Too many consecutive pause_turn responses", "");
                continue;  // resend as-is: the API continues the paused turn
            case StopReason::MaxTokens:
                pauseStreak = 0;
                if (resp->message.toolCalls.empty()) {
                    history.push_back(Message::user("Your previous response was cut off by the output limit. Continue exactly where you stopped."));
                    tr.write(Json::object({{"kind", "user"}, {"text", "(continue after max_tokens)"}}));
                    continue;
                }
                break;  // tool calls may be truncated: answered with errors below
            default: pauseStreak = 0; break;
        }

        if (resp->message.toolCalls.empty()) {
            return finish_with(true, "end_turn", resp->message.text, "", "");
        }

        // Execute ALL tool calls of this assistant turn and answer them in ONE user message.
        std::vector<ToolResult> results;
        std::vector<std::int64_t> toolMs;
        const bool truncated = resp->stopReason == StopReason::MaxTokens;
        for (const auto& call : resp->message.toolCalls) {
            if (is_cancelled(cancel_)) break;
            if (truncated) {
                ToolResult r;
                r.toolUseId = call.id;
                r.isError = true;
                r.content = dump(Json::object(
                    {{"code", "truncated"},
                     {"message", "Your response hit the output token limit before this tool call could be trusted; it was not run."},
                     {"hint", "Repeat the call with smaller content (e.g. write big files in several steps)."}}));
                results.push_back(std::move(r));
                toolMs.push_back(0);
                continue;
            }
            const std::int64_t toolStartMs = unix_time_ms_now();
            results.push_back(execute_tool(call, role, depth, &toolServers, &plan));
            toolMs.push_back(unix_time_ms_now() - toolStartMs);
        }
        if (is_cancelled(cancel_)) {
            // Still answer every tool_use so the transcript stays valid.
            for (std::size_t i = results.size(); i < resp->message.toolCalls.size(); ++i) {
                ToolResult r;
                r.toolUseId = resp->message.toolCalls[i].id;
                r.isError = true;
                r.content = "{\"code\":\"cancelled\",\"message\":\"cancelled by the user\"}";
                results.push_back(std::move(r));
            }
            history.push_back(Message::tool_results(std::move(results)));
            return finish_with(false, "cancelled", res.finalText, "cancelled", "");
        }
        Json trJson = Json::array();
        for (std::size_t i = 0; i < results.size(); ++i) {
            const ToolResult& r = results[i];
            Json entry = Json::object({{"toolUseId", r.toolUseId}, {"isError", r.isError}, {"content", clip_text(r.content, 4000)}});
            if (i < toolMs.size() && i < resp->message.toolCalls.size()) {
                entry["tool"] = resp->message.toolCalls[i].name;
                entry["ms"] = toolMs[i];  // how long the tool ran
            }
            trJson.push_back(std::move(entry));
        }
        tr.write(Json::object({{"kind", "tool_results"}, {"results", trJson}}));
        history.push_back(Message::tool_results(std::move(results)));
    }
}

}  // namespace fa::ai
