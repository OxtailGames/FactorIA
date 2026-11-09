// fa::PackReader's file layer on POSIX systems (macOS, Linux, iOS, Android, the web): open, pread, mmap.
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <cstddef>
#include <limits>

#include "pack_file.h"

namespace fa::detail {

std::intptr_t pack_open(const std::filesystem::path& file) {
    int fd = -1;
    do {
        fd = ::open(file.c_str(), O_RDONLY | O_CLOEXEC);
    } while (fd < 0 && errno == EINTR);
    return fd;
}

void pack_close(std::intptr_t native) {
    if (native >= 0) ::close(int(native));
}

bool pack_read_at(std::intptr_t native, std::uint64_t offset, void* dst, std::uint64_t size) {
    auto* out = static_cast<unsigned char*>(dst);
#if defined(__ANDROID__) && !defined(__LP64__)
    // 32-bit Android: off_t is 32 bits there, pread64 takes the 64-bit offset of a pack over 2 GB.
    using Offset = off64_t;
#else
    using Offset = off_t;
#endif
    while (size > 0) {
        if (offset > std::uint64_t(std::numeric_limits<Offset>::max())) return false;
        const std::size_t chunk = std::size_t(std::min<std::uint64_t>(size, std::uint64_t(1) << 30));
#if defined(__ANDROID__) && !defined(__LP64__)
        const ssize_t got = ::pread64(int(native), out, chunk, Offset(offset));
#else
        const ssize_t got = ::pread(int(native), out, chunk, Offset(offset));
#endif
        if (got < 0 && errno == EINTR) continue;
        if (got <= 0) return false;
        out += got;
        offset += std::uint64_t(got);
        size -= std::uint64_t(got);
    }
    return true;
}

bool pack_map(std::intptr_t native, std::uint64_t size, const std::uint8_t*& map, std::intptr_t& mapping) {
    mapping = 0;
    map = nullptr;
#if defined(__EMSCRIPTEN__)
    // The web player's pack is in MEMFS (browser memory): mmap there copies the whole file, and reads are a memcpy already.
    (void)native;
    (void)size;
    return false;
#else
    // A 32-bit process (32-bit Android) has too little address space to map a game of hundreds of MB: it reads instead.
    if constexpr (sizeof(void*) < 8) {
        (void)native;
        (void)size;
        return false;
    } else {
        if (native < 0 || size == 0 || size > std::uint64_t(std::numeric_limits<std::size_t>::max() / 2)) return false;
        void* p = ::mmap(nullptr, std::size_t(size), PROT_READ, MAP_SHARED, int(native), 0);
        if (p == MAP_FAILED) return false;
        map = static_cast<const std::uint8_t*>(p);
        return true;
    }
#endif
}

void pack_unmap(const std::uint8_t* map, std::uint64_t size, std::intptr_t) {
    if (map) ::munmap(const_cast<std::uint8_t*>(map), std::size_t(size));
}

}  // namespace fa::detail
