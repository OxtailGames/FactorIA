// What app.cpp asks of the phone or tablet it runs on, one implementation per platform: mobile_android.cpp (JNI),
// mobile_apple.mm (iOS; macOS has none) and mobile.cpp (everything else: nothing to do). Private to fa_platform.
#pragma once

#include "fa/core/math.h"
#include "fa/platform/input.h"

namespace fa {

// The part of the framebuffer the notch, rounded corners and system bars cover, in framebuffer pixels. Zero when the
// platform has none or cannot tell. Valid on the thread that runs the sokol_app callbacks.
EdgeInsets mobile_safe_insets();
// One pulse of the vibration motor. Does nothing without a motor (or, on Android, without the VIBRATE permission).
void mobile_vibrate(float seconds);
// Shows or hides the on-screen keyboard.
void mobile_show_keyboard(bool show);
// Feeds the keys, typed characters and Back button that came in since the last frame. Once per frame, before the game runs.
void mobile_poll(Input& input);
// sapp_desc.android.native_event_cb: true when the event is consumed. Android only; the other platforms never call it.
bool mobile_native_event(const void* nativeEvent);

}  // namespace fa
