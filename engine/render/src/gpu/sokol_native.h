// Private to fa_render: what SokolDevice does through the native API of the one sokol backend a binary has (M77-P5d2,
// docs/design/ARCHITECTURE_RENDERING_GPU.md). Each function is implemented once per backend, in the file of that
// backend (readback_gl.cpp, readback_metal.mm, readback_d3d11.cpp; image_gl.cpp), and reaches the backend only through
// the Device it is given: its natives (native(), native_image(), native_buffer()), its state() and
// reset_state_cache(). No sokol type or call appears here or in those files.
//
// Only SokolDevice calls them: the renderer reads back through Device::read_image_rgba8 and the rest, and asks
// Device::storage_image_loadable. Render thread only, like the device.
#pragma once

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "gpu/types.h"

namespace fa::gpu {

class Device;

// GPU->CPU readback of an RGBA8 image (top row first). Waits for the GPU: the work recorded so far must have been
// committed (Device::commit).
bool native_read_image_rgba8(Device& device, Image image, int width, int height, std::vector<std::uint8_t>& out,
                             std::string* error);
// The same for an RGBA16F image, as floats (4 per pixel, top row first).
bool native_read_image_rgba16f(Device& device, Image image, int width, int height, std::vector<float>& out,
                               std::string* error);
// The rectangle (x, y, width, height) of a storage image: the pixels as the GPU holds them,
// `width * height * pixel_format_bytes(format)` bytes, the rectangle's first row first (rows count from the row an
// imageStore at y = 0 writes), tightly packed (RGBA16F as halves). Only the rectangle is copied (a blit, a staging copy
// or glReadPixels of its size), so a small read of a large image never holds the whole image. `format` is the image's
// own. False + `error` on a backend without storage images, or when the rectangle is outside the image.
bool native_read_storage_image(Device& device, Image image, PixelFormat format, int x, int y, int width, int height,
                               std::vector<std::uint8_t>& out, std::string* error);
// `bytes` bytes of a storage buffer from `offset`. False + `error` where the backend has no storage buffers.
bool native_read_buffer(Device& device, Buffer buffer, std::size_t offset, std::size_t bytes,
                        std::vector<std::uint8_t>& out, std::string* error);
// Whether a compute shader can imageLoad (not only imageStore) a storage image of `format` (RGBA8, RGBA16F, R32F,
// RGBA32F) on this GPU, the question behind `"access": "readWrite"`. PixelFormatCaps::read does not answer it: on
// Direct3D 11 it means a typed UAV exists, not a typed load (D3D11.0 hardware loads only R32_FLOAT/UINT/SINT), and on
// Metal the read-write texture tier decides (Tier 1: the 32-bit single-channel formats only). OpenGL 4.3 loads every
// format its shader declares with a layout qualifier. False + `why` (a sentence about this GPU) when it cannot.
bool native_storage_image_loadable(const Device& device, PixelFormat format, std::string* why);
// Direct3D 11 only (readback_d3d11.cpp): ID3D11DeviceContext::ClearState on the immediate context, so nothing a
// native section bound (shaders, views, render targets, states of a vendor SDK) leaks into sokol's next pass.
// SokolCommandList::end_native calls it, outside a pass, before reset_state_cache().
void native_d3d11_clear_state(Device& device);
// Called by SokolDevice::make_image after the image was made (image_gl.cpp). OpenGL ES: sokol_gfx gives every sampler a
// mipmap min filter and creates textures with glTexStorage2D, trusting the driver to clamp the effective max level to
// the storage's levels; the Android emulator's software GLES 3.0 does not, so every texture without a full mip chain
// samples black. This sets the real last level (`mipmaps` - 1) on every GL texture of the image (a writeTransient
// image has one per frame in flight). Nothing on the other backends, on a 3D image or on an image that is not Valid.
void native_finish_image(Device& device, Image image, int mipmaps);
// Who the GPU of the open sokol context is (gpu_info.cpp; DeviceInfo::gpu): D3D11 the DXGI adapter's PCI ids and
// LUID (and the IDXGIAdapter* in `adapter`, borrowed: the D3D11 device holds it), OpenGL the vendor GL_VENDOR and
// GL_RENDERER name (deviceId 0: GL has no PCI id), Metal Apple or the vendor the device name says (deviceId 0).
// `native` is the device's sokol_native_device(). Called once, by the SokolDevice constructor.
GpuIdentity native_gpu_identity(Backend backend, const NativeDevice& native, const void** adapter);

// GPU->CPU readback of the start of a storage buffer WITHOUT waiting (SokolDevice::request_buffer_read, which the Hi-Z
// culling of renderer_hiz.cpp uses): a small ring of staging buffers. request() queues a copy of the first `bytes`
// bytes of `buffer` behind the work submitted so far and returns the slot it uses; poll() hands the bytes over once the
// GPU has finished the copy, and never blocks unless `wait` is set (a headless frame waits so its result does not
// depend on the GPU's speed). The work that wrote the buffer must have been committed (Device::commit) before
// request(): on Metal the copy is a blit on the queue after sokol's command buffer. Needs the GPU's storage buffers (no
// GLES3): `supported()` says so. Not thread safe: the render thread only. The ring keeps the device it was made with,
// which outlives it (SokolDevice owns its rings).
// What a request costs the frame: GL a glFlush (the fence must be submitted to be signalled), D3D11 a Flush of the
// immediate context (the staging copy and its event query must be submitted), Metal one more command buffer committed
// behind sokol's. They are per request, so a frame with several cameras that use the depth pyramid flushes once per
// camera: the price of reading each camera's cells without waiting, bounded by the 8 cameras per frame that keep a
// pyramid (hiz.h).
class AsyncBufferRead {
public:
    static constexpr int kSlots = 4;
    explicit AsyncBufferRead(Device& device);
    ~AsyncBufferRead();
    AsyncBufferRead(const AsyncBufferRead&) = delete;
    AsyncBufferRead& operator=(const AsyncBufferRead&) = delete;
    static bool supported();
    // The slot, or -1: every slot is still in flight (error stays empty: ask again later), or the copy failed (error
    // says why).
    int request(Buffer buffer, std::size_t bytes, std::string* error);
    // True when the slot's copy has finished: `out` holds its bytes and the slot is free again. False: not done yet (or
    // the slot is unused); with `wait` it returns after the GPU finished (bounded: a GPU that does not answer in seconds
    // gives up, false).
    bool poll(int slot, std::vector<std::uint8_t>& out, bool wait);
    // Frees a slot without reading it (the copy may still be running; its staging buffer is reused only when it is
    // done).
    void release(int slot);

private:
    struct Impl;
    Device& device_;
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::gpu
