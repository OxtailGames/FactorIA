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
// Android: sokol_app's EGL window surface leaves the ANativeWindow while a GPU device presents there (M77-P9e3b,
// egl_surface_handover.h). sokol_app's EGL calls get wrappers: outside a release they are the real calls; while
// released its window surface is a stand-in (a 1x1 pbuffer or "no drawable"), a new ANativeWindow gets a stand-in and
// is told to the device, the window's loss is told to the device before the stand-in goes. EGL's headers come first, so
// their own declarations keep their names. Every call runs on sokol_app's loop thread (its frame thread too).
#if defined(__ANDROID__)
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES3/gl3.h>
#include <android/native_window.h>
#include <string.h>

#include "egl_surface_handover.h"
_Static_assert(EGL_WIDTH == FA_EGL_WIDTH && EGL_HEIGHT == FA_EGL_HEIGHT, "egl_surface_handover.h's EGL names");

static void* fa_egl_op_create_pbuffer(void* user, void* display, void* config) {
    (void)user;
    EGLint types = 0;
    if (!eglGetConfigAttrib((EGLDisplay)display, (EGLConfig)config, EGL_SURFACE_TYPE, &types)) return NULL;
    if (!(types & EGL_PBUFFER_BIT)) return NULL;
    const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
    const EGLSurface pbuffer = eglCreatePbufferSurface((EGLDisplay)display, (EGLConfig)config, attribs);
    return pbuffer == EGL_NO_SURFACE ? NULL : (void*)pbuffer;
}
static bool fa_egl_op_surfaceless(void* user, void* display) {
    (void)user;
    const char* extensions = eglQueryString((EGLDisplay)display, EGL_EXTENSIONS);
    return extensions && strstr(extensions, "EGL_KHR_surfaceless_context") != NULL;
}
static void* fa_egl_op_create_window_surface(void* user, void* display, void* config, void* window,
                                             const int* attribs) {
    (void)user;
    const EGLSurface s = eglCreateWindowSurface((EGLDisplay)display, (EGLConfig)config, (EGLNativeWindowType)window,
                                                (const EGLint*)attribs);
    return s == EGL_NO_SURFACE ? NULL : (void*)s;
}
static bool fa_egl_op_destroy_surface(void* user, void* display, void* surface) {
    (void)user;
    return eglDestroySurface((EGLDisplay)display, (EGLSurface)surface) == EGL_TRUE;
}
static bool fa_egl_op_make_current(void* user, void* display, void* draw, void* read, void* context) {
    (void)user;
    return eglMakeCurrent((EGLDisplay)display, (EGLSurface)draw, (EGLSurface)read, (EGLContext)context) == EGL_TRUE;
}
static bool fa_egl_op_swap_buffers(void* user, void* display, void* surface) {
    (void)user;
    return eglSwapBuffers((EGLDisplay)display, (EGLSurface)surface) == EGL_TRUE;
}
static bool fa_egl_op_query_surface(void* user, void* display, void* surface, int attribute, int* value) {
    (void)user;
    EGLint v = 0;
    const bool ok = eglQuerySurface((EGLDisplay)display, (EGLSurface)surface, attribute, &v) == EGL_TRUE;
    if (ok) *value = v;
    return ok;
}
static void fa_egl_op_window_size(void* user, void* window, int* width, int* height) {
    (void)user;
    *width = ANativeWindow_getWidth((ANativeWindow*)window);
    *height = ANativeWindow_getHeight((ANativeWindow*)window);
    if (*width < 0) *width = 0;  // a negative value is an error code
    if (*height < 0) *height = 0;
}
static void fa_egl_op_finish(void* user) {
    (void)user;
    glFinish();
}
static const fa_egl_surface_ops fa_egl_ops = {
    NULL,
    fa_egl_op_create_pbuffer,
    fa_egl_op_surfaceless,
    fa_egl_op_create_window_surface,
    fa_egl_op_destroy_surface,
    fa_egl_op_make_current,
    fa_egl_op_swap_buffers,
    fa_egl_op_query_surface,
    fa_egl_op_window_size,
    fa_egl_op_finish,
};
static fa_egl_surface_handover fa_egl = {&fa_egl_ops, 0, NULL, NULL, NULL, NULL};

static EGLSurface fa_egl_create_window_surface(EGLDisplay display, EGLConfig config, EGLNativeWindowType window,
                                               const EGLint* attribs) {
    void* s = fa_egl_handover_create_window_surface(&fa_egl, (void*)display, (void*)config, (void*)window,
                                                    (const int*)attribs);
    return s ? (EGLSurface)s : EGL_NO_SURFACE;
}
static EGLBoolean fa_egl_destroy_surface(EGLDisplay display, EGLSurface surface) {
    return fa_egl_handover_destroy_surface(&fa_egl, (void*)display, (void*)surface) ? EGL_TRUE : EGL_FALSE;
}
static EGLBoolean fa_egl_make_current(EGLDisplay display, EGLSurface draw, EGLSurface read, EGLContext context) {
    return fa_egl_handover_make_current(&fa_egl, (void*)display, (void*)draw, (void*)read, (void*)context) ? EGL_TRUE
                                                                                                           : EGL_FALSE;
}
static EGLBoolean fa_egl_swap_buffers(EGLDisplay display, EGLSurface surface) {
    return fa_egl_handover_swap_buffers(&fa_egl, (void*)display, (void*)surface) ? EGL_TRUE : EGL_FALSE;
}
static EGLBoolean fa_egl_query_surface(EGLDisplay display, EGLSurface surface, EGLint attribute, EGLint* value) {
    int v = 0;
    if (!fa_egl_handover_query_surface(&fa_egl, (void*)display, (void*)surface, (int)attribute, &v)) return EGL_FALSE;
    *value = (EGLint)v;
    return EGL_TRUE;
}
#define eglCreateWindowSurface fa_egl_create_window_surface
#define eglDestroySurface fa_egl_destroy_surface
#define eglMakeCurrent fa_egl_make_current
#define eglSwapBuffers fa_egl_swap_buffers
#define eglQuerySurface fa_egl_query_surface
#endif
// Linux: the IME backend (ime_linux.cpp) sees every X event before sokol_app does. sokol_app's loop reads the queue
// with XPending (once per frame) and XNextEvent (each event); here they get wrappers that call the real ones and then
// the backend, which may turn an event the input method took into one sokol_app ignores. Xlib.h comes first, so its own
// declarations keep their names.
#if defined(__linux__) && !defined(__ANDROID__)
#include <X11/Xlib.h>
#include <string.h>

#include "ime_linux.h"
static int fa_x11_pending(Display* display) {
    fa_ime_x11_batch();
    return XPending(display);
}
static int fa_x11_next_event(Display* display, XEvent* event) {
    // sokol_app reads XPending's count once and then that many events. The input method may take some of them meanwhile
    // (XFilterEvent and XOpenIM wait for their server's answers with XIfEvent), and XNextEvent on an empty queue would
    // block until the next X event, the game not drawing: what is missing becomes an event sokol_app skips (its switch
    // has no case for NoExpose), and the backend does not see it.
    if (XQLength(display) == 0 && XPending(display) == 0) {  // XPending flushes and reads the socket: only when empty
        memset(event, 0, sizeof *event);
        event->type = NoExpose;
        return 0;
    }
    const int r = XNextEvent(display, event);
    fa_ime_x11_event(event);
    return r;
}
#define XPending fa_x11_pending
#define XNextEvent fa_x11_next_event
#endif
// Windows: sokol_app makes the window and owns no graphics device (SOKOL_NOAPI); sokol_gfx stays SOKOL_D3D11. The
// engine makes the D3D11 device and the window's DXGI swapchain itself (d3d11_present_win32.cpp), so the D3D12 and
// Vulkan backends can make their own swapchain on the same window. sokol_app's frame callback then only runs the frame:
// app.cpp resizes and presents around it. The backend macro is SOKOL_D3D11 again from sokol_gfx.h on (sokol_glue.h is
// not used for it).
#if defined(_WIN32) && defined(SOKOL_D3D11)
#define FA_SOKOL_APP_NOAPI 1
#undef SOKOL_D3D11
#define SOKOL_NOAPI
#endif
#include "sokol_app.h"
#if defined(FA_SOKOL_APP_NOAPI)
#undef SOKOL_NOAPI
#define SOKOL_D3D11
#endif
#if defined(__ANDROID__)
#undef ANativeActivity_onCreate
#undef eglCreateWindowSurface
#undef eglDestroySurface
#undef eglMakeCurrent
#undef eglSwapBuffers
#undef eglQuerySurface
#endif
#if defined(__linux__) && !defined(__ANDROID__)
#undef XPending
#undef XNextEvent
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
    if (!_sapp.win32.hwnd) return false;  // no window (a headless run): no monitor to ask
    MONITORINFO info;
    memset(&info, 0, sizeof(info));
    info.cbSize = sizeof(info);
    if (!GetMonitorInfo(MonitorFromWindow(_sapp.win32.hwnd, MONITOR_DEFAULTTONEAREST), &info)) return false;
    *w = (int)((info.rcMonitor.right - info.rcMonitor.left) / _sapp.win32.dpi.window_scale + 0.5f);
    *h = (int)((info.rcMonitor.bottom - info.rcMonitor.top) / _sapp.win32.dpi.window_scale + 0.5f);
    return true;
#elif defined(_SAPP_LINUX)
    // The whole X screen: with several monitors it spans all of them (no XRandR here).
    if (!_sapp.x11.display) return false;  // no window (a headless run): DisplayWidth would read a null display
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
typedef struct {
    HMONITOR h;
    RECT r;
    bool primary;
    char name[64];
    double hz;
} fa_win_mon;
typedef struct {
    fa_win_mon m[16];
    int n;
} fa_win_mons;

// The refresh rate of monitor `h` in Hz: the frequency of its current display mode. Windows answers 0 or 1 for "the
// hardware's default", which says nothing: 0 (unknown). It rounds the NTSC rates down to whole numbers (59.94 Hz is
// 59): a frequency one below a multiple of 24 or 30 is taken as that multiple / 1.001.
static double fa_win_monitor_hz(HMONITOR h) {
    MONITORINFOEXW info;
    DEVMODEW mode;
    if (h == NULL) return 0.0;
    memset(&info, 0, sizeof(info));
    info.cbSize = sizeof(info);
    if (!GetMonitorInfoW(h, (MONITORINFO*)&info)) return 0.0;
    memset(&mode, 0, sizeof(mode));
    mode.dmSize = sizeof(mode);
    if (!EnumDisplaySettingsW(info.szDevice, ENUM_CURRENT_SETTINGS, &mode)) return 0.0;
    if (mode.dmDisplayFrequency <= 1) return 0.0;
    const DWORD next = mode.dmDisplayFrequency + 1;
    if (next >= 24 && (next % 24 == 0 || next % 30 == 0)) return (double)next / 1.001;
    return (double)mode.dmDisplayFrequency;
}

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
    m->hz = fa_win_monitor_hz(h);
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
typedef struct {
    Time timestamp, configTimestamp;
    int ncrtc;
    XID* crtcs;
    int noutput;
    XID* outputs;
    int nmode;
    struct fa_xrr_mode_info* modes;
} fa_xrr_resources;
// XRRModeInfo: the timings of one mode (its refresh rate is dotClock / (hTotal * vTotal)).
typedef struct fa_xrr_mode_info {
    XID id;
    unsigned int width, height;
    unsigned long dotClock;
    unsigned int hSyncStart, hSyncEnd, hTotal, hSkew;
    unsigned int vSyncStart, vSyncEnd, vTotal;
    char* name;
    unsigned int nameLength;
    unsigned long modeFlags;
} fa_xrr_mode_info;
typedef struct {
    Time timestamp;
    int x, y;
    unsigned int width, height;
    XID mode;
    unsigned short rotation;
    int noutput;
    XID* outputs;
    unsigned short rotations;
    int npossible;
    XID* possible;
} fa_xrr_crtc;
typedef struct {
    Time timestamp;
    XID crtc;
    char* name;
    int nameLen;
    unsigned long mm_width, mm_height;
    unsigned short connection;
    unsigned short subpixel_order;
    int ncrtc;
    XID* crtcs;
    int nclone;
    XID* clones;
    int nmode;
    int npreferred;
    XID* modes;
} fa_xrr_output;

typedef struct {
    int x, y, w, h;  // physical pixels
    bool primary;
    char name[64];
    double hz;  // 0: unknown
} fa_x11_mon;

// The refresh rate of mode `id` of `res` in Hz, the way xrandr computes it (a double-scan mode draws each line twice,
// an interlaced one half the lines per field). 0: no such mode, or no timings.
static double fa_xrr_mode_hz(const fa_xrr_resources* res, XID id) {
    for (int i = 0; i < res->nmode; i++) {
        const fa_xrr_mode_info* m = &res->modes[i];
        if (m->id != id) continue;
        double v = (double)m->vTotal;
        if (m->modeFlags & 0x20) v *= 2.0;  // RR_DoubleScan
        if (m->modeFlags & 0x10) v /= 2.0;  // RR_Interlace
        if (m->hTotal == 0 || v <= 0.0) return 0.0;
        return (double)m->dotClock / ((double)m->hTotal * v);
    }
    return 0.0;
}

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
        !fa_XRRFreeCrtcInfo || !fa_XRRFreeOutputInfo || !fa_XRRGetOutputPrimary)
        return false;
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
                        m->hz = fa_xrr_mode_hz(res, c->mode);
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
        out[0].hz = 0.0;
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

// The index in `list` of the monitor under the window's centre (0 when it is on none of them).
static int fa_x11_current(const fa_x11_mon* list, int count) {
    int cx, cy;
    fa_x11_window_centre(&cx, &cy);
    int current = 0;
    for (int i = 0; i < count; i++) {
        if (cx >= list[i].x && cx < list[i].x + list[i].w && cy >= list[i].y && cy < list[i].y + list[i].h) current = i;
    }
    return current;
}

// The refresh rate of the mode in use under the window's centre (0: unknown). The engine asks every two seconds, so
// this reads only the CRTCs (one XRandR resources query and one call per CRTC), not the whole monitor list with
// names, outputs and the primary's move. A window on no CRTC gets the first one that shows something.
static double fa_x11_window_hz(void) {
    if (!fa_xrr_load()) return 0.0;
    fa_xrr_resources* res = fa_XRRGetScreenResourcesCurrent(_sapp.x11.display, _sapp.x11.root);
    if (!res) return 0.0;
    int cx, cy;
    fa_x11_window_centre(&cx, &cy);
    double under = 0.0, first = 0.0;
    for (int i = 0; i < res->ncrtc; i++) {
        fa_xrr_crtc* c = fa_XRRGetCrtcInfo(_sapp.x11.display, res, res->crtcs[i]);
        if (!c) continue;
        if (c->mode != 0 && c->noutput > 0 && c->width > 0 && c->height > 0) {
            const double hz = fa_xrr_mode_hz(res, c->mode);
            if (first == 0.0) first = hz;
            if (hz > 0.0 && cx >= c->x && cx < c->x + (int)c->width && cy >= c->y && cy < c->y + (int)c->height)
                under = hz;
        }
        fa_XRRFreeCrtcInfo(c);
    }
    fa_XRRFreeScreenResources(res);
    return under > 0.0 ? under : first;
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
        out[n].refresh_hz = m->hz;
    }
    return n;
#elif defined(_SAPP_LINUX)
    fa_x11_mon list[16];
    const int count = fa_x11_collect(list, 16);
    const float scale = _sapp.x11.dpi / 96.0f;
    const int current = fa_x11_current(list, count);
    int n = 0;
    for (; n < count && n < max; n++) {
        memcpy(out[n].name, list[n].name, sizeof(out[n].name));
        out[n].x = (int)(list[n].x / scale);
        out[n].y = (int)(list[n].y / scale);
        out[n].w = (int)(list[n].w / scale + 0.5f);
        out[n].h = (int)(list[n].h / scale + 0.5f);
        out[n].primary = list[n].primary;
        out[n].current = n == current;
        out[n].refresh_hz = list[n].hz;
    }
    return n;
#else
    return 0;
#endif
}

double fa_sapp_display_refresh_hz(void) {
#if defined(_SAPP_WIN32)
    if (_sapp.win32.hwnd == NULL) return 0.0;
    return fa_win_monitor_hz(MonitorFromWindow(_sapp.win32.hwnd, MONITOR_DEFAULTTONEAREST));
#elif defined(_SAPP_LINUX)
    if (_sapp.x11.display == NULL || _sapp.x11.window == 0) return 0.0;
    return fa_x11_window_hz();
#else
    return 0.0;  // the web has no API for it (the engine estimates it), Android asks through JNI (app.cpp)
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
        SetWindowPos(hwnd, HWND_TOP, r.left, r.top, r.right - r.left, r.bottom - r.top,
                     SWP_NOACTIVATE | SWP_FRAMECHANGED);
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

// ---- the window's OpenGL surface, off the window while a GPU device presents there (sokol_window.h, M77-P9e3) ---
#if defined(_SAPP_GLX)
// GLX 1.3 names sokol_app's own GLX declarations leave out (it includes no <GL/glx.h>, whose types would clash with
// them).
#define FA_GLX_PBUFFER_BIT 0x00000004
#define FA_GLX_PBUFFER_HEIGHT 0x8040
#define FA_GLX_PBUFFER_WIDTH 0x8041
typedef XID fa_glx_pbuffer;
typedef fa_glx_pbuffer (*fa_glx_create_pbuffer_fn)(Display*, GLXFBConfig, const int*);
typedef void (*fa_glx_destroy_pbuffer_fn)(Display*, fa_glx_pbuffer);

static struct {
    int state;               // fa_sapp_gl_surface_state(): 0 on the window, 1 a pbuffer, 2 no drawable
    fa_glx_pbuffer pbuffer;  // state 1
    fa_glx_destroy_pbuffer_fn destroy_pbuffer;
    PFNGLXSWAPBUFFERSPROC swap;  // sokol_app's glXSwapBuffers, replaced by fa_glx_no_swap while the surface is off
} fa_gl_surface;

// sokol_app swaps _sapp.glx.window after every frame; while the device has the window there is nothing to swap.
static void fa_glx_no_swap(Display* display, GLXDrawable drawable) {
    (void)display;
    (void)drawable;
}

// X errors of the GLX requests below are trapped (Xlib's default handler would end the process) and answered with their
// code. The handler that was installed before (none: Xlib's default) comes back afterwards.
static int fa_x11_error_code;
static int fa_x11_record_error(Display* display, XErrorEvent* event) {
    (void)display;
    fa_x11_error_code = event->error_code;
    return 0;
}
static XErrorHandler fa_x11_trap_errors(void) {
    XSync(_sapp.x11.display, False);  // the errors of earlier requests are not these ones'
    fa_x11_error_code = Success;
    return XSetErrorHandler(fa_x11_record_error);
}
static int fa_x11_untrap_errors(XErrorHandler previous) {
    XSync(_sapp.x11.display, False);  // every error of the trapped requests has arrived
    XSetErrorHandler(previous);
    return fa_x11_error_code;
}

static void fa_glx_destroy_pbuffer_quietly(fa_glx_destroy_pbuffer_fn destroy, fa_glx_pbuffer pbuffer) {
    if (!destroy || !pbuffer) return;
    const XErrorHandler previous = fa_x11_trap_errors();
    destroy(_sapp.x11.display, pbuffer);
    fa_x11_untrap_errors(previous);
}

static void fa_glx_destroy_window_quietly(GLXWindow window) {
    if (!window) return;
    const XErrorHandler previous = fa_x11_trap_errors();
    _sapp.glx.DestroyWindow(_sapp.x11.display, window);
    fa_x11_untrap_errors(previous);
}

bool fa_sapp_gl_surface_release(char* err, size_t errLen) {
    if (errLen > 0) err[0] = 0;
    if (fa_gl_surface.state != 0) return true;
    if (!_sapp.valid || !_sapp.x11.display || !_sapp.glx.ctx || !_sapp.glx.window) {
        snprintf(err, errLen, "sokol_app has no OpenGL surface on a window yet (no window)");
        return false;
    }
    Display* display = _sapp.x11.display;
    const GLXFBConfig config = _sapp_glx_choosefbconfig();  // the one sokol_app made the context and GLXWindow with
    const fa_glx_create_pbuffer_fn create = (fa_glx_create_pbuffer_fn)dlsym(_sapp.glx.libgl, "glXCreatePbuffer");
    const fa_glx_destroy_pbuffer_fn destroy = (fa_glx_destroy_pbuffer_fn)dlsym(_sapp.glx.libgl, "glXDestroyPbuffer");
    glFinish();  // what OpenGL still draws into the window is done before its surface goes

    // 1. A 1x1 pbuffer of the window's GLXFBConfig.
    fa_glx_pbuffer pbuffer = 0;
    char pbuffer_why[96];
    pbuffer_why[0] = 0;
    if (!config) {
        snprintf(pbuffer_why, sizeof pbuffer_why, "no GLXFBConfig to make a pbuffer with");
    } else if (!create || !destroy) {
        snprintf(pbuffer_why, sizeof pbuffer_why, "this libGL has no glXCreatePbuffer");
    } else if (!(_sapp_glx_attrib(config, GLX_DRAWABLE_TYPE) & FA_GLX_PBUFFER_BIT)) {
        snprintf(pbuffer_why, sizeof pbuffer_why, "the window's GLXFBConfig makes no pbuffer");
    } else {
        const int attribs[] = {FA_GLX_PBUFFER_WIDTH, 1, FA_GLX_PBUFFER_HEIGHT, 1, None};
        XErrorHandler previous = fa_x11_trap_errors();
        pbuffer = create(display, config, attribs);
        int code = fa_x11_untrap_errors(previous);
        if (code != Success || !pbuffer) {
            fa_glx_destroy_pbuffer_quietly(destroy, pbuffer);
            pbuffer = 0;
            snprintf(pbuffer_why, sizeof pbuffer_why, "glXCreatePbuffer failed (X error %d)", code);
        } else {
            previous = fa_x11_trap_errors();
            const Bool current = _sapp.glx.MakeCurrent(display, pbuffer, _sapp.glx.ctx);
            code = fa_x11_untrap_errors(previous);
            if (!current || code != Success) {
                fa_glx_destroy_pbuffer_quietly(destroy, pbuffer);
                pbuffer = 0;
                snprintf(pbuffer_why, sizeof pbuffer_why, "glXMakeCurrent on the pbuffer failed (X error %d)", code);
            }
        }
    }
    // 2. No drawable at all: a 3.0+ context of GLX_ARB_create_context may be current without a default framebuffer.
    int state = pbuffer ? 1 : 0;
    if (state == 0) {
        const XErrorHandler previous = fa_x11_trap_errors();
        const Bool current = _sapp.glx.MakeCurrent(display, None, _sapp.glx.ctx);
        if (fa_x11_untrap_errors(previous) == Success && current) state = 2;
    }
    if (state == 0) {
        const XErrorHandler previous = fa_x11_trap_errors();  // a failed glXMakeCurrent keeps the old one; said again
        _sapp.glx.MakeCurrent(display, _sapp.glx.window, _sapp.glx.ctx);
        fa_x11_untrap_errors(previous);
        snprintf(err, errLen,
                 "the OpenGL context sokol_app made on the window could not leave it (%s, and the driver refused a "
                 "context with no drawable), so a Vulkan swapchain cannot be made there (hint: leave render.backend "
                 "on auto on this driver, or run headless)",
                 pbuffer_why);
        return false;
    }
    // The GLXWindow goes. _sapp.glx.window is 0 from now on: sokol_app's shutdown then destroys no GLXWindow, and the
    // only other per-frame use, its glXSwapBuffers, does nothing (fa_sapp_set_vsync refuses while the surface is off).
    fa_glx_destroy_window_quietly(_sapp.glx.window);
    _sapp.glx.window = 0;
    fa_gl_surface.swap = _sapp.glx.SwapBuffers;
    _sapp.glx.SwapBuffers = fa_glx_no_swap;
    fa_gl_surface.pbuffer = pbuffer;
    fa_gl_surface.destroy_pbuffer = destroy;
    fa_gl_surface.state = state;
    if (state == 2) snprintf(err, errLen, "%s", pbuffer_why);  // why there is no pbuffer (app.cpp logs it)
    return true;
}

bool fa_sapp_gl_surface_restore(char* err, size_t errLen) {
    if (errLen > 0) err[0] = 0;
    if (fa_gl_surface.state == 0) return true;
    Display* display = _sapp.x11.display;
    const GLXFBConfig config = _sapp_glx_choosefbconfig();
    GLXWindow window = 0;
    XErrorHandler previous = fa_x11_trap_errors();
    if (config) window = _sapp.glx.CreateWindow(display, config, _sapp.x11.window, NULL);
    int code = fa_x11_untrap_errors(previous);
    if (!window || code != Success) {
        fa_glx_destroy_window_quietly(window);
        snprintf(err, errLen,
                 "glXCreateWindow on the X11 window failed (X error %d): the OpenGL context stays off the window "
                 "and its frames are not shown (hint: leave render.backend on auto on this driver)",
                 code);
        return false;
    }
    previous = fa_x11_trap_errors();
    const Bool current = _sapp.glx.MakeCurrent(display, window, _sapp.glx.ctx);
    code = fa_x11_untrap_errors(previous);
    if (!current || code != Success) {
        fa_glx_destroy_window_quietly(window);
        snprintf(err, errLen,
                 "glXMakeCurrent on the new GLXWindow failed (X error %d): the OpenGL context stays off the window "
                 "and its frames are not shown (hint: leave render.backend on auto on this driver)",
                 code);
        return false;
    }
    // sokol_app's state as _sapp_glx_create_context and _sapp_glx_make_current left it.
    _sapp.glx.window = window;
    _sapp.glx.SwapBuffers = fa_gl_surface.swap;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint*)&_sapp.gl.framebuffer);
    fa_glx_destroy_pbuffer_quietly(fa_gl_surface.destroy_pbuffer, fa_gl_surface.pbuffer);
    fa_gl_surface.pbuffer = 0;
    fa_gl_surface.state = 0;
    // The swap interval belongs to the drawable (GLX_EXT_swap_control): the new one gets what the window had.
    previous = fa_x11_trap_errors();
    _sapp_glx_swapinterval(_sapp.desc.disable_vsync ? 0 : _sapp.desc.swap_interval);
    fa_x11_untrap_errors(previous);
    return true;
}

void fa_sapp_gl_surface_discard(void) {
    if (fa_gl_surface.state == 0) return;
    // sokol_app's shutdown destroys no GLXWindow (_sapp.glx.window is 0) and its context: the pbuffer goes now.
    fa_glx_destroy_pbuffer_quietly(fa_gl_surface.destroy_pbuffer, fa_gl_surface.pbuffer);
    fa_gl_surface.pbuffer = 0;
    fa_gl_surface.state = 0;
}

int fa_sapp_gl_surface_state(void) { return fa_gl_surface.state; }
void fa_sapp_gl_surface_set_window_listener(void (*listener)(void* window, void* user), void* user) {
    (void)listener;  // the X11 window outlives the release: nothing to hear
    (void)user;
}
#elif defined(_SAPP_ANDROID)
// sokol_app's EGL surface attributes, as _sapp_android_init_egl_surface passes them.
static const EGLint* fa_egl_window_attribs(void) {
    static const EGLint srgb[] = {EGL_GL_COLORSPACE, EGL_GL_COLORSPACE_SRGB, EGL_NONE};
    return _sapp.desc.srgb ? srgb : NULL;
}
bool fa_sapp_gl_surface_release(char* err, size_t errLen) {
    void* surface = (void*)_sapp.android.surface;
    const bool ok = fa_egl_handover_release(&fa_egl, (void*)_sapp.android.display, (void*)_sapp.android.config,
                                            (void*)_sapp.android.context, (void*)_sapp.android.current.window, &surface,
                                            err, errLen);
    _sapp.android.surface = (EGLSurface)surface;
    return ok;
}
bool fa_sapp_gl_surface_restore(char* err, size_t errLen) {
    void* surface = (void*)_sapp.android.surface;
    const bool was_released = fa_egl.state != 0;
    const bool ok = fa_egl_handover_restore(&fa_egl, (void*)_sapp.android.display, (void*)_sapp.android.config,
                                            (void*)_sapp.android.context, (const int*)fa_egl_window_attribs(), &surface,
                                            err, errLen);
    _sapp.android.surface = (EGLSurface)surface;
    // sokol_app's state as _sapp_android_init_egl_surface leaves it, when there is a window surface again.
    if (ok && was_released && _sapp.android.surface != EGL_NO_SURFACE) {
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint*)&_sapp.gl.framebuffer);
    }
    return ok;
}
void fa_sapp_gl_surface_discard(void) {
    // sokol_app's shutdown destroys its surface, the stand-in, through the wrapper above, which knows it (state stays
    // set).
}
int fa_sapp_gl_surface_state(void) { return fa_egl.state; }
void fa_sapp_gl_surface_set_window_listener(void (*listener)(void* window, void* user), void* user) {
    fa_egl_handover_set_listener(&fa_egl, listener, user);
}
#else
bool fa_sapp_gl_surface_release(char* err, size_t errLen) {
#if defined(_SAPP_LINUX) && defined(_SAPP_EGL)
    snprintf(err, errLen,
             "this build's sokol_app draws its window through EGL (SOKOL_FORCE_EGL or -DFA_GFX_BACKEND=GLES3), whose "
             "window surface the engine does not hand over, so a Vulkan swapchain cannot be made there (hint: build "
             "with the default GLX window, leave render.backend on auto, or run headless)");
#else
    snprintf(err, errLen, "this platform's window has no OpenGL surface to release");
#endif
    return false;
}
bool fa_sapp_gl_surface_restore(char* err, size_t errLen) {
    if (errLen > 0) err[0] = 0;
    return true;
}
void fa_sapp_gl_surface_discard(void) {}
int fa_sapp_gl_surface_state(void) { return 0; }
void fa_sapp_gl_surface_set_window_listener(void (*listener)(void* window, void* user), void* user) {
    (void)listener;
    (void)user;
}
#endif

// The CAMetalLayer of a macOS window is sokol_impl_apple.m's: nothing to save or restore elsewhere.
void fa_sapp_window_claimed(void) {}
void fa_sapp_window_returned(void) {}

// Windows (FA_SOKOL_APP_NOAPI): the swapchain is the engine's, so are vsync and its kind (d3d11_present_win32.cpp).
#if !defined(FA_SOKOL_APP_NOAPI)
bool fa_sapp_set_vsync(bool on) {
#if defined(_SAPP_GLX)
    if (fa_gl_surface.state != 0) return false;  // a GPU device presents into the window: its swapchain has the vsync
    if (!_sapp.glx.EXT_swap_control && !_sapp.glx.MESA_swap_control) return false;  // the driver offers no swap control
    _sapp_glx_swapinterval(on ? 1 : 0);
    _sapp.desc.disable_vsync = !on;
    return true;
#else
    (void)on;
    return false;
#endif
}

int fa_sapp_swapchain_kind(void) { return 0; }

int fa_sapp_set_swapchain_kind(int kind, bool linear) {
    (void)kind;
    (void)linear;
    return 0;
}
#endif

bool fa_sapp_edr(fa_sapp_edr_screen* out) {
    memset(out, 0, sizeof(*out));  // Apple only (sokol_impl_apple.m)
    out->max_headroom = 1.0f;
    out->headroom = 1.0f;
    return false;
}

bool fa_sapp_set_dock_icon(const unsigned char* rgba, int w, int h) {
    (void)rgba;  // macOS only (sokol_impl_apple.m): Windows and Linux take the window icon from sapp_desc.icon
    (void)w;
    (void)h;
    return false;
}

bool fa_sapp_native_window(void** window, void** display) {
    *window = NULL;
    *display = NULL;
#if defined(_SAPP_WIN32)
    *window = (void*)_sapp.win32.hwnd;
#elif defined(_SAPP_LINUX)
    if (!_sapp.x11.display || _sapp.x11.window == 0) return false;
    *window = (void*)(uintptr_t)_sapp.x11.window;  // an XID: VK_KHR_xlib_surface takes it back as an integer
    *display = (void*)_sapp.x11.display;
#elif defined(_SAPP_ANDROID)
    *window = (void*)_sapp.android.current.window;  // the surface of now (null while the activity has none)
#endif
    return *window != NULL;
}

bool fa_sapp_set_class_name(const char* name) {
#if defined(_SAPP_LINUX)
    XClassHint hint;
    hint.res_name = (char*)name;
    hint.res_class = (char*)name;
    XSetClassHint(_sapp.x11.display, _sapp.x11.window, &hint);
    XFlush(_sapp.x11.display);
    return true;
#else
    (void)name;
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
//
// Before that, the game ends (activity_end_android.cpp): its "quit" handlers, the storage writes still waiting, the audio
// device, all on sokol_app's loop thread while this main thread waits for them, at most about 1.5 s. A loop thread that
// does not answer in time is busy: sokol's onDestroy would wait for it without a limit, so the process ends here at once.
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static void (*fa_sokol_on_destroy)(ANativeActivity* activity);
int fa_android_activity_ending(void);  // activity_end_android.cpp

static void fa_exit_now(void) {
    fflush(NULL);  // what exit() would still do for stdio
    _exit(0);
}

static void fa_on_destroy(ANativeActivity* activity) {
    if (!fa_android_activity_ending()) _exit(0);  // the game's end timed out (and logged it): no stdio flush either
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

#if defined(__EMSCRIPTEN__)
// The web: sokol_app listens for keys, focus and blur on the window (capture phase). The IME backend (ime_web.cpp) sees
// each first, through these wrappers of sokol_app's own handlers:
//  - a key the browser's input method takes (keyCode 229, or any key while a composition is open) is the IME's: sokol_app
//    does not see it, and the browser gets it with its default action (no preventDefault), so the composition goes on;
//  - the focus moving to or from the hidden <input> the IME and the phone's keyboard type into is not the page losing it.
#include "ime_web.h"

static EM_BOOL fa_emsc_key_cb(int type, const EmscriptenKeyboardEvent* e, void* user_data) {
    const int kind = type == EMSCRIPTEN_EVENT_KEYDOWN ? 0 : (type == EMSCRIPTEN_EVENT_KEYUP ? 1 : 2);
    const sapp_keycode key = _sapp_emsc_translate_key(e->code[0] != 0 ? e->code : e->key);
    if (fa_ime_web_key(kind, (int)e->keyCode, (int)key)) return false;
    return _sapp_emsc_key_cb(type, e, user_data);
}

static EM_BOOL fa_emsc_focus_cb(int type, const EmscriptenFocusEvent* e, void* user_data) {
    if (fa_ime_web_ignore_focus(e->id)) return true;
    return _sapp_emsc_focus_cb(type, e, user_data);
}

static EM_BOOL fa_emsc_blur_cb(int type, const EmscriptenFocusEvent* e, void* user_data) {
    if (fa_ime_web_ignore_focus(e->id)) return true;
    fa_ime_web_blur();
    return _sapp_emsc_blur_cb(type, e, user_data);
}

void fa_sapp_web_route_events(void) {
    // A NULL callback removes the handlers sokol_app registered for that event on the window; then the wrappers go on.
    emscripten_set_keydown_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, 0);
    emscripten_set_keyup_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, 0);
    emscripten_set_keypress_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, 0);
    emscripten_set_focus_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, 0);
    emscripten_set_blur_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, 0);
    emscripten_set_keydown_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, fa_emsc_key_cb);
    emscripten_set_keyup_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, fa_emsc_key_cb);
    emscripten_set_keypress_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, fa_emsc_key_cb);
    emscripten_set_focus_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, fa_emsc_focus_cb);
    emscripten_set_blur_callback(EMSCRIPTEN_EVENT_TARGET_WINDOW, 0, true, fa_emsc_blur_cb);
}
#endif  // __EMSCRIPTEN__

#endif  // !__APPLE__
