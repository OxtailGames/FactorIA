// The bake's helper process (docs/design/ARCHITECTURE_BAKING.md, "The GPU bake", "A helper process"): a `factoria session --no-graphics` child that runs
// a Plan with the GPU tracer when this process already has a graphics context and so cannot open one itself. Private to fa_authoring and its tests.
#pragma once

#include "lightmap_bake_job.h"

namespace fa::lightmap_job {

struct HelperOutcome {
    // Done: `result` is the bake's result (the files are written). Cancelled: the helper was stopped by the cancel flag. Failed: the bake itself
    // failed in the helper and `error` is its own error (a scene it refuses, a GPU it cannot use, "device \"gpu\": ..."). Unavailable: no helper
    // could be started (no factoria next to this program, no project folder, it did not become ready). Crashed: the helper died or went silent
    // while it ran (a driver crash, a GPU reset): this process is untouched.
    enum class Kind { Done, Cancelled, Failed, Unavailable, Crashed } kind = Kind::Unavailable;
    Json result;
    Error error{"", ""};
};

// True when `plan` should bake in a helper: a device other than "cpu", at least one mesh that gets lightmap texels, and either the policy
// says Always or (Auto) the GPU tracer cannot open in this process but could in a process without graphics.
bool helper_wanted(const Plan& plan);

// What set_helper_use last set (Auto at start).
HelperUse helper_use();

// Runs `plan` in a helper (see HelperOutcome). Checks the cancel flag of this thread (CommandCancelScope) every 50 ms and asks the helper to stop;
// a helper that does not answer for 2 minutes after a cancel is killed. Whatever happens the helper ends before this returns.
HelperOutcome run_in_helper(const Plan& plan, const ReportFn& report);

// Seconds without any change of progress after which a helper is taken for hung and killed (a safety net far above any phase of a real bake).
inline constexpr double kHelperStallSeconds = 900;

}  // namespace fa::lightmap_job
