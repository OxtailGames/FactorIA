#include "fa/scene/jitter.h"

#include <algorithm>

namespace fa {

float halton(std::uint32_t index, std::uint32_t base) {
    if (base < 2) return 0.0f;
    double f = 1.0, r = 0.0;
    std::uint32_t i = index;
    while (i > 0) {
        f /= double(base);
        r += f * double(i % base);
        i /= base;
    }
    return float(r);
}

Vec2 jitter_offset_pixels(std::uint64_t frameIndex, int phases) {
    const int n = std::clamp(phases, 1, kJitterPhasesMax);
    const std::uint32_t index = std::uint32_t(frameIndex % std::uint64_t(n)) + 1u;
    return {halton(index, 2) - 0.5f, halton(index, 3) - 0.5f};
}

Vec2 jitter_pixels_to_ndc(Vec2 pixels, float widthPx, float heightPx) {
    const float w = std::max(widthPx, 1.0f), h = std::max(heightPx, 1.0f);
    return {2.0f * pixels.x / w, -2.0f * pixels.y / h};
}

}  // namespace fa
