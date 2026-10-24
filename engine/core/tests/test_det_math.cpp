// Deterministic math (fa/core/det_math.h, M26.21): accuracy against the C library, and exact committed bit patterns, so a
// platform that computes them differently fails right here and not as a different physics replay far away.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <cstring>
#include <initializer_list>
#include <ios>

#include "fa/core/det_math.h"

namespace {
std::uint32_t bits_of(float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    return u;
}
}  // namespace

TEST_CASE("det math: sin and cos stay within 2 ulp / 1e-7 of the C library over a dense sweep") {
    double worst = 0;
    for (int i = -200000; i <= 200000; ++i) {
        const float x = float(i) * 0.0005f;  // -100 .. 100 rad
        float s, c;
        fa::det::sin_cos(x, s, c);
        worst = std::fmax(worst, std::fabs(double(s) - std::sin(double(x))));
        worst = std::fmax(worst, std::fabs(double(c) - std::cos(double(x))));
        CHECK(s == fa::det::sin(x));
        CHECK(c == fa::det::cos(x));
    }
    CHECK(worst < 1.2e-7);  // half an ulp at 1 is 6e-8: the result is the float nearest the exact value, give or take one
    for (float x : {1e3f, 12345.678f, -54321.0f, 1e5f, 3e5f, 1e7f, -2.5e9f}) {
        CHECK(std::fabs(double(fa::det::sin(x)) - std::sin(double(x))) < 1e-6);
        CHECK(std::fabs(double(fa::det::cos(x)) - std::cos(double(x))) < 1e-6);
    }
    CHECK(fa::det::sin(0.0f) == 0.0f);
    CHECK(fa::det::cos(0.0f) == 1.0f);
    CHECK(std::isnan(fa::det::sin(INFINITY)));
}

TEST_CASE("det math: atan2, asin and acos stay close to the C library") {
    double worst = 0;
    for (int i = 0; i < 720; ++i) {
        const double a = (double(i) + 0.37) * 0.00872664626;  // a full turn
        for (float r : {0.001f, 1.0f, 250.0f}) {
            const float y = float(std::sin(a)) * r, x = float(std::cos(a)) * r;
            worst = std::fmax(worst, std::fabs(double(fa::det::atan2(y, x)) - std::atan2(double(y), double(x))));
        }
    }
    CHECK(worst < 2e-7);
    CHECK(fa::det::atan2(0.0f, 0.0f) == 0.0f);
    CHECK(fa::det::atan2(1.0f, 0.0f) == doctest::Approx(1.5707964f));
    CHECK(fa::det::atan2(0.0f, -1.0f) == doctest::Approx(3.1415927f));
    CHECK(fa::det::atan2(-0.0f, -1.0f) == doctest::Approx(-3.1415927f));
    CHECK(fa::det::atan2(-1.0f, 0.0f) == doctest::Approx(-1.5707964f));
    worst = 0;
    for (int i = -1000; i <= 1000; ++i) {
        const float x = float(i) * 0.001f;
        worst = std::fmax(worst, std::fabs(double(fa::det::asin(x)) - std::asin(double(x))));
        worst = std::fmax(worst, std::fabs(double(fa::det::acos(x)) - std::acos(double(x))));
    }
    CHECK(worst < 2e-7);
    CHECK(fa::det::asin(2.0f) == doctest::Approx(1.5707964f));  // clamped
    CHECK(fa::det::acos(-3.0f) == doctest::Approx(3.1415927f));
    CHECK(std::isnan(fa::det::atan2(NAN, 1.0f)));
}

// The exact bits of a handful of results. If this fails on a platform, that platform computes + - * / sqrt differently
// (FP contraction on? fast-math? x87 arithmetic?), and the physics replay hash cannot match the other platforms either.
TEST_CASE("det math: exact bit patterns") {
    struct Case { const char* what; float got; std::uint32_t bits; };
    float s1, c1, s2, c2;
    fa::det::sin_cos(1.0f, s1, c1);
    fa::det::sin_cos(-123.456f, s2, c2);
    const Case cases[] = {
        {"sin(1)", s1, 0x3f576aa4u},
        {"cos(1)", c1, 0x3f0a5140u},
        {"sin(-123.456)", s2, 0x3f4dcee4u},
        {"cos(-123.456)", c2, 0xbf183f1bu},
        {"sin(0.5)", fa::det::sin(0.5f), 0x3ef57744u},
        {"cos(3)", fa::det::cos(3.0f), 0xbf7d7026u},
        {"atan2(1, 2)", fa::det::atan2(1.0f, 2.0f), 0x3eed6338u},
        {"atan2(-3, -0.25)", fa::det::atan2(-3.0f, -0.25f), 0xbfd3b43au},
        {"asin(0.3)", fa::det::asin(0.3f), 0x3e9c00adu},
        {"acos(-0.8)", fa::det::acos(-0.8f), 0x401fe0bbu},
        // The sign of zero too: the replay hash feeds raw bits, and asin(-0) once gave +0 with Clang, -0 with MSVC.
        {"asin(-0)", fa::det::asin(-0.0f), 0x80000000u},
        {"asin(+0)", fa::det::asin(0.0f), 0x00000000u},
        {"atan2(-0, 2)", fa::det::atan2(-0.0f, 2.0f), 0x80000000u},
        {"atan2(+0, 2)", fa::det::atan2(0.0f, 2.0f), 0x00000000u},
    };
    for (const Case& c : cases) {
        INFO(c.what << " = 0x" << std::hex << bits_of(c.got));
        CHECK(bits_of(c.got) == c.bits);
    }
}
