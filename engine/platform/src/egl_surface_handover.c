// sokol_app's Android EGL surface off the window while a GPU device presents there (egl_surface_handover.h).
#include "egl_surface_handover.h"

#include <stdio.h>

// The stand-in for "no drawable": an address no EGL surface has. sokol_app only compares its surface with
// EGL_NO_SURFACE and passes it back to EGL, where the wrappers turn it into EGL_NO_SURFACE.
static char fa_egl_no_drawable;

static void fa_egl_say(char* err, size_t errLen, const char* text) {
    if (errLen > 0) snprintf(err, errLen, "%s", text);
}

static bool fa_egl_is_stand_in(const fa_egl_surface_handover* h, void* surface) {
    return h->state != 0 && surface != NULL && surface == h->stand_in;
}

// What EGL gets for `surface`: EGL_NO_SURFACE for the token, the surface itself otherwise.
static void* fa_egl_real(void* surface) { return surface == (void*)&fa_egl_no_drawable ? NULL : surface; }

// A stand-in for `config`: a pbuffer (kind 1), else the token (kind 2) where the context may be current with no
// surface. Null when neither.
static void* fa_egl_make_stand_in(const fa_egl_surface_handover* h, void* display, void* config, int* kind) {
    const fa_egl_surface_ops* ops = h->ops;
    void* pbuffer = ops->create_pbuffer(ops->user, display, config);
    if (pbuffer) {
        *kind = 1;
        return pbuffer;
    }
    if (ops->surfaceless(ops->user, display)) {
        *kind = 2;
        return (void*)&fa_egl_no_drawable;
    }
    *kind = 0;
    return NULL;
}

static void fa_egl_drop_stand_in(const fa_egl_surface_handover* h, void* display, void* stand_in) {
    if (stand_in && stand_in != (void*)&fa_egl_no_drawable) h->ops->destroy_surface(h->ops->user, display, stand_in);
}

bool fa_egl_handover_release(fa_egl_surface_handover* h, void* display, void* config, void* context, void* window,
                             void** surface, char* err, size_t errLen) {
    if (errLen > 0) err[0] = 0;
    if (h->state != 0) return true;
    const fa_egl_surface_ops* ops = h->ops;
    if (!display || !context || !window || !*surface) {
        fa_egl_say(err, errLen, "sokol_app has no OpenGL ES surface on a window yet (no window)");
        return false;
    }
    ops->finish(ops->user);
    int kind = 0;
    void* stand_in = fa_egl_make_stand_in(h, display, config, &kind);
    if (!stand_in) {
        fa_egl_say(err, errLen,
                   "the OpenGL ES context sokol_app made on the window cannot leave it (this EGL makes no pbuffer of "
                   "the window's EGLConfig and has no EGL_KHR_surfaceless_context), so a Vulkan swapchain cannot be "
                   "made there (hint: leave render.backend on auto on this device)");
        return false;
    }
    void* real = fa_egl_real(stand_in);
    if (!ops->make_current(ops->user, display, real, real, context)) {
        fa_egl_drop_stand_in(h, display, stand_in);
        // A failed eglMakeCurrent keeps the old binding; said again so the window surface is surely current.
        (void)ops->make_current(ops->user, display, *surface, *surface, context);
        fa_egl_say(err, errLen,
                   kind == 1
                       ? "eglMakeCurrent on a 1x1 pbuffer failed, so the OpenGL ES context stays on the window "
                         "and a Vulkan swapchain cannot be made there (hint: leave render.backend on auto on "
                         "this device)"
                       : "eglMakeCurrent with no surface failed, so the OpenGL ES context stays on the window and "
                         "a Vulkan swapchain cannot be made there (hint: leave render.backend on auto on this "
                         "device)");
        return false;
    }
    // Not current any more: destroyed at once, and the ANativeWindow is free for another producer.
    (void)ops->destroy_surface(ops->user, display, *surface);
    *surface = stand_in;
    h->stand_in = stand_in;
    h->window = window;
    h->state = kind;
    if (kind == 2) fa_egl_say(err, errLen, "this EGL makes no pbuffer of the window's EGLConfig");
    return true;
}

bool fa_egl_handover_restore(fa_egl_surface_handover* h, void* display, void* config, void* context, const int* attribs,
                             void** surface, char* err, size_t errLen) {
    if (errLen > 0) err[0] = 0;
    if (h->state == 0) return true;
    const fa_egl_surface_ops* ops = h->ops;
    if (!h->stand_in || !h->window) {
        // The window went while the device had it: sokol_app makes its own surface on the next one.
        h->state = 0;
        h->stand_in = NULL;
        h->window = NULL;
        return true;
    }
    void* made = ops->create_window_surface(ops->user, display, config, h->window, attribs);
    if (!made) {
        fa_egl_say(err, errLen,
                   "eglCreateWindowSurface on the window failed: the OpenGL ES context stays off the window and its "
                   "frames are not shown (hint: leave render.backend on auto on this device)");
        return false;
    }
    if (!ops->make_current(ops->user, display, made, made, context)) {
        (void)ops->destroy_surface(ops->user, display, made);
        fa_egl_say(err, errLen,
                   "eglMakeCurrent on the new window surface failed: the OpenGL ES context stays off the window and "
                   "its frames are not shown (hint: leave render.backend on auto on this device)");
        return false;
    }
    fa_egl_drop_stand_in(h, display, h->stand_in);
    *surface = made;
    h->state = 0;
    h->stand_in = NULL;
    h->window = NULL;
    return true;
}

void fa_egl_handover_set_listener(fa_egl_surface_handover* h, fa_egl_window_listener listener, void* user) {
    h->listener = listener;
    h->listener_user = user;
}

void* fa_egl_handover_create_window_surface(fa_egl_surface_handover* h, void* display, void* config, void* window,
                                            const int* attribs) {
    const fa_egl_surface_ops* ops = h->ops;
    if (h->state == 0) return ops->create_window_surface(ops->user, display, config, window, attribs);
    // A new window while the device holds it (the activity came back): a stand-in again, and the device's swapchain
    // goes on the window. A stand-in of the old window still held (sokol_app destroys it first) is dropped.
    if (h->stand_in) fa_egl_drop_stand_in(h, display, h->stand_in);
    if (!h->listener) {
        // No device hears the window (it let go, and the restore failed so the state stayed): nothing to hand over, the
        // window gets sokol_app's own surface again.
        h->state = 0;
        h->stand_in = NULL;
        h->window = NULL;
        return ops->create_window_surface(ops->user, display, config, window, attribs);
    }
    int kind = 0;
    void* stand_in = fa_egl_make_stand_in(h, display, config, &kind);
    h->stand_in = stand_in;
    h->window = stand_in ? window : NULL;
    if (!stand_in) return NULL;  // sokol_app ends the activity, as for a window surface the driver refuses
    h->state = kind;
    if (h->listener) h->listener(window, h->listener_user);
    return stand_in;
}

bool fa_egl_handover_destroy_surface(fa_egl_surface_handover* h, void* display, void* surface) {
    const fa_egl_surface_ops* ops = h->ops;
    if (!fa_egl_is_stand_in(h, surface)) return ops->destroy_surface(ops->user, display, surface);
    // The window is going: the device's swapchain goes first, while the window still exists.
    if (h->listener) h->listener(NULL, h->listener_user);
    fa_egl_drop_stand_in(h, display, surface);
    h->stand_in = NULL;
    h->window = NULL;
    return true;
}

bool fa_egl_handover_make_current(fa_egl_surface_handover* h, void* display, void* draw, void* read, void* context) {
    return h->ops->make_current(h->ops->user, display, fa_egl_real(draw), fa_egl_real(read), context);
}

bool fa_egl_handover_swap_buffers(fa_egl_surface_handover* h, void* display, void* surface) {
    if (fa_egl_is_stand_in(h, surface)) return true;  // nothing to show: the device presents into the window
    return h->ops->swap_buffers(h->ops->user, display, surface);
}

bool fa_egl_handover_query_surface(fa_egl_surface_handover* h, void* display, void* surface, int attribute,
                                   int* value) {
    const fa_egl_surface_ops* ops = h->ops;
    if (!fa_egl_is_stand_in(h, surface)) return ops->query_surface(ops->user, display, surface, attribute, value);
    if ((attribute == FA_EGL_WIDTH || attribute == FA_EGL_HEIGHT) && h->window) {
        // sokol_app's framebuffer size is the window's, as its window surface would have answered.
        int width = 0, height = 0;
        ops->window_size(ops->user, h->window, &width, &height);
        *value = attribute == FA_EGL_WIDTH ? width : height;
        return true;
    }
    if (surface == (void*)&fa_egl_no_drawable) return false;  // no surface: no other attribute to read
    return ops->query_surface(ops->user, display, surface, attribute, value);
}
