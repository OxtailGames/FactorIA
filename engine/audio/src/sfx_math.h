// The math of the sound synthesizer (sfx_render.cpp): sine, exp2, log2, pow and tanh built only from + - * / and sqrt on doubles,
// which IEEE 754 requires to be correctly rounded, so they give the same bits on every platform (the C library's versions differ
// in the last bit between glibc, Apple's libm and the MSVC CRT). Accuracy is about 1e-12, far below 16-bit audio.
// The engine is built without floating-point contraction, so a*b+c is never fused (CMakeLists.txt, "floating point").
#pragma once

#include <cmath>
#include <cstdint>

namespace fa::sfx_math {

constexpr double kLog2E = 1.4426950408889634;
constexpr double kLog2Of10 = 3.321928094887362;
constexpr double kLog10Of2 = 0.3010299956639812;
constexpr double kTwoPi = 6.283185307179586;

// sin(2 pi x) for x in turns (any finite value).
inline double sin_turns(double x) {
    x -= std::floor(x);  // [0, 1)
    double y;
    double sign = 1.0;
    if (x < 0.25)
        y = 4.0 * x;
    else if (x < 0.5)
        y = 4.0 * (0.5 - x);
    else if (x < 0.75) {
        y = 4.0 * (x - 0.5);
        sign = -1.0;
    } else {
        y = 4.0 * (1.0 - x);
        sign = -1.0;
    }
    // sin(pi/2 * y) for y in [0, 1]: its Taylor series in y (error < 1e-11).
    const double z = y * y;
    const double s = y * (1.5707963267948966 +
                          z * (-0.6459640975062462 +
                               z * (0.07969262624616703 +
                                    z * (-0.004681754135318687 +
                                         z * (0.00016044118478735975 +
                                              z * (-3.598843235212084e-06 +
                                                   z * (5.692172921967924e-08 +
                                                        z * (-6.688035109811464e-10 + z * 6.066935731106192e-12))))))));
    return sign * s;
}
inline double cos_turns(double x) { return sin_turns(x + 0.25); }

// 2^x. Out-of-range arguments are clamped to a range doubles can hold.
inline double exp2(double x) {
    if (x > 1000.0) x = 1000.0;
    if (x < -1000.0) x = -1000.0;
    const double n = std::floor(x);
    const double f = x - n;  // [0, 1)
    const double p =
        1.0 + f * (0.6931471805599453 +
                   f * (0.2402265069591007 +
                        f * (0.055504108664821576 +
                             f * (0.009618129107628477 +
                                  f * (0.0013333558146428441 +
                                       f * (0.00015403530393381606 +
                                            f * (1.5252733804059838e-05 +
                                                 f * (1.3215486790144305e-06 +
                                                      f * (1.0178086009239696e-07 +
                                                           f * (7.054911620801121e-09 +
                                                                f * (4.44553827187081e-10 +
                                                                     f * (2.5678435993488196e-11 +
                                                                          f * 1.3691488853904124e-12))))))))))));
    return std::ldexp(p, int(n));  // exact: a power-of-two scaling
}

// log2(x) for x > 0 (a value <= 0 gives -1000).
inline double log2(double x) {
    if (!(x > 0.0)) return -1000.0;
    int e = 0;
    double m = std::frexp(x, &e);  // exact; m in [0.5, 1)
    if (m < 0.7071067811865476) {
        m *= 2.0;
        e -= 1;
    }  // m in [0.707, 1.414)
    const double z = (m - 1.0) / (m + 1.0), w = z * z;  // ln(m) = 2 atanh(z), |z| <= 0.172
    const double ln =
        z * (2.0 + w * (0.6666666666666666 +
                        w * (0.4 + w * (0.2857142857142857 +
                                        w * (0.2222222222222222 +
                                             w * (0.18181818181818182 +
                                                  w * (0.15384615384615385 +
                                                       w * (0.13333333333333333 + w * 0.11764705882352941))))))));
    return double(e) + ln * kLog2E;
}

inline double pow(double a, double b) {
    if (b == 0.0) return 1.0;
    if (!(a > 0.0)) return 0.0;
    return exp2(b * log2(a));
}

inline double pow10(double x) { return exp2(x * kLog2Of10); }
inline double db_to_gain(double db) { return pow10(db / 20.0); }
inline double gain_to_db(double g) { return g > 0.0 ? 20.0 * kLog10Of2 * log2(g) : -200.0; }
inline double semitones_to_ratio(double s) { return exp2(s / 12.0); }

inline double tanh(double x) {
    if (x > 20.0) return 1.0;
    if (x < -20.0) return -1.0;
    const double e = exp2(2.0 * x * kLog2E);
    return (e - 1.0) / (e + 1.0);
}

// tan(pi f) for f = frequency / sample rate, f in (0, 0.5): the prewarped cutoff of a filter. sin / cos from sin_turns, so no libm.
inline double tan_pi(double f) {
    const double turns = f * 0.5;  // pi f radians are f / 2 turns
    return sin_turns(turns) / cos_turns(turns);
}

// splitmix64: the generator of every noise.
struct SfxRng {
    std::uint64_t s;
    std::uint64_t next() {
        std::uint64_t z = (s += 0x9E3779B97F4A7C15ull);
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
        z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
        return z ^ (z >> 31);
    }
    double signed_unit() { return double(next() >> 11) / double(1ull << 52) - 1.0; }  // [-1, 1)
};

}  // namespace fa::sfx_math
