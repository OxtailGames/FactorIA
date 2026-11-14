// Job system benchmarks (fa/core/jobs.h): the cost of submitting, scheduling and waiting for jobs, which a change of the
// queues (one global queue, per-worker queues with stealing) moves. Each job does a few arithmetic operations on its own
// slot, so the numbers are the scheduler's, not the work's.
//
// They run with the job settings of `fa_bench --jobs`: the baselines are made with `inline` (every job runs at once on the
// submitting thread: it measures the bookkeeping of a job without any thread), and `--jobs 4` or `--jobs auto` measures the
// pool. A baseline is only compared with a run of the same `--jobs`. Every run returns a checksum of the results, summed in
// a fixed order, so it is the same whatever the threads.
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "benches.h"
#include "fa/core/jobs.h"

namespace fa::bench {

namespace {

// A little deterministic work: `steps` xorshift steps from `seed` (not an LCG: the optimizer folds a loop of those into one multiply).
inline std::uint64_t tiny_work(std::uint64_t seed, int steps) {
    std::uint64_t x = seed * 0x9E3779B97F4A7C15ull + 1;
    for (int i = 0; i < steps; ++i) {
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
    }
    return x >> 33;
}

double sum_of(const std::vector<std::uint64_t>& v) {
    std::uint64_t s = 0;
    for (std::uint64_t x : v) s += x;
    return double(s % 1000003ull);
}

// Wider bands than the single-threaded benchmarks, in every mode (the inline baselines too: a run is only compared with
// a baseline made with the same `--jobs`, but the ratios are the benchmark's, not the mode's). With `--jobs` > 0 the
// numbers depend on how busy the machine is; and an inline run is short: each one does enough jobs to take a few
// milliseconds on a CI runner (the slack of 0.2 and 0.5 ms of the comparison covers only runs under a millisecond), so a
// slow second on a shared VM is a fraction of it, not a multiple.
void threaded(Bench& b) {
    b.warnRatio = 1.8;
    b.failRatio = 3.0;
}

Bench tiny_jobs() {
    Bench b;
    b.name = "jobs.tiny";
    b.summary = "40000 tiny jobs submitted one after the other from one thread, then waited for together (wait_all)";
    threaded(b);
    b.make = [] {
        constexpr int kJobs = 40000;
        auto out = std::make_shared<std::vector<std::uint64_t>>(kJobs, 0);
        Prepared p;
        p.items = kJobs;
        p.unit = "jobs";
        p.run = [out] {
            std::vector<jobs::Handle> hs;
            hs.reserve(kJobs);
            std::vector<std::uint64_t>& v = *out;
            for (int i = 0; i < kJobs; ++i)
                hs.push_back(
                    jobs::submit("bench.tiny", [&v, i] { v[std::size_t(i)] = tiny_work(std::uint64_t(i), 8); }));
            (void)jobs::wait_all(hs);
            return sum_of(v);
        };
        return p;
    };
    return b;
}

Bench parallel_for_small() {
    Bench b;
    b.name = "jobs.for_small_grain";
    b.summary = "100 parallel_for calls over 20000 items each, grain 16 (1250 chunks per call)";
    threaded(b);
    b.make = [] {
        constexpr int kCalls = 100;
        constexpr std::size_t kItems = 20000, kGrain = 16;
        auto out = std::make_shared<std::vector<std::uint64_t>>(kItems, 0);
        Prepared p;
        p.items = std::int64_t(kCalls) * std::int64_t(kItems / kGrain);
        p.unit = "chunks";
        p.run = [out] {
            std::vector<std::uint64_t>& v = *out;
            double sum = 0;
            for (int call = 0; call < kCalls; ++call) {
                (void)jobs::parallel_for("bench.for_small", kItems, kGrain, [&v, call](const jobs::Chunk& c) {
                    for (std::size_t i = c.begin; i < c.end; ++i) v[i] = tiny_work(i + std::size_t(call), 4);
                });
                sum += sum_of(v);
            }
            return sum;
        };
        return p;
    };
    return b;
}

Bench parallel_for_large() {
    Bench b;
    b.name = "jobs.for_large_grain";
    b.summary = "10 parallel_for calls over 160000 items each, grain 5000 (32 chunks of real work per call)";
    threaded(b);
    b.make = [] {
        constexpr int kCalls = 10;
        constexpr std::size_t kItems = 160000, kGrain = 5000;
        auto out = std::make_shared<std::vector<std::uint64_t>>(kItems, 0);
        Prepared p;
        p.items = std::int64_t(kCalls) * std::int64_t(kItems / kGrain);
        p.unit = "chunks";
        p.run = [out] {
            std::vector<std::uint64_t>& v = *out;
            double sum = 0;
            for (int call = 0; call < kCalls; ++call) {
                (void)jobs::parallel_for("bench.for_large", kItems, kGrain, [&v, call](const jobs::Chunk& c) {
                    for (std::size_t i = c.begin; i < c.end; ++i) v[i] = tiny_work(i + std::size_t(call), 24);
                });
                sum += sum_of(v);
            }
            return sum;
        };
        return p;
    };
    return b;
}

Bench dependency_graph() {
    Bench b;
    b.name = "jobs.graph";
    b.summary =
        "200 rounds of 1 job that fans out to 64 that fan in to 1 (13200 jobs), then a chain of 12000 jobs, each "
        "depending on the one before";
    threaded(b);
    b.make = [] {
        constexpr int kRounds = 200, kFan = 64, kChain = 12000;
        auto out = std::make_shared<std::vector<std::uint64_t>>(std::size_t(kRounds) * (kFan + 2) + kChain, 0);
        Prepared p;
        p.items = std::int64_t(out->size());
        p.unit = "jobs";
        p.run = [out] {
            std::vector<std::uint64_t>& v = *out;
            std::size_t slot = 0;
            jobs::Handle prev;
            std::vector<jobs::Handle> all;
            all.reserve(v.size());
            for (int r = 0; r < kRounds; ++r) {
                const std::size_t root = slot++;
                std::vector<jobs::Handle> deps;
                if (prev.valid()) deps.push_back(prev);
                jobs::Handle rootH =
                    jobs::submit("bench.graph.root", [&v, root] { v[root] = tiny_work(root, 8); }, deps);
                std::vector<jobs::Handle> mids;
                for (int k = 0; k < kFan; ++k) {
                    const std::size_t s = slot++;
                    mids.push_back(
                        jobs::submit("bench.graph.mid", [&v, s, root] { v[s] = tiny_work(s + v[root], 8); }, {rootH}));
                }
                const std::size_t join = slot++;
                prev = jobs::submit(
                    "bench.graph.join",
                    [&v, join, first = join - kFan, last = join] {
                        std::uint64_t s = 0;
                        for (std::size_t i = first; i < last; ++i) s += v[i];
                        v[join] = s;
                    },
                    mids);
                all.push_back(rootH);
                all.insert(all.end(), mids.begin(), mids.end());
                all.push_back(prev);
            }
            for (int i = 0; i < kChain; ++i) {
                const std::size_t s = slot++;
                std::vector<jobs::Handle> deps;
                if (prev.valid()) deps.push_back(prev);
                prev = jobs::submit("bench.graph.chain", [&v, s] { v[s] = tiny_work(s, 8); }, deps);
                all.push_back(prev);
            }
            (void)jobs::wait_all(all);
            return sum_of(v);
        };
        return p;
    };
    return b;
}

Bench nested_waits() {
    Bench b;
    b.name = "jobs.nested_wait";
    b.summary =
        "3072 jobs that each submit 8 jobs and wait for them (inside a job, so the wait helps), plus a parallel_for "
        "in every 4th one";
    threaded(b);
    b.make = [] {
        constexpr int kOuter = 3072, kInner = 8;
        auto out = std::make_shared<std::vector<std::uint64_t>>(std::size_t(kOuter) * kInner, 0);
        Prepared p;
        p.items = kOuter * (kInner + 1);
        p.unit = "jobs";
        p.run = [out] {
            std::vector<std::uint64_t>& v = *out;
            std::vector<jobs::Handle> outer;
            outer.reserve(kOuter);
            for (int o = 0; o < kOuter; ++o) {
                outer.push_back(jobs::submit("bench.nested.outer", [&v, o] {
                    std::vector<jobs::Handle> inner;
                    for (int k = 0; k < kInner; ++k) {
                        const std::size_t s = std::size_t(o) * kInner + std::size_t(k);
                        inner.push_back(jobs::submit("bench.nested.inner", [&v, s] { v[s] = tiny_work(s, 8); }));
                    }
                    (void)jobs::wait_all(inner);
                    if (o % 4 == 0) {
                        (void)jobs::parallel_for("bench.nested.for", kInner, 2, [&v, o](const jobs::Chunk& c) {
                            for (std::size_t i = c.begin; i < c.end; ++i) v[std::size_t(o) * kInner + i] += 1;
                        });
                    }
                }));
            }
            (void)jobs::wait_all(outer);
            return sum_of(v);
        };
        return p;
    };
    return b;
}

Bench main_thread_queue() {
    Bench b;
    b.name = "jobs.main_queue";
    b.summary =
        "160000 main-thread tasks posted from this thread, then run (run_main_thread_tasks), and 32000 more posted by "
        "jobs and run the same way";
    threaded(b);
    b.make = [] {
        constexpr int kTasks = 160000, kFromJobs = 32000, kPosters = 40;
        auto count = std::make_shared<std::uint64_t>(0);
        Prepared p;
        p.items = kTasks + kFromJobs;
        p.unit = "tasks";
        p.run = [count] {
            *count = 0;
            std::uint64_t* c = count.get();
            for (int i = 0; i < kTasks; ++i) jobs::post_main("bench.main", [c, i] { *c += std::uint64_t(i % 7) + 1; });
            int ran = jobs::run_main_thread_tasks();
            std::vector<jobs::Handle> posters;
            for (int j = 0; j < kPosters; ++j)
                posters.push_back(jobs::submit("bench.main.poster", [c, j] {
                    for (int i = 0; i < kFromJobs / kPosters; ++i)
                        jobs::post_main("bench.main", [c, j, i] { *c += std::uint64_t(j + i) % 5 + 1; });
                }));
            (void)jobs::wait_all(posters);
            ran += jobs::run_main_thread_tasks();
            return double(*count % 1000003ull) + double(ran);
        };
        return p;
    };
    return b;
}

}  // namespace

void add_jobs_benches(std::vector<Bench>& out) {
    out.push_back(tiny_jobs());
    out.push_back(parallel_for_small());
    out.push_back(parallel_for_large());
    out.push_back(dependency_graph());
    out.push_back(nested_waits());
    out.push_back(main_thread_queue());
}

}  // namespace fa::bench
