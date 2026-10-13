// Whole-project validation: `factoria validate`, command "project.validate".
//
// Checks: factoria.json vs schemas/project.schema.json (+ mainScene exists, input
// bindings valid), ENGINE_FEEDBACK.json present and valid, every scene/prefab in
// the project loads (messages from fa::load_scene_file are forwarded), asset
// paths referenced by reflected Asset fields exist, scripts (via an optional
// syntax-check hook installed by the CLI once the script module exists).
#pragma once

#include <functional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa {

struct ValidationIssue {
    std::string file;     // project-relative file ("scenes/main.scene.json")
    std::string pointer;  // JSON pointer inside the file ("" when not applicable)
    std::string message;
    std::string hint;
    Json to_json() const;
    std::string to_string() const;  // "file#/pointer: message (hint: ...)"
};

struct ValidationReport {
    bool ok = true;  // no errors (warnings allowed)
    std::vector<ValidationIssue> errors;
    std::vector<ValidationIssue> warnings;
    int scenesChecked = 0;
    int scriptsChecked = 0;
    Json to_json() const;
    std::string to_text() const;  // multi-line, for the CLI
};

// Checks one script file (project-relative path) and returns syntax errors.
// Installed by the CLI when the script module is available.
using ScriptCheckHook = std::function<std::vector<ValidationIssue>(const std::string& projectDir, const std::string& scriptPath)>;
void set_script_check_hook(ScriptCheckHook hook);  // process-wide default

// Checks `Script.props` of a scene/prefab entity against the behaviour module: returns one message per prop that does
// not exist on the behaviour (empty = fine). Reported as warnings. Installed by the CLI (ScriptSystem::check_props).
using ScriptPropsCheckHook = std::function<std::vector<std::string>(const std::string& modulePath, const Json& props)>;
void set_script_props_check_hook(ScriptPropsCheckHook hook);  // process-wide default

struct ValidateOptions {
    ScriptPropsCheckHook propsCheck;  // overrides the process-wide hook when set
    ScriptCheckHook scriptCheck;  // overrides the process-wide hook when set
    bool checkScenes = true;      // load scenes into a temporary World
};

ValidationReport validate_project(const std::string& projectDir, const ValidateOptions& options = {});

void register_validate_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
