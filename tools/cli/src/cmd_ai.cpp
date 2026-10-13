// ai doctor | providers | config | run
#include <filesystem>
#include <fstream>
#include <iostream>

#include "common.h"
#include "fa/ai/config.h"
#include "fa/ai/detect.h"
#include "fa/ai/session.h"
#include "fa/core/strings.h"
#include "fa/tooling/validate.h"

namespace fa::cli {

namespace fsys = std::filesystem;

namespace {

ai::AiConfig load_config_or_throw() {
    auto cfg = ai::load_config();
    if (!cfg.ok()) throw CliError("AI configuration is invalid: " + cfg.error().message, cfg.error().hint);
    return *cfg;
}

Json roles_json(const ai::AiConfig& cfg) {
    Json roles = Json::object();
    for (const char* r : {ai::kRoleOrchestrator, ai::kRoleWorker, ai::kRoleFast}) {
        ai::RoleConfig rc = cfg.role(r);
        roles[r] = Json::object({{"provider", rc.provider}, {"model", rc.model}, {"effort", rc.effort}});
    }
    return roles;
}

Json providers_report(const ai::AiConfig& cfg, bool probe) {
    ai::DetectOptions dopt;
    dopt.probeVersions = probe;
    Json providers = Json::array();
    for (const auto& s : ai::detect_providers(cfg, dopt)) providers.push_back(s.to_json());
    Json warnings = Json::array();
    for (const auto& w : cfg.warnings) warnings.push_back(w);
    return Json::object({{"configPath", ai::default_config_path()},
                         {"configLoadedFrom", cfg.sourcePath},
                         {"defaultProvider", cfg.defaultProvider},
                         {"roles", roles_json(cfg)},
                         {"providers", providers},
                         {"warnings", warnings}});
}

std::string clip(std::string s, std::size_t n) {
    for (char& c : s)
        if (c == '\n' || c == '\r') c = ' ';
    if (s.size() > n) s = s.substr(0, n - 3) + "...";
    return s;
}

}  // namespace

Command make_ai_command() {
    Command g;
    g.name = "ai";
    g.summary = "The built-in AI agent: check providers, configure, and run a task on a project.";
    g.details = "Providers: API keys (Anthropic, OpenAI-compatible) or your Claude Code / Codex subscription via their CLIs.\nSee docs: factoria docs read ai-providers";
    g.maxPositional = -1;

    Command doctor;
    doctor.name = "doctor";
    doctor.summary = "Check which AI providers are usable (CLIs installed, keys visible). Never prints keys.";
    doctor.flags = {{"json", "", "Machine-readable output."}};
    doctor.examples = {"factoria ai doctor", "factoria ai doctor --json"};
    doctor.run = [](Context& ctx) {
        ai::AiConfig cfg = load_config_or_throw();
        if (ctx.args.has("json")) {
            print_json(ctx.out, providers_report(cfg, true));
            return 0;
        }
        ctx.out << ai::format_doctor_report(cfg, ai::detect_providers(cfg));
        return 0;
    };

    Command providers;
    providers.name = "providers";
    providers.summary = "List the configured providers, their availability and the role mapping.";
    providers.flags = {{"json", "", "Machine-readable output."}};
    providers.examples = {"factoria ai providers --json"};
    providers.run = [](Context& ctx) {
        ai::AiConfig cfg = load_config_or_throw();
        Json rep = providers_report(cfg, false);
        if (ctx.args.has("json")) {
            print_json(ctx.out, rep);
            return 0;
        }
        ctx.out << "roles:\n";
        for (const auto& [role, v] : rep["roles"].items())
            ctx.out << "  " << role << ": " << v["provider"].get<std::string>() << " / " << v["model"].get<std::string>() << "\n";
        ctx.out << "providers:\n";
        for (const auto& p : rep["providers"])
            ctx.out << "  " << (p.value("available", false) ? "[ok]   " : "[none] ") << p.value("name", std::string()) << "  (" << p.value("kind", std::string())
                    << ")  " << p.value("detail", std::string()) << "\n";
        return 0;
    };

    Command config;
    config.name = "config";
    config.summary = "Show where the AI config lives, the effective settings (keys redacted) and an example.";
    config.flags = {{"json", "", "Machine-readable output."}};
    config.examples = {"factoria ai config"};
    config.run = [](Context& ctx) {
        ai::AiConfig cfg = load_config_or_throw();
        std::string path = ai::default_config_path();
        std::error_code ec;
        bool exists = fsys::exists(path, ec);
        const char* example = R"({
  "defaultProvider": "anthropic",
  "providers": {
    "openrouter": { "type": "openai-compatible", "preset": "openrouter", "apiKeyEnv": "OPENROUTER_API_KEY" }
  },
  "roles": {
    "orchestrator": { "provider": "claude-code", "model": "opus" },
    "worker":       { "provider": "anthropic",   "model": "claude-sonnet-5-5" },
    "fast":         { "provider": "anthropic",   "model": "claude-haiku-4-5" }
  },
  "limits": { "maxTurns": 40, "maxCostUsd": 5 }
})";
        if (ctx.args.has("json")) {
            print_json(ctx.out, Json::object({{"path", path}, {"exists", exists}, {"effective", ai::config_to_json(cfg, true)},
                                              {"example", Json::parse(example)}}));
            return 0;
        }
        ctx.out << "Config file: " << path << (exists ? "" : "  (does not exist yet; defaults are used)") << "\n"
                << "Override the location with FACTORIA_AI_CONFIG. API keys come from environment variables\n"
                << "(ANTHROPIC_API_KEY, OPENAI_API_KEY, ...) or this user file, never from a game project.\n"
                << "Schema: schemas/ai-config.schema.json (factoria docs read ai-providers)\n\nExample:\n" << example << "\n";
        return 0;
    };

    Command run;
    run.name = "run";
    run.summary = "Give the AI agent a task on a project; it works through the engine commands (and sub-agents).";
    run.usage = "[project] \"<task>\" [--provider P] [--role R] [--model M] [--max-turns N]";
    run.details =
        "The agent sees the project's tools (scene.*, game.*, fs.*, feedback.report, ...). Text, tool calls and costs stream\n"
        "to the terminal; the transcript is saved in <project>/.factoria/ai/sessions/. Use '-' as task to read stdin,\n"
        "@file to read the task from a file. Exit code 1 if the run did not finish normally.";
    run.maxPositional = 2;
    run.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
                 {"provider", "NAME", "Use this provider instead of the role's (see 'factoria ai providers')."},
                 {"role", "ROLE", "orchestrator (default), worker or fast."},
                 {"model", "MODEL", "Model override."},
                 {"max-turns", "N", "Turn limit (default from config limits)."},
                 {"max-cost", "USD", "Cost limit in USD (0 = unlimited)."},
                 {"no-delegate", "", "Do not let the orchestrator spawn worker sub-agents."},
                 {"no-transcript", "", "Do not save a transcript."},
                 {"json", "", "Emit one JSON object per event, then the final result."}};
    run.examples = {"factoria ai run \"add a double jump and a test for it\"",
                    "factoria ai run games/my-game \"make the enemy patrol\" --role worker --max-turns 20",
                    "factoria ai run --provider claude-code \"fix the failing tests\""};
    run.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Missing task.", "Usage: factoria ai run [project] \"<task>\"");
        std::string task = a.positional().back();
        std::string projectArg = a.positional().size() == 2 ? a.pos(0) : "";
        if (task == "-") {
            task.assign(std::istreambuf_iterator<char>(ctx.in), std::istreambuf_iterator<char>());
        } else if (!task.empty() && task[0] == '@') {
            std::ifstream f(task.substr(1), std::ios::binary);
            if (!f) throw UsageError("Cannot read task file '" + task.substr(1) + "'.");
            task.assign(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
        }
        if (trim(task).empty()) throw UsageError("The task is empty.");

        std::string role = a.str("role", ai::kRoleOrchestrator);
        if (role != ai::kRoleOrchestrator && role != ai::kRoleWorker && role != ai::kRoleFast)
            throw UsageError("Unknown role '" + role + "'.", "Valid roles: orchestrator, worker, fast.");
        ai::AiConfig cfg = load_config_or_throw();
        std::string provider = a.str("provider");
        if (!provider.empty() && !cfg.provider(provider)) {
            std::vector<std::string> names;
            for (const auto& [n, _] : cfg.providers) names.push_back(n);
            throw UsageError("Unknown provider '" + provider + "'.", fa::did_you_mean(provider, names));
        }

        std::string dir;
        if (!projectArg.empty()) {
            std::string abs = absolute_path(projectArg);
            if (!fsys::exists(fsys::path(abs) / kProjectFileName))
                throw CliError("'" + abs + "' is not a FactorIA project: " + kProjectFileName + " not found.");
            dir = abs;
        } else {
            dir = resolve_project_dir(ctx, 99);
        }

        SessionOptions so;
        so.gfx = Gfx::Auto;
        auto session = Session::open(dir, so);
        register_cli_commands(session->registry(), dir, &session->engine());

        ai::SessionOptions ao;
        ao.projectDir = dir;
        ao.role = role;
        ao.providerOverride = provider;
        ao.modelOverride = a.str("model");
        ao.maxTurns = a.integer("max-turns", 0);
        if (a.has("max-cost")) ao.maxCostUsd = a.number("max-cost", 0);
        ao.allowDelegation = !a.has("no-delegate");
        ao.saveTranscript = !a.has("no-transcript");

        const bool asJson = a.has("json");
        bool midLine = false;
        auto handler = [&](const ai::AgentEvent& e) {
            using T = ai::AgentEvent::Type;
            if (asJson) {
                Json j = Json::object({{"event", ai::event_type_name(e.type)}, {"depth", e.depth}, {"role", e.role}});
                if (!e.text.empty()) j["text"] = e.text;
                if (!e.toolName.empty()) j["tool"] = e.toolName;
                if (!e.toolInput.is_null()) j["input"] = e.toolInput;
                if (!e.toolResult.is_null()) j["result"] = clip(e.toolResult.dump(), 2000);
                if (e.isError) j["isError"] = true;
                if (e.type == T::Usage || e.type == T::Done) j["costUsd"] = e.costUsd;
                ctx.out << j.dump() << "\n";
                ctx.out.flush();
                return;
            }
            std::string pad(static_cast<std::size_t>(e.depth) * 2, ' ');
            auto endLine = [&]() {
                if (midLine) ctx.out << "\n";
                midLine = false;
            };
            switch (e.type) {
                case T::SessionStart: endLine(); ctx.out << pad << "[" << e.role << "] " << e.text << "\n"; break;
                case T::TextDelta: ctx.out << e.text; midLine = !e.text.empty() && e.text.back() != '\n'; break;
                case T::ToolStart: endLine(); ctx.out << pad << "> " << e.toolName << " " << clip(e.toolInput.dump(), 160) << "\n"; break;
                case T::ToolEnd: endLine(); ctx.out << pad << "  " << (e.isError ? "ERROR " : "ok    ") << clip(e.toolResult.dump(), 160) << "\n"; break;
                case T::Info: endLine(); ctx.out << pad << "[info] " << e.text << "\n"; break;
                case T::Error: endLine(); ctx.out << pad << "[error] " << e.text << "\n"; break;
                default: break;
            }
            ctx.out.flush();
        };

        ai::AgentSession agent(session->registry(), cfg, ao);
        agent.set_event_handler(handler);
        ai::SessionResult res = agent.run(task);
        if (midLine) ctx.out << "\n";
        if (asJson) {
            print_json(ctx.out, res.to_json());
            return res.ok ? 0 : 1;
        }
        ctx.out << "\n--- " << (res.ok ? "done" : "stopped") << ": " << res.stopReason << ", " << res.turns << " turns, " << res.usage.total()
                << " tokens";
        if (res.costUsd > 0) ctx.out << ", ~$" << res.costUsd;
        ctx.out << "\n";
        if (!res.transcriptPath.empty()) ctx.out << "transcript: " << res.transcriptPath << "\n";
        if (!res.ok) return report_failure(ctx.err, res.error.empty() ? "The agent stopped: " + res.stopReason : res.error, res.hint);
        return 0;
    };

    g.subs = {doctor, providers, config, run};
    return g;
}

}  // namespace fa::cli
