// macOS window read-back for autotest screenshots (Metal). See ui::read_backbuffer in ui_backend.h.
#include "backbuffer_apple.h"

#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <cstring>
#include <utility>

#include "sokol_app.h"
#include "sokol_gfx.h"

namespace fa::editor::ui {

namespace {

// The app of the frontmost ordinary window that is not an autotest's: the one the person at the computer is using.
NSRunningApplication* app_in_front() {
    NSString* me = NSProcessInfo.processInfo.processName;
    const CGWindowListOption onScreen = kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements;
    CFArrayRef windows = CGWindowListCopyWindowInfo(onScreen, kCGNullWindowID);
    if (!windows) return nil;
    NSRunningApplication* app = nil;
    for (NSDictionary* w in (__bridge NSArray*)windows) {  // front to back
        // Not the menu bar, the Dock or a floating window (the autotests'), nor a window of this or another autotest
        // (ctest runs several at once).
        if ([w[(__bridge id)kCGWindowLayer] intValue] != 0) continue;
        if ([w[(__bridge id)kCGWindowOwnerName] isEqualToString:me]) continue;
        const pid_t pid = [w[(__bridge id)kCGWindowOwnerPID] intValue];
        if ((app = [NSRunningApplication runningApplicationWithProcessIdentifier:pid])) break;
    }
    CFRelease(windows);
    return app;
}

void give_keyboard_back() {
    if (!NSApp.active) return;
    if (NSRunningApplication* app = app_in_front()) [app activateWithOptions:0];
    else [NSApp deactivate];
}

}  // namespace

void metal_make_window_readable(bool show) {
    // sokol_app creates the layer framebuffer-only (drawables can only be render targets); a blit needs them readable.
    // Drawables created from now on are; the current one may not be yet.
    NSWindow* window = (__bridge NSWindow*)sapp_macos_get_window();
    CALayer* layer = window.contentView.layer;
    if ([layer isKindOfClass:[CAMetalLayer class]]) ((CAMetalLayer*)layer).framebufferOnly = NO;
    // macOS gives a window that other windows cover completely no drawable, so nothing to read: above them, it gets one.
    window.level = NSFloatingWindowLevel;
    if (show) return;
    // Above the others, so out of the way of whoever uses the computer meanwhile: see-through (the drawables keep
    // their pixels, only the compositing skips them), clicks reach the windows below, no Dock icon, and the keyboard
    // goes back to the app in front. sokol_app activates the app when it opens the window, maybe after this: so on
    // every activation.
    window.alphaValue = 0;
    window.hasShadow = NO;
    window.ignoresMouseEvents = YES;
    NSApp.activationPolicy = NSApplicationActivationPolicyAccessory;
    [NSNotificationCenter.defaultCenter addObserverForName:NSApplicationDidBecomeActiveNotification
                                                    object:nil
                                                     queue:nil
                                                usingBlock:^(NSNotification*) { give_keyboard_back(); }];
    give_keyboard_back();
}

bool metal_read_drawable(const void* drawablePtr, int w, int h, std::uint8_t* out) {
    id<CAMetalDrawable> drawable = (__bridge id<CAMetalDrawable>)drawablePtr;
    id<MTLCommandQueue> queue = (__bridge id<MTLCommandQueue>)sg_mtl_command_queue();
    if (!drawable || !queue) return false;
    id<MTLTexture> tex = drawable.texture;
    if (!tex || tex.framebufferOnly || int(tex.width) != w || int(tex.height) != h) return false;
    const MTLPixelFormat fmt = tex.pixelFormat;
    const bool bgra = fmt == MTLPixelFormatBGRA8Unorm || fmt == MTLPixelFormatBGRA8Unorm_sRGB;
    if (!bgra && fmt != MTLPixelFormatRGBA8Unorm && fmt != MTLPixelFormatRGBA8Unorm_sRGB) return false;

    // Called after sg_commit(): this command buffer runs after the frame's on the same queue, and the drawable (presented
    // by then) keeps its pixels while the autorelease pool of the frame callback holds it.
    const NSUInteger bytesPerRow = NSUInteger(w) * 4;
    id<MTLBuffer> buf = [queue.device newBufferWithLength:bytesPerRow * NSUInteger(h) options:MTLResourceStorageModeShared];
    id<MTLCommandBuffer> cmd = [queue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [cmd blitCommandEncoder];
    [blit copyFromTexture:tex sourceSlice:0 sourceLevel:0 sourceOrigin:MTLOriginMake(0, 0, 0)
               sourceSize:MTLSizeMake(NSUInteger(w), NSUInteger(h), 1) toBuffer:buf destinationOffset:0
        destinationBytesPerRow:bytesPerRow destinationBytesPerImage:bytesPerRow * NSUInteger(h)];
    [blit endEncoding];
    [cmd commit];
    [cmd waitUntilCompleted];
    if (cmd.status != MTLCommandBufferStatusCompleted) return false;

    std::memcpy(out, [buf contents], size_t(bytesPerRow) * size_t(h));  // Metal rows are top-down
    if (bgra)
        for (size_t i = 0; i < size_t(w) * size_t(h) * 4; i += 4) std::swap(out[i], out[i + 2]);
    return true;
}

}  // namespace fa::editor::ui
