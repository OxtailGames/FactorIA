#include "render_jobs.h"

#include <atomic>

#include "fa/core/log.h"

namespace fa::render::rjobs {

void run(std::string_view name, const Split& s, const std::function<void(const jobs::Chunk&)>& fn) {
    if (s.chunks == 0) return;
    if (s.chunks == 1) {
        jobs::Chunk c;
        c.end = s.count;
        fn(c);
        return;
    }
    // The job system already logged the job's name and what it threw; say what the frame does about it once.
    if (auto r = jobs::parallel_for(name, s.count, s.grain, fn); !r) {
        static std::atomic<bool> warned{false};
        if (!warned.exchange(true))
            FA_ERROR("render", "{}: a chunk failed ({}); this frame draws what the other chunks gathered", name, r.error().message);
    }
}

std::vector<std::pair<std::size_t, std::size_t>> weighted_ranges(const std::vector<std::size_t>& weights, std::size_t target,
                                                                 std::size_t minTotal) {
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
