// beforeCommand / afterCommand hooks around the commands of a registry (command_hooks.h, docs/HOOKS.md).
#include "fa/ai/command_hooks.h"

#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <mutex>

#include "fa/core/date.h"
#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using util::child;

namespace {

constexpr std::size_t kMaxResultBytes = 20000;  // of a command's result handed to an afterCommand hook

// While a hook runs on this thread, commands it makes the registry run are not hooked again.
thread_local bool tInHook = false;
// One entry per call that went through `before` and will reach `after`: the warnings of a hook that failed before the command.
thread_local std::vector<std::vector<std::string>> tPendingWarnings;

struct HookGuard {
    HookGuard() { tInHook = true; }
    ~HookGuard() { tInHook = false; }
};

bool in_hook_process() {
    const char* v = std::getenv("FACTORIA_IN_HOOK");
    return v && *v && std::string(v) != "0";
}

Json clipped_result(const Json& r) {
    const std::string text = util::dump(r);
    if (text.size() <= kMaxResultBytes) return r;
    return Json::object({{"clipped", true}, {"bytes", text.size()}, {"start", text.substr(0, 2000)}});
}

std::string failure_line(const HookRunRecord& r) {
    return std::string(hook_event_name(r.event)) + " hook " + r.extension + ": " + r.target + " failed: " + r.error;
}

}  // namespace

struct CommandHooks::State {
    CommandHooksOptions opt;
    mutable std::mutex mu;
    std::shared_ptr<const CommandHookConfig> config = std::make_shared<CommandHookConfig>();
    std::string error;
    std::chrono::steady_clock::time_point lastRead{};
    bool everRead = false;
    std::string sessionId;
    std::shared_ptr<const CommandInterceptor> interceptor;

    void read() {
        auto fresh = std::make_shared<CommandHookConfig>();
        std::string err;
        if (opt.loadConfig) {
            auto cfg = opt.loadConfig();
            if (!cfg) {
                err = cfg.error().message;
            } else {
                const std::string dir = opt.projectDir ? opt.projectDir() : std::string();
                ExtensionContext ctx = make_extension_context(*cfg, dir, opt.env);
                if (!opt.trustPath.empty()) ctx.trustPath = opt.trustPath;
                ctx.dropStaleTrust = false;
                *fresh = load_command_hooks(*cfg, ctx);
            }
        }
        std::lock_guard<std::mutex> lock(mu);
        config = std::move(fresh);
        error = std::move(err);
        lastRead = std::chrono::steady_clock::now();
        everRead = true;
    }

    std::shared_ptr<const CommandHookConfig> snapshot() {
        bool stale = false;
        {
            std::lock_guard<std::mutex> lock(mu);
            stale = !everRead || opt.refreshSeconds <= 0 ||
                    std::chrono::duration<double>(std::chrono::steady_clock::now() - lastRead).count() >= opt.refreshSeconds;
        }
        if (stale) read();
        std::lock_guard<std::mutex> lock(mu);
        return config;
    }

    HookRunContext context() const {
        HookRunContext ctx;
        ctx.projectDir = opt.projectDir ? opt.projectDir() : std::string();
        ctx.sessionId = sessionId;
        ctx.cancel = opt.cancel;
        ctx.defaultTimeoutSeconds = opt.defaultTimeoutSeconds;
        return ctx;
    }
};

CommandHooks::CommandHooks(CommandHooksOptions options) : state_(std::make_shared<State>()) {
    state_->opt = std::move(options);
    state_->sessionId = "factoria-" + std::to_string(unix_time_ms_now());
}

CommandHookConfig CommandHooks::current() const {
    std::lock_guard<std::mutex> lock(state_->mu);
    return *state_->config;
}

std::string CommandHooks::configError() const {
    std::lock_guard<std::mutex> lock(state_->mu);
    return state_->error;
}

void CommandHooks::refresh() { state_->read(); }

std::shared_ptr<const CommandInterceptor> CommandHooks::interceptor() {
    if (state_->interceptor) return state_->interceptor;
    auto st = state_;
    auto ic = std::make_shared<CommandInterceptor>();
    ic->wants = [st](std::string_view name) {
        if (tInHook) return false;
        const auto cfg = st->snapshot();
        if (cfg->set.empty()) return false;
        return !cfg->set.matching(HookEvent::BeforeCommand, name).empty() || !cfg->set.matching(HookEvent::AfterCommand, name).empty();
    };
    ic->before = [st](std::string_view name, Json& args) -> std::optional<CommandResult> {
        const auto cfg = st->snapshot();
        std::vector<std::string> warnings;
        if (!cfg->set.matching(HookEvent::BeforeCommand, name).empty()) {
            HookGuard guard;
            HookRunContext ctx = st->context();
            Json input = Json::object({{"command", std::string(name)}, {"args", args}});
            HookOutcome out = run_hooks(cfg->set, HookEvent::BeforeCommand, name, input, ctx);
            for (const HookRunRecord& r : out.runs)
                if (r.failed) {
                    warnings.push_back(failure_line(r));
                    FA_WARN("hooks", "{}", failure_line(r));
                }
            if (out.blocked || out.stop) {
                const std::string why = out.blocked ? out.reason : out.stopReason;
                CommandResult r;
                r.ok = false;
                r.error = Json::object(
                    {{"code", "blocked_by_hook"},
                     {"message", "A beforeCommand hook (" + (out.blockedBy.empty() ? std::string("a hook") : out.blockedBy) + ") blocked '" + std::string(name) +
                                     "'" + (why.empty() ? std::string(".") : ": " + why)},
                     {"hint", "The command did not run. The hook is in the \"hooks\" entries of ai.json or .factoria/extensions.json (`ai.hooks` lists them); "
                              "change the call so the hook accepts it, or ask the user to change the hook."}});
                if (!warnings.empty()) r.error["hookWarnings"] = warnings;
                return r;
            }
            if (out.updatedInput && out.updatedInput->is_object()) args = *out.updatedInput;
        }
        tPendingWarnings.push_back(std::move(warnings));
        return std::nullopt;
    };
    ic->after = [st](std::string_view name, const Json& args, CommandResult& result, double ms) {
        std::vector<std::string> warnings;
        if (!tPendingWarnings.empty()) {
            warnings = std::move(tPendingWarnings.back());
            tPendingWarnings.pop_back();
        }
        const auto cfg = st->snapshot();
        if (!cfg->set.matching(HookEvent::AfterCommand, name).empty()) {
            HookGuard guard;
            HookRunContext ctx = st->context();
            Json input = Json::object({{"command", std::string(name)}, {"args", args}, {"ok", result.ok}, {"durationMs", std::round(ms * 10) / 10}});
            if (result.ok) input["result"] = clipped_result(result.result);
            else input["error"] = result.error;
            HookOutcome out = run_hooks(cfg->set, HookEvent::AfterCommand, name, input, ctx);
            for (const HookRunRecord& r : out.runs)
                if (r.failed) {
                    warnings.push_back(failure_line(r));
                    FA_WARN("hooks", "{}", failure_line(r));
                }
        }
        if (!warnings.empty()) {
            Json& target = result.ok ? result.result : result.error;
            if (target.is_object()) target["hookWarnings"] = warnings;
        }
    };
    state_->interceptor = ic;
    return ic;
}

std::shared_ptr<CommandHooks> install_command_hooks(CommandRegistry& registry, CommandHooksOptions options) {
    if (in_hook_process()) return nullptr;
    auto hooks = std::make_shared<CommandHooks>(std::move(options));
    registry.set_interceptor(hooks->interceptor());
    return hooks;
}

// --- reports ---------------------------------------------------------------------------------------------------------

namespace {

Json handlers_json(const Json& hooks) {
    Json events = Json::object();
    if (!hooks.is_object()) return events;
    for (auto it = hooks.begin(); it != hooks.end(); ++it) {
        if (!it.value().is_array()) continue;
        Json groups = Json::array();
        for (const Json& g : it.value()) {
            Json handlers = Json::array();
            const Json* hs = child(g, "hooks");
            if (hs && hs->is_array())
                for (const Json& h : *hs) {
                    const std::string type = util::str(h, "type");
                    Json hj = Json::object({{"type", type}, {"target", type == "js" ? util::str(h, "module") : type == "command" ? util::str(h, "command") : util::str(h, "url", type)}});
                    if (h.contains("timeout")) hj["timeout"] = h["timeout"];
                    hj["runsHere"] = type == "command" || type == "js";
                    handlers.push_back(std::move(hj));
                }
            groups.push_back(Json::object({{"matcher", util::str(g, "matcher", util::str(g, "match"))}, {"handlers", std::move(handlers)}}));
        }
        events[it.key()] = std::move(groups);
    }
    return events;
}

}  // namespace

Json hooks_report(const AiConfig& cfg, const ExtensionContext& ctx, std::string_view roleFilter, std::size_t recentRuns) {
    const ProjectTrustState state = read_project_trust(ctx, false);
    std::vector<const Extension*> all;
    for (const Extension& e : cfg.extensions.entries)
        if (e.kind == ExtensionKind::Hooks) all.push_back(&e);
    for (const Extension& e : state.extensions.entries)
        if (e.kind == ExtensionKind::Hooks) all.push_back(&e);
    Json entries = Json::array();
    std::vector<HookSource> sources;
    for (const Extension* e : all) {
        if (!roleFilter.empty() && !e->serves_role(roleFilter)) continue;
        const ExtensionItem item = resolve_extension(*e, ctx, state.trusted);
        Json j = Json::object({{"name", e->name}, {"source", e->source}, {"enabled", e->enabled}, {"events", handlers_json(e->hooks)},
                               {"runsProgram", e->runs_program()}});
        j["roles"] = e->roles.empty() ? Json(std::vector<std::string>(std::begin(kDefaultExtensionRoles), std::end(kDefaultExtensionRoles)))
                                      : Json(e->roles);
        if (e->from_project() && e->runs_program()) j["trusted"] = state.trusted;
        if (!item.problem.empty()) {
            j["problem"] = item.problem;
            j["fix"] = item.fix;
        } else if (e->enabled) {
            sources.push_back({e->name, e->source, e->hooks});
        }
        entries.push_back(std::move(j));
    }
    Json out = Json::object({{"entries", std::move(entries)},
                             {"events", engine_hook_event_names()},
                             {"defaultTimeoutSeconds", kDefaultHookTimeoutSeconds},
                             {"notRun", make_hook_set(sources).notRun}});
    if (!state.extensions.error.empty()) out["projectFileError"] = state.extensions.error;
    Json runs = Json::array();
    for (const HookRunRecord& r : recent_hook_runs(recentRuns)) runs.push_back(r.to_json());
    out["recentRuns"] = std::move(runs);
    return out;
}

Result<Json> test_hooks(const AiConfig& cfg, const ExtensionContext& ctx, HookEvent event, const std::string& matchValue, const Json& input,
                        const std::string& role, const CancelFlag* cancel) {
    HookSet set;
    std::vector<ExtensionItem> skipped;
    if (is_command_hook_event(event)) {
        CommandHookConfig c = load_command_hooks(cfg, ctx);
        set = std::move(c.set);
        skipped = std::move(c.skipped);
    } else {
        if (!is_known_role(role)) {
            const std::vector<std::string> names(std::begin(kAllRoles), std::end(kAllRoles));
            return Error{"No role named '" + role + "'", fa::did_you_mean(role, names)};
        }
        ProviderConfig synthetic;
        synthetic.name = "hooks-test";
        synthetic.kind = ProviderKind::Anthropic;  // a provider whose loop runs hooks
        const ExtensionPlan plan = plan_extensions(cfg, synthetic, role, ExtensionContext{ctx.projectDir, ctx.env, ctx.trustPath, false});
        set = make_hook_set(plan.hookSources);
        skipped = plan.skipped;
    }
    HookRunContext hc;
    hc.projectDir = ctx.projectDir;
    hc.sessionId = "hooks-test";
    hc.cancel = cancel;
    const auto groups = set.matching(event, matchValue);
    Json out = Json::object({{"event", hook_event_name(event)}, {"matched", matchValue}, {"groups", groups.size()}});
    HookOutcome o = run_hooks(set, event, matchValue, input, hc);
    out["outcome"] = hook_outcome_json(o);
    Json skippedJson = Json::array();
    for (const ExtensionItem& s : skipped) skippedJson.push_back(Json::object({{"name", s.name}, {"source", s.source}, {"reason", s.problem}, {"fix", s.fix}}));
    out["skipped"] = std::move(skippedJson);
    if (groups.empty()) {
        out["note"] = std::string("No hook is configured for ") + hook_event_name(event) + " with '" + matchValue +
                      "'. `ai.hooks` lists what is configured; a matcher compares with the tool name, the command name or the source.";
    }
    return out;
}

}  // namespace fa::ai
