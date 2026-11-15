// The IME backend of every platform until M98.6c (desktop, web) and M98.6d (Android, iOS) fill it in: nothing happens.
#include "ime_impl.h"

namespace fa {

void ime_backend_set_enabled(bool) {}
void ime_backend_set_caret_rect(Rect) {}

}  // namespace fa
