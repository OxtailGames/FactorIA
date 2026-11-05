#include "ai_project_edit.h"

#include <algorithm>

#include "fa/ai/assets.h"

namespace fa::editor {

std::string ai_settings_title(bool projectOpen, std::string_view projectName) {
    if (!projectOpen) return "AI settings - Your defaults";
    return "AI settings - This project: " + (projectName.empty() ? std::string("(unnamed)") : std::string(projectName));
}

const char* ai_source_label(ai::SettingSource source) {
    switch (source) {
        case ai::SettingSource::Project: return "This project";
        case ai::SettingSource::You: return "Your defaults";
        case ai::SettingSource::Default: return "Built in";
    }
    return "?";
}

ai::SettingSource ai_group_source(const ai::ResolvedAiConfig& resolved, std::string_view pointer) {
    bool you = false;
    bool any = false;
    const std::string prefix = std::string(pointer) + "/";
    for (const auto& [key, source] : resolved.sources) {
        if (key != pointer && key.compare(0, prefix.size(), prefix) != 0) continue;
        any = true;
        if (source == ai::SettingSource::Project) return ai::SettingSource::Project;
        if (source == ai::SettingSource::You) you = true;
    }
    if (!any) return resolved.source_of(pointer);
    return you ? ai::SettingSource::You : ai::SettingSource::Default;
}

ai::AiConfig ai_apply_edits(const ai::AiConfig& base, const std::map<std::string, ai::RoleConfig>* roles,
                            const std::map<std::string, ai::AssetRoute>* routes, const ai::AssetSources* sources) {
    ai::AiConfig out = base;
    if (roles) {
        for (const char* name : ai::kAllRoles) {
            const auto it = roles->find(name);
            if (it == roles->end()) continue;
            out.roles[name] = it->second;
            if (std::string_view(name) == ai::kRoleOrchestrator) out.roles[name].enabled = true;  // it cannot be turned off
        }
    }
    if (routes) {
        out.assets.clear();
        for (ai::MediaKind k : ai::kMediaKinds) {
            const auto it = routes->find(ai::media_kind_name(k));
            if (it != routes->end() && !it->second.provider.empty()) out.assets[ai::media_kind_name(k)] = it->second;
        }
    }
    if (sources) out.assetSources = *sources;
    return out;
}

Result<Json> ai_project_overrides_for(const ai::ResolvedAiConfig& resolved, const std::map<std::string, ai::RoleConfig>* roles,
                                      const std::map<std::string, ai::AssetRoute>* routes, const ai::AssetSources* sources) {
    if (routes) {
        for (ai::MediaKind k : ai::kMediaKinds) {
            const std::string kind = ai::media_kind_name(k);
            const auto have = resolved.inherited.assets.find(kind);
            const auto want = routes->find(kind);
            if (have == resolved.inherited.assets.end() || have->second.provider.empty()) continue;
            if (want != routes->end() && !want->second.provider.empty()) continue;
            return make_error("A project cannot turn " + kind + " assets back to None: your defaults make them with '" +
                                  have->second.provider + "'",
                              "Pick a provider for this project, press Reset to my defaults on the row, or use Save as my defaults to "
                              "change it for every project.");
        }
    }
    const ai::AiConfig wanted = ai_apply_edits(resolved.config, roles, routes, sources);
    return ai::project_overrides_from(wanted, resolved.inherited);
}

std::map<std::string, ai::RoleConfig> ai_roles_for_defaults(const ai::AiConfig& inherited,
                                                            const std::map<std::string, ai::RoleConfig>& edits) {
    std::map<std::string, ai::RoleConfig> out = edits;
    for (const char* extra : ai::kExtraRoles) {
        const auto it = out.find(extra);
        if (it == out.end()) continue;
        const ai::RoleConfig was = inherited.role(extra);
        const ai::RoleConfig& now = it->second;
        if (was.provider == now.provider && was.model == now.model && was.effort == now.effort &&
            was.maxContextTokens == now.maxContextTokens && was.enabled == now.enabled)
            out.erase(it);
    }
    return out;
}

}  // namespace fa::editor
