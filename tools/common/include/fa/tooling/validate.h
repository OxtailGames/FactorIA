// Whole-project validation: `factoria validate`, command "project.validate".
//
// Checks: factoria.json vs schemas/project.schema.json (+ mainScene exists, input
// bindings valid), ENGINE_FEEDBACK.json present and valid, every scene/prefab in
// the project loads (messages from fa::load_scene_file are forwarded), asset
// paths referenced by reflected Asset fields exist, scenes and prefabs are in the canonical layout (warning), the
// `icon` / `export` settings of factoria.json (fa/tooling/export_settings.h) and the icon files they name, the files an
// export ships (texture size, a file over 20 MB, the total against the store limits) and the textures Sprites draw (fully
// transparent images, a background that should be transparent; docs/ASSETS.md, "Checks"), the "localization" section,
// the string tables (locales/<language>.json: missing, extra and misspelled keys, placeholders, plural forms), the `key`s of
// scenes and prefabs, and whether the fonts have a glyph for every character the game shows (docs/LOCALIZATION.md,
// "Checks"), scripts
// (via optional hooks installed by the CLI once the script module exists: syntax, Script.props, misspelled hooks).
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
// engine_validate_options (fa/tooling/tooling.h) builds this and the props check from an Engine.
using ScriptCheckHook = std::function<std::vector<ValidationIssue>(const std::string& projectDir, const std::string& scriptPath)>;

// Checks `Script.props` of a scene/prefab entity against the behaviour module: returns one message per prop that does
// not exist on the behaviour (empty = fine). Reported as warnings (ScriptSystem::check_props).
using ScriptPropsCheckHook = std::function<std::vector<std::string>(const std::string& modulePath, const Json& props)>;

// Checks one script (project-relative path): returns one message per method of its behaviour class that looks like a
// misspelled lifecycle hook (`update()` for onUpdate). Reported as warnings (ScriptSystem::check_hooks).
using ScriptHooksCheckHook = std::function<std::vector<std::string>(const std::string& modulePath)>;

struct ValidateOptions {
    ScriptPropsCheckHook propsCheck;  // empty: Script.props are not checked
    ScriptHooksCheckHook hooksCheck;  // empty: behaviour method names are not checked
    ScriptCheckHook scriptCheck;      // empty: scripts are counted, not compiled
    bool checkScenes = true;      // load scenes into a temporary World
};

ValidationReport validate_project(const std::string& projectDir, const ValidateOptions& options = {});

void register_validate_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
