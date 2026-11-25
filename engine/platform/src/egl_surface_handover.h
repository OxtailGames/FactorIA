// The OpenGL ES surface of sokol_app's Android window, off the window while a GPU device presents there (M77-P9e3b,
// sokol_window.h fa_sapp_gl_surface_release; docs/design/ARCHITECTURE_RENDERING_GPU.md, "The OpenGL surface leaves an
// Android window").
//
// sokol_app makes one EGL context and an EGL window surface on the activity's ANativeWindow, makes a new window surface
// for every new ANativeWindow (the app backgrounded and resumed), swaps it after every frame and asks its size every
// frame. A Vulkan swapchain cannot share the window with an EGL window surface (both connect to it as its producer). So
// while a device holds the window, sokol_app holds a stand-in in place of its window surface: a 1x1 pbuffer of its
// EGLConfig or, where that config makes none, a token for "no drawable" (EGL_KHR_surfaceless_context). sokol_impl.c
// renames sokol_app's EGL calls to the wrappers below, so that while released
//   * a swap of the stand-in shows nothing (the device presents), a size query of it answers the window's size,
//   * a new ANativeWindow gets a new stand-in in place of a window surface, and the listener learns the window,
//   * the destruction of the stand-in (the window is going) tells the listener first (window null), so the device
//     destroys its swapchain before Android's onNativeWindowDestroyed returns,
//   * a make-current of the token makes the context current with no surface.
// Outside a release every wrapper calls the real function unchanged.
//
// Pure logic over the EGL calls of fa_egl_surface_ops (EGL handles as void*: EGLDisplay, EGLConfig, EGLContext and
// EGLSurface are pointers, EGL_NO_* are null), so the tests drive it with a fake EGL on every host
// (tests/egl_surface_handover_tests.cpp). Every call runs on sokol_app's loop thread: no locks.
#pragma once

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// EGL_WIDTH and EGL_HEIGHT (EGL/egl.h; sokol_impl.c checks that they match).
#define FA_EGL_WIDTH 0x3057
#define FA_EGL_HEIGHT 0x3056

typedef struct fa_egl_surface_ops {
    void* user;
    // A 1x1 pbuffer of `config`; null when the config makes no pbuffers or the driver refuses one.
    void* (*create_pbuffer)(void* user, void* display, void* config);
    // Whether a context of `display` may be current with no surface (EGL_KHR_surfaceless_context).
    bool (*surfaceless)(void* user, void* display);
    // The real eglCreateWindowSurface, eglDestroySurface, eglMakeCurrent, eglSwapBuffers and eglQuerySurface.
    void* (*create_window_surface)(void* user, void* display, void* config, void* window, const int* attribs);
    bool (*destroy_surface)(void* user, void* display, void* surface);
    bool (*make_current)(void* user, void* display, void* draw, void* read, void* context);
    bool (*swap_buffers)(void* user, void* display, void* surface);
    bool (*query_surface)(void* user, void* display, void* surface, int attribute, int* value);
    // The window's buffer size in pixels (ANativeWindow_getWidth / _getHeight).
    void (*window_size)(void* user, void* window, int* width, int* height);
    // glFinish: what the context still draws into the window is done before its surface goes.
    void (*finish)(void* user);
} fa_egl_surface_ops;

// The device's window, as the listener hears it: the new ANativeWindow, or null when the window is going.
typedef void (*fa_egl_window_listener)(void* window, void* user);

typedef struct fa_egl_surface_handover {
    const fa_egl_surface_ops* ops;
    int state;       // fa_sapp_gl_surface_state: 0 on the window (sokol_app's own state), 1 a pbuffer, 2 no drawable
    void* stand_in;  // what sokol_app holds as its surface while released; null while the activity has no window
    void* window;    // the ANativeWindow the device presents into; null while the activity has none
    fa_egl_window_listener listener;
    void* listener_user;
} fa_egl_surface_handover;

// Release: the context becomes current on a stand-in of `config` (a pbuffer, else no drawable), `*surface` (sokol_app's
// window surface on `window`) is destroyed and replaced with the stand-in. true: released (or it already was); with no
// drawable `err` says why there is no pbuffer. false: nothing changed, `err` (errLen bytes, NUL-terminated) says why.
bool fa_egl_handover_release(fa_egl_surface_handover* h, void* display, void* config, void* context, void* window,
                             void** surface, char* err, size_t errLen);
// Restore: a new window surface on the device's window (attribs as sokol_app passes them), current, the stand-in
// destroyed, `*surface` the new one. While the activity has no window there is nothing to make: the next window gets
// sokol_app's own surface. true: on the window again (or it never left). false: the driver refused (`err`); the context
// stays on the stand-in.
bool fa_egl_handover_restore(fa_egl_surface_handover* h, void* display, void* config, void* context, const int* attribs,
                             void** surface, char* err, size_t errLen);
void fa_egl_handover_set_listener(fa_egl_surface_handover* h, fa_egl_window_listener listener, void* user);

// The wrappers sokol_app's EGL calls go through (sokol_impl.c).
void* fa_egl_handover_create_window_surface(fa_egl_surface_handover* h, void* display, void* config, void* window,
                                            const int* attribs);
bool fa_egl_handover_destroy_surface(fa_egl_surface_handover* h, void* display, void* surface);
bool fa_egl_handover_make_current(fa_egl_surface_handover* h, void* display, void* draw, void* read, void* context);
bool fa_egl_handover_swap_buffers(fa_egl_surface_handover* h, void* display, void* surface);
bool fa_egl_handover_query_surface(fa_egl_surface_handover* h, void* display, void* surface, int attribute, int* value);

#ifdef __cplusplus
}
#endif
