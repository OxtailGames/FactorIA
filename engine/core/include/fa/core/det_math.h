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
#include <cmath>
#include <cstdint>

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
    return r * (1.0 + z * (-0.16666666666666666 + z * (0.008333333333333333 + z * (-0.0001984126984126984 +
                z * (2.7557319223985893e-06 + z * (-2.505210838544172e-08 + z * (1.6059043836821613e-10 +
                z * -7.647163731819816e-13)))))));
}
inline double cos_poly(double r) {
    const double z = r * r;
    return 1.0 + z * (-0.5 + z * (0.041666666666666664 + z * (-0.001388888888888889 + z * (2.48015873015873e-05 +
                z * (-2.755731922398589e-07 + z * (2.08767569878681e-09 + z * -1.1470745597729725e-11))))));
}

// atan(t) for t >= 0, any size, in double.
inline double atan_pos(double t) {
    bool inv = false;
    if (t > 1.0) { t = 1.0 / t; inv = true; }
    // atan(t) = 2 atan(t / (1 + sqrt(1 + t^2))): twice brings t <= 1 down to <= 0.199, where the series converges fast.
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    t = t / (1.0 + std::sqrt(1.0 + t * t));
    const double z = t * t;
    const double a = t * (1.0 + z * (-0.3333333333333333 + z * (0.2 + z * (-0.14285714285714285 + z * (0.1111111111111111 +
                    z * (-0.09090909090909091 + z * (0.07692307692307693 + z * (-0.06666666666666667 +
                    z * (0.058823529411764705 + z * -0.05263157894736842)))))))));
    const double r = 4.0 * a;
    return inv ? 1.5707963267948966 - r : r;
}

}  // namespace detail

// Sine and cosine of `x` (radians) in one call: `s = sin(x)`, `c = cos(x)`. NaN or infinity gives NaN for both.
inline void sin_cos(float x, float& s, float& c) {
    double xd = double(x);
    if (!(xd == xd) || xd > 1e30 || xd < -1e30) { s = c = std::nanf(""); return; }
    if (xd > 1e5 || xd < -1e5) xd = std::fmod(xd, 2.0 * detail::kPiD);  // exact; keeps the reduction below accurate
    const double n = std::floor(xd * detail::kTwoOverPi + 0.5);
    const double r = ((xd - n * detail::kHalfPi1) - n * detail::kHalfPi2) - n * detail::kHalfPi3;
    const double sr = detail::sin_poly(r), cr = detail::cos_poly(r);
    switch (static_cast<std::int64_t>(n) & 3) {
        case 0: s = float(sr); c = float(cr); break;
        case 1: s = float(cr); c = float(-sr); break;
        case 2: s = float(-sr); c = float(-cr); break;
        default: s = float(-cr); c = float(sr); break;
    }
}
// Sine of `x` radians.
inline float sin(float x) { float s, c; sin_cos(x, s, c); return s; }
// Cosine of `x` radians.
inline float cos(float x) { float s, c; sin_cos(x, s, c); return c; }

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

}  // namespace fa::det
