// The IME backend of Windows: nothing happens yet. M98.6c fills it in; this file is its alone.
#include "ime_impl.h"

namespace fa {

void ime_backend_set_enabled(bool) {}
void ime_backend_set_caret_rect(Rect) {}
void ime_backend_cancel() {}

}  // namespace fa
