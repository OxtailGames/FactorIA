// What mobile_android.cpp needs from the Android IME backend (ime_android.cpp). Private to fa_platform; Android only.
#pragma once

#include "fa/platform/input.h"

namespace fa {

// Feeds what the input method composed and typed since the last frame (ime_ic::Session::feed). Once per frame, on the
// sokol_app loop thread, after the keys of the input queue.
void ime_android_poll(Input& input);
// The on-screen keyboard, once the IME's Java side is loaded: shown on the UI thread, after what the IME asked before
// (so a show posted there cannot land after a later hide). While the IME is on it is shown for the engine's text view,
// which the input method is connected to; while it is off, the way mobile_android.cpp does (the decor view, then a
// forced toggle). False when the Java side is not loaded or failed: the caller shows the keyboard its own way.
bool ime_android_show_keyboard(bool show);

}  // namespace fa
