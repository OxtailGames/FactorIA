// The IME backend of the web (docs/TEXT.md, "What composes where"): a browser composes only into an editable element, so
// while a TextField has the focus a hidden <input> (window.faText.el, id "fa-text-input": 1 px wide, no opacity) takes the
// browser's focus and sits at the field's caret, where the browser puts its candidate window. Its composition events
// (compositionstart, compositionupdate, compositionend) become Input's (ime_compose::Session decides;
// tests/ime_compose_tests.cpp covers it on every host). Keys still reach sokol_app through its window handlers: those go
// through sokol_impl.c's wrappers first, and a key the input method took (keyCode 229, or any key while a composition is
// open) goes to the browser alone, with its default action, so the composition goes on.
//
// The same <input> raises a phone's on-screen keyboard (mobile_show_keyboard, ime_web_keyboard): on a touch screen it
// has the focus while the keyboard is wanted, also for a password field, where the IME is off and what the keyboard
// composes is typed when it ends, as before the IME existed. What the <input> receives outside a composition goes to a
// queue that ime_web_poll() drains into Input: a code point >= 32 for typed text, -2 for Backspace. Keys that reach the
// page as real key events (a hardware keyboard) are seen by sokol_app too; the <input> skips what it already delivered.
//
// Everything runs on the browser's main thread. The composition events call fa_web_ime_event() at once, so a commit
// reaches Input before the key that follows it.
#include <emscripten.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string>

#include "fa/core/utf8.h"
#include "fa/platform/ime.h"
#include "fa/platform/input.h"
#include "ime_compose.h"
#include "ime_impl.h"
#include "ime_text.h"
#include "ime_web.h"

// No apostrophes in this code: it travels through the C preprocessor.
// clang-format off
EM_JS(void, fa_web_text_init, (), {
    if (window.faText) return;
    const MARK = String.fromCharCode(0x200b);  // always in the field, so Backspace has something to delete
    const st = window.faText = {
        el: null, want: false, ime: false, moving: false, queue: [], composing: false, hardKey: false, pressAt: -1000,
        data: "", selA: -1, selB: -1, caret: null,
        touch: (navigator.maxTouchPoints || 0) > 0 || !!(window.matchMedia && window.matchMedia("(pointer: coarse)").matches)
    };
    const canvas = () => document.getElementById("canvas");
    const clean = (s) => (s || "").split(MARK).join("");
    const send = (kind) => { if (Module._fa_web_ime_event) Module._fa_web_ime_event(kind); };
    st.reset = () => {
        if (!st.el) return;
        st.el.value = MARK;
        try { st.el.setSelectionRange(1, 1); } catch (e) {}
    };
    // Focus moves made here are not the page gaining or losing the focus (fa_ime_web_ignore_focus).
    st.move = (fn) => {
        st.moving = true;
        try { fn(); } finally { st.moving = false; }
    };
    // At the caret of the field while the IME is on (framebuffer pixels to CSS pixels: the canvas box over its size);
    // in the bottom-left corner otherwise. A phone browser zooms into an <input> whose text is under 16 px.
    st.place = () => {
        const el = st.el;
        if (!el) return;
        const c = canvas();
        const r = st.ime && st.caret && c && c.width > 0 && c.height > 0 ? c.getBoundingClientRect() : null;
        if (!r) {
            el.style.left = "0px"; el.style.top = "auto"; el.style.bottom = "0px";
            el.style.height = "1px"; el.style.fontSize = "16px";
            return;
        }
        const sx = r.width / c.width, sy = r.height / c.height;
        const h = Math.max(1, st.caret.h * sy);
        el.style.left = (r.left + st.caret.x * sx) + "px";
        el.style.top = (r.top + st.caret.y * sy) + "px";
        el.style.bottom = "auto";
        el.style.height = h + "px";
        el.style.fontSize = (st.touch ? Math.max(16, h) : h) + "px";
    };
    st.ensure = () => {
        if (st.el) return st.el;
        const el = document.createElement("input");
        el.type = "text";
        el.id = "fa-text-input";
        el.setAttribute("autocomplete", "off");
        el.setAttribute("autocapitalize", "off");
        el.setAttribute("autocorrect", "off");
        el.setAttribute("aria-hidden", "true");
        el.setAttribute("enterkeyhint", "done");
        el.tabIndex = -1;
        el.spellcheck = false;
        el.style.cssText = "position:fixed;left:0;bottom:0;width:1px;height:1px;opacity:0;border:0;padding:0;margin:0;" +
                           "font-size:16px;line-height:1;caret-color:transparent;pointer-events:none;";
        const push = (text) => {
            for (const ch of text) {
                const cp = ch.codePointAt(0);
                if (cp >= 32 && cp !== 127 && cp !== 0x200b) st.queue.push(cp);
            }
        };
        const selection = () => {
            const off = el.value.indexOf(MARK) === 0 ? 1 : 0;
            if (el.selectionStart === null || el.selectionEnd === null) { st.selA = st.selB = -1; return; }
            st.selA = el.selectionStart - off;
            st.selB = el.selectionEnd - off;
        };
        el.addEventListener("compositionstart", () => {
            st.composing = true; st.data = ""; st.selA = st.selB = -1;
            send(1);
        });
        el.addEventListener("compositionupdate", (ev) => {
            st.data = clean(ev.data); st.selA = st.selB = -1;
            send(2);
        });
        el.addEventListener("compositionend", (ev) => {
            st.composing = false; st.data = clean(ev.data); st.selA = st.selB = -1;
            send(3);
            st.data = "";
            st.reset();
        });
        el.addEventListener("keydown", (ev) => { if (ev.key === "Backspace" && ev.keyCode !== 229) st.hardKey = true; });
        el.addEventListener("keyup", (ev) => { if (ev.key === "Backspace") st.hardKey = false; });
        el.addEventListener("input", (ev) => {
            const type = ev.inputType || "";
            if (st.composing || ev.isComposing || type.indexOf("Composition") >= 0) {
                if (st.composing) { selection(); send(2); }  // the caret inside the composition, now that the value has it
                return;
            }
            // Only typing and Backspace go to the field: a cut, an undo or a redo of the <input> itself (its menu, Ctrl+Z)
            // does not, and sokol_app delivers the paste event of the window itself. A browser without inputType: the value.
            // A replacement (a phone keyboard autocorrect or suggestion) and a yank (Ctrl+Y on macOS) put text in a value
            // that held only the mark: what is there besides it is the text, typed as is. A transpose (Ctrl+T) swaps the
            // characters around the caret, which are the field ones, never in the <input>: nothing to type.
            if (type === "insertReplacementText" || type === "insertFromYank") {
                const text = clean(el.value);
                if (text.length > 0) push(text);
                st.reset();
                return;
            }
            const typed = type === "insertText" || (type === "" && el.value.length >= MARK.length);
            const erased = type === "deleteContentBackward" || type === "deleteWordBackward" ||
                           (type === "" && el.value.length < MARK.length);
            if (erased) {
                if (!st.hardKey) st.queue.push(-2);  // a real Backspace key reaches sokol_app by itself
            } else if (typed && performance.now() - st.pressAt > 100) {  // else sokol_app got it from keypress already
                push(typeof ev.data === "string" ? ev.data : el.value.split(MARK).join(""));
            }
            st.reset();
        });
        window.addEventListener("keypress", () => { st.pressAt = performance.now(); }, true);
        // iOS raises the keyboard only for focus() inside a touch or click handler, so try again on every tap; with the
        // IME on, a click on the game gives the <input> its focus back too.
        window.addEventListener("pointerup", (ev) => {
            if (document.activeElement === el) return;
            if ((st.want && st.touch) || (st.ime && ev.target === canvas())) st.move(() => el.focus({ preventScroll: true }));
        }, true);
        st.el = el;
        st.reset();
        st.place();
        document.body.appendChild(el);
        return el;
    };
});
// Who has the focus: the <input> while the IME is on, or while a phone keyboard is wanted; the canvas otherwise.
EM_JS(void, fa_web_text_state, (int want, int ime), {
    const st = window.faText;
    if (!st) return;
    st.want = !!want;
    st.ime = !!ime;
    const focus = st.ime || (st.want && st.touch);
    if (!focus && !st.el) return;
    const el = st.ensure();
    st.place();
    if (focus) {
        if (document.activeElement !== el) st.move(() => el.focus({ preventScroll: true }));
    } else if (document.activeElement === el) {
        st.move(() => {
            el.blur();
            const canvas = document.getElementById("canvas");
            if (canvas) canvas.focus({ preventScroll: true });
        });
    }
});
EM_JS(void, fa_web_text_caret, (float x, float y, float w, float h), {
    const st = window.faText;
    if (!st) return;
    st.caret = { x: x, y: y, w: w, h: h };
    st.place();
});
// ime_cancel: the browser drops its composition when the <input> loses the focus; it gets it back at once. A phone keeps
// its keyboard only for a focus() inside a tap, so there the value is reset instead and the keyboard starts over.
EM_JS(void, fa_web_text_cancel, (), {
    const st = window.faText;
    if (!st || !st.el || !st.composing) return;
    const el = st.el;
    if (!st.touch && document.activeElement === el) st.move(() => { el.blur(); el.focus({ preventScroll: true }); });
    st.composing = false;
    st.data = "";
    st.reset();
});
EM_JS(int, fa_web_text_moving, (), {
    return window.faText && window.faText.moving ? 1 : 0;
});
EM_JS(int, fa_web_text_data, (char* out, int capacity), {
    const st = window.faText;
    const s = (st && st.data) || "";
    const n = lengthBytesUTF8(s);
    if (out && capacity > n) stringToUTF8(s, out, capacity);
    return n;
});
EM_JS(int, fa_web_text_selection, (int end), {
    const st = window.faText;
    if (!st) return -1;
    const v = end ? st.selB : st.selA;
    return typeof v === "number" && v >= 0 ? v : -1;
});
EM_JS(int, fa_web_text_pop, (), {
    const st = window.faText;
    return st && st.queue.length ? st.queue.shift() : -1;
});
// clang-format on

namespace {

namespace ic = fa::ime_compose;

ic::Session g_session({.typeWhenOff = true});
bool g_attached = false;
bool g_want = false;  // the phone keyboard is wanted (ime_web_keyboard)

// A composition is a few words: one that claims more is not read.
constexpr int kMaxBytes = 1 << 16;

void init() {
    static bool done = false;
    if (!done) fa_web_text_init();
    done = true;
}

void apply_state() { fa_web_text_state(g_want ? 1 : 0, g_session.active() ? 1 : 0); }

std::string read_data() {
    const int n = fa_web_text_data(nullptr, 0);
    if (n <= 0 || n > kMaxBytes) return {};
    std::string s(static_cast<std::size_t>(n) + 1, '\0');
    fa_web_text_data(s.data(), n + 1);
    s.resize(static_cast<std::size_t>(n));
    return s;
}

fa::ime_text::Marked read_marked() {
    const std::u16string text = ic::to_utf16(fa::utf8_decode(read_data()));
    const int a = fa_web_text_selection(0), b = fa_web_text_selection(1);
    const std::size_t loc = a < 0 ? text.size() : std::min(static_cast<std::size_t>(a), text.size());
    const std::size_t end = b < 0 ? loc : std::clamp(static_cast<std::size_t>(b), loc, text.size());
    return fa::ime_text::marked_from_utf16(text, loc, end - loc, {});
}

}  // namespace

// kind: 1 compositionstart, 2 the composition changed (compositionupdate, or the input event that follows it), 3
// compositionend (its data is what it commits; empty: nothing).
extern "C" EMSCRIPTEN_KEEPALIVE void fa_web_ime_event(int kind) {
    switch (kind) {
        case 1: g_session.start(); break;
        case 2: g_session.update(read_marked()); break;
        case 3:
            g_session.commit(fa::utf8_decode(read_data()));
            g_session.end();
            break;
        default: break;
    }
}

extern "C" int fa_ime_web_key(int kind, int keyCode, int sappKey) {
    const bool took = keyCode == 229 || g_session.os_composing();
    const unsigned code = static_cast<unsigned>(std::max(sappKey, 0));
    switch (kind) {
        case 0:
            if (took && !g_session.active())
                return 1;  // a phone keyboard composing with the IME off: still not a game key
            return g_session.key_down(code, took) ? 1 : 0;
        case 1: return g_session.key_up(code, took) ? 1 : 0;
        default: return took ? 1 : 0;
    }
}

extern "C" int fa_ime_web_ignore_focus(const char* targetId) {
    return (targetId && std::strcmp(targetId, "fa-text-input") == 0) || fa_web_text_moving() ? 1 : 0;
}

extern "C" void fa_ime_web_blur(void) { g_session.focus_lost(); }

namespace fa {

void ime_web_attach(Input* input) {
    init();
    if (!input) {
        if (g_attached) {
            g_session.cancel();
            fa_web_text_cancel();
        }
        g_session.attach(nullptr);
        g_attached = false;
        apply_state();
        return;
    }
    g_session.attach(input);
    g_attached = true;
    const ImeState s = ime_state();
    g_session.set_enabled(s.enabled);
    if (s.enabled && (s.caretRect.w > 0.0f || s.caretRect.h > 0.0f))
        fa_web_text_caret(s.caretRect.x, s.caretRect.y, s.caretRect.w, s.caretRect.h);
    apply_state();
}

void ime_web_keyboard(bool show) {
    init();
    g_want = show;
    apply_state();
}

void ime_web_poll(Input& input) {
    for (int guard = 0; guard < 256; ++guard) {  // what the hidden <input> collected since the last frame
        const int v = fa_web_text_pop();
        if (v == -1) break;
        if (v == -2) {
            input.on_key(Key::Backspace, true);
            input.on_key(Key::Backspace, false);  // pressed and released within the frame: the UI sees the press
        } else if (v >= 32) {
            input.on_text(static_cast<std::uint32_t>(v));
        }
    }
}

void ime_backend_set_enabled(bool enabled) {
    if (!g_attached) return;         // not attached (tests, the editor): nothing to tell the browser
    g_session.set_enabled(enabled);  // off: Input's composition ends; the rest of the browser's one is dropped
    apply_state();                   // the <input> leaves (or keeps, for a phone keyboard) the focus
}

void ime_backend_set_caret_rect(Rect framebufferPixels) {
    if (!g_attached) return;
    fa_web_text_caret(framebufferPixels.x, framebufferPixels.y, framebufferPixels.w, framebufferPixels.h);
}

void ime_backend_cancel() {
    if (!g_attached) return;
    g_session.cancel();
    fa_web_text_cancel();
}

}  // namespace fa
