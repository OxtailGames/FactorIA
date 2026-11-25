// The window presenter of Windows (src/d3d11_present.h): sokol_app owns no graphics device there, the engine makes the
// D3D11 device and the window's DXGI swapchain. Windows only (the _win32 suffix): a hidden window of our own, sokol_gfx
// on the presenter's device, frames cleared to a colour, read back from the swapchain's buffer before they are
// presented.
#include <doctest.h>

#if defined(_WIN32) && defined(SOKOL_D3D11)

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

#include "../src/d3d11_present.h"
#include "sokol_gfx.h"

using namespace fa;

namespace {

// A window that is never shown: a swapchain needs an HWND, not a visible one.
struct HiddenWindow {
    HWND hwnd = nullptr;
    HINSTANCE instance = GetModuleHandleW(nullptr);
    const wchar_t* className = L"FactoriaPresenterTestWindow";
    HiddenWindow(int w, int h) {
        WNDCLASSEXW wc{};
        wc.cbSize = sizeof(wc);
        wc.lpfnWndProc = DefWindowProcW;
        wc.hInstance = instance;
        wc.lpszClassName = className;
        RegisterClassExW(&wc);
        RECT r{0, 0, w, h};
        AdjustWindowRect(&r, WS_OVERLAPPEDWINDOW, FALSE);
        hwnd = CreateWindowExW(0, className, L"presenter test", WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT,
                               r.right - r.left, r.bottom - r.top, nullptr, nullptr, instance, nullptr);
    }
    ~HiddenWindow() {
        if (hwnd) DestroyWindow(hwnd);
        UnregisterClassW(className, instance);
    }
};

// The graphics card's device, else WARP (a CI machine or a remote session without a GPU driver).
bool make_presenter(d3d11::Presenter& p, d3d11::PresenterDesc desc, std::string& error) {
    if (p.create(desc, &error)) return true;
    std::string hardware = error;
    desc.warp = true;
    if (p.create(desc, &error)) return true;
    error = "hardware: " + hardware + "; WARP: " + error;
    return false;
}

void clear_frame(const d3d11::Presenter& p, float r, float g, float b) {
    sg_pass pass{};
    pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
    pass.action.colors[0].clear_value = {r, g, b, 1.0f};
    pass.action.depth.load_action = SG_LOADACTION_CLEAR;
    pass.action.depth.clear_value = 1.0f;
    pass.swapchain = p.swapchain().get();
    sg_begin_pass(&pass);
    sg_end_pass();
    sg_commit();
}

bool close_to(std::uint8_t got, int want) { return std::abs(int(got) - want) <= 1; }

// Clears `frames` frames of the presenter's size to (r, g, b), checks a centre and a corner pixel of each before it is
// presented, then presents it.
void draw_and_check(d3d11::Presenter& p, int frames, float r, float g, float b) {
    const int w = p.width(), h = p.height();
    const int wr = int(r * 255.0f + 0.5f), wg = int(g * 255.0f + 0.5f), wb = int(b * 255.0f + 0.5f);
    std::vector<std::uint8_t> pixels(std::size_t(w) * std::size_t(h) * 4);
    for (int f = 0; f < frames; ++f) {
        clear_frame(p, r, g, b);
        REQUIRE(p.read_back_buffer(w, h, pixels.data()));
        for (const std::size_t at : {std::size_t(h / 2) * std::size_t(w) + std::size_t(w / 2),
                                     std::size_t(h - 1) * std::size_t(w) + std::size_t(w - 1)}) {
            const std::uint8_t* px = pixels.data() + at * 4;
            INFO("frame " << f << " pixel " << at << ": " << int(px[0]) << "," << int(px[1]) << "," << int(px[2]));
            CHECK(close_to(px[0], wr));
            CHECK(close_to(px[1], wg));
            CHECK(close_to(px[2], wb));
            CHECK(px[3] == 255);
        }
        const d3d11::PresentResult shown = p.present(0, false);
        CHECK(shown != d3d11::PresentResult::DeviceLost);
        CHECK(shown != d3d11::PresentResult::Failed);
    }
}

void run_presenter(int sampleCount) {
    HiddenWindow window(64, 48);
    REQUIRE(window.hwnd != nullptr);
    d3d11::PresenterDesc desc;
    desc.hwnd = window.hwnd;
    desc.width = 64;
    desc.height = 48;
    desc.sampleCount = sampleCount;
    d3d11::Presenter p;
    std::string error;
    REQUIRE_MESSAGE(make_presenter(p, desc, error), error);
    MESSAGE("presenter: " << p.description() << (p.flip_model() ? ", flip model" : ", blit model")
                          << (p.tearing() ? ", tearing" : ""));
    CHECK(p.valid());
    CHECK(p.sample_count() == sampleCount);

    sg_desc sd{};
    sd.environment = p.environment().get();
    CHECK(sd.environment.d3d11.device == p.device());
    CHECK(sd.environment.defaults.color_format == SG_PIXELFORMAT_BGRA8);
    CHECK(sd.environment.defaults.sample_count == sampleCount);
    sg_setup(&sd);
    REQUIRE(sg_isvalid());

    const sg_swapchain sc = p.swapchain().get();
    CHECK_FALSE(sc.invalid);
    CHECK(sc.width == 64);
    CHECK(sc.height == 48);
    CHECK(sc.color_format == SG_PIXELFORMAT_BGRA8);
    CHECK((sc.d3d11.resolve_view != nullptr) == (sampleCount > 1));

    draw_and_check(p, 3, 0.25f, 0.5f, 0.75f);

    // A window resize: new buffers, new views, the frame fills the new size.
    REQUIRE(p.resize(80, 60));
    CHECK(p.width() == 80);
    CHECK(p.height() == 60);
    CHECK(p.swapchain().get().width == 80);
    draw_and_check(p, 2, 1.0f, 0.0f, 0.5f);
    CHECK(p.resize(80, 60));  // the same size: nothing to do

    // The scRGB kind (HDR output) changes the buffers' format and back; the flip model only.
    if (p.flip_model()) {
        CHECK(p.set_kind(1) == 1);
        CHECK(p.swapchain().get().color_format == SG_PIXELFORMAT_RGBA16F);
        CHECK(p.set_kind(0) == 0);
        CHECK(p.swapchain().get().color_format == SG_PIXELFORMAT_BGRA8);
        draw_and_check(p, 1, 0.0f, 1.0f, 0.0f);
    }

    sg_shutdown();
    CHECK(p.destroy());  // every object's last reference went: sokol_gfx kept none and nothing leaked
    CHECK_FALSE(p.valid());
    CHECK(p.swapchain().get().invalid);
}

}  // namespace

TEST_CASE("D3D11 window presenter: clear, read back, present, resize, destroy") { run_presenter(1); }

TEST_CASE("D3D11 window presenter with MSAA resolves into the swapchain's buffer") { run_presenter(4); }

TEST_CASE("D3D11 window presenter: destroyed, the same window takes a new flip-model swapchain") {
    // The in-process fallback (M77-P9e1): a D3D12 or Vulkan device claimed the window, so the presenter was destroyed
    // (one flip-model swapchain per HWND, released at once by ClearState + Flush), then failed; the presenter is made
    // again on the same HWND. Two rounds: the second one is the one a released swapchain would have refused
    // (E_ACCESSDENIED).
    HiddenWindow window(64, 48);
    REQUIRE(window.hwnd);
    for (int round = 0; round < 2; ++round) {
        CAPTURE(round);
        d3d11::Presenter p;
        d3d11::PresenterDesc desc;
        desc.hwnd = window.hwnd;
        desc.width = 64;
        desc.height = 48;
        std::string error;
        REQUIRE_MESSAGE(make_presenter(p, desc, error), error);
        CHECK(p.valid());
        CHECK_FALSE(p.lost());
        CHECK(p.destroy());
        CHECK_FALSE(p.valid());
        CHECK(p.lost());  // nothing made: it never presents
    }
}

TEST_CASE("D3D11 window presenter refuses a null window with a teaching error") {
    d3d11::Presenter p;
    std::string error;
    CHECK_FALSE(p.create(d3d11::PresenterDesc{}, &error));
    CHECK(error.find("HWND") != std::string::npos);
    CHECK_FALSE(p.valid());
    CHECK(p.lost());
    CHECK(p.present(1, false) == d3d11::PresentResult::Failed);
}

#endif  // _WIN32 && SOKOL_D3D11
