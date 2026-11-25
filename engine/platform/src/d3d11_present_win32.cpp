// The window's D3D11 device and DXGI swapchain (d3d11_present.h). It does what sokol_app's own D3D11 code did
// (_sapp_d3d11_create_device_and_swapchain, _sapp_d3d11_create_default_render_target,
// _sapp_d3d11_resize_default_render_target, _sapp_d3d11_present), now that sokol_app runs without a graphics API on
// Win32: the same device flags, frame latency and window association, the flip model from Windows 10 on, plus tearing
// when vsync is off and the display allows it, and the HDR buffer formats hdr_output_win32.cpp asks for. Written on
// macOS: the MinGW cross build compiles it, CI's Windows job runs it (d3d11_present_tests_win32.cpp, the editor
// autotest, every windowed test of the suite).
#include "d3d11_present.h"

#if defined(FA_D3D11_PRESENTER)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <d3d11.h>
#include <dxgi1_5.h>

#include <algorithm>
#include <cstring>
#include <format>
#include <string>

#include "fa/core/log.h"
#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_window.h"

namespace fa::d3d11 {
namespace {

// Older SDK headers lack the name (sokol_app spells it out the same way).
constexpr DXGI_SWAP_EFFECT kFlipDiscard = static_cast<DXGI_SWAP_EFFECT>(4);  // DXGI_SWAP_EFFECT_FLIP_DISCARD

template <class T>
void release(T*& p) {
    if (p) p->Release();
    p = nullptr;
}

// Releases `p` and clears `clean` when another reference keeps the object alive (a leak, or a view still in use).
template <class T>
void release_last(T*& p, bool& clean) {
    if (p && p->Release() != 0) clean = false;
    p = nullptr;
}

DXGI_FORMAT buffer_format(int kind) {
    return kind == 1   ? DXGI_FORMAT_R16G16B16A16_FLOAT
           : kind == 2 ? DXGI_FORMAT_R10G10B10A2_UNORM
                       : DXGI_FORMAT_B8G8R8A8_UNORM;
}
// The MSAA texture is typeless, its view has the buffer's format (sokol_app's _sapp_d3d11_msaatex_color_format). Kind 2
// never has one.
DXGI_FORMAT msaa_format(int kind) {
    return kind == 1 ? DXGI_FORMAT_R16G16B16A16_TYPELESS : DXGI_FORMAT_B8G8R8A8_TYPELESS;
}
sg_pixel_format sg_format(int kind) {
    return kind == 1 ? SG_PIXELFORMAT_RGBA16F : kind == 2 ? SG_PIXELFORMAT_RGB10A2 : SG_PIXELFORMAT_BGRA8;
}

std::string hex(HRESULT hr) { return std::format("0x{:08x}", static_cast<unsigned>(hr)); }

const char* removed_reason_name(HRESULT hr) {
    switch (hr) {
        case DXGI_ERROR_DEVICE_HUNG: return "DXGI_ERROR_DEVICE_HUNG: the GPU stopped answering";
        case DXGI_ERROR_DEVICE_REMOVED: return "DXGI_ERROR_DEVICE_REMOVED: the GPU or its driver went away";
        case DXGI_ERROR_DEVICE_RESET: return "DXGI_ERROR_DEVICE_RESET: a bad command reset the GPU";
        case DXGI_ERROR_DRIVER_INTERNAL_ERROR: return "DXGI_ERROR_DRIVER_INTERNAL_ERROR: the driver failed";
        case DXGI_ERROR_INVALID_CALL: return "DXGI_ERROR_INVALID_CALL";
        default: return "no reason given";
    }
}

std::string utf8(const wchar_t* w) {
    if (!w || !*w) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return {};
    std::string out(std::size_t(n - 1), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, out.data(), n, nullptr, nullptr);
    return out;
}

}  // namespace

struct Presenter::Impl {
    PresenterDesc desc;
    HWND hwnd = nullptr;
    ID3D11Device* device = nullptr;
    ID3D11DeviceContext* context = nullptr;
    IDXGISwapChain* swap = nullptr;
    ID3D11RenderTargetView* rtv = nullptr;  // the swapchain's buffer 0 (flip model: always the current back buffer)
    ID3D11Texture2D* msaa = nullptr;
    ID3D11RenderTargetView* msaaRtv = nullptr;
    ID3D11Texture2D* depth = nullptr;
    ID3D11DepthStencilView* dsv = nullptr;
    UINT swapFlags = 0;  // the flags the swapchain was made with: ResizeBuffers must get the same ones
    bool flip = false;
    bool tearing = false;
    bool lost = false;
    bool failLogged = false;
    bool viewsFailLogged = false;
    int kind = 0;
    int width = 1, height = 1;
    std::string description;

    // The views of the buffers in the current kind's format; on failure none is left made.
    HRESULT make_views() {
        const HRESULT hr = make_views_unchecked();
        if (FAILED(hr)) {
            bool clean = true;
            drop_views(clean);
        }
        return hr;
    }

    HRESULT make_views_unchecked() {
        ID3D11Texture2D* back = nullptr;
        HRESULT hr = swap->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&back));
        if (FAILED(hr) || !back) return FAILED(hr) ? hr : E_FAIL;
        D3D11_RENDER_TARGET_VIEW_DESC view{};
        view.Format = buffer_format(kind);
        view.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
        hr = device->CreateRenderTargetView(back, &view, &rtv);
        release(back);
        if (FAILED(hr)) return hr;
        const bool wantsMsaa = desc.sampleCount > 1;
        if (!wantsMsaa && !desc.depthStencil) return S_OK;
        D3D11_TEXTURE2D_DESC tex{};
        tex.Width = UINT(width);
        tex.Height = UINT(height);
        tex.MipLevels = 1;
        tex.ArraySize = 1;
        tex.Usage = D3D11_USAGE_DEFAULT;
        tex.SampleDesc.Count = UINT(desc.sampleCount);
        tex.SampleDesc.Quality = wantsMsaa ? UINT(D3D11_STANDARD_MULTISAMPLE_PATTERN) : 0u;
        if (wantsMsaa) {
            tex.Format = msaa_format(kind);
            tex.BindFlags = D3D11_BIND_RENDER_TARGET;
            hr = device->CreateTexture2D(&tex, nullptr, &msaa);
            if (FAILED(hr)) return hr;
            view.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2DMS;
            hr = device->CreateRenderTargetView(msaa, &view, &msaaRtv);
            if (FAILED(hr)) return hr;
        }
        if (desc.depthStencil) {
            tex.Format = DXGI_FORMAT_D32_FLOAT_S8X24_UINT;  // sapp_desc.depth_format SAPP_PIXELFORMAT_DEPTH_STENCIL
            tex.BindFlags = D3D11_BIND_DEPTH_STENCIL;
            hr = device->CreateTexture2D(&tex, nullptr, &depth);
            if (FAILED(hr)) return hr;
            hr = device->CreateDepthStencilView(depth, nullptr, &dsv);
            if (FAILED(hr)) return hr;
        }
        return S_OK;
    }

    void drop_views(bool& clean) {
        release_last(rtv, clean);
        release_last(msaaRtv, clean);
        release_last(msaa, clean);
        release_last(dsv, clean);
        release_last(depth, clean);
    }

    // ResizeBuffers needs every view of the buffers gone and none bound (sokol_gfx clears the context's state at the end of
    // every pass); the flush lets the runtime drop what it still holds of them.
    HRESULT resize_buffers(int w, int h, int k) {
        bool clean = true;
        drop_views(clean);
        context->Flush();
        return swap->ResizeBuffers(0, UINT(w), UINT(h), buffer_format(k), swapFlags);
    }

    void note_lost(HRESULT hr, const char* what) {
        if (lost) return;
        lost = true;
        const HRESULT reason = device ? device->GetDeviceRemovedReason() : hr;
        FA_ERROR(
            "platform",
            "D3D11: the graphics device was lost ({} returned {}, reason {} {}). The window shows no new frames from "
            "here on. A driver update, a GPU reset (Windows resets a GPU that does not answer within 2 seconds) or "
            "a hung GPU removes the device: restart the game; if it happens again, update the graphics driver and "
            "look for a draw or compute pass that runs for seconds.",
            what, hex(hr), hex(reason), removed_reason_name(reason));
    }

    static bool is_lost(HRESULT hr) { return hr == DXGI_ERROR_DEVICE_REMOVED || hr == DXGI_ERROR_DEVICE_RESET; }
};

Presenter::Presenter() = default;
Presenter::~Presenter() { destroy(); }

bool Presenter::valid() const { return impl_ && impl_->rtv && !impl_->lost; }

bool Presenter::create(const PresenterDesc& desc, std::string* error) {
    destroy();
    auto fail = [&](std::string message) {
        if (error) *error = std::move(message);
        destroy();
        return false;
    };
    if (!desc.hwnd) return fail("D3D11: there is no window to present to (the HWND is null)");
    impl_ = std::make_unique<Impl>();
    Impl& m = *impl_;
    m.desc = desc;
    m.desc.sampleCount = std::clamp(desc.sampleCount, 1, 16);
    m.hwnd = static_cast<HWND>(desc.hwnd);
    m.width = std::max(1, desc.width);
    m.height = std::max(1, desc.height);

    // sokol_app's flags: one thread uses the device (the engine's main thread), BGRA for the swapchain's format.
    UINT flags = D3D11_CREATE_DEVICE_SINGLETHREADED | D3D11_CREATE_DEVICE_BGRA_SUPPORT;
    if (desc.debugLayer) flags |= D3D11_CREATE_DEVICE_DEBUG;
    const D3D_DRIVER_TYPE type = desc.warp ? D3D_DRIVER_TYPE_WARP : D3D_DRIVER_TYPE_HARDWARE;
    const D3D_FEATURE_LEVEL levels[] = {D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0};
    D3D_FEATURE_LEVEL got{};
    auto make = [&](UINT f) {
        HRESULT hr =
            D3D11CreateDevice(nullptr, type, nullptr, f, levels, 2, D3D11_SDK_VERSION, &m.device, &got, &m.context);
        // A runtime that does not know 11.1 (Windows 7 without its platform update) refuses the whole list.
        if (hr == E_INVALIDARG)
            hr = D3D11CreateDevice(nullptr, type, nullptr, f, levels + 1, 1, D3D11_SDK_VERSION, &m.device, &got,
                                   &m.context);
        return hr;
    };
    HRESULT hr = make(flags);
    if (FAILED(hr) && (flags & D3D11_CREATE_DEVICE_DEBUG)) {
        // The debug layer needs the Graphics Tools optional feature (sokol_app retried without it too).
        FA_WARN("platform", "D3D11: the debug layer is not installed (Settings > Optional features > Graphics Tools); "
                            "running without it");
        hr = make(flags & ~UINT(D3D11_CREATE_DEVICE_DEBUG));
    }
    if (FAILED(hr) || !m.device || !m.context)
        return fail(std::format("D3D11CreateDevice failed for the {} adapter (HRESULT {}): this PC has no Direct3D 11 "
                                "graphics. Install the latest graphics driver; on Windows Server, install the Desktop "
                                "Experience feature",
                                desc.warp ? "WARP software" : "hardware", hex(hr)));

    // What sokol_app did: at most one frame queued ahead (input latency), no Alt+Enter or Print Screen handling by DXGI.
    IDXGIDevice1* dxgiDevice = nullptr;
    IDXGIAdapter* adapter = nullptr;
    IDXGIFactory* factory = nullptr;
    IDXGIFactory2* factory2 = nullptr;
    std::string adapterName = "unknown adapter";
    if (SUCCEEDED(m.device->QueryInterface(__uuidof(IDXGIDevice1), reinterpret_cast<void**>(&dxgiDevice)))) {
        dxgiDevice->SetMaximumFrameLatency(1);
        if (SUCCEEDED(dxgiDevice->GetAdapter(&adapter)) && adapter) {
            DXGI_ADAPTER_DESC ad{};
            if (SUCCEEDED(adapter->GetDesc(&ad))) adapterName = utf8(ad.Description);
            adapter->GetParent(__uuidof(IDXGIFactory), reinterpret_cast<void**>(&factory));
        }
    }
    release(dxgiDevice);
    release(adapter);
    if (!factory) return fail("D3D11: the device's DXGI factory could not be read (IDXGIDevice1::GetAdapter)");
    factory->QueryInterface(__uuidof(IDXGIFactory2), reinterpret_cast<void**>(&factory2));

    // Tearing (DXGI 1.5, Windows 10 1607 and a driver that supports it): a vsync-off frame shows at once.
    if (factory2) {
        IDXGIFactory5* factory5 = nullptr;
        if (SUCCEEDED(factory2->QueryInterface(__uuidof(IDXGIFactory5), reinterpret_cast<void**>(&factory5)))) {
            BOOL allow = FALSE;
            m.tearing =
                SUCCEEDED(factory5->CheckFeatureSupport(DXGI_FEATURE_PRESENT_ALLOW_TEARING, &allow, sizeof(allow))) &&
                allow;
        }
        release(factory5);
    }

    HRESULT swapHr = E_FAIL;
    if (factory2) {
        DXGI_SWAP_CHAIN_DESC1 sd{};
        sd.Width = UINT(m.width);
        sd.Height = UINT(m.height);
        sd.Format = buffer_format(0);
        sd.SampleDesc.Count = 1;
        sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        sd.BufferCount = 2;
        sd.Scaling = DXGI_SCALING_STRETCH;
        sd.SwapEffect = kFlipDiscard;
        sd.AlphaMode = DXGI_ALPHA_MODE_UNSPECIFIED;
        sd.Flags = m.tearing ? UINT(DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING) : 0u;
        IDXGISwapChain1* chain = nullptr;
        swapHr = factory2->CreateSwapChainForHwnd(m.device, m.hwnd, &sd, nullptr, nullptr, &chain);
        m.flip = SUCCEEDED(swapHr);
        if (FAILED(swapHr)) {  // before Windows 10: no FLIP_DISCARD; the blit model, one buffer, as sokol_app had there
            sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
            sd.BufferCount = 1;
            sd.Flags = 0;
            m.tearing = false;
            swapHr = factory2->CreateSwapChainForHwnd(m.device, m.hwnd, &sd, nullptr, nullptr, &chain);
        }
        m.swap = chain;
    } else {  // DXGI 1.1 (Windows 7 without its platform update)
        DXGI_SWAP_CHAIN_DESC sd{};
        sd.BufferDesc.Width = UINT(m.width);
        sd.BufferDesc.Height = UINT(m.height);
        sd.BufferDesc.Format = buffer_format(0);
        sd.SampleDesc.Count = 1;
        sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        sd.BufferCount = 1;
        sd.OutputWindow = m.hwnd;
        sd.Windowed = TRUE;
        sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
        m.tearing = false;
        swapHr = factory->CreateSwapChain(m.device, &sd, &m.swap);
    }
    if (SUCCEEDED(swapHr)) factory->MakeWindowAssociation(m.hwnd, DXGI_MWA_NO_ALT_ENTER | DXGI_MWA_NO_PRINT_SCREEN);
    release(factory2);
    release(factory);
    if (FAILED(swapHr) || !m.swap)
        return fail(std::format("D3D11: the window's swapchain could not be made (CreateSwapChainForHwnd returned {}). "
                                "Another swapchain may already present to this window (a D3D12 or Vulkan one): a "
                                "window has one at a time",
                                hex(swapHr)));
    m.swapFlags = m.tearing ? UINT(DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING) : 0u;

    if (const HRESULT viewHr = m.make_views(); FAILED(viewHr))
        return fail(std::format("D3D11: the window's render target views could not be made (HRESULT {}, {}x{}, {} "
                                "samples): use a sample count of 1, 2, 4 or 8",
                                hex(viewHr), m.width, m.height, m.desc.sampleCount));
    m.description = std::format("D3D11 {} / {} (feature level 0x{:x})", desc.warp ? "WARP software" : "hardware",
                                adapterName, unsigned(got));
    return true;
}

bool Presenter::destroy() {
    if (!impl_) return true;
    Impl& m = *impl_;
    bool clean = true;
    // Flip-model swapchains are destroyed lazily: drop every reference to the swapchain first, then ClearState +
    // Flush so the destruction happens now (ID3D11DeviceContext::Flush, "Deferred Destruction Issues with Flip
    // Presentation Swap Chains"). Otherwise a D3D12 or Vulkan swapchain made next on the same HWND gets
    // E_ACCESSDENIED, and the device keeps a reference.
    m.drop_views(clean);
    release_last(m.swap, clean);
    if (m.context) {
        m.context->ClearState();
        m.context->Flush();
    }
    release(m.context);  // the immediate context lives as long as the device
    release_last(m.device, clean);
    impl_.reset();
    return clean;
}

GfxEnvironment Presenter::environment() const {
    GfxEnvironment out{};
    sg_environment env{};
    const int k = impl_ ? impl_->kind : 0;
    env.defaults.color_format =
        k == 1 ? SG_PIXELFORMAT_RGBA16F : SG_PIXELFORMAT_BGRA8;  // what sapp_color_format() said
    env.defaults.depth_format = !impl_ || impl_->desc.depthStencil ? SG_PIXELFORMAT_DEPTH_STENCIL : SG_PIXELFORMAT_NONE;
    env.defaults.sample_count = impl_ ? impl_->desc.sampleCount : 1;
    if (impl_) {
        env.d3d11.device = impl_->device;
        env.d3d11.device_context = impl_->context;
    }
    static_assert(sizeof(env) <= sizeof(out.storage));
    std::memcpy(out.storage, &env, sizeof(env));
    return out;
}

GfxSwapchain Presenter::swapchain() const {
    GfxSwapchain out{};
    sg_swapchain sc{};
    if (!valid()) {
        sc.invalid = true;  // sokol_gfx skips the pass
    } else {
        const Impl& m = *impl_;
        sc.width = m.width;
        sc.height = m.height;
        sc.sample_count = m.desc.sampleCount;
        sc.color_format = sg_format(m.kind);
        sc.depth_format = m.desc.depthStencil ? SG_PIXELFORMAT_DEPTH_STENCIL : SG_PIXELFORMAT_NONE;
        if (m.desc.sampleCount > 1) {
            sc.d3d11.render_view = m.msaaRtv;
            sc.d3d11.resolve_view = m.rtv;
        } else {
            sc.d3d11.render_view = m.rtv;
        }
        sc.d3d11.depth_stencil_view = m.dsv;
    }
    static_assert(sizeof(sc) <= sizeof(out.storage));
    std::memcpy(out.storage, &sc, sizeof(sc));
    return out;
}

bool Presenter::resize(int w, int h) {
    if (!impl_ || impl_->lost || !impl_->swap) return false;
    Impl& m = *impl_;
    w = std::max(1, w);
    h = std::max(1, h);
    if (w == m.width && h == m.height && m.rtv) return true;
    const HRESULT hr = m.resize_buffers(w, h, m.kind);
    if (Impl::is_lost(hr)) {
        m.note_lost(hr, "ResizeBuffers");
        return false;
    }
    if (SUCCEEDED(hr)) {
        m.width = w;
        m.height = h;
    } else {
        FA_WARN("platform",
                "D3D11: the window's buffers could not be resized to {}x{} (ResizeBuffers returned {}); "
                "the frame stays {}x{} and is stretched",
                w, h, hex(hr), m.width, m.height);
    }
    if (const HRESULT viewHr = m.make_views(); FAILED(viewHr)) {
        if (!m.viewsFailLogged)  // tried again every frame (resize() with no views): said once
            FA_ERROR("platform",
                     "D3D11: the window's render target views could not be made again at {}x{} (HRESULT {}); "
                     "nothing is drawn to the window until they can be (tried every frame)",
                     m.width, m.height, hex(viewHr));
        m.viewsFailLogged = true;
        return false;
    }
    m.viewsFailLogged = false;
    return SUCCEEDED(hr);
}

PresentResult Presenter::present(int interval, bool modalLoop) {
    if (!impl_ || !impl_->swap) return PresentResult::Failed;
    Impl& m = *impl_;
    if (m.lost) return PresentResult::DeviceLost;
    UINT sync = UINT(std::clamp(interval, 0, 4));
    UINT flags = 0;
    if (m.flip) {
        // sokol_app: vsync off, or the modal move and resize loop, presents at once and drops the frame when the queue is
        // full; tearing (when the display allows it) shows a vsync-off frame at once instead of at the next vblank.
        if (modalLoop) {
            sync = 0;
            flags = DXGI_PRESENT_DO_NOT_WAIT;
        } else if (sync == 0) {
            flags = DXGI_PRESENT_DO_NOT_WAIT | (m.tearing ? UINT(DXGI_PRESENT_ALLOW_TEARING) : 0u);
        }
    } else {
        sync = std::max(sync, 1u);  // the blit model: no vsync off (fa_sapp_set_vsync says so)
    }
    const HRESULT hr = m.swap->Present(sync, flags);
    if (hr == DXGI_ERROR_WAS_STILL_DRAWING) return PresentResult::Skipped;
    if (Impl::is_lost(hr)) {
        m.note_lost(hr, "Present");
        return PresentResult::DeviceLost;
    }
    if (FAILED(hr)) {
        if (!m.failLogged)
            FA_ERROR("platform", "D3D11: presenting the window's frame failed (IDXGISwapChain::Present returned {})",
                     hex(hr));
        m.failLogged = true;
        return PresentResult::Failed;
    }
    return PresentResult::Shown;
}

int Presenter::kind() const { return impl_ ? impl_->kind : 0; }

int Presenter::set_kind(int want) {
    if (want < 0 || want > 2) want = 0;
    if (!valid()) return kind();
    Impl& m = *impl_;
    if (want == m.kind) return want;
    if (want != 0 && !m.flip) return m.kind;                 // HDR needs the flip model (Windows 10 and later)
    if (want == 2 && m.desc.sampleCount > 1) return m.kind;  // no 10-bit MSAA texture (hdr_output.cpp)
    const int old = m.kind;
    HRESULT hr = m.resize_buffers(m.width, m.height, want);
    if (Impl::is_lost(hr)) {
        m.note_lost(hr, "ResizeBuffers");
        return m.kind;
    }
    if (SUCCEEDED(hr)) m.kind = want;
    if (SUCCEEDED(m.make_views())) return m.kind;
    // The new format's views failed (an MSAA texture of that format): back to the old buffers.
    if (m.kind != old) {
        hr = m.resize_buffers(m.width, m.height, old);
        if (SUCCEEDED(hr)) m.kind = old;
    }
    if (FAILED(m.make_views()))
        FA_ERROR("platform", "D3D11: the window's render target views could not be made again after a format change; "
                             "nothing is drawn to the window until they can be (tried every frame)");
    return m.kind;
}

bool Presenter::flip_model() const { return impl_ && impl_->flip; }
bool Presenter::tearing() const { return impl_ && impl_->tearing; }
int Presenter::width() const { return impl_ ? impl_->width : 0; }
int Presenter::height() const { return impl_ ? impl_->height : 0; }
int Presenter::sample_count() const { return impl_ ? impl_->desc.sampleCount : 1; }
const std::string& Presenter::description() const {
    static const std::string none = "no D3D11 device";
    return impl_ ? impl_->description : none;
}
void* Presenter::swap_chain() const { return impl_ ? impl_->swap : nullptr; }
void* Presenter::device() const { return impl_ ? impl_->device : nullptr; }
void* Presenter::context() const { return impl_ ? impl_->context : nullptr; }

bool Presenter::read_back_buffer(int w, int h, std::uint8_t* rgba) const {
    if (!valid() || !rgba || w <= 0 || h <= 0) return false;
    const Impl& m = *impl_;
    // Buffer 0 is the current back buffer: the window pass has drawn (and resolved MSAA) into it, and the flip model only
    // changes buffers inside Present().
    ID3D11Texture2D* back = nullptr;
    if (FAILED(m.swap->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&back))) || !back) return false;
    D3D11_TEXTURE2D_DESC desc{};
    back->GetDesc(&desc);
    if (int(desc.Width) != w || int(desc.Height) != h || desc.SampleDesc.Count != 1 ||
        (desc.Format != DXGI_FORMAT_B8G8R8A8_UNORM && desc.Format != DXGI_FORMAT_B8G8R8A8_UNORM_SRGB)) {
        release(back);
        return false;
    }
    D3D11_TEXTURE2D_DESC sd = desc;
    sd.Usage = D3D11_USAGE_STAGING;
    sd.BindFlags = 0;
    sd.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    sd.MiscFlags = 0;
    ID3D11Texture2D* staging = nullptr;
    if (FAILED(m.device->CreateTexture2D(&sd, nullptr, &staging)) || !staging) {
        release(back);
        return false;
    }
    m.context->CopyResource(staging, back);
    release(back);
    D3D11_MAPPED_SUBRESOURCE mapped{};
    if (FAILED(m.context->Map(staging, 0, D3D11_MAP_READ, 0, &mapped))) {
        release(staging);
        return false;
    }
    for (int y = 0; y < h; ++y) {
        const auto* src = static_cast<const std::uint8_t*>(mapped.pData) + std::size_t(y) * mapped.RowPitch;
        std::uint8_t* dst = rgba + std::size_t(y) * std::size_t(w) * 4;
        for (int x = 0; x < w; ++x) {  // BGRA -> RGBA; the surface is already top row first
            dst[x * 4 + 0] = src[x * 4 + 2];
            dst[x * 4 + 1] = src[x * 4 + 1];
            dst[x * 4 + 2] = src[x * 4 + 0];
            dst[x * 4 + 3] = src[x * 4 + 3];
        }
    }
    m.context->Unmap(staging, 0);
    release(staging);
    return true;
}

// ---- the window's presenter ----------------------------------------------------------------------------------------------

namespace {
// Made with new and deleted only by window_presenter_release: a presenter sokol_gfx still uses at exit is left to the OS.
Presenter* g_window = nullptr;
bool g_windowFailed = false;  // the error was logged once: no new attempt every frame
}  // namespace

Presenter* window_presenter() { return g_window && g_window->valid() ? g_window : nullptr; }

Presenter* window_presenter_ensure() {
    if (g_window) return g_window->valid() ? g_window : nullptr;
    if (g_windowFailed || !sapp_isvalid()) return nullptr;
    void* hwnd = const_cast<void*>(sapp_win32_get_hwnd());
    if (!hwnd) return nullptr;
    PresenterDesc desc;
    desc.hwnd = hwnd;
    desc.width = sapp_width();
    desc.height = sapp_height();
    desc.sampleCount = std::max(1, sapp_sample_count());
    desc.depthStencil = sapp_depth_format() != SAPP_PIXELFORMAT_NONE;
    auto* p = new Presenter();
    std::string error;
    if (!p->create(desc, &error)) {
        delete p;
        g_windowFailed = true;
        FA_ERROR("platform", "{}", error);
        return nullptr;
    }
    FA_DEBUG("platform", "window presenter: {}, {}x{}, {} sample(s), {}{}", p->description(), p->width(), p->height(),
             p->sample_count(), p->flip_model() ? "flip model" : "blit model", p->tearing() ? ", tearing" : "");
    g_window = p;
    return g_window;
}

void window_presenter_release() {
    if (!g_window || sg_isvalid()) return;  // sokol_gfx still draws with its device: the process is ending anyway
    g_window->destroy();
    delete g_window;
    g_window = nullptr;
    g_windowFailed = false;
}

bool in_modal_move_size_loop() {
    GUITHREADINFO info{};
    info.cbSize = sizeof(info);
    return GetGUIThreadInfo(GetCurrentThreadId(), &info) && (info.flags & GUI_INMOVESIZE) != 0;
}

}  // namespace fa::d3d11

// ---- sokol_window.h on Windows: the swapchain is the presenter's, not sokol_app's -----------------------------------------

extern "C" bool fa_sapp_set_vsync(bool on) {
    // app.cpp keeps the wish and passes the interval to every present(). The blit model of Windows before 10 always
    // syncs: vsync on always works, off only with the flip model.
    const fa::d3d11::Presenter* p = fa::d3d11::window_presenter();
    return on || !p || p->flip_model();
}

extern "C" int fa_sapp_swapchain_kind(void) {
    const fa::d3d11::Presenter* p = fa::d3d11::window_presenter();
    return p ? p->kind() : 0;
}

extern "C" int fa_sapp_set_swapchain_kind(int kind, bool linear) {
    (void)linear;  // Metal only: D3D11's colour space is set by hdr_output_win32.cpp
    fa::d3d11::Presenter* p = fa::d3d11::window_presenter();
    return p ? p->set_kind(kind) : 0;
}

#endif  // FA_D3D11_PRESENTER
