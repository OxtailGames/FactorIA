// Which player process draws a game on Linux and Android (M77-P9e2, docs/RENDERING.md "Choosing the GPU backend").
//
// There the player comes in two variants: the OpenGL one (factoria_player, libfactoria_player.so) and the Vulkan one
// (factoria_player_vulkan, libfactoria_player_vulkan.so), whose renderer carries the SPIR-V of the built-in shaders and the
// Vulkan backend. One process cannot fall back from Vulkan to OpenGL there (sokol_app owns the GL context), so the Vulkan
// player that cannot start Vulkan starts the OpenGL player in its place, with the same arguments and environment plus the
// marker of fa/runtime/gpu_backend_choice.h (kGpuFallbackFromEnv, kGpuFallbackReasonEnv). The OpenGL player never starts
// another one, and neither does a player that carries the marker: no loop.
//
// decide_gpu_launch is the pure decision (tests run it on every host); exec_gl_player does it on Linux.
#pragma once

#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/types.h"
#include "fa/render/renderer.h"

namespace fa {

enum class GpuLaunchAction : std::uint8_t {
    Stay,          // this process draws the game
    RunGl,         // the game asks for OpenGL: the OpenGL player draws it (no marker: nothing failed)
    FallBackToGl,  // Vulkan could not start: the OpenGL player draws it, with the marker and the reason
};

struct GpuLaunchInput {
    bool vulkanPlayer = false;                 // this process is the Vulkan player (FA_PLAYER_VULKAN_VARIANT)
    bool glPlayerPresent = false;              // the OpenGL player sits next to it (gl_player_path)
    GpuBackend backend = GpuBackend::Default;  // GpuBackendChoice::backend: what this process would draw with
    std::string fallbackFrom;   // GpuBackendChoice::fallbackFrom: this process was itself started by a fallback
    std::string vulkanFailure;  // "" = Vulkan started (or was not tried); else why it could not (probe_gpu_backend)
};

struct GpuLaunchDecision {
    GpuLaunchAction action = GpuLaunchAction::Stay;
    std::string reason;  // one sentence: why this process stays or which player runs and why
};

// The decision. In order: the OpenGL player stays; a process started by a fallback stays; a Vulkan player whose game asks
// for another backend (gl, gles3) runs the OpenGL player when it is there (else draws it itself: the Vulkan player still
// has the sokol backend); a Vulkan player whose Vulkan failed falls back to the OpenGL player when it is there (else draws
// with the sokol backend in this process); otherwise it stays and draws with Vulkan.
GpuLaunchDecision decide_gpu_launch(const GpuLaunchInput& in);
const char* gpu_launch_action_name(GpuLaunchAction a);  // "stay", "runGl", "fallBackToGl"

// The file name of the OpenGL player next to the Vulkan player `vulkanName`: "factoria_player_vulkan" -> "factoria_player"
// (a build tree), any other name "<name>-gl" (an exported game: "mygame" -> "mygame-gl"). The same rule as the exports
// (export_detail::desktop_player_files).
std::string gl_player_name(const std::string& vulkanName);
// The OpenGL player next to this executable (/proc/self/exe on Linux); empty where it is not there or off Linux.
std::filesystem::path gl_player_path();

// Linux: replaces this process with `glPlayer` (execv), argv unchanged (argv[0] becomes the new path), the environment
// unchanged plus the marker when `fromBackend` is not empty. Returns only when the exec failed (the error says why); the
// caller then draws in this process. Off Linux it returns an error at once.
Result<void> exec_gl_player(const std::filesystem::path& glPlayer, const std::vector<std::string>& argv,
                            const std::string& fromBackend, const std::string& reason);

#if defined(__ANDROID__)
// Android: starts the OpenGL activity (factoria.engine.GlActivity, which loads libfactoria_player.so in its own process
// ":gl") with the marker as intent extras when `fromBackend` is not empty, and finishes this one. `nativeActivity` is the
// ANativeActivity of the Vulkan player.
Result<void> android_start_gl_activity(void* nativeActivity, const std::string& fromBackend, const std::string& reason);
// Android, in the OpenGL activity: copies the marker extras of the intent that started it into the environment, where
// choose_gpu_backend reads them. Does nothing when the intent has none.
void android_take_gpu_fallback_extras(void* nativeActivity);
#endif

}  // namespace fa
