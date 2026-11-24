// Metal readback (gpu/sokol_native.h): blit the render target into a shared buffer and wait. Covered by the render
// goldens on macOS. The Metal objects come from the Device's natives.
#include "gpu/sokol_native.h"

#if defined(SOKOL_METAL)

#import <Metal/Metal.h>

#include <cstring>

#include "gpu/device.h"
#include "hdr_encode.h"

namespace fa::gpu {

namespace {

// The texture of `image` and the device's queue and MTLDevice (nil when the device has none).
struct MetalObjects {
    id<MTLTexture> tex = nil;
    id<MTLBuffer> buf = nil;
    id<MTLCommandQueue> queue = nil;
    id<MTLDevice> device = nil;
};

MetalObjects metal_objects(const Device& device) {
    const NativeDevice n = device.native();
    MetalObjects m;
    m.queue = (__bridge id<MTLCommandQueue>)n.commandQueue;
    m.device = (__bridge id<MTLDevice>)n.device;
    return m;
}

MetalObjects metal_objects(const Device& device, Image image) {
    MetalObjects m = metal_objects(device);
    m.tex = (__bridge id<MTLTexture>)device.native_image(image).texture;
    return m;
}

MetalObjects metal_objects(const Device& device, Buffer buffer) {
    MetalObjects m = metal_objects(device);
    m.buf = (__bridge id<MTLBuffer>)device.native_buffer(buffer).buffer;
    return m;
}

}  // namespace

bool native_read_image_rgba8(Device& gpuDevice, Image image, int width, int height, std::vector<std::uint8_t>& out,
                             std::string* error) {
    // The command buffer and its encoder are autoreleased. A headless run has no run loop to drain the pool, so without an
    // own pool every capture kept its buffer (one frame of pixels) until the process ended: 8 MB a frame at 1080p.
    @autoreleasepool {
    const MetalObjects m = metal_objects(gpuDevice, image);
    id<MTLTexture> tex = m.tex;
    id<MTLCommandQueue> queue = m.queue;
    id<MTLDevice> device = m.device;
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

bool native_read_image_rgba16f(Device& gpuDevice, Image image, int width, int height, std::vector<float>& out,
                               std::string* error) {
    @autoreleasepool {
    const MetalObjects m = metal_objects(gpuDevice, image);
    id<MTLTexture> tex = m.tex;
    id<MTLCommandQueue> queue = m.queue;
    id<MTLDevice> device = m.device;
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
    for (std::size_t i = 0; i < n; ++i) out[i] = render::half_to_float(halves[i]);
    return true;
    }
}

bool native_read_storage_image(Device& gpuDevice, Image image, PixelFormat format, int x, int y, int width, int height,
                               std::vector<std::uint8_t>& out, std::string* error) {
    @autoreleasepool {
    const MetalObjects m = metal_objects(gpuDevice, image);
    id<MTLTexture> tex = m.tex;
    id<MTLCommandQueue> queue = m.queue;
    id<MTLDevice> device = m.device;
    if (!tex || !queue || !device) {
        if (error) *error = "readback: no Metal texture for the storage image";
        return false;
    }
    const NSUInteger pixel = NSUInteger(pixel_format_bytes(format));
    if (pixel == 0 || x < 0 || y < 0 || width < 1 || height < 1 || NSUInteger(x) + NSUInteger(width) > tex.width ||
        NSUInteger(y) + NSUInteger(height) > tex.height) {
        if (error) *error = "readback: the storage image does not have the size or format asked for";
        return false;
    }
    const NSUInteger bytesPerRow = NSUInteger(width) * pixel, bytes = bytesPerRow * NSUInteger(height);
    // The caller committed the sokol command buffer that holds the dispatches; this blit goes after it on the same
    // queue.
    id<MTLBuffer> buf = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
    if (!buf) {
        if (error) *error = "readback: Metal could not allocate " + std::to_string(bytes) + " bytes to read into";
        return false;
    }
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromTexture:tex sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(NSUInteger(x), NSUInteger(y), 0)
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

bool native_storage_image_loadable(const Device& gpuDevice, PixelFormat format, std::string* why) {
    id<MTLDevice> device = metal_objects(gpuDevice).device;
    if (!device) {
        if (why) *why = "the Metal device is gone";
        return false;
    }
    const MTLReadWriteTextureTier tier = [device readWriteTextureSupport];
    // Tier 1 (older Intel Macs, iOS A9-A10) reads and writes only the single-channel 32-bit formats in one texture;
    // Tier 2 adds the 8-bit, 16-bit float and 32-bit float RGBA ones.
    if (tier == MTLReadWriteTextureTier2) return true;
    if (tier == MTLReadWriteTextureTier1 && format == PixelFormat::R32F) return true;
    if (why)
        *why = std::string("this Metal GPU supports reading and writing one texture only for r32f (read-write texture tier ") +
               (tier == MTLReadWriteTextureTier1 ? "1" : "none") + ")";
    return false;
}

bool native_read_buffer(Device& gpuDevice, Buffer buffer, std::size_t offset, std::size_t bytes,
                        std::vector<std::uint8_t>& out, std::string* error) {
    @autoreleasepool {
    const MetalObjects m = metal_objects(gpuDevice, buffer);
    id<MTLBuffer> src = m.buf;
    id<MTLCommandQueue> queue = m.queue;
    id<MTLDevice> device = m.device;
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

struct AsyncBufferRead::Impl {
    enum class State { Free, Pending, Discard };
    struct Slot {
        id<MTLBuffer> dst = nil;  // shared memory: the CPU reads it directly
        id<MTLCommandBuffer> cmd = nil;
        std::size_t bytes = 0;     // what the last request asked for (what poll returns)
        std::size_t capacity = 0;  // the size of `dst`
        State state = State::Free;
    };
    Slot slots[kSlots];
    static bool finished(const Slot& s) {
        return s.cmd.status == MTLCommandBufferStatusCompleted || s.cmd.status == MTLCommandBufferStatusError;
    }
    // A discarded slot becomes free when its copy has finished.
    void sweep() {
        for (Slot& s : slots)
            if (s.state == State::Discard && finished(s)) {
                s.cmd = nil;
                s.state = State::Free;
            }
    }
};

AsyncBufferRead::AsyncBufferRead(Device& device) : device_(device), impl_(std::make_unique<Impl>()) {}
AsyncBufferRead::~AsyncBufferRead() {
    for (Impl::Slot& s : impl_->slots)
        if (s.cmd && s.state != Impl::State::Free) [s.cmd waitUntilCompleted];
}

bool AsyncBufferRead::supported() { return true; }

int AsyncBufferRead::request(Buffer buffer, std::size_t bytes, std::string* error) {
    @autoreleasepool {
    impl_->sweep();
    int slot = -1;
    for (int i = 0; i < kSlots && slot < 0; ++i)
        if (impl_->slots[i].state == Impl::State::Free) slot = i;
    if (slot < 0) return -1;
    const MetalObjects m = metal_objects(device_, buffer);
    id<MTLBuffer> src = m.buf;
    id<MTLCommandQueue> queue = m.queue;
    id<MTLDevice> device = m.device;
    if (!src || !queue || !device || bytes == 0 || bytes > std::size_t(src.length)) {
        if (error) *error = "readback: no Metal buffer of that size to read";
        return -1;
    }
    Impl::Slot& s = impl_->slots[slot];
    if (!s.dst || s.capacity < bytes) {
        s.dst = [device newBufferWithLength:bytes options:MTLResourceStorageModeShared];
        s.capacity = s.dst ? bytes : 0;
        if (!s.dst) {
            if (error) *error = "readback: Metal could not allocate " + std::to_string(bytes) + " bytes to read into";
            return -1;
        }
    }
    s.bytes = bytes;
    // After the sokol command buffer that wrote `src` (one queue, in order; the caller committed it).
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromBuffer:src sourceOffset:0 toBuffer:s.dst destinationOffset:0 size:bytes];
    [blit endEncoding];
    [cmd commit];
    s.cmd = cmd;
    s.state = Impl::State::Pending;
    return slot;
    }
}

bool AsyncBufferRead::poll(int slot, std::vector<std::uint8_t>& out, bool wait) {
    if (slot < 0 || slot >= kSlots || impl_->slots[slot].state != Impl::State::Pending) return false;
    Impl::Slot& s = impl_->slots[slot];
    if (!Impl::finished(s)) {
        if (!wait) return false;
        [s.cmd waitUntilCompleted];
    }
    const bool ok = s.cmd.status == MTLCommandBufferStatusCompleted;
    if (ok) {
        out.resize(s.bytes);
        std::memcpy(out.data(), [s.dst contents], s.bytes);
    }
    s.cmd = nil;
    s.state = Impl::State::Free;
    return ok;
}

void AsyncBufferRead::release(int slot) {
    if (slot < 0 || slot >= kSlots) return;
    Impl::Slot& s = impl_->slots[slot];
    if (s.state == Impl::State::Pending) s.state = Impl::State::Discard;
}

}  // namespace fa::gpu

#endif
