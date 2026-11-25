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
#include <stdio.h>

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

#if !TARGET_OS_IPHONE
// The refresh rate of `screen` in Hz, 0 when macOS does not say. maximumFramesPerSecond (macOS 12) is the top of a variable
// rate (ProMotion: 120); before it the display mode's rate, which is 0 for most built-in panels.
static double fa_mac_screen_hz(NSScreen* screen) {
    if (screen == nil) return 0.0;
    double hz = 0.0;
    if (@available(macOS 12.0, *)) hz = (double)screen.maximumFramesPerSecond;
    if (hz < 1.5) {
        NSNumber* number = screen.deviceDescription[@"NSScreenNumber"];
        if (number != nil) {
            CGDisplayModeRef mode = CGDisplayCopyDisplayMode((CGDirectDisplayID)number.unsignedIntValue);
            if (mode != NULL) {
                hz = CGDisplayModeGetRefreshRate(mode);
                CGDisplayModeRelease(mode);
            }
        }
    }
    return hz >= 1.5 ? hz : 0.0;
}
#endif

double fa_sapp_display_refresh_hz(void) {
#if !TARGET_OS_IPHONE
    if (_sapp.macos.window == nil) return 0.0;
    return fa_mac_screen_hz(_sapp.macos.window.screen ? _sapp.macos.window.screen : NSScreen.mainScreen);
#else
    // The screen of sokol_app's window (what its display link runs at). An iPhone runs a ProMotion panel at 60 at most unless
    // the Info.plist sets CADisableMinimumFrameDurationOnPhone (iPads do not need it).
    if (_sapp.ios.window == nil) return 0.0;
    UIScreen* screen = _sapp.ios.window.windowScene ? _sapp.ios.window.windowScene.screen : UIScreen.mainScreen;
    double hz = screen ? (double)screen.maximumFramesPerSecond : 0.0;
    if (hz > 60.0 && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        id lifted = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"];
        if (!([lifted respondsToSelector:@selector(boolValue)] && [lifted boolValue])) hz = 60.0;
    }
    return hz >= 1.5 ? hz : 0.0;
#endif
}

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
        m->refresh_hz = fa_mac_screen_hz(screen);
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

// ---- HDR output (sokol_window.h, hdr_output.cpp) ------------------------------------------------------------------------
static int fa_mtl_kind;      // 0 = sokol_app's 8-bit format, 1 = RGBA16Float with EDR
static bool fa_mtl_linear;   // kind 1: extended linear sRGB (true) or extended sRGB (false)

int fa_sapp_swapchain_kind(void) { return fa_mtl_kind; }

int fa_sapp_set_swapchain_kind(int kind, bool linear) {
#if defined(SOKOL_METAL)
    if (kind != 1) kind = 0;  // no 10-bit swapchain on Metal here: EDR is the float one
    if (kind == fa_mtl_kind && (kind == 0 || linear == fa_mtl_linear)) return kind;
    CAMetalLayer* layer = _sapp.mtl.layer;
    if (!_sapp.valid || layer == nil) return fa_mtl_kind;
    if (kind == 1) {
        if (@available(macOS 10.11, iOS 16.0, *)) {
        } else {
            return fa_mtl_kind;  // iOS before 16: the layer has no EDR
        }
    }
    // sokol_app reads desc.hdr for the layer's format, its MSAA texture and sapp_color_format() (what sglue_swapchain() tells
    // sokol_gfx), so the next drawable, its pass and the pipelines drawn in it agree. Drawables already taken keep the old
    // format; the engine takes the next one after this call.
    _sapp.desc.hdr = kind == 1;
    layer.pixelFormat = _sapp_mtl_color_format();
    // sokol_app's own HDR colour space is extended linear Display P3. Extended sRGB keeps sRGB's primaries, so a picture made
    // for sRGB keeps its colours; `linear` says whether the values are linear light or sRGB-encoded like an SDR picture.
    CGColorSpaceRef space = CGColorSpaceCreateWithName(
        kind == 1 ? (linear ? kCGColorSpaceExtendedLinearSRGB : kCGColorSpaceExtendedSRGB) : kCGColorSpaceSRGB);
    layer.colorspace = space;
    CGColorSpaceRelease(space);
    if (@available(macOS 10.11, iOS 16.0, *)) layer.wantsExtendedDynamicRangeContent = kind == 1;
    if (_sapp.desc.sample_count > 1) _sapp_mtl_swapchain_resize(_sapp.framebuffer_width, _sapp.framebuffer_height);
    fa_mtl_kind = kind;
    fa_mtl_linear = linear;
    return kind;
#else
    (void)kind;
    (void)linear;
    return 0;
#endif
}

bool fa_sapp_edr(fa_sapp_edr_screen* out) {
    memset(out, 0, sizeof(*out));
    out->max_headroom = 1.0f;
    out->headroom = 1.0f;
    if (!_sapp.valid) return false;
#if !TARGET_OS_IPHONE
    NSScreen* screen = _sapp.macos.window.screen ? _sapp.macos.window.screen : NSScreen.mainScreen;
    if (screen == nil) return false;
    if (@available(macOS 10.15, *)) {
        snprintf(out->name, sizeof(out->name), "%s", screen.localizedName.UTF8String);
        out->max_headroom = (float)screen.maximumPotentialExtendedDynamicRangeColorComponentValue;
    } else {
        snprintf(out->name, sizeof(out->name), "Display");
        out->max_headroom = (float)screen.maximumExtendedDynamicRangeColorComponentValue;
    }
    out->headroom = (float)screen.maximumExtendedDynamicRangeColorComponentValue;
    return true;
#else
    if (@available(iOS 16.0, *)) {
        UIScreen* screen = _sapp.ios.window.windowScene.screen;
        if (screen == nil) return false;
        snprintf(out->name, sizeof(out->name), "Display");
        out->max_headroom = (float)screen.potentialEDRHeadroom;
        out->headroom = (float)screen.currentEDRHeadroom;
        return true;
    }
    out->old_os = true;
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

// ---- the native window for a GPU device of its own (app_native_window, M77-P9e1) ----------------------------------------
// macOS: the CAMetalLayer sokol_app made for its view (Vulkan on MoltenVK presents into it). sokol_app takes a drawable of
// it only when sokol_glue asks for the frame's swapchain, which app.cpp does not while a device has the window.
bool fa_sapp_native_window(void** window, void** display) {
    *window = NULL;
    *display = NULL;
#if !TARGET_OS_IPHONE && defined(SOKOL_METAL)
    if (!_sapp.valid || _sapp.mtl.layer == nil) return false;
    *window = (__bridge void*)_sapp.mtl.layer;
    return true;
#else
    return false;
#endif
}

// The window's OpenGL surface (sokol_window.h, M77-P9e3): Apple's windows draw with Metal, there is none to release.
bool fa_sapp_gl_surface_release(char* err, size_t errLen) {
    snprintf(err, errLen, "this platform's window has no OpenGL surface to release");
    return false;
}
bool fa_sapp_gl_surface_restore(char* err, size_t errLen) {
    if (errLen > 0) err[0] = 0;
    return true;
}
int fa_sapp_gl_surface_state(void) { return 0; }

// ---- IME (ime_apple.mm) -------------------------------------------------------------------------------------------------
void* fa_sapp_macos_view(void) {
#if !TARGET_OS_IPHONE
    return (__bridge void*)_sapp.macos.view;
#else
    return NULL;
#endif
}

void* fa_sapp_ios_textfield(void) {
#if TARGET_OS_IPHONE
    return (__bridge void*)_sapp.ios.textfield;
#else
    return NULL;
#endif
}

// A copy of sokol_app's -[_sapp_macos_view keyDown:] with the CHAR events optional (the text may have been delivered already).
void fa_sapp_macos_key_down(const void* nsevent, bool chars) {
#if !TARGET_OS_IPHONE
    NSEvent* event = (__bridge NSEvent*)nsevent;
    if (!_sapp_events_enabled()) return;
    _sapp_gl_make_current();
    const uint32_t mods = _sapp_macos_mods(event);
    const sapp_keycode key_code = _sapp_translate_key(event.keyCode);
    _sapp_macos_key_event(SAPP_EVENTTYPE_KEY_DOWN, key_code, event.isARepeat, mods);
    const NSString* text = event.characters;
    const NSUInteger len = text.length;
    if (chars && len > 0) {
        _sapp_init_event(SAPP_EVENTTYPE_CHAR);
        _sapp.event.modifiers = mods;
        for (NSUInteger i = 0; i < len; i++) {
            const unichar codepoint = [text characterAtIndex:i];
            if ((codepoint & 0xFF00) == 0xF700) continue;
            _sapp.event.char_code = codepoint;
            _sapp.event.key_repeat = event.isARepeat;
            _sapp_call_event(&_sapp.event);
        }
    }
    if (_sapp.clipboard.enabled && (mods == SAPP_MODIFIER_SUPER) && (key_code == SAPP_KEYCODE_V)) {
        _sapp_init_event(SAPP_EVENTTYPE_CLIPBOARD_PASTED);
        _sapp_call_event(&_sapp.event);
    }
#else
    (void)nsevent;
    (void)chars;
#endif
}

bool fa_sapp_set_class_name(const char* name) {
    (void)name;  // Linux only: the name of a macOS app comes from its bundle
    return false;
}

#if defined(SOKOL_METAL)
// The command buffer sokol records the next passes into (the one sg_commit() submits), made now when there is none yet. sokol hands
// out the encoder of a pass but never the buffer; the MetalFX scaler (engine/render/src/metalfx_apple.mm) needs it to order its own
// buffer against the passes before and after it with a shared event.
const void* fa_sg_mtl_command_buffer(void) {
    _sg_mtl_finish_blit_cmd_encoder();  // sokol keeps a blit encoder open between passes; an event is encoded outside any encoder
    _sg_mtl_acquire_cmd_buffer();
    return (__bridge const void*)_sg.mtl.cmd_buffer;
}
#endif
