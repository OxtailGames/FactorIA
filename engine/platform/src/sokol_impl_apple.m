// sokol implementation translation unit for macOS and iOS (Objective-C, ARC).
// UNTESTED: cannot be compiled on the Linux development machine.
#include <TargetConditionals.h>

#define SOKOL_IMPL

// macOS: we own main() and call sapp_run() from fa::run_app().
// iOS: sokol_app provides main(); the game supplies sokol_main() (player/).
#if !TARGET_OS_IPHONE
#define SOKOL_NO_ENTRY
#endif

#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"
#include "sokol_log.h"
#include "sokol_time.h"
#include "sokol_audio.h"

// ---- window operations sokol_app has no API for (sokol_window.h; see sokol_impl.c) -----------------------------------
// UNTESTED: written without a Mac at hand. Cocoa works in points, which are the logical pixels.
#include "sokol_window.h"

void fa_sapp_window_size(int* w, int* h) {
    *w = _sapp.window_width;
    *h = _sapp.window_height;
}

bool fa_sapp_display_size(int* w, int* h) {
#if !TARGET_OS_IPHONE
    NSScreen* screen = _sapp.macos.window.screen ? _sapp.macos.window.screen : NSScreen.mainScreen;
    if (screen == nil) return false;
    *w = (int)(screen.frame.size.width + 0.5);
    *h = (int)(screen.frame.size.height + 0.5);
    return true;
#else
    return false;
#endif
}

bool fa_sapp_set_window_size(int w, int h) {
#if !TARGET_OS_IPHONE
    [_sapp.macos.window setContentSize:NSMakeSize(w, h)];
    return true;
#else
    return false;
#endif
}

bool fa_sapp_set_vsync(bool on) {
#if !TARGET_OS_IPHONE && defined(SOKOL_METAL)
    // CAMetalLayer.displaySyncEnabled: presents no longer wait for the display. sokol_app still paces its frames with a
    // display link, so this lets the picture tear instead of raising the frame rate beyond the display's.
    _sapp.mtl.layer.displaySyncEnabled = on;
    return true;
#else
    return false;
#endif
}

bool fa_sapp_safe_insets(float* left, float* top, float* right, float* bottom) {
#if TARGET_OS_IPHONE
    // UIView.safeAreaInsets (iOS 11): points, relative to the view, which covers the screen. They are zero until the view
    // is in a window and follow the rotation. Points times the display scale are framebuffer pixels.
    if (_sapp.ios.view == nil) return false;
    const UIEdgeInsets insets = _sapp.ios.view.safeAreaInsets;
    const float scale = _sapp.dpi_scale;
    *left = (float)insets.left * scale;
    *top = (float)insets.top * scale;
    *right = (float)insets.right * scale;
    *bottom = (float)insets.bottom * scale;
    return true;
#else
    return false;
#endif
}
