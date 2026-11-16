// What mobile_android.cpp needs from the Android IME backend (ime_android.cpp). Private to fa_platform; Android only.
#pragma once

#include <vector>

#include "fa/platform/android_keys.h"
#include "fa/platform/input.h"

namespace fa {

// The app's window is up (on_init: true) or gone (on_cleanup: false). While it is not, the backend tells the OS nothing: the
// UI's teardown (ime_cancel, ime_set_enabled(false)) runs after the app's end. Turning it off first takes the text view's
// focus away. On the sokol_app loop thread.
void ime_android_attach(bool attached);
// Feeds the keys and what the input method composed and typed since the last frame, in the order they came
// (ime_ic::Session::feed). Once per frame, on the sokol_app loop thread.
void ime_android_poll(Input& input);
// The keys one event of the activity's input queue became (AndroidKeys::take), queued in the same sequence as the input
// method's calls. On the sokol_app loop thread; a full queue drops them, logged once.
void ime_android_push_keys(const std::vector<AndroidKeys::Item>& items);
// The on-screen keyboard, once the IME's Java side is loaded: shown on the UI thread, after what the IME asked before
// (so a show posted there cannot land after a later hide). While the IME is on it is shown for the engine's text view,
// which the input method is connected to; while it is off, the way mobile_android.cpp does (the decor view, then a
// forced toggle). False when the Java side is not loaded or failed: the caller shows the keyboard its own way.
bool ime_android_show_keyboard(bool show);

}  // namespace fa
