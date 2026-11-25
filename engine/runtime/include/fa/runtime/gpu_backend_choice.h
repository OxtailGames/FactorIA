// Which GPU backend a run asks for (M77-P9a): EngineConfig.gpuBackend, then the FA_GPU_BACKEND environment variable, then
// factoria.json render.backend, then "auto". Pure functions, so tests and tools can check the decision without an engine.
#pragma once

#include <functional>
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

// The one warning of a run that could not use the backend it asked for (M77-P9e1): what was asked, why it failed (the
// first error, kept whole), what draws instead and how to choose. `windowed`: the window draws with `used`, else the
// headless run does.
std::string gpu_backend_fallback_warning(GpuBackend asked, const std::string& why, const std::string& used,
                                         bool windowed = true);

// One start of the renderer on `backend`: "" = it started; else why not (the device's or the swapchain's error).
using GpuBackendStart = std::function<std::string(GpuBackend backend)>;

struct GpuBackendStartResult {
    bool ok = false;
    GpuBackend used = GpuBackend::Default;  // the backend that started (the last one tried when none did)
    // The first attempt's error when the run fell back to Default ("" = it did not fall back): the startup report's
    // gpu.backendFallback.
    std::string fallbackReason;
    std::string warning;  // gpu_backend_fallback_warning of that fallback ("" = none)
    std::string error;    // !ok: what failed, every attempt's error (the first one first)
};

// The in-process fallback (M77-P9e1): starts `asked`; when it fails and it is not one that runs on the sokol context
// (gpu_backend_on_context: D3d12, Vulkan), starts Default (the build's sokol backend, `defaultName` in the warning)
// and keeps the first error as the reason. Default or the build's own sokol backend failing is not retried: there is
// nothing else to draw with. Pure, so every platform's tests check it with a `start` that fails on purpose.
GpuBackendStartResult start_gpu_backend(GpuBackend asked, const GpuBackendStart& start, const std::string& defaultName,
                                        bool windowed);

}  // namespace fa
