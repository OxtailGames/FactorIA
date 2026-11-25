#include "fa/render/gpu_probe.h"

#include <string>

#include "gpu/vulkan_device.h"

namespace fa {

Result<void> probe_gpu_backend(GpuBackend backend) {
    if (!gpu_backend_available(backend))
        return make_error(std::string("this build has no ") + gpu_backend_name(backend) + " backend",
                          "Use the player built with it (on Linux and Android: factoria_player_vulkan for Vulkan).");
    if (backend != GpuBackend::Vulkan) return {};
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
}

}  // namespace fa
