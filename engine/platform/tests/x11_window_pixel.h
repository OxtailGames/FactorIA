// Tests that run in a real X11 window (Linux, under xvfb): the colour the X server holds for one pixel of the game
// window. Shared by tests/gl_surface_handover_tests_linux.cpp and the runtime's tests/windowed_vulkan_tests_linux.cpp.
// Include it AFTER every engine header of the test file: Xlib's macros (None, Bool, Status...) would rename the
// engine's identifiers (this header undefines None, which is WindowPresenter's here).
#pragma once

#include <cstdint>

#include "fa/platform/app.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#undef None

namespace fa::test {

// The colour of the window's pixel (x, y) as 0-255 channels: what the last present put there, whichever API presented
// it.
// False: no window, or the server refused the read (an X error, trapped: Xlib's default handler would end the process).
inline bool x11_window_pixel(int x, int y, unsigned& r, unsigned& g, unsigned& b) {
    static int xError = 0;
    const NativeWindow h = app_native_window();
    if (!h.window || !h.display) return false;
    Display* display = static_cast<Display*>(const_cast<void*>(h.display));
    const Window window = static_cast<Window>(reinterpret_cast<std::uintptr_t>(h.window));
    XSync(display, False);
    xError = 0;
    const XErrorHandler previous = XSetErrorHandler([](Display*, XErrorEvent* e) {
        xError = e->error_code;
        return 0;
    });
    XImage* image = XGetImage(display, window, x, y, 1, 1, AllPlanes, ZPixmap);
    XSync(display, False);
    XSetErrorHandler(previous);
    if (!image) return false;
    const unsigned long pixel = XGetPixel(image, 0, 0);
    auto channel = [pixel](unsigned long mask) -> unsigned {
        if (mask == 0) return 0;
        int shift = 0;
        while (((mask >> shift) & 1UL) == 0) ++shift;
        const unsigned long max = mask >> shift;
        return static_cast<unsigned>(((pixel & mask) >> shift) * 255UL / max);
    };
    r = channel(image->red_mask);
    g = channel(image->green_mask);
    b = channel(image->blue_mask);
    XDestroyImage(image);
    return xError == 0;
}

}  // namespace fa::test
