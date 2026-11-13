// Game pack: ONE read-only archive that holds all the files of a game (a `--release` desktop export, docs/EXPORTING.md).
//
// A pack is read through `fa::fs` (fs::mount_pack, fa/core/fs.h): while one is mounted every project-relative path the
// engine reads ("scenes/main.scene.json", "assets/hero.png") is answered from it instead of from loose files.
//
// File format (version 2, what PackWriter writes), all integers little-endian:
//
//   offset 0    header, 16 bytes   "FAPACK\r\n" (8)  u32 format version (2)  u32 flags (0)
//   offset 16   the data: each file's blocks back to back, file after file in PACK ORDER (the order the game first read
//               them in, fa::PackWriter::set_order; the files no recorded session read come last, sorted by path), so a
//               scene's files lie next to each other and a load reads the drive mostly forward
//   index       u32 file count, u32 block size B (the most bytes one block holds once decoded: kPackBlockSize, 256 KiB),
//               u32 block count, then per file, sorted by path (byte order):
//                 u16 path length, the path, u8 codec (0 store, 1 lz4, 2 zstd: fa/core/compress.h),
//                 u64 size (decoded bytes), u64 offset of the file's first block (from the start of the pack),
//                 u64 stored size (bytes of all its blocks in the pack), u32 index of its first block in the block table
//               then the block table, one entry per block, file after file in index order:
//                 u32 stored size of the block, bit 31 set when the block is stored as it is (the codec did not save
//                 enough: see below), u32 XXH32 (seed 0) of the block's stored bytes
//               then u32 XXH32 (seed 0) of every index byte before it
//   footer      24 bytes at the very end:  u64 index offset, u64 index size, "FAPKEND!" (8)
//
// Blocks. A file of `size` bytes has ceil(size / B) blocks (an empty file has none); block k decodes to bytes
// [k*B, min((k+1)*B, size)) of the file, and the blocks of one file are contiguous in the pack. Each block is compressed
// on its own with the file's codec, so a reader that wants part of a big file (a range of an audio stream, one mip of
// a texture) decodes only the blocks that hold it: a read's buffers are what it returns plus at most one block (and
// the zstd decoder's own working state per block, ~14 KiB plus up to 128 KiB of literals, fa/core/compress.h). A block
// keeps its compressed form only when that saves at least 1/32 of its bytes; else it is stored as it is (bit 31), and
// a file none of whose blocks kept a compressed form is recorded with codec store. Small files do NOT share blocks:
// every file starts its own block, so any file can be read without decoding a neighbour (the cost is a worse ratio on
// many tiny files, which are a small part of a game's bytes). Paths are normalized project-relative UTF-8 with '/'
// separators ("assets/hero.png"), case-sensitive, no duplicates.
//
// Checks. Every block's checksum is verified each time it is read, and the index's when the pack is opened, so a pack
// damaged on the drive or in a download is an error that names the file (and block) instead of wrong bytes in a game.
// Opening also checks every size in the index (blocks inside the file, stored sizes that add up, a compressed block
// smaller than what it decodes to and able to hold it), so a tampered index is refused before a read allocates.
//
// Format 1 (FactorIA 0.18 and before) is still read: the same header, footer and path order, with an index of u32 count
// then per file u16 path length, path, u64 offset, u64 size, and the files' bytes stored as they are, unchecked.
//
// Reading. The reader keeps only the index in memory. On 64-bit desktops it maps the whole pack into memory once
// (mmap / MapViewOfFile): a read is then a copy (or a decode) out of the mapping, the OS pages the data in, and a file
// stored as it is can be handed out with no copy at all (PackReader::view, fs::read_view). Where a mapping is not
// possible or not wanted (a 32-bit process, the web build whose pack lives in browser memory, a failed map, the
// FA_PACK_MAP=0 environment variable or PackOpenOptions::map false) it falls back to positional reads (pread /
// ReadFile with an offset). Both are safe from any number of threads at the same time.
//
// A pack is immutable: the writer builds a new file next to the target and renames it over it when it is complete, so
// a game that has the old pack mapped keeps reading the old bytes on macOS and Linux (rename never touches the old
// file; changing a mapped pack IN PLACE, by truncating it, would make the reading process crash with SIGBUS, which is
// why nothing in FactorIA writes into an existing pack). On Windows an open file cannot be replaced at all, mapped or not:
// PackWriter::write over the pack of a running game fails with an error that says to close it, and the old pack stays as
// it was (a release export looks for open files in its whole output folder before it deletes anything, EXPORTING.md).
#pragma once

#include <array>
#include <atomic>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/compress.h"
#include "fa/core/fs.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr std::uint32_t kPackFormatVersion = 2;
inline constexpr std::uint32_t kPackBlockSize = 256 * 1024;  // the most bytes one block decodes to (format 2)
inline constexpr const char* kPackFileName =
    "game.pak";  // where an export puts it: next to the executable (see EXPORTING.md)

// The largest file (decoded) a pack of `packBytes` bytes may hold: 64 times the pack's size, and never less than 256 MiB.
// A reader refuses a bigger one as damaged when it opens the pack, so a hostile index cannot make a read allocate
// gigabytes from a small file; a writer refuses to write one (a file that compresses more than 64 times, in a pack under
// 4 MiB: store it, `export.pack.codecs`). Real game data is far below it: zstd packs text 3 to 10 times.
inline constexpr std::uint64_t kPackMinFileCap = 256ull << 20;
inline constexpr std::uint64_t kPackFileCapRatio = 64;
constexpr std::uint64_t pack_max_file_size(std::uint64_t packBytes) {
    if (packBytes > ~std::uint64_t(0) / kPackFileCapRatio) return ~std::uint64_t(0);
    return packBytes * kPackFileCapRatio > kPackMinFileCap ? packBytes * kPackFileCapRatio : kPackMinFileCap;
}

// The codec a file gets when nobody chose one (factoria.json export.pack.codecs overrides it per extension,
// docs/EXPORTING.md): data that is compressed already is stored (PNG, JPG, WebP, OGG, MP3, QOA, MP4, WebM, Basis, KTX2
// with supercompression, WOFF/WOFF2, archives); what a load reads on its hot path and decodes fast gets lz4 (JSON,
// scenes, scripts and script bytecode, meshes, raw images and sounds, KTX2 without supercompression); text that is
// mostly read once and compresses well gets zstd (fonts, .txt, .md, .csv, .xml, .svg, .html, shaders, localization
// files). `head` is the start of the file (at least 48 bytes for .ktx2, whose header says whether it is supercompressed;
// empty = treat a .ktx2 as supercompressed).
Codec pack_default_codec(std::string_view path, std::span<const std::uint8_t> head = {});

// The checksum of blocks and of the index in format 2: XXH32 with seed 0 (the xxHash algorithm; "" gives 0x02CC5D05).
std::uint32_t pack_checksum(std::span<const std::uint8_t> data);

// What PackWriter::write packed, for the export report.
struct PackCodecStats {
    std::uint64_t files = 0;
    std::uint64_t bytes = 0;        // the files' sizes
    std::uint64_t storedBytes = 0;  // what they take in the pack
};
struct PackStats {
    std::uint64_t files = 0, bytes = 0, storedBytes = 0;
    std::uint64_t packBytes = 0;  // the size of the pack file (data + index + header and footer)
    // By the codec each file ended up with (index = Codec value): a file whose codec saved nothing counts as store.
    std::array<PackCodecStats, 3> codecs{};
    std::uint64_t orderedFiles = 0;  // files placed by set_order (the rest came after them, by path)
    std::uint64_t blocksKeptRaw =
        0;  // blocks of lz4 / zstd files stored as they are, because the codec saved too little
    // Blocks a codec could not compress (an error from fa::compress): stored as they are, and the first error is kept
    // here so the export can say so. 0 in a working build.
    std::uint64_t compressErrors = 0;
    std::string firstCompressError;
};

// Collects files and writes the pack. Paths are normalized project-relative (fs::normalize_checked leaves them as they
// are); anything else is an error that says how to write it.
class PackWriter {
public:
    // The bytes are kept in memory until write(): for generated content (compiled scripts) and small files. `codec`
    // empty = pack_default_codec(path, data).
    Result<void> add_bytes(std::string path, std::vector<std::uint8_t> data, std::optional<Codec> codec = std::nullopt);
    // `source` is streamed into the pack by write(), one block at a time, never held in memory: use it for the game's
    // own files. `codec` empty = pack_default_codec(path, <the file's first bytes>).
    Result<void> add_file(std::string path, std::filesystem::path source, std::optional<Codec> codec = std::nullopt);

    // The order of the data: these paths first, in this order (paths that were not added are skipped, a repeat counts
    // once), then every other file sorted by path. Without it the data is sorted by path. The index is always sorted.
    void set_order(std::vector<std::string> paths);

    // Compression level for every file (fa::CompressOptions::level; 0 = each codec's default).
    void set_level(int level) { level_ = level; }

    // Writes the pack to `out` (the folder must exist). The file appears complete or not at all: the bytes go to
    // `out` + ".tmp", which replaces `out` once it is complete (fs::replace_file, which waits about a second for a
    // reader to let go). The same files, codecs, order and level give the same bytes on every platform. When `out` is in
    // use (Windows: a running game has it open), the error says to close the game, and `out` stays as it was. A file over
    // pack_max_file_size of the finished pack is an error (nothing is written).
    Result<PackStats> write(const std::filesystem::path& out) const;

private:
    struct Item {
        std::string path;
        std::vector<std::uint8_t> bytes;  // add_bytes
        std::filesystem::path source;     // add_file (empty for add_bytes)
        std::uint64_t size = 0;
        Codec codec = Codec::Store;
    };
    Result<void> check_path(const std::string& path) const;
    std::vector<Item> items_;
    std::vector<std::string> order_;
    int level_ = 0;
};

struct PackOpenOptions {
    // Map the pack into memory when the platform allows it (64-bit, not the web). false = positional reads only, as the
    // FA_PACK_MAP=0 environment variable does for every pack the process opens (tests use both to cover each path).
    bool map = true;
};

// An open pack. Safe to use from several threads at once.
class PackReader : public std::enable_shared_from_this<PackReader> {
public:
    ~PackReader();
    PackReader(const PackReader&) = delete;
    PackReader& operator=(const PackReader&) = delete;

    // Opens `file` and reads its index. The errors say what is wrong with the file (not a pack, cut short, damaged,
    // written by a newer FactorIA) and how to fix it (export the game again with this FactorIA version).
    static Result<std::shared_ptr<const PackReader>> open(const std::filesystem::path& file,
                                                          const PackOpenOptions& options = {});
    // Opens a pack that is already in memory (a download, a test, a fuzz input): `bytes` is moved into the reader, which
    // answers every read from it. The same checks as open(): any byte string is either a pack or an error, never a
    // crash. `name` stands for the file in the error messages. Nothing is registered with the Windows file rules.
    static Result<std::shared_ptr<const PackReader>> open_memory(std::vector<std::uint8_t> bytes,
                                                                 std::string name = "(memory)");

    bool contains(std::string_view path) const;         // a file; `path` is normalized, project-relative
    bool is_directory(std::string_view path) const;     // "" (the root) or a folder with at least one file below it
    std::int64_t size_of(std::string_view path) const;  // decoded bytes; -1 when the pack has no such file
    std::int64_t
    stored_size_of(std::string_view path) const;  // bytes the file takes in the pack; -1 when it is not there
    // The codec the file is stored with (store when the pack has no such file).
    Codec codec_of(std::string_view path) const;
    // The file's bytes, read (and decoded) now. A missing file is an error with a "did you mean" taken from the index; a
    // damaged block is an error that names the file and the block.
    Result<std::vector<std::uint8_t>> read(std::string_view path) const;
    // `size` bytes of the file from `offset` (clamped to the file's end): only the blocks that hold them are read and
    // decoded.
    Result<std::vector<std::uint8_t>> read_range(std::string_view path, std::uint64_t offset, std::uint64_t size) const;
    // The file's bytes without a copy when the pack is mapped and the file is stored as it is (the view keeps the pack
    // mapped while it lives); else the bytes of read() in a buffer the view owns. Checksums are verified either way.
    Result<fs::FileView> view(std::string_view path) const;
    // Files below `dir` ("" = all), sorted full paths; `recursive` false lists only the files directly in it.
    std::vector<std::string> list(std::string_view dir, bool recursive) const;
    std::size_t file_count() const { return entries_.size(); }
    // A fixed number (the pack file's modification time when it was opened) for every file: a pack never changes.
    std::int64_t modified_time() const { return mtime_; }
    std::uint32_t format_version() const { return version_; }
    bool mapped() const {
        return map_ != nullptr;
    }  // reads come from memory: a mapping or open_memory (else positional reads)
    // The data region in pack order: each file's path, in the order its bytes lie in the pack (tests, `factoria` tools).
    std::vector<std::string> data_order() const;

    // Reads served since the pack was opened (read, read_range and view calls that succeeded) and the bytes they
    // returned and took from the pack (stored, before decoding). For the loading section of a play report.
    struct Counters {
        std::uint64_t reads = 0, bytes = 0, storedBytes = 0;
    };
    Counters counters() const;

    // The error for a path the pack does not hold: the "did you mean" comes from the files in the same folder, else from
    // every path in the pack. `requested` is what the caller asked for, `normalized` the same, normalized.
    Error not_found(std::string_view requested, std::string_view normalized) const;

private:
    PackReader() = default;
    // What open() and open_memory() share: checks the header, the footer and the index of the `fileSize` bytes read_at()
    // serves, then (a file only: `file` is not null) maps the pack and registers it.
    static Result<std::shared_ptr<const PackReader>> finish_open(std::shared_ptr<PackReader> pack,
                                                                 const std::string& name, std::uint64_t fileSize,
                                                                 const std::filesystem::path* file,
                                                                 const PackOpenOptions& options);
    struct Entry {
        std::string path;
        Codec codec = Codec::Store;
        std::uint64_t offset = 0, size = 0, stored = 0;
        std::uint32_t firstBlock = 0, blockCount = 0;  // format 1: no blocks
    };
    struct Block {
        std::uint64_t offset = 0;  // from the start of the pack
        std::uint32_t stored = 0;
        std::uint32_t checksum = 0;
        bool raw = false;
    };
    const Entry* find(std::string_view path) const;
    Result<const Entry*> find_file(std::string_view path) const;
    bool read_at(std::uint64_t offset, void* dst, std::uint64_t size) const;
    // Decodes bytes [from, from + out.size()) of `e` into `out`.
    Result<void> decode_range(const Entry& e, std::uint64_t from, std::span<std::uint8_t> out) const;
    Error damaged(const Entry& e, std::uint32_t block, const std::string& what) const;
    void count(std::uint64_t bytes, std::uint64_t stored) const;

    std::filesystem::path file_;
    std::vector<Entry> entries_;  // sorted by path
    std::vector<Block> blocks_;
    std::uint32_t version_ = 0;
    std::uint32_t blockSize_ = kPackBlockSize;
    std::int64_t mtime_ = 0;
    std::intptr_t native_ = -1;          // the open file (HANDLE or descriptor), shared by every reader thread
    std::intptr_t mapping_ = 0;          // Windows: the file mapping object
    const std::uint8_t* map_ = nullptr;  // the whole pack, when mapped (or held in memory_)
    std::vector<std::uint8_t> memory_;   // open_memory: the pack's bytes, which map_ points into
    bool inMemory_ = false;              // open_memory: map_ points into memory_ and is not a file mapping to unmap
    std::uint64_t mapSize_ = 0;
    std::string registered_;  // the Windows rules registry key while open (fs.h, "Windows file rules")
    mutable std::atomic<std::uint64_t> reads_{0}, bytesRead_{0}, storedRead_{0};
};

}  // namespace fa
