// Window operations sokol_app has no API for. They reach sokol_app's private state (_sapp), which only the translation
// unit that contains its implementation can see, so they live in sokol_impl.c (and sokol_impl_apple.m on Apple) and
// app.cpp calls them through this header. Private to fa_platform.
#pragma once

#include <stdbool.h>

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
    bool current;  // the window is on it (its centre, on Linux)
} fa_sapp_monitor;
int fa_sapp_monitors(fa_sapp_monitor* out, int max);
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
// HDR output (hdr_output.cpp). The kind of pixels the window's swapchain holds: 0 = sokol_app's standard 8-bit format, 1 = 16-bit
// float (D3D11: R16G16B16A16_FLOAT for scRGB; Metal: RGBA16Float with EDR on, in extended sRGB, or extended LINEAR sRGB when
// `linear`), 2 = 10-bit (D3D11 only: R10G10B10A2_UNORM for HDR10, never with MSAA). Switches between frames (before the
// swapchain of the next one is taken) and returns the kind in effect: the old one when the platform cannot (no window, not D3D11
// or Metal, Windows before 10, a buffer resize the driver refused). D3D11 sets only the buffers; the colour space is
// hdr_output_win32.cpp's (IDXGISwapChain3::SetColorSpace1).
int fa_sapp_set_swapchain_kind(int kind, bool linear);
int fa_sapp_swapchain_kind(void);
// Apple: the EDR headroom of the screen the window is on (NSScreen; UIScreen from iOS 16). false: no window yet, or `old_os`
// (iOS before 16 has no EDR headroom to read).
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
