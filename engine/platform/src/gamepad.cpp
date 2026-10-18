// Windows, Linux, Apple, Android and the web have their own gamepad_<platform> file (see cmake/FactoriaHelpers.cmake).
// This file is what is left for a platform with none: no pad is ever reported.
#include "fa/platform/gamepad.h"

#if !defined(_WIN32) && !defined(__linux__) && !defined(__APPLE__) && !defined(__ANDROID__) && !defined(__EMSCRIPTEN__)
namespace fa {
void poll_gamepads(Input&) {}
}  // namespace fa
#endif
