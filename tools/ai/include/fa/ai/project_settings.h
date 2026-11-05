// AI settings per project: <project>/.factoria/ai/settings.json (schemas/ai-project-settings.schema.json), and the one place that
// turns "engine defaults < your ai.json < the project's file" into the AiConfig a project runs with. docs/AI_PROVIDERS.md,
// "Per project".
//
// What the file may hold: roles (enabled, provider, model, effort, maxTokens, maxContextTokens, toolGroups), limits, assets,
// assetSources, savers, and on/off switches for the user's own mcpServers and extensions. What it may NOT hold: anything that
// runs a program or sends data somewhere (a command, an address, a header, an environment, a key): it can only NAME the
// providers, tool servers and extensions that ~/.factoria/ai.json defines, so a copied project never runs a program or spends a
// key. Such a key is an error that says so and says where it belongs.
//
// Trust: a file the user did not save on this computer (it came inside a copied or unzipped project) applies only after the user
// accepts it once (accept_project_settings; the editor asks). The acceptance is the sha256 of the file in ai-trust.json (next
// to ai.json, the same file as the extensions' trust) and is dropped when the file changes. Saving through save_project_settings
// on this computer records it, so the user's own edits apply at once. No command grants trust: an AI cannot accept what it
// just wrote.
//
// How callers use it:
//   * a runtime path that needs "the config of this project": load_resolved_config(projectDir) (an AiConfig, as load_config
//     returns, with the project's file applied when it is trusted). Without a project file it returns exactly what
//     load_config returns and writes nothing.
//   * a window or command that shows where each value comes from: resolve_ai_config(projectDir) (ResolvedAiConfig: the config,
//     the source of every value, what a file that is not accepted yet would change).
//   * editing: save_project_settings / project_overrides_from / reset_project_setting.
// The user file keeps its own API (load_config, save_roles, ...); nothing here writes ai.json.
#pragma once

#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/ai/config.h"
#include "fa/core/json.h"
#include "fa/core/json_schema.h"

namespace fa::ai {

inline constexpr const char* kProjectAiSettingsFile = ".factoria/ai/settings.json";

std::string_view project_settings_schema_text();  // schemas/ai-project-settings.schema.json
// Schema problems only (types, ranges, unknown keys). validate_project_settings adds the names and the teaching messages.
std::vector<SchemaError> validate_project_settings_json(const Json& j);

// Where a value of a resolved config comes from.
enum class SettingSource {
    Default,  // the engine's built-in value
    You,      // ~/.factoria/ai.json
    Project,  // <project>/.factoria/ai/settings.json (accepted)
};
const char* setting_source_name(SettingSource s);  // "default", "you", "project"

// The settings a project can override, as one JSON document shaped like the project's file (the same keys), with EVERY value
// of `cfg` filled in:
//   /roles/<role>/{enabled,provider,model,effort,maxTokens,maxContextTokens[,toolGroups]}   (the seven roles; toolGroups only when set)
//   /limits/{maxTurns,maxCostUsd,maxTotalTokens,stuckAfterSeconds,maxConcurrentRuns}
//   /assets/<kind>/{provider[,model][,voice]}                                              (the kinds that have a route)
//   /assetSources/{images,models,audio,fonts,other,onlyListed}                              (a category: the array of sites)
//   /savers/{loopGuard,loopGuardJudge,learnedToolGroups,projectFacts}
//   /mcpServers/<name>                                                                      (true/false: the server is enabled)
//   /extensions/{plugins,skills,hooks}/<name>                                               (true/false: the entry is enabled)
// A "leaf" is a value of this document that is not an object (an array is a leaf); the JSON pointers of the leaves are the
// keys of ResolvedAiConfig::sources, of SettingChange::pointer and of reset_project_setting.
Json settings_view(const AiConfig& cfg);

// One value that the project's file would change: the pointer, the value now (null when there is none) and the value the file gives.
struct SettingChange {
    std::string pointer;  // "/roles/artist/enabled"
    Json from;
    Json to;
    std::string text() const;  // "/roles/artist/enabled: true -> false"
};

struct ResolvedAiConfig {
    // The config the project runs with: `inherited` with the project's file applied when `applied`. sourcePath is ai.json's.
    AiConfig config;
    // The same without the project's file: engine defaults < ai.json. The value a row goes back to on "Reset to my defaults".
    AiConfig inherited;
    // Where each leaf of settings_view(config) comes from (a leaf the project's file names counts as Project even when it
    // equals the inherited value; a value that follows another one the project changed, such as the artist following the
    // orchestrator's provider, counts as Project too). A value ai.json sets, or that differs from the engine's, is You.
    std::map<std::string, SettingSource> sources;

    std::string projectDir;   // as given
    std::string projectFile;  // absolute path of .factoria/ai/settings.json (even when it does not exist)
    bool fileExists = false;
    std::string fileHash;     // sha256 of the file (line endings normalized); "" when there is none
    Json overrides = Json::object();  // the file's content ({} when there is none)
    bool applied = false;     // the file exists, is valid and accepted: `config` has its values
    // The file exists and is valid but the user has not accepted it on this computer: the project behaves as without it, and
    // `pending` says what it would change, for the editor to show before the user accepts (accept_project_settings).
    bool pendingTrust = false;
    std::vector<SettingChange> pending;

    SettingSource source_of(std::string_view pointer) const;  // Default for a pointer that is not a leaf of the view
};

// What `projectDir` runs with. `aiConfigPath` "" = default_config_path(env). `projectDir` "" = no project (the user file alone).
// An error when ai.json is invalid, or when the project's file is invalid: not JSON, a key that is not allowed in a project
// file, an unknown provider, server, role or extension name (each with its JSON pointer, the file and the fix), or a value
// ai.json would refuse. An invalid project file is an error even before it is accepted, so the user sees it.
Result<ResolvedAiConfig> resolve_ai_config(std::string_view projectDir, std::string_view aiConfigPath = {},
                                           const EnvLookup& env = system_env());
// resolve_ai_config(...).config, for the paths that only run with it (ai commands, skills, asset commands, the agent). Without a
// project file the result is load_config's, byte for byte.
Result<AiConfig> load_resolved_config(std::string_view projectDir, std::string_view aiConfigPath = {},
                                      const EnvLookup& env = system_env());

// The file as it is on disk: its syntax and its hash, nothing else (names are checked against ai.json by
// validate_project_settings). `error` is set when it cannot be read or is not a JSON object.
struct ProjectSettingsFile {
    std::string path;  // absolute (even when the file does not exist)
    bool exists = false;
    std::string hash;  // sha256 of the text with CRLF turned into LF, so a line-ending change does not need a new acceptance
    std::string error;
    Json overrides = Json::object();
};
ProjectSettingsFile read_project_settings_file(std::string_view projectDir);

// Checks a project's file against the user's config: no key that is not allowed in a project file (the error names the JSON
// pointer, says the key belongs in ~/.factoria/ai.json and where in the AI settings), no unknown role, provider, server,
// extension or asset kind ("did you mean"), the types and ranges of the schema. `source` names the file in the messages.
Result<void> validate_project_settings(const Json& file, const AiConfig& user, std::string_view source);

// What `wanted` changes compared with `inherited`, as the project's file would say it: only the leaves that differ. A role (or
// asset route) whose provider differs also carries its model, effort (voice), since a new provider resets them.
Json project_overrides_from(const AiConfig& wanted, const AiConfig& inherited);

// Replaces the project's file with `overrides`, keeping only what changes the inherited value: a key equal to what the user's
// ai.json gives (or the engine's default) is removed, empty objects too, and when nothing is left the file is removed. The file is
// checked first (validate_project_settings and a trial resolution): an invalid one is refused and nothing is written. The content
// is the caller's: it records the project's acceptance, so these edits apply at once. Atomic replacement with retry (fa::fs).
Result<void> save_project_settings(std::string_view projectDir, const Json& overrides, std::string_view aiConfigPath = {},
                                   const EnvLookup& env = system_env());
// Removes one override from the project's file ("/roles/artist/enabled", or a whole branch: "/roles/artist", "/limits",
// "/roles"), so the value goes back to the user's. Resetting a role's or asset route's provider also resets its model, effort
// and voice (they belong to that provider). Not a save of new content: when the file was not accepted before, it stays not
// accepted (the reduced file is still unreviewed). Nothing to remove is not an error.
Result<void> reset_project_setting(std::string_view projectDir, std::string_view pointer, std::string_view aiConfigPath = {},
                                   const EnvLookup& env = system_env());
// The user accepts the project's file as it is: `expectedHash` is ResolvedAiConfig::fileHash of what was shown, so a file that
// changed since then is refused ("" = accept whatever is there). The file must be valid. Only the editor (and C++ callers) call
// this; no command does.
Result<void> accept_project_settings(std::string_view projectDir, std::string_view expectedHash, std::string_view aiConfigPath = {},
                                     const EnvLookup& env = system_env());

}  // namespace fa::ai
