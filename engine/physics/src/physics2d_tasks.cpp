// Box2D's task system on fa::jobs (see B2JobTasks in physics_internal.h).
#include <algorithm>
#include <atomic>
#include <vector>

#include "fa/core/jobs.h"
#include "fa/core/log.h"
#include "physics_internal.h"

namespace fa {

namespace {
std::atomic<int> g_awakeBodies{PhysicsJobThresholds{}.awakeBodies};
std::atomic<int> g_contacts{PhysicsJobThresholds{}.contacts};
}  // namespace

PhysicsJobThresholds physics_job_thresholds() {
    return {g_awakeBodies.load(std::memory_order_relaxed), g_contacts.load(std::memory_order_relaxed)};
}
void set_physics_job_thresholds(const PhysicsJobThresholds& t) {
    g_awakeBodies.store(t.awakeBodies, std::memory_order_relaxed);
    g_contacts.store(t.contacts, std::memory_order_relaxed);
}

}  // namespace fa

namespace fa::detail {

namespace {
// What enqueue hands back to Box2D for a task that went to the pool: one job per piece.
struct Pending {
    std::vector<jobs::Handle> pieces;
};
}  // namespace

void* B2JobTasks::enqueue(b2TaskCallback* task, int itemCount, int minRange, void* taskContext, void* userContext) {
    if (itemCount <= 0) return nullptr;
    const auto* self = static_cast<const B2JobTasks*>(userContext);
    // On the calling thread: small steps, a stopped or inline pool, a pool without workers, and any thread but the
    // main one (the solver's worker tasks wait for each other, so they must not queue behind a job that waits).
    if (!self->wide || !jobs::running() || jobs::inline_mode() || jobs::worker_count() <= 0 || !jobs::is_main_thread()) {
        task(0, itemCount, 0, taskContext);
        return nullptr;
    }
    // Pieces of at least minRange items, at most kWorkers; the piece index is the worker index Box2D indexes its
    // per-worker scratch with. A task of one item is one of Box2D's long-running ones (tree update, island split, the
    // solver's workers): it ignores the index and overlaps the rest of the step.
    const int pieces = std::clamp((itemCount + std::max(minRange, 1) - 1) / std::max(minRange, 1), 1, kWorkers);
    auto* pending = new Pending;
    pending->pieces.reserve(std::size_t(pieces));
    for (int p = 0; p < pieces; ++p) {
        const int begin = int(std::int64_t(itemCount) * p / pieces);
        const int end = int(std::int64_t(itemCount) * (p + 1) / pieces);
        pending->pieces.push_back(jobs::submit(
            "physics2d.step", [task, begin, end, p, taskContext] { task(begin, end, std::uint32_t(p), taskContext); }));
    }
    return pending;
}

void B2JobTasks::finish(void* userTask, void*) {
    auto* pending = static_cast<Pending*>(userTask);
    if (!pending) return;
    if (auto w = jobs::wait_all(pending->pieces); !w) {
        // A piece can only fail by a throw, which Box2D's C code never does; the step would be half done.
        FA_ERROR("physics", "2D physics: a step task failed: {}", w.error().to_string());
    }
    delete pending;
}

}  // namespace fa::detail
