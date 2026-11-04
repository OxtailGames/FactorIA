/* TinySoundFont implementation (single C translation unit): the SoundFont (.sf2) synthesizer behind fa/audio/soundfont.h.
 *
 * Its libm calls (pow, exp, log, tan, log10) are redirected to the shims of audio_tsf_math.cpp, which use the synth's own
 * correctly-rounded-arithmetic versions, so a SoundFont renders the same samples on every platform like the rest of the audio code. */
#include <stdlib.h>
#include <string.h>

#define TSF_NO_STDIO
double fa_tsf_pow(double a, double b);
float fa_tsf_powf(float a, float b);
float fa_tsf_expf(float x);
double fa_tsf_log(double x);
double fa_tsf_tan(double x);
double fa_tsf_log10(double x);
float fa_tsf_sqrtf(float x);
#define TSF_POW fa_tsf_pow
#define TSF_POWF fa_tsf_powf
#define TSF_EXPF fa_tsf_expf
#define TSF_LOG fa_tsf_log
#define TSF_TAN fa_tsf_tan
#define TSF_LOG10 fa_tsf_log10
#define TSF_SQRT fa_tsf_sqrtf
#define TSF_SQRTF fa_tsf_sqrtf
#define TSF_IMPLEMENTATION
#include "tsf.h"
