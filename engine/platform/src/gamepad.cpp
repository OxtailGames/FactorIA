// The web build has no gamepad backend yet (no web build exists in the repo): no pad is ever reported. Windows, Linux,
// Apple and Android have their own gamepad_<platform> file (see cmake/FactoriaHelpers.cmake).
#include "fa/platform/gamepad.h"

#if defined(__EMSCRIPTEN__)
namespace fa {
void poll_gamepads(Input&) {}
}  // namespace fa
#endif
