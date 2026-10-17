// Game pack: ONE read-only archive that holds all the files of a game (a `--release` desktop export, docs/EXPORTING.md).
//
// A pack is read through `fa::fs` (fs::mount_pack, fa/core/fs.h): while one is mounted every project-relative path the
// engine reads ("scenes/main.scene.json", "assets/hero.png") is answered from it instead of from loose files.
//
// File format (version 1), all integers little-endian:
//
//   offset 0    header, 16 bytes   "FAPACK\r\n" (8)  u32 format version (1)  u32 reserved (0)
//   offset 16   the files' bytes, back to back, stored as they are (textures, sounds and fonts are already compressed)
//   index       u32 count, then per file, sorted by path (byte order):  u16 path length, the path, u64 offset, u64 size
//               paths are normalized project-relative UTF-8 with '/' separators ("assets/hero.png"), no duplicates;
//               offset counts from the start of the pack
//   footer      24 bytes at the very end:  u64 index offset, u64 index size, "FAPKEND!" (8)
//
// The reader finds the index through the footer, so a pack that was cut short (a download that stopped, a full disk) is
// recognized at once, and it keeps only the index in memory: a file is read from disk when somebody asks for it (a game
// can be hundreds of MB). Reads are positional (pread / ReadFile with an offset), so any number of threads may read the
// same pack at the same time (textures and audio load from several threads).
//
// A pack is immutable: the writer builds a new file next to the target and renames it over it when it is complete.
#pragma once

#include <cstdint>
#include <filesystem>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

inline constexpr std::uint32_t kPackFormatVersion = 1;
inline constexpr const char* kPackFileName = "game.pak";  // where an export puts it: next to the executable (see EXPORTING.md)

// Collects files and writes the pack. Paths are normalized project-relative (fs::normalize_checked leaves them as they
// are); anything else is an error that says how to write it.
class PackWriter {
public:
    // The bytes are kept in memory until write(): for generated content (compiled scripts) and small files.
    Result<void> add_bytes(std::string path, std::vector<std::uint8_t> data);
    // `source` is streamed into the pack by write(), never held in memory: use it for the game's own files.
    Result<void> add_file(std::string path, std::filesystem::path source);

    std::size_t count() const { return items_.size(); }

    // Writes the pack to `out` (the folder must exist). The file appears complete or not at all.
    Result<void> write(const std::filesystem::path& out) const;

private:
    struct Item {
        std::string path;
        std::vector<std::uint8_t> bytes;  // add_bytes
        std::filesystem::path source;     // add_file (empty for add_bytes)
        std::uint64_t size = 0;
    };
    Result<void> check_path(const std::string& path) const;
    std::vector<Item> items_;
};

// An open pack. Safe to use from several threads at once.
class PackReader {
public:
    ~PackReader();
    PackReader(const PackReader&) = delete;
    PackReader& operator=(const PackReader&) = delete;

    // Opens `file` and reads its index. The errors say what is wrong with the file (not a pack, cut short, written by a
    // newer FactorIA) and how to fix it (export the game again with this FactorIA version).
    static Result<std::shared_ptr<const PackReader>> open(const std::filesystem::path& file);

    const std::filesystem::path& file() const { return file_; }

    bool contains(std::string_view path) const;       // a file; `path` is normalized, project-relative
    bool is_directory(std::string_view path) const;   // "" (the root) or a folder with at least one file below it
    std::int64_t size_of(std::string_view path) const;  // bytes; -1 when the pack has no such file
    // The file's bytes, read from disk now. A missing file is an error with a "did you mean" taken from the index.
    Result<std::vector<std::uint8_t>> read(std::string_view path) const;
    // Files below `dir` ("" = all), sorted full paths; `recursive` false lists only the files directly in it.
    std::vector<std::string> list(std::string_view dir, bool recursive) const;
    std::size_t file_count() const { return entries_.size(); }
    // A fixed number (the pack file's modification time when it was opened) for every file: a pack never changes.
    std::int64_t modified_time() const { return mtime_; }

    // The error for a path the pack does not hold: the "did you mean" comes from the files in the same folder, else from
    // every path in the pack. `requested` is what the caller asked for, `normalized` the same, normalized.
    Error not_found(std::string_view requested, std::string_view normalized) const;

private:
    PackReader() = default;
    struct Entry {
        std::string path;
        std::uint64_t offset = 0, size = 0;
    };
    const Entry* find(std::string_view path) const;
    bool read_at(std::uint64_t offset, void* dst, std::uint64_t size) const;

    std::filesystem::path file_;
    std::vector<Entry> entries_;  // sorted by path
    std::int64_t mtime_ = 0;
    std::intptr_t native_ = -1;  // the open file (HANDLE or descriptor), shared by every reader thread
};

}  // namespace fa
