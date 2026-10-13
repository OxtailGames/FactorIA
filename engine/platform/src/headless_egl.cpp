// Window-less GPU context through EGL.
//   Linux:   desktop OpenGL 4.3 core (falls back to 4.1) on Mesa's
//            EGL_MESA_platform_surfaceless display (works with llvmpipe and no
//            X server), else the default EGL display with a 1x1 pbuffer.
//   Android: OpenGL ES 3 on the default display with a 1x1 pbuffer (UNTESTED).
#include <cstdio>
#include <cstring>
#include <format>
#include <string>

#include <EGL/egl.h>
#include <EGL/eglext.h>
#if defined(__ANDROID__)
#include <GLES3/gl3.h>
#else
#include <GL/gl.h>
#endif

#include "fa/platform/app.h"
#include "sokol_gfx.h"

#ifndef EGL_PLATFORM_SURFACELESS_MESA
#define EGL_PLATFORM_SURFACELESS_MESA 0x31DD
#endif

namespace fa {

struct HeadlessGpu::Impl {
    EGLDisplay display = EGL_NO_DISPLAY;
    EGLContext context = EGL_NO_CONTEXT;
    EGLSurface surface = EGL_NO_SURFACE;
    bool valid = false;
    std::string description;
};

HeadlessGpu::HeadlessGpu() = default;
HeadlessGpu::~HeadlessGpu() { shutdown(); }

namespace {
std::string egl_error_name() {
    EGLint e = eglGetError();
    return std::format("EGL error 0x{:x}", unsigned(e));
}
}  // namespace

bool HeadlessGpu::init(std::string* error) {
    if (impl_) return true;
    Impl* m = new Impl();
    auto fail = [&](const std::string& msg) {
        if (error) *error = msg;
        if (m->context != EGL_NO_CONTEXT) eglDestroyContext(m->display, m->context);
        if (m->surface != EGL_NO_SURFACE) eglDestroySurface(m->display, m->surface);
        if (m->display != EGL_NO_DISPLAY) eglTerminate(m->display);
        delete m;
        return false;
    };

    // ---- display -----------------------------------------------------------
    std::string how;
    EGLint major = 0, minor = 0;
#if !defined(__ANDROID__)
    {
        auto getPlatformDisplay = reinterpret_cast<PFNEGLGETPLATFORMDISPLAYEXTPROC>(eglGetProcAddress("eglGetPlatformDisplayEXT"));
        if (getPlatformDisplay) {
            EGLDisplay d = getPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA, EGL_DEFAULT_DISPLAY, nullptr);
            if (d != EGL_NO_DISPLAY && eglInitialize(d, &major, &minor)) {
                m->display = d;
                how = "EGL surfaceless";
            } else if (d != EGL_NO_DISPLAY) {
                eglTerminate(d);
            }
        }
    }
#endif
    if (m->display == EGL_NO_DISPLAY) {
        EGLDisplay d = eglGetDisplay(EGL_DEFAULT_DISPLAY);
        if (d == EGL_NO_DISPLAY || !eglInitialize(d, &major, &minor)) {
            return fail(
                "No EGL display available (" + egl_error_name() + "). The headless renderer needs an OpenGL driver: "
                "install Mesa (apt install libegl1 libgl1-mesa-dri libgles2) or run the command under "
                "`xvfb-run -a -s \"-screen 0 1280x720x24\" <cmd>`.");
        }
        m->display = d;
        how = "EGL pbuffer";
    }

    // ---- API + config ------------------------------------------------------
#if defined(__ANDROID__)
    if (!eglBindAPI(EGL_OPENGL_ES_API)) return fail("eglBindAPI(OpenGL ES) failed: " + egl_error_name());
    const EGLint renderable = EGL_OPENGL_ES3_BIT;
#else
    if (!eglBindAPI(EGL_OPENGL_API)) {
        return fail("eglBindAPI(OpenGL) failed: " + egl_error_name() +
                    ". This EGL driver has no desktop OpenGL support; install Mesa (apt install libgl1-mesa-dri).");
    }
    const EGLint renderable = EGL_OPENGL_BIT;
#endif
    EGLConfig config = nullptr;
    EGLint numConfigs = 0;
    bool havePbuffer = true;
    {
        const EGLint attribs[] = {EGL_SURFACE_TYPE, EGL_PBUFFER_BIT, EGL_RENDERABLE_TYPE, renderable,
                                  EGL_RED_SIZE, 8, EGL_GREEN_SIZE, 8, EGL_BLUE_SIZE, 8, EGL_ALPHA_SIZE, 8, EGL_NONE};
        if (!eglChooseConfig(m->display, attribs, &config, 1, &numConfigs) || numConfigs < 1) {
            // Surfaceless-only drivers: no pbuffer configs, rely on EGL_KHR_surfaceless_context.
            const EGLint attribs2[] = {EGL_RENDERABLE_TYPE, renderable, EGL_NONE};
            havePbuffer = false;
            if (!eglChooseConfig(m->display, attribs2, &config, 1, &numConfigs) || numConfigs < 1) {
                return fail("No suitable EGL config (" + egl_error_name() + ") for OpenGL rendering via " + how +
                            ". Install Mesa (apt install libgl1-mesa-dri) or run under xvfb-run.");
            }
        }
    }

    // ---- context -----------------------------------------------------------
#if defined(__ANDROID__)
    {
        const EGLint ctxAttribs[] = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL_NONE};
        m->context = eglCreateContext(m->display, config, EGL_NO_CONTEXT, ctxAttribs);
    }
    std::string ctxVersion = "GLES 3.0";
#else
    std::string ctxVersion;
    const int versions[][2] = {{4, 3}, {4, 1}};
    for (const auto& v : versions) {
        const EGLint ctxAttribs[] = {EGL_CONTEXT_MAJOR_VERSION, v[0], EGL_CONTEXT_MINOR_VERSION, v[1],
                                     EGL_CONTEXT_OPENGL_PROFILE_MASK, EGL_CONTEXT_OPENGL_CORE_PROFILE_BIT, EGL_NONE};
        m->context = eglCreateContext(m->display, config, EGL_NO_CONTEXT, ctxAttribs);
        if (m->context != EGL_NO_CONTEXT) {
            ctxVersion = std::format("GL {}.{} core", v[0], v[1]);
            break;
        }
    }
#endif
    if (m->context == EGL_NO_CONTEXT) {
        return fail("Could not create an OpenGL 4.1+ core context (" + egl_error_name() + ") via " + how +
                    ". The GPU driver is too old or missing; with Mesa use llvmpipe: "
                    "`LIBGL_ALWAYS_SOFTWARE=1`, or install libgl1-mesa-dri.");
    }

    if (havePbuffer) {
        const EGLint pb[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
        m->surface = eglCreatePbufferSurface(m->display, config, pb);
        if (m->surface == EGL_NO_SURFACE) return fail("eglCreatePbufferSurface failed: " + egl_error_name());
    }
    if (!eglMakeCurrent(m->display, m->surface, m->surface, m->context)) {
        return fail("eglMakeCurrent failed: " + egl_error_name() +
                    (havePbuffer ? "" : " (driver lacks EGL_KHR_surfaceless_context and pbuffer configs)"));
    }

    const char* renderer = reinterpret_cast<const char*>(glGetString(GL_RENDERER));
    const char* version = reinterpret_cast<const char*>(glGetString(GL_VERSION));
    m->description = std::format("{} / {} ({}, {})", how, renderer ? renderer : "unknown GPU", ctxVersion,
                                 version ? version : "?");
    m->valid = true;
    impl_ = m;
    return true;
}

void HeadlessGpu::shutdown() {
    if (!impl_) return;
    if (impl_->display != EGL_NO_DISPLAY) {
        eglMakeCurrent(impl_->display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
        if (impl_->context != EGL_NO_CONTEXT) eglDestroyContext(impl_->display, impl_->context);
        if (impl_->surface != EGL_NO_SURFACE) eglDestroySurface(impl_->display, impl_->surface);
        eglTerminate(impl_->display);
    }
    delete impl_;
    impl_ = nullptr;
}

bool HeadlessGpu::valid() const { return impl_ && impl_->valid; }

GfxEnvironment HeadlessGpu::environment() const {
    GfxEnvironment out{};
    sg_environment env{};
    env.defaults.color_format = SG_PIXELFORMAT_RGBA8;
    env.defaults.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    env.defaults.sample_count = 1;
    static_assert(sizeof(sg_environment) <= sizeof(GfxEnvironment::storage), "GfxEnvironment storage too small");
    std::memcpy(out.storage, &env, sizeof(env));
    return out;
}

const char* HeadlessGpu::description() const { return impl_ ? impl_->description.c_str() : "not initialized"; }

void HeadlessGpu::end_frame() { glFlush(); }

}  // namespace fa
