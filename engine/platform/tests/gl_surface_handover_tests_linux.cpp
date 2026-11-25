// sokol_app's OpenGL surface leaves the X11 window while a GPU device has it, and comes back (M77-P9e3, sokol_window.h:
// fa_sapp_gl_surface_release / _restore; app.cpp: app_claim_native_window / app_release_native_window). Linux only (the
// _linux suffix), in a real window: runs when FA_WINDOWED_SMOKE=1 and a display exists (CI: ctest
// `platform_windowed_gl_handover`, under xvfb):
//   FA_WINDOWED_SMOKE=1 xvfb-run -a -s "-screen 0 1280x720x24" build/.../fa_test_platform -tc="gl surface handover*"
// (sokol_app and sokol_gfx are process singletons: the case runs alone in its process.)
#include <doctest.h>

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <string>

#include "../src/sokol_window.h"
#include "fa/platform/app.h"
#include "sokol_gfx.h"

// Last: it includes Xlib, whose macros (None, Bool, Status...) would rename the engine's identifiers.
#include "x11_window_pixel.h"

using namespace fa;
using fa::test::x11_window_pixel;

namespace {

sg_environment sg_env(const GfxEnvironment& e) {
    sg_environment out;
    std::memcpy(&out, e.storage, sizeof(out));
    return out;
}
sg_swapchain sg_chain(const GfxSwapchain& s) {
    sg_swapchain out;
    std::memcpy(&out, s.storage, sizeof(out));
    return out;
}

struct Run {
    int frame = 0;
    // What each step saw (checked after run_app: a CHECK inside sokol_app's callback would work too, but the order of
    // the steps is easier to read here).
    std::string busy = "unset";
    bool claimed = false, deviceAfterClaim = false, surfaceOff = false, vsyncRefused = false, platformRefused = false;
    bool releaseOk = false, released = false, surfaceBack = false, gfxUp = false, drewRed = false;
    unsigned r = 0, g = 0, b = 0;
    std::string refusedWhileGfx;
    bool claimedAgain = false, offAgain = false;
    int widthAfterResize = 0;
    float dpiScale = 0.0f;
};
Run g_run;

void step_frame(double) {
    Run& s = g_run;
    ++s.frame;
    if (s.frame == 2) {
        const NativeWindow h = app_native_window();
        s.busy = h.busy;
        Result<NativeWindow> claim = app_claim_native_window("vulkan");
        s.claimed = claim.ok() && claim->window != nullptr && claim->display != nullptr;
        if (!claim.ok()) MESSAGE("claim: " << claim.error().to_string());
        s.deviceAfterClaim =
            app_window_presenter() == WindowPresenter::Device && app_window_device_backend() == "vulkan";
        s.surfaceOff = fa_sapp_gl_surface_state() != 0;
        s.vsyncRefused = !app_set_vsync(false);  // the device's swapchain has the vsync
        app_gfx_environment();                   // refused (logged once): a device has the window
        s.platformRefused = app_window_presenter() == WindowPresenter::Device;
    }
    // Frames 3-19: sokol_app swaps nothing (an X error would end the process); a resize reaches the framebuffer size.
    if (s.frame == 5) app_set_window_size(400, 240);
    if (s.frame == 15) {
        s.widthAfterResize = app_framebuffer_width();
        s.dpiScale = app_dpi_scale();
    }
    if (s.frame == 20) {
        s.releaseOk = app_release_native_window();
        s.released = app_window_presenter() == WindowPresenter::Unclaimed && app_window_device_backend().empty();
        s.surfaceBack = fa_sapp_gl_surface_state() == 0;
        sg_desc desc{};
        desc.environment = sg_env(app_gfx_environment());
        sg_setup(&desc);
        s.gfxUp = sg_isvalid() && app_window_presenter() == WindowPresenter::Platform;
    }
    if (s.frame > 20 && s.frame <= 40 && sg_isvalid()) {
        sg_pass pass{};
        pass.action.colors[0].load_action = SG_LOADACTION_CLEAR;
        pass.action.colors[0].clear_value = {1.0f, 0.0f, 0.0f, 1.0f};
        pass.swapchain = sg_chain(app_gfx_swapchain());
        sg_begin_pass(&pass);
        sg_end_pass();
        sg_commit();
    }
    if (s.frame == 40) s.drewRed = x11_window_pixel(10, 10, s.r, s.g, s.b);  // frame 39's swap is on the screen
    if (s.frame == 41) {
        Result<NativeWindow> refused = app_claim_native_window("vulkan");  // sokol_gfx draws with the window
        s.refusedWhileGfx = refused.ok() ? std::string() : refused.error().message;
        sg_shutdown();
        Result<NativeWindow> again = app_claim_native_window("vulkan");
        s.claimedAgain = again.ok();
        s.offAgain = fa_sapp_gl_surface_state() != 0;
    }
    // Quit with the window still claimed: app.cpp's cleanup drops the pbuffer (no GLXWindow is made for sokol_app to
    // destroy).
    if (s.frame == 45) app_request_quit();
}

}  // namespace

TEST_CASE(
    "gl surface handover: a claim takes sokol_app's OpenGL surface off the X11 window and the release puts it back" *
    doctest::skip(std::getenv("FA_WINDOWED_SMOKE") == nullptr)) {
    AppDesc d;
    d.title = "GL surface handover";
    d.width = 320;
    d.height = 180;
    d.highDpi = false;
    d.frame = step_frame;
    CHECK(run_app(d) == 0);
    const Run& s = g_run;
    CHECK(s.frame >= 45);
    CHECK(s.busy.empty());  // a GLX window is not busy any more
    CHECK(s.claimed);
    CHECK(s.deviceAfterClaim);
    CHECK(s.surfaceOff);
    CHECK(s.vsyncRefused);
    CHECK(s.platformRefused);
    if (s.dpiScale == 1.0f)
        CHECK(s.widthAfterResize == 400);  // sokol_app reads the X11 window size every frame, GL or not
    else
        MESSAGE("display scale " << s.dpiScale << ": the resize was not checked");
    CHECK(s.releaseOk);  // the OpenGL surface came back on the window
    CHECK(s.released);
    CHECK(s.surfaceBack);
    CHECK(s.gfxUp);
    REQUIRE(s.drewRed);
    CHECK(s.r > 200);  // OpenGL draws into the window again
    CHECK(s.g < 60);
    CHECK(s.b < 60);
    CHECK(s.refusedWhileGfx.find("close_context") != std::string::npos);
    CHECK(s.claimedAgain);
    CHECK(s.offAgain);
    CHECK(fa_sapp_gl_surface_state() == 0);  // the cleanup gave up the stand-in
}
