// Windows process CPU time and peak memory (see fa/core/perf.h).
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#define PSAPI_VERSION 2  // GetProcessMemoryInfo from kernel32: no psapi.lib to link
#include <windows.h>
#include <psapi.h>
#include <realtimeapiset.h>
#if defined(_M_X64) || defined(_M_IX86) || defined(__x86_64__) || defined(__i386__)
#include <intrin.h>  // __rdtsc (MSVC and MinGW-w64)
#define FA_PERF_TSC 1
#endif

#include "fa/core/perf.h"

namespace fa {

namespace {

double filetime_seconds(const FILETIME& ft) {
    return double((std::uint64_t(ft.dwHighDateTime) << 32) | ft.dwLowDateTime) * 1e-7;
}

#ifdef FA_PERF_TSC
// One reading of the performance counter and the time-stamp counter taken together: the TSC is read on both sides of
// the QPC read and averaged, so a preemption between the two reads moves the pair by half of it at most.
struct ClockPair {
    LONGLONG qpc = 0;
    double tsc = 0.0;
};

ClockPair read_clock_pair() {
    LARGE_INTEGER q;
    const unsigned long long a = __rdtsc();
    QueryPerformanceCounter(&q);
    const unsigned long long b = __rdtsc();
    return {q.QuadPart, (double(a) + double(b)) * 0.5};
}

// Taken during static initialization, long before the first frame. Read before it (from another file's static
// initializer), it is still zero, and both clocks then count from boot, which gives the same rate.
const ClockPair g_processStart = read_clock_pair();

// Seconds per time-stamp-counter tick: QueryProcessCycleTime counts TSC ticks (the kernel reads the TSC at each
// context switch), so this turns cycles into CPU seconds. Measured against QueryPerformanceCounter (100 ns ticks) over
// at least 5 ms, which puts it within about 1e-4.
double seconds_per_tsc_tick() {
    static const double value = [] {
        LARGE_INTEGER freq;
        QueryPerformanceFrequency(&freq);
        for (;;) {
            const ClockPair now = read_clock_pair();
            const double wall = double(now.qpc - g_processStart.qpc) / double(freq.QuadPart);
            const double ticks = now.tsc - g_processStart.tsc;
            if (wall >= 0.005 && ticks > 0.0) return wall / ticks;
            Sleep(1);  // only when the first call comes within 5 ms of the start of the process
        }
    }();
    return value;
}
#endif

}  // namespace

double process_cpu_seconds() {
    // GetProcessTimes only advances once per scheduler tick (about 15.6 ms), too coarse for one frame, and it charges a
    // whole tick to the thread that happens to run when the tick fires. The cycle counter is precise.
    ULONG64 cycles = 0;
#ifdef FA_PERF_TSC
    // Its rate is the TSC's. Calibrating it from GetProcessTimes instead read 4x too much CPU on the CI's Windows VM: the
    // first call (StartupTimeline, a few tens of ms into the process) saw a tick-sampled time several times the real one.
    if (QueryProcessCycleTime(GetCurrentProcess(), &cycles) && cycles != 0) return double(cycles) * seconds_per_tsc_tick();
#endif
    FILETIME created, exited, kernel, user;
    if (!GetProcessTimes(GetCurrentProcess(), &created, &exited, &kernel, &user)) return 0.0;
    const double coarse = filetime_seconds(kernel) + filetime_seconds(user);
#ifndef FA_PERF_TSC
    // ARM64: the cycle counter has no rate Windows names; its seconds-per-cycle comes from the process's own life, once
    // it has used enough CPU for the tick-sampled time to mean something.
    if (!QueryProcessCycleTime(GetCurrentProcess(), &cycles) || cycles == 0 || coarse < 0.05) return coarse;
    static double secondsPerCycle = 0.0;  // calibrated once: the clock rate does not change during a run enough to matter
    if (secondsPerCycle == 0.0) secondsPerCycle = coarse / double(cycles);
    return double(cycles) * secondsPerCycle;
#else
    return coarse;
#endif
}

bool cpu_time_is_wall_clock() { return false; }

std::uint64_t peak_memory_bytes() {
    PROCESS_MEMORY_COUNTERS pmc{};
    pmc.cb = sizeof(pmc);
    if (!GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) return 0;
    return std::uint64_t(pmc.PeakWorkingSetSize);
}

std::uint64_t current_memory_bytes() {
    PROCESS_MEMORY_COUNTERS pmc{};
    pmc.cb = sizeof(pmc);
    if (!GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) return 0;
    return std::uint64_t(pmc.WorkingSetSize);
}

std::uint64_t total_memory_bytes() {
    MEMORYSTATUSEX ms{};
    ms.dwLength = sizeof(ms);
    return GlobalMemoryStatusEx(&ms) ? std::uint64_t(ms.ullTotalPhys) : 0;
}

}  // namespace fa
