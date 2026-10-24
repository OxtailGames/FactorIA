// The desktop, the web and the test machines: no notch. A browser vibrates through navigator.vibrate (phones; ignored
// where it does not exist) and raises the phone's keyboard through a hidden <input> (below). Desktop and the test machines
// have no on-screen keyboard. Android and iOS have their own files (mobile_android.cpp, mobile_apple.mm).
#if defined(__EMSCRIPTEN__)
#include <emscripten.h>

#include "fa/platform/input.h"
EM_JS(void, fa_web_vibrate, (int ms), { if (navigator.vibrate) navigator.vibrate(ms); });

// The on-screen keyboard of a mobile browser: a browser raises it only for a focused <input>, so a hidden one (1 px, no
// opacity) takes the focus while a TextField has it. What it receives goes to a queue that mobile_poll() drains into Input:
// a code point >= 32 for typed text, -2 for Backspace. On a browser with no touch screen nothing happens: sokol_app takes
// the keys of the window itself (keydown, and typed text from the keypress events). Keys that reach the page as real key
// events (a hardware keyboard on a tablet) are seen by sokol_app too; the hidden input skips what it already delivered.
// No apostrophes in this code: it travels through the C preprocessor.
EM_JS(void, fa_web_keyboard, (int show), {
    const st = window.faText || (window.faText = { el: null, want: false, queue: [], composing: false, hardKey: false, pressAt: -1000 });
    st.want = !!show;
    const touch = (navigator.maxTouchPoints || 0) > 0 || (window.matchMedia && window.matchMedia("(pointer: coarse)").matches);
    if (!touch) return;
    if (!st.el) {
        const MARK = String.fromCharCode(0x200b);  // always in the field, so Backspace has something to delete
        const el = document.createElement("input");
        el.type = "text";
        el.setAttribute("autocomplete", "off");
        el.setAttribute("autocapitalize", "off");
        el.setAttribute("autocorrect", "off");
        el.setAttribute("aria-hidden", "true");
        el.setAttribute("enterkeyhint", "done");
        el.tabIndex = -1;
        el.spellcheck = false;
        el.style.cssText = "position:fixed;left:0;bottom:0;width:1px;height:1px;opacity:0;border:0;padding:0;margin:0;" +
                           "font-size:16px;caret-color:transparent;pointer-events:none;";
        const reset = () => {
            el.value = MARK;
            try { el.setSelectionRange(1, 1); } catch (e) {}
        };
        const push = (text) => {
            for (const ch of text) {
                const cp = ch.codePointAt(0);
                if (cp >= 32 && cp !== 127 && cp !== 0x200b) st.queue.push(cp);
            }
        };
        el.addEventListener("compositionstart", () => { st.composing = true; });
        el.addEventListener("compositionend", (ev) => { st.composing = false; push(ev.data || ""); reset(); });
        el.addEventListener("keydown", (ev) => { if (ev.key === "Backspace" && ev.keyCode !== 229) st.hardKey = true; });
        el.addEventListener("keyup", (ev) => { if (ev.key === "Backspace") st.hardKey = false; });
        el.addEventListener("input", (ev) => {
            const type = ev.inputType || "";
            if (st.composing || ev.isComposing || type.indexOf("insertComposition") === 0) return;
            if (type.indexOf("delete") === 0 || el.value.length < MARK.length) {
                if (!st.hardKey) st.queue.push(-2);  // a real Backspace key reaches sokol_app by itself
            } else if (performance.now() - st.pressAt > 100) {  // else sokol_app already got this character from keypress
                push(typeof ev.data === "string" ? ev.data : el.value.split(MARK).join(""));
            }
            reset();
        });
        window.addEventListener("keypress", () => { st.pressAt = performance.now(); }, true);
        // iOS raises the keyboard only for focus() inside a touch or click handler, so try again on every tap.
        window.addEventListener("pointerup", () => { if (st.want && document.activeElement !== el) el.focus({ preventScroll: true }); }, true);
        reset();
        document.body.appendChild(el);
        st.el = el;
    }
    if (show) {
        st.el.focus({ preventScroll: true });
    } else {
        st.el.blur();
        const canvas = document.getElementById("canvas");
        if (canvas) canvas.focus({ preventScroll: true });
    }
});
EM_JS(int, fa_web_text_pop, (), {
    const st = window.faText;
    return st && st.queue.length ? st.queue.shift() : -1;
});
#endif
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "mobile_impl.h"

#if !defined(__ANDROID__) && !(defined(__APPLE__) && TARGET_OS_IPHONE)

namespace fa {

EdgeInsets mobile_safe_insets() { return {}; }
void mobile_vibrate(float seconds) {
#if defined(__EMSCRIPTEN__)
    fa_web_vibrate(int(seconds * 1000.0f));
#else
    (void)seconds;
#endif
}
void mobile_show_keyboard(bool show) {
#if defined(__EMSCRIPTEN__)
    fa_web_keyboard(show ? 1 : 0);
#else
    (void)show;
#endif
}
void mobile_poll(Input& input) {
#if defined(__EMSCRIPTEN__)
    for (int guard = 0; guard < 256; ++guard) {  // what the hidden <input> collected since the last frame
        const int v = fa_web_text_pop();
        if (v == -1) break;
        if (v == -2) {
            input.on_key(Key::Backspace, true);
            input.on_key(Key::Backspace, false);  // pressed and released within the frame: the UI sees the press
        } else {
            input.on_text(std::uint32_t(v));
        }
    }
#else
    (void)input;
#endif
}
bool mobile_native_event(const void*) { return false; }

}  // namespace fa

#endif
