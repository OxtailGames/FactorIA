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

#ifdef __cplusplus
}
#endif
