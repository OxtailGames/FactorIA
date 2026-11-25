// The Vulkan backend's GPU timers: timestamp queries on the graphics queue, one query pool per timed frame, read once
// the frame's timeline value passed (docs/design/ARCHITECTURE_RENDERING_VULKAN.md, "GPU timers").
//
// The same contract as GpuTimer (gpu_timer.cpp) on D3D11 and GL and as the D3D12 backend: a ring of kTimerSlots timed
// frames (a full ring skips the frame), at most kMaxTimedScopes scopes per frame, scopes that do not nest, results
// polled in order and never waited for. The prelude (the device's own list, submitted before every other list) resets
// a frame's pool and writes its start timestamp, and writes its end one at timer_end_frame. A scope whose list was not
// submitted before the frame's end is never read: vkGetQueryPoolResults reads only the frame's two queries and the
// submitted scopes' pairs, so no query that was never written is asked for.
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

namespace fa::gpu::vk {

namespace {

constexpr std::uint32_t kQueriesPerSlot = 2u + 2u * 64u;  // frame start and end, then two per scope

}  // namespace

void VulkanDevice::init_timer() {
    static_assert(kQueriesPerSlot == 2u + 2u * std::uint32_t(kMaxTimedScopes));
    std::lock_guard<std::mutex> lock(timerMutex_);
    timerOk_ = false;
    if (queues_[0].timestampBits == 0) {
        timerWhy_ = "the queue family " + std::to_string(queues_[0].family) + " of " + deviceName_ +
                    " has no timestamps (timestampValidBits is 0): GPU time cannot be measured on this device";
        return;
    }
    if (!(props_.limits.timestampPeriod > 0.0f)) {
        timerWhy_ = "the Vulkan driver of " + deviceName_ + " gives no timestamp period (timestampPeriod is 0)";
        return;
    }
    for (TimerSlot& slot : timerSlots_) {
        VkQueryPoolCreateInfo qi{};
        qi.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
        qi.queryType = VK_QUERY_TYPE_TIMESTAMP;
        qi.queryCount = kQueriesPerSlot;
        const VkResult r = fn_.vkCreateQueryPool(device_, &qi, nullptr, &slot.pool);
        if (r != VK_SUCCESS || !slot.pool) {
            slot.pool = VK_NULL_HANDLE;
            timerWhy_ = "the Vulkan device " + deviceName_ +
                        " could not make a timestamp query pool: vkCreateQueryPool failed with " + result_text(r);
            for (TimerSlot& s : timerSlots_)
                if (s.pool) {
                    fn_.vkDestroyQueryPool(device_, s.pool, nullptr);
                    s.pool = VK_NULL_HANDLE;
                }
            return;
        }
        set_name(VK_OBJECT_TYPE_QUERY_POOL, handle_bits(slot.pool), "fa-vulkan-timer-queries");
    }
    timerOk_ = true;
    timerWhy_.clear();
}

void VulkanDevice::destroy_timer() {
    std::lock_guard<std::mutex> lock(timerMutex_);
    // A pool goes once the submissions that write its queries finished: the frames ended and not read yet are waited
    // for (bounded; a device lost gives up at once).
    for (int s : timerPending_) {
        const TimerSlot& slot = timerSlots_[std::size_t(s)];
        if (slot.fence > 0) (void)wait_timeline(slot.fence, "destroy_timer");
    }
    for (TimerSlot& slot : timerSlots_)
        if (slot.pool) {
            fn_.vkDestroyQueryPool(device_, slot.pool, nullptr);
            slot.pool = VK_NULL_HANDLE;
        }
    timerOk_ = false;
    timerWhy_ = "the device is being destroyed";
    timerPending_.clear();
    timerCurrent_ = -1;
}

bool VulkanDevice::timer_supported(std::string* why) const {
    std::lock_guard<std::mutex> lock(timerMutex_);
    if (!timerOk_ && why) *why = timerWhy_;
    return timerOk_;
}

void VulkanDevice::timer_begin_frame() {
    std::lock_guard<std::mutex> queueLock(queueMutex_);
    std::lock_guard<std::mutex> timerLock(timerMutex_);
    if (!timerOk_) return;
    if (timerCurrent_ >= 0) end_timer_frame_locked();              // a frame left open ends here
    if (timerPending_.size() >= std::size_t(kTimerSlots)) return;  // every slot waits for its GPU work: not timed
    VulkanCommandList& pl = prelude();
    if (!pl.open_ || !pl.cmd_) return;  // reported by acquire_list
    // The next slot in ring order that no pending frame holds (a dropped frame leaves its slot free and out of order,
    // so the next one in the ring may still be pending: it is skipped, never reset under its results). One is free:
    // fewer than kTimerSlots are pending. The reset runs after whatever last wrote its queries (one queue, in
    // submission order).
    int index = -1;
    for (int tries = 0; tries < kTimerSlots && index < 0; ++tries) {
        const int candidate = int(timerNext_++ % std::uint64_t(kTimerSlots));
        if (std::find(timerPending_.begin(), timerPending_.end(), candidate) == timerPending_.end()) index = candidate;
    }
    if (index < 0) return;
    TimerSlot& slot = timerSlots_[std::size_t(index)];
    slot.serial = ++timerSerial_;
    slot.fence = 0;
    slot.names.clear();
    slot.submitted.clear();
    fn_.vkCmdResetQueryPool(pl.cmd_, slot.pool, 0, kQueriesPerSlot);
    fn_.vkCmdWriteTimestamp(pl.cmd_, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, slot.pool, 0);
    pl.empty_ = false;
    timerCurrent_ = index;
}

void VulkanDevice::timer_end_frame() {
    std::lock_guard<std::mutex> queueLock(queueMutex_);
    std::lock_guard<std::mutex> timerLock(timerMutex_);
    if (timerCurrent_ >= 0) end_timer_frame_locked();
}

void VulkanDevice::end_timer_frame_locked() {
    const int index = timerCurrent_;
    timerCurrent_ = -1;
    TimerSlot& slot = timerSlots_[std::size_t(index)];
    // A frame that cannot end (reported) is dropped; when timer_forget() counted it, it no longer arrives.
    auto drop = [this] {
        if (timerStale_ > timerPending_.size()) --timerStale_;
    };
    VulkanCommandList& pl = prelude();
    if (!pl.open_ || !pl.cmd_) return drop();
    fn_.vkCmdWriteTimestamp(pl.cmd_, VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, slot.pool, 1);
    pl.empty_ = false;
    VulkanCommandList* list = &pl;
    const std::uint64_t before = queues_[0].value;
    flush_prelude();
    if (list->fence_ <= before) return drop();  // the submission failed (reported): the end timestamp never runs
    slot.fence = list->fence_;
    timerPending_.push_back(index);
}

void VulkanDevice::timer_poll(std::vector<double>& frameMs) {
    std::lock_guard<std::mutex> lock(timerMutex_);
    if (!timerOk_ || timerPending_.empty()) return;
    const std::uint64_t completed = completed_value();  // 0 when the device was lost: nothing more arrives
    const std::uint32_t bits = queues_[0].timestampBits;
    const std::uint64_t mask = bits >= 64 ? ~0ull : (1ull << bits) - 1ull;
    const double toMs = double(props_.limits.timestampPeriod) * 1e-6;  // nanoseconds per tick -> milliseconds
    auto ticks_between = [&](const std::uint64_t (&t)[2]) { return double((t[1] - t[0]) & mask) * toMs; };
    while (!timerPending_.empty()) {
        TimerSlot& slot = timerSlots_[std::size_t(timerPending_.front())];
        if (slot.fence == 0 || slot.fence > completed) break;  // in order: the next one is not there yet
        timerPending_.pop_front();
        if (timerStale_ > 0) {
            --timerStale_;
            continue;
        }
        // The timeline passed the frame's end, so its queries were written. VK_QUERY_RESULT_WAIT_BIT all the same: a
        // driver may signal the timeline before the results are visible (MoltenVK signals it from a command buffer's
        // completion handler), and without the wait such a frame came back VK_NOT_READY. The wait is that short gap
        // only; a scope whose list was not submitted is never read (its queries were never written).
        std::uint64_t frame[2] = {};
        const VkResult fr =
            fn_.vkGetQueryPoolResults(device_, slot.pool, 0, 2, sizeof(frame), frame, sizeof(std::uint64_t),
                                      VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
        if (fr != VK_SUCCESS) continue;  // this frame is lost
        frameMs.push_back(ticks_between(frame));
        struct Timed {
            std::uint64_t begin;
            ScopeTime time;
        };
        std::vector<Timed> scopes;
        for (std::size_t i = 0; i < slot.names.size(); ++i) {
            if (!slot.submitted[i]) continue;
            std::uint64_t t[2] = {};
            const VkResult sr =
                fn_.vkGetQueryPoolResults(device_, slot.pool, std::uint32_t(2 + 2 * i), 2, sizeof(t), t,
                                          sizeof(std::uint64_t), VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
            if (sr != VK_SUCCESS) continue;
            // In the frame's order: ticks since the frame's start (masked, so a counter that wrapped still sorts).
            scopes.push_back({(t[0] - frame[0]) & mask, {slot.names[i], ticks_between(t)}});
        }
        std::stable_sort(scopes.begin(), scopes.end(),
                         [](const Timed& a, const Timed& b) { return a.begin < b.begin; });
        timerLastScopes_.clear();
        for (Timed& t : scopes) timerLastScopes_.push_back(std::move(t.time));
    }
}

std::vector<Device::ScopeTime> VulkanDevice::timer_last_scopes() const {
    std::lock_guard<std::mutex> lock(timerMutex_);
    return timerLastScopes_;
}

void VulkanDevice::timer_forget() {
    std::lock_guard<std::mutex> lock(timerMutex_);
    timerLastScopes_.clear();
    // The frames already ended arrive later and are dropped; the open one is dropped when it ends.
    timerStale_ = timerPending_.size() + (timerCurrent_ >= 0 ? 1 : 0);
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
