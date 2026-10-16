// The child-process runner lives in fa_core (fa/core/process.h) since the export tooling needs it too. This header keeps
// the old spelling `fa::ai::run_process` working for the AI, MCP and editor code.
#pragma once

#include "fa/core/process.h"

namespace fa::ai {

using fa::ProcessOptions;
using fa::ProcessResult;
using fa::run_process;
using fa::which;

}  // namespace fa::ai
