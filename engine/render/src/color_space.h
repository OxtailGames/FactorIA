// sRGB <-> linear light, for SceneSettings.colorSpace "linear" (M71): the colours the author picked (tints, lights, ambient,
// fog, sky, clear colour) are sRGB-encoded values; the linear pipeline lights and blends in linear light, so they are converted
// on the CPU before they reach a shader. The shaders do the same conversion with the same formula (quad.glsl, mesh_common.glsl).
#pragma once

#include <fa/core/math.h>

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>

namespace fa::render {

// The IEC 61966-2-1 transfer functions. Input outside [0,1] is clamped on the dark side only: a value above 1 is light above
// white (an emissive 3.0) and keeps its meaning with the power curve.
inline float srgb_to_linear(float v) {
    if (!(v > 0.0f)) return 0.0f;  // also NaN
    return v <= 0.04045f ? v / 12.92f : std::pow((v + 0.055f) / 1.055f, 2.4f);
}
inline float linear_to_srgb(float v) {
    if (!(v > 0.0f)) return 0.0f;
    return v <= 0.0031308f ? v * 12.92f : 1.055f * std::pow(v, 1.0f / 2.4f) - 0.055f;
}

// A colour's rgb, converted; alpha is coverage, not light, and stays.
inline Color srgb_to_linear(const Color& c) {
    return {srgb_to_linear(c.r), srgb_to_linear(c.g), srgb_to_linear(c.b), c.a};
}
inline Color linear_to_srgb(const Color& c) {
    return {linear_to_srgb(c.r), linear_to_srgb(c.g), linear_to_srgb(c.b), c.a};
}
// Convert only when `linear` (the callers' one-liner: `ambient = to_scene(ss.ambientLight, linear)`).
inline Color to_scene(const Color& c, bool linear) { return linear ? srgb_to_linear(c) : c; }

// The 8-bit sRGB value -> linear float, for the CPU side of the sRGB texture fallback and the tests.
inline const std::array<float, 256>& srgb8_to_linear_table() {
    static const std::array<float, 256> table = [] {
        std::array<float, 256> t{};
        for (int i = 0; i < 256; ++i) t[std::size_t(i)] = srgb_to_linear(float(i) / 255.0f);
        return t;
    }();
    return table;
}

}  // namespace fa::render
