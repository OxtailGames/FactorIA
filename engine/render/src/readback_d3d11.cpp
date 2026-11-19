// D3D11 readback through a staging texture. UNTESTED (no Windows toolchain here).
#include "render_internal.h"

#if defined(SOKOL_D3D11)

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>

#include <cstring>

#include "hdr_encode.h"

namespace fa::render {

bool readback_rgba8(sg_image image, int width, int height, std::vector<std::uint8_t>& out, std::string* error) {
    auto* device = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()));
    auto* ctx = static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context()));
    auto* src = static_cast<ID3D11Texture2D*>(const_cast<void*>(sg_d3d11_query_image_info(image).tex2d));
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

bool readback_rgba16f(sg_image image, int width, int height, std::vector<float>& out, std::string* error) {
    auto* device = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()));
    auto* ctx = static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context()));
    auto* src = static_cast<ID3D11Texture2D*>(const_cast<void*>(sg_d3d11_query_image_info(image).tex2d));
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
        for (std::size_t i = 0; i < stride; ++i) out[std::size_t(y) * stride + i] = half_to_float(row[i]);
    }
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
}

bool readback_storage_image(sg_image image, sg_pixel_format format, int x, int y, int width, int height,
                            std::vector<std::uint8_t>& out, std::string* error) {
    auto* device = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()));
    auto* ctx = static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context()));
    auto* src = static_cast<ID3D11Texture2D*>(const_cast<void*>(sg_d3d11_query_image_info(image).tex2d));
    if (!device || !ctx || !src) {
        if (error) *error = "readback: no D3D11 texture for the storage image";
        return false;
    }
    const std::size_t pixel = std::size_t(sg_query_pixelformat(format).bytes_per_pixel);
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

bool storage_image_loadable(sg_pixel_format format, std::string* why) {
    auto* device = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()));
    DXGI_FORMAT dxgi = DXGI_FORMAT_UNKNOWN;
    switch (format) {
        case SG_PIXELFORMAT_RGBA8: dxgi = DXGI_FORMAT_R8G8B8A8_UNORM; break;
        case SG_PIXELFORMAT_RGBA16F: dxgi = DXGI_FORMAT_R16G16B16A16_FLOAT; break;
        case SG_PIXELFORMAT_R32F: dxgi = DXGI_FORMAT_R32_FLOAT; break;
        case SG_PIXELFORMAT_RGBA32F: dxgi = DXGI_FORMAT_R32G32B32A32_FLOAT; break;
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

bool readback_buffer(sg_buffer buffer, std::size_t offset, std::size_t bytes, std::vector<std::uint8_t>& out,
                     std::string* error) {
    auto* device = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()));
    auto* ctx = static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context()));
    auto* src = static_cast<ID3D11Buffer*>(const_cast<void*>(sg_d3d11_query_buffer_info(buffer).buf));
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

}  // namespace fa::render

#endif
