/* M91.3: deterministic Math for the game scripts.
 *
 * QuickJS calls the C library for Math.sin, cos, tan, asin, acos, atan, atan2, exp, log, log2, log10, log1p, expm1, pow
 * (and so the ** operator), sinh, cosh, tanh, asinh, acosh, atanh, cbrt and hypot. glibc, Apple's libm, the MSVC CRT and
 * musl (WebAssembly) each round them differently, so a script that uses Math.pow or Math.sin could not give the same replay
 * on two machines. This header is FORCE-INCLUDED into every source of fa_ext_quickjs (engine/script/CMakeLists.txt: -include
 * / /FI), after the system's <math.h>, and in the four QuickJS C files turns those calls into calls of fa_det_* in
 * quickjs_det_shim.cpp, which forwards to fa::det::f64 (engine/core/include/fa/core/det_math.h): the same bits on every
 * platform. The macros are defined for C only: the shim is C++ and must keep fa::det::f64::sin and friends as they are.
 *
 * Why a macro and not an edit of external/quickjs: external/ stays as released, and a link-time override of `sin` would
 * change the whole program (Box2D, the renderer...). sqrt, floor, ceil, trunc, fmod, fabs, scalbn and frexp are exact in
 * IEEE 754 and stay the C library's.
 *
 * <math.h> is included FIRST so that the system header never sees the macros below.
 */
#ifndef FA_QUICKJS_DET_MATH_H
#define FA_QUICKJS_DET_MATH_H

#include <math.h>

#ifdef __cplusplus
extern "C" {
#endif
double fa_det_sin(double x);
double fa_det_cos(double x);
double fa_det_tan(double x);
double fa_det_asin(double x);
double fa_det_acos(double x);
double fa_det_atan(double x);
double fa_det_atan2(double y, double x);
double fa_det_exp(double x);
double fa_det_expm1(double x);
double fa_det_log(double x);
double fa_det_log2(double x);
double fa_det_log10(double x);
double fa_det_log1p(double x);
double fa_det_pow(double x, double y);
double fa_det_sinh(double x);
double fa_det_cosh(double x);
double fa_det_tanh(double x);
double fa_det_asinh(double x);
double fa_det_acosh(double x);
double fa_det_atanh(double x);
double fa_det_cbrt(double x);
double fa_det_hypot(double x, double y);
#ifdef __cplusplus
}
#endif

/* C only. The force-include covers the whole target, shim included, because the Visual Studio and Xcode generators evaluate
 * $<COMPILE_LANGUAGE:C> as CXX for every file of a target that has a C++ source, so a C-only option never reached the C files
 * there (M91 CI: Windows ran Math.sin on the CRT). */
#ifndef __cplusplus
#define sin(x) fa_det_sin(x)
#define cos(x) fa_det_cos(x)
#define tan(x) fa_det_tan(x)
#define asin(x) fa_det_asin(x)
#define acos(x) fa_det_acos(x)
#define atan(x) fa_det_atan(x)
#define atan2(y, x) fa_det_atan2(y, x)
#define exp(x) fa_det_exp(x)
#define expm1(x) fa_det_expm1(x)
#define log(x) fa_det_log(x)
#define log2(x) fa_det_log2(x)
#define log10(x) fa_det_log10(x)
#define log1p(x) fa_det_log1p(x)
#define pow(x, y) fa_det_pow(x, y)
#define sinh(x) fa_det_sinh(x)
#define cosh(x) fa_det_cosh(x)
#define tanh(x) fa_det_tanh(x)
#define asinh(x) fa_det_asinh(x)
#define acosh(x) fa_det_acosh(x)
#define atanh(x) fa_det_atanh(x)
#define cbrt(x) fa_det_cbrt(x)
#define hypot(x, y) fa_det_hypot(x, y)
#endif /* !__cplusplus */

#endif /* FA_QUICKJS_DET_MATH_H */
