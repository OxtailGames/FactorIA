// What a platform backend provides for fa/platform/ime.h. ime.cpp keeps the requested state and calls these only when the
// value changed. Exactly one of ime_linux.cpp, ime_win32.cpp, ime_apple.mm, ime_android.cpp and ime_web.cpp is compiled on
// each platform (cmake/FactoriaHelpers.cmake) and implements them (ime_android.cpp through the Java class factoria.engine.Ime).
#pragma once

#include <fa/core/math.h>

namespace fa {

void ime_backend_set_enabled(bool enabled);
void ime_backend_set_caret_rect(Rect framebufferPixels);
void ime_backend_cancel();

}  // namespace fa
