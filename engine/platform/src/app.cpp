// Windowed application shell on top of sokol_app (desktop + iOS/Android).
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <functional>
#include <memory>
#include <utility>
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "fa/platform/app.h"
#include "fa/platform/clipboard.h"
#include "fa/platform/gamepad.h"
#include "fa/platform/sokol_entry.h"
#if defined(__APPLE__)
#include "ime_apple.h"
#endif
#if defined(_WIN32)
#include "ime_win32.h"
#endif
#if defined(__linux__) && !defined(__ANDROID__)
#include "ime_linux.h"
#endif
#if defined(__EMSCRIPTEN__)
#include "ime_web.h"
#endif
#if defined(__APPLE__) && !TARGET_OS_IPHONE
#include "display_watchdog.h"
#endif
#include "mobile_impl.h"
#if defined(__ANDROID__)
#include <android/native_activity.h>

#include "activity_end.h"
#include "ime_android.h"
#endif
#include "d3d11_present.h"
#include "sokol_window.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"

#include "fa/core/fs.h"
#include "fa/core/log.h"
#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
#endif

// Linux with sokol_app's GLX window (M77-P9e3) and Android's EGL window (M77-P9e3b): the OpenGL surface leaves the window
// while a Vulkan device presents there (fa_sapp_gl_surface_release in sokol_impl.c). A Linux EGL window (SOKOL_FORCE_EGL,
// a GLES3 build) keeps it.
#if (defined(__linux__) && !defined(__ANDROID__) && defined(SOKOL_GLCORE) && !defined(SOKOL_FORCE_EGL)) ||             \
    defined(__ANDROID__)
#define FA_GL_WINDOW_HANDOVER 1
#endif

namespace fa {

static_assert(sizeof(sg_environment) <= sizeof(GfxEnvironment::storage), "GfxEnvironment storage too small");
static_assert(sizeof(sg_swapchain) <= sizeof(GfxSwapchain::storage), "GfxSwapchain storage too small");

namespace {

struct AppState {
    AppDesc desc;
    bool active = false;
    bool focused = true;  // pads are not polled while the window is in the background
    bool vsync = true;    // as asked for: AppDesc::vsync, then app_set_vsync
    bool borderlessWanted =
        false;  // full screen was asked for as "borderless" (Windows, Linux: the same window as "fullscreen")
    bool touchLogged = false;  // the first touch is logged once (the mobile smoke tests wait for it)
    int fbW = 0, fbH = 0;
    EdgeInsets insets;  // app_safe_insets(): asked of the platform at start, on resize and every few frames
    int framesToInsets = 0;
    bool quitFromApp = false;  // app_request_quit() was called and its QuitRequested event has not arrived yet
#if defined(__APPLE__) && !TARGET_OS_IPHONE
    std::unique_ptr<display_watchdog::Watchdog> watchdog;  // macOS test runs: skips when every display sleeps
#endif
    bool inQuitEvent = false;  // a QuitRequested event is being handled: app_cancel_quit() may act
    bool finishing = false;    // Android: app_request_quit() asked the system to finish the activity
    // Who makes the window's swapchain (window_presenter_step): the platform's, or a GPU device that claimed the window.
    WindowPresenter presenter = WindowPresenter::None;
    std::string deviceBackend;            // the backend that claimed the window ("" when none did)
    bool presenterRefusalLogged = false;  // app_gfx_environment() while a device has the window: said once
};
AppState g;

Key map_key(sapp_keycode k) {
    if (k >= SAPP_KEYCODE_A && k <= SAPP_KEYCODE_Z) return Key(int(Key::A) + (k - SAPP_KEYCODE_A));
    if (k >= SAPP_KEYCODE_0 && k <= SAPP_KEYCODE_9) return Key(int(Key::Num0) + (k - SAPP_KEYCODE_0));
    if (k >= SAPP_KEYCODE_KP_0 && k <= SAPP_KEYCODE_KP_9) return Key(int(Key::Num0) + (k - SAPP_KEYCODE_KP_0));
    if (k >= SAPP_KEYCODE_F1 && k <= SAPP_KEYCODE_F12) return Key(int(Key::F1) + (k - SAPP_KEYCODE_F1));
    switch (k) {
        case SAPP_KEYCODE_SPACE: return Key::Space;
        case SAPP_KEYCODE_ENTER:
        case SAPP_KEYCODE_KP_ENTER: return Key::Enter;
        case SAPP_KEYCODE_ESCAPE: return Key::Escape;
        case SAPP_KEYCODE_TAB: return Key::Tab;
        case SAPP_KEYCODE_BACKSPACE: return Key::Backspace;
        case SAPP_KEYCODE_INSERT: return Key::Insert;
        case SAPP_KEYCODE_DELETE: return Key::Delete;
        case SAPP_KEYCODE_LEFT: return Key::Left;
        case SAPP_KEYCODE_RIGHT: return Key::Right;
        case SAPP_KEYCODE_UP: return Key::Up;
        case SAPP_KEYCODE_DOWN: return Key::Down;
        case SAPP_KEYCODE_PAGE_UP: return Key::PageUp;
        case SAPP_KEYCODE_PAGE_DOWN: return Key::PageDown;
        case SAPP_KEYCODE_HOME: return Key::Home;
        case SAPP_KEYCODE_END: return Key::End;
        case SAPP_KEYCODE_LEFT_SHIFT: return Key::LeftShift;
        case SAPP_KEYCODE_RIGHT_SHIFT: return Key::RightShift;
        case SAPP_KEYCODE_LEFT_CONTROL: return Key::LeftControl;
        case SAPP_KEYCODE_RIGHT_CONTROL: return Key::RightControl;
        case SAPP_KEYCODE_LEFT_ALT: return Key::LeftAlt;
        case SAPP_KEYCODE_RIGHT_ALT: return Key::RightAlt;
        case SAPP_KEYCODE_LEFT_SUPER: return Key::LeftSuper;
        case SAPP_KEYCODE_RIGHT_SUPER: return Key::RightSuper;
        case SAPP_KEYCODE_MINUS:
        case SAPP_KEYCODE_KP_SUBTRACT: return Key::Minus;
        case SAPP_KEYCODE_EQUAL:
        case SAPP_KEYCODE_KP_EQUAL:
        case SAPP_KEYCODE_KP_ADD: return Key::Equal;
        case SAPP_KEYCODE_LEFT_BRACKET: return Key::LeftBracket;
        case SAPP_KEYCODE_RIGHT_BRACKET: return Key::RightBracket;
        case SAPP_KEYCODE_BACKSLASH: return Key::Backslash;
        case SAPP_KEYCODE_SEMICOLON: return Key::Semicolon;
        case SAPP_KEYCODE_APOSTROPHE: return Key::Apostrophe;
        case SAPP_KEYCODE_COMMA: return Key::Comma;
        case SAPP_KEYCODE_PERIOD:
        case SAPP_KEYCODE_KP_DECIMAL: return Key::Period;
        case SAPP_KEYCODE_SLASH:
        case SAPP_KEYCODE_KP_DIVIDE: return Key::Slash;
        case SAPP_KEYCODE_GRAVE_ACCENT: return Key::GraveAccent;
        default: return Key::Unknown;
    }
}

// Event position -> design coords. sokol_app reports mouse and touch positions in framebuffer pixels on every platform
// (it already multiplies by sapp_dpi_scale() where the system gives points: macOS, iOS, the web), so they go to
// to_design_coords as they are. Scaling them again put every click and tap off by the display scale (3x on an iPhone,
// 2x on a Retina Mac or a 200% Windows display).
Vec2 to_design(float x, float y) {
    Vec2 fb{x, y};
    return g.desc.to_design_coords ? g.desc.to_design_coords(fb) : fb;
}

void emit(AppEvent::Type type, int w = 0, int h = 0) {
    if (!g.desc.event) return;
    AppEvent e;
    e.type = type;
    e.width = w;
    e.height = h;
    g.desc.event(e);
}

// The system moves the notch with the rotation and the bars with the window, and says so late (or not at all): ask again
// a few times a second. Desktop windows have none and skip the call.
void refresh_insets() {
    g.framesToInsets = 15;
    if (app_is_mobile()) g.insets = mobile_safe_insets();
}

#if defined(__EMSCRIPTEN__)
// The page's hide and close signals. sokol_app raises neither as suspend/quit on the web (its quit is the "leave this site?"
// prompt, which only exists when asked for), so the shell listens itself: `visibilitychange` (a tab switch, a minimised
// window, a phone's app switcher) raises Suspended when the page becomes hidden and Resumed when it is shown again, and
// `pagehide` (the tab closing, a reload, leaving the site) raises QuitRequested. The page is going away, so a quit raised
// by pagehide cannot be cancelled: app_cancel_quit() does nothing for it. Each handler's work is followed by a copy of the
// save folder to IndexedDB (fs::flush_user_dir), so a storage.set made inside a handler is kept.
}  // namespace
// clang-format off
EM_JS(void, fa_web_install_lifecycle, (), {
    if (Module.faLifecycle) return;
    Module.faLifecycle = true;
    document.addEventListener('visibilitychange', () => {
        Module._fa_web_lifecycle(document.visibilityState === 'hidden' ? 0 : 1);
    });
    window.addEventListener('pagehide', () => { Module._fa_web_lifecycle(2); });
});
// clang-format on

namespace {
// kind: 0 the page became hidden, 1 it became visible, 2 the page is being closed.
void web_lifecycle(int kind) {
    if (!g.active) return;
    Input* in = g.desc.input;
    if (kind == 0) {
        g.focused = false;
        if (in) in->release_all();
        emit(AppEvent::Type::Suspended);
    } else if (kind == 1) {
        g.focused = true;
        emit(AppEvent::Type::Resumed);
    } else if (g.desc.event) {
        AppEvent q;
        q.type = AppEvent::Type::QuitRequested;
        g.desc.event(q);  // inQuitEvent stays false: the page cannot be kept open
    }
    fs::flush_user_dir();
}
}  // namespace
extern "C" EMSCRIPTEN_KEEPALIVE void fa_web_lifecycle(int kind) {
    web_lifecycle(kind);
}  // called by the page code above
namespace {
#endif

void on_init() {
    g.active = true;
    g.fbW = sapp_width();
    g.fbH = sapp_height();
    refresh_insets();
#if defined(__APPLE__)
    ime_apple_attach(
        g.desc.input);  // macOS and iOS: the input method composes into this Input while a TextField has the focus
#endif
#if defined(_WIN32)
    ime_win32_attach(g.desc.input);  // Windows: the same, through IMM32 on sokol_app's window
#endif
#if defined(__linux__) && !defined(__ANDROID__)
    ime_linux_attach(g.desc.input);  // Linux: the same, through XIM on sokol_app's X11 window
#endif
#if defined(__ANDROID__)
    ime_android_attach(true);  // Android: the keyboard's composition, through an InputConnection (ime_android.cpp)
#endif
#if defined(__EMSCRIPTEN__)
    fa_sapp_web_route_events();    // the web: the keys the browser's input method takes are not the game's
    ime_web_attach(g.desc.input);  // and its compositions go to this Input, through a hidden <input>
#endif
    if (const AppIconImage& dock = g.desc.dockIcon;
        dock.width > 0 && dock.height > 0 && dock.rgba.size() == std::size_t(dock.width) * std::size_t(dock.height) * 4)
        fa_sapp_set_dock_icon(dock.rgba.data(), dock.width, dock.height);  // macOS only; NSApp exists from here on
    if (!g.desc.appName.empty()) fa_sapp_set_class_name(g.desc.appName.c_str());  // Linux only
#if defined(__EMSCRIPTEN__)
    // The browser decides when a paste happens: a TextField pastes on the paste event, not on the V key.
    if (g.desc.input) g.desc.input->set_paste_from_events(true);
    fa_web_install_lifecycle();
#endif
#if defined(__ANDROID__)
    android_end_attach();  // from here on a destroyed activity runs the game's end on this thread (activity_end_android.cpp)
#endif
    if (g.desc.init) g.desc.init();
}

void on_frame() {
#if defined(__APPLE__) && !TARGET_OS_IPHONE
    if (g.watchdog) g.watchdog->frame();
#endif
    double dt = sapp_frame_duration();
    if (!(dt > 0.0)) dt = 1.0 / 60.0;
    dt = std::min(dt, 0.25);
    if (g.desc.input && g.focused) {
        poll_gamepads(*g.desc.input);  // pads have no events: read them before the game runs
        refresh_gamepad_rumble_support(
            *g.desc.input);  // a pad that just connected answers canRumble in this frame already
    }
    if (g.desc.input)
        mobile_poll(*g.desc.input);  // Android: keys, typed characters and the Back button of the input queue
    if (--g.framesToInsets <= 0) refresh_insets();
#if defined(FA_D3D11_PRESENTER)
    // Windows: sokol_app has no graphics API (sokol_impl.c), so the window's swapchain follows the framebuffer size here
    // and the frame is presented after the game drew it. No presenter yet (the game has not asked for its device, or draws
    // with D3D12 or Vulkan on its own swapchain): nothing to do. A presenter whose views could not be made again (a
    // failed resize) is still resized every frame, which makes them again; it presents only with its views (valid()).
    if (d3d11::Presenter* live = d3d11::window_presenter_live()) live->resize(sapp_width(), sapp_height());
#endif
    if (g.desc.frame) g.desc.frame(dt);
#if defined(FA_D3D11_PRESENTER)
    // Asked again: the frame may have made it (its first app_gfx_environment()) or released it (a D3D12 or Vulkan renderer
    // claimed the window).
    if (d3d11::Presenter* presenter = d3d11::window_presenter()) {
        const int interval = g.vsync ? std::max(1, sapp_query_desc().swap_interval) : 0;
        presenter->present(interval, d3d11::in_modal_move_size_loop());
    }
#endif
}

#if !(defined(__ANDROID__) ||                                                                                          \
      (defined(__APPLE__) && TARGET_OS_IPHONE))  // phones never reach run_app() or the macOS exit below
int exit_code() { return g.desc.exit_code ? g.desc.exit_code() : 0; }
#endif

#if defined(FA_GL_WINDOW_HANDOVER)
// sokol_app's OpenGL surface back on the window after a device let it go (nothing when it never left).
void restore_gl_surface() {
    if (fa_sapp_gl_surface_state() == 0) return;
    char why[512];
    if (!fa_sapp_gl_surface_restore(why, sizeof why))
        FA_ERROR("platform", "The window's OpenGL surface could not come back: {}", why);
}
#endif

void on_cleanup() {
#if defined(__APPLE__) && !TARGET_OS_IPHONE
    g.watchdog.reset();
#endif
#if defined(__APPLE__)
    ime_apple_attach(nullptr);
#endif
#if defined(_WIN32)
    ime_win32_attach(nullptr);
#endif
#if defined(__linux__) && !defined(__ANDROID__)
    ime_linux_attach(nullptr);
#endif
#if defined(__EMSCRIPTEN__)
    ime_web_attach(nullptr);
#endif
#if defined(__ANDROID__)
    ime_android_attach(false);
#endif
    if (g.desc.cleanup) g.desc.cleanup();
#if defined(FA_D3D11_PRESENTER)
    d3d11::window_presenter_release();  // after sg_shutdown(): sokol_gfx used its device
#endif
#if defined(FA_GL_WINDOW_HANDOVER)
    // A device that still had the window (a host that did not call app_release_native_window()) is gone with the app's
    // cleanup: sokol_app's shutdown then finds the state it made, a window surface, and destroys it.
    app_set_native_window_listener({});
    restore_gl_surface();
#endif
    g.presenter = WindowPresenter::None;
    g.deviceBackend.clear();
    g.active = false;
#if defined(__APPLE__) && !TARGET_OS_IPHONE
    // macOS: sapp_run() does not return; Cocoa ends the process with 0 right after this callback. Use our code instead.
    std::exit(exit_code());
#endif
}

void on_event(const sapp_event* e) {
    Input* in = g.desc.input;
    switch (e->type) {
        case SAPP_EVENTTYPE_KEY_DOWN:
        case SAPP_EVENTTYPE_KEY_UP:
            if (in && !(e->type == SAPP_EVENTTYPE_KEY_DOWN && e->key_repeat))
                in->on_key(map_key(e->key_code), e->type == SAPP_EVENTTYPE_KEY_DOWN);
            break;
        case SAPP_EVENTTYPE_CHAR:
            if (in && e->char_code >= 32 && e->char_code != 127) in->on_text(e->char_code);
            break;
        case SAPP_EVENTTYPE_MOUSE_MOVE:
            if (in) {
                in->on_mouse_move(to_design(e->mouse_x, e->mouse_y));
                if (sapp_mouse_locked()) in->on_mouse_delta({e->mouse_dx, e->mouse_dy});  // the position is frozen then
            }
            break;
        case SAPP_EVENTTYPE_MOUSE_DOWN:
        case SAPP_EVENTTYPE_MOUSE_UP:
            if (in) {
                in->on_mouse_move(to_design(e->mouse_x, e->mouse_y));
                MouseButton b = MouseButton::Left;
                if (e->mouse_button == SAPP_MOUSEBUTTON_RIGHT)
                    b = MouseButton::Right;
                else if (e->mouse_button == SAPP_MOUSEBUTTON_MIDDLE)
                    b = MouseButton::Middle;
                else if (e->mouse_button != SAPP_MOUSEBUTTON_LEFT)
                    break;
                in->on_mouse_button(b, e->type == SAPP_EVENTTYPE_MOUSE_DOWN);
            }
            break;
        case SAPP_EVENTTYPE_MOUSE_SCROLL:
            if (in) in->on_mouse_wheel(e->scroll_y);
            break;
        case SAPP_EVENTTYPE_TOUCHES_BEGAN:
        case SAPP_EVENTTYPE_TOUCHES_MOVED:
        case SAPP_EVENTTYPE_TOUCHES_ENDED:
        case SAPP_EVENTTYPE_TOUCHES_CANCELLED:
            if (in) {
                for (int i = 0; i < e->num_touches; ++i) {
                    const sapp_touchpoint& t = e->touches[i];
                    if (!t.changed) continue;
                    std::uint64_t id = std::uint64_t(t.identifier);
                    Vec2 p = to_design(t.pos_x, t.pos_y);
                    if (!g.touchLogged && e->type == SAPP_EVENTTYPE_TOUCHES_BEGAN) {
                        g.touchLogged = true;
                        FA_INFO("input", "first touch at design ({:.0f}, {:.0f}), {} finger(s) down", p.x, p.y,
                                e->num_touches);
                    }
                    // Input mirrors the first finger onto the mouse (see Input::on_touch_begin).
                    if (e->type == SAPP_EVENTTYPE_TOUCHES_BEGAN)
                        in->on_touch_begin(id, p);
                    else if (e->type == SAPP_EVENTTYPE_TOUCHES_MOVED)
                        in->on_touch_move(id, p);
                    else {
                        in->on_touch_move(id, p);  // the lift position: the mouse button is released there
                        in->on_touch_end(id);
                    }
                }
            }
            break;
        case SAPP_EVENTTYPE_RESIZED:
            g.fbW = e->framebuffer_width;
            g.fbH = e->framebuffer_height;
            refresh_insets();
            emit(AppEvent::Type::Resized, e->framebuffer_width, e->framebuffer_height);
            break;
        case SAPP_EVENTTYPE_UNFOCUSED:
        case SAPP_EVENTTYPE_ICONIFIED:
            g.focused = false;
            if (in) in->release_all();
            emit(AppEvent::Type::FocusLost);
            break;
        case SAPP_EVENTTYPE_FOCUSED:
        case SAPP_EVENTTYPE_RESTORED:
            g.focused = true;
            emit(AppEvent::Type::FocusGained);
            break;
        case SAPP_EVENTTYPE_SUSPENDED:
            g.focused = false;
            if (in) in->release_all();
            emit(AppEvent::Type::Suspended);
            break;
        case SAPP_EVENTTYPE_RESUMED:
            g.focused = true;
            emit(AppEvent::Type::Resumed);
            break;
        case SAPP_EVENTTYPE_QUIT_REQUESTED: {
            // The handler may call app_cancel_quit() when the player (not the app) asked; default: quit.
            AppEvent q;
            q.type = AppEvent::Type::QuitRequested;
            q.fromApp = g.quitFromApp;
            g.quitFromApp = false;
            g.inQuitEvent = true;
            if (g.desc.event) g.desc.event(q);
            g.inQuitEvent = false;
            break;
        }
        case SAPP_EVENTTYPE_CLIPBOARD_PASTED:
            // The web hands the pasted text to sokol_app (app_clipboard_get reads it); a focused TextField pastes on this.
            if (in) in->on_paste();
            break;
        case SAPP_EVENTTYPE_FILES_DROPPED: emit(AppEvent::Type::FilesDropped); break;
        default: break;
    }
}

}  // namespace

int fill_sapp_icon(sapp_icon_desc& out, const std::vector<AppIconImage>& images) {
    int count = 0;
    for (const AppIconImage& image : images) {
        if (count >= SAPP_MAX_ICONIMAGES) break;
        const std::size_t bytes = std::size_t(std::max(image.width, 0)) * std::size_t(std::max(image.height, 0)) * 4;
        if (bytes == 0 || image.rgba.size() != bytes) continue;
        out.images[count].width = image.width;
        out.images[count].height = image.height;
        out.images[count].pixels.ptr = image.rgba.data();
        out.images[count].pixels.size = bytes;
        ++count;
    }
    return count;
}

sapp_desc to_sapp_desc(const AppDesc& desc) {
    g.desc = desc;
#if defined(__APPLE__) && !TARGET_OS_IPHONE
    // A test run (the editor autotest, a ctest player) on a Mac whose displays all sleep never gets a frame: skip it with
    // exit code 77 instead of waiting for ever. sokol_app calls init_cb only with the first frame, so it starts here.
    const display_watchdog::EnvLookup env = [](const char* name) { return std::getenv(name); };
    if (!g.watchdog && display_watchdog::wanted(env)) {
        display_watchdog::Options options;
        options.ignoreSleep = display_watchdog::ignore_sleep(env);
        options.fakeNoFrames = display_watchdog::fake_asleep(env);  // the fake also holds back the frames that do come
        // FA_TEST_DISPLAY_IDLE_SECONDS (0.2 to 600): a shorter wait for the test of the watchdog itself.
        if (const char* idle = std::getenv("FA_TEST_DISPLAY_IDLE_SECONDS")) {
            const double seconds = std::atof(idle);
            if (seconds >= 0.2 && seconds <= 600.0) {
                options.idleSeconds = seconds;
                options.pollSeconds = std::min(1.0, seconds / 4.0);
            }
        }
        g.watchdog = std::make_unique<display_watchdog::Watchdog>(std::move(options));
    }
#endif
    g.focused = true;
    g.vsync = desc.vsync;
    sapp_desc s{};
    s.init_cb = on_init;
    s.frame_cb = on_frame;
    s.cleanup_cb = on_cleanup;
    s.event_cb = on_event;
    s.width = desc.width;
    s.height = desc.height;
    s.sample_count = std::max(1, desc.sampleCount);
    // swap_interval 0 means "default" (1) to sokol_app, so vsync off has to be asked for with these two.
    s.disable_vsync = !desc.vsync;
    s.metal.disable_display_sync = !desc.vsync;
    s.high_dpi = desc.highDpi;
    s.fullscreen = desc.fullscreen;
    s.window_title = g.desc.title.c_str();  // owned by g.desc, which outlives sapp_run
#if defined(_WIN32) || (defined(__linux__) && !defined(__ANDROID__))
    // The window icon: sokol_app sets it on Windows and Linux (macOS would replace the Dock icon of the app bundle, which
    // is better made than a plain image; mobile has no window icon). The pixels are owned by g.desc, like the title.
    fill_sapp_icon(s.icon, g.desc.icon);
#endif
    s.enable_clipboard = true;  // clipboard.* and a TextField's Ctrl+V / Ctrl+C (fa/platform/clipboard.h)
    s.clipboard_size = 1 << 20;
    s.enable_dragndrop = true;
    s.max_dropped_files = 8;
    s.depth_format = SAPP_PIXELFORMAT_DEPTH_STENCIL;
    s.logger.func = fa_sokol_log_func;
#if defined(__ANDROID__)
    s.android.native_event_cb =
        mobile_native_event;  // pads, keys and Back: see gamepad_android.cpp, mobile_android.cpp
    // sokol_app asks for an OpenGL ES 3.1 context on Android by default. The engine's shaders are GLSL ES 3.00 and
    // use no 3.1 feature, but not every GL stack offers 3.1 (the emulator's software GPU is 3.0: eglCreateContext
    // fails with EGL_BAD_CONFIG and sokol aborts at startup), so ask for 3.0; drivers may still return a newer context.
    s.gl.major_version = 3;
    s.gl.minor_version = 0;
#endif
    return s;
}

int run_app(const AppDesc& desc) {
#if defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
    FA_ERROR("platform", "run_app() is not available on mobile: sokol_app owns the entry point. "
                         "Define sokol_main() and return fa::to_sapp_desc(appDesc) (see fa/platform/sokol_entry.h).");
    return 1;
#else
    sapp_desc s = to_sapp_desc(desc);
    sapp_run(&s);
    return exit_code();
#endif
}

bool gfx_device_active() { return sg_isvalid(); }

GfxEnvironment app_gfx_formats() {
    GfxEnvironment out{};
#if defined(FA_D3D11_PRESENTER)
    // What the D3D11 presenter's environment() says before it has a device: BGRA8, a depth-stencil buffer when the window
    // asked for one, its sample count.
    sg_environment env{};
    env.defaults.color_format = SG_PIXELFORMAT_BGRA8;
    const bool depth = !sapp_isvalid() || sapp_depth_format() != SAPP_PIXELFORMAT_NONE;
    env.defaults.depth_format = depth ? SG_PIXELFORMAT_DEPTH_STENCIL : SG_PIXELFORMAT_NONE;
    env.defaults.sample_count = sapp_isvalid() ? std::max(1, sapp_sample_count()) : 1;
#else
    sg_environment env = sglue_environment();
#endif
    static_assert(sizeof(env) <= sizeof(out.storage));
    std::memcpy(out.storage, &env, sizeof(env));
    return out;
}

GfxEnvironment app_gfx_environment() {
    const WindowPresenterStep step =
        window_presenter_step(g.presenter, WindowPresenterEvent::PlatformAsked, gfx_device_active(), "");
    if (!step.error.empty()) {
        if (!g.presenterRefusalLogged)
            FA_ERROR("platform", "app_gfx_environment(): the {} renderer has the window: {}", g.deviceBackend,
                     step.error);
        g.presenterRefusalLogged = true;
        return app_gfx_formats();  // no device in it: sg_setup() fails
    }
    g.presenter = step.next;
#if defined(FA_D3D11_PRESENTER)
    // The window's D3D11 device, made on the first call (d3d11_present_win32.cpp). Without one (no Direct3D 11, the error
    // was logged) the environment has a null device and sg_setup() fails the way it did when sokol_app could not make it.
    if (const d3d11::Presenter* p = d3d11::window_presenter_ensure()) return p->environment();
    return d3d11::Presenter().environment();
#else
    return app_gfx_formats();
#endif
}

GfxSwapchain app_gfx_swapchain() {
    if (g.presenter == WindowPresenter::Device) {
        // A D3D12 or Vulkan device presents into the window: there are no platform views to hand out (and on macOS taking
        // sokol_app's next drawable would take one of the layer's from that device).
        GfxSwapchain out{};
        sg_swapchain sc{};
        sc.invalid = true;  // sokol_gfx skips the pass
        static_assert(sizeof(sc) <= sizeof(out.storage));
        std::memcpy(out.storage, &sc, sizeof(sc));
        return out;
    }
#if defined(FA_D3D11_PRESENTER)
    if (const d3d11::Presenter* p = d3d11::window_presenter()) return p->swapchain();
    return d3d11::Presenter().swapchain();  // invalid: sokol_gfx skips the pass
#else
    GfxSwapchain out{};
    sg_swapchain sc = sglue_swapchain();
    // HDR10 (hdr_output.cpp): sokol_app knows only its 8-bit and 16-bit float formats, so the 10-bit one is said here.
    if (fa_sapp_swapchain_kind() == 2) sc.color_format = SG_PIXELFORMAT_RGB10A2;
    std::memcpy(out.storage, &sc, sizeof(sc));
    return out;
#endif
}

NativeWindow app_native_window() {
    NativeWindow out;
#if (defined(SOKOL_GLCORE) || defined(SOKOL_GLES3)) && !defined(FA_GL_WINDOW_HANDOVER)
    // A Linux EGL window, the web: sokol_app's OpenGL surface stays on the window.
    out.busy = "sokol_app made an OpenGL context on this window and swaps its buffers after every frame, so a Vulkan "
               "device cannot make its own swapchain on it (hint: this build draws its window with OpenGL; leave "
               "render.backend on auto here, or run headless)";
#endif
    void* window = nullptr;
    void* display = nullptr;
    if (sapp_isvalid() && fa_sapp_native_window(&window, &display)) {
        out.window = window;
        out.display = display;
    } else if (out.busy.empty()) {
        out.busy = "there is no native window to make a swapchain on (no window yet, or this platform hands none: iOS, "
                   "the web) (hint: leave render.backend on auto here, or run headless)";
    }
    return out;
}

Result<NativeWindow> app_claim_native_window(const std::string& backend) {
    NativeWindow handles = app_native_window();
    const WindowPresenterStep step =
        window_presenter_step(g.presenter, WindowPresenterEvent::DeviceClaim, gfx_device_active(), handles.busy);
    if (!step.error.empty())
        return make_error("the window cannot be handed to the " + backend + " device: " + step.error);
#if defined(FA_GL_WINDOW_HANDOVER)
    // sokol_app's GLX or EGL surface is on the window from its start, whatever the presenter state says (None too: the
    // runner opened no sokol context), so it leaves on every claim. A driver that refuses keeps the window on OpenGL and the
    // claim fails with its reason (the engine falls back to OpenGL in process and reports it).
    {
        char why[512];
        if (!fa_sapp_gl_surface_release(why, sizeof why))
            return make_error("the window cannot be handed to the " + backend + " device: " + why);
        if (fa_sapp_gl_surface_state() == 2)
            FA_INFO("platform", "The window's OpenGL context waits for the {} device with no drawable (no pbuffer: {})",
                    backend, why);
        else
            FA_INFO("platform", "The window's OpenGL context waits for the {} device on a 1x1 pbuffer", backend);
    }
#endif
    if (step.releasePlatform) {
#if defined(FA_D3D11_PRESENTER)
        // One flip-model swapchain per HWND: the D3D11 presenter's goes (ClearState + Flush release it at once) before the
        // device makes its own. A later app_gfx_environment() makes a new presenter (the fallback to D3D11).
        d3d11::window_presenter_release();
#endif
    }
    g.presenter = step.next;
    g.deviceBackend = backend;
    g.presenterRefusalLogged = false;
    return handles;
}

#if defined(FA_GL_WINDOW_HANDOVER)
namespace {
std::function<void(const void*)>& window_listener() {
    static std::function<void(const void*)> listener;
    return listener;
}
// sokol_impl.c's listener: on sokol_app's loop thread, the frame thread (no lock: nothing else touches it).
void hear_native_window(void* window, void*) {
    if (window_listener()) window_listener()(window);
}
}  // namespace
#endif

void app_set_native_window_listener(std::function<void(const void* window)> listener) {
#if defined(FA_GL_WINDOW_HANDOVER)
    window_listener() = std::move(listener);
    fa_sapp_gl_surface_set_window_listener(window_listener() ? hear_native_window : nullptr, nullptr);
#else
    (void)listener;  // the window lives as long as the app: nothing to hear
#endif
}

void app_release_native_window() {
#if defined(FA_GL_WINDOW_HANDOVER)
    app_set_native_window_listener({});  // the device has no swapchain to remake any more
#endif
    const WindowPresenterStep step =
        window_presenter_step(g.presenter, WindowPresenterEvent::DeviceRelease, gfx_device_active(), "");
    if (g.presenter == WindowPresenter::Device) g.deviceBackend.clear();
    g.presenter = step.next;
    g.presenterRefusalLogged = false;
#if defined(FA_GL_WINDOW_HANDOVER)
    restore_gl_surface();  // the device's swapchain is gone: sokol_app's OpenGL surface goes back on the window
#endif
}

WindowPresenter app_window_presenter() { return g.presenter; }
std::string app_window_device_backend() { return g.presenter == WindowPresenter::Device ? g.deviceBackend : ""; }

bool app_read_window_back_buffer(int width, int height, std::uint8_t* rgba) {
#if defined(FA_D3D11_PRESENTER)
    const d3d11::Presenter* p = d3d11::window_presenter();
    return p && p->read_back_buffer(width, height, rgba);
#else
    (void)width;
    (void)height;
    (void)rgba;
    return false;
#endif
}

int app_framebuffer_width() { return sapp_isvalid() ? sapp_width() : g.fbW; }
int app_framebuffer_height() { return sapp_isvalid() ? sapp_height() : g.fbH; }
float app_dpi_scale() { return sapp_isvalid() ? sapp_dpi_scale() : 1.0f; }
void app_request_quit() {
#if defined(__ANDROID__)
    // sokol_app never reads a quit request on Android: finish the activity instead (once; the call only posts to Android's
    // main thread). The system destroys it, and the onDestroy wrapper of sokol_impl.c sends AppEvent::Type::Ending.
    if (g.finishing) return;
    g.finishing = true;
    if (const void* activity = sapp_android_get_native_activity())
        ANativeActivity_finish(static_cast<ANativeActivity*>(const_cast<void*>(activity)));
#else
    g.quitFromApp = true;
    sapp_request_quit();
#endif
}
void app_cancel_quit() {
    if (g.inQuitEvent) sapp_cancel_quit();
}

bool app_clipboard_supported() { return !app_is_mobile(); }
std::string app_clipboard_get() {
    if (app_is_mobile() || !sapp_isvalid()) return {};
    const char* text = sapp_get_clipboard_string();
    return text ? std::string(text) : std::string();
}
void app_clipboard_set(const std::string& text) {
    if (app_is_mobile() || !sapp_isvalid()) return;
    sapp_set_clipboard_string(text.c_str());
}

namespace {
class SystemClipboard final : public Clipboard {
public:
    bool supported() const override { return app_clipboard_supported(); }
    std::string get() override { return app_clipboard_get(); }
    void set(const std::string& text) override { app_clipboard_set(text); }
};
}  // namespace

Clipboard& system_clipboard() {
    static SystemClipboard clipboard;
    return clipboard;
}
void app_set_title(const std::string& title) { sapp_set_window_title(title.c_str()); }
void app_show_mouse(bool show) { sapp_show_mouse(show); }
void app_lock_mouse(bool lock) { sapp_lock_mouse(lock); }
void app_show_keyboard(bool show) { mobile_show_keyboard(show); }
EdgeInsets app_safe_insets() { return g.insets; }
void app_vibrate(float seconds) { mobile_vibrate(seconds); }

bool app_is_fullscreen() { return app_is_mobile() || sapp_is_fullscreen(); }
void app_set_fullscreen(bool on) {
    if (!app_is_mobile() && sapp_is_fullscreen() != on) sapp_toggle_fullscreen();
}

namespace {
// macOS is the one desktop OS where "full screen" (a native Space) and "borderless" (a window over the monitor) differ.
constexpr bool kNativeFullscreenSpace =
#if defined(__APPLE__)
    true;
#else
    false;
#endif
}  // namespace

bool app_has_window_modes() {
#if defined(__EMSCRIPTEN__)
    return false;
#else
    return !app_is_mobile();
#endif
}

WindowMode app_window_mode() {
    if (app_is_mobile()) return WindowMode::Fullscreen;
    if constexpr (kNativeFullscreenSpace) {
        if (fa_sapp_is_borderless()) return WindowMode::Borderless;
    }
    if (!sapp_is_fullscreen()) {
        g.borderlessWanted = false;
        return WindowMode::Windowed;
    }
    return g.borderlessWanted && !kNativeFullscreenSpace ? WindowMode::Borderless : WindowMode::Fullscreen;
}

std::string app_set_window_mode(WindowMode mode) {
    if (app_is_mobile())
        return mode == WindowMode::Fullscreen ? std::string() : "phones and tablets always run full screen";
    const WindowMode now = app_window_mode();
    if (now == mode) return {};
    if constexpr (kNativeFullscreenSpace) {
        if (mode == WindowMode::Borderless && now == WindowMode::Fullscreen)
            return "macOS full screen is a Space of its own that takes a moment to leave: call "
                   "window.setMode(\"windowed\"), "
                   "wait a second, then window.setMode(\"borderless\")";
        if (now == WindowMode::Borderless) fa_sapp_set_borderless(false);
        if (mode == WindowMode::Borderless) {
            if (!fa_sapp_set_borderless(true)) return "this window cannot go borderless right now";
        } else if (sapp_is_fullscreen() != (mode == WindowMode::Fullscreen)) {
            sapp_toggle_fullscreen();
        }
        return {};
    }
    // Windows, Linux (and the web's canvas): one full screen window that covers its monitor, so borderless and full screen
    // are the same window; the mode only remembers which one was asked for.
    g.borderlessWanted = mode == WindowMode::Borderless;
    if (sapp_is_fullscreen() != (mode != WindowMode::Windowed)) sapp_toggle_fullscreen();
    return {};
}

std::vector<MonitorInfo> app_monitors() {
    std::vector<MonitorInfo> list;
    if (app_is_mobile()) return list;
    fa_sapp_monitor raw[16];
    const int n = fa_sapp_monitors(raw, 16);
    for (int i = 0; i < n; ++i) {
        MonitorInfo m;
        m.name = raw[i].name;
        m.x = raw[i].x;
        m.y = raw[i].y;
        m.width = raw[i].w;
        m.height = raw[i].h;
        m.primary = raw[i].primary;
        m.current = raw[i].current;
        m.refreshHz = raw[i].refresh_hz >= 1.5 && raw[i].refresh_hz <= 1000.0 ? raw[i].refresh_hz : 0.0;
        list.push_back(std::move(m));
    }
    return list;
}

double app_display_refresh_hz() {
#if defined(__ANDROID__)
    const double hz = mobile_display_refresh_hz();
#else
    const double hz = fa_sapp_display_refresh_hz();
#endif
    return hz >= 1.5 && hz <= 1000.0 ? hz : 0.0;  // NaN and nonsense are "unknown" too
}

bool app_move_to_monitor(int index) { return !app_is_mobile() && fa_sapp_move_to_monitor(index); }

void app_window_size(int& width, int& height) { fa_sapp_window_size(&width, &height); }
bool app_display_size(int& width, int& height) { return fa_sapp_display_size(&width, &height); }
bool app_set_window_size(int width, int height) {
    return !app_is_mobile() && fa_sapp_set_window_size(std::max(width, 1), std::max(height, 1));
}

bool app_vsync() { return app_is_mobile() || g.vsync; }  // a phone's display always syncs
bool app_set_vsync(bool on) {
    // A D3D12 or Vulkan device presents into the window with its own swapchain's present mode: the platform's vsync
    // switch does not reach it.
    if (app_is_mobile() || g.presenter == WindowPresenter::Device || !fa_sapp_set_vsync(on)) return false;
    g.vsync = on;
    return true;
}

#if defined(__ANDROID__)
void app_android_end() {
    if (g.active) emit(AppEvent::Type::Ending);
}
#endif

bool app_is_mobile() {
#if defined(__ANDROID__)
    return true;
#elif defined(__APPLE__)
    return TARGET_OS_IPHONE != 0;
#else
    return false;
#endif
}

}  // namespace fa
