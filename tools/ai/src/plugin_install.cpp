#include "fa/ai/plugin_install.h"

#include <algorithm>
#include <cctype>
#include <set>

#include "fa/ai/cli_agent.h"
#include "fa/ai/extensions.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;

PluginInstallRequest token_economizer_request() {
    PluginInstallRequest r;
    r.marketplace = "microsoft/TokenEconomizer";
    r.plugin = "tokeneconomizer@tokeneconomizer";
    r.entryName = "tokeneconomizer";
    r.requiresPython = "3.10";
    r.note = "TokenEconomizer: micro-skills learned per repository, tool pruning, a failure-loop guard";
    return r;
}

namespace {

std::vector<int> version_parts(const std::string& v) {
    std::vector<int> out;
    std::size_t i = 0;
    while (i < v.size() && !std::isdigit(static_cast<unsigned char>(v[i]))) ++i;
    while (i < v.size() && out.size() < 3) {
        int n = 0;
        bool any = false;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) {
            n = n * 10 + (v[i] - '0');
            any = true;
            ++i;
        }
        if (!any) break;
        out.push_back(n);
        if (i < v.size() && v[i] == '.') ++i;
        else break;
    }
    return out;
}

std::string clip(std::string s, std::size_t max = 600) {
    s = std::string(fa::trim(s));
    if (s.size() > max) s = s.substr(0, max) + "...";
    return s;
}

std::string join_argv(const std::vector<std::string>& argv) {
    std::string out;
    for (const std::string& a : argv) out += (out.empty() ? "" : " ") + (a.find(' ') != std::string::npos ? "\"" + a + "\"" : a);
    return out;
}

// Every string value of a JSON document.
void collect_strings(const Json& j, std::vector<std::string>& out) {
    if (j.is_string()) out.push_back(j.get<std::string>());
    else if (j.is_array()) for (const Json& c : j) collect_strings(c, out);
    else if (j.is_object()) for (auto it = j.begin(); it != j.end(); ++it) collect_strings(it.value(), out);
}

// Does `output` of a `list` command name `needle`? JSON when the CLI gave JSON (a string equal to it, or a GitHub/git URL that
// ends in it), else the plain text of the listing.
bool listing_has(const std::string& output, const std::vector<std::string>& needles) {
    const Json j = parse(output);
    for (std::string needle : needles) {
        needle = lower(needle);
        if (needle.size() < 3) continue;
        if (!j.is_discarded() && (j.is_array() || j.is_object())) {
            std::vector<std::string> strings;
            collect_strings(j, strings);
            for (std::string s : strings) {
                s = lower(s);
                if (s.ends_with(".git")) s.resize(s.size() - 4);
                if (s == needle || (s.size() > needle.size() && s.ends_with("/" + needle))) return true;
            }
        } else if (lower(output).find(needle) != std::string::npos) {
            return true;
        }
    }
    return false;
}

struct CliRun {
    bool started = false;
    bool ok = false;
    int exitCode = -1;
    bool timedOut = false, cancelled = false;
    std::string out, err;
    std::string startError, startHint;
};

CliRun run_cli(const ProcessOptions& base, const std::vector<std::string>& args, const PluginInstallHooks& hooks, double timeoutSeconds) {
    ProcessOptions po = base;
    for (const std::string& a : args) po.argv.push_back(a);
    po.timeoutSeconds = timeoutSeconds;
    po.cancel = hooks.cancel;
    po.stdinText.clear();
    CliRun r;
    auto pr = run_process(po);
    if (!pr) {
        r.startError = pr.error().message;
        r.startHint = pr.error().hint;
        return r;
    }
    r.started = true;
    r.exitCode = pr->exitCode;
    r.timedOut = pr->timedOut;
    r.cancelled = pr->cancelled;
    r.out = pr->stdoutText;
    r.err = pr->stderrText;
    r.ok = pr->exitCode == 0 && !pr->timedOut && !pr->cancelled;
    return r;
}

// `<cli> plugin <what> list --json`, falling back to the plain listing for a CLI without --json.
Result<std::string> list_output(const ProcessOptions& base, std::vector<std::string> args, const std::string& what,
                                const PluginInstallHooks& hooks, const std::string& updateHint) {
    args.push_back("--json");
    CliRun r = run_cli(base, args, hooks, 60);
    if (!r.started) return make_error("Could not start the Claude Code CLI to list " + what + ": " + r.startError, r.startHint);
    if (r.cancelled) return make_error("Cancelled while listing " + what, "Start it again when you are ready.");
    if (!r.ok) {
        args.pop_back();
        r = run_cli(base, args, hooks, 60);
        if (r.cancelled) return make_error("Cancelled while listing " + what, "Start it again when you are ready.");
    }
    if (!r.ok) {
        return make_error("`" + join_argv(args) + "` failed (" + (r.timedOut ? "no answer in 60 s" : "exit code " + std::to_string(r.exitCode)) +
                              "): " + clip(r.err.empty() ? r.out : r.err, 300),
                          updateHint);
    }
    return r.out + "\n" + r.err;
}

struct PythonCheck {
    std::string command, version, message;
    bool ok = false;
};

PythonCheck check_python(const std::string& minimum, const PluginInstallHooks& hooks) {
    PythonCheck pc;
    std::vector<std::string> candidates = hooks.pythonCommands;
    if (candidates.empty()) {
#ifdef _WIN32
        candidates = {"python", "python3", "py"};
#else
        candidates = {"python3", "python"};
#endif
    }
    std::string seen;
    for (const std::string& c : candidates) {
        ProcessOptions po;
        po.argv = {c, "--version"};
        po.timeoutSeconds = 15;
        po.cancel = hooks.cancel;
        auto pr = run_process(po);
        if (!pr || pr->exitCode != 0) continue;
        const std::string text = std::string(fa::trim(pr->stdoutText + " " + pr->stderrText));
        const auto at = text.find("Python ");
        if (at == std::string::npos) continue;
        std::string v = text.substr(at + 7);
        v = v.substr(0, v.find_first_of(" \r\n\t"));
        if (pc.version.empty()) {
            pc.command = c;
            pc.version = v;
        }
        if (python_version_at_least(v, minimum)) {
            pc.command = c;
            pc.version = v;
            pc.ok = true;
            pc.message = "Python " + v + " (" + c + ")";
            return pc;
        }
    }
    if (pc.version.empty()) {
        pc.message = "Python " + minimum + " or newer was not found (tried " + join_argv(candidates) + ")";
    } else {
        pc.message = "Python " + pc.version + " (" + pc.command + ") is older than the " + minimum + " it needs";
    }
    return pc;
}

std::string entry_name_from(const PluginInstallRequest& r) {
    std::string name = r.entryName;
    if (name.empty()) name = r.plugin.substr(0, r.plugin.find('@'));
    std::string out;
    for (char c : name) out += (std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-') ? c : '-';
    if (out.empty()) out = "plugin";
    return out.substr(0, kMaxExtensionName);
}

Json step_json(const std::string& id, const std::vector<std::string>& command, bool needed, const std::string& status,
               const std::string& detail) {
    Json cmd = Json::array();
    for (const std::string& a : command) cmd.push_back(a);
    return Json::object({{"id", id}, {"command", cmd}, {"needed", needed}, {"status", status}, {"detail", detail}});
}

}  // namespace

bool python_version_at_least(const std::string& version, const std::string& minimum) {
    const auto v = version_parts(version), m = version_parts(minimum);
    if (v.empty() || m.empty()) return false;
    for (std::size_t i = 0; i < m.size(); ++i) {
        const int have = i < v.size() ? v[i] : 0;
        if (have != m[i]) return have > m[i];
    }
    return true;
}

Result<Json> plugin_install(const AiConfig& cfg, const PluginInstallRequest& req, const PluginInstallHooks& hooks) {
    if (fa::trim(req.marketplace).empty() || fa::trim(req.plugin).empty()) {
        return make_error("A plugin install needs a marketplace and a plugin",
                          "Example: marketplace \"microsoft/TokenEconomizer\", plugin \"tokeneconomizer@tokeneconomizer\".");
    }
    const auto at = req.plugin.find('@');
    if (at == std::string::npos || at == 0 || at + 1 == req.plugin.size()) {
        return make_error("The plugin '" + req.plugin + "' is not name@marketplace",
                          "Claude Code names a marketplace plugin name@marketplace, e.g. tokeneconomizer@tokeneconomizer.");
    }
    const std::string marketplaceName = req.plugin.substr(at + 1);

    // The provider whose executable runs the plugin commands.
    const ProviderConfig* provider = cfg.provider("claude-code");
    if (!provider || provider->kind != ProviderKind::ClaudeCode) {
        provider = nullptr;
        for (const auto& [name, p] : cfg.providers)
            if (p.kind == ProviderKind::ClaudeCode) {
                provider = &p;
                break;
            }
    }
    if (!provider) {
        return make_error("No claude-code provider is configured",
                          "Plugins are a Claude Code feature. Add a provider of kind \"claude-code\" to ai.json (docs/AI_PROVIDERS.md), or install "
                          "Claude Code (npm i -g @anthropic-ai/claude-code).");
    }
    auto base = cli_process_options(*provider);
    if (!base) return base.error();
    const std::string exe = base->argv.front();
    const std::string updateHint = "Update Claude Code (npm i -g @anthropic-ai/claude-code): older versions have no `claude plugin` commands.";

    // What the entry needs.
    std::string configPath = req.configPath.empty() ? cfg.sourcePath : req.configPath;
    if (configPath.empty()) configPath = default_config_path();
    const auto sameEntry = [&](const Extension& e) { return e.kind == ExtensionKind::Plugin && !e.from_project() && lower(e.plugin) == lower(req.plugin); };
    const bool entryPresent = std::ranges::any_of(cfg.extensions.entries, sameEntry);
    std::string entryName = entry_name_from(req);
    if (!entryPresent) {
        const auto taken = [&](const std::string& n) {
            return std::ranges::any_of(cfg.extensions.entries, [&](const Extension& e) { return e.kind == ExtensionKind::Plugin && e.name == n; });
        };
        std::string base2 = entryName;
        for (int n = 2; taken(entryName); ++n) entryName = base2.substr(0, kMaxExtensionName - 4) + "-" + std::to_string(n);
    } else {
        for (const Extension& e : cfg.extensions.entries)
            if (sameEntry(e)) entryName = e.name;
    }

    // The entry is checked before anything is installed: a bad role must not leave a plugin without its entry.
    Extension newEntry;
    if (!entryPresent) {
        Json body = Json::object({{"plugin", req.plugin}});
        if (!req.note.empty()) body["note"] = req.note;
        if (!req.roles.empty()) body["roles"] = req.roles;
        auto parsed = parse_extensions(Json::object({{"plugins", Json::object({{entryName, body}})}}), "the plugin entry", "user");
        if (!parsed) return make_error("The ai.json entry is not valid: " + parsed.error().message + " Nothing was installed.", parsed.error().hint);
        newEntry = parsed->entries.front();
    }

    // What the CLI already has.
    auto marketplaces = list_output(*base, {"plugin", "marketplace", "list"}, "the marketplaces", hooks, updateHint);
    if (!marketplaces) return marketplaces.error();
    auto plugins = list_output(*base, {"plugin", "list"}, "the installed plugins", hooks, updateHint);
    if (!plugins) return plugins.error();
    const bool marketplaceListed = listing_has(*marketplaces, {req.marketplace, marketplaceName});
    const bool pluginInstalled = listing_has(*plugins, {req.plugin});

    const std::vector<std::string> addCmd = {exe, "plugin", "marketplace", "add", req.marketplace};
    const std::vector<std::string> installCmd = {exe, "plugin", "install", req.plugin};
    const bool needMarketplace = !marketplaceListed && !pluginInstalled;
    const bool needPlugin = !pluginInstalled;

    PythonCheck py;
    const bool wantPython = !req.requiresPython.empty() && (needMarketplace || needPlugin || req.dryRun);
    if (wantPython) py = check_python(req.requiresPython, hooks);

    Json steps = Json::array();
    const auto emit = [&](Json step) {
        if (hooks.onStep) hooks.onStep(step);
        if (step.value("status", "") != "running") steps.push_back(std::move(step));
    };

    Json report = Json::object({{"dryRun", req.dryRun},
                                {"provider", provider->name},
                                {"command", exe},
                                {"marketplace", req.marketplace},
                                {"plugin", req.plugin},
                                {"configPath", configPath}});
    report["python"] = Json::object({{"required", req.requiresPython},
                                     {"command", py.command},
                                     {"version", py.version},
                                     {"ok", req.requiresPython.empty() || !wantPython ? true : py.ok},
                                     {"message", py.message}});

    if (req.dryRun) {
        emit(step_json("marketplace", addCmd, needMarketplace, needMarketplace ? "would_run" : "not_needed",
                       needMarketplace ? "The marketplace is not listed by `claude plugin marketplace list`."
                                       : (pluginInstalled ? "The plugin is already installed, so its marketplace is not needed again."
                                                          : "The marketplace is already listed.")));
        emit(step_json("plugin", installCmd, needPlugin, needPlugin ? "would_run" : "not_needed",
                       needPlugin ? "The plugin is not listed by `claude plugin list`." : "The plugin is already installed."));
        emit(step_json("entry", {}, !entryPresent, !entryPresent ? "would_run" : "not_needed",
                       !entryPresent ? "Adds plugin '" + entryName + "' (" + req.plugin + ") to " + configPath + "."
                                     : "ai.json already has the entry '" + entryName + "'."));
        report["steps"] = steps;
        report["entry"] = Json::object({{"name", entryName}, {"added", false}, {"present", entryPresent}, {"path", configPath}});
        const bool pythonBlocks = wantPython && !py.ok && (needMarketplace || needPlugin);
        report["ok"] = !pythonBlocks;
        report["message"] = pythonBlocks ? py.message + ". Install Python " + req.requiresPython + " or newer first."
                                         : "Dry run: nothing was changed.";
        return report;
    }

    if (wantPython && !py.ok && (needMarketplace || needPlugin)) {
#ifdef _WIN32
        const char* pythonName = "python";
#else
        const char* pythonName = "python3";
#endif
        return make_error(py.message + ", and " + req.plugin + " needs it",
                          "Install Python " + req.requiresPython + " or newer (python.org, or your package manager) so that `" + pythonName +
                              " --version` prints it, then try again. Nothing was installed.");
    }

    // The failure message carries the steps that already ran: the caller sees where it stopped.
    std::string done;
    const auto fail = [&](const std::string& what, const CliRun& r, const std::vector<std::string>& cmd) -> Error {
        std::string why = !r.started ? r.startError
                          : r.cancelled ? "it was cancelled"
                          : r.timedOut  ? "it did not finish in time"
                                        : "exit code " + std::to_string(r.exitCode) + ": " + clip(r.err.empty() ? r.out : r.err, 400);
        return make_error(what + " failed (" + why + ")" + (done.empty() ? "" : ". Done before: " + done),
                          "Run `" + join_argv(cmd) + "` in a terminal to see the whole output. A failed install changes nothing in ai.json. " +
                              (r.started ? "" : r.startHint));
    };

    const auto run_step = [&](const std::string& id, const std::string& what, const std::vector<std::string>& cmd, bool needed,
                              const std::string& skipReason, double timeout) -> Result<bool> {
        if (!needed) {
            emit(step_json(id, cmd, false, "skipped", skipReason));
            return false;
        }
        if (hooks.onStep) hooks.onStep(step_json(id, cmd, true, "running", what));
        std::vector<std::string> args(cmd.begin() + 1, cmd.end());
        CliRun r = run_cli(*base, args, hooks, timeout);
        if (!r.ok) {
            emit(step_json(id, cmd, true, "failed", clip(r.err.empty() ? r.out : r.err, 300)));
            return fail(what, r, cmd);
        }
        emit(step_json(id, cmd, true, "done", clip(r.out.empty() ? r.err : r.out, 300)));
        done += (done.empty() ? "" : ", ") + what;
        return true;
    };

    if (auto r = run_step("marketplace", "adding the marketplace " + req.marketplace, addCmd, needMarketplace,
                          pluginInstalled ? "The plugin is already installed." : "The marketplace is already listed.", 300);
        !r)
        return r.error();
    if (auto r = run_step("plugin", "installing " + req.plugin, installCmd, needPlugin, "The plugin is already installed.", 300); !r)
        return r.error();

    // The ai.json entry.
    bool added = false;
    if (entryPresent) {
        emit(step_json("entry", {}, false, "skipped", "ai.json already has the entry '" + entryName + "'."));
    } else {
        if (hooks.onStep) hooks.onStep(step_json("entry", {}, true, "running", "adding the entry to ai.json"));
        ExtensionsConfig next = cfg.extensions;
        next.entries.push_back(newEntry);
        // Plugins come before skills and hooks in the file.
        std::stable_sort(next.entries.begin(), next.entries.end(),
                         [](const Extension& a, const Extension& b) { return static_cast<int>(a.kind) < static_cast<int>(b.kind); });
        if (auto saved = save_extensions(next, configPath); !saved) {
            emit(step_json("entry", {}, true, "failed", saved.error().message));
            return make_error("The plugin is installed but ai.json could not be written: " + saved.error().message,
                              saved.error().hint + " Add it by hand, or fix the file and call ai.plugin_install again: the installed steps are skipped.");
        }
        added = true;
        emit(step_json("entry", {}, true, "done", "Added '" + entryName + "' to " + configPath + "."));
    }
    report["steps"] = steps;
    report["entry"] = Json::object({{"name", entryName}, {"added", added}, {"present", true}, {"path", configPath}});
    report["ok"] = true;
    report["message"] = std::string(added ? "Added the entry '" + entryName + "'. " : "") + req.plugin +
                        " is installed. The next AI run with Claude Code loads it for the roles of the entry.";
    return report;
}

}  // namespace fa::ai
