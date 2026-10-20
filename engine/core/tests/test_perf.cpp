#include <doctest.h>

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
    CHECK(peak_memory_bytes() >= std::uint64_t(40) * 1024 * 1024);
}
