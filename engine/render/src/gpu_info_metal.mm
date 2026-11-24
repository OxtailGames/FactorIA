// Metal: the name and the memory of the device (gpu_info.cpp). The MTLDevice is the gpu::Device's native one.
#include <algorithm>
#include <cstdint>

#include "fa/render/gpu_info.h"

#if defined(SOKOL_METAL)

#import <Metal/Metal.h>

namespace fa::render {

bool gpu_info_metal(const void* mtlDevice, GpuInfo& info) {
    id<MTLDevice> device = (__bridge id<MTLDevice>)mtlDevice;
    if (!device) return false;
    const char* name = [[device name] UTF8String];
    info.name = name ? name : "";
    info.unifiedMemory = [device hasUnifiedMemory];
    // The most memory the GPU should use (about 2/3 to 3/4 of the RAM on an Apple chip): the figure a game can plan with.
    const unsigned long long ws = [device recommendedMaxWorkingSetSize];
    info.memoryMB = std::int64_t(std::min<unsigned long long>(ws / (1024ull * 1024ull), 1ull << 30));
    return true;
}

}  // namespace fa::render

#endif
