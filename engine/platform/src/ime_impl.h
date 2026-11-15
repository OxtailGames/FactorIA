// What a platform backend provides for fa/platform/ime.h. ime.cpp keeps the requested state and calls these only when the
// value changed. exactly one of ime_linux.cpp, ime_win32.cpp, ime_apple.mm, ime_android.cpp and ime_web.cpp is compiled on each platform
// (cmake/FactoriaHelpers.cmake) and implements them as no-ops for now; M98.6c / 6d each replace their own.
#pragma once

#include <fa/core/math.h>

namespace fa {

void ime_backend_set_enabled(bool enabled);
void ime_backend_set_caret_rect(Rect framebufferPixels);
void ime_backend_cancel();

}  // namespace fa
