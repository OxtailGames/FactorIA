// The native file layer of fa::PackReader (pack.cpp): open, positional reads and a read-only memory mapping.
// pack_file_posix.cpp (macOS, Linux, iOS, Android, the web) and pack_file_win32.cpp implement it.
#pragma once

#include <cstdint>
#include <filesystem>

namespace fa::detail {

// Opens `file` for reading; -1 when it cannot. On Windows it is opened with FILE_SHARE_READ | WRITE | DELETE: other
// processes may read and write it, and rename or delete it while it is not mapped, but nobody can replace it: MoveFileExW
// onto a file that is open fails (mapped or not), so an export cannot replace the pack of a running game (fa::PackWriter
// reports it). fs::replace_file keeps that rule; the Windows rules emulation (fs.h) follows it for every open PackReader.
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
