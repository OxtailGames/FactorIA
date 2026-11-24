// D3D11 readback through a staging texture (gpu/sokol_native.h). The D3D11 objects come from the Device's natives.
// Built by the Windows CI and the MinGW cross build.
#include "gpu/sokol_native.h"

#if defined(SOKOL_D3D11)

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>

#include <cstring>

#include "gpu/device.h"
#include "hdr_encode.h"

namespace fa::gpu {

namespace {

ID3D11Device* d3d11_device(const Device& device) {
    return static_cast<ID3D11Device*>(const_cast<void*>(device.native().device));
}
ID3D11DeviceContext* d3d11_context(const Device& device) {
    return static_cast<ID3D11DeviceContext*>(const_cast<void*>(device.native().context));
}
// The 2D texture of `image`; null for a 3D image (native_image gives its ID3D11Texture3D, which these reads do not
// take) and for an image that is not valid.
ID3D11Texture2D* d3d11_texture2d(const Device& device, Image image) {
    const NativeImage n = device.native_image(image);
    auto* res = static_cast<ID3D11Resource*>(const_cast<void*>(n.resource));
    if (!res || !n.texture) return nullptr;
    D3D11_RESOURCE_DIMENSION dim = D3D11_RESOURCE_DIMENSION_UNKNOWN;
    res->GetType(&dim);
    return dim == D3D11_RESOURCE_DIMENSION_TEXTURE2D ? static_cast<ID3D11Texture2D*>(const_cast<void*>(n.texture))
                                                     : nullptr;
}
ID3D11Buffer* d3d11_buffer(const Device& device, Buffer buffer) {
    return static_cast<ID3D11Buffer*>(const_cast<void*>(device.native_buffer(buffer).buffer));
}

}  // namespace

bool native_read_image_rgba8(Device& gpuDevice, Image image, int width, int height, std::vector<std::uint8_t>& out,
                             std::string* error) {
    ID3D11Device* device = d3d11_device(gpuDevice);
    ID3D11DeviceContext* ctx = d3d11_context(gpuDevice);
    ID3D11Texture2D* src = d3d11_texture2d(gpuDevice, image);
    if (!device || !ctx || !src) {
        if (error) *error = "capture: no D3D11 texture for the game target";
        return false;
    }
    D3D11_TEXTURE2D_DESC desc{};
    src->GetDesc(&desc);
    desc.Usage = D3D11_USAGE_STAGING;
    desc.BindFlags = 0;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    desc.MiscFlags = 0;
    desc.SampleDesc.Count = 1;
    desc.SampleDesc.Quality = 0;
    ID3D11Texture2D* staging = nullptr;
    if (FAILED(device->CreateTexture2D(&desc, nullptr, &staging))) {
        if (error) *error = "capture: could not create the D3D11 staging texture";
        return false;
    }
    ctx->CopyResource(staging, src);
    D3D11_MAPPED_SUBRESOURCE map{};
    if (FAILED(ctx->Map(staging, 0, D3D11_MAP_READ, 0, &map))) {
        staging->Release();
        if (error) *error = "capture: ID3D11DeviceContext::Map failed";
        return false;
    }
    out.resize(std::size_t(width) * height * 4);
    for (int y = 0; y < height; ++y)  // D3D rows are top-down; the offscreen format is RGBA8
        std::memcpy(&out[std::size_t(y) * width * 4],
                    static_cast<const std::uint8_t*>(map.pData) + std::size_t(y) * map.RowPitch,
                    std::size_t(width) * 4);
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
}

bool native_read_image_rgba16f(Device& gpuDevice, Image image, int width, int height, std::vector<float>& out,
                               std::string* error) {
    ID3D11Device* device = d3d11_device(gpuDevice);
    ID3D11DeviceContext* ctx = d3d11_context(gpuDevice);
    ID3D11Texture2D* src = d3d11_texture2d(gpuDevice, image);
    if (!device || !ctx || !src) {
        if (error) *error = "readback: no D3D11 texture for the image";
        return false;
    }
    D3D11_TEXTURE2D_DESC desc{};
    src->GetDesc(&desc);
    if (desc.Format != DXGI_FORMAT_R16G16B16A16_FLOAT || desc.SampleDesc.Count != 1) {
        if (error) *error = "readback: the image is not a single-sampled RGBA16F texture";
        return false;
    }
    desc.Usage = D3D11_USAGE_STAGING;
    desc.BindFlags = 0;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    desc.MiscFlags = 0;
    ID3D11Texture2D* staging = nullptr;
    if (FAILED(device->CreateTexture2D(&desc, nullptr, &staging))) {
        if (error) *error = "readback: could not create the D3D11 staging texture";
        return false;
    }
    ctx->CopyResource(staging, src);
    D3D11_MAPPED_SUBRESOURCE map{};
    if (FAILED(ctx->Map(staging, 0, D3D11_MAP_READ, 0, &map))) {
        staging->Release();
        if (error) *error = "readback: ID3D11DeviceContext::Map failed";
        return false;
    }
    const std::size_t stride = std::size_t(width) * 4;
    out.resize(stride * std::size_t(height));
    std::vector<std::uint16_t> row(stride);
    for (int y = 0; y < height; ++y) {  // D3D rows are top-down
        std::memcpy(row.data(), static_cast<const std::uint8_t*>(map.pData) + std::size_t(y) * map.RowPitch,
                    stride * sizeof(std::uint16_t));
        for (std::size_t i = 0; i < stride; ++i) out[std::size_t(y) * stride + i] = render::half_to_float(row[i]);
    }
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
}

bool native_read_storage_image(Device& gpuDevice, Image image, PixelFormat format, int x, int y, int width, int height,
                               std::vector<std::uint8_t>& out, std::string* error) {
    ID3D11Device* device = d3d11_device(gpuDevice);
    ID3D11DeviceContext* ctx = d3d11_context(gpuDevice);
    ID3D11Texture2D* src = d3d11_texture2d(gpuDevice, image);
    if (!device || !ctx || !src) {
        if (error) *error = "readback: no D3D11 texture for the storage image";
        return false;
    }
    const std::size_t pixel = std::size_t(pixel_format_bytes(format));
    D3D11_TEXTURE2D_DESC desc{};
    src->GetDesc(&desc);
    if (pixel == 0 || desc.SampleDesc.Count != 1 || x < 0 || y < 0 || width < 1 || height < 1 ||
        UINT(x) + UINT(width) > desc.Width || UINT(y) + UINT(height) > desc.Height) {
        if (error) *error = "readback: the storage image does not have the size or format asked for";
        return false;
    }
    // A staging texture of the rectangle's size only: a small read of a large image never holds the whole image.
    desc.Width = UINT(width);
    desc.Height = UINT(height);
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Usage = D3D11_USAGE_STAGING;
    desc.BindFlags = 0;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    desc.MiscFlags = 0;
    ID3D11Texture2D* staging = nullptr;
    if (FAILED(device->CreateTexture2D(&desc, nullptr, &staging))) {
        if (error) *error = "readback: could not create the D3D11 staging texture";
        return false;
    }
    const D3D11_BOX box{UINT(x), UINT(y), 0, UINT(x + width), UINT(y + height), 1};
    // the UAV writes of the dispatches are ordered before the copy on the immediate context
    ctx->CopySubresourceRegion(staging, 0, 0, 0, 0, src, 0, &box);
    D3D11_MAPPED_SUBRESOURCE map{};
    if (FAILED(ctx->Map(staging, 0, D3D11_MAP_READ, 0, &map))) {
        staging->Release();
        if (error) *error = "readback: ID3D11DeviceContext::Map failed";
        return false;
    }
    const std::size_t row = std::size_t(width) * pixel;
    out.resize(row * std::size_t(height));
    for (int r = 0; r < height; ++r)  // D3D rows are top-down, like the rows an imageStore writes
        std::memcpy(&out[std::size_t(r) * row],
                    static_cast<const std::uint8_t*>(map.pData) + std::size_t(r) * map.RowPitch, row);
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
}

bool native_storage_image_loadable(const Device& gpuDevice, PixelFormat format, std::string* why) {
    ID3D11Device* device = d3d11_device(gpuDevice);
    DXGI_FORMAT dxgi = DXGI_FORMAT_UNKNOWN;
    switch (format) {
        case PixelFormat::Rgba8: dxgi = DXGI_FORMAT_R8G8B8A8_UNORM; break;
        case PixelFormat::Rgba16F: dxgi = DXGI_FORMAT_R16G16B16A16_FLOAT; break;
        case PixelFormat::R32F: dxgi = DXGI_FORMAT_R32_FLOAT; break;
        case PixelFormat::Rgba32F: dxgi = DXGI_FORMAT_R32G32B32A32_FLOAT; break;
        default: break;
    }
    // D3D11.0 hardware guarantees a typed load only for R32_FLOAT/UINT/SINT; the others are a capability bit of the
    // device.
    D3D11_FEATURE_DATA_FORMAT_SUPPORT2 support{};
    support.InFormat = dxgi;
    const bool known = device && dxgi != DXGI_FORMAT_UNKNOWN &&
                       SUCCEEDED(device->CheckFeatureSupport(D3D11_FEATURE_FORMAT_SUPPORT2, &support, sizeof(support)));
    if (known && (support.OutFormatSupport2 & D3D11_FORMAT_SUPPORT2_UAV_TYPED_LOAD) != 0) return true;
    if (why)
        *why = "this Direct3D 11 device has no typed UAV load for that format (only r32f is guaranteed on every D3D11 "
               "GPU)";
    return false;
}

bool native_read_buffer(Device& gpuDevice, Buffer buffer, std::size_t offset, std::size_t bytes,
                        std::vector<std::uint8_t>& out, std::string* error) {
    ID3D11Device* device = d3d11_device(gpuDevice);
    ID3D11DeviceContext* ctx = d3d11_context(gpuDevice);
    ID3D11Buffer* src = d3d11_buffer(gpuDevice, buffer);
    if (!device || !ctx || !src) {
        if (error) *error = "readback: no D3D11 buffer for the storage buffer";
        return false;
    }
    D3D11_BUFFER_DESC sd{};
    src->GetDesc(&sd);
    if (bytes > 0xFFFFFFFFu || offset > sd.ByteWidth || bytes > sd.ByteWidth - offset) {
        if (error) *error = "readback: the range is outside the storage buffer";
        return false;
    }
    out.resize(bytes);
    if (bytes == 0) return true;
    D3D11_BUFFER_DESC desc{};
    desc.ByteWidth = UINT(bytes);
    desc.Usage = D3D11_USAGE_STAGING;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    ID3D11Buffer* staging = nullptr;
    if (FAILED(device->CreateBuffer(&desc, nullptr, &staging))) {
        if (error) *error = "readback: could not create the D3D11 staging buffer";
        return false;
    }
    const D3D11_BOX box{UINT(offset), 0, 0, UINT(offset + bytes), 1, 1};
    ctx->CopySubresourceRegion(staging, 0, 0, 0, 0, src, 0, &box);
    D3D11_MAPPED_SUBRESOURCE map{};
    if (FAILED(ctx->Map(staging, 0, D3D11_MAP_READ, 0, &map))) {
        staging->Release();
        if (error) *error = "readback: ID3D11DeviceContext::Map failed";
        return false;
    }
    std::memcpy(out.data(), map.pData, bytes);
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
}

struct AsyncBufferRead::Impl {
    enum class State { Free, Pending, Discard };
    struct Slot {
        ID3D11Buffer* staging = nullptr;
        ID3D11Query* done = nullptr;  // an event query: signalled when the GPU has passed the copy
        std::size_t bytes = 0, capacity = 0;
        State state = State::Free;
    };
    Slot slots[kSlots];
    ID3D11DeviceContext* ctx = nullptr;  // the device's immediate context (it outlives the ring)
    bool finished(Slot& s) const {
        BOOL b = FALSE;
        return ctx && ctx->GetData(s.done, &b, sizeof(b), D3D11_ASYNC_GETDATA_DONOTFLUSH) == S_OK && b;
    }
};

AsyncBufferRead::AsyncBufferRead(Device& device) : device_(device), impl_(std::make_unique<Impl>()) {
    impl_->ctx = d3d11_context(device_);
}
AsyncBufferRead::~AsyncBufferRead() {
    for (Impl::Slot& s : impl_->slots) {
        if (s.staging) s.staging->Release();
        if (s.done) s.done->Release();
    }
}

bool AsyncBufferRead::supported() { return true; }

int AsyncBufferRead::request(Buffer buffer, std::size_t bytes, std::string* error) {
    for (Impl::Slot& s : impl_->slots)
        if (s.state == Impl::State::Discard && impl_->finished(s)) s.state = Impl::State::Free;
    int slot = -1;
    for (int i = 0; i < kSlots && slot < 0; ++i)
        if (impl_->slots[i].state == Impl::State::Free) slot = i;
    if (slot < 0) return -1;
    ID3D11Device* device = d3d11_device(device_);
    ID3D11DeviceContext* ctx = impl_->ctx;
    ID3D11Buffer* src = d3d11_buffer(device_, buffer);
    if (!device || !ctx || !src || bytes == 0 || bytes > 0xFFFFFFFFu) {
        if (error) *error = "readback: no D3D11 buffer for the storage buffer";
        return -1;
    }
    D3D11_BUFFER_DESC sd{};
    src->GetDesc(&sd);
    if (bytes > sd.ByteWidth) {
        if (error) *error = "readback: the range is outside the storage buffer";
        return -1;
    }
    Impl::Slot& s = impl_->slots[slot];
    if (!s.staging || s.capacity < bytes) {
        if (s.staging) s.staging->Release();
        s.staging = nullptr;
        D3D11_BUFFER_DESC desc{};
        desc.ByteWidth = UINT(bytes);
        desc.Usage = D3D11_USAGE_STAGING;
        desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
        if (FAILED(device->CreateBuffer(&desc, nullptr, &s.staging))) {
            if (error) *error = "readback: could not create the D3D11 staging buffer";
            return -1;
        }
        s.capacity = bytes;
    }
    if (!s.done) {
        D3D11_QUERY_DESC qd{};
        qd.Query = D3D11_QUERY_EVENT;
        if (FAILED(device->CreateQuery(&qd, &s.done))) {
            if (error) *error = "readback: could not create the D3D11 event query";
            return -1;
        }
    }
    const D3D11_BOX box{0, 0, 0, UINT(bytes), 1, 1};
    ctx->CopySubresourceRegion(s.staging, 0, 0, 0, 0, src, 0, &box);
    ctx->End(s.done);
    ctx->Flush();
    s.bytes = bytes;
    s.state = Impl::State::Pending;
    return slot;
}

bool AsyncBufferRead::poll(int slot, std::vector<std::uint8_t>& out, bool wait) {
    if (slot < 0 || slot >= kSlots || impl_->slots[slot].state != Impl::State::Pending) return false;
    Impl::Slot& s = impl_->slots[slot];
    if (!impl_->finished(s) && !wait) return false;
    // Map without DO_NOT_WAIT blocks until the copy has run: only on `wait`.
    D3D11_MAPPED_SUBRESOURCE map{};
    if (!impl_->ctx || FAILED(impl_->ctx->Map(s.staging, 0, D3D11_MAP_READ, 0, &map))) {
        s.state = Impl::State::Free;
        return false;
    }
    out.resize(s.bytes);
    std::memcpy(out.data(), map.pData, s.bytes);
    impl_->ctx->Unmap(s.staging, 0);
    s.state = Impl::State::Free;
    return true;
}

void AsyncBufferRead::release(int slot) {
    if (slot < 0 || slot >= kSlots) return;
    Impl::Slot& s = impl_->slots[slot];
    if (s.state == Impl::State::Pending) s.state = Impl::State::Discard;
}

}  // namespace fa::gpu

#endif
