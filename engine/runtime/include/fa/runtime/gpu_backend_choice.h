// Which GPU backend a run asks for (M77-P9a): EngineConfig.gpuBackend, then the FA_GPU_BACKEND environment variable, then
// the player's stored choice (graphics.backend, M77-P9e2), then factoria.json render.backend, then "auto". Pure functions,
// so tests and tools can check the decision without an engine; read_gpu_backend_setting and write_gpu_backend_setting are
// the two that touch a file.
#pragma once

#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/render/renderer.h"

namespace fa {

// The marker of a player that another player started because its backend could not start (M77-P9e2,
// fa/runtime/gpu_launch.h): the backend that failed ("vulkan") and why. A player that finds it never relaunches again, and
// names it in its startup report (gpu.fallbackFrom, gpu.fallbackReason) and in graphics.backend.
inline constexpr const char* kGpuFallbackFromEnv = "FA_GPU_FALLBACK_FROM";
inline constexpr const char* kGpuFallbackReasonEnv = "FA_GPU_FALLBACK_REASON";

struct GpuBackendChoice {
    GpuBackend backend = GpuBackend::Default;  // Default = auto: the backend this binary was built with
    GpuBackend requested =
        GpuBackend::Default;  // what was asked, even when this binary has none of it (then backend is Default)
    // "EngineConfig", "FA_GPU_BACKEND", "user settings" (graphics.backend), "factoria.json" or "default"
    std::string source = "default";
    std::string asked;                  // the name that was asked ("" when nothing was); "auto" is a request for auto
    std::vector<std::string> warnings;  // what this platform or binary does not have (then backend is Default)
    std::string fallbackFrom;           // the backend another player could not start (kGpuFallbackFromEnv), or ""
    std::string fallbackReason;         // why it could not (kGpuFallbackReasonEnv), or ""
};

// Everything the choice reads. "" (or null) = not set.
struct GpuBackendInputs {
    std::string config;         // EngineConfig::gpuBackend: an unknown name is an error
    const char* env = nullptr;  // FA_GPU_BACKEND: an unknown name is an error
    std::string user;           // the player's stored choice (read_gpu_backend_setting): an unknown name is a warning
    std::string project;        // ProjectSettings::renderBackend ("auto" = not set)
    // What "auto" means in this binary: Default = the sokol backend it was built with; the Vulkan player
    // (factoria_player_vulkan, EngineConfig::gpuBackendAuto) puts Vulkan here. Used only when this binary has it and no
    // fallback marker names it.
    GpuBackend autoBackend = GpuBackend::Default;
    const char* fallbackFrom = nullptr;    // kGpuFallbackFromEnv
    const char* fallbackReason = nullptr;  // kGpuFallbackReasonEnv
};

// Resolves the places in the order above. Names are those of gpu_backend_name. An unknown name in EngineConfig or the
// variable is an error with the valid names and a did-you-mean (the place says where it came from); one in the stored
// choice is a warning and is skipped (the file belongs to the player's machine, not to the game). A valid name this binary
// cannot make is a warning and "auto". A fallback marker adds one warning that says which player could not start and why
// (and replaces the "this binary does not have it" warning of that same backend).
Result<GpuBackendChoice> choose_gpu_backend(const GpuBackendInputs& in);
// The three-place form of M77-P9a (no stored choice, no marker, auto = the sokol backend).
Result<GpuBackendChoice> choose_gpu_backend(const std::string& configValue, const char* envValue,
                                            const std::string& projectValue);

// The one warning of a window that could not use the backend it asked for: what was asked, why it failed and what draws.
std::string gpu_backend_fallback_warning(GpuBackend asked, const std::string& why, const std::string& used);

// The file of the player's stored backend choice: graphics_backend.json in `userDir` (fs::user_dir(): the save folder of
// the game), {"backend": "<name>"}.
inline constexpr const char* kGpuBackendSettingFile = "graphics_backend.json";
// The stored name, "" when there is none. A file that cannot be read or holds no string `backend` is "" and a warning
// in *warning (the start goes on with the other places).
std::string read_gpu_backend_setting(const std::filesystem::path& userDir, std::string* warning);
// Stores `name` ("auto" removes the file: nothing stored). The write replaces the file in one step (fs::write_text): a
// failure leaves the old file and says why.
Result<void> write_gpu_backend_setting(const std::filesystem::path& userDir, const std::string& name);

}  // namespace fa
