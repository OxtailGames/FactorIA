#include "fa/tooling/validate.h"

#include <algorithm>
#include <filesystem>
#include <set>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "fa/platform/input.h"
#include "fa/runtime/project.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "fa/tooling/feedback.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {
ScriptCheckHook& global_hook() {
    static ScriptCheckHook h;
    return h;
}

ScriptPropsCheckHook& global_props_hook() {
    static ScriptPropsCheckHook h;
    return h;
}

struct PropsCheck {
    std::string file, pointer, module;
    Json props;
};

struct Ctx {
    std::string dir;
    std::vector<PropsCheck> propChecks;
    ValidationReport report;
    void error(std::string file, std::string pointer, std::string msg, std::string hint = {}) {
        report.errors.push_back({std::move(file), std::move(pointer), std::move(msg), std::move(hint)});
    }
    void warn(std::string file, std::string pointer, std::string msg, std::string hint = {}) {
        report.warnings.push_back({std::move(file), std::move(pointer), std::move(msg), std::move(hint)});
    }
};

bool is_builtin_mesh(const std::string& m) {
    static const std::set<std::string> v = {"cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad"};
    return v.count(m) > 0;
}

// Restores the global VFS root on scope exit.
struct RootGuard {
    stdfs::path saved;
    explicit RootGuard(const stdfs::path& root) : saved(fs::project_root()) { fs::set_project_root(root); }
    ~RootGuard() { fs::set_project_root(saved); }
};

void check_asset_value(Ctx& c, const std::string& file, const std::string& pointer, const FieldInfo& f,
                       const Json& value) {
    if (!value.is_string()) return;
    std::string path = value.get<std::string>();
    if (path.empty()) return;
    if (f.assetType == "mesh" && is_builtin_mesh(path)) return;
    if (!stdfs::exists(stdfs::path(c.dir) / path)) {
        // Suggest a similar file in the same folder.
        std::string hint = "Create the file or fix the path (project-relative, forward slashes).";
        stdfs::path parent = (stdfs::path(c.dir) / path).parent_path();
        std::error_code ec;
        if (stdfs::is_directory(parent, ec)) {
            std::vector<std::string> names;
            for (const auto& e : stdfs::directory_iterator(parent, ec)) names.push_back(e.path().filename().string());
            std::string m = closest_match(stdfs::path(path).filename().string(), names);
            if (!m.empty()) hint = "Did you mean '" + (stdfs::path(path).parent_path() / m).generic_string() + "'?";
        }
        c.error(file, pointer, "Asset '" + path + "' (" + f.assetType + ") does not exist.", hint);
    }
}

void check_component_assets(Ctx& c, const std::string& file, const std::string& pointer, const std::string& typeName,
                            const Json& fields) {
    const TypeInfo* t = TypeRegistry::global().find(typeName);
    if (!t || !fields.is_object()) return;
    for (const FieldInfo& f : t->fields) {
        if (f.kind != FieldKind::Asset || !fields.contains(f.name)) continue;
        check_asset_value(c, file, pointer + "/" + f.name, f, fields[f.name]);
    }
}

void check_entity_assets(Ctx& c, const std::string& file, const std::string& pointer, const Json& entity,
                         std::set<std::string>& scripts) {
    if (!entity.is_object()) return;
    if (entity.contains("prefab") && entity["prefab"].is_string()) {
        std::string pf = entity["prefab"].get<std::string>();
        if (!stdfs::exists(stdfs::path(c.dir) / pf))
            c.error(file, pointer + "/prefab", "Prefab '" + pf + "' does not exist.", "Create it under prefabs/ or fix the path.");
    }
    if (entity.contains("components") && entity["components"].is_object()) {
        for (auto it = entity["components"].begin(); it != entity["components"].end(); ++it) {
            check_component_assets(c, file, pointer + "/components/" + it.key(), it.key(), it.value());
            if (it.key() == "Script" && it.value().is_object() && it.value().contains("path") && it.value()["path"].is_string()) {
                scripts.insert(it.value()["path"].get<std::string>());
                if (it.value().contains("props") && it.value()["props"].is_object() && !it.value()["props"].empty())
                    c.propChecks.push_back({file, pointer + "/components/Script/props", it.value()["path"].get<std::string>(),
                                            it.value()["props"]});
            }
        }
    }
    if (entity.contains("children") && entity["children"].is_array()) {
        int i = 0;
        for (const auto& ch : entity["children"]) check_entity_assets(c, file, pointer + "/children/" + std::to_string(i++), ch, scripts);
    }
}

void check_binding(Ctx& c, const std::string& pointer, const std::string& binding) {
    std::string b = to_lower(binding);
    if (b == "mouseleft" || b == "mouseright" || b == "mousemiddle" || b == "touch" || b.rfind("gamepad", 0) == 0) return;
    if (key_from_name(binding) != Key::Unknown) return;
    std::vector<std::string> names;
    for (int k = 1; k < int(Key::Count); ++k) names.push_back(key_name(Key(k)));
    for (const char* extra : {"MouseLeft", "MouseRight", "MouseMiddle", "Touch"}) names.push_back(extra);
    c.error(kProjectFileName, pointer, "Unknown input binding '" + binding + "'.", did_you_mean(binding, names));
}

void check_project_file(Ctx& c, std::string& mainScene, std::string& feedbackFile) {
    auto text = tooling_detail::read_file(stdfs::path(c.dir) / kProjectFileName);
    if (!text) {
        c.error(kProjectFileName, "", "factoria.json not found in " + c.dir + ".",
                "Run from the project folder, or create a project with `factoria new <dir>`.");
        return;
    }
    auto parsed = parse_json(*text, kProjectFileName);
    if (!parsed.ok()) {
        c.error(kProjectFileName, "", parsed.error().message, parsed.error().hint.empty() ? "Fix the JSON syntax." : parsed.error().hint);
        return;
    }
    const Json& pj = parsed.value();
    Json schema = tooling_detail::load_schema("schemas/project.schema.json");
    if (!schema.is_null())
        for (const auto& e : validate_json(schema, pj)) c.error(kProjectFileName, e.pointer, e.message, e.hint);
    if (!pj.is_object()) return;
    mainScene = pj.value("mainScene", std::string("scenes/main.scene.json"));
    feedbackFile = pj.value("feedbackFile", std::string(kFeedbackFileName));
    if (!stdfs::exists(stdfs::path(c.dir) / mainScene))
        c.error(kProjectFileName, "/mainScene", "Main scene '" + mainScene + "' does not exist.",
                "Create it or point mainScene at an existing scene (see scenes/).");
    if (pj.contains("input") && pj["input"].is_object() && pj["input"].contains("actions") && pj["input"]["actions"].is_object()) {
        for (auto it = pj["input"]["actions"].begin(); it != pj["input"]["actions"].end(); ++it) {
            if (!it.value().is_array()) continue;
            int i = 0;
            for (const auto& b : it.value()) {
                if (b.is_string()) check_binding(c, "/input/actions/" + it.key() + "/" + std::to_string(i), b.get<std::string>());
                ++i;
            }
            if (it.value().empty())
                c.warn(kProjectFileName, "/input/actions/" + it.key(), "Action '" + it.key() + "' has no bindings.", "Add at least one key, e.g. [\"Space\"].");
        }
    }
}

void check_feedback_file(Ctx& c, const std::string& file) {
    stdfs::path p = stdfs::path(c.dir) / file;
    if (!stdfs::exists(p)) {
        c.error(file, "", file + " is missing.",
                "Run `factoria feedback init` (or call feedback.report) to create it; every project must keep one.");
        return;
    }
    auto doc = load_feedback(p.string());
    if (!doc.ok()) {
        c.error(file, "", doc.error().message, "Fix the JSON syntax or recreate with `factoria feedback init`.");
        return;
    }
    for (const auto& e : validate_feedback(doc.value())) c.error(file, e.pointer, e.message, e.hint);
}

}  // namespace

Json ValidationIssue::to_json() const {
    Json j = Json::object({{"file", file}});
    if (!pointer.empty()) j["pointer"] = pointer;
    j["message"] = message;
    if (!hint.empty()) j["hint"] = hint;
    return j;
}

std::string ValidationIssue::to_string() const {
    std::string s = file;
    if (!pointer.empty()) s += "#" + pointer;
    s += ": " + message;
    if (!hint.empty()) s += " (hint: " + hint + ")";
    return s;
}

Json ValidationReport::to_json() const {
    Json e = Json::array(), w = Json::array();
    for (const auto& i : errors) e.push_back(i.to_json());
    for (const auto& i : warnings) w.push_back(i.to_json());
    return Json::object({{"ok", ok}, {"errors", e}, {"warnings", w}, {"scenesChecked", scenesChecked}, {"scriptsChecked", scriptsChecked}});
}

std::string ValidationReport::to_text() const {
    std::ostringstream o;
    for (const auto& i : errors) o << "error: " << i.to_string() << "\n";
    for (const auto& i : warnings) o << "warning: " << i.to_string() << "\n";
    o << (ok ? "OK" : "FAILED") << ": " << errors.size() << " error(s), " << warnings.size() << " warning(s), "
      << scenesChecked << " scene(s), " << scriptsChecked << " script(s) checked.\n";
    return o.str();
}

void set_script_check_hook(ScriptCheckHook hook) { global_hook() = std::move(hook); }
void set_script_props_check_hook(ScriptPropsCheckHook hook) { global_props_hook() = std::move(hook); }

ValidationReport validate_project(const std::string& projectDir, const ValidateOptions& options) {
    Ctx c;
    std::error_code ec;
    c.dir = stdfs::absolute(projectDir, ec).lexically_normal().string();
    if (!c.dir.empty() && (c.dir.back() == '/' || c.dir.back() == '\\')) c.dir.pop_back();
    if (!stdfs::is_directory(c.dir, ec)) {
        c.error("", "", "Project directory '" + projectDir + "' does not exist.", "Pass the folder that contains factoria.json.");
        c.report.ok = false;
        return std::move(c.report);
    }

    std::string mainScene, feedbackFile = kFeedbackFileName;
    check_project_file(c, mainScene, feedbackFile);
    check_feedback_file(c, feedbackFile);

    std::set<std::string> scripts;
    if (options.checkScenes) {
        RootGuard guard(c.dir);
        std::vector<std::string> sceneFiles, prefabFiles;
        for (const char* folder : {"scenes", "prefabs"}) {
            stdfs::path base = stdfs::path(c.dir) / folder;
            if (!stdfs::is_directory(base, ec)) continue;
            for (stdfs::recursive_directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec)) {
                if (!it->is_regular_file(ec)) continue;
                std::string rel = stdfs::relative(it->path(), c.dir, ec).generic_string();
                if (ends_with(rel, ".scene.json")) sceneFiles.push_back(rel);
                else if (ends_with(rel, ".prefab.json")) prefabFiles.push_back(rel);
            }
        }
        std::sort(sceneFiles.begin(), sceneFiles.end());
        std::sort(prefabFiles.begin(), prefabFiles.end());
        for (const auto& rel : sceneFiles) {
            ++c.report.scenesChecked;
            World world;  // registers built-in components
            LoadReport lr = load_scene_file(world, rel);
            for (const auto& m : lr.messages) {
                ValidationIssue issue{m.source.empty() ? rel : m.source, m.pointer, m.message, m.hint};
                // Normalize absolute sources to project-relative.
                if (stdfs::path(issue.file).is_absolute()) issue.file = stdfs::relative(issue.file, c.dir, ec).generic_string();
                (m.severity == LoadMessage::Severity::Error ? c.report.errors : c.report.warnings).push_back(std::move(issue));
            }
            auto text = tooling_detail::read_file(stdfs::path(c.dir) / rel);
            if (!text) continue;
            auto parsed = parse_json(*text, rel);
            if (!parsed.ok()) continue;  // load_scene_file already reported it
            const Json& j = parsed.value();
            if (j.is_object() && j.contains("settings"))
                check_component_assets(c, rel, "/settings", "SceneSettings", j["settings"]);
            if (j.is_object() && j.contains("entities") && j["entities"].is_array()) {
                int i = 0;
                for (const auto& e : j["entities"]) check_entity_assets(c, rel, "/entities/" + std::to_string(i++), e, scripts);
            }
        }
        for (const auto& rel : prefabFiles) {
            auto text = tooling_detail::read_file(stdfs::path(c.dir) / rel);
            auto parsed = text ? parse_json(*text, rel) : Result<Json>(make_error("cannot read " + rel));
            if (!parsed.ok()) { c.error(rel, "", parsed.error().message, "Fix the JSON syntax."); continue; }
            if (parsed.value().is_object() && parsed.value().contains("entity"))
                check_entity_assets(c, rel, "/entity", parsed.value()["entity"], scripts);
        }
        if (sceneFiles.empty())
            c.warn("scenes", "", "No scenes found (scenes/*.scene.json).", "Create scenes/main.scene.json.");
        else if (!mainScene.empty() && std::find(sceneFiles.begin(), sceneFiles.end(), mainScene) == sceneFiles.end() &&
                 stdfs::exists(stdfs::path(c.dir) / mainScene))
            c.warn(kProjectFileName, "/mainScene", "mainScene '" + mainScene + "' is not under scenes/ or is not named *.scene.json.");
    }

    // Scripts: everything under scripts/ and tools/ plus referenced paths.
    for (const char* folder : {"scripts", "tools"}) {
        stdfs::path base = stdfs::path(c.dir) / folder;
        if (!stdfs::is_directory(base, ec)) continue;
        for (stdfs::recursive_directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec) && it->path().extension() == ".js")
                scripts.insert(stdfs::relative(it->path(), c.dir, ec).generic_string());
    }
    const ScriptCheckHook& hook = options.scriptCheck ? options.scriptCheck : global_hook();
    for (const auto& s : scripts) {
        if (!stdfs::exists(stdfs::path(c.dir) / s)) continue;  // missing referenced scripts were reported as assets
        ++c.report.scriptsChecked;
        if (!hook) continue;
        for (auto& issue : hook(c.dir, s)) c.report.errors.push_back(std::move(issue));
    }
    const ScriptPropsCheckHook& propsHook = options.propsCheck ? options.propsCheck : global_props_hook();
    if (propsHook) {
        for (const PropsCheck& pc : c.propChecks) {
            if (!stdfs::exists(stdfs::path(c.dir) / pc.module)) continue;
            for (const std::string& msg : propsHook(pc.module, pc.props))
                c.warn(pc.file, pc.pointer, msg, "Fix the prop name, or declare the field in " + pc.module + " (props only set existing fields).");
        }
    }
    if (auto dts = tooling_detail::read_file(stdfs::path(c.dir) / "types" / "factoria.d.ts");
        dts && dts->find("(placeholder)") != std::string::npos)
        c.warn("types/factoria.d.ts", "", "The script typings are a placeholder (everything is `any`).",
               "Run `factoria validate --fix-types` (or `factoria api --dts --project .`) to write the real typings.");
    if (!stdfs::exists(stdfs::path(c.dir) / "AGENTS.md"))
        c.warn("AGENTS.md", "", "AGENTS.md is missing.", "AI agents rely on it; create it with `factoria new` or copy from templates/common/AGENTS.md.");
    if (!stdfs::is_directory(stdfs::path(c.dir) / "tests", ec))
        c.warn("tests", "", "No tests/ folder.", "Add tests/*.test.js so `factoria test` can verify behaviour.");

    c.report.ok = c.report.errors.empty();
    return std::move(c.report);
}

void register_validate_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "project.validate";
    info.category = "project";
    info.readOnly = true;
    info.summary = "Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.";
    info.description = "Run after every batch of edits. Returns {ok, errors[], warnings[]}; each issue has file, JSON pointer, "
                       "message and a fix hint. Loads every scene into a temporary world, so it does not disturb a running game. "
                       "Example: {}";
    registry.add(info, [projectDir](const Json&) { return validate_project(projectDir).to_json(); });
}

}  // namespace fa
