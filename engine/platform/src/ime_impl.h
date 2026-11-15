// What a platform backend provides for fa/platform/ime.h. ime.cpp keeps the requested state and calls these only when the
// value changed. ime_default.cpp implements them as no-ops for every platform; M98.6c / 6d replace it with real code (or add
// _linux / _win32 / _apple / _android / _web files and make the default skip those platforms).
#pragma once

#include <fa/core/math.h>

namespace fa {

void ime_backend_set_enabled(bool enabled);
void ime_backend_set_caret_rect(Rect windowPixels);

}  // namespace fa
