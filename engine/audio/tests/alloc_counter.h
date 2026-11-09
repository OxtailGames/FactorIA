// Counts the heap allocations the calling thread makes while a Scope is alive. The global operator new of this test binary
// is replaced (alloc_counter.cpp); the count is off by default, so the other tests of fa_test_audio only pay one thread-local
// read per allocation. Only the thread that made the Scope is counted: allocations of other threads (job workers...) are not.
#pragma once

#include <cstddef>

namespace audio_test {

struct AllocCounter {
    // Allocations (operator new calls, every form) made by this thread since the innermost Scope began.
    static std::size_t count();

    struct Scope {
        Scope();
        ~Scope();
        Scope(const Scope&) = delete;
        Scope& operator=(const Scope&) = delete;
        std::size_t count() const { return AllocCounter::count(); }

    private:
        bool previous_;
    };
};

}  // namespace audio_test
