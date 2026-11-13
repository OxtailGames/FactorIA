// Lock-free structures between the game thread and the audio thread (private to fa_audio). Both are deliberately the
// textbook versions: one producer, one consumer, fixed storage allocated up front, monotonic indexes. Nothing here
// blocks, allocates after construction or spins.
//
// The memory-ordering rule they all follow: whoever hands data to the other thread writes the data first and then
// publishes an index with a release store; the other thread reads that index with an acquire load before it reads the
// data. Handing a slot back (the consumer saying "I am done with it") is the same rule in the other direction.
#pragma once

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace fa::audio_detail {

inline std::size_t round_up_pow2(std::size_t n) {
    std::size_t p = 1;
    while (p < n) p <<= 1;
    return p;
}

// A bounded single-producer single-consumer queue of trivially copyable values. The producer stages values with push()
// and makes them visible with commit(): a batch committed at once is seen by the consumer whole or not at all (the mixer
// applies the commands of one API call in the same block). The capacity is a power of two (rounded up).
template <class T>
class SpscRing {
public:
    explicit SpscRing(std::size_t capacity)
        : slots_(round_up_pow2(capacity < 2 ? 2 : capacity)), mask_(slots_.size() - 1) {}

    std::size_t capacity() const { return slots_.size(); }

    // ---- producer side
    // Room for this many more pushes. Acquire: the consumer's release of `read_` means it has finished copying the slots
    // before that index, so they may be overwritten.
    std::size_t free_space() const {
        return slots_.size() - std::size_t(staged_ - read_.load(std::memory_order_acquire));
    }
    bool push(const T& v) {
        if (free_space() == 0) return false;
        slots_[std::size_t(staged_ & mask_)] = v;
        ++staged_;
        return true;
    }
    // Publishes everything pushed so far. Release: the slot writes above happen-before the consumer's acquire of `write_`.
    void commit() { write_.store(staged_, std::memory_order_release); }

    // ---- consumer side
    // Acquire pairs with commit(): the values of every index below the loaded `write_` are visible.
    std::size_t size() const {
        return std::size_t(write_.load(std::memory_order_acquire) - read_.load(std::memory_order_relaxed));
    }
    bool empty() const { return size() == 0; }
    // The oldest value, or null. Valid until pop().
    const T* front() const {
        const std::uint64_t r = read_.load(std::memory_order_relaxed);  // only this thread writes read_
        if (r == write_.load(std::memory_order_acquire)) return nullptr;
        return &slots_[std::size_t(r & mask_)];
    }
    // Release: the copy out of the slot is finished before the producer may reuse it (see free_space()).
    void pop() { read_.store(read_.load(std::memory_order_relaxed) + 1, std::memory_order_release); }
    bool pop(T& out) {
        const T* f = front();
        if (!f) return false;
        out = *f;
        pop();
        return true;
    }

private:
    std::vector<T> slots_;
    std::size_t mask_;
    std::uint64_t staged_ = 0;             // producer only: pushed, maybe not committed
    std::atomic<std::uint64_t> write_{0};  // written by the producer (commit), read by both
    std::atomic<std::uint64_t> read_{0};   // written by the consumer (pop), read by both
};

// The latest value of something one thread writes and another reads, without either waiting: three slots, the writer
// owns one, the reader owns one, the third is "the middle" and the two trade theirs for it. The reader always gets a
// whole value (never one being written) and the newest one published.
template <class T>
class TripleBuffer {
public:
    // ---- writer
    T& back() { return slots_[back_]; }
    // Hands the slot just written over and takes the middle one back. acq_rel: release so the reader that takes this
    // slot sees what was written into it; acquire so the slot the writer gets back is one the reader released.
    void publish() {
        back_ = std::uint8_t(middle_.exchange(std::uint8_t(back_ | kFresh), std::memory_order_acq_rel) & kIndex);
    }

    // ---- reader
    // Takes the newest published value if there is one since the last call (true), else keeps the current one.
    // The relaxed peek is only a shortcut; the exchange is what synchronizes (acq_rel, the mirror of publish()).
    bool update() {
        if (!(middle_.load(std::memory_order_relaxed) & kFresh)) return false;
        front_ = std::uint8_t(middle_.exchange(front_, std::memory_order_acq_rel) & kIndex);
        return true;
    }
    const T& front() const { return slots_[front_]; }

private:
    static constexpr std::uint8_t kIndex = 3, kFresh = 4;
    T slots_[3]{};
    std::uint8_t back_ = 0, front_ = 2;    // owned by the writer / the reader
    std::atomic<std::uint8_t> middle_{1};  // the slot neither owns, plus kFresh when the writer published into it
};

}  // namespace fa::audio_detail
