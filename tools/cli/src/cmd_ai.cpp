// ai doctor | providers | config | run
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>

#include "common.h"
#include "fa/ai/config.h"
#include "fa/ai/detect.h"
#include "fa/ai/progress_file.h"
#include "fa/ai/review.h"
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
    for (const char* r : ai::kAllRoles) {
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
    "fast":         { "provider": "anthropic",   "model": "claude-haiku-4-5" },
    "artist":       { "provider": "claude-code", "model": "opus", "effort": "high" }
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
                 {"role", "ROLE", "orchestrator (default), worker, fast, artist or audio. Critics and reviewers: factoria ai review."},
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
        if (ai::is_review_role(role))
            throw UsageError("The role '" + role + "' only runs as a review.",
                             "Use 'factoria ai review " + ai::review_kind_for_role(role) + "' (docs/AI_PROVIDERS.md, \"Reviews\").");
        if (role != ai::kRoleOrchestrator && !ai::is_delegable_role(role))
            throw UsageError("Unknown role '" + role + "'.",
                             "Valid roles: orchestrator, worker, fast, artist, audio (reviews: 'factoria ai review').");
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
        std::mutex outMu;  // the progress thread below prints too
        auto handler = [&](const ai::AgentEvent& e) {
            using T = ai::AgentEvent::Type;
            std::lock_guard<std::mutex> lock(outMu);
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
        ai::SessionResult res;
        {
            // A CLI orchestrator delegates with ai_run to `factoria mcp`, a process of its own: its sub-agents' steps come
            // through the project's progress file, and are printed here as "  | worker > running Bash (...)" lines so a
            // long delegation is not a silent terminal.
            ai::ProgressTail tail(dir, [&](const std::string& line) {
                std::lock_guard<std::mutex> lock(outMu);
                if (midLine) ctx.out << "\n";
                midLine = false;
                if (asJson) ctx.out << Json::object({{"event", "progress"}, {"text", line}}).dump() << "\n";
                else ctx.out << "  | " << line << "\n";
                ctx.out.flush();
            });
            res = agent.run(task);
        }
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
        if (!res.ok) return report_failure(ctx, res.error.empty() ? "The agent stopped: " + res.stopReason : res.error, res.hint);
        return 0;
    };

    Command review;
    review.name = "review";
    review.summary = "Ask for an art critique (kind art) or a game review (kind game): read-only agents play the build and score it.";
    review.usage = "art|game [project] [--count N] [--focus TEXT] [--provider P] [--model M] [--max-cost USD] [--json]";
    review.details =
        "Starts N critics (art, role artCritic) or reviewers (game, role reviewer), one after another, each with its own point\n"
        "of view. They can look and play (screenshots, game_step/input/click, bot play) but not change anything. Each report\n"
        "ends in a score from 0 to 10 with sub-scores and is saved in <project>/.factoria/ai/reviews/ (list them with\n"
        "'factoria ai reviews'). Reviews only run when you ask: no agent starts them. They read REVIEW.md first\n"
        "(docs/AI_PROVIDERS.md, \"Reviews\").";
    review.maxPositional = 2;
    review.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
                    {"count", "N", "How many reviewers (1 to 5, default 1), each with a different point of view."},
                    {"focus", "TEXT", "What to look at (default: everything), e.g. \"the shop screen\"."},
                    {"provider", "NAME", "Use this provider instead of the role's."},
                    {"model", "MODEL", "Model override."},
                    {"max-turns", "N", "Turn limit per reviewer."},
                    {"max-cost", "USD", "Cost limit in USD per reviewer (0 = unlimited)."},
                    {"json", "", "Print the result as JSON."}};
    review.examples = {"factoria ai review game", "factoria ai review art --count 3 --focus \"the main menu\""};
    review.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Missing kind.", "Usage: factoria ai review art|game [project]");
        const std::string kind = a.pos(0);
        if (kind != "art" && kind != "game")
            throw UsageError("Unknown kind '" + kind + "'.", "Valid kinds: art (art critic), game (game reviewer).");
        std::string projectArg = a.positional().size() == 2 ? a.pos(1) : "";
        std::string dir;
        if (!projectArg.empty()) {
            std::string abs = absolute_path(projectArg);
            if (!fsys::exists(fsys::path(abs) / kProjectFileName))
                throw CliError("'" + abs + "' is not a FactorIA project: " + kProjectFileName + " not found.");
            dir = abs;
        } else {
            dir = resolve_project_dir(ctx, 99);
        }
        Json args = Json::object({{"kind", kind}, {"count", a.integer("count", 1)}});
        if (a.has("focus")) args["focus"] = a.str("focus");
        if (a.has("provider")) args["provider"] = a.str("provider");
        if (a.has("model")) args["model"] = a.str("model");
        if (a.has("max-turns")) args["maxTurns"] = a.integer("max-turns", 0);
        if (a.has("max-cost")) args["maxCostUsd"] = a.number("max-cost", 0);

        SessionOptions so;
        so.gfx = Gfx::Auto;
        auto session = Session::open(dir, so);
        register_cli_commands(session->registry(), dir, &session->engine());
        CommandResult r = session->registry().call("ai.review", args);
        if (!r.ok) {
            return report_failure(ctx, r.error.value("message", std::string("The review failed.")),
                                  r.error.value("hint", std::string()));
        }
        if (a.has("json")) {
            print_json(ctx.out, r.result);
            return 0;
        }
        for (const Json& rv : r.result.value("reviews", Json::array())) {
            ctx.out << "=== " << rv.value("role", std::string()) << " (" << rv.value("persona", std::string()) << ")  score: ";
            if (rv.contains("score") && rv["score"].is_number()) ctx.out << rv["score"].get<double>() << "/10";
            else ctx.out << "none";
            ctx.out << " ===\n" << rv.value("text", std::string()) << "\n";
            if (!rv.value("path", std::string()).empty()) ctx.out << "saved: " << rv.value("path", std::string()) << "\n";
            ctx.out << "\n";
        }
        for (const Json& e : r.result.value("errors", Json::array())) ctx.out << "[error] " << e.get<std::string>() << "\n";
        if (r.result.contains("averageScore") && r.result["averageScore"].is_number())
            ctx.out << "average score: " << r.result["averageScore"].get<double>() << "/10\n";
        return 0;
    };

    Command reviews;
    reviews.name = "reviews";
    reviews.summary = "List the saved art critiques and game reviews with their scores, newest first.";
    reviews.usage = "[project] [--kind art|game] [--limit N] [--json]";
    reviews.maxPositional = 1;
    reviews.flags = {{"project", "DIR", "Project folder (alternative to the positional argument)."},
                     {"kind", "KIND", "Only art or game reviews."},
                     {"limit", "N", "At most N reviews (default 20)."},
                     {"json", "", "Machine-readable output (with the full text)."}};
    reviews.examples = {"factoria ai reviews", "factoria ai reviews --kind game --limit 5"};
    reviews.run = [](Context& ctx) {
        const Args& a = ctx.args;
        std::string dir = a.positional().empty() ? resolve_project_dir(ctx, 99) : absolute_path(a.pos(0));
        const std::string kind = a.str("kind");
        if (!kind.empty() && kind != "art" && kind != "game")
            throw UsageError("Unknown kind '" + kind + "'.", "Valid kinds: art, game.");
        const std::size_t limit = static_cast<std::size_t>(a.integer("limit", 20));
        const std::string role = kind.empty() ? std::string() : ai::review_role_for_kind(kind);
        std::vector<ai::Review> list = ai::list_reviews(dir, role, limit);
        if (a.has("json")) {
            Json out = Json::array();
            for (const ai::Review& r : list) out.push_back(r.to_json());
            print_json(ctx.out, Json::object({{"reviews", out}}));
            return 0;
        }
        if (list.empty()) {
            ctx.out << "No reviews yet. Ask for one with 'factoria ai review game' or 'factoria ai review art'.\n";
            return 0;
        }
        for (const ai::Review& r : list) {
            ctx.out << r.time << "  " << ai::review_kind_for_role(r.role) << "  ";
            if (r.score >= 0) ctx.out << r.score << "/10";
            else ctx.out << "  -  ";
            ctx.out << "  " << r.persona << "  v" << r.gameVersion << "  " << clip(r.summary, 80) << "\n";
        }
        return 0;
    };

    g.subs = {doctor, providers, config, run, review, reviews};
    return g;
}

}  // namespace fa::cli
