// The private side of sfx macros and variations (sfx_macros.cpp): the transforms render_sfx applies to a copy of a patch.
#pragma once

#include "fa/audio/sfx.h"

namespace fa::sfx_detail {

// The built-in macro values a render uses: the patch's declared values replaced by the options'.
struct MacroValues {
    double attack = 0, brightness = 0, weight = 0, tail = 0, pitch = 0, grit = 0;
    double strength[6] = {1, 1, 1, 1, 1, 1};
    bool any() const { return attack != 0 || brightness != 0 || weight != 0 || tail != 0 || pitch != 0 || grit != 0; }
};
MacroValues effective_macros(const SfxPatch& patch, const std::map<std::string, double>& overrides);

// The parts of a macro that are not parameters of the patch: a gentle EQ and an exciter on the final mix.
struct Tilt {
    double brightness = 0, weight = 0;
    bool any() const { return brightness != 0 || weight != 0; }
};

// Changes `patch` (a copy) for the macros; `transpose` is multiplied by the pitch change and `tilt` receives the EQ.
void apply_macros(SfxPatch& patch, const MacroValues& macros, double& transpose, Tilt& tilt);
// Changes `patch` (a copy) for a variant: layer lengths and filter cutoffs; the pitch, seed and gain are the caller's.
void apply_variant(SfxPatch& patch, const SfxVariantParams& variant);
// The tilt EQ on the final mix (double samples at `rate`).
void apply_tilt(std::vector<double>& mix, const Tilt& tilt, int rate);

}  // namespace fa::sfx_detail
