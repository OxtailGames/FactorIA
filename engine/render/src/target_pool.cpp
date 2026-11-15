#include "target_pool.h"

#include <algorithm>
#include <utility>

namespace fa::render {

TargetPool::TargetPool(CreateFn create, DestroyFn destroy, int maxIdleFrames)
    : create_(std::move(create)), destroy_(std::move(destroy)), maxIdle_(std::max(0, maxIdleFrames)) {}

TargetPool::~TargetPool() {
    for (Entry& e : entries_) {
        if (destroy_) destroy_(e.handle);
        ++counters_.destroyed;
    }
    entries_.clear();
}

std::uint64_t TargetPool::acquire(const TransientDesc& desc) {
    for (Entry& e : entries_) {
        if (!e.inUse && e.desc.same_shape(desc)) {
            e.inUse = true;
            e.lastUsedFrame = frame_;
            ++counters_.reused;
            return e.handle;
        }
    }
    std::uint64_t h = create_ ? create_(desc) : 0;
    if (h == 0) return 0;
    ++counters_.created;
    Entry e;
    e.handle = h;
    e.desc = desc;
    e.inUse = true;
    e.lastUsedFrame = frame_;
    entries_.push_back(std::move(e));
    return h;
}

void TargetPool::release(std::uint64_t handle) {
    for (Entry& e : entries_) {
        if (e.handle == handle) {
            if (e.inUse) {
                e.inUse = false;
                e.lastUsedFrame = frame_;
            }
            return;
        }
    }
}

void TargetPool::begin_frame() {
    ++frame_;
    auto dead = [&](const Entry& e) { return !e.inUse && frame_ - e.lastUsedFrame > maxIdle_; };
    for (Entry& e : entries_) {
        if (dead(e)) {
            if (destroy_) destroy_(e.handle);
            ++counters_.destroyed;
        }
    }
    entries_.erase(std::remove_if(entries_.begin(), entries_.end(), dead), entries_.end());
}

void TargetPool::clear_free() {
    auto freeEntry = [](const Entry& e) { return !e.inUse; };
    for (Entry& e : entries_) {
        if (freeEntry(e)) {
            if (destroy_) destroy_(e.handle);
            ++counters_.destroyed;
        }
    }
    entries_.erase(std::remove_if(entries_.begin(), entries_.end(), freeEntry), entries_.end());
}

TargetPoolStats TargetPool::stats() const {
    TargetPoolStats s = counters_;
    s.live = int(entries_.size());
    s.inUse = int(std::count_if(entries_.begin(), entries_.end(), [](const Entry& e) { return e.inUse; }));
    return s;
}

}  // namespace fa::render
