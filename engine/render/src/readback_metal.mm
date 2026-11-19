// Metal readback: blit the render target into a shared buffer and wait. Covered by the render goldens on macOS.
#include "render_internal.h"

#if defined(SOKOL_METAL)

#import <Metal/Metal.h>

#include <cstring>

#include "hdr_encode.h"

namespace fa::render {

bool readback_rgba8(sg_image image, int width, int height, std::vector<std::uint8_t>& out, std::string* error) {
    // The command buffer and its encoder are autoreleased. A headless run has no run loop to drain the pool, so without an
    // own pool every capture kept its buffer (one frame of pixels) until the process ended: 8 MB a frame at 1080p.
    @autoreleasepool {
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
}

bool readback_rgba16f(sg_image image, int width, int height, std::vector<float>& out, std::string* error) {
    @autoreleasepool {
    id<MTLTexture> tex = (__bridge id<MTLTexture>)sg_mtl_query_image_info(image).tex[sg_mtl_query_image_info(image).active_slot];
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)sg_mtl_command_queue();
    id<MTLDevice> device = (__bridge id<MTLDevice>)sg_mtl_device();
    if (!tex || !queue || !device) {
        if (error) *error = "readback: no Metal texture for the image";
        return false;
    }
    if (tex.pixelFormat != MTLPixelFormatRGBA16Float) {
        if (error) *error = "readback: the image is not RGBA16F";
        return false;
    }
    NSUInteger bytesPerRow = NSUInteger(width) * 8;
    id<MTLBuffer> buf = [device newBufferWithLength:bytesPerRow * NSUInteger(height) options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromTexture:tex sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0)
               sourceSize:MTLSizeMake(width, height, 1) toBuffer:buf destinationOffset:0
        destinationBytesPerRow:bytesPerRow destinationBytesPerImage:bytesPerRow * NSUInteger(height)];
    [blit endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];
    const std::size_t n = std::size_t(width) * std::size_t(height) * 4;
    std::vector<std::uint16_t> halves(n);
    std::memcpy(halves.data(), [buf contents], n * 2);
    out.resize(n);
    for (std::size_t i = 0; i < n; ++i) out[i] = half_to_float(halves[i]);
    return true;
    }
}

bool readback_storage_image(sg_image image, sg_pixel_format format, int width, int height, std::vector<std::uint8_t>& out,
                            std::string* error) {
    @autoreleasepool {
    const sg_mtl_image_info info = sg_mtl_query_image_info(image);
    id<MTLTexture> tex = (__bridge id<MTLTexture>)info.tex[info.active_slot];
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)sg_mtl_command_queue();
    id<MTLDevice> device = (__bridge id<MTLDevice>)sg_mtl_device();
    if (!tex || !queue || !device) {
        if (error) *error = "readback: no Metal texture for the storage image";
        return false;
    }
    const NSUInteger pixel = NSUInteger(sg_query_pixelformat(format).bytes_per_pixel);
    if (pixel == 0 || NSUInteger(width) > tex.width || NSUInteger(height) > tex.height) {
        if (error) *error = "readback: the storage image does not have the size or format asked for";
        return false;
    }
    const NSUInteger bytesPerRow = NSUInteger(width) * pixel, bytes = bytesPerRow * NSUInteger(height);
    // The caller committed the sokol command buffer that holds the dispatches; this blit goes after it on the same queue.
    id<MTLBuffer> buf = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
    if (!buf) {
        if (error) *error = "readback: Metal could not allocate " + std::to_string(bytes) + " bytes to read into";
        return false;
    }
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromTexture:tex sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0)
               sourceSize:MTLSizeMake(NSUInteger(width), NSUInteger(height), 1) toBuffer:buf destinationOffset:0
        destinationBytesPerRow:bytesPerRow destinationBytesPerImage:bytes];
    [blit endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];
    out.resize(std::size_t(bytes));
    std::memcpy(out.data(), [buf contents], std::size_t(bytes));
    return true;
    }
}

bool storage_image_loadable(sg_pixel_format format, std::string* why) {
    id<MTLDevice> device = (__bridge id<MTLDevice>)sg_mtl_device();
    const MTLReadWriteTextureTier tier = [device readWriteTextureSupport];
    // Tier 1 (older Intel Macs, iOS A9-A10) reads and writes only the single-channel 32-bit formats in one texture; Tier 2
    // adds the 8-bit, 16-bit float and 32-bit float RGBA ones.
    if (tier == MTLReadWriteTextureTier2) return true;
    if (tier == MTLReadWriteTextureTier1 && format == SG_PIXELFORMAT_R32F) return true;
    if (why)
        *why = std::string("this Metal GPU supports reading and writing one texture only for r32f (read-write texture tier ") +
               (tier == MTLReadWriteTextureTier1 ? "1" : "none") + ")";
    return false;
}

bool readback_buffer(sg_buffer buffer, std::size_t offset, std::size_t bytes, std::vector<std::uint8_t>& out,
                     std::string* error) {
    @autoreleasepool {
    const sg_mtl_buffer_info info = sg_mtl_query_buffer_info(buffer);
    id<MTLBuffer> src = (__bridge id<MTLBuffer>)info.buf[info.active_slot];
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)sg_mtl_command_queue();
    id<MTLDevice> device = (__bridge id<MTLDevice>)sg_mtl_device();
    if (!src || !queue || !device) {
        if (error) *error = "readback: no Metal buffer for the storage buffer";
        return false;
    }
    if (offset > std::size_t(src.length) || bytes > std::size_t(src.length) - offset) {
        if (error) *error = "readback: the range is outside the storage buffer";
        return false;
    }
    out.resize(bytes);
    if (bytes == 0) return true;
    // A copy through a shared buffer: the same code serves a managed (Intel) and a private-memory buffer, and the blit
    // runs after the sokol command buffer that holds the dispatches (one queue, in order; the caller committed it).
    id<MTLBuffer> dst = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
    if (!dst) {
        if (error) *error = "readback: Metal could not allocate " + std::to_string(bytes) + " bytes to read into";
        return false;
    }
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromBuffer:src sourceOffset:offset toBuffer:dst destinationOffset:0 size:bytes];
    [blit endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];
    std::memcpy(out.data(), [dst contents], bytes);
    return true;
    }
}

}  // namespace fa::render

#endif
