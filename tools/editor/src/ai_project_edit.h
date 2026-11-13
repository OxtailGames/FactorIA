// The non-UI half of the AI settings window's per-project editing (docs/EDITOR.md, "AI settings"; docs/AI_PROVIDERS.md, "Per
// project"): where a row's value comes from, what the Roles and Assets tabs would write to <project>/.factoria/ai/settings.json,
// and what "Save as my defaults" writes to ai.json. The window itself is in ai_settings.cpp and ai_project_ui.cpp.
#pragma once

#include <map>
#include <string>
#include <string_view>

#include "fa/ai/project_settings.h"

namespace fa::editor {

// The title of the AI settings window (without the "###AiSettings" id): "AI settings - This project: <name>" with a project open,
// "AI settings - Your defaults" without one (the window then edits ai.json).
std::string ai_settings_title(bool projectOpen, std::string_view projectName);

// "This project", "Your defaults" or "Built in": what a row says about where its value comes from.
const char* ai_source_label(ai::SettingSource source);

// Where a group of values comes from: Project when the project's file sets any value under `pointer` ("/roles/artist",
// "/assets/image", "/assetSources/images", or one value), else You when ai.json sets one (or one differs from the engine's), else
// Default. `pointer` is a JSON pointer into ai::settings_view.
ai::SettingSource ai_group_source(const ai::ResolvedAiConfig& resolved, std::string_view pointer);

// The edits of the Roles tab (roles) and of the Assets tab (routes, sources) laid over `base`. A null part stays as `base` has it.
// `routes` holds every kind by name; a kind with an empty provider has no route.
ai::AiConfig ai_apply_edits(const ai::AiConfig& base, const std::map<std::string, ai::RoleConfig>* roles,
                            const std::map<std::string, ai::AssetRoute>* routes, const ai::AssetSources* sources);

// What the project's file must say so that the project runs with `base` plus the edits (resolved.config is the base): the
// values that differ from what the project inherits (resolved.inherited), as ai::project_overrides_from writes them. An error
// (message + hint) for what a project's file cannot say: a kind of asset set to None while the user's ai.json has a provider for
// it (a project cannot remove a route).
Result<Json> ai_project_overrides_for(const ai::ResolvedAiConfig& resolved,
                                      const std::map<std::string, ai::RoleConfig>* roles,
                                      const std::map<std::string, ai::AssetRoute>* routes,
                                      const ai::AssetSources* sources);

// The roles "Save as my defaults" writes to ai.json: all seven, except artist, audio, artCritic and reviewer that still have the
// value `inherited` (ai.json) gives them, since these follow the orchestrator's and the worker's provider until someone sets them.
std::map<std::string, ai::RoleConfig> ai_roles_for_defaults(const ai::AiConfig& inherited,
                                                            const std::map<std::string, ai::RoleConfig>& edits);

// "Unsaved edits survive a reload" (the project's file or ai.json changed while the window was open, or Accept changed what the project
// sets). `shown` is the config the window displayed when the edits were made, `now` the one it shows after the reload. A row the
// person changed (it differs from `shown`) stays as typed; a row they did not touch takes the value of `now`.
bool ai_same_role(const ai::RoleConfig& a, const ai::RoleConfig& b);
bool ai_roles_edited(const std::map<std::string, ai::RoleConfig>& edits,
                     const ai::AiConfig& shown);  // any role differs from `shown`
std::map<std::string, ai::RoleConfig> ai_roles_keep_edits(const std::map<std::string, ai::RoleConfig>& edits,
                                                          const ai::AiConfig& shown, const ai::AiConfig& now);
std::map<std::string, ai::AssetRoute> ai_routes_keep_edits(const std::map<std::string, ai::AssetRoute>& edits,
                                                           const ai::AiConfig& shown, const ai::AiConfig& now);
// Per list: each category's sites and the "only these sites" switch are kept or replaced on their own.
ai::AssetSources ai_sources_keep_edits(const ai::AssetSources& edits, const ai::AiConfig& shown,
                                       const ai::AiConfig& now);

}  // namespace fa::editor
