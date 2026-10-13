// Metal readback: blit the render target into a shared buffer and wait. UNTESTED (no Apple toolchain here).
#include "render_internal.h"

#if defined(SOKOL_METAL)

#import <Metal/Metal.h>

#include <cstring>

namespace fa::render {

bool readback_rgba8(sg_image image, int width, int height, std::vector<std::uint8_t>& out, std::string* error) {
    id<MTLTexture> tex = (__bridge id<MTLTexture>)sg_mtl_query_image_info(image).tex[sg_mtl_query_image_info(image).active_slot];
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)sg_mtl_command_queue();
    id<MTLDevice> device = (__bridge id<MTLDevice>)sg_mtl_device();
    if (!tex || !queue || !device) {
        if (error) *error = "capture: no Metal texture for the game target";
        return false;
    }
    NSUInteger bytesPerRow = NSUInteger(width) * 4;
    id<MTLBuffer> buf = [device newBufferWithLength:bytesPerRow * NSUInteger(height) options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromTexture:tex sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0)
               sourceSize:MTLSizeMake(width, height, 1) toBuffer:buf destinationOffset:0
        destinationBytesPerRow:bytesPerRow destinationBytesPerImage:bytesPerRow * NSUInteger(height)];
    [blit endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];
    out.resize(bytesPerRow * NSUInteger(height));
    std::memcpy(out.data(), [buf contents], out.size());  // Metal rows are top-down
    return true;
}

}  // namespace fa::render

#endif
