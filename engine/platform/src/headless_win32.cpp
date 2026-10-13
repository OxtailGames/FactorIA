// Window-less GPU context for Windows: a D3D11 device (hardware, falling back
// to the WARP software rasterizer). UNTESTED: written without a Windows
// toolchain available on the development machine.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <d3d11.h>
#include <dxgi.h>

#include <cstring>
#include <format>
#include <string>

#include "fa/platform/app.h"
#include "sokol_gfx.h"

namespace fa {

struct HeadlessGpu::Impl {
    ID3D11Device* device = nullptr;
    ID3D11DeviceContext* context = nullptr;
    bool valid = false;
    std::string description;
};

HeadlessGpu::HeadlessGpu() = default;
HeadlessGpu::~HeadlessGpu() { shutdown(); }

bool HeadlessGpu::init(std::string* error) {
    if (impl_) return true;
    Impl* m = new Impl();
    UINT flags = 0;
#if !defined(NDEBUG)
    // The debug layer needs the Graphics Tools optional feature; retry without it if missing.
    flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
    const D3D_FEATURE_LEVEL levels[] = {D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0};
    D3D_FEATURE_LEVEL got{};
    const char* kind = "hardware";
    HRESULT hr = E_FAIL;
    for (int attempt = 0; attempt < 4; ++attempt) {
        D3D_DRIVER_TYPE type = (attempt < 2) ? D3D_DRIVER_TYPE_HARDWARE : D3D_DRIVER_TYPE_WARP;
        UINT f = (attempt % 2 == 0) ? flags : (flags & ~UINT(D3D11_CREATE_DEVICE_DEBUG));
        kind = (type == D3D_DRIVER_TYPE_HARDWARE) ? "hardware" : "WARP software";
        hr = D3D11CreateDevice(nullptr, type, nullptr, f, levels, 2, D3D11_SDK_VERSION, &m->device, &got, &m->context);
        if (SUCCEEDED(hr)) break;
    }
    if (FAILED(hr)) {
        if (error) {
            *error = std::format("D3D11CreateDevice failed (HRESULT 0x{:08x}) for both hardware and WARP. "
                                 "Install the latest graphics driver or enable the 'Graphics Tools' / D3D11 runtime "
                                 "(Windows Server: install the Desktop Experience feature).",
                                 unsigned(hr));
        }
        delete m;
        return false;
    }
    std::string adapterName = "unknown adapter";
    IDXGIDevice* dxgiDevice = nullptr;
    if (SUCCEEDED(m->device->QueryInterface(__uuidof(IDXGIDevice), reinterpret_cast<void**>(&dxgiDevice)))) {
        IDXGIAdapter* adapter = nullptr;
        if (SUCCEEDED(dxgiDevice->GetAdapter(&adapter))) {
            DXGI_ADAPTER_DESC d{};
            if (SUCCEEDED(adapter->GetDesc(&d))) {
                char buf[256] = {};
                WideCharToMultiByte(CP_UTF8, 0, d.Description, -1, buf, sizeof(buf) - 1, nullptr, nullptr);
                adapterName = buf;
            }
            adapter->Release();
        }
        dxgiDevice->Release();
    }
    m->description = std::format("D3D11 {} / {} (feature level 0x{:x})", kind, adapterName, unsigned(got));
    m->valid = true;
    impl_ = m;
    return true;
}

void HeadlessGpu::shutdown() {
    if (!impl_) return;
    if (impl_->context) impl_->context->Release();
    if (impl_->device) impl_->device->Release();
    delete impl_;
    impl_ = nullptr;
}

bool HeadlessGpu::valid() const { return impl_ && impl_->valid; }

GfxEnvironment HeadlessGpu::environment() const {
    GfxEnvironment out{};
    sg_environment env{};
    env.defaults.color_format = SG_PIXELFORMAT_BGRA8;
    env.defaults.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    env.defaults.sample_count = 1;
    if (impl_) {
        env.d3d11.device = impl_->device;
        env.d3d11.device_context = impl_->context;
    }
    std::memcpy(out.storage, &env, sizeof(env));
    return out;
}

const char* HeadlessGpu::description() const { return impl_ ? impl_->description.c_str() : "not initialized"; }

void HeadlessGpu::end_frame() {
    if (impl_ && impl_->context) impl_->context->Flush();
}

}  // namespace fa
