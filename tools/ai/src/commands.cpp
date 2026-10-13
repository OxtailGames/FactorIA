#include "fa/ai/commands.h"

#include <memory>

#include "fa/ai/detect.h"
#include "fa/core/fs.h"
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
            "also checks for CLIs (claude, codex, ant) and API keys (never printed). Example: "
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
            }
            Json out = Json::object({{"configPath", cfg->sourcePath.empty() ? default_config_path() : cfg->sourcePath},
                                     {"configFound", !cfg->sourcePath.empty()},
                                     {"providers", providers},
                                     {"roles", roles},
                                     {"warnings", cfg->warnings}});
            if (doctor) out["report"] = format_doctor_report(*cfg, status);
            return out;
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
            "tool loop. Example: {\"task\":\"Add a pause menu\",\"role\":\"orchestrator\",\"maxCostUsd\":2}";
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
            for (const auto& w : scan_project_for_keys(so.projectDir, 500)) cfg->warnings.push_back(w);
            AgentSession session(registry, *cfg, so);
            if (opts->onEvent) session.set_event_handler(opts->onEvent);
            if (opts->providerFactory) session.set_provider_factory(opts->providerFactory);
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
}

}  // namespace fa::ai
