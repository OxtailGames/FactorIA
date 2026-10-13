// fa_tooling umbrella header: everything developer tools share.
#pragma once

#include "fa/core/command.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/mcp_config.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

namespace fa {

// Registers every tooling command for the project at `projectDir`:
// feedback.{report,list,update}, docs.{list,read,search,components,commands},
// fs.{list,read,write,edit,search,delete}, project.validate.
void register_tooling_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
