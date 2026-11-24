// Which GPU backend a run asks for (M77-P9a): EngineConfig.gpuBackend, then the FA_GPU_BACKEND environment variable, then
// factoria.json render.backend, then "auto". Pure functions, so tests and tools can check the decision without an engine.
#pragma once

#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/render/renderer.h"

namespace fa {

struct GpuBackendChoice {
    GpuBackend backend = GpuBackend::Default;  // Default = auto: the backend this binary was built with
    GpuBackend requested =
        GpuBackend::Default;         // what was asked, even when this binary has none of it (then backend is Default)
    std::string source = "default";  // "EngineConfig", "FA_GPU_BACKEND", "factoria.json" or "default"
    std::string asked;               // the name that was asked ("" when nothing was); "auto" is a request for auto
    std::vector<std::string> warnings;  // what this platform or binary does not have (then backend is Default)
};

// Resolves the three places. `configValue` and `envValue` ("" or null = not set) are names of gpu_backend_name;
// `projectValue` is ProjectSettings::renderBackend. An unknown name is an error with the valid names and a did-you-mean
// (the JSON pointer-like place says where it came from). A valid name this binary cannot make is a warning and "auto".
Result<GpuBackendChoice> choose_gpu_backend(const std::string& configValue, const char* envValue,
                                            const std::string& projectValue);

// The one warning of a window that could not use the backend it asked for: what was asked, why it failed and what draws.
std::string gpu_backend_fallback_warning(GpuBackend asked, const std::string& why, const std::string& used);

}  // namespace fa
