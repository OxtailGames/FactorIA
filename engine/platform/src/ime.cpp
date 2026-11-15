#include <fa/platform/ime.h>

#include "ime_impl.h"

namespace fa {

namespace {
ImeState g_state;

bool same(const Rect& a, const Rect& b) { return a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h; }
}  // namespace

void ime_set_enabled(bool enabled) {
    if (enabled == g_state.enabled) return;
    g_state.enabled = enabled;
    if (!enabled) g_state.caretRect = {};
    ime_backend_set_enabled(enabled);
}

void ime_set_caret_rect(Rect windowPixels) {
    if (!g_state.enabled || same(windowPixels, g_state.caretRect)) return;
    g_state.caretRect = windowPixels;
    ime_backend_set_caret_rect(windowPixels);
}

ImeState ime_state() { return g_state; }
void ime_reset_state() { g_state = {}; }

}  // namespace fa
