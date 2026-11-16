// The input method editor (IME) hook: what a text field tells the platform so the OS can show its candidate window under
// the caret and send composition events (Input::on_composition_update / commit / cancel).
//
// Both calls are for the game thread and are cheap to repeat: the backend sees only the changes. Each platform has its
// backend in engine/platform/src (ime_apple.mm, ime_win32.cpp, ime_linux.cpp, ime_web.cpp; ime_android.cpp is a JNI glue to
// an InputConnection): docs/TEXT.md, "What composes where".
// The last values asked for are kept (ime_state()) so tests and diagnostics can read what the UI requested.
#pragma once

#include <fa/core/math.h>

namespace fa {

// A text field has the focus (true) or no text field has it (false). Turning it off also drops the caret rectangle.
void ime_set_enabled(bool enabled);
// Where the caret is, in FRAMEBUFFER pixels (x, y = top-left, +Y down; the units of app_framebuffer_width/height, NOT
// divided by the DPI scale): the OS puts its candidate window next to this rectangle. macOS, iOS and the web, whose
// window coordinates are logical points, divide by the DPI scale (app_dpi_scale) in their backend. Ignored while the IME is
// not enabled.
void ime_set_caret_rect(Rect framebufferPixels);
// The composition in progress is over (a click inside the field or the focus moving to another one). The UI has already
// written what it wants kept into the text field it began in (a commit of its own: no Input::on_composition_commit, so
// nothing reaches Input::text_input() for it) and has ended Input's composition (Input::on_composition_cancel), or it drops it.
// The backend resets the OS's composition state and from now on delivers neither a commit nor updates of THAT composition; a
// later composition starts normally. ime_cancel NEVER delivers text: a backend that committed here as well would type the
// text twice.
void ime_cancel();

// What the UI asked for last.
struct ImeState {
    bool enabled = false;
    Rect caretRect;
    int cancels = 0;  // how many times ime_cancel() was called (kept for tests; ime_reset_state() zeroes it)
};
ImeState ime_state();
// Test isolation: the state back to "not enabled, no rectangle" without telling the backend.
void ime_reset_state();

}  // namespace fa
