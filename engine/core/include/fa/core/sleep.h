// A sleep that ends close to when it was asked to: frame caps and frame pacing (docs/LATENCY.md).
#pragma once

#include <chrono>

namespace fa {

// Sleeps about `d` on the calling thread. A plain sleep overshoots by a whole timer tick on Windows (15 ms by default),
// which would turn a 144 fps cap into 64 fps, so Windows waits on a high-resolution waitable timer (Windows 10 1803 and
// later; one per thread), and falls back to std::this_thread::sleep_for where there is none. It may still end a little
// late on a loaded machine: a caller that must not start late sleeps a millisecond short and spins the rest.
void sleep_precise(std::chrono::nanoseconds d);

}  // namespace fa
