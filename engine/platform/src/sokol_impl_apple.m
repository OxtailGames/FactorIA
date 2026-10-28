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

// ---- monitors -----------------------------------------------------------------------------------------------------------
#if !TARGET_OS_IPHONE
static bool fa_mac_borderless;
static NSRect fa_mac_stored_frame;
static NSUInteger fa_mac_stored_style;
static NSApplicationPresentationOptions fa_mac_stored_presentation;
#endif

int fa_sapp_monitors(fa_sapp_monitor* out, int max) {
#if !TARGET_OS_IPHONE
    NSArray<NSScreen*>* screens = NSScreen.screens;  // [0] is the one with the menu bar: the primary
    NSScreen* here = _sapp.macos.window.screen ? _sapp.macos.window.screen : NSScreen.mainScreen;
    int n = 0;
    for (NSScreen* screen in screens) {
        if (n >= max) break;
        fa_sapp_monitor* m = &out[n];
        memset(m, 0, sizeof(*m));
        NSString* name = @"Display";
        if (@available(macOS 10.15, *)) name = screen.localizedName;
        snprintf(m->name, sizeof(m->name), "%s", name.UTF8String);
        m->x = (int)screen.frame.origin.x;
        m->y = (int)screen.frame.origin.y;
        m->w = (int)(screen.frame.size.width + 0.5);
        m->h = (int)(screen.frame.size.height + 0.5);
        m->primary = n == 0;
        m->current = screen == here;
        n++;
    }
    return n;
#else
    (void)out;
    (void)max;
    return 0;
#endif
}

bool fa_sapp_move_to_monitor(int index) {
#if !TARGET_OS_IPHONE
    NSArray<NSScreen*>* screens = NSScreen.screens;
    if (index < 0 || index >= (int)screens.count) return false;
    NSScreen* screen = screens[(NSUInteger)index];
    NSWindow* window = _sapp.macos.window;
    if (fa_mac_borderless) {
        [window setFrame:screen.frame display:YES];
        return true;
    }
    if (window.styleMask & NSWindowStyleMaskFullScreen) return false;  // its own Space: leave it first
    const NSRect area = screen.visibleFrame;
    NSRect frame = window.frame;
    frame.origin.x = area.origin.x + (area.size.width - frame.size.width) / 2;
    frame.origin.y = area.origin.y + (area.size.height - frame.size.height) / 2;
    [window setFrame:frame display:YES];
    return true;
#else
    (void)index;
    return false;
#endif
}

bool fa_sapp_set_borderless(bool on) {
#if !TARGET_OS_IPHONE
    NSWindow* window = _sapp.macos.window;
    if (on == fa_mac_borderless) return true;
    if (window.styleMask & NSWindowStyleMaskFullScreen) return false;
    if (on) {
        fa_mac_stored_frame = window.frame;
        fa_mac_stored_style = window.styleMask;
        fa_mac_stored_presentation = NSApp.presentationOptions;
        NSScreen* screen = window.screen ? window.screen : NSScreen.mainScreen;
        // No title bar, but still "resizable" so the window can become key (a plain borderless window cannot).
        window.styleMask = NSWindowStyleMaskResizable;
        NSApp.presentationOptions = NSApplicationPresentationHideDock | NSApplicationPresentationHideMenuBar;
        window.level = NSMainMenuWindowLevel + 1;
        [window setFrame:screen.frame display:YES];
        [window makeKeyAndOrderFront:nil];
    } else {
        window.level = NSNormalWindowLevel;
        NSApp.presentationOptions = fa_mac_stored_presentation;
        window.styleMask = fa_mac_stored_style;
        [window setFrame:fa_mac_stored_frame display:YES];
        [window makeKeyAndOrderFront:nil];
    }
    fa_mac_borderless = on;
    return true;
#else
    (void)on;
    return false;
#endif
}

bool fa_sapp_is_borderless(void) {
#if !TARGET_OS_IPHONE
    return fa_mac_borderless;
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

bool fa_sapp_set_dock_icon(const unsigned char* rgba, int w, int h) {
#if !TARGET_OS_IPHONE
    if (rgba == NULL || w <= 0 || h <= 0 || NSApp == nil) return false;
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                    pixelsWide:w
                                                                    pixelsHigh:h
                                                                 bitsPerSample:8
                                                               samplesPerPixel:4
                                                                      hasAlpha:YES
                                                                      isPlanar:NO
                                                                colorSpaceName:NSDeviceRGBColorSpace
                                                                  bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
                                                                   bytesPerRow:w * 4
                                                                  bitsPerPixel:32];
    if (rep == nil) return false;
    memcpy(rep.bitmapData, rgba, (size_t)w * (size_t)h * 4);
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
    [image addRepresentation:rep];
    NSApp.applicationIconImage = image;
    return true;
#else
    (void)rgba;
    (void)w;
    (void)h;
    return false;
#endif
}
