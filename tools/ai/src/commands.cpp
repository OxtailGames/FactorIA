#include "fa/ai/commands.h"

#include <algorithm>
#include <atomic>
#include <map>
#include <memory>

#include "asset_commands.h"
#include "fa/ai/detect.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/mcp_client.h"
#include "fa/ai/review.h"
#include "fa/ai/skills.h"
#include "fa/ai/tool_catalog.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "feedback_review.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

// Runs one session the way ai.run and ai.review do: its events go to the caller as MCP progress (when the call carries a
// progressToken: the reply can take many minutes and Claude Code aborts a call that stays silent for 300 s) and to the
// host's callbacks. Every event runs on this thread: the progress scope is this thread's.
SessionResult run_agent_session(CommandRegistry& registry, const AiConfig& cfg, SessionOptions so, const AiRunInfo& info,
                                const AiCommandOptions& opts) {
    so.mcpUrl = opts.mcpUrl;
    if (opts.onRunProcess) so.onProcessStart = [&opts, info](long long pid, const std::string&) { opts.onRunProcess(info, pid); };
    AgentSession session(registry, cfg, so);
    session.set_event_handler([&opts, info](const AgentEvent& e) {
        if (opts.onEvent) opts.onEvent(e);
        if (opts.onRunEvent) opts.onRunEvent(info, e);
        const std::string what = describe_agent_event(e);
        if (!what.empty()) report_command_progress(info.role + (e.depth > 0 ? " > " : ": ") + what);
    });
    if (opts.providerFactory) session.set_provider_factory(opts.providerFactory);
    session.set_cancel_flag(opts.cancel);
    session.set_cancel_cause(opts.cancelCause);
    report_command_progress(info.role + ": starting");
    if (opts.onRunStart) opts.onRunStart(info);
    SessionResult r = session.run(info.task);
    if (opts.onRunEnd) opts.onRunEnd(info, r.ok, r.finalText, r.ok ? std::string() : r.error);
    return r;
}

AiRunInfo next_run_info(const std::string& role, const std::string& task) {
    static std::atomic<int> nextRun{1};
    AiRunInfo info;
    info.id = "run-" + std::to_string(nextRun.fetch_add(1));
    info.role = role;
    info.task = task;
    return info;
}

Json review_json(const Review& r, bool withText) {
    Json sub = Json::object();
    for (const auto& [k, v] : r.subScores) sub[k] = v;
    Json j = Json::object({{"id", r.id},
                           {"path", r.path},
                           {"role", r.role},
                           {"persona", r.persona},
                           {"time", r.time},
                           {"engineVersion", r.engineVersion},
                           {"gameVersion", r.gameVersion},
                           {"model", r.model},
                           {"score", r.score < 0 ? Json(nullptr) : Json(r.score)},
                           {"subScores", sub},
                           {"summary", r.summary}});
    if (withText) j["text"] = r.text;
    return j;
}

}  // namespace

void register_ai_commands(CommandRegistry& registry, AiCommandOptions options) {
    auto opts = std::make_shared<AiCommandOptions>(std::move(options));
    auto load = [opts]() -> Result<AiConfig> {
        if (opts->loadConfig) return opts->loadConfig();
        return load_config();
    };
    auto project_dir = [opts]() -> std::string {
        if (opts->projectDir) return opts->projectDir();
        return fs::project_root().string();
    };

    {
        CommandInfo info;
        info.name = "ai.providers";
        info.category = "ai";
        info.summary = "List configured AI providers and roles, or diagnose which ones are usable (doctor).";
        info.description =
            "action \"list\" (default) shows providers and the role mapping from ~/.factoria/ai.json. action \"doctor\" "
            "also checks for CLIs (claude, codex, ant) and API keys (never printed). `assets` maps each kind of asset "
            "(image, sound, music, voice, model3d) to the provider that generates it (assets.generate_* commands). Example: "
            "{\"action\":\"doctor\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "action":{"type":"string","enum":["list","doctor"],"default":"list","description":"list or doctor."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, project_dir, opts](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const bool doctor = str(args, "action", "list") == "doctor";
            if (doctor) {
                std::string dir = project_dir();
                if (!dir.empty()) for (const auto& w : scan_project_for_keys(dir, 500)) cfg->warnings.push_back(w);
            }
            DetectOptions dopt;
            dopt.probeVersions = doctor;
            auto status = detect_providers(*cfg, dopt);
            Json providers = Json::array();
            for (const auto& s : status) providers.push_back(s.to_json());
            Json roles = Json::object();
            for (const auto& [name, r] : cfg->roles) {
                roles[name] = Json::object({{"provider", r.provider}, {"model", r.model}, {"effort", r.effort}, {"enabled", r.enabled}});
                if (r.maxContextTokens > 0) roles[name]["maxContextTokens"] = r.maxContextTokens;
                if (r.toolGroups) roles[name]["toolGroups"] = *r.toolGroups;
            }
            Json assets = Json::object();
            for (const auto& [kind, r] : cfg->assets) {
                assets[kind] = Json::object({{"provider", r.provider}, {"model", r.model}, {"voice", r.voice}});
            }
            Json out = Json::object({{"configPath", cfg->sourcePath.empty() ? default_config_path() : cfg->sourcePath},
                                     {"configFound", !cfg->sourcePath.empty()},
                                     {"providers", providers},
                                     {"roles", roles},
                                     {"assets", assets},
                                     {"warnings", cfg->warnings}});
            Json toolServers = Json::array();
            for (const auto& t : tool_server_statuses(*cfg, opts->runtime.env)) toolServers.push_back(t.to_json());
            out["toolServers"] = toolServers;
            if (doctor) out["report"] = format_doctor_report(*cfg, status, opts->runtime.env, project_dir());
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "ai.tool_servers";
        info.category = "ai";
        info.summary = "List the external tool servers (MCP) the user configured in ai.json, and optionally test them.";
        info.description =
            "The user's \"mcpServers\" (docs/AI_PROVIDERS.md, External tools): services such as Scenario (game art) or local "
            "programs whose tools the AI may call. Each entry has name, type (http|stdio), target (URL without its query, or "
            "program), enabled, roles (who gets it), usesKey, keySource (where the key was found, never the key), problem (what "
            "is missing, \"\" when ready) and note. With test:true each enabled, ready server is contacted (initialize + "
            "tools/list; no tool is called, nothing is spent) and gets `connected`, `server` (how it introduced itself), `tools` "
            "[{name, description}] or `error` + `hint`. Keys are never returned. `name` limits the call to one server. "
            "Example: {\"test\":true,\"name\":\"scenario\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "test":{"type":"boolean","default":false,"description":"Connect to each server and list its tools."},
            "name":{"type":"string","description":"Only this server (a name from the list)."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, opts](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string only = str(args, "name");
            if (!only.empty() && !std::any_of(cfg->toolServers.begin(), cfg->toolServers.end(),
                                              [&](const ToolServer& s) { return s.name == only; })) {
                std::vector<std::string> known;
                for (const auto& s : cfg->toolServers) known.push_back(s.name);
                throw CommandError("unknown_tool_server", "No tool server named '" + only + "'",
                                   known.empty() ? "ai.json has no \"mcpServers\" yet (docs/AI_PROVIDERS.md, External tools)."
                                                 : fa::did_you_mean(only, known));
            }
            const bool test = flag(args, "test", false);
            Json servers = Json::array();
            for (const auto& st : tool_server_statuses(*cfg, opts->runtime.env)) {
                if (!only.empty() && st.name != only) continue;
                const ToolServer* server = nullptr;
                for (const auto& s : cfg->toolServers) if (s.name == st.name) server = &s;
                Json entry = st.to_json();
                entry["note"] = server->note;
                if (test) {
                    if (!st.enabled) {
                        entry["connected"] = false;
                        entry["error"] = "The server is turned off (enabled false).";
                    } else if (!st.problem.empty()) {
                        entry["connected"] = false;
                        entry["error"] = st.problem;
                    } else {
                        auto resolved = resolve_tool_server(*server, opts->runtime.env);
                        McpOptions mo;
                        mo.transport = opts->runtime.transport;
                        mo.cancel = opts->cancel;
                        auto client = McpClient::connect(*resolved, mo);
                        if (client) {
                            entry["connected"] = true;
                            entry["server"] = (*client)->server_description();
                            Json tools = Json::array();
                            for (const auto& t : (*client)->tools()) {
                                tools.push_back(Json::object({{"name", t.name}, {"description", t.description}}));
                            }
                            entry["tools"] = tools;
                        } else {
                            entry["connected"] = false;
                            entry["error"] = client.error().message;
                            if (!client.error().hint.empty()) entry["hint"] = client.error().hint;
                        }
                    }
                }
                servers.push_back(std::move(entry));
            }
            return Json::object({{"servers", servers}, {"configured", cfg->toolServers.size()}});
        });
    }
    {
        CommandInfo info;
        info.name = "ai.extensions";
        info.category = "ai";
        info.summary = "Show the extensions (plugins, skills, hooks) AI runs load, per role, and what stops one from loading.";
        info.description =
            "The user's \"extensions\" in ai.json plus the project's .factoria/extensions.json (docs/AI_PROVIDERS.md, Extensions). "
            "Returns {inheritUserPlugins, projectFile:{path, exists, hash, trusted, error}, entries:[{kind plugin|skill|hooks, name, "
            "source user|project, enabled, roles, target (the folder it resolves to), problem + fix when it cannot load, trusted for "
            "a project's plugin or hooks}], roles:{<role>:{provider, providerKind, receives:[{kind, name, source}], "
            "skipped:[{kind, name, source, reason, fix}], notes, userPluginsOff, projectSettingsSkipped}}, "
            "claudeSettings:{files:[{path, exists, needsTrust, grants (what in the file runs a program or widens what the AI may do: "
            "hooks, enabledPlugins, statusLine, env, permissions.allow, defaultMode...)}], needsTrust, trusted, loadedByClaudeCode, "
            "message + fix when a file needs trust and the project is not trusted: Claude Code then runs without them}, denyRules:[{file, rule, tool, fix}] (rules in the "
            "project's .claude/settings*.json that remove FactorIA's own tools from Claude Code), scope}. Claude Code uses plugins, "
            "skills and hooks; Codex uses skills only; a generic CLI uses plugins and hooks when its argv has {plugin_dirs} / {settings}; "
            "the API providers (anthropic, openai-compatible) do not use extensions yet. A plugin or hook that comes from a project loads only after the USER "
            "trusts the project in the editor (AI settings > Extensions); no command can grant that. Read-only. Example: "
            "{\"role\":\"worker\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "role":{"type":"string","description":"Only this role (orchestrator, worker, fast, artist, audio, artCritic, reviewer). Omit for all."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, project_dir, opts](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string role = str(args, "role");
            if (!role.empty() && !is_known_role(role)) {
                const std::vector<std::string> names(std::begin(kAllRoles), std::end(kAllRoles));
                throw CommandError("unknown_role", "No role named '" + role + "'", fa::did_you_mean(role, names));
            }
            ExtensionContext ctx = make_extension_context(*cfg, project_dir(), opts->runtime.env);
            Json out = extensions_report(*cfg, ctx, role);
            out["configPath"] = cfg->sourcePath.empty() ? default_config_path(opts->runtime.env ? opts->runtime.env : system_env()) : cfg->sourcePath;
            return out;
        });
    }
    {
        SkillsCommandOptions so;
        so.loadConfig = load;
        so.projectDir = project_dir;
        so.env = opts->runtime.env;
        register_skills_commands(registry, std::move(so));
    }
    {
        CommandInfo info;
        info.name = "ai.models";
        info.category = "ai";
        info.summary = "List the models each AI provider offers (the values for roles.<role>.model).";
        info.description =
            "Asks the providers themselves, so newly released models show up: Claude Code through its CLI (aliases such as "
            "opus first, then full names; no model call, no usage), the Anthropic API and OpenAI-compatible APIs through "
            "GET /models. Codex and generic CLIs cannot list their models: their entry has an error. Without `provider` "
            "it lists every provider that ai.providers reports available; one provider's failure is in its own entry "
            "(error, hint) and does not fail the call. Returns {providers:[{name, models:[{id, name, description, resolved}], "
            "error?, hint?}]}: id is the value for roles.<role>.model, name the display name (empty when the provider gives "
            "none), description one line, resolved the model an alias stands for (empty for a full name). "
            "Example: {\"provider\":\"claude-code\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "provider":{"type":"string","description":"Only this provider (a name from ai.providers). Omit for every available one."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, opts](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            std::vector<std::string> names;
            if (const std::string only = str(args, "provider"); !only.empty()) {
                if (!cfg->provider(only)) {
                    std::vector<std::string> known;
                    for (const auto& [name, _] : cfg->providers) known.push_back(name);
                    throw CommandError("unknown_provider", "No provider named '" + only + "'", fa::did_you_mean(only, known));
                }
                names.push_back(only);
            } else {
                DetectOptions dopt;
                dopt.probeVersions = false;
                dopt.env = opts->runtime.env;
                for (const auto& s : detect_providers(*cfg, dopt)) {
                    if (s.available && !is_asset_only_kind(cfg->provider(s.name)->kind)) names.push_back(s.name);
                }
            }
            Json providers = Json::array();
            for (const auto& name : names) {
                Json entry = Json::object({{"name", name}, {"models", Json::array()}});
                if (auto models = list_models(*cfg->provider(name), opts->runtime)) {
                    for (const ModelInfo& m : *models) {
                        entry["models"].push_back(Json::object(
                            {{"id", m.id}, {"name", m.name}, {"description", m.description}, {"resolved", m.resolved}}));
                    }
                } else {
                    entry["error"] = models.error().message;
                    if (!models.error().hint.empty()) entry["hint"] = models.error().hint;
                }
                providers.push_back(std::move(entry));
            }
            return Json::object({{"providers", providers}});
        });
    }
    {
        CommandInfo info;
        info.name = "ai.run";
        info.category = "ai";
        info.summary = "Run an AI agent on a task in the current project (blocks until it finishes).";
        info.description =
            "Uses the provider/model mapped to `role` in ~/.factoria/ai.json (default orchestrator). CLI providers "
            "(claude-code, codex) run their own loop with the FactorIA MCP server attached; API providers run the built-in "
            "tool loop. An orchestrator that is itself a CLI agent delegates with this tool: role \"worker\" (code), "
            "\"fast\" (small edits), \"artist\" (all the art) or \"audio\" (all the sound) and a self-contained task; the "
            "result's finalText is the sub-agent's report. The roles artCritic and reviewer are refused here: only the user "
            "asks for reviews (ai.review). A role the user turned off (roles.<role>.enabled false in ai.json) is refused "
            "too (error role_off): do that work yourself. Example: "
            "{\"task\":\"Add a pause menu\",\"role\":\"orchestrator\",\"maxCostUsd\":2}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "task":{"type":"string","description":"What the agent should do."},
            "role":{"type":"string","enum":["orchestrator","worker","fast","artist","audio"],"default":"orchestrator"},
            "provider":{"type":"string","description":"Override the role's provider (e.g. claude-code, codex, openrouter)."},
            "model":{"type":"string","description":"Override the role's model."},
            "maxTurns":{"type":"integer","minimum":1},
            "maxCostUsd":{"type":"number","minimum":0},
            "stream":{"type":"boolean","default":true}},
            "required":["task"],"additionalProperties":false})");
        info.readOnly = false;
        registry.add(std::move(info), [load, opts, project_dir, &registry](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            SessionOptions so;
            so.projectDir = project_dir();
            so.role = str(args, "role", kRoleOrchestrator);
            if (is_review_role(so.role)) {
                throw CommandError("not_delegable", "Role '" + so.role + "' cannot be started with ai.run: critics and reviewers run only when the user asks",
                                   "The user asks for a review with the editor's review buttons or `factoria ai review " +
                                       review_kind_for_role(so.role) + "` (ai.review). Use role worker, fast, artist or audio.");
            }
            if (!is_known_role(so.role)) {
                throw CommandError("unknown_role", "No role named '" + so.role + "'", fa::did_you_mean(so.role, std::vector<std::string>{"orchestrator", "worker", "fast", "artist", "audio"}));
            }
            if (!cfg->role_enabled(so.role)) throw CommandError("role_off", role_off_message(so.role), role_off_hint(so.role));
            so.providerOverride = str(args, "provider");
            so.modelOverride = str(args, "model");
            so.maxTurns = static_cast<int>(num(args, "maxTurns"));
            if (args.contains("maxCostUsd")) so.maxCostUsd = num(args, "maxCostUsd");
            so.stream = flag(args, "stream", true);
            for (const auto& w : scan_project_for_keys(so.projectDir, 500)) cfg->warnings.push_back(w);
            const AiRunInfo info = next_run_info(so.role, str(args, "task"));
            SessionResult r = run_agent_session(registry, *cfg, so, info, *opts);
            Json out = r.to_json();
            out["warnings"] = cfg->warnings;
            if (!r.ok) {
                throw CommandError(r.stopReason.empty() ? "failed" : r.stopReason, r.error.empty() ? "agent run failed" : r.error,
                                   r.hint);
            }
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "ai.review";
        info.category = "ai";
        info.summary = "Ask the art critics (kind art) or the game reviewers (kind game) for their opinion and a score (blocks until done).";
        info.description =
            "Starts `count` read-only AI reviewers (1 to 5, one after the other, each with a different persona; the first is "
            "always the all-rounder, so the score of one reviewer stays comparable over time). They play the current build "
            "(REVIEW.md first), never change the project, and write a report with a score from 0 to 10 and sub-scores. Each "
            "review is saved in <project>/.factoria/ai/reviews/ and returned: {reviews:[{id, path, persona, score, subScores, "
            "summary, text}], averageScore, costUsd, errors}. Only a person asks for reviews: the orchestrator is told not to call "
            "this. The roles artCritic and reviewer of ~/.factoria/ai.json choose the models. Example: "
            "{\"kind\":\"game\",\"count\":3,\"focus\":\"the first five minutes\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "kind":{"type":"string","enum":["art","game"],"description":"art: the art critics (role artCritic). game: the game reviewers (role reviewer)."},
            "count":{"type":"integer","minimum":1,"maximum":5,"default":1,"description":"How many critics or reviewers, each with a different persona."},
            "focus":{"type":"string","description":"Something to pay special attention to (optional), e.g. \"the UI\" or \"the boss fight\"."},
            "provider":{"type":"string","description":"Override the role's provider."},
            "model":{"type":"string","description":"Override the role's model."},
            "maxTurns":{"type":"integer","minimum":1},
            "maxCostUsd":{"type":"number","minimum":0,"description":"Cost limit of each review."},
            "stream":{"type":"boolean","default":true}},
            "required":["kind"],"additionalProperties":false})");
        info.readOnly = false;  // it spends money and writes the review files
        registry.add(std::move(info), [load, opts, project_dir, &registry](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string kind = str(args, "kind");
            const std::string role = review_role_for_kind(kind);
            if (role.empty()) throw CommandError("invalid_arguments", "kind must be \"art\" or \"game\", got '" + kind + "'", "");
            const std::string dir = project_dir();
            if (dir.empty()) throw CommandError("no_project", "A review needs a project to play", "Open a project (or pass --project).");
            const int count = std::clamp(static_cast<int>(num(args, "count", 1)), 1, kMaxReviewers);
            const std::string focus = str(args, "focus");
            const auto& personas = review_personas(role);
            const RoleConfig rc = cfg->effective_role(role);
            Json reviews = Json::array(), errors = Json::array();
            double total = 0, scoreSum = 0, cost = 0;
            int scored = 0;
            for (int i = 0; i < count; ++i) {
                if (opts->cancel && opts->cancel->load()) {
                    errors.push_back("stopped before reviewer " + std::to_string(i + 1));
                    break;
                }
                SessionOptions so;
                so.projectDir = dir;
                so.role = role;
                so.providerOverride = str(args, "provider");
                so.modelOverride = str(args, "model");
                so.maxTurns = static_cast<int>(num(args, "maxTurns"));
                if (args.contains("maxCostUsd")) so.maxCostUsd = num(args, "maxCostUsd");
                so.stream = flag(args, "stream", true);
                so.allowDelegation = false;
                so.extraSystem = persona_prompt(personas[static_cast<std::size_t>(i)], i, count);
                const AiRunInfo info = next_run_info(role, review_task(role, focus));
                SessionResult r = run_agent_session(registry, *cfg, so, info, *opts);
                cost += r.costUsd;
                if (!r.ok || trim(r.finalText).empty()) {
                    errors.push_back(personas[static_cast<std::size_t>(i)].name + ": " +
                                     (r.ok ? std::string("the reviewer wrote no report") : (r.error.empty() ? r.stopReason : r.error)));
                    continue;
                }
                const ParsedReport parsed = parse_review_report(r.finalText);
                Review review;
                review.role = role;
                review.persona = personas[static_cast<std::size_t>(i)].name;
                review.provider = so.providerOverride.empty() ? rc.provider : so.providerOverride;
                review.model = so.modelOverride.empty() ? rc.model : so.modelOverride;
                review.focus = focus;
                review.text = parsed.text;
                review.summary = parsed.summary;
                review.score = parsed.score;
                review.subScores = parsed.subScores;
                review.costUsd = r.costUsd;
                auto saved = save_review(dir, review);
                if (saved) review = *saved;
                else errors.push_back(review.persona + ": the review could not be saved: " + saved.error().message);
                reviews.push_back(review_json(review, true));  // returned to the caller even when it could not be saved
                if (review.score >= 0) {
                    scoreSum += review.score;
                    ++scored;
                }
            }
            total = static_cast<double>(reviews.size());
            if (total == 0) {
                throw CommandError("review_failed", errors.empty() ? "no review was written" : errors.front().get<std::string>(),
                                   "Check `factoria ai providers` for the role '" + role + "' and try again.");
            }
            Json out = Json::object({{"kind", kind}, {"role", role}, {"reviews", reviews}, {"errors", errors}, {"costUsd", cost}});
            out["averageScore"] = scored > 0 ? Json(scoreSum / scored) : Json(nullptr);
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "ai.review_feedback";
        info.category = "ai";
        info.summary = "Check an ENGINE_FEEDBACK.json entry's `share` text before it can be shared: a real gap, about the engine, not possible yet.";
        info.description =
            "Run this after feedback.report when you wrote a `share` text (a person also gets it as \"Review with AI\" in the Engine "
            "Feedback panel). A cheap model checks the entry against the engine's command list and documentation: (1) the gap is real, "
            "(2) it is about the engine and not about the game, (3) the engine cannot already do it. The text also goes through the "
            "automatic sanitizer, which refuses anything with names, paths or quotes from the game. On a PASS the entry is marked "
            "reviewed: true and, if the text needed it, `share` is rewritten in engine terms (components, fields, commands and API "
            "names only; nothing about the game). On a FAIL nothing is changed: you get `reasons` (which check failed and why) and `fix`, "
            "what to change (rewrite the share text, use what the engine already has, or drop `share`). The model is the \"fast\" "
            "role of ai.json, the cheapest one (the orchestrator when fast is off; docs/AI_PROVIDERS.md). The result is "
            "{id, pass, checks:{real, aboutEngine, notPossibleYet, sanitizer}, reasons, fix, rewritten, reviewed, share, role}. "
            "This command never changes the sharing mode and never sends anything: only a person decides whether entries leave the "
            "machine. Example: {\"id\":\"FB-0003\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "id":{"type":"string","description":"The entry to review, e.g. FB-0003 (feedback.list shows the ids). It needs a `share` text."}},
            "required":["id"],"additionalProperties":false})");
        info.readOnly = false;  // marks the entry reviewed and may rewrite its `share`; spends tokens
        registry.add(std::move(info), [load, opts, project_dir, &registry](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string dir = project_dir();
            if (dir.empty()) throw CommandError("no_project", "Reviewing feedback needs a project", "Open a project (or pass --project).");
            return review_feedback_entry(registry, *cfg, *opts, dir, str(args, "id"));
        });
    }
    {
        CommandInfo info;
        info.name = "ai.reviews";
        info.category = "ai";
        info.summary = "List the saved reviews of the art critics and the game reviewers, newest first, with their scores.";
        info.description =
            "Reads <project>/.factoria/ai/reviews/. Each entry has id, path, role, persona, time, engineVersion, gameVersion, "
            "score (0 to 10, null when none), subScores and summary; `text` (the report) only with includeText. Use it to see "
            "how the score changes between builds. Example: {\"kind\":\"game\",\"limit\":10}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "kind":{"type":"string","enum":["art","game"],"description":"Only the art critiques or only the game reviews. Omit for both."},
            "limit":{"type":"integer","minimum":1,"description":"At most this many (newest first)."},
            "includeText":{"type":"boolean","default":false,"description":"Include each report's full text."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [project_dir](const Json& args) -> Json {
            const std::string kind = str(args, "kind");
            const std::string role = kind.empty() ? std::string() : review_role_for_kind(kind);
            if (!kind.empty() && role.empty()) throw CommandError("invalid_arguments", "kind must be \"art\" or \"game\", got '" + kind + "'", "");
            const bool withText = flag(args, "includeText", false);
            Json out = Json::array();
            for (const Review& r : list_reviews(project_dir(), role, static_cast<std::size_t>(num(args, "limit")))) {
                out.push_back(review_json(r, withText));
            }
            return Json::object({{"reviews", out}});
        });
    }
    {
        CommandInfo info;
        info.name = "ai.session_timeline";
        info.category = "ai";
        info.summary = "Show where the time of a recorded AI session went: the long gaps and what was going on in each.";
        info.description =
            "Reads one transcript of <project>/.factoria/ai/sessions/ (every event has \"t\", the UTC time with ms; tool_end has "
            "\"ms\", the duration of the tool; thinking has \"ms\", how long the model thought, also when its text is hidden). "
            "Returns `gaps`: each pause of at least minGapSeconds with start, end, seconds, activity (tool, thinking, model = "
            "waiting for the model, user = waiting for the user) and detail (the tool's name...), and `totals` per activity with "
            "the tools sorted by time. A session recorded before events carried times gives hasTimes false and a note. "
            "`context` splits what each model call carried (built-in agent only): per step the system prompt, the tool "
            "definitions and the conversation, in bytes and estimated tokens, plus how many commands were tools and how many "
            "only catalog lines, and the totals of the run. Example: {\"minGapSeconds\":60}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "session":{"type":"string","description":"File name of the session (20261014-153012-orchestrator or with .jsonl) in .factoria/ai/sessions. Omit for the newest."},
            "minGapSeconds":{"type":"number","minimum":0,"default":30,"description":"List only the gaps at least this long (seconds). Totals always count every gap."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [project_dir](const Json& args) -> Json {
            auto r = session_timeline(project_dir(), str(args, "session"), args.contains("minGapSeconds") ? num(args, "minGapSeconds") : 30.0);
            if (!r) throw CommandError("not_found", r.error().message, r.error().hint);
            return *r;
        });
    }
    {
        CommandInfo info;
        info.name = "ai.tool_plan";
        info.category = "ai";
        info.summary = "Show which commands the built-in AI agent of a role gets as tools in full and which only as catalog lines.";
        info.description =
            "The built-in agent (API providers) does not send every command's definition on every step: it gets the core commands "
            "(files, docs, scene, running the game, validating, scripts) and the tool groups of the role (ai.json "
            "roles.<role>.toolGroups, default: artist assets, audio assets and audio) in full, plus tool_describe and tool_call, "
            "and lists the other commands in its system prompt. Returns `tools` (name and estimated bytes of each tool sent), "
            "`catalogCommands`, the estimated `toolBytes`/`toolTokens` against `fullBytes`/`fullTokens` (every command in full), "
            "`groups` (the tool groups loaded), `notes` (a group that matches nothing, with suggestions) and `categories` "
            "(per category: commands, inCatalog, inFull). CLI agents (claude-code...) choose their own "
            "tools; this plan is what the API providers get. Example: {\"role\":\"artist\",\"catalog\":true}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "role":{"type":"string","default":"orchestrator","description":"Role to plan for: orchestrator, worker, fast, artist, audio, artCritic, reviewer."},
            "catalog":{"type":"boolean","default":false,"description":"Also list every catalog command (command, category, summary)."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [load, &registry](const Json& args) -> Json {
            auto cfg = load();
            if (!cfg) throw CommandError("invalid_config", cfg.error().message, cfg.error().hint);
            const std::string role = str(args, "role", kRoleOrchestrator);
            auto roleIt = cfg->roles.find(role);
            if (roleIt == cfg->roles.end()) {
                std::vector<std::string> names;
                for (const auto& [n, _] : cfg->roles) names.push_back(n);
                throw CommandError("unknown_role", "No role named '" + role + "'", fa::did_you_mean(role, names));
            }
            ToolPlanOptions po;
            po.withDelegate = role == kRoleOrchestrator && cfg->can_delegate_to_anyone();
            po.readOnly = is_review_role(role);
            po.groups = roleIt->second.toolGroups ? *roleIt->second.toolGroups : default_tool_groups(role);
            const ToolPlan plan = plan_tools(registry, po);
            Json tools = Json::array();
            for (const ToolDef& t : plan.tools) {
                tools.push_back(Json::object({{"name", t.name},
                                              {"bytes", t.name.size() + t.description.size() + dump(t.inputSchema).size() + 60}}));
            }
            std::map<std::string, int> total, inCatalog;
            for (const CommandInfo* info : registry.list()) {
                if (is_agent_tool_excluded(info->name) || (po.readOnly && !is_read_only_tool(*info))) continue;
                ++total[info->category];
            }
            for (const CatalogEntry& e : plan.catalog) ++inCatalog[e.category];
            Json categories = Json::object();
            for (const auto& [cat, n] : total) {
                categories[cat] = Json::object({{"commands", n}, {"inCatalog", inCatalog[cat]}, {"inFull", n - inCatalog[cat]}});
            }
            Json out = Json::object({{"role", role},
                                     {"useCatalog", plan.useCatalog},
                                     {"tools", tools},
                                     {"toolCount", plan.tools.size()},
                                     {"toolBytes", plan.toolBytes},
                                     {"toolTokens", estimate_tokens(plan.toolBytes)},
                                     {"catalogCommands", plan.catalog.size()},
                                     {"catalogBytes", plan.catalogText.size()},
                                     {"catalogTokens", estimate_tokens(plan.catalogText.size())},
                                     {"fullBytes", plan.fullBytes},
                                     {"fullTokens", estimate_tokens(plan.fullBytes)},
                                     {"groups", plan.loadedGroups},
                                     {"notes", plan.notes},
                                     {"categories", categories}});
            if (flag(args, "catalog", false)) {
                Json catalog = Json::array();
                for (const CatalogEntry& e : plan.catalog) {
                    catalog.push_back(Json::object({{"command", e.command}, {"category", e.category}, {"summary", e.summary}}));
                }
                out["catalog"] = catalog;
            }
            return out;
        });
    }
    register_asset_commands(registry, load, project_dir, opts->runtime, opts->cancel);
}

}  // namespace fa::ai
