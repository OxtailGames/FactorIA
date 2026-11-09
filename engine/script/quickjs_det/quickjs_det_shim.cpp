// M91.3: the functions quickjs_det_math.h routes QuickJS's Math.* and ** to. Compiled into fa_ext_quickjs (not into fa_script):
// QuickJS is a C library, and this file is the only C++ it needs. Each function is the fa::det::f64 one of the same name, so a
// script's Math.sin(x) has the same bits on x86-64, arm64 and WebAssembly.
#include "fa/core/det_math.h"

#include "quickjs_det_math.h"

// This file must NOT see the macros of quickjs_det_math.h (they would rename fa::det::f64::sin): they are only for C.
#undef sin
#undef cos
#undef tan
#undef asin
#undef acos
#undef atan
#undef atan2
#undef exp
#undef expm1
#undef log
#undef log2
#undef log10
#undef log1p
#undef pow
#undef sinh
#undef cosh
#undef tanh
#undef asinh
#undef acosh
#undef atanh
#undef cbrt
#undef hypot

namespace dm = fa::det::f64;

extern "C" {
double fa_det_sin(double x) { return dm::sin(x); }
double fa_det_cos(double x) { return dm::cos(x); }
double fa_det_tan(double x) { return dm::tan(x); }
double fa_det_asin(double x) { return dm::asin(x); }
double fa_det_acos(double x) { return dm::acos(x); }
double fa_det_atan(double x) { return dm::atan(x); }
double fa_det_atan2(double y, double x) { return dm::atan2(y, x); }
double fa_det_exp(double x) { return dm::exp(x); }
double fa_det_expm1(double x) { return dm::expm1(x); }
double fa_det_log(double x) { return dm::log(x); }
double fa_det_log2(double x) { return dm::log2(x); }
double fa_det_log10(double x) { return dm::log10(x); }
double fa_det_log1p(double x) { return dm::log1p(x); }
double fa_det_pow(double x, double y) { return dm::pow(x, y); }
double fa_det_sinh(double x) { return dm::sinh(x); }
double fa_det_cosh(double x) { return dm::cosh(x); }
double fa_det_tanh(double x) { return dm::tanh(x); }
double fa_det_asinh(double x) { return dm::asinh(x); }
double fa_det_acosh(double x) { return dm::acosh(x); }
double fa_det_atanh(double x) { return dm::atanh(x); }
double fa_det_cbrt(double x) { return dm::cbrt(x); }
double fa_det_hypot(double x, double y) { return dm::hypot(x, y); }
}
