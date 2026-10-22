// script.trace: how AIs debug scripts without an IDE (docs/DEBUGGING.md, "For AIs: script.trace"; the design is in
// docs/design/SCRIPT_DEBUGGER.md). A headless run with tracepoints: each hit records the stack, the locals and watch
// expressions as JSON; logpoints collect text. Built on the script debugger (fa/script/debugger.h) and the instrumenter
// (fa/tooling/script_instrument.h).
#pragma once

#include <string>

#include "fa/core/command.h"

namespace fa {

void register_script_trace_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
