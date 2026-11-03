// FactorIA's translation unit of xatlas (not part of upstream): builds the unmodified xatlas.cpp with the four transcendental
// functions it calls (sinf, cosf, acosf, atan2f) replaced by fa::det's, which give the same bits on every platform (the C
// libraries round them differently). The rest of xatlas is + - * / and sqrtf on floats, so with the engine's flags (no FP
// contraction, no fast-math) a model unwraps to the same UVs on every compiler and CPU. Single-threaded (XA_MULTITHREADED=0,
// set by external/CMakeLists.txt), no profiling, no debug checks.
#include <cmath>
#include <math.h>

#include "fa/core/det_math.h"

namespace {
inline float fa_sinf(float x) { return fa::det::sin(x); }
inline float fa_cosf(float x) { return fa::det::cos(x); }
inline float fa_acosf(float x) { return fa::det::acos(x); }
inline float fa_atan2f(float y, float x) { return fa::det::atan2(y, x); }
}  // namespace

#define sinf fa_sinf
#define cosf fa_cosf
#define acosf fa_acosf
#define atan2f fa_atan2f

#include "xatlas.cpp"
