// The game window on the engine's own Vulkan device (M77-P9e3): on Linux sokol_app's OpenGL surface leaves the X11
// window (app_claim_native_window) and the Vulkan device makes its swapchain there; when that start fails the claim is
// released, the OpenGL surface comes back and the build's backend draws in the same process. Linux only (the _linux
// suffix), in a real window: runs when FA_WINDOWED_SMOKE=1 and a display exists (CI: ctest `runtime_windowed_vulkan`
// and `runtime_windowed_vulkan_fallback`, under xvfb with lavapipe):
//   FA_WINDOWED_SMOKE=1 xvfb-run -a -s "-screen 0 1280x720x24" build/.../fa_test_runtime -tc="windowed vulkan: *"
// A machine without a Vulkan driver says so (MESSAGE) and passes, unless FA_VULKAN_REQUIRE=1 (the Linux CI job). Each
// case runs alone in its process (sokol_app and sokol_gfx are singletons).
#include <doctest.h>

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/platform/app.h"
#include "fa/render/renderer.h"
#include "fa/runtime/engine.h"

// Last: it includes Xlib, whose macros (None, Bool, Status...) would rename the engine's identifiers.
#include "../../platform/tests/x11_window_pixel.h"

using namespace fa;
using fa::test::x11_window_pixel;

namespace {

bool vulkan_required() {
    const char* v = std::getenv("FA_VULKAN_REQUIRE");
    return v && std::strcmp(v, "1") == 0;
}

// A 320x180 game whose camera clears to red, with a square in the middle.
std::string make_project(const char* name) {
    namespace stdfs = std::filesystem;
    const stdfs::path dir = fs::make_temp_dir_until_exit(name).value();
    stdfs::create_directories(dir / "scenes");
    std::ofstream(dir / "factoria.json") << R"({"name":"Windowed Vulkan","display":{"width":320,"height":180}})";
    std::ofstream(dir / "scenes/main.scene.json")
        << R"({"entities":[{"id":"cam","components":{"Camera":{"clearColor":[1,0,0,1]}}},
                           {"id":"b","components":{"Shape2D":{"size":[50,50]}}}]})";
    return dir.generic_string();
}

struct Seen {
    int frames = 0;
    WindowPresenter presenter = WindowPresenter::Unclaimed;
    std::string deviceBackend = "unset";
    bool vsyncSwitch = true;
    bool pixel = false;
    unsigned r = 0, g = 0, b = 0;
    int widthAfterResize = 0;
    float dpiScale = 0.0f;
};
Seen g_seen;

// Runs the game for 80 frames; frame 30 looks at who presents, frame 40 resizes the window, frame 60 reads a corner.
int run_game(EngineConfig cfg) {
    AppDesc d = make_app_desc(cfg);
    auto frame = d.frame;
    d.frame = [frame](double dt) {
        frame(dt);
        Seen& s = g_seen;
        ++s.frames;
        if (s.frames == 30) {
            s.presenter = app_window_presenter();
            s.deviceBackend = app_window_device_backend();
            s.vsyncSwitch = app_set_vsync(true);  // false while a device presents: its swapchain has the vsync
        }
        if (s.frames == 40)
            app_set_window_size(640, 360);  // the device's swapchain follows (resize_swapchain); no letterbox
        if (s.frames == 60) {
            s.widthAfterResize = app_framebuffer_width();
            s.dpiScale = app_dpi_scale();
            s.pixel = x11_window_pixel(5, 5, s.r, s.g, s.b);
        }
        if (s.frames == 80) app_request_quit();
    };
    return run_app(d);
}

// The runner's one-line startup report ("... GPU backend vulkan)"), or "".
std::string startup_line() {
    for (const LogEntry& e : recent_logs(4096))
        if (e.category == "player" && e.message.rfind("startup:", 0) == 0) return e.message;
    return "";
}

// The errors of the renderer and of the window's presenter ("" when none).
std::string render_errors() {
    std::string out;
    for (const LogEntry& e : recent_logs(4096)) {
        const bool presenter = e.category == "platform" && (e.message.find("OpenGL surface") != std::string::npos ||
                                                            e.message.find("has the window") != std::string::npos);
        if (e.level == LogLevel::Error && (e.category == "render" || presenter)) out += e.message + "\n";
    }
    return out;
}

void check_red_corner(const Seen& s) {
    REQUIRE(s.pixel);
    CHECK(s.r > 200);
    CHECK(s.g < 60);
    CHECK(s.b < 60);
}

}  // namespace

TEST_CASE("windowed vulkan: the game window draws with the engine's own Vulkan device" *
          doctest::skip(std::getenv("FA_WINDOWED_SMOKE") == nullptr)) {
    if (!gpu_backend_available(GpuBackend::Vulkan)) {
        if (vulkan_required()) FAIL("FA_VULKAN_REQUIRE=1 but this build has no Vulkan backend (FA_RENDER_VULKAN)");
        MESSAGE("this build has no Vulkan backend: the windowed Vulkan run was not checked");
        return;
    }
    EngineConfig cfg;
    cfg.projectDir = make_project("fa_runtime_windowed_vulkan");
    cfg.gpuBackend = "vulkan";
    CHECK(run_game(cfg) == 0);
    const Seen& s = g_seen;
    CHECK(s.frames >= 80);
    const std::string line = startup_line();
    INFO("startup: " << line);
    if (line.find("asked for vulkan") != std::string::npos) {
        // No Vulkan driver here: the claim was released and the build's backend drew in process.
        if (vulkan_required()) FAIL("FA_VULKAN_REQUIRE=1 but Vulkan did not start in the window: " << line);
        MESSAGE("this machine has no Vulkan driver: the window fell back (" << line << ")");
        CHECK(s.presenter == WindowPresenter::Platform);
        check_red_corner(s);
        return;
    }
    CHECK(line.find("GPU backend vulkan)") != std::string::npos);
    CHECK(s.presenter == WindowPresenter::Device);
    CHECK(s.deviceBackend == "vulkan");
    CHECK_FALSE(s.vsyncSwitch);
    if (s.dpiScale > 0.99f && s.dpiScale < 1.01f)
        CHECK(s.widthAfterResize == 640);
    else
        MESSAGE("display scale " << s.dpiScale << ": the resize was not checked");
    CHECK(render_errors().empty());
    check_red_corner(s);  // Vulkan's frame, presented into the X11 window
}

TEST_CASE("windowed vulkan fallback: a Vulkan start that fails after the claim gives the window back to OpenGL" *
          doctest::skip(std::getenv("FA_WINDOWED_SMOKE") == nullptr)) {
    if (!gpu_backend_available(GpuBackend::Vulkan)) {
        // The Linux CI job builds with Vulkan: a build without it there would let this case pass by checking nothing.
        if (vulkan_required()) FAIL("FA_VULKAN_REQUIRE=1 but this build has no Vulkan backend (FA_RENDER_VULKAN)");
        MESSAGE("this build has no Vulkan backend: no claim to fall back from");
        return;
    }
    EngineConfig cfg;
    cfg.projectDir = make_project("fa_runtime_windowed_vulkan_fallback");
    cfg.gpuBackend = "vulkan";
    cfg.gpuStartFault = [](GpuBackend b) {
        return b == GpuBackend::Vulkan ? std::string("forced failure after the claim") : std::string();
    };
    CHECK(run_game(cfg) == 0);
    const Seen& s = g_seen;
    CHECK(s.frames >= 80);
    const std::string line = startup_line();
    INFO("startup: " << line);
    CHECK(line.find("asked for vulkan, which could not start") != std::string::npos);
    bool claimed = false;  // the OpenGL surface left the window before the forced failure
    for (const LogEntry& e : recent_logs(4096))
        claimed =
            claimed || (e.category == "platform" && e.message.find("waits for the vulkan device") != std::string::npos);
    CHECK(claimed);
    CHECK(s.presenter == WindowPresenter::Platform);
    CHECK(s.deviceBackend.empty());
    if (!s.vsyncSwitch) MESSAGE("this OpenGL driver offers no swap control: app_set_vsync was not checked");
    CHECK(render_errors().empty());
    check_red_corner(s);  // OpenGL's frame, on the GLXWindow made again
}
