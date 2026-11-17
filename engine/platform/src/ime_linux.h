/* The Linux IME backend's own interface (ime_linux.cpp), private to fa_platform. The shared hooks are in ime_impl.h.
   Plain C on top: sokol_impl.c calls the two event hooks from sokol_app's X11 event loop. */
#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Each event sokol_app takes from the X queue, before it handles it (an XEvent*). The input method gets it first
   (XFilterEvent); an event it took, a key it composed with, or the text it committed (a KeyPress with keycode 0) is
   turned into an event sokol_app ignores. Does nothing while no Input is attached. */
void fa_ime_x11_event(void* xevent);
/* sokol_app is about to read a batch of events (one per frame): an end of composition that waited for its commit is
   applied now. */
void fa_ime_x11_batch(void);

#ifdef __cplusplus
}

namespace fa {

class Input;

// Which Input the composition events go to (AppDesc::input; app.cpp sets it when the app starts and clears it at the end).
// The first call opens the X input method (XOpenIM, from XMODIFIERS: ibus, fcitx...) and an input context on sokol_app's
// window; nullptr closes them. Without an Input, or when no input method opens, keys and text reach the game as sokol_app
// delivers them.
void ime_linux_attach(Input* input);

}  // namespace fa
#endif
