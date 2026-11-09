#include <doctest.h>

#include <chrono>
#include <vector>

#include "fa/core/perf.h"

using namespace fa;

TEST_CASE("perf probes: CPU time advances with work, peak memory grows with allocation") {
    const std::uint64_t before = peak_memory_bytes();
    CHECK(before > 0);
    const double t0 = process_cpu_seconds();
    std::vector<char> big(48 * 1024 * 1024, 1);  // touched, so it is resident
    volatile double sink = 0;
    for (int i = 0; i < 20000000; ++i) sink = sink + double(i) * 0.5 + double(big[std::size_t(i) % big.size()]);
    const double t1 = process_cpu_seconds();
    CHECK(t1 > t0);
    CHECK(t1 - t0 < 60.0);
    CHECK(peak_memory_bytes() >= before);
    // Under memory pressure macOS compresses the untouched-since pages of `big` and the resident peak stays below its
    // 48 MB (38.9 MB seen while other builds ran), so only half of it must show up.
    CHECK(peak_memory_bytes() >= std::uint64_t(24) * 1024 * 1024);
}

TEST_CASE("perf probes: one busy thread never uses more CPU time than the wall clock that passed") {
    // The Windows clock once read 4x the real CPU time on a CI VM (its rate came from GetProcessTimes' 15.6 ms ticks).
    // One busy thread cannot use more CPU than the time that passes; the margin covers the other threads of this test
    // binary (idle job workers) and the clocks' own steps.
    const auto wall0 = std::chrono::steady_clock::now();
    const double cpu0 = process_cpu_seconds();
    volatile double sink = 0;
    while (std::chrono::steady_clock::now() - wall0 < std::chrono::milliseconds(300))
        for (int i = 0; i < 10000; ++i) sink = sink + double(i) * 0.5;
    const double cpu = process_cpu_seconds() - cpu0;
    const double wall = std::chrono::duration<double>(std::chrono::steady_clock::now() - wall0).count();
    CHECK(cpu > 0.0);
    CHECK(cpu <= wall * 1.25 + 0.02);
    double last = process_cpu_seconds();
    for (int i = 0; i < 1000; ++i) {  // never goes back
        const double now = process_cpu_seconds();
        CHECK(now >= last);
        last = now;
    }
}
