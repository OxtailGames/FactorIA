// The window's D3D11 device and swapchain on Windows (d3d11_present_win32.cpp). Private to fa_platform.
//
// sokol_app runs with SOKOL_NOAPI on Win32 (sokol_impl.c): it makes the window and sends its events, and owns no graphics
// device. A Presenter makes the ID3D11Device, a DXGI flip-model swapchain on the window (FLIP_DISCARD, two buffers), the
// render target view of its buffer, a depth-stencil buffer and, when the sample count is above 1, the MSAA render target the
// window pass resolves into the buffer. It hands sokol_gfx the sg_environment (device, immediate context) and, every frame,
// the sg_swapchain (views, size, sample count, formats), resizes its buffers when the window's framebuffer size changes and
// presents. The D3D12 and Vulkan backends make their own swapchains on the same window: the window has no device of its own.
#pragma once

#if defined(_WIN32) && defined(SOKOL_D3D11)
#define FA_D3D11_PRESENTER 1

#include <cstdint>
#include <memory>
#include <string>

#include "fa/platform/app.h"

namespace fa::d3d11 {

struct PresenterDesc {
    void* hwnd = nullptr;  // the window (HWND) the swapchain presents to
    int width = 1;         // the framebuffer size in pixels
    int height = 1;
    int sampleCount = 1;  // above 1: an MSAA render target, resolved into the swapchain's buffer at the end of the pass
    bool depthStencil = true;  // a D32_FLOAT_S8X24_UINT depth-stencil buffer of the same size and sample count
    // The D3D11 debug layer, as sokol_app asked for it (a Debug build); without the Graphics Tools feature it is retried off.
    bool debugLayer =
#if defined(NDEBUG)
        false;
#else
        true;
#endif
    bool warp = false;  // the WARP software rasterizer instead of the graphics card (tests on a machine without one)
};

enum class PresentResult {
    Shown,       // queued for the display (or the window is hidden: DXGI_STATUS_OCCLUDED)
    Skipped,     // dropped: vsync off and the queue was still full (DXGI_ERROR_WAS_STILL_DRAWING)
    DeviceLost,  // the device was removed or reset (a driver update, a GPU hang or reset): nothing shows any more
    Failed,      // another error (logged once)
};

class Presenter {
public:
    Presenter();
    ~Presenter();
    Presenter(const Presenter&) = delete;
    Presenter& operator=(const Presenter&) = delete;

    // Makes the device and the swapchain. False with `error` saying what failed and what to do; nothing is left made.
    bool create(const PresenterDesc& desc, std::string* error);
    // Releases every object. True when each one's last reference went with it (nothing leaked: sokol_gfx is shut down first).
    bool destroy();
    bool valid() const;

    GfxEnvironment environment() const;
    // This frame's views. Call after resize() and before present().
    GfxSwapchain swapchain() const;
    // New buffers of w x h pixels when the size differs (the views first go, then ResizeBuffers, then new views). False:
    // the driver refused, the old buffers and views stay.
    bool resize(int w, int h);
    // `interval` 0 = no vsync (the frame tears when the display allows it, else it is dropped when the queue is full), 1 =
    // every vblank, 2 = every other one. `modalLoop`: the window is being moved or resized (Windows' modal loop draws from a
    // timer): no vsync wait then, as sokol_app did, so the drag does not stutter on some drivers.
    PresentResult present(int interval, bool modalLoop);

    // The kind of pixels the buffers hold (fa_sapp_set_swapchain_kind): 0 = B8G8R8A8_UNORM, 1 = R16G16B16A16_FLOAT (scRGB),
    // 2 = R10G10B10A2_UNORM (HDR10, never with MSAA). set_kind returns the kind in effect (the old one when it cannot).
    int kind() const;
    int set_kind(int kind);

    // FLIP_DISCARD (Windows 10 and later); false: the old DISCARD model (no HDR, no vsync off).
    bool flip_model() const;
    bool tearing() const;  // DXGI_FEATURE_PRESENT_ALLOW_TEARING: vsync off tears instead of dropping frames
    int width() const;
    int height() const;
    int sample_count() const;
    const std::string& description() const;  // "D3D11 hardware / <adapter> (feature level 0xb000)"
    void* swap_chain() const;                // IDXGISwapChain*
    void* device() const;                    // ID3D11Device*
    void* context() const;                   // ID3D11DeviceContext*

    // Copies the swapchain's buffer (the frame drawn so far: the window pass resolves MSAA into it) into `rgba` as w x h
    // RGBA8, row 0 = top. Call before present(). False: another size, or not an 8-bit buffer (HDR).
    bool read_back_buffer(int w, int h, std::uint8_t* rgba) const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

// The presenter of sokol_app's window, made on the first call (app_gfx_environment). Null when it could not be made (the
// error was logged once) or there is no window yet.
Presenter* window_presenter_ensure();
// The window's presenter when it exists (no creation).
Presenter* window_presenter();
// Releases it at the end of the app (after sokol_gfx shut down; left alone while sokol_gfx still uses it).
void window_presenter_release();
// True while Windows' modal move or resize loop runs on this thread (GetGUIThreadInfo: GUI_INMOVESIZE).
bool in_modal_move_size_loop();

}  // namespace fa::d3d11

#endif  // _WIN32 && SOKOL_D3D11
