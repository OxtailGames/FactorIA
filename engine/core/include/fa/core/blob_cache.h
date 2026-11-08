// A small on-disk cache of named byte blobs the engine can always rebuild: the compiled shader programs of a graphics
// backend (fa/render, docs/PERFORMANCE.md "Startup"). It lives in fs::cache_dir() (per user, never the game folder).
//
// One file per blob: <dir>/<name>.facache = a header (magic, format version, the cache KEY, payload size, the SHA-256 of the
// payload) and the payload. The key says what the blob is valid for (backend, graphics driver, engine version, a hash of the
// source it was built from). A read checks the file in this order and ignores the file, with ONE log line, when
//   - the magic or the format version is not ours (Damaged: not a cache file, or from another engine layout),
//   - the key differs (Stale: another driver, engine version or source; the next store replaces it),
//   - the file is shorter or longer than its header says (Damaged: cut short),
//   - the checksum does not match (Damaged: bit rot or a partial write by something other than this class).
// Nothing is ever fatal: the caller builds the blob the slow way and stores it again.
//
// A store is atomic: the bytes go to a temporary file next to the target, which then replaces it (fs::replace_file: it waits
// for a reader that holds the target open on Windows). A reader sees the old file or the new one, never half of one; two
// processes storing the same blob at once both succeed and the last rename wins.
#pragma once

#include <cstdint>
#include <filesystem>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

class BlobCache {
public:
    // The most a blob may hold (64 MiB): a bigger file is Damaged without being read. A deterministic cap, not a time.
    static constexpr std::uint64_t kMaxBlobBytes = 64ull * 1024 * 1024;
    static constexpr std::uint32_t kFormatVersion = 1;

    enum class Status {
        Hit,       // `out` holds the payload
        Miss,      // no such file (or the cache is off)
        Stale,     // the file's key is not this cache's key: ignored
        Damaged,   // bad magic or version, cut short, too big or a checksum mismatch: ignored
        Disabled,  // no directory (the web build, a phone before set_cache_dir): nothing is read or written
    };

    // `dir` empty = disabled. `key` is any text (<= 4096 bytes); equal keys accept each other's blobs.
    BlobCache(std::filesystem::path dir, std::string key);

    bool enabled() const { return !dir_.empty(); }
    const std::filesystem::path& dir() const { return dir_; }
    const std::string& key() const { return key_; }
    // Where the blob `name` lives. `name` may hold letters, digits, '.', '_' and '-' only (no path separators).
    std::filesystem::path file_for(std::string_view name) const;

    // Reads `name`. On Stale / Damaged logs one line (category "cache") saying why and that the file is ignored; `why`
    // (optional) gets that sentence for Stale, Damaged and Miss caused by a bad name.
    Status load(std::string_view name, std::vector<std::uint8_t>& out, std::string* why = nullptr) const;
    // Writes `name` atomically (creates the folder). The error says what failed; the cache stays as it was.
    Result<void> store(std::string_view name, std::span<const std::uint8_t> payload) const;

    // The bytes load() would find for these, for tests: header + payload as store() writes them.
    static std::vector<std::uint8_t> encode(std::string_view key, std::span<const std::uint8_t> payload);

private:
    std::filesystem::path dir_;
    std::string key_;
};

const char* blob_cache_status_name(BlobCache::Status s);

}  // namespace fa
