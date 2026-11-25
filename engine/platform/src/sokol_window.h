// Window operations sokol_app has no API for. They reach sokol_app's private state (_sapp), which only the translation
// unit that contains its implementation can see, so they live in sokol_impl.c (and sokol_impl_apple.m on Apple) and
// app.cpp calls them through this header. Private to fa_platform.
#pragma once

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// The window's client size in logical pixels (what sapp_width() / sapp_dpi_scale() gives, without rounding differences).
void fa_sapp_window_size(int* w, int* h);
// The monitor the window is on, in logical pixels. false: unknown on this platform (mobile).
bool fa_sapp_display_size(int* w, int* h);
// The monitors, primary first, in logical pixels (what each one is called is what the OS says: the driver's device string on
// Windows, NSScreen.localizedName on macOS, the RandR output on Linux). Fills up to `max` entries and returns how many; 0 means
// this platform cannot list them (mobile, web). `x`, `y` are the monitor's top-left corner in the desktop space.
typedef struct fa_sapp_monitor {
    char name[64];
    int x, y, w, h;
    bool primary;
    bool current;       // the window is on it (its centre, on Linux)
    double refresh_hz;  // its refresh rate (the largest of a variable one); 0 = the OS does not say
} fa_sapp_monitor;
int fa_sapp_monitors(fa_sapp_monitor* out, int max);
// The refresh rate of the display the window is on, in Hz: NSScreen.maximumFramesPerSecond on macOS (CGDisplayModeGetRefreshRate
// before macOS 12), the frame rate sokol_app's view runs at on iOS (UIScreen.maximumFramesPerSecond, 60 on an iPhone whose
// Info.plist does not lift the 60 fps cap), the current display mode's frequency on Windows, the CRTC mode of the RandR output
// under the window's centre on Linux. 0: unknown (no window yet, the web, Android: app.cpp asks Android through JNI, a driver
// that answers "the hardware's default", Linux without libXrandr).
double fa_sapp_display_refresh_hz(void);
// Moves the window onto monitor `index` (as fa_sapp_monitors lists them): a window is centred on it, a full screen (Windows,
// Linux) or borderless (macOS) window covers it. false: no such monitor, or the platform cannot (a macOS window in its own
// full screen Space stays where it is).
bool fa_sapp_move_to_monitor(int index);
// macOS only: a window without title bar that covers its monitor and hides the menu bar and the Dock, on (true) or off. false: not
// available here (every other platform: its full screen already is borderless) or not possible now (the window is in macOS's
// native full screen).
bool fa_sapp_set_borderless(bool on);
bool fa_sapp_is_borderless(void);
// Resizes the client area to w x h logical pixels (a window that is not full screen). false: this platform cannot (mobile).
bool fa_sapp_set_window_size(int w, int h);
// The part of the window the notch, rounded corners and home indicator cover, in framebuffer pixels (iOS: the safeAreaInsets of
// sokol_app's view times the display scale). false: this platform has none to report; the values are left alone.
bool fa_sapp_safe_insets(float* left, float* top, float* right, float* bottom);
// Turns vsync on or off while running. false: this platform or graphics driver cannot (the state is unchanged).
bool fa_sapp_set_vsync(bool on);
// macOS: shows `rgba` (w x h RGBA8, not premultiplied, row 0 = top) as the Dock icon while the app runs (AppDesc::dockIcon).
// false: not available here (every other platform: their window icon is sapp_desc.icon).
bool fa_sapp_set_dock_icon(const unsigned char* rgba, int w, int h);
// IME (ime_apple.mm), Apple only. The views sokol_app made, as Objective-C objects behind void* (NSView* of macOS, UITextField* of
// iOS; nil when there is none yet: the iOS text field exists after the first sapp_show_keyboard).
void* fa_sapp_macos_view(void);
void* fa_sapp_ios_textfield(void);
// macOS: what sokol_app's keyDown: does for `nsevent` (an NSEvent*): the KEY_DOWN event and, when `chars`, a CHAR event per
// character of NSEvent.characters (and the paste event of Cmd+V). ime_apple.mm calls it with chars = false when an input method
// already delivered that text.
void fa_sapp_macos_key_down(const void* nsevent, bool chars);
// Linux: sets the window's WM_CLASS to `name` (AppDesc::appName). false: not available here.
bool fa_sapp_set_class_name(const char* name);
// The window's native handles for a GPU device that makes its own swapchain on it (app_native_window, M77-P9e1): the
// HWND (Windows), the X11 Window as an integer in `*window` and its Display* in `*display` (Linux), the ANativeWindow*
// of the current surface (Android), the CAMetalLayer* sokol_app made for its view (macOS). false (both left null): no
// window yet, or this platform hands none (iOS, the web).
bool fa_sapp_native_window(void** window, void** display);
// The OpenGL surface sokol_app keeps on its window (M77-P9e3), for a GPU device that makes its own swapchain there
// (app_claim_native_window on Linux and Android). sokol_app made its GL context with the window (a GLXWindow on the X11
// window, an EGL window surface on the ANativeWindow) and swaps it after every frame; while a Vulkan device presents,
// that surface must be off the window.
//
// Release: the context moves to a 1x1 pbuffer of the window's config (GLXFBConfig, EGLConfig) or, when the driver makes
// no pbuffer of it, stays current with no drawable at all (GLX_ARB_create_context allows that for a 3.0+ context, which
// sokol_app's is; EGL_KHR_surfaceless_context on Android); the window surface is destroyed and sokol_app's per-frame
// swap does nothing until the restore. The context stays alive, so a fallback to OpenGL in the same process needs no
// new one. true: released (or it already was); with no drawable, `err` says why there is no pbuffer. false: nothing
// changed and `err` (errLen bytes, NUL-terminated) says why: no window yet, a Linux build whose sokol_app draws through
// EGL (SOKOL_FORCE_EGL, -DFA_GFX_BACKEND=GLES3), a driver that refused both, or a platform with no GL window surface to
// release (Windows, Apple, the web). Android: while released, a new ANativeWindow (the app came back from the
// background) gets a stand-in in place of a window surface, and the window listener hears both its loss and its
// successor (egl_surface_handover.h).
bool fa_sapp_gl_surface_release(char* err, size_t errLen);
// Restore: a new window surface on the window (a GLXWindow, an EGL window surface), the context current on it again,
// sokol_app's swap and swap interval (vsync) back, the pbuffer destroyed. Call it once the device destroyed its
// swapchain. Android with no window at that moment: nothing to make, sokol_app makes its own surface on the next one.
// true: on the window again (or it never left). false: the driver refused the window surface (`err` says so); the
// context stays off the window and OpenGL frames show nothing.
bool fa_sapp_gl_surface_restore(char* err, size_t errLen);
// Shutdown of the app with a device that still had the window: gives up the stand-in the context draws on (the pbuffer;
// on Android sokol_app destroys its stand-in itself) and makes no window surface, unlike a restore, whose surface
// sokol_app's own shutdown would destroy at once (and which fails when the window is still the device's). Nothing when
// the surface never left.
void fa_sapp_gl_surface_discard(void);
// macOS: a GPU device (Vulkan on MoltenVK) claimed the CAMetalLayer, or gave it back. Its swapchain sets the layer's
// device and pixelFormat; the first call saves what sokol_app made the layer with, the second puts it back, so a
// fallback to Metal in the same process draws with a layer that matches sokol_gfx's pipelines. No-ops on every other
// platform.
void fa_sapp_window_claimed(void);
void fa_sapp_window_returned(void);
// Where the GL context draws now: 0 = on the window (sokol_app's own state), 1 = a pbuffer, 2 = no drawable
// (surfaceless).
int fa_sapp_gl_surface_state(void);
// Android, while released: `listener` hears on sokol_app's loop thread (the frame thread), between frames, that the
// window is going (window null: destroy the swapchain before returning, the window is still valid until then) and that
// a new ANativeWindow came (make the swapchain there). Null stops it. A no-op on every other platform (the X11 window
// outlives a release).
void fa_sapp_gl_surface_set_window_listener(void (*listener)(void* window, void* user), void* user);
// HDR output (hdr_output.cpp). The kind of pixels the window's swapchain holds: 0 = sokol_app's standard 8-bit format,
// 1 = 16-bit float (D3D11: R16G16B16A16_FLOAT for scRGB; Metal: RGBA16Float with EDR on, in extended sRGB, or extended
// LINEAR sRGB when `linear`), 2 = 10-bit (D3D11 only: R10G10B10A2_UNORM for HDR10, never with MSAA). Switches between
// frames (before the swapchain of the next one is taken) and returns the kind in effect: the old one when the platform
// cannot (no window, not D3D11 or Metal, Windows before 10, a buffer resize the driver refused). D3D11 sets only the
// buffers; the colour space is hdr_output_win32.cpp's (IDXGISwapChain3::SetColorSpace1).
int fa_sapp_set_swapchain_kind(int kind, bool linear);
int fa_sapp_swapchain_kind(void);
// Apple: the EDR headroom of the screen the window is on (NSScreen; UIScreen from iOS 16). false: no window yet, or
// `old_os` (iOS before 16 has no EDR headroom to read).
typedef struct fa_sapp_edr_screen {
    char name[64];
    float max_headroom;  // maximumPotentialExtendedDynamicRangeColorComponentValue / potentialEDRHeadroom
    float headroom;      // maximumExtendedDynamicRangeColorComponentValue / currentEDRHeadroom
    bool old_os;
} fa_sapp_edr_screen;
bool fa_sapp_edr(fa_sapp_edr_screen* out);
// The web only: sokol_app's key, focus and blur handlers on the window go through the IME backend first (ime_web.cpp:
// what the browser's input method takes is not a game key, and the focus moving to the hidden <input> is not the page
// losing it). app.cpp calls it once, when the app starts.
void fa_sapp_web_route_events(void);

#ifdef __cplusplus
}
#endif
