#pragma once
// Deterministic math (M26.21, CC/FB-0055): sin, cos, atan2, asin and acos that give the SAME BITS on every platform.
//
// The C library's transcendentals (glibc, Apple's libm, the MSVC CRT) are each accurate to about one unit in the last place
// but round differently, so a physics step that calls std::sin on one machine and std::sin on another drifts apart. These
// functions are built only from + - * / and floor / fmod / sqrt on doubles. IEEE 754 requires those to be correctly
// rounded, so a build without fast-math and without FP contraction (the engine's CMakeLists sets both) computes identical
// results everywhere, and the final rounding to float is the only place the answer is truncated.
//
// Accuracy: within 1 ulp of the exact value for float arguments up to 1e5 radians (about 1e-7 relative to 1, and usually
// the correctly rounded float). The simulation (physics, world transforms) uses these; rendering may keep std::.
//
// M91.3 adds exp, exp2, log, log2, log10, pow, tan, atan, sqrt, hypot, sinh, cosh, tanh and cbrt (float, the same bits
// everywhere) and the whole family in double under `det::f64` (what the game scripts' Math.* uses). The float
// sin, cos, atan2, asin and acos above are frozen: the committed replay hashes depend on their exact bits.
#include <cmath>
#include <cstdint>
#include <cstring>
#include <limits>

namespace fa::det {

namespace detail {

constexpr double kHalfPi1 = 1.5707963267948966;  // pi/2 in three parts (Cody-Waite): hi + mid + lo is pi/2 to ~1e-49
constexpr double kHalfPi2 = 6.123233995736766e-17;
constexpr double kHalfPi3 = -1.4973849048591697e-33;
constexpr double kTwoOverPi = 0.6366197723675814;
constexpr double kPiD = 3.141592653589793;

// sin and cos of r for |r| <= pi/4 + a little, Taylor series.
inline double sin_poly(double r) {
    const double z = r * r;
    return r * (1.0 + z * (-0.16666666666666666 +
                           z * (0.008333333333333333 +
                                z * (-0.0001984126984126984 +
                                     z * (2.7557319223985893e-06 +
                                          z * (-2.505210838544172e-08 +
                                               z * (1.6059043836821613e-10 + z * -7.647163731819816e-13)))))));
}
inline double cos_poly(double r) {
    const double z = r * r;
    return 1.0 + z * (-0.5 + z * (0.041666666666666664 +
                                  z * (-0.001388888888888889 +
                                       z * (2.48015873015873e-05 +
                                            z * (-2.755731922398589e-07 +
                                                 z * (2.08767569878681e-09 + z * -1.1470745597729725e-11))))));
}

// atan(t) for t >= 0, any size, in double.
inline double atan_pos(double t) {
    bool inv = false;
    if (t > 1.0) {
        t = 1.0 / t;
        inv = true;
    }
    // atan(t) = 2 atan(t / (1 + sqrt(1 + t^2))): twice brings t <= 1 down to <= 0.199, where the series converges fast.
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    const double z = t * t;
    const double a =
        t *
        (1.0 + z * (-0.3333333333333333 +
                    z * (0.2 + z * (-0.14285714285714285 +
                                    z * (0.1111111111111111 +
                                         z * (-0.09090909090909091 +
                                              z * (0.07692307692307693 +
                                                   z * (-0.06666666666666667 +
                                                        z * (0.058823529411764705 + z * -0.05263157894736842)))))))));
    const double r = 4.0 * a;
    return inv ? 1.5707963267948966 - r : r;
}

}  // namespace detail

// Sine and cosine of `x` (radians) in one call: `s = sin(x)`, `c = cos(x)`. NaN or infinity gives NaN for both.
inline void sin_cos(float x, float& s, float& c) {
    double xd = double(x);
    if (!(xd == xd) || xd > 1e30 || xd < -1e30) {
        s = c = std::nanf("");
        return;
    }
    if (xd > 1e5 || xd < -1e5) xd = std::fmod(xd, 2.0 * detail::kPiD);  // exact; keeps the reduction below accurate
    const double n = std::floor(xd * detail::kTwoOverPi + 0.5);
    const double r = ((xd - n * detail::kHalfPi1) - n * detail::kHalfPi2) - n * detail::kHalfPi3;
    const double sr = detail::sin_poly(r), cr = detail::cos_poly(r);
    switch (static_cast<std::int64_t>(n) & 3) {
        case 0:
            s = float(sr);
            c = float(cr);
            break;
        case 1:
            s = float(cr);
            c = float(-sr);
            break;
        case 2:
            s = float(-sr);
            c = float(-cr);
            break;
        default:
            s = float(-cr);
            c = float(sr);
            break;
    }
}
// Sine of `x` radians.
inline float sin(float x) {
    float s, c;
    sin_cos(x, s, c);
    return s;
}
// Cosine of `x` radians.
inline float cos(float x) {
    float s, c;
    sin_cos(x, s, c);
    return c;
}

namespace detail {
// atan2 in double: the angle of (x, y) in [-pi, pi]. (0, 0) gives 0; y = -0 gives -0 (or -pi), like std::atan2.
// The magnitudes use std::fabs, never `v < 0 ? -v : v`: that keeps -0 negative, and MSVC (even with /fp:precise) turns
// it into fabs anyway, so asin(-0) came out +0 on one compiler and -0 on the other (the replay hash test caught it).
inline double atan2_d(double yd, double xd) {
    if (yd == 0.0 && xd == 0.0) return 0.0;
    const double ay = std::fabs(yd), ax = std::fabs(xd);
    double a = ax == 0.0 ? 1.5707963267948966 : atan_pos(ay / ax);
    if (xd < 0.0) a = kPiD - a;
    return std::signbit(yd) ? -a : a;
}
inline double clamp_unit(float x) { return x < -1.0f ? -1.0 : (x > 1.0f ? 1.0 : double(x)); }
}  // namespace detail

// Angle in radians, in [-pi, pi], of the point (x, y) seen from the origin, like std::atan2(y, x). atan2(0, 0) is 0. NaN in,
// NaN out.
inline float atan2(float y, float x) {
    if (!(y == y) || !(x == x)) return std::nanf("");
    return float(detail::atan2_d(double(y), double(x)));
}
// Arc sine in radians, in [-pi/2, pi/2]. `x` is clamped to [-1, 1]; NaN gives NaN.
inline float asin(float x) {
    if (!(x == x)) return x;
    const double xd = detail::clamp_unit(x);
    return float(detail::atan2_d(xd, std::sqrt((1.0 - xd) * (1.0 + xd))));
}
// Arc cosine in radians, in [0, pi]. `x` is clamped to [-1, 1]; NaN gives NaN.
inline float acos(float x) {
    if (!(x == x)) return x;
    const double xd = detail::clamp_unit(x);
    return float(detail::atan2_d(std::sqrt((1.0 - xd) * (1.0 + xd)), xd));
}

// ---------------------------------------------------------------------------------------------------------------------
// Double precision (M91.3): the same family in `double`, for the places that cannot round to float first (the game
// scripts' Math.* and `**`, engine/script/quickjs_det/) and as the core of the float functions below. Every function
// here is made of + - * / sqrt, floor, fmod, fabs, copysign and bit patterns of doubles: all of them exact or correctly
// rounded by IEEE 754, so the bits are the same on x86-64, arm64 and WebAssembly. No fma, no long double, no libm call.
// sqrt is exact too (IEEE requires the correctly rounded result), so `std::sqrt` IS the deterministic square root and
// det::sqrt is only a name for it.
//
// Accuracy against the C library (measured in the core tests, "det math: f64 accuracy"): exp, exp2, log, log2, log10,
// cosh, cbrt and hypot within 2 ulp; sin and cos within 3 ulp (up to 1.6e6 radians; up to 1e9 the absolute error stays
// below 1e-15; beyond that they only promise the same bits everywhere, not the exact angle); tan, expm1, log1p, sinh,
// tanh, asinh, acosh, atanh and atan within 6 ulp; atan2, asin and acos within 6 ulp; pow has a relative error of up
// to about 1.5 * |y ln x| * 2^-52 (a few ulp for results between 0.01 and 100) and is EXACT whenever the true result
// is a double and the exponent is an integer or half an integer of a perfect square (2^10, 10^22, 0.5^3, 9^2.5,
// ...), and for the exponents 0, 0.5, 1, 2 and -1; 10^n for -307 <= n <= 308 is the double nearest to the true power
// (also where it is not exactly a double, from 10^23), so Math.floor(Math.log10(1e25)) is 25.
// ---------------------------------------------------------------------------------------------------------------------
namespace f64 {

namespace k {
constexpr double kInf = std::numeric_limits<double>::infinity();
constexpr double kPi = 3.141592653589793;
constexpr double kHalfPi = 1.5707963267948966;
constexpr double kQuarterPi = 0.7853981633974483;
// pi/2 = P1 + P2 + P3: P1 and P2 have 33 significant bits, so n * P1 and n * P2 are exact for |n| < 2^20.
constexpr double kP1 = 1.5707963267341256;
constexpr double kP2 = 6.077100506303966e-11;
constexpr double kP3 = 2.0222662487959506e-21;
constexpr double kTwoOverPi = 0.6366197723675814;
// ln 2 = Hi + Lo; Hi has 32 significant bits so k * Hi is exact for |k| < 2^21.
constexpr double kLn2Hi = 0.6931471803691238;
constexpr double kLn2Lo = 1.9082149292705877e-10;
constexpr double kLn2 = 0.6931471805599453;
constexpr double kInvLn2 = 1.4426950408889634;
constexpr double kInvLn10 = 0.4342944819032518;
constexpr double kLog10Of2 = 0.3010299956639812;
constexpr double kSqrt2 = 1.4142135623730951;
}  // namespace k

namespace d {

inline std::uint64_t bits(double x) {
    std::uint64_t u;
    std::memcpy(&u, &x, sizeof u);
    return u;
}
inline double from_bits(std::uint64_t u) {
    double x;
    std::memcpy(&x, &u, sizeof x);
    return x;
}
inline bool is_inf(double x) { return std::fabs(x) == k::kInf; }
inline double nan() { return std::numeric_limits<double>::quiet_NaN(); }

// 2^e exactly, for e in [-1022, 1023].
inline double pow2(int e) { return from_bits(std::uint64_t(e + 1023) << 52); }
// y * 2^e with at most one rounding (overflow to infinity, gradual underflow), for any int e.
inline double scale2(double y, int e) {
    if (e > 1023) {
        y *= pow2(1023);
        e -= 1023;
        if (e > 1023) {
            y *= pow2(1023);
            e -= 1023;
            if (e > 1023) e = 1023;
        }
    } else if (e < -1022) {
        y *= pow2(-1022);
        e += 1022;
        if (e < -1022) {
            y *= pow2(-1022);
            e += 1022;
            if (e < -1022) e = -1022;
        }
    }
    return y * pow2(e);
}
// x = m * 2^e with m in [sqrt(1/2), sqrt(2)); x finite and > 0.
inline double split_mantissa(double x, int& e) {
    int adjust = 0;
    if (x < 2.2250738585072014e-308) {
        x *= 18014398509481984.0;
        adjust = -54;
    }  // subnormal: times 2^54
    const std::uint64_t u = bits(x);
    e = int((u >> 52) & 0x7ff) - 1023 + adjust;
    double m = from_bits((u & 0x000fffffffffffffull) | 0x3ff0000000000000ull);
    if (m > k::kSqrt2) {
        m *= 0.5;
        e += 1;
    }
    return m;
}
inline bool is_integer(double y) { return std::fabs(y) >= 4503599627370496.0 || std::floor(y) == y; }
inline bool is_odd_integer(double y) {
    return std::fabs(y) < 9007199254740992.0 && std::floor(y) == y && std::fmod(y, 2.0) != 0.0;
}

// e^r - 1 for |r| <= 0.5: r + r^2/2 + ... + r^17/17!.
inline double expm1_core(double r) {
    const double q =
        0.5 +
        r * (0.16666666666666666 +
             r * (0.041666666666666664 +
                  r * (0.008333333333333333 +
                       r * (0.001388888888888889 +
                            r * (0.0001984126984126984 +
                                 r * (2.48015873015873e-05 +
                                      r * (2.7557319223985893e-06 +
                                           r * (2.755731922398589e-07 +
                                                r * (2.505210838544172e-08 +
                                                     r * (2.08767569878681e-09 +
                                                          r * (1.6059043836821613e-10 +
                                                               r * (1.1470745597729725e-11 +
                                                                    r * (7.647163731819816e-13 +
                                                                         r * (4.779477332387385e-14 +
                                                                              r * 2.8114572543455206e-15))))))))))))));
    return r + r * r * q;
}

// log(m) for m in [sqrt(1/2), sqrt(2)]: 2 atanh(s) with s = (m - 1) / (m + 1), |s| <= 0.1716.
inline double log_core(double m) {
    const double f = m - 1.0;
    const double s = f / (2.0 + f);
    const double z = s * s;
    const double r =
        0.3333333333333333 +
        z * (0.2 + z * (0.14285714285714285 +
                        z * (0.1111111111111111 +
                             z * (0.09090909090909091 +
                                  z * (0.07692307692307693 +
                                       z * (0.06666666666666667 +
                                            z * (0.058823529411764705 +
                                                 z * (0.05263157894736842 +
                                                      z * (0.047619047619047616 + z * 0.043478260869565216)))))))));
    return 2.0 * s + s * (2.0 * z * r);
}

// sin and cos of r, |r| <= pi/4 + a little: Taylor series to r^19 and r^18.
inline double sin_poly(double r) {
    const double z = r * r;
    return r *
           (1.0 + z * (-0.16666666666666666 +
                       z * (0.008333333333333333 +
                            z * (-0.0001984126984126984 +
                                 z * (2.7557319223985893e-06 +
                                      z * (-2.505210838544172e-08 +
                                           z * (1.6059043836821613e-10 +
                                                z * (-7.647163731819816e-13 +
                                                     z * (2.8114572543455206e-15 + z * -8.22063524662433e-18)))))))));
}
inline double cos_poly(double r) {
    const double z = r * r;
    return 1.0 +
           z * (-0.5 + z * (0.041666666666666664 +
                            z * (-0.001388888888888889 +
                                 z * (2.48015873015873e-05 +
                                      z * (-2.755731922398589e-07 +
                                           z * (2.08767569878681e-09 +
                                                z * (-1.1470745597729725e-11 +
                                                     z * (4.779477332387385e-14 + z * -1.5619206968586225e-16))))))));
}

// x = n * pi/2 + r with |r| <= pi/4 (a little more): returns n (use n & 3 for the quadrant) and r.
// Up to 1.6e6 radians the products n * P1 and n * P2 are exact and r keeps full relative accuracy. Up to 1e9 the multiples
// of 2*pi are removed first (fmod by the 33-bit head of 2*pi is exact) and the rest of 2*pi is subtracted from a small
// number, so the absolute error of r stays below about 1e-15. Beyond 1e9 the argument is reduced by the rounded 2*pi:
// the same bits everywhere, but not the exact angle (the result is still a valid sine, cosine or tangent of some angle).
inline std::int64_t reduce_half_pi(double x, double& r) {
    const double ax = std::fabs(x);
    double c = 0.0;  // what the 2*pi pieces beyond the 33-bit head add up to
    if (ax > 1e9) {
        x = std::fmod(x, 6.283185307179586);
    } else if (ax > 1.6e6) {
        const double q = 4.0 * k::kP1;  // 2*pi, first 33 bits: fmod(x, q) is exact
        const double xr = std::fmod(x, q);
        const double nq = std::floor((x - xr) / q + 0.5);
        c = nq * (4.0 * k::kP2) + nq * (4.0 * k::kP3);
        x = xr;
    }
    const double n = std::floor(x * k::kTwoOverPi + 0.5);
    r = (((x - n * k::kP1) - c) - n * k::kP2) - n * k::kP3;
    return static_cast<std::int64_t>(n);
}

// atan(t) for t >= 0 (infinity allowed).
inline double atan_pos(double t) {
    bool inv = false;
    if (t > 1.0) {
        t = 1.0 / t;
        inv = true;
    }
    t = t / (1.0 + std::sqrt(1.0 + t * t));  // atan(t) = 2 atan(t / (1 + sqrt(1 + t^2))), twice: t <= 0.199
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    const double z = t * t;
    const double a =
        t * (1.0 +
             z * (-0.3333333333333333 +
                  z * (0.2 + z * (-0.14285714285714285 +
                                  z * (0.1111111111111111 +
                                       z * (-0.09090909090909091 +
                                            z * (0.07692307692307693 +
                                                 z * (-0.06666666666666667 +
                                                      z * (0.058823529411764705 +
                                                           z * (-0.05263157894736842 +
                                                                z * (0.047619047619047616 +
                                                                     z * (-0.043478260869565216 + z * 0.04))))))))))));
    const double r = 4.0 * a;
    return inv ? k::kHalfPi - r : r;
}

// a^y for a power of two a = 2^e and an integer y: exact (or 0 / infinity), whatever y. False when a is not a power of two.
inline bool pow_of_two(double a, double y, double& out) {
    const std::uint64_t u = bits(a);
    const int be = int((u >> 52) & 0x7ff);
    if (be == 0 || (u & 0x000fffffffffffffull) != 0) return false;
    const double yc = y > 4000.0 ? 4000.0 : (y < -4000.0 ? -4000.0 : y);
    out = scale2(1.0, (be - 1023) * static_cast<int>(yc));
    return true;
}

// a^n for a finite a > 0 and 1 <= n <= 64 when the result is exactly representable (a = M * 2^e with M odd, M^n < 2^53),
// computed exactly; false when it is not (the caller then uses exp / log).
inline bool exact_pow(double a, int n, double& out) {
    constexpr double kLimit = 9007199254740992.0;
    const std::uint64_t u = bits(a);
    const int be = int((u >> 52) & 0x7ff);
    std::uint64_t m = be == 0 ? (u & 0x000fffffffffffffull) : ((u & 0x000fffffffffffffull) | 0x0010000000000000ull);
    int e = be == 0 ? -1074 : be - 1075;
    while (!(m & 1)) {
        m >>= 1;
        ++e;
    }
    double p = 1.0, b = double(m);
    for (int i = n; i > 0; i >>= 1) {
        if (i & 1) {
            p *= b;
            if (p >= kLimit) return false;
        }
        if (i > 1) {
            b *= b;
            if (b >= kLimit) return false;
        }
    }
    out = scale2(p, e * n);
    return true;
}

// 10^n for -307 <= n <= 308: the double nearest to the true power, which is what the literal 1eN is (a compiler
// parses it correctly rounded, the same on every platform). For n above 22 the power is not a double (10^23 is not),
// so pow and log10 cannot get it by multiplying and must agree on this value: log10 of 1e25 is 25, not
// 24.999999999999996.
inline double pow10_int(int n) {
    static constexpr double kPos[309] = {
        1e0,   1e1,   1e2,   1e3,   1e4,   1e5,   1e6,   1e7,   1e8,   1e9,   1e10,  1e11,  1e12,  1e13,  1e14,  1e15,
        1e16,  1e17,  1e18,  1e19,  1e20,  1e21,  1e22,  1e23,  1e24,  1e25,  1e26,  1e27,  1e28,  1e29,  1e30,  1e31,
        1e32,  1e33,  1e34,  1e35,  1e36,  1e37,  1e38,  1e39,  1e40,  1e41,  1e42,  1e43,  1e44,  1e45,  1e46,  1e47,
        1e48,  1e49,  1e50,  1e51,  1e52,  1e53,  1e54,  1e55,  1e56,  1e57,  1e58,  1e59,  1e60,  1e61,  1e62,  1e63,
        1e64,  1e65,  1e66,  1e67,  1e68,  1e69,  1e70,  1e71,  1e72,  1e73,  1e74,  1e75,  1e76,  1e77,  1e78,  1e79,
        1e80,  1e81,  1e82,  1e83,  1e84,  1e85,  1e86,  1e87,  1e88,  1e89,  1e90,  1e91,  1e92,  1e93,  1e94,  1e95,
        1e96,  1e97,  1e98,  1e99,  1e100, 1e101, 1e102, 1e103, 1e104, 1e105, 1e106, 1e107, 1e108, 1e109, 1e110, 1e111,
        1e112, 1e113, 1e114, 1e115, 1e116, 1e117, 1e118, 1e119, 1e120, 1e121, 1e122, 1e123, 1e124, 1e125, 1e126, 1e127,
        1e128, 1e129, 1e130, 1e131, 1e132, 1e133, 1e134, 1e135, 1e136, 1e137, 1e138, 1e139, 1e140, 1e141, 1e142, 1e143,
        1e144, 1e145, 1e146, 1e147, 1e148, 1e149, 1e150, 1e151, 1e152, 1e153, 1e154, 1e155, 1e156, 1e157, 1e158, 1e159,
        1e160, 1e161, 1e162, 1e163, 1e164, 1e165, 1e166, 1e167, 1e168, 1e169, 1e170, 1e171, 1e172, 1e173, 1e174, 1e175,
        1e176, 1e177, 1e178, 1e179, 1e180, 1e181, 1e182, 1e183, 1e184, 1e185, 1e186, 1e187, 1e188, 1e189, 1e190, 1e191,
        1e192, 1e193, 1e194, 1e195, 1e196, 1e197, 1e198, 1e199, 1e200, 1e201, 1e202, 1e203, 1e204, 1e205, 1e206, 1e207,
        1e208, 1e209, 1e210, 1e211, 1e212, 1e213, 1e214, 1e215, 1e216, 1e217, 1e218, 1e219, 1e220, 1e221, 1e222, 1e223,
        1e224, 1e225, 1e226, 1e227, 1e228, 1e229, 1e230, 1e231, 1e232, 1e233, 1e234, 1e235, 1e236, 1e237, 1e238, 1e239,
        1e240, 1e241, 1e242, 1e243, 1e244, 1e245, 1e246, 1e247, 1e248, 1e249, 1e250, 1e251, 1e252, 1e253, 1e254, 1e255,
        1e256, 1e257, 1e258, 1e259, 1e260, 1e261, 1e262, 1e263, 1e264, 1e265, 1e266, 1e267, 1e268, 1e269, 1e270, 1e271,
        1e272, 1e273, 1e274, 1e275, 1e276, 1e277, 1e278, 1e279, 1e280, 1e281, 1e282, 1e283, 1e284, 1e285, 1e286, 1e287,
        1e288, 1e289, 1e290, 1e291, 1e292, 1e293, 1e294, 1e295, 1e296, 1e297, 1e298, 1e299, 1e300, 1e301, 1e302, 1e303,
        1e304, 1e305, 1e306, 1e307, 1e308};
    static constexpr double kNeg[307] = {
        1e-1,   1e-2,   1e-3,   1e-4,   1e-5,   1e-6,   1e-7,   1e-8,   1e-9,   1e-10,  1e-11,  1e-12,  1e-13,  1e-14,
        1e-15,  1e-16,  1e-17,  1e-18,  1e-19,  1e-20,  1e-21,  1e-22,  1e-23,  1e-24,  1e-25,  1e-26,  1e-27,  1e-28,
        1e-29,  1e-30,  1e-31,  1e-32,  1e-33,  1e-34,  1e-35,  1e-36,  1e-37,  1e-38,  1e-39,  1e-40,  1e-41,  1e-42,
        1e-43,  1e-44,  1e-45,  1e-46,  1e-47,  1e-48,  1e-49,  1e-50,  1e-51,  1e-52,  1e-53,  1e-54,  1e-55,  1e-56,
        1e-57,  1e-58,  1e-59,  1e-60,  1e-61,  1e-62,  1e-63,  1e-64,  1e-65,  1e-66,  1e-67,  1e-68,  1e-69,  1e-70,
        1e-71,  1e-72,  1e-73,  1e-74,  1e-75,  1e-76,  1e-77,  1e-78,  1e-79,  1e-80,  1e-81,  1e-82,  1e-83,  1e-84,
        1e-85,  1e-86,  1e-87,  1e-88,  1e-89,  1e-90,  1e-91,  1e-92,  1e-93,  1e-94,  1e-95,  1e-96,  1e-97,  1e-98,
        1e-99,  1e-100, 1e-101, 1e-102, 1e-103, 1e-104, 1e-105, 1e-106, 1e-107, 1e-108, 1e-109, 1e-110, 1e-111, 1e-112,
        1e-113, 1e-114, 1e-115, 1e-116, 1e-117, 1e-118, 1e-119, 1e-120, 1e-121, 1e-122, 1e-123, 1e-124, 1e-125, 1e-126,
        1e-127, 1e-128, 1e-129, 1e-130, 1e-131, 1e-132, 1e-133, 1e-134, 1e-135, 1e-136, 1e-137, 1e-138, 1e-139, 1e-140,
        1e-141, 1e-142, 1e-143, 1e-144, 1e-145, 1e-146, 1e-147, 1e-148, 1e-149, 1e-150, 1e-151, 1e-152, 1e-153, 1e-154,
        1e-155, 1e-156, 1e-157, 1e-158, 1e-159, 1e-160, 1e-161, 1e-162, 1e-163, 1e-164, 1e-165, 1e-166, 1e-167, 1e-168,
        1e-169, 1e-170, 1e-171, 1e-172, 1e-173, 1e-174, 1e-175, 1e-176, 1e-177, 1e-178, 1e-179, 1e-180, 1e-181, 1e-182,
        1e-183, 1e-184, 1e-185, 1e-186, 1e-187, 1e-188, 1e-189, 1e-190, 1e-191, 1e-192, 1e-193, 1e-194, 1e-195, 1e-196,
        1e-197, 1e-198, 1e-199, 1e-200, 1e-201, 1e-202, 1e-203, 1e-204, 1e-205, 1e-206, 1e-207, 1e-208, 1e-209, 1e-210,
        1e-211, 1e-212, 1e-213, 1e-214, 1e-215, 1e-216, 1e-217, 1e-218, 1e-219, 1e-220, 1e-221, 1e-222, 1e-223, 1e-224,
        1e-225, 1e-226, 1e-227, 1e-228, 1e-229, 1e-230, 1e-231, 1e-232, 1e-233, 1e-234, 1e-235, 1e-236, 1e-237, 1e-238,
        1e-239, 1e-240, 1e-241, 1e-242, 1e-243, 1e-244, 1e-245, 1e-246, 1e-247, 1e-248, 1e-249, 1e-250, 1e-251, 1e-252,
        1e-253, 1e-254, 1e-255, 1e-256, 1e-257, 1e-258, 1e-259, 1e-260, 1e-261, 1e-262, 1e-263, 1e-264, 1e-265, 1e-266,
        1e-267, 1e-268, 1e-269, 1e-270, 1e-271, 1e-272, 1e-273, 1e-274, 1e-275, 1e-276, 1e-277, 1e-278, 1e-279, 1e-280,
        1e-281, 1e-282, 1e-283, 1e-284, 1e-285, 1e-286, 1e-287, 1e-288, 1e-289, 1e-290, 1e-291, 1e-292, 1e-293, 1e-294,
        1e-295, 1e-296, 1e-297, 1e-298, 1e-299, 1e-300, 1e-301, 1e-302, 1e-303, 1e-304, 1e-305, 1e-306, 1e-307};
    return n >= 0 ? kPos[n] : kNeg[-n - 1];
}

}  // namespace d

// ---- exponentials and logarithms -------------------------------------------------------------------------------------

// e^x. Overflow gives +infinity, underflow 0; NaN gives NaN.
inline double exp(double x) {
    if (!(x == x)) return x;
    if (x > 710.0) return k::kInf;
    if (x < -746.0) return 0.0;
    const double n = std::floor(x * k::kInvLn2 + 0.5);
    const double r = (x - n * k::kLn2Hi) - n * k::kLn2Lo;
    return d::scale2(1.0 + d::expm1_core(r), static_cast<int>(n));
}
// 2^x. Exact for integer x.
inline double exp2(double x) {
    if (!(x == x)) return x;
    if (x > 1100.0) return k::kInf;
    if (x < -1100.0) return 0.0;
    const double n = std::floor(x + 0.5);
    return d::scale2(1.0 + d::expm1_core((x - n) * k::kLn2), static_cast<int>(n));
}
// e^x - 1, accurate for x near 0.
inline double expm1(double x) {
    if (!(x == x)) return x;
    if (x > 710.0) return k::kInf;
    if (x < -40.0) return -1.0;
    if (std::fabs(x) < 0.5) return d::expm1_core(x);
    return exp(x) - 1.0;
}
// Natural logarithm. log(0) is -infinity, a negative number gives NaN.
inline double log(double x) {
    if (!(x == x)) return x;
    if (x < 0.0) return d::nan();
    if (x == 0.0) return -k::kInf;
    if (x == k::kInf) return x;
    int e;
    const double m = d::split_mantissa(x, e);
    const double ed = double(e);
    return ed * k::kLn2Hi + (d::log_core(m) + ed * k::kLn2Lo);
}
// Base 2 logarithm. Exact for the powers of two.
inline double log2(double x) {
    if (!(x == x)) return x;
    if (x < 0.0) return d::nan();
    if (x == 0.0) return -k::kInf;
    if (x == k::kInf) return x;
    int e;
    const double m = d::split_mantissa(x, e);
    return double(e) + d::log_core(m) * k::kInvLn2;
}
// Base 10 logarithm. Exact for the powers of ten: the double nearest to 10^n (the literal 1eN, -307 <= n <= 308) gives n.
inline double log10(double x) {
    if (!(x == x)) return x;
    if (x < 0.0) return d::nan();
    if (x == 0.0) return -k::kInf;
    if (x == k::kInf) return x;
    int e;
    const double m = d::split_mantissa(x, e);
    const double r = double(e) * k::kLog10Of2 + d::log_core(m) * k::kInvLn10;
    const double n = std::floor(r + 0.5);
    if (std::fabs(r - n) < 1e-9 && n >= -307.0 && n <= 308.0 && x == d::pow10_int(int(n))) return n;
    return r;
}
// log(1 + x), accurate for x near 0.
inline double log1p(double x) {
    if (!(x == x)) return x;
    if (x < -1.0) return d::nan();
    if (x == -1.0) return -k::kInf;
    if (x == k::kInf) return x;
    const double u = 1.0 + x;
    if (u == 1.0) return x;
    return log(u) * (x / (u - 1.0));
}
// x^y with C99 / IEEE 754 special values (pow(x, 0) = 1, pow(1, y) = 1, pow(-8, 1/3) = NaN, ...).
inline double pow(double x, double y) {
    if (y == 0.0 || x == 1.0) return 1.0;
    if (!(x == x) || !(y == y)) return d::nan();
    const double ax = std::fabs(x);
    const bool yInt = d::is_integer(y), yOdd = d::is_odd_integer(y);
    if (d::is_inf(y)) {
        if (ax == 1.0) return 1.0;
        return ((ax > 1.0) == (y > 0.0)) ? k::kInf : 0.0;
    }
    if (ax == 0.0) {
        const double z = (std::signbit(x) && yOdd) ? -1.0 : 1.0;
        return y < 0.0 ? z * k::kInf : z * 0.0;
    }
    if (d::is_inf(x)) {
        const double z = (x < 0.0 && yOdd) ? -1.0 : 1.0;
        return y > 0.0 ? z * k::kInf : z * 0.0;
    }
    if (x < 0.0 && !yInt) return d::nan();
    const bool neg = x < 0.0 && yOdd;
    double r;
    if (y == 1.0)
        r = ax;
    else if (y == 2.0)
        r = ax * ax;
    else if (y == -1.0)
        r = 1.0 / ax;
    else if (y == 0.5)
        r = std::sqrt(ax);
    else if (yInt && d::pow_of_two(ax, y, r)) {
    } else if (ax == 10.0 && yInt && y >= -307.0 && y <= 308.0)
        r = d::pow10_int(int(y));  // the double nearest to 10^y
    else if (yInt && std::fabs(y) <= 64.0 && d::exact_pow(ax, int(std::fabs(y)), r)) {
        if (y < 0.0) r = 1.0 / r;
    } else if (std::fabs(y) <= 32.0 && std::floor(2.0 * y) == 2.0 * y && std::sqrt(ax) * std::sqrt(ax) == ax &&
               d::exact_pow(std::sqrt(ax), int(std::fabs(2.0 * y)), r)) {
        if (y < 0.0) r = 1.0 / r;  // x^(k/2) with x a perfect square
    } else {
        r = exp(y * log(ax));
    }
    return neg ? -r : r;
}

// ---- trigonometry -----------------------------------------------------------------------------------------------------

// Sine and cosine of `x` radians in one call. Infinity or NaN gives NaN for both.
inline void sin_cos(double x, double& s, double& c) {
    if (!(x == x) || d::is_inf(x)) {
        s = c = d::nan();
        return;
    }
    double r;
    const std::int64_t n = d::reduce_half_pi(x, r);
    const double sr = d::sin_poly(r), cr = d::cos_poly(r);
    switch (n & 3) {
        case 0:
            s = sr;
            c = cr;
            break;
        case 1:
            s = cr;
            c = -sr;
            break;
        case 2:
            s = -sr;
            c = -cr;
            break;
        default:
            s = -cr;
            c = sr;
            break;
    }
}
inline double sin(double x) {
    if (!(x == x) || d::is_inf(x)) return d::nan();
    if (x == 0.0) return x;  // keeps -0
    double r;
    const std::int64_t n = d::reduce_half_pi(x, r);
    switch (n & 3) {
        case 0: return d::sin_poly(r);
        case 1: return d::cos_poly(r);
        case 2: return -d::sin_poly(r);
        default: return -d::cos_poly(r);
    }
}
inline double cos(double x) {
    if (!(x == x) || d::is_inf(x)) return d::nan();
    double r;
    const std::int64_t n = d::reduce_half_pi(x, r);
    switch (n & 3) {
        case 0: return d::cos_poly(r);
        case 1: return -d::sin_poly(r);
        case 2: return -d::cos_poly(r);
        default: return d::sin_poly(r);
    }
}
inline double tan(double x) {
    if (!(x == x) || d::is_inf(x)) return d::nan();
    if (x == 0.0) return x;
    double r;
    const std::int64_t n = d::reduce_half_pi(x, r);
    const double sr = d::sin_poly(r), cr = d::cos_poly(r);
    return (n & 1) ? -cr / sr : sr / cr;
}
// Arc tangent in [-pi/2, pi/2].
inline double atan(double x) {
    if (!(x == x)) return x;
    const double a = d::atan_pos(std::fabs(x));
    return std::signbit(x) ? -a : a;
}
// Angle of the point (x, y) in [-pi, pi], like C99 atan2 (atan2(+-0, -0) is +-pi, atan2(+-0, +0) is +-0).
inline double atan2(double y, double x) {
    if (!(y == y) || !(x == x)) return d::nan();
    if (y == 0.0) return std::signbit(x) ? std::copysign(k::kPi, y) : y;
    if (x == 0.0) return std::copysign(k::kHalfPi, y);
    if (d::is_inf(x)) {
        if (d::is_inf(y)) return std::copysign(x > 0.0 ? k::kQuarterPi : 3.0 * k::kQuarterPi, y);
        return x > 0.0 ? std::copysign(0.0, y) : std::copysign(k::kPi, y);
    }
    if (d::is_inf(y)) return std::copysign(k::kHalfPi, y);
    double a = d::atan_pos(std::fabs(y) / std::fabs(x));
    if (x < 0.0) a = k::kPi - a;
    return std::copysign(a, y);
}
// Arc sine in [-pi/2, pi/2]; NaN when |x| > 1.
inline double asin(double x) {
    if (!(x == x) || std::fabs(x) > 1.0) return d::nan();
    return atan2(x, std::sqrt((1.0 - x) * (1.0 + x)));
}
// Arc cosine in [0, pi]; NaN when |x| > 1.
inline double acos(double x) {
    if (!(x == x) || std::fabs(x) > 1.0) return d::nan();
    return atan2(std::sqrt((1.0 - x) * (1.0 + x)), x);
}

// ---- roots, hyperbolic functions ---------------------------------------------------------------------------------------

// Square root. IEEE 754 requires the correctly rounded result from the hardware instruction on every platform, so the
// C library's sqrt IS deterministic; this is only its name in the det:: family.
inline double sqrt(double x) { return std::sqrt(x); }
inline double sinh(double x) {
    if (!(x == x) || x == 0.0 || d::is_inf(x)) return x;
    const double a = std::fabs(x);
    double r;
    if (a < 22.0) {
        const double t = expm1(a);
        r = a < 1.0 ? 0.5 * (2.0 * t - t * t / (t + 1.0)) : 0.5 * (t + t / (t + 1.0));
    } else if (a < 710.0) {
        r = 0.5 * exp(a);
    } else {
        const double w = exp(0.5 * a);  // exp(a) alone overflows; (w / 2) * w does not, up to 710.4758
        r = (0.5 * w) * w;
    }
    return std::signbit(x) ? -r : r;
}
inline double cosh(double x) {
    if (!(x == x)) return x;
    const double a = std::fabs(x);
    if (d::is_inf(a)) return k::kInf;
    if (a < 22.0) {
        const double t = exp(a);
        return 0.5 * (t + 1.0 / t);
    }
    if (a < 710.0) return 0.5 * exp(a);
    const double w = exp(0.5 * a);
    return (0.5 * w) * w;
}
inline double tanh(double x) {
    if (!(x == x) || x == 0.0) return x;
    const double a = std::fabs(x);
    double r;
    if (a >= 22.0) {
        r = 1.0;
    } else {
        const double t = expm1(2.0 * a);
        r = t / (t + 2.0);
    }
    return std::signbit(x) ? -r : r;
}
inline double asinh(double x) {
    if (!(x == x) || x == 0.0 || d::is_inf(x)) return x;
    const double a = std::fabs(x);
    double r;
    if (a >= 268435456.0)
        r = log(a) + k::kLn2;
    else if (a > 2.0)
        r = log(2.0 * a + 1.0 / (std::sqrt(a * a + 1.0) + a));
    else
        r = log1p(a + a * a / (1.0 + std::sqrt(1.0 + a * a)));
    return std::signbit(x) ? -r : r;
}
inline double acosh(double x) {
    if (!(x == x) || x < 1.0) return d::nan();
    if (x >= 268435456.0) return d::is_inf(x) ? x : log(x) + k::kLn2;
    if (x > 2.0) return log(2.0 * x - 1.0 / (x + std::sqrt(x * x - 1.0)));
    const double t = x - 1.0;
    return log1p(t + std::sqrt(2.0 * t + t * t));
}
inline double atanh(double x) {
    if (!(x == x)) return x;
    const double a = std::fabs(x);
    if (a > 1.0) return d::nan();
    if (a == 1.0) return std::copysign(k::kInf, x);
    if (a == 0.0) return x;
    const double r = a < 0.5 ? 0.5 * log1p((2.0 * a) + (2.0 * a) * a / (1.0 - a)) : 0.5 * log1p(2.0 * a / (1.0 - a));
    return std::signbit(x) ? -r : r;
}
// Cube root (negative numbers allowed): cbrt(27) is exactly 3.
inline double cbrt(double x) {
    if (!(x == x) || x == 0.0 || d::is_inf(x)) return x;
    const double a = std::fabs(x);
    double y = exp(log(a) * 0.3333333333333333);
    y = y - (y * y * y - a) / (3.0 * y * y);  // Newton: each step squares the relative error
    y = y - (y * y * y - a) / (3.0 * y * y);
    return std::signbit(x) ? -y : y;
}
// sqrt(x*x + y*y) without overflow or underflow of the squares; hypot(inf, NaN) is infinity.
inline double hypot(double x, double y) {
    const double ax = std::fabs(x), ay = std::fabs(y);
    if (d::is_inf(ax) || d::is_inf(ay)) return k::kInf;
    if (!(x == x) || !(y == y)) return d::nan();
    const double big = ax > ay ? ax : ay;
    if (big == 0.0) return 0.0;
    if (big > 1e150) return std::sqrt((ax * 1e-300) * (ax * 1e-300) + (ay * 1e-300) * (ay * 1e-300)) * 1e300;
    if (big < 1e-150) return std::sqrt((ax * 1e300) * (ax * 1e300) + (ay * 1e300) * (ay * 1e300)) * 1e-300;
    return std::sqrt(ax * ax + ay * ay);
}

}  // namespace f64

// ---- the same functions on floats ----------------------------------------------------------------------------------------
// Computed in double and rounded once to float, so they are within 1 ulp of the exact value (usually the correctly
// rounded float) and the same on every platform. NaN in, NaN out. (sin, cos, atan2, asin and acos above keep their own
// code: the committed replay hashes depend on their exact bits.)

// Square root: IEEE 754 requires the correctly rounded result, so the C library's sqrt IS deterministic.
inline float sqrt(float x) { return std::sqrt(x); }
inline float tan(float x) { return float(f64::tan(double(x))); }
inline float atan(float x) { return float(f64::atan(double(x))); }
inline float exp(float x) { return float(f64::exp(double(x))); }
inline float exp2(float x) { return float(f64::exp2(double(x))); }
inline float log(float x) { return float(f64::log(double(x))); }
inline float log2(float x) { return float(f64::log2(double(x))); }
inline float log10(float x) { return float(f64::log10(double(x))); }
inline float pow(float x, float y) { return float(f64::pow(double(x), double(y))); }
inline float sinh(float x) { return float(f64::sinh(double(x))); }
inline float cosh(float x) { return float(f64::cosh(double(x))); }
inline float tanh(float x) { return float(f64::tanh(double(x))); }
inline float cbrt(float x) { return float(f64::cbrt(double(x))); }
inline float hypot(float x, float y) { return float(f64::hypot(double(x), double(y))); }

}  // namespace fa::det
