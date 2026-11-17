// The desktop, the web and the test machines: no notch. A browser vibrates through navigator.vibrate (phones; ignored
// where it does not exist) and raises the phone's keyboard through the hidden <input> of ime_web.cpp. Desktop and the test
// machines have no on-screen keyboard. Android and iOS have their own files (mobile_android.cpp, mobile_apple.mm).
#if defined(__EMSCRIPTEN__)
#include <emscripten.h>

#include "fa/platform/input.h"
// clang-format off
EM_JS(void, fa_web_vibrate, (int ms), { if (navigator.vibrate) navigator.vibrate(ms); });
// clang-format on

// The on-screen keyboard of a mobile browser is ime_web.cpp's: a browser raises it only for a focused <input>, and the
// hidden one the IME composes into takes the focus while a TextField has it (on a touch screen).
#include "ime_web.h"
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
    ime_web_keyboard(show);
#else
    (void)show;
#endif
}
void mobile_poll(Input& input) {
#if defined(__EMSCRIPTEN__)
    ime_web_poll(input);
#else
    (void)input;
#endif
}
bool mobile_native_event(const void*) { return false; }

}  // namespace fa

#endif
