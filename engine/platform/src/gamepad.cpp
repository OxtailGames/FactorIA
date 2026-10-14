// Platforms without a gamepad backend yet (Android, web): no pad is ever reported. Windows, Linux and Apple have their
// own gamepad_<platform> file (see cmake/FactoriaHelpers.cmake).
#include "fa/platform/gamepad.h"

#if defined(__ANDROID__) || defined(__EMSCRIPTEN__)
namespace fa {
void poll_gamepads(Input&) {}
}  // namespace fa
#endif
