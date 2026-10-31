// What one run of one provider receives from the extensions (plugins, skills, hooks): the entries of the user's ai.json plus the
// project's .factoria/extensions.json, filtered by role, by what the provider can take and by the trust gate. The run
// (CliAgent) turns the plan into --plugin-dir / --settings arguments; `ai.extensions` and `factoria ai doctor` report it.
// docs/AI_PROVIDERS.md, "Extensions".
#pragma once

#include <string>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/extensions.h"

namespace fa::ai {

// What a provider can do with extensions.
struct ExtensionSupport {
    bool plugins = false;
    bool skills = false;
    bool hooks = false;
    bool inheritSetting = false;  // inheritUserPlugins: false can be applied (--setting-sources)
    // Why the unsupported parts are unsupported, in one sentence that also says what to do ("" when everything is supported).
    std::string reason;
    bool any() const { return plugins || skills || hooks; }
};
// Claude Code: plugins (--plugin-dir), skills (a plugin FactorIA writes for the run), hooks (--settings). Codex: nothing
// (FactorIA could not verify how it takes them). A generic CLI: plugins when its argv has {plugin_dirs}, hooks when it has
// {settings}. The API providers (anthropic, openai-compatible): nothing yet.
ExtensionSupport extension_support(const ProviderConfig& provider);

struct ExtensionContext {
    std::string projectDir;   // "" = no project (only the user's entries)
    ExtensionEnv env;         // HOME / CLAUDE_CONFIG_DIR lookups; null = the process environment
    std::string trustPath;    // ai-trust.json; "" = nothing is trusted
    bool dropStaleTrust = true;  // a trust record for a file that changed is removed (false for read-only reports)
};

// One entry as one run (or the report) sees it.
struct ExtensionItem {
    ExtensionKind kind = ExtensionKind::Plugin;
    std::string name;
    std::string source;  // "user" or "project"
    std::string target;  // the folder / zip it resolved to ("name@marketplace" -> its install folder); "" when it did not
    std::vector<std::string> dirs;  // plugin: the folder; skill: each skill folder found (one, or one per skill of a folder of skills)
    bool enabled = true;
    bool trusted = true;  // false: from a project, runs a program, and the project is not trusted
    std::string problem;  // why this entry cannot be loaded at all ("" when fine)
    std::string fix;      // how to fix `problem`
};

struct ExtensionPlan {
    std::string provider;
    ProviderKind providerKind = ProviderKind::Fake;
    std::string role;
    ExtensionSupport support;
    std::vector<std::string> pluginDirs;  // --plugin-dir / {plugin_dirs}
    std::vector<std::string> skillDirs;   // each skill folder; Claude Code gets them as one generated plugin
    Json hooks;                           // merged events object; null when there are none
    bool userPluginsOff = false;          // inheritUserPlugins false and the provider honours it
    // Claude Code only: the project's .claude/settings*.json runs a program and the project is not trusted, so the run starts
    // without the project and local setting sources. `untrustedSettings` says what would have run (ClaudeProjectSettings::describe).
    bool projectSettingsOff = false;
    std::vector<std::string> untrustedSettings;
    std::vector<ExtensionItem> received;  // entries the run loads
    std::vector<ExtensionItem> skipped;   // entries for this role the run does not load, each with problem + fix
    std::vector<std::string> notes;       // lines for the run output, in plain English
    std::vector<DeniedTool> denied;       // deny rules found for FactorIA's tools (Claude Code runs)

    bool empty() const { return pluginDirs.empty() && skillDirs.empty() && !hooks.is_object(); }
};

// Resolves one entry (paths, installed plugins, skill folders) without looking at the provider or the role. `trusted` says
// whether a program-running entry of a project may run. `projectDir` and `env` are as in ExtensionContext.
ExtensionItem resolve_extension(const Extension& e, const ExtensionContext& ctx, bool projectTrusted);

ExtensionPlan plan_extensions(const AiConfig& cfg, const ProviderConfig& provider, std::string_view role,
                              const ExtensionContext& ctx);

// Merges hooks objects: the groups of the same event are appended in order.
Json merge_hooks(const std::vector<Json>& sets);

// A plugin that holds the given skill folders, for Claude Code's --plugin-dir: dir/.claude-plugin/plugin.json and
// dir/skills/<name>/ (a copy of each folder; symbolic links are not followed). Names that collide get -2, -3...
Result<void> write_skills_plugin(const std::string& dir, const std::vector<std::string>& skillDirs);
inline constexpr const char* kSkillsPluginName = "factoria-extensions";

// What the trust of a project covers, read from disk: its extensions file and its Claude Code settings.
struct ProjectTrustState {
    ProjectExtensions extensions;
    ClaudeProjectSettings claude;
    bool needsTrust = false;  // something in the project runs a program (a plugin or hooks entry, or a program in .claude/settings*.json)
    bool trusted = false;     // the user trusted exactly these files
};
ProjectTrustState read_project_trust(const ExtensionContext& ctx, bool dropStale);

// The sentence the run, `ai.extensions` and `factoria ai doctor` use when the project's .claude/settings*.json is not loaded:
// what it holds, what that costs, how to trust the project.
std::string untrusted_settings_message(const std::vector<std::string>& described);

// The report `ai.extensions` returns (JSON, see docs/AI_PROVIDERS.md). `role` empty = every role.
Json extensions_report(const AiConfig& cfg, const ExtensionContext& ctx, std::string_view role = {});
// Lines for `factoria ai doctor` ("" prefix per line); empty when there is nothing to say.
std::vector<std::string> extension_doctor_lines(const AiConfig& cfg, const ExtensionContext& ctx);

// The context a run or a command uses: the project folder, the environment, and the trust file next to ai.json (the one the
// config was read from, else the default path).
ExtensionContext make_extension_context(const AiConfig& cfg, std::string_view projectDir, const EnvLookup& env);

}  // namespace fa::ai
