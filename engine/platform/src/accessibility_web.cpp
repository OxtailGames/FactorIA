// Web: CSS media queries. Browsers do not expose the text size or a screen reader: textScale 1, screenReader false.
// UNTESTED: only compiled by CI.
#include <emscripten.h>

#include "fa/platform/accessibility.h"

// Bit 0: prefers-reduced-motion: reduce. Bit 1: prefers-contrast: more or forced-colors: active.
EM_JS(int, fa_web_accessibility_bits, (), {
    if (typeof matchMedia !== 'function') return 0;
    let bits = 0;
    if (matchMedia('(prefers-reduced-motion: reduce)').matches) bits |= 1;
    if (matchMedia('(prefers-contrast: more)').matches || matchMedia('(forced-colors: active)').matches) bits |= 2;
    return bits;
});

namespace fa {

AccessibilitySettings read_system_accessibility() {
    AccessibilitySettings s;
    const int bits = fa_web_accessibility_bits();
    s.reduceMotion = (bits & 1) != 0;
    s.highContrast = (bits & 2) != 0;
    return s;
}

}  // namespace fa
