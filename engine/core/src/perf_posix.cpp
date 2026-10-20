// Linux, macOS, iOS, Android and web process CPU time and peak memory (see fa/core/perf.h). One file for the POSIX
// family (the build selects *_posix.cpp on every non-Windows platform, web included, so the web branch lives here).
#include "fa/core/perf.h"

#include <chrono>
#include <ctime>

#ifdef __EMSCRIPTEN__
#include <emscripten/heap.h>
#else
#include <sys/resource.h>
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

}  // namespace fa
