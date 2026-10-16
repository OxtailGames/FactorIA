// The ONE translation unit that contains the sokol implementations for every
// non-Apple platform (Apple uses sokol_impl_apple.m). Other modules include the
// sokol headers without SOKOL_IMPL.
//
// The graphics backend macro (SOKOL_GLCORE / SOKOL_D3D11 / SOKOL_GLES3) comes
// from the fa_ext_sokol interface target.
#if !defined(__APPLE__)

#define SOKOL_IMPL

// Desktop: we own main() and call sapp_run() from fa::run_app(). On Android
// (and iOS, see the .m file) sokol_app provides the entry point and the game
// supplies sokol_main() (see fa/platform/sokol_entry.h and player/).
#if !defined(__ANDROID__)
#define SOKOL_NO_ENTRY
#endif

// Android: sokol_app's NativeActivity entry point gets another name here and is wrapped at the end of this file.
#if defined(__ANDROID__)
#define ANativeActivity_onCreate fa_sokol_ANativeActivity_onCreate
#endif
#include "sokol_app.h"
#if defined(__ANDROID__)
#undef ANativeActivity_onCreate
#endif

#if defined(__ANDROID__)
// The OpenGL ES version sokol_gfx sees.
//
// sokol_gfx reads the version with glGetIntegerv(GL_MAJOR_VERSION / GL_MINOR_VERSION) and turns on the ES 3.1
// features from it (compute, storage buffers), whose limits sg_setup() then queries. The player asks for a 3.0 context
// (to_sapp_desc in app.cpp). The Android emulator's GL stack (gfxstream) answers those two queries with the highest
// version of its GPU (3.1 with -gpu swiftshader_indirect) but rejects every ES 3.1 query on a 3.0 context with
// GL_INVALID_ENUM, so sg_setup() hit an error (a Debug build aborts: "_sg_gl_init_limits: assertion glGetError() == 0
// failed"). sokol_gfx is told the version the player asked for whenever the driver reports a newer one: the engine uses
// no ES 3.1 feature, and every device then runs the same sokol_gfx code.
#include <GLES3/gl3.h>

static void fa_gl_get_integerv(GLenum pname, GLint* data) {
    glGetIntegerv(pname, data);
    if (pname != GL_MAJOR_VERSION && pname != GL_MINOR_VERSION) return;
    GLint major = 0, minor = 0;
    glGetIntegerv(GL_MAJOR_VERSION, &major);
    glGetIntegerv(GL_MINOR_VERSION, &minor);
    const int asked_major = sapp_gl_get_major_version(), asked_minor = sapp_gl_get_minor_version();
    if (major > asked_major || (major == asked_major && minor > asked_minor)) {
        *data = pname == GL_MAJOR_VERSION ? asked_major : asked_minor;
    }
}
#define glGetIntegerv fa_gl_get_integerv
#endif
#include "sokol_gfx.h"
#if defined(__ANDROID__)
#undef glGetIntegerv
#endif
#include "sokol_glue.h"
#include "sokol_log.h"
#include "sokol_time.h"
// No audio device library available at build time: sokol_audio becomes a dummy
// backend. (SOKOL_DUMMY_BACKEND is shared with sokol_gfx, so it is only defined
// here, after every other header has been processed.)
#if defined(FA_NO_AUDIO_DEVICE)
#define SOKOL_DUMMY_BACKEND
#endif
#include "sokol_audio.h"

// ---- window operations sokol_app has no API for (sokol_window.h) ----------------------------------------------------------
// They read and change sokol_app's private state, so they must live in this translation unit. Sizes are logical pixels:
// what the window system calls the client size before the display scale (Windows: dpi / 96, X11: Xft dpi / 96).
#include "sokol_window.h"

void fa_sapp_window_size(int* w, int* h) {
    *w = _sapp.window_width;
    *h = _sapp.window_height;
}

bool fa_sapp_display_size(int* w, int* h) {
#if defined(_SAPP_WIN32)
    MONITORINFO info;
    memset(&info, 0, sizeof(info));
    info.cbSize = sizeof(info);
    if (!GetMonitorInfo(MonitorFromWindow(_sapp.win32.hwnd, MONITOR_DEFAULTTONEAREST), &info)) return false;
    *w = (int)((info.rcMonitor.right - info.rcMonitor.left) / _sapp.win32.dpi.window_scale + 0.5f);
    *h = (int)((info.rcMonitor.bottom - info.rcMonitor.top) / _sapp.win32.dpi.window_scale + 0.5f);
    return true;
#elif defined(_SAPP_LINUX)
    // The whole X screen: with several monitors it spans all of them (no XRandR here).
    const float scale = _sapp.x11.dpi / 96.0f;
    *w = (int)(DisplayWidth(_sapp.x11.display, _sapp.x11.screen) / scale + 0.5f);
    *h = (int)(DisplayHeight(_sapp.x11.display, _sapp.x11.screen) / scale + 0.5f);
    return true;
#else
    (void)w;
    (void)h;
    return false;
#endif
}

bool fa_sapp_set_window_size(int w, int h) {
#if defined(_SAPP_WIN32)
    const float scale = _sapp.win32.dpi.window_scale;
    RECT rect = {0, 0, (LONG)(w * scale + 0.5f), (LONG)(h * scale + 0.5f)};
    AdjustWindowRectEx(&rect, (DWORD)GetWindowLongPtr(_sapp.win32.hwnd, GWL_STYLE), FALSE,
                       (DWORD)GetWindowLongPtr(_sapp.win32.hwnd, GWL_EXSTYLE));
    if (IsZoomed(_sapp.win32.hwnd)) ShowWindow(_sapp.win32.hwnd, SW_RESTORE);
    SetWindowPos(_sapp.win32.hwnd, NULL, 0, 0, rect.right - rect.left, rect.bottom - rect.top,
                 SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
    return true;
#elif defined(_SAPP_LINUX)
    const float scale = _sapp.x11.dpi / 96.0f;
    XResizeWindow(_sapp.x11.display, _sapp.x11.window, (unsigned)(w * scale + 0.5f), (unsigned)(h * scale + 0.5f));
    XFlush(_sapp.x11.display);
    return true;
#else
    (void)w;
    (void)h;
    return false;
#endif
}

bool fa_sapp_set_vsync(bool on) {
#if defined(SOKOL_D3D11)
    // _sapp_d3d11_present() reads disable_vsync at every present (Windows 10 and later).
    if (!_sapp.win32.is_win10_or_greater) return false;
    _sapp.desc.disable_vsync = !on;
    return true;
#elif defined(_SAPP_GLX)
    if (!_sapp.glx.EXT_swap_control && !_sapp.glx.MESA_swap_control) return false;  // the driver offers no swap control
    _sapp_glx_swapinterval(on ? 1 : 0);
    _sapp.desc.disable_vsync = !on;
    return true;
#else
    (void)on;
    return false;
#endif
}

#if defined(__ANDROID__)
// Ending the process when the activity is destroyed.
//
// sokol_app's onDestroy stops its loop thread and then calls exit(0), so that the next activity starts in a fresh
// process. exit() runs the C++ static destructors while other threads still run: the engine, owned by static
// AppDescs, shuts down on the main thread with no GL context ("call to OpenGL ES API with no current context"), the
// logger's mutex is destroyed while the loop thread still logs "loop thread done", and bionic aborts the process
// ("FORTIFY: pthread_mutex_lock called on a destroyed mutex", SIGABRT). Android destroys the activity when the game
// is closed and on every relaunch the manifest cannot opt out of (an assets-path change: wallpaper colours or theme
// on Android 12+, an overlay; see AndroidManifest.xml). So the entry point below wraps sokol_app's and turns that
// exit(0) into _exit(0): the process ends at once, nothing is torn down under a running thread.
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void (*fa_sokol_on_destroy)(ANativeActivity* activity);

static void fa_exit_now(void) {
    fflush(NULL);  // what exit() would still do for stdio
    _exit(0);
}

static void fa_on_destroy(ANativeActivity* activity) {
    // Registered after every static object was constructed, so exit() calls it before any static destructor.
    atexit(fa_exit_now);
    fa_sokol_on_destroy(activity);  // sokol: stop the loop thread, close the pipe, exit(0)
}

// The symbol NativeActivity looks up (player/CMakeLists.txt keeps it with -u ANativeActivity_onCreate).
JNIEXPORT void ANativeActivity_onCreate(ANativeActivity* activity, void* saved_state, size_t saved_state_size) {
    fa_sokol_ANativeActivity_onCreate(activity, saved_state, saved_state_size);
    if (activity->callbacks->onDestroy && activity->callbacks->onDestroy != fa_on_destroy) {  // unset if sokol failed
        fa_sokol_on_destroy = activity->callbacks->onDestroy;
        activity->callbacks->onDestroy = fa_on_destroy;
    }
}
#endif  // __ANDROID__

#endif  // !__APPLE__
