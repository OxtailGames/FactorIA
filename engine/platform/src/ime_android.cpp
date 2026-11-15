// The IME backend of Android: nothing happens yet. M98.6d fills it in; this file is its alone.
#include "ime_impl.h"

namespace fa {

void ime_backend_set_enabled(bool) {}
void ime_backend_set_caret_rect(Rect) {}
void ime_backend_cancel() {}

}  // namespace fa
