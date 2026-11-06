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

bool ai_same_role(const ai::RoleConfig& a, const ai::RoleConfig& b) {
    return a.provider == b.provider && a.model == b.model && a.effort == b.effort && a.maxTokens == b.maxTokens &&
           a.maxContextTokens == b.maxContextTokens && a.enabled == b.enabled && a.toolGroups == b.toolGroups;
}

bool ai_roles_edited(const std::map<std::string, ai::RoleConfig>& edits, const ai::AiConfig& shown) {
    return std::ranges::any_of(edits, [&](const auto& kv) { return !ai_same_role(kv.second, shown.role(kv.first)); });
}

std::map<std::string, ai::RoleConfig> ai_roles_keep_edits(const std::map<std::string, ai::RoleConfig>& edits, const ai::AiConfig& shown,
                                                          const ai::AiConfig& now) {
    std::map<std::string, ai::RoleConfig> out;
    for (const char* name : ai::kAllRoles) {
        const auto it = edits.find(name);
        out[name] = it != edits.end() && !ai_same_role(it->second, shown.role(name)) ? it->second : now.role(name);
    }
    return out;
}

namespace {

ai::AssetRoute route_of(const ai::AiConfig& cfg, const std::string& kind) {
    const auto it = cfg.assets.find(kind);
    return it == cfg.assets.end() ? ai::AssetRoute{} : it->second;
}

bool same_route(const ai::AssetRoute& a, const ai::AssetRoute& b) {
    return a.provider == b.provider && a.model == b.model && a.voice == b.voice;
}

bool same_sites(const std::vector<ai::AssetSite>& a, const std::vector<ai::AssetSite>& b) {
    return std::ranges::equal(a, b, [](const ai::AssetSite& x, const ai::AssetSite& y) { return x.url == y.url && x.note == y.note; });
}

}  // namespace

std::map<std::string, ai::AssetRoute> ai_routes_keep_edits(const std::map<std::string, ai::AssetRoute>& edits, const ai::AiConfig& shown,
                                                           const ai::AiConfig& now) {
    std::map<std::string, ai::AssetRoute> out;
    for (ai::MediaKind k : ai::kMediaKinds) {
        const std::string kind = ai::media_kind_name(k);
        const auto it = edits.find(kind);
        const ai::AssetRoute edited = it == edits.end() ? ai::AssetRoute{} : it->second;
        out[kind] = same_route(edited, route_of(shown, kind)) ? route_of(now, kind) : edited;
    }
    return out;
}

ai::AssetSources ai_sources_keep_edits(const ai::AssetSources& edits, const ai::AiConfig& shown, const ai::AiConfig& now) {
    ai::AssetSources out = now.assetSources;
    if (edits.onlyListed != shown.assetSources.onlyListed) out.onlyListed = edits.onlyListed;
    for (ai::SiteCategory c : ai::kSiteCategories) {
        if (!same_sites(edits.list(c), shown.assetSources.list(c))) out.list(c) = edits.list(c);
    }
    return out;
}

}  // namespace fa::editor
