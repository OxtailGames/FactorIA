// The desktop and the test machines: no notch, no vibration motor, no on-screen keyboard. Android and iOS have their own
// files (mobile_android.cpp, mobile_apple.mm).
#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

#include "mobile_impl.h"

#if !defined(__ANDROID__) && !(defined(__APPLE__) && TARGET_OS_IPHONE)

namespace fa {

EdgeInsets mobile_safe_insets() { return {}; }
void mobile_vibrate(float) {}
void mobile_show_keyboard(bool) {}
void mobile_poll(Input&) {}
bool mobile_native_event(const void*) { return false; }

}  // namespace fa

#endif
