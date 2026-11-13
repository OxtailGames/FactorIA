// M91.3: det::exp, pow, log, tan, ... and the double family det::f64. Accuracy against the C library (ulp bounds over many
// inputs), the special values, the results that must be exact, and a table of exact committed bit patterns: a platform that
// computes them differently fails right here, not as a different replay or a different Math.pow in a game script.
#include <doctest.h>

#include <bit>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <ios>
#include <limits>

#include "fa/core/det_math.h"

namespace {

std::uint64_t bits_of(double d) {
    std::uint64_t u;
    std::memcpy(&u, &d, sizeof u);
    return u;
}
std::uint32_t bits_of(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}

// Distance in units in the last place of `ref` (1e30 when one is NaN/inf and the other is not).
double ulps(double got, double ref) {
    if (got == ref) return 0;
    if (std::isnan(got) && std::isnan(ref)) return 0;
    if (!std::isfinite(got) || !std::isfinite(ref)) return 1e30;
    double u = std::nextafter(std::fabs(ref), INFINITY) - std::fabs(ref);
    if (u == 0) u = 4.9e-324;
    return std::fabs(got - ref) / u;
}

// The same in units of a float's last place.
double ulps_f(float got, float ref) {
    if (got == ref) return 0;
    if (std::isnan(got) && std::isnan(ref)) return 0;
    if (!std::isfinite(got) || !std::isfinite(ref)) return 1e30;
    double u = double(std::nextafter(std::fabs(ref), INFINITY)) - double(std::fabs(ref));
    return std::fabs(double(got) - double(ref)) / u;
}

// A fixed pseudo-random sequence (no <random>: its distributions differ between standard libraries).
struct Lcg {
    std::uint64_t s = 0x9e3779b97f4a7c15ull;
    double next01() {
        s = s * 6364136223846793005ull + 1442695040888963407ull;
        return double(s >> 11) / 9007199254740992.0;
    }
    double range(double lo, double hi) { return lo + (hi - lo) * next01(); }
    double log_range(double lo, double hi) { return std::exp(range(std::log(lo), std::log(hi))); }
};

// The references are the C library of the machine running the test (glibc, Apple's libm, the MSVC CRT, bionic, musl), whose
// own error varies by up to about one ulp: every bound against it gets this much on top. Determinism is not checked here but
// by the table of bit patterns below, which is exact.
constexpr double kLibmSlack = 1.0;

template <class F, class G>
void check_sweep(const char* what, double lo, double hi, double maxUlps, F mine, G ref, bool logScale = false) {
    Lcg rng;
    double worst = 0, at = 0;
    for (int i = 0; i < 20000; ++i) {
        const double x = logScale ? rng.log_range(lo, hi) : rng.range(lo, hi);
        const double e = ulps(mine(x), ref(x));
        if (e > worst) {
            worst = e;
            at = x;
        }
    }
    INFO(what << " [" << lo << ", " << hi << "] worst " << worst << " ulp at " << at);
    CHECK(worst <= maxUlps + kLibmSlack);
}

#define SWEEP(fn, lo, hi, maxUlps)                                                                                     \
    check_sweep(#fn, lo, hi, maxUlps, [](double x) { return fa::det::f64::fn(x); }, [](double x) { return std::fn(x); })

bool same(double a, double b) { return bits_of(a) == bits_of(b) || (std::isnan(a) && std::isnan(b)); }

}  // namespace

TEST_CASE("det math f64: accuracy against the C library over many inputs") {
    // Bounds are about twice the measured worst case; the header documents the measured ones.
    SWEEP(sin, -10, 10, 4);
    SWEEP(sin, -1.6e6, 1.6e6, 4);
    SWEEP(cos, -10, 10, 4);
    SWEEP(cos, -1.6e6, 1.6e6, 6);
    SWEEP(tan, -10, 10, 6);
    SWEEP(tan, -1e5, 1e5, 10);
    SWEEP(exp, -700, 700, 2);
    SWEEP(exp, -1, 1, 2);
    SWEEP(exp2, -1000, 1000, 2);
    SWEEP(expm1, -30, 30, 4);
    SWEEP(expm1, -1, 1, 4);
    check_sweep(
        "log", 1e-300, 1e300, 2, [](double x) { return fa::det::f64::log(x); }, [](double x) { return std::log(x); },
        true);
    SWEEP(log, 0.5, 2, 4);
    check_sweep(
        "log2", 1e-300, 1e300, 2, [](double x) { return fa::det::f64::log2(x); }, [](double x) { return std::log2(x); },
        true);
    check_sweep(
        "log10", 1e-300, 1e300, 2, [](double x) { return fa::det::f64::log10(x); },
        [](double x) { return std::log10(x); }, true);
    check_sweep(
        "log (subnormal)", 1e-320, 1e-308, 2, [](double x) { return fa::det::f64::log(x); },
        [](double x) { return std::log(x); }, true);
    SWEEP(log1p, -0.9, 3, 4);
    SWEEP(log1p, -1e-3, 1e-3, 8);
    SWEEP(atan, -100, 100, 8);
    SWEEP(atan, -1e10, 1e10, 3);
    SWEEP(asin, -1, 1, 10);
    SWEEP(acos, -1, 1, 10);
    SWEEP(sinh, -20, 20, 4);
    SWEEP(sinh, -700, 700, 4);
    SWEEP(cosh, -700, 700, 2);
    SWEEP(tanh, -10, 10, 4);
    SWEEP(asinh, -100, 100, 6);
    SWEEP(acosh, 1, 100, 6);
    SWEEP(atanh, -0.999, 0.999, 6);
    check_sweep(
        "cbrt", 1e-300, 1e300, 2, [](double x) { return fa::det::f64::cbrt(x); }, [](double x) { return std::cbrt(x); },
        true);
    SWEEP(cbrt, -1000, 1000, 2);

    Lcg rng;
    double worstPow = 0, worstAtan2 = 0, worstHypot = 0;
    for (int i = 0; i < 20000; ++i) {
        const double x = rng.range(0.01, 100), y = rng.range(-5, 5);
        // |y ln x| is at most 23 here; the error of pow is about 1.5 * |y ln x| ulp.
        worstPow =
            std::fmax(worstPow, ulps(fa::det::f64::pow(x, y), std::pow(x, y)) - 1.6 * std::fabs(y * std::log(x)));
        const double a = rng.range(-100, 100), b = rng.range(-100, 100);
        worstAtan2 = std::fmax(worstAtan2, ulps(fa::det::f64::atan2(a, b), std::atan2(a, b)));
        worstHypot = std::fmax(worstHypot, ulps(fa::det::f64::hypot(a * 1e3, b * 1e3), std::hypot(a * 1e3, b * 1e3)));
    }
    CHECK(worstPow <= 2 + kLibmSlack);
    CHECK(worstAtan2 <= 8 + kLibmSlack);
    CHECK(worstHypot <= 2 + kLibmSlack);
    CHECK(fa::det::f64::pow(7.3, 2.5) == doctest::Approx(std::pow(7.3, 2.5)).epsilon(1e-14));
    CHECK(fa::det::f64::hypot(1e200, 1e200) == doctest::Approx(1.4142135623730951e200).epsilon(1e-14));
    CHECK(fa::det::f64::hypot(1e-200, 1e-200) == doctest::Approx(1.4142135623730951e-200).epsilon(1e-14));
}

TEST_CASE("det math f64: absolute error of sin and cos beyond 1.6e6 radians") {
    Lcg rng;
    double worst = 0;
    for (int i = 0; i < 20000; ++i) {
        const double x = rng.range(-1e9, 1e9);
        worst = std::fmax(worst, std::fabs(fa::det::f64::sin(x) - std::sin(x)));
        worst = std::fmax(worst, std::fabs(fa::det::f64::cos(x) - std::cos(x)));
    }
    CHECK(worst < 2e-15);
    // Past 1e9 only the bits are promised: still a sine (|sin| <= 1, sin^2 + cos^2 = 1), the same on every platform.
    for (double x : {1e10, -3.3e12, 1e15, 7.7e18, 1e300}) {
        double s, c;
        fa::det::f64::sin_cos(x, s, c);
        CHECK(std::fabs(s) <= 1.0);
        CHECK(s * s + c * c == doctest::Approx(1.0).epsilon(1e-12));
    }
}

TEST_CASE("det math f64: special values follow C99 / IEEE 754 (and the sign of zero)") {
    namespace dm = fa::det::f64;
    const double inf = std::numeric_limits<double>::infinity();
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double specials[] = {0.0, -0.0, 1.0, -1.0, 0.5, -0.5, 2.0, -2.0, 3.0, -3.0, inf, -inf, nan};
    for (double x : specials) {
        for (double y : specials) {
            INFO("pow(" << x << ", " << y << ")");
            const double p = dm::pow(x, y), q = std::pow(x, y);
            if (std::isfinite(q) && q != 0.0)
                CHECK(ulps(p, q) <= 4 + kLibmSlack);  // 0.5^-0.5 and the like: not exact, but close
            else
                CHECK(same(p, q));
            if (!std::isnan(q)) CHECK(std::signbit(p) == std::signbit(q));
            INFO("atan2(" << x << ", " << y << ")");
            const double a = dm::atan2(x, y), b = std::atan2(x, y);
            if (std::isnan(b))
                CHECK(std::isnan(a));
            else {
                CHECK(ulps(a, b) <= 2 + kLibmSlack);
                CHECK(std::signbit(a) == std::signbit(b));
            }
        }
    }
    CHECK(dm::exp(0.0) == 1.0);
    CHECK(dm::exp(-inf) == 0.0);
    CHECK(dm::exp(inf) == inf);
    CHECK(dm::exp(710.0) == inf);
    CHECK(dm::exp(-800.0) == 0.0);
    CHECK(std::isnan(dm::exp(nan)));
    CHECK(dm::log(0.0) == -inf);
    CHECK(dm::log(-0.0) == -inf);
    CHECK(std::isnan(dm::log(-1.0)));
    CHECK(dm::log(inf) == inf);
    CHECK(dm::log(1.0) == 0.0);
    CHECK(std::isnan(dm::log2(-2.0)));
    CHECK(dm::log10(0.0) == -inf);
    CHECK(std::isnan(dm::sin(inf)));
    CHECK(std::isnan(dm::cos(-inf)));
    CHECK(std::isnan(dm::tan(nan)));
    CHECK(std::signbit(dm::sin(-0.0)));
    CHECK(std::signbit(dm::tan(-0.0)));
    CHECK(dm::cos(0.0) == 1.0);
    CHECK(dm::atan(inf) == doctest::Approx(1.5707963267948966).epsilon(1e-15));
    CHECK(std::isnan(dm::asin(1.0000001)));
    CHECK(std::isnan(dm::acos(-1.5)));
    CHECK(dm::asin(1.0) == doctest::Approx(1.5707963267948966).epsilon(1e-15));
    CHECK(dm::acos(1.0) == 0.0);
    CHECK(dm::sqrt(2.0) == std::sqrt(2.0));
}

TEST_CASE("det math f64: results that must be exact") {
    namespace dm = fa::det::f64;
    for (int e = -1070; e <= 1020; e += 7) {
        const double p = std::ldexp(1.0, e);
        CHECK(dm::log2(p) == double(e));
        CHECK(dm::exp2(double(e)) == p);
        CHECK(dm::pow(2.0, double(e)) == p);
    }
    for (int n = 0; n <= 22; ++n) {
        double p = 1;
        for (int i = 0; i < n; ++i) p *= 10.0;  // exact up to 10^22
        CHECK(dm::pow(10.0, double(n)) == p);
        CHECK(dm::log10(p) == double(n));
        CHECK(dm::pow(10.0, double(-n)) == 1.0 / p);
    }
    // Beyond 10^22 a power of ten is not a double: pow and log10 agree on the nearest one (the literal), so the round trip holds.
    CHECK(dm::pow(10.0, 23.0) == 1e23);
    CHECK(dm::pow(10.0, 25.0) == 1e25);
    CHECK(dm::pow(10.0, 300.0) == 1e300);
    CHECK(dm::pow(10.0, 308.0) == 1e308);
    CHECK(dm::pow(10.0, -25.0) == 1e-25);
    CHECK(dm::pow(10.0, -300.0) == 1e-300);
    CHECK(dm::pow(10.0, -307.0) == 1e-307);
    CHECK(dm::pow(-10.0, 25.0) == -1e25);
    CHECK(dm::pow(-10.0, 24.0) == 1e24);
    // The literals above are parsed by the compiler; these bit patterns are the correctly rounded doubles, written down, so a
    // compiler that parsed one differently could not make the table and the test agree on a wrong value.
    struct Pow10Bits {
        int n;
        double lit;
        std::uint64_t bits;
    };
    for (const Pow10Bits& c :
         {Pow10Bits{23, 1e23, 0x44B52D02C7E14AF6ull}, Pow10Bits{25, 1e25, 0x45208B2A2C280291ull},
          Pow10Bits{300, 1e300, 0x7E37E43C8800759Cull}, Pow10Bits{308, 1e308, 0x7FE1CCF385EBC8A0ull},
          Pow10Bits{-307, 1e-307, 0x0031FA182C40C60Dull}}) {
        INFO("10^" << c.n);
        CHECK(std::bit_cast<std::uint64_t>(c.lit) == c.bits);
        CHECK(std::bit_cast<std::uint64_t>(dm::pow(10.0, double(c.n))) == c.bits);
        CHECK(std::bit_cast<std::uint64_t>(dm::d::pow10_int(c.n)) == c.bits);
    }
    CHECK(dm::log10(1e23) == 23.0);
    CHECK(dm::log10(1e25) == 25.0);
    CHECK(dm::log10(1e-25) == -25.0);
    CHECK(dm::log10(1e300) == 300.0);
    CHECK(dm::log10(1e308) == 308.0);
    CHECK(dm::log10(1e-307) == -307.0);
    for (int n = -307; n <= 308; ++n) {
        INFO("n = " << n);
        CHECK(dm::log10(dm::pow(10.0, double(n))) == double(n));
    }
    for (int b = 2; b <= 12; ++b) {
        double p = 1;
        for (int n = 0; n <= 14 && p < 9e15 / b; ++n, p *= b) CHECK(dm::pow(double(b), double(n)) == p);
    }
    CHECK(dm::pow(3.0, 33.0) == 5559060566555523.0);
    CHECK(dm::pow(0.5, 3.0) == 0.125);
    CHECK(dm::pow(1.5, 4.0) == 5.0625);
    CHECK(dm::pow(-9.5, 3.0) == -857.375);
    CHECK(dm::pow(9.5, 4.0) == 8145.0625);
    CHECK(dm::pow(9.0, 2.5) == 243.0);
    CHECK(dm::pow(16.0, 0.5) == 4.0);
    CHECK(dm::pow(4.0, -1.5) == 0.125);
    CHECK(dm::pow(2.0, 0.0) == 1.0);
    CHECK(dm::pow(2.0, 1.0) == 2.0);
    CHECK(dm::exp(0.0) == 1.0);
    CHECK(dm::cbrt(27.0) == 3.0);
    CHECK(dm::cbrt(-8.0) == -2.0);
    CHECK(dm::cbrt(0.125) == 0.5);
    CHECK(dm::hypot(3.0, 4.0) == 5.0);
    CHECK(dm::hypot(-5.0, 12.0) == 13.0);
    CHECK(dm::sqrt(1.0e-300) == std::sqrt(1.0e-300));
}

TEST_CASE("det math: the float versions are within 2 ulp of the float C library and the same for 0, 1 and powers") {
    Lcg rng;
    double worst = 0;
    for (int i = 0; i < 20000; ++i) {
        const float x = float(rng.range(-8, 8)), p = float(rng.range(0.01, 50)), y = float(rng.range(-4, 4));
        auto f = [&](float got, float ref) { worst = std::fmax(worst, ulps_f(got, ref)); };
        f(fa::det::exp(x), std::exp(x));
        f(fa::det::exp2(x), std::exp2(x));
        f(fa::det::log(p), std::log(p));
        f(fa::det::log2(p), std::log2(p));
        f(fa::det::log10(p), std::log10(p));
        f(fa::det::pow(p, y), std::pow(p, y));
        f(fa::det::tan(x * 0.15f), std::tan(x * 0.15f));
        f(fa::det::atan(x), std::atan(x));
        f(fa::det::sinh(x), std::sinh(x));
        f(fa::det::cosh(x), std::cosh(x));
        f(fa::det::tanh(x), std::tanh(x));
        f(fa::det::cbrt(x), std::cbrt(x));
        f(fa::det::hypot(x, y), std::hypot(x, y));
        f(fa::det::sqrt(p), std::sqrt(p));
    }
    CHECK(worst <= 2);
    CHECK(fa::det::pow(2.0f, 10.0f) == 1024.0f);
    CHECK(fa::det::exp(0.0f) == 1.0f);
    CHECK(fa::det::pow(0.0f, 0.0f) == 1.0f);
    CHECK(fa::det::pow(5.0f, 0.0f) == 1.0f);
    CHECK(fa::det::sqrt(16.0f) == 4.0f);
    CHECK(std::isnan(fa::det::log(-1.0f)));
    CHECK(std::isnan(fa::det::pow(-2.0f, 0.5f)));
    CHECK(std::isinf(fa::det::exp(100.0f)));
    CHECK(fa::det::exp(-200.0f) == 0.0f);
}

// The exact bits of results. If this fails on a platform, that platform computes + - * / sqrt floor fmod differently
// (FP contraction on? fast-math? x87 arithmetic?): the replay hashes and every script's Math.* would drift too.
// First measured on arm64 (Apple clang, -O0 and -O2 gave the same bits); CI compares x86-64 GCC, MSVC and clang.
TEST_CASE("det math f64: exact bit patterns") {
    namespace dm = fa::det::f64;
    struct Case {
        const char* what;
        double got;
        std::uint64_t bits;
    };
    const Case cases[] = {
        {"sin(1)", dm::sin(1.0), 0x3feaed548f090ceeull},
        {"cos(1)", dm::cos(1.0), 0x3fe14a280fb5068cull},
        {"sin(-123.456)", dm::sin(-123.456), 0x3fe9b9dadc41aeb6ull},
        {"tan(1)", dm::tan(1.0), 0x3ff8eb245cbee3a5ull},
        {"tan(-2.5)", dm::tan(-2.5), 0x3fe7e79b4e00bb14ull},
        {"sin(1e7)", dm::sin(1.0e7), 0x3fdaea414a8a3351ull},
        {"cos(5e8)", dm::cos(5.0e8), 0xbfeeacfa519daddcull},
        {"exp(1)", dm::exp(1.0), 0x4005bf0a8b14576aull},
        {"exp(-5.5)", dm::exp(-5.5), 0x3f70bd4a5aca7728ull},
        {"exp(700)", dm::exp(700.0), 0x7f0d945df4f8ec8eull},
        {"exp2(0.3)", dm::exp2(0.3), 0x3ff3b2c47bff8329ull},
        {"exp2(-1074)", dm::exp2(-1074.0), 0x0000000000000001ull},
        {"log(2)", dm::log(2.0), 0x3fe62e42fefa39efull},
        {"log(10)", dm::log(10.0), 0x40026bb1bbb55516ull},
        {"log(1e-310)", dm::log(1.0e-310), 0xc0864e69394d9508ull},
        {"log2(10)", dm::log2(10.0), 0x400a934f0979a371ull},
        {"log10(7)", dm::log10(7.0), 0x3feb0b0b0b78cc3full},
        {"pow(1.1, 7.3)", dm::pow(1.1, 7.3), 0x40000abbdb22bbdeull},
        {"pow(10, -3.2)", dm::pow(10.0, -3.2), 0x3f44acda94717d60ull},
        {"pow(2, 0.5)", dm::pow(2.0, 0.5), 0x3ff6a09e667f3bcdull},
        {"pow(0.5, 3)", dm::pow(0.5, 3.0), 0x3fc0000000000000ull},
        {"pow(10, 22)", dm::pow(10.0, 22.0), 0x4480f0cf064dd592ull},
        {"pow(9, 2.5)", dm::pow(9.0, 2.5), 0x406e600000000000ull},
        {"atan(0.7)", dm::atan(0.7), 0x3fe38b112d7bd4adull},
        {"atan2(2, -3)", dm::atan2(2.0, -3.0), 0x40046dc09ec29432ull},
        {"asin(0.3)", dm::asin(0.3), 0x3fd380159e14f6feull},
        {"acos(-0.4)", dm::acos(-0.4), 0x3fffb78e047dfba5ull},
        {"sinh(0.8)", dm::sinh(0.8), 0x3fec6b5d3c9c16f0ull},
        {"cosh(2.2)", dm::cosh(2.2), 0x40124589c2cef9c1ull},
        {"tanh(0.4)", dm::tanh(0.4), 0x3fd8511573c242d7ull},
        {"cbrt(10)", dm::cbrt(10.0), 0x40013c484138704full},
        {"hypot(3, 4.5)", dm::hypot(3.0, 4.5), 0x4015a22073490377ull},
        {"expm1(1e-3)", dm::expm1(1.0e-3), 0x3f506466dfb8cf3aull},
        {"log1p(0.2)", dm::log1p(0.2), 0x3fc7565011e49675ull},
        {"asinh(1.5)", dm::asinh(1.5), 0x3ff31dc0090b63d9ull},
        {"acosh(3)", dm::acosh(3.0), 0x3ffc34366179d426ull},
        {"atanh(0.4)", dm::atanh(0.4), 0x3fdb1d10670aae9aull},
    };
    for (const Case& c : cases) {
        INFO(c.what << " = 0x" << std::hex << bits_of(c.got));
        CHECK(bits_of(c.got) == c.bits);
    }
}

TEST_CASE("det math: exact bit patterns of the float versions") {
    struct Case {
        const char* what;
        float got;
        std::uint32_t bits;
    };
    const Case cases[] = {
        {"exp(1.5)", fa::det::exp(1.5f), 0x408f69ffu},
        {"exp(-0.25)", fa::det::exp(-0.25f), 0x3f475f7du},
        {"log(3)", fa::det::log(3.0f), 0x3f8c9f54u},
        {"log2(0.1)", fa::det::log2(0.1f), 0xc0549a78u},
        {"pow(2.5, 3.3)", fa::det::pow(2.5f, 3.3f), 0x41a48c3bu},
        {"pow(0.9, 60)", fa::det::pow(0.9f, 60.0f), 0x3aeb8990u},
        {"tan(0.7)", fa::det::tan(0.7f), 0x3f57a036u},
        {"atan(1.7)", fa::det::atan(1.7f), 0x3f850052u},
        {"sqrt(2)", fa::det::sqrt(2.0f), 0x3fb504f3u},
        {"cbrt(-8.5)", fa::det::cbrt(-8.5f), 0xc0029cebu},
        {"hypot(3, 4)", fa::det::hypot(3.0f, 4.0f), 0x40a00000u},
        {"tanh(0.3)", fa::det::tanh(0.3f), 0x3e9526eeu},
        {"exp2(-3.7)", fa::det::exp2(-3.7f), 0x3d9d9624u},
        {"log10(250)", fa::det::log10(250.0f), 0x401977d9u},
    };
    for (const Case& c : cases) {
        INFO(c.what << " = 0x" << std::hex << bits_of(c.got));
        CHECK(bits_of(c.got) == c.bits);
    }
}
