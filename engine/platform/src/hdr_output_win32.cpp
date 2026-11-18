// Windows: HDR output through DXGI (hdr_output_impl.h). UNTESTED on this host (written on macOS): CI builds it, a Windows
// PC with an HDR display runs it.
//
// The display: the DXGI output whose monitor holds the window (MonitorFromWindow), from a DXGI factory of our own. DXGI
// keeps what it learnt of the outputs per factory, so a factory made before the user switched HDR on still says SDR:
// IDXGIFactory1::IsCurrent turns false then (and when a display is added or removed) and the factory is made again. The
// output is asked again only when the window's monitor changes or the factory is replaced, so the per-frame cost is
// MonitorFromWindow and IsCurrent.
//
// The swapchain: sokol_app's flip-model swapchain (Windows 10 on) gets new buffers from fa_sapp_set_swapchain_kind and
// the colour space that goes with them from IDXGISwapChain3::SetColorSpace1: scRGB (R16G16B16A16_FLOAT, linear, 1.0 =
// 80 nits, DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709) or HDR10 (R10G10B10A2_UNORM, ST.2084 in Rec.2020,
// DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020), and back to sRGB (G22_NONE_P709) for the standard range.
#include "hdr_output_impl.h"

#if defined(SOKOL_D3D11)

#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <dxgi1_6.h>

#include "sokol_app.h"
#include "sokol_window.h"

#include <string>

namespace fa::hdr_impl {
namespace {

// Written out, so this file needs no dxguid entry of DXGI 1.4 / 1.6 (MinGW's import libraries lag behind the SDK's).
const GUID kIidFactory1 = {0x770aae78, 0xf26f, 0x4dba, {0xa8, 0x29, 0x25, 0x3c, 0x83, 0xd1, 0xb3, 0x87}};
const GUID kIidOutput6 = {0x068346e8, 0xaaec, 0x4b84, {0xad, 0xd7, 0x13, 0x7f, 0x51, 0x3f, 0x77, 0xa1}};
const GUID kIidSwapChain3 = {0x94d99bdb, 0xf1f8, 0x4ab0, {0xb2, 0x36, 0x7d, 0xa0, 0x17, 0x0e, 0xda, 0xb1}};

template <class T>
void release(T*& p) {
    if (p) p->Release();
    p = nullptr;
}

std::string utf8(const wchar_t* w) {
    if (!w || !*w) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, w, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 1) return {};
    std::string out(std::size_t(n - 1), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w, -1, out.data(), n, nullptr, nullptr);
    return out;
}

// What the user sees as the monitor's name: the driver's string of the monitor on `device` ("\\.\DISPLAY1"), else the
// device name itself.
std::string monitor_name(const wchar_t* device) {
    DISPLAY_DEVICEW dd{};
    dd.cb = sizeof(dd);
    if (EnumDisplayDevicesW(device, 0, &dd, 0) && dd.DeviceString[0]) return utf8(dd.DeviceString);
    return utf8(device);
}

struct State {
    IDXGIFactory1* factory = nullptr;
    HMONITOR monitor = nullptr;
    HdrDisplay display;
    // The framebuffer size the colour space was last set for (0: none set, or the standard range).
    int spaceW = 0, spaceH = 0;
};
State& state() {
    static State s;
    return s;
}

HdrDisplay ask_output(IDXGIFactory1* factory, HMONITOR monitor) {
    for (UINT a = 0;; ++a) {
        IDXGIAdapter1* adapter = nullptr;
        if (FAILED(factory->EnumAdapters1(a, &adapter)) || !adapter) break;  // DXGI_ERROR_NOT_FOUND: no more
        for (UINT o = 0;; ++o) {
            IDXGIOutput* output = nullptr;
            if (FAILED(adapter->EnumOutputs(o, &output)) || !output) break;
            DXGI_OUTPUT_DESC plain{};
            const bool match = SUCCEEDED(output->GetDesc(&plain)) && plain.Monitor == monitor;
            IDXGIOutput6* output6 = nullptr;
            if (match) output->QueryInterface(kIidOutput6, reinterpret_cast<void**>(&output6));
            release(output);
            if (!match) continue;
            HdrDisplay d;
            if (output6) {
                DXGI_OUTPUT_DESC1 desc{};
                if (SUCCEEDED(output6->GetDesc1(&desc)))
                    d = hdr_display_from_dxgi(desc.ColorSpace == DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020,
                                              desc.MaxLuminance, desc.MinLuminance, desc.MaxFullFrameLuminance,
                                              monitor_name(desc.DeviceName));
                release(output6);
            }
            release(adapter);
            if (!d.known) {
                d.known = true;
                d.name = monitor_name(plain.DeviceName);
                d.why = "Windows: this version of Windows does not report HDR (DXGI 1.6, Windows 10 1703 or later)";
            }
            return d;
        }
        release(adapter);
    }
    HdrDisplay d;
    d.why = "Windows: the monitor the window is on has no DXGI output (a remote desktop or an indirect display)";
    return d;
}

// The DXGI colour space of the swapchain kind `want` (0 sRGB, 1 scRGB, 2 HDR10), set when the swapchain can present in it.
bool set_color_space(IDXGISwapChain3* chain3, int want) {
    const DXGI_COLOR_SPACE_TYPE space = want == 1   ? DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709
                                        : want == 2 ? DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020
                                                    : DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709;
    UINT support = 0;
    return SUCCEEDED(chain3->CheckColorSpaceSupport(space, &support)) &&
           (support & DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT) && SUCCEEDED(chain3->SetColorSpace1(space));
}

}  // namespace

HdrDisplay dxgi_display() {
    State& s = state();
    HWND hwnd = static_cast<HWND>(const_cast<void*>(sapp_win32_get_hwnd()));
    if (!hwnd) {
        HdrDisplay d;
        d.why = "there is no window";
        return d;
    }
    HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    bool stale = s.factory == nullptr || !s.factory->IsCurrent();
    if (stale) {
        release(s.factory);
        if (FAILED(CreateDXGIFactory1(kIidFactory1, reinterpret_cast<void**>(&s.factory)))) s.factory = nullptr;
    }
    if (!s.factory) {
        HdrDisplay d;
        d.why = "Windows: DXGI could not be asked about the display (CreateDXGIFactory1 failed)";
        return d;
    }
    if (stale || monitor != s.monitor || !s.display.known) {
        s.monitor = monitor;
        s.display = ask_output(s.factory, monitor);
    }
    return s.display;
}

HdrEncoding dxgi_apply(HdrEncoding encoding) {
    const int want = encoding == HdrEncoding::ScRgb ? 1 : encoding == HdrEncoding::Hdr10 ? 2 : 0;
    auto* chain = static_cast<IDXGISwapChain*>(const_cast<void*>(sapp_d3d11_get_swap_chain()));
    IDXGISwapChain3* chain3 = nullptr;
    if (chain) chain->QueryInterface(kIidSwapChain3, reinterpret_cast<void**>(&chain3));
    auto current = [] {
        const int k = fa_sapp_swapchain_kind();
        return k == 1 ? HdrEncoding::ScRgb : k == 2 ? HdrEncoding::Hdr10 : HdrEncoding::Sdr;
    };
    if (!chain3) return current();  // before Windows 10 there is no colour space to set: the standard range only
    // The colour space must be one the swapchain can present in its new format, so the buffers change first.
    if (fa_sapp_set_swapchain_kind(want, false) != want) {
        release(chain3);
        return current();
    }
    State& s = state();
    const bool ok = set_color_space(chain3, want);
    if (!ok && want != 0) {  // back to 8-bit sRGB: never an HDR format with the wrong colour space
        fa_sapp_set_swapchain_kind(0, false);
        chain3->SetColorSpace1(DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709);
    }
    s.spaceW = ok && want != 0 ? sapp_width() : 0;
    s.spaceH = ok && want != 0 ? sapp_height() : 0;
    release(chain3);
    return current();
}

void dxgi_keep_color_space(HdrEncoding applied) {
    State& s = state();
    const int want = applied == HdrEncoding::ScRgb ? 1 : applied == HdrEncoding::Hdr10 ? 2 : 0;
    if (want == 0) {
        s.spaceW = s.spaceH = 0;
        return;
    }
    const int w = sapp_width(), h = sapp_height();
    if (w == s.spaceW && h == s.spaceH) return;  // the buffers are the ones the colour space was set on
    auto* chain = static_cast<IDXGISwapChain*>(const_cast<void*>(sapp_d3d11_get_swap_chain()));
    IDXGISwapChain3* chain3 = nullptr;
    if (chain) chain->QueryInterface(kIidSwapChain3, reinterpret_cast<void**>(&chain3));
    if (!chain3) return;
    // sokol_app resized the buffers (ResizeBuffers): DXGI gives the new ones its default colour space again, so an HDR window would
    // show its scRGB or PQ values as sRGB. Set it again; when it fails the size stays unmatched and the next frame tries again.
    if (set_color_space(chain3, want)) {
        s.spaceW = w;
        s.spaceH = h;
    }
    release(chain3);
}

}  // namespace fa::hdr_impl

#endif  // SOKOL_D3D11
