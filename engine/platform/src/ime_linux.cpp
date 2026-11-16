// The IME backend of Linux (docs/TEXT.md, "What composes where"): XIM on the X11 window sokol_app made. sokol_app has no
// input method and is not edited: sokol_impl.c wraps the two Xlib calls of its event loop (XPending, XNextEvent), so every
// event reaches fa_ime_x11_event() before sokol_app handles it.
//  - The input context is "on the spot" (XIMPreeditCallbacks) when the input method offers it: XIM draws the pre-edit
//    string through callbacks (Start, Draw, Caret, Done), ime_compose::Preedit rebuilds it, and the TextField draws it at
//    its caret. An input method without callbacks draws the string in its own window (XIMPreeditNothing) and only the
//    commit arrives.
//  - What XIM commits comes back as a KeyPress with keycode 0, read with Xutf8LookupString: that is the commit's only
//    delivery (the event never reaches sokol_app).
//  - A key XIM took (XFilterEvent returned True) is not a game key, and neither is its key up; ime_compose::Session
//    decides (tests/ime_compose_tests.cpp covers it on every host).
// While no TextField has the focus the input context does not have it either (XUnsetICFocus) and no key goes through
// XFilterEvent: the game's keys stay as sokol_app delivers them. sokol_app has no Wayland backend: on a Wayland desktop the
// game runs through XWayland, where ibus and fcitx serve XIM the same way. Everything runs on the main thread, where
// sokol_app reads the X queue and runs the game. A failure (a locale Xlib does not support, no input method, an input
// context refused) leaves the IME off, never the keys.
//
// The fa headers come before the X11 ones: Xlib defines None, Bool, Status, True and False as macros.
#include <algorithm>
#include <climits>
#include <clocale>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <cwchar>
#include <locale.h>  // newlocale, uselocale (POSIX)
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/log.h"
#include "fa/core/utf8.h"
#include "fa/platform/ime.h"
#include "ime_compose.h"
#include "ime_impl.h"
#include "ime_linux.h"
#include "sokol_app.h"

#include <X11/Xlib.h>
#include <X11/Xutil.h>

namespace ic = fa::ime_compose;

static_assert(static_cast<unsigned long>(XIMReverse) == ic::kXimReverse);
static_assert(static_cast<unsigned long>(XIMUnderline) == ic::kXimUnderline);
static_assert(static_cast<unsigned long>(XIMHighlight) == ic::kXimHighlight);
static_assert(static_cast<int>(XIMForwardChar) == ic::kXimForwardChar);
static_assert(static_cast<int>(XIMBackwardChar) == ic::kXimBackwardChar);
static_assert(static_cast<int>(XIMLineStart) == ic::kXimLineStart);
static_assert(static_cast<int>(XIMLineEnd) == ic::kXimLineEnd);
static_assert(static_cast<int>(XIMAbsolutePosition) == ic::kXimAbsolutePosition);
static_assert(static_cast<int>(XIMDontChange) == ic::kXimDontChange);

namespace {

Display* g_display = nullptr;  // sokol_app's, while an Input is attached
Window g_window = 0;
Window g_root = 0;              // screen 0's root window, which holds XIM_SERVERS (as Xlib reads it)
Atom g_ximServers = 0;          // the XIM_SERVERS atom: the input method servers running now
bool g_reopen = false;          // the server stopped (on_im_destroy): open another input method after XFilterEvent
locale_t g_imLocale = nullptr;  // the LC_CTYPE the input method opened with: its multibyte strings are in it
bool g_localeWarned = false;
XIM g_im = nullptr;
XIC g_ic = nullptr;
bool g_callbacks = false;  // the input context is on the spot (XIMPreeditCallbacks)
bool g_focused = true;     // the window has the keyboard focus (FocusIn / FocusOut)
ic::Session g_session({.deferEnds = true});
ic::Preedit g_preedit;
fa::Rect g_caret;  // framebuffer pixels (on X11 the window's pixels), as ime_set_caret_rect() gave it
bool g_haveCaret = false;

// A commit is a few words: one that claims more is not read.
constexpr int kMaxCommitBytes = 1 << 16;

// An event sokol_app's loop skips (its switch has no case for it): what the input method took goes no further.
void neutralise(XEvent* e) { e->type = NoExpose; }

std::u32string decode(const XIMText& t) {
    std::u32string out;
    const std::size_t n = std::min<std::size_t>(t.length, ic::kMaxPreedit);
    if (t.encoding_is_wchar) {
        const wchar_t* w = t.string.wide_char;
        for (std::size_t i = 0; w && i < n && w[i] != 0; ++i) out.push_back(static_cast<char32_t>(w[i]));
        return out;
    }
    const char* s = t.string.multi_byte;  // in the encoding of the input method's locale (LocaleScope), NUL-terminated
    if (!s) return out;
    std::size_t bytes = strnlen(s, n * MB_LEN_MAX);
    // mbrtowc reads the thread's locale: the input method's for this loop, the game's own again after it.
    struct UseLocale {
        locale_t previous = g_imLocale ? uselocale(g_imLocale) : nullptr;
        ~UseLocale() {
            if (previous) uselocale(previous);
        }
    } use;
    std::mbstate_t state{};
    while (bytes > 0 && out.size() < n) {
        wchar_t wc = 0;
        const std::size_t r = std::mbrtowc(&wc, s, std::min<std::size_t>(bytes, MB_LEN_MAX), &state);
        if (r == 0) break;
        if (r == static_cast<std::size_t>(-1) || r == static_cast<std::size_t>(-2)) {
            out.push_back(U'�');  // a byte this locale cannot read: one character, as XIM counted it
            state = {};
            ++s;
            --bytes;
            continue;
        }
        out.push_back(static_cast<char32_t>(wc));
        s += r;
        bytes -= r;
    }
    return out;
}

void show_preedit() { g_session.update(g_preedit.marked()); }

// The preedit callbacks: XIM calls them from inside XFilterEvent (or XmbResetIC), on the main thread.
int on_preedit_start(XIC, XPointer, XPointer) {
    g_preedit.clear();
    g_session.start();
    return -1;  // no limit on the pre-edit string's length
}

void on_preedit_done(XIC, XPointer, XPointer) {
    g_preedit.clear();
    g_session.end();
}

void on_preedit_draw(XIC, XPointer, XPointer data) {
    const auto* d = reinterpret_cast<const XIMPreeditDrawCallbackStruct*>(data);
    if (!d) return;
    ic::Draw draw;
    draw.caret = d->caret;
    draw.first = d->chg_first;
    draw.length = d->chg_length;
    if (const XIMText* t = d->text) {
        draw.hasText = true;
        // The union member read is the one encoding_is_wchar names; without a string only the feedback changes.
        const bool hasString = t->encoding_is_wchar ? t->string.wide_char != nullptr : t->string.multi_byte != nullptr;
        if (hasString)
            draw.chars = decode(*t);
        else
            draw.feedbackOnly = true;
        if (t->feedback) {
            const std::size_t n = std::min<std::size_t>(t->length, ic::kMaxPreedit);
            draw.feedback.assign(t->feedback, t->feedback + n);
        }
    }
    g_preedit.draw(draw);
    show_preedit();
}

void on_preedit_caret(XIC, XPointer, XPointer data) {
    auto* c = reinterpret_cast<XIMPreeditCaretCallbackStruct*>(data);
    if (!c) return;
    c->position = g_preedit.move_caret(static_cast<int>(c->direction), c->position);
    if (!g_preedit.text().empty()) show_preedit();
}

// XIMProc is void(XIM, XPointer, XPointer); Xlib calls each preedit callback with the type it documents for it (the Start
// callback returns an int). Through void(*)() so that GCC's -Wcast-function-type sees a deliberate cast.
template <typename F>
XIMProc as_proc(F* f) {
    return reinterpret_cast<XIMProc>(reinterpret_cast<void (*)()>(f));
}

// The callback structs outlive the input context that points at them.
XIMCallback g_start{nullptr, nullptr}, g_done{nullptr, nullptr}, g_draw{nullptr, nullptr},
    g_caretMoved{nullptr, nullptr};
XIMCallback g_destroy{nullptr, nullptr};

void reset_ic() {
    if (!g_ic) return;
    if (char* left = XmbResetIC(g_ic)) XFree(left);  // what was being composed: never typed (ime_cancel's contract)
    g_preedit.clear();
}

void apply_focus() {
    if (!g_ic) return;
    if (g_session.enabled() && g_focused)
        XSetICFocus(g_ic);
    else
        XUnsetICFocus(g_ic);
}

void apply_caret() {
    if (!g_ic || !g_haveCaret) return;
    const float x = g_caret.x, y = g_caret.y + g_caret.h;  // XIM puts its candidate window below the spot
    if (!std::isfinite(x) || !std::isfinite(y)) return;
    XPoint spot;
    spot.x = static_cast<short>(std::clamp(std::lround(x), -32768l, 32767l));
    spot.y = static_cast<short>(std::clamp(std::lround(y), -32768l, 32767l));
    XVaNestedList attrs = XVaCreateNestedList(0, XNSpotLocation, &spot, nullptr);
    if (!attrs) return;
    XSetICValues(g_ic, XNPreeditAttributes, attrs, nullptr);  // an input method that places nothing ignores it
    XFree(attrs);
}

void forget_im() {
    g_ic = nullptr;
    g_im = nullptr;
    g_preedit.clear();
    if (g_imLocale) freelocale(g_imLocale);
    g_imLocale = nullptr;
}

void close_im() {
    if (g_ic) XDestroyIC(g_ic);
    if (g_im) XCloseIM(g_im);
    forget_im();
}

// Xlib picks its locale data from the process's LC_CTYPE when it checks or opens an input method, and keeps them in the
// input method. A process that left LC_CTYPE at "C" (every program starts so) gets the environment's (LANG, LC_ALL,
// LC_CTYPE) for those calls only, as GLFW and SDL do for good; the game's own comes back right after. setlocale changes
// the whole process's locale, and the engine's other threads (loads, audio) run meanwhile: anything of theirs that reads
// LC_CTYPE (the C library's multibyte functions, printf's %ls) may see the environment's for these few calls. The
// engine decodes its UTF-8 itself and calls no multibyte function outside this file, and the ASCII classes (isalpha,
// tolower) are the same in every locale; it happens only when an input method opens (at start, when a server starts
// or stops).
class LocaleScope {
public:
    LocaleScope() {
        const char* now = std::setlocale(LC_CTYPE, nullptr);
        if (now) saved_ = now;  // a copy: the next setlocale may reuse the buffer
        if (!now || saved_ == "C" || saved_ == "POSIX") changed_ = std::setlocale(LC_CTYPE, "") != nullptr;
    }
    ~LocaleScope() {
        if (changed_) std::setlocale(LC_CTYPE, saved_.empty() ? "C" : saved_.c_str());
    }
    LocaleScope(const LocaleScope&) = delete;
    LocaleScope& operator=(const LocaleScope&) = delete;

private:
    std::string saved_;
    bool changed_ = false;
};

// The server of the input method stopped (Xlib saw its window destroyed, in XFilterEvent: _XimFilterServerDestroy). Xlib
// calls this before it frees the input method and its context itself, without a request to the server: they get no more
// calls from here (no X call in this callback). The window tries another input method once XFilterEvent returns.
void on_im_destroy(XIM, XPointer, XPointer) {
    forget_im();
    g_session.cancel();  // Input's composition ends; nothing more comes about it
    g_reopen = true;
}

bool create_ic() {
    XIMStyles* styles = nullptr;
    if (XGetIMValues(g_im, XNQueryInputStyle, &styles, nullptr) != nullptr || !styles) return false;
    XIMStyle style = 0;
    for (const XIMStyle want :
         {XIMStyle(XIMPreeditCallbacks | XIMStatusNothing), XIMStyle(XIMPreeditNothing | XIMStatusNothing)}) {
        for (unsigned short i = 0; i < styles->count_styles && style == 0; ++i)
            if (styles->supported_styles[i] == want) style = want;
        if (style) break;
    }
    XFree(styles);
    if (!style) return false;
    g_callbacks = (style & XIMPreeditCallbacks) != 0;
    if (g_callbacks) {
        g_start.callback = as_proc(&on_preedit_start);
        g_done.callback = as_proc(&on_preedit_done);
        g_draw.callback = as_proc(&on_preedit_draw);
        g_caretMoved.callback = as_proc(&on_preedit_caret);
        XVaNestedList preedit =
            XVaCreateNestedList(0, XNPreeditStartCallback, &g_start, XNPreeditDoneCallback, &g_done,
                                XNPreeditDrawCallback, &g_draw, XNPreeditCaretCallback, &g_caretMoved, nullptr);
        if (!preedit) return false;
        g_ic = XCreateIC(g_im, XNInputStyle, style, XNClientWindow, g_window, XNFocusWindow, g_window,
                         XNPreeditAttributes, preedit, nullptr);
        XFree(preedit);
    } else {
        g_ic = XCreateIC(g_im, XNInputStyle, style, XNClientWindow, g_window, XNFocusWindow, g_window, nullptr);
    }
    if (!g_ic) return false;
    // The window asks for the events the input method filters (KeyPress and KeyRelease, which sokol_app selects already,
    // and whatever else it names).
    unsigned long filter = 0;
    XWindowAttributes wa;
    if (XGetICValues(g_ic, XNFilterEvents, &filter, nullptr) == nullptr &&
        XGetWindowAttributes(g_display, g_window, &wa))
        XSelectInput(g_display, g_window, wa.your_event_mask | static_cast<long>(filter));
    return true;
}

// Opens the input method XMODIFIERS names (ibus, fcitx; with none, Xlib's own) and an input context on the window. None
// now (no server yet, a locale Xlib does not support) leaves the IME off: a change of XIM_SERVERS tries again.
void open_im() {
    if (g_im || !g_display) return;
    const LocaleScope locale;
    if (!XSupportsLocale()) {
        if (!g_localeWarned) {
            const char* name = std::setlocale(LC_CTYPE, nullptr);
            FA_WARN("platform",
                    "IME: Xlib does not support the locale \"{}\" (LANG, LC_ALL): text fields do not compose",
                    name ? name : "?");
        }
        g_localeWarned = true;
        return;
    }
    XSetLocaleModifiers("");  // XMODIFIERS (@im=ibus): the locale data keep it
    g_im = XOpenIM(g_display, nullptr, nullptr, nullptr);
    if (!g_im) return;  // none now: the next change of XIM_SERVERS (a server that starts) tries again
    if (const char* name = std::setlocale(LC_CTYPE, nullptr)) g_imLocale = newlocale(LC_CTYPE_MASK, name, nullptr);
    g_destroy.callback = &on_im_destroy;
    XSetIMValues(g_im, XNDestroyCallback, &g_destroy, nullptr);
    if (!create_ic()) {
        FA_WARN("platform", "IME: the X input method offers no input context this backend can use: text fields do not "
                            "compose (keys and typed text are not affected)");
        close_im();
        return;
    }
    g_preedit.clear();
    apply_focus();
    apply_caret();
}

void detach() {
    if (!g_display) return;
    g_session.cancel();  // Input's composition ends; what XIM still says about it is dropped
    reset_ic();
    close_im();
    g_session.attach(nullptr);
    g_haveCaret = false;
    g_display = nullptr;
    g_window = 0;
    g_root = 0;
    g_ximServers = 0;
    g_reopen = false;
}

void on_key_press(XEvent* e) {
    XKeyEvent& k = e->xkey;
    if (!g_ic) return;
    if (k.keycode == 0) {  // the text XIM committed, put back in the queue as a key event without a key
        if (XFilterEvent(e, None)) {
            neutralise(e);
            return;
        }
        char small[256];
        std::vector<char> big;
        char* buf = small;
        KeySym sym = 0;
        Status status = 0;
        int n = Xutf8LookupString(g_ic, &k, buf, static_cast<int>(sizeof small), &sym, &status);
        if (status == XBufferOverflow && n > 0 && n <= kMaxCommitBytes) {
            big.resize(static_cast<std::size_t>(n));
            buf = big.data();
            n = Xutf8LookupString(g_ic, &k, buf, n, &sym, &status);
        }
        if ((status == XLookupChars || status == XLookupBoth) && n > 0)
            g_session.commit(fa::utf8_decode(std::string_view(buf, static_cast<std::size_t>(n))));
        neutralise(e);
        return;
    }
    const bool took = g_session.active() && g_focused && XFilterEvent(e, None);
    if (g_session.key_down(k.keycode, took, static_cast<std::uint32_t>(k.time))) neutralise(e);
}

void on_key_release(XEvent* e) {
    XKeyEvent& k = e->xkey;
    if (!g_ic) return;
    if (k.keycode == 0) {
        neutralise(e);
        return;
    }
    const bool took = g_session.active() && g_focused && XFilterEvent(e, None);
    if (g_session.key_up(k.keycode, took, static_cast<std::uint32_t>(k.time))) neutralise(e);
}

}  // namespace

extern "C" void fa_ime_x11_event(void* xevent) {
    auto* e = static_cast<XEvent*>(xevent);
    if (!g_display || !e) return;
    switch (e->type) {
        case KeyPress: on_key_press(e); return;
        case KeyRelease: on_key_release(e); return;
        case GenericEvent: return;   // XInput2 (raw mouse motion): nothing of the input method's
        case ClientMessage: return;  // sokol_app passes these to XFilterEvent itself
        case FocusIn:
        case FocusOut:
            if (e->xfocus.window == g_window && e->xfocus.mode != NotifyGrab && e->xfocus.mode != NotifyUngrab) {
                g_focused = e->type == FocusIn;
                if (!g_focused) g_session.focus_lost();
                apply_focus();
            }
            break;
        case PropertyNotify:
            if (e->xproperty.window == g_root && g_ximServers && e->xproperty.atom == g_ximServers) {
                // A server started or stopped (a server writes XIM_SERVERS when it starts, also when its name is there).
                // Only a game without an input method tries again. One that is open stays: Xlib picks its own input
                // method (no server) whenever XMODIFIERS names none (or "local") and the locale has a Compose file,
                // whatever servers run, so reopening it would only cancel a dead-key sequence; with a server named, or
                // without a Compose file, XOpenIM opens nothing until a server runs, and the input method it opened
                // then notices its server stopping itself (on_im_destroy).
                if (!g_im) open_im();
                return;
            }
            break;
        default: break;
    }
    // XIM also talks to its server through properties of its own windows, and watches the server's window: its
    // DestroyNotify goes through here (XFilterEvent calls on_im_destroy, then frees the input method).
    if (g_im && XFilterEvent(e, None)) neutralise(e);
    if (g_reopen) {
        g_reopen = false;
        open_im();  // another server, Xlib's own, or none until the next change of XIM_SERVERS
    }
}

extern "C" void fa_ime_x11_batch(void) {
    if (g_display) g_session.flush();
}

namespace fa {

void ime_linux_attach(Input* input) {
    if (!input) {
        detach();
        return;
    }
    auto* display = static_cast<Display*>(const_cast<void*>(sapp_x11_get_display()));
    const auto window = static_cast<Window>(reinterpret_cast<std::uintptr_t>(sapp_x11_get_window()));
    if (!display || !window) return;
    if (g_display != display || g_window != window) {
        detach();
        g_display = display;
        g_window = window;
        g_focused = true;
        g_localeWarned = false;
        // An input method server that starts after the game, or again after it stopped, writes XIM_SERVERS on the root
        // window: the window asks for its PropertyNotify (XRegisterIMInstantiateCallback watches the same property,
        // but calls its callback once per registration).
        g_root = RootWindow(display, 0);
        g_ximServers = XInternAtom(display, "XIM_SERVERS", False);
        XWindowAttributes root;
        if (XGetWindowAttributes(display, g_root, &root))
            XSelectInput(display, g_root, root.your_event_mask | PropertyChangeMask);
        open_im();
    }
    g_session.attach(input);
    const ImeState s = ime_state();
    g_session.set_enabled(s.enabled);
    g_caret = s.caretRect;
    g_haveCaret = s.enabled && (s.caretRect.w > 0.0f || s.caretRect.h > 0.0f);
    apply_focus();
    apply_caret();
}

void ime_backend_set_enabled(bool enabled) {
    if (!g_display) return;  // not attached (tests, the editor's Play mode): nothing to tell the OS
    if (!enabled) {
        const bool open = g_session.open();
        g_session.set_enabled(false);  // Input's composition ends; the rest of XIM's one is dropped
        if (open) reset_ic();
        g_haveCaret = false;
        apply_focus();
        return;
    }
    g_session.set_enabled(true);
    apply_focus();
    apply_caret();
}

void ime_backend_set_caret_rect(Rect framebufferPixels) {
    if (!g_display) return;
    g_caret = framebufferPixels;
    g_haveCaret = true;
    apply_caret();
}

void ime_backend_cancel() {
    if (!g_display) return;
    const bool open = g_session.open();
    g_session.cancel();
    // Without callbacks the session cannot know whether the input method's own window shows a composition: reset anyway.
    if (open || !g_callbacks) reset_ic();
}

}  // namespace fa
