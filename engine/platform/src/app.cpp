// Windowed application shell on top of sokol_app (desktop + iOS/Android).
#include <algorithm>
#include <cstring>
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "fa/platform/app.h"
#include "fa/platform/sokol_entry.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"

#include "fa/core/log.h"

namespace fa {

static_assert(sizeof(sg_environment) <= sizeof(GfxEnvironment::storage), "GfxEnvironment storage too small");
static_assert(sizeof(sg_swapchain) <= sizeof(GfxSwapchain::storage), "GfxSwapchain storage too small");

namespace {

struct AppState {
    AppDesc desc;
    bool active = false;
    int fbW = 0, fbH = 0;
    bool primaryTouchDown = false;
    std::uint64_t primaryTouchId = 0;
};
AppState g;

Key map_key(sapp_keycode k) {
    if (k >= SAPP_KEYCODE_A && k <= SAPP_KEYCODE_Z) return Key(int(Key::A) + (k - SAPP_KEYCODE_A));
    if (k >= SAPP_KEYCODE_0 && k <= SAPP_KEYCODE_9) return Key(int(Key::Num0) + (k - SAPP_KEYCODE_0));
    if (k >= SAPP_KEYCODE_KP_0 && k <= SAPP_KEYCODE_KP_9) return Key(int(Key::Num0) + (k - SAPP_KEYCODE_KP_0));
    if (k >= SAPP_KEYCODE_F1 && k <= SAPP_KEYCODE_F12) return Key(int(Key::F1) + (k - SAPP_KEYCODE_F1));
    switch (k) {
        case SAPP_KEYCODE_SPACE: return Key::Space;
        case SAPP_KEYCODE_ENTER: case SAPP_KEYCODE_KP_ENTER: return Key::Enter;
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
        case SAPP_KEYCODE_MINUS: case SAPP_KEYCODE_KP_SUBTRACT: return Key::Minus;
        case SAPP_KEYCODE_EQUAL: case SAPP_KEYCODE_KP_EQUAL: case SAPP_KEYCODE_KP_ADD: return Key::Equal;
        case SAPP_KEYCODE_LEFT_BRACKET: return Key::LeftBracket;
        case SAPP_KEYCODE_RIGHT_BRACKET: return Key::RightBracket;
        case SAPP_KEYCODE_BACKSLASH: return Key::Backslash;
        case SAPP_KEYCODE_SEMICOLON: return Key::Semicolon;
        case SAPP_KEYCODE_APOSTROPHE: return Key::Apostrophe;
        case SAPP_KEYCODE_COMMA: return Key::Comma;
        case SAPP_KEYCODE_PERIOD: case SAPP_KEYCODE_KP_DECIMAL: return Key::Period;
        case SAPP_KEYCODE_SLASH: case SAPP_KEYCODE_KP_DIVIDE: return Key::Slash;
        case SAPP_KEYCODE_GRAVE_ACCENT: return Key::GraveAccent;
        default: return Key::Unknown;
    }
}

// Window-pixel position (logical, as reported by sokol events) -> design coords.
Vec2 to_design(float x, float y) {
    Vec2 fb{x * sapp_dpi_scale(), y * sapp_dpi_scale()};
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

void on_init() {
    g.active = true;
    g.fbW = sapp_width();
    g.fbH = sapp_height();
    if (g.desc.init) g.desc.init();
}

void on_frame() {
    double dt = sapp_frame_duration();
    if (!(dt > 0.0)) dt = 1.0 / 60.0;
    dt = std::min(dt, 0.25);
    if (g.desc.frame) g.desc.frame(dt);
}

void on_cleanup() {
    if (g.desc.cleanup) g.desc.cleanup();
    g.active = false;
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
            if (in) in->on_mouse_move(to_design(e->mouse_x, e->mouse_y));
            break;
        case SAPP_EVENTTYPE_MOUSE_DOWN:
        case SAPP_EVENTTYPE_MOUSE_UP:
            if (in) {
                in->on_mouse_move(to_design(e->mouse_x, e->mouse_y));
                MouseButton b = MouseButton::Left;
                if (e->mouse_button == SAPP_MOUSEBUTTON_RIGHT) b = MouseButton::Right;
                else if (e->mouse_button == SAPP_MOUSEBUTTON_MIDDLE) b = MouseButton::Middle;
                else if (e->mouse_button != SAPP_MOUSEBUTTON_LEFT) break;
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
                    // Touch also drives the mouse (first finger = left button) so
                    // mouse-based UI and scripts work on mobile unchanged.
                    if (e->type == SAPP_EVENTTYPE_TOUCHES_BEGAN) {
                        in->on_touch_begin(id, p);
                        if (!g.primaryTouchDown) {
                            g.primaryTouchDown = true;
                            g.primaryTouchId = id;
                            in->on_mouse_move(p);
                            in->on_mouse_button(MouseButton::Left, true);
                        }
                    } else if (e->type == SAPP_EVENTTYPE_TOUCHES_MOVED) {
                        in->on_touch_move(id, p);
                        if (g.primaryTouchDown && g.primaryTouchId == id) in->on_mouse_move(p);
                    } else {
                        in->on_touch_end(id);
                        if (g.primaryTouchDown && g.primaryTouchId == id) {
                            g.primaryTouchDown = false;
                            in->on_mouse_move(p);
                            in->on_mouse_button(MouseButton::Left, false);
                        }
                    }
                }
            }
            break;
        case SAPP_EVENTTYPE_RESIZED:
            g.fbW = e->framebuffer_width;
            g.fbH = e->framebuffer_height;
            emit(AppEvent::Type::Resized, e->framebuffer_width, e->framebuffer_height);
            break;
        case SAPP_EVENTTYPE_UNFOCUSED:
        case SAPP_EVENTTYPE_ICONIFIED:
            if (in) in->release_all();
            emit(AppEvent::Type::FocusLost);
            break;
        case SAPP_EVENTTYPE_FOCUSED:
        case SAPP_EVENTTYPE_RESTORED:
            emit(AppEvent::Type::FocusGained);
            break;
        case SAPP_EVENTTYPE_SUSPENDED:
            if (in) in->release_all();
            emit(AppEvent::Type::Suspended);
            break;
        case SAPP_EVENTTYPE_RESUMED:
            emit(AppEvent::Type::Resumed);
            break;
        case SAPP_EVENTTYPE_QUIT_REQUESTED:
            emit(AppEvent::Type::QuitRequested);  // the handler may call app_request_quit()/cancel; default: quit
            break;
        case SAPP_EVENTTYPE_FILES_DROPPED:
            emit(AppEvent::Type::FilesDropped);
            break;
        default:
            break;
    }
}

}  // namespace

sapp_desc to_sapp_desc(const AppDesc& desc) {
    g.desc = desc;
    sapp_desc s{};
    s.init_cb = on_init;
    s.frame_cb = on_frame;
    s.cleanup_cb = on_cleanup;
    s.event_cb = on_event;
    s.width = desc.width;
    s.height = desc.height;
    s.sample_count = std::max(1, desc.sampleCount);
    s.swap_interval = desc.vsync ? 1 : 0;
    s.high_dpi = desc.highDpi;
    s.fullscreen = desc.fullscreen;
    s.window_title = g.desc.title.c_str();  // owned by g.desc, which outlives sapp_run
    s.enable_dragndrop = true;
    s.max_dropped_files = 8;
    s.depth_format = SAPP_PIXELFORMAT_DEPTH_STENCIL;
    s.logger.func = fa_sokol_log_func;
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
    return 0;
#endif
}

GfxEnvironment app_gfx_environment() {
    GfxEnvironment out{};
    sg_environment env = sglue_environment();
    std::memcpy(out.storage, &env, sizeof(env));
    return out;
}

GfxSwapchain app_gfx_swapchain() {
    GfxSwapchain out{};
    sg_swapchain sc = sglue_swapchain();
    std::memcpy(out.storage, &sc, sizeof(sc));
    return out;
}

int app_framebuffer_width() { return sapp_isvalid() ? sapp_width() : g.fbW; }
int app_framebuffer_height() { return sapp_isvalid() ? sapp_height() : g.fbH; }
float app_dpi_scale() { return sapp_isvalid() ? sapp_dpi_scale() : 1.0f; }
void app_request_quit() { sapp_request_quit(); }
void app_set_title(const std::string& title) { sapp_set_window_title(title.c_str()); }
void app_show_mouse(bool show) { sapp_show_mouse(show); }

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
