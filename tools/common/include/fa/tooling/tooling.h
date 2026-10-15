// fa_tooling umbrella header: everything developer tools share.
#pragma once

#include "fa/core/command.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/export.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/mcp_config.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"
#include "fa/runtime/engine.h"

namespace fa {

class Engine;

// Registers every tooling command for the project at `projectDir`:
// feedback.{report,list,update}, docs.{list,read,search,components,commands},
// fs.{list,read,write,edit,search,delete}, project.validate, project.export.
void register_tooling_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa

namespace fa {

// ONE command set everywhere (`factoria mcp/call/session/test/ai run`, the editor): registers on engine.commands()
//   register_tooling_commands(...)  plus project.templates, project.create, and a project.validate bound to this
//   engine (script syntax via check_syntax, Script.props via check_props).
// project.test is a built-in engine command. Call it once after Engine::init; a second call replaces the commands.
void register_project_commands(Engine& engine, const std::string& projectDir);

// Validation options backed by `engine`'s script system (syntax + Script.props checks). The engine must outlive them.
ValidateOptions engine_validate_options(Engine& engine);

}  // namespace fa
