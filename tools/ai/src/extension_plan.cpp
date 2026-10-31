// What one run receives from the extensions, and the reports about it. docs/AI_PROVIDERS.md, "Extensions".
#include "fa/ai/extension_plan.h"

#include <algorithm>
#include <filesystem>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

namespace fsys = std::filesystem;
using util::child;

namespace {

bool argv_has(const ProviderConfig& p, const char* placeholder) {
    return std::any_of(p.argv.begin(), p.argv.end(), [&](const std::string& a) { return a.find(placeholder) != std::string::npos; });
}

const char* kApiSentence = "the API providers (anthropic, openai-compatible) do not use extensions yet";

// Why `kind` cannot reach this provider, and what to do. Both empty when it can.
void unsupported(const ProviderConfig& p, ExtensionKind kind, std::string& reason, std::string& fix) {
    reason.clear();
    fix.clear();
    switch (p.kind) {
        case ProviderKind::ClaudeCode: return;
        case ProviderKind::Codex:
            reason = "FactorIA could not verify how Codex takes plugins, skills or hooks, so it passes none to provider '" + p.name + "'";
            fix = "Give the role a Claude Code provider to run it with extensions.";
            return;
        case ProviderKind::GenericCli:
            if (kind == ExtensionKind::Plugin) {
                if (argv_has(p, "{plugin_dirs}")) return;
                reason = "the \"argv\" of provider '" + p.name + "' has no {plugin_dirs}";
                fix = "Add the flag of your CLI that takes a plugin folder and {plugin_dirs} after it, for example \"--plugin-dir\", \"{plugin_dirs}\".";
            } else if (kind == ExtensionKind::Hooks) {
                if (argv_has(p, "{settings}")) return;
                reason = "the \"argv\" of provider '" + p.name + "' has no {settings}";
                fix = "Add the flag of your CLI that takes a settings file and {settings} after it, for example \"--settings\", \"{settings}\".";
            } else {
                reason = "a generic CLI cannot take a skill folder: skills are a Claude Code concept";
                fix = "Put the skill in a plugin folder and list it under \"plugins\" (with {plugin_dirs} in the argv), or use a Claude Code provider.";
            }
            return;
        case ProviderKind::Anthropic:
        case ProviderKind::OpenAICompatible:
            reason = std::string(kApiSentence) + " (provider '" + p.name + "')";
            fix = "Give the role a Claude Code provider to run it with extensions.";
            return;
        default:
            reason = "provider '" + p.name + "' does not use extensions";
            fix = "Give the role a Claude Code provider to run it with extensions.";
            return;
    }
}

EnvLookup env_of(const ExtensionContext& ctx) { return ctx.env ? EnvLookup(ctx.env) : system_env(); }

bool inside(const fsys::path& root, const fsys::path& p) {
    std::error_code ec;
    const fsys::path r = fsys::weakly_canonical(root, ec);
    const fsys::path c = fsys::weakly_canonical(p, ec);
    auto rit = r.begin();
    auto cit = c.begin();
    for (; rit != r.end(); ++rit, ++cit)
        if (cit == c.end() || *rit != *cit) return false;
    return true;
}

// ~/.claude/plugins/installed_plugins.json (or $CLAUDE_CONFIG_DIR/...)
fsys::path installed_plugins_file(const EnvLookup& env) {
    std::string dir = env("CLAUDE_CONFIG_DIR");
    if (dir.empty()) {
        const std::string home = expand_home("~", env);
        if (home == "~") return {};
        dir = (fsys::path(home) / ".claude").string();
    }
    return fsys::path(dir) / "plugins" / "installed_plugins.json";
}

// The folder of an installed Claude Code plugin "name@marketplace" for `projectDir`. Empty path + reason when none.
fsys::path installed_plugin_path(const std::string& ref, std::string_view projectDir, const EnvLookup& env, std::string& problem,
                                 std::string& fix) {
    const fsys::path file = installed_plugins_file(env);
    fix = "Install it with `claude plugin install " + ref + "` (Claude Code), then try again.";
    if (file.empty()) {
        problem = "no home folder to look for " + ref;
        fix = "Set HOME so FactorIA can read ~/.claude/plugins/installed_plugins.json.";
        return {};
    }
    std::error_code ec;
    if (!fsys::is_regular_file(file, ec)) {
        problem = "Claude Code has no installed plugins (" + file.string() + " does not exist), so '" + ref + "' is not installed";
        return {};
    }
    auto text = fs::read_text(file.string());
    const Json doc = text ? util::parse(*text) : Json();
    const Json* plugins = child(doc, "plugins");
    const Json* entries = plugins ? child(*plugins, ref.c_str()) : nullptr;
    if (!entries || !entries->is_array() || entries->empty()) {
        problem = "the plugin '" + ref + "' is not installed (not in " + file.string() + ")";
        return {};
    }
    const std::string project = projectDir.empty() ? std::string() : canonical_project_key(projectDir);
    const Json* chosen = nullptr;
    auto path_of = [&](const Json& e) { return util::str(e, "installPath"); };
    for (const Json& e : *entries) {  // installed for this very project
        const std::string pp = util::str(e, "projectPath");
        if (!pp.empty() && !project.empty() && canonical_project_key(pp) == project && !path_of(e).empty()) { chosen = &e; break; }
    }
    if (!chosen)
        for (const Json& e : *entries)
            if (util::str(e, "scope") == "user" && !path_of(e).empty()) { chosen = &e; break; }
    if (!chosen)
        for (const Json& e : *entries)
            if (util::str(e, "projectPath").empty() && !path_of(e).empty()) { chosen = &e; break; }
    if (!chosen) {
        problem = "the plugin '" + ref + "' is installed only for other projects";
        fix = "Install it for the user with `claude plugin install " + ref + " --scope user`, or for this project from its folder.";
        return {};
    }
    const fsys::path install(path_of(*chosen));
    if (!fsys::is_directory(install, ec)) {
        problem = "the plugin '" + ref + "' is installed at " + install.string() + ", which no longer exists";
        fix = "Reinstall it: `claude plugin install " + ref + "`.";
        return {};
    }
    return install;
}

}  // namespace

ExtensionSupport extension_support(const ProviderConfig& p) {
    ExtensionSupport s;
    std::string reason, fix;
    unsupported(p, ExtensionKind::Plugin, reason, fix);
    s.plugins = reason.empty();
    std::string r2;
    unsupported(p, ExtensionKind::Skill, r2, fix);
    s.skills = r2.empty();
    std::string r3;
    unsupported(p, ExtensionKind::Hooks, r3, fix);
    s.hooks = r3.empty();
    s.inheritSetting = p.kind == ProviderKind::ClaudeCode;
    if (!s.plugins) s.reason = reason;
    else if (!s.hooks) s.reason = r3;
    else if (!s.skills) s.reason = r2;
    // Only the plugins' reason is the general one for providers that take nothing; a generic CLI lists its own gaps per kind.
    if (!s.any()) s.reason = reason;
    return s;
}

ExtensionItem resolve_extension(const Extension& e, const ExtensionContext& ctx, bool projectTrusted) {
    ExtensionItem it;
    it.kind = e.kind;
    it.name = e.name;
    it.source = e.source;
    it.enabled = e.enabled;
    const EnvLookup env = env_of(ctx);
    if (e.from_project() && e.runs_program() && !projectTrusted) {
        it.trusted = false;
        it.problem = "it comes from this project's " + std::string(kProjectExtensionsFile) + ", which you have not trusted";
        it.fix = "Open the editor's AI settings > Extensions, read what the project would run and choose Trust this project. "
                 "The trust is dropped whenever the file changes.";
    }
    auto fail = [&](std::string problem, std::string fix) {
        if (it.problem.empty()) {  // an untrusted project's first problem stays the one the user must act on
            it.problem = std::move(problem);
            it.fix = std::move(fix);
        }
    };

    switch (e.kind) {
        case ExtensionKind::Hooks: it.target = "hooks"; return it;
        case ExtensionKind::Plugin: {
            if (!e.plugin.empty()) {
                std::string problem, fix;
                const fsys::path dir = installed_plugin_path(e.plugin, ctx.projectDir, env, problem, fix);
                if (dir.empty()) { fail(problem, fix); return it; }
                it.target = dir.string();
                it.dirs.push_back(it.target);
                return it;
            }
            const std::string path = resolve_extension_path(e, ctx.projectDir, env);
            it.target = path;
            std::error_code ec;
            if (fsys::is_directory(path, ec)) {
                it.dirs.push_back(path);
            } else if (fsys::is_regular_file(path, ec)) {
                if (fsys::path(path).extension() == ".zip") it.dirs.push_back(path);
                else fail("'" + path + "' is a file, but a plugin is a directory or a .zip", "Point \"path\" at the plugin's folder (the one with .claude-plugin/plugin.json), or at its .zip.");
            } else {
                fail("'" + path + "' does not exist", "Check the path (~ is your home folder), or install the plugin there.");
            }
            return it;
        }
        case ExtensionKind::Skill: {
            const std::string path = resolve_extension_path(e, ctx.projectDir, env);
            it.target = path;
            std::error_code ec;
            if (!fsys::is_directory(path, ec)) {
                fail("'" + path + "' is not a folder", "Point \"path\" at a skill folder (it holds a SKILL.md) or at a folder of skill folders.");
                return it;
            }
            if (e.from_project() && !ctx.projectDir.empty() && !inside(fsys::path(ctx.projectDir), fsys::path(path))) {
                fail("'" + path + "' is outside the project", "A project's skill must live inside the project.");
                return it;
            }
            if (fsys::is_regular_file(fsys::path(path) / "SKILL.md", ec)) {
                it.dirs.push_back(path);
                return it;
            }
            std::vector<std::string> found;
            for (const auto& entry : fsys::directory_iterator(path, ec)) {
                std::error_code e2;
                if (entry.is_directory(e2) && !entry.is_symlink(e2) && fsys::is_regular_file(entry.path() / "SKILL.md", e2))
                    found.push_back(entry.path().string());
            }
            std::sort(found.begin(), found.end());
            if (found.empty()) {
                fail("'" + path + "' has no SKILL.md, and none of its folders has one", "A skill is a folder with a SKILL.md file; point \"path\" at it, or at a folder of such folders.");
                return it;
            }
            it.dirs = std::move(found);
            return it;
        }
    }
    return it;
}

Json merge_hooks(const std::vector<Json>& sets) {
    Json out = Json::object();
    for (const Json& set : sets) {
        if (!set.is_object()) continue;
        for (auto it = set.begin(); it != set.end(); ++it) {
            if (!it.value().is_array()) continue;
            if (!out.contains(it.key())) out[it.key()] = Json::array();
            for (const Json& group : it.value()) out[it.key()].push_back(group);
        }
    }
    return out;
}

Result<void> write_skills_plugin(const std::string& dir, const std::vector<std::string>& skillDirs) {
    std::error_code ec;
    fsys::remove_all(dir, ec);
    fsys::create_directories(fsys::path(dir) / ".claude-plugin", ec);
    fsys::create_directories(fsys::path(dir) / "skills", ec);
    if (ec) return make_error("Cannot create " + dir, "Is the project directory writable?");
    Json manifest = Json::object({{"name", kSkillsPluginName},
                                  {"version", "1.0.0"},
                                  {"description", "The skill folders listed under \"extensions\" in FactorIA's AI settings, for this run."}});
    if (auto ok = fs::write_text((fsys::path(dir) / ".claude-plugin" / "plugin.json").string(), dump_json(manifest)); !ok) return ok;
    std::set<std::string> used;
    for (const std::string& src : skillDirs) {
        std::string name = fsys::path(src).filename().string();
        if (name.empty() || name == "." || name == "..") name = "skill";
        std::string unique = name;
        for (int n = 2; !used.insert(unique).second; ++n) unique = name + "-" + std::to_string(n);
        fsys::copy(src, fsys::path(dir) / "skills" / unique, fsys::copy_options::recursive | fsys::copy_options::skip_symlinks, ec);
        if (ec) return make_error("Cannot copy the skill '" + src + "' for this run: " + ec.message(), "Check that the folder is readable.");
    }
    return {};
}

ExtensionPlan plan_extensions(const AiConfig& cfg, const ProviderConfig& provider, std::string_view role, const ExtensionContext& ctx) {
    ExtensionPlan plan;
    plan.provider = provider.name;
    plan.providerKind = provider.kind;
    plan.role = std::string(role);
    plan.support = extension_support(provider);

    // The entries that apply to this role: the user's, then the project's.
    std::vector<const Extension*> entries = cfg.extensions_for(role);
    ProjectExtensions project;
    bool projectTrusted = false;
    if (!ctx.projectDir.empty()) {
        project = load_project_extensions(ctx.projectDir);
        if (!project.error.empty()) {
            plan.notes.push_back("The project's extensions file was ignored: " + project.error);
        } else if (!project.entries.empty()) {
            projectTrusted = project_extensions_trusted(ctx.trustPath, ctx.projectDir, project.hash, nullptr, ctx.dropStaleTrust);
            for (const Extension& e : project.entries)
                if (e.serves_role(role)) entries.push_back(&e);
        }
    }

    std::vector<Json> hookSets;
    std::set<std::string> seenPlugin, seenSkill;
    for (const Extension* e : entries) {
        ExtensionItem item = resolve_extension(*e, ctx, projectTrusted);
        std::string reason, fix;
        unsupported(provider, e->kind, reason, fix);
        if (item.problem.empty() && !reason.empty()) {
            item.problem = reason;
            item.fix = fix;
        }
        if (!item.problem.empty()) {
            plan.skipped.push_back(std::move(item));
            continue;
        }
        switch (e->kind) {
            case ExtensionKind::Plugin:
                for (const std::string& d : item.dirs)
                    if (seenPlugin.insert(d).second) plan.pluginDirs.push_back(d);
                break;
            case ExtensionKind::Skill:
                for (const std::string& d : item.dirs)
                    if (seenSkill.insert(d).second) plan.skillDirs.push_back(d);
                break;
            case ExtensionKind::Hooks: hookSets.push_back(e->hooks); break;
        }
        plan.received.push_back(std::move(item));
    }
    if (!hookSets.empty()) plan.hooks = merge_hooks(hookSets);
    plan.userPluginsOff = !cfg.extensions.inheritUserPlugins && plan.support.inheritSetting;

    // Notes: what the run did with the extensions, in the words of the user's settings.
    if (!plan.skipped.empty() && plan.received.empty() && !plan.support.any()) {
        plan.notes.push_back(std::to_string(plan.skipped.size()) + (plan.skipped.size() == 1 ? " extension" : " extensions") +
                             " for the role '" + plan.role + "' not loaded: " + plan.support.reason + ".");
    } else {
        for (const ExtensionItem& s : plan.skipped) {
            plan.notes.push_back(std::string("Extension ") + extension_kind_name(s.kind) + " '" + s.name + "' (" + s.source + ") not loaded: " +
                                 s.problem + ". " + s.fix);
        }
    }
    if (!plan.received.empty()) {
        std::string list;
        for (const ExtensionItem& r : plan.received)
            list += (list.empty() ? "" : ", ") + std::string(extension_kind_name(r.kind)) + " " + r.name;
        plan.notes.push_back("Extensions loaded: " + list + ".");
    }
    if (plan.userPluginsOff) {
        plan.notes.push_back("inheritUserPlugins is off: this run starts Claude Code with --setting-sources project,local, so the "
                             "plugins, skills, hooks and settings of your ~/.claude are not loaded.");
    } else if (!cfg.extensions.inheritUserPlugins && !plan.support.inheritSetting) {
        plan.notes.push_back("inheritUserPlugins is off, but it applies to Claude Code only: provider '" + provider.name + "' is not affected.");
    }
    if (provider.kind == ProviderKind::ClaudeCode && !ctx.projectDir.empty()) {
        plan.denied = find_denied_factoria_tools(ctx.projectDir);
        for (const DeniedTool& d : plan.denied) plan.notes.push_back(format_denied_tool(d));
    }
    return plan;
}

ExtensionContext make_extension_context(const AiConfig& cfg, std::string_view projectDir, const EnvLookup& env) {
    ExtensionContext ctx;
    ctx.projectDir = std::string(projectDir);
    ctx.env = env;
    const std::string configPath = cfg.sourcePath.empty() ? default_config_path(env ? env : system_env()) : cfg.sourcePath;
    ctx.trustPath = extensions_trust_path(configPath);
    return ctx;
}

// --- reports ---------------------------------------------------------------------------------------------------------

namespace {

Json item_json(const ExtensionItem& i) {
    Json j = Json::object({{"kind", extension_kind_name(i.kind)}, {"name", i.name}, {"source", i.source}});
    if (!i.problem.empty()) {
        j["reason"] = i.problem;
        j["fix"] = i.fix;
    }
    return j;
}

}  // namespace

Json extensions_report(const AiConfig& cfg, const ExtensionContext& ctx, std::string_view roleFilter) {
    Json out = Json::object();
    out["inheritUserPlugins"] = cfg.extensions.inheritUserPlugins;

    ProjectExtensions project;
    bool projectTrusted = false;
    if (!ctx.projectDir.empty()) {
        project = load_project_extensions(ctx.projectDir);
        projectTrusted = !project.hash.empty() && project_extensions_trusted(ctx.trustPath, ctx.projectDir, project.hash, nullptr, false);
    }
    Json file = Json::object({{"path", project.path}, {"exists", project.exists}});
    if (project.exists) {
        file["hash"] = project.hash;
        file["trusted"] = projectTrusted;
        if (!project.error.empty()) file["error"] = project.error;
    }
    out["projectFile"] = ctx.projectDir.empty() ? Json() : file;

    std::vector<const Extension*> all;
    for (const Extension& e : cfg.extensions.entries) all.push_back(&e);
    for (const Extension& e : project.entries) all.push_back(&e);
    Json entries = Json::array();
    for (const Extension* e : all) {
        ExtensionItem item = resolve_extension(*e, ctx, projectTrusted);
        Json j = Json::object({{"kind", extension_kind_name(e->kind)}, {"name", e->name}, {"source", e->source}, {"enabled", e->enabled}});
        if (!item.target.empty() && e->kind != ExtensionKind::Hooks) j["target"] = item.target;
        if (!e->plugin.empty()) j["plugin"] = e->plugin;
        j["roles"] = e->roles.empty() ? Json(std::vector<std::string>(std::begin(kDefaultExtensionRoles), std::end(kDefaultExtensionRoles)))
                                      : Json(e->roles);
        if (!e->note.empty()) j["note"] = e->note;
        if (e->from_project() && e->runs_program()) j["trusted"] = projectTrusted;
        if (!item.problem.empty()) {
            j["problem"] = item.problem;
            j["fix"] = item.fix;
        }
        entries.push_back(std::move(j));
    }
    out["entries"] = std::move(entries);

    Json roles = Json::object();
    bool anyEntry = !all.empty();
    for (const char* roleName : kAllRoles) {
        if (!roleFilter.empty() && roleFilter != roleName) continue;
        const RoleConfig eff = cfg.effective_role(roleName);
        const ProviderConfig* p = cfg.provider(eff.provider);
        if (!p) continue;
        const ExtensionPlan plan = plan_extensions(cfg, *p, roleName, ExtensionContext{ctx.projectDir, ctx.env, ctx.trustPath, false});
        Json r = Json::object({{"provider", p->name}, {"providerKind", provider_kind_name(p->kind)}, {"enabled", cfg.role_enabled(roleName)}});
        Json received = Json::array();
        for (const ExtensionItem& i : plan.received) received.push_back(item_json(i));
        Json skipped = Json::array();
        for (const ExtensionItem& i : plan.skipped) skipped.push_back(item_json(i));
        r["receives"] = std::move(received);
        r["skipped"] = std::move(skipped);
        r["notes"] = plan.notes;
        r["userPluginsOff"] = plan.userPluginsOff;
        roles[roleName] = std::move(r);
    }
    out["roles"] = std::move(roles);

    Json deny = Json::array();
    for (const DeniedTool& d : find_denied_factoria_tools(ctx.projectDir))
        deny.push_back(Json::object({{"file", d.file}, {"rule", d.rule}, {"tool", d.tool}, {"fix", d.fix}}));
    out["denyRules"] = std::move(deny);

    out["scope"] = "Only Claude Code (all three kinds) and a generic CLI whose argv has {plugin_dirs} / {settings} use extensions. "
                   "Codex gets none (FactorIA could not verify how it takes them). The API providers (anthropic, openai-compatible) "
                   "do not use extensions yet.";
    if (!anyEntry) out["hint"] = "No extensions yet. Add them in the editor (AI settings > Extensions) or under \"extensions\" in ai.json; see docs/AI_PROVIDERS.md, \"Extensions\".";
    return out;
}

std::vector<std::string> extension_doctor_lines(const AiConfig& cfg, const ExtensionContext& ctx) {
    std::vector<std::string> lines;
    ProjectExtensions project;
    if (!ctx.projectDir.empty()) project = load_project_extensions(ctx.projectDir);
    const bool projectTrusted =
        !project.hash.empty() && project_extensions_trusted(ctx.trustPath, ctx.projectDir, project.hash, nullptr, false);
    std::vector<const Extension*> all;
    for (const Extension& e : cfg.extensions.entries) all.push_back(&e);
    for (const Extension& e : project.entries) all.push_back(&e);

    const auto count = [&](ExtensionKind k) { return std::count_if(all.begin(), all.end(), [&](const Extension* e) { return e->kind == k; }); };
    if (!all.empty() || !cfg.extensions.inheritUserPlugins) {
        lines.push_back("Extensions: " + std::to_string(count(ExtensionKind::Plugin)) + " plugin(s), " +
                        std::to_string(count(ExtensionKind::Skill)) + " skill folder(s), " + std::to_string(count(ExtensionKind::Hooks)) +
                        " hook set(s); inheritUserPlugins " + (cfg.extensions.inheritUserPlugins ? "on" : "off") +
                        ". Used by Claude Code (and a generic CLI with {plugin_dirs} / {settings}); not by Codex or the API providers yet.");
    }
    if (!project.error.empty()) lines.push_back("  ! The project's extensions file is ignored: " + project.error);
    for (const Extension* e : all) {
        const ExtensionItem item = resolve_extension(*e, ctx, projectTrusted);
        if (item.problem.empty()) continue;
        lines.push_back(std::string("  ! ") + extension_kind_name(e->kind) + " '" + e->name + "' (" + e->source + "): " + item.problem + ". " + item.fix);
    }
    for (const DeniedTool& d : find_denied_factoria_tools(ctx.projectDir)) lines.push_back("  ! " + format_denied_tool(d));
    return lines;
}

}  // namespace fa::ai
