// The native file layer of fa::PackReader (pack.cpp): open, positional reads and a read-only memory mapping.
// pack_file_posix.cpp (macOS, Linux, iOS, Android, the web) and pack_file_win32.cpp implement it.
#pragma once

#include <cstdint>
#include <filesystem>

namespace fa::detail {

// Opens `file` for reading; -1 when it cannot. On Windows other processes may read, write, rename and delete it while
// it is open (FILE_SHARE_READ | WRITE | DELETE), as with a loose file.
std::intptr_t pack_open(const std::filesystem::path& file);
void pack_close(std::intptr_t native);
// Reads `size` bytes at `offset` without moving a file position (pread / ReadFile with an offset): any number of threads
// may call it at once. False when the file has fewer bytes there or the read fails.
bool pack_read_at(std::intptr_t native, std::uint64_t offset, void* dst, std::uint64_t size);
// Maps the first `size` bytes of the file read-only. False when this platform or process does not map packs (a 32-bit
// address space, the web build, whose files already live in memory) or the OS refused: the reader then reads.
// `mapping` is the Windows file mapping object (0 elsewhere). Every handle it made is released when it fails.
bool pack_map(std::intptr_t native, std::uint64_t size, const std::uint8_t*& map, std::intptr_t& mapping);
void pack_unmap(const std::uint8_t* map, std::uint64_t size, std::intptr_t mapping);

}  // namespace fa::detail
