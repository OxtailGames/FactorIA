// D3D11 readback through a staging texture. UNTESTED (no Windows toolchain here).
#include "render_internal.h"

#if defined(SOKOL_D3D11)

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>

#include <cstring>

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
        std::memcpy(&out[std::size_t(y) * width * 4], static_cast<const std::uint8_t*>(map.pData) + std::size_t(y) * map.RowPitch,
                    std::size_t(width) * 4);
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
}

}  // namespace fa::render

#endif
