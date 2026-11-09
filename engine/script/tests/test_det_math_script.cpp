// M91.3: the game scripts' Math.* is the deterministic one (fa::det::f64), not the C library's: the same bits on x86-64,
// arm64 and WebAssembly (engine/script/quickjs_det/).
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>

#include "fa/core/det_math.h"
#include "test_host.h"

using namespace fa;
using namespace fa::test;

namespace {

std::uint64_t bits_of(double d) {
    std::uint64_t u;
    std::memcpy(&u, &d, sizeof u);
    return u;
}

double eval_number(TestHost& h, const std::string& code) {
    auto r = h.scripts.eval(code);
    REQUIRE_MESSAGE(r.ok(), code);
    REQUIRE_MESSAGE(r->is_number(), code);
    return r->get<double>();
}

}  // namespace

TEST_CASE("script Math: sin, cos, exp, pow and the rest are the deterministic functions, bit for bit") {
    TestHost h("det_math_script");
    REQUIRE(h.start());
    namespace f = fa::det::f64;
    struct Case {
        const char* code;
        double expected;
    };
    const Case cases[] = {
        {"Math.sin(1.2345)", f::sin(1.2345)},
        {"Math.cos(2.5)", f::cos(2.5)},
        {"Math.tan(0.7)", f::tan(0.7)},
        {"Math.asin(0.3)", f::asin(0.3)},
        {"Math.acos(0.3)", f::acos(0.3)},
        {"Math.atan(3.7)", f::atan(3.7)},
        {"Math.atan2(-1.5, 2.25)", f::atan2(-1.5, 2.25)},
        {"Math.exp(3.3)", f::exp(3.3)},
        {"Math.expm1(0.001)", f::expm1(0.001)},
        {"Math.log(10.5)", f::log(10.5)},
        {"Math.log2(10.5)", f::log2(10.5)},
        {"Math.log10(10.5)", f::log10(10.5)},
        {"Math.log1p(0.01)", f::log1p(0.01)},
        {"Math.pow(1.1, 7.7)", f::pow(1.1, 7.7)},
        {"1.1 ** 7.7", f::pow(1.1, 7.7)},  // ** is the same function
        {"Math.sinh(0.9)", f::sinh(0.9)},
        {"Math.cosh(0.9)", f::cosh(0.9)},
        {"Math.tanh(0.9)", f::tanh(0.9)},
        {"Math.asinh(0.9)", f::asinh(0.9)},
        {"Math.acosh(1.9)", f::acosh(1.9)},
        {"Math.atanh(0.9)", f::atanh(0.9)},
        {"Math.cbrt(10)", f::cbrt(10.0)},
        {"Math.hypot(3.3, 4.4)", f::hypot(3.3, 4.4)},
    };
    for (const Case& c : cases) {
        const double got = eval_number(h, c.code);
        INFO(c.code << " got " << got << " expected " << c.expected);
        CHECK(bits_of(got) == bits_of(c.expected));
    }
    // Exact results stay exact, and the integer cases the games rely on.
    CHECK(eval_number(h, "Math.pow(2, 10)") == 1024.0);
    CHECK(eval_number(h, "10 ** 3") == 1000.0);
    CHECK(eval_number(h, "Math.sqrt(2)") == std::sqrt(2.0));  // sqrt is exact in IEEE 754: the C library's is fine
    CHECK(eval_number(h, "Math.sin(0)") == 0.0);
    // Math.random is the world's generator, not a math function (factoria.js).
    CHECK(eval_number(h, "Math.random()") < 1.0);
}
