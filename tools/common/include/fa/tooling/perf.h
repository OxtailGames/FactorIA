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
struct PerfSample {
    int frames = 0;
    double cpuMsAvg = 0, cpuMsP95 = 0, cpuMsMax = 0;  // CPU time of the engine per frame (process CPU, not wall clock)
    double peakMemoryMB = 0;                          // peak resident memory of the process
    int drawCalls = 0;                                // max over the run
    int entities = 0;                                 // max over the run
    // What the renderer drew (max over the run); -1 = not recorded (a baseline file from before these fields: no budget
    // for a field it does not have). A measured sample always has them (0 without a GPU).
    double triangles = -1;                            // triangles of the main pass
    double lights = -1;                               // lights sent to the shader
    double textureMB = -1;                            // GPU texture memory
    // CPU milliseconds from the start of reading the game to its first frame (Engine::init up to the end of frame 1: files read,
    // scenes, scripts, textures, shaders; fa/core/startup.h). -1 = not recorded. Process CPU time, so a busy machine moves it less
    // than the wall clock; still the noisiest number here, so its limits are wide and a budget on it is a "timing" row.
    double startupMs = -1;
    std::string graphics;                             // the GPU used, "none" without one
};
Json perf_sample_json(const PerfSample& s);
PerfSample perf_sample_from_json(const Json& j);  // missing or mistyped fields read as 0

// How far a measurement may go past its baseline. A limit is max(baseline * (1 + ratio), baseline + slack): the slack keeps
// a tiny baseline (0.3 ms, 3 draw calls) from failing on noise.
struct PerfTolerance {
    double cpuAvg = 1.0;      // +100%: CPU time is noisy, even as CPU time (other processes share caches, clocks scale)
    double cpuP95 = 1.5;      // +150%
    double memory = 0.10;     // +10%: peak memory is nearly deterministic
    double drawCalls = 0.10;  // +10%: deterministic for a fixed scene
    double entities = 0.10;
    double triangles = 0.10;  // deterministic for a fixed scene
    double lights = 0.10;
    double textureMB = 0.10;
    double textureSlackMB = 1.0;
    double startup = 2.0;         // +200%: reading files and compiling shaders depends on the disk, its cache and the driver
    double startupSlackMs = 500.0;
    double cpuSlackMs = 1.0;
    double memorySlackMB = 8.0;
    double countSlack = 2.0;
};
// Defaults overridden by the keys of `j` (the "tolerance" object of a budget file); problems (unknown key, bad value) go to `problems`.
PerfTolerance perf_tolerance_from_json(const Json& j, std::vector<std::string>* problems = nullptr);

struct PerfCheckRow {
    std::string metric;  // "cpuMsAvg", "cpuMsP95", "peakMemoryMB", "drawCalls", "entities", "triangles", "lights", "textureMB"; "maxTriangles"... for a budget
    double measured = 0, baseline = 0, limit = 0;
    bool timing = false;  // a time metric (also maxStartupMs): over budget only warns outside CI
    bool exceeded = false;
};
struct PerfVerdict {
    std::string status;  // "pass", "warn" (time over budget outside CI) or "fail"
    std::vector<PerfCheckRow> rows;
};
// `strictTime`: a time over budget fails (CI); otherwise it only warns. Memory, draw calls and entities always fail.
PerfVerdict perf_compare(const PerfSample& measured, const PerfSample& baseline, const PerfTolerance& tol, bool strictTime);

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
