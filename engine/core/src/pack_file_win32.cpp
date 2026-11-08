// fa::PackReader's file layer on Windows: CreateFileW, ReadFile with an offset, CreateFileMappingW + MapViewOfFile.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include <algorithm>
#include <cstddef>
#include <limits>

#include "fa/core/fs.h"
#include "pack_file.h"

namespace fa::detail {

std::intptr_t pack_open(const std::filesystem::path& file) {
    HANDLE h = CreateFileW(fs::os_path(file).c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_RANDOM_ACCESS, nullptr);
    return h == INVALID_HANDLE_VALUE ? -1 : reinterpret_cast<std::intptr_t>(h);
}

void pack_close(std::intptr_t native) {
    if (native != -1) CloseHandle(reinterpret_cast<HANDLE>(native));
}

bool pack_read_at(std::intptr_t native, std::uint64_t offset, void* dst, std::uint64_t size) {
    auto* out = static_cast<unsigned char*>(dst);
    while (size > 0) {
        const DWORD chunk = DWORD(std::min<std::uint64_t>(size, std::uint64_t(1) << 28));
        OVERLAPPED at{};
        at.Offset = DWORD(offset & 0xffffffffu);
        at.OffsetHigh = DWORD(offset >> 32);
        DWORD got = 0;
        if (!ReadFile(reinterpret_cast<HANDLE>(native), out, chunk, &got, &at) || got == 0) return false;
        out += got;
        offset += got;
        size -= got;
    }
    return true;
}

bool pack_map(std::intptr_t native, std::uint64_t size, const std::uint8_t*& map, std::intptr_t& mapping) {
    map = nullptr;
    mapping = 0;
    // A 32-bit process has too little address space to map a game of hundreds of MB: it reads instead.
    if constexpr (sizeof(void*) < 8) {
        (void)native;
        (void)size;
        return false;
    } else {
        if (native == -1 || size == 0 || size > std::uint64_t(std::numeric_limits<std::size_t>::max() / 2)) return false;
        HANDLE section = CreateFileMappingW(reinterpret_cast<HANDLE>(native), nullptr, PAGE_READONLY, DWORD(size >> 32),
                                            DWORD(size & 0xffffffffu), nullptr);
        if (!section) return false;
        void* view = MapViewOfFile(section, FILE_MAP_READ, 0, 0, SIZE_T(size));
        if (!view) {
            CloseHandle(section);
            return false;
        }
        map = static_cast<const std::uint8_t*>(view);
        mapping = reinterpret_cast<std::intptr_t>(section);
        return true;
    }
}

void pack_unmap(const std::uint8_t* map, std::uint64_t, std::intptr_t mapping) {
    if (map) UnmapViewOfFile(map);
    if (mapping) CloseHandle(reinterpret_cast<HANDLE>(mapping));
}

}  // namespace fa::detail
