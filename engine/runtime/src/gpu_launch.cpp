#include "fa/runtime/gpu_launch.h"

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "fa/core/fs.h"
#include "fa/runtime/gpu_backend_choice.h"

#if defined(__linux__) && !defined(__ANDROID__)
#include <unistd.h>
#endif

namespace fa {

GpuLaunchDecision decide_gpu_launch(const GpuLaunchInput& in) {
    GpuLaunchDecision d;
    if (!in.vulkanPlayer) {
        d.reason = "this is the OpenGL player: it draws the game itself and never starts another player";
        return d;
    }
    if (!in.fallbackFrom.empty()) {
        d.reason = "this player was started in place of the " + in.fallbackFrom +
                   " one: it draws the game itself and never starts another player";
        return d;
    }
    const bool wantsVulkan = in.backend == GpuBackend::Vulkan;
    if (!wantsVulkan) {
        if (in.glPlayerPresent) {
            d.action = GpuLaunchAction::RunGl;
            d.reason = std::string("the game asks for the ") +
                       (in.backend == GpuBackend::Default ? "sokol (OpenGL)" : gpu_backend_name(in.backend)) +
                       " backend, which the OpenGL player draws with";
        } else {
            d.reason = "the game asks for another backend than Vulkan and the OpenGL player is not next to this one: "
                       "this player draws with its own sokol backend";
        }
        return d;
    }
    if (!in.vulkanFailure.empty()) {
        if (in.glPlayerPresent) {
            d.action = GpuLaunchAction::FallBackToGl;
            d.reason = "Vulkan cannot start (" + in.vulkanFailure + "): the OpenGL player draws the game";
        } else {
            d.reason = "Vulkan cannot start (" + in.vulkanFailure +
                       ") and the OpenGL player is not next to this one: this player draws with its own sokol backend";
        }
        return d;
    }
    d.reason = "this player draws with Vulkan";
    return d;
}

const char* gpu_launch_action_name(GpuLaunchAction a) {
    switch (a) {
        case GpuLaunchAction::Stay: return "stay";
        case GpuLaunchAction::RunGl: return "runGl";
        case GpuLaunchAction::FallBackToGl: return "fallBackToGl";
    }
    return "stay";
}

std::string gl_player_name(const std::string& vulkanName) {
    static constexpr const char kSuffix[] = "_vulkan";
    constexpr std::size_t n = sizeof(kSuffix) - 1;
    if (vulkanName.size() > n && vulkanName.compare(vulkanName.size() - n, n, kSuffix) == 0)
        return vulkanName.substr(0, vulkanName.size() - n);
    return vulkanName + "-gl";
}

std::filesystem::path gl_player_path() {
#if defined(__linux__) && !defined(__ANDROID__)
    std::error_code ec;
    const std::filesystem::path self = std::filesystem::read_symlink("/proc/self/exe", ec);
    if (ec || self.empty()) return {};
    const std::filesystem::path gl =
        self.parent_path() / fs::path_from_utf8(gl_player_name(fs::path_to_utf8(self.filename())));
    if (!std::filesystem::is_regular_file(gl, ec)) return {};
    if (::access(gl.c_str(), X_OK) != 0) return {};
    return gl;
#else
    return {};
#endif
}

Result<void> exec_gl_player(const std::filesystem::path& glPlayer, const std::vector<std::string>& argv,
                            const std::string& fromBackend, const std::string& reason) {
#if defined(__linux__) && !defined(__ANDROID__)
    if (glPlayer.empty())
        return make_error("cannot start the OpenGL player: it is not next to this one",
                          "Export the game again (it ships both players) or set FA_GPU_BACKEND=gl.");
    if (!fromBackend.empty()) {
        ::setenv(kGpuFallbackFromEnv, fromBackend.c_str(), 1);
        ::setenv(kGpuFallbackReasonEnv, reason.c_str(), 1);
    }
    // argv lives in `args` until execv replaces the process (or returns): the strings are not copied again.
    std::vector<std::string> args = argv;
    if (args.empty()) args.emplace_back();
    args[0] = glPlayer.native();
    std::vector<char*> raw;
    raw.reserve(args.size() + 1);
    for (std::string& a : args) raw.push_back(a.data());
    raw.push_back(nullptr);
    std::fflush(nullptr);  // what this process printed comes before what the OpenGL player prints
    ::execv(glPlayer.c_str(), raw.data());
    const int err = errno;  // execv returns only on failure
    ::unsetenv(kGpuFallbackFromEnv);
    ::unsetenv(kGpuFallbackReasonEnv);
    return make_error("cannot start the OpenGL player " + fs::path_to_utf8(glPlayer) + ": " + std::strerror(err),
                      "Check that the file is there and executable (chmod +x); this player draws the game itself.");
#else
    (void)glPlayer;
    (void)argv;
    (void)fromBackend;
    (void)reason;
    return make_error("starting the OpenGL player in place of this one is done on Linux only",
                      "On Android the Vulkan activity starts the OpenGL activity (android_start_gl_activity).");
#endif
}

}  // namespace fa
