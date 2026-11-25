// sokol_app's Android EGL surface off the window while a GPU device presents there, and back (M77-P9e3b,
// src/egl_surface_handover.h). The logic runs over a fake EGL on every host; on Android sokol_impl.c gives it the real
// one.
#include <doctest.h>

#include <cstdint>
#include <string>
#include <vector>

#include "../src/egl_surface_handover.h"

namespace {

// A fake EGL: surfaces are numbered handles, the calls are recorded in order.
struct FakeEgl {
    bool pbuffers = true;     // the config makes pbuffers
    bool surfaceless = true;  // EGL_KHR_surfaceless_context
    bool makeCurrentFails = false;
    bool createWindowFails = false;
    std::uintptr_t next = 0x100;
    std::vector<std::uintptr_t> live;  // surfaces made and not destroyed
    void* draw = nullptr;              // what is current
    int finishes = 0;
    int swaps = 0;
    int windowCreates = 0;
    std::vector<std::string> log;

    void* make() {
        live.push_back(next);
        return reinterpret_cast<void*>(next++);
    }
    bool alive(void* s) const {
        for (std::uintptr_t v : live)
            if (v == reinterpret_cast<std::uintptr_t>(s)) return true;
        return false;
    }
};

FakeEgl& fake(void* user) { return *static_cast<FakeEgl*>(user); }

void* f_pbuffer(void* user, void*, void*) {
    FakeEgl& e = fake(user);
    if (!e.pbuffers) return nullptr;
    e.log.push_back("pbuffer");
    return e.make();
}
bool f_surfaceless(void* user, void*) { return fake(user).surfaceless; }
void* f_window_surface(void* user, void*, void*, void* window, const int*) {
    FakeEgl& e = fake(user);
    if (e.createWindowFails || !window) return nullptr;
    e.windowCreates++;
    e.log.push_back("window surface");
    return e.make();
}
bool f_destroy(void* user, void*, void* surface) {
    FakeEgl& e = fake(user);
    for (auto it = e.live.begin(); it != e.live.end(); ++it)
        if (*it == reinterpret_cast<std::uintptr_t>(surface)) {
            e.live.erase(it);
            e.log.push_back("destroy");
            return true;
        }
    return false;
}
bool f_make_current(void* user, void*, void* draw, void*, void*) {
    FakeEgl& e = fake(user);
    if (e.makeCurrentFails) return false;
    if (draw && !e.alive(draw)) return false;
    e.draw = draw;
    e.log.push_back(draw ? "current" : "current none");
    return true;
}
bool f_swap(void* user, void*, void* surface) {
    FakeEgl& e = fake(user);
    if (!e.alive(surface)) return false;
    e.swaps++;
    return true;
}
bool f_query(void* user, void*, void* surface, int attribute, int* value) {
    FakeEgl& e = fake(user);
    if (!e.alive(surface)) return false;
    *value = attribute == FA_EGL_WIDTH ? 1 : attribute == FA_EGL_HEIGHT ? 1 : 42;
    return true;
}
void f_window_size(void*, void* window, int* width, int* height) {
    *width = window ? 1080 : 0;
    *height = window ? 2400 : 0;
}
void f_finish(void* user) { fake(user).finishes++; }

struct Listener {
    std::vector<void*> heard;
    FakeEgl* egl = nullptr;
    std::vector<bool> standInAlive;  // whether the stand-in still existed when the listener heard
    void* standIn = nullptr;
};
void listen(void* window, void* user) {
    Listener& l = *static_cast<Listener*>(user);
    l.heard.push_back(window);
    if (l.egl) l.standInAlive.push_back(l.standIn ? l.egl->alive(l.standIn) : false);
}

struct Rig {
    FakeEgl egl;
    fa_egl_surface_ops ops{};
    fa_egl_surface_handover h{};
    void* display = reinterpret_cast<void*>(0x1);
    void* config = reinterpret_cast<void*>(0x2);
    void* context = reinterpret_cast<void*>(0x3);
    void* window = reinterpret_cast<void*>(0x4);
    void* surface = nullptr;  // sokol_app's _sapp.android.surface
    char err[512] = {};

    Rig() {
        ops.user = &egl;
        ops.create_pbuffer = f_pbuffer;
        ops.surfaceless = f_surfaceless;
        ops.create_window_surface = f_window_surface;
        ops.destroy_surface = f_destroy;
        ops.make_current = f_make_current;
        ops.swap_buffers = f_swap;
        ops.query_surface = f_query;
        ops.window_size = f_window_size;
        ops.finish = f_finish;
        h.ops = &ops;
        // sokol_app's start: a window surface on the window, current.
        surface = fa_egl_handover_create_window_surface(&h, display, config, window, nullptr);
        fa_egl_handover_make_current(&h, display, surface, surface, context);
    }
    bool release() { return fa_egl_handover_release(&h, display, config, context, window, &surface, err, sizeof err); }
    bool restore() { return fa_egl_handover_restore(&h, display, config, context, nullptr, &surface, err, sizeof err); }
};

}  // namespace

TEST_CASE("egl surface handover: outside a release every wrapper is the real call") {
    Rig r;
    REQUIRE(r.surface != nullptr);
    CHECK(r.h.state == 0);
    CHECK(r.egl.windowCreates == 1);
    CHECK(fa_egl_handover_swap_buffers(&r.h, r.display, r.surface));
    CHECK(r.egl.swaps == 1);
    int w = 0;
    CHECK(fa_egl_handover_query_surface(&r.h, r.display, r.surface, FA_EGL_WIDTH, &w));
    CHECK(w == 1);  // the fake's answer, not the window's
    // Restore with nothing released is a no-op.
    CHECK(r.restore());
    CHECK(r.egl.windowCreates == 1);
}

TEST_CASE("egl surface handover: release onto a pbuffer and restore") {
    Rig r;
    void* windowSurface = r.surface;
    REQUIRE(r.release());
    CHECK(r.err[0] == 0);
    CHECK(r.h.state == 1);
    CHECK(r.egl.finishes == 1);
    CHECK_FALSE(r.egl.alive(windowSurface));  // off the window: the ANativeWindow is free
    CHECK(r.surface != windowSurface);
    CHECK(r.egl.alive(r.surface));  // sokol_app holds the pbuffer
    CHECK(r.egl.draw == r.surface);
    // Released twice: nothing more.
    CHECK(r.release());
    CHECK(r.egl.finishes == 1);

    // sokol_app's frame: its swap shows nothing, its size is the window's.
    CHECK(fa_egl_handover_swap_buffers(&r.h, r.display, r.surface));
    CHECK(r.egl.swaps == 0);
    int w = 0, hgt = 0;
    CHECK(fa_egl_handover_query_surface(&r.h, r.display, r.surface, FA_EGL_WIDTH, &w));
    CHECK(fa_egl_handover_query_surface(&r.h, r.display, r.surface, FA_EGL_HEIGHT, &hgt));
    CHECK(w == 1080);
    CHECK(hgt == 2400);
    int other = 0;
    CHECK(fa_egl_handover_query_surface(&r.h, r.display, r.surface, 0x3058, &other));  // a pbuffer answers the rest
    CHECK(other == 42);

    void* pbuffer = r.surface;
    REQUIRE(r.restore());
    CHECK(r.h.state == 0);
    CHECK(r.h.stand_in == nullptr);
    CHECK_FALSE(r.egl.alive(pbuffer));
    CHECK(r.egl.alive(r.surface));
    CHECK(r.egl.draw == r.surface);
    CHECK(r.egl.windowCreates == 2);
    CHECK(r.egl.live.size() == 1);
    CHECK(fa_egl_handover_swap_buffers(&r.h, r.display, r.surface));
    CHECK(r.egl.swaps == 1);
}

TEST_CASE("egl surface handover: with no pbuffer the context is current with no surface") {
    Rig r;
    r.egl.pbuffers = false;
    REQUIRE(r.release());
    CHECK(r.h.state == 2);
    CHECK(std::string(r.err).find("no pbuffer") != std::string::npos);
    CHECK(r.surface != nullptr);  // sokol_app must not see EGL_NO_SURFACE (it would stop drawing frames)
    CHECK(r.egl.draw == nullptr);
    CHECK(r.egl.live.empty());
    // sokol_app's make-current of its "surface" reaches EGL as EGL_NO_SURFACE.
    CHECK(fa_egl_handover_make_current(&r.h, r.display, r.surface, r.surface, r.context));
    CHECK(r.egl.draw == nullptr);
    CHECK(fa_egl_handover_swap_buffers(&r.h, r.display, r.surface));
    int w = 0, other = 0;
    CHECK(fa_egl_handover_query_surface(&r.h, r.display, r.surface, FA_EGL_WIDTH, &w));
    CHECK(w == 1080);
    CHECK_FALSE(fa_egl_handover_query_surface(&r.h, r.display, r.surface, 0x3058, &other));
    REQUIRE(r.restore());
    CHECK(r.h.state == 0);
    CHECK(r.egl.live.size() == 1);
    CHECK(r.egl.draw == r.surface);
}

TEST_CASE("egl surface handover: a context that cannot leave the window changes nothing") {
    Rig r;
    r.egl.pbuffers = false;
    r.egl.surfaceless = false;
    void* windowSurface = r.surface;
    CHECK_FALSE(r.release());
    CHECK(std::string(r.err).find("EGL_KHR_surfaceless_context") != std::string::npos);
    CHECK(std::string(r.err).find("hint:") != std::string::npos);
    CHECK(r.h.state == 0);
    CHECK(r.surface == windowSurface);
    CHECK(r.egl.alive(windowSurface));
    CHECK(r.egl.draw == windowSurface);
}

TEST_CASE("egl surface handover: a failed make-current keeps the window surface") {
    Rig r;
    void* windowSurface = r.surface;
    r.egl.makeCurrentFails = true;
    CHECK_FALSE(r.release());
    CHECK(std::string(r.err).find("pbuffer") != std::string::npos);
    CHECK(r.h.state == 0);
    CHECK(r.surface == windowSurface);
    CHECK(r.egl.live.size() == 1);  // the pbuffer went again
    CHECK(r.egl.alive(windowSurface));
}

TEST_CASE("egl surface handover: a restore the driver refuses stays on the stand-in") {
    Rig r;
    REQUIRE(r.release());
    void* pbuffer = r.surface;
    r.egl.createWindowFails = true;
    CHECK_FALSE(r.restore());
    CHECK(std::string(r.err).find("eglCreateWindowSurface") != std::string::npos);
    CHECK(r.h.state == 1);
    CHECK(r.surface == pbuffer);
    CHECK(r.egl.alive(pbuffer));
    r.egl.createWindowFails = false;
    CHECK(r.restore());
    CHECK(r.h.state == 0);
}

TEST_CASE("egl surface handover: the window goes and comes back while released") {
    Rig r;
    Listener l;
    l.egl = &r.egl;
    fa_egl_handover_set_listener(&r.h, listen, &l);
    REQUIRE(r.release());
    l.standIn = r.surface;

    // onNativeWindowDestroyed: sokol_app makes no surface current and destroys its own (the stand-in).
    CHECK(fa_egl_handover_make_current(&r.h, r.display, nullptr, nullptr, nullptr));
    CHECK(fa_egl_handover_destroy_surface(&r.h, r.display, r.surface));
    r.surface = nullptr;  // sokol_app's EGL_NO_SURFACE
    REQUIRE(l.heard.size() == 1);
    CHECK(l.heard[0] == nullptr);
    CHECK(l.standInAlive[0]);  // the device heard before anything went
    CHECK(r.egl.live.empty());
    CHECK(r.h.state == 1);  // still released: the next window is the device's

    // onNativeWindowCreated: sokol_app asks a window surface of the new window and gets a stand-in.
    void* window2 = reinterpret_cast<void*>(0x5);
    r.surface = fa_egl_handover_create_window_surface(&r.h, r.display, r.config, window2, nullptr);
    REQUIRE(r.surface != nullptr);
    CHECK(r.egl.windowCreates == 1);  // no EGL window surface on it: the device's swapchain goes there
    REQUIRE(l.heard.size() == 2);
    CHECK(l.heard[1] == window2);
    CHECK(r.h.window == window2);
    CHECK(fa_egl_handover_make_current(&r.h, r.display, r.surface, r.surface, r.context));

    // The device lets go: sokol_app's surface comes back on the new window.
    fa_egl_handover_set_listener(&r.h, nullptr, nullptr);
    REQUIRE(r.restore());
    CHECK(r.h.state == 0);
    CHECK(r.egl.windowCreates == 2);
    CHECK(r.egl.live.size() == 1);
    CHECK(r.egl.draw == r.surface);
    CHECK(l.heard.size() == 2);
}

TEST_CASE("egl surface handover: a release ended while the activity has no window") {
    Rig r;
    REQUIRE(r.release());
    CHECK(fa_egl_handover_destroy_surface(&r.h, r.display, r.surface));  // no listener: nobody to tell
    r.surface = nullptr;
    REQUIRE(r.restore());
    CHECK(r.h.state == 0);
    CHECK(r.surface == nullptr);  // sokol_app makes its own surface on the next window
    void* window2 = reinterpret_cast<void*>(0x5);
    r.surface = fa_egl_handover_create_window_surface(&r.h, r.display, r.config, window2, nullptr);
    CHECK(r.egl.windowCreates == 2);  // the real call again
    CHECK(fa_egl_handover_swap_buffers(&r.h, r.display, r.surface));
    CHECK(r.egl.swaps == 1);
}

TEST_CASE("egl surface handover: a release needs a window surface") {
    Rig r;
    void* none = nullptr;
    CHECK_FALSE(
        fa_egl_handover_release(&r.h, r.display, r.config, r.context, nullptr, &r.surface, r.err, sizeof r.err));
    CHECK(std::string(r.err).find("no window") != std::string::npos);
    CHECK_FALSE(fa_egl_handover_release(&r.h, r.display, r.config, r.context, r.window, &none, r.err, sizeof r.err));
    CHECK(r.h.state == 0);
    CHECK(r.egl.finishes == 0);
}
