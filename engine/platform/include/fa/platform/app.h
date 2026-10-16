// Application shell and GPU contexts.
//
// Two ways to get a GPU:
//   * run_app()      — a window (desktop) or full-screen view (iOS/Android)
//                      driven by sokol_app; calls your callbacks every frame.
//   * HeadlessGpu    — no window at all (CI, AI agents, tests, screenshots):
//                      Linux EGL (surfaceless/pbuffer, works with Mesa
//                      llvmpipe), macOS Metal device, Windows D3D11 (WARP
//                      fallback). Rendering goes to offscreen targets only.
// Both produce a GfxEnvironment for fa_render, which owns sg_setup().
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/platform/input.h"

// Forward-declare the sokol structs we hand to the renderer so this header
// stays free of sokol includes.
struct sg_environment;
struct sg_swapchain;

namespace fa {

// Opaque copy of sg_environment / sg_swapchain (fa_render casts back).
struct GfxEnvironment {
    alignas(16) unsigned char storage[512];
    const sg_environment& get() const { return *reinterpret_cast<const sg_environment*>(storage); }
};
struct GfxSwapchain {
    alignas(16) unsigned char storage[512];
    const sg_swapchain& get() const { return *reinterpret_cast<const sg_swapchain*>(storage); }
};

struct AppEvent {
    enum class Type { Resized, FocusLost, FocusGained, Suspended, Resumed, QuitRequested, FilesDropped };
    Type type;
    int width = 0, height = 0;  // Resized: framebuffer pixels
};

// One candidate image of the window icon: width * height RGBA8 pixels, row 0 = top.
struct AppIconImage {
    int width = 0;
    int height = 0;
    std::vector<std::uint8_t> rgba;
};

struct AppDesc {
    std::string title = "FactorIA";
    int width = 1280;           // initial window size (logical pixels)
    int height = 720;
    bool fullscreen = false;
    bool vsync = true;
    bool highDpi = true;
    int sampleCount = 1;        // MSAA of the window swapchain
    // The window icon (the title bar and the taskbar): the same icon in several sizes, the platform picks the closest to
    // what it shows. Used on Windows and Linux; macOS shows the icon of the app bundle (the Dock) and mobile apps have
    // none here. Empty = the platform's default icon. At most 8 images are used. to_sapp_desc keeps the pixels alive in
    // the copy of this AppDesc it owns, like `title`.
    std::vector<AppIconImage> icon;
    // Input is fed into this object; positions are converted with to_design_coords. Physical gamepads are polled into
    // it once per frame, before `frame` runs (fa/platform/gamepad.h; not while the window is unfocused).
    Input* input = nullptr;
    // Converts framebuffer pixel coordinates to design coordinates (letterbox).
    std::function<Vec2(Vec2 framebufferPos)> to_design_coords;

    std::function<void()> init;          // GPU is ready (gfx_environment() valid)
    std::function<void(double dt)> frame;  // once per display frame, dt in seconds (clamped to 0.25)
    std::function<void(const AppEvent&)> event;
    std::function<void()> cleanup;
    // Process exit code once the window closed (after cleanup); unset = 0. run_app returns it.
    std::function<int()> exit_code;
};

// Desktop: blocks until the window closes, returns desc.exit_code(). On macOS sapp_run() never returns (Cocoa ends the
// process after cleanup), so run_app exits the process with that code there: code after run_app does not run.
// iOS/Android: see player/ — the platform entry point calls this from sokol_main.
int run_app(const AppDesc& desc);

// Valid inside run_app callbacks.
GfxEnvironment app_gfx_environment();
GfxSwapchain app_gfx_swapchain();
int app_framebuffer_width();
int app_framebuffer_height();
float app_dpi_scale();
void app_request_quit();
void app_set_title(const std::string& title);
void app_show_mouse(bool show);
bool app_is_mobile();

// Window-less GPU context.
class HeadlessGpu {
public:
    HeadlessGpu();
    ~HeadlessGpu();
    HeadlessGpu(const HeadlessGpu&) = delete;
    HeadlessGpu& operator=(const HeadlessGpu&) = delete;

    bool init(std::string* error);  // error explains what is missing (e.g. "no EGL display: install mesa")
    void shutdown();
    bool valid() const;
    GfxEnvironment environment() const;
    const char* description() const;  // e.g. "EGL surfaceless / llvmpipe (Mesa 25.2)"
    // Must be called once per rendered frame after sg_commit() on backends that
    // need explicit submission/flush (Metal command buffers). No-op elsewhere.
    void end_frame();

private:
    struct Impl;
    Impl* impl_ = nullptr;
};

}  // namespace fa
