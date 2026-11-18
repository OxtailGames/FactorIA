#include "hdr_encode.h"

#include <algorithm>
#include <cmath>
#include <limits>

namespace fa::render {

namespace {

float finite_or(float v, float fallback) { return std::isfinite(v) ? v : fallback; }

using Mat3 = std::array<Rgb, 3>;  // rows

Rgb mul(const Mat3& m, const Rgb& c) {
    Rgb o{};
    for (std::size_t i = 0; i < 3; ++i) o[i] = m[i][0] * c[0] + m[i][1] * c[1] + m[i][2] * c[2];
    return o;
}

float peak_of(const Rgb& c) { return std::max(c[0], std::max(c[1], c[2])); }

// ---- the tonemaps of post.glsl (same constants; post.glsl writes its matrices by columns, these are rows) -----------------------
Rgb reinhard(Rgb c) {
    for (float& v : c) v = v / (1.0f + v);
    return c;
}

Rgb aces(Rgb c) {
    for (float& v : c) {
        const float x = v * 0.6f;
        v = std::clamp((x * (2.51f * x + 0.03f)) / (x * (2.43f * x + 0.59f) + 0.14f), 0.0f, 1.0f);
    }
    return c;
}

Rgb neutral(Rgb c) {
    for (float& v : c) v = std::max(v, 0.0f);
    const float peak = peak_of(c);
    constexpr float start = 0.76f;
    if (peak <= start) return c;
    constexpr float d = 1.0f - start;
    const float newPeak = 1.0f - d * d / (peak + d - start);
    const float g = 1.0f - 1.0f / (0.15f * (peak - newPeak) + 1.0f);
    for (float& v : c) {
        v *= newPeak / peak;
        v = v + (newPeak - v) * g;
    }
    return c;
}

float agx_contrast(float x) {
    const float x2 = x * x, x4 = x2 * x2;
    return 15.5f * x4 * x2 - 40.14f * x4 * x + 31.96f * x4 - 6.868f * x2 * x + 0.4298f * x2 + 0.1191f * x - 0.00232f;
}

Rgb agx(Rgb c) {
    static const Mat3 srgbTo2020{
        {{0.6274f, 0.3293f, 0.0433f}, {0.0691f, 0.9195f, 0.0113f}, {0.0164f, 0.0880f, 0.8956f}}};
    static const Mat3 rec2020ToSrgb{
        {{1.6605f, -0.5876f, -0.0728f}, {-0.1246f, 1.1329f, -0.0083f}, {-0.0182f, -0.1006f, 1.1187f}}};
    static const Mat3 inset{{{0.856627153315983f, 0.0951212405381588f, 0.0482516061458583f},
                             {0.137318972929847f, 0.761241990602591f, 0.101439036467562f},
                             {0.11189821299995f, 0.0767994186031903f, 0.811302368396859f}}};
    static const Mat3 outset{{{1.1271005818144368f, -0.11060664309660323f, -0.016493938717834573f},
                              {-0.1413297634984383f, 1.157823702216272f, -0.016493938717834257f},
                              {-0.14132976349843826f, -0.11060664309660294f, 1.2519364065950405f}}};
    constexpr float minEv = -12.47393f, maxEv = 4.026069f;
    for (float& v : c) v = std::max(v, 0.0f);
    c = mul(inset, mul(srgbTo2020, c));
    for (float& v : c) {
        v = std::log2(std::max(v, 1e-10f));
        v = std::clamp((v - minEv) / (maxEv - minEv), 0.0f, 1.0f);
        v = agx_contrast(v);
    }
    c = mul(outset, c);
    for (float& v : c) v = std::pow(std::max(v, 0.0f), 2.2f);
    c = mul(rec2020ToSrgb, c);
    for (float& v : c) v = std::clamp(v, 0.0f, 1.0f);
    return c;
}

float grey(int mode, float x) { return tonemap_sdr({x, x, x}, mode)[0]; }

HdrShoulder make_shoulder(int mode) {
    HdrShoulder s;
    s.start = mode == 1 ? 0.76f : 0.5f;
    // The SDR curves rise from 0 to at most 1: bisect the scene value that reaches `start` (40 steps of [0, 1000]).
    float lo = 0.0f, hi = 1000.0f;
    for (int i = 0; i < 40; ++i) {
        const float mid = 0.5f * (lo + hi);
        (grey(mode, mid) < s.start ? lo : hi) = mid;
    }
    s.input = 0.5f * (lo + hi);
    const float h = std::max(s.input * 1e-3f, 1e-5f);
    s.slope = std::max((grey(mode, s.input + h) - grey(mode, s.input - h)) / (2.0f * h), 1e-4f);
    return s;
}

}  // namespace

const char* output_encode_name(OutputEncode e) {
    switch (e) {
        case OutputEncode::Sdr: return "sdr";
        case OutputEncode::ScRgb: return "scRGB";
        case OutputEncode::Hdr10: return "hdr10";
        case OutputEncode::EdrLinear: return "edrLinear";
    }
    return "sdr";
}

OutputTarget select_output(const HdrOutputInfo& info, bool floatDisplay) {
    OutputTarget t;
    t.paperWhiteNits = std::clamp(finite_or(info.paperWhiteNits, 200.0f), 80.0f, 1000.0f);
    if (!info.active) return t;
    switch (info.encoding) {
        case HdrEncoding::Sdr: return t;
        case HdrEncoding::ScRgb: t.encode = OutputEncode::ScRgb; break;
        case HdrEncoding::Hdr10: t.encode = OutputEncode::Hdr10; break;
        case HdrEncoding::Edr: t.encode = OutputEncode::EdrLinear; break;
    }
    const float h = finite_or(info.headroom, 1.0f);
    t.headroom = floatDisplay ? std::clamp(h, 1.0f, std::min(kMaxHeadroom, 10000.0f / t.paperWhiteNits)) : 1.0f;
    return t;
}

float pq_from_nits(float nits) {
    constexpr float m1 = 2610.0f / 16384.0f, m2 = 2523.0f / 4096.0f * 128.0f;
    constexpr float c1 = 3424.0f / 4096.0f, c2 = 2413.0f / 4096.0f * 32.0f, c3 = 2392.0f / 4096.0f * 32.0f;
    const float y = std::clamp(finite_or(nits, 0.0f) / 10000.0f, 0.0f, 1.0f);
    const float p = std::pow(y, m1);
    return std::pow((c1 + c2 * p) / (1.0f + c3 * p), m2);
}

float nits_from_pq(float signal) {
    constexpr float m1 = 2610.0f / 16384.0f, m2 = 2523.0f / 4096.0f * 128.0f;
    constexpr float c1 = 3424.0f / 4096.0f, c2 = 2413.0f / 4096.0f * 32.0f, c3 = 2392.0f / 4096.0f * 32.0f;
    const float e = std::pow(std::clamp(finite_or(signal, 0.0f), 0.0f, 1.0f), 1.0f / m2);
    return 10000.0f * std::pow(std::max(e - c1, 0.0f) / (c2 - c3 * e), 1.0f / m1);
}

Rgb rec709_to_rec2020(const Rgb& c) {
    static const Mat3 m{{{0.627403896f, 0.329283039f, 0.043313066f},
                         {0.069097289f, 0.919540395f, 0.011362316f},
                         {0.016391439f, 0.088013308f, 0.895595253f}}};
    return mul(m, c);
}

Rgb encode_output(OutputEncode encode, const Rgb& light, float paperWhiteNits) {
    const float pw = std::clamp(finite_or(paperWhiteNits, 200.0f), 80.0f, 1000.0f);
    Rgb o = light;
    switch (encode) {
        case OutputEncode::Sdr:
            for (float& v : o) {
                v = std::clamp(v, 0.0f, 1.0f);
                v = v <= 0.0031308f ? v * 12.92f : 1.055f * std::pow(v, 1.0f / 2.4f) - 0.055f;
            }
            break;
        case OutputEncode::ScRgb:
            for (float& v : o) v *= pw / 80.0f;
            break;
        case OutputEncode::Hdr10:
            o = rec709_to_rec2020(light);
            for (float& v : o) v = pq_from_nits(std::max(v, 0.0f) * pw);
            break;
        case OutputEncode::EdrLinear: break;
    }
    return o;
}

float half_to_float(std::uint16_t h) {
    const int sign = (h >> 15) & 1, exponent = (h >> 10) & 31, mantissa = h & 1023;
    float v;
    if (exponent == 0)
        v = std::ldexp(float(mantissa), -24);  // subnormal
    else if (exponent == 31)
        v = mantissa ? std::numeric_limits<float>::quiet_NaN() : std::numeric_limits<float>::infinity();
    else
        v = std::ldexp(float(mantissa | 1024), exponent - 25);
    return sign ? -v : v;
}

Rgb tonemap_sdr(const Rgb& c, int mode) {
    switch (mode) {
        case 1: return neutral(c);
        case 2: return aces(c);
        case 3: return agx(c);
        case 4: return reinhard(c);
        default: break;
    }
    Rgb o = c;
    for (float& v : o) v = std::clamp(v, 0.0f, 1.0f);
    return o;
}

HdrShoulder hdr_shoulder(int mode) {
    static const std::array<HdrShoulder, 5> table = [] {
        std::array<HdrShoulder, 5> t{};
        for (int m = 1; m < 5; ++m) t[std::size_t(m)] = make_shoulder(m);
        return t;
    }();
    return mode >= 1 && mode <= 4 ? table[std::size_t(mode)] : HdrShoulder{};
}

Rgb tonemap_hdr(const Rgb& c, int mode, float headroom) {
    const float hr = std::clamp(finite_or(headroom, 1.0f), 1.0f, kMaxHeadroom);
    if (mode < 1 || mode > 4) {
        Rgb o = c;
        for (float& v : o) v = std::clamp(v, 0.0f, hr);
        return o;
    }
    Rgb s = tonemap_sdr(c, mode);
    const HdrShoulder sh = hdr_shoulder(mode);
    const float cm = peak_of(c);
    if (hr <= 1.0f || !(cm > sh.input)) return s;
    const float x = sh.slope * (cm - sh.input) / (hr - sh.start);
    const float e = sh.start + (hr - sh.start) * x / (1.0f + x);
    const float t = grey(mode, cm);
    const float w = std::clamp(hr - 1.0f, 0.0f, 1.0f);
    const float peak = t + (e - t) * w;
    for (float& v : s) v *= peak / std::max(t, 1e-6f);
    return s;
}

}  // namespace fa::render
