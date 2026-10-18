// The desktop, the web and the test machines: no notch, no on-screen keyboard. A browser vibrates through navigator.vibrate
// (phones; ignored where it does not exist). Android and iOS have their own files (mobile_android.cpp, mobile_apple.mm).
#if defined(__EMSCRIPTEN__)
#include <emscripten.h>
EM_JS(void, fa_web_vibrate, (int ms), { if (navigator.vibrate) navigator.vibrate(ms); });
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
void mobile_show_keyboard(bool) {}
void mobile_poll(Input&) {}
bool mobile_native_event(const void*) { return false; }

}  // namespace fa

#endif
