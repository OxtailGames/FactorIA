#include "fa/core/sleep.h"

#include <thread>

#if defined(_WIN32)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#endif

namespace fa {

#if defined(_WIN32)
namespace {
// One timer per thread: two threads setting the same timer would cut each other's waits short.
struct ThreadTimer {
    HANDLE handle = CreateWaitableTimerExW(nullptr, nullptr, 0x00000002 /* CREATE_WAITABLE_TIMER_HIGH_RESOLUTION */,
                                           TIMER_ALL_ACCESS);
    ThreadTimer() = default;
    ThreadTimer(const ThreadTimer&) = delete;
    ThreadTimer& operator=(const ThreadTimer&) = delete;
    ~ThreadTimer() {
        if (handle) CloseHandle(handle);
    }
};
}  // namespace
#endif

void sleep_precise(std::chrono::nanoseconds d) {
    if (d.count() <= 0) return;
#if defined(_WIN32)
    thread_local ThreadTimer timer;
    if (timer.handle) {
        LARGE_INTEGER due;
        due.QuadPart = -(d.count() / 100);  // 100 ns units, negative = relative
        if (due.QuadPart == 0) due.QuadPart = -1;
        if (SetWaitableTimer(timer.handle, &due, 0, nullptr, nullptr, FALSE)) {
            WaitForSingleObject(timer.handle, INFINITE);
            return;
        }
    }
#endif
    std::this_thread::sleep_for(d);
}

}  // namespace fa
