// hooks run: a JavaScript hook module run as a hook program (docs/HOOKS.md, "JavaScript hooks").
#include <iostream>
#include <iterator>

#include "common.h"
#include "fa/ai/hook_js.h"
#include "fa/ai/hooks.h"
#include "fa/core/strings.h"

namespace fa::cli {

Command make_hooks_command() {
    Command g;
    g.name = "hooks";
    g.summary = "Run a JavaScript hook module of the project as a hook program (what Claude Code starts for a \"js\" hook).";
    g.details =
        "FactorIA runs the \"js\" hooks of its own loop in-process. Claude Code only starts programs, so the per-run settings\n"
        "file it is given names this command for every \"js\" handler. See: factoria docs read hooks";
    g.maxPositional = -1;

    Command run;
    run.name = "run";
    run.summary = "Read a hook event as JSON on stdin, call the module's handler and print its answer as JSON on stdout.";
    run.usage = "<module> [--project DIR] [--event NAME] [--timeout SECONDS]";
    run.details =
        "<module> is a .js file inside the project's hooks/ folder. stdin is the JSON a hook program receives (its\n"
        "hook_event_name field picks the handler unless --event is given). The handler's return value is printed as the\n"
        "hook's JSON answer (exit 0), console output goes to stderr. A module that fails exits 1 with the reason on stderr\n"
        "(a non-blocking error for Claude Code).";
    run.maxPositional = 1;
    run.flags = {{"project", "DIR", "Project folder (default: the one containing the current directory)."},
                 {"event", "NAME", "Event name, when stdin does not carry hook_event_name."},
                 {"timeout", "SECONDS", "Time limit of the module (default 60)."}};
    run.examples = {"echo '{\"hook_event_name\":\"PreToolUse\",\"tool_name\":\"Bash\"}' | factoria hooks run hooks/guard.js"};
    run.run = [](Context& ctx) {
        const Args& a = ctx.args;
        if (a.positional().empty()) throw UsageError("Missing module.", "Usage: factoria hooks run hooks/<module>.js --project DIR");
        const std::string module = a.positional()[0];
        const std::string problem = ai::hook_module_problem(module);
        if (!problem.empty()) return report_failure(ctx, problem, "Hook modules live in the project's hooks/ folder.");
        const std::string dir = resolve_project_dir(ctx, 99);
        std::string text((std::istreambuf_iterator<char>(ctx.in)), std::istreambuf_iterator<char>());
        Json input = text.empty() ? Json::object() : Json::parse(text, nullptr, false);
        if (!input.is_object())
            return report_failure(ctx, "stdin is not a JSON object.", "A hook program receives the event as a JSON object on stdin.");
        std::string eventName = a.has("event") ? a.str("event") : std::string();
        if (eventName.empty() && input.contains("hook_event_name") && input["hook_event_name"].is_string())
            eventName = input["hook_event_name"].get<std::string>();
        const auto event = ai::parse_hook_event(eventName);
        if (!event) {
            return report_failure(ctx, "Unknown hook event '" + eventName + "'.",
                                  "Give the event as hook_event_name in the stdin JSON or with --event. Events: " +
                                      join(ai::engine_hook_event_names(), ", ") + ".");
        }
        const double timeout = a.has("timeout") ? std::stod(a.str("timeout")) : ai::kDefaultHookTimeoutSeconds;
        const ai::JsHookResult res = ai::run_js_hook(dir, module, *event, input, timeout);
        for (const std::string& line : res.logs) ctx.err << line << "\n";
        if (!res.ok) return report_failure(ctx, res.error, "Fix the module, or run `factoria call ai.hooks_test` to try it.");
        if (res.handled && !res.value.is_null()) ctx.out << res.value.dump() << "\n";
        return 0;
    };
    g.subs = {run};
    return g;
}

}  // namespace fa::cli
