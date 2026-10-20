#include "fa/tooling/tooling.h"

#include <filesystem>

#include "fa/runtime/engine.h"
#include "fa/tooling/ci_workflow.h"
#include "fa/tooling/sign.h"

namespace fa {

void register_tooling_commands(CommandRegistry& registry, const std::string& projectDir) {
    register_feedback_commands(registry, projectDir);
    register_docs_commands(registry);
    register_api_export_commands(registry);
    register_fs_commands(registry, projectDir);
    register_asset_commands(registry, projectDir);
    register_validate_commands(registry, projectDir);
    register_shader_commands(registry, projectDir);
    register_translation_commands(registry, projectDir);
    register_export_commands(registry, projectDir);
    register_publish_commands(registry, projectDir);
    register_audio_commands(registry, projectDir);
    register_plugin_commands(registry, projectDir);
    register_sign_commands(registry, projectDir);
    register_ci_workflow_commands(registry, projectDir);
    register_platform_setup_commands(registry, projectDir);
    register_setup_commands(registry);
}

ValidateOptions engine_validate_options(Engine& engine) {
    ValidateOptions vo;
    Engine* e = &engine;
    vo.scriptCheck = [e](const std::string&, const std::string& scriptPath) {
        std::vector<ValidationIssue> issues;
        std::string brokenImport;
        auto r = e->scripts().check_syntax(scriptPath, &brokenImport);
        if (!r.ok()) {
            ValidationIssue i;
            if (!brokenImport.empty()) {
                // An imported .json that does not parse: the problem is IN that file ("file:line:column: invalid JSON").
                i.file = brokenImport;
                i.message = r.error().message;
                i.hint = r.error().hint;
            } else {
                i.file = scriptPath;
                i.message = "Syntax error: " + r.error().message;
                i.hint = r.error().hint.empty() ? "Fix the script; 'factoria call script.eval' can test snippets." : r.error().hint;
            }
            issues.push_back(std::move(i));
        }
        return issues;
    };
    vo.propsCheck = [e](const std::string& modulePath, const Json& props) { return e->scripts().check_props(modulePath, props); };
    vo.hooksCheck = [e](const std::string& modulePath) { return e->scripts().check_hooks(modulePath); };
    return vo;
}

void register_project_commands(Engine& engine, const std::string& projectDir) {
    CommandRegistry& registry = engine.commands();
    if (!projectDir.empty()) {
        register_tooling_commands(registry, projectDir);
        // project.validate bound to this engine: script syntax and Script.props go through its script system.
        if (const CommandInfo* ci = registry.info("project.validate")) {
            CommandInfo info = *ci;
            info.description += " Warns about Script.props keys that do not exist on the behaviour, and about behaviour "
                                "methods that look like misspelled lifecycle hooks (update() or onupdate() instead of "
                                "onUpdate()).";
            Engine* e = &engine;
            registry.add(info, [e, projectDir](const Json&) { return validate_project(projectDir, engine_validate_options(*e)).to_json(); });
        }
    } else {
        register_docs_commands(registry);
        register_api_export_commands(registry);
        register_setup_commands(registry);
    }
    register_api_reference_command(registry, engine.scripts());
    {
        CommandInfo info;
        info.name = "project.templates";
        info.summary = "List the project templates `project.create` can start from.";
        info.description = "Returns [{name, description, dimension}]. Example: {}.";
        info.category = "project";
        registry.add(info, [](const Json&) {
            Json arr = Json::array();
            for (const auto& t : list_templates())
                arr.push_back(Json::object({{"name", t.name}, {"description", t.description}, {"dimension", t.dimension}}));
            return arr;
        });
    }
    {
        CommandInfo info;
        info.name = "project.create";
        info.summary = "Create a new game project from a template.";
        info.description =
            "Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, "
            "scripts, a test, AGENTS.md, ENGINE_FEEDBACK.json and the real types/factoria.d.ts. Afterwards start "
            "`factoria mcp --project <dir>` to work on it. Example: {\"dir\":\"my-game\",\"template\":\"2d-platformer\",\"name\":\"My Game\"}.";
        info.readOnly = false;
        info.category = "project";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["dir"],
          "properties":{
            "dir":{"type":"string","description":"Target folder (created; must be empty or new)."},
            "template":{"type":"string","description":"2d-empty, 2d-platformer or 3d-empty (see project.templates).","default":"2d-empty"},
            "name":{"type":"string","description":"Display name (default: folder name)."},
            "id":{"type":"string","description":"Reverse-DNS id, e.g. com.example.mygame."}
          }})");
        registry.add(info, [](const Json& a) {
            ScaffoldOptions o;
            o.name = a.value("name", std::string());
            o.id = a.value("id", std::string());
            std::error_code ec;
            std::string dir = std::filesystem::absolute(std::filesystem::path(a.at("dir").get<std::string>()), ec).lexically_normal().string();
            auto r = create_project(dir, a.value("template", std::string("2d-empty")), o);
            if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
            return r->to_json();
        });
    }
}

}  // namespace fa
