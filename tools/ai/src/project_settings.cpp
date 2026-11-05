// AI settings per project: the file, its validation, the resolution engine defaults < ai.json < project, the trust and the
// writer. See fa/ai/project_settings.h and docs/AI_PROVIDERS.md, "Per project".
#include "fa/ai/project_settings.h"

#include <algorithm>
#include <filesystem>
#include <cstring>
#include <optional>
#include <set>

#include "fa/ai/extensions.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using namespace util;

const char* setting_source_name(SettingSource s) {
    switch (s) {
        case SettingSource::Default: return "default";
        case SettingSource::You: return "you";
        case SettingSource::Project: return "project";
    }
    return "default";
}

std::vector<SchemaError> validate_project_settings_json(const Json& j) {
    Json schema = util::parse(project_settings_schema_text());
    if (schema.is_discarded()) {
        return {SchemaError{"", "internal error: embedded ai-project-settings schema is not valid JSON", ""}};
    }
    return validate_json(schema, j);
}

std::string SettingChange::text() const {
    return pointer + ": " + (from.is_null() ? std::string("(not set)") : dump(from)) + " -> " + dump(to);
}

SettingSource ResolvedAiConfig::source_of(std::string_view pointer) const {
    auto it = sources.find(std::string(pointer));
    return it == sources.end() ? SettingSource::Default : it->second;
}

// ---------------------------------------------------------------------------------------------------------------------
// The view: every resolvable value as one JSON document shaped like the project's file

namespace {

const char* const kLimitKeys[] = {"maxTurns", "maxCostUsd", "maxTotalTokens", "stuckAfterSeconds", "maxConcurrentRuns"};
const char* const kRoleKeys[] = {"enabled", "provider", "model", "effort", "maxTokens", "maxContextTokens", "toolGroups"};
const char* const kAssetKeys[] = {"provider", "model", "voice"};
const char* const kSaverKeys[] = {"loopGuard", "loopGuardJudge", "learnedToolGroups", "projectFacts"};
const char* const kExtensionGroups[] = {"plugins", "skills", "hooks"};

const char* extension_group(ExtensionKind k) {
    switch (k) {
        case ExtensionKind::Plugin: return "plugins";
        case ExtensionKind::Skill: return "skills";
        case ExtensionKind::Hooks: return "hooks";
    }
    return "plugins";
}

std::vector<std::string> names_of(const char* const* first, std::size_t n) { return std::vector<std::string>(first, first + n); }
template <std::size_t N>
std::vector<std::string> names_of(const char* const (&list)[N]) { return names_of(list, N); }

std::string pointer_escape(std::string_view key) {
    std::string out;
    for (char c : key) {
        if (c == '~') out += "~0";
        else if (c == '/') out += "~1";
        else out += c;
    }
    return out;
}

Json site_to_json(const AssetSite& s) { return s.note.empty() ? Json(s.url) : Json::object({{"url", s.url}, {"note", s.note}}); }

// Entries of "assetSources" in one spelling: a string when there is no note.
Json normalize_site(const Json& entry) {
    if (entry.is_string()) return entry;
    if (entry.is_object() && str(entry, "note").empty()) return Json(str(entry, "url"));
    return entry;
}

// Every leaf of `j` (a value that is not an object) by JSON pointer.
void collect_leaves(const Json& j, const std::string& pointer, std::map<std::string, Json>& out) {
    if (j.is_object()) {
        for (auto it = j.begin(); it != j.end(); ++it) collect_leaves(it.value(), pointer + "/" + pointer_escape(it.key()), out);
    } else {
        out[pointer] = j;
    }
}
std::map<std::string, Json> leaves_of(const Json& j) {
    std::map<std::string, Json> out;
    collect_leaves(j, "", out);
    return out;
}

// The leaves a user's ai.json sets, in the pointers of the view (the depth of each section is fixed).
std::set<std::string> raw_leaf_pointers(const Json& raw) {
    std::set<std::string> out;
    auto at_depth = [&](const char* section, int depth) {
        const Json* s = child(raw, section);
        if (!s || !s->is_object()) return;
        std::string base = std::string("/") + section;
        for (auto a = s->begin(); a != s->end(); ++a) {
            const std::string p1 = base + "/" + pointer_escape(a.key());
            if (depth == 1 || !a.value().is_object()) {
                out.insert(p1);
                continue;
            }
            for (auto b = a.value().begin(); b != a.value().end(); ++b) {
                const std::string p2 = p1 + "/" + pointer_escape(b.key());
                out.insert(p2);
            }
        }
    };
    at_depth("roles", 2);
    at_depth("limits", 1);
    at_depth("savers", 1);
    at_depth("assets", 2);
    at_depth("assetSources", 1);
    at_depth("mcpServers", 1);
    if (const Json* ext = child(raw, "extensions"); ext && ext->is_object()) {
        for (const char* g : kExtensionGroups) {
            const Json* list = child(*ext, g);
            if (!list || !list->is_object()) continue;
            for (auto it = list->begin(); it != list->end(); ++it)
                out.insert(std::string("/extensions/") + g + "/" + pointer_escape(it.key()));
        }
    }
    return out;
}

}  // namespace

Json settings_view(const AiConfig& cfg) {
    Json view = Json::object();
    Json roles = Json::object();
    for (const char* name : kAllRoles) {
        auto it = cfg.roles.find(name);
        if (it == cfg.roles.end()) continue;
        const RoleConfig& r = it->second;
        Json rj = Json::object({{"enabled", r.enabled},
                                {"provider", r.provider},
                                {"model", r.model},
                                {"effort", r.effort},
                                {"maxTokens", r.maxTokens},
                                {"maxContextTokens", r.maxContextTokens}});
        if (r.toolGroups) rj["toolGroups"] = *r.toolGroups;
        roles[name] = std::move(rj);
    }
    view["roles"] = std::move(roles);
    view["limits"] = Json::object({{"maxTurns", cfg.limits.maxTurns},
                                   {"maxCostUsd", cfg.limits.maxCostUsd},
                                   {"maxTotalTokens", cfg.limits.maxTotalTokens},
                                   {"stuckAfterSeconds", cfg.limits.stuckAfterSeconds},
                                   {"maxConcurrentRuns", cfg.limits.maxConcurrentRuns}});
    Json assets = Json::object();
    for (MediaKind k : kMediaKinds) {
        auto it = cfg.assets.find(media_kind_name(k));
        if (it == cfg.assets.end()) continue;
        Json route = Json::object({{"provider", it->second.provider}});
        if (!it->second.model.empty()) route["model"] = it->second.model;
        if (!it->second.voice.empty()) route["voice"] = it->second.voice;
        assets[media_kind_name(k)] = std::move(route);
    }
    view["assets"] = std::move(assets);
    Json sources = Json::object();
    for (SiteCategory c : kSiteCategories) {
        Json list = Json::array();
        for (const AssetSite& s : cfg.assetSources.list(c)) list.push_back(site_to_json(s));
        sources[site_category_key(c)] = std::move(list);
    }
    sources["onlyListed"] = cfg.assetSources.onlyListed;
    view["assetSources"] = std::move(sources);
    view["savers"] = Json::object({{"loopGuard", cfg.savers.loopGuard},
                                   {"loopGuardJudge", cfg.savers.loopGuardJudge},
                                   {"learnedToolGroups", cfg.savers.learnedToolGroups},
                                   {"projectFacts", cfg.savers.projectFacts}});
    Json servers = Json::object();
    for (const ToolServer& s : cfg.toolServers) servers[s.name] = s.enabled;
    view["mcpServers"] = std::move(servers);
    Json extensions = Json::object();
    for (const Extension& e : cfg.extensions.entries) {
        if (e.from_project()) continue;
        extensions[extension_group(e.kind)][e.name] = e.enabled;
    }
    view["extensions"] = std::move(extensions);
    return view;
}

namespace {

// ---------------------------------------------------------------------------------------------------------------------
// The file

std::string normalized_text(std::string text) {
    std::string out;
    out.reserve(text.size());
    for (std::size_t i = 0; i < text.size(); ++i) {
        if (text[i] == '\r' && i + 1 < text.size() && text[i + 1] == '\n') continue;
        out += text[i];
    }
    return out;
}

std::string absolute_dir(std::string_view projectDir) {
    std::error_code ec;
    fsys::path p = fsys::absolute(fsys::path(std::string(projectDir)), ec);
    return (ec ? fsys::path(std::string(projectDir)) : p).lexically_normal().string();
}

std::string settings_path(std::string_view projectDir) {
    return (fsys::path(absolute_dir(projectDir)) / ".factoria" / "ai" / "settings.json").string();
}

}  // namespace

ProjectSettingsFile read_project_settings_file(std::string_view projectDir) {
    ProjectSettingsFile out;
    out.path = settings_path(projectDir);
    std::error_code ec;
    if (!fsys::is_regular_file(fsys::path(out.path), ec)) return out;
    out.exists = true;
    auto text = fs::read_text(out.path);
    if (!text) {
        out.error = out.path + ": cannot read the file: " + text.error().message;
        return out;
    }
    out.hash = sha256_hex(normalized_text(*text));
    auto parsed = fa::parse_json(*text, out.path);
    if (!parsed) {
        out.error = parsed.error().to_string();
        return out;
    }
    if (!parsed->is_object()) {
        out.error = out.path + ": the AI settings of a project must be a JSON object, like {\"roles\": {\"artist\": {\"enabled\": false}}}";
        return out;
    }
    out.overrides = std::move(*parsed);
    return out;
}

namespace {

// ---------------------------------------------------------------------------------------------------------------------
// Validation

struct Problem {
    std::string pointer, message;
};

// Keys that define WHAT a provider, tool server or extension is or does. They belong in the user's ai.json: in a project file
// they could run a program or send data to an address the user never chose.
bool is_user_only_key(std::string_view key) {
    static const char* const keys[] = {"providers", "defaultProvider", "type", "preset", "command", "argv", "args", "env", "unsetEnv",
                                       "url", "baseUrl", "headers", "apiKey", "apiKeyEnv", "factoriaCommand", "pricing", "license",
                                       "useAntCli", "sendReasoningEffort", "maxRetries", "timeoutSeconds", "path", "plugin", "hooks",
                                       "note", "inheritUserPlugins"};
    return std::any_of(std::begin(keys), std::end(keys), [&](const char* k) { return key == k; });
}

struct Area {
    const char* where;    // "AI settings > Providers"
    const char* example;  // what to write in the project file instead
};
constexpr Area kProviders{"AI settings > Providers", R"({"roles": {"artist": {"provider": "claude-code"}}})"};
constexpr Area kServers{"AI settings > Tool servers", R"({"mcpServers": {"scenario": false}})"};
constexpr Area kExtensions{"AI settings > Extensions", R"({"extensions": {"plugins": {"notes": false}}})"};

Problem not_allowed(const std::string& pointer, std::string_view key, const Area& area) {
    return {pointer, "'" + std::string(key) + "' is not allowed in a project's AI settings file: a project may only NAME the providers, tool "
                     "servers and extensions you defined, never define one (a command, an address, a header, an environment or a key "
                     "could run a program or spend a key when the project is copied to another computer). Put it in "
                     "~/.factoria/ai.json (" + area.where + "); here, name it instead, for example " + area.example};
}

// Keys of `obj` that are not in `allowed`: not allowed (user-only), or unknown with "did you mean".
void check_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& allowed, const Area& area,
                std::vector<Problem>& out) {
    if (!obj.is_object()) return;
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        const std::string& key = it.key();
        if (std::find(allowed.begin(), allowed.end(), key) != allowed.end()) continue;
        const std::string at = pointer + "/" + pointer_escape(key);
        if (is_user_only_key(key)) out.push_back(not_allowed(at, key, area));
        else out.push_back({at, "unknown key '" + key + "'. " + fa::did_you_mean(key, allowed)});
    }
}

std::string join_problems(const std::vector<Problem>& problems, std::string_view source) {
    std::string out;
    for (const Problem& p : problems) {
        if (!out.empty()) out += "\n";
        out += std::string(source) + ": " + (p.pointer.empty() ? std::string("/") : p.pointer) + ": " + p.message;
    }
    return out;
}

Error problems_error(const std::vector<Problem>& problems, std::string_view source) {
    return make_error(join_problems(problems, source),
                      "Fix the file or delete it. The format is in docs/AI_PROVIDERS.md, \"Per project\" (schemas/ai-project-settings.schema.json).");
}

}  // namespace

Result<void> validate_project_settings(const Json& file, const AiConfig& user, std::string_view source) {
    std::vector<Problem> problems;
    if (!file.is_object()) {
        return make_error(std::string(source) + ": the AI settings of a project must be a JSON object",
                          "Write something like {\"roles\": {\"artist\": {\"enabled\": false}}}.");
    }
    // 1. Keys: what a project file may not hold, and typos.
    const std::vector<std::string> top = {"$schema", "roles", "limits", "assets", "assetSources", "savers", "mcpServers", "extensions"};
    check_keys(file, "", top, kProviders, problems);
    const std::vector<std::string> allRoles(std::begin(kAllRoles), std::end(kAllRoles));
    if (const Json* roles = child(file, "roles"); roles && roles->is_object()) {
        for (auto it = roles->begin(); it != roles->end(); ++it) {
            const std::string at = "/roles/" + pointer_escape(it.key());
            if (!is_known_role(it.key())) {
                problems.push_back({at, "no role named '" + it.key() + "'. " + fa::did_you_mean(it.key(), allRoles)});
                continue;
            }
            check_keys(it.value(), at, names_of(kRoleKeys), kProviders, problems);
        }
    }
    if (const Json* v = child(file, "limits")) check_keys(*v, "/limits", names_of(kLimitKeys), kProviders, problems);
    if (const Json* v = child(file, "savers")) check_keys(*v, "/savers", names_of(kSaverKeys), kProviders, problems);
    if (const Json* v = child(file, "assetSources")) {
        std::vector<std::string> keys;
        for (SiteCategory c : kSiteCategories) keys.push_back(site_category_key(c));
        keys.push_back("onlyListed");
        check_keys(*v, "/assetSources", keys, kProviders, problems);
    }
    if (const Json* assets = child(file, "assets"); assets && assets->is_object()) {
        std::vector<std::string> kinds;
        for (MediaKind k : kMediaKinds) kinds.push_back(media_kind_name(k));
        check_keys(*assets, "/assets", kinds, kProviders, problems);
        for (auto it = assets->begin(); it != assets->end(); ++it) {
            if (std::find(kinds.begin(), kinds.end(), it.key()) == kinds.end()) continue;
            check_keys(it.value(), "/assets/" + pointer_escape(it.key()), names_of(kAssetKeys), kProviders, problems);
        }
    }
    // A server or an extension is only switched on or off: any key inside its entry defines it.
    auto no_definitions = [&](const Json& entry, const std::string& at, const Area& area, const char* name) {
        if (!entry.is_object()) return;
        for (auto it = entry.begin(); it != entry.end(); ++it) {
            const std::string key_at = at + "/" + pointer_escape(it.key());
            if (it.key() == "enabled") {
                problems.push_back({key_at, "a project only switches '" + std::string(name) + "' on or off: write the boolean itself, for example " +
                                                std::string(area.example) + ", not an object with \"enabled\""});
            } else {
                problems.push_back(not_allowed(key_at, it.key(), area));
            }
        }
    };
    if (const Json* servers = child(file, "mcpServers"); servers && servers->is_object()) {
        for (auto it = servers->begin(); it != servers->end(); ++it)
            no_definitions(it.value(), "/mcpServers/" + pointer_escape(it.key()), kServers, it.key().c_str());
    }
    if (const Json* ext = child(file, "extensions"); ext && ext->is_object()) {
        check_keys(*ext, "/extensions", names_of(kExtensionGroups), kExtensions, problems);
        for (const char* g : kExtensionGroups) {
            const Json* list = child(*ext, g);
            if (!list || !list->is_object()) continue;
            for (auto it = list->begin(); it != list->end(); ++it)
                no_definitions(it.value(), std::string("/extensions/") + g + "/" + pointer_escape(it.key()), kExtensions, it.key().c_str());
        }
    }
    if (!problems.empty()) return problems_error(problems, source);

    // 2. Types and ranges (the schema).
    for (const SchemaError& e : validate_project_settings_json(file)) {
        problems.push_back({e.pointer, e.message + (e.hint.empty() ? std::string() : " (" + e.hint + ")")});
    }
    if (!problems.empty()) return problems_error(problems, source);

    // 3. Names: only what the user's ai.json defines.
    std::vector<std::string> providerNames;
    for (const auto& [n, p] : user.providers) providerNames.push_back(n);
    auto check_provider = [&](const Json& obj, const std::string& at) {
        const std::string name = str(obj, "provider");
        if (name.empty() || user.provider(name)) return;
        problems.push_back({at + "/provider", "no provider named '" + name + "' in your AI settings. " + fa::did_you_mean(name, providerNames) +
                                                  " A project can only name a provider ~/.factoria/ai.json defines (AI settings > Providers)."});
    };
    if (const Json* roles = child(file, "roles"); roles && roles->is_object()) {
        for (auto it = roles->begin(); it != roles->end(); ++it) check_provider(it.value(), "/roles/" + it.key());
    }
    if (const Json* assets = child(file, "assets"); assets && assets->is_object()) {
        for (auto it = assets->begin(); it != assets->end(); ++it) {
            const std::string at = "/assets/" + it.key();
            check_provider(it.value(), at);
            if (!it.value().contains("provider") && user.assets.find(it.key()) == user.assets.end()) {
                MediaKind kind = MediaKind::Image;
                for (MediaKind k : kMediaKinds)
                    if (it.key() == media_kind_name(k)) kind = k;
                problems.push_back({at + "/provider", "your ai.json has no route for '" + it.key() + "' assets, so the project must name the provider. Providers that can: " +
                                                          providers_that_make(user, kind) + "."});
            }
        }
    }
    if (const Json* servers = child(file, "mcpServers"); servers && servers->is_object()) {
        std::vector<std::string> names;
        for (const ToolServer& s : user.toolServers) names.push_back(s.name);
        for (auto it = servers->begin(); it != servers->end(); ++it) {
            if (std::find(names.begin(), names.end(), it.key()) != names.end()) continue;
            problems.push_back({"/mcpServers/" + pointer_escape(it.key()),
                                "no tool server named '" + it.key() + "' in your AI settings. " + (names.empty() ? std::string("You have none yet. ") : fa::did_you_mean(it.key(), names) + " ") +
                                    "Define the server in ~/.factoria/ai.json (AI settings > Tool servers); a project can only switch it on or off."});
        }
    }
    if (const Json* ext = child(file, "extensions"); ext && ext->is_object()) {
        for (const char* g : kExtensionGroups) {
            const Json* list = child(*ext, g);
            if (!list || !list->is_object()) continue;
            std::vector<std::string> names;
            for (const Extension& e : user.extensions.entries)
                if (!e.from_project() && std::string(extension_group(e.kind)) == g) names.push_back(e.name);
            for (auto it = list->begin(); it != list->end(); ++it) {
                if (std::find(names.begin(), names.end(), it.key()) != names.end()) continue;
                problems.push_back({std::string("/extensions/") + g + "/" + pointer_escape(it.key()),
                                    "no " + std::string(g, std::strlen(g) - 1) + " named '" + it.key() + "' in your AI settings. " +
                                        (names.empty() ? std::string("You have none. ") : fa::did_you_mean(it.key(), names) + " ") +
                                        "Add it in ~/.factoria/ai.json (AI settings > Extensions); a project can only switch it on or off. Extensions "
                                        "the project brings itself are in .factoria/extensions.json."});
            }
        }
    }
    if (!problems.empty()) return problems_error(problems, source);
    return {};
}

namespace {

// ---------------------------------------------------------------------------------------------------------------------
// Resolution

// ai.json as JSON, or {} when it does not exist or is not an object (load_config already accepted it when there is one).
Json read_raw_user(const std::string& path) {
    std::error_code ec;
    if (path.empty() || !fsys::exists(fsys::path(path), ec)) return Json::object();
    auto text = fs::read_text(path);
    if (!text) return Json::object();
    Json j = util::parse(*text);
    return j.is_object() ? j : Json::object();
}

// The user's ai.json with the project's overrides written into it, so ONE parse (parse_config) applies the defaults, the
// derived roles and every check of ai.json to the result.
Json merged_json(const Json& raw, const Json& ov, const AiConfig& user) {
    Json m = raw.is_object() ? raw : Json::object();
    auto object_at = [](Json& parent, const std::string& key) -> Json& {
        Json& slot = parent[key];
        if (!slot.is_object()) slot = Json::object();
        return slot;
    };
    if (const Json* roles = child(ov, "roles"); roles && roles->is_object()) {
        for (auto it = roles->begin(); it != roles->end(); ++it) {
            Json& base = object_at(object_at(m, "roles"), it.key());
            const Json& o = it.value();
            bool providerChanged = false;
            if (o.contains("provider")) {
                const std::string want = o["provider"].get<std::string>();
                auto cur = user.roles.find(it.key());
                if (cur == user.roles.end() || cur->second.provider != want) {
                    base["provider"] = want;
                    providerChanged = true;
                }
            }
            // A new provider brings its own model and effort, unless the project says which.
            if (providerChanged) {
                if (!o.contains("model")) base.erase("model");
                if (!o.contains("effort")) base.erase("effort");
            }
            for (auto f = o.begin(); f != o.end(); ++f) {
                if (f.key() == "provider") continue;
                if ((f.key() == "maxTokens" || f.key() == "maxContextTokens") && f.value().is_number() && f.value() == 0) {
                    base.erase(f.key());  // 0 = no cap of its own: what the key's absence means
                    continue;
                }
                base[f.key()] = f.value();
            }
        }
    }
    for (const char* section : {"limits", "savers"}) {
        const Json* s = child(ov, section);
        if (!s || !s->is_object()) continue;
        Json& base = object_at(m, section);
        for (auto f = s->begin(); f != s->end(); ++f) base[f.key()] = f.value();
    }
    if (const Json* assets = child(ov, "assets"); assets && assets->is_object()) {
        for (auto it = assets->begin(); it != assets->end(); ++it) {
            Json& base = object_at(object_at(m, "assets"), it.key());
            const Json& o = it.value();
            bool providerChanged = false;
            if (o.contains("provider")) {
                const std::string want = o["provider"].get<std::string>();
                auto cur = user.assets.find(it.key());
                if (cur == user.assets.end() || cur->second.provider != want) {
                    base["provider"] = want;
                    providerChanged = true;
                }
            }
            if (providerChanged) {
                if (!o.contains("model")) base.erase("model");
                if (!o.contains("voice")) base.erase("voice");
            }
            for (auto f = o.begin(); f != o.end(); ++f) {
                if (f.key() != "provider") base[f.key()] = f.value();
            }
        }
    }
    if (const Json* s = child(ov, "assetSources"); s && s->is_object()) {
        Json& base = object_at(m, "assetSources");
        for (auto f = s->begin(); f != s->end(); ++f) base[f.key()] = f.value();
    }
    if (const Json* servers = child(ov, "mcpServers"); servers && servers->is_object()) {
        Json& base = object_at(m, "mcpServers");
        for (auto it = servers->begin(); it != servers->end(); ++it) object_at(base, it.key())["enabled"] = it.value();
    }
    if (const Json* ext = child(ov, "extensions"); ext && ext->is_object()) {
        Json& base = object_at(m, "extensions");
        for (const char* g : kExtensionGroups) {
            const Json* list = child(*ext, g);
            if (!list || !list->is_object()) continue;
            Json& group = object_at(base, g);
            for (auto it = list->begin(); it != list->end(); ++it) object_at(group, it.key())["enabled"] = it.value();
        }
    }
    return m;
}

// `inherited` with the project's overrides applied. Errors name the project's file and the JSON pointer of its key.
Result<AiConfig> apply_overrides(const Json& raw, const Json& ov, const AiConfig& inherited, const std::string& file) {
    auto merged = parse_config(merged_json(raw, ov, inherited), file);
    if (!merged) {
        return make_error(merged.error().message + "\n(" + file + " is this project's AI settings; its keys are checked like ai.json's)",
                          merged.error().hint);
    }
    AiConfig cfg = std::move(*merged);
    cfg.sourcePath = inherited.sourcePath;
    std::vector<std::string> warnings = inherited.warnings;
    for (const std::string& w : cfg.warnings)
        if (std::find(warnings.begin(), warnings.end(), w) == warnings.end()) warnings.push_back(w);
    cfg.warnings = std::move(warnings);
    return cfg;
}

std::vector<SettingChange> diff_views(const Json& from, const Json& to) {
    const auto a = leaves_of(from), b = leaves_of(to);
    std::vector<SettingChange> out;
    for (const auto& [pointer, value] : b) {
        auto it = a.find(pointer);
        if (it != a.end() && it->second == value) continue;
        out.push_back({pointer, it == a.end() ? Json(nullptr) : it->second, value});
    }
    return out;
}

std::string trust_path_for(const std::string& userPath) { return extensions_trust_path(userPath); }

}  // namespace

Result<ResolvedAiConfig> resolve_ai_config(std::string_view projectDir, std::string_view aiConfigPath, const EnvLookup& env) {
    const std::string userPath = aiConfigPath.empty() ? default_config_path(env) : std::string(aiConfigPath);
    auto user = load_config(userPath, env);
    if (!user) return user.error();

    ResolvedAiConfig out;
    out.inherited = *user;
    out.config = *user;
    out.projectDir = std::string(projectDir);
    Json raw = read_raw_user(userPath);

    Json overrides = Json::object();
    if (!projectDir.empty()) {
        ProjectSettingsFile file = read_project_settings_file(projectDir);
        out.projectFile = file.path;
        out.fileExists = file.exists;
        out.fileHash = file.hash;
        if (file.exists) {
            if (!file.error.empty()) {
                return make_error(file.error, "Fix the file or delete it (" + file.path + "): it is this project's AI settings, see docs/AI_PROVIDERS.md, \"Per project\".");
            }
            if (auto ok = validate_project_settings(file.overrides, *user, file.path); !ok) return ok.error();
            auto applied = apply_overrides(raw, file.overrides, *user, file.path);
            if (!applied) return applied.error();
            out.overrides = file.overrides;
            overrides = file.overrides;
            const bool trusted = project_ai_settings_trusted(trust_path_for(userPath), projectDir, file.hash);
            if (trusted) {
                out.config = *applied;
                out.applied = true;
            } else {
                out.pendingTrust = true;
                out.pending = diff_views(settings_view(*user), settings_view(*applied));
            }
        }
    }

    // Where each value comes from.
    const Json view = settings_view(out.config);
    const auto resolvedLeaves = leaves_of(view);
    const auto inheritedLeaves = leaves_of(settings_view(*user));
    const auto defaultLeaves = leaves_of(settings_view(default_config()));
    const auto touched = out.applied ? leaves_of(overrides) : std::map<std::string, Json>{};
    const std::set<std::string> rawLeaves = raw_leaf_pointers(raw);
    for (const auto& [pointer, value] : resolvedLeaves) {
        if (out.applied) {
            auto in = inheritedLeaves.find(pointer);
            if (touched.count(pointer) != 0 || in == inheritedLeaves.end() || in->second != value) {
                out.sources[pointer] = SettingSource::Project;
                continue;
            }
        }
        auto def = defaultLeaves.find(pointer);
        out.sources[pointer] = rawLeaves.count(pointer) != 0 || def == defaultLeaves.end() || def->second != value ? SettingSource::You
                                                                                                                   : SettingSource::Default;
    }
    return out;
}

Result<AiConfig> load_resolved_config(std::string_view projectDir, std::string_view aiConfigPath, const EnvLookup& env) {
    // Without a project file there is nothing to resolve: exactly what load_config returns.
    if (projectDir.empty() || !fsys::is_regular_file(fsys::path(settings_path(projectDir)))) {
        return load_config(aiConfigPath, env);
    }
    auto resolved = resolve_ai_config(projectDir, aiConfigPath, env);
    if (!resolved) return resolved.error();
    return std::move(resolved->config);
}

// ---------------------------------------------------------------------------------------------------------------------
// The writer

namespace {

// The key order of the files this module writes: stable and the one the docs show.
Json ordered(const Json& ov) {
    auto reorder = [](const Json& obj, const std::vector<std::string>& order) {
        Json out = Json::object();
        for (const std::string& k : order)
            if (obj.contains(k)) out[k] = obj[k];
        for (auto it = obj.begin(); it != obj.end(); ++it)
            if (!out.contains(it.key())) out[it.key()] = it.value();
        return out;
    };
    Json out = reorder(ov, {"$schema", "roles", "limits", "assets", "assetSources", "savers", "mcpServers", "extensions"});
    auto each = [&](const char* section, const std::vector<std::string>& names, const std::vector<std::string>& inner) {
        if (!out.contains(section) || !out[section].is_object()) return;
        Json sec = reorder(out[section], names);
        if (!inner.empty()) {
            for (auto it = sec.begin(); it != sec.end(); ++it)
                if (it.value().is_object()) it.value() = reorder(it.value(), inner);
        }
        out[section] = std::move(sec);
    };
    each("roles", std::vector<std::string>(std::begin(kAllRoles), std::end(kAllRoles)), names_of(kRoleKeys));
    each("limits", names_of(kLimitKeys), {});
    each("assets", {"image", "sound", "music", "voice", "model3d"}, names_of(kAssetKeys));
    each("assetSources", {"images", "models", "audio", "fonts", "other", "onlyListed"}, {});
    each("savers", names_of(kSaverKeys), {});
    each("extensions", names_of(kExtensionGroups), {});
    return out;
}

void set_at(Json& root, const std::string& pointer, const Json& value) { root[Json::json_pointer(pointer)] = value; }

// Drops empty objects (not empty arrays: an empty site list or toolGroups is a value).
bool prune_empty(Json& j) {
    if (!j.is_object()) return false;
    for (auto it = j.begin(); it != j.end();) {
        if (prune_empty(it.value())) it = j.erase(it);
        else ++it;
    }
    return j.empty();
}

// Keeps the leaves of `ov` that change the inherited value. A model, effort or voice stays when its provider changes (the new
// provider would reset them: "the same model" would be lost).
Json normalize_overrides(const Json& ovIn, const AiConfig& inherited) {
    Json ov = ovIn;
    if (Json* s = ov.contains("assetSources") && ov["assetSources"].is_object() ? &ov["assetSources"] : nullptr) {
        for (auto it = s->begin(); it != s->end(); ++it) {
            if (!it.value().is_array()) continue;
            Json list = Json::array();
            for (const Json& e : it.value()) list.push_back(normalize_site(e));
            it.value() = std::move(list);
        }
    }
    const auto mine = leaves_of(ov);
    const auto base = leaves_of(settings_view(inherited));
    Json out = Json::object();
    for (const auto& [pointer, value] : mine) {
        auto in = base.find(pointer);
        bool keep = in == base.end() || in->second != value;
        if (!keep) {
            const auto slash = pointer.rfind('/');
            const std::string key = pointer.substr(slash + 1), parent = pointer.substr(0, slash);
            if (key == "model" || key == "effort" || key == "voice") {
                auto prov = mine.find(parent + "/provider");
                auto was = base.find(parent + "/provider");
                keep = prov != mine.end() && (was == base.end() || was->second != prov->second);
            }
        }
        if (keep) set_at(out, pointer, value);
    }
    prune_empty(out);
    return ordered(out);
}

Result<void> write_overrides(const std::string& projectDir, const std::string& userPath, const Json& overrides, bool recordTrust) {
    const std::string path = settings_path(projectDir);
    const std::string trustPath = trust_path_for(userPath);
    if (overrides.empty()) {
        std::error_code ec;
        fs::remove_file(fsys::path(path), ec);
        if (ec && fsys::exists(fsys::path(path))) {
            return make_error("Cannot remove '" + path + "': " + ec.message(), "Close any program that has the file open, then try again.");
        }
        (void)forget_project_ai_settings_trust(trustPath, projectDir);
        return {};
    }
    const std::string text = dump_json(overrides);
    if (auto ok = fs::write_text(path, text); !ok) return ok;
    if (!recordTrust) return {};
    if (auto ok = trust_project_ai_settings(trustPath, projectDir, sha256_hex(normalized_text(text))); !ok) {
        return make_error("The AI settings of the project were saved to " + path + " but FactorIA could not record that you accept them: " + ok.error().message,
                          ok.error().hint);
    }
    return {};
}

}  // namespace

Json project_overrides_from(const AiConfig& wanted, const AiConfig& inherited) {
    const Json wantedView = settings_view(wanted);
    const auto want = leaves_of(wantedView);
    const auto have = leaves_of(settings_view(inherited));
    Json out = Json::object();
    for (const auto& [pointer, value] : want) {
        auto in = have.find(pointer);
        if (in != have.end() && in->second == value) continue;
        const auto slash = pointer.rfind('/');
        const std::string key = pointer.substr(slash + 1);
        // An empty provider, model or effort is "not set": the file cannot say it.
        if ((key == "provider" || key == "model" || key == "effort") && value.is_string() && value.get<std::string>().empty()) continue;
        set_at(out, pointer, value);
    }
    // A provider that changes resets model, effort and voice: carry the wanted ones along.
    for (const auto& [pointer, value] : want) {
        const auto slash = pointer.rfind('/');
        if (pointer.substr(slash + 1) != "provider") continue;
        const std::string parent = pointer.substr(0, slash);
        if (!out.contains(Json::json_pointer(pointer))) continue;
        for (const char* k : {"model", "effort", "voice"}) {
            auto w = want.find(parent + "/" + k);
            if (w == want.end() || (w->second.is_string() && w->second.get<std::string>().empty())) continue;
            set_at(out, parent + "/" + k, w->second);
        }
    }
    prune_empty(out);
    return ordered(out);
}

Result<void> save_project_settings(std::string_view projectDir, const Json& overrides, std::string_view aiConfigPath, const EnvLookup& env) {
    if (projectDir.empty()) {
        return make_error("Cannot save the AI settings of a project: no project is open", "Open a project first; without one the settings are your defaults (ai.json).");
    }
    const std::string userPath = aiConfigPath.empty() ? default_config_path(env) : std::string(aiConfigPath);
    auto user = load_config(userPath, env);
    if (!user) return user.error();
    const std::string path = settings_path(projectDir);
    if (auto ok = validate_project_settings(overrides, *user, path); !ok) return ok;
    const Json normalized = normalize_overrides(overrides, *user);
    // The result must resolve: a file that fails ai.json's own checks (an asset-only provider on a role, the orchestrator off)
    // is refused here, not found at the next run.
    if (!normalized.empty()) {
        if (auto trial = apply_overrides(read_raw_user(userPath), normalized, *user, path); !trial) return trial.error();
    }
    return write_overrides(std::string(projectDir), userPath, normalized, true);
}

Result<void> reset_project_setting(std::string_view projectDir, std::string_view pointer, std::string_view aiConfigPath, const EnvLookup& env) {
    if (projectDir.empty()) return make_error("Cannot reset a project setting: no project is open");
    if (pointer.empty() || pointer.front() != '/') {
        return make_error("'" + std::string(pointer) + "' is not a JSON pointer", "Write it like /roles/artist/enabled (a leaf) or /roles/artist (a whole branch).");
    }
    const std::string userPath = aiConfigPath.empty() ? default_config_path(env) : std::string(aiConfigPath);
    (void)env;
    ProjectSettingsFile file = read_project_settings_file(projectDir);
    if (!file.exists) return {};
    if (!file.error.empty()) return make_error(file.error, "Fix the file or delete it, then reset again.");
    const bool wasAccepted = project_ai_settings_trusted(trust_path_for(userPath), projectDir, file.hash, nullptr, false);

    Json ov = file.overrides;
    const Json::json_pointer ptr(std::string{pointer});
    auto drop = [&](const Json::json_pointer& p) {
        if (!ov.contains(p)) return;
        Json::json_pointer parent = p.parent_pointer();
        const std::string key = p.back();
        Json& holder = ov[parent];
        if (holder.is_object()) holder.erase(key);
    };
    if (!ov.contains(ptr)) return {};
    drop(ptr);
    // The provider and what follows it go together.
    if (ptr.back() == "provider") {
        const Json::json_pointer parent = ptr.parent_pointer();
        for (const char* k : {"model", "effort", "voice"}) drop(parent / k);
    }
    prune_empty(ov);
    return write_overrides(std::string(projectDir), userPath, ordered(ov), wasAccepted);
}

Result<void> accept_project_settings(std::string_view projectDir, std::string_view expectedHash, std::string_view aiConfigPath, const EnvLookup& env) {
    if (projectDir.empty()) return make_error("Cannot accept AI settings: no project is open");
    const std::string userPath = aiConfigPath.empty() ? default_config_path(env) : std::string(aiConfigPath);
    ProjectSettingsFile file = read_project_settings_file(projectDir);
    if (!file.exists) return make_error("This project has no AI settings file (" + file.path + ") to accept");
    if (!file.error.empty()) return make_error(file.error, "Fix the file or delete it first.");
    if (!expectedHash.empty() && file.hash != expectedHash) {
        return make_error(file.path + " changed after it was shown to you", "Look at it again before accepting.");
    }
    auto user = load_config(userPath, env);
    if (!user) return user.error();
    if (auto ok = validate_project_settings(file.overrides, *user, file.path); !ok) return ok;
    return trust_project_ai_settings(trust_path_for(userPath), projectDir, file.hash);
}

}  // namespace fa::ai
