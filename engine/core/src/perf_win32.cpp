// Windows process CPU time and peak memory (see fa/core/perf.h).
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#define PSAPI_VERSION 2  // GetProcessMemoryInfo from kernel32: no psapi.lib to link
#include <windows.h>
#include <psapi.h>
#include <realtimeapiset.h>

#include "fa/core/perf.h"

namespace fa {

namespace {

double filetime_seconds(const FILETIME& ft) {
    return double((std::uint64_t(ft.dwHighDateTime) << 32) | ft.dwLowDateTime) * 1e-7;
}

}  // namespace

double process_cpu_seconds() {
    // GetProcessTimes only advances once per scheduler tick (about 15.6 ms), too coarse for one frame. The cycle counter is
    // precise; its seconds-per-cycle comes from the whole process life (hundreds of ms of CPU by the time a frame runs).
    FILETIME created, exited, kernel, user;
    ULONG64 cycles = 0;
    if (!GetProcessTimes(GetCurrentProcess(), &created, &exited, &kernel, &user)) return 0.0;
    const double coarse = filetime_seconds(kernel) + filetime_seconds(user);
    if (!QueryProcessCycleTime(GetCurrentProcess(), &cycles) || cycles == 0 || coarse < 0.05) return coarse;
    static double secondsPerCycle = 0.0;  // calibrated once: the clock rate does not change during a run enough to matter
    if (secondsPerCycle == 0.0) secondsPerCycle = coarse / double(cycles);
    return double(cycles) * secondsPerCycle;
}

bool cpu_time_is_wall_clock() { return false; }

std::uint64_t peak_memory_bytes() {
    PROCESS_MEMORY_COUNTERS pmc{};
    pmc.cb = sizeof(pmc);
    if (!GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) return 0;
    return std::uint64_t(pmc.PeakWorkingSetSize);
}

}  // namespace fa
