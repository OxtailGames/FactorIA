// Performance budgets (docs/PERFORMANCE.md): measure a project headless, keep a baseline per runner, fail past a tolerance.
//
// Commands: perf.measure, perf.check, perf.baseline (perf.cpp). The pure parts (runner id, tolerances, the comparison) are
// declared here so the tests can drive them without running a game.
#pragma once

#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa {

// What one measured run costs: the `perf` object of the `factoria run --headless --json` report.
struct PerfFrame {
    int frame = 0;
    double ms = 0;
};
struct PerfSample {
    int frames = 0;
    double cpuMsAvg = 0, cpuMsP95 = 0, cpuMsMax = 0;  // CPU time of the engine per frame (process CPU, not wall clock)
    // The median frame. -1 = not recorded (a baseline from before it: the average stands in for it, which is never lower, so the
    // comparison only gets more lenient). Time is gated on the median and the p95; the average and the maximum are only reported,
    // because one slow frame decides them.
    double cpuMsMedian = -1;
    // The slowest frames of the run, slowest first (at most kPerfSlowestFrames): so a spike is seen, not hidden in a number.
    std::vector<PerfFrame> slowestFrames;
    // A baseline entry only: "provisional": true. Only the counters (draw calls, entities, triangles, lights) are enforced, never
    // time or memory: the entry is an estimate until a CI run of that runner replaces it (perf.baseline).
    bool provisional = false;
    double peakMemoryMB = 0;  // peak resident memory of the process
    int drawCalls = 0;        // max over the run
    int entities = 0;         // max over the run
    // What the renderer drew (max over the run); -1 = not recorded (a baseline file from before these fields: no budget
    // for a field it does not have). A measured sample always has them (0 without a GPU).
    double triangles = -1;  // triangles of the main pass
    double lights = -1;     // lights sent to the shader
    double textureMB = -1;  // GPU texture memory
    // Reported, never gated and never written to a baseline: the decoded audio (clips, streaming buffers, music) and the music
    // alone, max over the run. -1 = not recorded.
    double audioDecodedMB = -1;
    double musicMB = -1;
    // CPU milliseconds from the start of reading the game to its first frame (Engine::init up to the end of frame 1: files read,
    // scenes, scripts, textures, shaders; fa/core/startup.h). -1 = not recorded. Process CPU time, so a busy machine moves it less
    // than the wall clock; still the noisiest number here, so its limits are wide and a budget on it is a "timing" row.
    double startupMs = -1;
    std::string graphics;  // the GPU used, "none" without one
};
constexpr int kPerfSlowestFrames = 5;
// `withSlowest` false leaves the slowest frames out: a baseline entry is the same on every run, a measurement is not.
Json perf_sample_json(const PerfSample& s, bool withSlowest = true);
PerfSample perf_sample_from_json(const Json& j);  // missing or mistyped fields read as 0

// How far a measurement may go past its baseline. There are two kinds of metric.
//  - COUNTERS (draw calls, entities, triangles, lights): the same on every run of a fixed scene, so the limit is the baseline
//    itself (ratio 0, slack 0) and one more fails. Fewer is fine. texture memory is nearly one: it keeps a small band.
//  - NOISE (the median and p95 frame time, peak memory): a shared CI runner moves them by several times. A row has two limits.
//    Past `warnLimit` = max(baseline * (1 + ratio), baseline + slack) it warns; only past `limit` =
//    max(baseline * (1 + failRatio), baseline + failSlack) does it fail (a time only when strictTime). The wide band, not the
//    re-measures, is what absorbs the noise, so a baseline is never refreshed to make a check pass. The absolute slack matters
//    under a millisecond, where a ratio alone is noise (0.46 ms measured as 1.75 ms is 3.8x and not a regression).
struct PerfTolerance {
    double cpuMedian = 1.0;  // warn at +100% (and cpuSlackMs)
    double cpuP95 = 1.5;     // warn at +150%
    double cpuFail = 5.0;    // fail at +500% (6x the baseline) or cpuFailSlackMs, the larger
    double cpuFailSlackMs = 10.0;
    double memory = 0.10;     // warn at +10% (and memorySlackMB)
    double memoryFail = 0.5;  // fail at +50% or memoryFailSlackMB, the larger
    double memoryFailSlackMB = 32.0;
    double drawCalls = 0.0;  // exact: one more fails
    double entities = 0.0;
    double triangles = 0.0;
    double lights = 0.0;
    double textureMB = 0.10;
    double textureSlackMB = 1.0;
    double startup = 2.0;  // +200%: reading files and compiling shaders depends on the disk, its cache and the driver
    double startupSlackMs = 500.0;
    double cpuSlackMs = 1.0;
    double memorySlackMB = 8.0;
    double countSlack = 0.0;
};
// Defaults overridden by the keys of `j` (the "tolerance" object of a budget file); problems (unknown key, bad value) go to `problems`.
PerfTolerance perf_tolerance_from_json(const Json& j, std::vector<std::string>* problems = nullptr);

struct PerfCheckRow {
    std::string
        metric;  // "cpuMsMedian", "cpuMsP95", "peakMemoryMB", "drawCalls", "entities", "triangles", "lights", "textureMB", "startupMs"; "maxTriangles"... for a budget
    double measured = 0, baseline = 0;
    double limit = 0;       // past it the row FAILS (a time: only when strictTime)
    double warnLimit = 0;   // past it, up to `limit`, the row warns; equal to `limit` for a counter or an absolute cap
    bool timing = false;    // a time metric (also maxStartupMs): over budget only warns outside CI
    bool exceeded = false;  // measured > limit
    bool warned = false;    // warnLimit < measured <= limit
};
struct PerfVerdict {
    std::string status;  // "pass", "warn" (inside a band, or a time over budget outside CI) or "fail"
    std::vector<PerfCheckRow> rows;
};
// `strictTime`: a time past its limit fails (CI); otherwise it only warns. Memory and the counters past theirs always fail.
// A provisional baseline (PerfSample::provisional) compares the counters only: no time, memory, texture or start-up row.
PerfVerdict perf_compare(const PerfSample& measured, const PerfSample& baseline, const PerfTolerance& tol,
                         bool strictTime);

// Absolute caps, whatever the runner: the "budgets" object of a budget file or the `budgets` argument of perf.check.
// {maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities, maxStartupMs}; a key left out is not checked. A unknown key or a
// bad value goes to `problems` with a "did you mean".
struct PerfBudgets {
    double maxTriangles = -1, maxLights = -1, maxTextureMB = -1, maxDrawCalls = -1, maxEntities = -1;  // -1 = no cap
    // The `perf.startup` budget: the most CPU milliseconds the game may take from reading its files to its first frame
    // (PerfSample::startupMs). A time: over it only warns outside CI, and fails in CI after two re-measures.
    double maxStartupMs = -1;
};
PerfBudgets perf_budgets_from_json(const Json& j, std::vector<std::string>* problems = nullptr);
// One row per cap that is set (baseline = limit = the cap); `exceeded` when the measurement is over it.
// maxStartupMs is a timing row; it is skipped when the sample has no startupMs.
std::vector<PerfCheckRow> perf_budget_rows(const PerfSample& measured, const PerfBudgets& budgets);
// The sentence that teaches how to bring a game's start-up time down (docs/AI_GUIDE.md, "Keep startup low"), for a perf.check
// message when a startup row is over its limit.
std::string perf_startup_advice();

// "<os>-<compiler>-<renderer>[-debug]", e.g. linux-gcc-llvmpipe, windows-msvc-d3d11-warp, macos-clang-metal-paravirtual
// (GitHub's macOS VMs; a Mac's own GPU is macos-clang-metal). A Debug build (no NDEBUG) adds "-debug": it costs more memory
// and time, so it never shares a baseline with a release build. FACTORIA_PERF_RUNNER overrides it (a machine of your own,
// or the test of the check itself). `graphics` is PerfSample::graphics.
std::string perf_runner_id(const std::string& graphics);
void register_perf_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
