// Process-level performance probes: CPU time and peak memory of this process.
//
// The performance budgets (`factoria call perf.check`, docs/PERFORMANCE.md) measure CPU time instead of wall-clock time
// so a busy machine moves the numbers less, and the peak resident memory of the process. Per platform:
//   Windows        CPU: QueryProcessCycleTime scaled by GetProcessTimes (the tick of GetProcessTimes alone is 15.6 ms);
//                  memory: PeakWorkingSetSize.
//   Linux/Android  CPU: CLOCK_PROCESS_CPUTIME_ID; memory: ru_maxrss (VmHWM).
//   macOS/iOS      CPU: CLOCK_PROCESS_CPUTIME_ID; memory: ru_maxrss (bytes).
//   Web            CPU: not available, the wall clock stands in (cpu_time_is_wall_clock()); memory: the wasm heap size,
//                  which never shrinks, so it is a peak.
#pragma once

#include <cstdint>

namespace fa {

// CPU seconds (user + kernel, every thread) this process has used so far; only differences are meaningful.
double process_cpu_seconds();
// How many times more time than an optimized build a test's speed budget gets in THIS build. MSVC's Debug configuration
// (/Od, checked iterators, debug heap) runs the same code several times slower than an optimized build (script_instrument's
// speed test measured 2.1x its budget on a PC), so a budget written for the others fails there for no reason; 1 everywhere else (including MSVC
// Release, the build CI runs). Tests multiply a budget by it instead of raising the number for every build.
constexpr double test_speed_budget_scale() {
#if defined(_MSC_VER) && defined(_DEBUG)
    return 4.0;
#else
    return 1.0;
#endif
}
// True where process_cpu_seconds() is really the wall clock (web): the budgets still work, but a busy machine moves them.
bool cpu_time_is_wall_clock();
// Peak resident memory of the process in bytes; 0 when the platform cannot say.
std::uint64_t peak_memory_bytes();
// Resident memory of the process right now in bytes (the profiler's memory curve); 0 when the platform cannot say.
// Windows: WorkingSetSize; Linux/Android: /proc/self/statm; macOS/iOS: mach task_info; web: the wasm heap size.
std::uint64_t current_memory_bytes();
// Physical memory of the machine in bytes (what game.device.memoryGB and the quality tier read); 0 when the platform cannot say.
std::uint64_t total_memory_bytes();

}  // namespace fa
