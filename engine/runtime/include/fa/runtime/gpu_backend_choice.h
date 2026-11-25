// Which GPU backend a run asks for (M77-P9a): EngineConfig.gpuBackend, then the FA_GPU_BACKEND environment variable, then
// the player's stored choice (graphics.backend, M77-P9e2), then factoria.json render.backend, then "auto". Pure functions,
// so tests and tools can check the decision without an engine; read_gpu_backend_setting and write_gpu_backend_setting are
// the two that touch a file.
#pragma once

#include <filesystem>
#include <functional>
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

// The start of a reason that says the WINDOW cannot take a swapchain of that backend at all (sokol_app keeps its OpenGL surface
// on it: Linux EGL builds only; app_native_window().busy), not that a driver or GPU is missing. A Linux GLX window
// (M77-P9e3a) and an Android window (M77-P9e3b) hand their surface over, so a claim refused there is a driver's reason. The engine builds it
// (gpu_window_path_reason); the Vulkan player passes it on in kGpuFallbackReasonEnv, and the warning of the OpenGL player
// that starts then does not promise that a driver update brings Vulkan back.
inline constexpr const char* kGpuWindowPathReason = "the window path is not available on this platform yet";
std::string gpu_window_path_reason(const std::string& backend, const std::string& why);
bool is_gpu_window_path_reason(const std::string& reason);

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

// The inputs of a run as the engine and the window runner read them, so both ask the same question: EngineConfig's name,
// FA_GPU_BACKEND, the stored choice (only when `readStored`: not with memoryStorage; a file that cannot be read is told
// in *storedWarning), the project's render.backend, what auto means in this binary and the fallback marker.
GpuBackendInputs make_gpu_backend_inputs(const std::string& configValue, bool readStored, GpuBackend autoBackend,
                                         const std::string& projectValue, std::string* storedWarning);

// Resolves the places in the order above. Names are those of gpu_backend_name. An unknown name in EngineConfig or the
// variable is an error with the valid names and a did-you-mean (the place says where it came from); one in the stored
// choice is a warning and is skipped (the file belongs to the player's machine, not to the game). A valid name this binary
// cannot make is a warning and "auto". A fallback marker adds one warning that says which player could not start and why
// (and replaces the "this binary does not have it" warning of that same backend).
Result<GpuBackendChoice> choose_gpu_backend(const GpuBackendInputs& in);
// The three-place form of M77-P9a (no stored choice, no marker, auto = the sokol backend).
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

// Called with the first error when the backend asked for failed and the run is about to fall back in process.
using GpuBackendFailed = std::function<void(const std::string& why)>;

// The in-process fallback (M77-P9e1): starts `asked`; when it fails and it is not one that runs on the sokol context
// (gpu_backend_on_context: D3d12, Vulkan), starts Default (the build's sokol backend, `defaultName` in the warning)
// and keeps the first error as the reason. Default or the build's own sokol backend failing is not retried: there is
// nothing else to draw with. `failed` (EngineConfig::gpuBackendFailed, M77-P9e2) runs first, before the warning and the
// second start: it may replace the process (the Vulkan player starts the OpenGL player, so a Vulkan failure reaches it
// and is not hidden by this fallback); the fallback goes on when it returns. Pure, so every platform's tests check it
// with a `start` that fails on purpose.
GpuBackendStartResult start_gpu_backend(GpuBackend asked, const GpuBackendStart& start, const std::string& defaultName,
                                        bool windowed, const GpuBackendFailed& failed = {});

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
