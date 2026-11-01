// Installing a Claude Code marketplace plugin for the user ("ai.plugin_install", the editor's Add TokenEconomizer button):
// runs the Claude Code CLI's own `plugin marketplace add` and `plugin install`, skips a step that is already done, then adds
// a `plugin` entry to the user's ai.json "extensions". docs/AI_PROVIDERS.md, "Installing a plugin".
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/ai/config.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"

namespace fa::ai {

struct PluginInstallRequest {
    std::string marketplace;   // what `claude plugin marketplace add` takes: "owner/repo", a git URL or a path
    std::string plugin;        // "name@marketplace" as `claude plugin install` takes it
    std::vector<std::string> roles;  // roles of the ai.json entry; empty = the default roles
    std::string entryName;     // the entry's key in "extensions.plugins"; empty = the plugin's name
    std::string note;          // the entry's note
    std::string requiresPython;  // "3.10": the plugin needs this Python or newer; empty = none
    bool dryRun = false;       // report the commands and which are needed; run nothing that changes anything
    // Where ai.json is written. Empty: the loaded config's file, else default_config_path().
    std::string configPath;
};

struct PluginInstallHooks {
    const CancelFlag* cancel = nullptr;
    // Called when a step starts (status "running") and when it ends ("done", "skipped", "failed", "would_run", "not_needed").
    // Same fields as the entries of the result's "steps". Runs on the calling thread.
    std::function<void(const Json& step)> onStep;
    // Test hooks: the Python programs to try (default python3 then python; python then python3 on Windows).
    std::vector<std::string> pythonCommands;
};

// The TokenEconomizer preset (https://github.com/microsoft/TokenEconomizer): what the editor's button installs.
PluginInstallRequest token_economizer_request();

// "3.10.4" -> true when it is at least "3.10". False when either does not parse.
bool python_version_at_least(const std::string& version, const std::string& minimum);

// Runs (or, with dryRun, plans) the install with the configured claude-code provider's executable. Result:
// {ok, dryRun, provider, command, marketplace, plugin, python:{required, command, version, ok, message}, 
//  steps:[{id: marketplace|plugin|entry, command: [argv] | "", needed, status, detail}], entry:{name, added, path}, message}.
// An Error names the step that failed, what the CLI said and how to fix it; the steps before it are in the message.
Result<Json> plugin_install(const AiConfig& cfg, const PluginInstallRequest& request, const PluginInstallHooks& hooks = {});

}  // namespace fa::ai
