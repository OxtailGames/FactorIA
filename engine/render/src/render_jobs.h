// The render work of a frame handed to the job system (fa/core/jobs.h; docs/ARCHITECTURE.md, "Systems that run as
// jobs"). A pass splits its items into chunks whose bounds depend only on how many items there are (never on the
// thread count, never on a time), each chunk writes only its own slot, and the slots are joined in chunk order on the
// calling thread: the frame is the same with jobThreads "inline", 0 or 16. Below a pass's threshold (a count of items,
// see the constants at each pass), and whenever the pool has no worker thread (stopped, inline, 0 workers), the work
// is one chunk on the calling thread: a job would cost more than it saves, and with nobody to share the chunks with,
// splitting and joining them would only add copies. One chunk gives the same result as many (the joins are exact), so
// this never changes a frame. Nothing here touches sokol_gfx: the GPU calls stay on the main thread, after the passes.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <functional>
#include <limits>
#include <string_view>
#include <utility>
#include <vector>

#include "fa/core/jobs.h"

namespace fa::render::rjobs {

// A float as a sort key: NaN (a NaN transform, colour or distance) becomes +infinity. A comparison with NaN is
// false both ways, which breaks the strict weak order every sort needs: std::stable_sort and the chunked sort below
// would then disagree, and the frame would depend on the thread count. Every float a render sort compares goes
// through this.
inline float order_float(float v) { return std::isnan(v) ? std::numeric_limits<float>::infinity() : v; }

// How a pass splits `count` items: `chunks` pieces of `grain` items (the last one shorter). One chunk with every item
// when count < minCount, grain is 0 or the pool has no worker thread.
struct Split {
    std::size_t count = 0;
    std::size_t grain = 1;
    std::size_t chunks = 0;
};

inline Split split(std::size_t count, std::size_t grain, std::size_t minCount) {
    Split s;
    s.count = count;
    if (count == 0) return s;
    if (count < minCount || grain == 0 || grain >= count || jobs::worker_count() == 0) {
        s.grain = count;
        s.chunks = 1;
        return s;
    }
    s.grain = grain;
    s.chunks = jobs::chunk_count(count, grain);
    return s;
}

// Every item in one chunk, run on the calling thread.
inline Split whole(std::size_t count) { return split(count, 0, 0); }

// Chunks for items of very different sizes (emitters of 3 or 3000 particles): jobs::weighted_ranges (fa/core/jobs.h).
using jobs::weighted_ranges;

// Runs fn on every chunk of `s`: as jobs when there are several, at once on this thread when there is one. A chunk
// that throws is logged by the job system with `name`; the frame goes on with what the other chunks wrote.
void run(std::string_view name, const Split& s, const std::function<void(const jobs::Chunk&)>& fn);

// std::stable_sort of `v` by `less`, as jobs when v has at least `minCount` items: each chunk of `grain` items is
// sorted on its own, then neighbouring runs are merged pass by pass (std::merge keeps equal items of the left run
// first). A stable sort has exactly one result, so this gives the same order as std::stable_sort whatever the chunks.
template <class T, class Less>
void stable_sort(std::string_view name, std::vector<T>& v, Less less, std::size_t minCount, std::size_t grain) {
    const std::size_t n = v.size();
    const Split s = split(n, grain, minCount);
    if (s.chunks <= 1) {
        std::stable_sort(v.begin(), v.end(), less);
        return;
    }
    using Diff = typename std::vector<T>::difference_type;
    run(name, s, [&](const jobs::Chunk& c) {
        std::stable_sort(v.begin() + Diff(c.begin), v.begin() + Diff(c.end), less);
    });
    std::vector<T> scratch(n);
    std::vector<T>* src = &v;
    std::vector<T>* dst = &scratch;
    for (std::size_t width = s.grain; width < n; width *= 2) {
        const std::size_t pairs = (n + 2 * width - 1) / (2 * width);
        run(name, Split{pairs, 1, pairs}, [&](const jobs::Chunk& c) {
            for (std::size_t p = c.begin; p < c.end; ++p) {
                const std::size_t lo = p * 2 * width, mid = std::min(n, lo + width), hi = std::min(n, lo + 2 * width);
                const auto in = src->begin();
                std::merge(in + Diff(lo), in + Diff(mid), in + Diff(mid), in + Diff(hi), dst->begin() + Diff(lo), less);
            }
        });
        std::swap(src, dst);
    }
    if (src != &v) v.swap(*src);
}

}  // namespace fa::render::rjobs
