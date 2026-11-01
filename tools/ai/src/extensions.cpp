// Extensions (plugins, skills, hooks) in ai.json and in a project's .factoria/extensions.json: parse, validate, write, the
// per-project trust and the Claude Code deny-rule scan. docs/AI_PROVIDERS.md, "Extensions".
#include "fa/ai/extensions.h"

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <set>

#include "fa/ai/config.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using util::child;

const char* extension_kind_name(ExtensionKind k) {
    switch (k) {
        case ExtensionKind::Plugin: return "plugin";
        case ExtensionKind::Skill: return "skill";
        case ExtensionKind::Hooks: return "hooks";
    }
    return "?";
}

bool Extension::serves_role(std::string_view role) const {
    if (!enabled) return false;
    if (roles.empty()) {
        for (const char* r : kDefaultExtensionRoles)
            if (role == r) return true;
        return false;
    }
    return std::find(roles.begin(), roles.end(), role) != roles.end();
}

std::string extension_name_problem(std::string_view name) {
    if (name.empty()) return "the name is empty";
    if (name.size() > kMaxExtensionName)
        return "the name is longer than " + std::to_string(kMaxExtensionName) + " characters";
    for (char c : name) {
        const bool ok = std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-';
        if (!ok) return std::string("the name has the character '") + c + "', only letters, digits, _ and - are allowed";
    }
    return {};
}

namespace {

// Claude Code's hook events (docs.claude.com, "Hooks reference"). Anything else is a typo or an event this version of
// FactorIA has not heard of: the error lists these.
const std::vector<std::string>& hook_events() {
    static const std::vector<std::string> v = {
        "SessionStart",  "SessionEnd",       "Setup",         "UserPromptSubmit", "UserPromptExpansion", "PreToolUse",
        "PostToolUse",   "PostToolUseFailure", "PostToolBatch", "PermissionRequest", "PermissionDenied",   "Notification",
        "SubagentStart", "SubagentStop",     "Stop",          "StopFailure",      "TeammateIdle",        "TaskCreated",
        "TaskCompleted", "PreCompact",       "PostCompact",   "InstructionsLoaded", "ConfigChange",      "CwdChanged",
        "FileChanged",   "WorktreeCreate",   "WorktreeRemove", "Elicitation",     "ElicitationResult"};
    return v;
}

std::string join(const std::vector<std::string>& v) {
    std::string out;
    for (const auto& s : v) out += (out.empty() ? "" : ", ") + s;
    return out;
}

Error err(const std::string& message, const std::string& hint) { return Error{message, hint}; }

std::string clean_plugin_ref(const std::string& s) {
    const auto at = s.find('@');
    if (at == std::string::npos || at == 0 || at + 1 >= s.size() || s.find('@', at + 1) != std::string::npos) return {};
    for (unsigned char c : s)
        if (std::isspace(c)) return {};
    return s;
}

bool path_is_absolute_or_home(const std::string& p) {
    if (p == "~" || p.rfind("~/", 0) == 0 || p.rfind("~\\", 0) == 0) return true;
    return fsys::path(p).is_absolute();
}

bool has_dotdot(const std::string& p) {
    for (const auto& part : fsys::path(p))
        if (part == "..") return true;
    return false;
}

}  // namespace

Result<void> validate_hooks(const Json& hooks, std::string_view atIn) {
    const std::string at(atIn);
    if (!hooks.is_object()) {
        return err(at + ": the hooks are an object whose keys are events, for example {\"PostToolUse\": [{\"matcher\": "
                        "\"Edit|Write\", \"hooks\": [{\"type\": \"command\", \"command\": \"./check.sh\"}]}]}",
                   "This is Claude Code's hooks format (docs.claude.com, \"Hooks reference\").");
    }
    for (auto it = hooks.begin(); it != hooks.end(); ++it) {
        const std::string eventAt = at + "/" + it.key();
        if (std::find(hook_events().begin(), hook_events().end(), it.key()) == hook_events().end()) {
            std::string hint = fa::did_you_mean(it.key(), hook_events());
            if (it.key() == "hooks") hint = "A {\"hooks\": {...}} wrapper goes around the events: paste only the events object, or paste the wrapper in AI settings > Extensions. " + hint;
            return err(eventAt + ": '" + it.key() + "' is not a Claude Code hook event",
                       hint + (hint.empty() ? "" : " ") + "Events: " + join(hook_events()) + ".");
        }
        if (!it.value().is_array()) {
            return err(eventAt + ": an event holds a list of groups, [{\"matcher\": \"...\", \"hooks\": [...]}]",
                       "Wrap the group in [ ].");
        }
        std::size_t gi = 0;
        for (const Json& group : it.value()) {
            const std::string groupAt = eventAt + "/" + std::to_string(gi++);
            if (!group.is_object()) return err(groupAt + ": a group is an object {\"matcher\": \"...\", \"hooks\": [...]}", "");
            for (auto g = group.begin(); g != group.end(); ++g) {
                if (g.key() != "matcher" && g.key() != "hooks") {
                    return err(groupAt + "/" + g.key() + ": unknown property '" + g.key() + "'",
                               fa::did_you_mean(g.key(), std::vector<std::string>{"matcher", "hooks"}));
                }
            }
            if (const Json* m = child(group, "matcher"); m && !m->is_string())
                return err(groupAt + "/matcher: the matcher is a string such as \"Edit|Write\"", "Use \"\" or leave it out to match everything.");
            const Json* handlers = child(group, "hooks");
            if (!handlers || !handlers->is_array() || handlers->empty()) {
                return err(groupAt + "/hooks: a group needs its list of hooks, [{\"type\": \"command\", \"command\": \"...\"}]", "");
            }
            std::size_t hi = 0;
            for (const Json& h : *handlers) {
                const std::string hookAt = groupAt + "/hooks/" + std::to_string(hi++);
                if (!h.is_object()) return err(hookAt + ": a hook is an object {\"type\": \"command\", \"command\": \"...\"}", "");
                const std::string type = util::str(h, "type");
                const std::vector<std::string> types = {"command", "http", "prompt", "agent"};
                if (type.empty() || std::find(types.begin(), types.end(), type) == types.end()) {
                    return err(hookAt + "/type: " + (type.empty() ? "a hook needs its \"type\"" : "unknown hook type '" + type + "'"),
                               type.empty() ? "Use \"command\" to run a program." : fa::did_you_mean(type, types));
                }
                if (type == "command" && util::str(h, "command").empty())
                    return err(hookAt + "/command: a hook of type \"command\" needs the program to run", "Add \"command\": \"./check.sh\".");
                if (type == "http" && util::str(h, "url").empty())
                    return err(hookAt + "/url: a hook of type \"http\" needs its address", "Add \"url\": \"https://...\".");
            }
        }
    }
    return {};
}

Result<Json> parse_hooks_json(const Json& pasted, std::string_view atIn) {
    const std::string at(atIn);
    const Json* events = &pasted;
    if (pasted.is_object() && pasted.contains("hooks") && pasted["hooks"].is_object()) events = &pasted["hooks"];
    if (auto ok = validate_hooks(*events, events == &pasted ? at : at + "/hooks"); !ok) return ok.error();
    return *events;
}

namespace {

Result<void> read_common(const Json& entry, const std::string& at, Extension& e) {
    e.note = util::str(entry, "note");
    if (const Json* n = child(entry, "note"); n && !n->is_string()) return err(at + "/note: the note is text", "");
    if (const Json* en = child(entry, "enabled")) {
        if (!en->is_boolean()) return err(at + "/enabled: true or false", "");
        e.enabled = en->get<bool>();
    }
    if (const Json* r = child(entry, "roles")) {
        if (!r->is_array()) return err(at + "/roles: a list of role names, for example [\"worker\"]", "");
        std::vector<std::string> roleNames(std::begin(kAllRoles), std::end(kAllRoles));
        std::size_t index = 0;
        for (const Json& v : *r) {
            const std::string role = v.is_string() ? v.get<std::string>() : std::string();
            if (!is_known_role(role)) {
                return err(at + "/roles/" + std::to_string(index) + ": unknown role '" + role + "'",
                           fa::did_you_mean(role, roleNames) + " Roles: " + join(roleNames) + ".");
            }
            if (std::find(e.roles.begin(), e.roles.end(), role) == e.roles.end()) e.roles.push_back(role);
            ++index;
        }
    }
    return {};
}

Result<Extension> parse_entry(ExtensionKind kind, const std::string& name, const Json& entry, const std::string& at,
                              const std::string& source) {
    if (auto problem = extension_name_problem(name); !problem.empty()) {
        return err(at + ": '" + name + "' cannot be an extension name: " + problem,
                   "Use a short name such as notes or log-edits (letters, digits, _ and -).");
    }
    if (!entry.is_object()) {
        const char* example = kind == ExtensionKind::Plugin ? "{\"path\": \"~/plugins/notes\"}"
                              : kind == ExtensionKind::Skill ? "{\"path\": \"~/skills/gdd\"}"
                                                             : "{\"hooks\": {\"Stop\": [{\"hooks\": [{\"type\": \"command\", \"command\": \"./done.sh\"}]}]}}";
        return err(at + ": " + extension_kind_name(kind) + " '" + name + "' is an object, for example " + example,
                   "See docs/AI_PROVIDERS.md, \"Extensions\".");
    }
    std::vector<std::string> known = {"note", "roles", "enabled"};
    if (kind == ExtensionKind::Plugin) { known.push_back("path"); known.push_back("plugin"); }
    if (kind == ExtensionKind::Skill) known.push_back("path");
    if (kind == ExtensionKind::Hooks) known.push_back("hooks");
    for (auto it = entry.begin(); it != entry.end(); ++it) {
        if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
        return err(at + "/" + it.key() + ": unknown property '" + it.key() + "'", fa::did_you_mean(it.key(), known));
    }

    Extension e;
    e.kind = kind;
    e.name = name;
    e.source = source;
    if (auto ok = read_common(entry, at, e); !ok) return ok.error();

    const bool project = source == "project";
    if (kind == ExtensionKind::Hooks) {
        const Json* h = child(entry, "hooks");
        if (!h) return err(at + "/hooks: a hooks entry needs its \"hooks\" object", "Add \"hooks\": {\"PostToolUse\": [...]}.");
        if (auto ok = validate_hooks(*h, at + "/hooks"); !ok) return ok.error();
        e.hooks = *h;
        return e;
    }

    const Json* pathJson = child(entry, "path");
    if (pathJson && !pathJson->is_string()) return err(at + "/path: the path is text", "");
    e.path = util::str(entry, "path");
    const bool hasPath = pathJson != nullptr;
    if (hasPath && e.path.empty()) return err(at + "/path: the path is empty", "Write the folder of the " + std::string(extension_kind_name(kind)) + ".");

    if (kind == ExtensionKind::Plugin) {
        const Json* refJson = child(entry, "plugin");
        if (refJson && !refJson->is_string()) return err(at + "/plugin: text such as \"name@marketplace\"", "");
        e.plugin = util::str(entry, "plugin");
        const bool hasRef = refJson != nullptr;
        if (hasPath == hasRef) {
            return err(at + ": a plugin sets " + (hasPath ? "only one of" : "one of") + " \"path\" (a directory or a .zip) or \"plugin\" (name@marketplace)",
                       hasPath ? "Remove one of them." : "For a plugin you installed with `claude plugin install name@marketplace` write \"plugin\": \"name@marketplace\"; for a folder, \"path\".");
        }
        if (hasRef && clean_plugin_ref(e.plugin).empty()) {
            return err(at + "/plugin: '" + e.plugin + "' is not name@marketplace",
                       "Write the plugin name, an @ and the marketplace it came from, for example superpowers@claude-plugins-official "
                       "(`claude plugin list` shows them).");
        }
    } else if (!hasPath) {
        return err(at + "/path: a skill needs the folder it lives in", "Add \"path\": \"~/skills/gdd\" (a folder with a SKILL.md, or a folder of skill folders).");
    }

    if (kind == ExtensionKind::Skill && is_engine_skill_path(e.path)) {
        if (e.path.size() == kEngineSkillPrefix.size())
            return err(at + "/path: '" + e.path + "' names no skill", "Write engine:<skill name>, for example \"engine:custom-shaders\" (skills.list shows the names).");
    } else if (hasPath) {
        if (!project && !path_is_absolute_or_home(e.path)) {
            return err(at + "/path: '" + e.path + "' is relative, and ai.json is not inside any folder it could be relative to",
                       "Write the full path, or start with ~ for your home folder: \"~/" + e.path + "\".");
        }
        if (project && kind == ExtensionKind::Skill) {
            if (e.path.rfind("~", 0) == 0 || fsys::path(e.path).is_absolute() || has_dotdot(e.path)) {
                return err(at + "/path: '" + e.path + "' leaves the project",
                           "A skill of a project must live inside it: write a path relative to the project, such as \"skills/gdd\".");
            }
        }
    }
    return e;
}

}  // namespace

Result<ExtensionsConfig> parse_extensions(const Json& section, std::string_view atIn, std::string_view sourceIn) {
    const std::string at(atIn);
    const std::string source(sourceIn);
    const bool project = source == "project";
    if (!section.is_object()) {
        return err(at + ": \"extensions\" is an object with \"plugins\", \"skills\" and \"hooks\"",
                   "For example {\"plugins\": {\"notes\": {\"path\": \"~/plugins/notes\"}}}. See docs/AI_PROVIDERS.md, \"Extensions\".");
    }
    std::vector<std::string> known = {"plugins", "skills", "hooks"};
    if (!project) known.push_back("inheritUserPlugins");
    for (auto it = section.begin(); it != section.end(); ++it) {
        if (project && it.key() == "$schema") continue;
        if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
        std::string hint = fa::did_you_mean(it.key(), known);
        if (project && it.key() == "inheritUserPlugins")
            hint = "inheritUserPlugins is a setting of your own ai.json: a project cannot decide which of your extensions load.";
        return err(at + "/" + it.key() + ": unknown property '" + it.key() + "'", hint);
    }
    ExtensionsConfig cfg;
    if (const Json* inherit = child(section, "inheritUserPlugins")) {
        if (!inherit->is_boolean()) return err(at + "/inheritUserPlugins: true or false", "");
        cfg.inheritUserPlugins = inherit->get<bool>();
    }
    const std::pair<const char*, ExtensionKind> groups[] = {
        {"plugins", ExtensionKind::Plugin}, {"skills", ExtensionKind::Skill}, {"hooks", ExtensionKind::Hooks}};
    for (const auto& [key, kind] : groups) {
        const Json* group = child(section, key);
        if (!group) continue;
        if (!group->is_object()) {
            return err(at + "/" + key + ": \"" + key + "\" is an object with one entry per extension, keyed by its name",
                       "For example {\"notes\": {...}}.");
        }
        for (auto it = group->begin(); it != group->end(); ++it) {
            auto e = parse_entry(kind, it.key(), it.value(), at + "/" + key + "/" + it.key(), source);
            if (!e) return e.error();
            cfg.entries.push_back(std::move(*e));
        }
    }
    return cfg;
}

Json extension_to_json(const Extension& e) {
    Json j = Json::object();
    switch (e.kind) {
        case ExtensionKind::Plugin:
            if (!e.plugin.empty()) j["plugin"] = e.plugin;
            else j["path"] = e.path;
            break;
        case ExtensionKind::Skill: j["path"] = e.path; break;
        case ExtensionKind::Hooks: j["hooks"] = e.hooks.is_object() ? e.hooks : Json::object(); break;
    }
    if (!e.note.empty()) j["note"] = e.note;
    if (!e.roles.empty()) j["roles"] = e.roles;
    if (!e.enabled) j["enabled"] = false;
    return j;
}

Json extensions_to_json(const ExtensionsConfig& cfg, bool includeSettings) {
    Json j = Json::object();
    if (includeSettings && !cfg.inheritUserPlugins) j["inheritUserPlugins"] = false;
    const std::pair<const char*, ExtensionKind> groups[] = {
        {"plugins", ExtensionKind::Plugin}, {"skills", ExtensionKind::Skill}, {"hooks", ExtensionKind::Hooks}};
    for (const auto& [key, kind] : groups) {
        Json group = Json::object();
        for (const Extension& e : cfg.entries)
            if (e.kind == kind) group[e.name] = extension_to_json(e);
        if (!group.empty()) j[key] = std::move(group);
    }
    return j;
}

namespace {

// Names unique per kind and valid: the writers refuse anything the parser would refuse.
Result<void> check_writable(const std::vector<Extension>& entries) {
    std::set<std::pair<int, std::string>> seen;
    for (const Extension& e : entries) {
        if (auto problem = extension_name_problem(e.name); !problem.empty())
            return err("Cannot save the " + std::string(extension_kind_name(e.kind)) + " '" + e.name + "': " + problem,
                       "Use a short name such as notes (letters, digits, _ and -).");
        if (!seen.insert({static_cast<int>(e.kind), e.name}).second)
            return err("Two " + std::string(extension_kind_name(e.kind)) + " entries are called '" + e.name + "'", "Give each its own name.");
    }
    return {};
}

}  // namespace

Result<void> save_extensions(const ExtensionsConfig& cfg, std::string_view path) {
    Json j = Json::object();
    std::error_code ec;
    if (fsys::exists(fsys::path(path), ec)) {
        auto text = fs::read_text(path);
        if (!text) return text.error();
        auto parsed = fa::parse_json(*text, path);
        if (!parsed) return parsed.error();
        if (!parsed->is_object()) {
            return err("AI config '" + std::string(path) + "' is not a JSON object", "Fix or delete the file, then save the extensions again.");
        }
        j = std::move(*parsed);
    }
    ExtensionsConfig user;
    user.inheritUserPlugins = cfg.inheritUserPlugins;
    for (const Extension& e : cfg.entries)
        if (!e.from_project()) user.entries.push_back(e);
    if (auto ok = check_writable(user.entries); !ok) return ok;
    if (user.empty()) j.erase("extensions");
    else j["extensions"] = extensions_to_json(user, true);
    return write_private_file(path, dump_json(j));
}

// --- the project file ------------------------------------------------------------------------------------------------

namespace {

fsys::path absolute_project(std::string_view projectDir) {
    std::error_code ec;
    fsys::path p = fsys::absolute(fsys::path(std::string(projectDir)), ec);
    return ec ? fsys::path(std::string(projectDir)) : p.lexically_normal();
}

}  // namespace

ProjectExtensions load_project_extensions(std::string_view projectDir) {
    ProjectExtensions out;
    const fsys::path file = absolute_project(projectDir) / ".factoria" / "extensions.json";
    out.path = file.string();
    std::error_code ec;
    if (!fsys::is_regular_file(file, ec)) return out;
    out.exists = true;
    auto text = fs::read_text(out.path);
    if (!text) {
        out.error = text.error().message;
        return out;
    }
    out.hash = sha256_hex(*text);
    auto parsed = fa::parse_json(*text, out.path);
    if (!parsed) {
        out.error = parsed.error().to_string();
        return out;
    }
    auto cfg = parse_extensions(*parsed, "", "project");
    if (!cfg) {
        out.error = out.path + ": " + cfg.error().to_string();
        return out;
    }
    out.entries = std::move(cfg->entries);
    return out;
}

Result<void> save_project_extensions(const std::vector<Extension>& entries, std::string_view projectDir) {
    const fsys::path file = absolute_project(projectDir) / ".factoria" / "extensions.json";
    std::vector<Extension> project;
    for (Extension e : entries) {
        e.source = "project";
        project.push_back(std::move(e));
    }
    if (auto ok = check_writable(project); !ok) return ok;
    std::error_code ec;
    if (project.empty()) {
        fsys::remove(file, ec);
        return {};
    }
    ExtensionsConfig cfg;
    cfg.entries = std::move(project);
    return fs::write_text(file.string(), dump_json(extensions_to_json(cfg, false)));
}

// --- trust -----------------------------------------------------------------------------------------------------------

std::string canonical_project_key(std::string_view projectDir) {
    std::error_code ec;
    fsys::path p = fsys::weakly_canonical(absolute_project(projectDir), ec);
    if (ec) p = absolute_project(projectDir);
    return p.generic_string();
}

std::string extensions_trust_path(std::string_view aiConfigPath) {
    fsys::path p(std::string{aiConfigPath});
    return (p.has_parent_path() ? p.parent_path() / "ai-trust.json" : fsys::path("ai-trust.json")).string();
}

namespace {

Json read_trust(std::string_view trustPath) {
    Json root = Json::object();
    std::error_code ec;
    if (trustPath.empty() || !fsys::exists(fsys::path(std::string(trustPath)), ec)) return root;
    auto text = fs::read_text(trustPath);
    if (!text) return root;
    Json parsed = util::parse(*text);  // a damaged file means "nothing is trusted"
    if (parsed.is_object()) root = std::move(parsed);
    if (!root.contains("projects") || !root["projects"].is_object()) root["projects"] = Json::object();
    root["version"] = 1;
    return root;
}

Result<void> write_trust(std::string_view trustPath, Json root) {
    if (trustPath.empty()) return err("Cannot keep the trust: no place for it", "Set FACTORIA_AI_CONFIG or HOME so FactorIA knows where your ai.json lives.");
    return write_private_file(trustPath, dump_json(root));
}

}  // namespace

bool project_extensions_trusted(std::string_view trustPath, std::string_view projectDir, std::string_view hash, bool* dropped,
                                bool dropStale, std::string_view claudeHash) {
    if (dropped) *dropped = false;
    if (hash.empty() && claudeHash.empty()) return false;
    Json root = read_trust(trustPath);
    if (!root.contains("projects")) return false;
    Json& projects = root["projects"];
    const std::string key = canonical_project_key(projectDir);
    auto it = projects.find(key);
    if (it == projects.end()) return false;
    if (util::str(*it, "extensionsHash") == hash && util::str(*it, "claudeSettingsHash") == claudeHash) return true;
    if (dropped) *dropped = true;
    if (!dropStale) return false;
    projects.erase(key);  // a file changed since the user trusted the project: the trust is gone
    (void)write_trust(trustPath, std::move(root));
    return false;
}

Result<void> trust_project_extensions(std::string_view trustPath, std::string_view projectDir, std::string_view hash,
                                      std::string_view claudeHash) {
    if (hash.empty() && claudeHash.empty())
        return err("This project has nothing to trust: no .factoria/extensions.json and nothing in .claude/settings*.json that needs trust",
                   "Add extensions to the project first.");
    Json root = read_trust(trustPath);
    if (!root.contains("projects")) {
        root["projects"] = Json::object();
        root["version"] = 1;
    }
    Json record = Json::object();
    record["extensionsHash"] = std::string(hash);
    record["claudeSettingsHash"] = std::string(claudeHash);
    root["projects"][canonical_project_key(projectDir)] = std::move(record);
    return write_trust(trustPath, std::move(root));
}

Result<void> forget_project_trust(std::string_view trustPath, std::string_view projectDir) {
    Json root = read_trust(trustPath);
    if (!root.contains("projects")) return {};
    if (root["projects"].erase(canonical_project_key(projectDir)) == 0) return {};
    return write_trust(trustPath, std::move(root));
}

// --- Claude Code's project settings ----------------------------------------------------------------------------------

namespace {

bool non_empty_container(const Json* v) { return v && ((v->is_object() || v->is_array()) && !v->empty()); }

// "a, b, c" of the first few strings, then "+N more".
std::string joined(const std::vector<std::string>& names, std::size_t most = 5) {
    std::string out;
    for (std::size_t i = 0; i < names.size() && i < most; ++i) out += (i ? ", " : "") + names[i];
    if (names.size() > most) out += " +" + std::to_string(names.size() - most) + " more";
    return out;
}

bool is_empty_value(const Json& v) {
    return v.is_null() || (v.is_string() && v.get<std::string>().empty()) || ((v.is_object() || v.is_array()) && v.empty());
}

// The rule for a project's Claude Code settings: a key counts (needs the user's trust) UNLESS it is known to run nothing, send
// requests nowhere new and widen no permission. This is that list; in doubt a key stays off it, and a key a newer Claude Code
// adds needs the trust until it is added here. Display, text and housekeeping settings, and keys that only restrict.
bool is_harmless_setting(const std::string& key) {
    static const char* const kHarmless[] = {
        "$schema",           "model",                   "outputStyle",         "language",         "cleanupPeriodDays",
        "includeCoAuthoredBy", "includeGitInstructions", "spinnerTipsEnabled", "alwaysThinkingEnabled", "disableAllHooks",
        "respectGitignore",  "showTurnDuration",        "prefersReducedMotion", "companyAnnouncements", "attribution",
        "forceLoginMethod",  "forceLoginOrgUUID",       "disabledMcpjsonServers",
    };
    for (const char* k : kHarmless)
        if (key == k) return true;
    return false;
}

// Keys settings_grants looks into itself (each can be harmless or not depending on its value).
bool is_judged_setting(const std::string& key) {
    static const char* const kJudged[] = {
        "hooks", "enabledPlugins", "extraKnownMarketplaces", "statusLine", "fileSuggestion", "apiKeyHelper", "awsAuthRefresh",
        "awsCredentialExport", "otelHeadersHelper", "enableAllProjectMcpServers", "enabledMcpjsonServers", "env", "permissions",
    };
    for (const char* k : kJudged)
        if (key == k) return true;
    return false;
}

// What a Claude Code settings file asks for that needs the user's trust: a program to run (hooks, plugins, commands) and what
// widens the AI's reach without a dialog (-p mode has none): env (a base URL or a proxy sends the requests, with the user's key,
// elsewhere; BASH_ENV, NODE_OPTIONS, PATH, LD_PRELOAD change what programs do), permissions.allow, a defaultMode other than
// "default", additionalDirectories. permissions.deny and ask only restrict, so they do not count. Any other non-empty key that
// is not in is_harmless_setting counts as "unknown setting KEY".
std::vector<std::string> settings_grants(const Json& s) {
    std::vector<std::string> out;
    if (!s.is_object()) return out;
    if (const Json* hooks = child(s, "hooks"); non_empty_container(hooks) && hooks->is_object()) {
        std::string events;
        for (auto it = hooks->begin(); it != hooks->end(); ++it) {
            if (!it.value().is_array() || it.value().empty()) continue;
            events += (events.empty() ? "" : ", ") + it.key();
        }
        if (!events.empty()) out.push_back("hooks (" + events + ")");
    }
    if (const Json* plugins = child(s, "enabledPlugins"); plugins && plugins->is_object()) {
        std::string names;
        for (auto it = plugins->begin(); it != plugins->end(); ++it) {
            const bool on = it.value().is_boolean() ? it.value().get<bool>() : !it.value().is_null();
            if (on) names += (names.empty() ? "" : ", ") + it.key();
        }
        if (!names.empty()) out.push_back("enabledPlugins (" + names + ")");
    }
    if (const Json* mk = child(s, "extraKnownMarketplaces"); non_empty_container(mk) && mk->is_object()) {
        std::string names;
        for (auto it = mk->begin(); it != mk->end(); ++it) names += (names.empty() ? "" : ", ") + it.key();
        out.push_back("extraKnownMarketplaces (" + names + ")");
    }
    for (const char* key : {"statusLine", "fileSuggestion"}) {
        const Json* v = child(s, key);
        if (v && !v->is_null() && !(v->is_object() && v->empty())) out.push_back(key);
    }
    for (const char* key : {"apiKeyHelper", "awsAuthRefresh", "awsCredentialExport", "otelHeadersHelper"}) {
        const Json* v = child(s, key);
        if (v && v->is_string() && !v->get<std::string>().empty()) out.push_back(key);
    }
    // Servers of the project's .mcp.json run programs, and these settings approve them without asking.
    if (const Json* v = child(s, "enableAllProjectMcpServers"); v && v->is_boolean() && v->get<bool>())
        out.push_back("enableAllProjectMcpServers");
    if (const Json* v = child(s, "enabledMcpjsonServers"); non_empty_container(v)) out.push_back("enabledMcpjsonServers");
    if (const Json* env = child(s, "env"); non_empty_container(env) && env->is_object()) {
        std::vector<std::string> names;
        for (auto it = env->begin(); it != env->end(); ++it) names.push_back(it.key());
        out.push_back("env (" + joined(names) + ")");
    }
    if (const Json* perms = child(s, "permissions"); perms && perms->is_object()) {
        if (const Json* allow = child(*perms, "allow"); allow && allow->is_array()) {
            std::vector<std::string> rules;
            for (const Json& r : *allow)
                if (r.is_string() && !r.get<std::string>().empty()) rules.push_back(r.get<std::string>());
            if (!rules.empty()) out.push_back("permissions.allow (" + joined(rules) + ")");
        }
        if (const Json* mode = child(*perms, "defaultMode"); mode && !is_empty_value(*mode) &&
                                                              !(mode->is_string() && mode->get<std::string>() == "default"))
            out.push_back("permissions.defaultMode (" + (mode->is_string() ? mode->get<std::string>() : std::string("unrecognized value")) + ")");
        if (const Json* dirs = child(*perms, "additionalDirectories"); dirs && !is_empty_value(*dirs))
            out.push_back("permissions.additionalDirectories (" + (dirs->is_array() ? std::to_string(dirs->size()) : std::string("unrecognized value")) + ")");
        // Anything else under permissions is a key this version does not know.
        for (auto it = perms->begin(); it != perms->end(); ++it) {
            const std::string& key = it.key();
            if (key == "allow" || key == "defaultMode" || key == "additionalDirectories") continue;  // judged above
            if (key == "deny" || key == "ask" || key == "disableBypassPermissionsMode") continue;    // only restrict
            if (!is_empty_value(it.value())) out.push_back("unknown setting permissions." + key);
        }
    }
    // The rule is "trust unless known harmless", so a key a newer Claude Code adds needs the trust until it is listed here.
    for (auto it = s.begin(); it != s.end(); ++it) {
        const std::string& key = it.key();
        if (is_judged_setting(key) || is_harmless_setting(key) || is_empty_value(it.value())) continue;
        out.push_back("unknown setting " + key);  // the name only: the value may be a secret
    }
    return out;
}

}  // namespace

std::vector<std::string> ClaudeProjectSettings::describe() const {
    std::vector<std::string> out;
    for (const ClaudeSettingsFile& f : files) {
        if (f.grants.empty()) continue;
        std::string line = ".claude/" + fsys::path(f.path).filename().string() + ": ";
        for (std::size_t i = 0; i < f.grants.size(); ++i) line += (i ? ", " : "") + f.grants[i];
        out.push_back(std::move(line));
    }
    return out;
}

ClaudeProjectSettings load_claude_project_settings(std::string_view projectDir) {
    ClaudeProjectSettings out;
    if (projectDir.empty()) return out;
    const fsys::path dir = absolute_project(projectDir) / ".claude";
    std::string material;
    bool runs = false;
    for (const char* name : {"settings.json", "settings.local.json"}) {
        ClaudeSettingsFile f;
        f.path = (dir / name).string();
        std::error_code ec;
        std::string bytes;
        if (fsys::is_regular_file(f.path, ec)) {
            f.exists = true;
            if (auto text = fs::read_text(f.path)) {
                bytes = std::move(*text);
                f.hash = sha256_hex(bytes);
                auto parsed = fa::parse_json(bytes, f.path);
                if (parsed) {
                    f.grants = settings_grants(*parsed);
                } else {
                    f.error = parsed.error().message;
                }
            } else {
                f.error = text.error().message;
            }
        }
        runs = runs || !f.grants.empty();
        material += std::string(name) + '\n' + (f.exists ? "1" : "0") + '\n' + f.hash + '\n';
        out.files.push_back(std::move(f));
    }
    if (runs) out.hash = sha256_hex(material);
    return out;
}

// --- deny rules -----------------------------------------------------------------------------------------------------

std::vector<DeniedTool> find_denied_factoria_tools(std::string_view projectDir) {
    std::vector<DeniedTool> out;
    if (projectDir.empty()) return out;
    const fsys::path dir = absolute_project(projectDir) / ".claude";
    for (const char* name : {"settings.json", "settings.local.json"}) {
        const std::string file = (dir / name).string();
        std::error_code ec;
        if (!fsys::is_regular_file(file, ec)) continue;
        auto text = fs::read_text(file);
        if (!text) continue;
        const Json settings = util::parse(*text);
        const Json* perms = child(settings, "permissions");
        const Json* deny = perms ? child(*perms, "deny") : nullptr;
        if (!deny || !deny->is_array()) continue;
        for (const Json& r : *deny) {
            if (!r.is_string()) continue;
            std::string rule = r.get<std::string>();
            while (!rule.empty() && std::isspace(static_cast<unsigned char>(rule.back()))) rule.pop_back();
            while (!rule.empty() && std::isspace(static_cast<unsigned char>(rule.front()))) rule.erase(rule.begin());
            DeniedTool d;
            d.file = file;
            d.rule = rule;
            if (rule == "mcp__factoria" || rule == "mcp__factoria__*") {
                d.tool = "all FactorIA tools";
            } else if (rule.rfind("mcp__factoria__", 0) == 0 && rule.size() > 15) {
                d.tool = rule.substr(15);
            } else {
                continue;
            }
            d.fix = "Remove \"" + rule + "\" from permissions.deny in " + file +
                    " (a deny rule wins over the --allowedTools FactorIA passes, so nothing else restores it).";
            out.push_back(std::move(d));
        }
    }
    return out;
}

std::string format_denied_tool(const DeniedTool& d) {
    return "Claude Code settings deny " + d.tool + ": the rule \"" + d.rule + "\" in " + d.file + " removes " +
           (d.tool == "all FactorIA tools" ? "them" : "it") + " from every Claude Code run in this project. " + d.fix;
}

// --- helpers ----------------------------------------------------------------------------------------------------------

std::string expand_home(const std::string& path, const ExtensionEnv& env) {
    if (path != "~" && path.rfind("~/", 0) != 0 && path.rfind("~\\", 0) != 0) return path;
    std::string home = env ? env("HOME") : std::string();
    if (home.empty() && env) home = env("USERPROFILE");
    if (home.empty()) return path;
    return path == "~" ? home : (fsys::path(home) / path.substr(2)).string();
}

std::string resolve_extension_path(const Extension& e, std::string_view projectDir, const ExtensionEnv& env) {
    fsys::path p(expand_home(e.path, env));
    if (p.is_relative() && !projectDir.empty()) p = absolute_project(projectDir) / p;
    return p.lexically_normal().string();
}

}  // namespace fa::ai
