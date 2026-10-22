// Source instrumenter of the script debugger (docs/design/SCRIPT_DEBUGGER.md, "The instrumented code").
//
// Parses a project module with acorn (external/acorn, run in a private QuickJS runtime) and returns a copy with a hook
// before every statement and a frame record around every function body, plus the ScriptDebugInfo that describes it.
// Text is only inserted, never a newline. The format is the contract with the script runtime (fa/script/debugger.h).
//
// Thread-safe: one lazily created runtime behind a mutex (the script thread and the DAP reader thread both call it).
// Developer tooling only: an exported game does not contain acorn.
#pragma once

#include <string>
#include <string_view>

#include "fa/script/debugger.h"

namespace fa {

// file: project-relative path ("scripts/player.js"), for error messages. moduleId: written into the code as
// `__fa_d.m(moduleId, ...)`. A source that does not parse gives an Error "file:line:column: message" (columns are
// 1-based UTF-8 byte columns); the runtime then compiles the original source so QuickJS reports the error itself.
Result<InstrumentedScript> instrument_script(const std::string& file, std::string_view source, int moduleId);

// instrument_script as a ScriptInstrumenter, for EngineConfig / ScriptDebugger.
ScriptInstrumenter script_instrumenter();

}  // namespace fa
