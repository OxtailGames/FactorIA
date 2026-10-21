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
// True where process_cpu_seconds() is really the wall clock (web): the budgets still work, but a busy machine moves them.
bool cpu_time_is_wall_clock();
// Peak resident memory of the process in bytes; 0 when the platform cannot say.
std::uint64_t peak_memory_bytes();
// Resident memory of the process right now in bytes (the profiler's memory curve); 0 when the platform cannot say.
// Windows: WorkingSetSize; Linux/Android: /proc/self/statm; macOS/iOS: mach task_info; web: the wasm heap size.
std::uint64_t current_memory_bytes();

}  // namespace fa
