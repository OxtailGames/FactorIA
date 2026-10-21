// Linux, macOS, iOS, Android and web process CPU time and peak memory (see fa/core/perf.h). One file for the POSIX
// family (the build selects *_posix.cpp on every non-Windows platform, web included, so the web branch lives here).
#include "fa/core/perf.h"

#include <chrono>
#include <cstdio>
#include <ctime>

#ifdef __EMSCRIPTEN__
#include <emscripten/heap.h>
#else
#include <sys/resource.h>
#include <unistd.h>
#ifdef __APPLE__
#include <mach/mach.h>
#endif
#endif

namespace fa {

double process_cpu_seconds() {
#ifdef __EMSCRIPTEN__
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
#else
    timespec ts{};
    if (clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts) != 0) return 0.0;
    return double(ts.tv_sec) + double(ts.tv_nsec) * 1e-9;
#endif
}

bool cpu_time_is_wall_clock() {
#ifdef __EMSCRIPTEN__
    return true;
#else
    return false;
#endif
}

std::uint64_t peak_memory_bytes() {
#ifdef __EMSCRIPTEN__
    return std::uint64_t(emscripten_get_heap_size());  // the heap only grows
#else
    rusage ru{};
    if (getrusage(RUSAGE_SELF, &ru) != 0) return 0;
#ifdef __APPLE__
    return std::uint64_t(ru.ru_maxrss);  // bytes
#else
    return std::uint64_t(ru.ru_maxrss) * 1024;  // kilobytes
#endif
#endif
}

std::uint64_t current_memory_bytes() {
#ifdef __EMSCRIPTEN__
    return std::uint64_t(emscripten_get_heap_size());
#elif defined(__APPLE__)
    mach_task_basic_info info{};
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
    if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, reinterpret_cast<task_info_t>(&info), &count) != KERN_SUCCESS) return 0;
    return std::uint64_t(info.resident_size);
#else
    std::FILE* f = std::fopen("/proc/self/statm", "r");  // pages: size resident shared ...
    if (!f) return 0;
    unsigned long long size = 0, resident = 0;
    const int n = std::fscanf(f, "%llu %llu", &size, &resident);
    std::fclose(f);
    return n == 2 ? std::uint64_t(resident) * std::uint64_t(sysconf(_SC_PAGESIZE)) : 0;
#endif
}

}  // namespace fa
