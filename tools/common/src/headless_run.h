// The headless run the measuring and tracing commands share (perf.measure, perf.profile, script.trace): a second engine
// inside this process with the fake platform, in-memory storage and a fixed timestep, so the same input gives the same run.
#pragma once

#include <string>

#include "fa/runtime/engine.h"

namespace fa::tooling_detail {

// Throws CommandError "not_found" unless projectDir holds a factoria.json. `command` ("perf.*", "script.trace") names the
// caller in the message.
void require_project_dir(const std::string& projectDir, const std::string& command);

// `p` as is when absolute, else relative to the project folder.
std::string project_path(const std::string& projectDir, const std::string& p);

// The engine configuration of a headless run. `graphics` false: no GPU at all (renderer() is null).
EngineConfig headless_engine_config(const std::string& projectDir, const std::string& scene, bool graphics, RenderMode renderMode);

}  // namespace fa::tooling_detail
