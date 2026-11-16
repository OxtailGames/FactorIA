/* The web IME backend's own interface (ime_web.cpp), private to fa_platform. The shared hooks are in ime_impl.h. Plain C
   on top: sokol_impl.c calls the two event hooks from its wrappers of sokol_app's window handlers. */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* A key event of the window, before sokol_app sees it: `kind` 0 keydown, 1 keyup, 2 keypress; `keyCode` the DOM keyCode
   (229: the browser's input method took the key); `sappKey` the sapp_keycode sokol_app makes of it. Nonzero: the key is
   the input method's (sokol_app does not see it, the browser keeps its default action). */
int fa_ime_web_key(int kind, int keyCode, int sappKey);
/* A focus or blur event of the window whose target has the id `targetId`: nonzero when it is the hidden <input> of
   ime_web.cpp, or the focus moving because ime_web.cpp moved it (not the page gaining or losing the focus). */
int fa_ime_web_ignore_focus(const char* targetId);

#ifdef __cplusplus
}

namespace fa {

class Input;

// Which Input the composition events go to (AppDesc::input; app.cpp sets it when the app starts and clears it at the end).
// nullptr: the composition events go nowhere and the hidden <input> serves only the phone's keyboard.
void ime_web_attach(Input* input);
// The phone's on-screen keyboard (mobile_show_keyboard): on a touch screen the hidden <input> takes the focus while
// `show`, so the browser raises the keyboard.
void ime_web_keyboard(bool show);
// What the hidden <input> received outside a composition since the last frame (a phone keyboard's letters and
// Backspace): typed into `input` (mobile_poll).
void ime_web_poll(Input& input);

}  // namespace fa
#endif
