#include "fa/ai/session.h"

#include <chrono>
#include <ctime>
#include <filesystem>
#include <fstream>

#include "fa/core/log.h"
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
    void write(Json line) {
        if (!f_.is_open()) return;
        f_ << dump(line) << "\n";
        f_.flush();
    }
    const std::string& path() const { return path_; }

private:
    std::ofstream f_;
    std::string path_;
};

std::string make_stamp() {
    auto t = std::time(nullptr);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    char buf[32];
    std::strftime(buf, sizeof buf, "%Y%m%d-%H%M%S", &tm);
    return buf;
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
    return Json::object({{"ok", ok},
                         {"finalText", finalText},
                         {"stopReason", stopReason},
                         {"error", error},
                         {"hint", hint},
                         {"usage", usage.to_json()},
                         {"costUsd", costUsd},
                         {"turns", turns},
                         {"transcript", transcriptPath}});
}

bool is_agent_tool_excluded(std::string_view name) { return fa::starts_with(name, "ai."); }

std::string tool_name_for_command(std::string_view name) {
    std::string out(name);
    for (auto& c : out) {
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-')) c = '_';
    }
    return out;
}

std::vector<ToolDef> tools_from_registry(const CommandRegistry& registry, bool withDelegate) {
    std::vector<ToolDef> tools;
    for (const CommandInfo* info : registry.list()) {  // sorted by name
        if (is_agent_tool_excluded(info->name)) continue;
        ToolDef t;
        t.name = tool_name_for_command(info->name);
        t.description = info->description.empty() ? info->summary : info->summary + "\n\n" + info->description;
        t.inputSchema = info->inputSchema;
        tools.push_back(std::move(t));
    }
    if (withDelegate) {
        ToolDef d;
        d.name = kDelegateTool;
        d.description =
            "Delegate a self-contained task to a sub-agent with its own context and a cheaper model. role \"worker\" "
            "implements features and fixes; role \"fast\" does small mechanical edits. The sub-agent has the same tools "
            "but cannot delegate and does not see this conversation: include all needed context in `task`. Returns the "
            "sub-agent's final report.";
        d.inputSchema = Json::parse(R"({"type":"object","properties":{"role":{"type":"string","enum":["worker","fast"],
            "description":"Which sub-agent runs the task."},"task":{"type":"string","description":"Complete task description with file paths and acceptance criteria."}},
            "required":["role","task"],"additionalProperties":false})");
        tools.push_back(std::move(d));
    }
    std::stable_sort(tools.begin(), tools.end(), [](const ToolDef& a, const ToolDef& b) { return a.name < b.name; });
    return tools;
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

bool AgentSession::over_budget(std::string& why) const {
    double maxCost = opt_.maxCostUsd >= 0 ? opt_.maxCostUsd : config_.limits.maxCostUsd;
    u64 maxTokens = opt_.maxTotalTokens > 0 ? opt_.maxTotalTokens : config_.limits.maxTotalTokens;
    if (maxCost > 0 && totalCost_ >= maxCost) {
        why = "Cost budget reached ($" + std::to_string(totalCost_) + " >= $" + std::to_string(maxCost) + ")";
        return true;
    }
    if (maxTokens > 0 && totalUsage_.total() >= maxTokens) {
        why = "Token budget reached (" + std::to_string(totalUsage_.total()) + " >= " + std::to_string(maxTokens) + ")";
        return true;
    }
    return false;
}

SessionResult AgentSession::run(const std::string& task) {
    totalUsage_ = {};
    totalCost_ = 0;
    delegateCount_ = 0;
    stamp_ = make_stamp();
    SessionResult r = run_role(opt_.role, task, 0);
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
    RoleConfig rc = config_.role(role);
    if (depth == 0) {
        if (!opt_.providerOverride.empty()) {
            rc.provider = opt_.providerOverride;
            if (opt_.modelOverride.empty()) {
                const ProviderConfig* p = config_.provider(rc.provider);
                rc.model = p ? p->defaultModel : "";
                if (p && p->kind == ProviderKind::Anthropic) {
                    rc.model = config_.role(role).model;
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

SessionResult AgentSession::run_cli(const std::string& role, const RoleConfig& rc, const ProviderConfig& pc,
                                    const std::string& task, int depth) {
    SessionResult res;
    PromptContext pctx{opt_.projectDir, role, false, opt_.extraSystem};
    CliRunRequest req;
    req.prompt = build_system_prompt(pctx) + "\n\n# Task\n" + task;
    req.model = rc.model == kPlaceholderModel ? std::string() : rc.model;
    req.projectDir = opt_.projectDir;

    AgentEvent start;
    start.type = AgentEvent::Type::SessionStart;
    start.text = pc.name + (req.model.empty() ? "" : "/" + req.model) + " (CLI agent, runs its own loop)";
    emit(start, depth, role);

    Transcript tr;
    if (opt_.saveTranscript) tr.open(opt_.projectDir, stamp_ + "-" + role + (depth ? "-" + std::to_string(++delegateCount_) : ""));
    tr.write(Json::object({{"kind", "start"}, {"role", role}, {"provider", pc.name}, {"model", req.model}, {"task", task}}));
    res.transcriptPath = tr.path();

    CliAgent agent(pc);
    auto run = agent.run(
        req,
        [&](const AgentEvent& ev) {
            AgentEvent copy = ev;
            tr.write(Json::object({{"kind", event_type_name(ev.type)}, {"text", ev.text}, {"tool", ev.toolName},
                                   {"input", ev.toolInput}, {"result", ev.toolResult}}));
            emit(copy, depth, "cli");
        },
        cancel_);
    if (!run) {
        res.stopReason = "error";
        res.error = run.error().message;
        res.hint = run.error().hint;
        return res;
    }
    double cost = run->costUsd;
    add_usage(run->usage, cost);
    res.finalText = run->finalText;
    res.turns = run->turns;
    res.ok = run->ok;
    res.stopReason = run->cancelled ? "cancelled" : (run->ok ? "cli" : "error");
    res.error = run->error;
    res.hint = run->hint;
    tr.write(Json::object({{"kind", "end"}, {"ok", res.ok}, {"text", res.finalText}, {"error", res.error}}));
    return res;
}

ToolResult AgentSession::execute_tool(const ToolCall& call, const std::string& role, int depth) {
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
    if (call.name == kDelegateTool && depth == 0 && role == kRoleOrchestrator && opt_.allowDelegation) {
        std::string r = str(call.input, "role");
        std::string task = str(call.input, "task");
        if ((r != kRoleWorker && r != kRoleFast) || task.empty()) {
            return fail("invalid_arguments", "agent_delegate needs role (\"worker\" or \"fast\") and a non-empty task", "");
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
    auto it = toolToCommand_.find(call.name);
    if (it == toolToCommand_.end()) {
        std::vector<std::string> names;
        for (const auto& [n, _] : toolToCommand_) names.push_back(n);
        return fail("unknown_tool", "No tool named '" + call.name + "'", fa::did_you_mean(call.name, names));
    }
    CommandResult cr = registry_.call(it->second, call.input.is_object() ? call.input : Json::object());
    if (!cr.ok) {
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

    const bool canDelegate = depth == 0 && role == kRoleOrchestrator && opt_.allowDelegation;
    PromptContext pctx{opt_.projectDir, role, canDelegate, opt_.extraSystem};
    ChatRequest req;
    req.model = rc.model;
    req.effort = rc.effort;
    req.maxTokens = rc.maxTokens;
    req.system = build_system_prompt(pctx);
    req.tools = tools_from_registry(registry_, canDelegate);
    req.stream = opt_.stream;
    toolToCommand_.clear();
    for (const CommandInfo* info : registry_.list()) {
        if (!is_agent_tool_excluded(info->name)) toolToCommand_[tool_name_for_command(info->name)] = info->name;
    }

    AgentEvent start;
    start.type = AgentEvent::Type::SessionStart;
    start.text = pc.name + "/" + rc.model + (rc.effort.empty() ? "" : " effort=" + rc.effort);
    emit(start, depth, role);

    Transcript tr;
    if (opt_.saveTranscript) tr.open(opt_.projectDir, stamp_ + "-" + role + (depth ? "-" + std::to_string(++delegateCount_) : ""));
    tr.write(Json::object({{"kind", "start"}, {"role", role}, {"provider", pc.name}, {"model", rc.model},
                           {"effort", rc.effort}, {"tools", req.tools.size()}, {"task", task}}));
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
    std::vector<Message> history;  // append-only
    history.push_back(Message::user(task));
    tr.write(Json::object({{"kind", "user"}, {"text", task}}));
    int pauseStreak = 0;

    auto finish_with = [&](bool ok, const std::string& stop, const std::string& text, const std::string& error,
                           const std::string& hint) {
        res.ok = ok;
        res.stopReason = stop;
        res.finalText = text;
        res.error = error;
        res.hint = hint;
        tr.write(Json::object({{"kind", "end"}, {"ok", ok}, {"stopReason", stop}, {"text", text}, {"error", error}}));
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
        auto resp = provider->chat(req, hooks, cancel_);
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
            emit(u, depth, role);
        }
        history.push_back(resp->message);  // APPEND the assistant message unchanged (raw content kept)
        tr.write(Json::object({{"kind", "assistant"}, {"stopReason", resp->rawStopReason}, {"text", resp->message.text},
                               {"content", resp->message.raw}, {"usage", resp->usage.to_json()}, {"costUsd", cost}}));
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
                continue;
            }
            results.push_back(execute_tool(call, role, depth));
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
        for (const auto& r : results) {
            trJson.push_back(Json::object({{"toolUseId", r.toolUseId}, {"isError", r.isError}, {"content", clip_text(r.content, 4000)}}));
        }
        tr.write(Json::object({{"kind", "tool_results"}, {"results", trJson}}));
        history.push_back(Message::tool_results(std::move(results)));
    }
}

}  // namespace fa::ai
