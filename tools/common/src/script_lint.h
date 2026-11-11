// Checks of a gameplay script against the engine's API that need no type inference (`factoria validate`): the names it
// imports from "factoria" and "factoria:test", `ns.member` on an imported namespace, and literal component names passed to
// `get`/`add`/`has`/`remove`. A text scan with comments and strings masked, not a parser: it only reports what it is sure of.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/tooling/validate.h"

namespace fa::tooling_detail {

struct ScriptLintResult {
    std::vector<ValidationIssue> errors;
    std::vector<ValidationIssue> warnings;
};

// `file` is the project-relative path (messages start with "file:line:column"), `text` its source, `manifest` the scripting
// API (ScriptSystem::api_manifest()). Components come from TypeRegistry::global().
ScriptLintResult lint_script(const std::string& file, const std::string& text, const Json& manifest);

}  // namespace fa::tooling_detail
