// Project scaffolding: `factoria new`.
//
// A template is a folder under templates/ (bundled in the binary). Files of
// templates/common/ are copied first, then the template's own files on top.
// Text files get placeholders replaced:
//   {{PROJECT_NAME}} {{PROJECT_ID}} {{ENGINE_VERSION}} {{DATE}}
// (inside .json files the values are JSON-escaped).
// Always generated: ENGINE_FEEDBACK.json, AGENTS.md + CLAUDE.md (same guide),
// .gitignore, jsconfig.json, .mcp.json (Claude Code), types/factoria.d.ts (the real typings).
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct TemplateInfo {
    std::string name;         // "2d-platformer"
    std::string description;  // from the template's template.json
    std::string dimension;    // "2d" | "3d"
};

struct ScaffoldOptions {
    std::string name;  // display name; default = target folder name
    std::string id;    // reverse-DNS id; default "com.example.<slug>"
    std::string engineVersion;  // default FA_ENGINE_VERSION
    bool writeTypings = true;  // generate the real types/factoria.d.ts (needs a logic-only Engine); false = placeholder
    bool force = false;  // allow a non-empty target dir (overwrites template files, keeps others)
};

struct ScaffoldResult {
    std::string dir;                 // absolute project directory
    std::vector<std::string> files;  // project-relative files written, sorted
    std::string templateName;
    Json to_json() const;
};

std::vector<TemplateInfo> list_templates();
Result<ScaffoldResult> create_project(const std::string& targetDir, const std::string& templateName,
                                      const ScaffoldOptions& options = {});

// Regenerates <projectDir>/types/factoria.d.ts from the engine's script API (starts a throw-away logic-only Engine;
// the global VFS root is restored afterwards). Returns the written path.
Result<std::string> write_project_typings(const std::string& projectDir);

// Text of the generated AGENTS.md / CLAUDE.md for a project (from templates/common/AGENTS.md).
std::string render_agents_guide(const std::string& projectName, const std::string& engineVersion = {});

}  // namespace fa
