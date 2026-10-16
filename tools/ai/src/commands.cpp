#include "fa/ai/commands.h"

#include <memory>

#include "asset_commands.h"
#include "fa/ai/detect.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;

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
                roles[name] = Json::object({{"provider", r.provider}, {"model", r.model}, {"effort", r.effort}});
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
            "tool loop. An orchestrator that is itself a CLI agent delegates with this tool: role \"worker\" or \"fast\" "
            "and a self-contained task; the result's finalText is the sub-agent's report. Example: "
            "{\"task\":\"Add a pause menu\",\"role\":\"orchestrator\",\"maxCostUsd\":2}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "task":{"type":"string","description":"What the agent should do."},
            "role":{"type":"string","enum":["orchestrator","worker","fast"],"default":"orchestrator"},
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
            so.providerOverride = str(args, "provider");
            so.modelOverride = str(args, "model");
            so.maxTurns = static_cast<int>(num(args, "maxTurns"));
            if (args.contains("maxCostUsd")) so.maxCostUsd = num(args, "maxCostUsd");
            so.stream = flag(args, "stream", true);
            so.mcpUrl = opts->mcpUrl;
            for (const auto& w : scan_project_for_keys(so.projectDir, 500)) cfg->warnings.push_back(w);
            AgentSession session(registry, *cfg, so);
            if (opts->onEvent) session.set_event_handler(opts->onEvent);
            if (opts->providerFactory) session.set_provider_factory(opts->providerFactory);
            session.set_cancel_flag(opts->cancel);
            SessionResult r = session.run(str(args, "task"));
            Json out = r.to_json();
            out["warnings"] = cfg->warnings;
            if (!r.ok) {
                throw CommandError(r.stopReason.empty() ? "failed" : r.stopReason, r.error.empty() ? "agent run failed" : r.error,
                                   r.hint);
            }
            return out;
        });
    }
    register_asset_commands(registry, load, project_dir, opts->runtime, opts->cancel);
}

}  // namespace fa::ai
