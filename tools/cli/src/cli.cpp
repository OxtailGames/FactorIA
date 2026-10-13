#include "fa/cli/cli.h"

#include <iostream>
#include <sstream>

#include "common.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"

#ifndef FA_ENGINE_VERSION
#define FA_ENGINE_VERSION "0.0.0"
#endif

namespace fa::cli {

namespace {

Command make_version_command() {
    Command c;
    c.name = "version";
    c.summary = "Print the engine version.";
    c.flags = {{"json", "", "Machine-readable output."}};
    c.examples = {"factoria version", "factoria --version"};
    c.run = [](Context& ctx) {
        bool editor = false;
#ifdef FA_WITH_EDITOR
        editor = true;
#endif
        if (ctx.args.has("json")) {
            print_json(ctx.out, Json::object({{"name", "factoria"}, {"version", FA_ENGINE_VERSION}, {"editor", editor}}));
            return 0;
        }
        ctx.out << "factoria " << FA_ENGINE_VERSION << "\n";
        return 0;
    };
    return c;
}

std::vector<Command> build_commands() {
    std::vector<Command> v;
    v.push_back(make_new_command());
    v.push_back(make_templates_command());
    v.push_back(make_run_command());
    v.push_back(make_screenshot_command());
    v.push_back(make_test_command());
    v.push_back(make_validate_command());
    v.push_back(make_call_command());
    v.push_back(make_session_command());
    v.push_back(make_commands_command());
    v.push_back(make_api_command());
    v.push_back(make_mcp_command());
    v.push_back(make_ai_command());
    v.push_back(make_feedback_command());
    v.push_back(make_docs_command());
    v.push_back(make_editor_command());
    v.push_back(make_export_command());
    v.push_back(make_version_command());
    return v;
}

std::string top_help(const std::vector<Command>& cmds) {
    std::ostringstream o;
    o << "factoria " << FA_ENGINE_VERSION << " - the FactorIA developer tool (create, run, test, MCP server, AI agent)\n\n"
      << "Usage:\n  factoria <command> [options]\n\nCommands:\n"
      << format_command_list(cmds)
      << "  help       Show help for a command (factoria help run)\n"
      << "\nTypical AI workflow:\n"
      << "  factoria new my-game && cd my-game\n"
      << "  factoria validate && factoria test\n"
      << "  factoria run --headless --frames 120 --screenshot-at 60 --json\n"
      << "  factoria mcp                         # expose everything to an MCP client\n"
      << "\nEvery command has --help with examples. Exit codes: 0 ok, 1 failure, 2 usage error.\n";
    return o.str();
}

std::vector<std::string> names_of(const std::vector<Command>& cmds) {
    std::vector<std::string> n;
    for (const auto& c : cmds)
        if (!c.hidden) n.push_back(c.name);
    n.push_back("help");
    return n;
}

int usage_error(std::ostream& err, const std::string& path, const UsageError& e) {
    err << "error: " << e.what() << "\n";
    if (!e.hint.empty()) err << "  hint: " << e.hint << "\n";
    if (!path.empty()) err << "Run 'factoria " << path << " --help' for usage and examples.\n";
    return 2;
}

}  // namespace

int cli_main(const std::vector<std::string>& args, std::ostream& out, std::ostream& err, std::istream& in) {
    static const std::vector<Command> commands = build_commands();
    if (args.empty()) {
        out << top_help(commands);
        return 0;
    }
    const std::string& first = args[0];
    if (first == "--version" || first == "-V") {
        out << "factoria " << FA_ENGINE_VERSION << "\n";
        return 0;
    }
    if (first == "--help" || first == "-h") {
        out << top_help(commands);
        return 0;
    }

    std::vector<std::string> rest(args.begin() + 1, args.end());
    const bool isHelp = first == "help";
    if (isHelp) {
        if (rest.empty()) {
            out << top_help(commands);
            return 0;
        }
    }
    const std::string wanted = isHelp ? rest[0] : first;
    if (isHelp) rest.erase(rest.begin());

    const Command* cmd = nullptr;
    for (const auto& c : commands)
        if (c.name == wanted) cmd = &c;
    if (!cmd) {
        err << "error: unknown command '" << wanted << "'.\n  hint: " << did_you_mean(wanted, names_of(commands)) << "\nRun 'factoria help' for the list.\n";
        return 2;
    }
    std::string path = cmd->name;

    // Descend into subcommands.
    while (!cmd->subs.empty() && !rest.empty() && rest[0].rfind("-", 0) != 0) {
        const Command* sub = nullptr;
        for (const auto& s : cmd->subs)
            if (s.name == rest[0]) sub = &s;
        if (!sub) {
            if (cmd->run && !isHelp) break;  // group with a default action (docs <name>)
            std::vector<std::string> names;
            for (const auto& s : cmd->subs) names.push_back(s.name);
            err << "error: unknown subcommand '" << rest[0] << "' for 'factoria " << path << "'.\n  hint: " << did_you_mean(rest[0], names) << "\n";
            return 2;
        }
        cmd = sub;
        path += " " + sub->name;
        rest.erase(rest.begin());
    }

    try {
        bool help = false;
        Args parsed = parse_args(*cmd, rest, path, help);
        if (help || isHelp) {
            out << format_help(*cmd, path);
            return 0;
        }
        if (!cmd->run) {
            err << "error: 'factoria " << path << "' needs a subcommand.\n\n" << format_help(*cmd, path);
            return 2;
        }
        LogLevel level = LogLevel::Warn;
        if (parsed.has("log-level") && !parse_log_level(parsed.str("log-level"), level))
            throw UsageError("Unknown log level '" + parsed.str("log-level") + "'.", "Valid: trace, debug, info, warn, error.");
        set_log_level(level);
        Context ctx{out, err, in, std::move(parsed), cmd, path};
        return cmd->run(ctx);
    } catch (const UsageError& e) {
        return usage_error(err, path, e);
    } catch (const CliError& e) {
        return report_failure(err, e.what(), e.hint);
    } catch (const std::exception& e) {
        return report_failure(err, std::string("internal error: ") + e.what(),
                              "This is a bug in factoria; please report it with 'factoria feedback add --category tooling ...'.");
    }
}

int cli_main(const std::vector<std::string>& args, std::ostream& out, std::ostream& err) {
    return cli_main(args, out, err, std::cin);
}

}  // namespace fa::cli
