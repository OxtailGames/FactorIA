// Typed arrays of numbers for reflected component fields: ArrayI32 (FieldKind::ArrayI32), ArrayF32 (ArrayF32) and
// ArrayU8 (ArrayU8). On disk and in commands the field is a flat JSON array of numbers; in memory it is contiguous
// (std::vector storage); a script reads it as an Int32Array / Float32Array / Uint8Array.
//
// Why a class and not a std::vector<T>: a consumer that derives data from the array (a physics body from a tile map, a
// render chunk) must know WHEN and WHERE it changed without comparing every element each frame. So the array counts
// its writes:
//   * version(): grows on every write through a mutable accessor or a modifier. Const access (const operator[],
//     const data(), cdata(), cbegin(), span()) never touches it. A consumer keeps the version it built from and
//     rebuilds when it differs.
//   * the dirty range: the smallest [dirty_begin(), dirty_end()) that covers every index written since the consumer
//     last called acknowledge(). A tile map of chunk size C rebuilds the chunks dirty_begin() / C ..
//     (dirty_end() - 1) / C and then acknowledges. A write that changes the size dirties [0, max(old size, new
//     size)), so dirty_end() may exceed size() after a shrink: clamp it.
//
// Rules for the writers:
//   * `a[i] = x` on a non-const array counts as a write of index i even when x equals the old value (the array cannot
//     see the store). `set(i, x)` writes only when the value differs, so use it where a no-op must not rebuild.
//   * A mutable data() / begin() / end() counts as a write of the WHOLE array. To read, call it on a const reference
//     (std::as_const(a).data(), or cdata()).
//   * Copy/move assignment and assign() compare first: assigning identical contents changes nothing; otherwise the
//     dirty range is the span between the first and last element that differ (the whole array when the size changes).
//     Reflection patches go through this, so patching another field of a component does not dirty its arrays.
//   * A new or copy-constructed array starts at version 0 with everything dirty (when not empty). A move
//     construction keeps version and dirty range (a pool that relocates a component must not look like a change).
//   * version() and the dirty range only mean something on ONE array object. A consumer that caches per component
//     drops its cache when the component is removed or added again.
//   * Not thread safe: one writer, no concurrent reads while it writes (the same rule as any component field).
#pragma once

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <initializer_list>
#include <span>
#include <type_traits>
#include <utility>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// The most elements a field written from JSON or from a script may hold (16 Mi: a 4096 x 4096 grid; 64 MiB of i32).
// Checked before anything is allocated.
inline constexpr std::size_t kMaxTypedArrayElements = std::size_t(1) << 24;

template <class T>
class TypedArray {
    static_assert(std::is_arithmetic_v<T>, "TypedArray holds numbers");

public:
    using value_type = T;

    TypedArray() = default;
    explicit TypedArray(std::size_t n, T value = T{}) : v_(n, value) { dirty_all(); }
    TypedArray(std::initializer_list<T> values) : v_(values) { dirty_all(); }
    TypedArray(const TypedArray& o) : v_(o.v_) { dirty_all(); }
    TypedArray(TypedArray&& o) noexcept
        : v_(std::move(o.v_)), version_(o.version_), dirtyBegin_(o.dirtyBegin_), dirtyEnd_(o.dirtyEnd_) {
        o.v_.clear();
        o.acknowledge();
    }
    TypedArray& operator=(const TypedArray& o) {
        if (this != &o) assign(o.v_.data(), o.v_.size());
        return *this;
    }
    TypedArray& operator=(TypedArray&& o) noexcept {
        if (this != &o) {
            std::size_t lo = 0, hi = 0;
            if (diff_range(o.v_.data(), o.v_.size(), lo, hi)) {
                v_ = std::move(o.v_);
                o.v_.clear();
                touch(lo, hi);
            }
            // Equal contents: nothing changed here.
        }
        return *this;
    }

    // ---- read: never touches version() or the dirty range
    std::size_t size() const { return v_.size(); }
    bool empty() const { return v_.empty(); }
    const T* data() const { return v_.data(); }
    const T* cdata() const { return v_.data(); }
    const T& operator[](std::size_t i) const {
        FA_ASSERT(i < v_.size(), "TypedArray index out of range");
        return v_[i];
    }
    const T* begin() const { return v_.data(); }
    const T* end() const { return v_.data() + v_.size(); }
    const T* cbegin() const { return begin(); }
    const T* cend() const { return end(); }
    std::span<const T> span() const { return {v_.data(), v_.size()}; }
    // The size is part of the value: arrays of different sizes differ. Version and dirty range are not compared.
    bool operator==(const TypedArray& o) const { return v_ == o.v_; }
    bool operator!=(const TypedArray& o) const { return v_ != o.v_; }

    // ---- write: each one bumps version() and marks what it touches
    // Mutable element access: counts as a write of index i (see the header comment).
    T& operator[](std::size_t i) {
        FA_ASSERT(i < v_.size(), "TypedArray index out of range");
        touch(i, i + 1);
        return v_[i];
    }
    // Mutable pointer: counts as a write of the whole array.
    T* data() {
        touch(0, v_.size());
        return v_.data();
    }
    T* begin() { return data(); }
    T* end() { return data() + v_.size(); }
    // Writes one element; changes nothing (no bump) when the value is already there. An index out of range is ignored
    // and returns false (a script cannot crash the engine with a bad index).
    bool set(std::size_t i, T value) {
        if (i >= v_.size()) return false;
        if (v_[i] != value) {
            v_[i] = value;
            touch(i, i + 1);
        }
        return true;
    }
    // Sets the elements in [first, last) (clamped to the size) to `value`; bumps only when one differs.
    void fill(T value, std::size_t first = 0, std::size_t last = SIZE_MAX) {
        last = std::min(last, v_.size());
        std::size_t lo = SIZE_MAX, hi = 0;
        for (std::size_t i = first; i < last; ++i) {
            if (v_[i] == value) continue;
            v_[i] = value;
            lo = std::min(lo, i);
            hi = i + 1;
        }
        if (lo != SIZE_MAX) touch(lo, hi);
    }
    // Replaces the contents with the `n` values at `p`. Identical contents change nothing.
    void assign(const T* p, std::size_t n) {
        std::size_t lo = 0, hi = 0;
        if (!diff_range(p, n, lo, hi)) return;
        if (n != v_.size())
            v_.assign(p, p + n);
        else
            std::copy(p + lo, p + hi, v_.begin() + std::ptrdiff_t(lo));
        touch(lo, hi);
    }
    void assign(std::span<const T> values) { assign(values.data(), values.size()); }
    // Changes the size (new elements = `value`); dirties [0, max(old size, n)).
    void resize(std::size_t n, T value = T{}) {
        if (n == v_.size()) return;
        const std::size_t old = v_.size();
        v_.resize(n, value);
        touch(0, std::max(old, n));
    }
    void push_back(T value) {
        v_.push_back(value);
        touch(0, v_.size());
    }
    void clear() { resize(0); }
    void reserve(std::size_t n) { v_.reserve(n); }  // capacity only: not a change
    // Declares that [first, last) was written through a pointer the array could not see (e.g. a memcpy into a
    // pointer taken from a const data()).
    void mark_dirty(std::size_t first, std::size_t last) {
        last = std::min(last, v_.size());
        if (first < last) touch(first, last);
    }

    // ---- change tracking
    // Counts the writes (never reset). Equal versions of the same array mean equal contents.
    std::uint64_t version() const { return version_; }
    bool has_dirty() const { return dirtyBegin_ < dirtyEnd_; }
    // Half-open index range of the writes since the last acknowledge(); begin == end == 0 when there are none. The end
    // can exceed size() after a shrink.
    std::size_t dirty_begin() const { return has_dirty() ? dirtyBegin_ : 0; }
    std::size_t dirty_end() const { return has_dirty() ? dirtyEnd_ : 0; }
    // The consumer has rebuilt from the array: forget the dirty range (version() is kept).
    void acknowledge() {
        dirtyBegin_ = kNone;
        dirtyEnd_ = 0;
    }

private:
    static constexpr std::size_t kNone = SIZE_MAX;

    void touch(std::size_t first, std::size_t last) {
        ++version_;
        dirtyBegin_ = std::min(dirtyBegin_, first);
        dirtyEnd_ = std::max(dirtyEnd_, last);
    }
    // A fresh array with elements: a consumer that never saw it must read it all.
    void dirty_all() {
        if (!v_.empty()) {
            dirtyBegin_ = 0;
            dirtyEnd_ = v_.size();
        }
    }
    // True and [lo, hi) = what changes when the contents become (p, n); false when they are identical.
    bool diff_range(const T* p, std::size_t n, std::size_t& lo, std::size_t& hi) const {
        if (n != v_.size()) {
            lo = 0;
            hi = std::max(n, v_.size());
            return true;
        }
        std::size_t a = 0;
        while (a < n && v_[a] == p[a]) ++a;
        if (a == n) return false;
        std::size_t b = n;
        while (b > a && v_[b - 1] == p[b - 1]) --b;
        lo = a;
        hi = b;
        return true;
    }

    std::vector<T> v_;
    std::uint64_t version_ = 0;
    std::size_t dirtyBegin_ = kNone;
    std::size_t dirtyEnd_ = 0;
};

using ArrayI32 = TypedArray<std::int32_t>;
using ArrayF32 = TypedArray<float>;
using ArrayU8 = TypedArray<std::uint8_t>;

}  // namespace fa
