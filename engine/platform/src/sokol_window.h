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
