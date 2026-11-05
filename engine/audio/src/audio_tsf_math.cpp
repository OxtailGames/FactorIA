// The math TinySoundFont calls (audio_tsf.c), written with the synth's own functions (sfx_math.h) instead of the C library's, whose last
// bit differs between platforms. Accuracy is about 1e-12, far below what a float sample can show.
#include <cmath>

#include "sfx_math.h"

extern "C" {

double fa_tsf_pow(double a, double b) { return fa::sfx_math::pow(a, b); }
float fa_tsf_powf(float a, float b) { return float(fa::sfx_math::pow(double(a), double(b))); }
float fa_tsf_expf(float x) { return float(fa::sfx_math::exp2(double(x) * fa::sfx_math::kLog2E)); }
double fa_tsf_log(double x) { return fa::sfx_math::log2(x) * 0.6931471805599453; }
double fa_tsf_log10(double x) { return fa::sfx_math::log2(x) * fa::sfx_math::kLog10Of2; }
// tan(x) for the filter's prewarped cutoff, x in (0, pi/2): tan_pi takes x / pi.
double fa_tsf_tan(double x) {
    double f = x * 0.3183098861837907;
    if (f < 1e-9) f = 1e-9;
    if (f > 0.4999) f = 0.4999;
    return fa::sfx_math::tan_pi(f);
}
float fa_tsf_sqrtf(float x) { return std::sqrt(x); }

}  // extern "C"
