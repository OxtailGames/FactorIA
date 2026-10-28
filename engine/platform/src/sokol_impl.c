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

// ---- monitors -----------------------------------------------------------------------------------------------------------
#include <stdio.h>
#if defined(_SAPP_WIN32)
typedef struct { HMONITOR h; RECT r; bool primary; char name[64]; } fa_win_mon;
typedef struct { fa_win_mon m[16]; int n; } fa_win_mons;

static BOOL CALLBACK fa_win_enum(HMONITOR h, HDC dc, LPRECT r, LPARAM param) {
    (void)dc;
    (void)r;
    fa_win_mons* list = (fa_win_mons*)param;
    if (list->n >= 16) return FALSE;
    MONITORINFOEXA info;
    memset(&info, 0, sizeof(info));
    info.cbSize = sizeof(info);
    if (!GetMonitorInfoA(h, (MONITORINFO*)&info)) return TRUE;
    fa_win_mon* m = &list->m[list->n++];
    m->h = h;
    m->r = info.rcMonitor;
    m->primary = (info.dwFlags & MONITORINFOF_PRIMARY) != 0;
    DISPLAY_DEVICEA dd;
    memset(&dd, 0, sizeof(dd));
    dd.cb = sizeof(dd);
    const char* label = info.szDevice;
    if (EnumDisplayDevicesA(info.szDevice, 0, &dd, 0) && dd.DeviceString[0]) label = dd.DeviceString;
    snprintf(m->name, sizeof(m->name), "%s", label);
    return TRUE;
}

// Primary first, then in the order Windows lists them.
static void fa_win_collect(fa_win_mons* list) {
    memset(list, 0, sizeof(*list));
    EnumDisplayMonitors(NULL, NULL, fa_win_enum, (LPARAM)list);
    for (int i = 1; i < list->n; i++) {
        if (list->m[i].primary) {
            fa_win_mon p = list->m[i];
            memmove(&list->m[1], &list->m[0], sizeof(fa_win_mon) * (size_t)i);
            list->m[0] = p;
            break;
        }
    }
}
#elif defined(_SAPP_LINUX)
// XRandR is loaded at run time, so a machine without libXrandr (or a build without its headers) still runs: it then has one
// monitor, the whole X screen. Layouts are the ones libXrandr documents (X11/extensions/Xrandr.h).
typedef struct { Time timestamp, configTimestamp; int ncrtc; XID* crtcs; int noutput; XID* outputs; int nmode; void* modes; } fa_xrr_resources;
typedef struct { Time timestamp; int x, y; unsigned int width, height; XID mode; unsigned short rotation; int noutput; XID* outputs;
                 unsigned short rotations; int npossible; XID* possible; } fa_xrr_crtc;
typedef struct { Time timestamp; XID crtc; char* name; int nameLen; unsigned long mm_width, mm_height; unsigned short connection;
                 unsigned short subpixel_order; int ncrtc; XID* crtcs; int nclone; XID* clones; int nmode; int npreferred;
                 XID* modes; } fa_xrr_output;

typedef struct {
    int x, y, w, h;  // physical pixels
    bool primary;
    char name[64];
} fa_x11_mon;

static void* fa_xrr_lib;
static fa_xrr_resources* (*fa_XRRGetScreenResourcesCurrent)(Display*, Window);
static fa_xrr_crtc* (*fa_XRRGetCrtcInfo)(Display*, fa_xrr_resources*, XID);
static fa_xrr_output* (*fa_XRRGetOutputInfo)(Display*, fa_xrr_resources*, XID);
static void (*fa_XRRFreeScreenResources)(fa_xrr_resources*);
static void (*fa_XRRFreeCrtcInfo)(fa_xrr_crtc*);
static void (*fa_XRRFreeOutputInfo)(fa_xrr_output*);
static XID (*fa_XRRGetOutputPrimary)(Display*, Window);

static bool fa_xrr_load(void) {
    static int state;  // 0 not tried, 1 loaded, -1 missing
    if (state) return state > 0;
    state = -1;
    fa_xrr_lib = dlopen("libXrandr.so.2", RTLD_LAZY);
    if (!fa_xrr_lib) return false;
    *(void**)&fa_XRRGetScreenResourcesCurrent = dlsym(fa_xrr_lib, "XRRGetScreenResourcesCurrent");
    *(void**)&fa_XRRGetCrtcInfo = dlsym(fa_xrr_lib, "XRRGetCrtcInfo");
    *(void**)&fa_XRRGetOutputInfo = dlsym(fa_xrr_lib, "XRRGetOutputInfo");
    *(void**)&fa_XRRFreeScreenResources = dlsym(fa_xrr_lib, "XRRFreeScreenResources");
    *(void**)&fa_XRRFreeCrtcInfo = dlsym(fa_xrr_lib, "XRRFreeCrtcInfo");
    *(void**)&fa_XRRFreeOutputInfo = dlsym(fa_xrr_lib, "XRRFreeOutputInfo");
    *(void**)&fa_XRRGetOutputPrimary = dlsym(fa_xrr_lib, "XRRGetOutputPrimary");
    if (!fa_XRRGetScreenResourcesCurrent || !fa_XRRGetCrtcInfo || !fa_XRRGetOutputInfo || !fa_XRRFreeScreenResources ||
        !fa_XRRFreeCrtcInfo || !fa_XRRFreeOutputInfo || !fa_XRRGetOutputPrimary) return false;
    state = 1;
    return true;
}

// Connected outputs that show something, primary first. Returns the count (at least 1: the whole screen without XRandR).
static int fa_x11_collect(fa_x11_mon* out, int max) {
    int n = 0;
    if (fa_xrr_load()) {
        fa_xrr_resources* res = fa_XRRGetScreenResourcesCurrent(_sapp.x11.display, _sapp.x11.root);
        if (res) {
            const XID primary = fa_XRRGetOutputPrimary(_sapp.x11.display, _sapp.x11.root);
            for (int i = 0; i < res->noutput && n < max; i++) {
                fa_xrr_output* o = fa_XRRGetOutputInfo(_sapp.x11.display, res, res->outputs[i]);
                if (!o) continue;
                if (o->connection == 0 /* RR_Connected */ && o->crtc) {
                    fa_xrr_crtc* c = fa_XRRGetCrtcInfo(_sapp.x11.display, res, o->crtc);
                    if (c && c->width > 0 && c->height > 0) {
                        fa_x11_mon* m = &out[n++];
                        m->x = c->x;
                        m->y = c->y;
                        m->w = (int)c->width;
                        m->h = (int)c->height;
                        m->primary = res->outputs[i] == primary;
                        snprintf(m->name, sizeof(m->name), "%s", o->name ? o->name : "Display");
                    }
                    if (c) fa_XRRFreeCrtcInfo(c);
                }
                fa_XRRFreeOutputInfo(o);
            }
            fa_XRRFreeScreenResources(res);
        }
    }
    if (n == 0) {
        out[0].x = 0;
        out[0].y = 0;
        out[0].w = DisplayWidth(_sapp.x11.display, _sapp.x11.screen);
        out[0].h = DisplayHeight(_sapp.x11.display, _sapp.x11.screen);
        out[0].primary = true;
        snprintf(out[0].name, sizeof(out[0].name), "Display");
        return 1;
    }
    bool any_primary = false;
    for (int i = 0; i < n; i++) any_primary = any_primary || out[i].primary;
    if (!any_primary) out[0].primary = true;
    for (int i = 1; i < n; i++) {
        if (out[i].primary) {
            fa_x11_mon p = out[i];
            memmove(&out[1], &out[0], sizeof(fa_x11_mon) * (size_t)i);
            out[0] = p;
            break;
        }
    }
    return n;
}

// The window's centre in root coordinates (physical pixels).
static void fa_x11_window_centre(int* cx, int* cy) {
    XWindowAttributes a;
    Window child;
    int rx = 0, ry = 0;
    XGetWindowAttributes(_sapp.x11.display, _sapp.x11.window, &a);
    XTranslateCoordinates(_sapp.x11.display, _sapp.x11.window, _sapp.x11.root, 0, 0, &rx, &ry, &child);
    *cx = rx + a.width / 2;
    *cy = ry + a.height / 2;
}
#endif

int fa_sapp_monitors(fa_sapp_monitor* out, int max) {
    if (max <= 0) return 0;
#if defined(_SAPP_WIN32)
    fa_win_mons list;
    fa_win_collect(&list);
    const float scale = _sapp.win32.dpi.window_scale;
    const HMONITOR here = MonitorFromWindow(_sapp.win32.hwnd, MONITOR_DEFAULTTONEAREST);
    int n = 0;
    for (; n < list.n && n < max; n++) {
        const fa_win_mon* m = &list.m[n];
        memcpy(out[n].name, m->name, sizeof(out[n].name));
        out[n].x = (int)(m->r.left / scale);
        out[n].y = (int)(m->r.top / scale);
        out[n].w = (int)((m->r.right - m->r.left) / scale + 0.5f);
        out[n].h = (int)((m->r.bottom - m->r.top) / scale + 0.5f);
        out[n].primary = m->primary;
        out[n].current = m->h == here;
    }
    return n;
#elif defined(_SAPP_LINUX)
    fa_x11_mon list[16];
    const int count = fa_x11_collect(list, 16);
    const float scale = _sapp.x11.dpi / 96.0f;
    int cx, cy;
    fa_x11_window_centre(&cx, &cy);
    int current = 0;
    for (int i = 0; i < count; i++) {
        if (cx >= list[i].x && cx < list[i].x + list[i].w && cy >= list[i].y && cy < list[i].y + list[i].h) current = i;
    }
    int n = 0;
    for (; n < count && n < max; n++) {
        memcpy(out[n].name, list[n].name, sizeof(out[n].name));
        out[n].x = (int)(list[n].x / scale);
        out[n].y = (int)(list[n].y / scale);
        out[n].w = (int)(list[n].w / scale + 0.5f);
        out[n].h = (int)(list[n].h / scale + 0.5f);
        out[n].primary = list[n].primary;
        out[n].current = n == current;
    }
    return n;
#else
    return 0;
#endif
}

bool fa_sapp_move_to_monitor(int index) {
#if defined(_SAPP_WIN32)
    fa_win_mons list;
    fa_win_collect(&list);
    if (index < 0 || index >= list.n) return false;
    const RECT r = list.m[index].r;
    HWND hwnd = _sapp.win32.hwnd;
    if (_sapp.fullscreen) {
        // sokol's full screen window is a WS_POPUP: it only has to cover the other monitor.
        SetWindowPos(hwnd, HWND_TOP, r.left, r.top, r.right - r.left, r.bottom - r.top, SWP_NOACTIVATE | SWP_FRAMECHANGED);
    } else {
        if (IsZoomed(hwnd)) ShowWindow(hwnd, SW_RESTORE);
        RECT w;
        GetWindowRect(hwnd, &w);
        const int ww = w.right - w.left, wh = w.bottom - w.top;
        int x = r.left + ((r.right - r.left) - ww) / 2, y = r.top + ((r.bottom - r.top) - wh) / 2;
        if (x < r.left) x = r.left;
        if (y < r.top) y = r.top;
        SetWindowPos(hwnd, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
    }
    return true;
#elif defined(_SAPP_LINUX)
    fa_x11_mon list[16];
    const int count = fa_x11_collect(list, 16);
    if (index < 0 || index >= count) return false;
    if (_sapp.fullscreen) {
        // EWMH: the monitors a full screen window covers (indices of the Xinerama / RandR order).
        const Atom monitors = XInternAtom(_sapp.x11.display, "_NET_WM_FULLSCREEN_MONITORS", False);
        _sapp_x11_send_event(monitors, index, index, index, index, 1);
    } else {
        XWindowAttributes a;
        XGetWindowAttributes(_sapp.x11.display, _sapp.x11.window, &a);
        int x = list[index].x + (list[index].w - a.width) / 2, y = list[index].y + (list[index].h - a.height) / 2;
        if (x < list[index].x) x = list[index].x;
        if (y < list[index].y) y = list[index].y;
        XMoveWindow(_sapp.x11.display, _sapp.x11.window, x, y);
    }
    XFlush(_sapp.x11.display);
    return true;
#else
    (void)index;
    return false;
#endif
}

bool fa_sapp_set_borderless(bool on) {
    (void)on;
    return false;
}

bool fa_sapp_is_borderless(void) { return false; }

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

bool fa_sapp_set_dock_icon(const unsigned char* rgba, int w, int h) {
    (void)rgba;  // macOS only (sokol_impl_apple.m): Windows and Linux take the window icon from sapp_desc.icon
    (void)w;
    (void)h;
    return false;
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
