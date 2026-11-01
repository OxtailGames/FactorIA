// Extensions the CLI agents load: plugins, skill folders and hooks ("extensions" in the user ai.json and in a project's
// .factoria/extensions.json). This header holds the data, the parsing and writing, the per-project trust and the deny rules
// found in a project's Claude Code settings; extension_plan.h turns them into what one run of one provider receives.
// docs/AI_PROVIDERS.md, "Extensions".
#pragma once

#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::ai {

enum class ExtensionKind { Plugin, Skill, Hooks };
const char* extension_kind_name(ExtensionKind k);  // "plugin", "skill", "hooks"

// Who gets an extension that lists no roles: the roles that build the game (the same as the tool servers' default).
inline constexpr const char* kDefaultExtensionRoles[] = {"orchestrator", "worker", "fast", "artist", "audio"};
inline constexpr std::size_t kMaxExtensionName = 40;
inline constexpr const char* kProjectExtensionsFile = ".factoria/extensions.json";

struct Extension {
    ExtensionKind kind = ExtensionKind::Plugin;
    std::string name;      // [A-Za-z0-9_-], up to kMaxExtensionName; unique among the entries of its kind
    std::string source = "user";  // "user" (ai.json) or "project" (.factoria/extensions.json); never written to a file
    std::string path;      // plugin (a directory or a .zip) and skill (a folder): as written, "~" and relative not yet resolved
    std::string plugin;    // plugin: "name@marketplace" of a Claude Code plugin the user installed (instead of path)
    Json hooks;            // hooks: Claude Code's hooks object (event -> [{matcher, hooks: [{type, command}]}])
    std::string note;      // what it is for
    std::vector<std::string> roles;  // who loads it; empty = kDefaultExtensionRoles
    bool enabled = true;

    bool from_project() const { return source == "project"; }
    // Plugins and hooks can run a program (a hook command, a plugin's own hooks and servers); a skill is text. A hooks entry whose
    // handlers are all of type "js" runs no program: its modules run in the engine's sandbox, so it needs no trust.
    bool runs_program() const;
    // Enabled, and `role` is in `roles` (in the defaults when `roles` is empty). artCritic and reviewer only when listed.
    bool serves_role(std::string_view role) const;
};

struct ExtensionsConfig {
    std::vector<Extension> entries;  // plugins, then skills, then hooks, each in the file's order
    // true: Claude Code also loads your own setup (~/.claude); false: only the extensions listed here and the project's .claude
    // (--setting-sources project,local), which drops ALL user-level settings (permissions and env too). User file only.
    bool inheritUserPlugins = true;

    bool empty() const { return entries.empty() && inheritUserPlugins; }
};

// "" when `name` is usable, else what is wrong with it.
std::string extension_name_problem(std::string_view name);

// Parses the value of "extensions" (user ai.json) or the whole content of .factoria/extensions.json (`source` "project",
// where inheritUserPlugins is an error). `at` is the JSON pointer for errors ("/extensions"). Teaching errors with
// "did you mean" for unknown properties, roles and hook events. Relative paths: an error in a user entry (a user file has no
// folder to be relative to), resolved against the project folder later for a project entry; a project skill must stay inside
// the project (no "~", no "..", not absolute).
Result<ExtensionsConfig> parse_extensions(const Json& section, std::string_view at, std::string_view source = "user");
// Checks Claude Code's hooks object (the value under "hooks" in a settings.json), plus FactorIA's beforeCommand and afterCommand:
// known event names, matcher groups ("match" is accepted for "matcher"), handler types (command, js, http, prompt, agent), a
// "command" for type command, a "module" inside hooks/ for type js, a "timeout" in seconds. `at` is the pointer for errors.
Result<void> validate_hooks(const Json& hooks, std::string_view at);
// What a user pastes as hooks: {"hooks": {...}} (a settings.json or hooks.json), or the events object itself. Returns the
// events object, validated.
Result<Json> parse_hooks_json(const Json& pasted, std::string_view at = "/hooks");

// One entry as the file writes it.
Json extension_to_json(const Extension& e);
// The whole section; inheritUserPlugins only when `includeSettings` (the user file) and false.
Json extensions_to_json(const ExtensionsConfig& cfg, bool includeSettings);

// Writes ONLY "extensions" into the config file at `path` (created when missing), keeping everything else; empty removes the
// section. Entries from a project are not written. Owner-only permissions (write_private_file).
Result<void> save_extensions(const ExtensionsConfig& cfg, std::string_view path);

// The project's .factoria/extensions.json, read.
struct ProjectExtensions {
    std::string path;   // absolute path of the file (even when it does not exist)
    bool exists = false;
    std::string hash;   // sha256 of the bytes ("" when there is no file)
    std::string error;  // why the file could not be used ("" when fine); `entries` is empty then
    std::vector<Extension> entries;  // source "project"
};
ProjectExtensions load_project_extensions(std::string_view projectDir);
// Writes the project file (an empty list removes it). The entries' source is ignored.
Result<void> save_project_extensions(const std::vector<Extension>& entries, std::string_view projectDir);

// --- Claude Code's own project settings -----------------------------------------------------------------------------------
// Claude Code in -p mode skips its workspace-trust dialog, so a downloaded game's .claude/settings.json and
// .claude/settings.local.json would take effect in FactorIA's runs without asking: they run programs (hooks, enabledPlugins,
// extraKnownMarketplaces, statusLine, apiKeyHelper and the other settings that name a command) and widen what the AI may do (env,
// permissions.allow, a permissions.defaultMode other than "default", additionalDirectories). FactorIA reads the two files, never
// loads them for the user, and keeps Claude Code from loading them (--setting-sources without project and local) until the
// project is trusted.
struct ClaudeSettingsFile {
    std::string path;                  // absolute path (even when the file does not exist)
    bool exists = false;
    std::string hash;                  // sha256 of the bytes ("" when there is no file)
    // what in it needs the user's trust: it runs a program ("hooks (PreToolUse, Stop)", "statusLine") or widens what the AI may
    // do without a dialog ("env (ANTHROPIC_BASE_URL)", "permissions.allow (Bash)", "permissions.defaultMode (bypassPermissions)"),
    // or is a setting this version does not know ("unknown setting KEY", the name only): only keys known to be harmless are free
    std::vector<std::string> grants;
    std::string error;                 // the file is not valid JSON: Claude Code ignores it too, so it grants nothing
};
struct ClaudeProjectSettings {
    std::vector<ClaudeSettingsFile> files;  // settings.json, then settings.local.json
    // sha256 over the bytes of both files; "" when neither needs trust (an edit of a harmless file then changes nothing, an edit
    // that adds a hook or a permissions.allow rule changes it from "" to a hash).
    std::string hash;
    bool needs_trust() const { return !hash.empty(); }
    // ".claude/<file name>: hooks (Stop), env (A_KEY)" for each file that needs trust.
    std::vector<std::string> describe() const;
};
ClaudeProjectSettings load_claude_project_settings(std::string_view projectDir);

// --- trust ---------------------------------------------------------------------------------------------------------------
// A plugin or a hook that comes from a project runs a program, and so do the hooks, plugins and commands in the project's
// .claude/settings*.json that Claude Code would load (programs, env, allowed tools), so they apply only after the USER trusts
// the project once. The trust is
// kept per project path and per hash of BOTH sources (the extensions file and the two Claude Code settings files), in a
// user-level file next to ai.json (ai-trust.json), and is dropped when either changes. Only the editor (and C++ callers) can
// grant it: no command does, so an AI cannot trust what it just wrote.
std::string extensions_trust_path(std::string_view aiConfigPath);
// True when `projectDir` is trusted for exactly these hashes: `hash` of .factoria/extensions.json ("" = no file) and
// `claudeHash` of ClaudeProjectSettings::hash ("" = nothing in .claude needs trust). False when both are empty (nothing to
// trust). A record for other hashes is removed (a file changed; `dropped` says so) unless `dropStale` is false (the read-only
// report only looks).
bool project_extensions_trusted(std::string_view trustPath, std::string_view projectDir, std::string_view hash,
                                bool* dropped = nullptr, bool dropStale = true, std::string_view claudeHash = {});
Result<void> trust_project_extensions(std::string_view trustPath, std::string_view projectDir, std::string_view hash,
                                      std::string_view claudeHash = {});
Result<void> forget_project_trust(std::string_view trustPath, std::string_view projectDir);

// --- Claude Code deny rules --------------------------------------------------------------------------------------------
// A rule in the project's .claude/settings.json or settings.local.json "permissions.deny" that names FactorIA's own tool server
// (mcp__factoria, mcp__factoria__*, mcp__factoria__<tool>). Claude Code applies it over --allowedTools, so the AI loses
// those tools without any error to explain it.
struct DeniedTool {
    std::string file;  // the settings file (absolute path)
    std::string rule;  // the rule as written
    std::string tool;  // "all FactorIA tools" or the tool name
    std::string fix;   // how to restore it
};
std::vector<DeniedTool> find_denied_factoria_tools(std::string_view projectDir);
std::string format_denied_tool(const DeniedTool& d);  // one sentence: file, rule, what is lost, the fix

// --- shared helpers -----------------------------------------------------------------------------------------------------
using ExtensionEnv = std::function<std::string(const std::string& name)>;  // same shape as EnvLookup
// "~" and "~/x" -> the home folder (HOME, else USERPROFILE, from `env`). Anything else unchanged.
std::string expand_home(const std::string& path, const ExtensionEnv& env);
// Absolute path of an entry's folder/zip: "~" expanded, relative resolved against `projectDir` (project entries).
std::string resolve_extension_path(const Extension& e, std::string_view projectDir, const ExtensionEnv& env);
// Canonical form used as a key of the trust file.
std::string canonical_project_key(std::string_view projectDir);

}  // namespace fa::ai
