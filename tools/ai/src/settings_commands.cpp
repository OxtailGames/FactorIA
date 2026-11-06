#include "settings_commands.h"

#include <algorithm>
#include <filesystem>
#include <map>
#include <set>
#include <utility>
#include <vector>

#include "fa/ai/project_settings.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;
namespace fsys = std::filesystem;

namespace {

const char* const kExtensionGroupNames[] = {"plugins", "skills", "hooks"};

void collect_leaves(const Json& j, const std::string& pointer, std::vector<std::pair<std::string, Json>>& out) {
    if (j.is_object()) {
        for (auto it = j.begin(); it != j.end(); ++it) {
            std::string key = it.key();
            std::string esc;
            for (char c : key) esc += c == '~' ? "~0" : c == '/' ? "~1" : std::string(1, c);
            collect_leaves(it.value(), pointer + "/" + esc, out);
        }
    } else {
        out.emplace_back(pointer, j);
    }
}

// Every value of the config with its source: [{pointer, value, source}].
Json values_json(const ResolvedAiConfig& r) {
    std::vector<std::pair<std::string, Json>> leaves;
    collect_leaves(settings_view(r.config), "", leaves);
    Json out = Json::array();
    for (const auto& [pointer, value] : leaves) {
        out.push_back(Json::object({{"pointer", pointer}, {"value", value}, {"source", setting_source_name(r.source_of(pointer))}}));
    }
    return out;
}

bool is_project(const std::string& dir) {
    std::error_code ec;
    return !dir.empty() && fsys::exists(fsys::path(dir) / "factoria.json", ec);
}

// What the project's file is now: its content, whether it applies and what it would change.
Json project_state(const ResolvedAiConfig& r) {
    Json pending = Json::array();
    for (const auto& c : r.pending) pending.push_back(Json::object({{"pointer", c.pointer}, {"from", c.from}, {"to", c.to}}));
    Json out = Json::object({{"file", r.projectFile},
                             {"exists", r.fileExists},
                             {"overrides", r.overrides},
                             {"applied", r.applied},
                             {"pendingTrust", r.pendingTrust},
                             {"pending", pending}});
    if (r.invalidError) {
        out["invalidError"] = Json::object({{"message", r.invalidError->message}, {"hint", r.invalidError->hint}});
    }
    return out;
}

// Every setting whose value differs between two configs: [{pointer, from, to}] (null where a side has no such setting).
Json changed_json(const AiConfig& before, const AiConfig& after) {
    std::vector<std::pair<std::string, Json>> a, b;
    collect_leaves(settings_view(before), "", a);
    collect_leaves(settings_view(after), "", b);
    std::map<std::string, std::pair<Json, Json>> both;
    for (auto& [pointer, value] : a) both[pointer].first = value;
    for (auto& [pointer, value] : b) both[pointer].second = value;
    Json out = Json::array();
    for (const auto& [pointer, values] : both) {
        if (values.first != values.second) out.push_back(Json::object({{"pointer", pointer}, {"from", values.first}, {"to", values.second}}));
    }
    return out;
}

[[noreturn]] void fail(const std::string& code, const Error& e) { throw CommandError(code, e.message, e.hint); }

}  // namespace

void register_settings_commands(CommandRegistry& registry, std::function<std::string()> projectDir, std::string aiConfigPath,
                                EnvLookup env, std::function<void()> onUserConfigChanged, std::function<void()> onProjectConfigChanged) {
    if (!env) env = system_env();
    {
        CommandInfo info;
        info.name = "ai.settings.get";
        info.category = "ai";
        info.summary = "Show the AI settings (roles, limits, assets, savers, tool servers, extensions) with where each value comes from: this project, your defaults or the engine.";
        info.description =
            "The AI settings of a project resolve key by key: the engine's defaults, then your ~/.factoria/ai.json, then the project's own "
            "file (<project>/.factoria/ai/settings.json), docs/AI_PROVIDERS.md \"Per project\". scope \"resolved\" (default) returns "
            "{scope, project (the folder, or null), values:[{pointer, value, source}], projectSettings} with the values the project runs "
            "with (JSON pointers like /roles/artist/enabled or /limits/maxTurns) and `source` \"project\", \"you\" or \"default\"; "
            "projectSettings is the file's state when the project has one. scope \"project\" returns the project file itself: "
            "{scope, project, file, exists, overrides (the raw file), applied, pendingTrust, pending:[{pointer, from, to}], invalidError}. "
            "A project file the user has not accepted on this computer (it came inside a copied project, or an AI wrote it with "
            "ai.settings.set) has no effect yet: pendingTrust is true and `pending` lists what it would change; an invalid one that is "
            "not accepted is in invalidError and has no effect either. scope \"user\" returns your own ai.json view: "
            "{scope, configPath, configFound, values} with source \"you\" (the file sets it, or it differs from the engine's) or "
            "\"default\". Read-only; providers and keys are never part of it. Example: {\"scope\":\"resolved\"}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "scope":{"type":"string","enum":["resolved","project","user"],"default":"resolved","description":"resolved: what this project runs with, each value with its source. project: the project's own file. user: your ai.json."}},
            "additionalProperties":false})");
        info.readOnly = true;
        registry.add(std::move(info), [projectDir, aiConfigPath, env](const Json& args) -> Json {
            const std::string scope = str(args, "scope", "resolved");
            std::string dir = projectDir ? projectDir() : std::string();
            if (!is_project(dir)) dir.clear();
            if (scope == "user") {
                auto r = resolve_ai_config("", aiConfigPath, env);
                if (!r) throw CommandError("invalid_config", r.error().message, r.error().hint);
                const std::string path = aiConfigPath.empty() ? default_config_path(env) : aiConfigPath;
                return Json::object({{"scope", "user"}, {"configPath", path}, {"configFound", !r->config.sourcePath.empty()}, {"values", values_json(*r)}});
            }
            if (scope == "project" && dir.empty()) {
                throw CommandError("no_project", "No FactorIA project is open here, so there is no project AI settings file to show",
                                   "Run this from a project folder (or serve one with factoria mcp --project <dir>); scope \"user\" shows your own settings.");
            }
            auto r = resolve_ai_config(dir, aiConfigPath, env);
            if (!r) throw CommandError("invalid_config", r.error().message, r.error().hint);
            if (scope == "project") {
                Json out = project_state(*r);
                out["scope"] = "project";
                out["project"] = dir;
                if (r->pendingTrust) {
                    out["hint"] = "This file has no effect yet: the user accepts it once in the editor (AI settings, with this project open). No command accepts it.";
                }
                return out;
            }
            Json out = Json::object({{"scope", "resolved"}, {"project", dir.empty() ? Json(nullptr) : Json(dir)}, {"values", values_json(*r)}});
            if (r->fileExists) out["projectSettings"] = project_state(*r);
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "ai.settings.set";
        info.category = "ai";
        info.summary = "Change one AI setting of this project; a project change waits for the user to accept it in the editor. Your own defaults (scope user) only the user changes.";
        info.description =
            "Writes ONE value, named by its JSON pointer as ai.settings.get lists them (/roles/artist/enabled, /roles/worker/model, "
            "/limits/maxCostUsd, /savers/loopGuard, /assets/image/provider, /assetSources/images, /mcpServers/<name> true or false, "
            "/extensions/plugins/<name> true or false). scope \"project\" writes <project>/.factoria/ai/settings.json (only what "
            "differs from your defaults is kept). scope \"user\" writes the user's own ~/.factoria/ai.json defaults and is only for the user "
            "(`factoria call`): an AI agent or MCP client that asks for it gets the error user_only, and the user changes "
            "them in the editor's AI settings window (Your defaults). `value` null removes the "
            "setting: from the project file (it goes back to your default) or from ai.json (it goes back to the engine's). A new "
            "provider for a role or asset route drops its model, effort and voice. A project can only NAME providers, tool servers and "
            "extensions that your ai.json defines, and never holds a command, address, header, environment or key: such keys, "
            "and pointers that are not settings, are refused with where they belong and a \"did you mean\" (errors unknown_pointer, "
            "rejected_key, invalid_setting). "
            "IMPORTANT: this command NEVER accepts a project file: setting a value never writes ai-trust.json. A project file written here is "
            "NOT applied until the user accepts it once in the editor (AI settings, with this project open); until then the project runs with "
            "the user's settings. Setting a value in an already accepted file makes the whole file wait for acceptance again. Removing a "
            "value (null) from an accepted file keeps it accepted (it only gets smaller; its acceptance is updated to the smaller file), and a "
            "removal that empties the file deletes it and forgets its acceptance; removing a value from a file that is not accepted leaves it "
            "waiting. The result says so: needsAcceptance true plus a hint. Returns {ok, scope, pointer, "
            "removed (true only when a value was really taken out: null for a setting the file did not hold changes nothing, says removed false "
            "and a hint that nothing changed), value (what you asked for), runsWith (what the project runs with right now, which is unchanged while its file waits), source "
            "(where runsWith comes from), file, needsAcceptance, applied, hint}; scope \"user\" also returns changed: [{pointer, from, to}], "
            "every setting whose value is different now (a new provider for a role also drops its model, effort and voice). Example: {\"scope\":\"project\",\"pointer\":\"/roles/artist/enabled\",\"value\":false}";
        info.inputSchema = Json::parse(R"({"type":"object","properties":{
            "scope":{"type":"string","enum":["project","user"],"description":"project: this project's file (waits for the user's acceptance). user: the user's ai.json defaults; refused for an AI agent or MCP client (only the user changes them)."},
            "pointer":{"type":"string","description":"JSON pointer of one value, like /roles/artist/enabled (ai.settings.get lists them)."},
            "value":{"description":"The new value (boolean, number, string, or an array for /assetSources/<category>). null removes the setting."}},
            "required":["scope","pointer","value"],"additionalProperties":false})");
        info.readOnly = false;
        registry.add(std::move(info), [projectDir, aiConfigPath, env, onUserConfigChanged, onProjectConfigChanged](const Json& args) -> Json {
            const std::string scope = str(args, "scope");
            const std::string pointer = str(args, "pointer");
            const Json value = args.contains("value") ? args["value"] : Json(nullptr);
            if (scope != "project" && scope != "user") {
                throw CommandError("invalid_arguments", "scope must be \"project\" or \"user\"", "Use \"project\" for this project's file, \"user\" for your ai.json defaults.");
            }
            if (scope == "user" && command_caller() != CommandCaller::User) {
                throw CommandError("user_only",
                                   std::string("scope \"user\" changes the user's own defaults (their ai.json), which only the user does: refused for ") +
                                       command_caller_name(command_caller()),
                                   "Tell the user which setting you want and ask the user to change it in the editor's AI settings window (Your defaults). "
                                   "scope \"project\" changes this project's file instead (the user accepts it in the editor).");
            }
            std::string dir = projectDir ? projectDir() : std::string();
            if (scope == "project" && !is_project(dir)) {
                throw CommandError("no_project", "No FactorIA project is open here, so there is no project AI settings file to change",
                                   "Run this from a project folder (or serve one with factoria mcp --project <dir>), or use scope \"user\" for your defaults.");
            }
            if (scope == "user") dir.clear();
            auto before = resolve_ai_config(dir, aiConfigPath, env);
            if (!before) throw CommandError("invalid_config", before.error().message, before.error().hint);
            const AiConfig& base = before->inherited;

            // The pointers that are settings: every leaf of the view, a role's toolGroups, the fields of an asset route.
            const std::vector<std::string> allowed = setting_pointers(base);
            bool known = std::find(allowed.begin(), allowed.end(), pointer) != allowed.end();
            if (!known && pointer.rfind("/mcpServers/", 0) == 0 && pointer.find('/', 12) == std::string::npos && pointer.size() > 12) known = true;
            if (!known && pointer.rfind("/extensions/", 0) == 0) {
                for (const char* g : kExtensionGroupNames) {
                    const std::string prefix = std::string("/extensions/") + g + "/";
                    if (pointer.rfind(prefix, 0) == 0 && pointer.size() > prefix.size() && pointer.find('/', prefix.size()) == std::string::npos) known = true;
                }
            }
            if (!known) {
                const std::string suggestion = fa::did_you_mean(pointer, allowed);
                // What is wrong with it, when the project-file rules say: a key that is not allowed, an unknown role...
                if (pointer.size() > 1 && pointer.front() == '/') {
                    try {
                        Json ov = Json::object();
                        ov[Json::json_pointer(pointer)] = value.is_null() ? Json(true) : value;
                        if (auto ok = validate_project_settings(ov, base, "the AI settings"); !ok) {
                            const bool rejected = ok.error().message.find("is not allowed in a project") != std::string::npos;
                            throw CommandError(rejected ? "rejected_key" : "unknown_pointer", ok.error().message,
                                               (rejected ? std::string("ai.settings.set only changes the settings ai.settings.get lists. ")
                                                         : std::string()) + suggestion);
                        }
                    } catch (const CommandError&) {
                        throw;
                    } catch (const std::exception&) {
                        // a pointer nlohmann cannot parse: reported below as unknown
                    }
                }
                throw CommandError("unknown_pointer", "'" + escape_control_chars(pointer) + "' is not an AI setting",
                                   "Pointers look like /roles/artist/enabled; ai.settings.get lists them all. " + suggestion);
            }

            Json out = Json::object({{"scope", scope}, {"pointer", pointer}});
            if (scope == "user") {
                if (auto ok = set_user_setting(pointer, value, aiConfigPath, env); !ok) fail("invalid_setting", ok.error());
                if (onUserConfigChanged) onUserConfigChanged();  // the file is written: the editor reloads before anything below can fail
                auto after = resolve_ai_config("", aiConfigPath, env);
                if (!after) throw CommandError("invalid_config", after.error().message, after.error().hint);
                out["ok"] = true;
                // `removed` says a value was taken out of ai.json: null for a setting the file did not set removes nothing.
                const bool removed = value.is_null() && before->source_of(pointer) == SettingSource::You;
                out["removed"] = removed;
                const Json view = settings_view(after->config);
                const Json::json_pointer jp{pointer};
                out["value"] = view.contains(jp) ? view[jp] : Json(nullptr);
                out["runsWith"] = out["value"];
                out["source"] = setting_source_name(after->source_of(pointer));
                out["file"] = after->config.sourcePath.empty() ? (aiConfigPath.empty() ? default_config_path(env) : aiConfigPath) : after->config.sourcePath;
                out["needsAcceptance"] = false;
                out["applied"] = true;
                out["changed"] = changed_json(before->config, after->config);
                out["hint"] = value.is_null() && !removed
                                  ? "Nothing changed: your ai.json does not set " + escape_control_chars(pointer) + ", so there was nothing to remove (it is "
                                    "the engine's own value)."
                                  : "Saved in your ai.json: it is the default of every project that does not set it itself.";
                return out;
            }

            ProjectSettingsFile file = read_project_settings_file(dir);
            if (!file.error.empty()) throw CommandError("invalid_setting", file.error, "Fix the file or delete it, then try again.");
            const bool fileSetsIt = file.overrides.is_object() && file.overrides.contains(Json::json_pointer(pointer));
            if (value.is_null()) {
                if (auto ok = reset_project_setting(dir, pointer, aiConfigPath, env); !ok) fail("invalid_setting", ok.error());
            } else {
                Json ov = file.overrides;
                try {
                    ov[Json::json_pointer(pointer)] = value;
                } catch (const std::exception& e) {
                    throw CommandError("invalid_setting", "'" + escape_control_chars(pointer) + "' cannot be set here: " + e.what(),
                                       "The project file already holds a value of another shape at that place; remove it first with value null.");
                }
                // recordTrust false: a command never accepts what it wrote.
                if (auto ok = save_project_settings(dir, ov, aiConfigPath, env, false); !ok) fail("invalid_setting", ok.error());
            }
            if (onProjectConfigChanged) onProjectConfigChanged();
            auto after = resolve_ai_config(dir, aiConfigPath, env);
            if (!after) throw CommandError("invalid_config", after.error().message, after.error().hint);
            out["ok"] = true;
            const bool removed = value.is_null() && fileSetsIt;  // null for a value the project's file did not hold removes nothing
            out["removed"] = removed;
            // `value` is what was asked for; `runsWith` is what the project runs with right now (its file may still wait).
            const Json view = settings_view(after->config);
            const Json::json_pointer jp{pointer};
            out["value"] = value;
            out["runsWith"] = view.contains(jp) ? view[jp] : Json(nullptr);
            out["source"] = setting_source_name(after->source_of(pointer));
            out["file"] = after->projectFile;
            out["fileExists"] = after->fileExists;
            out["applied"] = after->applied;
            out["needsAcceptance"] = after->pendingTrust;
            if (value.is_null() && !removed) {
                out["hint"] = "Nothing changed: this project's AI settings file does not set " + escape_control_chars(pointer) + ", so there was nothing "
                              "to remove (the value comes from source \"" + std::string(setting_source_name(after->source_of(pointer))) + "\")." +
                              (after->pendingTrust ? " The file that is there still waits for the user to accept it once in the editor." : "");
            } else if (after->pendingTrust) {
                out["hint"] = "Saved, but NOT applied yet: the project keeps running with your settings until the user accepts " + after->projectFile +
                              " once in the editor (AI settings, with this project open). No command can accept it. Tell the user what you changed.";
            } else if (!after->fileExists) {
                out["hint"] = "The project has no AI settings file now: every value is the user's.";
            } else {
                out["hint"] = "Applied: the file was already accepted and this change only removed a value from it.";
            }
            return out;
        });
    }
}

}  // namespace fa::ai
