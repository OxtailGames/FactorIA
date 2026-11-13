// The replacement global allocation functions of fa_test_audio, and the counter behind alloc_counter.h. Not inline (MSVC C4595),
// every form goes through the same malloc/free pair so any new/delete combination matches.
#include "alloc_counter.h"

#include <cstdlib>
#if defined(_WIN32)
#include <malloc.h>
#endif
#include <new>

namespace {

thread_local bool g_counting = false;
thread_local std::size_t g_count = 0;

inline void note() {
    if (g_counting) ++g_count;
}

void* allocate(std::size_t size) {
    note();
    if (size == 0) size = 1;
    return std::malloc(size);
}

void* allocate_aligned(std::size_t size, std::size_t align) {
    note();
    if (size == 0) size = 1;
#if defined(_WIN32)
    return _aligned_malloc(size, align);
#else
    void* p = nullptr;
    if (align < sizeof(void*)) align = sizeof(void*);
    return posix_memalign(&p, align, size) == 0 ? p : nullptr;
#endif
}

void release(void* p) { std::free(p); }

void release_aligned(void* p) {
#if defined(_WIN32)
    _aligned_free(p);
#else
    std::free(p);
#endif
}

}  // namespace

namespace audio_test {

std::size_t AllocCounter::count() { return g_count; }

AllocCounter::Scope::Scope() : previousCounting_(g_counting), previousCount_(g_count) {
    g_counting = true;
    g_count = 0;
}

// An inner scope hands its allocations to the outer one when it ends.
AllocCounter::Scope::~Scope() {
    g_counting = previousCounting_;
    g_count += previousCount_;
}

void* AllocCounter::allocate_for_test(std::size_t size) { return ::operator new(size); }
void AllocCounter::release_for_test(void* p) { ::operator delete(p); }

}  // namespace audio_test

#if !defined(FA_ALLOC_COUNTER_OFF)
void* operator new(std::size_t size) {
    if (void* p = allocate(size)) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t size) {
    if (void* p = allocate(size)) return p;
    throw std::bad_alloc();
}
void* operator new(std::size_t size, const std::nothrow_t&) noexcept { return allocate(size); }
void* operator new[](std::size_t size, const std::nothrow_t&) noexcept { return allocate(size); }
void* operator new(std::size_t size, std::align_val_t align) {
    if (void* p = allocate_aligned(size, std::size_t(align))) return p;
    throw std::bad_alloc();
}
void* operator new[](std::size_t size, std::align_val_t align) {
    if (void* p = allocate_aligned(size, std::size_t(align))) return p;
    throw std::bad_alloc();
}
void* operator new(std::size_t size, std::align_val_t align, const std::nothrow_t&) noexcept {
    return allocate_aligned(size, std::size_t(align));
}
void* operator new[](std::size_t size, std::align_val_t align, const std::nothrow_t&) noexcept {
    return allocate_aligned(size, std::size_t(align));
}

void operator delete(void* p) noexcept { release(p); }
void operator delete[](void* p) noexcept { release(p); }
void operator delete(void* p, std::size_t) noexcept { release(p); }
void operator delete[](void* p, std::size_t) noexcept { release(p); }
void operator delete(void* p, const std::nothrow_t&) noexcept { release(p); }
void operator delete[](void* p, const std::nothrow_t&) noexcept { release(p); }
void operator delete(void* p, std::align_val_t) noexcept { release_aligned(p); }
void operator delete[](void* p, std::align_val_t) noexcept { release_aligned(p); }
void operator delete(void* p, std::size_t, std::align_val_t) noexcept { release_aligned(p); }
void operator delete[](void* p, std::size_t, std::align_val_t) noexcept { release_aligned(p); }
void operator delete(void* p, std::align_val_t, const std::nothrow_t&) noexcept { release_aligned(p); }
void operator delete[](void* p, std::align_val_t, const std::nothrow_t&) noexcept { release_aligned(p); }
#endif  // !FA_ALLOC_COUNTER_OFF
