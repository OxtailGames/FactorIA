#include "render_jobs.h"

#include <atomic>
#include <exception>
#include <string>

#include "fa/core/log.h"

namespace fa::render::rjobs {

namespace {

// What the frame does about a failed chunk, said once per process: it draws what the other chunks gathered.
void report_failure(std::string_view name, const std::string& message) {
    static std::atomic<bool> warned{false};
    if (!warned.exchange(true))
        FA_ERROR("render", "{}: a chunk failed ({}); this frame draws what the other chunks gathered", name,
                 message);
}

}  // namespace

void run(std::string_view name, const Split& s, const std::function<void(const jobs::Chunk&)>& fn) {
    if (s.chunks == 0) return;
    if (s.chunks == 1) {
        // One chunk on this thread: a throw is caught and reported as parallel_for does for a chunk of a job (its
        // name, what it threw), so a frame goes on the same way whatever the thread count.
        jobs::Chunk c;
        c.end = s.count;
        std::string what;
        try {
            fn(c);
            return;
        } catch (const std::exception& e) {
            what = std::string("exception: ") + e.what();
        } catch (...) {
            what = "an exception that is not a std::exception";
        }
        const std::string message = "chunk 0 (items 0.." + std::to_string(s.count - 1) + ") failed: " + what;
        FA_ERROR("jobs", "parallel_for '{}': 1 of 1 chunk(s) failed; the first is chunk 0 (items 0..{}): {}", name,
                 s.count - 1, what);
        report_failure(name, std::string("parallel_for '") + std::string(name) + "' " + message);
        return;
    }
    // The job system already logged the job's name and what it threw; say what the frame does about it once.
    if (auto r = jobs::parallel_for(name, s.count, s.grain, fn); !r) report_failure(name, r.error().message);
}

std::vector<std::pair<std::size_t, std::size_t>> weighted_ranges(const std::vector<std::size_t>& weights,
                                                                 std::size_t target, std::size_t minTotal) {
    std::vector<std::pair<std::size_t, std::size_t>> out;
    if (weights.empty()) return out;
    std::size_t total = 0;
    for (std::size_t w : weights) total += w;
    if (total < minTotal || jobs::worker_count() == 0) {
        out.emplace_back(0, weights.size());
        return out;
    }
    std::size_t first = 0, sum = 0;
    for (std::size_t i = 0; i < weights.size(); ++i) {
        sum += weights[i];
        if (sum >= target) {
            out.emplace_back(first, i + 1);
            first = i + 1;
            sum = 0;
        }
    }
    if (first < weights.size()) out.emplace_back(first, weights.size());
    return out;
}

}  // namespace fa::render::rjobs
