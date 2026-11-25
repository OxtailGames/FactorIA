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
#include "fa/core/types.h"
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
    // Ending (Android only): the system destroyed the activity (Back that no handler consumed, game.quit(), the system
    // relaunching or closing the app). Sent once, on the engine's thread, while Android's main thread waits for it (about
    // 1.5 s at most). The surface is already gone: no GPU work. The process ends right after, without AppDesc::cleanup.
    enum class Type { Resized, FocusLost, FocusGained, Suspended, Resumed, QuitRequested, FilesDropped, Ending };
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
    int width = 1280;  // initial window size (logical pixels)
    int height = 720;
    bool fullscreen = false;
    bool vsync = true;
    bool highDpi = true;
    int sampleCount = 1;  // MSAA of the window swapchain
    // The window icon (the title bar and the taskbar): the same icon in several sizes, the platform picks the closest to
    // what it shows. Used on Windows and Linux; macOS shows the icon of the app bundle (the Dock) and mobile apps have
    // none here. Empty = the platform's default icon. At most 8 images are used. to_sapp_desc keeps the pixels alive in
    // the copy of this AppDesc it owns, like `title`.
    std::vector<AppIconImage> icon;
    // macOS: the Dock icon while the app runs, for a program that is not an app bundle (the editor, started from the
    // `factoria` executable, would show the generic one). Draw it on Apple's icon grid: the tile covers the middle ~80%
    // of the image. Empty = the bundle's icon. The other platforms ignore it.
    AppIconImage dockIcon;
    // Linux: the window's class (WM_CLASS), the name docks and window switchers group the window under and match with
    // a .desktop file's StartupWMClass. Empty = none set. Windows takes the program's name from the exe's version
    // resource and macOS from the app bundle.
    std::string appName;
    // Input is fed into this object; positions are converted with to_design_coords. Physical gamepads are polled into
    // it once per frame, before `frame` runs (fa/platform/gamepad.h; not while the window is unfocused).
    Input* input = nullptr;
    // Converts framebuffer pixel coordinates to design coordinates (letterbox).
    std::function<Vec2(Vec2 framebufferPos)> to_design_coords;

    std::function<void()> init;            // GPU is ready (gfx_environment() valid)
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

// The window's device for sg_setup(). On Windows the first call makes the D3D11 device and the window's swapchain (sokol_app
// owns none there). While a GPU device has claimed the window (app_claim_native_window: D3D12, Vulkan) it makes nothing and
// returns app_gfx_formats(), whose null device makes sg_setup() fail (logged once).
GfxEnvironment app_gfx_environment();
// The window's default formats (colour, depth, sample count) without making any device: what a D3D12 or Vulkan renderer
// reads before it makes its own swapchain. Windows: the formats the D3D11 presenter would have (BGRA8, depth-stencil when
// asked, the window's sample count), with no device in it; elsewhere sokol_app's environment, as app_gfx_environment().
GfxEnvironment app_gfx_formats();
// This frame's window views for the swapchain pass (Windows: invalid until app_gfx_environment() made the device). Invalid
// (sokol_gfx skips the pass) while a GPU device has claimed the window: that device acquires its own images.
GfxSwapchain app_gfx_swapchain();
// Windows D3D11: copies what the window pass drew this frame (before it is presented) into `rgba`, width x height RGBA8,
// row 0 = top. False elsewhere, on another size, with an HDR buffer, or while a GPU device (D3D12, Vulkan) has claimed the
// window (there is no D3D11 presenter then): the caller reads the frame its own way.
bool app_read_window_back_buffer(int width, int height, std::uint8_t* rgba);

// ---- Who makes the window's swapchain (M77-P9e1) -------------------------------------------------------------------
// A window holds one swapchain: Windows takes one flip-model DXGI swapchain per HWND, Android one producer per
// ANativeWindow. Either the platform makes it (sokol_app's own; on Windows the D3D11 presenter of app_gfx_environment()),
// or a GPU device that makes its own (D3D12, Vulkan) claims the window's native handles first (app_claim_native_window).
enum class WindowPresenter : std::uint8_t {
    None,      // nothing made yet (Windows before the first app_gfx_environment(); after a device let the window go)
    Platform,  // the platform's swapchain presents the frames
    Device,    // a GPU device made (or is making) its own swapchain on the native window
};
const char* window_presenter_name(WindowPresenter presenter);  // "none", "platform", "device"
enum class WindowPresenterEvent : std::uint8_t {
    PlatformAsked,  // app_gfx_environment(): the platform's swapchain is wanted
    DeviceClaim,    // app_claim_native_window()
    DeviceRelease,  // app_release_native_window()
};
// What one event does. app.cpp acts on it; the rule itself is pure, so every platform's tests check it.
struct WindowPresenterStep {
    WindowPresenter next = WindowPresenter::None;
    bool makePlatform = false;     // make the platform's swapchain now (Windows: the D3D11 presenter)
    bool releasePlatform = false;  // destroy the platform's swapchain before the device makes its own on the window
    std::string error;             // "" = done; else why the event is refused (the state stays `now`)
};
// The state machine: PlatformAsked makes the platform's swapchain from None and is refused while a device has the window;
// DeviceClaim takes the window from None, or from Platform when no graphics context draws with it (`platformInUse` false:
// the platform's swapchain is released first), and is refused when `busy` says the window cannot take a device's swapchain
// (it has a graphics API of its own) or a device has it already; DeviceRelease goes back to None (nothing from another state).
WindowPresenterStep window_presenter_step(WindowPresenter now, WindowPresenterEvent event, bool platformInUse,
                                          const std::string& busy);

// The window's native handles, for a GPU device that makes its own swapchain on it (gpu::SwapchainDesc::nativeWindow).
struct NativeWindow {
    // HWND (Windows), the X11 Window as an integer in the pointer (Linux), ANativeWindow* (Android), the CAMetalLayer* of
    // sokol_app's view (macOS: Vulkan on MoltenVK). Null: no window, or a platform that hands none (iOS, the web).
    const void* window = nullptr;
    const void* display = nullptr;  // the X11 Display* (Linux); null elsewhere
    // "" when a GPU device may make its own swapchain on the window; else why not, one sentence (a Linux EGL window, the
    // web: sokol_app made an OpenGL context on it and swaps its buffers after every frame; no window). A Linux GLX window
    // and an Android window are not busy: sokol_app's OpenGL surface leaves them when a device claims them.
    std::string busy;
};
// The handles, without claiming the window. Valid inside run_app callbacks.
NativeWindow app_native_window();
// Claims the window for the GPU device of `backend` (its name, "d3d12" or "vulkan": HDR output says it is not available on
// it). On success the platform's swapchain is gone (Windows: the D3D11 presenter is destroyed and its flip-model swapchain
// released at once, so the device's own can be made on the HWND; Linux and Android: sokol_app's OpenGL context moves off
// the window to a 1x1 pbuffer, or to no drawable, its window surface (a GLXWindow, an EGL window surface) is destroyed
// and its per-frame swap does nothing), app_gfx_environment() makes none and app_gfx_swapchain() is invalid until
// app_release_native_window(). Refused (nothing changes) when the window is busy, a graphics context draws with the
// platform's swapchain (sokol_gfx is set up), a device has the window already, or the GL driver refuses to move the
// context off the window (Linux, Android).
Result<NativeWindow> app_claim_native_window(const std::string& backend);
// Android: an ANativeWindow lives only while the activity is in front, so the device that claimed the window hears here
// when it goes and when a new one comes (`listener` gets null, then the new ANativeWindow*). It is called on the frame
// thread, between frames. With null the window is about to be destroyed: destroy the swapchain before returning (the
// window stays valid until then); with a window, make the swapchain on it (before the next present). One listener; an
// empty function removes it, and app_release_native_window() removes it too. Never called on other platforms, whose
// window lives as long as the app.
void app_set_native_window_listener(std::function<void(const void* window)> listener);
// Gives the window back once the device destroyed its swapchain (a backend that failed to start, the end of a renderer): the
// next app_gfx_environment() makes the platform's swapchain again (Linux and Android: the OpenGL context is current on a
// new window surface here, with its vsync on Linux; Android with no window at that moment: sokol_app makes its surface on
// the next one). Nothing when no device has the window.
void app_release_native_window();
WindowPresenter app_window_presenter();
// The backend that claimed the window ("" while no device has it).
std::string app_window_device_backend();
int app_framebuffer_width();
int app_framebuffer_height();
float app_dpi_scale();
// Closes the window (desktop: a QuitRequested event with fromApp follows). Android: finishes the activity once, so the
// system destroys it and an Ending event follows; sokol_app ignores a quit request there.
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
    // Its refresh rate in Hz: on macOS and iOS the top of a variable-rate panel (ProMotion: 120), on Windows the
    // frequency of the monitor's current display mode (a panel with dynamic refresh rate reports the mode in force
    // now), elsewhere the mode in use. 0 = the OS does not say (a Windows driver that answers "the hardware's
    // default", Linux without libXrandr).
    double refreshHz = 0.0;
};
// The monitors, primary first. Empty: this platform cannot list them (phones, tablets, web).
std::vector<MonitorInfo> app_monitors();
// The refresh rate in Hz of the display the window is on, asked of the OS each call (cheap, but not for every frame):
// macOS NSScreen.maximumFramesPerSecond (the top of a variable rate; the display mode's rate before macOS 12), iOS
// the screen's maximumFramesPerSecond (60 on an iPhone whose Info.plist does not set
// CADisableMinimumFrameDurationOnPhone), Windows the frequency of the monitor's current display mode (59 read as
// 59.94), Linux the mode of the XRandR output under the window's centre, Android Display.getRefreshRate(). 0: unknown
// (no window, the web, which has no API for it, a driver that does not say, Linux without libXrandr). The engine
// estimates it from the frame times then (docs/UPSCALING.md).
double app_display_refresh_hz();
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
