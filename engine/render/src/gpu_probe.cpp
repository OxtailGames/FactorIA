#include "fa/render/gpu_probe.h"

#include <string>

#include "gpu/vulkan_device.h"  // the options and the factory's declaration: the code is vulkan_*.cpp, built with FA_VULKAN_BACKEND

namespace fa {

Result<void> probe_gpu_backend(GpuBackend backend) {
    if (!gpu_backend_available(backend))
        return make_error(std::string("this build has no ") + gpu_backend_name(backend) + " backend",
                          "Use the player built with it (on Linux and Android: factoria_player_vulkan for Vulkan).");
    if (backend != GpuBackend::Vulkan) return {};
    // FA_RENDER_VULKAN, not FA_VULKAN_BACKEND: the OpenGL player of Android and Linux has the backend's sources in fa_render
    // but not the renderer on Vulkan, and this file must not name make_vulkan_device there (the linker would take the whole
    // Vulkan backend into that player). Only the Vulkan player recompiles it with FA_RENDER_VULKAN (fa_render_vulkan in
    // engine/render/CMakeLists.txt takes every source that tests it). Where it is off, gpu_backend_available() is false
    // for Vulkan and the check above has answered already.
#if defined(FA_RENDER_VULKAN)
    gpu::VulkanOptions options;
    options.uploadRingBytes = 64u * 1024u;  // the smallest pools the factory takes: nothing is uploaded
    options.memoryBlockBytes = 1024u * 1024u;
    options.dedicatedThreshold = 1024u * 1024u;
    options.frameDescriptorSets = 1;
    options.frameDescriptors = 1;
    options.frameDescriptorPools = 1;
    options.bindlessDescriptors = 0;
    auto device = gpu::make_vulkan_device(options);
    if (!device) return device.error();
    return {};
#else
    return make_error("this build has no Vulkan backend (FA_RENDER_VULKAN is off)",
                      "Use the player built with it (on Linux and Android: factoria_player_vulkan), or configure with "
                      "-DFA_RENDER_VULKAN=ON on a platform with Vulkan.");
#endif
}

}  // namespace fa
