// The D3D12 backend's GPU timers: timestamp queries on the direct queue, resolved into a readback buffer per timed
// frame and read once the frame's fence passed (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
//
// The same contract as GpuTimer (gpu_timer.cpp) on D3D11 and GL: a ring of kTimerSlots timed frames (a full ring skips
// the frame), at most kMaxTimedScopes scopes per frame, scopes that do not nest, results polled in order and never
// waited for. Only the direct queue is timed: a copy queue would need D3D12_OPTIONS3.CopyQueueTimestampQueriesSupported.
#include <algorithm>
#include <cstring>
#include <string>
#include <utility>
#include <vector>

#include "gpu/d3d12_device.h"

namespace fa::gpu::d3d12 {

namespace {

constexpr std::uint32_t kQueriesPerSlot = 2u + 2u * 64u;  // frame start and end, then two per scope

}  // namespace

void D3d12Device::init_timer() {
    auto drop_timer_slots = [this] {
        for (TimerSlot& slot : timerSlots_) {
            slot.heap.reset();
            slot.readback.reset();
        }
    };
    static_assert(kQueriesPerSlot == 2u + 2u * std::uint32_t(kMaxTimedScopes));
    timerOk_ = false;
    UINT64 freq = 0;
    const HRESULT hr = queue_->GetTimestampFrequency(&freq);
    if (FAILED(hr) || freq == 0) {
        timerWhy_ = "the D3D12 direct queue of " + adapterName_ + " cannot time: GetTimestampFrequency failed with " +
                    hr_text(hr);
        return;
    }
    for (std::size_t i = 0; i < timerSlots_.size(); ++i) {
        TimerSlot& slot = timerSlots_[i];
        D3D12_QUERY_HEAP_DESC qd{};
        qd.Type = D3D12_QUERY_HEAP_TYPE_TIMESTAMP;
        qd.Count = kQueriesPerSlot;
        const HRESULT qhr = device_->CreateQueryHeap(&qd, __uuidof(ID3D12QueryHeap), slot.heap.put_void());
        if (FAILED(qhr) || !slot.heap) {
            timerWhy_ = "the D3D12 device of " + adapterName_ +
                        " could not make a timestamp query heap: CreateQueryHeap failed with " + hr_text(qhr);
            drop_timer_slots();
            return;
        }
        slot.heap->SetName(L"fa-d3d12-timer-queries");
        slot.readback = make_readback(std::uint64_t(kQueriesPerSlot) * sizeof(std::uint64_t), "the GPU timer");
        if (!slot.readback) {
            timerWhy_ = "the D3D12 device of " + adapterName_ +
                        " could not make the timer's readback buffer (see the render log for D3D12's reason)";
            drop_timer_slots();
            return;
        }
    }
    timestampFrequency_ = freq;
    timerOk_ = true;
    timerWhy_.clear();
}

bool D3d12Device::timer_supported(std::string* why) const {
    std::lock_guard<std::mutex> lock(timerMutex_);
    if (!timerOk_ && why) *why = timerWhy_;
    return timerOk_;
}

void D3d12Device::timer_begin_frame() {
    std::lock_guard<std::mutex> queueLock(queueMutex_);
    std::lock_guard<std::mutex> timerLock(timerMutex_);
    if (!timerOk_) return;
    if (timerCurrent_ >= 0) end_timer_frame_locked();              // a frame left open ends here
    if (timerPending_.size() >= std::size_t(kTimerSlots)) return;  // every slot waits for its fence: not timed
    D3d12CommandList& pl = prelude();
    if (!pl.list_) return;  // reported by acquire_list
    // The pending frames hold the slots before this one (in ring order), so this one is free.
    const int index = int(timerNext_++ % std::uint64_t(kTimerSlots));
    TimerSlot& slot = timerSlots_[std::size_t(index)];
    slot.serial = ++timerSerial_;
    slot.fence = 0;
    slot.names.clear();
    slot.submitted.clear();
    pl.list_->EndQuery(slot.heap.get(), D3D12_QUERY_TYPE_TIMESTAMP, 0);
    pl.empty_ = false;
    timerCurrent_ = index;
}

void D3d12Device::timer_end_frame() {
    std::lock_guard<std::mutex> queueLock(queueMutex_);
    std::lock_guard<std::mutex> timerLock(timerMutex_);
    if (timerCurrent_ >= 0) end_timer_frame_locked();
}

void D3d12Device::end_timer_frame_locked() {
    const int index = timerCurrent_;
    timerCurrent_ = -1;
    TimerSlot& slot = timerSlots_[std::size_t(index)];
    // A frame that cannot end (reported) is dropped; when timer_forget() counted it, it no longer arrives.
    auto drop = [this] {
        if (timerStale_ > timerPending_.size()) --timerStale_;
    };
    D3d12CommandList& pl = prelude();
    if (!pl.list_) return drop();
    ID3D12QueryHeap* heap = slot.heap.get();
    pl.list_->EndQuery(heap, D3D12_QUERY_TYPE_TIMESTAMP, 1);
    // A scope whose list was not submitted before the frame's end is not reported; its two queries are ended here so
    // the resolve reads no query that was never written.
    for (std::size_t i = 0; i < slot.submitted.size(); ++i)
        if (!slot.submitted[i]) {
            pl.list_->EndQuery(heap, D3D12_QUERY_TYPE_TIMESTAMP, UINT(2 + 2 * i));
            pl.list_->EndQuery(heap, D3D12_QUERY_TYPE_TIMESTAMP, UINT(3 + 2 * i));
        }
    const auto used = UINT(2 + 2 * slot.names.size());
    pl.list_->ResolveQueryData(heap, D3D12_QUERY_TYPE_TIMESTAMP, 0, used, slot.readback.get(), 0);
    pl.empty_ = false;
    D3d12CommandList* list = &pl;
    const std::uint64_t before = fenceValue_;
    flush_prelude();
    if (list->fence_ <= before) return drop();  // Close failed (reported): the resolve never runs
    slot.fence = list->fence_;
    timerPending_.push_back(index);
}

void D3d12Device::timer_poll(std::vector<double>& frameMs) {
    std::lock_guard<std::mutex> lock(timerMutex_);
    if (!timerOk_ || timerPending_.empty()) return;
    const std::uint64_t completed = fence_->GetCompletedValue();
    if (completed == UINT64_MAX) return;  // device lost: nothing more arrives
    while (!timerPending_.empty()) {
        TimerSlot& slot = timerSlots_[std::size_t(timerPending_.front())];
        if (slot.fence == 0 || slot.fence > completed) break;  // in order: the next one is not there yet
        timerPending_.pop_front();
        if (timerStale_ > 0) {
            --timerStale_;
            continue;
        }
        const std::size_t used = 2 + 2 * slot.names.size();
        std::vector<std::uint64_t> ticks(used, 0);
        void* p = nullptr;
        const D3D12_RANGE range{0, SIZE_T(used * sizeof(std::uint64_t))};
        if (FAILED(slot.readback->Map(0, &range, &p)) || !p) continue;  // out of address space: this frame is lost
        std::memcpy(ticks.data(), p, used * sizeof(std::uint64_t));
        const D3D12_RANGE none{0, 0};
        slot.readback->Unmap(0, &none);
        const double toMs = 1000.0 / double(timestampFrequency_);
        if (ticks[1] >= ticks[0]) frameMs.push_back(double(ticks[1] - ticks[0]) * toMs);
        struct Timed {
            std::uint64_t begin;
            ScopeTime time;
        };
        std::vector<Timed> scopes;
        for (std::size_t i = 0; i < slot.names.size(); ++i) {
            if (!slot.submitted[i]) continue;
            const std::uint64_t b = ticks[2 + 2 * i], e = ticks[3 + 2 * i];
            scopes.push_back({b, {slot.names[i], e > b ? double(e - b) * toMs : 0.0}});
        }
        std::stable_sort(scopes.begin(), scopes.end(),
                         [](const Timed& a, const Timed& b) { return a.begin < b.begin; });
        timerLastScopes_.clear();
        for (Timed& t : scopes) timerLastScopes_.push_back(std::move(t.time));
    }
}

std::vector<Device::ScopeTime> D3d12Device::timer_last_scopes() const {
    std::lock_guard<std::mutex> lock(timerMutex_);
    return timerLastScopes_;
}

void D3d12Device::timer_forget() {
    std::lock_guard<std::mutex> lock(timerMutex_);
    timerLastScopes_.clear();
    // The frames already ended arrive later and are dropped; the open one is dropped when it ends.
    timerStale_ = timerPending_.size() + (timerCurrent_ >= 0 ? 1 : 0);
}

}  // namespace fa::gpu::d3d12
