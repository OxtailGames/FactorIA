#include "fa/ai/commands.h"

#include <algorithm>
#include <atomic>
#include <memory>

#include "asset_commands.h"
#include "fa/ai/detect.h"
#include "fa/ai/review.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
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
        registry.add(std::move(info), [load, project_dir](const Json& args) -> Json {
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
            if (doctor) out["report"] = format_doctor_report(*cfg, status);
            return out;
        });
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
    register_asset_commands(registry, load, project_dir, opts->runtime, opts->cancel);
}

}  // namespace fa::ai
