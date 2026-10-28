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

#include "fa/core/math.h"
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
    // QuitRequested: true when the app itself asked (app_request_quit(): game.quit(), a failed start, --frames): the window
    // must close then, so hosts do not offer it to the game as the player's close request.
    bool fromApp = false;
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
    // macOS: the Dock icon while the app runs, for a program that is not an app bundle (the editor, started from the
    // `factoria` executable, would show the generic one). Draw it on Apple's icon grid: the tile covers the middle ~80%
    // of the image. Empty = the bundle's icon. The other platforms ignore it.
    AppIconImage dockIcon;
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
// True while this process owns a graphics device (a window, the editor, a headless GPU, an engine with graphics). Only one
// can exist per process: starting a second one aborts inside sokol, so code that would start one asks first.
bool gfx_device_active();

GfxEnvironment app_gfx_environment();
GfxSwapchain app_gfx_swapchain();
int app_framebuffer_width();
int app_framebuffer_height();
float app_dpi_scale();
void app_request_quit();
// Keeps the window open after a QuitRequested event that did not come from the app (the close button, Cmd+Q, Alt+F4).
// Only meaningful while that event is handled (inside AppDesc::event); no effect anywhere else.
void app_cancel_quit();
// The system clipboard (Windows, macOS, Linux, web; the app descriptor enables it). Mobile has none: the getter answers ""
// and the setter does nothing (app_clipboard_supported() is false). The web lets a page read only inside a paste, so the
// getter answers the text of the last paste there.
bool app_clipboard_supported();
std::string app_clipboard_get();
void app_clipboard_set(const std::string& text);
void app_set_title(const std::string& title);
void app_show_mouse(bool show);
bool app_is_mobile();

// Window settings. Valid inside run_app callbacks, on the thread that runs them. Sizes are LOGICAL pixels (the window
// system's points: a 200% display shows a 1280 x 720 window with 2560 x 1440 framebuffer pixels). Phones and tablets
// always run full screen: they report true, ignore app_set_fullscreen and cannot be resized.
bool app_is_fullscreen();
// Enters or leaves full screen when the state differs (desktop). app_is_fullscreen() follows the request at once, even
// where the window manager (X11) takes a moment to resize the window. Does nothing on mobile.
void app_set_fullscreen(bool on);
// The three ways a desktop window can be shown. Windowed has a frame and a size of its own; Borderless and Fullscreen cover
// the whole monitor. They differ only where the OS has two kinds: macOS runs Fullscreen as its native full screen (a Space
// of its own, the menu bar slides in) and Borderless as a frameless window over the monitor that hides the menu bar and the
// Dock; Windows and Linux have one full screen window (a frameless window over the monitor, no exclusive mode), so the two
// modes look the same there and only app_window_mode() remembers which one was asked for. Phones and tablets are Fullscreen.
enum class WindowMode { Windowed, Borderless, Fullscreen };
// false: this platform has no window modes to choose from (phones, tablets and the web).
bool app_has_window_modes();
WindowMode app_window_mode();
// "" when done, else the reason it was refused (macOS cannot go from its native full screen straight to Borderless).
std::string app_set_window_mode(WindowMode mode);

// One monitor, in logical pixels. `x`, `y` is its corner in the desktop space.
struct MonitorInfo {
    std::string name;
    int x = 0, y = 0, width = 0, height = 0;
    bool primary = false;
    bool current = false;  // the window is on it
};
// The monitors, primary first. Empty: this platform cannot list them (phones, tablets, web).
std::vector<MonitorInfo> app_monitors();
// Moves the window to monitor `index` of app_monitors(): centred when windowed, covering it when full screen. false: no such
// monitor, or not possible now (a macOS window in its native full screen stays where it is).
bool app_move_to_monitor(int index);

// The client size of the window now.
void app_window_size(int& width, int& height);
// The size of the monitor the window is on. false: unknown on this platform (width and height are left alone).
bool app_display_size(int& width, int& height);
// Resizes a windowed (not full screen) desktop window; its position stays. false: the platform cannot (mobile, web).
bool app_set_window_size(int width, int height);
// Vsync as the game asked for it (AppDesc::vsync at start, app_set_vsync afterwards). Mobile displays always sync.
bool app_vsync();
// Turns vsync on or off while the game runs. false (nothing changed): the platform or the graphics driver cannot (Android,
// iOS, a Linux driver without GLX_EXT_swap_control). macOS only stops presents from waiting for the display: the frame
// rate stays at the display's.
bool app_set_vsync(bool on);
// Mouse lock: the pointer is hidden and held in the window, and Input::mouse_delta() reports raw movement. The window
// system may unlock it by itself (focus lost), so the caller asks again when the window regains focus.
void app_lock_mouse(bool lock);
// The on-screen keyboard (phones and tablets; a no-op on desktop). What is typed arrives as Input text and key edges.
void app_show_keyboard(bool show);
// The part of the framebuffer that a notch, rounded corners, status and navigation bars cover, in framebuffer pixels from
// each edge: the screen minus this is the safe area. Android: the window insets of the activity (system bars and display
// cutout); iOS: the view's safeAreaInsets. Desktop windows: all zero. Refreshed on resize and rotation (and polled a few
// times a second, because the system reports some changes late).
EdgeInsets app_safe_insets();
// One pulse of the vibration motor of a phone, `seconds` long. iOS cannot pick a length: short is a haptic tap, long the
// system vibration. A no-op without a motor, and on desktop.
void app_vibrate(float seconds);

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
